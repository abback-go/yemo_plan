class_name ArcheryMark
extends Node2D
## 활터 과녁 (엘라리엔의 부탁 e_archery — docs/archive/sera/chapter3.md 11절). 짚 과녁이 레일을 따라 움직이고(dx·dy·period),
## 불(화염탄 등)에 맞으면 금빛으로 "맞음" 표시가 켜진다(한 판 동안 유지). 대본이 group의 과녁을 세며 제한 시간을 잰다.
## active_if 플래그가 서 있을 때만 맞힐 수 있다(시험 중). 대본이 reset_group(group)으로 다시 세운다.
## 방 데이터: {t = "archery_mark", x, y, group = "archery", dx = 0, dy = 0, period = 2.4, phase = 0, active_if = "", hang = false}

var group := "archery"
var hit := false
var active_if := ""
var axis := Vector2.ZERO
var period := 2.4
var hang := false
var _base := Vector2.ZERO
var _t := 0.0
var _flash := 0.0
var _hurt: Area2D


func setup(room: Room, e: Dictionary, _eid: String) -> void:
	group = String(e.get("group", "archery"))
	active_if = String(e.get("active_if", ""))
	axis = Vector2(float(e.get("dx", 0)), float(e.get("dy", 0))) * 16.0
	period = float(e.get("period", 2.4))
	_t = float(e.get("phase", 0.0))
	hang = bool(e.get("hang", false))
	position = room.tile_pos(e) + Vector2(8, 0)
	_base = position
	add_to_group(&"archery_mark")
	_hurt = Area2D.new()
	_hurt.collision_layer = GameConst.L_ENEMY_HURT
	_hurt.collision_mask = 0
	_hurt.monitoring = false
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 10.0
	cs.shape = c
	cs.position = Vector2(0, 18 if hang else -20)
	_hurt.add_child(cs)
	add_child(_hurt)


func is_alive() -> bool:
	return not hit


func is_on_floor() -> bool:
	return not hang


static func reset_group(tree: SceneTree, g: String) -> void:
	for n in tree.get_nodes_in_group(&"archery_mark"):
		if n.group == g:
			n.hit = false


static func count_hit(tree: SceneTree, g: String) -> int:
	var k := 0
	for n in tree.get_nodes_in_group(&"archery_mark"):
		if n.group == g and n.hit:
			k += 1
	return k


static func count_all(tree: SceneTree, g: String) -> int:
	var k := 0
	for n in tree.get_nodes_in_group(&"archery_mark"):
		if n.group == g:
			k += 1
	return k


func take_hit(_h: Hit) -> void:
	if hit or not RoomData.cond_ok(active_if) or active_if == "":
		if active_if != "" and not RoomData.cond_ok(active_if):
			_flash = 0.2
		return
	hit = true
	_flash = 0.5
	Ch3Sfx.play(&"arrow_hit", 0.0, 0.0)
	Sfx.play(&"pickup", -6.0, 0.0)
	Fx.ring(global_position + Vector2(0, 18 if hang else -20), 3.0, 20.0, Color(1.0, 0.85, 0.4), 0.3, 2.0)


func _process(delta: float) -> void:
	_t += delta
	_flash = maxf(_flash - delta, 0.0)
	if axis != Vector2.ZERO and not hit:
		position = _base + axis * sin(_t * TAU / period)
	queue_redraw()


func _draw() -> void:
	var c := Vector2(0, 18 if hang else -20)
	if hang:
		draw_line(Vector2(0, -2 - axis.y), c + Vector2(0, -10), Color("#8a7448"), 1.0)
	else:
		draw_line(Vector2(-6, 0), c + Vector2(-2, 8), Color("#6a4a2a"), 2.0)
		draw_line(Vector2(6, 0), c + Vector2(2, 8), Color("#6a4a2a"), 2.0)
	draw_circle(c, 10.0, Color("#c8b878"))
	draw_circle(c, 7.5, Color("#3a6a3a") if not hit else Color("#d8a840"))
	draw_circle(c, 5.0, Color("#e8dcb0"))
	draw_circle(c, 2.5, Color("#e6bf4e") if not hit else Color.WHITE)
	if hit:
		draw_line(c + Vector2(2, -1), c + Vector2(-8, -4), Palette.FIRE_HOT, 1.0)
		draw_circle(c, 13.0, Color(1.0, 0.85, 0.4, 0.15 + 0.1 * sin(_t * 6.0)))
	if _flash > 0.0:
		draw_circle(c, 12.0, Color(1, 1, 1, _flash))
