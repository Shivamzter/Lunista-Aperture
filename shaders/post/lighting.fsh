#version 460 core

#include "/lib/brdf.glsl"

uniform sampler2D mainTexture; // colortex0
uniform sampler2D lightmapTex;
uniform sampler2D normalTex;
uniform sampler2D specularTex;

uniform sampler2D mainDepthTex;

in vec2 uv;
in vec3 normal;

layout(location = 0) out vec4 colorOut;

bool isNight = ap.world.time >= 13000 && ap.world.time < 24000;

const vec3 blocklightColor = vec3(1.0, 0.5, 0.08);
const vec3 skylightColor = vec3(0.05, 0.15, 0.3);

const vec3 sunlightColor = vec3(23.47, 21.31, 20.79); // vec3(23.47, 21.31, 20.79) BRDF
const vec3 moonlightColor = vec3(0.1, 0.1, 0.3);
vec3 lightColor = isNight ? moonlightColor : sunlightColor;

const vec3 ambientColorDay = vec3(0.15);
const vec3 ambientColorNight = vec3(0.01);
vec3 ambient = isNight ? ambientColorNight : ambientColorDay;

float specularStrength = 0.5;
float emissiveIntensity = 7.5;

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position) {
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

void main() {
	vec3 color = texture(mainTexture, uv).rgb;
  vec3 albedo = color;

  float depth = texture(mainDepthTex, uv).r;

  // if (depth == 1.0) {
  //   return;
  // }

  vec2 lightmap = texture(lightmapTex, uv).rg;
  vec3 encodedNormal = texture(normalTex, uv).rgb;
  vec4 labSpecular = texture(specularTex, uv);

  float labRoughness = labSpecular.r;
  labRoughness = pow(1.0 - labRoughness, 2.0); //convert smoothness to linear roughness

  float labSpecG = labSpecular.g * 255.0;

  float labMetallic = (labSpecG >= 230.0) ? 1.0 : 0.0;
  vec3 f0 = vec3(clamp(labSpecular.g, 0.04, 229.0 / 255.0));

  vec3 labHCM;
  if (labSpecG == 230.0) {
    labHCM = vec3(0.560, 0.570, 0.580); // Iron 
  } else if (labSpecG == 231.0) {
    labHCM = vec3(1.000, 0.710, 0.290); // Gold
  } else if (labSpecG == 232.0) {
    labHCM = vec3(0.910, 0.920, 0.920); // Aluminum
  } else if (labSpecG == 234.0) {
    labHCM = vec3(0.950, 0.640, 0.540); // Copper
  } else {
    labHCM = albedo;
  }

  vec3 labF0 = labMetallic == 1.0 ? labHCM : f0;

  float labEmissive = fract(labSpecular.a);
  vec3 emissiveFinal = labEmissive * albedo * emissiveIntensity;
  
  vec3 normal = normalize((encodedNormal - 0.5) * 2.0); // view space normals
  vec3 vNormal = mat3(ap.camera.viewInv) * normal; // view to player space

  vec3 NDCPos = vec3(uv.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(ap.camera.projectionInv, NDCPos);
  vec3 eyePlayerPos = mat3(ap.camera.viewInv) * viewPos; // player space

  // vec3 lightSunMoon = lightColor * clamp(dot(lightDir, normal), 0.0, 1.0) * lightmap.g;

  vec3 lightDir = mat3(ap.camera.viewInv) * normalize(ap.celestial.pos); // view to player space
  vec3 viewDir = normalize(-eyePlayerPos); // player space

  // float diff = max(dot(vNormal, lightDir), 0.0);
  // vec3 diffuse = diff * lightColor;

  // vec3 halfwayDir = normalize(lightDir + viewDir);

  // float spec = pow(max(dot(vNormal, halfwayDir), 0.0), 128);
  // vec3 specular = specularStrength * spec * lightColor;

  vec3 brdf = brdfMicrofacet(lightColor, vNormal, lightDir, viewDir, labRoughness, labF0, albedo, labMetallic);

  vec3 skylight = lightmap.g * skylightColor;
  vec3 blocklight = lightmap.r * blocklightColor;

  vec3 directLight = brdf;
  vec3 indirectLight = blocklight + skylight + ambient;

  // color.rgb *= ambient + diffuse + specular;
  color.rgb *= indirectLight + directLight;
  color.rgb += emissiveFinal;

  colorOut = vec4(color, 1.0);
  // colorOut = texture(specularTex, uv);
  // colorOut = labSpecular;
}