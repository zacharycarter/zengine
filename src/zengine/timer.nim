import sdl2

var 
  startTime, currentTime, previousTime, updateTime: float64
  ticks: uint
  frequency: float64

# Returns total number of ticks the timer has endured
proc totalTicks*() : uint {.inline.} =
  ticks

# Returns the time elapsed between the current frame
# and previous frame
proc deltaTime*() : float64 {.inline.} =
  updateTime

# Returns the time elapsed since application start
proc timeElapsed*() : float64 {.inline.} =
  currentTime - startTime

# Returns the current time
proc time*() : float64 {.inline.} =
  float64(sdl2.getPerformanceCounter()*1000) / frequency

# Ticks the timer
proc tick*() {.inline.} =
  currentTime = time()
  updateTime = currentTime - previousTime
  previousTime = currentTime
  inc(ticks)

# Initializes the timer
proc init*() =
  frequency = float64 sdl2.getPerformanceFrequency()
  startTime = time()
  currentTime = startTime