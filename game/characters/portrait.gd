class_name Portrait
extends Control
## 대화창 초상화 (72×72, 코드 그래픽). Characters.DB 값으로 상반신을 그리고 표정 5종을 바꾼다.
## expr: normal · happy · angry · sad · surprised (+ 너울 전용 smug, scary)

var who := "sera"
var expr := "normal"
var talking := false
var _t := 0.0
var _blink := 0.0


func set_speaker(p_who: String, p_expr: String) -> void:
	who = p_who
	expr = p_expr
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	_blink -= delta
	if _blink < -3.0:
		_blink = 0.12
	queue_redraw()


func _draw() -> void:
	var info := Characters.info(who)
	var accent: Color = info.get("color", Color.WHITE)
	# 배경: 인물 색이 은은하게 깔린 사각
	draw_rect(Rect2(0, 0, 72, 72), Color(0.05, 0.04, 0.09))
	for i in 6:
		draw_rect(Rect2(0, 72 - i * 12, 72, 12), Color(accent, 0.03 + i * 0.012))
	match who:
		"neoul":
			_draw_fox()
		"neoul_god":
			_draw_goddess()
		"hodu":
			_draw_owl()
		"narration":
			pass
		_:
			_draw_person(info)
	draw_rect(Rect2(0, 0, 72, 72), Color(accent, 0.8), false, 1.0)


func _bob() -> float:
	return sin(_t * 2.0) * 0.6 + (sin(_t * 18.0) * 0.5 if talking else 0.0)


func _draw_person(info: Dictionary) -> void:
	var robe: Color = info.robe
	var robe2: Color = info.robe2
	var skin: Color = info.skin
	var hair: Color = info.hair
	var eye: Color = info.eye
	var extra: Array = info.get("extra", [])
	var style := String(info.get("hair_style", "short"))
	var b := _bob()
	var fc := Vector2(36, 40 + b) # 얼굴 중심
	# 어깨·옷
	draw_colored_polygon(PackedVector2Array([Vector2(8, 72), Vector2(16, 58 + b), Vector2(56, 58 + b), Vector2(64, 72)]), robe)
	draw_colored_polygon(PackedVector2Array([Vector2(30, 58 + b), Vector2(36, 66 + b), Vector2(42, 58 + b)]), robe2)
	if "apron" in extra:
		draw_rect(Rect2(26, 62 + b, 20, 10), Color("#f0e8dc"))
	draw_rect(Rect2(32, 52 + b, 8, 7), skin.darkened(0.1))
	# 뒷머리
	match style:
		"long":
			draw_colored_polygon(PackedVector2Array([fc + Vector2(-16, -10), fc + Vector2(16, -10), fc + Vector2(18, 24), fc + Vector2(-18, 26)]), hair)
		"twin":
			draw_circle(fc + Vector2(-18, 4), 7, hair)
			draw_circle(fc + Vector2(18, 4), 7, hair)
			draw_rect(Rect2(fc.x - 24, fc.y + 4, 7, 18), hair)
			draw_rect(Rect2(fc.x + 17, fc.y + 4, 7, 18), hair)
		"tied":
			draw_colored_polygon(PackedVector2Array([fc + Vector2(12, -8), fc + Vector2(24, 8), fc + Vector2(20, 26), fc + Vector2(12, 6)]), hair)
		"bun":
			draw_circle(fc + Vector2(0, -20), 9, hair)
		"bob":
			draw_colored_polygon(PackedVector2Array([fc + Vector2(-17, -8), fc + Vector2(17, -8), fc + Vector2(17, 12), fc + Vector2(-17, 12)]), hair)
	# 얼굴 (둥근 다각형)
	var face := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		var rx := 13.0
		var ry := 14.0 if sin(a) < 0 else 15.5
		face.append(fc + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(face, skin)
	# 볼
	if expr in ["happy", "surprised"] or "apron" in extra:
		draw_rect(Rect2(fc.x - 11, fc.y + 5, 4, 2), Color(1.0, 0.5, 0.5, 0.35))
		draw_rect(Rect2(fc.x + 7, fc.y + 5, 4, 2), Color(1.0, 0.5, 0.5, 0.35))
	_eyes(fc, eye)
	_mouth(fc)
	# 앞머리
	var bangs := PackedVector2Array([
		fc + Vector2(-15, 2), fc + Vector2(-14, -10), fc + Vector2(-6, -16), fc + Vector2(6, -16), fc + Vector2(14, -10),
		fc + Vector2(15, 2), fc + Vector2(10, -6), fc + Vector2(4, -3), fc + Vector2(-2, -7), fc + Vector2(-8, -3),
	])
	draw_colored_polygon(bangs, hair)
	draw_line(fc + Vector2(-10, -13), fc + Vector2(2, -15), hair.lightened(0.3), 1.0)
	if who == "sera":
		# 붉은 머리끝
		draw_rect(Rect2(fc.x - 18, fc.y + 20, 6, 4), Color("#b4282d"))
		draw_rect(Rect2(fc.x + 12, fc.y + 20, 6, 4), Color("#b4282d"))
	if "glasses" in extra:
		draw_arc(fc + Vector2(-6, 2), 5, 0, TAU, 12, Color("#d8d8e8"), 1.0)
		draw_arc(fc + Vector2(6, 2), 5, 0, TAU, 12, Color("#d8d8e8"), 1.0)
		draw_line(fc + Vector2(-1, 2), fc + Vector2(1, 2), Color("#d8d8e8"), 1.0)
	if "goggles" in extra:
		draw_rect(Rect2(fc.x - 16, fc.y - 13, 32, 5), Color("#6a4a2a"))
		draw_circle(fc + Vector2(-6, -11), 5, Color("#8ad0d8"))
		draw_circle(fc + Vector2(6, -11), 5, Color("#8ad0d8"))
		draw_circle(fc + Vector2(-7, -12), 1.5, Color.WHITE)
	if "ribbon" in extra:
		draw_colored_polygon(PackedVector2Array([fc + Vector2(14, -10), fc + Vector2(24, -16), fc + Vector2(24, -4)]), Color("#4a6ad8"))
		draw_colored_polygon(PackedVector2Array([fc + Vector2(14, -10), fc + Vector2(6, -18), fc + Vector2(8, -6)]), Color("#4a6ad8"))
	# 모자
	var hc: Color = info.hat_col
	match String(info.get("hat", "none")):
		"witch", "witch_small":
			var big := String(info.hat) == "witch"
			var by := fc.y - 13
			draw_colored_polygon(PackedVector2Array([Vector2(fc.x - 26, by + 2), Vector2(fc.x + 26, by + 2), Vector2(fc.x + 20, by - 3), Vector2(fc.x - 20, by - 3)]), hc)
			var tip := Vector2(fc.x - (14 if big else 6) + sin(_t * 1.5) * 1.5, by - (34 if big else 22))
			draw_colored_polygon(PackedVector2Array([Vector2(fc.x - 14, by - 2), Vector2(fc.x + 14, by - 2), Vector2(fc.x + 4, by - 18), tip]), hc)
			draw_line(Vector2(fc.x - 14, by - 5), Vector2(fc.x + 14, by - 5), robe2, 2.0)
		"nurse":
			draw_rect(Rect2(fc.x - 14, fc.y - 22, 28, 9), hc)
			draw_rect(Rect2(fc.x - 2, fc.y - 21, 4, 7), Color("#d84a5a"))
			draw_rect(Rect2(fc.x - 4, fc.y - 19, 8, 3), Color("#d84a5a"))
	if "feather" in extra:
		draw_line(fc + Vector2(-20, -30), fc + Vector2(-10, -46), Color("#e8e0ff"), 3.0)
	if "stars" in extra:
		for i in 4:
			var a2 := _t * 0.6 + TAU * i / 4.0
			draw_rect(Rect2(fc + Vector2(cos(a2) * 28, -24 + sin(a2) * 6), Vector2(2, 2)), Color(0.9, 0.9, 1.0, 0.8))
	if "owl" in extra:
		var oc := Vector2(60, 56 + _bob())
		draw_circle(oc, 7, Color("#8a6a48"))
		draw_circle(oc + Vector2(0, -6), 6, Color("#9a7a58"))
		draw_circle(oc + Vector2(-2, -7), 1.5, Color("#f0d060"))
		draw_circle(oc + Vector2(2, -7), 1.5, Color("#f0d060"))


func _eyes(fc: Vector2, eye: Color) -> void:
	var l := fc + Vector2(-6, 2)
	var r := fc + Vector2(6, 2)
	var brow := Color(0.15, 0.1, 0.12)
	if _blink > 0.0 and expr != "surprised":
		draw_line(l + Vector2(-3, 0), l + Vector2(3, 0), brow, 1.0)
		draw_line(r + Vector2(-3, 0), r + Vector2(3, 0), brow, 1.0)
		return
	match expr:
		"happy":
			draw_arc(l + Vector2(0, 2), 3, PI, TAU, 6, brow, 1.5)
			draw_arc(r + Vector2(0, 2), 3, PI, TAU, 6, brow, 1.5)
		"angry":
			for p in [l, r]:
				draw_rect(Rect2(p.x - 2, p.y - 1, 4, 4), eye)
				draw_rect(Rect2(p.x - 1, p.y - 1, 1, 1), Color.WHITE)
			draw_line(l + Vector2(-4, -5), l + Vector2(3, -3), brow, 1.5)
			draw_line(r + Vector2(4, -5), r + Vector2(-3, -3), brow, 1.5)
		"sad":
			for p in [l, r]:
				draw_rect(Rect2(p.x - 2, p.y, 4, 3), eye)
			draw_line(l + Vector2(-4, -3), l + Vector2(3, -5), brow, 1.0)
			draw_line(r + Vector2(4, -3), r + Vector2(-3, -5), brow, 1.0)
		"surprised":
			for p in [l, r]:
				draw_circle(p, 3.5, Color.WHITE)
				draw_circle(p, 2.0, eye)
			draw_line(l + Vector2(-3, -6), l + Vector2(3, -7), brow, 1.0)
			draw_line(r + Vector2(-3, -7), r + Vector2(3, -6), brow, 1.0)
		_:
			for p in [l, r]:
				draw_rect(Rect2(p.x - 2, p.y - 2, 4, 5), eye)
				draw_rect(Rect2(p.x - 1, p.y - 2, 1, 2), Color(1, 1, 1, 0.9))
			draw_line(l + Vector2(-3, -5), l + Vector2(3, -5), brow, 1.0)
			draw_line(r + Vector2(-3, -5), r + Vector2(3, -5), brow, 1.0)


func _mouth(fc: Vector2) -> void:
	var m := fc + Vector2(0, 10)
	var col := Color("#8a3a3a")
	var open := talking and int(_t * 12.0) % 2 == 0
	match expr:
		"happy":
			draw_arc(m + Vector2(0, -2), 3, 0.2, PI - 0.2, 6, col, 1.5)
		"angry":
			draw_line(m + Vector2(-3, 1), m + Vector2(3, 0), col, 1.5)
		"sad":
			draw_arc(m + Vector2(0, 2), 3, PI + 0.3, TAU - 0.3, 6, col, 1.0)
		"surprised":
			draw_circle(m, 2.5, col)
		_:
			if open:
				draw_rect(Rect2(m.x - 2, m.y - 1, 4, 3), col)
			else:
				draw_line(m + Vector2(-2, 0), m + Vector2(2, 0), col, 1.0)


func _draw_fox() -> void:
	# 작은 여우 너울: 흰 털, 귀 끝·볼털의 푸른 여우불
	var b := _bob()
	var c := Vector2(36, 44 + b)
	var fur := Color("#f4f0ea")
	var blue := Color(0.55, 0.82, 1.0)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-20, 28), c + Vector2(-14, 10), c + Vector2(14, 10), c + Vector2(20, 28)]), fur.darkened(0.08))
	# 귀
	var ear_tw := sin(_t * 3.0) * 1.5 if expr != "angry" else 0.0
	draw_colored_polygon(PackedVector2Array([c + Vector2(-16, -8), c + Vector2(-20 + ear_tw, -30), c + Vector2(-4, -14)]), fur)
	draw_colored_polygon(PackedVector2Array([c + Vector2(16, -8), c + Vector2(20 - ear_tw, -30), c + Vector2(4, -14)]), fur)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-16, -12), c + Vector2(-19 + ear_tw, -27), c + Vector2(-9, -15)]), blue)
	draw_colored_polygon(PackedVector2Array([c + Vector2(16, -12), c + Vector2(19 - ear_tw, -27), c + Vector2(9, -15)]), blue)
	# 얼굴
	var face := PackedVector2Array([c + Vector2(-18, -6), c + Vector2(-10, -16), c + Vector2(10, -16), c + Vector2(18, -6), c + Vector2(14, 6), c + Vector2(0, 14), c + Vector2(-14, 6)])
	draw_colored_polygon(face, fur)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-18, -2), c + Vector2(-24, 4), c + Vector2(-14, 6)]), blue.lerp(fur, 0.4))
	draw_colored_polygon(PackedVector2Array([c + Vector2(18, -2), c + Vector2(24, 4), c + Vector2(14, 6)]), blue.lerp(fur, 0.4))
	draw_circle(c + Vector2(0, 10), 2.0, Color("#2a1a2a"))
	var ec := Color("#3a7ad8")
	match expr:
		"happy", "smug":
			draw_arc(c + Vector2(-7, -2), 3, PI, TAU, 6, Color("#2a1a2a"), 1.5)
			draw_arc(c + Vector2(7, -2), 3, PI, TAU, 6, Color("#2a1a2a"), 1.5)
		"angry", "scary":
			draw_line(c + Vector2(-11, -6), c + Vector2(-3, -2), ec, 2.0)
			draw_line(c + Vector2(11, -6), c + Vector2(3, -2), ec, 2.0)
			if expr == "scary":
				draw_circle(c + Vector2(-7, -2), 1.5, Color(0.6, 0.9, 1.0))
				draw_circle(c + Vector2(7, -2), 1.5, Color(0.6, 0.9, 1.0))
		"sad":
			draw_rect(Rect2(c.x - 9, c.y - 2, 4, 2), ec)
			draw_rect(Rect2(c.x + 5, c.y - 2, 4, 2), ec)
		"surprised":
			draw_circle(c + Vector2(-7, -3), 3, ec)
			draw_circle(c + Vector2(7, -3), 3, ec)
		_:
			draw_rect(Rect2(c.x - 9, c.y - 4, 4, 4), ec)
			draw_rect(Rect2(c.x + 5, c.y - 4, 4, 4), ec)
			draw_rect(Rect2(c.x - 8, c.y - 4, 1, 1), Color.WHITE)
			draw_rect(Rect2(c.x + 6, c.y - 4, 1, 1), Color.WHITE)
	# 이마의 여우불 문양
	draw_circle(c + Vector2(0, -12), 2.0, Color(blue, 0.6 + 0.4 * sin(_t * 3.0)))


func _draw_goddess() -> void:
	# 본모습 너울: 너울(얼굴을 가리는 천)을 쓴 여신, 뒤로 아홉 꼬리의 그림자
	var b := _bob()
	var c := Vector2(36, 40 + b)
	for i in 9:
		var a := -PI * 0.5 + (i - 4) * 0.32
		var tip := c + Vector2(cos(a), sin(a)) * 44
		draw_line(c + Vector2(0, 10), tip, Color(0.4, 0.65, 1.0, 0.18), 7.0)
	draw_colored_polygon(PackedVector2Array([Vector2(6, 72), Vector2(18, 54 + b), Vector2(54, 54 + b), Vector2(66, 72)]), Color("#e8e4f0"))
	draw_colored_polygon(PackedVector2Array([Vector2(28, 54 + b), Vector2(36, 72), Vector2(44, 54 + b)]), Color("#b83a3a"))
	# 귀
	draw_colored_polygon(PackedVector2Array([c + Vector2(-14, -14), c + Vector2(-20, -34), c + Vector2(-6, -18)]), Color("#f4f0ea"))
	draw_colored_polygon(PackedVector2Array([c + Vector2(14, -14), c + Vector2(20, -34), c + Vector2(6, -18)]), Color("#f4f0ea"))
	# 너울(반투명 천)
	var veil := PackedVector2Array([c + Vector2(-16, -16), c + Vector2(16, -16), c + Vector2(20, 22), c + Vector2(-20, 22)])
	draw_colored_polygon(veil, Color(0.85, 0.85, 0.95, 0.85))
	for i in 5:
		draw_line(c + Vector2(-16 + i * 8, -16), c + Vector2(-20 + i * 10, 22), Color(0.7, 0.7, 0.85, 0.6), 1.0)
	var glow := 0.7 + 0.3 * sin(_t * 2.0)
	var col := Color(0.5, 0.85, 1.0, glow) if expr != "scary" else Color(0.7, 0.95, 1.0)
	draw_rect(Rect2(c.x - 8, c.y - 2, 4, 2), col)
	draw_rect(Rect2(c.x + 4, c.y - 2, 4, 2), col)
	draw_rect(Rect2(c.x - 18, c.y - 20, 36, 4), Color("#c8a040"))


func _draw_owl() -> void:
	var b := _bob()
	var c := Vector2(36, 42 + b)
	draw_circle(c + Vector2(0, 12), 20, Color("#8a6a48"))
	draw_circle(c, 18, Color("#9a7a58"))
	draw_colored_polygon(PackedVector2Array([c + Vector2(-14, -12), c + Vector2(-12, -22), c + Vector2(-6, -14)]), Color("#8a6a48"))
	draw_colored_polygon(PackedVector2Array([c + Vector2(14, -12), c + Vector2(12, -22), c + Vector2(6, -14)]), Color("#8a6a48"))
	for x in [-7.0, 7.0]:
		draw_circle(c + Vector2(x, -2), 6, Color("#f0e0b0"))
		draw_circle(c + Vector2(x, -2), 3, Color("#2a1a10"))
	draw_colored_polygon(PackedVector2Array([c + Vector2(-3, 4), c + Vector2(3, 4), c + Vector2(0, 9)]), Color("#d8a040"))
