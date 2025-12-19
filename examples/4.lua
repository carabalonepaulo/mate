local App = require 'mate.app'
local input = require 'mate.input'

App {
  init = function()
    return 0
  end,

  update = function(model, msg)
    if input.pressed(msg, 'enter') then
      model = model + 1
    end
    return model
  end,

  view = function(model, buf)
    buf:write('Count: ' .. tostring(model))
  end
}
