pub mod bindings;
pub mod error;

use std::time::Instant;

use ljr::prelude::*;

use crate::bindings::{
    Term,
    buffer::BufferFactory,
    time::{START_TIME, Time},
};

#[ljr::module]
fn term(lua: &Lua) -> Option<Term> {
    START_TIME.set(Instant::now()).ok();

    lua.register("term.time", Time);
    lua.register("term.buffer", BufferFactory);
    bindings::new().ok()
}
