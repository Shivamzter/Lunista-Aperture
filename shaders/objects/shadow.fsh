#version 460 core

in vec2 uv;

layout (location = 0) out vec4 outColor;

void iris_emitFragment() {
    outColor = iris_sampleBaseTex(uv);

    if (iris_discardFragment(outColor)) discard;
}