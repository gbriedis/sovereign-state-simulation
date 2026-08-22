use bevy::{
    input::mouse::{MouseScrollUnit, MouseWheel},
    prelude::*,
    window::{CursorMoved, PrimaryWindow},
};

const DIAGNOSTIC_GRID_HALF_STEPS: i32 = 128;
const DIAGNOSTIC_GRID_SPACING: f32 = 128.0;

/// Installs the presentation-only map camera and its provisional controls.
pub(crate) struct MapCameraPlugin;

impl Plugin for MapCameraPlugin {
    fn build(&self, app: &mut App) {
        app.init_resource::<MapCameraSettings>()
            .init_resource::<MapCameraInputGate>()
            .init_resource::<MapPanGesture>()
            .add_systems(Startup, spawn_map_camera)
            .add_systems(PostStartup, log_diagnostic_context)
            .add_systems(Update, (navigate_map_camera, draw_diagnostic_fixture));
    }
}

/// Identifies the client presentation camera without assigning it world authority.
#[derive(Component)]
struct MapCamera;

#[derive(Resource)]
struct MapCameraSettings {
    pan_button: MouseButton,
    zoom_step: f32,
    min_scale: f32,
    max_scale: f32,
    max_zoom_intent_per_frame: f32,
}

impl Default for MapCameraSettings {
    fn default() -> Self {
        Self {
            // Middle-drag leaves the primary button available for future picking.
            pan_button: MouseButton::Middle,
            zoom_step: 1.2,
            min_scale: 0.125,
            max_scale: 16.0,
            max_zoom_intent_per_frame: 4.0,
        }
    }
}

/// Future UI surfaces can close this gate while they own the pointer.
#[derive(Resource)]
pub(crate) struct MapCameraInputGate {
    pub(crate) enabled: bool,
}

impl Default for MapCameraInputGate {
    fn default() -> Self {
        Self { enabled: true }
    }
}

/// Client-owned drag state prevents stale platform button state from reviving a
/// gesture after focus, pointer, or UI ownership has been lost.
#[derive(Resource, Default)]
struct MapPanGesture {
    active: bool,
}

fn spawn_map_camera(mut commands: Commands) {
    commands.spawn((Camera2d, MapCamera));
}

fn log_diagnostic_context(
    primary_window: Single<&Window, With<PrimaryWindow>>,
    map_camera: Single<(&Transform, &Projection), With<MapCamera>>,
) {
    let (transform, projection) = *map_camera;
    let scale = match projection {
        Projection::Orthographic(orthographic) => orthographic.scale,
        _ => f32::NAN,
    };

    info!(
        "CLIENT-001 diagnostic fixture: logical={}x{}, physical={}x{}, scale_factor={}, camera=({}, {}), orthographic_scale={}, pan=middle-drag, zoom=wheel/trackpad",
        primary_window.resolution.width(),
        primary_window.resolution.height(),
        primary_window.resolution.physical_width(),
        primary_window.resolution.physical_height(),
        primary_window.resolution.scale_factor(),
        transform.translation.x,
        transform.translation.y,
        scale,
    );
}

fn navigate_map_camera(
    primary_window: Single<(Entity, &Window), With<PrimaryWindow>>,
    map_camera: Single<
        (&Camera, &GlobalTransform, &mut Transform, &mut Projection),
        With<MapCamera>,
    >,
    mut cursor_moved: MessageReader<CursorMoved>,
    mut mouse_wheel: MessageReader<MouseWheel>,
    mouse_buttons: Res<ButtonInput<MouseButton>>,
    control: (
        Res<MapCameraSettings>,
        Res<MapCameraInputGate>,
        ResMut<MapPanGesture>,
    ),
) {
    let (settings, input_gate, mut pan_gesture) = control;
    let (window_entity, window) = *primary_window;
    let cursor_delta = cursor_moved
        .read()
        .filter(|event| event.window == window_entity)
        .filter_map(|event| event.delta)
        .fold(Vec2::ZERO, |sum, delta| sum + delta);
    let zoom_intent = mouse_wheel
        .read()
        .filter(|event| event.window == window_entity)
        .map(|event| normalized_zoom_intent(event.y, event.unit))
        .sum::<f32>();

    let pointer_position = window.cursor_position();
    let (camera, camera_global, mut transform, mut projection) = map_camera.into_inner();
    let Projection::Orthographic(orthographic) = &mut *projection else {
        return;
    };
    let pointer_is_in_map = pointer_input_is_available(
        input_gate.enabled,
        window.focused,
        pointer_position,
        camera.logical_viewport_rect(),
    );

    if pointer_is_in_map
        && zoom_intent != 0.0
        && let Some(cursor_position) = pointer_position
        && let Ok(anchor_world) = camera.viewport_to_world_2d(camera_global, cursor_position)
    {
        let old_scale = orthographic.scale;
        let new_scale = zoomed_scale(
            old_scale,
            bounded_zoom_intent(zoom_intent, settings.max_zoom_intent_per_frame),
            settings.zoom_step,
            settings.min_scale,
            settings.max_scale,
        );
        let new_center = camera_center_after_zoom(
            transform.translation.xy(),
            anchor_world,
            old_scale,
            new_scale,
        );

        orthographic.scale = new_scale;
        transform.translation.x = new_center.x;
        transform.translation.y = new_center.y;
    }

    let button_is_pressed = mouse_buttons.pressed(settings.pan_button);
    let button_was_just_pressed = mouse_buttons.just_pressed(settings.pan_button);
    pan_gesture.active = next_drag_state(
        pan_gesture.active,
        pointer_is_in_map,
        button_is_pressed,
        button_was_just_pressed,
        mouse_buttons.just_released(settings.pan_button),
    );
    let drag_is_active = pan_gesture.active && !button_was_just_pressed;
    let accepted_drag = accepted_drag_delta(cursor_delta, drag_is_active);
    let new_center = camera_center_after_drag(
        transform.translation.xy(),
        accepted_drag,
        orthographic.scale,
    );
    transform.translation.x = new_center.x;
    transform.translation.y = new_center.y;
}

fn normalized_zoom_intent(delta_y: f32, unit: MouseScrollUnit) -> f32 {
    if !delta_y.is_finite() {
        return 0.0;
    }

    match unit {
        MouseScrollUnit::Line => delta_y,
        MouseScrollUnit::Pixel => delta_y / MouseScrollUnit::SCROLL_UNIT_CONVERSION_FACTOR,
    }
}

fn bounded_zoom_intent(intent: f32, maximum_magnitude: f32) -> f32 {
    if intent.is_nan() || !maximum_magnitude.is_finite() || maximum_magnitude <= 0.0 {
        return 0.0;
    }

    intent.clamp(-maximum_magnitude, maximum_magnitude)
}

fn pointer_input_is_available(
    enabled: bool,
    focused: bool,
    pointer: Option<Vec2>,
    viewport: Option<Rect>,
) -> bool {
    enabled
        && focused
        && pointer.is_some_and(Vec2::is_finite)
        && pointer
            .zip(viewport)
            .is_some_and(|(pointer, viewport)| viewport.contains(pointer))
}

fn next_drag_state(
    was_active: bool,
    pointer_is_in_map: bool,
    button_is_pressed: bool,
    button_was_just_pressed: bool,
    button_was_just_released: bool,
) -> bool {
    if !pointer_is_in_map || !button_is_pressed || button_was_just_released {
        false
    } else if button_was_just_pressed {
        true
    } else {
        was_active
    }
}

fn accepted_drag_delta(cursor_delta: Vec2, drag_is_active: bool) -> Vec2 {
    if drag_is_active && cursor_delta.is_finite() {
        cursor_delta
    } else {
        Vec2::ZERO
    }
}

fn camera_center_after_drag(center: Vec2, cursor_delta: Vec2, scale: f32) -> Vec2 {
    if !center.is_finite() || !cursor_delta.is_finite() || !scale.is_finite() || scale <= 0.0 {
        return center;
    }

    // Screen Y grows downward while world Y grows upward. Moving the camera in
    // the opposite direction makes the diagnostic surface follow the pointer.
    center + Vec2::new(-cursor_delta.x, cursor_delta.y) * scale
}

fn zoomed_scale(
    current_scale: f32,
    zoom_in_intent: f32,
    zoom_step: f32,
    min_scale: f32,
    max_scale: f32,
) -> f32 {
    if !current_scale.is_finite()
        || current_scale <= 0.0
        || !zoom_in_intent.is_finite()
        || !zoom_step.is_finite()
        || zoom_step <= 1.0
        || !min_scale.is_finite()
        || !max_scale.is_finite()
        || min_scale <= 0.0
        || max_scale < min_scale
    {
        return current_scale;
    }

    let bounded_current = current_scale.clamp(min_scale, max_scale);
    let candidate = bounded_current * zoom_step.powf(-zoom_in_intent);

    if candidate.is_finite() {
        candidate.clamp(min_scale, max_scale)
    } else if zoom_in_intent.is_sign_positive() {
        min_scale
    } else {
        max_scale
    }
}

fn camera_center_after_zoom(
    center: Vec2,
    anchor_world: Vec2,
    old_scale: f32,
    new_scale: f32,
) -> Vec2 {
    if !center.is_finite()
        || !anchor_world.is_finite()
        || !old_scale.is_finite()
        || !new_scale.is_finite()
        || old_scale <= 0.0
        || new_scale <= 0.0
    {
        return center;
    }

    center + (anchor_world - center) * (1.0 - new_scale / old_scale)
}

fn draw_diagnostic_fixture(mut gizmos: Gizmos) {
    let extent = DIAGNOSTIC_GRID_HALF_STEPS as f32 * DIAGNOSTIC_GRID_SPACING;
    let minor = Color::srgba_u8(83, 106, 119, 105);
    let axis = Color::srgb_u8(74, 189, 172);
    let marker = Color::srgb_u8(245, 183, 70);

    for step in -DIAGNOSTIC_GRID_HALF_STEPS..=DIAGNOSTIC_GRID_HALF_STEPS {
        let offset = step as f32 * DIAGNOSTIC_GRID_SPACING;
        let color = if step == 0 { axis } else { minor };
        gizmos.line_2d(Vec2::new(offset, -extent), Vec2::new(offset, extent), color);
        gizmos.line_2d(Vec2::new(-extent, offset), Vec2::new(extent, offset), color);
    }

    for (position, radius) in [
        (Vec2::ZERO, 32.0),
        (Vec2::new(-384.0, -192.0), 20.0),
        (Vec2::new(320.0, -128.0), 40.0),
        (Vec2::new(-192.0, 256.0), 16.0),
        (Vec2::new(448.0, 224.0), 52.0),
        (Vec2::new(-4096.0, 2048.0), 96.0),
        (Vec2::new(6144.0, -3072.0), 128.0),
    ] {
        gizmos.circle_2d(position, radius, marker);
        let arm = radius + 16.0;
        gizmos.line_2d(position - Vec2::X * arm, position + Vec2::X * arm, marker);
        gizmos.line_2d(position - Vec2::Y * arm, position + Vec2::Y * arm, marker);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const EPSILON: f32 = 1.0e-5;

    fn assert_vec2_close(actual: Vec2, expected: Vec2) {
        assert!(
            actual.abs_diff_eq(expected, EPSILON),
            "expected {expected:?}, got {actual:?}"
        );
    }

    #[test]
    fn direct_manipulation_drag_moves_the_surface_with_the_pointer() {
        let center = Vec2::new(10.0, 20.0);
        let cases = [
            (Vec2::X, Vec2::new(8.0, 20.0)),
            (Vec2::NEG_X, Vec2::new(12.0, 20.0)),
            (Vec2::Y, Vec2::new(10.0, 22.0)),
            (Vec2::NEG_Y, Vec2::new(10.0, 18.0)),
            (Vec2::new(3.0, 4.0), Vec2::new(4.0, 28.0)),
        ];

        for (drag, expected) in cases {
            assert_vec2_close(camera_center_after_drag(center, drag, 2.0), expected);
        }
    }

    #[test]
    fn drag_distance_scales_with_the_current_zoom() {
        let center = Vec2::new(-5.0, 7.0);
        let drag = Vec2::new(12.0, -8.0);
        let near = camera_center_after_drag(center, drag, 0.5) - center;
        let far = camera_center_after_drag(center, drag, 2.0) - center;

        assert_vec2_close(far, near * 4.0);
    }

    #[test]
    fn inactive_or_invalid_drag_rejects_pointer_delta() {
        assert_eq!(accepted_drag_delta(Vec2::new(4.0, 5.0), false), Vec2::ZERO);
        assert_eq!(accepted_drag_delta(Vec2::NAN, true), Vec2::ZERO);
        assert_eq!(
            camera_center_after_drag(Vec2::ONE, Vec2::ZERO, 1.0),
            Vec2::ONE
        );
    }

    #[test]
    fn pointer_input_requires_gate_focus_and_a_finite_position() {
        let pointer = Some(Vec2::new(320.0, 180.0));
        let viewport = Some(Rect::from_corners(Vec2::ZERO, Vec2::new(1280.0, 720.0)));

        assert!(pointer_input_is_available(true, true, pointer, viewport));
        assert!(!pointer_input_is_available(false, true, pointer, viewport));
        assert!(!pointer_input_is_available(true, false, pointer, viewport));
        assert!(!pointer_input_is_available(true, true, None, viewport));
        assert!(!pointer_input_is_available(
            true,
            true,
            Some(Vec2::NAN),
            viewport
        ));
        assert!(!pointer_input_is_available(
            true,
            true,
            Some(Vec2::new(1281.0, 360.0)),
            viewport
        ));
        assert!(!pointer_input_is_available(true, true, pointer, None));
    }

    #[test]
    fn drag_cancels_and_stale_button_state_cannot_rearm() {
        let armed = next_drag_state(false, true, true, true, false);
        assert!(armed);
        assert!(next_drag_state(armed, true, true, false, false));

        for cancelled in [
            next_drag_state(armed, true, true, false, true),
            next_drag_state(armed, false, true, false, false),
            next_drag_state(armed, true, false, false, false),
        ] {
            assert!(!cancelled);
            assert!(!next_drag_state(cancelled, true, true, false, false));
            assert!(next_drag_state(cancelled, true, true, true, false));
        }
    }

    #[test]
    fn line_and_pixel_scroll_normalize_to_the_same_zoom_intent() {
        let lines = normalized_zoom_intent(2.0, MouseScrollUnit::Line);
        let pixels = normalized_zoom_intent(
            2.0 * MouseScrollUnit::SCROLL_UNIT_CONVERSION_FACTOR,
            MouseScrollUnit::Pixel,
        );

        assert_eq!(lines, pixels);
        assert!(normalized_zoom_intent(1.0, MouseScrollUnit::Line) > 0.0);
        assert!(normalized_zoom_intent(-1.0, MouseScrollUnit::Line) < 0.0);
        assert_eq!(normalized_zoom_intent(f32::NAN, MouseScrollUnit::Line), 0.0);
    }

    #[test]
    fn zoom_intent_is_bounded_before_it_reaches_camera_math() {
        assert_eq!(bounded_zoom_intent(1.5, 4.0), 1.5);
        assert_eq!(bounded_zoom_intent(1000.0, 4.0), 4.0);
        assert_eq!(bounded_zoom_intent(-1000.0, 4.0), -4.0);
        assert_eq!(bounded_zoom_intent(f32::INFINITY, 4.0), 4.0);
        assert_eq!(bounded_zoom_intent(f32::NEG_INFINITY, 4.0), -4.0);
        assert_eq!(bounded_zoom_intent(f32::NAN, 4.0), 0.0);
    }

    #[test]
    fn zoom_is_monotonic_positive_finite_and_clamped() {
        let current = 1.0;
        let zoomed_in = zoomed_scale(current, 1.0, 1.2, 0.125, 16.0);
        let zoomed_out = zoomed_scale(current, -1.0, 1.2, 0.125, 16.0);

        assert!(zoomed_in < current);
        assert!(zoomed_out > current);
        assert!(zoomed_in.is_finite() && zoomed_in > 0.0);
        assert!(zoomed_out.is_finite() && zoomed_out > 0.0);
        assert_eq!(zoomed_scale(current, 10_000.0, 1.2, 0.125, 16.0), 0.125);
        assert_eq!(zoomed_scale(current, -10_000.0, 1.2, 0.125, 16.0), 16.0);
        assert!(zoomed_scale(0.125, -1.0, 1.2, 0.125, 16.0) > 0.125);
        assert!(zoomed_scale(16.0, 1.0, 1.2, 0.125, 16.0) < 16.0);
    }

    #[test]
    fn repeated_zoom_in_and_out_is_stable_away_from_bounds() {
        let mut scale = 1.0;
        for _ in 0..16 {
            scale = zoomed_scale(scale, 0.25, 1.2, 0.125, 16.0);
        }
        for _ in 0..16 {
            scale = zoomed_scale(scale, -0.25, 1.2, 0.125, 16.0);
        }

        assert!((scale - 1.0).abs() <= EPSILON, "scale drifted to {scale}");
    }

    #[test]
    fn cursor_anchor_is_invariant_at_center_edges_and_corners_at_all_scales() {
        let center = Vec2::new(160.0, -90.0);
        let screen_offsets = [
            Vec2::ZERO,
            Vec2::new(620.0, 0.0),
            Vec2::new(-620.0, 0.0),
            Vec2::new(0.0, 340.0),
            Vec2::new(0.0, -340.0),
            Vec2::new(620.0, 340.0),
            Vec2::new(-620.0, 340.0),
            Vec2::new(620.0, -340.0),
            Vec2::new(-620.0, -340.0),
        ];

        for (old_scale, new_scale) in [(0.125, 0.2), (1.0, 0.75), (16.0, 8.0)] {
            for screen_offset in screen_offsets {
                let anchor = center + screen_offset * old_scale;
                let new_center = camera_center_after_zoom(center, anchor, old_scale, new_scale);
                let new_screen_offset = (anchor - new_center) / new_scale;
                assert_vec2_close(new_screen_offset, screen_offset);
            }
        }
    }

    #[test]
    fn anchor_is_preserved_when_zoom_hits_a_bound() {
        let center = Vec2::new(-25.0, 40.0);
        let anchor = Vec2::new(300.0, -180.0);
        let old_scale = 0.2;
        let new_scale = zoomed_scale(old_scale, 100.0, 1.2, 0.125, 16.0);
        let new_center = camera_center_after_zoom(center, anchor, old_scale, new_scale);

        assert_eq!(new_scale, 0.125);
        assert_vec2_close(
            (anchor - new_center) / new_scale,
            (anchor - center) / old_scale,
        );
    }

    #[test]
    fn repeated_input_holds_each_bound_and_can_reverse_away() {
        let mut scale = 1.0;
        let zoom_in = bounded_zoom_intent(1000.0, 4.0);
        for _ in 0..128 {
            scale = zoomed_scale(scale, zoom_in, 1.2, 0.125, 16.0);
            assert!(scale.is_finite() && (0.125..=16.0).contains(&scale));
        }
        assert_eq!(scale, 0.125);
        assert_eq!(zoomed_scale(scale, zoom_in, 1.2, 0.125, 16.0), 0.125);
        assert!(zoomed_scale(scale, -1.0, 1.2, 0.125, 16.0) > 0.125);

        scale = 1.0;
        let zoom_out = bounded_zoom_intent(-1000.0, 4.0);
        for _ in 0..128 {
            scale = zoomed_scale(scale, zoom_out, 1.2, 0.125, 16.0);
            assert!(scale.is_finite() && (0.125..=16.0).contains(&scale));
        }
        assert_eq!(scale, 16.0);
        assert_eq!(zoomed_scale(scale, zoom_out, 1.2, 0.125, 16.0), 16.0);
        assert!(zoomed_scale(scale, 1.0, 1.2, 0.125, 16.0) < 16.0);
    }

    #[test]
    fn invalid_zoom_input_cannot_create_a_non_finite_transform() {
        let center = Vec2::new(1.0, 2.0);
        let anchor = Vec2::new(3.0, 4.0);

        assert_eq!(zoomed_scale(1.0, f32::NAN, 1.2, 0.125, 16.0), 1.0);
        assert_eq!(
            camera_center_after_zoom(center, anchor, 1.0, f32::NAN),
            center
        );
    }
}
