local function read_file(path)
  local file = io.open(path, 'r')
  if file then
    local text = file:read('*a')
    file:close()
    return text
  else
    return ''
  end
end

local function write_file(path, mode, text)
  local file = io.open(path, mode)
  if file then
    file:write(text)
    file:close()
  end
end

local push = table.insert
local fmt = string.format

assert(#arg == 2, '-f:text|bin -m:manifest.dest')
local args = {}
for _, a in ipairs(arg) do
  local key, value = a:match('-(%w):([a-zA-Z%.]+)')
  args[key] = value
end

assert(args.f and args.m, 'output format and manifest must be provided')
local mode = args.f
local manifest = require(args.m)

local buffer = {}
for _, entry in ipairs(manifest.files) do
  local text = read_file(entry[2])
  local inner_buffer = {}
  push(inner_buffer, fmt('package.loaded["%s"] = (function()', entry[1]))

  for a, b in pairs(manifest.replace) do
    text = text:gsub(a, b)
  end
  push(inner_buffer, text)

  push(inner_buffer, [[end)()]])
  push(buffer, table.concat(inner_buffer, '\n'))
end

local bundle = table.concat(buffer, '\n')
if mode == 'text' then
  write_file('./out.lua', 'w+', bundle)
elseif mode == 'bin' then
  local chunk, err = load(bundle, manifest.prefix, 't')
  assert(chunk, err)
  local bin = string.dump(chunk, true)
  write_file('./out.luac', 'wb+', bin)
end
