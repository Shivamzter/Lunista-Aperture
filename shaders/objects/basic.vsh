#version 460 core

out vec2 uv;
out vec2 light;
out vec4 color;
out vec3 normal;
out float ao;

// out vec3 vNormal;

out mat3 tbn_matrix;

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


    tbn_matrix[2] = normalize(mat3(iris_normalMatrix) * data.normal.xyz);
    tbn_matrix[0] = normalize(mat3(iris_normalMatrix) * data.tangent.xyz);
    tbn_matrix[1] = normalize(
    cross(tbn_matrix[0], tbn_matrix[2]) * data.tangent.w
    );

    // normal = mat3(ap.camera.viewInv) * tbn_matrix[2];
    normal = iris_normalMatrix * data.normal;
    normal = mat3(ap.camera.viewInv) * normal;

    // Used for fog later on.
    vertexDistance = length(data.modelPos);

    // Add red entity hit flash and creeper explosion flash
    color.rgb = mix(data.overlayColor.rgb, data.color.rgb, data.overlayColor.a);
}