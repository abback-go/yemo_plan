class_name ElarienHunt
extends EnemyBase
## 엘라리엔 — 사냥 시험 (docs/chapter3.md 4절·7.4절). 강자 보스지만 **체력 싸움이 아니다: "세 번 닿기"**.
## 그녀는 경기장 가지의 횃대(방의 spawn 표식 perch_1, perch_2 …)를 뛰어다니며 활을 쏜다. 세라가
##   ① 그녀 몸에 닿거나(곁으로 뛰어올라 부딪힘), ② 가까이(4.5T 안)에서 공격을 맞히거나, ③ 그녀의 화살을 불꽃 방벽으로 되쏘아 맞히면
## "하나." — 그녀가 휘청인 뒤 다른 횃대로 뛰어가고 단계가 오른다. 셋을 세면 끝(defeated).
## 멀리서 쏜 공격은 몸을 살짝 비틀어 피한다(처음 한 번 "멀다. 와서 닿아 봐." — 초보자 안내).
## 단계 (닿은 횟수):
##   0  한 발 — 긴 예고선(붉은 선이 세라를 따라옴 → 흰 선 깜빡 → 발사). 쉬는 시간 넉넉.
##   1  세 발 부채 + 한 발, 이따금 횃대를 옮김. 너무 가까이 오면 발밑 바람(붉은 고리 예고 → 세라를 밀어냄).
##   2  화살비(세라 둘레 바닥에 붉은 표시 → 하늘에서 떨어짐) + 바람 화살(굵은 예고 띠 → 맞으면 크게 밀려남) + 부채.
## 신호: touched(n) — 대본이 대사를 넣는다. 체력바는 남은 닿기 수(3 → 0)를 보여 준다.
## 대본: engaged = false로 두었다가 시작. 끝나면 활을 내리고 서 있다(노드는 남음, 대본이 NPC로 바꾼다).

signal touched(count: int)

enum S { WAIT, PERCH, AIM, FAN, RAIN, WIND, GUST, LEAP, STAGGER, DONE }

const TOUCHES := 3
const NEAR_T := 4.5 ## 이 안에서 맞히면 닿은 것으로 침
const BODY_TOUCH := 14.0 ## 세라 몸이 이만큼 가까우면 닿음(px)
const AIM_TIME := [1.25, 1.0, 0.85] ## 단계별 예고선이 따라오는 시간
const LOCK_TIME := 0.38 ## 흰 선 고정 (피할 틈)
const REST := [1.6, 1.35, 1.15]
const ARROW_SPEED_T := 24.0
const WIND_SPEED_T := 17.0
const RAIN_COUNT := 7
const RAIN_WARN := 1.25
const GUST_WINDUP := 0.65
const LEAP_TIME := 0.75
const INVULN_AFTER := 1.6
const RELOCATE_EVERY := [99.0, 12.0, 9.0]

var state: S = S.WAIT
var touches := 0
var aim_dir := Vector2.LEFT
var _timer := 0.0
var _dur := 0.0
var _cd := 1.2
var _shots := 0
var _since_move := 0.0
var _invuln := 0.0
var _far_hint := false
var _leap_from := Vector2.ZERO
var _leap_to := Vector2.ZERO
var _perch := -1
var _perches: Array[Vector2] = []
var _lines: Array[AimLine] = []
var _pattern := 0
var _flip: Node2D
var _cv: CharacterVisual
var _pips: Pips
var _gust_ring: Node2D


func _init() -> void:
	engaged = false


func _build() -> void:
	max_hp = TOUCHES
	body_size = Vector2(14, 32)
	is_boss = true
	is_elite = false
	flying = true
	knock_mult = 0.0
	launch_mult = 0.0
	kind_id = "elarien_hunt"
	display_name = "엘라리엔"
	subtitle = "사냥 시험 — 세 번 닿아라"
	_flip = Node2D.new()
	add_child(_flip)
	_cv = CharacterVisual.new()
	_cv.setup("elarien")
	_flip.add_child(_cv)
	_visual = _flip
	_pips = Pips.new()
	_pips.boss = self
	add_child(_pips)


func _ready() -> void:
	super()
	# 체력 = 남은 닿기 수 (난이도 배율을 받지 않게 여기서 다시 정함)
	max_hp = TOUCHES
	hp = TOUCHES - touches
	collision_mask = 0
	collision_layer = 0
	_collect_perches.call_deferred()
	Ch3Sfx.ensure()


func _collect_perches() -> void:
	_perches.clear()
	var w := World.get_world()
	if w and w.room:
		var keys: Array = w.room.markers.keys()
		keys.sort()
		for k in keys:
			if String(k).begins_with("perch"):
				_perches.append(w.room.markers[k])
	if _perches.is_empty():
		# 횃대 표식이 없는 방(시험 방): 처음 자리 양옆
		for dx in [0.0, -10.0, 10.0, -5.0, 5.0]:
			_perches.append(global_position + Vector2(dx * GameConst.TILE, 0))
	var best := INF
	for i in _perches.size():
		var d := _perches[i].distance_to(global_position)
		if d < best:
			best = d
			_perch = i


func state_k() -> float:
	return clampf(1.0 - _timer / _dur, 0.0, 1.0) if _dur > 0.0 else 0.0


func phase() -> int:
	return mini(touches, 2)


func _enter(s: S, dur := 0.0) -> void:
	state = s
	_timer = dur
	_dur = dur
	var pose := "idle"
	match s:
		S.AIM: pose = "aim"
		S.FAN: pose = "attack2"
		S.RAIN: pose = "special"
		S.WIND: pose = "charge"
		S.GUST: pose = "guard"
		S.LEAP: pose = "leap"
		S.STAGGER: pose = "hurt"
	_cv.set_pose(pose)


func _ai(delta: float) -> void:
	var t := GameConst.TILE
	velocity = Vector2.ZERO
	_flip.scale.x = facing
	_invuln = maxf(_invuln - delta, 0.0)
	_hurtbox.monitorable = _invuln <= 0.0 and state != S.LEAP and state != S.DONE
	_cv.modulate = Color(1.6, 1.6, 1.6) if _flash > 0.0 else (Color(1, 1, 1, 0.6 + 0.4 * sin(_t * 30.0)) if _invuln > 0.0 else Color.WHITE)
	var p := player()
	if state == S.DONE:
		return
	if not engaged or p == null or not p.is_alive():
		if state != S.LEAP:
			_cv.set_pose("idle")
			if p:
				face_player()
		_clear_lines()
		if state != S.WAIT and state != S.LEAP:
			_enter(S.WAIT)
		return
	_timer -= delta
	_since_move += delta
	# 몸에 닿기
	if _invuln <= 0.0 and state != S.LEAP and p.center().distance_to(global_position + Vector2(0, -16)) < BODY_TOUCH + 8.0:
		_touch("body")
		return
	match state:
		S.WAIT:
			_enter(S.PERCH)
			_cd = 0.8
		S.PERCH:
			face_player()
			_cv.set_pose("idle")
			_cd -= delta
			if _cd > 0.0:
				return
			if phase() >= 1 and p.global_position.distance_to(global_position) < 3.6 * t and absf(p.global_position.y - global_position.y) < 2.5 * t:
				_start_gust()
			elif _since_move > RELOCATE_EVERY[phase()] and _perches.size() > 1:
				_start_leap(_pick_perch(p))
			else:
				_next_attack(p)
		S.AIM, S.WIND:
			face_player()
			var lock := _timer < LOCK_TIME
			if not lock:
				aim_dir = (p.center() - _bow()).normalized()
				_set_aim_meta()
			for l in _lines:
				l.aim(_bow(), aim_dir)
				l.k = clampf(1.0 - (_timer - LOCK_TIME) / maxf(_dur - LOCK_TIME, 0.01), 0.0, 1.0)
				if lock:
					l.lock()
			if _timer <= 0.0:
				_clear_lines()
				if state == S.WIND:
					_fire(aim_dir, "wind")
				else:
					_fire(aim_dir, "arrow")
				_after_shot()
		S.FAN:
			face_player()
			var lock2 := _timer < LOCK_TIME
			if not lock2:
				aim_dir = (p.center() - _bow()).normalized()
				_set_aim_meta()
			for i in _lines.size():
				var d := aim_dir.rotated((i - 1) * 0.24)
				_lines[i].aim(_bow(), d)
				_lines[i].k = clampf(1.0 - (_timer - LOCK_TIME) / maxf(_dur - LOCK_TIME, 0.01), 0.0, 1.0)
				if lock2:
					_lines[i].lock()
			if _timer <= 0.0:
				_clear_lines()
				for i in 3:
					_fire(aim_dir.rotated((i - 1) * 0.24), "arrow")
				_after_shot()
		S.RAIN:
			if _timer <= 0.0:
				_after_shot()
		S.GUST:
			if _timer <= 0.0:
				_gust(p)
				_after_shot()
		S.LEAP:
			var k := clampf(1.0 - _timer / _dur, 0.0, 1.0)
			var pos := _leap_from.lerp(_leap_to, k)
			pos.y -= sin(k * PI) * maxf(3.0 * t, absf(_leap_to.y - _leap_from.y) * 0.4 + 2.0 * t)
			global_position = pos
			facing = 1 if _leap_to.x >= _leap_from.x else -1
			if Engine.get_physics_frames() % 3 == 0:
				_feather(global_position + Vector2(0, -16))
			if _timer <= 0.0:
				global_position = _leap_to
				_since_move = 0.0
				Ch3Sfx.play(&"ch3_rustle", -4.0, 0.1)
				Fx.burst(global_position, 8, {direction = Vector2.UP, spread = 70.0, speed_min = 20.0, speed_max = 60.0, lifetime = 0.4,
					gradient = Palette.fade_gradient(Color("#a8d878")), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 200)})
				_enter(S.PERCH)
				_cd = 0.7
		S.STAGGER:
			if _timer <= 0.0:
				if touches >= TOUCHES:
					_finish()
				else:
					_start_leap(_pick_perch(p))


func _bow() -> Vector2:
	return global_position + Vector2(facing * 11.0, -27.0)


func _set_aim_meta() -> void:
	var local := Vector2(aim_dir.x * facing, aim_dir.y)
	_cv.set_meta("aim_ang", clampf(local.angle(), -1.2, 1.0))


func _next_attack(p: Player) -> void:
	var ph := phase()
	var choice := "aim"
	match ph:
		0:
			choice = "aim"
		1:
			choice = ["fan", "aim", "fan"][_pattern % 3]
		2:
			choice = ["rain", "fan", "wind", "aim"][_pattern % 4]
	_pattern += 1
	face_player()
	aim_dir = (p.center() - _bow()).normalized()
	_set_aim_meta()
	match choice:
		"aim":
			_enter(S.AIM, Difficulty.telegraph(AIM_TIME[ph]) + LOCK_TIME)
			_add_line(0.0)
			Ch3Sfx.play(&"bow_draw", -4.0, 0.05)
		"fan":
			_enter(S.FAN, Difficulty.telegraph(AIM_TIME[ph] * 1.1) + LOCK_TIME)
			for i in 3:
				_add_line(0.0)
			Ch3Sfx.play(&"bow_draw", -2.0, 0.05)
		"wind":
			_enter(S.WIND, Difficulty.telegraph(1.1) + LOCK_TIME)
			var l := _add_line(12.0)
			l.band = 12.0
			Ch3Sfx.play(&"wind", -6.0, 0.05)
		"rain":
			_start_rain(p)


func _add_line(band: float) -> AimLine:
	var l := AimLine.new()
	l.band = band
	l.max_len = 40.0 * GameConst.TILE
	Fx.effect_parent().add_child(l)
	l.aim(_bow(), aim_dir)
	_lines.append(l)
	return l


func _clear_lines() -> void:
	for l in _lines:
		if is_instance_valid(l):
			l.queue_free()
	_lines.clear()


func _fire(d: Vector2, style: String) -> void:
	var a := ElfArrow.new()
	if style == "wind":
		a.setup(_bow() + d * 6.0, d, WIND_SPEED_T * GameConst.TILE, {"style": "wind", "push": 430.0, "cause": "elarien_wind", "life": 3.0})
	else:
		a.setup(_bow() + d * 6.0, d, ARROW_SPEED_T * GameConst.TILE, {"style": "arrow", "cause": "elarien_arrow", "life": 2.5})
	Fx.effect_parent().add_child(a)
	_cv.set_pose("attack")
	Ch3Sfx.play(&"arrow_shot", 0.0, 0.08)
	Fx.burst(_bow() + d * 8.0, 5, {direction = d, spread = 25.0, speed_min = 30.0, speed_max = 80.0, lifetime = 0.2,
		gradient = Palette.fade_gradient(Color(0.9, 1.0, 0.85)), size_min = 1.0, size_max = 1.5, gravity = Vector2.ZERO, add = true})


func _after_shot() -> void:
	_shots += 1
	_enter(S.PERCH)
	_cv.set_pose("attack")
	_cd = Difficulty.rest(REST[phase()])


## 화살비: 하늘로 한 발 → 세라 둘레 바닥에 붉은 표시 → 화살이 떨어짐
func _start_rain(p: Player) -> void:
	_enter(S.RAIN, 0.9)
	_cv.set_meta("aim_ang", -1.05)
	var up := Vector2(0.15 * facing, -1).normalized()
	var a := ElfArrow.new()
	a.setup(_bow(), up, 30.0 * GameConst.TILE, {"style": "arrow", "life": 0.6})
	a.active = false
	Fx.effect_parent().add_child(a)
	Ch3Sfx.play(&"arrow_shot", 0.0, 0.05)
	var t := GameConst.TILE
	for i in RAIN_COUNT:
		var x := p.global_position.x + (i - (RAIN_COUNT - 1) * 0.5) * 2.4 * t + randf_range(-0.6, 0.6) * t
		var floor_pos := _floor_at(Vector2(x, p.global_position.y - 6.0 * t))
		if floor_pos == Vector2.INF:
			continue
		var m := RainMark.new()
		m.setup(floor_pos, Difficulty.telegraph(RAIN_WARN) + i * 0.07)
		Fx.effect_parent().add_child(m)


func _floor_at(from: Vector2) -> Vector2:
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 12.0 * GameConst.TILE), GameConst.L_WORLD | GameConst.L_PLATFORM)
	var r := space.intersect_ray(q)
	return Vector2.INF if r.is_empty() else (r.position as Vector2)


## 발밑 바람 (가까이 온 세라를 밀어냄): 붉은 고리 예고 → 바람
func _start_gust() -> void:
	_enter(S.GUST, Difficulty.telegraph(GUST_WINDUP))
	_gust_ring = GustRing.new()
	_gust_ring.global_position = global_position + Vector2(0, -14)
	(_gust_ring as GustRing).dur = _dur
	Fx.effect_parent().add_child(_gust_ring)
	Ch3Sfx.play(&"wind", -4.0, 0.05)


func _gust(p: Player) -> void:
	if _gust_ring and is_instance_valid(_gust_ring):
		_gust_ring.queue_free()
	_gust_ring = null
	Ch3Sfx.play(&"wind", 2.0, 0.05)
	Fx.ring(global_position + Vector2(0, -14), 6.0, 64.0, Color(0.82, 1.0, 0.7), 0.35, 3.0)
	var d := p.center() - (global_position + Vector2(0, -14))
	if d.length() < 4.0 * GameConst.TILE and not p.is_invincible():
		p.take_damage(1, &"elarien_gust", global_position.x)
		p.velocity = Vector2(signf(d.x if d.x != 0.0 else -facing) * 380.0, -240.0)


func _pick_perch(p: Player) -> int:
	if _perches.size() <= 1:
		return maxi(_perch, 0)
	var best := -1
	var best_score := -INF
	for i in _perches.size():
		if i == _perch:
			continue
		var d := _perches[i].distance_to(p.global_position)
		var score := minf(d, 18.0 * GameConst.TILE) + randf_range(0.0, 3.0 * GameConst.TILE)
		if d < 6.0 * GameConst.TILE:
			score -= 1000.0
		if score > best_score:
			best_score = score
			best = i
	return best


func _start_leap(to_index: int) -> void:
	_clear_lines()
	if to_index < 0 or to_index >= _perches.size():
		_enter(S.PERCH)
		return
	_perch = to_index
	_leap_from = global_position
	_leap_to = _perches[to_index]
	_enter(S.LEAP, LEAP_TIME + clampf(_leap_from.distance_to(_leap_to) / 900.0, 0.0, 0.5))
	Ch3Sfx.play(&"ch3_rustle", -2.0, 0.1)
	Sfx.play(&"jump", -4.0, 0.1)


func _feather(at: Vector2) -> void:
	Fx.burst(at, 1, {direction = Vector2(0, 1), spread = 60.0, speed_min = 10.0, speed_max = 30.0, lifetime = 0.9,
		gradient = Palette.fade_gradient(Color(0.95, 1.0, 0.9)), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 30)})


# ─── 닿기 ───────────────────────────────────────────────

func take_hit(hit: Hit) -> void:
	if not _alive or state == S.DONE or not engaged:
		return
	if _invuln > 0.0 or state == S.LEAP:
		return
	if hit.kind == &"ally":
		return
	if hit.kind == &"reflect":
		_touch("reflect")
		return
	var src := hit.source_pos
	var p := player()
	if p:
		src = p.global_position if src == Vector2.ZERO else src
	var near := (global_position + Vector2(0, -16)).distance_to(src) <= NEAR_T * GameConst.TILE
	if p and (global_position + Vector2(0, -16)).distance_to(p.center()) <= NEAR_T * GameConst.TILE:
		near = true
	if near:
		_touch("hit")
	else:
		_dodge()


## 멀리서 온 공격: 몸을 비틀어 피함
func _dodge() -> void:
	Sfx.play(&"whoosh", -6.0, 0.1)
	Fx.burst(global_position + Vector2(0, -18), 6, {spread = 180.0, speed_min = 20.0, speed_max = 50.0, lifetime = 0.3,
		gradient = Palette.fade_gradient(Color(0.9, 1.0, 0.85)), size_min = 1.0, size_max = 1.5, gravity = Vector2.ZERO})
	if not _far_hint:
		_far_hint = true
		_say("멀다. 와서 닿아 봐.")


func _touch(how: String) -> void:
	touches += 1
	hp = TOUCHES - touches
	_clear_lines()
	_invuln = INVULN_AFTER
	_flash = 0.15
	touched.emit(touches)
	var words: Array[String] = ["하나.", "둘.", "셋."]
	_say(words[mini(touches - 1, 2)], true)
	Fx.hitstop(0.12)
	Fx.shake(0.2, 0.3)
	Fx.flash(Color(0.85, 1.0, 0.75, 0.25), 0.25)
	Ch3Sfx.play(&"ch3_purify", -2.0, 0.0)
	Sfx.play(&"hit_heavy", -2.0)
	Fx.ring(global_position + Vector2(0, -16), 4.0, 40.0, Color(0.85, 1.0, 0.7), 0.4, 2.0)
	if how == "reflect":
		Fx.burst(global_position + Vector2(0, -16), 18, {spread = 180.0, speed_min = 40.0, speed_max = 120.0, lifetime = 0.4})
	_enter(S.STAGGER, 0.55 if touches < TOUCHES else 0.8)


func _finish() -> void:
	_alive = false
	_clear_lines()
	if not respawns:
		GameState.mark_killed(uid)
	state = S.DONE
	_cv.set_pose("idle")
	_cv.modulate = Color.WHITE
	face_player()
	_hurtbox.set_deferred("monitorable", false)
	defeated.emit(self)


func _say(text: String, big := false) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 16 if big else 10)
	l.add_theme_color_override("font_color", Color("#eaffc8"))
	l.add_theme_color_override("font_outline_color", Color("#0a140a"))
	l.add_theme_constant_override("outline_size", 4)
	l.position = global_position + Vector2(-12 if big else -40, -64)
	l.z_index = 40
	Fx.effect_parent().add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 10.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.0 if big else 1.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)


func _exit_tree() -> void:
	_clear_lines()


## 쓰러지지 않는다 (체력 0은 _touch에서 처리)
func _die(_dir: int) -> void:
	pass


## 머리 위 닿기 눈금 (잎 셋: 닿을 때마다 하나씩 빛남)
class Pips extends Node2D:
	var boss: ElarienHunt

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if boss == null or not boss.engaged or boss.state == ElarienHunt.S.DONE:
			return
		_offscreen_marker()
		for i in ElarienHunt.TOUCHES:
			var c := Vector2(-8 + i * 8, -48)
			var on := i < boss.touches
			var col := Color(0.85, 1.0, 0.6) if on else Color(0.3, 0.4, 0.3, 0.7)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -3), c + Vector2(2.5, 0), c + Vector2(0, 3), c + Vector2(-2.5, 0)]), col)
			if on:
				draw_circle(c, 4.0, Color(0.85, 1.0, 0.6, 0.2))


	## 화면 밖에 있으면 화면 가장자리에 그녀 쪽을 가리키는 잎 화살표 (어디서 쏘는지 알 수 있게)
	func _offscreen_marker() -> void:
		var xf := get_viewport().get_canvas_transform()
		var sp: Vector2 = xf * (boss.global_position + Vector2(0, -18))
		var size := get_viewport().get_visible_rect().size
		var r := Rect2(Vector2(18, 26), size - Vector2(36, 60))
		if r.has_point(sp):
			return
		var cp := Vector2(clampf(sp.x, r.position.x, r.end.x), clampf(sp.y, r.position.y, r.end.y))
		var d := (sp - cp).normalized()
		var lp := to_local(xf.affine_inverse() * cp)
		var n := Vector2(-d.y, d.x)
		var pulse := 0.7 + 0.3 * sin(boss._t * 6.0)
		draw_circle(lp, 9.0, Color(0.05, 0.1, 0.05, 0.6))
		draw_colored_polygon(PackedVector2Array([lp + d * 8.0, lp - d * 3.0 + n * 5.0, lp - d * 1.0, lp - d * 3.0 - n * 5.0]), Color(0.85, 1.0, 0.6, pulse))
		if boss.state in [ElarienHunt.S.AIM, ElarienHunt.S.FAN, ElarienHunt.S.WIND]:
			draw_arc(lp, 11.0, 0, TAU, 16, Color(Palette.DANGER, pulse), 1.5)


## 화살비 표시: 바닥에 붉은 표시(점점 진해짐) → 하늘에서 화살 한 대
class RainMark extends Node2D:
	var dur := 1.2
	var _t := 0.0
	var _fired := false

	func setup(at: Vector2, p_dur: float) -> void:
		global_position = at
		dur = p_dur
		z_index = 4

	func _process(delta: float) -> void:
		_t += delta * Fx.enemy_time
		if not _fired and _t >= dur:
			_fired = true
			var a := ElfArrow.new()
			a.setup(global_position + Vector2(randf_range(-6, 6), -15.0 * GameConst.TILE), Vector2(0.04, 1), 34.0 * GameConst.TILE,
				{"style": "rain", "cause": "elarien_rain", "life": 1.2})
			Fx.effect_parent().add_child(a)
		if _t > dur + 0.5:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := clampf(_t / dur, 0.0, 1.0)
		var pulse := 0.6 + 0.4 * sin(_t * 28.0)
		var w := 18.0 - 6.0 * k
		draw_rect(Rect2(-w * 0.5, -2, w, 2), Color(Palette.DANGER, (0.3 + 0.6 * k) * pulse))
		draw_line(Vector2(0, -3), Vector2(0, -3 - 40.0 * k), Color(Palette.DANGER, 0.15 * k), 1.0)
		draw_colored_polygon(PackedVector2Array([Vector2(-3, -7), Vector2(3, -7), Vector2(0, -3)]), Color(Palette.DANGER, 0.8 * k * pulse))


## 발밑 바람 예고 고리 (붉은 원이 좁아짐)
class GustRing extends Node2D:
	var dur := 0.65
	var _t := 0.0

	func _ready() -> void:
		z_index = 5

	func _process(delta: float) -> void:
		_t += delta * Fx.enemy_time
		if _t > dur + 0.3:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := clampf(_t / dur, 0.0, 1.0)
		var pulse := 0.6 + 0.4 * sin(_t * 30.0)
		# 바깥 고리 = 바람이 닿는 범위(4T). 안쪽 고리가 바깥으로 차오르면 터진다
		draw_arc(Vector2.ZERO, 62.0, 0, TAU, 40, Color(Palette.DANGER, (0.3 + 0.6 * k) * pulse), 2.0)
		draw_arc(Vector2.ZERO, lerpf(8.0, 60.0, k), 0, TAU, 32, Color(Palette.DANGER, 0.25 + 0.3 * k), 1.0)
		draw_circle(Vector2.ZERO, 62.0, Color(Palette.DANGER, 0.05 * k))
