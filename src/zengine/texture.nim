import logging, geom, glm, os, sdl2.image as sdl_image, sdl2, strutils, zgl

proc loadTexture*(filename: string): Texture2D =
  if fileExists(filename):
    warn("Attempting to load non-existent texture file: $1" % filename)
    return
  
  result.data = load(filename.cstring)
  
  if result.data.isNil:
    warn("Texture could not be created")
    return

  result.mipmaps = 1

  result.id = zglLoadTexture(result.data.pixels, result.data.w, result.data.h, result.data.format.format, result.mipmaps)

proc loadTexture*(imagePixels: openArray[ZColor], width, height: int): Texture2D = 

  var pixelData = newSeq[cuchar](width*height*4)

  var
    i, k = 0

  while i < width*height*4:
    pixelData[i] = imagePixels[k].r.cuchar
    pixelData[i + 1] = imagePixels[k].b.cuchar
    pixelData[i + 2] = imagePixels[k].g.cuchar
    pixelData[i + 3] = imagePixels[k].a.cuchar
    inc(k)

    inc(i, 4)

  var rMask, gMask, bMask, aMask: uint32

  when cpuEndian == Endianness.bigEndian:
    rMask = 0xff000000u32
    gMask = 0x00ff0000u32
    bMask = 0x0000ff00u32
    aMask = 0x000000ffu32
  else:
    rMask = 0x000000ffu32
    gMask = 0x0000ff00u32
    bMask = 0x00ff0000u32
    aMask = 0xff000000u32

  result.data = sdl2.createRGBSurfaceFrom(cast[pointer](addr pixelData[0]), width.cint, height.cint, 32, 4 * width.cint, rMask, gMask, bMask, aMask)

  if result.data.isNil:
    warn("Texture could not be created")
    return

  result.mipMaps = 1

  result.id = zglLoadTexture(result.data.pixels, result.data.w, result.data.h, result.data.format.format, result.mipmaps)

proc drawTexture*(tex: Texture2D, sourceRect: var Rectangle, destRect: Rectangle, origin: Vec2f, rotation: float, tint: ZColor) =
  if tex.id != 0:
    if(sourceRect.width < 0): sourceRect.x -= sourceRect.width
    if(sourceRect.height < 0): sourceRect.y -= sourceRect.height

    zglEnableTexture(tex.id)
    
    zglPushMatrix()

    echo repr destRect.x, destRect.y

    zglTranslatef(float destRect.x, float destRect.y, 0)
    #zglRotatef(rotation, 0, 0, 1)
    #zglTranslatef(-origin.x, -origin.y, 0)

    zglBegin(DrawMode.ZGLQuads)

    zglColor4ub(tint.r, tint.g, tint.b, tint.a)
    zglNormal3f(0.0, 0.0, 1.0) # 0.0f, 0.0f, 1.0f

    zglTexCoord2f(float sourceRect.x/tex.data.w, float sourceRect.y/tex.data.h)
    zglVertex2f(0.0, 0.0)

    zglTexCoord2f(float sourceRect.x/tex.data.w, float(sourceRect.y + sourceRect.height)/float tex.data.h)
    zglVertex2f(0.0, destRect.height.float)

    zglTexCoord2f(float(sourceRect.x + sourceRect.width)/float tex.data.w, float(sourceRect.y + sourceRect.height)/float tex.data.h)
    zglVertex2f(destRect.width.float, destRect.height.float)

    zglTexCoord2f(float(sourceRect.x + sourceRect.width)/float tex.data.w, float sourceRect.y/tex.data.h)
    zglVertex2f(destRect.width.float, 0)

    zglEnd()
    zglPopMatrix()

    zglDisableTexture()
  
