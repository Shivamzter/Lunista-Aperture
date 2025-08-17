#version 460 core

in vec2 uv;

uniform sampler2D bloomTex;

vec3 bloomDownsample(sampler2D srcTexture, vec2 coord) {
    vec2 res = textureSize(srcTexture, BLOOM_INDEX);
    vec2 srcRes = 1.0 / res;
    float x = srcRes.x;
    float y = srcRes.y;

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
  bloom = bloomDownsample(bloomTex, uv);
}