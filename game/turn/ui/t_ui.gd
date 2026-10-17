class_name TUi
extends RefCounted
## 턴제 화면 공용: 색·자리·글자 그리기. 화면은 640×360(폰 가로), 터치가 1급 시민 — 누르는 것은 모두 36px 이상.

const W := 640.0
const H := 360.0
const GROUND_Y := 254.0
const ACTOR_SCALE := 1.6 ## 코드 그림(키 약 40px)을 이만큼 키워 그린다

## 아군 자리 (발밑) — 왼쪽, 앞에서 뒤로 비스듬히
const ALLY_POS := [Vector2(200, 262), Vector2(132, 244), Vector2(92, 274)]
## 적 자리 — 수에 따라
const ENEMY_POS := {
	1: [Vector2(500, 262)],
	2: [Vector2(458, 268), Vector2(548, 246)],
	3: [Vector2(440, 270), Vector2(515, 244), Vector2(590, 266)],
}

# 색
const INK := Color("#14081f")
const PANEL := Color(0.05, 0.03, 0.09, 0.82)
const PANEL_LINE := Color("#3d3450")
const VIOLET := Color("#a98bff")
const PALE := Color("#d9ccff")
const MAGENTA := Color("#e352ff")
const EDGE := Color("#ffe4fb")
const FIRE_HOT := Color("#ffd27a")
const FIRE_MID := Color("#ffb347")
const FIRE_OUT := Color("#ff5a2a")
const FIRE_DARK := Color("#b3241d")
const EMBER := Color("#f0c050")
const BONE := Color("#ece4d6")
const RED := Color("#ff2f58")
const GREEN := Color("#8fe04a")
const DIM := Color("#8a7fa3")
const TEXT := Color("#efe6ff")
const GOLD := Color("#f0c050")
const ATTACK_C := Color("#ff6a4a")
const SUPPORT_C := Color("#f0c050")
const ULT_C := Color("#c77dff")
const HP_C := Color("#ff5a4a")
const HP_BG := Color("#2a1a2a")
const SHIELD_C := Color("#ffb347")
const CAST_C := Color("#ffe4fb")
const ENEMY_C := Color("#ff6a6a")

const KIND_COLORS := {"attack": ATTACK_C, "support": SUPPORT_C, "ult": ULT_C}
const BUFF_COLORS := {"atk": Color("#ff8a5a"), "elem": Color("#ffb347"), "crit_rate": Color("#ffe9a8"), "crit_dmg": Color("#fff2c0"), "final": Color("#c77dff"),
	"vuln": Color("#ff5a8a"), "def": Color("#9fb0c0"), "haste": Color("#8fe0c0"), "shield": Color("#ffb347"), "burn": Color("#ff5a2a"),
	"crack": Color("#d9a8ff"), "oil": Color("#e0b060"), "sure": Color("#fff6d0")}
const BUFF_SHORT := {"atk": "공", "elem": "속", "crit_rate": "치", "crit_dmg": "치피", "final": "최", "vuln": "취", "def": "방", "haste": "마력", "shield": "벽", "burn": "화",
	"crack": "금", "oil": "기름", "sure": "별"}


static func font() -> Font:
	return ThemeDB.fallback_font


static func text(ci: CanvasItem, p: Vector2, s: String, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0, outline := 3) -> void:
	var f := font()
	if outline > 0:
		ci.draw_string_outline(f, p, s, align, width, size, outline, Color(0, 0, 0, 0.75 * col.a))
	ci.draw_string(f, p, s, align, width, size, col)


static func text_w(s: String, size: int) -> float:
	return font().get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## 글자가 폭을 넘으면 뒤를 잘라 "…"을 붙인다
static func fit(s: String, size: int, width: float) -> String:
	if text_w(s, size) <= width:
		return s
	var n := s.length()
	while n > 1 and text_w(s.substr(0, n) + "…", size) > width:
		n -= 1
	return s.substr(0, n) + "…"


## 글자를 상자 가운데에
static func text_center(ci: CanvasItem, rect: Rect2, s: String, size: int, col: Color, outline := 3) -> void:
	var f := font()
	var h := f.get_height(size)
	var y := rect.position.y + (rect.size.y + h) * 0.5 - f.get_descent(size)
	text(ci, Vector2(rect.position.x, y), s, size, col, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, outline)


static func panel(ci: CanvasItem, rect: Rect2, fill := PANEL, line := PANEL_LINE, line_w := 1.0) -> void:
	ci.draw_rect(rect, fill)
	if line.a > 0.0:
		ci.draw_rect(rect, line, false, line_w)


## 버튼: 바탕·테두리·글자. 눌린(hot) 것은 밝게, 막힌(off) 것은 어둡게
static func button(ci: CanvasItem, rect: Rect2, label: String, col: Color, size := 12, hot := false, off := false) -> void:
	var fill := Color(col, 0.16 if not hot else 0.34)
	if off:
		fill = Color(0.1, 0.08, 0.14, 0.6)
	ci.draw_rect(rect, fill)
	ci.draw_rect(rect, Color(col, 0.35 if off else (1.0 if hot else 0.7)), false, 1.0)
	text_center(ci, rect, label, size, Color(col, 0.45) if off else (Color.WHITE if hot else col.lightened(0.25)))


static func bar(ci: CanvasItem, rect: Rect2, ratio: float, col: Color, bg := HP_BG, line := Color(0, 0, 0, 0.6)) -> void:
	ci.draw_rect(rect, bg)
	var w := rect.size.x * clampf(ratio, 0.0, 1.0)
	if w > 0.0:
		ci.draw_rect(Rect2(rect.position, Vector2(w, rect.size.y)), col)
	ci.draw_rect(rect, line, false, 1.0)


static func kind_color(kind: String) -> Color:
	return KIND_COLORS.get(kind, TEXT)


static func elem_color(elem: String) -> Color:
	if elem == TData.ELEM_SPACE:
		return VIOLET
	if elem == TData.ELEM_FIRE:
		return FIRE_MID
	return BONE


static func fmt(n: int) -> String:
	var s := str(n)
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return out


static func pct(x: float) -> String:
	return "%d%%" % int(round(x * 100.0))
