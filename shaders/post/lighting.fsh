#version 460 core

#include "/lib/brdf.glsl"


uniform sampler2D mainTex; // colortex0
uniform sampler2D lightmapTex;
uniform sampler2D normalTex;
uniform sampler2D specularTex;
uniform sampler2D labNormalTex;
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
  vec3 labNormal = texture(labNormalTex, uv).rgb;
  vec3 flatNormal = texture(flatNormalTex, uv).rgb;

  float depth = texture(mainDepthTex, uv).r;

  // if (depth == 1.0) {
  //   return;
  // }

  vec3 encodedNorm = normalize(encodedNormal.rgb * 2.0 - 1.0);
  float vanillaAO = encodedNormal.a;

  vec3 flatNorm = normalize(flatNormal * 2.0 - 1.0);

  float labAO = labNormal.b;

  float labRoughness = labSpecular.r;
  labRoughness = pow(1.0 - labRoughness, 2.0);
  labRoughness = clamp(labRoughness, 0.001, 1.0);

  float labSpecG = labSpecular.g;


  // float labEmissive = float(labEmissiveDecode);

  // float labEmissive = fract(labSpecular.a);
  // vec3 emissiveFinal = labEmissive * color;
  
  vec3 NDCPos = vec3(uv, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(ap.camera.projectionInv, NDCPos);
  vec3 eyePlayerPos = mat3(ap.camera.viewInv) * viewPos; // player space
  vec3 playerFeetPos = eyePlayerPos + ap.camera.viewInv[3].xyz; // player space

  vec3 lightDir = mat3(ap.camera.viewInv) * normalize(ap.celestial.pos); // view to player space
  vec3 viewDir = normalize(-eyePlayerPos); // player space

  vec3 brdf = microfacetBRDF(lightDir, viewDir, encodedNorm, labSpecG, labRoughness, color, lightColor);

  vec3 skylight = lightmap.g * skylightColor;
  vec3 blocklight = lightmap.r * blocklightColor;

  vec3 shadow = get_shadowed(playerFeetPos, flatNorm, lightDir);

  vec3 directLight = brdf * shadow;
  vec3 indirectLight = (blocklight + skylight + ambient) * vanillaAO * labAO;

  color.rgb *= indirectLight + directLight;
  // color.rgb += emissiveFinal;

  vec3 hdrColor = color.rgb;

  int labSpecAlpha = int(labSpecular.a * 255.0 + 0.5);
  
  // float brightness = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));

  // if (brightness > 1.0) {
  //   bloom = vec3(color.rgb); 
  // } else {
  //   bloom = vec3(0.0);
  // };

  // float threshold = 1.0;   // minimum brightness to bloom
  // float knee = 0.5;        // smooth fade range
  // float x = max(0.0, brightness - threshold);
  // float contribution = x * x / (x + knee * knee);

  vec3 bloomMasked = (labSpecAlpha >= 1 && labSpecAlpha <= 254) ? hdrColor : vec3(0.0);

  bloom = bloomMasked;
  
  colorOut = vec4(color, 1.0);
}