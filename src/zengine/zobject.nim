# ZObject is a base type for many objects in Zengine

# Next available ID
var nextID:uint = 1
proc getNextID*(): uint=
  result = nextID
  nextID.inc()


type ZObject* = ref object of RootObj
  id*: uint   # Unique Id for the ZObject, positive integer


# Instatiate a new ZObject
proc newZObject*(): ZObject=
  result = ZObject(id: getNextID())


# Get the ID of the ZObject.  It will always be a positive integer
proc id*(self: ZObject): uint=
  return self.id


method `$`*(self: ZObject): string=
  return "ZObject [" & $self.id & "]"

