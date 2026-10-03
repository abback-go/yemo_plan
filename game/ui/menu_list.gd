class_name MenuList
extends Control
## 위아래로 고르고 확인하는 간단한 메뉴 (일시정지·결과 화면 공용). 키보드·패드 모두 사용.

signal chosen(index: int)

var items: Array[String] = []
var selected := 0
var font_size := 12
var line_height := 18.0
var _t := 0.0
var _font: Font


func _ready() -> void:
	_font = get_theme_default_font()
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func handle_input(event: InputEvent) -> bool:
	if not is_visible_in_tree() or items.is_empty():
		return false
	if event.is_action_pressed("ui_up"):
		selected = (selected - 1 + items.size()) % items.size()
		Sfx.play(&"ui_move", 0.0, 0.0)
		return true
	if event.is_action_pressed("ui_down"):
		selected = (selected + 1) % items.size()
		Sfx.play(&"ui_move", 0.0, 0.0)
		return true
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump") or event.is_action_pressed("attack"):
		Sfx.play(&"ui_ok", 0.0, 0.0)
		chosen.emit(selected)
		return true
	return false


func _draw() -> void:
	for i in items.size():
		var y := i * line_height + font_size
		var sel := i == selected
		var col := Palette.UI_TEXT if sel else Palette.UI_DIM
		if sel:
			var bob := sin(_t * 8.0)
			draw_colored_polygon(PackedVector2Array([
				Vector2(-12 + bob, y - 8), Vector2(-6 + bob, y - 4.5), Vector2(-12 + bob, y - 1),
			]), Palette.FIRE_OUT)
		draw_string(_font, Vector2(0, y), items[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
