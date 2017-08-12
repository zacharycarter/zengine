#version 330
in vec2 exFragTexCoord;
in vec4 exColor;
out vec4 outColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

float LinearizeDepth(float depth)
{
    float z = depth * 2.0 - 1.0; // Back to NDC 
    return (2.0 * 0.1 * 100.0) / (100.0 + 0.1 - z * (100.0 - 0.1));	
}

void main() {
    // vec4 texelColor = texture(texture0, exFragTexCoord);
    // outColor = texelColor * colDiffuse * exColor;
    float depthValue = texture(texture0, exFragTexCoord).r;
    outColor = vec4(vec3(LinearizeDepth(depthValue) / 100.0), 1.0);
}
