// 3D 탁자 바닥 판 (전투 시험판 v2.1 — ui/board_table.gd). 돌판 그림(art/raw/vs_f/75)에 위쪽에서 비추는 은은한 빛 웅덩이를 곱한다.
// 실제 조명·그림자 없이(unshaded) 가운데는 밝고 가장자리로 갈수록 어둡다 → 탁자 너머는 어둠(배경 검정).
shader_type spatial;
render_mode unshaded;

uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform vec2 light_center = vec2(0.5, 0.5);
uniform vec2 light_size = vec2(0.55, 0.62);
uniform float bright = 1.18;
uniform float ambient = 0.38;

void fragment() {
	vec3 c = texture(tex, UV).rgb;
	vec2 d = (UV - light_center) / light_size;
	float l = mix(bright, ambient, smoothstep(0.35, 1.15, length(d)));
	ALBEDO = c * l;
}
