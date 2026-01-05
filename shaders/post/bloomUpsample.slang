import aperture;

Sampler2D<float3> bloomTex;

extern static const uint MIP_INDEX;

[[shader("fragment")]]
float4 bloomUpsample(float2 pos : SV_Position) : SV_Target0 {

    float3 res;
    bloomTex.GetDimensions(MIP_INDEX, res.x, res.y, res.z);

    float2 srcRes = 1.0 / res.xy;
    float2 texcoord = 0.5 * pos * srcRes;

    float3 a = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(-1, +1));
    float3 b = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(0, +1));
    float3 c = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(+1, +1));

    float3 d = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(-1, 0));
    float3 e = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(0, 0));
    float3 f = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(+1, 0));

    float3 g = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(-1, -1));
    float3 h = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(0, -1));
    float3 i = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(+1, -1));

    float3 upsample = e * float3(4.0);
    upsample += (b + d + f + h) * float3(2.0);
    upsample += (a + c + g + i);
    upsample *= float3(1.0 / 16.0);

    return float4(upsample, 1.0);
}