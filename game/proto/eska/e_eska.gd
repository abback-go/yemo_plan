class_name EEska
extends CharacterBody2D
## 에스카(종언의 마녀) 전투 시제품. 기획: Claude 문서 "새 컨셉: 종언의 마녀" 탭.
## 조작: 이동(떠서 활주) · 점프 + 이단점프(공중에서 한 번) · 순간이동(지상은 자유, 공중은 착지 전까지 1번) · 4타 연격(공중 가능 — 팔을 휘두르지 않고 가리키기·튕기기 같은 가벼운 손짓, 제자리에서)
##       · 스킬 키: 그냥 = 천열(손가락을 튕기면 앞으로 거대한 참격 열 번) / ↑ = 단공(머리 위를 납작한 회오리 참격으로 연달아 휘감음)
##       · 봉공(공간 틀에 가둠). 스킬은 쿨다운만 쓴다.
## 공격 판정은 물리 없이 표적(ETarget: 허수아비·적)의 hit_rect()와 부채꼴·선분으로 계산한다(세라 시제품과 같은 방식).

enum St { NORMAL, ATTACK, BLINK, CAST, HURT, DEAD }

signal hurt_taken(hp: int) ## 맞았을 때 (남은 체력)
signal died ## 쓰러졌을 때 — 장면이 부활시킨다 (respawn)

const GROUP := &"e_eska"
const SIZE := Vector2(10, 30)

# 이동: 땅 위를 살짝 떠서 미끄러지듯 활주 (상체를 숙이고 빠르게)
const RUN_SPEED := 210.0
const RUN_ACCEL := 2800.0
const RUN_DECEL := 3200.0
const AIR_ACCEL := 1900.0
const GRAVITY := 1350.0
const FALL_MAX := 330.0
const JUMP_SPEED := 360.0 ## 높이 고정 (길게 눌러도 같음) — 약 46px (예전 길게 누르면 약 65px)
const APEX_HANG := 0.55
const COYOTE := 0.09
const JUMP_BUFFER := 0.12
const AIR_JUMP_SPEED := 320.0 ## 이단점프: 공중의 공간을 밟고 한 번 더 도약 (착지 전까지 1번, 높이 고정)
const ATTACK_BUFFER := 0.14
const FAST_FALL_MAX := 440.0 ## 공중에서 ↓를 누르고 있으면
const COMBO_WINDOW := 1.6 ## 이 시간 안에 다시 맞히면 연타 수가 이어진다

# 순간이동
const BLINK_DIST := 150.0 ## 약 9타일 (100에서 1.5배)
const BLINK_GONE := 0.07 ## 사라져 있는 시간
const BLINK_CD := 0.26

# 체력·피격
const MAX_HP := 6
const HURT_LOCK := 0.3 ## 맞은 뒤 조작이 막히는 시간
const HURT_INVULN := 1.1 ## 맞은 뒤 무적(깜빡임)
const RESPAWN_INVULN := 1.6 ## 부활 뒤 무적

## 스킬 쿨다운 (짧게 — 손맛 시험용)
const CD := {"cheonyeol": 5.0, "dangong": 2.0, "bonggong": 6.0} ## 천열은 896 피해라 5초 (2초면 연격을 쓸 이유가 없어짐 — docs/eska/combat_spec.md 밸런스)
const NAMES := {"cheonyeol": "천열", "dangong": "단공", "bonggong": "봉공"}

## 4타 연격. 각도는 도(0 = 앞, + = 아래). 호는 a0 → a1로 휘두른다. 납작한 회오리(sq)를 rot만큼 기울인다 —
## 1~3타는 앞쪽 한 곳(발 기준 앞 약 30px)을 중심으로 모아 친다. 1타 앞이 들린 대각 · 2타 앞이 내려간 가파른 대각(반대로 감음) · 3타 비스듬히 세워 아래에서 위로 올려 벰 · 4타 가장 큰 가로 회오리 (타마다 다른 각도)
## dur 한 타 길이 · hit 판정 시각 · next 다음 타를 받기 시작하는 시각 · r 반지름 · w 가장 굵은 곳 · sq 세로 납작함 · c 몸 기준 중심
const COMBO := [
	{"dur": 0.15, "hit": 0.035, "next": 0.07, "a0": -190.0, "a1": 40.0, "r": 74.0, "w": 26.0, "sq": 0.34, "rot": -22.0, "c": Vector2(30, -26), "dmg": 30, "step": 12.0},
	{"dur": 0.15, "hit": 0.035, "next": 0.07, "a0": 150.0, "a1": -80.0, "r": 78.0, "w": 26.0, "sq": 0.3, "rot": 38.0, "c": Vector2(32, -28), "dmg": 30, "step": 12.0},
	{"dur": 0.16, "hit": 0.04, "next": 0.08, "a0": 170.0, "a1": -60.0, "r": 100.0, "w": 28.0, "sq": 0.36, "rot": -50.0, "c": Vector2(26, -30), "dmg": 34, "step": 14.0},
	{"dur": 0.34, "hit": 0.06, "next": 0.34, "a0": -200.0, "a1": 160.0, "r": 140.0, "w": 44.0, "sq": 0.4, "rot": -8.0, "c": Vector2(6, -26), "dmg": 64, "step": 24.0},
]
const CHAIN_WINDOW := 0.28 ## 한 타가 끝난 뒤 이 안에 누르면 다음 타로 이어짐

var st := St.NORMAL
var st_t := 0.0
var facing := 1
var art: EArt
var cooldowns := {"cheonyeol": 0.0, "dangong": 0.0, "bonggong": 0.0}

var _coyote := 0.0
var _jump_buf := 0.0
var _atk_buf := 0.0
var _was_floor := true

var combo_i := 0
var _hit_done := false
var _queued := false
var _chain_next := 0
var _chain_t := 0.0
var _air_hang := true ## 공중 연격으로 떠 있기 (착지 전까지 연격 한 바퀴)
var _air_jump := true ## 이단점프 남았는지 (착지하면 다시)
var _ghost_t := 0.0 ## 활주 잔상 간격

var _air_blink := true
var _blink_cd := 0.0
var _blink_dir := 1
var _blink_to := Vector2.ZERO

var cast_kind := ""
var _cast_dur := 0.0
var _cast_fired := false
var _bind_target: Node2D

var invuln := 0.0
var hp := MAX_HP
var hurt_flicker := 0.0 ## 맞은 뒤 깜빡이는 남은 시간 (그림이 읽는다)
var controls_locked := false ## 연출 중 조작 막기 (튜토리얼 대사 등)

# 연타 수 (화면 오른쪽 위)
var hit_count := 0
var hit_damage := 0
var combo_left := 0.0
var _dust_t := 0.0
var _last_dir := 1


static func find(tree: SceneTree) -> EEska:
	return tree.get_first_node_in_group(GROUP) as EEska


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
	art = EArt.new()
	art.body = self
	add_child(art)


func center() -> Vector2:
	return global_position + Vector2(0, -SIZE.y * 0.55)


func cd_left(id: String) -> float:
	return float(cooldowns.get(id, 0.0))


func cd_ratio(id: String) -> float:
	return clampf(cd_left(id) / float(CD[id]), 0.0, 1.0)


func is_up_held() -> bool:
	return Input.is_action_pressed("es_up")


# ═══════════════════════════════════════════════════════════
# 한 프레임
# ═══════════════════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	st_t += delta
	for k in cooldowns:
		cooldowns[k] = maxf(float(cooldowns[k]) - delta, 0.0)
	_blink_cd = maxf(_blink_cd - delta, 0.0)
	_chain_t = maxf(_chain_t - delta, 0.0)
	invuln = maxf(invuln - delta, 0.0)
	combo_left = maxf(combo_left - delta, 0.0)
	if combo_left <= 0.0:
		hit_count = 0
		hit_damage = 0
	_coyote = COYOTE if is_on_floor() else maxf(_coyote - delta, 0.0)
	_jump_buf = maxf(_jump_buf - delta, 0.0)
	_atk_buf = maxf(_atk_buf - delta, 0.0)
	if Input.is_action_just_pressed("es_jump"):
		_jump_buf = JUMP_BUFFER
	if Input.is_action_just_pressed("es_attack"):
		_atk_buf = ATTACK_BUFFER
	hurt_flicker = maxf(hurt_flicker - delta, 0.0)
	var dir_x := Input.get_axis("es_left", "es_right")
	if controls_locked:
		dir_x = 0.0
		_jump_buf = 0.0
		_atk_buf = 0.0
	match st:
		St.NORMAL:
			_normal(delta, dir_x)
		St.ATTACK:
			_attack(delta, dir_x)
		St.BLINK:
			_blink(delta)
		St.CAST:
			_cast(delta)
		St.HURT:
			_hurt_state(delta)
		St.DEAD:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			_gravity(delta)
	if st != St.BLINK:
		move_and_slide()
	var on_floor := is_on_floor()
	if on_floor:
		_air_blink = true
		_air_hang = true
		_air_jump = true
		if not _was_floor:
			EVfx.land_dust(global_position)
			Sfx.play(&"land", -14.0)
	_was_floor = on_floor
	_ground_fx(delta)
	art.tick(delta)


func _gravity(delta: float, mult := 1.0) -> void:
	var g := GRAVITY * mult
	if absf(velocity.y) < 60.0 and not is_on_floor():
		g *= APEX_HANG
	var cap := FALL_MAX
	if Input.is_action_pressed("es_down") and not is_on_floor():
		g *= 1.35
		cap = FAST_FALL_MAX
	velocity.y = minf(velocity.y + g * delta, cap)


## 활주: 발밑에 낮게 깔리는 보랏빛 바람 · 뒤로 흐르는 속도선 · 짧은 잔상 / 방향 바꿀 때 미끄러지는 먼지
func _ground_fx(delta: float) -> void:
	var vx := velocity.x
	var fast := absf(vx) > 190.0 and st == St.NORMAL
	if fast:
		_ghost_t -= delta
		if _ghost_t <= 0.0:
			_ghost_t = 0.14
			EVfx.afterimage(art, 0.14, EVfx.VIOLET, Vector2.ZERO, 0.4) # 최고 속도에서만 아주 옅은 잔상
	if not is_on_floor() or st == St.BLINK:
		return
	if absf(vx) > 110.0:
		_dust_t -= delta
		if _dust_t <= 0.0:
			_dust_t = 0.045
			EMoveFx.glide_wake(global_position, signf(vx), absf(vx) / RUN_SPEED)
	var d := int(signf(Input.get_axis("es_left", "es_right")))
	if d != 0 and d != _last_dir and absf(vx) > 90.0 and st == St.NORMAL:
		PVfx.dust(global_position + Vector2(-d * 2.0, 0), 4, 1.2, 16.0)
		art.squash(Vector2(1.12, 0.9))
	if d != 0:
		_last_dir = d


func _run(delta: float, dir_x: float, speed_mult := 1.0) -> void:
	var target := dir_x * RUN_SPEED * speed_mult
	var acc := RUN_ACCEL if is_on_floor() else AIR_ACCEL
	if absf(dir_x) < 0.01:
		acc = RUN_DECEL if is_on_floor() else AIR_ACCEL * 0.6
	velocity.x = move_toward(velocity.x, target, acc * delta)
	if dir_x > 0.01:
		facing = 1
	elif dir_x < -0.01:
		facing = -1


func _normal(delta: float, dir_x: float) -> void:
	_run(delta, dir_x)
	if _jump_buf > 0.0 and _coyote > 0.0:
		_jump_buf = 0.0
		_coyote = 0.0
		velocity.y = -JUMP_SPEED
		art.squash(Vector2(0.82, 1.2))
		if is_on_floor():
			PVfx.dust(global_position, 4, 1.0, 14.0)
		Sfx.play(&"jump", -6.0)
	elif _jump_buf > 0.0 and _air_jump and not is_on_floor():
		_double_jump(dir_x)
	_gravity(delta)
	_try_actions(dir_x)


## 이단점프: 발밑 공중에 다크 회오리 고리가 생겨 그것을 밟고 도약, 몸이 아주 빠르게 한 바퀴(치맛자락이 우산처럼 퍼짐). 누른 방향으로 바로 꺾는다
func _double_jump(dir_x: float) -> void:
	_jump_buf = 0.0
	_air_jump = false
	velocity.y = -AIR_JUMP_SPEED
	if absf(dir_x) > 0.01:
		velocity.x = signf(dir_x) * RUN_SPEED
		facing = 1 if dir_x > 0.0 else -1
	art.air_flourish()
	art.squash(Vector2(0.9, 1.12))
	EMoveFx.air_step(global_position)
	Sfx.play(&"es_air_step", -4.0)
	Sfx.play_pitch(&"whoosh", 1.4, -12.0)


## 순간이동·스킬·공격 시작 (상태가 바뀌면 true)
func _try_actions(dir_x: float) -> bool:
	if controls_locked:
		return false
	if Input.is_action_just_pressed("es_bind") and cd_left("bonggong") <= 0.0:
		_start_cast("bonggong", 0.22)
		return true
	if Input.is_action_just_pressed("es_skill"):
		if is_up_held():
			if cd_left("dangong") <= 0.0:
				_start_cast("dangong", 0.32)
				return true
		elif cd_left("cheonyeol") <= 0.0:
			_start_cast("cheonyeol", 0.26)
			return true
	if Input.is_action_just_pressed("es_blink") and _blink_cd <= 0.0 and (is_on_floor() or _air_blink):
		_start_blink(dir_x)
		return true
	if _atk_buf > 0.0:
		_atk_buf = 0.0
		var i := _chain_next if _chain_t > 0.0 else 0
		_start_attack(i)
		return true
	return false


# ═══════════════════════════════════════════════════════════
# 4타 연격
# ═══════════════════════════════════════════════════════════

func _start_attack(i: int) -> void:
	var dir_x := Input.get_axis("es_left", "es_right")
	if dir_x > 0.01:
		facing = 1
	elif dir_x < -0.01:
		facing = -1
	combo_i = i
	st = St.ATTACK
	st_t = 0.0
	_hit_done = false
	_queued = false
	var a: Dictionary = COMBO[i]
	if is_on_floor():
		velocity.x = facing * float(a.step)
	elif _air_hang:
		velocity.y = minf(velocity.y, -30.0 if i == 0 else 10.0)
		velocity.x *= 0.5
	var c: Vector2 = a.c
	var sl := ESkillFx.Slash.new()
	sl.setup(a, facing, i == 3)
	EVfx.add(sl, global_position + Vector2(c.x * facing, c.y), false) # 다크 참격은 보통 섞기 (검은 테두리가 보이게)
	Sfx.play_pitch(&"es_snap", [1.0, 1.12, 0.94, 0.86][i] * randf_range(0.97, 1.03), -6.0)
	Sfx.play_pitch(&"es_slash_big" if i == 3 else &"es_slash", [1.05, 1.15, 0.95, 1.0][i] * randf_range(0.96, 1.04), -3.0 if i < 3 else 0.0)
	# 팔을 휘두르지 않고 손끝 하나로 — 손가락 끝이 반짝이며 공간이 갈라진다
	art.snap_flash()
	if i == 3:
		art.squash(Vector2(1.04, 0.97))
		EVfx.afterimage(art, 0.22)
	else:
		art.squash(Vector2(1.02, 0.99))


func _attack(delta: float, dir_x: float) -> void:
	var a: Dictionary = COMBO[combo_i]
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 1100.0 * delta)
		velocity.y = minf(velocity.y + GRAVITY * delta, FALL_MAX)
	elif _air_hang:
		velocity.y = minf(velocity.y + GRAVITY * 0.2 * delta, 50.0)
		velocity.x = move_toward(velocity.x, dir_x * RUN_SPEED * 0.4, 700.0 * delta)
	else:
		_gravity(delta)
		velocity.x = move_toward(velocity.x, dir_x * RUN_SPEED * 0.6, AIR_ACCEL * delta)
	if not _hit_done and st_t >= float(a.hit):
		_hit_done = true
		_slash_hit(a)
	if _atk_buf > 0.0:
		_atk_buf = 0.0
		_queued = true
	# 판정 뒤에는 점프로 끊을 수 있다 (땅에서는 점프, 공중에서는 이단점프)
	if _hit_done and _jump_buf > 0.0 and (is_on_floor() or _air_jump):
		st = St.NORMAL
		_normal(delta, dir_x)
		return
	# 판정 뒤에는 순간이동·스킬로 끊을 수 있다
	if _hit_done and (Input.is_action_just_pressed("es_blink") or Input.is_action_just_pressed("es_skill")
			or Input.is_action_just_pressed("es_bind")):
		if combo_i == 3 and not is_on_floor():
			_air_hang = false
		st = St.NORMAL
		if _try_actions(dir_x):
			return
	if _queued and combo_i < 3 and st_t >= float(a.next):
		_start_attack(combo_i + 1)
		return
	if st_t >= float(a.dur):
		st = St.NORMAL
		st_t = 0.0
		if combo_i < 3:
			_chain_next = combo_i + 1
			_chain_t = CHAIN_WINDOW
		else:
			_chain_next = 0
			_chain_t = 0.0
			if not is_on_floor():
				_air_hang = false # 공중 연격 한 바퀴 뒤엔 떨어진다


func _slash_hit(a: Dictionary) -> void:
	var c: Vector2 = a.c
	var cen := global_position + Vector2(c.x * facing, c.y)
	var heavy := combo_i == 3
	var any := false
	for d: Node2D in ETarget.alive(get_tree()):
		if _sector_hits(d.hit_rect(), cen, float(a.r) + 8.0, float(a.a0), float(a.a1), float(a.sq), float(a.get("rot", 0.0))):
			deal(d, int(a.dmg), heavy, cen)
			any = true
	if any:
		Fx.hitstop(0.075 if heavy else 0.04)
		PVfx.kick(Vector2(facing * (5.0 if heavy else 2.5), 0))
		Fx.shake(0.4 if heavy else 0.14, 0.18 if heavy else 0.1)
		if heavy:
			Fx.zoom_punch(0.05)


## 부채꼴(납작함 sq) 안에 사각형이 걸치는지. 각도는 앞 기준(도)
## 기울인(rot, 도) 납작한(sq) 호 안에 rect가 들어오는지 — 그림(Slash)과 같은 변환을 거꾸로 적용
func _sector_hits(rect: Rect2, cen: Vector2, r: float, a0: float, a1: float, sq: float, rot := 0.0) -> bool:
	sq = maxf(sq, 0.6) # 그림은 납작한 회오리지만 판정은 위아래로 넉넉하게 (공중에서도 맞게)
	var unrot := -deg_to_rad(rot) * float(facing)
	var lo := deg_to_rad(minf(a0, a1)) - 0.25
	var hi := deg_to_rad(maxf(a0, a1)) + 0.25
	var p0 := rect.position
	var p1 := rect.end
	var m := rect.get_center()
	for pt: Vector2 in [m, p0, p1, Vector2(p0.x, p1.y), Vector2(p1.x, p0.y), Vector2(m.x, p0.y), Vector2(m.x, p1.y), Vector2(p0.x, m.y), Vector2(p1.x, m.y)]:
		var q := (pt - cen).rotated(unrot)
		q.x *= facing
		q.y /= sq
		var l := q.length()
		if l > r:
			continue
		if l < 16.0:
			return true
		var ang := atan2(q.y, q.x)
		if ang >= lo and ang <= hi:
			return true
	return false


## 피해 한 번 (이펙트 노드들도 이걸 부른다)
func deal(d: Node2D, dmg: int, heavy: bool, from: Vector2) -> void:
	if not is_instance_valid(d):
		return
	d.take_hit(dmg, from, {"heavy": heavy, "launch": 1.5 if heavy else 0.0})
	hit_count += 1
	hit_damage += dmg
	combo_left = COMBO_WINDOW
	EVfx.hit_crack(d.center() + Vector2(randf_range(-4, 4), randf_range(-8, 8)), heavy, signf(d.global_position.x - from.x))
	Sfx.play(&"hit_heavy" if heavy else &"hit", -6.0 if not heavy else -2.0)


# ═══════════════════════════════════════════════════════════
# 순간이동
# ═══════════════════════════════════════════════════════════

func _start_blink(dir_x: float) -> void:
	var d := facing
	if dir_x > 0.01:
		d = 1
	elif dir_x < -0.01:
		d = -1
	facing = d
	_blink_dir = d
	var motion := Vector2(d * BLINK_DIST, 0)
	var from_xf := global_transform.translated(Vector2(0, -2))
	var col := KinematicCollision2D.new()
	var travel := motion
	if test_move(from_xf, motion, col):
		travel = col.get_travel()
	_blink_to = global_position + Vector2(travel.x, 0)
	if not is_on_floor():
		_air_blink = false
	st = St.BLINK
	st_t = 0.0
	invuln = BLINK_GONE + 0.08
	EMoveFx.blink_out(art, center(), d)
	EMoveFx.blink_trail(art, center(), _blink_to + Vector2(0, -SIZE.y * 0.55), not is_on_floor())
	art.visible = false
	velocity = Vector2.ZERO
	Sfx.play(&"es_blink", -3.0)


func _blink(_delta: float) -> void:
	velocity = Vector2.ZERO
	if st_t >= BLINK_GONE:
		global_position = _blink_to
		art.visible = true
		st = St.NORMAL
		st_t = 0.0
		_blink_cd = BLINK_CD
		velocity.x = _blink_dir * RUN_SPEED
		velocity.y = 0.0
		EMoveFx.blink_in(center(), _blink_dir)
		art.squash(Vector2(1.9, 0.5)) # 길게 늘어난 채 나타났다가 탁 돌아온다
		PVfx.kick(Vector2(_blink_dir * 3.0, 0))


# ═══════════════════════════════════════════════════════════
# 스킬: 천열 · 단공 · 봉공
# ═══════════════════════════════════════════════════════════

func _start_cast(kind: String, dur: float) -> void:
	var dir_x := Input.get_axis("es_left", "es_right")
	if dir_x > 0.01:
		facing = 1
	elif dir_x < -0.01:
		facing = -1
	cast_kind = kind
	_cast_dur = dur
	_cast_fired = false
	cooldowns[kind] = CD[kind]
	st = St.CAST
	st_t = 0.0
	if not is_on_floor():
		velocity.y = minf(velocity.y, 0.0) * 0.3
	if kind == "bonggong":
		_bind_target = _pick_target(240.0)


func _cast(delta: float) -> void:
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)
		velocity.y = minf(velocity.y + GRAVITY * delta, FALL_MAX)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		velocity.y = move_toward(velocity.y, 20.0, 900.0 * delta) # 시전 중엔 공중에 잠깐 머문다
	var fire_at: float = {"cheonyeol": 0.07, "dangong": 0.06, "bonggong": 0.07}.get(cast_kind, 0.05)
	if not _cast_fired and st_t >= fire_at:
		_cast_fired = true
		match cast_kind:
			"cheonyeol":
				var fl := ESkillFx.Flurry.new()
				fl.eska = self
				fl.dir = facing
				EVfx.add(fl, global_position, false)
				art.snap_flash()
				Sfx.play_pitch(&"blip", 1.6, -2.0)
				Sfx.play(&"whoosh", -4.0)
			"dangong":
				var up := ESkillFx.Upsweep.new()
				up.eska = self
				up.dir = facing
				up.area = Rect2(global_position + Vector2(-140, -230), Vector2(280, 222)) # 머리 위 (양옆으로 넓게)
				EVfx.add(up, global_position, false)
				art.snap_flash()
				Sfx.play(&"storm", -6.0)
			"bonggong":
				var fr := ESkillFx.BindFrame.new()
				fr.eska = self
				fr.target = _bind_target
				var at: Vector2 = _bind_target.center() if is_instance_valid(_bind_target) else global_position + Vector2(facing * 70, -20)
				EVfx.add(fr, at, false)
				art.snap_flash()
				Sfx.play(&"chain", -4.0)
	if _cast_fired and Input.is_action_just_pressed("es_blink") and _blink_cd <= 0.0 and (is_on_floor() or _air_blink):
		_start_blink(Input.get_axis("es_left", "es_right"))
		return
	if st_t >= _cast_dur:
		st = St.NORMAL
		st_t = 0.0


## 가장 가까운 허수아비 (앞쪽을 조금 더 쳐 줌)
func _pick_target(reach: float) -> Node2D:
	var best: Node2D = null
	var best_s := INF
	for d: Node2D in ETarget.alive(get_tree()):
		if d.get("lockable") == false:
			continue # 적 구슬 등은 겨누지 않음
		var off: Vector2 = d.center() - center()
		var dist := off.length()
		if dist > reach:
			continue
		var s: float = dist * (0.7 if signf(off.x) == float(facing) else 1.3)
		if s < best_s:
			best_s = s
			best = d
	return best


# ═══════════════════════════════════════════════════════════
# 체력 · 피격 · 쓰러짐 · 부활
# ═══════════════════════════════════════════════════════════

## 맞는 판정 사각형 (전역)
func hurt_rect() -> Rect2:
	return Rect2(global_position + Vector2(-SIZE.x * 0.5, -SIZE.y), SIZE)


func is_dead() -> bool:
	return st == St.DEAD


## 적에게 맞음 (맞았으면 true). 순간이동 중·필살기 중·무적 중엔 안 맞는다
func hurt(dmg: int, from: Vector2) -> bool:
	if invuln > 0.0 or st in [St.DEAD, St.BLINK]:
		return false
	hp = maxi(hp - dmg, 0)
	invuln = HURT_INVULN
	hurt_flicker = HURT_INVULN
	var d := signf(global_position.x - from.x)
	if d == 0.0:
		d = -float(facing)
	velocity = Vector2(d * 190.0, -190.0)
	st = St.HURT
	st_t = 0.0
	art.visible = true
	art.hurt()
	Fx.hitstop(0.09)
	Fx.shake(0.55, 0.22)
	PVfx.kick(Vector2(d * 4.0, -2.0))
	Fx.flash(Color(1.0, 0.2, 0.3, 0.22), 0.16)
	Sfx.play(&"hurt", -3.0)
	EVfx.dark_bits(center(), 8, 160.0, Vector2(d, -0.4), 70.0, 0.4, 2)
	hurt_taken.emit(hp)
	if hp <= 0:
		_die()
	return true


func _hurt_state(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
	_gravity(delta)
	if st_t >= HURT_LOCK:
		st = St.NORMAL
		st_t = 0.0


func _die() -> void:
	st = St.DEAD
	st_t = 0.0
	hurt_flicker = 0.0
	art.dissolve()
	EVfx.dark_bits(center(), 22, 220.0, Vector2.UP, 180.0, 0.7, 6)
	EVfx.dark_burst(center(), 30.0)
	Fx.slowmo(0.35, 0.5)
	died.emit()


## 장면이 부르는 부활: 자리를 옮기고 체력을 채운 뒤 공간 틈에서 나타난다
func respawn(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	hp = MAX_HP
	st = St.NORMAL
	st_t = 0.0
	invuln = RESPAWN_INVULN
	hurt_flicker = RESPAWN_INVULN
	art.revive()
	EMoveFx.blink_in(center(), facing)
	art.squash(Vector2(0.7, 1.35))
	hurt_taken.emit(hp)
