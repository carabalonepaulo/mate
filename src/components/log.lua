local CircularBuffer = require 'ds.queue.circular'
local IndexedView = require 'components.indexed_view'

return {
  init = function(cap)
    local view = IndexedView.init()
    return {
      ready = false,
      size = { 0, 0 },
      view = view,
      lines = CircularBuffer(cap),
    }
  end,

  update = function(model, msg)
    model.view = IndexedView.update(model.view, msg)

    if msg.id == 'log:push' then
      local location, num, err = string.match(msg.data, '^(.*:)(%d+): (.*)$')
      if location then
        model.lines.push {
          { text = location,      attr = 'dim' },
          { text = tostring(num), fg = '#b37e49' },
          { text = ': ',          attr = 'dim' },
          { text = err },
        }
      else
        model.lines.push { { text = msg.data } }
      end
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
          model.lines.push {
            { text = '[' },
            { text = 'key',          fg = '#9e624a' },
            { text = ':' },
            { text = msg.data.kind,  fg = '#968d89' },
            { text = '] ' },
            { text = msg.data.string },
          }
        end
      else
        local prefix, sufix = string.match(msg.id, '^(.*):(.*)$')
        if prefix then
          model.lines.push {
            { text = '[' },
            { text = prefix, fg = '#9e8c4a' },
            { text = ':' },
            { text = sufix,  fg = '#909e4a' },
            { text = '] ' },
          }
        else
          model.lines.push {
            { text = '[' },
            { text = msg.id, fg = '#9e8c4a' },
            { text = '] ' },
          }
        end
      end
      model.view = IndexedView.update(model.view, model.view.msg.set_len(model.lines.length()))
    end

    return model
  end,

  view = function(model, buf)
    if not model.ready then return end

    IndexedView.view(model.view, 1, 1, function(x, y, idx)
      buf:move_to(x, y)
      for _, span in ipairs(model.lines.at(idx)) do
        buf:set_fg(span.fg)
        buf:set_bg(span.bg)
        buf:set_attr(span.attr)
        buf:write(span.text or 'ruim')
      end
      buf:move_to_next_line()
    end)

    buf:set_fg(nil)
    buf:set_bg(nil)
    buf:set_attr(nil)
  end,
}
