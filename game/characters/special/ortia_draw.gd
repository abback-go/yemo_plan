extends "res://characters/special/ortia_palette.gd"
## 오르티아 장로 (세계수의 드루이드) 전용 몸 그림 — 키 34px, 등이 조금 굽은 늙은 엘프.
## 땅에 끌릴 듯한 흰 머리(이끼·작은 꽃이 엮임), 처진 긴 귀, 늘 웃는 듯 감은 눈, 나무껍질색 로브 + 이끼 망토,
## 살아 있는 가지 지팡이(새순 + 빛나는 씨앗), 가끔 지팡이 끝에 앉았다 가는 이끼 참새.
## 자세: idle · walk · special/cast(지팡이를 들어 씨앗이 밝게) · kneel(기도) · 그 밖 idle

const SKIN_SH := Color("#c09a84")
const ROBE_SH := Color("#3a2c1e")
const STAFF_HI := Color("#8a6c48")


static func draw_body(v: CharacterVisual) -> void:
	var t := v.time()
	var pose := v.pose if v.pose != "" else "idle"
	var walking := v.walking
	var ph := v.walk_phase() * 0.6
	var bob := sin(t * 1.6) * 0.5 if not walking else -absf(sin(ph)) * 0.6
	if v.talking:
		bob += sin(t * 10.0) * 0.3
	var raise := 0.0
	var kneel := 0.0
	match pose:
		"special", "cast":
			raise = clampf(v.pose_t / 0.6, 0.0, 1.0)
		"kneel":
			kneel = 5.0
	var stoop := 1.5 - raise * 1.0
	var hc := Vector2(2.0 + stoop, -30.0 + bob + kneel + stoop * 0.6)
	var top := Vector2(stoop * 0.6, -23 + bob + kneel)
	# 윤곽 빛
	v.draw_circle(Vector2(0, -18), 16.0, Color(SAP, 0.05))
	# 등 뒤로 흘러내린 긴 흰 머리 (이끼·꽃 엮음)
	var sw := sin(t * 1.2) * 0.8
	v.draw_colored_polygon(PackedVector2Array([hc + Vector2(-4, -3), hc + Vector2(1, -5), Vector2(-3 + sw, -3), Vector2(-9 + sw * 1.5, -1), Vector2(-8 + sw, -14)]), HAIR_SH)
	v.draw_colored_polygon(PackedVector2Array([hc + Vector2(-3, -4), hc + Vector2(0, -5), Vector2(-4 + sw, -5), Vector2(-7 + sw * 1.2, -14)]), HAIR)
	for p in [Vector2(-5, -18), Vector2(-7, -10), Vector2(-4, -8)]:
		var q: Vector2 = p + Vector2(sw * 0.6, 0)
		v.draw_rect(Rect2(q, Vector2(2, 1)), MOSS)
	v.draw_rect(Rect2(-6 + sw, -13, 1, 1), Color("#f0d8f0"))
	v.draw_rect(Rect2(-4 + sw, -21, 1, 1), Color("#ffe08a"))
	# 로브 (땅까지, 뿌리 같은 아랫단)
	var robe := PackedVector2Array([top + Vector2(-4, 0), top + Vector2(5, 0), Vector2(7, -1), Vector2(-7, -1)])
	v.draw_colored_polygon(robe, ROBE)
	v.draw_colored_polygon(PackedVector2Array([top + Vector2(-4, 0), top + Vector2(-1, 0), Vector2(-3, -1), Vector2(-7, -1)]), ROBE_SH)
	for i in 5:
		var x := -6.0 + i * 3.0
		v.draw_line(Vector2(x, -1), Vector2(x + sin(i * 1.3) * 1.0, 0), ROBE_SH, 1.0)
	# 이끼 망토 (어깨에 두르고 앞으로 늘어짐)
	var mant := PackedVector2Array([top + Vector2(-5, -1), top + Vector2(6, -1), top + Vector2(7 + sin(t * 1.5) * 0.4, 8), top + Vector2(-6, 9)])
	v.draw_colored_polygon(mant, MANTLE)
	v.draw_line(top + Vector2(-5, 8), top + Vector2(6, 7), MANTLE_SH, 1.0)
	for i in 4:
		v.draw_rect(Rect2(top.x - 4 + i * 3, top.y + 7 + (i % 2), 2, 2), MOSS)
	# 씨앗 목걸이
	var k := 0.7 + 0.3 * sin(t * 1.3)
	v.draw_line(top + Vector2(-1, -1), top + Vector2(1.5, 4), Color("#8a7a5a"), 1.0)
	v.draw_circle(top + Vector2(1.5, 5), 1.5, Color(SAP, 0.9 * k))
	v.draw_circle(top + Vector2(1.5, 5), 4.0, Color(SAP, 0.1 * k))
	# 지팡이 (앞손) — 들면 위로
	var hand := Vector2(7, -16 - raise * 8.0 + bob + kneel)
	var st_top := hand + Vector2(1.5, -16)
	var st_bot := Vector2(8.5, 0) if raise < 0.5 else hand + Vector2(-0.5, 12)
	v.draw_line(st_bot, st_top, STAFF, 2.0)
	v.draw_line(st_bot + Vector2(0.6, 0), st_top + Vector2(0.6, 0), STAFF_HI, 1.0)
	# 지팡이 끝: 말린 가지 + 새순 + 빛나는 씨앗
	v.draw_arc(st_top + Vector2(-2.5, 0), 2.5, -PI * 0.1, PI * 1.3, 8, STAFF, 1.5)
	for a in [-2.2, -1.2, -0.4]:
		var ang: float = a + sin(t * 1.4 + a) * 0.1
		var d := Vector2(cos(ang), sin(ang))
		v.draw_colored_polygon(PackedVector2Array([st_top, st_top + d * 3.0 + Vector2(-d.y, d.x) * 1.5, st_top + d * 6.0, st_top + d * 3.0 - Vector2(-d.y, d.x) * 1.5]), MOSS)
	var seed := st_top + Vector2(-3, 3)
	var glow := k + raise * 0.8
	v.draw_circle(seed, 6.0 + raise * 6.0, Color(SAP, 0.08 * glow))
	v.draw_circle(seed, 1.6, Color(0.92, 1.0, 0.75, minf(glow, 1.0)))
	if raise > 0.5:
		for i in 6:
			var a2 := t * 2.0 + TAU * i / 6.0
			v.draw_rect(Rect2(seed + Vector2(cos(a2), sin(a2)) * (8.0 + sin(t * 3.0 + i) * 2.0), Vector2(1, 1)), Color(SAP, 0.8))
	# 이끼 참새 (12초 중 6초 동안 지팡이 끝에 앉아 있음)
	var bt := fmod(t, 12.0)
	if bt > 3.0 and bt < 9.0 and raise <= 0.0:
		var bp := st_top + Vector2(0.5, -1.5 - (absf(sin(t * 6.0)) * 1.0 if fmod(t, 2.3) < 0.4 else 0.0))
		v.draw_circle(bp, 1.8, Color("#7a8a4a"))
		v.draw_circle(bp + Vector2(1.2, -1.2), 1.2, Color("#8a9a5a"))
		v.draw_rect(Rect2(bp.x + 2.0, bp.y - 1.4, 1, 1), Color("#d8a040"))
		v.draw_rect(Rect2(bp.x + 1.3, bp.y - 1.8, 1, 1), Color("#1a1a10"))
		v.draw_line(bp + Vector2(-1.5, 0.5), bp + Vector2(-3.0, 1.5), Color("#5a6a3a"), 1.0)
	# 팔과 손
	v.draw_line(top + Vector2(4, 1), hand, MANTLE, 2.0)
	v.draw_rect(Rect2(hand.x - 1, hand.y - 1, 2.4, 2.4), SKIN)
	# 머리: 처진 긴 귀
	var etip := hc + Vector2(-8.5, -2.0 + sin(t * 0.5) * 0.3)
	v.draw_colored_polygon(PackedVector2Array([hc + Vector2(-1.5, -1.5), etip, hc + Vector2(-1.0, 1.5)]), SKIN)
	v.draw_line(hc + Vector2(-2.0, 0.0), etip + Vector2(1.5, 0.8), SKIN_SH, 1.0)
	v.draw_circle(hc, 4.4, SKIN)
	# 주름과 웃는 감은 눈
	v.draw_arc(hc + Vector2(2.2, 0.6), 1.2, PI + 0.3, TAU - 0.3, 4, LINE, 1.0)
	v.draw_line(hc + Vector2(1.0, 2.5), hc + Vector2(3.5, 2.8), SKIN_SH, 1.0)
	v.draw_line(hc + Vector2(3.6, -1.6), hc + Vector2(4.2, -1.0), SKIN_SH, 1.0)
	if v.talking and int(t * 8.0) % 2 == 0:
		v.draw_rect(Rect2(hc.x + 2.2, hc.y + 3.0, 1.5, 1), Color("#7a3a32"))
	# 앞머리 (흰 머리를 가르마로 넘김) + 꽃 하나
	v.draw_colored_polygon(PackedVector2Array([hc + Vector2(-3.5, -3.5), hc + Vector2(1.5, -5.0), hc + Vector2(4.5, -2.5), hc + Vector2(2.0, -2.8), hc + Vector2(-1.0, -1.5)]), HAIR)
	v.draw_line(hc + Vector2(-3.0, -3.6), hc + Vector2(1.5, -4.8), Color.WHITE, 1.0)
	v.draw_rect(Rect2(hc.x - 3.5, hc.y - 4.5, 2, 2), Color("#f0d0f0"))
	v.draw_rect(Rect2(hc.x - 3.0, hc.y - 4.0, 1, 1), Color("#ffe08a"))
