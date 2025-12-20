#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error(transparent)]
    Io(#[from] std::io::Error),
    #[error(transparent)]
    Lua(#[from] ljr::error::Error),
    #[error("invalid color, must be a table, string, number or nil")]
    InvalidColor,
    #[error("front and back buffer has different sizes")]
    BufferSizeMismatch,
}
