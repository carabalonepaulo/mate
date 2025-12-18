local App = require 'mate.app'

App {
  init = function()
    return 0
  end,

  update = function(model, msg)
    if msg.id == 'key' and msg.data.code == 'enter' and msg.data.kind == 'press' then
      model = model + 1
    end
    return model
  end,

  view = function(model, buf)
    buf.write('Count: ' .. tostring(model))
  end
}
