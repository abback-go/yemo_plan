@tool
class_name SpawnTrigger
extends Area2D
## 세라가 이 영역에 들어오면 자식 SpawnPoint들에서 적을 소환한다 (한 번만).
## 구간 3의 "돌진형이 시간차로 등장"에 쓴다. 원점은 왼쪽 위.

@export var size := Vector2(32, 160)

var _fired := false


func _ready() -> void:
	collision_layer = GameConst.L_TRIGGER
	collision_mask = GameConst.L_PLAYER
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = size / 2.0
	add_child(shape)
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _fired or not body is Player:
		return
	_fired = true
	var parent := get_parent()
	for c in get_children():
		if c is SpawnPoint:
			c.spawn(parent, func(_e: EnemyBase) -> void: pass)


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.4, 1.0, 1.0, 0.12))
