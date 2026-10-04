class_name BubbleDraw
extends RefCounted
## 머리 위 감정 기호·말풍선 공용 그리기 (세라·인물 EmoteBubble, Npc, 동료 Ally, 너울 NeoulPet).
## 모양은 쓰는 곳마다 조금씩 다르다 — 지금 보이는 모습을 그대로 두려고 차이를 인자로 받는다.

## 감정 이름 → 기호 (emote("…")의 kind). 표에 없으면 글자를 그대로 보여 준다.
const GLYPHS := {"!": "!", "?": "?", "...": "…", "heart": "♥", "note": "♪", "anger": "#"}
## "sweat"(땀)은 출처마다 다르게 보인다(현재 모습 보존): 세라·인물 말풍선 "~", Npc "💧",
## 너울은 표에 없어 "sweat" 글자 그대로. 통일하려면 이 표만 고치면 된다.
const SWEAT := {"bubble": "~", "npc": "💧"}
const BUBBLE_FILL := Color("#f4eee4")
const GLYPH_COLOR := Color("#2a1a2a")


## 감정 기호 (source: "bubble" 세라·인물 EmoteBubble, "npc" Npc, "pet" 너울)
static func glyph(kind: String, source := "bubble") -> String:
	if kind == "sweat":
		return String(SWEAT.get(source, kind))
	return String(GLYPHS.get(kind, kind))


## 둥근 감정 말풍선: at 중심, pop 0~1(커지는 정도), 다 커지면(0.9 넘으면) 기호.
## centered = 기호를 가운데 정렬(EmoteBubble), 아니면 왼쪽 -4px에서 시작(Npc)
static func draw_emote(ci: CanvasItem, font: Font, at: Vector2, pop: float, txt: String, centered: bool) -> void:
	ci.draw_circle(at, 7.0 * pop, BUBBLE_FILL)
	ci.draw_colored_polygon(PackedVector2Array([at + Vector2(-2, 5), at + Vector2(2, 5), at + Vector2(0, 9)]), BUBBLE_FILL)
	if pop > 0.9:
		var x := -font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x * 0.5 if centered else -4.0
		ci.draw_string(font, at + Vector2(x, 4), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, GLYPH_COLOR)


## 네모 말풍선(혼잣말): 가운데 정렬, 위쪽 y, 높이 16. border·top_line은 알파 0이면 안 그림,
## tail_y가 NAN이 아니면 그 y에서 아래로 작은 꼬리.
static func draw_speech(ci: CanvasItem, font: Font, text: String, top_y: float, fill: Color, text_col: Color,
		border := Color(0, 0, 0, 0), top_line := Color(0, 0, 0, 0), tail_y := NAN) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 10.0
	var top := Vector2(-w * 0.5, top_y)
	ci.draw_rect(Rect2(top, Vector2(w, 16)), fill)
	if border.a > 0.0:
		ci.draw_rect(Rect2(top, Vector2(w, 16)), border, false, 1.0)
	if top_line.a > 0.0:
		ci.draw_rect(Rect2(top, Vector2(w, 1)), top_line)
	if not is_nan(tail_y):
		ci.draw_colored_polygon(PackedVector2Array([Vector2(-3, tail_y), Vector2(3, tail_y), Vector2(0, tail_y + 4)]), fill)
	ci.draw_string(font, top + Vector2(5, 12), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, text_col)
