// 카드 프레임·그림 색 바꾸기 (HTML 판 CSS filter 를 흉내 낸다)
// mode 1: 흑백(유품) / 2: 검붉게 어둡게(죽음 카드) / 3: 붉게(상속 카드)
shader_type canvas_item;
uniform int mode = 0;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	if (mode == 1) {
		c.rgb = vec3(l);
	} else if (mode == 2) {
		c.rgb = vec3(l * 0.62, l * 0.12, l * 0.14);
	} else if (mode == 3) {
		c.rgb = vec3(l * 1.25, l * 0.32, l * 0.3);
	}
	COLOR = c;
}
