shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, shadows_disabled;

instance uniform float phase = 0.0;

void fragment() {
	float tick = TIME * 12.0 + phase * 5.0;
	float y = 1.0 - UV.y;
	float x = UV.x - 0.5 + sin(y * 7.0 + tick) * y * 0.11;
	float width = pow(1.0 - y, 0.88) * (0.43 - y * 0.12);
	float tips = 0.67 + 0.17 * sin(tick * 0.73 + UV.x * 24.0) + 0.09 * sin(tick + UV.x * 41.0);
	float flame = (1.0 - smoothstep(width * 0.70, width, abs(x))) * (1.0 - smoothstep(tips - 0.17, tips, y));
	float core = (1.0 - smoothstep(width * 0.31, width * 0.53, abs(x))) * (1.0 - smoothstep(0.22, 0.62, y));
	float flicker = 0.92 + 0.08 * sin(tick * 1.7);
	ALBEDO = mix(vec3(1.22, 0.14, 0.018), vec3(2.1, 0.94, 0.18), core);
	ALPHA = flame * flicker * smoothstep(0.0, 0.12, y) * 0.78;
}
