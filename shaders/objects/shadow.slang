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
};

[[shader("vertex")]]
VertexOutput vertexMain(Vertex input) { // If we had any more vertex semantics we wanted to use, we could declare them after input in the parameters.
    VertexOutput output;

    // The Vertex struct has many built in variables. Some of them are declared as Optional types, meaning they may not be present
    // depending on the object.

    // Basic transformations.
    float4 modelPos = input.pos(); // These functions are capable of running expensive calculations; better to cache when possible.

    output.position = mul(input.projectionMatrix(), mul(input.viewMatrix(), modelPos));
    output.uv = input.uv();
    output.color = input.color();

    if (let overlayColor = input.overlayColor()) {
        output.color = lerp(output.color, overlayColor, overlayColor.a);
    }

    return output;
}

// The fragment entrypoint takes the output of the vertex shader as input.
[[shader("fragment")]]
float4 fragmentMain(VertexOutput input) : SV_Target0 { // See the comment in gamma.slang about what targets are.
    // Aperture provides some built-in samplers for object shaders.
    float4 color = albedoTex.Sample(input.uv) * input.color;

    iris_discardIfNeeded(color); // This helper function is given by Aperture to auto-discard if needed in the object shader.

    return color;
}