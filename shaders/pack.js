// pack.ts
function configureRenderer(renderer) {
  renderer.mergedHandDepth = true;
  renderer.ambientOcclusionLevel = 1;
  renderer.disableShade = false;
  renderer.render.entityShadow = false;
  renderer.shadow.enabled = true;
  renderer.shadow.resolution = 2048;
  renderer.shadow.far = 192;
  renderer.shadow.distance = 192;
  renderer.shadow.cascades = 4;
  renderer.shadow.entityCascadeCount = 1;
  renderer.render.sun = false;
  renderer.sunPathRotation = 30;
}
function configurePipeline(pipeline) {
  let mainTexture = pipeline.createTexture("mainTexture").width(screenWidth).height(screenHeight).format(Format.RGB16).build();
  let lightmapTex = pipeline.createTexture("lightmapTex").width(screenWidth).height(screenHeight).format(Format.RGBA8).build();
  let normalTexture = pipeline.createTexture("normalTexture").width(screenWidth).height(screenHeight).format(Format.RGBA8).build();
  let flatNormalTex = pipeline.createTexture("flatNormalTex").width(screenWidth).height(screenHeight).build();
  let finalTexture = pipeline.createTexture("finalTexture").width(screenWidth).height(screenHeight).format(Format.RGB16).build();
  pipeline.createObjectShader("basic", Usage.BASIC).location("objects/basic").exportBool("disableFog", true).target(0, mainTexture).target(1, lightmapTex).target(2, normalTexture).target(3, flatNormalTex).blendOff(3).compile();
  pipeline.createObjectShader("shadow", Usage.SHADOW).location("objects/shadow").compile();
  pipeline.createObjectShader("sky", Usage.SKY_TEXTURES).location("objects/basic").target(0, mainTexture).exportBool("disableFog", true).compile();
  let postRender = pipeline.forStage(Stage.POST_RENDER);
  postRender.createComposite("clouds").location("post/clouds", "applyClouds").target(0, mainTexture).compile();
  postRender.createComposite("lighting").location("post/lighting", "applyLighting").target(0, finalTexture).compile();
  postRender.end();
  pipeline.createCombinationPass("post/final").compile();
}
function beginFrame(state) {
}
export {
  beginFrame,
  configurePipeline,
  configureRenderer
};
//# sourceMappingURL=pack.js.map
