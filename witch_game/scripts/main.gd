extends Node2D
## 손맛 프로토타입 한 판: 시험용 지형 + 마녀 + 허수아비 2개 + 안내 글.
## 지형은 이동·점프 수치를 확인하도록 높이를 타일 단위로 맞췄다 (점프 최고 3.25타일).

const T := Tuning.TILE
const GROUND_COLOR := Color(0.16, 0.13, 0.18)
const EDGE_COLOR := Color(0.3, 0.24, 0.3)
const SlashFx := preload("res://scripts/slash_fx.gd")
const PopupText := preload("res://scripts/popup_text.gd")

## 지형 블록 (타일 단위: x, y(윗면, 위가 −), 너비, 높이) — 땅 윗면이 y = 0
const BLOCKS := [
	[-16, -12, 4, 16], # 왼쪽 벽
	[-12, 0, 68, 4], # 시작 땅
	[16, -2, 5, 1], # 발판: 2타일 높이
	[23, -5, 4, 1], # 발판: 거기서 3타일 더 (점프 최고 높이 확인)
	[34, -3, 2, 3], # 3타일 턱 (점프로 넘을 수 있음)
	[56, 0, 4, 4], # 구덩이 앞 땅
	[60, 3, 4, 1], # 구덩이 바닥 (4타일 폭, 3타일 깊이)
	[64, 0, 24, 4], # 구덩이 건너 땅
	[88, -12, 4, 16], # 오른쪽 벽
]

var player: Player
var _info_label: Label
var _info_on := false


func _ready() -> void:
	_build_ground()
	player = Player.new()
	player.position = Vector2(2 * T, 0)
	add_child(player)
	player.swung.connect(_on_swung)

	var cam := Camera2D.new()
	cam.position = Vector2(0, -40)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	cam.limit_left = int(-16 * T)
	cam.limit_right = int(92 * T)
	cam.limit_bottom = int(6 * T)
	player.add_child(cam)
	cam.make_current()
	Feel.camera = cam

	for x in [12, 44]:
		var d := Dummy.new()
		d.position = Vector2(x * T, 0)
		add_child(d)
		d.hit_taken.connect(_on_hit_taken)

	_build_hud()


func _build_ground() -> void:
	for b in BLOCKS:
		var rect := Rect2(b[0] * T, b[1] * T, b[2] * T, b[3] * T)
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		var col := CollisionShape2D.new()
		col.shape = shape
		col.position = rect.get_center()
		body.add_child(col)
		add_child(body)
	queue_redraw()


func _draw() -> void:
	for b in BLOCKS:
		var rect := Rect2(b[0] * T, b[1] * T, b[2] * T, b[3] * T)
		draw_rect(rect, GROUND_COLOR)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2.0)), EDGE_COLOR)
		# 타일 눈금 (점프 높이·거리를 눈으로 재기 쉽게)
		var x := rect.position.x + T
		while x < rect.end.x:
			draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color(1, 1, 1, 0.04), 1.0)
			x += T
		var y := rect.position.y + T
		while y < rect.end.y:
			draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color(1, 1, 1, 0.04), 1.0)
			y += T


func _on_swung(data: Dictionary) -> void:
	var fx := SlashFx.new()
	add_child(fx)
	fx.setup(data)


func _on_hit_taken(at: Vector2, dmg: int, heavy: bool) -> void:
	var p := PopupText.new()
	add_child(p)
	p.setup(at, str(dmg), Color(1.0, 0.75, 0.4) if heavy else Color(1, 1, 1))


# ═══ 안내 글 ═══

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var help := _make_label("←→ 이동   Z·스페이스 점프   X 공격(땅 3연격·공중 2연격)   R 처음 위치   Tab 수치 보기")
	help.position = Vector2(6, 4)
	layer.add_child(help)
	var build := _make_label("손맛 프로토타입 · build %s" % BuildInfo.COMMIT)
	build.position = Vector2(6, 342)
	build.modulate = Color(1, 1, 1, 0.5)
	layer.add_child(build)
	_info_label = _make_label(_info_text())
	_info_label.position = Vector2(6, 22)
	_info_label.visible = false
	layer.add_child(_info_label)


func _make_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", Feel.font)
	l.add_theme_font_size_override("font_size", Feel.FONT_SIZE)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	return l


func _info_text() -> String:
	var lines := PackedStringArray([
		"이동  최고 속도 %d px/s · 가속 %.2fs · 감속 %.2fs" % [Tuning.RUN_SPEED, Tuning.ACCEL_TIME, Tuning.DECEL_TIME],
		"점프  높이 %d px(%.2f타일) · 정점 %.2fs · 낙하 중력 x%.1f · 코요테 %.2fs · 버퍼 %.2fs" % [
			Tuning.JUMP_HEIGHT, Tuning.JUMP_HEIGHT / Tuning.TILE, Tuning.JUMP_APEX_TIME,
			Tuning.FALL_GRAVITY_MULT, Tuning.COYOTE_TIME, Tuning.JUMP_BUFFER],
	])
	for id in Tuning.COMBO + Tuning.AIR_COMBO:
		var s: Dictionary = Tuning.SWINGS[id]
		lines.append("%s  준비 %.3f · 휘두름 %.3f · 거둠 %.2f · 피해 %d · 히트스톱 %.2f · 흔들림 %dpx" % [
			id, s["wu"], s["sw"], s["rec"], s["dmg"], s["hs"], s["shake"]])
	return "\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_info"):
		_info_on = not _info_on
		_info_label.visible = _info_on
