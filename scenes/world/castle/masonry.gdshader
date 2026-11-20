shader_type spatial;

varying vec3 stone_position;
varying vec3 stone_normal;

void vertex() {
	stone_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	stone_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec3 axis = abs(stone_normal);
	vec2 face = axis.x > axis.z ? stone_position.zy : stone_position.xy;
	if (axis.y > max(axis.x, axis.z)) {
		face = stone_position.xz;
	}
	vec2 cells = face / vec2(2.2, 0.84);
	cells.x += 0.5 * mod(floor(cells.y), 2.0);
	vec2 block = floor(cells);
	vec2 local = fract(cells);
	vec2 edge = min(local, 1.0 - local);
	float grout_distance = min(edge.x * 1.6, edge.y);
	float variation = fract(sin(dot(block, vec2(47.23, 91.77))) * 4231.0);
	vec3 stone = mix(vec3(0.13, 0.145, 0.157), vec3(0.21, 0.221, 0.22), variation);
	vec3 grout = vec3(0.085, 0.093, 0.094);
	ALBEDO = mix(grout, stone, smoothstep(0.009, 0.042, grout_distance));
	ROUGHNESS = 0.95;
}
