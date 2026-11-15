extends Node2D
## 백금 사도 그림: 흰 팔면체 핵(세로로 갈라진 틈에서 흰빛), 금 테 두른 기하 고리 두 겹(서로 반대로 돎), 둘레를 도는 거울판 3장.
## 바깥 신들 계열이라 예고는 흰색 — 대신 굵고 깜빡이게(docs/archive/sera/systems2.md 3절). 빛줄기·격자는 가산 합성 자식(_fx)이 그린다.

const H := preload("res://enemies/ch4/holy.gd")
const WHITE := Color(0.96, 0.96, 1.0)
const GRAY := Color(0.7, 0.72, 0.82)
const GOLD := Color(1.0, 0.84, 0.42)
const OUTL := Color("#101018")

var enemy: GoldHerald
var _fx: FxDraw


class FxDraw extends Node2D:
	var h: GoldHerald

	func _ready() -> void:
		material = Fx.add_material
		top_level = true
		z_index = 6

	func _process(_d: float) -> void:
		global_position = Vector2.ZERO
		queue_redraw()

	func _draw() -> void:
		if h == null or not is_instance_valid(h):
			return
		var t := h._t
		var blink := 0.5 + 0.5 * signf(sin(t * 22.0))
		match h.state:
			GoldHerald.S.PRISM_AIM:
				for path in h.prism_paths:
					var pts: PackedVector2Array = path
					draw_polyline(pts, Color(1, 1, 1, 0.12 + 0.25 * h.progress()), 7.0)
					draw_polyline(pts, Color(1, 1, 1, 0.35 + 0.5 * blink), 2.0)
			GoldHerald.S.PRISM:
				for path in h.prism_paths:
					var pts2: PackedVector2Array = path
					H.draw_beam(self, pts2, 5.0, Color(0.92, 0.94, 1.0), Color.WHITE, 1.0)
			GoldHerald.S.LATTICE_WARN:
				for c in h.lattice:
					var cp: Vector2 = c
					var k := h.progress()
					draw_rect(Rect2(cp + Vector2(-13, -26), Vector2(26, 26)), Color(1, 1, 1, 0.08 + 0.15 * k * blink))
					draw_rect(Rect2(cp + Vector2(-13, -2), Vector2(26, 2)), Color(1, 1, 1, 0.4 + 0.5 * blink))
					draw_rect(Rect2(cp + Vector2(-13, -26), Vector2(26, 26)), Color(1, 1, 1, 0.5 + 0.4 * blink), false, 2.0)
			GoldHerald.S.LATTICE:
				for c in h.lattice:
					var cp2: Vector2 = c
					var e := 1.0 - h.progress()
					for i in 3:
						var x := -9.0 + i * 9.0
						var hh := 30.0 + (i % 2) * 8.0
						draw_colored_polygon(PackedVector2Array([cp2 + Vector2(x - 4, 0), cp2 + Vector2(x, -hh), cp2 + Vector2(x + 4, 0)]), Color(0.95, 0.96, 1.0, 0.9 * e))
						draw_line(cp2 + Vector2(x, 0), cp2 + Vector2(x, -hh), Color(GOLD, 0.8 * e), 1.0)
					draw_rect(Rect2(cp2 + Vector2(-14, -3), Vector2(28, 3)), Color(1, 1, 1, e))
			GoldHerald.S.SPIN_WARN:
				for i in 3:
					var a := h.panel_angle(i)
					var c2 := h.core() + Vector2(cos(a), sin(a)) * GoldHerald.ORBIT_SPIN
					draw_arc(h.core(), GoldHerald.ORBIT_SPIN, a - 0.3, a + 0.3, 6, Color(1, 1, 1, 0.3 + 0.5 * blink), 3.0)
					draw_circle(c2, 4.0, Color(1, 1, 1, 0.5 * blink))


func _ready() -> void:
	_fx = FxDraw.new()
	_fx.h = enemy
	add_child(_fx)


func _draw() -> void:
	if enemy == null:
		return
	var white := enemy.flash_amount() > 0.0
	var t := enemy._t
	var c := Vector2(0, -20)
	var dk := enemy.dying_k
	var st := enemy.state
	var shake := Vector2(sin(t * 60.0), cos(t * 47.0)) * 2.0 * dk
	c += shake
	draw_set_transform(c * (1.0 - 1.5), 0.0, Vector2(1.5, 1.5)) # 핵·고리는 1.5배 (c를 중심으로)
	# 빛 무리
	draw_circle(c, 26.0, Color(1, 1, 1, 0.05))
	draw_circle(c, 16.0, Color(GOLD, 0.06))
	# 기하 고리 두 겹 (사각·삼각, 서로 반대로 돎)
	_poly_ring(c, 21.0, 4, t * 0.6, Color(GOLD, 0.7 * (1.0 - dk)), 1.5)
	_poly_ring(c, 17.0, 3, -t * 0.9, Color(WHITE, 0.6 * (1.0 - dk)), 1.0)
	# 핵 (팔면체 = 마름모 두 겹)
	var s := 1.0 + 0.06 * sin(t * 3.0)
	var outer := PackedVector2Array([c + Vector2(0, -12) * s, c + Vector2(9, 0) * s, c + Vector2(0, 12) * s, c + Vector2(-9, 0) * s])
	var o2 := PackedVector2Array()
	for p in outer:
		o2.append(c + (p - c) * 1.15)
	draw_colored_polygon(o2, OUTL)
	draw_colored_polygon(outer, Color.WHITE if white else WHITE)
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -12) * s, c + Vector2(9, 0) * s, c + Vector2(0, 12) * s, c]), Color.WHITE if white else GRAY)
	draw_line(c + Vector2(0, -12) * s, c + Vector2(0, 12) * s, GOLD, 1.0)
	# 얼굴 자리의 세로 틈 (흰빛)
	var open := 1.0
	if st == GoldHerald.S.PRISM_AIM:
		open = 1.0 + enemy.progress() * 1.5
	elif st == GoldHerald.S.GROUNDED or st == GoldHerald.S.STAGGER:
		open = 2.5
	draw_rect(Rect2(c + Vector2(-0.5 * open, -6), Vector2(open, 12)), Color(1, 1, 1, 0.95))
	draw_circle(c, 3.0 * open, Color(1, 1, 1, 0.2))
	if dk > 0.0:
		for i in 6:
			var a := TAU * i / 6.0 + t
			draw_line(c, c + Vector2(cos(a), sin(a)) * 30.0 * dk, Color(1, 1, 1, dk), 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# 거울판 3장
	if not enemy.panels_dropped():
		for i in 3:
			var a := enemy.panel_angle(i)
			var pc := c + Vector2(cos(a), sin(a)) * enemy.orbit
			var tang := Vector2(-sin(a), cos(a))
			var nrm := Vector2(cos(a), sin(a))
			var half := GoldHerald.PANEL_LEN * 0.5
			var flash := 0.0
			if st == GoldHerald.S.SPIN_WARN:
				flash = 0.5 + 0.5 * signf(sin(t * 22.0))
			var pts := PackedVector2Array([pc - tang * half - nrm * 3.0, pc + tang * half - nrm * 3.0, pc + tang * half + nrm * 3.0, pc - tang * half + nrm * 3.0])
			var po := PackedVector2Array()
			for p in pts:
				po.append(pc + (p - pc) * 1.2)
			draw_colored_polygon(po, OUTL)
			draw_colored_polygon(pts, Color(0.75, 0.82, 0.98).lerp(Color.WHITE, flash))
			draw_line(pc - tang * half + nrm * 2.0, pc + tang * half + nrm * 2.0, GOLD, 1.0)
			var g := fmod(t * 1.3 + i * 0.4, 1.0)
			draw_line(pc + tang * (g * 2.0 - 1.0) * half - nrm * 1.5, pc + tang * (g * 2.0 - 1.0) * half + nrm * 1.5, Color(1, 1, 1, 0.9), 1.0)
	else:
		# 떨어뜨린 판: 발밑에 누워 있음
		for i in 3:
			var px := -16.0 + i * 16.0
			draw_rect(Rect2(Vector2(px - 7, -3), Vector2(14, 3)), Color(0.6, 0.66, 0.8))
			draw_line(Vector2(px - 7, -3), Vector2(px + 7, -3), GOLD, 1.0)


func _poly_ring(c: Vector2, r: float, n: int, rot: float, col: Color, w: float) -> void:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := rot + TAU * i / n
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	draw_polyline(pts, col, w)
