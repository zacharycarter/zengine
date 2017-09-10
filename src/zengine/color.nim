import zgl, random

const RED*         = ZColor(r: 255, g: 0,   b: 0,   a: 255)
const ZENGRAY*     = ZColor(r: 48,  g: 48,  b: 48,  a: 255)
const WHITE*       = ZColor(r: 255, g: 255, b: 255, a: 255)
const TRANSPARENT* = ZColor(r: 0,   g: 0,   b: 0,   a: 0  )
const BLACK*       = ZColor(r: 0,   g: 0,   b: 0,   a: 255)
const GREEN*       = ZColor(r: 0,   g: 255, b: 0,   a: 255)
const BLUE*        = ZColor(r: 0,   g: 0,   b: 255, a: 255)
const GRAY*        = ZColor(r: 130, g: 130, b: 130, a: 255)
const LIGHTGRAY*   = ZColor(r: 200, g: 200, b: 200, a: 255)
const DARKGRAY*    = ZColor(r: 80,  g: 80,  b: 80,  a: 255)
const MAROON*      = ZColor(r: 190, g: 33,  b: 55,  a: 255)

proc random*(): ZColor =
  result = ZColor(r: random(256), g: random(256), b: random(256), a: 255)