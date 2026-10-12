class_name EStage
extends Node2D
## 에스카 장면 공통 바탕 (훈련장 EArena · 튜토리얼 ETutorial).
## 하는 일: 화면 꽉 채우기(높이 360 기준, 넓은 화면은 옆이 더 보임, 배율은 소수 허용 — 나가면 원래 설정으로),
##          터치 중엔 카메라가 오른쪽 끝을 cam_margin_touch만큼 넘어 봄 + 가장 가까운 적이 버튼 자리(화면 오른쪽 40%)에 오지 않게 살짝 치우침(CamBias),
##          이펙트 층, 에스카·카메라·터치 조작·화면 표시, 쓰러지면 잠시 뒤 부활, Esc로 나가기, 시험용 성능 수치.
## 하위 장면은 _build()에서 땅·배경·표적을 놓고 stage_w·floor_y·respawn_at을 정한다. 다 만든 뒤 _start()가 불린다.

const ArenaScript := preload("res://proto/p_arena.gd")
const RESPAWN_DELAY := 1.5 ## 쓰러진 뒤 다시 나타나기까지 (실제 시간)
const PORTRAIT_W := 400.0 ## 세로 화면에서 보이는 가로 폭(월드) — 캐릭터가 작아지지 않게
const PORTRAIT_GROUND := 240.0 ## 세로 화면: 바닥 아래로 보이는 땅 (조작 버튼이 여기 놓임)

var stage_w := 1280.0
var floor_y := 300.0
var cam_top := -260.0 ## 카메라가 올라갈 수 있는 위 끝
var respawn_at := Vector2(400, 300)
## 터치 중 카메라 여유: 오른쪽 끝(벽)에서도 캐릭터가 오른쪽 아래 버튼(엄지) 밑에 오지 않게 카메라가 무대 오른쪽 끝을 이만큼 넘어 볼 수 있다.
## 배경(EScenery)은 EScenery.MARGIN만큼 더 그려 둔다. 다른 배경을 쓰는 장면(보스장)은 이 값을 바꾸거나 자기 배경을 그만큼 늘린다
var cam_margin_touch := 240.0 ## 180이면 벽에 붙을 때 물약 버튼과 몸이 겹침 (루프2 코어 측정)
var music := "boss"
## 훈련장 연습 과제 저장소 (loop6 2장): 해낸 과제 id → true. 장면이 바뀌어도 남는다(게임을 끄면 사라짐 — 저장은 월드 제작 단계).
## 튜토리얼이 가르친 것을 여기 적으면 훈련장이 그 과제를 체크된 채로 시작한다.
## 키 = 정수 과제 번호(훈련장 PracticeList.T_*): 0 낙성으로 공중 표적 · 1 단공 딱 맞춤 · 2 새 물약 달이기 · 3 틈 달이기 · 4 대마법.
## (이름 키 PRACTICE_IDS[번호]로 적어도 읽어 줌)
static var practice_done := {}
const PRACTICE_IDS: Array[String] = ["nakseong_air", "dangong_perfect", "brew_new", "rift_brew", "ult"] ## 번호별 이름 (읽을 때만 — 저장은 정수 키)

var eska: EEska
var touch: ETouch
var hud: EHud
var cam: Camera2D
var cam_bias: CamBias
var _prev_aspect := Window.CONTENT_SCALE_ASPECT_KEEP
var _prev_stretch := Window.CONTENT_SCALE_STRETCH_INTEGER
var _prev_size := Vector2i(640, 360)


func _ready() -> void:
	EKeys.register()
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
	cam_bias = CamBias.new()
	cam_bias.stage = self
	add_child(cam_bias)
	_fit_view()
	get_viewport().size_changed.connect(_fit_view)
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


## 세로 화면(휴대폰 세로): 기준 화면을 가로 400으로 줄여(= 크게 보이게) 캐릭터·버튼이 작아지지 않게 하고,
## 바닥 아래 땅을 넓게 보여 조작 버튼이 그 위에 놓이게 한다. 가로 화면은 원래대로 (높이 360 기준).
## (카메라 확대로 하면 시차 배경 층이 어긋나서 기준 화면 크기를 바꾼다)
func _fit_view() -> void:
	var win := get_tree().root
	var portrait := win.size.y > win.size.x
	var want := Vector2i(int(PORTRAIT_W), 360) if portrait else _prev_size
	if win.content_scale_size != want:
		win.content_scale_size = want
	cam.limit_bottom = int(floor_y + (PORTRAIT_GROUND if portrait else 60.0))
	cam.limit_top = int(floor_y - 2400.0 if portrait else cam_top)


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
	win.content_scale_size = _prev_size


func _process(_delta: float) -> void:
	var right := int(stage_w + (cam_margin_touch if touch.active else 0.0))
	if cam.limit_right != right:
		cam.limit_right = right
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


## 시험 실행기 eval용: pos에서 r 안에 열린 틈(ERifts)이 있나 (식에서는 전역 클래스 이름을 못 써서)
func rift_at(pos: Vector2, r := 4.0) -> bool:
	return not ERifts.at(pos, r).is_empty()


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


## 카메라 치우침 강제 (loop6 3장): sec초(실제 시간) 동안 가장 가까운 적이 화면 가로 frac 안에 오게 강하게 민다 — 입력 방식과 상관없이,
## 연출(focus_w)도 무시. 튜토리얼 틈 달이기 느려짐·보스 발도 예고처럼 "지금 이걸 봐야 하는" 순간에 부른다. 겹쳐 부르면 긴 쪽·작은 frac
func force_bias(sec: float, frac := 0.55) -> void:
	if not is_instance_valid(cam_bias):
		return
	if cam_bias.force_left <= 0.0:
		cam_bias.force_frac = frac
	else:
		cam_bias.force_frac = minf(cam_bias.force_frac, frac)
	cam_bias.force_left = maxf(cam_bias.force_left, sec)


## 카메라 치우침: 가장 가까운 적(살아 있는 EEnemy)이 화면 왼쪽에서 KEEP_X 몫보다 오른쪽(= 오른쪽 아래 버튼 자리)에 오면
## 그만큼(최대 MAX px) 카메라를 오른쪽으로 부드럽게 민다 — 평소엔 터치 중에만, 연출(focus_w)이 카메라를 잡고 있으면 그만큼 약하게 (loop5 4장).
## force_bias가 걸린 동안은 입력 방식·연출과 상관없이 force_frac 안으로, 최대 FORCE_MAX px, 더 빠르게 (화면 왼쪽 끝 EDGE_X 밖이면 왼쪽으로도).
## 카메라(PCamera)가 이번 프레임 자리를 정한 뒤에 더하도록 처리 순서를 늦춘다.
class CamBias extends Node:
	const KEEP_X := 0.6
	const MAX := 140.0
	const SPEED := 2.5 ## 따라가는 빠르기 (실제 시간 초당)
	const FORCE_MAX := 220.0
	const FORCE_SPEED := 6.0
	const EDGE_X := 0.08 ## 강제 중: 적이 화면 왼쪽 이 몫보다 바깥이면 왼쪽으로 민다
	var stage: EStage
	var bias := 0.0 ## 지금 더하는 양 (시험용으로 읽음)
	var force_left := 0.0 ## 강제 남은 시간 (실제 시간)
	var force_frac := 0.55

	func _ready() -> void:
		process_priority = 100 # PCamera(0)보다 나중에

	func _process(delta: float) -> void:
		var cam := stage.cam
		if not is_instance_valid(cam) or not is_instance_valid(stage.eska):
			return
		var real := minf(delta / maxf(Engine.time_scale, 0.0001), 0.1)
		force_left = maxf(force_left - real, 0.0)
		var forced := force_left > 0.0
		var want := 0.0
		if forced or (stage.touch and stage.touch.active):
			var view_w := cam.get_viewport_rect().size.x / maxf(cam.zoom.x, 0.01)
			var base := cam.global_position
			var ex := stage.eska.global_position.x
			var best := INF
			var bx := 0.0
			for n: Node in stage.get_tree().get_nodes_in_group(PDummy.GROUP):
				var e := n as EEnemy
				if e == null or e.is_dead():
					continue
				var dx := absf(e.global_position.x - ex)
				if dx < best and dx < view_w * (1.5 if forced else 1.0):
					best = dx
					bx = e.global_position.x
			if best < INF:
				var sx := bx - base.x + view_w * 0.5
				if forced:
					want = clampf(sx - view_w * force_frac, 0.0, FORCE_MAX) + clampf(sx - view_w * EDGE_X, -FORCE_MAX, 0.0)
				else:
					want = clampf(sx - view_w * KEEP_X, 0.0, MAX) * (1.0 - clampf(float(cam.get("focus_w")), 0.0, 1.0))
		bias = lerpf(bias, want, 1.0 - exp(-real * (FORCE_SPEED if forced else SPEED)))
		if absf(bias) > 0.05:
			cam.global_position.x += bias
