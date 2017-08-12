#version 330

in vec3 inPosition;
in vec3 inNormal;
in vec2 inTexCoord0;
in vec4 inColor;

layout (location = 6) in ivec4 BoneIDs;
layout (location = 7) in vec4 Weights;

const int MAX_BONES = 100;

out vec3 fragPosition;
out vec2 fragTexCoord;
out vec4 fragColor;
out vec3 fragNormal;

uniform mat4 mvpMatrix;
uniform mat4 gBones[MAX_BONES];

void main()
{
    mat4 BoneTransform = gBones[BoneIDs[0]] * Weights[0];
    BoneTransform     += gBones[BoneIDs[1]] * Weights[1];
    BoneTransform     += gBones[BoneIDs[2]] * Weights[2];
    BoneTransform     += gBones[BoneIDs[3]] * Weights[3];

    vec4 PosL    = BoneTransform * vec4(inPosition, 1.0);

    fragPosition = inPosition;
    fragTexCoord = inTexCoord0;
    fragColor = inColor;

    vec4 NormalL = BoneTransform * vec4(inNormal, 0.0);

    fragNormal = NormalL.xyz;

    gl_Position = mvpMatrix * PosL;
}
