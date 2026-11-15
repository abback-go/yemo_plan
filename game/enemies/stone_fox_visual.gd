class_name StoneFoxVisual
extends Node2D
## 석상 여우 그림: 웅크린 여우 석상(남색 돌, 붉은 옻칠 턱받이, 위로 말린 꼬리).
## 예고 때 눈이 붉게 타오르고 돌 틈으로 붉은 빛이 새며, 돌진 중엔 눈빛이 꼬리를 끈다.
## 벽에 부딪힐 때마다 금이 하나씩 늘고, 기절 중엔 머리 위로 별이 돈다. 오른쪽을 보는 기준, scale.x로 뒤집는다.

const STONE := Color("#4a4a5e")
const STONE_LIGHT := Color("#6b6b85")
const STONE_DARK := Color("#2f2f40")
const LACQUER := Color("#b8322a")
const LACQUER_DARK := Color("#6e1a1c")
const CRACK := Color("#15141f")

var enemy: StoneFox
var _walk := 0.0


func _process(delta: float) -> void:
	if enemy == null:
		return
	scale.x = enemy.facing
	rotation = enemy._airborne_spin * enemy._t * 12.0 if enemy._airborne_spin != 0.0 else 0.0
	if enemy.awake and enemy.wake_left <= 0.0:
		if enemy.state == Charger.S.PATROL:
			_walk += delta * 8.0
		elif enemy.state == Charger.S.CHARGE:
			_walk += delta * 28.0


func _draw() -> void:
	if enemy == null:
		return
	var st := enemy.state
	var white := enemy.flash_amount() > 0.0
	var t := enemy._t
	var dormant := not enemy.awake
	var waking := enemy.awake and enemy.wake_left > 0.0
	var stunned := enemy.wall_stunned or st == Charger.S.STAGGER
	var wk := enemy.windup_k()
	var charging := st == Charger.S.CHARGE and not dormant and not waking
	var danger := wk if st == Charger.S.WINDUP and not waking else (0.6 if charging else 0.0)

	var stone := Color.WHITE if white else STONE
	var light := Color.WHITE if white else STONE_LIGHT
	var dark := Color(0.85, 0.85, 0.9) if white else STONE_DARK
	var outline := Color.WHITE if white else Palette.OUTLINE
	var lacquer := Color.WHITE if white else LACQUER

	var o := Vector2.ZERO
	if st == Charger.S.WINDUP and not waking:
		o = Vector2(randf_range(-1, 1) * wk, 2.5 * wk) # 웅크리며 떨림
	elif waking:
		o = Vector2(randf_range(-1.2, 1.2), 0) # 돌가루를 털어냄
	elif charging:
		o = Vector2(0, 1)

	# 위험 예고: 몸 윤곽을 따라 번지는 붉은 빛 (바닥 아래로는 새지 않게)
	if danger > 0.0 and not white:
		var pulse := 0.6 + 0.4 * sin(t * 40.0)
		var glow := Color(Palette.DANGER, 0.14 + 0.26 * danger * pulse)
		var hy := -1.5 * wk if not charging else 2.0
		draw_circle(o + Vector2(-7, -11), 8.0, glow)
		draw_circle(o + Vector2(6, -11), 8.0, glow)
		draw_circle(o + Vector2(11, -17 + hy), 7.5, glow)
		draw_circle(o + (Vector2(-19, -14) if charging else Vector2(-14, -18)), 7.0, glow)

	# 꼬리 (몸 뒤): 평소엔 위로 말리고, 돌진 중엔 뒤로 날린다
	var tail: Array[Vector2] = [Vector2(-12, -12), Vector2(-15, -16), Vector2(-14, -21), Vector2(-11, -24)]
	if charging:
		tail = [Vector2(-13, -12), Vector2(-17, -13), Vector2(-21, -14), Vector2(-25, -15)]
	var tail_r: Array[float] = [3.5, 4.0, 3.5, 2.5]
	var wag := sin(t * 3.0) * 0.6 if not dormant else 0.0
	for i in tail.size():
		draw_circle(o + tail[i] + Vector2(wag * i, 0), tail_r[i] + 1.0, outline)
	for i in tail.size():
		var col := light if i == tail.size() - 1 else stone
		draw_circle(o + tail[i] + Vector2(wag * i, 0), tail_r[i], col)

	# 다리 4개
	var legs: Array[float] = [-8.0, -4.0, 5.0, 9.0]
	for i in legs.size():
		var ph := _walk + i * 1.7
		var moving := (st == Charger.S.PATROL or charging) and not dormant and not waking
		var lift := maxf(sin(ph), 0.0) * 2.0 if moving else 0.0
		var x := legs[i] + (cos(ph) * (1.6 if charging else 0.7) if moving else 0.0)
		draw_rect(Rect2(Vector2(x - 1.5, -5.0 - lift), Vector2(3, 5)), dark)
		draw_rect(Rect2(Vector2(x - 2.0, -1.0 - lift), Vector2(4, 1)), outline)

	# 몸통: 웅크린 덩어리 (외곽선 → 돌)
	draw_circle(o + Vector2(-7, -10), 6.0, outline)
	draw_circle(o + Vector2(6, -10), 6.0, outline)
	draw_rect(Rect2(o + Vector2(-8, -15), Vector2(15, 10)), outline)
	draw_circle(o + Vector2(-7, -10), 5.0, stone)
	draw_circle(o + Vector2(6, -10), 5.0, stone)
	draw_rect(Rect2(o + Vector2(-7, -14), Vector2(13, 8)), stone)
	draw_rect(Rect2(o + Vector2(-8, -15), Vector2(11, 2)), light) # 등 윤곽 빛
	draw_line(o + Vector2(-9, -5.5), o + Vector2(8, -5.5), dark, 1.0) # 배 그림자
	if not white:
		# 돌 얼룩
		draw_rect(Rect2(o + Vector2(-4, -11), Vector2(2, 1)), dark)
		draw_rect(Rect2(o + Vector2(1, -8), Vector2(1, 1)), dark)
		draw_rect(Rect2(o + Vector2(-9, -9), Vector2(1, 2)), dark)

	# 머리: 목 → 머리통 → 주둥이 → 귀
	var h := o + Vector2(0, -1.5 * wk if not charging else 2.0) # 돌진 땐 머리를 낮춘다
	draw_rect(Rect2(h + Vector2(5, -19), Vector2(10, 8)), outline)
	draw_rect(Rect2(h + Vector2(6, -18), Vector2(8, 6)), stone)
	draw_colored_polygon(PackedVector2Array([h + Vector2(13, -18), h + Vector2(21, -14.5), h + Vector2(13, -12)]), stone)
	draw_line(h + Vector2(14, -12.5), h + Vector2(20, -14), dark, 1.0) # 입선
	draw_rect(Rect2(h + Vector2(20, -15.5), Vector2(1.5, 1.5)), outline) # 코
	draw_colored_polygon(PackedVector2Array([h + Vector2(6, -18), h + Vector2(7.5, -26), h + Vector2(10, -18)]), stone)
	draw_colored_polygon(PackedVector2Array([h + Vector2(9.5, -18), h + Vector2(12.5, -25), h + Vector2(13.5, -17)]), light)
	if not white:
		draw_line(h + Vector2(7.5, -19), h + Vector2(7.8, -23), LACQUER_DARK, 1.0) # 귓속

	# 붉은 옻칠 턱받이 (신사 여우상)
	draw_colored_polygon(PackedVector2Array([h + Vector2(5, -12.5), h + Vector2(13, -12.5), h + Vector2(9, -7)]), lacquer)
	if not white:
		draw_line(h + Vector2(5, -12.5), h + Vector2(13, -12.5), LACQUER_DARK, 1.0)
		draw_rect(Rect2(h + Vector2(8.5, -9), Vector2(1, 1)), Palette.GOLD)

	# 금: 벽에 부딪힐 때마다 하나씩, 체력이 반 아래면 하나 더
	var n := enemy.cracks + (1 if enemy.hp * 2 <= enemy.max_hp else 0)
	var crack_col := CRACK
	if danger > 0.0 and not white:
		crack_col = CRACK.lerp(Palette.DANGER, 0.5 + 0.5 * danger) # 예고 땐 금 사이로 붉은 빛
	if n >= 1:
		draw_polyline(PackedVector2Array([o + Vector2(-2, -14), o + Vector2(0, -11), o + Vector2(-1, -8), o + Vector2(1, -6)]), crack_col, 1.0)
	if n >= 2:
		draw_polyline(PackedVector2Array([h + Vector2(9, -18), h + Vector2(10, -15.5), h + Vector2(12, -14)]), crack_col, 1.0)
	if n >= 3:
		draw_polyline(PackedVector2Array([o + Vector2(-10, -12), o + Vector2(-7, -10), o + Vector2(-8, -7)]), crack_col, 1.0)
	if n >= 4:
		draw_polyline(PackedVector2Array([o + Vector2(4, -14), o + Vector2(5, -11), o + Vector2(3, -9)]), crack_col, 1.0)

	# 눈
	var e := h + Vector2(11, -16.5)
	if white:
		draw_rect(Rect2(e, Vector2(2.5, 1.5)), Color.WHITE)
	elif dormant:
		draw_line(e + Vector2(0, 1), e + Vector2(2.5, 1), CRACK, 1.0) # 감은 눈 (석상)
	elif stunned:
		draw_line(e + Vector2(0, -0.5), e + Vector2(2.5, 2), Palette.DANGER.darkened(0.3), 1.0)
		draw_line(e + Vector2(0, 2), e + Vector2(2.5, -0.5), Palette.DANGER.darkened(0.3), 1.0)
		for i in 3:
			var a := t * 6.0 + i * TAU / 3.0
			draw_rect(Rect2(h + Vector2(8 + cos(a) * 7.0, -29 + sin(a) * 2.0), Vector2(1.5, 1.5)), Palette.GOLD)
	else:
		var eye := Color(0.75, 0.25, 0.22)
		if waking:
			eye = eye if fmod(t, 0.16) < 0.08 else CRACK # 깜빡깜빡 켜짐
		elif danger > 0.0:
			eye = eye.lerp(Palette.DANGER, maxf(danger, 0.6)).lightened(0.25 * danger)
			draw_circle(e + Vector2(1.2, 0.7), 2.5 + 2.0 * danger, Color(Palette.DANGER, 0.25 + 0.25 * danger))
		draw_rect(Rect2(e, Vector2(2.5, 1.5)), eye)
		if danger > 0.0:
			draw_rect(Rect2(e + Vector2(1.5, 0), Vector2(1, 1)), Color(1, 0.9, 0.85))
			# 눈빛 꼬리 (뒤로 흐르는 붉은 선)
			var tail_len := 4.0 + 8.0 * danger
			draw_line(e + Vector2(0, 0.7), e + Vector2(-tail_len, 0.2), Color(Palette.DANGER, 0.6 * danger), 1.0)

	# 돌진 속도선
	if charging and not white:
		for i in 3:
			var y := -15.0 + i * 4.0
			var slen := 8.0 + fmod(t * 90.0 + i * 7.0, 10.0)
			draw_line(Vector2(-17 - slen, y), Vector2(-17, y), Color(STONE_LIGHT, 0.5), 1.0)
