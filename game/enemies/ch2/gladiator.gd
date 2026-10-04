extends EnemyBase
## 투기장 챔피언 가론 (docs/chapter2.md 4절·6절 서브 퀘스트 k_arena) — 미니보스. 삼지창과 그물, 관중을 사랑하는 쇼맨.
## 패턴 (예고 → 공격 → 빈틈):
##   그물 던지기: 머리 위로 그물을 돌림(0.6초) → 포물선으로 펼쳐지며 날아옴 → 맞으면 0.8초 묶임 + 곧바로 찌르기가 이어짐
##   삼지창 찌르기: 창을 뒤로 당김(0.5초, 창끝이 붉게) → 6칸 돌진 → 0.8초 헛디딤(빈틈)
##   뛰어 내려찍기: 웅크림(0.55초, 착지점 붉은 표시) → 도약 → 쿵! 양옆으로 돌 충격파(점프로 넘기)
##   관중 환호: 공격을 맞히거나 12초마다 두 팔을 들고 관중에게 환호를 받음(1.5초) → 끊지 못하면 8초 동안 금빛 "흥분"(빠르고 강해짐)
##             환호 중에 두 번 맞히거나(강한 공격은 한 번) 하면 머쓱해하며 1.2초 휘청 → 답: 환호를 끊어라.
## is_boss = true(화면 아래 체력바). engaged = false로 두면 대본이 시작 신호를 줄 때까지 기다린다.

signal cheered ## 관중 환호를 받아 흥분했을 때

const KE := preload("res://enemies/ch2/k_enemy.gd")
const KArt := preload("res://world/entities/ch2/k_art.gd")

enum S { IDLE, STALK, NET_WINDUP, NET_THROW, THRUST_WINDUP, THRUST, OVEREXTEND, LEAP_CROUCH, LEAP, SLAM, TAUNT, FLUSTER, RECOVER }

const HP := 1800
const WALK_T := 2.4
const NET_WINDUP := 0.6
const THRUST_WINDUP := 0.5
const THRUST_SPEED_T := 16.0
const THRUST_MAX_T := 6.0
const OVEREXTEND := 0.8
const LEAP_CROUCH := 0.55
const LEAP_TIME := 0.6
const SLAM_TIME := 0.5
const TAUNT_TIME := 1.5
const FLUSTER_TIME := 1.2
const HYPE_TIME := 8.0
const TAUNT_EVERY := 12.0
const NET_BIND := 0.8
const SKIN := Color("#c88a68")
const SKIN_D := Color("#8a5a40")
const SKIN_L := Color("#e8b090")
const LEATHER := Color("#6a3a24")
const BRONZE := Color("#b0803a")
const BRONZE_L := Color("#e8c070")
const CLOTH := Color("#8a1e2a")

var state: S = S.IDLE
var hype := 0.0 ## 흥분 남은 시간
var _timer := 0.0
var _dur := 0.0
var _taunt_cd := TAUNT_EVERY
var _taunt_hits := 0
var _thrust_start := 0.0
var _leap_to := Vector2.ZERO
var _last := ""
var _walk := 0.0
var _pending_taunt := false
var _contact: EnemyAttackArea
var _spear: EnemyAttackArea


func _init() -> void:
	engaged = false


func _build() -> void:
	max_hp = HP
	body_size = Vector2(24, 42)
	knock_mult = 0.15
	launch_mult = 0.0
	is_boss = true
	is_elite = false
	display_name = "가론"
	subtitle = "투기장의 챔피언"
	kind_id = "gladiator"
	var v := KE.Vis.new()
	v.enemy = self
	v.fn = _draw_body
	_visual = v
	add_child(v)
	_contact = add_attack_area(Vector2(22, 38), Vector2(0, -20), &"gladiator", 1)
	_contact.dodgeable = false
	_spear = add_attack_area(Vector2(34, 10), Vector2(28, -24), &"gladiator", 1)
	_spear.active = false


func _enter(s: S, d: float) -> void:
	state = s
	_timer = d
	_dur = d


func progress() -> float:
	return clampf(1.0 - _timer / _dur, 0.0, 1.0) if _dur > 0.0 else 1.0


func _speed() -> float:
	return 1.3 if hype > 0.0 else 1.0


func _ai(delta: float) -> void:
	var t := GameConst.TILE
	var sp := _speed()
	_timer -= delta * sp
	hype = maxf(hype - delta, 0.0)
	_taunt_cd -= delta
	place_area(_spear, Vector2(28, -24))
	var p := player()
	_contact.active = engaged and _alive
	if not engaged or p == null or not p.is_alive():
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		if state != S.IDLE:
			_enter(S.IDLE, 0.0)
		return
	if state == S.IDLE:
		_enter(S.STALK, 0.8)
	var dx := p.global_position.x - global_position.x
	match state:
		S.STALK:
			face_player()
			var adx := absf(dx)
			var want := 0.0
			if adx > 5.0 * t:
				want = signf(dx) * WALK_T * t * sp
			elif adx < 2.5 * t:
				want = -signf(dx) * WALK_T * 0.6 * t
			velocity.x = move_toward(velocity.x, want, 500.0 * delta)
			if absf(velocity.x) > 5.0:
				_walk += delta * 8.0
			if _timer <= 0.0 and is_on_floor():
				_choose(adx / t)
		S.NET_WINDUP:
			velocity.x = 0.0
			if _timer <= 0.0:
				_throw_net()
				_enter(S.NET_THROW, 0.45)
		S.NET_THROW:
			if _timer <= 0.0:
				_enter(S.STALK, Difficulty.rest(0.6))
		S.THRUST_WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _timer <= 0.0:
				_enter(S.THRUST, 0.0)
				_thrust_start = global_position.x
				_spear.active = true
				_spear.dodgeable = true
				KE.snd(&"spear", &"charger_charge", 0.0)
		S.THRUST:
			velocity.x = facing * THRUST_SPEED_T * t * sp
			if absf(global_position.x - _thrust_start) > THRUST_MAX_T * t or is_on_wall():
				_spear.active = false
				velocity.x = facing * 2.0 * t
				_enter(S.OVEREXTEND, Difficulty.rest(OVEREXTEND))
				KE.debris(global_position + Vector2(facing * 6.0, 0), 6, Color("#a8906a"), Vector2(-facing, -1), 80.0)
		S.LEAP_CROUCH:
			velocity.x = 0.0
			if _timer > 0.15:
				_leap_to = Vector2(p.global_position.x, KE.floor_at(self, p.global_position.x, p.global_position.y))
			if _timer <= 0.0:
				_enter(S.LEAP, LEAP_TIME)
				var ddx := clampf(_leap_to.x - global_position.x, -10.0 * t, 10.0 * t)
				facing = 1 if ddx >= 0.0 else -1
				velocity.y = -0.5 * _gravity * LEAP_TIME
				velocity.x = ddx / LEAP_TIME
				KE.snd(&"jump", &"jump", 0.0)
		S.LEAP:
			if is_on_floor() and _dur - _timer > 0.1:
				_slam()
		S.SLAM, S.OVEREXTEND, S.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
			if _timer <= 0.0:
				if _pending_taunt:
					_pending_taunt = false
					_start_taunt()
				else:
					_enter(S.STALK, Difficulty.rest(0.7))
		S.TAUNT:
			velocity.x = 0.0
			if int(_t * 6.0) % 2 == 0:
				KE.snd(&"crowd", &"blip", -14.0, 0.3)
			if _timer <= 0.0:
				hype = HYPE_TIME
				cheered.emit()
				KE.snd(&"roar", &"roar", 0.0)
				Fx.shake(0.2, 0.3)
				KE.star_burst(global_position + Vector2(0, -30), 20, BRONZE_L, 120.0, 0.6)
				_enter(S.STALK, 0.4)
		S.FLUSTER:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if _timer <= 0.0:
				_enter(S.STALK, 0.5)


func _choose(adx: float) -> void:
	face_player()
	if _taunt_cd <= 0.0:
		_start_taunt()
		return
	var pick := "thrust"
	if adx > 7.0:
		pick = "net" if randf() < 0.6 else "leap"
	elif adx > 3.5:
		pick = ["thrust", "net", "leap"][randi() % 3]
	if pick == _last and randf() < 0.7:
		pick = "leap" if pick != "leap" else "thrust"
	_last = pick
	match pick:
		"net":
			_enter(S.NET_WINDUP, Difficulty.telegraph(NET_WINDUP))
			KE.snd(&"whoosh", &"whoosh", -6.0)
		"thrust":
			_enter(S.THRUST_WINDUP, Difficulty.telegraph(THRUST_WINDUP))
			KE.snd(&"charger_windup", &"charger_windup", -3.0)
		"leap":
			_enter(S.LEAP_CROUCH, Difficulty.telegraph(LEAP_CROUCH))
			KE.snd(&"growl", &"growl", -4.0)


func _start_taunt() -> void:
	_taunt_cd = TAUNT_EVERY
	_taunt_hits = 0
	_enter(S.TAUNT, TAUNT_TIME)
	KE.snd(&"crowd", &"rank_up", -4.0)


func _throw_net() -> void:
	var p := player()
	if p == null:
		return
	var from := global_position + Vector2(facing * 8.0, -40)
	var to := p.center()
	var dist := absf(to.x - from.x)
	var flight := clampf(dist / 220.0, 0.45, 1.0)
	var g := 500.0
	var vx := (to.x - from.x) / flight
	var vy := (to.y - from.y - 0.5 * g * flight * flight) / flight
	var net := NetShot.new()
	net.setup(from, Vector2(vx, vy).normalized(), Vector2(vx, vy).length(), "net", {"gravity": g, "radius": 9.0, "life": 2.0, "cause": "gladiator_net"})
	net.owner_ref = weakref(self)
	Fx.effect_parent().add_child(net)
	KE.snd(&"whoosh", &"whoosh", 0.0)


## 그물에 걸린 세라에게 곧바로 찌르기
func net_caught() -> void:
	var p := player()
	if p:
		p.state = Player.State.STUN
		p.set("_stun_timer", NET_BIND)
	if state in [S.STALK, S.NET_THROW, S.RECOVER]:
		face_player()
		_enter(S.THRUST_WINDUP, Difficulty.telegraph(THRUST_WINDUP * 0.8))
	_pending_taunt = true # 맞혔으니 관중에게 자랑하고 싶다


func _slam() -> void:
	_enter(S.SLAM, Difficulty.rest(SLAM_TIME))
	velocity.x = 0.0
	Fx.shake(0.4, 0.3)
	KE.snd(&"slam", &"slam", 2.0)
	KE.debris(global_position, 14, Color("#a8906a"), Vector2.UP, 160.0)
	for d in [-1, 1]:
		KE.wave(global_position + Vector2(d * 12.0, 0), d, 10.0 * GameConst.TILE, 9.0 * GameConst.TILE, "rock", 16.0)


func modify_damage(_hit: Hit) -> float:
	if not engaged:
		return 0.0
	return 1.0


func _on_hit(hit: Hit, _dir: int) -> void:
	if state == S.TAUNT:
		_taunt_hits += 2 if hit.kind in Hit.HEAVY_GLADIATOR else 1
		if _taunt_hits >= 2:
			_enter(S.FLUSTER, FLUSTER_TIME)
			velocity.x = -facing * 80.0
			KE.snd(&"crowd", &"blip", -8.0)
			var hud := get_tree().get_first_node_in_group(&"hud")
			if hud and hud.has_method("banner"):
				hud.banner("환호를 끊었다!", 1.0)


func _resists_knockback(_hit: Hit) -> bool:
	return true


func _die(dir: int) -> void:
	KE.death_fx(global_position + Vector2(0, -22), BRONZE_L, true)
	KE.snd(&"crowd", &"clear", 0.0)
	super(dir)


# ─── 그림 ───────────────────────────────────────────────

func _col(c: Color, white: bool) -> Color:
	return Color.WHITE if white else c


func _draw_body(c: Node2D) -> void:
	var white := flash_amount() > 0.0
	var k := progress()
	var skin := _col(SKIN, white)
	var skin_d := _col(SKIN_D, white)
	var o := Vector2.ZERO
	var lean := 0.0
	var arms_up := 0.0
	var spear_a := -PI * 0.45
	var spear_hand := Vector2(10, -24)
	var warn := 0.0
	var net_spin := false
	var walk := sin(_walk) if state == S.STALK else 0.0
	match state:
		S.NET_WINDUP:
			net_spin = true
			arms_up = 0.6
		S.THRUST_WINDUP:
			o = Vector2(-3, 2) * k
			spear_a = lerpf(-PI * 0.4, 0.0, k)
			spear_hand = Vector2(10, -24).lerp(Vector2(-4, -22), k)
			warn = KE.warn_pulse(_t, k)
		S.THRUST:
			o = Vector2(3, 1)
			lean = 0.2
			spear_a = 0.0
			spear_hand = Vector2(16, -23)
		S.OVEREXTEND:
			o = Vector2(4, 3)
			lean = 0.35
			spear_a = 0.3
			spear_hand = Vector2(16, -16)
		S.LEAP_CROUCH:
			o = Vector2(0, 5 * k)
			warn = KE.warn_pulse(_t, k)
			spear_a = -PI * 0.5
		S.LEAP:
			spear_a = -PI * 0.5 - 0.6
			arms_up = 0.5
		S.SLAM:
			o = Vector2(0, 4)
			spear_a = 1.2
			spear_hand = Vector2(12, -12)
		S.TAUNT:
			arms_up = 1.0
			o = Vector2(0, -absf(sin(_t * 8.0)) * 1.5)
		S.FLUSTER:
			lean = -0.15
			o = Vector2(-2, 0)
	if hype > 0.0 and not white:
		KArt.glow(c, Vector2(0, -24), 30.0, Color(BRONZE_L, 0.45 + 0.15 * sin(_t * 8.0)), 3)
	c.draw_set_transform(o, lean, Vector2.ONE)
	# 다리 (가죽 치마 아래 굵은 다리 + 정강이받이)
	for i in 2:
		var lx := -6.0 + i * 8.0
		var lift := maxf(walk * (1.0 if i == 1 else -1.0), 0.0) * 2.0
		c.draw_rect(Rect2(lx - 1, -16 - lift, 7, 16).grow(1.0), KE.OUT)
		c.draw_rect(Rect2(lx - 1, -16 - lift, 7, 9), skin_d if i == 0 else skin)
		c.draw_rect(Rect2(lx - 1, -8 - lift, 7, 8), _col(BRONZE, white))
		c.draw_rect(Rect2(lx - 1, -8 - lift, 7, 1), _col(BRONZE_L, white))
	# 가죽 치마 + 허리띠
	c.draw_colored_polygon(PackedVector2Array([Vector2(-9, -20), Vector2(9, -20), Vector2(11, -12), Vector2(-11, -12)]), _col(LEATHER, white))
	for i in 5:
		c.draw_line(Vector2(-9 + i * 4.5, -19), Vector2(-10 + i * 5.0, -12), _col(LEATHER.darkened(0.3), white), 1.0)
	c.draw_rect(Rect2(-10, -22, 20, 3), _col(BRONZE, white))
	c.draw_rect(Rect2(-2, -22, 4, 3), _col(BRONZE_L, white))
	# 뒷팔
	var arm_b_end := Vector2(-11, -24).lerp(Vector2(-12, -46), arms_up)
	c.draw_line(Vector2(-7, -36), arm_b_end, KE.OUT, 6.0)
	c.draw_line(Vector2(-7, -36), arm_b_end, skin_d, 4.0)
	# 몸통 (근육질, 한쪽 어깨에 청동 어깨갑 + 진홍 띠)
	var torso := PackedVector2Array([Vector2(-9, -21), Vector2(9, -21), Vector2(11, -36), Vector2(4, -41), Vector2(-5, -41), Vector2(-11, -36)])
	var to := PackedVector2Array()
	for pnt in torso:
		to.append(pnt + (pnt - Vector2(0, -31)).normalized())
	c.draw_colored_polygon(to, KE.OUT)
	c.draw_colored_polygon(torso, skin)
	c.draw_line(Vector2(0, -38), Vector2(0, -24), skin_d, 1.0) # 근육선
	c.draw_line(Vector2(-6, -32), Vector2(6, -32), skin_d, 1.0)
	c.draw_line(Vector2(4, -38), Vector2(8, -30), _col(SKIN_L, white), 1.0)
	c.draw_line(Vector2(-9, -37), Vector2(8, -23), _col(CLOTH, white), 3.0) # 어깨띠
	# 머리: 짧은 상투 + 수염 + 흉터
	var hc := Vector2(2, -47)
	c.draw_circle(hc, 6.5, KE.OUT)
	c.draw_circle(hc, 5.6, skin)
	c.draw_colored_polygon(PackedVector2Array([hc + Vector2(-6, -1), hc + Vector2(-5, -5), hc + Vector2(1, -7), hc + Vector2(5, -4), hc + Vector2(1, -3)]), _col(Color("#2a1a14"), white))
	c.draw_circle(hc + Vector2(-5, -6), 2.0, _col(Color("#2a1a14"), white)) # 상투
	c.draw_colored_polygon(PackedVector2Array([hc + Vector2(-1, 2), hc + Vector2(5, 1), hc + Vector2(4, 6), hc + Vector2(0, 6)]), _col(Color("#2a1a14"), white)) # 수염
	var eye_col := _col(Color("#1a1010") if hype <= 0.0 else Color("#ffc040"), white)
	c.draw_rect(Rect2(hc + Vector2(2, -2), Vector2(2, 1.5)), eye_col)
	c.draw_line(hc + Vector2(-1, -3), hc + Vector2(1, 0), _col(SKIN_L, white), 1.0)
	if state == S.TAUNT and not white:
		c.draw_rect(Rect2(hc + Vector2(2, 2), Vector2(3, 2)), Color("#3a1010")) # 웃음
	if state == S.FLUSTER and not white:
		c.draw_rect(Rect2(hc + Vector2(7, -6), Vector2(1, 3)), Color(0.6, 0.85, 1.0)) # 땀
	# 청동 어깨갑 (앞)
	c.draw_colored_polygon(PackedVector2Array([Vector2(3, -42), Vector2(13, -40), Vector2(14, -34), Vector2(5, -35)]), _col(BRONZE, white))
	c.draw_line(Vector2(4, -41), Vector2(12, -39.5), _col(BRONZE_L, white), 1.0)
	# 삼지창 + 앞팔
	var dir := Vector2.from_angle(spear_a)
	var hand := spear_hand
	if arms_up > 0.0 and state in [S.TAUNT, S.NET_WINDUP]:
		hand = Vector2(10, -24).lerp(Vector2(12, -50), arms_up)
		dir = Vector2.from_angle(-PI * 0.5 + 0.2)
	var butt := hand - dir * 16.0
	var tip := hand + dir * 22.0
	if warn > 0.0 and state == S.THRUST_WINDUP:
		c.draw_line(hand, tip, Color(KE.DANGER, 0.35 * warn), 7.0)
	c.draw_line(butt, tip, KE.OUT, 3.4)
	c.draw_line(butt, tip, _col(Color("#5a3a20"), white), 1.8)
	var side := dir.orthogonal()
	var prong := _col(Color("#d8dce8") if warn <= 0.0 or state != S.THRUST_WINDUP else Color("#ffb0a0"), white)
	for s in [-1.0, 0.0, 1.0]:
		var base: Vector2 = tip + side * s * 3.0
		c.draw_line(base - dir * 1.0, base + dir * (6.0 if s == 0.0 else 4.5), prong, 1.4)
	c.draw_line(tip - side * 3.0, tip + side * 3.0, prong, 1.4)
	c.draw_line(Vector2(6, -37), hand, KE.OUT, 6.0)
	c.draw_line(Vector2(6, -37), hand, skin, 4.0)
	c.draw_circle(hand, 2.6, skin_d)
	# 머리 위에서 도는 그물
	if net_spin and not white:
		var nc := hand + Vector2(0, -6)
		for i in 6:
			var a := _t * 14.0 + TAU * i / 6.0
			c.draw_line(nc, nc + Vector2(cos(a) * 12.0, sin(a) * 4.0), Color("#c8b890"), 1.0)
		c.draw_arc(nc, 12.0, 0, TAU, 14, Color(KE.DANGER, KE.warn_pulse(_t, k)), 1.0)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# 착지점 예고 (도약 웅크림) — 뒤집기를 되돌려 그림
	if state == S.LEAP_CROUCH and not white:
		var rel := _leap_to - global_position
		c.draw_set_transform(Vector2(rel.x * float(facing), rel.y - 1), 0.0, Vector2(1.0, 0.3))
		c.draw_arc(Vector2.ZERO, 22.0, 0, TAU, 20, Color(KE.DANGER, 0.4 + 0.5 * warn), 2.0)
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# 관중 환호 아이콘
	if state == S.TAUNT and not white:
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2(float(facing), 1.0))
		for i in 3:
			var nx := -12.0 + i * 12.0
			var ny := -66.0 - absf(sin(_t * 6.0 + i)) * 4.0
			c.draw_rect(Rect2(nx, ny, 2, 5), Color(BRONZE_L, 0.9))
			c.draw_rect(Rect2(nx, ny + 6, 2, 2), Color(BRONZE_L, 0.9))
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## 펼쳐지며 날아오는 그물: 맞으면 세라를 잠깐 묶는다
class NetShot extends EnemyProjectile:
	var owner_ref: WeakRef

	func _ready() -> void:
		super()
		hit_player.connect(_on_caught)

	func _on_caught(_p: Node) -> void:
		var o: Object = owner_ref.get_ref() if owner_ref else null
		if o and o.has_method("net_caught"):
			o.call("net_caught")
		if Sfx.has_sound(&"chain"):
			Sfx.play(&"chain", 0.0)

	func _color() -> Color:
		return Color("#c8b890")

	func _draw() -> void:
		var open := clampf(_t / 0.35, 0.3, 1.0)
		var r := radius * open + 2.0
		var rot := _spin * 0.3
		var pts := PackedVector2Array()
		for i in 8:
			var a := rot + TAU * i / 8.0
			pts.append(Vector2(cos(a), sin(a)) * r)
		for i in 8:
			draw_line(pts[i], pts[(i + 1) % 8], Color("#c8b890"), 1.0)
			draw_line(Vector2.ZERO, pts[i], Color("#a89870"), 1.0)
			draw_circle(pts[i], 1.2, Color("#7a7068"))
		draw_arc(Vector2.ZERO, r * 0.5, 0, TAU, 10, Color("#c8b890"), 1.0)
		draw_arc(Vector2.ZERO, r + 1.5, 0, TAU, 16, Color(1.0, 0.25, 0.25, 0.5), 1.0)
