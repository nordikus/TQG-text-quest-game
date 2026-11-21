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
	ALBEDO = wood;
	ROUGHNESS = 0.97;
}
