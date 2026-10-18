class_name TSetup
extends Control
## 편성 화면 — 두 단계 (2026-10-18 사용자 지시).
## 1단계 편성: 왼쪽에 **세로로 긴 파티 카드 3장**(앞·중·뒤) — 큰 그림·이름·속성·능력치·**장비 고르기(◀ ▶)**·"마법 장착" 버튼.
##             오른쪽에 12명 명단(작은 초상 4×3): 카드를 누르고 명단의 마녀를 누르면 그 자리에 들어간다(이미 파티에 있으면 자리를 맞바꿈). 전투 시작.
## 2단계 마법: 위에 파티원 탭 3개 · 왼쪽 큰 그림 + 능력치 · 가운데 배운 마법 10개 목록(한 번 누르면 설명, 다시 누르면 장착, 최대 5) ·
##             오른쪽 큰 설명 상자(이름·비용·종류·대상·배율·효과·항목별 수치·참고 구조·예상 피해) · 전투 시작 / 편성으로.
## 장착·파티·장비는 static state에 남아 전투 → 편성을 오가도 유지된다.
## 키보드 1단계: ←→ 카드 · ↑↓ 그 자리의 마녀 바꾸기 · X 장비 바꾸기 · Z 마법 장착 · S 전투 시작 · Esc 나가기.  2단계: ↑↓ 줄 · ←→ 탭 · Z 장착 · S 시작 · X 편성으로.

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
const LIST_X := 152.0
const LIST_Y := 46.0
const LIST_W := 226.0
const DESC_X := 386.0
const DESC_W := 242.0
const START_RECT := Rect2(520, 322, 108, 30) ## 2단계 전투 시작
const BACK_RECT := Rect2(152, 322, 80, 30) ## 2단계 편성으로
const START1_RECT := Rect2(404, 300, 224, 32) ## 1단계 전투 시작
const EQUIP_IDS := ["", "black_cup", "kaleido", "notebook"]
const CARD_W := 122.0
const CARD_H := 300.0
const CARD_Y := 36.0
const ROSTER_X := 404.0
const ROSTER_Y := 40.0
const SLOT_NAME := ["앞", "중", "뒤"]

static var state := {} ## "party": [id, id, id] · 마녀 id → {"equipped": [id...], "equip": 장비 id}

var step := 1 ## 1 편성(카드) · 2 마법
var tab := 0 ## 2단계: 파티원 번호
var cursor := 0 ## 2단계: -1 탭 · 0~9 마법 · 10 시작
var active := 0 ## 1단계: 고른 카드(자리) 0~2
var _font: Font
var _t := 0.0
var _preview: Node2D
var _actors := {} ## 마녀 id → TActor (명단의 작은 그림)
var _big := {} ## 마녀 id → TActor (카드·상세의 큰 그림)
var _msg := ""
var _msg_t := 0.0


static func ensure_state() -> void:
	if not state.has("party"):
		var p: Array = []
		for w in TData.BATTLE.party:
			p.append(String(w))
		state["party"] = p
	for wid in TData.ROSTER:
		if not state.has(wid):
			var d: Array[String] = []
			for s in TData.WITCHES[wid].default:
				d.append(String(s))
			state[wid] = {"equipped": d, "equip": ""}


static func party() -> Array:
	ensure_state()
	return state.party


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = get_theme_default_font()
	if _font == null:
		_font = ThemeDB.fallback_font
	ensure_state()
	_preview = Node2D.new()
	add_child(_preview)
	for wid in TData.ROSTER:
		for big in [false, true]:
			var u := TUnit.make_witch(String(wid), state[wid], 0)
			var a := TActor.new()
			_preview.add_child(a)
			a.setup(u, Vector2.ZERO)
			a.z_index = 0
			if big:
				_big[wid] = a
			else:
				_actors[wid] = a
	_layout_actors()


## 단계에 맞게 그림을 놓는다 (1단계: 명단은 작게, 파티 3명은 카드에 크게 · 2단계: 고른 파티원만 아주 크게)
func _layout_actors() -> void:
	if _actors.is_empty():
		return
	var p: Array = party()
	for i in TData.ROSTER.size():
		var wid: String = TData.ROSTER[i]
		var a: TActor = _actors[wid]
		var b: TActor = _big[wid]
		var slot := p.find(wid)
		if step == 1:
			var r := _roster_rect(i)
			a.visible = true
			a.home = r.position + Vector2(r.size.x * 0.5, r.size.y - 14.0)
			a.scale = Vector2(1.15, 1.15)
			b.visible = slot >= 0
			if slot >= 0:
				var c := _card_rect(slot)
				b.home = c.position + Vector2(c.size.x * 0.5, 196.0)
				b.scale = Vector2(2.6, 2.6)
		else:
			a.visible = false
			b.visible = slot == tab
			b.home = Vector2(76, 262)
			b.scale = Vector2(3.0, 3.0)
		a.position = a.home
		b.position = b.home
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	size = get_viewport_rect().size # 캔버스 층 아래 Control은 앵커로 화면 크기를 못 받는다
	_msg_t = maxf(_msg_t - delta, 0.0)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_inside_tree() and visible:
		_layout_actors()


func _wid() -> String:
	var p := party()
	if p.is_empty():
		return String(TData.ROSTER[0])
	return String(p[clampi(tab, 0, p.size() - 1)])


func _equipped() -> Array:
	return state[_wid()].equipped


## 1단계 파티 카드 (세로로 긴 직사각형) 자리 i = 앞·중·뒤
func _card_rect(i: int) -> Rect2:
	return Rect2(12 + 130 * i, CARD_Y, CARD_W, CARD_H)


## 카드 안 장비 고르기 띠
func _equip_chip(i: int) -> Rect2:
	var c := _card_rect(i)
	return Rect2(c.position.x + 6, c.position.y + 242, c.size.x - 12, 22)


## 카드 안 "마법 장착" 버튼
func _magic_btn(i: int) -> Rect2:
	var c := _card_rect(i)
	return Rect2(c.position.x + 6, c.position.y + 270, c.size.x - 12, 24)


## 오른쪽 명단 칸 (12명, 4×3)
func _roster_rect(i: int) -> Rect2:
	return Rect2(ROSTER_X + 56 * (i % 4), ROSTER_Y + 74 * (i / 4), 52, 70)


func _row_rect(i: int) -> Rect2:
	return Rect2(LIST_X, LIST_Y + ROW_H * float(i), LIST_W, ROW_H - 2.0)


func _tab_rect(i: int) -> Rect2:
	return Rect2(12 + 46 * i, 8, 44, 22)


# ═══════════════════════════════════════════════════════════
# 입력
# ═══════════════════════════════════════════════════════════

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
	if step == 1:
		_key_roster(event)
	else:
		_key_detail(event)
	queue_redraw()


func _key_roster(event: InputEvent) -> void:
	if event.is_action_pressed("es_right"):
		active = (active + 1) % 3
	elif event.is_action_pressed("es_left"):
		active = (active + 2) % 3
	elif event.is_action_pressed("es_down") or event.is_action_pressed("es_up"):
		_cycle_slot(active, 1 if event.is_action_pressed("es_down") else -1)
	elif event.is_action_pressed("es_attack"):
		_cycle_equip(active, 1)
	elif event.is_action_pressed("es_jump"):
		_go_detail(active)
	elif event.is_action_pressed("es_bind"):
		_start()
	elif event.is_action_pressed("es_exit"):
		exit_pressed.emit()
	else:
		return
	Sfx.play(&"tn_select", -12.0)


func _key_detail(event: InputEvent) -> void:
	if event.is_action_pressed("es_down"):
		cursor = mini(cursor + 1, 10)
	elif event.is_action_pressed("es_up"):
		cursor = maxi(cursor - 1, -1)
	elif event.is_action_pressed("es_right") or event.is_action_pressed("es_left"):
		var d := 1 if event.is_action_pressed("es_right") else -1
		tab = (tab + d + party().size()) % party().size()
		_layout_actors()
	elif event.is_action_pressed("es_jump"):
		if cursor == 10:
			_start()
		elif cursor >= 0 and cursor <= 9:
			_toggle(cursor)
		elif cursor == -1:
			tab = (tab + 1) % party().size()
			_layout_actors()
	elif event.is_action_pressed("es_bind"):
		_start()
	elif event.is_action_pressed("es_exit") or event.is_action_pressed("es_attack"):
		_go_roster()
	else:
		return
	Sfx.play(&"tn_select", -12.0)


func _tap(p: Vector2) -> void:
	if p.distance_to(Vector2(size.x - 16, 16)) < 16.0:
		if step == 2:
			_go_roster()
		else:
			exit_pressed.emit()
		return
	if step == 1:
		for i in 3:
			var chip := _equip_chip(i)
			if chip.has_point(p):
				active = i
				_cycle_equip(i, -1 if p.x < chip.position.x + 18.0 else 1)
				return
			if _magic_btn(i).has_point(p):
				_go_detail(i)
				return
			if _card_rect(i).has_point(p):
				if active != i:
					active = i
					Sfx.play(&"tn_select", -12.0)
				queue_redraw()
				return
		for i in 12:
			if _roster_rect(i).has_point(p):
				_assign(active, String(TData.ROSTER[i]))
				return
		if START1_RECT.has_point(p):
			_start()
		return
	for i in party().size():
		if _tab_rect(i).has_point(p):
			tab = i
			cursor = -1
			Sfx.play(&"tn_select", -10.0)
			_layout_actors()
			return
	var skills: Array = TData.WITCHES[_wid()].skills
	for i in skills.size():
		if _row_rect(i).has_point(p):
			if cursor == i:
				_toggle(i) # 두 번째 누름: 장착/해제
			else:
				cursor = i # 첫 누름: 설명 보기
				Sfx.play(&"tn_select", -12.0)
			queue_redraw()
			return
	if START_RECT.has_point(p):
		_start()
	elif BACK_RECT.has_point(p):
		_go_roster()


## 자리 slot에 마녀 wid를 넣는다 (이미 다른 자리에 있으면 둘을 맞바꿈)
func _assign(slot: int, wid: String) -> void:
	var p: Array = party()
	var was := p.find(wid)
	if was == slot:
		_go_detail(slot) # 같은 마녀를 다시 누르면 마법 장착으로
		return
	if was >= 0:
		p[was] = p[slot]
	p[slot] = wid
	Sfx.play(&"tn_select", -8.0)
	_say("%s 자리: %s" % [SLOT_NAME[slot], TData.WITCHES[wid].name])
	_layout_actors()


## 자리 slot의 마녀를 명단 순서대로 다음/이전 (파티에 없는 마녀 중에서)
func _cycle_slot(slot: int, d: int) -> void:
	var p: Array = party()
	var i := TData.ROSTER.find(p[slot])
	for k in TData.ROSTER.size():
		i = (i + d + TData.ROSTER.size()) % TData.ROSTER.size()
		var wid := String(TData.ROSTER[i])
		if not p.has(wid):
			p[slot] = wid
			_layout_actors()
			return


func _cycle_equip(slot: int, d: int) -> void:
	var wid := String(party()[slot])
	var i := EQUIP_IDS.find(String(state[wid].equip))
	state[wid].equip = EQUIP_IDS[(i + d + EQUIP_IDS.size()) % EQUIP_IDS.size()]
	Sfx.play(&"tn_select", -10.0)
	_say("%s 장비: %s — %s" % [TData.WITCHES[wid].name, TData.EQUIPS[state[wid].equip].name, TData.EQUIPS[state[wid].equip].desc])
	queue_redraw()


func _go_detail(slot: int) -> void:
	step = 2
	tab = slot
	cursor = 0
	Sfx.play(&"tn_confirm", -8.0)
	_layout_actors()


func _go_roster() -> void:
	step = 1
	active = tab
	cursor = 0
	Sfx.play(&"tn_cancel", -10.0)
	_layout_actors()


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


# ═══════════════════════════════════════════════════════════
# 그림
# ═══════════════════════════════════════════════════════════

## 글자 + 먹 테두리. 오른쪽·가운데 맞춤은 폭이 없으면 글자 폭으로 자리를 옮겨 맞춘다 (Godot은 폭 0이면 맞춤을 무시한다)
func _text(p: Vector2, s: String, fs: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, w := -1) -> void:
	if w <= 0 and align != HORIZONTAL_ALIGNMENT_LEFT:
		var tw := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		p.x -= tw if align == HORIZONTAL_ALIGNMENT_RIGHT else tw * 0.5
		align = HORIZONTAL_ALIGNMENT_LEFT
		w = -1
	draw_string_outline(_font, p, s, align, w, fs, 3, Color(INK, 0.9 * col.a))
	draw_string(_font, p, s, align, w, fs, col)


func _x_button() -> void:
	draw_circle(Vector2(size.x - 16, 16), 11.0, Color(INK, 0.5))
	draw_arc(Vector2(size.x - 16, 16), 11.0, 0.0, TAU, 24, Color(LAV, 0.6), 1.0)
	_text(Vector2(size.x - 16, 20), "X", 11, Color(PALE, 0.8), HORIZONTAL_ALIGNMENT_CENTER, 0)


func _draw() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color("#0e0916", 0.96))
	if step == 1:
		_draw_roster()
	else:
		_draw_detail()
	_x_button()


func _draw_roster() -> void:
	var p: Array = party()
	_text(Vector2(12, 24), "편성 — 카드를 누르고 오른쪽 명단에서 마녀를 고르세요 · 카드 안에서 장비 · 마법 장착", 11, PALE)
	for i in 3:
		_draw_card(i, String(p[i]), i == active)
	# 오른쪽 명단
	_text(Vector2(ROSTER_X, ROSTER_Y - 6), "명단 12명 — 누르면 %s 자리에" % SLOT_NAME[active], 9, Color(DIM, 0.95))
	for i in 12:
		var wid := String(TData.ROSTER[i])
		var w: Dictionary = TData.WITCHES[wid]
		var r := _roster_rect(i)
		var slot := p.find(wid)
		var ecol: Color = TData.ELEMENT_COLOR.get(w.element, LAV)
		draw_rect(r, Color(LAV, 0.2) if slot >= 0 else Color(PANEL, 0.9))
		draw_rect(r, Color(LAV, 0.7) if slot >= 0 else Color(ecol, 0.3), false, 1.0)
		draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color(ecol, 0.9))
		draw_string(_font, Vector2(r.position.x, r.position.y + r.size.y - 3), String(w.name), HORIZONTAL_ALIGNMENT_CENTER, int(r.size.x), 8, PALE if slot >= 0 else Color(PALE, 0.75))
		if slot >= 0:
			var b := r.position + Vector2(r.size.x - 9, 10)
			draw_circle(b, 7.0, LAV)
			draw_string(_font, b + Vector2(-7, 3.5), SLOT_NAME[slot], HORIZONTAL_ALIGNMENT_CENTER, 14, 8, INK)
	# 전투 시작
	var pulse := 0.8 + 0.2 * sin(_t * 4.0)
	draw_rect(START1_RECT, Color(LAV, 0.75 * pulse))
	draw_rect(START1_RECT, Color(PALE, 0.9), false, 1.0)
	draw_string(_font, Vector2(START1_RECT.position.x, START1_RECT.position.y + 21), "전투 시작", HORIZONTAL_ALIGNMENT_CENTER, int(START1_RECT.size.x), 13, INK)
	if _msg_t > 0.0:
		draw_string(_font, Vector2(12, 352), _msg, HORIZONTAL_ALIGNMENT_LEFT, 616, 9, Color(GOLD, minf(_msg_t, 1.0)))
	else:
		_text(Vector2(ROSTER_X, 352), "적: 짚 골렘(불 약점) · 늪 두꺼비(번개 약점) · 재의 기사", 8, Color(DIM, 0.9))


## 파티 카드 한 장: 자리 이름 · 이름 · 속성/역할 · (큰 그림은 _big 노드) · 능력치 · 장비 ◀ ▶ · 마법 장착
func _draw_card(i: int, wid: String, on: bool) -> void:
	var w: Dictionary = TData.WITCHES[wid]
	var r := _card_rect(i)
	var ecol: Color = TData.ELEMENT_COLOR.get(w.element, LAV)
	draw_rect(r, Color(PANEL, 0.95))
	draw_rect(Rect2(r.position, Vector2(r.size.x, 22)), Color(ecol, 0.35 if on else 0.18))
	draw_rect(r, Color(PALE, 0.95) if on else Color(ecol, 0.45), false, 1.5 if on else 1.0)
	draw_rect(Rect2(r.position, Vector2(3, r.size.y)), Color(ecol, 0.9))
	# 머리: 자리 + 이름
	draw_circle(r.position + Vector2(14, 11), 8.0, LAV if on else Color(LAV, 0.6))
	draw_string(_font, r.position + Vector2(6, 15), SLOT_NAME[i], HORIZONTAL_ALIGNMENT_CENTER, 16, 9, INK)
	_text(r.position + Vector2(28, 15), String(w.name), 12, PALE)
	_text(r.position + Vector2(r.size.x * 0.5, 36), "%s · %s" % [TData.ELEMENT_NAME.get(w.element, w.element), TData.ROLE_NAME.get(w.get("role", ""), "")], 9, Color(ecol, 1.0), HORIZONTAL_ALIGNMENT_CENTER, 0)
	# 그림 뒤 빛 (속성 색)
	draw_circle(r.position + Vector2(r.size.x * 0.5, 150), 34.0, Color(ecol, 0.08))
	# 능력치
	var eq: Dictionary = TData.EQUIPS.get(String(state[wid].equip), {})
	var atk := int(round(float(w.atk) * (1.0 + float(eq.get("atk", 0.0)))))
	var lines := ["공격 %s" % TData.fmt(atk), "체력 %s" % TData.fmt(int(w.hp)), "속도 %d · 방어 %d%%" % [int(w.speed), int(round(float(w.def) * 100.0))]]
	for k in lines.size():
		_text(r.position + Vector2(r.size.x * 0.5, 212 + 10 * k), lines[k], 8, Color(PALE, 0.85), HORIZONTAL_ALIGNMENT_CENTER, 0)
	# 장비 ◀ ▶
	var chip := _equip_chip(i)
	var has_eq := String(state[wid].equip) != ""
	draw_rect(chip, Color(GOLD, 0.22) if has_eq else Color(INK, 0.6))
	draw_rect(chip, Color(GOLD if has_eq else DIM, 0.8), false, 1.0)
	draw_colored_polygon(PackedVector2Array([chip.position + Vector2(5, 11), chip.position + Vector2(12, 6), chip.position + Vector2(12, 16)]), Color(PALE, 0.9))
	draw_colored_polygon(PackedVector2Array([chip.position + Vector2(chip.size.x - 5, 11), chip.position + Vector2(chip.size.x - 12, 6), chip.position + Vector2(chip.size.x - 12, 16)]), Color(PALE, 0.9))
	draw_string(_font, Vector2(chip.position.x + 14, chip.position.y + 15), "장비 " + String(TData.EQUIPS[state[wid].equip].name), HORIZONTAL_ALIGNMENT_CENTER, int(chip.size.x - 28), 9, GOLD if has_eq else Color(PALE, 0.8))
	# 마법 장착 버튼 (장착 수)
	var mb := _magic_btn(i)
	var eqd: Array = state[wid].equipped
	draw_rect(mb, Color(LAV, 0.55 if on else 0.35))
	draw_rect(mb, Color(PALE, 0.8), false, 1.0)
	draw_string(_font, Vector2(mb.position.x, mb.position.y + 16), "마법 장착 %d/%d ▶" % [eqd.size(), TData.EQUIP_MAX], HORIZONTAL_ALIGNMENT_CENTER, int(mb.size.x), 10, INK if on else PALE)


func _draw_detail() -> void:
	var p: Array = party()
	var wid := _wid()
	var w: Dictionary = TData.WITCHES[wid]
	var ecol: Color = TData.ELEMENT_COLOR.get(w.element, LAV)
	draw_rect(Rect2(0, 36, 146, 304), Color(PANEL, 0.9))
	draw_rect(Rect2(LIST_X - 6, 36, LIST_W + 12, 236), Color(PANEL, 0.9))
	draw_rect(Rect2(DESC_X - 6, 36, DESC_W + 12, 280), Color(PANEL, 0.9))
	# 탭 (파티원 3)
	for i in p.size():
		var r := _tab_rect(i)
		var twid := String(p[i])
		var on := i == tab
		var col: Color = TData.WITCHES[twid].color
		draw_rect(r, Color(col, 0.9) if on else Color(INK, 0.7))
		draw_rect(r, Color(PALE if on else DIM, 0.9 if on or cursor == -1 else 0.4), false, 1.0)
		draw_string(_font, Vector2(r.position.x, r.position.y + 15), String(TData.WITCHES[twid].name), HORIZONTAL_ALIGNMENT_CENTER, int(r.size.x), 10, INK if on else PALE)
	_text(Vector2(156, 24), "마법 장착 — 배운 마법 10개 중 5개 · 전투 시작", 11, Color(DIM, 0.9))
	# 왼쪽: 소개·능력치
	_text(Vector2(73, 52), String(w.name), 14, PALE, HORIZONTAL_ALIGNMENT_CENTER, 0)
	_text(Vector2(73, 66), String(w.title), 9, Color(ecol, 1.0), HORIZONTAL_ALIGNMENT_CENTER, 0)
	var eq: Dictionary = TData.EQUIPS.get(String(state[wid].equip), {})
	var atk := int(round(float(w.atk) * (1.0 + float(eq.get("atk", 0.0)))))
	var lines := ["공격력 %s" % TData.fmt(atk), "체력 %s" % TData.fmt(int(w.hp)), "속도 %d · 방어 %d%%" % [int(w.speed), int(round(float(w.def) * 100.0))],
		"속성 %s%s" % [TData.ELEMENT_NAME.get(w.element, w.element), " (무상성 1.2배)" if bool(w.special) else ""],
		"기본 공격: %s" % String(w.basic.name)]
	for i in lines.size():
		_text(Vector2(73, 284 + 11 * i), lines[i], 8, Color(PALE, 0.85), HORIZONTAL_ALIGNMENT_CENTER, 0)
	# 가운데: 마법 목록
	var skills: Array = w.skills
	var equipped: Array = _equipped()
	_text(Vector2(LIST_X, 42), "배운 마법 — 누르면 설명, 다시 누르면 장착 (%d/%d)" % [equipped.size(), TData.EQUIP_MAX], 9, Color(PALE, 0.9))
	for i in skills.size():
		var sid := String(skills[i])
		var s := TData.skill(sid)
		var r := _row_rect(i)
		var on := equipped.has(sid)
		var cur := cursor == i
		var kind := String(s.kind)
		var kcol := FIRE if kind == "attack" else (Color("#c9b8c8") if kind == "debuff" else LAV)
		draw_rect(r, Color(LAV, 0.22) if on else Color(INK, 0.5))
		if cur:
			draw_rect(r, Color(PALE, 0.9), false, 1.0)
		elif on:
			draw_rect(r, Color(LAV, 0.5), false, 1.0)
		if on:
			var idx := equipped.find(sid) + 1
			draw_circle(r.position + Vector2(10, 10), 7.0, LAV)
			draw_string(_font, r.position + Vector2(6.5, 14), str(idx), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, INK)
		else:
			draw_arc(r.position + Vector2(10, 10), 6.0, 0.0, TAU, 16, Color(DIM, 0.5), 1.0)
		for j in int(s.cost):
			var q := r.position + Vector2(26 + float(j) * 6.0, 10)
			draw_circle(q, 2.2, Color(INK, 0.9))
			draw_circle(q, 1.7, GOLD)
		_text(r.position + Vector2(62, 14), String(s.name), 11, kcol)
		_text(r.position + Vector2(r.size.x - 6, 14), _kind_label(s), 8, Color(DIM, 0.9), HORIZONTAL_ALIGNMENT_RIGHT, 0)
	# 오른쪽: 큰 설명 상자
	if cursor >= 0 and cursor < skills.size():
		_draw_desc(TData.skill(String(skills[cursor])), String(skills[cursor]))
	else:
		_draw_witch_desc(w)
	# 장비는 편성 카드에서 고른다 — 여기선 보여 주기만
	_text(Vector2(LIST_X, 290), "장비: %s — %s" % [String(TData.EQUIPS[state[wid].equip].name), String(eq.get("desc", "편성 카드에서 고릅니다"))], 8, Color(GOLD, 0.9))
	# 버튼
	draw_rect(BACK_RECT, Color(INK, 0.7))
	draw_rect(BACK_RECT, Color(DIM, 0.8), false, 1.0)
	draw_string(_font, Vector2(BACK_RECT.position.x, BACK_RECT.position.y + 20), "← 편성", HORIZONTAL_ALIGNMENT_CENTER, int(BACK_RECT.size.x), 11, PALE)
	var pulse := 0.8 + 0.2 * sin(_t * 4.0)
	draw_rect(START_RECT, Color(LAV, 0.9 if cursor == 10 else 0.7 * pulse))
	draw_rect(START_RECT, Color(PALE, 0.9), false, 1.0)
	draw_string(_font, Vector2(START_RECT.position.x, START_RECT.position.y + 20), "전투 시작", HORIZONTAL_ALIGNMENT_CENTER, int(START_RECT.size.x), 13, INK)
	if _msg_t > 0.0:
		draw_string(_font, Vector2(240, 348), _msg, HORIZONTAL_ALIGNMENT_LEFT, 270, 9, Color(FIRE, minf(_msg_t, 1.0)))
	else:
		draw_string(_font, Vector2(240, 348), "적: 짚 골렘(불 약점) · 늪 두꺼비(번개 약점) · 재의 기사", HORIZONTAL_ALIGNMENT_LEFT, 270, 8, Color(DIM, 0.9))


func _kind_label(s: Dictionary) -> String:
	var k: String = {"attack": "공격", "support": "보조", "debuff": "디버프"}.get(String(s.kind), "")
	var t: String = {"enemy": "적 1", "enemies": "적 전체", "ally": "아군 1", "ally_any": "아군 1", "allies": "아군 전체", "self": "자신"}.get(String(s.target), "")
	return "%s · %s" % [k, t]


## 큰 설명 상자: 이름 + 비용 점 / 종류 · 대상 · 배율 / 효과(줄바꿈) / 참고 구조
func _draw_desc(s: Dictionary, sid: String) -> void:
	var x := DESC_X
	var y := 44.0
	var kind := String(s.kind)
	var kcol := FIRE if kind == "attack" else (Color("#c9b8c8") if kind == "debuff" else LAV)
	var on := _equipped().has(sid)
	_text(Vector2(x, y + 14), String(s.name), 15, kcol)
	var nx := x + _font.get_string_size(String(s.name), HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 8.0
	for j in int(s.cost):
		draw_circle(Vector2(nx + float(j) * 7.5, y + 9), 3.0, Color(INK, 0.9))
		draw_circle(Vector2(nx + float(j) * 7.5, y + 9), 2.3, GOLD)
	_text(Vector2(x + DESC_W, y + 14), "장착됨" if on else "미장착", 9, Color(LAV if on else DIM, 0.9), HORIZONTAL_ALIGNMENT_RIGHT, 0)
	y += 30
	var line2 := "비용 %d · %s" % [int(s.cost), _kind_label(s)]
	if kind == "attack":
		line2 += " · 배율 ×%.1f" % float(s.mult)
	_text(Vector2(x, y), line2, 10, Color(PALE, 0.9))
	y += 8
	draw_line(Vector2(x, y), Vector2(x + DESC_W, y), Color(LAV, 0.35), 1.0)
	y += 6
	# 효과: 글자 크기 11, 줄바꿈
	var desc := String(s.desc)
	var h := _font.get_multiline_string_size(desc, HORIZONTAL_ALIGNMENT_LEFT, DESC_W, 11).y
	draw_multiline_string_outline(_font, Vector2(x, y + 12), desc, HORIZONTAL_ALIGNMENT_LEFT, DESC_W, 11, -1, 3, Color(INK, 0.9))
	draw_multiline_string(_font, Vector2(x, y + 12), desc, HORIZONTAL_ALIGNMENT_LEFT, DESC_W, 11, -1, PALE)
	y += h + 18
	# 효과를 항목으로 (수치가 한눈에)
	for e in s.get("effects", []):
		var t := _effect_line(e)
		if t == "":
			continue
		draw_circle(Vector2(x + 4, y - 3), 1.6, Color(kcol, 0.9))
		_text(Vector2(x + 10, y), t, 9, Color(PALE, 0.85))
		y += 12
	y += 4
	if y < 290:
		draw_multiline_string(_font, Vector2(x, y + 10), "참고 구조: " + String(s.get("ref", "")), HORIZONTAL_ALIGNMENT_LEFT, DESC_W, 8, -1, Color(DIM, 0.9))
	# 공격이면 예상 피해 (짚 골렘 기준, 버프 없음)
	if kind == "attack":
		var u := TUnit.make_witch(_wid(), state[_wid()], 0)
		var en := TUnit.make_enemy("straw_golem", 0)
		var b := TBattle.new()
		var est := b.estimate(u, en, sid)
		_text(Vector2(x + DESC_W, 308), "짚 골렘에게 예상 %s" % TData.fmt(est), 9, Color(GOLD, 0.9), HORIZONTAL_ALIGNMENT_RIGHT, 0)


func _effect_line(e: Dictionary) -> String:
	var who: String = {"target": "", "self": "자신: ", "allies": "아군 전체: ", "enemies": "적 전체: ", "others": "다른 적: "}.get(String(e.get("who", "target")), "")
	var dur := " (행동 %d번)" % int(e.dur) if e.has("dur") else ""
	match String(e.t):
		"buff":
			var cat := String(e.cat)
			if cat == "element":
				return who + "%s 속성 부여%s" % [TData.ELEMENT_NAME.get(e.get("el", ""), ""), dur]
			var nm: String = TData.CAT_NAME.get(cat, cat)
			if e.has("mark"):
				nm = "%s 적 %s" % [TData.MARK_NAME.get(e.mark, ""), nm]
			if e.has("el") and cat != "element":
				nm = "%s 공격 %s" % [TData.ELEMENT_NAME.get(e.el, ""), nm]
			var v := int(round(float(e.get("v", 0.0)) * 100.0))
			return who + ("공격 직전 " if bool(e.get("pre", false)) else "") + "%s %+d%%%s" % [nm, v, dur]
		"debuff":
			return who + "%s %d%% (적 행동 %d번)" % [TData.CAT_NAME.get(e.cat, e.cat), int(round(float(e.v) * 100.0)), int(e.dur)]
		"mark":
			return who + "%s (적 행동 %d번)" % [TData.MARK_NAME.get(e.kind, e.kind), int(e.dur)]
		"this_special":
			return "이 공격만 %s 특공 +%d%%" % [TData.MARK_NAME.get(e.mark, ""), int(round(float(e.v) * 100.0))]
		"ignore_def": return "이 공격만 적 방어율 무시"
		"sure_crit": return "이 공격은 크리티컬 확정"
		"multi": return "%d번으로 나눠 맞힘" % int(e.n)
		"credits": return who + "크레딧 +%d" % int(e.v)
		"gauge": return who + "행동 게이지 +%d%%" % int(round(float(e.v) * 100.0))
		"heal": return who + "체력 %d%% 회복" % int(round(float(e.pct) * 100.0))
		"revive": return "되살림 %d%% (살아 있으면 회복)" % int(round(float(e.pct) * 100.0))
		"invincible": return who + "무적 (다음 적 행동 %d번)" % int(e.dur)
		"demerit_zero": return "대가: 그 행동 뒤 크레딧 0"
		"enemy_gauge":
			var v := int(round(float(e.v) * 100.0))
			var s := who + "적 게이지 −%d%%" % v
			if bool(e.get("frost_x2", false)):
				s += " (빙결이면 −%d%%)" % (v * 2)
			if e.has("if_mark"):
				s = "%s 적이면 " % TData.MARK_NAME.get(e.if_mark, "") + s
			return s
		"gauge_zero":
			return ("%s 적이면 " % TData.MARK_NAME.get(e.if_mark, "") if e.has("if_mark") else "") + who + "적 게이지 0"
		"extend_buffs": return who + "버프 지속 +%d" % int(e.v)
		"extend_mark": return who + "%s 적이면 %s 연장 +%d" % [TData.MARK_NAME.get(e.kind, ""), TData.MARK_NAME.get(e.kind, ""), int(e.v)]
		"on_crit":
			var parts: Array = []
			for e2 in e.effects:
				parts.append(_effect_line(e2))
			return "크리면: " + " · ".join(parts)
	return ""


func _draw_witch_desc(w: Dictionary) -> void:
	_text(Vector2(DESC_X, 58), String(w.name), 15, PALE)
	_text(Vector2(DESC_X, 74), String(w.title), 10, Color(TData.ELEMENT_COLOR.get(w.element, LAV), 1.0))
	var n_atk := 0
	var n_sup := 0
	var n_deb := 0
	for sid in w.skills:
		match String(TData.skill(String(sid)).kind):
			"attack": n_atk += 1
			"debuff": n_deb += 1
			_: n_sup += 1
	draw_multiline_string(_font, Vector2(DESC_X, 98), "마법 10개: 공격 %d · 보조 %d · 디버프 %d\n기본 공격: %s\n\n마법을 누르면 여기에 비용·종류·대상·효과·수치가 크게 나옵니다. 한 번 더 누르면 장착합니다." % [n_atk, n_sup, n_deb, String(w.basic.desc)], HORIZONTAL_ALIGNMENT_LEFT, DESC_W, 10, -1, Color(PALE, 0.9))
