import aperture;
import lib.shadowSampling;

Sampler2D mainTexture;
Sampler2D normalTexture;
Sampler2D flatNormalTex;

Sampler2D mainDepthTex;

// This is a simple way to write to one texture. To write to more, return a struct with multiple SV_TargetN members, like the one below.
/*
struct Output {
    float4 color : SV_Target0;
    float4 normals : SV_Target1;
}
*/

// static const float3 blocklightColor = float3(1.0, 0.5, 0.08);
// static const float3 skylightColor = float3(0.05, 0.15, 0.3);
// static const float3 sunlightColor = float3(1.0);
// static const float3 ambientColor = float3(0.1);

static bool isNight = ap.world.time >= 13000 && ap.world.time <= 24000;

static const float3 sunLightColor = float3(1.47, 1.31, 1.79);
static const float3 moonLightColor = float3(0.1, 0.1, 0.3);
static float3 planetLight = isNight ? moonLightColor : sunLightColor;

float3 projectAndDivide(float4x4 projectionMatrix, float3 ndcPos) {
    float4 homPos = mul(projectionMatrix, float4(ndcPos, 1.0));
    return homPos.xyz / homPos.w;
}

[[shader("fragment")]]
float4 applyLighting(float2 pos : SV_Position) : SV_Target0 { 

    float2 uv = pos / ap.game.screenSize;

    float4 color = mainTexture[int2(pos)]; // acts as texelFetch would in GLSL. mainTexture.Sample is equivalent to `texture`.
    float4 normals = normalTexture[int2(pos)];
    normals.rgb = normals.rgb * 0.5 + 0.5;
    float3 flatNormal = flatNormalTex[int2(pos)].xyz;
    flatNormal = flatNormal * 0.5 + 0.5;
    flatNormal = flatNormal * 2.0 - 1.0;

    float depth = mainDepthTex.Sample(uv).r;
    
    float3 screenPos = float3(uv, depth);
    float3 ndcPos = screenPos * 2.0 - 1.0;
    float3 viewPos = projectAndDivide(ap.camera.projectionInv, ndcPos);
    float3 playerFeetPos = mul(ap.camera.viewInv, float4(viewPos, 1.0)).xyz;

    float3 lightDir = mul(float3x3(ap.camera.viewInv), normalize(ap.celestial.position));

    float3 lightVector = normalize(ap.celestial.position);
    float3 worldLightVector = normalize(mul(float3x3(ap.camera.viewInv), lightVector));

    float labAO = normals.a;
    color.rgb *= labAO;

    float3 shadow = getShadow(playerFeetPos, flatNormal, lightDir);

    float3 dirLight = planetLight * clamp(dot(worldLightVector, flatNormal), 0.0, 1.0) * shadow;

    color.rgb *= dirLight;

    return float4(color.rgb, 1.0);
}