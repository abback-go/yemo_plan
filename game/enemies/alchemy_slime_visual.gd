class_name AlchemySlimeVisual
extends Node2D
## 연금 슬라임 그림: 플라스크 물약 색(반투명 청록)의 출렁이는 덩어리. 안에 코르크 마개·유리 조각·"F" 맞은 과제 쪽지·기포가 떠다닌다.
## 달아오를수록 노랑 → 주황 → 붉은 주황, 부풀면 깜빡이며 커진다. 뛰기 전 착지 자리에 그림자 예고(크게 뛸 땐 붉은 테두리).

var enemy: AlchemySlime

const W := 38.0
const H := 25.0


## 달아오름 0~1 → 몸 색
static func goo_color(r: float) -> Color:
	var teal := Color(0.25, 0.8, 0.72)
	var lime := Color(0.85, 0.86, 0.38)
	var orange := Color(1.0, 0.55, 0.2)
	var hot := Color(1.0, 0.3, 0.15)
	if r < 0.34:
		return teal.lerp(lime, r / 0.34)
	if r < 0.67:
		return lime.lerp(orange, (r - 0.34) / 0.33)
	return orange.lerp(hot, (r - 0.67) / 0.33)


func _process(_delta: float) -> void:
	if enemy == null:
		return
	if enemy.is_alive():
		scale.x = enemy.facing
	z_index = 2


func _squash() -> Vector2:
	var t := enemy._t
	var k := enemy.state_progress()
	var s := Vector2(1.0 + 0.04 * sin(t * 3.0), 1.0 - 0.04 * sin(t * 3.0))
	match enemy.state:
		AlchemySlime.S.HOP_WIND:
			s = Vector2(1.0 + 0.25 * k, 1.0 - 0.3 * k)
		AlchemySlime.S.LEAP_WIND:
			var tremble := sin(t * 60.0) * 0.03 * k
			s = Vector2(1.0 + 0.42 * k + tremble, 1.0 - 0.45 * k)
		AlchemySlime.S.HOP, AlchemySlime.S.LEAP:
			s = Vector2(0.85, 1.2) if enemy.velocity.y < 0.0 else Vector2(0.95, 1.08)
		AlchemySlime.S.LAND:
			s = Vector2(1.3 - 0.3 * k, 0.72 + 0.28 * k)
		AlchemySlime.S.SLAM:
			var f := clampf(k / 0.3, 0.0, 1.0)
			s = Vector2(1.55 - 0.1 * f, 0.45 + 0.05 * f) if k < 0.7 else Vector2(1.45, 0.5).lerp(Vector2.ONE, (k - 0.7) / 0.3)
		AlchemySlime.S.SWELL:
			var g := 1.0 + 0.5 * k + sin(t * (20.0 + 30.0 * k)) * 0.06 * k
			s = Vector2(g, g * 0.95)
	var wob := enemy.wobble()
	s += Vector2(sin(t * 26.0), -sin(t * 26.0)) * 0.1 * wob
	return s


func _blob(w: float, h: float, wob: float, t: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 17:
		var a := PI + PI * i / 16.0
		var rr := 1.0 + sin(a * 3.0 + t * 5.0) * (0.03 + 0.06 * wob)
		pts.append(Vector2(cos(a) * w * 0.5 * rr, sin(a) * h * rr))
	pts.append(Vector2(w * 0.46, 1.0))
	pts.append(Vector2(-w * 0.46, 1.0))
	return pts


func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	draw_set_transform(c, 0.0, Vector2(1.0, ry / maxf(rx, 0.01)))
	draw_circle(Vector2.ZERO, rx, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw() -> void:
	if enemy == null:
		return
	var t := enemy._t
	var st := enemy.state
	var white := enemy.flash_amount() > 0.0
	var heat_r := enemy.heat_ratio()
	var goo := goo_color(heat_r)
	var k := enemy.state_progress()

	# ─ 착지 예고 그림자 ─
	if st == AlchemySlime.S.HOP_WIND or st == AlchemySlime.S.HOP or st == AlchemySlime.S.LEAP_WIND or st == AlchemySlime.S.LEAP:
		var big := st == AlchemySlime.S.LEAP_WIND or st == AlchemySlime.S.LEAP
		var at := to_local(Vector2(enemy.land_x, enemy.ground_y))
		var a := 0.35 + 0.25 * (k if st == AlchemySlime.S.HOP_WIND or st == AlchemySlime.S.LEAP_WIND else 1.0)
		var rx := (24.0 if big else 15.0)
		if st == AlchemySlime.S.LEAP:
			rx *= 0.7 + 0.5 * clampf(enemy.velocity.y / 400.0, 0.0, 1.0)
		_ellipse(at + Vector2(0, -1), rx, 3.5, Color(0.0, 0.0, 0.02, a))
		draw_set_transform(at + Vector2(0, -1), 0.0, Vector2(1.0, 0.2))
		draw_arc(Vector2.ZERO, rx, 0.0, TAU, 24, Color(goo, 0.45), 1.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if big:
			var locked := st == AlchemySlime.S.LEAP or enemy._timer <= AlchemySlime.LEAP_LOCK_TIME
			var blink := locked and int(t * 20.0) % 2 == 0
			var rim := Color.WHITE if blink else Palette.DANGER
			draw_set_transform(at + Vector2(0, -1), 0.0, Vector2(1.0, 0.18))
			draw_arc(Vector2.ZERO, rx + 3.0, 0.0, TAU, 28, Color(rim, 0.85), 3.0)
			draw_arc(Vector2.ZERO, rx + 9.0 - 6.0 * fmod(t * 2.0, 1.0), 0.0, TAU, 28, Color(Palette.DANGER, 0.4), 2.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			# 위에서 떨어진다는 표시: 아래를 향한 붉은 꺾쇠
			for i in 2:
				var yy := -14.0 - i * 7.0 - 4.0 * fmod(t * 3.0, 1.0)
				draw_line(at + Vector2(-5, yy), at + Vector2(0, yy + 4), Color(Palette.DANGER, 0.7), 2.0)
				draw_line(at + Vector2(5, yy), at + Vector2(0, yy + 4), Color(Palette.DANGER, 0.7), 2.0)
	# 공중에 떠 있을 때 자기 발밑 그림자
	if not enemy.is_on_floor() and (st == AlchemySlime.S.HOP or st == AlchemySlime.S.LEAP):
		var under := to_local(Vector2(enemy.global_position.x, enemy.ground_y))
		_ellipse(under + Vector2(0, -1), 10.0, 2.5, Color(0, 0, 0.02, 0.3))

	# ─ 몸 ─
	var sq := _squash()
	var w := W * sq.x
	var h := H * sq.y
	var wob := enemy.wobble()
	# 맞으면 흰색으로 반쯤만 번쩍 (달아오른 색이 계속 보이게)
	var fl := 0.6 if white else 0.0
	var outline := goo.darkened(0.78).lerp(Color.WHITE, fl)
	var body := Color(goo.lerp(Color.WHITE, fl), 0.72 + 0.2 * fl)
	var body_in := Color(goo.lightened(0.25), 0.5)
	var swell_blink := st == AlchemySlime.S.SWELL and int(t * (8.0 + 22.0 * k)) % 2 == 0
	if swell_blink:
		body = Color(1.0, 0.92, 0.8, 0.9)
		outline = Palette.DANGER.darkened(0.3)

	var out_pts := _blob(w + 3.0, h + 2.0, wob, t)
	draw_colored_polygon(out_pts, outline)
	draw_colored_polygon(_blob(w, h, wob, t), body)
	# 봉인의 보랏빛 마력 심지 (학교 물건을 움직이는 폭주 마력)
	var core := Vector2(sin(t * 1.3) * 2.0, -h * 0.42)
	draw_circle(core, h * 0.32, Color(0.55, 0.25, 0.9, 0.22))
	draw_circle(core, h * 0.16, Color(0.7, 0.45, 1.0, 0.25))
	# 안쪽 밝은 층
	draw_colored_polygon(_blob(w * 0.72, h * 0.62, wob * 0.5, t + 1.0), body_in)

	# 안에 떠다니는 것들: 코르크 마개, 유리 조각, "F" 쪽지
	var drift := sin(t * 1.1) * 1.5
	draw_set_transform(Vector2(-w * 0.22, -h * 0.3 + drift), sin(t * 0.8) * 0.6 + 0.4, Vector2.ONE)
	draw_rect(Rect2(-3, -2.5, 6, 5), Color(0.55, 0.36, 0.22, 0.9))
	draw_rect(Rect2(-3, -2.5, 6, 1), Color(0.75, 0.55, 0.35, 0.9))
	draw_set_transform(Vector2(w * 0.05, -h * 0.2 - drift), -0.35 + sin(t * 0.6) * 0.2, Vector2.ONE)
	draw_rect(Rect2(-3, -3.5, 6, 7), Color(0.93, 0.9, 0.8, 0.85))
	draw_line(Vector2(-1, -2.5), Vector2(-1, 2.5), Color(0.85, 0.12, 0.15), 1.0)
	draw_line(Vector2(-1, -2.5), Vector2(2, -2.5), Color(0.85, 0.12, 0.15), 1.0)
	draw_line(Vector2(-1, 0), Vector2(1.5, 0), Color(0.85, 0.12, 0.15), 1.0)
	draw_set_transform(Vector2(-w * 0.05, -h * 0.62 + drift * 0.5), t * 0.5, Vector2.ONE)
	draw_colored_polygon(PackedVector2Array([Vector2(-3, 2), Vector2(0, -4), Vector2(3, 1)]), Color(0.9, 0.98, 1.0, 0.6))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# 기포: 달아오를수록 빨라진다
	var speed := 0.35 + 1.1 * heat_r
	for i in 6:
		var ph := fmod(t * (speed + 0.07 * i) + i * 0.37, 1.0)
		var bx := sin(i * 2.3 + t * 0.7) * w * 0.32
		var by := lerpf(-2.0, -h * 0.92, ph)
		var br := 1.0 + 0.6 * float(i % 3)
		draw_arc(Vector2(bx, by), br, 0.0, TAU, 8, Color(1, 1, 1, 0.55 * (1.0 - ph)), 1.0)

	# 윤기
	draw_line(Vector2(-w * 0.32, -h * 0.55), Vector2(-w * 0.18, -h * 0.82), Color(1, 1, 1, 0.55), 2.0)
	draw_circle(Vector2(-w * 0.12, -h * 0.88), 1.2, Color(1, 1, 1, 0.6))

	# 눈과 입
	var eye_y := -h * 0.6
	var ex := w * 0.2
	var dark := Color(0.04, 0.06, 0.08)
	match st:
		AlchemySlime.S.SWELL:
			for sx: float in [-1.0, 1.0]:
				draw_arc(Vector2(ex + sx * 5.0, eye_y), 2.5, t * 12.0, t * 12.0 + TAU * 0.8, 8, dark, 1.0)
			draw_circle(Vector2(ex, eye_y + 6.0), 2.5, dark)
		AlchemySlime.S.SLAM:
			# 납작해져 어질어질 (빈틈)
			for sx: float in [-1.0, 1.0]:
				var c := Vector2(ex + sx * 5.0, eye_y)
				draw_line(c + Vector2(-2, -2), c + Vector2(2, 2), dark, 1.0)
				draw_line(c + Vector2(-2, 2), c + Vector2(2, -2), dark, 1.0)
		_:
			var angry := st == AlchemySlime.S.LEAP_WIND or st == AlchemySlime.S.HOP_WIND
			for sx: float in [-1.0, 1.0]:
				var c := Vector2(ex + sx * 5.0, eye_y)
				_ellipse(c, 1.6, 2.4, dark)
				draw_rect(Rect2(c + Vector2(-0.5, -1.5), Vector2(1, 1)), Color(1, 1, 1, 0.9))
				if angry:
					draw_line(c + Vector2(-2.5 * sx, -4.0), c + Vector2(2.0 * sx, -2.5), dark, 1.0)
			if st == AlchemySlime.S.HOP or st == AlchemySlime.S.LEAP:
				draw_circle(Vector2(ex, eye_y + 5.0), 1.5, dark)
			else:
				draw_line(Vector2(ex - 2, eye_y + 5.0), Vector2(ex, eye_y + 6.0), dark, 1.0)
				draw_line(Vector2(ex, eye_y + 6.0), Vector2(ex + 2, eye_y + 5.0), dark, 1.0)

	# 달아오름: 몸 위로 튀는 불티, 부풀 때 붉은 금
	if heat_r > 0.3:
		for i in 3:
			var ph := fmod(t * 1.5 + i * 0.33, 1.0)
			var px := sin(i * 4.1 + t) * w * 0.3
			draw_rect(Rect2(px, -h - 2.0 - ph * 10.0, 1.5, 1.5), Color(Palette.FIRE_HOT, (1.0 - ph) * heat_r))
	if st == AlchemySlime.S.SWELL:
		var crack := Color(1.0, 0.95, 0.6, 0.6 + 0.4 * k)
		draw_line(Vector2(-w * 0.3, -h * 0.3), Vector2(-w * 0.1, -h * 0.5), crack, 1.0)
		draw_line(Vector2(-w * 0.1, -h * 0.5), Vector2(-w * 0.15, -h * 0.75), crack, 1.0)
		draw_line(Vector2(w * 0.25, -h * 0.2), Vector2(w * 0.35, -h * 0.45), crack, 1.0)
		draw_line(Vector2(w * 0.05, -h * 0.85), Vector2(w * 0.15, -h * 0.6), crack, 1.0)
		draw_arc(Vector2(0, -h * 0.5), w * 0.5 + 4.0 + 3.0 * sin(t * 30.0), 0.0, TAU, 24, Color(Palette.DANGER, 0.5 * k), 1.0)
	# 크게 뛰기 예고: 몸 테두리가 붉게
	if st == AlchemySlime.S.LEAP_WIND:
		draw_polyline(out_pts, Color(Palette.DANGER, 0.5 + 0.5 * k), 1.5)
