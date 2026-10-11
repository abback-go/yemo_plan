class_name ERunner
extends EEnemy
## 돌진형 "뼈가면 사냥개": 다가오다 가까워지면 웅크려 눈이 붉게 타오르고(0.45초, 땅에 붉은 선 예고),
## 일직선으로 돌진(닿으면 피해 1, 돌진 중엔 맞아도 밀리지 않음) → 잠깐 숨 고르기(이때가 반격 기회).
## 웅크린 동안 때리면 돌진이 끊긴다.

enum S { IDLE, WIND, DASH, REST }

const WALK := 70.0
const SEE := 190.0 ## 이 거리 안에 들어오면 돌진 준비
const WIND_T := 0.45
const DASH_V := 330.0
const DASH_T := 0.5
const REST_T := 0.6

var st := S.IDLE
var st_t := 0.0
var _cool := 0.6
var _dir := 1
var _trail_t := 0.0


func _init() -> void:
	max_hp = 360
	size = Vector2(28, 20)
	contact_dmg = 1


func _think(delta: float) -> void:
	st_t += delta
	_cool = maxf(_cool - delta, 0.0)
	match st:
		S.IDLE:
			var dx := eska.global_position.x - global_position.x if eska_ok() else 0.0
			facing = toward_eska()
			var want := 0.0 if absf(dx) < 46.0 or not eska_ok() else signf(dx) * WALK
			velocity.x = move_toward(velocity.x, want, 500.0 * delta)
			if eska_ok() and _cool <= 0.0 and absf(dx) < SEE and absf(eska.global_position.y - global_position.y) < 70.0:
				_go(S.WIND)
				_dir = facing
				velocity.x = -_dir * 40.0 # 뒤로 살짝 물러서며 웅크림
				Sfx.play_pitch(&"charger_windup", 1.25, -8.0)
		S.WIND:
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			if st_t >= WIND_T:
				_go(S.DASH)
				velocity.x = _dir * DASH_V
				Sfx.play_pitch(&"charger_charge", 1.15, -6.0)
				EVfx.land_dust(global_position)
		S.DASH:
			velocity.x = _dir * DASH_V
			_trail_t -= delta
			if _trail_t <= 0.0:
				_trail_t = 0.03
				var pp := PParticles.get_layer(false)
				pp.spawn(global_position + Vector2(-_dir * 10, -randf_range(4, 14)), Vector2(-_dir * randf_range(20, 60), randf_range(-20, 0)), Vector2.ZERO,
					0.3, randf_range(3.0, 5.0), Color(BLACK, 0.6), Color(RED_DEEP, 0.0), 2, 2.0)
			if is_on_wall():
				_go(S.REST)
				velocity.x = -_dir * 90.0
				Fx.shake(0.3, 0.12)
			elif st_t >= DASH_T:
				_go(S.REST)
		S.REST:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if st_t >= REST_T:
				_go(S.IDLE)
				_cool = 0.6 + randf() * 0.5


func _go(s: S) -> void:
	st = s
	st_t = 0.0


func _interrupted() -> void:
	if st == S.WIND:
		_go(S.IDLE)
		_cool = 0.45


func _armored() -> bool:
	return st == S.DASH


func _contact_now() -> bool:
	return st == S.DASH


# ═══════════════════════════════════════════════════════════
# 그림: 등이 굽은 검은 짐승 + 뼈 가면 + 붉은 눈, 등에 뼈 가시, 흔들리는 꼬리
# ═══════════════════════════════════════════════════════════

func _paint_body(a: float) -> void:
	var moving := absf(velocity.x) > 12.0 and spawn_t <= 0.0
	var ph := t * (22.0 if st == S.DASH else 13.0)
	var crouch := 0.0
	var lean := 0.0
	if st == S.WIND:
		crouch = smoothstep(0.0, 0.25, st_t)
		_paint_warn(a)
	elif st == S.DASH:
		lean = 1.0
	var body_off := Vector2(-3.0 * crouch + 3.0 * lean, 2.5 * crouch + (absf(sin(ph)) * 1.2 if moving else sin(t * 3.0) * 0.4))
	# 다리 (뒤쪽 쌍을 먼저, 어둡게)
	for pair in 2:
		var dark := pair == 0
		for leg in 2:
			var hip := Vector2(7.0 if leg == 0 else -9.0, -7.0) + body_off * 0.6
			var off := ph + (PI if leg == 1 else 0.0) + (PI * 0.5 if dark else 0.0)
			var foot := Vector2(hip.x + (sin(off) * 5.0 if moving else 0.0) - lean * 6.0 * (1.0 if leg == 1 else -0.4), 0.0)
			if moving:
				foot.y -= maxf(cos(off), 0.0) * 3.0
			if crouch > 0.0:
				foot.x += 3.0 if leg == 0 else -2.0
			var knee := (hip + foot) * 0.5 + Vector2(-2.5 if leg == 0 else 2.5, 0.0)
			var c := col(SHADE if dark else BLACK, a)
			pd.line2(hip, knee, c, c, 3.0, 2.2)
			pd.line2(knee, foot, c, c, 2.2, 1.4)
	# 꼬리
	var tail := PackedVector2Array()
	for i in 6:
		var f := float(i) / 5.0
		tail.append(Vector2(-12.0 - f * 13.0 - lean * f * 6.0, -10.0 - f * 3.0 + sin(t * 9.0 - f * 3.0) * 2.5 * f) + body_off)
	for i in range(1, tail.size()):
		var w := 3.2 * (1.0 - float(i) / 6.0) + 0.4
		pd.line2(tail[i - 1], tail[i], col(BLACK, a), col(BLACK, a), w + 0.6, w)
	# 몸통
	var o := body_off
	var body := PackedVector2Array([Vector2(-13, -9) + o, Vector2(-7, -15) + o, Vector2(-1, -18) + o, Vector2(6, -19) + o,
		Vector2(11, -16) + o, Vector2(11, -8) + o, Vector2(3, -6) + o, Vector2(-6, -5) + o, Vector2(-13, -5) + o])
	pd.draw_colored_polygon(body, col(BLACK, a))
	pd.draw_colored_polygon(PackedVector2Array([Vector2(-10, -9) + o, Vector2(-1, -15) + o, Vector2(7, -16) + o, Vector2(3, -12) + o, Vector2(-6, -9) + o]), col(SHADE, a))
	# 등뼈 가시 (뼈색)
	for s: Array in [[Vector2(-8, -13), Vector2(-12, -20)], [Vector2(-3, -16), Vector2(-6, -24)], [Vector2(2, -18), Vector2(0, -25)], [Vector2(6, -18), Vector2(6, -23)]]:
		var b: Vector2 = s[0] + o
		var tip: Vector2 = s[1] + o + Vector2(-lean * 3.0, lean * 2.0 + crouch * 1.5)
		pd.draw_colored_polygon(PackedVector2Array([b + Vector2(-2, 0), tip, b + Vector2(2, 0)]), col(BONE_DIM, a))
	# 머리: 뼈 가면
	var h := Vector2(0.0, 2.0 * crouch - lean * 1.5) + o
	var mask := PackedVector2Array([Vector2(9, -20) + h, Vector2(16, -18) + h, Vector2(22, -13) + h, Vector2(16, -9) + h, Vector2(10, -10) + h])
	pd.draw_colored_polygon(mask, col(BONE, a))
	pd.draw_line(Vector2(13, -10) + h, Vector2(21, -12.5) + h, col(BLACK, a), 1.0) # 턱 선
	pd.draw_line(Vector2(11, -18) + h, Vector2(13, -15) + h, col(BONE_DIM, a), 1.0) # 금
	var eye := Vector2(15, -15) + h
	pd.draw_circle(eye, 2.0, col(BLACK, a))
	var hot := 0.0
	if st == S.WIND:
		hot = smoothstep(0.0, WIND_T, st_t)
	elif st == S.DASH:
		hot = 1.0
	if hot > 0.0:
		pd.glow(eye, 4.0 + 5.0 * hot, Color(RED, 0.55 * hot * a), 0.0)
	pd.draw_circle(eye, 1.2 + 0.5 * hot, Color(RED.lerp(RED_HOT, hot), a))
	if st == S.DASH:
		# 눈에서 뒤로 끌리는 붉은 빛줄 + 속도선
		pd.line2(eye, eye + Vector2(-26, -2), Color(RED, 0.8 * a), Color(RED, 0.0), 1.6, 0.4)
		for i in 3:
			var y := -6.0 - float(i) * 5.0
			var x0 := -16.0 - fmod(t * 300.0 + float(i) * 13.0, 20.0)
			pd.draw_line(Vector2(x0, y), Vector2(x0 - 12.0, y), Color(BONE, 0.35 * a), 1.0)


## 웅크린 동안 땅에 붉은 돌진 예고선 (깜빡이며 짙어짐)
func _paint_warn(a: float) -> void:
	var f := smoothstep(0.0, WIND_T, st_t)
	var blink := 0.6 + 0.4 * sin(st_t * 40.0)
	var len := DASH_V * DASH_T * (0.4 + 0.6 * f)
	pd.line2(Vector2(14, -1), Vector2(14 + len, -1), Color(RED, 0.55 * f * blink * a), Color(RED, 0.0), 2.0, 1.0)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(16 + len * 0.3, -4), Vector2(22 + len * 0.3, -1), Vector2(16 + len * 0.3, 2)]), Color(RED, 0.7 * f * blink * a))
