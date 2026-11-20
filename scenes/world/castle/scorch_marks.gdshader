shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 soot : source_color = vec4(0.105, 0.071, 0.054, 0.86);
instance uniform float seed = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise_value(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0)), f.x), f.y);
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	vec2 offset = vec2(seed * 3.1, seed * -7.4);
	float patch = noise_value(p * vec2(4.3, 6.1) + offset);
	float flecks = noise_value(p * 31.0 + offset);
	float spread = length(p) + 0.44 * (patch - 0.45) + 0.12 * (flecks - 0.5);
	float edge = 1.0 - smoothstep(0.36, 0.98, spread);
	ALBEDO = soot.rgb * mix(0.66, 1.20, patch);
	ROUGHNESS = 1.0;
	ALPHA = soot.a * edge * mix(0.55, 1.0, flecks);
}
