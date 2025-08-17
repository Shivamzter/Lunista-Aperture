#version 460 core

#include "/lib/brdf.glsl"


uniform sampler2D mainTexture; // colortex0
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
layout (location = 1) out vec4 brightColor;

bool isNight = ap.world.time >= 13000 && ap.world.time < 24000;

const vec3 blocklightColor = vec3(1.0, 0.5, 0.08);
const vec3 skylightColor = vec3(0.05, 0.15, 0.3);

const vec3 sunlightColor = vec3(23.47, 21.31, 20.79) * 2.5; // vec3(23.47, 21.31, 20.79) BRDF
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

vec3 screen_to_view_space(vec3 position_screen) {
    vec3 position_ndc = position_screen * 2.0 - 1.0;
    return projectAndDivide(ap.camera.projectionInv, position_ndc);
}
vec3 view_to_screen_space(vec3 position_view) {
    vec3 position_ndc = projectAndDivide(ap.camera.projection, position_view);
    return position_ndc * 0.5 + 0.5;
}

vec3 view_to_scene_space(vec3 position_view) {
  vec3 position_scene = mat3(ap.camera.viewInv) * position_view;
    return position_scene;
}

#include "/lib/shadowSampling.glsl"

void main() {
	vec3 color = texture(mainTexture, uv).rgb;
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

  float labSpecG = labSpecular.g;

  float labEmissive = fract(labSpecular.a);
  vec3 emissiveFinal = labEmissive * color * emissiveIntensity;
  
  vec3 NDCPos = vec3(uv, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(ap.camera.projectionInv, NDCPos);
  vec3 eyePlayerPos = mat3(ap.camera.viewInv) * viewPos; // player space
  vec3 playerFeetPos = eyePlayerPos + ap.camera.viewInv[3].xyz; // player space

  // vec3 pos_screen = vec3(uv, depth);
  // vec3 pos_view   = screen_to_view_space(pos_screen);
  // vec3 pos_scene  = view_to_scene_space(pos_view);

  vec3 lightDir = mat3(ap.camera.viewInv) * normalize(ap.celestial.pos); // view to player space
  vec3 viewDir = normalize(-eyePlayerPos); // player space

  vec3 brdf = microfacetBRDF(lightDir, viewDir, encodedNorm, labSpecG, labRoughness, color, lightColor);

  vec3 skylight = lightmap.g * skylightColor;
  vec3 blocklight = lightmap.r * blocklightColor;

  // vec3 shadow = get_shadow(eyePlayerPos, flatNorm, lightDir);
  vec3 shadow = get_shadowed(playerFeetPos, flatNorm, lightDir);

  vec3 directLight = brdf * shadow;
  vec3 indirectLight = (blocklight + skylight + ambient) * vanillaAO;

  // vec3 shadow_view_normal = flatNorm + ap.camera.viewInv[3].xyz; // player space

  // vec3 shadow_view_normal = (ap.celestial.view) * flatNorm;
  // vec3 shadow_view_pos = (ap.celestial.view * vec4(playerPos, 1.0)).xyz;

  color.rgb *= indirectLight + directLight;
  color.rgb += emissiveFinal;
  color.rgb *= labAO; // Apply ambient occlusion

  // float d = -viewPos.z; // if viewPos is camera-space (z negative forward)
  // int ccascade = (d < 32.0) ? 0 : (d < 96.0) ? 1 : (d < 192.0) ? 2 : 3;
  // vec3 col = vec3(float(ccascade)/3.0);
  // outColor = vec4(col,1.0);

  float brightness = dot(emissiveFinal.rgb, vec3(0.2126, 0.7152, 0.0722));

  
  // colorOut = vec4(vec3(shadow / 3.0), 1.0); // Debugging cascade
  // colorOut = texture(specularTex, uv);
  // colorOut = labSpecular;

  // float brightness = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
  if (brightness > 1.0) {
    brightColor = vec4(color.rgb, 1.0);
  } else {
    brightColor = vec4(0.0, 0.0, 0.0, 1.0);
  }
  
  colorOut = vec4(color, 1.0);
  // colorOut = vec4(brightness, brightness, brightness, 1.0);
}