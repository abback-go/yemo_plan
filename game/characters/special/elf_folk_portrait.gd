extends RefCounted
## 3장 엘프 인물 공용 초상화 (72×72). 1장 Portrait의 사람 그림(_draw_person — 같은 값으로 얼굴·머리·표정)을 그대로 쓰고,
## 그 뒤에 긴 귀를, 위에 엘프 장식(잎 모자·두건·고글 등)을 더한다.

const LEAF := Color("#3a6a2a")
const LEAF_L := Color("#7ab450")


static func draw_portrait(p: Portrait, info: Dictionary, expr: String, t: float, talking: bool, _blinking: bool) -> void:
	var extra: Array = info.get("extra", [])
	var skin: Color = info.get("skin", Color("#f2dcc8"))
	var b := sin(t * 2.0) * 0.6 + (sin(t * 18.0) * 0.5 if talking else 0.0)
	var fc := Vector2(36, 40 + b)
	var droop := 4.0 if expr in ["sad"] else (-3.0 if expr == "surprised" else 0.0)
	# 긴 귀 (얼굴 뒤)
	for side in [-1.0, 1.0]:
		var base := fc + Vector2(side * 11.0, 0)
		var tip := fc + Vector2(side * 26.0, -12.0 + droop + sin(t * 0.8 + side) * 0.5)
		p.draw_colored_polygon(PackedVector2Array([base + Vector2(0, -4), tip, base + Vector2(0, 5)]), skin)
		p.draw_line(base + Vector2(side * 1.5, 1), tip + Vector2(-side * 3.0, 2.5), skin.darkened(0.15), 1.0)
	# 사람 그림 (얼굴·머리·옷·표정)
	p._draw_person(info)
	if "freckles" in extra:
		for f in [Vector2(-8, 5), Vector2(-6, 7), Vector2(6, 5), Vector2(8, 7), Vector2(-1, 6)]:
			var fp: Vector2 = fc + f
			p.draw_rect(Rect2(fp, Vector2.ONE), skin.darkened(0.25))
	# 잎 모양 옷깃
	var robe2: Color = info.get("robe2", Color("#c8b060"))
	p.draw_colored_polygon(PackedVector2Array([Vector2(24, 58 + b), Vector2(36, 66 + b), Vector2(48, 58 + b), Vector2(36, 61 + b)]), robe2)
	if "leafcap" in extra:
		var sw := sin(t * 1.4) * 1.5
		p.draw_colored_polygon(PackedVector2Array([fc + Vector2(-22, -10), fc + Vector2(-8, -26), fc + Vector2(10, -27 + sw), fc + Vector2(24, -12 + sw), fc + Vector2(4, -14)]), LEAF)
		p.draw_line(fc + Vector2(-20, -11), fc + Vector2(22, -13 + sw), LEAF_L, 1.0)
		for i in 4:
			p.draw_line(fc + Vector2(-12 + i * 9, -12), fc + Vector2(-9 + i * 8, -22 + sw * 0.5), Color("#2e5a22"), 1.0)
		p.draw_line(fc + Vector2(-6, -24), fc + Vector2(-8, -31), Color("#5a3a20"), 2.0)
	if "warden" in extra:
		# 두건 + 가리개
		p.draw_colored_polygon(PackedVector2Array([fc + Vector2(-17, 6), fc + Vector2(-16, -12), fc + Vector2(0, -21), fc + Vector2(16, -12), fc + Vector2(17, 6), fc + Vector2(12, -6), fc + Vector2(-12, -6)]), Color("#2e4a24"))
		p.draw_colored_polygon(PackedVector2Array([fc + Vector2(-12, 5), fc + Vector2(12, 5), fc + Vector2(10, 15), fc + Vector2(-10, 15)]), Color("#5a6a4a"))
		p.draw_line(fc + Vector2(-12, 5), fc + Vector2(12, 5), Color("#7a8a6a"), 1.0)
	if "flower" in extra:
		var c := fc + Vector2(-14, -12)
		for i in 5:
			var a := TAU * i / 5.0
			p.draw_circle(c + Vector2(cos(a), sin(a)) * 3.0, 2.2, Color("#f0e0f8"))
		p.draw_circle(c, 1.6, Color("#ffe08a"))
