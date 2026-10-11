extends EnemyBase
## 별 신도 (docs/archive/sera/chapter2.md 4절) — "별을 좇는 자들"의 말단 신도. 약하지만 성가시다(빨리 끝나는 적).
## 바닥의 별 문양 셋(제자리 ±5칸) 사이를 순간이동하며, 주위에 별 조각 셋을 돌리다(마지막 0.5초 붉게) 하나씩 쏜다.
## 두 번에 한 번은 **별 수정 방패**를 세운다: 방패는 어떤 불도 막지만(팅), 되쏜 탄(Hit.kind = reflect)에는 산산조각 난다.
## 방패를 든 동안 1초마다 느린 별 조각을 쏘니 → 불꽃 방벽으로 되쏘면 방패가 깨지고 1.5초 휘청(피해 150%).
## 방패를 못 깨도 4초 뒤엔 저절로 사라진다(방벽 없이도 잡을 수 있음).

const KE := preload("res://enemies/ch2/k_enemy.gd")
const KArt := preload("res://world/entities/ch2/k_art.gd")

enum S { APPEAR, ORBIT, FIRE, VANISH, SHIELD, STAGGER, IDLE }

const HP := 400
const SIGIL_SPREAD_T := 5.0
const APPEAR_TIME := 0.35
const ORBIT_TIME := 1.3
const ORBIT_WARN := 0.5
const SHOT_GAP := 0.22
const SHOT_SPEED_T := 8.5
const VANISH_TIME := 0.35
const DEST_WARN := 0.45
const SHIELD_TIME := 4.0
const SHIELD_SHOT_EVERY := 1.0
const SHIELD_SHOT_SPEED_T := 5.0
const STAGGER_TIME := 1.5
const STAGGER_MULT := 1.5
const ROBE := Color("#241c40")
const ROBE_L := Color("#3e3270")
const ROBE_D := Color("#120c22")
const MASK := Color("#e8e4f0")
const STAR := Color("#c89aff")

var state: S = S.IDLE
var shield_up := false
var sigils: Array[Vector2] = []
var _sigil := 0
var _next_sigil := 0
var _clock := StateClock.new() ## 상태 시간 (남은 시간·길이·진행도)
var _shots := 0
var _cycle := 0
var _shield_shot := 0.0
var _shield_hp := 1
var _fade := 1.0
var _shatter_t := 9.0


func _build() -> void:
	max_hp = HP
	body_size = Vector2(14, 30)
	knock_mult = 0.5
	launch_mult = 0.6
	display_name = "별 신도"
	subtitle = "별을 좇는 자들"
	kind_id = "cultist"
	var v := KE.Vis.new()
	v.enemy = self
	v.fn = _draw_body
	_visual = v
	add_child(v)
	var fx := KE.Vis.new()
	fx.enemy = self
	fx.fn = _draw_fx
	fx.flip = false
	fx.z_index = 5
	add_child(fx)


func _ready() -> void:
	super()
	var home := global_position
	sigils = [home]
	for dx in [-SIGIL_SPREAD_T, SIGIL_SPREAD_T]:
		var x: float = home.x + dx * GameConst.TILE
		var fy := KE.floor_at(self, x, home.y, 64.0)
		# 벽 안이면 쓰지 않음
		var q := PhysicsRayQueryParameters2D.create(home + Vector2(0, -12), Vector2(x, home.y - 12), GameConst.L_WORLD)
		if get_world_2d().direct_space_state.intersect_ray(q).is_empty() and absf(fy - home.y) < 48.0:
			sigils.append(Vector2(x, fy))
	_enter(S.IDLE, 0.4)


func _enter(s: S, d: float) -> void:
	state = s
	_clock.enter(d)


func progress() -> float:
	return _clock.k()


func _ai(delta: float) -> void:
	_clock.tick(delta)
	_shatter_t += delta
	velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	var p := player()
	if p and state != S.VANISH:
		face_player()
	if not engaged or p == null or not p.is_alive():
		return
	match state:
		S.IDLE:
			if _clock.done() and dist_to_player() < 16.0 * GameConst.TILE:
				_enter(S.ORBIT, Difficulty.telegraph(ORBIT_TIME))
				KE.snd(&"star_twinkle", &"pillar_warn", -6.0)
		S.APPEAR:
			_fade = progress()
			if _clock.done():
				_fade = 1.0
				_cycle += 1
				if _cycle % 2 == 0:
					_raise_shield()
				else:
					_enter(S.ORBIT, Difficulty.telegraph(ORBIT_TIME))
					KE.snd(&"star_twinkle", &"pillar_warn", -6.0)
		S.ORBIT:
			if _clock.done():
				_shots = 0
				_enter(S.FIRE, 0.0)
		S.FIRE:
			if _clock.done():
				_fire_orbit_shard()
				_shots += 1
				_clock.left = SHOT_GAP
				if _shots >= 3:
					_start_vanish(Difficulty.rest(0.6))
		S.SHIELD:
			_shield_shot -= delta
			if _shield_shot <= 0.0:
				_shield_shot = SHIELD_SHOT_EVERY
				_fire_slow_shard()
			if _clock.done():
				_drop_shield(false)
				_start_vanish(0.2)
		S.STAGGER:
			if _clock.done():
				_start_vanish(0.0)
		S.VANISH:
			if _clock.left > 0.0 and _clock.left <= VANISH_TIME:
				_fade = clampf(_clock.left / VANISH_TIME, 0.0, 1.0)
			if _clock.done():
				_sigil = _next_sigil
				global_position = sigils[_sigil]
				_enter(S.APPEAR, APPEAR_TIME)
				KE.star_burst(global_position + Vector2(0, -16), 12, STAR, 80.0, 0.4)
				KE.snd(&"warp", &"reveal", -6.0)


func _start_vanish(delay: float) -> void:
	# 다음 별 문양을 고르고(세라와 너무 가깝지 않은 곳) 그곳을 먼저 붉게 깜빡인다
	var p := player()
	var best := _sigil
	var best_d := -1.0
	for i in sigils.size():
		if i == _sigil and sigils.size() > 1:
			continue
		var d := sigils[i].distance_to(p.global_position) if p else 0.0
		var score := d if d > 3.0 * GameConst.TILE else d * 0.3
		if score > best_d:
			best_d = score
			best = i
	_next_sigil = best
	_enter(S.VANISH, delay + Difficulty.telegraph(DEST_WARN) + VANISH_TIME)
	KE.snd(&"whoosh", &"whoosh", -8.0)


func _orbit_pos(i: int) -> Vector2:
	var a := _t * 4.0 + TAU * i / 3.0
	return global_position + Vector2(cos(a) * 13.0, -18.0 + sin(a) * 6.0)


func _fire_orbit_shard() -> void:
	var p := player()
	if p == null:
		return
	var from := _orbit_pos(_shots)
	KE.shard(from, (p.center() - from).normalized(), SHOT_SPEED_T * GameConst.TILE, {"radius": 3.0, "life": 3.0})
	KE.snd(&"star_twinkle", &"sniper_shot", -5.0)


func _fire_slow_shard() -> void:
	var p := player()
	if p == null:
		return
	var from := global_position + Vector2(facing * 14.0, -20.0)
	KE.shard(from, (p.center() - from).normalized(), SHIELD_SHOT_SPEED_T * GameConst.TILE, {"radius": 4.0, "life": 5.0})
	KE.snd(&"star_twinkle", &"sniper_shot", -6.0)


func _raise_shield() -> void:
	shield_up = true
	_shield_shot = 0.6
	_enter(S.SHIELD, SHIELD_TIME)
	KE.snd(&"star_burst", &"reveal", -4.0)
	KE.star_burst(global_position + Vector2(facing * 10.0, -16), 10, STAR, 60.0, 0.4)


func _drop_shield(shattered: bool) -> void:
	shield_up = false
	if shattered:
		_shatter_t = 0.0
		Fx.shake(0.2, 0.2)
		KE.snd(&"crumble", &"crumble", 0.0)
		KE.snd(&"star_burst", &"explode", -6.0)
		KE.star_burst(global_position + Vector2(facing * 10.0, -16), 26, STAR, 180.0, 0.6)
		Fx.ring(global_position + Vector2(facing * 10.0, -16), 4.0, 30.0, STAR, 0.35, 2.0)
	else:
		KE.star_burst(global_position + Vector2(facing * 10.0, -16), 8, STAR, 40.0, 0.4)


func modify_damage(hit: Hit) -> float:
	if state == S.VANISH and _fade < 0.4:
		return 0.0 # 사라지는 중엔 맞지 않음
	if shield_up:
		return 1.0 if hit.kind == &"reflect" else 0.0
	if state == S.STAGGER:
		return STAGGER_MULT
	return 1.0


func _on_blocked(hit: Hit) -> void:
	if shield_up:
		# 수정 방패에 튕김: 보랏빛 파편 + 맑은 소리
		var at := global_position + Vector2(facing * 11.0, -16)
		KE.star_burst(at, 6, STAR, 90.0, 0.25)
		KE.snd(&"block", &"block", -2.0, 0.1)
		return
	super(hit)


func _on_hit(hit: Hit, _dir: int) -> void:
	if shield_up and hit.kind == &"reflect":
		_drop_shield(true)
		_enter(S.STAGGER, STAGGER_TIME)
		velocity.x = -facing * 60.0


func _die(dir: int) -> void:
	shield_up = false
	KE.death_fx(global_position + Vector2(0, -16), STAR)
	super(dir)


# ─── 그림 ───────────────────────────────────────────────

func _draw_body(c: Node2D) -> void:
	var white := flash_amount() > 0.0
	var a := _fade
	var bob := sin(_t * 2.6) * 1.0
	var stag := state == S.STAGGER
	var cast := state in [S.ORBIT, S.FIRE, S.SHIELD]
	var robe := ROBE if not white else Color.WHITE
	var robe_l := ROBE_L if not white else Color.WHITE
	c.modulate.a = a
	if stag:
		c.draw_set_transform(Vector2(0, 0), -0.15 + sin(_t * 30.0) * 0.05, Vector2.ONE)
	# 로브 (아래로 퍼짐, 자락이 흔들림)
	var sway := sin(_t * 2.0) * 1.2
	var pts := PackedVector2Array([Vector2(-4, -26 + bob), Vector2(4, -26 + bob), Vector2(7 + sway, -1), Vector2(-8 + sway, -1)])
	c.draw_colored_polygon(PackedVector2Array([Vector2(-5, -27 + bob), Vector2(5, -27 + bob), Vector2(8 + sway, 0), Vector2(-9 + sway, 0)]), KE.OUT)
	c.draw_colored_polygon(pts, robe)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-4, -26 + bob), Vector2(-1, -26 + bob), Vector2(-2 + sway, -1), Vector2(-8 + sway, -1)]), ROBE_D if not white else Color.WHITE)
	c.draw_line(Vector2(-7 + sway, -2), Vector2(6 + sway, -2), Color(STAR, 0.6), 1.0)
	# 별자리 수
	if not white:
		c.draw_rect(Rect2(1, -18 + bob, 1, 1), Color(1, 0.95, 1.0, 0.8))
		c.draw_rect(Rect2(3, -12 + bob, 1, 1), Color(1, 0.95, 1.0, 0.6))
		c.draw_line(Vector2(1.5, -17.5 + bob), Vector2(3.5, -11.5 + bob), Color(STAR, 0.35), 1.0)
	# 두건 + 흰 가면 + 보라 눈
	var hc := Vector2(1, -30 + bob)
	c.draw_colored_polygon(PackedVector2Array([hc + Vector2(-6, 5), hc + Vector2(-6, -2), hc + Vector2(-2, -7), hc + Vector2(3, -6), hc + Vector2(6, -1), hc + Vector2(5, 5)]), KE.OUT)
	c.draw_colored_polygon(PackedVector2Array([hc + Vector2(-5, 4), hc + Vector2(-5, -2), hc + Vector2(-2, -6), hc + Vector2(3, -5), hc + Vector2(5, -1), hc + Vector2(4, 4)]), robe_l)
	c.draw_circle(hc + Vector2(1.5, 0.5), 3.0, MASK if not white else Color.WHITE)
	if not white:
		KArt.star4(c, hc + Vector2(1.5, 0.5), 3.4, Color("#a8a0c0"))
		KArt.star4(c, hc + Vector2(1.5, 0.5), 2.2, MASK)
		var eg := 1.0 if cast else 0.6 + 0.3 * sin(_t * 4.0)
		c.draw_rect(Rect2(hc + Vector2(2, -0.5), Vector2(1.5, 1)), Color(STAR.lightened(0.3), eg))
	# 팔: 별 문양을 든 손 (시전 때 앞으로)
	var hand := Vector2(6, -16 + bob) if cast else Vector2(4, -12 + bob)
	c.draw_line(Vector2(1, -22 + bob), hand, KE.OUT, 4.0)
	c.draw_line(Vector2(1, -22 + bob), hand, robe_l, 2.4)
	if not white:
		KArt.star5(c, hand + Vector2(2, -1), 2.6, Color(STAR, 0.9), _t)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_fx(c: Node2D) -> void:
	var t := GameConst.TILE
	# 바닥의 별 문양들 (지금 자리·다음 자리)
	for i in sigils.size():
		var sp: Vector2 = sigils[i] - global_position
		var col := Color(STAR, 0.35)
		var warn := state == S.VANISH and i == _next_sigil
		if warn:
			col = Color(KE.DANGER, KE.warn_pulse(_t, 1.0 - clampf(_clock.left, 0.0, 1.0)))
		c.draw_set_transform(sp + Vector2(0, -1), 0.0, Vector2(1.0, 0.3))
		c.draw_arc(Vector2.ZERO, 12.0, 0, TAU, 20, col, 1.5)
		var pts := PackedVector2Array()
		for k in 6:
			var a := _t * 0.5 + TAU * k * 2.0 / 5.0 - PI * 0.5
			pts.append(Vector2(cos(a), sin(a)) * 10.0)
		c.draw_polyline(pts, col, 1.0)
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if state == S.ORBIT or state == S.FIRE:
		var k := progress() if state == S.ORBIT else 1.0
		var warn_k := clampf((k * _clock.dur - (_clock.dur - ORBIT_WARN)) / ORBIT_WARN, 0.0, 1.0) if state == S.ORBIT else 1.0
		for i in range(_shots, 3):
			var op := _orbit_pos(i) - global_position
			var cc := STAR.lerp(KE.DANGER, warn_k * KE.warn_pulse(_t, warn_k))
			KArt.glow(c, op, 7.0, Color(cc, 0.6), 2)
			KArt.star4(c, op, 3.5, cc)
	if shield_up:
		# 별 수정 방패: 세라 쪽에 세운 육각 수정판 (금이 간 정도 = 남은 시간)
		var at := Vector2(facing * 12.0, -16)
		var hh := 17.0
		var ww := 6.0
		var shimmer := 0.7 + 0.3 * sin(_t * 6.0)
		var hexp := PackedVector2Array([at + Vector2(-ww * 0.5, -hh), at + Vector2(ww * 0.5, -hh * 0.8), at + Vector2(ww * 0.6, hh * 0.8),
			at + Vector2(-ww * 0.4, hh), at + Vector2(-ww * 0.7, 0)])
		KArt.glow(c, at, 22.0, Color(STAR, 0.5), 3)
		c.draw_colored_polygon(hexp, Color(STAR.lightened(0.2), 0.55 * shimmer))
		c.draw_polyline(hexp + PackedVector2Array([hexp[0]]), Color(1, 0.95, 1.0, 0.9), 1.0)
		c.draw_line(at + Vector2(-1, -hh * 0.8), at + Vector2(1, hh * 0.6), Color(1, 1, 1, 0.5), 1.0)
		var crack := 1.0 - clampf(_clock.left / SHIELD_TIME, 0.0, 1.0)
		if crack > 0.5:
			c.draw_polyline(PackedVector2Array([at + Vector2(-2, -8), at + Vector2(1, -2), at + Vector2(-1, 4), at + Vector2(2, 9)]), Color(1, 1, 1, crack), 1.0)
	if _shatter_t < 0.5:
		var k2 := _shatter_t / 0.5
		for i in 6:
			var a2 := TAU * i / 6.0
			KArt.star4(c, Vector2(facing * 12.0, -16) + Vector2(cos(a2), sin(a2)) * (6.0 + k2 * 24.0), 2.5 * (1.0 - k2), Color(STAR, 1.0 - k2))
