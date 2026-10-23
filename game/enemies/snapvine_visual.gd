class_name SnapvineVisual
extends Node2D
## 독덩굴 그림: 깨진 온실 화분을 뚫고 자란 굵은 덩굴 몸통(보랏빛 마력 핏줄) + 긴 줄기 끝의 파리지옥 같은 꽃머리 3개.
## 예고 중인 머리는 붉게 빛나고, 머리가 뻗은 동안엔 몸통 껍질이 갈라져 연두빛 속살이 드러난다(약점).

var enemy: Snapvine

const BARK := Color("#2c3a1c")
const BARK_LIGHT := Color("#4a5e2a")
const BARK_DARK := Color("#141b0c")
const STEM := Color("#3f6a2a")
const STEM_LIGHT := Color("#6f9a3a")
const PETAL := Color("#7a1f45")
const PETAL_LIGHT := Color("#b03a62")
const MOUTH := Color("#ff9ab8")
const POT := Color("#9a4a2a")
const POT_DARK := Color("#5a2614")
const CORE := Color("#d8ff8a")
const MANA := Color(0.7, 0.4, 1.0)


func _process(_delta: float) -> void:
	z_index = 2


func _draw() -> void:
	if enemy == null:
		return
	var t := enemy._t
	var white := enemy.flash_amount() > 0.0
	var fl := 0.55 if white else 0.0
	var exposed := enemy.is_exposed()

	# 뿌리 (깨진 화분 밖으로 뻗어 나감)
	for i in 4:
		var sx := -1.0 if i % 2 == 0 else 1.0
		var rl := 14.0 + 6.0 * float(i >> 1)
		draw_line(Vector2(sx * 8.0, -2), Vector2(sx * (8.0 + rl), 0), BARK_DARK, 3.0)
		draw_line(Vector2(sx * 8.0, -2), Vector2(sx * (8.0 + rl * 0.8), -1), BARK.lerp(Color.WHITE, fl), 1.0)

	# 줄기 (뒤에 있는 것부터)
	for i: int in [1, 2, 0]:
		_draw_stem(enemy.heads[i], t, fl, exposed)

	# 몸통: 꼬인 굵은 덩굴
	var sway := sin(t * 1.2) * 1.0
	var trunk := PackedVector2Array([
		Vector2(-11, -8), Vector2(-13, -18), Vector2(-9, -28 + sway), Vector2(-4, -36 + sway), Vector2(4, -36 + sway),
		Vector2(10, -29 + sway), Vector2(12, -18), Vector2(10, -8),
	])
	draw_colored_polygon(trunk, BARK_DARK.lerp(Color.WHITE, fl))
	var inner := PackedVector2Array()
	for v: Vector2 in trunk:
		inner.append(v * Vector2(0.8, 0.94) + Vector2(0, -0.5))
	draw_colored_polygon(inner, BARK.lerp(Color.WHITE, fl))
	# 꼬인 결
	for i in 3:
		var y0 := -10.0 - i * 8.0
		draw_line(Vector2(-8, y0), Vector2(7, y0 - 6), BARK_LIGHT.lerp(Color.WHITE, fl), 1.0)
	# 가시
	for i in 4:
		var y := -12.0 - i * 6.0
		var sx2 := -1.0 if i % 2 == 0 else 1.0
		draw_line(Vector2(sx2 * 10.0, y), Vector2(sx2 * 14.0, y - 2.0), BARK_DARK, 1.0)
	# 보랏빛 폭주 마력 핏줄 (맥박)
	var pulse := 0.4 + 0.3 * sin(t * 3.0)
	draw_polyline(PackedVector2Array([Vector2(-5, -9), Vector2(-7, -17), Vector2(-3, -24), Vector2(-5, -31)]), Color(MANA, pulse), 1.0)
	draw_polyline(PackedVector2Array([Vector2(5, -10), Vector2(3, -19), Vector2(6, -27)]), Color(MANA, pulse * 0.8), 1.0)
	# 약점: 머리가 뻗으면 껍질이 갈라져 속살이 드러남
	if exposed:
		var glow := 0.6 + 0.4 * sin(t * 18.0)
		draw_circle(Vector2(0, -22), 9.0, Color(CORE, 0.18 * glow))
		draw_set_transform(Vector2(0, -22), 0.0, Vector2(0.5, 1.0))
		draw_circle(Vector2.ZERO, 8.0, Color(CORE, 0.85))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_line(Vector2(0, -30), Vector2(0, -14), Color(1, 1, 0.9, glow), 1.0)
	# 잎 두 장
	var leaf_col := STEM.lerp(Color.WHITE, fl)
	draw_colored_polygon(PackedVector2Array([Vector2(-10, -20), Vector2(-24, -27 + sway), Vector2(-17, -17)]), leaf_col)
	draw_colored_polygon(PackedVector2Array([Vector2(10, -16), Vector2(24, -21 - sway), Vector2(16, -12)]), leaf_col)

	# 깨진 화분
	var pot := POT.lerp(Color.WHITE, fl)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, 0), Vector2(12, 0), Vector2(15, -11), Vector2(10, -13), Vector2(7, -9),
		Vector2(3, -14), Vector2(-4, -10), Vector2(-9, -14), Vector2(-15, -11),
	]), pot)
	draw_rect(Rect2(-15, -12, 30, 2), Color(POT.lightened(0.2), 0.9))
	draw_line(Vector2(-6, -1), Vector2(-3, -7), POT_DARK, 1.0)
	draw_line(Vector2(-3, -7), Vector2(-5, -10), POT_DARK, 1.0)
	draw_line(Vector2(8, -2), Vector2(6, -8), POT_DARK, 1.0)
	# 화분에 붙은 이름표 (온실 관리표)
	draw_rect(Rect2(-4, -7, 8, 4), Color(0.92, 0.88, 0.75))
	draw_line(Vector2(-3, -5), Vector2(3, -5), Color(0.4, 0.3, 0.3), 1.0)

	# 꽃머리 (앞에 그림)
	for i: int in [1, 2, 0]:
		_draw_head(enemy.heads[i], t, fl)


func _stem_points(h: Snapvine.VineHead, t: float) -> PackedVector2Array:
	var a := h.root
	var b := h.pos
	var mid := (a + b) * 0.5 + Vector2(sin(t * 1.5 + h.bob) * 3.0, -14.0 - absf(b.x - a.x) * 0.12)
	var pts := PackedVector2Array()
	for i in 9:
		var s := i / 8.0
		pts.append(a.lerp(mid, s).lerp(mid.lerp(b, s), s))
	return pts


func _draw_stem(h: Snapvine.VineHead, t: float, fl: float, exposed: bool) -> void:
	var pts := _stem_points(h, t)
	var out := h.state == Snapvine.H.LUNGE or h.state == Snapvine.H.HOLD
	draw_polyline(pts, BARK_DARK, 6.0)
	draw_polyline(pts, (STEM_LIGHT if out and exposed else STEM).lerp(Color.WHITE, fl), 4.0)
	draw_polyline(pts, Color(STEM_LIGHT.lerp(Color.WHITE, fl), 0.6), 1.0)
	# 줄기 마디 가시
	for i: int in [2, 5]:
		var p := pts[i]
		draw_line(p, p + Vector2(-2, -3), BARK_DARK, 1.0)


func _draw_head(h: Snapvine.VineHead, t: float, fl: float) -> void:
	var st := h.state
	var k := h.progress()
	var open := 0.18 + 0.08 * sin(t * 2.0 + h.bob)
	var danger := 0.0
	match st:
		Snapvine.H.WIND:
			open = 0.05
			danger = k
		Snapvine.H.LUNGE:
			open = 0.9
		Snapvine.H.HOLD:
			open = 0.15 + 0.6 * absf(sin(t * 22.0))
		Snapvine.H.RETRACT:
			open = 0.3 * (1.0 - k)
		Snapvine.H.SPIT_WIND:
			open = 0.0
			danger = k
		Snapvine.H.SPIT:
			open = 0.7 * (1.0 - k)
	# 붉은 예고 빛
	if danger > 0.0:
		var blink := 0.7 + 0.3 * sin(t * 30.0)
		draw_circle(h.pos, 9.0 + 5.0 * danger, Color(Palette.DANGER, 0.25 * danger * blink))
		draw_circle(h.pos, 6.0 + 2.0 * danger, Color(Palette.DANGER, 0.35 * danger))
	var flip := -1.0 if cos(h.look) < 0.0 else 1.0
	var puff := 1.0 + (0.35 * k if st == Snapvine.H.SPIT_WIND else 0.0)
	draw_set_transform(h.pos, h.look, Vector2(puff, flip * puff))
	# 꽃잎 깃 (머리 뒤)
	var petal := PETAL.lerp(Color.WHITE, fl)
	for i in 5:
		var a := PI + (i - 2) * 0.55
		draw_circle(Vector2.from_angle(a) * 6.0 + Vector2(-3, 0), 3.5, petal.darkened(0.15))
	# 입 안
	draw_circle(Vector2(3, 0), 4.0 + 2.0 * open, MOUTH.lerp(Palette.DANGER, danger).lerp(Color.WHITE, fl))
	# 위·아래 턱 (경첩 (-5, 0) 기준으로 벌어짐)
	var jaw_col := PETAL_LIGHT.lerp(Palette.DANGER, danger * 0.6).lerp(Color.WHITE, fl)
	for side: float in [-1.0, 1.0]:
		var rot := side * (0.15 + open * 0.75)
		var jaw := PackedVector2Array()
		for v: Vector2 in [Vector2(0, 0), Vector2(1, -6), Vector2(8, -8), Vector2(15, -4), Vector2(16, 0)]:
			var vv := Vector2(v.x, v.y * -side if side > 0.0 else v.y)
			jaw.append(Vector2(-5, 0) + vv.rotated(rot))
		draw_colored_polygon(jaw, jaw_col)
		# 이빨
		var tip := Vector2(-5, 0) + Vector2(15, 0).rotated(rot)
		var mid := Vector2(-5, 0) + Vector2(9, 0).rotated(rot)
		draw_line(mid, mid + Vector2(0, -side * 2.5).rotated(rot), Color(1, 0.97, 0.85), 1.0)
		draw_line(tip, tip + Vector2(-1, -side * 2.5).rotated(rot), Color(1, 0.97, 0.85), 1.0)
	# 위턱의 눈 하나
	var eye := Vector2(-5, 0) + Vector2(6, -5).rotated(-(0.15 + open * 0.75))
	draw_circle(eye, 2.0, Color(1.0, 0.9, 0.3) if danger <= 0.0 else Color.WHITE)
	draw_rect(Rect2(eye + Vector2(-0.5, -1), Vector2(1, 2)), Color(0.1, 0.0, 0.05))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
