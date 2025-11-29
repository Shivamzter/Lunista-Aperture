import aperture;
import lib.tonemap;

Sampler2D finalTex;
Sampler2D bloomTex;

[[shader("fragment")]]
float4 main(float2 pos : SV_Position) : SV_Target0 {
    float4 color = finalTex[int2(pos)]; // acts as texelFetch would in GLSL. mainTexture.Sample is equivalent to `texture`.

    float4 bloom = bloomTex[int2(pos)];

    float3 finalScene = color.rgb + (0.04 * bloom.rgb);

    // reinhard tone mapping
    finalScene = finalScene / (finalScene + float3(1.0));
    // finalScene = agx(finalScene);
    finalScene = pow(finalScene, 1.0 / 2.2);

    return float4(finalScene, 1.0);
}