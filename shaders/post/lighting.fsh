#version 460 core

uniform sampler2D mainTexture; // colortex0
uniform sampler2D lightmapTex;
uniform sampler2D normalTex;

uniform sampler2D normals; // labPBR normal map

uniform sampler2D mainDepthTex;

in vec2 uv;
in vec3 normal;

layout(location = 0) out vec4 colorOut;

bool isNight = ap.world.time >= 13000 && ap.world.time < 24000;

// const vec3 blocklightColor = vec3(1.0, 0.5, 0.08);
// const vec3 skylightColor = vec3(0.05, 0.15, 0.3);

const vec3 sunlightColor = vec3(2.47, 2.31, 2.79); // vec3(23.47, 21.31, 20.79) BRDF
const vec3 moonlightColor = vec3(0.1, 0.1, 0.3);
vec3 lightColor = isNight ? moonlightColor : sunlightColor;

const vec3 ambientColorDay = vec3(0.15);
const vec3 ambientColorNight = vec3(0.01);
vec3 ambient = isNight ? ambientColorNight : ambientColorDay;

float specularStrength = 0.5;

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position) {
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

void main() {
	vec3 color = texture(mainTexture, uv).rgb;

  float depth = texture(mainDepthTex, uv).r;

  // if (depth == 1.0) {
  //   return;
  // }

  vec2 lightmap = texture(lightmapTex, uv).rg;
  vec3 encodedNormal = texture(normalTex, uv).rgb;
  
  vec3 normal = normalize((encodedNormal - 0.5) * 2.0); // view space normals
  vec3 vNormal = mat3(ap.camera.viewInv) * normal; // view to player space

  vec3 NDCPos = vec3(uv.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(ap.camera.projectionInv, NDCPos);
  vec3 eyePlayerPos = mat3(ap.camera.viewInv) * viewPos; // player space

  // vec3 lightSunMoon = lightColor * clamp(dot(lightDir, normal), 0.0, 1.0) * lightmap.g;

  vec3 lightDir = mat3(ap.camera.viewInv) * normalize(ap.celestial.pos); // view to player space
  vec3 viewDir = normalize(-eyePlayerPos); // player space

  float diff = max(dot(vNormal, lightDir), 0.0);
  vec3 diffuse = diff * lightColor;

  vec3 halfwayDir = normalize(lightDir + viewDir);

  float spec = pow(max(dot(vNormal, halfwayDir), 0.0), 128);
  vec3 specular = specularStrength * spec * lightColor;

  // vec3 skylight = lightmap.g * skylightColor;
  // vec3 blocklight = lightmap.r * blocklightColor;

  color.rgb *= ambient + diffuse + specular;

  colorOut = vec4(color, 1.0);
  // colorOut = texture(normalTex, uv);
}