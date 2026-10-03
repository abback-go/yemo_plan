extends Node2D
## 1단계 테스트 방. 발판 높이(1~4T)와 대시 간격(4T)으로 점프·대시 손맛을 확인한다.


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()
