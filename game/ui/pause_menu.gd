extends CanvasLayer
## 일시정지 (Esc / 패드 Start): 계속하기 · 지도 · 퀘스트 · 마법서 · 설정 · 타이틀로 (docs/systems2.md).
## 프로토타입 스테이지(연습장)에서는 예전 메뉴(체크포인트에서 다시·처음부터)를 쓴다.

var _root: Control
var _menu: MenuList
var _info: InfoDraw
var _options: OptionsPanel
var _quests: QuestPanel
var _book: SpellbookPanel
var _page := "main" ## main · quests · spells · options


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.06, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	_info = InfoDraw.new()
	_info.set_anchors_preset(Control.PRESET_FULL_RECT)
	_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_info)

	_menu = MenuList.new()
	if _in_world():
		_menu.items = ["계속하기", "지도", "퀘스트", "마법서", "설정", "타이틀로"]
	else:
		_menu.items = ["계속하기", "체크포인트에서 다시", "처음부터", "타이틀로"]
	_menu.position = Vector2(60, 120)
	_menu.size = Vector2(200, 100)
	_menu.chosen.connect(_on_chosen)
	_root.add_child(_menu)

	_quests = QuestPanel.new()
	_quests.set_anchors_preset(Control.PRESET_FULL_RECT)
	_quests.closed.connect(func() -> void: _set_page("main"))
	_root.add_child(_quests)
	_quests.visible = false
	_book = SpellbookPanel.new()
	_book.set_anchors_preset(Control.PRESET_FULL_RECT)
	_book.closed.connect(func() -> void: _set_page("main"))
	_root.add_child(_book)
	_book.visible = false
	_options = OptionsPanel.new()
	_options.position = Vector2(260, 110)
	_options.closed.connect(func() -> void: _set_page("main"))
	_root.add_child(_options)
	_options.visible = false
	_root.visible = false


func _in_world() -> bool:
	return get_parent() is World


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _page != "main" and _root.visible:
			_set_page("main")
		else:
			_toggle()
		get_viewport().set_input_as_handled()
		return
	if not _root.visible:
		return
	match _page:
		"main":
			if _menu.handle_input(event) and is_inside_tree():
				get_viewport().set_input_as_handled()
		"quests":
			if _quests.handle_input(event) and is_inside_tree():
				get_viewport().set_input_as_handled()
		"spells":
			if _book.handle_input(event) and is_inside_tree():
				get_viewport().set_input_as_handled()
		"options":
			if _options.handle_input(event):
				get_viewport().set_input_as_handled()


func is_open() -> bool:
	return _root.visible


func _toggle() -> void:
	var p := get_tree().get_first_node_in_group(GameConst.GROUP_PLAYER) as Player
	if not _root.visible:
		if p == null or not p.is_alive() or not p.controls_enabled or get_tree().paused:
			return
		if Story.busy():
			return
	_root.visible = not _root.visible
	get_tree().paused = _root.visible
	_menu.selected = 0
	_set_page("main")
	Sfx.play(&"ui_move", 0.0, 0.0)


func _set_page(page: String) -> void:
	_page = page
	_info.page = page
	_menu.visible = page == "main"
	_options.visible = page == "options"
	_quests.visible = page == "quests"
	_book.visible = page == "spells"
	if page == "options":
		_options.open()
	elif page == "quests":
		_quests.open()
	elif page == "spells":
		_book.open()


func _on_chosen(index: int) -> void:
	if not _in_world():
		get_tree().paused = false
		_root.visible = false
		match index:
			1: GameState.restart_from_checkpoint()
			2: GameState.restart_run()
			3: GameState.go_title()
		return
	match index:
		0:
			get_tree().paused = false
			_root.visible = false
		1:
			_root.visible = false
			get_tree().paused = false
			(get_parent() as World).map_screen.open()
		2:
			_set_page("quests")
		3:
			_set_page("spells")
		4:
			_set_page("options")
		5:
			get_tree().paused = false
			_root.visible = false
			GameState.go_title()


class InfoDraw extends Control:
	var page := "main"
	var _font: Font

	func _ready() -> void:
		_font = ThemeDB.fallback_font

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if page == "quests" or page == "spells":
			return
		draw_string(_font, Vector2(60, 90), "일시정지", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Palette.GOLD)
		draw_string(_font, Vector2(60, 330), "플레이 시간 " + GameState.format_time(GameState.run_time), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_DIM)
		if page == "main":
			var cur := Objectives.current()
			if cur != "":
				draw_string(_font, Vector2(260, 130), "지금 할 일", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_DIM)
				draw_string(_font, Vector2(260, 148), cur, HORIZONTAL_ALIGNMENT_LEFT, 340, 12, Palette.UI_TEXT)
			var y := 190.0
			draw_string(_font, Vector2(260, y), "익힌 마법", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_DIM)
			var spells := ["화염탄 (X)"]
			for sid in Spells.ORDER:
				if Spells.learned(sid):
					spells.append("%s Lv%d" % [String(Spells.info(sid).name), Spells.level(sid)])
			if GameState.has_ability("fox_window"):
				spells.append("여우창문 (D)")
			if GameState.has_ability("fox_mode"):
				spells.append("빙의 — 여우 모드 (꼬리 %d)" % int(GameState.flag("tails", 1)))
			for i in spells.size():
				draw_string(_font, Vector2(260 + (i % 2) * 170, y + 18 + (i / 2) * 16), spells[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_TEXT)
		elif page == "goals":
			draw_string(_font, Vector2(60, 120), "목표", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.GOLD)
			var cur2 := Objectives.current()
			var y2 := 142.0
			if cur2 != "":
				draw_string(_font, Vector2(60, y2), "▶ " + cur2, HORIZONTAL_ALIGNMENT_LEFT, 520, 12, Palette.UI_TEXT)
				y2 += 22
			for d in Objectives.done_list():
				draw_string(_font, Vector2(60, y2), "✓ " + String(d), HORIZONTAL_ALIGNMENT_LEFT, 520, 12, Palette.UI_DIM)
				y2 += 16
			draw_string(_font, Vector2(60, 310), "눌러서 돌아가기" if TouchControls.active else "Z 돌아가기", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_DIM)
