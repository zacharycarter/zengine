import logging, zgl, zmath, sdl2, os, strutils, assimp, opengl, texture, color

# type
#   Model = object
#     meshes: seq[Mesh]
#     materials: seq[Material]

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


# proc init(mesh: var Mesh, some: PMesh) =
#   mesh.vertices = newSeq[GLfloat](some.vertexCount*3)
#   mesh.texCoords = newSeq[GLfloat](some.vertexCount*2)
  
#   if some.hasFaces():
#     mesh.indices = newSeq[GLushort](some.faceCount * 3)

#   if some.hasNormals():
#     mesh.normals = newSeq[GLfloat](some.vertexCount*3)

#   var vCounter = 0
#   for v in 0..<some.vertexCount:
#     mesh.vertices[vCounter] = some.vertices.offset(v)[].x
#     mesh.vertices[vCounter + 1] = some.vertices.offset(v)[].y
#     mesh.vertices[vCounter + 2] = some.vertices.offset(v)[].z
#     inc(mesh.vertexCount)
#     inc(vCounter, 3)

#   var tcCounter = 0
#   for tc in 0..<some.vertexCount:
#     mesh.texCoords[tcCounter] = some.texCoords[0].offset(tc)[].x
#     mesh.texCoords[tcCounter + 1] = some.texCoords[0].offset(tc)[].y
#     inc(tcCounter, 2)
  
#   if some.hasNormals():
#     var nCounter = 0
#     for n in 0..<some.vertexCount:
#       mesh.normals[nCounter] = some.normals.offset(n).x
#       mesh.normals[nCounter + 1] = some.normals.offset(n).y
#       mesh.normals[nCounter + 2] = some.normals.offset(n).z
#       inc(nCounter, 3)

#   if some.hasFaces():
#     var fCounter = 0
#     for f in 0..<some.faceCount:
#       mesh.indices[fCounter] = GLushort some.faces[f].indices[0]
#       mesh.indices[fCounter + 1] = GLushort some.faces[f].indices[1]
#       mesh.indices[fCounter + 2] = GLushort some.faces[f].indices[2]
#       inc(mesh.triangleCount)
#       inc(fCounter, 3)

#   zglLoadMesh(mesh, false)

#   mesh.materialIndex = some.materialIndex

# proc init(model: var Model, scene: PScene, filename: string, shader: Shader) =
#   model.meshes = newSeq[Mesh](scene.meshCount)
#   model.materials = newSeq[Material](scene.materialCount)

#   var m = 0
#   for mesh in model.meshes.mitems:
#     mesh.init(scene.meshes[m])
#     inc(m)

#   m = 0
#   for material in model.materials.mitems:
#     material.init(scene.materials[m], filename, shader)
#     inc(m)

# proc drawModel*(model: var Model, tint: ZColor) =
#   for mesh in model.meshes:
#     zglDrawMesh(mesh, model.materials[mesh.materialIndex])

# proc loadModel*(filename: string, shader: Shader = getDefaultShader()): Model =
#   let scene = aiImportFile(filename, ASSIMP_LOAD_FLAGS)
#   if scene.isNil:
#     warn("[$1] Mesh could not be loaded." % filename)
#     return
  
#   result.init(scene, filename, shader)

proc drawModel*(model: var Model, tint: ZColor) =
  zglDrawModel(model)

proc initMesh(model: var Model, index: int, mesh: PMesh) =
  var vCounter = 0
  for v in 0..<mesh.vertexCount:
    model.vertices[vCounter] = mesh.vertices.offset(v)[].x
    model.vertices[vCounter + 1] = mesh.vertices.offset(v)[].y
    model.vertices[vCounter + 2] = mesh.vertices.offset(v)[].z
    inc(model.vertexCount)
    inc(vCounter, 3)

  var tcCounter = 0
  for tc in 0..<mesh.vertexCount:
    model.texCoords[tcCounter] = mesh.texCoords[0].offset(tc)[].x
    model.texCoords[tcCounter + 1] = mesh.texCoords[0].offset(tc)[].y
    inc(tcCounter, 2)

  # if mesh.hasNormals():
  #   var nCounter = 0
  #   for n in 0..<mesh.vertexCount:
  #     model.normals[nCounter] = mesh.normals.offset(n).x
  #     model.normals[nCounter + 1] = mesh.normals.offset(n).y
  #     model.normals[nCounter + 2] = mesh.normals.offset(n).z
  #     inc(nCounter, 3)

  if mesh.hasFaces():
    var fCounter = 0
    for f in 0..<mesh.faceCount:
      model.indices[fCounter] = GLushort mesh.faces[f].indices[0]
      model.indices[fCounter + 1] = GLushort mesh.faces[f].indices[1]
      model.indices[fCounter + 2] = GLushort mesh.faces[f].indices[2]
      inc(model.triangleCount)
      inc(fCounter, 3)

proc init(model: var Model, scene: PScene, filename: string, shader: Shader) =
  model.meshEntries = newSeq[MeshEntry](scene.meshCount)

  var 
    numVertices = 0
    numIndices = 0
  
  for m in 0..<scene.meshCount:
    model.meshEntries[m].materialIndex = scene.meshes[m].materialIndex
    model.meshEntries[m].indexCount = scene.meshes[m].faceCount * 3
    model.meshEntries[m].baseVertex = numVertices
    model.meshEntries[m].baseIndex = numIndices

    numVertices += scene.meshes[m].vertexCount
    numIndices += model.meshEntries[m].indexCount

  model.vertices = newSeq[GLfloat](numVertices*3)
  model.texCoords = newSeq[GLfloat](numVertices*2)
  # model.normals = newSeq[GLfloat](numVertices*3)
  model.indices = newSeq[GLushort](numIndices)
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

