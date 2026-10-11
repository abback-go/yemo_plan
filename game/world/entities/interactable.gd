class_name Interactable
extends Node2D
## ↑로 상호작용하는 것들의 공통 부분 (대화·문·기록·조사).
## World가 매 프레임 세라와 가장 가까운 것을 골라 머리 위에 "↑ 대화" 같은 안내를 띄운다.

var prompt := "조사"
var area_size := Vector2(28, 36) ## 발밑 기준 상호작용 범위 (가로, 위로 높이)
var room: Room


func _ready() -> void:
	add_to_group(&"interactable")


func interact_rect() -> Rect2:
	return Rect2(global_position + Vector2(-area_size.x * 0.5, -area_size.y), area_size)


func can_interact() -> bool:
	return is_visible_in_tree()


func interact() -> void:
	pass
