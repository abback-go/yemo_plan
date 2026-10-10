class_name EStage
extends Node2D
## 에스카 장면 공통 바탕 (훈련장 EArena · 튜토리얼 ETutorial).
## 하는 일: 화면 꽉 채우기(높이 360 기준, 넓은 화면은 옆이 더 보임, 배율은 소수 허용 — 나가면 원래 설정으로),
##          이펙트 층, 에스카·카메라·터치 조작·화면 표시, 쓰러지면 잠시 뒤 부활, Esc로 나가기, 시험용 성능 수치.
## 하위 장면은 _build()에서 땅·배경·표적을 놓고 stage_w·floor_y·respawn_at을 정한다. 다 만든 뒤 _start()가 불린다.

const ArenaScript := preload("res://proto/p_arena.gd")
const RESPAWN_DELAY := 1.5 ## 쓰러진 뒤 다시 나타나기까지 (실제 시간)

var stage_w := 1280.0
var floor_y := 300.0
var cam_top := -260.0 ## 카메라가 올라갈 수 있는 위 끝
var respawn_at := Vector2(400, 300)
var music := "boss"

var eska: EEska
var touch: ETouch
var hud: EHud
var cam: Camera2D
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
	_build()
	eska = EEska.new()
	eska.position = respawn_at
	add_child(eska)
	eska.died.connect(_on_eska_died)
	cam = ArenaScript.PCamera.new()
	cam.target = eska
	cam.look_y = -70.0
	cam.limit_left = 0
	cam.limit_right = int(stage_w)
	cam.limit_top = int(cam_top)
	cam.limit_bottom = int(floor_y + 60.0)
	add_child(cam)
	cam.global_position = eska.global_position
	touch = ETouch.new()
	touch.eska = eska
	add_child(touch)
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	hud = EHud.new()
	hud.eska = eska
	hud.touch = touch
	layer.add_child(hud)
	Music.play(music)
	_start()


## 하위 장면: 땅·배경·표적
func _build() -> void:
	pass


## 하위 장면: 모두 만든 뒤 (화면 표시·에스카를 쓸 수 있음)
func _start() -> void:
	pass


func _exit_tree() -> void:
	var win := get_tree().root
	win.content_scale_aspect = _prev_aspect
	win.content_scale_stretch = _prev_stretch


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("es_exit"):
		touch.release_all()
		Fx.reset()
		GameState.go_title()


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


## 바닥 + 양쪽 벽 (일자형 마당)
func flat_ground() -> void:
	solid(Rect2(-40, floor_y, stage_w + 80, 120))
	solid(Rect2(-40, floor_y - 400, 56, 520))
	solid(Rect2(stage_w - 16, floor_y - 400, 56, 520))


func _on_eska_died() -> void:
	hud.banner("쓰러졌다", "공간의 틈에서 다시 일어선다", RESPAWN_DELAY + 0.4)
	await get_tree().create_timer(RESPAWN_DELAY, true, false, true).timeout
	if is_instance_valid(eska):
		eska.respawn(_respawn_point())


## 부활 자리: 기본은 respawn_at (튜토리얼은 마지막 확인점으로 바꾼다)
func _respawn_point() -> Vector2:
	return respawn_at


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
		if node != eska.art and node.has_method("_paint") and node.get("pd") is PDraw:
			var pd: PDraw = node.get("pd")
			t0 = Time.get_ticks_usec()
			for i in n:
				node.call("_paint")
				pd.clear()
			var us := float(Time.get_ticks_usec() - t0) / n
			if us > 20.0:
				var nm: String = node.get_script().get_global_name()
				out += "%s=%.1f " % [nm if nm != "" else str(node.get_class()) + ":" + node.name, us]
	return out
