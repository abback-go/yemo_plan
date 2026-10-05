class_name PSera
extends CharacterBody2D
## 훈련장 세라 (새 조작 시제품). 결정 기록: docs/design/controls_skills.md
## 상태 하나(st)로 나눈다: 보통(달리기·점프·벽·활공·기본공격 던지기), 대시, 의태 돌진, 시전 잠김, 압축(열선),
## 마시기, 피격, 쓰러짐. 기본공격은 둘레를 도는 불덩이 셋(orbs)을 하나씩 던진다(PShot). 체력은 반 칸 단위(hp2)라 쉬움 난이도의 "받는 피해 절반"을 그대로 표현한다.

enum St { NORMAL, DASH, MIMIC, CAST, CHARGE, DRINK, HURT, DEAD, SHIELD }

const GROUP := &"p_sera"
const SIZE := Vector2(10, 32)


var st := St.NORMAL
var st_t := 0.0 ## 지금 상태에 들어온 뒤 시간
var facing := 1
var art: SeraArt
var _flip: Node2D

# 자원
var hp2 := PData.MAX_HEARTS * 2 ## 반 칸 단위
var gauge := 0.0 ## 폭주 게이지 0~1 (가득 = Space로 변신)
var fox_time := 0.0 ## 변신 남은 시간
var potions := 2
var potions_max := 2
var revive := 0 ## 불사조 부활 (최대 1)
var cooldowns := {} ## 마법 ID → 남은 시간

# 이동
var _coyote := 0.0
var _jump_buf := 0.0
var _jump_hold := 0.0
var _air_jumps := 1
var _air_dash := true
var _dash_cd := 0.0
var _dash_dir := 1
var _wall_dir := 0 ## 붙어 있는 벽 방향 (-1 왼쪽 / 1 오른쪽)
var _wall_lock := 0.0
var _gliding := false
var _glide_ready := false ## 2단 점프를 쓴 뒤 다시 누르면 활공
var _was_floor := true
var _run_dust := 0.0
var _mimic_hit := {}
var _fall_speed := 0.0
var _ray := PhysicsRayQueryParameters2D.new()

# 전투
var orbs := 3 ## 둘레를 도는 불덩이 수 (0이 되면 잠깐 뒤 다시 3)
var _orb_refill := 0.0
var _atk_cd := 0.0
var _atk_buf := 0.0
var _atk_aim := 0
var _recoil := 0.0
var _shield_t := 0.0
var shield_cd := 0.0
var _iframe := 0.0
var _cast_lock := 0.0
var _cast_invuln := false
var _mote_t := 0.0
var charge_t := 0.0 ## 열선 압축 시간
var _hurt_t := 0.0
var _respawn := Vector2.ZERO
var _shield_fx: Node2D


static func find(tree: SceneTree) -> PSera:
	return tree.get_first_node_in_group(GROUP) as PSera


func _ready() -> void:
	add_to_group(GROUP)
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 4.0
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = SIZE
	cs.shape = rs
	cs.position = Vector2(0, -SIZE.y / 2)
	add_child(cs)
	_flip = Node2D.new()
	add_child(_flip)
	art = SeraArt.new()
	_flip.add_child(art)
	_respawn = global_position
	_spawn_orbits.call_deferred() # 장면이 다 붙은 뒤 효과 층에


## 둘레를 도는 불덩이 그림 (몸 뒤 층 + 앞 층)
func _spawn_orbits() -> void:
	for f in [false, true]:
		var o := PShot.Orbit.new()
		o.sera = self
		o.front = f
		PVfx.add(o, global_position)


func center() -> Vector2:
	return global_position + Vector2(0, -18)


func hurt_rect() -> Rect2:
	return Rect2(global_position + Vector2(-5, -31), Vector2(10, 30))


func hearts() -> float:
	return float(hp2) / 2.0


func is_fox() -> bool:
	return fox_time > 0.0


## 폭주 봉인 중인가 (게이지 가득 + 아직 변신 안 함 → 마법 사용 불가, 기본공격·대시·이동은 됨)
func overloaded() -> bool:
	return gauge >= 1.0 and not is_fox()


func invulnerable() -> bool:
	return _iframe > 0.0 or _shield_t > 0.0 or st == St.DEAD or _cast_invuln \
		or (st == St.DASH and PState.evade) or st == St.MIMIC


func set_respawn(p: Vector2) -> void:
	_respawn = p


# ═══════════════════════════════════════════════════════════
# 매 프레임
# ═══════════════════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	st_t += delta
	_timers(delta)
	match st:
		St.NORMAL:
			_normal(delta)
		St.DASH:
			_dash(delta)
		St.MIMIC:
			_mimic(delta)
		St.CAST:
			_cast(delta)
		St.CHARGE:
			_charge(delta)
		St.DRINK:
			_drink(delta)
		St.HURT:
			_hurt(delta)
		St.SHIELD:
			_shield(delta)
		St.DEAD:
			velocity = Vector2.ZERO
	var was := is_on_floor()
	_fall_speed = maxf(velocity.y, 0.0)
	move_and_slide()
	if is_on_floor() and not _was_floor and st != St.DEAD:
		_land()
	_was_floor = is_on_floor()
	if was or is_on_floor():
		_air_dash = true
	_animate(delta)


func _timers(delta: float) -> void:
	_dash_cd = maxf(_dash_cd - delta, 0.0)
	_atk_cd = maxf(_atk_cd - delta, 0.0)
	_atk_buf = maxf(_atk_buf - delta, 0.0)
	if orbs <= 0:
		_orb_refill -= delta
		if _orb_refill <= 0.0:
			_refill_orbs()
	_recoil = maxf(_recoil - delta, 0.0)
	_iframe = maxf(_iframe - delta, 0.0)
	_jump_buf = maxf(_jump_buf - delta, 0.0)
	_wall_lock = maxf(_wall_lock - delta, 0.0)
	shield_cd = maxf(shield_cd - delta, 0.0)
	if _shield_t > 0.0:
		_shield_t -= delta
	for id: String in cooldowns.keys():
		cooldowns[id] = maxf(float(cooldowns[id]) - delta, 0.0)
	if PState.no_cooldown:
		cooldowns.clear()
	if fox_time > 0.0:
		fox_time -= delta
		if fox_time <= 0.0:
			_end_transform()
	# 입력: 버퍼
	if Input.is_action_just_pressed("pr_jump"):
		_jump_buf = PData.JUMP_BUFFER


func _axis() -> int:
	return int(Input.is_action_pressed("pr_right")) - int(Input.is_action_pressed("pr_left"))


func _run_speed() -> float:
	return PData.RUN_SPEED * (1.15 if is_fox() else 1.0)


# ─── 보통 상태 ──────────────────────────────────────────

func _normal(delta: float) -> void:
	var ax := _axis()
	var on_floor := is_on_floor()
	if on_floor:
		_coyote = PData.COYOTE
		_air_jumps = 1
		_glide_ready = false
		_gliding = false
	else:
		_coyote = maxf(_coyote - delta, 0.0)
	# 좌우
	if ax != 0 and _wall_lock <= 0.0 and _recoil <= 0.0:
		facing = ax
	var target := float(ax) * _run_speed()
	if _wall_lock > 0.0:
		target = velocity.x
	var acc := PData.RUN_ACCEL if on_floor else PData.AIR_ACCEL
	if ax == 0 and on_floor:
		acc = PData.RUN_DECEL
	if _recoil > 0.0:
		pass # 큰 덩이를 던진 반동 중에는 밀려난 속도를 유지
	else:
		velocity.x = move_toward(velocity.x, target, acc * delta)
	# 벽
	_wall_dir = 0
	if not on_floor and is_on_wall() and velocity.y > -20.0:
		var n := get_wall_normal()
		var wd := -int(signf(n.x))
		if wd != 0 and ax == wd:
			_wall_dir = wd
	# 점프
	if _jump_buf > 0.0:
		if on_floor or _coyote > 0.0:
			_do_jump(PData.JUMP_SPEED)
		elif _wall_dir != 0:
			_wall_jump()
		elif _air_jumps > 0:
			_air_jumps -= 1
			_do_jump(PData.DOUBLE_JUMP_SPEED)
			_glide_ready = true
			var ring := PVfx.AirRing.new()
			ring.fox = is_fox()
			PVfx.add(ring, global_position + Vector2(0, -2), true)
			Sfx.play(&"double_jump", -4.0)
		elif _glide_ready or not on_floor:
			_gliding = true
			_jump_buf = 0.0
			Sfx.play(&"glide", -6.0)
	if not Input.is_action_pressed("pr_jump"):
		_gliding = false
		if _jump_hold > 0.0 and velocity.y < 0.0:
			velocity.y *= PData.JUMP_CUT
		_jump_hold = 0.0
	# 중력
	var g := PData.GRAVITY
	if _jump_hold > 0.0:
		_jump_hold -= delta
		g *= PData.JUMP_HOLD_GRAVITY
	elif absf(velocity.y) < 60.0 and not on_floor:
		g *= PData.APEX_HANG
	velocity.y += g * delta
	var fall_max := PData.FALL_MAX
	if Input.is_action_pressed("pr_down") and not on_floor:
		fall_max = PData.FAST_FALL_MAX
	if _wall_dir != 0:
		fall_max = PData.WALL_SLIDE
		if randf() < 0.25:
			PVfx.dust(global_position + Vector2(_wall_dir * 5, -18), 1, 0.3, 4.0)
	if _gliding and velocity.y > 0.0:
		fall_max = PData.GLIDE_FALL
		velocity.x = move_toward(velocity.x, float(facing) * PData.GLIDE_SPEED, PData.AIR_ACCEL * delta)
	velocity.y = minf(velocity.y, fall_max)
	# 달리기 먼지
	if on_floor and absf(velocity.x) > 100.0:
		_run_dust -= delta
		if _run_dust <= 0.0:
			_run_dust = 0.16
			PVfx.dust(global_position + Vector2(-facing * 4, 0), 1, 0.5, 8.0)
	_actions(on_floor)


## 보통 상태에서 받는 행동 입력 (대시·기본공격·변신·물약·마법)
func _actions(on_floor: bool) -> void:
	if Input.is_action_just_pressed("pr_dash") and _dash_cd <= 0.0 and (on_floor or (PState.evade and _air_dash)):
		if is_fox():
			_start_mimic() # 변신 중 대시 = 의태 돌진
		else:
			_start_dash()
		return
	if Input.is_action_just_pressed("pr_attack"):
		_atk_buf = 0.15 # 쿨이 막 끝나기 전에(또는 다시 피어나는 중에) 눌러도 이어지게
	if _atk_buf > 0.0 and _atk_cd <= 0.0 and orbs > 0:
		_atk_buf = 0.0
		_throw()
	if Input.is_action_just_pressed("pr_transform") and gauge >= 1.0 and not is_fox():
		_start_transform()
	if Input.is_action_just_pressed("pr_potion") and potions > 0 and hp2 < PData.MAX_HEARTS * 2 and on_floor:
		_go(St.DRINK)
		velocity.x = 0.0
		Sfx.play(&"potion", -6.0)
		return
	var spell := PState.spell_pressed()
	if spell != "":
		PSpells.try_cast(self, spell)
		return


func _go(s: St) -> void:
	st = s
	st_t = 0.0


func _do_jump(speed: float) -> void:
	velocity.y = -speed
	_jump_buf = 0.0
	_coyote = 0.0
	_jump_hold = PData.JUMP_HOLD_TIME
	_gliding = false
	if is_on_floor():
		PVfx.dust(global_position, 4, 0.8, 14.0)
	Sfx.play(&"jump", -8.0)


func _wall_jump() -> void:
	velocity = Vector2(-_wall_dir * PData.WALL_JUMP_X, -PData.WALL_JUMP_Y)
	facing = -_wall_dir
	_wall_lock = PData.WALL_JUMP_LOCK
	_jump_buf = 0.0
	_jump_hold = PData.JUMP_HOLD_TIME * 0.6
	_air_jumps = 1
	_air_dash = true
	PVfx.dust(global_position + Vector2(_wall_dir * 5, -14), 4, 0.4, 10.0)
	if is_fox(): # 여우 발자국은 변신 중에만 (평소엔 순수한 불 마법사)
		var paw := PVfx.FoxPaw.new()
		paw.dir = -_wall_dir
		paw.size = 0.7
		PVfx.add(paw, global_position + Vector2(_wall_dir * 6, -14), true)
	else:
		PVfx.embers(global_position + Vector2(_wall_dir * 6, -14), 4, false, 50.0, Vector2(2, 6))
	Sfx.play(&"jump", -6.0)
	_wall_dir = 0


func _land() -> void:
	art.land_k = clampf(_fall_speed / 330.0, 0.35, 1.0)
	PVfx.dust(global_position, 5, 1.0, 10.0)
	Sfx.play(&"land", -10.0)


# ─── 대시 (흰 가시 다발 + 여우 발자국) ─────────────────

func _start_dash() -> void:
	_go(St.DASH)
	_dash_dir = facing if _axis() == 0 else _axis()
	facing = _dash_dir
	_dash_cd = PData.DASH_COOLDOWN
	if not is_on_floor():
		_air_dash = false
	_gliding = false
	var burst := PVfx.DashBurst.new()
	burst.dir = _dash_dir
	burst.fox = is_fox()
	PVfx.add(burst, global_position + Vector2(-_dash_dir * 4, -14))
	PVfx.sparks(global_position + Vector2(-_dash_dir * 6, -6), 6, PData.FIRE_HOT, 120.0, 0.25, Vector2(-_dash_dir, -0.2), 30.0)
	Sfx.play(&"dash", -4.0)
	Fx.shake(0.05, 0.08)


func _dash(_delta: float) -> void:
	var dur := PData.DASH_TIME * (1.2 if is_fox() else 1.0)
	velocity = Vector2(_dash_dir * PData.DASH_SPEED, 0.0)
	PVfx.speed_line(global_position + Vector2(-_dash_dir * 4, randf_range(-24, -6)), _dash_dir, is_fox())
	if st_t >= dur:
		_go(St.NORMAL)
		velocity.x = _dash_dir * _run_speed()


# ─── 의태 돌진 = 변신 중 대시 (거대한 여우 정령이 감싸고 뛰어듦: 적·탄 관통, 피해, 무적) ───

func _start_mimic() -> void:
	_go(St.MIMIC)
	_dash_dir = facing if _axis() == 0 else _axis()
	facing = _dash_dir
	_dash_cd = PData.DASH_COOLDOWN
	if not is_on_floor():
		_air_dash = false
	_gliding = false
	_mimic_hit.clear()
	var sp := PVfx.SpiritDash.new()
	sp.dir = _dash_dir
	sp.follow = self
	PVfx.add(sp, global_position, true)
	var paw := PVfx.FoxPaw.new()
	paw.dir = _dash_dir
	paw.size = 1.6
	PVfx.add(paw, global_position + Vector2(-_dash_dir * 6, -6), true)
	PVfx.sparks(global_position + Vector2(0, -18), 18, PData.FOX_HOT, 160.0, 0.4)
	Sfx.play(&"dash", -2.0)
	Sfx.play(&"fox_transform", -10.0)
	Fx.shake(0.08, 0.1)


func _mimic(_delta: float) -> void:
	velocity = Vector2(_dash_dir * PData.MIMIC_SPEED, 0.0)
	if randf() < 0.8:
		PVfx.embers(global_position + Vector2(-_dash_dir * 20, -24), 3, true, 40.0, Vector2(20, 14))
	var x0 := global_position.x + (-34.0 if _dash_dir > 0 else -76.0)
	var r := Rect2(Vector2(x0, global_position.y - 70), Vector2(110, 70))
	for d: PDummy in PDummy.all(get_tree()):
		if not _mimic_hit.has(d) and r.intersects(d.hit_rect()):
			_mimic_hit[d] = true
			d.take_hit(int(PData.MIMIC_DAMAGE * (PData.FOX_DAMAGE if is_fox() else 1.0)), global_position, {"fox": true})
			PVfx.sparks(d.center(), 8, PData.FOX_HOT, 100.0)
	if st_t >= PData.MIMIC_TIME:
		_go(St.NORMAL)
		velocity.x = _dash_dir * _run_speed()
		PVfx.sparks(global_position + Vector2(0, -10), 10, PData.FOX_HOT, 90.0)


# ─── 기본공격: 둘레의 불덩이를 하나씩 던짐 (같은 위력 3연타, 마지막은 두 손 큰 덩이) ───

func _throw() -> void:
	var up := Input.is_action_pressed("pr_up")
	var down := Input.is_action_pressed("pr_down") and not is_on_floor()
	_atk_aim = -1 if up else (1 if down else 0)
	var step := 3 - orbs # 0 오른손 · 1 왼손 · 2 두 손(마지막 덩이)
	var big := step == 2
	var fox := is_fox()
	_atk_cd = PData.SHOT_COOLDOWN_FOX if fox else PData.SHOT_COOLDOWN
	var d := Vector2(facing, 0)
	match _atk_aim:
		-1:
			d = Vector2(facing * 0.12, -1.0).normalized()
		1:
			d = Vector2(facing * 0.55, 0.84).normalized()
	var from := _shot_origin(step)
	# 손으로 끌어올 불덩이 자리 (궤도 위 그 칸) — 손까지 불꽃 줄기
	var orbit_pos := global_position + Vector2(0, -17)
	for o in get_tree().get_nodes_in_group(&"p_orbit"):
		if (o as PShot.Orbit).front:
			orbit_pos += (o as PShot.Orbit).slot_pos(orbs - 1)
			break
	orbs -= 1
	if orbs == 0:
		_orb_refill = 0.2 if fox else 0.3
	var lv := PState.shot_size() * (1.15 if fox else 1.0) * (1.5 if big else 1.0)
	var sh := PShot.new()
	sh.sera = self
	sh.dir = d
	sh.step = step
	sh.fox = fox
	sh.r = PData.SHOT_RADIUS * lv
	sh.blast = PData.SHOT_BLAST * lv
	sh.speed = PData.SHOT_SPEED * (0.85 if big else 1.0)
	sh.range_px = PData.SHOT_RANGE + 6.0 * float(PState.tails - 1)
	sh.dmg = int(round(PData.SHOT_DAMAGE * PState.shot_mult() * (PData.FOX_DAMAGE if fox else 1.0)))
	PVfx.add(sh, from) # 일반 합성: 붉은·주황 색이 하얗게 타지 않고 또렷하게 (빛무리는 반투명으로 직접 그림)
	var mz := PShot.Muzzle.new()
	mz.dir = d
	mz.fox = fox
	mz.size = lv
	mz.from = orbit_pos - from
	PVfx.add(mz, from, true)
	PVfx.sparks(from, 4 if not big else 9, PSpells._pal(fox)[1], 150.0, 0.2, d, 35.0)
	art.atk_step = step
	art.atk_k = 0.0
	Sfx.play_pitch(&"whoosh", (1.5 + 0.1 * step if not big else 1.15) * (1.15 if fox else 1.0), -8.0 if not big else -4.0)
	Sfx.play_pitch(&"shoot", 0.85 + 0.1 * step if not big else 0.7, -9.0 if not big else -5.0)
	# 큰 덩이: 뒤로 살짝 밀리고 화면도 던진 쪽으로 살짝
	if big:
		PVfx.kick(d * 1.5)
		if _atk_aim == 0:
			velocity.x = -facing * PData.SHOT_RECOIL
			_recoil = 0.08
	# 공중에서 던지면 잠깐 떠 있음 (떨어지는 속도를 줄임 — 공중 연타가 스타일리시하게)
	if not is_on_floor() and velocity.y > 0.0:
		velocity.y *= 0.35


## 불덩이가 손을 떠나는 자리 (1타 오른손 · 2타 왼손 · 3타 두 손 머리 앞)
func _shot_origin(step: int) -> Vector2:
	match _atk_aim:
		-1:
			return global_position + Vector2(facing * 3, -36)
		1:
			return global_position + Vector2(facing * 8, -12)
	return global_position + Vector2(facing * [12, 10, 13][step], [-22, -24, -27][step])


func _refill_orbs() -> void:
	orbs = 3
	var rf := PShot.Refill.new()
	rf.fox = is_fox()
	PVfx.add(rf, global_position + Vector2(0, -17), true)
	PVfx.embers(global_position + Vector2(0, -17), 5, is_fox(), 50.0, Vector2(14, 4))
	Sfx.play_pitch(&"ignite", 1.6, -16.0)


## 폭주 게이지: 마법 사용·기본공격 적중으로만 찬다 (시험 배율 × 쉬움 배율). 변신 중에는 차지 않음
func add_gauge(v: float) -> void:
	if is_fox():
		return
	var before := gauge
	var mult := PState.od_mult * (PData.OD_EASY if PState.difficulty == 0 else 1.0)
	gauge = minf(gauge + v * mult, 1.0)
	if gauge >= 0.999: # 작은 값을 여러 번 더할 때 생기는 소수점 오차(0.9999…)로 '가득'을 놓치지 않게
		gauge = 1.0
	if before < 1.0 and gauge >= 1.0:
		Sfx.play(&"star_twinkle", -6.0)
		Fx.ring(center(), 6, 24, PData.FOX_HOT, 0.3)


# ─── 방패 · 변신 · 물약 ────────────────────────────────

## 여우방패: 거대한 여우 정령이 방패로 앞을 1.5초 막고(무적), 방패를 내리며 막은 피해만큼 커진 할퀴기로 반격
## (2026-10-04 속도감 때문에 조작에서 뺌 — 되살리려면 _actions에서 키 입력만 다시 연결)
func _start_shield() -> void:
	_go(St.SHIELD)
	_shield_t = PData.SHIELD_TIME
	shield_cd = PData.SHIELD_TIME + PData.SHIELD_COOLDOWN
	_gliding = false
	if is_instance_valid(_shield_fx):
		_shield_fx.queue_free()
	var fx := PSpells.ShieldSpirit.new()
	fx.owner_sera = self
	fx.fox = is_fox()
	fx.dir = facing
	_shield_fx = fx
	PVfx.add(fx, global_position, true)
	Sfx.play(&"ward", -2.0)
	Fx.shake(0.08, 0.1)


func _shield(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, PData.RUN_DECEL * delta)
	velocity.y = minf(velocity.y + PData.GRAVITY * delta, PData.FALL_MAX)
	if st_t >= PData.SHIELD_TIME:
		art.atk_step = 2 # 정령과 같이 휘두르는 팔 동작
		art.atk_k = 0.0
		_atk_aim = 0
		_atk_cd = 0.2
		_go(St.NORMAL)


func _start_transform() -> void:
	fox_time = PState.transform_time()
	gauge = 0.0
	art.fox = true
	Fx.hitstop(0.08)
	Fx.flash(Color(0.6, 0.85, 1.0, 0.5), 0.2)
	Fx.shake(0.15, 0.25)
	Fx.ring(center(), 6, 60, PData.FOX_HOT, 0.4, 3.0)
	var tb := PVfx.TransformBurst.new()
	tb.tails = PState.tails
	PVfx.add(tb, global_position, true)
	PVfx.sparks(center(), 40, PData.FOX_HOT, 220.0, 0.6)
	PVfx.embers(global_position + Vector2(0, -10), 24, true, 120.0, Vector2(10, 12))
	Sfx.play(&"fox_transform")


func _end_transform() -> void:
	fox_time = 0.0
	art.fox = false
	PVfx.sparks(center(), 18, PData.FOX_HOT, 90.0, 0.5)
	Sfx.play(&"fox_end", -6.0)


func _drink(_delta: float) -> void:
	velocity.x = 0.0
	velocity.y += PData.GRAVITY * _delta
	if st_t >= PData.POTION_TIME:
		potions -= 1
		hp2 = mini(hp2 + PData.POTION_HEAL * 2, PData.MAX_HEARTS * 2)
		PVfx.sparks(center(), 14, Color(1, 0.5, 0.6), 80.0, 0.5)
		Fx.ring(center(), 4, 20, Color(1, 0.6, 0.7), 0.3)
		Sfx.play(&"pickup", -4.0)
		_go(St.NORMAL)


# ─── 시전 잠김 · 압축 (PSpells가 시작) ───────────

func lock_cast(sec: float, invuln := false) -> void:
	_cast_lock = sec
	_cast_invuln = invuln
	_go(St.CAST)


func _cast(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, PData.RUN_DECEL * delta)
	if _cast_invuln:
		velocity.y = move_toward(velocity.y, 0.0, 900.0 * delta) # 대마법: 공중에 잠깐 뜬다
	else:
		velocity.y += PData.GRAVITY * delta
	if st_t >= _cast_lock:
		_cast_invuln = false
		_go(St.NORMAL)


func start_charge() -> void:
	charge_t = 0.0
	_go(St.CHARGE)


func _charge(delta: float) -> void:
	charge_t += delta
	var ax := _axis()
	if ax != 0:
		facing = ax
	velocity.x = move_toward(velocity.x, float(ax) * PData.RUN_SPEED * 0.3, PData.RUN_ACCEL * delta)
	velocity.y = minf(velocity.y + PData.GRAVITY * delta * (0.5 if not is_on_floor() else 1.0), PData.FALL_MAX * 0.5)
	if randf() < 0.7:
		var ang := randf() * TAU
		var hand := global_position + Vector2(facing * 11, -25)
		PVfx.mote_to(hand + Vector2(cos(ang), sin(ang)) * randf_range(14, 26), hand)
	if not Input.is_action_pressed(PState.spell_action("laser")) or charge_t >= 2.0:
		PSpells.fire_laser(self, clampf(charge_t, 0.5, 2.0))
		lock_cast(0.25)


# ─── 피격 · 쓰러짐 ─────────────────────────────────────

## 맞으면 true. 무적이면 false (탄이 사라질지 판단)
func take_damage(hearts_n: int, from: Vector2) -> bool:
	if invulnerable():
		if _shield_t > 0.0:
			if is_instance_valid(_shield_fx):
				(_shield_fx as PSpells.ShieldSpirit).absorb(hearts_n)
			Sfx.play(&"block", -2.0)
			return true
		return false
	var units := hearts_n * 2
	if PState.difficulty == 0:
		units = maxi(units / 2, 1)
	hp2 -= units
	_iframe = PData.HURT_IFRAME
	var dir := -1 if from.x > global_position.x else 1
	velocity = Vector2(dir * PData.HURT_KNOCK.x, PData.HURT_KNOCK.y)
	facing = -dir
	art.flash = 1.0
	Fx.hitstop(0.09)
	Fx.shake(0.18, 0.2)
	Fx.flash(Color(1, 0.3, 0.3, 0.25), 0.15)
	Sfx.play(&"hurt")
	_gliding = false
	if hp2 <= 0:
		if revive > 0:
			revive = 0
			hp2 = (PData.REVIVE_HEARTS_AWAKE if PState.awakened("phoenix") else PData.REVIVE_HEARTS) * 2
			PSpells.phoenix_revive(self)
			_go(St.NORMAL)
		else:
			_die()
		return true
	_go(St.HURT)
	return true


func _hurt(delta: float) -> void:
	velocity.y += PData.GRAVITY * delta
	velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	if st_t >= 0.25:
		_go(St.NORMAL)


func _die() -> void:
	_go(St.DEAD)
	art.visible = false
	PVfx.sparks(center(), 30, Color(1, 0.6, 0.6), 160.0, 0.6)
	Sfx.play(&"explode", -6.0)
	await get_tree().create_timer(1.1).timeout
	global_position = _respawn
	velocity = Vector2.ZERO
	hp2 = PData.MAX_HEARTS * 2
	potions = potions_max
	fox_time = 0.0
	art.fox = false
	art.visible = true
	_iframe = 1.2
	_go(St.NORMAL)
	Fx.ring(center(), 4, 30, PData.FIRE_HOT, 0.4)


## 여우 석등에서 쉬기: 체력·물약 회복
func rest() -> void:
	hp2 = PData.MAX_HEARTS * 2
	potions = potions_max
	_respawn = global_position
	PVfx.embers(global_position + Vector2(0, -8), 20, true, 70.0, Vector2(8, 4))
	Sfx.play(&"checkpoint", -4.0)


# ═══════════════════════════════════════════════════════════
# 그림 상태
# ═══════════════════════════════════════════════════════════

func _animate(delta: float) -> void:
	_flip.scale.x = float(facing)
	var a := art
	# 그림자: 발밑에서 아래로 광선 한 번 (바닥까지 거리)
	if is_on_floor():
		a.shadow_y = 0.0
	else:
		_ray.from = global_position
		_ray.to = global_position + Vector2(0, 90)
		_ray.collision_mask = 1
		var hit := get_world_2d().direct_space_state.intersect_ray(_ray)
		a.shadow_y = (hit.position.y - global_position.y) if hit else 999.0
	a.vel = velocity
	a.tails = PState.tails
	a.fox = is_fox()
	a.flash = maxf(a.flash - delta * 5.0, 0.0)
	a.modulate = Color(1, 1, 1).lerp(Color(3, 3, 3), a.flash * 0.6)
	a.blink_hidden = _iframe > 0.0 and st != St.DEAD and int(_iframe * 18.0) % 2 == 0
	a.focus_k = 0.0
	a.od = 0.0 if is_fox() else gauge
	a.charge_k = clampf(charge_t / 2.0, 0.0, 1.0) if st == St.CHARGE else 0.0
	if a.atk_k < 1.0:
		a.atk_k = minf(a.atk_k + delta / (0.2 if a.atk_step == 2 else 0.16), 1.0)
	var p := "idle"
	match st:
		St.DASH:
			p = "dash"
		St.MIMIC:
			p = "dash"
		St.SHIELD:
			p = "shield"
		St.CAST:
			p = "cast"
		St.CHARGE:
			p = "charge"
		St.DRINK:
			p = "drink"
		St.HURT:
			p = "hurt"
		_:
			if a.atk_k < 1.0:
				p = ["throw", "throw_up", "throw_down"][[0, -1, 1].find(_atk_aim)]
			elif not is_on_floor():
				if _wall_dir != 0:
					p = "wall"
				elif _gliding and velocity.y > 0.0:
					p = "glide"
				else:
					p = "jump" if velocity.y < 0.0 else "fall"
			elif absf(velocity.x) > 20.0:
				p = "run"
	if p == "wall":
		_flip.scale.x = float(-_wall_dir) # 벽을 등지고
	a.pose = p
	if p == "run":
		a.run_phase += delta * absf(velocity.x) / 9.5
	a.step(delta)
