class_name ArmorKnightVisual
extends Node2D
## 갑옷 수호기사 그림: 속이 빈 강철 갑옷(투구 틈·관절에서 보라 마력이 샌다) + 학교 문장이 박힌 탑 방패 + 긴 검.
## 오른쪽을 보는 기준으로 그리고 scale.x로 뒤집는다. 예고는 붉은 빛(방패 테두리·검날·방패 윗변), 방패가 깨지면 금 간 조각.

const STEEL := Color("#5a6178")
const STEEL_LIGHT := Color("#8a93b0")
const STEEL_DARK := Color("#343a4e")
const LEATHER := Color("#4a2e2a")
const PLUME := Color("#6a2e7a")
const SHIELD_FACE := Color("#2e3a5e")
const SHIELD_RIM := Color("#b08a4a")
const CREST := Color("#ffd27a")
const BLADE := Color("#c8d0e0")

var enemy: ArmorKnight
var _walk := 0.0
var _white := false


func _process(delta: float) -> void:
	if enemy == null:
		return
	var sx := float(enemy.facing)
	if enemy.state == ArmorKnight.S.TURN:
		sx *= 1.0 - sin(enemy.progress() * PI) * 0.5
	scale.x = sx
	rotation = enemy._airborne_spin * enemy._t * 8.0 if enemy._airborne_spin != 0.0 else 0.0
	if enemy.state == ArmorKnight.S.ADVANCE and absf(enemy.velocity.x) > 5.0:
		_walk += delta * 9.0


func _col(c: Color) -> Color:
	return Color.WHITE if _white else c


func _box(r: Rect2, fill: Color) -> void:
	draw_rect(r.grow(1.0), Palette.OUTLINE if not _white else Color(0.85, 0.85, 0.9))
	draw_rect(r, _col(fill))


func _draw() -> void:
	if enemy == null:
		return
	_white = enemy.flash_amount() > 0.0
	var st := enemy.state
	var k := enemy.progress()
	var ek := k * k * (3.0 - 2.0 * k)
	var t := enemy._t
	var o := Vector2.ZERO # 몸 오프셋 (웅크림·흔들림)
	var lift_f := 0.0
	var lift_b := 0.0
	var visor := ArmorKnight.MANA
	# 검: 손잡이 위치와 날 방향
	var hilt := Vector2(-7, -20)
	var blade_dir := Vector2(0.15, 1.0).normalized()
	var blade_len := 20.0
	var sword_front := false
	var sword_glow := 0.0
	# 방패: 앞(세움) / 위(올림)
	var shield_off := Vector2.ZERO
	var shield_glow := 0.0
	var top_glow := 0.0

	match st:
		ArmorKnight.S.ADVANCE:
			var s := sin(_walk)
			lift_f = maxf(s, 0.0) * 2.0
			lift_b = maxf(-s, 0.0) * 2.0
			o.y = -absf(s) * 0.8
		ArmorKnight.S.IDLE, ArmorKnight.S.TURN:
			o.y = sin(t * 2.0) * 0.5
		ArmorKnight.S.BASH_WINDUP:
			o = Vector2(-2.0 * ek, 2.0 * ek) + Vector2(randf_range(-0.5, 0.5), 0) * k
			shield_off = Vector2(-2.0 * ek, 0)
			shield_glow = k
			visor = visor.lerp(Palette.DANGER, k)
		ArmorKnight.S.BASH:
			o = Vector2(2, 1)
			shield_off = Vector2(5, 0)
			visor = Palette.DANGER
		ArmorKnight.S.BASH_RECOVER:
			shield_off = Vector2(5, 0).lerp(Vector2.ZERO, ek)
		ArmorKnight.S.SLAM_WINDUP:
			hilt = Vector2(-7, -20).lerp(Vector2(-3, -50), ek)
			blade_dir = Vector2(0.15, 1.0).normalized().slerp(Vector2(-0.45, -1.0).normalized(), ek)
			sword_glow = k
			o = Vector2(-1.5 * ek, -1.0 * ek) + Vector2(randf_range(-0.5, 0.5), 0) * k
			visor = visor.lerp(Palette.DANGER, k)
		ArmorKnight.S.SLAM:
			hilt = Vector2(16, -22)
			blade_dir = Vector2(1.0, 0.75).normalized()
			blade_len = 24.0
			sword_front = true
			o = Vector2(3, 2)
			visor = Palette.DANGER
		ArmorKnight.S.SLAM_RECOVER:
			hilt = Vector2(16, -14)
			blade_dir = Vector2(0.9, 1.0).normalized()
			blade_len = 22.0
			sword_front = true
			o = Vector2(3, 3) * (1.0 - ek * 0.5)
		ArmorKnight.S.AA_WINDUP:
			o = Vector2(0, 3.0 * ek)
			top_glow = k
			visor = visor.lerp(Palette.DANGER, k)
		ArmorKnight.S.AA_THRUST:
			o = Vector2(0, -2)
			visor = Palette.DANGER
		ArmorKnight.S.STAGGER:
			o = Vector2(-3, 1) + Vector2(sin(t * 40.0), 0) * 1.0

	var raised := enemy.shield_raised()
	var broken := enemy.shield_broken > 0.0

	# 뒤쪽 검 (몸 뒤)
	if not sword_front:
		_sword(hilt + o, blade_dir, blade_len, sword_glow)
		_arm(Vector2(-5, -31) + o, hilt + o)
	# 다리 (정강이받이 + 쇠장화)
	_leg(Vector2(-7, 0), lift_b, true)
	# 몸통
	var chest := Rect2(Vector2(-8, -34) + o, Vector2(16, 19))
	_box(chest, STEEL)
	if not _white:
		draw_rect(Rect2(chest.position, Vector2(16, 2)), STEEL_LIGHT)
		draw_rect(Rect2(chest.position + Vector2(10, 2), Vector2(3, 14)), STEEL_LIGHT.darkened(0.15))
		draw_line(chest.position + Vector2(4, 4), chest.position + Vector2(4, 16), STEEL_DARK, 1.0)
	# 허리띠 + 금 버클
	_box(Rect2(Vector2(-8, -17) + o, Vector2(16, 3)), LEATHER)
	if not _white:
		draw_rect(Rect2(Vector2(1, -17) + o, Vector2(3, 3)), CREST)
	# 치마 갑옷
	_box(Rect2(Vector2(-8, -14) + o * 0.5, Vector2(16, 4)), STEEL_DARK)
	# 빈 갑옷 속: 목 틈의 보라 마력
	if not _white:
		draw_rect(Rect2(Vector2(-4, -36) + o, Vector2(8, 2)), Color(ArmorKnight.MANA, 0.6 + 0.3 * sin(t * 5.0)))
	# 어깨받이
	_box(Rect2(Vector2(-11, -35) + o, Vector2(7, 5)), STEEL_LIGHT)
	# 투구
	var helm := Rect2(Vector2(-6, -47) + o, Vector2(13, 12))
	_box(helm, STEEL)
	if not _white:
		draw_rect(Rect2(helm.position, Vector2(13, 2)), STEEL_LIGHT)
		draw_rect(Rect2(helm.position + Vector2(0, 9), Vector2(13, 3)), STEEL_DARK)
	# 투구 틈 (눈빛)
	draw_rect(Rect2(Vector2(1, -42) + o, Vector2(6, 2)), _col(visor))
	if not _white:
		draw_rect(Rect2(Vector2(0, -43) + o, Vector2(8, 4)), Color(visor, 0.3))
	# 깃털 장식 (뒤로 흩날림)
	var sway := sin(t * 3.0) * 1.5
	var plume := PackedVector2Array([
		Vector2(0, -47) + o, Vector2(-4, -52) + o, Vector2(-10, -51 + sway) + o, Vector2(-15, -46 + sway) + o,
	])
	draw_polyline(plume, Palette.OUTLINE if not _white else Color(0.85, 0.85, 0.9), 5.0)
	draw_polyline(plume, _col(PLUME), 3.0)
	# 앞다리
	_leg(Vector2(1, 0), lift_f, false)
	# 방패
	if broken:
		_broken_shield(o)
	elif raised:
		_raised_shield(o, top_glow)
	else:
		_front_shield(o + shield_off, shield_glow)
	# 앞쪽 검 (내려벤 뒤)
	if sword_front:
		_arm(Vector2(-3, -31) + o, hilt + o)
		_sword(hilt + o, blade_dir, blade_len, 0.0)
	# 휘청
	if st == ArmorKnight.S.STAGGER and not _white:
		for i in 3:
			var a := t * 7.0 + i * TAU / 3.0
			draw_rect(Rect2(Vector2(cos(a) * 8.0, -54 + sin(a) * 2.0) + o, Vector2(2, 2)), Palette.GOLD)


func _leg(at: Vector2, lift: float, is_back: bool) -> void:
	var c := STEEL_DARK if is_back else STEEL
	_box(Rect2(at + Vector2(0, -13 - lift), Vector2(5, 10)), c)
	_box(Rect2(at + Vector2(-1, -4 - lift), Vector2(7, 4)), STEEL_DARK if is_back else STEEL_LIGHT.darkened(0.2))


func _arm(shoulder: Vector2, hand: Vector2) -> void:
	draw_line(shoulder, hand, Palette.OUTLINE if not _white else Color(0.85, 0.85, 0.9), 5.0)
	draw_line(shoulder, hand, _col(STEEL_DARK), 3.0)


func _sword(hilt: Vector2, dir: Vector2, length: float, glow: float) -> void:
	var tip := hilt + dir * length
	var side := Vector2(-dir.y, dir.x)
	if glow > 0.0 and not _white:
		var pulse := 0.5 + 0.5 * sin(enemy._t * 40.0)
		draw_line(hilt, tip, Color(Palette.DANGER, 0.25 + 0.5 * glow * pulse), 6.0)
	draw_line(hilt, tip, Palette.OUTLINE if not _white else Color(0.85, 0.85, 0.9), 4.0)
	draw_line(hilt, tip, _col(BLADE), 2.0)
	if not _white:
		draw_line(hilt + dir * 2.0, tip - dir * 2.0, Color(1, 1, 1, 0.6), 1.0)
		if glow > 0.6:
			draw_circle(tip, 2.0 + glow, Color(1.0, 0.6, 0.55, glow)) # 칼끝 번쩍
	# 손잡이·코등이
	draw_line(hilt - side * 3.0, hilt + side * 3.0, _col(CREST), 2.0)
	draw_line(hilt, hilt - dir * 4.0, _col(LEATHER), 2.0)


## 세운 탑 방패: 남색 면 + 금테 + 학교 문장(초승달과 별)
func _front_shield(o: Vector2, glow: float) -> void:
	var r := Rect2(Vector2(8, -38) + o, Vector2(9, 36))
	if glow > 0.0 and not _white:
		var pulse := 0.5 + 0.5 * sin(enemy._t * 40.0)
		draw_rect(r.grow(4.0), Color(Palette.DANGER, 0.2 + 0.5 * glow * pulse))
		draw_rect(r.grow(2.0), Color(Palette.DANGER, 0.3 + 0.4 * glow))
	draw_rect(r.grow(1.0), Palette.OUTLINE if not _white else Color(0.85, 0.85, 0.9))
	var rim := SHIELD_RIM.lerp(Palette.DANGER, glow * 0.8)
	if enemy.shield_flash > 0.0:
		rim = Color.WHITE
	draw_rect(r, _col(rim))
	draw_rect(r.grow(-1.5), _col(SHIELD_FACE))
	if not _white:
		draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(1, 32)), SHIELD_FACE.lightened(0.2))
		var c := r.get_center() + Vector2(0.5, -3)
		draw_circle(c, 3.0, CREST)
		draw_circle(c + Vector2(1.2, -0.6), 2.4, SHIELD_FACE)
		draw_rect(Rect2(c + Vector2(-0.5, 5), Vector2(1, 3)), CREST)
		draw_rect(Rect2(c + Vector2(-1.5, 6), Vector2(3, 1)), CREST)
		if enemy.shield_flash > 0.0:
			draw_rect(r.grow(2.0), Color(1, 1, 1, 0.35))


## 머리 위로 든 방패 (이때 정면이 열린다)
func _raised_shield(o: Vector2, glow: float) -> void:
	var lift := -4.0 if enemy.state == ArmorKnight.S.AA_THRUST else 0.0
	var r := Rect2(Vector2(-12, -58 + lift) + o, Vector2(30, 8))
	_arm(Vector2(3, -32) + o, Vector2(3, -50 + lift) + o)
	if glow > 0.0 and not _white:
		var pulse := 0.5 + 0.5 * sin(enemy._t * 40.0)
		draw_rect(Rect2(r.position + Vector2(-2, -4), Vector2(r.size.x + 4, 5)), Color(Palette.DANGER, 0.25 + 0.55 * glow * pulse))
	draw_rect(r.grow(1.0), Palette.OUTLINE if not _white else Color(0.85, 0.85, 0.9))
	draw_rect(r, _col(SHIELD_RIM))
	draw_rect(r.grow(-1.5), _col(SHIELD_FACE))
	if enemy.state == ArmorKnight.S.AA_THRUST and not _white:
		for i in 3:
			var x := -8.0 + i * 10.0
			draw_line(Vector2(x, -62 + lift) + o, Vector2(x, -70 + lift) + o, Color(1, 1, 1, 0.5), 1.0)


## 깨진 방패: 아래쪽 반만 남고 금이 갔다. 조각이 둘레를 떠돌다 다시 붙는다
func _broken_shield(o: Vector2) -> void:
	var left := enemy.shield_broken
	var r := Rect2(Vector2(8, -18) + o, Vector2(9, 16))
	draw_rect(r.grow(1.0), Palette.OUTLINE if not _white else Color(0.85, 0.85, 0.9))
	draw_rect(r, _col(SHIELD_RIM.darkened(0.3)))
	draw_rect(r.grow(-1.5), _col(SHIELD_FACE.darkened(0.2)))
	if _white:
		return
	draw_polyline(PackedVector2Array([r.position + Vector2(2, 0), r.position + Vector2(5, 5), r.position + Vector2(3, 9), r.position + Vector2(7, 14)]),
		Color(0.55, 0.85, 1.0, 0.9), 1.0)
	# 떠도는 조각: 남은 시간이 줄수록 방패 자리로 모인다
	var gather := clampf(1.0 - left / 1.0, 0.0, 1.0)
	for i in 4:
		var a := enemy._t * 2.0 + i * TAU / 4.0
		var home := Vector2(12.5, -32 + i * 4.0) + o
		var orbit := home + Vector2(cos(a) * 10.0, sin(a) * 6.0)
		var p := orbit.lerp(home, gather)
		draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 3)), SHIELD_FACE.lightened(0.15))
		draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 1)), SHIELD_RIM)
	if gather > 0.0:
		draw_rect(Rect2(Vector2(7, -39) + o, Vector2(11, 38)), Color(ArmorKnight.MANA, 0.25 * gather))
