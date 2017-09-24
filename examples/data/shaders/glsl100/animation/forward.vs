#version 100
attribute vec3 inPosition;
attribute vec3 inNormal;
attribute vec2 inTexCoord0;
attribute vec4 inColor;
attribute vec4 BoneIDs;
attribute vec4 Weights;

const int MAX_BONES = 100;

varying vec2 exFragTexCoord;
varying vec4 exColor;

uniform mat4 mvpMatrix;
uniform mat4 gBones[MAX_BONES];

void main()
{
    mat4 BoneTransform = gBones[int(BoneIDs[0])] * Weights[0];
    BoneTransform     += gBones[int(BoneIDs[1])] * Weights[1];
    BoneTransform     += gBones[int(BoneIDs[2])] * Weights[2];
    BoneTransform     += gBones[int(BoneIDs[3])] * Weights[3];

    vec4 PosL    = BoneTransform * vec4(inPosition, 1.0);

    exFragTexCoord = inTexCoord0;
    exColor = inColor;

    gl_Position = mvpMatrix * PosL;
}
