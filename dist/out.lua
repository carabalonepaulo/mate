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

  local function at(idx)
    assert(idx >= 1 and idx <= size, string.format('index %d out of bounds, len is %d', idx, size))

    local physical = head + idx - 1
    if physical > capacity then
      physical = physical - capacity
    end
    return buffer[physical]
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
    at = at,
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
    if msg.data.ctrl and not msg.data.alt then return nil end

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
package.loaded["mate.components.indexed_view"] = (function()
local input = require 'mate.input'
local uid = require 'mate.uid'

local function clamp(value, min, max)
  if value < min then
    return min
  elseif value > max then
    return max
  end
  return value
end

return {
  init = function()
    local id = uid()
    return {
      uid = id,
      len = 0,
      offset = 0,
      height = 0,
      user_scrolled = false,

      msg = {
        set_len = function(len)
          return { id = 'indexed_view:set_len', data = { uid = id, len = len } }
        end,
        set_height = function(h)
          return { id = 'indexed_view:set_height', data = { uid = id, height = h } }
        end,
        reset = { id = 'indexed_view:reset', data = { uid = id } },
        sync = function(len, height)
          return { id = 'indexed_view:sync', data = { uid = id, len = len, height = height } }
        end,
        scroll_to = function(idx)
          return { id = 'indexed_view:scroll_to', data = { uid = id, index = idx } }
        end
      },
    }
  end,

  update = function(model, msg)
    if msg.id == 'indexed_view:set_len' and msg.data.uid == model.uid then
      model.len = msg.data.len
    elseif msg.id == 'indexed_view:set_height' and msg.data.uid == model.uid then
      model.height = msg.data.height
    elseif msg.id == 'indexed_view:reset' and msg.data.uid == model.uid then
      model.len = 0
      model.offset = 0
      model.user_scrolled = false
    elseif msg.id == 'indexed_view:sync' and msg.data.uid == model.uid then
      model.len = msg.data.len
      model.height = msg.data.height
    elseif msg.id == 'indexed_view:scroll_to' and msg.data.uid == model.uid then
      local max_offset = math.max(0, model.len - model.height)
      model.user_scrolled = true
      local target_offset = msg.data.index - math.floor(model.height / 2)
      model.offset = clamp(target_offset, 0, max_offset)
    elseif input.pressed(msg, 'up') then
      model.offset = model.offset - 1
      model.user_scrolled = true
    elseif input.pressed(msg, 'down') then
      model.offset = model.offset + 1
      model.user_scrolled = true
    elseif input.pressed(msg, 'home') then
      model.offset = 0
      model.user_scrolled = true
    elseif input.pressed(msg, 'end') then
      model.offset = math.huge
      model.user_scrolled = false
    end

    local max_offset = math.max(0, model.len - model.height)
    if model.len <= model.height then
      model.offset = 0
      model.user_scrolled = false
    else
      if model.user_scrolled then
        model.offset = clamp(model.offset, 0, max_offset)
        if model.offset == max_offset then model.user_scrolled = false end
      else
        model.offset = max_offset
      end
    end

    return model
  end,

  view = function(model, buf, fn)
    for i = 1, model.height do
      local item_idx = model.offset + i
      if item_idx > model.len then
        break
      end
      buf:with_offset(0, i - 1, function()
        fn(item_idx)
      end)
    end
  end,
}

end)()
package.loaded["mate.components.log"] = (function()
local CircularBuffer = require 'mate.ds.queue.circular'
local IndexedView = require 'mate.components.indexed_view'

return {
  init = function(cap)
    local view = IndexedView.init()
    return {
      ready = false,
      size = { 0, 0 },
      view = view,
      lines = CircularBuffer(cap),
    }
  end,

  update = function(model, msg)
    model.view = IndexedView.update(model.view, msg)

    if msg.id == 'log:push' then
      local location, num, err = string.match(msg.data, '^(.*:)(%d+): (.*)$')
      if location then
        model.lines.push {
          { text = location,      attr = 'dim' },
          { text = tostring(num), fg = '#b37e49' },
          { text = ': ',          attr = 'dim' },
          { text = err },
        }
      else
        model.lines.push { { text = msg.data } }
      end
      model.view = IndexedView.update(model.view, model.view.msg.set_len(model.lines.length()))
    elseif msg.id == 'sys:ready' then
      model.size[0] = msg.data.width
      model.size[1] = msg.data.height
      model.ready = true
      model.view = IndexedView.update(model.view, model.view.msg.set_height(msg.data.height - 2))
    elseif msg.id == 'sys:resize' then
      model.size[0] = msg.data.width
      model.size[1] = msg.data.height
      model.view = IndexedView.update(model.view, model.view.msg.set_height(msg.data.height - 2))
    elseif msg.id ~= 'sys:tick' then
      if msg.id == 'key' then
        if not (msg.data.code == 'up' or msg.data.code == 'down') then
          model.lines.push {
            { text = '[' },
            { text = 'key',          fg = '#9e624a' },
            { text = ':' },
            { text = msg.data.kind,  fg = '#968d89' },
            { text = '] ' },
            { text = msg.data.string },
          }
        end
      else
        local prefix, sufix = string.match(msg.id, '^(.*):(.*)$')
        if prefix then
          model.lines.push {
            { text = '[' },
            { text = prefix, fg = '#9e8c4a' },
            { text = ':' },
            { text = sufix,  fg = '#909e4a' },
            { text = '] ' },
          }
        else
          model.lines.push {
            { text = '[' },
            { text = msg.id, fg = '#9e8c4a' },
            { text = '] ' },
          }
        end
      end
      model.view = IndexedView.update(model.view, model.view.msg.set_len(model.lines.length()))
    end

    return model
  end,

  view = function(model, buf)
    if not model.ready then return end

    IndexedView.view(model.view, buf, function(idx)
      for _, span in ipairs(model.lines.at(idx)) do
        buf:set_fg(span.fg)
        buf:set_bg(span.bg)
        buf:set_attr(span.attr)
        buf:write(span.text)
      end
    end)

    buf:set_fg(nil)
    buf:set_bg(nil)
    buf:set_attr(nil)
  end,
}

end)()
package.loaded["mate.box"] = (function()
local unicode = require 'term.unicode'
local layout = require 'term.layout'

local visual_width = unicode.width
local get_horizontal_line = layout.horizontal_line

local function split_lines(str)
  local lines = {}
  if str == '' then return lines end
  for line in (str .. '\n'):gmatch('(.-)\n') do
    table.insert(lines, line)
  end
  return lines
end

return function()
  local cfg = {
    w = 0,
    h = 0,
    pt = 0,
    pr = 0,
    pb = 0,
    pl = 0,
    mt = 0,
    mr = 0,
    mb = 0,
    ml = 0,
    sfg = nil,
    sbg = nil,
    sattr = nil,
    border_enabled = false,
    border_color = nil,
    border_chars = { v = '│', h = '─', tl = '┌', tr = '┐', bl = '└', br = '┘' }
  }

  local self = {}

  self.width = function(w)
    cfg.w = w
    return self
  end

  self.height = function(h)
    cfg.h = h
    return self
  end

  self.padding = function(t, r, b, l)
    if not r then r, b, l = t, t, t end
    cfg.pt, cfg.pr, cfg.pb, cfg.pl = t, r, b, l
    return self
  end

  self.margin = function(t, r, b, l)
    if not r then r, b, l = t, t, t end
    cfg.mt, cfg.mr, cfg.mb, cfg.ml = t, r, b, l
    return self
  end

  self.border = function(enable, color)
    cfg.border_enabled = enable
    if color then cfg.border_color = color end
    return self
  end

  self.border_color = function(color)
    cfg.border_color = color
    return self
  end

  self.border_chars = function(v, h, tl, tr, bl, br)
    cfg.border_chars = { v = v, h = h, tl = tl, tr = tr, bl = bl, br = br }
    return self
  end

  self.style = function(fg, bg, attr)
    cfg.sfg, cfg.sbg, cfg.sattr = fg, bg, attr
    return self
  end

  self.fg = function(fg)
    cfg.sfg = fg
    return self
  end

  self.bg = function(bg)
    cfg.sbg = bg
    return self
  end

  self.attr = function(attr)
    cfg.sattr = attr
    return self
  end

  self.resolve = function(content_w, content_h)
    content_w, content_h = content_w or 0, content_h or 0
    local b = cfg.border_chars

    local pieces = {
      v = split_lines(b.v),
      h = split_lines(b.h),
      tl = split_lines(b.tl),
      tr = split_lines(b.tr),
      bl = split_lines(b.bl),
      br = split_lines(b.br)
    }

    local b_wl = cfg.border_enabled and math.max(visual_width(b.v), visual_width(b.tl), visual_width(b.bl)) or 0
    local b_wr = cfg.border_enabled and math.max(visual_width(b.v), visual_width(b.tr), visual_width(b.br)) or 0
    local b_ht = cfg.border_enabled and math.max(#pieces.tl, #pieces.tr, #pieces.h) or 0
    local b_hb = cfg.border_enabled and math.max(#pieces.bl, #pieces.br, #pieces.h) or 0

    local bw = (cfg.w > 0) and math.max(b_wl + b_wr + cfg.pl + cfg.pr, cfg.w - cfg.ml - cfg.mr)
        or (content_w + cfg.pl + cfg.pr + b_wl + b_wr)
    local bh = (cfg.h > 0) and math.max(b_ht + b_hb + cfg.pt + cfg.pb, cfg.h - cfg.mt - cfg.mb)
        or (content_h + cfg.pt + cfg.pb + b_ht + b_hb)

    return {
      total_w = bw + cfg.ml + cfg.mr,
      total_h = bh + cfg.mt + cfg.mb,
      bx = cfg.ml,
      by = cfg.mt,
      bw = bw,
      bh = bh,
      ix = cfg.ml + cfg.pl + b_wl,
      iy = cfg.mt + cfg.pt + b_ht,
      iw = math.max(0, bw - (cfg.pl + cfg.pr + b_wl + b_wr)),
      ih = math.max(0, bh - (cfg.pt + cfg.pb + b_ht + b_hb)),
      b_ht = b_ht,
      b_hb = b_hb,
      b_wl = b_wl,
      b_wr = b_wr,
      pieces = pieces,
      cfg = cfg
    }
  end

  self.draw = function(buf, layout, content_fn)
    local c = layout.cfg
    buf:push_style()

    if c.sbg then
      buf:set_bg(c.sbg)
      for row = 0, layout.bh - 1 do
        buf:move_to(layout.bx, layout.by + row)
        buf:write(string.rep(' ', layout.bw))
      end
    end

    if c.border_enabled then
      buf:set_fg(c.border_color or c.sfg)
      local p = layout.pieces

      for i = 1, layout.b_ht do
        local lt, rt, mid = p.tl[i] or '', p.tr[i] or '', p.h[i] or ''
        local line = get_horizontal_line(lt, rt, mid, layout.bw)
        buf:move_to(layout.bx, layout.by + i - 1)
        buf:write(line)
      end

      local by_bot = layout.by + layout.bh - layout.b_hb
      for i = 1, layout.b_hb do
        local lb, rb, mid = p.bl[i] or '', p.br[i] or '', p.h[i] or ''
        local line = get_horizontal_line(lb, rb, mid, layout.bw)
        buf:move_to(layout.bx, by_bot + i - 1)
        buf:write(line)
      end

      local w_v = visual_width(c.border_chars.v)
      for i = layout.b_ht, layout.bh - layout.b_hb - 1 do
        for line_idx, line in ipairs(p.v) do
          buf:move_to(layout.bx, layout.by + i + line_idx - 1)
          buf:write(line)
          buf:move_to(layout.bx + layout.bw - w_v, layout.by + i + line_idx - 1)
          buf:write(line)
        end
      end
    end

    if content_fn and layout.iw > 0 and layout.ih > 0 then
      buf:set_fg(c.sfg)
      buf:set_attr(c.sattr)

      buf:with_offset(layout.ix, layout.iy, function()
        buf:with_clip(0, 0, layout.iw, layout.ih, function()
          content_fn(layout.iw, layout.ih)
        end)
      end)
    end

    buf:pop_style()
    return self
  end

  return self
end

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
  max_logs = 256,
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

  local log_model, log_cmd = Log.init(config.max_logs)
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
        back_buffer:clear()
        front_buffer:resize(w, h)
        front_buffer:clear()
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

      msg = {
        start = { id = 'timer:start', data = { uid = id } },
        stop = { id = 'timer:stop', data = { uid = id } },
        timeout = { id = 'timer:timeout', data = { uid = id } }
      }
    }
  end,

  update = function(model, msg)
    local id = msg.id

    if id == 'timer:start' and msg.data.uid == model.uid then
      model.last_tick = time.now()
      return model
    elseif id == 'timer:stop' and msg.data.uid == model.uid then
      model.last_tick = -1
      return model
    elseif id == 'sys:tick' and model.last_tick > 0 then
      local batch = Batch()
      local now = msg.data.now
      if now - model.last_tick >= model.interval then
        model.last_tick = now
        batch.push(model.msg.timeout)
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
local unicode = require 'term.unicode'
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

      msg = {
        enable = { id = 'line_input:enable', data = { uid = id } },
        disable = { id = 'line_input:disable', data = { uid = id } },
        clear = { id = 'line_input:clear', data = { uid = id } },
        text_changed = function(text)
          return { id = 'line_input:text_changed', data = { uid = id, text = text } }
        end,
        submit = function(text)
          return { id = 'line_input:submit', data = { uid = id, text = text } }
        end
      }
    }
  end,

  update = function(model, msg)
    local id = msg.id

    if model.enabled and id == 'key' and msg.data.kind == 'press' then
      if msg.data.code == 'backspace' then
        model.text = unicode.pop_grapheme(model.text)
        return model, model.msg.text_changed(model.text)
      end

      if msg.data.code == 'enter' then
        return model, model.msg.submit(model.text)
      end

      local c = input.char(msg)
      if c then
        model.text = model.text .. c
        return model, model.msg.text_changed(model.text)
      end
    end

    if id == 'paste' then
      model.text = model.text .. msg.data
      return model, model.msg.text_changed(model.text)
    end

    if not (msg.data and msg.data.uid == model.uid) then
      return model
    end

    if id == 'line_input:set_text' then
      model.text = msg.data
    elseif id == 'line_input:clear' then
      model.text = ''
      return model, model.msg.text_changed(model.text)
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
package.loaded["mate.components.progress_bar"] = (function()
local unicode = require 'term.unicode'
local layout = require 'term.layout'
local uid = require 'mate.uid'

return {
  init = function(opts)
    opts = opts or {}
    local id = uid()
    return {
      uid = id,
      value = opts.value or 0,
      max = opts.max or 100,

      char_fill = opts.fill or '█',
      char_empty = opts.empty or '░',
      char_left = opts.left or '',
      char_right = opts.right or '',
      show_percentage = opts.show_percentage ~= false,

      msg = {
        set = function(value, max)
          return { id = 'progress_bar:set', data = { uid = id, value = value, max = max } }
        end,
        set_value = function(value)
          return { id = 'progress_bar:set_value', data = { uid = id, value = value } }
        end,
        set_max = function(max)
          return { id = 'progress_bar:set_max', data = { uid = id, max = max } }
        end,
        set_percent = function(p)
          return { id = 'progress_bar:set_percent', data = { uid = id, percent = math.min(math.max(p, 0), 1) } }
        end,
      }
    }
  end,

  update = function(model, msg)
    if msg.data and msg.data.uid == model.uid then
      if msg.id == 'progress_bar:set' then
        model.value = msg.data.value
        model.max = msg.data.max
      elseif msg.id == 'progress_bar:set_value' then
        model.value = msg.data.value
      elseif msg.id == 'progress_bar:set_max' then
        model.max = msg.data.max
      elseif msg.id == 'progress_bar:set_percent' then
        model.value = msg.data.percent * model.max
      end

      if model.value < 0 then model.value = 0 end
      if model.max < 0 then model.max = 0 end
      if model.value > model.max and model.max > 0 then model.value = model.max end
    end
    return model
  end,

  view = function(model, buf, w)
    local percent = 0
    if model.max > 0 then
      percent = math.min(math.max(model.value / model.max, 0), 1)
    end

    local label = ''
    if model.show_percentage then
      label = string.format(' %3d%%', math.floor(percent * 100))
    end
    local w_label = unicode.width(label)

    local w_bar = w - w_label

    if w_bar < 2 and model.show_percentage then
      label = ''
      w_label = 0
      w_bar = w
    end

    local w_left = unicode.width(model.char_left)
    local w_right = unicode.width(model.char_right)
    local w_inner = w_bar - w_left - w_right

    if w_inner < 0 then return end

    local w_filled = math.floor(percent * w_inner)
    local w_empty = w_inner - w_filled

    local c_fill = (unicode.width(model.char_fill) > 0) and model.char_fill or ' '
    local c_empty = (unicode.width(model.char_empty) > 0) and model.char_empty or ' '

    buf:write(model.char_left)

    if w_filled > 0 then
      buf:write(layout.horizontal_line('', '', c_fill, w_filled))
    end

    if w_empty > 0 then
      buf:write(layout.horizontal_line('', '', c_empty, w_empty))
    end

    buf:write(model.char_right)
    buf:write(label)
  end
}

end)()
package.loaded["mate.components.list"] = (function()
local IndexedView = require 'mate.components.indexed_view'
local Batch = require 'mate.batch'
local input = require 'mate.input'
local uid = require 'mate.uid'

return {
  init = function()
    local view = IndexedView.init()
    local id = uid()

    return {
      uid = id,
      items = {},
      view = view,
      size = { 0, 0 },
      selected = 0,

      msg = {
        add = function(item)
          return { id = 'list:append', data = { uid = id, item = item } }
        end,
        append = function(items)
          return { id = 'list:append', data = { uid = id, items = items } }
        end,
        selected = function(idx)
          return { id = 'list:selected', data = { uid = id, index = idx } }
        end,
        clear = { id = 'list:clear', data = { uid = id } },
      }
    }
  end,

  update = function(model, msg, cmd)
    local batch = Batch()

    model.view, cmd = IndexedView.update(model.view, msg)
    batch.push(cmd)

    if msg.id == 'sys:ready' or msg.id == 'sys:resize' then
      model.size[1] = msg.data.width
      model.size[2] = msg.data.height
      model.view, cmd = IndexedView.update(model.view, model.view.msg.set_height(model.size[2] - 2))
      batch.push(cmd)
    elseif msg.id == 'list:add' and msg.data.uid == model.uid then
      table.insert(model.items, msg.data.item)
      model.view, cmd = IndexedView.update(model.view, model.view.msg.set_len(#model.items))
      batch.push(cmd)
      if model.selected == 0 then
        model.selected = 1
        batch.push(model.view.msg.scroll_to(1))
      end
    elseif msg.id == 'list:append' and msg.data.uid == model.uid then
      for _, item in ipairs(msg.data.items) do
        table.insert(model.items, item)
      end
      model.view, cmd = IndexedView.update(model.view, model.view.msg.set_len(#model.items))
      batch.push(cmd)
      if model.selected == 0 then
        model.selected = 1
        batch.push(model.view.msg.scroll_to(1))
      end
    elseif msg.id == 'list:clear' and msg.data.uid == model.uid then
      model.items = {}
      model.view, cmd = IndexedView.update(model.view, model.view.msg.set_len(0))
      batch.push(cmd)
    elseif input.pressed(msg, 'tab') then
      model.selected = (model.selected % #model.items) + 1
      model.view, cmd = IndexedView.update(model.view, model.view.msg.scroll_to(model.selected))
      batch.push(cmd)
    elseif input.pressed(msg, 'shift+tab') then
      model.selected = ((model.selected - 2) % #model.items) + 1
      model.view, cmd = IndexedView.update(model.view, model.view.msg.scroll_to(model.selected))
      batch.push(cmd)
    elseif input.pressed(msg, 'enter') then
      if model.selected <= #model.items then
        batch.push(model.msg.selected(model.selected))
      end
    end

    return model, batch
  end,

  view = function(model, buf, fn)
    if model.size[1] == 0 or model.size[2] == 0 then return end
    IndexedView.view(model.view, buf, function(idx)
      fn(idx, model.items[idx], idx == model.selected)
      buf:write(model.items[idx])
      buf:reset_style()
    end)
  end
}

end)()