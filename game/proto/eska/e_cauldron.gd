class_name ECauldron
extends Node2D
## 마녀의 가마솥 (쉼터): 앞에 서서 ↑를 톡 누르면(뗄 때 — ↑A·↑F와 겹치지 않게, 터치: 달이기 버튼) 달이기 화면(EBrewUI) → 재료 2~3개로 물약을 달여 허리띠 칸에 넣는다.
## 들르기만 해도 허리띠 물약이 가득 찬다. 기준서: docs/eska/design.md 4장, 수치: docs/eska/potions.md
## 그림: 세 발 달린 무쇠 솥 · 보랏빛으로 끓는 물약(거품이 올라와 터짐) · 김 · 솥 밑 불씨 · 솥 배에 희미한 마녀 문장.

const NEAR_X := 34.0 ## 에스카가 이 가로 거리 안 + 땅 높이가 비슷하면 "가까이"
const NEAR_Y := 40.0
const BTN := Rect2(-30, -88, 60, 24) ## 터치 달이기 버튼 (발밑 기준)
const BTN_PAD := 8.0 ## 버튼 누르는 자리를 이만큼 넓게
const PROMPT_Y := -70.0 ## 키보드 안내 "↑ 달이기" 높이
const OTHER_ACTIONS: Array[String] = ["es_skill", "es_potion", "es_attack", "es_jump", "es_blink"] ## ↑와 함께 누르면 달이기가 아님

# 색 (파랑 없음)
const IRON := Color("#2a2433")
const IRON_HI := Color("#4a4058")
const IRON_RIM := Color("#6b5c80")
const OUT := Color("#0a090e")
const BREW := Color("#7a2fd0")
const BREW_HI := Color("#c27bff")
const BREW_FOAM := Color("#ecd2ff")
const EMBER := Color("#ff8a3d")
const EMBER_HOT := Color("#ffd27a")
const STEAM := Color("#d9ccff")

var eska: EEska
var near := false
var ui: EBrewUI
var refills := 0 ## 들러서 채운 횟수 (시험용)
var t := 0.0
var pd := PDraw.new()
var _prompt := 0.0 ## 안내 글씨 나타남 (0~1)
var _sparkle := 0.0 ## 채울 때 반짝임
var _steam_t := 0.0
var _armed := false ## 가까이서 ↑를 누른 채 (떼면 열림)


## 장면(stage)의 pos(발밑)에 가마솥 하나를 놓는다
static func place(stage: Node, pos: Vector2) -> ECauldron:
	var c := ECauldron.new()
	c.position = pos
	stage.add_child(c)
	return c


func _ready() -> void:
	z_index = -1
	t = randf() * 3.0
	# 터치 버튼 입력은 장면 맨 끝에 붙인 작은 노드가 받는다: _input은 나중에 붙은 노드가 먼저 받으므로,
	# 장면을 지을 때 놓인 가마솥보다 늦게 붙는 터치 조작(ETouch)이 왼쪽 아래 방향 패드 자리에서 손가락을 먼저 가져가 버리지 않게
	var catcher := TouchCatch.new()
	catcher.cauldron = self
	get_tree().current_scene.add_child.call_deferred(catcher)
	tree_exiting.connect(catcher.queue_free)


func _process(delta: float) -> void:
	t += delta
	if not is_instance_valid(eska):
		eska = EEska.find(get_tree())
		if eska == null:
			return
	var d := eska.global_position - global_position
	var now := absf(d.x) <= NEAR_X and absf(d.y) <= NEAR_Y and not eska.is_dead()
	if now and not near:
		_arrive()
	near = now
	_prompt = move_toward(_prompt, 1.0 if near and ui == null else 0.0, delta * 6.0)
	_sparkle = maxf(_sparkle - delta * 1.6, 0.0)
	# ↑를 눌렀다 떼면 연다 (그 사이 다른 키를 함께 누르면 ↑A 단공·↑F 물약이므로 열지 않음)
	if near and ui == null:
		if Input.is_action_just_pressed("es_up"):
			_armed = true
		if _armed and _other_action():
			_armed = false
		if _armed and Input.is_action_just_released("es_up"):
			_armed = false
			if _can_open():
				open()
	else:
		_armed = false
	_steam_t -= delta
	if _steam_t <= 0.0: # 솥 위로 피어오르는 김 + 가끔 튀는 불씨
		_steam_t = 0.16
		var pp := PParticles.get_layer(false)
		pp.spawn(global_position + Vector2(randf_range(-12, 12), -34), Vector2(randf_range(-6, 6), randf_range(-26, -16)), Vector2(4, -6), randf_range(1.0, 1.6), randf_range(3.0, 5.0), Color(STEAM, 0.18), Color(STEAM, 0.0), 2, 0.6)
		if randf() < 0.35:
			PParticles.get_layer(true).spawn(global_position + Vector2(randf_range(-8, 8), -4), Vector2(randf_range(-14, 14), randf_range(-50, -24)), Vector2(0, -10), randf_range(0.4, 0.8), 1.2, EMBER_HOT, EMBER, 0, 1.0)
	queue_redraw()


func _other_action() -> bool:
	for a: String in OTHER_ACTIONS:
		if InputMap.has_action(a) and Input.is_action_pressed(a):
			return true
	return false


func _can_open() -> bool:
	return eska.is_on_floor() and eska.st == EEska.St.NORMAL and not eska.controls_locked


## 들름: 허리띠가 가득 참 (비어 있던 게 있으면 반짝임 + 소리)
func _arrive() -> void:
	if eska.belt.is_full():
		return
	eska.belt.refill()
	refills += 1
	_sparkle = 1.0
	Sfx.play(&"es_pot_refill", -4.0)
	var pp := PParticles.get_layer(true)
	for i in 14: # 솥에서 에스카 쪽으로 튀는 보랏빛 방울
		var to := eska.center() - (global_position + Vector2(0, -34))
		pp.spawn(global_position + Vector2(randf_range(-10, 10), -34), to * randf_range(1.2, 2.0) + Vector2(0, randf_range(-90, -40)), Vector2(0, 160), randf_range(0.45, 0.7), randf_range(1.2, 2.2), BREW_FOAM, BREW_HI, 0, 1.0)
	EVfx.pixels(eska.center(), 10, 90.0, Vector2.UP, 120.0, 0.5)


## 달이기 화면을 연다 (게임은 멈춤)
func open() -> void:
	if ui != null or not is_instance_valid(eska):
		return
	eska.velocity.x = 0.0
	if not eska.belt.is_full():
		_arrive()
	ui = EBrewUI.new()
	ui.eska = eska
	ui.closed.connect(_on_ui_closed)
	get_tree().current_scene.add_child(ui)


func _on_ui_closed() -> void:
	ui = null
	if is_instance_valid(eska):
		eska.belt.refill()


## 터치·마우스로 달이기 버튼을 누름 (가까이 있을 때만) — TouchCatch가 넘겨 줌
func touch_input(event: InputEvent) -> void:
	if not near or ui != null or not is_instance_valid(eska):
		return
	var pos := Vector2.INF
	if event is InputEventScreenTouch and event.pressed:
		pos = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION:
		pos = event.position
	if pos == Vector2.INF:
		return
	var world := get_viewport().get_canvas_transform().affine_inverse() * pos
	if BTN.grow(BTN_PAD).has_point(world - global_position) and _can_open():
		get_viewport().set_input_as_handled()
		open()


## 장면 맨 끝에서 입력을 먼저 받아 가마솥에 넘기는 노드
class TouchCatch extends Node:
	var cauldron: ECauldron

	func _input(event: InputEvent) -> void:
		if is_instance_valid(cauldron):
			cauldron.touch_input(event)


func _touch_on() -> bool:
	var sc := get_tree().current_scene
	var tc: Variant = sc.get("touch") if sc else null
	return tc != null and is_instance_valid(tc) and bool(tc.get("active"))


# ═══════════════════════════════════════════════════════════
# 그림 (원점 = 발밑 가운데)
# ═══════════════════════════════════════════════════════════

func _draw() -> void:
	var flick := 0.8 + 0.2 * sin(t * 11.0) * sin(t * 7.3)
	# 바닥 그림자 + 불빛
	pd.draw_set_transform(Vector2(0, 0), 0.0, Vector2(1.0, 0.25))
	pd.glow(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.5), 0.0)
	pd.draw_set_transform(Vector2.ZERO)
	pd.glow(Vector2(0, -6), 26.0 * flick, Color(EMBER, 0.16), 0.0)
	# 다리 셋 (뒤 다리는 어둡게)
	pd.draw_line(Vector2(0, -12), Vector2(2, 0), Color(IRON, 1.0), 3.0)
	for sd: float in [-1.0, 1.0]:
		pd.draw_line(Vector2(sd * 13.0, -15), Vector2(sd * 17.0, 0), OUT, 4.4)
		pd.draw_line(Vector2(sd * 13.0, -15), Vector2(sd * 17.0, 0), IRON_HI, 2.4)
		pd.draw_rect(Rect2(sd * 17.0 - 2.5, -1.5, 5, 2), OUT)
	# 불씨와 작은 불꽃
	pd.draw_set_transform(Vector2(0, -3), 0.0, Vector2(1.0, 0.45))
	pd.draw_circle(Vector2.ZERO, 9.0, Color("#3a1408"))
	pd.draw_set_transform(Vector2.ZERO)
	for i in 5:
		var x := (float(i) - 2.0) * 3.4
		var h := (5.0 + 3.0 * sin(t * 9.0 + float(i) * 1.7)) * flick
		pd.draw_colored_polygon(PackedVector2Array([Vector2(x - 2.0, -3), Vector2(x + 2.0, -3), Vector2(x + sin(t * 6.0 + i) * 1.0, -3 - h)]), Color(EMBER, 0.95))
		pd.draw_colored_polygon(PackedVector2Array([Vector2(x - 1.0, -3), Vector2(x + 1.0, -3), Vector2(x, -3 - h * 0.55)]), EMBER_HOT)
	# 솥 몸통 (무쇠 공)
	var body := PackedVector2Array()
	for i in 24:
		var an := float(i) / 24.0 * TAU
		body.append(Vector2(cos(an) * 20.0, -22.0 + sin(an) * 13.5))
	pd.outlined(body, IRON, OUT, 1.2)
	pd.draw_set_transform(Vector2(0, -22), 0.0, Vector2(1.0, 13.5 / 20.0))
	pd.draw_arc(Vector2.ZERO, 20.0, PI * 0.95, PI * 2.05, 16, Color(IRON_RIM, 0.45), 1.0) # 어두운 배경에서 윤곽이 읽히게
	pd.draw_set_transform(Vector2.ZERO)
	pd.draw_arc(Vector2(0, -22), 16.5, PI * 1.05, PI * 1.38, 6, Color(IRON_RIM, 0.8), 1.6) # 왼쪽 위 쇠빛
	pd.draw_arc(Vector2(0, -22), 14.0, PI * 0.25, PI * 0.75, 8, Color(EMBER, 0.22 * flick), 1.2) # 아래쪽 불빛 반사
	# 솥 배의 희미한 마녀 문장 (원 안의 일곱 갈래 별)
	var sg := Vector2(0, -19)
	var rune := Color(BREW_HI, 0.28 + 0.12 * sin(t * 2.0))
	pd.draw_arc(sg, 6.0, 0.0, TAU, 20, rune, 0.8)
	for i in 7:
		var a0 := -PI / 2.0 + float(i) * TAU / 7.0
		var a1 := -PI / 2.0 + float(i + 3) * TAU / 7.0
		pd.draw_line(sg + Vector2.from_angle(a0) * 5.0, sg + Vector2.from_angle(a1) * 5.0, rune, 0.7)
	# 손잡이 고리
	for sd: float in [-1.0, 1.0]:
		pd.draw_arc(Vector2(sd * 20.0, -28), 3.4, 0.0, TAU, 10, OUT, 2.4)
		pd.draw_arc(Vector2(sd * 20.0, -28), 3.4, 0.0, TAU, 10, IRON_HI, 1.2)
	# 아가리 테 + 끓는 물약
	pd.draw_set_transform(Vector2(0, -33), 0.0, Vector2(1.0, 0.28))
	pd.draw_circle(Vector2.ZERO, 18.5, OUT)
	pd.draw_circle(Vector2.ZERO, 17.0, IRON_HI)
	pd.draw_circle(Vector2.ZERO, 14.5, BREW)
	pd.glow(Vector2.ZERO, 14.0, Color(BREW_HI, 0.75), 0.15)
	pd.draw_arc(Vector2.ZERO, 17.0, PI * 1.1, PI * 1.6, 8, Color(IRON_RIM, 0.9), 1.6)
	pd.draw_set_transform(Vector2.ZERO)
	# 넘쳐 흐르는 물약 방울
	var drip := fmod(t * 0.7, 1.0)
	pd.draw_line(Vector2(11, -32), Vector2(12.5, -28 + drip * 4.0), BREW_HI, 1.6)
	pd.draw_circle(Vector2(12.5, -27.4 + drip * 4.0), 1.2, BREW_HI)
	# 거품: 올라와 부풀었다 터짐
	for i in 5:
		var ph := fmod(t * (0.9 + 0.17 * float(i)) + float(i) * 0.31, 1.0)
		var bx := sin(float(i) * 2.3) * 9.0
		var by := -33.0 + cos(float(i) * 1.7) * 2.0
		if ph < 0.8:
			var br := 0.8 + 2.2 * (ph / 0.8)
			pd.draw_circle(Vector2(bx, by - br * 0.5), br, Color(BREW_HI, 0.85))
			pd.draw_circle(Vector2(bx - br * 0.35, by - br * 0.85), br * 0.35, Color(BREW_FOAM, 0.9))
		else:
			var f := (ph - 0.8) / 0.2
			pd.draw_arc(Vector2(bx, by - 1.0), 2.5 + f * 3.0, PI, TAU, 6, Color(BREW_FOAM, 0.8 * (1.0 - f)), 0.8)
	# 채울 때 반짝임
	if _sparkle > 0.0:
		pd.glow(Vector2(0, -34), 34.0 * (1.2 - _sparkle * 0.2), Color(BREW_HI, 0.45 * _sparkle), 0.0)
	# 안내: 키보드 "↑ 달이기" 또는 터치 버튼
	var touch_on := _touch_on()
	if _prompt > 0.0:
		var a := _prompt
		var bob := sin(t * 3.0) * 1.0
		if touch_on:
			var r := BTN
			r.position.y += bob
			pd.draw_rect(r.grow(1.0), Color(OUT, 0.9 * a))
			pd.draw_rect(r, Color(EVfx.INK, 0.92 * a))
			pd.draw_rect(r, Color(EVfx.VIOLET, 0.95 * a), false, 1.0)
			pd.draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, 1)), Color(EVfx.MAGENTA, 0.5 * a))
		else:
			pd.draw_rect(Rect2(-27, PROMPT_Y - 11 + bob, 54, 15), Color(EVfx.INK, 0.8 * a))
			pd.draw_rect(Rect2(-27, PROMPT_Y - 11 + bob, 54, 15), Color(EVfx.VIOLET, 0.6 * a), false, 1.0)
	pd.flush(self)
	if _prompt > 0.0:
		var f := ThemeDB.fallback_font
		var a2 := _prompt
		var bob2 := sin(t * 3.0) * 1.0
		var label := "달이기" if touch_on else "↑ 달이기"
		var fs := 12 if touch_on else 11
		var w := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var y := BTN.position.y + 17.0 if touch_on else PROMPT_Y
		draw_string_outline(f, Vector2(-w * 0.5, y + bob2), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0, 0, 0, 0.7 * a2))
		draw_string(f, Vector2(-w * 0.5, y + bob2), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(EVfx.PALE, a2))
