# Minimal example to open up a zengine window

import zengine, sdl2, opengl, random, glm


# Constants
const
  ScreenWidth = 960
  ScreenHeight = 540
  MaxBuildings = 100

var buildings = newSeq[Rectangle](MaxBuildings)
var buildingColors = newSeq[ZColor](MaxBuildings)

var spacing = 0
for i in 0..<MaxBuildings:
  buildings[i].width = random(50..201)
  buildings[i].height = random(100..801)
  buildings[i].y = ScreenHeight - 220 - buildings[i].height
  buildings[i].x = -6000 + spacing

  spacing += buildings[i].width

  buildingColors[i] = ZColor(r: random(200..241), g: random(200..241), b: random(200..251), a: 255)


# Init zengine
zengine.init(ScreenWidth, ScreenHeight, "Zengine example: 00_Minimal")

var player = Rectangle(x: 400, y: 280, width: 40, height: 40)

# State variables
var
  # Window control
  evt = sdl2.defaultEvent
  running = true

  # Camera control
  camera = Camera2D(
    target: vec2f(float32 player.x + 20, float32 player.y + 20),
    offset: vec2f(0),
    rotation: 0.0,
    zoom: 1.0
  )
  mouseXRel: int
  mouseYRel: int

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
        # if keyEvent.keysym.sym == K_C:
        #     echo("camera.position=" & $camera.position)
        #     echo("camera.target=" & $camera.target)
        #     echo("camera.up=" & $camera.up)

      # Update camera if mouse moved
      of MouseMotion:
        let mouseMoveEvent = cast[MouseMotionEventPtr](addr evt)
        mouseXRel = mouseMoveEvent.xrel
        mouseYRel = mouseMoveEvent.yrel

      else:
        discard

  # Update the camera's position
  # camera.update(0, -mouseXrel, -mouseYRel)

  if isKeyDown(sdl2.K_d):
    player.x += 2
    camera.offset.x -= 2

  if isKeyDown(sdl2.K_a):
    player.x -= 2
    camera.offset.x += 2

  if isKeyDown(sdl2.K_q):
    camera.rotation -= 1.0
  elif isKeyDown(sdl2.K_e):
    camera.rotation += 1.0

  camera.target = vec2f(float player.x + 20, float player.y + 20)

  clock.tick()

  # Start drawing
  beginDrawing()
  clearBackground(WHITE)

  for x in 0..<60:
    for y in 0..<60:
      drawRectangle(x, y, 1, 1, RED)
      
  for x in 0..<60:
    for y in 0..<60:
      drawText(".", float x, float y, 10, BLUE)

  endDrawing()
  swapBuffers()



# Shutdown
zengine.core.shutdown()
