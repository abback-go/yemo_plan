class_name EnemyAttackArea
extends Area2D
## 세라에게 피해를 주는 영역 (돌진형 몸통, 저격탄).
## 세라 쪽이 매 프레임 자기 피격 판정과 겹치는 이 영역을 찾아 피해를 받는다.

signal hit_player(player: Node)

@export var damage := 1
@export var cause := &"charger" ## 결과 화면의 피격 원인 (charger / sniper)
@export var active := true


func _init() -> void:
	collision_layer = GameConst.L_ENEMY_ATTACK
	collision_mask = 0
	monitoring = false # 세라 쪽에서 찾으므로 이 영역은 감지하지 않아도 됨
	monitorable = true


func notify_hit(player: Node) -> void:
	hit_player.emit(player)


static func with_rect(size: Vector2, offset := Vector2.ZERO) -> EnemyAttackArea:
	var a := EnemyAttackArea.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = offset
	a.add_child(shape)
	return a
