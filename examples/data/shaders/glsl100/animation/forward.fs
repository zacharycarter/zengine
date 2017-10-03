#version 100
precision mediump float;
varying vec2 exFragTexCoord;
varying vec4 exColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

void main() {
    vec4 texelColor = texture2D(texture0, exFragTexCoord);
    gl_FragColor = texelColor;
}