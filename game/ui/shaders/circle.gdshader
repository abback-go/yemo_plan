// 둥근 얼굴(마녀 HP 판·탐색 화면 초상): 그림을 원 안으로 자르고 가장자리를 부드럽게
shader_type canvas_item;
uniform float gray = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float d = distance(UV, vec2(0.5));
	c.a *= 1.0 - smoothstep(0.48, 0.5, d);
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(c.rgb, vec3(l) * 0.6, gray);
	COLOR = c;
}
