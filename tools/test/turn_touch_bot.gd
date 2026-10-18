extends Node
## 첫 플레이 터치 봇 (scenarios/turn_firstplay.json — review_G_firstplay.md §4.8): 저장 없는 첫 실행에서 **화면 터치만으로**
## 안내 A부(편성) → 안내 전투 B부 → 첫 승리 뒤 C부 → 일반 전투 시작까지 간다. 입력은 전부 InputEventScreenTouch (누름 → 다음 프레임 뗌).
## 무엇을 누를지는 화면이 보여 주는 것으로 정한다: 안내 판이 있으면 그 판(눌러 닫기) 또는 강조 사각(눌러야 할 곳),
## 바퀴가 열리면 TAuto.pick(= 잘하는 사람)이 고른 칸 → 다시 그 칸 → 대상(적 카드·아군 패널). 사람처럼 누름 사이 0.35초.
## 안내 판이 처음 뜰 때마다 스크린샷 g_<id>, 끝에 n00_normal_start. 출력: "FIRSTPLAY …" 줄.

const THINK := 0.35

var stage: Node
var _cool := 1.0
var _release := false
var _shots := {}
var _taps := 0
var _plan := {} ## 이번 마녀 차례 {slot, target: TUnit, step}
var _plan_turn := -1
var _t := 0.0
var _intro_t0 := -1.0
var _done := false


func _ready() -> void:
	stage = get_parent()
	print("FIRSTPLAY start first_run=", TSave.first_run(), " phase=", stage.guide.phase)


func _process(delta: float) -> void:
	_t += delta
	if _release:
		_release = false
		var up := InputEventScreenTouch.new()
		up.index = 0
		up.pressed = false
		up.position = _last
		Input.parse_input_event(up)
		return
	if _done:
		return
	var g: TGuide = stage.guide
	if not g.card.is_empty() and not _shots.has("g_" + String(g.card.id)):
		_shot("g_" + String(g.card.id))
	if stage.hud.visible and stage.hud.msg.contains("길게") and not _shots.has("b2_hint"):
		_shot("b2_hint")
	_cool -= delta
	if _cool > 0.0:
		return
	_cool = THINK
	# 1) 모달
	if g.mode == "resume":
		_tap(TGuide.RESUME_YES.get_center())
		return
	if g.mode in ["pause", "help", "settings"]:
		_tap(Vector2(320, 340) if g.mode != "pause" else Vector2(320, 180))
		return
	# 2) 안내 판
	if not g.card.is_empty():
		if String(g.card.mode) == "tap":
			_tap(g._card_rect().get_center() + Vector2(-40, 0))
		else:
			var h: Rect2 = g.card.holes[0]
			_tap(h.get_center())
		return
	# 3) 편성 화면
	var setup: TSetup = stage.setup
	if setup.visible:
		match setup.step:
			1: _tap(TSetup.START1_RECT.get_center())
			2: _tap(TSetup.START_RECT.get_center())
			3:
				var ids := TSetup.battle_ids()
				var want := "normal_01" if ids.has("normal_01") else String(ids[0])
				if TSetup.battle_pick != want:
					_tap(setup.pick_rect_for(want).get_center())
				else:
					_tap(TSetup.START1_RECT.get_center())
		return
	# 4) 전투
	var hud: THud = stage.hud
	if not hud.visible or stage.battle == null:
		return
	if stage.battle_id == "intro_01" and _intro_t0 < 0.0:
		_intro_t0 = _t
	if stage.battle_id == "normal_01" and hud.state == "wheel":
		_shot("n00_normal_start")
		print("FIRSTPLAY done intro_sec=%.1f taps=%d tips=%s phase='%s' cleared=%s setup_file=%s" % [_t - _intro_t0, _taps, str(TSave.tips.keys()), g.phase, str(TSave.cleared), str(FileAccess.file_exists(TSave.dir.path_join(TSave.SETUP_FILE)))])
		_done = true
		get_tree().quit.call_deferred()
		return
	if hud.state == "banner":
		_tap(Vector2(320, 180))
		return
	if not (hud.state == "wheel" or hud.state == "target") or hud.actor == null:
		return
	var b: TBattle = stage.battle
	if _plan_turn != b.turn_no:
		var a := TAuto.pick(b, hud.actor.unit)
		var sid := "basic" if String(a.kind) == "basic" else String(a.skill)
		var si := 0
		for i in hud.slots.size():
			if String(hud.slots[i].id) == sid:
				si = i
		_plan = {"slot": si, "target": a.get("target"), "step": 0}
		_plan_turn = b.turn_no
	match int(_plan.step):
		0, 1:
			_tap(hud.slots[int(_plan.slot)].pos)
			_plan.step = int(_plan.step) + 1
		_:
			if hud.state == "target":
				var t: TUnit = _plan.target
				if t == null or not hud.targets.has(hud.actors.get(t)):
					t = (hud.targets[0] as TActor).unit
				_tap(hud._panel_rect(t.slot).get_center() if t.is_witch() else hud._card_rect(t).get_center())
			else:
				_plan.step = 0 # 아직 바퀴면 처음부터 (칸이 바뀐 경우)


var _last := Vector2.ZERO


func _tap(p: Vector2) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = 0
	ev.pressed = true
	ev.position = p
	_last = p
	Input.parse_input_event(ev)
	_release = true
	_taps += 1


func _shot(name: String) -> void:
	_shots[name] = true
	var out = get_tree().get("outdir")
	if out == null or String(out) == "":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(String(out).path_join(name + ".png"))
	print("FIRSTPLAY shot ", name, " t=%.1f" % _t)
