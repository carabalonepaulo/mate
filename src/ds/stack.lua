return function()
  local len = 0
  local items = {}

  local function push(value)
    len = len + 1
    items[len] = value
  end

  local function pop()
    if len == 0 then return nil end
    local value = items[len]
    items[len] = nil
    len = len - 1
    return value
  end

  return {
    push = push,
    pop = pop,
  }
end
