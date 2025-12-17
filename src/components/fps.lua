local __uid = 0
local function uid()
  __uid = __uid + 1
  return __uid
end

return {
  init = function()
    local id = uid()
    return {
      uid = id,
      last_tick = os.clock(),
      fps = 0,
      count = 0,
      enabled = false,

      start = function()
        return { id = 'fps:start', data = id }
      end,

      stop = function()
        return { id = 'fps:stop', data = id }
      end
    }
  end,

  update = function(model, msg)
    if msg.id == 'fps:start' and msg.data == model.uid then
      model.enabled = true
      return model, { id = 'fps:tick', data = model.uid }
    elseif msg.id == 'fps:stop' and msg.data == model.uid then
      model.fps = 0
      model.count = 0
      model.enabled = false
    elseif msg.id == 'fps:tick' and msg.data == model.uid and model.enabled then
      local now = os.clock()
      if now - model.last_tick >= 1 then
        model.fps = model.count
        model.last_tick = now
        model.count = 0
      else
        model.count = model.count + 1
      end
      return model, { id = 'fps:tick', data = model.uid }
    end
    return model, nil
  end,

  view = function(model, buf)
    buf.write('FPS: ')
    buf.write(tostring(model.fps))
  end
}
