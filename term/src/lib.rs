pub mod bindings;
pub mod error;

use std::time::Instant;

use ljr::prelude::*;

use crate::bindings::{
    Term,
    buffer::BufferFactory,
    layout::Layout,
    time::{START_TIME, Time},
    unicode::Unicode,
};

#[ljr::module]
fn term(lua: &Lua) -> Option<Term> {
    START_TIME.set(Instant::now()).ok();

    lua.register("term.time", Time);
    lua.register("term.buffer", BufferFactory);
    lua.register("term.unicode", Unicode);
    lua.register("term.layout", Layout);

    bindings::new().ok()
}
