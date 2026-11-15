// 컷인 띠: 화면을 가로지르는 기울어진 띠 안에서만 보이게 (CSS clip-path 대신)
// 그림의 화면 위치를 uniform 으로 받아 UV 로 화면 좌표를 계산한다 (Compatibility 렌더러에서도 같은 결과)
// mid: 띠 가운데 y / half_h: 띠 높이의 절반(열림 정도) / slant: 기울기(왼쪽이 이만큼 아래) / r0·rsize: 이 그림의 화면 사각형
shader_type canvas_item;
uniform float mid = 510.0;
uniform float half_h = 210.0;
uniform float slant = 70.0;
uniform vec2 r0 = vec2(0.0);
uniform vec2 rsize = vec2(1920.0, 1080.0);

void fragment() {
	vec2 world = r0 + UV * rsize;
	float c = mid + slant * 0.5 - slant * (world.x / 1920.0);
	float d = abs(world.y - c);
	float inside = 1.0 - smoothstep(half_h - 1.5, half_h + 1.5, d);
	vec4 col = texture(TEXTURE, UV) * COLOR;
	col.a *= inside;
	COLOR = col;
}
