local UnboundedQueue = require 'queue.unbounded'

local term = require 'term'
local Buffer = require 'buffer'

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
