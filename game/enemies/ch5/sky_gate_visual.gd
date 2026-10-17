extends Node2D
## 문 그림: 화면을 넘는 흰 고리, 그 안의 검은 바깥 하늘, 금(선), 촉수, 눈, 거신의 손, 장막
## 하늘 문(sky_gate.gd)의 문 그림 (무거움 — 보스전에서만 생김).

const RING_R := 150.0 ## 문 고리 반지름 (sky_gate.gd가 눈·촉수·손 위치에도 이 값을 씀)

var gate: Node


func _ready() -> void:
	z_index = -4


func _process(d: float) -> void:
	# 쓰러진 뒤(적 처리 멈춤)에도 문이 닫히는 연출은 계속
	if gate and gate.state == "dead":
		gate.sealing = minf(float(gate.sealing) + d * 0.45, 1.0)
	queue_redraw()


func _draw() -> void:
	if gate == null:
		return
	var t: float = gate._t
	var seal: float = gate.sealing
	var r: float = RING_R
	var c := Vector2(0, -20)
	var open_k := 1.0 - seal
	# 안쪽: 검은 바깥 하늘 + 먼 별 + 소용돌이
	var inner := PackedVector2Array()
	for i in 40:
		var a := TAU * i / 40.0
		inner.append(c + Vector2(cos(a) * r * 0.86, sin(a) * r * 0.65) * open_k)
	if open_k > 0.02:
		draw_colored_polygon(inner, Color(0.02, 0.01, 0.05))
		for i in 30:
			var a2 := t * (0.05 + (i % 5) * 0.01) + i * 2.4
			var rr := fmod(i * 37.0, r * 0.8)
			draw_rect(Rect2(c + Vector2(cos(a2) * rr, sin(a2) * rr * 0.75) * open_k, Vector2.ONE), Color(0.8, 0.8, 1.0, 0.5))
		for k in 4:
			var sp := PackedVector2Array()
			for i in 24:
				var a3 := t * 0.4 + k * PI * 0.5 + i * 0.25
				var rr2 := (8.0 + i * 4.5) * open_k
				sp.append(c + Vector2(cos(a3) * rr2, sin(a3) * rr2 * 0.75))
			draw_polyline(sp, Color(0.9, 0.9, 1.0, 0.12), 1.0)
	# 흰 고리 (기하학 마디)
	var ring_col := StArt.GOD_WHITE.lerp(Color(0.55, 0.8, 1.0), seal)
	for i in 24:
		var a0 := TAU * i / 24.0 + t * 0.02
		var a1 := a0 + TAU / 24.0 * 0.86
		var p0 := c + Vector2(cos(a0) * r, sin(a0) * r * 0.75)
		var p1 := c + Vector2(cos(a1) * r, sin(a1) * r * 0.75)
		var q0 := c + Vector2(cos(a0) * r * 0.86, sin(a0) * r * 0.65)
		var q1 := c + Vector2(cos(a1) * r * 0.86, sin(a1) * r * 0.65)
		draw_colored_polygon(PackedVector2Array([p0, p1, q1, q0]), ring_col if i % 2 == 0 else StArt.GOD_SHADE.lerp(Color(0.4, 0.6, 0.9), seal))
		draw_line(p0, q0, StArt.GOD_LINE, 1.0)
	draw_arc(c, r + 6.0, 0, TAU, 64, Color(1, 1, 1, 0.25), 2.0)
	for i in 12:
		var a4 := TAU * i / 12.0 - t * 0.05
		draw_line(c + Vector2(cos(a4) * (r + 6.0), sin(a4) * (r + 6.0) * 0.75), c + Vector2(cos(a4) * (r + 30.0), sin(a4) * (r + 30.0) * 0.75), Color(1, 1, 1, 0.3), 1.0)
	# 봉인되는 푸른 불 (닫히는 중)
	if seal > 0.0:
		for i in 16:
			var a5 := TAU * i / 16.0
			StArt.foxfire(self, c + Vector2(cos(a5) * r, sin(a5) * r * 0.75), 6.0, t + i, seal)
	# 장막 (리라를 감싼 흰 막)
	if gate.veiled():
		var vk := 0.5 + 0.2 * sin(t * 3.0)
		draw_circle(Vector2(0, -14), 34.0, Color(1, 1, 1, 0.12 * vk))
		for i in 6:
			var a6 := TAU * i / 6.0 + t * 0.4
			draw_line(Vector2(0, -14) + Vector2.from_angle(a6) * 34.0, Vector2(0, -14) + Vector2.from_angle(a6 + TAU / 6.0) * 34.0, Color(1, 1, 1, 0.6 * vk), 1.0)
	elif gate.exposed():
		draw_arc(Vector2(0, -14), 30.0 + sin(t * 8.0) * 2.0, 0, TAU, 24, Color(1.0, 0.86, 0.45, 0.6), 2.0)
	# 리라를 붙든 흰 사슬(선)
	for i in 4:
		var a7 := -PI * 0.75 + i * PI * 0.5
		var far := c + Vector2(cos(a7) * r * 0.86, sin(a7) * r * 0.65)
		draw_line(Vector2(0, -14), far, Color(1, 1, 1, 0.35 * open_k), 1.0)
	# 촉수
	for td in gate.tendrils:
		_draw_tendril(td, t)
	# 눈
	for e in gate.eyes:
		var ep: Vector2 = to_local(e.global_position)
		var open: float = 0.0 if not e.is_open() else (0.7 + 0.3 * e.charge())
		var look: Vector2 = (to_local(_player_pos()) - ep).normalized()
		draw_circle(ep, 13.0, Color(0.05, 0.05, 0.1))
		StArt.god_eye(self, ep, 11.0, open, look, e.charge())
		if e.flash_amount() > 0.0:
			draw_circle(ep, 12.0, Color(1, 1, 1, 0.6))
	# 문 너머에서 내려오는 거신의 손
	var hp2: Vector2 = gate.hand_pos
	if hp2 != Vector2.INF:
		StColossusArt.draw_slam_hand(self, to_local(hp2), 70.0, StColossusArt.palette(0.05, 1.0))


func _player_pos() -> Vector2:
	var w := World.get_world()
	if w and w.player:
		return w.player.center()
	return global_position + Vector2(0, 100)


func _draw_tendril(td: Node, t: float) -> void:
	var base: Vector2 = to_local(td.global_position)
	var tip: Vector2 = to_local(td.tip())
	var out: float = td.out
	if out < 0.05:
		return
	var mid: Vector2 = base.lerp(tip, 0.5) + Vector2(sin(t * 1.7 + td.index) * 18.0, -30.0)
	var pts := PackedVector2Array()
	var n := 14
	for i in n + 1:
		var u := float(i) / n
		pts.append(base.lerp(mid, u).lerp(mid.lerp(tip, u), u))
	for i in n:
		var u2 := float(i) / n
		var w := lerpf(11.0, 3.0, u2) * out
		var col := StArt.GOD_WHITE if i % 2 == 0 else StArt.GOD_SHADE
		if td.flash_amount() > 0.0:
			col = Color.WHITE
		draw_line(pts[i], pts[i + 1], col, w)
		draw_circle(pts[i], w * 0.5, col)
		if i % 3 == 0:
			draw_line(pts[i] + (pts[i + 1] - pts[i]).orthogonal().normalized() * w * 0.5, pts[i] - (pts[i + 1] - pts[i]).orthogonal().normalized() * w * 0.5, StArt.GOD_LINE, 1.0)
	if td.state == "raise":
		draw_circle(tip, 6.0, Color(1, 1, 1, 0.5 + 0.3 * sin(t * 20.0)))
	if gate and float(gate.frost_t) > 0.0:
		for i in range(0, n, 3):
			draw_rect(Rect2(pts[i] - Vector2(2, 2), Vector2(4, 4)), Color(0.7, 0.9, 1.0, 0.8))
