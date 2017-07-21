# Package

version       = "0.1.0"
author        = "Zachary Carter"
description   = "Game engine"
license       = "MIT"

skipDirs      = @["examples"]
srcDir        = "src"

# Dependencies

requires "nim >= 0.17.1"
requires "sdl2 >= 1.1"
requires "opengl >= 1.1.0"
requires "https://github.com/zacharycarter/nimassimp.git"