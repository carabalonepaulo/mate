local App = require 'mate.app'
local ProgressBar = require 'mate.components.progress_bar'
local Timer = require 'mate.components.timer'
local Batch = require 'mate.batch'
local input = require 'mate.input'

App {
  init = function()
    local timer = Timer.init(0.01)

    local progress = ProgressBar.init {
      value = 0,
      max = 100,

      fill = '━',
      empty = '─',
      left = '┣',
      right = '┫',

      -- fill = '●',
      -- empty = '○',
      -- left = '(',
      -- right = ')',

      -- fill = '⣿',
      -- empty = '⣀',
      -- left = '⡇',
      -- right = '⢸',
    }

    local model = {
      timer = timer,
      progress = progress,
      running = true,
      value = 0,
      max = 100,
    }

    return model, timer.msg.start
  end,

  update = function(model, msg, cmd)
    local batch = Batch()

    model.timer, cmd = Timer.update(model.timer, msg)
    batch.push(cmd)

    model.progress, cmd = ProgressBar.update(model.progress, msg)
    batch.push(cmd)

    if input.pressed(msg, 'enter') then
      model = model + 1
    elseif msg.id == 'timer:timeout' and msg.data.uid == model.timer.uid then
      model.value = model.value >= model.max and 0 or model.value + 1
      batch.push(model.progress.msg.set_value(model.value))
    elseif input.pressed(msg, 'ctrl+l') then
      model.running = not model.running
      batch.push(model.timer.msg[model.running and 'start' or 'stop'])
    elseif input.pressed(msg, 'ctrl+r') then
      model.value = 0
      batch.push(model.progress.msg.set_value(model.value))
    end

    return model, batch
  end,

  view = function(model, buf)
    ProgressBar.view(model.progress, buf, 100)
  end
}
