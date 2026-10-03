extends CanvasLayer
## 일시정지 메뉴 (Esc / 패드 Start): 계속하기 · 체크포인트에서 다시 · 처음부터 · 타이틀로

var _root: Control
var _menu: MenuList


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.06, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	var title := Label.new()
	title.text = "일시정지"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 110)
	title.size = Vector2(640, 20)
	var ls := LabelSettings.new()
	ls.font_size = 12
	ls.font_color = Palette.GOLD
	title.label_settings = ls
	_root.add_child(title)

	_menu = MenuList.new()
	_menu.items = ["계속하기", "체크포인트에서 다시", "처음부터", "타이틀로"]
	_menu.position = Vector2(270, 140)
	_menu.size = Vector2(200, 90)
	_menu.chosen.connect(_on_chosen)
	_root.add_child(_menu)
	_root.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle()
		get_viewport().set_input_as_handled()
		return
	if _root.visible and _menu.handle_input(event):
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	var p := get_tree().get_first_node_in_group(GameConst.GROUP_PLAYER) as Player
	if not _root.visible and (p == null or not p.is_alive() or not p.controls_enabled):
		return
	_root.visible = not _root.visible
	get_tree().paused = _root.visible
	_menu.selected = 0
	Sfx.play(&"ui_move", 0.0, 0.0)


func _on_chosen(index: int) -> void:
	get_tree().paused = false
	_root.visible = false
	match index:
		0: pass
		1: GameState.restart_from_checkpoint()
		2: GameState.restart_run()
		3: GameState.go_title()
