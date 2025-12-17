local CircularBuffer = require 'queue.circular'

return {
  init = function()
    return CircularBuffer(16)
  end,

  update = function(model, msg)
    if msg.id == 'log:push' then
      model.push(msg.data)
    end
    return model, nil
  end,

  view = function(model, buf)
    buf.move_to_next_line()

    for line in model.items() do
      buf.move_to_col(2)

      local location, num, err = string.match(line, '^(.*:)(%d+): (.*)$')
      if location and num and err then
        buf.set_attr('dim')
        buf.write(location)
        buf.reset_style()
        buf.set_fg('#b37e49')
        buf.write(num)
        buf.reset_style()
        buf.set_attr('dim')
        buf.write(': ')
        buf.reset_style()
        buf.write(err)
        buf.move_to_next_line()
      else
        buf.write(line)
        buf.move_to_next_line()
      end
    end
  end,
}
