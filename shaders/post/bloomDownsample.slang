import aperture;

Sampler2D<half3> bloomTex;

extern static const uint MIP_INDEX;

[[shader("fragment")]]
float4 bloomDownsample(float2 pos : SV_Position) : SV_Target0 {

    float2 texcoord = pos / (ap.game.screenSize >> (MIP_INDEX + 1));

    half3 a = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(-2, +2));
    half3 b = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(0, +2));
    half3 c = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(+2, +2));

    half3 d = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(-2, 0));
    half3 e = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(0, 0));
    half3 f = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(+2, 0));

    half3 g = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(-2, -2));
    half3 h = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(0, -2));
    half3 i = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(+2, -2));

    half3 j = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(-1, +1));
    half3 k = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(+1, +1));
    half3 l = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(-1, -1));
    half3 m = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(+1, -1));

    float3 downsample;
    downsample =                e * half3(0.12500);
    downsample += (a + c + g + i) * half3(0.03125);
    downsample += (b + d + f + h) * half3(0.06250);
    downsample += (j + k + l + m) * half3(0.12500);

    return float4(downsample, 1.0);
}