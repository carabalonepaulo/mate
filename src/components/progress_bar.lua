local unicode = require 'term.unicode'
local layout = require 'term.layout'
local uid = require 'uid'

return {
  init = function(opts)
    opts = opts or {}
    local id = uid()
    return {
      uid = id,
      value = opts.value or 0,
      max = opts.max or 100,

      char_fill = opts.fill or '█',
      char_empty = opts.empty or '░',
      char_left = opts.left or '',
      char_right = opts.right or '',
      show_percentage = opts.show_percentage ~= false,

      msg = {
        set = function(value, max)
          return { id = 'progress_bar:set', data = { uid = id, value = value, max = max } }
        end,
        set_value = function(value)
          return { id = 'progress_bar:set_value', data = { uid = id, value = value } }
        end,
        set_max = function(max)
          return { id = 'progress_bar:set_max', data = { uid = id, max = max } }
        end,
        set_percent = function(p)
          return { id = 'progress_bar:set_percent', data = { uid = id, percent = math.min(math.max(p, 0), 1) } }
        end,
      }
    }
  end,

  update = function(model, msg)
    if msg.data and msg.data.uid == model.uid then
      if msg.id == 'progress_bar:set' then
        model.value = msg.data.value
        model.max = msg.data.max
      elseif msg.id == 'progress_bar:set_value' then
        model.value = msg.data.value
      elseif msg.id == 'progress_bar:set_max' then
        model.max = msg.data.max
      elseif msg.id == 'progress_bar:set_percent' then
        model.value = msg.data.percent * model.max
      end

      if model.value < 0 then model.value = 0 end
      if model.max < 0 then model.max = 0 end
      if model.value > model.max and model.max > 0 then model.value = model.max end
    end
    return model
  end,

  view = function(model, buf, w)
    local percent = 0
    if model.max > 0 then
      percent = math.min(math.max(model.value / model.max, 0), 1)
    end

    local label = ''
    if model.show_percentage then
      label = string.format(' %3d%%', math.floor(percent * 100))
    end
    local w_label = unicode.width(label)

    local w_bar = w - w_label

    if w_bar < 2 and model.show_percentage then
      label = ''
      w_label = 0
      w_bar = w
    end

    local w_left = unicode.width(model.char_left)
    local w_right = unicode.width(model.char_right)
    local w_inner = w_bar - w_left - w_right

    if w_inner < 0 then return end

    local w_filled = math.floor(percent * w_inner)
    local w_empty = w_inner - w_filled

    local c_fill = (unicode.width(model.char_fill) > 0) and model.char_fill or ' '
    local c_empty = (unicode.width(model.char_empty) > 0) and model.char_empty or ' '

    buf:write(model.char_left)

    if w_filled > 0 then
      buf:write(layout.horizontal_line('', '', c_fill, w_filled))
    end

    if w_empty > 0 then
      buf:write(layout.horizontal_line('', '', c_empty, w_empty))
    end

    buf:write(model.char_right)
    buf:write(label)
  end
}
