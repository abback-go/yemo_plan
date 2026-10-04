extends EnemyBase
## 별똥 도마뱀 (docs/chapter2.md 4절) — 별 조각을 삼킨 도마뱀. 빛나는 공처럼 몸을 말아 바닥·벽·천장을 타고 굴러다닌다.
## 구를 때는 등껍질이 단단해 피해 30%. 멈춰서 몸을 펴면(0.6초, 등 수정이 붉게) 별 조각 3발을 뿜는다 → 그 뒤 1.2초가 빈틈(피해 100%).
## 빈틈에 묵직한 공격(강한 화염탄·불기둥·폭풍 마지막 타)을 맞으면 벌러덩 뒤집혀 1초 동안 피해 150%.
## 천장·벽에 붙은 채로도 멈춰 쏜다. 별 조각은 불꽃 방벽으로 되쏠 수 있다.

const KE := preload("res://enemies/ch2/k_enemy.gd")
const KArt := preload("res://world/entities/ch2/k_art.gd")

enum S { ROLL, BRAKE, UNCURL, FIRE, OPEN, CURL, FLIPPED, FALL }

const HP := 450
const R := 8.0 ## 몸 반지름 (공 상태)
const ROLL_SPEED_T := 7.0
const ROLL_TIME := Vector2(2.4, 3.6)
const BRAKE_TIME := 0.25
const UNCURL_TIME := 0.6
const SHOT_GAP := 0.18
const SHOT_SPEED_T := 9.0
const OPEN_TIME := 1.2
const CURL_TIME := 0.3
const FLIP_TIME := 1.0
const ROLL_MULT := 0.3
const FLIP_MULT := 1.5
const HEAVY := Hit.HEAVY_LIZARD
const SHELL := Color("#4a4058")
const SHELL_L := Color("#7a6a94")
const SHELL_D := Color("#241c30")
const BELLY := Color("#c8b0a0")
const CRYSTAL := Color("#c89aff")

var state: S = S.FALL
var surf := Vector2.UP ## 붙어 있는 면에서 바깥으로 향하는 방향 (바닥이면 위)
var roll_dir := 1 ## 면을 따라 도는 방향 (+1: 면을 왼쪽에 두고 시계 방향)
var _clock := StateClock.new() ## 상태 시간 (남은 시간·길이·진행도)
var _shots := 0
var _spin := 0.0
var _stuck := 0.0
var _last_pos := Vector2.ZERO
var _turn_cd := 0.0
var _contact: EnemyAttackArea
var _face_local := 1.0 ## 몸을 편 그림이 면 위에서 바라보는 쪽 (회전된 좌표 기준)


func _build() -> void:
	max_hp = HP
	body_size = Vector2(16, 16)
	knock_mult = 0.0
	launch_mult = 0.0
	flying = true
	display_name = "별똥 도마뱀"
	subtitle = "별 조각을 삼킨 굴렁쇠"
	kind_id = "star_lizard"
	var v := KE.Vis.new()
	v.enemy = self
	v.fn = _draw_body
	v.flip = false
	v.position = Vector2(0, -R)
	_visual = v
	add_child(v)
	_contact = add_attack_area(Vector2(14, 14), Vector2(0, -R), &"star_lizard", 1)


func _ready() -> void:
	super()
	collision_mask = GameConst.L_WORLD # 통과 발판은 무시 (벽·천장만 타고 다님)
	_enter(S.FALL, 0.0)


func _enter(s: S, d: float) -> void:
	state = s
	_clock.enter(d)


func progress() -> float:
	return _clock.k()


## 면을 따라 가는 방향
func _tan() -> Vector2:
	return Vector2(-surf.y, surf.x) * roll_dir


func _center() -> Vector2:
	return global_position + Vector2(0, -R)


func _ray(from: Vector2, to: Vector2) -> Dictionary:
	var q := PhysicsRayQueryParameters2D.create(from, to, GameConst.L_WORLD)
	q.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(q)


func _ai(delta: float) -> void:
	var t := GameConst.TILE
	_clock.tick(delta)
	_turn_cd -= delta
	_contact.active = engaged and _alive
	_contact.dodgeable = state == S.ROLL
	var p := player()
	_visual.rotation = Vector2.UP.angle_to(surf) if state != S.FALL else 0.0
	if p:
		var loc := (p.center() - _center()).rotated(-_visual.rotation)
		if absf(loc.x) > 2.0:
			_face_local = signf(loc.x)
	if not engaged:
		velocity = Vector2.ZERO
		return
	match state:
		S.FALL:
			flying = false
			surf = Vector2.UP
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			if is_on_floor():
				flying = true
				velocity = Vector2.ZERO
				_face_roll_toward_player()
				_enter(S.ROLL, randf_range(ROLL_TIME.x, ROLL_TIME.y))
		S.ROLL:
			_roll(delta, ROLL_SPEED_T * t)
			if _clock.done():
				_enter(S.BRAKE, BRAKE_TIME)
		S.BRAKE:
			_roll(delta, ROLL_SPEED_T * t * clampf(_clock.left / BRAKE_TIME, 0.0, 1.0))
			if _clock.done():
				velocity = Vector2.ZERO
				_enter(S.UNCURL, Difficulty.telegraph(UNCURL_TIME))
				KE.snd(&"star_twinkle", &"pillar_warn", -4.0)
		S.UNCURL:
			velocity = _press()
			if p:
				facing = 1 if p.global_position.x >= global_position.x else -1
			if _clock.done():
				_shots = 0
				_enter(S.FIRE, 0.0)
		S.FIRE:
			velocity = _press()
			if _clock.done():
				_fire()
				_shots += 1
				_clock.left = SHOT_GAP
				if _shots >= 3:
					_enter(S.OPEN, Difficulty.rest(OPEN_TIME))
		S.OPEN, S.FLIPPED:
			velocity = _press()
			if _clock.done():
				_enter(S.CURL, CURL_TIME)
				KE.snd(&"crumble", &"crumble", -10.0)
		S.CURL:
			velocity = _press()
			if _clock.done():
				_face_roll_toward_player()
				_enter(S.ROLL, randf_range(ROLL_TIME.x, ROLL_TIME.y))


func _press() -> Vector2:
	return -surf * 30.0


## 플레이어 쪽으로 굴러가도록 방향을 고른다 (지금 면의 접선 기준)
func _face_roll_toward_player() -> void:
	var p := player()
	if p == null:
		return
	var to := p.global_position - global_position
	roll_dir = 1
	if _tan().dot(to) < 0.0:
		roll_dir = -1


## 면 따라 구르기: 앞에 벽이 있으면 그 벽으로 올라타고(오목 모서리), 발밑 면이 끝나면 모서리를 돌아 넘어간다(볼록 모서리)
func _roll(delta: float, speed: float) -> void:
	var c := _center()
	var tan := _tan()
	_spin += delta * speed / R * roll_dir
	if _turn_cd <= 0.0:
		var ahead := _ray(c, c + tan * (R + 3.0))
		if not ahead.is_empty():
			# 오목 모서리: 앞의 벽이 새 바닥
			var n: Vector2 = ahead.normal
			surf = n.round()
			_turn_cd = 0.12
			tan = _tan()
		else:
			var below := _ray(c, c - surf * (R + 5.0))
			if below.is_empty():
				# 볼록 모서리(발판 끝·천장 끝): 떨어진다 — 방 밖으로 기어 나가지 않게
				_enter(S.FALL, 0.0)
				return
	velocity = tan * speed + _press()
	# 오래 제자리면(끼임) 떨어뜨림
	if global_position.distance_to(_last_pos) < 0.3:
		_stuck += delta
		if _stuck > 0.5:
			_stuck = 0.0
			_enter(S.FALL, 0.0)
	else:
		_stuck = 0.0
	_last_pos = global_position
	if int(_t * 20.0) % 3 == 0:
		Fx.burst(c - surf * R, 1, {direction = surf - tan, spread = 40.0, speed_min = 20.0, speed_max = 60.0, lifetime = 0.3,
			gradient = KE.grad(Color(KE.STAR_HOT, 0.9), Color(CRYSTAL, 0.0)), size_min = 1.0, size_max = 2.0, gravity = Vector2.ZERO, add = true})


func _fire() -> void:
	var p := player()
	if p == null:
		return
	var mouth := _center() + Vector2(_face_local * 10.0, -1.0).rotated(_visual.rotation)
	var aim := (p.center() - mouth).normalized()
	var spread: float = [-0.2, 0.0, 0.2][_shots % 3]
	KE.shard(mouth, aim.rotated(spread), SHOT_SPEED_T * GameConst.TILE, {"radius": 3.0, "life": 3.0})
	KE.snd(&"star_twinkle", &"sniper_shot", -4.0)
	KE.star_burst(mouth, 5, CRYSTAL, 60.0, 0.25)


func modify_damage(hit: Hit) -> float:
	match state:
		S.ROLL, S.BRAKE, S.FALL:
			return ROLL_MULT
		S.FLIPPED:
			return FLIP_MULT
	return 1.0


func _on_hit(hit: Hit, _dir: int) -> void:
	if state == S.ROLL or state == S.BRAKE:
		# 등껍질에 튕김
		Fx.burst(_center(), 6, {spread = 180.0, speed_min = 40.0, speed_max = 100.0, lifetime = 0.2,
			gradient = Palette.fade_gradient(SHELL_L), size_min = 1.0, size_max = 2.0})
		KE.snd(&"block", &"block", -8.0)
	elif state == S.OPEN and hit.kind in HEAVY:
		_enter(S.FLIPPED, FLIP_TIME)
		KE.snd(&"crumble", &"crumble", -4.0)
		KE.star_burst(_center(), 10, CRYSTAL, 90.0, 0.4)


func _die(dir: int) -> void:
	KE.death_fx(_center(), CRYSTAL)
	KE.debris(_center(), 10, SHELL_L, Vector2(dir, -1))
	super(dir)


# ─── 그림 ───────────────────────────────────────────────

func _draw_body(c: Node2D) -> void:
	var white := flash_amount() > 0.0
	var curled := state in [S.ROLL, S.BRAKE, S.FALL, S.CURL] or (state == S.UNCURL and progress() < 0.35)
	if state == S.CURL:
		curled = progress() > 0.5
	if curled:
		_draw_ball(c, white)
	else:
		_draw_lizard(c, white)


func _col(c: Color, white: bool) -> Color:
	return Color(1, 1, 1) if white else c


func _draw_ball(c: Node2D, white: bool) -> void:
	# 빛나는 공: 바위 껍데기 조각이 돌고, 틈새에서 별빛
	var glow := 0.7 + 0.3 * sin(_t * 8.0)
	KArt.glow(c, Vector2.ZERO, R * 3.2, Color(CRYSTAL, 1.0 * glow), 4)
	# 굴러온 자리의 별빛 꼬리 (면을 따라 뒤로)
	var back := -_tan().rotated(-c.rotation) if state != S.FALL else Vector2.ZERO
	for i in 4:
		var tp := back * (5.0 + i * 5.0)
		c.draw_circle(tp, R * (0.8 - i * 0.16), Color(CRYSTAL, 0.35 - i * 0.07))
	c.draw_circle(Vector2.ZERO, R + 1.0, KE.OUT)
	c.draw_circle(Vector2.ZERO, R, _col(SHELL, white))
	c.draw_circle(Vector2.ZERO, R - 2.0, _col(SHELL.lerp(CRYSTAL, 0.25), white))
	for i in 5:
		var a := _spin + TAU * i / 5.0
		var p0 := Vector2(cos(a), sin(a))
		c.draw_line(p0 * 2.0, p0 * (R - 0.5), _col(Color(CRYSTAL.lightened(0.5), glow), white), 1.5)
		var plate := PackedVector2Array([p0 * (R - 0.2), Vector2(cos(a + 0.5), sin(a + 0.5)) * (R - 0.2), Vector2(cos(a + 0.25), sin(a + 0.25)) * (R - 3.5)])
		c.draw_colored_polygon(plate, _col(SHELL_L if i % 2 == 0 else SHELL_D, white))
	c.draw_circle(Vector2.ZERO, 3.5, Color(CRYSTAL.lightened(0.4), glow))
	c.draw_circle(Vector2.ZERO, 2.0, Color(1, 0.97, 1.0, 1.0))
	# 꼬리 끝이 살짝 삐져나옴
	var ta := _spin + 2.2
	c.draw_line(Vector2(cos(ta), sin(ta)) * R, Vector2(cos(ta + 0.4), sin(ta + 0.4)) * (R + 3.0), _col(SHELL_L, white), 2.0)


func _draw_lizard(c: Node2D, white: bool) -> void:
	# 몸을 편 도마뱀 (오른쪽을 보는 기준, 면 위에 엎드림). 몸 원점 = 몸 가운데
	var f := _face_local
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2(f, 1.0))
	var k := progress() if state == S.UNCURL else 1.0
	var warn := state == S.UNCURL
	var flipped := state == S.FLIPPED
	var body_y := 3.0
	var pant := sin(_t * 10.0) * 0.6 if state == S.OPEN else 0.0
	if flipped:
		# 벌러덩: 배를 보이고 다리를 버둥
		c.draw_set_transform(Vector2(0, 2), PI, Vector2(f, 1))
	# 꼬리 (말려 있음)
	var tail := PackedVector2Array()
	for i in 7:
		var tk := i / 6.0
		var a := PI * 0.9 + tk * 2.6 * k + sin(_t * 3.0 + tk * 2.0) * 0.15
		tail.append(Vector2(-6, body_y - 1) + Vector2(cos(a) * (4.0 + tk * 3.0), sin(a) * (3.0 + tk * 2.0) * 0.7))
	c.draw_polyline(tail, KE.OUT, 4.0)
	c.draw_polyline(tail, _col(SHELL, white), 2.4)
	# 다리 넷 (버둥대거나 디딤)
	for i in 4:
		var lx := -5.0 + i * 3.6
		var wig := sin(_t * (30.0 if flipped else 6.0) + i * 1.7) * (2.0 if flipped else 0.4)
		c.draw_line(Vector2(lx, body_y + 1), Vector2(lx + (1.5 if i % 2 == 0 else -1.5), body_y + 4 + wig), _col(SHELL_D, white), 1.6)
	# 몸통 (위 껍질 + 밝은 배)
	var body := PackedVector2Array([Vector2(-9, body_y + 1), Vector2(-7, body_y - 4 - pant), Vector2(0, body_y - 6 - pant), Vector2(7, body_y - 4), Vector2(9, body_y), Vector2(5, body_y + 2.5), Vector2(-6, body_y + 2.5)])
	c.draw_colored_polygon(_grow(body), KE.OUT)
	c.draw_colored_polygon(body, _col(SHELL, white))
	c.draw_rect(Rect2(-6, body_y + 1, 11, 1.5), _col(BELLY, white))
	c.draw_line(Vector2(-6, body_y - 4), Vector2(5, body_y - 5), _col(SHELL_L, white), 1.0)
	# 등의 별 수정 (예고 때 붉게)
	for i in 3:
		var sx := -4.0 + i * 3.6
		var hh := 3.0 + (i % 2) * 2.0
		var cc := CRYSTAL
		if warn:
			cc = CRYSTAL.lerp(KE.DANGER, KE.warn_pulse(_t, k))
		var tip := Vector2(sx + 0.5, body_y - 5 - pant - hh)
		c.draw_colored_polygon(PackedVector2Array([Vector2(sx - 1.4, body_y - 4.5 - pant), tip, Vector2(sx + 1.6, body_y - 4.5 - pant)]), _col(cc, white))
		if not white:
			c.draw_circle(tip, 1.5 + (2.0 if warn else 0.0) * k, Color(cc, 0.35))
	# 머리 + 빛나는 눈 + (쏠 때) 벌린 입
	var hc := Vector2(9.5, body_y - 2.5)
	c.draw_circle(hc, 3.6, KE.OUT)
	c.draw_circle(hc, 3.0, _col(SHELL, white))
	c.draw_rect(Rect2(hc + Vector2(1, -2), Vector2(1.5, 1.5)), _col(Color(1, 0.95, 0.6) if not warn else KE.DANGER, white))
	if state == S.FIRE:
		c.draw_colored_polygon(PackedVector2Array([hc + Vector2(1, 0.5), hc + Vector2(5, -0.5), hc + Vector2(5, 2.5)]), Color("#ffe0ff"))
		KArt.glow(c, hc + Vector2(4, 1), 6.0, Color(CRYSTAL, 0.8), 3)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if flipped:
		for i in 3:
			var a2 := _t * 6.0 + TAU * i / 3.0
			c.draw_rect(Rect2(Vector2(cos(a2) * 6.0, -8 + sin(a2) * 2.0), Vector2(2, 2)), Palette.GOLD)


func _grow(pts: PackedVector2Array) -> PackedVector2Array:
	var cc := Vector2.ZERO
	for p in pts:
		cc += p
	cc /= pts.size()
	var out := PackedVector2Array()
	for p2 in pts:
		out.append(p2 + (p2 - cc).normalized())
	return out
