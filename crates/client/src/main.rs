#![forbid(unsafe_code)]

use bevy::{
    diagnostic::{FrameTimeDiagnosticsPlugin, LogDiagnosticsPlugin},
    prelude::*,
    window::{PresentMode, WindowPlugin, WindowTheme},
};
use std::time::Duration;

mod map_camera;

use map_camera::MapCameraPlugin;

const WINDOW_TITLE: &str = "State of Consequence — Diagnostic Camera Fixture";
// Bootstrap presentation defaults; these are not final player-interface choices.
const WINDOW_WIDTH: u32 = 1280;
const WINDOW_HEIGHT: u32 = 720;

fn main() {
    App::new()
        .insert_resource(ClearColor(Color::srgb_u8(12, 20, 27)))
        .add_plugins((
            DefaultPlugins.set(WindowPlugin {
                primary_window: Some(Window {
                    title: WINDOW_TITLE.into(),
                    name: Some("state-of-consequence".into()),
                    resolution: (WINDOW_WIDTH, WINDOW_HEIGHT).into(),
                    present_mode: PresentMode::AutoVsync,
                    window_theme: Some(WindowTheme::Dark),
                    ..default()
                }),
                ..default()
            }),
            FrameTimeDiagnosticsPlugin::default(),
            LogDiagnosticsPlugin {
                wait_duration: Duration::from_secs(5),
                ..default()
            },
        ))
        .add_plugins(MapCameraPlugin)
        .run();
}
