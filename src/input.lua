local ALIAS = {
  ['backtab'] = 'tab',
  [' '] = 'space',
}

return {
  stringify_key = function(ev)
    local parts = {}
    if ev.ctrl then
      table.insert(parts, 'ctrl')
    end
    if ev.alt then
      table.insert(parts, 'alt')
    end
    if ev.shift then
      table.insert(parts, 'shift')
    end
    table.insert(parts, string.lower(ALIAS[ev.code] or ev.code))
    return table.concat(parts, '+')
  end,

  hit = function(msg, key_str)
    return msg.id == 'key' and msg.data.string == key_str and (msg.data.kind == 'press' or msg.data.kind == 'repeat')
  end,

  pressed = function(msg, key_str)
    return msg.id == 'key' and msg.data.string == key_str and msg.data.kind == 'press'
  end,

  released = function(msg, key_str)
    return msg.id == 'key' and msg.data.string == key_str and msg.data.kind == 'release'
  end,

  repeated = function(msg, key_str)
    return msg.id == 'key' and msg.data.string == key_str and msg.data.kind == 'repeat'
  end,

  num = function(msg)
    local press = msg.id == 'key' and (msg.data.kind == 'press' or msg.data.kind == 'repeat')
    local is_num = press and msg.data.code >= '0' and msg.data.code <= '9'
    return is_num and tonumber(msg.data.code) or nil
  end,

  char = function(msg)
    if msg.id ~= 'key' then return nil end
    if msg.data.ctrl or msg.data.alt then return nil end

    local code = msg.data.code
    if code == 'enter'
        or code == 'backspace'
        or code == 'tab'
        or code == 'esc'
        or code == 'up'
        or code == 'down'
        or code == 'left'
        or code == 'right'
        or code == 'home'
        or code == 'end'
        or code == 'pageup'
        or code == 'pagedown'
        or code:match('^f%d+$') then
      return nil
    end

    return code
  end,
}
