use crossterm::{
    QueueableCommand,
    cursor::MoveTo,
    style::{
        Attribute, Attributes, Color, Print, SetAttribute, SetAttributes, SetBackgroundColor,
        SetForegroundColor,
    },
};
use ljr::{prelude::*, value::Kind};
use std::io::Write;
use unicode_segmentation::UnicodeSegmentation;

use crate::error::Error;

pub struct BufferFactory;

#[user_data]
impl BufferFactory {
    pub fn new(width: i32, height: i32) -> Buffer {
        new(width, height)
    }
}

#[derive(Debug, Clone, PartialEq)]
struct Style {
    fg: Color,
    bg: Color,
    attr: Attributes,
}

impl Default for Style {
    fn default() -> Self {
        Self {
            fg: Color::Reset,
            bg: Color::Reset,
            attr: Default::default(),
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
struct Cell {
    symbol: String,
    style: Style,
    width: u8,
}

impl Default for Cell {
    fn default() -> Self {
        Self {
            symbol: " ".to_string(),
            style: Style::default(),
            width: 1,
        }
    }
}

#[derive(Debug, Clone)]
pub struct Buffer {
    cells: Vec<Cell>,
    width: u16,
    height: u16,

    cx: u16,
    cy: u16,

    clip_x: u16,
    clip_y: u16,
    clip_w: u16,
    clip_h: u16,

    style: Style,
    styles: Vec<Style>,
}

#[user_data]
impl Buffer {
    pub fn resize(&mut self, width: i32, height: i32) {
        let width = width.max(0) as u16;
        let height = height.max(0) as u16;
        self.cells
            .resize((width * height) as usize, Cell::default());
        self.width = width;
        self.height = height;
        self.clip_x = 0;
        self.clip_y = 0;
        self.clip_w = width;
        self.clip_h = height;
        self.clear()
    }

    pub fn clear(&mut self) {
        self.cx = 0;
        self.cy = 0;
        self.cells.fill(Cell::default());
        self.style = Style::default();
        self.styles.clear();
    }

    pub fn clear_clip(&mut self) {
        for y in self.clip_y..(self.clip_y + self.clip_h).min(self.height) {
            for x in self.clip_x..(self.clip_x + self.clip_w).min(self.width) {
                let idx = (y as usize * self.width as usize) + x as usize;
                if let Some(cell) = self.cells.get_mut(idx) {
                    *cell = Cell::default();
                }
            }
        }
    }

    pub fn set_clip(&mut self, x: i32, y: i32, w: i32, h: i32) {
        self.clip_x = (x - 1).max(0) as u16;
        self.clip_y = (y - 1).max(0) as u16;
        self.clip_w = w.max(0) as u16;
        self.clip_h = h.max(0) as u16;
    }

    pub fn get_clip(&self) -> (i32, i32, i32, i32) {
        (
            (self.clip_x + 1) as i32,
            (self.clip_y + 1) as i32,
            self.clip_w as i32,
            self.clip_h as i32,
        )
    }

    pub fn set_fg(&mut self, color: Option<&StackValue>) -> Result<(), Error> {
        self.style.fg = match color {
            Some(v) => parse_color(v)?.unwrap_or(Color::Reset),
            None => Color::Reset,
        };
        Ok(())
    }

    pub fn set_bg(&mut self, color: Option<&StackValue>) -> Result<(), Error> {
        self.style.bg = match color {
            Some(v) => parse_color(v)?.unwrap_or(Color::Reset),
            None => Color::Reset,
        };
        Ok(())
    }

    pub fn set_attr(&mut self, attr: Option<&str>) {
        match attr {
            Some(attr) => self.style.attr = parse_attributes(attr),
            None => self.style.attr = Attributes::none(),
        }
    }

    pub fn reset_style(&mut self) {
        self.style = Style::default();
    }
    pub fn push_style(&mut self) {
        self.styles.push(self.style.clone())
    }
    pub fn pop_style(&mut self) {
        if let Some(style) = self.styles.pop() {
            self.style = style;
        }
    }

    pub fn move_to(&mut self, x: i32, y: i32) {
        self.cx = ((x - 1).max(0) as u16).min(self.width.saturating_sub(1));
        self.cy = ((y - 1).max(0) as u16).min(self.height.saturating_sub(1));
    }

    pub fn move_to_col(&mut self, x: i32) {
        self.cx = ((x - 1).max(0) as u16).min(self.width.saturating_sub(1));
    }

    pub fn move_to_next_line(&mut self) {
        self.cx = 0;
        self.cy = (self.cy + 1).min(self.height.saturating_sub(1));
    }

    pub fn write(&mut self, text: &str) {
        if self.width == 0 || self.height == 0 {
            return;
        }

        for g in text.graphemes(true) {
            if g == "\n" {
                self.move_to_next_line();
                continue;
            }

            let w = unicode_width::UnicodeWidthStr::width(g) as u16;

            if w == 0 {
                if self.cx > 0 {
                    let idx = (self.cy as usize * self.width as usize) + (self.cx as usize - 1);
                    let target_idx = if self.cells[idx].width == 0 && self.cx > 1 {
                        idx - 1
                    } else {
                        idx
                    };
                    self.cells[target_idx].symbol.push_str(g);
                }
                continue;
            }

            if self.cx + w > self.width {
                self.move_to_next_line();
            }
            if self.cy >= self.height {
                break;
            }

            if self.cx >= self.clip_x
                && self.cx < (self.clip_x + self.clip_w)
                && self.cy >= self.clip_y
                && self.cy < (self.clip_y + self.clip_h)
            {
                let idx = (self.cy as usize * self.width as usize) + self.cx as usize;

                if self.cells[idx].width == 0 && self.cx > 0 {
                    self.cells[idx - 1] = Cell::default();
                }

                if self.cells[idx].width == 2 && w == 1 && (self.cx + 1) < self.width {
                    self.cells[idx + 1] = Cell::default();
                }

                self.cells[idx] = Cell {
                    symbol: g.to_string(),
                    style: self.style.clone(),
                    width: w as u8,
                };

                if w == 2 && (self.cx + 1) < self.width {
                    self.cells[idx + 1] = Cell {
                        symbol: String::new(),
                        style: self.style.clone(),
                        width: 0,
                    };
                }
            }
            self.cx += w;
        }
    }

    pub fn write_at(&mut self, x: i32, y: i32, text: &str) {
        let (old_x, old_y) = (self.cx, self.cy);
        self.cx = ((x - 1).max(0) as u16).min(self.width.saturating_sub(1));
        self.cy = ((y - 1).max(0) as u16).min(self.height.saturating_sub(1));
        self.write(text);
        (self.cx, self.cy) = (old_x, old_y);
    }

    pub fn blit(
        &mut self,
        other: &Buffer,
        src_x: i32,
        src_y: i32,
        dest_x: i32,
        dest_y: i32,
        dest_w: i32,
        dest_h: i32,
    ) {
        let src_x = (src_x - 1).max(0);
        let src_y = (src_y - 1).max(0);
        let dest_x = (dest_x - 1).max(0);
        let dest_y = (dest_y - 1).max(0);

        let src_end_x = (src_x + dest_w).min(other.width as i32);
        let src_end_y = (src_y + dest_h).min(other.height as i32);

        for sy in src_y..src_end_y {
            let dy = dest_y + (sy - src_y);
            if dy < 0 || dy >= self.height as i32 {
                continue;
            }

            for sx in src_x..src_end_x {
                let dx = dest_x + (sx - src_x);
                if dx < 0 || dx >= self.width as i32 {
                    continue;
                }

                let src_idx = (sy as usize * other.width as usize) + sx as usize;
                let dest_idx = (dy as usize * self.width as usize) + dx as usize;

                let cell = &other.cells[src_idx];

                if cell.width == 0 {
                    continue;
                }

                let dest_width = self.cells[dest_idx].width;

                if dest_width == 0 && dx > 0 {
                    self.cells[dest_idx - 1] = Cell::default();
                }

                if dest_width == 2 && cell.width == 1 && (dx + 1) < self.width as i32 {
                    self.cells[dest_idx + 1] = Cell::default();
                }

                self.cells[dest_idx] = cell.clone();

                if cell.width == 2 && (dx + 1) < self.width as i32 && (sx + 1) < other.width as i32
                {
                    let src_next_idx = src_idx + 1;
                    let dest_next_idx = dest_idx + 1;
                    self.cells[dest_next_idx] = other.cells[src_next_idx].clone();
                }
            }
        }
    }
}

fn new(width: i32, height: i32) -> Buffer {
    let width = width.max(0) as u16;
    let height = height.max(0) as u16;
    let cells = vec![Cell::default(); (width * height) as usize];
    Buffer {
        cells,
        width,
        height,
        cx: 0,
        cy: 0,
        clip_x: 0,
        clip_y: 0,
        clip_w: width,
        clip_h: height,
        style: Style::default(),
        styles: vec![],
    }
}

pub fn render_diff(back: &Buffer, front: &mut Buffer, qc: &mut impl Write) -> Result<(), Error> {
    let mut cur_fg = None;
    let mut cur_bg = None;
    let mut cur_attr = None;

    for y in 0..back.height {
        for x in 0..back.width {
            let idx = (y as usize * back.width as usize) + x as usize;
            let b = &back.cells[idx];
            let f = &front.cells[idx];

            if b != f {
                front.cells[idx] = b.clone();

                if b.width == 0 {
                    continue;
                }

                qc.queue(MoveTo(x, y))?;

                if cur_fg != Some(b.style.fg)
                    || cur_bg != Some(b.style.bg)
                    || cur_attr != Some(b.style.attr)
                {
                    qc.queue(SetAttribute(Attribute::Reset))?;
                    qc.queue(SetForegroundColor(b.style.fg))?;
                    qc.queue(SetBackgroundColor(b.style.bg))?;
                    qc.queue(SetAttributes(b.style.attr))?;
                    cur_fg = Some(b.style.fg);
                    cur_bg = Some(b.style.bg);
                    cur_attr = Some(b.style.attr);
                }

                let to_print = if b.symbol.is_empty() { " " } else { &b.symbol };
                qc.queue(Print(to_print))?;

                if b.width == 2 && (x + 1) < back.width {
                    let next_idx = idx + 1;
                    front.cells[next_idx] = back.cells[next_idx].clone();
                }
            }
        }
    }
    qc.flush()?;
    Ok(())
}

fn parse_color(value: &StackValue) -> Result<Option<Color>, Error> {
    match value.kind() {
        Kind::Nil => Ok(None),
        Kind::Number => {
            let num = value.try_as_number().map_err(|_| Error::InvalidColor)? as u8;
            Ok(Some(Color::AnsiValue(num)))
        }
        Kind::String => {
            let lstr = value.try_as_str().map_err(|_| Error::InvalidColor)?;
            let val = lstr.try_as_str().map_err(|_| Error::InvalidColor)?;

            if val.starts_with('#') && val.len() == 7 {
                let r = u8::from_str_radix(&val[1..3], 16).unwrap_or(0);
                let g = u8::from_str_radix(&val[3..5], 16).unwrap_or(0);
                let b = u8::from_str_radix(&val[5..7], 16).unwrap_or(0);

                Ok(Some(Color::Rgb { r, g, b }))
            } else {
                Err(Error::InvalidColor)
            }
        }
        Kind::Table => {
            let table = value.try_as_table().map_err(|_| Error::InvalidColor)?;
            let guard = table.try_as_ref().map_err(|_| Error::InvalidColor)?;

            let r = guard.get(1).unwrap_or(0) as u8;
            let g = guard.get(2).unwrap_or(0) as u8;
            let b = guard.get(3).unwrap_or(0) as u8;

            Ok(Some(Color::Rgb { r, g, b }))
        }
        _ => Err(Error::InvalidColor),
    }
}

fn parse_attributes(s: &str) -> Attributes {
    let mut attrs = Attributes::default();
    for part in s.split_whitespace() {
        match part {
            "bold" => attrs.set(Attribute::Bold),
            "italic" => attrs.set(Attribute::Italic),
            "dim" => attrs.set(Attribute::Dim),
            "under" | "underline" => attrs.set(Attribute::Underlined),
            "blink" => attrs.set(Attribute::SlowBlink),
            "reverse" => attrs.set(Attribute::Reverse),
            "hidden" => attrs.set(Attribute::Hidden),
            "reset" => attrs = Attributes::none(),
            "no_bold" => attrs.set(Attribute::NoBold),
            "no_italic" => attrs.set(Attribute::NoItalic),
            "no_under" | "no_underline" => attrs.set(Attribute::NoUnderline),
            "no_blink" => attrs.set(Attribute::NoBlink),
            "no_reverse" => attrs.set(Attribute::NoReverse),
            "no_hidden" => attrs.set(Attribute::NoHidden),

            _ => {}
        }
    }
    attrs
}
