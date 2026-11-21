shader_type spatial;

varying vec3 point;
varying vec3 world_normal;

float grain(vec2 p) {
	vec2 cell = floor(p);
	vec2 weight = smoothstep(vec2(0.0), vec2(1.0), fract(p));
	vec2 d = vec2(61.8, 38.3);
	float a = fract(sin(dot(cell, d)) * 3819.71);
	float b = fract(sin(dot(cell + vec2(1.0, 0.0), d)) * 3819.71);
	float c = fract(sin(dot(cell + vec2(0.0, 1.0), d)) * 3819.71);
	float e = fract(sin(dot(cell + vec2(1.0), d)) * 3819.71);
	return mix(mix(a, b, weight.x), mix(c, e, weight.x), weight.y);
}

void vertex() {
	point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	bool horizontal = abs(world_normal.y) > 0.58;
	vec2 facet = horizontal ? point.xz : vec2(atan(point.z, point.x) * max(0.6, length(point.xz)), point.y);
	float weather = 0.65 * grain(facet * 4.0) + 0.35 * grain(facet * 16.0);
	vec3 limestone = mix(vec3(0.12, 0.13, 0.108), vec3(0.25, 0.25, 0.21), weather);
	float moss = smoothstep(0.43, 0.75, grain(point.xz * 2.0)) * (1.0 - smoothstep(0.12, 1.35, point.y));
	ALBEDO = mix(limestone, vec3(0.09, 0.155, 0.058), moss * 0.84);
	ROUGHNESS = 0.98;
}
