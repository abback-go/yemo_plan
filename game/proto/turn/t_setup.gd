class_name TSetup
extends Control
## 편성 화면 — 세 단계 (combat_proto.md §21.3·§21.4·§21.4.1).
## S-01 편성: 왼쪽에 세로로 긴 파티 카드 3장(앞·중·뒤) — 큰 그림·이름·속성/역할·능력치 2×2·대마법·패시브·장비 ◀ ▶·장착 마법 4.
##            오른쪽에 12명 명단(4×3): 카드를 누르고 명단의 마녀를 누르면 그 자리에 들어간다(이미 파티에 있으면 자리를 맞바꿈).
##            아래 오른쪽: 고른 전투와 약점 · "전투 고르기 ▶".
## S-02 마법: 위에 파티원 탭 3개 · 왼쪽 큰 그림·능력치·패시브 · 가운데 배운 마법 10개 타일(2열×5줄, 한 번 누르면 설명, 다시 누르면 장착, 최대 4)
##            · 대마법 줄 · 장비 줄 · 오른쪽 큰 설명 상자. 마법·장비를 길게 누르면 강화 Lv1→2→3 순환 [제안, 시험용].
## S-03 전투 고르기: 일반 normal_01 · 보스 boss_01 · 시련 trial_01 카드 3장 → 출격.
## 장착·파티·장비·강화·고른 전투는 static에 남아 전투 → 편성을 오가도 유지된다.
## 키보드 S-01: ←→ 카드 · ↑↓ 그 자리의 마녀 바꾸기 · X 장비 바꾸기 · Z 마법 장착 · S 전투 고르기 · Esc 나가기.
##        S-02: ↑↓ 줄 · ←→ 탭 · Z 장착 · S 전투 고르기 · X 편성으로.  S-03: ←→ 전투 · Z/S 출격 · X 편성으로.

signal start_pressed
signal exit_pressed

const T := preload("res://proto/turn/t_theme.gd")
const START1_RECT := Rect2(404, 300, 224, 32) ## S-01 전투 고르기 · S-03 출격 (같은 자리)
const PICK_RECT := Rect2(404, 264, 224, 30) ## S-01 고른 전투 줄
const START_RECT := Rect2(520, 322, 108, 30) ## S-02 전투 고르기
const BACK_RECT := Rect2(152, 322, 80, 30) ## S-02 편성으로
const BACK3_RECT := Rect2(12, 300, 120, 32) ## S-03 편성으로
const ULT_ROW := Rect2(152, 207, 228, 30) ## S-02 대마법 줄
const EQUIP_ROW := Rect2(152, 242, 228, 28) ## S-02 장비 줄
const DESC := Rect2(380, 36, 254, 280) ## S-02 설명 상자
const DESC_X := 388.0
const DESC_W := 238.0
const CARD_W := 122.0
const CARD_H := 300.0
const CARD_Y := 34.0
const ROSTER_X := 404.0
const ROSTER_Y := 34.0
const BATTLE_IDS := ["normal_01", "boss_01", "trial_01"]
const KIND_TAG := {"normal": ["일반", Color("#b9a2ff")], "boss": ["보스", Color("#ffe08a")], "trial": ["시련", Color("#ff4f6a")]}
## 전투 카드의 한 줄 안내 (데이터에 없는 화면 글)
const BATTLE_NOTE := {"normal_01": "적 3마리 한 웨이브. 빌드 시험에 알맞음", "boss_01": "웨이브 3. 마지막에 재의 왕 (3줄 · 차지 5 · 버프 해제)",
	"trial_01": "공격력이 아주 높고 필살기는 무적 관통. 버티며 쌓는 빌드용"}
const HOLD := 0.4

static var state := {} ## "party": [id, id, id] · 마녀 id → {"equipped": [id...], "equip": 장비 id, "equip_lv": 1~3, "skill_lv": {마법 id: 1~3}}
static var battle_pick: String = TData.BATTLE.battle ## S-03에서 고른 전투 id

var step := 1 ## 1 편성(카드) · 2 마법 · 3 전투 고르기
var tab := 0 ## 2단계: 파티원 번호
var cursor := 0 ## 2단계: -1 탭 · 0~9 마법 · 10 대마법 · 11 장비 · 12 시작
var active := 0 ## 1단계: 고른 카드(자리) 0~2
var _t := 0.0
var _preview: Node2D
var _actors := {} ## 마녀 id → TActor (명단의 작은 그림)
var _big := {} ## 마녀 id → TActor (카드·상세의 큰 그림)
var _foes := {} ## 전투 id → TActor (전투 카드의 적 그림)
var _msg := ""
var _msg_t := 0.0
var _press := {} ## 누르는 중 {pos, t, what, i, held}


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
			state[wid] = {"equipped": d, "equip": "", "equip_lv": 1, "skill_lv": {}}


static func party() -> Array:
	ensure_state()
	return state.party


## 장비는 파티에 한 명만 (combat_proto.md §4.3) — 규칙은 TData (헤드리스 시험에서도 쓰게)
static func step_equip(slot: int, d: int) -> String:
	ensure_state()
	return TData.step_equip(state, slot, d)


static func fix_equip(wid: String) -> void:
	ensure_state()
	TData.fix_equip(state, wid)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	for bid in BATTLE_IDS:
		var waves: Array = TData.BATTLES[bid].waves
		var list: Array = []
		for item in waves[waves.size() - 1]: # 마지막 웨이브의 적
			var eid := String(item.id) if item is Dictionary else String(item)
			var a := TActor.new()
			_preview.add_child(a)
			a.setup(TUnit.make_enemy(eid, 0), Vector2.ZERO)
			a.z_index = 0
			list.append(a)
		_foes[bid] = list
	_layout_actors()


## 단계에 맞게 그림을 놓는다 (1단계: 명단은 작게, 파티 3명은 카드에 크게 · 2단계: 고른 파티원만 크게 · 3단계: 전투 카드의 적)
func _layout_actors() -> void:
	if _actors.is_empty():
		return
	var p: Array = party()
	for i in TData.ROSTER.size():
		var wid: String = TData.ROSTER[i]
		var a: TActor = _actors[wid]
		var b: TActor = _big[wid]
		var slot := p.find(wid)
		a.visible = step == 1
		b.visible = false
		if step == 1:
			var r := _roster_rect(i)
			a.home = r.position + Vector2(r.size.x * 0.5, r.size.y - 16.0)
			a.scale = Vector2(1.15, 1.15)
			b.visible = slot >= 0
			if slot >= 0:
				var c := _card_rect(slot)
				b.home = c.position + Vector2(c.size.x * 0.5, 146.0)
				b.scale = Vector2(2.3, 2.3)
		elif step == 2:
			b.visible = slot == tab
			b.home = Vector2(73, 190)
			b.scale = Vector2(2.6, 2.6)
		a.position = a.home
		b.position = b.home
	for i in BATTLE_IDS.size():
		var list: Array = _foes[BATTLE_IDS[i]]
		var c := _battle_rect(i)
		for j in list.size():
			var f: TActor = list[j]
			f.visible = step == 3
			var sz := float(f.unit.data.get("size", 1.0))
			var k := 1.0 if list.size() == 1 else 0.85
			f.home = c.position + Vector2(c.size.x * (0.5 if list.size() == 1 else 0.24 + 0.27 * float(j)), 154.0 - (8.0 * float(j) if list.size() > 1 else 0.0))
			f.scale = Vector2(k * sz, k * sz)
			f.z_index = list.size() - j
			f.position = f.home
	queue_redraw()


## 편성 1단계로 (전투가 끝나 돌아올 때)
func back_to_roster() -> void:
	step = 1
	_press = {}
	_layout_actors()


func _process(delta: float) -> void:
	_t += delta
	size = get_viewport_rect().size # 캔버스 층 아래 Control은 앵커로 화면 크기를 못 받는다
	_msg_t = maxf(_msg_t - delta, 0.0)
	if not _press.is_empty() and not bool(_press.held):
		_press.t = float(_press.t) + delta
		if float(_press.t) >= HOLD:
			_press.held = true
			_hold(String(_press.what), int(_press.i))
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


## 카드 안 장비 ◀ ▶ 버튼 (24×28)과 이름 칸
func _equip_btn(i: int, right: bool) -> Rect2:
	var c := _card_rect(i)
	return Rect2(c.position.x + (c.size.x - 30.0 if right else 6.0), c.position.y + 226, 24, 28)


func _equip_name_rect(i: int) -> Rect2:
	var c := _card_rect(i)
	return Rect2(c.position.x + 30, c.position.y + 226, c.size.x - 60, 28)


## 카드 안 "마법 장착" 버튼 (장착 4개 아이콘)
func _magic_btn(i: int) -> Rect2:
	var c := _card_rect(i)
	return Rect2(c.position.x + 6, c.position.y + 260, c.size.x - 12, 34)


## 오른쪽 명단 칸 (12명, 4×3)
func _roster_rect(i: int) -> Rect2:
	return Rect2(ROSTER_X + 56 * (i % 4), ROSTER_Y + 76 * (i / 4), 52, 72)


## 2단계 마법 타일 (2열 × 5줄)
func _tile_rect(i: int) -> Rect2:
	return Rect2(152 + 116 * (i % 2), 40 + 33 * (i / 2), 112, 30)


func _tab_rect(i: int) -> Rect2:
	return Rect2(8 + 68 * i, 4, 64, 28)


## 3단계 전투 카드
func _battle_rect(i: int) -> Rect2:
	return Rect2(12 + 208 * i, 36, 200, 256)


# ═══════════════════════════════════════════════════════════
# 입력
# ═══════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_press_down(event.position)
		else:
			_press_up()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION:
			if event.pressed:
				_press_down(event.position)
			else:
				_press_up()
			get_viewport().set_input_as_handled()
		return
	match step:
		1: _key_roster(event)
		2: _key_detail(event)
		3: _key_battle(event)
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
		_go_battle()
	elif event.is_action_pressed("es_exit"):
		exit_pressed.emit()
	else:
		return
	Sfx.play(&"tn_select", -12.0)


func _key_detail(event: InputEvent) -> void:
	if event.is_action_pressed("es_down"):
		cursor = mini(cursor + 1, 12)
	elif event.is_action_pressed("es_up"):
		cursor = maxi(cursor - 1, -1)
	elif event.is_action_pressed("es_right") or event.is_action_pressed("es_left"):
		var d := 1 if event.is_action_pressed("es_right") else -1
		tab = (tab + d + party().size()) % party().size()
		_layout_actors()
	elif event.is_action_pressed("es_jump"):
		if cursor == 12:
			_go_battle()
		elif cursor >= 0 and cursor <= 9:
			_toggle(cursor)
		elif cursor == -1:
			tab = (tab + 1) % party().size()
			_layout_actors()
	elif event.is_action_pressed("es_bind"):
		_go_battle()
	elif event.is_action_pressed("es_exit") or event.is_action_pressed("es_attack"):
		_go_roster()
	else:
		return
	Sfx.play(&"tn_select", -12.0)


func _key_battle(event: InputEvent) -> void:
	var i := BATTLE_IDS.find(battle_pick)
	if event.is_action_pressed("es_right") or event.is_action_pressed("es_left"):
		var d := 1 if event.is_action_pressed("es_right") else -1
		battle_pick = BATTLE_IDS[(i + d + BATTLE_IDS.size()) % BATTLE_IDS.size()]
	elif event.is_action_pressed("es_jump") or event.is_action_pressed("es_bind"):
		_start()
	elif event.is_action_pressed("es_exit") or event.is_action_pressed("es_attack"):
		_go_roster()
	else:
		return
	Sfx.play(&"tn_select", -12.0)


## 손가락이 닿음: 길게 누를 수 있는 것(마법 타일·장비 줄)은 떼는 때까지 기다리고, 나머지는 바로
func _press_down(p: Vector2) -> void:
	_press = {}
	if p.distance_to(Vector2(size.x - 16, 16)) < 16.0:
		if step == 1:
			exit_pressed.emit()
		else:
			_go_roster()
		return
	if step == 2:
		var skills: Array = TData.WITCHES[_wid()].skills
		for i in skills.size():
			if _tile_rect(i).has_point(p):
				_press = {"pos": p, "t": 0.0, "what": "skill", "i": i, "held": false}
				return
		if EQUIP_ROW.has_point(p):
			_press = {"pos": p, "t": 0.0, "what": "equip", "i": 0, "held": false}
			return
	_tap_now(p)


func _press_up() -> void:
	if _press.is_empty():
		return
	var pr := _press
	_press = {}
	if bool(pr.held):
		return
	match String(pr.what):
		"skill":
			var i := int(pr.i)
			if cursor == i:
				_toggle(i) # 두 번째 누름: 장착/해제
			else:
				cursor = i # 첫 누름: 설명 보기
				Sfx.play(&"tn_select", -12.0)
		"equip":
			cursor = 11
			Sfx.play(&"tn_select", -12.0)
	queue_redraw()


## 길게 누름 (0.4초): 강화 레벨 순환 Lv1 → 2 → 3 → 1 [제안 — 시험용, §21.4]
func _hold(what: String, i: int) -> void:
	var wid := _wid()
	match what:
		"skill":
			var sid := String(TData.WITCHES[wid].skills[i])
			var lv: Dictionary = state[wid].skill_lv
			var nv := int(lv.get(sid, 1)) % 3 + 1
			if nv == 1:
				lv.erase(sid)
			else:
				lv[sid] = nv
			cursor = i
			_say("%s 강화 Lv%d (수치 ×%.2f)" % [String(TData.skill(sid).name), nv, float(TData.SKILL_LV[nv - 1])])
		"equip":
			if String(state[wid].equip) == "":
				_say("장비가 없습니다 — 편성 카드의 ◀ ▶로 고르세요")
				return
			state[wid].equip_lv = int(state[wid].get("equip_lv", 1)) % 3 + 1
			cursor = 11
			var eq := TData.equip_at(String(state[wid].equip), int(state[wid].equip_lv))
			_say("%s 강화 Lv%d — %s" % [String(eq.name), int(state[wid].equip_lv), String(eq.desc)])
	Sfx.play(&"tn_confirm", -8.0)


func _tap_now(p: Vector2) -> void:
	if step == 1:
		for i in 3:
			if _equip_btn(i, false).has_point(p) or _equip_btn(i, true).has_point(p) or _equip_name_rect(i).has_point(p):
				active = i
				_cycle_equip(i, -1 if _equip_btn(i, false).has_point(p) else 1)
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
		if START1_RECT.has_point(p) or PICK_RECT.has_point(p):
			_go_battle()
		return
	if step == 3:
		for i in BATTLE_IDS.size():
			if _battle_rect(i).has_point(p):
				if battle_pick != BATTLE_IDS[i]:
					battle_pick = BATTLE_IDS[i]
					Sfx.play(&"tn_select", -10.0)
				queue_redraw()
				return
		if START1_RECT.has_point(p):
			_start()
		elif BACK3_RECT.has_point(p):
			_go_roster()
		return
	for i in party().size():
		if _tab_rect(i).has_point(p):
			tab = i
			cursor = -1
			Sfx.play(&"tn_select", -10.0)
			_layout_actors()
			return
	if ULT_ROW.has_point(p):
		cursor = 10
		Sfx.play(&"tn_select", -12.0)
	elif START_RECT.has_point(p):
		_go_battle()
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
	var had := String(state[wid].equip)
	fix_equip(wid)
	Sfx.play(&"tn_select", -8.0)
	if had != "" and String(state[wid].equip) == "":
		_say("%s 자리: %s — 장비 %s는 다른 파티원이 끼고 있어 뺐습니다" % [T.SLOT_NAME[slot], TData.WITCHES[wid].name, TData.EQUIPS[had].name])
	else:
		_say("%s 자리: %s" % [T.SLOT_NAME[slot], TData.WITCHES[wid].name])
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
			fix_equip(wid)
			_layout_actors()
			return


## 장비 ◀ ▶: 다른 파티원이 낀 장비는 건너뛴다 (§4.3) — 건너뛴 것을 안내 글로 알린다
func _cycle_equip(slot: int, d: int) -> void:
	var wid := String(party()[slot])
	var before := TData.EQUIP_ORDER.find(String(state[wid].equip))
	step_equip(slot, d)
	var now := TData.EQUIP_ORDER.find(String(state[wid].equip))
	var skipped: Array = []
	var i := before
	var n := TData.EQUIP_ORDER.size()
	for k in n:
		i = (i + d + n) % n
		if i == now:
			break
		skipped.append(TData.EQUIPS[TData.EQUIP_ORDER[i]].name)
	Sfx.play(&"tn_select", -10.0)
	var eq: Dictionary = TData.EQUIPS[state[wid].equip]
	var s := "%s 장비: %s — %s" % [TData.WITCHES[wid].name, eq.name, eq.desc]
	if not skipped.is_empty():
		s += " (다른 파티원이 낀 %s 건너뜀)" % ", ".join(skipped)
	_say(s)
	queue_redraw()


func _go_detail(slot: int) -> void:
	step = 2
	tab = slot
	cursor = 0
	Sfx.play(&"tn_confirm", -8.0)
	_layout_actors()


func _go_roster() -> void:
	if step == 2:
		active = tab
	step = 1
	cursor = 0
	Sfx.play(&"tn_cancel", -10.0)
	_layout_actors()


## 전투 고르기 (S-03)
func _go_battle() -> void:
	step = 3
	if not BATTLE_IDS.has(battle_pick):
		battle_pick = BATTLE_IDS[0]
	Sfx.play(&"tn_confirm", -8.0)
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
	_msg_t = 2.4


func _start() -> void:
	Sfx.play(&"tn_confirm", -4.0)
	start_pressed.emit()


# ═══════════════════════════════════════════════════════════
# 그림
# ═══════════════════════════════════════════════════════════

func _x_button() -> void:
	var c := Vector2(size.x - 16, 16)
	draw_circle(c, 12.0, Color(T.INK, 0.6))
	draw_arc(c, 12.0, 0.0, TAU, 24, Color(T.LINE, 0.6), 1.0)
	draw_line(c + Vector2(-4, -4), c + Vector2(4, 4), Color(T.TEXT, 0.85), 1.6)
	draw_line(c + Vector2(-4, 4), c + Vector2(4, -4), Color(T.TEXT, 0.85), 1.6)


func _button(r: Rect2, label: String, main: bool, pulse := 1.0) -> void:
	T.panel(self, r, Color(T.LINE, 0.8 * pulse) if main else Color(T.INK, 0.85), Color(T.TEXT, 0.9) if main else Color(T.TEXT_OFF, 0.9), 1, 3)
	T.text(self, r.get_center() + Vector2(0, 5), label, 12, T.INK if main else T.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 0 if main else -1)


func _msg_line(p: Vector2, w: float, fallback: String) -> void:
	if _msg_t > 0.0:
		T.text(self, p, T.clip(_msg, 10, w), 10, Color(T.GOLD, minf(_msg_t, 1.0)))
	elif fallback != "":
		T.text(self, p, T.clip(fallback, 10, w), 10, T.TEXT_SUB)


func _draw() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color(T.BG, 0.97))
	match step:
		1: _draw_roster()
		2: _draw_detail()
		3: _draw_battles()
	_x_button()


func _draw_roster() -> void:
	var p: Array = party()
	T.text(self, Vector2(12, 22), "편성", 15, T.TEXT)
	T.text(self, Vector2(56, 21), "카드를 누르고 명단에서 마녀를 고르세요", 10, T.TEXT_SUB)
	for i in 3:
		_draw_card(i, String(p[i]), i == active)
	# 오른쪽 명단 (이름 10px · 속성 색 윗선 · 파티 배지)
	for i in 12:
		var wid := String(TData.ROSTER[i])
		var w: Dictionary = TData.WITCHES[wid]
		var r := _roster_rect(i)
		var slot := p.find(wid)
		var ecol: Color = TData.ELEMENT_COLOR.get(w.element, T.LINE)
		T.panel(self, r, Color(T.LINE, 0.2) if slot >= 0 else Color(T.PANEL, 0.9), Color(T.LINE, 0.75) if slot >= 0 else Color(ecol, 0.3), 1, 3)
		draw_rect(Rect2(r.position + Vector2(2, 1), Vector2(r.size.x - 4, 2)), Color(ecol, 0.9))
		T.text(self, Vector2(r.get_center().x, r.end.y - 4), String(w.name), 10, T.TEXT if slot >= 0 else T.TEXT_SUB, HORIZONTAL_ALIGNMENT_CENTER)
		if slot >= 0:
			var b := r.position + Vector2(r.size.x - 9, 11)
			draw_circle(b, 7.0, T.LINE)
			T.text(self, b + Vector2(0, 4), T.SLOT_NAME[slot], 10, T.INK, HORIZONTAL_ALIGNMENT_CENTER, 0)
	# 고른 전투 + 그 전투의 약점 (편성 판단에 필요한 것만)
	var bd: Dictionary = TData.BATTLES.get(battle_pick, {})
	T.panel(self, PICK_RECT, Color(T.PANEL, 0.9), Color(T.LINE, 0.5), 1, 3)
	var tag: Array = KIND_TAG.get(String(bd.get("kind", "normal")), KIND_TAG.normal)
	T.text(self, PICK_RECT.position + Vector2(8, 19), "전투", 10, T.TEXT_SUB)
	T.text(self, PICK_RECT.position + Vector2(36, 19), T.clip(_battle_title(battle_pick), 12, 96), 12, tag[1])
	var weak := _battle_weak(battle_pick)
	var wx := PICK_RECT.end.x - 8.0
	if weak.is_empty():
		T.text(self, Vector2(wx, PICK_RECT.position.y + 19), "약점 없음", 10, T.TEXT_OFF, HORIZONTAL_ALIGNMENT_RIGHT)
	else:
		for k in range(weak.size() - 1, -1, -1):
			wx -= 13.0
			draw_rect(Rect2(wx, PICK_RECT.position.y + 9, 11, 11), Color(T.INK, 0.9))
			draw_rect(Rect2(wx + 0.5, PICK_RECT.position.y + 9.5, 10, 10), Color(T.WEAK, 0.9), false, 1.0)
			T.element_icon(self, Vector2(wx + 5.5, PICK_RECT.position.y + 14.5), String(weak[k]), 4.2)
		T.text(self, Vector2(wx - 4, PICK_RECT.position.y + 19), "약점", 10, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_RIGHT)
	_button(START1_RECT, "전투 고르기  ▶", true, 0.8 + 0.2 * sin(_t * 4.0))
	_msg_line(Vector2(12, 350), 616, "")


## 전투 카드 제목: "보스 전투 — 재의 왕" → "재의 왕"
func _battle_title(bid: String) -> String:
	var nm := String(TData.BATTLES.get(bid, {}).get("name", ""))
	return nm.substr(nm.find(" — ") + 3) if nm.find(" — ") >= 0 else nm


## 전투의 약점 속성 (모든 웨이브 적의 약점 합)
func _battle_weak(bid: String) -> Array:
	var out: Array = []
	for wave in TData.BATTLES.get(bid, {}).get("waves", []):
		for item in wave:
			var eid := String(item.id) if item is Dictionary else String(item)
			var u := TUnit.make_enemy(eid, 0)
			for el in u.weak:
				if not out.has(String(el)):
					out.append(String(el))
	return out


## 파티 카드 한 장: 자리 · 이름 · 속성/역할 · (큰 그림은 _big 노드) · 능력치 2×2 · 대마법 · 패시브 · 장비 ◀ ▶ · 장착 마법 4
func _draw_card(i: int, wid: String, on: bool) -> void:
	var w: Dictionary = TData.WITCHES[wid]
	var r := _card_rect(i)
	var X := r.position.x
	var Y := r.position.y
	var ecol: Color = TData.ELEMENT_COLOR.get(w.element, T.LINE)
	T.panel(self, r, Color(T.PANEL, 0.95), T.GOLD if on else Color(ecol, 0.45), 2 if on else 1, 4)
	draw_rect(Rect2(X + 2, Y + 2, r.size.x - 4, 22), Color(ecol, 0.3 if on else 0.15))
	# 머리: 자리 + 이름
	draw_circle(Vector2(X + 14, Y + 13), 8.0, T.GOLD if on else Color(T.LINE, 0.7))
	T.text(self, Vector2(X + 14, Y + 17), T.SLOT_NAME[i], 10, T.INK, HORIZONTAL_ALIGNMENT_CENTER, 0)
	T.text(self, Vector2(X + 28, Y + 18), String(w.name), 12, T.TEXT)
	T.text(self, Vector2(X + r.size.x * 0.5, Y + 38), "%s · %s" % [TData.ELEMENT_NAME.get(w.element, w.element), TData.ROLE_NAME.get(w.get("role", ""), "")], 10, ecol, HORIZONTAL_ALIGNMENT_CENTER)
	draw_circle(Vector2(X + r.size.x * 0.5, Y + 110), 34.0, Color(ecol, 0.08))
	# 능력치 2×2
	var lv := int(state[wid].get("equip_lv", 1))
	var eq := TData.equip_at(String(state[wid].equip), lv)
	var atk := int(round(float(w.atk) * (1.0 + float(eq.get("atk", 0.0)))))
	var hp := int(round(float(w.hp) * (1.0 + float(eq.get("hp", 0.0)))))
	T.text(self, Vector2(X + 8, Y + 162), "공격 %s" % TData.fmt(atk), 10, T.TEXT)
	T.text(self, Vector2(X + r.size.x - 8, Y + 162), "속도 %d" % (int(w.speed) + int(eq.get("speed", 0))), 10, T.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	T.text(self, Vector2(X + 8, Y + 175), "체력 %s" % TData.fmt(hp), 10, T.TEXT)
	T.text(self, Vector2(X + r.size.x - 8, Y + 175), "방어 %d%%" % int(round(float(w.def) * 100.0)), 10, T.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	# 대마법 · 패시브
	var ult := TData.skill(String(w.get("ultimate", "")))
	draw_rect(Rect2(X + 6, Y + 181, r.size.x - 12, 1), Color(T.LINE, 0.25))
	TIcon.draw(self, Vector2(X + 13, Y + 191), String(ult.get("icon", "burst")), T.GOLD, 5.0)
	T.text(self, Vector2(X + 22, Y + 196), T.clip(String(ult.get("name", "")), 10, r.size.x - 30), 10, T.GOLD)
	var pas: Dictionary = w.get("passive", {})
	T.diamond(self, Vector2(X + 13, Y + 209), 4.5, Color(T.INK, 0.9))
	T.diamond(self, Vector2(X + 13, Y + 209), 3.5, T.TEXT_SUB)
	T.text(self, Vector2(X + 22, Y + 213), T.clip("패시브 " + String(pas.get("name", "")), 10, r.size.x - 30), 10, T.TEXT_SUB)
	# 장비 ◀ 이름 ▶ (다른 파티원이 낀 장비는 건너뜀)
	var has_eq := String(state[wid].equip) != ""
	for right in [false, true]:
		var br := _equip_btn(i, right)
		T.panel(self, br, Color(T.INK, 0.85), Color(T.TEXT_SUB, 0.8), 1, 3)
		var c := br.get_center()
		var dx := 3.0 if right else -3.0
		draw_colored_polygon(PackedVector2Array([c + Vector2(dx, 0), c + Vector2(-dx, -5), c + Vector2(-dx, 5)]), T.TEXT)
	var nr := _equip_name_rect(i)
	T.panel(self, nr, Color(T.GOLD, 0.16) if has_eq else Color(T.INK, 0.6), Color(T.GOLD, 0.6) if has_eq else Color(T.TEXT_OFF, 0.5), 1, 2)
	T.text(self, Vector2(nr.get_center().x, nr.position.y + 11), "장비", 8, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_CENTER, 0)
	var en := String(TData.EQUIPS[state[wid].equip].name) + (" Ⅱ" if lv == 2 else (" Ⅲ" if lv == 3 else "")) if has_eq else "없음"
	T.text(self, Vector2(nr.get_center().x, nr.position.y + 24), T.clip(en, 10, nr.size.x - 2), 10, T.GOLD if has_eq else T.TEXT_SUB, HORIZONTAL_ALIGNMENT_CENTER)
	# 마법 장착 버튼: 장착한 마법 4개 아이콘 + 비용 배지, 오른쪽 ▶
	var mb := _magic_btn(i)
	var eqd: Array = state[wid].equipped
	T.panel(self, mb, Color(T.LINE, 0.3 if on else 0.18), Color(T.TEXT, 0.7), 1, 3)
	for k in TData.EQUIP_MAX:
		var cc := mb.position + Vector2(13 + 24 * k, 15)
		if k < eqd.size():
			var sk := TData.skill(String(eqd[k]))
			draw_circle(cc, 9.0, Color(T.INK, 0.95))
			draw_arc(cc, 9.0, 0.0, TAU, 20, Color(T.kind_col(String(sk.kind)), 0.9), 1.0)
			TIcon.draw(self, cc, String(sk.get("icon", "strike")), ecol, 5.5)
			T.cost_badge(self, cc + Vector2(7, 8), str(int(sk.cost)))
		else:
			draw_arc(cc, 8.0, 0.0, TAU, 16, Color(T.TEXT_OFF, 0.5), 1.0)
	draw_colored_polygon(PackedVector2Array([mb.end - Vector2(10, 22), mb.end - Vector2(4, 17), mb.end - Vector2(10, 12)]), T.TEXT)


func _draw_detail() -> void:
	var p: Array = party()
	var wid := _wid()
	var w: Dictionary = TData.WITCHES[wid]
	var ecol: Color = TData.ELEMENT_COLOR.get(w.element, T.LINE)
	T.panel(self, Rect2(0, 36, 146, 304), Color(T.PANEL, 0.9), Color(T.LINE, 0.25), 1, 0)
	T.panel(self, DESC, Color(T.PANEL, 0.9), Color(T.LINE, 0.25), 1, 3)
	# 탭 (파티원 3)
	for i in p.size():
		var r := _tab_rect(i)
		var twid := String(p[i])
		var on := i == tab
		T.panel(self, r, Color(T.PANEL_HI, 1.0) if on else Color(T.INK, 0.7), Color(T.TEXT_OFF, 0.6), 1, 3)
		draw_rect(Rect2(r.position.x + 2, r.position.y + 2, 3, r.size.y - 4), TData.WITCHES[twid].color)
		if on:
			draw_rect(Rect2(r.position.x, r.end.y - 2, r.size.x, 2), T.GOLD)
		T.text(self, r.get_center() + Vector2(2, 5), String(TData.WITCHES[twid].name), 12, T.TEXT if on else T.TEXT_SUB, HORIZONTAL_ALIGNMENT_CENTER)
	T.text(self, Vector2(216, 22), "마법 장착 — 10개 중 %d개 (%d/%d)" % [TData.EQUIP_MAX, _equipped().size(), TData.EQUIP_MAX], 10, T.TEXT_SUB)
	# 왼쪽: 이름·능력치·패시브
	T.text(self, Vector2(73, 55), String(w.name), 15, T.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	T.text(self, Vector2(73, 69), String(w.title), 10, ecol, HORIZONTAL_ALIGNMENT_CENTER)
	var lv := int(state[wid].get("equip_lv", 1))
	var eq := TData.equip_at(String(state[wid].equip), lv)
	var atk := int(round(float(w.atk) * (1.0 + float(eq.get("atk", 0.0)))))
	var hp := int(round(float(w.hp) * (1.0 + float(eq.get("hp", 0.0)))))
	var lines := ["공격력 %s" % TData.fmt(atk), "체력 %s" % TData.fmt(hp), "속도 %d · 방어 %d%%" % [int(w.speed) + int(eq.get("speed", 0)), int(round(float(w.def) * 100.0))],
		"속성 %s%s" % [TData.ELEMENT_NAME.get(w.element, w.element), " (무상성 1.2배)" if bool(w.special) else ""], "기본 공격 %s" % String(w.basic.name)]
	for i in lines.size():
		T.text(self, Vector2(6, 208 + 12 * i), T.clip(lines[i], 10, 136), 10, T.TEXT)
	var pas: Dictionary = w.get("passive", {})
	draw_rect(Rect2(6, 268, 134, 1), Color(T.LINE, 0.3))
	T.text(self, Vector2(6, 282), "패시브 " + String(pas.get("name", "")), 10, T.GOLD)
	T.wrap(self, Vector2(6, 295), String(pas.get("desc", "")), 134, 10, T.TEXT_SUB, 12.0, 4)
	# 가운데: 마법 타일 2열 × 5줄
	var skills: Array = w.skills
	var equipped: Array = _equipped()
	var slv: Dictionary = state[wid].skill_lv
	for i in skills.size():
		var sid := String(skills[i])
		var s := TData.skill(sid)
		var r := _tile_rect(i)
		var on := equipped.has(sid)
		var cur := cursor == i
		var held := not _press.is_empty() and String(_press.what) == "skill" and int(_press.i) == i
		T.panel(self, r, Color(T.LINE, 0.22) if on else Color(T.INK, 0.6), T.TEXT if cur else (Color(T.LINE, 0.7) if on else Color(T.TEXT_OFF, 0.35)), 2 if cur else 1, 3)
		draw_rect(Rect2(r.position.x + 2, r.position.y + 3, 2, r.size.y - 6), T.kind_col(String(s.kind)))
		TIcon.draw(self, r.position + Vector2(17, 15), String(s.get("icon", "strike")), ecol if (on or cur) else Color(ecol, 0.7), 7.5)
		T.text(self, r.position + Vector2(30, 19), T.clip(String(s.name), 10, 66), 10, T.TEXT if (on or cur) else T.TEXT_SUB)
		T.cost_badge(self, r.position + Vector2(104, 9), str(int(s.cost)))
		var sl := int(slv.get(sid, 1))
		if sl > 1:
			T.text(self, r.end - Vector2(3, 3), "Lv%d" % sl, 8, T.GOLD, HORIZONTAL_ALIGNMENT_RIGHT, 2)
		if on:
			var idx := equipped.find(sid) + 1
			draw_circle(r.position + Vector2(7, 7), 6.0, T.GOLD)
			T.text(self, r.position + Vector2(7, 11), str(idx), 8, T.INK, HORIZONTAL_ALIGNMENT_CENTER, 0)
		if held:
			draw_arc(r.position + Vector2(17, 15), 12.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(float(_press.t) / HOLD, 0.0, 1.0), 24, T.GOLD, 2.0)
	# 대마법 줄 (장착 칸 아님 — 누르면 설명)
	var uid := String(w.get("ultimate", ""))
	var ult := TData.skill(uid)
	T.panel(self, ULT_ROW, Color(T.GOLD, 0.12), T.TEXT if cursor == 10 else Color(T.GOLD, 0.8), 2 if cursor == 10 else 1, 3)
	TIcon.draw(self, ULT_ROW.position + Vector2(17, 15), String(ult.get("icon", "burst")), T.GOLD, 7.5)
	T.text(self, ULT_ROW.position + Vector2(30, 19), "대마법  " + String(ult.get("name", "")), 10, T.GOLD)
	T.text(self, ULT_ROW.end - Vector2(8, 11), "크레딧 7 · 바퀴 끝 칸", 10, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_RIGHT)
	# 장비 줄 (길게 누르면 강화 Lv)
	var has_eq := String(state[wid].equip) != ""
	var eheld := not _press.is_empty() and String(_press.what) == "equip"
	T.panel(self, EQUIP_ROW, Color(T.INK, 0.6), T.TEXT if cursor == 11 else Color(T.GOLD, 0.5), 2 if cursor == 11 else 1, 3)
	draw_circle(EQUIP_ROW.position + Vector2(14, 14), 6.0, Color(T.INK, 0.9))
	draw_arc(EQUIP_ROW.position + Vector2(14, 14), 6.0, 0.0, TAU, 16, T.GOLD if has_eq else T.TEXT_OFF, 1.5)
	if eheld:
		draw_arc(EQUIP_ROW.position + Vector2(14, 14), 10.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(float(_press.t) / HOLD, 0.0, 1.0), 24, T.GOLD, 2.0)
	var etxt := "장비 %s%s — %s" % [String(eq.get("name", "없음")), " Lv%d" % lv if lv > 1 and has_eq else "", String(eq.get("desc", ""))] if has_eq else "장비 없음 — 편성 카드의 ◀ ▶로 고릅니다"
	T.text(self, EQUIP_ROW.position + Vector2(26, 18), T.clip(etxt, 10, EQUIP_ROW.size.x - 32), 10, T.GOLD if has_eq else T.TEXT_SUB)
	T.text(self, Vector2(152, 288), "마법·장비를 길게 누르면 강화 Lv1→2→3 (시험용)", 10, T.TEXT_OFF)
	# 오른쪽: 큰 설명 상자
	if cursor >= 0 and cursor < skills.size():
		_draw_desc(String(skills[cursor]), int(slv.get(String(skills[cursor]), 1)))
	elif cursor == 10:
		_draw_desc(uid, 1)
	elif cursor == 11:
		_draw_equip_desc(String(state[wid].equip), lv)
	else:
		_draw_witch_desc(w)
	# 버튼
	_button(BACK_RECT, "← 편성", false)
	_button(START_RECT, "전투 고르기", true, 0.8 + 0.2 * sin(_t * 4.0))
	_msg_line(Vector2(240, 342), 272, "")


## 큰 설명 상자: 이름 + 비용 / 종류 · 대상 · 배율 / 효과 / 항목별 수치(강화 반영) / 참고 구조 / 예상 피해
func _draw_desc(sid: String, lv: int) -> void:
	var s := TData.skill_at(sid, lv)
	var x := DESC_X
	var y := 52.0
	var kind := String(s.kind)
	var kcol := T.kind_col(kind)
	var ult := bool(s.get("ultimate", false))
	var on := _equipped().has(sid)
	var ecol: Color = TData.ELEMENT_COLOR.get(String(TData.WITCHES[_wid()].element), T.LINE)
	TIcon.draw(self, Vector2(x + 8, y - 5), String(s.get("icon", "strike")), T.GOLD if ult else ecol, 8.0)
	T.text(self, Vector2(x + 22, y), String(s.name), 15, T.GOLD if ult else T.TEXT)
	var nx := x + 28.0 + T.width(String(s.name), 15)
	if not ult:
		T.cost_badge(self, Vector2(nx + 4, y - 5), str(int(s.cost)))
	T.text(self, Vector2(x + DESC_W, y - 1), "대마법" if ult else ("장착됨" if on else "미장착"), 10, T.GOLD if ult else (T.LINE if on else T.TEXT_OFF), HORIZONTAL_ALIGNMENT_RIGHT)
	y += 18
	var line2 := "비용 %d · %s" % [int(s.cost), T.kind_label(s)]
	if kind == "attack":
		line2 += " · 배율 ×%.1f" % float(s.mult)
	if lv > 1:
		line2 += " · Lv%d" % lv
	T.text(self, Vector2(x, y), line2, 10, kcol)
	y += 6
	draw_line(Vector2(x, y), Vector2(x + DESC_W, y), Color(T.LINE, 0.35), 1.0)
	y += 14
	y += T.wrap(self, Vector2(x, y), String(TData.skill(sid).desc), DESC_W, 10, T.TEXT, 13.0)
	y += 4
	# 효과를 항목으로 (수치가 한눈에, 강화 레벨 반영)
	for e in s.get("effects", []):
		var t := _effect_line(e)
		if t == "":
			continue
		draw_circle(Vector2(x + 3, y - 4), 1.6, Color(kcol, 0.9))
		y += T.wrap(self, Vector2(x + 9, y), t, DESC_W - 9, 10, T.TEXT_SUB, 13.0, 2)
	y += 4
	if y < 280:
		T.wrap(self, Vector2(x, y + 8), "참고 구조: " + String(s.get("ref", "")), DESC_W, 10, T.TEXT_OFF, 13.0, maxi(1, int((290.0 - y) / 13.0)))
	# 공격이면 예상 피해 (짚 골렘 기준, 버프 없음)
	if kind == "attack":
		var u := TUnit.make_witch(_wid(), state[_wid()], 0)
		var en := TUnit.make_enemy("straw_golem", 0)
		var b := TBattle.new()
		var est := b.estimate(u, en, sid)
		var est_c := b.estimate(u, en, sid, true)
		T.text(self, Vector2(x + DESC_W, 308), "짚 골렘에게 예상 %s · 크리 %s" % [TData.fmt_short(est), TData.fmt_short(est_c)], 10, T.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)


func _draw_equip_desc(eid: String, lv: int) -> void:
	var x := DESC_X
	if eid == "":
		T.text(self, Vector2(x, 52), "장비 없음", 15, T.TEXT)
		T.wrap(self, Vector2(x, 76), "편성 카드의 ◀ ▶로 장비를 고릅니다. 한 장비는 파티에 한 명만 낄 수 있어, 다른 파티원이 낀 장비는 건너뜁니다.", DESC_W, 10, T.TEXT_SUB, 13.0)
		return
	T.text(self, Vector2(x, 52), String(TData.EQUIPS[eid].name), 15, T.GOLD)
	T.text(self, Vector2(x + DESC_W, 51), "Lv%d" % lv, 10, T.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	var y := 76.0
	for l in [1, 2, 3]:
		var e := TData.equip_at(eid, l)
		var col := T.TEXT if l == lv else T.TEXT_OFF
		T.text(self, Vector2(x, y), "Lv%d" % l, 10, T.GOLD if l == lv else T.TEXT_OFF)
		y += T.wrap(self, Vector2(x + 28, y), String(e.desc), DESC_W - 28, 10, col, 13.0) + 4.0
	T.wrap(self, Vector2(x, y + 10), "한 장비는 파티에 한 명만 (다른 파티원이 낀 장비는 ◀ ▶에서 건너뜀). 길게 누르면 강화 Lv 시험.", DESC_W, 10, T.TEXT_SUB, 13.0)


## 3단계: 전투 고르기 — 카드 3장 (종류·이름·웨이브별 적·약점·안내) + 출격
func _draw_battles() -> void:
	T.text(self, Vector2(12, 22), "전투 고르기", 15, T.TEXT)
	T.text(self, Vector2(104, 21), "카드를 누르고 출격", 10, T.TEXT_SUB)
	for i in BATTLE_IDS.size():
		var bid := String(BATTLE_IDS[i])
		var bd: Dictionary = TData.BATTLES[bid]
		var r := _battle_rect(i)
		var on := bid == battle_pick
		var tag: Array = KIND_TAG.get(String(bd.kind), KIND_TAG.normal)
		T.panel(self, r, Color(T.PANEL_HI if on else T.PANEL, 0.95), T.GOLD if on else Color(T.LINE, 0.4), 2 if on else 1, 4)
		T.panel(self, Rect2(r.position + Vector2(8, 8), Vector2(T.width(String(tag[0]), 10) + 12, 15)), Color(tag[1], 0.2), tag[1], 1, 2)
		T.text(self, r.position + Vector2(14, 20), String(tag[0]), 10, tag[1])
		T.text(self, r.position + Vector2(T.width(String(tag[0]), 10) + 26, 21), _battle_title(bid), 12, T.TEXT)
		draw_set_transform(r.position + Vector2(r.size.x * 0.5, 150), 0.0, Vector2(1.0, 0.3))
		draw_circle(Vector2.ZERO, 50.0, Color(tag[1], 0.08))
		draw_set_transform(Vector2.ZERO)
		# 웨이브별 적
		var y := r.position.y + 168.0
		var waves: Array = bd.waves
		for wi in waves.size():
			var names := {}
			var order: Array = []
			for item in waves[wi]:
				var eid := String(item.id) if item is Dictionary else String(item)
				if not names.has(eid):
					names[eid] = 0
					order.append(eid)
				names[eid] = int(names[eid]) + 1
			var parts: Array = []
			for eid in order:
				parts.append(String(TData.ENEMIES[eid].name) + (" ×%d" % int(names[eid]) if int(names[eid]) > 1 else ""))
			var lab := ("웨이브 %d  " % (wi + 1) if waves.size() > 1 else "") + " · ".join(parts)
			T.text(self, Vector2(r.position.x + 8, y), T.clip(lab, 10, r.size.x - 16), 10, T.TEXT)
			y += 13.0
		# 약점
		var weak := _battle_weak(bid)
		T.text(self, Vector2(r.position.x + 8, y + 2), "약점", 10, T.TEXT_SUB)
		if weak.is_empty():
			T.text(self, Vector2(r.position.x + 38, y + 2), "없음", 10, T.TEXT_OFF)
		for k in weak.size():
			var wx := r.position.x + 36 + 13 * k
			draw_rect(Rect2(wx, y - 8, 11, 11), Color(T.INK, 0.9))
			draw_rect(Rect2(wx + 0.5, y - 7.5, 10, 10), Color(T.WEAK, 0.9), false, 1.0)
			T.element_icon(self, Vector2(wx + 5.5, y - 2.5), String(weak[k]), 4.2)
		T.wrap(self, Vector2(r.position.x + 8, y + 17), String(BATTLE_NOTE.get(bid, "")), r.size.x - 16, 10, T.TEXT_SUB, 12.0, 2)
	_button(BACK3_RECT, "← 편성", false)
	_button(START1_RECT, "출격", true, 0.8 + 0.2 * sin(_t * 4.0))
	_msg_line(Vector2(140, 320), 250, "")


func _effect_line(e: Dictionary) -> String:
	var who: String = {"target": "", "self": "자신: ", "allies": "아군 전체: ", "enemies": "적 전체: ", "others": "다른 적: ", "other_allies": "다른 아군: ", "dead_allies": "쓰러진 아군: "}.get(String(e.get("who", "target")), "")
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
			if bool(e.get("per_mark", false)) or (cat == "special" and e.has("mark")):
				nm += " 1겹마다"
			if e.has("count"):
				dur = " (%s %d번)" % [{"basic": "기본 공격", "skill": "공격 마법", "attack": "공격"}.get(String(e.get("on", "attack")), "공격"), int(e.count)]
			return who + ("공격 직전 " if bool(e.get("pre", false)) else "") + "%s %+d%%%s" % [nm, v, dur]
		"debuff":
			return who + "%s %d%% (적 행동 %d번)" % [TData.CAT_NAME.get(e.cat, e.cat), int(round(float(e.v) * 100.0)), int(e.dur)]
		"mark":
			return who + "%s %d겹 (적 행동 %d번)" % [TData.MARK_NAME.get(e.kind, e.kind), int(e.get("n", 1)), int(e.dur)]
		"this_special":
			return "이 공격만 %s 특공 +%d%%" % [TData.MARK_NAME.get(e.mark, ""), int(round(float(e.v) * 100.0))]
		"ignore_def": return "이 공격만 적 방어율 무시"
		"sure_crit": return "이 공격은 크리티컬 확정"
		"multi": return "%d번으로 나눠 맞힘" % int(e.n)
		"credits":
			return ("%s 적이면 " % TData.MARK_NAME.get(e.if_mark, "") if e.has("if_mark") else "") + who + "크레딧 +%d" % int(e.v)
		"crit_gauge": return "크리 1번마다 자신 게이지 +%d%%" % int(round(float(e.v) * 100.0))
		"enemy_charge": return who + "적 차지 −%d" % int(e.v)
		"hp_cost": return who + "대가: 체력 −%d%%" % int(round(float(e.pct) * 100.0))
		"spread": return "%s 겹 수만큼 다른 적 전체에" % TData.MARK_NAME.get(e.kind, "")
		"burst": return "%s 터뜨리기 (겹마다 +%.1f배)" % [TData.MARK_NAME.get(e.mark, ""), float(e.per)]
		"hit_stack": return "맞을 때마다 %s공격력 +%d%% (최대 %d겹)" % ["아군 전체 " if String(e.get("to", "self")) == "allies" else "", int(round(float(e.v) * 100.0)), int(e.get("max", 5))]
		"taunt": return who + "도발 (적 행동 %d번)" % int(e.dur)
		"guts": return who + "근성 1회 (적 행동 %d번 안)" % int(e.dur)
		"stun": return ("%s 적이면 " % TData.MARK_NAME.get(e.if_mark, "") if e.has("if_mark") else "") + who + "기절"
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
	T.text(self, Vector2(DESC_X, 52), String(w.name), 15, T.TEXT)
	T.text(self, Vector2(DESC_X, 68), String(w.title), 10, TData.ELEMENT_COLOR.get(w.element, T.LINE))
	var n_atk := 0
	var n_sup := 0
	var n_deb := 0
	for sid in w.skills:
		match String(TData.skill(String(sid)).kind):
			"attack": n_atk += 1
			"debuff": n_deb += 1
			_: n_sup += 1
	var y := 90.0
	y += T.wrap(self, Vector2(DESC_X, y), "마법 10개: 공격 %d · 보조 %d · 디버프 %d" % [n_atk, n_sup, n_deb], DESC_W, 10, T.TEXT, 13.0)
	y += T.wrap(self, Vector2(DESC_X, y), "기본 공격 %s — %s" % [String(w.basic.name), String(w.basic.desc)], DESC_W, 10, T.TEXT, 13.0) + 8.0
	T.wrap(self, Vector2(DESC_X, y), "마법 타일을 누르면 여기에 비용·종류·대상·효과·수치가 나옵니다. 한 번 더 누르면 장착합니다. 길게 누르면 강화 레벨(시험용)이 바뀝니다.", DESC_W, 10, T.TEXT_SUB, 13.0)
