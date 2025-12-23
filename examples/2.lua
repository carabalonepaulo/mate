local App = require 'mate.app'
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
    buf:with_offset(1, 1, function()
      if model.state == 'done' then
        buf:write('Selected: ' .. model.items[model.idx])
        return
      end

      buf:set_attr('bold')
      buf:write('Options:')
      buf:set_attr(nil)

      buf:with_offset(1, 2, function()
        for i, item in ipairs(model.items) do
          if model.idx == i then
            buf:set_fg('#60e0a7')
            buf:set_attr('italic')
            buf:write('> ' .. item)
            buf:reset_style()
          else
            buf:move_to_col(2)
            buf:write(item)
          end
          buf:move_to_next_line()
        end
      end)
    end)
  end
}
