class_name EArt
extends PDraw.Canvas
## 에스카 코드 그림 (키 약 40px — 모자 포함, 이나리 주인공과 비슷한 화면 비율).
## 컨셉아트 기준: 백발 장발(오른쪽 눈을 덮는 앞머리), 챙 넓은 검은 마녀 모자(챙 끝이 갈라져 흰 공허가 비침),
## 검은 롱드레스(높은 트임, 자락 끝이 갈라져 흰 공허), 회보라 시스루 소매, 보라 안감. 흑백이 바탕이고 보라는 포인트만.
## 원점 = 발밑 가운데, 오른쪽을 보는 모습으로 그리고 scale.x로 뒤집는다.

const OUT := Color("#0a090e")
const CLOTH := Color("#15121b")
const CLOTH_HI := Color("#2a2333")
const CLOTH_SH := Color("#1f1a26")
const RIM := Color("#5c5470") ## 어두운 배경에서 실루엣이 읽히게 두르는 보랏빛 테두리
const LINING := Color("#4a2f6e")
const SLEEVE := Color("#6b5a86")
const GLOW := Color("#a98bff")
const GLOW_PALE := Color("#d9ccff")
const HAIR := Color("#ece9f2")
const HAIR_SH := Color("#b9b3c9")
const HAIR_DEEP := Color("#8a8399")
const SKIN := Color("#f0e6e2")
const SKIN_SH := Color("#c9b4b4")

var body: EEska
var _t := 0.0
var _hair_sway := 0.0 ## 머리카락·자락이 뒤로 끌리는 정도 (속도를 늦게 따라감)
var _lift := 0.0
var _hand := Vector2(3, -15)
var _hand_glow := 0.0


func tick(delta: float) -> void:
	_t += delta
	scale.x = float(body.facing)
	var vx := absf(body.velocity.x)
	var want_sway := clampf(vx / EEska.RUN_SPEED, 0.0, 1.3) * 3.2
	if not body.is_on_floor():
		want_sway += clampf(-body.velocity.y / 300.0, -1.0, 1.0) * -1.5
	_hair_sway = lerpf(_hair_sway, want_sway, 1.0 - exp(-delta * 8.0))
	var want_lift := 2.0 if body.st == EEska.St.ULT else 0.0
	_lift = lerpf(_lift, want_lift, 1.0 - exp(-delta * 10.0))
	var h := _hand_target()
	_hand = _hand.lerp(h, 1.0 - exp(-delta * 40.0))
	_hand_glow = maxf(_hand_glow - delta * 5.0, 0.0)
	if body.st in [EEska.St.ATTACK, EEska.St.CAST, EEska.St.ULT]:
		_hand_glow = 1.0
	queue_redraw()


func _hand_target() -> Vector2:
	var s := Vector2(1.5, -23.5)
	match body.st:
		EEska.St.ATTACK:
			var a: Dictionary = EEska.COMBO[body.combo_i]
			var k := clampf(body.st_t / maxf(float(a.hit) * 1.4, 0.001), 0.0, 1.0)
			var ang := deg_to_rad(lerpf(float(a.a0), float(a.a1), k))
			return s + Vector2(cos(ang), sin(ang) * 0.9) * 11.0
		EEska.St.CAST:
			match body.cast_kind:
				"cheonyeol":
					return Vector2(11.5, -23)
				"dangong":
					return Vector2(6, -37)
				_:
					return Vector2(11, -21)
		EEska.St.ULT:
			return Vector2(2, -41)
	if not body.is_on_floor():
		return Vector2(5, -19)
	if absf(body.velocity.x) > 20.0:
		return Vector2(3.0 + sin(_t * 14.0) * 2.5, -16.0)
	return Vector2(3, -15.5)


func _paint() -> void:
	var run := absf(body.velocity.x) > 20.0 and body.is_on_floor()
	var bob := 0.0
	if run:
		bob = -1.0 if sin(_t * 14.0) > 0.0 else 0.0
	elif body.is_on_floor() and body.st == EEska.St.NORMAL:
		bob = -0.5 if sin(_t * 2.2) > 0.6 else 0.0
	var o := Vector2(0, bob - _lift)
	var sway := _hair_sway + sin(_t * 2.6) * 0.5
	var air := not body.is_on_floor()
	var flare := 2.0 if air else (1.0 if run else 0.0)
	if body.st == EEska.St.ULT:
		flare = 3.0
		sway += sin(_t * 9.0) * 1.2

	# 바닥 그림자
	pd.draw_set_transform(Vector2(0, _lift), 0.0, Vector2(1.0, 0.25))
	pd.glow(Vector2.ZERO, 9.0, Color(0, 0, 0, 0.5), 0.0)
	pd.draw_set_transform(Vector2.ZERO)

	# 뒤 머리 (긴 백발 — 허리 아래까지)
	var hb := PackedVector2Array([
		o + Vector2(-3.5, -31), o + Vector2(-5.0 - sway * 0.3, -24), o + Vector2(-6.5 - sway * 0.7, -14),
		o + Vector2(-6.5 - sway * 1.2, -6), o + Vector2(-4.0 - sway * 1.3, -4), o + Vector2(-2.6 - sway * 0.8, -11),
		o + Vector2(-1.6, -22), o + Vector2(0.5, -31)])
	pd.outlined(hb, HAIR_SH, OUT, 0.8)
	pd.draw_colored_polygon(PackedVector2Array([
		o + Vector2(-3.2, -30), o + Vector2(-4.4 - sway * 0.3, -23), o + Vector2(-5.4 - sway * 0.8, -12),
		o + Vector2(-4.2 - sway * 1.1, -7), o + Vector2(-3.0 - sway * 0.7, -13), o + Vector2(-2.0, -24)]), HAIR)

	# 치마 (검은 롱드레스, 뒤로 보라 안감, 자락 끝 갈라짐 = 흰 공허)
	var back := -9.0 - flare - sway * 0.5
	var front := 7.0 + flare * 0.5
	var hem := PackedVector2Array()
	hem.append(o + Vector2(-3.2, -16))
	hem.append(o + Vector2(3.2, -16))
	hem.append(o + Vector2(front - 1.0, -6))
	var n := 7
	for i in n + 1:
		var f := float(i) / float(n)
		var x := lerpf(front, back, f)
		var y := -1.0 if i % 2 == 0 else -4.2
		if i == n:
			y = -2.0
		hem.append(Vector2(x, y + o.y * 0.3))
	hem.append(o + Vector2(back + 1.5, -8))
	pd.draw_colored_polygon(PackedVector2Array([o + Vector2(-3, -15), o + Vector2(back + 0.5, -2), o + Vector2(back + 3.0, -1.5), o + Vector2(-1, -12)]), LINING)
	pd.outlined(hem, CLOTH, RIM, 0.8)
	# 앞 트임 사이로 다리 한 줄
	pd.draw_line(o + Vector2(2.2, -12), o + Vector2(3.6 + flare * 0.3, -1.5), SKIN_SH, 1.0)
	# 자락 주름 하이라이트
	pd.draw_line(o + Vector2(-1, -14), o + Vector2(-4 - flare * 0.5, -3), CLOTH_HI, 1.0)
	# 갈라진 자락의 흰 공허 (반짝임)
	var shimmer := 0.75 + 0.25 * sin(_t * 7.0)
	for i in 3:
		var f := (float(i) + 0.5) / 3.0
		var x := lerpf(front - 1.0, back + 1.0, f)
		var tri := PackedVector2Array([Vector2(x - 1.3, o.y * 0.3 - 1.0), Vector2(x + 1.3, o.y * 0.3 - 1.0), Vector2(x, o.y * 0.3 - 4.0)])
		pd.draw_colored_polygon(tri, Color(1, 1, 1, shimmer))

	# 몸통 (몸에 맞는 검은 드레스)
	var torso := PackedVector2Array([o + Vector2(-3, -16), o + Vector2(3.2, -16), o + Vector2(4.2, -20), o + Vector2(3.4, -23.2), o + Vector2(-3, -23.2)])
	pd.outlined(torso, CLOTH, RIM, 0.8)
	pd.draw_line(o + Vector2(-2.6, -16.6), o + Vector2(3.0, -16.6), CLOTH_SH, 1.0)
	# 드러난 어깨 + 목
	pd.draw_rect(Rect2(o + Vector2(-3.4, -25), Vector2(7, 2)), SKIN)
	pd.draw_rect(Rect2(o + Vector2(-0.2, -26.6), Vector2(2.2, 1.8)), SKIN_SH)

	# 얼굴 (앞머리가 오른쪽 눈을 덮는다)
	pd.draw_circle(o + Vector2(1.3, -29.2), 3.2, SKIN)
	pd.draw_rect(Rect2(o + Vector2(2.6, -27.6), Vector2(1.2, 0.8)), SKIN_SH) # 턱 그늘
	# 정수리 + 앞머리
	pd.draw_circle(o + Vector2(0.2, -30.6), 3.5, HAIR)
	pd.outlined(PackedVector2Array([o + Vector2(0.6, -33.2), o + Vector2(4.2, -31.4), o + Vector2(4.6, -27.0),
		o + Vector2(3.0, -26.2), o + Vector2(2.2, -28.6), o + Vector2(0.0, -30.4)]), HAIR, OUT, 0.6)
	pd.draw_line(o + Vector2(3.6, -30.8), o + Vector2(3.8, -27.4), HAIR_SH, 0.8)
	# 앞머리 사이로 비치는 눈빛 하나 (흰빛 + 보라)
	var eye_a := 0.65 + 0.35 * sin(_t * 3.0)
	if body.st == EEska.St.ULT:
		eye_a = 1.0
	pd.draw_rect(Rect2(o + Vector2(3.0, -29.4), Vector2(1.2, 1.0)), Color(GLOW_PALE, eye_a))

	# 모자: 챙 (갈라진 끝에 흰 공허) + 꺾인 뾰족 머리
	var brim_c := o + Vector2(0.5, -33.4)
	pd.draw_set_transform(brim_c, -0.07, Vector2.ONE)
	var brim := PackedVector2Array()
	for i in 20:
		var a := float(i) / 20.0 * TAU
		brim.append(Vector2(cos(a) * 14.0, sin(a) * 2.3))
	pd.outlined(brim, CLOTH, RIM, 0.8)
	# 챙 끝 갈라짐 (앞 둘 · 뒤 하나)
	for spec: Array in [[11.5, 1.0], [7.5, 1.2], [-11.0, 0.9]]:
		var x: float = spec[0]
		var dir := signf(x)
		pd.draw_colored_polygon(PackedVector2Array([Vector2(x + dir * 2.6, -0.4), Vector2(x - dir * 0.6, 0.0), Vector2(x + dir * 2.4, 1.4)]), Color(1, 1, 1, shimmer))
	pd.draw_set_transform(Vector2.ZERO)
	var crown := PackedVector2Array([o + Vector2(-4.8, -34.2), o + Vector2(5.0, -34.4), o + Vector2(2.4, -39.0),
		o + Vector2(-0.5, -42.4), o + Vector2(-4.0 - sway * 0.25, -45.6), o + Vector2(-5.6 - sway * 0.3, -44.8),
		o + Vector2(-3.4, -41.8), o + Vector2(-4.4, -38.0)])
	pd.outlined(crown, CLOTH, RIM, 0.8)
	pd.draw_line(o + Vector2(-4.4, -35.2), o + Vector2(4.4, -35.4), LINING, 1.2) # 보라 띠
	pd.draw_line(o + Vector2(-0.6, -41.4), o + Vector2(1.6, -38.0), CLOTH_HI, 0.8)

	# 앞팔 + 시스루 소매 + 손빛
	var sh := o + Vector2(1.5, -23.5)
	var hand := o + _hand
	var el := sh.lerp(hand, 0.5) + Vector2(-0.6, 1.2)
	var mid := sh.lerp(hand, 0.55)
	var drape := PackedVector2Array([sh + Vector2(-1.5, -0.5), sh + Vector2(1.8, -0.4), mid + Vector2(1.0, 0.6),
		mid + Vector2(-1.5 - sway * 0.4, 7.0), sh + Vector2(-3.4 - sway * 0.3, 5.5)])
	pd.draw_colored_polygon(drape, Color(SLEEVE, 0.55))
	pd.draw_line(sh, el, SKIN, 1.6)
	pd.draw_line(el, hand, SKIN, 1.5)
	pd.draw_circle(hand, 1.1, SKIN)
	if _hand_glow > 0.0:
		pd.glow(hand, 5.0, Color(GLOW_PALE, 0.55 * _hand_glow), 0.0)
		pd.draw_circle(hand, 1.4, Color(1, 1, 1, 0.9 * _hand_glow))
