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