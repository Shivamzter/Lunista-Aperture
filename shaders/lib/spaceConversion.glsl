// vec3 projectAndDivide (in mat4 projectionMatrix, in vec3 position) {
//     vec4 homPos = projectionMatrix * vec4(position, 1.0);
//     return homPos.xyz / homPos.w;
// }

// vec3 getNDCPos (in vec3 screenPos) {
//     return screenPos * 2.0 - 1.0;
// }

// vec3 getViewPos (in vec3 ndcPos) {
//     return projectAndDivide(ap.camera.projectionInv, ndcPos);
// }

// vec3 getFeetPlayerPos (in vec3 viewPos) {
//     return (ap.camera.viewInv * vec4(viewPos, 1.0)).xyz;
// }

// vec3 getEyePlayerPos (in vec3 viewPos) {
//     return mat3(ap.camera.viewInv) * viewPos;
// }

// vec3 eyeCameraPosition = ap.camera.pos + ap.camera.viewInv[3].xyz;

// vec3 eyeToWorldPos (in vec3 eyePos) {
//     return eyePos + eyeCameraPosition;
// }

// vec3 feetToWorldPos (in vec3 feetPos) {
//     return feetPos + ap.camera.pos;
// }