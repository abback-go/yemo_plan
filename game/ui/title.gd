extends Control
## 타이틀 (docs/archive/sera/chapter1.md 10절). 브라우저는 첫 입력 전 소리를 막으므로 "아무 키나"로 한 번 받은 뒤 메뉴를 연다.
## 메뉴: 이어하기(기록이 있으면) · 새로 시작 · 설정 · 전투 시제품(새 조작 훈련장, proto/) · 전투 연습장(v0.3 프로토타입)
## 홈 화면 웹앱(오프라인 캐시)에 새 버전이 받아져 있으면 맨 위에 "새 버전으로 업데이트"가 생긴다.
## 웹 주소 뒤에 ?blade 를 붙이면 빗자루 검 손맛 데모, ?eska_tut 를 붙이면 에스카 튜토리얼, ?eska_boss 를 붙이면 검성 보스전, ?eska 를 붙이면 에스카 시제품, ?proto 를 붙이면 처음 한 번은 타이틀을 건너뛰고 전투 시제품으로 바로 들어간다 (Esc로 나오면 타이틀).

const BG := preload("res://levels/background.gd")

var _t := 0.0
var _eska: EEska ## 타이틀의 마녀 = 게임 속 에스카 그림(EArt) 그대로 (작은 화면에 그려 3배로 키움)
var _font: Font
var _phase := 0 ## 0 아무 키 대기, 1 메뉴, 2 설정, 3 새로 시작 확인, 4 시작함
var _text: Control
var _menu: MenuList
static var _legacy := false ## 구버전(세라 데모) 메뉴를 보는 중 — 세라 데모에서 타이틀로 돌아오면 그 메뉴 그대로
var _confirm: MenuList
var _options: OptionsPanel
var _items: Array[String] = []
var _code_msg := ""
var _code_msg_t := 0.0
static var _direct_done := false ## ?proto 바로가기를 이미 썼는지 (시제품에서 나왔을 때 다시 튕기지 않게)


func _ready() -> void:
	Fx.reset()
	get_tree().paused = false
	if not _direct_done and OS.has_feature("web"):
		_direct_done = true
		var q: Variant = JavaScriptBridge.eval("window.location.search", true)
		if q is String and String(q).contains("blade"):
			_phase = 4
			get_tree().change_scene_to_file.call_deferred("res://proto/blade/blade_demo.tscn")
		elif q is String and String(q).contains("eska_tut"):
			_phase = 4
			get_tree().change_scene_to_file.call_deferred("res://proto/eska/eska_tutorial.tscn")
		elif q is String and String(q).contains("eska_boss"):
			_phase = 4
			get_tree().change_scene_to_file.call_deferred("res://proto/eska/eska_boss.tscn")
		elif q is String and String(q).contains("eska"):
			_phase = 4
			get_tree().change_scene_to_file.call_deferred("res://proto/eska/eska_arena.tscn")
		elif q is String and String(q).contains("proto"):
			_phase = 4
			get_tree().change_scene_to_file.call_deferred("res://proto/proto_arena.tscn")
	_font = get_theme_default_font()
	var sky := BG.SkyDraw.new()
	add_child(sky)
	var school := BG.LayerDraw.new()
	school.kind = BG.LayerDraw.Kind.SCHOOL
	school.position = Vector2(-200, 0)
	add_child(school)
	var mask := HeroMoon.new() # 하늘의 작은 달은 하늘색으로 덮음 (달은 하나 — 큰 달은 숲 앞에 따로)
	mask.mask_only = true
	add_child(mask)
	var forest := BG.LayerDraw.new()
	forest.kind = BG.LayerDraw.Kind.FOREST_NEAR
	forest.position = Vector2(0, 10)
	add_child(forest)
	var moon := HeroMoon.new() # 에스카 뒤 큰 보름달 — 숲 앞 (달 앞 전나무가 실루엣을 끊지 않게, loop8 4장)
	add_child(moon)

	var ground := ColorRect.new()
	ground.color = Palette.GROUND
	ground.position = Vector2(0, 318)
	ground.size = Vector2(640, 42)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ground)
	var ground_top := ColorRect.new()
	ground_top.color = Palette.GROUND_TOP
	ground_top.position = Vector2(0, 318)
	ground_top.size = Vector2(640, 2)
	ground_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ground_top)

	_add_eska()

	_text = TitleText.new()
	_text.title = self
	_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_text)

	_menu = MenuList.new()
	_menu.position = Vector2(284, 178)
	_menu.size = Vector2(220, 110)
	_menu.chosen.connect(_on_menu)
	_menu.visible = false
	add_child(_menu)
	_confirm = MenuList.new()
	_confirm.items = ["아니요", "예, 새로 시작"]
	_confirm.position = Vector2(284, 232)
	_confirm.size = Vector2(220, 40)
	_confirm.chosen.connect(_on_confirm)
	_confirm.visible = false
	add_child(_confirm)
	_options = OptionsPanel.new()
	_options.position = Vector2(284, 150)
	_options.visible = false
	_options.closed.connect(func() -> void:
		_options.visible = false
		_menu.visible = true
		_phase = 1)
	add_child(_options)
	Music.play("title", 1.5)
	if OS.has_feature("web"):
		JavaScriptBridge.pwa_update_available.connect(_on_pwa_update)


func _on_pwa_update() -> void:
	if _phase == 1:
		_build_menu()


## 첫 메뉴 = 현행(종언의 마녀 · 에스카). 세라 데모는 "구버전 (세라 데모)" 안으로 (docs/archive/sera/README.md)
func _build_menu() -> void:
	_items.clear()
	if OS.has_feature("web") and JavaScriptBridge.pwa_needs_update():
		_items.append("새 버전으로 업데이트")
	if _legacy:
		if GameState.has_save():
			_items.append("이어하기")
		_items.append("새로 시작")
		_items.append("저장 코드로 이어하기")
		_items.append("세라 전투 시제품")
		_items.append("전투 연습장")
		_items.append("← 돌아가기")
	else:
		_items.append("에스카 튜토리얼 (종언의 문턱)")
		_items.append("에스카 시제품 (종언의 마녀)")
		_items.append("에스카 보스전 (검성)")
		_items.append("구버전 (세라 데모)")
		_items.append("설정")
	_menu.items = _items.duplicate()
	_menu.selected = 0


## 타이틀의 에스카: 물리·입력 없이 서 있는 에스카(EEska + EArt)를 작은 SubViewport에 그리고, 그 그림을 3배로 키워 놓는다
## (줄 흔들림이 1배 크기 기준이라 노드를 키우지 않고 그림을 키움). 발밑 = 화면 (150, 318).
## 주인공 구도: 큰 보름달(HeroMoon) 앞 실루엣 + 등 뒤에서 천천히 도는 마녀 문장 고리(HeroSigil).
## 게임 속 1px 테두리 빛은 3배면 3px 회색 띠가 되므로 끄고(art.rim_on), 키운 그림 둘레에 화면 1px 외곽선을 셰이더로 따로 그린다(OUTLINE_SHADER).
## 모자 챙 반짝 점은 양 끝 둘만, 챙 그늘은 빼서 얼굴이 읽히게(art.calm)
const ESKA_VIEW := Vector2i(56, 64) ## 그림 칸 크기 (모자·머리칼·치맛자락이 다 들어가게)
const ESKA_FEET := Vector2(28, 58) ## 그림 칸 안 발밑
const ESKA_SCALE := 3.0
const ESKA_AT := Vector2(150, 318)
const ESKA_LINE := Color("#b9a2ff") ## 둘레 외곽선: 라벤더, 아트 픽셀 1칸(= 화면 3px — 키운 그림과 같은 밀도, loop8 4장)
const ESKA_DIM := 0.4 ## 달 앞 실루엣: 몸 명도 −60% (흰 머리칼이 달과 같은 명도라 윤곽이 녹던 문제)
const OUTLINE_SHADER := """
shader_type canvas_item;
uniform vec4 line_col : source_color;
uniform vec2 step_uv; // 그림 칸 텍셀 1개 (= 키운 화면 3px)
uniform float dim = 0.4; // 몸 명도 배수 (먹빛 실루엣)
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a < 0.5) {
		float a = max(max(texture(TEXTURE, UV + vec2(step_uv.x, 0.0)).a, texture(TEXTURE, UV - vec2(step_uv.x, 0.0)).a),
			max(texture(TEXTURE, UV + vec2(0.0, step_uv.y)).a, texture(TEXTURE, UV - vec2(0.0, step_uv.y)).a));
		c = a > 0.5 ? line_col : vec4(0.0);
	} else {
		c.rgb *= dim;
	}
	COLOR = c;
}
"""


func _add_eska() -> void:
	var vp := SubViewport.new()
	vp.size = ESKA_VIEW
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(vp)
	_eska = EEska.new()
	_eska.position = ESKA_FEET
	vp.add_child(_eska)
	_eska.set_physics_process(false) # 물리·입력 없이 그림만
	_eska.set_process(false)
	_eska.art.stand = true
	_eska.art.rim_on = false
	_eska.art.calm = true
	var sig := HeroSigil.new() # 등 뒤 문장 고리 (에스카 그림 바로 뒤)
	sig.position = ESKA_AT + Vector2(0, -24.0 * ESKA_SCALE)
	add_child(sig)
	var sp := Sprite2D.new()
	sp.texture = vp.get_texture()
	sp.centered = false
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.scale = Vector2(ESKA_SCALE, ESKA_SCALE)
	sp.position = ESKA_AT - ESKA_FEET * ESKA_SCALE
	var sh := Shader.new()
	sh.code = OUTLINE_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("line_col", ESKA_LINE)
	mat.set_shader_parameter("step_uv", Vector2(1.0 / float(ESKA_VIEW.x), 1.0 / float(ESKA_VIEW.y)))
	mat.set_shader_parameter("dim", ESKA_DIM)
	sp.material = mat
	add_child(sp)


func _process(delta: float) -> void:
	_t += delta
	_code_msg_t = maxf(_code_msg_t - delta, 0.0)
	if is_instance_valid(_eska):
		_eska.art.tick(delta)
	_text.queue_redraw()


func draw_text_on(c: CanvasItem) -> void:
	c.draw_rect(Rect2(258, 40, 300, 268), Color(0.03, 0.02, 0.06, 0.62))
	c.draw_rect(Rect2(258, 40, 2, 268), Color(Palette.FIRE_OUT, 0.6))
	c.draw_string(_font, Vector2(270, 92), "YEMO", HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Palette.FIRE_HOT)
	if _legacy:
		c.draw_string(_font, Vector2(272, 116), "구버전 · 마녀학교와 여우신 (1~5장 데모)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_TEXT)
		c.draw_string(_font, Vector2(272, 140), "폐급 마녀 세라와 여우신 너울의 이야기", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_DIM)
	else:
		c.draw_string(_font, Vector2(272, 116), "종언의 마녀 · 시제품", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_TEXT)
		c.draw_string(_font, Vector2(272, 140), "세계를 끝내러 온 마녀 에스카의 이야기", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_DIM)
	c.draw_string(_font, Vector2(420, 350), "빌드 " + BuildInfo.COMMIT, HORIZONTAL_ALIGNMENT_RIGHT, 210, 12, Color(Palette.UI_DIM, 0.6))
	match _phase:
		0:
			if fmod(_t, 1.0) < 0.65:
				c.draw_string(_font, Vector2(272, 230), "화면을 누르세요" if _touch_screen() else "아무 키나 누르세요", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.GOLD)
			c.draw_string(_font, Vector2(272, 290), "터치 · 키보드 · 게임패드" if _touch_screen() else "키보드 또는 게임패드", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_DIM)
		1:
			c.draw_string(_font, Vector2(272, 300), "눌러서 고르기" if TouchControls.active else "↑↓ 고르기 · Z 확인", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_DIM)
			if _code_msg_t > 0.0:
				c.draw_multiline_string(_font, Vector2(272, 322), _code_msg, HORIZONTAL_ALIGNMENT_LEFT, 280, 12, 2, Color(1.0, 0.55, 0.45, minf(_code_msg_t, 1.0)))
		3:
			c.draw_string(_font, Vector2(272, 208), "기록을 지우고 처음부터 시작할까요?", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_TEXT)


func _touch_screen() -> bool:
	return TouchControls.active or DisplayServer.is_touchscreen_available()


func _input(event: InputEvent) -> void:
	if _t < 0.3 or _phase == 4:
		return
	match _phase:
		0:
			var pressed: bool = (event is InputEventKey and event.pressed and not event.echo) \
				or (event is InputEventJoypadButton and event.pressed) \
				or (event is InputEventMouseButton and event.pressed)
			if pressed:
				get_viewport().set_input_as_handled()
				Sfx.play(&"ui_ok", 0.0, 0.0)
				_build_menu()
				_menu.visible = true
				_phase = 1
		1:
			if _menu.handle_input(event) and is_inside_tree():
				get_viewport().set_input_as_handled() # 장면이 바뀌었으면 이미 트리 밖
		2:
			if _options.handle_input(event):
				get_viewport().set_input_as_handled()
		3:
			if _confirm.handle_input(event):
				if is_inside_tree():
					get_viewport().set_input_as_handled()
			elif event.is_action_pressed("ui_cancel"):
				_confirm.visible = false
				_menu.visible = true
				_phase = 1


func _on_menu(index: int) -> void:
	match _items[index]:
		"새 버전으로 업데이트":
			_phase = 4
			JavaScriptBridge.pwa_update() # 새 캐시로 바꾸고 다시 불러온다 (기록은 그대로)
		"이어하기":
			_phase = 4
			Music.stop(0.8)
			if not GameState.continue_game():
				_phase = 1
		"새로 시작":
			if GameState.has_save():
				_menu.visible = false
				_confirm.visible = true
				_confirm.selected = 0
				_phase = 3
			else:
				_start_new()
		"저장 코드로 이어하기":
			var code := SaveCodeUI.ask_code()
			if code.strip_edges() == "":
				return
			if GameState.import_code(code):
				_phase = 4
				Music.stop(0.8)
				if not GameState.continue_game():
					_phase = 1
			else:
				_code_msg = "저장 코드가 올바르지 않아요. YEMO1- 부터 끝까지 전부 붙여 넣었는지 확인해 주세요."
				_code_msg_t = 5.0
				Sfx.play(&"block", -2.0, 0.0)
		"설정":
			_menu.visible = false
			_options.open()
			_options.visible = true
			_phase = 2
		"에스카 튜토리얼 (종언의 문턱)":
			_phase = 4
			get_tree().change_scene_to_file("res://proto/eska/eska_tutorial.tscn")
		"에스카 시제품 (종언의 마녀)":
			_phase = 4
			get_tree().change_scene_to_file("res://proto/eska/eska_arena.tscn")
		"에스카 보스전 (검성)":
			_phase = 4
			get_tree().change_scene_to_file("res://proto/eska/eska_boss.tscn")
		"구버전 (세라 데모)", "← 돌아가기":
			_legacy = not _legacy
			_build_menu()
		"세라 전투 시제품":
			_phase = 4
			get_tree().change_scene_to_file("res://proto/proto_arena.tscn")
		"전투 연습장":
			_phase = 4
			GameState.new_run()
			GameState.start_stage()


func _on_confirm(index: int) -> void:
	if index == 1:
		GameState.delete_save()
		_start_new()
	else:
		_confirm.visible = false
		_menu.visible = true
		_phase = 1


func _start_new() -> void:
	_phase = 4
	Music.stop(1.0)
	GameState.start_new_game()


class TitleText extends Control:
	var title: Node

	func _draw() -> void:
		title.draw_text_on(self)


## 타이틀 주인공 구도: 에스카 뒤 큰 보름달 (옅은 보랏빛 흰색, 파랑 없음). 하늘 그림(BG.SkyDraw)의 작은 달 자리는 하늘색 띠로 덮어 달을 하나로
class HeroMoon extends Node2D:
	const C := Vector2(150, 246) ## 달 가운데 = 에스카 몸 가운데 (등 뒤 문장 고리와 같은 중심 — loop8 4장)
	const R := 62.0
	const FACE := Color("#ece4f6")
	const SHADE := Color("#cfc3e4")
	const OLD_MOON := Vector2(500, 70) ## BG.SkyDraw의 달 자리
	const OLD_R := 36.0
	var mask_only := false ## true = 하늘의 작은 달만 덮음 (하늘 바로 위), false = 큰 달만 (숲 앞)

	func _draw() -> void:
		if not mask_only:
			_draw_moon()
			return
		var top := Palette.SKY_TOP.lerp(Palette.SKY_BOTTOM, (OLD_MOON.y - OLD_R) / 360.0)
		var bot := Palette.SKY_TOP.lerp(Palette.SKY_BOTTOM, (OLD_MOON.y + OLD_R) / 360.0)
		var r0 := Rect2(OLD_MOON - Vector2(OLD_R, OLD_R), Vector2(OLD_R, OLD_R) * 2.0)
		draw_polygon(PackedVector2Array([r0.position, Vector2(r0.end.x, r0.position.y), r0.end, Vector2(r0.position.x, r0.end.y)]), PackedColorArray([top, top, bot, bot]))
		for i in 70: # 덮은 자리의 별은 다시 (BG.SkyDraw와 같은 자리)
			var p := Vector2(fmod(i * 97.13, 640.0), fmod(i * 53.71 + i * i * 0.37, 230.0))
			if r0.has_point(p):
				draw_rect(Rect2(p, Vector2.ONE), Color(1, 0.95, 0.9, 0.25 + fmod(i * 0.618, 0.6)))

	func _draw_moon() -> void:
		draw_circle(C, R + 34.0, Color(FACE, 0.04))
		draw_circle(C, R + 16.0, Color(FACE, 0.07))
		draw_circle(C, R, FACE)
		for spec: Array in [[Vector2(-22, -18), 11.0], [Vector2(18, 10), 8.0], [Vector2(-8, 26), 6.0], [Vector2(28, -24), 5.0]]:
			draw_circle(C + (spec[0] as Vector2), float(spec[1]), SHADE)


## 등 뒤 마녀 문장 고리: 두 겹 원 + 일곱 갈래 별 {7/2} + 원 사이 작은 점, 아주 천천히 돎 (EVfx.Sigil과 같은 모양 말투)
class HeroSigil extends Node2D:
	const R := 46.0
	const SPIN := 0.18 ## 초당 회전 (라디안)
	const LINE := Color(0.66, 0.42, 0.95, 0.75)
	const EDGE := Color(0.96, 0.82, 1.0, 0.85)
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var sp := _t * SPIN
		draw_arc(Vector2.ZERO, R, 0.0, TAU, 64, EDGE, 1.0)
		draw_arc(Vector2.ZERO, R * 0.82, 0.0, TAU, 56, LINE, 1.0)
		var st := PackedVector2Array()
		for i in 7:
			st.append(Vector2.from_angle(sp + float(i) * TAU / 7.0) * R * 0.8)
		for i in 7:
			draw_line(st[i], st[(i + 2) % 7], LINE, 1.0)
		for i in 14:
			var a := -sp * 0.6 + float(i) * TAU / 14.0
			draw_rect(Rect2(Vector2.from_angle(a) * R * 0.91 - Vector2(1, 1), Vector2(2, 2)), EDGE)

