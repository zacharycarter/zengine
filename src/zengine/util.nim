import opengl

converter toBool*(x: GLint): bool = x.bool
converter toInt*(x: GLuint): int = x.int
converter toGLuint*(x: GLint): GLuint = x.GLuint
converter toCuchar*(x: int): cuchar = x.cuchar
converter toCint*(x: int): cint = x.cint