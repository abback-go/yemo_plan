class_name VineStalker
extends EnemyBase
## 덩굴 사냥꾼 (docs/archive/sera/chapter3.md 4절) — 덤불인 척 숨어 있는 포식 식물.
## 숨어 있을 땐 평범한 덤불처럼 보인다(아주 가끔 덤불 사이로 노란 눈이 깜빡 — 눈치 빠른 사람만 알아챔). 맞지도 않는다.
## 드러나는 때:
##   - 세라가 3.5T 안으로 다가옴 → 기습: 덤불이 갈라지며 곧장 덩굴 채찍(예고 짧음 0.45초)
##   - 여우창문에 비침(1장 환영 벽과 같은 illusion 그룹) → 정체가 드러나 1.6초 동안 어리둥절(무방비, 피해 1.5배) — 여우창문 보상
##   - 불에 맞음 → 놀라서 드러남
## 드러난 뒤: 덩굴 채찍 2연타 — 덩굴을 뒤로 감아올림(붉은 예고 0.6초) → ① 앞으로 후려침(5T) → 0.3초 → ② 위에서 내려찍기(3.5T)
## 체력이 절반 아래면 채찍 사이가 짧아지고, 가끔 땅속으로 숨었다가 세라 가까이에서 다시 솟는다.

enum S { HIDDEN, EMERGE, DAZED, IDLE, WIND, LASH1, GAP, LASH2, RECOVER, BURROW, SURFACE }

const HP := 820
const NOTICE_T := 3.5
const WIND_TIME := 0.6
const AMBUSH_WIND := 0.45
const LASH_TIME := 0.18
const GAP_TIME := 0.3
const RECOVER_TIME := 0.8
const REST := Vector2(1.2, 1.8)
const REACH1 := 5.0
const REACH2 := 3.5
const NAME := "덩굴 사냥꾼"

var state: S = S.HIDDEN
var revealed := false
var _timer := 0.0
var _dur := 0.0
var _cd := 1.0
var _ambush := false
var _peek := 0.0
var _burrows := 0
var _lash1: EnemyAttackArea
var _lash2: EnemyAttackArea
var _body: EnemyAttackArea


func _build() -> void:
	max_hp = HP
	body_size = Vector2(26, 26)
	knock_mult = 0.0
	launch_mult = 0.0
	kind_id = "vine_stalker"
	display_name = "" # 숨어 있는 동안엔 이름표를 띄우지 않는다 (드러날 때 NAME)
	subtitle = "덤불인 척하는 입"
	_visual = StalkerVisual.new()
	(_visual as StalkerVisual).enemy = self
	add_child(_visual)
	_lash1 = add_attack_area(Vector2(REACH1 * 16.0, 14), Vector2(REACH1 * 8.0 + 6, -14), &"vine_stalker")
	_lash1.active = false
	_lash2 = add_attack_area(Vector2(REACH2 * 16.0, 30), Vector2(REACH2 * 8.0 + 4, -14), &"vine_stalker")
	_lash2.active = false
	_body = add_attack_area(Vector2(20, 18), Vector2(0, -10), &"vine_stalker")
	_body.active = false
	_body.dodgeable = false


func _ready() -> void:
	super()
	add_to_group(&"illusion")
	_hurtbox.monitorable = false # 숨어 있는 동안엔 맞지 않는다


func state_k() -> float:
	return clampf(1.0 - _timer / _dur, 0.0, 1.0) if _dur > 0.0 else 0.0


func _enter(s: S, dur := 0.0) -> void:
	state = s
	_timer = dur
	_dur = dur


## 여우창문 (FoxWindow가 illusion 그룹에 부름): 원 안이면 정체가 드러나 어리둥절
func try_reveal(center: Vector2, radius: float) -> bool:
	if revealed or not _alive:
		return false
	if (global_position + Vector2(0, -12)).distance_to(center) > radius + 10.0:
		return false
	_reveal(false)
	return true


func is_revealed() -> bool:
	return revealed


func _reveal(ambush: bool) -> void:
	revealed = true
	_ambush = ambush
	display_name = NAME
	_hurtbox.set_deferred("monitorable", true)
	_body.active = true
	face_player()
	Ch3Sfx.play(&"ch3_rustle", 0.0, 0.1)
	Fx.burst(global_position + Vector2(0, -10), 18, {direction = Vector2.UP, spread = 80.0, speed_min = 40.0, speed_max = 110.0,
		lifetime = 0.5, gradient = Palette.fade_gradient(Color("#4e8a36")), size_min = 1.0, size_max = 2.5, gravity = Vector2(0, 300)})
	if ambush:
		_enter(S.EMERGE, 0.25)
	else:
		Sfx.play(&"reveal", -4.0, 0.0)
		_enter(S.DAZED, 1.6)
		Fx.ring(global_position + Vector2(0, -14), 6.0, 30.0, Color(0.55, 0.85, 1.0), 0.4, 2.0)


func _ai(delta: float) -> void:
	velocity.x = 0.0
	place_area(_lash1, Vector2(REACH1 * 8.0 + 6, -14))
	place_area(_lash2, Vector2(REACH2 * 8.0 + 4, -14))
	_timer -= delta
	var p := player()
	if state == S.HIDDEN:
		_peek -= delta
		if _peek < -randf_range(4.0, 7.0):
			_peek = 0.35
		if p and p.is_alive() and engaged and dist_to_player() < NOTICE_T * GameConst.TILE:
			_reveal(true)
		return
	if not engaged or p == null or not p.is_alive():
		return
	match state:
		S.EMERGE:
			if _timer <= 0.0:
				_start_wind(AMBUSH_WIND if _ambush else WIND_TIME)
		S.DAZED:
			if _timer <= 0.0:
				_enter(S.IDLE)
				_cd = 0.5
		S.IDLE:
			face_player()
			_cd -= delta
			var hurt := hp < max_hp * 0.5
			if hurt and _burrows < 3 and dist_to_player() > 7.0 * GameConst.TILE and _cd <= 0.0:
				_burrow()
			elif _cd <= 0.0 and dist_to_player() < 7.0 * GameConst.TILE:
				_start_wind(WIND_TIME)
		S.WIND:
			if _timer <= 0.0:
				_enter(S.LASH1, LASH_TIME)
				_lash1.active = true
				_lash1.dodgeable = true
				Ch3Sfx.play(&"ch3_whip", 0.0, 0.1)
				Fx.shake(0.08, 0.12)
		S.LASH1:
			if _timer <= 0.0:
				_lash1.active = false
				_enter(S.GAP, GAP_TIME)
		S.GAP:
			if _timer <= 0.0:
				_enter(S.LASH2, LASH_TIME)
				_lash2.active = true
				_lash2.dodgeable = true
				Ch3Sfx.play(&"ch3_whip", 2.0, 0.1)
				Sfx.play(&"slam", -6.0, 0.1)
				Fx.shake(0.12, 0.15)
				Fx.burst(global_position + Vector2(facing * REACH2 * 14.0, -2), 10, {direction = Vector2.UP, spread = 60.0, speed_min = 30.0,
					speed_max = 90.0, lifetime = 0.35, gradient = Palette.fade_gradient(Color("#6a8a4a")), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 300)})
		S.LASH2:
			if _timer <= 0.0:
				_lash2.active = false
				_enter(S.RECOVER, RECOVER_TIME)
		S.RECOVER:
			if _timer <= 0.0:
				_enter(S.IDLE)
				var r := Difficulty.rest(randf_range(REST.x, REST.y))
				_cd = r * (0.7 if hp < max_hp * 0.5 else 1.0)
		S.BURROW:
			if _timer <= 0.0:
				# 세라 가까이(앞쪽 3T)로 옮겨 솟는다 — 바닥이 있는 곳만
				var target := p.global_position + Vector2(-p.facing * 3.0 * GameConst.TILE, 0)
				if _ground_at(target.x):
					global_position.x = target.x
				_enter(S.SURFACE, Difficulty.telegraph(0.7))
		S.SURFACE:
			if _timer <= 0.0:
				_hurtbox.set_deferred("monitorable", true)
				_body.active = true
				face_player()
				Ch3Sfx.play(&"ch3_rustle", 0.0, 0.1)
				Fx.burst(global_position + Vector2(0, -6), 16, {direction = Vector2.UP, spread = 50.0, speed_min = 50.0, speed_max = 130.0,
					lifetime = 0.5, gradient = Palette.fade_gradient(Color("#6a5a3a")), size_min = 1.0, size_max = 2.5, gravity = Vector2(0, 300)})
				_start_wind(AMBUSH_WIND)


func _start_wind(dur: float) -> void:
	face_player()
	_enter(S.WIND, Difficulty.telegraph(dur))
	Ch3Sfx.play(&"ch3_rustle", -6.0, 0.15)


func _burrow() -> void:
	_burrows += 1
	_enter(S.BURROW, 1.0)
	_hurtbox.set_deferred("monitorable", false)
	_body.active = false
	Ch3Sfx.play(&"ch3_rustle", -2.0, 0.1)
	Fx.burst(global_position + Vector2(0, -6), 14, {direction = Vector2.UP, spread = 50.0, speed_min = 30.0, speed_max = 90.0,
		lifetime = 0.5, gradient = Palette.fade_gradient(Color("#6a5a3a")), size_min = 1.0, size_max = 2.5, gravity = Vector2(0, 300)})


func _ground_at(x: float) -> bool:
	var space := get_world_2d().direct_space_state
	var from := Vector2(x, global_position.y - 8)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 16), GameConst.L_WORLD)
	var r := space.intersect_ray(q)
	if r.is_empty():
		return false
	var q2 := PhysicsRayQueryParameters2D.create(Vector2(x, global_position.y - 24), Vector2(x, global_position.y - 9), GameConst.L_WORLD)
	return space.intersect_ray(q2).is_empty()


func modify_damage(_hit: Hit) -> float:
	if state == S.HIDDEN or state == S.BURROW or state == S.SURFACE:
		return 0.0
	return 1.5 if state == S.DAZED else 1.0


func _on_blocked(_hit: Hit) -> void:
	if state == S.HIDDEN:
		_reveal(false) # 불에 맞으면 놀라 드러남 (피해는 없음)


## 숨어 있는 동안엔 피격 상자가 꺼져 있어 맞지 않지만, 불기둥처럼 범위로 맞히는 공격은 여기로 온다
func take_hit(hit: Hit) -> void:
	if state == S.HIDDEN:
		_reveal(false)
		return
	super(hit)


## 덩굴 사냥꾼 그림: 숨었을 땐 둥근 덤불, 드러나면 꽃봉오리 입 + 덩굴 채찍 두 줄기
class StalkerVisual extends Node2D:
	const LEAF := Color("#2f5a26")
	const LEAF_HI := Color("#5a8f3e")
	const LEAF_SH := Color("#1c3a18")
	const VINE := Color("#3e6a2a")
	const MAW := Color("#6a1e2a")
	const MAW_IN := Color("#c84a4a")
	var enemy: VineStalker

	func _process(_d: float) -> void:
		if enemy == null:
			return
		scale.x = enemy.facing
		z_index = 1

	func _draw() -> void:
		if enemy == null:
			return
		var t := enemy._t
		var st := enemy.state
		var k := enemy.state_k()
		var wh := enemy.flash_amount() > 0.0
		var hidden := st == VineStalker.S.HIDDEN or st == VineStalker.S.BURROW
		if st == VineStalker.S.SURFACE:
			# 땅이 들썩임 (예고)
			var shake := sin(t * 40.0) * 1.5
			draw_rect(Rect2(-12 + shake, -3, 24, 3), Color("#4a3a26"))
			for i in 5:
				draw_rect(Rect2(-10 + i * 5 + shake, -5 - (i % 2) * 2, 2, 2), Color("#6a5a3a"))
			draw_arc(Vector2(0, -2), 14.0, PI, TAU, 12, Color(Palette.DANGER, 0.5 + 0.4 * sin(t * 30.0)), 1.0)
			return
		if st == VineStalker.S.BURROW:
			var sink := k
			_bush(t, 1.0 - sink, false)
			return
		# 덤불 (숨었을 땐 전부, 드러나면 갈라진 잎이 양옆으로)
		var open := 0.0 if hidden else 1.0
		if st == VineStalker.S.EMERGE:
			open = k
		_bush(t, 1.0, open > 0.0, open)
		if hidden:
			# 아주 가끔 덤불 사이로 노란 눈 깜빡
			if enemy._peek > 0.0:
				draw_rect(Rect2(2, -12, 2, 1), Color("#e8d040"))
				draw_rect(Rect2(6, -12, 2, 1), Color("#e8d040"))
			return
		# 줄기 + 꽃봉오리 입
		var rise := 18.0 * open
		var lean := 0.0
		var maw_open := 0.25 + 0.15 * sin(t * 3.0)
		var red := 0.0
		match st:
			VineStalker.S.WIND:
				lean = -6.0 * k
				maw_open = 0.5 + 0.4 * k
				red = k * (0.7 + 0.3 * sin(t * 30.0))
			VineStalker.S.LASH1, VineStalker.S.LASH2:
				lean = 6.0
				maw_open = 1.0
			VineStalker.S.DAZED:
				lean = sin(t * 8.0) * 3.0
				maw_open = 0.1
		var neck := Vector2(lean * 0.4, -rise * 0.5)
		var head := Vector2(lean, -rise - 6)
		draw_line(Vector2(0, -2), neck, VINE if not wh else Color.WHITE, 4.0)
		draw_line(neck, head, VINE if not wh else Color.WHITE, 3.0)
		# 꽃잎 입 (위·아래 턱)
		var hc := head
		var top_lip := PackedVector2Array([hc + Vector2(-5, 0), hc + Vector2(2, -6 - maw_open * 3.0), hc + Vector2(9, -2 - maw_open * 4.0), hc + Vector2(6, 0)])
		var bot_lip := PackedVector2Array([hc + Vector2(-5, 0), hc + Vector2(6, 0), hc + Vector2(9, 2 + maw_open * 4.0), hc + Vector2(2, 6 + maw_open * 2.0)])
		if maw_open > 0.2:
			draw_colored_polygon(PackedVector2Array([hc + Vector2(-2, 0), hc + Vector2(8, -2 - maw_open * 3.0), hc + Vector2(8, 2 + maw_open * 3.0)]), MAW_IN)
			for i in 3:
				draw_line(hc + Vector2(2 + i * 2.5, -1.5 - maw_open * 2.0), hc + Vector2(3 + i * 2.5, 0), Color("#f0e8d0"), 1.0)
		var lip := Color("#8a2a3a") if not wh else Color.WHITE
		if red > 0.0:
			lip = lip.lerp(Palette.DANGER, red)
		draw_colored_polygon(top_lip, lip)
		draw_colored_polygon(bot_lip, lip.darkened(0.2))
		draw_line(hc + Vector2(-4, -1), hc + Vector2(8, -2 - maw_open * 4.0), Color("#c85a6a"), 1.0)
		# 노란 눈 (꽃받침 위)
		var eye := Color("#e8d040") if st != VineStalker.S.DAZED else Color(0.55, 0.85, 1.0)
		draw_rect(Rect2(hc.x - 3, hc.y - 6, 2, 2), eye)
		draw_rect(Rect2(hc.x + 0.5, hc.y - 7, 2, 2), eye)
		if st == VineStalker.S.DAZED:
			for i in 3:
				var a := t * 4.0 + TAU * i / 3.0
				draw_rect(Rect2(hc + Vector2(cos(a) * 8.0, -12 + sin(a) * 3.0), Vector2(2, 2)), Color(0.6, 0.9, 1.0, 0.8))
		# 덩굴 채찍 두 줄기
		_whips(t, st, k, red, wh)

	func _bush(t: float, s: float, parted: bool, open := 0.0) -> void:
		var sw := sin(t * 1.3) * 0.6
		var spread := 7.0 * open if parted else 0.0
		var blobs := [[Vector2(-8, -7), 7.0], [Vector2(7, -7), 7.0], [Vector2(0, -12), 8.5], [Vector2(-3, -4), 6.0], [Vector2(4, -4), 6.0]]
		for i in blobs.size():
			var c: Vector2 = blobs[i][0]
			var r: float = blobs[i][1]
			if parted:
				c.x += spread * signf(c.x + 0.1)
				if i == 2:
					continue
			c = c * s + Vector2(sw * (1.0 if i % 2 else -1.0), (1.0 - s) * 6.0)
			draw_circle(c, r * s, LEAF_SH)
			draw_circle(c + Vector2(-0.5, -0.5), r * s * 0.85, LEAF)
			draw_line(c + Vector2(-r * 0.5 * s, -r * 0.4 * s), c + Vector2(r * 0.2 * s, -r * 0.7 * s), LEAF_HI, 1.0)
		# 잎 끝
		for i in 6:
			var lp := Vector2(-12 + i * 5 + (spread * (1.0 if i > 2 else -1.0)), -10 - (i % 3) * 3) * s
			draw_colored_polygon(PackedVector2Array([lp, lp + Vector2(2, -3), lp + Vector2(3, 0)]), LEAF_HI)

	func _whips(t: float, st: int, k: float, red: float, wh: bool) -> void:
		var col := Color("#4a7a30") if not wh else Color.WHITE
		if red > 0.0:
			col = col.lerp(Palette.DANGER, red * 0.7)
		# 채찍 1: 앞으로 길게 / 채찍 2: 위에서 내려찍기
		var reach1 := 0.0
		var reach2 := 0.0
		var coil := 0.0
		match st:
			VineStalker.S.WIND:
				coil = k
			VineStalker.S.LASH1:
				reach1 = 1.0
			VineStalker.S.GAP:
				reach1 = 1.0 - k
				coil = k * 0.6
			VineStalker.S.LASH2:
				reach2 = 1.0
			VineStalker.S.RECOVER:
				reach2 = 1.0 - k
		for side in 2:
			var root := Vector2(-6 + side * 12, -6)
			var pts := PackedVector2Array([root])
			var n := 8
			for i in range(1, n + 1):
				var q := float(i) / n
				var p := root
				if reach1 > 0.0 and side == 1:
					p = root + Vector2(q * VineStalker.REACH1 * 16.0 * reach1, -8.0 * sin(q * PI) * (1.0 - reach1) - 6.0)
				elif reach2 > 0.0 and side == 0:
					var ang := lerpf(-PI * 0.6, 0.15, reach2) * q
					p = root + Vector2(cos(ang - 0.6), sin(ang - 0.6)) * q * VineStalker.REACH2 * 16.0 * maxf(reach2, 0.3) + Vector2(0, -4)
				else:
					# 감아올린 채찍 (예고) 또는 쉬는 채찍
					var ang2 := -PI * 0.5 - (0.9 if side == 0 else 0.4) - coil * 1.2 + sin(t * 2.0 + side + q * 3.0) * 0.15
					p = root + Vector2(cos(ang2 - q * coil * 2.5), sin(ang2 - q * coil * 2.5)) * q * (14.0 + coil * 4.0)
				pts.append(p)
			draw_polyline(pts, col.darkened(0.25), 3.0)
			draw_polyline(pts, col, 1.5)
			# 가시
			for i in range(2, pts.size(), 2):
				draw_rect(Rect2(pts[i] + Vector2(-0.5, -2), Vector2(1, 2)), Color("#c8d890"))
