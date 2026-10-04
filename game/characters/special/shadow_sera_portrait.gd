extends RefCounted
## "불 속의 나" 초상화: 세라의 초상화를 검게 태우고, 붉은 눈빛과 검은 불꽃을 두른다.


static func draw_portrait(p: Portrait, _info: Dictionary, _expr: String, t: float, _talking: bool, _blinking: bool) -> void:
	p.draw_person(Characters.info("sera"))
	p.draw_rect(Rect2(0, 0, 72, 72), Color(0.06, 0.02, 0.1, 0.72))
	# 눈 자리에서 새어 나오는 붉은 빛 (좌우로 길게)
	var glow := 0.6 + 0.4 * sin(t * 3.0)
	for s in [-1.0, 1.0]:
		var e := Vector2(36 + s * 7, 34)
		p.draw_rect(Rect2(e - Vector2(2, 1), Vector2(4, 2)), Color(1.0, 0.25, 0.3, glow))
		p.draw_line(e + Vector2(s * 2, 0), e + Vector2(s * 7, -1), Color(1.0, 0.2, 0.25, 0.35 * glow), 1.0)
	# 검은 불꽃 테두리
	for i in 9:
		var x := 4.0 + i * 8.0
		var h := 8.0 + 6.0 * absf(sin(t * 4.0 + i * 1.3))
		p.draw_colored_polygon(PackedVector2Array([Vector2(x - 4, 72), Vector2(x, 72 - h), Vector2(x + 4, 72)]), Color(0.3, 0.1, 0.45, 0.8))
