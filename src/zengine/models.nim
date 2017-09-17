import logging, zgl, sdl2, os, strutils, assimp, opengl, texture, color, tables, glm, math, timer

converter toMat4f*(m: TMatrix4x4) : Mat4f = 
  mat4f(
    vec4f(m[0], m[1], m[2], m[3])
    , vec4f(m[4], m[5], m[6], m[7])
    , vec4f(m[8], m[9], m[10], m[11])
    , vec4f(m[12], m[13], m[14], m[15])
  )

const ASSIMP_LOAD_FLAGS = aiProcess_Triangulate or aiProcess_GenSmoothNormals or aiProcess_FlipUVs or aiProcess_JoinIdenticalVertices

proc offset*[A](some: ptr A; b: int): ptr A =
  result = cast[ptr A](cast[int](some) + (b * sizeof(A)))

proc drawCube*(position: Vec3f, rotation: tuple[angle: float, axisX, axisY, axisZ: float], width, height, length: float, color: ZColor) =
  let x, y, z = 0.0

  zglPushMatrix()
  
  zglTranslatef(position.x, position.y, position.z)
  zglRotatef(rotation.angle, rotation.axisX, rotation.axisY, rotation.axisZ)

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

proc drawCubeWires*(position: Vec3f, width, height, length: float, color: ZColor) =
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

proc drawPlane*(centerPos: Vec3f, size: Vec2f, color: ZColor) =
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

proc drawCircle3d*(center: Vec3f, radius: float, rotationAxis: Vec3f, rotationAngle: float, color: ZColor) =
  zglPushMatrix()
  zglTranslatef(center.x, center.y, center.z)
  zglRotatef(rotationAngle, rotationAxis.x, rotationAxis.y, rotationAxis.z)

  zglBegin(DrawMode.ZGLLines)
  var i = 0.0
  while i < 360.0:
    zglColor4ub(color.r, color.g, color.b, color.a)

    zglVertex3f(sin(degToRad(i))*radius, cos(degToRad(i)*radius), 0.0)
    zglVertex3f(sin(degToRad(i + 10))*radius, cos(degToRad(i + 10)*radius), 0.0)
    i += 10.0
  zglEnd()
  zglPopMatrix()

proc drawSphereWires*(centerPos: Vec3f, radius: float, rings: int, slices: int, color: ZColor) =
  zglPushMatrix()
  zglTranslatef(centerPos.x, centerPos.y, centerPos.z)
  zglScalef(radius, radius, radius)

  zglBegin(DrawMode.ZGLLines)
  zglColor4ub(color.r, color.g, color.b, color.a)

  for i in 0..<rings + 2:
    for j in 0..<slices:
      zglVertex3f(
        cos(degToRad(270+(180/(rings + 1))*i.float)) * sin(degToRad(j*360/slices)),
        sin(degToRad(270+(180/(rings + 1))*i.float)),
        cos(degToRad(270+(180/(rings + 1))*i.float)) * cos(degToRad(j*360/slices))
      )
      zglVertex3f(
        cos(degToRad(270+(180/(rings + 1))*(i+1).float)) * sin(degToRad((j+1)*360/slices)),
        sin(degToRad(270+(180/(rings + 1))*(i+1).float)),
        cos(degToRad(270+(180/(rings + 1))*(i+1).float)) * cos(degToRad((j+1)*360/slices))
      )

      zglVertex3f(
        cos(degToRad(270+(180/(rings + 1))*(i+1).float)) * sin(degToRad((j+1)*360/slices)),
        sin(degToRad(270+(180/(rings + 1))*(i+1).float)),
        cos(degToRad(270+(180/(rings + 1))*(i+1).float)) * cos(degToRad((j+1)*360/slices))
      )
      zglVertex3f(
        cos(degToRad(270+(180/(rings + 1))*(i+1).float)) * sin(degToRad(j*360/slices)),
        sin(degToRad(270+(180/(rings + 1))*(i+1).float)),
        cos(degToRad(270+(180/(rings + 1))*(i+1).float)) * cos(degToRad(j*360/slices))
      )

      zglVertex3f(
        cos(degToRad(270+(180/(rings + 1))*i.float)) * sin(degToRad(j*360/slices)),
        sin(degToRad(270+(180/(rings + 1))*i.float)),
        cos(degToRad(270+(180/(rings + 1))*i.float)) * cos(degToRad(j*360/slices))
      )
      zglVertex3f(
        cos(degToRad(270+(180/(rings + 1))*i.float)) * sin(degToRad(j*360/slices)),
        sin(degToRad(270+(180/(rings + 1))*i.float)),
        cos(degToRad(270+(180/(rings + 1))*i.float)) * cos(degToRad(j*360/slices))
      )

  zglEnd()
  zglPopMatrix()


proc init(material: var Material, some: PMaterial, filename: string, shader: Shader) =
  var path : AIString
  if getTexture(some, TexDiffuse, 0, addr path) == ReturnSuccess:
    let filename = getCurrentDir() & DirSep & splitPath(filename).head & DirSep & $path
    
    try:
      material.texDiffuse = loadTexture(filename)
    except:
      error "Failed to load diffuse texture for material with filename: " % filename
  else:
    material.texDiffuse = getDefaultTexture()

  if getTexture(some, TexNormals, 0, addr path) == ReturnSuccess:
    let filename = getCurrentDir() & DirSep & splitPath(filename).head & DirSep & $path
    
    try:
      material.texNormal = loadTexture(filename)
    except:
      error "Failed to load normal texture for material with filename: " % filename
  
  if getTexture(some, TexSpecular, 0, addr path) == ReturnSuccess:
    let filename = getCurrentDir() & DirSep & splitPath(filename).head & DirSep & $path
    
    try:
      material.texSpecular = loadTexture(filename)
    except:
      error "Failed to load specular texture for material with filename: " % filename
  
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

proc findNodeAnim(animation: PAnimation, nodeName: string) : PNodeAnim =
  for i in 0..<animation.channelCount:
    let anim = animation.channels.offset(i)[]

    if $anim.nodeName.data == nodeName:
      return anim
  return nil

proc findScaling(animationTime: float, nodeAnim: PNodeAnim) : int =
  for i in 0..<nodeAnim.scalingKeyCount - 1:
    if animationTime < nodeAnim.scalingKeys.offset(i + 1).time:
      return i
  
  assert false
  return 0

proc calcInterpolatedScaling(scaling: var Vec3f, animationTime: float, nodeAnim: PNodeAnim) =
  if nodeAnim.scalingKeyCount == 1:
    let value = nodeAnim.scalingKeys.offset(0)[].value
    scaling = vec3f(value.x, value.y, value.z)
    return
  
  let scalingIndex = findScaling(animationTime, nodeAnim)
  let nextScalingIndex = scalingIndex + 1
  let deltaTime = nodeAnim.scalingKeys.offset(nextScalingIndex)[].time - nodeAnim.scalingKeys.offset(scalingIndex).time
  let factor = (animationTime - nodeAnim.scalingKeys.offset(scalingIndex)[].time) / deltaTime
  let start = nodeAnim.scalingKeys.offset(scalingIndex)[].value
  let `end` = nodeAnim.scalingKeys.offset(nextScalingIndex)[].value
  scaling = mix(vec3f(start.x, start.y, start.z), vec3f(`end`.x, `end`.y, `end`.z), factor)

proc findRotation(animationTime: float, nodeAnim: PNodeAnim) : int =
  for i in 0..<nodeAnim.rotationKeyCount - 1:
    if animationTime < nodeAnim.rotationKeys.offset(i + 1)[].time:
      return i
  
  assert false
  return 0


proc calcInterpolatedRotation(rotation: var Quatf, animationTime: float, nodeAnim: PNodeAnim) =
  if nodeAnim.rotationKeyCount == 1:
    let value = nodeAnim.rotationKeys.offset(0)[].value
    rotation = quatf(value.x, value.y, value.z, value.w)
    return

  let rotationIndex = findRotation(animationTime, nodeAnim)
  let nextRotationIndex = rotationIndex + 1
  let deltaTime = nodeAnim.rotationKeys.offset(nextRotationIndex)[].time - nodeAnim.rotationKeys.offset(rotationIndex).time
  let factor = (animationTime - nodeAnim.rotationKeys.offset(rotationIndex).time) / deltaTime
  let startRotationQ = nodeAnim.rotationKeys.offset(rotationIndex)[].value
  let endRotationQ = nodeAnim.rotationKeys.offset(nextRotationIndex)[].value
  rotation = slerp(
    quatf(startRotationQ.x, startRotationQ.y, startRotationQ.z, startRotationQ.w), 
    quatf(endRotationQ.x, endRotationQ.y, endRotationQ.z, endRotationQ.w), factor)

proc findPosition(animationTime: float, nodeAnim: PNodeAnim) : int =
  for i in 0..<nodeAnim.positionKeyCount - 1:
    if animationTime < nodeAnim.positionKeys.offset(i + 1)[].time:
      return i

  assert false
  return 0

proc calcInterpolatedPosition(translation: var Vec3f, animationTime: float, nodeAnim: PNodeAnim) =
  if nodeAnim.positionKeyCount == 1:
    let value = nodeAnim.positionKeys.offset(0)[].value
    translation = vec3f(value.x, value.y, value.z)
    return
  
  let positionIndex = findPosition(animationTime, nodeAnim)
  let nextPositionIndex = positionIndex + 1
  let deltaTime = nodeAnim.positionKeys.offset(nextPositionIndex)[].time - nodeAnim.positionKeys.offset(positionIndex)[].time
  let factor = (animationTime - nodeAnim.positionKeys.offset(positionIndex)[].time) / deltaTime
  let start = nodeAnim.positionKeys.offset(positionIndex).value
  let `end` = nodeAnim.positionKeys.offset(nextPositionIndex).value
  translation = mix(vec3f(start.x, start.y, start.z), vec3f(`end`.x, `end`.y, `end`.z), factor)


proc readNodeHierarchy(model: var Model, animationTime: float, node: PNode, parentTransform: Mat4f) =
  let nodeName = $node.name.data
  let animation = model.scene.animations[0]
  var nodeTransformation = toMat4f(node.transformation)
  let nodeAnim = findNodeAnim(animation, nodeName)

  if not nodeAnim.isNil:
    var rotation : Quatf
    calcInterpolatedRotation(rotation, animationTime, nodeAnim)

    var scaling : Vec3f
    calcInterpolatedScaling(scaling, animationTime, nodeAnim)

    var translation : Vec3f
    calcInterpolatedPosition(translation, animationTime, nodeAnim)
    
    nodeTransformation = inverse(mat4(rotation, vec4f(0,0,0,1)))
    
    nodeTransformation[0][0] *= scaling.x
    nodeTransformation[0][1] *= scaling.y
    nodeTransformation[0][2] *= scaling.z
    nodeTransformation[0][3] = translation.x

    nodeTransformation[1][0] *= scaling.x
    nodeTransformation[1][1] *= scaling.y
    nodeTransformation[1][2] *= scaling.z
    nodeTransformation[1][3] = translation.y

    nodeTransformation[2][0] *= scaling.x
    nodeTransformation[2][1] *= scaling.y
    nodeTransformation[2][2] *= scaling.z
    nodeTransformation[2][3] = translation.z

  var globalTransformation = nodeTransformation * parentTransform

  if model.boneMapping.contains(nodeName):
    var boneIndex = model.boneMapping[nodeName]
    model.boneInfos[int boneIndex].finalTransformation = model.boneInfos[int boneIndex].boneOffset  * globalTransformation * model.globalInverseTransform 
  
  for i in 0..<node.childrenCount:
    readNodeHierarchy(model, animationTime, node.children[i], globalTransformation)

proc boneTransform*(model: var Model, timeInSeconds: float, transforms: var seq[Mat4f]) =
  var ticksPerSecond : float
  if model.scene.animations[0].ticksPerSec != 0:
    ticksPerSecond = model.scene.animations[0].ticksPerSec
  else:
    ticksPerSecond = 25.0
  
  var timeInTicks = timeInSeconds * ticksPerSecond
  var animationTime = fmod(timeInTicks,  float(model.scene.animations[0].duration))

  readNodeHierarchy(model, animationTime, model.scene.rootNode, mat4f())

  transforms = newSeq[Mat4f](model.numBones)

  for i in 0..<model.numBones:
    transforms[int i] = model.boneInfos[int i].finalTransformation

proc addBoneData(bone: var Bone, boneIndex: int, weight: float) =
  for i in 0..<4:
    if bone.weights[i] == 0.0:
      bone.ids[i] = GLint boneIndex
      bone.weights[i] = weight
      return
  
  # assert(false)

proc initBones*(index: int, model: var Model, mesh: PMesh) =
  for i in 0..<mesh.boneCount:
    var boneIndex = 0
    let boneName = $mesh.bones[i].name.data
    if not model.boneMapping.contains(boneName):
      boneIndex = int model.numBones
      inc(model.numBones)
      var bi : BoneInfo
      model.boneInfos.add(bi)
      model.boneInfos[int boneIndex].boneOffset = toMat4f(mesh.bones[i].offsetMatrix)
      model.boneMapping.add(boneName, boneIndex)
    else:
      boneIndex = model.boneMapping[boneName]

    for j in 0..<mesh.bones[i].numWeights:
      let vertexId = model.meshEntries[index].baseVertex + mesh.bones[i].weights[j].vertexID
      let weight = mesh.bones[i].weights[j].weight
      model.bones[vertexId].addBoneData(boneIndex, weight)

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

  if model.scene.animationCount > 0:
    initBones(index, model, mesh)

  if mesh.hasFaces():
    for f in 0..<mesh.faceCount:
      model.indices.add(GLushort mesh.faces[f].indices[0])
      model.indices.add(GLushort mesh.faces[f].indices[1])
      model.indices.add(GLushort mesh.faces[f].indices[2])
      inc(model.triangleCount)

proc init(model: var Model, scene: PScene, filename: string, shader: Shader) =
  model.scene = scene
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
  
  model.scene = scene

  if model.scene.animationCount > 0:
    model.bones = newSeq[Bone](numVertices)
    model.boneInfos = @[]
    model.boneMapping = initTable[string, int]()
  
  model.globalInverseTransform = inverse(toMat4f(scene.rootNode.transformation))

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

proc drawModel*(model: var Model, tint: ZColor, time: float64) =
  var transforms : seq[Mat4f] = @[]
  if model.scene.animationCount > 0:
    boneTransform(model, time * 0.001, transforms)
    zglDrawModel(model, transforms)
  else:
    zglDrawModel(model)