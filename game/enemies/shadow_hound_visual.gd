class_name ShadowHoundVisual
extends Node2D
## 그림자 늑대 그림: 거의 검은 남보라 실루엣 + 보랏빛 테두리, 등에서 연기가 피어오르고 눈만 보랏빛으로 빛난다.
## 잠행 중엔 바닥의 그림자 웅덩이(눈 두 개가 엿봄), 솟기 직전엔 세라 발밑에 붉은 물결.

var enemy: ShadowHound

const BODY := Color(0.07, 0.05, 0.12)
const RIM := Color(0.45, 0.28, 0.75)
const EYE := Color(0.8, 0.55, 1.0)
const SMOKE := Color(0.25, 0.15, 0.4)

## 몸 실루엣 (오른쪽을 볼 때, 발밑 원점)
const SIL := [
	Vector2(-18, -16), Vector2(-12, -19), Vector2(-4, -20), Vector2(4, -21), Vector2(10, -23),
	Vector2(13, -27), Vector2(15, -30), Vector2(15, -36), Vector2(18, -31), Vector2(20, -36),
	Vector2(21, -30), Vector2(27, -27), Vector2(31, -25), Vector2(30, -22), Vector2(24, -21),
	Vector2(18, -18), Vector2(14, -13), Vector2(9, -10), Vector2(2, -11), Vector2(-8, -11),
	Vector2(-14, -10), Vector2(-19, -12),
]


func _process(_delta: float) -> void:
	if enemy == null:
		return
	if enemy.is_alive():
		scale.x = enemy.facing
	z_index = 2


func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	draw_set_transform(c, 0.0, Vector2(1.0, ry / maxf(rx, 0.01)))
	draw_circle(Vector2.ZERO, rx, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _ring(c: Vector2, r: float, flat: float, col: Color, width: float) -> void:
	draw_set_transform(c, 0.0, Vector2(1.0, flat))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 28, col, width)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw() -> void:
	if enemy == null:
		return
	var t := enemy._t
	var st := enemy.state
	var k := enemy.state_progress()
	var white := enemy.flash_amount() > 0.0

	match st:
		ShadowHound.S.SUBMERGED:
			_draw_puddle(t, 1.0, false)
			return
		ShadowHound.S.RIPPLE:
			_draw_ripple(t, k)
			_draw_puddle(t, 1.0, true)
			return
		ShadowHound.S.SINK:
			_draw_puddle(t, k, false)
			# 바닥으로 녹아내림: 아래로 눌리며 납작해짐
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0 + 0.35 * k, maxf(1.0 - k, 0.05)))
			_draw_wolf(t, st, white, k)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			return
	if st == ShadowHound.S.ERUPT and enemy.velocity.y < 0.0:
		# 솟구치는 중: 머리를 하늘로 쳐든 자세
		draw_set_transform(Vector2(0, -4), -0.7, Vector2(0.95, 1.1))
		_draw_wolf(t, st, white, k)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		_draw_wolf(t, st, white, k)


func _draw_wolf(t: float, st: ShadowHound.S, white: bool, k: float) -> void:
	var fl := 0.6 if white else 0.0
	var solid := st == ShadowHound.S.OPEN or st == ShadowHound.S.DAZED
	var body := BODY.lerp(Color(0.2, 0.16, 0.3), 0.6 if solid else 0.0).lerp(Color.WHITE, fl)
	var rim := RIM.lerp(Color(0.75, 0.6, 1.0), 0.5 if solid else 0.0).lerp(Color.WHITE, fl)
	var moving := absf(enemy.velocity.x) > 10.0 and enemy.is_on_floor()
	var crouch := 0.0
	if st == ShadowHound.S.GROWL:
		crouch = 3.0 * k
	var breathe := sin(t * (9.0 if st == ShadowHound.S.OPEN else 3.0)) * (1.0 if st == ShadowHound.S.OPEN else 0.5)

	# 뒤에 옅은 보랏빛 기운 (어두운 배경에서 윤곽이 읽히게)
	draw_circle(Vector2(4, -18), 22.0, Color(RIM, 0.1))
	# 연기 꼬리 (흔들림)
	var wag := sin(t * 6.0) * 3.0
	var tail := PackedVector2Array([
		Vector2(-17, -17 + crouch), Vector2(-32, -24 + wag), Vector2(-28, -17 + wag * 0.5), Vector2(-18, -12 + crouch),
	])
	draw_colored_polygon(tail, body)
	draw_polyline(tail, Color(rim, 0.7), 1.0)
	# 다리 4개 (걷기 흔들림): 테두리색으로 굵게 그린 뒤 몸색으로 덮음
	var legs := [Vector2(-15, -11), Vector2(-9, -11), Vector2(8, -11), Vector2(13, -11)]
	for i in 4:
		var top: Vector2 = legs[i]
		var sw := sin(t * 14.0 + i * PI * 0.5) * (4.0 if moving else 0.0)
		if st == ShadowHound.S.DASH or st == ShadowHound.S.LUNGE or (st == ShadowHound.S.ERUPT and not enemy.is_on_floor()):
			sw = (6.0 if i >= 2 else -6.0)
		var knee := top + Vector2(-2.0 if i < 2 else 1.0, 5.0 + crouch * 0.5)
		var foot := Vector2(top.x + sw, 0)
		draw_polyline(PackedVector2Array([top + Vector2(0, crouch), knee, foot]), Color(rim, 0.8), 4.0)
		draw_polyline(PackedVector2Array([top + Vector2(0, crouch), knee, foot]), body, 2.0)
	# 몸통 실루엣
	var pts := PackedVector2Array()
	for i in SIL.size():
		var v: Vector2 = SIL[i]
		if v.y < -11.0:
			v.y += crouch + (breathe if i < 5 else 0.0) * 0.5
		pts.append(v)
	draw_colored_polygon(pts, body)
	var loop := pts.duplicate()
	loop.append(pts[0])
	draw_polyline(loop, Color(rim, 0.95), 1.0)
	# 등줄기 윤광
	draw_polyline(PackedVector2Array([pts[1] + Vector2(0, 2), pts[2] + Vector2(0, 2), pts[3] + Vector2(0, 2), pts[4] + Vector2(0, 2)]), Color(rim, 0.45), 1.0)

	# 등에서 피어오르는 그림자 연기
	for i in 6:
		var ph := fmod(t * 0.9 + i * 0.29, 1.0)
		var sx := lerpf(-16.0, 10.0, i / 5.0) + sin(t * 2.0 + i) * 2.0
		var sy := -21.0 + crouch - ph * 14.0
		var sz := 3.0 - ph * 2.0
		draw_rect(Rect2(sx, sy, sz, sz), Color(SMOKE.lightened(0.25), 0.7 * (1.0 - ph)))

	# 입: 무는 동안 크게 벌림
	var biting := st == ShadowHound.S.ERUPT or st == ShadowHound.S.DASH or st == ShadowHound.S.LUNGE
	if biting:
		draw_colored_polygon(PackedVector2Array([Vector2(23, -25), Vector2(35, -18), Vector2(24, -20)]), Color(0.02, 0.0, 0.05))
		for i in 3:
			draw_line(Vector2(25 + i * 3.0, -24 + i * 1.8), Vector2(25 + i * 3.0, -22.5 + i * 1.8), Color(0.9, 0.75, 1.0), 1.0)
	elif st == ShadowHound.S.OPEN:
		# 헐떡임: 혀
		draw_rect(Rect2(27, -22, 3, 3 + absf(breathe)), Color(0.8, 0.4, 0.65))

	# 눈
	var eye_pos := Vector2(21, -29 + crouch)
	match st:
		ShadowHound.S.DAZED:
			draw_line(eye_pos + Vector2(-1.5, -1.5), eye_pos + Vector2(1.5, 1.5), EYE, 1.0)
			draw_line(eye_pos + Vector2(-1.5, 1.5), eye_pos + Vector2(1.5, -1.5), EYE, 1.0)
			# 머리 위를 도는 별 (여우창문의 푸른빛)
			for i in 3:
				var a := t * 5.0 + TAU * i / 3.0
				var c := Vector2(18 + cos(a) * 9.0, -41 + sin(a) * 2.5)
				var col := Color(0.6, 0.85, 1.0) if i != 1 else Palette.GOLD
				draw_line(c + Vector2(-2, 0), c + Vector2(2, 0), col, 1.0)
				draw_line(c + Vector2(0, -2), c + Vector2(0, 2), col, 1.0)
		ShadowHound.S.OPEN:
			draw_rect(Rect2(eye_pos + Vector2(-1, 0), Vector2(3, 1)), Color(EYE, 0.6))
		_:
			var danger := st == ShadowHound.S.GROWL
			var ec := Palette.DANGER if danger else EYE
			draw_circle(eye_pos, 4.0 if danger else 3.0, Color(ec, 0.25))
			draw_rect(Rect2(eye_pos + Vector2(-1, -1), Vector2(3, 2)), ec)
			draw_rect(Rect2(eye_pos + Vector2(0, -1), Vector2(1, 1)), Color.WHITE)
			if danger:
				draw_line(eye_pos + Vector2(4, -1), eye_pos + Vector2(12, -2), Color(Palette.DANGER, 0.5 * k), 1.0)


## 그림자 웅덩이 (k: 퍼진 정도 0~1)
func _draw_puddle(t: float, k: float, glare: bool) -> void:
	var rx := lerpf(12.0, 24.0, k)
	var wave := sin(t * 8.0) * 1.0
	_ellipse(Vector2(0, -1), rx + 2.0 + wave, 3.5, Color(0.0, 0.0, 0.0, 0.5 * k))
	_ellipse(Vector2(0, -1), rx + wave, 2.6, Color(0.03, 0.01, 0.07, 0.95))
	_ring(Vector2(0, -1), rx + wave, 0.14, Color(RIM.lightened(0.2), 0.9 * k), 1.0)
	if k < 0.5:
		return
	# 엿보는 눈 두 개
	var ec := Palette.DANGER if glare else EYE
	var blink := fmod(t, 2.3) < 0.12
	if not blink:
		for i in 2:
			var e := Vector2(5 + i * 5, -2)
			draw_circle(e, 2.5, Color(ec, 0.25))
			draw_rect(Rect2(e + Vector2(-1, -0.5), Vector2(2, 1)), ec)
	# 뒤로 끌리는 연기
	if enemy.state == ShadowHound.S.SUBMERGED:
		for i in 4:
			var ph := fmod(t * 2.0 + i * 0.25, 1.0)
			draw_rect(Rect2(-rx - 2.0 - ph * 10.0, -3.0 - ph * 6.0, 2, 2), Color(SMOKE, 0.7 * (1.0 - ph)))


## 솟아오르기 직전 물결 예고 (붉은 고리가 퍼지며 바닥이 들끓음)
func _draw_ripple(t: float, k: float) -> void:
	var c := Vector2(0, -1)
	for i in 3:
		var ph := fmod(t * 2.5 + i / 3.0, 1.0)
		_ring(c, 8.0 + ph * 34.0, 0.22, Color(Palette.DANGER, 0.95 * (1.0 - ph)), 2.0)
	_ring(c, 18.0, 0.22, Color(Palette.DANGER, 0.4 + 0.6 * k), 2.0)
	# 솟을 자리에서 그림자 가시가 비죽비죽
	for i in 5:
		var x := -12.0 + i * 6.0
		var hh := (2.0 + 4.0 * k) * (0.6 + 0.4 * sin(t * 30.0 + i * 1.7))
		draw_line(Vector2(x, -1), Vector2(x + 1, -1 - hh), Color(0.12, 0.05, 0.2), 2.0)
	# 위쪽으로 붉은 경고 빛줄기
	draw_rect(Rect2(-12, -44, 24, 43), Color(Palette.DANGER, 0.1 + 0.18 * k))
