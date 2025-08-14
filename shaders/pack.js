// pack.ts
function configureRenderer(renderer) {
  renderer.mergedHandDepth = true;
  renderer.ambientOcclusionLevel = 1;
  renderer.disableShade = false;
  renderer.render.entityShadow = true;
}
function configurePipeline(pipeline) {
  let mainTexture = pipeline.createTexture("mainTexture").width(screenWidth).height(screenHeight).format(Format.RGBA16F).build();
  let lightmapTex = pipeline.createTexture("lightmapTex").width(screenWidth).height(screenHeight).build();
  let normalTex = pipeline.createTexture("normalTex").width(screenWidth).height(screenHeight).build();
  let specularTex = pipeline.createTexture("specularTex").width(screenWidth).height(screenHeight).format(Format.RGBA8).build();
  pipeline.createObjectShader("basic", Usage.BASIC).vertex("objects/basic.vsh").fragment("objects/basic.fsh").target(0, mainTexture).target(1, lightmapTex).target(2, normalTex).target(3, specularTex).compile();
  pipeline.createObjectShader("basic", Usage.SHADOW).vertex("objects/shadow.vsh").fragment("objects/shadow.fsh").compile();
  let postRender = pipeline.forStage(Stage.POST_RENDER);
  postRender.createComposite("lighting").fragment("post/lighting.fsh").target(0, mainTexture).compile();
  postRender.createComposite("tonemap").fragment("post/tonemap.fsh").target(0, mainTexture).compile();
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
