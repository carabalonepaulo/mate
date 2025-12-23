local App = require 'mate.app'
local List = require 'mate.components.list'
local Batch = require 'mate.batch'

App {
  init = function()
    local list = List.init()
    local items = {}
    for i = 1, 100 do
      table.insert(items, 'Item ' .. tostring(i))
    end

    local model = {
      list = list,
    }

    return model, list.msg.append(items)
  end,

  update = function(model, msg, cmd)
    local batch = Batch()

    model.list, cmd = List.update(model.list, msg)
    batch.push(cmd)

    return model, batch
  end,

  view = function(model, buf)
    buf:with_offset(1, 1, function()
      List.view(model.list, buf, function(idx, item, is_selected)
        if is_selected then
          buf:set_fg('#4f9fe0')
        else
          if idx % 2 == 0 then
            buf:set_fg('#b4b1b5')
          else
            buf:set_fg('#6d6b6e')
          end
        end
      end)
    end)
  end
}
