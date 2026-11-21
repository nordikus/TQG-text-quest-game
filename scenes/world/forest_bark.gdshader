shader_type spatial;

uniform bool charred = false;
uniform bool exposed_ends = false;
varying vec3 surface_position;
varying vec3 bark_point;
varying float end_face;

void vertex() {
	surface_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	bark_point = VERTEX;
	end_face = abs(NORMAL.y);
}

void fragment() {
	float grain = sin(UV.x * 113.097 + sin(UV.y * 13.0 + UV.x * 25.133) * 1.2);
	float fibers = sin(UV.x * 194.779 + sin(UV.y * 37.0) * 0.84) * 0.18;
	float grooves = smoothstep(0.54, 0.94, grain + fibers);
	float patch = sin(surface_position.x * 1.8 + surface_position.z * 2.7 + UV.y * 5.0) * 0.5 + 0.5;
	vec3 warm_bark = mix(vec3(0.071, 0.042, 0.022), vec3(0.142, 0.096, 0.055), patch);
	vec3 coaled_bark = mix(vec3(0.016, 0.012, 0.009), vec3(0.042, 0.030, 0.023), patch);
	ALBEDO = (charred ? coaled_bark : warm_bark) * (1.0 - grooves * 0.42);
	if (exposed_ends && end_face > 0.95) {
		float end_grain = sin(length(bark_point.xz * vec2(1.0, 1.11) + vec2(0.035, -0.018)) * 123.0);
		ALBEDO = mix(warm_bark, vec3(0.27, 0.171, 0.092), 0.32 + end_grain * 0.24);
	}
	ROUGHNESS = 0.99;
}
