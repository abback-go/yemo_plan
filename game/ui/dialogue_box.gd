class_name DialogueBox
extends CanvasLayer
## 대화창 (docs/chapter1.md 4.4절): 아래쪽 판, 왼쪽 초상화, 이름, 타자 효과(초당 40자), 화자별 목소리 삑삑음.
## 확인(Z·X·Enter·Space·패드 A)을 누르면 전부 표시 → 다시 누르면 다음. 너울의 말은 푸른 테두리.
## 일시정지·히트스톱과 무관하게 실제 시간으로 움직인다.

signal advanced

const CPS := 40.0 ## 초당 글자 수
const PANEL := Rect2(14, 262, 612, 88)

var _root: Control
var _panel: PanelDraw
var _portrait: Portrait
var _name: Label
var _text: Label
var _choices: MenuList
var _typing := false
var _shown := 0.0
var _total := 0
var _waiting := false
var _voice := 1.0
var _blip_acc := 0
var _choice_result := -1
var _neoul_note := 0


func _ready() -> void:
	layer = 62
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_panel = PanelDraw.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_panel)
	_portrait = Portrait.new()
	_portrait.position = PANEL.position + Vector2(8, 8)
	_portrait.size = Vector2(72, 72)
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_portrait)
	_name = Label.new()
	var ns := LabelSettings.new()
	ns.font_size = 12
	ns.outline_size = 4
	ns.outline_color = Color("#0b0914")
	_name.label_settings = ns
	_root.add_child(_name)
	_text = Label.new()
	var ts := LabelSettings.new()
	ts.font_size = 12
	ts.line_spacing = 3
	ts.font_color = Palette.UI_TEXT
	_text.label_settings = ts
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root.add_child(_text)
	_choices = MenuList.new()
	_choices.visible = false
	_choices.chosen.connect(_on_choice)
	_root.add_child(_choices)
	_root.visible = false


func is_open() -> bool:
	return _root.visible


## 한 줄 보여 주고 플레이어가 넘길 때까지 기다린다
func show_line(who: String, text: String, expr := "normal") -> void:
	var info := Characters.info(who)
	var narr := who == "narration" or who == ""
	_root.visible = true
	_panel.color = info.get("color", Palette.UI_TEXT) if not narr else Color(0.6, 0.55, 0.75)
	_panel.neoul = who == "neoul" or who == "neoul_god"
	_panel.narration = narr
	_portrait.visible = not narr
	_portrait.set_speaker(who, expr)
	var name_text := Characters.display_name(who)
	if who == "neoul" and _neoul_note < 2:
		name_text += "  (세라에게만 들린다)"
		_neoul_note += 1
	_name.text = name_text
	_name.label_settings.font_color = info.get("color", Palette.GOLD)
	_name.visible = not narr
	if narr:
		_text.position = PANEL.position + Vector2(24, 18)
		_text.size = Vector2(PANEL.size.x - 48, 60)
		_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		_name.position = PANEL.position + Vector2(90, 6)
		_text.position = PANEL.position + Vector2(90, 24)
		_text.size = Vector2(PANEL.size.x - 102, 58)
		_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_text.text = text
	_total = text.length()
	_shown = 0.0
	_text.visible_characters = 0
	_typing = true
	_waiting = true
	_voice = float(info.get("voice", 1.0))
	_portrait.talking = true
	_panel.done = false
	await advanced


## 고르기: 대사 아래 선택지. 고른 번호를 돌려줌
func choose(options: Array) -> int:
	_choices.items.clear()
	for o in options:
		_choices.items.append(String(o))
	_choices.selected = 0
	_choices.position = PANEL.position + Vector2(PANEL.size.x - 200, -18.0 * options.size() - 10)
	_choices.size = Vector2(190, 18.0 * options.size())
	_choices.visible = true
	_panel.choice_rect = Rect2(_choices.position + Vector2(-20, -6), _choices.size + Vector2(30, 10))
	_choice_result = -1
	await _choices.chosen
	_choices.visible = false
	_panel.choice_rect = Rect2()
	return _choice_result


func _on_choice(i: int) -> void:
	_choice_result = i


func close() -> void:
	_root.visible = false
	_waiting = false


func _process(delta: float) -> void:
	if not _root.visible:
		return
	if _typing:
		var before := int(_shown)
		var real := delta / maxf(Engine.time_scale, 0.0001) if not get_tree().paused else delta
		_shown += real * CPS
		var now := int(_shown)
		# 문장 부호에서 잠깐 멈춤
		if now > before and before < _total and _text.text[before] in [".", "!", "?", "…", ","]:
			_shown = before + 0.6 if _shown - before < 1.0 else _shown
		if now > before and _voice > 0.0:
			for i in range(before, mini(now, _total)):
				var ch := _text.text[i]
				if ch != " " and ch != "\n":
					_blip_acc += 1
					if _blip_acc % 2 == 0:
						Sfx.play_pitch(&"blip", _voice * randf_range(0.95, 1.05), -14.0)
		_text.visible_characters = mini(int(_shown), _total)
		if _shown >= _total:
			_typing = false
			_portrait.talking = false
			_panel.done = true


func _input(event: InputEvent) -> void:
	if not _root.visible or not _waiting:
		return
	if _choices.visible:
		if _choices.handle_input(event):
			get_viewport().set_input_as_handled()
		return
	var ok := event.is_action_pressed("jump") or event.is_action_pressed("attack") or event.is_action_pressed("ui_accept")
	if not ok or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	if _typing:
		_shown = _total
		_text.visible_characters = _total
		_typing = false
		_portrait.talking = false
		_panel.done = true
	else:
		Sfx.play(&"ui_move", -10.0, 0.0)
		advanced.emit()


class PanelDraw extends Control:
	var color := Color.WHITE
	var neoul := false
	var narration := false
	var done := false
	var choice_rect := Rect2()
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var r := DialogueBox.PANEL
		var bg := Color(0.035, 0.03, 0.07, 0.93) if not neoul else Color(0.02, 0.05, 0.1, 0.94)
		draw_rect(r, bg)
		var edge := Color(color, 0.9)
		draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), edge)
		draw_rect(Rect2(r.position + Vector2(0, r.size.y - 1), Vector2(r.size.x, 1)), Color(edge, 0.4))
		draw_rect(Rect2(r.position, Vector2(1, r.size.y)), Color(edge, 0.5))
		draw_rect(Rect2(r.position + Vector2(r.size.x - 1, 0), Vector2(1, r.size.y)), Color(edge, 0.5))
		if neoul:
			# 푸른 여우불이 테두리를 따라 일렁임
			for i in 8:
				var x := r.position.x + fmod(_t * 40.0 + i * 80.0, r.size.x)
				draw_rect(Rect2(x, r.position.y - 2, 3, 2), Color(0.6, 0.85, 1.0, 0.6))
		if done:
			var y := r.end.y - 10 + sin(_t * 6.0) * 1.5
			draw_colored_polygon(PackedVector2Array([Vector2(r.end.x - 16, y - 3), Vector2(r.end.x - 8, y - 3), Vector2(r.end.x - 12, y + 2)]), Color(color, 0.9))
		if choice_rect.size != Vector2.ZERO:
			draw_rect(choice_rect, Color(0.035, 0.03, 0.07, 0.95))
			draw_rect(Rect2(choice_rect.position, Vector2(choice_rect.size.x, 1)), edge)
