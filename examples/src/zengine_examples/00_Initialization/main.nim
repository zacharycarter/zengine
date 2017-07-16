import zengine, sdl2, opengl

const 
  WIDTH = 960
  HEIGHT = 540

zengine.init(WIDTH, HEIGHT, "zengine example: 00_Initialization")

var 
  evt = sdl2.defaultEvent
  running = true
  camera = Camera(
    position: Vector3(x: 10, y: 10, z: 10),
    target: Vector3(x: 0, y: 0, z: 0),
    up: Vector3(x: 0, y: 1, z: 0),
    fovY: 45
  )
  mouseWheelMovement = 0

camera.setMode(CameraMode.Free)

while running:
  mouseWheelMovement = 0
  while sdl2.pollEvent(evt):
    case evt.kind
    of QuitEvent:
      running = false
    of MouseWheel:
      var mouseWheelEvent = cast[MouseWheelEventPtr](addr evt)
      mouseWheelMovement = mouseWheelEvent.y
    else:
      discard

  camera.update(mouseWheelMovement)
  beginDrawing()
  clearBackground(ZENGRAY)

  
  drawText("Hello zengine!", 5, 5, 30, ZColor(r: 255, g: 255, b: 255, a: 255))
  
  begin3dMode(camera)
  drawCube(Vector3(x:0.0, y: 0.0, z: 0.0), 2.0f, 2.0f, 2.0f, RED)
  drawCubeWires(Vector3(x:0.0, y:0.0, z:0.0), 2.0, 2.0, 2.0, BLACK)
  drawGrid(10, 1.0)
  end3dMode()

  endDrawing()

zengine.shutdown()
