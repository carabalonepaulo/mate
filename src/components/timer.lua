local Batch = require 'batch'
local uid = require 'uid'

return {
  init = function(interval)
    local id = uid()
    return {
      uid = id,
      last_tick = 0,
      interval = interval,

      start = { id = 'timer:start', data = id },
      stop = { id = 'timer:stop', data = id },
      tick = { id = 'timer:tick', data = id },
      timeout = { id = 'timer:timeout', data = id }
    }
  end,

  update = function(model, msg)
    local id = msg.id

    if id == 'timer:start' and msg.data == model.uid then
      model.last_tick = os.clock()
      return model, model.tick
    elseif id == 'timer:stop' and msg.data == model.uid then
      model.last_tick = -1
      return model
    elseif id == 'timer:tick' and msg.data == model.uid and model.last_tick > 0 then
      local batch = Batch()
      local now = os.clock()
      if now - model.last_tick >= model.interval then
        model.last_tick = now
        batch.push(model.timeout)
      end
      batch.push(model.tick)
      return model, batch
    end

    return model
  end,
}
