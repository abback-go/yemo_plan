class_name CalmZone
extends Area2D
## 봉인 결계 구역 (docs/archive/sera/chapter1.md 12.2절): 안에 있는 동안 세라의 폭주 게이지가 오르지 않는다(퍼즐 보호).

var _inside := false


func setup(room: Room, e: Dictionary, _eid: String) -> void:
	collision_layer = 0
	collision_mask = GameConst.L_PLAYER
	monitoring = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	var size := Vector2(float(e.get("w", 4)), float(e.get("h", 4))) * 16.0
	r.size = size
	cs.shape = r
	cs.position = room.tile_pos(e) + size * 0.5
	add_child(cs)
	body_entered.connect(func(b: Node) -> void:
		if b is Player:
			b.no_overload = true)
	body_exited.connect(func(b: Node) -> void:
		if b is Player:
			b.no_overload = false)


func _exit_tree() -> void:
	var w := World.get_world()
	if w and w.player:
		w.player.no_overload = false
