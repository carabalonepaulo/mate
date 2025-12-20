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
      list = {},
      offset = 0,
      size = { 0, 0 },
      user_scrolled = false,

      msg = {
        set_size = function(w, h)
          return { id = 'list:set_size', data = { uid = id, width = w, height = h } }
        end,
        push = function(value)
          return { id = 'list:push', data = { uid = id, value = value } }
        end
      }
    }
  end,

  update = function(model, msg)
    if msg.id == 'list:push' and msg.data.uid == model.uid then
      table.insert(model.list, msg.data.value)
    elseif msg.id == 'list:set_size' and msg.data.uid == model.uid then
      model.size = { msg.data.width, msg.data.height }
    elseif input.pressed(msg, 'up') then
      model.offset = model.offset - 1
      model.user_scrolled = true
    elseif input.pressed(msg, 'down') then
      model.offset = model.offset + 1
      model.user_scrolled = true
    elseif input.pressed(msg, 'home') or (msg.id == 'list:reset' and msg.data.uid == model.uid) then
      model.offset = 0
      model.user_scrolled = true
    elseif input.pressed(msg, 'end') then
      model.offset = math.huge
      model.user_scrolled = false
    end

    local count = #model.list
    local max_offset = math.max(0, count - model.size[2])

    if count <= model.size[2] then
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

  view = function(model, buf, x, y, w, h, fn)
    for i = 1, h do
      local item_idx = model.offset + i
      local item = model.list[item_idx]

      if item then
        buf:move_to(x, y + (i - 1))
        fn(item_idx, item)
      end
    end
  end,
}
