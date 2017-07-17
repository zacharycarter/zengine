import logging, zgl, zmath, sdl2, os, strutils

proc drawCube*(position: Vector3, width, height, length: float, color: ZColor) =
  let x, y, z = 0.0

  zglPushMatrix()
  
  zglTranslatef(position.x, position.y, position.z)
  #zglRotatef(sdl2.getTicks().float / 10.0, 0, 1, 0)

  zglBegin(DrawMode.ZGLTriangles)
  zglColor4ub(color.r, color.g, color.b, color.a)

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

  zglEnd()

  zglPopMatrix()

proc drawGrid*(slices: int, spacing: float) =
  let halfSlices = slices/2;

  zglBegin(DrawMode.ZGLLines)
  for i in -halfSlices..halfSlices.int:
    if i == 0:
      zglColor3f(1.0, 1.0, 1.0)
      zglColor3f(1.0, 1.0, 1.0)
      zglColor3f(1.0, 1.0, 1.0)
      zglColor3f(1.0, 1.0, 1.0)
    else:
      zglColor3f(0.5, 0.5, 0.5)
      zglColor3f(0.5, 0.5, 0.5)
      zglColor3f(0.5, 0.5, 0.5)
      zglColor3f(0.5, 0.5, 0.5)
    
    zglVertex3f(i.float*spacing, 0.0f, -halfSlices*spacing)
    zglVertex3f(i.float*spacing, 0.0f, halfSlices*spacing)

    zglVertex3f(-halfSlices*spacing, 0.0f, i.float*spacing)
    zglVertex3f(halfSlices*spacing, 0.0f, i.float*spacing)
    
    zglEnd()

proc drawCubeWires*(position: Vector3, width, height, length: float, color: ZColor) =
  let x = 0.0
  let y = 0.0
  let z = 0.0

  zglPushMatrix()

  zglTranslatef(position.x, position.y, position.z)
  # zglRotatef(sdl2.getTicks().float / 10.0, 0, 1, 0)

  zglBegin(DrawMode.ZGLLines)
  zglColor4ub(color.r, color.g, color.b, color.a)

  # Front Face -----------------------------------------------------
  # Bottom Line
  zglVertex3f(x-width/2, y-height/2, z+length/2);  # Bottom Left
  zglVertex3f(x+width/2, y-height/2, z+length/2);  # Bottom Right

  # Left Line
  zglVertex3f(x+width/2, y-height/2, z+length/2);  # Bottom Right
  zglVertex3f(x+width/2, y+height/2, z+length/2);  # Top Right

  # Top Line
  zglVertex3f(x+width/2, y+height/2, z+length/2);  # Top Right
  zglVertex3f(x-width/2, y+height/2, z+length/2);  # Top Left

  # Right Line
  zglVertex3f(x-width/2, y+height/2, z+length/2);  # Top Left
  zglVertex3f(x-width/2, y-height/2, z+length/2);  # Bottom Left

  # Back Face ------------------------------------------------------
  # Bottom Line
  zglVertex3f(x-width/2, y-height/2, z-length/2);  # Bottom Left
  zglVertex3f(x+width/2, y-height/2, z-length/2);  # Bottom Right

  # Left Line
  zglVertex3f(x+width/2, y-height/2, z-length/2);  # Bottom Right
  zglVertex3f(x+width/2, y+height/2, z-length/2);  # Top Right

  # Top Line
  zglVertex3f(x+width/2, y+height/2, z-length/2);  # Top Right
  zglVertex3f(x-width/2, y+height/2, z-length/2);  # Top Left

  # Right Line
  zglVertex3f(x-width/2, y+height/2, z-length/2);  # Top Left
  zglVertex3f(x-width/2, y-height/2, z-length/2);  # Bottom Left

  # Top Face -------------------------------------------------------
  # Left Line
  zglVertex3f(x-width/2, y+height/2, z+length/2);  # Top Left Front
  zglVertex3f(x-width/2, y+height/2, z-length/2);  # Top Left Back

  # Right Line
  zglVertex3f(x+width/2, y+height/2, z+length/2);  # Top Right Front
  zglVertex3f(x+width/2, y+height/2, z-length/2);  # Top Right Back

  # Bottom Face  ---------------------------------------------------
  # Left Line
  zglVertex3f(x-width/2, y-height/2, z+length/2);  # Top Left Front
  zglVertex3f(x-width/2, y-height/2, z-length/2);  # Top Left Back

  # Right Line
  zglVertex3f(x+width/2, y-height/2, z+length/2);  # Top Right Front
  zglVertex3f(x+width/2, y-height/2, z-length/2);  # Top Right Back

  zglEnd()
  zglPopMatrix()

proc drawPlane*(centerPos: Vector3, size: Vector2, color: ZColor) =
  zglPushMatrix()
  zglTranslatef(centerPos.x, centerPos.y, centerPos.z)
  zglScalef(size.x, 1.0f, size.y)

  zglBegin(DrawMode.ZGLTriangles)
  zglColor4ub(color.r, color.g, color.b, color.a)
  zglNormal3f(0.0, 1.0, 0.0)

  zglVertex3f(0.5f, 0.0f, -0.5f)
  zglVertex3f(-0.5f, 0.0f, -0.5f)
  zglVertex3f(-0.5f, 0.0f, 0.5f)

  zglVertex3f(-0.5f, 0.0f, 0.5f)
  zglVertex3f(0.5f, 0.0f, 0.5f)
  zglVertex3f(0.5f, 0.0f, -0.5f)

  zglEnd()
  zglPopMatrix()



proc loadOBJ*(filename: string): Mesh =
  var 
    vertexCount = 0
    normalCount = 0
    texCoordCount = 0
    triangleCount = 0

  if not fileExists(filename):
    warn("[%s] OBJ file does not exist" % fileName)
    return result

  var objFile = open(filename)

  if objFile.isNil:
    warn("[%s] OBJ file could not be opened" % fileName)
    return result

  for line in objFile.lines:
    case line[0]
    of '#', # Comments
      'o', # Object name
      'g', # Group name
      's', # Smooting level
      'm', #mtllib
      'u': #usemtl
        discard 
    of 'v':
      case line[1]
      of 't':
        inc(texCoordCount)
      of 'n':
        inc(normalCount)
      else:
        inc(vertexCount)
    of 'f':
      inc(triangleCount)
    else:
        discard

  var midVertices = newSeq[Vector3](vertexCount)
  var midNormals: seq[Vector3] = nil
  if normalCount > 0:
    midNormals = newSeq[Vector3](normalCount)
  var midTexCoords: seq[Vector2] = nil
  if texCoordCount > 0:
    midTexCoords = newSeq[Vector2](texCoordCount)
  
  var 
    countVertex = 0
    countNormals = 0
    countTexCoords = 0

  for line in objFile.lines:
    case line[0]
    of '#', 'o', 'g', 's', 'm', 'u', 'f':
        discard 
    of 'v':
      case line[1]
      of 't':
        echo "HERE"
        let a = split(line, ' ')
        for i in 1..<a.high:
          echo parseFloat(a[i])
        inc(texCoordCount)
      of 'n':
        inc(normalCount)
      else:
        inc(vertexCount)
    else:
        discard
