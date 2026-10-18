class_name THud
extends Control
## 턴제 전투 화면 표시 + 입력 (터치 우선, 키보드도 같은 흐름). 배치는 combat_proto.md §21.5 (3단: 위 = 적 정보 · 가운데 = 그림 · 아래 = 아군 정보).
## 위 띠: 차례 줄(다음 8명) · 전투 이름/웨이브 · 연쇄 단계 · 나가기 X.  그 아래 왼쪽: 행동 띠(지금 행동 이름·안내 1.6초).
## 오른쪽 위: 적 카드 3장(의도 종류·차지 칸·이름·약점·체력 막대·숫자·징표/디버프) — 보스 1명이면 넓은 보스 카드(남은 줄 칸).
## 아래 띠: 평소엔 아군 패널 3장(초상·이름·체력·크레딧 7칸·버프 아이콘·게이지), 바퀴가 열리면 설명 띠(이름·비용·예상 피해(크리 값)·효과·크레딧·안내).
## 머리 위엔 게이지·얇은 체력(마녀) / 의도 아이콘(적) · 기절 별 · 대상 화살표만.
## 스킬 바퀴: 차례 마녀 몸 둘레 위쪽 반원, 칸 6개 고정(기본 공격 → 장착 4 → 대마법). 한 번 누르면 고르고, 다시 누르면 사용/대상 고르기.
## 유닛·적 카드·아군 패널·차례 칸을 0.4초 누르면 상세 판(떼면 닫힘). 키보드: ←→↑↓ 고르기 · Z 확인 · X 뒤로 · Esc 철수 확인.
## 피해 숫자는 맞은 몸의 머리 꼭대기 아래에서(다단은 오른쪽 아래로 비켜 쌓기, 다른 대상의 숫자와 겹치면 위로), 버프 글은 아군 패널 위 / 적 카드 아래에서 뜬다.
## 보이는 값 (review_C2 H2): 행동 연출 동안(hold_view ~ release_view) 카드·패널·상세의 체력·징표·버프·쓰러짐은 그 사건이 화면에 뜰 때(view_event) 바뀐다.

signal chosen(action: Dictionary)
signal banner_tapped(choice: String) ## "setup" · "retry"
signal exit_tapped
signal help_tapped

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
const HELP_C := Vector2(582, 15) ## 도움말 "?" (review_G G05 — X 왼쪽)
const HELP_RECT := Rect2(566, 0, 32, 32)
const WHEEL_R := 78.0
const SLOT_R := 20.0
const ULT_R := 22.0
const HOLD := 0.4 ## 길게 누르기 (상세)
const CONFIRM := Rect2(220, 135, 200, 90)
const CONFIRM_NO := Rect2(228, 184, 88, 34) ## 터치 목표 34px 이상 (review_C2 M8)
const CONFIRM_YES := Rect2(324, 184, 88, 34)
const LOSE_RETRY := Rect2(194, 206, 120, 34) ## 패배 배너가 진 이유 세 줄만큼 높아져 아래로 (review_G G03)
const LOSE_SETUP := Rect2(326, 206, 120, 34)
const LOSE_H := 132.0
const DETAIL_W := 232.0
const DETAIL_H := 180.0
const DETAIL_Y := 86.0 ## 상세 판 위 끝 — 적 카드(y 32~82)를 덮지 않게 (review_C2 M7)
const HEAD_MIN_Y := 92.0 ## 적 머리 위 의도·게이지의 가장 위 (적 카드 밑 — review_C2 M1)
const NUM_MIN_Y := 118.0 ## 피해 숫자 시작 y의 가장 위 (18px 떠올라도 "약점" 꼬리표까지 적 카드 밑)
## 차례 줄의 적 글자
const SHORT := {"straw_golem": "골", "swamp_toad": "두", "ash_knight": "기", "ash_king": "왕", "trial_colossus": "거"}
## 피해 숫자 종류 → [글꼴 크기, 색]
const NUM_STYLE := {"dmg": [12, Color("#fff3e0")], "crit": [24, Color("#ffe08a")], "weak": [15, Color("#ffb04a")], "big": [24, Color("#fff3e0")],
	"hurt": [15, Color("#ff8a9a")], "heal": [12, Color("#b8f0a0")], "revive": [12, Color("#e6dcff")], "total": [12, Color("#ffe08a")],
	"status": [12, Color("#cfcfe0")], "break": [15, Color("#ffe08a")], "buff": [10, Color("#d9ccff")], "debuff": [10, Color("#c9b8c8")],
	"credit": [10, Color("#ffe08a")], "zero": [10, Color("#ff4f6a")], "mark": [10, Color("#ffb08a")]}
const BODY_KINDS := ["dmg", "crit", "weak", "big", "hurt", "heal", "revive", "total"]
const MERGE_KINDS := ["dmg", "crit", "weak", "big", "hurt"] ## 다단을 하나로 합치는 피해 숫자
const MERGE := 0.45 ## 같은 대상이 이 안에 또 맞으면 숫자를 더함 (대마법 다단 간격 0.09초 · 광역 히트 사이)
const HOLD_AGE := 0.2 ## 합칠 때 나이를 여기까지만 되돌림 (PVfx.Numbers와 같음)
const GROW_HITS := 3 ## 이만큼 합치면 글자를 한 단계 키움
const STACK_MAX := 3 ## 다른 숫자를 피해 쌓는 칸 최대

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
var msg_total := "" ## 행동 띠 끝의 금빛 합계 (review_C2 L4)
var numbers: Array = [] ## [{p, text, kind, age, dir, weak, key}]
var confirm_open := false ## 철수 확인 판
var battle_name := ""
var _t := 0.0
var _queue: Array = []
var _banner_t := 0.0
var _touch_seen := false
var _keys_seen := false ## 키보드를 쓴 적이 있나 (없으면 안내는 터치 문구 — 폰이 기본)
var _press := {} ## 누르는 중: {pos, t, unit}
var _detail: TUnit = null ## 상세 판에 띄운 유닛
var _flash := {} ## TUnit → 남은 시간 (차례 칸을 눌러 그 유닛을 알려 줌)
var _wave_t := 0.0 ## 웨이브 배너 남은 시간
var _wave_txt := ""
var _wave_flash := 0.0
var ult_t := 0.0 ## 대마법 연출 남은 시간 (연쇄 칩 숨쉬기)
var _back: PanelBack
var _portraits := {} ## TUnit → PortraitBox
var _view := {} ## TUnit → 보이는 값 {hp, max_hp, bar_i, alive, icons, marks} — 행동 연출 중에만 (비면 실제 값)
var banner_lines: Array = [] ## 패배 배너 아래 진 이유 (review_G G03 · review_F F13) [[글, 색]]
var lose_main := "retry" ## 패배 배너의 강조 버튼 (시련 = setup)
var hint_once := "" ## 다음 마녀 차례에 행동 띠에 한 번 띄울 안내 (첫 플레이 B2 뒤 "길게 누르면 자세히")
var _after := {} ## "사용 뒤" 차례 줄 캐시 {key, queue, fin, rate} (review_F F05 규칙 B)


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
	ult_t = maxf(ult_t - delta, 0.0)
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
		n.last = float(n.get("last", 0.0)) + delta
	numbers = numbers.filter(func(n: Dictionary) -> bool: return float(n.age) < 1.1)
	if actor != null and _wheel_on():
		_dim_others(true)
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
	_after = {}
	if hint_once != "":
		show_msg(hint_once, T.GOLD)
		hint_once = ""
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
	msg_total = ""


## 한 행동의 적 피해 합계를 행동 띠 끝에 붙인다 ("엠버 — 세계의 끝 · 합계 232,368")
func show_total(sum: int) -> void:
	msg_total = "합계 " + TData.fmt_short(sum)
	msg_t = maxf(msg_t, 1.6)


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
## weak = 위에 "약점" 꼬리표. value > 0 = 피해 값 — 같은 대상의 다단은 숫자 하나를 이어서 키운다 (review_D A1, PVfx.Numbers와 같은 규칙)
func pop(u: TUnit, text: String, kind := "dmg", weak := false, value := 0) -> void:
	if u == null or not actors.has(u):
		return
	var a: TActor = actors[u]
	var key := "%d:%s" % [u.get_instance_id(), "body" if kind in BODY_KINDS else ("st" if kind in ["status", "break"] else "txt")]
	if value > 0 and kind in MERGE_KINDS:
		for n: Dictionary in numbers:
			if String(n.key) == key and int(n.get("val", 0)) > 0 and float(n.last) < MERGE and String(n.kind) in MERGE_KINDS:
				n.val = int(n.val) + value
				n.hits = int(n.hits) + 1
				n.last = 0.0
				n.age = minf(float(n.age), HOLD_AGE)
				n.weak = bool(n.weak) or weak
				n.crit = bool(n.crit) or kind == "crit"
				n.kind = "crit" if bool(n.crit) else ("hurt" if kind == "hurt" else ("big" if int(n.val) >= 300000 or String(n.kind) == "big" else ("weak" if bool(n.weak) else String(n.kind))))
				n.text = TData.fmt_short(int(n.val)) + ("!" if bool(n.crit) else "")
				return
	var k := 0
	for n: Dictionary in numbers:
		if String(n.key) == key and float(n.age) < 0.5:
			k += 1
	var p := Vector2.ZERO
	var dir := -1.0
	var age := 0.0
	if kind in BODY_KINDS:
		# 머리 꼭대기 아래 14px (맞는 연출의 번쩍·번개 중심인 몸 가운데를 피함, review_C2 H3) — 같은 몸의 다른 숫자는 아래 _avoid_numbers가 비킴
		p = _num_base(a)
		var fs0 := int(NUM_STYLE.get(kind, NUM_STYLE.dmg)[0])
		p = _avoid_numbers(p, text, fs0)
		var hw := T.width(text, fs0) * 0.5 + 18.0 # 화면 밖으로 잘리지 않게 (오른쪽 끝 적 · "n타" 꼬리표 몫)
		p.x = clampf(p.x, hw, 640.0 - hw)
	elif kind in ["status", "break"]:
		# 상태 글은 그 몸의 마지막 숫자 칸 위에서 (숫자와 겹치지 않게)
		var last := _last_number(u)
		if last.is_empty() and u.is_witch():
			# 마녀 머리 위 체력·게이지 막대 오른쪽 (review_D B8: 막대 위에 겹쳤다)
			var top := to_screen(a.head()).round()
			p = Vector2(top.x + 24.0 + T.width(text, 12) * 0.5, top.y - 1.0 - 14.0 * float(k % 3))
		elif last.is_empty():
			p = _num_base(a) + Vector2(0, -16 - 14 * (k % 3))
		else:
			p = Vector2((last.p as Vector2).x, (last.p as Vector2).y - float(_num_fs(last)) - 6.0 - 14.0 * float(k % 3))
	elif u.is_witch():
		p = Vector2(_panel_rect(u.slot).position.x + 104.0, PANEL_Y - 4.0) + Vector2(0, -12.0 * float(k % 2))
		age = -0.35 * float(k / 2) # 한 패널에 두 줄씩, 나머지는 늦춰서
	else:
		var cr := _card_rect(u)
		var stagger := 24.0 if not _boss_card_on() and pos_index(battle.enemies.size(), battle.enemies.find(u)) == 1 else 0.0 # 가운데 카드의 글은 두 줄 아래 (이웃 카드 글과 가로로 겹치지 않게)
		p = Vector2(cr.position.x + cr.size.x * 0.5, cr.end.y + 12.0 + stagger) + Vector2(0, 12.0 * float(k % 2))
		age = -0.35 * float(k / 2)
		dir = 1.0
	numbers.append({"p": p, "text": text, "kind": kind, "age": age, "dir": dir, "weak": weak, "key": key,
		"val": value, "hits": 1, "last": 0.0, "crit": kind == "crit"})
	if numbers.size() > 48:
		numbers.pop_front()


## 숫자 항목의 글자 크기: 종류 크기, 3타 이상 합치면 한 단계 큰 설계 크기 (12 → 15 · 15 → 24 · 24 → 30 — 갈무리는 설계 크기로만 그림)
func _num_fs(n: Dictionary) -> int:
	var fs := int(NUM_STYLE.get(String(n.kind), NUM_STYLE.dmg)[0])
	if int(n.get("hits", 1)) >= GROW_HITS:
		var i := T.SIZES.find(fs)
		if i >= 0 and i + 1 < T.SIZES.size():
			fs = int(T.SIZES[i + 1])
	return fs


## 피해 숫자의 시작점: 머리 꼭대기 아래 14px, 몸 가운데 + 6 (적 카드 밑보다 위로는 안 감)
func _num_base(a: TActor) -> Vector2:
	var top := to_screen(a.head())
	return Vector2(to_screen(a.center()).x + 6.0, maxf(top.y + 14.0, NUM_MIN_Y))


## 살아 있는 다른 숫자 칸과 겹치면 글자 높이 + 2px씩 위로 (위가 막히면 처음부터 아래로) 최대 STACK_MAX칸, 넘치면 가로로 비킴
## (review_D A2 — PVfx.Numbers의 STACK 규칙. 예전 14px 위·아래 번갈이는 NUM_MIN_Y 근처에서 제자리걸음을 했다)
func _avoid_numbers(p: Vector2, text: String, fs: int) -> Vector2:
	var w := T.width(text, fs) + 8.0 # 다단으로 커지는 몫
	var step := float(fs) + 2.0
	var dy := -step if p.y - step * float(STACK_MAX) >= NUM_MIN_Y else step
	var base := p
	for tries in STACK_MAX * 2 + 1:
		if not _number_hit(p, w, fs):
			return p
		if tries < STACK_MAX:
			p.y += dy
		else: # 칸이 다 차면 대상 쪽 x로 ±20씩
			var side := 1.0 if (tries - STACK_MAX) % 2 == 0 else -1.0
			p = base + Vector2(side * 20.0 * float((tries - STACK_MAX) / 2 + 1), dy * float(STACK_MAX - 1))
	return p


func _number_hit(p: Vector2, w: float, fs: int) -> bool:
	var r := Rect2(p.x - w * 0.5, p.y - float(fs), w, float(fs))
	for n: Dictionary in numbers:
		if not (String(n.kind) in BODY_KINDS) or float(n.age) > 0.7 or float(n.age) < 0.0:
			continue
		var nfs := _num_fs(n)
		var nw := T.width(String(n.text), nfs)
		var q: Vector2 = n.p
		if r.intersects(Rect2(q.x - nw * 0.5, q.y - float(nfs), nw, float(nfs)).grow(1.0)):
			return true
	return false


## 그 유닛의 가장 최근 몸 숫자 (0.6초 안)
func _last_number(u: TUnit) -> Dictionary:
	var key := "%d:body" % u.get_instance_id()
	for i in range(numbers.size() - 1, -1, -1):
		var n: Dictionary = numbers[i]
		if String(n.key) == key and float(n.age) < 0.6:
			return n
	return {}


# ═══════════════════════════════════════════════════════════
# 보이는 값 (review_C2 H2): 결과는 그 히트·글이 화면에 뜰 때 보인다
# ═══════════════════════════════════════════════════════════

## 행동 결과를 계산하기 직전에 부른다: 지금 값을 붙잡아 둔다
func hold_view() -> void:
	_view.clear()
	if battle == null:
		return
	for u in battle.all_units():
		_view[u] = _snap(u)
	for u in _view:
		if actors.has(u):
			(actors[u] as TActor).view_ratio = vratio(u)


## 행동 연출이 끝나면: 실제 값으로 맞춘다 (어긋남 방지)
func release_view() -> void:
	_view.clear()
	for u in actors:
		(actors[u] as TActor).view_ratio = -1.0


func _snap(u: TUnit) -> Dictionary:
	return {"hp": u.hp, "max_hp": u.max_hp, "bar_i": u.bar_i, "alive": u.alive, "icons": u.buff_icons(), "marks": _marks_of(u)}


func _marks_of(u: TUnit) -> Dictionary:
	var out := {}
	for k in u.marks:
		out[k] = {"n": u.mark_n(String(k)), "dur": u.mark_dur(String(k))}
	return out


## 사건 하나가 화면에 뜬 순간 (TStage._show_event): 그 유닛의 보이는 값을 사건만큼 옮긴다. t "down" = 쓰러짐 글이 뜸
func view_event(e: Dictionary) -> void:
	var u: TUnit = e.get("tgt")
	if u == null or not _view.has(u):
		return
	var v: Dictionary = _view[u]
	match String(e.t):
		"hit":
			if not bool(e.get("invincible", false)):
				v.hp = int(e.get("hp", u.hp))
				v.max_hp = int(e.get("max_hp", u.max_hp))
				v.bar_i = int(e.get("bar_i", u.bar_i))
		"heal":
			v.hp = mini(int(v.hp) + int(e.v), int(v.max_hp))
		"hp_cost":
			v.hp = maxi(int(v.hp) - int(e.v), 1)
		"revive":
			_view[u] = _snap(u)
		"down":
			v.alive = false
			v.hp = 0
			v.icons = []
			v.marks = {}
		_:
			if u.alive:
				v.icons = u.buff_icons()
				v.marks = _marks_of(u)
	if actors.has(u):
		(actors[u] as TActor).view_ratio = vratio(u)


func vhp(u: TUnit) -> int:
	return int(_view[u].hp) if _view.has(u) else u.hp


func vmax(u: TUnit) -> int:
	return int(_view[u].max_hp) if _view.has(u) else u.max_hp


func vratio(u: TUnit) -> float:
	return clampf(float(vhp(u)) / float(maxi(vmax(u), 1)), 0.0, 1.0)


func valive(u: TUnit) -> bool:
	return bool(_view[u].alive) if _view.has(u) else u.alive


func vbar(u: TUnit) -> int:
	return int(_view[u].bar_i) if _view.has(u) else u.bar_i


func vicons(u: TUnit) -> Array:
	return _view[u].icons if _view.has(u) else u.buff_icons()


## 징표 kind → {n, dur}
func vmarks(u: TUnit) -> Dictionary:
	return _view[u].marks if _view.has(u) else _marks_of(u)


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
		_keys_seen = true
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
				_banner_go(lose_main)
			elif event.is_action_pressed("es_attack"):
				_banner_go("setup" if lose_main == "retry" else "retry")
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
	if HELP_RECT.has_point(p) and state != "banner":
		help_tapped.emit()
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
		if state == "target" and i != sel:
			i = -1 # 대상 고르기 중엔 고른 칸만 눌림 — 다른 칸은 흐리고 그 밑의 마녀·적을 누를 수 있다 (review_C2 H1)
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
		var r := body_rect(a)
		if r.has_point(p):
			var d := p.distance_to(r.get_center())
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


## 바퀴가 열린 동안 다른 마녀는 흐리게 (고르는 마녀가 또렷이). 아군 대상 고르기면 대상 후보는 또렷이 (review_C2 H1 ③)
func _dim_others(on: bool) -> void:
	for u in actors:
		var a: TActor = actors[u]
		if u.is_witch() and a != actor:
			var cand := state == "target" and targets.has(a)
			a.modulate = Color(0.55, 0.5, 0.65) if on and not cand else Color.WHITE


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

## 아래 띠가 설명 띠인가 (바퀴가 열림). 아군 대상 고르기 중엔 아군 패널로 되돌려 패널을 누르면 대상 (review_C2 H1 ②)
func _strip_on() -> bool:
	return (state == "wheel" or state == "target") and sel >= 0 and not _ally_pick() # 칸을 고르기 전엔 아군 패널을 그대로 (review_G G07)


func _wheel_on() -> bool:
	return state == "wheel" or state == "target"


## 아군 대상 고르기 중인가
func _ally_pick() -> bool:
	return state == "target" and not targets.is_empty() and (targets[0] as TActor).unit.is_witch()


## 아군 패널 자리: 왼→오 = 뒤·중·앞 (전장 그림 순서와 같게, review_C2 M6 [제안])
func _panel_rect(slot: int) -> Rect2:
	var r := Rect2(PANEL_X0 + PANEL_STEP * float(2 - slot), PANEL_Y, PANEL_W, PANEL_H)
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


## 차례 칸: 왼쪽에 "지금" 꼬리표 자리(22px)를 두고 지금(24) → 다음 7(18) (review_G G19)
func _queue_rect(i: int) -> Rect2:
	if i == 0:
		return Rect2(26, 3, 24, 24)
	return Rect2(56 + 21 * (i - 1), 6, 18, 18)


## 위 띠의 연쇄 칩 자리 (안내 D5 강조) — _draw_top과 같은 셈
func chain_rect() -> Rect2:
	var wl := battle_name
	if battle.wave_count() > 1:
		wl = "웨이브 %d/%d" % [battle.wave_i + 1, battle.wave_count()]
	var cx := 562.0 - T.width(wl, 10) - 8.0
	if battle.chain_stage <= 0:
		return Rect2(cx - 120, 6, 120, 19)
	var lab := "연쇄 %d단계 · 이어 쓰면 대마법 효과 ×%s" % [battle.chain_stage, str(TData.CHAIN_MULT[mini(battle.chain_stage, 2)])] if battle.chain_stage < 3 else "연쇄 3단계 (최대) · 효과 ×1.5"
	var w := T.width(lab, 10) + 10.0
	return Rect2(cx - w - 2.0, 6, w + 4.0, 19)


## 차례 줄 전체 (안내 B5 강조)
func queue_box() -> Rect2:
	return Rect2(2, 1, _queue_rect(QUEUE_N - 1).end.x + 30.0, 28)


## 바퀴 칸 i의 사각 (안내 강조·시험 봇)
func slot_rect(i: int) -> Rect2:
	if i < 0 or i >= slots.size():
		return Rect2()
	var r := _slot_r(i) + 3.0
	return Rect2((slots[i].pos as Vector2) - Vector2(r, r), Vector2(r * 2.0, r * 2.0))


## 유닛 그림의 누를 수 있는 몸 사각 (_actor_at과 같은 크기)
func body_rect(a: TActor) -> Rect2:
	var feet := to_screen(a.feet())
	var head := to_screen(a.head())
	var hw := maxf(a.half_w(), 14.0) + 8.0
	return Rect2(Vector2(feet.x - hw, head.y - 6.0), Vector2(hw * 2.0, feet.y - head.y + 12.0))


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
		p.visible = not strip and modulate.a > 0.5 # 대마법 동안 HUD가 걷힐 때 초상은 숨김 (에스카의 EArt 테 셰이더는 알파를 0/1로 잘라 흰 유령이 됨, review_D A4)
		var r := _panel_rect(w.slot)
		p.position = r.position + Vector2(4, 4)
		p.modulate = Color(1, 1, 1, 0.45) if not valive(w) else Color.WHITE


## 판 바탕 (초상보다 아래) — PanelBack이 부른다
func _draw_panel_backs(ci: CanvasItem) -> void:
	if battle == null:
		return
	var pick := _ally_pick()
	for w in battle.witches:
		var r := _panel_rect(w.slot)
		var cur := battle.actor == w
		var fill := Color(T.PANEL_HI if cur else T.PANEL, 0.92 if valive(w) else 0.6)
		var border := Color(T.GOLD, 1.0) if cur else Color(T.LINE, 0.55)
		var bw := 2 if cur else 1
		if pick and targets.has(actors.get(w)):
			# 아군 대상 고르기: 후보 패널은 밝은 테, 지금 고른 대상은 금빛 2px
			var on: bool = targets[tsel] == actors.get(w)
			fill = Color(T.PANEL_HI, 0.95) if on else fill
			border = T.GOLD if on else Color(T.TEXT, 0.85)
			bw = 2 if on else 1
		T.panel(ci, r, fill, border, bw, 3)


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
	if _wheel_on():
		_draw_wheel()
	if _strip_on():
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
		_draw_banner_box(_wave_txt, "", T.TEXT, 1.0 - _wave_t, _wave_t)
	if state == "banner":
		_draw_banner()
	if confirm_open:
		_draw_confirm()


## 위 띠: 바탕 · 차례 줄 · 전투 이름/웨이브 · 연쇄 · X
func _draw_top() -> void:
	draw_rect(Rect2(0, 0, size.x, 30), Color(T.INK, 0.55))
	draw_rect(Rect2(0, 30, size.x, 1), Color(T.LINE, 0.3))
	if state != "banner": # 승패 배너가 열리면 차례 줄도 숨김 (review_G G20)
		_draw_queue()
	var wl := battle_name
	if battle.wave_count() > 1:
		wl = "웨이브 %d/%d" % [battle.wave_i + 1, battle.wave_count()]
	var wcol := T.GOLD if _wave_flash > 0.0 and _wave_flash < 0.4 else T.TEXT
	T.text(self, Vector2(562, 20), wl, 10, wcol, HORIZONTAL_ALIGNMENT_RIGHT)
	# 대마법 연쇄 진행 중 (§13.6) — 효과를 같이 (review_G G17)
	if battle.chain_owner != null and battle.chain_stage > 0 and state != "banner": # 승패 배너가 열리면 숨김 (L5)
		var cx := 562.0 - T.width(wl, 10) - 8.0
		var lab := "연쇄 %d단계 · 이어 쓰면 대마법 효과 ×%s" % [battle.chain_stage, str(TData.CHAIN_MULT[mini(battle.chain_stage, 2)])] if battle.chain_stage < 3 else "연쇄 3단계 (최대) · 효과 ×1.5"
		var w := T.width(lab, 10) + 10.0
		var br := 0.5 + 0.5 * sin(_t * TAU / 0.6) if ult_t > 0.0 else 0.0 # 대마법 동안 0.6초 주기로 숨쉼
		if br > 0.0:
			draw_rect(Rect2(cx - w - 2.0, 6, w + 4.0, 19), Color(T.GOLD, 0.25 * br))
		T.panel(self, Rect2(cx - w, 8, w, 15), Color(T.INK, 0.9).lerp(Color(T.GOLD, 0.9), 0.25 * br), Color(T.GOLD, 0.8 + 0.2 * br), 1, 3)
		T.text(self, Vector2(cx - w * 0.5, 20), lab, 10, T.GOLD.lerp(Color.WHITE, 0.5 * br), HORIZONTAL_ALIGNMENT_CENTER)
	# 도움말 ?
	draw_circle(HELP_C, 12.0, Color(T.INK, 0.6))
	draw_arc(HELP_C, 12.0, 0.0, TAU, 24, Color(T.LINE, 0.6), 1.0)
	T.text(self, HELP_C + Vector2(0, 5), "?", 12, T.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	# 나가기 X
	draw_circle(X_C, 12.0, Color(T.INK, 0.6))
	draw_arc(X_C, 12.0, 0.0, TAU, 24, Color(T.LINE, 0.6), 1.0)
	draw_line(X_C + Vector2(-4, -4), X_C + Vector2(4, 4), Color(T.TEXT, 0.85), 1.6)
	draw_line(X_C + Vector2(-4, 4), X_C + Vector2(4, -4), Color(T.TEXT, 0.85), 1.6)


## 차례 줄: "지금" 꼬리표 · 지금(크게·금테) → 다음 7 · "다음 →". 아군 = 속성 색 칸 · 적 = 먹 칸 + 빨간 테(보스 금테) + 카드 번호 배지 · 기절 = 별 + 어둡게.
## 다가오는 필살기 차례 = 빨간 2px 테 + 칸 위 빨간 삼각 (관통이면 관통 표시) — review_F F05 규칙 A.
## 바퀴에서 칸을 고른 동안 그 마법을 쓴 뒤의 순서가 다르면 "사용 뒤" 줄로 그린다 (앞당겨진 아군 칸 금빛 밑줄 · 밀린 적 칸 흐린 밑줄) — 규칙 B
func _draw_queue() -> void:
	var q: Array = _queue
	var fin: Dictionary = battle.finisher_slots(_queue)
	var after := _after_queue()
	if not after.is_empty():
		q = after.queue
		fin = after.fin
	T.text(self, Vector2(14, 13), "지금", 8, T.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 0)
	draw_colored_polygon(PackedVector2Array([Vector2(19, 17), Vector2(23, 20), Vector2(19, 23)]), Color(T.GOLD, 0.8))
	var last := _queue_rect(QUEUE_N - 1)
	T.text(self, Vector2(last.end.x + 4, 18), "다음 →" if after.is_empty() else "사용 뒤", 8, T.TEXT_SUB if after.is_empty() else T.GOLD, HORIZONTAL_ALIGNMENT_LEFT, 0)
	for i in q.size():
		var u: TUnit = q[i]
		var r := _queue_rect(i)
		var witch := u.is_witch()
		var fill: Color = Color(TData.ELEMENT_COLOR.get(u.element, T.LINE), 0.9) if witch else Color(T.PANEL, 0.95)
		var border := T.GOLD if i == 0 else (Color(T.INK, 0.9) if witch else (T.GOLD if u.boss else T.DANGER))
		if u.stunned:
			fill = fill.darkened(0.5)
		var fm: Dictionary = fin.get(i, {})
		T.panel(self, r, fill, T.DANGER if not fm.is_empty() and i > 0 else border, 2 if (i == 0 or not fm.is_empty()) else 1, 4 if i == 0 else 3)
		var glyph: String = SHORT.get(u.id, u.name.substr(0, 1))
		var fs := 12 if i == 0 else 10
		T.text(self, r.get_center() + Vector2(0, 5 if i == 0 else 4), glyph, fs, T.INK if witch else T.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 0 if witch else -1)
		var dup := _dup_suffix(u).strip_edges() if not witch else ""
		if dup != "": # 같은 적이 둘 이상일 때만 카드와 같은 A·B 배지 (L3)
			var b := r.end - Vector2(2, 2)
			draw_rect(Rect2(b - Vector2(4, 4), Vector2(8, 8)), Color(T.INK, 0.95))
			T.text(self, b + Vector2(0, 4), dup, 8, T.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 0)
		if u.stunned:
			T.star(self, Vector2(r.get_center().x, r.position.y + 1), 3.5, T.STUN)
		elif not fm.is_empty():
			var c := Vector2(r.get_center().x, r.position.y - 1)
			if bool(fm.get("pierce", false)):
				draw_rect(Rect2(c - Vector2(5, 3), Vector2(10, 5)), Color(T.INK, 0.95))
				draw_line(c + Vector2(-4, 0), c + Vector2(3, 0), T.DANGER, 1.2)
				draw_line(c + Vector2(1, -2), c + Vector2(3, 0), T.DANGER, 1.2)
				draw_line(c + Vector2(1, 2), c + Vector2(3, 0), T.DANGER, 1.2)
			else:
				draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -3), c + Vector2(4, -3), c + Vector2(0, 2)]), T.DANGER)
		if not after.is_empty() and i > 0:
			var mv := int((after.moved as Dictionary).get(i, 0))
			if mv != 0:
				draw_rect(Rect2(r.position.x, r.end.y + 1, r.size.x, 2), T.GOLD if mv > 0 else T.TEXT_OFF)


## "사용 뒤" 줄 (바퀴에서 칸을 고른 동안만): 그 마법을 쓴 사본 전투의 순서. 지금 줄과 같으면 {} (review_F F05 규칙 B)
func _after_queue() -> Dictionary:
	if not (state == "wheel" or state == "target") or sel < 0 or sel >= slots.size() or actor == null or bool(slots[sel].empty) or bool(slots[sel].ult) or not bool(slots[sel].can):
		return {}
	var s: Dictionary = slots[sel]
	var tgt: TUnit = null
	if state == "target" and not targets.is_empty():
		tgt = (targets[tsel] as TActor).unit
	else:
		var vt: Array[TUnit] = battle.alive_of(battle.enemies) if String(s.id) == "basic" else battle.valid_targets(actor.unit, String(s.id))
		if String(s.target) in ["ally", "ally_any"]:
			for t in vt:
				if t != actor.unit:
					tgt = t
					break
		if tgt == null and not vt.is_empty():
			tgt = vt[0]
	var key := "%s|%d|%d" % [String(s.id), tgt.get_instance_id() if tgt != null else 0, battle.turn_no]
	if String(_after.get("key", "")) == key:
		return _after.get("res", {})
	var c := battle.simulate(actor.unit, String(s.id), tgt)
	var q: Array[TUnit] = [actor.unit]
	var cq: Array[TUnit] = c.preview(QUEUE_N - 1)
	for x in cq:
		var mine := battle.unit_by_key(c.unit_key(x))
		if mine != null:
			q.append(mine)
	var fin := c.finisher_slots(cq) # 사본의 차지로 센 필살기 칸 (번호는 뒤 7칸 기준 → +1)
	var fin2 := {}
	for k in fin:
		fin2[int(k) + 1] = fin[k]
	var same := q.size() == _queue.size()
	if same:
		for i in q.size():
			if q[i] != _queue[i]:
				same = false
				break
	var now_fin := battle.finisher_slots(_queue)
	var res := {}
	if not same or fin2.keys() != now_fin.keys():
		# 밑줄: 그 유닛의 n번째 등장이 지금 줄보다 앞이면 + (금빛), 뒤면 − (흐림)
		var moved := {}
		var seen_new := {}
		var seen_old := {}
		var old_pos := {}
		for i in _queue.size():
			var u: TUnit = _queue[i]
			seen_old[u] = int(seen_old.get(u, 0)) + 1
			old_pos["%d:%d" % [u.get_instance_id(), int(seen_old[u])]] = i
		for i in q.size():
			var u: TUnit = q[i]
			seen_new[u] = int(seen_new.get(u, 0)) + 1
			var op = old_pos.get("%d:%d" % [u.get_instance_id(), int(seen_new[u])])
			if op == null or int(op) > i:
				moved[i] = 1 if u.is_witch() else 0
			elif int(op) < i:
				moved[i] = -1 if not u.is_witch() else 0
		res = {"queue": q, "fin": fin2, "moved": moved}
	_after = {"key": key, "res": res}
	return res


## 행동 띠 (왼쪽 위 (6, 32, 300, 18)): 지금 행동 이름·안내
## 아군 대상 고르기 중엔 그 안내 한 줄 ("공허의 요람 → 아군 1 · 패널이나 마녀를 누르세요", review_C2 H1 ②)
func _draw_action_strip() -> void:
	if _ally_pick() and sel >= 0 and sel < slots.size():
		var s: Dictionary = slots[sel]
		var hint := "%s → %s · %s" % [String(s.name), T.TARGET_NAME.get(String(s.target), "아군 1"), "패널이나 마녀를 누르세요" if _touch_seen else "←→ 대상 · Z 확인"]
		var hw := minf(T.width(hint, 12) + 22.0, 300.0)
		var hr := Rect2(ACT_STRIP.position, Vector2(hw, ACT_STRIP.size.y))
		draw_rect(hr, Color(T.INK, 0.85))
		draw_rect(Rect2(hr.position, Vector2(2, hr.size.y)), T.GOLD)
		T.text(self, hr.position + Vector2(10, 14), T.clip(hint, 12, 280), 12, T.TEXT)
		return
	if (msg_t <= 0.0 or msg == "") and state == "wheel" and sel < 0 and actor != null:
		# 칸을 고르기 전: 아군 패널을 그대로 두고 안내는 여기 (review_G G07)
		var hint := "%s의 차례 — %s" % [actor.unit.name, "칸을 눌러 마법 고르기" if _touch_seen or not _keys_seen else "←→ 고르기 · Z 확인"]
		var hw := minf(T.width(hint, 12) + 22.0, 300.0)
		var hr := Rect2(ACT_STRIP.position, Vector2(hw, ACT_STRIP.size.y))
		draw_rect(hr, Color(T.INK, 0.85))
		draw_rect(Rect2(hr.position, Vector2(2, hr.size.y)), TData.ELEMENT_COLOR.get(actor.unit.element, T.GOLD))
		T.text(self, hr.position + Vector2(10, 14), T.clip(hint, 12, 280), 12, T.TEXT)
		return
	if msg_t <= 0.0 or msg == "":
		return
	var a := minf(msg_t / 0.4, 1.0)
	var tot := (" · " + msg_total) if msg_total != "" else ""
	var mw := minf(T.width(msg, 12), 280.0 - (T.width(tot, 12) if tot != "" else 0.0))
	var w := minf(mw + T.width(tot, 12) + 22.0, 300.0)
	var r := Rect2(ACT_STRIP.position, Vector2(w, ACT_STRIP.size.y))
	draw_rect(r, Color(T.INK, 0.72 * a))
	draw_rect(Rect2(r.position, Vector2(2, r.size.y)), Color(msg_col, a))
	var shown := T.clip(msg, 12, mw)
	T.text(self, r.position + Vector2(10, 14), shown, 12, Color(T.TEXT, a))
	if tot != "":
		T.text(self, r.position + Vector2(10 + T.width(shown, 12), 14), tot, 12, Color(T.GOLD, a))


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
		if not valive(unit):
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
			var col := T.HP_ALLY.lerp(T.HP_LOW, clampf(1.0 - vratio(unit) * 2.0, 0.0, 1.0))
			draw_rect(Rect2(x, y, w * a.shown_hp, 3), Color(col, 0.45))
			draw_rect(Rect2(x, y, w * vratio(unit), 3), col)
			draw_rect(Rect2(x, y + 4, w * clampf(unit.gauge / TData.GAUGE_MAX, 0.0, 1.0), 2), Color(T.GAUGE, 0.95 if cur else 0.7))
			if cur:
				draw_rect(Rect2(x - 2, y - 2, w + 4, 11), Color(T.GOLD, 0.9), false, 1.0)
			if unit.is_taunting():
				T.buff_icon(self, Vector2(x + w + 3, y - 2), {"cat": "taunt"})
		else:
			# 의도 아이콘·게이지는 적 카드 밑(y ≥ 92)에서 — 키 큰 적도 가려지지 않게 (review_C2 M1)
			top.y = maxf(top.y, HEAD_MIN_Y + 15.0)
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
		if not valive(e):
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
	if k == "dispel":
		var nb := 0
		for wt in battle.alive_of(battle.witches):
			nb += wt.buffs.size()
		name += " · 버프 %d" % nb # 지워질 버프 수 (review_G G15)
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


## 징표·디버프 아이콘 (오른쪽 끝 right부터, 간격 15, 최대 maxn개 + "+n"). 징표는 둥근 바탕(약점 네모 칸과 구분, L2), 겹 수는 아이콘 밖 먹 알약 (L1)
func _foe_icons(e: TUnit, right: float, y: float, maxn: int) -> void:
	var list: Array = []
	var mk_now := vmarks(e)
	for mk in mk_now:
		list.append({"mark": String(mk), "n": int(mk_now[mk].n)})
	for ic in vicons(e):
		list.append(ic)
	var shown := mini(list.size(), maxn)
	var x := right - 15.0 * float(shown) + 5.0
	if list.size() > maxn:
		var more := "+%d" % (list.size() - maxn)
		x -= T.width(more, 10) + 2.0
		T.text(self, Vector2(right, y + 9), more, 10, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_RIGHT)
	for i in shown:
		var d: Dictionary = list[i]
		var p := Vector2(x + 15.0 * float(i), y)
		if d.has("mark") and not d.has("cat"):
			var c := p + Vector2(5, 5)
			draw_circle(c, 5.5, Color(T.INK, 0.95))
			draw_arc(c, 5.0, 0.0, TAU, 16, Color("#ff9a5a", 0.85), 1.0)
			T.mark_icon(self, c, String(d.mark), _t)
			T.count_pill(self, p, int(d.n))
		else:
			T.buff_icon(self, p, d, int(d.dur))


func _hp_bar(e: TUnit, r: Rect2) -> void:
	draw_rect(r.grow(1), Color(T.INK, 0.95))
	var a: TActor = actors.get(e)
	var shown := a.shown_hp if a != null else vratio(e)
	draw_rect(Rect2(r.position, Vector2(r.size.x * shown, r.size.y)), Color(T.HP_FOE_TRAIL, 0.5))
	draw_rect(Rect2(r.position, Vector2(r.size.x * vratio(e), r.size.y)), T.HP_FOE)


## 공격 칸을 고른 동안: 대상 후보 카드의 체력 막대에 예상 피해 구간(금빛 0.5) + 예상 ≥ 남은 체력이면 "처치"·"줄 깸", 크리 예상만 넘으면 "크리면 처치" (review_F F06 d)
func _est_overlay(e: TUnit, bar: Rect2, card: Rect2) -> void:
	var info := _est_for(e)
	if info.is_empty():
		return
	var hp := float(vhp(e))
	var mx := float(maxi(vmax(e), 1))
	var est := float(info.est)
	var w := bar.size.x * clampf(est / mx, 0.0, hp / mx)
	var x1 := bar.position.x + bar.size.x * (hp / mx)
	draw_rect(Rect2(x1 - w, bar.position.y, w, bar.size.y), Color(T.GOLD, 0.5 + 0.2 * sin(_t * 6.0)))
	var lab := ""
	var col := T.GOLD
	var multi := e.bars.size() > 1 and vbar(e) < e.bars.size() - 1
	if est >= hp:
		lab = "줄 깸" if multi else "처치"
	elif float(info.crit) >= hp and not bool(info.sure):
		lab = "크리면 " + ("줄 깸" if multi else "처치")
		col = T.TEXT_SUB
	if lab != "":
		var lw := T.width(lab, 10) + 8.0
		var lr := Rect2(card.end.x - lw - 2.0, card.end.y - 1.0, lw, 13)
		T.panel(self, lr, Color(T.INK, 0.95), col, 1, 2)
		T.text(self, Vector2(lr.get_center().x, lr.position.y + 11), lab, 10, col, HORIZONTAL_ALIGNMENT_CENTER)


## 고른 공격 칸의 그 적에 대한 예상 {est, crit, rate, sure} — 공격 칸을 고르지 않았거나 그 적이 대상이 아니면 {}
func _est_for(e: TUnit) -> Dictionary:
	if actor == null or sel < 0 or sel >= slots.size() or not (state == "wheel" or state == "target"):
		return {}
	var s: Dictionary = slots[sel]
	if bool(s.empty) or String(s.kind) != "attack" or not bool(s.can):
		return {}
	var tg := String(s.target)
	if tg == "enemy" and state == "target" and not targets.has(actors.get(e)):
		return {}
	if not (tg in ["enemy", "enemies"]):
		return {}
	return battle.est_info(actor.unit, e, "" if String(s.id) == "basic" else String(s.id))


func _draw_card(e: TUnit) -> void:
	var r := _card_rect(e)
	var X := r.position.x
	var Y := r.position.y
	_card_frame(e, r)
	var pw := _intent_pill(e, Vector2(X + 3, Y + 3))
	_charge_cells(e, X + 96.0, Y + 5.0, 6.0, 8.0, 7.0)
	if e.charge_max > 0:
		# "차지" 이름표 (review_G G16): 알약과 닿지 않을 때만
		var lx := X + 96.0 - 7.0 * float(e.charge_max) - 2.0
		if lx - T.width("차지", 8) > X + 3.0 + pw + 2.0:
			T.text(self, Vector2(lx, Y + 12), "차지", 8, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_RIGHT, 0)
	# 이름 · 약점 · 줄 수
	T.text(self, Vector2(X + 4, Y + 28), T.clip(e.name + _dup_suffix(e), 10, 70), 10, T.TEXT)
	var wx := X + 86.0
	for el in e.weak:
		draw_rect(Rect2(wx, Y + 18, 11, 11), Color(T.INK, 0.9))
		draw_rect(Rect2(wx + 0.5, Y + 18.5, 10, 10), Color(T.WEAK, 0.9), false, 1.0)
		T.element_icon(self, Vector2(wx + 5.5, Y + 23.5), String(el), 4.2)
		wx -= 13.0
	if e.bars.size() > 1:
		T.text(self, Vector2(wx + 10, Y + 28), "×%d" % maxi(e.bars.size() - vbar(e), 1), 8, T.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	_hp_bar(e, Rect2(X + 4, Y + 31, 92, 5))
	_est_overlay(e, Rect2(X + 4, Y + 31, 92, 5), r)
	T.text(self, Vector2(X + 4, Y + 47), TData.fmt_short(vhp(e)), 10, T.TEXT)
	_foe_icons(e, X + 96.0, Y + 37.0, 3 if TData.fmt_short(vhp(e)).length() <= 7 else 2)


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
		var bi := vbar(e)
		for k in n:
			var cx := X + 304.0 - float(n - k) * 11.0
			draw_rect(Rect2(cx, Y + 21, 9, 5), T.GOLD if k >= bi else T.EMPTY)
		T.text(self, Vector2(X + 304.0 - float(n) * 11.0 - 4.0, Y + 28), "줄 %d/%d" % [bi + 1, n], 10, T.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	_hp_bar(e, Rect2(X + 4, Y + 32, 300, 6))
	_est_overlay(e, Rect2(X + 4, Y + 32, 300, 6), r)
	T.text(self, Vector2(X + 4, Y + 48), "%s / %s" % [TData.fmt_short(vhp(e)), TData.fmt_short(vmax(e))], 10, T.TEXT)
	_foe_icons(e, X + 304.0, Y + 39.0, 8)


## 조건 버프가 지금 붙는가 (review_F F06 e, §16.6 FGO 조건 불충족 어둡게): 기준 = 대상 고르기 중이면 고른 적, 아니면 첫 적 ·
## 바퀴에서 고른 칸의 종류(기본 공격 / 공격 마법). 그 아이콘에 묶인 버프 중 하나라도 붙으면 밝게
func _icon_active(w: TUnit, ic: Dictionary) -> bool:
	var foe: TUnit = null
	if state == "target" and not targets.is_empty() and not (targets[tsel] as TActor).unit.is_witch():
		foe = (targets[tsel] as TActor).unit
	elif not battle.alive_of(battle.enemies).is_empty():
		foe = battle.alive_of(battle.enemies)[0]
	var kind := ""
	if actor != null and actor.unit == w and sel >= 0 and sel < slots.size():
		kind = "basic" if String(slots[sel].id) == "basic" else ("skill" if String(slots[sel].kind) == "attack" else "")
	var ik := String(ic.get("cat", "")) + (":" + String(ic.get("mark", "")) if String(ic.get("cat", "")) == "special" else "")
	var any := false
	for b in w.buffs:
		var key := String(b.cat) + (":" + String(b.get("mark", "")) if String(b.cat) == "special" else "")
		if key != ik:
			continue
		any = true
		if _buff_on(w, b, foe, kind):
			return true
	return not any


func _buff_on(w: TUnit, b: Dictionary, foe: TUnit, kind: String) -> bool:
	if String(b.get("mark", "")) != "" and (foe == null or not foe.marks.has(String(b.mark))):
		return false
	if String(b.get("el", "")) != "" and String(b.cat) != "element" and w.attack_element() != String(b.el):
		return false
	if b.has("count") and kind != "":
		var on := String(b.get("on", "attack"))
		if (on == "basic" and kind != "basic") or (on == "skill" and kind != "skill"):
			return false
	return true


## 버프 한 줄이 지금 안 붙는 까닭 (상세 판 꼬리)
func _buff_off_reason(w: TUnit, b: Dictionary) -> String:
	var foes := battle.alive_of(battle.enemies)
	var foe: TUnit = foes[0] if not foes.is_empty() else null
	if String(b.get("mark", "")) != "" and (foe == null or not foe.marks.has(String(b.mark))):
		return "(지금 안 붙음: %s 없는 적)" % TData.MARK_NAME.get(String(b.mark), "")
	if String(b.get("el", "")) != "" and String(b.cat) != "element" and w.attack_element() != String(b.el):
		return "(지금 안 붙음: %s 공격 아님)" % TData.ELEMENT_NAME.get(String(b.el), "")
	return ""


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
		var dim := 1.0 if valive(w) else 0.5
		T.text(self, Vector2(X + 50, Y + 16), w.name, 12, Color(T.GOLD if cur else T.TEXT, dim))
		T.text(self, Vector2(X + 204, Y + 15), T.SLOT_NAME[w.slot], 10, Color(T.TEXT_SUB, dim), HORIZONTAL_ALIGNMENT_RIGHT)
		if not valive(w):
			T.text(self, Vector2(X + 128, Y + 38), "쓰러짐", 12, T.TEXT_OFF, HORIZONTAL_ALIGNMENT_CENTER)
			continue
		# 체력
		var hr := Rect2(X + 50, Y + 21, 100, 5)
		draw_rect(hr.grow(1), Color(T.INK, 0.95))
		var hcol := T.HP_ALLY.lerp(T.HP_LOW, clampf(1.0 - vratio(w) * 2.0, 0.0, 1.0))
		var a: TActor = actors.get(w)
		draw_rect(Rect2(hr.position, Vector2(hr.size.x * (a.shown_hp if a != null else vratio(w)), hr.size.y)), Color(hcol, 0.45))
		draw_rect(Rect2(hr.position, Vector2(hr.size.x * vratio(w), hr.size.y)), hcol)
		T.text(self, Vector2(X + 204, Y + 28), TData.fmt_short(vhp(w)), 10, T.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
		# 크레딧 7칸
		var full := w.credits >= TData.CREDIT_MAX
		var pulse := 0.85 + 0.15 * sin(_t * 5.0) if full else 1.0
		T.credit_row(self, Vector2(X + 54, Y + 36), w.credits, 10.0, 3.5, pulse)
		if full:
			T.text(self, Vector2(X + 124, Y + 40), "대마법", 10, Color(T.GOLD, pulse))
		else:
			T.text(self, Vector2(X + 124, Y + 40), "%d/%d" % [w.credits, TData.CREDIT_MAX], 10, T.TEXT_SUB)
		# 버프 아이콘 (최대 6 + "+n") — 장비 도발·장비 근성도 아이콘으로
		var icons: Array = vicons(w).duplicate()
		if bool(w.equip_data().get("taunt", false)) and not w.has_buff("taunt"):
			icons.append({"cat": "taunt", "dur": -1})
		if float(w.equip_data().get("guts_once", 0.0)) > 0.0 and not w.guts_used:
			icons.append({"cat": "guts", "dur": -1})
		for k in mini(icons.size(), 6):
			T.buff_icon(self, Vector2(X + 50 + 15 * k, Y + 43), icons[k], int(icons[k].get("dur", -1)))
			if not _icon_active(w, icons[k]):
				draw_rect(Rect2(X + 50 + 15 * k, Y + 43, 10, 10), Color(T.INK, 0.6)) # 지금 안 붙는 조건 버프는 어둡게
		if icons.size() > 6:
			T.text(self, Vector2(X + 50 + 15 * 6, Y + 52), "+%d" % (icons.size() - 6), 10, T.TEXT_SUB)
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
			if full:
				var br := 0.6 + 0.4 * (0.5 + 0.5 * sin(_t * 4.0))
				draw_arc(p, r, 0.0, TAU, 32, Color(T.GOLD, br), 2.0)
				draw_arc(p, r + 3.0, 0.0, TAU, 32, Color(T.GOLD, 0.5), 1.0)
				var ph := fmod(_t, 0.8) / 0.8
				draw_arc(p, r + 3.0 + ph * 10.0, 0.0, TAU, 32, Color(T.GOLD, 0.5 * (1.0 - ph)), 1.0)
			else:
				# 모이는 중: 둘레에 진행 호 (크레딧/7, 12시부터 시계 방향) + 배지 "n/7" (review_C2 M3)
				draw_arc(p, r, 0.0, TAU, 32, Color(T.GOLD, 0.25), 2.0)
				var k := clampf(float(u.credits) / float(TData.ULT_COST), 0.0, 1.0)
				if k > 0.0:
					draw_arc(p, r, -PI * 0.5, -PI * 0.5 + TAU * k, 32, T.GOLD, 2.0)
			TIcon.draw(self, p, String(s.icon), Color(T.GOLD if full else ecol, 1.0 if full else 0.45), r * 0.5)
			if not full:
				var lab := "%d/%d" % [u.credits, TData.ULT_COST]
				var bw := T.width(lab, 8) + 6.0
				var bc := p + Vector2(14, 14)
				T.panel(self, Rect2(bc - Vector2(bw * 0.5, 5), Vector2(bw, 10)), Color(T.INK, 0.95), Color(T.GOLD, 0.8), 1, 2)
				T.text(self, bc + Vector2(0, 3), lab, 8, T.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 0)
			var nxt := mini(battle.chain_stage + 1, 3) if (battle.chain_owner != null and battle.chain_stage > 0) else 1
			if nxt >= 2 and full: # 쓸 수 있을 때만 "연쇄 n" (review_G G17)
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
		elif state == "target":
			draw_circle(p, r + 4.0, Color(T.INK, 0.75)) # 대상 고르기 중엔 고른 칸만 또렷이 (다른 칸은 눌리지 않음, H1)
	# 고른 칸 이름 꼬리표: 모든 칸 다음에, 바퀴 중심 → 칸 방향 바깥쪽 (이웃 칸을 덮지 않게, review_C2 M2). 화면 밖이면 생략 (설명 띠 1줄에 이름이 있음)
	if sel >= 0 and sel < slots.size() and not bool(slots[sel].empty):
		var s: Dictionary = slots[sel]
		var p: Vector2 = s.pos
		var dir := (p - c).normalized()
		var at := p + dir * (_slot_r(sel) + 3.0 + 12.0)
		var nm := String(s.name)
		var nw := T.width(nm, 10) + 8.0
		var x0 := at.x - nw * 0.5
		if dir.x < -0.3:
			x0 = at.x - nw
		elif dir.x > 0.3:
			x0 = at.x
		var nr := Rect2(x0, at.y - 7.0, nw, 14)
		if nr.position.x >= 2.0 and nr.end.x <= size.x - 2.0 and nr.position.y >= 32.0:
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
		var right := ""
		var rcol := T.GOLD
		if String(s.kind) == "attack" and est_tgt != null:
			var info := battle.est_info(u, est_tgt, "" if sid == "basic" else sid)
			right = T.est_text(int(info.est), int(info.crit))
			if not bool(info.sure):
				right += " (%d%%)" % int(round(float(info.rate) * 100.0)) # 크리 확률 (review_F F06 b)
		var sr := _success_text(u, sid, est_tgt)
		if sr != "":
			right = sr if right == "" else right + " · " + sr
			if right == sr and (sr == "면역" or sr == "기절 내성"):
				rcol = T.TEXT_OFF
		if right != "":
			T.text(self, Vector2(STRIP.end.x - 8, 318), right, 10, rcol, HORIZONTAL_ALIGNMENT_RIGHT)
		var desc := String(u.data.basic.desc) if sid == "basic" else String(TData.skill(sid).desc)
		var bf := T.body_fs()
		T.text(self, Vector2(X, 334 if bf == 10 else 335), T.clip(desc, bf, 616), bf, T.TEXT)
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
		var info := "대상 %s · 체력 %s" % [t.name + (_dup_suffix(t) if not t.is_witch() else ""), TData.fmt_short(vhp(t))]
		if not t.is_witch() and not t.weak.is_empty():
			var wn: Array = []
			for el in t.weak:
				wn.append(TData.ELEMENT_NAME.get(String(el), ""))
			info += " · 약점 " + ", ".join(wn)
		T.text(self, Vector2(X, 351), info, 10, T.TEXT)
	else:
		T.text(self, Vector2(X, 351), "크레딧", 10, T.TEXT_SUB)
		T.credit_row(self, Vector2(X + 38, 347), u.credits, 9.0, 3.0)
		var own := "%d/%d" % [u.credits, TData.CREDIT_MAX]
		T.text(self, Vector2(X + 38 + 9 * 7, 351), own, 10, T.GOLD if u.credits >= TData.CREDIT_MAX else T.TEXT)
		# 동료 크레딧 짧게 (바퀴가 열려 패널이 가려도 몰아주기·크레딧 주기 판단이 되게, review_C2 M10)
		var mates: Array = []
		for w in battle.witches:
			if w != u and w.alive:
				mates.append("%s ◆%d" % [w.name, w.credits])
		if not mates.is_empty():
			T.text(self, Vector2(X + 38 + 9 * 7 + T.width(own, 10) + 12, 351), " · ".join(mates), 10, T.TEXT_SUB)
	if hint != "":
		T.text(self, Vector2(STRIP.end.x - 8, 351), hint, 10, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_RIGHT)


## 판정이 있는 칸의 성공률 글 (review_F F06 c): 디버프·게이지 감소·게이지 0·차지 감소 → "성공률 70%"(100%면 없음) · 기절 → 보스 "면역" / 기절 내성 중 "기절 내성"
func _success_text(u: TUnit, sid: String, tgt: TUnit) -> String:
	if sid == "basic" or sid == "" or tgt == null or tgt.is_witch():
		return ""
	var s := battle.skill_of(u, sid)
	var worst := 1.0
	var stun := false
	for e in s.get("effects", []):
		var t := String(e.get("t", ""))
		if t in ["debuff", "enemy_gauge", "gauge_zero", "enemy_charge"]:
			worst = minf(worst, battle.success_rate(u, tgt, e))
		elif t == "stun":
			stun = true
	if stun and tgt.stun_immune:
		return "면역"
	if stun and tgt.stun_guard:
		return "기절 내성"
	if worst < 0.999:
		return "성공률 %d%%" % int(round(worst * 100.0))
	return ""


## 대상 표시: 고를 수 있는 대상 위 화살, 지금 고른 대상은 금빛 + 발밑 고리 (카드 테는 _card_frame)
func _draw_targets() -> void:
	for i in targets.size():
		var a: TActor = targets[i]
		var on := i == tsel
		var top := to_screen(a.head()) + Vector2(0, -22 + sin(_t * 6.0) * 2.0)
		if not a.unit.is_witch() and top.y < HEAD_MIN_Y + 2.0:
			# 키 큰 적: 의도 아이콘(y 92 둘레)을 피해 그 오른쪽에서 (카드 테가 금빛으로 같이 알림)
			top = Vector2(top.x + 20.0, HEAD_MIN_Y + 6.0 + sin(_t * 6.0) * 2.0)
		var col := Color(T.GOLD if on else T.TEXT, 1.0 if on else 0.6)
		draw_colored_polygon(PackedVector2Array([top + Vector2(-7, -10), top + Vector2(7, -10), top]), Color(T.INK, 0.9))
		draw_colored_polygon(PackedVector2Array([top + Vector2(-5, -9), top + Vector2(5, -9), top + Vector2(0, -2)]), col)
		var feet := to_screen(a.feet())
		draw_set_transform(feet, 0.0, Vector2(1.0, 0.35))
		draw_arc(Vector2.ZERO, a.half_w() + 8.0, 0.0, TAU, 28, Color(col, 0.9 if on else 0.4), 2.0 if on else 1.0)
		draw_set_transform(Vector2.ZERO)


func _draw_numbers() -> void:
	var wc := _wheel_center() if _wheel_on() and actor != null else Vector2(-999, -999)
	for n: Dictionary in numbers:
		var age := float(n.age)
		if age < 0.0:
			continue
		var kind := String(n.kind)
		var st: Array = NUM_STYLE.get(kind, NUM_STYLE.dmg)
		var fs := _num_fs(n)
		var col: Color = st[1]
		var hits := int(n.get("hits", 1))
		var rise := 18.0 * (1.0 - pow(1.0 - minf(age / 0.5, 1.0), 2.0)) * float(n.dir)
		var a := 1.0 - clampf((age - 0.6) / 0.5, 0.0, 1.0)
		if kind in BODY_KINDS and (n.p as Vector2).distance_to(wc) < WHEEL_R + 24.0:
			a *= 0.35 # 바퀴가 열린 동안 바퀴 위의 지난 숫자는 흐리게 (review_G G08)
		var pop := 1.0 - clampf(minf(age, float(n.get("last", age))) / 0.12, 0.0, 1.0) # 합칠 때마다 다시 툭 커짐
		var q: Vector2 = (n.p as Vector2) + Vector2(0, rise)
		var s := 1.0 + 0.25 * pop
		draw_set_transform(q, 0.0, Vector2(s, s))
		var c := Color(col.lerp(Color.WHITE, pop * 0.6), a)
		if kind == "big" and age < 0.2:
			c = Color(Color.WHITE, a)
		# 테두리 1px 두껍게 + (1, 1) 먹 그림자 — 맞는 연출의 번쩍 위에서도 읽히게 (review_C2 H3)
		var ow := 5 if fs >= 24 else (4 if fs >= 12 else 3)
		T.text(self, Vector2(1, 1), String(n.text), fs, Color(T.INK, 0.8 * a), HORIZONTAL_ALIGNMENT_CENTER, ow)
		T.text(self, Vector2.ZERO, String(n.text), fs, c, HORIZONTAL_ALIGNMENT_CENTER, ow)
		if bool(n.weak):
			T.text(self, Vector2(0, -float(fs) - 1.0), "약점", 10, Color(T.WEAK, a), HORIZONTAL_ALIGNMENT_CENTER)
		if hits > 1: # 오른쪽 위 "n타" 꼬리표
			T.text(self, Vector2(T.width(String(n.text), fs) * 0.5 + 2.0, -float(fs) + 9.0), "%d타" % hits, 10, Color(T.TEXT, a), HORIZONTAL_ALIGNMENT_LEFT, 3)
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
		lines.append(["체력 %s / %s · 크레딧 %d/%d" % [TData.fmt_short(vhp(u)), TData.fmt_short(vmax(u)), u.credits, TData.CREDIT_MAX], T.TEXT, 1])
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
		if u.inv_guard > 0:
			st.append("무적 내성 (적 행동 %d번)" % u.inv_guard)
		if float(eq.get("guts_once", 0.0)) > 0.0:
			st.append("장비 근성 %s" % ("씀" if u.guts_used else "남음"))
		if not st.is_empty():
			lines.append([" · ".join(st), T.STUN, 1])
		for b in u.buffs:
			var off := _buff_off_reason(u, b)
			lines.append([T.buff_line(b) + (" " + off if off != "" else ""), (Color("#d9ccff") if off == "" else T.TEXT_OFF) if not (String(b.cat) in T.BAD_CATS) else T.DANGER, 1 if off == "" else 2])
	else:
		title = u.name + _dup_suffix(u)
		title_col = T.GOLD if u.boss else T.TEXT
		sub = String(TData.TIER_NAME.get(u.tier, ""))
		var bl := " (줄 %d/%d)" % [vbar(u) + 1, u.bars.size()] if u.bars.size() > 1 else ""
		lines.append(["체력 %s / %s%s" % [TData.fmt_short(vhp(u)), TData.fmt_short(vmax(u)), bl], T.TEXT, 1])
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
	# 용어 풀이 한 줄: 이 판에 나온 첫 용어 (review_F F08)
	var all_txt := ""
	for ln: Array in lines:
		all_txt += String(ln[0]) + " "
	var gl := TData.gloss_for(("차지 " if not u.is_witch() and u.charge_max > 0 else "") + all_txt)
	if gl != "":
		lines.append([gl, T.TEXT_OFF, 3])
	var bf := T.body_fs()
	var lh := T.body_lh()
	var dw := DETAIL_W + (48.0 if T.big else 0.0)
	var h := 30.0
	for ln: Array in lines:
		h += lh * float(mini(T.split_lines(String(ln[0]), dw - 16.0, bf).size(), int(ln[2]))) + 1.0
	var dh := DETAIL_H + (60.0 if T.big else 0.0)
	var r := Rect2(16, DETAIL_Y, dw, minf(h, dh)) if not u.is_witch() else Rect2(640.0 - 16.0 - dw, DETAIL_Y, dw, minf(h, dh))
	T.panel(self, r, Color(T.INK, 1.0), Color(T.LINE, 0.8), 1, 4)
	var X := r.position.x + 8.0
	var y := r.position.y + 16.0
	T.text(self, Vector2(X, y), title, 12, title_col)
	T.text(self, Vector2(r.end.x - 8, y), sub, 10, sub_col, HORIZONTAL_ALIGNMENT_RIGHT)
	draw_rect(Rect2(X, y + 5, dw - 16.0, 1), Color(T.LINE, 0.3))
	y += 18.0
	for ln: Array in lines:
		if y > r.end.y - 4.0:
			break
		y += T.wrap(self, Vector2(X, y), String(ln[0]), dw - 16.0, bf, ln[1], lh, int(ln[2])) + 1.0


## left = 남은 시간 (닫히는 배너만): 마지막 0.2초에 높이 84 → 0, 글 알파 1 → 0 (review_D C4: 끝에 툭 사라졌다)
func _draw_banner_box(title: String, sub: String, col: Color, t: float, left := 99.0, full_h := 84.0) -> void:
	var k := clampf(t / 0.35, 0.0, 1.0)
	var e := (1.0 - pow(1.0 - k, 3.0)) * clampf(left / 0.2, 0.0, 1.0)
	col = Color(col, col.a * clampf(left / 0.2, 0.0, 1.0))
	var h := full_h * e
	var cy := 180.0
	draw_rect(Rect2(0, cy - h * 0.5, size.x, h), Color(T.INK, 0.86 * e))
	draw_rect(Rect2(0, cy - h * 0.5, size.x, 1), Color(T.LINE, 0.8 * e))
	draw_rect(Rect2(0, cy + h * 0.5 - 1, size.x, 1), Color(T.LINE, 0.8 * e))
	if k >= 1.0:
		T.text(self, Vector2(size.x * 0.5, cy + 8.0 if full_h <= 84.0 else cy - full_h * 0.5 + 38.0), title, 30, col, HORIZONTAL_ALIGNMENT_CENTER)
		if sub != "":
			T.text(self, Vector2(size.x * 0.5, cy + 30), sub, 10, Color(T.TEXT, 0.9), HORIZONTAL_ALIGNMENT_CENTER)


func _draw_banner() -> void:
	var win := banner_text == "승리"
	var lose := banner_text == "패배"
	_draw_banner_box(banner_text, "" if lose or _banner_t < 0.5 or fmod(_banner_t, 1.0) > 0.75 else banner_sub, T.GOLD if win else T.DANGER, _banner_t, 99.0, LOSE_H if lose else 84.0)
	if lose and _banner_t > 0.35:
		# 진 이유 (review_G G03 · review_F F13): 줄마다 10px
		for i in banner_lines.size():
			var ln: Array = banner_lines[i]
			T.text(self, Vector2(size.x * 0.5, 166 + 13 * i), T.clip(String(ln[0]), 10, 600), 10, ln[1], HORIZONTAL_ALIGNMENT_CENTER)
	if lose and _banner_t > 0.5:
		for b: Array in [[LOSE_RETRY, "다시 도전", lose_main == "retry"], [LOSE_SETUP, "편성으로", lose_main == "setup"]]:
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
