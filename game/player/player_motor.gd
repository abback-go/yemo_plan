class_name PlayerMotor
extends RefCounted
## 세라 이동 — 달리기·점프·중력·활공(불꽃 날개)·발판 내려가기·천장 모서리 보정·대시·2단 점프·착지.
## Player._physics_process가 정해진 순서로 부른다. 바깥이 읽는 값(air_dashes_left 등)은 Player에 그대로 있다.
## v0.3: 빠른 이동, 대시 점프, 최고점 체공, 빠른 낙하, 발판 내려가기, 천장 모서리 보정 (docs/archive/sera/prototype.md 14절).

var p: Player

# tuning(T 단위)에서 계산한 실제 물리 값(px 단위) — recalculate()
var max_speed := 0.0
var _accel := 0.0
var decel := 0.0
var gravity := 0.0
var jump_velocity := 0.0
var _jump_cut_velocity := 0.0
var max_fall_speed := 0.0
var _dash_speed := 0.0

# 남은 시간을 초 단위로 세는 타이머들
var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _dash_timer := 0.0
var _dash_cooldown_timer := 0.0
var dash_iframe := 0.0 ## 대시 무적 (피격 판정·퍼펙트 회피·무적 판정이 읽음)
var _since_dash := 99.0 ## 대시가 끝난 뒤 흐른 시간 (대시 점프 판정)
var dodged_this_dash := false ## 이번 대시에서 퍼펙트 회피를 했는가 (PlayerHealth가 씀)
var _afterimage_timer := 0.0
var _dust_timer := 0.0
var _drop_timer := 0.0 ## 통과 발판 내려가는 중
var _fox_trail_t := 0.0
var _ember_t := 0.0
var _safe_timer := 0.0

var air_hovers_left := 0 ## 공중 사격으로 떠 있을 수 있는 남은 횟수 (화염탄이 씀)
var _dash_dir := 1
var _dash_jumping := false
var _was_on_floor := true
var _fall_speed := 0.0
var _jump_start_y := 0.0
var _jump_peak_y := 0.0
var gliding := false ## 불꽃 날개 활공 중
var _glide_armed := false ## 공중에서 점프를 다시 눌렀는가 (활공 조건)
var _updraft_power := 0.0 ## 이번 프레임 상승 기류 세기 (updraft 개체가 넣음)
var _updraft_top := 0.0
var safe_positions: Array = [] ## 가시·불꽃에 닿으면 돌아갈 최근 안전한 땅 (최대 3)
var walk_target := INF ## 컷신 걷기 목표 x (INF = 없음)
var _walk_speed := 90.0


func _init(owner: Player) -> void:
	p = owner


## tuning 값을 픽셀 단위 물리 값으로 바꾼다.
func recalculate() -> void:
	var tu := p.tuning
	var t := GameConst.TILE
	max_speed = tu.max_speed_t * t
	_accel = max_speed / tu.accel_time
	decel = max_speed / tu.decel_time
	# 점프 공식: 높이 h를 시간 t_apex 만에 오르려면 중력 g = 2h / t², 초속 v = 2h / t
	var h_max := tu.jump_height_max_t * t
	gravity = 2.0 * h_max / pow(tu.time_to_apex, 2)
	jump_velocity = -2.0 * h_max / tu.time_to_apex
	_jump_cut_velocity = -sqrt(2.0 * gravity * tu.jump_height_min_t * t)
	max_fall_speed = tu.max_fall_speed_t * t
	_dash_speed = tu.dash_distance_t * t / tu.dash_duration


func tick(delta: float) -> void:
	_coyote_timer -= delta
	_jump_buffer_timer -= delta
	_dash_cooldown_timer -= delta
	dash_iframe -= delta
	_since_dash += delta
	if _drop_timer > 0.0:
		_drop_timer -= delta
		if _drop_timer <= 0.0:
			p.collision_mask = GameConst.L_WORLD | GameConst.L_PLATFORM


## 점프 입력을 잠깐 기억 (착지 직전에 눌러도 뛰게)
func buffer_jump() -> void:
	_jump_buffer_timer = p.tuning.jump_buffer_time


## 상승 기류 개체가 매 물리 프레임 부른다 (top_y: 기류 꼭대기, 거기서 힘이 약해짐)
func apply_updraft(power: float, top_y: float) -> void:
	_updraft_power = maxf(_updraft_power, power)
	_updraft_top = top_y


## 컷신 걷기: 목표가 있으면 입력을 대신 만든다 (도착하면 목표를 지움)
func walk_input(input_x: float) -> float:
	if walk_target != INF:
		var dx := walk_target - p.global_position.x
		if absf(dx) < 3.0:
			walk_target = INF
			p.velocity.x = 0.0
		else:
			input_x = signf(dx) * clampf(_walk_speed / max_speed, 0.2, 1.0)
	return input_x


## 컷신에서 걸어가기 (도착하면 돌아옴)
func walk_to(x: float, speed: float) -> void:
	walk_target = x
	_walk_speed = speed
	var guard := 0
	while walk_target != INF and guard < 600:
		await p.get_tree().physics_frame
		guard += 1
	walk_target = INF


## 쓰러진 뒤: 떨어지며 미끄러지다 멈춤
func process_dead(delta: float) -> void:
	p.velocity.y = minf(p.velocity.y + gravity * delta, max_fall_speed)
	p.velocity.x = move_toward(p.velocity.x, 0.0, decel * delta)
	p.move_and_slide()


## 피격·경직 중: 미끄러지며 떨어짐
func process_hurt(delta: float) -> void:
	p.velocity.x = move_toward(p.velocity.x, 0.0, decel * 0.5 * delta)
	apply_gravity(delta, false)


## 움직이고 천장 모서리를 보정한다
func move() -> void:
	_fall_speed = p.velocity.y
	var vy_before := p.velocity.y
	p.move_and_slide()
	_corner_correction(vy_before)


# ─── 달리기·점프·중력 ───────────────────────────────────

func process_run(input_x: float, delta: float) -> void:
	var tu := p.tuning
	var mult := tu.storm_move_mult if p.caster.storm_timer > 0.0 else 1.0
	var target := input_x * max_speed * mult
	if gliding:
		target = input_x * (tu.glide_speed_t + (tu.wings_lv2_glide_bonus_t if Spells.level("wings") >= 2 else 0.0)) * GameConst.TILE
	var over := absf(p.velocity.x) > max_speed and signf(p.velocity.x) == signf(input_x)
	if over:
		# 대시 점프 등으로 최고 속도를 넘었으면 관성을 살려 천천히 줄인다
		var over_decel := tu.over_speed_decel_t if p.is_on_floor() else tu.over_speed_air_decel_t
		p.velocity.x = move_toward(p.velocity.x, target, over_decel * GameConst.TILE * delta)
	else:
		var rate := _accel if input_x != 0.0 else decel
		if not p.is_on_floor() and input_x == 0.0:
			rate *= 0.35 # 공중에서 손을 떼면 미끄러지듯 관성 유지
		p.velocity.x = move_toward(p.velocity.x, target, rate * delta)


func process_jump() -> void:
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		var dash_jump := _since_dash <= p.tuning.dash_jump_window and _was_on_floor
		_do_jump(dash_jump)
	if Input.is_action_just_released("jump") and p.velocity.y < _jump_cut_velocity:
		p.velocity.y = _jump_cut_velocity


## 공중에서 점프를 누름: 코요테 시간이 지났으면 활공 준비 (불꽃 날개)
func arm_glide_if_airborne() -> void:
	if not p.is_on_floor() and _coyote_timer <= 0.0:
		_glide_armed = true


## 공중 점프(2단 점프)를 쓸 수 있는가 — 코요테 시간이 지났고, 횟수가 남았고, 배웠고, 대시 중이 아님
func can_air_jump() -> bool:
	return not p.is_on_floor() and _coyote_timer <= 0.0 and p.air_jumps_left > 0 and p.can_double_jump() and p.state != Player.State.DASH


func _do_jump(dash_jump: bool) -> void:
	p.velocity.y = jump_velocity
	_jump_start_y = p.position.y
	_jump_peak_y = p.position.y
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0
	p._squash_to(Vector2(0.75, 1.25))
	if dash_jump:
		# 대시 점프: 대시 속도를 이어받아 멀리 뛴다
		p.velocity.x = _dash_dir * p.tuning.dash_jump_speed_t * GameConst.TILE
		_dash_jumping = true
		Sfx.play(&"dash_jump", -2.0)
		Fx.ring(p.global_position + Vector2(0, -2), 2.0, 16.0, Palette.FIRE_HOT, 0.2, 1.0)
	else:
		Sfx.play(&"jump", -4.0)
	Fx.burst(p.global_position, 6, {
		direction = Vector2.UP, spread = 70.0, speed_min = 20.0, speed_max = 60.0, lifetime = 0.25,
		gradient = Palette.fade_gradient(Palette.GROUND_TOP), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 60),
	})
	if not Input.is_action_pressed("jump"):
		p.velocity.y = maxf(p.velocity.y, _jump_cut_velocity)


func double_jump() -> void:
	p.air_jumps_left -= 1
	var tu := p.tuning
	p.velocity.y = jump_velocity * tu.double_jump_mult * (tu.levitate_lv2_jump_mult if Spells.level("levitate") >= 2 else 1.0)
	_jump_start_y = p.position.y
	_jump_peak_y = p.position.y
	p._squash_to(Vector2(0.75, 1.25))
	Sfx.play(&"double_jump", -2.0)
	# 발밑 마법진
	Fx.ring(p.global_position + Vector2(0, -1), 3.0, 18.0, Color(0.75, 0.65, 1.0) if not p.is_fox() else FoxPalette.GLOW, 0.25, 1.0)
	Fx.burst(p.global_position, 10, {direction = Vector2.DOWN, spread = 60.0, speed_min = 30.0, speed_max = 90.0,
		lifetime = 0.3, gradient = Palette.fade_gradient(Color(0.8, 0.75, 1.0)), gravity = Vector2.ZERO, add = true})


func apply_gravity(delta: float, fast_fall: bool) -> void:
	if p.caster.ult_float > 0.0:
		# 고급 마법 시전: 공중에 떠서 하늘에 마력을 바침
		p.velocity.y = move_toward(p.velocity.y, -24.0, 700.0 * delta)
		p.velocity.x = move_toward(p.velocity.x, 0.0, 900.0 * delta)
		_updraft_power = 0.0
		return
	_update_glide()
	if p.is_on_floor():
		_updraft_power = 0.0
		return
	if gliding:
		_glide_physics(delta)
		_updraft_power = 0.0
		return
	_updraft_power = 0.0
	var tu := p.tuning
	var g := gravity
	var max_fall := max_fall_speed
	if p.velocity.y > 0.0:
		g *= tu.fall_gravity_multiplier
	# 최고점 근처에서 점프를 누르고 있으면 중력 절반 → 공중에서 조준할 여유
	if absf(p.velocity.y) < tu.apex_hang_speed_t * GameConst.TILE and Input.is_action_pressed("jump"):
		g *= 0.5
	if fast_fall and p.velocity.y > 0.0:
		g *= 1.4
		max_fall = tu.fast_fall_speed_t * GameConst.TILE
	p.velocity.y = minf(p.velocity.y + g * delta, max_fall)


# ─── 활공 (불꽃 날개) ───────────────────────────────────

## 불꽃 날개: 배웠고, 공중에서 점프를 다시 누르고 있으면(또는 상승 기류 안에서 누르고 있으면) 활공
func _update_glide() -> void:
	var want := Spells.learned("wings") and p.controls_enabled and not p.is_on_floor() \
		and (p.state == Player.State.JUMP or p.state == Player.State.FALL) and Input.is_action_pressed("jump") and p.caster.potion_timer <= 0.0
	if want:
		want = _updraft_power > 0.0 or (_glide_armed and p.velocity.y > -40.0)
	if want and not gliding:
		Sfx.play(&"glide", -6.0, 0.08)
	gliding = want


func _glide_physics(delta: float) -> void:
	var tu := p.tuning
	var t := GameConst.TILE
	var lv := Spells.level("wings")
	if _updraft_power > 0.0:
		var lift := tu.updraft_speed_t * t * _updraft_power * (tu.wings_lv2_updraft_mult if lv >= 2 else 1.0)
		# 기류 꼭대기 3칸 안에서는 힘이 약해져 그 높이에 머문다
		var k := clampf((p.global_position.y - _updraft_top) / (3.0 * t), 0.15, 1.0)
		p.velocity.y = move_toward(p.velocity.y, -lift * k, 1500.0 * delta)
	else:
		var fall := tu.glide_fall_speed_t * t
		if p.velocity.y < fall:
			p.velocity.y = minf(p.velocity.y + gravity * 0.5 * delta, fall)
		else:
			p.velocity.y = move_toward(p.velocity.y, fall, 1200.0 * delta)
	if lv >= 3:
		_ember_t -= delta
		if _ember_t <= 0.0:
			_ember_t = tu.ember_interval
			_drop_ember()


## 불꽃 날개 Lv3: 아래로 불씨 — 발밑 아래 ember_depth_t칸 안 적에게 피해
func _drop_ember() -> void:
	var c := p.global_position
	var tu := p.tuning
	var t := GameConst.TILE
	Fx.burst(c, 3, {direction = Vector2.DOWN, spread = 20.0, speed_min = 80.0, speed_max = 140.0, lifetime = 0.5,
		gradient = Palette.fade_gradient(Palette.FIRE_HOT), gravity = Vector2(0, 300), add = true})
	var below := func(en: EnemyBase) -> bool:
		var d := en.global_position - c
		return absf(d.x) < tu.ember_half_width_t * t and d.y > 0.0 and d.y < tu.ember_depth_t * t + en.body_size.y
	var burn := func(en: EnemyBase) -> void:
		var h := Hit.make(tu.ember_damage, &"storm", c)
		h.hitstop = 0.0
		en.take_hit(h)
	EnemyQuery.within(p.get_tree(), below, burn)


# ─── 발판·천장 ──────────────────────────────────────────

## 통과 발판(충돌 층 L_PLATFORM) 위에 서 있는가: 연습 방의 Block, 1장 방의 발판, 숨은 발판, 벽에 박힌 빗자루 모두
func standing_on_platform() -> bool:
	for i in p.get_slide_collision_count():
		var c := p.get_slide_collision(i)
		var body := c.get_collider() as CollisionObject2D
		if c.get_normal().y < -0.7 and body and (body.collision_layer & GameConst.L_PLATFORM) != 0:
			return true
	return false


func drop_through() -> void:
	p.collision_mask = GameConst.L_WORLD
	_drop_timer = 0.22
	p.position.y += 2.0
	p.velocity.y = maxf(p.velocity.y, 60.0)


## 점프하다 천장 모서리에 머리가 살짝 걸리면 옆으로 밀어 주어 계속 오르게 한다
func _corner_correction(vy_before: float) -> void:
	if vy_before >= 0.0 or not p.is_on_ceiling():
		return
	for d in range(1, p.tuning.corner_correction_px + 1):
		for s in [-1, 1]:
			var shifted := p.global_transform.translated(Vector2(s * d, 0))
			if not p.test_move(shifted, Vector2(0, -3)):
				p.position.x += s * d
				p.velocity.y = vy_before
				return


# ─── 대시 ───────────────────────────────────────────────

func can_dash() -> bool:
	if p.state == Player.State.DASH or _dash_cooldown_timer > 0.0:
		return false
	return p.is_on_floor() or p.air_dashes_left > 0


func start_dash(input_x: float) -> void:
	if not p.is_on_floor():
		p.air_dashes_left -= 1
	if input_x != 0.0:
		_dash_dir = 1 if input_x > 0.0 else -1
	else:
		_dash_dir = p.facing
	p.facing = _dash_dir
	_dash_timer = p.tuning.dash_duration
	dash_iframe = p.tuning.dash_invincible_time
	_afterimage_timer = 0.0
	dodged_this_dash = false
	_dash_jumping = false
	p.caster.cancel_storm()
	p.state = Player.State.DASH
	GameState.add("dashes")
	Sfx.play(&"dash")
	Fx.burst(p.global_position + Vector2(-_dash_dir * 4, -8), 8, {
		direction = Vector2(-_dash_dir, 0), spread = 25.0, speed_min = 60.0, speed_max = 160.0, lifetime = 0.25,
		size_min = 1.0, size_max = 2.0, gravity = Vector2.ZERO,
	})


func process_dash(delta: float) -> void:
	_dash_timer -= delta
	# 땅 대시 중 점프 → 대시 점프
	if _jump_buffer_timer > 0.0 and p.is_on_floor():
		end_dash()
		_do_jump(true)
		return
	if _dash_timer <= 0.0:
		end_dash()
		return
	p.velocity = Vector2(_dash_dir * _dash_speed, 0.0)
	if p.is_fox():
		_fox_trail_t -= delta
		if _fox_trail_t <= 0.0:
			_fox_trail_t = 0.035
			var tr := FoxTrail.new()
			tr.global_position = p.global_position + Vector2(0, -10)
			Fx.effect_parent().add_child(tr)
	_afterimage_timer -= delta
	if _afterimage_timer <= 0.0:
		p._spawn_afterimage(0.6)
		_afterimage_timer = p.tuning.dash_duration / 4.0


func end_dash() -> void:
	p.state = Player.State.FALL
	_dash_cooldown_timer = p.tuning.dash_cooldown
	_since_dash = 0.0
	p.velocity.x = _dash_dir * max_speed


# ─── 이동 후 처리 ───────────────────────────────────────

func after_move() -> void:
	var tu := p.tuning
	var on_floor := p.is_on_floor()
	_jump_peak_y = minf(_jump_peak_y, p.position.y)
	if on_floor:
		_coyote_timer = tu.coyote_time
		p.air_dashes_left = tu.air_dash_count
		air_hovers_left = tu.air_shot_hover_count
		p.air_jumps_left = tu.levitate_lv3_air_jumps if Spells.level("levitate") >= 3 else 1
		_glide_armed = false
		_safe_timer -= p.get_physics_process_delta_time()
		if _safe_timer <= 0.0 and p.state != Player.State.HURT and p.health.hazard_cool <= 0.0:
			_safe_timer = 0.25
			safe_positions.append(p.global_position)
			if safe_positions.size() > 3:
				safe_positions.pop_front()
		if not _was_on_floor:
			_on_land()
		elif p.state == Player.State.RUN and absf(p.velocity.x) > max_speed * 0.6:
			_dust_timer -= p.get_physics_process_delta_time()
			if _dust_timer <= 0.0:
				_dust_timer = 0.09
				Fx.burst(p.global_position + Vector2(-p.facing * 3, 0), 2, {
					direction = Vector2(-p.facing, -1), spread = 30.0, speed_min = 15.0, speed_max = 40.0,
					lifetime = 0.3, gradient = Palette.fade_gradient(Color(Palette.GROUND_TOP, 0.7)),
					size_min = 1.0, size_max = 2.0, gravity = Vector2(0, -10),
				})
	_was_on_floor = on_floor
	# 빠르게 움직일 때 옅은 잔상 (대시 점프, 최고 속도 질주)
	if p.state != Player.State.DASH and (absf(p.velocity.x) > max_speed * 1.15 or _dash_jumping):
		_afterimage_timer -= p.get_physics_process_delta_time()
		if _afterimage_timer <= 0.0:
			_afterimage_timer = 0.05
			p._spawn_afterimage(0.3)


func _on_land() -> void:
	_dash_jumping = false
	var impact := clampf(_fall_speed / max_fall_speed, 0.0, 1.5)
	p._squash_to(Vector2(1.15 + impact * 0.2, 0.85 - impact * 0.15))
	p.last_jump_height_t = (_jump_start_y - _jump_peak_y) / GameConst.TILE
	_jump_start_y = p.position.y
	_jump_peak_y = p.position.y
	if impact > 0.25:
		Sfx.play(&"land", -6.0 + impact * 4.0)
		Fx.burst(p.global_position, 4 + int(impact * 8.0), {
			direction = Vector2.UP, spread = 85.0, speed_min = 20.0, speed_max = 50.0 + impact * 50.0,
			lifetime = 0.3, gradient = Palette.fade_gradient(Palette.GROUND_TOP), size_min = 1.0, size_max = 2.0,
			gravity = Vector2(0, 80),
		})
	if impact > 1.1:
		Fx.shake(0.1, 0.12) # 빠른 낙하 착지
