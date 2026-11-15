class_name FoxTrail
extends Area2D
## 여우 모드 대시가 남기는 푸른 불 자국: 닿은 적에게 한 번 작은 피해.

var _t := 0.0
var _hit := {}
const LIFE := 0.45


func _ready() -> void:
	collision_layer = GameConst.L_PLAYER_ATTACK
	collision_mask = GameConst.L_ENEMY_HURT
	material = Fx.add_material
	z_index = 3
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(14, 22)
	cs.shape = r
	add_child(cs)
	area_entered.connect(_on_area)


func _on_area(a: Area2D) -> void:
	var t := a.get_parent()
	if t and t.has_method("take_hit") and t.is_alive() and not _hit.has(t):
		_hit[t] = true
		var h := Hit.make(8, &"fox_trail", global_position)
		t.take_hit(h)


func _physics_process(delta: float) -> void:
	_t += delta
	if _t > 0.08:
		monitoring = false
	if _t >= LIFE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := 1.0 - _t / LIFE
	for i in 3:
		var x := -4.0 + i * 4.0
		var h := (10.0 + 4.0 * sin(_t * 30.0 + i)) * k
		draw_colored_polygon(PackedVector2Array([Vector2(x - 2.5, 10), Vector2(x, 10 - h - 6), Vector2(x + 2.5, 10)]), Color(0.45, 0.78, 1.0, 0.7 * k))
