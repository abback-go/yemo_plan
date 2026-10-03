extends RefCounted
## 녹시스 (별 신도 대사제) 전용 몸 그림. 키 39px.
## 별자리 수가 놓인 깊은 남보라 로브와 두건, 두건 밖으로 흘러내린 은빛 머리, 하얀 별 가면(눈구멍에서 보랏빛),
## 초승달 지팡이 끝의 별 수정, 몸 둘레를 천천히 도는 작은 별 셋. 광신도답게 움직임이 연극적이다.
## 자세: idle · walk · cast(두 팔을 들어 별을 부름) · attack(지팡이를 내지름) · hurt · kneel(웃으며 무릎) · special(별빛으로 흩어짐) · down

const KArt := preload("res://world/entities/ch2/k_art.gd")
const OUT := Color("#07060c")
const ROBE := Color("#2a2050")
const ROBE_L := Color("#45387a")
const ROBE_D := Color("#140e2a")
const TRIM := Color("#c8a8ff")
const HAIR := Color("#dcd4ec")
const MASK := Color("#f0ecf6")
const MASK_D := Color("#a8a0c0")
const STAR := Color("#c89aff")
const STAFF := Color("#3a2a3a")
const SKIN := Color("#e0ccd4")


static func draw_body(v: CharacterVisual) -> void:
	var t := v.time()
	var pose := v.pose
	var pt := v.pose_t
	var float_y := 0.0
	var arms := 0.0 # 0 내림 · 1 들어 올림
	var thrust := 0.0
	var tilt := 0.0
	var crouch := 0.0
	var fade := 1.0
	match pose:
		"cast":
			arms = clampf(pt / 0.25, 0.0, 1.0)
			float_y = -2.0 - sin(t * 3.0) * 1.0
		"attack":
			thrust = clampf(pt / 0.1, 0.0, 1.0)
		"hurt":
			tilt = -0.25
		"kneel":
			crouch = 9.0
			tilt = 0.15 + sin(t * 9.0) * 0.03 # 낄낄 웃으며 어깨가 들썩
		"special":
			fade = clampf(1.0 - pt / 0.6, 0.0, 1.0)
			float_y = -pt * 8.0
		"down":
			crouch = 0.0
	if v.walking:
		float_y = -absf(sin(v.walk_phase())) * 0.6
	var sway := sin(t * 1.6) * 1.2
	var base := Vector2(0, float_y)
	var hip := base + Vector2(0, -16 + crouch)
	var chest := hip + Vector2(sin(tilt) * 12.0, -12)
	var head := chest + Vector2(1.5 + sin(tilt) * 4.0, -6)
	if pose == "down":
		v.draw_set_transform(Vector2(18, -5), -PI * 0.5, Vector2.ONE)
	if fade < 1.0:
		_dissolve(v, chest, t, 1.0 - fade)
	var a := fade
	# 등 뒤 별빛
	KArt.glow(v, chest, 22.0, Color(STAR, 0.5 * a), 3)
	# 로브 (아래로 넓게 퍼지고 자락이 흔들림)
	var hem_y := base.y - 0.5
	var robe := PackedVector2Array([
		chest + Vector2(-4.5, 0), chest + Vector2(4.5, 0), hip + Vector2(6.5, 4),
		Vector2(9 + sway, hem_y), Vector2(3, hem_y - 1), Vector2(-3, hem_y), Vector2(-10 + sway * 1.4, hem_y), hip + Vector2(-7, 4),
	])
	if crouch > 0.0:
		robe = PackedVector2Array([chest + Vector2(-4.5, 0), chest + Vector2(4.5, 0), hip + Vector2(8, 3), Vector2(11, hem_y), Vector2(-12, hem_y), hip + Vector2(-8, 3)])
	KArt.poly(v, _grow(robe, 1.0), Color(OUT, a))
	KArt.poly(v, robe, Color(ROBE, a))
	KArt.poly(v, PackedVector2Array([robe[0], chest + Vector2(-1, 0), Vector2(-2, hem_y), robe[robe.size() - 2] if crouch <= 0.0 else robe[4]]), Color(ROBE_D, a))
	# 별자리 수 (점과 선)
	var cons := [Vector2(2, -8), Vector2(4, -4), Vector2(1, -2), Vector2(5, 1), Vector2(-3, -6)]
	for i in cons.size() - 1:
		var p0: Vector2 = hip + (cons[i] as Vector2)
		var p1: Vector2 = hip + (cons[i + 1] as Vector2)
		v.draw_line(p0, p1, Color(TRIM, 0.35 * a), 1.0)
	for i in cons.size():
		var tw := 0.5 + 0.5 * sin(t * 3.0 + i * 1.7)
		v.draw_rect(Rect2(hip + (cons[i] as Vector2) - Vector2(0.5, 0.5), Vector2(1, 1)), Color(1, 0.95, 1.0, (0.5 + 0.5 * tw) * a))
	# 자락 끝 금빛 테두리
	v.draw_line(Vector2(-10 + sway * 1.4, hem_y), Vector2(9 + sway, hem_y), Color(TRIM, 0.7 * a), 1.0)
	v.draw_line(chest + Vector2(1, 0), Vector2(2, hem_y - 1), Color(TRIM, 0.45 * a), 1.0)
	# 뒷팔
	var sh_b := chest + Vector2(-2.5, 1.5)
	var hand_b := sh_b + Vector2(-2, 9).lerp(Vector2(-6, -9), arms)
	_sleeve(v, sh_b, hand_b, a, true)
	# 두건 + 은빛 머리 + 별 가면
	var hood := PackedVector2Array([head + Vector2(-6.5, 5), head + Vector2(-7, -2), head + Vector2(-3, -7.5), head + Vector2(3, -7), head + Vector2(6, -2), head + Vector2(5.5, 4)])
	KArt.poly(v, _grow(hood, 1.0), Color(OUT, a))
	KArt.poly(v, hood, Color(ROBE_L, a))
	KArt.poly(v, PackedVector2Array([head + Vector2(-6.5, 5), head + Vector2(-7, -2), head + Vector2(-4, -6), head + Vector2(-3, 4)]), Color(ROBE, a))
	# 흘러내린 은빛 머리 (가면 양옆)
	KArt.poly(v, PackedVector2Array([head + Vector2(-1, -4), head + Vector2(1, -4), head + Vector2(0, 8 + sway * 0.3), head + Vector2(-2.5, 7)]), Color(HAIR, a))
	v.draw_line(head + Vector2(3.5, -2), head + Vector2(4 + sway * 0.2, 7), Color(HAIR, a), 1.0)
	# 가면: 흰 얼굴판 + 네 갈래 별 문양 + 보라 눈빛
	var face := head + Vector2(2.0, 0)
	v.draw_circle(face, 3.6, Color(OUT, a))
	v.draw_circle(face, 3.1, Color(MASK, a))
	KArt.star4(v, face + Vector2(0.5, -0.5), 4.0, Color(MASK_D, 0.8 * a))
	KArt.star4(v, face + Vector2(0.5, -0.5), 2.6, Color(MASK, a))
	var eg := 0.7 + 0.3 * sin(t * 4.0)
	if pose == "cast" or pose == "special":
		eg = 1.0
	v.draw_rect(Rect2(face + Vector2(0.8, -1.2), Vector2(1.6, 1.2)), Color(STAR.lightened(0.3), eg * a))
	v.draw_circle(face + Vector2(1.6, -0.6), 2.0, Color(STAR, 0.25 * eg * a))
	if v.talking and int(t * 10.0) % 2 == 0:
		v.draw_rect(Rect2(face + Vector2(0.6, 2.0), Vector2(1.6, 0.8)), Color("#5a2a4a", a))
	# 지팡이 + 앞팔
	var sh_f := chest + Vector2(2.5, 1.5)
	var hand_f := sh_f + Vector2(3, 8).lerp(Vector2(4, -10), arms).lerp(Vector2(10, 1), thrust)
	var sdir := Vector2(0.05, -1.0).normalized().lerp(Vector2(1, -0.15).normalized(), thrust)
	if arms > 0.0:
		sdir = sdir.lerp(Vector2(0.25, -1.0).normalized(), arms)
	var bottom := hand_f - sdir * 14.0
	var top := hand_f + sdir * 16.0
	v.draw_line(bottom, top, Color(OUT, a), 3.0)
	v.draw_line(bottom, top, Color(STAFF, a), 1.6)
	v.draw_line(bottom + Vector2(0.5, 0), top + Vector2(0.5, 0), Color(STAFF.lightened(0.3), 0.6 * a), 1.0)
	# 초승달 고리와 별 수정
	var moon := top + sdir * 3.0
	v.draw_arc(moon, 3.6, sdir.angle() + PI * 0.35, sdir.angle() + PI * 1.65, 10, Color(Color("#d8c070"), a), 1.4)
	var crystal_k := 0.6 + 0.4 * sin(t * 3.0) + arms * 0.6
	KArt.glow(v, moon, 8.0 + arms * 10.0, Color(STAR, 0.7 * a), 3)
	KArt.star5(v, moon, 2.8 + arms * 1.0, Color(STAR.lightened(0.3), clampf(crystal_k, 0.0, 1.0) * a), t * 0.6)
	v.draw_rect(Rect2(moon - Vector2(0.5, 0.5), Vector2(1, 1)), Color(1, 1, 1, a))
	_sleeve(v, sh_f, hand_f, a, false)
	# 몸을 도는 작은 별 셋
	for i in 3:
		var ang := t * 1.2 + TAU * i / 3.0
		var orb := chest + Vector2(cos(ang) * 11.0, sin(ang) * 4.0 - 2.0)
		var front := sin(ang) > 0.0
		var col := Color(STAR.lightened(0.2), (0.9 if front else 0.45) * a)
		KArt.star4(v, orb, 1.8 if front else 1.2, col)
	if pose == "down":
		v.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _sleeve(v: CharacterVisual, sh: Vector2, hand: Vector2, a: float, back: bool) -> void:
	var col := ROBE_D if back else ROBE_L
	v.draw_line(sh, hand, Color(OUT, a), 4.6)
	v.draw_line(sh, hand, Color(col, a), 3.0)
	var d := (hand - sh).normalized()
	# 넓은 소맷부리
	KArt.poly(v, PackedVector2Array([hand - d * 2.0 + d.orthogonal() * 2.6, hand + d * 0.5, hand - d * 2.0 - d.orthogonal() * 2.6]), Color(col, a))
	v.draw_line(hand - d * 2.0 + d.orthogonal() * 2.6, hand - d * 2.0 - d.orthogonal() * 2.6, Color(TRIM, 0.6 * a), 1.0)
	v.draw_circle(hand + d * 0.8, 1.1, Color(SKIN, a))


static func _dissolve(v: CharacterVisual, c: Vector2, t: float, k: float) -> void:
	for i in 12:
		var ang := i * 2.4
		var r := 4.0 + k * 22.0 + (i % 3) * 3.0
		var p := c + Vector2(cos(ang + t), sin(ang + t) * 1.2) * r + Vector2(0, -k * 10.0)
		KArt.star4(v, p, 1.0 + (i % 2), Color(STAR.lightened(0.3), (1.0 - k * 0.7)))


static func _grow(pts: PackedVector2Array, by: float) -> PackedVector2Array:
	var c := Vector2.ZERO
	for p in pts:
		c += p
	c /= maxf(pts.size(), 1)
	var out := PackedVector2Array()
	for p2 in pts:
		var d := p2 - c
		out.append(p2 + d.normalized() * by if d.length() > 0.01 else p2)
	return out
