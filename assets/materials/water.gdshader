shader_type spatial;

uniform vec3 albedo: source_color = vec3(1.);
uniform sampler2D normalmap_tex1: repeat_enable, filter_linear;
uniform sampler2D normalmap_tex2: repeat_enable, filter_linear;

uniform vec2 direction1 = vec2(1., 0.);
uniform float scroll_speed1: hint_range(0., 1.) = 0.1;
uniform vec2 direction2 = vec2(0., 1.);
uniform float scroll_speed2: hint_range(0., 1.) = 0.2;

uniform vec2 player_location;

void fragment() {
    // Time-based scrolling (for wave motion)
    vec2 offset1 = direction1 * scroll_speed1 * TIME + player_location;
    vec2 offset2 = direction2 * scroll_speed2 * TIME + player_location;

    // Player offset for world alignment (prevent “sliding” look)

    vec3 normal1 = texture(normalmap_tex1, UV + offset1).rgb;
    vec3 normal2 = texture(normalmap_tex2, UV + offset2).rgb;

    NORMAL_MAP = mix(normal1, normal2, 0.5);
    ALBEDO = albedo;
    ROUGHNESS = 0.01;
    METALLIC = 0.2;
}
