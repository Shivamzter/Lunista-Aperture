static const float PI = 3.14159265359;

struct LabConductorData {
    float3 f0;
    float3 f82;
}

float3 srgbToLinear(in float3 c) {
    return pow(c, float3(2.2));
}

LabConductorData getLabConductorData(in int conductor, in float3 albedo) {
    LabConductorData data;

    // Iron
    if (conductor == 230) {
        data.f0 = srgbToLinear(float3(0.78, 0.77, 0.74));
        data.f82 = srgbToLinear(float3(0.75, 0.76, 0.74));
    }
    // Gold
    else if (conductor == 231) {
        data.f0 = srgbToLinear(float3(1.00, 0.90, 0.61));
        data.f82 = srgbToLinear(float3(1.00, 0.92, 0.73));
    }
    // Copper
    else if (conductor == 234) {
        data.f0 = srgbToLinear(float3(1.00, 0.89, 0.73));
        data.f82 = srgbToLinear(float3(1.00, 0.90, 0.80));
    }
    // Albedo Tint
    else if (conductor == 255) {
        data.f0 = albedo;
        data.f82 = albedo;
    }

    return data;
}

// Distribution function
float distributionGGX(in float NoH, in float roughness) {
    float a2 = roughness * roughness;

    float NoH2 = NoH * NoH;

    float num = a2;
    float denom = PI * pow((NoH2 * (a2 - 1.0) + 1.0), 2.0);

    return num / denom;
}

// Geometry function
float geometryGGX(in float NoX, in float roughness) {

    float a2 = roughness * roughness;

    float num = 2.0 * NoX;
    float denom = NoX + sqrt(a2 + (1.0 - a2) * (NoX * NoX));
    return num / denom;
}

float geometrySmith(in float NoV, in float NoL, in float roughness) {
    return geometryGGX(NoV, roughness) * geometryGGX(NoL, roughness);
}

// Fresnel function
float3 fresnelSchlick(in float cosTheta, in float3 F0) {
    return F0 + (float3(1.0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

float3 fresnalLazanyi2019(in float cosTheta, in float3 f0, in float3 f82) {
    float3 a = (823543.0 / 46656.0) * (f0 - f82) + (49.0 / 6.0) * (1.0 - f0);

    return f0 + (1.0 - f0) * pow(1.0 - cosTheta, 5.0) - a * cosTheta * pow(1.0 - cosTheta, 6.0);
}

// https://advances.realtimerendering.com/s2017/DecimaSiggraph2017.pdf
float getNoHSquared(float NoL, float NoV, float VoL, float radius) {
  float radiusCos = cos(radius);
  float radiusTan = tan(radius);

  float RoL = 2.0 * NoL * NoV - VoL;
  if (RoL >= radiusCos) return 1.0;

  float rOverLengthT = radiusCos * radiusTan / sqrt(1.0 - RoL * RoL);
  float NoTr = rOverLengthT * (NoV - RoL * NoL);
  float VoTr = rOverLengthT * (2.0 * NoV * NoV - 1.0 - RoL * VoL);

  float triple = sqrt(
    clamp(
      1.0 - NoL * NoL - NoV * NoV - VoL * VoL + 2.0 * NoL * NoV * VoL,
      0.0,
      1.0
    )
  );

  float NoBr = rOverLengthT * triple,
    VoBr = rOverLengthT * (2.0 * triple * NoV);
  float NoLVTr = NoL * radiusCos + NoV + NoTr,
    VoLVTr = VoL * radiusCos + 1.0 + VoTr;
  float p = NoBr * VoLVTr,
    q = NoLVTr * VoLVTr,
    s = VoBr * NoLVTr;
  float xNum = q * (-0.5 * p + 0.25 * VoBr * NoLVTr);
  float xDenom =
    p * p +
    s * (s - 2.0 * p) +
    NoLVTr *
      ((NoL * radiusCos + NoV) * VoLVTr * VoLVTr +
        q * (-0.5 * (VoLVTr + VoL * radiusCos) - 0.5));
  float twoX1 = 2.0 * xNum / (xDenom * xDenom + xNum * xNum);
  float sinTheta = twoX1 * xDenom;
  float cosTheta = 1.0 - twoX1 * xNum;
  NoTr = cosTheta * NoTr + sinTheta * NoBr;
  VoTr = cosTheta * VoTr + sinTheta * VoBr;

  float newNoL = NoL * radiusCos + NoTr;
  float newVoL = VoL * radiusCos + VoTr;
  float NoH = NoV + newNoL;
  float HoH = 2.0 * newVoL + 2.0;
  return clamp(NoH * NoH / HoH, 0.0, 1.0);
}

float3 brdfMicrofacet(in float3 L, in float3 V, in float3 N, in float roughness, in float3 albedo, in float reflectance, in float3 directLight) {

    float3 Lo = float3(0.0);

    float3 H = normalize(V + L);
    float cosTheta = clamp(dot(V, H), 0.0, 1.0);
    float NoV = clamp(dot(N, V), 0.0, 1.0);
    float NoL = clamp(dot(N, L), 0.0, 1.0);
    float VoL = dot(V, L);

    float NoH = sqrt(getNoHSquared(NoL, NoV, VoL, 0.01));

    float3 F0 = float3(0.04);
    float3 F82 = float3(0.04);
    float3 F;

    float metallic = 0.0;

    int conductor = int(reflectance * 255 + 0.5);

    if (conductor == 255) {
        metallic = 1.0;

        F = fresnelSchlick(cosTheta, F0);
    } else if (conductor >= 230 && conductor <= 254) {
        LabConductorData data = getLabConductorData(conductor, albedo);

        F0 = data.f0;
        F82 = data.f82;
        metallic = 1.0;

        F = fresnalLazanyi2019(cosTheta, F0, F82);
    } else if (conductor <= 229 && conductor >= 1) {
        F0 = float3(clamp(reflectance * 255.0, 0.0, 229.0) / 229.0);
        metallic = 0.0;

        F = fresnelSchlick(cosTheta, F0);
    } else {
        F = fresnelSchlick(cosTheta, F0);
    }
    
    float NDF = distributionGGX(NoH, roughness);
    float G = geometrySmith(NoV, NoL, roughness);

    float3 KS = F;
    float3 KD = float3(1.0) - KS;
    KD *= 1.0 - metallic;

    float3 lambert = albedo / PI;
    float3 diffuse = KD * lambert;

    float3 num = (NDF * G * F);
    float3 denom = 4.0 * NoV * NoL + 1e-6;

    float3 specular = num / denom;

    float3 brdf = diffuse + specular;

    Lo += brdf * directLight * NoL;

    return Lo;
}