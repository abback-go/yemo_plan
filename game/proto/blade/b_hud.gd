class_name BHud
extends Control
## 빗자루 검 데모 화면 표시: 왼쪽 위 모드 두 칸(지금 모드가 밝음) + 스킬 이름·쿨다운 막대, 오른쪽 위 연타 수,
## 위 가운데 안내 한 줄(처음엔 모드 바꾸기, 틈 자국이 있으면 터뜨리는 법), 아래 키 안내(키보드일 때만).

const PALE := Color("#e6dcff")
const LAV := Color("#b9a2ff")
const INK := Color("#14081f")
const HELP_KEYS := "←→ 이동   Z 점프   X 공격   A 스킬   S 모드 바꾸기   Esc 나가기"
const INTRO := 7.0 ## 처음 안내를 보여 주는 시간

var eska: BEska
var stage: BStage
var _t := 0.0
var _sig := ""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## 보이는 것이 바뀔 때만 다시 그린다 (글자 테두리 그리기가 비싸서 — 매 프레임 그리면 처리 시간이 약 10ms 늘었다)
func _process(delta: float) -> void:
	_t += delta
	size = get_viewport_rect().size # 캔버스 층 아래 Control은 앵커로 화면 크기를 못 받아서 직접 맞춘다
	if not is_instance_valid(eska):
		return
	var sig := "%d|%d|%d|%d|%s|%s|%s" % [eska.mode, int(eska.skill_ratio() * 42.0), eska.hit_count,
		int(clampf(eska.combo_left / 0.4, 0.0, 1.0) * 8.0), _hint(eska.mode == BEska.Mode.SWORD), EKeys.touch_mode, size]
	if sig != _sig:
		_sig = sig
		queue_redraw()


func _text(font: Font, p: Vector2, s: String, fs: int, col: Color) -> void:
	draw_string_outline(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(INK, 0.85 * col.a))
	draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _draw() -> void:
	if not is_instance_valid(eska):
		return
	var font := get_theme_default_font()
	var sword := eska.mode == BEska.Mode.SWORD
	# 모드 두 칸
	var x := 8.0
	for i in 2:
		var on := (i == 1) == sword
		var name := "검술" if i == 1 else "마법"
		var r := Rect2(x, 8, 40, 17)
		draw_rect(r, Color(LAV, 0.95) if on else Color(INK, 0.6))
		draw_rect(r, Color(PALE, 0.9 if on else 0.35), false, 1.0)
		var sz := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
		draw_string(font, Vector2(r.position.x + (r.size.x - sz.x) * 0.5, 21), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
			INK if on else Color(PALE, 0.5))
		x += 44.0
	# 스킬
	var key := "" if EKeys.touch_mode else "A "
	var ratio := eska.skill_ratio()
	_text(font, Vector2(8, 40), key + eska.skill_name(), 11, Color(PALE, 0.45 if ratio > 0.0 else 0.95))
	draw_rect(Rect2(8, 44, 84, 3), Color(INK, 0.7))
	draw_rect(Rect2(8, 44, 84 * (1.0 - ratio), 3), Color(LAV, 0.95))
	# 연타 수
	if eska.hit_count >= 2:
		var s := "%d 연타" % eska.hit_count
		var sz := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
		_text(font, Vector2(size.x - sz.x - 10.0, 56 if EKeys.touch_mode else 26), s, 16, Color(PALE, clampf(eska.combo_left / 0.4, 0.0, 1.0)))
	# 안내 한 줄
	var hint := _hint(sword)
	if hint != "":
		var sz := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
		_text(font, Vector2((size.x - sz.x) * 0.5, 22), hint, 11, Color(PALE, 0.9))
	if not EKeys.touch_mode:
		var sz := font.get_string_size(HELP_KEYS, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
		_text(font, Vector2((size.x - sz.x) * 0.5, size.y - 8.0), HELP_KEYS, 11, Color(PALE, 0.55))


func _hint(sword: bool) -> String:
	var mode_key := "모드" if EKeys.touch_mode else "S"
	var atk := "공격" if EKeys.touch_mode else "X"
	if is_instance_valid(stage) and stage.any_scar():
		return "틈 자국 — %s로 마법 모드, %s로 터뜨리기" % [mode_key, atk] if sword else "%s 균열 점화로 틈 자국을 터뜨린다" % atk
	if _t < INTRO:
		return "%s: 빗자루 ↔ 검 (바꾸는 순간 전환 공격)" % mode_key
	return ""
