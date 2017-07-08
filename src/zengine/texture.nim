import logging, os, sdl2.image, strutils, zgl

proc loadTexture*(filename: string): Texture2D =
  if not fileExists(filename):
    warn("Attempting to load non-existent texture file: $1" % filename)
    return
  
  result.data = load(filename.cstring)
  
  if result.data.isNil:
    warn("Texture could not be created")
    return

  result.mipmaps = 1

  zglLoadTexture(result.data.pixels, result.data.w, result.data.h, result.data.format.format, result.mipmaps)
