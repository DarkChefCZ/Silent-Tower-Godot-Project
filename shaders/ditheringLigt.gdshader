shader_type canvas_item;

uniform sampler2D dither_map;
uniform float strength = 0.1;
uniform float depth_levels = 3.0;

void fragment() {
    vec4 col = texture(TEXTURE, UV);

    ivec2 ds = textureSize(dither_map, 0);
    vec2 duv = fract(FRAGCOORD.xy / vec2(ds));

    float d = texture(dither_map, duv).r - 0.5;

    col.rgb += d * strength;
    col.rgb = round(col.rgb * depth_levels) / depth_levels;

    COLOR = col;
}
