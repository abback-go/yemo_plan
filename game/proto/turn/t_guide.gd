class_name TGuide
extends Control
## 첫 플레이 안내 · 도움말 · 설정 · 이어하기 판 · 멈춤 판 (combat_proto.md §28, review_G_firstplay.md §4 · review_F_gaps.md F07·F08·F12).
## 맨 위 캔버스 층(40)에 있어 입력을 가장 먼저 받는다 (SceneTree는 _input을 나무의 뒤쪽 노드부터 부르고, 처리되면 멈춘다).
## 안내 판은 시간이 멈춘 순간(마녀 차례 바퀴가 열려 고르기를 기다릴 때 · 적 차례 앞 · 배너 · 편성 화면)에만 뜨고 연출 길이는 건드리지 않는다
## (1배속·건너뛰기 없음 [확정 21-3 A] · 짧은 연출 [확정 22-1 A]).
## 판 종류 (card.mode):
##   "tap"  — 어디를 눌러도 닫힘 (그 누름은 먹는다). 강조 사각은 보여 주기만
##   "pass" — 강조 사각(holes) 안의 누름만 아래 화면으로 넘긴다 (첫 두 행동 B1·B2와 A3·B7·C1). 바깥 누름은 먹는다. 상태가 바뀌면 다음 단계로
## 첫 실행 흐름 (phase): A1 → A2 → A3a → A3b → (안내 전투) B1 → B2 → B3 → B4 → B5 → B7 → C1 → C2 → C3. B6(크레딧 7)·D1~D6·T7·T8·T11은 처음 일어날 때 한 번.

signal resume_chosen(yes: bool)

const T := preload("res://proto/turn/t_theme.gd")
const PANEL_W := 300.0
const OFF_W := 60.0 ## "안내 끄기" 터치 목표 60×24
const OFF_H := 24.0
const HELP := Rect2(40, 34, 560, 296)
const HELP_CELL := Vector2(80, 26)
const HELP_RESET := Rect2(52, 290, 136, 32)
const HELP_CLOSE := Rect2(452, 290, 136, 32)
const SET := Rect2(150, 30, 340, 300)
const RESUME := Rect2(190, 104, 260, 132)
const RESUME_YES := Rect2(202, 186, 112, 36)
const RESUME_NO := Rect2(326, 186, 112, 36)

var stage: Node ## TStage
var phase := "" ## 첫 실행 흐름의 지금 단계 ("" = 없음)
var card := {} ## {id, title, body, holes: [Rect2], mode: "tap"|"pass", finger}
var mode := "" ## "" · help · settings · resume · resume_confirm · pause
var help_i := 0 ## 도움말에서 고른 용어
var resume_info := ""
var _t := 0.0
var _pass_press := false ## 이번 누름을 아래 화면으로 넘겼나 (떼기도 넘긴다)
var _card_t := 0.0 ## 판이 뜬 지 (뜨자마자 같은 손가락의 떼기로 닫히지 않게)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	_card_t += delta
	size = get_viewport_rect().size
	TSave.tick(delta)
	_update_flow()
	queue_redraw()


# ═══════════════════════════════════════════════════════════
# 바깥에서 부르는 것
# ═══════════════════════════════════════════════════════════

## 첫 실행 안내를 처음부터 (편성 화면 A1)
func begin() -> void:
	phase = "A1"
	card = {}


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


func _show(id: String, title: String, body: String, holes: Array, m: String, finger := false) -> void:
	card = {"id": id, "title": title, "body": body, "holes": holes, "mode": m, "finger": finger}
	_card_t = 0.0
	Sfx.play(&"tn_select", -14.0)


func _close_card() -> void:
	if card.is_empty():
		return
	var id := String(card.id)
	card = {}
	TSave.mark(id)
	if id == phase:
		phase = String({"A1": "A2", "A2": "A3a", "B3": "B4", "B4": "B5", "B5": "B7", "C2": "C3", "C3": ""}.get(id, phase))
		if id == "C3":
			TSave.mark("first_done")


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
		phase = "B7" # 안내 전투가 빨리 끝나면 남은 B 단계는 건너뜀
		card = {}
	match phase:
		"A1":
			if setup.visible and setup.step == 1 and card.is_empty():
				_show("A1", "마녀 셋으로 싸웁니다", "마녀마다 마법 4개와 대마법 1개를 들고 나갑니다. 지금 파티 그대로 바로 해 봐도 됩니다.", [Rect2(12, 34, 382, 300)], "tap")
		"A2":
			if setup.visible and setup.step == 1 and card.is_empty():
				_show("A2", "금빛 숫자는 크레딧", "마법을 쓰는 데 드는 값입니다. 크레딧은 전투에서 차례마다 모읍니다.", [setup._magic_btn(0).grow(3)], "tap")
		"A3a":
			if setup.visible and setup.step == 3:
				phase = "A3b"
				card = {}
			elif setup.visible and setup.step == 1:
				_keep("A3a", "첫 전투로 갑니다", "아래 버튼을 누르세요.", [TSetup.START1_RECT.grow(2)])
			else:
				card = {}
		"A3b":
			if in_battle:
				phase = "B1"
				card = {}
			elif setup.visible and setup.step == 3:
				_keep("A3b", "안내 전투", "짚 골렘 두 마리와 짧게 싸웁니다. 출격을 누르세요.", [TSetup.START1_RECT.grow(2), setup._battle_rect(0).grow(2)])
			elif setup.visible and setup.step == 1:
				phase = "A3a"
				card = {}
		"B1":
			if not in_battle:
				return
			if hud.state == "target" and hud.sel >= 0 and String(hud.slots[hud.sel].id) == "basic":
				phase = "B2"
				card = {}
			elif hud.state == "wheel" and hud.actor != null and not hud.slots.is_empty():
				_keep("B1", "%s의 차례" % hud.actor.unit.name, "칸을 한 번 누르면 설명, 한 번 더 누르면 사용합니다. 기본 공격은 크레딧을 +1 더 줍니다.", [hud.slot_rect(0)])
		"B2":
			if hud.state == "target":
				var holes: Array = []
				var e: TUnit = (hud.targets[0] as TActor).unit if not hud.targets.is_empty() else null
				if e != null:
					holes = [hud._card_rect(e), hud.body_rect(hud.targets[0])]
				_keep("B2", "누구를 칠까", "적을 누르세요. 불꽃 칸은 약점 — 불 공격이 1.5배 아픕니다. 빈 곳을 누르면 뒤로.", holes)
			elif hud.state == "wheel":
				phase = "B1"
				card = {}
			else:
				phase = "B3"
				card = {}
				hud.hint_once = "길게 누르면 자세히 — 적·마녀·카드를 0.4초"
		"B3", "B5":
			if in_battle and hud.state == "wheel" and hud.sel < 0 and hud.actor != null and card.is_empty() and stage.wheel_ready():
				if phase == "B3":
					var holes: Array = [hud._panel_rect(hud.actor.unit.slot)]
					for i in hud.slots.size():
						if not bool(hud.slots[i].empty) and bool(hud.slots[i].can) and i > 0 and not bool(hud.slots[i].ult):
							holes.append(hud.slot_rect(i))
					_show("B3", "크레딧이 모였습니다", "차례마다 +1. 금빛 숫자 칸은 지금 쓸 수 있는 마법, 빨간 숫자는 아직 모자랍니다.", holes, "tap")
				else:
					_show("B5", "차례 줄", "맨 왼쪽이 지금, 오른쪽으로 다음 차례입니다. 칸을 누르면 그 마녀·적이 빛납니다.", [hud.queue_box()], "tap")
		"B7":
			if hud.visible and hud.state == "banner" and hud.banner_text == "승리":
				_keep("B7", "이겼습니다", "이제 마법을 바꿔 나만의 빌드를 짜 봅니다. 화면을 누르세요.", [Rect2(0, 138, 640, 84)])
			elif setup.visible:
				phase = "C1" if TSave.intro_done else "A3a" # 안내 전투에서 지면 다시 출격부터
				card = {}
		"C1":
			if setup.visible and setup.step == 2:
				phase = "C2"
				card = {}
			elif setup.visible and setup.step == 1:
				var slot := maxi(TSetup.party().find("ignis"), 0)
				_keep("C1", "마법 장착", "마녀마다 마법 10개 중 4개를 골라 나갑니다. 눌러 보세요.", [setup._magic_btn(slot).grow(3)])
		"C2":
			if setup.visible and setup.step == 2 and card.is_empty():
				_show("C2", "한 번 누르면 설명, 다시 누르면 장착", "4개까지 장착합니다. 대마법(금빛 줄)은 바꿀 수 없습니다.", [Rect2(150, 38, 232, 166), TSetup.DESC], "tap")
		"C3":
			if setup.visible and setup.step == 2 and card.is_empty():
				_show("C3", "장비", "마녀마다 장비 하나. 편성 카드의 장비 칸을 누르면 목록이 열립니다. 강해지는 대신 대가가 있는 것도 있습니다.", [TSetup.EQUIP_ROW.grow(2)], "tap")


## 적 차례 앞 (TStage가 0.4초 대기 전에 부름): B4 "적의 다음 행동"
func on_enemy_turn(u: TUnit) -> void:
	if phase == "B4" and card.is_empty() and mode == "" and stage != null:
		var r: Rect2 = stage.hud._card_rect(u)
		_show("B4", "적의 다음 행동", "적 카드 왼쪽 위 글이 이 적이 다음에 할 일입니다. 강공격은 아픕니다.", [r.grow(2)], "tap")


## "pass" 판을 띄우거나 강조 사각만 새로 (자리가 바뀌는 화면 — 바퀴·카드)
func _keep(id: String, title: String, body: String, holes: Array) -> void:
	if card.is_empty() or String(card.id) != id:
		_show(id, title, body, holes, "pass", true)
	else:
		card.holes = holes


# ═══════════════════════════════════════════════════════════
# 입력
# ═══════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if not visible or (card.is_empty() and mode == ""):
		return
	var pos := Vector2.ZERO
	var pressed := false
	var is_press := false
	if event is InputEventScreenTouch:
		pos = event.position
		pressed = event.pressed
		is_press = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION:
		pos = event.position
		pressed = event.pressed
		is_press = true
	elif event is InputEventKey and event.pressed and not event.echo:
		if mode == "" and String(card.get("mode", "")) == "tap" and (event.is_action_pressed("es_jump") or event.is_action_pressed("es_attack")):
			_close_card()
			get_viewport().set_input_as_handled()
		elif mode in ["help", "settings", "pause"] and (event.is_action_pressed("es_attack") or event.is_action_pressed("es_exit") or event.is_action_pressed("es_jump")):
			mode = ""
			get_viewport().set_input_as_handled()
		return
	else:
		return
	if not pressed:
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


func _modal_press(p: Vector2) -> void:
	match mode:
		"pause":
			mode = ""
			Sfx.play(&"tn_confirm", -10.0)
		"help":
			for i in TData.GLOSSARY.size():
				if _help_cell(i).has_point(p):
					help_i = i
					Sfx.play(&"tn_select", -12.0)
					return
			if HELP_RESET.has_point(p):
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
		"resume_confirm":
			if RESUME_YES.has_point(p):
				mode = ""
				resume_chosen.emit(false)
			elif RESUME_NO.has_point(p):
				mode = "resume"
				Sfx.play(&"tn_cancel", -10.0)


# ═══════════════════════════════════════════════════════════
# 설정 (review_F F12 · review_G G18): 효과음 · 흔들림 · 번쩍임 · 큰 글자 · 안내 다시 보기 · 도움말 · 타이틀로
# ═══════════════════════════════════════════════════════════

func _set_row(i: int) -> Rect2:
	return Rect2(SET.position.x + 12, SET.position.y + 36 + 38 * i, SET.size.x - 24, 32)


func _set_btn(i: int, right: bool) -> Rect2:
	var r := _set_row(i)
	return Rect2(r.end.x - (44.0 if right else 168.0), r.position.y, 44, 32) if i == 0 else Rect2(r.end.x - 96.0, r.position.y, 96, 32)


func _set_half(i: int, right: bool) -> Rect2:
	var r := _set_row(i)
	return Rect2(r.position.x + (r.size.x * 0.5 + 4.0 if right else 0.0), r.position.y, r.size.x * 0.5 - 4.0, 32)


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
	elif _set_half(4, false).has_point(p):
		TSave.reset_tips()
		mode = ""
		begin()
	elif _set_half(4, true).has_point(p):
		mode = "help"
	elif _set_half(5, false).has_point(p):
		mode = ""
		if stage != null:
			stage._exit()
	elif _set_half(5, true).has_point(p) or not SET.has_point(p):
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
		"help": _draw_help()
		"settings": _draw_settings()
		"resume", "resume_confirm": _draw_resume()
		"pause": _draw_pause()


## 덮개(INK 0.6, 강조 사각만 뚫림) · 강조 금테(1.2초 숨쉬기) · 손가락 ▼ · 판 (제목 12 · 본문 10/12 · 안내 끄기)
func _draw_card() -> void:
	var holes: Array = card.holes
	var dim: Array = [Rect2(Vector2.ZERO, size)]
	for h: Rect2 in holes:
		dim = _subtract(dim, h)
	for r: Rect2 in dim:
		draw_rect(r, Color(T.INK, 0.6))
	var br := 0.6 + 0.4 * (0.5 + 0.5 * sin(_t * TAU / 1.2))
	for h: Rect2 in holes:
		draw_rect(h.grow(1), Color(T.GOLD, br), false, 2.0)
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
	var pr := _card_rect()
	T.panel(self, pr, Color(T.PANEL, 0.96), Color(T.LINE, 0.9), 1, 4)
	draw_rect(Rect2(pr.position + Vector2(1, 1), Vector2(3, pr.size.y - 2)), T.GOLD)
	T.text(self, pr.position + Vector2(12, 18), String(card.title), 12, T.GOLD)
	T.wrap(self, pr.position + Vector2(12, 34), String(card.body), pr.size.x - 22.0, T.body_fs(), T.TEXT, T.body_lh())
	var off := _off_rect()
	T.text(self, Vector2(off.end.x - 6, off.end.y - 7), "안내 끄기", 8, T.TEXT_OFF, HORIZONTAL_ALIGNMENT_RIGHT, 0)
	if String(card.mode) == "tap":
		T.text(self, Vector2(pr.position.x + 12, pr.end.y - 7), "눌러서 닫기", 8, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_LEFT, 0)


## 판 자리: 강조 사각 반대쪽 (아래 → 위 → 오른쪽 → 왼쪽 중 화면 안에 들어가고 강조와 안 겹치는 첫 자리)
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
	var cands: Array = [Rect2(cx, u.end.y + 10.0, w, h), Rect2(cx, u.position.y - h - 10.0, w, h)]
	var rw := minf(w, size.x - u.end.x - 14.0)
	if rw >= 180.0:
		var rh := _card_h(rw)
		cands.append(Rect2(u.end.x + 8.0, clampf(u.get_center().y - rh * 0.5, 34.0, size.y - rh - 6.0), rw, rh))
	var lw := minf(w, u.position.x - 14.0)
	if lw >= 180.0:
		var lh2 := _card_h(lw)
		cands.append(Rect2(u.position.x - lw - 8.0, clampf(u.get_center().y - lh2 * 0.5, 34.0, size.y - lh2 - 6.0), lw, lh2))
	for c: Rect2 in cands:
		if c.position.y >= 32.0 and c.end.y <= size.y - 4.0 and c.position.x >= 4.0 and c.end.x <= size.x - 4.0:
			var hit := false
			for hh: Rect2 in holes:
				if c.intersects(hh):
					hit = true
			if not hit:
				return c
	return Rect2(cx, clampf(u.end.y + 10.0, 32.0, size.y - h - 4.0), w, h)


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


func _help_cell(i: int) -> Rect2:
	return Rect2(HELP.position.x + 12 + (HELP_CELL.x + 4) * float(i % 3), HELP.position.y + 34 + (HELP_CELL.y + 4) * float(i / 3), HELP_CELL.x, HELP_CELL.y)


func _draw_help() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(T.INK, 0.55))
	T.panel(self, HELP, Color(T.PANEL, 0.98), Color(T.LINE, 0.9), 1, 4)
	T.text(self, HELP.position + Vector2(12, 22), "도움말 — 용어", 15, T.TEXT)
	T.text(self, HELP.end - Vector2(12, HELP.size.y - 21), "눌러서 풀이", 10, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_RIGHT)
	for i in TData.GLOSSARY.size():
		var r := _help_cell(i)
		var on := i == help_i
		T.panel(self, r, Color(T.PANEL_HI, 1.0) if on else Color(T.INK, 0.7), T.GOLD if on else Color(T.LINE, 0.4), 2 if on else 1, 3)
		T.text(self, r.get_center() + Vector2(0, 4), String(TData.GLOSSARY[i][0]), 10, T.GOLD if on else T.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	var x := HELP.position.x + 12 + (HELP_CELL.x + 4) * 3.0 + 10.0
	var w := HELP.end.x - x - 14.0
	draw_rect(Rect2(x - 8, HELP.position.y + 34, 1, 248), Color(T.LINE, 0.3))
	var g: Array = TData.GLOSSARY[clampi(help_i, 0, TData.GLOSSARY.size() - 1)]
	T.text(self, Vector2(x, HELP.position.y + 50), String(g[0]), 15, T.GOLD)
	T.wrap(self, Vector2(x, HELP.position.y + 72), String(g[1]), w, T.body_fs(), T.TEXT, T.body_lh())
	_btn(HELP_RESET, "안내 다시 보기", false)
	_btn(HELP_CLOSE, "닫기", true)


func _btn(r: Rect2, label: String, main: bool) -> void:
	T.panel(self, r, Color(T.LINE, 0.8) if main else Color(T.INK, 0.85), Color(T.TEXT, 0.9) if main else Color(T.TEXT_OFF, 0.9), 1, 3)
	T.text(self, r.get_center() + Vector2(0, 5), label, 12, T.INK if main else T.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 0 if main else -1)


func _draw_settings() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(T.INK, 0.55))
	T.panel(self, SET, Color(T.PANEL, 0.98), Color(T.LINE, 0.9), 1, 4)
	T.text(self, SET.position + Vector2(12, 22), "설정", 15, T.TEXT)
	var gs := GameState
	var rows := [["효과음", ""], ["화면 흔들림", "켬" if bool(gs.settings.get("shake", true)) else "끔"], ["번쩍임 (광과민)", "켬" if bool(gs.settings.get("flash", true)) else "끔"],
		["큰 글자", "켬" if TSave.big_text else "끔"]]
	for i in rows.size():
		var r := _set_row(i)
		T.text(self, r.position + Vector2(0, 20), String(rows[i][0]), 12, T.TEXT)
		if i == 0:
			var lv := clampi(int(round(float(gs.settings.sfx) * 5.0)), 0, 5)
			_btn(_set_btn(0, false), "−", false)
			_btn(_set_btn(0, true), "+", false)
			for k in 5:
				var c := Rect2(_set_btn(0, false).end.x + 6 + 13 * k, r.position.y + 11, 10, 10)
				draw_rect(c, T.GOLD if k < lv else T.EMPTY)
		else:
			var on := String(rows[i][1]) == "켬"
			_btn(_set_btn(i, false), String(rows[i][1]), on)
	_btn(_set_half(4, false), "안내 다시 보기", false)
	_btn(_set_half(4, true), "도움말 (용어)", false)
	_btn(_set_half(5, false), "타이틀로", false)
	_btn(_set_half(5, true), "닫기", true)
	if not TSave.persistent():
		T.text(self, Vector2(SET.get_center().x, SET.end.y - 8), "이 브라우저에서는 저장되지 않습니다", 10, T.TEXT_OFF, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_resume() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(T.INK, 0.7))
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
		T.panel(self, RESUME_YES, Color(T.DANGER, 0.85), Color(T.TEXT, 0.8), 1, 3)
		T.text(self, RESUME_YES.get_center() + Vector2(0, 5), "버리기", 12, T.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		_btn(RESUME_NO, "취소", false)


func _draw_pause() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(T.INK, 0.6))
	var r := Rect2(220, 140, 200, 72)
	T.panel(self, r, Color(T.PANEL, 0.98), Color(T.LINE, 0.9), 1, 4)
	T.text(self, Vector2(320, 172), "멈춤", 15, T.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	T.text(self, Vector2(320, 194), "눌러서 계속", 10, T.TEXT_SUB, HORIZONTAL_ALIGNMENT_CENTER)
