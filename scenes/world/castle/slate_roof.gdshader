shader_type spatial;

varying vec3 point;
varying vec3 world_normal;

void vertex() {
	point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec3 axis = abs(world_normal);
	vec2 face = axis.z > axis.x ? point.xy : point.zy;
	if (axis.y > 0.93) {
		face = point.xz;
	}
	vec2 tile = face / vec2(0.79, 0.39);
	tile.x += 0.5 * mod(floor(tile.y), 2.0);
	vec2 index = floor(tile);
	vec2 local = fract(tile);
	float shade = fract(sin(dot(index, vec2(12.7, 70.9))) * 3971.4);
	float overlap = smoothstep(0.02, 0.13, local.y);
	float seam = smoothstep(0.01, 0.05, min(local.x, 1.0 - local.x));
	vec3 slate = mix(vec3(0.038, 0.057, 0.079), vec3(0.084, 0.108, 0.136), shade);
	ALBEDO = slate * mix(0.57, 1.12, overlap * seam);
	ROUGHNESS = 0.92;
}
