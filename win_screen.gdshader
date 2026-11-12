
shader_type canvas_item;

uniform float threshold = 0.35;
uniform float softness = 0.18;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    float green = tex.g - max(tex.r, tex.b);

    float mask = 1.0 - smoothstep(
        threshold,
        threshold + softness,
        green
    );

    tex.a *= mask;
    COLOR = tex;
}
