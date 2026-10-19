class_name TStage
extends Node2D
## 턴제 전투 프로토타입 장면 (웹 주소 끝 ?turn). docs/eska-turn/combat_proto.md.
## 편성(TSetup) → 전투(TBattle 규칙 + TActor 그림 + THud 표시 + TFx 연출) → 승리(편성으로) / 패배(바로 다시).
## 전투는 코루틴 _run()이 돈다: 다음 차례 → 마녀면 바퀴에서 고르기를 기다림 / 적이면 의도대로 → 연출의 맞는 시각에 피해·숫자 → 다음.
## 배경·마녀·적은 모두 코드 그림. Esc 또는 오른쪽 위 X → 철수 확인 → 편성. 전투는 편성의 "전투 고르기"(S-03)에서 고른다.
## 첫 플레이 안내·도움말·설정·이어하기·멈춤은 TGuide(맨 위 층), 저장은 TSave (combat_proto.md §28).

const ArenaScript := preload("res://proto/p_arena.gd")
const WITCH_AT: Array[Vector2] = [Vector2(222, 288), Vector2(160, 258), Vector2(98, 228)] ## 앞 · 중 · 뒤 (대각선, 아래 띠 y 302 위) — 간격 62 (review_D C1: 54면 모자 챙이 겹쳤다)
const ENEMY_AT: Array[Vector2] = [Vector2(424, 290), Vector2(507, 256), Vector2(590, 222)] ## 적 1명 = 가운데 · 2명 = 앞·뒤 (THud.pos_index). 간격 83 (review_C2 L11)
## 보스 + 졸개 웨이브 (잿빛 둥지어미, review_K K-09): 보스는 뒤 오른쪽 · 졸개는 보스 몸 바깥 왼쪽 앞·뒤 — 졸개가 보스 머리·가시를 가리던 것
const BOSS_MIX_AT := Vector2(554, 254)
const MINION_AT: Array[Vector2] = [Vector2(440, 300), Vector2(386, 234)]

var battle: TBattle
var actors := {} ## TUnit → TActor
var hud: THud
var setup: TSetup
var cam: Camera2D
var units_node: Node2D
var _run_id := 0
var _in_battle := false
var _hud_layer: CanvasLayer
var _setup_layer: CanvasLayer
var stats := {"turns": 0, "biggest": 0} ## 시험용
var battle_id: String = TData.BATTLE.battle ## 전투 데이터 id (TData.BATTLES)
var _bg: TBackdrop
var auto := false ## 시험용 자동 플레이: 바퀴를 잠깐 보여 준 뒤 간단한 규칙으로 고른다 (tools/test/scenarios/turn_*.json)
var guide: TGuide
var _guide_layer: CanvasLayer
var _snap := {} ## 지금 마녀 차례가 시작될 때의 전투 사본 (이어하기 — 창이 가려지면 이것을 쓴다)
var _witch_turns := 0 ## 이 전투의 마녀 차례 수 (5차례마다 저장)
var _wave_new := true ## 웨이브의 첫 마녀 차례 (저장)
## 진 이유를 고르는 기록 (review_F F13): 필살기로 쓰러진 마녀 · 관통 · 해제된 버프 · 회복 횟수 · 가장 큰 받은 피해
var _why := {}
var _flags := {} ## 처음 일어난 일 안내용 (broke · resist)
var turn_only := false ## 웹 주소가 ?turn (턴제만) — 설정의 "타이틀로"(옛 실시간판)를 숨김 (review_I I-21)
var _page_cb: JavaScriptObject ## 웹: 문서 visibilitychange·pagehide를 받는 콜백 (review_I I-01 — 지우지 않게 붙잡아 둔다)
var _froze := false ## 판 때문에 시간을 멈췄나
var _scale_was := [] ## 들어오기 전 창 배율 [aspect, stretch] — 나갈 때 되돌림 (세라·실시간판은 정수 배율 그대로)
var _probe_cb: JavaScriptObject ## 웹 시험(주소에 probe): window.eskaProbe() → window.eskaState (tools/test/web_turn.mjs)
var _setup_theme := "" ## 편성 화면 뒤 배경 테마 (넓은 화면 양옆 띠에 비침 — 고른 전투의 첫 웨이브, R3 review_N N-05)


func _exit_tree() -> void:
	TTheme.release()
	if not _scale_was.is_empty():
		var win := get_tree().root
		win.content_scale_aspect = _scale_was[0]
		win.content_scale_stretch = _scale_was[1]
	if _page_cb != null:
		JavaScriptBridge.get_interface("document").removeEventListener("visibilitychange", _page_cb)
		JavaScriptBridge.get_interface("window").removeEventListener("pagehide", _page_cb)
		_page_cb = null
	_probe_cb = null


func _ready() -> void:
	EKeys.register()
	TSave.source = func() -> Dictionary: return {"state": TSetup.state, "pick": TSetup.battle_pick}
	TSave.load_all() # 편성 화면을 만들기 전에 (편성 그림이 저장된 편성으로)
	if not TSave.loaded.is_empty():
		TSetup.state = TSave.loaded.state
		TSetup.battle_pick = String(TSave.loaded.pick)
		TSave.loaded = {}
	Engine.time_scale = 1.0
	get_tree().paused = false
	Fx.reset()
	# 폰 가로 화면을 꽉 채운다 (review_K K-01): 정수 배율 + 고정 화면비는 20:9 폰에서 좌우 20%를 검은 띠로 버렸다.
	# 높이 360 기준 소수 배율 + 화면비 확장 → 넓은 화면은 논리 폭이 늘고(20:9 ≈ 800), 640×360 설계 화면은 가운데(TTheme.ofs)
	var win := get_tree().root
	_scale_was = [win.content_scale_aspect, win.content_scale_stretch]
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	win.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	TTheme.sync_view(get_viewport())
	var bg := TBackdrop.new()
	add_child(bg)
	_bg = bg
	units_node = Node2D.new()
	units_node.name = "Units"
	units_node.z_index = 0
	add_child(units_node)
	var fx := Node2D.new()
	fx.name = "Effects"
	fx.z_index = 0
	add_child(fx)
	cam = ArenaScript.PCamera.new()
	cam.position_smoothing_enabled = false
	add_child(cam)
	cam.global_position = Vector2(320, 180)
	cam.reset_smoothing()
	_hud_layer = CanvasLayer.new()
	_hud_layer.layer = 20
	add_child(_hud_layer)
	hud = THud.new()
	hud.stage = self
	_hud_layer.add_child(hud)
	hud.exit_tapped.connect(_on_hud_exit)
	hud.banner_tapped.connect(_on_banner)
	_setup_layer = CanvasLayer.new()
	_setup_layer.layer = 30
	add_child(_setup_layer)
	setup = TSetup.new()
	_setup_layer.add_child(setup)
	setup.start_pressed.connect(_on_setup_start)
	setup.exit_pressed.connect(_exit)
	_guide_layer = CanvasLayer.new()
	_guide_layer.layer = 40
	add_child(_guide_layer)
	guide = TGuide.new()
	guide.stage = self
	_guide_layer.add_child(guide)
	guide.resume_chosen.connect(_on_resume_chosen)
	setup.guide = guide
	hud.help_tapped.connect(guide.open_help)
	hud.visible = false
	_place_layers()
	Music.stop(0.3) # 다른 게임(세라 실시간판)의 곡이 턴제 내내 돌던 것 — 전투 음악은 아직 [확정 22-2 A] (review_K K-02 · 총괄 결정 ③)
	if OS.has_feature("web"):
		var q: Variant = JavaScriptBridge.eval("window.location.search", true)
		TSetup.dev = q is String and String(q).contains("dev")
		turn_only = q is String and String(q).contains("turn")
		# 창 focus out(캔버스 blur)이 안 오고 탭이 바로 가려지는 경우(앱 전환·화면 끔)도 받는다 (review_I I-01)
		_page_cb = JavaScriptBridge.create_callback(_on_page_event)
		JavaScriptBridge.get_interface("document").addEventListener("visibilitychange", _page_cb)
		JavaScriptBridge.get_interface("window").addEventListener("pagehide", _page_cb)
		if q is String and String(q).contains("probe"):
			_probe_cb = JavaScriptBridge.create_callback(_on_probe)
			JavaScriptBridge.get_interface("window").eskaProbe = _probe_cb
	setup.back_to_roster()
	if TSave.has_battle():
		var d := TSave.load_battle()
		if d.is_empty():
			TSave.clear_battle()
		else:
			var bd: Dictionary = TData.BATTLES[String(d.battle_id)]
			var info := String(bd.name)
			if (bd.waves as Array).size() > 1:
				info += " · 웨이브 %d/%d" % [int(d.wave_i) + 1, (bd.waves as Array).size()]
			guide.ask_resume(info + " · 차례 %d" % int(d.turn_no))
	if guide.mode == "" and not TSave.tips_off and not TSave.intro_done:
		if TSave.first_run():
			TSave.hold = true # 안내를 끝내거나 끌 때 처음 저장 (review_G §5.2)
		guide.begin()


func _process(_delta: float) -> void:
	if TTheme.sync_view(get_viewport()):
		_place_layers()
	if not _in_battle and setup.visible:
		var th := battle_theme(TSetup.battle_pick, 0)
		if th != _setup_theme:
			_bg.set_theme(th, _setup_theme == "")
			_setup_theme = th
	elif _in_battle:
		_setup_theme = ""
	# 철수 확인·도움말·설정·멈춤 판이 열려 있으면 전투 시간을 멈춘다 — 판 뒤에서 숫자·웨이브 전환이 흘렀다 (review_K K-22)
	var modal := _in_battle and (hud.confirm_open or guide.mode in ["help", "settings", "pause"])
	if modal:
		Engine.time_scale = 0.0
		_froze = true
	elif _froze:
		_froze = false
		Engine.time_scale = 1.0


## 턴제 캔버스 층(HUD·대마법 연출·편성·안내)을 설계 화면 자리(TTheme.ofs)로 — 카메라(320, 180)가 전장을 가운데에 두는 것과 같은 자리
func _place_layers() -> void:
	for l: CanvasLayer in [_hud_layer, _setup_layer, _guide_layer, get_node_or_null("UltLayer")]:
		if l != null:
			l.offset = TTheme.ofs


func _exit() -> void:
	Fx.reset()
	TSave.save_setup()
	GameState.go_title()


## 진입 판: 이어 하기 → 저장한 차례부터 · 버리기 → 지움
func _on_resume_chosen(yes: bool) -> void:
	if yes:
		resume_battle()
	else:
		TSave.clear_battle()
		Sfx.play(&"tn_cancel", -8.0)


## 시험용: 새로 켠 것처럼 (메모리의 편성을 잊고 장면을 다시 연다 — 파일에서 다시 읽음)
func test_relaunch() -> void:
	TSave.forget()
	TSetup.state = {}
	TSetup.battle_pick = TData.BATTLE.battle
	get_tree().reload_current_scene.call_deferred()


## 시험용: 화면 좌표 p를 손가락으로 한 번 누르고 뗀다 (runner의 touch와 같은 입력 — 좌표를 식으로 구할 때)
func test_touch(p: Vector2) -> void:
	var ev := InputEventScreenTouch.new()
	ev.pressed = true
	ev.position = p
	Input.parse_input_event(ev)
	var up := InputEventScreenTouch.new()
	up.pressed = false
	up.position = p
	Input.parse_input_event.call_deferred(up)


## 시험용: 저장 파일·편성 한 줄
func test_files() -> String:
	var fs: Array = []
	for f in [TSave.SETUP_FILE, TSave.TIPS_FILE, TSave.BATTLE_FILE]:
		if FileAccess.file_exists(TSave.dir.path_join(f)):
			fs.append(f)
	var p := TSetup.party()
	return "files=%s party=%s equip0=%s pick=%s phase='%s' mode='%s' cleared=%s" % [str(fs), str(p), String(TSetup.state[String(p[0])].equip), TSetup.battle_pick, guide.phase, guide.mode, str(TSave.cleared)]


## 시험용: 창이 가려짐 (F07 규칙 4)
func test_focus_out() -> void:
	_notification(NOTIFICATION_APPLICATION_FOCUS_OUT)


## 창이 가려지면(전화·알림·탭 전환) 지금 마녀 차례의 사본을 쓰고 멈춤 판 (F07 규칙 4 · review_G §5.2)
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_hidden()


## 웹 문서 이벤트: visibilitychange(가려짐) · pagehide → 멈출 때와 같이 저장 (localStorage는 이 안에서 동기로 쓰임)
func _on_page_event(_args: Array) -> void:
	var st: Variant = JavaScriptBridge.eval("document.visibilityState", true)
	if String(st) == "hidden" or (not _args.is_empty() and _args[0] is JavaScriptObject and String((_args[0] as JavaScriptObject).type) == "pagehide"):
		_hidden()


func _hidden() -> void:
	if _in_battle and TSave.enabled and guide != null:
		if not _snap.is_empty() and battle_id != "intro_01":
			TSave.save_battle(_snap)
		guide.pause()


## 웹 시험용 상태 (window.eskaState, JSON): 화면 배율·설계 화면 자리(ofs)·지금 화면·누를 자리(설계 좌표). web_turn.mjs가 CSS 좌표로 바꿔 누른다
func _on_probe(_args: Array) -> void:
	var xf := get_tree().root.get_final_transform()
	var d := {"scale": xf.x.x, "origin": [xf.origin.x, xf.origin.y], "ofs": [TTheme.ofs.x, TTheme.ofs.y], "view": [TTheme.view.x, TTheme.view.y],
		"in_battle": _in_battle, "hud_state": hud.state, "sel": hud.sel, "setup_step": setup.step, "setup_visible": setup.visible,
		"guide_mode": guide.mode, "phase": guide.phase, "card": String(guide.card.get("id", "")), "last_press": hud.last_press,
		"turn": battle.turn_no if battle != null else 0, "banner": hud.banner_text, "confirm": hud.confirm_open}
	var r2a := func(r: Rect2) -> Array: return [r.position.x, r.position.y, r.size.x, r.size.y]
	d["off"] = r2a.call(guide._off_rect())
	d["portrait"] = guide.portrait # 폰 웹 전체 화면·세로 안내 (R3, review_N N-02)
	d["fs_web"] = guide.fs_web
	d["fs_tried"] = guide.fs_tried
	d["fs_is"] = guide.fs_is
	d["fs_btn"] = r2a.call(guide.fs_btn())
	d["start1"] = r2a.call(TSetup.START1_RECT)
	if _in_battle and battle != null:
		var slots: Array = []
		for i in hud.slots.size():
			slots.append(r2a.call(hud.slot_rect(i)))
		d["slots"] = slots
		var cards: Array = []
		for e in battle.enemies:
			cards.append(r2a.call(hud._card_rect(e)) if e.alive else [])
		d["cards"] = cards
		var bodies: Array = []
		for e in battle.enemies:
			bodies.append(r2a.call(hud.body_rect(actors[e])) if e.alive and actors.has(e) else [])
		d["bodies"] = bodies
		d["x_rect"] = r2a.call(hud.x_rect())
	JavaScriptBridge.get_interface("window").eskaState = JSON.stringify(d)


func wheel_ready() -> bool:
	return _in_battle and hud.state == "wheel"


func _on_hud_exit() -> void:
	_to_setup()


## 전투를 접고 편성으로
func _to_setup() -> void:
	_run_id += 1
	_in_battle = false
	TSave.clear_battle() # 철수·승리 뒤 (F07 규칙 2)
	_snap = {}
	Engine.time_scale = 1.0
	hud.visible = false
	hud.close_wheel()
	hud.clear_banner()
	for u in actors:
		(actors[u] as TActor).queue_free()
	actors.clear()
	for c in get_node("Effects").get_children():
		c.queue_free()
	var ul := get_node_or_null("UltLayer")
	if ul != null:
		for c in ul.get_children():
			c.queue_free()
	hud.modulate.a = 1.0
	setup.back_to_roster()
	setup.visible = true


## 편성의 전투 고르기(S-03)에서 "출격"
func _on_setup_start() -> void:
	battle_id = TSetup.battle_pick
	start_battle()


func start_battle() -> void:
	TSetup.ensure_state()
	battle = TBattle.new()
	battle.setup(TSetup.party(), battle_id, TSetup.state)
	TSave.clear_battle()
	_why = {"fin_kills": 0, "pierce_kills": 0, "dispelled": 0, "heals": 0, "guard": 0, "big": {}}
	_witch_turns = 0
	_begin_battle()


## 끊긴 전투를 저장한 마녀 차례부터 (F07 규칙 2): 크레딧 +1은 저장 전에 받았으므로 다시 주지 않는다
func resume_battle() -> void:
	var d := TSave.load_battle()
	if d.is_empty():
		TSave.clear_battle()
		return
	battle = TBattle.from_dict(d)
	battle_id = battle.battle_id
	TSetup.battle_pick = battle_id
	var ex: Dictionary = d.get("stage", {})
	_why = ex.get("why", {"fin_kills": 0, "pierce_kills": 0, "dispelled": 0, "heals": 0, "guard": 0, "big": {}})
	_witch_turns = int(ex.get("witch_turns", 0))
	_begin_battle()
	for u in actors:
		if not u.alive:
			(actors[u] as TActor).set_down(true)
	hud.show_msg("이어 하기 — 차례 %d" % battle.turn_no, TTheme.GOLD)


func _begin_battle() -> void:
	setup.visible = false
	hud.visible = true
	for u in actors:
		(actors[u] as TActor).queue_free()
	actors.clear()
	for i in battle.witches.size():
		_add_actor(battle.witches[i], WITCH_AT[i])
	_add_enemies()
	_bg.set_theme(_wave_theme(), true)
	var pools: Array = []
	for i in battle.witches.size():
		pools.append([WITCH_AT[i], TData.ELEMENT_COLOR.get((battle.witches[i] as TUnit).element, Color("#b9a2ff"))])
	_bg.set_pools(pools) # 마녀 발밑 빛 원 (검토 O §3)
	_bg_tint(true)
	hud.bind(battle, actors)
	stats = {"turns": 0, "biggest": 0}
	_flags = {}
	_snap = {}
	_wave_new = true
	_in_battle = true
	_run_id += 1
	_run(_run_id)


func _add_actor(u: TUnit, at: Vector2) -> void:
	var a := TActor.new()
	units_node.add_child(a)
	a.setup(u, at)
	a.z_index = 1 + int((at.y - 218.0) / 25.0) # 앞(아래)이 위에 그려짐 (1~3)
	if not u.is_witch():
		# 키 큰 적(뒤 칸 재의 기사)은 머리 꼭대기가 적 카드 밑 + 18(HEAD_MIN_Y + 8)보다 위면 그만큼 내려 세움 — 투구를 카드가 덮고
		# 대상 고르기의 머리 위 의도 아이콘이 투구 위에 겹쳤다 (R3, review_N N-06 [제안]). 카드는 위 띠 밑 한 줄 고정이라 옮길 자리가 없다.
		# R4: DIMS 키를 실제 투구 꼭대기에 맞추며 상한 24 → 48 · 큰 글자면 카드가 8px 길어 그만큼 더 (뒤 칸 재의 기사 222 → 262 · 큰 글자 270)
		var dy := clampf(THud.HEAD_MIN_Y + (8.0 if TTheme.big else 0.0) + 8.0 - a.head().y, 0.0, 48.0)
		if dy > 0.0:
			a.home.y += dy
			a.position.y += dy
	actors[u] = a


## 지금 웨이브의 적을 세운다: 1명 = 가운데(10px 아래 — 큰 보스 머리가 보스 카드 밑에 들어가지 않게) · 2명 = 앞·뒤 · 3명 = 앞·중·뒤
func _add_enemies() -> void:
	for i in battle.enemies.size():
		_add_actor(battle.enemies[i], enemy_spot(battle.enemies, i))


## 적 i가 서는 자리: 보스와 졸개가 같이 있으면 BOSS_MIX_AT·MINION_AT, 아니면 ENEMY_AT[pos_index] (1명이면 10px 아래)
static func enemy_spot(es: Array, i: int) -> Vector2:
	var n := es.size()
	if THud.boss_mix(es):
		if (es[i] as TUnit).boss:
			return BOSS_MIX_AT
		return MINION_AT[clampi(THud.minion_index(es, i), 0, MINION_AT.size() - 1)]
	return ENEMY_AT[THud.pos_index(n, i)] + (Vector2(0, 10) if n == 1 else Vector2.ZERO)


func _wait(sec: float) -> void:
	if sec <= 0.0:
		return
	await get_tree().create_timer(sec).timeout


# ═══════════════════════════════════════════════════════════
# 전투 흐름
# ═══════════════════════════════════════════════════════════

func _run(token: int) -> void:
	await _wait(0.5)
	Sfx.play(&"tn_bless", -10.0)
	if not battle.resume:
		var bd: Dictionary = TData.BATTLES.get(battle_id, {})
		var nm := String(bd.get("name", ""))
		hud.start_banner(nm.substr(nm.find(" — ") + 3) if nm.find(" — ") >= 0 else nm, "웨이브 1/%d" % battle.wave_count() if battle.wave_count() > 1 else "")
	await _wait(0.8 if not battle.resume else 0.6)
	while token == _run_id and is_inside_tree():
		while (hud.confirm_open or guide.busy()) and token == _run_id: # 철수 확인 판 · 안내 판 · 도움말 · 멈춤 동안 차례 사이에서 멈춤
			await _wait(0.1)
		if token != _run_id:
			return
		var u := battle.next_actor()
		if u == null:
			return
		hud.refresh()
		var a: TActor = actors[u]
		if u.stunned:
			# 기절로 쉬는 차례 (§17.2): 행동 없음, 0.6초
			battle.rest(u)
			hud.show_msg("%s — 기절 — 쉼" % u.name, TTheme.STUN)
			hud.pop(u, "기절 — 쉼", "status")
			await _wait(0.6)
		elif u.is_witch():
			a.set_turn(true)
			hud.open_wheel(a)
			_turn_snapshot()
			_turn_tips(u)
			var action: Dictionary
			if auto:
				await _wait(0.5)
				if token != _run_id:
					return
				action = _auto_pick(a)
				hud.close_wheel()
			else:
				action = await hud.chosen
			if token != _run_id:
				return # 철수·다시 시작으로 이 전투가 끝났다 (그림 a는 이미 지워졌을 수 있다 — 다음 전투의 고르기에 깨어나도 건드리지 않음)
			a.set_turn(false)
			stats.turns = int(stats.turns) + 1
			await _perform_witch(a, action)
		else:
			guide.on_enemy_turn(u)
			_enemy_tips(u)
			await guide.wait_clear() # 적 차례 앞 안내 판은 누를 때까지 (시간이 멈춘 순간)
			await _wait(0.4)
			if token != _run_id:
				return
			await _perform_enemy(a)
		if token != _run_id:
			return
		var ev := battle.end_action(u)
		var regen := false
		for e in ev:
			if e.t == "zeroed":
				hud.pop(e.tgt, "크레딧 0", "zero")
			elif e.t == "heal" and int(e.v) > 0:
				hud.pop(e.tgt, "+" + TData.fmt_short(int(e.v)), "heal") # 지속 회복 (F-4)
				regen = true
		hud.refresh()
		if regen:
			await _wait(0.3) # 지속 회복 숫자를 다음 바퀴가 열리기 전에 보인다 (R2 — 같은 프레임에 바퀴가 열려 가렸다, review_L §4.4)
			if token != _run_id:
				return
		var oc := battle.outcome()
		if oc == "wave":
			_wave_new = true
			await _wave_change(token)
		elif oc != "":
			await _finish(oc, token)
			return


## 웨이브 전환 (§6.3 · §22.2): 배너 "웨이브 N/M" 1.0초 + 북 소리 → 다음 웨이브의 적이 오른쪽 밖에서 0.4초 걸어 들어온다 (마녀 쪽은 그대로).
## 보스 웨이브면 하늘 아래쪽이 붉어지고 보스가 땅을 울린다
func _wave_change(token: int) -> void:
	await _wait(0.3)
	if token != _run_id:
		return
	hud.wave_banner(battle.wave_i + 2, battle.wave_count())
	Sfx.play(&"tn_wave", -2.0)
	await _wait(1.0)
	if token != _run_id:
		return
	if battle.outcome() != "wave":
		return # 이미 다음 웨이브로 넘어감 (시험용 demo_wave와 흐름이 겹칠 때)
	for e in battle.enemies:
		if actors.has(e):
			(actors[e] as TActor).queue_free()
			actors.erase(e)
	battle.next_wave()
	_add_enemies()
	var boss := _wave_has_boss()
	for e in battle.enemies:
		var ea: TActor = actors[e]
		ea.walk_in(260.0 if not e.boss else 300.0, 0.4)
		TFx.walk_dust(ea.feet() + Vector2(260, 0))
	_bg.set_theme(_wave_theme()) # 웨이브마다 배경 (F-3 · review_F F20) — 0.35초 어두워졌다 밝아짐
	_bg_tint(true)
	if boss:
		TFx.after(0.4, func() -> void:
			Fx.shake(0.8, 0.35)
			Sfx.play(&"tn_wave", 0.0, 0.0)
			Sfx.play(&"colossus_step", -6.0) # 보스 착지 (review_D B2)
			for e in battle.enemies:
				if actors.has(e):
					var sw := TFx.Shockwave.new()
					TFx.add(sw, (actors[e] as TActor).feet(), false))
	hud.refresh()
	await _wait(0.4)


## 지금 웨이브의 배경 테마 (TData.BATTLES의 bgs[웨이브] → bg → field)
func _wave_theme() -> String:
	return battle_theme(battle_id, battle.wave_i if battle != null else 0)


## 전투 bid의 웨이브 wi 배경 테마 (bgs[wi] → bg → field) — 편성 화면 뒤 배경도 이것으로
static func battle_theme(bid: String, wi: int) -> String:
	var bd: Dictionary = TData.BATTLES.get(bid, {})
	var bgs: Array = bd.get("bgs", [])
	if wi < bgs.size():
		return String(bgs[wi])
	return String(bd.get("bg", "field"))


## 세 빛의 인형 배경: 달 색 = 보스 지금 줄의 속성 색 (review_H §7.2 [제안])
func _bg_tint(instant := false) -> void:
	if battle == null:
		return
	for e in battle.enemies:
		if e.boss and (e.data.get("phases", []) as Array).size() > 1:
			_bg.set_tint(Color(TData.ELEMENT_COLOR.get(e.element, Color("#e8e0ff"))).lerp(Color.WHITE, 0.35), instant)


func _wave_has_boss() -> bool:
	for e in battle.enemies:
		if e.boss:
			return true
	return false


func _targets_for(a: TActor, action: Dictionary) -> Array:
	var out: Array = []
	var tgt: TUnit = action.get("target")
	if action.kind == "basic":
		if tgt != null and actors.has(tgt):
			out.append(actors[tgt])
		return out
	var s := TData.skill(String(action.skill))
	match String(s.get("target", "enemy")):
		"enemy", "ally", "ally_any":
			if tgt != null and actors.has(tgt):
				out.append(actors[tgt])
		"enemies":
			for e in battle.alive_of(battle.enemies):
				out.append(actors[e])
		"allies":
			for w in battle.alive_of(battle.witches):
				out.append(actors[w])
		"self":
			out.append(a)
	return out


func _perform_witch(a: TActor, action: Dictionary) -> void:
	var u := a.unit
	var targets := _targets_for(a, action)
	var tgt: TUnit = action.get("target")
	var fx_id := ""
	var ev: Array = []
	var big := false
	var el := String(u.data.element)
	if action.kind == "basic":
		fx_id = "basic_fire"
		if el in ["space", "time"]:
			fx_id = "basic_eska"
		elif el == "sword":
			fx_id = "slash"
		hud.hold_view()
		ev = battle.basic_attack(u, tgt)
		a.lunge()
		a.pose("cast")
	var ult := ""
	if action.kind != "basic":
		var s := TData.skill(String(action.skill))
		fx_id = String(s.fx)
		big = int(s.cost) >= 4
		hud.hold_view()
		ev = battle.use_skill(u, String(action.skill), tgt)
		if bool(s.get("ultimate", false)) and TFx.is_ult(String(action.skill)):
			ult = String(action.skill)
		elif String(s.kind) == "attack":
			a.lunge()
		a.pose("cast_big" if big else "cast")
	hud.show_msg("%s — %s" % [u.name, battle.last_action], TData.ELEMENT_COLOR.get(el, TTheme.LINE))
	hud.refresh()
	var timing: Dictionary
	if ult != "":
		# 대마법 2.0초 (§13.4 · §22.2): HUD를 잠깐 걷고 컷인 → 효과 → 숫자
		var stage := maxi(battle.chain_stage, 1)
		for e in ev:
			if String(e.t) == "chain":
				stage = int(e.stage)
		_ult_hud_fade()
		timing = TFx.ultimate(ult, a, targets, stage, _alive_actors(battle.enemies), _alive_actors(battle.witches))
	else:
		timing = TFx.play(fx_id, a, targets)
	_note_events(ev, "")
	await _show_events(ev, targets, timing, "space" if el in ["space", "time", "sword"] else "fire")
	if not is_instance_valid(a):
		return # 연출 중에 전투가 접혔다
	_show_total(ev)
	hud.release_view()
	a.pose("idle")
	hud.refresh()


func _perform_enemy(a: TActor) -> void:
	var u := a.unit
	var it := u.intent()
	var kind := String(it.get("k", "attack"))
	# 해제 연출용: 행동 전 마녀들의 버프 아이콘 · 관통용: 행동 전 무적
	var icons_before := {}
	var inv_before := {}
	var nbuf := 0
	for w in battle.witches:
		if w.alive:
			icons_before[w] = w.buff_icons()
			inv_before[w] = w.is_invincible()
			nbuf += w.buffs.size()
	a.set_acting(true)
	if kind == "finisher":
		# 필살기 예고 0.35초 (화면 가장자리 붉게 + 그 적 둘레 붉은 기운)
		hud.show_msg("%s — %s" % [u.name, String(it.get("name", "필살기"))], TTheme.DANGER)
		a.pose("buff")
		TFx.finisher_warn(a)
		await _wait(0.35)
	hud.hold_view()
	var ev := battle.enemy_action(u)
	for e in ev:
		if String(e.t) == "summon":
			_summon_actor(e) # 부르기: 쓰러진 칸의 그림을 새 적으로 (review_H §10.1)
	_note_events(ev, kind, u, String(it.get("name", TData.INTENT_NAME.get(kind, ""))), bool(it.get("pierce", false)))
	if kind == "dispel":
		_why.dispelled = int(_why.get("dispelled", 0)) + nbuf
	hud.show_msg("%s — %s" % [u.name, battle.last_action], TTheme.DANGER)
	var self_kind := kind in ["buff", "guard", "cover", "purge", "summon", "rally"]
	a.pose("buff" if self_kind else "attack")
	if not self_kind:
		a.lunge()
	var targets: Array = []
	for e in ev:
		if e.t == "hit" and actors.has(e.tgt) and not targets.has(actors[e.tgt]):
			targets.append(actors[e.tgt])
	if targets.is_empty():
		# 피해 없는 새 의도: 효과를 받은 쪽 (약화·봉인·흩기 = 마녀 · 재촉·부르기 = 적)
		for e in ev:
			if String(e.t) in ["weaken", "seal", "seal_resist", "credits", "charge_up", "gauge", "summon"] and actors.has(e.tgt) and not targets.has(actors[e.tgt]):
				targets.append(actors[e.tgt])
	if targets.is_empty():
		targets.append(a)
	var fx_id := "enemy_" + kind
	var dmg_it := float(it.get("mult", 0.0)) > 0.0
	match kind:
		"stun_attack": fx_id = "enemy_heavy"
		"finisher": fx_id = "enemy_aoe" if bool(it.get("aoe", false)) else "enemy_heavy"
		"dispel": fx_id = "enemy_buff"
		"seal": fx_id = "enemy_attack" if dmg_it else "enemy_seal"
		"weaken": fx_id = ("enemy_aoe" if bool(it.get("aoe", false)) else "enemy_attack") if dmg_it else "enemy_weaken"
	var timing := TFx.play(fx_id, a, targets)
	if bool(it.get("pierce", false)) and targets[0] != a:
		var ps := TFx.PierceSpear.new()
		ps.from = a.center()
		ps.to = (targets[0] as TActor).center()
		ps.barrier = bool(inv_before.get((targets[0] as TActor).unit, false))
		TFx.add(ps, Vector2.ZERO, true)
	var lost := {}
	for e in ev:
		if String(e.t) == "dispel" and icons_before.has(e.tgt):
			lost[e.tgt] = icons_before[e.tgt]
	if not lost.is_empty():
		TFx.after(0.3, func() -> void: TFx.dispel_fx(_alive_actors(battle.witches), lost, hud))
	await _show_events(ev, targets, timing, "enemy")
	await _wait(0.2)
	if not is_instance_valid(a):
		return # 연출 중에 전투가 접혔다 (철수·다시 시작 — 그림은 이미 지워짐)
	hud.release_view()
	a.set_acting(false)
	a.pose("idle")
	hud.refresh()


## 부르기 (review_H §2.1): 쓰러진 칸(old)의 그림을 지우고 새 적(tgt)을 그 자리에 — 오른쪽에서 짧게 걸어 들어온다
func _summon_actor(e: Dictionary) -> void:
	var old: TUnit = e.get("old")
	if old != null and actors.has(old):
		(actors[old] as TActor).queue_free()
		actors.erase(old)
	var nu: TUnit = e.tgt
	_add_actor(nu, enemy_spot(battle.enemies, int(e.slot)))
	var na: TActor = actors[nu]
	na.walk_in(70.0, 0.35)
	TFx.walk_dust(na.feet() + Vector2(70, 0))


func _alive_actors(units: Array) -> Array:
	var out: Array = []
	for u in units:
		if u.alive and actors.has(u):
			out.append(actors[u])
	return out


## 대마법 동안 HUD를 걷었다가(컷인 0.15~0.62초) 피해 숫자 전에 되돌린다
func _ult_hud_fade() -> void:
	hud.ult_t = TFx.ULT_TOTAL # 위 띠의 연쇄 칩이 대마법 동안 숨쉼 (review_D B3)
	var tw := create_tween()
	tw.tween_property(hud, "modulate:a", 0.12, 0.15)
	tw.tween_interval(0.47)
	tw.tween_property(hud, "modulate:a", 1.0, 0.18)


## 연출의 시각표에 맞춰 사건을 보여 준다: 맞는 순간마다 그 대상의 사건(피해·징표·디버프), 그 뒤 나머지(버프·크레딧 …)
func _show_events(ev: Array, targets: Array, timing: Dictionary, kind: String) -> void:
	var hits: Array = timing.get("hits", [0.2])
	var total := float(timing.get("total", 0.8))
	var sub := float(timing.get("sub", 0.09)) # 같은 대상의 다단 타격 간격
	var shown := {}
	var t_prev := 0.0
	for i in hits.size():
		var ht := float(hits[i])
		await _wait(ht - t_prev)
		t_prev = ht
		var ti := i if i < targets.size() else (0 if not targets.is_empty() else -1)
		if ti >= 0 and not is_instance_valid(targets[ti]):
			return # 연출 중에 전투가 접혔다 (지워진 그림을 변수에 넣기 전에 봄)
		var ta: TActor = targets[ti] if ti >= 0 else null
		var nth := 0
		for j in ev.size():
			if shown.has(j):
				continue
			var e: Dictionary = ev[j]
			if ta != null and e.get("tgt") == ta.unit and e.t in ["hit", "mark", "debuff", "invincible", "enemy_gauge", "gauge_zero", "extend_mark", "resist", "stun", "immune", "stun_resist", "burst", "charge_down"]:
				if e.t == "hit" and int(e.get("sub", 0)) > 0:
					nth += 1
					await _wait(sub)
					t_prev += sub
				_show_event(e, kind)
				shown[j] = true
			elif e.t == "hit" and i == hits.size() - 1: # 시각표보다 사건이 많으면 마지막 때에 몰아서
				_show_event(e, kind)
				shown[j] = true
		if hits.size() == 1 or i == hits.size() - 1:
			for j in ev.size():
				if shown.has(j):
					continue
				_show_event(ev[j], kind)
				shown[j] = true
	await _wait(maxf(total - t_prev, 0.1))


func _show_event(e: Dictionary, kind: String) -> void:
	var tgt: TUnit = e.get("tgt")
	if tgt == null or not actors.has(tgt):
		return
	var ta: TActor = actors[tgt]
	hud.view_event(e) # 화면의 보이는 값 (체력·징표·버프)을 이 사건이 뜨는 순간에 맞춤
	match String(e.t):
		"hit":
			if bool(e.invincible):
				hud.pop(tgt, "무적", "status")
				var b := TFx.Barrier.new()
				TFx.add(b, ta.center(), false)
				Sfx.play(&"bl_unfold", -10.0)
				return
			var dmg := int(e.dmg)
			var heavy := dmg >= 100000 or bool(e.crit)
			stats.biggest = maxi(int(stats.biggest), dmg if tgt.is_witch() == false else 0)
			ta.hurt(heavy)
			if bool(e.crit) and not tgt.is_witch():
				TFx.crit_flash(ta.center())
			if dmg >= 10000000:
				Fx.flash(Color(1, 1, 1, 0.2), 0.1) # 1,000만 이상 (§22.3) — 0.2 이하 (review_D B5: 밝은 막이 숫자 대비를 무너뜨림)
			var dir := -1.0 if tgt.is_witch() else 1.0
			TFx.impact(ta.center() + Vector2(randf_range(-4, 4), randf_range(-6, 2)), kind, heavy, dir)
			# 숫자 (§21.12): 일반 12 · 크리 24 금빛 "!" · 약점 15 + "약점" 꼬리표 · 한 히트 30만 이상 24 · 받은 피해 15
			var nk := "dmg"
			var txt := TData.fmt_short(dmg)
			if tgt.is_witch():
				nk = "hurt"
				Fx.flash(Color(1.0, 0.2, 0.3, 0.18), 0.12)
				Sfx.play(&"hurt", -6.0)
			elif bool(e.crit):
				nk = "crit"
				txt += "!"
				Sfx.play(&"tn_crit", -4.0)
			elif dmg >= 300000:
				nk = "big"
			elif bool(e.weak):
				nk = "weak"
			hud.pop(tgt, txt, nk, bool(e.weak) and not tgt.is_witch(), dmg)
			if dmg >= 300000:
				Fx.hitstop(0.1)
				Fx.shake(0.7, 0.3)
			elif heavy:
				Fx.hitstop(0.05)
				Fx.shake(0.4, 0.2)
			if bool(e.broke):
				# 브레이크 1.0초 (§22.2): 멈춤 0.15 · 막대 깨짐 0.5 · 다음 줄 차오름 0.35 — "브레이크" 글은 BarShatter가 30px로
				var cr: Rect2 = hud._card_rect(tgt)
				var bar := Rect2(cr.position + Vector2(4, 32), Vector2(300, 6)) if hud._boss_card_on() else Rect2(cr.position + Vector2(4, 31), Vector2(92, 5))
				TFx.break_fx(ta, bar, hud)
				_bg_tint() # 세 빛의 인형: 달 색이 다음 줄 속성으로
			if bool(e.get("guard_break", false)):
				# 약점 속성에 방어 태세가 갈라짐 (세 빛의 인형 "갈라지는 빛", F-3)
				hud.pop(tgt, "태세 깨짐", "status")
				TFx.intent_sign(ta, "guard")
				Sfx.play(&"tn_dispel_glint", -6.0)
			if bool(e.guts):
				hud.pop(tgt, "근성", "status")
				TFx.guts_fx(ta)
			for f in e.get("fall", []):
				# 우두머리와 함께 사라지는 졸개 (review_H §6.2)
				if actors.has(f):
					var fa: TActor = actors[f]
					var ft: TUnit = f
					var tw2 := create_tween()
					tw2.tween_interval(0.35)
					tw2.tween_callback(func() -> void:
						hud.view_event({"t": "down", "tgt": ft})
						fa.set_down(true)
						TFx.ash_dissolve(fa)
						hud.pop(ft, "사라짐", "status"))
			if bool(e.killed):
				var tw := create_tween()
				tw.tween_interval(0.25)
				tw.tween_callback(func() -> void:
					hud.view_event({"t": "down", "tgt": tgt})
					ta.set_down(true)
					if not tgt.is_witch():
						TFx.ash_dissolve(ta)
					hud.pop(tgt, "쓰러짐", "status")
					Sfx.play(&"bl_fold", -6.0))
		"buff":
			var cat := String(e.cat)
			var txt := ""
			if cat == "element":
				txt = "%s 속성 부여" % TData.ELEMENT_NAME.get(e.get("el", ""), "")
			elif cat == "dmg_taken":
				txt = "받는 피해 %+d%%" % int(round(float(e.v) * 100.0))
			else:
				var nm: String = TData.CAT_NAME.get(cat, cat)
				if cat == "special":
					nm = "%s 특공" % TData.MARK_NAME.get(e.get("mark", ""), "")
				txt = "%s +%d%%" % [nm, int(round(float(e.v) * 100.0))]
			hud.pop(tgt, txt, "buff")
		"debuff":
			hud.pop(tgt, "%s %d%%" % [TData.CAT_NAME.get(e.cat, e.cat), int(round(float(e.v) * 100.0))], "debuff")
		"mark":
			var mn := int(e.get("n", 1))
			hud.pop(tgt, TData.MARK_NAME.get(e.kind, e.kind) + (" %d겹" % mn if mn > 1 else ""), "mark")
		"burst":
			hud.pop(tgt, "%s %d겹 터뜨림" % [TData.MARK_NAME.get(e.kind, e.kind), int(e.n)], "mark")
		"resist":
			hud.pop(tgt, "저항", "status")
			TFx.resist_fx(ta, false)
		"stun":
			hud.pop(tgt, "기절", "status")
			TFx.stun_fx(ta)
		"immune":
			hud.pop(tgt, "면역", "status")
			TFx.resist_fx(ta, true)
		"stun_resist":
			hud.pop(tgt, "기절 내성", "status")
			TFx.resist_fx(ta, true)
		"taunt":
			hud.pop(tgt, "도발", "buff")
			TFx.taunt_fx(ta, _alive_actors(battle.enemies))
		"guts_on":
			hud.pop(tgt, "근성", "buff")
		"dispel":
			hud.pop(tgt, "버프 해제", "debuff")
		"credits":
			if int(e.v) > 0:
				hud.pop(tgt, "크레딧 +%d" % int(e.v), "credit")
			elif int(e.v) < 0:
				hud.pop(tgt, "크레딧 %d" % int(e.v), "zero") # 크레딧 흩기 (review_H §2.1)
				TFx.intent_sign(ta, "scatter")
		"gauge":
			if float(e.v) > 0.0:
				hud.pop(tgt, "게이지 +%d%%" % int(round(float(e.v) * 100.0)), "buff")
		"heal":
			if int(e.v) > 0:
				hud.pop(tgt, "+" + TData.fmt_short(int(e.v)), "heal")
		"revive":
			ta.set_down(false)
			hud.pop(tgt, "되살아남", "revive")
		"invincible":
			hud.pop(tgt, "무적", "buff")
		"inv_guard":
			hud.pop(tgt, "무적 내성", "status")
		"enemy_buff":
			hud.pop(tgt, "공격력 +%d%%" % int(round(float(e.v) * 100.0)), "debuff")
		"demerit":
			hud.pop(tgt, "다음 행동 뒤 크레딧 0", "zero")
		"enemy_gauge":
			hud.pop(tgt, "게이지 −%d%%" % int(round(float(e.v) * 100.0)), "debuff")
		"gauge_zero":
			hud.pop(tgt, "게이지 0", "debuff")
		"extend_buffs":
			hud.pop(tgt, "버프 지속 +%d" % int(e.v), "buff")
		"extend_mark":
			hud.pop(tgt, "%s +%d" % [TData.MARK_NAME.get(e.kind, e.kind), int(e.v)], "mark")
		# 단계 B
		"chain":
			hud.pop(tgt, "연쇄 %d단계" % int(e.stage), "break")
		"charge_down":
			if int(e.v) > 0:
				hud.pop(tgt, "차지 −%d" % int(e.v), "debuff")
		"hp_cost":
			if int(e.v) > 0:
				hud.pop(tgt, "−" + TData.fmt_short(int(e.v)), "hurt")
		"stack":
			hud.pop(tgt, "공격력 +%d%% (%d겹)" % [int(round(float(e.v) * 100.0)), int(e.n)], "buff")
		"hit_stack":
			hud.pop(tgt, "맞으며 쌓기", "buff")
		# 단계 F-2 새 의도 (review_H §2)
		"seal":
			hud.pop(tgt, "대마법 봉인" if bool(e.get("ult", false)) else "봉인", "debuff")
			TFx.intent_sign(ta, "seal")
			Sfx.play(&"tn_seal", -4.0)
		"seal_resist":
			hud.pop(tgt, "봉인 내성", "status")
			TFx.resist_fx(ta, true)
		"weaken":
			var wt := "공격력 −%d%%" if String(e.cat) == "atk_down" else "받는 피해 +%d%%"
			hud.pop(tgt, wt % int(round(float(e.v) * 100.0)), "debuff")
			TFx.intent_sign(ta, "weaken")
		"guard":
			hud.pop(tgt, "방어 태세 −%d%%" % int(round(float(e.v) * 100.0)), "status")
		"cover":
			hud.pop(tgt, "막아서기", "status")
		"charge_up":
			if int(e.v) > 0:
				hud.pop(tgt, "차지 +%d" % int(e.v), "debuff")
		"summon":
			hud.pop(tgt, "부름", "status")
		"purge":
			hud.pop(tgt, "징표 털기" + (" %d겹" % int(e.n) if int(e.n) > 0 else ""), "status")
		"self_ko":
			var sa := ta
			var tw3 := create_tween()
			tw3.tween_interval(0.2)
			tw3.tween_callback(func() -> void:
				hud.view_event({"t": "down", "tgt": tgt})
				sa.set_down(true)
				TFx.ash_dissolve(sa)
				hud.pop(tgt, "자폭", "status")
				Sfx.play(&"bl_fold", -6.0))


## 한 행동의 적 피해 합계 (히트가 2번 이상일 때, §21.12 [하면 좋음 G1]) — 행동 띠 끝에 금빛으로 (review_C2 L4)
func _show_total(ev: Array) -> void:
	var sum := 0
	var n := 0
	var first: TUnit = null
	for e in ev:
		if String(e.t) == "hit" and e.tgt is TUnit and not (e.tgt as TUnit).is_witch() and not bool(e.invincible):
			sum += int(e.dmg)
			n += 1
			if first == null:
				first = e.tgt
	if n >= 2 and first != null:
		hud.show_total(sum)


func _finish(oc: String, token: int) -> void:
	await _wait(0.5)
	if token != _run_id:
		return
	_in_battle = false
	TSave.clear_battle()
	_snap = {}
	if oc == "win":
		for u in actors:
			if u.is_witch() and u.alive:
				(actors[u] as TActor).pose("win")
				TFx.victory_sparkle(actors[u])
		Sfx.play(&"tn_victory", -2.0)
		var first := TSave.mark_cleared(battle_id)
		var sub := "눌러서 편성으로"
		if battle_id == "intro_01":
			TSave.hold = false
			TSave.intro_done = true
		if first and TSetup.NEXT.has(battle_id):
			# 다음 추천 (review_G G06): 첫 승리만, 안내 → 일반 → 보스 → 시련. 고른 전투도 다음으로
			var nx := String(TSetup.NEXT[battle_id])
			TSetup.battle_pick = nx
			sub += " · 다음 추천: " + String(TData.BATTLES[nx].name).replace("보스 전투 — ", "보스 ").replace("시련 — ", "시련 ")
		TSave.save_setup()
		hud.banner("승리", sub)
	else:
		for u in actors: # 쓰러진 마녀는 모두 무릎 꿇은 모습으로 (사건 없이 쓰러진 경우도 — review_D C5)
			if u.is_witch() and not u.alive:
				hud.view_event({"t": "down", "tgt": u})
				(actors[u] as TActor).set_down(true)
		Sfx.play(&"tn_defeat", -2.0)
		hud.banner_lines = _lose_reasons()
		hud.lose_main = "setup" if String(TData.BATTLES[battle_id].get("kind", "")) == "trial" else "retry" # 시련은 같은 편성으로 다시 해도 어렵다 (review_G G03)
		hud.banner("패배", "")


## 배너 누름: 승리 → 편성 · 패배 → "다시 도전"(같은 전투) 또는 "편성으로"
func _on_banner(choice: String) -> void:
	if hud.banner_text == "패배" and choice == "retry":
		hud.clear_banner()
		start_battle()
	else:
		_in_battle = false
		_to_setup()


## 마녀 차례가 시작됨 (크레딧 +1 뒤, 고르기 전): 사본을 붙잡고 5차례마다·웨이브 첫 차례에 파일로 (review_G §5.2 — 웹 IndexedDB 동기화를 줄임)
func _turn_snapshot() -> void:
	_witch_turns += 1
	_snap = battle.to_dict()
	_snap["stage"] = {"why": _why.duplicate(true), "witch_turns": _witch_turns - 1}
	if battle_id != "intro_01" and (_wave_new or _witch_turns % 5 == 1):
		TSave.save_battle(_snap)
	_wave_new = false


## 사건에서 안내·진 이유 기록을 모은다
func _note_events(ev: Array, enemy_kind: String, src: TUnit = null, act := "", pierce := false) -> void:
	for e in ev:
		match String(e.t):
			"hit":
				var tgt: TUnit = e.tgt
				if bool(e.broke):
					_flags["broke"] = true
				if tgt.is_witch() and src != null:
					var big: Dictionary = _why.get("big", {})
					if int(e.dmg) > int(big.get("dmg", 0)):
						_why["big"] = {"dmg": int(e.dmg), "src": src.name, "act": act}
					if bool(e.killed) and enemy_kind == "finisher":
						_why.fin_kills = int(_why.get("fin_kills", 0)) + 1
						_why["fin_src"] = src.name # 필살기로 쓰러뜨린 적 (가장 세게 때린 적과 다를 수 있다 — review_I I-13)
						if pierce:
							_why.pierce_kills = int(_why.get("pierce_kills", 0)) + 1
			"resist":
				_flags["resist"] = true
			"heal":
				if int(e.v) > 0:
					_why.heals = int(_why.get("heals", 0)) + 1
			"buff":
				if String(e.cat) in ["dmg_taken", "invincible"]:
					_why.guard = int(_why.get("guard", 0)) + 1


## 진 이유 (review_F F13 · review_G G03): 원인 하나 + 남은 적 체력 + 시련이면 추천 빌드. [[글, 색]]
func _lose_reasons() -> Array:
	return TData.lose_lines(_why, battle, battle_id)


## 처음 일어난 일 안내 (review_G §4.6 D1~D6 + F08 T7·T8·T11) — 마녀 차례에 바퀴가 열린 뒤 (고르기를 기다리는 멈춘 순간)
func _turn_tips(u: TUnit) -> void:
	if guide.phase in ["B1", "B2", "B3", "B5"]:
		return
	if u.credits >= TData.ULT_COST and hud.slots.size() > 5 and guide.tip("B6", "대마법", "크레딧 7을 모두 써서 쓰는 큰 마법입니다. 바퀴 끝 금빛 칸. 쓰고 나면 0부터 다시 모읍니다.", [hud.slot_rect(5)]):
		return
	if battle.chain_owner != null and battle.chain_stage > 0 and battle.chain_owner != u and hud.slots.size() > 5:
		if guide.tip("D5", "연쇄", "앞 대마법의 주인이 다시 움직이기 전에 다른 마녀가 대마법을 이으면 효과가 커집니다 (최대 3단계).", [hud.chain_rect(), hud.slot_rect(5)]):
			return
	_common_tips()


## 적 차례 앞 (0.4초 대기 전)
func _enemy_tips(_u: TUnit) -> void:
	if guide.phase in ["B1", "B2", "B4"] or guide.busy():
		return
	_common_tips()


func _common_tips() -> void:
	var fin := battle.finisher_slots(hud._queue)
	for e in battle.alive_of(battle.enemies):
		var k := String(e.intent().get("k", ""))
		var cr: Rect2 = hud._card_rect(e)
		var top := cr.grow(2)
		if k == "finisher" and bool(e.intent().get("pierce", false)):
			if guide.tip("D6", "관통", "이 공격(→| 표시)은 무적을 뚫습니다. 받는 피해 감소·도발·근성은 통합니다.", [top]):
				return
		if k == "finisher":
			var holes: Array = [top]
			for i in fin:
				if hud._queue[i] == e:
					holes.append(hud._queue_rect(int(i)).grow(2))
					break
			if guide.tip("D1", "필살기가 옵니다", "차지 칸이 다 차면 다음 행동이 필살기입니다. 차례 줄의 빨간 칸이 그 차례 — 무적·도발·기절·차지 감소로 대비하세요.", holes):
				return
		if k == "dispel":
			if guide.tip("D3", "해제", "이 적이 마녀들의 버프를 모두 지웁니다. 그 전에 쏟아붓거나, 지난 뒤에 거세요.", [top]):
				return
		# 단계 F-2 새 의도 — 처음 보일 때 한 번 (용어 풀이 글, review_H §2)
		var tk := "자폭" if k == "finisher" and bool(e.intent().get("self_ko", false)) else String(TData.INTENT_NAME.get(k, ""))
		if k in ["seal", "weaken", "guard", "cover", "rally", "summon", "purge", "scatter"] or tk == "자폭":
			var gl := TData.gloss_for(tk)
			if gl != "" and guide.tip("E_" + tk, tk, gl.get_slice(" — ", 1), [top]):
				return
		if e.leader and guide.tip("E_우두머리", "우두머리", TData.gloss_for("우두머리").get_slice(" — ", 1), [top]):
			return
		if not e.marks.is_empty() and guide.phase == "": # 안내 전투(첫 실행 흐름) 동안은 미룸 — B4 바로 다음 적 차례에 또 멈췄다 (review_I I-07)
			if guide.tip("D2", "징표", "화상·빙결·감전은 그 자체로 피해가 없습니다. 겹(숫자)이 쌓일수록 그 징표를 노리는 마법이 세지고, 화상은 터뜨려 한 번에 씁니다.", [cr.grow(2)]):
				return
		if e.stunned and guide.tip("T7", "기절", "기절하면 다음 차례 하나를 쉽니다. 쉰 뒤 한 차례는 다시 기절하지 않습니다.", [cr.grow(2)]):
			return
	if bool(_flags.get("broke", false)) and hud._boss_card_on():
		if guide.tip("D4", "줄", "보스는 체력이 여러 줄입니다. 한 줄을 깨면 넘친 피해는 사라지고 보스가 달라집니다.", [THud.BOSS_CARD.grow(2)]):
			return
	if bool(_flags.get("resist", false)) and not battle.alive_of(battle.enemies).is_empty():
		if guide.tip("T8", "저항", "강적·보스는 디버프를 막을 수 있습니다. 성공률은 마법 칸을 고르면 설명 띠에 보입니다.", [hud._card_rect(battle.alive_of(battle.enemies)[0]).grow(2)]):
			return
	for w in battle.witches:
		if not w.alive:
			if guide.tip("T11", "쓰러짐", "쓰러져도 크레딧은 남습니다. 되살림 마법으로 다시 세울 수 있습니다.", [hud._panel_rect(w.slot).grow(1)]):
				return
		elif w.stunned and guide.tip("T7", "기절", "기절하면 다음 차례 하나를 쉽니다. 쉰 뒤 한 차례는 다시 기절하지 않습니다.", [hud._panel_rect(w.slot).grow(1)]):
			return


func set_auto(v: bool) -> void:
	auto = v
	# 바퀴가 이미 열려 고르기를 기다리는 중이면 그 차례도 자동으로 (예전엔 그 마녀 차례가 영원히 기다렸다 — review_K T-6)
	if v and _in_battle and hud.state in ["wheel", "target"] and hud.actor != null:
		var act := _auto_pick(hud.actor)
		hud.close_wheel()
		hud.chosen.emit(act)


## 시험용: 전투 데이터를 바꾼다 (normal_01 · boss_01 · trial_01) — 편성의 전투 고르기에서 고른 것과 같다
func set_battle(id: String) -> void:
	battle_id = id
	TSetup.battle_pick = id


## 시험용: 파티를 바꾼다 (편성 화면을 거치지 않고)
func set_party(ids: Array) -> void:
	TSetup.ensure_state()
	var p: Array = []
	for i in ids:
		p.append(String(i))
	TSetup.state.party = p


## 시험용 자동 선택: TAuto (turn_sim과 같은 규칙)
func _auto_pick(a: TActor) -> Dictionary:
	return TAuto.pick(battle, a.unit)


## 시험용: 마법 연출 하나를 그냥 띄운다 (규칙은 건드리지 않음). 시전자는 마법 주인 마녀, 대상은 종류에 맞춰 고른다
func demo_fx(sid: String) -> String:
	var fx_id := sid
	var caster_id := "ignis"
	var target := "enemy"
	if TData.SKILLS.has(sid):
		var sk := TData.skill(sid)
		fx_id = String(sk.fx)
		target = String(sk.target)
		for wid in TData.WITCHES:
			if (TData.WITCHES[wid].skills as Array).has(sid):
				caster_id = wid
	elif sid.begins_with("enemy_"):
		caster_id = "straw_golem"
		target = "allies" if sid == "enemy_aoe" else ("self" if sid == "enemy_buff" else "ally")
	elif sid == "basic_eska":
		caster_id = "eska"
	var caster: TActor = null
	for u in actors:
		if u.id == caster_id:
			caster = actors[u]
	if caster == null:
		return "no caster"
	var targets: Array = []
	match target:
		"enemy":
			for e in battle.alive_of(battle.enemies):
				targets.append(actors[e])
				break
		"enemies":
			for e in battle.alive_of(battle.enemies):
				targets.append(actors[e])
		"ally", "ally_any":
			for w in battle.alive_of(battle.witches):
				if w.id == "eska":
					targets.append(actors[w])
		"allies":
			for w in battle.alive_of(battle.witches):
				targets.append(actors[w])
		"self":
			targets.append(caster)
	caster.pose("cast_big" if TData.cost_of(sid) >= 4 else "cast")
	var timing := TFx.play(fx_id, caster, targets)
	var tw := create_tween()
	tw.tween_interval(float(timing.total))
	tw.tween_callback(func() -> void: caster.pose("idle"))
	hud.show_msg("%s — %s" % [caster.unit.name, TData.skill(sid).get("name", sid)])
	return "%s %s hits=%s total=%.2f" % [fx_id, caster_id, str(timing.hits), float(timing.total)]


## 시험용: 지금 상태 한 줄
func status() -> String:
	if battle == null:
		return "no battle"
	var s := "turn=%d actor=%s outcome=%s" % [battle.turn_no, battle.actor.name if battle.actor else "-", battle.outcome()]
	for u in battle.all_units():
		s += " | %s hp=%d g=%d c=%d%s" % [u.name, u.hp, int(u.gauge), u.credits, "" if u.alive else " X"]
	return s


## 시험용: 대마법 연출 하나를 그냥 띄운다 (규칙은 건드리지 않음 — tools/test/scenarios/turn_ult.json). 맞는 시각마다 가짜 숫자
func demo_ult(sid: String, stage := 1) -> String:
	var caster: TActor = null
	for u in actors:
		if u.is_witch() and String(u.data.get("ultimate", "")) == sid:
			caster = actors[u]
	if caster == null:
		return "no caster for " + sid
	hud.close_wheel()
	var sk := TData.skill(sid)
	var targets: Array = []
	match String(sk.get("target", "enemy")):
		"enemy":
			targets = _alive_actors(battle.enemies).slice(0, 1)
		"enemies":
			targets = _alive_actors(battle.enemies)
		_:
			targets = _alive_actors(battle.witches)
	caster.pose("cast_big")
	_ult_hud_fade()
	hud.show_msg("%s — %s" % [caster.unit.name, String(sk.get("name", sid))], TData.ELEMENT_COLOR.get(caster.unit.element, TTheme.LINE))
	var timing := TFx.ultimate(sid, caster, targets, stage, _alive_actors(battle.enemies), _alive_actors(battle.witches))
	var hits: Array = timing.hits
	var sub := float(timing.get("sub", 0.09))
	var n := int(sk.get("effects", [{}])[0].get("n", 1)) if String(sk.get("effects", [{}])[0].get("t", "")) == "multi" else 1
	var attack := String(sk.get("kind", "")) == "attack"
	for i in hits.size():
		var ta: TActor = targets[i] if i < targets.size() else null
		if ta == null:
			continue
		for j in (n if attack else 1):
			var at := float(hits[i]) + sub * float(j)
			TFx.after(at, func() -> void:
				if not is_instance_valid(ta):
					return
				if attack:
					ta.hurt(true)
					TFx.impact(ta.center(), "space" if caster.unit.element in ["space", "sword"] else "fire", true, 1.0)
					hud.pop(ta.unit, TData.fmt_short(1234567) + ("!" if sid == "ult_harpe" else ""), "crit" if sid in ["ult_harpe", "ult_fulgur"] else "big", false, 1234567)
				else:
					hud.pop(ta.unit, "버프", "buff"))
	var tw := create_tween()
	tw.tween_interval(float(timing.total))
	tw.tween_callback(func() -> void: caster.pose("idle"))
	return "%s stage=%d hits=%s total=%.2f" % [sid, stage, str(hits), float(timing.total)]


## 시험용: 지금 프레임의 그리기 호출 · 입자 수 · 연출 노드 수 (대마법 성능 확인, §22)
func perf() -> String:
	var dc := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var obj := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
	var pa := PParticles.get_layer(true).count()
	var pn := PParticles.get_layer(false).count()
	var fxn := get_node("Effects").get_child_count()
	var ul := get_node_or_null("UltLayer")
	return "draw_calls=%d objects=%d particles=%d+%d fx_nodes=%d ult_nodes=%d" % [dc, obj, pa, pn, fxn, ul.get_child_count() if ul != null else 0]


## 시험용: 상태 연출 하나를 띄운다 (break · stun · dispel · guts · taunt · resist · immune · pierce · finisher · crit). 규칙은 브레이크의 줄 번호만 넘긴다
func demo_event(kind: String) -> String:
	hud.close_wheel()
	var foe: TUnit = battle.alive_of(battle.enemies)[0]
	var w: TUnit = battle.alive_of(battle.witches)[0]
	var hit := {"t": "hit", "tgt": foe, "dmg": 1500000, "crit": false, "weak": false, "invincible": false, "broke": false, "guts": false, "killed": false}
	match kind:
		"break":
			if foe.bars.size() > foe.bar_i + 1:
				foe.bar_i += 1
				foe.max_hp = int(foe.bars[foe.bar_i])
				foe.hp = foe.max_hp
			hit.broke = true
			_show_event(hit, "fire")
		"crit":
			hit.crit = true
			_show_event(hit, "fire")
		"stun":
			w.stunned = true
			_show_event({"t": "stun", "tgt": w}, "enemy")
		"guts":
			_show_event({"t": "hit", "tgt": w, "dmg": 30000, "crit": false, "weak": false, "invincible": false, "broke": false, "guts": true, "killed": false}, "enemy")
		"taunt", "resist", "immune":
			_show_event({"t": kind, "tgt": w if kind == "taunt" else foe}, "enemy")
		"dispel":
			var lost := {}
			for u in battle.alive_of(battle.witches):
				lost[u] = [{"cat": "atk"}, {"cat": "crit_dmg"}, {"cat": "invincible"}, {"cat": "dmg_taken", "v": -0.3}]
				hud.pop(u, "버프 해제", "debuff")
			TFx.dispel_fx(_alive_actors(battle.witches), lost, hud)
		"pierce", "finisher":
			var fa: TActor = actors[foe]
			TFx.finisher_warn(fa)
			fa.set_acting(true)
			TFx.after(0.35, func() -> void:
				var ps := TFx.PierceSpear.new()
				ps.from = fa.center()
				ps.to = (actors[w] as TActor).center()
				ps.barrier = kind == "pierce"
				TFx.add(ps, Vector2.ZERO, true)
				fa.set_acting(false))
	return kind


## 시험용: 지금 웨이브의 적을 모두 쓰러뜨리고 다음 웨이브로 넘긴다 (웨이브 전환 연출 확인 — 규칙의 다음 웨이브를 그대로 씀)
## 시험용: 적 i가 의도 it를 지금 실행하는 연출 (차례·패턴은 그대로 — tools/test/scenarios/turn_enemies.json, 단계 F-2)
func demo_enemy(i: int, it: Dictionary) -> String:
	var e := battle.enemies[i]
	if not actors.has(e) or not e.alive:
		return "no enemy %d" % i
	hud.close_wheel()
	e.intent_now = it
	e.intent_src = "insert"
	_perform_enemy(actors[e])
	return "%s %s" % [e.name, String(it.get("k", ""))]


## 시험용: 마녀 wi가 적 ei에게 기본 공격 (우두머리 쓰러짐 등 히트 연출 확인)
func demo_basic(wi: int, ei: int) -> String:
	hud.close_wheel()
	_perform_witch(actors[battle.witches[wi]], {"kind": "basic", "skill": "basic", "target": battle.enemies[ei]})
	return "basic %d → %d" % [wi, ei]


## 시험용: 적 i를 바로 쓰러뜨림 (빈 칸 만들기)
func demo_down(i: int) -> String:
	var e := battle.enemies[i]
	e.alive = false
	e.hp = 0
	if actors.has(e):
		(actors[e] as TActor).set_down(true)
		TFx.ash_dissolve(actors[e])
	return "down %d" % i


func demo_wave() -> String:
	hud.close_wheel()
	for e in battle.enemies:
		e.alive = false
		e.hp = 0
		if actors.has(e):
			(actors[e] as TActor).set_down(true)
			TFx.ash_dissolve(actors[e])
	if battle.wave_i + 1 >= battle.wave_count():
		return "last wave"
	_wave_change(_run_id)
	return "wave %d" % (battle.wave_i + 2)
