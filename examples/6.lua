local App = require 'mate.app'
local Timer = require 'mate.components.timer'
local fmt = string.format

App {
  init = function()
    local timer = Timer.init(0.5)
    local model = {
      elapsed = os.clock(),
      timer = timer,
      count = 0,
    }
    return model, timer.start
  end,

  update = function(model, msg, cmd)
    model.timer, cmd = Timer.update(model.timer, msg)

    if msg.id == 'timer:timeout' and msg.data == model.timer.uid then
      model.count = model.count + 1
    end

    return model, cmd
  end,

  view = function(model, buf)
    buf:write(fmt('Count: %d\n', model.count))
    buf:write(fmt('Elapsed: %0.2fs', (os.clock() - model.elapsed)))
  end
}
