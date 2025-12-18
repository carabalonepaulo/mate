package.loaded["mate.queue.circular"] = (function()
return function(capacity)
  assert(type(capacity) == 'number' and capacity > 0)

  local DUMMY = false

  local buffer = {}
  for i = 1, capacity do
    buffer[i] = DUMMY
  end

  local head = 1
  local tail = 1
  local size = 0

  local function push(value)
    buffer[tail] = value

    tail = tail + 1
    if tail > capacity then
      tail = 1
    end

    if size < capacity then
      size = size + 1
    else
      head = head + 1
      if head > capacity then
        head = 1
      end
    end
  end

  local function items()
    local i = 0
    return function()
      if i >= size then
        return nil
      end

      local current_idx = head + i
      if current_idx > capacity then
        current_idx = current_idx - capacity
      end

      i = i + 1
      return buffer[current_idx]
    end
  end

  local function peek()
    if size == 0 then
      return nil
    end
    return buffer[head]
  end

  local function last()
    if size == 0 then return nil end
    local idx = tail - 1
    if idx < 1 then idx = capacity end
    return buffer[idx]
  end

  local function length()
    return size
  end

  local function get_capacity()
    return capacity
  end

  return {
    push = push,
    items = items,
    peek = peek,
    last = last,
    length = length,
    capacity = get_capacity
  }
end

end)()
package.loaded["mate.queue.unbounded"] = (function()
return function()
  local buffer = {}
  local head = 1
  local tail = 1

  local function enqueue(value)
    buffer[tail] = value
    tail = tail + 1
    return true
  end

  local function dequeue()
    if head == tail then
      return nil
    end

    local value = buffer[head]
    buffer[head] = nil
    head = head + 1

    if head == tail then
      head = 1
      tail = 1
    end

    return value
  end

  local function peek()
    if head == tail then return nil end
    return buffer[head]
  end

  local function length()
    return tail - head
  end

  return {
    enqueue = enqueue,
    dequeue = dequeue,
    peek = peek,
    length = length
  }
end

end)()
package.loaded["mate.style"] = (function()
local utf8_pattern = '[%z\1-\127\194-\244][\128-\191]*'

local function utf8_len(str)
  local count = 0
  for _ in str:gmatch(utf8_pattern) do
    count = count + 1
  end
  return count
end

return function()
  local self_w, self_h = 0, 0
  local self_x, self_y = 0, 0

  local pt, pr, pb, pl = 0, 0, 0, 0
  local mt, mr, mb, ml = 0, 0, 0, 0
  local sfg, sbg, sattr = nil, nil, nil

  local border_enabled = false
  local border_char_v = '│'
  local border_char_h = '─'
  local border_tl, border_tr = '┌', '┐'
  local border_bl, border_br = '└', '┘'

  local self = {}

  self.width = function(w)
    self_w = w
    return self
  end

  self.height = function(h)
    self_h = h
    return self
  end

  self.x = function(x)
    self_x = x
    return self
  end

  self.y = function(y)
    self_y = y
    return self
  end

  self.at = function(x, y)
    self_x, self_y = x, y
    return self
  end

  self.center = function(external_w, external_h)
    assert(self_w > 0 and self_h > 0, 'style must be sized to be centered')
    self_x = math.floor((external_w / 2) - self_w / 2)
    self_y = math.floor((external_h / 2) - self_h / 2)
    return self
  end

  self.padding = function(t, r, b, l)
    if not r then r, b, l = t, t, t end
    pt, pr, pb, pl = t, r, b, l
    return self
  end

  self.margin = function(t, r, b, l)
    if not r then r, b, l = t, t, t end
    mt, mr, mb, ml = t, r, b, l
    return self
  end

  self.border = function(enable)
    border_enabled = enable
    return self
  end

  self.style = function(fg, bg, attr)
    sfg, sbg, sattr = fg, bg, attr
    return self
  end

  self.fg = function(fg)
    sfg = fg
    return self
  end

  self.bg = function(bg)
    sbg = bg
    return self
  end

  self.attr = function(attr)
    sattr = attr
    return self
  end

  self.get_right = function() return self_x + self_w end

  self.get_bottom = function() return self_y + self_h end

  self.get_dims = function() return self_x, self_y, self_w, self_h end

  self.draw = function(buf, content_fn)
    local old_fg = buf.get_fg()
    local old_bg = buf.get_bg()
    local old_attr = buf.get_attr()

    local bx = self_x + ml
    local by = self_y + mt
    local bw = self_w - (ml + mr)
    local bh = self_h - (mt + mb)

    if bw <= 0 or bh <= 0 then return self end

    if sfg then buf.set_fg(sfg) end
    if sbg then buf.set_bg(sbg) end
    if sattr and sattr ~= '' then buf.set_attr(sattr) end

    if sbg then
      for row = 0, bh - 1 do
        buf.move_to(bx, by + row)
        buf.write(string.rep(" ", bw))
      end
    end

    local b_offset = 0
    if border_enabled then
      b_offset = 1
      buf.move_to(bx, by)
      buf.write(border_tl .. string.rep(border_char_h, bw - 2) .. border_tr)

      buf.move_to(bx, by + bh - 1)
      buf.write(border_bl .. string.rep(border_char_h, bw - 2) .. border_br)

      for i = 1, bh - 2 do
        buf.move_to(bx, by + i); buf.write(border_char_v)
        buf.move_to(bx + bw - 1, by + i); buf.write(border_char_v)
      end
    end

    local ix = bx + pl + b_offset
    local iy = by + pt + b_offset
    local iw = bw - (pl + pr + (b_offset * 2))
    local ih = bh - (pt + pb + (b_offset * 2))

    if content_fn and iw > 0 and ih > 0 then
      local cx, cy, cw, ch = 0, 0, 0, 0
      cx, cy, cw, ch = buf.get_clip()
      buf.set_clip(ix, iy, iw, ih)

      content_fn(ix, iy, iw, ih)

      buf.set_clip(cx, cy, cw, ch)
    end

    buf.set_style(old_fg, old_bg, old_attr)

    return self
  end

  self.draw_text = function(buf, text)
    local text_w = utf8_len(text)
    local text_h = 1

    local b_offset = border_enabled and 1 or 0

    local inner_w = text_w + pl + pr + (b_offset * 2)
    local inner_h = text_h + pt + pb + (b_offset * 2)

    self_w = inner_w + ml + mr
    self_h = inner_h + mt + mb

    self.draw(buf, function(ix, iy, iw, ih)
      buf.move_to(ix, iy)
      buf.write(text)
    end)

    return self
  end

  return self
end

end)()
package.loaded["mate.batch"] = (function()
return function(...)
  local self = { id = 'batch', data = {} }
  self.push = function(msg)
    if msg ~= nil then
      table.insert(self.data, msg)
    end
  end

  local n = select('#', ...)
  local args = { ... }
  for i = 1, n do
    self.push(args[i])
  end

  return self
end

end)()
package.loaded["mate.buffer"] = (function()
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

end)()
package.loaded["mate.uid"] = (function()
local __uid = 0
return function()
  __uid = __uid + 1
  return __uid
end

end)()
package.loaded["mate.app"] = (function()
local UnboundedQueue = require 'mate.queue.unbounded'

local term = require 'term'
local Buffer = require 'mate.buffer'

return function(meta)
  term:enable_raw_mode()
  term:enter_alt_screen()
  term:enable_bracketed_paste()
  term:hide_cursor()
  term:move_cursor(0, 0)
  term:flush()

  local msgs = UnboundedQueue()
  local should_quit = false
  local should_redraw = true
  local model, init_cmd = meta.init()

  local w, h = term:get_size()
  local front_buffer = Buffer(w, h)
  local back_buffer = Buffer(w, h)

  local function dispatch(msg)
    if not msg then return end

    if msg.id == 'batch' then
      for _, m in ipairs(msg.data) do
        dispatch(m)
      end
    else
      if msg.id == 'quit' then
        should_quit = true
      end
      msgs.enqueue(msg)
    end
  end

  local function loop()
    if should_quit then
      return
    end

    local events, err = term:poll(10)
    if err then print(err) end

    for _, e in ipairs(events) do
      if e.type == 'key' then
        dispatch { id = 'key', data = e }
      elseif e.type == 'mouse' then
        dispatch { id = 'mouse', data = e }
      elseif e.type == 'paste' then
        dispatch { id = 'paste', data = e.content }
      elseif e.type == 'resize' then
        w, h = e.width, e.height
        front_buffer = Buffer(w, h)
        back_buffer = Buffer(w, h)
        term:clear()
        dispatch { id = 'window_size', data = { width = w, height = h } }
        should_redraw = true
      end
    end

    local msg
    local len = msgs.length()
    should_redraw = len > 0

    for i = 1, len do
      msg = msgs.dequeue()
      model, msg = meta.update(model, msg)
      dispatch(msg)
    end

    if should_redraw then
      back_buffer.clear()
      meta.view(model, back_buffer)
      back_buffer.render_diff(front_buffer)
      should_redraw = false
    end
  end

  dispatch(init_cmd)
  dispatch { id = 'window_size', data = { width = w, height = h } }

  repeat
    loop()
  until should_quit
end

end)()
package.loaded["mate.components.spinner"] = (function()
local STYLES = {
  { '⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷' },
  { '←', '↖', '↑', '↗', '→', '↘', '↓', '↙' },
  { 'b', 'ᓂ', 'q', 'ᓄ' },
  { 'd', 'ᓇ', 'p', 'ᓀ' },
  { '|', '/', '—', '\\' },
  { 'x', '+' },
  { '◰', '◳', '◲', '◱' },
  { '◴', '◷', '◶', '◵' },
  { '◐', '◓', '◑', '◒' },
  { 'd', '|', 'b', '|' },
  { 'q', '|', 'p', '|' },
  { 'ᓂ', '—', 'ᓄ', '—' },
  { 'ᓇ', '—', 'ᓀ', '—' },
  { '|', 'b', 'O', 'b' },
  { '_', 'o', 'O', 'o' },
  { '.', 'o', 'O', '@', '*', ' ' },
  { '▁', '▃', '▄', '▅', '▆', '▇', '█', '▇', '▆', '▅', '▄', '▃' },
  { '▉', '▊', '▋', '▌', '▍', '▎', '▏', '▎', '▍', '▌', '▋', '▊', '▉' }
}

local __uid = 0
local function uid()
  __uid = __uid + 1
  return __uid
end

return {
  init = function(tick_interval)
    local id = uid()
    return {
      uid = id,
      style = 1,
      idx = 1,
      len = #STYLES[1],
      enabled = false,
      last_tick = os.clock(),
      interval = tick_interval,

      messages = {
        start = { id = 'spinner:start', data = { uid = id } },
        stop = { id = 'spinner:stop', data = { uid = id } },
        style = function(style_idx)
          return { id = 'spinner:style', data = { uid = id, style = style_idx } }
        end,
      },
    }
  end,

  update = function(model, msg)
    if msg.id == 'spinner:start' and msg.data.uid == model.uid then
      model.enabled = true
      return model, { id = 'spinner:tick', data = { uid = model.uid } }
    elseif msg.id == 'spinner:stop' and msg.data.uid == model.uid then
      model.enabled = false
    elseif msg.id == 'spinner:style' and msg.data.uid == model.uid then
      model.style = msg.data.style
      model.idx = 1
      model.len = #STYLES[msg.data.style]
    elseif msg.id == 'spinner:tick' and msg.data.uid == model.uid and model.enabled then
      local now = os.clock()
      if now - model.last_tick >= model.interval then
        model.idx = model.idx + 1
        if model.idx > model.len then
          model.idx = 1
        end
        model.last_tick = now
      end
      return model, { id = 'spinner:tick', data = { uid = model.uid } }
    end
    return model, nil
  end,

  view = function(model, buf)
    buf.write(STYLES[model.style][model.idx])
  end,
}

end)()
package.loaded["mate.components.log"] = (function()
local CircularBuffer = require 'mate.queue.circular'

return {
  init = function()
    return CircularBuffer(16)
  end,

  update = function(model, msg)
    if msg.id == 'log:push' then
      model.push(msg.data)
    end
    return model, nil
  end,

  view = function(model, buf)
    buf.move_to_next_line()

    for line in model.items() do
      buf.move_to_col(2)

      local location, num, err = string.match(line, '^(.*:)(%d+): (.*)$')
      if location and num and err then
        buf.set_attr('dim')
        buf.write(location)
        buf.reset_style()
        buf.set_fg('#b37e49')
        buf.write(num)
        buf.reset_style()
        buf.set_attr('dim')
        buf.write(': ')
        buf.reset_style()
        buf.write(err)
        buf.move_to_next_line()
      else
        buf.write(line)
        buf.move_to_next_line()
      end
    end
  end,
}

end)()
package.loaded["mate.components.line_input"] = (function()
local uid = require 'mate.uid'
local utf8_pattern = '[%z\1-\127\194-\244][\128-\191]*'

local function pop_grapheme(s)
  local last_start = nil
  local i = 1

  for g in s:gmatch(utf8_pattern) do
    last_start = i
    i = i + #g
  end

  if not last_start then
    return s
  end

  return s:sub(1, last_start - 1)
end

local function is_text_input(code)
  if not code then return false end

  if code == 'enter'
      or code == 'backspace'
      or code == 'tab'
      or code == 'esc'
      or code == 'up'
      or code == 'down'
      or code == 'left'
      or code == 'right'
      or code == 'home'
      or code == 'end'
      or code == 'pageup'
      or code == 'pagedown'
      or code:match('^f%d+$') then
    return false
  end

  return true
end

return {
  init = function()
    local id = uid()
    return {
      uid = id,
      text = '',
      enabled = false,

      enable = { id = 'line_input:enable', data = { uid = id } },
      disable = { id = 'line_input:disable', data = { uid = id } },
      submit = { id = 'line_input:submit', data = { uid = id } },
    }
  end,

  update = function(model, msg)
    local id = msg.id

    if model.enabled and id == 'key' and msg.data.kind == 'press' then
      if msg.data.code == 'backspace' then
        model.text = pop_grapheme(model.text)
        return model
      end

      if msg.data.code == 'enter' then
        return model, model.submit
      end

      if is_text_input(msg.data.code)
          and not msg.data.ctrl
          and not msg.data.alt then
        model.text = model.text .. msg.data.code
        return model
      end
    end

    if not (msg.data and msg.data.uid == model.uid) then
      return model
    end

    if id == 'line_input:set_text' then
      model.text = msg.data.text
    elseif id == 'line_input:clear' then
      model.text = ''
    elseif id == 'line_input:enable' then
      model.enabled = true
    elseif id == 'line_input:disable' then
      model.enabled = false
    end

    return model
  end,

  view = function(model, buf)
    buf.write(model.text)
  end
}

end)()