class_name Hazard
extends Area2D
## 가시·불꽃: 닿으면 1 피해 + 직전에 서 있던 안전한 땅으로 돌아간다.

func setup(r: Rect2) -> void:
	collision_layer = 0
	collision_mask = GameConst.L_PLAYER
	monitoring = true
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = r.size
	cs.shape = rs
	cs.position = r.get_center()
	add_child(cs)


func _physics_process(_delta: float) -> void:
	for b in get_overlapping_bodies():
		if b is Player:
			b.hazard_hit()
