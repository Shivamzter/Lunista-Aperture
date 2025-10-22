// pack.ts
function configureRenderer(renderer) {
  renderer.mergedHandDepth = true;
  renderer.ambientOcclusionLevel = 1;
  renderer.disableShade = false;
  renderer.render.entityShadow = true;
}
function configurePipeline(pipeline) {
  let mainTexture = pipeline.createTexture("mainTexture").width(screenWidth).height(screenHeight).format(Format.RGB16).build();
  let normalTexture = pipeline.createTexture("normalTexture").width(screenWidth).height(screenHeight).format(Format.RGBA8).build();
  let finalTexture = pipeline.createTexture("finalTexture").width(screenWidth).height(screenHeight).format(Format.RGBA8).build();
  pipeline.createObjectShader("basic", Usage.BASIC).location("objects/basic").exportBool("disableFog", true).target(0, mainTexture).target(1, normalTexture).compile();
  pipeline.createObjectShader("sky", Usage.SKY_TEXTURES).location("objects/basic").target(0, mainTexture).exportBool("disableFog", true).compile();
  let postRender = pipeline.forStage(Stage.POST_RENDER);
  postRender.createComposite("gamma").location("post/gamma", "applyGamma").target(0, finalTexture).compile();
  postRender.end();
  pipeline.createCombinationPass("post/combination").compile();
}
function beginFrame(state) {
}
export {
  beginFrame,
  configurePipeline,
  configureRenderer
};
//# sourceMappingURL=pack.js.map
