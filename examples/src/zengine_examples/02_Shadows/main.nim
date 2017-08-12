import zengine, sdl2, opengl

const 
  WIDTH = 960
  HEIGHT = 540


zengine.init(WIDTH, HEIGHT, "zengine example: 00_Initialization")

var 
  evt = sdl2.defaultEvent
  running = true
  camera = Camera(
    position: Vector3(x: 4, y: 2, z: 4),
    target: Vector3(x: 0, y: 1.8, z: 0),
    up: Vector3(x: 0, y: 1, z: 0),
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
    else:
      discard

  pollInput()

  camera.update(mouseWheelMovement, mouseXRel, mouseYRel)
  
  beginDrawing()
  clearBackground(BLACK)
  
  beginTextureMode(target)
  begin3dMode(camera)
  drawPlane(Vector3(x: 0.0, y: 0.0, z: 0.0), Vector2(x: 32.0, y: 32.0), GREEN)
  drawCube(Vector3(x: -16.0, y: 2.5, z: 0.0), 1.0, 5.0, 32.0, BLUE)
  drawCube(Vector3(x: 16.0, y: 2.5, z: 0.0), 1.0, 5.0, 32.0, RED)
  drawCube(Vector3(x: 0.0, y: 2.5, z: 16.0), 32.0, 5.0, 1.0, WHITE)
  drawModel(model, WHITE)
  end3dMode()
  endTextureMode()

  beginShaderMode(depthShader)
  # setShaderValue(depthShader, getShaderLocation(depthShader, 
  # "near_plane"), [1.0.GLfloat], 1)
  # setShaderValue(depthShader, getShaderLocation(depthShader, "far_plane"), [7.5.GLfloat], 1)
  drawTextureRec(target.depth, Rectangle(x: 0, y: 0, width: target.depth.data.w, height: -target.depth.data.h), Vector2(x: 0, y: 0), RED)
  endShaderMode()

  drawText("Hello zengine!", 5, 5, 30, ZColor(r: 255, g: 255, b: 255, a: 255))

  endDrawing()

  swapBuffers()

zengine.core.shutdown()
