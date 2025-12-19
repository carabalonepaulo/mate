local App = require 'mate.app'
local Timer = require 'mate.components.timer'
local time = require 'term.time'
local fmt = string.format

App {
  config = { fps = 20 },

  init = function()
    local timer = Timer.init(0.5)
    local model = {
      elapsed = time.now(),
      timer = timer,
      budget = 0,
      count = 0,
    }
    return model, timer.start
  end,

  update = function(model, msg, cmd)
    model.timer, cmd = Timer.update(model.timer, msg)

    if msg.id == 'sys:tick' then
      model.budget = msg.data.budget
    end

    if msg.id == 'timer:timeout' and msg.data == model.timer.uid then
      model.count = model.count + 1
    end

    return model, cmd
  end,

  view = function(model, buf)
    buf:write(fmt('Count: %d\n', model.count))
    buf:write(fmt('Elapsed: %0.2fs\n', (time.now() - model.elapsed)))
    buf:write(fmt('Budget: %0.2fs', model.budget))
  end
}
