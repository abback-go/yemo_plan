// 탁자 위 3D 카드 한 장 (전투 시험판 v2.1 — ui/board_table.gd). 빛 계산 없이(unshaded) 앞면·뒷면 그림을 붙인 얇은 판.
// 판은 카드보다 margin 만큼 크고, 그 바깥 띠에는 고를 수 있음·노려짐 테두리 빛(glow)을 그린다(실시간 그림자·후처리 없음 — 웹 WebGL 2).
// 앞면은 카드 앞면 뷰포트(투명 바탕 — 틀 바깥 둥근 모서리), 뒷면은 카드 뒷면 그림(좌우를 뒤집어 붙임).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;

uniform sampler2D front : source_color, filter_linear;
uniform sampler2D back : source_color, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 back_tint : source_color = vec4(1.0);
uniform vec4 glow_color : source_color = vec4(1.0, 0.78, 0.38, 1.0);
uniform float glow = 0.0;
uniform float flash = 0.0;          // 맞았을 때 붉게
uniform float alpha = 1.0;
uniform vec2 margin = vec2(0.1, 0.0667);   // 판 UV 에서 빛 띠의 몫(가로·세로)

void fragment() {
	vec2 uv = (UV - margin) / (vec2(1.0) - 2.0 * margin);
	vec4 c = vec4(0.0);
	if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) {
		if (FRONT_FACING) {
			c = texture(front, uv) * tint;
		} else {
			c = texture(back, vec2(1.0 - uv.x, uv.y)) * back_tint;
		}
	}
	c.rgb = mix(c.rgb, vec3(1.0, 0.1, 0.12), flash * c.a * 0.6);
	// 카드 바깥(또는 투명한 모서리) 빛: 카드 사각형까지의 거리로 옅어진다
	vec2 q = max(vec2(0.0), max(-uv, uv - vec2(1.0)));
	float d = length(q * vec2(1.0, 1.5));
	float g = glow * (1.0 - smoothstep(0.0, margin.x * 0.9, d)) * (0.75 + 0.25 * sin(TIME * 4.0));
	float a = c.a + g * (1.0 - c.a);
	vec3 col = (c.rgb * c.a + glow_color.rgb * g * (1.0 - c.a)) / max(a, 0.001);
	ALBEDO = col;
	ALPHA = a * alpha;
}
