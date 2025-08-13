#version 460 core

layout (location = 0) out vec4 fragColor;
layout (location = 1) out vec4 lightmapData;
layout (location = 2) out vec4 encodedNormal;

in vec2 uv;
in vec2 light;
in vec4 color;

in mat3 tbn_matrix;

in vec3 normal;

in float vertexDistance;

void iris_emitFragment() {
    fragColor = iris_sampleBaseTex(uv) * iris_sampleLightmap(light) * color;

    vec4 normalData = iris_sampleNormalMap(uv);
    vec3 textureNormal = normalData.xyz * 2.0 - 1.0;
    textureNormal.z = sqrt(1.0 - dot(textureNormal.xy, textureNormal.xy));
    textureNormal = tbn_matrix * textureNormal;

    // textureSpecular = iris_sampleSpecularMap(new_atlas_uv);

    if (iris_discardFragment(fragColor)) discard;

    fragColor.rgb = pow(fragColor.rgb, vec3(2.2));

    // #ifndef DISABLE_FOG
    // float mixValue = (vertexDistance - ap.world.fogStart) / (ap.world.fogEnd - ap.world.fogStart);

    // float renderDistanceFogStart = ap.camera.renderDistance * 0.95;
    // mixValue = max(mixValue, (vertexDistance - renderDistanceFogStart) / (ap.camera.renderDistance - renderDistanceFogStart));

    // fragColor = mix(fragColor, ap.world.fogColor, clamp(mixValue, 0.0, 1.0));
    // #endif

    lightmapData = vec4(light, 0.0, 1.0);

    encodedNormal = vec4(textureNormal * 0.5 + 0.5, 1.0);
}