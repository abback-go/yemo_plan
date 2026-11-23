// 흐린 카드: 누구인지 알아볼 수 없을 만큼 번진 그림 (빈 캠프의 다음 죽음 카드)
shader_type canvas_item;
uniform float amount = 1.0;

void fragment() {
	vec2 r = vec2(0.035, 0.024) * amount;
	vec4 acc = vec4(0.0);
	float wsum = 0.0;
	for (int i = -3; i <= 3; i++) {
		for (int j = -3; j <= 3; j++) {
			float w = 1.0 / (1.0 + float(i * i + j * j));
			acc += texture(TEXTURE, UV + vec2(float(i), float(j)) * r) * w;
			wsum += w;
		}
	}
	vec4 c = acc / wsum;
	COLOR = c * COLOR;
}
