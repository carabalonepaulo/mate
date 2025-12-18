local App = require 'mate.app'
local Batch = require 'mate.batch'

App {
  init = function()
    return {
      prev_state = nil,
      state = 'counter',
      count = 0,
    }
  end,

  update = function(model, msg)
    local batch = Batch()
    local cmd

    if msg.id == 'key' then
      if msg.data.code == 'q' or (msg.data.code == 'c' and msg.data.ctrl) then
        return model, { id = 'quit' }
      elseif msg.data.code == 'enter' and msg.data.kind == 'press' then
        local a = 1 + 'sd'
        model.count = model.count + 1
      end
    end

    return model, batch
  end,

  view = function(model, buf)
    buf.write('Count: ' .. tostring(model.count))
  end
}
