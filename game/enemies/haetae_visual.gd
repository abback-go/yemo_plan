class_name HaetaeVisual
extends Node2D
## 해태 그림: 광화문 해태 석상 같은 남색 돌 몸, 소용돌이 갈기, 이마의 외뿔, 붉은 옻칠 목띠와 금방울.
## 예고는 붉은색으로 통일: 돌진 전 몸이 붉게 달아오르고, 도약 전 착지 지점에 붉은 표시, 불 숨결 전 불길 범위가 붉은 선으로 보인다.
## 오른쪽을 보는 기준으로 그리고 scale.x로 뒤집는다. 몸 전체 찌그러짐은 발밑 기준 변환, 머리는 목을 축으로 돌린다.

const STONE := Color("#3d4163")
const STONE_LIGHT := Color("#5f6696")
const STONE_DARK := Color("#272a44")
const MANE := Color("#363c6a")
const MANE_LIGHT := Color("#6c74ae")
const HORN := Color("#cfc6a8")
const LACQUER := Color("#b8322a")
const LACQUER_DARK := Color("#6e1a1c")
const MOUTH_IN := Color("#4a1016")
const FANG := Color("#ece4d0")
const EYE := Color("#ffb347")

var enemy: Haetae
var _walk := 0.0
var _white := false
var _tint := 0.0
var _hit := 0.0
var _tf := Transform2D.IDENTITY


func _process(delta: float) -> void:
	if enemy == null:
		return
	scale.x = enemy.facing
	_walk += absf(enemy.velocity.x) * delta * 0.09
	z_index = 1


## 상태에 따른 색 (붉은 예고 → 맞았을 때 살짝 밝아짐)
func _c(col: Color) -> Color:
	if _white:
		return Color.WHITE
	var c := col
	if _tint > 0.0:
		c = c.lerp(Palette.DANGER, _tint)
	if _hit > 0.0:
		c = c.lerp(Color.WHITE, _hit)
	return c


func _draw() -> void:
	if enemy == null:
		return
	var st := enemy.state
	var k := enemy.state_k()
	var t := enemy._t
	# 큰 몸이 통째로 하얘지면 붉은 예고가 안 보이므로, 맞으면 몸 색만 살짝 밝힌다
	_white = false
	_hit = enemy.flash_amount() if st != Haetae.S.DEFEATED else 0.0
	_tint = 0.0
	var by := 0.0 # 몸통을 내림(+)
	var sq := Vector2.ONE
	var head_rot := 0.0 # -: 고개를 듦, +: 숙임
	var head_off := Vector2.ZERO
	var jaw := 0.0
	var eye_mode := 0 # 0 뜸, 1 감음, 2 어질(X), 3 찡그림, 4 만족(^)
	var kneel := 0.0
	var shake := Vector2.ZERO
	var breathe := sin(t * 2.2)
	var stride := 2.5
	var danger_eye := 0.0
	match st:
		Haetae.S.DORMANT:
			by = 6.0 + breathe * 0.6
			head_rot = 0.28
			eye_mode = 1
			kneel = 1.0
		Haetae.S.RISE:
			by = lerpf(6.0, 0.0, k)
			kneel = 1.0 - k
			head_rot = lerpf(0.28, -0.12, k)
			eye_mode = 0 if k > 0.25 else 1
			jaw = 0.5 * sin(k * PI)
		Haetae.S.STALK:
			by = breathe * 0.5
			head_rot = sin(t * 1.4) * 0.04
		Haetae.S.CHARGE_WINDUP:
			by = 2.5 * k
			head_rot = 0.32 * k
			head_off = Vector2(2.0, 3.0) * k
			_tint = 0.5 * k * (0.75 + 0.25 * sin(t * 30.0))
			shake.x = randf_range(-1.0, 1.0) * k
			danger_eye = k
		Haetae.S.CHARGE:
			by = absf(sin(_walk * 1.5)) * 1.5
			head_rot = 0.32
			head_off = Vector2(3, 3)
			_tint = 0.3
			stride = 5.0
			danger_eye = 1.0
		Haetae.S.WALL_STAGGER:
			by = 2.0
			head_rot = 0.2 + sin(t * 7.0) * 0.06
			eye_mode = 2
			if k < 0.25:
				shake.x = randf_range(-2.0, 2.0)
		Haetae.S.SKID:
			by = 1.0
			head_rot = 0.15
		Haetae.S.CROUCH:
			sq = Vector2(1.0 + 0.08 * k, 1.0 - 0.14 * k)
			head_rot = -0.12 * k
			_tint = 0.42 * k * (0.75 + 0.25 * sin(t * 30.0))
			danger_eye = k
		Haetae.S.LEAP:
			if enemy.velocity.y < 0.0:
				sq = Vector2(0.94, 1.08)
				head_rot = -0.22
			else:
				head_rot = 0.18
			_tint = 0.25
			danger_eye = 1.0
		Haetae.S.LAND:
			sq = Vector2(1.0 + 0.12 * (1.0 - k), 1.0 - 0.15 * (1.0 - k))
			head_rot = 0.1
		Haetae.S.BREATH_WINDUP:
			head_rot = -0.45 * k
			head_off = Vector2(-3.0 * k, 0)
			jaw = 0.35 * k
			_tint = 0.35 * k * (0.75 + 0.25 * sin(t * 30.0))
			danger_eye = k
		Haetae.S.BREATH:
			head_rot = 0.12 + sin(t * 25.0) * 0.02
			head_off = Vector2(2, 0)
			jaw = 1.0
		Haetae.S.PANT:
			head_rot = 0.16
			jaw = 0.3 + 0.25 * absf(sin(t * 9.0))
			by = absf(sin(t * 9.0))
		Haetae.S.EAT_WINDUP:
			head_rot = -0.3 * k
			jaw = 0.8 * k
		Haetae.S.INHALE:
			head_rot = -0.3 + sin(t * 12.0) * 0.03
			jaw = 1.0
			sq = Vector2(1.0 + 0.05 * k, 1.0 + 0.05 * k) # 들이켜며 부푼다
		Haetae.S.SATED:
			head_rot = -0.1
			eye_mode = 4
		Haetae.S.FLINCH:
			head_rot = -0.35 * (1.0 - k)
			head_off = Vector2(-3.0 * (1.0 - k), 0)
			eye_mode = 3
			shake.x = randf_range(-1.5, 1.5) * (1.0 - k)
		Haetae.S.ROAR:
			head_rot = -0.5
			jaw = 1.0
			by = -2.0
			shake = Vector2(randf_range(-1.5, 1.5), randf_range(-0.5, 0.5))
			_tint = 0.35 * (1.0 - k)
			danger_eye = 1.0
		Haetae.S.DEFEATED:
			var dk := enemy.death_k()
			by = 6.0 * dk
			kneel = dk
			head_rot = 0.45 * dk
			eye_mode = 1 if dk > 0.35 else 3
	if enemy.is_enraged:
		danger_eye = maxf(danger_eye, 0.6)
	var walking := st == Haetae.S.STALK or st == Haetae.S.CHARGE or st == Haetae.S.SKID

	# 예고 표시는 몸 변환과 상관없이 그린다
	_draw_leap_marker(st, t)

	_tf = Transform2D(0.0, sq, 0.0, shake)
	draw_set_transform_matrix(_tf)

	var outline := Color.WHITE if _white else Palette.OUTLINE
	var stone := _c(STONE)
	var light := _c(STONE_LIGHT)
	var dark := _c(STONE_DARK)
	var mane := _c(MANE)
	var mane_light := _c(MANE_LIGHT)
	var lacquer := Color.WHITE if _white else LACQUER

	# 위험 예고: 몸 둘레 붉은 빛
	if _tint > 0.0 and not _white:
		var glow := Color(Palette.DANGER, 0.18 + 0.3 * _tint)
		draw_circle(Vector2(-18, -27 + by), 16.0, glow)
		draw_circle(Vector2(14, -29 + by), 17.0, glow)
		draw_circle(Vector2(29, -38 + by) + head_off, 17.0, glow)
		draw_rect(Rect2(-20, -44 + by, 36, 30), glow)

	# 꼬리 (몸 뒤): 위로 말린 소용돌이 + 불꽃 끝
	var tail: Array[Vector2] = [Vector2(-28, -36), Vector2(-34, -42), Vector2(-34, -50), Vector2(-28, -54), Vector2(-23, -50)]
	var tail_r: Array[float] = [6.0, 5.5, 5.0, 4.5, 3.0]
	var wag := sin(t * 2.0) * 1.0
	for i in tail.size():
		draw_circle(tail[i] + Vector2(wag * i * 0.4, by), tail_r[i] + 1.0, outline)
	for i in tail.size():
		draw_circle(tail[i] + Vector2(wag * i * 0.4, by), tail_r[i], mane)
		if i < 4 and not _white:
			draw_arc(tail[i] + Vector2(wag * i * 0.4, by), tail_r[i] * 0.5, 0.0, PI * 1.4, 6, mane_light, 1.0)
	var flame := clampf(enemy.fed_glow + (0.4 if enemy.is_enraged else 0.0), 0.0, 1.0) if st != Haetae.S.DEFEATED else 0.0
	if flame > 0.05 and not _white:
		var tip := tail[3] + Vector2(wag * 1.2, by)
		var fl := 4.0 + 8.0 * flame + sin(t * 18.0) * 1.5
		draw_colored_polygon(PackedVector2Array([tip + Vector2(-3, 0), tip + Vector2(1, -fl), tip + Vector2(4, 0)]), Color(Palette.FIRE_OUT, 0.85))
		draw_colored_polygon(PackedVector2Array([tip + Vector2(-1.5, 0), tip + Vector2(1, -fl * 0.6), tip + Vector2(2.5, 0)]), Palette.FIRE_HOT)

	# 다리: 먼 쪽(어둡게) → 몸통 → 가까운 쪽
	var legs_far: Array[float] = [-11.0, 19.0]
	var legs_near: Array[float] = [-18.0, 12.0]
	var phases: Array[float] = [PI, 0.0, 0.0, PI]
	for i in 2:
		_draw_leg(legs_far[i], by, phases[i], walking, stride, kneel if i == 1 else 0.0, _c(STONE_DARK).darkened(0.25), outline)

	# 몸통: 둥근 엉덩이 + 부푼 가슴
	draw_circle(Vector2(-18, -27 + by), 13.5, outline)
	draw_circle(Vector2(14, -29 + by), 14.5, outline)
	draw_rect(Rect2(-25, -41 + by, 42, 28), outline)
	draw_circle(Vector2(-18, -27 + by), 12.5, stone)
	draw_circle(Vector2(14, -29 + by), 13.5, stone)
	draw_rect(Rect2(-24, -40 + by, 40, 26), stone)
	draw_rect(Rect2(-22, -40 + by, 34, 3), light)
	draw_rect(Rect2(-20, -16 + by, 30, 3), dark)
	# 비늘 무늬
	if not _white:
		for row in 2:
			for i in 4:
				var c := Vector2(-17.0 + i * 7.0 + row * 3.5, -32.0 + row * 6.0 + by)
				draw_arc(c, 3.2, 0.0, PI, 5, Color(STONE_LIGHT, 0.55), 1.0)
	# 등줄기 갈기 소용돌이 (불을 먹거나 화나면 끝이 불꽃)
	for i in 5:
		var c2 := Vector2(-22.0 + i * 7.0, -41.0 + by)
		draw_circle(c2, 3.6, mane)
		if not _white:
			draw_arc(c2, 1.8, 0.0, PI * 1.5, 5, mane_light, 1.0)
			if flame > 0.05:
				var fh := (2.0 + 3.0 * flame) * (0.7 + 0.3 * sin(t * 20.0 + i * 1.7))
				draw_rect(Rect2(c2 + Vector2(-1, -3.0 - fh), Vector2(2, fh)), Color(Palette.FIRE_OUT, 0.8))
	# 가슴 갈기 (턱 아래로 흘러내리는 소용돌이)
	var chest: Array[Vector2] = [Vector2(21, -31), Vector2(23, -24), Vector2(21, -17)]
	for c3 in chest:
		draw_circle(c3 + Vector2(0, by), 4.6, outline)
		draw_circle(c3 + Vector2(0, by), 3.8, mane)
		if not _white:
			draw_arc(c3 + Vector2(0, by), 1.9, 0.5, PI * 1.8, 6, mane_light, 1.0)
	# 붉은 옻칠 목띠 + 금방울
	var lacq_dark := Color.WHITE if _white else LACQUER_DARK
	draw_colored_polygon(PackedVector2Array([
		Vector2(9, -36 + by), Vector2(17, -36 + by), Vector2(23, -12 + by), Vector2(15, -12 + by),
	]), lacq_dark)
	draw_colored_polygon(PackedVector2Array([
		Vector2(10.5, -36 + by), Vector2(15.5, -36 + by), Vector2(21.5, -12.5 + by), Vector2(16.5, -12.5 + by),
	]), lacquer)
	var bell := Vector2(19.5 + sin(t * 3.0) * 0.8, -10 + by)
	draw_circle(bell, 3.8, outline)
	draw_circle(bell, 3.0, Color.WHITE if _white else Palette.GOLD)
	draw_line(bell + Vector2(-1.5, 1), bell + Vector2(1.5, 1), outline, 1.0)
	if not _white:
		draw_rect(Rect2(bell + Vector2(-1.5, -2), Vector2(1, 1)), Color(1, 1, 0.85))

	for i in 2:
		_draw_leg(legs_near[i], by, phases[i + 2], walking, stride, kneel if i == 1 else 0.0, stone, outline)

	# 머리 (목을 축으로)
	var pivot := Vector2(17, -40 + by) + head_off
	draw_set_transform_matrix(_tf * Transform2D(head_rot, pivot))
	_draw_head(st, t, jaw, eye_mode, danger_eye, outline, stone, light, dark, mane, mane_light)
	var mouth_local := pivot + Vector2(28, 9.0 + jaw * 4.0).rotated(head_rot)
	draw_set_transform_matrix(_tf)

	# 불 숨결 · 들이켜기 · 어지러움
	match st:
		Haetae.S.BREATH_WINDUP:
			_draw_breath_cone(mouth_local, t, k, true)
		Haetae.S.BREATH:
			_draw_breath_cone(mouth_local, t, 1.0, false)
		Haetae.S.INHALE, Haetae.S.EAT_WINDUP:
			if not _white:
				for i in 3:
					var r := 34.0 - fmod(t * 70.0 + i * 11.0, 34.0)
					var a0 := t * 5.0 + i * TAU / 3.0
					draw_arc(mouth_local, r, a0, a0 + 1.3, 7, Color(Palette.FIRE_HOT, 0.55 * (r / 34.0)), 1.5)
		Haetae.S.WALL_STAGGER:
			for i in 3:
				var a := t * 6.0 + i * TAU / 3.0
				draw_rect(Rect2(pivot + Vector2(10 + cos(a) * 10.0, -20 + sin(a) * 3.0), Vector2(2, 2)), Palette.GOLD)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_leg(x: float, by: float, phase: float, walking: bool, stride: float, kneel: float, col: Color, outline: Color) -> void:
	var ph := _walk * 2.0 + phase
	var dx := sin(ph) * stride if walking else 0.0
	var lift := maxf(cos(ph), 0.0) * 3.0 if walking else 0.0
	var top := -18.0 + by
	if kneel > 0.5:
		# 앞다리를 접고 엎드림
		draw_rect(Rect2(x - 6.0, -7.0, 18, 7), outline)
		draw_rect(Rect2(x - 5.0, -6.0, 16, 5), col)
		return
	draw_rect(Rect2(x - 5.5 + dx, top, 11, -top - lift + 0.5), outline)
	draw_rect(Rect2(x - 4.5 + dx, top, 9, -top - lift - 1.0), col)
	# 발 (발톱 셋)
	var py := -4.0 - lift
	draw_rect(Rect2(x - 6.0 + dx, py, 13, 4), outline)
	draw_rect(Rect2(x - 5.0 + dx, py, 11, 3), col.lightened(0.12))
	if not _white:
		for c in 3:
			draw_rect(Rect2(x - 3.0 + dx + c * 3.5, py + 2.0, 1, 1), Palette.OUTLINE)


func _draw_head(st: Haetae.S, t: float, jaw: float, eye_mode: int, danger_eye: float, outline: Color,
		stone: Color, light: Color, dark: Color, mane: Color, mane_light: Color) -> void:
	var hc := Vector2(12, 1) # 머리 중심
	# 갈기: 머리 뒤·위·아래를 감싼 소용돌이
	for i in 8:
		var a := deg_to_rad(105.0 + i * 28.0)
		draw_circle(hc + Vector2(cos(a), sin(a)) * 12.5, 6.4, outline)
	for i in 8:
		var a2 := deg_to_rad(105.0 + i * 28.0)
		var c2 := hc + Vector2(cos(a2), sin(a2)) * 12.5
		draw_circle(c2, 5.5, mane)
		if not _white:
			draw_arc(c2, 2.7, a2, a2 + PI * 1.4, 6, mane_light, 1.0)
	# 외뿔 (이마 위)
	var horn := HORN if not _white else Color.WHITE
	if danger_eye > 0.0 and not _white and (st == Haetae.S.CHARGE_WINDUP or st == Haetae.S.CHARGE):
		horn = HORN.lerp(Palette.DANGER, 0.6 * danger_eye)
	draw_colored_polygon(PackedVector2Array([Vector2(8, -8), Vector2(15, -8), Vector2(16, -15), Vector2(10, -14)]), horn)
	draw_colored_polygon(PackedVector2Array([Vector2(10, -14), Vector2(16, -15), Vector2(20, -23)]), horn)
	# 머리통 (둥근 이마) + 넓적한 주둥이
	draw_circle(hc, 11.5, outline)
	draw_rect(Rect2(14, -5, 18, 14), outline)
	draw_circle(hc, 10.5, stone)
	draw_rect(Rect2(15, -4, 16, 12), light)
	if not _white:
		draw_arc(hc, 8.5, PI * 1.15, PI * 1.7, 6, light, 2.0) # 이마의 빛
	# 코 (넓은 사자코)
	draw_rect(Rect2(26, -4, 6, 5), outline)
	draw_rect(Rect2(27, -3, 4, 2), dark if not _white else Color.WHITE)
	# 눈: 툭 튀어나온 큰 눈 + 두꺼운 눈썹
	var e := Vector2(18, -0.5)
	var eye_col := EYE.lerp(Palette.DANGER, danger_eye)
	match eye_mode:
		1:
			draw_line(e + Vector2(-3.5, 0.5), e + Vector2(3.5, 0.5), outline, 1.0)
		2:
			draw_line(e + Vector2(-3, -2.5), e + Vector2(3, 2.5), outline, 1.0)
			draw_line(e + Vector2(-3, 2.5), e + Vector2(3, -2.5), outline, 1.0)
		3:
			draw_line(e + Vector2(-3, -2.5), e + Vector2(2.5, 0), outline, 1.0)
			draw_line(e + Vector2(2.5, 0), e + Vector2(-3, 2.5), outline, 1.0)
		4:
			draw_line(e + Vector2(-3, 1), e + Vector2(0, -2), outline, 1.0)
			draw_line(e + Vector2(0, -2), e + Vector2(3, 1), outline, 1.0)
		_:
			if danger_eye > 0.0 and not _white:
				draw_circle(e, 5.0 + 3.0 * danger_eye, Color(Palette.DANGER, 0.2 + 0.25 * danger_eye))
			draw_circle(e, 4.4, outline)
			draw_circle(e, 3.6, Color.WHITE if _white else Color(1.0, 0.95, 0.85))
			if not _white:
				draw_circle(e + Vector2(1, 0), 2.3, eye_col)
				draw_rect(Rect2(e + Vector2(0.6, -1.3), Vector2(1.3, 2.6)), Palette.OUTLINE)
				draw_rect(Rect2(e + Vector2(-1.5, -2), Vector2(1, 1)), Color.WHITE)
	draw_line(Vector2(12, -6), Vector2(23, -5), dark if not _white else Color.WHITE, 2.0) # 성난 눈썹
	# 입: 이빨을 드러낸 웃음. 벌린 만큼 아래턱이 내려간다
	var fang := FANG if not _white else Color.WHITE
	var drop := jaw * 9.0
	if drop > 0.5:
		draw_rect(Rect2(14, 7, 17, drop), Color.WHITE if _white else MOUTH_IN)
		var fire_mouth := st == Haetae.S.BREATH or st == Haetae.S.BREATH_WINDUP or st == Haetae.S.INHALE or st == Haetae.S.ROAR
		if fire_mouth and not _white:
			var gk := 1.0 if st != Haetae.S.BREATH_WINDUP else enemy.state_k()
			draw_circle(Vector2(25, 7 + drop * 0.5), 3.0 + 4.0 * gk + sin(t * 30.0), Color(Palette.FIRE_HOT, 0.4 + 0.4 * gk))
	draw_rect(Rect2(14, 7, 18, 1), outline)
	draw_rect(Rect2(17, 6, 13, 2), fang) # 윗니 줄
	draw_rect(Rect2(28, 6, 2, 3.5), fang) # 송곳니
	if not _white:
		for i in 4:
			draw_rect(Rect2(19.5 + i * 3.0, 6, 0.6, 2), Color(MOUTH_IN, 0.8))
	# 아래턱
	draw_rect(Rect2(13, 8 + drop, 19, 6), outline)
	draw_rect(Rect2(14, 8 + drop, 17, 5), stone)
	draw_rect(Rect2(18, 7 + drop, 11, 1.5), fang) # 아랫니
	draw_rect(Rect2(19, 5.5 + drop, 2, 2.5), fang)
	# 턱수염 소용돌이
	draw_circle(Vector2(16, 14 + drop), 3.8, outline)
	draw_circle(Vector2(16, 14 + drop), 3.1, mane)
	draw_circle(Vector2(23, 14.5 + drop), 3.4, outline)
	draw_circle(Vector2(23, 14.5 + drop), 2.7, mane)


## 착지 예고: 웅크린 동안 세라를 따라가다 도약 순간 고정되는 붉은 표시
func _draw_leap_marker(st: Haetae.S, t: float) -> void:
	if enemy.leap_target == Vector2.INF:
		return
	if st != Haetae.S.CROUCH and st != Haetae.S.LEAP:
		return
	draw_set_transform_matrix(Transform2D.IDENTITY)
	var m := to_local(enemy.leap_target)
	var strong := 1.0 if st == Haetae.S.LEAP else enemy.state_k()
	var pulse := 0.6 + 0.4 * sin(t * 30.0)
	var col := Color(Palette.DANGER, (0.25 + 0.5 * strong) * pulse)
	var half := enemy.body_size.x * 0.5
	draw_rect(Rect2(m.x - half, m.y - 2.0, half * 2.0, 3.0), col)
	draw_rect(Rect2(m.x - half - 1.0, m.y - 7.0, 2.0, 7.0), col)
	draw_rect(Rect2(m.x + half - 1.0, m.y - 7.0, 2.0, 7.0), col)
	var ay := m.y - 16.0 - sin(t * 10.0) * 2.0
	draw_colored_polygon(PackedVector2Array([Vector2(m.x - 5, ay), Vector2(m.x + 5, ay), Vector2(m.x, ay + 6)]), col)


## 불 숨결 부채꼴: 예고 땐 범위만 붉은 선, 뿜을 땐 일렁이는 불길 세 겹 (판정: 입 앞 4T, 아래로 퍼져 바닥까지)
func _draw_breath_cone(m: Vector2, t: float, k: float, preview: bool) -> void:
	if _white:
		return
	if preview:
		var pulse := 0.5 + 0.5 * sin(t * 30.0)
		var line := _cone_points(m, 1.0, 1.0, t, 0.0)
		line.append(line[0])
		draw_polyline(line, Color(Palette.DANGER, (0.2 + 0.5 * k) * (0.6 + 0.4 * pulse)), 1.0)
		return
	var layers: Array[Color] = [Color(Palette.FIRE_DARK, 0.6), Color(Palette.FIRE_OUT, 0.75), Color(Palette.FIRE_HOT, 0.85)]
	var sizes: Array[float] = [1.0, 0.72, 0.45]
	var reach := 64.0
	for i in layers.size():
		var s := sizes[i]
		draw_colored_polygon(_cone_points(m, s, k, t + i * 0.37, 1.0), layers[i])
		# 끝을 둥글게: 불길 끝의 뭉게 불꽃
		var u := k * (0.85 + 0.15 * s)
		var end := Vector2(m.x + reach * u, m.y + (-m.y) * 0.55 * u)
		draw_circle(end + Vector2(-3, 0), (3.0 + 12.0 * u) * s, layers[i])


## 불길 윤곽 점들: 입에서 앞으로 뻗으며 아래로 처지고(가운데선), 앞으로 갈수록 넓어진다
func _cone_points(m: Vector2, s: float, k: float, t: float, jitter: float) -> PackedVector2Array:
	var reach := 64.0
	var n := 5
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	for i in n + 1:
		var u := float(i) / n * k * (0.85 + 0.15 * s)
		var cx := m.x + reach * u
		var cy := m.y + (-m.y) * 0.55 * u
		var hw := (3.0 + 15.0 * u) * s
		var wob := sin(t * 26.0 + u * 9.0) * 2.5 * u * jitter
		top.append(Vector2(cx, cy - hw + wob))
		bottom.append(Vector2(cx, minf(cy + hw - wob, -1.0)))
	bottom.reverse()
	top.append_array(bottom)
	return top
