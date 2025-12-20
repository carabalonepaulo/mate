use std::{sync::OnceLock, time::Instant};

use ljr::user_data;

pub static START_TIME: OnceLock<Instant> = OnceLock::new();

pub struct Time;

#[user_data]
impl Time {
    pub fn now() -> f64 {
        START_TIME
            .get()
            .map(|t| t.elapsed().as_secs_f64())
            .unwrap_or(0.0)
    }
}
