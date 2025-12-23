local App         = require 'mate.app'
local input       = require 'mate.input'
local Timer       = require 'mate.components.timer'
local Batch       = require 'mate.batch'
local Box         = require 'mate.box'

local SNAKE_CHAR  = '█'
local FOOD_CHAR   = '●'
local SNAKE_COLOR = '#42f581'
local FOOD_COLOR  = '#f54263'

local function spawn_food(snake, w, h)
  local food
  repeat
    food = { x = math.random(0, w - 1), y = math.random(0, h - 1) }
    local collision = false
    for _, segment in ipairs(snake) do
      if segment.x == food.x and segment.y == food.y then
        collision = true
        break
      end
    end
  until not collision
  return food
end

App {
  init = function()
    math.randomseed(os.time())
    local timer = Timer.init(0.05)

    local model = {
      timer = timer,
      snake = {},
      dir = { x = 1, y = 0 },
      next_dir = { x = 1, y = 0 },
      food = { x = 0, y = 0 },
      score = 0,
      game_over = false,
      paused = false,
      ready = false,

      board_box = Box().border(true).bg('#1a1b26'),
      board_layout = nil,
      inner_w = 0,
      inner_h = 0,
    }
    return model, timer.msg.start
  end,

  update = function(model, msg)
    local batch = Batch()
    local cmd

    model.timer, cmd = Timer.update(model.timer, msg)
    batch.push(cmd)

    if input.pressed(msg, 'p') then
      model.paused = not model.paused
      batch.push(model.paused and model.timer.msg.stop or model.timer.msg.start)
      return model, batch
    end

    if input.pressed(msg, 'space') and model.game_over then
      model.game_over = false
      model.score = 0
      model.dir = { x = 1, y = 0 }
      model.next_dir = { x = 1, y = 0 }

      local sx = math.floor(model.inner_w / 2)
      local sy = math.floor(model.inner_h / 2)
      model.snake = { { x = sx, y = sy }, { x = sx - 1, y = sy }, { x = sx - 2, y = sy } }
      model.food = spawn_food(model.snake, model.inner_w, model.inner_h)

      batch.push(model.timer.msg.start)
      return model, batch
    end

    if msg.id == 'sys:ready' or msg.id == 'sys:resize' then
      model.board_box.width(msg.data.width - 2).height(msg.data.height - 2)
      model.board_layout = model.board_box.resolve()

      model.inner_w = model.board_layout.total_w - 2
      model.inner_h = model.board_layout.total_h - 2

      if #model.snake == 0 then
        local sx = math.floor(model.inner_w / 2)
        local sy = math.floor(model.inner_h / 2)
        model.snake = { { x = sx, y = sy }, { x = sx - 1, y = sy }, { x = sx - 2, y = sy } }
        model.food = spawn_food(model.snake, model.inner_w, model.inner_h)
      end
      model.ready = true
    end

    if not model.ready or model.game_over or model.paused then return model, batch end

    if input.pressed(msg, 'w') and model.dir.y == 0 then model.next_dir = { x = 0, y = -1 } end
    if input.pressed(msg, 's') and model.dir.y == 0 then model.next_dir = { x = 0, y = 1 } end
    if input.pressed(msg, 'a') and model.dir.x == 0 then model.next_dir = { x = -1, y = 0 } end
    if input.pressed(msg, 'd') and model.dir.x == 0 then model.next_dir = { x = 1, y = 0 } end

    if msg.id == 'timer:timeout' and msg.data.uid == model.timer.uid then
      model.dir = model.next_dir
      local head = model.snake[1]
      local new_head = { x = head.x + model.dir.x, y = head.y + model.dir.y }

      if new_head.x < 0 or new_head.x >= model.inner_w or new_head.y < 0 or new_head.y >= model.inner_h then
        model.game_over = true
      else
        for _, s in ipairs(model.snake) do
          if s.x == new_head.x and s.y == new_head.y then
            model.game_over = true
            break
          end
        end
      end

      if model.game_over then
        batch.push(model.timer.msg.stop)
      else
        table.insert(model.snake, 1, new_head)
        if new_head.x == model.food.x and new_head.y == model.food.y then
          model.score = model.score + 10
          model.food = spawn_food(model.snake, model.inner_w, model.inner_h)
        else
          table.remove(model.snake)
        end
      end
    end

    return model, batch
  end,

  view = function(model, buf)
    if not model.ready then return end

    buf:with_offset(2, 1, function()
      buf:set_attr('bold')
      buf:write(string.format('SCORE: %04d', model.score))
      buf:set_attr(nil)
    end)

    buf:with_offset(1, 2, function()
      model.board_box.draw(buf, model.board_layout, function(w, h)
        if model.game_over then
          local msg = 'GAME OVER!'
          buf:move_to(math.floor(w / 2) - #msg / 2, math.floor(h / 2))
          buf:set_fg('#d4596f')
          buf:write(msg)
          buf:set_fg(nil)
          return
        end

        buf:move_to(model.food.x, model.food.y)
        buf:set_fg(FOOD_COLOR)
        buf:write(FOOD_CHAR)

        buf:set_fg(SNAKE_COLOR)
        for i, seg in ipairs(model.snake) do
          if seg.x >= 0 and seg.x < w and seg.y >= 0 and seg.y < h then
            buf:move_to(seg.x, seg.y)
            buf:write(SNAKE_CHAR)
          end
        end
        buf:set_fg(nil)
      end)
    end)
  end
}
