class_name BroomVisual
extends Node2D
## 폭주 빗자루 그림: 나무 손잡이 + 보라 마력이 새는 묶음 띠 + 성난 두 눈이 달린 지푸라기 솔.
## 손잡이 끝이 +x를 보는 기준으로 그리고, 노드 회전·위아래 뒤집기로 방향을 맞춘다(눈은 늘 위쪽).
## 예고: 솔이 곤두서고 끝이 붉어지며 조준 점선(고정되면 흰색 깜빡임). 박힘: 손잡이 윗면이 밝게(밟을 수 있음).

const WOOD := Color("#9a6a3a")
const WOOD_LIGHT := Color("#c8925a")
const WOOD_DARK := Color("#5a3a20")
const STRAW := Color("#e6c56c")
const STRAW_MID := Color("#c9a24e")
const STRAW_DARK := Color("#9c7a36")
const BAND := Color("#4a2a6a")

var enemy: RunawayBroom
var _white := false


func _process(_delta: float) -> void:
	if enemy == null:
		return
	position = Vector2(0, -6)
	z_index = 2
	var st := enemy.state
	var dir := Vector2(enemy.facing, 0)
	var spin := 0.0
	if enemy._airborne_spin != 0.0:
		spin = enemy._airborne_spin * enemy._t * 12.0
	elif st == RunawayBroom.S.BONK:
		spin = enemy._t * 16.0 * enemy.facing
	elif st == RunawayBroom.S.WINDUP or st == RunawayBroom.S.SWOOP or st == RunawayBroom.S.STUCK:
		dir = enemy.aim
	else:
		dir = Vector2(enemy.facing, clampf(enemy.velocity.y / 500.0, -0.35, 0.35) + sin(enemy._t * 7.0) * 0.12)
	if spin != 0.0:
		rotation = spin
		scale = Vector2(1, -1) if enemy.facing < 0 else Vector2.ONE
	else:
		rotation = dir.angle()
		scale = Vector2(1, -1) if dir.x < 0.0 else Vector2.ONE


func _col(c: Color) -> Color:
	return Color.WHITE if _white else c


func _draw() -> void:
	if enemy == null:
		return
	_white = enemy.flash_amount() > 0.0
	var st := enemy.state
	var t := enemy._t
	var k := enemy.progress()
	var outline := Palette.OUTLINE if not _white else Color(0.85, 0.85, 0.9)
	var windup := st == RunawayBroom.S.WINDUP
	var stuck := st == RunawayBroom.S.STUCK
	var shake := Vector2.ZERO
	if windup:
		shake = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * (0.4 + k)
	elif stuck:
		shake = Vector2(0, sin(t * 60.0) * 0.8)

	# 조준 점선: 추적 중 붉게, 고정되면 흰색 깜빡임
	if windup and not _white:
		var locked := enemy.is_locked()
		var blink := int(t * 30.0) % 2 == 0
		var c := Color(1, 1, 1, 0.9 if blink else 0.45) if locked else Color(Palette.DANGER, 0.25 + 0.5 * k)
		var reach := 24.0 + 70.0 * minf(k * 1.4, 1.0)
		var x := 24.0
		while x < reach:
			draw_line(Vector2(x, 0), Vector2(minf(x + 5.0, reach), 0), c, 1.0)
			x += 9.0
	# 급강하 속도선
	if st == RunawayBroom.S.SWOOP and not _white:
		for i in 3:
			var y := -4.0 + i * 4.0
			var slen := 10.0 + fmod(t * 120.0 + i * 7.0, 12.0)
			draw_line(Vector2(-26 - slen, y), Vector2(-24, y), Color(1, 1, 1, 0.35), 1.0)

	# ── 솔 (지푸라기) ──
	var h0 := 4.0
	var h1 := 8.0
	var flap := 0.0
	if windup:
		h1 = 8.0 + 7.0 * minf(k * 1.5, 1.0) # 곤두선다
		flap = sin(t * 70.0) * 1.0
	elif stuck:
		flap = sin(t * 38.0) * 4.0 # 버둥버둥
		h1 = 9.0 + sin(t * 24.0) * 2.5
	elif st == RunawayBroom.S.SWOOP:
		h1 = 6.0 # 바람에 눌림
	else:
		flap = sin(t * 9.0) * 1.2
	var bx0 := -8.0
	var bx1 := -28.0
	var tip_y := flap
	var mass := PackedVector2Array([
		shake + Vector2(bx0, -h0), shake + Vector2(bx1, -h1 + tip_y), shake + Vector2(bx1 - 2.0, tip_y),
		shake + Vector2(bx1, h1 + tip_y), shake + Vector2(bx0, h0),
	])
	var mass_out := PackedVector2Array()
	for pt in mass:
		mass_out.append(pt + (pt - shake - Vector2(-18, tip_y * 0.5)).normalized() * 1.3)
	draw_colored_polygon(mass_out, outline)
	draw_colored_polygon(mass, _col(STRAW_MID))
	# 지푸라기 결
	for i in 7:
		var f := (float(i) / 6.0) * 2.0 - 1.0
		var a := shake + Vector2(bx0 - 1.0, f * h0 * 0.8)
		var b := shake + Vector2(bx1 + 1.0 - absf(f) * 1.5, f * h1 * 0.9 + tip_y)
		var c2 := STRAW if i % 2 == 0 else STRAW_DARK
		if windup:
			c2 = c2.lerp(Palette.DANGER, clampf(k * 1.3 - 0.2, 0.0, 1.0) * (0.5 + 0.5 * absf(f)))
		draw_line(a, b, _col(c2), 1.0)
	# 솔 끝이 붉게 (예고)
	if windup and not _white:
		draw_line(shake + Vector2(bx1, -h1 + tip_y), shake + Vector2(bx1, h1 + tip_y), Color(Palette.DANGER, 0.5 + 0.5 * k), 2.0)

	# ── 눈 (솔 덩어리 위) ──
	var ey := -2.0 + shake.y
	var e1 := shake + Vector2(-20, ey)
	var e2 := shake + Vector2(-14, ey)
	if st == RunawayBroom.S.BONK or enemy._airborne_spin != 0.0:
		for e in [e1, e2]:
			var ev: Vector2 = e
			draw_line(ev + Vector2(-1.5, -1.5), ev + Vector2(1.5, 1.5), _col(Palette.OUTLINE), 1.0)
			draw_line(ev + Vector2(-1.5, 1.5), ev + Vector2(1.5, -1.5), _col(Palette.OUTLINE), 1.0)
	elif stuck:
		# > < 꽉 감은 눈 (버둥버둥)
		draw_polyline(PackedVector2Array([e1 + Vector2(-1.5, -1.5), e1 + Vector2(1, 0), e1 + Vector2(-1.5, 1.5)]), _col(Palette.OUTLINE), 1.0)
		draw_polyline(PackedVector2Array([e2 + Vector2(1.5, -1.5), e2 + Vector2(-1, 0), e2 + Vector2(1.5, 1.5)]), _col(Palette.OUTLINE), 1.0)
	else:
		var iris := RunawayBroom.MANA if not windup else Palette.DANGER
		for e in [e1, e2]:
			var ev2: Vector2 = e
			draw_rect(Rect2(ev2 + Vector2(-2.5, -2.5), Vector2(5, 5)), _col(Palette.OUTLINE))
			draw_rect(Rect2(ev2 + Vector2(-1.5, -1.5), Vector2(3, 3)), _col(Color("#f4ecdc")))
			draw_rect(Rect2(ev2 + Vector2(0, -1), Vector2(1.5, 2.5)), _col(iris))
		# 성난 눈썹
		draw_line(e1 + Vector2(-3, -4.5), e1 + Vector2(2.5, -2.5), _col(Palette.OUTLINE), 1.5)
		draw_line(e2 + Vector2(3, -4.5), e2 + Vector2(-2.5, -2.5), _col(Palette.OUTLINE), 1.5)

	# ── 손잡이 ──
	var tip := 20.0 if not stuck else 23.0 # 박히면 끝이 벽 속으로
	var hs := shake * 0.5
	if windup and not _white:
		draw_line(hs + Vector2(-6, 0), hs + Vector2(tip, 0), Color(Palette.DANGER, 0.25 + 0.3 * k * (0.6 + 0.4 * sin(t * 40.0))), 8.0)
	draw_line(hs + Vector2(-6, 0), hs + Vector2(tip + 1.0, 0), outline, 6.0)
	draw_line(hs + Vector2(-6, 0), hs + Vector2(tip, 0), _col(WOOD), 4.0)
	if not _white:
		draw_line(hs + Vector2(-5, -1.5), hs + Vector2(tip - 1.0, -1.5), WOOD_LIGHT if not stuck else Color("#ffe8b0"), 1.0)
		draw_line(hs + Vector2(-5, 1.5), hs + Vector2(tip - 1.0, 1.5), WOOD_DARK, 1.0)
		draw_rect(Rect2(hs + Vector2(tip - 1.0, -2), Vector2(2, 4)), WOOD_DARK)
	# ── 묶음 띠: 폭주 마력이 새는 룬 ──
	var band := Rect2(shake + Vector2(-10, -5), Vector2(5, 10))
	draw_rect(band.grow(1.0), outline)
	draw_rect(band, _col(BAND))
	if not _white:
		var glow := 0.5 + 0.4 * sin(t * 6.0)
		draw_rect(Rect2(band.position + Vector2(1, 2), Vector2(3, 1)), Color(RunawayBroom.MANA, glow))
		draw_rect(Rect2(band.position + Vector2(1, 5), Vector2(3, 1)), Color(RunawayBroom.MANA, glow))
		draw_circle(band.get_center(), 6.0, Color(RunawayBroom.MANA, 0.08 + 0.06 * glow))
	# 박힘: 머리 위 땀방울 (버둥버둥)
	if stuck and not _white:
		for i in 2:
			var ph := fmod(t * 3.0 + i * 0.5, 1.0)
			draw_rect(Rect2(Vector2(-18 + i * 7, -10 - ph * 5.0), Vector2(1.5, 2)), Color(0.7, 0.85, 1.0, 1.0 - ph))
	# 어질어질 별
	if st == RunawayBroom.S.BONK:
		for i in 3:
			var a := t * 7.0 + i * TAU / 3.0
			draw_rect(Rect2(Vector2(-12 + cos(a) * 7.0, -9 + sin(a) * 2.0), Vector2(1.5, 1.5)), Palette.GOLD)
