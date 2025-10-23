// Object shaders are required to import the aperture module to gain access to built-in functionality.
import aperture;

// Two entrypoints are required: a vertex entrypoint and a fragment entrypoint. The vertex entrypoint is given
// a `Vertex` object and returns a struct of your choice,
// which is passed to the fragment entrypoint.

struct VertexOutput {
    // The value after the colon is known as a "semantic", and denotes a special value used by the graphics pipeline.
    // There are many of these usable in both vertex and fragment, but in this case, SV_Position is all we care about; it is equivalent to writing gl_Position.
    float4 position : SV_Position;
    float2 uv;
    float4 color;
    float2 light;
    float distance;
    float3 normal;
    float4 tangent;
    float3x3 tbnMatrix;
    float ao;
};

[[shader("vertex")]]
VertexOutput vertexMain(Vertex input) { // If we had any more vertex semantics we wanted to use, we could declare them after input in the parameters.
    VertexOutput output;

    // The Vertex struct has many built in variables. Some of them are declared as Optional types, meaning they may not be present
    // depending on the object.
    

    // Basic transformations.
    float4 modelPos = input.pos(); // These functions are capable of running expensive calculations; better to cache when possible.

    float3 normal = input.normal().orElse(float3(1.0, 1.0, 1.0)); // Model space
    float4 tangent = input.tangent().orElse(float4(1.0, 1.0, 1.0, 1.0)); // Model space
    
    float3x3 tbnMatrix;
    tbnMatrix[2] = normalize(mul(input.normalMatrix(), normal)); // Transform normal to view space.
    tbnMatrix[0] = normalize(mul(input.normalMatrix(), tangent.xyz)); // Transform tangent to view space.
    tbnMatrix[1] = normalize(cross(tbnMatrix[0], tbnMatrix[2]) * sign(tangent.w)); 
    tbnMatrix = mul(float3x3(ap.camera.viewInv), transpose(tbnMatrix)); // Note to self: transpose is needed here because matrix's are just handled differently in slang.

    normal = normalize(mul(input.normalMatrix(), normal));
    normal = normalize(mul(float3x3(ap.camera.viewInv), normal));

    // float3 vNormal = normalize(mul(input.normalMatrix(), normal)); // View space normal
    // float3 vTangent = normalize(mul(input.normalMatrix(), tangent.xyz)); // View space tangent
    // float3 vBitangent = normalize(cross(vTangent, vNormal) * sign(tangent.w));

    // vNormal = normalize(mul(float3x3(ap.camera.viewInv), vNormal));
    // vTangent = normalize(mul(float3x3(ap.camera.viewInv), vTangent));
    // vBitangent = normalize(mul(float3x3(ap.camera.viewInv), vBitangent));

    // float3x3 tbnMatrix = float3x3(vTangent, vBitangent, vNormal); // World space TBN matrix
    // tbnMatrix = mul(float3x3(ap.camera.viewInv), transpose(tbnMatrix));

    output.position = mul(input.projectionMatrix(), mul(input.viewMatrix(), modelPos));
    output.uv = input.uv();
    output.color = input.color();
    output.light = input.light();
    output.distance = length(modelPos);
    output.normal = normal;
    output.tangent = tangent;
    output.tbnMatrix = tbnMatrix;
    output.ao = input.ao();

    // There is... one more thing we should deal with. When an entity gets hit and turns red, this is known as an "overlay color"; and that is a manual job.
    // Overlay color is one of the mentioned Optional semantics; we can check if it exists and apply it if so.
    
    //float4 overlayColor = input.overlayColor().orElse(float4(0.0));
    // orElse is one way to handle an optional, but there is another way. The following allows you to auto-check the existence of an optional.

    if (let overlayColor = input.overlayColor()) {
        output.color = lerp(output.color, overlayColor, overlayColor.a);
    }

    return output;
}

extern static const bool disableFog; // This is set in the pack.ts when creating the object shader. A default value could be given here if desired.

// The fragment entrypoint takes the output of the vertex shader as input.

struct FragmentOutput {
    float4 color : SV_Target0;
    float4 normals : SV_Target1;
    float3 flatNormal : SV_Target2;
}

[[shader("fragment")]]
FragmentOutput fragmentMain(VertexOutput input) { // See the comment in gamma.slang about what targets are.
    // Aperture provides some built-in samplers for object shaders.
    float4 color = albedoTex.Sample(input.uv) * input.color;
    

    color.rgb *= lightmap.Sample(input.light).rgb;
    color.rgb = pow(color.rgb, float3(2.2)); // Simple gamma correction.

    float3x3 tbnMatrix = input.tbnMatrix;

    float4 labNormal = normalTex.Sample(input.uv);

    float labAO = labNormal.b;

    labNormal.xy = labNormal.xy * 2.0 - 1.0;
    labNormal.z = sqrt(1.0 - dot(labNormal.xy, labNormal.xy));
    labNormal.xyz = normalize(mul(tbnMatrix, labNormal.xyz));
    labNormal = float4(labNormal.xyz, labAO);

    float3 flatNormal = input.normal;

    iris_discardIfNeeded(color); // This helper function is given by Aperture to auto-discard if needed in the object shader.

    // Apply fog if needed
    if (!disableFog) {
        float mixValue = (input.distance - ap.world.fogStart) / (ap.world.fogEnd - ap.world.fogStart);

        float renderDistanceFogStart = clamp(ap.world.renderDistance / 10, 4, 64); // Default calculation as of 1.21.10.
        mixValue = max(mixValue, (input.distance - renderDistanceFogStart) / (ap.world.renderDistance - renderDistanceFogStart));

        color = lerp(color, ap.world.fogColor, clamp(mixValue, 0.0, 1.0));
    }
    
    FragmentOutput output;
    output.color = color;
    // output.lightmap = lightmap;
    output.normals = labNormal;
    output.flatNormal = flatNormal;

    return output;
}