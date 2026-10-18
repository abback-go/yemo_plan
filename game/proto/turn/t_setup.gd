class_name TSetup
extends Control
## 편성 화면 — 세 단계 (combat_proto.md §21.3·§21.4·§21.4.1).
## S-01 편성: 왼쪽에 세로로 긴 파티 카드 3장(왼→오 = 뒤·중·앞 — 전투 패널·전장 그림 순서와 같게) — 큰 그림·이름·속성/역할·능력치 2×2·대마법·패시브·장비 ◀ ▶·장착 마법 4.
##            오른쪽에 12명 명단(4×3): 카드를 누르고 명단의 마녀를 누르면 그 자리에 들어간다(이미 파티에 있으면 자리를 맞바꿈).
##            아래 오른쪽: 고른 전투와 약점 · "전투 고르기 ▶".
## S-02 마법: 위에 파티원 탭 3개 · 왼쪽 큰 그림·능력치·패시브 · 가운데 배운 마법 10개 타일(2열×5줄, 한 번 누르면 설명, 다시 누르면 장착, 최대 4)
##            · 대마법 줄 · 장비 줄 · 오른쪽 큰 설명 상자. 마법·장비를 길게 누르면 강화 Lv1→2→3 순환 [제안, 시험용].
## S-03 전투 고르기 (단계 F-2): 탭 일반 6 · 보스 3 · 시련 1 + 왼쪽 목록(웨이브별 약점·난이도·예상 시간·깸) + 오른쪽 상세 → 출격.
## 장착·파티·장비·강화·고른 전투는 static에 남아 전투 → 편성을 오가도 유지된다.
## 키보드 S-01: ←→ 카드 · ↑↓ 그 자리의 마녀 바꾸기 · X 장비 바꾸기 · Z 마법 장착 · S 전투 고르기 · Esc 나가기.
##        S-02: ↑↓ 줄 · ←→ 탭 · Z 장착 · S 전투 고르기 · X 편성으로.  S-03: ↑↓ 전투 · ←→ 탭 · Z/S 출격 · X 편성으로.

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
const PASSIVE_RECT := Rect2(0, 268, 146, 72) ## S-02 왼쪽 패시브 (누르면 오른쪽 설명 상자에 전문, review_C2 M9)
const CARD_W := 122.0
const CARD_H := 300.0
const CARD_Y := 34.0
const ROSTER_X := 404.0
const ROSTER_Y := 34.0
const ALL_BATTLES := ["intro_01", "normal_01", "normal_fire", "normal_water", "normal_bolt", "normal_swarm", "normal_rift", "boss_01", "boss_02", "boss_03", "trial_01"]
## 이긴 뒤 다음 추천 (review_G G06): 안내 → 목록 순서 (TData.BATTLE_ORDER)
const NEXT := {"intro_01": "normal_01", "normal_01": "normal_fire", "normal_fire": "normal_water", "normal_water": "normal_bolt", "normal_bolt": "normal_swarm",
	"normal_swarm": "normal_rift", "normal_rift": "boss_01", "boss_01": "boss_02", "boss_02": "boss_03", "boss_03": "trial_01"}
const TABS := ["normal", "boss", "trial"] ## S-03 탭 (전투 종류)
const DETAIL3 := Rect2(332, 36, 296, 256) ## S-03 오른쪽 상세 판
const ROW3_H := 36.0 ## S-03 목록 한 줄 높이 (터치 목표 34px 이상)
const GEAR_C := Vector2(624, 16) ## S-01 설정 톱니 (review_G G18 — 옛 X 자리)
const HELP_C := Vector2(590, 16) ## S-01 도움말 ?
const EQ_LIST := Rect2(40, 30, 560, 304) ## 장비 목록 판 (review_G G11 · review_F F11)
const EQ_CLOSE := Rect2(480, 296, 108, 30)
const KIND_TAG := {"intro": ["안내", Color("#7ddc8a")], "normal": ["일반", Color("#b9a2ff")], "boss": ["보스", Color("#ffe08a")], "trial": ["시련", Color("#ff4f6a")]}
const HOLD := 0.4

static var state := {} ## "party": [id, id, id] · 마녀 id → {"equipped": [id...], "equip": 장비 id, "equip_lv": 1~3, "skill_lv": {마법 id: 1~3}}
static var battle_pick: String = TData.BATTLE.battle ## S-03에서 고른 전투 id
static var dev := false ## 주소에 &dev — 개발자용 글("참고 구조")을 보임 (review_G G12)
static var _tab3 := "normal" ## S-03 지금 탭 (전투 종류)

var step := 1 ## 1 편성(카드) · 2 마법 · 3 전투 고르기
var tab := 0 ## 2단계: 파티원 번호
var cursor := 0 ## 2단계: -1 탭 · 0~9 마법 · 10 대마법 · 11 장비 · 12 시작 · 13 패시브 (누름으로만)
var active := 0 ## 1단계: 고른 카드(자리) 0~2
var _t := 0.0
var _preview: Node2D
var _actors := {} ## 마녀 id → TActor (명단의 작은 그림)
var _big := {} ## 마녀 id → TActor (카드·상세의 큰 그림)
var _foes := {} ## 전투 id → TActor (전투 카드의 적 그림)
var _msg := ""
var _msg_t := 0.0
var _press := {} ## 누르는 중 {pos, t, what, i, held}
var guide: TGuide ## 설정·도움말 판 (TStage가 넣음)
var _peek := "" ## 명단을 길게 누르는 동안 보이는 마녀 상세 (review_G G10)
var _eq_slot := -1 ## 장비 목록 판을 연 자리 (−1 = 닫힘)
var _eq_pick := "" ## 장비 목록에서 고른(설명 중인) 장비
var _over: Overlay


static func ensure_state() -> void:
	TData.fill_state(state)


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


func _exit_tree() -> void:
	TTheme.release()


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
	for bid in ALL_BATTLES:
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
	_over = Overlay.new()
	_over.setup = self
	_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_over.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_over)
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
	# 3단계: 고른 전투의 마지막 웨이브 적만 오른쪽 상세 판에 (단계 F-2)
	for bid in ALL_BATTLES:
		for f: TActor in _foes[bid]:
			f.visible = false
	if step == 3 and _foes.has(battle_pick):
		var list: Array = _foes[battle_pick]
		var c := DETAIL3
		for j in list.size():
			var f: TActor = list[j]
			f.visible = true
			var sz := float(f.unit.data.get("size", 1.0))
			var k := 0.95 if list.size() == 1 else 0.8
			f.home = c.position + Vector2(c.size.x * (0.5 if list.size() == 1 else 0.2 + 0.3 * float(j)), 128.0 - (6.0 * float(j) if list.size() > 1 else 0.0))
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
	if _over != null:
		_over.size = size
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


## 1단계 파티 카드 (세로로 긴 직사각형) 자리 i = 앞·중·뒤. 왼→오 = 뒤·중·앞 (편성 카드 = 전투 패널 = 전장 왼→오, review_C2 M6 [제안])
func _card_rect(i: int) -> Rect2:
	return Rect2(12 + 130 * (2 - i), CARD_Y, CARD_W, CARD_H)


## 카드 안 장비 ◀ ▶ 버튼 (32×36 — 터치 목표, review_C2 M8)과 이름 칸
func _equip_btn(i: int, right: bool) -> Rect2:
	var c := _card_rect(i)
	return Rect2(c.position.x + (c.size.x - 36.0 if right else 4.0), c.position.y + 218, 32, 36)


func _equip_name_rect(i: int) -> Rect2:
	var c := _card_rect(i)
	return Rect2(c.position.x + 38, c.position.y + 218, c.size.x - 76, 36)


## 카드 안 "마법 장착" 버튼 (장착 4개 아이콘, 위에 "장착 마법" 꼬리표)
func _magic_btn(i: int) -> Rect2:
	var c := _card_rect(i)
	return Rect2(c.position.x + 6, c.position.y + 265, c.size.x - 12, 32)


## 오른쪽 명단 칸 (12명, 4×3)
func _roster_rect(i: int) -> Rect2:
	return Rect2(ROSTER_X + 56 * (i % 4), ROSTER_Y + 76 * (i / 4), 52, 72)


## 2단계 마법 타일 (2열 × 5줄)
func _tile_rect(i: int) -> Rect2:
	return Rect2(152 + 116 * (i % 2), 40 + 33 * (i / 2), 112, 30)


## 탭 (자리 i): 왼→오 = 뒤·중·앞 — S-01 카드·전투 패널과 같은 순서 (review_G G14)
func _tab_rect(i: int) -> Rect2:
	return Rect2(8 + 68 * (2 - i), 4, 64, 28)


## 3단계 목록 i번째 줄 (지금 탭에 보이는 전투 중). 탭이 있으면 탭 아래부터
func _battle_rect(i: int) -> Rect2:
	var y0 := 36.0 if battle_ids().size() == 1 else 66.0
	return Rect2(12, y0 + (ROW3_H + 3.0) * float(i), 312, ROW3_H)


## 3단계 탭 i (일반 · 보스 · 시련)
func _tab3_rect(i: int) -> Rect2:
	return Rect2(12 + 102 * i, 32, 98, 30)


## 전투 고르기에 보이는 전투: 첫 실행 안내 중엔 안내 전투 한 줄 (진행 안내일 뿐 잠금 아님 — 안내를 끄면 처음부터 전부, review_G §4.3 A3)
static func battle_ids() -> Array:
	if not TSave.intro_done and not TSave.tips_off:
		return ["intro_01"]
	return TData.BATTLE_ORDER


## 지금 탭의 전투 (안내 중이면 안내 전투 하나)
static func _visible_ids() -> Array:
	var all := battle_ids()
	if all.size() == 1:
		return all
	var out: Array = []
	for b in all:
		if String(TData.BATTLES[b].kind) == _tab3:
			out.append(b)
	return out


## 시험 봇·안내용: 그 전투를 고르려면 누를 자리 (지금 탭에 없으면 그 탭)
func pick_rect_for(bid: String) -> Rect2:
	var vis := _visible_ids()
	if vis.has(bid):
		return _battle_rect(vis.find(bid))
	return _tab3_rect(TABS.find(String(TData.BATTLES[bid].kind)))


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
	if event.is_action_pressed("es_right"): # 카드가 왼→오 = 뒤·중·앞이라 오른쪽 = 앞쪽 자리
		active = (active + 2) % 3
	elif event.is_action_pressed("es_left"):
		active = (active + 1) % 3
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
		var d := -1 if event.is_action_pressed("es_right") else 1 # 탭이 왼→오 = 뒤·중·앞 (review_G G14)
		tab = (tab + d + party().size()) % party().size()
		_msg_t = 0.0
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
	var ids := _visible_ids()
	var i := ids.find(battle_pick)
	if event.is_action_pressed("es_down") or event.is_action_pressed("es_up"):
		var d := 1 if event.is_action_pressed("es_down") else -1
		battle_pick = ids[(i + d + ids.size()) % ids.size()]
		TSave.save_soon()
		_layout_actors()
	elif (event.is_action_pressed("es_right") or event.is_action_pressed("es_left")) and battle_ids().size() > 1:
		var d := 1 if event.is_action_pressed("es_right") else -1
		_set_tab3(String(TABS[(TABS.find(_tab3) + d + TABS.size()) % TABS.size()]))
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
	if _eq_slot >= 0:
		_equip_list_press(p)
		return
	if step == 1 and p.distance_to(GEAR_C) < 16.0:
		if guide != null:
			guide.open_settings()
		return
	if step == 1 and p.distance_to(HELP_C) < 16.0:
		if guide != null:
			guide.open_help()
		return
	if step != 1 and p.distance_to(Vector2(size.x - 16, 16)) < 16.0:
		_go_roster()
		return
	if step == 1:
		for i in 12:
			if _roster_rect(i).has_point(p):
				_press = {"pos": p, "t": 0.0, "what": "roster", "i": i, "held": false}
				return
	if step == 3:
		var ids := _visible_ids()
		for i in ids.size():
			if _battle_rect(i).has_point(p):
				_press = {"pos": p, "t": 0.0, "what": "battle", "i": i, "held": false}
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
	_peek = ""
	if bool(pr.held):
		return
	match String(pr.what):
		"roster":
			_assign(active, String(TData.ROSTER[int(pr.i)]))
		"battle":
			_pick_battle(int(pr.i))
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
		"roster":
			_peek = String(TData.ROSTER[i]) # 길게 누르는 동안 그 마녀 상세 (떼면 닫힘, 교체 없음)
			Sfx.play(&"tn_select", -12.0)
			return
		"battle":
			var bid := String(_visible_ids()[i])
			_say(String(TData.BATTLES[bid].get("ask", "")))
			Sfx.play(&"tn_select", -12.0)
			return
		"skill":
			var sid := String(TData.WITCHES[wid].skills[i])
			var lv: Dictionary = state[wid].skill_lv
			var nv := int(lv.get(sid, 1)) % 3 + 1
			if nv == 1:
				lv.erase(sid)
			else:
				lv[sid] = nv
			cursor = i
			TSave.save_soon()
			_say("%s 강화 Lv%d (수치 ×%.2f)" % [String(TData.skill(sid).name), nv, float(TData.SKILL_LV[nv - 1])])
		"equip":
			if String(state[wid].equip) == "":
				_say("장비가 없습니다 — 편성 카드의 ◀ ▶로 고르세요")
				return
			state[wid].equip_lv = int(state[wid].get("equip_lv", 1)) % 3 + 1
			cursor = 11
			TSave.save_soon()
			var eq := TData.equip_at(String(state[wid].equip), int(state[wid].equip_lv))
			_say("%s 강화 Lv%d — %s" % [String(eq.name), int(state[wid].equip_lv), String(eq.desc)])
	Sfx.play(&"tn_confirm", -8.0)


func _tap_now(p: Vector2) -> void:
	if step == 1:
		for i in 3:
			if _equip_name_rect(i).has_point(p):
				active = i
				_open_equip_list(i)
				return
			if _equip_btn(i, false).has_point(p) or _equip_btn(i, true).has_point(p):
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
		for i in _visible_ids().size():
			if _battle_rect(i).has_point(p):
				_pick_battle(i)
				return
		if battle_ids().size() > 1:
			for i in TABS.size():
				if _tab3_rect(i).has_point(p):
					_set_tab3(String(TABS[i]))
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
			_msg_t = 0.0 # 앞 탭의 안내 글을 남기지 않음 (review_G G23)
			Sfx.play(&"tn_select", -10.0)
			_layout_actors()
			return
	if ULT_ROW.has_point(p):
		cursor = 10
		Sfx.play(&"tn_select", -12.0)
	elif PASSIVE_RECT.has_point(p):
		cursor = 13
		Sfx.play(&"tn_select", -12.0)
	elif START_RECT.has_point(p):
		_go_battle()
	elif BACK_RECT.has_point(p):
		_go_roster()


func _pick_battle(i: int) -> void:
	var bid := String(_visible_ids()[i])
	if battle_pick != bid:
		battle_pick = bid
		Sfx.play(&"tn_select", -10.0)
		TSave.save_soon()
		_layout_actors()
	queue_redraw()


## S-03 탭을 바꾼다: 고른 전투가 그 탭에 없으면 그 탭의 아직 안 깬 첫 전투(다 깼으면 첫 전투)
func _set_tab3(kind: String) -> void:
	if _tab3 == kind:
		return
	_tab3 = kind
	var vis := _visible_ids()
	if not vis.has(battle_pick) and not vis.is_empty():
		battle_pick = String(vis[0])
		for b in vis:
			if not TSave.cleared.has(String(b)):
				battle_pick = String(b)
				break
		TSave.save_soon()
	Sfx.play(&"tn_select", -10.0)
	_layout_actors()


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
	TSave.save_soon()
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
			TSave.save_soon()
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
	TSave.save_soon()
	queue_redraw()


func _go_detail(slot: int) -> void:
	step = 2
	tab = slot
	cursor = 0
	_msg_t = 0.0
	Sfx.play(&"tn_confirm", -8.0)
	_layout_actors()


func _go_roster() -> void:
	if step == 2:
		active = tab
	step = 1
	cursor = 0
	_msg_t = 0.0
	Sfx.play(&"tn_cancel", -10.0)
	_layout_actors()


## 전투 고르기 (S-03)
func _go_battle() -> void:
	step = 3
	_msg_t = 0.0
	var ids := battle_ids()
	if not ids.has(battle_pick):
		battle_pick = ids[0]
	_tab3 = String(TData.BATTLES[battle_pick].kind) # 고른 전투의 탭으로
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
	TSave.save_soon()
	queue_redraw()


func _say(s: String) -> void:
	_msg = s
	_msg_t = 2.4


func _start() -> void:
	Sfx.play(&"tn_confirm", -4.0)
	TSave.save_setup()
	start_pressed.emit()


# ═══════════════════════════════════════════════════════════
# 그림
# ═══════════════════════════════════════════════════════════

func _x_button() -> void:
	var c := Vector2(size.x - 16, 16)
	if step == 1:
		# 설정 톱니 + 도움말 ? (review_G G18 — 나가기는 설정 판 안 "타이틀로")
		draw_circle(GEAR_C, 12.0, Color(T.INK, 0.6))
		draw_arc(GEAR_C, 12.0, 0.0, TAU, 24, Color(T.LINE, 0.6), 1.0)
		for k in 8:
			var a := TAU * float(k) / 8.0
			draw_line(GEAR_C + Vector2(cos(a), sin(a)) * 4.0, GEAR_C + Vector2(cos(a), sin(a)) * 7.5, Color(T.TEXT, 0.85), 2.0)
		draw_circle(GEAR_C, 4.5, Color(T.TEXT, 0.85))
		draw_circle(GEAR_C, 2.0, Color(T.INK, 1.0))
		draw_circle(HELP_C, 12.0, Color(T.INK, 0.6))
		draw_arc(HELP_C, 12.0, 0.0, TAU, 24, Color(T.LINE, 0.6), 1.0)
		T.text(self, HELP_C + Vector2(0, 5), "?", 12, T.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		return
	draw_circle(c, 12.0, Color(T.INK, 0.6))
	draw_arc(c, 12.0, 0.0, TAU, 24, Color(T.LINE, 0.6), 1.0)
	draw_line(c + Vector2(-4, -4), c + Vector2(4, 4), Color(T.TEXT, 0.85), 1.6)
	draw_line(c + Vector2(-4, 4), c + Vector2(4, -4), Color(T.TEXT, 0.85), 1.6)


func _button(r: Rect2, label: String, main: bool, pulse := 1.0, ci: CanvasItem = null) -> void:
	if ci == null:
		ci = self
	T.panel(ci, r, Color(T.LINE, 0.8 * pulse) if main else Color(T.INK, 0.85), Color(T.TEXT, 0.9) if main else Color(T.TEXT_OFF, 0.9), 1, 3)
	T.text(ci, r.get_center() + Vector2(0, 5), label, 12, T.INK if main else T.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 0 if main else -1)


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
	if _over != null:
		_over.queue_redraw()


func _draw_roster() -> void:
	var p: Array = party()
	T.text(self, Vector2(12, 22), "편성", 15, T.TEXT)
	T.text(self, Vector2(56, 21), "카드를 누르고 명단에서 마녀를 고르세요 · 명단을 길게 누르면 자세히", 10, T.TEXT_SUB)
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
		# 속성 아이콘 + 역할 한 글자 (review_G G10)
		draw_circle(r.position + Vector2(9, 11), 6.0, Color(T.INK, 0.9))
		T.element_icon(self, r.position + Vector2(9, 11), String(w.element), 4.0)
		T.text(self, r.position + Vector2(9, 27), String(TData.ROLE_NAME.get(String(w.get("role", "")), " ")).substr(0, 1), 8, ecol, HORIZONTAL_ALIGNMENT_CENTER, 0)
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
	if NEXT.values().has(battle_pick) and not TSave.cleared.has(battle_pick) and not TSave.cleared.is_empty() and NEXT.get(TSave.cleared.back(), "") == battle_pick:
		var tg := Rect2(PICK_RECT.position + Vector2(PICK_RECT.size.x - 52, -9), Vector2(48, 12))
		T.panel(self, tg, Color(T.INK, 0.95), T.GOLD, 1, 2)
		T.text(self, Vector2(tg.get_center().x, tg.end.y - 2), "다음 추천", 8, T.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 0)
	_button(START1_RECT, "전투 고르기  ▶", true, 0.8 + 0.2 * sin(_t * 4.0))
	_msg_line(Vector2(12, 350), 616, "" if TSave.persistent() else "이 브라우저에서는 저장되지 않습니다 (사생활 보호 창·저장 막힘)")


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
	# 여백 4 (체력 100,000과 방어 15%가 붙지 않게, review_C2 M5) · 값이 7자를 넘으면 짧게
	var atk_s := TData.fmt(atk) if TData.fmt(atk).length() <= 7 else TData.fmt_short(atk)
	var hp_s := TData.fmt(hp) if TData.fmt(hp).length() <= 7 else TData.fmt_short(hp)
	T.text(self, Vector2(X + 4, Y + 162), "공격 %s" % atk_s, 10, T.TEXT)
	T.text(self, Vector2(X + r.size.x - 4, Y + 162), "속도 %d" % (int(w.speed) + int(eq.get("speed", 0))), 10, T.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	T.text(self, Vector2(X + 4, Y + 175), "체력 %s" % hp_s, 10, T.TEXT)
	T.text(self, Vector2(X + r.size.x - 4, Y + 175), "방어 %d%%" % int(round(float(w.def) * 100.0)), 10, T.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
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
	T.text(self, Vector2(nr.get_center().x, nr.position.y + 10), "장비", 8, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_CENTER, 0)
	var en := String(TData.EQUIPS[state[wid].equip].name) + (" Ⅱ" if lv == 2 else (" Ⅲ" if lv == 3 else "")) if has_eq else "없음"
	var ecl := T.GOLD if has_eq else T.TEXT_SUB
	if T.width(en, 10) <= nr.size.x - 2.0:
		T.text(self, Vector2(nr.get_center().x, nr.position.y + 25), en, 10, ecl, HORIZONTAL_ALIGNMENT_CENTER)
	else: # 이름이 길면 작은 글자 두 줄 (모래시계 / 펜던트)
		var el := T.split_lines(en, nr.size.x - 2.0, 8)
		for k in mini(el.size(), 2):
			T.text(self, Vector2(nr.get_center().x, nr.position.y + 21 + 9 * k), T.clip(String(el[k]), 8, nr.size.x - 2.0), 8, ecl, HORIZONTAL_ALIGNMENT_CENTER)
	# 마법 장착 버튼: 위에 "장착 마법" 꼬리표 (L10), 장착한 마법 4개 아이콘 + 비용 배지, 오른쪽 ▶
	var mb := _magic_btn(i)
	var eqd: Array = state[wid].equipped
	T.text(self, Vector2(mb.position.x + 2, mb.position.y - 2), "장착 마법 · 숫자 = 크레딧", 8, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_LEFT, 0)
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
		T.text(self, r.get_center() + Vector2(2, 3), String(TData.WITCHES[twid].name), 12, T.TEXT if on else T.TEXT_SUB, HORIZONTAL_ALIGNMENT_CENTER)
		T.text(self, Vector2(r.end.x - 3, r.end.y - 3), T.SLOT_NAME[i], 8, T.GOLD if on else T.TEXT_OFF, HORIZONTAL_ALIGNMENT_RIGHT, 0)
	T.text(self, Vector2(216, 22), "마법 장착 — 10개 중 %d개 (%d/%d)" % [TData.EQUIP_MAX, _equipped().size(), TData.EQUIP_MAX], 10, T.TEXT_SUB)
	# 타일 왼쪽 색 막대의 뜻 (review_G G22)
	var lx := 380.0
	for kd: Array in [["attack", "공격"], ["support", "보조"], ["debuff", "디버프"]]:
		draw_rect(Rect2(lx, 15, 6, 6), T.kind_col(String(kd[0])))
		T.text(self, Vector2(lx + 9, 22), String(kd[1]), 8, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_LEFT, 0)
		lx += 13.0 + T.width(String(kd[1]), 8) + 6.0
	# 왼쪽: 이름·능력치·패시브
	T.text(self, Vector2(73, 55), String(w.name), 15, T.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	T.text(self, Vector2(73, 69), String(w.title), 10, ecol, HORIZONTAL_ALIGNMENT_CENTER)
	var lv := int(state[wid].get("equip_lv", 1))
	var eq := TData.equip_at(String(state[wid].equip), lv)
	var atk := int(round(float(w.atk) * (1.0 + float(eq.get("atk", 0.0)))))
	var hp := int(round(float(w.hp) * (1.0 + float(eq.get("hp", 0.0)))))
	var lines := ["공격력 %s" % TData.fmt(atk), "체력 %s" % TData.fmt(hp), "속도 %d · 방어 %d%%" % [int(w.speed) + int(eq.get("speed", 0)), int(round(float(w.def) * 100.0))],
		"속성 %s%s" % [TData.ELEMENT_NAME.get(w.element, w.element), " · 모든 적에게 1.2배" if bool(w.special) else ""], "기본 공격 %s" % String(w.basic.name)]
	for i in lines.size():
		T.text(self, Vector2(6, 208 + 12 * i), T.clip(lines[i], 10, 136), 10, T.TEXT)
	var pas: Dictionary = w.get("passive", {})
	draw_rect(Rect2(6, 268, 134, 1), Color(T.LINE, 0.3))
	if cursor == 13:
		T.panel(self, PASSIVE_RECT.grow(-1), Color(0, 0, 0, 0), T.TEXT, 1, 2)
	T.text(self, Vector2(6, 282), "패시브 " + String(pas.get("name", "")), 10, T.GOLD)
	var pl := T.split_lines(String(pas.get("desc", "")), 134, 10)
	if pl.size() <= 4:
		T.wrap(self, Vector2(6, 295), String(pas.get("desc", "")), 134, 10, T.TEXT_SUB, 12.0, 4)
	else: # 잘리면 3줄 + "… 눌러 전체" (누르면 오른쪽 설명 상자에 전문)
		for k in 3:
			T.text(self, Vector2(6, 295 + 12 * k), String(pl[k]), 10, T.TEXT_SUB)
		T.text(self, Vector2(6, 331), "… 눌러 전체", 10, T.TEXT_OFF)
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
		T.panel(self, r, Color(T.LINE, 0.22) if on else Color(T.INK, 0.6), T.TEXT if cur else (T.GOLD if on else Color(T.TEXT_OFF, 0.35)), 2 if cur else 1, 3)
		if on:
			# 장착 번호: 타일 왼쪽 금빛 띠(10px) 안의 먹 숫자 — 오른쪽 위 비용 배지(금빛 원)와 모양을 갈라 놓음 (review_C2 M4)
			draw_rect(Rect2(r.position.x + 1, r.position.y + 1, 10, r.size.y - 2), T.GOLD)
			T.text(self, Vector2(r.position.x + 6, r.position.y + 19), str(equipped.find(sid) + 1), 10, T.INK, HORIZONTAL_ALIGNMENT_CENTER, 0)
		else:
			draw_rect(Rect2(r.position.x + 2, r.position.y + 3, 2, r.size.y - 6), T.kind_col(String(s.kind)))
		TIcon.draw(self, r.position + Vector2(21, 15), String(s.get("icon", "strike")), ecol if (on or cur) else Color(ecol, 0.7), 7.5)
		T.text(self, r.position + Vector2(33, 19), T.clip(String(s.name), 10, 63), 10, T.TEXT if (on or cur) else T.TEXT_SUB)
		T.cost_badge(self, r.position + Vector2(104, 9), str(int(s.cost)))
		var sl := int(slv.get(sid, 1))
		if sl > 1:
			T.text(self, r.end - Vector2(3, 3), "Lv%d" % sl, 8, T.GOLD, HORIZONTAL_ALIGNMENT_RIGHT, 2)
		if held:
			draw_arc(r.position + Vector2(21, 15), 12.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(float(_press.t) / HOLD, 0.0, 1.0), 24, T.GOLD, 2.0)
	# 대마법 줄 (장착 칸 아님 — 누르면 설명)
	var uid := String(w.get("ultimate", ""))
	var ult := TData.skill(uid)
	T.panel(self, ULT_ROW, Color(T.GOLD, 0.12), T.TEXT if cursor == 10 else Color(T.GOLD, 0.8), 2 if cursor == 10 else 1, 3)
	TIcon.draw(self, ULT_ROW.position + Vector2(17, 15), String(ult.get("icon", "burst")), T.GOLD, 7.5)
	var ul := "대마법  " + String(ult.get("name", ""))
	T.text(self, ULT_ROW.position + Vector2(30, 19), ul, 10, T.GOLD)
	var ur := "크레딧 7 · 바퀴 끝 칸"
	if T.width(ul, 10) + T.width(ur, 10) + 46.0 > ULT_ROW.size.x:
		ur = "크레딧 7" # 이름이 길면 줄여서 (review_G G13 — "불새의 축복크레딧 7"처럼 붙었다)
	if T.width(ul, 10) + T.width(ur, 10) + 46.0 <= ULT_ROW.size.x:
		T.text(self, ULT_ROW.end - Vector2(8, 11), ur, 10, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_RIGHT)
	# 장비 줄 (길게 누르면 강화 Lv)
	var has_eq := String(state[wid].equip) != ""
	var eheld := not _press.is_empty() and String(_press.what) == "equip"
	T.panel(self, EQUIP_ROW, Color(T.INK, 0.6), T.TEXT if cursor == 11 else Color(T.GOLD, 0.5), 2 if cursor == 11 else 1, 3)
	draw_circle(EQUIP_ROW.position + Vector2(14, 14), 6.0, Color(T.INK, 0.9))
	draw_arc(EQUIP_ROW.position + Vector2(14, 14), 6.0, 0.0, TAU, 16, T.GOLD if has_eq else T.TEXT_OFF, 1.5)
	if eheld:
		draw_arc(EQUIP_ROW.position + Vector2(14, 14), 10.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(float(_press.t) / HOLD, 0.0, 1.0), 24, T.GOLD, 2.0)
	var etxt := "장비 %s%s — %s" % [String(eq.get("name", "없음")), " Lv%d" % lv if lv > 1 and has_eq else "", String(eq.get("desc", ""))] if has_eq else "장비 없음 — 편성 카드의 장비 칸에서 고릅니다"
	T.text(self, EQUIP_ROW.position + Vector2(26, 18), T.clip(etxt, 10, EQUIP_ROW.size.x - 32), 10, T.GOLD if has_eq else T.TEXT_SUB)
	T.wrap(self, Vector2(152, 286), "마법·장비를 길게 누르면 강화 Lv", 222, 10, T.TEXT_OFF, 12.0, 2)
	# 오른쪽: 큰 설명 상자
	if cursor >= 0 and cursor < skills.size():
		_draw_desc(String(skills[cursor]), int(slv.get(String(skills[cursor]), 1)))
	elif cursor == 10:
		_draw_desc(uid, 1)
	elif cursor == 11:
		_draw_equip_desc(String(state[wid].equip), lv)
	elif cursor == 13:
		_draw_passive_desc(w)
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
	var line2 := "비용 %d · %s" % [int(s.cost), T.kind_label(s)] # 배율은 효과 글에 있어 뺌 (review_G G12)
	if lv > 1:
		line2 += " · Lv%d" % lv
	T.text(self, Vector2(x, y), line2, 10, kcol)
	y += 6
	draw_line(Vector2(x, y), Vector2(x + DESC_W, y), Color(T.LINE, 0.35), 1.0)
	y += 14
	var bf := T.body_fs()
	var lh := T.body_lh()
	y += T.wrap(self, Vector2(x, y), String(TData.skill(sid).desc), DESC_W, bf, T.TEXT, lh)
	y += 4
	# 효과를 항목으로 (수치가 한눈에, 강화 레벨 반영)
	for e in s.get("effects", []):
		var t := _effect_line(e)
		if t == "":
			continue
		draw_circle(Vector2(x + 3, y - 4), 1.6, Color(kcol, 0.9))
		y += T.wrap(self, Vector2(x + 9, y), t, DESC_W - 9, bf, T.TEXT_SUB, lh, 2)
	y += 4
	var gl := TData.gloss_for(String(TData.skill(sid).desc) + " " + String(s.get("name", "")))
	if gl != "" and y < 276:
		y += T.wrap(self, Vector2(x, y + 8), gl, DESC_W, 10, T.TEXT_OFF, 13.0, maxi(1, mini(3, int((292.0 - y) / 13.0)))) + 8.0 # 용어 풀이 한 줄 (review_F F08)
	if dev and y < 280:
		T.wrap(self, Vector2(x, y + 8), "참고 구조: " + String(s.get("ref", "")), DESC_W, 10, T.TEXT_OFF, 13.0, maxi(1, int((290.0 - y) / 13.0)))
	# 공격이면 예상 피해 (짚 골렘 기준, 버프 없음)
	if kind == "attack":
		var u := TUnit.make_witch(_wid(), state[_wid()], 0)
		var en := TUnit.make_enemy("straw_golem", 0)
		var b := TBattle.new()
		var est := b.estimate(u, en, sid)
		var est_c := b.estimate(u, en, sid, true)
		T.text(self, Vector2(x + DESC_W, 308), T.est_text(est, est_c, "짚 골렘에게 예상"), 10, T.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)


func _draw_equip_desc(eid: String, lv: int) -> void:
	var x := DESC_X
	if eid == "":
		T.text(self, Vector2(x, 56), "장비 없음", 15, T.TEXT) # 제목 기준선 +4 (위 테에 붙지 않게, L7)
		T.wrap(self, Vector2(x, 80), "편성 카드의 장비 칸을 누르면 목록이 열립니다(◀ ▶로 하나씩도 됩니다). 한 장비는 파티에 한 명만 낄 수 있어, 다른 파티원이 낀 장비는 건너뜁니다.", DESC_W, 10, T.TEXT_SUB, 13.0)
		return
	T.text(self, Vector2(x, 56), String(TData.EQUIPS[eid].name), 15, T.GOLD)
	T.text(self, Vector2(x + DESC_W, 55), "Lv%d" % lv, 10, T.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	var y := 80.0
	for l in [1, 2, 3]:
		var e := TData.equip_at(eid, l)
		var col := T.TEXT if l == lv else T.TEXT_OFF
		T.text(self, Vector2(x, y), "Lv%d" % l, 10, T.GOLD if l == lv else T.TEXT_OFF)
		y += T.wrap(self, Vector2(x + 28, y), String(e.desc), DESC_W - 28, 10, col, 13.0) + 4.0
	T.wrap(self, Vector2(x, y + 10), "한 장비는 파티에 한 명만 (다른 파티원이 낀 장비는 건너뜀). 편성 카드의 장비 칸을 누르면 목록. 길게 누르면 강화 Lv.", DESC_W, 10, T.TEXT_SUB, 13.0)


## 3단계: 전투 고르기 (단계 F-2 다시 정리 — review_H §7.1 · F04 화면안): 위 탭 "일반 6 · 보스 3 · 시련 1" · 왼쪽 목록(줄 = 종류 띠 · 이름 · 웨이브별 약점 아이콘 ·
## 난이도 별 · 예상 시간 · 깸/추천) · 오른쪽 고른 전투 상세(마지막 웨이브 적 그림 · 웨이브별 적 · 묻는 것) + 출격. 첫 실행 안내 중엔 탭 없이 안내 전투 한 줄
func _draw_battles() -> void:
	T.text(self, Vector2(12, 22), "전투 고르기", 15, T.TEXT)
	var ids := _visible_ids()
	var all := battle_ids()
	if all.size() > 1:
		T.text(self, Vector2(104, 21), "줄을 누르고 출격 · 길게 누르면 자세히", 10, T.TEXT_SUB)
		for i in TABS.size():
			var r := _tab3_rect(i)
			var on := String(TABS[i]) == _tab3
			var tag: Array = KIND_TAG[TABS[i]]
			var n := 0
			for b in all:
				if String(TData.BATTLES[b].kind) == String(TABS[i]):
					n += 1
			T.panel(self, r, Color(tag[1], 0.25) if on else Color(T.PANEL, 0.9), tag[1] if on else Color(T.LINE, 0.4), 2 if on else 1, 3)
			T.text(self, r.get_center() + Vector2(0, 5), "%s %d" % [tag[0], n], 12, T.TEXT if on else T.TEXT_SUB, HORIZONTAL_ALIGNMENT_CENTER)
	var rec := ""
	for b in all:
		if not TSave.cleared.has(String(b)):
			rec = String(b)
			break
	for i in ids.size():
		_draw_battle_row(String(ids[i]), _battle_rect(i), String(ids[i]) == rec and all.size() > 1)
	_draw_battle_detail(battle_pick)
	_button(BACK3_RECT, "← 편성", false)
	_button(START1_RECT, "출격", true, 0.8 + 0.2 * sin(_t * 4.0))
	_msg_line(Vector2(140, 320), 250, "")


## 목록 한 줄: 왼쪽 종류 색 띠 · 이름 · 아래 웨이브별 약점(웨이브 사이 "▶", 약점 없으면 "—") · 오른쪽 난이도 별 · 시간 · 깸/추천
func _draw_battle_row(bid: String, r: Rect2, rec: bool) -> void:
	var bd: Dictionary = TData.BATTLES[bid]
	var on := bid == battle_pick
	var tag: Array = KIND_TAG.get(String(bd.kind), KIND_TAG.normal)
	T.panel(self, r, Color(T.PANEL_HI if on else T.PANEL, 0.95), T.GOLD if on else Color(T.LINE, 0.35), 2 if on else 1, 3)
	draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(4, r.size.y - 4)), Color(tag[1], 0.9))
	var X := r.position.x + 12.0
	T.text(self, Vector2(X, r.position.y + 15), _battle_title(bid), 12, T.TEXT if on else Color(T.TEXT, 0.9))
	# 웨이브별 약점 아이콘
	var wx := X
	var waves: Array = bd.waves
	for wi in waves.size():
		if wi > 0:
			T.text(self, Vector2(wx + 1, r.position.y + 31), "▶", 8, T.TEXT_OFF)
			wx += 10.0
		var wk := _wave_weak(waves[wi])
		if wk.is_empty():
			T.text(self, Vector2(wx + 2, r.position.y + 31), "—", 10, T.TEXT_OFF)
			wx += 12.0
		for el in wk:
			draw_rect(Rect2(wx, r.position.y + 21, 11, 11), Color(T.INK, 0.9))
			draw_rect(Rect2(wx + 0.5, r.position.y + 21.5, 10, 10), Color(T.WEAK, 0.9), false, 1.0)
			T.element_icon(self, Vector2(wx + 5.5, r.position.y + 26.5), String(el), 4.2)
			wx += 13.0
	# 오른쪽: 별 · 시간
	var rx := r.end.x - 8.0
	T.text(self, Vector2(rx, r.position.y + 31), "약 %d분" % int(bd.get("mins", 0)), 10, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_RIGHT)
	for k in 3:
		T.star(self, Vector2(rx - 44.0 + 9.0 * float(k), r.position.y + 10), 3.6, T.GOLD if k < int(bd.get("stars", 1)) else T.EMPTY)
	# 깸 · 추천 배지 (진행 표시 — 결과 기록이 아님, §27.6 ③)
	var badge := "깸" if TSave.cleared.has(bid) else ("추천" if rec else "")
	if badge != "":
		var bc := T.HP_ALLY if badge == "깸" else T.GOLD
		var bw := T.width(badge, 10) + (18.0 if badge == "깸" else 8.0)
		var br := Rect2(rx - 44.0 - bw - 10.0, r.position.y + 3, bw, 14)
		T.panel(self, br, Color(T.INK, 0.95), bc, 1, 2)
		if badge == "깸":
			draw_polyline(PackedVector2Array([br.position + Vector2(4, 7), br.position + Vector2(7, 10), br.position + Vector2(12, 4)]), bc, 1.6)
			T.text(self, Vector2(br.end.x - 4, br.position.y + 11), badge, 10, bc, HORIZONTAL_ALIGNMENT_RIGHT)
		else:
			T.text(self, Vector2(br.get_center().x, br.position.y + 11), badge, 10, bc, HORIZONTAL_ALIGNMENT_CENTER)


## 오른쪽 상세: 종류·이름 · 마지막 웨이브 적 그림(노드 _foes) · 웨이브별 적 · 약점(웨이브마다, 보스 줄마다) · 묻는 것 · 난이도 · 시간
func _draw_battle_detail(bid: String) -> void:
	var bd: Dictionary = TData.BATTLES.get(bid, {})
	if bd.is_empty():
		return
	var r := DETAIL3
	var tag: Array = KIND_TAG.get(String(bd.kind), KIND_TAG.normal)
	T.panel(self, r, Color(T.PANEL, 0.95), Color(tag[1], 0.6), 1, 4)
	T.panel(self, Rect2(r.position + Vector2(8, 8), Vector2(T.width(String(tag[0]), 10) + 12, 15)), Color(tag[1], 0.2), tag[1], 1, 2)
	T.text(self, r.position + Vector2(14, 20), String(tag[0]), 10, tag[1])
	T.text(self, r.position + Vector2(T.width(String(tag[0]), 10) + 26, 21), _battle_title(bid), 15, T.TEXT)
	# 적 그림 자리 (바닥 타원)
	draw_set_transform(r.position + Vector2(r.size.x * 0.5, 128), 0.0, Vector2(1.0, 0.25))
	draw_circle(Vector2.ZERO, 70.0, Color(tag[1], 0.1))
	draw_set_transform(Vector2.ZERO)
	var y := r.position.y + 146.0
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
		var head := "웨이브 %d" % (wi + 1) if waves.size() > 1 else "적"
		T.text(self, Vector2(r.position.x + 10, y), head, 10, T.TEXT_SUB)
		T.text(self, Vector2(r.position.x + 62, y), T.clip(" · ".join(parts), 10, r.size.x - 70), 10, T.TEXT)
		y += 13.0
	# 약점: 보스가 줄마다 바뀌면 "줄 1 ▶ 줄 2 ▶ 줄 3"
	var boss_ph: Array = []
	for item in waves[waves.size() - 1]:
		var eid := String(item.id) if item is Dictionary else String(item)
		if (TData.ENEMIES[eid].get("phases", []) as Array).size() > 1:
			boss_ph = TData.ENEMIES[eid].phases
			boss_ph = [{"weak": TData.ENEMIES[eid].get("weak", [])}] + boss_ph.slice(1)
	T.text(self, Vector2(r.position.x + 10, y + 2), "약점", 10, T.TEXT_SUB)
	var wx := r.position.x + 62.0
	var groups: Array = []
	if not boss_ph.is_empty():
		for p in boss_ph:
			groups.append(p.get("weak", []))
	else:
		groups = [_battle_weak(bid)]
	for gi in groups.size():
		if gi > 0:
			T.text(self, Vector2(wx + 1, y + 2), "▶", 8, T.TEXT_OFF)
			wx += 10.0
		if (groups[gi] as Array).is_empty():
			T.text(self, Vector2(wx, y + 2), "없음", 10, T.TEXT_OFF)
			wx += 26.0
		for el in groups[gi]:
			draw_rect(Rect2(wx, y - 8, 11, 11), Color(T.INK, 0.9))
			draw_rect(Rect2(wx + 0.5, y - 7.5, 10, 10), Color(T.WEAK, 0.9), false, 1.0)
			T.element_icon(self, Vector2(wx + 5.5, y - 2.5), String(el), 4.2)
			wx += 13.0
	if not boss_ph.is_empty():
		T.text(self, Vector2(wx + 4, y + 2), "(보스 줄마다)", 8, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_LEFT, 0)
	y += 16.0
	T.wrap(self, Vector2(r.position.x + 10, y), String(bd.get("ask", "")), r.size.x - 20, 10, T.GOLD, 12.0, 2)
	var sy := r.end.y - 9.0
	T.text(self, Vector2(r.position.x + 10, sy + 4), "난이도", 10, T.TEXT_SUB)
	for k in 3:
		T.star(self, Vector2(r.position.x + 52 + 12 * k, sy), 4.5, T.GOLD if k < int(bd.get("stars", 1)) else T.EMPTY)
	T.text(self, Vector2(r.end.x - 8, sy + 4), "예상 약 %d분" % int(bd.get("mins", 0)), 10, T.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)


## 웨이브 하나의 약점 (적들의 약점 합, 처음 줄 기준)
func _wave_weak(wave: Array) -> Array:
	var out: Array = []
	for item in wave:
		var eid := String(item.id) if item is Dictionary else String(item)
		for el in TUnit.make_enemy(eid, 0).weak:
			if not out.has(String(el)):
				out.append(String(el))
	return out


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


## 패시브 전문 (S-02 왼쪽 패시브를 누름)
func _draw_passive_desc(w: Dictionary) -> void:
	var pas: Dictionary = w.get("passive", {})
	T.text(self, Vector2(DESC_X, 56), "패시브 " + String(pas.get("name", "")), 15, T.GOLD)
	T.text(self, Vector2(DESC_X + DESC_W, 55), String(w.name), 10, TData.ELEMENT_COLOR.get(w.element, T.LINE), HORIZONTAL_ALIGNMENT_RIGHT)
	var y := 80.0
	y += T.wrap(self, Vector2(DESC_X, y), String(pas.get("desc", "")), DESC_W, 10, T.TEXT, 13.0) + 8.0
	T.wrap(self, Vector2(DESC_X, y), "패시브는 늘 켜져 있고 해제되지 않습니다 (버프가 아님).", DESC_W, 10, T.TEXT_SUB, 13.0)


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
	T.wrap(self, Vector2(DESC_X, y), "마법 타일을 누르면 여기에 비용·종류·대상·효과·수치가 나옵니다. 한 번 더 누르면 장착합니다. 길게 누르면 강화 레벨이 바뀝니다.", DESC_W, 10, T.TEXT_SUB, 13.0)


## 명단을 길게 누르는 동안: 그 마녀 상세 (S-02 왼쪽·설명 상자와 같은 내용 — 능력치·속성·역할·대마법·패시브, review_G G10)
func _draw_peek(ci: CanvasItem, wid: String) -> void:
	var w: Dictionary = TData.WITCHES[wid]
	var ecol: Color = TData.ELEMENT_COLOR.get(w.element, T.LINE)
	var r := Rect2(16, 40, 376, 268)
	T.panel(ci, r, Color(T.INK, 0.98), Color(ecol, 0.8), 1, 4)
	var x := r.position.x + 12.0
	T.text(ci, Vector2(x, r.position.y + 22), String(w.name), 15, T.TEXT)
	T.text(ci, Vector2(r.end.x - 12, r.position.y + 21), String(w.title), 10, ecol, HORIZONTAL_ALIGNMENT_RIGHT)
	var bf := T.body_fs()
	var lh := T.body_lh()
	var y := r.position.y + 42.0
	var st := "공격 %s · 체력 %s · 속도 %d · 방어 %d%%" % [TData.fmt(int(w.atk)), TData.fmt(int(w.hp)), int(w.speed), int(round(float(w.def) * 100.0))]
	y += T.wrap(ci, Vector2(x, y), st, r.size.x - 24, bf, T.TEXT, lh) + 4.0
	var el := "속성 %s%s · 역할 %s" % [TData.ELEMENT_NAME.get(w.element, ""), " (모든 적에게 1.2배)" if bool(w.special) else "", TData.ROLE_NAME.get(String(w.get("role", "")), "")]
	y += T.wrap(ci, Vector2(x, y), el, r.size.x - 24, bf, ecol, lh) + 6.0
	var ult := TData.skill(String(w.get("ultimate", "")))
	y += T.wrap(ci, Vector2(x, y), "대마법 %s — %s" % [String(ult.get("name", "")), String(ult.get("desc", ""))], r.size.x - 24, bf, T.GOLD, lh, 3) + 6.0
	var pas: Dictionary = w.get("passive", {})
	y += T.wrap(ci, Vector2(x, y), "패시브 %s — %s" % [String(pas.get("name", "")), String(pas.get("desc", ""))], r.size.x - 24, bf, T.TEXT_SUB, lh, 3) + 6.0
	y += T.wrap(ci, Vector2(x, y), "기본 공격 %s — %s" % [String(w.basic.name), String(w.basic.desc)], r.size.x - 24, bf, T.TEXT, lh, 2) + 6.0
	T.text(ci, Vector2(r.get_center().x, r.end.y - 10), "떼면 닫힘 · 짧게 누르면 이 자리에 넣기", 10, T.TEXT_OFF, HORIZONTAL_ALIGNMENT_CENTER)


# ── 장비 목록 판 (review_G G11 · review_F F11): 15칸 한눈에. 한 번 누르면 설명, 다시 누르면 낌. 다른 파티원이 낀 것은 흐림

func _open_equip_list(slot: int) -> void:
	_eq_slot = slot
	_eq_pick = String(state[String(party()[slot])].equip)
	Sfx.play(&"tn_select", -10.0)


func _eq_cell(i: int) -> Rect2:
	return Rect2(EQ_LIST.position.x + 12 + 134 * (i % 4), EQ_LIST.position.y + 34 + 44 * (i / 4), 128, 40)


func _equip_list_press(p: Vector2) -> void:
	var wid := String(party()[_eq_slot])
	for i in TData.EQUIP_ORDER.size():
		if _eq_cell(i).has_point(p):
			var eid := String(TData.EQUIP_ORDER[i])
			if TData.equip_taken(state, eid, wid):
				_say("%s는 다른 파티원이 끼고 있습니다" % String(TData.EQUIPS[eid].name))
				Sfx.play(&"tn_cancel", -10.0)
				return
			if _eq_pick == eid:
				state[wid].equip = eid
				var eq: Dictionary = TData.EQUIPS[eid]
				_say("%s 장비: %s — %s" % [TData.WITCHES[wid].name, eq.name, eq.desc])
				TSave.save_soon()
				_eq_slot = -1
				Sfx.play(&"tn_confirm", -8.0)
			else:
				_eq_pick = eid
				Sfx.play(&"tn_select", -12.0)
			return
	if EQ_CLOSE.has_point(p) or not EQ_LIST.has_point(p):
		_eq_slot = -1
		Sfx.play(&"tn_cancel", -10.0)


func _draw_equip_list(ci: CanvasItem) -> void:
	var wid := String(party()[_eq_slot])
	ci.draw_rect(Rect2(Vector2.ZERO, size), Color(T.INK, 0.55))
	T.panel(ci, EQ_LIST, Color(T.PANEL, 0.98), Color(T.LINE, 0.9), 1, 4)
	T.text(ci, EQ_LIST.position + Vector2(12, 22), "장비 — %s" % String(TData.WITCHES[wid].name), 15, T.TEXT)
	T.text(ci, Vector2(EQ_LIST.end.x - 12, EQ_LIST.position.y + 21), "한 번 누르면 설명 · 다시 누르면 낌", 10, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_RIGHT)
	var cur := String(state[wid].equip)
	for i in TData.EQUIP_ORDER.size():
		var eid := String(TData.EQUIP_ORDER[i])
		var r := _eq_cell(i)
		var taken := TData.equip_taken(state, eid, wid)
		var on := eid == _eq_pick
		T.panel(ci, r, Color(T.PANEL_HI, 1.0) if on else Color(T.INK, 0.75), T.TEXT if on else (T.GOLD if eid == cur else Color(T.LINE, 0.35)), 2 if on or eid == cur else 1, 3)
		var nm := String(TData.EQUIPS[eid].name) if eid != "" else "없음"
		var col := T.TEXT_OFF if taken else (T.GOLD if eid == cur else T.TEXT)
		var ls := T.split_lines(nm, r.size.x - 10, 10)
		for k in mini(ls.size(), 2):
			T.text(ci, Vector2(r.position.x + 6, r.position.y + (16 if ls.size() > 1 else 24) + 12 * k), String(ls[k]), 10, col)
		if taken:
			for w2 in party():
				if String(w2) != wid and String(state[String(w2)].equip) == eid and eid != "":
					T.text(ci, Vector2(r.end.x - 4, r.end.y - 4), String(TData.WITCHES[String(w2)].name), 8, T.TEXT_OFF, HORIZONTAL_ALIGNMENT_RIGHT, 0)
		elif eid == cur:
			T.text(ci, Vector2(r.end.x - 4, r.end.y - 4), "낀 것", 8, T.GOLD, HORIZONTAL_ALIGNMENT_RIGHT, 0)
	var e: Dictionary = TData.equip_at(_eq_pick, int(state[wid].get("equip_lv", 1)) if _eq_pick == cur else 1) if _eq_pick != "" else {}
	var dy := EQ_LIST.position.y + 34 + 44 * 4 + 14.0
	if _eq_pick == "":
		T.text(ci, Vector2(EQ_LIST.position.x + 12, dy), "없음 — 장비를 끼지 않습니다", 10, T.TEXT_SUB)
	else:
		T.text(ci, Vector2(EQ_LIST.position.x + 12, dy), String(e.get("name", "")), 12, T.GOLD)
		T.wrap(ci, Vector2(EQ_LIST.position.x + 12, dy + 16), String(e.get("desc", "")), 420, T.body_fs(), T.TEXT, T.body_lh(), 3)
	_button(EQ_CLOSE, "닫기", true, 1.0, ci)


## 편성 위 판(장비 목록·명단 상세)은 미리보기 그림(TActor)보다 위에 그려야 해서 마지막 자식 Control에 그린다
func _draw_overlays(ci: CanvasItem) -> void:
	if _peek != "":
		_draw_peek(ci, _peek)
	if _eq_slot >= 0:
		_draw_equip_list(ci)


class Overlay extends Control:
	var setup: TSetup

	func _draw() -> void:
		setup._draw_overlays(self)
