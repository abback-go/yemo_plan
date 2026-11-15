class_name DrawKit
extends RefCounted
## 인물 전용 그림(characters/special/*_draw.gd) 공용 도형 도우미. 모두 static, v는 그릴 대상(CanvasItem).
## 윤곽 색은 인물 파일마다 달라서 인자로 받는다 — 각 파일의 _seg·_poly는 자기 윤곽 색을 넣어 부르는 한 줄짜리다.
## 팔다리 IK(_ik)는 파일마다 알고리즘이 달라(코사인 법칙 vs acos 각도) 그림이 달라지므로 여기로 합치지 않는다.
## 2장 공용 KArt(world/entities/ch2/k_art.gd: 안전한 poly·glow·별 등)와는 별개 — 겹치는 함수는 없다.


## 윤곽선 있는 굵은 선분 (윤곽 = 양쪽 1px 더 굵게 먼저)
static func seg(v: CanvasItem, a: Vector2, b: Vector2, w: float, col: Color, out: Color) -> void:
	v.draw_line(a, b, out, w + 2.0)
	v.draw_line(a, b, col, w)


## 윤곽 있는 다각형: 상하좌우 1px 밀린 윤곽 4장 + 채움 (outline = false면 채움만)
static func outlined_poly(v: CanvasItem, pts: PackedVector2Array, col: Color, out: Color, outline := true) -> void:
	if outline:
		for o: Vector2 in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
			var q := PackedVector2Array()
			for p in pts:
				q.append(p + o)
			v.draw_colored_polygon(q, out)
	v.draw_colored_polygon(pts, col)


## 다각형을 무게중심에서 바깥으로 by만큼 부풀림 (윤곽용 큰 다각형)
static func grow_poly(pts: PackedVector2Array, by: float) -> PackedVector2Array:
	var c := Vector2.ZERO
	for p in pts:
		c += p
	c /= maxf(pts.size(), 1)
	var out := PackedVector2Array()
	for p2 in pts:
		var d := p2 - c
		out.append(p2 + d.normalized() * by if d.length() > 0.01 else p2)
	return out


## 타원 꼭짓점 n개 (기본 12각)
static func ellipse(c: Vector2, rx: float, ry: float, n := 12) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
