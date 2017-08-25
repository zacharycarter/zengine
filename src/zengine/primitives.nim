import math, zgl, zmath, texture, geom

proc drawTriangle*(v1, v2, v3: Vector3, color: ZColor) =
  zglEnableTexture(getDefaultTexture().id)

  zglBegin(DrawMode.ZGLQuads)
  zglColor4ub(color.r, color.g, color.b, color.a)
  zglVertex2f(v1.x, v1.y)
  zglVertex2f(v2.x, v2.y)
  zglVertex2f(v2.x, v2.y)
  zglVertex2f(v3.x, v3.y)
  zglEnd()

  zglDisableTexture()

proc drawCircleV*(center: Vector2, radius: float, color: ZColor) =
  zglEnableTexture(getDefaultTexture().id)

  zglBegin(DrawMode.ZGLQuads)
  var i = 0
  while i < 360:
    zglColor4ub(color.r, color.g, color.b, color.a)
    zglVertex2f(center.x, center.y)
    zglVertex2f(center.x + sin(degToRad(i.float))*radius, center.y + cos(degToRad(i.float))*radius)
    zglVertex2f(center.x + sin(degToRad(i.float + 10))*radius, center.y + cos(degToRad(i.float + 10))*radius)
    zglVertex2f(center.x + sin(degToRad(i.float + 20))*radius, center.y + cos(degToRad(i.float + 20))*radius)

    inc(i, 20)

  zglEnd()

  zglDisableTexture()

proc drawRectangleV*(position, size: Vector2, color: ZColor) =
  zglEnableTexture(getDefaultTexture().id)

  zglBegin(DrawMode.ZGLQuads)
  zglColor4ub(color.r, color.g, color.b, color.a)
  zglNormal3f(0.0, 0.0, 1.0)

  zglTexCoord2f(0.0, 0.0)
  zglVertex2f(position.x, position.y)

  zglTexCoord2f(0.0, 1.0)
  zglVertex2f(position.x, position.y + size.y)

  zglTexCoord2f(1.0, 1.0)
  zglVertex2f(position.x + size.x, position.y + size.y)

  zglTexCoord2f(1.0, 0.0)
  zglVertex2f(position.x + size.x, position.y)

  zglEnd()
  zglDisableTexture()

proc drawRectangle*(posX, posY, width, height: int, color: ZColor) =
  let position = Vector2(x: float posX, y: float posY)
  let size = Vector2(x: float width, y: float height)

  drawRectangleV(position, size, color)

proc drawRectangleRec*(rec: Rectangle, color: ZColor) =
  drawRectangle(rec.x, rec.y, rec.width, rec.height, color)