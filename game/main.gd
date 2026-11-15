extends Node

func _ready() -> void:
	var l := Label.new()
	l.text = "테스트 한글"
	l.add_theme_font_size_override("font_size", 64)
	add_child(l)
