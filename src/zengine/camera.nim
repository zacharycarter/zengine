import zgl, math, zmath, core, sdl2

type
  CameraMode* = enum
    Custom, Free

const CAMERA_FREE_DISTANCE_MAX_CLAMP = 120.0
const CAMERA_FREE_DISTANCE_MIN_CLAMP = 1.5
const CAMERA_MOUSE_SCROLL_SENSITIVITY = 1.5
const CAMERA_FREE_MOUSE_SENSITIVITY = 0.01
const CAMERA_FREE_PANNING_DIVIDER = 5.1

var cameraTargetDistance = 0.0
var cameraAngle = vector2Zero()
var playerEyesPosition = 1.85
var cameraMode = CameraMode.Custom
var previousMousePosition: Vector2

proc setMode*(camera: var Camera, mode: CameraMode) =
  let v1 = camera.position
  let v2 = camera.target

  let dx = v2.x - v1.x
  let dy = v2.y - v1.y
  let dz = v2.z - v1.z

  cameraTargetDistance= sqrt(dx*dx + dy*dy + dz*dz)

  var distance: Vector2
  distance.x = sqrt(dx*dx + dz*dz)
  distance.y = sqrt(dx*dx + dy*dy)

  cameraAngle.x = arcsin(abs(dx)/distance.x)
  cameraAngle.y = -arcsin(abs(dy)/distance.y)

  playerEyesPosition = camera.position.y

  cameraMode = mode

proc update*(camera: var Camera, mouseWheelMove: int) =
  var mousePositionDelta = vector2Zero()
  var mousePosition = getMousePosition()

  mousePositionDelta.x = mousePosition.x - previousMousePosition.x;
  mousePositionDelta.y = mousePosition.y - previousMousePosition.y;

  previousMousePosition = mousePosition;

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

    if isKeyDown(sdl2.K_LALT):
      camera.target.x += ((mousePositionDelta.x * -CAMERA_FREE_MOUSE_SENSITIVITY)*cos(cameraAngle.x) + (mousePositionDelta.y*CAMERA_FREE_MOUSE_SENSITIVITY)*sin(cameraAngle.x)*sin(cameraAngle.y))*(cameraTargetDistance/CAMERA_FREE_PANNING_DIVIDER);
      camera.target.y += ((mousePositionDelta.y * CAMERA_FREE_MOUSE_SENSITIVITY)*cos(cameraAngle.y))*(cameraTargetDistance/CAMERA_FREE_PANNING_DIVIDER)
      camera.target.z += ((mousePositionDelta.x * CAMERA_FREE_MOUSE_SENSITIVITY)*sin(cameraAngle.x) + (mousePositionDelta.y*CAMERA_FREE_MOUSE_SENSITIVITY)*cos(cameraAngle.x)*sin(cameraAngle.y))*(cameraTargetDistance/CAMERA_FREE_PANNING_DIVIDER);

  else:
      discard

  if cameraMode in { CameraMode.Free }:
    camera.position.x = sin(cameraAngle.x)*cameraTargetDistance*cos(cameraAngle.y) + camera.target.x
    if cameraAngle.y <= 0.0:
      camera.position.y = sin(cameraAngle.y)*cameraTargetDistance*sin(cameraAngle.y) + camera.target.y
    else:
      camera.position.y = -sin(cameraAngle.y)*cameraTargetDistance*sin(cameraAngle.y) + camera.target.y
    camera.position.z = cos(cameraAngle.x)*cameraTargetDistance*cos(cameraAngle.y) + camera.target.z