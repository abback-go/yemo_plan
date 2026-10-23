extends Node3D
## 2.5D 헥스 지도 시안 — 마녀성으로 가는 길 (2026-10-23 사용자: 성 그림을 주며 "이 성의 느낌을 거의 비슷하게"). 주소 끝 ?hex3d.
## 걷는 곳: 횃불·깃발이 선 돌 테라스 → 아치 다리 → 폭포가 떨어지는 떠 있는 섬의 계단길 → 성문 앞 광장.
## 둘레(H3Castle): 고딕 마녀성(첨탑 · 불 켜진 창 · 스테인드글라스 · 성문) · 떠 있는 섬들 · 보라 밤하늘(달 · 소용돌이) · 구름 바다 · 비룡.
## 헥스 격자는 평소 숨기고 커서·발밑·목적지만 보인다 (G로 전체 격자). 테라스·다리 칸은 돌 구조물이 그려 주고 칸은 걷기 판정만 한다.
## 조작: 누르기 = 그 칸으로 걸어감 · 휠 = 확대·축소 · 왼쪽 끌기 = 지도 이동 · 오른쪽 끌기 = 회전·기울기 · Q/E 회전 · R 복원 · G 격자 · Esc 타이틀.
## 폰(시험용): 끌기 = 이동, 오른쪽 버튼(↺ ↻ + - 복원 격자)으로 회전·확대·복원·격자.
## 그림은 코드 픽셀 그림(H3Art) — 에스카만 사용자 AI 그림(대기·걷기는 그 그림을 줄마다 1~2px 밀어 만든 8장).

const S := 1.0 ## 헥스 반지름 (뾰족 위)
const LH := 0.9 ## 높이 한 층
const W := 36 ## 열
const H := 32 ## 줄
const PX := 1.0 / 32.0 ## 소품 스프라이트 1px 크기
const BASE := Vector2i(960, 540) ## 이 장면의 설계 해상도 (3D를 이 크기로 그려 키움 → 픽셀 느낌)
const WATER_DROP := 0.45 ## 물 칸 바닥 깊이
const WATER_SURF := 0.14 ## 물 칸 수면 (층 높이 아래)
const SEA_Y := -11.0 ## 구름 바다 높이
const CLIFF_BOTTOM := -4.0 ## 섬 절벽 아래 끝 (변마다 0~3 더 내려감 → 들쭉날쭉. 그 밑은 바위 뿌리)
## 모서리 i(각 60i−30°)와 i+1 사이 변이 바라보는 이웃 (축 좌표)
const EDGE := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1)]
## 배치 (세계 x · z). 카메라는 테라스 쪽(앞 왼쪽)에서 성(뒤 오른쪽)을 본다
const TERRACE := Rect2(2, 33, 15, 9)
const BRIDGE_A := Vector2(15.5, 36.0)
const BRIDGE_B := Vector2(31.5, 24.0)
const BRIDGE_W := 3.4
const ISLAND_C := Vector2(39, 15.5)
const ISLAND_R := Vector2(13.5, 10.5)
const PLAZA := Rect2(32, -1.2, 13, 10)
const ROAD := [Vector2(30.5, 25.0), Vector2(34, 21.5), Vector2(36.5, 18), Vector2(38.5, 13.5), Vector2(38.5, 8.5)]
const STREAMS := [[Vector2(44, 13.5), Vector2(48, 14.2), Vector2(53.5, 15)], [Vector2(43, 20.5), Vector2(45.5, 24), Vector2(48.5, 28)]]
const CASTLE := Vector3(38.5, 2.7, -12.0) ## 성 가운데 바닥 (광장 높이 = 3층)

var tiles := {} ## 축 좌표 Vector2i → {lv, water, path, deck, depth}
var cam: Camera3D
var yaw := 0.0
var pitch := deg_to_rad(13.0)
var dist := 26.0
var target := Vector3.ZERO
var follow := true
var _yaw_goal := 0.0
var _t := 0.0

var eska: Sprite3D
var eska_shadow: MeshInstance3D
var here := Vector2i.ZERO
var path: Array = []
var step_t := 0.0
var _walk_t := 0.0
var hover := Vector2i(9999, 9999)
var cursor: MeshInstance3D
var marker: MeshInstance3D
var goal_ring: MeshInstance3D
var grid: MeshInstance3D
var flames: Array = [] ## [Sprite3D, 위상]
var lights: Array = [] ## [OmniLight3D, 기본 세기, 위상]
var banners: Array = []
var dragons: Array = []
var cliff_falls: Array = [] ## 성 바위에서 떨어지는 폭포 자리 [시작, 끝, 바깥 방향] (_mass가 고름)
var _press := Vector2.ZERO
var _press_btn := 0
var _dragging := false
var _scale_was: Array = []
var hud: Control


func _ready() -> void:
	var win := get_tree().root
	_scale_was = [win.content_scale_size, win.content_scale_stretch, win.content_scale_aspect]
	win.content_scale_size = BASE
	win.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	_gen_map()
	_build_env()
	_build_terrain()
	_build_deck()
	_build_water()
	_build_falls()
	H3Castle.build_castle(self, CASTLE)
	H3Castle.build_islands(self)
	H3Castle.build_clouds(self, SEA_Y, [Vector3(23, SEA_Y + 1.5, 30), Vector3(39, SEA_Y + 1.0, 16), Vector3(9, SEA_Y + 3.0, 38), Vector3(52, SEA_Y + 1.0, 18), Vector3(38, SEA_Y + 1.0, -16)])
	dragons = H3Castle.build_dragons(self, CASTLE)
	_build_props()
	_build_markers()
	_build_eska()
	_build_hud()
	_reset_view()


func _exit_tree() -> void:
	TTheme.release()
	if not _scale_was.is_empty():
		var win := get_tree().root
		win.content_scale_size = _scale_was[0]
		win.content_scale_stretch = _scale_was[1]
		win.content_scale_aspect = _scale_was[2]


# ─── 좌표 ───────────────────────────────────────────

static func to_axial(col: int, row: int) -> Vector2i:
	return Vector2i(col - (row - (row & 1)) / 2, row)


static func wpos(a: Vector2i) -> Vector3:
	return Vector3(sqrt(3.0) * (float(a.x) + float(a.y) * 0.5) * S, 0.0, 1.5 * float(a.y) * S)


static func corner(i: int) -> Vector3:
	var ang := deg_to_rad(60.0 * float(i) - 30.0)
	return Vector3(cos(ang), 0.0, sin(ang)) * S


## 칸 a의 모서리 i (세계 좌표, 흔들림 포함). 이웃 칸과 공유하는 모서리는 같은 자리에서 같은 만큼 흔들린다
static func cw(a: Vector2i, i: int) -> Vector3:
	var p := wpos(a) + corner(i)
	var kx := roundf(p.x * 100.0)
	var kz := roundf(p.z * 100.0)
	var h1 := fposmod(sin(kx * 0.12989 + kz * 0.78233) * 43758.5453, 1.0)
	var h2 := fposmod(sin(kx * 0.39346 + kz * 0.11135) * 24634.6345, 1.0)
	return p + Vector3(h1 - 0.5, 0.0, h2 - 0.5) * (S * 0.55)


func top_y(a: Vector2i) -> float:
	var t: Dictionary = tiles[a]
	return float(t.lv) * LH - (WATER_DROP if bool(t.water) else 0.0)


func stand_y(a: Vector2i) -> float:
	var t: Dictionary = tiles[a]
	return float(t.lv) * LH - (WATER_SURF if bool(t.water) else 0.0)


static func hex_round(q: float, r: float) -> Vector2i:
	var x := q
	var z := r
	var y := -x - z
	var rx := roundf(x)
	var ry := roundf(y)
	var rz := roundf(z)
	var dx := absf(rx - x)
	var dy := absf(ry - y)
	var dz := absf(rz - z)
	if dx > dy and dx > dz:
		rx = -ry - rz
	elif dy <= dz:
		rz = -rx - ry
	return Vector2i(int(rx), int(rz))


static func pixel_to_hex(x: float, z: float) -> Vector2i:
	return hex_round((sqrt(3.0) / 3.0 * x - z / 3.0) / S, (2.0 / 3.0 * z) / S)


static func _seg_dist(p: Vector2, pts: Array) -> float:
	var best := INF
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var ab := b - a
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		best = minf(best, p.distance_to(a + ab * t))
	return best


# ─── 지도 (걷는 칸) ─────────────────────────────────

## 섬은 성 쪽(뒤)으로 갈수록 한 층씩 높아진다 (계단길은 흔들지 않아 한 층씩 오름)
func _island_lv(x: float, z: float) -> int:
	if z > 22.5:
		return 0
	if z > 18.5:
		return 1
	if z > 14.0:
		return 2
	return 3


func _gen_map() -> void:
	var n := FastNoiseLite.new()
	n.seed = 5
	n.frequency = 0.3
	for row in H:
		for col in W:
			var a := to_axial(col, row)
			var p := wpos(a)
			var v := Vector2(p.x, p.z)
			var deck := TERRACE.grow(-0.5).has_point(v) or _seg_dist(v, [BRIDGE_A, BRIDGE_B]) < BRIDGE_W * 0.5 - 0.25
			if deck:
				tiles[a] = {"lv": 0, "water": false, "path": true, "deck": true, "depth": 0}
				continue
			if PLAZA.has_point(v):
				tiles[a] = {"lv": 3, "water": false, "path": true, "deck": false, "depth": 0}
				continue
			var e := Vector2((p.x - ISLAND_C.x) / ISLAND_R.x, (p.z - ISLAND_C.y) / ISLAND_R.y)
			if e.length() + n.get_noise_2d(p.x, p.z) * 0.12 > 1.0:
				continue
			var road := _seg_dist(v, ROAD) < 0.95
			var lv := _island_lv(p.x, p.z) if road else _island_lv(p.x, p.z + n.get_noise_2d(p.x * 1.7, p.z * 1.7) * 1.4)
			var water := false
			if not road:
				for s: Array in STREAMS:
					if _seg_dist(v, s) < 0.8:
						water = true
			tiles[a] = {"lv": lv, "water": water, "path": road, "deck": false, "depth": 0}
	for a: Vector2i in tiles: # 물 깊이 (얕은 개울)
		if bool(tiles[a].water):
			tiles[a].depth = 1
	# 시작 칸: 테라스 가운데
	var best := Vector2i.ZERO
	var bd := INF
	for a: Vector2i in tiles:
		var d := Vector2(wpos(a).x, wpos(a).z).distance_to(Vector2(8.5, 38.0))
		if d < bd:
			bd = d
			best = a
	here = best


func can_step(a: Vector2i, b: Vector2i) -> bool:
	if not tiles.has(b) or bool(tiles[b].water):
		return false
	var dl := absi(int(tiles[a].lv) - int(tiles[b].lv))
	return dl == 0 or (dl == 1 and bool(tiles[a].path) and bool(tiles[b].path))


func find_path(from: Vector2i, to: Vector2i) -> Array:
	var prev := {from: from}
	var q: Array = [from]
	while not q.is_empty():
		var a: Vector2i = q.pop_front()
		if a == to:
			break
		for d: Vector2i in EDGE:
			var b: Vector2i = a + d
			if not prev.has(b) and can_step(a, b):
				prev[b] = a
				q.append(b)
	if not prev.has(to):
		return []
	var seq: Array = []
	var c := to
	while c != from:
		seq.push_front(c)
		c = prev[c]
	return seq


# ─── 환경 · 빛 ─────────────────────────────────────

func _build_env() -> void:
	var env := Environment.new()
	H3Castle.sky_env(env)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#8a78c0")
	env.ambient_light_energy = 0.75
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.9
	env.fog_enabled = true
	env.fog_light_color = Color("#6a5494")
	env.fog_density = 0.003
	env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var moon := DirectionalLight3D.new() # 달빛: 하늘의 달 쪽(성 오른쪽 뒤)에서 — 오른쪽 면이 밝고 화면 쪽 면은 그늘 (그림처럼 역광)
	moon.light_color = Color("#d6ccff")
	moon.light_energy = 0.85
	moon.basis = Basis.looking_at(Vector3(-0.66, -0.62, 0.42))
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 90.0
	add_child(moon)
	cam = Camera3D.new()
	cam.fov = 44.0
	cam.near = 0.5
	cam.far = 420.0
	add_child(cam)


# ─── 지형 메시 (섬 · 광장) ──────────────────────────

func _top_shader() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform sampler2D moss_tex : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D flag_tex : source_color, filter_nearest_mipmap, repeat_enable;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = wp.xz * 0.5;
	float h = hash(floor(wp.xz * 32.0));
	float w = COLOR.r + (h - 0.5) * 0.45;   // 판석길 비율 (모서리 보간 + 픽셀 얼룩 → 이끼가 비집고 나온 가장자리)
	vec3 c = w > 0.5 ? texture(flag_tex, uv).rgb : texture(moss_tex, uv).rgb;
	float ao = COLOR.g + (h - 0.5) * 0.25;     // 높은 이웃 밑 그늘
	c *= ao < 0.55 ? 0.62 : (ao < 0.8 ? 0.82 : 1.0);
	float rim = COLOR.b + (h - 0.5) * 0.3;     // 낮은 이웃 쪽 입술 빛
	if (rim > 0.82 && w <= 0.5) c = mix(c, vec3(0.42, 0.56, 0.40), 0.5);
	ALBEDO = c;
	ROUGHNESS = 1.0;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("moss_tex", H3Art.moss())
	m.set_shader_parameter("flag_tex", H3Art.flags())
	return m


func _build_terrain() -> void:
	var top := H3Castle.new_st()
	var side := H3Castle.new_st()
	for a: Vector2i in tiles:
		var t: Dictionary = tiles[a]
		if bool(t.deck):
			continue # 테라스·다리는 _build_deck이 그림
		var c := wpos(a)
		var y := top_y(a)
		# 윗면 (모서리 색: r = 판석 비율 · g = 그늘(1 밝음) · b = 입술 빛)
		var cols: Array = []
		for i in 6:
			var pw := (1.0 if bool(t.path) else 0.0)
			var cnt := 1.0
			var ao := 1.0
			var rim := 0.0
			for nb: Vector2i in [a + EDGE[(i + 5) % 6], a + EDGE[i]]:
				if tiles.has(nb):
					pw += 1.0 if bool(tiles[nb].path) and not bool(tiles[nb].deck) else 0.0
					cnt += 1.0
					if top_y(nb) > y + 0.01:
						ao = 0.45
					elif top_y(nb) < y - 0.01:
						rim = 1.0
				else:
					rim = 1.0
			cols.append(Color(pw / cnt, ao, rim))
		var water := bool(t.water)
		for i in 6:
			var j := (i + 1) % 6
			top.set_normal(Vector3.UP)
			top.set_color(Color(0, 0.5, 0) if water else Color(1.0 if bool(t.path) else 0.0, 1.0, 0.0))
			top.add_vertex(c + Vector3(0, y, 0))
			top.set_color(Color(0, 0.5, 0) if water else cols[i])
			top.add_vertex(cw(a, i) + Vector3(0, y, 0))
			top.set_color(Color(0, 0.5, 0) if water else cols[j])
			top.add_vertex(cw(a, j) + Vector3(0, y, 0))
		# 옆면: 이웃이 더 낮으면 그 높이까지, 이웃이 없으면 절벽 아래 끝까지 (변마다 길이가 달라 아래 끝이 들쭉날쭉)
		for i in 6:
			var nb: Vector2i = a + EDGE[i]
			var ny := top_y(nb) if tiles.has(nb) else CLIFF_BOTTOM - fposmod(sin(float(a.x) * 12.9898 + float(a.y) * 78.233 + float(i) * 3.7) * 43758.5453, 1.0) * 3.0
			if ny >= y - 0.01:
				continue
			var p0 := cw(a, i)
			var p1 := cw(a, (i + 1) % 6)
			var u0 := fposmod(float(a.x * 7 + a.y * 13 + i * 3) * 0.37, 1.0)
			var u1 := u0 + S * 0.5
			var v1 := (y - ny) * 0.5
			H3Castle.quad(side, Vector3(p0.x, y, p0.z), Vector3(p1.x, y, p1.z), Vector3(p1.x, ny, p1.z), Vector3(p0.x, ny, p0.z),
				Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, v1), Vector2(u0, v1))
	var mi_top := MeshInstance3D.new()
	mi_top.mesh = top.commit()
	mi_top.material_override = _top_shader()
	add_child(mi_top)
	# 섬 밑 거꾸로 선 바위 · 성이 앉은 바위산 (겹친 들쭉날쭉 덩어리 넷 — 윗면은 판석 마당)
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var rock := H3Castle.new_st()
	_root(rock, ISLAND_C, ISLAND_R * 0.9, CLIFF_BOTTOM + 0.5, 26.0, rng)
	var yard := H3Castle.new_st()
	for m: Array in [[Vector2(CASTLE.x, CASTLE.z - 3.0), 16.5], [Vector2(CASTLE.x - 11.0, CASTLE.z - 13.0), 12.0],
			[Vector2(CASTLE.x + 11.0, CASTLE.z - 13.0), 12.0], [Vector2(CASTLE.x, CASTLE.z - 24.0), 11.0]]:
		_mass(yard, side, rock, m[0], float(m[1]), CASTLE.y - 0.03, rng)
	H3Castle.commit(self, side, H3Castle.mat(H3Art.cliff()))
	H3Castle.commit(self, rock, H3Castle.mat(H3Art.cliff()))
	var ym := MeshInstance3D.new()
	ym.mesh = yard.commit()
	ym.material_override = mi_top.material_override # 같은 세계 좌표 판석 → 겹친 윗면이 깜빡이지 않음
	add_child(ym)


## 들쭉날쭉한 바위 덩어리: 윗면(판석) · 옆 절벽(아래 끝까지) · 밑 거꾸로 선 바위
func _mass(top: SurfaceTool, side: SurfaceTool, rock: SurfaceTool, c: Vector2, r: float, y: float, rng: RandomNumberGenerator) -> void:
	var n := 11
	var pts: Array = []
	for i in n:
		var a := TAU * float(i) / float(n) + rng.randf_range(-0.12, 0.12)
		pts.append(Vector3(c.x + cos(a) * r * rng.randf_range(0.86, 1.08), 0.0, c.y + sin(a) * r * rng.randf_range(0.86, 1.08)))
	var u := 0.0
	for i in n:
		var p0: Vector3 = pts[i]
		var p1: Vector3 = pts[(i + 1) % n]
		top.set_normal(Vector3.UP)
		top.set_color(Color(1, 1, 0))
		top.add_vertex(Vector3(c.x, y, c.y))
		top.add_vertex(Vector3(p1.x, y, p1.z))
		top.add_vertex(Vector3(p0.x, y, p0.z))
		var du := p0.distance_to(p1) * 0.5
		var b0 := CLIFF_BOTTOM - 2.0 - rng.randf() * 3.0
		var v1 := (y - b0) * 0.5
		H3Castle.quad(side, Vector3(p0.x, y, p0.z), Vector3(p1.x, y, p1.z), Vector3(p1.x, b0, p1.z), Vector3(p0.x, b0, p0.z),
			Vector2(u, 0), Vector2(u + du, 0), Vector2(u + du, v1), Vector2(u, v1))
		u += du
		var outv := ((p0 + p1) * 0.5 - Vector3(c.x, 0, c.y)).normalized()
		if du > 1.5 and outv.dot(Vector3(-0.51, 0, 0.86)) > 0.4 and rng.randf() < 0.45: # 시작 시점 쪽 절벽에만 폭포
			cliff_falls.append([p0.lerp(p1, 0.38), p0.lerp(p1, 0.62), outv])
	_root(rock, c, Vector2(r, r) * 0.92, CLIFF_BOTTOM - 1.5, r * 1.9, rng)


## 바위 뿌리: 위는 타원(반지름 rr) → 아래로 불룩했다가 가늘어져 한 점. 테두리가 들쭉날쭉
func _root(st: SurfaceTool, c: Vector2, rr: Vector2, y: float, depth: float, rng: RandomNumberGenerator) -> void:
	var n := 14
	var rings := [[1.0, 0.0], [1.04, 0.18], [0.72, 0.45], [0.36, 0.75]] # [반지름 배율, 깊이 비율]
	var pts: Array = []
	for k in rings.size():
		var ring: Array = []
		for i in n:
			var a := TAU * float(i) / float(n)
			var j := rng.randf_range(0.8, 1.1) if k > 0 else rng.randf_range(0.93, 1.03)
			var f: float = float(rings[k][0]) * j
			ring.append(Vector3(c.x + cos(a) * rr.x * f, y - depth * float(rings[k][1]) - rng.randf() * depth * 0.06 * float(k), c.y + sin(a) * rr.y * f))
		pts.append(ring)
	var tip := Vector3(c.x + rng.randf_range(-1, 1) * rr.x * 0.15, y - depth, c.y + rng.randf_range(-1, 1) * rr.y * 0.15)
	var per := TAU * (rr.x + rr.y) * 0.5 / float(n) * 0.5
	for k in rings.size():
		var r0: Array = pts[k]
		for i in n:
			var j := (i + 1) % n
			var u0 := float(i) * per
			var u1 := float(i + 1) * per
			var v0 := depth * float(rings[k][1]) * 0.5
			if k + 1 < rings.size():
				var r1: Array = pts[k + 1]
				var v1 := depth * float(rings[k + 1][1]) * 0.5
				H3Castle.quad(st, r0[j], r0[i], r1[i], r1[j], Vector2(u1, v0), Vector2(u0, v0), Vector2(u0, v1), Vector2(u1, v1))
			else:
				H3Castle.tri(st, r0[j], r0[i], tip, Vector2(u1, v0), Vector2(u0, v0), Vector2((u0 + u1) * 0.5, depth * 0.5))


# ─── 테라스 · 다리 (돌 구조물) ──────────────────────

func _build_deck() -> void:
	var wall := H3Castle.new_st()
	var flag := H3Castle.new_st()
	var arch := H3Castle.new_st()
	var rail := H3Castle.new_st()
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	# 테라스: 윗면 · 두꺼운 벽(아래로 깊게) · 앞·옆 아치 띠 · 밑 바위
	var tr := TERRACE
	var tc := Vector3(tr.get_center().x, 0, tr.get_center().y)
	H3Castle.box(wall, tc + Vector3(0, -4.0, 0), Vector3(tr.size.x, 8.0, tr.size.y), 0.0, Vector2(2, 2))
	H3Castle.quad(flag, Vector3(tr.position.x, 0.01, tr.position.y), Vector3(tr.end.x, 0.01, tr.position.y), Vector3(tr.end.x, 0.01, tr.end.y), Vector3(tr.position.x, 0.01, tr.end.y),
		Vector2(0, 0), Vector2(tr.size.x * 0.5, 0), Vector2(tr.size.x * 0.5, tr.size.y * 0.5), Vector2(0, tr.size.y * 0.5))
	for k in 3: # 아치 띠 세 줄 (벽에 붙은 장식 아치)
		var y0 := -1.2 - float(k) * 2.4
		H3Castle.quad(arch, Vector3(tr.position.x, y0, tr.end.y + 0.06), Vector3(tr.end.x, y0, tr.end.y + 0.06), Vector3(tr.end.x, y0 - 2.0, tr.end.y + 0.06), Vector3(tr.position.x, y0 - 2.0, tr.end.y + 0.06),
			Vector2(0, 0), Vector2(tr.size.x / 4.0, 0), Vector2(tr.size.x / 4.0, 1), Vector2(0, 1))
		H3Castle.quad(arch, Vector3(tr.position.x - 0.06, y0, tr.position.y), Vector3(tr.position.x - 0.06, y0, tr.end.y), Vector3(tr.position.x - 0.06, y0 - 2.0, tr.end.y), Vector3(tr.position.x - 0.06, y0 - 2.0, tr.position.y),
			Vector2(0, 0), Vector2(tr.size.y / 4.0, 0), Vector2(tr.size.y / 4.0, 1), Vector2(0, 1))
	var rock := H3Castle.new_st()
	_root(rock, Vector2(tc.x, tc.z), tr.size * 0.6, -7.9, 16.0, rng)
	# 다리: 바닥판 · 기둥 · 양옆 아치 띠
	var a3 := Vector3(BRIDGE_A.x, 0, BRIDGE_A.y)
	var b3 := Vector3(BRIDGE_B.x, 0, BRIDGE_B.y)
	var dir := (b3 - a3).normalized()
	var blen := a3.distance_to(b3)
	var rot := -atan2(dir.z, dir.x)
	var side := dir.cross(Vector3.UP).normalized()
	H3Castle.box(wall, (a3 + b3) * 0.5 + Vector3(0, -0.45, 0), Vector3(blen, 0.9, BRIDGE_W), rot, Vector2(2, 2))
	var hw := BRIDGE_W * 0.5
	H3Castle.quad(flag, a3 + side * hw + Vector3(0, 0.01, 0), b3 + side * hw + Vector3(0, 0.01, 0), b3 - side * hw + Vector3(0, 0.01, 0), a3 - side * hw + Vector3(0, 0.01, 0),
		Vector2(0, 0), Vector2(blen * 0.5, 0), Vector2(blen * 0.5, BRIDGE_W * 0.5), Vector2(0, BRIDGE_W * 0.5))
	var piers := int(blen / 4.0)
	for k in range(1, piers + 1):
		var pc := a3 + dir * (float(k) * blen / float(piers + 1))
		H3Castle.box(wall, pc + Vector3(0, (-0.9 + SEA_Y - 2.0) * 0.5, 0), Vector3(1.1, -0.9 - (SEA_Y - 2.0), BRIDGE_W - 0.4), rot, Vector2(2, 2))
	for sgn in [-1.0, 1.0]:
		var o := side * (hw - 0.05) * float(sgn)
		H3Castle.quad(arch, a3 + o + Vector3(0, -0.9, 0), b3 + o + Vector3(0, -0.9, 0), b3 + o + Vector3(0, -3.4, 0), a3 + o + Vector3(0, -3.4, 0),
			Vector2(0, 0), Vector2(blen / 4.0, 0), Vector2(blen / 4.0, 1.25), Vector2(0, 1.25))
	# 난간: 기둥 + 위 손잡이. 테라스는 다리가 붙는 곳을 비움, 다리는 양옆
	var segs: Array = []
	var p00 := Vector3(tr.position.x, 0, tr.position.y)
	var p10 := Vector3(tr.end.x, 0, tr.position.y)
	var p11 := Vector3(tr.end.x, 0, tr.end.y)
	var p01 := Vector3(tr.position.x, 0, tr.end.y)
	segs.append([p00, p10])
	segs.append([p01, p11])
	segs.append([p00, p01])
	segs.append([p10, Vector3(tr.end.x, 0, BRIDGE_A.y - hw - 0.3)]) # 오른쪽 변: 다리 자리 비움
	segs.append([Vector3(tr.end.x, 0, BRIDGE_A.y + hw + 0.3), p11])
	for sgn in [-1.0, 1.0]:
		var o := side * (hw - 0.15) * float(sgn)
		segs.append([a3 + o + dir * 1.6, b3 + o - dir * 0.3])
	for sg: Array in segs:
		var s0: Vector3 = sg[0]
		var s1: Vector3 = sg[1]
		var L := s0.distance_to(s1)
		if L < 0.5:
			continue
		var r2 := -atan2(s1.z - s0.z, s1.x - s0.x)
		var np := maxi(1, int(L / 1.6))
		for k in np + 1:
			var pp := s0.lerp(s1, float(k) / float(np))
			H3Castle.box(rail, pp + Vector3(0, 0.45, 0), Vector3(0.26, 0.9, 0.26), r2, Vector2(2, 2))
		H3Castle.box(rail, (s0 + s1) * 0.5 + Vector3(0, 0.98, 0), Vector3(L, 0.16, 0.34), r2, Vector2(2, 2))
		H3Castle.box(rail, (s0 + s1) * 0.5 + Vector3(0, 0.12, 0), Vector3(L, 0.24, 0.3), r2, Vector2(2, 2))
	var mm := H3Castle.mat(H3Art.masonry())
	H3Castle.commit(self, wall, mm)
	H3Castle.commit(self, rail, mm)
	H3Castle.commit(self, flag, H3Castle.mat(H3Art.flags()))
	H3Castle.commit(self, rock, H3Castle.mat(H3Art.cliff()))
	var am := H3Castle.mat(H3Art.arch_band())
	am.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	H3Castle.commit(self, arch, am)


# ─── 물 · 폭포 ─────────────────────────────────────

func _build_water() -> void:
	var st := H3Castle.new_st()
	for a: Vector2i in tiles:
		var t: Dictionary = tiles[a]
		if not bool(t.water):
			continue
		var c := wpos(a)
		var y := stand_y(a)
		var shore: Array = []
		for i in 6:
			var s := 0.0
			for nb: Vector2i in [a + EDGE[(i + 5) % 6], a + EDGE[i]]:
				if tiles.has(nb) and (not bool(tiles[nb].water) or stand_y(nb) > y + 0.01):
					s = 1.0
			shore.append(s)
		for i in 6:
			var j := (i + 1) % 6
			st.set_normal(Vector3.UP)
			st.set_color(Color(0.0, 0.1, 0.0))
			st.add_vertex(c + Vector3(0, y, 0))
			st.set_color(Color(shore[i], 0.0, 0.0))
			st.add_vertex(cw(a, i) + Vector3(0, y, 0))
			st.set_color(Color(shore[j], 0.0, 0.0))
			st.add_vertex(cw(a, j) + Vector3(0, y, 0))
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, cull_disabled;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 p = floor(wp.xz * 16.0) / 16.0;
	vec3 c = vec3(0.22, 0.42, 0.62);
	float w = sin(p.x * 2.3 + TIME * 1.4 + sin(p.y * 1.7 + TIME) * 2.0) * sin(p.y * 3.1 - TIME * 1.1);
	if (w > 0.7) c = vec3(0.55, 0.72, 0.88);
	else if (w < -0.85) c = vec3(0.16, 0.30, 0.50);
	float h = hash(floor(wp.xz * 32.0));
	float foam = COLOR.r + (h - 0.5) * 0.3 + sin(TIME * 2.2 + p.x * 2.7 + p.y * 1.3) * 0.06;
	if (foam > 0.82) c = vec3(0.86, 0.90, 0.98);
	else if (foam > 0.62) c = mix(c, vec3(0.58, 0.68, 0.90), 0.6);
	ALBEDO = c;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	H3Castle.commit(self, st, m, false)


func _build_falls() -> void:
	var st := H3Castle.new_st()
	var mist_at: Array = []
	for a: Vector2i in tiles:
		if not bool(tiles[a].water):
			continue
		var y := stand_y(a)
		var c := wpos(a)
		for i in 6:
			var nb: Vector2i = a + EDGE[i]
			var ny := SEA_Y # 섬 끝 → 구름 바다까지
			if tiles.has(nb):
				if not bool(tiles[nb].water):
					continue
				ny = stand_y(nb)
				if ny >= y - 0.05:
					continue
			var p0 := cw(a, i)
			var p1 := cw(a, (i + 1) % 6)
			var out := ((p0 + p1) * 0.5 - c).normalized() * 0.08
			for k in 2: # 두 겹 (앞 물줄기 + 살짝 앞으로 흰 물)
				var o := out * float(k + 1)
				var hh := y - ny
				H3Castle.quad(st, Vector3(p0.x, y, p0.z) + o, Vector3(p1.x, y, p1.z) + o, Vector3(p1.x, ny, p1.z) + o * (1.0 + hh * 0.05), Vector3(p0.x, ny, p0.z) + o * (1.0 + hh * 0.05),
					Vector2(0, 0), Vector2(1, 0), Vector2(1, hh), Vector2(0, hh))
			mist_at.append(Vector3(((p0 + p1) * 0.5).x, ny + 0.1, ((p0 + p1) * 0.5).z))
	for f: Array in cliff_falls: # 성 바위 옆구리에서 쏟아지는 폭포 (그림: 성 양옆 폭포)
		var y := CASTLE.y - 1.2
		var hh := y - SEA_Y
		for k in 2:
			var o: Vector3 = f[2] * (0.12 * float(k + 1))
			var p0: Vector3 = f[0] + o
			var p1: Vector3 = f[1] + o
			H3Castle.quad(st, Vector3(p0.x, y, p0.z), Vector3(p1.x, y, p1.z), Vector3(p1.x, SEA_Y, p1.z) + o * hh * 0.04, Vector3(p0.x, SEA_Y, p0.z) + o * hh * 0.04,
				Vector2(0, 0), Vector2(1, 0), Vector2(1, hh), Vector2(0, hh))
		var mid: Vector3 = (f[0] + f[1]) * 0.5
		mist_at.append(Vector3(mid.x, SEA_Y + 0.1, mid.z))
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	float col = floor(UV.x * 24.0);
	float sp = 0.7 + hash(vec2(col, 3.0)) * 0.8;
	float y = floor(UV.y * 32.0 - TIME * 36.0 * sp);
	float s = hash(vec2(col, floor(y / (3.0 + hash(vec2(col, 7.0)) * 6.0))));
	vec3 c = vec3(0.30, 0.46, 0.72);
	if (s > 0.55) c = vec3(0.66, 0.78, 0.95);
	if (s > 0.82) c = vec3(0.94, 0.96, 1.0);
	float edge = min(UV.x, 1.0 - UV.x);
	ALBEDO = c;
	ALPHA = edge < 0.06 ? 0.5 : 0.92;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	H3Castle.commit(self, st, m, false)
	var seen := {}
	for p: Vector3 in mist_at: # 물보라 (가까운 것끼리 하나로)
		var key := Vector2i(int(p.x / 2.0), int(p.z / 2.0))
		if seen.has(key):
			continue
		seen[key] = true
		var pt := CPUParticles3D.new()
		pt.position = p
		pt.amount = 12
		pt.lifetime = 1.4
		pt.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		pt.emission_sphere_radius = 0.8
		pt.direction = Vector3.UP
		pt.spread = 60.0
		pt.initial_velocity_min = 0.4
		pt.initial_velocity_max = 1.1
		pt.gravity = Vector3(0, -0.2, 0)
		pt.scale_amount_min = 0.4
		pt.scale_amount_max = 0.9
		var qm := QuadMesh.new()
		qm.size = Vector2(0.6, 0.6)
		var pm := StandardMaterial3D.new()
		pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		pm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		pm.albedo_color = Color(0.92, 0.9, 1.0, 0.5)
		pm.albedo_texture = H3Art.puff()
		pm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		qm.material = pm
		pt.mesh = qm
		add_child(pt)


# ─── 소품 ───────────────────────────────────────────

func _sprite(tex: Texture2D, at: Vector3, flip := false, px := PX) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = tex
	s.pixel_size = px
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.shaded = false # 그림에 이미 빛·그늘이 그려져 있음
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.offset = Vector2(0, float(tex.get_height()) * 0.5 - 1.0)
	s.flip_h = flip
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	s.position = at
	add_child(s)
	return s


func _blob(at: Vector3, size: float) -> MeshInstance3D:
	var pm := PlaneMesh.new()
	pm.size = Vector2(size, size * 0.6)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = H3Art.shadow()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	pm.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	mi.position = at + Vector3(0, 0.02, 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


## 불꽃 (3장 시트) + 빛. purple = 마녀 등불
func _fire(at: Vector3, purple: bool, scale_px: float, light: float) -> void:
	var s := _sprite(H3Art.flame(purple), at, false, scale_px)
	s.hframes = 3
	s.offset = Vector2(0, 7.0)
	s.modulate = Color(1.4, 1.3, 1.2) # 빛 번짐(glow)에 걸리게 밝게
	flames.append([s, randf() * 10.0])
	if light > 0.0:
		var l := OmniLight3D.new()
		l.light_color = Color("#b070ff") if purple else Color("#ff9a48")
		l.light_energy = light
		l.omni_range = 7.0 if purple else 9.0
		l.position = at + Vector3(0, 0.6, 0)
		add_child(l)
		lights.append([l, light, randf() * 10.0])


## 화로: 돌기둥 + 그릇 + 주황 불
func _brazier(st: SurfaceTool, at: Vector3, light: float) -> void:
	H3Castle.prism(st, at, 0.35, 1.2, 6, Vector2(2, 2))
	H3Castle.prism(st, at + Vector3(0, 1.2, 0), 0.6, 0.35, 6, Vector2(2, 2))
	_fire(at + Vector3(0, 1.5, 0), false, 0.06, light)


## 등불 기둥: 가는 쇠기둥 + 보라 불
func _lamp(st: SurfaceTool, at: Vector3, light: float) -> void:
	H3Castle.box(st, at + Vector3(0, 1.3, 0), Vector3(0.14, 2.6, 0.14), 0.0, Vector2(2, 2))
	H3Castle.box(st, at + Vector3(0, 2.65, 0), Vector3(0.5, 0.12, 0.5), 0.0, Vector2(2, 2))
	_fire(at + Vector3(0, 2.7, 0), true, 0.045, light)


## 깃발 기둥: 높은 고딕 기둥 + 가로대 + 보라 깃발(바람에 흔들림)
func _banner_post(st: SurfaceTool, at: Vector3, face: float) -> void:
	H3Castle.box(st, at + Vector3(0, 3.6, 0), Vector3(0.55, 7.2, 0.55), face, Vector2(2, 2))
	H3Castle.cone(st, at + Vector3(0, 7.2, 0), 0.42, 1.4, 4, Vector2(1, 2))
	var arm := Basis(Vector3.UP, face) * Vector3(1, 0, 0)
	H3Castle.box(st, at + Vector3(0, 6.4, 0) + arm * 0.9, Vector3(1.8, 0.14, 0.14), face, Vector2(2, 2))
	var bq := QuadMesh.new()
	bq.size = Vector2(1.25, 3.0)
	bq.subdivide_depth = 6
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform sampler2D tex : source_color, filter_nearest;
uniform float phase = 0.0;
void vertex() {
	float k = (1.5 - VERTEX.y) / 3.0;   // 0 위(묶인 곳) · 1 아래
	VERTEX.z += sin(TIME * 1.8 + phase + VERTEX.y * 1.6) * 0.18 * k;
	VERTEX.x += sin(TIME * 1.3 + phase) * 0.06 * k;
}
void fragment() {
	vec4 c = texture(tex, UV);
	if (c.a < 0.5) discard;
	ALBEDO = c.rgb;
	ROUGHNESS = 1.0;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("tex", H3Art.banner())
	m.set_shader_parameter("phase", randf() * 6.0)
	var bi := MeshInstance3D.new()
	bi.mesh = bq
	bi.material_override = m
	bi.position = at + Vector3(0, 4.8, 0) + arm * 1.3
	bi.rotation.y = face
	add_child(bi)


func _build_props() -> void:
	var st := H3Castle.new_st() # 돌·쇠 소품 묶음
	var tr := TERRACE
	# 테라스: 화로 둘 · 깃발 기둥 둘 · 등불
	_brazier(st, Vector3(tr.position.x + 0.7, 0, tr.end.y - 0.7), 2.2)
	_brazier(st, Vector3(tr.end.x - 0.7, 0, tr.end.y - 0.7), 2.2)
	_banner_post(st, Vector3(tr.position.x + 0.5, 0, tr.position.y + 3.0), 0.0) # 왼쪽 난간 (그림: 앞 왼쪽 발코니 깃발)
	_banner_post(st, Vector3(tr.position.x + 0.5, 0, tr.end.y - 1.2), 0.0)
	_lamp(st, Vector3(tr.end.x - 0.5, 0, BRIDGE_A.y - BRIDGE_W * 0.5 - 0.5), 1.8)
	# 다리: 양옆 번갈아 보라 등불 (빛은 둘만)
	var a3 := Vector3(BRIDGE_A.x, 0, BRIDGE_A.y)
	var b3 := Vector3(BRIDGE_B.x, 0, BRIDGE_B.y)
	var dir := (b3 - a3).normalized()
	var side := dir.cross(Vector3.UP).normalized()
	for k in 4:
		var p := a3.lerp(b3, (float(k) + 0.6) / 4.4) + side * (BRIDGE_W * 0.5 - 0.15) * (1.0 if k % 2 == 0 else -1.0)
		_lamp(st, p, 1.6 if k == 1 or k == 3 else 0.0)
	# 광장: 성문 옆 화로 둘
	_brazier(st, Vector3(CASTLE.x - 3.2, CASTLE.y, CASTLE.z + 10.8), 2.4)
	_brazier(st, Vector3(CASTLE.x + 3.2, CASTLE.y, CASTLE.z + 10.8), 0.0)
	var gl := OmniLight3D.new() # 성문 불빛
	gl.light_color = Color("#ff9a48")
	gl.light_energy = 2.5
	gl.omni_range = 12.0
	gl.position = Vector3(CASTLE.x, CASTLE.y + 2.0, CASTLE.z + 11.5)
	add_child(gl)
	# 섬 계단길 옆 작은 등불 (빛 없이 불꽃만)
	for i in range(1, ROAD.size() - 1):
		var r: Vector2 = ROAD[i]
		var a := pixel_to_hex(r.x + 1.6, r.y)
		if tiles.has(a) and not bool(tiles[a].water):
			_lamp(st, wpos(a) + Vector3(0, top_y(a), 0), 0.0)
	H3Castle.commit(self, st, H3Castle.mat(H3Art.masonry()))
	# 섬: 어두운 바늘잎나무 · 덤불 (길·물·광장 비움)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for a: Vector2i in tiles:
		var t: Dictionary = tiles[a]
		if bool(t.deck) or bool(t.water) or bool(t.path):
			continue
		var c := wpos(a)
		if rng.randf() > 0.32:
			continue
		var at := c + Vector3(rng.randf_range(-0.4, 0.4), top_y(a), rng.randf_range(-0.35, 0.35))
		var tr2 := _sprite(H3Art.pine(rng.randi_range(0, 3)), at, rng.randf() < 0.5)
		tr2.pixel_size = PX * rng.randf_range(0.9, 1.5)
		_blob(at, 1.2)


# ─── 표시 (커서 · 발밑 · 목적지 · 격자) ─────────────

func _ring_mesh(r_out: float, r_in: float, col: Color) -> Mesh:
	var st := H3Castle.new_st()
	for i in 6:
		var j := (i + 1) % 6
		var o0 := corner(i) * r_out
		var o1 := corner(j) * r_out
		var i0 := corner(i) * r_in
		var i1 := corner(j) * r_in
		for v: Vector3 in [o0, o1, i1, o0, i1, i0]:
			st.add_vertex(v)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = col
	var mesh := st.commit()
	mesh.surface_set_material(0, m)
	return mesh


func _build_markers() -> void:
	cursor = MeshInstance3D.new()
	cursor.mesh = _ring_mesh(0.95, 0.8, Color(1, 1, 1, 0.55))
	add_child(cursor)
	cursor.visible = false
	marker = MeshInstance3D.new()
	marker.mesh = _ring_mesh(0.9, 0.62, Color("#d8c0ff", 0.7))
	add_child(marker)
	goal_ring = MeshInstance3D.new()
	goal_ring.mesh = _ring_mesh(0.95, 0.72, Color("#b48cff", 0.8))
	add_child(goal_ring)
	goal_ring.visible = false
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	for a: Vector2i in tiles:
		var c := wpos(a) + Vector3(0, stand_y(a) + 0.03, 0)
		for i in 6:
			st.add_vertex(c + corner(i))
			st.add_vertex(c + corner((i + 1) % 6))
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.albedo_color = Color(1, 1, 1, 0.22)
	grid = MeshInstance3D.new()
	grid.mesh = st.commit()
	grid.material_override = gm
	grid.visible = false
	add_child(grid)


func _build_eska() -> void:
	var at := wpos(here) + Vector3(0, stand_y(here), 0)
	eska_shadow = _blob(at, 1.2)
	eska = _sprite(H3Art.eska_sheet("idle"), at)
	eska.hframes = 8
	eska.offset = Vector2(0, 107.0 * 0.5 - 1.0)
	eska.pixel_size = 2.3 / 107.0 # 키 약 2.3칸
	eska.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	marker.position = at + Vector3(0, 0.04, 0)


# ─── 카메라 ─────────────────────────────────────────

## 처음 보는 방향: 테라스에서 성 쪽 (그림 구도 — 앞 왼쪽 난간 · 오른쪽 뒤 성)
func _home_yaw() -> float:
	var d := Vector2(CASTLE.x - wpos(here).x, CASTLE.z - wpos(here).z).normalized()
	return atan2(-d.x, -d.y)


func _reset_view() -> void:
	_yaw_goal = _home_yaw()
	yaw = _yaw_goal
	pitch = deg_to_rad(13.0) # 낮게 — 성이 화면 위를 채우게 (그림 구도)
	dist = 32.0
	follow = true
	target = eska.position + _look_ahead()
	_place_cam()


## 캐릭터가 화면 아래쪽에 오게 화면 위쪽으로 당겨 보는 거리 (확대할수록 짧게)
func _look_ahead() -> Vector3:
	return Vector3(-sin(yaw), 0, -cos(yaw)) * dist * 0.24 + Vector3(0, dist * 0.16, 0)


func _place_cam() -> void:
	var off := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * dist
	cam.position = target + off
	cam.look_at(target, Vector3.UP)


func _pan(rel: Vector2) -> void:
	var k := dist * 0.0021
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	target += (-right * rel.x + fwd * rel.y) * k
	follow = false


func _rotate(step: float) -> void:
	_yaw_goal += step


func _zoom(f: float) -> void:
	dist = clampf(dist * f, 9.0, 60.0)


# ─── 입력 ───────────────────────────────────────────

func pick(sp: Vector2) -> Vector2i:
	var o := cam.project_ray_origin(sp)
	var d := cam.project_ray_normal(sp)
	if absf(d.y) < 0.001:
		return Vector2i(9999, 9999)
	for lv in range(7, -1, -1): # 높은 면부터 — 위에서 내려다보므로 높은 면이 먼저 맞는다
		for wsink in [0.0, WATER_SURF]:
			var y := float(lv) * LH - float(wsink)
			var t := (y - o.y) / d.y
			if t <= 0.0:
				continue
			var p := o + d * t
			var a := pixel_to_hex(p.x, p.z)
			if tiles.has(a) and int(tiles[a].lv) == lv and (bool(tiles[a].water) == (float(wsink) > 0.0)):
				return a
	return Vector2i(9999, 9999)


func _unhandled_input(ev: InputEvent) -> void:
	var k := ev as InputEventKey
	if k != null and k.pressed and not k.echo:
		match k.keycode:
			KEY_Q: _rotate(-PI / 4.0)
			KEY_E: _rotate(PI / 4.0)
			KEY_R: _reset_view()
			KEY_G: grid.visible = not grid.visible
			KEY_EQUAL, KEY_KP_ADD: _zoom(0.85)
			KEY_MINUS, KEY_KP_SUBTRACT: _zoom(1.18)
			KEY_ESCAPE: get_tree().change_scene_to_file("res://ui/title.tscn")
		return
	var mb := ev as InputEventMouseButton
	if mb != null:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom(0.9)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom(1.11)
		elif mb.pressed and mb.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			_press = mb.position
			_press_btn = mb.button_index
			_dragging = false
		elif not mb.pressed and mb.button_index == _press_btn:
			if mb.button_index == MOUSE_BUTTON_LEFT and not _dragging:
				_click(mb.position)
			_press_btn = 0
		return
	var mm := ev as InputEventMouseMotion
	if mm != null:
		if _press_btn != 0:
			if not _dragging and mm.position.distance_to(_press) > 7.0:
				_dragging = true
			if _dragging:
				if _press_btn == MOUSE_BUTTON_LEFT:
					_pan(mm.relative)
				else:
					yaw -= mm.relative.x * 0.008
					_yaw_goal = yaw
					pitch = clampf(pitch + mm.relative.y * 0.004, deg_to_rad(8.0), deg_to_rad(60.0))
		else:
			hover = pick(mm.position)


func _click(sp: Vector2) -> void:
	var a := pick(sp)
	if not tiles.has(a) or bool(tiles[a].water) or a == here:
		return
	var p := find_path(here if path.is_empty() else path[0], a)
	if p.is_empty():
		hud.call("say", "그 칸으로 가는 길이 없습니다 — 절벽은 계단길로만 오를 수 있습니다.")
		return
	if not path.is_empty():
		p.push_front(path[0])
	path = p
	goal_ring.visible = true
	goal_ring.position = wpos(a) + Vector3(0, stand_y(a) + 0.05, 0)
	follow = true


# ─── 매 프레임 ─────────────────────────────────────

func _process(delta: float) -> void:
	_t += delta
	if not path.is_empty():
		step_t += delta
		_walk_t += delta
		var nxt: Vector2i = path[0]
		var a := wpos(here) + Vector3(0, stand_y(here), 0)
		var b := wpos(nxt) + Vector3(0, stand_y(nxt), 0)
		var f := clampf(step_t / 0.22, 0.0, 1.0)
		var pos := a.lerp(b, f)
		pos.y += sin(f * PI) * (0.16 if absf(b.y - a.y) > 0.1 else 0.0)
		eska.position = pos
		var sx := (b - a).dot(cam.global_transform.basis.x)
		if absf(sx) > 0.01:
			eska.flip_h = sx > 0.0 # 원본 그림은 왼쪽을 봄
		if eska.texture != H3Art.eska_sheet("walk"):
			eska.texture = H3Art.eska_sheet("walk")
		eska.frame = int(_walk_t / 0.09) % 8
		if step_t >= 0.22:
			here = nxt
			path.pop_front()
			step_t = 0.0
			if path.is_empty():
				goal_ring.visible = false
				eska.texture = H3Art.eska_sheet("idle")
	else:
		eska.frame = int(_t / 0.16) % 8
	eska_shadow.position = Vector3(eska.position.x, stand_y(here) + 0.02 if path.is_empty() else eska.position.y + 0.02, eska.position.z)
	marker.position = wpos(here) + Vector3(0, stand_y(here) + 0.04, 0)
	if tiles.has(hover):
		cursor.visible = true
		cursor.position = wpos(hover) + Vector3(0, stand_y(hover) + 0.05, 0)
		var m: StandardMaterial3D = cursor.mesh.surface_get_material(0)
		m.albedo_color = Color(1, 1, 1, 0.4 + 0.25 * sin(_t * 6.0))
	else:
		cursor.visible = false
	for fl: Array in flames:
		(fl[0] as Sprite3D).frame = int(_t * 9.0 + float(fl[1])) % 3
	for li: Array in lights: # 불빛 일렁임
		(li[0] as OmniLight3D).light_energy = float(li[1]) * (0.85 + 0.15 * sin(_t * 9.0 + float(li[2])) * sin(_t * 5.3 + float(li[2]) * 2.0))
	H3Castle.fly(dragons, _t)
	if follow:
		target = target.lerp(eska.position + _look_ahead(), clampf(delta * 3.0, 0.0, 1.0))
	yaw = lerp_angle(yaw, _yaw_goal, clampf(delta * 8.0, 0.0, 1.0))
	_place_cam()


# ─── HUD ───────────────────────────────────────────

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = H3Hud.new()
	hud.map = self
	layer.add_child(hud)


class H3Hud extends Control:
	var map: Node3D
	var _msg := ""
	var _msg_t := 0.0
	const BTNS := [["rl", "↺"], ["rr", "↻"], ["zi", "+"], ["zo", "-"], ["home", "복원"], ["grid", "격자"]]

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		for i in BTNS.size():
			var b := H3Btn.new()
			b.id = String(BTNS[i][0])
			b.label = String(BTNS[i][1])
			b.map = map
			add_child(b)

	func say(s: String) -> void:
		_msg = s
		_msg_t = 2.5

	func _process(delta: float) -> void:
		_msg_t = maxf(0.0, _msg_t - delta)
		var r := get_viewport_rect().size
		for i in get_child_count():
			var b := get_child(i) as Control
			b.position = Vector2(r.x - 52.0, 60.0 + 48.0 * float(i))
			b.size = Vector2(40, 40)
		queue_redraw()

	func _draw() -> void:
		var r := get_viewport_rect().size
		TTheme.text(self, Vector2(14, 26), "2.5D 헥스 지도 시안 — 마녀성으로 가는 길", 15, TTheme.GOLD)
		TTheme.text(self, Vector2(14, 44), "그림은 코드 임시 그림 (에스카만 AI 그림) — AI 그림으로 바꿔 끼울 자리", 10, TTheme.TEXT_SUB)
		draw_rect(Rect2(0, r.y - 22, r.x, 22), Color(0, 0, 0, 0.55))
		var hv: Vector2i = map.get("hover")
		var tiles: Dictionary = map.get("tiles")
		var info := "(%d, %d) 높이 %d" % [hv.x, hv.y, int(tiles[hv].lv)] if tiles.has(hv) else "—"
		TTheme.text(self, Vector2(10, r.y - 7), "%s · %d칸 · %d FPS" % [info, tiles.size(), Engine.get_frames_per_second()], 10, TTheme.TEXT)
		TTheme.text(self, Vector2(r.x - 10, r.y - 7), "누르기 이동 · 휠 확대·축소 · 왼쪽 끌기 지도 이동 · 오른쪽 끌기 회전 · Q/E 회전 · R 복원 · G 격자", 10, TTheme.TEXT_SUB, HORIZONTAL_ALIGNMENT_RIGHT)
		if _msg_t > 0.0:
			var w := TTheme.width(_msg, 12) + 24.0
			TTheme.panel(self, Rect2((r.x - w) * 0.5, r.y - 64, w, 28), TTheme.PANEL, TTheme.LINE, 1, 4)
			TTheme.text(self, Vector2(r.x * 0.5, r.y - 45), _msg, 12, TTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER)


class H3Btn extends Control:
	var id := ""
	var label := ""
	var map: Node3D

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(ev: InputEvent) -> void:
		var mb := ev as InputEventMouseButton
		if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
			return
		match id:
			"rl": map.call("_rotate", -PI / 4.0)
			"rr": map.call("_rotate", PI / 4.0)
			"zi": map.call("_zoom", 0.8)
			"zo": map.call("_zoom", 1.25)
			"home": map.call("_reset_view")
			"grid":
				var g: MeshInstance3D = map.get("grid")
				g.visible = not g.visible
		accept_event()

	func _draw() -> void:
		TTheme.panel(self, Rect2(Vector2.ZERO, size), Color(TTheme.PANEL, 0.85), Color(TTheme.LINE, 0.6), 1, 5)
		TTheme.text(self, Vector2(size.x * 0.5, 26), label, 12 if label.length() > 1 else 15, TTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
