#version 100
attribute vec3 inPosition;
attribute vec2 inTexCoord0;
attribute vec4 inColor;
varying vec2 exFragTexCoord;
varying vec4 exColor;
uniform mat4 mvpMatrix;
void main() {
    exFragTexCoord = inTexCoord0;
    exColor = inColor;
    gl_Position = mvpMatrix * vec4(inPosition, 1.0);
}