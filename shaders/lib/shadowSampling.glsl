// const float eps = 1e-6;

// vec2 diagonal(mat2 m) {
//     return vec2(m[0].x, m[1].y);
// }
// vec3 diagonal(mat3 m) {
//     return vec3(m[0].x, m[1].y, m[2].z);
// }
// vec4 diagonal(mat4 m) {
//     return vec4(m[0].x, m[1].y, m[2].z, m[3].w);
// }

// vec3 project_ortho(mat4 m, vec3 pos) {
//     return diagonal(m).xyz * pos + m[3].xyz;
// }


// int get_shadow_cascade(vec3 position_sv, out vec3 position_sc) {
//     int cascade;

//     for (cascade = 0; cascade < 4; cascade++){
//         position_sc = project_ortho(ap.celestial.projection[cascade], position_sv);

//         if (clamp(position_sc.xy, vec2(-1.0), vec2(1.0)) == position_sc.xy) break;
//     }

//     return cascade;
// }

// vec3 get_shadow(
//     vec3 position_p,
//     vec3 flat_normal_w,
//     vec3 lightDir
// ) {
//     if (dot(flat_normal_w, lightDir) < 1e-6) {
//         return vec3(0.0);
//     }

//     // float bias = 0.05;
//     // position_p += bias * flat_normal_w;

//     vec3 position_sv = (ap.celestial.view  * vec4(position_p, 1.0)).xyz;
//     vec3 position_sc;

//     int cascade = get_shadow_cascade(position_sv, position_sc);

//     vec3 position_ss = position_sc * 0.5 + 0.5;

//     float shadow_solid = texture(shadowMapFiltered, vec4(position_ss, cascade).xywz);

//     return vec3(shadow_solid);
// }




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

// float shadow = texture(shadowMapFiltered, vec4(shadowScreenPos.xy, cascade, shadowScreenPos.z));

// vec3 get_shadow_map_pixel_size(int cascade){
//   return 0.5 * abs(vec3(ap.celestial.projection[cascade][0].x, ap.celestial.projection[cascade][1].y, ap.celestial.projection[cascade][2].z));
// }