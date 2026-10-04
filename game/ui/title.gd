extends Control
## 타이틀 (docs/chapter1.md 10절). 브라우저는 첫 입력 전 소리를 막으므로 "아무 키나"로 한 번 받은 뒤 메뉴를 연다.
## 메뉴: 이어하기(기록이 있으면) · 새로 시작 · 설정 · 전투 시제품(새 조작 훈련장, proto/) · 전투 연습장(v0.3 프로토타입)
## 홈 화면 웹앱(오프라인 캐시)에 새 버전이 받아져 있으면 맨 위에 "새 버전으로 업데이트"가 생긴다.

const BG := preload("res://levels/background.gd")

var _t := 0.0
var _sera: PlayerVisual
var _font: Font
var _phase := 0 ## 0 아무 키 대기, 1 메뉴, 2 설정, 3 새로 시작 확인, 4 시작함
var _text: Control
var _menu: MenuList
var _confirm: MenuList
var _options: OptionsPanel
var _items: Array[String] = []
var _code_msg := ""
var _code_msg_t := 0.0


func _ready() -> void:
	Fx.reset()
	get_tree().paused = false
	_font = get_theme_default_font()
	var sky := BG.SkyDraw.new()
	add_child(sky)
	var school := BG.LayerDraw.new()
	school.kind = BG.LayerDraw.Kind.SCHOOL
	school.position = Vector2(-200, 0)
	add_child(school)
	var forest := BG.LayerDraw.new()
	forest.kind = BG.LayerDraw.Kind.FOREST_NEAR
	forest.position = Vector2(0, 10)
	add_child(forest)

	var ground := ColorRect.new()
	ground.color = Palette.GROUND
	ground.position = Vector2(0, 318)
	ground.size = Vector2(640, 42)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ground)
	var ground_top := ColorRect.new()
	ground_top.color = Palette.GROUND_TOP
	ground_top.position = Vector2(0, 318)
	ground_top.size = Vector2(640, 2)
	ground_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ground_top)

	_sera = PlayerVisual.new()
	_sera.position = Vector2(150, 318)
	_sera.scale = Vector2(3, 3)
	add_child(_sera)

	_text = TitleText.new()
	_text.title = self
	_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_text)

	_menu = MenuList.new()
	_menu.position = Vector2(284, 178)
	_menu.size = Vector2(220, 110)
	_menu.chosen.connect(_on_menu)
	_menu.visible = false
	add_child(_menu)
	_confirm = MenuList.new()
	_confirm.items = ["아니요", "예, 새로 시작"]
	_confirm.position = Vector2(284, 232)
	_confirm.size = Vector2(220, 40)
	_confirm.chosen.connect(_on_confirm)
	_confirm.visible = false
	add_child(_confirm)
	_options = OptionsPanel.new()
	_options.position = Vector2(284, 150)
	_options.visible = false
	_options.closed.connect(func() -> void:
		_options.visible = false
		_menu.visible = true
		_phase = 1)
	add_child(_options)
	Music.play("title", 1.5)
	if OS.has_feature("web"):
		JavaScriptBridge.pwa_update_available.connect(_on_pwa_update)


func _on_pwa_update() -> void:
	if _phase == 1:
		_build_menu()


func _build_menu() -> void:
	_items.clear()
	if OS.has_feature("web") and JavaScriptBridge.pwa_needs_update():
		_items.append("새 버전으로 업데이트")
	if GameState.has_save():
		_items.append("이어하기")
	_items.append("새로 시작")
	_items.append("저장 코드로 이어하기")
	_items.append("설정")
	_items.append("전투 시제품 (새 조작)")
	_items.append("전투 연습장")
	_menu.items = _items.duplicate()
	_menu.selected = 0


func _process(delta: float) -> void:
	_t += delta
	_code_msg_t = maxf(_code_msg_t - delta, 0.0)
	_sera.overload_ratio = 0.3 + 0.3 * sin(_t * 0.8)
	_sera.update_pose(delta)
	_text.queue_redraw()


func draw_text_on(c: CanvasItem) -> void:
	c.draw_rect(Rect2(258, 40, 300, 268), Color(0.03, 0.02, 0.06, 0.62))
	c.draw_rect(Rect2(258, 40, 2, 268), Color(Palette.FIRE_OUT, 0.6))
	c.draw_string(_font, Vector2(270, 92), "YEMO", HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Palette.FIRE_HOT)
	c.draw_string(_font, Vector2(272, 116), "마녀학교와 여우신 · 전체판 v1.0 (1~5장)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_TEXT)
	c.draw_string(_font, Vector2(272, 140), "폐급 마녀 세라와 여우신 너울의 이야기", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_DIM)
	c.draw_string(_font, Vector2(420, 350), "빌드 " + BuildInfo.COMMIT, HORIZONTAL_ALIGNMENT_RIGHT, 210, 12, Color(Palette.UI_DIM, 0.6))
	match _phase:
		0:
			if fmod(_t, 1.0) < 0.65:
				c.draw_string(_font, Vector2(272, 230), "화면을 누르세요" if _touch_screen() else "아무 키나 누르세요", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.GOLD)
			c.draw_string(_font, Vector2(272, 290), "터치 · 키보드 · 게임패드" if _touch_screen() else "키보드 또는 게임패드", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_DIM)
		1:
			c.draw_string(_font, Vector2(272, 300), "눌러서 고르기" if TouchControls.active else "↑↓ 고르기 · Z 확인", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_DIM)
			if _code_msg_t > 0.0:
				c.draw_multiline_string(_font, Vector2(272, 322), _code_msg, HORIZONTAL_ALIGNMENT_LEFT, 280, 12, 2, Color(1.0, 0.55, 0.45, minf(_code_msg_t, 1.0)))
		3:
			c.draw_string(_font, Vector2(272, 208), "기록을 지우고 처음부터 시작할까요?", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_TEXT)


func _touch_screen() -> bool:
	return TouchControls.active or DisplayServer.is_touchscreen_available()


func _input(event: InputEvent) -> void:
	if _t < 0.3 or _phase == 4:
		return
	match _phase:
		0:
			var pressed: bool = (event is InputEventKey and event.pressed and not event.echo) \
				or (event is InputEventJoypadButton and event.pressed) \
				or (event is InputEventMouseButton and event.pressed)
			if pressed:
				get_viewport().set_input_as_handled()
				Sfx.play(&"ui_ok", 0.0, 0.0)
				_build_menu()
				_menu.visible = true
				_phase = 1
		1:
			if _menu.handle_input(event) and is_inside_tree():
				get_viewport().set_input_as_handled() # 장면이 바뀌었으면 이미 트리 밖
		2:
			if _options.handle_input(event):
				get_viewport().set_input_as_handled()
		3:
			if _confirm.handle_input(event):
				if is_inside_tree():
					get_viewport().set_input_as_handled()
			elif event.is_action_pressed("ui_cancel"):
				_confirm.visible = false
				_menu.visible = true
				_phase = 1


func _on_menu(index: int) -> void:
	match _items[index]:
		"새 버전으로 업데이트":
			_phase = 4
			JavaScriptBridge.pwa_update() # 새 캐시로 바꾸고 다시 불러온다 (기록은 그대로)
		"이어하기":
			_phase = 4
			Music.stop(0.8)
			if not GameState.continue_game():
				_phase = 1
		"새로 시작":
			if GameState.has_save():
				_menu.visible = false
				_confirm.visible = true
				_confirm.selected = 0
				_phase = 3
			else:
				_start_new()
		"저장 코드로 이어하기":
			var code := SaveCodeUI.ask_code()
			if code.strip_edges() == "":
				return
			if GameState.import_code(code):
				_phase = 4
				Music.stop(0.8)
				if not GameState.continue_game():
					_phase = 1
			else:
				_code_msg = "저장 코드가 올바르지 않아요. YEMO1- 부터 끝까지 전부 붙여 넣었는지 확인해 주세요."
				_code_msg_t = 5.0
				Sfx.play(&"block", -2.0, 0.0)
		"설정":
			_menu.visible = false
			_options.open()
			_options.visible = true
			_phase = 2
		"전투 시제품 (새 조작)":
			_phase = 4
			get_tree().change_scene_to_file("res://proto/proto_arena.tscn")
		"전투 연습장":
			_phase = 4
			GameState.new_run()
			GameState.start_stage()


func _on_confirm(index: int) -> void:
	if index == 1:
		GameState.delete_save()
		_start_new()
	else:
		_confirm.visible = false
		_menu.visible = true
		_phase = 1


func _start_new() -> void:
	_phase = 4
	Music.stop(1.0)
	GameState.start_new_game()


class TitleText extends Control:
	var title: Node

	func _draw() -> void:
		title.draw_text_on(self)
