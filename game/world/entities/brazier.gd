class_name Brazier
extends Node2D
## 봉화(화로): 불 공격(화염탄·불기둥·화염 폭풍·여우불·폭주 폭발)에 맞으면 켜진다.
## group이 같은 봉화들은 퍼즐 하나 — 모두 켜지면 room 쪽 퍼즐 처리기(BrazierPuzzle)가 플래그를 세운다.
## order가 있으면 순서 퍼즐: 틀린 순서로 켜면 그룹 전체가 꺼진다.

signal lit_changed(b: Brazier)

var bz_id := ""
var group := ""
var order := 0
var lit := false
var style := "stone" ## stone(신계 봉화) · iron(학교 화로) · seal(봉인 촛대)
var symbol := "" ## 받침에 새긴 문양 (순서 퍼즐 단서와 맞춰 봄): moon · fox · flame · star
var _hurt: Area2D
var _glow: LightGlow
var _t := 0.0
var _fail := 0.0


func setup(room: Room, e: Dictionary, eid: String) -> void:
	bz_id = eid
	group = String(e.get("group", ""))
	order = int(e.get("order", 0))
	style = String(e.get("style", "stone"))
	symbol = String(e.get("symbol", ""))
	position = room.tile_pos(e) + Vector2(8, 0)
	add_to_group(&"brazier")
	add_to_group(&"pillar_target")
	var done_flag := String(e.get("done_flag", ""))
	if done_flag != "" and GameState.has_flag(done_flag):
		lit = true
	_hurt = Area2D.new()
	_hurt.collision_layer = GameConst.L_ENEMY_HURT
	_hurt.collision_mask = 0
	_hurt.monitoring = false
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(16, 26)
	cs.shape = rs
	cs.position = Vector2(0, -13)
	_hurt.add_child(cs)
	add_child(_hurt)
	var col := Color(0.6, 0.85, 1.0) if style == "seal" else Color(1.0, 0.6, 0.3)
	_glow = LightGlow.make(Vector2(0, -24), 60.0, col, 0.0)
	add_child(_glow)


func is_alive() -> bool:
	return not lit


func is_on_floor() -> bool:
	return true


func take_hit(_hit: Hit) -> void:
	if lit:
		return
	set_lit(true)


func set_lit(v: bool, quiet := false) -> void:
	if lit == v:
		return
	lit = v
	if lit and not quiet:
		Sfx.play(&"ignite", 0.0, 0.05)
		Fx.burst(global_position + Vector2(0, -24), 16, {direction = Vector2.UP, spread = 30.0, speed_min = 30.0,
			speed_max = 90.0, lifetime = 0.6, gravity = Vector2(0, -60)})
	lit_changed.emit(self)


func flash_fail() -> void:
	_fail = 0.6


func _process(delta: float) -> void:
	_t += delta
	_fail = maxf(_fail - delta, 0.0)
	_glow.base_alpha = 0.55 if lit else 0.0
	queue_redraw()


func _draw() -> void:
	match style:
		"stone":
			draw_rect(Rect2(-7, -6, 14, 6), Color("#3a3a4e"))
			draw_rect(Rect2(-3, -16, 6, 10), Color("#4a4a60"))
			draw_rect(Rect2(-9, -22, 18, 6), Color("#5a5a72"))
			draw_rect(Rect2(-9, -22, 18, 1), Color("#8a8aa8"))
		"iron":
			draw_line(Vector2(-6, 0), Vector2(0, -12), Color("#3a3a44"), 2.0)
			draw_line(Vector2(6, 0), Vector2(0, -12), Color("#3a3a44"), 2.0)
			draw_rect(Rect2(-8, -22, 16, 8), Color("#4a4a58"))
			draw_rect(Rect2(-8, -22, 16, 1), Color("#8a8a9a"))
		"seal":
			draw_rect(Rect2(-2, -18, 4, 18), Color("#3a3050"))
			draw_rect(Rect2(-6, -22, 12, 4), Color("#5a4a78"))
			draw_arc(Vector2(0, -10), 9.0, 0, TAU, 16, Color(0.7, 0.5, 1.0, 0.3 + 0.2 * sin(_t * 2.0)), 1.0)
	if symbol != "":
		# 받침에 새긴 문양 (벽화의 순서와 맞춰 봄)
		var sc := Color(0.75, 0.6, 1.0, 0.85)
		var c := Vector2(0, -10)
		match symbol:
			"moon":
				draw_circle(c, 4.0, sc)
				draw_circle(c + Vector2(2, -1), 3.5, Color("#3a3050"))
			"fox":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -1), c + Vector2(-5, -5), c + Vector2(-1, -3), c + Vector2(1, -3), c + Vector2(5, -5), c + Vector2(4, -1), c + Vector2(0, 4)]), sc)
			"flame":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-3, 4), c + Vector2(0, -5), c + Vector2(3, 4)]), sc)
			"star":
				for k in 5:
					var ang := -PI * 0.5 + TAU * k / 5.0
					draw_line(c, c + Vector2(cos(ang), sin(ang)) * 4.0, sc, 1.0)
	if _fail > 0.0:
		draw_rect(Rect2(-9, -22, 18, 4), Color(1.0, 0.2, 0.2, _fail))
	if lit:
		var blue := style == "seal"
		var c1 := Color(0.5, 0.8, 1.0) if blue else Palette.FIRE_OUT
		var c2 := Color(0.85, 0.95, 1.0) if blue else Palette.FIRE_HOT
		for i in 3:
			var x := -5.0 + i * 5.0
			var hgt := 10.0 + 4.0 * sin(_t * 8.0 + i * 2.0)
			draw_colored_polygon(PackedVector2Array([Vector2(x - 3, -22), Vector2(x + sin(_t * 6.0 + i), -22 - hgt), Vector2(x + 3, -22)]), c1)
		draw_colored_polygon(PackedVector2Array([Vector2(-3, -22), Vector2(sin(_t * 9.0), -30), Vector2(3, -22)]), c2)
	else:
		draw_rect(Rect2(-6, -24, 12, 2), Color("#1a1a20"))
