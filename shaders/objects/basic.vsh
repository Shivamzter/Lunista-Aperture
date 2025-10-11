#version 460 core

out vec2 uv;
out vec2 light;
out vec4 color;
out vec3 normal;
out float ao;

out mat3 tbnMatrix;

out float vertexDistance;

/*
Reference for VertexData struct (in emitVertex, you are expected to fill in data.clipPos):
                    {
                        vec4 modelPos;
                        vec4 clipPos;
                        vec2 uv;
                        vec2 light;
                        vec4 color;
                        vec3 normal;
                        vec4 tangent;
                        vec4 overlayColor;
                        vec3 midBlock;
                        uint blockId;
                        uint textureId;
                        vec2 midCoord;
                        float ao;
                    };
*/


// This is the vertex emitter function. Your main job here is to set data.clipPos to the clip position (formerly gl_Position), using the model position (formerly gl_Vertex).
// However, you should avoid sending data from this function; instead using the function below. Doing so is not forbidden, but you may have incorrect results.
void iris_emitVertex(inout VertexData data) {
	data.clipPos = iris_projectionMatrix * iris_modelViewMatrix * data.modelPos;
}

// This takes a finalized VertexData object and sets the output variables.
void iris_sendParameters(VertexData data) {
    // These are the basic variables.
    uv = data.uv;
    light = data.light;
    color = data.color;
    ao = data.ao;

    // vec3 normalizedNormal = normalize(data.normal - 0.5) * 2.0;
    // normal = (iris_normalMatrix * data.normal);
    // normal = mat3(ap.camera.viewInv) * normal; // view to player space
    // normal = normal + ap.camera.viewInv[3].xyz; // feet position in player space


    // Add red entity hit flash and creeper explosion flash
    color.rgb = mix(data.overlayColor.rgb, data.color.rgb, data.overlayColor.a);

    // Add ambient occlusion
    // ao = data.ao;

    // from Jbritains Glint shader
    tbnMatrix[2] = normalize(iris_normalMatrix * data.normal);
    tbnMatrix[0] = normalize(iris_normalMatrix * data.tangent.xyz);
    tbnMatrix[1] = normalize(cross(tbnMatrix[0], tbnMatrix[2]) * sign(data.tangent.w));

    normal = mat3(ap.camera.viewInv) * tbnMatrix[2]; // view to player space
    tbnMatrix = mat3(ap.camera.viewInv) * tbnMatrix; // view to player space

    // Used for fog later on.
    vertexDistance = length(data.modelPos);
}