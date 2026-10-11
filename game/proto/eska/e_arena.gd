extends EStage
## 에스카 훈련장: 마녀 분위기의 일자형 마당 + 허수아비 하나 + 끝없는 적 물결(EWaves).
## 적 물결은 오른쪽 위 버튼이나 W 키로 켜고 끈다 (기본 켜짐).
## 오른쪽 끝은 공간 고정 시험 구역: 떨어지는 돌을 봉공으로 굳혀 밟고 높은 턱(점프로는 안 닿음)에 오른다.
## 봉공 진화(굳은 동안 준 피해의 50%가 깨질 때 터짐)는 오른쪽 위 두 번째 버튼이나 T 키로 켜고 끈다.
## 종언 게이지는 오른쪽 위 세 번째 버튼 "게이지 가득"이나 G 키로 바로 채운다 (대마법 시험). 왼쪽 끝에 마녀의 가마솥.
## 허수아비 위에 틈 달이기 안내판 (천열로 찢은 틈에 물약을 던져 넣기 — loop3 1장).
## 들어오는 길: 타이틀 메뉴 "에스카 시제품" 또는 웹 주소 뒤 ?eska

const W := 1280.0
const FLOOR := 300.0
const SHELF := Rect2(1150, FLOOR - 200.0, 114, 14) ## 공간 고정 시험: 이단점프(81)로는 안 닿는 높은 턱
const ROCK_XS: Array[float] = [1040.0, 1096.0] ## 돌이 떨어지는 두 기둥 (반 간격씩 어긋남 → 굳히면 엇갈린 계단)
const CAULDRON_X := 250.0 ## 가마솥 자리 (부활 자리 왼쪽)
const RIFT_SIGN := Vector2(468, FLOOR - 150.0) ## 틈 달이기 안내판 글자 왼쪽 위 (허수아비 위 — 처음 화면에 다 보이게)
const BTN_TOP := [8.0, 34.0] ## 오른쪽 위 시험 버튼들의 위 끝 (적 물결 · 봉공 진화). 그 아래는 연타 수 자리
const BTN_W := 104.0 ## 시험 버튼 너비
const BTN_RIGHT := -42.0 ## 첫 줄 버튼 오른쪽 끝 (나가기 ✕ 왼쪽)
const BTN_COL2 := -110.0 ## "게이지 가득"은 왼쪽 옆 줄에 (연타 수와 겹치지 않게)

var dummy: PDummy
var waves: EWaves
var _wave_btn: Button
var _still_btn: Button
var _gauge_btn: Button
var cauldron: ECauldron
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
	cauldron = ECauldron.place(self, Vector2(CAULDRON_X, FLOOR))
	var sign := RiftSign.new()
	sign.at = RIFT_SIGN
	add_child(sign)


func _start() -> void:
	waves = EWaves.new()
	waves.stage = self
	add_child(waves)
	_wave_btn = _make_button("적 물결: 켜짐", BTN_TOP[0], _toggle_waves)
	hud.get_parent().add_child(_wave_btn)
	_still_btn = _make_button(_still_label(), BTN_TOP[1], _toggle_still)
	hud.get_parent().add_child(_still_btn)
	_gauge_btn = _make_button("게이지 가득", BTN_TOP[0], _fill_gauge, BTN_COL2)
	hud.get_parent().add_child(_gauge_btn)


func _process(delta: float) -> void:
	super._process(delta)
	var show_btns := not hud.cinematic # 연출 중엔 시험 버튼도 숨김
	for b: Button in [_wave_btn, _still_btn, _gauge_btn]:
		if b.visible != show_btns:
			b.visible = show_btns
	if Input.is_action_just_pressed("es_waves"):
		_toggle_waves()
	if Input.is_action_just_pressed("es_still_t"):
		_toggle_still()
	if Input.is_action_just_pressed("es_gauge_fill"):
		_fill_gauge()
	var up := eska.is_on_floor() and eska.global_position.y <= SHELF.position.y + 2.0 and eska.global_position.x > SHELF.position.x
	if up and not _on_shelf:
		shelf_hits += 1
		hud.banner("공간 고정", "떨어지는 돌을 굳혀 올라왔다", 1.6)
		Sfx.play(&"checkpoint", -4.0)
	_on_shelf = up


func _toggle_waves() -> void:
	waves.set_on(not waves.enabled)
	_wave_btn.text = "적 물결: 켜짐" if waves.enabled else "적 물결: 꺼짐"


## 봉공 진화 켜기/끄기 (1장 무구를 거둔 상태 시험)
func _toggle_still() -> void:
	eska.still_evolved = not eska.still_evolved
	_still_btn.text = _still_label()


## 시험용: 종언 게이지를 바로 가득 (대마법 시험)
func _fill_gauge() -> void:
	eska.fill_gauge()


func _still_label() -> String:
	return "봉공 진화: 켜짐" if eska.still_evolved else "봉공 진화: 꺼짐"


## 오른쪽 위(나가기 ✕ 왼쪽) 작은 버튼 — 터치·마우스 모두. shift = 옆 줄로 옮기는 양(음수 = 왼쪽). 키보드 포커스는 받지 않음 (Z·X가 눌러 버리지 않게)
func _make_button(text: String, top: float, on_press: Callable, shift := 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	b.offset_left = BTN_RIGHT - BTN_W + shift
	b.offset_right = BTN_RIGHT + shift
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
		draw_string(f, at, "대마법 봉공으로 떨어지는 돌을", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(EVfx.PALE, 0.75))
		draw_string(f, at + Vector2(0, 14), "굳혀 밟고 오르기 →", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(EVfx.PALE, 0.75))
		draw_string(f, at + Vector2(0, 28), "(D로 봉공 고르기 · 게이지 가득이면 S · G 채우기)", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(EVfx.PALE, 0.55))


## 틈 달이기 안내판: 작은 틈 그림 + 안내 글씨 (시험 구역 안내판과 같은 방식, 정적 — 한 번만 그림)
class RiftSign extends Node2D:
	const LINES := ["틈 달이기", "천열(A)로 찢은 틈이 열려 있을 때", "물약을 던져 넣으면(↓F 속박 등)", "진하게 스며들어 강자에게도 다 걸린다"]
	const LINE_H := 14.0
	var at := Vector2.ZERO
	var pd := PDraw.new()

	func _ready() -> void:
		z_index = -1

	func _draw() -> void:
		# 왼쪽 작은 틈: 검은 무 + 마젠타 테 + 흰 금 (안내하는 대상을 그림으로)
		var c := at + Vector2(-12, 22)
		var tear := PackedVector2Array([c + Vector2(0, -16), c + Vector2(3, -6), c + Vector2(2, 4), c + Vector2(0, 16), c + Vector2(-2, 5), c + Vector2(-3, -7)])
		pd.glow(c, 18.0, Color(EVfx.MAGENTA, 0.18), 0.0)
		pd.outlined(tear, EVfx.VOID, EVfx.MAGENTA, 1.0)
		pd.draw_line(c + Vector2(0, -11), c + Vector2(0, 11), Color(EVfx.EDGE, 0.8), 1.0)
		pd.flush(self)
		var f := ThemeDB.fallback_font
		for i in LINES.size():
			var col := Color(EVfx.EDGE, 0.85) if i == 0 else Color(EVfx.PALE, 0.75)
			draw_string(f, at + Vector2(0, LINE_H * float(i) + 11.0), LINES[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12 if i == 0 else 11, col)
