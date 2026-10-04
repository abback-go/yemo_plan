class_name Player
extends CharacterBody2D
## 세라 — 이동·점프·대시 + 화염탄(묵직한 한 발), 마법, 폭주 게이지·여우 모드, 체력·피격·사망.
## 이 파일은 겉(파사드)이다: 바깥(대본·HUD·적·시험 실행기)은 여기 있는 공개 이름만 쓴다(참조 약 185곳).
## 실제 동작은 컴포넌트 4개가 나눠 맡고, _physics_process가 정해진 순서로 부른다 (docs/dev/player.md).
##   motor  PlayerMotor  이동·점프·대시·활공·발판·착지      (player_motor.gd)
##   caster PlayerCaster 화염탄·마법·물약·여우창문·재사용 대기 (player_caster.gd)
##   gauge  PlayerGauge  폭주 게이지·과열·여우 모드           (player_gauge.gd)
##   health PlayerHealth 체력·피격·퍼펙트 회피·사망·부활      (player_health.gd)
## 원점(0, 0)은 발밑. 수치는 전부 core/tuning.tres, 전투 중 문구는 player_text.gd.

signal hp_changed(hp: int, max_hp: int)
signal died

enum State { IDLE, RUN, JUMP, FALL, DASH, HURT, STUN, DEAD }

## 상태 → 그림 자세 (두 enum의 순서에 기대지 않게 짝을 적어 둔다)
const POSE_OF := {
	State.IDLE: PlayerVisual.Pose.IDLE,
	State.RUN: PlayerVisual.Pose.RUN,
	State.JUMP: PlayerVisual.Pose.JUMP,
	State.FALL: PlayerVisual.Pose.FALL,
	State.DASH: PlayerVisual.Pose.DASH,
	State.HURT: PlayerVisual.Pose.HURT,
	State.STUN: PlayerVisual.Pose.STUN,
	State.DEAD: PlayerVisual.Pose.DEAD,
}

const TUNING: Tuning = preload("res://core/tuning.tres")
const HAND := Vector2(11, -19) ## 화염탄이 나가는 손 위치 (오른쪽을 볼 때)

var tuning: Tuning = TUNING
var state: State = State.IDLE
var facing := 1 ## 1 = 오른쪽, -1 = 왼쪽
var hp := 5
var overload := 0.0 ## 폭주 게이지 0~100
var air_dashes_left := 0
var air_jumps_left := 0
var controls_enabled := true
var fox_time := 0.0 ## 여우 모드(빙의) 남은 시간
var fox_energy := 1.0 ## 너울의 기운 0~1. 가득 차 있어야 폭주가 여우 모드로 바뀜 (docs/chapter1.md 12.4절)
var no_overload := false ## 봉인 결계 안: 폭주 게이지가 오르지 않음
var last_jump_height_t := 0.0 ## 직전 점프의 실제 높이 (T). 디버그 표시용

## 재사용 대기 남은 시간 — 옛 이름 (HUD·시험 실행기가 읽음). 값은 caster.cooldowns 한 곳에.
var pillar_cooldown_left: float:
	get: return caster.cooldowns.pillar
	set(v): caster.cooldowns.pillar = v
var storm_cooldown_left: float:
	get: return caster.cooldowns.storm
	set(v): caster.cooldowns.storm = v
var ward_cooldown_left: float:
	get: return caster.cooldowns.ward
	set(v): caster.cooldowns.ward = v

# 바깥이 문자열 set("…")으로 직접 쓰는 이름 — 바꾸면 오류 없이 동작만 사라진다 (docs/dev/player.md 함정).
# 새 코드는 grant_iframes·set_iframes·stun을 쓴다.
var _hurt_iframe := 0.0 ## 피격 뒤 무적 남은 시간 (시험 godmode·scripts_ch5·sky_gate·ally)
var _stun_timer := 0.0 ## 경직 남은 시간 (gladiator)
var _ward_time := 0.0 ## 불꽃 방벽 남은 시간 = 무적 (시나리오 ch4_full·ch4_mirrors)

var motor: PlayerMotor
var caster: PlayerCaster
var gauge: PlayerGauge
var health: PlayerHealth

var _emote_node: EmoteBubble
var _squash: Tween

@onready var _visual: Node2D = $Visual
@onready var _flip: Node2D = $Visual/Flip
@onready var _body: PlayerVisual = $Visual/Flip/Body
@onready var _hurtbox: Area2D = $Hurtbox
@onready var camera: GameCamera = $Camera2D


func _init() -> void:
	motor = PlayerMotor.new(self)
	caster = PlayerCaster.new(self)
	gauge = PlayerGauge.new(self)
	health = PlayerHealth.new(self)


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
	motor.recalculate()


# ─── 공개 API: 상태 묻기 ────────────────────────────────

func is_alive() -> bool:
	return state != State.DEAD


func is_invincible() -> bool:
	return motor.dash_iframe > 0.0 or _hurt_iframe > 0.0 or _ward_time > 0.0 or caster.ult_float > 0.0 or state == State.DEAD


## 불꽃 방벽을 두르고 있는가 (빛줄기·별 수정 장치가 읽음)
func is_warding() -> bool:
	return _ward_time > 0.0


func ward_center() -> Vector2:
	return global_position + Vector2(0, -16)


## 불꽃 날개로 활공 중인가
func is_gliding() -> bool:
	return motor.gliding


## 상승 기류 개체가 매 물리 프레임 부른다 (top_y: 기류 꼭대기, 거기서 힘이 약해짐)
func apply_updraft(power: float, top_y: float) -> void:
	motor.apply_updraft(power, top_y)


## 너울의 꼬리 수 (장 진행) — 여우 모드 시간·기운 회복이 달라진다
func tails() -> int:
	return clampi(int(GameState.flag("tails", 1)), 1, 9)


func fox_duration() -> float:
	return gauge.fox_duration()


func fox_recharge() -> float:
	return gauge.fox_recharge()


## 마법 재사용 대기 [남은 시간, 전체] (HUD·터치 버튼이 읽음)
func spell_cooldown(id: String) -> Vector2:
	return caster.spell_cooldown(id)


func overload_ratio() -> float:
	return overload / tuning.overload_max


func overload_fusing() -> bool:
	return gauge.fuse >= 0.0


## 폭주 게이지 70% 이상: 화염탄이 강해지는 과열 상태 (위험을 감수한 보상)
func is_overheated() -> bool:
	return gauge.overheated()


func center() -> Vector2:
	return global_position + Vector2(0, -16)


func max_hp() -> int:
	return GameState.max_hp


func is_fox() -> bool:
	return fox_time > 0.0


func can_double_jump() -> bool:
	return GameState.has_ability("double_jump") or GameState.has_flag("temp_double_jump")


# ─── 공개 API: 바꾸기 (대본·적·시험이 부름) ─────────────

## 체력 회복 (불사조 등)
func heal(n: int) -> void:
	if state == State.DEAD:
		return
	health.set_hp(mini(hp + n, max_hp()))


func heal_full() -> void:
	if hp < max_hp():
		health.set_hp(max_hp())


## 체력을 정하고 GameState·HUD에 알린다 (대본이 hp를 직접 쓰면 GameState·HUD에 반영되지 않음)
func set_hp(v: int) -> void:
	health.set_hp(v)


## GameState의 체력을 세라에게 반영 (방 이동·기록·부활 후). GameState에는 다시 쓰지 않는다.
func restore_from_state() -> void:
	hp = clampi(GameState.hp, 1, max_hp())
	hp_changed.emit(hp, max_hp())


## 피격 무적을 최소 t초로 (이미 더 길면 그대로)
func grant_iframes(t: float) -> void:
	_hurt_iframe = maxf(_hurt_iframe, t)


## 피격 무적을 정확히 t초로 (줄일 수도 있음 — 컷신 뒤 되돌리기, 시험 godmode)
func set_iframes(t: float) -> void:
	_hurt_iframe = t


## t초 경직 (그물·폭주 폭발). 끝나면 FALL
func stun(t: float) -> void:
	state = State.STUN
	_stun_timer = t


## 마법 재사용 대기를 정함 (id: pillar·storm·ward·meteor·phoenix)
func set_cooldown(id: String, t: float) -> void:
	caster.cooldowns[id] = t


## 불꽃 방벽 무적 시간을 정함 (방벽 그림 없이 — 시험·대본용)
func set_ward_time(t: float) -> void:
	_ward_time = t


## 방에 들어갈 때 등장 위치로
func place_at(pos: Vector2, face: int) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	facing = face if face != 0 else facing
	if state == State.DASH:
		motor.end_dash()
	if state != State.DEAD:
		state = State.IDLE
	motor.safe_positions.clear()
	motor.walk_target = INF
	caster.cancel_storm()
	camera.reset_smoothing()


## 컷신 시작: 멈춰 세움
func halt() -> void:
	velocity.x = 0.0
	if state == State.DASH:
		motor.end_dash()
		velocity.x = 0.0
	caster.cancel_storm()
	caster.stop_potion()


func revive() -> void:
	state = State.IDLE
	controls_enabled = true
	overload = 0.0
	gauge.fuse = -1.0
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
			if Input.is_action_pressed("move_down") and is_on_floor() and motor.standing_on_platform():
				motor.drop_through()
			else:
				motor.buffer_jump()
		"attack":
			caster.buffer_attack()
		"dash":
			if motor.can_dash():
				motor.start_dash(0.0)
		"skill_1":
			cast_slot("a")
		"skill_2":
			cast_slot("s")
		"skill_3":
			cast_slot("f")
		"fox_window":
			caster.open_window()


## 컷신에서 걸어가기 (도착하면 돌아옴)
func walk_to(x: float, speed := 90.0) -> void:
	await motor.walk_to(x, speed)


func emote(kind: String, time := 1.2) -> void:
	_emote_node.show_emote(kind, time)


## 가시·불꽃: 1 피해 + 직전 안전한 땅으로
func hazard_hit() -> void:
	health.hazard_hit()


## 적에게 공격이 맞았을 때 EnemyBase가 알려 준다
func on_hit_landed(_hit: Hit) -> void:
	if tuning.hit_refreshes_air_dash and not is_on_floor():
		air_dashes_left = maxi(air_dashes_left, tuning.air_dash_count)


## 장착 칸(a·s·f)의 마법을 쓴다
func cast_slot(slot: String) -> void:
	caster.cast_slot(slot)


## 불꽃 방벽을 재사용 대기와 상관없이 바로 시전 (대본)
func cast_ward() -> void:
	caster.cast_ward()


## 옛 이름 — scripts_ch2.gd가 call("_cast_ward")로 부른다
func _cast_ward() -> void:
	caster.cast_ward()


## 대본에서 폭주 게이지를 강제로 채움 (P4 폭주 폭발, P7 첫 빙의)
func force_overload_full() -> void:
	gauge.force_full()


func start_fox_mode() -> void:
	gauge.start_fox_mode()


## forced = 무적 시간과 상관없이 받는 피해 (폭주 자기 피해). 피해를 입었으면 true
func take_damage(amount: int, cause: StringName, from_x: float, forced := false) -> bool:
	return health.take_damage(amount, cause, from_x, forced)


# ─── 매 프레임 ──────────────────────────────────────────
# 순서가 곧 동작이다(입력 → 상태별 이동 → 충돌 이동 → 착지 → 상태 → 피격 → 게이지 → 그림). 바꾸지 말 것.

func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	if state == State.DEAD:
		motor.process_dead(delta)
		_update_visual(delta)
		return

	var input_x := Input.get_axis("move_left", "move_right") if controls_enabled else 0.0
	var down := controls_enabled and Input.is_action_pressed("move_down")
	input_x = motor.walk_input(input_x)
	if caster.potion_timer > 0.0:
		input_x *= 0.3
	if _can_act():
		_read_action_input(input_x, down)

	match state:
		State.DASH:
			motor.process_dash(delta)
		State.HURT, State.STUN:
			motor.process_hurt(delta)
		_:
			if input_x != 0.0 and caster.storm_timer <= 0.0:
				facing = 1 if input_x > 0.0 else -1
			motor.process_run(input_x, delta)
			motor.process_jump()
			motor.apply_gravity(delta, down)

	motor.move()
	motor.after_move()
	_update_state()
	health.check_hurtbox()
	gauge.update(delta)
	_update_visual(delta)


## 타이머 감소. 물약이 끝나면 회복(caster), 피격·경직이 끝나면 FALL(health)
func _tick_timers(delta: float) -> void:
	motor.tick(delta)
	caster.tick(delta)
	gauge.tick(delta)
	health.tick(delta)


func _can_act() -> bool:
	return controls_enabled and state != State.HURT and state != State.STUN and state != State.DEAD and caster.ult_float <= 0.0


func _read_action_input(input_x: float, down: bool) -> void:
	if Input.is_action_just_pressed("jump"):
		motor.arm_glide_if_airborne() # 불꽃 날개: 공중에서 다시 누르고 있으면 활공
		if down and is_on_floor() and motor.standing_on_platform():
			motor.drop_through()
		elif motor.can_air_jump():
			motor.double_jump()
		else:
			motor.buffer_jump()
	if Input.is_action_just_pressed("potion"):
		caster.drink_potion()
	if Input.is_action_just_pressed("fox_window"):
		caster.open_window()
	if Input.is_action_just_pressed("dash") and motor.can_dash():
		motor.start_dash(input_x)
	# 대시 중에도 화염탄·불기둥은 쏠 수 있다 (화염 폭풍은 자세를 잡아야 하므로 대시를 끊고 시전)
	if Input.is_action_just_pressed("attack"):
		caster.buffer_attack()
	caster.try_fire(Input.is_action_pressed("attack"))
	if Input.is_action_just_pressed("skill_1"):
		cast_slot("a")
	if Input.is_action_just_pressed("skill_2"):
		cast_slot("s")
	if Input.is_action_just_pressed("skill_3"):
		cast_slot("f")


func _update_state() -> void:
	if state == State.DASH or state == State.HURT or state == State.STUN or state == State.DEAD:
		return
	if is_on_floor():
		state = State.RUN if absf(velocity.x) > 1.0 else State.IDLE
	else:
		state = State.JUMP if velocity.y < 0.0 else State.FALL


# ─── 연출 (컴포넌트도 부른다) ───────────────────────────

func _update_visual(delta: float) -> void:
	_flip.scale.x = facing
	_body.pose = POSE_OF[state]
	_body.speed_x = velocity.x * facing
	_body.speed_y = velocity.y
	_body.cast = clampf(caster.cast_pose / 0.16, 0.0, 1.0) if caster.cast_pose > 0.0 else 0.0
	_body.cast_kind = caster.cast_kind
	_body.overload_ratio = overload_ratio()
	_body.overload_fuse = gauge.fuse >= 0.0
	_body.gliding = motor.gliding
	_body.tails = tails()
	_body.update_pose(delta)
	if state == State.DEAD:
		return
	# 무적: 대시 중엔 밝게, 피격 후엔 깜빡임, 폭주 직전엔 떨림
	if motor.dash_iframe > 0.0:
		_visual.modulate = Color(1.7, 1.5, 1.4)
		_visual.position.x = 0.0
	elif _hurt_iframe > 0.0:
		var blink := int(_hurt_iframe * 20.0) % 2 == 0
		_visual.modulate = Color(1, 1, 1, 0.35 if blink else 1.0)
		_visual.position.x = 0.0
	elif gauge.fuse >= 0.0:
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
	ghost.ghost_color = Color(1.0, 0.45, 0.25, alpha) if not is_fox() else Color(FoxPalette.GHOST, alpha)
	ghost.material = Fx.add_material
	Fx.effect_parent().add_child(ghost)
	ghost.global_transform = _body.global_transform
	ghost.z_index = -1
	ghost.queue_redraw()
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.22)
	tween.tween_callback(ghost.queue_free)


## HUD 배너 (HUD가 없으면 무시)
func _banner(text: String, time: float) -> void:
	var hud := get_tree().get_first_node_in_group(&"hud")
	if hud:
		hud.banner(text, time)
