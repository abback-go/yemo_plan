class_name BStage
extends EStage
## 빗자루 검 손맛 데모 장면 (웹 주소 끝 ?blade). docs/eska-turn/README.md §0-4.
## 에스카 마당 배경(EScenery) 위에 허수아비 셋(작은 것 둘·큰 것 하나) + 공중 모래주머니 하나. 적은 공격하지 않는다.
## EStage의 화면 맞추기·땅·나가기를 쓰고, 에스카·터치·화면 표시는 이 데모 것(BEska·BTouch·BHud)으로 바꾼다.

const MODE_ACTION := "bl_mode" ## 모드 바꾸기 (키보드 S)
const W := 1100.0
const FLOOR := 300.0
const VIEW_ZOOM := 0.15 ## 손맛 데모는 조금 가깝게 (카메라 추가 확대)

var btouch: BTouch
var bhud: BHud
var dummies: Array[BDummy] = []
var dummy: BDummy ## 첫 허수아비 (시험용)


static func register_keys() -> void:
	EKeys.register()
	if not InputMap.has_action(MODE_ACTION):
		InputMap.add_action(MODE_ACTION, 0.2)
	InputMap.action_erase_events(MODE_ACTION)
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_S
	InputMap.action_add_event(MODE_ACTION, ev)


func _ready() -> void:
	register_keys()
	var win := get_tree().root
	_prev_aspect = win.content_scale_aspect
	_prev_stretch = win.content_scale_stretch
	_prev_size = win.content_scale_size
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	win.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	Engine.time_scale = 1.0
	get_tree().paused = false
	Fx.reset()
	var fx := Node2D.new()
	fx.name = "Effects"
	fx.z_index = 5
	add_child(fx)
	_build()
	var e := BEska.new()
	e.position = respawn_at
	add_child(e)
	eska = e
	cam = ArenaScript.PCamera.new()
	cam.target = eska
	cam.look_y = -60.0
	cam.zoom_extra = VIEW_ZOOM
	cam.limit_left = 0
	cam.limit_right = int(stage_w)
	cam.limit_top = int(cam_top)
	cam.limit_bottom = int(floor_y + 60.0)
	add_child(cam)
	cam.global_position = eska.global_position
	_fit_view()
	get_viewport().size_changed.connect(_fit_view)
	btouch = BTouch.new()
	btouch.eska = e
	add_child(btouch)
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	bhud = BHud.new()
	bhud.eska = e
	bhud.stage = self
	layer.add_child(bhud)
	Music.play(music)


func _build() -> void:
	stage_w = W
	floor_y = FLOOR
	cam_top = FLOOR - 420.0
	respawn_at = Vector2(380, FLOOR)
	EScenery.build(self, W, FLOOR)
	flat_ground()
	for spec: Array in [["small", Vector2(530, FLOOR)], ["small", Vector2(610, FLOOR)], ["big", Vector2(770, FLOOR)], ["hang", Vector2(450, FLOOR - 86)]]:
		var d := BDummy.new()
		d.setup(spec[0])
		d.position = spec[1]
		add_child(d)
		dummies.append(d)
	dummy = dummies[0]


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("es_exit"):
		btouch.release_all()
		Fx.reset()
		GameState.go_title()


## 틈 자국이 남은 허수아비가 있나 (화면 안내)
func any_scar() -> bool:
	for d: BDummy in dummies:
		if not d.scars.is_empty():
			return true
	return false


## 시험 실행기 eval용: 허수아비들의 자국 수 · 터진 횟수 · 체력
func scar_info() -> String:
	var out := ""
	for d: BDummy in dummies:
		out += "%s(scars=%d bursts=%d hp=%d) " % [d.kind, d.scars.size(), d.bursts, d.hp]
	return out
