// 카드 밑 그림자 (전투 시험판 v2.1 — ui/board_table.gd). 실시간 그림자 대신 둥근 사각형 모양으로 번진 검은 판.
// 카드가 들리면 옅어지고 넓어진다(코드가 strength·spread 를 바꾼다).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;

uniform float strength = 0.55;
uniform float soft = 0.12;   // 판 UV 에서 번지는 띠의 몫

void fragment() {
	vec2 p = abs(UV - vec2(0.5)) * 2.0;           // 0 = 가운데, 1 = 가장자리
	vec2 k = vec2(1.0) - vec2(soft * 2.0, soft * 2.0 / 1.5);
	vec2 q = max(vec2(0.0), p - k) / max(vec2(0.0001), vec2(1.0) - k);
	float a = 1.0 - smoothstep(0.0, 1.0, length(q));
	ALBEDO = vec3(0.0);
	ALPHA = a * strength;
}
