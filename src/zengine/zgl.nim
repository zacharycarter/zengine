import logging, math, opengl, sdl2, strutils, util, os, tables, assimp, glm

const 
  MATRIX_STACK_SIZE = 16
  MAX_TRIANGLES_BATCH = 4096
  MAX_LINES_BATCH = 8192
  MAX_QUADS_BATCH = 8192
  MAX_DRAWS_BY_TEXTURE = 256
  TEMP_VERTEX_BUFFER_SIZE = 4096
  DEFAULT_ATTRIB_POSITION_NAME = "inPosition"
  DEFAULT_ATTRIB_TEXCOORD_NAME = "inTexCoord0"
  DEFAULT_ATTRIB_NORMAL_NAME = "inNormal"
  DEFAULT_ATTRIB_COLOR_NAME = "inColor"

type
  Shader* = object
    id*: GLuint
    vertexLoc: GLint
    texCoordLoc: GLint
    normalLoc: GLint
    colDiffuseLoc: GLint
    colAmbientLoc: GLint
    colSpecularLoc: GLint
    colorLoc: GLint
    mapTexture0Loc, mapTexture1Loc, mapTexture2Loc: GLint
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

  RenderTexture2D* = object
    id*: GLuint
    texture*, depth*: Texture2D

  Camera* = object
    position*, target*, up*: Vec3f
    fovY*: float

  Camera2D* = object
    offset*, target*: Vec2f
    rotation*, zoom*: float

  Material* = object
    shader*: Shader
    texDiffuse*, texNormal*, texSpecular*: Texture2D
    colDiffuse*, colAmbient*, colSpecular*: ZColor
    glossiness*: float

  Model* = object
    meshEntries*: seq[MeshEntry]
    vaoId: GLuint
    vboId: array[8, GLuint]
    vertices*: seq[GLfloat]
    vertexCount*, triangleCount*: GLint
    materials*: seq[Material]
    indices*: seq[GLushort]
    texCoords*: seq[GLfloat]
    normals*: seq[GLfloat]
    colors: seq[cuchar]
    bones*: seq[Bone]
    boneInfos*: seq[BoneInfo]
    boneMapping*: Table[string, int]
    numBones*: uint
    globalInverseTransform*: Mat4f
    scene*: PScene

  MeshEntry* = object
    materialIndex*: int
    baseVertex*, baseIndex*: GLint
    indexCount*: GLint

  Bone* = object
    ids*: array[4, GLint]
    weights*: array[4, GLfloat]

  BoneInfo* = object
    boneOffset*: Mat4f
    finalTransformation*: Mat4f
      
  # Mesh* = object
  #   vertexCount*: int
  #   triangleCount*: int
  #   vertices*: seq[GLfloat]
  #   texCoords*: seq[GLfloat]
  #   texCoords2: seq[float]
  #   normals*: seq[GLfloat]
  #   tangents: seq[float]
  #   colors: seq[cuchar]
  #   indices*: seq[GLushort]
  #   vaoId: GLuint
  #   vboId: array[7, GLuint]
  #   materialIndex*: int

var
  stack: array[MATRIX_STACK_SIZE, Mat4f]
  stackCounter = 0
  currentDrawMode: DrawMode
  draws: seq[DrawCall]
  drawsCounter: int
  lines: DynamicBuffer
  quads: DynamicBuffer
  triangles: DynamicBuffer
  currentDepth = -1.0
  defaultShader, currentShader: Shader
  whiteTexture: GLuint
  modelView, projection: Mat4f
  currentMatrix: ptr Mat4f
  currentMatrixMode: MatrixMode
  useTempBuffer = false
  tempBufferCount = 0
  tempBuffer: seq[Vec3f]

proc getDefaultTexture*(): Texture2D =
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

  result.id = whiteTexture
  result.data = sdl2.createRGBSurface(0, 1, 1, 32, rmask, gmask, bmask, amask)
  result.mipMaps = 1

proc getDefaultShader*(): Shader =
  return defaultShader

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
  glBindAttribLocation(program, 1, DEFAULT_ATTRIB_TEXCOORD_NAME)
  glBindAttribLocation(program, 2, DEFAULT_ATTRIB_NORMAL_NAME)
  glBindAttribLocation(program, 3, DEFAULT_ATTRIB_COLOR_NAME)

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

proc getShaderLocation*(shader: Shader, uniformName: string): GLint =
  result = -1

  result = glGetUniformLocation(shader.id, uniformName)

  if result == -1:
    debug("[SHDR ID $1] Shader location for $2 could not be found" % [$shader.id.int, uniformName])

proc loadDefaultShaderLocations(shader: var Shader) =
  shader.vertexLoc = glGetAttribLocation(shader.id, DEFAULT_ATTRIB_POSITION_NAME)
  shader.texCoordLoc = glGetAttribLocation(shader.id, DEFAULT_ATTRIB_TEXCOORD_NAME)
  shader.normalLoc = glGetAttribLocation(shader.id, DEFAULT_ATTRIB_NORMAL_NAME)
  shader.colorLoc = glGetAttribLocation(shader.id, DEFAULT_ATTRIB_COLOR_NAME)

  shader.mvpLoc = glGetUniformLocation(shader.id, "mvpMatrix")

  shader.colDiffuseLoc = glGetUniformLocation(shader.id, "colDiffuse")
  shader.colAmbientLoc = glGetUniformLocation(shader.id, "colAmbient")
  shader.colSpecularLoc = glGetUniformLocation(shader.id, "colSpecular")

  shader.mapTexture0Loc = glGetUniformLocation(shader.id, "texture0")
  shader.mapTexture1Loc = glGetUniformLocation(shader.id, "texture1")
  shader.mapTexture2Loc = glGetUniformLocation(shader.id, "texture2")

proc loadShader*(vsFilePath, fsFilePath: string): Shader =
  var 
    vsFileContent = ""
    fsFileContent = ""
  if fileExists(vsFilePath):
    vsFileContent = readFile(vsFilePath)
  if fileExists(fsFilePath):
    fsFileContent = readFile(fsFilePath)
  
  result.id = loadShaderProgram(vsFileContent, fsFileContent)

  if result.id != 0:
    loadDefaultShaderLocations(result)

proc loadDefaultShader(): Shader =

  let vDefaultShaderStr = """
    #version 330
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
    #version 330
    in vec2 exFragTexCoord;
    in vec4 exColor;
    out vec4 outColor;

    uniform sampler2D texture0;
    uniform vec4 colDiffuse;

    void main() {
        vec4 texelColor = texture(texture0, exFragTexCoord);
        outColor = texelColor * colDiffuse * exColor;
    }
  """

  result.id = loadShaderProgram(vDefaultShaderStr, fDefaultShaderStr)

  if result.id != 0:
    loadDefaultShaderLocations(result)

proc loadDefaultBuffers() =
  lines.vertices = newSeq[GLdouble](3*2*MAX_LINES_BATCH)
  lines.colors = newSeq[cuchar](4*2*MAX_LINES_BATCH)

  triangles.vertices = newSeq[GLdouble](3*3*MAX_TRIANGLES_BATCH)
  triangles.colors = newSeq[cuchar](4*3*MAX_TRIANGLES_BATCH)

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

  glGenVertexArrays(1, addr lines.vaoId)
  glBindVertexArray(lines.vaoId)

  glGenBuffers(1, addr lines.vboId[0])
  glBindBuffer(GL_ARRAY_BUFFER, lines.vboId[0])
  glBufferData(GL_ARRAY_BUFFER, sizeof(GLdouble)*3*2*MAX_LINES_BATCH, addr lines.vertices[0], GL_DYNAMIC_DRAW)
  glEnableVertexAttribArray(currentShader.vertexLoc)
  glVertexAttribPointer(currentShader.vertexLoc, 3, cGL_DOUBLE, false, 0, nil)

  glGenBuffers(1, addr lines.vboId[1]);
  glBindBuffer(GL_ARRAY_BUFFER, lines.vboId[1]);
  glBufferData(GL_ARRAY_BUFFER, sizeof(cuchar)*4*2*MAX_LINES_BATCH, addr lines.colors[0], GL_DYNAMIC_DRAW);
  glEnableVertexAttribArray(currentShader.colorLoc);
  glVertexAttribPointer(currentShader.colorLoc, 4, cGL_UNSIGNED_BYTE, GL_TRUE, 0, nil);

  info("[VAO ID $1] Default buffers VAO initialized successfully (lines)" % $lines.vaoId.int)

  glGenVertexArrays(1, addr triangles.vaoId)
  glBindVertexArray(triangles.vaoId)

  glGenBuffers(1, addr triangles.vboId[0])
  glBindBuffer(GL_ARRAY_BUFFER, triangles.vboId[0])
  glBufferData(GL_ARRAY_BUFFER, sizeof(GLdouble)*3*3*MAX_TRIANGLES_BATCH, addr triangles.vertices[0], GL_DYNAMIC_DRAW)
  glEnableVertexAttribArray(currentShader.vertexLoc)
  glVertexAttribPointer(currentShader.vertexLoc, 3, cGL_DOUBLE, false, 0, nil)

  glGenBuffers(1, addr triangles.vboId[1]);
  glBindBuffer(GL_ARRAY_BUFFER, triangles.vboId[1]);
  glBufferData(GL_ARRAY_BUFFER, sizeof(cuchar)*4*3*MAX_TRIANGLES_BATCH, addr triangles.colors[0], GL_DYNAMIC_DRAW);
  glEnableVertexAttribArray(currentShader.colorLoc);
  glVertexAttribPointer(currentShader.colorLoc, 4, cGL_UNSIGNED_BYTE, GL_TRUE, 0, nil);

  info("[VAO ID $1] Default buffers VAO initialized successfully (triangles)" % $triangles.vaoId.int)

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
  glBufferData(GL_ARRAY_BUFFER, sizeof(cuchar)*4*4*MAX_QUADS_BATCH, addr quads.colors[0], GL_DYNAMIC_DRAW);
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

  if sdl2.SDL_BYTESPERPIXEL(pixelFormat) == 4:
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8.ord, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data)
  else:
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8.ord, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, data)

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT)

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)

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
    stack[i] = mat4f()

  projection = mat4f()
  modelView = mat4f()
  currentMatrix = addr modelView

  glDisable(GL_DEPTH_TEST)

  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA) # Color blending function (how colors are mixed)
  glEnable(GL_BLEND)

  glEnable(GL_MULTISAMPLE)

  glCullFace(GL_BACK)
  glFrontFace(GL_CCW)
  glEnable(GL_CULL_FACE)

  glClearColor(0.0, 0.0, 0.0, 1.0)
  glClearDepth(1.0f)
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

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
    of DrawMode.ZGLLines:
      if lines.vCounter/3 < MAX_LINES_BATCH:
        lines.vertices[3*lines.vCounter] = x
        lines.vertices[3*lines.vCounter + 1] = y
        lines.vertices[3*lines.vCounter + 2] = z

        inc(lines.vCounter)
      else:
        error("MAX_TRIANGLES_BATCH overflow")

    of DrawMode.ZGLTriangles:
      if triangles.vCounter/3 < MAX_TRIANGLES_BATCH:
        triangles.vertices[3*triangles.vCounter] = x
        triangles.vertices[3*triangles.vCounter + 1] = y
        triangles.vertices[3*triangles.vCounter + 2] = z

        inc(triangles.vCounter)
      else:
        error("MAX_TRIANGLES_BATCH overflow")
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
        tempBuffer[i] = (currentMatrix[] * vec4f(tempBuffer[i], 1)).xyz

    
    useTempBuffer = false

    for i in 0..<tempBufferCount:
      zglVertex3f(tempBuffer[i].x, tempBuffer[i].y, tempBuffer[i].z)

    tempBufferCount = 0

  case currentDrawMode:
    of DrawMode.ZGLLines:
      if lines.vCounter != lines.cCounter:
        let addColors = lines.vCounter - lines.cCounter
        for i in 0..<addColors:
          lines.colors[4*lines.cCounter] = lines.colors[4*lines.cCounter - 4]
          lines.colors[4*lines.cCounter + 1] = lines.colors[4*lines.cCounter - 3]
          lines.colors[4*lines.cCounter + 2] = lines.colors[4*lines.cCounter - 2]
          lines.colors[4*lines.cCounter + 3] = lines.colors[4*lines.cCounter - 1]

          inc(lines.cCounter)
    of DrawMode.ZGLTriangles:
      if triangles.vCounter != triangles.cCounter:
        let addColors = triangles.vCounter - triangles.cCounter
        for i in 0..<addColors:
          triangles.colors[4*triangles.cCounter] = triangles.colors[4*triangles.cCounter - 4]
          triangles.colors[4*triangles.cCounter + 1] = triangles.colors[4*triangles.cCounter - 3]
          triangles.colors[4*triangles.cCounter + 2] = triangles.colors[4*triangles.cCounter - 2]
          triangles.colors[4*triangles.cCounter + 3] = triangles.colors[4*triangles.cCounter - 1]

          inc(triangles.cCounter)
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

proc matrixToFloat*(mat: Mat4f): array[16, GLfloat] =
    var buffer {.global.}: array[16, GLfloat]
  
    buffer[0] = mat[0][0]
    buffer[1] = mat[0][1]
    buffer[2] = mat[0][2]
    buffer[3] = mat[0][3]
    buffer[4] = mat[1][0]
    buffer[5] = mat[1][1]
    buffer[6] = mat[1][2]
    buffer[7] = mat[1][3]
    buffer[8] = mat[2][0]
    buffer[9] = mat[2][1]
    buffer[10] = mat[2][2]
    buffer[11] = mat[2][3]
    buffer[12] = mat[3][0]
    buffer[13] = mat[3][1]
    buffer[14] = mat[3][2]
    buffer[15] = mat[3][3]

    return buffer

proc drawDefaultBuffers() =
  var matProjection = projection
  var matModelView = modelView

  if lines.vCounter > 0 or quads.vCounter > 0 or triangles.vCounter > 0:
    glUseProgram(currentShader.id)

    # var matMVP = matrixMultiply(modelView, projection)
    var matMVP = transpose(modelView * projection)

    var matMVPFloatArray = matrixToFloat(matMVP)
    glUniformMatrix4fv(currentShader.mvpLoc, 1, false, addr matMVPFloatArray[0])
    glUniform4f(currentShader.colDiffuseLoc, 1.0f, 1.0f, 1.0f, 1.0f)
    glUniform1i(currentShader.mapTexture0Loc, 0)

  if lines.vCounter > 0:
    glBindTexture(GL_TEXTURE_2D, whiteTexture)

    glBindVertexArray(lines.vaoId)

    glDrawArrays(GL_LINES, 0, lines.vCounter)

    glBindTexture(GL_TEXTURE_2D, 0)

  if triangles.vCounter > 0:
    glBindTexture(GL_TEXTURE_2D, whiteTexture)

    glBindVertexArray(triangles.vaoId)

    glDrawArrays(GL_TRIANGLES, 0, triangles.vCounter)

    glBindTexture(GL_TEXTURE_2D, 0)

  if quads.vCounter > 0:

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

  lines.vCounter = 0
  lines.cCounter = 0
  triangles.vCounter = 0
  triangles.cCounter = 0
  quads.vCounter = 0
  quads.tcCounter = 0
  quads.cCounter = 0

  currentDepth = -1.0

  projection = matProjection

  modelview = matModelView

proc updateDefaultBuffers() =
  if lines.vCounter > 0:
    glBindVertexArray(lines.vaoId)

    glBindBuffer(GL_ARRAY_BUFFER, lines.vboId[0])
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(GLdouble)*3*lines.vCounter, addr lines.vertices[0])

    glBindBuffer(GL_ARRAY_BUFFER, lines.vboId[1])
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(int)*4*lines.cCounter, addr lines.colors[0])

  if triangles.vCounter > 0:
    glBindVertexArray(triangles.vaoId)

    glBindBuffer(GL_ARRAY_BUFFER, triangles.vboId[0])
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(GLdouble)*3*triangles.vCounter, addr triangles.vertices[0])

    glBindBuffer(GL_ARRAY_BUFFER, triangles.vboId[1])
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(int)*4*triangles.cCounter, addr triangles.colors[0])

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
  of DrawMode.ZGLLines:
    lines.colors[4*lines.cCounter] = x
    lines.colors[4*lines.cCounter + 1] = y
    lines.colors[4*lines.cCounter + 2] = z
    lines.colors[4*lines.cCounter + 3] = w

    inc(lines.cCounter)
  of DrawMode.ZGLTriangles:
    triangles.colors[4*triangles.cCounter] = x
    triangles.colors[4*triangles.cCounter + 1] = y
    triangles.colors[4*triangles.cCounter + 2] = z
    triangles.colors[4*triangles.cCounter + 3] = w

    inc(triangles.cCounter)
  of DrawMode.ZGLQuads:
    quads.colors[4*quads.cCounter] = x
    quads.colors[4*quads.cCounter + 1] = y
    quads.colors[4*quads.cCounter + 2] = z
    quads.colors[4*quads.cCounter + 3] = w

    inc(quads.cCounter)
  else:
    discard

proc zglColor3f*(x, y, z: float) =
  zglColor4ub(int x * 255, int y * 255, int z * 255, 255)

proc zglVertex2i*(x, y: int) =
  zglVertex3f(x.float, y.float, currentDepth)

proc zglVertex2f*(x, y: float32) =
  zglVertex3f(x, y, currentDepth)

proc zglViewport*(x, y, width, height: int) =
  glViewport(x, y, width, height)

proc zglLoadIdentity*() =
  currentMatrix[] = mat4f()

proc zglMatrixMode*(mode: MatrixMode) =
  if mode == MatrixMode.ZGLProjection:
    currentMatrix = addr projection
  elif mode == MatrixMode.ZGLModelView:
    currentMatrix = addr modelView

  currentMatrixMode = mode

proc zglPushMatrix*() =
  if stackCounter == MATRIX_STACK_SIZE - 1:
    error("Stack Buffer Overflow (MAX $1 Matrix)" % $MATRIX_STACK_SIZE)

  stack[stackCounter] = currentMatrix[]
  zglLoadIdentity()
  inc(stackCounter)

  if currentMatrixMode == MatrixMode.ZGLModelView:
    useTempBuffer = true


proc zglOrtho*(left, right, bottom, top, near, far: float) =
  var matOrtho = ortho[float32](left, right, bottom, top, near, far)
  currentMatrix[] = currentMatrix[] * transpose(matOrtho)

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
    if draws[drawsCounter - 1].vertexCount > 0: inc(drawsCounter)

    draws[drawsCounter - 1].textureId = textureId
    draws[drawsCounter - 1].vertexCount = 0

proc zglDisableTexture*() =
  if quads.vCounter/4 >= MAX_QUADS_BATCH: 
    zglDraw()

proc zglTranslatef*(x, y, z: float) =
  # var tmp = matrixTranslate(x, y, z)
  # currentMatrix[] = matrixMultiply(currentMatrix[], tmp)
  var tmp = translate(mat4f(), vec3f(x, y, z))
  currentMatrix[] = currentMatrix[] * tmp

proc zglRotatef*(angleDeg: float, x, y, z: float) =
  # var matRotation = matrixIdentity()

  # var axis = Vector3(x: x, y: y, z: z)
  # vectorNormalize(axis)
  # matRotation = matrixRotate(axis, degToRad(angleDeg))

  # currentMatrix[] = matrixMultiply(currentMatrix[], matRotation)
  var matRotation = rotate(mat4f(), vec3f(x, y, z), degToRad(angleDeg))
  currentMatrix[] = currentMatrix[] * matRotation

proc zglScalef*(x, y, z: float) =
  var tmp = scale(mat4f(), vec3f(x, y, z))
  currentMatrix[] = currentMatrix[] * tmp

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

proc zglFrustum*(left, right, bottom, top, near, far: float) =
  # var frustum = matrixFrustum(left, right, bottom, top, near, far)
  var frustum = frustum[float32](left, right, bottom, top, near, far)
  # matrixTranspose(frustum)
  # currentMatrix[] = matrixMultiply(currentMatrix[], frustum)
  currentMatrix[] = currentMatrix[] * transpose(frustum)

proc zglMultMatrix*(m: array[16, GLfloat]) =
  var tmp = transpose(mat4f(
    vec4f(m[0], m[1], m[2], m[3]),
    vec4f(m[4], m[5], m[6], m[7]),
    vec4f(m[8], m[9], m[10], m[11]),
    vec4f(m[12], m[13], m[14], m[15])
  ))
  currentMatrix[] = currentMatrix[] * tmp

proc zglEnableDepthTest*() =
  glEnable(GL_DEPTH_TEST)

proc zglDisableDepthTest*() =
  glDisable(GL_DEPTH_TEST)

proc zglLoadModel*(model: var Model, dynamic: bool) =
  model.vaoId = 0
  model.vboId[0] = 0
  model.vboId[1] = 0
  model.vboId[2] = 0
  model.vboId[3] = 0
  model.vboId[4] = 0
  model.vboId[5] = 0
  model.vboId[6] = 0
  model.vboId[7] = 0

  var vaoId: GLuint = 0
  var vboId: array[8, GLuint]

  glGenVertexArrays(1, addr vaoId)
  glBindVertexArray(vaoId)

  let drawHint = if dynamic: GL_DYNAMIC_DRAW else: GL_STATIC_DRAW

  glGenBuffers(1, addr vboId[0])
  glBindBuffer(GL_ARRAY_BUFFER, vboId[0])
  glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*model.vertexCount, addr model.vertices[0], drawHint)
  glVertexAttribPointer(0, 3, cGL_FLOAT, GL_FALSE, 0, nil)
  glEnableVertexAttribArray(0)

  glGenBuffers(1, addr vboId[1])
  glBindBuffer(GL_ARRAY_BUFFER, vboId[1])
  glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*2*model.vertexCount, addr model.texcoords[0], drawHint);
  glVertexAttribPointer(1, 2, cGL_FLOAT, GL_FALSE, 0, nil)
  glEnableVertexAttribArray(1)

  if model.normals != nil:
    glGenBuffers(1, addr vboId[2])
    glBindBuffer(GL_ARRAY_BUFFER, vboId[2])
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*model.vertexCount, addr model.normals[0], drawHint)
    glVertexAttribPointer(2, 3, cGL_FLOAT, GL_FALSE, 0, nil)
    glEnableVertexAttribArray(2)
  else:
    glVertexAttrib3f(2, 1.0, 1.0, 1.0)
    glDisableVertexAttribArray(2)

  if model.colors != nil:
    glGenBuffers(1, addr vboId[3])
    glBindBuffer(GL_ARRAY_BUFFER, vboId[3])
    glBufferData(GL_ARRAY_BUFFER, sizeof(cuchar)*4*model.vertexCount, addr model.colors[0], drawHint)
    glVertexAttribPointer(3, 4, cGL_UNSIGNED_BYTE, GL_TRUE, 0, nil)
    glEnableVertexAttribArray(3)
  else:
    glVertexAttrib4f(3, 1.0, 1.0, 1.0, 1.0)
    glDisableVertexAttribArray(3)

  glVertexAttrib3f(4, 0.0f, 0.0f, 0.0f)
  glDisableVertexAttribArray(4)
  
  glVertexAttrib2f(5, 0.0f, 0.0f)
  glDisableVertexAttribArray(5)

  if model.bones != nil:
    glGenBuffers(1, addr vboId[6])
    glBindBuffer(GL_ARRAY_BUFFER, vboId[6])
    glBufferData(GL_ARRAY_BUFFER, sizeof(Bone) * model.bones.len, addr model.bones[0], drawHint);
    glEnableVertexAttribArray(6)
    glVertexAttribIPointer(6, 4, cGL_INT, GLsizei sizeof(Bone), nil)
    glEnableVertexAttribArray(7)  
    glVertexAttribPointer(7, 4, cGL_FLOAT, GL_FALSE, GLSizei sizeof(Bone), cast[pointer](sizeof(array[4, GLint])));
  else:
    glDisableVertexAttribArray(6)
    glDisableVertexAttribArray(7)

  if model.indices != nil:
    glGenBuffers(1, addr vboId[7])
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vboId[7])
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(GLushort)*model.triangleCount*3, addr model.indices[0], drawHint)

  model.vboId[0] = vboId[0]
  model.vboId[1] = vboId[1]
  model.vboId[2] = vboId[2]
  model.vboId[3] = vboId[3]
  model.vboId[4] = vboId[4]
  model.vboId[5] = vboId[5]
  model.vboId[6] = vboId[6]
  model.vboId[7] = vboId[7]
  
  
  
  model.vaoId = vaoId

proc zglDrawModel*(model: Model) =
  let matView = modelView
  let matProjection = projection

  #var transform = matrixIdentity()
  # var transform = matrixRotate(Vector3(x: 1, y: 0, z: 0), 90)
  # transform = matrixMultiply(transform, matrixScale(0.05, 0.05, 0.05))
  # var transform = matrixIdentity()
  # let matModelView = matrixMultiply(transform, matView)
  var transform = mat4f()
  let matModelView = transform * matView

  glBindVertexArray(model.vaoId)

  modelView = matModelView
  # let matMVP = matrixMultiply(modelview, projection)
  let matMVP = transpose(modelView * projection)
  var matMVPFloatArray = matrixToFloat(matMVP)

  for meshEntry in model.meshEntries:
    let material = model.materials[meshEntry.materialIndex]
    let materialShader = material.shader

    glUseProgram(materialShader.id)

    glUniform4f(material.shader.colDiffuseLoc, float material.colDiffuse.r/255, float material.colDiffuse.g/255, float material.colDiffuse.b/255, float material.colDiffuse.a/255)

    if material.shader.colAmbientLoc != -1:
      glUniform4f(material.shader.colAmbientLoc, float material.colAmbient.r/255, float material.colAmbient.g/255, float material.colAmbient.b/255, float material.colAmbient.a/255)
    
    if material.shader.colSpecularLoc != -1:
      glUniform4f(material.shader.colSpecularLoc, float material.colSpecular.r/255, float material.colSpecular.g/255, float material.colSpecular.b/255, float material.colSpecular.a/255)

    if material.shader.id != defaultShader.id:
      let modelMatrixLoc = glGetUniformLocation(material.shader.id, "modelMatrix")

      if modelMatrixLoc != -1:
        var transInvTransform  = inverse(transpose(transform))
        # matrixTranspose(transInvTransform)
        # matrixInvert(transInvTransform)


        var transInvTransformFloatArray = matrixToFloat(transInvTransform)
        glUniformMatrix4fv(modelMatrixLoc, 1, false, addr transInvTransformFloatArray[0])

      let viewDirLoc = glGetUniformLocation(material.shader.id, "viewDir")
      if viewDirLoc != -1:
        glUniform3f(viewDirLoc, matView[2][0], matView[2][1], matView[2][2])
      
      let glossinessLoc = glGetUniformLocation(material.shader.id, "glossiness")
      if glossinessLoc != -1:
        glUniform1f(glossinessLoc, material.glossiness)

    glUniformMatrix4fv(materialShader.mvpLoc, 1, false, addr matMVPFloatArray[0])

    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, material.texDiffuse.id)
    glUniform1i(materialShader.mapTexture0Loc, 0)

    if material.texNormal.id != 0 and material.shader.mapTexture1Loc != -1:
      glUniform1i(glGetUniformLocation(material.shader.id, "useNormal"), 1)

      glActiveTexture(GL_TEXTURE1)
      glBindTexture(GL_TEXTURE_2D, material.texNormal.id)
      glUniform1i(material.shader.mapTexture1Loc, 1)

    if material.texSpecular.id != 0 and material.shader.mapTexture2Loc != -1:
      glUniform1i(glGetUniformLocation(material.shader.id, "useSpecular"), 1)
    
      glActiveTexture(GL_TEXTURE2)
      glBindTexture(GL_TEXTURE_2D, material.texSpecular.id)
      glUniform1i(material.shader.mapTexture2Loc, 2)

    if model.indices != nil:
      glDrawElementsBaseVertex(GL_TRIANGLES, meshEntry.indexCount, GL_UNSIGNED_SHORT, cast[pointer](sizeof(GLushort) * int meshEntry.baseIndex), meshEntry.baseVertex)


  glActiveTexture(GL_TEXTURE0)
  glBindTexture(GL_TEXTURE_2D, 0)

  glBindVertexArray(0)

  glUseProgram(0)

  projection = matProjection
  modelview = matView

proc zglDrawModel*(model: Model, transforms: var seq[Mat4f]) =
  let matView = modelView
  let matProjection = projection

  # var transform = matrixIdentity()
  # var transform = matrixScale(0.05, 0.05, 0.05)
  # let matModelView = matrixMultiply(transform, matView)
  var transform = scale(mat4f(), vec3f(0.5, 0.5, 0.5))
  let matModelView = transform * matView

  glBindVertexArray(model.vaoId)

  modelView = matModelView
  # let matMVP = matrixMultiply(modelview, projection)
  let matMVP = transpose(modelView * projection)
  var matMVPFloatArray = matrixToFloat(matMVP)

  for meshEntry in model.meshEntries:
    let material = model.materials[meshEntry.materialIndex]
    let materialShader = material.shader

    glUseProgram(materialShader.id)

    for i in 0..<transforms.len:
      glUniformMatrix4fv(GLint(glGetUniformLocation(materialShader.id, "gBones[" & $i & "]")), 1, true, transforms[i].caddr)

    glUniform4f(material.shader.colDiffuseLoc, float material.colDiffuse.r/255, float material.colDiffuse.g/255, float material.colDiffuse.b/255, float material.colDiffuse.a/255)

    if material.shader.colAmbientLoc != -1:
      glUniform4f(material.shader.colAmbientLoc, float material.colAmbient.r/255, float material.colAmbient.g/255, float material.colAmbient.b/255, float material.colAmbient.a/255)
    
    if material.shader.colSpecularLoc != -1:
      glUniform4f(material.shader.colSpecularLoc, float material.colSpecular.r/255, float material.colSpecular.g/255, float material.colSpecular.b/255, float material.colSpecular.a/255)

    if material.shader.id != defaultShader.id:
      let modelMatrixLoc = glGetUniformLocation(material.shader.id, "modelMatrix")

      if modelMatrixLoc != -1:
        var transInvTransform  = transform
        # matrixTranspose(transInvTransform)
        # matrixInvert(transInvTransform)
        transInvTransform = inverse(transpose(transInvTransform))

        var transInvTransformFloatArray = matrixToFloat(transInvTransform)
        glUniformMatrix4fv(modelMatrixLoc, 1, false, addr transInvTransformFloatArray[0])

      let viewDirLoc = glGetUniformLocation(material.shader.id, "viewDir")
      if viewDirLoc != -1:
        glUniform3f(viewDirLoc, matView[2][0], matView[2][1], matView[2][2])
      
      let glossinessLoc = glGetUniformLocation(material.shader.id, "glossiness")
      if glossinessLoc != -1:
        glUniform1f(glossinessLoc, material.glossiness)

    glUniformMatrix4fv(materialShader.mvpLoc, 1, false, addr matMVPFloatArray[0])

    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, material.texDiffuse.id)
    glUniform1i(materialShader.mapTexture0Loc, 0)

    if material.texNormal.id != 0 and material.shader.mapTexture1Loc != -1:
      glUniform1i(glGetUniformLocation(material.shader.id, "useNormal"), 1)

      glActiveTexture(GL_TEXTURE1)
      glBindTexture(GL_TEXTURE_2D, material.texNormal.id)
      glUniform1i(material.shader.mapTexture1Loc, 1)

    if material.texSpecular.id != 0 and material.shader.mapTexture2Loc != -1:
      glUniform1i(glGetUniformLocation(material.shader.id, "useSpecular"), 1)
    
      glActiveTexture(GL_TEXTURE2)
      glBindTexture(GL_TEXTURE_2D, material.texSpecular.id)
      glUniform1i(material.shader.mapTexture2Loc, 2)

    if model.indices != nil:
      glDrawElementsBaseVertex(GL_TRIANGLES, meshEntry.indexCount, GL_UNSIGNED_SHORT, cast[pointer](sizeof(GLushort) * int meshEntry.baseIndex), meshEntry.baseVertex)


  glActiveTexture(GL_TEXTURE0)
  glBindTexture(GL_TEXTURE_2D, 0)

  glBindVertexArray(0)

  glUseProgram(0)

  projection = matProjection
  modelview = matView

proc setShaderValuei*(shader: Shader, uniformLoc: GLint, data: openarray[GLint], size: int) =
  glUseProgram(shader.id)
  case size
  of 1:
    glUniform1iv(uniformLoc, GLsizei(1), unsafeAddr data[0])
  of 2:
    glUniform2iv(uniformLoc, GLsizei(1), unsafeAddr data[0])
  of 3:
    glUniform3iv(uniformLoc, GLsizei(1), unsafeAddr data[0])
  of 4:
    glUniform4iv(uniformLoc, GLsizei(1), unsafeAddr data[0])
  else:
    warn("Shader value int array size not supported")

proc setShaderValue*(shader: Shader, uniformLoc: GLint, data: openarray[GLfloat], size: int) =
  glUseProgram(shader.id)
  case size
  of 1:
    glUniform1fv(uniformLoc, GLsizei(1), unsafeAddr data[0])
  of 2:
    glUniform2fv(uniformLoc, GLsizei(1), unsafeAddr data[0])
  of 3:
    glUniform3fv(uniformLoc, GLsizei(1), unsafeAddr data[0])
  of 4:
    glUniform4fv(uniformLoc, GLsizei(1), unsafeAddr data[0])
  else:
    warn("Shader value float array size not supported")

proc zglLoadRenderTexture*(width, height: int): RenderTexture2D =
  result.texture.data = sdl2.createRGBSurface(0, width, height, 32, 0, 0, 0, 0)
  result.depth.data = sdl2.createRGBSurface(0, width, height, 32, 0, 0, 0, 0)

  glGenTextures(1, addr result.texture.id)
  glBindTexture(GL_TEXTURE_2D, result.texture.id)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA.ord, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil)
  glBindTexture(GL_TEXTURE_2D, 0)

  glGenTextures(1, addr result.depth.id)
  glBindTexture(GL_TEXTURE_2D, result.depth.id)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
  glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT24.ord, width, height, 0, GL_DEPTH_COMPONENT, GL_UNSIGNED_INT, nil)
  glBindTexture(GL_TEXTURE_2D, 0)

  glGenFramebuffers(1, addr result.id)
  glBindFramebuffer(GL_FRAMEBUFFER, result.id)

  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, result.texture.id, 0)
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D, result.depth.id, 0)

  assert glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE

  glBindFramebuffer(GL_FRAMEBUFFER, 0)

proc zglEnableRenderTexture*(id: GLuint) =
  glBindFramebuffer(GL_FRAMEBUFFER, id)

proc zglDisableRenderTexture*() =
  glBindFramebuffer(GL_FRAMEBUFFER, 0)

proc beginShaderMode*(shader: Shader) = 
  if currentShader.id != shader.id:
    zglDraw()
    currentShader = shader

proc endShaderMode*() =
  beginShaderMode(getDefaultShader())
