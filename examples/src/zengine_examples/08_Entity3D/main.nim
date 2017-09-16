# Debug drawing for an Entity3D

import zengine, sdl2, opengl, glm


# Constants
const
  ScreenWidth = 960
  ScreenHeight = 540


# Init zengine
zengine.init(ScreenWidth, ScreenHeight, "DebugDraw for Entity3D test")
zengine.gui.init()


# State variables
var
  # Window control
  evt = sdl2.defaultEvent
  running = true

  # Camera control
  camera = Camera(
    position: vec3f(0, 1, 2),
    target: vec3f(0, 1, 0),
    up: vec3f(0, 1, 0),
    fovY: 60
  )
  mouseXRel: int
  mouseYRel: int

  obj = newEntity3D()

# Set the location
obj.position.y += 1
obj.orientation = quatf(vec3f(0, 0, 1), 0)
obj.origin = vec3f(0.2, -0.2, -0.2)


# Use a first person camera
camera.setMode(CameraMode.FirstPerson)

var clock = Timer()
clock.start()

# Main Game loop
while running:
  # Reset
  mouseXRel = 0
  mouseYRel = 0
  clock.tick()

  # Check for new input
  pollInput()

  # Poll for events
  while sdl2.pollEvent(evt):
    case evt.kind:
      # Shutdown if X button clicked
      of QuitEvent:
        running = false

      of KeyDown:
        let keyEvent = cast[KeyboardEventPtr](addr evt)
        if keyEvent.keysym.sym == K_W:
          obj.position.z += 1.0 * clock.deltaTime()
        elif keyEvent.keysym.sym == K_S:
          obj.position.z -= 1.0 * clock.deltaTime()
        elif keyEvent.keysym.sym == K_A:
          obj.position.x -= 1.0 * clock.deltaTime()
        elif keyEvent.keysym.sym == K_D:
          obj.position.x += 1.0 * clock.deltaTime()
        elif keyEvent.keysym.sym == K_R:
          obj.position.y += 1.0 * clock.deltaTime()
        elif keyEvent.keysym.sym == K_F:
          obj.position.y -= 1.0 * clock.deltaTime()

      of KeyUp:
        let keyEvent = cast[KeyboardEventPtr](addr evt)
        # Shutdown if ESC pressed
        if keyEvent.keysym.sym == K_ESCAPE:
          running = false

        # Get some info about the camera state
        if keyEvent.keysym.sym == K_C:
          echo("camera.position=" & $camera.position)
          echo("camera.target=" & $camera.target)
          echo("camera.up=" & $camera.up)

      # Update camera if mouse moved
      of MouseMotion:
        let mouseMoveEvent = cast[MouseMotionEventPtr](addr evt)
        mouseXRel = mouseMoveEvent.xrel
        mouseYRel = mouseMoveEvent.yrel

      else:
        discard

  # Swivel the orientation
  obj.orientation *= quatf(vec3f(1, 0, 0), mouseYRel.float / 100f)
  obj.orientation *= quatf(vec3f(0, 1, 0), mouseXRel.float / 100f)

  # Start drawing
  beginDrawing()
  clearBackground(BLACK)

  begin3dMode(camera)
  drawPlane(vec3f(0, 0, 0), vec2f(32, 32), GRAY)
  debugDraw(obj)
  end3dMode()

  # done with drawing, display the screen
  endDrawing()
  swapBuffers()

# Shutdown
zengine.core.shutdown()
