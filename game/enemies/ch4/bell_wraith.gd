class_name BellWraith
extends EnemyBase
## 종지기 망령 (docs/archive/sera/chapter4.md 4절·7.4절): 종탑에서 박자를 놓친 채 영원히 종을 치는 옛 종지기의 혼. 해진 회색 두건, 긴 팔,
## 한 손엔 반투명한 유령 종, 한 손엔 끊어진 종 줄. 늘 엇박으로 흥얼거린다.
## - 유령 종 울리기: 종을 들어 올리고(0.8초 예고 — 붉은 고리가 퍼질 범위를 그림) → 퍼져 나가는 소리 고리 2겹(고리 띠에 닿으면 1 피해).
##   고리 안쪽은 안전 — 붙어 있거나, 대시 무적으로 띠를 통과하거나, 멀리.
## - 엇박 세 번 치기: 작은 고리 셋이 빠르게.
## - 진짜 종(temple_bell)을 불기둥으로 울리면: 3초 동안 귀를 막고 바닥으로 내려앉는다(공격 없음, 받는 피해 1.5배, 유령 종에 금이 감).

enum S { DRIFT, RAISE, TOLL, TRIPLE, RECOVER, STUNNED }

const H := preload("res://enemies/ch4/holy.gd")
const VIS := preload("res://enemies/ch4/bell_wraith_visual.gd")

const HP := 800
const KEEP_T := Vector2(4.0, 8.0)
const RAISE_TIME := 0.8
const RING_SPEED_T := 7.5
const RING_MAX_T := 8.0
const RING_BAND := 12.0
const TRIPLE_GAP := 0.32
const REST := Vector2(1.4, 2.2)

var state: S = S.DRIFT
var bell_crack := 0.0 ## 유령 종 금 (그림)
var stun_left := 0.0
var rings: Array = [] ## [{c: Vector2, r: float, alive: bool}] (그림이 읽음)
var _clock := StateClock.new() ## 상태 시간 (남은 시간·길이·진행도)
var _home := Vector2.INF
var _triple_left := 0
var _drift_phase := 0.0


func _build() -> void:
	max_hp = HP
	body_size = Vector2(20, 30)
	flying = true
	knock_mult = 0.5
	launch_mult = 0.0
	display_name = "종지기 망령"
	subtitle = "박자를 놓친 종소리"
	kind_id = "bell_wraith"
	var v: Node2D = VIS.new()
	v.set("enemy", self)
	_visual = v
	add_child(v)
	var c := add_attack_area(Vector2(14, 22), Vector2(0, -14), &"bell_wraith")
	c.dodgeable = false


func _ready() -> void:
	super()
	add_to_group(&"bell_wraith")
	collision_mask = 0
	_drift_phase = randf() * TAU
	_clock.left = 1.2


func progress() -> float:
	return _clock.k()


func _go(s: S, time := 0.0) -> void:
	state = s
	_clock.enter(time)


## 진짜 종이 울림 (TempleBell이 부름)
func bell_stun(sec: float) -> void:
	if not _alive:
		return
	stun_left = sec
	bell_crack = minf(bell_crack + 0.5, 1.0)
	_go(S.STUNNED, sec)
	_triple_left = 0
	H.snd(&"growl", &"growl", -4.0)
	Fx.burst(global_position + Vector2(0, -20), 12, {
		spread = 180.0, speed_min = 20.0, speed_max = 70.0, lifetime = 0.5,
		gradient = H.white_grad(), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 80), add = true,
	})


func is_stunned() -> bool:
	return state == S.STUNNED


func _ai(delta: float) -> void:
	if _home == Vector2.INF:
		_home = global_position
	var t := GameConst.TILE
	_clock.tick(delta)
	_tick_rings(delta)
	var p := player()
	# 떠돌기 (멈췄을 땐 바닥으로 내려앉음)
	if state == S.STUNNED:
		var space := get_world_2d().direct_space_state
		var fy := H.floor_below(space, global_position + Vector2(0, -4), 12.0 * t)
		var target_y := fy if fy != INF else global_position.y
		velocity = Vector2(0, (target_y - global_position.y) * 4.0)
		if _clock.done():
			stun_left = 0.0
			_go(S.RECOVER, 0.6)
		return
	var target := _home
	if p and p.is_alive() and engaged:
		var dx := p.global_position.x - global_position.x
		var want := global_position.x
		if absf(dx) < KEEP_T.x * t:
			want = global_position.x - signf(dx) * t
		elif absf(dx) > KEEP_T.y * t:
			want = global_position.x + signf(dx) * t
		target = Vector2(clampf(want, _home.x - 10.0 * t, _home.x + 10.0 * t), _home.y)
		facing = 1 if dx >= 0.0 else -1
	var bob := sin(_t * 1.3 + _drift_phase) * 0.5 * t
	var still := state == S.RAISE or state == S.TOLL
	velocity = (target + Vector2(0, bob) - global_position) * (0.8 if not still else 0.2)
	match state:
		S.DRIFT:
			if _clock.done() and p and p.is_alive() and engaged and global_position.distance_to(p.global_position) < 13.0 * t:
				if randf() < 0.35:
					_triple_left = 3
					_go(S.TRIPLE, Difficulty.telegraph(0.5))
				else:
					_go(S.RAISE, Difficulty.telegraph(RAISE_TIME))
				H.snd(&"bell_small", &"blip", -6.0)
		S.RAISE:
			if _clock.done():
				_go(S.TOLL, 0.5)
				_emit_ring(1.0)
				var tw := create_tween()
				tw.tween_interval(0.28)
				tw.tween_callback(func() -> void:
					if _alive and state != S.STUNNED:
						_emit_ring(0.9))
		S.TOLL:
			if _clock.done():
				_go(S.RECOVER, 0.5)
		S.TRIPLE:
			if _clock.done():
				_emit_ring(0.55)
				_triple_left -= 1
				if _triple_left <= 0:
					_go(S.RECOVER, 0.6)
				else:
					_go(S.TRIPLE, TRIPLE_GAP)
		S.RECOVER:
			if _clock.done():
				_go(S.DRIFT, Difficulty.rest(randf_range(REST.x, REST.y)))


func bell_pos() -> Vector2:
	var raise := 1.0 if state in [S.RAISE, S.TOLL, S.TRIPLE] else 0.0
	return global_position + Vector2(facing * 9.0, -24.0 - raise * 6.0)


func _emit_ring(scale: float) -> void:
	var a := EnemyAttackArea.new()
	a.cause = &"bell_wraith"
	a.damage = 1
	a.dodgeable = true
	a.top_level = true
	var cs := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 8.0
	cs.shape = circ
	a.add_child(cs)
	a.monitorable = true
	add_child(a)
	a.global_position = bell_pos()
	rings.append({"c": bell_pos(), "r": 6.0, "max": RING_MAX_T * GameConst.TILE * scale, "area": a, "circle": circ})
	H.snd_pitch(&"bell", &"checkpoint", 0.6 + randf() * 0.1, -2.0)
	Fx.shake(0.05, 0.15)


## 고리 띠 판정: 세라 중심이 고리 띠(r ± BAND/2) 안에 있을 때만 영역을 켠다
func _tick_rings(delta: float) -> void:
	var p := player()
	for ring in rings.duplicate():
		var r: float = float(ring.r) + RING_SPEED_T * GameConst.TILE * delta
		ring.r = r
		var a: EnemyAttackArea = ring.area
		var circ: CircleShape2D = ring.circle
		var c: Vector2 = ring.c
		var on := false
		if p:
			var d := p.center().distance_to(c)
			on = absf(d - r) < RING_BAND * 0.5 + 6.0
			if on:
				# 영역을 세라 쪽 띠 위에 작게 놓는다
				a.global_position = c + (p.center() - c).normalized() * r
				circ.radius = 7.0
		a.active = on and _alive
		if r >= float(ring.max) or not _alive:
			a.queue_free()
			rings.erase(ring)


func modify_damage(_hit: Hit) -> float:
	return 1.5 if state == S.STUNNED else 1.0


func _die(dir: int) -> void:
	for ring in rings:
		var a: EnemyAttackArea = ring.area
		a.queue_free()
	rings.clear()
	H.snd_pitch(&"bell", &"checkpoint", 0.5, 0.0)
	Fx.burst(global_position + Vector2(0, -18), 26, {
		spread = 180.0, speed_min = 20.0, speed_max = 90.0, lifetime = 1.0,
		gradient = H.white_grad(), size_min = 1.0, size_max = 3.0, gravity = Vector2(0, -50), add = true,
	})
	super(dir)
