local App = require 'mate.app'
local Batch = require 'mate.batch'

App {
  init = function()
    return {
      idx = 1,
      items = { 'Option A', 'Option B', 'Quit' },
      state = 'menu'
    }
  end,

  update = function(model, msg)
    local batch = Batch()
    local cmd

    if msg.id == 'key' and msg.data.kind == 'press' then
      local code = msg.data.code
      if code == 'q' or (code == 'c' and msg.data.ctrl) then
        batch.push { id = 'quit' }
      elseif code == 'up' and model.state ~= 'done' then
        model.idx = model.idx > 1 and model.idx - 1 or #model.items
      elseif code == 'down' and model.state ~= 'done' then
        model.idx = model.idx < #model.items and model.idx + 1 or 1
      elseif code == 'enter' then
        model.state = 'done'
        if model.idx == 3 then
          batch.push { id = 'quit' }
        end
      elseif code == 'tab' and model.state ~= 'done' then
        model.idx = model.idx < #model.items and model.idx + 1 or 1
      end
    end

    return model, batch
  end,

  view = function(model, buf)
    if model.state == 'done' then
      buf:move_to(2, 2)
      buf:write('Selected: ' .. model.items[model.idx])
      return
    end

    buf:move_to(2, 2)
    buf:set_attr('bold')
    buf:write('Options:')
    buf:move_to_next_line()

    for i, item in ipairs(model.items) do
      buf:move_to_col(2)
      buf:move_to_next_line()

      if model.idx == i then
        buf:set_fg('#60e0a7')
        buf:set_attr('italic')
        buf:write('> ' .. item)
        buf:reset_style()
      else
        buf:write('  ' .. item)
      end
    end
  end
}
