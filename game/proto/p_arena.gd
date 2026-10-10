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


func _ready() -> void:
	PState.register_keys()
	Engine.time_scale = 1.0
	get_tree().paused = false
	Fx.reset()
	var fx := Node2D.new()
	fx.name = "Effects"
	fx.z_index = 5
	add_child(fx)
	_build_world()
	var scenery := PScenery.build(self, _solids, _lantern)
	_build_props()
	sera = PSera.new()
	sera.position = Vector2(150, FLOOR)
	add_child(sera)
	(scenery.live as PScenery.HallLive).sera = sera
	(scenery.vignette as PScenery.Vignette).sera = sera
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
	if PBench.wanted():
		var b := PBench.new()
		b.arena = self
		add_child(b)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pr_exit") and not panel.visible:
		Fx.reset()
		GameState.go_title()
		return
	# 여우 석등에서 쉬기
	if sera.global_position.distance_to(_lantern) < 26.0 and Input.is_action_just_pressed("pr_up") and sera.st == PSera.St.NORMAL and sera.is_on_floor():
		sera.rest()
		sera.set_respawn(_lantern + Vector2(24, 0))


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


## 카메라: 세라를 따라가며 진행 방향을 조금 앞서 보여 줌. Fx가 흔들기·확대에 쓰는 shake/punch를 제공
class PCamera extends Camera2D:
	var target: CharacterBody2D ## 세라(PSera) 또는 에스카(EEska) — facing 값을 가진 몸
	var _look := 0.0
	var look_y := -30.0 ## 몸보다 이만큼 위를 화면 가운데로
	var _shake_amp := 0.0
	var _shake_left := 0.0
	var _shake_time := 0.0
	var _punch := 0.0
	var _kick := Vector2.ZERO ## 타격 방향으로 밀렸다가 용수철처럼 돌아오는 화면
	var _kick_v := Vector2.ZERO

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
			var want := float(target.get("facing")) * 46.0 * clampf(absf(target.velocity.x) / 150.0, 0.3, 1.0)
			_look = lerpf(_look, want, 1.0 - exp(-real * 2.5))
			global_position = target.global_position + Vector2(_look, look_y)
		# 멈춤(hitstop)으로 time_scale이 0에 가까우면 real이 튀므로 한 프레임 길이로 자름 (용수철이 폭주하지 않게)
		var kd := minf(real, 1.0 / 30.0)
		_kick_v += (-_kick * 900.0 - _kick_v * 34.0) * kd
		_kick += _kick_v * kd
		if _shake_left > 0.0:
			_shake_left -= real
			var fall := clampf(_shake_left / _shake_time, 0.0, 1.0)
			var amp := _shake_amp * fall * fall
			offset = (Vector2(randf_range(-amp, amp), randf_range(-amp, amp)) + _kick).round()
		else:
			offset = _kick.round()
		_punch = move_toward(_punch, 0.0, real * 0.6)
		zoom = Vector2.ONE * (1.0 + _punch)

	func shake(amplitude_px: float, duration: float) -> void:
		if amplitude_px >= _shake_amp * clampf(_shake_left / maxf(_shake_time, 0.001), 0.0, 1.0):
			_shake_amp = amplitude_px
			_shake_time = duration
			_shake_left = duration

	## 화면을 v 방향으로 순간 밀었다가 되돌림 (던진·맞은 방향의 손맛)
	func kick(v: Vector2) -> void:
		_kick = v
		_kick_v = v * 18.0

	func punch(amount: float) -> void:
		_punch = maxf(_punch, amount)
