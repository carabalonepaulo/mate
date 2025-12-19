local UnboundedQueue = require 'ds.queue.unbounded'

local term           = require 'term'
local time           = require 'term.time'
local Buffer         = require 'term.buffer'
local Log            = require 'components.log'
local Stack          = require 'ds.stack'

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
  local last_tick = time.now()
  local frame_time = 1 / 60
  local last_render = 0

  local tick_msg_data = { now = 0, dt = 0, budget = 0 }
  local tick_msg = { id = 'sys:tick', data = tick_msg_data }

  local log_model, log_cmd = Log.init()
  local display_log = false
  local disptach_stack = Stack()

  local function dispatch(initial)
    if not initial then return end
    disptach_stack.push(initial)

    local id, data
    local msg = disptach_stack.pop()

    while msg do
      id = msg.id

      if id == 'batch' then
        data = msg.data
        for i = #data, 1, -1 do
          disptach_stack.push(data[i])
        end
        data = nil
      else
        msgs.enqueue(msg)
      end

      msg = disptach_stack.pop()
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
    local ok, err = pcall(loop)
    if not ok then exit_err(err) end
  until should_quit

  deinit_term()
end
