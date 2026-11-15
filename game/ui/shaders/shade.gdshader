// 거대 존재의 그림자: 그림 모양 그대로의 검은 덮개. 화면 위쪽일수록 짙다(그림자 레이어와 같은 세로 그라데이션).
// (발이 동료 뒤에 있어도 그림자는 동료 위에 드리워진다)
shader_type canvas_item;
uniform float opacity = 0.0;
varying float world_y;

void vertex() {
	world_y = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).y;
}

float mask(float y) {
	float t = y / 1080.0;
	if (t < 0.26) return mix(0.97, 0.9, t / 0.26);
	if (t < 0.46) return mix(0.9, 0.62, (t - 0.26) / 0.2);
	if (t < 0.62) return mix(0.62, 0.25, (t - 0.46) / 0.16);
	if (t < 0.78) return mix(0.25, 0.0, (t - 0.62) / 0.16);
	return 0.0;
}

void fragment() {
	float a = texture(TEXTURE, UV).a;
	COLOR = vec4(0.008, 0.008, 0.024, a * mask(world_y) * opacity);
}
