import aperture;
import lib.shadowSampling;
import lib.brdf;

Sampler2D mainTex;
Sampler2D lightmapTex;
Sampler2D encodedNormalTex;
Sampler2D labNormalTex;
Sampler2D labSpecularTex;

Sampler2D mainDepthTex;

// This is a simple way to write to one texture. To write to more, return a struct with multiple SV_TargetN members, like the one below.
/*
struct Output {
    float4 color : SV_Target0;
    float4 normals : SV_Target1;
}
*/

static const float3 blocklightColor = float3(1.0, 0.5, 0.08);
static const float3 skylightColor = float3(0.05, 0.15, 0.3);
static const float3 planetLight = float3(23.47, 21.31, 20.79);
static const float3 ambientStrength = float3(0.1);

static const float EMISSIVE_INTENSITY = 10.0;

float3 projectAndDivide(float4x4 invProj, float3 position) {
    float4 homPos = mul(invProj, float4(position, 1.0));
    return homPos.xyz / homPos.w;
}

struct FragmentOutput {
    float4 color : SV_Target0;
    float4 bloom : SV_Target1;
}

float RGBtoLuminance(float3 col) {
  return dot(col.rgb, float3(0.2126, 0.7152, 0.0722));
}

[[shader("fragment")]]
FragmentOutput applyLighting(float2 pos : SV_Position) { 

    float2 texcoord = pos / ap.game.screenSize;

    float depth = mainDepthTex.Sample(texcoord).r;

    if (depth >= 1.0) {
        discard;
    }

    float4 color = mainTex[int2(pos)];

    float2 lightmap = lightmapTex[int2(pos)].rg;

    float4 encodedNormal = encodedNormalTex[int2(pos)];
    encodedNormal.rgb = normalize((encodedNormal.rgb - 0.5) * 2.0);

    float vanillaAO = encodedNormal.a;

    float4 labNormal = labNormalTex[int2(pos)];
    labNormal.xyz = normalize((labNormal.xyz - 0.5) * 2.0);

    float labAO = labNormal.a;

    float4 labSpecular = labSpecularTex.Sample(texcoord);

    float3 screenPos = float3(texcoord, depth);
    float3 ndcPos = screenPos * 2.0 - 1.0;
    float3 viewPos = projectAndDivide(ap.camera.projectionInv, ndcPos);
    float3 feetPlayerPos = mul(ap.camera.viewInv, float4(viewPos, 1.0)).xyz;
    float3 eyePlayerPos = mul(float3x3(ap.camera.viewInv), viewPos);

    float3 blocklight = lightmap.r * blocklightColor;
    float3 skylight = lightmap.g * skylightColor;

    float3 lightPos = normalize(ap.celestial.position);
    float3 lightDir = mul(float3x3(ap.camera.viewInv), lightPos);

    float3 viewDir = normalize(-eyePlayerPos);

    float3 shadow = getShadow(feetPlayerPos, encodedNormal.rgb);

    float3 albedo = color.rgb;

    // LabPBR
    float labRoughness = pow(1.0 - labSpecular.r, 2.0);
    // roughness = clamp(roughness, 1e-6, 1.0);
    float labReflectance = labSpecular.g;
    float labEmissive = labSpecular.a;

    float3 brdf = brdfMicrofacet(lightDir, viewDir, labNormal.rgb, labRoughness, albedo, labReflectance, planetLight);

    float3 ambient = ambientStrength * albedo;

    float3 dirLight = brdf * shadow;
    float3 indirectLight = (blocklight + skylight + ambient) * labAO * vanillaAO;

    color.rgb *= dirLight + indirectLight;

    if (int(labEmissive * 255 + 0.5) <= 254) {
        color.rgb += color.rgb * labEmissive * EMISSIVE_INTENSITY;
    }

    FragmentOutput output;

    output.color = float4(color.rgb, 1.0);
    output.bloom = float4(color.rgb, 1.0); 

    return output;
}