class_name Grimoire
extends EnemyBase
## 마도서 (docs/archive/sera/chapter1.md 7절·12.2절·12.4절·12.5절): 서가 미로의 정예. 표지에 외눈이 달린 살아 있는 금서.
## 책장 사이를 순간이동하며 페이지 탄을 쏜다: 5장 부채꼴 / 느린 유도 페이지 2장.
## 400 피해마다 책을 덮어 1.2초 무적(맞으면 "팅") → 펼치며 사방으로 페이지 고리. 덮을 때마다 다음 페이지 패턴이 바뀐다.
## 펼친 직후 잠깐 제자리에 머무는 때가 집중 공격할 틈.
## 순간이동은 home에서 10T 안, 벽 속이 아니고 세라가 보이는 곳으로만 간다. 멀리 밀려나면 home 근처로 돌아온다.
## 여우불에 맞으면 페이지가 탄다(피해 1.3배 + 푸른 불티).

enum S { HOVER, WINDUP, VOLLEY, TELE_OUT, TELE_IN, CLOSED, BURST }
enum A { FAN, HOMING }

const HP := 600
const CLOSE_EVERY := 400 ## 이만큼 피해를 받을 때마다 책을 덮는다 (v0.4 묵직한 한 발: 150 → 400, 두 발마다)
const CLOSED_TIME := 1.2
const TELE_RANGE_T := 10.0 ## home에서 순간이동할 수 있는 거리
const LEASH_T := 12.0 ## home에서 이보다 멀어지면 home 근처로 순간이동
const HOVER_TIME := 1.1
const FAN_WINDUP := 0.55
const HOMING_WINDUP := 0.6
const TELE_OUT_TIME := 0.35
const TELE_IN_TIME := 0.3
const PAGE_SPEED_T := 9.0
const HOMING_SPEED_T := 4.5
const HOMING_TURN := 1.2 ## 유도 페이지 회전 (rad/s)
const RING_SPEED_T := 6.5
const AFTER_BURST_TIME := 1.4 ## 펼친 뒤 제자리에 머무는 시간 (집중 공격할 틈)
const FOX_MULT := 1.3
const MANA := Color("#b77bff") ## 폭주 마력
const FOX_BLUE := Color(0.55, 0.85, 1.0)

var home := Vector2.ZERO ## 돌아올 자리. _ready에서 처음 위치로 정해지고, 대본이 옮겨도 된다
var state: S = S.HOVER
var pattern := 0 ## 책을 덮을 때마다 1씩 늘어 페이지 패턴이 바뀐다
var open_amount := 0.3 ## 표지가 열린 정도 0~1 (그림이 읽는다)
var burn := 0.0 ## 여우불에 탄 채 남은 시간 (그림이 읽는다)
var _timer := 0.0
var _state_time := 0.0
var _anchor := Vector2.ZERO
var _action: A = A.FAN
var _next_attack: A = A.FAN
var _actions_since_tele := 0
var _dmg_acc := 0
var _volley_left := 0
var _volley_t := 0.0
var _volley_kind := 0 ## 0 = 엇갈린 두 번째 부채꼴, 1 = 한 장씩 휩쓸기
var _volley_i := 0
var _volley_base := Vector2.RIGHT
var _hidden := false
var _wisp_t := 0.0
var _contact: EnemyAttackArea


func _build() -> void:
	max_hp = HP
	body_size = Vector2(28, 32)
	flying = true
	knock_mult = 0.3
	launch_mult = 0.0
	display_name = "마도서"
	subtitle = "반납 기한을 넘긴 책"
	kind_id = "grimoire"
	var v := GrimoireVisual.new()
	v.enemy = self
	_visual = v
	add_child(v)
	_contact = add_attack_area(Vector2(26, 30), Vector2(0, -16), &"grimoire")
	_contact.dodgeable = false


func _ready() -> void:
	super()
	collision_mask = GameConst.L_WORLD # 나는 적이라 통과 발판에는 걸리지 않는다
	if home == Vector2.ZERO:
		home = global_position
	_anchor = global_position
	_set_state(S.HOVER, 1.2)


## 몸 가운데
func center() -> Vector2:
	return global_position + Vector2(0, -16)


## 상태 진행도 0→1 (연출용)
func progress() -> float:
	if _state_time <= 0.0:
		return 1.0
	return clampf(1.0 - _timer / _state_time, 0.0, 1.0)


## 순간이동 중 크기·투명도 (1 = 보통, 0 = 사라짐)
func tele_scale() -> float:
	if state == S.TELE_OUT:
		return 1.0 - progress()
	if state == S.TELE_IN:
		return progress()
	return 1.0


func _set_state(s: S, time := 0.0) -> void:
	state = s
	_timer = time
	_state_time = time


func _ai(delta: float) -> void:
	burn = maxf(burn - delta, 0.0)
	open_amount = move_toward(open_amount, _open_target(), delta * (8.0 if state == S.CLOSED or state == S.BURST else 3.0))
	_leak(delta)
	var p := player()
	if p != null and not p.is_alive():
		p = null
	if not engaged:
		_hover_move(delta)
		return
	_timer -= delta
	match state:
		S.HOVER:
			_hover_move(delta)
			if p:
				face_player()
			if _timer <= 0.0 and p:
				_decide(p)
		S.WINDUP:
			_hover_move(delta)
			if p:
				face_player()
			if _timer <= 0.0:
				_fire(p)
		S.VOLLEY:
			_hover_move(delta)
			_volley_t -= delta
			if _volley_left > 0 and _volley_t <= 0.0:
				_volley_shot(p)
			if _volley_left <= 0 and _volley_t <= 0.0:
				_set_state(S.HOVER, HOVER_TIME)
		S.TELE_OUT:
			velocity = Vector2.ZERO
			if not _hidden and progress() > 0.6:
				_set_hidden(true)
			if _timer <= 0.0:
				var spot := _pick_spot(p)
				global_position = spot
				_anchor = spot
				velocity = Vector2.ZERO
				_set_state(S.TELE_IN, TELE_IN_TIME)
				_page_puff(center(), 10)
				Sfx.play(&"page", -2.0, 0.2)
				Fx.ring(center(), 18.0, 4.0, MANA, 0.25, 1.0)
		S.TELE_IN:
			velocity = Vector2.ZERO
			if _hidden and progress() > 0.3:
				_set_hidden(false)
			if _timer <= 0.0:
				_set_state(S.HOVER, 0.6)
		S.CLOSED:
			velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
			if _timer <= 0.0:
				_burst_open()
		S.BURST:
			velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
			if _timer <= 0.0:
				_set_state(S.HOVER, AFTER_BURST_TIME)


func _open_target() -> float:
	match state:
		S.WINDUP:
			return 0.62
		S.VOLLEY:
			return 0.8
		S.CLOSED:
			return 0.0
		S.BURST:
			return 1.0
		S.TELE_OUT, S.TELE_IN:
			return 0.1
	return 0.22 + 0.16 * sin(_t * 3.0) # 숨 쉬듯 펄럭


## 기준점 둘레를 둥실 떠다닌다 (밀려나도 기준점으로 돌아온다)
func _hover_move(delta: float) -> void:
	var target := _anchor + Vector2(sin(_t * 1.3) * 6.0, sin(_t * 2.1) * 4.0)
	var want := ((target - global_position) * 3.0).limit_length(130.0)
	velocity = velocity.move_toward(want, 500.0 * delta)


func _decide(p: Player) -> void:
	var t := GameConst.TILE
	var far_home := global_position.distance_to(home) > LEASH_T * t
	var sees := _clear(center(), p.center()) and center().distance_to(p.center()) <= 16.0 * t
	if far_home or _actions_since_tele >= 2 or not sees:
		_actions_since_tele = 0
		_set_state(S.TELE_OUT, TELE_OUT_TIME)
		Sfx.play(&"whoosh", -4.0, 0.1)
		_page_puff(center(), 8)
		return
	_action = _next_attack
	_next_attack = A.HOMING if _action == A.FAN else A.FAN
	_actions_since_tele += 1
	_set_state(S.WINDUP, FAN_WINDUP if _action == A.FAN else HOMING_WINDUP)
	Sfx.play(&"page", -2.0, 0.2)
	Sfx.play_pitch(&"sniper_aim", 0.8 if _action == A.FAN else 0.6, -4.0)


func _aim(p: Player) -> Vector2:
	if p == null:
		return Vector2(facing, 0)
	return (p.center() - center()).normalized()


func _page(dir: Vector2, speed_t: float, homing := 0.0) -> void:
	var opts := {damage = 1, cause = "grimoire", radius = 4.0, life = 3.2}
	if homing > 0.0:
		opts["homing"] = homing
		opts["life"] = 5.0
	shoot(center() + dir * 10.0, dir, speed_t * GameConst.TILE, "page", opts)


func _fan(base: Vector2, count: int, spread_deg: float, speed_t: float, offset := 0.0) -> void:
	var spread := deg_to_rad(spread_deg)
	for i in count:
		var a := -spread * 0.5 + spread * (float(i) + offset) / maxf(float(count - 1), 1.0)
		_page(base.rotated(a), speed_t)


## 패턴별 발사. 책을 덮을 때마다 pattern이 바뀐다
func _fire(p: Player) -> void:
	var base := _aim(p)
	Sfx.play(&"page", 0.0, 0.2)
	Sfx.play(&"shoot", -8.0, 0.1)
	_page_puff(center() + base * 8.0, 6)
	var pat := mini(pattern, 3)
	if _action == A.FAN:
		match pat:
			0:
				_fan(base, 5, 56.0, PAGE_SPEED_T)
				_set_state(S.HOVER, HOVER_TIME)
			1:
				# 두 번: 두 번째는 사이사이를 메운다
				_fan(base, 5, 56.0, PAGE_SPEED_T)
				_start_volley(0, 1, 0.3, base)
			2:
				# 한 장씩 휩쓸기
				_start_volley(1, 9, 0.0, base)
			_:
				_fan(base, 7, 84.0, PAGE_SPEED_T)
				_start_volley(0, 1, 0.3, base)
	else:
		var n := 2 if pat < 2 else 3
		for i in n:
			var side := (float(i) - (n - 1) * 0.5) * 1.1
			_page(base.rotated(side + PI * 0.5 * signf(side) * 0.3), HOMING_SPEED_T, HOMING_TURN)
		if pat == 1 or pat >= 3:
			_fan(base, 3, 30.0, PAGE_SPEED_T * 0.8)
		_set_state(S.HOVER, HOVER_TIME)


func _start_volley(kind: int, count: int, first_delay: float, base: Vector2) -> void:
	_volley_kind = kind
	_volley_left = count
	_volley_t = first_delay
	_volley_i = 0
	_volley_base = base
	_set_state(S.VOLLEY, 0.0)


func _volley_shot(p: Player) -> void:
	_volley_left -= 1
	if _volley_kind == 0:
		# 엇갈린 두 번째 부채꼴 (세라의 새 위치를 노림)
		var count := 5 if mini(pattern, 3) < 3 else 7
		var spread := 56.0 if count == 5 else 84.0
		_fan(_aim(p), count - 1, spread * (count - 2) / (count - 1), PAGE_SPEED_T * 1.1)
		Sfx.play(&"page", 0.0, 0.2)
		_volley_t = 0.0
	else:
		# 휩쓸기: 110° 호를 한 장씩
		var a := deg_to_rad(-55.0 + 110.0 * float(_volley_i) / 8.0)
		_page(_volley_base.rotated(a), PAGE_SPEED_T)
		Sfx.play(&"page", -4.0, 0.2)
		_volley_i += 1
		_volley_t = 0.05
	if _volley_left <= 0:
		_volley_t = 0.35


## 책을 덮는다: 1.2초 무적
func _close() -> void:
	_volley_left = 0
	_set_state(S.CLOSED, CLOSED_TIME)
	velocity = Vector2.ZERO
	Sfx.play_pitch(&"slam", 1.7, -2.0)
	Sfx.play(&"chain", -4.0, 0.1)
	Fx.ring(center(), 6.0, 24.0, MANA, 0.3, 2.0)
	_page_puff(center(), 10)


## 펼치며 사방으로 페이지 고리. 다음 패턴으로
func _burst_open() -> void:
	pattern += 1
	var n := 10 + 2 * mini(pattern, 3)
	var off := PI / n if pattern % 2 == 0 else 0.0
	for i in n:
		_page(Vector2.from_angle(off + TAU * i / n), RING_SPEED_T)
	_set_state(S.BURST, 0.35)
	_actions_since_tele = 0
	Sfx.play(&"storm", -4.0, 0.1)
	Sfx.play(&"page", 0.0, 0.2)
	Fx.ring(center(), 4.0, 40.0, MANA.lightened(0.3), 0.35, 2.0)
	Fx.shake(0.1, 0.15)
	_page_puff(center(), 16)


func _set_hidden(v: bool) -> void:
	_hidden = v
	_hurtbox.set_deferred("monitorable", not v)
	_contact.active = not v


## 순간이동할 자리: home에서 10T 안, 벽 속이 아니고(점·몸 크기 검사), 세라가 보이는 곳
func _pick_spot(p: Player) -> Vector2:
	var t := GameConst.TILE
	var space := get_world_2d().direct_space_state
	var box := RectangleShape2D.new()
	box.size = body_size + Vector2(8, 8)
	var sq := PhysicsShapeQueryParameters2D.new()
	sq.shape = box
	sq.collision_mask = GameConst.L_WORLD
	var pq := PhysicsPointQueryParameters2D.new()
	pq.collision_mask = GameConst.L_WORLD
	var home_c := home + Vector2(0, -body_size.y / 2.0)
	for i in 28:
		var cand := home + Vector2(randf_range(-1.0, 1.0), randf_range(-0.7, 0.4)) * TELE_RANGE_T * t
		if cand.distance_to(home) > TELE_RANGE_T * t or cand.distance_to(global_position) < 3.0 * t:
			continue
		var c := cand + Vector2(0, -body_size.y / 2.0)
		pq.position = c
		if not space.intersect_point(pq, 1).is_empty():
			continue
		sq.transform = Transform2D(0.0, c)
		if not space.intersect_shape(sq, 1).is_empty():
			continue
		if not _clear(home_c, c): # home에서 닿는 곳 (방 밖으로 나가지 않게)
			continue
		if p:
			var d := c.distance_to(p.center())
			if d < 4.5 * t or d > 13.0 * t or not _clear(c, p.center()):
				continue
		return cand
	return home


func _clear(from: Vector2, to: Vector2) -> bool:
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(from, to, GameConst.L_WORLD)
	return space.intersect_ray(q).is_empty()


func take_hit(hit: Hit) -> void:
	if _hidden:
		return # 순간이동으로 사라진 동안엔 범위 공격(폭풍·여우비 등)에도 맞지 않는다
	var before := hp
	super(hit)
	if not _alive:
		return
	var dealt := before - hp
	if dealt <= 0:
		return
	_dmg_acc += dealt
	if _dmg_acc >= CLOSE_EVERY and state != S.CLOSED and state != S.BURST:
		_dmg_acc = mini(_dmg_acc - CLOSE_EVERY, CLOSE_EVERY - 1)
		_close()


func modify_damage(hit: Hit) -> float:
	if state == S.CLOSED:
		return 0.0
	return FOX_MULT if is_fox_hit(hit) else 1.0


func _on_hit(hit: Hit, _dir: int) -> void:
	if is_fox_hit(hit):
		burn = 2.0
		Sfx.play(&"ignite", -8.0, 0.1)
		Fx.burst(center(), 8, {
			direction = Vector2.UP, spread = 60.0, speed_min = 20.0, speed_max = 70.0, lifetime = 0.5,
			gradient = Palette.fade_gradient(FOX_BLUE), size_min = 1.0, size_max = 2.5, gravity = Vector2(0, -60), add = true,
		})


func _page_puff(pos: Vector2, amount: int) -> void:
	Fx.burst(pos, amount, {
		spread = 180.0, speed_min = 20.0, speed_max = 80.0, lifetime = 0.5, damping = 60.0,
		gradient = Palette.fade_gradient(Color("#e8dcc0")), size_min = 1.0, size_max = 2.5, gravity = Vector2(0, 40),
	})


## 폭주 마력(그리고 타는 중이면 푸른 불티)이 책장 사이로 샌다
func _leak(delta: float) -> void:
	_wisp_t -= delta
	if _wisp_t > 0.0 or _hidden:
		return
	_wisp_t = 0.12 if burn > 0.0 else 0.2
	var c := FOX_BLUE if burn > 0.0 else MANA
	Fx.burst(center() + Vector2(randf_range(-8, 8), randf_range(-8, 4)), 1, {
		direction = Vector2.UP, spread = 30.0, speed_min = 8.0, speed_max = 24.0, lifetime = 0.8,
		gradient = Palette.fade_gradient(c), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, -20), add = true,
	})
