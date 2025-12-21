local input = require 'input'
local uid = require 'uid'

local function clamp(value, min, max)
  if value < min then
    return min
  elseif value > max then
    return max
  end
  return value
end

return {
  init = function()
    local id = uid()
    return {
      uid = id,
      len = 0,
      offset = 0,
      height = 0,
      user_scrolled = false,

      msg = {
        set_len = function(len)
          return { id = 'indexed_view:set_len', data = { uid = id, len = len } }
        end,
        set_height = function(h)
          return { id = 'indexed_view:set_height', data = { uid = id, height = h } }
        end,
        reset = { id = 'indexed_view:reset', data = { uid = id } }
      }
    }
  end,

  update = function(model, msg)
    if msg.id == 'indexed_view:set_len' and msg.data.uid == model.uid then
      model.len = msg.data.len
    elseif msg.id == 'indexed_view:set_height' and msg.data.uid == model.uid then
      model.height = msg.data.height
    elseif msg.id == 'indexed_view:reset' and msg.data.uid then
      model.len = 0
      model.offset = 0
      model.user_scrolled = false
    elseif input.pressed(msg, 'up') then
      model.offset = model.offset - 1
      model.user_scrolled = true
    elseif input.pressed(msg, 'down') then
      model.offset = model.offset + 1
      model.user_scrolled = true
    elseif input.pressed(msg, 'home') then
      model.offset = 0
      model.user_scrolled = true
    elseif input.pressed(msg, 'end') then
      model.offset = math.huge
      model.user_scrolled = false
    end

    local max_offset = math.max(0, model.len - model.height)

    if model.len <= model.height then
      model.offset = 0
      model.user_scrolled = false
    else
      if model.user_scrolled then
        model.offset = clamp(model.offset, 0, max_offset)
        if model.offset == max_offset then model.user_scrolled = false end
      else
        model.offset = max_offset
      end
    end

    return model
  end,

  view = function(model, x, y, fn)
    for i = 1, model.height do
      local item_idx = model.offset + i
      if item_idx > model.len then
        break
      end
      fn(x, y + (i - 1), item_idx)
    end
  end,
}
