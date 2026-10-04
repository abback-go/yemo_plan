class_name InteractHint
extends Node2D
## 상호작용할 수 있는 것 위에 뜨는 작은 안내 ("↑ 말 걸기 — 피피")

var target: Interactable:
	set(v):
		if v != target:
			target = v
			_pop = 0.0
var _t := 0.0
var _pop := 0.0
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font


func _process(delta: float) -> void:
	_t += delta
	_pop = minf(_pop + delta * 6.0, 1.0)
	queue_redraw()


func _draw() -> void:
	if target == null or not is_instance_valid(target):
		return
	var r := target.interact_rect()
	var text := "↑ " + target.prompt
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 10
	var p := Vector2(r.get_center().x - w * 0.5, r.position.y - 18 + sin(_t * 4.0) * 1.0 + (1.0 - _pop) * 4.0)
	var a := _pop
	draw_rect(Rect2(p, Vector2(w, 15)), Color(0.04, 0.03, 0.08, 0.82 * a))
	draw_rect(Rect2(p, Vector2(w, 1)), Color(Palette.GOLD, 0.8 * a))
	draw_string(_font, p + Vector2(5, 12), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(Palette.UI_TEXT, a))
