#version 460 core

layout (location = 0) out vec4 fragColor;
layout (location = 1) out vec4 lightmapData;
layout (location = 2) out vec4 encodedNormal;
layout (location = 3) out vec4 labSpecular;
layout (location = 5) out vec4 flatNormal;

in vec2 uv;
in vec2 light;
in vec4 color;
in vec3 normal;
in float ao;

in mat3 tbnMatrix;

in float vertexDistance;

void iris_emitFragment() {
    fragColor = iris_sampleBaseTex(uv) * iris_sampleLightmap(light) * color;

    if (iris_discardFragment(fragColor)) discard;

    // #ifndef DISABLE_FOG
    // float mixValue = (vertexDistance - ap.world.fogStart) / (ap.world.fogEnd - ap.world.fogStart);

    // float renderDistanceFogStart = ap.camera.renderDistance * 0.95;
    // mixValue = max(mixValue, (vertexDistance - renderDistanceFogStart) / (ap.camera.renderDistance - renderDistanceFogStart));

    // fragColor = mix(fragColor, ap.world.fogColor, clamp(mixValue, 0.0, 1.0));
    // #endif

    fragColor.rgb = pow(fragColor.rgb, vec3(2.2));

    // Decode LabPBR normal
    vec4 labNormal = iris_sampleNormalMap(uv);

    float labAO = labNormal.b;

    labNormal.xy = labNormal.xy * 2.0 - 1.0;
    labNormal.z = sqrt(1.0 - dot(labNormal.xy, labNormal.xy));
    labNormal.xyz = normalize(tbnMatrix * labNormal.xyz);

    // Decode LabPBR specular
    labSpecular = iris_sampleSpecularMap(uv);

    

    lightmapData = vec4(light, 0.0, 1.0);
    
    flatNormal = vec4(normal * 0.5 + 0.5, ao); // convert to [0, 1] range
    
    encodedNormal = vec4(labNormal.xyz * 0.5 + 0.5, labAO);
}