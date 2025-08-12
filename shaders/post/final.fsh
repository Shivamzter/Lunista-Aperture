#version 460 core

uniform sampler2D mainTexture;

in vec2 uv;

layout(location = 0) out vec4 fragColor;

void main() {
    vec4 color = texture(mainTexture, uv);
    color.rgb = pow(color.rgb, vec3(1.0 / 2.2));

    // fragColor = color;
}