class_name TrainingGolem
extends EnemyBase
## 훈련 골렘 (docs/chapter1.md 7절·12.5절): 실습장의 낡은 나무·돌 허수아비가 지하에서 새어 나온 마력에 폭주했다.
## 느린 걸음 → 2연타 주먹(주먹을 뒤로 당기며 붉게 빛남) / 내려찍기(0.8초 예고) → 바닥 충격파가 양쪽으로 → 등의 핵이 2초간 노출.
## 정면(과녁이 그려진 가슴)은 단단해서 여우불이 아니면 피해 15%, 등의 핵은 2배. 9T 넘게 떨어져 3초 버티면 세라를 따라가는 충격파.
## 화염 폭풍은 열기가 틈으로 스며들어 정면에서도 그대로 들어가고, 돌진 끊기 공격(breaks_charge)에 잠깐 휘청인다
## (엠버린이 전투 도중 화염 폭풍을 가르치는 대본 전투. 대본이 잡아 두려면 engaged = false).

enum S { IDLE, WALK, TURN, PUNCH_WINDUP, PUNCH, PUNCH2_WINDUP, PUNCH2, PUNCH_RECOVER, SLAM_WINDUP, SLAM, CORE_OPEN, STOMP_WINDUP, STOMP, RECOVER, STAGGER }

const HP := 1400
const WALK_SPEED_T := 1.6
const TURN_DELAY := 0.5 ## 세라가 등 뒤에 이만큼 머물면 돌아서기 시작
const TURN_TIME := 0.4 ## 돌아서는 데 걸리는 시간 (이 사이가 등을 노릴 틈)
const PUNCH_RANGE_T := 3.4 ## 중심에서 세라까지 수평 거리가 이 안이면 주먹
const MID_RANGE_T := 7.5 ## 이 안의 중거리에 오래 있으면 내려찍기 (충격파가 닿는 거리)
const PUNCH_WINDUP := 0.55
const PUNCH2_WINDUP := 0.32
const PUNCH_ACTIVE := 0.14
const PUNCH_RECOVER := 0.75
const SLAM_WINDUP := 0.8
const SLAM_ACTIVE := 0.12
const CORE_OPEN_TIME := 2.0
const STOMP_WINDUP := 0.6
const PURSUIT_DIST_T := 9.0
const PURSUIT_TIME := 3.0
const FRONT_MULT := 0.15 ## 정면(여우불·화염 폭풍 제외)
const CORE_MULT := 2.0 ## 등의 핵
const NEUTRAL_MULT := 0.6 ## 발밑(불기둥)·정중앙
const STAGGER_TIME := 0.45
const STAGGER_COOLDOWN := 2.5
const WAVE_SPEED_T := 13.0
const WAVE_RANGE_T := 14.0
const FIST_OFFSET := Vector2(32, -28)
const SLAM_OFFSET := Vector2(30, -14)
const MANA := Color("#b77bff") ## 폭주 마력
const MANA_DEEP := Color("#5b2d8e")

var state: S = S.WALK
var core_glow := 0.0 ## 등 핵의 빛 (0~1) — 그림이 읽는다
var _timer := 0.0
var _state_time := 0.0 ## 현재 상태의 전체 길이 (그림의 진행도 계산용)
var _behind_t := 0.0
var _far_t := 0.0
var _mid_t := 0.0
var _attack_cd := 1.2
var _attack_count := 0
var _stagger_cd := 0.0
var _clank_cd := 0.0
var _wisp_t := 0.0
var _contact: EnemyAttackArea
var _fist: EnemyAttackArea
var _slam: EnemyAttackArea


func _build() -> void:
	max_hp = HP
	body_size = Vector2(36, 60)
	display_name = "훈련 골렘"
	subtitle = "실습장의 오래된 상대"
	kind_id = "golem"
	knock_mult = 0.12
	launch_mult = 0.0
	var v := GolemVisual.new()
	v.enemy = self
	_visual = v
	add_child(v)
	_contact = add_attack_area(Vector2(28, 50), Vector2(0, -27), &"golem")
	_contact.dodgeable = false # 걷는 몸에 스친 건 회피가 아니다
	_fist = add_attack_area(Vector2(28, 24), FIST_OFFSET, &"golem")
	_fist.active = false
	_slam = add_attack_area(Vector2(46, 28), SLAM_OFFSET, &"golem")
	_slam.active = false


## 상태 진행도 0→1 (예고 연출용)
func progress() -> float:
	if _state_time <= 0.0:
		return 1.0
	return clampf(1.0 - _timer / _state_time, 0.0, 1.0)


func _set_state(s: S, time := 0.0) -> void:
	state = s
	_timer = time
	_state_time = time


func _ai(delta: float) -> void:
	var t := GameConst.TILE
	_stagger_cd = maxf(_stagger_cd - delta, 0.0)
	_clank_cd = maxf(_clank_cd - delta, 0.0)
	_place_area(_fist, FIST_OFFSET)
	_place_area(_slam, SLAM_OFFSET)
	core_glow = move_toward(core_glow, 1.0 if state == S.CORE_OPEN else 0.0, delta * (5.0 if state == S.CORE_OPEN else 1.5))
	_leak_mana(delta)

	var p := player()
	if not engaged or p == null or not p.is_alive():
		# 대본 대기 중이거나 세라가 없으면 제자리에 선다
		_set_state(S.IDLE)
		_fist.active = false
		_slam.active = false
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		return
	if state == S.IDLE:
		_set_state(S.WALK)
		_attack_cd = 0.8

	var dx := p.global_position.x - global_position.x
	var dy := p.global_position.y - global_position.y
	var adx := absf(dx)
	_timer -= delta
	match state:
		S.WALK:
			_walk(delta, dx, dy, adx)
		S.TURN:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if _timer <= 0.0:
				facing = -facing
				_behind_t = 0.0
				_set_state(S.WALK)
				Sfx.play(&"land", -4.0, 0.1)
				_dust(global_position + Vector2(0, -2), 6)
		S.PUNCH_WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _timer <= 0.0:
				_set_state(S.PUNCH, PUNCH_ACTIVE)
				_fist.active = true
				_fist.dodgeable = true
				Sfx.play(&"swing", -2.0, 0.1)
		S.PUNCH:
			velocity.x = facing * 5.0 * t
			if _timer <= 0.0:
				_fist.active = false
				_set_state(S.PUNCH2_WINDUP, PUNCH2_WINDUP)
				Sfx.play(&"growl", -8.0, 0.1)
		S.PUNCH2_WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _timer <= 0.0:
				_set_state(S.PUNCH2, PUNCH_ACTIVE + 0.02)
				_fist.active = true
				_fist.dodgeable = true
				Sfx.play(&"swing", 0.0, 0.1)
		S.PUNCH2:
			velocity.x = facing * 8.0 * t
			if _timer <= 0.0:
				_fist.active = false
				_set_state(S.PUNCH_RECOVER, PUNCH_RECOVER)
				Fx.shake(0.08, 0.12)
				_dust(global_position + Vector2(facing * 30, -2), 5)
		S.SLAM_WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _timer <= 0.0:
				_do_slam()
		S.SLAM:
			velocity.x = 0.0
			if _timer <= 0.0:
				_slam.active = false
				_set_state(S.CORE_OPEN, CORE_OPEN_TIME)
				Sfx.play(&"overheat", -2.0, 0.0)
		S.CORE_OPEN:
			velocity.x = 0.0
			if fmod(_timer, 0.2) < delta:
				# 등의 핵에서 김과 불티가 뿜어져 나온다
				Fx.burst(core_pos(), 3, {
					direction = Vector2(-facing, -1), spread = 30.0, speed_min = 20.0, speed_max = 60.0, lifetime = 0.6,
					gradient = Palette.fade_gradient(Color(0.95, 0.85, 1.0, 0.8)), size_min = 1.5, size_max = 3.0,
					gravity = Vector2(0, -60), add = true,
				})
			if _timer <= 0.0:
				_set_state(S.RECOVER, 0.45)
				Sfx.play(&"land", -2.0, 0.1)
		S.STOMP_WINDUP:
			velocity.x = 0.0
			if _timer <= 0.0:
				_do_stomp(dx)
		S.STOMP, S.PUNCH_RECOVER, S.RECOVER, S.STAGGER:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if _timer <= 0.0:
				_attack_cd = 0.5 if state == S.STAGGER else 0.7
				_set_state(S.WALK)


func _walk(delta: float, dx: float, dy: float, adx: float) -> void:
	var t := GameConst.TILE
	_attack_cd -= delta
	var ahead := signf(dx) == float(facing)
	# 세라가 등 뒤에 있으면 잠시 뒤 묵직하게 돌아선다 (그 사이가 핵을 노릴 틈)
	if not ahead and adx > 6.0:
		_behind_t += delta
		if _behind_t >= TURN_DELAY:
			_set_state(S.TURN, TURN_TIME)
			velocity.x = 0.0
			return
	else:
		_behind_t = 0.0
	# 멀리서 버티면 바닥을 따라가는 충격파
	if adx > PURSUIT_DIST_T * t:
		_far_t += delta
	else:
		_far_t = maxf(_far_t - delta * 2.0, 0.0)
	if _far_t >= PURSUIT_TIME and _attack_cd <= 0.0:
		_far_t = 0.0
		facing = 1 if dx >= 0.0 else -1
		_set_state(S.STOMP_WINDUP, STOMP_WINDUP)
		Sfx.play(&"charger_windup", -2.0, 0.0)
		return
	if ahead and adx > PUNCH_RANGE_T * t and adx <= MID_RANGE_T * t:
		_mid_t += delta
	else:
		_mid_t = 0.0
	var want := 0.0
	if ahead and adx > PUNCH_RANGE_T * t * 0.8 and not _ledge_ahead():
		want = facing * WALK_SPEED_T * t
	velocity.x = move_toward(velocity.x, want, 300.0 * delta)
	if _attack_cd > 0.0 or not ahead or absf(dy) > 4.0 * t:
		return
	if adx <= PUNCH_RANGE_T * t:
		_attack_count += 1
		if _attack_count % 3 == 0:
			_start_slam()
		else:
			_set_state(S.PUNCH_WINDUP, PUNCH_WINDUP)
			Sfx.play(&"growl", -4.0, 0.1)
	elif _mid_t > 1.2:
		_mid_t = 0.0
		_start_slam()


func _start_slam() -> void:
	_set_state(S.SLAM_WINDUP, SLAM_WINDUP)
	Sfx.play(&"charger_windup", 0.0, 0.0)
	Sfx.play(&"growl", -4.0, 0.0)


func _do_slam() -> void:
	_set_state(S.SLAM, SLAM_ACTIVE)
	_slam.active = true
	_slam.dodgeable = true
	Sfx.play(&"slam", 2.0, 0.05)
	Sfx.play(&"crumble", -4.0)
	Fx.shake(0.35, 0.3)
	Fx.zoom_punch(0.03)
	var at := global_position + Vector2(facing * 30, 0)
	_dust(at + Vector2(0, -2), 14)
	Fx.ring(at + Vector2(0, -4), 4.0, 34.0, Color(1.0, 0.5, 0.45), 0.25, 2.0)
	# 양쪽으로 퍼지는 바닥 충격파 (뒤로 가는 것은 등 쪽에서 출발)
	_spawn_wave(at, facing, false)
	_spawn_wave(global_position + Vector2(-facing * 20, 0), -facing, false)


func _do_stomp(dx: float) -> void:
	_set_state(S.STOMP, 0.4)
	var dir := 1 if dx >= 0.0 else -1
	Sfx.play(&"slam", 0.0, 0.05)
	Sfx.play(&"crumble", -6.0)
	Fx.shake(0.22, 0.25)
	_dust(global_position + Vector2(facing * 8, -2), 10)
	_spawn_wave(global_position + Vector2(dir * 22, 0), dir, true)
	_attack_cd = 1.0


func _spawn_wave(pos: Vector2, dir: int, follow: bool) -> void:
	var w := Shockwave.new()
	w.global_position = pos
	w.max_speed = WAVE_SPEED_T * GameConst.TILE * (0.8 if follow else 1.0)
	w.speed = dir * w.max_speed * (0.6 if follow else 1.0)
	w.follow = follow
	w.life = 3.0 if follow else WAVE_RANGE_T / WAVE_SPEED_T
	Fx.effect_parent().add_child(w)


## 공격 판정 위치를 바라보는 쪽에 맞춘다
func _place_area(a: EnemyAttackArea, offset: Vector2) -> void:
	var cs := a.get_child(0) as CollisionShape2D
	if cs:
		cs.position = Vector2(offset.x * facing, offset.y)


func _ledge_ahead() -> bool:
	var space := get_world_2d().direct_space_state
	var from := global_position + Vector2(facing * 22, -4)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 16), GameConst.L_WORLD | GameConst.L_PLATFORM)
	return space.intersect_ray(q).is_empty()


## 등 핵의 전역 위치
func core_pos() -> Vector2:
	return global_position + Vector2(-facing * 21, -35)


## 맞은 방향: 1 = 정면(과녁), -1 = 등(핵), 0 = 발밑·정중앙
func _hit_side(hit: Hit) -> int:
	if hit.kind == &"pillar" or hit.kind == &"fox_pillar" or hit.kind == &"fox_rain":
		return 0
	var from := 0.0
	if hit.direction != 0:
		from = -float(hit.direction)
	else:
		var dxs := hit.source_pos.x - global_position.x
		if absf(dxs) < 10.0:
			return 0
		from = signf(dxs)
	return 1 if from == float(facing) else -1


func modify_damage(hit: Hit) -> float:
	var side := _hit_side(hit)
	if side < 0:
		return CORE_MULT
	if is_fox_hit(hit) or hit.kind == &"storm" or hit.kind == &"storm_final":
		return 1.0
	return FRONT_MULT if side > 0 else NEUTRAL_MULT


func _resists_knockback(hit: Hit) -> bool:
	return state != S.WALK and state != S.STAGGER and state != S.IDLE and not hit.breaks_charge


func _on_hit(hit: Hit, _dir: int) -> void:
	var side := _hit_side(hit)
	if side < 0:
		# 핵 명중: 보랏빛 불티가 튄다
		Fx.burst(core_pos(), 10, {
			direction = Vector2(-facing, -0.4), spread = 70.0, speed_min = 50.0, speed_max = 150.0, lifetime = 0.35,
			gradient = Palette.fade_gradient(MANA.lightened(0.4)), size_min = 1.0, size_max = 2.5, add = true,
		})
		Fx.ring(core_pos(), 2.0, 12.0 + 6.0 * core_glow, MANA.lightened(0.3), 0.18, 1.0)
	elif side > 0 and modify_damage(hit) < 1.0 and _clank_cd <= 0.0:
		# 정면 장갑에 튕김: 작은 회색 불티 + 둔한 "팅"
		_clank_cd = 0.15
		var at := global_position + Vector2(facing * 18, -34 + randf_range(-6, 6))
		Fx.burst(at, 5, {
			direction = Vector2(facing, -0.5), spread = 50.0, speed_min = 40.0, speed_max = 110.0, lifetime = 0.2,
			gradient = Palette.fade_gradient(Color(0.85, 0.85, 0.9)), size_min = 1.0, size_max = 1.5, gravity = Vector2(0, 300),
		})
		Sfx.play(&"block", -11.0, 0.15)
	# 돌진 끊기 공격(화염 폭풍 등): 예고 중이면 끊기고 잠깐 휘청 (연속으로는 안 됨)
	if hit.breaks_charge and _stagger_cd <= 0.0 and state in [S.WALK, S.TURN, S.PUNCH_WINDUP, S.PUNCH2_WINDUP, S.SLAM_WINDUP, S.STOMP_WINDUP, S.PUNCH_RECOVER, S.RECOVER]:
		_stagger_cd = STAGGER_COOLDOWN
		_fist.active = false
		_slam.active = false
		_set_state(S.STAGGER, STAGGER_TIME)
		Sfx.play(&"growl", -2.0, 0.2)


## 폭주 마력이 몸 이음새에서 새어 나온다
func _leak_mana(delta: float) -> void:
	_wisp_t -= delta
	if _wisp_t > 0.0:
		return
	_wisp_t = 0.14
	var spots := [Vector2(-10, -50), Vector2(12, -48), Vector2(0, -16), Vector2(-16, -36)]
	var s: Vector2 = spots[randi() % spots.size()]
	Fx.burst(global_position + Vector2(s.x * facing, s.y), 1, {
		direction = Vector2.UP, spread = 25.0, speed_min = 8.0, speed_max = 22.0, lifetime = 0.9,
		gradient = Palette.fade_gradient(MANA), size_min = 1.5, size_max = 2.5, gravity = Vector2(0, -20), add = true,
	})


func _dust(pos: Vector2, amount: int) -> void:
	Fx.burst(pos, amount, {
		direction = Vector2.UP, spread = 80.0, speed_min = 30.0, speed_max = 110.0, lifetime = 0.45,
		gradient = Palette.fade_gradient(Color("#8a7a68")), size_min = 1.5, size_max = 3.0, gravity = Vector2(0, 200),
	})


## 바닥을 타고 퍼지는 충격파 (점프로 넘는다). follow면 세라 쪽으로 방향을 틀며 따라간다.
class Shockwave extends EnemyAttackArea:
	const FOLLOW_ACCEL := 260.0 ## 따라가는 충격파가 방향을 트는 가속 (px/s²)

	var speed := 200.0 ## 부호 있는 수평 속도 (px/s)
	var max_speed := 200.0
	var follow := false
	var life := 1.0
	var _t := 0.0
	var _dust_t := 0.0
	var _dead := false

	func _ready() -> void:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(14, 15)
		shape.shape = rect
		shape.position = Vector2(0, -7.5)
		add_child(shape)
		cause = &"golem"
		dodgeable = true
		z_index = 3

	func _physics_process(delta: float) -> void:
		if _dead:
			return
		var d := delta * Fx.enemy_time
		_t += d
		life -= d
		if follow:
			var p := get_tree().get_first_node_in_group(GameConst.GROUP_PLAYER) as Node2D
			if p:
				var want := signf(p.global_position.x - global_position.x) * max_speed
				speed = move_toward(speed, want, FOLLOW_ACCEL * d)
		var step := speed * d
		var space := get_world_2d().direct_space_state
		var from := global_position + Vector2(0, -6)
		var wall := PhysicsRayQueryParameters2D.create(from, from + Vector2(signf(step) * (absf(step) + 6.0), 0), GameConst.L_WORLD)
		if not space.intersect_ray(wall).is_empty():
			_fade()
			return
		global_position.x += step
		# 바닥을 따라간다 (낭떠러지면 사라짐)
		var down := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -12), global_position + Vector2(0, 20),
			GameConst.L_WORLD | GameConst.L_PLATFORM)
		var r := space.intersect_ray(down)
		if r.is_empty():
			_fade()
			return
		var floor_pos: Vector2 = r.position
		global_position.y = floor_pos.y
		_dust_t -= d
		if _dust_t <= 0.0:
			_dust_t = 0.05
			Fx.burst(global_position + Vector2(0, -2), 2, {
				direction = Vector2(-signf(speed), -1.0), spread = 40.0, speed_min = 30.0, speed_max = 80.0, lifetime = 0.35,
				gradient = Palette.fade_gradient(Color("#8a7a68")), size_min = 1.0, size_max = 2.5, gravity = Vector2(0, 260),
			})
		if life <= 0.0:
			_fade()
		queue_redraw()

	func _fade() -> void:
		_dead = true
		active = false
		set_deferred("monitorable", false)
		Fx.burst(global_position + Vector2(0, -4), 6, {
			direction = Vector2.UP, spread = 70.0, speed_min = 20.0, speed_max = 70.0, lifetime = 0.3,
			gradient = Palette.fade_gradient(Color("#8a7a68")), size_min = 1.0, size_max = 2.0,
		})
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.12)
		tw.tween_callback(queue_free)

	func _draw() -> void:
		var dirx := signf(speed) if speed != 0.0 else 1.0
		var flick := sin(_t * 50.0)
		# 붉게 달아오른 마력 물마루 (위험 표시)
		draw_rect(Rect2(-12, -8, 24, 8), Color(1.0, 0.25, 0.2, 0.18 + 0.08 * flick))
		draw_rect(Rect2(-11, -3, 22, 3), Color(1.0, 0.3, 0.25, 0.6))
		# 솟구치는 돌 조각 (앞쪽이 가장 높다)
		for i in 5:
			var x := (4.0 - i * 4.0) * dirx
			var h := 17.0 - i * 3.0 + flick * (1.5 if i % 2 == 0 else -1.5)
			draw_rect(Rect2(x - 2.5, -h - 1.0, 5.0, h + 1.0), Palette.OUTLINE)
			draw_rect(Rect2(x - 1.5, -h, 3.0, h), Color("#8d8498") if i % 2 == 0 else Color("#686076"))
			draw_rect(Rect2(x - 1.5, -h, 3.0, 2.0), Color("#ff6a5a"))
		# 보랏빛 폭주 마력 띠
		draw_line(Vector2(-12, -1), Vector2(12, -1), Color(TrainingGolem.MANA, 0.9), 1.0)
