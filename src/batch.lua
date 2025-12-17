return function(...)
  local self = { id = 'batch', data = {} }
  self.push = function(msg)
    if msg ~= nil then
      table.insert(self.data, msg)
    end
  end

  local n = select('#', ...)
  local args = { ... }
  for i = 1, n do
    self.push(args[i])
  end

  return self
end
