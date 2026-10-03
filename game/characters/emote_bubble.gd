class_name EmoteBubble
extends Node2D
## 머리 위 감정 표시 (! ? … ♪ ♥ 땀). 세라·인물 공용.

var _kind := ""
var _t := 0.0
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	z_index = 30


func show_emote(kind: String, time := 1.2) -> void:
	_kind = kind
	_t = time


func _process(delta: float) -> void:
	if _t > 0.0:
		_t -= delta
		queue_redraw()
		if _t <= 0.0:
			_kind = ""
			queue_redraw()


func _draw() -> void:
	if _kind == "":
		return
	var pop := clampf(_t * 6.0, 0.0, 1.0)
	draw_circle(Vector2.ZERO, 7.0 * pop, Color("#f4eee4"))
	draw_colored_polygon(PackedVector2Array([Vector2(-2, 5), Vector2(2, 5), Vector2(0, 9)]), Color("#f4eee4"))
	var txt: String = {"!": "!", "?": "?", "...": "…", "heart": "♥", "note": "♪", "anger": "#", "sweat": "~"}.get(_kind, _kind)
	if pop > 0.9:
		var w := _font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(_font, Vector2(-w * 0.5, 4), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#2a1a2a"))
