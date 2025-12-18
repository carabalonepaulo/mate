local term = require 'term'
local Buffer = require 'term.buffer'

return function(w, h)
  local buf = Buffer.new(w, h)

  local current_fg = nil
  local current_bg = nil
  local current_attr = nil

  local function set_clip(x, y, cw, ch)
    buf:set_clip(x, y, cw, ch)
  end

  local function get_clip()
    return buf:get_clip()
  end

  local function move_to(nx, ny)
    buf:move_to(nx, ny)
  end

  local function move_to_col(col)
    buf:move_to_col(col)
  end

  local function move_to_next_line()
    buf:move_to_next_line()
  end

  local function set_style(fg, bg, attr)
    current_fg = fg
    current_bg = bg
    current_attr = attr

    buf:set_fg(fg)
    buf:set_bg(bg)
    buf:set_attr(attr)
  end

  local function get_bg()
    return current_bg
  end

  local function set_fg(fg)
    current_fg = fg
    buf:set_fg(fg)
  end

  local function get_fg()
    return current_fg
  end

  local function set_bg(bg)
    current_bg = bg
    buf:set_bg(bg)
  end

  local function get_attr()
    return current_attr
  end

  local function set_attr(attr)
    current_attr = attr
    buf:set_attr(attr)
  end

  local function reset_style()
    current_fg = nil
    current_bg = nil
    current_attr = nil
    buf:reset_style()
  end

  local function write(text)
    buf:write(text)
  end

  local function write_at(x, y, text)
    buf:write_at(x, y, text)
  end

  local function clear()
    buf:clear()
  end

  local function render_diff(other)
    term:render_diff(buf, other.inner())
  end

  return {
    inner = function() return buf end,
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
