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
  renderer.shadow.entityCascadeCount = 4;
  renderer.sunPathRotation = -40;
}
function configurePipeline(pipeline) {
  const renderConfig = pipeline.getRendererConfig();
  const screenWidth_half = Math.ceil(screenWidth / 2);
  const screenHeight_half = Math.ceil(screenHeight / 2);
  let mainTex = pipeline.createTexture("mainTex").width(screenWidth).height(screenHeight).format(Format.RGBA16F).build();
  let lightmapTex = pipeline.createTexture("lightmapTex").width(screenWidth).height(screenHeight).format(Format.RGBA8).build();
  let encodedNormalTex = pipeline.createTexture("encodedNormalTex").width(screenWidth).height(screenHeight).format(Format.RGBA8).build();
  let labNormalTex = pipeline.createTexture("labNormalTex").width(screenWidth).height(screenHeight).format(Format.RGBA8).build();
  let labSpecularTex = pipeline.createTexture("labSpecularTex").width(screenWidth).height(screenHeight).format(Format.RGBA8).build();
  let bloomTex = pipeline.createTexture("bloomTex").width(screenWidth).height(screenHeight).format(Format.R11F_G11F_B10F).clear(true).mipmap(true).build();
  let finalTex = pipeline.createTexture("finalTex").width(screenWidth).height(screenHeight).format(Format.RGBA16F).build();
  let texShadowColor;
  texShadowColor = pipeline.createArrayTexture("texShadowColor").format(Format.RGBA8).width(renderConfig.shadow.resolution).height(renderConfig.shadow.resolution).clearColor(0, 0, 0, 0).build();
  pipeline.createObjectShader("basic", Usage.BASIC).location("objects/basic").exportBool("disableFog", true).target(0, mainTex).target(1, lightmapTex).target(2, encodedNormalTex).target(3, labNormalTex).target(4, labSpecularTex).blendOff(2).blendOff(3).blendOff(4).compile();
  pipeline.createObjectShader("shadow", Usage.SHADOW).location("objects/shadow").target(0, texShadowColor).compile();
  pipeline.createObjectShader("sky", Usage.SKY_TEXTURES).location("objects/basic").target(0, mainTex).exportBool("disableFog", true).compile();
  let postRender = pipeline.forStage(Stage.POST_RENDER);
  postRender.createComposite("lighting").location("post/lighting", "applyLighting").target(0, finalTex).target(1, bloomTex).compile();
  for (let i = 0; i < 6; i++) {
    postRender.createComposite(`bloomDownsample${i}-${i + 1}`).location("post/bloomDownsample", "bloomDownsample").target(0, bloomTex, i + 1).exportInt("MIP_INDEX", i).compile();
  }
  for (let i = 6; i > 0; i -= 1) {
    postRender.createComposite(`bloomUpsample${i}-${i - 1}`).location("post/bloomUpsample", "bloomUpsample").target(0, bloomTex, i - 1).exportInt("MIP_INDEX", i).compile();
  }
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
