import aperture;

Sampler2D<half3> bloomTex;

extern static const uint MIP_INDEX;

[[shader("fragment")]]
float4 bloomUpsample(float2 pos : SV_Position) : SV_Target0 {

    float2 texcoord = pos / (ap.game.screenSize >> (MIP_INDEX - 1));

    // The filter kernel is applied with a radius, specified in texture
    // coordinates, so that the radius will vary across mip resolutions.

    // Take 9 samples around current texel:
    // a - b - c
    // d - e - f
    // g - h - i
    // === ('e' is the current texel) ===
    half3 a = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(-1, +1));
    half3 b = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(0, +1));
    half3 c = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(+1, +1));

    half3 d = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(-1, 0));
    half3 e = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(0, 0));
    half3 f = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(+1, 0));

    half3 g = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(-1, -1));
    half3 h = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(0, -1));
    half3 i = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(+1, -1));

    // Apply weighted distribution, by using a 3x3 tent filter:
    //  1   | 1 2 1 |
    // -- * | 2 4 2 |
    // 16   | 1 2 1 |

    half3 upsample = e * half3(4.0);
    upsample += (b + d + f + h) * half3(2.0);
    upsample += (a + c + g + i);
    upsample *= half3(1.0 / 16.0);

    return float4(upsample, 1.0);
}