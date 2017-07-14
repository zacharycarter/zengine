# zengine
2D | 3D Game development library

Current status - 

![2D & 3D Primitive Rendering](http://i.imgur.com/pJrFhN1.png)


```nim
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

  
  drawText("Hello zengine!", 10, 10, 20, ZColor(r: 0, g: 255, b: 255, a: 255))
  
  begin3dMode()
  drawCube(vec3f(0, -5, 0), 2.0f, 2.0f, 0.2f, RED)
  end3dMode()

  drawTriangle(
    vec3f((960/2) - 40, (540/2), 0), 
    vec3f((960/2), (540/2) - 40, 0), 
    vec3f((960/2) + 40, (540/2), 0), 
    ZColor(r: 255, g: 255, b: 0, a: 255)
  )

  drawCircleV(
    vec2f((960/2) - 50.0, (540/2)) + vec2f(100.0, 100.0), 
    10.0, 
    ZColor(r: 255, g: 255, b: 255, a: 255)
  )

  

  endDrawing()

zengine.shutdown()

```
