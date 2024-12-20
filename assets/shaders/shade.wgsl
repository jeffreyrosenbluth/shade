#import bevy_sprite::mesh2d_vertex_output::VertexOutput;

@group(2) @binding(0)
var<uniform> time: f32;

struct ColorScale {
    a0: vec3<f32>,
    a1: vec3<f32>,
    a2: vec3<f32>,
    b1: vec3<f32>,
    b2: vec3<f32>,
}

// Constants
const TAU: f32 = 6.28318530718;

// Map color channel from [0,1] to [-1,1]
fn f(x: f32) -> f32 {
    return 2.0 * x - 1.0;
}

// Helper function to calculate coefficients for one channel
fn calculate_coefficients(
    channel0: f32,
    channel1: f32,
    channel2: f32,
    channel3: f32,
    channel4: f32
) -> array<f32, 5> {
    let a0 = 0.3333 * f(channel0) + 0.3333 * f(channel2) + 0.3333 * f(channel4);
    let a1 = 0.5 * f(channel0) - 0.5 * f(channel1) - 0.5 * f(channel3) + 0.5 * f(channel4);
    let a2 = 0.1667 * f(channel0) - 0.5 * f(channel1) + 0.6667 * f(channel2) - 0.5 * f(channel3) + 0.1667 * f(channel4);
    let b1 = 0.2887 * f(channel0) + 0.2887 * f(channel1) - 0.2887 * f(channel3) - 0.2887 * f(channel4);
    let b2 = 0.2887 * f(channel0) - 0.2887 * f(channel1) + 0.2887 * f(channel3) - 0.2887 * f(channel4);
    return array<f32, 5>(a0, a1, a2, b1, b2);
}

// Create a ColorScale from 5 colors
fn create_color_scale(color0: vec3<f32>, color1: vec3<f32>, color2: vec3<f32>, color3: vec3<f32>, color4: vec3<f32>) -> ColorScale {
    let r_coeffs = calculate_coefficients(color0.r, color1.r, color2.r, color3.r, color4.r);
    let g_coeffs = calculate_coefficients(color0.g, color1.g, color2.g, color3.g, color4.g);
    let b_coeffs = calculate_coefficients(color0.b, color1.b, color2.b, color3.b, color4.b);
    
    return ColorScale(
        vec3<f32>(r_coeffs[0], g_coeffs[0], b_coeffs[0]), // a0
        vec3<f32>(r_coeffs[1], g_coeffs[1], b_coeffs[1]), // a1
        vec3<f32>(r_coeffs[2], g_coeffs[2], b_coeffs[2]), // a2
        vec3<f32>(r_coeffs[3], g_coeffs[3], b_coeffs[3]), // b1
        vec3<f32>(r_coeffs[4], g_coeffs[4], b_coeffs[4]) // b2
    );
}

// Linear interpolation between two colors
fn lerp_color(a: vec3<f32>, b: vec3<f32>, t: f32) -> vec3<f32> {
    return a + (b - a) * t;
}

// Create a color scale from 2 colors
fn create_color_scale_from_2(color0: vec3<f32>, color4: vec3<f32>) -> ColorScale {
    let color1 = lerp_color(color0, color4, 0.25);
    let color2 = lerp_color(color0, color4, 0.5);
    let color3 = lerp_color(color0, color4, 0.75);
    return create_color_scale(color0, color1, color2, color3, color4);
}

// Create a color scale from 3 colors
fn create_color_scale_from_3(color0: vec3<f32>, color2: vec3<f32>, color4: vec3<f32>) -> ColorScale {
    let color1 = lerp_color(color0, color2, 0.5);
    let color3 = lerp_color(color2, color4, 0.5);
    return create_color_scale(color0, color1, color2, color3, color4);
}

// Get a color from the color scale at t in [0,1]
fn get_color(scale: ColorScale, t: f32) -> vec3<f32> {
    let cos_t = cos(TAU * t);
    let cos_2t = cos(2.0 * TAU * t);
    let sin_t = sin(TAU * t);
    let sin_2t = sin(2.0 * TAU * t);
    
    let color = 0.5 + 0.5 * (
        scale.a0 +
        scale.a1 * cos_t +
        scale.a2 * cos_2t +
        scale.b1 * sin_t +
        scale.b2 * sin_2t
    );
    
    return clamp(color, vec3<f32>(0.0), vec3<f32>(1.0));
}

// Get a clipped color from the scale
fn get_color_clip(scale: ColorScale, t: f32, clip: f32) -> vec3<f32> {
    let mapped_t = (1.0 - 2.0 * clip) * t + clip;
    return get_color(scale, mapped_t);
}

fn g7(x: f32, y: f32) -> f32 {
    let r = sqrt(x * x + y * y);
    let theta = atan2(y, x);
    return (1.0 + 0.10 * pow(sin(24.0 * theta), 5.0)) * r;
}

fn u(x: f32, y: f32) -> f32 {
    let g = 1.0 - y;
    return (pow(x, g) - 1)/(g);
}

fn hash2d(p: vec2<f32>) -> f32 {
    return fract(sin(dot(p, vec2<f32>(12.9898, 78.233))) * 43758.5453);
}

@fragment
fn fragment(in: VertexOutput) -> @location(0) vec4<f32> {
    let speed = 0.5;
    let t = 0.5 + 0.5 * sin(time * speed);
    let c1 = vec3<f32>(0.16 , 0.08, 0.14);
    let c2 = vec3<f32>(0.14, 0.32, 0.58);
    let c3 = vec3<f32>(0.1, 0.25, 0.29);
    let c4 = vec3<f32>(0.73, 0.61, 0.66);
    let c5 = vec3<f32>(0.45, 0.15, 0.09);
    let scale = create_color_scale(c1, 1.5 * t * c2, c3, c4, 1.5 * t * c5);
    // let s = g7(in.uv.x - 0.5, in.uv.y - 0.5);
    let s = u( 1.0 + (t + 0.25) * 128.0 * abs(in.uv.x - 0.5), (1.0 - in.uv.y) + 0.75);
    let c = get_color(scale, 5.0 * s);
    // let c = get_color(scale, t * (hash2d(in.uv) - 0.5) / 7.0 + 5.0 * s);
    return vec4<f32>(c, 1.0);
}
