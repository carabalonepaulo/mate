local utf8_pattern = '[%z\1-\127\194-\244][\128-\191]*'
local term = require 'term'

local NIL_STYLE = {}

return function(w, h)
  local rows = {}
  for y = 1, h do
    rows[y] = {}
    for x = 1, w do
      rows[y][x] = { char = ' ', fg = nil, bg = nil, attr = '' }
    end
  end

  local cx, cy = 1, 1
  local current_fg = nil
  local current_bg = nil
  local current_attr = ''

  local clip_x, clip_y, clip_w, clip_h = 1, 1, w, h

  local function set_clip(x, y, cw, ch)
    clip_x, clip_y, clip_w, clip_h = x, y, cw, ch
  end

  local function get_clip()
    return clip_x, clip_y, clip_w, clip_h
  end

  local function move_to(nx, ny)
    if nx >= 1 and nx <= w then cx = nx end
    if ny >= 1 and ny <= h then cy = ny end
  end

  local function move_to_col(col)
    if col >= 1 and col <= w then
      cx = col
    end
  end

  local function move_to_next_line()
    cx = 1
    cy = cy + 1
  end

  local function set_style(fg, bg, attr)
    current_fg = fg
    current_bg = bg
    current_attr = attr or ''
  end

  local function get_bg()
    return current_bg
  end

  local function set_fg(fg)
    current_fg = fg
  end

  local function get_fg()
    return current_fg
  end

  local function set_bg(bg)
    current_bg = bg
  end

  local function get_attr()
    return current_attr
  end

  local function set_attr(attr)
    current_attr = attr or ''
  end

  local function reset_style()
    current_fg = nil
    current_bg = nil
    current_attr = ''
  end

  local function write(text)
    local x1, y1 = clip_x, clip_y
    local x2, y2 = clip_x + clip_w - 1, clip_y + clip_h - 1

    for char in text:gmatch(utf8_pattern) do
      if char == '\n' then
        cx = 1
        cy = cy + 1
      else
        if cx > w then
          cx = 1
          cy = cy + 1
        end

        if cy > h then break end

        if cx >= x1 and cx <= x2 and cy >= y1 and cy <= y2 then
          local cell = rows[cy][cx]
          cell.char = char
          cell.fg = current_fg
          cell.bg = current_bg
          cell.attr = current_attr
        end

        cx = cx + 1
      end
    end
  end

  local function write_at(x, y, text)
    local old_x, old_y = cx, cy
    move_to(x, y)
    write(text)
    move_to(old_x, old_y)
  end

  local function clear()
    for y = 1, h do
      local row = rows[y]
      for x = 1, w do
        local cell = row[x]
        cell.char = ' '
        cell.fg = nil
        cell.bg = nil
        cell.attr = ''
      end
    end
    cx, cy = 1, 1
  end

  local function render_diff(other)
    local curr_x, curr_y = -99, -99
    local last_fg, last_bg, last_attr = NIL_STYLE, NIL_STYLE, NIL_STYLE

    term:hide_cursor()

    for y = 1, h do
      local row_back = rows[y]
      local row_front = other.rows[y]

      for x = 1, w do
        local b = row_back[x]
        local f = row_front[x]

        local changed = (b.char ~= f.char) or
            (b.fg ~= f.fg) or
            (b.bg ~= f.bg) or
            (b.attr ~= f.attr)

        if changed then
          local target_x = x - 1
          local target_y = y - 1

          local style_changed = (b.fg ~= last_fg or b.bg ~= last_bg or b.attr ~= last_attr)

          if style_changed or target_x ~= curr_x or target_y ~= curr_y then
            term:move_cursor(target_x, target_y)
            curr_x = target_x
            curr_y = target_y
          end

          if style_changed then
            term:reset_style()
            term:set_style(b.fg, b.bg, b.attr)

            last_fg = b.fg
            last_bg = b.bg
            last_attr = b.attr
          end

          term:print(b.char)

          curr_x = curr_x + 1

          f.char = b.char
          f.fg = b.fg
          f.bg = b.bg
          f.attr = b.attr
        end
      end
    end

    term:reset_style()
    term:flush()
  end

  return {
    rows = rows,
    clear = clear,
    write = write,
    write_at = write_at,

    set_clip = set_clip,
    get_clip = get_clip,

    set_style = set_style,
    reset_style = reset_style,
    get_fg = get_fg,
    set_fg = set_fg,
    get_bg = get_bg,
    set_bg = set_bg,
    get_attr = get_attr,
    set_attr = set_attr,

    move_to = move_to,
    move_to_col = move_to_col,
    move_to_next_line = move_to_next_line,
    render_diff = render_diff,
  }
end
