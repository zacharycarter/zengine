import text, logging, sdl2, sdl2.image as sdl_image, sdl2.ttf as sdl_ttf, opengl, zgl

var 
  window: sdl2.WindowPtr
  glCtx: sdl2.GlContextPtr
  consoleLogger: ConsoleLogger
  currentTime, previousTime, updateTime: uint32
  renderOffsetX, renderOffsetY = 0

proc setupViewport() =
  let size = sdl2.getSize(window)
  zglViewport(renderOffsetX div 2, renderOffsetY div 2, size.x - renderOffsetX, size.y - renderOffsetY)

proc init*(width, height: int, mainWindowTitle: string) =
  consoleLogger = newConsoleLogger()
  addHandler(consoleLogger)
  sdl2.init(INIT_TIMER or INIT_VIDEO)
  discard sdl_image.init()
  sdl_ttf.ttfInit()

  doAssert 0 == glSetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3)
  doAssert 0 == glSetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2)
  doAssert 0 == glSetAttribute(SDL_GL_CONTEXT_FLAGS        , SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG)
  doAssert 0 == glSetAttribute(SDL_GL_CONTEXT_PROFILE_MASK , SDL_GL_CONTEXT_PROFILE_CORE)

  window = createWindow(mainWindowTitle, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width.cint, height.cint, SDL_WINDOW_SHOWN or SDL_WINDOW_OPENGL)

  if window.isNil:
    quit(QUIT_FAILURE)

  glCtx = window.glCreateContext()

  if glCtx.isNil:
    quit(QUIT_FAILURE)

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

# Get current time in seconds since SDL2 timer was initialized
proc getTime(): uint32 =
  result = sdl2.getTicks() * 1000

proc beginDrawing*() =
  currentTime = getTime()
  updateTime = currentTime - previousTIme
  previousTime = currentTime

  zglClearScreenBuffers()
  zglLoadIdentity()

proc swapBuffers() =
  sdl2.glSwapWindow(window)

proc endDrawing*() =
  zglDraw()

  swapBuffers()

proc clearBackground*(color: ZColor) =
  zglClearColor(color.r, color.g, color.b, color.a)  

proc shutdown*() =
  unloadDefaultFont()
  zglShutdown()
  glCtx.glDeleteContext()
  window.destroyWindow()
  sdl2.quit()