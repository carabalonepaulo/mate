local App = require 'mate.app'
local Batch = require 'mate.batch'
local List = require 'mate.components.list'
local Box = require 'mate.box'
local LineInput = require 'mate.components.line_input'
local input = require 'mate.input'

local NAMES = {
  "Ana Maria Silva",
  "Ana Beatriz Oliveira",
  "Ana Paula Souza",
  "Beatriz Silva Santos",
  "Beatriz Oliveira Lima",
  "Bruno Silva Pereira",
  "Bruno Henrique Souza",
  "Carlos Alberto Silva",
  "Carlos Eduardo Oliveira",
  "Carlos Roberto Santos",
  "Daniela Souza Lima",
  "Daniela Silva Moreira",
  "Diego Oliveira Costa",
  "Eduardo Silva Ferreira",
  "Eduardo Santos Rocha",
  "Felipe Oliveira Silva",
  "Felipe Gabriel Santos",
  "Fernanda Lima Souza",
  "Fernanda Silva Oliveira",
  "Gabriel Santos Lima",
  "Gabriel Henrique Silva",
  "Guilherme Oliveira Souza",
  "Gustavo Silva Santos",
  "Helena Maria Oliveira",
  "Helena Souza Lima",
  "Igor Pereira Silva",
  "Isabela Rocha Santos",
  "João Carlos Silva",
  "João Paulo Oliveira",
  "João Victor Santos",
  "Julia Silva Ferreira",
  "Julia Maria Souza",
  "Lucas Oliveira Santos",
  "Lucas Gabriel Lima",
  "Lucas Silva Pereira",
  "Luiz Carlos Souza",
  "Luiz Henrique Oliveira",
  "Mariana Silva Lima",
  "Mariana Oliveira Souza",
  "Mateus Santos Ferreira",
  "Mateus Oliveira Silva",
  "Paulo Roberto Lima",
  "Paulo Henrique Silva",
  "Rafael Oliveira Santos",
  "Rafael Silva Costa",
  "Ricardo Santos Oliveira",
  "Rodrigo Silva Lima",
  "Sofia Maria Santos",
  "Thiago Oliveira Ferreira",
  "Thiago Silva Rocha"
}

local function layout(model, w, h)
  model.size[0] = w
  model.size[1] = h

  model.input_box
      .at(2, 2)
      .width(w - 2)
      .height(3)
  model.input_layout = model.input_box.resolve()

  model.list_box
      .at(2, 5)
      .width(w - 2)
      .height(h - 5)
  model.list_layout = model.list_box.resolve()
end

local function filter(model, text)
  model.filter = text:lower()
  local filtered = {}

  for _, n in ipairs(NAMES) do
    local segments = {}

    if model.filter ~= '' then
      local name_lower = n:lower()
      local last_pos = 1
      local found_match = false

      while true do
        local s, e = name_lower:find(model.filter, last_pos, true)
        if not s then break end

        found_match = true

        if s > last_pos then
          table.insert(segments, { text = n:sub(last_pos, s - 1), highlight = false })
        end

        table.insert(segments, { text = n:sub(s, e), highlight = true })

        last_pos = e + 1
      end

      if found_match then
        if last_pos <= #n then
          table.insert(segments, { text = n:sub(last_pos), highlight = false })
        end
        table.insert(filtered, { text = n, segments = segments })
      end
    else
      table.insert(segments, { text = n, highlight = false })
      table.insert(filtered, { text = n, segments = segments })
    end
  end
  return filtered
end

App {
  config = {
    fps = 60,
    log_key = 'f12',
    term_poll_timeout = 10,
  },

  init = function()
    local batch = Batch()

    local input = LineInput.init()
    input.placeholder = 'Search names...'
    local input_box = Box()
        .border(true)
        .border_color('#303640')
        .padding(0, 1, 0, 1)
    batch.push(input.msg.enable)

    local list = List.init()
    local list_box = Box()
        .border(true)
        .border_color('#303640')
        .padding(0, 1, 0, 1)
    -- .border_chars('👨‍👩‍👧‍👦', '👨‍👩‍👧‍👦', '👨‍👩‍👧‍👦', '👨‍👩‍👧‍👦', '👨‍👩‍👧‍👦', '👨‍👩‍👧‍👦')

    local model = {
      ready = false,
      size = { 0, 0 },
      found = true,
      filter = '',

      input = input,
      input_box = input_box,
      input_layout = nil,

      list = list,
      list_box = list_box,
      list_layout = nil,
    }

    return model, batch
  end,

  update = function(model, msg, cmd)
    local batch = Batch()

    model.input, cmd = LineInput.update(model.input, msg)
    batch.push(cmd)

    model.list, cmd = List.update(model.list, msg)
    batch.push(cmd)

    if msg.id == 'sys:ready' then
      model.ready = true
      layout(model, msg.data.width, msg.data.height)
      batch.push(model.list.msg.append(filter(model, model.filter)))
      batch.push(model.list.msg.set_size(model.list_layout.iw, model.list_layout.ih))
    elseif msg.id == 'sys:resize' then
      layout(model, msg.data.width, msg.data.height)
      batch.push(model.list.msg.set_size(model.list_layout.iw, model.list_layout.ih))
    elseif input.pressed(msg, 'ctrl+l') or input.pressed(msg, 'ctrl+backspace') or input.pressed(msg, 'ctrl+w') then
      batch.push(model.input.msg.clear)
    elseif msg.id == 'line_input:submit' and msg.data.uid == model.input.uid then
    elseif msg.id == 'line_input:text_changed' and msg.data.uid == model.input.uid then
      local filtered = filter(model, msg.data.text)
      batch.push(model.list.msg.clear)
      if #filtered > 0 then
        model.found = true
        batch.push(model.list.msg.append(filtered))
      else
        model.found = false
      end
    elseif input.pressed(msg, 'f10') then
      batch.push({ id = 'log:push', data = 'clear' })
    end

    return model, batch
  end,

  view = function(model, buf)
    if not model.ready then return end

    model.input_box.draw(buf, model.input_layout, function(x, y, w, h)
      buf:move_to(x, y)
      buf:set_attr('bold')
      buf:write('> ')
      buf:set_attr(nil)
      LineInput.view(model.input, buf)
    end)

    model.list_box.draw(buf, model.list_layout, function(x, y, w, h)
      if model.found then
        buf:move_to(x, y)
        List.view(model.list, buf, x, y, w, h, function(idx, result)
          for _, seg in ipairs(result.segments) do
            if seg.highlight then
              buf:set_fg('#a84c32')
              buf:write(seg.text)
              buf:set_fg(nil)
            else
              buf:write(seg.text)
            end
          end
        end)
      else
        buf:move_to(x, y)
        buf:set_attr('italic')
        buf:write('No results found!')
        buf:set_attr(nil)
      end
    end)
  end
}
