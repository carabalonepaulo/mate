return function(capacity)
  assert(type(capacity) == 'number' and capacity > 0)

  local DUMMY = false

  local buffer = {}
  for i = 1, capacity do
    buffer[i] = DUMMY
  end

  local head = 1
  local tail = 1
  local size = 0

  local function push(value)
    buffer[tail] = value

    tail = tail + 1
    if tail > capacity then
      tail = 1
    end

    if size < capacity then
      size = size + 1
    else
      head = head + 1
      if head > capacity then
        head = 1
      end
    end
  end

  local function at(idx)
    assert(idx >= 1 and idx <= size, string.format('index %d out of bounds, len is %d', idx, size))

    local physical = head + idx - 1
    if physical > capacity then
      physical = physical - capacity
    end
    return buffer[physical]
  end

  local function items()
    local i = 0
    return function()
      if i >= size then
        return nil
      end

      local current_idx = head + i
      if current_idx > capacity then
        current_idx = current_idx - capacity
      end

      i = i + 1
      return buffer[current_idx]
    end
  end

  local function peek()
    if size == 0 then
      return nil
    end
    return buffer[head]
  end

  local function last()
    if size == 0 then return nil end
    local idx = tail - 1
    if idx < 1 then idx = capacity end
    return buffer[idx]
  end

  local function length()
    return size
  end

  local function get_capacity()
    return capacity
  end

  return {
    at = at,
    push = push,
    items = items,
    peek = peek,
    last = last,
    length = length,
    capacity = get_capacity
  }
end
