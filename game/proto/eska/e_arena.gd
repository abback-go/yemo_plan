extends Node2D
## 에스카 전투 시제품 장면: 마녀 분위기의 일자형 마당 + 허수아비 하나. 전투 조작만 시험한다.
## 들어오는 길: 타이틀 메뉴 "에스카 시제품" 또는 웹 주소 뒤 ?eska

const ArenaScript := preload("res://proto/p_arena.gd")
const W := 1280.0
const FLOOR := 300.0

var eska: EEska
var touch: ETouch
var dummy: PDummy


func _ready() -> void:
	EKeys.register()
	Engine.time_scale = 1.0
	get_tree().paused = false
	Fx.reset()
	var fx := Node2D.new()
	fx.name = "Effects"
	fx.z_index = 5
	add_child(fx)
	EScenery.build(self, W, FLOOR)
	_solid(Rect2(-40, FLOOR, W + 80, 120))
	_solid(Rect2(-40, FLOOR - 400, 56, 520))
	_solid(Rect2(W - 16, FLOOR - 400, 56, 520))
	dummy = PDummy.new()
	dummy.setup("small")
	dummy.position = Vector2(540, FLOOR)
	add_child(dummy)
	eska = EEska.new()
	eska.position = Vector2(400, FLOOR)
	add_child(eska)
	var cam = ArenaScript.PCamera.new()
	cam.target = eska
	cam.look_y = -70.0
	cam.limit_left = 0
	cam.limit_right = int(W)
	cam.limit_top = int(FLOOR - 420)
	cam.limit_bottom = int(FLOOR + 50)
	add_child(cam)
	cam.global_position = eska.global_position
	touch = ETouch.new()
	touch.eska = eska
	add_child(touch)
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var hud := EHud.new()
	hud.eska = eska
	hud.touch = touch
	layer.add_child(hud)
	Music.play("boss")


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("es_exit"):
		touch.release_all()
		Fx.reset()
		GameState.go_title()


func _solid(r: Rect2) -> void:
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
