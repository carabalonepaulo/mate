local App = require 'mate.app'
local Buffer = require 'term.buffer'
local Box = require 'mate.box'

App {
  init = function()
    local box = Box().bg('#3498eb').width(10).height(1).at(1, 1)

    return {
      buf = Buffer.new(10, 1),
      box = box,
      box_layout = box.resolve()
    }
  end,

  update = function(model, msg)
    return model
  end,

  view = function(model, buf)
    model.box.draw(model.buf, model.box_layout, function(x, y, w, h)
    end)

    buf:with_offset(2, 1, function()
      buf:blit(model.buf, 0, 0, 0, 0, 10, 1)
      buf:with_offset(2, 2, function()
        buf:blit(model.buf, 0, 0, 0, 0, 10, 1)
        buf:with_offset(2, 2, function()
          buf:blit(model.buf, 0, 0, 0, 0, 10, 1)
        end)
      end)
    end)
  end
}
