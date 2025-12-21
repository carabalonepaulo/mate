local App = require 'mate.app'
local Batch = require 'mate.batch'
local input = require 'mate.input'

App {
  init = function()
    return {
      idx = 1,
      items = { 'Option A', 'Option B', 'Quit' },
      state = 'menu'
    }
  end,

  update = function(model, msg)
    if model.state ~= 'done' then
      if input.pressed(msg, 'up') or input.pressed(msg, 'shift+tab') then
        model.idx = model.idx > 1 and model.idx - 1 or #model.items
      elseif input.pressed(msg, 'down') or input.pressed(msg, 'tab') then
        model.idx = model.idx < #model.items and model.idx + 1 or 1
      elseif input.pressed(msg, 'enter') then
        model.state = 'done'
        if model.idx == 3 then
          return model, { id = 'quit' }
        end
      end
    elseif input.pressed(msg, 'esc') then
      model.state = 'menu'
      model.idx = 1
    end
    return model
  end,

  view = function(model, buf)
    if model.state == 'done' then
      buf:move_to(1, 1)
      buf:write('Selected: ' .. model.items[model.idx])
      return
    end

    buf:move_to(1, 1)
    buf:set_attr('bold')
    buf:write('Options:')
    buf:move_to_next_line()

    for i, item in ipairs(model.items) do
      buf:move_to_col(1)
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
