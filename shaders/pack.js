// pack.ts
var cascades = 4;
function configureRenderer(renderer) {
  renderer.sunPathRotation = -30;
  renderer.ambientOcclusionLevel = 1;
  renderer.mergedHandDepth = true;
  renderer.disableShade = false;
  renderer.render.sun = false;
  renderer.shadow.resolution = 1592;
  renderer.shadow.far = 192;
  renderer.shadow.distance = 192;
  renderer.shadow.enabled = true;
  renderer.shadow.cascades = cascades;
  renderer.shadow.entityCascadeCount = 1;
  renderer.render.entityShadow = true;
}
function configurePipeline(pipeline) {
  let mainTexture = pipeline.createTexture("mainTexture").width(screenWidth).height(screenHeight).format(Format.RGBA16F).build();
  let lightmapTex = pipeline.createTexture("lightmapTex").width(screenWidth).height(screenHeight).build();
  let normalTex = pipeline.createTexture("normalTex").width(screenWidth).height(screenHeight).build();
  let specularTex = pipeline.createTexture("specularTex").width(screenWidth).height(screenHeight).format(Format.RGBA16F).build();
  let labNormalTex = pipeline.createTexture("labNormalTex").width(screenWidth).height(screenHeight).format(Format.RGBA8).build();
  let flatNormalTex = pipeline.createTexture("flatNormalTex").width(screenWidth).height(screenHeight).build();
  pipeline.createObjectShader("basic", Usage.BASIC).vertex("objects/basic.vsh").fragment("objects/basic.fsh").target(0, mainTexture).target(1, lightmapTex).target(2, normalTex).target(3, specularTex).target(4, labNormalTex).target(5, flatNormalTex).compile();
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
