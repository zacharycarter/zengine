import glm, math, zgl, texture

proc drawTriangle*(v1, v2, v3: Vec3f, color: ZColor) =
  zglEnableTexture(getDefaultTexture().id)

  zglBegin(DrawMode.ZGLQuads)
  zglColor4ub(color.r, color.g, color.b, color.a)
  zglVertex2f(v1.x, v1.y)
  zglVertex2f(v2.x, v2.y)
  zglVertex2f(v2.x, v2.y)
  zglVertex2f(v3.x, v3.y)
  zglEnd()

  zglDisableTexture()

proc drawCircleV*(center: Vec2f, radius: float, color: ZColor) =
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