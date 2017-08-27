import zgl, math, glm, core, sdl2

type
  CameraMode* = enum
    Custom, Free, FirstPerson

  CameraMove* = enum
    Front, Back, Right, Left, Up, Down

const CAMERA_FREE_DISTANCE_MAX_CLAMP = 120.0
const CAMERA_FREE_MIN_CLAMP = 85.0
const CAMERA_FREE_MAX_CLAMP = -85.0
const CAMERA_FREE_DISTANCE_MIN_CLAMP = 1.5
const CAMERA_MOUSE_SCROLL_SENSITIVITY = 1.5
const CAMERA_FREE_MOUSE_SENSITIVITY = 0.01
const CAMERA_FREE_PANNING_DIVIDER = 5.1
const CAMERA_FIRST_PERSON_MIN_CLAMP = 85.0
const CAMERA_FIRST_PERSON_MAX_CLAMP = -85.0
const CAMERA_FIRST_PERSON_FOCUS_DISTANCE = 25.0
const CAMERA_FIRST_PERSON_STEP_TRIGONOMETRIC_DIVIDER = 5.0
const CAMERA_FIRST_PERSON_STEP_DIVIDER = 30.0
const CAMERA_FIRST_PERSON_WAVING_DIVIDER = 200.0

const PLAYER_MOVEMENT_SENSITIVITY = 20.0
const CAMERA_MOUSE_MOVE_SENSITIVITY = 0.003

var cameraTargetDistance = 0.0
var cameraAngle = vec2f(0)
var playerEyesPosition = 1.85
var cameraMode = CameraMode.Custom
var previousMousePosition: Vec2f
var swingCounter = 0

var cameraMoveControl = [sdl2.K_w, sdl2.K_s, sdl2.K_d, sdl2.K_a, sdl2.K_e, sdl2.K_q]

proc setMode*(camera: var Camera, mode: CameraMode) =
  let v1 = camera.position
  let v2 = camera.target

  let dx = v2.x - v1.x
  let dy = v2.y - v1.y
  let dz = v2.z - v1.z

  cameraTargetDistance= sqrt(dx*dx + dy*dy + dz*dz)

  var distance: Vec2f
  distance.x = sqrt(dx*dx + dz*dz)
  distance.y = sqrt(dx*dx + dy*dy)

  cameraAngle.x = arcsin(abs(dx)/distance.x)
  cameraAngle.y = -arcsin(abs(dy)/distance.y)

  playerEyesPosition = camera.position.y

  if mode == CameraMode.FirstPerson:
    disableCursor()

  cameraMode = mode

proc update*(camera: var Camera, mouseWheelMove: int, mouseXDelta, mouseYDelta: int) =
  var mousePositionDelta = vec2f(0)
  var mousePosition = getMousePosition()

  mousePositionDelta.x = mousePosition.x - previousMousePosition.x;
  mousePositionDelta.y = mousePosition.y - previousMousePosition.y;

  previousMousePosition = mousePosition;

  let direction = [
    isKeyDown(cameraMoveControl[Cameramove.Front.ord].cint),
    isKeyDown(cameraMoveControl[Cameramove.Back.ord].cint),
    isKeyDown(cameraMoveControl[Cameramove.Right.ord].cint),
    isKeyDown(cameraMoveControl[Cameramove.Left.ord].cint),
    isKeyDown(cameraMoveControl[Cameramove.Up.ord].cint),
    isKeyDown(cameraMoveControl[Cameramove.Down.ord].cint),
  ]

  case cameraMode
  of CameraMode.Free:
    if cameraTargetDistance < CAMERA_FREE_DISTANCE_MAX_CLAMP and mouseWheelMove < 0:
      cameraTargetDistance -= mouseWheelMove.float * CAMERA_MOUSE_SCROLL_SENSITIVITY

      if cameraTargetDistance > CAMERA_FREE_DISTANCE_MAX_CLAMP: cameraTargetDistance = CAMERA_FREE_DISTANCE_MAX_CLAMP
    
    elif camera.position.y > camera.target.y and cameraTargetDistance == CAMERA_FREE_DISTANCE_MAX_CLAMP and mouseWheelMove < 0:
      camera.target.x += mouseWheelMove.float*(camera.target.x - camera.position.x)*CAMERA_MOUSE_SCROLL_SENSITIVITY/cameraTargetDistance
      camera.target.y += mouseWheelMove.float*(camera.target.y - camera.position.y)*CAMERA_MOUSE_SCROLL_SENSITIVITY/cameraTargetDistance
      camera.target.z += mouseWheelMove.float*(camera.target.z - camera.position.z)*CAMERA_MOUSE_SCROLL_SENSITIVITY/cameraTargetDistance
    
    elif camera.position.y > camera.target.y and camera.target.y >= 0:
      camera.target.x += mouseWheelMove.float*(camera.target.x - camera.position.x)*CAMERA_MOUSE_SCROLL_SENSITIVITY/cameraTargetDistance;
      camera.target.y += mouseWheelMove.float*(camera.target.y - camera.position.y)*CAMERA_MOUSE_SCROLL_SENSITIVITY/cameraTargetDistance;
      camera.target.z += mouseWheelMove.float*(camera.target.z - camera.position.z)*CAMERA_MOUSE_SCROLL_SENSITIVITY/cameraTargetDistance;

    elif camera.position.y > camera.target.y and camera.target.y < 0 and mouseWheelMove > 0:
      cameraTargetDistance -= mouseWheelMove.float * CAMERA_MOUSE_SCROLL_SENSITIVITY
      if cameraTargetDistance < CAMERA_FREE_DISTANCE_MIN_CLAMP:
        cameraTargetDistance = CAMERA_FREE_DISTANCE_MIN_CLAMP

    elif camera.position.y < camera.target.y and cameraTargetDistance == CAMERA_FREE_DISTANCE_MAX_CLAMP and mouseWheelMove < 0:
      camera.target.x += mouseWheelMove.float*(camera.target.x - camera.position.x)*CAMERA_MOUSE_SCROLL_SENSITIVITY/cameraTargetDistance;
      camera.target.y += mouseWheelMove.float*(camera.target.y - camera.position.y)*CAMERA_MOUSE_SCROLL_SENSITIVITY/cameraTargetDistance;
      camera.target.z += mouseWheelMove.float*(camera.target.z - camera.position.z)*CAMERA_MOUSE_SCROLL_SENSITIVITY/cameraTargetDistance;
    
    elif camera.position.y < camera.target.y and camera.target.y <= 0:
      camera.target.x += mouseWheelMove.float*(camera.target.x - camera.position.x)*CAMERA_MOUSE_SCROLL_SENSITIVITY/cameraTargetDistance;
      camera.target.y += mouseWheelMove.float*(camera.target.y - camera.position.y)*CAMERA_MOUSE_SCROLL_SENSITIVITY/cameraTargetDistance;
      camera.target.z += mouseWheelMove.float*(camera.target.z - camera.position.z)*CAMERA_MOUSE_SCROLL_SENSITIVITY/cameraTargetDistance;

    elif camera.position.y < camera.target.y and camera.target.y > 0 and mouseWheelMove > 0:
      cameraTargetDistance -= mouseWheelMove.float*CAMERA_MOUSE_SCROLL_SENSITIVITY
      if cameraTargetDistance < CAMERA_FREE_DISTANCE_MIN_CLAMP: cameraTargetDistance = CAMERA_FREE_DISTANCE_MIN_CLAMP

    if isKeyDown(sdl2.K_LSHIFT):
      if isKeyDown(sdl2.K_LALT):
        cameraAngle.x += mousePositionDelta.x * -CAMERA_FREE_MOUSE_SENSITIVITY;
        cameraAngle.y += mousePositionDelta.y * -CAMERA_FREE_MOUSE_SENSITIVITY;

        if cameraAngle.y > degToRad(CAMERA_FREE_MIN_CLAMP): cameraAngle.y = degToRad(CAMERA_FREE_MIN_CLAMP)
        elif cameraAngle.y < degToRad(CAMERA_FREE_MAX_CLAMP): cameraAngle.y = degToRad(CAMERA_FREE_MAX_CLAMP)
    
      else:
        camera.target.x += ((mousePositionDelta.x * -CAMERA_FREE_MOUSE_SENSITIVITY)*cos(cameraAngle.x) + (mousePositionDelta.y*CAMERA_FREE_MOUSE_SENSITIVITY)*sin(cameraAngle.x)*sin(cameraAngle.y))*(cameraTargetDistance/CAMERA_FREE_PANNING_DIVIDER);
        camera.target.y += ((mousePositionDelta.y * CAMERA_FREE_MOUSE_SENSITIVITY)*cos(cameraAngle.y))*(cameraTargetDistance/CAMERA_FREE_PANNING_DIVIDER)
        camera.target.z += ((mousePositionDelta.x * CAMERA_FREE_MOUSE_SENSITIVITY)*sin(cameraAngle.x) + (mousePositionDelta.y*CAMERA_FREE_MOUSE_SENSITIVITY)*cos(cameraAngle.x)*sin(cameraAngle.y))*(cameraTargetDistance/CAMERA_FREE_PANNING_DIVIDER);

  of CameraMode.FirstPerson:
    camera.position.x += (
      sin(cameraAngle.x) * direction[CameraMove.Back.ord].float - 
      sin(cameraAngle.x) * direction[CameraMove.Front.ord].float - 
      cos(cameraAngle.x) * direction[CameraMove.Left.ord].float + 
      cos(cameraAngle.x) * direction[CameraMove.Right.ord].float)/PLAYER_MOVEMENT_SENSITIVITY

    camera.position.y += (
      sin(cameraAngle.y) * direction[CameraMove.Front.ord].float - 
      sin(cameraAngle.y) * direction[CameraMove.Back.ord].float +
      1.0 * direction[CameraMove.Up.ord].float -
      1.0 * direction[CameraMove.Down.ord].float)/PLAYER_MOVEMENT_SENSITIVITY

    camera.position.z += (
      cos(cameraAngle.x)*direction[CameraMove.Back.ord].float -
      cos(cameraAngle.x)*direction[CameraMove.Front.ord].float +
      sin(cameraAngle.x)*direction[CameraMove.Left.ord].float -
      sin(cameraAngle.x)*direction[CameraMove.Right.ord].float)/PLAYER_MOVEMENT_SENSITIVITY

    var isMoving = false

    for i in 0..<6:
      if direction[i]:
        isMoving = true
        break
    cameraAngle.x += (mouseXDelta.float * CAMERA_MOUSE_MOVE_SENSITIVITY)
    cameraAngle.y += (mouseYDelta.float * CAMERA_MOUSE_MOVE_SENSITIVITY)

    if cameraAngle.y > degToRad(CAMERA_FIRST_PERSON_MIN_CLAMP): cameraAngle.y = degToRad(CAMERA_FIRST_PERSON_MIN_CLAMP)
    elif cameraAngle.y < degToRad(CAMERA_FIRST_PERSON_MAX_CLAMP): cameraAngle.y = degToRad(CAMERA_FIRST_PERSON_MAX_CLAMP)

    camera.target.x = camera.position.x - sin(cameraAngle.x)*CAMERA_FIRST_PERSON_FOCUS_DISTANCE
    camera.target.y = camera.position.y + sin(cameraAngle.y)*CAMERA_FIRST_PERSON_FOCUS_DISTANCE
    camera.target.z = camera.position.z - cos(cameraAngle.x)*CAMERA_FIRST_PERSON_FOCUS_DISTANCE

    if isMoving: inc(swingCounter)

    camera.position.y = playerEyesPosition - sin(swingCounter.float / CAMERA_FIRST_PERSON_STEP_TRIGONOMETRIC_DIVIDER) / CAMERA_FIRST_PERSON_STEP_DIVIDER

    camera.up.x = sin(swingCounter.float/(CAMERA_FIRST_PERSON_STEP_TRIGONOMETRIC_DIVIDER*2))/CAMERA_FIRST_PERSON_WAVING_DIVIDER
    camera.up.z = -sin(swingCounter.float/(CAMERA_FIRST_PERSON_STEP_TRIGONOMETRIC_DIVIDER*2))/CAMERA_FIRST_PERSON_WAVING_DIVIDER
  else:
      discard

  if cameraMode in { CameraMode.Free }:
    camera.position.x = sin(cameraAngle.x)*cameraTargetDistance*cos(cameraAngle.y) + camera.target.x
    if cameraAngle.y <= 0.0:
      camera.position.y = sin(cameraAngle.y)*cameraTargetDistance*sin(cameraAngle.y) + camera.target.y
    else:
      camera.position.y = -sin(cameraAngle.y)*cameraTargetDistance*sin(cameraAngle.y) + camera.target.y
    camera.position.z = cos(cameraAngle.x)*cameraTargetDistance*cos(cameraAngle.y) + camera.target.z