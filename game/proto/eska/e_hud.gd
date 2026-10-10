class_name EHud
extends Control
## 에스카 시제품 화면 표시: 왼쪽 위 이름, 키보드일 때 아래쪽에 키 안내와 스킬 쿨다운.
## (터치 중에는 버튼이 쿨다운을 보여 주므로 키 안내를 숨긴다)

var eska: EEska
var touch: ETouch


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	_text(font, Vector2(10, 18), "에스카 · 종언의 마녀", 12, Color(1, 1, 1, 0.9))
	_text(font, Vector2(10, 32), "전투 시제품", 11, Color("#a98bff"))
	if touch and touch.active:
		return
	if not is_instance_valid(eska):
		return
	var y := 340.0
	_text(font, Vector2(10, y), "←→ 이동  Z 점프  X 연격  C 순간이동  Esc 나가기", 11, Color(1, 1, 1, 0.6))
	var x := 330.0
	for spec: Array in [["A", "cheonyeol"], ["↑A", "dangong"], ["S", "bonggong"], ["D", "ult"]]:
		var id: String = spec[1]
		var left := eska.cd_left(id)
		var name: String = EEska.NAMES[id]
		var col := Color(1, 1, 1, 0.9) if left <= 0.0 else Color(1, 1, 1, 0.35)
		var label := "%s %s" % [spec[0], name]
		if left > 0.0:
			label += " %.1f" % left
		_text(font, Vector2(x, y), label, 11, col)
		x += font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 12.0


func _text(font: Font, p: Vector2, s: String, fs: int, col: Color) -> void:
	draw_string_outline(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0, 0, 0, 0.7))
	draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
