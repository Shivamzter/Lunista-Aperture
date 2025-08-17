#version 460 core
  
in vec2 uv;

uniform sampler2D mainTexture;
uniform sampler2D bloomTex;

vec3 bloomUpsample(sampler2D srcTexture, vec2 coord) {
    vec2 res = textureSize(mainTexture, BLOOM_INDEX);
    vec2 srcRes = 1.0 / res;
    float x = srcRes.x;
    float y = srcRes.y;

    // Take 9 samples around current texel:
    // a - b - c
    // d - e - f
    // g - h - i
    // === ('e' is the current texel) ===
    vec3 a = textureLod(srcTexture, vec2(coord.x - x, coord.y + y), BLOOM_INDEX).rgb;
    vec3 b = textureLod(srcTexture, vec2(coord.x,     coord.y + y), BLOOM_INDEX).rgb;
    vec3 c = textureLod(srcTexture, vec2(coord.x + x, coord.y + y), BLOOM_INDEX).rgb;

    vec3 d = textureLod(srcTexture, vec2(coord.x - x, coord.y), BLOOM_INDEX).rgb;
    vec3 e = textureLod(srcTexture, vec2(coord.x,     coord.y), BLOOM_INDEX).rgb;
    vec3 f = textureLod(srcTexture, vec2(coord.x + x, coord.y), BLOOM_INDEX).rgb;

    vec3 g = textureLod(srcTexture, vec2(coord.x - x, coord.y - y), BLOOM_INDEX).rgb;
    vec3 h = textureLod(srcTexture, vec2(coord.x,     coord.y - y), BLOOM_INDEX).rgb;
    vec3 i = textureLod(srcTexture, vec2(coord.x + x, coord.y - y), BLOOM_INDEX).rgb;

    // Apply weighted distribution, by using a 3x3 tent filter:
    //  1   | 1 2 1 |
    // -- * | 2 4 2 |
    // 16   | 1 2 1 |
    vec3 upsample = e * 4.0;
    upsample += (b + d + f + h) * 2.0;
    upsample += a + c + g + i;
    upsample /= 16.0;

    return upsample;
}

layout(location = 0) out vec3 bloom;

void main() {
//     if (BLOOM_INDEX == 1) {
//         bloom = texture(mainTexture, uv).rgb;
//     } else {
//         bloom = textureLod(bloomTex, uv, BLOOM_INDEX - 1).rgb;
//     }

//   bloom += bloomUpsample(bloomTex, uv);
  #if BLOOM_INDEX == 1
  bloom = texture(mainTexture, uv).rgb;

  #else
  bloom = textureLod(bloomTex, uv, BLOOM_INDEX - 1).rgb;
  #endif

  bloom += bloomUpsample(bloomTex, uv);
}