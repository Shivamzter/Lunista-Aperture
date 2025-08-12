#version 460 core

layout(location = 0) out vec4 fragColor;

in vec2 uv;
in vec2 light;
in vec4 color;

in float vertexDistance;

void iris_emitFragment() {
    fragColor = iris_sampleBaseTex(uv) * iris_sampleLightmap(light) * color;

    if (iris_discardFragment(fragColor)) discard;

    fragColor.rgb = pow(fragColor.rgb, vec3(2.2));

    #ifndef DISABLE_FOG
    float mixValue = (vertexDistance - ap.world.fogStart) / (ap.world.fogEnd - ap.world.fogStart);

    float renderDistanceFogStart = ap.camera.renderDistance * 0.95;
    mixValue = max(mixValue, (vertexDistance - renderDistanceFogStart) / (ap.camera.renderDistance - renderDistanceFogStart));

    fragColor = mix(fragColor, ap.world.fogColor, clamp(mixValue, 0.0, 1.0));
    #endif
}