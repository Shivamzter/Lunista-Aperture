// pack.ts
function configureRenderer(renderer) {
  renderer.sunPathRotation = -30;
  renderer.ambientOcclusionLevel = 1;
  renderer.mergedHandDepth = true;
  renderer.disableShade = false;
  renderer.shadow.resolution = 1592;
  renderer.shadow.far = 192;
  renderer.shadow.distance = 192;
  renderer.shadow.enabled = true;
  renderer.shadow.cascades = 4;
  renderer.shadow.entityCascadeCount = 1;
  renderer.render.entityShadow = true;
}
function configurePipeline(pipeline) {
  let mainTex = pipeline.createTexture("mainTex").width(screenWidth).height(screenHeight).format(Format.RGBA16F).build();
  let lightmapTex = pipeline.createTexture("lightmapTex").width(screenWidth).height(screenHeight).build();
  let normalTex = pipeline.createTexture("normalTex").width(screenWidth).height(screenHeight).build();
  pipeline.createObjectShader("basic", Usage.BASIC).vertex("objects/basic.vsh").fragment("objects/basic.fsh").target(0, mainTex).target(1, lightmapTex).target(2, normalTex).compile();
  pipeline.createObjectShader("basic", Usage.SHADOW).vertex("objects/shadow.vsh").fragment("objects/shadow.fsh").compile();
  let postRender = pipeline.forStage(Stage.POST_RENDER);
  postRender.createComposite("lighting").fragment("post/lighting.fsh").target(0, mainTex).compile();
  postRender.end();
  pipeline.createCombinationPass("post/final.fsh").compile();
}
function beginFrame(state) {
}
export {
  beginFrame,
  configurePipeline,
  configureRenderer
};
//# sourceMappingURL=pack.js.map
