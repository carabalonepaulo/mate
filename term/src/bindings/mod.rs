pub mod buffer;
pub mod time;

use std::{
    io::{Stdout, Write, stdout},
    time::Duration,
};

use crossterm::{
    cursor::{
        self, MoveToNextLine, MoveToPreviousLine, RestorePosition, SavePosition, SetCursorStyle,
    },
    event::{
        self, DisableBracketedPaste, DisableMouseCapture, EnableBracketedPaste, EnableMouseCapture,
        Event, KeyCode, KeyEventKind, KeyModifiers, MouseButton, MouseEventKind,
    },
    execute, queue,
    style::{Attribute, Color, Print, SetAttribute, SetBackgroundColor, SetForegroundColor},
    terminal::{
        Clear, ClearType, EnterAlternateScreen, LeaveAlternateScreen, SetTitle, disable_raw_mode,
        enable_raw_mode,
    },
};
use ljr::{prelude::*, table::GuardMut, value::Kind};

use crate::{bindings::buffer::Buffer, error::Error};

pub struct Term {
    auto_cleanup: bool,
    stdout: Stdout,
}

#[user_data]
impl Term {
    pub fn enable_raw_mode(&mut self) -> Result<(), Error> {
        Ok(enable_raw_mode()?)
    }

    pub fn disable_raw_mode(&mut self) -> Result<(), Error> {
        Ok(disable_raw_mode()?)
    }

    pub fn enter_alt_screen(&mut self) -> Result<(), Error> {
        Ok(queue!(self.stdout, EnterAlternateScreen)?)
    }

    pub fn leave_alt_screen(&mut self) -> Result<(), Error> {
        Ok(queue!(self.stdout, LeaveAlternateScreen)?)
    }

    pub fn enable_mouse(&mut self) -> Result<(), Error> {
        Ok(queue!(self.stdout, EnableMouseCapture)?)
    }

    pub fn disable_mouse(&mut self) -> Result<(), Error> {
        Ok(queue!(self.stdout, DisableMouseCapture)?)
    }

    pub fn enable_bracketed_paste(&mut self) -> Result<(), Error> {
        Ok(queue!(self.stdout, EnableBracketedPaste)?)
    }

    pub fn disable_bracketed_paste(&mut self) -> Result<(), Error> {
        Ok(queue!(self.stdout, DisableBracketedPaste)?)
    }

    pub fn set_title(&mut self, title: &str) -> Result<(), Error> {
        Ok(queue!(self.stdout, SetTitle(title))?)
    }

    pub fn hide_cursor(&mut self) -> Result<(), Error> {
        Ok(queue!(self.stdout, cursor::Hide)?)
    }

    pub fn show_cursor(&mut self) -> Result<(), Error> {
        Ok(queue!(self.stdout, cursor::Show)?)
    }

    pub fn get_cursor_pos(&mut self) -> Result<(i32, i32), Error> {
        self.stdout.flush()?;
        let (x, y) = crossterm::cursor::position()?;
        Ok((x as _, y as _))
    }

    pub fn get_size(&mut self) -> Result<(i32, i32), Error> {
        self.stdout.flush()?;
        let (w, h) = crossterm::terminal::size()?;
        Ok((w as _, h as _))
    }

    pub fn move_cursor(&mut self, x: i32, y: i32) -> Result<(), Error> {
        let x = x.max(0).min(u16::MAX as i32) as u16;
        let y = y.max(0).min(u16::MAX as i32) as u16;
        Ok(queue!(self.stdout, cursor::MoveTo(x as _, y as _))?)
    }

    pub fn move_to_row(&mut self, x: i32) -> Result<(), Error> {
        Ok(queue!(self.stdout, cursor::MoveToRow(x as _))?)
    }

    pub fn move_to_col(&mut self, y: i32) -> Result<(), Error> {
        Ok(queue!(self.stdout, cursor::MoveToColumn(y as _))?)
    }

    pub fn move_to_next_line(&mut self) -> Result<(), Error> {
        Ok(queue!(self.stdout, MoveToNextLine(1))?)
    }

    pub fn move_to_previous_line(&mut self) -> Result<(), Error> {
        Ok(queue!(self.stdout, MoveToPreviousLine(1))?)
    }

    pub fn print(&mut self, text: &str) -> Result<(), Error> {
        Ok(queue!(self.stdout, Print(text))?)
    }

    pub fn print_at(&mut self, x: i32, y: i32, text: &str) -> Result<(), Error> {
        let x = x.max(0).min(u16::MAX as i32) as u16;
        let y = y.max(0).min(u16::MAX as i32) as u16;

        Ok(queue!(self.stdout, cursor::MoveTo(x, y), Print(text))?)
    }

    pub fn println(&mut self, text: &str) -> Result<(), Error> {
        Ok(queue!(self.stdout, Print(text), Print("\n"))?)
    }

    pub fn save_cursor(&mut self) -> Result<(), Error> {
        Ok(queue!(self.stdout, SavePosition)?)
    }

    pub fn restore_cursor(&mut self) -> Result<(), Error> {
        Ok(queue!(self.stdout, RestorePosition)?)
    }

    pub fn set_cursor_style(&mut self, style: &str) -> Result<(), Error> {
        let s = match style {
            "default" | "block" => SetCursorStyle::DefaultUserShape,
            "blinking_block" => SetCursorStyle::BlinkingBlock,
            "steady_block" => SetCursorStyle::SteadyBlock,
            "bar" | "line" => SetCursorStyle::BlinkingBar,
            "steady_bar" => SetCursorStyle::SteadyBar,
            "underline" => SetCursorStyle::BlinkingUnderScore,
            "steady_underline" => SetCursorStyle::SteadyUnderScore,
            _ => SetCursorStyle::DefaultUserShape,
        };
        Ok(queue!(self.stdout, s)?)
    }

    pub fn set_style(
        &mut self,
        fg: &StackValue,
        bg: &StackValue,
        attrs: &str,
    ) -> Result<(), Error> {
        if let Some(color) = parse_color(fg)? {
            queue!(self.stdout, SetForegroundColor(color))?;
        }

        if let Some(color) = parse_color(bg)? {
            queue!(self.stdout, SetBackgroundColor(color))?;
        }

        for attr in parse_attributes(attrs) {
            queue!(self.stdout, SetAttribute(attr))?
        }

        Ok(())
    }

    pub fn reset_style(&mut self) -> Result<(), Error> {
        Ok(queue!(self.stdout, SetAttribute(Attribute::Reset))?)
    }

    pub fn reset_fg(&mut self) -> Result<(), Error> {
        Ok(queue!(self.stdout, SetForegroundColor(Color::Reset))?)
    }

    pub fn reset_bg(&mut self) -> Result<(), Error> {
        Ok(queue!(self.stdout, SetBackgroundColor(Color::Reset))?)
    }

    pub fn set_attr(&mut self, attr: &str) -> Result<(), Error> {
        let a = match attr {
            "bold" => Attribute::Bold,
            "italic" => Attribute::Italic,
            "dim" => Attribute::Dim,
            "under" | "underline" => Attribute::Underlined,
            "blink" => Attribute::SlowBlink,
            "reverse" => Attribute::Reverse,
            "hidden" => Attribute::Hidden,
            "reset" => Attribute::Reset,
            _ => return Ok(()),
        };

        Ok(queue!(self.stdout, SetAttribute(a))?)
    }

    pub fn unset_attr(&mut self, attr: &str) -> Result<(), Error> {
        let a = match attr {
            "bold" => Attribute::NoBold,
            "italic" => Attribute::NoItalic,
            "under" | "underline" => Attribute::NoUnderline,
            "blink" => Attribute::NoBlink,
            "reverse" => Attribute::NoReverse,
            "hidden" => Attribute::NoHidden,
            _ => return Ok(()),
        };

        Ok(queue!(self.stdout, SetAttribute(a))?)
    }

    pub fn clear(&mut self) -> Result<(), Error> {
        Ok(queue!(self.stdout, Clear(ClearType::All))?)
    }

    pub fn clear_line(&mut self) -> Result<(), Error> {
        Ok(queue!(self.stdout, Clear(ClearType::CurrentLine))?)
    }

    pub fn clear_until_newline(&mut self) -> Result<(), Error> {
        Ok(queue!(self.stdout, Clear(ClearType::UntilNewLine))?)
    }

    pub fn clear_from_cursor_down(&mut self) -> Result<(), Error> {
        Ok(queue!(self.stdout, Clear(ClearType::FromCursorDown))?)
    }

    pub fn clear_from_cursor_up(&mut self) -> Result<(), Error> {
        Ok(queue!(self.stdout, Clear(ClearType::FromCursorUp))?)
    }

    pub fn scroll_up(&mut self, n: i32) -> Result<(), Error> {
        Ok(queue!(
            self.stdout,
            crossterm::terminal::ScrollUp(n as u16)
        )?)
    }

    pub fn scroll_down(&mut self, n: i32) -> Result<(), Error> {
        Ok(queue!(
            self.stdout,
            crossterm::terminal::ScrollDown(n as u16)
        )?)
    }

    pub fn flush(&mut self) -> Result<(), Error> {
        Ok(self.stdout.flush()?)
    }

    pub fn poll(&mut self, timeout_ms: i32, lua: &Lua) -> Result<TableRef, Error> {
        let mut table = lua.create_table();
        {
            let mut guard = table.try_as_mut()?;

            let timeout = Duration::from_millis(timeout_ms as u64);

            if event::poll(timeout)? {
                if let Ok(ev) = event::read() {
                    table_from_event(ev, &mut *guard)?;
                }

                let mut limit = 50;
                while limit > 0 && event::poll(Duration::from_millis(0)).unwrap_or(false) {
                    if let Ok(ev) = event::read() {
                        table_from_event(ev, &mut *guard)?;
                    }
                    limit -= 1;
                }
            }
        }
        Ok(table)
    }

    pub fn read(&mut self, lua: &Lua) -> Result<TableRef, Error> {
        let mut table = lua.create_table();
        {
            let mut guard = table.try_as_mut()?;

            let ev = event::read()?;
            table_from_event(ev, &mut *guard)?;

            let mut limit = 50;
            while limit > 0 && event::poll(Duration::from_millis(0)).unwrap_or(false) {
                if let Ok(ev) = event::read() {
                    table_from_event(ev, &mut *guard)?;
                }
                limit -= 1;
            }
        }
        Ok(table)
    }

    pub fn set_auto_cleanup(&mut self, enabled: bool) {
        self.auto_cleanup = enabled;
    }

    pub fn render_diff(&mut self, back: &Buffer, front: &mut Buffer) -> Result<(), Error> {
        buffer::render_diff(back, front, &mut self.stdout)?;
        Ok(())
    }
}

impl Drop for Term {
    fn drop(&mut self) {
        if !self.auto_cleanup {
            return;
        }

        execute!(
            self.stdout,
            cursor::Show,
            LeaveAlternateScreen,
            DisableMouseCapture,
            DisableBracketedPaste,
        )
        .ok();
        disable_raw_mode().ok();
    }
}

pub fn new() -> Result<Term, Error> {
    Ok(Term {
        stdout: stdout(),
        auto_cleanup: true,
    })
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

fn parse_attributes(s: &str) -> Vec<Attribute> {
    let mut attrs = vec![];
    for part in s.split_whitespace() {
        match part {
            "bold" => attrs.push(Attribute::Bold),
            "italic" => attrs.push(Attribute::Italic),
            "dim" => attrs.push(Attribute::Dim),
            "under" | "underline" => attrs.push(Attribute::Underlined),
            "blink" => attrs.push(Attribute::SlowBlink),
            "reverse" => attrs.push(Attribute::Reverse),
            "hidden" => attrs.push(Attribute::Hidden),
            "reset" => attrs.push(Attribute::Reset),

            "no_bold" => attrs.push(Attribute::NoBold),
            "no_italic" => attrs.push(Attribute::NoItalic),
            "no_under" | "no_underline" => attrs.push(Attribute::NoUnderline),
            "no_blink" => attrs.push(Attribute::NoBlink),
            "no_reverse" => attrs.push(Attribute::NoReverse),
            "no_hidden" => attrs.push(Attribute::NoHidden),

            _ => {}
        }
    }
    attrs
}

fn set_key_code(guard: &mut GuardMut<'_>, code: KeyCode) -> Result<(), Error> {
    match code {
        KeyCode::Char(c) => guard.try_set("code", c.to_string())?,
        KeyCode::F(n) => guard.try_set("code", format!("f{}", n))?,

        KeyCode::Up => guard.try_set("code", "up")?,
        KeyCode::Down => guard.try_set("code", "down")?,
        KeyCode::Left => guard.try_set("code", "left")?,
        KeyCode::Right => guard.try_set("code", "right")?,
        KeyCode::Home => guard.try_set("code", "home")?,
        KeyCode::End => guard.try_set("code", "end")?,
        KeyCode::PageUp => guard.try_set("code", "pageup")?,
        KeyCode::PageDown => guard.try_set("code", "pagedown")?,
        KeyCode::Tab => guard.try_set("code", "tab")?,
        KeyCode::BackTab => guard.try_set("code", "backtab")?,

        KeyCode::Enter => guard.try_set("code", "enter")?,
        KeyCode::Backspace => guard.try_set("code", "backspace")?,
        KeyCode::Delete => guard.try_set("code", "delete")?,
        KeyCode::Insert => guard.try_set("code", "insert")?,
        KeyCode::Esc => guard.try_set("code", "esc")?,

        KeyCode::CapsLock => guard.try_set("code", "capslock")?,
        KeyCode::ScrollLock => guard.try_set("code", "scrolllock")?,
        KeyCode::NumLock => guard.try_set("code", "numlock")?,
        KeyCode::PrintScreen => guard.try_set("code", "printscreen")?,
        KeyCode::Pause => guard.try_set("code", "pause")?,
        KeyCode::Menu => guard.try_set("code", "menu")?,
        KeyCode::KeypadBegin => guard.try_set("code", "keypad_begin")?,

        KeyCode::Null => guard.try_set("code", "null")?,
        _ => guard.try_set("code", "unknown")?,
    }
    Ok(())
}

fn set_mouse_btn(guard: &mut GuardMut<'_>, btn: MouseButton) -> Result<(), Error> {
    match btn {
        MouseButton::Left => guard.try_set("btn", "left")?,
        MouseButton::Right => guard.try_set("btn", "right")?,
        MouseButton::Middle => guard.try_set("btn", "middle")?,
    }
    Ok(())
}

fn table_from_event(ev: Event, root: &mut TableView) -> Result<(), Error> {
    match ev {
        Event::Key(key) => {
            root.try_push_table(0, 0, |t| {
                let mut guard = t.try_as_mut()?;
                guard.try_set("type", "key")?;

                match key.kind {
                    KeyEventKind::Press => guard.try_set("kind", "press")?,
                    KeyEventKind::Repeat => guard.try_set("kind", "repeat")?,
                    KeyEventKind::Release => guard.try_set("kind", "release")?,
                }

                set_key_code(&mut guard, key.code)?;

                guard.try_set("ctrl", key.modifiers.contains(KeyModifiers::CONTROL))?;
                guard.try_set("alt", key.modifiers.contains(KeyModifiers::ALT))?;
                guard.try_set("shift", key.modifiers.contains(KeyModifiers::SHIFT))?;
                Ok::<_, Error>(())
            })??;
        }
        Event::Resize(w, h) => {
            root.try_push_table(0, 0, |t| {
                let mut guard = t.try_as_mut()?;
                guard.try_set("type", "resize")?;
                guard.try_set("width", w as i32)?;
                guard.try_set("height", h as i32)?;
                Ok::<_, Error>(())
            })??;
        }
        Event::Mouse(m) => {
            root.try_push_table(0, 0, |t| {
                let mut guard = t.try_as_mut()?;
                guard.try_set("type", "mouse")?;

                guard.try_set("col", m.column as i32)?;
                guard.try_set("row", m.row as i32)?;

                guard.try_set("ctrl", m.modifiers.contains(KeyModifiers::CONTROL))?;
                guard.try_set("alt", m.modifiers.contains(KeyModifiers::ALT))?;

                match m.kind {
                    MouseEventKind::Down(btn) => {
                        guard.try_set("kind", "down")?;
                        set_mouse_btn(&mut guard, btn)?;
                    }
                    MouseEventKind::Up(btn) => {
                        guard.try_set("kind", "up")?;
                        set_mouse_btn(&mut guard, btn)?;
                    }
                    MouseEventKind::Drag(btn) => {
                        guard.try_set("kind", "drag")?;
                        set_mouse_btn(&mut guard, btn)?;
                    }
                    MouseEventKind::Moved => {
                        guard.try_set("kind", "moved")?;
                    }
                    MouseEventKind::ScrollDown => {
                        guard.try_set("kind", "scroll_down")?;
                    }
                    MouseEventKind::ScrollUp => {
                        guard.try_set("kind", "scroll_up")?;
                    }
                    MouseEventKind::ScrollLeft => {
                        guard.try_set("kind", "scroll_left")?;
                    }
                    MouseEventKind::ScrollRight => {
                        guard.try_set("kind", "scroll_right")?;
                    }
                }

                Ok::<_, Error>(())
            })??;
        }
        Event::Paste(text) => {
            root.try_push_table(0, 0, |t| {
                let mut guard = t.try_as_mut()?;
                guard.try_set("type", "paste")?;
                guard.try_set("content", text)?;
                Ok::<_, Error>(())
            })??;
        }
        _ => {}
    }
    Ok(())
}
