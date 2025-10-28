import aperture;
import lib.shadowSampling;

Sampler2D mainTexture;
Sampler2D lightmapTex;
Sampler2D normalTexture;
Sampler2D flatNormalTex;
Sampler2D labSpecularTex;

Sampler2D mainDepthTex;

static bool isNight = ap.world.time >= 13000 && ap.world.time <= 24000;

static const float3 blocklightColor = float3(1.0, 0.5, 0.08);
static const float3 skylightColor = float3(0.05, 0.15, 0.3);
// static const float3 sunlightColor = float3(1.0);
static const float3 ambientLight = isNight ? float3(0.01) : float3(0.15);

static const float3 sunLightColor = float3(1.0, 0.98, 0.9);
static const float3 moonLightColor = float3(0.1, 0.1, 0.3);
static float3 planetLightColor = isNight ? moonLightColor : sunLightColor;

static const float STEP_SIZE = 0.05;
static const int NUM_STEPS = 150;

static const float PI = 3.14159265359;
static const int MAX_STEPS = 60;
static const int MAX_STEPS_LIGHTS = 6;

static const float WIND_SPEED = 0.25;
static const float ELAPSED_TIME = ap.timing.timeElapsed;

static const float CLOUD_ALTITUDE = 800.0;
static const float CLOUD_HEIGHT = 200.0;


float3 projectAndDivide(float4x4 projectionMatrix, float3 position) {
    float4 homPos = mul(projectionMatrix, float4(position, 1.0));
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

    float bottom = lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);

    a = random3D(float3(floor(p.x), floor(p.y), ceil(p.z)));
    b = random3D(float3(ceil(p.x), floor(p.y), ceil(p.z)));
    c = random3D(float3(floor(p.x), ceil(p.y), ceil(p.z)));
    d = random3D(float3(ceil(p.xy), ceil(p.z)));

    float top = lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);

    return lerp(bottom, top, f.z);
}

float fractalNoise3D(in float3 p) {
    float total = 0.5;
    float amplitude = 1.0;
    float frequency = 1.0;
    float iterations = 4.0;
    
    for (float i = 0; i < iterations; i++) {
        total += (smoothNoise3D(p * frequency / 1024) - 0.5) * amplitude;
        amplitude *= 0.5;
        frequency *= 2.0;
    }

    return total;
}

float getCloud(float3 p) {
    return clamp((fractalNoise3D(p) * fractalNoise3D(p * 0.25) * fractalNoise3D(p * 0.12) * 4.0 - 0.5) * 1.5 + 0.5, 0, 1.0);
}

float BeersLaw(float dist, float absorption) {
    return exp(-dist * absorption);
}

float lightmarch(float3 position, float3 planetDirection) {
    float3 lightDirection = planetDirection;
    float totalDensity = 0.0;
    float merchSize = 0.03;

    for (int ss = 0; ss < MAX_STEPS_LIGHTS; ss++) {
        position += lightDirection * merchSize * float(ss);
        
        float lightSample = getCloud(position);
        totalDensity += lightSample;
    }

    float transmittance = BeersLaw(totalDensity, ABSORPTION_COEFFICIENT);
    return transmittance;
}

bool getCloudUV(in float3 rayOrigin, in float3 rayDirection, out float3 startPos, out float3 endPos) {
    float upperCloudHeight = CLOUD_ALTITUDE + CLOUD_HEIGHT;
    float lowerCloudHeight = CLOUD_ALTITUDE;

    float t1 = max((upperCloudHeight - rayOrigin.y) / rayDirection.y, 0.0);
    float t2 = max((lowerCloudHeight - rayOrigin.y) / rayDirection.y, 0.0);
    if (abs(t1) == - abs(t2)) return false;

    startPos = rayOrigin + min(t1, t2) * rayDirection;
    endPos = rayOrigin + max(t1, t2) * rayDirection;

    return true;
}

float4 raymarch(float3 rayOrigin, float3 rayDirection, float3 planetLightColor) {

    float3 startPos;
    float3 endPos;

    bool hitPlane = getCloudUV(rayOrigin, rayDirection, startPos, endPos);

    if (!hitPlane) {
        return float4(0.0, 0.0, 0.0, 1.0);
    }

    float3 scattering = 0.0;
    float transmittance = 1.0;

    float scatteringCoefficient = 0.1;
    float absorptionCoefficient = 0.0;

    float extinctionCoefficient = scatteringCoefficient + absorptionCoefficient;

    rayDirection = (endPos - startPos) / float(MAX_STEPS);

    for (int i = 0; i < MAX_STEPS; i++) {
        float3 rayPos = startPos + rayDirection * float(i);

        float sampleDensity = getCloud(rayPos);
        
        if (sampleDensity > 1e-6) {

            float3 scatteredLight = planetLightColor * 1.0;

            float transmittanceAtPoint = BeersLaw(sampleDensity * length(rayDirection), extinctionCoefficient);

            scattering += scatteredLight * scatteringCoefficient * transmittance;
            transmittance *= transmittanceAtPoint;
        }
    }
    
    return float4(scattering, transmittance);
}

// bool rayPlaneIntersection(float3 origin, float3 dir, float height, inout float3 point) {
//   float3 normal = float3(0.0, sign(origin.y - height), 0.0);
//   float3 p = float3(0.0, height, 0.0);

//   float NoD = dot(normal, dir);
//   if (NoD == 0.0) {
//     return false;
//   }

//   float t = dot(normal, p - origin) / NoD;

//   point = origin + t * dir;

//   return t >= 0.0;
// }


[[shader("fragment")]]
float4 applyLighting(float2 pos : SV_Position) : SV_Target0 { 

    float2 texcoord = pos / ap.game.screenSize;

    float4 color = mainTexture[int2(pos)]; // acts as texelFetch would in GLSL. mainTexture.Sample is equivalent to `texture`.
    float2 lightmap = lightmapTex[int2(pos)].rg;
    float4 normals = normalTexture[int2(pos)];
    normals= normalize((normals - 0.5) * 2.0);
    float4 flatNormal = flatNormalTex[int2(pos)];
    flatNormal.rgb = normalize((flatNormal.rgb - 0.5) * 2.0);
    float4 labSpecular = labSpecularTex.Sample(texcoord);

    float depth = mainDepthTex.Sample(texcoord).r;
    
    float3 screenPos = float3(texcoord, depth);
    float3 ndcPos = screenPos * 2.0 - 1.0;
    float3 viewPos = projectAndDivide(ap.camera.projectionInv, ndcPos);
    float3 playerFeetPos = mul(ap.camera.viewInv, float4(viewPos, 1.0)).xyz;
    float3 playerEyePos = mul(float3x3(ap.camera.viewInv), viewPos);

    float3 worldPos = playerFeetPos + ap.camera.position;

    float3 eyeCameraPos = ap.camera.position + ap.camera.viewInv[3].xyz;

    float3 viewDir = normalize(ap.camera.position - worldPos);

    float3 rayOrigin = eyeCameraPos;
    float3 rayDir = normalize(worldPos - rayOrigin);

    float3 lightPos = mul(float3x3(ap.camera.viewInv), normalize(ap.celestial.position));
    lightPos += eyeCameraPos;

    float3 lightDir = normalize(lightPos - worldPos);

    float cloudTime = ap.timing.frameCounter * 0.05;
    float cloudSpeed = 0.5;

    // float2 uv = rayDir.xz * 1.0 / rayDir.y;
    // float2 uv2 = rayDir.xz * 1.0 / rayDir.y;

    // float3 cloudPlaneBottom = float3(uv.x, CLOUD_ALTITUDE, uv.y);
    // float3 cloudPlaneTop = float3(uv2.x, CLOUD_ALTITUDE + CLOUD_HEIGHT, uv2.y);

    if (depth == 1.0 && rayDir.y > 0.0) {

        float4 res = raymarch(eyeCameraPos, rayDir, planetLightColor);

        color.rgb = color.rgb * res.a + res.rgb;
    }

    // float fogAmount = 0.0;
    // float lightIntensity = 1.0;
    // float t = STEP_SIZE;

    // for (int i = 0; i < NUM_STEPS; i++) {
    //     float3 samplePos = rayOrigin + rayDir * t;

    //     float distanceToLight = length(samplePos - lightPos);
    //     float attenuation = 1.0 / distanceToLight;

    //     fogAmount += attenuation * lightIntensity;

    //     t += STEP_SIZE;
    // }
    
    // fogAmount /= float(NUM_STEPS);

    // float3 volumetricLight = planetLightColor * fogAmount;

    float3 shadow = getShadow(playerFeetPos, normals.rgb);

    float3 directLight = clamp(dot(lightPos, normals.rgb), 0.0, 1.0) * shadow;

    float labAO = normals.a;
    float vanillaAO = flatNormal.a;

    float3 blocklight = lightmap.r * blocklightColor;
    float3 skylight = lightmap.g * skylightColor;

    float3 indirectLight = (blocklightColor + skylight + ambientLight) * labAO * vanillaAO;

    color.rgb *= directLight + indirectLight;

    return float4(color.rgb, 1.0);
}