use bevy::{
    prelude::*,
    reflect::TypePath,
    render::render_resource::{AsBindGroup, ShaderRef},
    sprite::{Material2d, Material2dPlugin},
    window::{WindowResized, WindowResolution},
};

const SHADER_ASSET_PATH: &str = "shaders/shade.wgsl";

fn main() {
    App::new()
        .add_plugins(DefaultPlugins.set(WindowPlugin {
            primary_window: Some(Window {
                resolution: WindowResolution::new(1200.0, 1200.0),
                title: "Bullseye".to_string(),
                ..default()
            }),
            ..default()
        }))
        .add_plugins(Material2dPlugin::<ShadeMaterial>::default())
        .add_systems(Startup, setup)
        .add_systems(Update, update_quad_size)
        .add_systems(Update, update_time)
        .run();
}

fn setup(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<ShadeMaterial>>,
    windows: Query<&Window>,
) {
    commands.spawn(Camera2d);

    let window = windows.single();
    let size = Vec2::new(window.width(), window.height());
    commands.spawn((
        Mesh2d(meshes.add(Rectangle::default())),
        MeshMaterial2d(materials.add(ShadeMaterial::default())),
        Transform::default().with_scale(Vec3::new(size.x, size.y, 1.0)),
        FullScreenQuad,
    ));
}

#[derive(Component)]
struct FullScreenQuad;

// System to update quad size when window is resized
fn update_quad_size(
    mut resize_event: EventReader<WindowResized>,
    mut query: Query<&mut Transform, With<FullScreenQuad>>,
) {
    for event in resize_event.read() {
        if let Ok(mut transform) = query.get_single_mut() {
            transform.scale = Vec3::new(event.width, event.height, 1.0);
        }
    }
}

fn update_time(time: Res<Time>, mut materials: ResMut<Assets<ShadeMaterial>>) {
    for material in materials.iter_mut() {
        material.1.time = time.elapsed_secs() as f32;
    }
}

#[derive(Asset, TypePath, AsBindGroup, Debug, Clone)]
struct ShadeMaterial {
    #[uniform(0)]
    time: f32,
    #[uniform(1)]
    resolution: Vec2,
}

impl Default for ShadeMaterial {
    fn default() -> Self {
        Self {
            time: 0.0,
            resolution: Vec2::new(0.0, 0.0),
        }
    }
}

impl Material2d for ShadeMaterial {
    fn fragment_shader() -> ShaderRef {
        SHADER_ASSET_PATH.into()
    }
}
