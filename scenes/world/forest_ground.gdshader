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
	vec3 floor_color = mix(leaf_litter, grass, smoothstep(0.10, 0.84, ground));
	float fine = patches(world_xz * vec2(4.2, 6.3)) + patches(world_xz * 19.0) * 0.30;
	float nearby = 1.0 - smoothstep(5.0, 25.0, distance(world_xz, CAMERA_POSITION_WORLD.xz));
	float track_edge = abs(world_xz.x - sin(world_xz.y * 1.26) * 0.10) + patches(world_xz * 2.83) * 0.25;
	float worn_track = smoothstep(3.12, 4.33, world_xz.y) * (1.0 - smoothstep(10.35, 12.3, world_xz.y));
	worn_track *= 1.0 - smoothstep(0.49, 1.24, track_edge);
	floor_color = mix(floor_color, vec3(0.125, 0.086, 0.049), worn_track * 0.76);
	floor_color *= mix(1.0, 0.76 + fine * 0.39, nearby);
	ALBEDO = apply_courtyard_scorch(floor_color, world_xz, 0.0);
	ROUGHNESS = 1.0;
}
