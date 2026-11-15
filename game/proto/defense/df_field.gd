extends Node2D
## 성 방어 시안 (2026-11-15 사용자: 그림을 보내며 "이런 느낌의 프로토타입 — 성벽 위가 아니라 평지에서 싸우는, 성을 침공으로부터 지키는 컨셉, 시점은 기존과 비슷하게"). 주소 끝 ?defense.
## 고른 것: 엘프 궁수 조작 · 병사는 서 있기만(연출) · 성문 체력 + 웨이브 3 · 성이 위쪽 · 적 2종(구울·어둠 마법사) · 마우스 조준 + 구르기 · 빌드 없음 · 코드 임시 그림.
## 맵 48×34칸(16px): 위쪽 성벽(탑 둘 · 쇠창살 성문 · 깃발) → 성문 앞 돌바닥(새긴 원) → 풀밭과 흙길 → 아래 적 진지 셋(타락한 땅 · 보라 수정 · 말뚝 · 붉은 깃발). 양옆은 숲.
## 승리: 웨이브 3개를 다 막음. 패배: 성문 체력 0 또는 궁수가 쓰러짐. R 다시 · Esc 타이틀.
## 시점·카메라·땅 셰이더·걷기는 ?party 틀 시안(PtField·PtHero·pt_ground)과 같다. 해 질 녘 보라빛(CanvasModulate) + 화로 빛.

const PtFieldScript := preload("res://proto/party/pt_field.gd")
const TS := 16
const MW := 48
const MH := 37
enum { GRASS, FLOWER, DIRT, STONE, WATER, FOREST, BLIGHT } ## pt_ground 칸 종류와 같은 번호
const WALL_ROWS := 11 ## 성벽이 덮는 줄 (176px)
const COURT := Rect2i(16, 11, 16, 6) ## 성문 앞 돌바닥 (칸)
const ROADS := [[Vector2(24, 16), Vector2(24, 36)], [Vector2(24, 24), Vector2(12, 32), Vector2(8, 36)], [Vector2(24, 24), Vector2(36, 32), Vector2(40, 36)]]
const CAMPS := [Vector4(8, 35, 7, 3.2), Vector4(40, 35, 7, 3.2), Vector4(24, 36.5, 5, 2.2)] ## 적 진지 (가운데 x, y, 반지름 — 칸)
const SPAWNS := [Vector2(8, 35), Vector2(24, 36), Vector2(40, 35)] ## 적이 나오는 자리 (칸)
const GATE_HP := 400
const WAVES := [[["ghoul", 8]], [["ghoul", 10], ["mage", 3]], [["ghoul", 14], ["mage", 5]]] ## 웨이브마다 [종류, 수]
const SPAWN_GAP := Vector2(0.6, 1.2) ## 적 사이 나오는 간격 (초, 무작위)
const WAVE_PAUSE := 3.5
const ARROW_SPEED := 330.0
const ARROW_LIFE := 0.9 ## 사거리 ≈ 300px
const ARROW_DMG := 10
const ORB_SPEED := 105.0
const ORB_LIFE := 3.0
const ROCKS := [Vector2(12, 22), Vector2(35, 21), Vector2(18, 29), Vector2(31, 30)]
const VIEW_LIFT := 14.0
const DUSK := Color(0.76, 0.68, 0.94) ## 해 질 녘 (그림의 보라빛)

const VIGNETTE := """
shader_type canvas_item;
const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
void fragment() {
	float bay = (BAYER[int(mod(FRAGCOORD.y, 4.0)) * 4 + int(mod(FRAGCOORD.x, 4.0))] + 0.5) / 16.0;
	float v = smoothstep(0.40, 0.95, length((UV - 0.5) * vec2(1.5, 1.1))) * 0.6;
	v = floor(v * 8.0 + bay) / 8.0;
	COLOR = vec4(0.06, 0.03, 0.10, v);
}
"""

var grid := PackedByteArray()
var archer: DfArcher
var gate_point := Vector2(DfArt.GATE_X, DfArt.WALL_BOTTOM + 16) ## 적이 성문을 치러 오는 자리
var gate_hp := GATE_HP
var enemies: Array = []
var shots: Array = [] ## {node: Sprite2D, vel, life, dmg, enemy(적의 구슬이면 참)}
var world: Node2D
var cam: Camera2D
var hud: Control
var wave_i := 0
var state := "intro" ## intro · spawn · fight · pause · win · lose
var lose_why := ""
var _queue: Array = [] ## 이번 웨이브에 아직 안 나온 적 종류
var _spawn_t := 0.0
var _state_t := 0.0
var _gate_flash := 0.0
var _shake := 0.0
var _cam_pos := Vector2.ZERO
var _scale_was: Array = []
var _touch_move := -1
var _touch_move_o := Vector2.ZERO
var _touch_fire := -1
var flames: Array = []
var _t := 0.0


func _ready() -> void:
	var win := get_tree().root
	_scale_was = [win.content_scale_stretch, win.content_scale_aspect]
	win.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	var cm := CanvasModulate.new()
	cm.color = DUSK
	add_child(cm)
	_gen_map()
	_build_ground()
	var w := Sprite2D.new()
	w.texture = DfArt.wall()
	w.centered = false
	add_child(w)
	_build_walls()
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	_build_props()
	archer = DfArcher.new()
	archer.position = Vector2(DfArt.GATE_X, DfArt.WALL_BOTTOM + 90)
	archer.shot.connect(_on_shot)
	archer.died.connect(func() -> void: _lose("궁수가 쓰러졌다"))
	world.add_child(archer)
	cam = Camera2D.new()
	add_child(cam)
	cam.make_current()
	_cam_pos = archer.position - Vector2(0, VIEW_LIFT)
	var fx := CanvasLayer.new()
	fx.layer = 5
	add_child(fx)
	var vg := ColorRect.new()
	vg.set_anchors_preset(Control.PRESET_FULL_RECT)
	vg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = VIGNETTE
	var sm := ShaderMaterial.new()
	sm.shader = sh
	vg.material = sm
	fx.add_child(vg)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	hud = DfHud.new()
	hud.field = self
	layer.add_child(hud)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN # 조준점은 HUD가 그림
	_state_t = 2.0
	Sfx.play(&"tn_wave", -4.0)


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
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


func _gen_map() -> void:
	var n := FastNoiseLite.new()
	n.seed = 23
	n.frequency = 0.2
	grid.resize(MW * MH)
	for y in MH:
		for x in MW:
			var t := GRASS
			var p := Vector2(x, y)
			if y < WALL_ROWS or COURT.has_point(Vector2i(x, y)):
				t = STONE
			for e: Vector4 in CAMPS:
				var dx := (float(x) - e.x) / e.z
				var dy := (float(y) - e.y) / e.w
				if dx * dx + dy * dy + n.get_noise_2d(x * 2.0, y * 2.0) * 0.3 < 1.0:
					t = BLIGHT
			if t == GRASS:
				for r: Array in ROADS:
					if PtFieldScript._seg_dist(p, r) < 1.2 + n.get_noise_2d(x * 3.0 + 7.0, y * 3.0) * 0.4:
						t = DIRT
			if y >= WALL_ROWS and (x < 2 or x > MW - 3 or float(mini(x, MW - 1 - x)) < 1.5 + n.get_noise_2d(x * 1.0 + 40.0, y * 1.0) * 1.2):
				t = FOREST
			grid[y * MW + x] = t


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
	m.set_shader_parameter("plaza_c", Vector2(DfArt.GATE_X, DfArt.WALL_BOTTOM + 52)) # 성문 앞 새긴 원
	m.set_shader_parameter("roots", 0.0)
	g.material = m
	add_child(g)


func _build_walls() -> void:
	var body := StaticBody2D.new()
	add_child(body)
	var tl := Rect2(DfArt.TOWER_L)
	var tr := Rect2(DfArt.TOWER_R)
	for r: Rect2 in [Rect2(0, 0, MW * TS, DfArt.WALL_BOTTOM - 2), Rect2(tl.position, tl.size - Vector2(0, 2)), Rect2(tr.position, tr.size - Vector2(0, 2)),
			Rect2(-TS, MH * TS, (MW + 2) * TS, TS), Rect2(-TS, 0, TS, MH * TS), Rect2(MW * TS, 0, TS, MH * TS)]:
		_box(body, r)
	for y in range(WALL_ROWS, MH):
		var x := 0
		while x < MW:
			if tile(x, y) != FOREST:
				x += 1
				continue
			var x0 := x
			while x < MW and tile(x, y) == FOREST:
				x += 1
			_box(body, Rect2(x0 * TS, y * TS, (x - x0) * TS, TS))


func _box(body: StaticBody2D, r: Rect2) -> void:
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = r.size
	cs.shape = sh
	cs.position = r.get_center()
	body.add_child(cs)


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
	# 화로 둘 (탑 앞) + 불꽃 + 빛
	for bx: float in [DfArt.TOWER_L.get_center().x, DfArt.TOWER_R.get_center().x]:
		var at := Vector2(bx, DfArt.WALL_BOTTOM + 22)
		var br := _prop(DfArt.brazier(), DfArt.BRAZIER_BASE, at)
		var fl := Sprite2D.new()
		fl.texture = DfArt.flame()
		fl.hframes = 3
		fl.position = Vector2(0, -27)
		br.add_child(fl)
		flames.append(fl)
		var gl := Sprite2D.new()
		gl.texture = DfArt.glow()
		gl.scale = Vector2(5, 4)
		gl.position = Vector2(0, -18)
		gl.modulate = Color(1.0, 0.55, 0.2, 0.35)
		var add := CanvasItemMaterial.new()
		add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		gl.material = add
		br.add_child(gl)
		var cs := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 6.0
		cs.shape = c
		cs.position = at + Vector2(0, -3)
		body.add_child(cs)
	# 서 있는 병사 넷 (연출만 — 싸우지 않고 막지도 않음)
	var wb := float(DfArt.WALL_BOTTOM)
	var soldiers := [[292.0, wb + 14.0, false], [266.0, wb + 20.0, true], [476.0, wb + 14.0, false], [502.0, wb + 20.0, true]]
	for sd: Array in soldiers:
		var s := _prop(DfArt.soldier_sheet(bool(sd[2])), DfArt.PERSON_FEET, Vector2(sd[0], sd[1]), float(sd[0]) > float(DfArt.GATE_X))
		s.hframes = 2
		s.set_meta("ph", randf() * 2.0)
	# 양옆 숲 나무
	var taken := {}
	for y in range(WALL_ROWS, MH):
		for x in MW:
			if tile(x, y) != FOREST or H3Art._hash(x, y, 1) > 0.55:
				continue
			if taken.has(Vector2i(x - 1, y)) or taken.has(Vector2i(x, y - 1)) or taken.has(Vector2i(x - 1, y - 1)):
				continue
			taken[Vector2i(x, y)] = true
			_prop(PtArt.tree(int(H3Art._hash(x, y, 4) * 4.0)), PtArt.TREE_BASE, (Vector2(x, y) + Vector2(0.5, 0.8)) * TS, H3Art._hash(x, y, 5) > 0.5)
	for i in ROCKS.size():
		var at: Vector2 = (ROCKS[i] + Vector2(0.5, 0.7)) * TS
		_prop(PtArt.rock(i), PtArt.ROCK_BASE, at)
		var cs := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 7.0
		cs.shape = c
		cs.position = at + Vector2(0, -4)
		body.add_child(cs)
	# 적 진지: 말뚝 · 붉은 깃발 · 보라 수정 (막지 않음)
	for i in CAMPS.size():
		var cp := Vector2(CAMPS[i].x, CAMPS[i].y) * TS
		_prop(DfArt.barricade(i % 2), DfArt.BARRICADE_BASE, cp + Vector2(-46, -30))
		_prop(DfArt.barricade((i + 1) % 2), DfArt.BARRICADE_BASE, cp + Vector2(46, -26), true)
		_prop(DfArt.enemy_banner(), DfArt.BANNER_BASE, cp + Vector2(-22, -8))
		_prop(DfArt.crystal(), DfArt.CRYSTAL_BASE, cp + Vector2(30, 4))
		_prop(DfArt.crystal(), DfArt.CRYSTAL_BASE, cp + Vector2(-60, 2), true)


# ─── 웨이브 ─────────────────────────────────────────

func _start_wave() -> void:
	_queue.clear()
	for part: Array in WAVES[wave_i]:
		for k in int(part[1]):
			_queue.append(String(part[0]))
	_queue.shuffle()
	state = "spawn"
	_spawn_t = 0.3


func _spawn(kind_name: String) -> void:
	var e := DfEnemy.new()
	e.setup(DfEnemy.Kind.MAGE if kind_name == "mage" else DfEnemy.Kind.GHOUL, self)
	var sp: Vector2 = SPAWNS[randi() % SPAWNS.size()]
	e.position = sp * TS + Vector2(randf_range(-20, 20), randf_range(-6, 6))
	world.add_child(e)
	enemies.append(e)


func on_enemy_dead(e: DfEnemy) -> void:
	enemies.erase(e)


func damage_gate(n: int) -> void:
	if state in ["win", "lose"]:
		return
	gate_hp = maxi(gate_hp - n, 0)
	_gate_flash = 0.2
	_shake = maxf(_shake, 2.0)
	Sfx.play(&"block", -8.0)
	if gate_hp <= 0:
		_lose("성문이 부서졌다")


func _lose(why: String) -> void:
	if state in ["win", "lose"]:
		return
	state = "lose"
	lose_why = why
	Sfx.play(&"tn_defeat", -2.0)


func _step_waves(delta: float) -> void:
	_state_t -= delta
	match state:
		"intro", "pause":
			if _state_t <= 0.0:
				_start_wave()
		"spawn":
			_spawn_t -= delta
			if _spawn_t <= 0.0 and not _queue.is_empty():
				_spawn(String(_queue.pop_back()))
				_spawn_t = randf_range(SPAWN_GAP.x, SPAWN_GAP.y)
			if _queue.is_empty():
				state = "fight"
		"fight":
			if enemies.is_empty():
				wave_i += 1
				if wave_i >= WAVES.size():
					state = "win"
					Sfx.play(&"tn_victory", -2.0)
				else:
					state = "pause"
					_state_t = WAVE_PAUSE
					Sfx.play(&"tn_wave", -4.0)


# ─── 화살 · 구슬 ────────────────────────────────────

func _on_shot(from: Vector2, dir: Vector2) -> void:
	_add_shot(DfArt.arrow(), from, dir * ARROW_SPEED, ARROW_LIFE, ARROW_DMG, false)


func spawn_orb(from: Vector2, dir: Vector2, dmg: int) -> void:
	_add_shot(DfArt.orb(), from, dir * ORB_SPEED, ORB_LIFE, dmg, true)


func _add_shot(tex: Texture2D, from: Vector2, vel: Vector2, life: float, dmg: int, hostile: bool) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.rotation = vel.angle() if not hostile else 0.0
	s.position = from.round()
	s.z_index = 2 # 날아가는 것은 땅 위 인물·소품보다 위에 (y 정렬 밖)
	if hostile:
		s.modulate = Color(1.6, 1.3, 1.8)
	add_child(s)
	shots.append({"node": s, "vel": vel, "life": life, "dmg": dmg, "hostile": hostile, "pos": from})


func _step_shots(delta: float) -> void:
	for i in range(shots.size() - 1, -1, -1):
		var sh: Dictionary = shots[i]
		var node: Sprite2D = sh.node
		sh.life = float(sh.life) - delta
		var p: Vector2 = sh.pos + Vector2(sh.vel) * delta
		sh.pos = p
		var done := float(sh.life) <= 0.0 or p.y < float(DfArt.WALL_BOTTOM) - 4.0 # 성벽에 박힘
		if bool(sh.hostile):
			if archer.alive and p.distance_to(archer.global_position + DfArcher.HAND) < 7.0:
				if archer.hurt(int(sh.dmg)):
					done = true
			elif p.distance_to(gate_point + Vector2(0, -8)) < 14.0:
				damage_gate(int(sh.dmg))
				done = true
			node.rotation += delta * 8.0
		else:
			for e: DfEnemy in enemies:
				if not e.dead and p.distance_to(e.center()) < DfEnemy.HIT_R:
					e.hit(int(sh.dmg), Vector2(sh.vel).normalized())
					done = true
					break
		if done:
			node.queue_free()
			shots.remove_at(i)
		else:
			node.position = p.round()


# ─── 입력 · 매 프레임 ───────────────────────────────

func _input(ev: InputEvent) -> void:
	var st := ev as InputEventScreenTouch
	if st != null:
		var left := st.position.x < get_viewport_rect().size.x * 0.5
		if st.pressed and left and _touch_move < 0:
			_touch_move = st.index
			_touch_move_o = st.position
		elif st.pressed and not left and _touch_fire < 0:
			_touch_fire = st.index
			_touch_aim(st.position)
		elif not st.pressed and st.index == _touch_move:
			_touch_move = -1
			archer.touch_vec = Vector2.ZERO
		elif not st.pressed and st.index == _touch_fire:
			_touch_fire = -1
			archer.touch_fire = false
		return
	var sd := ev as InputEventScreenDrag
	if sd != null:
		if sd.index == _touch_move:
			archer.touch_vec = ((sd.position - _touch_move_o) / 28.0).limit_length(1.0)
		elif sd.index == _touch_fire:
			_touch_aim(sd.position)


## 폰 시험: 오른쪽 절반을 누른 화면 자리 → 그쪽으로 연사
func _touch_aim(screen: Vector2) -> void:
	var world_p := get_canvas_transform().affine_inverse() * screen
	archer.touch_fire = true
	archer.touch_aim = (world_p - (archer.global_position + DfArcher.HAND)).normalized()


func _unhandled_input(ev: InputEvent) -> void:
	var k := ev as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if k.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://ui/title.tscn")
	elif k.keycode == KEY_R:
		get_tree().reload_current_scene()


func _process(delta: float) -> void:
	_t += delta
	_gate_flash -= delta
	_shake = maxf(_shake - delta * 10.0, 0.0)
	if not state in ["win", "lose"]:
		_step_waves(delta)
	_step_shots(delta)
	for i in flames.size():
		(flames[i] as Sprite2D).frame = int(_t * 9.0 + float(i) * 1.3) % 3
	for s in world.get_children():
		if s.has_meta("ph"):
			(s as Sprite2D).frame = int(_t * 1.4 + float(s.get_meta("ph"))) % 2
	var want := archer.position - Vector2(0, VIEW_LIFT)
	_cam_pos = _cam_pos.lerp(want, 1.0 - exp(-delta * 7.0))
	var half := get_viewport_rect().size * 0.5
	_cam_pos = Vector2(clampf(_cam_pos.x, half.x, MW * TS - half.x), clampf(_cam_pos.y, half.y, MH * TS - half.y))
	var sk := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
	cam.position = (_cam_pos + sk).round()


# ─── HUD ───────────────────────────────────────────

class DfHud extends Control:
	var field: Node2D

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_d: float) -> void:
		queue_redraw()

	func _bar(r: Rect2, ratio: float, col: Color, label: String, flash := false) -> void:
		draw_rect(r.grow(1), Color(0.05, 0.03, 0.08, 0.85))
		draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(ratio, 0.0, 1.0), r.size.y)), Color(1, 1, 1) if flash else col)
		TTheme.text(self, r.position + Vector2(0, -3), label, 8, TTheme.TEXT)

	func _draw() -> void:
		var r := get_viewport_rect().size
		var f := field
		var a: DfArcher = f.get("archer")
		_bar(Rect2(10, 22, 110, 6), float(a.hp) / float(DfArcher.HP_MAX), Color("#7ad06a"), "엘프 궁수  %d/%d" % [a.hp, DfArcher.HP_MAX])
		var gh: int = f.get("gate_hp")
		_bar(Rect2(r.x * 0.5 - 80, 22, 160, 6), float(gh) / float(f.GATE_HP), Color("#e2b44c"), "성문  %d/%d" % [gh, f.GATE_HP], float(f.get("_gate_flash")) > 0.0)
		var wi: int = f.get("wave_i")
		var n_left: int = (f.get("enemies") as Array).size() + (f.get("_queue") as Array).size()
		TTheme.text(self, Vector2(r.x - 10, 20), "웨이브 %d/%d · 남은 적 %d" % [mini(wi + 1, f.WAVES.size()), f.WAVES.size(), n_left], 10, TTheme.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
		TTheme.text(self, Vector2(r.x - 10, r.y - 8), "WASD 이동 · 마우스 조준 · 왼클릭 누르고 사격 · Space 구르기 · R 다시 · Esc 타이틀", 8, TTheme.TEXT_SUB, HORIZONTAL_ALIGNMENT_RIGHT)
		TTheme.text(self, Vector2(10, r.y - 8), "성 방어 시안 — 그림은 코드 임시", 8, TTheme.TEXT_SUB)
		var st: String = f.get("state")
		var t: float = f.get("_state_t")
		if st == "intro" or st == "pause":
			_banner("웨이브 %d" % (wi + 1), "적이 몰려온다 — 성문을 지켜라" if wi == 0 else "%.0f초 뒤" % ceilf(maxf(t, 0.0)))
		elif st == "win":
			_banner("승리", "성을 지켜냈다 · R 다시 · Esc 타이틀")
		elif st == "lose":
			_banner("패배", "%s · R 다시 · Esc 타이틀" % String(f.get("lose_why")))
		if Input.mouse_mode == Input.MOUSE_MODE_HIDDEN: # 조준점
			var m := get_viewport().get_mouse_position()
			for d: Vector2 in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
				draw_line(m + d * 3.0, m + d * 6.0, Color(1, 0.95, 0.8, 0.9), 1.0)
			draw_rect(Rect2(m, Vector2(1, 1)), Color(1, 0.6, 0.3))

	func _banner(title: String, sub: String) -> void:
		var r := get_viewport_rect().size
		draw_rect(Rect2(0, r.y * 0.36, r.x, 46), Color(0.04, 0.02, 0.08, 0.6))
		TTheme.text(self, Vector2(r.x * 0.5, r.y * 0.36 + 24), title, 15, TTheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		TTheme.text(self, Vector2(r.x * 0.5, r.y * 0.36 + 38), sub, 10, TTheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
