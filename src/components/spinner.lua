local STYLES = {
  { '⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷' },
  { '←', '↖', '↑', '↗', '→', '↘', '↓', '↙' },
  { 'b', 'ᓂ', 'q', 'ᓄ' },
  { 'd', 'ᓇ', 'p', 'ᓀ' },
  { '|', '/', '—', '\\' },
  { 'x', '+' },
  { '◰', '◳', '◲', '◱' },
  { '◴', '◷', '◶', '◵' },
  { '◐', '◓', '◑', '◒' },
  { 'd', '|', 'b', '|' },
  { 'q', '|', 'p', '|' },
  { 'ᓂ', '—', 'ᓄ', '—' },
  { 'ᓇ', '—', 'ᓀ', '—' },
  { '|', 'b', 'O', 'b' },
  { '_', 'o', 'O', 'o' },
  { '.', 'o', 'O', '@', '*', ' ' },
  { '▁', '▃', '▄', '▅', '▆', '▇', '█', '▇', '▆', '▅', '▄', '▃' },
  { '▉', '▊', '▋', '▌', '▍', '▎', '▏', '▎', '▍', '▌', '▋', '▊', '▉' }
}

local uid = require 'uid'

return {
  init = function(tick_interval)
    local id = uid()
    return {
      uid = id,
      style = 1,
      idx = 1,
      len = #STYLES[1],
      enabled = false,
      last_tick = os.clock(),
      interval = tick_interval,

      messages = {
        start = { id = 'spinner:start', data = { uid = id } },
        stop = { id = 'spinner:stop', data = { uid = id } },
        style = function(style_idx)
          return { id = 'spinner:style', data = { uid = id, style = style_idx } }
        end,
      },
    }
  end,

  update = function(model, msg)
    if msg.id == 'spinner:start' and msg.data.uid == model.uid then
      model.enabled = true
      return model
    elseif msg.id == 'spinner:stop' and msg.data.uid == model.uid then
      model.enabled = false
    elseif msg.id == 'spinner:style' and msg.data.uid == model.uid then
      model.style = msg.data.style
      model.idx = 1
      model.len = #STYLES[msg.data.style]
    elseif msg.id == 'sys:tick' and model.enabled then
      local now = msg.data.now
      if now - model.last_tick >= model.interval then
        model.idx = model.idx + 1
        if model.idx > model.len then
          model.idx = 1
        end
        model.last_tick = now
      end
      return model
    end
    return model, nil
  end,

  view = function(model, buf)
    buf:write(STYLES[model.style][model.idx])
  end,
}
