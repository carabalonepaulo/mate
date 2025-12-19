local uid = require 'uid'
local utf8_pattern = '[%z\1-\127\194-\244][\128-\191]*'
local input = require 'input'

local function pop_grapheme(s)
  local last_start = nil
  local i = 1

  for g in s:gmatch(utf8_pattern) do
    last_start = i
    i = i + #g
  end

  if not last_start then
    return s
  end

  return s:sub(1, last_start - 1)
end

return {
  init = function()
    local id = uid()
    return {
      uid = id,
      text = '',
      placeholder = '',
      enabled = false,

      enable = { id = 'line_input:enable', data = { uid = id } },
      disable = { id = 'line_input:disable', data = { uid = id } },
      submit = { id = 'line_input:submit', data = { uid = id } },
    }
  end,

  update = function(model, msg)
    local id = msg.id

    if model.enabled and id == 'key' and msg.data.kind == 'press' then
      if msg.data.code == 'backspace' then
        model.text = pop_grapheme(model.text)
        return model
      end

      if msg.data.code == 'enter' then
        return model, model.submit
      end

      local c = input.char(msg)
      if c then
        model.text = model.text .. c
        return model
      end
    end

    if id == 'paste' then
      model.text = model.text .. msg.data
      return model
    end

    if not (msg.data and msg.data.uid == model.uid) then
      return model
    end

    if id == 'line_input:set_text' then
      model.text = msg.data.text
    elseif id == 'line_input:clear' then
      model.text = ''
    elseif id == 'line_input:enable' then
      model.enabled = true
    elseif id == 'line_input:disable' then
      model.enabled = false
    end

    return model
  end,

  view = function(model, buf)
    if model.text == '' then
      buf:set_attr('dim')
      buf:write(model.placeholder)
      buf:set_attr(nil)
    else
      buf:write(model.text)
    end
  end
}
