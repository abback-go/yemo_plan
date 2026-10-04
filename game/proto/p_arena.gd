extends Node2D
## 전투 시제품 훈련장 (타이틀 → "전투 시제품"). 데모 본편과 따로 돌아간다.
## 구역: 여우 석등(쉬기) · 허수아비 마당(작은 둘·갑옷 하나·매달린 모래주머니) · 발판 · 벽 점프 굴뚝 · 발사대.

const W := 1440.0
const FLOOR := 400.0
const CEIL := 96.0

var sera: PSera
var hud: PHud
var panel: PPanel
var _lantern := Vector2(64, FLOOR)
var _t := 0.0


func _ready() -> void:
	PState.register_keys()
	Engine.time_scale = 1.0
	get_tree().paused = false
	Fx.reset()
	var fx := Node2D.new()
	fx.name = "Effects"
	fx.z_index = 5
	add_child(fx)
	_build_background()
	_build_world()
	_build_props()
	sera = PSera.new()
	sera.position = Vector2(150, FLOOR)
	add_child(sera)
	sera.set_respawn(Vector2(90, FLOOR))
	var cam := PCamera.new()
	cam.target = sera
	cam.limit_left = 0
	cam.limit_right = int(W)
	cam.limit_top = int(CEIL - 40)
	cam.limit_bottom = int(FLOOR + 74) # 아래 마법 칸이 땅을 가리지 않게
	add_child(cam)
	cam.global_position = sera.global_position
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	hud = PHud.new()
	hud.sera = sera
	layer.add_child(hud)
	var top := CanvasLayer.new()
	top.layer = 30
	top.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(top)
	panel = PPanel.new()
	panel.sera = sera
	top.add_child(panel)
	Music.play("boss")


func _process(delta: float) -> void:
	_t += delta
	if Input.is_action_just_pressed("pr_exit") and not panel.visible:
		Fx.reset()
		GameState.go_title()
		return
	# 여우 석등에서 쉬기
	if sera.global_position.distance_to(_lantern) < 26.0 and Input.is_action_just_pressed("pr_up") and sera.st == PSera.St.NORMAL and sera.is_on_floor():
		sera.rest()
		sera.set_respawn(_lantern + Vector2(24, 0))
	queue_redraw()


## 시험 실행기 eval용: PState 값 바꾸기 (eval "dbg('tails', 9)")
func dbg(key: String, value: Variant) -> void:
	match key:
		"key_mode":
			PState.key_mode = int(value)
			PState.register_keys()
		"tails": PState.tails = int(value)
		"od_mult": PState.od_mult = float(value)
		"no_cooldown": PState.no_cooldown = bool(value)
		"evade": PState.evade = bool(value)
		"launcher_on": PState.launcher_on = bool(value)
		"all_lv":
			for s: Dictionary in PData.SPELLS:
				PState.levels[s.id] = int(s.max_lv) if bool(value) else 1


# ═══════════════════════════════════════════════════════════
# 지형 (사각형 몸체) — 바닥·천장·양 벽·발판·벽 점프 굴뚝
# ═══════════════════════════════════════════════════════════

var _solids: Array[Rect2] = []


func _solid(r: Rect2, layer := 1) -> void:
	var b := StaticBody2D.new()
	b.collision_layer = layer
	b.collision_mask = 0
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = r.size
	cs.shape = rs
	cs.position = r.get_center()
	b.add_child(cs)
	add_child(b)
	if layer == 1:
		_solids.append(r)


func _build_world() -> void:
	_solid(Rect2(-40, FLOOR, W + 80, 120)) # 바닥
	_solid(Rect2(-40, CEIL - 60, W + 80, 60)) # 천장
	_solid(Rect2(-40, CEIL - 60, 56, FLOOR - CEIL + 180)) # 왼쪽 벽
	_solid(Rect2(W - 16, CEIL - 60, 56, FLOOR - CEIL + 180)) # 오른쪽 벽
	# 발판 계단
	_solid(Rect2(600, 340, 80, 10))
	_solid(Rect2(712, 284, 72, 10))
	# 벽 점프 굴뚝: 두 벽 사이(폭 56) 위로 올라가면 꼭대기 발판
	_solid(Rect2(840, 168, 18, FLOOR - 168))
	_solid(Rect2(914, 200, 18, FLOOR - 200 - 40)) # 오른쪽 벽은 아래가 뚫려 들어갈 수 있게
	_solid(Rect2(840, 152, 200, 16)) # 꼭대기


func _build_props() -> void:
	for spec: Array in [["small", Vector2(260, FLOOR)], ["small", Vector2(336, FLOOR)], ["big", Vector2(480, FLOOR)],
			["hang", Vector2(410, 268)], ["hang", Vector2(980, 230)], ["small", Vector2(1190, FLOOR)], ["launcher", Vector2(1360, FLOOR)],
			["small", Vector2(960, 152)]]:
		var d := PDummy.new()
		d.setup(String(spec[0]))
		d.position = spec[1]
		add_child(d)


# ═══════════════════════════════════════════════════════════
# 배경 (한 번만 그리는 정적 그림 + 먼 층은 시차)
# ═══════════════════════════════════════════════════════════

func _build_background() -> void:
	var sky := CanvasLayer.new()
	sky.layer = -10
	add_child(sky)
	var sky_draw := SkyDraw.new()
	sky.add_child(sky_draw)
	var far := Parallax2D.new()
	far.scroll_scale = Vector2(0.35, 0.6)
	far.z_index = -8
	add_child(far)
	var far_draw := FarDraw.new()
	far.add_child(far_draw)


class SkyDraw extends Node2D:
	func _draw() -> void:
		var top := Color("#140b24")
		var bot := Color("#4a2a4e")
		for i in 24:
			var f := float(i) / 23.0
			draw_rect(Rect2(0, i * 15, 640, 16), top.lerp(bot, f * f))
		# 달과 별
		draw_circle(Vector2(520, 70), 26.0, Color(1.0, 0.92, 0.8, 0.12))
		draw_circle(Vector2(520, 70), 18.0, Color("#f6e7c8"))
		draw_circle(Vector2(526, 64), 15.0, Color("#e6d2ae"))
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in 70:
			var p := Vector2(rng.randf() * 640, rng.randf() * 200)
			draw_rect(Rect2(p, Vector2(1, 1)), Color(1, 1, 1, rng.randf_range(0.3, 0.9)))


class FarDraw extends Node2D:
	func _draw() -> void:
		# 먼 학교 첨탑 실루엣
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		var col := Color("#26173a")
		var col2 := Color("#1c1030")
		for i in 14:
			var x := i * 90.0 + rng.randf_range(-20, 20)
			var w := rng.randf_range(30, 60)
			var h := rng.randf_range(80, 170)
			draw_rect(Rect2(x, 330 - h, w, h + 100), col)
			draw_colored_polygon(PackedVector2Array([Vector2(x - 4, 330 - h), Vector2(x + w / 2, 330 - h - rng.randf_range(30, 60)), Vector2(x + w + 4, 330 - h)]), col2)
			for k in 3:
				if rng.randf() < 0.6:
					draw_rect(Rect2(x + w / 2 - 2, 340 - h + k * 26, 4, 7), Color(1, 0.75, 0.4, 0.55))
		draw_rect(Rect2(-200, 330, 1600, 200), Color("#1a0f28"))


func _draw() -> void:
	# 실내 훈련장 벽(뒤판) — 아치와 기둥
	draw_rect(Rect2(16, CEIL, W - 32, FLOOR - CEIL), Color("#2b1c3c", 0.55))
	for i in 12:
		var x := 40.0 + i * 120.0
		draw_rect(Rect2(x, CEIL, 14, FLOOR - CEIL), Color("#22162f"))
		draw_arc(Vector2(x + 67, CEIL + 70), 52.0, PI, TAU, 18, Color("#3a2850"), 3.0)
	# 깃발
	for i in 6:
		var x := 120.0 + i * 220.0
		var sway := sin(_t * 1.6 + i) * 2.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, CEIL + 4), Vector2(x + 24, CEIL + 4), Vector2(x + 24 + sway, CEIL + 54), Vector2(x + 12 + sway, CEIL + 46), Vector2(x + sway, CEIL + 54)]), Color("#7a1f33"))
		draw_circle(Vector2(x + 12 + sway * 0.6, CEIL + 24), 5.0, Color("#f4c95d", 0.8))
	# 지형 몸체 그림
	for r in _solids:
		draw_rect(r, Color("#3d3450"))
		draw_rect(Rect2(r.position, Vector2(r.size.x, 3)), Color("#6e6286"))
		var y := r.position.y + 10
		while y < r.end.y and y < FLOOR + 60:
			draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color("#2c2540"), 1.0)
			y += 12
	# 바닥 무늬
	for i in int(W / 32.0):
		draw_line(Vector2(i * 32.0, FLOOR + 3), Vector2(i * 32.0, FLOOR + 15), Color("#2c2540"), 1.0)
	# 여우 석등
	var l := _lantern
	draw_rect(Rect2(l + Vector2(-8, -6), Vector2(16, 6)), Color("#6b6f7d"))
	draw_rect(Rect2(l + Vector2(-3, -22), Vector2(6, 16)), Color("#7d8191"))
	draw_colored_polygon(PackedVector2Array([l + Vector2(-10, -22), l + Vector2(10, -22), l + Vector2(6, -34), l + Vector2(-6, -34)]), Color("#8a8f9c"))
	draw_colored_polygon(PackedVector2Array([l + Vector2(-12, -34), l + Vector2(12, -34), l + Vector2(0, -42)]), Color("#6b6f7d"))
	var g := 0.7 + 0.3 * sin(_t * 5.0)
	draw_circle(l + Vector2(0, -28), 8.0, Color(PData.FOX_MID, 0.25 * g))
	draw_circle(l + Vector2(0, -28), 3.0, Color(PData.FOX_HOT, g))
	if sera and sera.global_position.distance_to(l) < 26.0:
		_label(l + Vector2(-16, -50), "↑ 쉬기")
	# 구역 표지
	_label(Vector2(250, FLOOR - 70), "허수아비 마당")
	_label(Vector2(842, 140), "벽 점프 굴뚝 ↑")


func _label(p: Vector2, s: String) -> void:
	var f := ThemeDB.fallback_font
	draw_string(f, p + Vector2(1, 1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0, 0, 0, 0.6))
	draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 0.9, 0.7, 0.75))


## 카메라: 세라를 따라가며 진행 방향을 조금 앞서 보여 줌. Fx가 흔들기·확대에 쓰는 shake/punch를 제공
class PCamera extends Camera2D:
	var target: PSera
	var _look := 0.0
	var _shake_amp := 0.0
	var _shake_left := 0.0
	var _shake_time := 0.0
	var _punch := 0.0

	func _ready() -> void:
		position_smoothing_enabled = true
		position_smoothing_speed = 8.0
		Fx.camera = self
		make_current()

	func _exit_tree() -> void:
		if Fx.camera == self:
			Fx.camera = null

	func _process(delta: float) -> void:
		var real := delta / maxf(Engine.time_scale, 0.0001)
		if is_instance_valid(target):
			var want := float(target.facing) * 46.0 * clampf(absf(target.velocity.x) / 150.0, 0.3, 1.0)
			_look = lerpf(_look, want, 1.0 - exp(-real * 2.5))
			global_position = target.global_position + Vector2(_look, -30)
		if _shake_left > 0.0:
			_shake_left -= real
			var fall := clampf(_shake_left / _shake_time, 0.0, 1.0)
			var amp := _shake_amp * fall * fall
			offset = Vector2(randf_range(-amp, amp), randf_range(-amp, amp)).round()
		else:
			offset = Vector2.ZERO
		_punch = move_toward(_punch, 0.0, real * 0.6)
		zoom = Vector2.ONE * (1.0 + _punch)

	func shake(amplitude_px: float, duration: float) -> void:
		if amplitude_px >= _shake_amp * clampf(_shake_left / maxf(_shake_time, 0.001), 0.0, 1.0):
			_shake_amp = amplitude_px
			_shake_time = duration
			_shake_left = duration

	func punch(amount: float) -> void:
		_punch = maxf(_punch, amount)
