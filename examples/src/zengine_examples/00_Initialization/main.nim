import zengine, sdl2, opengl

const 
  WIDTH = 960
  HEIGHT = 540

zengine.init(WIDTH, HEIGHT, "zengine example: 00_Initialization")

var 
  evt = sdl2.defaultEvent
  running = true

while running:
  while sdl2.pollEvent(evt):
    case evt.kind
    of QuitEvent:
      running = false
    else:
      discard

  beginDrawing()
  clearBackground(ZENGRAY)

  
  drawText("Hello zengine!", 5, 5, 30, ZColor(r: 255, g: 255, b: 255, a: 255))
  
  begin3dMode()
  drawCube(Vector3(x:0.0, y: 0.0, z: 0.0), 2.0f, 2.0f, 2.0f, RED)
  end3dMode()

  endDrawing()

zengine.shutdown()
