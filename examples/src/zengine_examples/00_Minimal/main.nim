# Minimal example to open up a zengine window

import zengine, opengl, glm, jsbind.emscripten, times, sdl2


# Constants
const
  ScreenWidth = 960
  ScreenHeight = 540

var
  camera = Camera(
    position: vec3f(4, 2, 4),
    target: vec3f(0, 1.8, 0),
    up: vec3f(0, 1, 0),
    fovY: 60
  )
  mouseWheelMovement = 0
  mouseXRel = 0
  mouseYRel = 0
  evt: sdl2.Event
  mainLoopRunning = true
  clock = Timer()
  model: Model
  shader: Shader

var gcRequested* = false
var lastFullCollectTime = 0.0
const fullCollectThreshold = 128 * 1024 * 1024 # 128 Megabytes	
template requestGCFullCollect*() =
  gcRequested = true

proc startApplication() =
  zengine.init(ScreenWidth, ScreenHeight, "Zengine example: 00_Minimal")
  clock.start()
  camera.setMode(CameraMode.Free)
  shader = loadShader("examples/data/shaders/glsl100/animation/forward.vs", "examples/data/shaders/glsl100/animation/forward.fs")
  model = loadModel("examples/data/models/mutant/mutant_idle.dae", shader)
  
proc runGC() =
  let t = epochTime()
  if gcRequested or (t > lastFullCollectTime + 10 and getOccupiedMem() > fullCollectThreshold):
      GC_enable()
      when defined(useRealtimeGC):
          GC_setMaxPause(0)
      GC_fullCollect()
      GC_disable()
      lastFullCollectTime = t
      gcRequested = false
  else:
      when defined(useRealtimeGC):
          GC_step(1000, true)
      else:
          {.hint: "It is recommended to compile your project with -d:useRealtimeGC for emscripten".}

proc mainLoopInner() =
  mouseWheelMovement = 0
  mouseXRel = 0
  mouseYRel = 0
  while sdl2.pollEvent(evt):
    case evt.kind
    of QuitEvent:
      mainLoopRunning = false
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
        mainLoopRunning = false
    else:
      discard

  pollInput()

  camera.update(mouseWheelMovement, mouseXRel, mouseYRel)
  
  clock.tick()

  beginDrawing()
  clearBackground(ZENGRAY)
  begin3dMode(camera)
  drawPlane(vec3f(0.0, 0.0, 0.0), vec2f(32.0, 32.0), GREEN)
  drawCube(vec3f(-16.0, 2.5, 0.0), (0.0, 0.0, 1.0, 0.0), 1.0, 5.0, 32.0, BLUE)
  drawCube(vec3f(16.0, 2.5, 0.0), (0.0, 0.0, 1.0, 0.0), 1.0, 5.0, 32.0, RED)
  drawCube(vec3f(0.0, 2.5, 16.0), (0.0, 0.0, 1.0, 0.0), 32.0, 5.0, 1.0, WHITE)
  drawModel(model, WHITE, clock.timeElapsed() * 1000)
  end3dMode()
  endDrawing()
  swapBuffers()
  runGC()

var initFunc : proc()

var initDone = false
proc mainLoopPreload() {.cdecl.} =
    if initDone:
        if mainLoopRunning:
          mainLoopInner()
    else:
        let r = EM_ASM_INT """
        return (document.readyState === 'complete') ? 1 : 0;
        """
        if r == 1:
            GC_disable() # GC Should only be called close to the bottom of the stack on emscripten.
            initFunc()
            initFunc = nil
            initDone = true

template runApplication*(initCode: typed): stmt =
  initFunc = proc() =
      initCode
  emscripten_set_main_loop(mainLoopPreload, 0, 1)

runApplication:
  startApplication()
  

# # State variables
# var
#   # Window control
#   evt = sdl2.defaultEvent
#   running = true

#   # Camera control
#   camera = Camera(
#     position: vec3f(4, 2, 4),
#     target: vec3f(0, 1.8, 0),
#     up: vec3f(0, 1, 0),
#     fovY: 60
#   )
#   mouseXRel: int
#   mouseYRel: int


# # Use a first person camera
# camera.setMode(CameraMode.FirstPerson)

# var clock = Timer()
# clock.start()

# # Main Game loop
# while running:
#   # Reset
#   mouseXRel = 0
#   mouseYRel = 0

#   # Check for new input
#   pollInput()

#   # Poll for events
#   while sdl2.pollEvent(evt):
#     case evt.kind:
#       # Shutdown if X button clicked
#       of QuitEvent:
#         running = false

#       of KeyUp:
#         let keyEvent = cast[KeyboardEventPtr](addr evt)
#         # Shutdown if ESC pressed
#         if keyEvent.keysym.sym == K_ESCAPE:
#           running = false

#         # Get some info about the camera state
#         if keyEvent.keysym.sym == K_C:
#             echo("camera.position=" & $camera.position)
#             echo("camera.target=" & $camera.target)
#             echo("camera.up=" & $camera.up)

#       # Update camera if mouse moved
#       of MouseMotion:
#         let mouseMoveEvent = cast[MouseMotionEventPtr](addr evt)
#         mouseXRel = mouseMoveEvent.xrel
#         mouseYRel = mouseMoveEvent.yrel

#       else:
#         discard

#   # Update the camera's position
#   camera.update(0, -mouseXrel, -mouseYRel)

#   clock.tick()

#   # Start drawing
#   beginDrawing()
#   clearBackground(BLACK)

#   begin3dMode(camera)
#   drawCube(vec3f(0, 2, 0), (0.0, 0.0, 1.0, 0.0), 1, 1, 1, RED)
#   drawPlane(vec3f(0, 0, 0), vec2f(32, 32), GRAY)
#   end3dMode()

#   drawText("Hello zengine!", 8, 8, 16, ZColor(r: 0xFF, g: 0xFF, b: 0xFF, a: 0xFF))

#   # done with drawing, display the screen
#   endDrawing()
#   swapBuffers()

# # Shutdown
# zengine.core.shutdown()
