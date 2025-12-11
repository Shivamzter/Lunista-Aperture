import aperture;

Sampler2D<float3> bloomTex;

extern static const uint MIP_INDEX;

struct VertexOutput {
    // The value after the colon is known as a "semantic", and denotes a special value used by the graphics pipeline.
    // There are many of these usable in both vertex and fragment, but in this case, SV_Position is all we care about; it is equivalent to writing gl_Position.
    float4 position : SV_Position;
    float2 uv;
    float4 color;
};

[[shader("vertex")]]
VertexOutput vertexMain(Vertex input) { // If we had any more vertex semantics we wanted to use, we could declare them after input in the parameters.
    VertexOutput output;

    // The Vertex struct has many built in variables. Some of them are declared as Optional types, meaning they may not be present
    // depending on the object.

    // Basic transformations.
    float4 modelPos = input.pos(); // These functions are capable of running expensive calculations; better to cache when possible.

    output.position = mul(input.projectionMatrix(), mul(input.viewMatrix(), modelPos));
    output.uv = (input.uv() + 1) * 0.5;

    return output;
}

float3 bloomDownsample(float2 pos) {
    float3 res;
    bloomTex.GetDimensions(MIP_INDEX, res.x, res.y, res.z);

    float2 srcRes = float(1) / res.xy;

    float2 texcoord = pos / (ap.game.screenSize);

    float3 a = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(-2, +2)) * srcRes.x;
    float3 b = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(0, +2));
    float3 c = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(+2, +2));

    float3 d = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(-2, 0));
    float3 e = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(0, 0));
    float3 f = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(+2, 0));

    float3 g = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(-2, -2));
    float3 h = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(0, -2));
    float3 i = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(+2, -2));

    float3 j = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(-1, +1));
    float3 k = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(+1, +1));
    float3 l = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(-1, -1));
    float3 m = bloomTex.SampleLevel(texcoord, MIP_INDEX, int2(+1, -1));

    float3 downsample;
    downsample =                e * float3(0.12500);
    downsample += (a + c + g + i) * float3(0.03125);
    downsample += (b + d + f + h) * float3(0.06250);
    downsample += (j + k + l + m) * float3(0.12500);
}

[[shader("fragment")]]
float4 bloomDownsample(VertexOutput input, float2 pos : SV_Position) : SV_Target0 {

    float3 bloom = bloomDownsample(pos);

    return float4(bloom, 1.0);
}