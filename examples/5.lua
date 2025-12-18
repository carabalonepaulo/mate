local App = require 'mate.app'
local LineInput = require 'mate.components.line_input'
local Batch = require 'mate.batch'

App {
  init = function()
    local model = {
      text = nil,
      input = LineInput.init()
    }
    return model, model.input.enable
  end,

  update = function(model, msg)
    local batch = Batch()
    local cmd

    model.input, cmd = LineInput.update(model.input, msg)
    batch.push(cmd)

    if msg.id == 'key' and (msg.data.code == 'q' or (msg.data.code == 'c' and msg.data.ctrl)) then
      batch.push { id = 'quit' }
    end

    if msg.id == 'line_input:submit' and msg.data.uid == model.input.uid then
      model.text = model.input.text
      model.input.text = ''
      return model, model.input.disable
    end

    return model, batch
  end,

  view = function(model, buf)
    buf.move_to(2, 2)
    if model.text then
      buf.write(model.text)
    else
      LineInput.view(model.input, buf)
    end
  end
}
