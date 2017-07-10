import logging, math, opengl, sdl2, strutils, util, glm

const 
  MATRIX_STACK_SIZE = 16
  MAX_QUADS_BATCH = 8192
  MAX_DRAWS_BY_TEXTURE = 256
  TEMP_VERTEX_BUFFER_SIZE = 4096
  DEFAULT_ATTRIB_POSITION_NAME = "inPosition"
  DEFAULT_ATTRIB_TEXCOORD_NAME = "inTexCoord0"
  DEFAULT_ATTRIB_COLOR_NAME = "inColor"

type
  Shader = object
    id: GLuint
    texCoordLoc: GLint
    vertexLoc: GLint
    colorLoc: GLint
    mapTexture0Loc: GLint
    mvpLoc: GLint
  
  ZColor* = object
    r*, g*, b*, a*: int

  DrawMode* {.pure.} = enum
    ZGLLines = 0x0001     # GL_LINES
    ZGLTriangles = 0x0004 # GL_TRIANGLES
    ZGLQuads = 0x0007     #GL_QUADS

  MatrixMode* {.pure.} = enum
    ZGLModelView = 0x1700
    ZGLProjection = 0x1701
    ZGLTexture = 0x1702

  DrawCall = object
    vertexCount: int
    vaoId: GLuint
    textureId: GLuint
    shaderId: GLuint
    projection, modelView: Mat4f

  DynamicBuffer = object
    vCounter: int # vertex position counter to process (and draw) from full buffer
    tcCounter: int # vertex texcoord counter to process (and draw) from full buffer
    cCounter: int # vertex color counter to process (and draw) from full buffer
    vertices: seq[GLdouble] # vertex position (XYZ - 3 components per vertex) (shader-location = 0)
    texCoords: seq[GLfloat] # vertex texture coordinates (UV - 2 components per vertex) (shader-location = 1)
    colors: seq[cuchar] # vertex colors (RGBA - 4 components per vertex) (shader-location = 3)
    indices: seq[GLushort] # vertex indices (in case vertex data comes indexed) (6 indices per quad)
    vaoId: GLuint
    vboId: array[4, GLuint]

  Texture2D* = object
    id*: GLuint
    data*: sdl2.SurfacePtr
    mipMaps*: int

var
  stack: array[MATRIX_STACK_SIZE, Mat4f]
  stackCounter = 0
  currentDrawMode: DrawMode
  draws: seq[DrawCall]
  drawsCounter: int
  quads: DynamicBuffer
  currentDepth = -1.0
  defaultShader, currentShader: Shader
  whiteTexture: GLuint
  modelView, projection: Mat4f
  currentMatrix: ptr Mat4f
  currentMatrixMode: MatrixMode
  useTempBuffer = false
  tempBufferCount = 0
  tempBuffer: seq[Vec3f]



proc loadShaderProgram*(vertexShaderStr, fragmentShaderStr: string): GLuint =
  var
    program: GLuint = 0
    vertexShader, fragmentShader: GLuint

  var 
    vertexShaderSrc = allocCStringArray([
      vertexShaderStr
    ])
    fragmentShaderSrc = allocCStringArray([
      fragmentShaderStr
    ])

  vertexShader = glCreateShader(GL_VERTEX_SHADER)
  fragmentShader = glCreateShader(GL_FRAGMENT_SHADER)

  glShaderSource(vertexShader, 1, vertexShaderSrc, nil)
  glShaderSource(fragmentShader, 1, fragmentShaderSrc, nil)

  var
    success: GLint = 0

  glCompileShader(vertexShader)

  glGetShaderiv(vertexShader, GL_COMPILE_STATUS, addr success)

  if success != GL_TRUE:
    warn("[VSHDR ID $1] Failed to compile vertex shader..." % $vertexShader.int)

    var
      maxLength = 0.GLsizei
      length: GLsizei

    glGetShaderiv(vertexShader, GL_INFO_LOG_LENGTH, addr maxLength)
    var errorLog: cstring = cast[cstring](alloc(maxLength))
    glGetShaderInfoLog(vertexShader, maxLength, addr length, errorLog)

    info(errorLog)
    dealloc(errorLog)
  else:
    debug("[VSHDR ID $1] Vertex shader compiled successfully" % $vertexShader.int)

  glCompileShader(fragmentShader)

  glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, addr success)

  if success != GL_TRUE:
    warn("[VSHDR ID $1] Failed to compile fragment shader..." % $fragmentShader.int)

    var
      maxLength = 0.GLsizei
      length: GLsizei

    glGetShaderiv(fragmentShader, GL_INFO_LOG_LENGTH, addr maxLength)
    var errorLog: cstring = cast[cstring](alloc(maxLength))
    glGetShaderInfoLog(fragmentShader, maxLength, addr length, errorLog)

    info(errorLog)
    dealloc(errorLog)
  else:
    debug("[VSHDR ID $1] Fragment shader compiled successfully" % $fragmentShader.int)

  program = glCreateProgram()

  glAttachShader(program, vertexShader)
  glAttachShader(program, fragmentShader)

  # NOTE: Default attribute shader locations must be binded before linking
  glBindAttribLocation(program, 0, DEFAULT_ATTRIB_POSITION_NAME)
  glBindAttribLocation(program, 1, DEFAULT_ATTRIB_COLOR_NAME)

  glLinkProgram(program)

  glGetProgramiv(program, GL_LINK_STATUS, addr success)

  if success == GL_FALSE:
    warn("[SHDR ID $1] Failed to link shader program..." % $program.int)

    var
      maxLength = 0.GLsizei
      length: GLsizei

    glGetProgramiv(program, GL_INFO_LOG_LENGTH, addr maxLength)
    var errorLog: cstring = cast[cstring](alloc(maxLength))
    glGetProgramInfoLog(program, maxLength, addr length, errorLog)

    info(errorLog)
    dealloc(errorLog)

    glDeleteProgram(program)

    program = 0
  else:
    debug("[SHDR ID $1] Shader program loaded successfully" % $program.int)

  glDeleteShader(vertexShader)
  glDeleteShader(fragmentShader)

  deallocCStringArray(vertexShaderSrc)
  deallocCStringArray(fragmentShaderSrc)

  return program

proc loadDefaultShaderLocations(shader: var Shader) =
  shader.vertexLoc = glGetAttribLocation(shader.id, DEFAULT_ATTRIB_POSITION_NAME)
  shader.texCoordLoc = glGetAttribLocation(shader.id, DEFAULT_ATTRIB_TEXCOORD_NAME)
  shader.colorLoc = glGetAttribLocation(shader.id, DEFAULT_ATTRIB_COLOR_NAME)

  shader.mvpLoc = glGetUniformLocation(shader.id, "mvpMatrix")

  shader.mapTexture0Loc = glGetUniformLocation(shader.id, "texture0")

proc loadDefaultShader(): Shader =

  let vDefaultShaderStr = """
    #version 400
    layout(location=0) in vec3 inPosition;
    layout(location=1) in vec2 inTexCoord0;
    layout(location=2) in vec4 inColor;
    out vec2 exFragTexCoord;
    out vec4 exColor;
    uniform mat4 mvpMatrix;
    void main() {
      exFragTexCoord = inTexCoord0;
      exColor = inColor;
      gl_Position = mvpMatrix * vec4(inPosition, 1.0);
    }
  """

  let fDefaultShaderStr = """
    #version 400
    in vec2 exFragTexCoord;
    in vec4 exColor;
    out vec4 outColor;

    uniform sampler2D texture0;

    void main() {
        vec4 texelColor = texture(texture0, exFragTexCoord);
        outColor = texelColor * exColor;
    }
  """

  result.id = loadShaderProgram(vDefaultShaderStr, fDefaultShaderStr)

  if result.id != 0:
    loadDefaultShaderLocations(result)

proc loadDefaultBuffers() =
  quads.vertices = newSeq[GLdouble](3*4*MAX_QUADS_BATCH)
  quads.texCoords = newSeq[GLfloat](2*4*MAX_QUADS_BATCH)
  quads.colors = newSeq[cuchar](4*4*MAX_QUADS_BATCH)
  quads.indices = newSeq[GLushort](6*MAX_QUADS_BATCH)

  var i, k = 0

  while i < (6*MAX_QUADS_BATCH):
    quads.indices[i] = GLushort 4*k
    quads.indices[i+1] = GLushort 4*k+1
    quads.indices[i+2] = GLushort 4*k+2
    quads.indices[i+3] = GLushort 4*k
    quads.indices[i+4] = GLushort 4*k+2
    quads.indices[i+5] = GLushort 4*k+3
    inc(k)
    inc(i, 6)

  quads.vCounter = 0
  quads.tcCounter = 0
  quads.cCounter = 0

  glGenVertexArrays(1, addr quads.vaoId)
  glBindVertexArray(quads.vaoId)

  glGenBuffers(1, addr quads.vboId[0])
  glBindBuffer(GL_ARRAY_BUFFER, quads.vboId[0])
  glBufferData(GL_ARRAY_BUFFER, sizeof(GLdouble)*3*4*MAX_QUADS_BATCH, addr quads.vertices[0], GL_DYNAMIC_DRAW)
  glEnableVertexAttribArray(currentShader.vertexLoc)
  glVertexAttribPointer(currentShader.vertexLoc, 3, cGL_DOUBLE, false, 0, nil)

  glGenBuffers(1, addr quads.vboId[1])
  glBindBuffer(GL_ARRAY_BUFFER, quads.vboId[1])
  glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*2*4*MAX_QUADS_BATCH, addr quads.texCoords[0], GL_DYNAMIC_DRAW)
  glEnableVertexAttribArray(currentShader.texCoordLoc)
  glVertexAttribPointer(currentShader.texCoordLoc, 2, cGL_FLOAT, false, 0, nil)

  glGenBuffers(1, addr quads.vboId[2]);
  glBindBuffer(GL_ARRAY_BUFFER, quads.vboId[2]);
  glBufferData(GL_ARRAY_BUFFER, sizeof(int)*4*4*MAX_QUADS_BATCH, addr quads.colors[0], GL_DYNAMIC_DRAW);
  glEnableVertexAttribArray(currentShader.colorLoc);
  glVertexAttribPointer(currentShader.colorLoc, 4, cGL_UNSIGNED_BYTE, GL_TRUE, 0, nil);

  glGenBuffers(1, addr quads.vboId[3])
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, quads.vboId[3])
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLushort)*6*MAX_QUADS_BATCH, addr quads.indices[0], GL_STATIC_DRAW)

  info("[VAO ID $1] Default buffers VAO initialized successfully (quads)" % $quads.vaoId.int)


  glBindVertexArray(0)

proc zglLoadTexture*(data: pointer, width, height: int, pixelFormat: uint32, mipmapCount: int): GLuint =
  glBindTexture(GL_TEXTURE_2D, 0)

  var id: GLuint = 0

  glGenTextures(1, addr id)

  glBindTexture(GL_TEXTURE_2D, id)

  case pixelFormat
  of SDL_PIXELFORMAT_RGBA8888:
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8.ord, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data)
  else:
    discard

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT)

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)

  if mipmapCount > 1:
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR)

  glBindTexture(GL_TEXTURE_2D, 0)

  if id > 0: info("[TEX ID $1] Texture created successfully ($2x$3)" % [$id.int, $width, $height])
  else: warn("Texture could not be created")

  return id

proc zglInit*(width, height: int) =
  var pixels: array[4, cuchar] = [255.toCuchar, 255, 255, 255]

  whiteTexture = zglLoadTexture(addr pixels[0], 1, 1, SDL_PIXELFORMAT_RGBA8888, 1)

  if whiteTexture != 0:
    info("[TEX ID $1] Base white texture loaded successfully" % $whiteTexture.int)
  else: warn("Base white texture could not be loaded")

  defaultShader = loadDefaultShader()
  currentShader = defaultShader

  loadDefaultBuffers()

  tempBuffer = newSeq[Vec3f](TEMP_VERTEX_BUFFER_SIZE)

  for i in 0..<TEMP_VERTEX_BUFFER_SIZE:
    tempBuffer[i] = vec3f(0)

  draws = newSeq[DrawCall](MAX_DRAWS_BY_TEXTURE)

  drawsCounter = 1
  draws[drawsCounter - 1].textureId = whiteTexture
  currentDrawMode = DrawMode.ZGLTriangles

  for i in 0..<MATRIX_STACK_SIZE:
    stack[i] = mat4f(1.0)

  projection = mat4f(1.0)
  modelView = mat4f(1.0)
  currentMatrix = addr modelView

  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); # Color blending function (how colors are mixed)
  glEnable(GL_BLEND);    

proc zglClearColor*(r, g, b, a: int) =
  glClearColor(r / 255, g / 255, b / 255, a / 255)

proc zglClearScreenBuffers*() =
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

proc zglBegin*(mode: DrawMode) =
  currentDrawMode = mode

proc zglVertex3f*(x, y, z: GLdouble) =
  if useTempBuffer:
    tempBuffer[tempBufferCount].x = x
    tempBuffer[tempBufferCount].y = y
    tempBuffer[tempBufferCount].z = z
    inc(tempBufferCount)

  else:
    case currentDrawMode
    of DrawMode.ZGLQuads:
      if quads.vCounter/4 < MAX_QUADS_BATCH:
        quads.vertices[3*quads.vCounter] = x
        quads.vertices[3*quads.vCounter + 1] = y
        quads.vertices[3*quads.vCounter + 2] = z

        inc(quads.vCounter)

        inc(draws[drawsCounter - 1].vertexCount)
      else:
        error("MAX_QUADS_BATCH overflow")
    else:
      discard

proc zglEnd*() =
  if useTempBuffer:
    for i in 0..<tempBufferCount:
      tempBuffer[i] = (vec4(tempBuffer[i], 0) * currentMatrix[]).xyz
    
    useTempBuffer = false

    for i in 0..<tempBufferCount:
      zglVertex3f(tempBuffer[i].x, tempBuffer[i].y, tempBuffer[i].z)

    tempBufferCount = 0

  case currentDrawMode:
    of DrawMode.ZGLLines:
      discard
    of DrawMode.ZGLTriangles:
      discard
    of DrawMode.ZGLQuads:
      # Make sure colors count matches vertex count
      if quads.vCounter != quads.cCounter:
        let addColors = quads.vCounter - quads.cCounter

        for i in 0..<addColors:
          quads.colors[4*quads.cCounter] = quads.colors[4*quads.cCounter - 4]
          quads.colors[4*quads.cCounter + 1] = quads.colors[4*quads.cCounter - 3]
          quads.colors[4*quads.cCounter + 2] = quads.colors[4*quads.cCounter - 2]
          quads.colors[4*quads.cCounter + 3] = quads.colors[4*quads.cCounter - 1]

          inc(quads.cCounter)
      
      if quads.vCounter != quads.tcCounter:
        let addTexCoords = quads.vCounter - quads.tcCounter
        
        for i in 0..<addTexCoords:
          quads.texcoords[2*quads.tcCounter] = 0.0
          quads.texcoords[2*quads.tcCounter + 1] = 0.0
          inc(quads.tcCounter)
  
  currentDepth += (1.0f/20000.0f)

proc drawDefaultBuffers() =
  var matProjection = projection
  var matModelView = modelView

  if quads.vCounter > 0:
    glUseProgram(currentShader.id)

    var matMVP = modelView * projection

    glUniformMatrix4fv(currentShader.mvpLoc, 1, false, matMVP.caddr)
    glUniform1i(currentShader.mapTexture0Loc, 0)

    var
      quadsCount = 0
      numIndicesToProcess = 0
      indicesOffset = 0

    glBindVertexArray(quads.vaoId)

    for i in 0..<drawsCounter:
      quadsCount = int draws[i].vertexCount/4
      numIndicesToProcess = quadsCount*6

      glBindTexture(GL_TEXTURE_2D, draws[i].textureId)

      glDrawElements(GL_TRIANGLES, numIndicesToProcess.GLsizei, GL_UNSIGNED_SHORT, cast[ptr GLvoid](sizeof(GLushort)*indicesOffset))

      indicesOffset += int draws[i].vertexCount/4*6

      glBindTexture(GL_TEXTURE_2D, 0)
    
    glBindVertexArray(0)

    glUseProgram(0)

  drawsCounter = 1
  draws[0].vertexCount = 0

  quads.vCounter = 0
  quads.tcCounter = 0
  quads.cCounter = 0

  currentDepth = -1.0

  projection = matProjection

  modelview = matModelView

proc updateDefaultBuffers() =
  if quads.vCounter > 0:
    glBindVertexArray(quads.vaoId)

    glBindBuffer(GL_ARRAY_BUFFER, quads.vboId[0])
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(GLdouble)*3*quads.vCounter, addr quads.vertices[0])

    glBindBuffer(GL_ARRAY_BUFFER, quads.vboId[1])
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(float)*2*quads.vCounter, addr quads.texcoords[0])

    glBindBuffer(GL_ARRAY_BUFFER, quads.vboId[2])
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(int)*4*quads.vCounter, addr quads.colors[0])
  
  glBindVertexArray(0)

proc zglDraw*() =
  updateDefaultBuffers()
  drawDefaultBuffers()

proc zglColor4ub*(x, y, z, w: int) =
  case currentDrawMode
  of DrawMode.ZGLQuads:
    quads.colors[4*quads.cCounter] = x
    quads.colors[4*quads.cCounter + 1] = y
    quads.colors[4*quads.cCounter + 2] = z
    quads.colors[4*quads.cCounter + 3] = w

    inc(quads.cCounter)
  else:
    discard

proc zglVertex2f*(x, y: float32) =
  zglVertex3f(x, y, currentDepth)

proc zglViewport*(x, y, width, height: int) =
  glViewport(x, y, width, height)

proc zglMatrixMode*(mode: MatrixMode) =
  if mode == MatrixMode.ZGLProjection:
    currentMatrix = addr projection
  elif mode == MatrixMode.ZGLModelView:
    currentMatrix = addr modelView

  currentMatrixMode = mode

proc zglLoadIdentity*() =
  currentMatrix[] = mat4f(1.0)

proc zglOrtho*(left, right, bottom, top, near, far: float) =
  var matOrtho = ortho[GLfloat](left, right, bottom, top, near, far)
  currentMatrix[] = currentMatrix[] * matOrtho

proc unloadDefaultShader() = 
  glUseProgram(0)
  glDeleteProgram(defaultShader.id)

proc unloadDefaultBuffers() =
  glBindVertexArray(0)
  #glDisableVertexAttribArray(0)
  #glDisableVertexAttribArray(1)
  #glDisableVertexAttribArray(2)
  #glDisableVertexAttribArray(3)
  glBindBuffer(GL_ARRAY_BUFFER, 0)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)

  glDeleteBuffers(1, addr quads.vboId[0])
  glDeleteBuffers(1, addr quads.vboId[1])
  glDeleteBuffers(1, addr quads.vboId[2])
  glDeleteBuffers(1, addr quads.vboId[3])

  glDeleteVertexArrays(1, addr quads.vaoId)

proc zglShutdown*() =
  unloadDefaultShader()
  unloadDefaultBuffers()

  glDeleteTextures(1, addr whiteTexture)
  info("[TEX ID $1] Unloaded texture data (base white texture) from VRAM" % $whiteTexture.int);


proc zglEnableTexture*(textureId: GLuint) =
  if draws[drawsCounter - 1].textureId != textureId:
    if draws[drawsCounter - 1].vertexCount > 0:
      inc(drawsCounter)

      draws[drawsCounter - 1].textureId = textureId
      draws[drawsCounter - 1].vertexCount = 0

proc zglDisableTexture*() =
  if quads.vCounter/4 >= MAX_QUADS_BATCH: 
    zglDraw()

proc zglPushMatrix*() =
  if stackCounter == MATRIX_STACK_SIZE - 1:
    error("Stack Buffer Overflow (MAX $1 Matrix)" % $MATRIX_STACK_SIZE)

  stack[stackCounter] = currentMatrix[]
  zglLoadIdentity()
  inc(stackCounter)

  if currentMatrixMode == MatrixMode.ZGLModelView:
    useTempBuffer = true

proc zglTranslatef*(x, y, z: float) =
  currentMatrix[] = translate(currentMatrix[], vec3f(x, y, z))

proc zglRotatef*(angleDeg: float, x, y, z: float) =
  currentMatrix[] = rotate(currentMatrix[], vec3f(x, y, z), degToRad(angleDeg))

proc zglScalef*(x, y, z: float) =
  currentMatrix[] = scale(currentMatrix[], vec3f(x, y, z))

proc zglNormal3f*(x, y, z: float) =
  # TODO 
  discard

# Define one vertex (texture coordinate)
# NOTE: Texture coordinates are limited to QUADS only
proc zglTexCoord2f*(x, y: float) =
  if currentDrawMode == DrawMode.ZGLQuads:
    quads.texcoords[2*quads.tcCounter] = x;
    quads.texcoords[2*quads.tcCounter + 1] = y;

    inc(quads.tcCounter)

proc zglPopMatrix*() =
  if stackCounter > 0:
    let mat = stack[stackCounter - 1]
    currentMatrix[] = mat
    dec(stackCounter)

proc zglDeleteTexture*(id: var GLuint) =
  if id != 0:
    glDeleteTextures(1, addr id)