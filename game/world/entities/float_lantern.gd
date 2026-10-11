class_name FloatLantern
extends Area2D
## 부양 실습 등불 (docs/archive/sera/chapter1.md 12.3절): 공중에 떠 있는 작은 등불. 닿으면 모인다.
## 같은 group의 등불을 모두 모으면 flag를 세운다.

var group := "lanterns"
var done_flag := ""
var _t := 0.0
var _got := false


func setup(room: Room, e: Dictionary, _eid: String) -> void:
	group = String(e.get("group", "lanterns"))
	done_flag = String(e.get("done_flag", ""))
	position = room.tile_pos(e) + Vector2(8, 8)
	_t = randf() * 5.0
	add_to_group(&"float_lantern")
	collision_layer = 0
	collision_mask = GameConst.L_PLAYER
	monitoring = true
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 9
	cs.shape = c
	add_child(cs)
	body_entered.connect(_on_body)
	add_child(LightGlow.make(Vector2.ZERO, 30.0, Color(0.8, 0.75, 1.0), 0.35))
	if done_flag != "" and GameState.has_flag(done_flag):
		_got = true
		visible = false


func is_collected() -> bool:
	return _got


func _on_body(b: Node) -> void:
	if _got or not b is Player:
		return
	_got = true
	Sfx.play(&"pickup", -2.0, 0.1)
	Fx.ring(global_position, 3.0, 22.0, Color(0.8, 0.75, 1.0), 0.3, 1.0)
	Fx.burst(global_position, 12, {spread = 180.0, speed_min = 20.0, speed_max = 70.0, lifetime = 0.5,
		gradient = Palette.fade_gradient(Color(0.85, 0.8, 1.0)), add = true, gravity = Vector2.ZERO})
	visible = false
	var left := 0
	var total := 0
	for n in get_tree().get_nodes_in_group(&"float_lantern"):
		if n.group == group:
			total += 1
			if not n.is_collected():
				left += 1
	if left == 0:
		if done_flag != "":
			GameState.set_flag(done_flag)
	else:
		Story.toast("등불 %d / %d" % [total - left, total], 1.2)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var y := sin(_t * 2.0) * 2.0
	draw_rect(Rect2(-4, -6 + y, 8, 11), Color("#efe4ff"))
	draw_rect(Rect2(-3, -4 + y, 6, 7), Color(1.0, 0.85, 0.55))
	draw_rect(Rect2(-5, -7 + y, 10, 2), Color("#8a7aa8"))
	draw_rect(Rect2(-5, 5 + y, 10, 2), Color("#8a7aa8"))
	draw_line(Vector2(0, -7 + y), Vector2(0, -11 + y), Color("#8a7aa8"), 1.0)
