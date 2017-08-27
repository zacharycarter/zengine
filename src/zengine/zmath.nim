import math, assimp, glm

type
  Vector2* = object
    x*, y*: float32
  
  Vector3* = object
    x*, y*, z*: float32

  Matrix* = object
    m0*, m4*, m8*, m12*: float32
    m1*, m5*, m9*, m13*: float32
    m2*, m6*, m10*, m14*: float32
    m3*, m7*, m11*, m15*: float32

converter toMat4f*(m: Matrix): Mat4f =
  result[0][0] = m.m0
  result[0][1] = m.m1
  result[0][2] = m.m2
  result[0][3] = m.m3
  result[1][0] = m.m4
  result[1][1] = m.m5
  result[1][2] = m.m6
  result[1][3] = m.m7
  result[2][0] = m.m8
  result[2][1] = m.m9
  result[2][2] = m.m10
  result[2][3] = m.m11
  result[3][0] = m.m12
  result[3][1] = m.m13
  result[3][2] = m.m14
  result[3][3] = m.m15

converter toMatrix*(m: Mat4f): Matrix =
  result.m0 = m[0][0]
  result.m1 = m[0][1]
  result.m2 = m[0][2]
  result.m3 = m[0][3]
  result.m4 = m[1][0]
  result.m5 = m[1][1]
  result.m6 = m[1][2]
  result.m7 = m[1][3]
  result.m8 = m[2][0]
  result.m9 = m[2][1]
  result.m10 = m[2][2]
  result.m11 = m[2][3]
  result.m12 = m[3][0]
  result.m13 = m[3][1]
  result.m14 = m[3][2]
  result.m15 = m[3][3]

proc clamp*(value, min, max: float32): float32 =
  let res = if value < min: min else: value
  return if res > max: max else: res

proc vector2Zero*(): Vector2 =
  result = Vector2(x: 0, y: 0)

proc vector2One*(): Vector2 =
  result = Vector2(x: 1.0, y: 1.0)

proc vector2Add*(v1, v2: Vector2): Vector2 =
  result = Vector2(x: v1.x - v2.x, y: v1.y - v2.y)

proc vector2Length*(v: Vector2): float32 =
  result = sqrt((v.x*v.x) + (v.y*v.y))

proc vector2DotProduct*(v1, v2: Vector2): float32 =
  result = (v1.x*v2.x + v1.y*v2.y)

proc vector2Distance*(v1, v2: Vector2): float32 =
  result = sqrt((v1.x - v2.x)*(v1.x - v2.x) + (v1.y - v2.y)*(v1.y - v2.y))

proc vector2Angle*(v1, v2: Vector2): float32 =
  result = arctan2(v2.y - v1.y, v2.x - v1.x)*(180.0/PI)

  if result < 0: result += 360.0

proc vector2Scale*(v: var Vector2, scale: float32) =
  v.x *= scale
  v.y *= scale

proc vector2Negate*(v: var Vector2) =
  v.x = -v.x
  v.y = -v.y

proc vector2Divide*(v: var Vector2, divisor: float32) =
  v = Vector2(x: v.x/divisor, y: v.y/divisor)

proc vector2Normalize*(v: var Vector2) =
  vector2Divide(v, vector2Length(v))

proc vectorZero*(): Vector3 =
  result = Vector3(x: 0.0, y: 0.0, z: 0.0)

proc vectorOne*(): Vector3 =
  result = Vector3(x: 1.0, y: 1.0, z: 1.0)

proc vectorAdd*(v1, v2: Vector3): Vector3 =
  result = Vector3(x: v1.x + v2.x, y: v1.y + v2.y, z: v1.z + v2.z)

proc vectorSubtract*(v1, v2: Vector3): Vector3 =
  result = Vector3(x: v1.x - v2.x, y: v1.y - v2.y, z: v1.z - v2.z)

proc vectorCrossProduct*(v1, v2: Vector3): Vector3 =
  result.x = v1.y*v2.z - v1.z*v2.y
  result.y = v1.z*v2.x - v1.x*v2.z
  result.z = v1.x*v2.y - v1.y*v2.x

proc vectorPerpendicular(v: Vector3): Vector3 =
  var min = abs(v.x)
  var cardinalAxis = Vector3(x:1.0, y:0.0, z:0.0)
  
  if abs(v.y) < min:
    min = abs(v.y)
    cardinalAxis = Vector3(x:0.0, y:1.0, z:0.0)
  if abs(v.z) < min:
    min = abs(v.z)
    cardinalAxis = Vector3(x:0.0, y:0.0, z:1.0)

  result = vectorCrossProduct(v, cardinalAxis)

proc vectorLength*(v: Vector3): float32 =
  result = sqrt(v.x*v.x + v.y*v.y + v.z*v.z)

proc vectorDotProduct*(v1, v2: Vector3): float32 =
  let dx = v2.x - v1.x
  let dy = v2.y - v1.y
  let dz = v2.z - v1.z

  return sqrt(dx*dx + dy*dy + dz*dz)

proc vectorScale*(v: var Vector3, scale: float32) =
  v.x *= scale
  v.y *= scale
  v.z *= scale

proc vectorNegate*(v: var Vector3) =
  v.x = -v.x
  v.y = -v.y
  v.z = -v.z

proc vectorNormalize*(v: var Vector3) =
  var length, iLength: float32

  length = vectorLength(v)
  
  if length == 0.0: length = 1.0

  iLength = 1.0 / length

  v.x *= iLength
  v.y *= iLength
  v.z *= iLength

proc vectorTransform*(v: var Vector3, mat: Matrix) =
  let x = v.x
  let y = v.y
  let z = v.z

  v.x = mat.m0*x + mat.m4*y + mat.m8*z + mat.m12
  v.y = mat.m1*x + mat.m5*y + mat.m9*z + mat.m13
  v.z = mat.m2*x + mat.m6*y + mat.m10*z + mat.m14

proc vectorLerp*(v1, v2: Vector3, amount: float32): Vector3 =
  result.x = v1.x + amount*(v2.x - v1.x)
  result.y = v1.y + amount*(v2.y - v1.y)
  result.z = v1.z + amount*(v2.z - v1.z)

proc vectorReflect*(v: Vector3, normal: Vector3): Vector3 =
  let dotProduct = vectorDotProduct(v, normal)

  result.x = v.x - (2.0f*normal.x)*dotProduct
  result.y = v.y - (2.0f*normal.y)*dotProduct
  result.z = v.z - (2.0f*normal.z)*dotProduct

proc vectorMin*(v1, v2: Vector3): Vector3 =
  result.x = min(v1.x, v2.x)
  result.y = min(v1.y, v2.y)
  result.z = min(v1.z, v2.z)

proc vectorMax*(v1, v2: Vector3): Vector3 =
  result.x = max(v1.x, v2.x)
  result.y = max(v1.y, v2.y)
  result.z = max(v1.z, v2.z)

converter toMatrix*(tMatrix4x4: TMatrix4x4): Matrix =
  result.m0 = tMatrix4x4[0]
  result.m1 = tMatrix4x4[1]
  result.m2 = tMatrix4x4[2]
  result.m3 = tMatrix4x4[3]
  result.m4 = tMatrix4x4[4]
  result.m5 = tMatrix4x4[5]
  result.m6 = tMatrix4x4[6]
  result.m7 = tMatrix4x4[7]
  result.m8 = tMatrix4x4[8]
  result.m9 = tMatrix4x4[9]
  result.m10 = tMatrix4x4[10]
  result.m11 = tMatrix4x4[11]
  result.m12 = tMatrix4x4[12]
  result.m13 = tMatrix4x4[13]
  result.m14 = tMatrix4x4[14]
  result.m15 = tMatrix4x4[15]

proc matrixIdentity*(): Matrix =
  result = Matrix(m0: 1.0, m1:0.0, m2:0.0, m3:0.0, 
                  m4:0.0, m5:1.0, m6:0.0, m7:0.0, 
                  m8:0.0, m9:0.0, m10:1.0, m11:0.0,
                  m12:0.0, m13:0.0, m14:0.0, m15:1.0)


proc matrixTranslate*(x, y, z: float32): Matrix =
  result = Matrix(m0:1.0, m1:0.0, m2:0.0, m3:0.0, 
                  m4:0.0, m5:1.0, m6:0.0, m7:0.0, 
                  m8:0.0, m9:0.0, m10:1.0, m11:0.0, 
                  m12:x, m13:y, m14:z, m15:1.0)


proc matrixMultiply*(left, right: Matrix): Matrix =
  result.m0 = right.m0*left.m0 + right.m1*left.m4 + right.m2*left.m8 + right.m3*left.m12
  result.m1 = right.m0*left.m1 + right.m1*left.m5 + right.m2*left.m9 + right.m3*left.m13
  result.m2 = right.m0*left.m2 + right.m1*left.m6 + right.m2*left.m10 + right.m3*left.m14
  result.m3 = right.m0*left.m3 + right.m1*left.m7 + right.m2*left.m11 + right.m3*left.m15
  result.m4 = right.m4*left.m0 + right.m5*left.m4 + right.m6*left.m8 + right.m7*left.m12
  result.m5 = right.m4*left.m1 + right.m5*left.m5 + right.m6*left.m9 + right.m7*left.m13
  result.m6 = right.m4*left.m2 + right.m5*left.m6 + right.m6*left.m10 + right.m7*left.m14
  result.m7 = right.m4*left.m3 + right.m5*left.m7 + right.m6*left.m11 + right.m7*left.m15
  result.m8 = right.m8*left.m0 + right.m9*left.m4 + right.m10*left.m8 + right.m11*left.m12
  result.m9 = right.m8*left.m1 + right.m9*left.m5 + right.m10*left.m9 + right.m11*left.m13
  result.m10 = right.m8*left.m2 + right.m9*left.m6 + right.m10*left.m10 + right.m11*left.m14
  result.m11 = right.m8*left.m3 + right.m9*left.m7 + right.m10*left.m11 + right.m11*left.m15
  result.m12 = right.m12*left.m0 + right.m13*left.m4 + right.m14*left.m8 + right.m15*left.m12
  result.m13 = right.m12*left.m1 + right.m13*left.m5 + right.m14*left.m9 + right.m15*left.m13
  result.m14 = right.m12*left.m2 + right.m13*left.m6 + right.m14*left.m10 + right.m15*left.m14
  result.m15 = right.m12*left.m3 + right.m13*left.m7 + right.m14*left.m11 + right.m15*left.m15

proc matrixOrtho*(left, right, bottom, top, near, far: float32): Matrix =
  let rl = (right - left)
  let tb = (top - bottom)
  let fn = (far - near)

  result.m0 = 2.0f/rl
  result.m1 = 0.0f
  result.m2 = 0.0f
  result.m3 = 0.0f
  result.m4 = 0.0f
  result.m5 = 2.0f/tb
  result.m6 = 0.0f
  result.m7 = 0.0f
  result.m8 = 0.0f
  result.m9 = 0.0f
  result.m10 = -2.0f/fn
  result.m11 = 0.0f
  result.m12 = -(left + right)/rl
  result.m13 = -(top + bottom)/tb
  result.m14 = -(far + near)/fn
  result.m15 = 1.0f

proc matrixLookAt*(eye, target, up: Vector3): Matrix =
  var z = vectorSubtract(eye, target)
  vectorNormalize(z)
  var x = vectorCrossProduct(up, z)
  vectorNormalize(x)
  var y = vectorCrossProduct(z, x)
  vectorNormalize(y)

  result.m0 = x.x
  result.m1 = x.y
  result.m2 = x.z
  result.m3 = -((x.x*eye.x) + (x.y*eye.y) + (x.z*eye.z))
  result.m4 = y.x
  result.m5 = y.y
  result.m6 = y.z
  result.m7 = -((y.x*eye.x) + (y.y*eye.y) + (y.z*eye.z))
  result.m8 = z.x
  result.m9 = z.y
  result.m10 = z.z
  result.m11 = -((z.x*eye.x) + (z.y*eye.y) + (z.z*eye.z))
  result.m12 = 0.0f
  result.m13 = 0.0f
  result.m14 = 0.0f
  result.m15 = 1.0f

proc matrixFrustum*(left, right, bottom, top, near, far: float32): Matrix =
  let rl = (right - left);
  let tb = (top - bottom);
  let fn = (far - near);

  result.m0 = (near*2.0f)/rl
  result.m1 = 0.0
  result.m2 = 0.0
  result.m3 = 0.0

  result.m4 = 0.0
  result.m5 = (near*2.0f)/tb
  result.m6 = 0.0
  result.m7 = 0.0

  result.m8 = (right + left)/rl
  result.m9 = (top + bottom)/tb
  result.m10 = -(far + near)/fn
  result.m11 = -1.0

  result.m12 = 0.0
  result.m13 = 0.0
  result.m14 = -(far*near*2.0f)/fn
  result.m15 = 0.0

proc matrixTranspose*(mat: var Matrix) =
  var temp: Matrix

  temp.m0 = mat.m0
  temp.m1 = mat.m4
  temp.m2 = mat.m8
  temp.m3 = mat.m12
  temp.m4 = mat.m1
  temp.m5 = mat.m5
  temp.m6 = mat.m9
  temp.m7 = mat.m13
  temp.m8 = mat.m2
  temp.m9 = mat.m6
  temp.m10 = mat.m10
  temp.m11 = mat.m14
  temp.m12 = mat.m3
  temp.m13 = mat.m7
  temp.m14 = mat.m11
  temp.m15 = mat.m15
  
  mat = temp

proc matrixRotate*(axis: Vector3, angle: float32): Matrix =
    let mat = matrixIdentity();

    var x = axis.x
    var y = axis.y
    var z = axis.z

    var length = sqrt(x*x + y*y + z*z);

    if length != 1.0 and length != 0.0:
      length = 1.0/length
      x *= length
      y *= length
      z *= length

    let sinres = sin(angle);
    let cosres = cos(angle);
    let t = 1.0f - cosres;

    let 
      a00 = mat.m0
      a01 = mat.m1
      a02 = mat.m2
      a03 = mat.m3

    let 
      a10 = mat.m4
      a11 = mat.m5
      a12 = mat.m6
      a13 = mat.m7
    
    let 
      a20 = mat.m8
      a21 = mat.m9
      a22 = mat.m10
      a23 = mat.m11

    let 
      b00 = x*x*t + cosres
      b01 = y*x*t + z*sinres
      b02 = z*x*t - y*sinres
    
    let 
      b10 = x*y*t - z*sinres
      b11 = y*y*t + cosres
      b12 = z*y*t + x*sinres

    let 
      b20 = x*z*t + y*sinres
      b21 = y*z*t - x*sinres
      b22 = z*z*t + cosres

    result.m0 = a00*b00 + a10*b01 + a20*b02;
    result.m1 = a01*b00 + a11*b01 + a21*b02;
    result.m2 = a02*b00 + a12*b01 + a22*b02;
    result.m3 = a03*b00 + a13*b01 + a23*b02;
    result.m4 = a00*b10 + a10*b11 + a20*b12;
    result.m5 = a01*b10 + a11*b11 + a21*b12;
    result.m6 = a02*b10 + a12*b11 + a22*b12;
    result.m7 = a03*b10 + a13*b11 + a23*b12;
    result.m8 = a00*b20 + a10*b21 + a20*b22;
    result.m9 = a01*b20 + a11*b21 + a21*b22;
    result.m10 = a02*b20 + a12*b21 + a22*b22;
    result.m11 = a03*b20 + a13*b21 + a23*b22;
    result.m12 = mat.m12;
    result.m13 = mat.m13;
    result.m14 = mat.m14;
    result.m15 = mat.m15;

proc matrixScale*(x, y, z: float32): Matrix =
  result = Matrix(m0:x, m1:0.0, m2:0.0, m3:0.0, 
                  m4:0.0, m5:y, m6:0.0f, m7:0.0, 
                  m8:0.0, m9:0.0f, m10:z, m11:0.0, 
                  m12:0.0, m13:0.0, m14:0.0, m15:1.0)

proc matrixInvert*(mat: var Matrix) =
  let 
    a00 = mat.m0
    a01 = mat.m1
    a02 = mat.m2
    a03 = mat.m3
  
    a10 = mat.m4 
    a11 = mat.m5
    a12 = mat.m6
    a13 = mat.m7

    a20 = mat.m8
    a21 = mat.m9
    a22 = mat.m10
    a23 = mat.m11

    a30 = mat.m12
    a31 = mat.m13
    a32 = mat.m14
    a33 = mat.m15

  let 
    b00 = a00*a11 - a01*a10
    b01 = a00*a12 - a02*a10
    b02 = a00*a13 - a03*a10
    b03 = a01*a12 - a02*a11
    b04 = a01*a13 - a03*a11
    b05 = a02*a13 - a03*a12
    b06 = a20*a31 - a21*a30
    b07 = a20*a32 - a22*a30
    b08 = a20*a33 - a23*a30
    b09 = a21*a32 - a22*a31
    b10 = a21*a33 - a23*a31
    b11 = a22*a33 - a23*a32

  let invDet = 1.0f/(b00*b11 - b01*b10 + b02*b09 + b03*b08 - b04*b07 + b05*b06)

  mat.m0 = (a11*b11 - a12*b10 + a13*b09)*invDet
  mat.m1 = (-a01*b11 + a02*b10 - a03*b09)*invDet
  mat.m2 = (a31*b05 - a32*b04 + a33*b03)*invDet
  mat.m3 = (-a21*b05 + a22*b04 - a23*b03)*invDet
  mat.m4 = (-a10*b11 + a12*b08 - a13*b07)*invDet
  mat.m5 = (a00*b11 - a02*b08 + a03*b07)*invDet
  mat.m6 = (-a30*b05 + a32*b02 - a33*b01)*invDet
  mat.m7 = (a20*b05 - a22*b02 + a23*b01)*invDet
  mat.m8 = (a10*b10 - a11*b08 + a13*b06)*invDet
  mat.m9 = (-a00*b10 + a01*b08 - a03*b06)*invDet
  mat.m10 = (a30*b04 - a31*b02 + a33*b00)*invDet
  mat.m11 = (-a20*b04 + a21*b02 - a23*b00)*invDet
  mat.m12 = (-a10*b09 + a11*b07 - a12*b06)*invDet
  mat.m13 = (a00*b09 - a01*b07 + a02*b06)*invDet
  mat.m14 = (-a30*b03 + a31*b01 - a32*b00)*invDet
  mat.m15 = (a20*b03 - a21*b01 + a22*b00)*invDet

proc `*`*(v: Vector3, s: float32): Vector3 =
  result.x = v.x * s
  result.y = v.y * s
  result.z = v.z * s

proc `+`*(v1, v2: Vector3): Vector3 =
  result.x = (v1.x + v2.x)
  result.y = (v1.y + v2.y)
  result.z = (v1.z + v2.z)

proc mix*(v1,v2: Vector3; a: float32): Vector3 =
  v1 * (1 - a) + v2 * a
