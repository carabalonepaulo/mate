local App = require 'mate.app'
local Batch = require 'mate.batch'
local uid = require 'mate.uid'

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

    if msg.id == 'key' and msg.data.kind == 'press' then
      local code = msg.data.code
      if code == 'q' or (code == 'c' and msg.data.ctrl) then
        batch.push { id = 'quit' }
      elseif code == 'enter' then
        batch.push { id = 'text:set', data = { uid = model.text.uid, text = 'hello world' } }
      elseif code == 'tab' and model.state ~= 'done' then
        model.idx = model.idx < #model.items and model.idx + 1 or 1
      end
    end

    return model, batch
  end,

  view = function(model, buf)
    buf:move_to_col(2)
    buf:set_fg('#758994')
    buf:set_attr('italic')
    buf:write('Press enter to display text...\n\n')
    buf:reset_style()

    buf:move_to_col(2)
    Text.view(model.text, buf)
  end
}
