extends Node2D
## 별자리 별 (유성 낙화 수업 1단계 — 오필리아의 별 관측): 화염탄으로 맞히면 켜진다. 같은 그룹의 별을
## order 순서대로 켜야 하고, 틀리면 모두 꺼진다. 다 켜면 별자리 선이 이어지고 done_flag.
## {t = "star_point", x, y, group = "lyre", order = 0, count = 7, done_flag = "stars_done"}

var group := ""
var order := 0
var count := 7
var done_flag := ""
var lit := false
var _t := 0.0
var _hurt: Area2D
var _wrong := 0.0
var hint := false ## 한 번 틀리면 다음 순서의 별이 반짝여 알려 준다 (초보자 난이도)


func setup(room: Room, e: Dictionary, _eid: String) -> void:
	position = room.tile_pos(e) + Vector2(8, 8)
	group = String(e.get("group", "stars"))
	order = int(e.get("order", 0))
	count = int(e.get("count", 7))
	done_flag = String(e.get("done_flag", ""))
	add_to_group(&"star_point_" + group)
	material = Fx.add_material
	z_index = 2
	_hurt = Area2D.new()
	_hurt.collision_layer = GameConst.L_ENEMY_HURT
	_hurt.collision_mask = 0
	_hurt.monitoring = false
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 9.0
	cs.shape = c
	_hurt.add_child(cs)
	add_child(_hurt)
	if done_flag != "" and GameState.has_flag(done_flag):
		lit = true


func is_alive() -> bool:
	return true


func _group() -> Array:
	return get_tree().get_nodes_in_group(&"star_point_" + group)


func take_hit(_hit: Hit) -> void:
	if lit:
		return
	var next := 0
	for n in _group():
		if n.lit:
			next += 1
	if order != next:
		for n in _group():
			n.reset_wrong()
		Sfx.play(&"block", -2.0, 0.0)
		return
	lit = true
	Sfx.play(&"star_twinkle", 0.0, 0.0)
	Fx.ring(global_position, 3.0, 22.0, Color(1.0, 0.95, 0.7), 0.4, 2.0)
	if next + 1 >= count and done_flag != "":
		GameState.set_flag(done_flag)
		Sfx.play(&"star_burst", 0.0, 0.0)


func reset_wrong() -> void:
	lit = false
	_wrong = 0.6
	hint = true


func _process(delta: float) -> void:
	_t += delta
	_wrong = maxf(_wrong - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	# 선: 다음 순서의 켜진 별까지
	if lit:
		for n in _group():
			if n.lit and n.order == order + 1:
				draw_line(Vector2.ZERO, to_local(n.global_position), Color(1.0, 0.95, 0.7, 0.6), 1.0)
	var tw := 0.6 + 0.4 * sin(_t * 3.0 + order)
	var col := Color(1.0, 0.95, 0.7) if lit else Color(0.55, 0.6, 0.9, 0.5 * tw)
	if _wrong > 0.0:
		col = Color(1.0, 0.3, 0.3, _wrong)
	var r := 5.0 if lit else 3.0
	if hint and not lit and _wrong <= 0.0:
		var nxt := 0
		for n in _group():
			if n.lit:
				nxt += 1
		if order == nxt:
			r = 4.0
			col = Color(1.0, 0.9, 0.6, 0.6 + 0.4 * sin(_t * 6.0))
			draw_arc(Vector2.ZERO, 10.0 + 2.0 * sin(_t * 6.0), 0.0, TAU, 20, Color(1.0, 0.9, 0.6, 0.4), 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -r * 1.8), Vector2(r * 0.45, -r * 0.45), Vector2(r * 1.8, 0), Vector2(r * 0.45, r * 0.45),
		Vector2(0, r * 1.8), Vector2(-r * 0.45, r * 0.45), Vector2(-r * 1.8, 0), Vector2(-r * 0.45, -r * 0.45)]), col)
	if lit:
		draw_circle(Vector2.ZERO, 9.0, Color(1.0, 0.95, 0.7, 0.2))
