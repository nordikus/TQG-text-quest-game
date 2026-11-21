shader_type spatial;

varying vec3 branch_position;
varying vec3 branch_color;

void vertex() {
	branch_position = VERTEX;
	branch_color = COLOR.rgb;
}

void fragment() {
	vec3 p = branch_position;
	float crosswise = p.x * 0.92 + p.y * 0.57
		+ 0.23 * sin(p.z * 0.51 + p.y * 0.74)
		+ 0.10 * sin(p.z * 1.35 + p.x * 2.45);
	float seam = pow(max(0.0, sin(crosswise * 15.1 + 0.56 * sin(p.z * 0.78))), 7.0);
	float fibers = 0.5 + 0.5 * sin(crosswise * 38.3 + p.z * 0.37);
	vec3 bark = pow(max(branch_color, vec3(0.0)), vec3(1.85));
	ALBEDO = bark * (1.04 + 0.11 * fibers - 0.53 * seam);
	ROUGHNESS = 0.94;
}
