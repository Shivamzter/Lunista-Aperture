// pack.ts
function configureRenderer(renderer) {
  renderer.mergedHandDepth = true;
  renderer.ambientOcclusionLevel = 1;
  renderer.disableShade = false;
  renderer.render.entityShadow = true;
}
function configurePipeline(pipeline) {
  let mainTexture = pipeline.createTexture("mainTexture").width(screenWidth).height(screenHeight).format(Format.RGBA8).build();
  let postRender = pipeline.forStage(Stage.POST_RENDER);
  postRender.createComposite("composite").fragment("post/composite.fsh").target(0, mainTexture).compile();
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
