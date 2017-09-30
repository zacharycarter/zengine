import zgl, color, geom, sdl2, sdl2.image as sdl_image, opengl, texture, strutils, glm, strscans, os

when not defined emscripten:
  import logging

when defined emscripten:
  proc info(msg: cstring) =
    discard
  proc debug(msg: cstring) =
    discard
  proc warn(msg: cstring) =
    discard
  proc error(msg: cstring) =
    discard

type
  CharInfo = object
    value: int
    rec: Rectangle
    offsetX, offsetY: int
    advanceX: int

  Font = object
    charCount: int
    texture: Texture2D
    chars: seq[CharInfo]
    baseSize: int
  
var defaultFont: Font

proc loadDefaultFont*() =
  template bitCheck(a, b: untyped): bool = (a and (1 shl b)) != 0

  defaultFont.charCount = 224

  var defaultFontData: array[512, int64] = [
    int64 0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00200020, 0x0001B000,
          0x00000000, 0x00000000, 0x8EF92520,
          0x00020A00, 0x7DBE8000, 0x1F7DF45F,
          0x4A2BF2A0, 0x0852091E, 0x41224000,
          0x10041450, 0x2E292020, 0x08220812,
          0x41222000, 0x10041450, 0x10F92020,
          0x3EFA084C, 0x7D22103C, 0x107DF7DE,
          0xE8A12020, 0x08220832, 0x05220800,
          0x10450410, 0xA4A3F000, 0x08520832,
          0x05220400, 0x10450410, 0xE2F92020,
          0x0002085E, 0x7D3E0281, 0x107DF41F,
          0x00200000, 0x8001B000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0xC0000FBE, 0xFBF7E00F,
          0x5FBF7E7D, 0x0050BEE8, 0x440808A2,
          0x0A142FE8, 0x50810285, 0x0050A048,
          0x49E428A2, 0x0A142828, 0x40810284,
          0x0048A048, 0x10020FBE, 0x09F7EBAF,
          0xD89F3E84, 0x0047A04F, 0x09E48822,
          0x0A142AA1, 0x50810284, 0x0048A048,
          0x04082822, 0x0A142FA0, 0x50810285,
          0x0050A248, 0x00008FBE, 0xFBF42021,
          0x5F817E7D, 0x07D09CE8, 0x00008000,
          0x00000FE0, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x000C0180,
          0xDFBF4282, 0x0BFBF7EF, 0x42850505,
          0x004804BF, 0x50A142C6, 0x08401428,
          0x42852505, 0x00A808A0, 0x50A146AA,
          0x08401428, 0x42852505, 0x00081090,
          0x5FA14A92, 0x0843F7E8, 0x7E792505,
          0x00082088, 0x40A15282, 0x08420128,
          0x40852489, 0x00084084, 0x40A16282,
          0x0842022A, 0x40852451, 0x00088082,
          0xC0BF4282, 0xF843F42F, 0x7E85FC21,
          0x3E0900BF, 0x00000000, 0x00000004,
          0x00000000, 0x000C0180, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x04000402,
          0x41482000, 0x00000000, 0x00000800,
          0x04000404, 0x4100203C, 0x00000000,
          0x00000800, 0xF7DF7DF0, 0x514BEF85,
          0xBEFBEFBE, 0x04513BEF, 0x14414500,
          0x494A2885, 0xA28A28AA, 0x04510820,
          0xF44145F0, 0x474A289D, 0xA28A28AA,
          0x04510BE0, 0x14414510, 0x494A2884,
          0xA28A28AA, 0x02910A00, 0xF7DF7DF0,
          0xD14A2F85, 0xBEFBE8AA, 0x011F7BE0,
          0x00000000, 0x00400804, 0x20080000,
          0x00000000, 0x00000000, 0x00600F84,
          0x20080000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0xAC000000, 0x00000F01, 0x00000000,
          0x00000000, 0x24000000, 0x00000901,
          0x00000000, 0x06000000, 0x24000000,
          0x00000901, 0x00000000, 0x09108000,
          0x24FA28A2, 0x00000901, 0x00000000,
          0x013E0000, 0x2242252A, 0x00000952,
          0x00000000, 0x038A8000, 0x2422222A,
          0x00000929, 0x00000000, 0x010A8000,
          0x2412252A, 0x00000901, 0x00000000,
          0x010A8000, 0x24FBE8BE, 0x00000901,
          0x00000000, 0x0EBE8000, 0xAC020000,
          0x00000F01, 0x00000000, 0x00048000,
          0x0003E000, 0x00000000, 0x00000000,
          0x00008000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000038, 0x8443B80E, 0x00203A03,
          0x02BEA080, 0xF0000020, 0xC452208A,
          0x04202B02, 0xF8029122, 0x07F0003B,
          0xE44B388E, 0x02203A02, 0x081E8A1C,
          0x0411E92A, 0xF4420BE0, 0x01248202,
          0xE8140414, 0x05D104BA, 0xE7C3B880,
          0x00893A0A, 0x283C0E1C, 0x04500902,
          0xC4400080, 0x00448002, 0xE8208422,
          0x04500002, 0x80400000, 0x05200002,
          0x083E8E00, 0x04100002, 0x804003E0,
          0x07000042, 0xF8008400, 0x07F00003,
          0x80400000, 0x04000022, 0x00000000,
          0x00000000, 0x80400000, 0x04000002,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00800702, 0x1848A0C2,
          0x84010000, 0x02920921, 0x01042642,
          0x00005121, 0x42023F7F, 0x00291002,
          0xEFC01422, 0x7EFDFBF7, 0xEFDFA109,
          0x03BBBBF7, 0x28440F12, 0x42850A14,
          0x20408109, 0x01111010, 0x28440408,
          0x42850A14, 0x2040817F, 0x01111010,
          0xEFC78204, 0x7EFDFBF7, 0xE7CF8109,
          0x011111F3, 0x2850A932, 0x42850A14,
          0x2040A109, 0x01111010, 0x2850B840,
          0x42850A14, 0xEFDFBF79, 0x03BBBBF7,
          0x001FA020, 0x00000000, 0x00001000,
          0x00000000, 0x00002070, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x08022800, 0x00012283, 0x02430802,
          0x01010001, 0x8404147C, 0x20000144,
          0x80048404, 0x00823F08, 0xDFBF4284,
          0x7E03F7EF, 0x142850A1, 0x0000210A,
          0x50A14684, 0x528A1428, 0x142850A1,
          0x03EFA17A, 0x50A14A9E, 0x52521428,
          0x142850A1, 0x02081F4A, 0x50A15284,
          0x4A221428, 0xF42850A1, 0x03EFA14B,
          0x50A16284, 0x4A521428, 0x042850A1,
          0x0228A17A, 0xDFBF427C, 0x7E8BF7EF,
          0xF7EFDFBF, 0x03EFBD0B, 0x00000000,
          0x04000000, 0x00000000, 0x00000008,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00200508,
          0x00840400, 0x11458122, 0x00014210,
          0x00514294, 0x51420800, 0x20A22A94,
          0x0050A508, 0x00200000, 0x00000000,
          0x00050000, 0x08000000, 0xFEFBEFBE,
          0xFBEFBEFB, 0xFBEB9114, 0x00FBEFBE,
          0x20820820, 0x8A28A20A, 0x8A289114,
          0x3E8A28A2, 0xFEFBEFBE, 0xFBEFBE0B,
          0x8A289114, 0x008A28A2, 0x228A28A2,
          0x08208208, 0x8A289114, 0x088A28A2,
          0xFEFBEFBE, 0xFBEFBEFB, 0xFA2F9114,
          0x00FBEFBE, 0x00000000, 0x00000040,
          0x00000000, 0x00000000, 0x00000000,
          0x00000020, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00210100, 0x00000004,
          0x00000000, 0x00000000, 0x14508200,
          0x00001402, 0x00000000, 0x00000000,
          0x00000010, 0x00000020, 0x00000000,
          0x00000000, 0xA28A28BE, 0x00002228,
          0x00000000, 0x00000000, 0xA28A28AA,
          0x000022E8, 0x00000000, 0x00000000,
          0xA28A28AA, 0x000022A8, 0x00000000,
          0x00000000, 0xA28A28AA, 0x000022E8,
          0x00000000, 0x00000000, 0xBEFBEFBE,
          0x00003E2F, 0x00000000, 0x00000000,
          0x00000004, 0x00002028, 0x00000000,
          0x00000000, 0x80000000, 0x00003E0F,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000, 0x00000000,
          0x00000000, 0x00000000
        ]
  
  let charHeight = 10
  let charDivisor = 1

  let charWidths = [
    3, 1, 4, 6, 5, 7, 6, 2, 3, 3, 5, 5, 2, 4, 1, 7, 5, 2, 5, 5, 5, 5, 5, 5, 5, 5, 1, 1, 3, 4, 3, 6,
    7, 6, 6, 6, 6, 6, 6, 6, 6, 3, 5, 6, 5, 7, 6, 6, 6, 6, 6, 6, 7, 6, 7, 7, 6, 6, 6, 2, 7, 2, 3, 5,
    2, 5, 5, 5, 5, 5, 4, 5, 5, 1, 2, 5, 2, 5, 5, 5, 5, 5, 5, 5, 4, 5, 5, 5, 5, 5, 5, 3, 1, 3, 4, 4,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 5, 5, 5, 7, 1, 5, 3, 7, 3, 5, 4, 1, 7, 4, 3, 5, 3, 3, 2, 5, 6, 1, 2, 2, 3, 5, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 7, 6, 6, 6, 6, 6, 3, 3, 3, 3, 7, 6, 6, 6, 6, 6, 6, 5, 6, 6, 6, 6, 6, 6, 4, 6,
    5, 5, 5, 5, 5, 5, 9, 5, 5, 5, 5, 5, 2, 2, 3, 3, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 3, 5
  ]

  let imgWidth = 128
  let imgHeight = 128

  var imagePixels = newSeq[ZColor](imgWidth*imgHeight)

  for i in 0..<imgWidth*imgHeight: imagePixels[i] = TRANSPARENT

  var counter = 0

  var i = 0
  while i < imgWidth*imgHeight:
    for j in countdown(31, 0):
      if bitCheck(defaultFontData[counter], j): imagePixels[i+j] = WHITE

    inc(counter)

    if counter > 512: counter = 0

    inc(i, 32)

  try:
    defaultFont.texture = loadTexture(imagePixels, imgWidth, imgHeight)
  except:
    error "Failed to load default font texture."

  # discard sdl_image.savePNG(defaultFont.texture.data, "default_font.png") # Test saving default font image

  defaultFont.chars = newSeq[CharInfo](defaultFont.charCount)

  var currentLine = 0
  var currentPosX = charDivisor
  var testPosX = charDivisor

  for i in 0..<defaultFont.charCount:
    defaultFont.chars[i].value = 32 + i # First character is 32

    defaultFont.chars[i].rec.x = currentPosX
    defaultFont.chars[i].rec.y = charDivisor + currentLine*(charHeight + charDivisor)
    defaultFont.chars[i].rec.width = charWidths[i]
    defaultFont.chars[i].rec.height = charHeight

    testPosX += (defaultFont.chars[i].rec.width + charDivisor)

    if testPosX >= defaultFont.texture.data.w:
      inc(currentLine)
      currentPosX = 2*charDivisor + charWidths[i]
      testPosX = currentPosX

      defaultFont.chars[i].rec.x = charDivisor
      defaultFont.chars[i].rec.y = charDivisor + currentLine*(charHeight + charDivisor)
    else:
      currentPosX = testPosX

    defaultFont.chars[i].offsetX = 0
    defaultFont.chars[i].offsetY = 0
    defaultFont.chars[i].advanceX = 0
    
  defaultFont.baseSize = defaultFont.chars[0].rec.height

  info("[TEX ID $1] Default font loaded successfully" % $defaultFont.texture.id)

proc unloadDefaultFont*() =
  unloadTexture(defaultFont.texture)

proc getCharIndex(font: Font, letter: int): int =
  var index = 0

  for i in 0..<font.charCount:
    if font.chars[i].value == letter:
      index = i
      break

  return index

proc drawTextEx*(font: Font, text: string, position: Vec2f, fontSize: float, spacing: int, tint: ZColor) =
  let length = text.len
  var textOffsetX = 0
  var textOffsetY = 0
  var scaleFactor: float
  var index: int

  scaleFactor = fontSize / font.baseSize.float

  var i = 0
  while i < length:
    if NewLines.contains(text[i]):
      textoffsetY += ((font.baseSize.float + font.baseSize/2) * scaleFactor).int
      textOffsetX = 0

    else:
      if text[i] == 0xc2.char:
        index = getCharIndex(font, text[i + 1].int)
        inc(i)

      elif text[i] == 0xc3.char:
        index = getCharIndex(font, text[i + 1].int + 64)
        inc(i)
      
      else:
        index = getCharIndex(font, text[i].int)

      drawTexture(font.texture, font.chars[index].rec,
        Rectangle(
          x: int position.x + textOffsetX.float + font.chars[index].offsetX.float*scaleFactor,
          y: int position.y + textOffsetY.float + font.chars[index].offsetY.float*scaleFactor,
          width: int font.chars[index].rec.width.float*scaleFactor,
          height: int font.chars[index].rec.height.float*scaleFactor,
        ),
        vec2f(0),
        0.0,
        tint
      )

      if font.chars[index].advanceX == 0:
        textOffsetX += (font.chars[index].rec.width.float*scaleFactor + spacing.float).int
      else:
        textOffsetX += (font.chars[index].advanceX.float*scaleFactor + spacing.float).int

    inc(i)


proc drawText*(text: string, posX, posY: float, fontSize: float, color: ZColor) =
  if defaultFont.texture.id != 0:
    let position = vec2f(posx, posY)

    let defaultFontSize = 10.0
    var size = if fontSize < defaultFontSize: defaultFontSize else: fontSize
    let spacing = fontSize / defaultFontSize

    drawTextEx(defaultFont, text, position, size, spacing.int, color)

proc measureTextEx*(font: Font, text: string, fontSize: float, spacing: int): Vec2f =
  let len = text.len
  var 
    tempLen = 0
    lenCounter = 0

    textWidth = 0.0
    tempTextWidth = 0.0

    textHeight = font.baseSize.float
    scaleFactor = fontSize / font.baseSize.float

  for i in 0..<len:
    inc(lenCounter)

    if not NewLines.contains(text[i]):
      let index = getCharIndex(font, text[i].int)

      if font.chars[index].advanceX != 0:
        textWidth += font.chars[index].advanceX.float
      else:
        textWidth += (font.chars[index].rec.width + font.chars[index].offsetX).float
    else:
      if tempTextWidth < textWidth: tempTextWidth = textWidth
      lenCounter = 0
      textWidth = 0
      textHeight += font.baseSize.float * 1.5

    if tempLen < lenCounter: tempLen = lenCounter
  
  if tempTextWidth < textWidth: tempTextWidth = textWidth

  
  result.x = tempTextWidth * scaleFactor + ((tempLen - 1) * spacing).float
  result.y = textHeight * scaleFactor


proc measureText*(text: string, fontSize: var int): int =
  var vec = vec2f(0)

  if defaultFont.texture.id != 0:
    let defaultFontSize = 10
    if fontSize < defaultFontSize: fontSize = defaultFontSize
    let spacing = fontSize div defaultFontSize

    vec = measureTextEx(defaultFont, text, fontSize.float, spacing)

  result = vec.x.int

proc loadBitmapFont*(filename: string): Font =
  proc quotedString(input: string; foo: var string, n: int): int =
    assert input[n] == '"'
    result = n + 1
    while input[result] != '"':
      inc(result)
    foo = input[n+1..result-1]
  
  when not defined emscripten:
    if not fileExists(filename):
      warn("[$1] .fnt file could not be opened" % fileName)
      return defaultFont

    let splitFilename = filename.splitFile()
    if not (splitFilename.ext == ".fnt"):
      warn("[$1] font file must have extension .fnt" % fileName)
      return defaultFont
    
    var
      fontSize = 0
      texWidth, texHeight: int
      texFileName: string
      charsCount: int
      base: int

    let fontFileContent = readFile(filename)
    var rest = substr(fontFileContent, fontFileContent.find("lineHeight"), fontFileContent.len)

    
    discard scanf(rest, "lineHeight=$i base=$i scaleW=$i scaleH=$i", fontSize, base, texWidth, texHeight)

    rest = subStr(rest, rest.find("file"), rest.len)

    discard scanf(rest, "file=${quotedString()}", texFileName)

    let texFilePath = splitFilename.dir & DirSep & texFileName
    if not fileExists(texFilePath):
      warn("[$1] texture file for font does not exist" % fileName)
      return defaultFont

    result.texture = loadTexture(texFilePath)
    
    rest = subStr(rest, rest.find("count"), rest.len)
    discard scanf(rest, "count=$i", charsCount)

    result.baseSize = fontSize
    result.charCount = charsCount
    result.chars = @[]

    var
      charId, charX, charY, charWidth, charHeight, charOffsetX, charOffsetY, charAdvanceX: int
    
    for line in splitLines subStr(rest, rest.find("char"), rest.len):
      discard scanf(line, "char id=$i$sx=$i$sy=$i$swidth=$i$sheight=$i$sxoffset=$i$syoffset=$i$sxadvance=$i", charId, charX, charY, charWidth, charHeight, charOffsetX, charOffsetY, charAdvanceX)
      result.chars.add(CharInfo(
        value: charId,
        rec: Rectangle(x: charX, y: charY, width: charWidth, height: charHeight),
        offsetX: charOffsetX,
        offsetY: charOffsetY,
        advanceX: charAdvanceX
      ))
    
    info("[$1] Bitmap font loaded successfully" % filename)
    