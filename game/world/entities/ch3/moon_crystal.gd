class_name MoonCrystal
extends Brazier
## 달빛 수정 (달샘 퍼즐). 봉화와 같은 규칙(group·puzzle mode = all → done_flag)이지만 **되쏜 달빛(Hit.kind = reflect)**에만 켜진다.
## 매달린 수정(원점 = 천장)이며, 켜지면 은빛으로 빛나며 천천히 돈다.
## 방 데이터: {t = "moon_crystal", x, y, group, done_flag}

const MOON := Color(0.82, 0.92, 1.0)


func setup(room: Room, e: Dictionary, eid: String) -> void:
	super(room, e, eid)
	remove_from_group(&"pillar_target") # 불기둥이 노리지 않게 (달빛만 통함)
	_glow.modulate = Color(MOON, 0.0)
	_glow.position = Vector2(0, 14)
	_glow.scale = Vector2.ONE * 80.0 / 32.0
	# 판정 상자를 수정 자리(천장 아래)로
	var cs := _hurt.get_child(0) as CollisionShape2D
	if cs:
		cs.position = Vector2(0, 14)


func is_on_floor() -> bool:
	return false


func take_hit(hit: Hit) -> void:
	if lit:
		return
	if hit.kind != &"reflect":
		if hit.kind != &"ally":
			_fail = 0.3
			Sfx.play(&"block", -8.0, 0.1)
		return
	set_lit(true)


func set_lit(v: bool, quiet := false) -> void:
	if lit == v:
		return
	lit = v
	if lit and not quiet:
		Ch3Sfx.play(&"ch3_purify", -2.0, 0.0)
		Fx.burst(global_position + Vector2(0, 14), 20, {spread = 180.0, speed_min = 20.0, speed_max = 70.0, lifetime = 0.8,
			gradient = Palette.fade_gradient(MOON), gravity = Vector2(0, 20), add = true})
	lit_changed.emit(self)


func _process(delta: float) -> void:
	_t += delta
	_fail = maxf(_fail - delta, 0.0)
	_glow.base_alpha = 0.7 if lit else 0.0
	queue_redraw()


func _draw() -> void:
	draw_line(Vector2.ZERO, Vector2(0, 7), Color("#8a7a5a"), 1.0)
	var c := Vector2(0, 14)
	var rot := _t * (0.8 if lit else 0.15)
	var col := MOON if lit else Color("#5a6a7a")
	var pts := PackedVector2Array()
	for i in 6:
		var a := rot + TAU * i / 6.0
		var r := 7.0 if i % 2 == 0 else 4.0
		pts.append(c + Vector2(cos(a) * r * 0.7, sin(a) * r))
	draw_colored_polygon(pts, col)
	draw_line(c + Vector2(0, -7), c + Vector2(0, 7), Color(1, 1, 1, 0.7 if lit else 0.2), 1.0)
	if lit:
		draw_circle(c, 10.0, Color(MOON, 0.12 + 0.05 * sin(_t * 3.0)))
	if _fail > 0.0:
		draw_circle(c, 9.0, Color(1.0, 0.3, 0.3, _fail * 0.6))
