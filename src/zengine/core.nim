import text, logging, sdl2, sdl2.image as sdl_image, sdl2.ttf as sdl_ttf, opengl, zgl, math, glm, timer


var 
  window: sdl2.WindowPtr
  glCtx: sdl2.GlContextPtr
  consoleLogger: ConsoleLogger
  renderOffsetX, renderOffsetY = 0
  previousKeyboardState, currentKeyboardState: ptr array[0 .. SDL_NUM_SCANCODES.int, uint8]
  previousMouseState, currentMouseState: uint8
  mousePositionX, mousePositionY: cint

proc setupViewport() =
  let size = sdl2.getSize(window)
  zglViewport(renderOffsetX div 2, renderOffsetY div 2, size.x - renderOffsetX, size.y - renderOffsetY)

proc init*(width, height: int, mainWindowTitle: string) =
  consoleLogger = newConsoleLogger()
  addHandler(consoleLogger)
  sdl2.init(INIT_TIMER or INIT_VIDEO)
  discard sdl_image.init()

  doAssert 0 == glSetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3)
  doAssert 0 == glSetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3)
  doAssert 0 == glSetAttribute(SDL_GL_CONTEXT_FLAGS        , SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG)
  doAssert 0 == glSetAttribute(SDL_GL_CONTEXT_PROFILE_MASK , SDL_GL_CONTEXT_PROFILE_CORE)

  doAssert 0 == glSetAttribute(SDL_GL_RED_SIZE, 8)
  doAssert 0 == glSetAttribute(SDL_GL_GREEN_SIZE, 8)
  doAssert 0 == glSetAttribute(SDL_GL_BLUE_SIZE, 8)
  doAssert 0 == glSetAttribute(SDL_GL_ALPHA_SIZE, 8)

  doAssert 0 == glSetAttribute(SDL_GL_DEPTH_SIZE, 24)
  doAssert 0 == glSetAttribute(SDL_GL_DOUBLEBUFFER, 1)

  doAssert 0 == glSetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 1)
  doAssert 0 == glSetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4)

  window = createWindow(mainWindowTitle, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width.cint, height.cint, SDL_WINDOW_SHOWN or SDL_WINDOW_OPENGL)

  if window.isNil:
    quit(QUIT_FAILURE)

  glCtx = window.glCreateContext()

  if glCtx.isNil:
    quit(QUIT_FAILURE)

  when not defined(emscripten):
    loadExtensions()
  
  doAssert 0 == glMakeCurrent(window, glCtx)  

  doAssert 0 == sdl2.glSetSwapInterval(1)

  zglInit(width, height)

  setupViewport()

  zglMatrixMode(MatrixMode.ZGLProjection)
  zglLoadIdentity()
  zglOrtho(0.0, GLfloat width - renderOffsetX, GLfloat height - renderOffsetY, 0, 0.1, 1.0)
  zglMatrixMode(MatrixMode.ZGLModelView)
  zglLoadIdentity()

  glClearColor(0.19, 0.19, 0.19, 1.0)

  loadDefaultFont()
  
  currentKeyboardState = sdl2.getKeyboardState()

  timer.init()

proc begin2dMode*(camera: Camera2D) =
  zglDraw()

  zglLoadIdentity()

  let matOrigin = translate(mat4f(), vec3f(-camera.target.x, -camera.target.y, 0))
  let matRotate = rotate(mat4f(), vec3f(0, 0, 1.0), degToRad(camera.rotation))
  let matScale = scale(mat4f(), vec3f(camera.zoom, camera.zoom, 1.0))
  let matTranslation = translate(mat4f(), vec3f(camera.offset.x + camera.target.x, camera.offset.y + camera.target.y, 0.0))

  let matTransform = matTranslation * ((matScale * matRotate) * matOrigin)

  # var matTransform = matrixMultiply(matrixMultiply(matOrigin, matrixMultiply(matScale, matRotation)), matTranslation)

  zglMultMatrix(matrixToFloat(matTransform))

proc end2dMode*() =
  zglDraw()
  zglLoadIdentity()

proc begin3dMode*(camera: Camera) =
  zglDraw()

  zglMatrixMode(MatrixMode.ZGLProjection)
  zglPushMatrix()
  zglLoadIdentity()

  let aspect = 960.0 / 540.0
  let top = 0.01 * tan(camera.fovY*PI/360.0)
  let right = top*aspect

  zglFrustum(-right, right, -top, top, 0.01, 1000.0)

  zglMatrixMode(MatrixMode.ZGLModelView)
  zglLoadIdentity()

  var cameraView = lookAt(camera.position, camera.target, camera.up)
  zglMultMatrix(matrixToFloat(cameraView))

  zglEnableDepthTest()

proc end3dMode*() =
  zglDraw()

  zglMatrixMode(MatrixMode.ZGLProjection)
  zglPopMatrix()

  zglMatrixMode(MatrixMode.ZGLModelView)
  zglLoadIdentity()

  zglDisableDepthTest()

proc beginDrawing*() =
  zglClearScreenBuffers()
  zglLoadIdentity()

proc swapBuffers*() =
  sdl2.glSwapWindow(window)

proc endDrawing*() =
  zglDraw()

proc clearBackground*(color: ZColor) =
  zglClearColor(color.r, color.g, color.b, color.a)  

proc shutdown*() =
  unloadDefaultFont()
  zglShutdown()
  glCtx.glDeleteContext()
  window.destroyWindow()
  sdl2.quit()

proc pollInput*() =
  previousMouseState = currentMouseState
  currentMouseState = sdl2.getMouseState(mousePositionX, mousePositionY)

  previousKeyboardState = currentKeyboardState
  currentKeyboardState = sdl2.getKeyboardState()

proc isKeyDown* (key:cint): bool {.inline.}=
  currentKeyboardState[int(getScancodeFromKey(key))] != 0

proc getMousePosition*(): Vec2f =
  result = vec2f(mousePositionX.float, mousePositionY.float)

proc disableCursor*() =
  discard sdl2.setRelativeMouseMode(sdl2.True32)

proc beginTextureMode*(target: RenderTexture2D) =
  zglDraw()

  zglEnableRenderTexture(target.id)

  zglClearScreenBuffers()

  zglViewport(0, 0, target.texture.data.w, target.texture.data.h)

  zglMatrixMode(MatrixMode.ZGLProjection)
  zglLoadIdentity()

  zglOrtho(0, float target.texture.data.w, float target.texture.data.h, 0, 0.0, 1.0)

  zglMatrixMode(MatrixMode.ZGLModelView)
  zglLoadIdentity()

proc endTextureMode*() =
  zglDraw()

  zglDisableRenderTexture()

  setupViewport()

  zglMatrixMode(MatrixMode.ZGLProjection)
  zglLoadIdentity()

  zglOrtho(0, 960, 540, 0, 0.0, 1.0)

  zglMatrixMode(MatrixMode.ZGLModelView)
  zglLoadIdentity()
