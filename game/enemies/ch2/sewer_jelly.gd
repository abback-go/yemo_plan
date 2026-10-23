extends EnemyBase
## 하수도 해파리 (docs/archive/sera/chapter2.md 4절) — 별빛 청록 물에서 자란 커다란 해파리.
## 둥실 떠서 세라 쪽으로 천천히 다가오다가, 갓을 오므리며 전기를 모으고(0.8초, 바닥에 붉은 고리)
## 바닥으로 내려앉아 **바닥을 따라 퍼지는 전기 고리**(양옆으로 달리는 충격파)를 낸다 → 점프로 넘는다.
## 고리를 낸 직후 1.5초 동안 갓이 열려 **핵이 드러남(피해 150%)**, 평소엔 말랑한 갓이 받아내 피해 50%.

const KE := preload("res://enemies/ch2/k_enemy.gd")
const KArt := preload("res://world/entities/ch2/k_art.gd")

enum S { DRIFT, CHARGE, DROP, PULSE, OPEN, RISE }

const HP := 500
const HOVER_T := 3.2
const DRIFT_T := 1.4
const DRIFT_TIME := Vector2(2.2, 3.0)
const CHARGE_TIME := 0.8
const DROP_TIME := 0.25
const OPEN_TIME := 1.5
const RISE_TIME := 0.7
const WAVE_SPEED_T := 9.0
const WAVE_DIST_T := 14.0
const SHELL_MULT := 0.5
const CORE_MULT := 1.5
const BELL := Color("#4ac8b8")
const BELL_L := Color("#a8fff0")
const CORE := Color("#f0ffb0")
const TEAL := Color("#6af0e0")

var state: S = S.DRIFT
var floor_y := 0.0
var _clock := StateClock.new() ## 상태 시간 (남은 시간·길이·진행도)
var _hover_y := 0.0
var _contact: EnemyAttackArea
var _zap: EnemyAttackArea


func _build() -> void:
	max_hp = HP
	body_size = Vector2(22, 22)
	knock_mult = 0.6
	launch_mult = 0.0
	flying = true
	display_name = "하수도 해파리"
	subtitle = "별빛을 머금은 물"
	kind_id = "sewer_jelly"
	var v := KE.Vis.new()
	v.enemy = self
	v.fn = _draw_body
	v.flip = false
	_visual = v
	add_child(v)
	_contact = add_attack_area(Vector2(20, 18), Vector2(0, -12), &"jelly", 1)
	_contact.dodgeable = false
	_zap = add_attack_area(Vector2(44, 22), Vector2(0, -11), &"jelly", 1)
	_zap.active = false


func _ready() -> void:
	super()
	collision_mask = GameConst.L_WORLD
	floor_y = KE.floor_at(self, global_position.x, global_position.y, 200.0)
	_hover_y = floor_y - HOVER_T * GameConst.TILE
	global_position.y = _hover_y
	_enter(S.DRIFT, randf_range(DRIFT_TIME.x, DRIFT_TIME.y))


func _enter(s: S, d: float) -> void:
	state = s
	_clock.enter(d)


func progress() -> float:
	return _clock.k()


func _ai(delta: float) -> void:
	var t := GameConst.TILE
	_clock.tick(delta)
	var p := player()
	floor_y = KE.floor_at(self, global_position.x, floor_y, 96.0)
	_hover_y = floor_y - HOVER_T * t
	if not engaged or p == null:
		velocity = Vector2(0, (_hover_y - global_position.y) * 2.0)
		return
	match state:
		S.DRIFT:
			var dx := p.global_position.x - global_position.x
			var want := signf(dx) * DRIFT_T * t if absf(dx) > 1.5 * t else 0.0
			velocity.x = move_toward(velocity.x, want, 120.0 * delta)
			velocity.y = (_hover_y + sin(_t * 2.0) * 4.0 - global_position.y) * 3.0
			if _clock.done() and absf(dx) < 12.0 * t:
				_enter(S.CHARGE, Difficulty.telegraph(CHARGE_TIME))
				KE.snd(&"star_twinkle", &"overload_warn", -8.0)
		S.CHARGE:
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			velocity.y = (_hover_y - 4.0 - global_position.y) * 4.0
			if int(_t * 20.0) % 2 == 0:
				_spark(global_position + Vector2(randf_range(-10, 10), -12 + randf_range(-8, 8)))
			if _clock.done():
				_enter(S.DROP, DROP_TIME)
		S.DROP:
			velocity.x = 0.0
			velocity.y = (floor_y - global_position.y) / maxf(_clock.left, 0.02)
			if _clock.done() or is_on_floor():
				global_position.y = floor_y
				_pulse()
		S.PULSE:
			velocity = Vector2.ZERO
			if _clock.done():
				_zap.active = false
				_enter(S.OPEN, Difficulty.rest(OPEN_TIME))
		S.OPEN:
			velocity = Vector2.ZERO
			if _clock.done():
				_enter(S.RISE, RISE_TIME)
		S.RISE:
			velocity.x = 0.0
			velocity.y = (_hover_y - global_position.y) * 3.5
			if _clock.done():
				_enter(S.DRIFT, randf_range(DRIFT_TIME.x, DRIFT_TIME.y))


func _pulse() -> void:
	_enter(S.PULSE, 0.18)
	_zap.active = true
	_zap.dodgeable = true
	Fx.shake(0.18, 0.2)
	KE.snd(&"star_burst", &"blast", -4.0)
	KE.snd(&"hit_heavy", &"hit_heavy", -10.0)
	for d in [-1, 1]:
		KE.wave(Vector2(global_position.x + d * 10.0, floor_y), d, WAVE_SPEED_T * GameConst.TILE, WAVE_DIST_T * GameConst.TILE, "spark", 14.0)
	Fx.ring(global_position + Vector2(0, -8), 6.0, 40.0, TEAL, 0.3, 2.0)
	Fx.burst(global_position + Vector2(0, -6), 18, {spread = 180.0, speed_min = 40.0, speed_max = 140.0, lifetime = 0.35,
		gradient = KE.grad(Color(1, 1, 1), Color(TEAL, 0.0)), size_min = 1.0, size_max = 2.0, gravity = Vector2.ZERO, add = true})


func _spark(at: Vector2) -> void:
	Fx.burst(at, 2, {spread = 180.0, speed_min = 20.0, speed_max = 60.0, lifetime = 0.15,
		gradient = KE.grad(Color(1, 1, 1), Color(TEAL, 0.0)), size_min = 1.0, size_max = 1.5, gravity = Vector2.ZERO, add = true})


func modify_damage(_hit: Hit) -> float:
	return CORE_MULT if state == S.OPEN else SHELL_MULT


func _on_hit(_hit: Hit, _dir: int) -> void:
	if state != S.OPEN:
		Fx.burst(global_position + Vector2(0, -14), 5, {spread = 180.0, speed_min = 20.0, speed_max = 70.0, lifetime = 0.3,
			gradient = Palette.fade_gradient(BELL_L), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 120)})
		KE.snd(&"squish", &"squish", -6.0)


func _die(dir: int) -> void:
	KE.death_fx(global_position + Vector2(0, -12), TEAL)
	Fx.burst(global_position + Vector2(0, -12), 20, {spread = 180.0, speed_min = 30.0, speed_max = 120.0, lifetime = 0.7,
		gradient = Palette.fade_gradient(Color(BELL_L, 0.8)), size_min = 1.5, size_max = 3.0, gravity = Vector2(0, 200)})
	super(dir)


# ─── 그림 ───────────────────────────────────────────────

func _draw_body(c: Node2D) -> void:
	var white := flash_amount() > 0.0
	var k := progress()
	var squeeze := 0.0 # 갓 오므림
	var open := 0.0 # 핵 노출
	match state:
		S.CHARGE: squeeze = k
		S.DROP: squeeze = 1.0
		S.PULSE: squeeze = 0.4
		S.OPEN: open = 1.0 - clampf((k - 0.85) / 0.15, 0.0, 1.0)
		S.RISE: open = 0.0
	var pulse := sin(_t * 3.0)
	var w := 13.0 * (1.0 - squeeze * 0.25) + pulse * 0.8
	var h := 11.0 * (1.0 + squeeze * 0.2)
	var top := Vector2(0, -22)
	# 바닥의 예고 고리 (모으는 중)
	if state == S.CHARGE and not white:
		var fy := floor_y - global_position.y
		var a := KE.warn_pulse(_t, k)
		c.draw_set_transform(Vector2(0, fy - 1), 0.0, Vector2(1.0, 0.25))
		c.draw_arc(Vector2.ZERO, 18.0 + 10.0 * k, 0, TAU, 24, Color(KE.DANGER, 0.3 + 0.5 * a), 2.0)
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for d in [-1.0, 1.0]:
			c.draw_line(Vector2(d * 20.0, fy - 3), Vector2(d * (30.0 + 20.0 * k), fy - 3), Color(KE.DANGER, 0.35 * a), 2.0)
	# 촉수 (뒤로 흐느적)
	for i in 5:
		var tx := -8.0 + i * 4.0
		var pts := PackedVector2Array()
		for j in 6:
			var tk := j / 5.0
			var sway := sin(_t * 3.0 + i * 1.3 + tk * 3.0) * 2.5 * tk
			pts.append(top + Vector2(tx * (1.0 - squeeze * 0.4) + sway, h + tk * (12.0 - squeeze * 6.0)))
		c.draw_polyline(pts, Color(BELL, 0.55) if not white else Color.WHITE, 1.0)
	# 갓 (반투명, 3단 명암)
	var bell := PackedVector2Array()
	for i in 13:
		var a2 := PI + PI * i / 12.0
		bell.append(top + Vector2(cos(a2) * w, sin(a2) * h + h))
	var edge_open := open * 4.0
	bell.append(top + Vector2(w - edge_open, h + 3.0 + sin(_t * 5.0)))
	bell.append(top + Vector2(-w + edge_open, h + 3.0 + sin(_t * 5.0 + 1.0)))
	KArt.glow(c, top + Vector2(0, h * 0.6), 26.0, Color(TEAL, 0.5 + 0.3 * squeeze), 3)
	c.draw_colored_polygon(bell, Color(BELL, 0.55) if not white else Color(1, 1, 1, 0.9))
	c.draw_arc(top + Vector2(0, h), w, PI, TAU, 14, Color(BELL_L, 0.9), 1.0)
	c.draw_arc(top + Vector2(-2, h + 1), w * 0.6, PI + 0.3, PI + 1.4, 6, Color(1, 1, 1, 0.6), 1.0)
	# 무늬 (방사선)
	for i in 4:
		var a3 := PI + PI * (i + 1) / 5.0
		c.draw_line(top + Vector2(0, h), top + Vector2(cos(a3) * w * 0.85, h + sin(a3) * h * 0.85), Color(BELL_L, 0.3), 1.0)
	# 핵: 평소엔 갓 속에 은은히, 열리면 크게 빛남
	var core_r := 3.0 + open * 2.5 + squeeze * 1.0
	var core_c := top + Vector2(0, h + 1.0 + open * 2.0)
	var core_col := CORE.lerp(Color(1, 1, 1), squeeze)
	if open > 0.0:
		KArt.glow(c, core_c, 12.0, Color(CORE, 0.8), 3)
	c.draw_circle(core_c, core_r, Color(core_col, 0.6 + 0.4 * open) if not white else Color.WHITE)
	c.draw_circle(core_c, core_r * 0.45, Color(1, 1, 1, 0.9))
	# 모으는 전기
	if (state == S.CHARGE or state == S.PULSE) and not white:
		for i in 3:
			var a4 := randf() * TAU
			var p0 := core_c + Vector2(cos(a4), sin(a4)) * (w + 2.0)
			var mid := (p0 + core_c) * 0.5 + Vector2(randf_range(-3, 3), randf_range(-3, 3))
			c.draw_polyline(PackedVector2Array([p0, mid, core_c]), Color(TEAL.lightened(0.4), 0.9), 1.0)
