# term

Minimal terminal bindings for Lua, built on top of **crossterm**.

This library exposes low-level terminal primitives (raw mode, alternate screen,
mouse, styles, cursor control, and input events).

This is **not** a TUI framework.

## Initialization

Nothing is enabled by default.

```lua
local term = require 'term'

term:enable_raw_mode()
term:enter_alt_screen()
term:enable_mouse()
term:enable_bracketed_paste()
term:hide_cursor()
```

## Automatic cleanup

By default, the terminal is restored on drop (process exit):

- cursor is shown
- alternate screen is left
- mouse capture is disabled
- bracketed paste is disabled
- raw mode is disabled

To opt out (for example when running inside another TUI like Neovim):

```
term:set_auto_cleanup(false)
```

## Writing output

```
term:print("hello")
term:println("world")

term:print_at(10, 5, "text")

term:flush()
```

Nothing is written until `flush()` is called.

## Cursor control

```
term:move_cursor(x, y)
term:move_to_row(row)
term:move_to_col(col)

term:move_to_next_line()
term:move_to_previous_line()

term:save_cursor()
term:restore_cursor()

term:hide_cursor()
term:show_cursor()

local x, y = term:get_cursor_pos()
```

## Screen and clearing

```
term:clear()
term:clear_line()
term:clear_until_newline()
term:clear_from_cursor_down()
term:clear_from_cursor_up()

local w, h = term:get_size()

term:scroll_up(n)
term:scroll_down(n)
```

## Styles and colors

### Colors

`fg` and `bg` accept:

- `nil`
- ANSI number `0-255`
- string `#rrggbb`
- table `{ r, g, b }`

```
term:set_style("green", nil, "bold")
term:set_style({ 60, 60, 60 }, nil, "dim")
```

## Attributes

```
term:set_attr('bold')
term:unset_attr('bold')

term:reset_fg()
term:reset_bg()
term:reset_style()
```

### Supported attributes:

- bold
- italic
- dim
- underline / under
- blink
- reverse
- hidden
- reset

no_* variants are also accepted in set_style.

## Cursor style

```
term:set_cursor_style('block')
term:set_cursor_style('blinking_block')
term:set_cursor_style('steady_block')
term:set_cursor_style('bar')
term:set_cursor_style('steady_bar')
term:set_cursor_style('underline')
term:set_cursor_style('steady_underline')
```

## Input events

### poll (non-blocking)

```
local events, err = term:poll(10)
if err then error(err) end

for _, e in ipairs(events) do
  -- e.type == 'key' | 'mouse' | 'resize' | 'paste'
end
```

### read (blocking)

```
local events, err = term:read()
if err then error(err) end
```

Events are returned as plain Lua tables. Detailed typing can be added separately
(lua-ls).

## Error handling

Functions that can fail follow a result-style convention:

```
result, err
```

- success (no value, no error) -> `nil`
- success (value, no error) -> `result`
- error (no value, error) -> `nil, string`

Ignoring the error return is the caller’s responsibility.

## Design philosophy

- no hidden state
- no implicit defaults
- no heuristics
- explicit API
- predictable behavior
