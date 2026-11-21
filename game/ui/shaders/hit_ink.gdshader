// 움직임 시험(?anim=a·c): 맞을 때 붉은 잉크 번짐 — 그림 위쪽부터 진홍 잉크가 스며 내려갔다가 빠진다.
// 그림의 명암은 남기고 색만 진홍(그림체의 유일한 선명한 색)으로 물들인다. COLOR = 텍스처 × modulate 이라 기존 색조(tint·쓰러짐 회색)도 그대로.
shader_type canvas_item;
uniform float amount = 0.0;   // 0~1 세기
uniform float front = 1.0;    // 잉크가 내려온 곳 (인물 높이 비율: 0 위 ~ 1 아래)
uniform float v0 = 0.0;       // 이 그림의 위·아래 끝 (인물 전체 높이 비율 — 부위 그림(C)이면 부위마다 다르다)
uniform float v1 = 1.0;
uniform vec4 ink : source_color = vec4(0.55, 0.02, 0.06, 1.0);

void fragment() {
	vec4 c = COLOR;
	float fy = mix(v0, v1, UV.y);
	float wet = 1.0 - smoothstep(front - 0.2, front + 0.02, fy);
	float k = clamp(amount * (0.25 + 0.75 * wet), 0.0, 1.0);
	float lum = dot(c.rgb, vec3(0.3, 0.55, 0.15));
	c.rgb = mix(c.rgb, ink.rgb * (0.45 + 1.25 * lum), k);
	COLOR = c;
}
