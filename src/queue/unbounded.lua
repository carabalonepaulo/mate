return function()
  local buffer = {}
  local head = 1
  local tail = 1

  local function enqueue(value)
    buffer[tail] = value
    tail = tail + 1
    return true
  end

  local function dequeue()
    if head == tail then
      return nil
    end

    local value = buffer[head]
    buffer[head] = nil
    head = head + 1

    if head == tail then
      head = 1
      tail = 1
    end

    return value
  end

  local function peek()
    if head == tail then return nil end
    return buffer[head]
  end

  local function length()
    return tail - head
  end

  return {
    enqueue = enqueue,
    dequeue = dequeue,
    peek = peek,
    length = length
  }
end
