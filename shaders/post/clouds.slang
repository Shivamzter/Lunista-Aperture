import aperture;


Sampler2D mainTexture;
// Sampler2D flatNormalTex;

Sampler2D mainDepthTex;

// This is a simple way to write to one texture. To write to more, return a struct with multiple SV_TargetN members, like the one below.
/*
struct Output {
    float4 color : SV_Target0;
    float4 normals : SV_Target1;
}
*/

static bool isNight = ap.world.time >= 13000 && ap.world.time <= 24000;

static const float3 sunLightColor = float3(1.47, 1.31, 1.79);
static const float3 moonLightColor = float3(0.1, 0.1, 0.3);
static float3 planetLight = isNight ? moonLightColor : sunLightColor;

float3 projectAndDivide(float4x4 projectionMatrix, float3 ndcPos) {
    float4 homPos = mul(projectionMatrix, float4(ndcPos, 1.0));
    return homPos.xyz / homPos.w;
}

float random3D(in float3 p) {
    return fract(sin(p.x * 456.0 + p.y * 56.0 + p.z * 741.0) * 100.0);
}

float3 smoothv2(in float3 v) {
    return v * v * (3.0 - 2.0 * v);
}

float smoothNoise3D(in float3 p) {
    float3 f = smoothv2(fract(p));

    float a = random3D(floor(p));
    float b = random3D(float3(ceil(p.x), floor(p.y), floor(p.z)));
    float c = random3D(float3(floor(p.x), ceil(p.y), floor(p.z)));
    float d = random3D(float3(ceil(p.xy), floor(p.z)));

    float bottom = lerp( lerp(a, b, f.x), lerp(c, d, f.x), f.y);

    a = random3D(float3(floor(p.x), floor(p.y), ceil(p.z)));
    b = random3D(float3(ceil(p.x), floor(p.y), ceil(p.z)));
    c = random3D(float3(floor(p.x), ceil(p.y), ceil(p.z)));
    d = random3D(float3(ceil(p.xy), ceil(p.z)));

    float top = lerp( lerp(a, b, f.x), lerp(c, d, f.x), f.y);

    return lerp(bottom, top, f.z);
}

float fractalNoise3D(in float3 p) {
    float total = 0.5;
    float amplitude = 1.0;
    float frequency = 1.0;
    float iterations = 4.0;
    
    for (float i = 0; i < iterations; i++) {
        total += (smoothNoise3D(p * frequency) - 0.5) * amplitude;
        amplitude *= 0.5;
        frequency *= 2.0;
    }

    return total;
}

[[shader("fragment")]]
float4 applyClouds(float2 pos : SV_Position) : SV_Target0 { 

    float2 texcoord = pos / ap.game.screenSize;

    float4 color = mainTexture[int2(pos)]; // acts as texelFetch would in GLSL. mainTexture.Sample is equivalent to `texture`.
    // float3 flatNormal = flatNormalTex[int2(pos)].xyz;
    // flatNormal = flatNormal * 0.5 + 0.5;

    float depth = mainDepthTex.Sample(texcoord).r;

    if (depth == 1.0) {
        float3 screenPos = float3(texcoord, depth);
        float3 ndcPos = screenPos * 2.0 - 1.0;
        float3 viewPos = projectAndDivide(ap.camera.projectionInv, ndcPos);
        float3 playerFeetPos = mul(ap.camera.viewInv, float4(viewPos, 1.0)).xyz;

        float3 rayDir = normalize(playerFeetPos.xyz);

        float2 uv = rayDir.xz * 1.0 / rayDir.y + 0.05 * ap.timing.frameCounter * 0.01;
        float2 uv2 = rayDir.xz * 3.0 / rayDir.y - 0.02 * ap.timing.frameCounter * 0.01;

        // Add clouds
        float4 clouds = float4(1.0, 1.0, 1.0, 0.0);
        float scale = 0.1;

        if (rayDir.y > 0.0) {
            float3 player = float3(uv, 0.0);
            float3 player2 = float3(uv2, 0.0);
            float3 skyColor = color.rgb;

            for (float s = 0.0; s < 20.0 && clouds.a < 0.99; s++) {
                float3 rayPos = player + rayDir * s * scale;
                float3 rayPos2 = player2 + rayDir * s * 3.0 * scale;

                float4 cloud = float4(fractalNoise3D(rayPos) * fractalNoise3D(rayPos2));
                // Making holes and density
                clouds.a = clamp((clouds.a - 0.3) * 4.0, 0.1, 2.0);
                cloud.rgb = lerp(float3(1.0), skyColor, min(1.0 , s / 20.0 + 0.1 * (1.0 - clouds.a)));
                // cloud.rgb = float3(1.0);
                // Blending
                clouds.rgb = lerp(clouds.rgb, cloud.rgb, (1.0 - clouds.a) * cloud.a);
                clouds.a = clamp(clouds.a + (1.0 - clouds.a) * cloud.a, 0.0, 1.0);
            }

            clouds.rgb = lerp(clouds.rgb, skyColor, pow(1.0 - rayDir.y, 4.0));

        } else {
            clouds = float4(0.0);
        }

        float cloudFog = 1.0 + 1.0 / rayDir.y;

        // Setting white
        // clouds.rgb = float3(1.0);
        // Shading
        // clouds.rgb *= 1.0 - clamp((clouds.a - 0.5) * 0.1, 0.0, 0.25);
        // Blending
        color.rgb = lerp(color.rgb, clouds.rgb, min(clouds.a, 1.0) / max(1.0, cloudFog * 1.0));
    }
    
    

    // float3 lightDir = mul(float3x3(ap.camera.viewInv), normalize(ap.celestial.position));

    // float3 lightVector = normalize(ap.celestial.position);
    // float3 worldLightVector = normalize(mul(float3x3(ap.camera.viewInv), lightVector));

    return float4(color.rgb, 1.0);
}