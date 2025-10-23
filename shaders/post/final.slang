import aperture;

Sampler2D finalTexture;

[[shader("fragment")]]
float4 main(float2 pos : SV_Position) : SV_Target0 {
    float4 color = finalTexture[int2(pos)];
    color.rgb = pow(color.rgb, 1.0 / 2.2);
    return color;
}