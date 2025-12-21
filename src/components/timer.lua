local Batch = require 'batch'
local uid = require 'uid'
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
