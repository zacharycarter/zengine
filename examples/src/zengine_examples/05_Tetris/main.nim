# Minimal example to open up a zengine window

import zengine, sdl2, opengl, random, glm, strutils

const
  ScreenWidth = 960
  ScreenHeight = 540
  SquareSize = 20
  Columns = 12
  Rows = 20
  LateralSpeed = 10
  TurningSpeed = 12
  FastFallAwaitCounter = 30
  FadingTime = 33

type
  GridSquare {.pure.} = enum
    Empty, Moving, Full, Block, Fading

var
  gameOver = false
  pause = false

  grid: array[Rows, array[Columns, GridSquare]]
  piece: array[4, array[4, GridSquare]]
  incomingPiece: array[4, array[4, GridSquare]]

  pieceRow = 0
  pieceCol = 0

  fadingColor: ZColor

  beginPlay = true
  pieceActive = false
  detection = false
  lineToDelete = false

  level = 1
  lines = 0

  gravityMovementCounter = 0
  lateralMovementCounter = 0
  turnMovementCounter = 0
  fastFallMovementCounter = 0

  fadeLineCounter = 0

  gravitySpeed = 30



let targetFramePeriod = 16.0 # 16 milliseconds corresponds to 60 fps
var frameTime: float64 = 0

proc limitFrameRate(clock: Timer) =
  let now = timeElapsed(clock) * 1000
  if frameTime > now:
    delay(uint32 frameTime - now) # Delay to maintain steady frame rate
  frameTime += targetFramePeriod

proc initGame() =
  level = 1
  lines = 0

  fadingColor = ZENGRAY

  pieceRow = 0
  pieceCol = 0

  pause = false

  beginPlay = true
  pieceActive = false
  detection = false
  lineToDelete = false

  gravityMovementCounter = 0
  lateralMovementCounter = 0
  turnMovementCounter = 0
  fastFallMovementCounter = 0

  fadeLineCounter = 0
  gravitySpeed = 30

  for row in 0..<Rows:
    for col in 0..<Columns:
      if col == Columns - 1 or col == 0 or row == Rows - 1:
        grid[row][col] = GridSquare.Block
      else:
        grid[row][col] = GridSquare.Empty

  for i in 0..<4:
    for j in 0..<4:
      incomingPiece[i][j] = GridSquare.Empty

  pollInput()

proc getRandomPiece(clock: Timer) =
  randomize(clock.timeElapsed().int64)
  let r = random(7)

  for i in 0..<4:
    for j in 0..<4:
      incomingPiece[i][j] = GridSquare.Empty
  
  case r:
    of 0:
      incomingPiece[1][1] = GridSquare.Moving;   incomingPiece[2][1] = GridSquare.Moving;    incomingPiece[1][2] = GridSquare.Moving;    incomingPiece[2][2] = GridSquare.Moving # Cube
    of 1:
      incomingPiece[1][0] = GridSquare.Moving;    incomingPiece[1][1] = GridSquare.Moving;    incomingPiece[1][2] = GridSquare.Moving;    incomingPiece[2][2] = GridSquare.Moving # L
    of 2:
      incomingPiece[1][2] = GridSquare.Moving;    incomingPiece[2][0] = GridSquare.Moving;    incomingPiece[2][1] = GridSquare.Moving;    incomingPiece[2][2] = GridSquare.Moving # Inv L
    of 3:
      incomingPiece[0][1] = GridSquare.Moving;    incomingPiece[1][1] = GridSquare.Moving;    incomingPiece[2][1] = GridSquare.Moving;    incomingPiece[3][1] = GridSquare.Moving # Rect
    of 4:
      incomingPiece[1][0] = GridSquare.Moving;    incomingPiece[1][1] = GridSquare.Moving;    incomingPiece[1][2] = GridSquare.Moving;    incomingPiece[2][1] = GridSquare.Moving # Tri
    of 5:
      incomingPiece[1][1] = GridSquare.Moving;    incomingPiece[2][1] = GridSquare.Moving;     incomingPiece[2][2] = GridSquare.Moving;    incomingPiece[3][2] = GridSquare.Moving # S
    of 6:
      incomingPiece[1][2] = GridSquare.Moving;    incomingPiece[2][2] = GridSquare.Moving;     incomingPiece[2][1] = GridSquare.Moving;    incomingPiece[3][1] = GridSquare.Moving # Z
    else:
      discard

proc createPiece(clock: Timer): bool =
  pieceRow = 0
  pieceCol = (Columns - 4) div 2

  if beginPlay:
    getRandomPiece(clock) 
    beginPlay = false

  for i in 0..<4:
    for j in 0..<4:
      piece[i][j] = incomingPiece[i][j]

  getRandomPiece(clock)

  for col in pieceCol..<pieceCol + 4:
    for row in 0..<4:
      if piece[row][col - pieceCol] == GridSquare.Moving: grid[row][col] = GridSquare.Moving

  return true

proc checkDetection() =
  for col in countdown(Columns - 2, 0):
    for row in 1..<Rows - 1:
      if grid[row][col] == GridSquare.Moving and grid[row + 1][col] == GridSquare.Full or grid[row][col] == GridSquare.Moving and grid[row + 1][col] == GridSquare.Block: 
        detection = true

proc checkCompletion() =
  var calculator: int

  for row in countdown(Rows - 2, 0):
    calculator = 0
    for col in 1..<Columns - 1: 
      if grid[row][col] == GridSquare.Full: inc(calculator)

      if calculator == Columns - 2:
        lineToDelete = true
        calculator = 0

        for z in 1..<Columns - 1:
          grid[row][z] = GridSquare.Fading


proc resolveFallingMovement() =
  if detection:
    for row in countdown(Rows - 2, 0):
      for col in 1..<Columns - 1:
        if grid[row][col] == GridSquare.Moving:
          grid[row][col] = GridSquare.Full
          detection = false
          pieceActive = false
  else:
    for row in countdown(Rows - 2, 0):
      for col in 1..<Columns - 1: 
        if grid[row][col] == GridSquare.Moving:
          grid [row+1][col] = GridSquare.Moving
          grid[row][col] = GridSquare.Empty

    inc(pieceRow)

proc deleteCompletedLines() =
  for row in countdown(Rows - 2, 0):
    while grid[row][1] == GridSquare.Fading:
      for col in 1..<Columns - 1:
        grid[row][col] = GridSquare.Empty
      for row2 in countdown(row - 1, 0):
        for col2 in 1..<Columns - 1:
          if grid[row2][col2] == GridSquare.Full:
            grid[row2 + 1][col2] = GridSquare.Full
            grid[row2][col2] = GridSquare.Empty
          elif grid[row2][col2] == GridSquare.Fading:
            grid[row2 + 1][col2] = GridSquare.Fading
            grid[row2][col2] = GridSquare.Empty

proc resolveLateralMovement(): bool =
  result = false

  # Move Left
  if isKeyDown(K_LEFT):
    for row in countdown(Rows - 2, 0):
      for col in 1..<Columns - 1:
        if grid[row][col] == GridSquare.Moving:
          if col - 1 == 0 or grid[row][col - 1] == GridSquare.Full: result = true
    
    # If able, move left
    if not result:
      for row in countdown(Rows - 2, 0):
        for col in 1..<Columns - 1:
          if grid[row][col] == GridSquare.Moving:
            grid[row][col - 1] = GridSquare.Moving
            grid[row][col] = GridSquare.Empty
      
      dec(pieceCol)
  
  elif isKeyDown(K_RIGHT):
    for row in countdown(Rows - 2, 0):
      for col in 1..<Columns - 1:
        if grid[row][col] == GridSquare.Moving:
          if col + 1 == Columns - 1 or grid[row][col + 1] == GridSquare.Full: result = true

    if not result:
      for row in countdown(Rows - 2, 0):
        for col in countdown(Columns - 1, 1):
          if grid[row][col] == GridSquare.Moving:
            grid[row][col + 1] = GridSquare.Moving
            grid[row][col] = GridSquare.Empty
      
      inc(pieceCol)

proc resolveTurnMovement(): bool =
  if isKeyDown(K_UP):
    var aux: int
    var checker = false

    if grid[pieceRow][pieceCol + 3] == GridSquare.Moving and grid[pieceRow][pieceCol] != GridSquare.Empty and grid[pieceRow][pieceCol] != GridSquare.Moving:
      checker = true
    if grid[pieceRow + 3][pieceCol + 3] == GridSquare.Moving and grid[pieceRow][pieceCol + 3] != GridSquare.Empty and grid[pieceRow][pieceCol + 3] != GridSquare.Moving:
      checker = true
    if grid[pieceRow + 3][pieceCol] != GridSquare.Moving and grid[pieceRow + 3][pieceCol + 3] != GridSquare.Empty and grid[pieceRow + 3][pieceCol + 3] != GridSquare.Moving:
      checker = true
    if grid[pieceRow][pieceCol] != GridSquare.Moving and grid[pieceRow + 3][pieceCol] != GridSquare.Empty and grid[pieceRow + 3][pieceCol] != GridSquare.Moving:
      checker = true

    if grid[pieceRow][pieceCol + 1] == GridSquare.Moving and grid[pieceRow + 2][pieceCol] != GridSquare.Empty and grid[pieceRow + 2][pieceCol] != GridSquare.Moving:
      checker = true
    if grid[pieceRow + 1][pieceCol + 3] == GridSquare.Moving and grid[pieceRow][pieceCol + 1] != GridSquare.Empty and grid[pieceRow][pieceCol + 1] != GridSquare.Moving:
      checker = true
    if grid[pieceRow + 3][pieceCol + 2] != GridSquare.Moving and grid[pieceRow + 1][pieceCol + 3] != GridSquare.Empty and grid[pieceRow + 1][pieceCol + 3] != GridSquare.Moving:
      checker = true
    if grid[pieceRow + 2][pieceCol] != GridSquare.Moving and grid[pieceRow + 3][pieceCol + 2] != GridSquare.Empty and grid[pieceRow + 3][pieceCol + 2] != GridSquare.Moving:
      checker = true

    if grid[pieceRow][pieceCol + 2] == GridSquare.Moving and grid[pieceRow + 1][pieceCol] != GridSquare.Empty and grid[pieceRow + 1][pieceCol] != GridSquare.Moving:
      checker = true
    if grid[pieceRow + 2][pieceCol + 2] == GridSquare.Moving and grid[pieceRow][pieceCol + 2] != GridSquare.Empty and grid[pieceRow][pieceCol + 2] != GridSquare.Moving:
      checker = true
    if grid[pieceRow + 3][pieceCol + 1] == GridSquare.Moving and grid[pieceRow + 2][pieceCol + 3] != GridSquare.Empty and grid[pieceRow + 2][pieceCol + 3] != GridSquare.Moving:
      checker = true
    if grid[pieceRow + 1][pieceCol] == GridSquare.Moving and grid[pieceRow + 3][pieceCol + 1] != GridSquare.Empty and grid[pieceRow + 3][pieceCol + 1] != GridSquare.Moving:
      checker = true

    if grid[pieceRow + 1][pieceCol + 1] == GridSquare.Moving and grid[pieceRow + 2][pieceCol + 1] != GridSquare.Empty and grid[pieceRow + 2][pieceCol + 1] != GridSquare.Moving:
      checker = true
    if grid[pieceRow + 1][pieceCol + 2] == GridSquare.Moving and grid[pieceRow + 1][pieceCol + 1] != GridSquare.Empty and grid[pieceRow + 1][pieceCol + 1] != GridSquare.Moving:
      checker = true
    if grid[pieceRow + 2][pieceCol + 2] == GridSquare.Moving and grid[pieceRow + 1][pieceCol + 2] != GridSquare.Empty and grid[pieceRow + 1][pieceCol + 2] != GridSquare.Moving:
      checker = true
    if grid[pieceRow + 2][pieceCol + 1] == GridSquare.Moving and grid[pieceRow + 2][pieceCol + 2] != GridSquare.Empty and grid[pieceRow + 2][pieceCol + 2] != GridSquare.Moving:
      checker = true
    

    if not checker:
      aux = piece[0][0].ord
      piece[0][0] = piece[3][0]
      piece[3][0] = piece[3][3]
      piece[3][3] = piece[0][3]
      piece[0][3] = aux.GridSquare

      aux = piece[1][0].ord
      piece[1][0] = piece[3][1]
      piece[3][1] = piece[2][3]
      piece[2][3] = piece[0][2]
      piece[0][2] = aux.GridSquare

      aux = piece[2][0].ord
      piece[2][0] = piece[3][2]
      piece[3][2] = piece[1][3]
      piece[1][3] = piece[0][1]
      piece[0][1] = aux.GridSquare

      aux = piece[1][1].ord
      piece[1][1] = piece[2][1]
      piece[2][1] = piece[2][2]
      piece[2][2] = piece[1][2]
      piece[1][2] = aux.GridSquare
    
    for row in countdown(Rows - 2, 0):
      for col in 1..<Columns - 1:
        if grid[row][col] == GridSquare.Moving:
          grid[row][col] = GridSquare.Empty
    
    for i in pieceRow..<pieceRow + 4:
      for j in pieceCol..<pieceCol + 4:
        if piece[i - pieceRow][j - pieceCol] == GridSquare.Moving:
          grid[i][j] = GridSquare.Moving
    
    return true
  
  result = false


proc updateGame(clock: Timer) =
  pollInput()
  if not gameOver:
    if isKeyPressed(K_p): 
      pause = not pause
    
    if not pause:
      if not lineToDelete:
        if not pieceActive:
          pieceActive = createPiece(clock)

          fastFallMovementCounter = 0
        else:
          inc(fastFallMovementCounter)
          inc(gravityMovementCounter)
          inc(lateralMovementCounter)
          inc(turnMovementCounter)
          if isKeyPressed(K_LEFT) or isKeyPressed(K_RIGHT): lateralMovementCounter = LateralSpeed
          if isKeyPressed(K_UP): turnMovementCounter = TurningSpeed

          if isKeyDown(K_DOWN) and fastFallMovementCounter >= FastFallAwaitCounter:
            gravityMovementCounter += gravitySpeed

          if gravityMovementCounter >= gravitySpeed:
            checkDetection()

            resolveFallingMovement()

            checkCompletion()

            gravityMovementCounter = 0

          if lateralMovementCounter >= LateralSpeed:
            if not resolveLateralMovement(): lateralMovementCounter = 0  
          
          if turnMovementCounter >= TurningSpeed:
            if resolveTurnMovement(): turnMovementCounter = 0
        
        for row in 0..<2:
          for col in 1..<Columns - 1:
            if grid[row][col] == GridSquare.Full:
              gameOver = true

      
      else:
        inc(fadeLineCounter)

        if fadeLineCounter mod 8 < 4:
          fadingColor = MAROON
        else: fadingColor = GRAY

        if fadeLineCounter >= FadingTime:
          deleteCompletedLines()
          fadeLineCounter = 0
          lineToDelete = false

          inc(lines)
  
  else:
    if isKeyPressed(K_SPACE):
      initGame()
      gameOver = false




proc drawGame(clock: var Timer) = 
  clock.tick()  

  beginDrawing()

  clearBackground(ZENGRAY)

  if not gameOver:
    var offset = vec2i(ScreenWidth div 2 - (Columns*SquareSize div 2) - 50, ScreenHeight div 2 - ((Rows - 1)*SquareSize div 2) + SquareSize*2)

    offset.y -= 50

    var controller = offset.x

    for row in 0..<Rows:
      for col in 0..<Columns:
        if grid[row][col] == GridSquare.Empty:
          drawLine(offset.x, offset.y, offset.x + SquareSize, offset.y, LIGHTGRAY)
          drawLine(offset.x, offset.y, offset.x, offset.y + SquareSize, LIGHTGRAY )
          drawLine(offset.x + SquareSize, offset.y, offset.x + SquareSize, offset.y + SquareSize, LIGHTGRAY )
          drawLine(offset.x, offset.y + SquareSize, offset.x + SquareSize, offset.y + SquareSize, LIGHTGRAY )
          offset.x += SquareSize
        elif grid[row][col] == GridSquare.Full:
          drawRectangle(offset.x, offset.y, SquareSize, SquareSize, GRAY)
          offset.x += SquareSize
        elif grid[row][col] == GridSquare.Moving:
          drawRectangle(offset.x, offset.y, SquareSize, SquareSize, RED)
          offset.x += SquareSize
        elif grid[row][col] == GridSquare.Block:
          drawRectangle(offset.x, offset.y, SquareSize, SquareSize, LIGHTGRAY)
          offset.x += SquareSize
        elif grid[row][col] == GridSquare.Fading:
          drawRectangle(offset.x, offset.y, SquareSize, SquareSize, fadingColor)
          offset.x += SquareSize
      offset.x = controller
      offset.y += SquareSize

    offset.x = 600
    offset.y = 54

    let control = offset.x

    for j in 0..<4:
      for i in 0..<4:
        if incomingPiece[i][j] == GridSquare.Empty:
          drawLine(offset.x, offset.y, offset.x + SquareSize, offset.y, LIGHTGRAY)
          drawLine(offset.x, offset.y, offset.x, offset.y + SquareSize, LIGHTGRAY )
          drawLine(offset.x + SquareSize, offset.y, offset.x + SquareSize, offset.y + SquareSize, LIGHTGRAY )
          drawLine(offset.x, offset.y + SquareSize, offset.x + SquareSize, offset.y + SquareSize, LIGHTGRAY )
          offset.x += SquareSize
        elif incomingPiece[i][j] == GridSquare.Moving:
          drawRectangle(offset.x, offset.y, SquareSize, SquareSize, GRAY)
          offset.x += SquareSize
      
      offset.x = control
      offset.y += SquareSize
    
    drawText("INCOMING:", offset.x.float, offset.y.float - 100, 10.0, GRAY)
    drawText("LINES:      $1" % $lines, offset.x.float, offset.y.float + 20, 10, GRAY)

    var fontSize = 40
    if pause: drawText("GAME PAUSED", ScreenWidth / 2.0 - measureText("GAME PAUSED", fontSize).float/2, ScreenHeight / 2.0 - 40.0, 40.0, WHITE)
  

  else:
    var fontSize = 20
    drawText("PRESS [SPACE] TO PLAY AGAIN", ScreenWidth/2 - measureText("PRESS [SPACE] TO PLAY AGAIN", fontSize)/2, ScreenHeight/2 - 50, 20, WHITE)


  endDrawing()
  swapBuffers()

proc disposeGame() =
  discard

zengine.init(ScreenWidth, ScreenHeight, "Tetris")

initGame()

var
  # Window control
  evt = sdl2.defaultEvent
  running = true

var clock = Timer()
clock.start()

while running:
  while sdl2.pollEvent(evt):
    case evt.kind:
      # Shutdown if X button clicked
      of QuitEvent:
        running = false
      of KeyUp:
        let keyEvent = cast[KeyboardEventPtr](addr evt)
        # Shutdown if ESC pressed
        if keyEvent.keysym.sym == K_ESCAPE:
          running = false
      else:
        discard

  updateGame(clock)

  drawGame(clock)

  limitFrameRate(clock)

disposeGame()

zengine.core.shutdown()