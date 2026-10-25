class_name EEska
extends CharacterBody2D
## 에스카(종언의 마녀) — 이동과 몸의 바탕. 에스카 프로젝트(cc/vigilant-dirac-751x7b, game/proto/eska/e_eska.gd)에서 옮겼다.
## 조작: 이동(떠서 활주) · 점프 + 이단점프(공중에서 한 번) · 순간이동(지상은 자유, 공중은 착지 전까지 1번)
## 공격은 빗자루 검 BEska가 맡는다. 원본의 기본 베기·고급 마법(천열·단공·낙성)·대마법·물약·종언 게이지·경로 찢기는 뺐다
## (St 상태 이름과 그림(EArt)이 읽는 변수는 그림 코드를 고치지 않으려고 남겨 두었다).
## 공격 판정은 물리 없이 표적(ETarget: 허수아비·적)의 hit_rect()와 부채꼴·선분으로 계산한다.

enum St { NORMAL, BLINK, CAST, HURT, DEAD, ULT, ITEM }

signal hurt_taken(hp: int) ## 맞았을 때 (남은 체력)
signal died ## 쓰러졌을 때 — 장면이 부활시킨다 (respawn)
signal respawned ## 부활했을 때 (화면 표시가 터치 장면 안내를 다시 보여 줌)

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
const ACTION_BUFFER := 0.12 ## 순간이동·스킬·모드 바꾸기 입력 기억 — 동작·피격 경직 중에 눌러도 끝나는 순간 꺼내 쓴다
const FAST_FALL_MAX := 440.0 ## 공중에서 ↓를 누르고 있으면
const COMBO_WINDOW := 1.6 ## 이 시간 안에 다시 맞히면 연타 수가 이어진다

# 순간이동
const BLINK_DIST := 150.0 ## 약 9타일 (100에서 1.5배)
const BLINK_GONE := 0.07 ## 사라져 있는 시간
const BLINK_CD := 0.26
const BLINK_INVULN := 0.2 ## 순간이동 무적 (사라짐 0.07초 + 나타난 뒤 0.13초)

# 체력·피격
const MAX_HP := 6
const HURT_LOCK := 0.3 ## 맞은 뒤 조작이 막히는 시간
const HURT_INVULN := 1.1 ## 맞은 뒤 무적(깜빡임)
const RESPAWN_INVULN := 1.6 ## 부활 뒤 무적

const SIGIL := 1.4 ## 베기·스킬 때 손끝 문장 크기

## 베기(기본 공격) — 예전 4타의 가장 큰 가로 참격 하나. 납작한 회오리(sq)를 rot만큼 기울인 호를 a0 → a1로 휘두른다 (각도는 도, 0 = 앞, + = 아래)
## hit 판정 시각 · r 반지름 · w 가장 굵은 곳 · c 몸 기준 중심. 참격은 튕긴 자리에 걸리고, 몸이 움직여도 그 자리에서 벤다
const SLASH := {"dur": 0.34, "hit": 0.06, "a0": -200.0, "a1": 160.0, "r": 140.0, "w": 44.0, "sq": 0.4, "rot": -8.0, "c": Vector2(6, -26), "dmg": 70}
const SLASH_RECOVER := 0.32 ## 다음 베기까지 (후딜) — 초당 약 220 피해 (예전 연격 약 200)
const SLASH_POSE := 0.22 ## 손짓이 보이는 시간

var st := St.NORMAL
var st_t := 0.0
var facing := 1
var art: EArt
var cooldowns := {} ## (원본: 고급 마법 쿨다운 — 이 프로토타입엔 없음)

var _coyote := 0.0
var _jump_buf := 0.0
var _atk_buf := 0.0
var _was_floor := true

var slash_t := 9.0 ## 마지막 베기 뒤 시간 (그림이 손짓에 씀)
var _atk_cd := 0.0
var _air_hang := true ## 공중 첫 베기는 살짝 떠오름 (착지 전까지 1번)
var _air_jump := true ## 이단점프 남았는지 (착지하면 다시)
var _ghost_t := 0.0 ## 활주 잔상 간격

var _air_blink := true
var _blink_cd := 0.0
var _blink_dir := 1
var _blink_to := Vector2.ZERO
var _buf_blink := 0.0
var _buf_skill := 0.0
var _phys_seen := -1 ## 지난 _process 때의 물리 틱 번호 (멈춤 중 누름 놓치지 않기)

## 그림(EArt)이 읽는 값 — 이 프로토타입에선 쓰지 않아 늘 기본값
var cast_kind := ""
var item_kind := ""
var last_potion_slot := -1

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
	art = _make_art()
	art.body = self
	add_child(art)


## 그림 노드 (하위 클래스가 다른 그림을 쓸 때 바꾼다 — 빗자루 검 데모 BArt)
func _make_art() -> EArt:
	return EArt.new()


func center() -> Vector2:
	return global_position + Vector2(0, -SIZE.y * 0.55)


# ═══════════════════════════════════════════════════════════
# 한 프레임
# ═══════════════════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	st_t += delta
	_blink_cd = maxf(_blink_cd - delta, 0.0)
	_atk_cd = maxf(_atk_cd - delta, 0.0)
	slash_t += delta
	invuln = maxf(invuln - delta, 0.0)
	combo_left = maxf(combo_left - delta, 0.0)
	if combo_left <= 0.0:
		hit_count = 0
		hit_damage = 0
	_coyote = COYOTE if is_on_floor() else maxf(_coyote - delta, 0.0)
	_jump_buf = maxf(_jump_buf - delta, 0.0)
	_atk_buf = maxf(_atk_buf - delta, 0.0)
	_buf_blink = maxf(_buf_blink - delta, 0.0)
	_buf_skill = maxf(_buf_skill - delta, 0.0)
	_poll_presses()
	hurt_flicker = maxf(hurt_flicker - delta, 0.0)
	var dir_x := Input.get_axis("es_left", "es_right")
	if controls_locked:
		dir_x = 0.0
		_jump_buf = 0.0
		_atk_buf = 0.0
		_forget_inputs()
	match st:
		St.NORMAL:
			_normal(delta, dir_x)
		St.BLINK:
			_blink(delta)
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
	_try_jump(dir_x)
	_gravity(delta)
	_try_actions(dir_x)


## 점프·이단점프 (기억해 둔 점프 입력이 있으면). 뛰었으면 true
func _try_jump(dir_x: float) -> bool:
	if _jump_buf > 0.0 and _coyote > 0.0:
		_jump_buf = 0.0
		_coyote = 0.0
		velocity.y = -JUMP_SPEED
		art.squash(Vector2(0.82, 1.2))
		if is_on_floor():
			PVfx.dust(global_position, 4, 1.0, 14.0)
		Sfx.play(&"jump", -6.0)
		return true
	if _jump_buf > 0.0 and _air_jump and not is_on_floor():
		_double_jump(dir_x)
		return true
	return false


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


## 입력 기억: 눌린 순간을 기억한다 (점프 JUMP_BUFFER · 공격 ATTACK_BUFFER · 나머지 ACTION_BUFFER초, 상태와 상관없이).
## 꺼내 쓰는 건 평소 상태의 _try_actions (피격 경직이 끝나는 순간 _resume이 바로 부름)
func _poll_presses() -> void:
	if Input.is_action_just_pressed("es_jump"):
		_jump_buf = JUMP_BUFFER
	if Input.is_action_just_pressed("es_attack"):
		_atk_buf = ATTACK_BUFFER
	if controls_locked or st == St.DEAD:
		return
	if Input.is_action_just_pressed("es_blink"):
		_buf_blink = ACTION_BUFFER
	if Input.is_action_just_pressed("es_skill"):
		_buf_skill = ACTION_BUFFER


## 멈춤(히트스톱)으로 시간이 거의 멈춘 프레임엔 물리 틱이 돌지 않아 그 프레임의 짧은 누름을 물리에서 못 본다 →
## 이번 프레임에 물리 틱이 한 번도 없었으면 여기서 대신 기억해 둔다 (기억 시간은 물리 틱에서만 줄어서 멈춤이 풀린 뒤 꺼내 씀)
func _process(_delta: float) -> void:
	var pf := Engine.get_physics_frames()
	if pf == _phys_seen:
		_poll_presses()
	_phys_seen = pf


func _forget_inputs() -> void:
	_buf_blink = 0.0
	_buf_skill = 0.0


## 피격 경직이 끝남: 평소 상태로 돌아가며 그동안 기억해 둔 입력(ACTION_BUFFER)을 같은 프레임에 꺼낸다
func _resume() -> void:
	st = St.NORMAL
	st_t = 0.0
	_try_actions(Input.get_axis("es_left", "es_right"))


func _can_blink() -> bool:
	return _blink_cd <= 0.0 and (is_on_floor() or _air_blink)


## 동작 시작 (상태가 바뀌면 true). 기억해 둔 입력을 여기서 꺼낸다. 공격·스킬은 하위 클래스(BEska)가 맡는다
func _try_actions(dir_x: float) -> bool:
	if controls_locked:
		return false
	if _buf_blink > 0.0 and _can_blink():
		_buf_blink = 0.0
		_start_blink(dir_x)
		return true
	return false


## 부채꼴(납작함 sq) 안에 사각형이 걸치는지. 각도는 앞 기준(도)
## 기울인(rot, 도) 납작한(sq) 호 안에 rect가 들어오는지 — 그림(Slash)과 같은 변환을 거꾸로 적용
func _sector_hits(rect: Rect2, cen: Vector2, r: float, a0: float, a1: float, sq: float, rot := 0.0, dir := 0) -> bool:
	sq = maxf(sq, 0.6) # 그림은 납작한 회오리지만 판정은 위아래로 넉넉하게 (공중에서도 맞게)
	var f := dir if dir != 0 else facing # 방향 (0 = 지금 바라보는 쪽)
	var unrot := -deg_to_rad(rot) * float(f)
	var lo := deg_to_rad(minf(a0, a1)) - 0.25
	var hi := deg_to_rad(maxf(a0, a1)) + 0.25
	var p0 := rect.position
	var p1 := rect.end
	var m := rect.get_center()
	for pt: Vector2 in [m, p0, p1, Vector2(p0.x, p1.y), Vector2(p1.x, p0.y), Vector2(m.x, p0.y), Vector2(m.x, p1.y), Vector2(p0.x, m.y), Vector2(p1.x, m.y)]:
		var q := (pt - cen).rotated(unrot)
		q.x *= f
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


## 피해 한 번 (이펙트 노드들도 이걸 부른다). opts: "poise" = 강자 버팀을 깎는 양(기본 = 피해)
func deal(d: Node2D, dmg: int, heavy: bool, from: Vector2, opts := {}) -> void:
	if not is_instance_valid(d):
		return
	d.take_hit(dmg, from, {"heavy": heavy, "launch": 1.5 if heavy else 0.0, "poise": opts.get("poise", dmg)})
	hit_count += 1
	hit_damage += dmg
	combo_left = COMBO_WINDOW
	EVfx.hit_crack(d.center() + Vector2(randf_range(-4, 4), randf_range(-8, 8)), heavy, signf(d.global_position.x - from.x))
	Sfx.play(&"hit_heavy" if heavy else &"hit", -6.0 if not heavy else -2.0)


## 그림(EArt)이 읽는 물약 동작 진행도 — 이 프로토타입엔 물약이 없어 늘 0
func item_progress() -> float:
	return 0.0


func item_fired() -> bool:
	return false


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
	invuln = BLINK_INVULN
	var to_c := _blink_to + Vector2(0, -SIZE.y * 0.55)
	EMoveFx.blink_out(art, center(), d)
	EMoveFx.blink_trail(art, center(), to_c, not is_on_floor())
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
# 체력 · 피격 · 쓰러짐 · 부활
# ═══════════════════════════════════════════════════════════

## 맞는 판정 사각형 (전역)
func hurt_rect() -> Rect2:
	return Rect2(global_position + Vector2(-SIZE.x * 0.5, -SIZE.y), SIZE)


func is_dead() -> bool:
	return st == St.DEAD


## 적에게 맞음 (맞았으면 true). 순간이동 중·무적 중엔 안 맞는다
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
		_resume()


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
	respawned.emit()
