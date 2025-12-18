local App = require 'mate.app'
local LineInput = require 'mate.components.line_input'
local Batch = require 'mate.batch'
local Style = require 'mate.style'

App {
  init = function()
    local input = LineInput.init()
    input.placeholder = 'type anything'

    local input_style = Style()
        .bg('#5773a1')
        .border(true)
        .width(50)
        .height(3)

    local model = {
      text = '',
      input = input,
      size = { 0, 0 },
      input_style = input_style,
    }
    return model, model.input.enable
  end,

  update = function(model, msg)
    local batch = Batch()
    local cmd

    model.input, cmd = LineInput.update(model.input, msg)
    batch.push(cmd)

    if msg.id == 'window_size' then
      model.size = { msg.data.width, msg.data.height }
    end

    if msg.data and msg.data.code == 'c' and msg.data.ctrl and not model.input.enabled then
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
    if model.text == '' then
      model.input_style
          .center(unpack(model.size))
          .draw(buf, function(x, y, w, h)
            buf:move_to(x, y)
            buf:write(' > ')
            LineInput.view(model.input, buf)
          end)
    else
      buf:move_to(2, 2)
      buf:write('Text: ')
      buf:set_attr('italic')
      buf:write(model.text)
      buf:set_attr(nil)
    end
  end
}
