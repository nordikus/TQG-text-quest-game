uniform bool courtyard_burned = false;

float scorch_hash(vec2 cell) {
	return fract(sin(dot(cell, vec2(67.17, 173.21))) * 4135.17);
}

float scorch_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = smoothstep(0.0, 1.0, fract(p));
	return mix(mix(scorch_hash(cell), scorch_hash(cell + vec2(1, 0)), f.x),
		mix(scorch_hash(cell + vec2(0, 1)), scorch_hash(cell + vec2(1)), f.x), f.y);
}

float distance_to_scorch(vec2 p, vec2 a, vec2 b) {
	vec2 line = b - a;
	return length(p - a - clamp(dot(p - a, line) / dot(line, line), 0.0, 1.0) * line);
}

vec3 apply_courtyard_scorch(vec3 color, vec2 p, float relief) {
	if (!courtyard_burned || p.x < -32.5 || p.x > 12.0 || p.y > -76.5 || p.y < -136.0) {
		return color;
	}
	float distance = distance_to_scorch(p, vec2(0.0, -77.3), vec2(-2.1, -83.4));
	distance = min(distance, distance_to_scorch(p, vec2(-2.1, -83.4), vec2(-18.0, -85.6)));
	distance = min(distance, distance_to_scorch(p, vec2(-18.0, -85.6), vec2(-25.7, -87.4)));
	distance = min(distance, distance_to_scorch(p, vec2(-25.7, -87.4), vec2(-26.2, -105.0)));
	distance = min(distance, distance_to_scorch(p, vec2(-26.2, -105.0), vec2(-23.5, -117.6)));
	distance = min(distance, distance_to_scorch(p, vec2(-23.5, -117.6), vec2(-20.35, -126.0)));
	float cloud = scorch_noise(p * 0.53);
	float flecks = scorch_noise(p * 4.1);
	float width = mix(2.7, 5.3, smoothstep(-87.0, -81.0, p.y));
	float edge = distance + 1.75 * (cloud - 0.48) + 0.52 * flecks;
	float strength = (1.0 - smoothstep(width * 0.29, width, edge));
	strength *= 1.0 - smoothstep(-79.75, -76.5, p.y);
	float repairs = 1.0 - smoothstep(2.0, 7.2, length((p - vec2(-21.1, -123.5)) * vec2(1.05, 0.72)) + cloud);
	float supplies = 1.0 - smoothstep(1.6, 4.4,
		distance_to_scorch(p, vec2(-24.8, -106.9), vec2(-15.60, -118.70)) + 1.2 * cloud);
	float drift = (1.0 - smoothstep(0.4, 5.2, distance_to_scorch(p,
		vec2(-1.5, -98.0), vec2(-7.0, -120.8)) + 1.18 * cloud));
	drift *= 0.37 + 0.68 * smoothstep(0.25, 0.78, cloud);
	strength = max(strength, 0.97 * repairs);
	strength = max(strength, 0.94 * supplies);
	strength = max(strength, drift);
	vec3 ash = mix(vec3(0.024, 0.021, 0.018), vec3(0.113, 0.097, 0.080), cloud * flecks);
	return mix(color, mix(ash, ash * 1.32, relief), strength * mix(0.9, 0.75, relief));
}
