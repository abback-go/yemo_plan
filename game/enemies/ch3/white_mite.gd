class_name WhiteMite
extends EnemyBase
## 백색 진드기 (docs/chapter3.md 4절) — 바깥 신들의 하수인. 흰 육각 껍데기 + 곧은 다리 여섯, 얼굴 대신 세로 틈.
## 생물처럼 걷지 않는다: 멈춰 있다가 직선으로 "탁" 미끄러져 옮겨 간다(유리 째깍 소리). 바깥 신들 계열이라 예고는 흰색(굵게 깜빡임).
## 정예(small = false): 체력 1800.
##   - 직선 돌진: 바닥에 굵은 흰 띠가 깜빡이며 길을 보여 줌(0.75초) → 그 띠를 따라 미끄러져 지나감.
##   - 다리 찌르기: 가까우면 앞다리를 쳐듦(0.5초) → 앞으로 내리찍음(2T).
##   - 쓰러지면 한 번 둘로 갈라진다(작은 진드기 둘, 체력 450, 다시는 갈라지지 않음).
## 작은 것(small = true): 다리 찌르기와 짧은 미끄러짐만.

enum S { IDLE, SKITTER, DASH_WINDUP, DASH, STAB_WINDUP, STAB, RECOVER, SPAWN }

const HP_BIG := 1800
const HP_SMALL := 450
const DASH_WINDUP := 0.75
const DASH_T := 13.0
const STAB_WINDUP := 0.5
const STAB_TIME := 0.16
const RECOVER_TIME := 0.6
const WHITE := Color("#f0f0ff")

@export var small := false

var state: S = S.IDLE
var _timer := 0.5
var _dur := 0.5
var _cd := 1.0
var _skit_to := 0.0
var _dash_dir := 1
var _dash_left := 0.0
var _line: AimLine
var _stab: EnemyAttackArea
var _body: EnemyAttackArea


func _build() -> void:
	max_hp = HP_SMALL if small else HP_BIG
	body_size = Vector2(16, 12) if small else Vector2(28, 20)
	knock_mult = 0.7 if small else 0.25
	launch_mult = 0.8 if small else 0.3
	is_elite = true
	kind_id = "white_mite_small" if small else "white_mite"
	display_name = "" if small else "백색 진드기"
	subtitle = "하얀 것들의 첫 발"
	_visual = MiteVisual.new()
	(_visual as MiteVisual).enemy = self
	add_child(_visual)
	var sz := 0.6 if small else 1.0
	_stab = add_attack_area(Vector2(28, 16) * sz, Vector2(18, -8) * sz, &"white_mite")
	_stab.active = false
	_body = add_attack_area(body_size - Vector2(4, 4), Vector2(0, -body_size.y * 0.5), &"white_mite")
	_body.active = false


func state_k() -> float:
	return clampf(1.0 - _timer / _dur, 0.0, 1.0) if _dur > 0.0 else 0.0


func _enter(s: S, dur := 0.0) -> void:
	state = s
	_timer = dur
	_dur = dur


func _ai(delta: float) -> void:
	var t := GameConst.TILE
	var sz := 0.6 if small else 1.0
	_place(_stab, Vector2(18, -8) * sz)
	_timer -= delta
	var p := player()
	if not engaged or p == null or not p.is_alive():
		velocity.x = 0.0
		return
	var dx := p.global_position.x - global_position.x
	var adx := absf(dx)
	match state:
		S.SPAWN:
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
			if _timer <= 0.0:
				_enter(S.IDLE, 0.3)
		S.IDLE:
			velocity.x = 0.0
			_cd -= delta
			if _timer > 0.0:
				return
			face_player()
			if _cd <= 0.0 and adx < 2.6 * t * sz + 8.0 and absf(p.global_position.y - global_position.y) < 2.0 * t:
				_enter(S.STAB_WINDUP, Difficulty.telegraph(STAB_WINDUP))
				Ch3Sfx.play(&"ch3_tick", 0.0, 0.2)
			elif _cd <= 0.0 and not small and adx < 13.0 * t and absf(p.global_position.y - global_position.y) < 1.5 * t:
				_start_dash(adx)
			else:
				# 직선으로 "탁" 옮겨 감 (세라 쪽 또는 비스듬히)
				var step := (2.5 if not small else 1.8) * t
				_skit_to = global_position.x + signf(dx) * step * (1.0 if adx > 3.0 * t else -0.6)
				_enter(S.SKITTER, 0.1)
				Ch3Sfx.play(&"ch3_tick", -6.0, 0.25)
		S.SKITTER:
			var want := (_skit_to - global_position.x) / maxf(_timer, 0.02)
			if _ledge(signi(int(signf(want)))):
				want = 0.0
			velocity.x = clampf(want, -20.0 * t, 20.0 * t)
			if _timer <= 0.0:
				velocity.x = 0.0
				_enter(S.IDLE, randf_range(0.25, 0.6) * (0.7 if small else 1.0))
		S.DASH_WINDUP:
			velocity.x = 0.0
			if _line:
				_line.k = state_k()
				if _timer < _dur * 0.35:
					_line.lock()
			if _timer <= 0.0:
				if _line:
					_line.queue_free()
					_line = null
				_enter(S.DASH, 2.0)
				_body.active = true
				_body.dodgeable = true
				Ch3Sfx.play(&"ch3_glass", -4.0, 0.15)
		S.DASH:
			velocity.x = _dash_dir * DASH_T * t
			_dash_left -= absf(velocity.x) * delta
			if Engine.get_physics_frames() % 2 == 0:
				Fx.burst(global_position + Vector2(-_dash_dir * 10, -6), 1, {direction = Vector2(-_dash_dir, 0), spread = 10.0, speed_min = 10.0,
					speed_max = 30.0, lifetime = 0.3, gradient = Palette.fade_gradient(WHITE), size_min = 1.0, size_max = 2.0, gravity = Vector2.ZERO})
			if _dash_left <= 0.0 or is_on_wall() or _ledge(_dash_dir) or _timer <= 0.0:
				velocity.x = 0.0
				_body.active = false
				_enter(S.RECOVER, RECOVER_TIME)
		S.STAB_WINDUP:
			velocity.x = 0.0
			if _timer <= 0.0:
				_enter(S.STAB, STAB_TIME)
				_stab.active = true
				_stab.dodgeable = true
				Ch3Sfx.play(&"ch3_glass", -6.0, 0.2)
				Fx.shake(0.06, 0.1)
		S.STAB:
			if _timer <= 0.0:
				_stab.active = false
				_enter(S.RECOVER, RECOVER_TIME * (0.7 if small else 1.0))
		S.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			if _timer <= 0.0:
				_enter(S.IDLE, 0.2)
				_cd = Difficulty.rest(randf_range(0.8, 1.3) * (0.8 if small else 1.0))


func _start_dash(adx: float) -> void:
	_dash_dir = facing
	_dash_left = minf(adx + 3.5 * GameConst.TILE, 14.0 * GameConst.TILE) # 세라 자리를 지나 3.5T 더
	_enter(S.DASH_WINDUP, Difficulty.telegraph(DASH_WINDUP))
	_line = AimLine.new()
	_line.white = true
	_line.band = 14.0
	_line.max_len = _dash_left
	Fx.effect_parent().add_child(_line)
	_line.aim(global_position + Vector2(0, -8), Vector2(_dash_dir, 0))
	Ch3Sfx.play(&"ch3_glass_low", -6.0, 0.1)


func _ledge(dir: int) -> bool:
	if dir == 0:
		return false
	var space := get_world_2d().direct_space_state
	var from := global_position + Vector2(dir * body_size.x * 0.6, -4)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 20), GameConst.L_WORLD | GameConst.L_PLATFORM)
	return space.intersect_ray(q).is_empty()


func _place(a: EnemyAttackArea, off: Vector2) -> void:
	var cs := a.get_child(0) as CollisionShape2D
	if cs:
		cs.position = Vector2(off.x * facing, off.y)


func _resists_knockback(_hit: Hit) -> bool:
	return state == S.DASH


func _exit_tree() -> void:
	if _line and is_instance_valid(_line):
		_line.queue_free()


func _die(dir: int) -> void:
	if _line and is_instance_valid(_line):
		_line.queue_free()
		_line = null
	Ch3Sfx.play(&"ch3_crystal_break", 0.0, 0.1)
	Fx.burst(global_position + Vector2(0, -8), 20, {spread = 180.0, speed_min = 40.0, speed_max = 140.0, lifetime = 0.6,
		gradient = Palette.fade_gradient(WHITE), size_min = 1.5, size_max = 3.0, gravity = Vector2(0, 200)})
	if not small:
		_split.call_deferred() # 물리 신호 처리 중에 새 판정 영역을 만들지 않게
	super(dir)


## 정예가 쓰러지면 작은 진드기 둘로 갈라진다
func _split() -> void:
	var w := World.get_world()
	if w == null or w.room == null:
		return
	for i in 2:
		var m := WhiteMite.new()
		m.small = true
		m.position = position + Vector2((-1 if i == 0 else 1) * 10.0, -4)
		m.uid = uid + ("_a" if i == 0 else "_b")
		m.respawns = true
		m.facing = -1 if i == 0 else 1
		w.room.add_entity(m)
		w.room.enemies.append(m)
		m.velocity = Vector2((-1 if i == 0 else 1) * 120.0, -180.0)
		m._enter(S.SPAWN, 0.5)
	Fx.ring(global_position + Vector2(0, -8), 4.0, 34.0, WHITE, 0.3, 2.0)


## 백색 진드기 그림: 흰 육각 껍데기(금이 직선으로 나 있음), 곧은 다리 여섯(꺾인 마디), 앞면의 세로 틈(얼굴 없음)
class MiteVisual extends Node2D:
	const SHELL := Color("#e8e8f2")
	const SHELL_SH := Color("#a8a8b8")
	const LEG := Color("#c8c8d6")
	const CORE := Color("#ffffff")
	var enemy: WhiteMite

	func _process(_d: float) -> void:
		if enemy == null:
			return
		scale.x = enemy.facing
		z_index = 1

	func _draw() -> void:
		if enemy == null:
			return
		var t := enemy._t
		var s := 0.6 if enemy.small else 1.0
		var st := enemy.state
		var k := enemy.state_k()
		var wh := enemy.flash_amount() > 0.0
		var lift := 0.0
		var rear := 0.0
		match st:
			WhiteMite.S.STAB_WINDUP:
				rear = k
			WhiteMite.S.STAB:
				rear = -0.5
			WhiteMite.S.DASH_WINDUP:
				lift = -2.0 * k
			WhiteMite.S.SKITTER:
				lift = 1.0
		var c := Vector2(0, (-10.0 + lift) * s)
		# 다리 여섯 (곧은 마디, 끝이 뾰족) — 걷는 대신 미세하게 떨림
		for i in 3:
			for side in [-1.0, 1.0]:
				var hip := c + Vector2((-6 + i * 6) * s, 3 * s)
				var jit := sin(t * 23.0 + i * 2.0 + side) * 0.4 if st == WhiteMite.S.IDLE else 0.0
				var knee := hip + Vector2(((-3 + i * 3) + side * 2.0) * s, -5 * s + jit)
				var foot := Vector2(hip.x + ((-5 + i * 5) + side * 1.5) * s, 0)
				if i == 2 and rear > 0.0:
					knee = hip + Vector2(6 * s, -9 * s * rear)
					foot = hip + Vector2(12 * s, -6 * s * rear)
				elif i == 2 and rear < 0.0:
					foot = hip + Vector2(14 * s, 8 * s)
					knee = hip + Vector2(8 * s, -3 * s)
				var lc := LEG.darkened(0.25) if side < 0.0 else LEG
				if wh:
					lc = Color.WHITE
				draw_line(hip, knee, lc, 1.5)
				draw_line(knee, foot, lc, 1.0)
		# 껍데기 (육각형 두 겹)
		var hex := PackedVector2Array()
		for i in 6:
			var a := TAU * i / 6.0
			hex.append(c + Vector2(cos(a) * 11.0 * s, sin(a) * 7.0 * s))
		draw_colored_polygon(hex, SHELL_SH if not wh else Color.WHITE)
		var hex2 := PackedVector2Array()
		for i in 6:
			var a2 := TAU * i / 6.0
			hex2.append(c + Vector2(cos(a2) * 9.0 * s, sin(a2) * 5.5 * s - 1.0))
		draw_colored_polygon(hex2, SHELL if not wh else Color.WHITE)
		# 직선 금 (기하학)
		draw_line(c + Vector2(-6 * s, -3 * s), c + Vector2(-1 * s, 1 * s), SHELL_SH, 1.0)
		draw_line(c + Vector2(-1 * s, 1 * s), c + Vector2(4 * s, -2 * s), SHELL_SH, 1.0)
		draw_line(c + Vector2(4 * s, -2 * s), c + Vector2(6 * s, 2 * s), SHELL_SH, 1.0)
		# 앞면의 세로 틈 (얼굴 없음 — 안에서 흰빛)
		var slit := c + Vector2(9 * s, -1 * s)
		var g := 0.6 + 0.4 * sin(t * 3.0)
		draw_line(slit + Vector2(0, -3 * s), slit + Vector2(0, 3 * s), Color("#4a4a58"), 2.0)
		draw_line(slit + Vector2(0, -2 * s), slit + Vector2(0, 2 * s), Color(CORE, g), 1.0)
		if st == WhiteMite.S.DASH_WINDUP or st == WhiteMite.S.STAB_WINDUP:
			var bl := 0.5 + 0.5 * sin(t * 30.0)
			draw_circle(slit, 5.0 * s, Color(1, 1, 1, 0.3 * k * bl))
		# 등의 작은 수정 가시
		for i in 3:
			var b := c + Vector2((-5 + i * 5) * s, -5 * s)
			draw_colored_polygon(PackedVector2Array([b + Vector2(-1.5 * s, 0), b + Vector2(0, -4 * s), b + Vector2(1.5 * s, 0)]), CORE)
