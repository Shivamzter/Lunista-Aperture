int calcCascade(vec3 playerPos) {
    vec3 shadow_view_pos = (ap.celestial.view * vec4(playerPos, 1.0)).xyz;
    vec4 shadow_clip_pos;

    int cascade;

    for (cascade = 0; cascade < 4; cascade++){

        shadow_clip_pos = ap.celestial.projection[cascade] * vec4(shadow_view_pos, 1.0);
        if (clamp(shadow_clip_pos.xy, vec2(-1.0), vec2(1.0)) == shadow_clip_pos.xy) break;
    }

    return cascade;
}

vec3 get_shadow_screen_pos(vec3 playerPos, vec3 flatNorm) {

    
    // vec3 shadow_view_normal = mat3(ap.celestial.view) * flatNorm;

    
    vec3 shadow_view_pos = (ap.celestial.view * vec4(playerPos, 1.0)).xyz;
    vec4 shadow_clip_pos;

    int cascade;

    for (cascade = 0; cascade < 4; cascade++){

        shadow_clip_pos = ap.celestial.projection[cascade] * vec4(shadow_view_pos, 1.0);

        if (clamp(shadow_clip_pos.xy, vec2(-1.0), vec2(1.0)) == shadow_clip_pos.xy) break;
    }

    vec3 shadow_view_normal = mat3(ap.celestial.view) * flatNorm;
    vec3 shadow_clip_normal = mat3(ap.celestial.projection[cascade]) * shadow_view_normal;

    shadow_clip_pos.xyz += shadow_clip_normal * 0.02 * pow(2, cascade);

    return shadow_clip_pos.xyz / shadow_clip_pos.w * 0.5 + 0.5;
}

vec3 get_shadowed(vec3 playerPos, vec3 flatNorm, vec3 lightDir) {

    if (dot(flatNorm, lightDir) < 1e-6) {
        return vec3(0.0);
    }

    int cascade = calcCascade(playerPos);

    // flatNorm = flatNorm * ap.camera.viewInv[3].xyz;

    // playerPos += 0.2 * flatNorm;
    vec3 shadowScreenPos = get_shadow_screen_pos(playerPos, flatNorm);

    float csmShadow = texture(shadowMapFiltered, vec4(shadowScreenPos.xy, cascade, shadowScreenPos.z));

    return vec3(csmShadow);
}