extends Node3D
## 2.5D 헥스 지도 시안 (2026-10-23 사용자: "고도로 2.5D 헥스 시안 · 보내준 사진 참고"). 주소 끝 ?hex3d.
## 3D 헥스 지형(칸마다 높이 · 층진 절벽 · 호수 · 폭포 · 흙길) + 세운 픽셀 그림(나무 · 덤불 · 바위 · 에스카).
## 헥스 격자는 평소 숨기고 커서·발밑·목적지만 보인다 (G로 전체 격자).
## 조작: 누르기 = 그 칸으로 걸어감 · 휠 = 확대·축소 · 왼쪽 끌기 = 지도 이동 · 오른쪽 끌기 = 회전·기울기 · Q/E 회전 · WASD 이동 · R 복원 · G 격자 · Esc 타이틀.
## 폰(시험용): 끌기 = 이동, 오른쪽 버튼(↺ ↻ + - 복원 격자)으로 회전·확대·복원·격자.
## 그림은 코드 픽셀 그림(H3Art) — 나중에 AI 그림으로 바꿔 끼운다.

const S := 1.0 ## 헥스 반지름 (뾰족 위)
const LH := 0.9 ## 높이 한 층 (사진처럼 키 큰 절벽)
const W := 32 ## 열
const H := 26 ## 줄
const PX := 1.0 / 32.0 ## 스프라이트 1px 크기
const BASE := Vector2i(960, 540) ## 이 장면의 설계 해상도 (3D를 이 크기로 그려 키움 → 픽셀 느낌)
const WATER_DROP := 0.45 ## 물 칸 바닥 깊이
const WATER_SURF := 0.14 ## 물 칸 수면 (층 높이 아래)
## 모서리 i(각 60i−30°)와 i+1 사이 변이 바라보는 이웃 (축 좌표)
const EDGE := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1)]
const RIVER := [Vector2(49, -2), Vector2(47, 3), Vector2(43, 7.5), Vector2(38.5, 11.5), Vector2(34, 15), Vector2(30, 17.5)]
const ROAD := [Vector2(27, 41), Vector2(28.5, 34), Vector2(33, 29), Vector2(38.5, 26.5), Vector2(43, 22), Vector2(46.5, 16.5),
	Vector2(50, 11), Vector2(53, 5), Vector2(55, -1)]

var tiles := {} ## 축 좌표 Vector2i → {lv, water, path, depth}
var cam: Camera3D
var yaw := 0.0
var pitch := deg_to_rad(32.0) ## 낮은 시점 — 세운 그림이 제 비율로 보이게 (사용자 2026-10-23 "시점이 너무 높아")
var dist := 26.0
var target := Vector3.ZERO
var follow := true
var _yaw_goal := 0.0

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
	_build_water()
	_build_falls()
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


# ─── 지도 만들기 (사진처럼: 뒤로 갈수록 층층이 높아지는 절벽 · 가운데 호수 · 뒤 폭포 · 앞 숲 · 오른쪽으로 오르는 흙길) ───

static func _seg_dist(p: Vector2, pts: Array) -> float:
	var best := INF
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var ab := b - a
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		best = minf(best, p.distance_to(a + ab * t))
	return best


func _band(x: float, z: float) -> int:
	var lv := 1
	if z < 23.0 + 2.6 * sin(x * 0.33) + 0.05 * (x - 28.0):
		lv = 2
	if z < 16.0 + 0.14 * (x - 28.0) + 2.2 * sin(x * 0.47 + 1.0):
		lv = 3
	if z < 9.0 + 0.12 * (x - 28.0) + 1.8 * sin(x * 0.61 + 2.0):
		lv = 4
	if z < 3.5 + 1.5 * sin(x * 0.5):
		lv = 5
	return lv


func _gen_map() -> void:
	var n := FastNoiseLite.new()
	n.seed = 5
	n.frequency = 0.35
	for row in H:
		for col in W:
			var a := to_axial(col, row)
			var p := wpos(a)
			var x := p.x
			var z := p.z
			var road := _seg_dist(Vector2(x, z), ROAD) < 0.95
			# 경계를 칸마다 흔들어 들쭉날쭉한 절벽선
			var lv := _band(x, z) if road else _band(x, z + n.get_noise_2d(x, z) * 1.6)
			if not road and x > 45.0 and z < 27.0 + n.get_noise_2d(x * 0.5, 3.0) * 2.0 and z > 18.0:
				lv += 1 # 오른쪽 앞 언덕
			var water := false
			var lake := Vector2((x - 20.0) / 15.0, (z - 21.0) / 6.8)
			if lake.length() + n.get_noise_2d(x * 0.6, z * 0.6) * 0.12 < 1.0 and not road:
				water = true
				lv = 0
			elif not road and _seg_dist(Vector2(x, z), RIVER) < 1.15:
				water = true
			tiles[a] = {"lv": lv, "water": water, "path": road and not water, "depth": 0}
	# 물 깊이 (물가에서 몇 칸)
	var q: Array = []
	for a: Vector2i in tiles:
		if bool(tiles[a].water):
			for d: Vector2i in EDGE:
				var b: Vector2i = a + d
				if tiles.has(b) and not bool(tiles[b].water):
					tiles[a].depth = 1
					q.append(a)
					break
	while not q.is_empty():
		var a: Vector2i = q.pop_front()
		for d: Vector2i in EDGE:
			var b: Vector2i = a + d
			if tiles.has(b) and bool(tiles[b].water) and int(tiles[b].depth) == 0:
				tiles[b].depth = int(tiles[a].depth) + 1
				q.append(b)
	# 시작 칸: 길 위 가장 앞쪽
	var best := Vector2i.ZERO
	var bz := -INF
	for a: Vector2i in tiles:
		if bool(tiles[a].path) and wpos(a).z > bz and wpos(a).z < 30.5:
			bz = wpos(a).z
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
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#0f1a12")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#9fb4c8")
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.05
	env.fog_enabled = true
	env.fog_light_color = Color("#3a5a52")
	env.fog_density = 0.006
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#fff1d6")
	sun.light_energy = 1.15
	sun.rotation = Vector3(deg_to_rad(-42.0), deg_to_rad(-150.0), 0.0) # 앞 왼쪽 위에서 비춤 → 화면 쪽 절벽면이 밝다
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70.0
	add_child(sun)
	cam = Camera3D.new()
	cam.fov = 30.0
	cam.near = 0.5
	cam.far = 200.0
	add_child(cam)


# ─── 지형 메시 ─────────────────────────────────────

func _top_shader() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform sampler2D grass_tex : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D dirt_tex : source_color, filter_nearest_mipmap, repeat_enable;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = wp.xz * 0.5;
	vec2 tp = floor(wp.xz * 32.0);
	float h = hash(tp);
	float w = COLOR.r + (h - 0.5) * 0.45;   // 흙길 비율 (모서리 보간 + 픽셀 얼룩 → 들쭉날쭉한 길 가장자리)
	vec3 c = w > 0.5 ? texture(dirt_tex, uv).rgb : texture(grass_tex, uv).rgb;
	float ao = COLOR.g + (h - 0.5) * 0.25;     // 높은 이웃 밑 그늘
	c *= ao < 0.55 ? 0.62 : (ao < 0.8 ? 0.82 : 1.0);
	float rim = COLOR.b + (h - 0.5) * 0.3;     // 낮은 이웃 쪽 입술 빛
	if (rim > 0.82 && w <= 0.5) c = mix(c, vec3(0.62, 0.78, 0.36), 0.55);
	ALBEDO = c;
	ROUGHNESS = 1.0;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("grass_tex", H3Art.grass())
	m.set_shader_parameter("dirt_tex", H3Art.dirt())
	return m


func _build_terrain() -> void:
	var top := SurfaceTool.new()
	top.begin(Mesh.PRIMITIVE_TRIANGLES)
	var side := SurfaceTool.new()
	side.begin(Mesh.PRIMITIVE_TRIANGLES)
	for a: Vector2i in tiles:
		var t: Dictionary = tiles[a]
		var c := wpos(a)
		var y := top_y(a)
		# 윗면 (모서리 색: r = 흙길 비율 · g = 그늘(1 밝음) · b = 입술 빛)
		var cols: Array = []
		for i in 6:
			var n1: Vector2i = a + EDGE[(i + 5) % 6]
			var n2: Vector2i = a + EDGE[i]
			var pw := (1.0 if bool(t.path) else 0.0)
			var cnt := 1.0
			var ao := 1.0
			var rim := 0.0
			for nb: Vector2i in [n1, n2]:
				if tiles.has(nb):
					pw += 1.0 if bool(tiles[nb].path) else 0.0
					cnt += 1.0
					if top_y(nb) > y + 0.01:
						ao = 0.45
					elif top_y(nb) < y - 0.01:
						rim = 1.0
				else:
					rim = 1.0
			cols.append(Color(pw / cnt, ao, rim))
		var cc := Color(1.0 if bool(t.path) else 0.0, 1.0, 0.0)
		if bool(t.water):
			cc = Color(0, 0.5, 0) # 물 밑바닥은 어둡게
		for i in 6:
			var j := (i + 1) % 6
			top.set_normal(Vector3.UP)
			top.set_color(cc)
			top.add_vertex(c + Vector3(0, y, 0))
			top.set_color(cols[i] if not bool(t.water) else Color(0, 0.5, 0))
			top.add_vertex(cw(a, i) + Vector3(0, y, 0))
			top.set_color(cols[j] if not bool(t.water) else Color(0, 0.5, 0))
			top.add_vertex(cw(a, j) + Vector3(0, y, 0))
		# 옆면: 이웃이 더 낮으면 그 높이까지 절벽 (지도 밖은 바닥까지)
		for i in 6:
			var nb: Vector2i = a + EDGE[i]
			var ny := top_y(nb) if tiles.has(nb) else -1.4
			if ny >= y - 0.01:
				continue
			var p0 := cw(a, i)
			var p1 := cw(a, (i + 1) % 6)
			var nrm := Vector3(p1.z - p0.z, 0.0, p0.x - p1.x).normalized()
			if nrm.dot((p0 + p1) * 0.5 - c) < 0.0:
				nrm = -nrm
			var u0 := fposmod(float(a.x * 7 + a.y * 13 + i * 3) * 0.37, 1.0)
			var u1 := u0 + S * 0.5
			var v0 := 0.0
			var v1 := (y - ny) * 0.5
			side.set_normal(nrm)
			side.set_uv(Vector2(u0, v0)); side.add_vertex(Vector3(p0.x, y, p0.z))
			side.set_uv(Vector2(u1, v0)); side.add_vertex(Vector3(p1.x, y, p1.z))
			side.set_uv(Vector2(u1, v1)); side.add_vertex(Vector3(p1.x, ny, p1.z))
			side.set_uv(Vector2(u0, v0)); side.add_vertex(Vector3(p0.x, y, p0.z))
			side.set_uv(Vector2(u1, v1)); side.add_vertex(Vector3(p1.x, ny, p1.z))
			side.set_uv(Vector2(u0, v1)); side.add_vertex(Vector3(p0.x, ny, p0.z))
	var mi_top := MeshInstance3D.new()
	mi_top.mesh = top.commit()
	mi_top.material_override = _top_shader()
	add_child(mi_top)
	var cm := StandardMaterial3D.new()
	cm.albedo_texture = H3Art.cliff()
	cm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	cm.cull_mode = BaseMaterial3D.CULL_DISABLED
	cm.roughness = 1.0
	cm.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	var mi_side := MeshInstance3D.new()
	mi_side.mesh = side.commit()
	mi_side.material_override = cm
	add_child(mi_side)


# ─── 물 · 폭포 ─────────────────────────────────────

func _build_water() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for a: Vector2i in tiles:
		var t: Dictionary = tiles[a]
		if not bool(t.water):
			continue
		var c := wpos(a)
		var y := stand_y(a)
		var dep := clampf(float(int(t.depth) - 1) / 4.0, 0.0, 1.0)
		var shore: Array = []
		var cdep: Array = []
		for i in 6:
			var s := 0.0
			var sum := float(int(t.depth))
			for nb: Vector2i in [a + EDGE[(i + 5) % 6], a + EDGE[i]]:
				if not tiles.has(nb) or not bool(tiles[nb].water) or stand_y(nb) > y + 0.01:
					s = 1.0
				else:
					sum += float(int(tiles[nb].depth))
			shore.append(s)
			cdep.append(0.0 if s > 0.0 else clampf((sum / 3.0 - 1.0) / 4.0, 0.0, 1.0))
		for i in 6:
			var j := (i + 1) % 6
			st.set_normal(Vector3.UP)
			st.set_color(Color(0.0, dep, 0.0))
			st.add_vertex(c + Vector3(0, y, 0))
			st.set_color(Color(shore[i], cdep[i], 0.0))
			st.add_vertex(cw(a, i) + Vector3(0, y, 0))
			st.set_color(Color(shore[j], cdep[j], 0.0))
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
	float d = COLOR.g + (hash(floor(wp.xz * 16.0)) - 0.5) * 0.12;
	vec3 shal = vec3(0.20, 0.52, 0.58), mid = vec3(0.10, 0.33, 0.50), deep = vec3(0.05, 0.16, 0.32);
	vec3 c = mix(shal, mid, smoothstep(0.0, 0.35, d));
	c = mix(c, deep, smoothstep(0.35, 0.9, d));
	float w = sin(p.x * 1.9 + TIME * 0.7 + sin(p.y * 1.1 + TIME * 0.45) * 2.2) * sin(p.y * 3.1 - TIME * 0.55 + p.x * 0.4);
	if (w > 0.86) c += vec3(0.10, 0.15, 0.15);
	else if (w < -0.9) c -= vec3(0.02, 0.03, 0.03);
	float h = hash(floor(wp.xz * 32.0));
	float foam = COLOR.r + (h - 0.5) * 0.28 + sin(TIME * 1.8 + p.x * 2.7 + p.y * 1.3) * 0.06;
	if (foam > 0.86) c = vec3(0.86, 0.95, 0.94);
	else if (foam > 0.66) c = mix(c, vec3(0.50, 0.78, 0.80), 0.65);
	ALBEDO = c;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _build_falls() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mist_at: Array = []
	for a: Vector2i in tiles:
		if not bool(tiles[a].water):
			continue
		var y := stand_y(a)
		var c := wpos(a)
		for i in 6:
			var nb: Vector2i = a + EDGE[i]
			if not tiles.has(nb) or not bool(tiles[nb].water):
				continue
			var ny := stand_y(nb)
			if ny >= y - 0.05:
				continue
			var p0 := cw(a, i)
			var p1 := cw(a, (i + 1) % 6)
			var out := ((p0 + p1) * 0.5 - c).normalized() * 0.06
			for k in 2: # 두 겹 (앞 물줄기 + 살짝 앞으로 휜 물)
				var o := out * float(k + 1)
				st.set_uv(Vector2(0, 0)); st.add_vertex(Vector3(p0.x, y, p0.z) + o)
				st.set_uv(Vector2(1, 0)); st.add_vertex(Vector3(p1.x, y, p1.z) + o)
				st.set_uv(Vector2(1, y - ny)); st.add_vertex(Vector3(p1.x, ny, p1.z) + o)
				st.set_uv(Vector2(0, 0)); st.add_vertex(Vector3(p0.x, y, p0.z) + o)
				st.set_uv(Vector2(1, y - ny)); st.add_vertex(Vector3(p1.x, ny, p1.z) + o)
				st.set_uv(Vector2(0, y - ny)); st.add_vertex(Vector3(p0.x, ny, p0.z) + o)
			mist_at.append(Vector3(((p0 + p1) * 0.5).x, ny + 0.05, ((p0 + p1) * 0.5).z))
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
	vec3 c = vec3(0.24, 0.52, 0.66);
	if (s > 0.55) c = vec3(0.62, 0.84, 0.90);
	if (s > 0.82) c = vec3(0.93, 0.98, 0.99);
	float edge = min(UV.x, 1.0 - UV.x);
	ALBEDO = c;
	ALPHA = edge < 0.06 ? 0.5 : 0.92;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	for p: Vector3 in mist_at: # 물보라
		var pt := CPUParticles3D.new()
		pt.position = p
		pt.amount = 10
		pt.lifetime = 1.0
		pt.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		pt.emission_sphere_radius = 0.4
		pt.direction = Vector3.UP
		pt.spread = 50.0
		pt.initial_velocity_min = 0.3
		pt.initial_velocity_max = 0.8
		pt.gravity = Vector3(0, -0.2, 0)
		pt.scale_amount_min = 0.25
		pt.scale_amount_max = 0.5
		var qm := QuadMesh.new()
		qm.size = Vector2(0.5, 0.5)
		var pm := StandardMaterial3D.new()
		pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		pm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		pm.albedo_color = Color(0.92, 0.98, 1.0, 0.5)
		pm.albedo_texture = H3Art.puff()
		pm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		qm.material = pm
		pt.mesh = qm
		add_child(pt)


# ─── 소품 (세운 픽셀 그림) ──────────────────────────

func _sprite(tex: Texture2D, at: Vector3, flip := false) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = tex
	s.pixel_size = PX
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.shaded = false # 그림에 이미 빛·그늘이 그려져 있음 (빌보드 법선으로 받는 빛은 뒤집혀 어두워짐)
	s.modulate = Color(0.94, 0.96, 0.92)
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


func _build_props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var n := FastNoiseLite.new()
	n.seed = 9
	n.frequency = 0.12
	for a: Vector2i in tiles:
		var t: Dictionary = tiles[a]
		if bool(t.water) or bool(t.path) or a == here:
			continue
		var c := wpos(a)
		var y := top_y(a)
		var near_path := false
		for d: Vector2i in EDGE:
			if tiles.has(a + d) and bool(tiles[a + d].path):
				near_path = true
		var dens := 0.08 + 0.5 * maxf(0.0, n.get_noise_2d(c.x, c.z))
		if c.z > 35.0 or c.x < 5.0:
			dens += 0.4 # 지도 앞 끝·왼쪽 숲으로 테두리 (낮은 시점이라 캐릭터 앞은 비움)
		if c.z > wpos(here).z and absf(c.x - wpos(here).x) < 6.0:
			dens *= 0.25 # 시작 자리 앞(카메라 쪽)은 덜 가리게
		if near_path:
			dens *= 0.3
		var roll := rng.randf()
		var off := Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.35, 0.35))
		var at := c + off + Vector3(0, y, 0)
		if roll < dens * 0.55:
			var tr := _sprite(H3Art.tree(rng.randi_range(0, 3)), at, rng.randf() < 0.5)
			tr.pixel_size = PX * rng.randf_range(0.85, 1.25)
			_blob(at, 2.4)
		elif roll < dens * 0.85:
			_sprite(H3Art.bush(rng.randi_range(0, 2)), at, rng.randf() < 0.5)
			_blob(at, 1.3)
		elif roll < dens * 0.85 + 0.06:
			_sprite(H3Art.rock(rng.randi_range(0, 2)), at, rng.randf() < 0.5)
		elif roll < dens * 0.85 + 0.3:
			_sprite(H3Art.tuft(rng.randi_range(0, 3)), at, rng.randf() < 0.5)
	# 물가 바위
	for a: Vector2i in tiles:
		if bool(tiles[a].water) and int(tiles[a].depth) == 1 and rng.randf() < 0.12:
			_sprite(H3Art.rock(rng.randi_range(0, 2)), wpos(a) + Vector3(rng.randf_range(-0.3, 0.3), stand_y(a) - 0.05, 0.2))


# ─── 표시 (커서 · 발밑 · 목적지 · 격자) ─────────────

func _ring_mesh(r_out: float, r_in: float, col: Color) -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
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
	m.no_depth_test = false
	var mesh := st.commit()
	mesh.surface_set_material(0, m)
	return mesh


func _build_markers() -> void:
	cursor = MeshInstance3D.new()
	cursor.mesh = _ring_mesh(0.95, 0.8, Color(1, 1, 1, 0.55))
	add_child(cursor)
	cursor.visible = false
	marker = MeshInstance3D.new()
	marker.mesh = _ring_mesh(0.9, 0.62, Color("#e8d4a0", 0.75))
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
	eska = _sprite(H3Art.eska(0), at)
	eska.pixel_size = 2.3 / float(eska.texture.get_height()) # 키 약 2.3칸 (나무 약 3칸)
	eska.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	eska.modulate = Color(1, 1, 1)
	marker.position = at + Vector3(0, 0.04, 0)


# ─── 카메라 ─────────────────────────────────────────

func _reset_view() -> void:
	_yaw_goal = 0.0
	yaw = 0.0
	pitch = deg_to_rad(32.0)
	dist = 26.0
	follow = true
	target = eska.position + _look_ahead()
	_place_cam()


## 캐릭터가 화면 아래쪽 1/3에 오게 화면 위쪽으로 당겨 보는 거리 (확대할수록 짧게)
func _look_ahead() -> Vector3:
	return Vector3(-sin(yaw), 0, -cos(yaw)) * dist * 0.13


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
	dist = clampf(dist * f, 9.0, 48.0)


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
					pitch = clampf(pitch + mm.relative.y * 0.004, deg_to_rad(18.0), deg_to_rad(60.0))
		else:
			hover = pick(mm.position)


func _click(sp: Vector2) -> void:
	var a := pick(sp)
	if not tiles.has(a) or bool(tiles[a].water) or a == here:
		return
	var p := find_path(here if path.is_empty() else path[0], a)
	if p.is_empty():
		hud.call("say", "그 칸으로 가는 길이 없습니다 — 절벽은 흙길로만 오를 수 있습니다.")
		return
	if not path.is_empty():
		p.push_front(path[0])
	path = p
	goal_ring.visible = true
	goal_ring.position = wpos(a) + Vector3(0, stand_y(a) + 0.05, 0)
	follow = true


# ─── 매 프레임 ─────────────────────────────────────

func _process(delta: float) -> void:
	if not path.is_empty():
		step_t += delta
		_walk_t += delta
		var nxt: Vector2i = path[0]
		var a := wpos(here) + Vector3(0, stand_y(here), 0)
		var b := wpos(nxt) + Vector3(0, stand_y(nxt), 0)
		var f := clampf(step_t / 0.2, 0.0, 1.0)
		var pos := a.lerp(b, f)
		pos.y += sin(f * PI) * (0.18 if absf(b.y - a.y) > 0.1 else 0.05)
		eska.position = pos
		var sx := (b - a).dot(cam.global_transform.basis.x)
		if absf(sx) > 0.01:
			eska.flip_h = sx < 0.0
		eska.texture = H3Art.eska(int(_walk_t * 8.0) % 2)
		if step_t >= 0.2:
			here = nxt
			path.pop_front()
			step_t = 0.0
			if path.is_empty():
				goal_ring.visible = false
				eska.texture = H3Art.eska(0)
	eska_shadow.position = Vector3(eska.position.x, stand_y(here) + 0.02 if path.is_empty() else eska.position.y + 0.02, eska.position.z)
	marker.position = wpos(here) + Vector3(0, stand_y(here) + 0.04, 0)
	if tiles.has(hover):
		cursor.visible = true
		cursor.position = wpos(hover) + Vector3(0, stand_y(hover) + 0.05, 0)
		var m: StandardMaterial3D = cursor.mesh.surface_get_material(0)
		m.albedo_color = Color(1, 1, 1, 0.4 + 0.25 * sin(Time.get_ticks_msec() * 0.006))
	else:
		cursor.visible = false
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
		TTheme.text(self, Vector2(14, 26), "2.5D 헥스 지도 시안", 15, TTheme.GOLD)
		TTheme.text(self, Vector2(14, 44), "그림은 코드 임시 그림 — AI 그림으로 바꿔 끼울 자리", 10, TTheme.TEXT_SUB)
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
