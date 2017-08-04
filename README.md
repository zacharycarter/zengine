# zengine
2D | 3D Game development library

Current status - 
![Skeletal Animation](http://i.imgur.com/Ev4YjcZ.gif)
![Lit Model](http://i.imgur.com/YIQutvx.png)
![Model Loading](http://i.imgur.com/fKbrXPi.png)
![FPS Camera](https://media.giphy.com/media/xUA7aSrJzGLbB0x5hS/giphy.gif)
![2D & 3D Primitive Rendering](http://i.imgur.com/m5gWahM.png)


Dependencies:
[Assimp](https://github.com/assimp/assimp)

```nim
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

#camera.setMode(CameraMode.Free)
camera.setMode(CameraMode.FirstPerson)

var model = loadModel("examples/data/cyborg/cyborg.obj")

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
  clearBackground(ZENGRAY)
  
  begin3dMode(camera)
  drawPlane(Vector3(x: 0.0, y: 0.0, z: 0.0), Vector2(x: 32.0, y: 32.0), GREEN)
  drawCube(Vector3(x: -16.0, y: 2.5, z: 0.0), 1.0, 5.0, 32.0, BLUE)
  drawCube(Vector3(x: 16.0, y: 2.5, z: 0.0), 1.0, 5.0, 32.0, RED)
  drawCube(Vector3(x: 0.0, y: 2.5, z: 16.0), 32.0, 5.0, 1.0, WHITE)
  drawModel(model, WHITE)
  end3dMode()

  drawText("Hello zengine!", 5, 5, 30, ZColor(r: 255, g: 255, b: 255, a: 255))

  endDrawing()

zengine.shutdown()
```
