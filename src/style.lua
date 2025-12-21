local utf8_pattern = '[%z\1-\127\194-\244][\128-\191]*'

local function utf8_len(str)
  local count = 0
  for _ in str:gmatch(utf8_pattern) do
    count = count + 1
  end
  return count
end

return function()
  local self_w, self_h = 0, 0
  local self_x, self_y = 0, 0

  local pt, pr, pb, pl = 0, 0, 0, 0
  local mt, mr, mb, ml = 0, 0, 0, 0
  local sfg, sbg, sattr = nil, nil, nil

  local border_enabled = false
  local border_char_v = '│'
  local border_char_h = '─'
  local border_tl, border_tr = '┌', '┐'
  local border_bl, border_br = '└', '┘'
  local border_color = nil

  local self = {}

  self.width = function(w)
    self_w = w
    return self
  end

  self.height = function(h)
    self_h = h
    return self
  end

  self.x = function(x)
    self_x = x
    return self
  end

  self.y = function(y)
    self_y = y
    return self
  end

  self.at = function(x, y)
    self_x, self_y = x, y
    return self
  end

  self.center = function(external_w, external_h)
    assert(self_w > 0 and self_h > 0, 'style must be sized to be centered')
    self_x = math.floor((external_w / 2) - self_w / 2)
    self_y = math.floor((external_h / 2) - self_h / 2)
    return self
  end

  self.padding = function(t, r, b, l)
    if not r then r, b, l = t, t, t end
    pt, pr, pb, pl = t, r, b, l
    return self
  end

  self.margin = function(t, r, b, l)
    if not r then r, b, l = t, t, t end
    mt, mr, mb, ml = t, r, b, l
    return self
  end

  self.border_color = function(color)
    border_color = color
    return self
  end

  self.border = function(enable)
    border_enabled = enable
    return self
  end

  self.style = function(fg, bg, attr)
    sfg, sbg, sattr = fg, bg, attr
    return self
  end

  self.fg = function(fg)
    sfg = fg
    return self
  end

  self.bg = function(bg)
    sbg = bg
    return self
  end

  self.attr = function(attr)
    sattr = attr
    return self
  end

  self.get_right = function() return self_x + self_w end

  self.get_bottom = function() return self_y + self_h end

  self.get_dims = function() return self_x, self_y, self_w, self_h end

  self.get_layout = function(content_w, content_h)
    local b_offset = border_enabled and 1 or 0

    local calc_w = (content_w or 0) + pl + pr + (b_offset * 2) + ml + mr
    local calc_h = (content_h or 0) + pt + pb + (b_offset * 2) + mt + mb

    local final_w = (self_w > 0) and self_w or calc_w
    local final_h = (self_h > 0) and self_h or calc_h

    local iw = final_w - (ml + mr + pl + pr + (b_offset * 2))
    local ih = final_h - (mt + mb + pt + pb + (b_offset * 2))

    return {
      outer_w = final_w,
      outer_h = final_h,
      inner_w = iw,
      inner_h = ih,
      ix = self_x + ml + pl + b_offset,
      iy = self_y + mt + pt + b_offset
    }
  end

  self.draw = function(buf, content_fn)
    buf:push_style()

    local bx = self_x + ml
    local by = self_y + mt
    local bw = self_w - (ml + mr)
    local bh = self_h - (mt + mb)

    if bw <= 0 or bh <= 0 then return self end

    if sfg then buf:set_fg(sfg) end
    if sbg then buf:set_bg(sbg) end
    if sattr then buf:set_attr(sattr) end

    if sbg then
      for row = 0, bh - 1 do
        buf:move_to(bx, by + row)
        buf:write(string.rep(" ", bw))
      end
    end

    buf:set_fg(border_color)
    local b_offset = 0
    if border_enabled then
      b_offset = 1
      buf:move_to(bx, by)
      buf:write(border_tl .. string.rep(border_char_h, bw - 2) .. border_tr)

      buf:move_to(bx, by + bh - 1)
      buf:write(border_bl .. string.rep(border_char_h, bw - 2) .. border_br)

      for i = 1, bh - 2 do
        buf:move_to(bx, by + i); buf:write(border_char_v)
        buf:move_to(bx + bw - 1, by + i); buf:write(border_char_v)
      end
    end
    buf:set_fg(nil)

    local ix = bx + pl + b_offset
    local iy = by + pt + b_offset
    local iw = bw - (pl + pr + (b_offset * 2))
    local ih = bh - (pt + pb + (b_offset * 2))

    if content_fn and iw > 0 and ih > 0 then
      buf:with_offset(ix, iy, function()
        buf:with_clip(0, 0, iw, ih, function()
          content_fn(0, 0, iw, ih)
        end)
      end)
    end

    buf:pop_style()
    return self
  end

  self.draw_text = function(buf, text)
    local text_w = utf8_len(text)
    local text_h = 1

    local b_offset = border_enabled and 1 or 0

    local inner_w = text_w + pl + pr + (b_offset * 2)
    local inner_h = text_h + pt + pb + (b_offset * 2)

    self_w = inner_w + ml + mr
    self_h = inner_h + mt + mb

    self.draw(buf, function(ix, iy, iw, ih)
      buf:move_to(ix, iy)
      buf:write(text)
    end)

    return self
  end

  return self
end
