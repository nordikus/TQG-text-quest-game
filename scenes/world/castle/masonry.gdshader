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
	float chip = sin(face.x * 7.6 + face.y * 10.4) * sin(face.y * 23.2 - face.x * 3.2) * 0.009;
	float grout_distance = min(edge.x * 1.6, edge.y) + chip;
	float variation = fract(sin(dot(block, vec2(47.23, 91.77))) * 4231.0);
	float mineral = sin(face.x * 14.1 + sin(face.y * 10.0 + variation) * 1.7)
		* sin(face.y * 21.6 + face.x * 3.1);
	float crust = smoothstep(0.015, 0.070, grout_distance);
	vec3 stone = mix(vec3(0.122, 0.136, 0.15), vec3(0.225, 0.229, 0.209), variation);
	stone *= 0.97 + mineral * 0.059 + smoothstep(0.1, 0.94, local.y) * 0.074;
	vec3 grout = vec3(0.077, 0.084, 0.080);
	ALBEDO = mix(grout, stone, crust);
	ROUGHNESS = mix(1.0, 0.90, crust);
}
