class_name PPanel
extends Control
## 시험 패널 (Tab). 게임을 멈추고 값을 바꿔 가며 비교한다. ↑↓ 고르기 · ←→ 바꾸기 · Z/Enter 실행 · Tab 닫기.

var sera: PSera
var _sel := 0
var _font: Font
var _rows: Array = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_font = ThemeDB.fallback_font
	_build()


func _build() -> void:
	_rows = [
		["회피술 (공중 대시 + 무적)", "evade"], ["꼬리 수 (변신 시간·발톱·집중 속도)", "tails"], ["마나 최대 칸", "mana_max"],
		["마나 무한", "infinite_mana"], ["쿨타임 없음", "no_cooldown"], ["▶ 변신 게이지 가득 채우기", "fill_gauge"],
		["▶ 마나 가득", "fill_mana"], ["난이도", "difficulty"], ["연습용 발사대 (맞는 연습)", "launcher_on"], ["피해 숫자", "damage_numbers"],
		["모든 마법 레벨", "all_lv"],
	]
	for s: Dictionary in PData.SPELLS:
		_rows.append(["  %s Lv (최고 = 각성)" % s.name, "lv:" + String(s.id)])
	_rows.append(["▶ 체력·물약 회복", "heal"])


func toggle() -> void:
	visible = not visible
	get_tree().paused = visible
	Sfx.play(&"menu_open" if visible else &"menu_close", -6.0)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pr_panel"):
		toggle()
		return
	if not visible:
		return
	if Input.is_action_just_pressed("pr_down"):
		_sel = (_sel + 1) % _rows.size()
		Sfx.play(&"ui_move", -10.0)
	elif Input.is_action_just_pressed("pr_up"):
		_sel = (_sel - 1 + _rows.size()) % _rows.size()
		Sfx.play(&"ui_move", -10.0)
	elif Input.is_action_just_pressed("pr_right"):
		_change(1)
	elif Input.is_action_just_pressed("pr_left"):
		_change(-1)
	elif Input.is_action_just_pressed("pr_jump") or Input.is_action_just_pressed("ui_accept"):
		_change(1)
	queue_redraw()


func _change(d: int) -> void:
	var key: String = _rows[_sel][1]
	match key:
		"evade":
			PState.evade = not PState.evade
		"tails":
			PState.tails = clampi(PState.tails + d, 1, 9)
		"mana_max":
			PState.mana_max = clampi(PState.mana_max + d, 3, 5)
		"infinite_mana":
			PState.infinite_mana = not PState.infinite_mana
		"no_cooldown":
			PState.no_cooldown = not PState.no_cooldown
		"fill_gauge":
			sera.gauge = 1.0
		"fill_mana":
			sera.mana = float(PState.mana_max)
		"difficulty":
			PState.difficulty = (PState.difficulty + d + 3) % 3
		"launcher_on":
			PState.launcher_on = not PState.launcher_on
		"damage_numbers":
			PState.damage_numbers = not PState.damage_numbers
		"all_lv":
			var to_max := PState.level("fireball") < 4
			for s: Dictionary in PData.SPELLS:
				PState.levels[s.id] = int(s.max_lv) if to_max else 1
		"heal":
			sera.hp2 = PData.MAX_HEARTS * 2
			sera.potions = sera.potions_max
		_:
			if key.begins_with("lv:"):
				var id := key.substr(3)
				var mx := int(PData.spell(id).max_lv)
				PState.levels[id] = clampi(PState.level(id) + d, 1, mx)
	Sfx.play(&"ui_ok", -8.0)


func _value(key: String) -> String:
	match key:
		"evade":
			return "배움" if PState.evade else "아직"
		"tails":
			return "%d개" % PState.tails
		"mana_max":
			return "%d칸" % PState.mana_max
		"infinite_mana":
			return "켬" if PState.infinite_mana else "끔"
		"no_cooldown":
			return "켬" if PState.no_cooldown else "끔"
		"difficulty":
			return ["쉬움", "보통", "어려움"][PState.difficulty]
		"launcher_on":
			return "켬" if PState.launcher_on else "끔"
		"damage_numbers":
			return "켬" if PState.damage_numbers else "끔"
		"all_lv":
			return "최고로" if PState.level("fireball") < 4 else "1로"
	if key.begins_with("lv:"):
		var id := key.substr(3)
		var lv := PState.level(id)
		return "Lv%d%s" % [lv, " 각성" if PState.awakened(id) else ""]
	return ""


func _draw() -> void:
	if not visible:
		return
	draw_rect(Rect2(0, 0, 640, 360), Color(0.02, 0.01, 0.05, 0.72))
	var x := 150.0
	var y := 20.0
	draw_rect(Rect2(x - 12, y - 12, 364, _rows.size() * 14 + 40), Color(0.08, 0.05, 0.14, 0.95))
	draw_rect(Rect2(x - 12, y - 12, 364, _rows.size() * 14 + 40), Color("#ffb347"), false, 1.0)
	draw_string(_font, Vector2(x, y + 4), "시험 패널", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#ffd27a"))
	draw_string(_font, Vector2(x + 120, y + 4), "↑↓ 고르기 · ←→ 바꾸기 · Tab 닫기", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.6))
	for i in _rows.size():
		var row: Array = _rows[i]
		var ry := y + 22 + i * 14
		if i == _sel:
			draw_rect(Rect2(x - 6, ry - 10, 352, 13), Color(1, 0.7, 0.3, 0.22))
		draw_string(_font, Vector2(x, ry), String(row[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.92))
		draw_string(_font, Vector2(x + 250, ry), _value(String(row[1])), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#ffd27a"))
