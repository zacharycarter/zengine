# Minimal example to open up a zengine window

import zengine, sdl2, opengl, glm

type
  Entity3D = object
    position: Vec3f
    origin: Vec3f
    orientation: Quatf

var rot = 0.0


proc newEntity3D(): Entity3D =
  result = Entity3D()

# TODO colors (default)
# Does a debug drawi of the `Entity3D` object's parameters
proc debugDraw(self: Entity3D; levelOfDetail: int=10)=
  # TODO is the origin and position stuff correct?
  drawsphereWires(self.position, 0.15, levelOfDetail, levelOfDetail, WHITE)
  drawsphereWires(self.position + self.origin, 0.1, levelOfDetail, levelOfDetail, RED)

  # drawCube(self.position, (rot, 0.0, 1.0, 0.0), 0.1, 0.1, 1.0, BLUE) # don't call this here as you already pushed a matrix onto the stack

  let 
    x = self.position.x
    y = self.position.y
    z = self.position.z
    width, height, length = 1.0
    color = BLUE

  zglPushMatrix() # push a matrix onto the stack

  # drawCube(self.position, (rot, 0.0, 1.0, 0.0), 0.1, 0.1, 1.0, BLUE) # don't call this here as you already pushed a matrix onto the stack - it does the same thing

  # perform whatever transformations you want here
  zglTranslatef(0.5, 1.5, 0.5)
  zglRotatef(rot, 0, 1, -1)

  zglBegin(DrawMode.ZGLTriangles)
  zglColor4ub(color.r, color.g, color.b, color.a)

  # ZGL Draw calls here
  # Front Face
  zglVertex3f(x-width/2, y-height/2, z+length/2)
  zglVertex3f(x+width/2, y-height/2, z+length/2)
  zglVertex3f(x-width/2, y+height/2, z+length/2)

  zglVertex3f(x+width/2, y+height/2, z+length/2)
  zglVertex3f(x-width/2, y+height/2, z+length/2)
  zglVertex3f(x+width/2, y-height/2, z+length/2)

  # Back Face
  zglVertex3f(x-width/2, y-height/2, z-length/2)
  zglVertex3f(x-width/2, y+height/2, z-length/2)
  zglVertex3f(x+width/2, y-height/2, z-length/2)

  zglVertex3f(x+width/2, y+height/2, z-length/2)
  zglVertex3f(x+width/2, y-height/2, z-length/2)
  zglVertex3f(x-width/2, y+height/2, z-length/2)

  # Top Face
  zglVertex3f(x-width/2, y+height/2, z-length/2)
  zglVertex3f(x-width/2, y+height/2, z+length/2)
  zglVertex3f(x+width/2, y+height/2, z+length/2)

  zglVertex3f(x+width/2, y+height/2, z-length/2)
  zglVertex3f(x-width/2, y+height/2, z-length/2)
  zglVertex3f(x+width/2, y+height/2, z+length/2)

  # Bottom Face
  zglVertex3f(x-width/2, y-height/2, z-length/2)
  zglVertex3f(x+width/2, y-height/2, z+length/2)
  zglVertex3f(x-width/2, y-height/2, z+length/2)

  zglVertex3f(x+width/2, y-height/2, z-length/2)
  zglVertex3f(x+width/2, y-height/2, z+length/2)
  zglVertex3f(x-width/2, y-height/2, z-length/2)

  # Right Face
  zglVertex3f(x+width/2, y-height/2, z-length/2)
  zglVertex3f(x+width/2, y+height/2, z-length/2)
  zglVertex3f(x+width/2, y+height/2, z+length/2)

  zglVertex3f(x+width/2, y-height/2, z+length/2)
  zglVertex3f(x+width/2, y-height/2, z-length/2)
  zglVertex3f(x+width/2, y+height/2, z+length/2)

  # Left Face
  zglVertex3f(x-width/2, y-height/2, z-length/2)
  zglVertex3f(x-width/2, y+height/2, z+length/2)
  zglVertex3f(x-width/2, y+height/2, z-length/2)

  zglVertex3f(x-width/2, y-height/2, z+length/2)
  zglVertex3f(x-width/2, y+height/2, z+length/2)
  zglVertex3f(x-width/2, y-height/2, z-length/2)

  # This call is where the current matrix is applied to all of the above calls
  zglEnd()
  
  # Pop the matrix off the stack since we're done with it
  zglPopMatrix()


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
#obj.orientation *= quatf(vec3f(0, 1, 0), 45)
obj.orientation = quatf(vec3f(0, 0, 1), 45)


# Use a first person camera
camera.setMode(CameraMode.FirstPerson)

let font = loadBitmapFont("examples/data/fonts/bmfont.fnt")

start()

# Main Game loop
while running:
  # Reset
  mouseXRel = 0
  mouseYRel = 0
  tick()

  rot += 45.0 * deltaTime()

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
#  camera.update(0, -mouseXrel, -mouseYRel)


  # Start drawing
  beginDrawing()
  clearBackground(BLACK)

  begin3dMode(camera)
  drawPlane(vec3f(0, 0, 0), vec2f(32, 32), GRAY)
  debugDraw(obj)
  end3dMode()

  drawTextEx(font, "Hello Zengine", vec2f(5, 5), 16.0, 1, WHITE)

  # done with drawing, display the screen
  endDrawing()
  swapBuffers()

# Shutdown
zengine.core.shutdown()