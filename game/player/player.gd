class_name Player
extends CharacterBody2D
## 세라 — 이동·점프·대시 + 화염탄(묵직한 한 발), 불기둥, 화염 폭풍, 폭주 게이지, 체력·피격·사망.
## v0.3: 빠른 이동, 대시 점프, 최고점 체공, 빠른 낙하, 발판 내려가기, 천장 모서리 보정,
##       대시 중 사격, 공중 체공 사격, 퍼펙트 회피(위치 타임), 과열 강화 (docs/prototype.md 14절).
## 원점(0, 0)은 발밑. 수치는 전부 core/tuning.tres.

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
var ward_cooldown_left := 0.0
var ult_cooldown_left := {"meteor": 0.0, "phoenix": 0.0} ## 고급 마법 재사용 대기 (docs/magic.md)
var controls_enabled := true
var fox_time := 0.0 ## 여우 모드(빙의) 남은 시간
var fox_energy := 1.0 ## 너울의 기운 0~1. 가득 차 있어야 폭주가 여우 모드로 바뀜 (docs/chapter1.md 12.4절)
var air_jumps_left := 0
var no_overload := false ## 봉인 결계 안: 폭주 게이지가 오르지 않음
var last_jump_height_t := 0.0 ## 직전 점프의 실제 높이 (T). 디버그 표시용

# 남은 시간을 초 단위로 세는 타이머들
var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _dash_timer := 0.0
var _dash_cooldown_timer := 0.0
var _dash_iframe := 0.0
var _since_dash := 99.0 ## 대시가 끝난 뒤 흐른 시간 (대시 점프 판정)
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
var _drop_timer := 0.0 ## 통과 발판 내려가는 중
var _witch_cooldown := 0.0
var _dodged_this_dash := false
var _potion_timer := 0.0
var _window_cooldown := 0.0
var _safe_positions: Array = []
var _safe_timer := 0.0
var _hazard_cool := 0.0
var _walk_target := INF
var _walk_speed := 90.0
var _fox_trail_t := 0.0
var _emote_node: EmoteBubble
var _ward_time := 0.0 ## 불꽃 방벽: 남은 시간 (무적)
var _ult_float := 0.0 ## 고급 마법 시전 중 떠 있는 시간 (무적, 조작 잠김)
var _gliding := false ## 불꽃 날개 활공 중
var _glide_armed := false ## 공중에서 점프를 다시 눌렀는가 (활공 조건)
var _updraft_power := 0.0 ## 이번 프레임 상승 기류 세기 (updraft 개체가 넣음)
var _updraft_top := 0.0
var _ember_t := 0.0

const FOX_DURATION := 12.0 ## 꼬리 1개 기준 (꼬리마다 +2초, docs/bible/progression.md 3절)
const FOX_RECHARGE := 50.0 ## 꼬리 1개 기준 (꼬리마다 −5초)
const POTION_HEAL := 2
const POTION_TIME := 0.6

var _air_hovers_left := 0
var _dash_dir := 1
var _dash_jumping := false
var _was_on_floor := true
var _was_overheated := false
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
	hp = GameState.hp
	recalculate()
	_emote_node = EmoteBubble.new()
	_emote_node.position = Vector2(0, -50)
	add_child(_emote_node)


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
	return _dash_iframe > 0.0 or _hurt_iframe > 0.0 or _ward_time > 0.0 or _ult_float > 0.0 or state == State.DEAD


## 불꽃 방벽을 두르고 있는가 (빛줄기·별 수정 장치가 읽음)
func is_warding() -> bool:
	return _ward_time > 0.0


func ward_center() -> Vector2:
	return global_position + Vector2(0, -16)


## 불꽃 날개로 활공 중인가
func is_gliding() -> bool:
	return _gliding


## 상승 기류 개체가 매 물리 프레임 부른다 (top_y: 기류 꼭대기, 거기서 힘이 약해짐)
func apply_updraft(power: float, top_y: float) -> void:
	_updraft_power = maxf(_updraft_power, power)
	_updraft_top = top_y


## 너울의 꼬리 수 (장 진행) — 여우 모드 시간·기운 회복이 달라진다
func tails() -> int:
	return clampi(int(GameState.flag("tails", 1)), 1, 9)


func fox_duration() -> float:
	var n := tails()
	if n >= 9:
		return 30.0
	return FOX_DURATION + 2.0 * (n - 1)


func fox_recharge() -> float:
	return maxf(FOX_RECHARGE - 5.0 * (tails() - 1), 25.0)


## 마법 재사용 대기 [남은 시간, 전체] (HUD·터치 버튼이 읽음)
func spell_cooldown(id: String) -> Vector2:
	var fox := is_fox()
	match id:
		"pillar":
			return Vector2(pillar_cooldown_left, Spells.cooldown_for(id, tuning) * (1.6 if fox else 1.0))
		"storm":
			return Vector2(storm_cooldown_left, Spells.cooldown_for(id, tuning) * (1.2 if fox else 1.0))
		"ward":
			return Vector2(ward_cooldown_left, Spells.cooldown_for(id, tuning))
		"meteor", "phoenix":
			return Vector2(float(ult_cooldown_left[id]), Spells.cooldown_for(id, tuning))
	return Vector2.ZERO


## 체력 회복 (불사조 등)
func heal(n: int) -> void:
	if state == State.DEAD:
		return
	hp = mini(hp + n, max_hp())
	GameState.hp = hp
	hp_changed.emit(hp, max_hp())


func overload_ratio() -> float:
	return overload / tuning.overload_max


func overload_fusing() -> bool:
	return _overload_fuse >= 0.0


## 폭주 게이지 70% 이상: 화염탄이 강해지는 과열 상태 (위험을 감수한 보상)
func is_overheated() -> bool:
	return overload_ratio() >= tuning.overload_warn_ratio or _overload_fuse >= 0.0


func center() -> Vector2:
	return global_position + Vector2(0, -16)


func max_hp() -> int:
	return GameState.max_hp


func heal_full() -> void:
	if hp < max_hp():
		hp = max_hp()
		GameState.hp = hp
		hp_changed.emit(hp, max_hp())


## GameState의 체력을 세라에게 반영 (방 이동·기록·부활 후)
func restore_from_state() -> void:
	hp = clampi(GameState.hp, 1, max_hp())
	hp_changed.emit(hp, max_hp())


func is_fox() -> bool:
	return fox_time > 0.0


func can_double_jump() -> bool:
	return GameState.has_ability("double_jump") or GameState.has_flag("temp_double_jump")


## 방에 들어갈 때 등장 위치로
func place_at(pos: Vector2, face: int) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	facing = face if face != 0 else facing
	if state == State.DASH:
		_end_dash()
	if state != State.DEAD:
		state = State.IDLE
	_safe_positions.clear()
	_walk_target = INF
	_cancel_storm()
	camera.reset_smoothing()


## 컷신 시작: 멈춰 세움
func halt() -> void:
	velocity.x = 0.0
	if state == State.DASH:
		_end_dash()
		velocity.x = 0.0
	_cancel_storm()
	_potion_timer = 0.0
	_body.drinking = false


func revive() -> void:
	state = State.IDLE
	controls_enabled = true
	overload = 0.0
	_overload_fuse = -1.0
	fox_time = 0.0
	fox_energy = 1.0
	_hurt_iframe = 1.0
	_visual.modulate = Color.WHITE
	_body.fox = 0.0
	restore_from_state()
	Fx.set_vignette(0.0)


## 멈춤 안내에서 누른 키를 이어서 실행
func buffer_action(a: String) -> void:
	match a:
		"jump":
			# 안내 중 ↓를 누른 채 Z를 눌렀다면 발판 내려가기
			if Input.is_action_pressed("move_down") and is_on_floor() and _standing_on_platform():
				_drop_through()
			else:
				_jump_buffer_timer = tuning.jump_buffer_time
		"attack":
			_attack_buffer = tuning.attack_buffer_time
		"dash":
			if _can_dash():
				_start_dash(0.0)
		"skill_1":
			cast_slot("a")
		"skill_2":
			cast_slot("s")
		"skill_3":
			cast_slot("f")
		"fox_window":
			_open_window()


## 컷신에서 걸어가기 (도착하면 돌아옴)
func walk_to(x: float, speed := 90.0) -> void:
	_walk_target = x
	_walk_speed = speed
	var guard := 0
	while _walk_target != INF and guard < 600:
		await get_tree().physics_frame
		guard += 1
	_walk_target = INF


func emote(kind: String, time := 1.2) -> void:
	_emote_node.show_emote(kind, time)


## 가시·불꽃: 1 피해 + 직전 안전한 땅으로
func hazard_hit() -> void:
	if state == State.DEAD or _hazard_cool > 0.0:
		return
	_hazard_cool = 0.6
	var back: Vector2 = _safe_positions[0] if not _safe_positions.is_empty() else global_position + Vector2(-facing * 32, -16)
	if take_damage(1, &"hazard", global_position.x, true) and state != State.DEAD:
		global_position = back
		velocity = Vector2.ZERO
		state = State.FALL
		_hurt_iframe = tuning.hurt_invincible
		camera.reset_smoothing()


## 적에게 공격이 맞았을 때 EnemyBase가 알려 준다
func on_hit_landed(_hit: Hit) -> void:
	if tuning.hit_refreshes_air_dash and not is_on_floor():
		air_dashes_left = maxi(air_dashes_left, tuning.air_dash_count)


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
	var down := controls_enabled and Input.is_action_pressed("move_down")
	if _walk_target != INF:
		var dx := _walk_target - global_position.x
		if absf(dx) < 3.0:
			_walk_target = INF
			velocity.x = 0.0
		else:
			input_x = signf(dx) * clampf(_walk_speed / _max_speed, 0.2, 1.0)
	if _potion_timer > 0.0:
		input_x *= 0.3
	if _can_act():
		_read_action_input(input_x, down)

	match state:
		State.DASH:
			_process_dash(delta)
		State.HURT, State.STUN:
			velocity.x = move_toward(velocity.x, 0.0, _decel * 0.5 * delta)
			_apply_gravity(delta, false)
		_:
			if input_x != 0.0 and _storm_timer <= 0.0:
				facing = 1 if input_x > 0.0 else -1
			_process_run(input_x, delta)
			_process_jump()
			_apply_gravity(delta, down)

	_fall_speed = velocity.y
	var vy_before := velocity.y
	move_and_slide()
	_corner_correction(vy_before)
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
	_since_dash += delta
	_hurt_iframe -= delta
	_attack_cooldown -= delta
	_attack_buffer -= delta
	_since_shot += delta
	_cast_pose -= delta
	_storm_timer -= delta
	_overload_idle += delta
	_witch_cooldown -= delta
	_window_cooldown -= delta
	_hazard_cool -= delta
	if _potion_timer > 0.0:
		_potion_timer -= delta
		if _potion_timer <= 0.0:
			_finish_potion()
	pillar_cooldown_left = maxf(pillar_cooldown_left - delta, 0.0)
	storm_cooldown_left = maxf(storm_cooldown_left - delta, 0.0)
	ward_cooldown_left = maxf(ward_cooldown_left - delta, 0.0)
	for k in ult_cooldown_left:
		ult_cooldown_left[k] = maxf(float(ult_cooldown_left[k]) - delta, 0.0)
	_ward_time = maxf(_ward_time - delta, 0.0)
	if _ult_float > 0.0:
		_ult_float -= delta
	if _drop_timer > 0.0:
		_drop_timer -= delta
		if _drop_timer <= 0.0:
			collision_mask = GameConst.L_WORLD | GameConst.L_PLATFORM
	if state == State.HURT:
		_hurt_timer -= delta
		if _hurt_timer <= 0.0:
			state = State.FALL
	elif state == State.STUN:
		_stun_timer -= delta
		if _stun_timer <= 0.0:
			state = State.FALL


func _can_act() -> bool:
	return controls_enabled and state != State.HURT and state != State.STUN and state != State.DEAD and _ult_float <= 0.0


func _read_action_input(input_x: float, down: bool) -> void:
	if Input.is_action_just_pressed("jump") and not is_on_floor() and _coyote_timer <= 0.0:
		_glide_armed = true # 불꽃 날개: 공중에서 다시 누르고 있으면 활공
	if Input.is_action_just_pressed("jump"):
		if down and is_on_floor() and _standing_on_platform():
			_drop_through()
		elif not is_on_floor() and _coyote_timer <= 0.0 and air_jumps_left > 0 and can_double_jump() and state != State.DASH:
			_double_jump()
		else:
			_jump_buffer_timer = tuning.jump_buffer_time
	if Input.is_action_just_pressed("potion"):
		_drink_potion()
	if Input.is_action_just_pressed("fox_window"):
		_open_window()
	if Input.is_action_just_pressed("dash") and _can_dash():
		_start_dash(input_x)
	# 대시 중에도 화염탄·불기둥은 쏠 수 있다 (화염 폭풍은 자세를 잡아야 하므로 대시를 끊고 시전)
	if Input.is_action_just_pressed("attack"):
		_attack_buffer = tuning.attack_buffer_time
	var wants_attack := _attack_buffer > 0.0 or Input.is_action_pressed("attack")
	if wants_attack and _attack_cooldown <= 0.0 and _storm_timer <= 0.0:
		_fire_bolt()
	if Input.is_action_just_pressed("skill_1"):
		cast_slot("a")
	if Input.is_action_just_pressed("skill_2"):
		cast_slot("s")
	if Input.is_action_just_pressed("skill_3"):
		cast_slot("f")


# ─── 이동 ───────────────────────────────────────────────

func _process_run(input_x: float, delta: float) -> void:
	var mult := tuning.storm_move_mult if _storm_timer > 0.0 else 1.0
	var target := input_x * _max_speed * mult
	if _gliding:
		target = input_x * (tuning.glide_speed_t + (2.0 if Spells.level("wings") >= 2 else 0.0)) * GameConst.TILE
	var over := absf(velocity.x) > _max_speed and signf(velocity.x) == signf(input_x)
	if over:
		# 대시 점프 등으로 최고 속도를 넘었으면 관성을 살려 천천히 줄인다
		var over_decel := tuning.over_speed_decel_t if is_on_floor() else tuning.over_speed_air_decel_t
		velocity.x = move_toward(velocity.x, target, over_decel * GameConst.TILE * delta)
	else:
		var rate := _accel if input_x != 0.0 else _decel
		if not is_on_floor() and input_x == 0.0:
			rate *= 0.35 # 공중에서 손을 떼면 미끄러지듯 관성 유지
		velocity.x = move_toward(velocity.x, target, rate * delta)


func _process_jump() -> void:
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		var dash_jump := _since_dash <= tuning.dash_jump_window and _was_on_floor
		_do_jump(dash_jump)
	if Input.is_action_just_released("jump") and velocity.y < _jump_cut_velocity:
		velocity.y = _jump_cut_velocity


func _do_jump(dash_jump: bool) -> void:
	velocity.y = _jump_velocity
	_jump_start_y = position.y
	_jump_peak_y = position.y
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0
	_squash_to(Vector2(0.75, 1.25))
	if dash_jump:
		# 대시 점프: 대시 속도를 이어받아 멀리 뛴다
		velocity.x = _dash_dir * tuning.dash_jump_speed_t * GameConst.TILE
		_dash_jumping = true
		Sfx.play(&"dash_jump", -2.0)
		Fx.ring(global_position + Vector2(0, -2), 2.0, 16.0, Palette.FIRE_HOT, 0.2, 1.0)
	else:
		Sfx.play(&"jump", -4.0)
	Fx.burst(global_position, 6, {
		direction = Vector2.UP, spread = 70.0, speed_min = 20.0, speed_max = 60.0, lifetime = 0.25,
		gradient = Palette.fade_gradient(Palette.GROUND_TOP), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 60),
	})
	if not Input.is_action_pressed("jump"):
		velocity.y = maxf(velocity.y, _jump_cut_velocity)


func _apply_gravity(delta: float, fast_fall: bool) -> void:
	if _ult_float > 0.0:
		# 고급 마법 시전: 공중에 떠서 하늘에 마력을 바침
		velocity.y = move_toward(velocity.y, -24.0, 700.0 * delta)
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		_updraft_power = 0.0
		return
	_update_glide()
	if is_on_floor():
		_updraft_power = 0.0
		return
	if _gliding:
		_glide_physics(delta)
		_updraft_power = 0.0
		return
	_updraft_power = 0.0
	var g := _gravity
	var max_fall := _max_fall_speed
	if velocity.y > 0.0:
		g *= tuning.fall_gravity_multiplier
	# 최고점 근처에서 점프를 누르고 있으면 중력 절반 → 공중에서 조준할 여유
	if absf(velocity.y) < tuning.apex_hang_speed_t * GameConst.TILE and Input.is_action_pressed("jump"):
		g *= 0.5
	if fast_fall and velocity.y > 0.0:
		g *= 1.4
		max_fall = tuning.fast_fall_speed_t * GameConst.TILE
	velocity.y = minf(velocity.y + g * delta, max_fall)


## 불꽃 날개: 배웠고, 공중에서 점프를 다시 누르고 있으면(또는 상승 기류 안에서 누르고 있으면) 활공
func _update_glide() -> void:
	var want := Spells.learned("wings") and controls_enabled and not is_on_floor() \
		and (state == State.JUMP or state == State.FALL) and Input.is_action_pressed("jump") and _potion_timer <= 0.0
	if want:
		want = _updraft_power > 0.0 or (_glide_armed and velocity.y > -40.0)
	if want and not _gliding:
		Sfx.play(&"glide", -6.0, 0.08)
	_gliding = want


func _glide_physics(delta: float) -> void:
	var t := GameConst.TILE
	var lv := Spells.level("wings")
	if _updraft_power > 0.0:
		var lift := tuning.updraft_speed_t * t * _updraft_power * (1.25 if lv >= 2 else 1.0)
		# 기류 꼭대기 3칸 안에서는 힘이 약해져 그 높이에 머문다
		var k := clampf((global_position.y - _updraft_top) / (3.0 * t), 0.15, 1.0)
		velocity.y = move_toward(velocity.y, -lift * k, 1500.0 * delta)
	else:
		var fall := tuning.glide_fall_speed_t * t
		if velocity.y < fall:
			velocity.y = minf(velocity.y + _gravity * 0.5 * delta, fall)
		else:
			velocity.y = move_toward(velocity.y, fall, 1200.0 * delta)
	if lv >= 3:
		_ember_t -= delta
		if _ember_t <= 0.0:
			_ember_t = 0.35
			_drop_ember()


## 불꽃 날개 Lv3: 아래로 불씨 — 발밑 아래 6칸 안 적에게 피해
func _drop_ember() -> void:
	var c := global_position
	Fx.burst(c, 3, {direction = Vector2.DOWN, spread = 20.0, speed_min = 80.0, speed_max = 140.0, lifetime = 0.5,
		gradient = Palette.fade_gradient(Palette.FIRE_HOT), gravity = Vector2(0, 300), add = true})
	for e in get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
		var en := e as EnemyBase
		if en == null or not en.is_alive():
			continue
		var d := en.global_position - c
		if absf(d.x) < 1.5 * GameConst.TILE and d.y > 0.0 and d.y < 6.0 * GameConst.TILE + en.body_size.y:
			var h := Hit.make(28, &"storm", c)
			h.hitstop = 0.0
			en.take_hit(h)


## 통과 발판(충돌 층 L_PLATFORM) 위에 서 있는가: 연습 방의 Block, 1장 방의 발판, 숨은 발판, 벽에 박힌 빗자루 모두
func _standing_on_platform() -> bool:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var body := c.get_collider() as CollisionObject2D
		if c.get_normal().y < -0.7 and body and (body.collision_layer & GameConst.L_PLATFORM) != 0:
			return true
	return false


func _drop_through() -> void:
	collision_mask = GameConst.L_WORLD
	_drop_timer = 0.22
	position.y += 2.0
	velocity.y = maxf(velocity.y, 60.0)


## 점프하다 천장 모서리에 머리가 살짝 걸리면 옆으로 밀어 주어 계속 오르게 한다
func _corner_correction(vy_before: float) -> void:
	if vy_before >= 0.0 or not is_on_ceiling():
		return
	for d in range(1, tuning.corner_correction_px + 1):
		for s in [-1, 1]:
			var shifted := global_transform.translated(Vector2(s * d, 0))
			if not test_move(shifted, Vector2(0, -3)):
				position.x += s * d
				velocity.y = vy_before
				return


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
	_dodged_this_dash = false
	_dash_jumping = false
	_cancel_storm()
	state = State.DASH
	GameState.add("dashes")
	Sfx.play(&"dash")
	Fx.burst(global_position + Vector2(-_dash_dir * 4, -8), 8, {
		direction = Vector2(-_dash_dir, 0), spread = 25.0, speed_min = 60.0, speed_max = 160.0, lifetime = 0.25,
		size_min = 1.0, size_max = 2.0, gravity = Vector2.ZERO,
	})


func _process_dash(delta: float) -> void:
	_dash_timer -= delta
	# 땅 대시 중 점프 → 대시 점프
	if _jump_buffer_timer > 0.0 and is_on_floor():
		_end_dash()
		_do_jump(true)
		return
	if _dash_timer <= 0.0:
		_end_dash()
		return
	velocity = Vector2(_dash_dir * _dash_speed, 0.0)
	if is_fox():
		_fox_trail_t -= delta
		if _fox_trail_t <= 0.0:
			_fox_trail_t = 0.035
			var tr := FoxTrail.new()
			tr.global_position = global_position + Vector2(0, -10)
			Fx.effect_parent().add_child(tr)
	_afterimage_timer -= delta
	if _afterimage_timer <= 0.0:
		_spawn_afterimage(0.6)
		_afterimage_timer = tuning.dash_duration / 4.0


func _end_dash() -> void:
	state = State.FALL
	_dash_cooldown_timer = tuning.dash_cooldown
	_since_dash = 0.0
	velocity.x = _dash_dir * _max_speed


# ─── 화염탄 (묵직한 한 발) ──────────────────────────────

## v0.4: 약 1.2초마다 커다란 한 발 (누르고 있으면 그 간격으로 계속). 여우 모드면 유도·관통 여우불
func _fire_bolt() -> void:
	var hand := to_global(Vector2(HAND.x * facing, HAND.y))
	if is_fox():
		FoxfireBolt.fire(hand, facing, tuning)
	else:
		var bolt := FireBolt.new()
		bolt.setup(facing, tuning, is_overheated())
		bolt.global_position = hand
		Fx.effect_parent().add_child(bolt)
		Sfx.play(&"shoot_heavy", 0.0)

	_attack_cooldown = tuning.shot_interval
	_since_shot = 0.0
	_attack_buffer = 0.0
	_cast_pose = 0.22
	_cast_kind = 0
	GameState.add("bolts_fired")
	var col := Color(0.55, 0.85, 1.0) if is_fox() else Palette.FIRE_HOT
	Fx.burst(hand, 14, {
		direction = Vector2(facing, 0), spread = 40.0, speed_min = 80.0, speed_max = 220.0,
		lifetime = 0.2, size_min = 1.5, size_max = 3.0, gravity = Vector2.ZERO,
		gradient = Palette.fade_gradient(col), add = true,
	})
	Fx.ring(hand, 2.0, 14.0, col, 0.15, 2.0)
	Fx.shake(tuning.shake_light_t)
	# 공중 사격: 낙하를 잠깐 멈춰 떠 있게 한다 (착지 전까지 정해진 횟수)
	if not is_on_floor() and state != State.DASH and _air_hovers_left > 0 and velocity.y > -20.0:
		velocity.y = minf(velocity.y, tuning.air_shot_hover_speed_t * GameConst.TILE)
		_air_hovers_left -= 1
	if state != State.DASH:
		# 반동: 뒤로 밀림 (공중에서는 절반)
		var k := 1.0 if is_on_floor() else 0.5
		velocity.x = -facing * 2.0 * tuning.heavy_recoil_t * GameConst.TILE / 0.1 * k
		_squash_to(Vector2(1.12, 0.9))


# ─── 스킬 (마법 7종 — docs/magic.md) ────────────────────

## 장착 칸(a·s·f)의 마법을 쓴다. 여우 모드면 불기둥 → 여우비, 화염 폭풍 → 구미호 폭풍
func cast_slot(slot: String) -> void:
	var id := Spells.equipped(slot)
	if id == "" and slot == "s" and is_fox():
		id = "storm" # 1장 해태전: 화염 폭풍을 배우기 전에도 여우 모드 S는 구미호 폭풍
	if id == "":
		if slot == "s" and not GameState.has_ability("storm") and not GameState.has_ability("ward"):
			Story.toast("아직 배우지 않은 마법이다.")
		elif slot == "f" and (GameState.has_ability("meteor") or GameState.has_ability("phoenix")):
			Story.toast("마법서(일시정지 → 마법서)에서 F 칸에 고급 마법을 끼우자.")
		return
	match id:
		"pillar":
			if pillar_cooldown_left <= 0.0 and _storm_timer <= 0.0:
				_cast_skill_1()
		"storm":
			if storm_cooldown_left <= 0.0:
				if state == State.DASH:
					_end_dash()
				_cast_skill_2()
		"ward":
			if ward_cooldown_left <= 0.0:
				_cast_ward()
		"meteor":
			if float(ult_cooldown_left.meteor) <= 0.0 and _ult_float <= 0.0:
				_cast_meteor()
			elif float(ult_cooldown_left.meteor) > 0.0:
				Sfx.play(&"block", -10.0, 0.0)
		"phoenix":
			if float(ult_cooldown_left.phoenix) <= 0.0 and _ult_float <= 0.0:
				_cast_phoenix()
			elif float(ult_cooldown_left.phoenix) > 0.0:
				Sfx.play(&"block", -10.0, 0.0)


## 레벨을 반영한 수치 사본 (불기둥·화염 폭풍)
func _scaled(id: String) -> Tuning:
	var t := tuning.duplicate() as Tuning
	var m := Spells.dmg_mult(id)
	match id:
		"pillar":
			t.pillar_damage = int(round(tuning.pillar_damage * m))
			t.pillar_side_damage = int(round(tuning.pillar_side_damage * m))
			if Spells.level(id) >= 3:
				t.pillar_side_count = tuning.pillar_side_count + 1
		"storm":
			t.storm_tick_damage = int(round(tuning.storm_tick_damage * m))
			t.storm_final_damage = int(round(tuning.storm_final_damage * m))
	return t


func _cast_ward() -> void:
	var w := FlameWard.new()
	w.setup(self, tuning, Spells.level("ward"), is_fox())
	add_child(w)
	_ward_time = w.duration
	ward_cooldown_left = Spells.cooldown_for("ward", tuning)
	_cast_pose = 0.35
	_cast_kind = 2
	Sfx.play(&"ward", -2.0, 0.05)
	GameState.add("ward")
	_add_overload(tuning.ward_overload)


func _cast_meteor() -> void:
	var m := MeteorFall.new()
	m.setup(self, tuning, Spells.level("meteor"), is_fox())
	Fx.effect_parent().add_child(m)
	ult_cooldown_left.meteor = Spells.cooldown_for("meteor", tuning)
	_ult_float = MeteorFall.CAST
	_cast_pose = MeteorFall.CAST
	_cast_kind = 2
	_cancel_storm()
	if state == State.DASH:
		_end_dash()
	velocity = Vector2(0, -90)
	# 모든 마력을 하늘에: 폭주 게이지가 비워짐
	if not is_fox():
		overload = 0.0
		_overload_fuse = -1.0
		Fx.set_vignette(0.0)
	GameState.add("meteor")


func _cast_phoenix(revive := false) -> void:
	var ph := PhoenixCall.new()
	ph.setup(self, tuning, Spells.level("phoenix"), is_fox(), revive)
	Fx.effect_parent().add_child(ph)
	ult_cooldown_left.phoenix = Spells.cooldown_for("phoenix", tuning)
	_ult_float = 0.45
	_cast_pose = 0.45
	_cast_kind = 2
	if not revive:
		heal(2 if Spells.level("phoenix") >= 2 else 1)
	if not is_fox():
		overload = maxf(overload - 50.0, 0.0)
	GameState.add("phoenix")


func _cast_skill_1() -> void:
	if is_fox():
		var r := FoxRain.new()
		r.setup(self, _scaled("pillar"))
		Fx.effect_parent().add_child(r)
		pillar_cooldown_left = Spells.cooldown_for("pillar", tuning) * 1.6
		_cast_pose = 0.4
		_cast_kind = 1
		GameState.add("pillar")
	else:
		_cast_pillar()


func _cast_skill_2() -> void:
	if is_fox():
		var st := NineTailStorm.new()
		st.setup(self, _scaled("storm"))
		add_child(st)
		_storm_timer = 0.5
		storm_cooldown_left = Spells.cooldown_for("storm", tuning) * 1.2
		_cast_pose = 0.6
		_cast_kind = 2
		if not is_on_floor():
			velocity.y = minf(velocity.y, 0.0)
		GameState.add("storm")
	else:
		_cast_storm()


func _double_jump() -> void:
	air_jumps_left -= 1
	velocity.y = _jump_velocity * 0.87 * (1.07 if Spells.level("levitate") >= 2 else 1.0)
	_jump_start_y = position.y
	_jump_peak_y = position.y
	_squash_to(Vector2(0.75, 1.25))
	Sfx.play(&"double_jump", -2.0)
	# 발밑 마법진
	Fx.ring(global_position + Vector2(0, -1), 3.0, 18.0, Color(0.75, 0.65, 1.0) if not is_fox() else Color(0.55, 0.85, 1.0), 0.25, 1.0)
	Fx.burst(global_position, 10, {direction = Vector2.DOWN, spread = 60.0, speed_min = 30.0, speed_max = 90.0,
		lifetime = 0.3, gradient = Palette.fade_gradient(Color(0.8, 0.75, 1.0)), gravity = Vector2.ZERO, add = true})


func _drink_potion() -> void:
	if _potion_timer > 0.0 or GameState.potions <= 0:
		if GameState.potions_max > 0 and GameState.potions <= 0:
			Story.toast("물약이 없다. 기록 지점에서 다시 채워진다.")
		return
	if hp >= max_hp():
		Story.toast("체력이 가득하다.")
		return
	_potion_timer = POTION_TIME
	_body.drinking = true
	Sfx.play(&"potion", -2.0)


func _finish_potion() -> void:
	_body.drinking = false
	if state == State.DEAD or GameState.potions <= 0:
		return
	GameState.potions -= 1
	hp = mini(hp + POTION_HEAL, max_hp())
	GameState.hp = hp
	hp_changed.emit(hp, max_hp())
	Fx.burst(center(), 18, {spread = 180.0, speed_min = 20.0, speed_max = 70.0, lifetime = 0.6,
		gradient = Palette.fade_gradient(Color(1.0, 0.5, 0.6)), gravity = Vector2(0, -60), add = true})
	Fx.ring(center(), 4.0, 22.0, Color(1.0, 0.6, 0.7), 0.3, 1.0)
	if GameState.has_flag("pippa_potion"):
		var lines := ["…딸기 맛? 아니, 이건 양말 맛이야.", "쓰다! 그래도 힘이 난다.", "피피, 대체 뭘 넣은 거야…", "어, 의외로 맛있어.", "혀가 파래졌을 것 같아."]
		Story.toast(lines[randi() % lines.size()], 1.8)


func _open_window() -> void:
	if not GameState.has_ability("fox_window") or _window_cooldown > 0.0:
		return
	if get_tree().get_first_node_in_group(&"fox_window"):
		return
	var w := FoxWindow.new()
	w.setup(self)
	Fx.effect_parent().add_child(w)
	_window_cooldown = FoxWindow.DURATION + 2.0
	_cast_pose = 0.5
	_cast_kind = 2
	Sfx.play(&"window", -2.0, 0.0)


func _cast_pillar() -> void:
	var target := _find_pillar_target()
	var pos: Vector2
	if target:
		pos = target.global_position
	else:
		pos = _ground_point(global_position.x + facing * tuning.pillar_fallback_t * GameConst.TILE)
	var p := FirePillar.new()
	p.setup(pos, target, _scaled("pillar"), facing)
	Fx.effect_parent().add_child(p)
	pillar_cooldown_left = Spells.cooldown_for("pillar", tuning)
	_cast_pose = 0.3
	_cast_kind = 1
	GameState.add("pillar")
	_add_overload(tuning.pillar_overload)


## 바라보는 방향 사거리 안, 땅에 서 있는 가장 가까운 적
func _find_pillar_target() -> Node2D:
	var best: Node2D = null
	var best_d := INF
	var range_px := tuning.pillar_range_t * GameConst.TILE
	for e in get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
		if not e.is_alive() or not e.is_on_floor():
			continue
		var dx: float = (e.global_position.x - global_position.x) * facing
		var dy: float = absf(e.global_position.y - global_position.y)
		if dx < -8.0 or dx > range_px or dy > 7.0 * GameConst.TILE:
			continue
		var d := Vector2(dx, dy).length()
		if d < best_d:
			best_d = d
			best = e
	if best == null:
		for b in get_tree().get_nodes_in_group(&"pillar_target"):
			if not b.is_alive():
				continue
			var dx2: float = (b.global_position.x - global_position.x) * facing
			var dy2: float = absf(b.global_position.y - global_position.y)
			if dx2 < -8.0 or dx2 > range_px or dy2 > 7.0 * GameConst.TILE:
				continue
			var d2 := Vector2(dx2, dy2).length()
			if d2 < best_d:
				best_d = d2
				best = b
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
	s.setup(facing, _scaled("storm"))
	s.position = Vector2(facing * 6, -15)
	add_child(s)
	_storm_timer = tuning.storm_duration
	storm_cooldown_left = Spells.cooldown_for("storm", tuning)
	if Spells.level("storm") >= 3:
		# Lv3: 지나간 자리에 2초 불바다
		var g := _ground_point(global_position.x + facing * 3.0 * GameConst.TILE)
		BurnGround.spawn(g, 5.0 * GameConst.TILE, 60.0 * Spells.dmg_mult("storm"), 2.0, &"storm")
	_cast_pose = tuning.storm_duration + 0.1
	_cast_kind = 2
	# 시전 반동: 뒤로 밀려나며 내뿜는다
	velocity.x = -facing * 2.0 * tuning.storm_recoil_t * GameConst.TILE / 0.2
	if not is_on_floor():
		velocity.y = minf(velocity.y, 0.0)
	GameState.add("storm")
	_add_overload(tuning.storm_overload)


func _cancel_storm() -> void:
	_storm_timer = 0.0
	for c in get_children():
		if c is FireStorm:
			c.queue_free()


# ─── 폭주 게이지 ────────────────────────────────────────

func _add_overload(amount: float) -> void:
	if is_fox() or no_overload:
		return
	overload = minf(overload + amount, tuning.overload_max)
	_overload_idle = 0.0
	if overload >= tuning.overload_max:
		_on_overload_full()


## 폭주 게이지가 가득 참: 너울이 있고 기운이 차 있으면 여우 모드, 아니면 폭주 폭발
func _on_overload_full() -> void:
	if GameState.has_ability("fox_mode") and fox_energy >= 1.0:
		start_fox_mode()
	elif _overload_fuse < 0.0:
		_overload_fuse = tuning.overload_fuse
		Sfx.play(&"overload_warn", 2.0, 0.0)


## 대본에서 폭주 게이지를 강제로 채움 (P4 폭주 폭발, P7 첫 빙의)
func force_overload_full() -> void:
	overload = tuning.overload_max
	_overload_idle = 0.0
	_on_overload_full()


func start_fox_mode() -> void:
	overload = 0.0
	_overload_fuse = -1.0
	Fx.set_vignette(0.0)
	fox_time = fox_duration()
	fox_energy = 0.0
	_hurt_iframe = maxf(_hurt_iframe, 1.0)
	GameState.add("fox_modes")
	var fx := FoxTransformFx.new()
	fx.setup(self)
	Fx.effect_parent().add_child(fx)
	var w := World.get_world()
	if w:
		w.pet.merge_into_player()


func _end_fox_mode() -> void:
	fox_time = 0.0
	overload = 0.0
	var b := FoxEndBurst.new()
	b.setup(center(), tuning)
	Fx.effect_parent().add_child(b)
	var w := World.get_world()
	if w:
		w.pet.leave_player()


func _update_overload(delta: float) -> void:
	if fox_time > 0.0:
		if not GameState.has_flag("fox_permanent"): # 5장 최종 구간: 아홉 꼬리 완전 빙의
			fox_time -= delta
		_body.fox = minf(_body.fox + delta * 4.0, 1.0)
		if fox_time <= 0.0:
			_end_fox_mode()
		return
	_body.fox = maxf(_body.fox - delta * 3.0, 0.0)
	if fox_energy < 1.0:
		fox_energy = minf(fox_energy + delta / fox_recharge(), 1.0)
	_body.mimic = 1.0 if GameState.has_ability("fox_mode") and is_overheated() and fox_energy >= 1.0 else 0.0
	var heated := is_overheated()
	if heated and not _was_overheated:
		Sfx.play(&"overheat", -2.0, 0.0)
		Fx.ring(center(), 4.0, 26.0, Palette.FIRE_OUT, 0.3, 1.0)
		var hud := get_tree().get_first_node_in_group(&"hud")
		if hud:
			hud.banner("과열! 화염탄 강화", 0.8)
	_was_overheated = heated

	if _overload_fuse >= 0.0:
		_overload_fuse -= delta
		Fx.set_vignette(0.5 + 0.5 * (1.0 - _overload_fuse / tuning.overload_fuse))
		if _overload_fuse < 0.0:
			_trigger_burst()
		return
	if _overload_idle > tuning.overload_decay_delay and overload > 0.0:
		overload = maxf(overload - tuning.overload_decay_rate * delta, 0.0)
	if heated:
		_pulse_timer -= delta
		if _pulse_timer <= 0.0:
			_pulse_timer = 0.45
			Sfx.play(&"overload_pulse", -6.0, 0.0)
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
		velocity = Vector2(0, -180)


# ─── 피격·사망·퍼펙트 회피 ──────────────────────────────

func _check_hurtbox() -> void:
	var areas := _hurtbox.get_overlapping_areas()
	if _dash_iframe > 0.0:
		# 대시 무적 중 공격이 몸을 스치면 퍼펙트 회피 → 위치 타임
		if not _dodged_this_dash and tuning.perfect_dodge_enabled and _witch_cooldown <= 0.0:
			for a in areas:
				if a is EnemyAttackArea and a.active and a.dodgeable:
					_perfect_dodge()
					break
		return
	if is_invincible():
		return
	for a in areas:
		if a is EnemyAttackArea and a.active:
			if take_damage(a.damage, a.cause, a.global_position.x):
				a.notify_hit(self)
			return


func _perfect_dodge() -> void:
	_dodged_this_dash = true
	_witch_cooldown = tuning.witch_time_cooldown
	_dash_iframe = maxf(_dash_iframe, 0.25)
	Fx.witch_time(tuning.witch_time_scale, tuning.witch_time_duration)
	Fx.ring(center(), 6.0, 60.0, Color(0.7, 0.55, 1.0), 0.45, 2.0, false)
	Fx.flash(Color(0.6, 0.45, 1.0, 0.3), 0.15)
	Fx.zoom_punch(tuning.zoom_punch)
	Sfx.play(&"witch_time")
	StyleRank.bonus("위치 타임!", 12.0)
	GameState.add("perfect_dodges")
	var hud := get_tree().get_first_node_in_group(&"hud")
	if hud:
		hud.banner("위치 타임!", 0.9)


## forced = 무적 시간과 상관없이 받는 피해 (폭주 자기 피해)
func take_damage(amount: int, cause: StringName, from_x: float, forced := false) -> bool:
	if state == State.DEAD:
		return false
	if not forced and is_invincible():
		return false
	if GameState.easy():
		amount = mini(amount, 1) # 초보자: 무엇이든 최대 1칸
	hp = maxi(hp - amount, 0)
	GameState.hp = hp
	GameState.add("hits_" + String(cause))
	StyleRank.on_hurt()
	hp_changed.emit(hp, max_hp())
	_hurt_iframe = tuning.hurt_invincible
	Fx.hitstop(tuning.hitstop_hurt)
	Fx.shake(tuning.shake_hurt_t)
	Fx.flash(Color(1.0, 0.1, 0.1, 0.32), 0.18)
	Sfx.play(&"hurt")
	Fx.burst(center(), 12, {
		spread = 180.0, speed_min = 40.0, speed_max = 140.0, lifetime = 0.35,
		gradient = Palette.fade_gradient(Palette.HP), size_min = 1.0, size_max = 2.5,
	})
	if hp <= 0 and Spells.learned("phoenix") and Spells.level("phoenix") >= 3 and float(ult_cooldown_left.phoenix) <= 0.0:
		# 불사조 Lv3 — 부활의 불꽃
		hp = mini(3, max_hp())
		GameState.hp = hp
		hp_changed.emit(hp, max_hp())
		_hurt_iframe = 2.0
		_cast_phoenix(true)
		Story.toast("부활의 불꽃!", 1.6)
		return false
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
		velocity = Vector2(dir * 2.0 * tuning.hurt_knockback_t * GameConst.TILE / tuning.hurt_stun, -140.0)
	return true


func _die() -> void:
	state = State.DEAD
	controls_enabled = false
	fox_time = 0.0
	_body.drinking = false
	_potion_timer = 0.0
	_overload_fuse = -1.0
	Fx.set_vignette(0.0)
	_cancel_storm()
	velocity = Vector2(-facing * 60.0, -160.0)
	GameState.add("deaths")
	died.emit()
	Fx.slowmo(0.3, 0.7)
	Fx.burst(center(), 50, {
		spread = 180.0, speed_min = 40.0, speed_max = 220.0, lifetime = 0.9, damping = 80.0,
		size_min = 1.5, size_max = 3.5, gravity = Vector2(0, -50),
	})
	var t := create_tween().set_ignore_time_scale(true)
	t.tween_property(_visual, "modulate:a", 0.0, 0.8).set_delay(0.3)


# ─── 이동 후 처리 ───────────────────────────────────────

func _after_move() -> void:
	var on_floor := is_on_floor()
	_jump_peak_y = minf(_jump_peak_y, position.y)
	if on_floor:
		_coyote_timer = tuning.coyote_time
		air_dashes_left = tuning.air_dash_count
		_air_hovers_left = tuning.air_shot_hover_count
		air_jumps_left = 2 if Spells.level("levitate") >= 3 else 1
		_glide_armed = false
		_safe_timer -= get_physics_process_delta_time()
		if _safe_timer <= 0.0 and state != State.HURT and _hazard_cool <= 0.0:
			_safe_timer = 0.25
			_safe_positions.append(global_position)
			if _safe_positions.size() > 3:
				_safe_positions.pop_front()
		if not _was_on_floor:
			_on_land()
		elif state == State.RUN and absf(velocity.x) > _max_speed * 0.6:
			_dust_timer -= get_physics_process_delta_time()
			if _dust_timer <= 0.0:
				_dust_timer = 0.09
				Fx.burst(global_position + Vector2(-facing * 3, 0), 2, {
					direction = Vector2(-facing, -1), spread = 30.0, speed_min = 15.0, speed_max = 40.0,
					lifetime = 0.3, gradient = Palette.fade_gradient(Color(Palette.GROUND_TOP, 0.7)),
					size_min = 1.0, size_max = 2.0, gravity = Vector2(0, -10),
				})
	_was_on_floor = on_floor
	# 빠르게 움직일 때 옅은 잔상 (대시 점프, 최고 속도 질주)
	if state != State.DASH and (absf(velocity.x) > _max_speed * 1.15 or _dash_jumping):
		_afterimage_timer -= get_physics_process_delta_time()
		if _afterimage_timer <= 0.0:
			_afterimage_timer = 0.05
			_spawn_afterimage(0.3)


func _on_land() -> void:
	_dash_jumping = false
	var impact := clampf(_fall_speed / _max_fall_speed, 0.0, 1.5)
	_squash_to(Vector2(1.15 + impact * 0.2, 0.85 - impact * 0.15))
	last_jump_height_t = (_jump_start_y - _jump_peak_y) / GameConst.TILE
	_jump_start_y = position.y
	_jump_peak_y = position.y
	if impact > 0.25:
		Sfx.play(&"land", -6.0 + impact * 4.0)
		Fx.burst(global_position, 4 + int(impact * 8.0), {
			direction = Vector2.UP, spread = 85.0, speed_min = 20.0, speed_max = 50.0 + impact * 50.0,
			lifetime = 0.3, gradient = Palette.fade_gradient(Palette.GROUND_TOP), size_min = 1.0, size_max = 2.0,
			gravity = Vector2(0, 80),
		})
	if impact > 1.1:
		Fx.shake(0.1, 0.12) # 빠른 낙하 착지


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
	_body.cast = clampf(_cast_pose / 0.16, 0.0, 1.0) if _cast_pose > 0.0 else 0.0
	_body.cast_kind = _cast_kind
	_body.overload_ratio = overload_ratio()
	_body.overload_fuse = _overload_fuse >= 0.0
	_body.gliding = _gliding
	_body.tails = tails()
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


func _spawn_afterimage(alpha: float) -> void:
	var ghost := PlayerVisual.new()
	ghost.copy_pose_from(_body)
	ghost.ghost = true
	ghost.ghost_color = Color(1.0, 0.45, 0.25, alpha) if not is_fox() else Color(0.4, 0.75, 1.0, alpha)
	ghost.material = Fx.add_material
	Fx.effect_parent().add_child(ghost)
	ghost.global_transform = _body.global_transform
	ghost.z_index = -1
	ghost.queue_redraw()
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.22)
	tween.tween_callback(ghost.queue_free)
