# zengine
2D | 3D Game development library

Current status - 
![FPS Camera](https://media.giphy.com/media/xUA7aSrJzGLbB0x5hS/giphy.gif)
![2D & 3D Primitive Rendering](http://i.imgur.com/m5gWahM.png)


```nim
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
  drawCubeWires(Vector3(x:0.0, y:0.0, z:0.0), 2.0, 2.0, 2.0, BLACK)
  drawGrid(10, 1.0)
  end3dMode()

  endDrawing()

zengine.shutdown()
```
