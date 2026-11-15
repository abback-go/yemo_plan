extends Node2D
## 용사 파티 탐험 — 틀 시안 (2026-11-15 사용자 "간단하고 작은 맵 1개와 시점, 그리고 캐릭터와 기본 이동 조작까지만"). 주소 끝 ?party.
## 기준 문서 docs/party/README.md. 실시간 · 고정 탑다운 3/4 시점(카메라를 돌리지 않음, 기둥·나무의 앞면이 보임) · 2D 픽셀.
## 맵: 숲속 유적 56×36칸(칸 16px) — 숲 테두리 · 연못과 금빛 석상 섬 · 무너진 기둥이 선 돌바닥 광장 · 흙길(왼쪽·오른쪽 위로 나감).
##   땅은 셰이더 한 장(pt_ground.gdshader), 소품(나무·기둥·석상·바위·덤불)은 y 정렬 — 캐릭터가 기둥·나무 뒤로 가면 가려진다.
##   막힘: 숲 · 물 칸(줄마다 이어 붙인 사각형) + 기둥·바위·안쪽 나무 밑동.
## 화면: 640×360 설계 화면을 키움(소수 배율 · 넓은 화면은 옆이 더 보임). 카메라는 캐릭터를 부드럽게 따라가고 맵 밖은 안 보임.
## 조작: WASD · 방향키 · 패드 왼쪽 스틱 = 8방향 걷기 · Esc 타이틀. 폰(시험용)은 화면 왼쪽 절반을 끌면 조이스틱.
## 그림은 모두 코드 임시(PtArt) — AI 그림으로 바꿔 끼울 자리.

const TS := 16 ## 칸 크기 (px)
const MW := 56 ## 맵 칸 수 (가로)
const MH := 36
enum { GRASS, FLOWER, DIRT, STONE, WATER, FOREST }
const BLOCK := [WATER, FOREST]
const PLAZA := Rect2i(5, 21, 16, 11) ## 유적 광장 (칸)
const PONDS := [Vector4(36, 14, 11, 6.5), Vector4(45, 21, 5, 4)] ## 연못 (가운데 x, y, 반지름 x, y — 칸)
const ISLAND := Vector4(35.5, 13, 3.2, 2.2) ## 석상 섬
const PATHS := [[Vector2(0, 18), Vector2(5, 19), Vector2(8, 22)],
	[Vector2(13, 21), Vector2(13, 15), Vector2(18, 10), Vector2(26, 6), Vector2(36, 4), Vector2(42, 3), Vector2(45, 0)],
	[Vector2(20, 26), Vector2(25, 25), Vector2(30, 21)]] ## 흙길 (칸)
const START := Vector2(12.5, 26.5) ## 처음 서는 자리 (칸) — 광장 가운데
## 소품 (칸 좌표): 기둥 [x, y, 부러짐, 물속] · 안쪽 나무 · 바위
const PILLARS := [[6, 22, false, false], [19, 22, true, false], [6, 30, true, false], [19, 30, false, false], [11, 15, true, false],
	[28, 13, false, true], [43, 16, true, true]]
const INNER_TREES := [Vector2(24, 31), Vector2(29, 32), Vector2(50, 28), Vector2(49, 11), Vector2(22, 14), Vector2(8, 12)]
const ROCKS := [Vector2(23, 18), Vector2(31, 27), Vector2(40, 25), Vector2(10, 17), Vector2(51, 22)]
const VIEW_LIFT := 10.0 ## 카메라가 캐릭터보다 이만큼 위를 봄 (몸이 화면 가운데)

const ATMOS := """
shader_type canvas_item;
// 화면 분위기: 가장자리 어둡게 + 오른쪽 위에서 비스듬히 드는 따뜻한 빛줄기. 투명도를 8단계로 잘라 픽셀 느낌
const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
void fragment() {
	vec2 uv = UV;
	float bay = (BAYER[int(mod(FRAGCOORD.y, 4.0)) * 4 + int(mod(FRAGCOORD.x, 4.0))] + 0.5) / 16.0;
	float vig = smoothstep(0.42, 0.95, length((uv - 0.5) * vec2(1.5, 1.1))) * 0.55;
	float beam = pow(max(0.0, sin(uv.x * 7.0 - uv.y * 4.5 + 2.2 + sin(TIME * 0.2) * 0.3)), 8.0) * (1.0 - uv.y) * 0.22;
	beam += pow(max(0.0, sin(uv.x * 5.0 - uv.y * 3.4 + 4.6)), 10.0) * (1.0 - uv.y * 0.8) * 0.14;
	vig = floor(vig * 8.0 + bay) / 8.0;
	beam = floor(beam * 8.0 + bay) / 8.0;
	float a = vig + beam * (1.0 - vig);
	vec3 col = a > 0.0 ? (vec3(1.0, 0.86, 0.55) * beam * (1.0 - vig) + vec3(0.02, 0.04, 0.05) * vig) / a : vec3(0.0);
	COLOR = vec4(col, a);
}
"""

var grid := PackedByteArray() ## 칸 종류 (MW × MH)
var hero: PtHero
var cam: Camera2D
var world: Node2D ## y 정렬 (소품 + 캐릭터)
var hud: Control
var _cam_pos := Vector2.ZERO
var _scale_was: Array = []
var _touch_id := -1
var _touch_o := Vector2.ZERO


func _ready() -> void:
	var win := get_tree().root
	_scale_was = [win.content_scale_stretch, win.content_scale_aspect]
	win.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	_gen_map()
	_build_ground()
	_build_walls()
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	_build_props()
	hero = PtHero.new()
	hero.position = START * TS
	world.add_child(hero)
	cam = Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = MW * TS
	cam.limit_bottom = MH * TS
	add_child(cam)
	cam.make_current()
	_cam_pos = hero.position - Vector2(0, VIEW_LIFT)
	cam.position = _cam_pos.round()
	cam.reset_smoothing()
	var fx := CanvasLayer.new()
	fx.layer = 5
	add_child(fx)
	var atm := ColorRect.new()
	atm.set_anchors_preset(Control.PRESET_FULL_RECT)
	atm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = ATMOS
	var sm := ShaderMaterial.new()
	sm.shader = sh
	atm.material = sm
	fx.add_child(atm)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	hud = PtHud.new()
	hud.field = self
	layer.add_child(hud)


func _exit_tree() -> void:
	TTheme.release()
	if not _scale_was.is_empty():
		var win := get_tree().root
		win.content_scale_stretch = _scale_was[0]
		win.content_scale_aspect = _scale_was[1]


# ─── 맵 ─────────────────────────────────────────────

func tile(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= MW or y >= MH:
		return FOREST
	return grid[y * MW + x]


static func _seg_dist(p: Vector2, pts: Array) -> float:
	var best := INF
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var ab: Vector2 = pts[i + 1] - a
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		best = minf(best, p.distance_to(a + ab * t))
	return best


func _gen_map() -> void:
	var n := FastNoiseLite.new()
	n.seed = 11
	n.frequency = 0.18
	grid.resize(MW * MH)
	for y in MH:
		for x in MW:
			var t := GRASS
			var p := Vector2(x, y)
			var edge := mini(mini(x, y), mini(MW - 1 - x, MH - 1 - y))
			if float(edge) < 2.6 + (n.get_noise_2d(x * 1.0, y * 1.0) + 1.0):
				t = FOREST
			for e: Vector4 in PONDS:
				var dx := (float(x) - e.x) / e.z
				var dy := (float(y) - e.y) / e.w
				if dx * dx + dy * dy + n.get_noise_2d(x * 2.0 + 50.0, y * 2.0) * 0.25 < 1.0:
					t = WATER
			var ix := (float(x) - ISLAND.x) / ISLAND.z
			var iy := (float(y) - ISLAND.y) / ISLAND.w
			if ix * ix + iy * iy < 1.0:
				t = GRASS
			if PLAZA.has_point(Vector2i(x, y)):
				var border := x == PLAZA.position.x or y == PLAZA.position.y or x == PLAZA.end.x - 1 or y == PLAZA.end.y - 1
				if not (border and H3Art._hash(x, y, 4) > 0.6): # 가장자리는 군데군데 풀에 묻힘
					t = STONE
			if t in [GRASS, FOREST]:
				for path: Array in PATHS:
					if _seg_dist(p, path) < 1.25 + n.get_noise_2d(x * 3.0, y * 3.0 + 9.0) * 0.4:
						t = DIRT
			grid[y * MW + x] = t
	for y in MH: # 꽃: 연못가와 군데군데
		for x in MW:
			if tile(x, y) != GRASS:
				continue
			var near_water := false
			for d: Vector2i in [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2), Vector2i(3, 1), Vector2i(-3, -1)]:
				if tile(x + d.x, y + d.y) == WATER:
					near_water = true
			if (near_water and H3Art._hash(x, y, 6) > 0.5) or n.get_noise_2d(x * 1.5 + 90.0, y * 1.5) > 0.55:
				grid[y * MW + x] = FLOWER


func _build_ground() -> void:
	var img := Image.create(MW, MH, false, Image.FORMAT_RGBA8)
	for y in MH:
		for x in MW:
			img.set_pixel(x, y, Color(float(tile(x, y)) / 10.0, 0, 0, 1))
	var g := Sprite2D.new()
	g.texture = ImageTexture.create_from_image(img)
	g.centered = false
	g.scale = Vector2(TS, TS)
	g.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var m := ShaderMaterial.new()
	m.shader = preload("res://proto/party/pt_ground.gdshader")
	m.set_shader_parameter("map_tex", g.texture)
	m.set_shader_parameter("tiles", Vector2(MW, MH))
	m.set_shader_parameter("plaza_c", Vector2(PLAZA.get_center()) * TS)
	g.material = m
	add_child(g)


## 막힌 칸(숲·물)을 줄마다 이어 붙인 사각형 + 맵 바깥 벽
func _build_walls() -> void:
	var body := StaticBody2D.new()
	add_child(body)
	for y in MH:
		var x := 0
		while x < MW:
			if not tile(x, y) in BLOCK:
				x += 1
				continue
			var x0 := x
			while x < MW and tile(x, y) in BLOCK:
				x += 1
			_box(body, Rect2(x0 * TS, y * TS, (x - x0) * TS, TS))
	for r: Rect2 in [Rect2(-TS, -TS, (MW + 2) * TS, TS), Rect2(-TS, MH * TS, (MW + 2) * TS, TS), Rect2(-TS, 0, TS, MH * TS), Rect2(MW * TS, 0, TS, MH * TS)]:
		_box(body, r)


func _box(body: StaticBody2D, r: Rect2) -> void:
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = r.size
	cs.shape = sh
	cs.position = r.get_center()
	body.add_child(cs)


func _circle(body: StaticBody2D, at: Vector2, r: float) -> void:
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = r
	cs.shape = sh
	cs.position = at
	body.add_child(cs)


## 밑동 자리 at에 소품 그림 (텍스처 안 밑동 base)
func _prop(tex: Texture2D, base: Vector2, at: Vector2, flip := false) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.offset = -base
	s.position = at.round()
	s.flip_h = flip
	world.add_child(s)
	return s


func _build_props() -> void:
	var body := StaticBody2D.new()
	add_child(body)
	var taken := {}
	for y in MH: # 숲 테두리 나무 (빽빽하게, 이웃 칸과 겹치지 않게)
		for x in MW:
			if tile(x, y) != FOREST or H3Art._hash(x, y, 1) > 0.5:
				continue
			var near := false
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if taken.has(Vector2i(x + dx, y + dy)):
						near = true
			if near:
				continue
			taken[Vector2i(x, y)] = true
			var j := Vector2(H3Art._hash(x, y, 2) - 0.5, H3Art._hash(x, y, 3) - 0.5) * 8.0
			_prop(PtArt.tree(int(H3Art._hash(x, y, 4) * 4.0)), PtArt.TREE_BASE, (Vector2(x, y) + Vector2(0.5, 0.7)) * TS + j, H3Art._hash(x, y, 5) > 0.5)
	for t: Vector2 in INNER_TREES:
		if tile(int(t.x), int(t.y)) in BLOCK:
			continue
		var at := (t + Vector2(0.5, 0.7)) * TS
		_prop(PtArt.tree(int(t.x + t.y) % 4), PtArt.TREE_BASE, at)
		_circle(body, at + Vector2(0, -2), 6.0)
	for pl: Array in PILLARS:
		var at := (Vector2(pl[0], pl[1]) + Vector2(0.5, 0.75)) * TS
		_prop(PtArt.pillar(bool(pl[2]), bool(pl[3]), int(pl[0]) + int(pl[1])), PtArt.PILLAR_BASE, at)
		if not bool(pl[3]):
			_box(body, Rect2(at + Vector2(-9, -8), Vector2(18, 9)))
	_prop(PtArt.statue(), PtArt.STATUE_BASE, (Vector2(ISLAND.x, ISLAND.y) + Vector2(0.0, 0.6)) * TS)
	for i in ROCKS.size():
		var r: Vector2 = ROCKS[i]
		if tile(int(r.x), int(r.y)) in BLOCK:
			continue
		var at := (r + Vector2(0.5, 0.7)) * TS
		_prop(PtArt.rock(i), PtArt.ROCK_BASE, at)
		_circle(body, at + Vector2(0, -4), 7.0)
	var nb := 0
	for y in MH: # 숲 가장자리 덤불 (막지 않음)
		for x in MW:
			if nb >= 16 or not tile(x, y) in [GRASS, FLOWER] or H3Art._hash(x, y, 8) < 0.55:
				continue
			if tile(x - 1, y) == FOREST or tile(x + 1, y) == FOREST or tile(x, y - 1) == FOREST:
				_prop(PtArt.bush(nb % 3), PtArt.BUSH_BASE, (Vector2(x, y) + Vector2(0.5, 0.8)) * TS, nb % 2 == 0)
				nb += 1


# ─── 입력 · 카메라 ──────────────────────────────────

func _input(ev: InputEvent) -> void:
	var st := ev as InputEventScreenTouch
	if st != null:
		if st.pressed and _touch_id < 0 and st.position.x < get_viewport_rect().size.x * 0.5:
			_touch_id = st.index
			_touch_o = st.position
		elif not st.pressed and st.index == _touch_id:
			_touch_id = -1
			hero.touch_vec = Vector2.ZERO
		return
	var sd := ev as InputEventScreenDrag
	if sd != null and sd.index == _touch_id:
		hero.touch_vec = ((sd.position - _touch_o) / 28.0).limit_length(1.0)


func _unhandled_input(ev: InputEvent) -> void:
	var k := ev as InputEventKey
	if k != null and k.pressed and not k.echo and k.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://ui/title.tscn")


func _process(delta: float) -> void:
	var want := hero.position - Vector2(0, VIEW_LIFT)
	_cam_pos = _cam_pos.lerp(want, 1.0 - exp(-delta * 7.0))
	var half := get_viewport_rect().size * 0.5
	_cam_pos = Vector2(clampf(_cam_pos.x, half.x, MW * TS - half.x), clampf(_cam_pos.y, half.y, MH * TS - half.y))
	cam.position = _cam_pos.round() # 화면 픽셀에 맞춤


# ─── HUD ───────────────────────────────────────────

class PtHud extends Control:
	var field: Node2D

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var r := get_viewport_rect().size
		TTheme.text(self, Vector2(10, 18), "용사 파티 탐험 — 틀 시안", 12, TTheme.GOLD)
		TTheme.text(self, Vector2(10, 31), "숲속 유적 · 그림은 코드 임시 (AI 그림으로 바꿀 자리)", 8, TTheme.TEXT_SUB)
		var h: PtHero = field.get("hero")
		var t := Vector2i((h.position / float(TS)).floor())
		TTheme.text(self, Vector2(10, r.y - 8), "칸 (%d, %d) · %d FPS" % [t.x, t.y, Engine.get_frames_per_second()], 8, TTheme.TEXT_SUB)
		TTheme.text(self, Vector2(r.x - 10, r.y - 8), "WASD · 방향키 · 패드 이동 · Esc 타이틀", 8, TTheme.TEXT_SUB, HORIZONTAL_ALIGNMENT_RIGHT)
		var tid: int = field.get("_touch_id")
		if tid >= 0: # 터치 조이스틱 (폰 시험용)
			var o: Vector2 = field.get("_touch_o")
			draw_arc(o, 28.0, 0.0, TAU, 32, Color(1, 1, 1, 0.35), 1.0)
			draw_circle(o + h.touch_vec * 28.0, 9.0, Color(1, 1, 1, 0.3))
