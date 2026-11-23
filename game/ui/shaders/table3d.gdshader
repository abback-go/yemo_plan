// 3D 탁자 바닥 판 (전투 시험판 v2.1 — ui/board_table.gd). 돌판 그림(art/raw/vs_f/75)에 위쪽에서 비추는 은은한 빛 웅덩이를 곱한다.
// 실제 조명·그림자 없이(unshaded) 가운데는 밝고 가장자리로 갈수록 어둡다 → 탁자 너머는 어둠(배경 검정).
// 밤샘 계획 2 A(1층 전투): room_on 이면 그 방의 VN 배경을 화면 좌표로 어둡게 겹친다 — 화면 위쪽(탁자 너머, 적 줄 뒤)은 진하게, 아래로 갈수록 옅게.
shader_type spatial;
render_mode unshaded;

uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform vec2 light_center = vec2(0.5, 0.5);
uniform vec2 light_size = vec2(0.55, 0.62);
uniform float bright = 1.18;
uniform float ambient = 0.38;
uniform sampler2D room : source_color, filter_linear;
uniform float room_on = 0.0;
uniform float room_top = 0.6;     // 화면 맨 위에서 방 그림이 비치는 정도
uniform float room_base = 0.06;   // 탁자 전체에 옅게
uniform float room_fade = 0.33;   // 화면 위에서 이 높이(비율)까지 옅어진다
uniform float room_dim = 0.55;    // 방 그림 밝기

void fragment() {
	vec3 c = texture(tex, UV).rgb;
	vec2 d = (UV - light_center) / light_size;
	float l = mix(bright, ambient, smoothstep(0.35, 1.15, length(d)));
	vec3 col = c * l;
	if (room_on > 0.5) {
		vec3 r = texture(room, SCREEN_UV).rgb * room_dim;
		float k = mix(room_top, room_base, smoothstep(0.0, room_fade, SCREEN_UV.y));
		col = mix(col, r, k);
	}
	ALBEDO = col;
}
