local App = require 'mate.app'

App {
  init = function()
    return 0
  end,

  update = function(model, msg)
    if msg.id == 'key' then
      if msg.data.code == 'q' or (msg.data.code == 'c' and msg.data.ctrl) then
        return model, { id = 'quit' }
      elseif msg.data.code == 'enter' and msg.data.kind == 'press' then
        model = model + 1
      end
    end
    return model, nil
  end,


  view = function(model, buf)
    buf.write('Count: ' .. model)
  end
}
