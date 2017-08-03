import logging, zgl, zmath, sdl2, os, strutils, assimp, opengl, texture, color

const ASSIMP_LOAD_FLAGS = aiProcess_Triangulate or aiProcess_GenSmoothNormals or aiProcess_FlipUVs or aiProcess_JoinIdenticalVertices

proc offset*[A](some: ptr A; b: int): ptr A =
  result = cast[ptr A](cast[int](some) + (b * sizeof(A)))

proc drawCube*(position: Vector3, width, height, length: float, color: ZColor) =
  let x, y, z = 0.0

  zglPushMatrix()
  
  zglTranslatef(position.x, position.y, position.z)
  #zglRotatef(sdl2.getTicks().float / 10.0, 0, 1, 0)

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

proc drawGrid*(slices: int, spacing: float) =
  let halfSlices = slices/2;

  zglBegin(DrawMode.ZGLLines)
  for i in -halfSlices..halfSlices.int:
    if i == 0:
      zglColor3f(1.0, 1.0, 1.0)
      zglColor3f(1.0, 1.0, 1.0)
      zglColor3f(1.0, 1.0, 1.0)
      zglColor3f(1.0, 1.0, 1.0)
    else:
      zglColor3f(0.5, 0.5, 0.5)
      zglColor3f(0.5, 0.5, 0.5)
      zglColor3f(0.5, 0.5, 0.5)
      zglColor3f(0.5, 0.5, 0.5)
    
    zglVertex3f(i.float*spacing, 0.0f, -halfSlices*spacing)
    zglVertex3f(i.float*spacing, 0.0f, halfSlices*spacing)

    zglVertex3f(-halfSlices*spacing, 0.0f, i.float*spacing)
    zglVertex3f(halfSlices*spacing, 0.0f, i.float*spacing)
    
    zglEnd()

proc drawCubeWires*(position: Vector3, width, height, length: float, color: ZColor) =
  let x = 0.0
  let y = 0.0
  let z = 0.0

  zglPushMatrix()

  zglTranslatef(position.x, position.y, position.z)
  # zglRotatef(sdl2.getTicks().float / 10.0, 0, 1, 0)

  zglBegin(DrawMode.ZGLLines)
  zglColor4ub(color.r, color.g, color.b, color.a)

  # Front Face -----------------------------------------------------
  # Bottom Line
  zglVertex3f(x-width/2, y-height/2, z+length/2);  # Bottom Left
  zglVertex3f(x+width/2, y-height/2, z+length/2);  # Bottom Right

  # Left Line
  zglVertex3f(x+width/2, y-height/2, z+length/2);  # Bottom Right
  zglVertex3f(x+width/2, y+height/2, z+length/2);  # Top Right

  # Top Line
  zglVertex3f(x+width/2, y+height/2, z+length/2);  # Top Right
  zglVertex3f(x-width/2, y+height/2, z+length/2);  # Top Left

  # Right Line
  zglVertex3f(x-width/2, y+height/2, z+length/2);  # Top Left
  zglVertex3f(x-width/2, y-height/2, z+length/2);  # Bottom Left

  # Back Face ------------------------------------------------------
  # Bottom Line
  zglVertex3f(x-width/2, y-height/2, z-length/2);  # Bottom Left
  zglVertex3f(x+width/2, y-height/2, z-length/2);  # Bottom Right

  # Left Line
  zglVertex3f(x+width/2, y-height/2, z-length/2);  # Bottom Right
  zglVertex3f(x+width/2, y+height/2, z-length/2);  # Top Right

  # Top Line
  zglVertex3f(x+width/2, y+height/2, z-length/2);  # Top Right
  zglVertex3f(x-width/2, y+height/2, z-length/2);  # Top Left

  # Right Line
  zglVertex3f(x-width/2, y+height/2, z-length/2);  # Top Left
  zglVertex3f(x-width/2, y-height/2, z-length/2);  # Bottom Left

  # Top Face -------------------------------------------------------
  # Left Line
  zglVertex3f(x-width/2, y+height/2, z+length/2);  # Top Left Front
  zglVertex3f(x-width/2, y+height/2, z-length/2);  # Top Left Back

  # Right Line
  zglVertex3f(x+width/2, y+height/2, z+length/2);  # Top Right Front
  zglVertex3f(x+width/2, y+height/2, z-length/2);  # Top Right Back

  # Bottom Face  ---------------------------------------------------
  # Left Line
  zglVertex3f(x-width/2, y-height/2, z+length/2);  # Top Left Front
  zglVertex3f(x-width/2, y-height/2, z-length/2);  # Top Left Back

  # Right Line
  zglVertex3f(x+width/2, y-height/2, z+length/2);  # Top Right Front
  zglVertex3f(x+width/2, y-height/2, z-length/2);  # Top Right Back

  zglEnd()
  zglPopMatrix()

proc drawPlane*(centerPos: Vector3, size: Vector2, color: ZColor) =
  zglPushMatrix()
  zglTranslatef(centerPos.x, centerPos.y, centerPos.z)
  zglScalef(size.x, 1.0f, size.y)

  zglBegin(DrawMode.ZGLTriangles)
  zglColor4ub(color.r, color.g, color.b, color.a)
  zglNormal3f(0.0, 1.0, 0.0)

  zglVertex3f(0.5f, 0.0f, -0.5f)
  zglVertex3f(-0.5f, 0.0f, -0.5f)
  zglVertex3f(-0.5f, 0.0f, 0.5f)

  zglVertex3f(-0.5f, 0.0f, 0.5f)
  zglVertex3f(0.5f, 0.0f, 0.5f)
  zglVertex3f(0.5f, 0.0f, -0.5f)

  zglEnd()
  zglPopMatrix()

proc init(material: var Material, some: PMaterial, filename: string, shader: Shader) =
  var path : AIString
  if getTexture(some, TexDiffuse, 0, addr path) == ReturnSuccess:
    let filename = getCurrentDir() & DirSep & splitPath(filename).head & DirSep & $path
    
    material.texDiffuse = loadTexture(filename)

  if getTexture(some, TexNormals, 0, addr path) == ReturnSuccess:
   let filename = getCurrentDir() & DirSep & splitPath(filename).head & DirSep & $path
    
   material.texNormal = loadTexture(filename)
  
  if getTexture(some, TexSpecular, 0, addr path) == ReturnSuccess:
   let filename = getCurrentDir() & DirSep & splitPath(filename).head & DirSep & $path
    
   material.texSpecular = loadTexture(filename)
  
  material.shader = shader
  
  
  var color: TColor3d
  material.colDiffuse = WHITE
  if getMaterialColor(some, AI_MATKEY_COLOR_DIFFUSE, 0, 0, addr color) == ReturnSuccess:
   material.colDiffuse.r = int color.r * 255.0
   material.colDiffuse.g = int color.g * 255.0
   material.colDiffuse.b = int color.b * 255.0
    
  material.colAmbient = WHITE
  if getMaterialColor(some, AI_MATKEY_COLOR_AMBIENT, 0, 0, addr color) == ReturnSuccess:
   material.colAmbient.r = int color.r * 255.0
   material.colAmbient.g = int color.g * 255.0
   material.colAmbient.b = int color.b * 255.0

  material.colSpecular = WHITE
  if getMaterialColor(some, AI_MATKEY_COLOR_SPECULAR, 0, 0, addr color) == ReturnSuccess:
   material.colSpecular.r = int color.r * 255.0
   material.colSpecular.g = int color.g * 255.0
   material.colSpecular.b = int color.b * 255.0

  var shininess: cfloat 
  material.glossiness = 100.0
  if getMaterialFloatArray(some, AI_MATKEY_SHININESS, 0, 0, addr shininess, nil) == ReturnSuccess:
   material.glossiness = shininess

proc drawModel*(model: var Model, tint: ZColor) =
  zglDrawModel(model)

proc initMesh(model: var Model, index: int, mesh: PMesh) =
  for v in 0..<mesh.vertexCount:
    model.vertices.add(mesh.vertices.offset(v)[].x)
    model.vertices.add(mesh.vertices.offset(v)[].y)
    model.vertices.add(mesh.vertices.offset(v)[].z)
    inc(model.vertexCount)

  for tc in 0..<mesh.vertexCount:
    model.texCoords.add(mesh.texCoords[0].offset(tc)[].x)
    model.texCoords.add(mesh.texCoords[0].offset(tc)[].y)

  if mesh.hasNormals():
    for n in 0..<mesh.vertexCount:
      model.normals.add(mesh.normals.offset(n).x)
      model.normals.add(mesh.normals.offset(n).y)
      model.normals.add(mesh.normals.offset(n).z)

    for f in 0..<mesh.faceCount:
      model.indices.add(GLushort mesh.faces[f].indices[0])
      model.indices.add(GLushort mesh.faces[f].indices[1])
      model.indices.add(GLushort mesh.faces[f].indices[2])
      inc(model.triangleCount)

proc init(model: var Model, scene: PScene, filename: string, shader: Shader) =
  model.meshEntries = newSeq[MeshEntry](scene.meshCount)

  var 
    numVertices: GLint = 0
    numIndices: GLint = 0
  
  for m in 0..<scene.meshCount:
    model.meshEntries[m].materialIndex = scene.meshes[m].materialIndex
    model.meshEntries[m].indexCount = scene.meshes[m].faceCount * 3
    model.meshEntries[m].baseVertex = numVertices
    model.meshEntries[m].baseIndex = numIndices

    numVertices += scene.meshes[m].vertexCount
    numIndices += model.meshEntries[m].indexCount

  model.vertices = @[]
  model.texCoords = @[]
  model.normals = @[]
  model.indices = @[]
  model.materials = newSeq[Material](scene.materialCount)

  for m in 0..<scene.meshCount:
    initMesh(model, m, scene.meshes[m])

  for m in 0..<scene.materialCount:
    model.materials[m].init(
      scene.materials[m],
      filename,
      shader,
    )

  zglLoadModel(model, false)

proc loadModel*(filename: string, shader: Shader = getDefaultShader()): Model =
  let scene = aiImportFile(filename, ASSIMP_LOAD_FLAGS)

  if scene.isNil:
    warn("[$1] Model could not be loaded." % filename)
    return

  result.init(scene, filename, shader)
