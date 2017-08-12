# zengine
2D | 3D Game development library

NOTE - Please run examples from root directory for now

Progress - 

![3D Skeletal Animation](https://media.giphy.com/media/l1J3tQly5PfRKtMUo/giphy.gif)
![Lit Model](http://i.imgur.com/YIQutvx.png)
![Model Loading](http://i.imgur.com/fKbrXPi.png)
![FPS Camera](https://media.giphy.com/media/xUA7aSrJzGLbB0x5hS/giphy.gif)
![2D & 3D Primitive Rendering](http://i.imgur.com/m5gWahM.png)


Dependencies:
[Assimp](https://github.com/assimp/assimp)

```nim
import zengine, sdl2, opengl

type
  LightKind = enum
    Point, Directional, Spot
  
  Light = ref object
    id: int
    enabled: bool
    kind: LightKind
    position: Vector3
    target: Vector3
    radius: float
    diffuse: ZColor
    intensity: float
    coneAngle: float

const 
  WIDTH = 960
  HEIGHT = 540
  MAX_LIGHTS = 8

var lights: array[MAX_LIGHTS, Light]
var lightsCount = 0
var lightsLocs: array[MAX_LIGHTS, array[8, int]]

proc createLight(kind: LightKind, position: Vector3, diffuse: ZColor): Light =
  result = nil

  if lightsCount < MAX_LIGHTS:
    result = Light(
      id: lightsCount,
      kind: kind,
      enabled: true,
      position: position,
      target: vectorZero(),
      intensity: 1.0,
      diffuse: diffuse
    )

    lights[lightsCount] = result

    inc(lightsCount)
  else:
    result = lights[lightsCount]

proc setShaderLightsValues(shader: Shader) =
  var tempInt: array[8, GLint]
  var tempFloat: array[8, GLfloat]

  for i in 0..<MAX_LIGHTS:
    if i < lightsCount:
      tempInt[0] = lights[i].enabled.GLint
      setShaderValuei(shader, lightsLocs[i][0].GLint, tempInt, 1)
      
      tempInt[0] = lights[i].kind.GLint
      setShaderValuei(shader, lightsLocs[i][1].GLint, tempInt, 1)

      tempFloat[0] = lights[i].diffuse.r.float/255.0
      tempFloat[1] = lights[i].diffuse.g.float/255.0
      tempFloat[2] = lights[i].diffuse.b.float/255.0
      tempFloat[3] = lights[i].diffuse.a.float/255.0
      setShaderValue(shader, lightsLocs[i][5].GLint, tempFloat, 4)

      tempFloat[0] = lights[i].intensity
      setShaderValue(shader, lightsLocs[i][6].GLint, tempFloat, 1)

      case lights[i].kind:
        of LightKind.Point:
          tempFloat[0] = lights[i].position.x
          tempFloat[1] = lights[i].position.y
          tempFloat[2] = lights[i].position.z
          setShaderValue(shader, lightsLocs[i][2].GLint, tempFloat, 3)

          tempFloat[0] = lights[i].radius
          setShaderValue(shader, lightsLocs[i][4].GLint, tempFloat, 1)
        of LightKind.Directional:
          var direction = vectorSubtract(lights[i].target, lights[i].position)
          vectorNormalize(direction)

          tempFloat[0] = direction.x
          tempFloat[1] = direction.y
          tempFloat[2] = direction.z
          setShaderValue(shader, lightsLocs[i][3].GLint, tempFloat, 3)
        of LightKind.Spot:
          tempFloat[0] = lights[i].position.x
          tempFloat[1] = lights[i].position.y
          tempFloat[2] = lights[i].position.z
          setShaderValue(shader, lightsLocs[i][2].GLint, tempFloat, 3)

          var direction = vectorSubtract(lights[i].target, lights[i].position)
          vectorNormalize(direction)

          tempFloat[0] = direction.x
          tempFloat[1] = direction.y
          tempFloat[2] = direction.z
          setShaderValue(shader, lightsLocs[i][3].GLint, tempFloat, 3)

          tempFloat[0] = lights[i].coneAngle
          setShaderValue(shader, lightsLocs[i][7].GLint, tempFloat, 1)
    else:
      tempInt[0] = 0
      setShaderValuei(shader, lightsLocs[i][0].GLint, tempInt, 1)


proc getShaderLightsLocation(shader: Shader) =
  var locName = "lights[x]."
  var locNameUpdated = newStringOfCap(64)

  for i in 0..<MAX_LIGHTS:
    locName[7] = ('0'.int + i).char

    locNameUpdated = locName
    locNameUpdated &= "enabled"
    lightsLocs[i][0] = getShaderLocation(shader, locNameUpdated)

    locNameUpdated[0] = ' '
    locNameUpdated = locName
    locNameUpdated &= "type"
    lightsLocs[i][1] = getShaderLocation(shader, locNameUpdated)

    locNameUpdated[0] = ' '
    locNameUpdated = locName
    locNameUpdated &= "position"
    lightsLocs[i][2] = getShaderLocation(shader, locNameUpdated)

    locNameUpdated[0] = ' '
    locNameUpdated = locName
    locNameUpdated &= "direction"
    lightsLocs[i][3] = getShaderLocation(shader, locNameUpdated)

    locNameUpdated[0] = ' '
    locNameUpdated = locName
    locNameUpdated &= "radius"
    lightsLocs[i][4] = getShaderLocation(shader, locNameUpdated)

    locNameUpdated[0] = ' '
    locNameUpdated = locName
    locNameUpdated &= "diffuse"
    lightsLocs[i][5] = getShaderLocation(shader, locNameUpdated)

    locNameUpdated[0] = ' '
    locNameUpdated = locName
    locNameUpdated &= "intensity"
    lightsLocs[i][6] = getShaderLocation(shader, locNameUpdated)

    locNameUpdated[0] = ' '
    locNameUpdated = locName
    locNameUpdated &= "coneAngle"
    lightsLocs[i][7] = getShaderLocation(shader, locNameUpdated)

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

let shader = loadShader("examples/data/shaders/glsl330/forward.vs", "examples/data/shaders/glsl330/forward.fs")

var model = loadModel("examples/data/models/mannequin/walking.dae", shader)

getShaderLightsLocation(shader)

var spotLight = createLight(LightKind.Spot, Vector3(x:0.0, y:5.0, z:0.0), ZColor(r:255, g:255, b:255, a:255))
spotLight.target = Vector3(x: 0.0, y: 0.0, z: 0.0)
spotLight.intensity = 2.0
spotlight.diffuse = ZColor(r: 0, g: 0, b: 255, a: 255)
spotLight.coneAngle = 60.0

var dirLight = createLight(LightKind.Directional, Vector3(x:0.0, y: -3.0, z: -3.0), ZColor(r:0, g:0, b:255, a:255))
dirLight.target = Vector3(x: 1.0, y: -2.0, z: -2.0)
dirLight.intensity = 2.0
dirLight.diffuse = ZColor(r: 100, g:255, b:100, a:255)

var pointLight = createLight(LightKind.Point, Vector3(x:0.0, y: 4.0, z: 5.0), ZColor(r:255, g:255, b:255, a:255))
pointLight.intensity = 2.0
pointLight.diffuse = ZColor(r: 100, g:100, b:255, a:255)
pointLight.radius = 3.0

setShaderLightsValues(shader)

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
