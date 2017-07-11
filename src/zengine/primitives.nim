import glm, zgl, texture

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