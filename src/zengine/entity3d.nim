# Entity3D is a ZObject child type that is used to represent an object in 3D
# space
from zobject import ZObject, getNextID
import glm
import strfmt


type Entity3D* = ref object of ZObject
  origin*: Vec3f        # Origin point of the object
  pos*: Vec3f           # Location of the object
  orientation*: Mat3f   # Orientation of the object


# Creates an new Entity3D object.  postion and origin are set to 0.  The orientation
# matrix is set to the identity matrix.
proc newEntity3D*(): Entity3D=
  result = Entity3D(
    id: getNextID(),
    origin: vec3f(0),
    pos: vec3f(0),
    orientation: mat3f(1)
  )


method `$`*(self: Entity3D): string=
  var s = "Entity3D [{0}]".fmt(self.id)
  s &= "\n  pos={0}".fmt($self.pos)
  return s

