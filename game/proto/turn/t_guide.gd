class_name TGuide
extends Control
## 첫 플레이 안내 · 도움말 · 설정 · 이어하기 판 · 멈춤 판 (combat_proto.md §28, review_G_firstplay.md §4 · review_F_gaps.md F07·F08·F12).
## 맨 위 캔버스 층(40)에 있어 입력을 가장 먼저 받는다 (SceneTree는 _input을 나무의 뒤쪽 노드부터 부르고, 처리되면 멈춘다).
## 안내 판은 시간이 멈춘 순간(마녀 차례 바퀴가 열려 고르기를 기다릴 때 · 적 차례 앞 · 배너 · 편성 화면)에만 뜨고 연출 길이는 건드리지 않는다
## (1배속·건너뛰기 없음 [확정 21-3 A] · 짧은 연출 [확정 22-1 A]).
## 판 종류 (card.mode):
##   "tap"  — 어디를 눌러도 닫힘 (그 누름은 먹는다). 강조 사각은 보여 주기만
##   "pass" — 강조 사각(holes) 안의 누름만 아래 화면으로 넘긴다 (첫 두 행동 B1·B2만 — "세게 막는 것은 B1·B2뿐" §28.1). 바깥 누름은 먹는다. 상태가 바뀌면 다음 단계로
##   "hint" — 모든 누름을 아래 화면으로 넘기고 판은 화면 상태가 바뀔 때까지 남는다 (덮개 0.35로 옅게 — A3a·A3b·B7·C1, review_I I-06)
## 첫 실행 흐름 (phase): A1 → A3a → A3b → (안내 전투) B1 → B2 → B3 → B4 → B5 → B7 → C1 → C2 → C3. B6(크레딧 7)·D1~D6·T7·T8·T11은 처음 일어날 때 한 번.
## (A2 "숫자는 비용"은 뺐다 — S-01 카드 꼬리표·B3과 같은 말, review_I I-07. D2 징표는 안내 흐름 동안 미뤄 일반 전투 첫 징표 때)
## 판 자리는 강조 사각과 피할 사각(바퀴가 열려 있으면 바퀴 칸·그 차례 마녀 패널, card.avoid)을 모두 피한다 (review_I I-08)

signal resume_chosen(yes: bool)
signal title_done ## 타이틀을 눌러 뗌 (R6 review_P D-2)

const T := preload("res://proto/turn/t_theme.gd")
const PANEL_W := 300.0
const OFF_W := 60.0 ## "안내 끄기" 터치 목표 60×24
const OFF_H := 24.0
const HELP := Rect2(40, 34, 560, 296)
const HELP_CELL := Vector2(78, 36) ## 4열 × 5줄 쪽 둘 (용어 37) — 칸 높이 19 → 36: 손가락으로 고를 수 없었다 (R3, review_N N-03)
const HELP_COLS := 4
const HELP_PER := 20 ## 한 쪽 칸 수
const HELP_RESET := Rect2(52, 288, 136, 36)
const HELP_SET := Rect2(196, 288, 136, 36) ## 전투 중에도 설정을 연다 (review_I I-12)
const HELP_CLOSE := Rect2(452, 288, 136, 36)
const HELP_PREV := Rect2(338, 288, 36, 36) ## 쪽 넘김 ◀ ▶ (R3 N-03)
const HELP_NEXT := Rect2(410, 288, 36, 36)
const SET := Rect2(150, 8, 340, 344) ## 줄 7개 × 36 (R3 — 줄 높이 32 → 36 · "전체 화면" 줄 더함)
const FS_JS := """(function(){ if (window.eskaFS) return;
 var d = document, el = d.documentElement, mm = function(q){ return !!(window.matchMedia && window.matchMedia(q).matches); };
 var mobile = mm('(pointer: coarse)') || ((navigator.maxTouchPoints || 0) > 0 && /Android|iPhone|iPad|Mobile/i.test(navigator.userAgent));
 window.eskaFS = {
  mobile: mobile, app: mm('(display-mode: fullscreen)') || mm('(display-mode: standalone)'),
  can: !!(el.requestFullscreen || el.webkitRequestFullscreen),
  is: function(){ return !!(d.fullscreenElement || d.webkitFullscreenElement) || this.app; },
  req: function(){ try {
    var lock = function(){ try { if (screen.orientation && screen.orientation.lock) screen.orientation.lock('landscape').catch(function(){}); } catch (e) {} };
    var p = el.requestFullscreen ? el.requestFullscreen({navigationUI: 'hide'}) : (el.webkitRequestFullscreen ? el.webkitRequestFullscreen() : null);
    if (p && p.then) p.then(lock).catch(function(){}); else lock();
   } catch (e) {} },
  exit: function(){ try { if ((d.fullscreenElement || d.webkitFullscreenElement) && d.exitFullscreen) d.exitFullscreen().catch(function(){}); } catch (e) {} }
 };
})();"""
const RESUME := Rect2(190, 104, 260, 132)
const RESUME_YES := Rect2(202, 186, 112, 36)
const RESUME_NO := Rect2(326, 186, 112, 36)

var stage: Node ## TStage
var phase := "" ## 첫 실행 흐름의 지금 단계 ("" = 없음)
var card := {} ## {id, title, body, holes: [Rect2], mode: "tap"|"pass"|"hint", finger, avoid: [Rect2]}
var mode := "" ## "" · title · help · settings · resume · resume_confirm · pause
var help_i := 0 ## 도움말에서 고른 용어
var resume_info := ""
var _t := 0.0
var _pass_press := false ## 이번 누름을 아래 화면으로 넘겼나 (떼기도 넘긴다)
var _card_t := 0.0 ## 판이 뜬 지 (뜨자마자 같은 손가락의 떼기로 닫히지 않게)
var help_page := 0 ## 도움말 쪽 (0 · 1)
var _title_t := 0.0 ## 타이틀이 뜬 지 (글이 0.4초에 걸쳐 떠오름)
## 폰 웹 전체 화면 · 가로 (R3, review_N N-02 = review_M N3): 첫 탭을 뗄 때 requestFullscreen → 되면 screen.orientation.lock('landscape') (실패는 조용히).
## 브라우저는 탭(touchend)에서 몇 초 동안 사용자 활성화를 주므로 Godot가 다음 프레임에 부르는 요청도 제스처 안이다. 데스크톱·이미 전체 화면(설치 앱)이면 아무것도 안 함
var fs_web := false ## 웹 + 터치 폰 (window.eskaFS.mobile)
var fs_tried := false ## 첫 탭 요청을 했나 (이번 실행에 한 번 — 풀린 뒤엔 다시 들어가는 버튼으로만)
var fs_is := false ## 지금 전체 화면인가 (0.5초마다 물음)
var _fs_poll := 0.0
var _fs_down := false ## 다시 들어가는 버튼을 누르는 중
var _fs_hold := 0.0 ## 요청한 뒤 이만큼은 버튼을 숨김 (전체 화면이 되기까지 — 버튼이 잠깐 깜빡이던 것)
var portrait := false ## 세로로 듦 → 안내 판 + 전투 멈춤 (폰 웹만)
var test_phone := false ## 시험용: 폰 웹처럼 (데스크톱에서 세로 안내·다시 들어가는 버튼 그림 확인)
var test_fs := false ## 시험용: test_phone에서 전체 화면인 척


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if OS.has_feature("web"):
		JavaScriptBridge.eval(FS_JS)
		fs_web = bool(JavaScriptBridge.eval("!!(window.eskaFS && window.eskaFS.mobile && window.eskaFS.can)", true))
		fs_is = _fs_query()


func _process(delta: float) -> void:
	_t += delta
	_card_t += delta
	_title_t += delta
	size = Vector2(640, 360) # 설계 화면 (review_K K-01)
	TSave.tick(delta)
	_fs_tick(delta)
	_update_flow()
	queue_redraw()


# ═══════════════════════════════════════════════════════════
# 폰 웹 전체 화면 · 가로 고정 · 세로 안내 (R3, review_N N-02)
# ═══════════════════════════════════════════════════════════

func _phone() -> bool:
	return fs_web or test_phone


func _fs_query() -> bool:
	if test_phone:
		return test_fs
	if not fs_web:
		return false
	return bool(JavaScriptBridge.eval("window.eskaFS.is()", true))


func _fs_request() -> void:
	_fs_hold = 1.5
	_fs_poll = 0.3
	if fs_web:
		JavaScriptBridge.eval("window.eskaFS.req()")


## 0.5초마다 전체 화면인지 묻고, 세로인지 본다 (세로로 들면 전투는 창이 가려질 때와 같게 저장·멈춤)
func _fs_tick(delta: float) -> void:
	_fs_hold = maxf(_fs_hold - delta, 0.0)
	_fs_poll -= delta
	if _fs_poll <= 0.0:
		_fs_poll = 0.5
		fs_is = _fs_query()
	var por := _phone() and T.view.y > T.view.x
	if por and not portrait and stage != null and bool(stage._in_battle):
		stage._hidden()
		pause()
	portrait = por


## 전체 화면이 풀린 뒤 다시 들어가는 작은 버튼 (화면 오른쪽 끝 · 위 띠 밑) — 오른쪽에 640 바깥 자리가 40px 이상일 때만 (없으면 설정 줄로)
func fs_btn() -> Rect2:
	if not _phone() or not TSave.full_screen or not fs_tried or fs_is or _fs_hold > 0.0 or portrait or mode != "" or T.ofs.x < 40.0:
		return Rect2()
	return Rect2(T.right() - 40.0, 34, 36, 36)


## 모든 누름·뗌을 먼저 본다: 첫 뗌에 전체 화면 요청(세로여도 — 되면 가로로 잠겨 돌아감) · 세로면 먹음 · 다시 들어가는 버튼. 처리했으면 true
func _fs_input(pos: Vector2, pressed: bool) -> bool:
	if not pressed and _phone() and TSave.full_screen and not fs_tried and not fs_is:
		fs_tried = true
		_fs_request() # 첫 탭 — 그 탭은 아래 화면도 그대로 받는다 (세로면 아래 화면은 안 받음)
		if not portrait:
			return false
	if portrait:
		return true
	var b := fs_btn()
	if pressed:
		_fs_down = b.has_area() and b.has_point(pos)
		return _fs_down
	if _fs_down:
		_fs_down = false
		if b.has_point(pos):
			_fs_request()
			Sfx.play(&"tn_select", -10.0)
		return true
	return false


# ═══════════════════════════════════════════════════════════
# 바깥에서 부르는 것
# ═══════════════════════════════════════════════════════════

## 첫 실행 안내를 처음부터 (편성 화면 A1) — 설정의 "안내 다시 보기"
func begin() -> void:
	phase = "A1"
	card = {}


## 첫 실행: 타이틀 다음 곧장 안내 전투 B1부터 (R6 review_P D-2 — 처음 켠 사람에게 편성 화면이 먼저 뜨던 것). A1은 이긴 뒤 편성에서
func begin_intro() -> void:
	phase = "B1"
	card = {}


## 타이틀 한 장 (R6 review_P D-2)
func open_title() -> void:
	mode = "title"
	_title_t = 0.0


func active() -> bool:
	return phase != "" and not TSave.tips_off


## 판이나 모달이 떠 있나 (전투 흐름이 차례 사이에서 기다림)
func busy() -> bool:
	return not card.is_empty() or mode != ""


## 지금 떠 있는 판이 사라질 때까지 기다린다 (적 차례 앞 B4·D 카드)
func wait_clear() -> void:
	while is_inside_tree() and busy():
		await get_tree().process_frame


## 처음 일어난 일 안내 (D·T·B6): 본 적 없으면 "tap" 판을 띄우고 true. 이미 판이 있으면 다음 기회로
func tip(id: String, title: String, body: String, holes: Array) -> bool:
	if TSave.seen(id) or not card.is_empty() or mode != "":
		return false
	_show(id, title, body, holes, "tap")
	return true


func open_help() -> void:
	mode = "help"
	help_page = clampi(help_i / HELP_PER, 0, _help_pages() - 1)
	Sfx.play(&"tn_select", -10.0)


func open_settings() -> void:
	mode = "settings"
	Sfx.play(&"tn_select", -10.0)


## 끊긴 전투 진입 판 (F07 규칙 3)
func ask_resume(info: String) -> void:
	resume_info = info
	mode = "resume"


## 자동 멈춤 (F07 규칙 4)
func pause() -> void:
	if mode == "":
		mode = "pause"


func _show(id: String, title: String, body: String, holes: Array, m: String, finger := false, avoid: Array = []) -> void:
	var clipped: Array = []
	for h: Rect2 in holes:
		var c := h.intersection(T.screen().grow(-1.0)) # 화면 밖으로 나간 강조는 화면 안으로 (B1 칸이 x 0에서 잘리던 것, I-18)
		clipped.append(c if c.has_area() else h)
	card = {"id": id, "title": title, "body": body, "holes": clipped, "mode": m, "finger": finger, "avoid": avoid}
	_card_t = 0.0
	Sfx.play(&"tn_select", -14.0)


func _close_card() -> void:
	if card.is_empty():
		return
	var id := String(card.id)
	card = {}
	TSave.mark(id)
	if id == phase:
		phase = String({"A1": "C1" if TSave.intro_done else "A3a", "B3": "B4", "B4": "B5", "B5": "B7", "C2": "C3", "C3": ""}.get(id, phase)) # 안내 전투를 이긴 뒤의 A1 → C1 (R6)
		if id == "C3":
			TSave.mark("first_done")
	if id == "B5" and stage != null:
		stage.hud.hint_once = "적·마녀·칸을 길게 누르면 자세히 볼 수 있습니다" # B3과 같은 순간에 겹치지 않게 B5 다음 마녀 차례로 (I-07)


# ═══════════════════════════════════════════════════════════
# 첫 실행 흐름 (review_G §4.3~§4.5) — 매 프레임 지금 화면에 맞는 판을 고른다
# ═══════════════════════════════════════════════════════════

func _update_flow() -> void:
	if stage == null or phase == "" or mode != "":
		return
	if TSave.tips_off:
		phase = ""
		card = {}
		return
	var setup: TSetup = stage.setup
	var hud: THud = stage.hud
	var in_battle: bool = stage._in_battle
	if hud.visible and hud.state == "banner" and phase in ["B1", "B2", "B3", "B4", "B5"]:
		# 이기면 남은 B 단계는 건너뜀 · 지면 다시 도전할 때 B1부터 (진 사람이 더 필요할 때 — review_I I-27)
		phase = "B7" if hud.banner_text == "승리" else "B1"
		card = {}
	match phase:
		"A1":
			if setup.visible and setup.step == 1 and card.is_empty():
				_show("A1", "마녀 셋으로 싸웁니다", "마녀마다 마법 4개와 대마법 1개를 들고 나갑니다. 지금 파티 그대로 출격해도 됩니다.", [Rect2(12, 34, 382, 300)], "tap")
		"A3a":
			if setup.visible and setup.step == 3:
				phase = "A3b"
				card = {}
			elif setup.visible and setup.step == 1:
				_keep("A3a", "첫 전투로 갑니다", "아래 \"전투 고르기\"를 누르세요.", [TSetup.START1_RECT.grow(2)], "hint")
			else:
				card = {}
		"A3b":
			if in_battle:
				phase = "B1"
				card = {}
			elif setup.visible and setup.step == 3:
				_keep("A3b", "안내 전투", "오른쪽 아래 출격을 누르세요.", [TSetup.START1_RECT.grow(2), setup._battle_rect(0).grow(2)], "hint")
			elif setup.visible and setup.step == 1:
				phase = "A3a"
				card = {}
		"B1":
			if not in_battle:
				if setup.visible:
					phase = "A3a" # 안내 전투에서 지고 편성으로 (I-27)
					card = {}
				return
			if hud.state == "target" and hud.sel >= 0 and String(hud.slots[hud.sel].id) == "basic":
				phase = "B2"
				card = {}
			elif hud.state == "wheel" and hud.actor != null and not hud.slots.is_empty():
				_keep("B1", "%s의 차례" % hud.actor.unit.name, "칸을 한 번 누르면 설명, 한 번 더 누르면 사용합니다. 기본 공격은 크레딧을 1 더 모읍니다.", [hud.slot_rect(0)])
		"B2":
			if hud.state == "target":
				var holes: Array = []
				var e: TUnit = (hud.targets[0] as TActor).unit if not hud.targets.is_empty() else null
				if e != null:
					holes = [hud._card_rect(e), hud.body_rect(hud.targets[0])]
				_keep("B2", "누구를 칠까", "빛나는 적을 누르세요. 카드의 불꽃 표시는 약점 — 불 공격이 1.5배 들어갑니다. 빈 곳을 누르면 뒤로.", holes)
			elif hud.state == "wheel":
				phase = "B1"
				card = {}
			else:
				phase = "B3"
				card = {}
		"B3", "B5":
			if in_battle and hud.state == "wheel" and hud.sel < 0 and hud.actor != null and card.is_empty() and stage.wheel_ready():
				if phase == "B3":
					var holes: Array = [hud._panel_rect(hud.actor.unit.slot)]
					for i in hud.slots.size():
						if not bool(hud.slots[i].empty) and bool(hud.slots[i].can) and i > 0 and not bool(hud.slots[i].ult):
							holes.append(hud.slot_rect(i))
					_show("B3", "크레딧이 모였습니다", "크레딧은 차례마다 1씩 모입니다. 숫자 배지가 금빛인 칸은 지금 쓸 수 있고, 회색(빨간 숫자)은 아직 모자랍니다.", holes, "tap")
				else:
					_show("B5", "차례 줄", "맨 왼쪽이 지금 차례, 오른쪽으로 갈수록 나중입니다. 칸을 누르면 누구인지 빛납니다.", [hud.queue_box()], "tap")
		"B7":
			if hud.visible and hud.state == "banner" and hud.banner_text == "승리" and hud._banner_t > 0.5: # 승리 글이 그려진 뒤 (review_K K-24)
				_keep("B7", "이겼습니다", "아무 데나 누르면 편성으로 갑니다. 이제 마법을 바꿔 나만의 빌드를 짜 봅니다.", [Rect2(T.left(), 138, T.view.x, 84)], "hint") # 어디를 눌러도 넘어감 (I-05)
			elif setup.visible:
				phase = "A1" if TSave.intro_done else "A3a" # 이기면 편성 소개 A1 → C1 (R6: 첫 실행은 타이틀 → 안내 전투라 A1을 여기로) · 지면 다시 출격부터
				card = {}
		"C1":
			if setup.visible and setup.step == 2:
				phase = "C2"
				card = {}
			elif setup.visible and setup.step == 1:
				var slot := maxi(TSetup.party().find("ignis"), 0)
				_keep("C1", "마법 장착", "이그니스의 장착 마법을 눌러 보세요. 마녀마다 마법 10개 중 4개를 고릅니다.", [setup._magic_btn(slot).grow(3)], "hint")
		"C2":
			if setup.visible and setup.step == 2 and card.is_empty():
				# 강조는 타일 묶음만 — 설명 상자까지 뚫으면 판이 갈 자리가 없어 설명 글 위에 겹쳤다 (I-08). 판은 설명 상자를 피해 왼쪽 아래로
				_show("C2", "마법 바꾸기", "한 번 누르면 설명, 다시 누르면 장착·해제. 4개까지이고 대마법(금빛 줄)은 바꿀 수 없습니다.", [Rect2(150, 38, 232, 192)], "tap", false, [TSetup.DESC])
		"C3":
			if setup.visible and setup.step == 2 and card.is_empty():
				_show("C3", "장비", "장비 줄을 누르면 목록이 열립니다. 마녀마다 하나 — 강한 만큼 대가가 붙은 것도 있습니다.", [TSetup.EQUIP_ROW.grow(2)], "tap")


## 적 차례 앞 (TStage가 0.4초 대기 전에 부름): B4 "적의 다음 행동"
func on_enemy_turn(u: TUnit) -> void:
	if phase == "B4" and card.is_empty() and mode == "" and stage != null:
		var r: Rect2 = stage.hud._card_rect(u)
		_show("B4", "적의 다음 행동", "카드 왼쪽 위 표시가 이 적의 다음 행동입니다. 빨간 \"강공격\"은 크게 아픕니다.", [r.grow(2)], "tap")


## "pass"("hint") 판을 띄우거나 강조 사각만 새로 (자리가 바뀌는 화면 — 바퀴·카드)
func _keep(id: String, title: String, body: String, holes: Array, m := "pass") -> void:
	if card.is_empty() or String(card.id) != id:
		_show(id, title, body, holes, m, true)
	else:
		card.holes = holes


# ═══════════════════════════════════════════════════════════
# 입력
# ═══════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if (event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION)) \
			and _fs_input(event.position - T.ofs, event.pressed):
		get_viewport().set_input_as_handled()
		return
	if portrait and event is InputEventKey:
		get_viewport().set_input_as_handled()
		return
	if card.is_empty() and mode == "":
		return
	var pos := Vector2.ZERO
	var pressed := false
	var is_press := false
	if event is InputEventScreenTouch:
		pos = event.position - T.ofs # 설계 좌표 (넓은 화면, review_K K-01)
		pressed = event.pressed
		is_press = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION:
		pos = event.position - T.ofs
		pressed = event.pressed
		is_press = true
	elif event is InputEventKey and event.pressed and not event.echo:
		if mode == "title" and (event.is_action_pressed("es_jump") or event.is_action_pressed("es_attack")):
			_close_title()
			get_viewport().set_input_as_handled()
		elif mode == "" and String(card.get("mode", "")) == "tap" and (event.is_action_pressed("es_jump") or event.is_action_pressed("es_attack")):
			_close_card()
			get_viewport().set_input_as_handled()
		elif mode in ["help", "settings", "pause"] and (event.is_action_pressed("es_attack") or event.is_action_pressed("es_exit") or event.is_action_pressed("es_jump")):
			mode = ""
			get_viewport().set_input_as_handled()
		return
	else:
		return
	if not pressed:
		if mode == "title" and _title_t > 0.2:
			_close_title() # 뗄 때 — 폰 웹 전체 화면 요청(_fs_input)과 같은 제스처
		if not _pass_press:
			get_viewport().set_input_as_handled()
		_pass_press = false
		return
	_pass_press = false
	if mode != "":
		_modal_press(pos)
		get_viewport().set_input_as_handled()
		return
	# 안내 판
	if _off_rect().has_point(pos):
		Sfx.play(&"tn_cancel", -10.0)
		TSave.turn_off()
		card = {}
		phase = ""
		get_viewport().set_input_as_handled()
		return
	if String(card.mode) == "hint":
		_pass_press = true
		return # 아래 화면이 받는다 (판은 화면 상태가 바뀔 때까지)
	if String(card.mode) == "pass":
		for h: Rect2 in card.holes:
			if h.has_point(pos):
				_pass_press = true
				return # 아래 화면이 받는다
		get_viewport().set_input_as_handled()
		return
	if _card_t > 0.15:
		_close_card()
	get_viewport().set_input_as_handled()


func _close_title() -> void:
	mode = ""
	title_done.emit()


func _modal_press(p: Vector2) -> void:
	match mode:
		"pause":
			mode = ""
			Sfx.play(&"tn_confirm", -10.0)
		"help":
			if HELP_PREV.has_point(p) or HELP_NEXT.has_point(p):
				help_page = clampi(help_page + (1 if HELP_NEXT.has_point(p) else -1), 0, _help_pages() - 1)
				Sfx.play(&"tn_select", -12.0)
				return
			for i in TData.GLOSSARY.size():
				if _help_cell(i).has_point(p):
					help_i = i
					TSave.terms_seen[String(TData.GLOSSARY[i][0])] = true
					Sfx.play(&"tn_select", -12.0)
					return
			if HELP_SET.has_point(p):
				mode = "settings"
				Sfx.play(&"tn_select", -10.0)
			elif HELP_RESET.has_point(p) and not _battle_on():
				TSave.reset_tips()
				mode = ""
				begin() # A1은 편성 화면에서 뜬다 (전투 중이면 전투가 끝난 뒤)
				Sfx.play(&"tn_confirm", -8.0)
			elif HELP_CLOSE.has_point(p) or not HELP.has_point(p):
				mode = ""
				Sfx.play(&"tn_cancel", -10.0)
		"settings":
			_settings_press(p)
		"resume":
			if RESUME_YES.has_point(p):
				mode = ""
				resume_chosen.emit(true)
			elif RESUME_NO.has_point(p):
				mode = "resume_confirm"
				Sfx.play(&"tn_select", -10.0)
		"resume_confirm": # 왼쪽 = 취소(안전) · 오른쪽 = 버리기(빨강) — 모든 확인 판과 같게 (review_K K-16)
			if RESUME_NO.has_point(p):
				mode = ""
				resume_chosen.emit(false)
			elif RESUME_YES.has_point(p):
				mode = "resume"
				Sfx.play(&"tn_cancel", -10.0)


# ═══════════════════════════════════════════════════════════
# 설정 (review_F F12 · review_G G18): 효과음 · 흔들림 · 번쩍임 · 큰 글자 · 안내 다시 보기 · 도움말 · 타이틀로
# ═══════════════════════════════════════════════════════════

## 설정 줄 i (0 효과음 · 1 흔들림 · 2 번쩍임 · 3 큰 글자 · 4 전체 화면 · 5 안내 다시 보기/도움말 · 6 타이틀로/닫기) — 높이 36 (R3 N-03)
func _set_row(i: int) -> Rect2:
	return Rect2(SET.position.x + 12, SET.position.y + 32 + 38 * i, SET.size.x - 24, 36)


func _set_btn(i: int, right: bool) -> Rect2:
	var r := _set_row(i)
	return Rect2(r.end.x - (44.0 if right else 168.0), r.position.y, 44, 36) if i == 0 else Rect2(r.end.x - 96.0, r.position.y, 96, 36)


func _set_half(i: int, right: bool) -> Rect2:
	var r := _set_row(i)
	return Rect2(r.position.x + (r.size.x * 0.5 + 4.0 if right else 0.0), r.position.y, r.size.x * 0.5 - 4.0, 36)


## 전투 중인가 (도움말·설정의 "안내 다시 보기"·"타이틀로"를 숨김 — review_I I-12)
func _battle_on() -> bool:
	return stage != null and bool(stage._in_battle)


## "타이틀로" 버튼을 보이나: 전투 중이 아니고, 웹 ?turn(턴제만)이 아닐 때 — 옛 실시간판 타이틀로 가서 헷갈렸다 (review_I I-21)
func _title_btn() -> bool:
	return not _battle_on() and not (stage != null and bool(stage.turn_only))


func _settings_press(p: Vector2) -> void:
	var gs := GameState
	if _set_btn(0, false).has_point(p) or _set_btn(0, true).has_point(p):
		var step := 1 if _set_btn(0, true).has_point(p) else -1
		var lv := clampi(int(round(float(gs.settings.sfx) * 5.0)) + step, 0, 5)
		gs.settings.sfx = float(lv) / 5.0
		gs.apply_settings()
		_save_settings()
		Sfx.play(&"tn_select", -6.0)
	elif _set_btn(1, false).has_point(p):
		gs.settings.shake = not bool(gs.settings.get("shake", true))
		_save_settings()
	elif _set_btn(2, false).has_point(p):
		gs.settings.flash = not bool(gs.settings.get("flash", true))
		_save_settings()
	elif _set_btn(3, false).has_point(p):
		TSave.big_text = not TSave.big_text
		T.big = TSave.big_text
		TSave.save_setup()
		TSave.save_tips() # 안내 중(hold)에도 남게 — 편성 파일은 안내가 끝나야 쓴다 (review_I I-17)
	elif _set_btn(4, false).has_point(p):
		# 전체 화면 (폰 웹): 켜면 바로 요청(이 누름이 제스처) · 끄면 나감. 데스크톱은 값만 바뀜 (R3, review_N N-02)
		TSave.full_screen = not TSave.full_screen
		TSave.save_setup()
		TSave.save_tips()
		if TSave.full_screen and _phone() and not fs_is:
			fs_tried = true
			_fs_request()
		elif not TSave.full_screen and fs_web:
			JavaScriptBridge.eval("window.eskaFS.exit()")
	elif _set_half(5, false).has_point(p) and not _battle_on():
		TSave.reset_tips()
		mode = ""
		begin()
	elif _set_half(5, true).has_point(p):
		mode = "help"
		help_page = clampi(help_i / HELP_PER, 0, _help_pages() - 1)
	elif _set_half(6, false).has_point(p) and _title_btn():
		mode = ""
		if stage != null:
			stage._exit()
	elif _set_half(6, true).has_point(p) or not SET.has_point(p):
		mode = ""
	else:
		return
	Sfx.play(&"tn_select", -10.0)


func _save_settings() -> void:
	if TSave.enabled:
		GameState.save_settings()


# ═══════════════════════════════════════════════════════════
# 그림
# ═══════════════════════════════════════════════════════════

func _draw() -> void:
	if not card.is_empty() and mode == "":
		_draw_card()
	match mode:
		"title": _draw_title()
		"help": _draw_help()
		"settings": _draw_settings()
		"resume", "resume_confirm": _draw_resume()
		"pause": _draw_pause()
	var fb := fs_btn()
	if fb.has_area():
		_draw_fs_btn(fb)
	if portrait:
		_draw_portrait()


## 타이틀 (R6 review_P D-2 [제안]): 배경·파티 셋(TStage가 세움) 위에 가운데 먹 띠(위아래로 옅어짐) · "에스카" 30 금 + 먹 테 (320, 120) ·
## "공간의 마녀" 12 보조 (320, 150) · 아래 "눌러서 시작" 12 (1초 숨쉬기, 320, 300). 글은 0.4초에 걸쳐 6px 떠오름
func _draw_title() -> void:
	var sc := T.screen()
	var k := clampf(_title_t / 0.4, 0.0, 1.0)
	var e := 1.0 - pow(1.0 - k, 3.0)
	var band := PackedVector2Array([Vector2(sc.position.x, 78), Vector2(sc.end.x, 78), Vector2(sc.end.x, 120), Vector2(sc.position.x, 120)])
	draw_polygon(band, PackedColorArray([Color(T.INK, 0.0), Color(T.INK, 0.0), Color(T.INK, 0.55 * e), Color(T.INK, 0.55 * e)]))
	draw_rect(Rect2(sc.position.x, 120, sc.size.x, 38), Color(T.INK, 0.55 * e))
	band = PackedVector2Array([Vector2(sc.position.x, 158), Vector2(sc.end.x, 158), Vector2(sc.end.x, 196), Vector2(sc.position.x, 196)])
	draw_polygon(band, PackedColorArray([Color(T.INK, 0.55 * e), Color(T.INK, 0.55 * e), Color(T.INK, 0.0), Color(T.INK, 0.0)]))
	var dy := 6.0 * (1.0 - e)
	# 제목 두 겹 (컷인 제목과 같은 말 — 먹 그림자 · 어두운 금 바깥 테 · 금 글)
	var f := T.font(30)
	var tp := (Vector2(320 - f.get_string_size("에스카", HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x * 0.5, 134 + dy)).round()
	draw_string_outline(f, tp + Vector2(2, 3), "에스카", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 8, Color(T.INK, 0.8 * e))
	draw_string_outline(f, tp, "에스카", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 8, Color(Color("#4a3008"), e))
	draw_string_outline(f, tp, "에스카", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 3, Color(Color("#fff6d6"), e))
	draw_string(f, tp, "에스카", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(T.GOLD, e))
	draw_rect(Rect2(320 - 70, 143 + dy, 140, 1), Color(T.GOLD, 0.45 * e))
	T.text(self, Vector2(320, 158 + dy), "공간의 마녀", 12, Color(T.TEXT_SUB, e), HORIZONTAL_ALIGNMENT_CENTER)
	var br := 0.55 + 0.45 * (0.5 + 0.5 * sin(_t * TAU))
	T.text(self, Vector2(320, 300), "눌러서 시작", 12, Color(T.TEXT, br * e), HORIZONTAL_ALIGNMENT_CENTER)


## 다시 들어가는 버튼: 먹 원 + 네 모서리 꺾쇠 (전체 화면 기호)
func _draw_fs_btn(r: Rect2) -> void:
	var c := r.get_center()
	draw_circle(c, 14.0, Color(T.INK, 0.75))
	draw_arc(c, 14.0, 0.0, TAU, 24, Color(T.LINE, 0.7), 1.0)
	var col := Color(T.TEXT, 0.9)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var k := c + Vector2(6.0 * sx, 6.0 * sy)
			draw_line(k, k - Vector2(4.0 * sx, 0), col, 1.6)
			draw_line(k, k - Vector2(0, 4.0 * sy), col, 1.6)


## 세로 안내: 화면 전체 먹 + 폰이 가로로 눕는 그림 + "가로로 돌려 주세요" 15px (세로 화면은 지원하지 않는다 — §21.16)
func _draw_portrait() -> void:
	draw_rect(T.screen(), Color(T.BG, 0.98))
	# 세로 화면은 폭이 640 설계 폭이라 글이 작다 → 판 가운데를 기준으로 2배 (픽셀 글꼴은 정수 배율로)
	var z := 2.0 if T.view.y > T.view.x else 1.0
	draw_set_transform(Vector2(320, 180) * (1.0 - z), 0.0, Vector2(z, z))
	var c := Vector2(320, 150)
	var k := 0.5 - 0.5 * cos(fmod(_t, 2.4) / 1.2 * PI) if fmod(_t, 2.4) < 1.2 else 1.0 # 1.2초 동안 눕고 1.2초 쉼
	var ang := -PI * 0.5 * k
	var xf := Transform2D(ang, c)
	var pts := PackedVector2Array()
	for v: Vector2 in [Vector2(-15, -26), Vector2(15, -26), Vector2(15, 26), Vector2(-15, 26), Vector2(-15, -26)]:
		pts.append(xf * v)
	draw_polyline(pts, T.TEXT, 2.0)
	draw_circle(xf * Vector2(0, 21), 2.0, T.TEXT)
	draw_arc(c, 40.0, -PI * 0.5, -PI * 0.5 - PI * 0.5 * k, 16, Color(T.GOLD, 0.8), 1.6)
	T.text(self, Vector2(320, 214), "가로로 돌려 주세요", 15, T.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	var sub := "세로 화면은 지원하지 않습니다" + (" · 전투는 멈춤" if stage != null and bool(stage._in_battle) else "")
	T.text(self, Vector2(320, 234), sub, 10, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_CENTER)
	draw_set_transform(Vector2.ZERO)


## 덮개(INK 0.6 · hint 0.35, 강조 사각만 뚫림) · 강조 금테(1.2초 숨쉬기 — 바퀴 칸은 원) · 판 (제목 12 · 본문 10/12 · 안내 끄기) · 손가락 ▼ (판 위에)
func _draw_card() -> void:
	var holes: Array = card.holes
	var dim: Array = [T.screen()]
	for h: Rect2 in holes:
		dim = _subtract(dim, h)
	for r: Rect2 in dim:
		draw_rect(r, Color(T.INK, 0.35 if String(card.mode) == "hint" else 0.6))
	var br := 0.6 + 0.4 * (0.5 + 0.5 * sin(_t * TAU / 1.2))
	for h: Rect2 in holes:
		if _is_slot(h):
			draw_arc(h.get_center(), h.size.x * 0.5, 0.0, TAU, 32, Color(T.GOLD, br), 2.0) # 바퀴 칸은 원 (네모끼리 겹쳐 지저분했다, I-18)
		else:
			draw_rect(h.grow(1), Color(T.GOLD, br), false, 2.0)
	var pr := _card_rect()
	T.panel(self, pr, Color(T.PANEL, 0.96), Color(T.LINE, 0.9), 1, 4)
	draw_rect(Rect2(pr.position + Vector2(1, 1), Vector2(3, pr.size.y - 2)), T.GOLD)
	T.text(self, pr.position + Vector2(12, 18), String(card.title), 12, T.GOLD)
	T.wrap(self, pr.position + Vector2(12, 34), String(card.body), pr.size.x - 22.0, T.body_fs(), T.TEXT, T.body_lh())
	var off := _off_rect()
	T.text(self, Vector2(off.end.x - 6, off.end.y - 7), "안내 끄기", 10, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_RIGHT) # 8px TEXT_OFF는 "안니 끄기"처럼 찍혔다 (I-09)
	if String(card.mode) == "tap":
		T.text(self, Vector2(pr.position.x + 12, pr.end.y - 7), "눌러서 닫기", 10, T.TEXT_SUB)
	if bool(card.finger) and not holes.is_empty():
		var h0: Rect2 = holes[0]
		var bob := 3.0 * (0.5 + 0.5 * sin(_t * 6.0))
		if h0.position.y > 20.0:
			var tip_p := Vector2(h0.get_center().x, h0.position.y - 3.0 - bob)
			draw_colored_polygon(PackedVector2Array([tip_p + Vector2(-6, -9), tip_p + Vector2(6, -9), tip_p]), Color(T.INK, 0.9))
			draw_colored_polygon(PackedVector2Array([tip_p + Vector2(-4, -8), tip_p + Vector2(4, -8), tip_p + Vector2(0, -2)]), T.GOLD)
		else:
			var tip_p := Vector2(h0.get_center().x, h0.end.y + 3.0 + bob)
			draw_colored_polygon(PackedVector2Array([tip_p + Vector2(-6, 9), tip_p + Vector2(6, 9), tip_p]), Color(T.INK, 0.9))
			draw_colored_polygon(PackedVector2Array([tip_p + Vector2(-4, 8), tip_p + Vector2(4, 8), tip_p + Vector2(0, 2)]), T.GOLD)


## 이 강조 사각이 바퀴 칸인가 (원으로 그림)
func _is_slot(h: Rect2) -> bool:
	if stage == null or not stage._in_battle:
		return false
	var hud: THud = stage.hud
	for i in hud.slots.size():
		if hud.slot_rect(i).is_equal_approx(h):
			return true
	return false


## 판이 피할 사각: card.avoid + 바퀴가 열려 있으면 바퀴 칸 전부 · 그 차례 마녀 패널 (B5가 열린 칸을, B6이 크레딧 7 패널을 덮던 것 — I-08)
func _avoid_rects() -> Array:
	var out: Array = (card.get("avoid", []) as Array).duplicate()
	if stage != null and stage._in_battle:
		var hud: THud = stage.hud
		if hud.state in ["wheel", "target"]:
			for i in hud.slots.size():
				out.append(hud.slot_rect(i))
			if hud.actor != null:
				out.append(hud._panel_rect(hud.actor.unit.slot))
	return out


## 판 자리: 강조 사각 아래 → 위(손가락 자리 22px를 띄움) → 오른쪽 → 왼쪽 → 화면의 빈 자리 순으로, 화면 안에 들고 강조·피할 사각과 안 겹치는 첫 자리.
## 없으면 겹치는 넓이가 가장 작은 자리
func _card_rect() -> Rect2:
	var holes: Array = card.holes
	var w := PANEL_W
	var h := _card_h(w)
	if holes.is_empty():
		return Rect2(170, 150 - h * 0.5, w, h)
	var u: Rect2 = holes[0]
	for k in range(1, holes.size()):
		u = u.merge(holes[k])
	var cx := clampf(u.get_center().x - w * 0.5, 6.0, size.x - w - 6.0)
	var cands: Array = [Rect2(cx, u.end.y + 10.0, w, h), Rect2(cx, u.position.y - h - 22.0, w, h)]
	var rw := minf(w, size.x - u.end.x - 14.0)
	if rw >= 180.0:
		var rh := _card_h(rw)
		cands.append(Rect2(u.end.x + 8.0, clampf(u.get_center().y - rh * 0.5, 34.0, size.y - rh - 6.0), rw, rh))
	var lw := minf(w, u.position.x - 14.0)
	if lw >= 180.0:
		var lh2 := _card_h(lw)
		cands.append(Rect2(u.position.x - lw - 8.0, clampf(u.get_center().y - lh2 * 0.5, 34.0, size.y - lh2 - 6.0), lw, lh2))
	for p: Vector2 in [Vector2(330, 92), Vector2(330, 150), Vector2(330, 200), Vector2(10, 92), Vector2(170, 120), Vector2(4, 200)]:
		cands.append(Rect2(p, Vector2(w, h)))
	var block: Array = holes + _avoid_rects()
	var best := Rect2()
	var best_a := INF
	for c: Rect2 in cands:
		if c.position.y >= 32.0 and c.end.y <= size.y - 4.0 and c.position.x >= 4.0 and c.end.x <= size.x - 4.0:
			var a := 0.0
			for hh: Rect2 in block:
				if c.intersects(hh):
					a += c.intersection(hh).get_area()
			if a <= 0.0:
				return c
			if a < best_a:
				best_a = a
				best = c
	return best if best_a < INF else Rect2(cx, clampf(u.end.y + 10.0, 32.0, size.y - h - 4.0), w, h)


func _card_h(w: float) -> float:
	var lines := T.split_lines(String(card.body), w - 22.0, T.body_fs()).size()
	return 34.0 + T.body_lh() * float(lines) + 18.0


func _off_rect() -> Rect2:
	if card.is_empty():
		return Rect2()
	var pr := _card_rect()
	return Rect2(pr.end.x - OFF_W, pr.end.y - OFF_H, OFF_W, OFF_H)


## 사각 목록에서 hole을 뺀다 (덮개를 강조 사각만큼 뚫기 — 남는 조각은 사각 4개까지)
static func _subtract(rects: Array, hole: Rect2) -> Array:
	var out: Array = []
	for r: Rect2 in rects:
		if not r.intersects(hole):
			out.append(r)
			continue
		var i := r.intersection(hole)
		if i.position.y > r.position.y:
			out.append(Rect2(r.position.x, r.position.y, r.size.x, i.position.y - r.position.y))
		if i.end.y < r.end.y:
			out.append(Rect2(r.position.x, i.end.y, r.size.x, r.end.y - i.end.y))
		if i.position.x > r.position.x:
			out.append(Rect2(r.position.x, i.position.y, i.position.x - r.position.x, i.size.y))
		if i.end.x < r.end.x:
			out.append(Rect2(i.end.x, i.position.y, r.end.x - i.end.x, i.size.y))
	return out


## 도움말 용어 칸 i — 지금 쪽(help_page)에 없으면 빈 사각
func _help_cell(i: int) -> Rect2:
	var j := i - help_page * HELP_PER
	if j < 0 or j >= HELP_PER:
		return Rect2()
	return Rect2(HELP.position.x + 10 + (HELP_CELL.x + 3) * float(j % HELP_COLS), HELP.position.y + 32 + (HELP_CELL.y + 2) * float(j / HELP_COLS), HELP_CELL.x, HELP_CELL.y)


func _help_pages() -> int:
	return maxi(ceili(float(TData.GLOSSARY.size()) / float(HELP_PER)), 1)


## 시험용: 용어 i가 있는 쪽으로 넘기고 그 칸 자리
func help_cell_at(i: int) -> Rect2:
	help_page = clampi(i / HELP_PER, 0, _help_pages() - 1)
	return _help_cell(i)


func _draw_help() -> void:
	draw_rect(T.screen(), Color(T.INK, 0.55))
	T.panel(self, HELP, Color(T.PANEL, 0.98), Color(T.LINE, 0.9), 1, 4)
	T.text(self, HELP.position + Vector2(12, 22), "도움말 — 용어", 15, T.TEXT)
	T.text(self, HELP.end - Vector2(12, HELP.size.y - 21), "눌러서 풀이", 10, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_RIGHT)
	for i in range(help_page * HELP_PER, mini((help_page + 1) * HELP_PER, TData.GLOSSARY.size())):
		var r := _help_cell(i)
		var on := i == help_i
		T.panel(self, r, Color(T.PANEL_HI, 1.0) if on else Color(T.INK, 0.7), T.GOLD if on else Color(T.LINE, 0.4), 2 if on else 1, 3)
		var nm := String(TData.GLOSSARY[i][0])
		if T.width(nm, 10) > HELP_CELL.x - 4.0:
			T.text_px(self, r.get_center() + Vector2(0, 4), nm, 10, T.GOLD if on else T.TEXT, HORIZONTAL_ALIGNMENT_CENTER) # 큰 글자에서 칸을 넘는 긴 용어("받는 크리 데미지")는 10px 그대로 (R2)
		else:
			T.text(self, r.get_center() + Vector2(0, 4), nm, 10, T.GOLD if on else T.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	var x := HELP.position.x + 10 + (HELP_CELL.x + 3) * float(HELP_COLS) + 8.0
	var w := HELP.end.x - x - 12.0
	draw_rect(Rect2(x - 6, HELP.position.y + 32, 1, 244), Color(T.LINE, 0.3))
	var g: Array = TData.GLOSSARY[clampi(help_i, 0, TData.GLOSSARY.size() - 1)]
	T.text(self, Vector2(x, HELP.position.y + 50), String(g[0]), 15, T.GOLD)
	var gy := HELP.position.y + 72.0
	gy += T.wrap(self, Vector2(x, gy), String(g[1]), w, T.body_fs(), T.TEXT, T.body_lh())
	if g.size() > 2:
		T.wrap(self, Vector2(x, gy + 8), "화면에서: " + String(g[2]), w, 10, T.TEXT_SUB, T.body_lh()) # 어디에 보이나 (review_I I-16)
	if not _battle_on():
		_btn(HELP_RESET, "안내 다시 보기", false)
	_btn(HELP_SET, "설정", false)
	_btn(HELP_CLOSE, "닫기", true)
	if _help_pages() > 1:
		_btn(HELP_PREV, "◀", false)
		_btn(HELP_NEXT, "▶", false)
		T.text(self, Vector2((HELP_PREV.end.x + HELP_NEXT.position.x) * 0.5, HELP_PREV.position.y + 23), "%d/%d" % [help_page + 1, _help_pages()], 10, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_CENTER)


func _btn(r: Rect2, label: String, main: bool) -> void:
	T.panel(self, r, Color(T.LINE, 0.8) if main else Color(T.INK, 0.85), Color(T.TEXT, 0.9) if main else Color(T.TEXT_OFF, 0.9), 1, 3)
	T.text(self, r.get_center() + Vector2(0, 5), label, 12, T.INK if main else T.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 0 if main else -1)


func _draw_settings() -> void:
	draw_rect(T.screen(), Color(T.INK, 0.55))
	T.panel(self, SET, Color(T.PANEL, 0.98), Color(T.LINE, 0.9), 1, 4)
	T.text(self, SET.position + Vector2(12, 22), "설정", 15, T.TEXT)
	var gs := GameState
	var rows := [["효과음", ""], ["화면 흔들림", "켬" if bool(gs.settings.get("shake", true)) else "끔"], ["화면 번쩍임", "켬" if bool(gs.settings.get("flash", true)) else "끔"],
		["큰 글자", "켬" if TSave.big_text else "끔"], ["전체 화면", "켬" if TSave.full_screen else "끔"]]
	for i in rows.size():
		var r := _set_row(i)
		if i == 2 or i == 4:
			# "번쩍임 (광과민) 켬"이 광과민 모드 켬으로 읽혔다 → 이름 "화면 번쩍임" + 보조 글 (review_I I-11) · 전체 화면은 폰 웹에서만 뜻이 있음 (R3 N-02)
			var sub := "빛에 민감하면 끄세요"
			if i == 4:
				sub = "폰 웹 가로 — 첫 터치에 꽉 채움" if _phone() else "폰 웹에서만 (이 화면은 해당 없음)"
			T.text(self, r.position + Vector2(0, 16), String(rows[i][0]), 12, T.TEXT)
			T.text(self, r.position + Vector2(0, 31), sub, 10, T.TEXT_SUB)
		else:
			T.text(self, r.position + Vector2(0, 23), String(rows[i][0]), 12, T.TEXT)
		if i == 0:
			var lv := clampi(int(round(float(gs.settings.sfx) * 5.0)), 0, 5)
			_btn(_set_btn(0, false), "−", false)
			_btn(_set_btn(0, true), "+", false)
			for k in 5:
				var c := Rect2(_set_btn(0, false).end.x + 6 + 13 * k, r.position.y + 13, 10, 10)
				draw_rect(c, T.GOLD if k < lv else T.EMPTY)
		else:
			var on := String(rows[i][1]) == "켬"
			_btn(_set_btn(i, false), String(rows[i][1]), on)
	if not _battle_on():
		_btn(_set_half(5, false), "안내 다시 보기", false)
	_btn(_set_half(5, true), "도움말 (용어)", false)
	if _title_btn():
		_btn(_set_half(6, false), "타이틀로", false)
	_btn(_set_half(6, true), "닫기", true)
	if not TSave.persistent():
		T.text(self, Vector2(SET.get_center().x, SET.end.y - 8), "이 브라우저에서는 저장되지 않습니다", 10, T.TEXT_OFF, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_resume() -> void:
	draw_rect(T.screen(), Color(T.INK, 0.7))
	T.panel(self, RESUME, Color(T.PANEL, 0.98), Color(T.GOLD, 0.8), 1, 4)
	var cx := RESUME.get_center().x
	if mode == "resume":
		T.text(self, Vector2(cx, RESUME.position.y + 26), "끊긴 전투가 있습니다", 12, T.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		T.text(self, Vector2(cx, RESUME.position.y + 46), resume_info, 10, T.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		T.text(self, Vector2(cx, RESUME.position.y + 62), "끊긴 차례부터 이어서 합니다", 10, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_CENTER)
		_btn(RESUME_YES, "이어 하기", true)
		_btn(RESUME_NO, "버리기", false)
	else:
		T.text(self, Vector2(cx, RESUME.position.y + 30), "끊긴 전투를 버릴까요?", 12, T.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		T.text(self, Vector2(cx, RESUME.position.y + 50), "되돌릴 수 없습니다", 10, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_CENTER)
		_btn(RESUME_YES, "취소", false)
		T.panel(self, RESUME_NO, Color(T.DANGER, 0.85), Color(T.TEXT, 0.8), 1, 3)
		T.text(self, RESUME_NO.get_center() + Vector2(0, 5), "버리기", 12, T.TEXT, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_pause() -> void:
	draw_rect(T.screen(), Color(T.INK, 0.6))
	var r := Rect2(220, 140, 200, 72)
	T.panel(self, r, Color(T.PANEL, 0.98), Color(T.LINE, 0.9), 1, 4)
	T.text(self, Vector2(320, 172), "멈춤", 15, T.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	T.text(self, Vector2(320, 194), "눌러서 계속", 10, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_CENTER)
