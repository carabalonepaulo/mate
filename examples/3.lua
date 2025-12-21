local App = require 'mate.app'
local Batch = require 'mate.batch'
local uid = require 'mate.uid'
local input = require 'mate.input'

local Text
do
  Text = {
    init = function()
      return {
        uid = uid(),
        text = ''
      }
    end,

    update = function(model, msg)
      if msg.id == 'text:set' and msg.data.uid == model.uid then
        model.text = msg.data.text
      end
      return model, nil
    end,

    view = function(model, buf)
      buf:set_attr('bold')
      buf:write('Text: ')
      buf:set_attr(nil)

      buf:set_fg('#60b2e0')
      buf:write(model.text)
      buf:set_fg(nil)
    end
  }
end

App {
  init = function()
    return {
      idx = 1,
      text = Text.init()
    }
  end,

  update = function(model, msg)
    local batch = Batch()
    local cmd

    model.text, cmd = Text.update(model.text, msg)
    batch.push(cmd)

    if input.pressed(msg, 'enter') then
      batch.push { id = 'text:set', data = { uid = model.text.uid, text = 'hello world' } }
    end

    return model, batch
  end,

  view = function(model, buf)
    buf:with_offset(1, 1, function()
      buf:set_fg('#758994')
      buf:set_attr('italic')
      buf:write('Press enter to display text...\n\n')
      buf:reset_style()

      Text.view(model.text, buf)
    end)
  end
}
