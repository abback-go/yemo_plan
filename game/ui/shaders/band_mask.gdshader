// 컷인 띠: 화면을 가로지르는 기울어진 띠 안에서만 보이게 (CSS clip-path 대신)
// mid: 띠 가운데 y / half: 띠 높이의 절반(열림 정도 반영) / slant: 기울기(왼쪽이 이만큼 아래)
shader_type canvas_item;
uniform float mid = 510.0;
uniform float half_h = 210.0;
uniform float slant = 70.0;
varying vec2 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float c = mid + slant * 0.5 - slant * (world.x / 1920.0);
	float d = abs(world.y - c);
	float inside = 1.0 - smoothstep(half_h - 1.5, half_h + 1.5, d);
	vec4 col = texture(TEXTURE, UV) * COLOR;
	col.a *= inside;
	COLOR = col;
}
