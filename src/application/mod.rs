use bevy::{prelude::*, window::WindowResolution};

pub struct GameApplication;

impl GameApplication {
    pub fn run() {
        App::new()
            .add_plugins(DefaultPlugins.set(WindowPlugin {
                primary_window: Some(Window {
                    title: "State of Consequence".into(),
                    resolution: WindowResolution::new(1280, 720),
                    ..default()
                }),
                ..default()
            }))
            .run();
    }
}
