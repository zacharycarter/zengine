import zgl, zmath, sdl2

proc drawCube*(position: Vector3, width, height, length: float, color: ZColor) =
  let x, y, z = 0.0

  zglPushMatrix()
  
  zglTranslatef(position.x, position.y, position.z)
  zglRotatef(sdl2.getTicks().float / 10.0, 0, 1, 0)

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
  zglRotatef(sdl2.getTicks().float / 10.0, 0, 1, 0)

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