shader_type canvas_item;

uniform sampler2D mask;
uniform float scale : hint_range(0.0, 1.0, 0.05);

float ease() {
	return 1.0 - cos((scale * PI) / 2.0);
}

void fragment() {
	float s = scale * 80.0 * ease();
	int cutoff = int(s / 80.0);
	vec2 offset = vec2(0.5, 0.5) * (1.0 - s);
	vec4 mask_color = texture(mask, UV * s + offset);
	COLOR.a = 1.0 - mask_color.a + float(cutoff);
}