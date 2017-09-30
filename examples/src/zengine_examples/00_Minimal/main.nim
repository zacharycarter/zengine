# Minimal example to open up a zengine window

import zengine, opengl, glm, times, sdl2

when defined emscripten:
  import jsbind.emscripten


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
  model: Model
  shader: Shader

var gcRequested* = false
var lastFullCollectTime = 0.0
const fullCollectThreshold = 128 * 1024 * 1024 # 128 Megabytes	
template requestGCFullCollect*() =
  gcRequested = true

proc startApplication() =
  zengine.init(ScreenWidth, ScreenHeight, "Zengine example: 00_Minimal")
  zengine.clock.start()
  camera.setMode(CameraMode.Free)
  when defined emscripten:
    shader = loadShader("examples/data/shaders/glsl100/animation/forward.vs", "examples/data/shaders/glsl100/animation/forward.fs")
  else:
    shader = loadShader("examples/data/shaders/glsl330/animation/forward.vs", "examples/data/shaders/glsl330/animation/forward.fs")
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
  
  zengine.clock.tick()

  beginDrawing()
  clearBackground(ZENGRAY)
  begin3dMode(camera)
  drawPlane(vec3f(0.0, 0.0, 0.0), vec2f(32.0, 32.0), GREEN)
  drawCube(vec3f(-16.0, 2.5, 0.0), (0.0, 0.0, 1.0, 0.0), 1.0, 5.0, 32.0, BLUE)
  drawCube(vec3f(16.0, 2.5, 0.0), (0.0, 0.0, 1.0, 0.0), 1.0, 5.0, 32.0, RED)
  drawCube(vec3f(0.0, 2.5, 16.0), (0.0, 0.0, 1.0, 0.0), 32.0, 5.0, 1.0, WHITE)
  drawModel(model, WHITE, zengine.clock.timeElapsed() * 1000)
  end3dMode()
  endDrawing()
  swapBuffers()
  when defined emscripten:
    runGC()

var initFunc : proc()
when defined emscripten:

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
  when defined emscripten:
    emscripten_set_main_loop(mainLoopPreload, 0, 1)
  else:
    initFunc()
    while mainLoopRunning:
      mainLoopInner()
  
  zengine.core.shutdown()
    
runApplication:
  startApplication()
  


