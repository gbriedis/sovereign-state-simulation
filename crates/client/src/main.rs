#![forbid(unsafe_code)]

use bevy::{
    prelude::*,
    window::{PresentMode, WindowPlugin, WindowTheme},
};

const WINDOW_TITLE: &str = "State of Consequence — Prototype";
// Bootstrap presentation defaults; these are not final player-interface choices.
const WINDOW_WIDTH: u32 = 1280;
const WINDOW_HEIGHT: u32 = 720;

fn main() {
    App::new()
        .insert_resource(ClearColor(Color::srgb_u8(12, 20, 27)))
        .add_plugins(DefaultPlugins.set(WindowPlugin {
            primary_window: Some(Window {
                title: WINDOW_TITLE.into(),
                name: Some("state-of-consequence".into()),
                resolution: (WINDOW_WIDTH, WINDOW_HEIGHT).into(),
                present_mode: PresentMode::AutoVsync,
                window_theme: Some(WindowTheme::Dark),
                ..default()
            }),
            ..default()
        }))
        .add_systems(Startup, spawn_map_camera)
        .run();
}

fn spawn_map_camera(mut commands: Commands) {
    commands.spawn(Camera2d);
}
