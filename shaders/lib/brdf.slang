static const float PI = 3.14159265359;

// Distribution function
float distributionGGX(in float NoH, in float roughness) {
    float a = pow(roughness, 2.0);
    float a2 = pow(a, 2.0);

    float NoH2 = pow(NoH, 2.0);

    float num = a2;
    float denom = PI * pow((NoH2 * (a2 - 1.0) + 1.0), 2.0);

    return num / denom;
}

// Geometry function
float geometrySchlickGGX(in float NoX, in float roughness) {

    float kNum = pow((roughness + 1.0), 2.0);
    float kDenom = 8.0;

    float k = kNum / kDenom;

    // float k = roughness / 2.0;

    float num = NoX;
    float denom = NoX * (1.0 - k) + k;

    return num / denom;
}

float geometrySmith(in float NoV, in float NoL, in float roughness) {
    return geometrySchlickGGX(NoV, roughness) * geometrySchlickGGX(NoL, roughness);
}

// Fresnel function
float3 fresnelSchlick(in float VoH, in float3 F0) {
    return F0 + (float3(1.0) - F0) * pow(clamp(1.0 - VoH, 0.0, 1.0), 5.0);
}

float3 labPBR_HCM_F0(int value, in float3 albedo) {
    if (value == 230) return albedo * float3(0.560, 0.570, 0.580); // Iron
    if (value == 231) return albedo * float3(0.981, 0.781, 0.497); // Gold
    if (value == 232) return albedo * float3(0.700, 0.700, 0.700); // Aluminum
    if (value == 234) return albedo * float3(0.955, 0.638, 0.538); // Copper
    return albedo;
}

float3 brdfMicrofacet(in float3 L, in float3 V, in float3 N, in float roughness, in float3 albedo, in float reflectance, in float3 planetLight) {

    float3 lightOutgoing = float3(0.0);

    float3 H = normalize(V + L);

    float NoV = max(dot(N, V), 0.0);
    float NoL = max(dot(N, L), 0.0);
    float NoH = max(dot(N, H), 0.0);
    float VoH = max(dot(V, H), 0.0);

    float3 F0;

    int labG = int(reflectance * 255 + 0.5);

    float metallic;

    if (labG >= 230) {
        metallic = 1.0;
        F0 = labPBR_HCM_F0(labG, albedo);
    } else if (labG == 0) {
        metallic = 0.0;
        F0 = float3(0.04);
    } else {
        metallic = 0.0;
        F0 = float3(reflectance);
    }

    float NDF = distributionGGX(NoH, roughness);
    float G = geometrySmith(NoV, NoL, roughness);
    float3 F = fresnelSchlick(VoH, F0);

    float3 KS = F;
    float3 KD = float3(1.0) - KS;
    KD *= 1.0 - metallic;

    float3 lambert = albedo / PI;
    float3 diffuse = KD * lambert;

    float3 num = (NDF * G * F);
    float3 denom = 4.0 * max(NoV, 0.0) * max(NoL, 0.0) + 1e-6;

    float3 specular = num / denom;

    float3 brdf = diffuse + specular;

    lightOutgoing += brdf * planetLight * NoL;

    return lightOutgoing;
}