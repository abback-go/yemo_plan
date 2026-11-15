// 용사 파티 탐험 틀 시안 — 땅 한 장 (PtField). map_tex = 칸 지도(56×36, R = 칸 종류 ÷ 10) — 스프라이트 텍스처와 같은 것을 16배로 키워 맵 전체를 덮는다.
// (TEXTURE는 fragment() 밖 함수에서 못 써서 같은 텍스처를 uniform으로 한 번 더 받는다)
// 칸 종류: 0 풀 · 1 꽃 핀 풀 · 2 흙길 · 3 돌바닥(유적 광장) · 4 물 · 5 숲 바닥.
// 화면 1px = 맵 1px (640×360 설계 화면)이라 맵 좌표를 정수로 잘라 픽셀 그림처럼 칠한다. 경계는 잡음으로 흔들어 칸 모양이 보이지 않게.
// 고정 탑다운 3/4 시점: 물 위쪽 물가(땅이 물보다 위)는 땅의 앞면(절벽 6px)이 보이고, 아래쪽 물가는 땅 가장자리 + 물거품만.
shader_type canvas_item;

uniform sampler2D map_tex : filter_nearest;
uniform vec2 tiles = vec2(56.0, 36.0);
uniform vec2 plaza_c = vec2(200.0, 420.0); // 광장 가운데 (맵 px) — 새긴 원
const float TS = 16.0;

const vec3 GR[6] = vec3[6](vec3(0.122, 0.227, 0.165), vec3(0.165, 0.302, 0.200), vec3(0.208, 0.380, 0.251), vec3(0.263, 0.471, 0.290), vec3(0.353, 0.569, 0.333), vec3(0.475, 0.671, 0.384));
const vec3 FO[3] = vec3[3](vec3(0.078, 0.133, 0.094), vec3(0.106, 0.180, 0.125), vec3(0.141, 0.227, 0.157));
const vec3 DI[4] = vec3[4](vec3(0.290, 0.212, 0.157), vec3(0.369, 0.275, 0.196), vec3(0.455, 0.345, 0.243), vec3(0.549, 0.424, 0.290));
const vec3 ST[5] = vec3[5](vec3(0.365, 0.329, 0.275), vec3(0.471, 0.424, 0.345), vec3(0.576, 0.522, 0.424), vec3(0.671, 0.612, 0.494), vec3(0.769, 0.702, 0.569));
const vec3 MORTAR = vec3(0.227, 0.204, 0.173);
const vec3 WA[5] = vec3[5](vec3(0.059, 0.243, 0.322), vec3(0.090, 0.376, 0.478), vec3(0.165, 0.541, 0.573), vec3(0.310, 0.702, 0.667), vec3(0.714, 0.918, 0.847));
const vec3 BK[3] = vec3[3](vec3(0.173, 0.129, 0.106), vec3(0.275, 0.204, 0.165), vec3(0.369, 0.275, 0.212));
const vec3 RT[3] = vec3[3](vec3(0.180, 0.110, 0.078), vec3(0.306, 0.188, 0.125), vec3(0.439, 0.275, 0.173));
const vec3 FLOWER = vec3(0.345, 0.784, 1.0);
const vec3 GLOW = vec3(0.20, 0.45, 0.60);
const vec3 GROOVE = vec3(0.30, 0.25, 0.18);
const vec3 GILT = vec3(0.91, 0.75, 0.31);
const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

float hash(vec2 p) {
	p = fract(p * vec2(0.1031, 0.1030));
	p += dot(p, p.yx + 33.33);
	return fract((p.x + p.y) * p.x);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * vnoise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v / 0.875;
}

float bay(vec2 p) {
	return (BAYER[int(mod(p.y, 4.0)) * 4 + int(mod(p.x, 4.0))] + 0.5) / 16.0;
}

int tile_at(vec2 q) {
	ivec2 t = clamp(ivec2(floor(q / TS)), ivec2(0), ivec2(tiles) - 1);
	return int(texelFetch(map_tex, t, 0).r * 10.0 + 0.5);
}

// 흔들린 경계의 칸 종류 (모든 판정이 같은 흔들림을 써야 물가 절벽·거품이 경계와 맞는다)
int mat(vec2 p) {
	vec2 j = vec2(vnoise(p * 0.13), vnoise(p * 0.13 + 19.7)) * 2.0 - 1.0;
	return tile_at(p + j * 4.5);
}

bool wet(vec2 p) {
	return mat(p) == 4;
}

void fragment() {
	vec2 p = floor(UV * tiles * TS);
	int m = mat(p);
	float d = bay(p);
	vec3 c;
	if (m == 4) {
		int up = 0; // 위로 몇 px에 땅이 있나 (물가 절벽)
		for (int i = 1; i <= 6; i++) {
			if (!wet(p - vec2(0.0, float(i)))) {
				up = i;
				break;
			}
		}
		if (up > 0) {
			float t = float(up) / 6.0;
			int k = clamp(int(floor((1.0 - t) * 2.0 + d)), 0, 2);
			c = BK[k];
			if (hash(vec2(p.x, floor((p.y + hash(vec2(p.x, 7.0)) * 5.0) / 3.0))) > 0.7) c = BK[max(k - 1, 0)]; // 세로 결
			if (up == 1) c = BK[2] * 1.12; // 절벽 윗선
			if (up == 6) c = mix(WA[2], WA[4], 0.55); // 절벽 밑 물거품
		} else {
			float land = 0.0;
			for (int i = 0; i < 4; i++) {
				float a = float(i) * 1.5708;
				vec2 dir = vec2(cos(a), sin(a));
				if (!wet(p + dir * 9.0)) land += 1.0;
				if (!wet(p + dir * 18.0)) land += 0.5;
			}
			float sh = clamp(land / 4.0, 0.0, 1.0) + (fbm(p * 0.05) - 0.5) * 0.4;
			c = WA[clamp(int(floor(sh * 2.0 + d)), 0, 2)];
			float w = sin(p.x * 0.18 + p.y * 0.05 + TIME * 1.3 + sin(p.y * 0.21 + TIME * 0.7) * 2.0);
			if (w > 0.92 && vnoise(vec2(p.x * 0.08 + TIME * 0.4, p.y * 0.35)) > 0.55) c = WA[3]; // 물결
			if (hash(floor(p / 2.0) + floor(TIME * 3.0)) > 0.997) c = WA[4]; // 반짝임
			if (!wet(p + vec2(0.0, 1.0)) || !wet(p + vec2(0.0, 2.0))) c = mix(c, WA[4], 0.8); // 아래 물가 거품
			else if (!wet(p + vec2(1.0, 0.0)) || !wet(p - vec2(1.0, 0.0))) c = mix(c, WA[3], 0.6);
		}
	} else if (m == 3) {
		float row = floor(p.y / 12.0);
		float sx = p.x + mod(row, 2.0) * 9.0;
		vec2 cell = vec2(floor(sx / 18.0), row);
		vec2 f = vec2(mod(sx, 18.0), mod(p.y, 12.0));
		float hs = hash(cell * 1.7 + 3.1);
		if (f.x < 1.0 || f.y < 1.0) {
			c = vnoise(p * 0.1) > 0.62 ? GR[1] : MORTAR; // 틈의 이끼
		} else {
			float v = 0.35 + hs * 0.35 + (fbm(p * 0.09) - 0.5) * 0.3;
			if (f.y < 2.0 || f.x < 2.0) v += 0.18; // 왼쪽 위 밝은 모서리
			if (f.y > 10.0 || f.x > 16.0) v -= 0.18;
			c = ST[clamp(int(floor(v * 4.0 + d)), 0, 4)];
			if (hs > 0.93 && f.y > 3.0 && f.y < 9.0 && abs(f.x - 3.0 - f.y * 0.9 - hash(cell) * 6.0) < 0.6) c = MORTAR; // 짧은 금 (돌 몇 개에만)
		}
		float rr = length(p - plaza_c); // 새긴 원 두 겹 + 살 8개
		float an = atan(p.y - plaza_c.y, p.x - plaza_c.x);
		float spoke = abs(fract(an / 0.7854 + 0.5) - 0.5) * rr;
		if (abs(rr - 40.0) < 0.7 || abs(rr - 32.0) < 0.7 || (rr > 32.0 && rr < 40.0 && spoke < 0.7)) {
			c = hash(p) > 0.55 ? GILT : GROOVE;
		}
		if (rr < 4.0) c = GILT;
		if (mat(p + vec2(0.0, 3.0)) != 3 || mat(p - vec2(0.0, 3.0)) != 3 || mat(p + vec2(3.0, 0.0)) != 3 || mat(p - vec2(3.0, 0.0)) != 3) {
			if (vnoise(p * 0.2) > 0.4) c = mix(c, GR[2], 0.7); // 광장 가장자리를 덮는 풀
		}
	} else if (m == 2) {
		float v = fbm(p * 0.07) + (hash(p) - 0.5) * 0.1;
		c = DI[clamp(int(floor(v * 3.0 + d)), 0, 3)];
		if (hash(p * 1.3) > 0.975) c = DI[3] * 1.15; // 자갈
		if (hash(p + 3.0) > 0.9 && (mat(p + vec2(0.0, 3.0)) != 2 || mat(p - vec2(0.0, 3.0)) != 2)) c = GR[3]; // 길가 풀
	} else {
		float v = fbm(p * 0.03) * 0.8 + fbm(p * 0.11) * 0.35 - 0.1;
		int k;
		if (m == 5) {
			k = clamp(int(floor(v * 2.0 + d)), 0, 2);
			c = FO[k];
			if (hash(p) > 0.95) c = vec3(0.30, 0.16, 0.10); // 낙엽
		} else {
			k = clamp(int(floor(v * 4.0 + d)) + 1, 1, 4);
			c = GR[k];
			if (hash(p) > 0.93 || (hash(p + vec2(0.0, 1.0)) > 0.93)) c = GR[min(k + 1, 5)]; // 풀잎 (2px)
		}
		if (m == 1) { // 빛나는 파란 꽃
			vec2 cell = floor(p / 10.0);
			vec2 fc = cell * 10.0 + 3.0 + floor(vec2(hash(cell + 1.0), hash(cell + 2.0)) * 4.0);
			vec2 dd = p - fc;
			if (hash(cell + 7.0) > 0.68) {
				float g = 1.0 - length(dd) / 4.0;
				if (g > 0.0) c += GLOW * g * 0.3;
				if (abs(dd.x) + abs(dd.y) <= 1.0) c = FLOWER;
				if (dd == vec2(0.0)) c = vec3(0.92, 1.0, 1.0);
			}
		}
		if (m != 5 && fbm(p * 0.012 + 40.0) > 0.62) { // 땅 위를 기는 뿌리 (가는 줄만)
			float r2 = abs(vnoise(p * 0.03) + vnoise(p * 0.07) * 0.35 - 0.67);
			if (r2 < 0.012) c = RT[2];
			else if (r2 < 0.022) c = RT[0];
		}
	}
	if (m != 4 && wet(p + vec2(0.0, 1.0))) c *= 0.62; // 물가 절벽 위 땅 가장자리
	COLOR = vec4(c, 1.0);
}
