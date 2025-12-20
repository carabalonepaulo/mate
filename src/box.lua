local unicode = require 'term.unicode'
local layout = require 'term.layout'

local visual_width = unicode.width
local get_horizontal_line = layout.horizontal_line

local function split_lines(str)
  local lines = {}
  if str == '' then return lines end
  for line in (str .. '\n'):gmatch('(.-)\n') do
    table.insert(lines, line)
  end
  return lines
end

return function()
  local cfg = {
    w = 0,
    h = 0,
    x = 0,
    y = 0,
    pt = 0,
    pr = 0,
    pb = 0,
    pl = 0,
    mt = 0,
    mr = 0,
    mb = 0,
    ml = 0,
    sfg = nil,
    sbg = nil,
    sattr = nil,
    border_enabled = false,
    border_color = nil,
    border_chars = { v = '│', h = '─', tl = '┌', tr = '┐', bl = '└', br = '┘' }
  }

  local self = {}

  self.width = function(w)
    cfg.w = w
    return self
  end

  self.height = function(h)
    cfg.h = h
    return self
  end

  self.at = function(x, y)
    cfg.x, cfg.y = x, y
    return self
  end

  self.padding = function(t, r, b, l)
    if not r then r, b, l = t, t, t end
    cfg.pt, cfg.pr, cfg.pb, cfg.pl = t, r, b, l
    return self
  end

  self.margin = function(t, r, b, l)
    if not r then r, b, l = t, t, t end
    cfg.mt, cfg.mr, cfg.mb, cfg.ml = t, r, b, l
    return self
  end

  self.border = function(enable, color)
    cfg.border_enabled = enable
    if color then cfg.border_color = color end
    return self
  end

  self.border_color = function(color)
    cfg.border_color = color
    return self
  end

  self.border_chars = function(v, h, tl, tr, bl, br)
    cfg.border_chars = { v = v, h = h, tl = tl, tr = tr, bl = bl, br = br }
    return self
  end

  self.style = function(fg, bg, attr)
    cfg.sfg, cfg.sbg, cfg.sattr = fg, bg, attr
    return self
  end

  self.resolve = function(content_w, content_h)
    content_w, content_h = content_w or 0, content_h or 0
    local b = cfg.border_chars

    local pieces = {
      v = split_lines(b.v),
      h = split_lines(b.h),
      tl = split_lines(b.tl),
      tr = split_lines(b.tr),
      bl = split_lines(b.bl),
      br = split_lines(b.br)
    }

    local b_wl = cfg.border_enabled and math.max(visual_width(b.v), visual_width(b.tl), visual_width(b.bl)) or 0
    local b_wr = cfg.border_enabled and math.max(visual_width(b.v), visual_width(b.tr), visual_width(b.br)) or 0
    local b_ht = cfg.border_enabled and math.max(#pieces.tl, #pieces.tr, #pieces.h) or 0
    local b_hb = cfg.border_enabled and math.max(#pieces.bl, #pieces.br, #pieces.h) or 0

    local bw = (cfg.w > 0) and math.max(b_wl + b_wr + cfg.pl + cfg.pr, cfg.w - cfg.ml - cfg.mr)
        or (content_w + cfg.pl + cfg.pr + b_wl + b_wr)
    local bh = (cfg.h > 0) and math.max(b_ht + b_hb + cfg.pt + cfg.pb, cfg.h - cfg.mt - cfg.mb)
        or (content_h + cfg.pt + cfg.pb + b_ht + b_hb)

    return {
      total_w = bw + cfg.ml + cfg.mr,
      total_h = bh + cfg.mt + cfg.mb,
      bx = cfg.x + cfg.ml,
      by = cfg.y + cfg.mt,
      bw = bw,
      bh = bh,
      ix = cfg.x + cfg.ml + cfg.pl + b_wl,
      iy = cfg.y + cfg.mt + cfg.pt + b_ht,
      iw = math.max(0, bw - (cfg.pl + cfg.pr + b_wl + b_wr)),
      ih = math.max(0, bh - (cfg.pt + cfg.pb + b_ht + b_hb)),
      b_ht = b_ht,
      b_hb = b_hb,
      b_wl = b_wl,
      b_wr = b_wr,
      pieces = pieces,
      cfg = cfg
    }
  end

  self.draw = function(buf, layout, content_fn)
    local c = layout.cfg
    buf:push_style()

    if c.sbg then
      buf:set_bg(c.sbg)
      for row = 0, layout.bh - 1 do
        buf:move_to(layout.bx, layout.by + row)
        buf:write(string.rep(' ', layout.bw))
      end
    end

    if c.border_enabled then
      buf:set_fg(c.border_color or c.sfg)
      local p = layout.pieces

      for i = 1, layout.b_ht do
        local lt, rt, mid = p.tl[i] or '', p.tr[i] or '', p.h[i] or ''
        local line = get_horizontal_line(lt, rt, mid, layout.bw)
        buf:move_to(layout.bx, layout.by + i - 1)
        buf:write(line)
      end

      local by_bot = layout.by + layout.bh - layout.b_hb
      for i = 1, layout.b_hb do
        local lb, rb, mid = p.bl[i] or '', p.br[i] or '', p.h[i] or ''
        local line = get_horizontal_line(lb, rb, mid, layout.bw)
        buf:move_to(layout.bx, by_bot + i - 1)
        buf:write(line)
      end

      local w_v = visual_width(c.border_chars.v)
      for i = layout.b_ht, layout.bh - layout.b_hb - 1 do
        for line_idx, line in ipairs(p.v) do
          buf:move_to(layout.bx, layout.by + i + line_idx - 1)
          buf:write(line)
          buf:move_to(layout.bx + layout.bw - w_v, layout.by + i + line_idx - 1)
          buf:write(line)
        end
      end
    end

    if content_fn and layout.iw > 0 and layout.ih > 0 then
      buf:set_fg(c.sfg)
      buf:set_attr(c.sattr)
      local cx, cy, cw, ch = buf:get_clip()
      buf:set_clip(layout.ix, layout.iy, layout.iw, layout.ih)
      content_fn(layout.ix, layout.iy, layout.iw, layout.ih)
      buf:set_clip(cx, cy, cw, ch)
    end

    buf:pop_style()
    return self
  end

  return self
end
