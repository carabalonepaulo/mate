--- @meta

--- @class Unicode
local unicode = {}

--- @param text string
--- @return integer
function unicode.width(text) end

--- @param text string
--- @return integer
function unicode.width_cjk(text) end

--- @param text string
--- @param is_extended boolean
--- @return string[]
function unicode.graphemes(text, is_extended) end

--- @param text string
--- @return string[]
function unicode.words(text) end

--- @param text string
--- @return string[]
function unicode.split_word_bounds(text) end

--- @param text string
--- @return string
function unicode.pop_grapheme(text, is_extended) end

--- @param text string
--- @return integer
function unicode.last_grapheme_width(text) end

return unicode
