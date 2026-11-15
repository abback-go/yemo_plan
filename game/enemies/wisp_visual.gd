class_name WispVisual
extends Node2D
## 도깨비불 그림: 초록·청록 여우불 덩어리에 장난스러운 얼굴(두 눈 + 씩 웃는 입).
## 예고 때는 부풀며 눈이 ^ ^ 로 휘고 입을 크게 벌리며, 몸 둘레에 붉은 고리가 맥박친다(위험 예고 = 붉은색).
## 얼굴 방향은 facing으로 옮기고, 노드 자체는 뒤집지 않는다.

const OUTER := Color(0.16, 0.62, 0.5, 0.55)
const MID := Color(0.4, 0.95, 0.7)
const CORE := Color(0.86, 1.0, 0.92)
const FACE := Color("#0e1a2a")
const BLUSH := Color(1.0, 0.42, 0.42, 0.75)

var enemy: Wisp
var _trail: Array[Vector2] = []


func _process(_delta: float) -> void:
	if enemy == null:
		return
	# 움직인 자취(꼬리 불꽃)를 전역 좌표로 기억
	_trail.push_front(enemy.center())
	if _trail.size() > 7:
		_trail.pop_back()


func _draw() -> void:
	if enemy == null:
		return
	var st := enemy.state
	var white := enemy.flash_amount() > 0.0
	var t := enemy._t
	var f := float(enemy.facing)
	var tk := enemy.telegraph_k()
	var bob := sin(t * 3.2) * 1.2
	var s := 1.0 + sin(t * 5.0) * 0.04 # 숨 쉬듯 일렁임
	var spin := 0.0
	match st:
		Wisp.S.TELEGRAPH:
			s = 1.0 + 0.38 * tk * tk + sin(t * 40.0) * 0.03 * tk
		Wisp.S.SHOOT:
			s = 1.12
		Wisp.S.BLINK_OUT:
			var k := enemy.blink_k()
			s = 1.0 - k
			spin = k * 6.0
		Wisp.S.BLINK_IN:
			var k2 := enemy.blink_k()
			s = k2 * (1.0 + 0.25 * sin(k2 * PI)) # 살짝 튀어나오듯
	if s <= 0.02:
		return
	var c := Wisp.CENTER + Vector2(0, bob)
	var outer := Color.WHITE if white else OUTER
	var mid := Color.WHITE if white else MID
	var core := Color.WHITE if white else CORE

	# 꼬리 불꽃 (지나온 자리)
	if not white and st != Wisp.S.BLINK_OUT:
		for i in range(1, _trail.size()):
			var k3 := 1.0 - float(i) / _trail.size()
			var p := to_local(_trail[i]) + Vector2(0, bob)
			draw_circle(p, (1.5 + 3.0 * k3) * s, Color(OUTER, 0.35 * k3))

	# 위험 예고: 붉은 고리가 맥박치며 조여 온다
	if tk > 0.0 and not white:
		var pulse := 0.5 + 0.5 * sin(t * 30.0)
		var r := (14.0 - 4.0 * tk) * s
		draw_arc(c, r, 0.0, TAU, 28, Color(Palette.DANGER, 0.35 + 0.45 * tk * pulse), 1.5 + tk)

	# 불꽃 몸: 위로 솟는 혀 3개 + 겹친 원
	var sway := sin(t * 6.0) * 2.0
	var tongue := PackedVector2Array([
		c + Vector2(-6, -1) * s, c + Vector2(sway * 0.6, -16.0 - sin(t * 9.0) * 1.5) * s + Vector2(sway, 0), c + Vector2(6, -1) * s,
	])
	draw_colored_polygon(tongue, outer)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-7, 0) * s, c + Vector2(-9.0 + sway * 0.3, -10) * s, c + Vector2(-2, -4) * s,
	]), outer)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(7, 0) * s, c + Vector2(9.0 + sway * 0.3, -9) * s, c + Vector2(2, -4) * s,
	]), outer)
	draw_circle(c, 8.0 * s, outer)
	draw_circle(c + Vector2(0, 0.5) * s, 6.2 * s, mid)
	draw_circle(c + Vector2(0, -6) * s + Vector2(sway * 0.4, 0), 3.0 * s, mid)
	draw_circle(c + Vector2(0, 1.5) * s, 4.0 * s, core)

	if st == Wisp.S.BLINK_OUT or st == Wisp.S.BLINK_IN:
		# 빙글 도는 불씨 (사라지고 나타나는 중)
		for i in 4:
			var a := spin + t * 14.0 + i * TAU / 4.0
			draw_rect(Rect2(c + Vector2(cos(a), sin(a)) * 9.0 * maxf(s, 0.4) - Vector2(1, 1), Vector2(2, 2)), Color(MID, 0.9))
		return

	# 얼굴 (불꽃 중심에서 바라보는 쪽으로 조금 치우침)
	var fc := c + Vector2(f * 1.6, 0.5) * s
	var face := Color(0.6, 0.6, 0.65) if white else FACE
	var eye_l := fc + Vector2(-2.6, -1.8) * s
	var eye_r := fc + Vector2(2.6, -1.8) * s
	if white:
		# 맞았을 때: > <
		_draw_squint(eye_l, s, face, 1.0)
		_draw_squint(eye_r, s, face, -1.0)
		draw_rect(Rect2(fc + Vector2(-1.5, 1.5) * s, Vector2(3, 1.5) * s), face)
	elif st == Wisp.S.TELEGRAPH:
		# 킥킥: ^ ^ 눈, 크게 벌린 입, 볼 홍조
		_draw_caret(eye_l, s, face)
		_draw_caret(eye_r, s, face)
		var open := 2.0 + 2.5 * tk
		draw_rect(Rect2(fc + Vector2(-3.0, 0.8) * s, Vector2(6.0, open) * s), face)
		draw_rect(Rect2(fc + Vector2(-1.0, 0.8) * s, Vector2(1.4, 1.2) * s), CORE) # 덧니
		draw_rect(Rect2(fc + Vector2(-5.2, 0.2) * s, Vector2(1.6, 1.0) * s), BLUSH)
		draw_rect(Rect2(fc + Vector2(3.6, 0.2) * s, Vector2(1.6, 1.0) * s), BLUSH)
	elif st == Wisp.S.SHOOT:
		draw_rect(Rect2(eye_l - Vector2(0.8, 1.2) * s, Vector2(1.6, 2.4) * s), face)
		draw_rect(Rect2(eye_r - Vector2(0.8, 1.2) * s, Vector2(1.6, 2.4) * s), face)
		draw_circle(fc + Vector2(0, 2.2) * s, 1.6 * s, face) # "오!"
	else:
		# 평소: 동그란 눈 + 씩 웃는 입. 가끔 눈을 깜빡인다
		var blink := fmod(enemy._t, 2.7) < 0.12
		if blink:
			draw_rect(Rect2(eye_l - Vector2(1.0, 0.3) * s, Vector2(2.0, 0.8) * s), face)
			draw_rect(Rect2(eye_r - Vector2(1.0, 0.3) * s, Vector2(2.0, 0.8) * s), face)
		else:
			draw_rect(Rect2(eye_l - Vector2(0.9, 1.4) * s, Vector2(1.8, 2.8) * s), face)
			draw_rect(Rect2(eye_r - Vector2(0.9, 1.4) * s, Vector2(1.8, 2.8) * s), face)
			draw_rect(Rect2(eye_l - Vector2(0.9, 1.4) * s, Vector2(0.8, 0.8) * s), CORE)
			draw_rect(Rect2(eye_r - Vector2(0.9, 1.4) * s, Vector2(0.8, 0.8) * s), CORE)
		draw_arc(fc + Vector2(0, 0.4) * s, 2.8 * s, 0.25, PI - 0.25, 8, face, 1.2)
		draw_rect(Rect2(fc + Vector2(f * 2.2 - 0.6, 2.4) * s, Vector2(1.2, 1.0) * s), face) # 입꼬리 한쪽만 씩


## ^ 모양 눈
func _draw_caret(at: Vector2, s: float, col: Color) -> void:
	draw_line(at + Vector2(-1.4, 0.8) * s, at + Vector2(0, -0.8) * s, col, 1.0)
	draw_line(at + Vector2(0, -0.8) * s, at + Vector2(1.4, 0.8) * s, col, 1.0)


## > < 모양 눈 (side: 1 = >, -1 = <)
func _draw_squint(at: Vector2, s: float, col: Color, side: float) -> void:
	draw_line(at + Vector2(-1.2 * side, -1.2) * s, at + Vector2(1.0 * side, 0) * s, col, 1.0)
	draw_line(at + Vector2(1.0 * side, 0) * s, at + Vector2(-1.2 * side, 1.2) * s, col, 1.0)
