#version 460 core

#include "/lib/tonemap.glsl"

uniform sampler2D mainTex;
uniform sampler2D bloomTex;

in vec2 uv;

layout(location = 0) out vec4 colorOut;

void main() {
    vec3 hdrColor = texture(mainTex, uv).rgb;
    vec3 bloom = texture(bloomTex, uv).rgb;

    // hdrColor = mix(hdrColor, bloom, 0.025); // Bloom intensity

    // hdrColor = reinhard2(hdrColor);
    
    //HDR -> SDR
    hdrColor = pow(hdrColor, vec3(1.0 / 2.2));
    
    colorOut = vec4(hdrColor, 1.0);
}