import aperture;

static const float3x3 LINEAR_REC2020_TO_LINEAR_SRGB = float3x3(
  1.6605, -0.1246, -0.0182,
  -0.5876, 1.1329, -0.1006,
  -0.0728, -0.0083, 1.1187
);

static const float3x3 LINEAR_SRGB_TO_LINEAR_REC2020 = float3x3(
  0.6274, 0.0691, 0.0164,
  0.3293, 0.9195, 0.0880,
  0.0433, 0.0113, 0.8956
);

float3 neutral(float3 color) {
  color = mul(transpose(LINEAR_SRGB_TO_LINEAR_REC2020), color);

  const float startCompression = 0.8 - 0.04;
  const float desaturation = 0.15;

  float x = min(color.r, min(color.g, color.b));
  float offset = x < 0.08 ? x - 6.25 * x * x : 0.04;
  color -= offset;

  float peak = max(color.r, max(color.g, color.b));
  if (peak < startCompression) return color;

  const float d = 1.0 - startCompression;
  float newPeak = 1.0 - d * d / (peak + d - startCompression);
  color *= newPeak / peak;

  float g = 1.0 - 1.0 / (desaturation * (peak - newPeak) + 1.0);
  float3 colorREC2020 = lerp(color, float3(newPeak), g);
  float3 finalColor = mul(transpose(LINEAR_REC2020_TO_LINEAR_SRGB), colorREC2020);
  return finalColor;
}