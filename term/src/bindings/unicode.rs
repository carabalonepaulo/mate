use ljr::prelude::*;
use unicode_segmentation::UnicodeSegmentation;
use unicode_width::UnicodeWidthStr;

#[derive(Debug)]
pub struct Unicode;

#[user_data]
impl Unicode {
    pub fn width(text: &str) -> i32 {
        text.width() as _
    }

    pub fn width_cjk(text: &str) -> i32 {
        text.width_cjk() as _
    }

    pub fn graphemes(text: &str, is_extended: bool, lua: &Lua) -> TableRef {
        let words = text.graphemes(is_extended);
        let mut table = lua.create_table();
        {
            let mut guard = table.as_mut();
            for w in words {
                guard.push(w);
            }
        }
        table
    }

    pub fn words(text: &str, lua: &Lua) -> TableRef {
        let words = text.unicode_words();
        let mut table = lua.create_table();
        {
            let mut guard = table.as_mut();
            for w in words {
                guard.push(w);
            }
        }
        table
    }

    pub fn split_word_bounds(text: &str, lua: &Lua) -> TableRef {
        let words = text.split_word_bounds();
        let mut table = lua.create_table();
        {
            let mut guard = table.as_mut();
            for w in words {
                guard.push(w);
            }
        }
        table
    }

    pub fn pop_grapheme(text: &str) -> String {
        let last_index = text
            .grapheme_indices(true)
            .next_back()
            .map(|(i, _)| i)
            .unwrap_or(0);
        text[..last_index].to_string()
    }

    pub fn last_grapheme_width(text: &str) -> i32 {
        text.graphemes(true)
            .next_back()
            .map(|g| g.width())
            .unwrap_or(0) as i32
    }
}
