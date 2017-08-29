{.experimental.}

import glm

import nuklear, opengl

import fonts/roboto_regular

const MAX_VERTEX_BUFFER = 512 * 1024
const MAX_ELEMENT_BUFFER = 128 * 1024


proc `+`[T](a: ptr T, b: int): ptr T =
    if b >= 0:
        cast[ptr T](cast[uint](a) + cast[uint](b * a[].sizeof))
    else:
        cast[ptr T](cast[uint](a) - cast[uint](-1 * b * a[].sizeof))

template offsetof(typ, field): untyped = (var dummy: typ; cast[uint](addr(dummy.field)) - cast[uint](addr(dummy)))

template alignof(typ) : uint =
  if sizeof(typ) > 1:
    offsetof(tuple[c: char, x: typ], x)
  else:
    1

type 
  Device = ref object
    cmds: buffer
    null: draw_null_texture
    vbo, vao, ebo: GLuint
    prog: GLuint
    vert_shader: GLuint
    frag_shader: GLuint
    attrib_pos: GLint
    attrib_uv: GLint
    attrib_col: GLint
    uniform_tex: GLint
    uniform_proj: GLint
    font_tex: GLuint

type
  Vertex = object
    position: array[2, float]
    uv: array[2, float]
    col: array[4, char]

var fontAtlas : font_atlas
var fontConfig : font_config
var config : convert_config

var 
  ctx : ref context = new(nuklear.context)
  dev : Device = Device()
  fb_scale = vec2f(1.0, 1.0)
  vertex_layout = @[
    draw_vertex_layout_element(
      attribute: VERTEX_POSITION,
      format: FORMAT_FLOAT, 
      offset: offsetof(Vertex, position)
    ),
    draw_vertex_layout_element(
      attribute: VERTEX_TEXCOORD,
      format: FORMAT_FLOAT, 
      offset: offsetof(Vertex, uv)
    ),
    draw_vertex_layout_element(
      attribute: VERTEX_COLOR,
      format: FORMAT_R8G8B8A8, 
      offset: offsetof(Vertex, col)
    ),
    draw_vertex_layout_element(
      attribute: VERTEX_ATTRIBUTE_COUNT,
      format: FORMAT_COUNT,
      offset: 0
    )
  ]

proc set_style(ctx: var context) =
  var style : array[COLOR_COUNT.ord, color]
  style[COLOR_TEXT.ord] = newColorRGBA( 70, 70, 70, 255 )
  style[COLOR_WINDOW.ord] = newColorRGBA( 175, 175, 175, 255 )
  style[COLOR_HEADER.ord] = newColorRGBA( 175, 175, 175, 255 )
  style[COLOR_BORDER.ord] = newColorRGBA( 175, 175, 175, 255 )
  style[COLOR_BUTTON.ord] = newColorRGBA( 175, 175, 175, 255 )
  style[COLOR_BUTTON_HOVER.ord] = newColorRGBA( 175, 175, 175, 255 )
  style[COLOR_BUTTON_ACTIVE.ord] = newColorRGBA( 175, 175, 175, 255 )
  style[COLOR_TOGGLE.ord] = newColorRGBA( 175, 175, 175, 255 )
  style[COLOR_TOGGLE_HOVER.ord] = newColorRGBA( 175, 175, 175, 255 )
  style[COLOR_TOGGLE_CURSOR.ord] = newColorRGBA( 175, 175, 175, 255 )
  style[COLOR_SELECT.ord] = newColorRGBA( 175, 175, 175, 255 )
  style[COLOR_SELECT_ACTIVE.ord] = newColorRGBA( 0, 0, 0, 255 )
  style[COLOR_SLIDER.ord] = newColorRGBA( 0, 0, 0, 255 )
  style[COLOR_SLIDER_CURSOR.ord] = newColorRGBA( 0, 0, 0, 255 )
  style[COLOR_SLIDER_CURSOR_HOVER.ord] = newColorRGBA( 0, 0, 0, 255 )
  style[COLOR_SLIDER_CURSOR_ACTIVE.ord] = newColorRGBA( 0, 0, 0, 255 )
  style[COLOR_PROPERTY.ord] = newColorRGBA( 0, 0, 0, 255 )
  style[COLOR_EDIT.ord] = newColorRGBA( 0, 0, 0, 255 )
  style[COLOR_EDIT_CURSOR.ord] = newColorRGBA( 0, 0, 0, 255 )
  style[COLOR_COMBO.ord] = newColorRGBA( 0, 0, 0, 255 )
  style[COLOR_CHART_COLOR.ord] = newColorRGBA( 0, 0, 0, 255 )
  style[COLOR_CHART_COLOR_HIGHLIGHT.ord] = newColorRGBA( 0, 0, 0, 255 )
  style[COLOR_SCROLLBAR.ord] = newColorRGBA( 0, 0, 0, 255 )
  style[COLOR_SCROLLBAR_CURSOR.ord] = newColorRGBA( 0, 0, 0, 255 )
  style[COLOR_SCROLLBAR_CURSOR_HOVER.ord] = newColorRGBA( 0, 0, 0, 255 )
  style[COLOR_SCROLLBAR_CURSOR_ACTIVE.ord] = newColorRGBA( 0, 0, 0, 255 )
  style[COLOR_TAB_HEADER.ord] = newColorRGBA( 0, 0, 0, 255 )
  
  ctx.newStyleFromTable(style[0])


proc init_device() =
  var status: GLint
  #buffer_init(addr dev.cmds, addr allocator, 512 * 1024)
  init(dev.cmds)
  dev.prog = glCreateProgram()
  dev.vert_shader = glCreateShader(GL_VERTEX_SHADER)
  dev.frag_shader = glCreateShader(GL_FRAGMENT_SHADER)
  
  var vertex_shader = """
    #version 330
    in vec2 Position;
    in vec2 TexCoord;
    in vec4 Color;
    out vec2 Frag_UV;
    out vec4 Frag_Color;
    uniform mat4 ProjMtx;
    void main() {
        Frag_UV = TexCoord;
        Frag_Color = Color;
        gl_Position = ProjMtx * vec4(Position.xy, 0, 1);
    }
  """
  var fragment_shader  = """
    #version 330
    precision mediump float;
    uniform sampler2D Texture;
    in vec2 Frag_UV;
    in vec4 Frag_Color;
    out vec4 Out_Color;
    void main() {
        Out_Color = Frag_Color * texture(Texture, Frag_UV.st);
    }
  """

  let vertCStringArray = allocCStringArray([vertex_shader])
  let fragCStringArray = allocCStringArray([fragment_shader])
  glShaderSource(dev.vert_shader, 1, vertCStringArray, nil)

  glShaderSource(dev.frag_shader, 1, fragCStringArray, nil)
  
  glCompileShader(dev.vert_shader)
  glCompileShader(dev.frag_shader)
  glGetShaderiv(dev.vert_shader, GL_COMPILE_STATUS, addr status)
  assert(status == GL_TRUE.cint)
  glGetShaderiv(dev.frag_shader, GL_COMPILE_STATUS, addr status)
  assert(status == GL_TRUE.cint)
  glAttachShader(dev.prog, dev.vert_shader)
  glAttachShader(dev.prog, dev.frag_shader)
  glLinkProgram(dev.prog)
  glGetProgramiv(dev.prog, GL_LINK_STATUS, addr status)
  assert(status == GL_TRUE.cint)

  dev.uniform_tex = glGetUniformLocation(dev.prog, "Texture")
  dev.uniform_proj = glGetUniformLocation(dev.prog, "ProjMtx")
  dev.attrib_pos = glGetAttribLocation(dev.prog, "Position")
  dev.attrib_uv = glGetAttribLocation(dev.prog, "TexCoord")
  dev.attrib_col = glGetAttribLocation(dev.prog, "Color")

  # buffer setup
  glGenBuffers(1, addr dev.vbo)
  glGenBuffers(1, addr dev.ebo)
  glGenVertexArrays(1, addr dev.vao)

  glBindVertexArray(dev.vao)
  glBindBuffer(GL_ARRAY_BUFFER, dev.vbo)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, dev.ebo)

  glEnableVertexAttribArray((GLuint)dev.attrib_pos)
  glEnableVertexAttribArray((GLuint)dev.attrib_uv)
  glEnableVertexAttribArray((GLuint)dev.attrib_col)

  let vs = GLsizei sizeof(Vertex)
  let vp = offsetof(Vertex, position)
  let vt = offsetof(Vertex, uv)
  let vc = offsetof(Vertex, col)
  glVertexAttribPointer((GLuint)dev.attrib_pos, 2, cGL_FLOAT, GL_FALSE, vs, cast[pointer](vp))
  glVertexAttribPointer((GLuint)dev.attrib_uv, 2, cGL_FLOAT, GL_FALSE, vs, cast[pointer](vt))
  glVertexAttribPointer((GLuint)dev.attrib_col, 4, cGL_UNSIGNED_BYTE, GL_TRUE, vs, cast[pointer](vc))

  glBindTexture(GL_TEXTURE_2D, 0)
  glBindBuffer(GL_ARRAY_BUFFER, 0)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)
  glBindVertexArray(0)


proc init*() =
  var w, h: cint = 0

  fontAtlas.init()
  fontAtlas.open()

  var font = fontAtlas.addFromMemory(addr s_robotoRegularTtf, uint sizeof(s_robotoRegularTtf), 13.0'f32, nil)

  let image = fontAtlas.bake(w, h, FONT_ATLAS_RGBA32)
  glGenTextures(1, addr dev.font_tex)
  glBindTexture(GL_TEXTURE_2D, dev.font_tex)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
  glTexImage2D(GL_TEXTURE_2D, 0, GLint GL_RGBA, (GLsizei)w, (GLsizei)h, 0, GL_RGBA, GL_UNSIGNED_BYTE, image)

  fontAtlas.close(handle_id(int32 dev.font_tex), dev.null)

  discard ctx.init(font.handle)

  init_device()

  set_style(ctx)

var background = newColorRGB(28,48,62)

proc beginGUI*() =
  openInput(ctx)

  closeInput(ctx)
  if ctx.open("test", newRect(50, 50, 230, 250), WINDOW_BORDER.ord or WINDOW_MOVABLE.ord or WINDOW_SCALABLE.ord or WINDOW_MINIMIZABLE.ord or WINDOW_TITLE.ord):
    const
      EASY = false
      HARD = true

    var op: bool = EASY

    var property {.global.}: cint = 20

    layoutStaticRow(ctx, 30, 80, 1)
    if buttonLabel(ctx, "button"): echo "button pressed"
  ctx.close()


  var bg : array[4, cfloat]
  
  background.fv(bg[0])

  var ortho = [
    [2.0f, 0.0f, 0.0f, 0.0f],
    [0.0f,-2.0f, 0.0f, 0.0f],
    [0.0f, 0.0f,-1.0f, 0.0f],
    [-1.0f,1.0f, 0.0f, 1.0f]
  ]
  ortho[0][0] /= (GLfloat)960;
  ortho[1][1] /= (GLfloat)540;

  glEnable(GL_BLEND);
  glBlendEquation(GL_FUNC_ADD);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glDisable(GL_CULL_FACE);
  glDisable(GL_DEPTH_TEST);
  glEnable(GL_SCISSOR_TEST);
  glActiveTexture(GL_TEXTURE0);

  glUseProgram(dev.prog);
  glUniform1i(dev.uniform_tex, 0);
  
  glUniformMatrix4fv(dev.uniform_proj, 1, GL_FALSE, addr ortho[0][0])

proc endGUI*() =
  var cmd : ptr draw_command
  var offset: ptr draw_index

  glBindVertexArray(dev.vao);
  glBindBuffer(GL_ARRAY_BUFFER, dev.vbo);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, dev.ebo);

  glBufferData(GL_ARRAY_BUFFER, MAX_VERTEX_BUFFER, nil, GL_STREAM_DRAW);
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, MAX_ELEMENT_BUFFER, nil, GL_STREAM_DRAW);

  var vertices = glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);
  var elements = glMapBuffer(GL_ELEMENT_ARRAY_BUFFER, GL_WRITE_ONLY);

  ##  fill convert configuration
  config.vertex_layout = addr vertex_layout[0]
  config.vertex_size = uint sizeof(Vertex)
  config.vertex_alignment = alignof(Vertex)
  config.null = dev.null
  config.circle_segment_count = 22;
  config.curve_segment_count = 22;
  config.arc_segment_count = 22;
  config.global_alpha = 1.0f;
  config.shape_AA = ANTI_ALIASING_ON;
  config.line_AA = ANTI_ALIASING_ON;

  var vbuf, ebuf : buffer
  init(vbuf, vertices, MAX_VERTEX_BUFFER)
  init(ebuf, elements, MAX_ELEMENT_BUFFER)

  convertDrawCommands(ctx, dev.cmds, vbuf, ebuf, config)

  discard glUnmapBuffer(GL_ARRAY_BUFFER);
  discard glUnmapBuffer(GL_ELEMENT_ARRAY_BUFFER);

  cmd = firstDrawCommand(ctx, dev.cmds)
  while not isNil(cmd):
    if cmd.elem_count == 0:
      continue
    glBindTexture(GL_TEXTURE_2D, GLuint cast[int](cmd.texture))
    glScissor(
                (GLint)(cmd.clip_rect.x * fb_scale.x),
                (GLint)((float(960) - float(cmd.clip_rect.y + cmd.clip_rect.h)) * fb_scale.y),
                (GLint)(cmd.clip_rect.w * fb_scale.x),
                (GLint)(cmd.clip_rect.h * fb_scale.y));
    glDrawElements(GL_TRIANGLES, (GLsizei)cmd.elem_count, GL_UNSIGNED_SHORT, offset);
    offset = offset + int cmd.elem_count

    cmd = nextDrawCommand(cmd, dev.cmds, ctx[])

      
  ctx.clear()


  glUseProgram(0)
  glBindBuffer(GL_ARRAY_BUFFER, 0)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)
  glBindVertexArray(0)
  # glDisable(GL_BLEND)
  glDisable(GL_SCISSOR_TEST)

proc shutdown*() =  
  fontAtlas.clear()
  ctx.free()
  glDetachShader(dev.prog, dev.vert_shader)
  glDetachShader(dev.prog, dev.frag_shader)
  glDeleteShader(dev.vert_shader)
  glDeleteShader(dev.frag_shader)
  glDeleteProgram(dev.prog)
  glDeleteTextures(1, addr dev.font_tex)
  glDeleteBuffers(1, addr dev.vbo)
  glDeleteBuffers(1, addr dev.ebo)
  free(dev.cmds)
