#![forbid(unsafe_code)]

//! Renderer-independent world and simulation core.
//!
//! Canonical world state, deterministic generation, spatial queries, and
//! simulation rules belong in this crate. Keep Bevy, window, input, and render
//! types out of this dependency boundary.
