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
const FACE_S := 16 ## 차례 칩 얼굴 (다음 칸 18px 안)
const FACE_L := 22 ## 지금 칸 얼굴 (24px 안)
const ACT_STRIP := Rect2(6, 32, 300, 18) ## 넓은 화면이면 왼쪽 끝으로 (_act_strip)
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
const STRIP := Rect2(4, 302, 632, 56) ## 640 화면의 설명 띠 — 넓은 화면은 _strip_rect가 화면 폭으로
const X_C := Vector2(620, 15) ## 640 화면 자리 — 넓은 화면은 오른쪽 끝에 붙임 (_x_c · review_K K-01)
const X_RECT := Rect2(600, 0, 40, 36) ## 누르는 자리 (그림은 반지름 12 원) — 터치 목표 36 (R3, review_N N-03). 적 카드 위 4px와 겹치는 곳은 X가 먼저
const HELP_C := Vector2(582, 15) ## 도움말 "?" (review_G G05 — X 왼쪽)
const HELP_RECT := Rect2(564, 0, 36, 36) ## 누르는 자리 36×36 (R3 N-03) — X 왼쪽 끝(600)에 붙음, 겹치지 않음
## 바퀴 (검토 O §4 · N-01): 몸 가운데 위쪽 반원(R 78) → 가슴(발 −50)을 중심으로 머리 위에서 적 쪽으로 펼친 부채 (−122° → −4°, R 110).
## 옆 마녀(간격 62·30)는 왼쪽 위·오른쪽 아래에 서므로 그 방향을 비우면 칸이 옆 마녀를 덮지 않는다
## (칸 원판 + 테 2px가 덮는 이웃 마녀 실루엣 픽셀: 기본 파티 3명 합 4,580 → 6, 칸 사이 틈 2.2 → 5.0px — 측정 review_O_art.md §4).
## 왼쪽 위 = 기본 공격 → 오른쪽(적 쪽) = 대마법. 칸 지름 34(대마법 38) · 누름 판정은 r + 6 (지름 46·50 — 터치 목표 36 이상)
const WHEEL_R := 110.0
const WHEEL_OY := -50.0 ## 바퀴 중심 = 발 + (0, −50) (마녀 배율 2 기준 가슴)
const WHEEL_A0 := -122.0 ## 첫 칸(기본 공격) 각도 (도)
const WHEEL_A1 := -4.0 ## 끝 칸(대마법) 각도
const SLOT_R := 17.0
const ULT_R := 19.0
const PORTRAIT_SC := 2.4 ## 아군 패널 초상 배율 (R6 review_P D-5: 1.4 → 2.4)
const PORTRAIT_FEET := Vector2(20, 84) ## 초상 칸(40×48) 안 발 자리 — 칸 밖 아래 (머리~가슴만 보임)
const ICON_K := 0.62 ## 칸 아이콘 반지름 = 칸 반지름 × 이것 (R6 review_P D-1: 0.5 → 0.62 — 일반 10.5 · 대마법 11.8)
const HOLD := 0.4 ## 길게 누르기 (상세)
const HOLD_MS := 400
const CONFIRM := Rect2(220, 135, 200, 90)
const CONFIRM_NO := Rect2(228, 183, 88, 36) ## 터치 목표 36px 이상 (review_C2 M8 · R3 review_N N-03)
const CONFIRM_YES := Rect2(324, 183, 88, 36)
const LOSE_RETRY := Rect2(194, 213, 120, 36) ## 패배 배너가 진 이유 네 줄만큼 높아져 아래로 (review_G G03 · review_I I-02 이유 두 줄)
const LOSE_SETUP := Rect2(326, 213, 120, 36)
const LOSE_H := 150.0
const DETAIL_W := 232.0
const DETAIL_Y := 86.0 ## 상세 판 위 끝 — 적 카드(y 32~82)를 덮지 않게 (review_C2 M7)
const HEAD_MIN_Y := 92.0 ## 적 머리 위 의도·게이지의 가장 위 (적 카드 밑 — review_C2 M1)
const NUM_MIN_Y := 118.0 ## 피해 숫자 시작 y의 가장 위 (18px 떠올라도 "약점" 꼬리표까지 적 카드 밑)
## 차례 줄의 적 글자
## 피해 숫자 종류 → [글꼴 크기, 색]
const NUM_STYLE := {"dmg": [12, Color("#fff3e0")], "crit": [24, Color("#ffe08a")], "weak": [15, Color("#ffb04a")], "big": [24, Color("#fff3e0")],
	"hurt": [15, Color("#ff8a9a")], "heal": [12, Color("#b8f0a0")], "revive": [12, Color("#e6dcff")], "total": [12, Color("#ffe08a")],
	"status": [12, Color("#cfcfe0")], "break": [15, Color("#ffe08a")], "buff": [10, Color("#d9ccff")], "debuff": [10, Color("#c9b8c8")],
	"credit": [10, Color("#ffe08a")], "zero": [10, Color("#ff4f6a")], "mark": [10, Color("#ffb08a")], "block": [10, Color("#c9b8ff")]} # block = 약화 막음 (R5, GAUGE)
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
var _cr_seen := {} ## TUnit → 패널이 마지막으로 본 크레딧 (R6 review_P D-4: 크레딧 변화는 패널에서만)
var _cr_fx := {} ## TUnit → {t, d, lo, hi, tag} 바뀐 칸 번쩍 0.4초 · "+n" 0.8초
var _cr_tag := {} ## TUnit → 다음 크레딧 변화에 붙일 말 ("예약")
var _msg_live := false ## msg가 지금 차례 바퀴가 열린 뒤에 뜬 안내인가 (R6 review_P D-3)
var numbers: Array = [] ## [{p, text, kind, age, dir, weak, key}]
var confirm_open := false ## 철수 확인 판
var battle_name := ""
var _t := 0.0
var _queue: Array = []
var _banner_t := 0.0
var _touch_seen := false
var _keys_seen := false ## 키보드를 쓴 적이 있나 (없으면 안내는 터치 문구 — 폰이 기본)
var _press := {} ## 누르는 중: {pos, t0(ms), f0(프레임), unit, open_f(상세가 열린 프레임)}
var _detail: TUnit = null ## 상세 판에 띄운 유닛
var _flash := {} ## TUnit → 남은 시간 (차례 칸을 눌러 그 유닛을 알려 줌)
var _wave_t := 0.0 ## 웨이브 배너 남은 시간
var _wave_txt := ""
var _wave_len := 1.0 ## 웨이브 배너 길이 (전투 시작 띠는 0.8)
var _wave_sub := ""
var _wave_no := 0 ## 배너로 알린 웨이브 번호 — 위 띠가 배너와 같은 숫자를 바로 보이게 (review_K K-17)
var _wave_flash := 0.0
var ult_t := 0.0 ## 대마법 연출 남은 시간 (연쇄 칩 숨쉬기)
var _back: PanelBack
var _portraits := {} ## TUnit → PortraitBox
var _view := {} ## TUnit → 보이는 값 {hp, max_hp, bar_i, alive, icons, marks} — 행동 연출 중에만 (비면 실제 값)
var banner_lines: Array = [] ## 패배 배너 아래 진 이유 (review_G G03 · review_F F13) [[글, 색]]
var lose_main := "retry" ## 패배 배너의 강조 버튼 (시련 = setup)
var hint_once := "" ## 다음 마녀 차례에 행동 띠에 한 번 띄울 안내 (첫 플레이 B2 뒤 "길게 누르면 자세히")
var last_press := {} ## 마지막 누름 {ms, held, tap, unit, state} — 웹 시험 probe가 읽음 (review_K K-10)
var _faces := {} ## "유닛 id:크기" → SubViewport (차례 칩 얼굴 — 한 번 그려 둠, review_K K-13)
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
	_wave_no = 0
	battle_name = String(TData.BATTLES.get(b.battle_id, {}).get("name", ""))
	_cr_seen.clear()
	_cr_fx.clear()
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
	return vp.get_canvas_transform() * world - T.ofs # 설계 좌표 (넓은 화면 — HUD 층이 ofs만큼 옮겨져 있다)


## 적 n명 웨이브에서 i번째 적이 서는 화면 자리 (0 앞 · 1 중 · 2 뒤): 1명 = 가운데, 2명 = 앞·뒤 (review_C §5.3)
static func pos_index(n: int, i: int) -> int:
	match n:
		1: return 1
		2: return 0 if i == 0 else 2
	return clampi(i, 0, 2)


func _process(delta: float) -> void:
	_t += delta
	size = Vector2(640, 360) # 설계 화면 — 넓은 화면은 층이 T.ofs만큼 옮겨지고 화면 끝까지는 T.screen()·left()·right()로 (review_K K-01)
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
		# 누른 시간은 누름을 받은 순간부터의 실제 시간 (review_K K-10): 예전엔 프레임 delta를 더해서, 누름이 들어온 프레임의 delta
		# (누르기 전 시간)까지 셌다 — 느린 프레임(웹 소프트웨어 렌더·첫 셰이더)에서 120 ms 탭이 0.4초를 넘어 상세가 열리고 탭이 버려졌다
		if Fx.now_ms() - int(_press.t0) >= HOLD_MS and Engine.get_process_frames() - int(_press.f0) >= 2 and _press.get("unit") != null:
			_detail = _press.unit
			_press.open_f = Engine.get_process_frames()
			Sfx.play(&"tn_select", -12.0)
	for n: Dictionary in numbers:
		n.age = float(n.age) + delta
		n.last = float(n.get("last", 0.0)) + delta
	numbers = numbers.filter(func(n: Dictionary) -> bool: return float(n.age) < 1.1)
	_credit_watch(delta)
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
	_msg_live = false
	msg_t = minf(msg_t, 1.2) # 지난 행동 글은 바퀴가 열린 뒤 1.2초만 (띠 아래 작은 줄, R6 D-3)
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
	_msg_live = actor != null and _wheel_on() # 이 차례의 안내인가 (바퀴가 열린 뒤) — 아니면 지난 행동 (R6 D-3)
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
	i = mini(i, n) # 시험 훅과 본 흐름이 겹쳐도 n/n까지 (R3, review_N N-14)
	_wave_txt = "웨이브 %d/%d" % [i, n]
	_wave_sub = ""
	_wave_len = 1.0
	_wave_no = i
	_wave_t = 1.0
	_wave_flash = 1.4


## 전투 시작 띠 (review_K K-29 — 예전엔 행동 띠의 "전투 시작" 작은 글뿐): 웨이브 배너와 같은 띠로 전투 이름 0.8초
func start_banner(title: String, sub := "") -> void:
	_wave_txt = title
	_wave_sub = sub
	_wave_len = 0.8
	_wave_t = 0.8


## 숫자·글 띄우기 (u = 맞은/받은 유닛). kind: dmg · crit · weak · big · hurt · heal · revive · total · status · break · buff · debuff · credit · zero · mark
## weak = 위에 "약점" 꼬리표. value > 0 = 피해 값 — 같은 대상의 다단은 숫자 하나를 이어서 키운다 (review_D A1, PVfx.Numbers와 같은 규칙)
func pop(u: TUnit, text: String, kind := "dmg", weak := false, value := 0) -> void:
	if u == null or not actors.has(u):
		return
	var a: TActor = actors[u]
	var key := "%d:%s" % [u.get_instance_id(), "body" if kind in BODY_KINDS else ("st" if kind in ["status", "break", "block"] else "txt")]
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
		p.x = clampf(p.x, T.left() + hw, T.right() - hw)
	elif kind in ["status", "break", "block"]:
		# 상태 글은 그 몸의 마지막 숫자 칸 위에서 (숫자와 겹치지 않게)
		var last := _last_number(u)
		if last.is_empty() and u.is_witch():
			# 마녀 머리 위 체력·게이지 막대 오른쪽 (review_D B8: 막대 위에 겹쳤다)
			var top := to_screen(a.head()).round()
			p = Vector2(top.x + 24.0 + T.width(text, 12) * 0.5, top.y - 1.0 - 14.0 * float(k % 2))
		elif last.is_empty():
			p = _num_base(a) + Vector2(0, -16 - 14 * (k % 2))
		else:
			p = Vector2((last.p as Vector2).x, (last.p as Vector2).y - float(_num_fs(last)) - 6.0 - 14.0 * float(k % 2))
		if not u.is_witch() and p.y - 12.0 - 18.0 < _head_min():
			# 키 큰 적·보스: 적 카드에 닿으면 머리 옆 바깥(오른쪽)으로 비켜 카드 밑에서 (review_K K-05 — "기절 — 쉼"·"면역"이 카드 위에 찍혔다)
			p = _beside(a, text, 12, k % 2) # 유닛 글은 두 줄까지 (R6 review_P D-4)
			dir = 0.0
	elif not u.is_witch():
		# 적에게 붙은 버프·디버프·징표 글 (review_K K-06): 주인 머리 위 두 줄까지 · 넘치면 "디버프 n"으로 합침 ·
		# 같은 글이 다른 적에게도 곧바로 붙으면(광역) 적마다 쓰지 않고 "적 전체: …" 한 줄로
		if _band(u, text, kind, "band", 2):
			return
		var mine: Array = []
		for n: Dictionary in numbers:
			if String(n.key) == key and float(n.age) < 0.8:
				mine.append(n)
		if mine.size() >= 2:
			var n2: Dictionary = mine[mine.size() - 1]
			n2.merged = int(n2.get("merged", 1)) + 1
			n2.text = "%s %d" % [{"debuff": "디버프", "buff": "버프", "mark": "징표"}.get(kind, "효과") if String(n2.kind) == kind else "효과", int(n2.merged) + 1]
			n2.age = minf(float(n2.age), HOLD_AGE)
			return
		var top := to_screen(a.head()).round()
		p = Vector2(to_screen(a.center()).x, top.y - 4.0 - 13.0 * float(mine.size()))
		dir = 0.0
		if p.y - 12.0 < _head_min():
			p = _beside(a, text, 10, mine.size())
	elif u.is_witch():
		# 같은 글이 마녀 셋 이상에게 곧바로 붙으면(아군 전체 지원) 패널마다 쓰지 않고 "아군 전체: …" 한 줄로 (R6 review_P D-4 — 패널 위가 글로 덮였다)
		if _band(u, text, kind, "aband", 3):
			return
		# 한 패널에 두 줄까지 — 셋째부터는 둘째 줄을 "… 외 n"으로 (R6 D-4: 예전엔 늦춰서 세 줄째를 띄웠다)
		var mine: Array = []
		for n: Dictionary in numbers:
			if String(n.key) == key and float(n.age) < 0.8:
				mine.append(n)
		if mine.size() >= 2:
			var n2: Dictionary = mine[mine.size() - 1]
			n2.merged = int(n2.get("merged", 0)) + 1
			n2.text = "%s 외 %d" % [String(n2.get("base", n2.text)), int(n2.merged)]
			n2.age = minf(float(n2.age), HOLD_AGE)
			return
		p = Vector2(_panel_rect(u.slot).get_center().x, PANEL_Y - 4.0) + Vector2(0, -12.0 * float(mine.size()))
	else:
		pass
	numbers.append({"p": p, "text": text, "base": text, "kind": kind, "age": age, "dir": dir, "weak": weak, "key": key,
		"val": value, "hits": 1, "last": 0.0, "crit": kind == "crit", "foe": not u.is_witch()})
	if numbers.size() > 48:
		numbers.pop_front()


## 적 머리 옆 바깥(오른쪽) 자리 — 적 카드 밑(HEAD_MIN_Y)에서 line줄째. 화면 오른쪽 끝이면 왼쪽으로
func _beside(a: TActor, text: String, fs: int, line: int) -> Vector2:
	var w := T.width(text, fs)
	var c := to_screen(a.center())
	var x := c.x + a.half_w() + 6.0 + w * 0.5
	if x + w * 0.5 > T.right() - 4.0:
		x = c.x - a.half_w() - 6.0 - w * 0.5
	return Vector2(x, _head_min() + 14.0 + 13.0 * float(line))


## 크레딧이 바뀐 마녀를 찾아 패널 번쩍을 건다 (기본 +1 · 마법 · 예약 · 대가 0 · 흩기 모두 — 머리 위·패널 위 글은 띄우지 않음)
func _credit_watch(delta: float) -> void:
	for k in _cr_fx.keys():
		_cr_fx[k].t = float(_cr_fx[k].t) - delta
		if float(_cr_fx[k].t) <= 0.0:
			_cr_fx.erase(k)
	if battle == null:
		return
	for w in battle.witches:
		var c := w.credits
		if _cr_seen.has(w) and int(_cr_seen[w]) != c:
			var was := int(_cr_seen[w])
			var tag := ""
			if _cr_tag.has(w) and _t - float(_cr_tag[w][1]) < 0.5:
				tag = String(_cr_tag[w][0])
			_cr_tag.erase(w)
			_cr_fx[w] = {"t": 0.8, "d": c - was, "lo": mini(was, c), "hi": maxi(was, c), "tag": tag}
		_cr_seen[w] = c


## 크레딧 변화 글에 붙일 말 (예약 발동 "+2 예약"): 막 바뀌었으면 그 글에, 아니면 0.5초 안의 다음 변화에
func credit_tag(u: TUnit, tag: String) -> void:
	if _cr_fx.has(u) and float(_cr_fx[u].t) > 0.4:
		_cr_fx[u].tag = tag
	else:
		_cr_tag[u] = [tag, _t]


## 패널 크레딧 줄: 바뀐 칸만 0.4초 번쩍 (늘면 흰 금 · 줄면 붉게) — T.credit_row의 flash 인자 [lo, hi, 색, 반지름] (없으면 [])
func _credit_flash(w: TUnit, half: float) -> Array:
	if not _cr_fx.has(w):
		return []
	var f: Dictionary = _cr_fx[w]
	var age := 0.8 - float(f.t)
	if age >= 0.4:
		return []
	var k := 1.0 - age / 0.4
	return [int(f.lo), int(f.hi), Color(Color("#fff6d6") if int(f.d) > 0 else T.DANGER, 0.85 * k), half + 2.0 * k]


## 패널 "n/7" 오른쪽 "+n"(금) · "−n"(붉게) 0.8초 — 예약 발동이면 "+2 예약"
func _credit_label(w: TUnit, tx: float, y: float) -> void:
	if not _cr_fx.has(w):
		return
	var f: Dictionary = _cr_fx[w]
	var up := int(f.d) > 0
	var lab := ("+%d" % int(f.d) if up else "−%d" % -int(f.d)) + (" " + String(f.tag) if String(f.tag) != "" else "")
	# "n/7"과 같은 12px · 테두리 없이 (같은 글꼴·같은 글자 그림이라 "n/7" 글과 한 묶음 — 검토 P의 9px·테두리는 그리기 호출 +2~3)
	T.text(self, Vector2(tx + 4.0, y), lab, 12, Color(T.GOLD if up else Color("#ff8a9a"), minf(float(f.t) / 0.25, 1.0)), HORIZONTAL_ALIGNMENT_LEFT, 0)


## 광역 글 합치기: 같은 글이 0.25초 안에 다른 유닛(같은 편)에게 떴고 이것으로 need명째면 그 글들을 지우고 한 줄 띠에 모은다. 모았으면 true
## bkey "band" = 적 (적 카드 바로 밑 "적 전체: …", review_K K-06 — 둘부터) · "aband" = 아군 (필드 가운데 위 (320, 96) "아군 전체: …", R6 review_P D-4 — 셋부터)
func _band(u: TUnit, text: String, kind: String, bkey: String, need: int) -> bool:
	var band: Dictionary = {}
	for n: Dictionary in numbers:
		if String(n.key) == bkey and float(n.age) < 0.4:
			band = n
	if not band.is_empty() and (band.parts as Array).has(text):
		return true
	var others: Array = []
	var me := "%d:txt" % u.get_instance_id()
	for n: Dictionary in numbers:
		if String(n.get("base", n.text)) == text and String(n.key).ends_with(":txt") and String(n.key) != me and float(n.age) < 0.25 and bool(n.get("foe", false)) != u.is_witch():
			others.append(n)
	if others.size() + 1 < need:
		return false
	for n: Dictionary in others:
		numbers.erase(n)
	if band.is_empty():
		var at := Vector2(320, 96)
		if bkey == "band":
			var xs := 0.0
			var cnt := 0
			for e in battle.alive_of(battle.enemies):
				if actors.has(e):
					xs += to_screen((actors[e] as TActor).center()).x
					cnt += 1
			at = Vector2(xs / float(maxi(cnt, 1)), _head_min() + 1.0) # 적 카드 바로 밑 줄 (피해 숫자는 그 아래 — 겹치지 않게)
		band = {"p": at, "text": "", "kind": kind, "age": 0.0, "dir": 0.0, "weak": false, "key": bkey,
			"val": 0, "hits": 1, "last": 0.0, "crit": false, "parts": [], "foe": bkey == "band"}
		numbers.append(band)
	(band.parts as Array).append(text)
	band.text = ("적 전체: " if bkey == "band" else "아군 전체: ") + " · ".join(band.parts)
	band.base = band.text
	band.age = minf(float(band.age), HOLD_AGE)
	return true


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
	return Vector2(to_screen(a.center()).x + 6.0, maxf(top.y + 14.0, _num_min()))


## 살아 있는 다른 숫자 칸과 겹치면 글자 높이 + 2px씩 위로 (위가 막히면 처음부터 아래로) 최대 STACK_MAX칸, 넘치면 가로로 비킴
## (review_D A2 — PVfx.Numbers의 STACK 규칙. 예전 14px 위·아래 번갈이는 NUM_MIN_Y 근처에서 제자리걸음을 했다)
func _avoid_numbers(p: Vector2, text: String, fs: int) -> Vector2:
	var w := T.width(text, fs) + 8.0 # 다단으로 커지는 몫
	var step := float(fs) + 2.0
	var dy := -step if p.y - step * float(STACK_MAX) >= _num_min() else step
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
		"max_hp": # 최대 체력 (R5): 최대·지금 체력 + 더한 값
			v.max_hp = int(v.max_hp) + int(e.v)
			v.hp = int(v.hp) + int(e.v)
			v.icons = u.buff_icons()
		"dispel", "cleanse": # 지운 버프가 최대 체력이면 최대가 되돌아감 (R5)
			v.hp = u.hp
			v.max_hp = u.max_hp
			v.icons = u.buff_icons()
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
			_press_down(event.position - T.ofs) # 설계 좌표로 (넓은 화면 — 층이 ofs만큼 옮겨져 있다)
		else:
			_press_up()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION:
			if event.pressed:
				_press_down(event.position - T.ofs)
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
	if x_rect().has_point(p):
		_ask_exit()
		return
	if _help_rect().has_point(p) and state != "banner":
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
	_press = {"pos": p, "t0": Fx.now_ms(), "f0": Engine.get_process_frames(), "unit": _unit_at(p), "open_f": -1}


func _press_up() -> void:
	if _press.is_empty():
		return
	var u: TUnit = _press.get("unit")
	var held := _detail != null
	# 상세가 바로 앞 프레임에 막 열렸으면(사람이 판을 본 적 없음) 탭으로 — 웹은 입력을 프레임마다 모아 주어 느린 프레임이면 뗌이 한두 프레임 늦게 온다
	var tap := not held or Engine.get_process_frames() - int(_press.open_f) <= 1
	last_press = {"ms": Fx.now_ms() - int(_press.t0), "held": held, "tap": tap, "unit": u.name if u != null else "", "state": state}
	_press = {}
	_detail = null
	if tap:
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


## 나가기 X 누를 자리 · 도움말 ? — 넓은 화면이면 오른쪽 끝에 붙인다 (review_K K-01, FGO §21.2 와이드 배치)
func x_rect() -> Rect2:
	return Rect2(X_RECT.position + Vector2(T.ofs.x, 0), X_RECT.size)


func _help_rect() -> Rect2:
	return Rect2(HELP_RECT.position + Vector2(T.ofs.x, 0), HELP_RECT.size)


func _x_c() -> Vector2:
	return X_C + Vector2(T.ofs.x, 0)


func _help_c() -> Vector2:
	return HELP_C + Vector2(T.ofs.x, 0)


## 행동 띠 · 설명 띠 (넓은 화면: 왼쪽 끝 · 화면 폭)
func _act_strip() -> Rect2:
	return Rect2(ACT_STRIP.position + Vector2(-T.ofs.x, 0), ACT_STRIP.size)


func _strip_rect() -> Rect2:
	return Rect2(T.left() + 4.0, STRIP.position.y, T.view.x - 8.0, STRIP.size.y)


func _confirm_yes() -> void:
	confirm_open = false
	Sfx.play(&"tn_confirm", -8.0)
	exit_tapped.emit()


func _confirm_no() -> void:
	confirm_open = false
	Sfx.play(&"tn_cancel", -10.0)


## 마녀성 필드 전투인가 (TStage.field) — 패배·철수 글을 "물러나기"로
func _field() -> bool:
	return stage != null and bool(stage.get("field"))


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
		if _queue_hit(i).has_point(p):
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
		var ang := deg_to_rad(lerpf(WHEEL_A0, WHEEL_A1, float(i) / float(n - 1)))
		var pos := c + Vector2(cos(ang), sin(ang)) * WHEEL_R
		var sid: String = ids[i]
		if sid == "basic":
			slots.append({"id": "basic", "name": String(u.data.basic.get("name", "기본 공격")), "cost": 0, "can": true, "pos": pos, "kind": "attack", "target": "enemy", "icon": "strike", "empty": false, "ult": false})
		elif sid == "":
			slots.append({"id": "", "name": "", "cost": 0, "can": false, "pos": pos, "kind": "", "target": "", "icon": "", "empty": true, "ult": i == n - 1})
		else:
			var s := TData.skill(sid)
			var cn := TBattle.cost_now(u, sid) # 비용 감소 반영 (R5)
			slots.append({"id": sid, "name": String(s.name), "cost": cn, "base_cost": int(s.cost), "can": battle.can_use(u, sid), "pos": pos, "kind": String(s.kind), "target": String(s.target),
				"icon": String(s.get("icon", "strike")), "empty": false, "ult": bool(s.get("ultimate", false)), "sealed": battle.sealed_out(u, sid)})


func _wheel_center() -> Vector2:
	return to_screen(actor.feet()) + Vector2(0, WHEEL_OY)


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
		if bool(s.get("sealed", false)):
			show_msg("봉인 — 이번 차례는 기본 공격만" if actor.unit.sealed == 1 else "봉인 — 이번 차례는 대마법을 못 씀", T.DANGER)
		else:
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
		var us: Array[TUnit] = battle.foe_targets() if String(s.id) == "basic" else battle.valid_targets(u, String(s.id)) # 막아서는 적이 있으면 그 적만 (단계 F-2)
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


## 아군 패널 자리 (지금 차례로 올리기 전): 화면 폭을 셋으로 — 640이면 4 + 212k · 폭 208 (넓은 화면은 패널이 넓어짐, review_K K-01)
static func panel_at(slot: int) -> Rect2:
	var step := (T.view.x - 4.0) / 3.0
	return Rect2(T.left() + PANEL_X0 + step * float(2 - slot), PANEL_Y, step - 4.0, PANEL_H)


## 아군 패널 자리: 왼→오 = 뒤·중·앞 (전장 그림 순서와 같게, review_C2 M6 [제안])
func _panel_rect(slot: int) -> Rect2:
	var r := panel_at(slot)
	if battle != null and battle.actor != null and battle.actor.is_witch() and battle.actor.slot == slot:
		r.position.y -= 4.0 # 지금 차례 패널은 4px 올림
	return r


func _boss_card_on() -> bool:
	return battle != null and battle.enemies.size() == 1 and battle.enemies[0].boss


## 보스와 졸개가 같은 웨이브 (잿빛 둥지어미): 보스는 넓은 보스 카드(204), 졸개는 그 오른쪽 반 높이 카드 두 장 (review_K K-08)
static func boss_mix(es: Array) -> bool:
	if es.size() < 2:
		return false
	for e: TUnit in es:
		if e.boss:
			return true
	return false


## 졸개 차례 번호 (보스를 뺀 순서)
static func minion_index(es: Array, i: int) -> int:
	var j := 0
	for k in i:
		if not (es[k] as TUnit).boss:
			j += 1
	return j


func _card_rect(u: TUnit) -> Rect2:
	if battle == null:
		return Rect2()
	if _boss_card_on():
		return Rect2(BOSS_CARD.position, Vector2(BOSS_CARD.size.x, _card_h()))
	if boss_mix(battle.enemies):
		if u.boss:
			return Rect2(CARD_X0, CARD_Y, CARD_W * 2.0 + CARD_STEP - CARD_W, _card_h())
		var j := minion_index(battle.enemies, battle.enemies.find(u))
		return Rect2(CARD_X0 + CARD_STEP * 2.0, CARD_Y + 26.0 * float(mini(j, 1)), CARD_W, 24.0)
	var i := pos_index(battle.enemies.size(), battle.enemies.find(u))
	return Rect2(CARD_X0 + CARD_STEP * float(i), CARD_Y, CARD_W, _card_h())


## 차례 칸: 왼쪽에 "지금" 꼬리표 자리(22px)를 두고 지금(24) → 다음 7(18) (review_G G19)
func _queue_rect(i: int) -> Rect2:
	var x0 := T.left() # 넓은 화면: 화면 왼쪽 끝에 붙임 (review_K K-01)
	if i == 0:
		return Rect2(x0 + 26, 3, 24, 24)
	return Rect2(x0 + 56 + 21 * (i - 1), 6, 18, 18)


## 적 카드 높이 · 머리 위 표시와 피해 숫자의 가장 위 — 큰 글자면 8px 더 (R3, review_N N-04: 12px 의도 알약의 아래 테가 이름 줄을 지나고 체력 숫자가 차지 칸을 덮었다)
func _card_h() -> float:
	return CARD_H + (8.0 if T.big else 0.0)


func _head_min() -> float:
	return HEAD_MIN_Y + (8.0 if T.big else 0.0)


func _num_min() -> float:
	return NUM_MIN_Y + (8.0 if T.big else 0.0)


## 차례 칸을 누르는 자리: 칸 간격(21)을 다 쓰고 위 띠 높이(0~31)까지 — 다음 칸 18px가 손가락보다 작았다 (R3, review_N N-15). 옆 칸과 겹치지 않음
func _queue_hit(i: int) -> Rect2:
	var r := _queue_rect(i)
	if i == 0:
		return Rect2(r.position.x - 2.0, 0, r.size.x + 4.0, 31)
	return Rect2(r.position.x - 1.5, 0, 21, 31)


## 위 띠의 연쇄 칩 자리 (안내 D5 강조) — _draw_top과 같은 셈
func chain_rect() -> Rect2:
	var wl := _top_label()
	var cx := _wave_x() - _top_w(wl) - 8.0
	if battle.chain_stage <= 0:
		return Rect2(cx - 120, 6, 120, 19)
	var lab := TData.chain_label(battle.chain_stage)
	var px := _chain_px(cx, lab)
	var w := (T.width_px(lab, 10) if px else T.width(lab, 10)) + 10.0
	var h := _chain_h(px)
	return Rect2(cx - w - 2.0, 15.5 - h * 0.5 - 2.0, w + 4.0, h + 4.0)


## 연쇄 칩 높이 = 글자 높이 + 5 (큰 글자에서 글이 테에 붙던 것, R2 — review_L §4.3)
func _chain_h(px := false) -> float:
	return (10.0 if px else float(T.eff(10))) + 5.0


## 큰 글자에서 칩이 차례 줄 끝(+4)에 닿으면 칩 글만 10px 그대로 (R2 — 웨이브 글이 길면 왼쪽으로 밀려 "다음 →"에 닿았다)
func _chain_px(cx: float, lab: String) -> bool:
	return T.big and cx - T.width(lab, 10) - 10.0 < _queue_rect(QUEUE_N - 1).end.x + 4.0


## 위 띠 오른쪽 글: 웨이브 n/m (한 웨이브면 전투 이름). 연쇄 칩은 그 앞 "차례 n · "까지 비켜 선다
func _top_label() -> String:
	if battle.wave_count() > 1:
		return "웨이브 %d/%d" % [mini(maxi(battle.wave_i + 1, _wave_no), battle.wave_count()), battle.wave_count()] # 시험 훅 demo_wave가 본 흐름과 겹쳐도 n/n 넘지 않게 (R3, review_N N-14)
	return battle_name


func _top_w(wl: String) -> float:
	return T.width(wl, 10) + T.width("차례 %d · " % maxi(battle.turn_no, 1), 10)


## 위 띠 웨이브 글의 오른쪽 끝 (? 왼쪽 — 넓은 화면은 오른쪽 끝에 붙임)
func _wave_x() -> float:
	return 562.0 + T.ofs.x


## 차례 줄 전체 (안내 B5 강조)
func queue_box() -> Rect2:
	return Rect2(T.left() + 2.0, 1, _queue_rect(QUEUE_N - 1).end.x + 30.0 - T.left(), 28)


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
		# 머리~가슴 흉상 (R6 review_P D-5): 1.4배 전신이라 얼굴이 6px였다 → 2.4배, 발을 칸 밖 (20, 96)에 — 얼굴(발 위 약 30)이 칸 y 24 근처, 모자 끝은 잘림
		a.setup(w, PORTRAIT_FEET)
		a.scale = Vector2(PORTRAIT_SC, PORTRAIT_SC)
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
		if bw >= 2:
			T.panel(ci, r, fill, border, bw, 3)
		else:
			T.panel_lit(ci, r, fill, border) # 입체 테 (R4 N-10) — 금테 2px는 그대로


class PanelBack extends Control:
	var hud: THud

	func _draw() -> void:
		hud._draw_panel_backs(self)


class PortraitBox extends Control:
	const T := preload("res://proto/turn/t_theme.gd")
	var col := Color.WHITE

	## 바탕: 먹 + 속성 색 방사(얼굴 자리 0.25 → 가장자리 0) — 단색 바탕이었다 (R6 review_P §5 ④)
	func _draw() -> void:
		# 바탕 사각 + 방사 + 아래 띠를 삼각형 묶음 하나로 (그리기 호출 1 — 예전 사각 둘과 같은 수)
		var ink := Color(T.INK, 0.9)
		var base := ink.lerp(col, 0.1)
		var pts := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), Vector2(size.x, size.y), Vector2(0, size.y),
			Vector2(0, size.y - 10), Vector2(size.x, size.y - 10)])
		var cols := PackedColorArray([ink, ink, base, base, ink.lerp(col, 0.08), ink.lerp(col, 0.08)])
		var idx := PackedInt32Array([0, 1, 5, 0, 5, 4, 4, 5, 2, 4, 2, 3])
		var c := Vector2(size.x * 0.5, 22.0)
		var n := 20
		var o := pts.size()
		pts.append(c)
		cols.append(Color(col, 0.25))
		for i in n:
			pts.append(c + Vector2.from_angle(TAU * float(i) / float(n)) * Vector2(30.0, 34.0))
			cols.append(Color(col, 0.0))
			idx.append_array(PackedInt32Array([o, o + 1 + i, o + 1 + (i + 1) % n]))
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, pts, cols)


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
		_draw_banner_box(_wave_txt, _wave_sub, T.TEXT, _wave_len - _wave_t, _wave_t)
	if state == "banner":
		_draw_banner()
	if confirm_open:
		_draw_confirm()


## 위 띠: 바탕 · 차례 줄 · 전투 이름/웨이브 · 연쇄 · X
func _draw_top() -> void:
	draw_rect(Rect2(T.left(), 0, T.view.x, 30), Color(T.INK, 0.55))
	draw_rect(Rect2(T.left(), 30, T.view.x, 1), Color(T.LINE, 0.3))
	if state != "banner" and _wave_t <= 0.0: # 승패 배너·웨이브 배너 동안 차례 줄 숨김 (review_G G20 · review_K K-17 — 앞 웨이브 줄이 남았다)
		_draw_queue()
	var wl := _top_label()
	var wcol := T.GOLD if _wave_flash > 0.0 and _wave_flash < 0.4 else T.TEXT
	T.text(self, Vector2(_wave_x(), 20), wl, 10, wcol, HORIZONTAL_ALIGNMENT_RIGHT)
	# 차례 수 (review_K K-23 — FGO §21.3 TURN): 웨이브 글 앞 흐린 글
	T.text(self, Vector2(_wave_x() - T.width(wl, 10), 20), "차례 %d · " % maxi(battle.turn_no, 1), 10, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_RIGHT)
	# 대마법 연쇄 진행 중 (§13.6) — 효과를 같이 (review_G G17)
	if battle.chain_owner != null and battle.chain_stage > 0 and state != "banner" and _wave_t <= 0.0: # 승패·웨이브 배너가 열리면 숨김 (L5 · K-17)
		var cx := _wave_x() - _top_w(wl) - 8.0
		var lab := TData.chain_label(battle.chain_stage)
		var px := _chain_px(cx, lab)
		var w := (T.width_px(lab, 10) if px else T.width(lab, 10)) + 10.0
		var br := 0.5 + 0.5 * sin(_t * TAU / 0.6) if ult_t > 0.0 else 0.0 # 대마법 동안 0.6초 주기로 숨쉼
		var ch := _chain_h(px)
		var cy := 15.5 - ch * 0.5
		if br > 0.0:
			draw_rect(Rect2(cx - w - 2.0, cy - 2.0, w + 4.0, ch + 4.0), Color(T.GOLD, 0.25 * br))
		T.panel(self, Rect2(cx - w, cy, w, ch), Color(T.INK, 0.9).lerp(Color(T.GOLD, 0.9), 0.25 * br), Color(T.GOLD, 0.8 + 0.2 * br), 1, 3)
		if px:
			T.text_px(self, Vector2(cx - w * 0.5, cy + ch - 3.0), lab, 10, T.GOLD.lerp(Color.WHITE, 0.5 * br), HORIZONTAL_ALIGNMENT_CENTER)
		else:
			T.text(self, Vector2(cx - w * 0.5, cy + ch - 3.0), lab, 10, T.GOLD.lerp(Color.WHITE, 0.5 * br), HORIZONTAL_ALIGNMENT_CENTER)
	# 도움말 ?
	var hc := _help_c()
	draw_circle(hc, 12.0, Color(T.INK, 0.6))
	draw_arc(hc, 12.0, 0.0, TAU, 24, Color(T.LINE, 0.6), 1.0)
	T.text(self, hc + Vector2(0, 5), "?", 12, T.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	# 나가기 X
	var xc := _x_c()
	draw_circle(xc, 12.0, Color(T.INK, 0.6))
	draw_arc(xc, 12.0, 0.0, TAU, 24, Color(T.LINE, 0.6), 1.0)
	draw_line(xc + Vector2(-4, -4), xc + Vector2(4, 4), Color(T.TEXT, 0.85), 1.6)
	draw_line(xc + Vector2(-4, 4), xc + Vector2(4, -4), Color(T.TEXT, 0.85), 1.6)


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
	var x0 := T.left()
	T.text(self, Vector2(x0 + 14, 13), "지금", 8, T.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 0)
	draw_colored_polygon(PackedVector2Array([Vector2(x0 + 19, 17), Vector2(x0 + 23, 20), Vector2(x0 + 19, 23)]), Color(T.GOLD, 0.8))
	var last := _queue_rect(QUEUE_N - 1)
	if not after.is_empty():
		# "사용 뒤" 줄: 다음 칸들을 금빛 테로 감싸 지금 줄과 다른 상태임을 보임 (review_K K-13 — 예전엔 8px 글 하나)
		var fr := Rect2(_queue_rect(1).position - Vector2(3, 3), last.end - _queue_rect(1).position + Vector2(6, 6))
		draw_rect(fr, Color(T.GOLD, 0.12))
		draw_rect(fr, T.GOLD, false, 1.0)
		T.text(self, Vector2(last.end.x + 6, 18), "사용 뒤", 10, T.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	for i in q.size():
		var u: TUnit = q[i]
		var r := _queue_rect(i)
		var witch := u.is_witch()
		var fill: Color = Color(TData.ELEMENT_COLOR.get(u.element, T.LINE), 0.5) if witch else Color(T.PANEL, 0.95)
		var border := T.GOLD if i == 0 else (Color(TData.ELEMENT_COLOR.get(u.element, T.LINE), 0.9) if witch else (T.GOLD if u.boss else T.DANGER))
		var fm: Dictionary = fin.get(i, {})
		T.panel(self, r, fill, T.DANGER if not fm.is_empty() and i > 0 else border, 2 if (i == 0 or not fm.is_empty()) else 1, 4 if i == 0 else 3)
		# 얼굴 (한 글자 칩은 처음 보는 사람이 못 읽었다 — review_K K-13): 마녀 = 모자·얼굴, 적 = 몸 전체 축소
		var fp := FACE_L if i == 0 else FACE_S
		var fr := Rect2(r.get_center() - Vector2(fp, fp) * 0.5, Vector2(fp, fp))
		draw_texture_rect(_face(u, fp), fr, false, Color(1, 1, 1, 0.45) if u.stunned else Color.WHITE)
		var dup := _dup_suffix(u).strip_edges() if not witch else ""
		if dup != "": # 같은 적이 둘 이상일 때만 카드와 같은 A·B 배지 (L3)
			var b := r.end - Vector2(2, 2)
			draw_rect(Rect2(b - Vector2(4, 4), Vector2(8, 8)), Color(T.INK, 0.95))
			T.text_px(self, b + Vector2(0, 4), dup, 8, T.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 0)
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


## 차례 칩 얼굴: 유닛 그림(TActor)을 px×px에 한 번 찍은 텍스처 (TActor.Snap — 같은 종류는 같은 얼굴, A·B 배지로 가름)
## 마녀 = 키의 위 60%(모자·얼굴·어깨) · 적 = 몸 전체
func _face(u: TUnit, px: int) -> Texture2D:
	var key := "%s:%d" % [u.id, px]
	if not _faces.has(key):
		var probe := TActor.new() # 키를 재는 그림 (배율 1)
		probe.deco = false
		add_child(probe)
		probe.setup(u, Vector2.ZERO)
		var base := probe.scale.x
		var h := maxf(probe.feet().y - probe.head().y, 1.0) / base
		var cx := (probe.center().x - probe.feet().x) / base
		probe.free()
		var k := (float(px) / 0.6 if u.is_witch() else float(px) - 2.0) / h
		var top := (1.0 if not u.is_witch() else -float(px) * 0.12)
		_faces[key] = TActor.Snap.make(self, u, Vector2i(px, px), k, Vector2(float(px) * 0.5 - cx * k, top + h * k))
	return (_faces[key] as SubViewport).get_texture()


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
	if _wheel_on() and actor != null:
		# 바퀴가 열려 있으면 띠는 늘 "{마녀}의 차례 — …" (R6 review_P D-3: 지난 적 행동 "늪 두꺼비 — 공격"이 남아 차례와 엇갈렸다).
		# 이 차례에 뜬 안내(크레딧 모자람·봉인·길게 누르기)는 "—" 뒤에, 바퀴가 열리기 전의 지난 행동은 띠 아래 작은 글 한 줄로 1.2초만
		var touch := _touch_seen or not _keys_seen
		var tail := ""
		var tcol := T.TEXT
		if msg_t > 0.0 and msg != "" and _msg_live:
			tail = msg
			tcol = msg_col if msg_col in [T.DANGER, T.GOLD] else T.TEXT
		elif _ally_pick() and sel >= 0 and sel < slots.size():
			tail = "%s → %s" % [String(slots[sel].name), "패널이나 마녀를 누르세요" if touch else "←→ 대상 · Z 확인"]
		elif state == "target":
			tail = "적을 눌러 대상 고르기" if touch else "←→ 대상 · Z 확인"
		elif sel >= 0:
			tail = "한 번 더 누르면 사용" if touch else "Z 사용 · X 뒤로"
		else:
			tail = "칸을 눌러 마법 고르기" if touch else "←→ 고르기 · Z 확인"
		var head := "%s의 차례 — " % actor.unit.name
		var tw := minf(T.width(tail, 12), 280.0 - T.width(head, 12))
		var hw := minf(T.width(head, 12) + tw + 22.0, 300.0)
		var hr := Rect2(_act_strip().position, Vector2(hw, ACT_STRIP.size.y))
		draw_rect(hr, Color(T.INK, 0.85))
		draw_rect(Rect2(hr.position, Vector2(2, hr.size.y)), TData.ELEMENT_COLOR.get(actor.unit.element, T.GOLD))
		if tcol == T.TEXT:
			T.text(self, hr.position + Vector2(10, 14), head + T.clip(tail, 12, tw), 12, T.TEXT) # 한 번에 (그리기 호출 — 글 둘이면 테·글이 번갈아 묶음이 갈림)
		else:
			T.text(self, hr.position + Vector2(10, 14), head, 12, T.TEXT)
			T.text(self, hr.position + Vector2(10 + T.width(head, 12), 14), T.clip(tail, 12, tw), 12, tcol)
		if msg_t > 0.0 and msg != "" and not _msg_live:
			var past := T.clip(msg, 8, 280)
			var pr := Rect2(hr.position + Vector2(6, ACT_STRIP.size.y + 2), Vector2(T.width(past, 8) + 4.0, float(T.eff(8)) + 2.0))
			var hit := false
			for i in slots.size(): # 뒤 마녀의 위쪽 칸을 덮으면 그리지 않음 (지난 행동은 그 행동 동안 이미 띠에 1.6초 떴다)
				if not bool(slots[i].empty) and pr.intersects(slot_rect(i)):
					hit = true
			if not hit:
				T.text(self, pr.position + Vector2(2, float(T.eff(8))), past, 8, Color(T.TEXT_SUB, 0.7 * minf(msg_t / 0.3, 1.0)))
		return
	if msg_t <= 0.0 or msg == "":
		return
	var a := minf(msg_t / 0.4, 1.0)
	var tot := (" · " + msg_total) if msg_total != "" else ""
	var mw := minf(T.width(msg, 12), 280.0 - (T.width(tot, 12) if tot != "" else 0.0))
	var w := minf(mw + T.width(tot, 12) + 22.0, 300.0)
	var r := Rect2(_act_strip().position, Vector2(w, ACT_STRIP.size.y))
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
		# 머리 위 막대·의도는 대상 고르기의 후보에게만 — 평소엔 카드·패널에 같은 것이 있어 화면 위 1/3이 붐볐다 (review_K K-14).
		# 기절 별·도발 방패 같은 상태 표식은 그대로
		var bars := state == "target" and targets.has(a)
		if not bars:
			if unit.is_witch() and unit.is_taunting():
				T.buff_icon(self, Vector2(top.x + 23, top.y - 11), {"cat": "taunt"})
			if unit.stunned:
				if not unit.is_witch():
					top.y = maxf(top.y, _head_min() + 15.0)
				for k in 3:
					var ang := _t * TAU / 0.8 + float(k) * TAU / 3.0
					T.star(self, Vector2(top.x, top.y - 28) + Vector2(cos(ang) * 8.0, sin(ang) * 3.0), 2.8, T.STUN)
			continue
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
			top.y = maxf(top.y, _head_min() + 15.0)
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
	var mix := boss_mix(battle.enemies)
	for e in battle.enemies:
		if not valive(e):
			continue
		if _boss_card_on() or (mix and e.boss):
			_draw_boss_card(e)
		elif mix:
			_draw_minion_card(e)
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
	if bw >= 2:
		T.panel(self, r, fill, border, bw, 3)
	else:
		T.panel_lit(self, r, fill, border) # 입체 테 (R4 N-10)


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
	var boom := bool(it.get("self_ko", false)) and not e.stunned # 자폭 필살기: 알약 끝 작은 폭발 (review_H §2.2)
	if k == "dispel":
		var nb := 0
		for wt in battle.alive_of(battle.witches):
			nb += wt.good_buffs()
		name += " · 버프 %d" % nb # 지워질 버프 수 (review_G G15) — 적이 건 나쁜 효과는 안 지워짐
	var w := T.width(name, 10) + 18.0 + (12.0 if pierce or boom else 0.0)
	var pulse := 1.0
	if k in ["heavy", "finisher"]:
		pulse = 0.6 + 0.4 * (0.5 + 0.5 * sin(_t * 5.0))
	var ph := 15.0 if T.big else 13.0 # 큰 글자면 알약 글 12px (review_I I-10)
	var r := Rect2(p, Vector2(w, ph))
	if k == "finisher":
		# 필살기는 빨간 바탕 + 밝은 글로 모양을 가름 — 강공격(빨간 테)과 색이 가깝다 (review_I I-23, 제1색약 ΔE 12.0)
		T.panel(self, r, Color(col, 0.55 + 0.35 * pulse), Color(T.TEXT, 0.9), 1, 2)
		T.intent_icon(self, p + Vector2(8, ph * 0.5), k, T.TEXT)
		T.text(self, p + Vector2(15, ph - 2.0), name, 10, T.TEXT)
	else:
		T.panel(self, r, Color(T.INK, 0.95), Color(col, pulse), 1, 2)
		T.intent_icon(self, p + Vector2(8, ph * 0.5), k, Color(col, pulse))
		T.text(self, p + Vector2(15, ph - 2.0), name, 10, col)
	if pierce:
		var c := p + Vector2(w - 7, 6.5)
		draw_line(c + Vector2(-4, 0), c + Vector2(4, 0), T.DANGER, 1.4)
		draw_line(c + Vector2(1, -3), c + Vector2(4, 0), T.DANGER, 1.4)
		draw_line(c + Vector2(1, 3), c + Vector2(4, 0), T.DANGER, 1.4)
		draw_line(c + Vector2(-1, -4), c + Vector2(-1, 4), Color(T.TEXT, 0.7), 1.0)
	if boom:
		var c := p + Vector2(w - 7, 6.5)
		draw_circle(c, 1.4, Color(T.GOLD, pulse))
		for k2 in 4:
			var d := Vector2.from_angle(PI * 0.25 + float(k2) * PI * 0.5)
			draw_line(c + d * 2.4, c + d * 4.4, Color(T.DANGER, pulse), 1.2)
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
	# 큰 글자면 카드 58: 이름 줄·약점·체력 막대 3px · 체력 숫자 줄 6px 아래 (R3, review_N N-04 — 12px 알약 아래 테가 이름 글자 위를 지났다)
	var d1 := 3.0 if T.big else 0.0
	var d2 := 6.0 if T.big else 0.0
	_card_frame(e, r)
	var pw := _intent_pill(e, Vector2(X + 3, Y + 3))
	# 이름 · 약점 · 줄 수
	var nm := T.clip(e.name + _dup_suffix(e), 10, 70)
	T.text(self, Vector2(X + 4, Y + 28 + d1), nm, 10, T.GOLD if e.boss else T.TEXT) # 졸개와 같은 웨이브의 보스는 일반 카드에 금빛 이름 (둥지어미)
	var wx := X + 86.0
	for el in e.weak:
		draw_rect(Rect2(wx, Y + 18 + d1, 11, 11), Color(T.INK, 0.9))
		draw_rect(Rect2(wx + 0.5, Y + 18.5 + d1, 10, 10), Color(T.WEAK, 0.9), false, 1.0)
		T.element_icon(self, Vector2(wx + 5.5, Y + 23.5 + d1), String(el), 4.2)
		wx -= 13.0
	var hp_s := TData.fmt_short(vhp(e))
	var hp_end := X + 4.0 + T.width(hp_s, 10) + 3.0
	# 체력 숫자가 차지 칸에 닿으면(큰 글자 "1,200,000") 차지 칸을 위 줄 오른쪽(알약 옆)으로, 징표·디버프 아이콘을 체력 숫자 줄로 바꿔 놓는다 (N-04)
	var top_charge := e.charge_max > 0 and hp_end > X + 96.0 - 7.0 * float(e.charge_max)
	if e.charge_max > 0:
		# 차지는 체력 숫자 줄 오른쪽 꺾쇠 + 이름표 "차지"(가득이면 빨간 "필살기") 10px — 체력 숫자 옆에 자리가 없으면(1,200,000) 이름 줄 오른쪽(약점 칸 앞)에.
		# 예전 알약 옆 자리는 알약 + 꺾쇠 5칸이면 자리가 없어 이름표가 안 그려졌다 (review_I I-04 · G16). 징표·디버프 아이콘은 알약 오른쪽 위 줄로
		var cy := Y + 5.0 if top_charge else Y + 39.0 + d2
		_charge_cells(e, X + 96.0, cy, 6.0, 8.0, 7.0)
		var full := e.charge >= e.charge_max
		var lab := "필살기" if full else "차지"
		var lcol := T.DANGER if full else T.TEXT_SUB
		var lx := X + 96.0 - 7.0 * float(e.charge_max) - 3.0
		if top_charge:
			if lx - T.width(lab, 10) >= X + 3.0 + pw + 3.0:
				T.text(self, Vector2(lx, Y + 13), lab, 10, lcol, HORIZONTAL_ALIGNMENT_RIGHT)
			elif wx + 10.0 - T.width(lab, 10) >= X + 4.0 + T.width(nm, 10) + 4.0:
				T.text(self, Vector2(wx + 10.0, Y + 28 + d1), lab, 10, lcol, HORIZONTAL_ALIGNMENT_RIGHT)
		elif lx - T.width(lab, 10) >= hp_end + 1.0:
			T.text(self, Vector2(lx, Y + 47 + d2), lab, 10, lcol, HORIZONTAL_ALIGNMENT_RIGHT)
		elif wx + 10.0 - T.width(lab, 10) >= X + 4.0 + T.width(nm, 10) + 4.0:
			T.text(self, Vector2(wx + 10.0, Y + 28 + d1), lab, 10, lcol, HORIZONTAL_ALIGNMENT_RIGHT)
	if e.bars.size() > 1:
		T.text(self, Vector2(wx + 10, Y + 28 + d1), "×%d" % maxi(e.bars.size() - vbar(e), 1), 8, T.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	_hp_bar(e, Rect2(X + 4, Y + 31 + d1, 92, 5))
	_est_overlay(e, Rect2(X + 4, Y + 31 + d1, 92, 5), r)
	T.text(self, Vector2(X + 4, Y + 47 + d2), hp_s, 10, T.TEXT)
	if e.charge_max > 0 and not top_charge:
		_foe_icons(e, X + 96.0, Y + 4.0, clampi(int((93.0 - pw - 6.0) / 15.0), 0, 3))
	else:
		_foe_icons(e, X + 96.0, Y + 37.0 + d2, clampi(int((X + 96.0 - hp_end - 2.0) / 15.0), 0, 3))


## 졸개 반 높이 카드 (100×24): 의도 아이콘 · 이름 · 체력 막대 · 징표/디버프 둘
func _draw_minion_card(e: TUnit) -> void:
	var r := _card_rect(e)
	var X := r.position.x
	var Y := r.position.y
	_card_frame(e, r)
	var it := e.intent()
	var k := "stun" if e.stunned else String(it.get("k", "attack"))
	var icol: Color = T.STUN if e.stunned else T.INTENT_COL.get(k, T.TEXT)
	var ic := Vector2(X + 9, Y + 9)
	draw_rect(Rect2(ic - Vector2(6, 6), Vector2(12, 12)), Color(T.INK, 0.9))
	draw_rect(Rect2(ic - Vector2(5.5, 5.5), Vector2(11, 11)), Color(icol, 0.9), false, 1.0)
	if e.stunned:
		T.star(self, ic, 3.5, T.STUN)
	else:
		T.intent_icon(self, ic, k, icol)
	T.text(self, Vector2(X + 18, Y + 13), T.clip(e.name + _dup_suffix(e), 10, 56), 10, T.TEXT)
	_foe_icons(e, X + 96.0, Y + 3.0, 1)
	_hp_bar(e, Rect2(X + 4, Y + 17, 92, 4))
	_est_overlay(e, Rect2(X + 4, Y + 17, 92, 4), r)


func _draw_boss_card(e: TUnit) -> void:
	var r := _card_rect(e)
	var X := r.position.x
	var Y := r.position.y
	var R := X + r.size.x - 4.0 # 오른쪽 안쪽 끝 (보스 카드 308 · 졸개와 같이 있으면 204)
	var d1 := 3.0 if T.big else 0.0 # 큰 글자면 카드 58 (일반 카드와 같게 — R3 N-04)
	var d2 := 6.0 if T.big else 0.0
	_card_frame(e, r)
	_intent_pill(e, Vector2(X + 3, Y + 3))
	_charge_cells(e, R, Y + 4.0, 8.0, 10.0, 11.0)
	if e.charge_max > 0:
		T.text(self, Vector2(R - 11.0 * e.charge_max - 4.0, Y + 13), "차지", 10, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_RIGHT)
	# 이름 (금빛) · 약점
	T.text(self, Vector2(X + 4, Y + 29 + d1), e.name, 12, T.GOLD)
	var nx := X + 10.0 + T.width(e.name, 12)
	if e.weak.is_empty():
		T.text(self, Vector2(nx, Y + 28 + d1), "약점 없음", 10, T.TEXT_OFF)
	else:
		T.text(self, Vector2(nx, Y + 28 + d1), "약점", 10, T.TEXT_SUB)
		var wx := nx + T.width("약점", 10) + 3.0
		for el in e.weak:
			draw_rect(Rect2(wx, Y + 18 + d1, 11, 11), Color(T.INK, 0.9))
			draw_rect(Rect2(wx + 0.5, Y + 18.5 + d1, 10, 10), Color(T.WEAK, 0.9), false, 1.0)
			T.element_icon(self, Vector2(wx + 5.5, Y + 23.5 + d1), String(el), 4.2)
			wx += 13.0
		# 줄마다 약점이 바뀌는 보스 (review_H §6.1): "▶ 다음 줄 약점" (다음 줄은 TEXT_SUB로 흐리게)
		var ph: Array = e.data.get("phases", [])
		for k in range(vbar(e) + 1, ph.size()):
			if not (ph[k] as Dictionary).has("weak"):
				continue
			T.text(self, Vector2(wx + 1, Y + 28 + d1), "▶", 8, T.TEXT_SUB)
			wx += 10.0
			for el in ph[k].weak:
				draw_rect(Rect2(wx, Y + 19 + d1, 9, 9), Color(T.INK, 0.9))
				draw_rect(Rect2(wx + 0.5, Y + 19.5 + d1, 8, 8), Color(T.TEXT_SUB, 0.7), false, 1.0)
				T.element_icon(self, Vector2(wx + 4.5, Y + 23.5 + d1), String(el), 3.4, 0.6)
				wx += 11.0
	# 남은 줄: 칸 (깬 줄 = 빈 칸, 남은 줄 = 금빛) + "줄 2/3"
	if e.bars.size() > 1:
		var n := e.bars.size()
		var bi := vbar(e)
		for k in n:
			var cx := R - float(n - k) * 11.0
			draw_rect(Rect2(cx, Y + 21 + d1, 9, 5), T.GOLD if k >= bi else T.EMPTY)
		T.text(self, Vector2(R - float(n) * 11.0 - 4.0, Y + 28 + d1), "줄 %d/%d" % [bi + 1, n], 10, T.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	_hp_bar(e, Rect2(X + 4, Y + 32 + d1, r.size.x - 8.0, 6))
	_est_overlay(e, Rect2(X + 4, Y + 32 + d1, r.size.x - 8.0, 6), r)
	T.text(self, Vector2(X + 4, Y + 48 + d2), "%s / %s" % [TData.fmt_short(vhp(e)), TData.fmt_short(vmax(e))], 10, T.TEXT)
	_foe_icons(e, R, Y + 39.0 + d2, 8 if r.size.x > 250.0 else 5)


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


## 아이콘 하나(같은 종류 합)가 상한(TData.CAP)에 닿았나 — 공격력·크리 확률·크리 데미지·특공·대마법 위력만 (마녀가 더 쌓을지 고르는 값)
func _capped(ic: Dictionary) -> bool:
	var cat := String(ic.get("cat", ""))
	if not (cat in ["atk", "crit_rate", "crit_dmg", "special", "ult_dmg"]):
		return false
	return float(ic.get("v", 0.0)) >= float(TData.CAP.get(cat, 99.0)) - 0.0001


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
		draw_rect(Rect2(X + 2, Y + 2, (r.size.x - 4.0) * clampf(w.gauge / TData.GAUGE_MAX, 0.0, 1.0), 2), Color(T.GAUGE, 0.9 if cur else 0.6))
		draw_rect(Rect2(X + 4, Y + 4, 40, 48), Color(ecol, 0.6), false, 1.0)
		var dim := 1.0 if valive(w) else 0.5
		T.text(self, Vector2(X + 50, Y + 16), w.name, 12, Color(T.GOLD if cur else T.TEXT, dim))
		T.text(self, Vector2(X + r.size.x - 4.0, Y + 15), T.SLOT_NAME[w.slot], 10, Color(T.TEXT_SUB, dim), HORIZONTAL_ALIGNMENT_RIGHT)
		if not valive(w):
			T.text(self, Vector2(X + (r.size.x + 50.0) * 0.5, Y + 38), "쓰러짐", 12, T.TEXT_OFF, HORIZONTAL_ALIGNMENT_CENTER)
			continue
		# 체력
		var hr := Rect2(X + 50, Y + 21, r.size.x - 108.0, 5) # 640이면 100 (넓은 패널은 막대도 길게)
		draw_rect(hr.grow(1), Color(T.INK, 0.95))
		var hcol := T.HP_ALLY.lerp(T.HP_LOW, clampf(1.0 - vratio(w) * 2.0, 0.0, 1.0))
		var a: TActor = actors.get(w)
		draw_rect(Rect2(hr.position, Vector2(hr.size.x * (a.shown_hp if a != null else vratio(w)), hr.size.y)), Color(hcol, 0.45))
		draw_rect(Rect2(hr.position, Vector2(hr.size.x * vratio(w), hr.size.y)), hcol)
		var boosted := vmax(w) > w.base_max_hp # 최대 체력 버프 중 (R5): 숫자 HEAL색 · 막대 위 기본 최대 자리에 1px GOLD 눈금
		if boosted:
			var tx := hr.position.x + roundf(hr.size.x * float(w.base_max_hp) / float(vmax(w)))
			draw_rect(Rect2(tx, hr.position.y - 2.0, 1, hr.size.y + 4.0), T.GOLD)
		T.text(self, Vector2(X + r.size.x - 4.0, Y + 28), TData.fmt_short(vhp(w)), 10, T.HEAL if boosted else T.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
		# 크레딧 7칸: 마름모 8px · 간격 11 · "n/7" 12px (R3, review_N N-07 — 지름 7px라 체력 숫자보다 안 보였다. FGO §21.3 NP 줄 = HP와 같은 위계)
		var full := w.credits >= TData.CREDIT_MAX
		var pulse := 0.8 + 0.2 * sin(_t * 5.0) if full else 1.0
		T.credit_row(self, Vector2(X + 54, Y + 36), w.credits, 11.0, 4.0, pulse, _credit_flash(w, 4.0)) # 번쩍은 같은 묶음에 (그리기 호출 그대로)
		var clab := "대마법" if full else "%d/%d" % [w.credits, TData.CREDIT_MAX]
		T.text(self, Vector2(X + 135, Y + 41), clab, 12, Color(T.GOLD, pulse) if full else T.TEXT)
		_credit_label(w, X + 135 + T.width(clab, 12), Y + 41)
		# 버프 아이콘 (최대 6 + "+n") — 장비 도발·장비 근성도 아이콘으로
		var icons: Array = vicons(w).duplicate()
		if bool(w.equip_data().get("taunt", false)) and not w.has_buff("taunt"):
			icons.append({"cat": "taunt", "dur": -1})
		if float(w.equip_data().get("guts_once", 0.0)) > 0.0 and not w.guts_used:
			icons.append({"cat": "guts", "dur": -1})
		if not w.delayed.is_empty():
			icons.append({"cat": "delay", "dur": w.delayed.size() if w.delayed.size() > 1 else -1}) # 예약 (R5): 시계 + 점선 화살
		if w.sealed > 0:
			icons.push_front({"cat": "seal", "dur": -1}) # 봉인 (적이 건 나쁜 효과 — 빨간 테, review_H §2.2)
		for k in mini(icons.size(), 6):
			T.buff_icon(self, Vector2(X + 50 + 15 * k, Y + 43), icons[k], int(icons[k].get("dur", -1)))
			if _capped(icons[k]): # 상한에 닿음: 금테 (상세 판에 "가득" 줄 — F-4 남긴 것)
				draw_rect(Rect2(X + 49 + 15 * k, Y + 42, 12, 12), T.GOLD, false, 1.0)
			if not _icon_active(w, icons[k]):
				draw_rect(Rect2(X + 50 + 15 * k, Y + 43, 10, 10), Color(T.INK, 0.6)) # 지금 안 붙는 조건 버프는 어둡게
		if icons.size() > 6:
			T.text(self, Vector2(X + 50 + 15 * 6, Y + 52), "+%d" % (icons.size() - 6), 10, T.TEXT_SUB)
		if w.stunned:
			for k in 3:
				T.star(self, Vector2(X + 14 + 10 * k, Y + 10), 3.5, T.STUN)
		if w.sealed > 0: # 초상 위 자물쇠
			draw_circle(Vector2(X + 38, Y + 12), 6.5, Color(T.INK, 0.95))
			T.intent_icon(self, Vector2(X + 38, Y + 12), "seal", T.DANGER)
		if cur:
			# 지금 차례: 판 위 작은 금빛 삼각
			var mx := X + r.size.x * 0.5
			draw_colored_polygon(PackedVector2Array([Vector2(mx - 5, Y - 6), Vector2(mx + 5, Y - 6), Vector2(mx, Y - 1)]), T.GOLD)


## 스킬 바퀴: 칸 6개 고정 (검토 O §4 — 칸 재질). 칸 = 바닥 그림자 · 속성 색 방사 원판(가운데 진하고 끝 옅게) · 안쪽 그림자 ·
## 종류 색 금속 테 2px(왼쪽 위 밝음 → 오른쪽 아래 어두움) · 흰빛 아이콘 + 그림자 · 비용 보석(금 = 쓸 수 있음 · 회색 + 붉은 숫자 = 모자람 · 보랏빛 = +1).
## 대마법 칸은 금 금속 테 3px + 모이는 호 / 가득이면 테를 도는 빛. 누를 수 없음 = 원판 회색 · 테 회색 · 아이콘 흐림.
## 원판·테·아이콘·보석은 PDraw 하나로 모아 그리기 호출 1번 (글자만 따로).
var _wpd := PDraw.new()

func _draw_wheel() -> void:
	if actor == null:
		return
	var pd := _wpd
	var c := _wheel_center()
	var a0 := deg_to_rad(WHEEL_A0) - 0.12
	var a1 := deg_to_rad(WHEEL_A1) + 0.12
	pd.draw_arc(c, WHEEL_R, a0, a1, 40, Color(T.LINE, 0.18), 1.0) # 부채 안내 호
	var u := actor.unit
	var ecol: Color = TData.ELEMENT_COLOR.get(String(u.data.get("element", "")), T.LINE)
	var labels: Array = [] ## [자리, 글, 색] — 보석 숫자는 flush 뒤에
	for i in slots.size():
		var s: Dictionary = slots[i]
		var p: Vector2 = s.pos
		var on := i == sel
		var ult := bool(s.get("ult", false))
		var r := _slot_r(i) + (3.0 if on else 0.0)
		if state == "target" and not on:
			# 대상 고르기 중엔 고른 칸만 — 다른 칸은 옅은 테만 남겨 그 밑의 마녀·적이 보이고 눌리게 (review_K K-07)
			if not bool(s.empty):
				pd.draw_arc(p, r, 0.0, TAU, 24, Color(T.TEXT_OFF, 0.25), 1.0)
			continue
		if bool(s.empty):
			pd.draw_arc(p, r - 2.0, 0.0, TAU, 24, Color(T.TEXT_OFF, 0.35), 1.0)
			continue
		var can := bool(s.can) and not bool(s.get("sealed", false))
		var full := ult and u.credits >= TData.ULT_COST
		var disc := ecol if can or full else Color("#6a6478")
		# 바닥 그림자 · 고른 칸 빛무리
		pd.glow(p + Vector2(0, 2.5), r + 5.0, Color(0, 0, 0, 0.55), 0.0)
		if on:
			pd.glow(p, r + 10.0, Color(ecol, 0.35), 0.0)
		# 원판: 먹 바탕 + 속성 색 방사(가운데 0.55 → 끝 0.22) + 왼쪽 위 윤기 + 안쪽 그림자
		pd.draw_circle(p, r, T.INK)
		pd.glow(p, r, Color(disc, 0.7 if can or full else 0.35), 0.4) # 쓸 수 있는 칸 0.55 → 0.7 (R6 review_P D-1: 속성 색이 살게)
		if ult and not full and u.credits > 0:
			# 모으는 대마법 칸: 크레딧 비율만큼 아래에서 위로 속성 색이 차오름 (R6 review_P §5 ③ — 어두운 원 + 흐린 해였다)
			var lv := clampf(float(u.credits) / float(TData.ULT_COST), 0.0, 1.0)
			var h0 := r - 2.0 * r * lv # 차오른 물높이 (중심 기준 y)
			var a_l := asin(clampf(h0 / r, -1.0, 1.0))
			var seg := PackedVector2Array()
			for k in 13:
				var aa := lerpf(a_l, PI - a_l, float(k) / 12.0)
				seg.append(p + Vector2(cos(aa), sin(aa)) * (r - 0.5))
			pd.convex(seg, Color(ecol, 0.3))
		pd.glow(p + Vector2(-r * 0.28, -r * 0.32), r * 0.5, Color(1, 1, 1, 0.10 if can or full else 0.04), 0.0)
		pd.ring_grad(p, Vector2(r * 0.66, r * 0.66), Vector2(r, r), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.5), 24)
		# 금속 테
		if ult:
			_ring_lit(pd, p, r, r + 3.0, Color("#fff2b8"), Color("#8a5a14") if full else Color("#5a4420"))
			if full:
				var ph := _t * 2.4
				pd.draw_arc(p, r + 1.5, ph, ph + 1.1, 10, Color(1, 1, 0.85, 0.9), 2.0) # 테를 도는 빛
				var pl := fmod(_t, 0.8) / 0.8
				pd.draw_arc(p, r + 4.0 + pl * 10.0, 0.0, TAU, 32, Color(T.GOLD, 0.5 * (1.0 - pl)), 1.0)
			else:
				var k := clampf(float(u.credits) / float(TData.ULT_COST), 0.0, 1.0)
				if k > 0.0: # 모이는 호 (12시부터 시계 방향, review_C2 M3)
					pd.draw_arc(p, r + 1.5, -PI * 0.5, -PI * 0.5 + TAU * k, 32, T.GOLD, 2.0)
		else:
			var kc := T.kind_col(String(s.kind)) if can else Color("#5a5566")
			_ring_lit(pd, p, r, r + 2.5, kc.lightened(0.35), kc.darkened(0.3))
		if on:
			pd.draw_arc(p, r + 1.0, 0.0, TAU, 32, T.TEXT, 2.0)
		# 아이콘 (그림자 1px + 흰빛)
		var ic := String(s.icon)
		# 못 쓰는 칸도 무슨 마법인지 보이게: 속성 기운이 남은 회색 알파 0.85 (R6 review_P D-1 — TEXT_OFF 0.5라 회색 원판 위에서 사라졌다)
		var icol := ecol.lightened(0.65) if can or full else Color(ecol.lightened(0.45).lerp(Color("#9a94a8"), 0.55), 0.85)
		if ult and full:
			icol = Color("#fff2c0")
		elif ult:
			icol = Color(T.GOLD, 0.75)
		TIcon.draw(pd, p + Vector2(0.8, 1.0), ic, Color(T.INK, 0.8), r * ICON_K)
		TIcon.draw(pd, p, ic, icol, r * ICON_K)
		# 비용 보석 (오른쪽 아래)
		var bc := p + Vector2(r * 0.74, r * 0.74)
		if ult:
			if not full:
				var lab := "%d/%d" % [u.credits, TData.ULT_COST]
				_gem(pd, bc, T.width(lab, 8) * 0.5 + 4.0, Color("#c9a24a"), labels, lab, T.INK)
		elif String(s.id) == "basic":
			_gem(pd, bc, 8.0, T.GAUGE, labels, "+1", T.INK)
		else:
			var cut := int(s.cost) < int(s.get("base_cost", s.cost)) # 비용 감소 중 (R5): 보석 GAUGE + 줄어든 숫자
			_gem(pd, bc, 6.5, (T.GAUGE if cut else T.GOLD) if can else Color("#5a5468"), labels, str(int(s.cost)), T.INK if can else Color("#ff9aa8"))
			var short := int(s.cost) - u.credits
			if not can and short > 0 and not bool(s.get("sealed", false)):
				# 모자란 크레딧 (R6 review_P D-1 — 얼마 더 모아야 하나): 먹 알약 위 붉은 "−n" (알약은 칸 묶음에 — 글 테두리를 따로 그리면 그리기 호출이 늘었다)
				var sp := p + Vector2(-r * 0.42, r * 0.55 + 4.0)
				var sw := T.width_px("−%d" % short, 8) * 0.5 + 2.0
				pd.draw_rect(Rect2(sp.x - sw, sp.y - 7.0, sw * 2.0, 8.0), Color(T.INK, 0.85))
				labels.append([sp, "−%d" % short, T.DANGER])
		if bool(s.get("sealed", false)):
			pd.draw_circle(p, r - 1.0, Color(T.INK, 0.6)) # 봉인 (review_H §2.2): 어둡게 + 자물쇠
			pd.draw_circle(p, 7.0, Color(T.INK, 0.95))
	pd.flush(self)
	for lb: Array in labels:
		T.text_px(self, lb[0], lb[1], 8, lb[2], HORIZONTAL_ALIGNMENT_CENTER, 0)
	for i in slots.size():
		var s: Dictionary = slots[i]
		if bool(s.get("sealed", false)) and not (state == "target" and i != sel):
			T.intent_icon(self, s.pos, "seal", T.DANGER)
	# 대마법 "연쇄 n" (쓸 수 있을 때만, review_G G17)
	if not slots.is_empty() and bool(slots[slots.size() - 1].get("ult", false)) and u.credits >= TData.ULT_COST and not (state == "target" and sel != slots.size() - 1):
		var nxt := mini(battle.chain_stage + 1, 3) if (battle.chain_owner != null and battle.chain_stage > 0) else 1
		if nxt >= 2:
			var p: Vector2 = slots[slots.size() - 1].pos
			var r := _slot_r(slots.size() - 1)
			var lab := "연쇄 %d" % nxt
			var lw := T.width(lab, 10) + 8.0
			var lr := Rect2(p.x - lw * 0.5, p.y + r + 4.0, lw, 13)
			T.panel(self, lr, Color(T.INK, 0.95), T.GOLD, 1, 2)
			T.text(self, Vector2(p.x, lr.position.y + 11), lab, 10, T.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	# 고른 칸 이름 꼬리표: 바퀴 중심 → 칸 방향 바깥쪽 (review_C2 M2). 화면 밖이면 생략
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
		if nr.position.x >= T.left() + 2.0 and nr.end.x <= T.right() - 2.0 and nr.position.y >= 32.0:
			T.panel(self, nr, Color(T.INK, 0.95), Color(T.TEXT, 0.6), 1, 2)
			T.text(self, Vector2(nr.get_center().x, nr.position.y + 11), nm, 10, T.TEXT, HORIZONTAL_ALIGNMENT_CENTER)


## 금속 테: r0~r1 고리, 왼쪽 위(−135°) hi → 오른쪽 아래 lo (빛이 위에서 오는 칸 테두리)
func _ring_lit(pd: PDraw, p: Vector2, r0: float, r1: float, hi: Color, lo: Color) -> void:
	var n := 28
	for i in n:
		var aa := TAU * float(i) / float(n)
		var ab := TAU * float(i + 1) / float(n)
		var ka := 0.5 + 0.5 * cos(aa + PI * 0.75)
		var kb := 0.5 + 0.5 * cos(ab + PI * 0.75)
		var da := Vector2(cos(aa), sin(aa))
		var db := Vector2(cos(ab), sin(ab))
		pd.convex_colors(PackedVector2Array([p + da * r1, p + db * r1, p + db * r0, p + da * r0]), PackedColorArray([lo.lerp(hi, ka), lo.lerp(hi, kb), lo.lerp(hi, kb), lo.lerp(hi, ka)]))


## 비용 보석: 가로로 긴 팔각 (위 반 밝은 면 · 아래 반 어두운 면 · 먹 테 · 왼쪽 위 반짝) — 숫자는 labels에 모아 flush 뒤에
func _gem(pd: PDraw, c: Vector2, hw: float, col: Color, labels: Array, lab: String, fg: Color) -> void:
	var h := 5.5
	var o := PackedVector2Array([c + Vector2(-hw - 1.2, 0), c + Vector2(-hw + 2.2, -h - 1.2), c + Vector2(hw - 2.2, -h - 1.2), c + Vector2(hw + 1.2, 0), c + Vector2(hw - 2.2, h + 1.2), c + Vector2(-hw + 2.2, h + 1.2)])
	pd.convex(o, T.INK)
	pd.convex(PackedVector2Array([c + Vector2(-hw, 0), c + Vector2(-hw + 3.0, -h), c + Vector2(hw - 3.0, -h), c + Vector2(hw, 0)]), col.lightened(0.25))
	pd.convex(PackedVector2Array([c + Vector2(-hw, 0), c + Vector2(hw, 0), c + Vector2(hw - 3.0, h), c + Vector2(-hw + 3.0, h)]), col.darkened(0.18))
	pd.draw_rect(Rect2(c + Vector2(-hw + 3.0, -h + 1.0), Vector2(2.0, 1.0)), Color(1, 1, 1, 0.7))
	labels.append([c + Vector2(0, 3), lab, fg])


## 설명 띠 (아래 띠 자리 (4, 302, 632, 56)): 1줄 이름·비용·종류 / 예상 피해(크리 값) · 2줄 효과 · 3줄 크레딧·대상 / 안내
func _draw_strip() -> void:
	if actor == null:
		return
	var u := actor.unit
	var ecol: Color = TData.ELEMENT_COLOR.get(u.element, T.LINE)
	var STRIP := _strip_rect()
	T.panel_lit(self, STRIP, Color(T.PANEL, 0.94), Color(ecol, 0.8)) # 입체 테 (R4 N-10)
	var X := STRIP.position.x + 8.0
	var hint := ""
	if sel < 0 or sel >= slots.size():
		T.text(self, Vector2(X, 318), "%s의 차례 — 마법을 고르세요" % u.name, 12, T.TEXT)
		if u.sealed > 0:
			T.text(self, Vector2(X, 333), "봉인 — 이번 차례는 기본 공격만" if u.sealed == 1 else "봉인 — 이번 차례는 대마법을 못 씀", 10, T.DANGER)
		else:
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
			var cut := int(s.cost) < int(s.get("base_cost", s.cost))
			T.cost_badge(self, Vector2(cx + 6, 314), str(int(s.cost)), ("gain" if cut else "ok") if can else "short")
			var kx := cx + 16.0
			if cut: # 비용 감소 (R5): 배지 오른쪽 "5 → 3"
				var cl := "%d → %d" % [int(s.base_cost), int(s.cost)]
				T.text(self, Vector2(kx, 318), cl, 10, T.GAUGE)
				kx += T.width(cl, 10) + 6.0
			T.text(self, Vector2(kx, 318), T.kind_label(TData.skill(sid)), 10, T.TEXT_SUB)
		# 예상 피해 (대상을 고르면 그 대상, 아니면 첫 적) [확정 21-2 B] — 크리 값 함께
		var est_tgt: TUnit = null
		if state == "target" and not targets.is_empty() and not (targets[tsel] as TActor).unit.is_witch():
			est_tgt = (targets[tsel] as TActor).unit
		elif not battle.alive_of(battle.enemies).is_empty():
			est_tgt = battle.alive_of(battle.enemies)[0]
		var right := ""
		var rcol := T.GOLD
		var tag := ""
		if String(s.kind) == "attack" and est_tgt != null:
			var info := battle.est_info(u, est_tgt, "" if sid == "basic" else sid)
			right = T.est_text(int(info.est), int(info.crit), "예상", -1.0 if bool(info.sure) else float(info.rate)) # 크리 확률 (review_F F06 b)
			for e in (battle.skill_of(u, sid).get("effects", []) if sid != "basic" else []): # 강화 레벨 수치 (조건 비례 배수가 예상과 같게)
				if String(e.t) == "this_special" and e.has("trait") and TBattle.special_hits(e, est_tgt):
					tag = "%s 특공" % TData.TRAIT_NAME.get(String(e.trait), "") # 특성 특공이 붙는 대상 (review_F F02 화면 — WEAK 꼬리표)
				elif String(e.t) == "scale": # 조건 비례 (R5 — review_M M2): "체력 40% · ×1.36" / "쌓인 힘 5 · ×2.0"
					var k := 1.0 + TBattle.scale_of(e, u)
					tag = ("체력 %d%%" % int(round(u.hp_ratio() * 100.0)) if String(e.get("by", "")) == "self_hp_low" else "쌓인 힘 %d" % u.stack_n()) + " · ×%s" % _x(k)
		var sr := _success_text(u, sid, est_tgt)
		if sr != "":
			right = sr if right == "" else right + " · " + sr
			if right == sr and (sr == "면역" or sr == "기절 내성"):
				rcol = T.TEXT_OFF
		if right != "":
			T.text(self, Vector2(STRIP.end.x - 8, 318), right, 10, rcol, HORIZONTAL_ALIGNMENT_RIGHT)
		if tag != "":
			T.text(self, Vector2(STRIP.end.x - 14 - T.width(right, 10), 318), tag, 10, T.WEAK, HORIZONTAL_ALIGNMENT_RIGHT)
		var desc := String(u.data.basic.desc) if sid == "basic" else String(TData.skill(sid).desc)
		var bf := T.body_fs()
		T.text(self, Vector2(X, 334 if bf == 10 else 335), T.clip(desc, bf, STRIP.size.x - 16.0), bf, T.TEXT)
		if not can:
			hint = "봉인됨" if bool(s.get("sealed", false)) else "크레딧이 모자랍니다"
		elif state == "target" and not _ally_pick() and battle.foe_targets().size() < battle.alive_of(battle.enemies).size():
			hint = "막아서기 — 이 적만 고를 수 있음" # 단일 대상이 막아서는 적뿐 (review_H §2.2)
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
		var cx0 := X + T.width("크레딧", 10) + 6.0 # 큰 글자면 이름표가 넓어짐 (I-10)
		T.credit_row(self, Vector2(cx0, 347), u.credits, 9.0, 3.0)
		var own := "%d/%d" % [u.credits, TData.CREDIT_MAX]
		T.text(self, Vector2(cx0 + 9 * 7, 351), own, 10, T.GOLD if u.credits >= TData.CREDIT_MAX else T.TEXT)
		# 동료 크레딧 짧게 (바퀴가 열려 패널이 가려도 몰아주기·크레딧 주기 판단이 되게, review_C2 M10)
		var mates: Array = []
		for w in battle.witches:
			if w != u and w.alive:
				mates.append("%s ◆%d" % [w.name, w.credits])
		if not mates.is_empty():
			T.text(self, Vector2(cx0 + 9 * 7 + T.width(own, 10) + 12, 351), " · ".join(mates), 10, T.TEXT_SUB)
	if hint != "":
		T.text(self, Vector2(STRIP.end.x - 8, 351), hint, 10, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_RIGHT)


## 배수 글 (×1.36 · ×2.0 — 끝 0은 한 자리만)
static func _x(k: float) -> String:
	var t := "%.2f" % k
	return t.trim_suffix("0") if t.ends_with("0") else t


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
		if not a.unit.is_witch() and top.y < _head_min() + 2.0:
			# 키 큰 적: 의도 아이콘(y 92 둘레)을 피해 그 오른쪽에서 (카드 테가 금빛으로 같이 알림)
			top = Vector2(top.x + 20.0, _head_min() + 6.0 + sin(_t * 6.0) * 2.0)
		var col := Color(T.GOLD if on else T.TEXT, 1.0 if on else 0.6)
		draw_colored_polygon(PackedVector2Array([top + Vector2(-7, -10), top + Vector2(7, -10), top]), Color(T.INK, 0.9))
		draw_colored_polygon(PackedVector2Array([top + Vector2(-5, -9), top + Vector2(5, -9), top + Vector2(0, -2)]), col)
		var feet := to_screen(a.feet())
		draw_set_transform(feet, 0.0, Vector2(1.0, 0.35))
		draw_arc(Vector2.ZERO, a.half_w() + 8.0, 0.0, TAU, 28, Color(col, 0.9 if on else 0.4), 2.0 if on else 1.0)
		draw_set_transform(Vector2.ZERO)


## 바퀴 칸 가까이 (부채가 넓어져 중심 거리 대신 칸마다 잼)
func _near_slot(p: Vector2, pad: float) -> bool:
	if not _wheel_on() or actor == null:
		return false
	for i in slots.size():
		if p.distance_to(slots[i].pos) < _slot_r(i) + pad:
			return true
	return false


func _draw_numbers() -> void:
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
		if kind in BODY_KINDS and kind != "heal" and _near_slot(n.p as Vector2, 24.0):
			a *= 0.35 # 바퀴가 열린 동안 바퀴 위의 지난 숫자는 흐리게 (review_G G08) — 회복 숫자는 빼고 (R2: 지속 회복이 다음 마녀 바퀴 밑에서 흐려졌다)
		var pop := 1.0 - clampf(minf(age, float(n.get("last", age))) / 0.12, 0.0, 1.0) # 합칠 때마다 다시 툭 커짐
		var q: Vector2 = (n.p as Vector2) + Vector2(0, rise)
		if bool(n.get("foe", false)) and kind in BODY_KINDS:
			# 떠오르는 큰 숫자도 적 카드(아래 끝 82)에 닿지 않게 (review_K K-05 — 1,500,000·19,423이 카드에 찍혔다)
			q.y = maxf(q.y, _head_min() + 3.0 + float(fs) + (12.0 if bool(n.weak) else 0.0))
		elif not (kind in BODY_KINDS):
			var hw := T.width(String(n.text), fs) * 0.5 + 2.0
			q.x = clampf(q.x, T.left() + hw, T.right() - hw)
		var s := 1.0 + 0.25 * pop
		draw_set_transform(q, 0.0, Vector2(s, s))
		var c := Color(col.lerp(Color.WHITE, pop * 0.6), a)
		if String(n.key) in ["band", "aband"]: # 적 전체·아군 전체 띠: 먹 바탕
			var bw := T.width(String(n.text), fs) + 10.0
			draw_rect(Rect2(-bw * 0.5, -float(fs) - 1.0, bw, float(fs) + 4.0), Color(T.INK, 0.8 * a))
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
	var gsrc := "" ## 용어 풀이를 찾을 글 — 패시브·의도·효과만 (능력치 줄의 "크레딧"·"차지"는 늘 같은 풀이가 떠서 뺌, review_I I-14)
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
			gsrc += String(pas.get("desc", "")) + " "
		var st: Array = []
		if u.stunned:
			st.append("기절 (다음 차례 쉼)")
		if u.stun_guard:
			st.append("기절 내성")
		if u.is_taunting():
			st.append("도발 중")
		if u.inv_guard > 0:
			st.append("무적 내성 (적 행동 %d번)" % u.inv_guard)
		if u.sealed > 0:
			st.append("봉인 (다음 차례 기본 공격만)" if u.sealed == 1 else "대마법 봉인")
		elif u.seal_guard:
			st.append("봉인 내성")
		if float(eq.get("guts_once", 0.0)) > 0.0:
			st.append("장비 근성 %s" % ("씀" if u.guts_used else "남음"))
		if not st.is_empty():
			lines.append([" · ".join(st), T.STUN, 1])
		for d in u.delayed: # 예약 (R5): "예약: 다음 차례 크레딧 +2"
			var parts: Array = []
			for e in d.get("effects", []):
				match String(e.t):
					"credits": parts.append("크레딧 +%d" % int(e.v))
					"gauge": parts.append("게이지 +%d%%" % int(round(float(e.v) * 100.0)))
					_: parts.append("%s +%d%%" % [TData.CAT_NAME.get(String(e.get("cat", "")), "버프"), int(round(float(e.get("v", 0.0)) * 100.0))])
			lines.append(["예약: 다음 차례 " + " · ".join(parts), T.GOLD, 1])
			gsrc += "예약 "
		var full: Array = []
		for ic in u.buff_icons():
			if _capped(ic):
				full.append("%s %d%%" % [TData.CAT_NAME.get(String(ic.cat), String(ic.cat)), int(round(float(TData.CAP[String(ic.cat)]) * 100.0))])
		if not full.is_empty(): # 상한에 닿은 버프 — 더 걸어도 안 오름 (review_J §7 6 · F-4 남긴 것)
			lines.append(["가득 (상한): " + " · ".join(full) + " — 더 걸어도 오르지 않음", T.GOLD, 2])
		for b in u.buffs:
			var off := _buff_off_reason(u, b)
			var bad := String(b.cat) in T.BAD_CATS or bool(b.get("bad", false)) # 적이 건 약화 (해제가 안 지움)
			lines.append([T.buff_line(b) + (" " + off if off != "" else "") + (" (적의 약화)" if bool(b.get("bad", false)) else ""), (Color("#d9ccff") if off == "" else T.TEXT_OFF) if not bad else T.DANGER, 1 if off == "" else 2])
			gsrc += T.buff_line(b) + (" 약화 " if bool(b.get("bad", false)) else " ")
	else:
		title = u.name + _dup_suffix(u)
		title_col = T.GOLD if u.boss else T.TEXT
		sub = String(TData.TIER_NAME.get(u.tier, ""))
		var bl := " (줄 %d/%d)" % [vbar(u) + 1, u.bars.size()] if u.bars.size() > 1 else ""
		lines.append(["체력 %s / %s%s" % [TData.fmt_short(vhp(u)), TData.fmt_short(vmax(u)), bl], T.TEXT, 1])
		var wn: Array = []
		for el in u.weak:
			wn.append(TData.ELEMENT_NAME.get(String(el), ""))
		var crit_s := " · 크리 %d%%" % int(round(u.ecrit * 100.0)) if absf(u.ecrit - TData.ENEMY_CRIT_BASE) > 0.001 else ""
		lines.append(["약점 %s · 방어율 %d%% · 내성 %d%%%s" % [", ".join(wn) if not wn.is_empty() else "없음", int(round(u.def_rate * 100.0)), int(round(u.resist * 100.0)), crit_s], T.WEAK if not wn.is_empty() else T.TEXT, 1])
		# 줄마다 약점 (review_H §6.1 — 약점은 처음부터 보임 [확정 21-5 A])
		var ph: Array = u.data.get("phases", [])
		if ph.size() > 1:
			var parts: Array = []
			for k in ph.size():
				var wk: Array = (ph[k] as Dictionary).get("weak", u.data.get("weak", [])) if k > 0 else u.data.get("weak", [])
				var nm: Array = []
				for el in wk:
					nm.append(TData.ELEMENT_NAME.get(String(el), ""))
				parts.append("%d %s" % [k + 1, "·".join(nm)])
			lines.append(["줄마다 약점 — " + " ▶ ".join(parts), T.WEAK, 1])
		# 특성 · 고유 효과 · 우두머리 (review_H §3)
		if not u.traits.is_empty():
			var tn: Array = []
			for tr in u.traits:
				tn.append(TData.TRAIT_NAME.get(String(tr), ""))
			lines.append(["특성 " + " · ".join(tn) + (" · 우두머리 (쓰러지면 졸개도 사라짐)" if u.leader else ""), T.TEXT_SUB, 2])
		for pa in u.passive:
			lines.append(["고유 효과 — " + TData.enemy_passive_text(pa), T.GOLD, 2])
			gsrc += TData.enemy_passive_text(pa) + " "
		var it := u.intent()
		var k := String(it.get("k", "attack"))
		var il := "다음 행동 %s%s" % [TData.INTENT_NAME.get(k, ""), " (관통)" if bool(it.get("pierce", false)) else ""] # "의도" → "다음 행동"으로 통일 (B4 판과 같은 말, review_I I-15)
		gsrc += "%s%s " % [TData.INTENT_NAME.get(k, ""), " 관통" if bool(it.get("pierce", false)) else ""]
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
			gsrc += "%s %d겹 " % [TData.MARK_NAME.get(mk, mk), u.mark_n(String(mk))]
		for b in u.buffs:
			lines.append([T.buff_line(b), T.DANGER if String(b.cat) == "atk" else Color("#c9b8c8"), 1])
	# 용어 풀이 한 줄: 패시브·의도·효과 글에 나온 첫 용어 — 도움말에서 이미 연 용어는 건너뜀 (review_F F08 · review_I I-14)
	var gl := TData.gloss_for(gsrc, TSave.terms_seen)
	if gl != "":
		lines.append([gl, T.TEXT_OFF, 3])
	var bf := T.body_fs()
	var lh := T.body_lh()
	var dw := DETAIL_W + (48.0 if T.big else 0.0)
	var h := 30.0
	for ln: Array in lines:
		h += lh * float(mini(T.split_lines(String(ln[0]), dw - 16.0, bf).size(), int(ln[2]))) + 1.0
	var dh := 360.0 - DETAIL_Y - 4.0 # 내용만큼 (화면 아래 끝까지) — 예전 180 상한에 글이 잘렸다 (review_K K-15)
	var r := Rect2(T.left() + 16.0, DETAIL_Y, dw, minf(h, dh)) if not u.is_witch() else Rect2(T.right() - 16.0 - dw, DETAIL_Y, dw, minf(h, dh))
	T.panel_lit(self, r, Color(T.PANEL, 1.0), Color(T.LINE, 0.8)) # 입체 테 (R4 N-10) — 바탕 INK → PANEL (먹 테가 보이게)
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
func _draw_banner_box(title: String, sub: String, col: Color, t: float, left := 99.0, full_h := 84.0, line_col := Color(1, 1, 1, 0.85), sparks := false) -> void:
	var k := clampf(t / 0.35, 0.0, 1.0)
	var fade := clampf(left / 0.2, 0.0, 1.0)
	var e := (1.0 - pow(1.0 - k, 3.0)) * fade
	var ta := clampf((t - 0.1) / 0.2, 0.0, 1.0) * fade # 글은 0.1초부터 알파 0 → 1 (R3, review_N N-08 — 띠가 다 열린 0.35초 뒤에 툭 떠서 1.0초 배너 중 0.65초만 보였다)
	col = Color(col, col.a * ta)
	var h := full_h * e
	var cy := 180.0
	var x0 := T.left()
	var w := T.view.x
	if h >= 1.0:
		# 띠 = 세로 그라데이션(가운데 0.92 → 위아래 끝 0.7) + 위아래 2px 선 (승리 금 · 웨이브 흰빛 · 패배 빨강) — 먹 띠 + 1px 선이 평평했다 (N-09)
		var top := cy - h * 0.5
		var edge := Color(T.INK, 0.7 * e)
		var mid := Color(T.INK, 0.92 * e)
		draw_polygon(PackedVector2Array([Vector2(x0, top), Vector2(x0 + w, top), Vector2(x0 + w, cy), Vector2(x0, cy)]), PackedColorArray([edge, edge, mid, mid]))
		draw_polygon(PackedVector2Array([Vector2(x0, cy), Vector2(x0 + w, cy), Vector2(x0 + w, cy + h * 0.5), Vector2(x0, cy + h * 0.5)]), PackedColorArray([mid, mid, edge, edge]))
		var lc := Color(line_col, line_col.a * e)
		draw_rect(Rect2(x0, top, w, 2), lc)
		draw_rect(Rect2(x0, cy + h * 0.5 - 2.0, w, 2), lc)
	if ta > 0.0:
		var ty := cy + 8.0 if full_h <= 84.0 else cy - full_h * 0.5 + 38.0
		T.text(self, Vector2(320.0, ty), title, 30, col, HORIZONTAL_ALIGNMENT_CENTER)
		if sub != "":
			T.text(self, Vector2(320.0, cy + 30), sub, 10, Color(T.TEXT, 0.9 * ta), HORIZONTAL_ALIGNMENT_CENTER)
		if sparks:
			_banner_sparks(T.width(title, 30), ty - 10.0, t)


## 승리 띠 양옆 금 불티 12개 (0.15~0.75초) — 제목 양옆에서 바깥·위로 튀어 사라짐. 결과 화면은 만들지 않음 [확정 20-1 A] (R3, review_N N-09)
func _banner_sparks(tw: float, y: float, t: float) -> void:
	var u := t - 0.15
	if u < 0.0 or u > 0.6:
		return
	for i in 12:
		var side := -1.0 if i % 2 == 0 else 1.0
		var r1 := fposmod(sin(float(i) * 12.9898) * 43758.5453, 1.0)
		var r2 := fposmod(sin(float(i) * 78.233) * 12543.531, 1.0)
		var d := u - 0.04 * float(i / 2) # 둘씩 조금씩 늦게
		if d < 0.0:
			continue
		var p0 := Vector2(320.0 + side * (tw * 0.5 + 6.0 + 18.0 * r1), y + 16.0 * r2 - 8.0)
		var v := Vector2(side * (50.0 + 70.0 * r2), -(40.0 + 60.0 * r1))
		var p := p0 + v * d + Vector2(0, 90.0) * d * d
		var a := clampf(1.0 - d / 0.45, 0.0, 1.0)
		if a <= 0.0:
			continue
		T.diamond(self, p, 2.5 * a + 0.8, Color(T.GOLD, a))
		draw_rect(Rect2(p - Vector2(0.5, 0.5), Vector2(1, 1)), Color(1, 1, 1, a))


func _draw_banner() -> void:
	var win := banner_text == "승리"
	var lose := banner_text == "패배"
	# 아래 글은 깜빡임 없이 0.5초 뒤 고정 (review_K K-28 — 1초마다 깜빡여 읽기 전에 사라졌다)
	_draw_banner_box(banner_text, "" if lose or _banner_t < 0.5 else banner_sub, T.GOLD if win else T.DANGER, _banner_t, 99.0, LOSE_H if lose else 84.0,
		Color(T.GOLD, 0.9) if win else Color(T.DANGER, 0.85), win)
	if lose and _banner_t > 0.35:
		# 진 이유 (review_G G03 · review_F F13): 줄마다 10px
		var lh := 15.0 if T.big else 13.0 # 큰 글자면 12px · 줄 간격 15 (review_I I-10)
		for i in banner_lines.size():
			var ln: Array = banner_lines[i]
			T.text(self, Vector2(320.0, 158 + lh * i), T.clip(String(ln[0]), 10, 620), 10, ln[1], HORIZONTAL_ALIGNMENT_CENTER)
	if lose and _banner_t > 0.5:
		for b: Array in [[LOSE_RETRY, "다시 도전", lose_main == "retry"], [LOSE_SETUP, "물러나기" if _field() else "편성으로", lose_main == "setup"]]:
			var r: Rect2 = b[0]
			T.panel(self, r, Color(T.LINE, 0.75) if b[2] else Color(T.INK, 0.9), Color(T.TEXT, 0.9), 1, 3)
			T.text(self, r.get_center() + Vector2(0, 5), String(b[1]), 12, T.INK if b[2] else T.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 0 if b[2] else -1)


func _draw_confirm() -> void:
	draw_rect(T.screen(), Color(T.INK, 0.45))
	T.panel(self, CONFIRM, Color(T.PANEL, 0.97), Color(T.LINE, 0.9), 1, 4)
	T.text(self, Vector2(320, 162), "전투를 접고 물러날까요?" if _field() else "전투를 접고 편성으로 갈까요?", 12, T.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	T.text(self, Vector2(320, 178), "지금 전투의 진행은 사라집니다", 10, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_CENTER)
	T.panel(self, CONFIRM_NO, Color(T.INK, 0.9), Color(T.TEXT, 0.8), 1, 3)
	T.text(self, CONFIRM_NO.get_center() + Vector2(0, 5), "취소", 12, T.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	T.panel(self, CONFIRM_YES, Color(T.DANGER, 0.85), Color(T.TEXT, 0.8), 1, 3)
	T.text(self, CONFIRM_YES.get_center() + Vector2(0, 5), "철수", 12, T.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
