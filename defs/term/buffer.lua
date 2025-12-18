--- @meta

--- Off-screen drawing buffer.
---
--- A Buffer represents a 2D grid of cells, each containing a character and a style
--- (foreground color, background color, and attributes).
---
--- Buffers do not write directly to the terminal. They are intended to be used as
--- back/front buffers and rendered via a terminal backend using a diff-based renderer.
---
--- No properties are exposed. All interaction is performed through methods.
---
--- @class Buffer
local buffer = {}

--- Creates a new buffer with the given dimensions.
---
--- Width and height are clamped to non-negative values.
---
--- @param width integer
--- @param height integer
--- @return Buffer
function buffer.new(width, height) end

--- Resizes the buffer.
---
--- Existing contents are preserved when possible; new cells are initialized to default.
--- Width and height are clamped to non-negative values.
---
--- @param width integer
--- @param height integer
function buffer:resize(width, height) end

--- Clears the buffer contents.
---
--- All cells are reset to the default character and style.
function buffer:clear() end

function buffer:clear_clip() end

--- @return integer, integer, integer, integer
function buffer:get_clip() end

--- @param x integer
--- @param y integer
--- @param w integer
--- @param h integer
function buffer:set_clip(x, y, w, h) end

--- Sets the current foreground color.
---
--- The color may be specified as a string, number, or table, depending on the
--- color formats supported by the backend.
---
--- @param color string | number | table
--- @raise error if the color value is invalid
function buffer:set_fg(color) end

--- Sets the current background color.
---
--- The color may be specified as a string, number, or table, depending on the
--- color formats supported by the backend.
---
--- @param color string | number | table
--- @raise error if the color value is invalid
function buffer:set_bg(color) end

--- Sets the current text attributes.
---
--- The attribute string is parsed as a whitespace-separated list of attribute names.
--- Calling this replaces the current attribute set.
---
--- Examples:
---   "bold"
---   "bold dim"
---   "reset"
---   "reset italic"
---
--- @param attr string
function buffer:set_attr(attr) end

--- Resets the current style to the default.
---
--- This clears foreground color, background color, and all attributes.
function buffer:reset_style() end

--- Pushes the current style onto the style stack.
---
--- This allows temporary style changes that can later be reverted using pop_style().
function buffer:push_style() end

--- Pops the last style from the style stack and restores it.
---
--- If the stack is empty, this function does nothing.
function buffer:pop_style() end

--- Moves the cursor to the given position.
---
--- Coordinates are clamped to the buffer bounds.
---
--- @param x integer
--- @param y integer
function buffer:move_to(x, y) end

--- Moves the cursor to the given column on the current row.
---
--- The column is clamped to the buffer width.
---
--- @param x integer
function buffer:move_to_col(x) end

--- Moves the cursor to the beginning of the next line.
---
--- The cursor will not move past the last row of the buffer.
function buffer:move_to_next_line() end

--- Writes text at the current cursor position.
---
--- Each character is written into a cell using the current style.
--- Newline characters ('\n') move the cursor to the next line.
--- Writing past the right edge automatically advances to the next line.
---
--- If the buffer has zero width or height, this function does nothing.
---
--- @param text string
function buffer:write(text) end

--- Writes text at the specified position.
---
--- The cursor position is restored after writing.
--- Coordinates are clamped to non-negative values.
---
--- @param x integer
--- @param y integer
--- @param text string
function buffer:write_at(x, y, text) end

return buffer
