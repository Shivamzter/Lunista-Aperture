#version 460 core

uniform sampler2D mainTex; // colortex0
uniform sampler2D lightmapTex;
uniform sampler2D normalTex;

uniform sampler2D mainDepthTex;

uniform sampler2DArrayShadow shadowMapFiltered;

in vec2 uv;
in vec3 normal;

layout(location = 0) out vec4 colorOut;

bool isNight = ap.world.time >= 13000 && ap.world.time < 24000;

const vec3 blocklightColor = vec3(1.0, 0.5, 0.08);
const vec3 skylightColor = vec3(0.05, 0.15, 0.3);

const vec3 sunlightColor = vec3(1.47, 1.31, 1.79); // vec3(23.47, 21.31, 20.79) BRDF
const vec3 moonlightColor = vec3(0.1, 0.1, 0.3);
vec3 light = isNight ? moonlightColor : sunlightColor;

const vec3 ambientColorDay = vec3(0.15);
const vec3 ambientColorNight = vec3(0.01);
vec3 ambient = isNight ? ambientColorNight : ambientColorDay;

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position) {
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

vec3 getWorldPos(vec2 uv, float depth) {
  vec3 NDCPos = vec3(uv.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(ap.camera.projectionInv, NDCPos);
  return (ap.camera.viewInv * vec4(viewPos, 1.0)).xyz;
}

#include "/lib/shadowSampling.glsl"

void main() {
	vec3 color = texture(mainTex, uv).rgb;
  float depth = texture(mainDepthTex, uv).r;

  // if (depth == 1.0) {
  //   return;
  // }

  // vec3 NDCPos = vec3(uv.xy, depth) * 2.0 - 1.0;
  // vec3 viewPos = projectAndDivide(ap.camera.projectionInv, NDCPos);
  // vec3 feetPlayerPos = (ap.camera.viewInv * vec4(viewPos, 1.0)).xyz;

  vec3 playerWorldPos = getWorldPos(uv, depth);

  vec2 lightmap = texture(lightmapTex, uv).rg;
  vec3 encodedNormal = texture(normalTex, uv).rgb;
  vec3 normal = normalize((encodedNormal - 0.5) * 2.0);

  vec3 lightDir = mat3(ap.camera.viewInv) * normalize(ap.celestial.pos);

  vec3 blocklight = lightmap.r * blocklightColor;
  vec3 skylight = lightmap.g * skylightColor;

  vec3 lightVector = normalize(ap.celestial.pos); // View space
  vec3 worldLightVector = mat3(ap.camera.viewInv) * lightVector; // World space

  vec3 shadow = get_shadowed(playerWorldPos, normal, lightDir); // all in world space

  vec3 dirLight = light * clamp(dot(worldLightVector, normal), 0.0, 1.0) * shadow;

  color.rgb *= blocklight + skylight + ambient + dirLight;

  colorOut = vec4(color, 1.0);
}