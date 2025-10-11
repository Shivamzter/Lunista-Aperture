// pack.ts
var cascades = 4;
function configureRenderer(renderer) {
  renderer.sunPathRotation = -30;
  renderer.ambientOcclusionLevel = 1;
  renderer.mergedHandDepth = true;
  renderer.disableShade = false;
  renderer.shadow.resolution = 1592;
  renderer.shadow.far = 192;
  renderer.shadow.distance = 192;
  renderer.shadow.enabled = true;
  renderer.shadow.cascades = cascades;
  renderer.shadow.entityCascadeCount = 1;
  renderer.render.entityShadow = true;
}
function configurePipeline(pipeline) {
  const mainTex = pipeline.createTexture("mainTex").format(Format.RGBA16F).width(screenWidth).height(screenHeight).clear(true).build();
  let lightmapTex = pipeline.createTexture("lightmapTex").width(screenWidth).height(screenHeight).build();
  let normalTex = pipeline.createTexture("normalTex").width(screenWidth).height(screenHeight).build();
  let specularTex = pipeline.createTexture("specularTex").width(screenWidth).height(screenHeight).format(Format.RGBA16F).build();
  let flatNormalTex = pipeline.createTexture("flatNormalTex").width(screenWidth).height(screenHeight).build();
  const bloomTex = pipeline.createTexture("bloomTex").format(Format.R11F_G11F_B10F).width(screenWidth).height(screenHeight).clear(true).mipmap(true).build();
  pipeline.createObjectShader("basic", Usage.BASIC).vertex("objects/basic.vsh").fragment("objects/basic.fsh").target(0, mainTex).target(1, lightmapTex).target(2, normalTex).target(3, specularTex).target(4, flatNormalTex).compile();
  pipeline.createObjectShader("basic", Usage.SHADOW).vertex("objects/shadow.vsh").fragment("objects/shadow.fsh").compile();
  let postRender = pipeline.forStage(Stage.POST_RENDER);
  postRender.createComposite("lighting").vertex("post/fullscreen_Pass.vsh").fragment("post/lighting.fsh").target(0, mainTex).target(1, bloomTex).compile();
  for (let i = 0; i < 6; i++) {
    postRender.createComposite(`bloomDownsample${i}-${i + 1}`).vertex("post/fullscreen_Pass.vsh").fragment("post/bloom_Downsample.fsh").target(0, bloomTex, i + 1).define("BLOOM_INDEX", i.toString()).compile();
  }
  for (let i = 6; i > 0; i -= 1) {
    postRender.createComposite(`bloomUpsample${i}-${i - 1}`).vertex("post/fullscreen_Pass.vsh").fragment("post/bloom_Upsample.fsh").target(0, bloomTex, i - 1).define("BLOOM_INDEX", i.toString()).compile();
  }
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
