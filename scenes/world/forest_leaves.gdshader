shader_type spatial;

uniform vec3 leaf_base : source_color = vec3(0.24, 0.43, 0.19);
uniform vec3 leaf_tip : source_color = vec3(0.43, 0.55, 0.23);
varying vec3 world_position;
varying vec3 tree_position;
varying vec3 local_position;

void vertex() {
	tree_position = MODEL_MATRIX[3].xyz;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	local_position = VERTEX;
}

void fragment() {
	float garden = fract(sin(dot(tree_position.xz, vec2(24.297, 83.869))) * 4314.77);
	float foliage = sin(world_position.x * 2.7 + world_position.z * 1.48) * sin(local_position.y * 3.0 - world_position.z * 1.8);
	float balance = clamp(local_position.y * 0.105 + garden * 0.31 + foliage * 0.09, 0.08, 0.92);
	ALBEDO = mix(leaf_base, leaf_tip, balance);
	ROUGHNESS = 0.93;
}
