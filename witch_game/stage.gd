class_name BStage
extends Node2D
## 종언의 마녀 손맛 프로토타입 장면: 에스카 빗자루 검 데모(game/proto/blade/b_stage.gd + game/proto/eska/e_stage.gd)를 바탕으로 한 마당.
## 에스카 마당 배경(EScenery) + 평평한 땅·양쪽 벽 + 이단점프를 시험하는 발판 둘 + 허수아비 셋(작은 것 둘·큰 것 하나) + 공중 모래주머니 하나.
## 적은 공격하지 않는다. Esc = 처음부터.

const MODE_ACTION := BEska.MODE_ACTION
const W := 1100.0
const FLOOR := 300.0
const VIEW_ZOOM := 0.15 ## 손맛 데모는 조금 가깝게 (카메라 추가 확대)
const RESPAWN_DELAY := 1.5
## 이단점프 시험 발판 (땅 기준 높이): 한 번 점프(약 46px)로 오르는 낮은 발판 + 이단점프로만 오르는 높은 발판
const LEDGES := [Rect2(130, FLOOR - 44, 84, 10), Rect2(232, FLOOR - 104, 84, 10)]

var eska: BEska
var cam: PCamera
var bhud: BHud
var dummies: Array[BDummy] = []
var respawn_at := Vector2(380, FLOOR)


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
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	win.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	Engine.time_scale = 1.0
	Fx.reset()
	var fx := Node2D.new()
	fx.name = "Effects"
	fx.z_index = 5
	add_child(fx)
	_build()
	eska = BEska.new()
	eska.position = respawn_at
	add_child(eska)
	eska.died.connect(_on_eska_died)
	cam = PCamera.new()
	cam.target = eska
	cam.look_y = -60.0
	cam.zoom_extra = VIEW_ZOOM
	cam.limit_left = 0
	cam.limit_right = int(W)
	cam.limit_top = int(FLOOR - 420.0)
	cam.limit_bottom = int(FLOOR + 60.0)
	add_child(cam)
	cam.global_position = eska.global_position
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	bhud = BHud.new()
	bhud.eska = eska
	bhud.stage = self
	layer.add_child(bhud)
	var build := Label.new()
	build.text = "build %s" % BuildInfo.COMMIT
	build.modulate = Color(1, 1, 1, 0.35)
	build.add_theme_font_size_override("font_size", 12)
	build.position = Vector2(8, 52)
	layer.add_child(build)


func _build() -> void:
	EScenery.build(self, W, FLOOR)
	solid(Rect2(-40, FLOOR, W + 80, 120))
	solid(Rect2(-40, FLOOR - 400, 56, 520))
	solid(Rect2(W - 16, FLOOR - 400, 56, 520))
	for r: Rect2 in LEDGES:
		solid(r)
	var ledges := Ledges.new()
	ledges.rects = LEDGES
	add_child(ledges)
	for spec: Array in [["small", Vector2(530, FLOOR)], ["small", Vector2(610, FLOOR)], ["big", Vector2(770, FLOOR)], ["hang", Vector2(690, FLOOR - 86)]]:
		var d := BDummy.new()
		d.setup(spec[0])
		d.position = spec[1]
		add_child(d)
		dummies.append(d)


## 막힌 땅·벽 (사각형)
func solid(r: Rect2) -> void:
	var b := StaticBody2D.new()
	b.collision_layer = 1
	b.collision_mask = 0
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = r.size
	cs.shape = rs
	cs.position = r.get_center()
	b.add_child(cs)
	add_child(b)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("es_exit"):
		Fx.reset()
		get_tree().reload_current_scene()


func _on_eska_died() -> void:
	await get_tree().create_timer(RESPAWN_DELAY, true, false, true).timeout
	if is_instance_valid(eska):
		eska.respawn(respawn_at)


## 틈 자국이 남은 허수아비가 있나 (화면 안내)
func any_scar() -> bool:
	for d: BDummy in dummies:
		if not d.scars.is_empty():
			return true
	return false


## 이단점프 시험 발판 그림: 배경(EScenery)의 돌·보라 금과 같은 색
class Ledges extends Node2D:
	var rects: Array = []

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		for r: Rect2 in rects:
			draw_rect(r, EScenery.STONE)
			draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), EScenery.STONE_TOP)
			draw_line(r.position + Vector2(6, 5), r.position + Vector2(r.size.x * 0.45, 7), Color(EScenery.CRACK, 0.5), 1.0)
