extends EStage
## 에스카 훈련장: 마녀 분위기의 일자형 마당 + 허수아비 하나 + 끝없는 적 물결(EWaves).
## 적 물결은 오른쪽 위 버튼이나 W 키로 켜고 끈다 (기본 켜짐).
## 오른쪽 끝은 공간 고정 시험 구역: 떨어지는 돌을 봉공으로 굳혀 밟고 높은 턱(점프로는 안 닿음)에 오른다.
## 봉공 시간(1.5초 기본 ↔ 3초 진화)은 오른쪽 위 두 번째 버튼이나 T 키로 바꾼다.
## 들어오는 길: 타이틀 메뉴 "에스카 시제품" 또는 웹 주소 뒤 ?eska

const W := 1280.0
const FLOOR := 300.0
const SHELF := Rect2(1150, FLOOR - 200.0, 114, 14) ## 공간 고정 시험: 이단점프(81)로는 안 닿는 높은 턱
const ROCK_XS: Array[float] = [1040.0, 1096.0] ## 돌이 떨어지는 두 기둥 (반 간격씩 어긋남 → 굳히면 엇갈린 계단)

var dummy: PDummy
var waves: EWaves
var _wave_btn: Button
var _still_btn: Button
var shelf_hits := 0 ## 시험 구역 턱에 오른 횟수
var _on_shelf := false


func _build() -> void:
	stage_w = W
	floor_y = FLOOR
	cam_top = FLOOR - 560.0
	respawn_at = Vector2(400, FLOOR)
	EScenery.build(self, W, FLOOR)
	flat_ground()
	dummy = PDummy.new()
	dummy.setup("small")
	dummy.position = Vector2(540, FLOOR)
	add_child(dummy)
	solid(SHELF)
	var mark := ShelfMark.new()
	mark.shelf = SHELF
	add_child(mark)
	var fall := EStill.RockFall.new()
	fall.xs = ROCK_XS
	fall.top = FLOOR - 430.0
	fall.floor_y = FLOOR
	add_child(fall)


func _start() -> void:
	waves = EWaves.new()
	waves.stage = self
	add_child(waves)
	_wave_btn = _make_button("적 물결: 켜짐", 8.0, _toggle_waves)
	hud.get_parent().add_child(_wave_btn)
	_still_btn = _make_button(_still_label(), 34.0, _toggle_still)
	hud.get_parent().add_child(_still_btn)


func _process(delta: float) -> void:
	super._process(delta)
	if Input.is_action_just_pressed("es_waves"):
		_toggle_waves()
	if Input.is_action_just_pressed("es_still_t"):
		_toggle_still()
	var up := eska.is_on_floor() and eska.global_position.y <= SHELF.position.y + 2.0 and eska.global_position.x > SHELF.position.x
	if up and not _on_shelf:
		shelf_hits += 1
		hud.banner("공간 고정", "떨어지는 돌을 굳혀 올라왔다", 1.6)
		Sfx.play(&"checkpoint", -4.0)
	_on_shelf = up


func _toggle_waves() -> void:
	waves.set_on(not waves.enabled)
	_wave_btn.text = "적 물결: 켜짐" if waves.enabled else "적 물결: 꺼짐"


## 봉공 시간 1.5초(기본) ↔ 3초(진화)
func _toggle_still() -> void:
	eska.still_time = EEska.STILL_EVOLVED if eska.still_time < EEska.STILL_EVOLVED else EEska.STILL_BASE
	_still_btn.text = _still_label()


func _still_label() -> String:
	return "봉공: %.1f초" % eska.still_time


## 오른쪽 위(나가기 ✕ 왼쪽) 작은 버튼 — 터치·마우스 모두. 키보드 포커스는 받지 않음 (Z·X가 눌러 버리지 않게)
func _make_button(text: String, top: float, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	b.offset_left = -146.0
	b.offset_right = -42.0
	b.offset_top = top
	b.offset_bottom = top + 22.0
	b.add_theme_font_size_override("font_size", 11)
	for st: Array in [["normal", 0.75, 0.5], ["hover", 0.9, 0.9], ["pressed", 0.95, 1.0]]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(EVfx.INK, float(st[1]))
		sb.border_color = Color(EVfx.VIOLET, float(st[2]))
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(4)
		b.add_theme_stylebox_override(String(st[0]), sb)
	b.add_theme_color_override("font_color", EVfx.PALE)
	b.pressed.connect(on_press)
	return b


## 시험 실행기 eval용: 적 하나 놓기
func spawn_foe(kind: String, x: float, y: float) -> String:
	var e := EWaves.spawn(self, kind, Vector2(x, y))
	return "%s hp=%d" % [kind, e.max_hp]


## 시험 실행기 eval용: 굳은 돌 하나 위에 에스카를 올려 놓기 (공간 고정 발판 시험)
func put_on_rock() -> String:
	for n: Node in get_tree().get_nodes_in_group(EStill.GROUP):
		var r := n as Node2D
		if r.position.y > FLOOR - 160.0 and r.position.y < FLOOR - 60.0:
			eska.global_position = r.position + Vector2(0, -EStill.Rock.SIZE.y * 0.5 - 1.0)
			eska.velocity = Vector2.ZERO
			return "rock x=%d y=%d" % [int(r.position.x), int(r.position.y)]
	return "none"


## 시험 실행기 eval용: 살아 있는 적 상태
func foes() -> String:
	var out := ""
	for n: Node in get_children():
		if n is EEnemy:
			var e := n as EEnemy
			out += "%s(x=%d hp=%d st=%d still=%.2f) " % [e.get_script().get_global_name(), int(e.global_position.x), e.hp, int(e.get("st")), float(e.get("_bound"))]
	return out


## 시험 구역 표시: 높은 턱(돌 난간) + 안내 글씨
class ShelfMark extends Node2D:
	var shelf: Rect2
	var pd := PDraw.new()

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		pd.draw_rect(shelf, Color("#241d2c"))
		pd.draw_rect(Rect2(shelf.position, Vector2(shelf.size.x, 3)), Color("#6b5c80"))
		pd.draw_line(shelf.position + Vector2(0, 3), shelf.position + Vector2(shelf.size.x, 3), Color(EVfx.VIOLET, 0.6), 1.0)
		pd.flush(self)
		var f := ThemeDB.fallback_font
		var at := Vector2(shelf.position.x - 296.0, shelf.position.y + 70.0) # 돌 기둥 왼쪽
		draw_string(f, at, "봉공(S)으로 떨어지는 돌을", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(EVfx.PALE, 0.75))
		draw_string(f, at + Vector2(0, 14), "굳혀 밟고 오르기 →", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(EVfx.PALE, 0.75))
