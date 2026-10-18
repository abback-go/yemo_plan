class_name TSetup
extends Control
## 편성 화면: 마녀 3명 탭 · 왼쪽에 고른 마녀의 큰 그림과 능력치 · 오른쪽에 배운 마법 10개(눌러서 장착, 최대 5) · 아래에 장비 4칸 · 전투 시작.
## 장착 상태는 static state에 남아 전투 → 편성을 오가도 유지된다. 키보드: ←→ 마녀/장비 · ↑↓ 줄 · Z 장착/시작 · X 나가기.

signal start_pressed
signal exit_pressed

const PALE := Color("#e6dcff")
const LAV := Color("#b9a2ff")
const INK := Color("#14081f")
const GOLD := Color("#ffe08a")
const FIRE := Color("#ff8a3a")
const DIM := Color("#8a7fa3")
const PANEL := Color("#1a1226")
const ROW_H := 22.0
const LIST_X := 214.0
const LIST_Y := 54.0
const LIST_W := 414.0
const EQUIP_Y := 290.0
const START_RECT := Rect2(520, 316, 108, 30)
const EQUIP_IDS := ["", "black_cup", "kaleido", "notebook"]

static var state := {} ## 마녀 id → {"equipped": [id...], "equip": 장비 id}

var tab := 0
var cursor := 0 ## -1 탭 · 0~9 마법 · 10 장비 · 11 시작
var _font: Font
var _t := 0.0
var _preview: Node2D
var _actors: Array[TActor] = []
var _msg := ""
var _msg_t := 0.0


static func ensure_state() -> void:
	for wid in TData.BATTLE.party:
		if not state.has(wid):
			var d: Array[String] = []
			for s in TData.WITCHES[wid].default:
				d.append(String(s))
			state[wid] = {"equipped": d, "equip": ""}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = get_theme_default_font()
	if _font == null:
		_font = ThemeDB.fallback_font
	ensure_state()
	_preview = Node2D.new()
	add_child(_preview)
	for wid in TData.BATTLE.party:
		var u := TUnit.make_witch(String(wid), state[wid], 0)
		var a := TActor.new()
		_preview.add_child(a)
		a.setup(u, Vector2(104, 262))
		a.scale = Vector2(3.2, 3.2)
		a.z_index = 0
		a.visible = false
		_actors.append(a)
	_show_tab()


func _show_tab() -> void:
	for i in _actors.size():
		_actors[i].visible = i == tab
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	size = get_viewport_rect().size # 캔버스 층 아래 Control은 앵커로 화면 크기를 못 받는다
	_msg_t = maxf(_msg_t - delta, 0.0)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_inside_tree():
		if visible:
			_show_tab()


func _wid() -> String:
	return String(TData.BATTLE.party[tab])


func _equipped() -> Array:
	return state[_wid()].equipped


func _row_rect(i: int) -> Rect2:
	return Rect2(LIST_X, LIST_Y + ROW_H * float(i), LIST_W, ROW_H - 2.0)


func _tab_rect(i: int) -> Rect2:
	return Rect2(12 + 64 * i, 8, 60, 22)


func _equip_rect(i: int) -> Rect2:
	return Rect2(LIST_X + 100.0 * float(i), EQUIP_Y, 96, 22)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_tap(event.position)
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION:
			_tap(event.position)
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("es_down"):
		cursor = mini(cursor + 1, 11)
		Sfx.play(&"tn_select", -12.0)
	elif event.is_action_pressed("es_up"):
		cursor = maxi(cursor - 1, -1)
		Sfx.play(&"tn_select", -12.0)
	elif event.is_action_pressed("es_right") or event.is_action_pressed("es_left"):
		var d := 1 if event.is_action_pressed("es_right") else -1
		if cursor == 10:
			var i := EQUIP_IDS.find(String(state[_wid()].equip))
			state[_wid()].equip = EQUIP_IDS[(i + d + EQUIP_IDS.size()) % EQUIP_IDS.size()]
		else:
			tab = (tab + d + 3) % 3
			_show_tab()
		Sfx.play(&"tn_select", -12.0)
	elif event.is_action_pressed("es_jump"):
		if cursor == 11:
			_start()
		elif cursor >= 0 and cursor <= 9:
			_toggle(cursor)
		elif cursor == 10:
			var i := EQUIP_IDS.find(String(state[_wid()].equip))
			state[_wid()].equip = EQUIP_IDS[(i + 1) % EQUIP_IDS.size()]
			Sfx.play(&"tn_select", -10.0)
		elif cursor == -1:
			tab = (tab + 1) % 3
			_show_tab()
	elif event.is_action_pressed("es_exit") or event.is_action_pressed("es_attack"):
		exit_pressed.emit()
	queue_redraw()


func _tap(p: Vector2) -> void:
	if p.distance_to(Vector2(size.x - 16, 16)) < 16.0:
		exit_pressed.emit()
		return
	for i in 3:
		if _tab_rect(i).has_point(p):
			tab = i
			cursor = -1
			Sfx.play(&"tn_select", -10.0)
			_show_tab()
			return
	var skills: Array = TData.WITCHES[_wid()].skills
	for i in skills.size():
		if _row_rect(i).has_point(p):
			cursor = i
			_toggle(i)
			return
	for i in EQUIP_IDS.size():
		if _equip_rect(i).has_point(p):
			state[_wid()].equip = EQUIP_IDS[i]
			cursor = 10
			Sfx.play(&"tn_select", -10.0)
			queue_redraw()
			return
	if START_RECT.has_point(p):
		_start()


func _toggle(i: int) -> void:
	var skills: Array = TData.WITCHES[_wid()].skills
	var sid := String(skills[i])
	var eq: Array = _equipped()
	if eq.has(sid):
		if eq.size() <= 1:
			_say("마법은 적어도 하나 장착해야 합니다")
			return
		eq.erase(sid)
		Sfx.play(&"tn_cancel", -10.0)
	else:
		if eq.size() >= TData.EQUIP_MAX:
			_say("장착은 최대 %d개 — 하나를 빼고 넣으세요" % TData.EQUIP_MAX)
			Sfx.play(&"tn_cancel", -8.0)
			return
		eq.append(sid)
		Sfx.play(&"tn_select", -8.0)
	queue_redraw()


func _say(s: String) -> void:
	_msg = s
	_msg_t = 1.8


func _start() -> void:
	Sfx.play(&"tn_confirm", -4.0)
	start_pressed.emit()


func _text(p: Vector2, s: String, fs: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, w := -1) -> void:
	draw_string_outline(_font, p, s, align, w, fs, 3, Color(INK, 0.9 * col.a))
	draw_string(_font, p, s, align, w, fs, col)


func _draw() -> void:
	# 바탕
	draw_rect(Rect2(0, 0, size.x, size.y), Color("#0e0916", 0.96))
	draw_rect(Rect2(0, 40, 200, 300), Color(PANEL, 0.9))
	draw_rect(Rect2(LIST_X - 8, 40, LIST_W + 16, 236), Color(PANEL, 0.9))
	draw_rect(Rect2(LIST_X - 8, 282, LIST_W + 16, 30 + 36), Color(PANEL, 0.9))
	# 탭
	for i in 3:
		var r := _tab_rect(i)
		var wid := String(TData.BATTLE.party[i])
		var on := i == tab
		var col: Color = TData.WITCHES[wid].color
		draw_rect(r, Color(col, 0.9) if on else Color(INK, 0.7))
		draw_rect(r, Color(PALE if on else DIM, 0.9 if on or cursor == -1 else 0.4), false, 1.0)
		draw_string(_font, Vector2(r.position.x, r.position.y + 15), String(TData.WITCHES[wid].name), HORIZONTAL_ALIGNMENT_CENTER, int(r.size.x), 11, INK if on else PALE)
	_text(Vector2(210, 24), "편성 — 마법 5개 장착 · 장비 1개 · 전투 시작", 11, Color(DIM, 0.9))
	# 왼쪽: 마녀 소개·능력치 (그림은 _preview 노드가 그린다)
	var wid := _wid()
	var w: Dictionary = TData.WITCHES[wid]
	_text(Vector2(100, 56), String(w.name), 14, PALE, HORIZONTAL_ALIGNMENT_CENTER, 0)
	_text(Vector2(100, 70), String(w.title), 9, Color(w.color, 1.0), HORIZONTAL_ALIGNMENT_CENTER, 0)
	var eq: Dictionary = TData.EQUIPS.get(String(state[wid].equip), {})
	var atk := int(round(float(w.atk) * (1.0 + float(eq.get("atk", 0.0)))))
	var lines := ["공격력 %s" % TData.fmt(atk), "체력 %s" % TData.fmt(int(w.hp)), "속도 %d · 방어 %d%%" % [int(w.speed), int(round(float(w.def) * 100.0))],
		"속성 %s%s" % [TData.ELEMENT_NAME.get(w.element, w.element), " (무상성 1.2배)" if bool(w.special) else ""]]
	for i in lines.size():
		_text(Vector2(100, 290 + 12 * i), lines[i], 9, Color(PALE, 0.85), HORIZONTAL_ALIGNMENT_CENTER, 0)
	# 오른쪽: 마법 목록
	var skills: Array = w.skills
	var equipped: Array = _equipped()
	_text(Vector2(LIST_X, 48), "배운 마법 — 눌러서 장착  (%d/%d)" % [equipped.size(), TData.EQUIP_MAX], 10, Color(PALE, 0.9))
	for i in skills.size():
		var sid := String(skills[i])
		var s := TData.skill(sid)
		var r := _row_rect(i)
		var on := equipped.has(sid)
		var cur := cursor == i
		var is_attack := String(s.kind) == "attack"
		draw_rect(r, Color(LAV, 0.22) if on else Color(INK, 0.5))
		if cur:
			draw_rect(r, Color(PALE, 0.9), false, 1.0)
		elif on:
			draw_rect(r, Color(LAV, 0.5), false, 1.0)
		# 장착 번호
		if on:
			var idx := equipped.find(sid) + 1
			draw_circle(r.position + Vector2(10, 10), 7.0, LAV)
			draw_string(_font, r.position + Vector2(6.5, 14), str(idx), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, INK)
		else:
			draw_arc(r.position + Vector2(10, 10), 6.0, 0.0, TAU, 16, Color(DIM, 0.5), 1.0)
		# 비용 점
		for j in int(s.cost):
			var q := r.position + Vector2(26 + float(j) * 6.0, 10)
			draw_circle(q, 2.2, Color(INK, 0.9))
			draw_circle(q, 1.7, GOLD)
		# 이름 (공격은 주홍, 보조는 라벤더)
		_text(r.position + Vector2(60, 14), String(s.name), 11, FIRE if is_attack else LAV)
		draw_string(_font, r.position + Vector2(126, 14), String(s.desc), HORIZONTAL_ALIGNMENT_LEFT, int(r.size.x - 132), 8, Color(PALE, 0.85 if on else 0.6))
	# 장비
	_text(Vector2(LIST_X, 286), "장비 (1개)", 10, Color(PALE, 0.9))
	for i in EQUIP_IDS.size():
		var r := _equip_rect(i)
		var eid: String = EQUIP_IDS[i]
		var on := String(state[wid].equip) == eid
		draw_rect(r, Color(GOLD, 0.25) if on else Color(INK, 0.5))
		draw_rect(r, Color(GOLD if on else DIM, 0.9 if on or cursor == 10 else 0.4), false, 1.0)
		draw_string(_font, Vector2(r.position.x, r.position.y + 15), String(TData.EQUIPS[eid].name), HORIZONTAL_ALIGNMENT_CENTER, int(r.size.x), 10, PALE if on else Color(PALE, 0.7))
	_text(Vector2(LIST_X, 326), String(eq.get("desc", "")), 9, Color(GOLD, 0.9))
	# 시작 버튼
	var pulse := 0.8 + 0.2 * sin(_t * 4.0)
	draw_rect(START_RECT, Color(LAV, 0.9 if cursor == 11 else 0.7 * pulse))
	draw_rect(START_RECT, Color(PALE, 0.9), false, 1.0)
	draw_string(_font, Vector2(START_RECT.position.x, START_RECT.position.y + 20), "전투 시작", HORIZONTAL_ALIGNMENT_CENTER, int(START_RECT.size.x), 13, INK)
	# 나가기 X
	draw_circle(Vector2(size.x - 16, 16), 11.0, Color(INK, 0.5))
	draw_arc(Vector2(size.x - 16, 16), 11.0, 0.0, TAU, 24, Color(LAV, 0.6), 1.0)
	_text(Vector2(size.x - 16, 20), "X", 11, Color(PALE, 0.8), HORIZONTAL_ALIGNMENT_CENTER, 0)
	# 안내·메시지
	if _msg_t > 0.0:
		_text(Vector2(LIST_X, 344), _msg, 10, Color(FIRE, minf(_msg_t, 1.0)))
	else:
		_text(Vector2(LIST_X, 344), "적: 짚 골렘(불 약점) · 늪 두꺼비 · 재의 기사", 9, Color(DIM, 0.9))
