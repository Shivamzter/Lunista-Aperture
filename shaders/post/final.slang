import aperture;
import lib.tonemap;

Sampler2D finalTex;

[[shader("fragment")]]
float4 main(float2 pos : SV_Position) : SV_Target0 {
    float4 color = finalTex[int2(pos)]; // acts as texelFetch would in GLSL. mainTexture.Sample is equivalent to `texture`.
    // color.rgb = neutral(color.rgb);
    color.rgb = pow(color.rgb, 1.0 / 2.2);
    return color;
}