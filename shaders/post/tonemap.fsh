#version 460 core

uniform sampler2D mainTexture;

in vec2 uv;

layout(location = 0) out vec4 outColor;

vec3 uncharted2Tonemap(vec3 x) {
  float A = 0.15;
  float B = 0.50;
  float C = 0.10;
  float D = 0.20;
  float E = 0.02;
  float F = 0.30;
  float W = 11.2;
  return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
}

vec3 uncharted2(vec3 color) {
  const float W = 11.2;
  float exposureBias = 2.0;
  vec3 curr = uncharted2Tonemap(exposureBias * color);
  vec3 whiteScale = 1.0 / uncharted2Tonemap(vec3(W));
  return curr * whiteScale;
}

void main() {
    vec3 color = texture(mainTexture, uv).rgb;

    //Tonemapping
    color = uncharted2(color);

    //HDR -> SDR
    color = pow(color, vec3(1.0 / 2.2));

    outColor = vec4(color, 1.0);
}
