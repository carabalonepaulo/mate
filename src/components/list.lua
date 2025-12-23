local IndexedView = require 'components.indexed_view'
local Batch = require 'batch'
local input = require 'input'
local uid = require 'uid'

return {
  init = function()
    local view = IndexedView.init()
    local id = uid()

    return {
      uid = id,
      items = {},
      view = view,
      size = { 0, 0 },
      selected = 0,

      msg = {
        add = function(item)
          return { id = 'list:append', data = { uid = id, item = item } }
        end,
        append = function(items)
          return { id = 'list:append', data = { uid = id, items = items } }
        end,
        selected = function(idx)
          return { id = 'list:selected', data = { uid = id, index = idx } }
        end,
        clear = { id = 'list:clear', data = { uid = id } },
      }
    }
  end,

  update = function(model, msg, cmd)
    local batch = Batch()

    model.view, cmd = IndexedView.update(model.view, msg)
    batch.push(cmd)

    if msg.id == 'sys:ready' or msg.id == 'sys:resize' then
      model.size[1] = msg.data.width
      model.size[2] = msg.data.height
      model.view, cmd = IndexedView.update(model.view, model.view.msg.set_height(model.size[2] - 2))
      batch.push(cmd)
    elseif msg.id == 'list:add' and msg.data.uid == model.uid then
      table.insert(model.items, msg.data.item)
      model.view, cmd = IndexedView.update(model.view, model.view.msg.set_len(#model.items))
      batch.push(cmd)
      if model.selected == 0 then
        model.selected = 1
        batch.push(model.view.msg.scroll_to(1))
      end
    elseif msg.id == 'list:append' and msg.data.uid == model.uid then
      for _, item in ipairs(msg.data.items) do
        table.insert(model.items, item)
      end
      model.view, cmd = IndexedView.update(model.view, model.view.msg.set_len(#model.items))
      batch.push(cmd)
      if model.selected == 0 then
        model.selected = 1
        batch.push(model.view.msg.scroll_to(1))
      end
    elseif msg.id == 'list:clear' and msg.data.uid == model.uid then
      model.items = {}
      model.view, cmd = IndexedView.update(model.view, model.view.msg.set_len(0))
      batch.push(cmd)
    elseif input.pressed(msg, 'tab') then
      model.selected = (model.selected % #model.items) + 1
      model.view, cmd = IndexedView.update(model.view, model.view.msg.scroll_to(model.selected))
      batch.push(cmd)
    elseif input.pressed(msg, 'shift+tab') then
      model.selected = ((model.selected - 2) % #model.items) + 1
      model.view, cmd = IndexedView.update(model.view, model.view.msg.scroll_to(model.selected))
      batch.push(cmd)
    elseif input.pressed(msg, 'enter') then
      if model.selected <= #model.items then
        batch.push(model.msg.selected(model.selected))
      end
    end

    return model, batch
  end,

  view = function(model, buf, fn)
    if model.size[1] == 0 or model.size[2] == 0 then return end
    IndexedView.view(model.view, buf, function(idx)
      fn(idx, model.items[idx], idx == model.selected)
      buf:write(model.items[idx])
      buf:reset_style()
    end)
  end
}
