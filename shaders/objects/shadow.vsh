#version 460 core

out vec2 uv;
out vec4 color;

void iris_emitVertex(inout VertexData data) {
	data.clipPos = iris_projectionMatrix * iris_modelViewMatrix * data.modelPos;
}

void iris_sendParameters() {
    uv = data.uv;
    color = data.color;
}