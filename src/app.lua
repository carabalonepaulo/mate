local UnboundedQueue = require 'queue.unbounded'

local term           = require 'term'
local Buffer         = require 'term.buffer'
local Log            = require 'components.log'

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

local function exit_err(err)
  deinit_term()
  term:println(err)
  term:println(debug.traceback())
  os.exit(false)
end

local function safe_init(fn, ...)
  local ok, model, cmd = pcall(fn, ...)
  if not ok then
    exit_err(model)
  else
    return model, cmd
  end
end

return function(meta)
  init_term()

  local msgs = UnboundedQueue()
  local should_quit = false
  local model, init_cmd = safe_init(meta.init)

  local w, h = term:get_size()
  local front_buffer = Buffer.new(w, h)
  local back_buffer = Buffer.new(w, h)
  local last_tick = os.clock()
  local frame_time = 1 / 60
  local last_render = 0

  local log_model, log_cmd = Log.init()
  local display_log = false

  local function dispatch(msg)
    if not msg then return end

    log_model, log_cmd = Log.update(log_model, msg)
    dispatch(log_cmd)

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
    local events, err = term:poll(1)
    if err then exit_err(err) end

    for _, e in ipairs(events) do
      if e.type == 'key' then
        if e.code == 'f12' and e.kind == 'press' then
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
        dispatch { id = 'window_size', data = { width = w, height = h } }
      end
    end

    local msg
    local len = msgs.length()

    local now = os.clock()
    local dt = now - last_tick
    last_tick = now

    model, msg = meta.update(model, { id = 'app:tick', data = { now = now, dt = dt } })
    dispatch(msg)

    for i = 1, len do
      msg = msgs.dequeue()
      model, msg = meta.update(model, msg)
      dispatch(msg)
    end

    if now - last_render >= frame_time then
      back_buffer:clear()
      if display_log then
        Log.view(log_model, back_buffer)
      else
        meta.view(model, back_buffer)
      end
      term:render_diff(back_buffer, front_buffer)
      last_render = now
    end
  end

  dispatch(init_cmd)
  dispatch(log_cmd)
  dispatch { id = 'window_size', data = { width = w, height = h } }

  repeat
    local ok, err = pcall(loop)
    if not ok then exit_err(err) end
  until should_quit

  deinit_term()
end
