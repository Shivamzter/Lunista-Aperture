import aperture;
import lib.shadowSampling;

Sampler2D mainTexture;
Sampler2D lightmapTex;
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

static bool isNight = ap.world.time >= 13000 && ap.world.time <= 24000;

static const float3 blocklightColor = float3(1.0, 0.5, 0.08);
static const float3 skylightColor = float3(0.05, 0.15, 0.3);
// static const float3 sunlightColor = float3(1.0);
static const float3 ambientLight = isNight ? float3(0.01) : float3(0.15);

static const float3 sunLightColor = float3(1.0, 0.98, 0.9);
static const float3 moonLightColor = float3(0.1, 0.1, 0.3);
static float3 planetLight = isNight ? moonLightColor : sunLightColor;

static const float STEP_SIZE = 0.05;
static const int NUM_STEPS = 150;

float3 projectAndDivide(float4x4 projectionMatrix, float3 position) {
    float4 homPos = mul(projectionMatrix, float4(position, 1.0));
    return homPos.xyz / homPos.w;
}

[[shader("fragment")]]
float4 applyLighting(float2 pos : SV_Position) : SV_Target0 { 

    float2 uv = pos / ap.game.screenSize;

    float4 color = mainTexture[int2(pos)]; // acts as texelFetch would in GLSL. mainTexture.Sample is equivalent to `texture`.
    float2 lightmap = lightmapTex[int2(pos)].rg;
    float4 normals = normalTexture[int2(pos)];
    normals= normalize((normals - 0.5) * 2.0);
    float4 flatNormal = flatNormalTex[int2(pos)];
    flatNormal.rgb = normalize((flatNormal.rgb - 0.5) * 2.0);

    float depth = mainDepthTex.Sample(uv).r;
    
    float3 screenPos = float3(uv, depth);
    float3 ndcPos = screenPos * 2.0 - 1.0;
    float3 viewPos = projectAndDivide(ap.camera.projectionInv, ndcPos);
    float3 playerFeetPos = mul(ap.camera.viewInv, float4(viewPos, 1.0)).xyz;
    float3 playerEyePos = mul(float3x3(ap.camera.viewInv), viewPos);

    float3 worldPos = playerFeetPos + ap.camera.position;

    float3 rayOrigin = ap.camera.position;
    float3 rayDir = normalize(worldPos - rayOrigin);

    float3 lightPos = mul(ap.camera.viewInv, float4(normalize(ap.celestial.position), 1.0)).xyz;
    lightPos = lightPos + ap.camera.position;
    
    float3 lightDir = normalize(lightPos - rayOrigin);

    float3 shadow = getShadow(playerFeetPos, flatNormal.rgb, lightPos);

    float fogAmount = 0.0;
    float lightIntensity = 1.0;
    float t = STEP_SIZE;

    for (int i = 0; i < NUM_STEPS; i++) {
        float3 samplePos = rayOrigin + rayDir * t;

        float distanceToLight = length(samplePos - lightPos);
        float attenuation = 1.0 / distanceToLight;

        fogAmount += attenuation * lightIntensity;

        t += STEP_SIZE;
    }
    
    fogAmount /= float(NUM_STEPS);

    float3 volumetricLight = fogAmount;

    float labAO = normals.a;
    float vanillaAO = flatNormal.a;

    // float3 dirLight = clamp(dot(lightPos, normals.rgb), 0.0, 1.0) * shadow;
    color.rgb *= volumetricLight;

    float3 blocklight = lightmap.r * blocklightColor;
    float3 skylight = lightmap.g * skylightColor;

    color.rgb *= shadow;

    float3 indirectLight = (blocklightColor + skylight + ambientLight) * labAO * vanillaAO;

    // color.rgb *= indirectLight + dirLight;

    return float4(color.rgb, 1.0);
}