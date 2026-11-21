shader_type spatial;

varying vec3 point;
varying vec3 tint;

void vertex() {
	point = VERTEX;
	tint = COLOR.rgb;
}

void fragment() {
	float angle = atan(point.z, point.x);
	float flow = angle * 15.0 + sin(point.y * 0.56 + angle * 3.0) * 1.05;
	float fissure = smoothstep(0.58, 0.95, sin(flow + sin(point.y * 1.6) * 0.32));
	float fiber = sin(flow * 2.17 + point.y * 0.41) * sin(point.y * 13.0);
	float moss = smoothstep(0.0, 0.27, tint.g - tint.r);
	vec3 wood = pow(max(tint, vec3(0.002)), vec3(1.65));
	wood *= 0.96 + fiber * 0.105 - fissure * mix(0.38, 0.16, moss);
	float upper_walk = smoothstep(14.95, 16.5, point.y) * (1.0 - smoothstep(17.65, 19.0, point.y));
	upper_walk *= (1.0 - smoothstep(-3.9, -1.9, point.z)) * moss;
	float grain = point.x * 8.1 + 0.9 * sin(point.z * 0.88) + 0.35 * sin(point.z * 2.52 + point.x * 3.27);
	float streaks = pow(0.5 + 0.5 * sin(grain), 5.5);
	float patches = 0.5 + 0.5 * sin(point.z * 2.83 + 1.6 * sin(point.x * 3.23));
	vec3 exposed_bark = vec3(0.165, 0.085, 0.044) * (0.80 + 0.25 * patches);
	wood = mix(wood * (1.0 + 0.16 * upper_walk * patches), exposed_bark, upper_walk * (0.13 + 0.43 * streaks));
	ALBEDO = wood;
	ROUGHNESS = 0.97;
}
