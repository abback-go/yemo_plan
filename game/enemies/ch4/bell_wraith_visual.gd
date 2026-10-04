extends Node2D
## 종지기 망령 그림: 해진 회색 두건(속은 어둠, 희미한 두 눈), 다리 대신 흩날리는 옷자락, 긴 팔, 반투명 유령 종(금테), 끊어진 종 줄.
## 예고: 종을 들어 올리며 붉게 + 퍼질 범위를 붉은 점선 원으로. 소리 고리는 가산 합성 자식(_rings)이 그린다.
## 진짜 종에 멈췄을 땐 바닥에 주저앉아 두 손으로 귀를 막고, 머리 위로 음표가 돈다.

const H := preload("res://enemies/ch4/holy.gd")
const CLOTH := Color(0.78, 0.78, 0.86, 0.85)
const CLOTH_S := Color(0.5, 0.5, 0.62, 0.85)
const DARK := Color("#120e1a")
const GHOST := Color(0.75, 0.9, 1.0, 0.55)
const DANGER := Color("#ff3b3b")

var enemy: BellWraith
var _rings: RingDraw


class RingDraw extends Node2D:
	var w: BellWraith

	func _ready() -> void:
		material = Fx.add_material
		top_level = true
		z_index = 5

	func _process(_d: float) -> void:
		global_position = Vector2.ZERO
		queue_redraw()

	func _draw() -> void:
		if w == null or not is_instance_valid(w):
			return
		for ring in w.rings:
			var c: Vector2 = ring.c
			var r: float = ring.r
			var mx: float = ring.max
			var k := clampf(r / mx, 0.0, 1.0)
			var a := 1.0 - k * 0.7
			draw_arc(c, r, 0, TAU, 48, Color(0.85, 0.9, 1.0, 0.18 * a), BellWraith.RING_BAND + 6.0)
			draw_arc(c, r, 0, TAU, 48, Color(1.0, 0.9, 0.6, 0.55 * a), BellWraith.RING_BAND * 0.5)
			draw_arc(c, r, 0, TAU, 48, Color(1, 1, 1, 0.9 * a), 1.0)
		# 예고: 퍼질 범위
		if w.state == BellWraith.S.RAISE or w.state == BellWraith.S.TRIPLE:
			var k2 := w.progress()
			var c2 := w.bell_pos()
			var mx2 := BellWraith.RING_MAX_T * GameConst.TILE * (1.0 if w.state == BellWraith.S.RAISE else 0.55)
			var segs := 24
			for i in segs:
				if i % 2 == 1:
					continue
				var a0 := TAU * i / segs + w._t * 0.5
				draw_arc(c2, mx2, a0, a0 + TAU / segs, 3, Color(DANGER, 0.25 + 0.35 * k2), 2.0)
			draw_circle(c2, 4.0 + 4.0 * k2, Color(DANGER, 0.3 * k2))


func _ready() -> void:
	_rings = RingDraw.new()
	_rings.w = enemy
	add_child(_rings)


func _process(_d: float) -> void:
	if enemy:
		scale.x = float(enemy.facing)


func _draw() -> void:
	if enemy == null:
		return
	var white := enemy.flash_amount() > 0.0
	var t := enemy._t
	var st := enemy.state
	var stunned := st == BellWraith.S.STUNNED
	var o := Vector2(0, 0 if stunned else sin(t * 2.0) * 1.0)
	var cl := Color.WHITE if white else CLOTH
	var cs := Color.WHITE if white else CLOTH_S
	if stunned:
		o.y = 10.0
	# 흩날리는 옷자락 (다리 대신)
	var tail := PackedVector2Array()
	tail.append(Vector2(-7, -16) + o)
	tail.append(Vector2(8, -16) + o)
	for i in 5:
		var x := 8.0 - i * 3.8
		var y := -4.0 + (i % 2) * 3.0 + sin(t * 4.0 + i) * 1.5
		tail.append(Vector2(x, y) + o * (0.0 if stunned else 0.5))
	draw_colored_polygon(tail, cs)
	# 몸통 (해진 로브)
	var body := PackedVector2Array([Vector2(-6, -27) + o, Vector2(6, -27) + o, Vector2(9, -14) + o, Vector2(-8, -14) + o])
	draw_colored_polygon(body, cl)
	draw_line(Vector2(-8, -14) + o, Vector2(9, -14) + o, cs, 1.0)
	# 두건 (속은 어둠 + 희미한 두 눈)
	var hc := Vector2(1, -31) + o
	draw_colored_polygon(PackedVector2Array([hc + Vector2(-7, 5), hc + Vector2(-6, -4), hc + Vector2(0, -9), hc + Vector2(6, -5), hc + Vector2(8, 4), hc + Vector2(4, 6)]), cl)
	draw_colored_polygon(PackedVector2Array([hc + Vector2(-1, -3), hc + Vector2(5, -3), hc + Vector2(6, 4), hc + Vector2(0, 5)]), DARK)
	var eye_a := 0.5 + 0.4 * sin(t * 3.0)
	if stunned:
		draw_line(hc + Vector2(1, 0), hc + Vector2(3, 1), Color(0.8, 0.9, 1.0, 0.9), 1.0)
		draw_line(hc + Vector2(4, 1), hc + Vector2(5, 0), Color(0.8, 0.9, 1.0, 0.9), 1.0)
	else:
		draw_rect(Rect2(hc + Vector2(1, -1), Vector2(1, 2)), Color(0.8, 0.95, 1.0, eye_a))
		draw_rect(Rect2(hc + Vector2(4, -1), Vector2(1, 2)), Color(0.8, 0.95, 1.0, eye_a))
	# 끊어진 종 줄 (뒤쪽 손)
	var bh := Vector2(-8, -18) + o
	draw_line(Vector2(-5, -25) + o, bh, cs, 2.0)
	draw_line(bh, bh + Vector2(-2 + sin(t * 2.0) * 2.0, 10), Color("#a8885a"), 1.0)
	if stunned:
		# 두 손으로 귀를 막음
		draw_line(Vector2(-4, -25) + o, hc + Vector2(-6, 0), cl, 2.0)
		draw_line(Vector2(5, -25) + o, hc + Vector2(7, 0), cl, 2.0)
		draw_circle(hc + Vector2(-6, 0), 1.8, cl)
		draw_circle(hc + Vector2(7, 0), 1.8, cl)
		for i in 3:
			var a := t * 4.0 + i * TAU / 3.0
			var np := hc + Vector2(cos(a) * 9.0, -12 + sin(a) * 3.0)
			draw_circle(np, 1.2, Color(1.0, 0.9, 0.6))
			draw_line(np + Vector2(1, 0), np + Vector2(1, -4), Color(1.0, 0.9, 0.6), 1.0)
		_ghost_bell(hc + Vector2(12, 14), 0.0, true, white)
		return
	# 유령 종을 든 앞팔
	var raise := 0.0
	if st == BellWraith.S.RAISE:
		raise = enemy.progress()
	elif st == BellWraith.S.TOLL or st == BellWraith.S.TRIPLE:
		raise = 1.0
	var hand := Vector2(9, -20 - raise * 6.0) + o
	draw_line(Vector2(5, -25) + o, hand, cl, 2.0)
	var swing := sin(t * 18.0) * 0.4 if st == BellWraith.S.TOLL or st == BellWraith.S.TRIPLE else sin(t * 1.5) * 0.1
	var danger := enemy.progress() if st == BellWraith.S.RAISE else (0.6 if st == BellWraith.S.TRIPLE else 0.0)
	_ghost_bell(hand + Vector2(0, -2), swing, false, white, danger)


func _ghost_bell(pivot: Vector2, ang: float, cracked: bool, white: bool, danger := 0.0) -> void:
	var size := 11.0
	var dir := Vector2(sin(ang), cos(ang))
	var side := Vector2(dir.y, -dir.x)
	var top := pivot
	var prof: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(0.22, 0.04), Vector2(0.3, 0.2), Vector2(0.33, 0.55), Vector2(0.45, 0.85), Vector2(0.54, 1.0)]
	var pts := PackedVector2Array()
	for p in prof:
		pts.append(top + side * p.x * size + dir * p.y * size)
	for i in range(prof.size() - 1, 0, -1):
		pts.append(top + side * -prof[i].x * size + dir * prof[i].y * size)
	var body := Color.WHITE if white else GHOST.lerp(Color(1.0, 0.45, 0.4, 0.7), danger * 0.7)
	draw_colored_polygon(pts, body)
	var rim := Color(1.0, 0.88, 0.5, 0.9).lerp(DANGER, danger * 0.6)
	draw_line(top + side * -0.54 * size + dir * size, top + side * 0.54 * size + dir * size, rim, 1.5)
	draw_line(top + side * -0.3 * size + dir * 0.25 * size, top + side * 0.3 * size + dir * 0.25 * size, Color(rim, 0.6), 1.0)
	draw_circle(top + dir * 1.05 * size, 1.5, Color(0.9, 0.95, 1.0, 0.8))
	if cracked or enemy.bell_crack > 0.0:
		draw_polyline(PackedVector2Array([top + dir * 0.2 * size, top + side * 0.1 * size + dir * 0.45 * size, top - side * 0.05 * size + dir * 0.7 * size, top + side * 0.15 * size + dir * 0.95 * size]), Color(1, 1, 1, 0.9), 1.0)
