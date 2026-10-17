class_name TTitle
extends Control
## 타이틀: 세 마녀가 나란히 선 그림 + [시작] [자동 시연]. 최고 한 방 기록을 보여 준다.

signal started(auto: bool)

var run: TRun
var _t := 0.0
var _stage: Node2D
var _eska: EEska
var _sera: SeraArt
var _ashe: TAsheArt
var _buttons := {} ## id → Rect2


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage = Node2D.new()
	add_child(_stage)
	_stage.z_index = -1
	var sky := EScenery.SkyBack.new()
	sky.z_index = -5
	_stage.add_child(sky)
	var sp := EScenery.Spires.new()
	sp.col = EScenery.MID
	sp.scale_k = 0.8
	sp.seed_n = 2
	sp.width = 640.0
	sp.floor_y = 330.0
	sp.z_index = -4
	_stage.add_child(sp)
	var ground := EScenery.Ground.new()
	ground.width = 640.0
	ground.floor_y = 330.0
	ground.z_index = -3
	_stage.add_child(ground)
	# 세 마녀 (에스카 가운데 크게)
	var e_root := Node2D.new()
	e_root.position = Vector2(150, 322)
	e_root.scale = Vector2(2.6, 2.6)
	_stage.add_child(e_root)
	_eska = EEska.new()
	e_root.add_child(_eska)
	_eska.set_physics_process(false)
	_eska.set_process(false)
	_eska.art.stand = true
	_eska.art.calm = true
	_eska.art.rim_on = false
	var s_root := Node2D.new()
	s_root.position = Vector2(66, 326)
	s_root.scale = Vector2(2.1, 2.1)
	_stage.add_child(s_root)
	_sera = SeraArt.new()
	s_root.add_child(_sera)
	var a_root := Node2D.new()
	a_root.position = Vector2(236, 328)
	a_root.scale = Vector2(2.1, 2.1)
	_stage.add_child(a_root)
	_ashe = TAsheArt.new()
	a_root.add_child(_ashe)
	_buttons = {"start": Rect2(372, 216, 200, 44), "auto": Rect2(372, 268, 200, 36)}


func _process(delta: float) -> void:
	_t += delta
	_eska.art.tick(delta)
	_sera.step(delta)
	_ashe.step(delta)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p := (event as InputEventMouseButton).position
		for id in _buttons.keys():
			if (_buttons[id] as Rect2).has_point(p):
				Sfx.play(&"ui_ok", -4.0, 0.0)
				get_viewport().set_input_as_handled()
				started.emit(id == "auto")
				return
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_Z, KEY_SPACE]:
			get_viewport().set_input_as_handled()
			started.emit(false)


func _draw() -> void:
	draw_rect(Rect2(340, 36, 280, 290), Color(0.03, 0.02, 0.06, 0.66))
	draw_rect(Rect2(340, 36, 2, 290), Color(TUi.VIOLET, 0.7))
	TUi.text(self, Vector2(356, 86), "에스카", 40, TUi.PALE)
	TUi.text(self, Vector2(358, 110), "종언의 마녀 · 턴제 전투 시험판", 12, TUi.TEXT)
	TUi.text(self, Vector2(358, 132), "마녀 셋이 버프를 겹쳐 대마법 한 방을 키운다.", 11, TUi.DIM)
	TUi.text(self, Vector2(358, 148), "행동 게이지(칸) · 시전 끊기 · 빌드(해금·빗자루·물약)", 11, TUi.DIM)
	TUi.text(self, Vector2(358, 170), "전투 3판: 들개 → 잿가루 길 → 재의 기사왕", 11, TUi.GOLD)
	if run and run.best_hit > 0:
		var info: Dictionary = run.best_hit_info
		var who := String(TData.witch(String(info.get("unit", ""))).get("name", ""))
		var sp := String(TData.spell(String(info.get("spell", ""))).get("name", ""))
		TUi.text(self, Vector2(358, 196), "최고 한 방  " + TUi.fmt(run.best_hit) + "  (" + who + " · " + sp + ")", 12, TUi.EDGE)
	TUi.button(self, _buttons.start, "시작", TUi.GOLD, 16, fmod(_t, 1.2) < 0.7)
	TUi.button(self, _buttons.auto, "자동 시연 (AI가 둘 다 해봄)", TUi.DIM, 11)
	TUi.text(self, Vector2(358, 320), "빌드 " + BuildInfo.COMMIT + " · 터치 · 키보드 1~6 Q W A", 10, Color(TUi.DIM, 0.7))
	TUi.text(self, Vector2(40, 60), "세라 · 화염", 11, Color("#ff7a52"))
	TUi.text(self, Vector2(118, 46), "에스카 · 공간", 12, TUi.PALE)
	TUi.text(self, Vector2(212, 60), "아셰 · 잿불", 11, TUi.EMBER)
