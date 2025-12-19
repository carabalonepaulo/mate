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

  local function enqueue(value)
    if size == capacity then
      return false
    end

    buffer[tail] = value
    tail = tail + 1
    if tail > capacity then
      tail = 1
    end

    size = size + 1
    return true
  end

  local function dequeue()
    if size == 0 then
      return nil
    end

    local value = buffer[head]
    buffer[head] = DUMMY
    head = head + 1
    if head > capacity then
      head = 1
    end

    size = size - 1
    return value
  end

  local function peek()
    if size == 0 then
      return nil
    end
    return buffer[head]
  end

  local function length()
    return size
  end

  local function capacity()
    return capacity
  end

  return {
    enqueue = enqueue,
    dequeue = dequeue,
    peek = peek,
    length = length,
    capacity = capacity
  }
end
