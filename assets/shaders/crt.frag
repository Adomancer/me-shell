#version 440

// Efek CRT untuk lockscreen: scanline, vignette, dan flicker halus.
// Compile dulu: scripts/build-shaders.sh -> crt.frag.qsb

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float lineCount;
    float strength;
};

layout(binding = 1) uniform sampler2D source;

void main() {
    vec2 uv = qt_TexCoord0;

    // Aberasi kromatik kecil di pinggir layar
    vec2 d = uv - 0.5;
    float edge = dot(d, d);
    vec2 shift = d * edge * 0.006;
    vec4 c;
    c.r = texture(source, uv + shift).r;
    c.g = texture(source, uv).g;
    c.b = texture(source, uv - shift).b;
    c.a = texture(source, uv).a;

    float line = sin(uv.y * lineCount * 3.14159265) * 0.5 + 0.5;
    c.rgb *= 1.0 - strength * (1.0 - line);

    c.rgb *= clamp(1.0 - edge * 1.4, 0.0, 1.0);
    c.rgb *= 1.0 - 0.015 * sin(time * 60.0);

    fragColor = c * qt_Opacity;
}
