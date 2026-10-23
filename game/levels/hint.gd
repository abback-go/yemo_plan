@tool
class_name Hint
extends Node2D
## 조작 안내 문구. 세라가 가까이 오면 나타나고 멀어지면 흐려진다.

@export_multiline var text := "안내":
	set(v):
		text = v
		if _label:
			_label.text = v
@export var show_radius_t := 9.0

var _label: Label


func _ready() -> void:
	_label = Label.new()
	_label.text = text
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ls := LabelSettings.new()
	ls.font_size = 12
	ls.font_color = Palette.UI_TEXT
	ls.outline_size = 4
	ls.outline_color = Color("#0b0914")
	_label.label_settings = ls
	_label.position = Vector2(-240, 0)
	_label.size = Vector2(480, 16)
	add_child(_label)
	z_index = 8
	if not Engine.is_editor_hint():
		modulate.a = 0.0


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var p := get_tree().get_first_node_in_group(GameConst.GROUP_PLAYER) as Node2D
	var target := 0.0
	if p and absf(p.global_position.x - global_position.x) < show_radius_t * GameConst.TILE:
		target = 1.0
	modulate.a = move_toward(modulate.a, target, delta * 3.0)
