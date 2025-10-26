import aperture;

Sampler2DArrayShadow solidShadowMapFiltered;

int calcCascade(float3 playerPos) {
    float3 shadowViewPos = mul((ap.celestial.view), float4(playerPos, 1.0)).xyz;
    float4 shadowClipPos;

    int cascade;

    for (cascade = 0; cascade < 4; cascade++) {

        shadowClipPos = mul(ap.celestial.projection[cascade], float4(shadowViewPos, 1.0));

        if (all(clamp(shadowClipPos.xy, float2(-1.0), float2(1.0)) == shadowClipPos.xy))
        break;
    }

    return cascade;
}

float3 getShadowScreenPos(float3 playerPos, float3 normal) {
    float3 shadowViewPos = mul((ap.celestial.view), float4(playerPos, 1.0)).xyz;
    float4 shadowClipPos;

    int cascade;

    for (cascade = 0; cascade < 4; cascade++) {

        shadowClipPos = mul(ap.celestial.projection[cascade], float4(shadowViewPos, 1.0));

        if (all(clamp(shadowClipPos.xy, float2(-1.0), float2(1.0)) == shadowClipPos.xy))
        break;
    }

    float3 shadowViewNormal = mul(float3x3(ap.celestial.view), normal);
    float3 shadowClipNormal = mul(float3x3(ap.celestial.projection[cascade]), shadowViewNormal);

    shadowClipPos.xyz += shadowClipNormal * 0.02 * pow(2.0, cascade);

    return shadowClipPos.xyz / shadowClipPos.w * 0.5 + 0.5;
}

float3 getShadow(float3 playerPos, float3 normal, float3 lightDir) {

    if (dot(normal, lightDir) < 1e-6) {
        return float3(0.0);
    }

    int cascade = calcCascade(playerPos);
    float3 shadowScreenPos = getShadowScreenPos(playerPos, normal);
    
    float csmShadow = solidShadowMapFiltered.SampleCmp(float3(shadowScreenPos.xy, cascade), shadowScreenPos.z);
    return float3(csmShadow);
}