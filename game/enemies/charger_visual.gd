class_name ChargerVisual
extends Node2D
## 돌진형 그림: 뿔 달린 짐승 정령. 오른쪽을 보는 기준으로 그리고 scale.x로 뒤집는다.

var enemy: Charger
var _walk := 0.0


func _process(delta: float) -> void:
	if enemy == null:
		return
	scale.x = enemy.facing
	rotation = enemy._airborne_spin * enemy._t * 12.0 if enemy._airborne_spin != 0.0 else 0.0
	if enemy.state == Charger.S.PATROL:
		_walk += delta * 9.0
	elif enemy.state == Charger.S.CHARGE:
		_walk += delta * 26.0


func _draw() -> void:
	if enemy == null:
		return
	var st := enemy.state
	var white := enemy.flash_amount() > 0.0
	var body := Palette.ENEMY_BODY
	var light := Palette.ENEMY_BODY_LIGHT
	var dark := Palette.ENEMY_DARK
	var eye := Palette.ENEMY_EYE
	var crouch := 0.0
	var shake := Vector2.ZERO
	var danger := 0.0

	if st == Charger.S.WINDUP:
		var k := 1.0 - enemy._timer / enemy.tuning.charger_windup
		crouch = 3.0 * k
		shake = Vector2(randf_range(-1, 1), 0) * k
		danger = k
		eye = Palette.ENEMY_EYE.lerp(Palette.DANGER, k)
	elif st == Charger.S.CHARGE:
		danger = 0.6
		eye = Palette.DANGER

	if white:
		body = Color.WHITE
		light = Color.WHITE
		dark = Color(0.85, 0.85, 0.9)

	var o := shake + Vector2(0, crouch)
	# 위험 예고: 몸 둘레의 붉은 빛
	if danger > 0.0 and not white:
		var glow := Color(Palette.DANGER, 0.25 + 0.35 * danger * (0.6 + 0.4 * sin(enemy._t * 40.0)))
		draw_colored_polygon(_body_poly(o, 3.0), glow)

	# 다리 4개
	var legs := [-8.0, -3.0, 4.0, 9.0]
	for i in legs.size():
		var ph := _walk + i * 1.6
		var lift := maxf(sin(ph), 0.0) * 2.0 if st == Charger.S.PATROL or st == Charger.S.CHARGE else 0.0
		var x: float = legs[i] + cos(ph) * (1.5 if st == Charger.S.CHARGE else 0.8)
		draw_rect(Rect2(Vector2(x - 1.5, -5 - lift) + Vector2(shake.x, 0), Vector2(3, 5 - crouch * 0.3)), dark)

	# 몸통 (어두운 외곽선으로 배경과 분리)
	var poly := _body_poly(o, 0.0)
	draw_colored_polygon(_body_poly(o, 1.0), Palette.OUTLINE if not white else Color.WHITE)
	draw_colored_polygon(poly, body)
	# 등 갈기 (날카로운 삼각형)
	for i in 4:
		var bx := -9.0 + i * 5.0
		draw_colored_polygon(PackedVector2Array([
			o + Vector2(bx - 2, -13 + absf(bx) * 0.08), o + Vector2(bx + 1, -18.5 + absf(bx) * 0.1), o + Vector2(bx + 3, -13 + absf(bx) * 0.08),
		]), light)
	# 배 그림자
	draw_line(o + Vector2(-9, -5.5), o + Vector2(8, -5.5), dark, 1.0)
	# 머리와 뿔
	draw_colored_polygon(PackedVector2Array([
		o + Vector2(7, -14), o + Vector2(14, -11), o + Vector2(15, -6), o + Vector2(8, -5),
	]), light)
	var horn := Color(0.9, 0.85, 0.75) if not white else Color.WHITE
	draw_colored_polygon(PackedVector2Array([o + Vector2(10, -13), o + Vector2(17, -19), o + Vector2(12, -11)]), horn)
	draw_colored_polygon(PackedVector2Array([o + Vector2(13, -8), o + Vector2(19, -9), o + Vector2(14, -6)]), horn)
	# 눈
	if st == Charger.S.RECOVER or st == Charger.S.STAGGER:
		var e := o + Vector2(12, -10)
		draw_line(e + Vector2(-1, -1), e + Vector2(1, 1), eye, 1.0)
		draw_line(e + Vector2(-1, 1), e + Vector2(1, -1), eye, 1.0)
		# 어지러움: 머리 위를 도는 별
		for i in 3:
			var a := enemy._t * 6.0 + i * TAU / 3.0
			draw_rect(Rect2(o + Vector2(4 + cos(a) * 6.0, -22 + sin(a) * 2.0), Vector2(1.5, 1.5)), Palette.GOLD)
	else:
		draw_rect(Rect2(o + Vector2(11, -11), Vector2(2.5, 2)), eye)
		if not white:
			draw_rect(Rect2(o + Vector2(11, -11), Vector2(1, 1)), Color.WHITE)

	# 돌진 속도선
	if st == Charger.S.CHARGE and not white:
		for i in 3:
			var y := -14.0 + i * 4.0
			var slen := 8.0 + fmod(enemy._t * 90.0 + i * 7.0, 10.0)
			draw_line(Vector2(-14 - slen, y), Vector2(-14, y), Color(Palette.ENEMY_EYE, 0.5), 1.0)


func _body_poly(o: Vector2, grow: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 14:
		var a := TAU * i / 14.0
		var rx := 11.5 + grow
		var ry := 6.5 + grow
		pts.append(o + Vector2(-1 + cos(a) * rx, -10 + sin(a) * ry))
	return pts
