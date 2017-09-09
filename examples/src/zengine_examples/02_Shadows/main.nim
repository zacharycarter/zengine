import zengine, sdl2, opengl, glm

const 
  WIDTH = 960
  HEIGHT = 540


zengine.init(WIDTH, HEIGHT, "zengine example: 00_Initialization")

var 
  evt = sdl2.defaultEvent
  running = true
  camera = Camera(
    position: vec3f(4, 2, 4),
    target: vec3f(0, 1.8, 0),
    up: vec3f(0, 1, 0),
    fovY: 60
  )
  mouseWheelMovement = 0
  mouseXRel = 0
  mouseYRel = 0

camera.setMode(CameraMode.Free)
#camera.setMode(CameraMode.FirstPerson)

let depthShader = loadShader("examples/data/shaders/glsl330/shadows/debug_quad.vs", "examples/data/shaders/glsl330/shadows/debug_quad.fs")

setShaderValuei(depthShader, getShaderLocation(depthShader, "depthMap"), [0.GLint], 1)

var model = loadModel("examples/data/models/cyborg/cyborg.obj", getDefaultShader())

let target = loadRenderTexture(WIDTH, HEIGHT)

var clock = Timer()
clock.start()

while running:
  mouseWheelMovement = 0
  mouseXRel = 0
  mouseYRel = 0
  while sdl2.pollEvent(evt):
    case evt.kind
    of QuitEvent:
      running = false
    of MouseMotion:
      var mouseMoveEvent = cast[MouseMotionEventPtr](addr evt)
      mouseXRel = mouseMoveEvent.xrel
      mouseYRel = mouseMoveEvent.yrel
    of MouseWheel:
      var mouseWheelEvent = cast[MouseWheelEventPtr](addr evt)
      mouseWheelMovement = mouseWheelEvent.y
    of KeyUp:
      # Close on ESC Pressed
      let keyEvent = cast[KeyboardEventPtr](addr evt)
      if keyEvent.keysym.sym == K_ESCAPE:
        running = false
    else:
      discard

  pollInput()

  camera.update(mouseWheelMovement, mouseXRel, mouseYRel)
  
  clock.tick()

  beginDrawing()
  clearBackground(BLACK)
  
  beginTextureMode(target)
  begin3dMode(camera)
  drawPlane(vec3f(0.0, 0.0, 0.0), vec2f(32.0, 32.0), GREEN)
  drawCube(vec3f(-16.0, 2.5, 0.0), 1.0, 5.0, 32.0, BLUE)
  drawCube(vec3f(16.0, 2.5, 0.0), 1.0, 5.0, 32.0, RED)
  drawCube(vec3f(0.0, 2.5, 16.0), 32.0, 5.0, 1.0, WHITE)
  drawModel(model, WHITE, clock.timeElapsed())
  end3dMode()
  endTextureMode()

  beginShaderMode(depthShader)
  # setShaderValue(depthShader, getShaderLocation(depthShader, 
  # "near_plane"), [1.0.GLfloat], 1)
  # setShaderValue(depthShader, getShaderLocation(depthShader, "far_plane"), [7.5.GLfloat], 1)
  drawTextureRec(target.depth, Rectangle(x: 0, y: 0, width: target.depth.data.w, height: -target.depth.data.h), vec2f(0), RED)
  endShaderMode()

  drawText("Hello zengine!", 5, 5, 30, ZColor(r: 255, g: 255, b: 255, a: 255))

  endDrawing()

  swapBuffers()

zengine.core.shutdown()
