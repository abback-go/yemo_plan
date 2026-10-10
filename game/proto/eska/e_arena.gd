extends Node2D
## 에스카 전투 시제품 장면: 마녀 분위기의 일자형 마당 + 허수아비 하나. 전투 조작만 시험한다.
## 들어오는 길: 타이틀 메뉴 "에스카 시제품" 또는 웹 주소 뒤 ?eska
## 화면: 이 장면에서만 여백 없이 꽉 채운다(높이 360 기준, 넓은 화면은 옆이 더 보임, 배율은 소수 허용). 나가면 원래 설정으로.

const ArenaScript := preload("res://proto/p_arena.gd")
const W := 1280.0
const FLOOR := 300.0

var eska: EEska
var touch: ETouch
var dummy: PDummy
var _prev_aspect := Window.CONTENT_SCALE_ASPECT_KEEP
var _prev_stretch := Window.CONTENT_SCALE_STRETCH_INTEGER


func _ready() -> void:
	EKeys.register()
	var win := get_tree().root
	_prev_aspect = win.content_scale_aspect
	_prev_stretch = win.content_scale_stretch
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	win.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
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
	cam.limit_top = int(FLOOR - 560)
	cam.limit_bottom = int(FLOOR + 60)
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


func _exit_tree() -> void:
	var win := get_tree().root
	win.content_scale_aspect = _prev_aspect
	win.content_scale_stretch = _prev_stretch


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


## 시험 실행기 eval용 성능 수치: 그리기 호출 · 그린 도형 · 노드 수 · 처리 시간(ms) · 입자 수
func perf() -> String:
	var pp := PParticles.get_layer(true)
	return "draws=%d prims=%d nodes=%d process_ms=%.2f particles=%d" % [
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		pp.count()]


## 시험 실행기 eval용: 그림 코드 하나를 n번 돌린 평균 시간(µs) — 최적화 대상 찾기
func bench(n: int) -> String:
	var out := ""
	var t0 := Time.get_ticks_usec()
	for i in n:
		eska.art.tick(1.0 / 60.0)
	out += "art_tick=%.1f " % (float(Time.get_ticks_usec() - t0) / n)
	t0 = Time.get_ticks_usec()
	for i in n:
		eska.art._paint()
		eska.art.pd.clear()
	out += "art_paint=%.1f " % (float(Time.get_ticks_usec() - t0) / n)
	for node: Node in find_children("*", "", true, false):
		if node is PDraw.Canvas and node != eska.art and node.has_method("_paint"):
			var c := node as PDraw.Canvas
			t0 = Time.get_ticks_usec()
			for i in n:
				c._paint()
				c.pd.clear()
			var us := float(Time.get_ticks_usec() - t0) / n
			if us > 20.0:
				out += "%s=%.1f " % [c.get_script().get_global_name() if c.get_script().get_global_name() != "" else str(c.get_class()) + ":" + c.name, us]
	return out
