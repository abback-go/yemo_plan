## main.gd — 시작: 화면 레이어를 만들고 각 부분을 등록한다. 1920×1080 무대를 창에 맞춰 비율 유지(project.godot stretch).
## 휴대폰 세로면 "가로로 돌려 주세요". 작은 화면이면 대사·안내·카드 확대 글씨를 키운다(FX.update_screen).
## 주소 뒤 옵션(웹): ?seed=7 · ?speed=4 · ?scene=giant(바로 시작) · ?test=1(시험 훅) · ?autoguide=1 · ?guides=reset · ?run=2
##   바로 가기: ?scene=camp | corridor | hall | map | room:<방>(prayer·gravekeeper·buried·corpse·chapel·training·stall·footprints·stairs·deep)
##             | giant | emptycamp | floor2 | ossuary | f2stairs | floor3&brun=alive|dead | pyre | result
##   자동 진행(--autoguide --autoplay): --rooms=방,방… (지도에서 들를 방 순서) · --choice=값,… · --reward=카드|skip(묘지기의 좌판에서 살 카드 — 전투 승리 보상은 2026-11-21 에 뺐다) · --train=카드
##   · ?fates=accept(=offer),defy,… (운명의 시도 자동 선택, 순서대로)
##   · ?nosave=1 / --nosave: 자동 저장·설정 파일을 쓰지도 읽지도 않는다(시험 실행 — 남은 저장이 결과를 바꾸지 않게) · ?continue=1: 타이틀 없이 이어하기
extends Node

var stage: Node2D
var world: Node2D
var fx_draw: Node2D
var fx_top: Node2D
var ui_layer: Node2D
var rotate_hint: Control
var test_api: TestApi


func _ready() -> void:
	G.read_params()
	G.main = self
	if G.params.has("check-scripts"):
		var fails: int = CheckScripts.new().run()
		get_tree().quit(1 if fails > 0 else 0)
		return
	stage = Node2D.new()
	stage.name = "Stage"
	add_child(stage)
	world = Node2D.new()
	world.name = "World"
	stage.add_child(world)
	FX.world = world
	var view := BattleView.new()
	view.name = "BattleView"
	world.add_child(view)
	G.view = view
	# 효과(입자·선·화살표·들어 올린 실)
	fx_draw = Node2D.new()
	fx_draw.name = "Fx"
	fx_draw.z_index = 200
	stage.add_child(fx_draw)
	FX.fx_draw = fx_draw
	fx_draw.draw.connect(_draw_fx)
	var fl := Node2D.new()
	fl.z_index = 210
	stage.add_child(fl)
	FX.float_layer = fl
	var cutin := Cutin.new()
	cutin.name = "Cutin"
	cutin.z_index = 260
	stage.add_child(cutin)
	G.cutin = cutin
	# 배너·알림
	var banner := UI.label("", 64, Color("#f4e6e8"), "serif_wide", HORIZONTAL_ALIGNMENT_CENTER, 12)
	banner.add_theme_color_override("font_outline_color", Color(0.4, 0.03, 0.06, 0.8))
	banner.position = Vector2(0, 470)
	banner.size = Vector2(1920, 100)
	banner.visible = false
	banner.z_index = 310
	stage.add_child(banner)
	FX.banner_label = banner
	var toast := Control.new()
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.z_index = 445   # 장면(VN·지도, 400)보다 위 · 대사창(450)보다 아래 — 방에서 얻은 것·촛불 알림이 보이게
	toast.visible = false
	var tl := UI.label("", 26, Color("#ffd9dc"), "sans_bold", HORIZONTAL_ALIGNMENT_CENTER)
	tl.position = Vector2(26, 10)
	toast.add_child(tl)
	toast.resized.connect(func(): pass)
	toast.draw.connect(func():
		tl.reset_size()
		toast.size = tl.size + Vector2(52, 20)
		toast.draw_style_box(UI.box(Color(0, 0, 0, 0.82), Color("#8c3340"), 10, 1), Rect2(Vector2.ZERO, toast.size)))
	stage.add_child(toast)
	FX.toast_box = toast
	FX.toast_label = tl
	ui_layer = Node2D.new()
	ui_layer.z_index = 330
	stage.add_child(ui_layer)
	var scenes := Scenes.new()
	scenes.name = "Scenes"
	scenes.z_index = 400
	stage.add_child(scenes)
	G.scenes = scenes
	# VN·지도·컷신 같은 장면이 열려 있으면 입자·선 효과를 장면 위에 그린다 (전투 중에는 아래 Fx 층)
	fx_top = Node2D.new()
	fx_top.name = "FxTop"
	fx_top.z_index = 440
	stage.add_child(fx_top)
	fx_top.draw.connect(_draw_fx_top)
	var dialog := DialogBox.new()
	dialog.name = "Dialog"
	dialog.z_index = 450
	stage.add_child(dialog)
	G.dialog = dialog
	var flash := ColorRect.new()
	flash.size = Vector2(1920, 1080)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.modulate.a = 0.0
	flash.z_index = 900
	stage.add_child(flash)
	FX.flash_rect = flash
	var fade := ColorRect.new()
	fade.color = Color.BLACK
	fade.size = Vector2(1920, 1080)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.modulate.a = 1.0
	fade.z_index = 950
	stage.add_child(fade)
	FX.fade_rect = fade
	_make_rotate_hint()
	var ctl := Ctl.new()
	ctl.name = "Ctl"
	add_child(ctl)
	G.ctl = ctl
	if G.params.has("seed"):
		ctl.seed = int(G.params.seed)
	var guide := Guide.new()
	add_child(guide)
	G.guide = guide
	var input := BattleInput.new()
	add_child(input)
	G.input = input
	test_api = TestApi.new()
	add_child(test_api)
	if G.params.has("autoplay"):
		add_child(AutoPlay.new())
	get_viewport().size_changed.connect(_on_resize)
	_on_resize()
	if G.params.has("scene"):
		ctl.jump(str(G.params.scene))
	elif G.params.has("continue") and not ctl.load_save().is_empty():
		ctl.continue_game()   # 시험용: 타이틀을 거치지 않고 이어하기 (?continue=1 / --continue)
	else:
		scenes.title()


func _fx_on_top() -> bool:
	return G.scenes != null and (G.scenes.is_open() or G.scenes.overlay_open())


func _draw_fx() -> void:
	if not _fx_on_top():
		FX.draw_particles(fx_draw)
		FX.draw_overlays(fx_draw)
	if G.view and G.view.visible:
		G.view.draw_highlights(fx_draw)
		G.view.draw_broken(fx_draw)
		G.view.draw_raised_thread(fx_draw)
		G.input.draw_overlay(fx_draw)


func _draw_fx_top() -> void:
	if _fx_on_top():
		FX.draw_particles(fx_top)
		FX.draw_overlays(fx_top)


func _process(_delta: float) -> void:
	if fx_draw:
		fx_draw.queue_redraw()
	if fx_top:
		fx_top.queue_redraw()


func _make_rotate_hint() -> void:
	rotate_hint = Control.new()
	rotate_hint.size = Vector2(1920, 1080)
	rotate_hint.mouse_filter = Control.MOUSE_FILTER_STOP
	rotate_hint.z_index = 2000
	rotate_hint.visible = false
	var bk := ColorRect.new()
	bk.color = Color("#050305")
	bk.size = rotate_hint.size
	bk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotate_hint.add_child(bk)
	var t := UI.label(G.ui("rotate"), 80, Color("#f0e2e4"), "sans_bold", HORIZONTAL_ALIGNMENT_CENTER)
	t.position = Vector2(0, 560)
	t.size = Vector2(1920, 110)
	rotate_hint.add_child(t)
	var s := UI.label(G.ui("rotateSub"), 46, Color("#aa9999"), "sans", HORIZONTAL_ALIGNMENT_CENTER)
	s.position = Vector2(0, 690)
	s.size = Vector2(1920, 70)
	rotate_hint.add_child(s)
	var icon := Control.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.position = Vector2(960, 380)
	var tt := [0.0]
	icon.draw.connect(func():
		var k := fposmod(tt[0], 1.8) / 1.8
		var ang := 0.0 if k < 0.25 else (-PI / 2.0 * minf(1.0, (k - 0.25) / 0.35))
		var xf := Transform2D(ang, Vector2.ZERO)
		var pts := PackedVector2Array()
		for p in [Vector2(-60, -100), Vector2(60, -100), Vector2(60, 100), Vector2(-60, 100), Vector2(-60, -100)]:
			pts.append(xf * p)
		icon.draw_polyline(pts, UI.RED, 8.0, true))
	icon.set_process(true)
	rotate_hint.add_child(icon)
	rotate_hint.set_meta("icon", icon)
	rotate_hint.set_meta("tt", tt)
	stage.add_child(rotate_hint)


func _on_resize() -> void:
	FX.update_screen()
	G.stage_scale = FX.css_scale
	var ws := Vector2(DisplayServer.window_get_size())
	var portrait := ws.y > ws.x
	# 세로로 든 휴대폰: "가로로 돌려 주세요" (가로 화면에서는 무대가 화면에 맞춰 비율 유지)
	rotate_hint.visible = portrait and (FX.touch or G.params.has("portraitHint"))
	if rotate_hint.visible:
		# 세로 화면에서는 무대가 작아지므로 안내 글씨를 그 비율만큼 키운다
		rotate_hint.scale = Vector2.ONE
	G.dialog.relayout()
	if G.scenes.current is VnScene:
		G.scenes.current.relayout()


func _unhandled_input(e: InputEvent) -> void:
	if rotate_hint.visible:
		return
	# PC: 스페이스·엔터로 대사·안내 상자 넘기기 (대화 장면은 각자 처리)
	if e is InputEventKey and e.pressed and not e.echo and e.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		if G.dialog.is_busy():
			G.dialog.advance()
			get_viewport().set_input_as_handled()
			return
		if not G.scenes.cut.is_empty() and G.scenes.cut.get("waiter") != null:
			G.scenes.cut.waiter.finish()   # 컷신(데스신) 다음 컷
			get_viewport().set_input_as_handled()
			return
	if e is InputEventMouse:
		var is_touch: bool = e.device == InputEvent.DEVICE_ID_EMULATION
		if is_touch:
			FX.touch = true
		var pos := stage.get_local_mouse_position()
		if e is InputEventMouseButton or e is InputEventMouseMotion:
			# 컷인·안내 상자는 어디를 탭해도 넘어간다
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and not G.ctl.in_battle and G.dialog.guide_open():
				G.dialog.advance()
				return
			G.input.handle(e, pos, is_touch)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PROCESS and rotate_hint and rotate_hint.visible:
		var tt: Array = rotate_hint.get_meta("tt")
		tt[0] += get_process_delta_time()
		rotate_hint.get_meta("icon").queue_redraw()
