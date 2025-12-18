local App = require 'mate.app'
local Batch = require 'mate.batch'
local Log = require 'mate.components.log'

App {
  init = function()
    return {
      prev_state = nil,
      state = 'counter',
      count = 0,
      log = Log.init()
    }
  end,

  update = function(model, msg)
    local batch = Batch()
    local cmd

    model.log, cmd = Log.update(model.log, msg)
    batch.push(cmd)

    if msg.id == 'key' then
      if msg.data.code == 'q' or (msg.data.code == 'c' and msg.data.ctrl) then
        return model, { id = 'quit' }
      elseif msg.data.code == 'tab' and msg.data.kind == 'press' then
        if model.state ~= 'log' then
          model.prev_state = model.state
          model.state = 'log'
        else
          model.state = model.prev_state
          model.prev_state = nil
        end
      elseif msg.data.code == 'enter' and msg.data.kind == 'press' then
        local a = 1 + 'sd'
        model.count = model.count + 1
      end
    end

    return model, batch
  end,

  view = function(model, buf)
    if model.state == 'counter' then
      buf.write('Count: ' .. tostring(model.count))
    elseif model.state == 'log' then
      Log.view(model.log, buf)
    end
  end
}
