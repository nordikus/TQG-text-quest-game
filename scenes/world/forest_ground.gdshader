shader_type spatial;

#include "res://scenes/world/castle/courtyard_scorch.gdshaderinc"

varying vec2 world_xz;

float seed_at(vec2 tile) {
	return fract(sin(dot(tile, vec2(19.31, 91.27))) * 4297.19);
}

float patches(vec2 point) {
	vec2 tile = floor(point);
	vec2 corner = smoothstep(0.0, 1.0, fract(point));
	float low = mix(seed_at(tile), seed_at(tile + vec2(1.0, 0.0)), corner.x);
	float high = mix(seed_at(tile + vec2(0.0, 1.0)), seed_at(tile + vec2(1.0)), corner.x);
	return mix(low, high, corner.y);
}

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	float ground = 0.78 * patches(world_xz * 0.27) + 0.22 * patches(world_xz * 1.35);
	vec3 leaf_litter = vec3(0.048, 0.052, 0.023);
	vec3 grass = vec3(0.036, 0.095, 0.019);
	ALBEDO = apply_courtyard_scorch(mix(leaf_litter, grass, smoothstep(0.10, 0.84, ground)),
		world_xz, 0.0);
	ROUGHNESS = 1.0;
}
