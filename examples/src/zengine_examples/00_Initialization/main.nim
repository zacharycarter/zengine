import zengine, sdl2, opengl, glm

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
  
  drawTriangle(
    vec3f((960/2) - 50, (540/2), 0), 
    vec3f((960/2), (540/2) - 50, 0), 
    vec3f((960/2) + 50, (540/2), 0), 
    ZColor(r: 255, g: 255, b: 0, a: 255)
  )

  endDrawing()

zengine.shutdown()
