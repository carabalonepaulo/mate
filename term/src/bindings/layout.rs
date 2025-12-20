use ljr::prelude::*;
use unicode_segmentation::UnicodeSegmentation;
use unicode_width::UnicodeWidthStr;

#[derive(Debug)]
pub struct Layout;

#[user_data]
impl Layout {
    pub fn horizontal_line(left: &str, right: &str, mid: &str, total_width: i32) -> String {
        let left_w = left.width() as i32;
        let right_w = right.width() as i32;
        let total_w = total_width as i32;

        let available = total_w - left_w - right_w;

        if available <= 0 {
            return format!("{left}{right}");
        }

        let mid_graphemes: Vec<&str> = mid.graphemes(true).collect();
        let mid_widths: Vec<i32> = mid_graphemes.iter().map(|g| g.width() as i32).collect();
        let mid_total: i32 = mid_widths.iter().sum();

        if mid_total <= 0 {
            return format!("{left}{right}");
        }

        let mut out = String::with_capacity(total_width as _);
        out.push_str(left);

        let full_repeats = available / mid_total;
        if full_repeats > 0 {
            out.push_str(&mid.repeat(full_repeats as usize));
        }

        let mut remaining_space = available % mid_total;
        for (g, w) in mid_graphemes.iter().zip(mid_widths.iter()) {
            if *w <= remaining_space {
                out.push_str(g);
                remaining_space -= w;
            } else {
                break;
            }
        }

        out.push_str(right);
        out
    }
}
