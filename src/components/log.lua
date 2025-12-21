local CircularBuffer = require 'ds.queue.circular'
local IndexedView = require 'components.indexed_view'

return {
  init = function(cap)
    local view = IndexedView.init()
    return {
      ready = false,
      size = { 0, 0 },
      view = view,
      lines = CircularBuffer(cap)
    }
  end,

  update = function(model, msg)
    model.view = IndexedView.update(model.view, msg)

    if msg.id == 'log:push' then
      model.lines.push(msg.data)
      model.view = IndexedView.update(model.view, model.view.msg.set_len(model.lines.length()))
    elseif msg.id == 'sys:ready' then
      model.size[0] = msg.data.width
      model.size[1] = msg.data.height
      model.ready = true
      model.view = IndexedView.update(model.view, model.view.msg.set_height(msg.data.height - 2))
    elseif msg.id == 'sys:resize' then
      model.size[0] = msg.data.width
      model.size[1] = msg.data.height
      model.view = IndexedView.update(model.view, model.view.msg.set_height(msg.data.height - 2))
    elseif msg.id ~= 'sys:tick' then
      if msg.id == 'key' then
        if not (msg.data.code == 'up' or msg.data.code == 'down') then
          model.lines.push(string.format('[key] %s', msg.data.string))
        end
      else
        model.lines.push(string.format('[%s]', msg.id))
      end
      model.view = IndexedView.update(model.view, model.view.msg.set_len(model.lines.length()))
    end

    return model
  end,

  view = function(model, buf)
    if not model.ready then return end

    IndexedView.view(model.view, 2, 2, function(x, y, idx)
      buf:move_to(x, y)

      local line = model.lines.at(idx)
      local location, num, err = string.match(line, '^(.*:)(%d+): (.*)$')
      if location and num and err then
        buf:set_attr('dim')
        buf:write(location)
        buf:reset_style()
        buf:set_fg('#b37e49')
        buf:write(num)
        buf:reset_style()
        buf:set_attr('dim')
        buf:write(': ')
        buf:reset_style()
        buf:write(err)
        buf:move_to_next_line()
      else
        buf:write(line)
        buf:move_to_next_line()
      end
    end)
  end,
}
