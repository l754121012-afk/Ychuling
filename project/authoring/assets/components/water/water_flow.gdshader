shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled;

uniform vec4 water_color : source_color = vec4(0.08, 0.42, 0.58, 0.72);
uniform vec4 foam_color : source_color = vec4(0.76, 0.94, 1.0, 0.88);
uniform float flow_speed = 0.35;
uniform float band_scale = 9.0;
uniform float foam_amount = 0.28;

void fragment() {
	float t = TIME * flow_speed;
	float wave_a = sin((UV.y - t) * band_scale + sin(UV.x * 10.0) * 1.2);
	float wave_b = sin((UV.y * 1.7 + t * 1.4) * band_scale * 0.6 + UV.x * 18.0);
	float waves = wave_a * 0.5 + wave_b * 0.5;
	float foam = smoothstep(0.32, 0.96, waves + foam_amount);
	vec4 mixed = mix(water_color, foam_color, foam * 0.6);
	ALBEDO = mixed.rgb;
	ALPHA = mixed.a;
	ROUGHNESS = 0.22;
	METALLIC = 0.0;
	EMISSION = foam_color.rgb * foam * 0.18;
}
