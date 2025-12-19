package.loaded["mate.ds.stack"] = (function()
return function()
  local len = 0
  local items = {}

  local function push(value)
    len = len + 1
    items[len] = value
  end

  local function pop()
    if len == 0 then return nil end
    local value = items[len]
    items[len] = nil
    len = len - 1
    return value
  end

  return {
    push = push,
    pop = pop,
  }
end

end)()
package.loaded["mate.ds.queue.circular"] = (function()
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
package.loaded["mate.ds.queue.unbounded"] = (function()
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
package.loaded["mate.ds.queue.bounded"] = (function()
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

  local function enqueue(value)
    if size == capacity then
      return false
    end

    buffer[tail] = value
    tail = tail + 1
    if tail > capacity then
      tail = 1
    end

    size = size + 1
    return true
  end

  local function dequeue()
    if size == 0 then
      return nil
    end

    local value = buffer[head]
    buffer[head] = DUMMY
    head = head + 1
    if head > capacity then
      head = 1
    end

    size = size - 1
    return value
  end

  local function peek()
    if size == 0 then
      return nil
    end
    return buffer[head]
  end

  local function length()
    return size
  end

  local function capacity()
    return capacity
  end

  return {
    enqueue = enqueue,
    dequeue = dequeue,
    peek = peek,
    length = length,
    capacity = capacity
  }
end

end)()
package.loaded["mate.input"] = (function()
local ALIAS = {
  ['backtab'] = 'tab',
  [' '] = 'space',
}

return {
  stringify_key = function(ev)
    local parts = {}
    if ev.ctrl then
      table.insert(parts, 'ctrl')
    end
    if ev.alt then
      table.insert(parts, 'alt')
    end
    if ev.shift then
      table.insert(parts, 'shift')
    end
    table.insert(parts, string.lower(ALIAS[ev.code] or ev.code))
    return table.concat(parts, '+')
  end,

  hit = function(msg, key_str)
    return msg.id == 'key' and msg.data.string == key_str and (msg.data.kind == 'press' or msg.data.kind == 'repeat')
  end,

  pressed = function(msg, key_str)
    return msg.id == 'key' and msg.data.string == key_str and msg.data.kind == 'press'
  end,

  released = function(msg, key_str)
    return msg.id == 'key' and msg.data.string == key_str and msg.data.kind == 'release'
  end,

  repeated = function(msg, key_str)
    return msg.id == 'key' and msg.data.string == key_str and msg.data.kind == 'repeat'
  end,

  num = function(msg)
    local press = msg.id == 'key' and (msg.data.kind == 'press' or msg.data.kind == 'repeat')
    local is_num = press and msg.data.code >= '0' and msg.data.code <= '9'
    return is_num and tonumber(msg.data.code) or nil
  end,

  char = function(msg)
    if msg.id ~= 'key' then return nil end
    if msg.data.ctrl or msg.data.alt then return nil end

    local code = msg.data.code
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
      return nil
    end

    return code
  end,
}

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
    buf:push_style()

    local bx = self_x + ml
    local by = self_y + mt
    local bw = self_w - (ml + mr)
    local bh = self_h - (mt + mb)

    if bw <= 0 or bh <= 0 then return self end

    if sfg then buf:set_fg(sfg) end
    if sbg then buf:set_bg(sbg) end
    if sattr then buf:set_attr(sattr) end

    if sbg then
      for row = 0, bh - 1 do
        buf:move_to(bx, by + row)
        buf:write(string.rep(" ", bw))
      end
    end

    local b_offset = 0
    if border_enabled then
      b_offset = 1
      buf:move_to(bx, by)
      buf:write(border_tl .. string.rep(border_char_h, bw - 2) .. border_tr)

      buf:move_to(bx, by + bh - 1)
      buf:write(border_bl .. string.rep(border_char_h, bw - 2) .. border_br)

      for i = 1, bh - 2 do
        buf:move_to(bx, by + i); buf:write(border_char_v)
        buf:move_to(bx + bw - 1, by + i); buf:write(border_char_v)
      end
    end

    local ix = bx + pl + b_offset
    local iy = by + pt + b_offset
    local iw = bw - (pl + pr + (b_offset * 2))
    local ih = bh - (pt + pb + (b_offset * 2))

    if content_fn and iw > 0 and ih > 0 then
      local cx, cy, cw, ch = 0, 0, 0, 0
      cx, cy, cw, ch = buf:get_clip()
      buf:set_clip(ix, iy, iw, ih)

      content_fn(ix, iy, iw, ih)

      buf:set_clip(cx, cy, cw, ch)
    end

    buf:pop_style()
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
      buf:move_to(ix, iy)
      buf:write(text)
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
package.loaded["mate.uid"] = (function()
local __uid = 0
return function()
  __uid = __uid + 1
  return __uid
end

end)()
package.loaded["mate.components.log"] = (function()
local CircularBuffer = require 'mate.ds.queue.circular'

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
    buf:move_to_next_line()

    for line in model.items() do
      buf:move_to_col(2)

      local location, num, err = string.match(line, '^(.*:)(%d+): (.*)$')
      if location and num and err then
        buf:set_attr('dim')
        buf:write(location)
        buf:reset_style()
        buf:set_fg('#b37e49')
        buf:write(num)
        buf:reset_style()
        buf:set_attr('dim')
        buf:write(': ')
        buf:reset_style()
        buf:write(err)
        buf:move_to_next_line()
      else
        buf:write(line)
        buf:move_to_next_line()
      end
    end
  end,
}

end)()
package.loaded["mate.app"] = (function()
local BoundedQueue   = require 'mate.ds.queue.bounded'

local input          = require 'mate.input'
local term           = require 'term'
local time           = require 'term.time'
local Buffer         = require 'term.buffer'
local Log            = require 'mate.components.log'
local Stack          = require 'mate.ds.stack'

local DEFAULT_CONFIG = {
  log_key = 'f12',
  fps = 60,
  max_msgs = 4096,
  term_poll_timeout = 1,
}

local function init_term()
  term:enable_raw_mode()
  term:enter_alt_screen()
  term:enable_bracketed_paste()
  term:hide_cursor()
  term:move_cursor(0, 0)
  term:flush()
end

local function deinit_term()
  term:disable_raw_mode()
  term:leave_alt_screen()
  term:disable_bracketed_paste()
  term:show_cursor()
  term:flush()
end

local function exit_with_err(err)
  deinit_term()
  term:println(tostring(err))
  term:println(debug.traceback())
  os.exit(false)
end

local function load_confg(meta_config)
  local config = {}

  for k, v in pairs(DEFAULT_CONFIG) do
    config[k] = v
  end

  if meta_config then
    local err_msg = 'invalid config value for "%s": expected %s, got %s'
    for k, v in pairs(meta_config) do
      if DEFAULT_CONFIG[k] == nil then
        error(string.format('unknown config key "%s"', k), 2)
      end

      local nty = type(v)
      local oty = type(DEFAULT_CONFIG[k])
      if nty ~= oty then
        error(string.format(err_msg, k, oty, nty), 2)
      end

      config[k] = v
    end
  end

  return config
end

local function run(meta)
  init_term()

  local config = load_confg(meta.config)
  local msgs = BoundedQueue(config.max_msgs)
  local should_quit = false
  local model, init_cmd = meta.init()

  local w, h = term:get_size()
  local front_buffer = Buffer.new(w, h)
  local back_buffer = Buffer.new(w, h)
  local last_tick = time.now()
  local frame_time = 1 / config.fps
  local last_render = 0

  local tick_msg_data = { now = 0, dt = 0, budget = 0 }
  local tick_msg = { id = 'sys:tick', data = tick_msg_data }

  local log_model, log_cmd = Log.init()
  local display_log = false
  local dispatch_stack = Stack()

  local function dispatch(initial)
    if not initial then return end
    dispatch_stack.push(initial)

    local id, data
    local msg = dispatch_stack.pop()

    while msg do
      id = msg.id

      if id == 'batch' then
        data = msg.data
        for i = #data, 1, -1 do
          dispatch_stack.push(data[i])
        end
        data = nil
      else
        if not msgs.enqueue(msg) then
          error('msg queue overflow')
        end
      end

      msg = dispatch_stack.pop()
    end
  end

  local function observe(msg)
    log_model = Log.update(log_model, msg)

    if msg.id == 'quit' then
      should_quit = true
    end
  end

  local function loop()
    local frame_start = time.now()

    local events, err = term:poll(config.term_poll_timeout)
    if err then exit_with_err(err) end

    for _, e in ipairs(events) do
      if e.type == 'key' then
        ---@diagnostic disable-next-line: inject-field
        e.string = input.stringify_key(e)

        if e.string == config.log_key and e.kind == 'press' then
          display_log = not display_log
        elseif e.ctrl and e.code == 'c' and e.kind == 'press' then
          dispatch { id = 'quit' }
        end

        dispatch { id = 'key', data = e }
      elseif e.type == 'mouse' then
        dispatch { id = 'mouse', data = e }
      elseif e.type == 'paste' then
        dispatch { id = 'paste', data = e.content }
      elseif e.type == 'resize' then
        w, h = e.width, e.height
        back_buffer:resize(w, h)
        front_buffer:resize(w, h)
        term:clear()
        dispatch { id = 'sys:resize', data = { width = w, height = h } }
      end
    end

    local msg
    local len = msgs.length()

    local now = time.now()
    local dt = now - last_tick
    last_tick = now
    local time_spent = now - frame_start
    local budget = math.max(0, frame_time - time_spent)

    tick_msg_data.now = now
    tick_msg_data.dt = dt
    tick_msg_data.budget = budget
    model, msg = meta.update(model, tick_msg)
    dispatch(msg)

    for i = 1, len do
      msg = msgs.dequeue()
      observe(msg)
      model, msg = meta.update(model, msg)
      dispatch(msg)
    end

    local render_now = time.now()
    if render_now - last_render >= frame_time then
      back_buffer:clear()
      if display_log then
        Log.view(log_model, back_buffer)
      else
        meta.view(model, back_buffer)
      end
      term:render_diff(back_buffer, front_buffer)
      last_render = render_now
    end
  end

  dispatch(init_cmd)
  dispatch(log_cmd)
  dispatch {
    id = 'sys:ready',
    data = {
      width = w,
      height = h,
      dispatch = dispatch
    }
  }

  repeat
    loop()
  until should_quit

  deinit_term()
end

return function(meta)
  local ok, err = pcall(run, meta)
  if not ok then exit_with_err(err) end
end

end)()
package.loaded["mate.components.timer"] = (function()
local Batch = require 'mate.batch'
local uid = require 'mate.uid'
local time = require 'term.time'

return {
  init = function(interval)
    local id = uid()
    return {
      uid = id,
      last_tick = 0,
      interval = interval,

      start = { id = 'timer:start', data = id },
      stop = { id = 'timer:stop', data = id },
      timeout = { id = 'timer:timeout', data = id }
    }
  end,

  update = function(model, msg)
    local id = msg.id

    if id == 'timer:start' and msg.data == model.uid then
      model.last_tick = time.now()
      return model
    elseif id == 'timer:stop' and msg.data == model.uid then
      model.last_tick = -1
      return model
    elseif id == 'sys:tick' and model.last_tick > 0 then
      local batch = Batch()
      local now = msg.data.now
      if now - model.last_tick >= model.interval then
        model.last_tick = now
        batch.push(model.timeout)
      end
      return model, batch
    end

    return model
  end,
}

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

local uid = require 'mate.uid'

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
      return model
    elseif msg.id == 'spinner:stop' and msg.data.uid == model.uid then
      model.enabled = false
    elseif msg.id == 'spinner:style' and msg.data.uid == model.uid then
      model.style = msg.data.style
      model.idx = 1
      model.len = #STYLES[msg.data.style]
    elseif msg.id == 'sys:tick' and model.enabled then
      local now = msg.data.now
      if now - model.last_tick >= model.interval then
        model.idx = model.idx + 1
        if model.idx > model.len then
          model.idx = 1
        end
        model.last_tick = now
      end
      return model
    end
    return model, nil
  end,

  view = function(model, buf)
    buf:write(STYLES[model.style][model.idx])
  end,
}

end)()
package.loaded["mate.components.line_input"] = (function()
local uid = require 'mate.uid'
local utf8_pattern = '[%z\1-\127\194-\244][\128-\191]*'
local input = require 'mate.input'

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

return {
  init = function()
    local id = uid()
    return {
      uid = id,
      text = '',
      placeholder = '',
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

      local c = input.char(msg)
      if c then
        model.text = model.text .. c
        return model
      end
    end

    if id == 'paste' then
      model.text = model.text .. msg.data
      return model
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
    if model.text == '' then
      buf:set_attr('dim')
      buf:write(model.placeholder)
      buf:set_attr(nil)
    else
      buf:write(model.text)
    end
  end
}

end)()