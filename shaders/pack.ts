// This configures basic settings for the world.
export function configureRenderer(renderer: RendererConfig): void {
  // These settings mimic Vanilla Minecraft's rendering settings.
  // mergedHandDepth is used to avoid needing to merge the hand depth; however, you will likely want this off for more complex shaders.
  renderer.mergedHandDepth = true;
  renderer.ambientOcclusionLevel = 1.0;
  renderer.disableShade = false;
  renderer.render.entityShadow = false;

  renderer.shadow.enabled = true;
  renderer.shadow.resolution = 2048;
  renderer.shadow.far = 192;
  renderer.shadow.distance = 192;
  renderer.shadow.cascades = 4;
  renderer.shadow.entityCascadeCount = 1;

  renderer.sunPathRotation = -35.0;
}

// This is where the shaders, buffers, and textures are configured.
export function configurePipeline(pipeline: PipelineConfig): void {
  // This creates the main texture; one of the two textures used in this template. It can be accessed via "Sampler2D mainTexture;" in shaders.
  // However, you are not limited by how many textures can be created.
  // The most important limitation is you should never read and write to the same texture in the same shader. (Using images avoids this limitation, but this is not covered here.)

  let mainTexture = pipeline
    .createTexture("mainTexture")
    .width(screenWidth)
    .height(screenHeight)
    .format(Format.RGB16)
    .build();

  let normalTexture = pipeline
    .createTexture("normalTexture")
    .width(screenWidth)
    .height(screenHeight)
    .format(Format.RGBA8)
    .build();

  let flatNormalTex = pipeline
    .createTexture("flatNormalTex")
    .width(screenWidth)
    .height(screenHeight)
    .format(Format.RGBA8)
    .build();

  let finalTexture = pipeline
    .createTexture("finalTexture")
    .width(screenWidth)
    .height(screenHeight)
    .format(Format.RGBA8)
    .build();

  // First, we need to define object shaders, and their source "modules".
  // The default entrypoint names are vertexMain and fragmentMain; however, this can be changed with the `vertex` and `fragment` functions.

  // A basic object shader. This shader is marked as BASIC, which means all objects will fall back to it.
  pipeline
    .createObjectShader("basic", Usage.BASIC)
    .location("objects/basic")
    .exportBool("disableFog", true)
    .target(0, mainTexture)
    .target(1, normalTexture)
    .target(2, flatNormalTex)
    .compile();

  pipeline
    .createObjectShader("shadow", Usage.SHADOW)
    .location("objects/shadow")
    .compile();

  // The following is a copy of the basic shader, but with disableFog enabled to avoid fog being run on the sky.
  pipeline
    .createObjectShader("sky", Usage.SKY_TEXTURES)
    .location("objects/basic")
    .target(0, mainTexture)
    .exportBool("disableFog", true)
    .compile();

  // The following is a command list; the main way to do post processing and compute.
  // For this, we will be creating a POST_RENDER command list, which will run after everything.
  let postRender = pipeline.forStage(Stage.POST_RENDER);

  // A basic composite. Requires both a module and entrypoint.
  postRender
    .createComposite("lighting")
    .location("post/lighting", "applyLighting")
    .target(0, finalTexture)
    .compile();

  // If you have multiple passes relying on each other, you will require memory barriers.

  // An example of a memory barrier that will make any SSBO's and images written to in the previous pass available to the next pass.
  // postRender.barrier(SSBO_BIT | IMAGE_BIT);

  // You must end your command list after you are done adding commands to it.
  postRender.end();

  // The combination pass. For more information, see the file.
  pipeline.createCombinationPass("post/final").compile();
}

export function beginFrame(state: WorldState): void {
  // This runs every frame. However, it won't be used in this template.
}
