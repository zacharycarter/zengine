#version 330 

in vec3 inPosition;
in vec3 inNormal;
in vec2 inTexCoord0;
in vec4 inColor;

out vec3 fragPosition;
out vec2 fragTexCoord;
out vec4 fragColor;
out vec3 fragNormal;

uniform mat4 mvpMatrix;

void main()
{
    fragPosition = inPosition;
    fragTexCoord = inTexCoord0;
    fragColor = inColor;
    fragNormal = inNormal;

    gl_Position = mvpMatrix*vec4(inPosition, 1.0);
}