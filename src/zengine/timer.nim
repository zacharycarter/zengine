import sdl2


# The `Timer` object is what is used to measure time and differences in time.
# This is necessary for things like Animation, frame independant movement,
# lifetimes, cooldowns, and many more things.  The general idea of this is that
# you create a Timer, start it up, tick it forward and then grab the difference
# in time from the previous tick to the next.
#
# Within your game (loop) there should be at least one timer.  It should look
# something like this:
#
# ```
#   # Create and start the clock
#   var clock = Timer()
#   clock.start()
#   while running:
#
#     # Update game & render logic
#     update(clock.deltaTime())
#     render(clock.deltaTime())
#
#     # Tick forward
#     clock.tick()
# ```
#
# I'd recommend reading the documentation for the `start()`, `tick()`, and
# `deltaTime()` procs to get a better idea how they work.
type Timer* = object
  ticks: uint64                                 # How many times the timer has "ticked,"
  timeSinceLastTick: uint64                     # Amount of time (in seconds) since the last tick
  startTime, currentTime, previousTime: uint64  # What actually measures the time under the hood


# How many "time units," from SDL is one second (caching the function's return)
let frequency: uint64 = sdl2.getPerformanceFrequency()


# Starts the timer.  You can call this multiple times to reset it.
proc start*(self: var Timer) =
  self.startTime = sdl2.getPerformanceCounter()
  self.previousTime = self.startTime
  self.currentTime = self.startTime


# Returns total number of ticks the Timer has endured.  You will probably not
# need to use this at all.
proc totalTicks*(self: Timer) : uint64 {.inline.} =
  self.ticks


# Returns the time elapsed between the current tick and the previous tick.  This
# value will not chance until you call `tick` again.  Say if your game is
# running at 100 logical updates per second, this would return a value around
# `0.01`.  If it was logically updating at 60 FPS, it would be more like
# `0.016667`.
# Return value is in seconds.
proc deltaTime*(self: Timer) : uint64 {.inline.} =
  self.timeSinceLastTick


# Returns the time elapsed since `Timer.init()` has been called.  Return value
# is in seconds.
proc timeElapsed*(self: Timer) : uint64 {.inline.} =
  (self.currentTime - self.startTime)


# Ticks the timer forward.
proc tick*(self: var Timer) {.inline.} =
  self.currentTime = sdl2.getPerformanceCounter()
  self.timeSinceLastTick = (self.currentTime - self.previousTime) div frequency
  self.previousTime = self.currentTime
  self.ticks.inc()

