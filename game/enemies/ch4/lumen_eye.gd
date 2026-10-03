class_name LumenEye
extends EnemyBase
## 빛의 감시안 (docs/chapter4.md 4절·7.4절): 신전 천장에 떠 있는 금빛 눈. 여섯 갈래 빛 날개가 천천히 돈다.
## 세라를 눈으로 좇다가 **빛줄기를 쓸어 온다**: 예고(붉은 조준선 + 쓸고 갈 부채꼴 끝선, 0.9초) → 1.3초 동안 금빛 빛줄기가 호를 그림 → 눈이 달아올라 1초 빈틈(피해 1.5배).
## 빛줄기는 벽에서 멈추고, 거울(light_mirror)에서 꺾이며, 불꽃 방벽에 닿으면 세라가 보는 쪽으로 되쏘아진다(수정을 밝힐 수 있음).
## 퍼즐 광원: source = true 이면 싸우지 않고(무적, 몸 피해 없음) beam_deg 방향으로 빛줄기를 계속 쏜다 — 거울 미로의 빛의 근원.

enum S { HOVER, AIM, SWEEP, HOT, SOURCE }

const H := preload("res://enemies/ch4/holy.gd")
const VIS := preload("res://enemies/ch4/lumen_eye_visual.gd")

const HP := 700
const AIM_TIME := 0.9
const SWEEP_TIME := 1.3
const SWEEP_ARC := 1.15 ## 라디안 (약 66도)
const HOT_TIME := 1.0
const REST := Vector2(1.6, 2.4)
const BEAM_LEN := 22.0 * 16.0
const BEAM_W := 7.0
const KEEP_T := 7.0

var state: S = S.HOVER
var source := false ## 퍼즐 광원 (방 데이터에서 source=true)
var beam_deg := 0.0 ## 광원일 때 빛줄기 방향 (0 = 오른쪽, 90 = 아래)
var look_dir := Vector2.LEFT ## 눈동자가 보는 방향 (그림)
var beam_pts := PackedVector2Array() ## 지금 빛줄기 경로 (전역)
var aim_from := 0.0
var aim_to := 0.0
var _timer := 0.0
var _dur := 0.0
var _home := Vector2.INF
var _segs: Array = []


func _build() -> void:
	max_hp = HP
	body_size = Vector2(22, 22)
	flying = true
	knock_mult = 0.3
	launch_mult = 0.0
	display_name = "빛의 감시안"
	subtitle = "신전은 모든 것을 본다"
	kind_id = "lumen_eye"
	var v: Node2D = VIS.new()
	v.set("enemy", self)
	_visual = v
	add_child(v)
	for i in 7:
		var a := H.SegmentArea.new()
		a.cause = &"lumen_eye"
		a.damage = 1
		a.dodgeable = true
		a.active = false
		add_child(a)
		_segs.append(a)


func _ready() -> void:
	super()
	collision_mask = 0 # 떠 있는 눈은 지형과 부딪히지 않는다 (제자리 근처를 떠돎)
	if source:
		state = S.SOURCE
		is_elite = false
		display_name = ""
		contact_damage = 0
		hp = max_hp


func progress() -> float:
	return clampf(1.0 - _timer / _dur, 0.0, 1.0) if _dur > 0.0 else 1.0


func _go(s: S, time := 0.0) -> void:
	state = s
	_timer = time
	_dur = time


func beam_dir() -> Vector2:
	match state:
		S.SOURCE:
			return Vector2.RIGHT.rotated(deg_to_rad(beam_deg))
		S.SWEEP:
			return Vector2.RIGHT.rotated(lerpf(aim_from, aim_to, progress()))
		S.AIM:
			return Vector2.RIGHT.rotated(aim_from)
	return look_dir


func eye_pos() -> Vector2:
	return global_position + Vector2(0, -11)


func _ai(delta: float) -> void:
	if _home == Vector2.INF:
		_home = global_position
	var t := GameConst.TILE
	var bob := sin(_t * 1.6) * 0.35 * t
	if state == S.SOURCE:
		velocity = Vector2.ZERO
		global_position = _home + Vector2(0, bob * 0.3)
		look_dir = beam_dir()
		_update_beam(delta, false)
		return
	var p := player()
	_timer -= delta
	if p and p.is_alive() and engaged:
		var to := p.center() - eye_pos()
		if state == S.HOVER or state == S.HOT:
			look_dir = look_dir.slerp(to.normalized(), clampf(delta * 4.0, 0.0, 1.0))
		# 떠돌기: 세라와 KEEP_T 거리를 두고 제자리 둘레에서 좌우로
		var want_x := _home.x
		var dx := p.global_position.x - _home.x
		if absf(dx) > KEEP_T * t:
			want_x = _home.x + signf(dx) * minf(absf(dx) - KEEP_T * t, 4.0 * t)
		var target := Vector2(want_x, _home.y + bob)
		velocity = (target - global_position) * 2.0 if state != S.SWEEP else Vector2.ZERO
	else:
		velocity = Vector2(0, (_home.y + bob - global_position.y) * 2.0)
	match state:
		S.HOVER:
			_beam_off()
			if _timer <= 0.0 and p and p.is_alive() and engaged and eye_pos().distance_to(p.center()) < 16.0 * t:
				_start_aim(p)
		S.AIM:
			_beam_off()
			if _timer <= 0.0:
				_go(S.SWEEP, SWEEP_TIME)
				H.snd(&"holy_charge", &"sniper_shot", -4.0)
				Fx.shake(0.08, 0.2)
		S.SWEEP:
			look_dir = beam_dir()
			_update_beam(delta, true)
			if Engine.get_physics_frames() % 4 == 0 and beam_pts.size() >= 2:
				var endp := beam_pts[beam_pts.size() - 1]
				Fx.burst(endp, 3, {
					direction = Vector2.UP, spread = 70.0, speed_min = 20.0, speed_max = 80.0, lifetime = 0.3,
					gradient = H.gold_grad(), size_min = 1.0, size_max = 2.5, gravity = Vector2(0, 200), add = true,
				})
			if _timer <= 0.0:
				_beam_off()
				_go(S.HOT, HOT_TIME)
		S.HOT:
			if _timer <= 0.0:
				_go(S.HOVER, Difficulty.rest(randf_range(REST.x, REST.y)))


## 조준: 세라 쪽에서 부채꼴 한쪽 끝부터 반대 끝까지 쓸어 올 각도를 정한다
func _start_aim(p: Player) -> void:
	var to := (p.center() - eye_pos()).angle()
	var side := 1.0 if randf() < 0.5 else -1.0
	aim_from = to - side * SWEEP_ARC * 0.55
	aim_to = to + side * SWEEP_ARC * 0.45
	_go(S.AIM, Difficulty.telegraph(AIM_TIME))
	H.snd(&"sniper_aim", &"sniper_aim", -4.0)


func _update_beam(delta: float, hurts: bool) -> void:
	var space := get_world_2d().direct_space_state
	beam_pts = H.trace(space, eye_pos(), beam_dir(), BEAM_LEN, true, delta)
	for i in _segs.size():
		var a: H.SegmentArea = _segs[i]
		if hurts and i < beam_pts.size() - 1:
			a.set_segment(beam_pts[i], beam_pts[i + 1], BEAM_W)
			a.active = true
		else:
			a.active = false


func _beam_off() -> void:
	beam_pts = PackedVector2Array()
	for a in _segs:
		(a as EnemyAttackArea).active = false


## 조준 중 그릴 예고선 (전역 경로): 시작선과 끝선
func aim_lines() -> Array:
	if state != S.AIM:
		return []
	var space := get_world_2d().direct_space_state
	var a := H.trace(space, eye_pos(), Vector2.RIGHT.rotated(aim_from), BEAM_LEN, false)
	var b := H.trace(space, eye_pos(), Vector2.RIGHT.rotated(aim_to), BEAM_LEN, false)
	return [a, b]


func modify_damage(hit: Hit) -> float:
	if source:
		return 0.0
	return 1.5 if state == S.HOT else 1.0


func _on_blocked(hit: Hit) -> void:
	if source:
		H.sparkle(eye_pos(), 6, 6.0)
		return
	super(hit)


func _die(dir: int) -> void:
	_beam_off()
	H.sparkle(eye_pos(), 30, 10.0, 20.0, 0.8)
	Fx.ring(eye_pos(), 4.0, 40.0, H.GOLD, 0.4, 2.0)
	super(dir)
