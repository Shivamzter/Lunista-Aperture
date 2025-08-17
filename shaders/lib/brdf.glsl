const float PI = 3.14159265359;

// float DistributionGGX(vec3 N, vec3 H, float roughness)
// {
//   float a = roughness * roughness;
//   float a2 = a * a;
//   float num = a2;

//   float NoH  = max(dot(N, H), 0.0);
//   float NoH2 = NoH*NoH;
	
//   float denom = (NoH2 * (a2 - 1.0) + 1.0);
//   denom = PI * denom * denom;
	
//   return num / denom;
// }

// // vec3 fresnelSchlick(float cosTheta, vec3 F0)
// // {
// //     return F0 + (vec3(1.0) - F0) * pow(1.0 - cosTheta, 5.0);
// // }  

// float GeometryShclickGGX(float NdotX, float roughness)
// {
//     float r = (roughness + 1.0);
//     float k = (r*r) / 8.0;

//     float num = NdotX;
//     float denom = NdotX * (1.0 - k) + k;
	
//     return num / denom;
// }

// float gGGX(float NoX, float roughness) {
//   float num = 2.0 * NoX;
  
//   float a = roughness * roughness;
//   float a2 = a * a;

// //   float NoV = dot(N, V);
//   float NoX2 = NoX * NoX;

//   float denom = max(NoX, 1e-6) + sqrt(a2 + (1.0 - a2) * NoX2);

//   return num / denom;
// }

// float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
// {
//   float NdotV = max(dot(N, V), 1e-6);
//   float NdotL = max(dot(N, L), 1e-6);
//   float ggx2  = gGGX(NdotV, roughness);
//   float ggx1  = gGGX(NdotL, roughness);

//   return ggx1 * ggx2;
// }

// vec3 brdfMicrofacet(vec3 lightColor, vec3 N, vec3 L, vec3 V, float roughness, vec3 labF0, vec3 albedo, float metallic) {

//   vec3 Lo = vec3(0.0);
  
//   //calculate light radiance
//   float dist = length(L);
//   float attenuation = 1.0 / (dist * dist);
//   vec3 radiance = lightColor * attenuation; 

//   vec3 H = normalize(V + L);

//   float NoV = max(dot(N, V), 0.0);
//   float NoL = clamp(dot(N, L), 0.0, 1.0);
//   float HoV = max(dot(H, V), 0.0);

//   float alpha = roughness * roughness;

//   float D = DistributionGGX(N, H, roughness);
//   vec3 F = fresnelSchlick(HoV, labF0);
//   float G = GeometrySmith(N, V, L, roughness);

//   vec3 spec = (D * F * G) / (4.0 * NoL * NoV + 0.0001);

//   vec3 kS = F;
//   vec3 kD = vec3(1.0) - kS;
//   kD *= 1.0 - metallic;

//   Lo += (kD * albedo / PI + spec) * radiance * NoL;

//   return Lo;
// }

float D_GGX(float NoH, float roughness) {

    float alpha = roughness * roughness;
    float alpha2 = alpha * alpha;

    float NoH2 = NoH * NoH;

    float b = (NoH2 * (alpha2 - 1.0) + 1.0);

    return alpha2 / (PI * b * b);
    // return alpha2 * PI / (b * b); // Check this if what you did doesn't work.
}

// float G1_GGX_Schlick(float NoV, float roughness) {
//     float alpha = roughness * roughness;
//     float k = alpha / 2.0;
//     return max(NoV, 0.0001) / (max(NoV, 0.0001) * (1.0 - k) + k);
// }

float G1_GGX(float NoVL, float roughness) {
    float alpha = roughness * roughness;
    float alpha2 = alpha * alpha;

    float NoX = max(NoVL, 1e-6);
    float NoX2 = NoX * NoX;

    float num = 2.0 * NoX;
    float denom = NoX + sqrt(alpha2 + (1.0 - alpha2) * NoX2);

    return num / denom;
}

float G_Smith(float NoV, float NoL, float roughness) {
    return G1_GGX(NoV, roughness) * G1_GGX(NoL, roughness);
}

vec3 fresnelSchlick(float cosTheta, vec3 F0)
{
    return F0 + (vec3(1.0) - F0) * (pow(1.0 - cosTheta, 5.0));
}

vec3 labPBR_HCM_F0(int conductor) {
    if (conductor == 230) return vec3(0.560, 0.570, 0.580); // Iron
    if (conductor == 231) return vec3(0.981, 0.781, 0.497); // Gold
    if (conductor == 232) return vec3(0.700, 0.700, 0.700); // Aluminum
    if (conductor == 234) return vec3(0.955, 0.638, 0.538); // Copper
    return vec3(0.75, 0.75, 0.75);
}

vec3 microfacetBRDF(vec3 L, vec3 V, vec3 N, float labF0_HCM, float roughness, vec3 albedo, vec3 lightColor) {

  vec3 Lo = vec3(0.0);
  
  //calculate light radiance
  float dist = length(L);
  float attenuation = 1.0 / (dist * dist);
  vec3 radiance = lightColor * attenuation; 

  vec3 H = normalize(V + L);

  float NoV = clamp(dot(N, V), 0.0, 1.0);
  float NoL = clamp(dot(N, L), 0.0, 1.0);
  float NoH = clamp(dot(N, H), 0.0, 1.0);
  float VoH = clamp(dot(V, H), 0.0, 1.0);

  vec3 f0;
  float metallic;

  int labG = int(labF0_HCM * 255.0 + 0.5);

  if (labG >= 230) {
    metallic = 1.0;
    f0 = labPBR_HCM_F0(labG);

  } else {
    metallic = 0.0;
    float reflectence = labG / 229.0;
    vec3 f0 = vec3(0.16 * (reflectence * reflectence));

  }

  vec3 F = fresnelSchlick(VoH, f0);
  float D = D_GGX(NoH, roughness);
  float G = G_Smith(NoV, NoL, roughness);

  vec3 spec = (D * F * G) / (4.0 * max(NoL, 1e-6) * max(NoV, 1e-6));

  vec3 rhoD = albedo;

  rhoD *= vec3(1.0) - F;
  rhoD *= (1.0 - metallic);

  vec3 diff = (rhoD / PI) * radiance;

  vec3 result = diff + spec;

  return result;
}
