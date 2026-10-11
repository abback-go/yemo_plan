class_name RunawayBroom
extends EnemyBase
## 폭주 빗자루 (docs/archive/sera/chapter1.md 7절·12.5절·12.6절): 청소 도구함의 빗자루가 지하에서 새어 나온 마력에 폭주했다.
## 갈팡질팡 날다가 → 솔이 곤두서며 휘파람(0.6초 예고, 마지막 0.18초는 조준 고정) → 세라가 있던 곳으로 직선 급강하(22 T/s).
## 빗나가 벽에 박히면 1.5초 버둥: 피해 1.5배, 그리고 손잡이를 밟고 설 수 있다(통과 발판 — 시계탑 오르기 퍼즐).
## 바닥·천장에 부딪히면 잠깐 어질어질. 급강하 중엔 뒤로 먼지 꼬리가 남는다. 아픈 건 급강하뿐(대시로 스치면 퍼펙트 회피).

enum S { FLIT, WINDUP, SWOOP, STUCK, BONK, RECOVER }

const HP := 160
const FLIT_SPEED_T := 7.0
const FLIT_TIME_MIN := 1.4 ## 갈팡질팡 나는 시간 (이후 시야가 트이면 예고)
const FLIT_TIME_MAX := 2.4
const WINDUP_TIME := 0.6
const LOCK_TIME := 0.18 ## 예고 마지막 이만큼은 조준이 고정된다 (피할 틈)
const SWOOP_SPEED_T := 22.0
const SWOOP_RANGE_T := 16.0
const MAX_DIVE := 0.9 ## 급강하 각도 한계 (라디안, 수평 기준 약 52°)
const STUCK_TIME := 1.5
const STUCK_MULT := 1.5
const DETECT_T := 13.0
const LAUNCH := 0.5
const LEVEL_OUT := 7.0 ## 노린 자리를 지난 뒤 수평으로 펴는 회전 속도 (rad/s)
const KEEP_AWAY_T := 3.5 ## 갈팡질팡 날 때 세라와 이만큼은 떨어진다
const MANA := Color("#b77bff") ## 폭주 마력
const DUST := Color("#a89a84")

var state: S = S.FLIT
var aim := Vector2.RIGHT ## 급강하 방향 (그림도 이 방향을 본다)
var _timer := 0.0
var _state_time := 0.0
var _home := Vector2.ZERO
var _flit_target := Vector2.ZERO
var _retarget := 0.0
var _side := 1.0
var _swoop_from := Vector2.ZERO
var _swoop_target := Vector2.ZERO
var _swoop_frames := 0
var _locked := false
var _dust_t := 0.0
var _wisp_t := 0.0
var _contact: EnemyAttackArea
var _platform: StaticBody2D
var _platform_shape: CollisionShape2D


func _build() -> void:
	max_hp = HP
	body_size = Vector2(30, 12)
	flying = true
	knock_mult = 0.7
	launch_mult = LAUNCH
	display_name = "폭주 빗자루"
	subtitle = "청소 당번의 원한"
	kind_id = "broom"
	var v := BroomVisual.new()
	v.enemy = self
	_visual = v
	add_child(v)
	_contact = add_attack_area(Vector2(30, 10), Vector2(0, -6), &"broom")
	_contact.dodgeable = true # 급강하 중에만 켜진다 → 대시로 스치면 퍼펙트 회피
	_contact.active = false
	# 벽에 박혔을 때만 켜지는 손잡이 발판 (위에서만 밟히는 통과 발판)
	_platform = StaticBody2D.new()
	_platform.name = "HandlePlatform"
	_platform.collision_layer = GameConst.L_PLATFORM
	_platform.collision_mask = 0
	_platform_shape = CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(34, 4)
	_platform_shape.shape = rs
	_platform_shape.one_way_collision = true
	_platform_shape.position = Vector2(0, -6)
	_platform_shape.disabled = true
	_platform.add_child(_platform_shape)
	add_child(_platform)


func _ready() -> void:
	super()
	collision_mask = GameConst.L_WORLD # 나는 적이라 통과 발판에는 걸리지 않는다
	_home = global_position
	add_collision_exception_with(_platform)
	_side = -1.0 if randf() < 0.5 else 1.0
	_set_state(S.FLIT, randf_range(FLIT_TIME_MIN, FLIT_TIME_MAX))


## 몸 가운데 (손잡이 높이)
func center() -> Vector2:
	return global_position + Vector2(0, -6)


## 상태 진행도 0→1 (예고 연출용)
func progress() -> float:
	if _state_time <= 0.0:
		return 1.0
	return clampf(1.0 - _timer / _state_time, 0.0, 1.0)


func is_locked() -> bool:
	return state == S.WINDUP and _timer <= LOCK_TIME


func is_stuck() -> bool:
	return state == S.STUCK


func _set_state(s: S, time := 0.0) -> void:
	state = s
	_timer = time
	_state_time = time


func _ai(delta: float) -> void:
	var t := GameConst.TILE
	_timer -= delta
	_leak_mana(delta)
	var p := player()
	if p != null and (not p.is_alive() or not engaged):
		p = null # 대본이 잡아 두면(engaged = false) 제자리 근처만 맴돈다
	match state:
		S.FLIT:
			_flit(delta, p)
		S.WINDUP:
			velocity = velocity.move_toward(Vector2.ZERO, 1400.0 * delta)
			if _timer > LOCK_TIME:
				if p:
					aim = _aim_at(p.center())
					_swoop_target = p.center()
					facing = 1 if aim.x >= 0.0 else -1
			elif not _locked:
				_locked = true
				Sfx.play_pitch(&"sniper_aim", 2.3, -1.0) # 휘파람 끝음 "익!"
				if p:
					_swoop_target = p.center()
			if _timer <= 0.0:
				_start_swoop()
		S.SWOOP:
			_swoop_frames += 1
			# 노린 자리를 지나치면 수평으로 몸을 편다 (그래서 바닥보다 벽에 잘 박힌다)
			if (center() - _swoop_target).dot(aim) > 0.0 and absf(aim.y) > 0.01:
				var level := Vector2(signf(aim.x), 0.0)
				aim = Vector2.from_angle(rotate_toward(aim.angle(), level.angle(), LEVEL_OUT * delta))
			velocity = aim * SWOOP_SPEED_T * t
			_trail(delta)
			if _swoop_frames > 1 and is_on_wall():
				_stick()
			elif _swoop_frames > 1 and (is_on_floor() or is_on_ceiling()):
				_bonk(true)
			elif global_position.distance_to(_swoop_from) >= SWOOP_RANGE_T * t:
				_set_state(S.RECOVER, 0.5)
		S.STUCK:
			velocity = Vector2.ZERO
			if fmod(_timer, 0.25) < delta:
				# 버둥거리며 솔에서 먼지가 날린다
				Fx.burst(center() - aim * 18.0, 3, {
					direction = Vector2(-aim.x, -0.6), spread = 70.0, speed_min = 20.0, speed_max = 60.0, lifetime = 0.4,
					gradient = Palette.fade_gradient(DUST), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 120),
				})
			if _timer <= 0.0:
				_unstick()
		S.BONK:
			velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
			if _timer <= 0.0:
				_set_state(S.FLIT, randf_range(0.9, 1.5))
		S.RECOVER:
			velocity = velocity.move_toward(Vector2.ZERO, 700.0 * delta)
			if _timer <= 0.0:
				_set_state(S.FLIT, randf_range(FLIT_TIME_MIN, FLIT_TIME_MAX))
	# 아픈 건 급강하뿐: 떠다니는 몸이나 박힌 손잡이(밟고 서는 발판)는 닿아도 아프지 않다
	_contact.active = state == S.SWOOP


func _flit(delta: float, p: Player) -> void:
	var t := GameConst.TILE
	_retarget -= delta
	if _retarget <= 0.0:
		_retarget = randf_range(0.3, 0.65)
		if p:
			# 세라 옆 비스듬히 위쪽을 맴돌다가 가끔 반대편으로 건너간다 (벽 속이면 반대편)
			if randf() < 0.25:
				_side = -_side
			_flit_target = p.center() + Vector2(_side * randf_range(4.0, 7.0), -randf_range(1.0, 3.0)) * t
			if _blocked(p.center(), _flit_target):
				_side = -_side
				_flit_target.x = p.center().x + (_flit_target.x - p.center().x) * -1.0
		else:
			_flit_target = _home + Vector2(randf_range(-3.0, 3.0), randf_range(-2.0, 1.0)) * t
	var to := _flit_target - global_position
	var desired := to.normalized() * minf(FLIT_SPEED_T * t, to.length() * 4.0)
	desired += Vector2(sin(_t * 9.0) * 40.0, cos(_t * 13.0) * 55.0) # 갈팡질팡
	if p:
		# 몸통 박치기로 아프게 하는 적이 아니다: 너무 붙으면 비켜난다
		var away := center() - p.center()
		if away.length() < KEEP_AWAY_T * t:
			desired += away.normalized() * FLIT_SPEED_T * t
	velocity = velocity.move_toward(desired, 1100.0 * delta)
	if absf(velocity.x) > 30.0:
		facing = 1 if velocity.x > 0.0 else -1
	if p and _timer <= 0.0 and center().distance_to(p.center()) <= DETECT_T * t and _has_los(p):
		_set_state(S.WINDUP, WINDUP_TIME)
		_locked = false
		aim = _aim_at(p.center())
		_swoop_target = p.center()
		facing = 1 if aim.x >= 0.0 else -1
		Sfx.play_pitch(&"sniper_aim", 1.5, -1.0) # 휘파람 "휘이—"
		Sfx.play(&"whoosh", -10.0, 0.1)


func _start_swoop() -> void:
	_set_state(S.SWOOP)
	_swoop_from = global_position
	_swoop_frames = 0
	Sfx.play(&"whoosh", 0.0, 0.1)
	Sfx.play(&"dash", -6.0, 0.1)


## 벽에 박힘: 손잡이 발판을 켠다
func _stick() -> void:
	var n := get_wall_normal()
	var wall_dir := -1 if n.x > 0.0 else 1
	_set_state(S.STUCK, STUCK_TIME)
	aim = Vector2(wall_dir, 0)
	facing = wall_dir
	velocity = Vector2.ZERO
	launch_mult = 0.0 # 박혀 있는 동안은 불기둥에도 빠지지 않는다
	_platform_shape.set_deferred("disabled", false)
	Sfx.play(&"hit_heavy", -3.0, 0.1)
	Sfx.play(&"land", 0.0, 0.1)
	Fx.shake(0.12, 0.15)
	Fx.burst(center() + Vector2(wall_dir * 14, 0), 10, {
		direction = Vector2(-wall_dir, -0.4), spread = 60.0, speed_min = 40.0, speed_max = 120.0, lifetime = 0.4,
		gradient = Palette.fade_gradient(DUST), size_min = 1.0, size_max = 2.5, gravity = Vector2(0, 260),
	})


func _unstick() -> void:
	launch_mult = LAUNCH
	_platform_shape.set_deferred("disabled", true)
	_set_state(S.RECOVER, 0.45)
	velocity = Vector2(-facing * 140.0, -50.0)
	Sfx.play(&"whoosh", -4.0, 0.1)
	Fx.burst(center() + Vector2(facing * 14, 0), 6, {
		direction = Vector2(-facing, -0.3), spread = 50.0, speed_min = 30.0, speed_max = 90.0, lifetime = 0.3,
		gradient = Palette.fade_gradient(DUST), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 260),
	})


## 바닥·천장에 부딪히거나 급강하가 끊김: 잠깐 어질어질
func _bonk(bounce: bool) -> void:
	_set_state(S.BONK, 0.7 if bounce else 0.6)
	if bounce:
		velocity = Vector2(-aim.x * 70.0, -signf(aim.y) * 90.0)
		Sfx.play(&"land", 0.0, 0.1)
		Fx.shake(0.06, 0.1)
		Fx.burst(center() + aim * 12.0, 8, {
			direction = Vector2(0, -signf(aim.y)), spread = 70.0, speed_min = 30.0, speed_max = 90.0, lifetime = 0.35,
			gradient = Palette.fade_gradient(DUST), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 200),
		})
	else:
		velocity *= 0.2


func _aim_at(target: Vector2) -> Vector2:
	var v := target - center()
	if v.length() < 1.0:
		return Vector2(facing, 0)
	var horiz := 0.0 if v.x >= 0.0 else PI
	var diff := clampf(wrapf(v.angle() - horiz, -PI, PI), -MAX_DIVE, MAX_DIVE)
	return Vector2.from_angle(horiz + diff)


## from에서 to까지 벽에 막히는가 (to가 벽 속이어도 막힘)
func _blocked(from: Vector2, to: Vector2) -> bool:
	return not has_los(from, to + (to - from).normalized() * 16.0)


func _has_los(p: Player) -> bool:
	return has_los(center(), p.center())


func _trail(delta: float) -> void:
	_dust_t -= delta
	if _dust_t > 0.0:
		return
	_dust_t = 0.03
	Fx.burst(center() - aim * 20.0, 2, {
		direction = -aim, spread = 40.0, speed_min = 10.0, speed_max = 40.0, lifetime = 0.45,
		gradient = Palette.fade_gradient(DUST), size_min = 1.0, size_max = 2.5, gravity = Vector2(0, 30), damping = 40.0,
	})


## 폭주 마력이 묶음 띠에서 새어 나온다
func _leak_mana(delta: float) -> void:
	_wisp_t -= delta
	if _wisp_t > 0.0:
		return
	_wisp_t = 0.2
	var band := center() - aim * 9.0 if state in [S.WINDUP, S.SWOOP, S.STUCK] else center() + Vector2(-facing * 9.0, 0)
	Fx.burst(band, 1, {
		direction = Vector2.UP, spread = 30.0, speed_min = 6.0, speed_max = 18.0, lifetime = 0.8,
		gradient = Palette.fade_gradient(MANA), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, -20), add = true,
	})


func modify_damage(_hit: Hit) -> float:
	return STUCK_MULT if state == S.STUCK else 1.0


func _resists_knockback(hit: Hit) -> bool:
	return state == S.STUCK or (state == S.SWOOP and not hit.breaks_charge)


func _on_hit(hit: Hit, _dir: int) -> void:
	if state == S.WINDUP and (hit.breaks_charge or hit.launch_t > 0.0):
		_bonk(false) # 예고 중 화염 폭풍·불기둥에 맞으면 끊긴다
	elif state == S.SWOOP and hit.breaks_charge:
		_bonk(false)
	elif state == S.STUCK:
		Fx.burst(center() - aim * 16.0, 4, {
			direction = Vector2(-aim.x, -1), spread = 60.0, speed_min = 30.0, speed_max = 80.0, lifetime = 0.35,
			gradient = Palette.fade_gradient(Color("#d8b860")), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 240),
		})


func _die(dir: int) -> void:
	_platform_shape.set_deferred("disabled", true)
	super(dir)
