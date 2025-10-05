#version 460 core

uniform sampler2D mainTex;

in vec2 uv;

layout(location = 0) out vec4 fragColor;

void main() {
    vec3 color = texture(mainTex, uv).rgb;

    //HDR -> SDR
    vec3 finalScene = pow(color, vec3(1.0 / 2.2));
    
    fragColor = vec4(finalScene, 1.0);
}