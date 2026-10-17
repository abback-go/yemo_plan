extends Node2D
## 백색 사도 그림: 얼굴 없는 흰 몸(직선 무늬), 세로 틈, 등 뒤 기하학 고리, 도는 조각, 수정 눈 셋
## 흰 전령(white_herald.gd)의 그림.

const WHITE := WhiteHerald.WHITE

const BODY_C := Color("#ececf6")
const BODY_SH := Color("#a6a6b8")
const BODY_DK := Color("#6e6e80")
const LINE := Color("#8a8a9e")
var enemy: WhiteHerald


func bob() -> float:
	if enemy == null:
		return 0.0
	return sin(enemy._t * 1.1) * 2.5


func _process(_d: float) -> void:
	if enemy == null:
		return
	scale.x = enemy.facing
	z_index = 2


func _draw() -> void:
	if enemy == null:
		return
	var t := enemy._t
	var st := enemy.state
	var b := bob()
	var hit := enemy.flash_amount()
	var stunned := st == WhiteHerald.S.STUNNED
	var dk := enemy.death_k() if st == WhiteHerald.S.DEFEATED else 0.0
	var dormant := st == WhiteHerald.S.DORMANT
	var al := 1.0 - clampf((dk - 0.4) / 0.6, 0.0, 1.0)
	var body := BODY_C.lerp(Color.WHITE, hit)
	var shade := BODY_SH.lerp(Color.WHITE, hit * 0.5)
	if dormant:
		body = body.darkened(0.35)
		shade = shade.darkened(0.35)
	body.a = al
	shade.a = al
	var c := Vector2(0, -44 + b)
	var tilt := 0.25 if stunned else 0.0
	# 등 뒤 기하학 고리 (천천히 돎) — 원 + 육각형 + 삼각형 둘
	var halo_c := c + Vector2(-2, -14)
	var rot := t * 0.25
	var ha := (0.35 if not dormant else 0.12) * al
	draw_arc(halo_c, 34.0, 0, TAU, 48, Color(1, 1, 1, ha * 0.7), 1.0)
	_poly(halo_c, 34.0, 6, rot, Color(1, 1, 1, ha), 1.0)
	_poly(halo_c, 26.0, 3, -rot * 1.6, Color(1, 1, 1, ha * 0.8), 1.0)
	_poly(halo_c, 26.0, 3, -rot * 1.6 + PI, Color(1, 1, 1, ha * 0.8), 1.0)
	for i in 6:
		var a := rot + TAU * i / 6.0
		draw_rect(Rect2(halo_c + Vector2(cos(a), sin(a)) * 34.0 - Vector2(1.5, 1.5), Vector2(3, 3)), Color(1, 1, 1, ha * 1.6))
	# 길게 늘어진 아래 몸 (발 없이 끝이 뾰족하게 떠 있음)
	var hem := c + Vector2(0, 40)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-14, 2), c + Vector2(14, 2), hem + Vector2(6, -6), hem, hem + Vector2(-6, -6)]), shade)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-10, 2), c + Vector2(12, 2), hem + Vector2(4, -8), hem + Vector2(-2, -4)]), body)
	# 몸통 (어깨가 넓고 매끈한 흰 상체)
	var torso := PackedVector2Array([c + Vector2(-16, -14), c + Vector2(16, -14), c + Vector2(13, 4), c + Vector2(-13, 4)])
	draw_colored_polygon(torso, shade)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-13, -14), c + Vector2(16, -14), c + Vector2(12, 3), c + Vector2(-9, 3)]), body)
	# 직선 무늬 (기하학 금)
	var lc := Color(LINE, 0.9 * al)
	draw_line(c + Vector2(0, -14), c + Vector2(0, 32), lc, 1.0)
	draw_line(c + Vector2(-12, -10), c + Vector2(0, 0), lc, 1.0)
	draw_line(c + Vector2(12, -10), c + Vector2(0, 0), lc, 1.0)
	draw_line(c + Vector2(-6, 14), c + Vector2(0, 24), lc, 1.0)
	draw_line(c + Vector2(6, 14), c + Vector2(0, 24), lc, 1.0)
	draw_rect(Rect2(c + Vector2(-3, -4), Vector2(6, 6)), Color(1, 1, 1, 0.4 * al))
	# 가는 팔 둘 (축 늘어짐 — 손 끝이 바늘처럼)
	for side in [-1.0, 1.0]:
		var sh := c + Vector2(side * 15, -12)
		var sway := sin(t * 0.9 + side) * 2.0
		var el := sh + Vector2(side * 4 + sway, 16)
		var hand := el + Vector2(side * 1 + sway, 18)
		draw_line(sh, el, shade, 3.0)
		draw_line(el, hand, shade, 2.0)
		draw_line(hand, hand + Vector2(0, 6), Color(1, 1, 1, al), 1.0)
	# 머리 (얼굴 없는 긴 달걀형) + 세로 틈
	draw_set_transform(c + Vector2(0, -26), tilt, Vector2.ONE)
	var head := PackedVector2Array()
	for i in 16:
		var a2 := TAU * i / 16.0
		head.append(Vector2(cos(a2) * 8.0, sin(a2) * 11.0))
	draw_colored_polygon(head, shade)
	var head2 := PackedVector2Array()
	for i in 16:
		var a3 := TAU * i / 16.0
		head2.append(Vector2(cos(a3) * 6.5 - 0.5, sin(a3) * 10.0 - 0.5))
	draw_colored_polygon(head2, body)
	var slit_open := 0.5 + 0.5 * sin(t * 0.7)
	if stunned:
		slit_open = 1.0
	if st == WhiteHerald.S.LANCE_WINDUP or st == WhiteHerald.S.CAGE:
		slit_open = 0.8 + 0.2 * sin(t * 20.0)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -8), Vector2(1.5 + slit_open, 0), Vector2(0, 8), Vector2(-1.5 - slit_open, 0)]), Color(BODY_DK, al))
	draw_line(Vector2(0, -7), Vector2(0, 7), Color(1, 1, 1, (0.5 + 0.5 * slit_open) * al), 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# 수정 눈 셋 (약점) — 이마·양 어깨
	var eoffs := [Vector2(0, -34), Vector2(14, -14), Vector2(-14, -14)]
	for i in 3:
		var ep: Vector2 = c + (eoffs[i] as Vector2)
		if i < enemy.eyes:
			_eye(ep, t + i * 1.3, al, st)
		else:
			# 깨진 자리: 금 간 검은 구멍
			draw_circle(ep, 3.0, Color(0.2, 0.2, 0.26, al))
			draw_line(ep + Vector2(-4, -3), ep + Vector2(4, 3), Color(1, 1, 1, 0.6 * al), 1.0)
			draw_line(ep + Vector2(3, -4), ep + Vector2(-2, 4), Color(1, 1, 1, 0.4 * al), 1.0)
	# 둘레를 도는 흰 조각들
	for i in 7:
		var a4 := t * (0.6 + i * 0.07) + TAU * i / 7.0
		var rr := 30.0 + sin(t * 0.8 + i) * 5.0
		var sp := c + Vector2(cos(a4) * rr, sin(a4) * rr * 0.45 + 4.0)
		var n := 3 if i % 2 == 0 else 4
		var shard := PackedVector2Array()
		for j in n:
			var a5 := t * 1.5 + i + TAU * j / n
			shard.append(sp + Vector2(cos(a5), sin(a5)) * 3.0)
		draw_colored_polygon(shard, Color(1, 1, 1, (0.55 if not dormant else 0.2) * al))
	# 무방비: 몸이 깜빡이고 흰 금이 번짐
	if stunned:
		var bl := 0.5 + 0.5 * sin(t * 24.0)
		draw_arc(c, 24.0, 0, TAU, 24, Color(1, 1, 1, 0.4 * bl), 2.0)
	if enemy._broken_flash > 0.0:
		draw_circle(c, 40.0 * enemy._broken_flash, Color(1, 1, 1, 0.25 * enemy._broken_flash))
	# 쓰러짐: 금이 온몸에 번짐
	if dk > 0.0:
		var n2 := int(dk * 14.0)
		for i in n2:
			var a6 := i * 2.4
			var p0 := c + Vector2(cos(a6) * 6.0, sin(a6) * 10.0)
			var p1 := p0 + Vector2(cos(a6 + 0.5), sin(a6 + 0.5)) * (10.0 + i)
			draw_line(p0, p1, Color(0.3, 0.3, 0.4, al), 1.0)


func _eye(p: Vector2, t: float, al: float, st: int) -> void:
	var pulse := 0.6 + 0.4 * sin(t * 2.0)
	draw_circle(p, 6.0, Color(1, 1, 1, 0.12 * pulse * al))
	var hexp := PackedVector2Array()
	for j in 6:
		var a := TAU * j / 6.0 + PI / 6.0
		hexp.append(p + Vector2(cos(a), sin(a)) * 3.6)
	draw_colored_polygon(hexp, Color(0.92, 0.95, 1.0, al))
	hexp.append(hexp[0])
	draw_polyline(hexp, Color(0.55, 0.55, 0.7, al), 1.0)
	# 세로 동공
	var look := 1.0 if st == WhiteHerald.S.LANCE_WINDUP else 0.6
	draw_line(p + Vector2(0, -2.5), p + Vector2(0, 2.5), Color(0.15, 0.15, 0.2, al), 1.0 + look * 0.5)


func _poly(cc: Vector2, r: float, n: int, rot: float, col: Color, w: float) -> void:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := rot + TAU * i / n
		pts.append(cc + Vector2(cos(a), sin(a)) * r)
	draw_polyline(pts, col, w)
