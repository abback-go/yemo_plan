class_name EmoteBubble
extends Node2D
## 머리 위 감정 표시 (! ? … ♪ ♥ 땀). 세라·인물 공용. 기호표·그리기는 BubbleDraw.

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
	BubbleDraw.draw_emote(self, _font, Vector2.ZERO, clampf(_t * 6.0, 0.0, 1.0), BubbleDraw.glyph(_kind, "bubble"), true)
