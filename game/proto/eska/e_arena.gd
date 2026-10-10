extends EStage
## 에스카 훈련장: 마녀 분위기의 일자형 마당 + 허수아비 하나 + 끝없는 적 물결(EWaves).
## 적 물결은 오른쪽 위 버튼이나 W 키로 켜고 끈다 (기본 켜짐).
## 들어오는 길: 타이틀 메뉴 "에스카 시제품" 또는 웹 주소 뒤 ?eska

const W := 1280.0
const FLOOR := 300.0

var dummy: PDummy
var waves: EWaves
var _wave_btn: Button


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


func _start() -> void:
	waves = EWaves.new()
	waves.stage = self
	add_child(waves)
	_wave_btn = _make_wave_button()
	hud.get_parent().add_child(_wave_btn)


func _process(delta: float) -> void:
	super._process(delta)
	if Input.is_action_just_pressed("es_waves"):
		_toggle_waves()


func _toggle_waves() -> void:
	waves.set_on(not waves.enabled)
	_wave_btn.text = "적 물결: 켜짐" if waves.enabled else "적 물결: 꺼짐"


## 오른쪽 위(나가기 ✕ 왼쪽) 작은 버튼 — 터치·마우스 모두. 키보드 포커스는 받지 않음 (Z·X가 눌러 버리지 않게)
func _make_wave_button() -> Button:
	var b := Button.new()
	b.text = "적 물결: 켜짐"
	b.focus_mode = Control.FOCUS_NONE
	b.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	b.offset_left = -146.0
	b.offset_right = -42.0
	b.offset_top = 8.0
	b.offset_bottom = 30.0
	b.add_theme_font_size_override("font_size", 11)
	for st: Array in [["normal", 0.75, 0.5], ["hover", 0.9, 0.9], ["pressed", 0.95, 1.0]]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(EVfx.INK, float(st[1]))
		sb.border_color = Color(EVfx.VIOLET, float(st[2]))
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(4)
		b.add_theme_stylebox_override(String(st[0]), sb)
	b.add_theme_color_override("font_color", EVfx.PALE)
	b.pressed.connect(_toggle_waves)
	return b


## 시험 실행기 eval용: 적 하나 놓기
func spawn_foe(kind: String, x: float, y: float) -> String:
	var e := EWaves.spawn(self, kind, Vector2(x, y))
	return "%s hp=%d" % [kind, e.max_hp]


## 시험 실행기 eval용: 살아 있는 적 상태
func foes() -> String:
	var out := ""
	for n: Node in get_children():
		if n is EEnemy:
			var e := n as EEnemy
			out += "%s(x=%d hp=%d st=%d) " % [e.get_script().get_global_name(), int(e.global_position.x), e.hp, int(e.get("st"))]
	return out
