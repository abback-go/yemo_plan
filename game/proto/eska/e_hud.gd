class_name EHud
extends Control
## 에스카 시제품 화면 표시
## - 왼쪽 위: 이름 + 빌드 번호(어느 버전이 떠 있는지 바로 확인)
## - 오른쪽 위: 연타 수(맞힐 때마다 튀어 오름) + 누적 피해, 끊기기 직전엔 흐려짐
## - 아래(키보드일 때만): 키 안내 + 스킬 쿨다운 (터치 중에는 버튼이 쿨다운을 보여 줌)
## 값이 바뀔 때만 다시 그린다 (글자 그리기는 비싸서).

const PALE := Color("#d9ccff")
const VIOLET := Color("#a98bff")

var eska: EEska
var touch: ETouch
var _sig := ""
var _last_hits := 0
var _pop := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if not is_instance_valid(eska):
		return
	if eska.hit_count != _last_hits:
		if eska.hit_count > _last_hits:
			_pop = 1.0
		_last_hits = eska.hit_count
	_pop = maxf(_pop - delta * 6.0, 0.0)
	var sig := "%d|%d|%.1f|%s|%d|%d|%d|%d" % [eska.hit_count, eska.hit_damage, eska.combo_left, str(touch.active if touch else false),
		ceili(eska.cd_left("cheonyeol") * 10.0), ceili(eska.cd_left("dangong") * 10.0), ceili(eska.cd_left("bonggong") * 10.0), ceili(eska.cd_left("ult") * 10.0)]
	if _pop > 0.0:
		sig += "|%.2f" % _pop
	if sig != _sig:
		_sig = sig
		queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	_text(font, Vector2(10, 18), "에스카 · 종언의 마녀", 12, Color(1, 1, 1, 0.9))
	_text(font, Vector2(10, 32), "전투 시제품 · 빌드 " + BuildInfo.COMMIT, 11, VIOLET)
	if not is_instance_valid(eska):
		return
	_draw_combo(font)
	if touch and touch.active:
		return
	var y := size.y - 20.0
	_text(font, Vector2(10, y), "←→ 이동  Z 점프  X 연격  C 순간이동  ↓ 빨리 떨어지기  Esc 나가기", 11, Color(1, 1, 1, 0.6))
	var x := 10.0
	y = size.y - 36.0
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


func _draw_combo(font: Font) -> void:
	if eska.hit_count <= 1:
		return
	var a := clampf(eska.combo_left / 0.4, 0.25, 1.0)
	var right := size.x - 12.0 if not (touch and touch.active) else size.x - 44.0
	var num := "%d" % eska.hit_count
	var fs := 22
	var sc := 1.0 + _pop * 0.35
	var nsz := font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var hit_w := font.get_string_size("HIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var base := Vector2(right - hit_w - 4.0, 62.0)
	draw_set_transform(base, 0.0, Vector2(sc, sc))
	draw_string_outline(font, Vector2(-nsz.x, 0), num, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(0.08, 0.02, 0.16, a))
	draw_string(font, Vector2(-nsz.x, 0), num, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(PALE.lerp(Color.WHITE, _pop), a))
	draw_set_transform(Vector2.ZERO)
	_text(font, Vector2(right - hit_w, 62.0), "HIT", 11, Color(VIOLET, a))
	# 끊기기까지 남은 시간 막대 + 누적 피해
	var bw := 60.0
	draw_rect(Rect2(right - bw, 68.0, bw, 2.0), Color(1, 1, 1, 0.12 * a))
	draw_rect(Rect2(right - bw, 68.0, bw * eska.combo_left / EEska.COMBO_WINDOW, 2.0), Color(VIOLET, 0.9 * a))
	var dmg := "%d" % eska.hit_damage
	var dw := font.get_string_size(dmg, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	_text(font, Vector2(right - dw, 82.0), dmg, 11, Color(1, 1, 1, 0.65 * a))


func _text(font: Font, p: Vector2, s: String, fs: int, col: Color) -> void:
	draw_string_outline(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0, 0, 0, 0.7 * col.a))
	draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
