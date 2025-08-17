#version 460 core

#include "/lib/tonemap.glsl"

uniform sampler2D mainTexture;
uniform sampler2D bloomTex;

in vec2 uv;

layout(location = 0) out vec4 colorOut;

void main() {
    vec3 hdrScene = texture(mainTexture, uv).rgb;
    vec3 bloom = texture(bloomTex, uv).rgb;

    vec3 hdrSceneFinal = hdrScene + bloom;
    hdrSceneFinal = uncharted2(hdrSceneFinal);
    //HDR -> SDR
    hdrSceneFinal = pow(hdrSceneFinal, vec3(1.0 / 2.2));
    
    colorOut = vec4(hdrSceneFinal, 1.0);
}