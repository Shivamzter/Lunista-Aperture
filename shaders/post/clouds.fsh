#version 460 core

uniform sampler2D mainTex; // colortex0
uniform sampler2D mainDepthTex;

uniform float frameTimeCounter;

in vec2 uv;

layout (location = 0) out vec4 colorOut;

float random(in vec2 p) {
    return fract(sin(p.x * 456.0 + p.y * 56.0) * 100.0);
}

vec2 smoothv2(in vec2 v) {
    return v * v * (3.0 - 2.0 * v);
}

float smooth_noise(in vec2 p) {
    vec2 f = smoothv2(fract(p));

    float a = random(floor(p));
    float b = random(vec2(ceil(p.x), floor(p.y)));
    float c = random(vec2(floor(p.x), ceil(p.y)));
    float d = random(ceil(p));
    return mix(
        mix(a, b, f.x),
        mix(c, d, f.x),
        f.y
    );
}

float fractal_noise(in vec2 p) {
    float total = 0.5;
    float amplitude = 1.0;
    float frequency = 1.0;
    float iterations = 4.0;

    for (float i = 0; i < iterations; i++) {
        total += (smooth_noise(p * frequency) - 0.5) * amplitude;
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return total;
}

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position) {
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

void main() {
    vec4 color = texture(mainTex, uv);
    float depth = texture(mainDepthTex, uv).r;

    if (depth == 1.0) {

        vec4 pos = vec4(uv, depth, 1.0) * 2.0 - 1.0;
        pos.xyz = projectAndDivide(ap.camera.projectionInv, pos.xyz);
        pos = ap.camera.viewInv * vec4(pos.xyz, 1.0);
        vec3 rayDir = normalize(pos.xyz);

        vec2 cloudPlane = rayDir.xz * 1.0/rayDir.y + 0.05 * ap.world.time * 0.0075;
        vec2 cloudPlane2 = rayDir.xz * 3.0/rayDir.y - 0.05 * ap.world.time * 0.00125;

        //add clouds
        vec4 clouds;

        if (rayDir.y > 0.0) {
            clouds = vec4(fractal_noise(cloudPlane) * fractal_noise(cloudPlane2));
        } else {
            clouds = vec4(0.0);
        }

        float cloud_fog = 1.0/rayDir.y;

        clouds.a = clamp((clouds.a - 0.3) * 4.0, 0.0, 2.0);
        clouds.rgb = vec3(1.0);
        clouds.rgb *= 1.0 - clamp((clouds.a - 0.5) * 0.1, 0.0, 0.25);

        color.rgb = mix(color.rgb, clouds.rgb, min(clouds.a, 1.0) / (cloud_fog * 1.0));

        // colorOut = vec4(color.rgb, 1.0);
    }

    colorOut = vec4(color.rgb, 1.0);

}