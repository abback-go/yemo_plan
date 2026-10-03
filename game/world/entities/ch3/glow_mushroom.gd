class_name GlowMushroom
extends Brazier
## 빛버섯 (뿌리 동굴 퍼즐, docs/chapter3.md 7.3절). 봉화(Brazier)와 같은 규칙: 불에 맞으면 켜지고, 1장 퍼즐 처리기
## (entity "puzzle", mode = all/order)가 같은 group을 본다 — order면 정해진 순서(크기 순)로 밝혀야 한다.
## 켜지면 청록 빛이 어두운 동굴을 넓게 밝힌다(가산 빛, 방 dark 값을 이긴다).
## 방 데이터: {t = "glow_mushroom", x, y, group, order, size = 1.0(크기), done_flag}

const MUSH := Color("#5affd0")

var size := 1.0


func setup(room: Room, e: Dictionary, eid: String) -> void:
	super(room, e, eid)
	size = float(e.get("size", 1.0))
	_glow.modulate = Color(MUSH, 0.0)
	_glow.scale = Vector2.ONE * (110.0 * size) / 32.0
	_glow.position = Vector2(0, -12 * size)


func set_lit(v: bool, quiet := false) -> void:
	if lit == v:
		return
	lit = v
	if lit and not quiet:
		Sfx.play(&"ignite", -4.0, 0.05)
		Ch3Sfx.play(&"ch3_purify", -8.0, 0.1)
		Fx.burst(global_position + Vector2(0, -14 * size), 18, {direction = Vector2.UP, spread = 80.0, speed_min = 20.0,
			speed_max = 60.0, lifetime = 0.9, gradient = Palette.fade_gradient(MUSH), gravity = Vector2(0, -30), add = true})
	lit_changed.emit(self)


func _process(delta: float) -> void:
	_t += delta
	_fail = maxf(_fail - delta, 0.0)
	_glow.base_alpha = (0.75 if lit else 0.08)
	queue_redraw()


func _draw() -> void:
	var s := size
	var g := 0.85 + 0.15 * sin(_t * 1.6 + order)
	var cap_col := Color("#1a5a50").lerp(MUSH, 0.45 * g) if lit else Color("#22403a")
	# 대
	draw_rect(Rect2(-2 * s, -12 * s, 4 * s, 12 * s), Color("#a8c8b8").darkened(0.35 if lit else 0.55))
	draw_rect(Rect2(-2 * s, -12 * s, 1, 12 * s), Color("#c8e8d8").darkened(0.2 if lit else 0.5))
	# 갓
	var cap := PackedVector2Array()
	for i in 11:
		var a := PI + PI * i / 10.0
		cap.append(Vector2(cos(a) * 10.0 * s, -12 * s + sin(a) * 7.0 * s))
	draw_colored_polygon(cap, cap_col)
	# 주름 (켜지면 밝게)
	draw_line(Vector2(-9 * s, -12 * s), Vector2(9 * s, -12 * s), Color(MUSH, 0.95 if lit else 0.2), maxf(1.0, s))
	for i in 4:
		var a2 := PI + PI * (i + 0.5) / 4.0
		draw_circle(Vector2(cos(a2) * 6.0 * s, -12 * s + sin(a2) * 4.0 * s), 1.2 * s, Color(MUSH, 0.8 * g if lit else 0.15))
	if _fail > 0.0:
		draw_line(Vector2(-9 * s, -12 * s), Vector2(9 * s, -12 * s), Color(1.0, 0.25, 0.25, _fail), 2.0)
	if lit:
		for i in 3:
			var k := fmod(_t * 0.3 + i / 3.0, 1.0)
			draw_rect(Rect2(-6 * s + i * 6 * s + sin(k * 6.0 + i) * 2.0, -12 * s - k * 22.0, 1, 1), Color(MUSH, 0.8 * (1.0 - k)))
