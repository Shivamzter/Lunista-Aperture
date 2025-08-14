const float PI = 3.14159265359;

float DistributionGGX(vec3 N, vec3 H, float roughness)
{
  float a = roughness * roughness;
  float a2 = a * a;
  float num = a2;

  float NoH  = max(dot(N, H), 0.0);
  float NoH2 = NoH*NoH;
	
  float denom = (NoH2 * (a2 - 1.0) + 1.0);
  denom = PI * denom * denom;
	
  return num / denom;
}

vec3 fresnelSchlick(float cosTheta, vec3 F0)
{
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}  

float GeometryShclickGGX(float NdotX, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;

    float num = NdotX;
    float denom = NdotX * (1.0 - k) + k;
	
    return num / denom;
}

float gGGX(float NoX, float roughness) {
  float num = 2.0 * NoX;
  
  float a = roughness * roughness;
  float a2 = a * a;

//   float NoV = dot(N, V);
  float NoX2 = NoX * NoX;

  float denom = max(NoX, 1e-6) + sqrt(a2 + (1.0 - a2) * NoX2);

  return num / denom;
}

float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
  float NdotV = max(dot(N, V), 1e-6);
  float NdotL = max(dot(N, L), 1e-6);
  float ggx2  = gGGX(NdotV, roughness);
  float ggx1  = gGGX(NdotL, roughness);

  return ggx1 * ggx2;
}

vec3 brdfMicrofacet(vec3 lightColor, vec3 N, vec3 L, vec3 V, float roughness, vec3 labF0, vec3 albedo, float metallic) {

  vec3 Lo = vec3(0.0);
  
  //calculate light radiance
  float dist = length(L);
  float attenuation = 1.0 / (dist * dist);
  vec3 radiance = lightColor * attenuation; 

  vec3 H = normalize(V + L);

  float NoV = max(dot(N, V), 0.0);
  float NoL = max(dot(N, L), 0.0);
  float HoV = max(dot(H, V), 0.0);

  float alpha = roughness * roughness;

  float D = DistributionGGX(N, H, roughness);
  vec3 F = fresnelSchlick(HoV, labF0);
  float G = GeometrySmith(N, V, L, roughness);

  vec3 spec = (D * F * G) / (4.0 * NoL * NoV + 0.0001);

  vec3 kS = F;
  vec3 kD = vec3(1.0) - kS;
  kD *= 1.0 - metallic;

  Lo += (kD * albedo / PI + spec) * radiance * NoL;

  return Lo;
}