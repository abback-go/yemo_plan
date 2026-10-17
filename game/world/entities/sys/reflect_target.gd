extends Node2D
## 되쏜 탄(Hit.kind = reflect)으로만 켜지는 과녁. 모두 켜지면 done_flag.
## {t = "reflect_target", x, y, group = "ward", done_flag = "ward_targets"}

var group := ""
var done_flag := ""
var lit := false
var _t := 0.0
var _hurt: Area2D


func setup(room: Room, e: Dictionary, _eid: String) -> void:
	position = room.tile_pos(e) + Vector2(8, 0)
	group = String(e.get("group", "ward"))
	done_flag = String(e.get("done_flag", ""))
	add_to_group(&"reflect_target_" + group)
	z_index = 1
	_hurt = Area2D.new()
	_hurt.collision_layer = GameConst.L_ENEMY_HURT
	_hurt.collision_mask = 0
	_hurt.monitoring = false
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(16, 22)
	cs.shape = r
	cs.position = Vector2(0, -14)
	_hurt.add_child(cs)
	add_child(_hurt)


func is_alive() -> bool:
	return true


func take_hit(hit: Hit) -> void:
	if lit:
		return
	if hit.kind != &"reflect":
		Sfx.play(&"block", -8.0, 0.1)
		return
	lit = true
	Sfx.play(&"ignite", 0.0, 0.0)
	Fx.ring(global_position + Vector2(0, -14), 4.0, 26.0, Palette.FIRE_HOT, 0.4, 2.0)
	var all_lit := true
	for n in get_tree().get_nodes_in_group(&"reflect_target_" + group):
		if not n.lit:
			all_lit = false
	if all_lit and done_flag != "":
		GameState.set_flag(done_flag)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-1, -8, 2, 8), Color("#4a3a2a"))
	var c := Vector2(0, -16)
	var col := Palette.FIRE_HOT if lit else Color("#c8b8a0")
	draw_circle(c, 8.0, Color("#e8dcc0"))
	draw_circle(c, 6.0, Color("#a83a2a"))
	draw_circle(c, 4.0, Color("#e8dcc0"))
	draw_circle(c, 2.0, col)
	if lit:
		draw_circle(c, 10.0 + sin(_t * 8.0), Color(Palette.FIRE_OUT, 0.25))
