#version 460 core

in vec4 color;
in vec2 uv;

layout (location = 0) out vec4 outColor;

void iris_emitFragment() {
    color = iris_sampleBaseTex(uv) * color;

    if (iris_discardFragment(fragColor)) discard;
}