class_name THud
extends Control
## 턴제 전투 화면 표시 + 입력 (터치 우선, 키보드도 같은 흐름). 배치는 combat_proto.md §21.5 (3단: 위 = 적 정보 · 가운데 = 그림 · 아래 = 아군 정보).
## 위 띠: 차례 줄(다음 8명) · 전투 이름/웨이브 · 연쇄 단계 · 나가기 X.  그 아래 왼쪽: 행동 띠(지금 행동 이름·안내 1.6초).
## 오른쪽 위: 적 카드 3장(의도 종류·차지 칸·이름·약점·체력 막대·숫자·징표/디버프) — 보스 1명이면 넓은 보스 카드(남은 줄 칸).
## 아래 띠: 평소엔 아군 패널 3장(초상·이름·체력·크레딧 7칸·버프 아이콘·게이지), 바퀴가 열리면 설명 띠(이름·비용·예상 피해(크리 값)·효과·크레딧·안내).
## 머리 위엔 게이지·얇은 체력(마녀) / 의도 아이콘(적) · 기절 별 · 대상 화살표만.
## 스킬 바퀴: 차례 마녀 몸 둘레 위쪽 반원, 칸 6개 고정(기본 공격 → 장착 4 → 대마법). 한 번 누르면 고르고, 다시 누르면 사용/대상 고르기.
## 유닛·적 카드·아군 패널·차례 칸을 0.4초 누르면 상세 판(떼면 닫힘). 키보드: ←→↑↓ 고르기 · Z 확인 · X 뒤로 · Esc 철수 확인.
## 피해 숫자는 맞은 몸 가운데에서(다단은 오른쪽 아래로 비켜 쌓기), 버프 글은 아군 패널 위 / 적 카드 아래에서 뜬다.

signal chosen(action: Dictionary)
signal banner_tapped(choice: String) ## "setup" · "retry"
signal exit_tapped

const T := preload("res://proto/turn/t_theme.gd")
const QUEUE_N := 8
const ACT_STRIP := Rect2(6, 32, 300, 18)
const CARD_X0 := 328.0
const CARD_STEP := 104.0
const CARD_Y := 32.0
const CARD_W := 100.0
const CARD_H := 50.0
const BOSS_CARD := Rect2(328, 32, 308, 50)
const PANEL_X0 := 4.0
const PANEL_STEP := 212.0
const PANEL_Y := 302.0
const PANEL_W := 208.0
const PANEL_H := 56.0
const STRIP := Rect2(4, 302, 632, 56)
const X_C := Vector2(620, 15)
const X_RECT := Rect2(600, 0, 40, 32)
const WHEEL_R := 78.0
const SLOT_R := 20.0
const ULT_R := 22.0
const HOLD := 0.4 ## 길게 누르기 (상세)
const CONFIRM := Rect2(220, 140, 200, 80)
const CONFIRM_NO := Rect2(232, 186, 84, 28)
const CONFIRM_YES := Rect2(324, 186, 84, 28)
const LOSE_RETRY := Rect2(206, 196, 108, 26)
const LOSE_SETUP := Rect2(326, 196, 108, 26)
const DETAIL_W := 232.0
const DETAIL_H := 180.0
## 차례 줄의 적 글자
const SHORT := {"straw_golem": "골", "swamp_toad": "두", "ash_knight": "기", "ash_king": "왕", "trial_colossus": "거"}
## 피해 숫자 종류 → [글꼴 크기, 색]
const NUM_STYLE := {"dmg": [12, Color("#fff3e0")], "crit": [24, Color("#ffe08a")], "weak": [15, Color("#ffcf4a")], "big": [24, Color("#fff3e0")],
	"hurt": [15, Color("#ff8a9a")], "heal": [12, Color("#b8f0a0")], "revive": [12, Color("#e6dcff")], "total": [12, Color("#ffe08a")],
	"status": [12, Color("#cfcfe0")], "break": [15, Color("#ffe08a")], "buff": [10, Color("#d9ccff")], "debuff": [10, Color("#c9b8c8")],
	"credit": [10, Color("#ffe08a")], "zero": [10, Color("#ff4f6a")], "mark": [10, Color("#ffb08a")]}
const BODY_KINDS := ["dmg", "crit", "weak", "big", "hurt", "heal", "revive", "total"]

var stage: Node
var battle: TBattle
var actors := {} ## TUnit → TActor
var state := "idle" ## idle · wheel · target · banner
var actor: TActor
var slots: Array = [] ## [{id, name, cost, can, pos, kind, target, icon, empty, ult}] — 늘 6칸
var sel := -1 ## 고른 칸 (−1 = 없음)
var targets: Array = [] ## 고를 수 있는 대상 TActor
var tsel := 0
var banner_text := ""
var banner_sub := ""
var msg := ""
var msg_t := 0.0
var msg_col := T.LINE
var numbers: Array = [] ## [{p, text, kind, age, dir, weak, key}]
var confirm_open := false ## 철수 확인 판
var battle_name := ""
var _t := 0.0
var _queue: Array = []
var _banner_t := 0.0
var _touch_seen := false
var _press := {} ## 누르는 중: {pos, t, unit}
var _detail: TUnit = null ## 상세 판에 띄운 유닛
var _flash := {} ## TUnit → 남은 시간 (차례 칸을 눌러 그 유닛을 알려 줌)
var _wave_t := 0.0 ## 웨이브 배너 남은 시간
var _wave_txt := ""
var _wave_flash := 0.0
var _back: PanelBack
var _portraits := {} ## TUnit → PortraitBox


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back = PanelBack.new()
	_back.hud = self
	_back.show_behind_parent = true
	_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_back)


func bind(b: TBattle, a: Dictionary) -> void:
	battle = b
	actors = a
	numbers.clear()
	state = "idle"
	actor = null
	confirm_open = false
	_detail = null
	_press = {}
	_wave_t = 0.0
	battle_name = String(TData.BATTLES.get(b.battle_id, {}).get("name", ""))
	_build_portraits()
	refresh()


func refresh() -> void:
	if battle != null:
		_queue = battle.preview(QUEUE_N)
	queue_redraw()


func to_screen(world: Vector2) -> Vector2:
	var vp := get_viewport()
	if vp == null:
		return world
	return vp.get_canvas_transform() * world


## 적 n명 웨이브에서 i번째 적이 서는 화면 자리 (0 앞 · 1 중 · 2 뒤): 1명 = 가운데, 2명 = 앞·뒤 (review_C §5.3)
static func pos_index(n: int, i: int) -> int:
	match n:
		1: return 1
		2: return 0 if i == 0 else 2
	return clampi(i, 0, 2)


func _process(delta: float) -> void:
	_t += delta
	size = get_viewport_rect().size # 캔버스 층 아래 Control은 앵커로 화면 크기를 못 받는다
	_back.size = size
	_back.queue_redraw()
	msg_t = maxf(msg_t - delta, 0.0)
	_banner_t += delta
	_wave_t = maxf(_wave_t - delta, 0.0)
	_wave_flash = maxf(_wave_flash - delta, 0.0)
	for k in _flash.keys():
		_flash[k] = float(_flash[k]) - delta
		if float(_flash[k]) <= 0.0:
			_flash.erase(k)
	if not _press.is_empty() and _detail == null:
		_press.t = float(_press.t) + delta / maxf(Engine.time_scale, 0.01) # 멈춤(히트스톱) 중에도 실제 시간으로
		if float(_press.t) >= HOLD and _press.get("unit") != null:
			_detail = _press.unit
			Sfx.play(&"tn_select", -12.0)
	for n: Dictionary in numbers:
		n.age = float(n.age) + delta
	numbers = numbers.filter(func(n: Dictionary) -> bool: return float(n.age) < 1.1)
	_layout_portraits()
	queue_redraw()


# ═══════════════════════════════════════════════════════════
# 바깥에서 부르는 것
# ═══════════════════════════════════════════════════════════

## 마녀의 차례: 바퀴를 열고 chosen 신호를 기다린다
func open_wheel(a: TActor) -> void:
	actor = a
	state = "wheel"
	sel = -1
	targets.clear()
	_build_slots()
	_dim_others(true)
	_layout_portraits()
	Sfx.play(&"tn_turn", -8.0)
	queue_redraw()


func close_wheel() -> void:
	_dim_others(false)
	state = "idle"
	actor = null
	slots.clear()
	targets.clear()
	_layout_portraits()
	queue_redraw()


## 행동 띠 (왼쪽 위): 행동 이름·안내 1.6초. col = 왼쪽 띠 색 (마녀 속성 색 · 적 DANGER)
func show_msg(s: String, col := T.LINE) -> void:
	msg = s
	msg_t = 1.6
	msg_col = col


func banner(text: String, sub: String) -> void:
	banner_text = text
	banner_sub = sub
	state = "banner"
	_banner_t = 0.0
	queue_redraw()


func clear_banner() -> void:
	banner_text = ""
	state = "idle"


## 웨이브 배너 (1.0초 뒤 저절로 닫힘, 누르기 없음) → 위 띠의 웨이브 글이 0.4초 금빛
func wave_banner(i: int, n: int) -> void:
	_wave_txt = "웨이브 %d/%d" % [i, n]
	_wave_t = 1.0
	_wave_flash = 1.4


## 숫자·글 띄우기 (u = 맞은/받은 유닛). kind: dmg · crit · weak · big · hurt · heal · revive · total · status · break · buff · debuff · credit · zero · mark
## weak = 위에 "약점" 꼬리표
func pop(u: TUnit, text: String, kind := "dmg", weak := false) -> void:
	if u == null or not actors.has(u):
		return
	var a: TActor = actors[u]
	var key := "%d:%s" % [u.get_instance_id(), "body" if kind in BODY_KINDS else ("st" if kind in ["status", "break"] else "txt")]
	var k := 0
	for n: Dictionary in numbers:
		if String(n.key) == key and float(n.age) < 0.5:
			k += 1
	var p := Vector2.ZERO
	var dir := -1.0
	var age := 0.0
	if kind in BODY_KINDS:
		p = to_screen(a.center()) + Vector2(8, 10) * float(k % 6) # 다단: 오른쪽 아래로 비켜 쌓기
	elif kind in ["status", "break"]:
		p = to_screen(a.center()) + Vector2(0, -16 - 14 * (k % 3))
	elif u.is_witch():
		p = Vector2(_panel_rect(u.slot).position.x + 104.0, PANEL_Y - 4.0) + Vector2(0, -12.0 * float(k % 2))
		age = -0.35 * float(k / 2) # 한 패널에 두 줄씩, 나머지는 늦춰서
	else:
		var cr := _card_rect(u)
		p = Vector2(cr.position.x + cr.size.x * 0.5, cr.end.y + 12.0) + Vector2(0, 12.0 * float(k % 2))
		age = -0.35 * float(k / 2)
		dir = 1.0
	numbers.append({"p": p, "text": text, "kind": kind, "age": age, "dir": dir, "weak": weak, "key": key})
	if numbers.size() > 48:
		numbers.pop_front()


# ═══════════════════════════════════════════════════════════
# 입력
# ═══════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		_touch_seen = true
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
	if event is InputEventKey and event.pressed and not event.echo:
		_touch_seen = false
	if confirm_open:
		if event.is_action_pressed("es_jump"):
			_confirm_yes()
		elif event.is_action_pressed("es_attack") or event.is_action_pressed("es_exit"):
			_confirm_no()
		return
	if event.is_action_pressed("es_exit"):
		_ask_exit()
		return
	if state == "banner":
		if banner_text == "패배":
			if event.is_action_pressed("es_jump"):
				_banner_go("retry")
			elif event.is_action_pressed("es_attack"):
				_banner_go("setup")
		elif event.is_action_pressed("es_jump") or event.is_action_pressed("es_attack"):
			_banner_go("setup")
		return
	if state == "wheel":
		if event.is_action_pressed("es_right") or event.is_action_pressed("es_down"):
			_move_sel(1)
		elif event.is_action_pressed("es_left") or event.is_action_pressed("es_up"):
			_move_sel(-1)
		elif event.is_action_pressed("es_jump"):
			if sel < 0:
				_move_sel(1)
			else:
				_confirm_slot()
		elif event.is_action_pressed("es_attack"):
			sel = -1
			Sfx.play(&"tn_cancel", -10.0)
			queue_redraw()
	elif state == "target":
		if event.is_action_pressed("es_right") or event.is_action_pressed("es_down"):
			tsel = (tsel + 1) % targets.size()
			Sfx.play(&"tn_select", -12.0)
		elif event.is_action_pressed("es_left") or event.is_action_pressed("es_up"):
			tsel = (tsel - 1 + targets.size()) % targets.size()
			Sfx.play(&"tn_select", -12.0)
		elif event.is_action_pressed("es_jump"):
			_choose_target(targets[tsel])
		elif event.is_action_pressed("es_attack"):
			state = "wheel"
			targets.clear()
			Sfx.play(&"tn_cancel", -10.0)
		queue_redraw()


func _move_sel(d: int) -> void:
	if slots.is_empty():
		return
	var i := sel
	for k in slots.size():
		if i < 0:
			i = 0 if d > 0 else slots.size() - 1
		else:
			i = (i + d + slots.size()) % slots.size()
		if not bool(slots[i].empty):
			break
	sel = i
	Sfx.play(&"tn_select", -12.0)
	queue_redraw()


## 한 번 누르고 떼기 (시험 시나리오가 eval로 부름: hud._tap(hud.slots[i].pos))
func _tap(p: Vector2) -> void:
	_press_down(p)
	_press_up()


## 손가락이 닿음: 바퀴 칸·버튼은 바로, 유닛(그림·카드·패널·차례 칸)은 떼는 때까지 기다린다 (0.4초 넘게 누르면 상세)
func _press_down(p: Vector2) -> void:
	_press = {}
	if confirm_open:
		if CONFIRM_YES.has_point(p):
			_confirm_yes()
		elif CONFIRM_NO.has_point(p) or not CONFIRM.has_point(p):
			_confirm_no()
		return
	if X_RECT.has_point(p):
		_ask_exit()
		return
	if state == "banner":
		if _banner_t > 0.5:
			if banner_text == "패배":
				if LOSE_RETRY.has_point(p):
					_banner_go("retry")
				elif LOSE_SETUP.has_point(p):
					_banner_go("setup")
			else:
				_banner_go("setup")
		return
	if state == "wheel" or state == "target":
		var i := _slot_at(p)
		if i >= 0:
			if state == "target":
				state = "wheel"
				targets.clear()
			if i == sel:
				_confirm_slot()
			else:
				sel = i
				Sfx.play(&"tn_select", -10.0)
				queue_redraw()
			return
	_press = {"pos": p, "t": 0.0, "unit": _unit_at(p)}


func _press_up() -> void:
	if _press.is_empty():
		return
	var u: TUnit = _press.get("unit")
	var held := _detail != null
	_press = {}
	if held:
		_detail = null
		return
	_tap_unit(u)


## 짧게 누름: 대상 고르기면 그 대상 / 바퀴 칸을 고른 채면 그 대상으로 바로 / 아니면 그 유닛을 잠깐 밝힘 · 빈 곳은 뒤로
func _tap_unit(u: TUnit) -> void:
	var a: TActor = actors.get(u) if u != null else null
	match state:
		"wheel":
			if a != null and sel >= 0:
				var s: Dictionary = slots[sel]
				if bool(s.can):
					_begin_target(s)
					if targets.has(a):
						_choose_target(a)
						return
				state = "wheel"
				targets.clear()
			elif u != null:
				_flash[u] = 0.4
		"target":
			if a != null and targets.has(a):
				_choose_target(a)
				return
			state = "wheel"
			targets.clear()
			Sfx.play(&"tn_cancel", -10.0)
		_:
			if u != null:
				_flash[u] = 0.4
	queue_redraw()


func _ask_exit() -> void:
	if state == "banner":
		exit_tapped.emit()
		return
	confirm_open = true
	Sfx.play(&"tn_select", -10.0)


func _confirm_yes() -> void:
	confirm_open = false
	Sfx.play(&"tn_confirm", -8.0)
	exit_tapped.emit()


func _confirm_no() -> void:
	confirm_open = false
	Sfx.play(&"tn_cancel", -10.0)


func _banner_go(choice: String) -> void:
	Sfx.play(&"tn_confirm", -6.0)
	banner_tapped.emit(choice)


func _slot_at(p: Vector2) -> int:
	var best := -1
	var bd := INF
	for i in slots.size():
		if bool(slots[i].empty):
			continue
		var d := p.distance_to(slots[i].pos)
		if d <= _slot_r(i) + 6.0 and d < bd:
			bd = d
			best = i
	return best


func _slot_r(i: int) -> float:
	return ULT_R if bool(slots[i].get("ult", false)) else SLOT_R


## 누른 자리의 유닛: 적 카드 → 아군 패널 → 차례 칸 → 그림(몸 사각형)
func _unit_at(p: Vector2) -> TUnit:
	if battle == null:
		return null
	for e in battle.enemies:
		if (e.alive or (state == "target" and targets.has(actors.get(e)))) and _card_rect(e).has_point(p):
			return e
	if not _strip_on():
		for w in battle.witches:
			if _panel_rect(w.slot).has_point(p):
				return w
	for i in _queue.size():
		if _queue_rect(i).grow(2).has_point(p):
			return _queue[i]
	var a := _actor_at(p)
	return a.unit if a != null else null


func _actor_at(p: Vector2) -> TActor:
	var best: TActor = null
	var bd := INF
	for u in actors:
		var a: TActor = actors[u]
		if not a.unit.alive and not (state == "target" and targets.has(a)):
			continue
		var feet := to_screen(a.feet())
		var head := to_screen(a.head())
		var hw := maxf(a.half_w(), 14.0) + 8.0
		var r := Rect2(Vector2(feet.x - hw, head.y - 6.0), Vector2(hw * 2.0, feet.y - head.y + 12.0))
		if r.has_point(p):
			var d := p.distance_to((feet + head) * 0.5)
			if d < bd:
				bd = d
				best = a
	return best


## 바퀴 칸 6개 (기본 공격 · 장착 1~4 · 대마법) — 빈 칸도 자리를 지킨다 (손이 칸 자리를 외우게)
func _build_slots() -> void:
	slots.clear()
	var u := actor.unit
	var c := _wheel_center()
	var ids: Array = ["basic"]
	for k in TData.EQUIP_MAX:
		ids.append(u.equipped[k] if k < u.equipped.size() else "")
	ids.append(String(u.data.get("ultimate", "")))
	var n := ids.size()
	for i in n:
		var ang := lerpf(-PI, 0.0, float(i) / float(n - 1))
		var pos := c + Vector2(cos(ang), sin(ang)) * WHEEL_R
		var sid: String = ids[i]
		if sid == "basic":
			slots.append({"id": "basic", "name": String(u.data.basic.get("name", "기본 공격")), "cost": 0, "can": true, "pos": pos, "kind": "attack", "target": "enemy", "icon": "strike", "empty": false, "ult": false})
		elif sid == "":
			slots.append({"id": "", "name": "", "cost": 0, "can": false, "pos": pos, "kind": "", "target": "", "icon": "", "empty": true, "ult": i == n - 1})
		else:
			var s := TData.skill(sid)
			slots.append({"id": sid, "name": String(s.name), "cost": int(s.cost), "can": battle.can_use(u, sid), "pos": pos, "kind": String(s.kind), "target": String(s.target),
				"icon": String(s.get("icon", "strike")), "empty": false, "ult": bool(s.get("ultimate", false))})


func _wheel_center() -> Vector2:
	return to_screen(actor.center())


## 바퀴가 열린 동안 다른 마녀는 흐리게 (고르는 마녀가 또렷이)
func _dim_others(on: bool) -> void:
	for u in actors:
		var a: TActor = actors[u]
		if u.is_witch() and a != actor:
			a.modulate = Color(0.55, 0.5, 0.65) if on else Color.WHITE


func _confirm_slot() -> void:
	if sel < 0 or sel >= slots.size():
		return
	var s: Dictionary = slots[sel]
	if not bool(s.can):
		Sfx.play(&"tn_cancel", -8.0)
		show_msg("크레딧이 모자랍니다 (%d 필요)" % int(s.cost), T.DANGER)
		return
	_begin_target(s)
	if state == "target":
		Sfx.play(&"tn_select", -8.0)
		queue_redraw()
	else:
		_emit(s, null)


## 대상이 필요한 마법이면 대상 고르기 상태로, 아니면 그대로
func _begin_target(s: Dictionary) -> void:
	targets.clear()
	var u := actor.unit
	if String(s.id) == "basic" or battle.needs_target_pick(String(s.id)):
		var us: Array[TUnit] = battle.alive_of(battle.enemies) if String(s.id) == "basic" else battle.valid_targets(u, String(s.id))
		for t in us:
			if actors.has(t):
				targets.append(actors[t])
		state = "target"
		tsel = 0
		# 기본값: 적이면 첫 적, 아군이면 자신이 아닌 첫 아군 (자기 버프는 보통 딜러에게)
		if String(s.target) in ["ally", "ally_any"]:
			for i in targets.size():
				if targets[i] != actor:
					tsel = i
					break
	else:
		state = "idle"


func _choose_target(a: TActor) -> void:
	var s: Dictionary = slots[sel]
	_emit(s, a.unit)


func _emit(s: Dictionary, tgt: TUnit) -> void:
	Sfx.play(&"tn_confirm", -6.0)
	var action := {"kind": "basic" if String(s.id) == "basic" else "skill", "skill": String(s.id), "target": tgt}
	close_wheel()
	chosen.emit(action)


# ═══════════════════════════════════════════════════════════
# 자리 계산
# ═══════════════════════════════════════════════════════════

func _strip_on() -> bool:
	return state == "wheel" or state == "target"


func _panel_rect(slot: int) -> Rect2:
	var r := Rect2(PANEL_X0 + PANEL_STEP * float(slot), PANEL_Y, PANEL_W, PANEL_H)
	if battle != null and battle.actor != null and battle.actor.is_witch() and battle.actor.slot == slot:
		r.position.y -= 4.0 # 지금 차례 패널은 4px 올림
	return r


func _boss_card_on() -> bool:
	return battle != null and battle.enemies.size() == 1 and battle.enemies[0].boss


func _card_rect(u: TUnit) -> Rect2:
	if battle == null:
		return Rect2()
	if _boss_card_on():
		return BOSS_CARD
	var i := pos_index(battle.enemies.size(), battle.enemies.find(u))
	return Rect2(CARD_X0 + CARD_STEP * float(i), CARD_Y, CARD_W, CARD_H)


func _queue_rect(i: int) -> Rect2:
	if i == 0:
		return Rect2(6, 3, 24, 24)
	return Rect2(36 + 21 * (i - 1), 6, 18, 18)


func _dup_suffix(u: TUnit) -> String:
	var same: Array = []
	for e in battle.enemies:
		if e.id == u.id:
			same.append(e)
	if same.size() < 2:
		return ""
	return " " + ["A", "B", "C"][same.find(u)]


# ═══════════════════════════════════════════════════════════
# 아군 패널 초상 (편성 화면처럼 TActor를 작게 — 판 안으로 잘라 보임)
# ═══════════════════════════════════════════════════════════

func _build_portraits() -> void:
	for k in _portraits:
		(_portraits[k] as Node).queue_free()
	_portraits.clear()
	if battle == null:
		return
	for w in battle.witches:
		var p := PortraitBox.new()
		p.clip_contents = true
		p.show_behind_parent = true
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.col = TData.ELEMENT_COLOR.get(w.element, T.LINE)
		p.size = Vector2(40, 48)
		add_child(p)
		var a := TActor.new()
		p.add_child(a)
		a.setup(w, Vector2(20, 54))
		a.scale = Vector2(1.4, 1.4)
		a.z_index = 0
		_portraits[w] = p


func _layout_portraits() -> void:
	var strip := _strip_on()
	_back.visible = not strip
	for w in _portraits:
		var p: PortraitBox = _portraits[w]
		p.visible = not strip
		var r := _panel_rect(w.slot)
		p.position = r.position + Vector2(4, 4)
		p.modulate = Color(1, 1, 1, 0.45) if not w.alive else Color.WHITE


## 판 바탕 (초상보다 아래) — PanelBack이 부른다
func _draw_panel_backs(ci: CanvasItem) -> void:
	if battle == null:
		return
	for w in battle.witches:
		var r := _panel_rect(w.slot)
		var cur := battle.actor == w
		T.panel(ci, r, Color(T.PANEL_HI if cur else T.PANEL, 0.92 if w.alive else 0.6), Color(T.GOLD, 1.0) if cur else Color(T.LINE, 0.55), 2 if cur else 1, 3)


class PanelBack extends Control:
	var hud: THud

	func _draw() -> void:
		hud._draw_panel_backs(self)


class PortraitBox extends Control:
	var col := Color.WHITE

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(col, 0.18))
		draw_rect(Rect2(0, size.y - 14, size.x, 14), Color(col, 0.10))


# ═══════════════════════════════════════════════════════════
# 그림
# ═══════════════════════════════════════════════════════════

func _draw() -> void:
	if battle == null:
		return
	_draw_heads()
	_draw_top()
	_draw_cards()
	if _strip_on():
		_draw_wheel()
		_draw_strip()
	else:
		_draw_panels()
	if state == "target":
		_draw_targets()
	_draw_numbers()
	_draw_action_strip()
	if _detail != null:
		_draw_detail(_detail)
	if _wave_t > 0.0:
		_draw_banner_box(_wave_txt, "", T.TEXT, 1.0 - _wave_t)
	if state == "banner":
		_draw_banner()
	if confirm_open:
		_draw_confirm()


## 위 띠: 바탕 · 차례 줄 · 전투 이름/웨이브 · 연쇄 · X
func _draw_top() -> void:
	draw_rect(Rect2(0, 0, size.x, 30), Color(T.INK, 0.55))
	draw_rect(Rect2(0, 30, size.x, 1), Color(T.LINE, 0.3))
	_draw_queue()
	var wl := battle_name
	if battle.wave_count() > 1:
		wl = "웨이브 %d/%d" % [battle.wave_i + 1, battle.wave_count()]
	var wcol := T.GOLD if _wave_flash > 0.0 and _wave_flash < 0.4 else T.TEXT
	T.text(self, Vector2(596, 20), wl, 10, wcol, HORIZONTAL_ALIGNMENT_RIGHT)
	# 대마법 연쇄 진행 중 (§13.6)
	if battle.chain_owner != null and battle.chain_stage > 0:
		var cx := 596.0 - T.width(wl, 10) - 8.0
		var lab := "대마법 연쇄 %d단계 · 다음 %d단계" % [battle.chain_stage, mini(battle.chain_stage + 1, 3)] if battle.chain_stage < 3 else "대마법 연쇄 3단계 (최대)"
		var w := T.width(lab, 10) + 10.0
		T.panel(self, Rect2(cx - w, 8, w, 15), Color(T.INK, 0.9), Color(T.GOLD, 0.8), 1, 3)
		T.text(self, Vector2(cx - w * 0.5, 20), lab, 10, T.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	# 나가기 X
	draw_circle(X_C, 12.0, Color(T.INK, 0.6))
	draw_arc(X_C, 12.0, 0.0, TAU, 24, Color(T.LINE, 0.6), 1.0)
	draw_line(X_C + Vector2(-4, -4), X_C + Vector2(4, 4), Color(T.TEXT, 0.85), 1.6)
	draw_line(X_C + Vector2(-4, 4), X_C + Vector2(4, -4), Color(T.TEXT, 0.85), 1.6)


## 차례 줄: 지금(크게·금테) → 다음 7. 아군 = 속성 색 칸 · 적 = 먹 칸 + 빨간 테(보스 금테) + 카드 번호 배지 · 기절 = 별 + 어둡게
func _draw_queue() -> void:
	for i in _queue.size():
		var u: TUnit = _queue[i]
		var r := _queue_rect(i)
		var witch := u.is_witch()
		var fill: Color = Color(TData.ELEMENT_COLOR.get(u.element, T.LINE), 0.9) if witch else Color(T.PANEL, 0.95)
		var border := T.GOLD if i == 0 else (Color(T.INK, 0.9) if witch else (T.GOLD if u.boss else T.DANGER))
		if u.stunned:
			fill = fill.darkened(0.5)
		T.panel(self, r, fill, border, 2 if i == 0 else 1, 4 if i == 0 else 3)
		var glyph: String = SHORT.get(u.id, u.name.substr(0, 1))
		var fs := 12 if i == 0 else 10
		T.text(self, r.get_center() + Vector2(0, 5 if i == 0 else 4), glyph, fs, T.INK if witch else T.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 0 if witch else -1)
		if not witch and battle.enemies.size() > 1:
			var b := r.end - Vector2(2, 2)
			draw_rect(Rect2(b - Vector2(4, 4), Vector2(8, 8)), Color(T.INK, 0.95))
			T.text(self, b + Vector2(0, 4), str(pos_index(battle.enemies.size(), battle.enemies.find(u)) + 1), 8, T.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 0)
		if u.stunned:
			T.star(self, Vector2(r.get_center().x, r.position.y + 1), 3.5, T.STUN)


## 행동 띠 (왼쪽 위 (6, 32, 300, 18)): 지금 행동 이름·안내
func _draw_action_strip() -> void:
	if msg_t <= 0.0 or msg == "":
		return
	var a := minf(msg_t / 0.4, 1.0)
	var w := minf(T.width(msg, 12) + 22.0, 300.0)
	var r := Rect2(ACT_STRIP.position, Vector2(w, ACT_STRIP.size.y))
	draw_rect(r, Color(T.INK, 0.72 * a))
	draw_rect(Rect2(r.position, Vector2(2, r.size.y)), Color(msg_col, a))
	T.text(self, r.position + Vector2(10, 14), T.clip(msg, 12, 280), 12, Color(T.TEXT, a))


## 머리 위 최소 표시 (§21.6): 마녀 = 체력 40×3 + 게이지 40×2 · 적 = 의도 아이콘 + 게이지 · 공통 = 기절 별 · 눌러 알린 유닛 고리
func _draw_heads() -> void:
	for u in actors:
		var a: TActor = actors[u]
		var unit: TUnit = u
		if _flash.has(unit):
			var feet := to_screen(a.feet())
			draw_set_transform(feet, 0.0, Vector2(1.0, 0.35))
			draw_arc(Vector2.ZERO, a.half_w() + 10.0, 0.0, TAU, 28, Color(T.GOLD, float(_flash[unit]) / 0.4), 2.0)
			draw_set_transform(Vector2.ZERO)
		if not unit.alive:
			continue
		if _strip_on() and unit.is_witch() and a != actor:
			continue
		var top := to_screen(a.head()).round()
		var cur := battle.actor == unit
		var w := 40.0
		var x := top.x - 20.0
		if unit.is_witch():
			var y := top.y - 9.0
			draw_rect(Rect2(x - 1, y - 1, w + 2, 9), Color(T.INK, 0.85))
			var col := T.HP_ALLY.lerp(T.HP_LOW, clampf(1.0 - unit.hp_ratio() * 2.0, 0.0, 1.0))
			draw_rect(Rect2(x, y, w * a.shown_hp, 3), Color(col, 0.45))
			draw_rect(Rect2(x, y, w * unit.hp_ratio(), 3), col)
			draw_rect(Rect2(x, y + 4, w * clampf(unit.gauge / TData.GAUGE_MAX, 0.0, 1.0), 2), Color(T.GAUGE, 0.95 if cur else 0.7))
			if cur:
				draw_rect(Rect2(x - 2, y - 2, w + 4, 11), Color(T.GOLD, 0.9), false, 1.0)
			if unit.is_taunting():
				T.buff_icon(self, Vector2(x + w + 3, y - 2), {"cat": "taunt"})
		else:
			var y := top.y - 6.0
			draw_rect(Rect2(x - 1, y - 1, w + 2, 4), Color(T.INK, 0.85))
			draw_rect(Rect2(x, y, w * clampf(unit.gauge / TData.GAUGE_MAX, 0.0, 1.0), 2), Color(T.GAUGE, 0.95 if cur else 0.7))
			if cur:
				draw_rect(Rect2(x - 2, y - 2, w + 4, 6), Color(T.TEXT, 0.9), false, 1.0)
			if not unit.stunned:
				var it := unit.intent()
				var k := String(it.get("k", "attack"))
				var icol: Color = T.INTENT_COL.get(k, T.TEXT)
				var ic := Vector2(top.x, top.y - 15)
				draw_rect(Rect2(ic - Vector2(6, 6), Vector2(12, 12)), Color(T.INK, 0.85))
				draw_rect(Rect2(ic - Vector2(5.5, 5.5), Vector2(11, 11)), Color(icol, 0.8), false, 1.0)
				T.intent_icon(self, ic, k, icol)
		if unit.stunned:
			for k in 3:
				var ang := _t * TAU / 0.8 + float(k) * TAU / 3.0
				T.star(self, Vector2(top.x, top.y - 28) + Vector2(cos(ang) * 8.0, sin(ang) * 3.0), 2.8, T.STUN)


## 적 카드 (일반 100×50 · 보스 308×50)
func _draw_cards() -> void:
	for e in battle.enemies:
		if not e.alive:
			continue
		if _boss_card_on():
			_draw_boss_card(e)
		else:
			_draw_card(e)


func _card_frame(e: TUnit, r: Rect2) -> void:
	var tgt_on := state == "target" and targets.has(actors.get(e))
	var picked: bool = tgt_on and targets[tsel] == actors.get(e)
	var fill := Color(T.PANEL_HI if picked else T.PANEL, 0.92)
	var border := Color(T.LINE, 0.55)
	var bw := 1
	if picked:
		border = T.GOLD
		bw = 2
	elif battle.actor == e:
		border = T.TEXT
		bw = 2
	elif tgt_on:
		border = Color(T.TEXT, 0.8)
	T.panel(self, r, fill, border, bw, 3)


## 의도 알약 (종류만 [확정 §0-9]). 기절이면 "기절". 필살기·강공격은 숨쉬기. 무적 관통이면 뒤에 관통 표시
func _intent_pill(e: TUnit, p: Vector2) -> float:
	var it := e.intent()
	var k := String(it.get("k", "attack"))
	var name: String = TData.INTENT_NAME.get(k, "")
	var col: Color = T.INTENT_COL.get(k, T.TEXT)
	if e.stunned:
		k = "stun"
		name = "기절"
		col = T.STUN
	var pierce := bool(it.get("pierce", false)) and not e.stunned
	var w := T.width(name, 10) + 18.0 + (12.0 if pierce else 0.0)
	var pulse := 1.0
	if k in ["heavy", "finisher"]:
		pulse = 0.6 + 0.4 * (0.5 + 0.5 * sin(_t * 5.0))
	var r := Rect2(p, Vector2(w, 13))
	T.panel(self, r, Color(T.INK, 0.95), Color(col, pulse), 1, 2)
	T.intent_icon(self, p + Vector2(8, 6.5), k, Color(col, pulse))
	T.text(self, p + Vector2(15, 11), name, 10, col)
	if pierce:
		var c := p + Vector2(w - 7, 6.5)
		draw_line(c + Vector2(-4, 0), c + Vector2(4, 0), T.DANGER, 1.4)
		draw_line(c + Vector2(1, -3), c + Vector2(4, 0), T.DANGER, 1.4)
		draw_line(c + Vector2(1, 3), c + Vector2(4, 0), T.DANGER, 1.4)
		draw_line(c + Vector2(-1, -4), c + Vector2(-1, 4), Color(T.TEXT, 0.7), 1.0)
	return w


## 차지 칸 (오른쪽 끝 right부터 왼쪽으로): 빈 칸 EMPTY · 찬 칸 GOLD · 가득이면 모두 DANGER + 깜빡임
func _charge_cells(e: TUnit, right: float, y: float, cw: float, ch: float, gap: float) -> void:
	if e.charge_max <= 0:
		return
	var full := e.charge >= e.charge_max
	var blink := 0.55 + 0.45 * (0.5 + 0.5 * sin(_t * 8.0))
	for k in e.charge_max:
		var x := right - float(e.charge_max - k) * gap
		var on := k < e.charge
		var col := (Color(T.DANGER, blink) if full else T.GOLD) if on else T.EMPTY
		# 셰브론 (오른쪽을 향한 꺾쇠)
		var pts := PackedVector2Array([Vector2(x, y), Vector2(x + cw * 0.55, y), Vector2(x + cw, y + ch * 0.5), Vector2(x + cw * 0.55, y + ch), Vector2(x, y + ch), Vector2(x + cw * 0.45, y + ch * 0.5)])
		draw_colored_polygon(pts, col)


## 징표·디버프 아이콘 (오른쪽 끝 right부터, 최대 maxn개 + "+n")
func _foe_icons(e: TUnit, right: float, y: float, maxn: int) -> void:
	var list: Array = []
	for mk in e.marks:
		list.append({"mark": String(mk)})
	for ic in e.buff_icons():
		list.append(ic)
	var shown := mini(list.size(), maxn)
	var x := right - 11.0 * float(shown)
	if list.size() > maxn:
		var more := "+%d" % (list.size() - maxn)
		x -= T.width(more, 10) + 2.0
		T.text(self, Vector2(right, y + 9), more, 10, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_RIGHT)
	for i in shown:
		var d: Dictionary = list[i]
		var p := Vector2(x + 11.0 * float(i), y)
		if d.has("mark") and not d.has("cat"):
			draw_rect(Rect2(p, Vector2(10, 10)), Color(T.INK, 0.92))
			draw_rect(Rect2(p + Vector2(0.5, 0.5), Vector2(9, 9)), Color("#ff9a5a", 0.8), false, 1.0)
			T.mark_icon(self, p + Vector2(5, 5), String(d.mark), _t)
			T.text(self, p + Vector2(11, 11), str(e.mark_n(String(d.mark))), 8, T.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, 2)
		else:
			T.buff_icon(self, p, d, int(d.dur))


func _hp_bar(e: TUnit, r: Rect2) -> void:
	draw_rect(r.grow(1), Color(T.INK, 0.95))
	var a: TActor = actors.get(e)
	var shown := a.shown_hp if a != null else e.hp_ratio()
	draw_rect(Rect2(r.position, Vector2(r.size.x * shown, r.size.y)), Color(T.HP_FOE_TRAIL, 0.5))
	draw_rect(Rect2(r.position, Vector2(r.size.x * e.hp_ratio(), r.size.y)), T.HP_FOE)


func _draw_card(e: TUnit) -> void:
	var r := _card_rect(e)
	var X := r.position.x
	var Y := r.position.y
	_card_frame(e, r)
	_intent_pill(e, Vector2(X + 3, Y + 3))
	_charge_cells(e, X + 96.0, Y + 5.0, 6.0, 8.0, 7.0)
	# 이름 · 약점 · 줄 수
	T.text(self, Vector2(X + 4, Y + 28), T.clip(e.name + _dup_suffix(e), 10, 70), 10, T.TEXT)
	var wx := X + 86.0
	for el in e.weak:
		draw_rect(Rect2(wx, Y + 18, 11, 11), Color(T.INK, 0.9))
		draw_rect(Rect2(wx + 0.5, Y + 18.5, 10, 10), Color(T.WEAK, 0.9), false, 1.0)
		T.element_icon(self, Vector2(wx + 5.5, Y + 23.5), String(el), 4.2)
		wx -= 13.0
	if e.bars.size() > 1:
		T.text(self, Vector2(wx + 10, Y + 28), "×%d" % e.bars_left(), 8, T.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	_hp_bar(e, Rect2(X + 4, Y + 31, 92, 5))
	T.text(self, Vector2(X + 4, Y + 47), TData.fmt_short(e.hp), 10, T.TEXT)
	_foe_icons(e, X + 96.0, Y + 38.0, 3 if TData.fmt_short(e.hp).length() <= 7 else 2)


func _draw_boss_card(e: TUnit) -> void:
	var r := _card_rect(e)
	var X := r.position.x
	var Y := r.position.y
	_card_frame(e, r)
	_intent_pill(e, Vector2(X + 3, Y + 3))
	_charge_cells(e, X + 304.0, Y + 4.0, 8.0, 10.0, 11.0)
	if e.charge_max > 0:
		T.text(self, Vector2(X + 304.0 - 11.0 * e.charge_max - 4.0, Y + 13), "차지", 10, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_RIGHT)
	# 이름 (금빛) · 약점
	T.text(self, Vector2(X + 4, Y + 29), e.name, 12, T.GOLD)
	var nx := X + 10.0 + T.width(e.name, 12)
	if e.weak.is_empty():
		T.text(self, Vector2(nx, Y + 28), "약점 없음", 10, T.TEXT_OFF)
	else:
		T.text(self, Vector2(nx, Y + 28), "약점", 10, T.TEXT_SUB)
		var wx := nx + T.width("약점", 10) + 3.0
		for el in e.weak:
			draw_rect(Rect2(wx, Y + 18, 11, 11), Color(T.INK, 0.9))
			draw_rect(Rect2(wx + 0.5, Y + 18.5, 10, 10), Color(T.WEAK, 0.9), false, 1.0)
			T.element_icon(self, Vector2(wx + 5.5, Y + 23.5), String(el), 4.2)
			wx += 13.0
	# 남은 줄: 칸 (깬 줄 = 빈 칸, 남은 줄 = 금빛) + "줄 2/3"
	if e.bars.size() > 1:
		var n := e.bars.size()
		for k in n:
			var cx := X + 304.0 - float(n - k) * 11.0
			draw_rect(Rect2(cx, Y + 21, 9, 5), T.GOLD if k >= e.bar_i else T.EMPTY)
		T.text(self, Vector2(X + 304.0 - float(n) * 11.0 - 4.0, Y + 28), "줄 %d/%d" % [e.bar_i + 1, n], 10, T.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	_hp_bar(e, Rect2(X + 4, Y + 32, 300, 6))
	T.text(self, Vector2(X + 4, Y + 48), "%s / %s" % [TData.fmt_short(e.hp), TData.fmt_short(e.max_hp)], 10, T.TEXT)
	_foe_icons(e, X + 304.0, Y + 39.0, 8)


## 아군 패널 3장 (바퀴가 닫혀 있을 때): 이름·자리 · 체력 · 크레딧 7칸 · 버프 · 게이지 · 기절 · 쓰러짐
func _draw_panels() -> void:
	for w in battle.witches:
		var r := _panel_rect(w.slot)
		var X := r.position.x
		var Y := r.position.y
		var cur := battle.actor == w
		var ecol: Color = TData.ELEMENT_COLOR.get(w.element, T.LINE)
		# 게이지 (판 위 테두리 안)
		draw_rect(Rect2(X + 2, Y + 2, (PANEL_W - 4.0) * clampf(w.gauge / TData.GAUGE_MAX, 0.0, 1.0), 2), Color(T.GAUGE, 0.9 if cur else 0.6))
		draw_rect(Rect2(X + 4, Y + 4, 40, 48), Color(ecol, 0.6), false, 1.0)
		var dim := 1.0 if w.alive else 0.5
		T.text(self, Vector2(X + 50, Y + 16), w.name, 12, Color(T.GOLD if cur else T.TEXT, dim))
		T.text(self, Vector2(X + 204, Y + 15), T.SLOT_NAME[w.slot], 10, Color(T.TEXT_SUB, dim), HORIZONTAL_ALIGNMENT_RIGHT)
		if not w.alive:
			T.text(self, Vector2(X + 128, Y + 38), "쓰러짐", 12, T.TEXT_OFF, HORIZONTAL_ALIGNMENT_CENTER)
			continue
		# 체력
		var hr := Rect2(X + 50, Y + 21, 100, 5)
		draw_rect(hr.grow(1), Color(T.INK, 0.95))
		var hcol := T.HP_ALLY.lerp(T.HP_LOW, clampf(1.0 - w.hp_ratio() * 2.0, 0.0, 1.0))
		var a: TActor = actors.get(w)
		draw_rect(Rect2(hr.position, Vector2(hr.size.x * (a.shown_hp if a != null else w.hp_ratio()), hr.size.y)), Color(hcol, 0.45))
		draw_rect(Rect2(hr.position, Vector2(hr.size.x * w.hp_ratio(), hr.size.y)), hcol)
		T.text(self, Vector2(X + 204, Y + 28), TData.fmt_short(w.hp), 10, T.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
		# 크레딧 7칸
		var full := w.credits >= TData.CREDIT_MAX
		var pulse := 0.85 + 0.15 * sin(_t * 5.0) if full else 1.0
		T.credit_row(self, Vector2(X + 54, Y + 36), w.credits, 10.0, 3.5, pulse)
		if full:
			T.text(self, Vector2(X + 124, Y + 40), "대마법", 10, Color(T.GOLD, pulse))
		else:
			T.text(self, Vector2(X + 124, Y + 40), "%d/%d" % [w.credits, TData.CREDIT_MAX], 10, T.TEXT_SUB)
		# 버프 아이콘 (최대 6 + "+n") — 장비 도발·장비 근성도 아이콘으로
		var icons: Array = w.buff_icons()
		if bool(w.equip_data().get("taunt", false)) and not w.has_buff("taunt"):
			icons.append({"cat": "taunt", "dur": -1})
		if float(w.equip_data().get("guts_once", 0.0)) > 0.0 and not w.guts_used:
			icons.append({"cat": "guts", "dur": -1})
		for k in mini(icons.size(), 6):
			T.buff_icon(self, Vector2(X + 50 + 13 * k, Y + 43), icons[k], int(icons[k].get("dur", -1)))
		if icons.size() > 6:
			T.text(self, Vector2(X + 50 + 13 * 6, Y + 52), "+%d" % (icons.size() - 6), 10, T.TEXT_SUB)
		if w.stunned:
			for k in 3:
				T.star(self, Vector2(X + 14 + 10 * k, Y + 10), 3.5, T.STUN)
		if cur:
			# 지금 차례: 판 위 작은 금빛 삼각
			draw_colored_polygon(PackedVector2Array([Vector2(X + 104 - 5, Y - 6), Vector2(X + 104 + 5, Y - 6), Vector2(X + 104, Y - 1)]), T.GOLD)


## 스킬 바퀴: 위쪽 반원, 칸 6개 고정. 칸 = 먹 원 + 종류 테 + 아이콘(속성 색) + 비용 배지. 대마법 칸은 금빛 + 남은 수 / 숨쉬기 + 연쇄 단계
func _draw_wheel() -> void:
	if actor == null:
		return
	var c := _wheel_center()
	draw_arc(c, WHEEL_R, -PI - 0.15, 0.15, 40, Color(T.LINE, 0.25), 1.0)
	var u := actor.unit
	var ecol: Color = TData.ELEMENT_COLOR.get(String(u.data.get("element", "")), T.LINE)
	for i in slots.size():
		var s: Dictionary = slots[i]
		var p: Vector2 = s.pos
		var on := i == sel
		var ult := bool(s.get("ult", false))
		var r := _slot_r(i) + (3.0 if on else 0.0)
		if bool(s.empty):
			draw_arc(p, r - 2.0, 0.0, TAU, 24, Color(T.TEXT_OFF, 0.35), 1.0)
			continue
		var can := bool(s.can)
		draw_circle(p, r + 1.5, Color(T.INK, 0.95))
		draw_circle(p, r, Color(T.PANEL_HI if on else T.INK, 0.95))
		if ult:
			var full := u.credits >= TData.ULT_COST
			var br := 0.6 + 0.4 * (0.5 + 0.5 * sin(_t * 4.0)) if full else 0.8
			draw_arc(p, r, 0.0, TAU, 32, Color(T.GOLD, br), 2.0)
			draw_arc(p, r + 3.0, 0.0, TAU, 32, Color(T.GOLD, 0.5), 1.0)
			if full:
				var ph := fmod(_t, 0.8) / 0.8
				draw_arc(p, r + 3.0 + ph * 10.0, 0.0, TAU, 32, Color(T.GOLD, 0.5 * (1.0 - ph)), 1.0)
			TIcon.draw(self, p, String(s.icon), Color(T.GOLD if full else ecol, 1.0 if full else 0.35), r * 0.5)
			if not full:
				T.text(self, p + Vector2(0, 5), "−%d" % (TData.ULT_COST - u.credits), 12, T.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
			var nxt := mini(battle.chain_stage + 1, 3) if (battle.chain_owner != null and battle.chain_stage > 0) else 1
			if nxt >= 2:
				var lab := "연쇄 %d" % nxt
				var lw := T.width(lab, 10) + 8.0
				var lr := Rect2(p.x - lw * 0.5, p.y + r + 4.0, lw, 13)
				T.panel(self, lr, Color(T.INK, 0.95), T.GOLD, 1, 2)
				T.text(self, Vector2(p.x, lr.position.y + 11), lab, 10, T.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		else:
			var ring := T.kind_col(String(s.kind)) if can else T.TEXT_OFF
			draw_arc(p, r, 0.0, TAU, 28, Color(ring, 1.0 if can else 0.6), 2.0 if on else 1.5)
			TIcon.draw(self, p, String(s.icon), Color(ecol, 1.0 if can else 0.4), r * 0.5)
			if String(s.id) == "basic":
				T.cost_badge(self, p + Vector2(14, 14), "+1", "gain")
			else:
				T.cost_badge(self, p + Vector2(14, 14), str(int(s.cost)), "ok" if can else "short")
		if on:
			draw_arc(p, r, 0.0, TAU, 32, T.TEXT, 2.0)
			var nm := String(s.name)
			var nw := T.width(nm, 10) + 8.0
			var nr := Rect2(clampf(p.x - nw * 0.5, 4.0, size.x - 4.0 - nw), p.y - r - 17.0, nw, 14)
			T.panel(self, nr, Color(T.INK, 0.95), Color(T.TEXT, 0.6), 1, 2)
			T.text(self, Vector2(nr.get_center().x, nr.position.y + 11), nm, 10, T.TEXT, HORIZONTAL_ALIGNMENT_CENTER)


## 설명 띠 (아래 띠 자리 (4, 302, 632, 56)): 1줄 이름·비용·종류 / 예상 피해(크리 값) · 2줄 효과 · 3줄 크레딧·대상 / 안내
func _draw_strip() -> void:
	if actor == null:
		return
	var u := actor.unit
	var ecol: Color = TData.ELEMENT_COLOR.get(u.element, T.LINE)
	T.panel(self, STRIP, Color(T.PANEL, 0.94), Color(ecol, 0.8), 1, 3)
	var X := STRIP.position.x + 8.0
	var hint := ""
	if sel < 0 or sel >= slots.size():
		T.text(self, Vector2(X, 318), "%s의 차례 — 마법을 고르세요" % u.name, 12, T.TEXT)
		T.text(self, Vector2(X, 333), "칸을 한 번 누르면 설명, 다시 누르면 사용 · 대상이 필요하면 적·아군을 누릅니다", 10, T.TEXT_SUB)
	else:
		var s: Dictionary = slots[sel]
		var can := bool(s.can)
		var sid := String(s.id)
		TIcon.draw(self, Vector2(X + 6, 313), String(s.icon), ecol if can else T.TEXT_OFF, 6.0)
		T.text(self, Vector2(X + 16, 318), String(s.name), 12, T.TEXT if can else T.TEXT_OFF)
		var cx := X + 22.0 + T.width(String(s.name), 12)
		if sid == "basic":
			T.text(self, Vector2(cx, 318), "크레딧 +1 · 공격 · 적 1", 10, T.GOLD)
		else:
			T.cost_badge(self, Vector2(cx + 6, 314), str(int(s.cost)), "ok" if can else "short")
			T.text(self, Vector2(cx + 16, 318), T.kind_label(TData.skill(sid)), 10, T.TEXT_SUB)
		# 예상 피해 (대상을 고르면 그 대상, 아니면 첫 적) [확정 21-2 B] — 크리 값 함께
		var est_tgt: TUnit = null
		if state == "target" and not targets.is_empty() and not (targets[tsel] as TActor).unit.is_witch():
			est_tgt = (targets[tsel] as TActor).unit
		elif not battle.alive_of(battle.enemies).is_empty():
			est_tgt = battle.alive_of(battle.enemies)[0]
		if String(s.kind) == "attack" and est_tgt != null:
			var skid := "" if sid == "basic" else sid
			var est := battle.estimate(u, est_tgt, skid)
			var est_c := battle.estimate(u, est_tgt, skid, true)
			var line := "예상 %s · 크리 %s" % [TData.fmt_short(est), TData.fmt_short(est_c)] if est_c != est else "예상 %s (크리 확정)" % TData.fmt_short(est)
			T.text(self, Vector2(STRIP.end.x - 8, 318), line, 10, T.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
		var desc := String(u.data.basic.desc) if sid == "basic" else String(TData.skill(sid).desc)
		T.text(self, Vector2(X, 334), T.clip(desc, 10, 616), 10, T.TEXT)
		if not can:
			hint = "크레딧이 모자랍니다"
		elif state == "target":
			hint = "대상을 누르세요 · 빈 곳 = 뒤로" if _touch_seen else "←→ 대상 · Z 확인 · X 뒤로"
		else:
			var need := sid == "basic" or battle.needs_target_pick(sid)
			hint = ("다시 누르면 대상 고르기" if need else "다시 누르면 사용") if _touch_seen else "Z 확인 · X 뒤로"
	# 3줄: 크레딧 ◆ n/7 (바퀴) · 대상 정보 (대상 고르기)
	if state == "target" and not targets.is_empty():
		var t: TUnit = (targets[tsel] as TActor).unit
		var info := "대상 %s · 체력 %s" % [t.name + (_dup_suffix(t) if not t.is_witch() else ""), TData.fmt_short(t.hp)]
		if not t.is_witch() and not t.weak.is_empty():
			var wn: Array = []
			for el in t.weak:
				wn.append(TData.ELEMENT_NAME.get(String(el), ""))
			info += " · 약점 " + ", ".join(wn)
		T.text(self, Vector2(X, 351), info, 10, T.TEXT)
	else:
		T.text(self, Vector2(X, 351), "크레딧", 10, T.TEXT_SUB)
		T.credit_row(self, Vector2(X + 38, 347), u.credits, 9.0, 3.0)
		T.text(self, Vector2(X + 38 + 9 * 7, 351), "%d/%d" % [u.credits, TData.CREDIT_MAX], 10, T.GOLD if u.credits >= TData.CREDIT_MAX else T.TEXT)
	if hint != "":
		T.text(self, Vector2(STRIP.end.x - 8, 351), hint, 10, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_RIGHT)


## 대상 표시: 고를 수 있는 대상 위 화살, 지금 고른 대상은 금빛 + 발밑 고리 (카드 테는 _card_frame)
func _draw_targets() -> void:
	for i in targets.size():
		var a: TActor = targets[i]
		var on := i == tsel
		var top := to_screen(a.head()) + Vector2(0, -22 + sin(_t * 6.0) * 2.0)
		top.y = maxf(top.y, CARD_Y + CARD_H + 14.0) # 키 큰 적은 카드 밑에서 (카드 테가 금빛으로 같이 알림)
		var col := Color(T.GOLD if on else T.TEXT, 1.0 if on else 0.6)
		draw_colored_polygon(PackedVector2Array([top + Vector2(-7, -10), top + Vector2(7, -10), top]), Color(T.INK, 0.9))
		draw_colored_polygon(PackedVector2Array([top + Vector2(-5, -9), top + Vector2(5, -9), top + Vector2(0, -2)]), col)
		var feet := to_screen(a.feet())
		draw_set_transform(feet, 0.0, Vector2(1.0, 0.35))
		draw_arc(Vector2.ZERO, a.half_w() + 8.0, 0.0, TAU, 28, Color(col, 0.9 if on else 0.4), 2.0 if on else 1.0)
		draw_set_transform(Vector2.ZERO)


func _draw_numbers() -> void:
	for n: Dictionary in numbers:
		var age := float(n.age)
		if age < 0.0:
			continue
		var kind := String(n.kind)
		var st: Array = NUM_STYLE.get(kind, NUM_STYLE.dmg)
		var fs := int(st[0])
		var col: Color = st[1]
		var rise := 18.0 * (1.0 - pow(1.0 - minf(age / 0.5, 1.0), 2.0)) * float(n.dir)
		var a := 1.0 - clampf((age - 0.6) / 0.5, 0.0, 1.0)
		var pop := 1.0 - clampf(age / 0.12, 0.0, 1.0)
		var q: Vector2 = (n.p as Vector2) + Vector2(0, rise)
		var s := 1.0 + 0.25 * pop
		draw_set_transform(q, 0.0, Vector2(s, s))
		var c := Color(col.lerp(Color.WHITE, pop * 0.6), a)
		if kind == "big" and age < 0.2:
			c = Color(Color.WHITE, a)
		T.text(self, Vector2.ZERO, String(n.text), fs, c, HORIZONTAL_ALIGNMENT_CENTER)
		if bool(n.weak):
			T.text(self, Vector2(0, -float(fs) - 1.0), "약점", 10, Color(T.WEAK, a), HORIZONTAL_ALIGNMENT_CENTER)
		draw_set_transform(Vector2.ZERO)


## 유닛 상세 (B-04, §21.11): 적이면 왼쪽, 마녀면 오른쪽 (232 폭, 높이는 내용만큼 최대 180). 의도는 종류만
func _draw_detail(u: TUnit) -> void:
	var ecol: Color = TData.ELEMENT_COLOR.get(u.element, T.TEXT)
	var title := u.name
	var title_col := T.TEXT
	var sub := ""
	var sub_col := T.TEXT_SUB
	var lines: Array = [] ## [글, 색, 최대 줄]
	if u.is_witch():
		sub = "%s · %s · %s" % [TData.ELEMENT_NAME.get(u.element, ""), TData.ROLE_NAME.get(String(u.data.get("role", "")), ""), T.SLOT_NAME[u.slot]]
		sub_col = ecol
		lines.append(["체력 %s / %s · 크레딧 %d/%d" % [TData.fmt_short(u.hp), TData.fmt_short(u.max_hp), u.credits, TData.CREDIT_MAX], T.TEXT, 1])
		lines.append(["공격력 %s · 속도 %d · 방어율 %d%%" % [TData.fmt(u.atk), u.speed, int(round(u.def_rate * 100.0))], T.TEXT, 1])
		var eq := u.equip_data()
		if u.equip != "":
			lines.append(["장비 %s%s — %s" % [String(eq.get("name", "")), " Lv%d" % u.equip_lv if u.equip_lv > 1 else "", String(eq.get("desc", ""))], T.GOLD, 2])
		var pas: Dictionary = u.data.get("passive", {})
		if not pas.is_empty():
			lines.append(["패시브 %s — %s" % [String(pas.get("name", "")), String(pas.get("desc", ""))], T.TEXT_SUB, 3])
		var st: Array = []
		if u.stunned:
			st.append("기절 (다음 차례 쉼)")
		if u.stun_guard:
			st.append("기절 내성")
		if u.is_taunting():
			st.append("도발 중")
		if float(eq.get("guts_once", 0.0)) > 0.0:
			st.append("장비 근성 %s" % ("씀" if u.guts_used else "남음"))
		if not st.is_empty():
			lines.append([" · ".join(st), T.STUN, 1])
		for b in u.buffs:
			lines.append([T.buff_line(b), Color("#d9ccff") if not (String(b.cat) in T.BAD_CATS) else T.DANGER, 1])
	else:
		title = u.name + _dup_suffix(u)
		title_col = T.GOLD if u.boss else T.TEXT
		sub = String(TData.TIER_NAME.get(u.tier, ""))
		var bl := " (줄 %d/%d)" % [u.bar_i + 1, u.bars.size()] if u.bars.size() > 1 else ""
		lines.append(["체력 %s / %s%s" % [TData.fmt_short(u.hp), TData.fmt_short(u.max_hp), bl], T.TEXT, 1])
		var wn: Array = []
		for el in u.weak:
			wn.append(TData.ELEMENT_NAME.get(String(el), ""))
		lines.append(["약점 %s · 방어율 %d%% · 내성 %d%%" % [", ".join(wn) if not wn.is_empty() else "없음", int(round(u.def_rate * 100.0)), int(round(u.resist * 100.0))], T.WEAK if not wn.is_empty() else T.TEXT, 1])
		var it := u.intent()
		var k := String(it.get("k", "attack"))
		var il := "다음 의도 %s%s" % [TData.INTENT_NAME.get(k, ""), " (무적 관통)" if bool(it.get("pierce", false)) else ""]
		if u.charge_max > 0:
			il += " · 차지 %d/%d" % [u.charge, u.charge_max]
		lines.append([il, T.INTENT_COL.get(k, T.TEXT), 1])
		var st: Array = []
		if u.stunned:
			st.append("기절 (다음 차례 쉼)")
		if u.stun_immune:
			st.append("기절 면역")
		elif u.stun_guard:
			st.append("기절 내성")
		if not st.is_empty():
			lines.append([" · ".join(st), T.STUN, 1])
		for mk in u.marks:
			lines.append(["%s %d겹 · 남은 %d" % [TData.MARK_NAME.get(mk, mk), u.mark_n(String(mk)), u.mark_dur(String(mk))], Color("#ffb08a"), 1])
		for b in u.buffs:
			lines.append([T.buff_line(b), T.DANGER if String(b.cat) == "atk" else Color("#c9b8c8"), 1])
	var h := 30.0
	for ln: Array in lines:
		h += 13.0 * float(mini(T.split_lines(String(ln[0]), DETAIL_W - 16.0, 10).size(), int(ln[2]))) + 1.0
	var r := Rect2(16, 60, DETAIL_W, minf(h, DETAIL_H)) if not u.is_witch() else Rect2(392, 60, DETAIL_W, minf(h, DETAIL_H))
	T.panel(self, r, Color(T.INK, 0.94), Color(T.LINE, 0.8), 1, 4)
	var X := r.position.x + 8.0
	var y := r.position.y + 16.0
	T.text(self, Vector2(X, y), title, 12, title_col)
	T.text(self, Vector2(r.end.x - 8, y), sub, 10, sub_col, HORIZONTAL_ALIGNMENT_RIGHT)
	draw_rect(Rect2(X, y + 5, DETAIL_W - 16.0, 1), Color(T.LINE, 0.3))
	y += 18.0
	for ln: Array in lines:
		if y > r.end.y - 4.0:
			break
		y += T.wrap(self, Vector2(X, y), String(ln[0]), DETAIL_W - 16.0, 10, ln[1], 13.0, int(ln[2])) + 1.0


func _draw_banner_box(title: String, sub: String, col: Color, t: float) -> void:
	var k := clampf(t / 0.35, 0.0, 1.0)
	var e := 1.0 - pow(1.0 - k, 3.0)
	var h := 84.0 * e
	var cy := 180.0
	draw_rect(Rect2(0, cy - h * 0.5, size.x, h), Color(T.INK, 0.86 * e))
	draw_rect(Rect2(0, cy - h * 0.5, size.x, 1), Color(T.LINE, 0.8 * e))
	draw_rect(Rect2(0, cy + h * 0.5 - 1, size.x, 1), Color(T.LINE, 0.8 * e))
	if k >= 1.0:
		T.text(self, Vector2(size.x * 0.5, cy + 8), title, 30, col, HORIZONTAL_ALIGNMENT_CENTER)
		if sub != "":
			T.text(self, Vector2(size.x * 0.5, cy + 30), sub, 10, Color(T.TEXT, 0.9), HORIZONTAL_ALIGNMENT_CENTER)


func _draw_banner() -> void:
	var win := banner_text == "승리"
	var lose := banner_text == "패배"
	_draw_banner_box(banner_text, "" if lose or _banner_t < 0.5 or fmod(_banner_t, 1.0) > 0.75 else banner_sub, T.GOLD if win else T.DANGER, _banner_t)
	if lose and _banner_t > 0.5:
		for b: Array in [[LOSE_RETRY, "다시 도전", true], [LOSE_SETUP, "편성으로", false]]:
			var r: Rect2 = b[0]
			T.panel(self, r, Color(T.LINE, 0.75) if b[2] else Color(T.INK, 0.9), Color(T.TEXT, 0.9), 1, 3)
			T.text(self, r.get_center() + Vector2(0, 5), String(b[1]), 12, T.INK if b[2] else T.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 0 if b[2] else -1)


func _draw_confirm() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(T.INK, 0.45))
	T.panel(self, CONFIRM, Color(T.PANEL, 0.97), Color(T.LINE, 0.9), 1, 4)
	T.text(self, Vector2(320, 162), "전투를 접고 편성으로 갈까요?", 12, T.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	T.text(self, Vector2(320, 178), "지금 전투의 진행은 사라집니다", 10, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_CENTER)
	T.panel(self, CONFIRM_NO, Color(T.INK, 0.9), Color(T.TEXT, 0.8), 1, 3)
	T.text(self, CONFIRM_NO.get_center() + Vector2(0, 5), "취소", 12, T.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	T.panel(self, CONFIRM_YES, Color(T.DANGER, 0.85), Color(T.TEXT, 0.8), 1, 3)
	T.text(self, CONFIRM_YES.get_center() + Vector2(0, 5), "철수", 12, T.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
