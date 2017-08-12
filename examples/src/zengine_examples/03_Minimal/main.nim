# Minimal example to open up a zengine window

import zengine, sdl2, opengl


# Constants
const
  ScreenWidth = 960
  ScreenHeight = 540


# Init zengine
zengine.init(ScreenWidth, ScreenHeight, "Zengine example: 03_Minimal")
zengine.gui.init()


# State variables
var
  # Window control
  evt = sdl2.defaultEvent
  running = true

  # Camera control
  camera = Camera(
    position: Vector3(x: 0, y: 5, z: 1),
    target: Vector3(x: 0, y: 0, z: 0),
    up: Vector3(x: 0, y: 1, z: 0),
    fovY: 60
  )
  mouseWheelMovement: int
  mouseXRel: int
  mouseYRel: int


# Use a first person camera
camera.setMode(CameraMode.FirstPerson)

# render target
let target = loadRenderTexture(ScreenWidth, ScreenHeight)


# Main Game loop
while running:
  # Reset
  mouseWheelMovement = 0
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

      # Shutdown of ESC pressed
      of KeyUp:
        let keyEvent = cast[KeyboardEventPtr](addr evt)
        if keyEvent.keysym.sym == K_ESCAPE:
          running = false

      # Update camera if mouse moved
      of MouseMotion:
        let mouseMoveEvent = cast[MouseMotionEventPtr](addr evt)
        mouseXRel = mouseMoveEvent.xrel
        mouseYRel = mouseMoveEvent.yrel

      # TODO remove?
      # Update camera scroll
      of MouseWheel:
        let mouseWheelEvent = cast[MouseWheelEventPtr](addr evt)
        mouseWheelMovement = mouseWheelEvent.y

      else:
        discard

  # Update the camera's position
  camera.update(mouseWheelMovement, mouseXrel, mouseYRel)

  # Start drawing
  beginDrawing()
  clearBackground(BLACK)

  beginTextureMode(target)
  begin3dMode(camera)
  drawCube(Vector3(x: 0, y: 0, z: 2), 1, 1, 1, RED)
  drawPlane(Vector3(x: 0, y: 0, z: 0), Vector2(x: 32, y: 32), GRAY)
  end3dMode()
  endTextureMode()

  drawText("Hello zengine!", 8, 8, 16, ZColor(r: 0xFF, g: 0xFF, b: 0xFF, a: 0xFF))

  # done with drawing, display the screen
  endDrawing()
  swapBuffers()

# Shutdown
zengine.core.shutdown()
