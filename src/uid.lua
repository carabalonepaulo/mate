local __uid = 0
return function()
  __uid = __uid + 1
  return __uid
end
