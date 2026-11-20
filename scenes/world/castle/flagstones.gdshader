shader_type spatial;

#include "res://scenes/world/castle/courtyard_scorch.gdshaderinc"

varying vec2 ground_position;

void vertex() {
	ground_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 paving = ground_position / vec2(1.38, 0.84);
	paving.x += 0.5 * mod(floor(paving.y), 2.0);
	vec2 tile = floor(paving);
	vec2 in_tile = fract(paving);
	vec2 edge = min(in_tile, 1.0 - in_tile);
	float chip = sin(ground_position.x * 14.0 + ground_position.y * 19.0) * 0.012;
	float joint = smoothstep(0.018, 0.055, min(edge.x, edge.y) + chip);
	float variation = fract(sin(dot(tile, vec2(39.7, 151.3))) * 4261.7);
	vec3 stone = mix(vec3(0.19, 0.18, 0.15), vec3(0.33, 0.30, 0.24), variation);
	ALBEDO = apply_courtyard_scorch(mix(vec3(0.097, 0.089, 0.062), stone, joint),
		ground_position, joint * 0.85);
	ROUGHNESS = 0.96;
}
