# Minimal example to open up a zengine window

import zengine, sdl2, opengl, glm


# Constants
const
  ScreenWidth = 960
  ScreenHeight = 540


# Init zengine
zengine.init(ScreenWidth, ScreenHeight, "Zengine example: 00_Minimal")
zengine.gui.init()

let customFont = loadFont("examples/data/fonts/testfnt.fnt")
let customFont2 = loadFont("examples/data/fonts/Zodiac-Square-12x12.fnt")

# State variables
var
  # Window control
  evt = sdl2.defaultEvent
  running = true

  # Camera control
  camera = Camera(
    position: vec3f(4, 2, 4),
    target: vec3f(0, 1.8, 0),
    up: vec3f(0, 1, 0),
    fovY: 60
  )
  mouseXRel: int
  mouseYRel: int


# Use a first person camera
camera.setMode(CameraMode.FirstPerson)

var clock = Timer()
clock.start()

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

  clock.tick()

  # Start drawing
  beginDrawing()
  clearBackground(BLACK)

  begin3dMode(camera)
  drawCube(vec3f(0, 2, 0), 1, 1, 1, RED)
  drawPlane(vec3f(0, 0, 0), vec2f(32, 32), GRAY)
  end3dMode()

  drawTextEx(customFont, "Hello Zengine!", vec2f(5, 5), 24, 0, WHITE)
  drawTextEx(customFont2, "Hello Custom Fonts!", vec2f(5, 30), 12, 0, WHITE)

  # done with drawing, display the screen
  endDrawing()
  swapBuffers()

# Shutdown
zengine.core.shutdown()
