class_name TeachPrompt
extends CanvasLayer
## 멈춤 조작 안내 (docs/chapter1.md 4.4절): 게임을 멈추고 키 그림 + 설명을 보여 준다.
## 안내한 키를 누르면 풀리고, 그 동작이 바로 이어서 실행된다(세라 쪽 입력 버퍼).

signal answered(action: String)

const KEY_LABEL := {
	"move": "← →", "move_left": "←", "move_right": "→", "jump": "Z", "attack": "X", "dash": "C",
	"skill_1": "A", "skill_2": "S", "skill_3": "F", "fox_window": "D", "potion": "Q", "move_up": "↑", "move_down": "↓",
	"map": "Tab", "pause": "Esc",
}
const PAD_LABEL := {
	"move": "스틱", "move_left": "←", "move_right": "→", "jump": "A", "attack": "X", "dash": "B",
	"skill_1": "LB", "skill_2": "RB", "skill_3": "R3", "fox_window": "Y", "potion": "LT", "move_up": "위", "move_down": "아래",
	"map": "Back", "pause": "Start",
}

var _root: Control
var _draw: PromptDraw
var _wait: Array = []
var _active := false
var _opened_at := 0


func _ready() -> void:
	layer = 45
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_draw = PromptDraw.new()
	_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_draw)
	_root.visible = false


func is_active() -> bool:
	return _active


## 풀리려면 눌러야 하는 동작들 (터치 버튼을 깜빡여 알려 줌)
func wanted() -> Array:
	return _wait if _active else []


## keys: 보여 줄 동작 이름들, wait: 눌러야 풀리는 동작(비우면 keys와 같음). 누른 동작 이름을 돌려줌
func ask(title: String, text: String, keys: Array, wait: Array = []) -> String:
	_wait = wait if not wait.is_empty() else keys
	_draw.title = title
	_draw.text = text
	_draw.keys = []
	for k in keys:
		if TouchControls.active:
			_draw.keys.append([TouchControls.TOUCH_LABEL.get(k, k), ""])
		else:
			_draw.keys.append([KEY_LABEL.get(k, k), PAD_LABEL.get(k, "")])
	_draw.t = 0.0
	_root.visible = true
	_active = true
	_opened_at = Fx.now_ms()
	get_tree().paused = true
	Sfx.play(&"teach", -4.0, 0.0)
	var got: String = await answered
	return got


func _input(event: InputEvent) -> void:
	if not _active or event.is_echo():
		return
	if Fx.now_ms() - _opened_at < 350:
		return # 실수로 바로 넘어가지 않게
	for a in _wait:
		var hit := false
		if a == "move":
			hit = event.is_action_pressed("move_left") or event.is_action_pressed("move_right")
		elif InputMap.has_action(a):
			hit = event.is_action_pressed(a)
		if hit:
			get_viewport().set_input_as_handled()
			_active = false
			_root.visible = false
			get_tree().paused = false
			var w := World.get_world()
			if w:
				w.player.buffer_action(a)
			answered.emit(a)
			return


class PromptDraw extends Control:
	var title := ""
	var text := ""
	var keys: Array = []
	var t := 0.0
	var _font: Font

	func _ready() -> void:
		_font = ThemeDB.fallback_font

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(0, 0, 640, 360), Color(0.02, 0.01, 0.05, 0.35))
		var lines := text.split("\n")
		var h := 52.0 + lines.size() * 16.0
		var w := 360.0
		var pop := clampf(t * 6.0, 0.0, 1.0)
		var r := Rect2(320 - w * 0.5, 120 - h * 0.5 + (1.0 - pop) * 8.0, w, h)
		draw_rect(r, Color(0.035, 0.03, 0.07, 0.95 * pop))
		draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color(Palette.GOLD, pop))
		draw_rect(Rect2(r.position + Vector2(0, r.size.y - 1), Vector2(r.size.x, 1)), Color(Palette.GOLD, 0.4 * pop))
		draw_string(_font, r.position + Vector2(12, 16), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(Palette.GOLD, pop))
		# 키 모양 상자
		var x := r.position.x + 12
		var y := r.position.y + 24
		for k in keys:
			var label := String(k[0])
			var kw := maxf(_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 12, 20)
			var press := 1.0 if fmod(t, 1.0) < 0.15 else 0.0
			draw_rect(Rect2(x, y + press, kw, 18), Color("#e8e0f0"))
			draw_rect(Rect2(x, y + 15 + press, kw, 3), Color("#8a80a0"))
			draw_string(_font, Vector2(x + 6, y + 13 + press), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#1a1428"))
			x += kw + 4
			if String(k[1]) != "":
				draw_string(_font, Vector2(x, y + 13), "(패드 " + String(k[1]) + ")", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_DIM)
				x += _font.get_string_size("(패드 " + String(k[1]) + ")", HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 10
		for i in lines.size():
			draw_string(_font, r.position + Vector2(12, 60 + i * 16), lines[i], HORIZONTAL_ALIGNMENT_LEFT, w - 24, 12, Color(Palette.UI_TEXT, pop))
