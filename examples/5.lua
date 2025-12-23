local App = require 'mate.app'
local LineInput = require 'mate.components.line_input'
local Batch = require 'mate.batch'
local Box = require 'mate.box'

App {
  init = function()
    local input = LineInput.init()
    input.placeholder = 'type anything'

    local input_box = Box()
        .bg('#5773a1')
        .border(true)
        .width(50)
        .height(3)

    local model = {
      text = '',
      input = input,
      size = { 0, 0 },
      input_box = input_box,
      input_layout = input_box.resolve(),
    }
    return model, model.input.msg.enable
  end,

  update = function(model, msg)
    local batch = Batch()
    local cmd

    model.input, cmd = LineInput.update(model.input, msg)
    batch.push(cmd)

    if msg.id == 'sys:ready' or msg.id == 'sys:resize' then
      model.size = { msg.data.width, msg.data.height }
      local cx = model.size[1] / 2 - model.input_layout.total_w / 2
      local cy = model.size[2] / 2 - model.input_layout.total_h / 2
      model.input_box.at(cx, cy)
      model.input_layout = model.input_box.resolve()
    end

    if msg.id == 'line_input:submit' and msg.data.uid == model.input.uid then
      if msg.data.text ~= '' then
        model.text = msg.data.text
        batch.push(model.input.msg.disable)
        batch.push(model.input.msg.clear)
      end
    end

    return model, batch
  end,

  view = function(model, buf)
    if model.text == '' then
      model.input_box.draw(buf, model.input_layout, function(w, h)
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
