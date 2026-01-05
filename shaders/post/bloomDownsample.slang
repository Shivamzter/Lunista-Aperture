import aperture;

Sampler2D<float3> bloomTex;

extern static const uint MIP_INDEX;

[[shader("fragment")]]
float4 bloomDownsample(float2 pos : SV_Position) : SV_Target0 { 

    // float2 texcoord = pos / ap.game.screenSize;

    float3 res;
    bloomTex.GetDimensions(MIP_INDEX, res.x, res.y, res.z);

    float2 srcRes = 1.0 / res.xy;
    float2 texcoord = 2.0 * pos * srcRes;

    float x = srcRes.x;
    float y = srcRes.y;

    float3 a = bloomTex.SampleLevel(float2(texcoord.x - 2 * x, texcoord.y + 2 * y), MIP_INDEX);
    float3 b = bloomTex.SampleLevel(float2(texcoord.x        , texcoord.y + 2 * y), MIP_INDEX);
    float3 c = bloomTex.SampleLevel(float2(texcoord.x + 2 * x, texcoord.y + 2 * y), MIP_INDEX);

    float3 d = bloomTex.SampleLevel(float2(texcoord.x - 2 * x, texcoord.y), MIP_INDEX);
    float3 e = bloomTex.SampleLevel(float2(texcoord.x        , texcoord.y), MIP_INDEX);
    float3 f = bloomTex.SampleLevel(float2(texcoord.x + 2 * x, texcoord.y), MIP_INDEX);

    float3 g = bloomTex.SampleLevel(float2(texcoord.x - 2 * x, texcoord.y - 2 * y), MIP_INDEX);
    float3 h = bloomTex.SampleLevel(float2(texcoord.x        , texcoord.y - 2 * y), MIP_INDEX);
    float3 i = bloomTex.SampleLevel(float2(texcoord.x + 2 * x, texcoord.y - 2 * y), MIP_INDEX);

    float3 j = bloomTex.SampleLevel(float2(texcoord.x - x    , texcoord.y + y), MIP_INDEX);
    float3 k = bloomTex.SampleLevel(float2(texcoord.x + x    , texcoord.y + y), MIP_INDEX);
    float3 l = bloomTex.SampleLevel(float2(texcoord.x - x    , texcoord.y - y), MIP_INDEX);
    float3 m = bloomTex.SampleLevel(float2(texcoord.x + x    , texcoord.y - y), MIP_INDEX);

    float3 downsample =         e * float3(0.12500);
    downsample += (a + c + g + i) * float3(0.03125);
    downsample += (b + d + f + h) * float3(0.06250);
    downsample += (j + k + l + m) * float3(0.12500);

    return float4(downsample, 1.0);
}