class_name ScreenFade
extends CanvasLayer
## 화면 전체 검은 막 (방 전환·컷신 암전). 일시정지·히트스톱과 상관없이 실제 시간으로 움직인다.

signal done

var _rect: ColorRect
var _tween: Tween


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)


func set_black(color := Color.BLACK) -> void:
	_stop()
	_rect.color = Color(color, 1.0)


## 진행 중인 페이드를 멈추고, 그것을 기다리던 쪽도 풀어 준다 (트윈을 죽이면 finished가 오지 않으므로)
func _stop() -> void:
	if _tween:
		_tween.kill()
		_tween = null
		done.emit()


func fade_out(time := 0.3, color := Color.BLACK) -> void:
	_stop()
	_rect.color = Color(color, _rect.color.a)
	_tween = create_tween().set_ignore_time_scale(true)
	_tween.tween_property(_rect, "color:a", 1.0, time)
	_tween.finished.connect(_on_finished.bind(_tween))
	await done


func fade_in(time := 0.3) -> void:
	_stop()
	_tween = create_tween().set_ignore_time_scale(true)
	_tween.tween_property(_rect, "color:a", 0.0, time)
	_tween.finished.connect(_on_finished.bind(_tween))
	await done


func _on_finished(t: Tween) -> void:
	if t == _tween:
		_tween = null
		done.emit()


func is_black() -> bool:
	return _rect.color.a > 0.99
