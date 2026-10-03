class_name Player
extends CharacterBody2D
## 세라 — 이동·점프·대시 + 화염탄 3타, 불기둥, 화염 폭풍, 폭주 게이지, 체력·피격·사망.
## 원점(0, 0)은 발밑. 수치는 전부 core/tuning.tres (docs/prototype.md 5절).

signal hp_changed(hp: int, max_hp: int)
signal died

enum State { IDLE, RUN, JUMP, FALL, DASH, HURT, STUN, DEAD }

const TUNING: Tuning = preload("res://core/tuning.tres")
const HAND := Vector2(11, -19) ## 화염탄이 나가는 손 위치 (오른쪽을 볼 때)

var tuning: Tuning = TUNING
var state: State = State.IDLE
var facing := 1 ## 1 = 오른쪽, -1 = 왼쪽
var hp := 5
var overload := 0.0 ## 폭주 게이지 0~100
var air_dashes_left := 0
var pillar_cooldown_left := 0.0
var storm_cooldown_left := 0.0
var controls_enabled := true
var last_jump_height_t := 0.0 ## 직전 점프의 실제 높이 (T). 디버그 표시용

# 남은 시간을 초 단위로 세는 타이머들
var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _dash_timer := 0.0
var _dash_cooldown_timer := 0.0
var _dash_iframe := 0.0
var _hurt_iframe := 0.0
var _hurt_timer := 0.0
var _stun_timer := 0.0
var _afterimage_timer := 0.0
var _attack_cooldown := 0.0
var _attack_buffer := 0.0
var _since_shot := 99.0
var _cast_pose := 0.0
var _cast_kind := 0
var _storm_timer := 0.0
var _overload_idle := 99.0
var _overload_fuse := -1.0 ## 0 이상이면 폭발까지 남은 시간
var _pulse_timer := 0.0
var _dust_timer := 0.0

var _combo_index := 0 ## 다음에 쏠 타 (0, 1, 2 = 1·2·3타)
var _dash_dir := 1
var _was_on_floor := true
var _fall_speed := 0.0
var _jump_start_y := 0.0
var _jump_peak_y := 0.0
var _squash: Tween

# tuning(T 단위)에서 계산한 실제 물리 값(px 단위)
var _max_speed := 0.0
var _accel := 0.0
var _decel := 0.0
var _gravity := 0.0
var _jump_velocity := 0.0
var _jump_cut_velocity := 0.0
var _max_fall_speed := 0.0
var _dash_speed := 0.0

@onready var _visual: Node2D = $Visual
@onready var _flip: Node2D = $Visual/Flip
@onready var _body: PlayerVisual = $Visual/Flip/Body
@onready var _hurtbox: Area2D = $Hurtbox
@onready var camera: GameCamera = $Camera2D


func _ready() -> void:
	add_to_group(GameConst.GROUP_PLAYER)
	collision_layer = GameConst.L_PLAYER
	collision_mask = GameConst.L_WORLD | GameConst.L_PLATFORM
	_hurtbox.collision_layer = GameConst.L_PLAYER_HURT
	_hurtbox.collision_mask = GameConst.L_ENEMY_ATTACK
	camera.tuning = tuning
	hp = tuning.max_hp
	recalculate()


## tuning 값을 픽셀 단위 물리 값으로 바꾼다.
func recalculate() -> void:
	var t := GameConst.TILE
	_max_speed = tuning.max_speed_t * t
	_accel = _max_speed / tuning.accel_time
	_decel = _max_speed / tuning.decel_time
	# 점프 공식: 높이 h를 시간 t_apex 만에 오르려면 중력 g = 2h / t², 초속 v = 2h / t
	var h_max := tuning.jump_height_max_t * t
	_gravity = 2.0 * h_max / pow(tuning.time_to_apex, 2)
	_jump_velocity = -2.0 * h_max / tuning.time_to_apex
	_jump_cut_velocity = -sqrt(2.0 * _gravity * tuning.jump_height_min_t * t)
	_max_fall_speed = tuning.max_fall_speed_t * t
	_dash_speed = tuning.dash_distance_t * t / tuning.dash_duration


func is_alive() -> bool:
	return state != State.DEAD


func is_invincible() -> bool:
	return _dash_iframe > 0.0 or _hurt_iframe > 0.0 or state == State.DEAD


func overload_ratio() -> float:
	return overload / tuning.overload_max


func overload_fusing() -> bool:
	return _overload_fuse >= 0.0


func center() -> Vector2:
	return global_position + Vector2(0, -16)


func heal_full() -> void:
	if hp < tuning.max_hp:
		hp = tuning.max_hp
		hp_changed.emit(hp, tuning.max_hp)


# ─── 매 프레임 ──────────────────────────────────────────

func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	if state == State.DEAD:
		velocity.y = minf(velocity.y + _gravity * delta, _max_fall_speed)
		velocity.x = move_toward(velocity.x, 0.0, _decel * delta)
		move_and_slide()
		_update_visual(delta)
		return

	var input_x := Input.get_axis("move_left", "move_right") if controls_enabled else 0.0
	if _can_act():
		_read_action_input(input_x)

	match state:
		State.DASH:
			_process_dash(delta)
		State.HURT, State.STUN:
			velocity.x = move_toward(velocity.x, 0.0, _decel * 0.5 * delta)
			_apply_gravity(delta)
		_:
			if input_x != 0.0 and _storm_timer <= 0.0:
				facing = 1 if input_x > 0.0 else -1
			_process_run(input_x, delta)
			_process_jump()
			_apply_gravity(delta)

	_fall_speed = velocity.y
	move_and_slide()
	_after_move()
	_update_state()
	_check_hurtbox()
	_update_overload(delta)
	_update_visual(delta)


func _tick_timers(delta: float) -> void:
	_coyote_timer -= delta
	_jump_buffer_timer -= delta
	_dash_cooldown_timer -= delta
	_dash_iframe -= delta
	_hurt_iframe -= delta
	_attack_cooldown -= delta
	_attack_buffer -= delta
	_since_shot += delta
	_cast_pose -= delta
	_storm_timer -= delta
	_overload_idle += delta
	pillar_cooldown_left = maxf(pillar_cooldown_left - delta, 0.0)
	storm_cooldown_left = maxf(storm_cooldown_left - delta, 0.0)
	if state == State.HURT:
		_hurt_timer -= delta
		if _hurt_timer <= 0.0:
			state = State.FALL
	elif state == State.STUN:
		_stun_timer -= delta
		if _stun_timer <= 0.0:
			state = State.FALL


func _can_act() -> bool:
	return controls_enabled and state != State.HURT and state != State.STUN and state != State.DEAD


func _read_action_input(input_x: float) -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = tuning.jump_buffer_time
	if Input.is_action_just_pressed("dash") and _can_dash():
		_start_dash(input_x)
	if state == State.DASH:
		return
	if Input.is_action_just_pressed("attack"):
		_attack_buffer = tuning.attack_buffer_time
	var wants_attack := _attack_buffer > 0.0 or Input.is_action_pressed("attack")
	if wants_attack and _attack_cooldown <= 0.0 and _storm_timer <= 0.0:
		_fire_bolt()
	if Input.is_action_just_pressed("skill_1") and pillar_cooldown_left <= 0.0 and _storm_timer <= 0.0:
		_cast_pillar()
	if Input.is_action_just_pressed("skill_2") and storm_cooldown_left <= 0.0:
		_cast_storm()


# ─── 이동 ───────────────────────────────────────────────

func _process_run(input_x: float, delta: float) -> void:
	var mult := tuning.storm_move_mult if _storm_timer > 0.0 else 1.0
	var target := input_x * _max_speed * mult
	var rate := _accel if input_x != 0.0 else _decel
	velocity.x = move_toward(velocity.x, target, rate * delta)


func _process_jump() -> void:
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = _jump_velocity
		_jump_start_y = position.y
		_jump_peak_y = position.y
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		_squash_to(Vector2(0.8, 1.2))
		Sfx.play(&"jump", -4.0)
		Fx.burst(global_position, 5, {
			direction = Vector2.UP, spread = 70.0, speed_min = 20.0, speed_max = 50.0, lifetime = 0.25,
			gradient = Palette.fade_gradient(Palette.GROUND_TOP), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 60),
		})
		if not Input.is_action_pressed("jump"):
			velocity.y = maxf(velocity.y, _jump_cut_velocity)
	if Input.is_action_just_released("jump") and velocity.y < _jump_cut_velocity:
		velocity.y = _jump_cut_velocity


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	var g := _gravity
	if velocity.y > 0.0:
		g *= tuning.fall_gravity_multiplier
	velocity.y = minf(velocity.y + g * delta, _max_fall_speed)


# ─── 대시 ───────────────────────────────────────────────

func _can_dash() -> bool:
	if state == State.DASH or _dash_cooldown_timer > 0.0:
		return false
	return is_on_floor() or air_dashes_left > 0


func _start_dash(input_x: float) -> void:
	if not is_on_floor():
		air_dashes_left -= 1
	if input_x != 0.0:
		_dash_dir = 1 if input_x > 0.0 else -1
	else:
		_dash_dir = facing
	facing = _dash_dir
	_dash_timer = tuning.dash_duration
	_dash_iframe = tuning.dash_invincible_time
	_afterimage_timer = 0.0
	_cancel_storm()
	state = State.DASH
	GameState.add("dashes")
	Sfx.play(&"dash")


func _process_dash(delta: float) -> void:
	_dash_timer -= delta
	if _dash_timer <= 0.0:
		state = State.FALL
		_dash_cooldown_timer = tuning.dash_cooldown
		velocity.x = _dash_dir * _max_speed
		return
	velocity = Vector2(_dash_dir * _dash_speed, 0.0)
	_afterimage_timer -= delta
	if _afterimage_timer <= 0.0:
		_spawn_afterimage()
		_afterimage_timer = tuning.dash_duration / 3.0


# ─── 화염탄 3타 ─────────────────────────────────────────

func _fire_bolt() -> void:
	if _since_shot > tuning.combo_keep_time:
		_combo_index = 0
	var heavy := _combo_index == 2
	var bolt := FireBolt.new()
	bolt.setup(facing, heavy, tuning)
	bolt.global_position = to_global(Vector2(HAND.x * facing, HAND.y))
	Fx.effect_parent().add_child(bolt)

	_attack_cooldown = tuning.bolt_interval_heavy if heavy else tuning.bolt_interval_light
	_combo_index = (_combo_index + 1) % 3
	_since_shot = 0.0
	_attack_buffer = 0.0
	_cast_pose = 0.18
	_cast_kind = 0
	GameState.add("bolts_fired")
	Sfx.play(&"shoot_heavy" if heavy else &"shoot", -1.0 if heavy else -3.0)
	Fx.burst(bolt.global_position, 6 if heavy else 3, {
		direction = Vector2(facing, 0), spread = 35.0, speed_min = 40.0, speed_max = 110.0,
		lifetime = 0.15, size_min = 1.0, size_max = 2.0, gravity = Vector2.ZERO,
	})
	if heavy:
		# 3타 반동: 뒤로 살짝 밀림
		velocity.x = -facing * 2.0 * tuning.heavy_recoil_t * GameConst.TILE / 0.1
		_squash_to(Vector2(1.1, 0.92))


# ─── 스킬 ───────────────────────────────────────────────

func _cast_pillar() -> void:
	var target := _find_pillar_target()
	var pos: Vector2
	if target:
		pos = target.global_position
	else:
		pos = _ground_point(global_position.x + facing * tuning.pillar_fallback_t * GameConst.TILE)
	var p := FirePillar.new()
	p.setup(pos, target, tuning)
	Fx.effect_parent().add_child(p)
	pillar_cooldown_left = tuning.pillar_cooldown
	_cast_pose = 0.3
	_cast_kind = 1
	GameState.add("pillar")
	_add_overload(tuning.pillar_overload)


## 바라보는 방향 7T 안, 땅에 서 있는 가장 가까운 적
func _find_pillar_target() -> Node2D:
	var best: Node2D = null
	var best_d := INF
	var range_px := tuning.pillar_range_t * GameConst.TILE
	for e in get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
		if not e.is_alive() or not e.is_on_floor():
			continue
		var dx: float = (e.global_position.x - global_position.x) * facing
		var dy: float = absf(e.global_position.y - global_position.y)
		if dx < -8.0 or dx > range_px or dy > 6.0 * GameConst.TILE:
			continue
		var d := Vector2(dx, dy).length()
		if d < best_d:
			best_d = d
			best = e
	return best


func _ground_point(x: float) -> Vector2:
	var space := get_world_2d().direct_space_state
	var from := Vector2(x, global_position.y - 2.0 * GameConst.TILE)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 12.0 * GameConst.TILE), GameConst.L_WORLD | GameConst.L_PLATFORM)
	var r := space.intersect_ray(q)
	if r:
		return r.position
	return Vector2(x, global_position.y)


func _cast_storm() -> void:
	var s := FireStorm.new()
	s.setup(facing, tuning)
	s.position = Vector2(facing * 6, -15)
	add_child(s)
	_storm_timer = tuning.storm_duration
	storm_cooldown_left = tuning.storm_cooldown
	_cast_pose = tuning.storm_duration + 0.1
	_cast_kind = 2
	GameState.add("storm")
	_add_overload(tuning.storm_overload)


func _cancel_storm() -> void:
	_storm_timer = 0.0
	for c in get_children():
		if c is FireStorm:
			c.queue_free()


# ─── 폭주 게이지 ────────────────────────────────────────

func _add_overload(amount: float) -> void:
	overload = minf(overload + amount, tuning.overload_max)
	_overload_idle = 0.0
	if overload >= tuning.overload_max and _overload_fuse < 0.0:
		_overload_fuse = tuning.overload_fuse
		Sfx.play(&"overload_warn", 2.0, 0.0)


func _update_overload(delta: float) -> void:
	if _overload_fuse >= 0.0:
		_overload_fuse -= delta
		Fx.set_vignette(0.5 + 0.5 * (1.0 - _overload_fuse / tuning.overload_fuse))
		if _overload_fuse < 0.0:
			_trigger_burst()
		return
	if _overload_idle > tuning.overload_decay_delay and overload > 0.0:
		overload = maxf(overload - tuning.overload_decay_rate * delta, 0.0)
	if overload_ratio() >= tuning.overload_warn_ratio:
		_pulse_timer -= delta
		if _pulse_timer <= 0.0:
			_pulse_timer = 0.45
			Sfx.play(&"overload_pulse", -4.0, 0.0)
	else:
		_pulse_timer = 0.0


func _trigger_burst() -> void:
	_overload_fuse = -1.0
	overload = 0.0
	Fx.set_vignette(0.0)
	var b := OverloadBurst.new()
	b.setup(center(), tuning)
	Fx.effect_parent().add_child(b)
	GameState.add("overloads")
	_cancel_storm()
	take_damage(tuning.burst_self_damage, &"overload", global_position.x, true)
	if state != State.DEAD:
		state = State.STUN
		_stun_timer = tuning.burst_stun
		velocity = Vector2(0, -140)


# ─── 피격·사망 ──────────────────────────────────────────

func _check_hurtbox() -> void:
	if is_invincible():
		return
	for a in _hurtbox.get_overlapping_areas():
		if a is EnemyAttackArea and a.active:
			if take_damage(a.damage, a.cause, a.global_position.x):
				a.notify_hit(self)
			return


## forced = 무적 시간과 상관없이 받는 피해 (폭주 자기 피해)
func take_damage(amount: int, cause: StringName, from_x: float, forced := false) -> bool:
	if state == State.DEAD:
		return false
	if not forced and is_invincible():
		return false
	hp = maxi(hp - amount, 0)
	GameState.add("hits_" + String(cause))
	hp_changed.emit(hp, tuning.max_hp)
	_hurt_iframe = tuning.hurt_invincible
	Fx.hitstop(tuning.hitstop_hurt)
	Fx.shake(tuning.shake_hurt_t)
	Fx.flash(Color(1.0, 0.1, 0.1, 0.32), 0.18)
	Sfx.play(&"hurt")
	Fx.burst(center(), 10, {
		spread = 180.0, speed_min = 40.0, speed_max = 120.0, lifetime = 0.35,
		gradient = Palette.fade_gradient(Palette.HP), size_min = 1.0, size_max = 2.5,
	})
	if hp <= 0:
		_die()
		return true
	if not forced:
		_cancel_storm()
		state = State.HURT
		_hurt_timer = tuning.hurt_stun
		var dir := signf(global_position.x - from_x)
		if dir == 0.0:
			dir = -facing
		velocity = Vector2(dir * 2.0 * tuning.hurt_knockback_t * GameConst.TILE / tuning.hurt_stun, -120.0)
	return true


func _die() -> void:
	state = State.DEAD
	controls_enabled = false
	_overload_fuse = -1.0
	Fx.set_vignette(0.0)
	_cancel_storm()
	velocity = Vector2(-facing * 60.0, -160.0)
	GameState.add("deaths")
	died.emit()
	Fx.slowmo(0.3, 0.7)
	Fx.burst(center(), 40, {
		spread = 180.0, speed_min = 40.0, speed_max = 200.0, lifetime = 0.9, damping = 80.0,
		size_min = 1.5, size_max = 3.5, gravity = Vector2(0, -50),
	})
	var t := create_tween().set_ignore_time_scale(true)
	t.tween_property(_visual, "modulate:a", 0.0, 0.8).set_delay(0.3)
	get_tree().create_timer(1.6, true, false, true).timeout.connect(GameState.restart_from_checkpoint)


# ─── 이동 후 처리 ───────────────────────────────────────

func _after_move() -> void:
	var on_floor := is_on_floor()
	_jump_peak_y = minf(_jump_peak_y, position.y)
	if on_floor:
		_coyote_timer = tuning.coyote_time
		air_dashes_left = tuning.air_dash_count
		if not _was_on_floor:
			_on_land()
		elif state == State.RUN and absf(velocity.x) > _max_speed * 0.6:
			_dust_timer -= get_physics_process_delta_time()
			if _dust_timer <= 0.0:
				_dust_timer = 0.14
				Fx.burst(global_position + Vector2(-facing * 3, 0), 2, {
					direction = Vector2(-facing, -1), spread = 30.0, speed_min = 10.0, speed_max = 30.0,
					lifetime = 0.3, gradient = Palette.fade_gradient(Color(Palette.GROUND_TOP, 0.7)),
					size_min = 1.0, size_max = 2.0, gravity = Vector2(0, -10),
				})
	_was_on_floor = on_floor


func _on_land() -> void:
	var impact := clampf(_fall_speed / _max_fall_speed, 0.0, 1.0)
	_squash_to(Vector2(1.15 + impact * 0.2, 0.85 - impact * 0.15))
	last_jump_height_t = (_jump_start_y - _jump_peak_y) / GameConst.TILE
	_jump_start_y = position.y
	_jump_peak_y = position.y
	if impact > 0.25:
		Sfx.play(&"land", -6.0 + impact * 4.0)
		Fx.burst(global_position, 4 + int(impact * 6.0), {
			direction = Vector2.UP, spread = 85.0, speed_min = 20.0, speed_max = 50.0 + impact * 40.0,
			lifetime = 0.3, gradient = Palette.fade_gradient(Palette.GROUND_TOP), size_min = 1.0, size_max = 2.0,
			gravity = Vector2(0, 80),
		})


func _update_state() -> void:
	if state == State.DASH or state == State.HURT or state == State.STUN or state == State.DEAD:
		return
	if is_on_floor():
		state = State.RUN if absf(velocity.x) > 1.0 else State.IDLE
	else:
		state = State.JUMP if velocity.y < 0.0 else State.FALL


# ─── 연출 ───────────────────────────────────────────────

func _update_visual(delta: float) -> void:
	_flip.scale.x = facing
	_body.pose = state as PlayerVisual.Pose
	_body.speed_x = velocity.x * facing
	_body.speed_y = velocity.y
	_body.cast = clampf(_cast_pose / 0.18, 0.0, 1.0) if _cast_pose > 0.0 else 0.0
	_body.cast_kind = _cast_kind
	_body.overload_ratio = overload_ratio()
	_body.overload_fuse = _overload_fuse >= 0.0
	_body.update_pose(delta)
	if state == State.DEAD:
		return
	# 무적: 대시 중엔 밝게, 피격 후엔 깜빡임, 폭주 직전엔 떨림
	if _dash_iframe > 0.0:
		_visual.modulate = Color(1.7, 1.5, 1.4)
		_visual.position.x = 0.0
	elif _hurt_iframe > 0.0:
		var blink := int(_hurt_iframe * 20.0) % 2 == 0
		_visual.modulate = Color(1, 1, 1, 0.35 if blink else 1.0)
		_visual.position.x = 0.0
	elif _overload_fuse >= 0.0:
		_visual.modulate = Color(1.4, 1.1, 1.0)
		_visual.position.x = randf_range(-1.0, 1.0)
	else:
		_visual.modulate = Color.WHITE
		_visual.position.x = 0.0


func _squash_to(amount: Vector2) -> void:
	if _squash:
		_squash.kill()
	_visual.scale = amount
	_squash = create_tween()
	_squash.tween_property(_visual, "scale", Vector2.ONE, 0.14) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _spawn_afterimage() -> void:
	var ghost := PlayerVisual.new()
	ghost.copy_pose_from(_body)
	ghost.ghost = true
	Fx.effect_parent().add_child(ghost)
	ghost.global_transform = _body.global_transform
	ghost.z_index = -1
	ghost.queue_redraw()
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.22)
	tween.tween_callback(ghost.queue_free)
