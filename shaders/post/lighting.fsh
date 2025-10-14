#version 460 core

#include "/lib/brdf.glsl"
#include "/lib/spaceConversion.glsl"

uniform sampler2D mainTex; // colortex0
uniform sampler2D lightmapTex;
uniform sampler2D normalTex;
uniform sampler2D specularTex;
uniform sampler2D flatNormalTex;

uniform sampler2DArrayShadow shadowMapFiltered;

uniform sampler2D mainDepthTex;

in vec2 uv;
in vec3 normal;

layout (location = 0) out vec4 colorOut;
layout (location = 1) out vec3 bloom;

bool isNight = ap.world.time >= 13000 && ap.world.time < 24000;

const vec3 blocklightColor = vec3(1.0, 0.5, 0.08);
const vec3 skylightColor = vec3(0.05, 0.15, 0.3);

const vec3 sunlightColor = vec3(1.051, 0.985, 0.94) * 20; // vec3(23.47, 21.31, 20.79) BRDF
const vec3 moonlightColor = sunlightColor * 0.00025; // vec3(0.1, 0.1, 0.3)
vec3 lightColor = isNight ? moonlightColor : sunlightColor;

const vec3 ambientColorDay = vec3(0.15);
const vec3 ambientColorNight = vec3(0.01);
vec3 ambient = isNight ? ambientColorNight : ambientColorDay;

float specularStrength = 0.5;
float emissiveIntensity = 1.0;

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position) {
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

#include "/lib/shadowSampling.glsl"

void main() {
	vec3 color = texture(mainTex, uv).rgb;
  vec2 lightmap = texture(lightmapTex, uv).rg;
  vec4 labSpecular = texture(specularTex, uv);
  vec4 encodedNormal = texture(normalTex, uv);
  vec4 flatNormal = texture(flatNormalTex, uv);

  float depth = texture(mainDepthTex, uv).r;

  // if (depth == 1.0) {
  //   return;
  // }

  float labAO = encodedNormal.a;
  float vanillaAO = flatNormal.a;

  encodedNormal.rgb = normalize(encodedNormal.rgb * 2.0 - 1.0);
  flatNormal.rgb = normalize(flatNormal.rgb * 2.0 - 1.0);

  float labRoughness = labSpecular.r;
  labRoughness = pow(1.0 - labRoughness, 2.0);
  labRoughness = clamp(labRoughness, 0.001, 1.0);

  float labSpecG = labSpecular.g;
  
  vec3 screenPos = vec3(uv, depth);
  vec3 NDCPos = screenPos * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(ap.camera.projectionInv, NDCPos);
  vec3 eyePlayerPos = mat3(ap.camera.viewInv) * viewPos;
  vec3 playerFeetPos = (ap.camera.viewInv * vec4(viewPos, 1.0)).xyz;

  vec3 lightDir = mat3(ap.camera.viewInv) * normalize(ap.celestial.pos); // view to eyePlayer space
  vec3 viewDir = normalize(-eyePlayerPos); // player space

  vec3 brdf = microfacetBRDF(lightDir, viewDir, encodedNormal.rgb, labSpecG, labRoughness, color, lightColor);

  vec3 skylight = lightmap.g * skylightColor;
  vec3 blocklight = lightmap.r * blocklightColor;

  vec3 shadow = get_shadowed(playerFeetPos, flatNormal.rgb, lightDir);

  vec3 directLight = brdf * shadow;
  vec3 indirectLight = (blocklight + skylight + ambient) * vanillaAO * labAO;

  color *= indirectLight + directLight;

  int labSpecA = int(labSpecular.a * 255.0 + 0.5);
  // vec3 labEmissive = vec3(labSpecA) * color * emissiveIntensity;

  vec3 labEmissive = (labSpecA >= 1 && labSpecA <= 254) ? vec3(labSpecA) * color * emissiveIntensity : vec3(0.0);

  color += labEmissive;
  bloom = color;
  
  colorOut = vec4(color, 1.0);
}