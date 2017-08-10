#version 400
layout(location=0) in vec3 inPosition;
layout(location=1) in vec2 inTexCoord0;
layout(location=2) in vec4 inColor;
out vec2 exFragTexCoord;
out vec4 exColor;
uniform mat4 mvpMatrix;
void main() {
    exFragTexCoord = inTexCoord0;
    exColor = inColor;
    gl_Position = mvpMatrix * vec4(inPosition, 1.0);
}