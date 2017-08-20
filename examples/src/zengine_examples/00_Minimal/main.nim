# Minimal example to open up a zengine window

import zengine, sdl2, opengl


# Constants
const
  ScreenWidth = 960
  ScreenHeight = 540


# Init zengine
zengine.init(ScreenWidth, ScreenHeight, "Zengine example: 00_Minimal")
zengine.gui.init()


# State variables
var
  # Window control
  evt = sdl2.defaultEvent
  running = true

  # Camera control
  camera = Camera(
    position: Vector3(x: 4, y: 2, z: 4),
    target: Vector3(x: 0, y: 1.8, z: 0),
    up: Vector3(x: 0, y: 1, z: 0),
    fovY: 60
  )
  mouseXRel: int
  mouseYRel: int


# Use a first person camera
camera.setMode(CameraMode.FirstPerson)


# Main Game loop
while running:
  # Reset
  mouseXRel = 0
  mouseYRel = 0

  # Check for new input
  pollInput()

  # Poll for events
  while sdl2.pollEvent(evt):
    case evt.kind:
      # Shutdown if X button clicked
      of QuitEvent:
        running = false

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

  # Update the camera's position
  camera.update(0, -mouseXrel, -mouseYRel)

  # Start drawing
  beginDrawing()
  clearBackground(BLACK)

  begin3dMode(camera)
  drawCube(Vector3(x: 0, y: 2, z: 0), 1, 1, 1, RED)
  drawPlane(Vector3(x: 0, y: 0, z: 0), Vector2(x: 32, y: 32), GRAY)
  end3dMode()

  drawText("Hello zengine!", 8, 8, 16, ZColor(r: 0xFF, g: 0xFF, b: 0xFF, a: 0xFF))

  # done with drawing, display the screen
  endDrawing()
  swapBuffers()

# Shutdown
zengine.core.shutdown()
