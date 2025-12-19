local f = string.format
local App = require 'mate.app'
local Batch = require 'mate.batch'
local Spinner = require 'mate.components.spinner'

local function select_scene(model, buf)
  buf:move_to(2, 2)
  buf:write(string.format('Size: %d/%d\n', model.size[1], model.size[2]))

  buf:move_to_col(2)
  buf:write('Index: ')
  buf:set_fg('#e0ab48')
  buf:set_attr('italic')
  buf:write(tostring(model.idx))
  buf:reset_style()

  buf:move_to_next_line()
  buf:move_to_next_line()

  for idx, item in ipairs(model.items) do
    local prefix = model.idx == idx and 'X' or ' '
    buf:move_to_col(2)
    buf:write('[')
    buf:set_fg('#70de5d')
    buf:set_attr('italic')
    buf:write(prefix)
    buf:reset_style()
    buf:write('] ')
    buf:set_fg('#6f7fb0')
    buf:write(f('%d. ', idx))
    buf:reset_style()
    buf:write(item)
    buf:write('\n')
  end

  local colors = {
    '#5d6cde',
    '#42f5ad',
    '#d8e640',
    '#e67240',
    '#e6409b',
    '#8540e6',
    '#40e6d2',
    '#d8e640',
    '#e67240',
    '#e6409b',
    '#8540e6',
    '#e67240',
    '#e6409b',
    '#8540e6',
    '#40e6d2',
    '#d8e640',
    '#e67240',
    '#e6409b',
    '#8540e6',
  }

  buf:move_to_next_line()
  buf:move_to_col(2)

  for i, spinner in ipairs(model.spinners) do
    buf:set_fg(colors[i])
    Spinner.view(spinner, buf)
    buf:reset_style()
    buf:write(' ')
  end

  buf:move_to(2, model.size[2] - 1)
end

local function done_scene(model, buf)
  buf:move_to(2, 2)
  buf:write('Você escolheu ')
  buf:set_fg('#5d6cde')
  buf:set_attr('italic under')
  buf:write(model.items[model.idx])
  buf:reset_style()
  buf:write('!')
end

App {
  init = function()
    local spinners = {}
    for i = 1, 18 do
      table.insert(spinners, Spinner.init(0.001))
    end

    local model = {
      should_quit = false,
      size = { 0, 0 },
      idx = 1,
      items = { 'First', 'Second', 'Third' },
      state = 'first',
      prev_state = 'first',
      spinners = spinners,
    }

    local batch = Batch()
    for i, spinner in ipairs(spinners) do
      batch.push(spinner.messages.start)
      batch.push(spinner.messages.style(i))
    end

    return model, batch
  end,

  update = function(model, msg)
    local batch = Batch()
    local cmd

    for idx, spinner in ipairs(model.spinners) do
      model.spinners[idx], cmd = Spinner.update(spinner, msg)
      batch.push(cmd)
    end

    local id = msg.id
    if id == 'quit' then
      model.should_quit = true
    elseif id == 'log' then
      model.log = msg.data
    elseif id == 'sys:ready' then
      model.size = { msg.data.width, msg.data.height }
    elseif id == 'key' then
      if msg.data.code == 'a' and msg.data.ctrl and msg.data.kind == 'press' then
        local fn = model.spinners[1].enabled and 'stop' or 'start'
        for _, spinner in ipairs(model.spinners) do
          batch.push(spinner.messages[fn])
        end
      end
      if msg.data.kind == 'press' or msg.data.kind == 'repeat' then
        if msg.data.code == 'up' then
          model.idx = model.idx - 1
          if model.idx < 1 then
            model.idx = #model.items
          end
        elseif msg.data.code == 'down' then
          model.idx = model.idx + 1
          if model.idx > #model.items then
            model.idx = 1
          end
        elseif msg.data.code == 'enter' then
          model.state = 'second'
        elseif msg.data.code == 'esc' then
          if model.state == 'second' then
            model.state = 'first'
            model.idx = 1
          else
            return model, { id = 'quit' }
          end
        elseif msg.data.code >= '1' and msg.data.code <= tostring(#model.items) then
          model.idx = tonumber(msg.data.code)
        end
      end
    end

    return model, batch
  end,

  view = function(model, buf)
    if model.state == 'first' then
      select_scene(model, buf)
    elseif model.state == 'second' then
      done_scene(model, buf)
    end
  end
}
