--- @meta

--- @alias TermEvent
--- | TermEventKey
--- | TermEventMouse
--- | TermEventResize
--- | TermEventPaste

--- @class TermEventKey
--- @field type 'key'
--- @field kind 'press' | 'repeat' | 'release'
--- @field code string
--- @field ctrl boolean
--- @field alt boolean
--- @field shift boolean

--- @class TermEventMouse
--- @field type 'mouse'
--- @field kind
--- | 'down'
--- | 'up'
--- | 'drag'
--- | 'moved'
--- | 'scroll_up'
--- | 'scroll_down'
--- | 'scroll_left'
--- | 'scroll_right'
--- @field row integer
--- @field col integer
--- @field ctrl boolean
--- @field alt boolean
--- @field btn? 'left' | 'right' | 'middle'

--- @class TermEventResize
--- @field type 'resize'
--- @field width integer
--- @field height integer

--- @class TermEventPaste
--- @field type 'paste'
--- @field content string

--- @class term
local term = {}

--- @return string?
function term:enable_raw_mode() end

--- @return string?
function term:disable_raw_mode() end

--- @return string?
function term:enter_alt_screen() end

--- @return string?
function term:leave_alt_screen() end

--- @return string?
function term:enable_mouse() end

--- @return string?
function term:disable_mouse() end

--- @return string?
function term:enable_bracketed_paste() end

--- @return string?
function term:disable_bracketed_paste() end

--- @param enabled boolean
--- @return string?
function term:set_auto_cleanup(enabled) end

--- @return string?
function term:hide_cursor() end

--- @return string?
function term:show_cursor() end

--- @return integer, integer, string?
function term:get_cursor_pos() end

--- @param x integer
--- @param y integer
--- @return string?
function term:move_cursor(x, y) end

--- @param row integer
--- @return string?
function term:move_to_row(row) end

--- @param col integer
--- @return string?
function term:move_to_col(col) end

--- @return string?
function term:move_to_next_line() end

--- @return string?
function term:move_to_previous_line() end

--- @return string?
function term:save_cursor() end

--- @return string?
function term:restore_cursor() end

--- @param style
--- | 'default'
--- | 'block'
--- | 'blinking_block'
--- | 'steady_block'
--- | 'bar'
--- | 'line'
--- | 'steady_bar'
--- | 'underline'
--- | 'steady_underline'
--- @return string?
function term:set_cursor_style(style) end

--- @return integer, integer, string?
function term:get_size() end

--- @return string?
function term:clear() end

--- @return string?
function term:clear_line() end

--- @return string?
function term:clear_until_newline() end

--- @return string?
function term:clear_from_cursor_down() end

--- @return string?
function term:clear_from_cursor_up() end

--- @param n integer
--- @return string?
function term:scroll_up(n) end

--- @param n integer
--- @return string?
function term:scroll_down(n) end

--- @param text string
--- @return string?
function term:print(text) end

--- @param x integer
--- @param y integer
--- @param text string
--- @return string?
function term:print_at(x, y, text) end

--- @param text string
--- @return string?
function term:println(text) end

--- @return string?
function term:flush() end

--- @param title string
--- @return string?
function term:set_title(title) end

--- fg / bg:
---  - nil
---  - number (ANSI 0-255)
---  - string "#rrggbb"
---  - table { r, g, b }
---
--- attrs: string composta (ex: "bold underline no_reverse")
---
--- @param fg any
--- @param bg any
--- @param attrs string
--- @return string?
function term:set_style(fg, bg, attrs) end

--- @return string?
function term:reset_style() end

--- @return string?
function term:reset_fg() end

--- @return string?
function term:reset_bg() end

--- @param attr
--- | 'bold'
--- | 'italic'
--- | 'dim'
--- | 'under'
--- | 'underline'
--- | 'blink'
--- | 'reverse'
--- | 'hidden'
--- | 'reset'
--- @return string?
function term:set_attr(attr) end

--- @param attr
--- | 'bold'
--- | 'italic'
--- | 'under'
--- | 'underline'
--- | 'blink'
--- | 'reverse'
--- | 'hidden'
--- @return string?
function term:unset_attr(attr) end

--- @param ms integer
--- @return TermEvent[], string?
function term:poll(ms) end

--- @return TermEvent[], string?
function term:read() end

--- @param back Buffer
--- @param front Buffer
--- @return string?
function term:render_diff(back, front) end

return term
