class_name TSetup
extends Control
## 편성 화면 — 두 단계 (2026-10-18 사용자 선택 "명단 → 상세").
## 1단계 명단: 12명 초상 격자(4×3)에서 3명을 고른다(누른 순서 = 앞·중·뒤). "다음"으로 2단계.
## 2단계 상세: 위에 파티원 탭 3개 · 왼쪽 큰 그림 + 능력치 · 가운데 배운 마법 10개 목록(눌러서 장착, 최대 5) ·
##             오른쪽 큰 설명 상자(이름·비용·종류·대상·배율·효과·참고 구조 — 캐릭터별 스킬 설명을 알아보기 쉽게) · 아래 장비 4칸 · 전투 시작 / 명단으로.
## 장착·파티 상태는 static state에 남아 전투 → 편성을 오가도 유지된다. 키보드: ←→↑↓ 고르기 · Z 장착/고르기 · S 다음/시작 · X 뒤로.

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
const EQUIP_Y := 276.0
const START_RECT := Rect2(520, 322, 108, 30)
const BACK_RECT := Rect2(152, 322, 80, 30)
const NEXT_RECT := Rect2(520, 328, 108, 26)
const EQUIP_IDS := ["", "black_cup", "kaleido", "notebook"]
const CARD_W := 150.0
const CARD_H := 92.0
const SLOT_NAME := ["앞", "중", "뒤"]

static var state := {} ## "party": [id, id, id] · 마녀 id → {"equipped": [id...], "equip": 장비 id}

var step := 1 ## 1 명단 · 2 상세
var tab := 0 ## 2단계: 파티원 번호
var cursor := 0 ## 2단계: -1 탭 · 0~9 마법 · 10 장비 · 11 시작 / 1단계: 0~11 명단 칸
var _font: Font
var _t := 0.0
var _preview: Node2D
var _actors := {} ## 마녀 id → TActor
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
		var u := TUnit.make_witch(String(wid), state[wid], 0)
		var a := TActor.new()
		_preview.add_child(a)
		a.setup(u, Vector2.ZERO)
		a.z_index = 0
		_actors[wid] = a
	_layout_actors()


## 단계에 맞게 그림을 놓는다 (1단계: 카드마다 작게 · 2단계: 고른 파티원만 크게)
func _layout_actors() -> void:
	if _actors.is_empty():
		return
	for i in TData.ROSTER.size():
		var wid: String = TData.ROSTER[i]
		var a: TActor = _actors[wid]
		if step == 1:
			var r := _card_rect(i)
			a.visible = true
			a.home = r.position + Vector2(30, CARD_H - 6)
			a.scale = Vector2(1.5, 1.5)
		else:
			var on := i < 0 or (party().size() > tab and String(party()[tab]) == wid)
			a.visible = on
			a.home = Vector2(76, 262)
			a.scale = Vector2(3.0, 3.0)
		a.position = a.home
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


func _card_rect(i: int) -> Rect2:
	return Rect2(12 + 154 * (i % 4), 38 + 96 * (i / 4), CARD_W, CARD_H)


func _row_rect(i: int) -> Rect2:
	return Rect2(LIST_X, LIST_Y + ROW_H * float(i), LIST_W, ROW_H - 2.0)


func _tab_rect(i: int) -> Rect2:
	return Rect2(12 + 46 * i, 8, 44, 22)


func _equip_rect(i: int) -> Rect2:
	return Rect2(LIST_X + 120.0 * float(i), EQUIP_Y, 114, 20)


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
		cursor = (cursor + 1) % 12
	elif event.is_action_pressed("es_left"):
		cursor = (cursor + 11) % 12
	elif event.is_action_pressed("es_down"):
		cursor = (cursor + 4) % 12
	elif event.is_action_pressed("es_up"):
		cursor = (cursor + 8) % 12
	elif event.is_action_pressed("es_jump"):
		_toggle_party(String(TData.ROSTER[cursor]))
	elif event.is_action_pressed("es_bind"):
		_go_detail()
	elif event.is_action_pressed("es_exit") or event.is_action_pressed("es_attack"):
		exit_pressed.emit()
	else:
		return
	Sfx.play(&"tn_select", -12.0)


func _key_detail(event: InputEvent) -> void:
	if event.is_action_pressed("es_down"):
		cursor = mini(cursor + 1, 11)
	elif event.is_action_pressed("es_up"):
		cursor = maxi(cursor - 1, -1)
	elif event.is_action_pressed("es_right") or event.is_action_pressed("es_left"):
		var d := 1 if event.is_action_pressed("es_right") else -1
		if cursor == 10:
			var i := EQUIP_IDS.find(String(state[_wid()].equip))
			state[_wid()].equip = EQUIP_IDS[(i + d + EQUIP_IDS.size()) % EQUIP_IDS.size()]
		else:
			tab = (tab + d + party().size()) % party().size()
			_layout_actors()
	elif event.is_action_pressed("es_jump"):
		if cursor == 11:
			_start()
		elif cursor >= 0 and cursor <= 9:
			_toggle(cursor)
		elif cursor == 10:
			var i := EQUIP_IDS.find(String(state[_wid()].equip))
			state[_wid()].equip = EQUIP_IDS[(i + 1) % EQUIP_IDS.size()]
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
		for i in 12:
			if _card_rect(i).has_point(p):
				cursor = i
				_toggle_party(String(TData.ROSTER[i]))
				return
		if NEXT_RECT.has_point(p):
			_go_detail()
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
	for i in EQUIP_IDS.size():
		if _equip_rect(i).has_point(p):
			state[_wid()].equip = EQUIP_IDS[i]
			cursor = 10
			Sfx.play(&"tn_select", -10.0)
			queue_redraw()
			return
	if START_RECT.has_point(p):
		_start()
	elif BACK_RECT.has_point(p):
		_go_roster()


func _toggle_party(wid: String) -> void:
	var p: Array = party()
	if p.has(wid):
		p.erase(wid)
		Sfx.play(&"tn_cancel", -10.0)
	else:
		if p.size() >= 3:
			_say("파티는 3명 — 한 명을 빼고 넣으세요")
			Sfx.play(&"tn_cancel", -8.0)
			return
		p.append(wid)
		Sfx.play(&"tn_select", -8.0)
	queue_redraw()


func _go_detail() -> void:
	if party().size() < 3:
		_say("3명을 고르세요 (지금 %d명)" % party().size())
		Sfx.play(&"tn_cancel", -8.0)
		return
	step = 2
	tab = 0
	cursor = 0
	Sfx.play(&"tn_confirm", -8.0)
	_layout_actors()


func _go_roster() -> void:
	step = 1
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
	if party().size() < 3:
		_say("3명을 고르세요")
		return
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
	_text(Vector2(12, 24), "편성 1/2 — 마녀 3명을 고르세요 (누른 순서 = 앞 · 중 · 뒤)", 12, PALE)
	for i in 12:
		var wid := String(TData.ROSTER[i])
		var w: Dictionary = TData.WITCHES[wid]
		var r := _card_rect(i)
		var idx := p.find(wid)
		var on := idx >= 0
		var ecol: Color = TData.ELEMENT_COLOR.get(w.element, LAV)
		draw_rect(r, Color(LAV, 0.18) if on else Color(PANEL, 0.9))
		draw_rect(r, Color(PALE, 0.95) if cursor == i else (Color(LAV, 0.7) if on else Color(ecol, 0.25)), false, 1.0)
		draw_rect(Rect2(r.position, Vector2(3, r.size.y)), Color(ecol, 0.9)) # 왼쪽 속성 띠
		# 이름·속성·역할·능력치 (그림은 _preview 노드가 카드 왼쪽에 그린다)
		var tx := r.position.x + 62
		_text(Vector2(tx, r.position.y + 18), String(w.name), 12, PALE)
		_text(Vector2(tx, r.position.y + 32), "%s · %s" % [TData.ELEMENT_NAME.get(w.element, w.element), TData.ROLE_NAME.get(w.get("role", ""), "")], 9, Color(ecol, 1.0))
		_text(Vector2(tx, r.position.y + 48), "공격 %s" % TData.fmt(int(w.atk)), 9, Color(PALE, 0.8))
		_text(Vector2(tx, r.position.y + 60), "체력 %s" % TData.fmt(int(w.hp)), 9, Color(PALE, 0.8))
		_text(Vector2(tx, r.position.y + 72), "속도 %d · 방어 %d%%" % [int(w.speed), int(round(float(w.def) * 100.0))], 9, Color(PALE, 0.8))
		_text(Vector2(tx, r.position.y + 84), String(w.title).get_slice(" · ", 0), 8, Color(DIM, 0.9))
		if on:
			var b := r.position + Vector2(r.size.x - 16, 14)
			draw_circle(b, 10.0, LAV)
			draw_string(_font, b + Vector2(-10, 4), SLOT_NAME[idx], HORIZONTAL_ALIGNMENT_CENTER, 20, 10, INK)
	# 아래: 파티 요약 + 다음
	var ptxt := "파티: "
	for i in p.size():
		ptxt += "%s %s  " % [SLOT_NAME[i], TData.WITCHES[String(p[i])].name]
	if p.is_empty():
		ptxt += "(없음)"
	_text(Vector2(12, 346), ptxt, 11, GOLD)
	var ok := p.size() == 3
	draw_rect(NEXT_RECT, Color(LAV, 0.85 if ok else 0.3))
	draw_rect(NEXT_RECT, Color(PALE, 0.9 if ok else 0.4), false, 1.0)
	draw_string(_font, Vector2(NEXT_RECT.position.x, NEXT_RECT.position.y + 18), "다음 → 마법 장착", HORIZONTAL_ALIGNMENT_CENTER, int(NEXT_RECT.size.x), 11, INK if ok else Color(PALE, 0.6))
	if _msg_t > 0.0:
		_text(Vector2(320, 346), _msg, 10, Color(FIRE, minf(_msg_t, 1.0)), HORIZONTAL_ALIGNMENT_CENTER, 0)


func _draw_detail() -> void:
	var p: Array = party()
	var wid := _wid()
	var w: Dictionary = TData.WITCHES[wid]
	var ecol: Color = TData.ELEMENT_COLOR.get(w.element, LAV)
	draw_rect(Rect2(0, 36, 146, 304), Color(PANEL, 0.9))
	draw_rect(Rect2(LIST_X - 6, 36, LIST_W + 12, 236), Color(PANEL, 0.9))
	draw_rect(Rect2(DESC_X - 6, 36, DESC_W + 12, 236), Color(PANEL, 0.9))
	draw_rect(Rect2(LIST_X - 6, EQUIP_Y - 8, DESC_X + DESC_W + 6 - LIST_X + 6, 42), Color(PANEL, 0.9))
	# 탭 (파티원 3)
	for i in p.size():
		var r := _tab_rect(i)
		var twid := String(p[i])
		var on := i == tab
		var col: Color = TData.WITCHES[twid].color
		draw_rect(r, Color(col, 0.9) if on else Color(INK, 0.7))
		draw_rect(r, Color(PALE if on else DIM, 0.9 if on or cursor == -1 else 0.4), false, 1.0)
		draw_string(_font, Vector2(r.position.x, r.position.y + 15), String(TData.WITCHES[twid].name), HORIZONTAL_ALIGNMENT_CENTER, int(r.size.x), 10, INK if on else PALE)
	_text(Vector2(156, 24), "편성 2/2 — 마법 5개 장착 · 장비 1개 · 전투 시작", 11, Color(DIM, 0.9))
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
	elif cursor == 10:
		_draw_equip_desc(eq)
	else:
		_draw_witch_desc(w)
	# 장비
	_text(Vector2(LIST_X, EQUIP_Y - 1), "장비 (1개)", 9, Color(PALE, 0.9))
	for i in EQUIP_IDS.size():
		var r := _equip_rect(i)
		var eid: String = EQUIP_IDS[i]
		var on := String(state[wid].equip) == eid
		draw_rect(r, Color(GOLD, 0.25) if on else Color(INK, 0.5))
		draw_rect(r, Color(GOLD if on else DIM, 0.9 if on or cursor == 10 else 0.4), false, 1.0)
		draw_string(_font, Vector2(r.position.x, r.position.y + 14), String(TData.EQUIPS[eid].name), HORIZONTAL_ALIGNMENT_CENTER, int(r.size.x), 10, PALE if on else Color(PALE, 0.7))
	_text(Vector2(LIST_X, EQUIP_Y + 32), String(eq.get("desc", "장비 없음")), 8, Color(GOLD, 0.9))
	# 버튼
	draw_rect(BACK_RECT, Color(INK, 0.7))
	draw_rect(BACK_RECT, Color(DIM, 0.8), false, 1.0)
	draw_string(_font, Vector2(BACK_RECT.position.x, BACK_RECT.position.y + 20), "← 명단", HORIZONTAL_ALIGNMENT_CENTER, int(BACK_RECT.size.x), 11, PALE)
	var pulse := 0.8 + 0.2 * sin(_t * 4.0)
	draw_rect(START_RECT, Color(LAV, 0.9 if cursor == 11 else 0.7 * pulse))
	draw_rect(START_RECT, Color(PALE, 0.9), false, 1.0)
	draw_string(_font, Vector2(START_RECT.position.x, START_RECT.position.y + 20), "전투 시작", HORIZONTAL_ALIGNMENT_CENTER, int(START_RECT.size.x), 13, INK)
	if _msg_t > 0.0:
		_text(Vector2(240, 348), _msg, 10, Color(FIRE, minf(_msg_t, 1.0)))
	else:
		_text(Vector2(240, 348), "적: 짚 골렘(불 약점) · 늪 두꺼비(번개 약점) · 재의 기사", 8, Color(DIM, 0.9))


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
	if y < 236:
		draw_multiline_string(_font, Vector2(x, y + 10), "참고 구조: " + String(s.get("ref", "")), HORIZONTAL_ALIGNMENT_LEFT, DESC_W, 8, -1, Color(DIM, 0.9))
	# 공격이면 예상 피해 (짚 골렘 기준, 버프 없음)
	if kind == "attack":
		var u := TUnit.make_witch(_wid(), state[_wid()], 0)
		var en := TUnit.make_enemy("straw_golem", 0)
		var b := TBattle.new()
		var est := b.estimate(u, en, sid)
		_text(Vector2(x + DESC_W, 266), "짚 골렘에게 예상 %s" % TData.fmt(est), 9, Color(GOLD, 0.9), HORIZONTAL_ALIGNMENT_RIGHT, 0)


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


func _draw_equip_desc(eq: Dictionary) -> void:
	_text(Vector2(DESC_X, 58), String(eq.get("name", "없음")), 15, GOLD)
	draw_multiline_string(_font, Vector2(DESC_X, 84), String(eq.get("desc", "장비 없음")), HORIZONTAL_ALIGNMENT_LEFT, DESC_W, 11, -1, PALE)
	draw_multiline_string(_font, Vector2(DESC_X, 130), "캐릭터당 장비 1개. FGO 개념예장 구조 참고 — 검은 잔은 화력과 위험을 맞바꾸고, 만화경은 시작부터 큰 마법, 수첩은 중간.", HORIZONTAL_ALIGNMENT_LEFT, DESC_W, 9, -1, Color(DIM, 0.95))


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
