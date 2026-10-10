class_name EColossus
extends EEnemy
## 거구 "검은 거상": 느리게 걸어와(초속 34) 가까워지면 두 주먹을 머리 위로 들어(0.85초, 체력 절반 아래면 0.65초 — 땅에 붉은 범위 예고)
## 내려찍는다 → 좌우 90px 땅 충격파(땅에 있으면 피해 2, 점프·순간이동으로 피함) → 0.9초 숨 고르기.
## 거의 밀리지 않는다(넉백 92% 버팀) — 봉공으로 묶어야 준비 동작이 끊긴다. 몸에 닿아도 피해 1.

enum S { WALK, WIND, SLAM, REST }

const WALK := 34.0
const REACH := 90.0
const SLAM_T := 0.14
const REST_T := 0.9

var st := S.WALK
var st_t := 0.0
var _cool := 1.0
var _step := 0.0 ## 걸음 위상


func _init() -> void:
	max_hp = 2400
	size = Vector2(40, 62)
	knock_resist = 0.92
	contact_dmg = 1


func _wind_time() -> float:
	return 0.65 if hp < max_hp / 2 else 0.85


func _slam_x() -> float:
	return global_position.x + float(facing) * 22.0


func _think(delta: float) -> void:
	st_t += delta
	_cool = maxf(_cool - delta, 0.0)
	match st:
		S.WALK:
			var dx := eska.global_position.x - global_position.x if eska_ok() else 0.0
			facing = toward_eska()
			var want := signf(dx) * WALK if absf(dx) > 60.0 else 0.0
			velocity.x = move_toward(velocity.x, want, 200.0 * delta)
			if absf(velocity.x) > 5.0:
				var prev := _step
				_step += delta * 4.2
				if int(prev / PI) != int(_step / PI): # 발이 땅에 닿을 때마다 쿵
					Fx.shake(0.18, 0.08)
					EVfx.land_dust(global_position + Vector2(float(facing) * 8.0, 0))
			if eska_ok() and _cool <= 0.0 and absf(dx) < REACH + 10.0:
				_go(S.WIND)
				velocity.x = 0.0
				Sfx.play_pitch(&"growl", 0.7, -4.0)
		S.WIND:
			velocity.x = 0.0
			if st_t >= _wind_time():
				_go(S.SLAM)
				_slam()
		S.SLAM:
			if st_t >= SLAM_T:
				_go(S.REST)
		S.REST:
			if st_t >= REST_T:
				_go(S.WALK)
				_cool = 0.9 + randf() * 0.6


func _go(s: S) -> void:
	st = s
	st_t = 0.0


func _slam() -> void:
	var p := Vector2(_slam_x(), global_position.y)
	EFoeFx.shock(p, REACH)
	Fx.shake(1.0, 0.3)
	Fx.hitstop(0.05)
	PVfx.kick(Vector2(0, 5))
	Sfx.play_pitch(&"slam", 0.8, 0.0)
	if eska_ok() and absf(eska.global_position.x - p.x) < REACH + 4.0 and eska.global_position.y > global_position.y - 24.0:
		eska.hurt(2, p)


func _interrupted() -> void:
	if st == S.WIND:
		_go(S.WALK)
		_cool = 1.2


func _contact_now() -> bool:
	return true


# ═══════════════════════════════════════════════════════════
# 그림: 검은 갑옷 몸통 + 뼈색 어깨받이·뿔 투구(붉은 눈구멍) + 거대한 두 주먹, 가슴에 붉은 금
# ═══════════════════════════════════════════════════════════

func _paint_body(a: float) -> void:
	var raise := 0.0 ## 0 = 내림, 1 = 머리 위
	var smash := 0.0 ## 내려찍은 뒤 남은 정도
	if st == S.WIND:
		raise = 1.0 - pow(1.0 - minf(st_t / (_wind_time() * 0.7), 1.0), 3.0)
		_paint_warn(a)
	elif st == S.SLAM or st == S.REST:
		smash = 1.0 - (st_t / (SLAM_T + REST_T) if st == S.REST else 0.0)
	var walk := sin(_step)
	var bob := absf(walk) * 1.5 if absf(velocity.x) > 5.0 else 0.0
	var crouch := 4.0 * smash + 2.0 * raise
	var o := Vector2(2.0 * smash, crouch - bob)
	# 뒤쪽 팔 (어둡게)
	_arm(Vector2(-14, -50) + o, raise, smash, -walk, true, a)
	# 다리
	for leg in 2:
		var s := 1.0 if leg == 0 else -1.0
		var lift := maxf(walk * s, 0.0) * 3.0 if absf(velocity.x) > 5.0 else 0.0
		var x := 8.0 * s - 1.0 + walk * s * 3.0
		pd.draw_colored_polygon(PackedVector2Array([Vector2(x - 7, -20) + o * 0.5, Vector2(x + 6, -20) + o * 0.5, Vector2(x + 8, -lift), Vector2(x - 8, -lift)]),
			col(SHADE if leg == 1 else BLACK, a))
		pd.draw_rect(Rect2(Vector2(x - 9, -3.5 - lift), Vector2(18, 3.5)), col(BONE_DIM if leg == 0 else SHADE, a))
	# 몸통 (위가 넓은 사다리꼴)
	var torso := PackedVector2Array([Vector2(-15, -18) + o, Vector2(14, -18) + o, Vector2(23, -50) + o, Vector2(10, -58) + o, Vector2(-12, -57) + o, Vector2(-24, -48) + o])
	pd.draw_colored_polygon(torso, col(BLACK, a))
	# 가슴판 두 장 (가운데로 모이는 V) + 허리띠
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-19, -47) + o, Vector2(-1, -45) + o, Vector2(-1, -27) + o, Vector2(-12, -31) + o]), col(SHADE, a))
	pd.draw_colored_polygon(PackedVector2Array([Vector2(1, -45) + o, Vector2(19, -48) + o, Vector2(12, -31) + o, Vector2(1, -27) + o]), col(SHADE, a))
	pd.draw_rect(Rect2(Vector2(-15, -23) + o, Vector2(29, 4)), col(BONE_DIM, a * 0.8))
	# 가슴의 붉은 금 (들어 올릴수록 밝아짐)
	var glow := 0.45 + 0.55 * maxf(raise, smash)
	var crack := PackedVector2Array([Vector2(-1, -46) + o, Vector2(2, -40) + o, Vector2(-2, -35) + o, Vector2(1, -28) + o])
	pd.glow(Vector2(0, -37) + o, 10.0 + 8.0 * glow, Color(RED, 0.3 * glow * a), 0.0)
	pd.draw_polyline(crack, Color(RED.lerp(RED_HOT, glow * 0.6), a), 2.0)
	# 투구: 어깨 사이에 낮게 박힌 뼈 투구 — 뒤로 크게 휜 숫양 뿔 둘 + T자 눈구멍의 붉은 빛
	var h := Vector2(3, -57) + o + Vector2(1.5 * raise, -1.5 * raise)
	for sd in [-1.0, 1.0]: # 뿔 (뒤쪽 것은 어둡게 먼저)
		var base: Vector2 = h + Vector2(sd * 3.0 - 2.0, -7.0)
		var horn := PackedVector2Array()
		for i in 6:
			var f := float(i) / 5.0
			horn.append(base + Vector2(-f * 13.0 + sd * 2.0, -f * 9.0 + f * f * 10.0))
		for i in range(1, horn.size()):
			var w := 4.5 * (1.0 - float(i) / 6.0) + 1.0
			var hc := col(BONE_DIM if sd < 0.0 else BONE, a)
			pd.line2(horn[i - 1], horn[i], hc, hc, w + 0.8, w)
	pd.draw_colored_polygon(PackedVector2Array([h + Vector2(-8, 5), h + Vector2(-9, -4), h + Vector2(-4, -10), h + Vector2(5, -10),
		h + Vector2(10, -4), h + Vector2(10, 4), h + Vector2(3, 7)]), col(BONE, a))
	pd.draw_line(h + Vector2(-7, -4), h + Vector2(-2, -9), col(BONE_DIM, a), 1.0)
	pd.draw_rect(Rect2(h + Vector2(0, -4), Vector2(10, 2.6)), col(BLACK, a))
	pd.draw_rect(Rect2(h + Vector2(5, -4), Vector2(2.6, 9)), col(BLACK, a))
	pd.glow(h + Vector2(6, -3), 5.0 + 5.0 * glow, Color(RED, 0.55 * glow * a), 0.0)
	pd.draw_rect(Rect2(h + Vector2(2, -3.4), Vector2(7, 1.4)), Color(RED.lerp(RED_HOT, glow), a))
	# 어깨받이
	for p: Vector2 in [Vector2(-20, -50), Vector2(18, -52)]:
		var q := p + o
		pd.draw_colored_polygon(PackedVector2Array([q + Vector2(-9, 3), q + Vector2(-7, -5), q + Vector2(0, -8), q + Vector2(8, -5), q + Vector2(10, 3)]), col(BONE, a))
		pd.draw_line(q + Vector2(-7, 1), q + Vector2(8, 1), col(BONE_DIM, a), 1.0)
	# 앞쪽 팔
	_arm(Vector2(18, -50) + o, raise, smash, walk, false, a)


## 팔 하나: 어깨 → 팔꿈치 → 큰 주먹 (들기·내려찍기 자세를 섞음)
func _arm(sh: Vector2, raise: float, smash: float, swing: float, back: bool, a: float) -> void:
	var rest_fist := sh + Vector2(4.0 + swing * 5.0, 34.0)
	var up_fist := Vector2(6.0 if back else 12.0, -86.0)
	var down_fist := Vector2(30.0 if back else 34.0, -8.0)
	var fist := rest_fist.lerp(up_fist, raise).lerp(down_fist, smash)
	var elbow := (sh + fist) * 0.5 + Vector2(8.0 - 4.0 * raise, 2.0 - 6.0 * raise)
	var c := col(SHADE if back else BLACK, a)
	pd.line2(sh, elbow, c, c, 12.0, 10.0)
	pd.line2(elbow, fist, c, c, 10.0, 12.0)
	pd.draw_circle(fist, 8.5, c)
	pd.draw_line(fist + Vector2(3, -6), fist + Vector2(7, 3), col(BONE_DIM if back else BONE, a), 2.0) # 뼈 마디


## 들어 올리는 동안 땅에 붉은 범위 예고 (내려찍을 곳 좌우 90px)
func _paint_warn(a: float) -> void:
	var f := minf(st_t / _wind_time(), 1.0)
	var blink := 0.55 + 0.45 * sin(st_t * (20.0 + 30.0 * f))
	var x0 := 22.0 - REACH
	var x1 := 22.0 + REACH
	pd.draw_rect(Rect2(Vector2(x0, -2), Vector2(x1 - x0, 2)), Color(RED, (0.2 + 0.5 * f) * blink * a))
	pd.line2(Vector2(x0, -1), Vector2(x0, -12.0 * f), Color(RED, 0.7 * blink * a), Color(RED, 0.0), 1.5, 0.5)
	pd.line2(Vector2(x1, -1), Vector2(x1, -12.0 * f), Color(RED, 0.7 * blink * a), Color(RED, 0.0), 1.5, 0.5)
