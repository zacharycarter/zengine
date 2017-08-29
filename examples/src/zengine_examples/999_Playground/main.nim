import zengine, sdl2, opengl, glm

type
  LightKind = enum
    Point, Directional, Spot
  
  Light = ref object
    id: int
    enabled: bool
    kind: LightKind
    position: Vec3f
    target: Vec3f
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

proc createLight(kind: LightKind, position: Vec3f, diffuse: ZColor): Light =
  result = nil

  if lightsCount < MAX_LIGHTS:
    result = Light(
      id: lightsCount,
      kind: kind,
      enabled: true,
      position: position,
      target: vec3f(0),
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
          var direction = lights[i].target - lights[i].position
          direction = normalize(direction)

          tempFloat[0] = direction.x
          tempFloat[1] = direction.y
          tempFloat[2] = direction.z
          setShaderValue(shader, lightsLocs[i][3].GLint, tempFloat, 3)
        of LightKind.Spot:
          tempFloat[0] = lights[i].position.x
          tempFloat[1] = lights[i].position.y
          tempFloat[2] = lights[i].position.z
          setShaderValue(shader, lightsLocs[i][2].GLint, tempFloat, 3)

          var direction = lights[i].target - lights[i].position
          direction = normalize(direction)

          tempFloat[0] = direction.x
          tempFloat[1] = direction.y
          tempFloat[2] = direction.z
          setShaderValue(shader, lightsLocs[i][3].GLint, tempFloat, 3)

          tempFloat[0] = lights[i].coneAngle
          setShaderValue(shader, lightsLocs[i][7].GLint, tempFloat, 1)
    else:
      tempInt[0] = 0
      setShaderValuei(shader, lightsLocs[i][0].GLint, tempInt, 1)

proc drawLight(light: Light) =
  case light.kind
  of LightKind.Point:
    drawSphereWires(light.position, 0.3 * light.intensity, 8, 8, if light.enabled: light.diffuse else: GRAY)
  else:
    discard

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
zengine.gui.init()

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

# camera.setMode(CameraMode.Free)
camera.setMode(CameraMode.FirstPerson)

let shader = loadShader("examples/data/shaders/glsl330/animation/forward.vs", "examples/data/shaders/glsl330/animation/forward.fs")

var model = loadModel("examples/data/models/mutant/mutant_idle.dae", shader)

# var model = loadModel("examples/data/models/nanosuit/nanosuit.obj", shader)

# var model = loadModel("examples/data/models/cyborg/cyborg.obj")

getShaderLightsLocation(shader)

var spotLight = createLight(LightKind.Spot, vec3f(0.0, 5.0, 0.0), ZColor(r:255, g:255, b:255, a:255))
spotLight.target = vec3f(0.0, 0.0, 0.0)
spotLight.intensity = 2.0
spotlight.diffuse = ZColor(r: 0, g: 0, b: 255, a: 255)
spotLight.coneAngle = 60.0

# var dirLight = createLight(LightKind.Directional, Vector3(x:0.0, y: -3.0, z: -3.0), ZColor(r:0, g:0, b:255, a:255))
# dirLight.target = Vector3(x: 1.0, y: -2.0, z: -2.0)
# dirLight.intensity = 2.0
# dirLight.diffuse = ZColor(r: 100, g:255, b:100, a:255)

var pointLight = createLight(LightKind.Point, vec3f(0.0, 4.0, 5.0), ZColor(r:255, g:255, b:255, a:255))
pointLight.intensity = 2.0
pointLight.diffuse = ZColor(r: 255, g:100, b:0, a:255)
pointLight.radius = 30.0

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
    of KeyUp:
      # Close on ESC Pressed
      let keyEvent = cast[KeyboardEventPtr](addr evt)
      if keyEvent.keysym.sym == K_ESCAPE:
        running = false
    else:
      discard

  pollInput()

  camera.update(mouseWheelMovement, mouseXRel, mouseYRel)

  beginDrawing()
  clearBackground(ZENGRAY)
  
  begin3dMode(camera)
  drawPlane(vec3f(0.0, 0.0, 0.0), vec2f(32.0, 32.0), GREEN)
  drawCube(vec3f(-16.0, 2.5, 0.0), 1.0, 5.0, 32.0, BLUE)
  drawCube(vec3f(16.0, 2.5, 0.0), 1.0, 5.0, 32.0, RED)
  drawCube(vec3f(0.0, 2.5, 16.0), 32.0, 5.0, 1.0, WHITE)
  
  drawLight(pointLight)
  
  drawModel(model, WHITE)


  end3dMode()

  beginGUI()
  endGUI()

  drawText("Hello zengine!", 5, 5, 30, ZColor(r: 255, g: 255, b: 255, a: 255))

  endDrawing()

  swapBuffers()

zengine.gui.shutdown()
zengine.core.shutdown()
