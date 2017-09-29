# Entity3D is a ZObject child type that is used to represent an object in 3D
# space
import glm
import strfmt
from zobject import ZObject, getNextID
from color import WHITE, RED, GREEN, BLUE
from models import drawSphereWires, drawCube
from zgl import zglPushMatrix, zglPopMatrix, zglTranslatef, zglRotatef


type Entity3D* = ref object of ZObject
  origin*: Vec3f        # Origin point of the object
  position*: Vec3f      # Location of the object
  orientation*: Quatf   # Orientation of the object


# Creates an new Entity3D object.  postion and origin are set to 0.  The orientation
# matrix is set to the identity matrix.
proc newEntity3D*(): Entity3D=
  result = Entity3D(
    id: getNextID(),
    origin: vec3f(0),
    position: vec3f(0),
    orientation: quatf()
  )


method `$`*(self: Entity3D): string=
  var s = "Entity3D [{0}]".fmt(self.id)
  s &= "\n  position={0}".fmt($self.position)
  return s


# Does a debug drawing of the `Entity3D` object's parameters
proc debugDraw*(self: Entity3D; levelOfDetail: int=10)=
  let
    zero = vec3f(0)
    noRot = (0.0, 1.0, 0.0, 0.0)  # Used for no rotation

  # Move to where we need to draw
  zglPushMatrix()
  zglTranslatef(self.position)

  # Draw the position and the origin points
  drawSphereWires(zero, 0.15, levelOfDetail, levelOfDetail, WHITE)
  drawSphereWires(self.origin, 0.1, levelOfDetail, levelOfDetail, RED)

  # X+
  zglPushMatrix()
  zglRotatef(self.orientation)
  zglTranslatef(0.5, 0, 0)
  drawCube(zero, noRot, 0.9, 0.1, 0.1, RED)
  zglPopMatrix()

  # Y+
  zglPushMatrix()
  zglRotatef(self.orientation)
  zglTranslatef(0, 0.5, 0)
  drawCube(zero, noRot, 0.1, 0.9, 0.1, GREEN)
  zglPopMatrix()

  # Z+
  zglPushMatrix()
  zglRotatef(self.orientation)
  zglTranslatef(0, 0, 0.5)
  drawCube(zero, noRot, 0.1, 0.1, 0.9, BLUE)
  zglPopMatrix()

  # Cleanup
  zglPopMatrix()

