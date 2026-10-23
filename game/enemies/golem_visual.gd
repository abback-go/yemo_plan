class_name GolemVisual
extends Node2D
## 훈련 골렘 그림: 돌 다리·돌 주먹에 나무통 몸통. 가슴엔 학생들이 쏘던 과녁(그을음·꽂힌 화살), 등엔 폭주 마력의 핵.
## 오른쪽을 보는 기준으로 그리고 scale.x로 뒤집는다. 위험 예고는 붉은 빛(주먹·발), 핵 노출은 밝은 보라.

const WOOD := Color("#6b4a32")
const WOOD_LIGHT := Color("#8a6444")
const WOOD_DARK := Color("#3e2a1e")
const STONE := Color("#6e6878")
const STONE_LIGHT := Color("#8e889a")
const STONE_DARK := Color("#45404f")
const METAL := Color("#34343f")
const METAL_LIGHT := Color("#5a5a6a")
const TARGET_CREAM := Color("#e8dcc0")
const TARGET_BLUE := Color("#2f4a7a")
const TARGET_GOLD := Color("#ffd27a")
const STRAW := Color("#c8a85a")

var enemy: TrainingGolem
var _walk := 0.0
var _white := false


func _process(delta: float) -> void:
	if enemy == null:
		return
	var sx := float(enemy.facing)
	if enemy.state == TrainingGolem.S.TURN:
		# 묵직하게 몸을 돌리는 중: 옆으로 납작해졌다가 반대로
		sx *= 1.0 - sin(enemy.progress() * PI) * 0.55
	scale.x = sx
	if absf(enemy.velocity.x) > 5.0 and enemy.state == TrainingGolem.S.WALK:
		_walk += delta * 6.0


func _col(c: Color) -> Color:
	return Color.WHITE if _white else c


## 어두운 외곽선이 있는 사각형
func _box(r: Rect2, fill: Color) -> void:
	draw_rect(r.grow(1.0), Palette.OUTLINE if not _white else Color(0.85, 0.85, 0.9))
	draw_rect(r, _col(fill))


func _draw() -> void:
	if enemy == null:
		return
	_white = enemy.flash_amount() > 0.0
	var st := enemy.state
	var k := enemy.progress()
	var ek := k * k * (3.0 - 2.0 * k) # 부드러운 진행도
	var t := enemy._t
	var o := Vector2.ZERO # 몸통·머리 오프셋
	var rest_front := Vector2(18, -24)
	var rest_back := Vector2(-16, -22)
	var front_fist := rest_front
	var back_fist := rest_back
	var front_glow := 0.0
	var back_glow := 0.0
	var foot_glow := 0.0
	var lift_front := 0.0
	var lift_back := 0.0
	var eye := TrainingGolem.MANA
	var back_in_front := false
	var dizzy := false

	match st:
		TrainingGolem.S.WALK:
			var s := sin(_walk)
			lift_front = maxf(s, 0.0) * 3.0
			lift_back = maxf(-s, 0.0) * 3.0
			o.y = -absf(s) * 1.0
			front_fist += Vector2(s * 3.0, 0)
			back_fist += Vector2(-s * 3.0, 0)
		TrainingGolem.S.IDLE, TrainingGolem.S.TURN:
			o.y = sin(t * 2.0) * 0.8
		TrainingGolem.S.PUNCH_WINDUP:
			front_fist = rest_front.lerp(Vector2(-4, -58), ek)
			front_glow = k
			o.x = -2.0 * ek
			eye = eye.lerp(Palette.DANGER, k)
			o += Vector2(randf_range(-0.6, 0.6), 0) * k
		TrainingGolem.S.PUNCH:
			front_fist = Vector2(38, -30)
			o.x = 3.0
			eye = Palette.DANGER
		TrainingGolem.S.PUNCH2_WINDUP:
			front_fist = Vector2(38, -30).lerp(Vector2(16, -26), ek)
			back_fist = rest_back.lerp(Vector2(-22, -56), ek)
			back_glow = k
			o.x = -1.0
			eye = Palette.DANGER
		TrainingGolem.S.PUNCH2:
			front_fist = Vector2(12, -24)
			back_fist = Vector2(40, -28)
			back_in_front = true
			o.x = 4.0
			eye = Palette.DANGER
		TrainingGolem.S.PUNCH_RECOVER:
			front_fist = Vector2(24, -10).lerp(rest_front, ek * 0.5)
			back_fist = Vector2(10, -10).lerp(rest_back, ek * 0.5)
			back_in_front = k < 0.5
			o.y = 3.0 * (1.0 - ek)
			eye = eye.darkened(0.4)
		TrainingGolem.S.SLAM_WINDUP:
			front_fist = rest_front.lerp(Vector2(8, -80), ek)
			back_fist = rest_back.lerp(Vector2(-4, -82), ek)
			front_glow = k
			back_glow = k
			o.y = -2.0 * ek
			eye = eye.lerp(Palette.DANGER, k)
			o += Vector2(randf_range(-1.0, 1.0), 0) * k
		TrainingGolem.S.SLAM, TrainingGolem.S.CORE_OPEN:
			front_fist = Vector2(32, -7)
			back_fist = Vector2(21, -7)
			o = Vector2(4, 5)
			if st == TrainingGolem.S.CORE_OPEN:
				o.y += sin(t * 5.0) * 0.6 # 헐떡임
				eye = TrainingGolem.MANA_DEEP.lerp(TrainingGolem.MANA, 0.5 + 0.5 * sin(t * 12.0))
		TrainingGolem.S.RECOVER:
			front_fist = Vector2(32, -7).lerp(rest_front, ek)
			back_fist = Vector2(21, -7).lerp(rest_back, ek)
			back_in_front = k < 0.5
			o = Vector2(4, 5).lerp(Vector2.ZERO, ek)
		TrainingGolem.S.STOMP_WINDUP:
			lift_front = 11.0 * ek
			foot_glow = k
			front_fist = rest_front + Vector2(-4, -8) * ek
			back_fist = rest_back + Vector2(0, -10) * ek
			o.y = -1.5 * ek
			eye = eye.lerp(Palette.DANGER, k)
		TrainingGolem.S.STOMP:
			o.y = 2.0
			front_fist = rest_front + Vector2(2, 4)
		TrainingGolem.S.STAGGER:
			o = Vector2(-4, 1)
			front_fist = Vector2(8, -52) + Vector2(sin(t * 30.0), cos(t * 26.0)) * 2.0
			back_fist = Vector2(-22, -48) + Vector2(cos(t * 28.0), sin(t * 24.0)) * 2.0
			eye = Color.WHITE if int(t * 20.0) % 2 == 0 else TrainingGolem.MANA
			dizzy = true

	# 발 구르기 예고: 바닥을 따라 붉은 금이 세라 쪽으로 번진다
	if foot_glow > 0.0 and not _white:
		var pulse := 0.5 + 0.5 * sin(t * 30.0)
		draw_rect(Rect2(4, -2, 10 + 46.0 * ek, 2), Color(Palette.DANGER, 0.35 + 0.4 * pulse * foot_glow))
		draw_circle(Vector2(9, 0), 6.0 + 6.0 * ek, Color(Palette.DANGER, 0.12 + 0.2 * foot_glow))
	# 뒷팔 (몸통 뒤)
	if not back_in_front:
		_arm(Vector2(-12, -44) + o, back_fist, back_glow, true)
	# 다리 (돌기둥)
	_leg(Rect2(-14, -16 - lift_back, 11, 16), 0.0)
	_leg(Rect2(3, -16 - lift_front, 11, 16), foot_glow)
	# 허리
	_box(Rect2(Vector2(-15, -21) + o * 0.5, Vector2(30, 6)), WOOD_DARK)
	# 몸통: 나무통
	var body := Rect2(Vector2(-18, -51) + o, Vector2(36, 32))
	_box(body, WOOD)
	if not _white:
		draw_rect(Rect2(body.position + Vector2(0, 0), Vector2(36, 3)), WOOD_LIGHT)
		for px: float in [-10.0, -2.0, 14.0]:
			draw_line(Vector2(px, -50) + o, Vector2(px, -20) + o, WOOD_DARK, 1.0)
	# 쇠테 두 줄
	_box(Rect2(Vector2(-18, -47) + o, Vector2(36, 3)), METAL)
	_box(Rect2(Vector2(-18, -25) + o, Vector2(36, 3)), METAL)
	if not _white:
		draw_rect(Rect2(Vector2(-18, -47) + o, Vector2(36, 1)), METAL_LIGHT)
		draw_rect(Rect2(Vector2(-18, -25) + o, Vector2(36, 1)), METAL_LIGHT)
	# 폭주 마력 금 (보라빛이 맥박친다)
	if not _white:
		var pulse := 0.45 + 0.35 * sin(t * 4.0)
		var mana := Color(TrainingGolem.MANA, pulse)
		draw_polyline(PackedVector2Array([Vector2(-16, -43) + o, Vector2(-12, -38) + o, Vector2(-14, -31) + o, Vector2(-10, -27) + o]), mana, 1.0)
		draw_polyline(PackedVector2Array([Vector2(16, -44) + o, Vector2(13, -41) + o, Vector2(16, -37) + o]), mana, 1.0)
	# 가슴의 과녁 (앞쪽으로 치우침) + 그을음 + 꽂힌 화살
	var tc := Vector2(5, -35) + o
	draw_circle(tc, 11.5, _col(Palette.OUTLINE))
	draw_circle(tc, 10.5, _col(TARGET_CREAM))
	draw_circle(tc, 8.0, _col(TARGET_BLUE))
	draw_circle(tc, 5.5, _col(TARGET_CREAM))
	draw_circle(tc, 3.0, _col(TARGET_GOLD))
	if not _white:
		draw_circle(tc + Vector2(-5, 4), 3.0, Color(0.1, 0.07, 0.06, 0.55)) # 세라의 화염탄 자국?
		draw_circle(tc + Vector2(6, -5), 2.0, Color(0.1, 0.07, 0.06, 0.45))
		for a: Vector2 in [Vector2(-3, -2), Vector2(4, 3)]:
			var base := tc + a
			draw_line(base, base + Vector2(6, -5), Color("#c8b89a"), 1.0)
			draw_rect(Rect2(base + Vector2(5, -7), Vector2(2, 2)), Color("#d8d0e0"))
	# 머리: 돌 블록 + 눈구멍 + 지푸라기
	var head := Rect2(Vector2(-9, -63) + o, Vector2(18, 12))
	_box(head, STONE)
	if not _white:
		draw_rect(Rect2(head.position, Vector2(18, 2)), STONE_LIGHT)
		draw_rect(Rect2(head.position + Vector2(0, 3), Vector2(18, 2)), STONE_DARK)
		for i in 4:
			var sx := -6.0 + i * 3.0
			draw_line(Vector2(sx, -63) + o, Vector2(sx - 1.5 + sin(t * 3.0 + i) * 1.0, -68) + o, STRAW, 1.0)
	# 눈 (예고 때 붉게)
	draw_rect(Rect2(Vector2(1, -58) + o, Vector2(7, 2)), _col(eye))
	if not _white:
		draw_rect(Rect2(Vector2(0, -59) + o, Vector2(9, 4)), Color(eye, 0.25))
	# 등의 핵
	_core(Vector2(-21, -35) + o)
	# 앞팔 (몸통 앞)
	if back_in_front:
		_arm(Vector2(-12, -44) + o, back_fist, back_glow, true)
	_arm(Vector2(12, -44) + o, front_fist, front_glow, false)
	# 주먹 지른 순간 속도선
	if (st == TrainingGolem.S.PUNCH or st == TrainingGolem.S.PUNCH2) and not _white:
		for i in 3:
			var y := -34.0 + i * 5.0
			draw_line(Vector2(6, y), Vector2(22, y), Color(1, 1, 1, 0.35), 1.0)
	# 휘청: 머리 위를 도는 별
	if dizzy:
		for i in 3:
			var a := t * 7.0 + i * TAU / 3.0
			draw_rect(Rect2(Vector2(cos(a) * 9.0, -72 + sin(a) * 2.5) + o, Vector2(2, 2)), Palette.GOLD)


func _leg(r: Rect2, glow: float) -> void:
	if glow > 0.0 and not _white:
		var pulse := 0.5 + 0.5 * sin(enemy._t * 40.0)
		draw_rect(r.grow(3.0), Color(Palette.DANGER, 0.25 + 0.45 * glow * pulse))
	_box(r, STONE_DARK)
	if not _white:
		draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), STONE)
		draw_rect(Rect2(r.position + Vector2(0, r.size.y - 3), Vector2(r.size.x + 2, 3)), STONE)


## 나무 팔 + 돌 주먹. glow > 0이면 붉은 예고 빛
func _arm(shoulder: Vector2, fist: Vector2, glow: float, is_back: bool) -> void:
	var wood := WOOD_DARK if is_back else WOOD
	draw_line(shoulder, fist, Palette.OUTLINE if not _white else Color(0.85, 0.85, 0.9), 7.0)
	draw_line(shoulder, fist, _col(wood), 5.0)
	var r := Rect2(fist - Vector2(6.5, 6), Vector2(13, 12))
	if glow > 0.0 and not _white:
		var pulse := 0.5 + 0.5 * sin(enemy._t * 40.0)
		draw_rect(r.grow(3.5), Color(Palette.DANGER, 0.2 + 0.5 * glow * pulse))
		draw_rect(r.grow(1.5), Color(Palette.DANGER, 0.35 * glow))
	_box(r, STONE_DARK if is_back else STONE)
	if not _white:
		draw_rect(Rect2(r.position, Vector2(13, 2)), STONE_LIGHT if not is_back else STONE)
		draw_line(r.position + Vector2(4, 3), r.position + Vector2(4, 8), STONE_DARK, 1.0)
		draw_line(r.position + Vector2(8, 3), r.position + Vector2(8, 8), STONE_DARK, 1.0)
		if glow > 0.6:
			draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(9, 3)), Color(1.0, 0.55, 0.45, glow))


## 등의 핵: 쇠 틀 안의 마력 수정. 내려찍은 뒤 2초간 덮개가 열리고 밝게 빛난다
func _core(c: Vector2) -> void:
	var g := enemy.core_glow
	var t := enemy._t
	if not _white:
		var halo := 6.0 + 9.0 * g + sin(t * 10.0) * 1.5 * g
		draw_circle(c, halo, Color(TrainingGolem.MANA, 0.12 + 0.3 * g))
		draw_circle(c, halo * 0.6, Color(TrainingGolem.MANA.lightened(0.3), 0.15 + 0.35 * g))
	_box(Rect2(c + Vector2(-4, -8), Vector2(6, 16)), METAL)
	var crystal := TrainingGolem.MANA_DEEP.lerp(TrainingGolem.MANA, 0.5 + 0.2 * sin(t * 3.0)).lerp(Color(1.0, 0.92, 1.0), g * (0.6 + 0.4 * sin(t * 18.0)))
	var sz := 4.0 + g * 1.5
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-1, -sz - 1), c + Vector2(-1 + sz * 0.7, 0), c + Vector2(-1, sz + 1), c + Vector2(-1 - sz * 0.7, 0),
	]), _col(crystal))
	if g > 0.05 and not _white:
		# 열린 덮개
		draw_rect(Rect2(c + Vector2(-9 - 3 * g, -10), Vector2(3, 6)), METAL_LIGHT)
		draw_rect(Rect2(c + Vector2(-9 - 3 * g, 4), Vector2(3, 6)), METAL_LIGHT)
		# 빛살
		for i in 4:
			var a := t * 2.0 + i * TAU / 4.0
			var d := Vector2(cos(a), sin(a))
			draw_line(c + d * 5.0, c + d * (10.0 + 8.0 * g), Color(1.0, 0.9, 1.0, 0.6 * g), 1.0)
