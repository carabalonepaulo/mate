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

App {
  config = {
    fps = 60,
    log_key = 'f12',
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
      batch.push(model.list.msg.append(NAMES))
      batch.push(model.list.msg.set_size(model.list_layout.iw, model.list_layout.ih))
    elseif msg.id == 'sys:resize' then
      layout(model, msg.data.width, msg.data.height)
      batch.push(model.list.msg.set_size(model.list_layout.iw, model.list_layout.ih))
    elseif input.pressed(msg, 'ctrl+l') or input.pressed(msg, 'ctrl+backspace') or input.pressed(msg, 'ctrl+w') then
      batch.push(model.input.msg.clear)
    elseif msg.id == 'line_input:submit' and msg.data.uid == model.input.uid then
    elseif msg.id == 'line_input:text_changed' and msg.data.uid == model.input.uid then
      model.filter = msg.data.text:lower()

      local filtered = {}
      for _, n in ipairs(NAMES) do
        if n:lower():find(model.filter, 1, true) then
          table.insert(filtered, n)
        end
      end
      batch.push(model.list.msg.clear)

      if #filtered > 0 then
        model.found = true
        batch.push(model.list.msg.append(filtered))
      else
        model.found = false
      end
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
        List.view(model.list, buf, x, y, w, h, function(idx, name)
          if model.filter ~= '' then
            local s, e = name:lower():find(model.filter, 1, true)

            if s then
              local first, mid, last = name:sub(1, s - 1), name:sub(s, e), name:sub(e + 1)
              buf:write(first)

              buf:set_fg('#a84c32')
              buf:write(mid)
              buf:set_fg(nil)

              buf:write(last)
            else
              buf:write(name)
            end
          else
            buf:write(name)
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
