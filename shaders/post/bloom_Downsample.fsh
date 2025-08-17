#version 460 core

in vec2 uv;

uniform sampler2D mainTexture;
uniform sampler2D bloomTex;

vec3 bloomDownsample(sampler2D srcTexture, vec2 coord) {
    vec2 res = textureSize(mainTexture, BLOOM_INDEX);
    vec2 srcRes = 1.0 / res;
    float x = srcRes.x;
    float y = srcRes.y;

    // Take 13 samples around current texel:
    // a - b - c
    // - j - k -
    // d - e - f
    // - l - m -
    // g - h - i
    // === ('e' is the current texel) ===
    vec3 a = textureLod(srcTexture, vec2(coord.x - 2*x, coord.y + 2*y), BLOOM_INDEX).rgb;
    vec3 b = textureLod(srcTexture, vec2(coord.x,       coord.y + 2*y), BLOOM_INDEX).rgb;
    vec3 c = textureLod(srcTexture, vec2(coord.x + 2*x, coord.y + 2*y), BLOOM_INDEX).rgb;

    vec3 d = textureLod(srcTexture, vec2(coord.x - 2*x, coord.y), BLOOM_INDEX).rgb;
    vec3 e = textureLod(srcTexture, vec2(coord.x,       coord.y), BLOOM_INDEX).rgb;
    vec3 f = textureLod(srcTexture, vec2(coord.x + 2*x, coord.y), BLOOM_INDEX).rgb;

    vec3 g = textureLod(srcTexture, vec2(coord.x - 2*x, coord.y - 2*y), BLOOM_INDEX).rgb;
    vec3 h = textureLod(srcTexture, vec2(coord.x,       coord.y - 2*y), BLOOM_INDEX).rgb;
    vec3 i = textureLod(srcTexture, vec2(coord.x + 2*x, coord.y - 2*y), BLOOM_INDEX).rgb;

    vec3 j = textureLod(srcTexture, vec2(coord.x - x, coord.y + y), BLOOM_INDEX).rgb;
    vec3 k = textureLod(srcTexture, vec2(coord.x + x, coord.y + y), BLOOM_INDEX).rgb;
    vec3 l = textureLod(srcTexture, vec2(coord.x - x, coord.y - y), BLOOM_INDEX).rgb;
    vec3 m = textureLod(srcTexture, vec2(coord.x + x, coord.y - y), BLOOM_INDEX).rgb;

    // Apply weighted distribution:
    // 0.5 + 0.125 + 0.125 + 0.125 + 0.125 = 1
    // a,b,d,e * 0.125
    // b,c,e,f * 0.125
    // d,e,g,h * 0.125
    // e,f,h,i * 0.125
    // j,k,l,m * 0.5
    // This shows 5 square areas that are being sampled. But some of them overlap,
    // so to have an energy preserving downsample we need to make some adjustments.
    // The weights are the distributed, so that the sum of j,k,l,m (e.g.)
    // contribute 0.5 to the final color output. The code below is written
    // to effectively yield this sum. We get:
    // 0.125*5 + 0.03125*4 + 0.0625*4 = 1
    vec3 downsample;
    downsample = e * 0.125;
    downsample += (a + c + g + i) * 0.03125;
    downsample += (b + d + f + h) * 0.0625;
    downsample += (j + k + l + m) * 0.125;
    downsample = max(downsample, 0.0001);

    return downsample;
}

layout(location = 0) out vec3 bloom;

void main() {
    if (BLOOM_INDEX == 0) {
    bloom = bloomDownsample(mainTexture, uv);
  } else {
    bloom = bloomDownsample(bloomTex, uv);
  }
}