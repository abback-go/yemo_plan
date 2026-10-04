class_name PSera
extends CharacterBody2D
## 훈련장 세라 (새 조작 시제품). 결정 기록: docs/design/controls_skills.md
## 상태 하나(st)로 나눈다: 보통(달리기·점프·벽·활공·발톱), 대시, 의태 돌진, 시전 잠김, 압축(열선), 난무(아수라),
## 마시기, 피격, 쓰러짐. 체력은 반 칸 단위(hp2)라 쉬움 난이도의 "받는 피해 절반"을 그대로 표현한다.

enum St { NORMAL, DASH, MIMIC, CAST, CHARGE, ASURA, DRINK, HURT, DEAD, SHIELD }

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

# 전투
var _claw_cd := 0.0
var _claw_buf := 0.0
var _claw_step := 0
var _claw_combo_t := 0.0
var _claw_hit := {}
var _claw_active := 0.0
var _claw_aim := 0
var _recoil := 0.0
var _shield_t := 0.0
var shield_cd := 0.0
var _iframe := 0.0
var _cast_lock := 0.0
var _cast_invuln := false
var _mote_t := 0.0
var charge_t := 0.0 ## 열선 압축 시간
var asura_t := 0.0
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


func center() -> Vector2:
	return global_position + Vector2(0, -18)


func hurt_rect() -> Rect2:
	return Rect2(global_position + Vector2(-5, -31), Vector2(10, 30))


func hearts() -> float:
	return float(hp2) / 2.0


func is_fox() -> bool:
	return fox_time > 0.0


## 폭주 봉인 중인가 (게이지 가득 + 아직 변신 안 함 → 마법 사용 불가, 발톱·대시·이동은 됨)
func overloaded() -> bool:
	return gauge >= 1.0 and not is_fox()


func invulnerable() -> bool:
	return _iframe > 0.0 or _shield_t > 0.0 or st == St.ASURA or st == St.DEAD or _cast_invuln \
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
		St.ASURA:
			_asura(delta)
		St.DRINK:
			_drink(delta)
		St.HURT:
			_hurt(delta)
		St.SHIELD:
			_shield(delta)
		St.DEAD:
			velocity = Vector2.ZERO
	var was := is_on_floor()
	move_and_slide()
	if is_on_floor() and not _was_floor and st != St.DEAD:
		_land()
	_was_floor = is_on_floor()
	if was or is_on_floor():
		_air_dash = true
	_animate(delta)


func _timers(delta: float) -> void:
	_dash_cd = maxf(_dash_cd - delta, 0.0)
	_claw_cd = maxf(_claw_cd - delta, 0.0)
	_claw_buf = maxf(_claw_buf - delta, 0.0)
	_claw_combo_t = maxf(_claw_combo_t - delta, 0.0)
	if _claw_combo_t <= 0.0:
		_claw_step = 0
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
	if _claw_active > 0.0:
		_claw_active -= delta
		_claw_hits()
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
		pass # 발톱 반동 중에는 밀려난 속도를 유지
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
			PVfx.add(PVfx.AirRing.new(), global_position + Vector2(0, -2), true)
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


## 보통 상태에서 받는 행동 입력 (대시·발톱·변신·물약·마법)
func _actions(on_floor: bool) -> void:
	if Input.is_action_just_pressed("pr_dash") and _dash_cd <= 0.0 and (on_floor or (PState.evade and _air_dash)):
		if is_fox():
			_start_mimic() # 변신 중 대시 = 의태 돌진
		else:
			_start_dash()
		return
	if Input.is_action_just_pressed("pr_claw"):
		_claw_buf = 0.15 # 쿨이 막 끝나기 전에 눌러도 이어지게
	if _claw_buf > 0.0 and _claw_cd <= 0.0:
		_claw_buf = 0.0
		_claw()
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
	var paw := PVfx.FoxPaw.new()
	paw.dir = -_wall_dir
	paw.size = 0.7
	PVfx.add(paw, global_position + Vector2(_wall_dir * 6, -14), true)
	Sfx.play(&"jump", -6.0)
	_wall_dir = 0


func _land() -> void:
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
	var paw := PVfx.FoxPaw.new()
	paw.dir = _dash_dir
	paw.size = 1.1
	PVfx.add(paw, global_position + Vector2(-_dash_dir * 6, -4), true)
	Sfx.play(&"dash", -4.0)
	Fx.shake(0.05, 0.08)


func _dash(_delta: float) -> void:
	var dur := PData.DASH_TIME * (1.2 if is_fox() else 1.0)
	velocity = Vector2(_dash_dir * PData.DASH_SPEED, 0.0)
	var sl := PVfx.SpeedLine.new()
	sl.dir = _dash_dir
	sl.fox = is_fox()
	PVfx.add(sl, global_position + Vector2(-_dash_dir * 4, randf_range(-24, -6)))
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


# ─── 발톱 (같은 위력 3연타) ─────────────────────────────

func _claw() -> void:
	var up := Input.is_action_pressed("pr_up")
	var down := Input.is_action_pressed("pr_down") and not is_on_floor()
	_claw_aim = -1 if up else (1 if down else 0)
	_claw_cd = PData.CLAW_COOLDOWN_FOX if is_fox() else PData.CLAW_COOLDOWN
	_claw_active = PData.CLAW_ACTIVE
	_claw_hit.clear()
	var slash := PVfx.ClawSlash.new()
	slash.dir = facing
	slash.aim = _claw_aim
	slash.step = _claw_step
	slash.fox = is_fox()
	slash.reach = PData.CLAW_REACH + 2.25 * float(PState.tails - 1)
	slash.follow = self
	slash.offset = _claw_origin() - global_position
	PVfx.add(slash, _claw_origin())
	art.claw_step = _claw_step
	art.claw_k = 0.0
	Sfx.play_pitch(&"swing", 1.15 + 0.08 * _claw_step if not is_fox() else 1.35, -4.0)
	_claw_step = (_claw_step + 1) % 3
	_claw_combo_t = 0.5
	_claw_hits()


func _claw_origin() -> Vector2:
	match _claw_aim:
		-1:
			return global_position + Vector2(facing * 1, -27)
		1:
			return global_position + Vector2(0, -6)
	return global_position + Vector2(facing * 2, -19)


func _claw_rect() -> Rect2:
	var reach := (PData.CLAW_REACH + 2.25 * float(PState.tails - 1)) * (1.25 if is_fox() else 1.0)
	var h := PData.CLAW_HEIGHT * (1.2 if is_fox() else 1.0)
	match _claw_aim:
		-1:
			return Rect2(global_position + Vector2(-h / 2, -26 - reach), Vector2(h, reach))
		1:
			return Rect2(global_position + Vector2(-h / 2, -8), Vector2(h, reach + 6))
	var x0 := global_position.x + (0.0 if facing > 0 else -reach)
	return Rect2(Vector2(x0, global_position.y - 15 - h / 2), Vector2(reach, h))


func _claw_hits() -> void:
	var r := _claw_rect()
	var hit_any := false
	for d: PDummy in PDummy.all(get_tree()):
		if _claw_hit.has(d) or not r.intersects(d.hit_rect()):
			continue
		_claw_hit[d] = true
		hit_any = true
		var dmg := int(round(PData.CLAW_DAMAGE * PState.claw_mult() * (PData.FOX_DAMAGE if is_fox() else 1.0)))
		d.take_hit(dmg, global_position, {"fox": is_fox()})
		var hp := r.intersection(d.hit_rect()).get_center()
		var fl := PVfx.HitFlash.new()
		fl.dir = facing
		fl.fox = is_fox()
		PVfx.add(fl, hp)
		PVfx.sparks(hp, 6, PData.FOX_HOT if is_fox() else Color(1, 0.95, 0.85), 150.0, 0.25, Vector2(facing, -0.3), 50.0)
		add_gauge(PData.OD_CLAW)
	if hit_any:
		Fx.hitstop(PData.CLAW_HITSTOP)
		Fx.shake(0.06, 0.08)
		Sfx.play(&"hit", -4.0)
		# 반동: 앞으로 친 건 뒤로, 아래로 친 건 살짝 위로(튕김은 아님)
		if _claw_aim == 0:
			velocity.x = -facing * PData.CLAW_RECOIL
			_recoil = 0.07
		elif _claw_aim == 1 and velocity.y > 0.0:
			velocity.y = minf(velocity.y, 30.0)


## 폭주 게이지: 마법 사용·발톱 적중으로만 찬다 (시험 배율 × 쉬움 배율). 변신 중에는 차지 않음
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
		art.claw_step = 2 # 정령과 같이 휘두르는 팔 동작
		art.claw_k = 0.0
		_claw_aim = 0
		_claw_cd = 0.2
		_go(St.NORMAL)


func _start_transform() -> void:
	fox_time = PState.transform_time()
	gauge = 0.0
	art.fox = true
	Fx.hitstop(0.08)
	Fx.flash(Color(0.6, 0.85, 1.0, 0.5), 0.2)
	Fx.shake(0.15, 0.25)
	Fx.ring(center(), 6, 60, PData.FOX_HOT, 0.4, 3.0)
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


# ─── 시전 잠김 · 압축 · 난무 (PSpells가 시작) ───────────

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
		var m := PVfx.Mote.new()
		var ang := randf() * TAU
		var hand := global_position + Vector2(facing * 11, -25)
		m.from = hand + Vector2(cos(ang), sin(ang)) * randf_range(14, 26)
		m.to = self
		m.to_off = Vector2(facing * 11, -25)
		m.life = 0.25
		PVfx.add(m, m.from, true)
	if not Input.is_action_pressed(PState.spell_action("laser")) or charge_t >= 2.0:
		PSpells.fire_laser(self, clampf(charge_t, 0.5, 2.0))
		lock_cast(0.25)


func start_asura(sec: float) -> void:
	asura_t = sec
	_go(St.ASURA)


func _asura(delta: float) -> void:
	asura_t -= delta
	var ax := _axis()
	if ax != 0:
		facing = ax
	velocity.x = move_toward(velocity.x, float(ax) * PData.RUN_SPEED, PData.RUN_ACCEL * delta)
	velocity.y = minf(velocity.y + PData.GRAVITY * delta, PData.FALL_MAX)
	if Input.is_action_just_pressed("pr_jump") and is_on_floor():
		velocity.y = -PData.JUMP_SPEED * 0.8
	if asura_t <= 0.0:
		_go(St.NORMAL)


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
	a.vel = velocity
	a.tails = PState.tails
	a.fox = is_fox()
	a.flash = maxf(a.flash - delta * 5.0, 0.0)
	a.modulate = Color(1, 1, 1).lerp(Color(3, 3, 3), a.flash * 0.6)
	a.blink_hidden = _iframe > 0.0 and st != St.DEAD and int(_iframe * 18.0) % 2 == 0
	a.focus_k = 0.0
	a.od = 0.0 if is_fox() else gauge
	a.charge_k = clampf(charge_t / 2.0, 0.0, 1.0) if st == St.CHARGE else 0.0
	if _claw_cd > 0.0 or _claw_active > 0.0:
		a.claw_k = minf(a.claw_k + delta / 0.16, 1.0)
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
		St.ASURA:
			p = "asura"
		St.DRINK:
			p = "drink"
		St.HURT:
			p = "hurt"
		_:
			if a.claw_k < 1.0:
				p = ["claw", "claw_up", "claw_down"][[0, -1, 1].find(_claw_aim)]
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
