extends RefCounted
## 3장 소품 그림 (Prop이 1장 목록에 없는 kind를 여기로 넘김) — docs/chapter3.md 7.7절 소품 목록.
## 원점: 바닥에 서는 것은 발밑, 매달린 것(등불·덩굴·현수막·풍경)은 천장(위 끝), 벽에 붙는 둥근 창은 창 가운데.
## 공통 키: w, h(타일), flip, front, len(매달린 길이, 타일), glow(빛 세기).
##
##   마을   elf_lantern(매달린 씨앗 꼬투리 등불) · elf_lantern_post · round_door · round_window(r) · seed_house(w,h)
##          hanging_bridge(w, sag) · leaf_awning(w) · market_stall(w) · herb_rack · tea_set · loom · bench_log
##          elf_banner(h) · wind_chime · wind_vane · firefly_jar · flower_bed(w) · fern · hammock(w) · elder_shelf(w,h)
##          bow_rack · archery_target · spirit_statue · eilach_sapling(white 0~1, 학교 온실 묘목)
##   숲·동굴 mushroom_glow(h) · mushroom_big(h) · root_arch(w,h) · vine_curtain(w,h) · moonwell(w)
##   역병   blight_crystal(h) · blight_tree(h) · blight_growth(w)

const SAP := Color("#c8ff7a")
const MUSH := Color("#5affd0")
const WHITE := Color("#f0f0ff")
const WARM := Color("#ffe6a0")
const WOOD := Color("#4a3420")
const WOOD_D := Color("#2a1d12")
const WOOD_L := Color("#7c5a36")
const LEAF := Color("#3a6a2a")
const LEAF_D := Color("#223f1a")
const LEAF_L := Color("#7ab450")
const GOLD := Color("#d8b04a")
const STONE := Color("#4a5048")
const STONE_L := Color("#6e766a")
const T := 16.0

const ANIMATED := ["elf_lantern", "elf_lantern_post", "wind_vane", "wind_chime", "elf_banner", "firefly_jar", "tea_set",
	"mushroom_glow", "mushroom_big", "moonwell", "vine_curtain", "blight_crystal", "spirit_statue", "round_window",
	"round_door", "seed_house", "flower_bed", "eilach_sapling", "blight_growth", "hammock", "loom", "market_stall"]


## 빛·움직임 정보: {animated, glow_pos, glow_r, glow_col} — 이 장 소품이 아니면 {}
static func setup_info(kind: String, p: Prop) -> Dictionary:
	var anim := kind in ANIMATED
	var info := {"animated": anim, "glow_r": 0.0, "glow_pos": Vector2.ZERO, "glow_col": SAP}
	match kind:
		"elf_lantern":
			var ln := float(p.params.get("len", 2)) * T
			info.glow_pos = Vector2(0, ln + 9)
			info.glow_r = 58.0
		"elf_lantern_post":
			info.glow_pos = Vector2(9, -38)
			info.glow_r = 54.0
		"round_door":
			info.glow_pos = Vector2(0, -16)
			info.glow_r = 34.0
			info.glow_col = WARM
		"round_window":
			info.glow_r = 30.0 * float(p.params.get("r", 1))
			info.glow_col = WARM
		"seed_house":
			info.glow_pos = Vector2(p.w * T * 0.18, -p.h * T * 0.55)
			info.glow_r = 50.0
			info.glow_col = WARM
		"firefly_jar":
			info.glow_pos = Vector2(0, -8)
			info.glow_r = 36.0
		"mushroom_glow":
			info.glow_pos = Vector2(0, -6 * p.h)
			info.glow_r = 34.0 * p.h
			info.glow_col = MUSH
		"mushroom_big":
			info.glow_pos = Vector2(0, -p.h * T * 0.8)
			info.glow_r = 26.0 * p.h
			info.glow_col = MUSH
		"moonwell":
			info.glow_pos = Vector2(0, -10)
			info.glow_r = 14.0 * p.w
			info.glow_col = Color(0.32, 0.42, 0.6)
		"blight_crystal":
			info.glow_pos = Vector2(0, -p.h * T * 0.5)
			info.glow_r = 22.0 * p.h
			info.glow_col = Color(0.85, 0.85, 1.0)
		"spirit_statue":
			info.glow_pos = Vector2(0, -34)
			info.glow_r = 40.0
		"tea_set":
			info.glow_pos = Vector2(0, -12)
			info.glow_r = 22.0
			info.glow_col = WARM
		"flower_bed":
			info.glow_pos = Vector2(0, -4)
			info.glow_r = 12.0 * p.w
		"eilach_sapling":
			info.glow_pos = Vector2(0, -24)
			info.glow_r = 40.0
			info.glow_col = SAP.lerp(WHITE, clampf(float(p.params.get("white", 0.0)), 0.0, 1.0))
		"market_stall":
			info.glow_pos = Vector2(0, -26)
			info.glow_r = 40.0
			info.glow_col = WARM
		_:
			if not anim and not kind in ["hanging_bridge", "leaf_awning", "herb_rack", "loom", "bench_log", "fern", "hammock",
					"elder_shelf", "bow_rack", "archery_target", "root_arch", "blight_tree", "blight_growth"]:
				return {}
	return info


## 그렸으면 true
static func draw(p: Prop, kind: String) -> bool:
	match kind:
		"elf_lantern": _elf_lantern(p)
		"elf_lantern_post": _lantern_post(p)
		"round_door": _round_door(p)
		"round_window": _round_window(p)
		"seed_house": _seed_house(p)
		"hanging_bridge": _hanging_bridge(p)
		"leaf_awning": _leaf_awning(p)
		"market_stall": _market_stall(p)
		"herb_rack": _herb_rack(p)
		"tea_set": _tea_set(p)
		"loom": _loom(p)
		"bench_log": _bench_log(p)
		"elf_banner": _elf_banner(p)
		"wind_chime": _wind_chime(p)
		"wind_vane": _wind_vane(p)
		"firefly_jar": _firefly_jar(p)
		"flower_bed": _flower_bed(p)
		"fern": _fern(p)
		"hammock": _hammock(p)
		"elder_shelf": _elder_shelf(p)
		"bow_rack": _bow_rack(p)
		"archery_target": _archery_target(p)
		"spirit_statue": _spirit_statue(p)
		"eilach_sapling": _sapling(p)
		"mushroom_glow": _mushroom_glow(p)
		"mushroom_big": _mushroom_big(p)
		"root_arch": _root_arch(p)
		"vine_curtain": _vine_curtain(p)
		"moonwell": _moonwell(p)
		"blight_crystal": _blight_crystal(p)
		"blight_tree": _blight_tree(p)
		"blight_growth": _blight_growth(p)
		_:
			return false
	return true


# ─── 공용 ───────────────────────────────────────────────

## 씨앗 꼬투리 등불 하나 (c = 꼭지, s = 크기)
static func _pod(p: Prop, c: Vector2, s: float, glow: float) -> void:
	p.draw_circle(c + Vector2(0, 6 * s), 9.0 * s, Color(SAP, 0.10 * glow))
	var outer := PackedVector2Array([c + Vector2(0, 0), c + Vector2(4 * s, 2.5 * s), c + Vector2(5 * s, 6 * s), c + Vector2(3 * s, 10 * s),
		c + Vector2(0, 12 * s), c + Vector2(-3 * s, 10 * s), c + Vector2(-5 * s, 6 * s), c + Vector2(-4 * s, 2.5 * s)])
	p.draw_colored_polygon(outer, Color("#5a7a2c"))
	# 꽃잎 틈 사이로 빛
	p.draw_colored_polygon(PackedVector2Array([c + Vector2(0, 2.5 * s), c + Vector2(2.5 * s, 6 * s), c + Vector2(0, 10.5 * s), c + Vector2(-2.5 * s, 6 * s)]), Color(0.92, 1.0, 0.62, 0.55 + 0.45 * glow))
	p.draw_rect(Rect2(c.x - 1 * s, c.y + 4 * s, 2 * s, 4 * s), Color(1, 1, 0.9, 0.7 + 0.3 * glow))
	p.draw_line(c + Vector2(-4 * s, 2.5 * s), c + Vector2(-2 * s, 10 * s), Color("#3a5a1c"), 1.0)
	p.draw_line(c + Vector2(4 * s, 2.5 * s), c + Vector2(2 * s, 10 * s), Color("#3a5a1c"), 1.0)
	# 꼭지 잎
	p.draw_colored_polygon(PackedVector2Array([c + Vector2(-1, 0), c + Vector2(-5 * s, -2 * s), c + Vector2(-2 * s, 1.5 * s)]), LEAF)
	p.draw_colored_polygon(PackedVector2Array([c + Vector2(1, 0), c + Vector2(5 * s, -2.5 * s), c + Vector2(2 * s, 1.5 * s)]), LEAF_L)
	p.draw_line(c + Vector2(0, 12 * s), c + Vector2(0, 14 * s), Color(SAP, 0.8), 1.0)


static func _leaf(p: Prop, base: Vector2, ang: float, len: float, wid: float, col: Color) -> void:
	var d := Vector2(cos(ang), sin(ang))
	var n := Vector2(-d.y, d.x)
	p.draw_colored_polygon(PackedVector2Array([base, base + d * len * 0.45 + n * wid, base + d * len, base + d * len * 0.45 - n * wid]), col)
	p.draw_line(base, base + d * len * 0.9, col.darkened(0.25), 1.0)


static func _ellipse(c: Vector2, rx: float, ry: float, n := 16) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		out.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return out


# ─── 마을 ───────────────────────────────────────────────

static func _elf_lantern(p: Prop) -> void:
	var t := p.time()
	var ln := float(p.params.get("len", 2)) * T
	var sway := sin(t * 1.3) * 1.8
	var c := Vector2(sway, ln)
	p.draw_line(Vector2.ZERO, c, Color("#5a4a30"), 1.0)
	p.draw_circle(Vector2(0, 1), 1.5, Color("#5a4a30"))
	_pod(p, c, 1.0, 0.75 + 0.25 * sin(t * 2.6))


static func _lantern_post(p: Prop) -> void:
	var t := p.time()
	# 휘어진 나무 기둥 (목동 지팡이처럼)
	p.draw_rect(Rect2(-2, -36, 4, 36), WOOD)
	p.draw_rect(Rect2(-2, -36, 1, 36), WOOD_L)
	p.draw_line(Vector2(0, -36), Vector2(4, -42), WOOD, 3.0)
	p.draw_line(Vector2(4, -42), Vector2(9, -42), WOOD, 3.0)
	p.draw_line(Vector2(9, -42), Vector2(10, -38), WOOD, 2.0)
	p.draw_rect(Rect2(-4, -2, 8, 2), WOOD_D)
	# 감긴 덩굴
	for i in 4:
		p.draw_line(Vector2(-2, -6 - i * 8), Vector2(2, -10 - i * 8), LEAF, 1.0)
	_leaf(p, Vector2(-2, -20), PI + 0.5, 6, 2, LEAF_L)
	var sway := sin(t * 1.5) * 1.0
	p.draw_line(Vector2(10, -38), Vector2(10 + sway, -34), Color("#5a4a30"), 1.0)
	_pod(p, Vector2(10 + sway, -34), 0.85, 0.8 + 0.2 * sin(t * 2.3))


static func _round_door(p: Prop) -> void:
	var t := p.time()
	var c := Vector2(0, -15)
	# 나무껍질 문틀 (두툼한 고리)
	p.draw_circle(c, 17.0, WOOD_D)
	p.draw_arc(c, 16.0, 0, TAU, 28, WOOD_L.darkened(0.1), 3.0)
	# 문짝 (세로 판자)
	p.draw_circle(c, 13.0, WOOD)
	for i in 5:
		var x := -10.0 + i * 5.0
		var hh := sqrt(maxf(169.0 - x * x, 0.0))
		p.draw_line(c + Vector2(x, -hh + 1), c + Vector2(x, hh - 1), WOOD_D, 1.0)
	p.draw_rect(Rect2(-13, -2, 26, 2), WOOD_D) # 문 아래쪽은 바닥으로 잘림
	# 잎 문양 새김
	_leaf(p, c + Vector2(0, 3), -PI * 0.5, 12, 4, WOOD_L)
	_leaf(p, c + Vector2(0, 0), -PI * 0.5 - 0.7, 8, 3, WOOD_L.darkened(0.1))
	_leaf(p, c + Vector2(0, 0), -PI * 0.5 + 0.7, 8, 3, WOOD_L.darkened(0.1))
	# 놋쇠 고리 손잡이
	p.draw_arc(c + Vector2(7, 2), 2.5, 0, TAU, 10, GOLD, 1.0)
	# 문틈 사이로 새는 따뜻한 빛
	var k := 0.6 + 0.2 * sin(t * 1.7)
	p.draw_arc(c, 13.0, PI * 0.15, PI * 0.45, 8, Color(WARM, 0.5 * k), 1.0)
	# 문턱 돌과 이끼
	p.draw_rect(Rect2(-16, -2, 32, 2), STONE)
	p.draw_rect(Rect2(-16, -2, 32, 1), STONE_L)
	for i in 6:
		p.draw_rect(Rect2(-17 + i * 6, -3 - (i % 2), 3, 1), LEAF_L)


static func _round_window(p: Prop) -> void:
	var t := p.time()
	var r := 7.0 * float(p.params.get("r", 1))
	p.draw_circle(Vector2.ZERO, r + 3.0, WOOD_D)
	p.draw_arc(Vector2.ZERO, r + 2.0, 0, TAU, 20, WOOD_L, 1.5)
	var k := 0.8 + 0.2 * sin(t * 1.3) * sin(t * 3.1)
	p.draw_circle(Vector2.ZERO, r, Color(WARM, 0.9 * k))
	p.draw_circle(Vector2(-r * 0.3, -r * 0.3), r * 0.35, Color(1, 1, 0.95, 0.5 * k))
	p.draw_line(Vector2(-r, 0), Vector2(r, 0), WOOD_D, 1.0)
	p.draw_line(Vector2(0, -r), Vector2(0, r), WOOD_D, 1.0)
	# 창가 화분 잎
	_leaf(p, Vector2(-r * 0.6, r + 2), PI + 0.4, 6, 2, LEAF_L)
	_leaf(p, Vector2(r * 0.6, r + 2), -0.4, 6, 2, LEAF)


static func _seed_house(p: Prop) -> void:
	var t := p.time()
	var ww := p.w * T
	var hh := p.h * T
	var c := Vector2(0, -hh * 0.48)
	# 꼬투리 몸 (위가 뾰족한 타원)
	var body := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		var y := sin(a) * hh * 0.48
		var x := cos(a) * ww * 0.5 * (1.0 - maxf(-sin(a), 0.0) * 0.25)
		body.append(c + Vector2(x, y))
	p.draw_colored_polygon(body, WOOD)
	# 판자 결
	for i in 6:
		var y := c.y - hh * 0.35 + i * hh * 0.14
		var half := ww * 0.5 * sqrt(maxf(1.0 - pow((y - c.y) / (hh * 0.48), 2), 0.0)) - 2.0
		p.draw_line(Vector2(-half, y), Vector2(half, y), WOOD_D, 1.0)
	# 오른쪽 빛, 왼쪽 그늘
	p.draw_arc(c, ww * 0.45, -0.9, 0.9, 12, Color(WOOD_L, 0.8), 2.0)
	# 잎 지붕 (겹겹)
	for i in 4:
		var y := c.y - hh * 0.3 - i * 5.0
		var rw := ww * (0.62 - i * 0.12)
		var col := LEAF_D.lerp(LEAF, i / 3.0)
		p.draw_colored_polygon(PackedVector2Array([Vector2(-rw, y + 5), Vector2(-rw * 0.5, y - 3), Vector2(0, y - 9), Vector2(rw * 0.5, y - 3), Vector2(rw, y + 5)]), col)
		for k in 4:
			var lx := -rw + (k + 0.5) * rw * 0.5
			p.draw_line(Vector2(lx, y + 4), Vector2(lx * 0.8, y - 2), col.darkened(0.3), 1.0)
	var tip := Vector2(0, c.y - hh * 0.3 - 26.0)
	p.draw_line(tip + Vector2(0, 6), tip, LEAF_D, 2.0)
	p.draw_circle(tip, 2.0, LEAF_L)
	# 둥근 창 (불빛)
	var wc := Vector2(ww * 0.18, -hh * 0.55)
	var k2 := 0.8 + 0.2 * sin(t * 1.1) * sin(t * 2.7)
	p.draw_circle(wc, 7.0, WOOD_D)
	p.draw_circle(wc, 5.0, Color(WARM, 0.95 * k2))
	p.draw_line(wc + Vector2(-5, 0), wc + Vector2(5, 0), WOOD_D, 1.0)
	p.draw_line(wc + Vector2(0, -5), wc + Vector2(0, 5), WOOD_D, 1.0)
	# 작은 둥근 창 하나 더
	var wc2 := Vector2(-ww * 0.22, -hh * 0.72)
	p.draw_circle(wc2, 4.0, WOOD_D)
	p.draw_circle(wc2, 2.6, Color(WARM, 0.7 * k2))
	# 둥근 문 (아래)
	var dc := Vector2(-ww * 0.12, -10)
	p.draw_circle(dc, 9.0, WOOD_D)
	p.draw_rect(Rect2(dc.x - 9, dc.y, 18, 10), WOOD_D)
	p.draw_circle(dc, 7.0, WOOD.darkened(0.15))
	p.draw_rect(Rect2(dc.x - 7, dc.y, 14, 10), WOOD.darkened(0.15))
	p.draw_line(Vector2(dc.x, dc.y - 7), Vector2(dc.x, 0), WOOD_D, 1.0)
	p.draw_circle(dc + Vector2(4, 2), 1.0, GOLD)
	# 문 옆 매달린 등불
	var sway := sin(t * 1.4) * 1.2
	p.draw_line(Vector2(dc.x + 12, -24), Vector2(dc.x + 12 + sway, -20), Color("#5a4a30"), 1.0)
	_pod(p, Vector2(dc.x + 12 + sway, -20), 0.6, 0.8 + 0.2 * sin(t * 2.0))


static func _hanging_bridge(p: Prop) -> void:
	var ww := p.w * T
	var sag := float(p.params.get("sag", 0.6)) * T
	var rope := Color("#8a7448")
	# 양끝 기둥
	for x in [0.0, ww]:
		p.draw_rect(Rect2(x - 2, -14, 4, 16), WOOD)
		p.draw_rect(Rect2(x - 2, -14, 4, 2), WOOD_L)
	var n := maxi(int(ww / 5.0), 3)
	var prev := Vector2(0, 0)
	var prev_r := Vector2(0, -12)
	for i in range(1, n + 1):
		var k := float(i) / n
		var pt := Vector2(ww * k, sin(k * PI) * sag)
		var rt := Vector2(ww * k, sin(k * PI) * sag * 0.8 - 12)
		p.draw_line(prev_r, rt, rope, 1.0)
		if i < n:
			p.draw_rect(Rect2(pt.x - 2, pt.y - 1, 4, 3), WOOD_L if i % 3 else WOOD)
			p.draw_rect(Rect2(pt.x - 2, pt.y + 2, 4, 1), WOOD_D)
			if i % 2 == 0:
				p.draw_line(pt, rt, Color(rope, 0.7), 1.0)
		p.draw_line(prev + Vector2(0, 2), pt + Vector2(0, 2), Color(rope, 0.8), 1.0)
		prev = pt
		prev_r = rt


static func _leaf_awning(p: Prop) -> void:
	var ww := p.w * T
	# 벽에서 비스듬히 내려오는 큰 잎들 (원점 = 위쪽 가운데)
	p.draw_rect(Rect2(-ww * 0.5, -2, ww, 3), WOOD)
	var n := maxi(int(ww / 10.0), 3)
	for i in n:
		var x := -ww * 0.5 + (i + 0.5) * ww / n
		var col := LEAF.lerp(LEAF_L, float(i % 3) / 3.0)
		_leaf(p, Vector2(x, 0), PI * 0.5 + (0.3 if i % 2 == 0 else -0.2), 16, 6, col)
	for i in n - 1:
		var x2 := -ww * 0.5 + (i + 1.0) * ww / n
		_leaf(p, Vector2(x2, 1), PI * 0.5, 12, 5, LEAF_D)


static func _market_stall(p: Prop) -> void:
	var t := p.time()
	var ww := p.w * T
	# 지붕 기둥
	p.draw_rect(Rect2(-ww * 0.5 + 2, -40, 3, 40), WOOD)
	p.draw_rect(Rect2(ww * 0.5 - 5, -40, 3, 40), WOOD)
	# 잎 차양
	var n := maxi(int(ww / 9.0), 3)
	for i in n:
		var x := -ww * 0.5 + (i + 0.5) * ww / n
		_leaf(p, Vector2(x, -44), PI * 0.5 + 0.15 * sin(t * 0.8 + i), 14, 5, LEAF if i % 2 else LEAF_L.darkened(0.2))
	p.draw_rect(Rect2(-ww * 0.5, -46, ww, 4), WOOD_D)
	# 판매대
	p.draw_rect(Rect2(-ww * 0.5, -14, ww, 4), WOOD_L)
	p.draw_rect(Rect2(-ww * 0.5 + 2, -10, ww - 4, 10), WOOD)
	for i in int(ww / 8.0):
		p.draw_line(Vector2(-ww * 0.5 + 4 + i * 8, -9), Vector2(-ww * 0.5 + 4 + i * 8, -1), WOOD_D, 1.0)
	# 바구니와 열매 (빛나는 열매 하나)
	var fruits := [Color("#d8603a"), Color("#e8c84a"), Color("#8ad04a"), Color("#a84ac8")]
	for i in mini(int(ww / 14.0), 4):
		var bx := -ww * 0.5 + 8 + i * 14
		p.draw_rect(Rect2(bx - 5, -19, 10, 5), Color("#8a6a3a"))
		var fc: Color = fruits[i % fruits.size()]
		for k in 3:
			p.draw_circle(Vector2(bx - 3 + k * 3, -20 - (k % 2)), 2.0, fc)
	p.draw_circle(Vector2(ww * 0.3, -21), 2.5, Color(SAP, 0.9))
	# 매달린 약초 묶음
	for i in 3:
		var hx := -ww * 0.3 + i * ww * 0.3
		p.draw_line(Vector2(hx, -42), Vector2(hx, -34), Color("#5a4a30"), 1.0)
		p.draw_colored_polygon(PackedVector2Array([Vector2(hx - 3, -34), Vector2(hx + 3, -34), Vector2(hx, -26)]), Color("#6a8a3a").darkened(i * 0.1))
	# 작은 등불
	p.draw_line(Vector2(0, -42), Vector2(0, -36), Color("#5a4a30"), 1.0)
	_pod(p, Vector2(0, -36), 0.5, 0.9)


static func _herb_rack(p: Prop) -> void:
	p.draw_rect(Rect2(-14, -28, 2, 28), WOOD)
	p.draw_rect(Rect2(12, -28, 2, 28), WOOD)
	p.draw_rect(Rect2(-15, -28, 30, 2), WOOD_L)
	p.draw_rect(Rect2(-14, -16, 28, 1), WOOD_D)
	var herbs := [Color("#6a8a3a"), Color("#8a7a4a"), Color("#5a7a5a"), Color("#9a6a8a"), Color("#7a9a4a")]
	for i in 5:
		var x := -11.0 + i * 5.5
		var hc: Color = herbs[i]
		p.draw_line(Vector2(x, -26), Vector2(x, -23), Color("#c8b890"), 1.0)
		p.draw_colored_polygon(PackedVector2Array([Vector2(x - 2, -23), Vector2(x + 2, -23), Vector2(x + 1, -17), Vector2(x - 1, -17)]), hc)
	for i in 3:
		p.draw_rect(Rect2(-10 + i * 8, -6, 6, 6), Color("#8a6a3a"))
		p.draw_rect(Rect2(-10 + i * 8, -6, 6, 1), Color("#a88a5a"))


static func _tea_set(p: Prop) -> void:
	var t := p.time()
	# 낮은 둥근 탁자 (그루터기)
	p.draw_rect(Rect2(-14, -8, 28, 8), WOOD)
	p.draw_rect(Rect2(-16, -10, 32, 3), WOOD_L)
	p.draw_arc(Vector2(0, -9), 8, PI, TAU, 10, WOOD_D, 1.0)
	# 찻주전자 (잎 무늬)
	p.draw_circle(Vector2(-4, -14), 4.5, Color("#c8d8b0"))
	p.draw_rect(Rect2(-8, -14, 9, 4), Color("#c8d8b0"))
	p.draw_line(Vector2(0, -15), Vector2(4, -18), Color("#c8d8b0"), 1.5)
	p.draw_rect(Rect2(-6, -19, 4, 1), Color("#8aa868"))
	_leaf(p, Vector2(-6, -14), 0.0, 4, 1.5, Color("#6a9a4a"))
	# 찻잔 둘
	for x in [6.0, 11.0]:
		p.draw_rect(Rect2(x - 2, -13, 4, 3), Color("#c8d8b0"))
		p.draw_rect(Rect2(x - 1.5, -13, 3, 1), Color("#a8c87a"))
	# 김 (모락모락)
	for i in 3:
		var k := fmod(t * 0.6 + i / 3.0, 1.0)
		var sx := 4.0 + sin(k * 6.0 + i) * 2.0
		p.draw_circle(Vector2(sx, -19 - k * 12), 1.0 + k * 1.5, Color(1, 1, 1, 0.25 * (1.0 - k)))


static func _loom(p: Prop) -> void:
	var t := p.time()
	p.draw_rect(Rect2(-16, -34, 3, 34), WOOD)
	p.draw_rect(Rect2(13, -34, 3, 34), WOOD)
	p.draw_rect(Rect2(-17, -36, 34, 3), WOOD_L)
	p.draw_rect(Rect2(-16, -8, 32, 3), WOOD)
	# 날실
	for i in 12:
		var x := -12.0 + i * 2.2
		p.draw_line(Vector2(x, -33), Vector2(x, -8), Color(0.85, 0.85, 0.7, 0.5), 1.0)
	# 짜인 천 (연금초록 잎 무늬)
	p.draw_rect(Rect2(-13, -22, 26, 14), Color("#5a7a3a"))
	for r in 3:
		for c in 4:
			_leaf(p, Vector2(-10 + c * 6.5, -12 - r * 4.5), -PI * 0.5 + 0.4, 4, 1.2, Color("#c8b860") if (r + c) % 2 == 0 else Color("#8ab050"))
	# 북 (왔다 갔다)
	var sx := sin(t * 0.8) * 9.0
	p.draw_rect(Rect2(sx - 4, -24, 8, 2), WOOD_L)


static func _bench_log(p: Prop) -> void:
	var ww := maxf(p.w, 2.0) * T
	p.draw_rect(Rect2(-ww * 0.5, -9, ww, 7), WOOD)
	p.draw_rect(Rect2(-ww * 0.5, -9, ww, 2), WOOD_L)
	p.draw_circle(Vector2(-ww * 0.5, -5.5), 3.5, Color("#9a7a4a"))
	p.draw_arc(Vector2(-ww * 0.5, -5.5), 2.0, 0, TAU, 8, WOOD, 1.0)
	p.draw_rect(Rect2(-ww * 0.4, -2, 3, 2), WOOD_D)
	p.draw_rect(Rect2(ww * 0.4 - 3, -2, 3, 2), WOOD_D)
	for i in 3:
		p.draw_rect(Rect2(-ww * 0.3 + i * ww * 0.25, -10, 3, 1), LEAF_L)


static func _elf_banner(p: Prop) -> void:
	var t := p.time()
	var hh := p.h * T
	var sway := sin(t * 1.1) * 2.0
	p.draw_rect(Rect2(-9, 0, 18, 2), WOOD_L)
	var col := Color(p.params.get("col", Color("#2e5a2a")))
	# 잎 모양 현수막
	p.draw_colored_polygon(PackedVector2Array([Vector2(-8, 2), Vector2(8, 2), Vector2(8 + sway * 0.6, hh * 0.7), Vector2(sway, hh), Vector2(-8 + sway * 0.6, hh * 0.7)]), col)
	p.draw_line(Vector2(0, 3), Vector2(sway, hh - 2), col.lightened(0.15), 1.0)
	# 세계수 문양 (줄기 + 가지 + 둥근 수관)
	var c := Vector2(sway * 0.4, hh * 0.4)
	p.draw_line(c + Vector2(0, 8), c + Vector2(0, -2), GOLD, 1.0)
	p.draw_line(c + Vector2(0, 2), c + Vector2(-3, -1), GOLD, 1.0)
	p.draw_line(c + Vector2(0, 2), c + Vector2(3, -1), GOLD, 1.0)
	p.draw_arc(c + Vector2(0, -4), 4.0, PI * 0.9, TAU + PI * 0.1, 10, GOLD, 1.0)
	p.draw_line(c + Vector2(-3, 8), c + Vector2(3, 8), GOLD, 1.0)
	for i in 3:
		p.draw_circle(Vector2(-6 + i * 6 + sway * 0.6, hh * 0.7 + 1), 1.0, GOLD)


static func _wind_chime(p: Prop) -> void:
	var t := p.time()
	var ln := float(p.params.get("len", 1)) * T
	var sway := sin(t * 1.6) * 2.5
	p.draw_line(Vector2.ZERO, Vector2(sway * 0.3, ln), Color("#5a4a30"), 1.0)
	var top := Vector2(sway * 0.3, ln)
	p.draw_rect(Rect2(top.x - 8, top.y, 16, 2), WOOD_L)
	for i in 5:
		var x := top.x - 6 + i * 3
		var len2 := 6.0 + (i % 3) * 3.0
		var sw := sin(t * 2.4 + i * 1.3) * 1.5
		p.draw_line(Vector2(x, top.y + 2), Vector2(x + sw, top.y + 2 + len2), Color(0.8, 0.8, 0.6, 0.6), 1.0)
		# 속이 빈 씨앗 관
		p.draw_rect(Rect2(x + sw - 1, top.y + 2 + len2, 2, 5), Color("#c8b878"))
		p.draw_rect(Rect2(x + sw - 1, top.y + 2 + len2, 2, 1), Color("#e8d898"))


static func _wind_vane(p: Prop) -> void:
	var t := p.time()
	p.draw_rect(Rect2(-1.5, -40, 3, 40), WOOD)
	p.draw_rect(Rect2(-4, -2, 8, 2), WOOD_D)
	var c := Vector2(0, -40)
	var rot := t * 2.4
	# 잎 날개 4장 (바람개비)
	for i in 4:
		var a := rot + TAU * i / 4.0
		_leaf(p, c, a, 11, 4, LEAF_L if i % 2 == 0 else LEAF)
	p.draw_circle(c, 2.0, GOLD)
	# 바람에 날리는 리본
	for k in 2:
		var pts := PackedVector2Array()
		for i in 7:
			var x := 2.0 + i * 3.5
			pts.append(c + Vector2(x, 6 + k * 4 + sin(t * 5.0 + i * 0.8 + k) * (1.0 + i * 0.4)))
		p.draw_polyline(pts, Color(0.85, 1.0, 0.75, 0.7) if k == 0 else Color(0.95, 0.85, 0.5, 0.7), 1.0)


static func _firefly_jar(p: Prop) -> void:
	var t := p.time()
	# 유리병
	p.draw_rect(Rect2(-6, -16, 12, 16), Color(0.7, 0.9, 0.8, 0.18))
	p.draw_rect(Rect2(-6, -16, 1, 16), Color(1, 1, 1, 0.35))
	p.draw_rect(Rect2(-4, -19, 8, 3), Color("#8a6a3a"))
	p.draw_line(Vector2(-4, -19), Vector2(0, -23), Color("#c8b890"), 1.0)
	p.draw_line(Vector2(4, -19), Vector2(0, -23), Color("#c8b890"), 1.0)
	p.draw_rect(Rect2(-6, -1, 12, 1), Color(0.7, 0.9, 0.8, 0.4))
	# 안의 반딧불
	for i in 5:
		var fp := Vector2(sin(t * (1.1 + i * 0.3) + i * 2.0) * 4.0, -8 + cos(t * (0.9 + i * 0.2) + i) * 6.0)
		var k := clampf(sin(t * 3.0 + i * 1.7) * 1.5, 0.2, 1.0)
		p.draw_circle(fp, 2.5, Color(SAP, 0.15 * k))
		p.draw_rect(Rect2(fp - Vector2(0.5, 0.5), Vector2(1, 1)), Color(1, 1, 0.8, k))


static func _flower_bed(p: Prop) -> void:
	var t := p.time()
	var ww := maxf(p.w, 1.0) * T
	var n := int(ww / 5.0)
	for i in n:
		var x := -ww * 0.5 + 2 + i * 5
		var h := 4.0 + (i * 7 % 5)
		var sw := sin(t * 1.2 + i) * 0.8
		p.draw_line(Vector2(x, 0), Vector2(x + sw, -h), LEAF, 1.0)
		var fc := SAP if i % 3 == 0 else (Color("#f0e8ff") if i % 3 == 1 else Color("#ffe08a"))
		var k := 0.6 + 0.4 * sin(t * 1.5 + i * 2.1)
		p.draw_rect(Rect2(x + sw - 1, -h - 1, 2, 2), Color(fc, 0.7 + 0.3 * k))
		if i % 3 == 0:
			p.draw_circle(Vector2(x + sw, -h), 3.0, Color(SAP, 0.08 * k))


static func _fern(p: Prop) -> void:
	var s := maxf(p.h, 1.0)
	for i in 7:
		var a := -PI * 0.5 + (i - 3) * 0.33
		var len := (12.0 + (3 - absi(i - 3)) * 3.0) * s
		var tip := Vector2(cos(a), sin(a)) * len
		var col := LEAF_D.lerp(LEAF, float(i % 3) / 2.0)
		p.draw_line(Vector2.ZERO, tip, col, 1.0)
		for k in 4:
			var q := tip * (0.3 + k * 0.17)
			var n := Vector2(-sin(a), cos(a)) * (3.0 - k * 0.5) * s
			p.draw_line(q, q + n + tip.normalized() * 2.0, col, 1.0)
			p.draw_line(q, q - n + tip.normalized() * 2.0, col, 1.0)


static func _hammock(p: Prop) -> void:
	var t := p.time()
	var ww := maxf(p.w, 2.0) * T
	var sw := sin(t * 0.9) * 1.5
	var pts := PackedVector2Array()
	for i in 13:
		var k := float(i) / 12.0
		pts.append(Vector2(-ww * 0.5 + ww * k, -24 + sin(k * PI) * 12.0 + sin(k * PI) * sw))
	p.draw_polyline(pts, Color("#8a9a5a"), 4.0)
	p.draw_polyline(pts, Color("#aab878"), 1.0)
	p.draw_line(Vector2(-ww * 0.5, -24), Vector2(-ww * 0.5 - 2, -34), Color("#8a7448"), 1.0)
	p.draw_line(Vector2(ww * 0.5, -24), Vector2(ww * 0.5 + 2, -34), Color("#8a7448"), 1.0)
	_leaf(p, pts[6] + Vector2(-4, -2), PI + 0.3, 8, 3, LEAF_L)


static func _elder_shelf(p: Prop) -> void:
	var ww := maxf(p.w, 2.0) * T
	var hh := maxf(p.h, 2.0) * T
	# 나무 속을 파낸 선반
	p.draw_rect(Rect2(-ww * 0.5, -hh, ww, hh), WOOD_D)
	p.draw_rect(Rect2(-ww * 0.5, -hh, 2, hh), WOOD_L)
	var rows := int(hh / 14.0)
	var jars := [Color(SAP, 0.7), Color("#c8a85a"), Color("#8ab8c8"), Color("#c87a5a")]
	for r in rows:
		var y := -hh + 12 + r * 14
		p.draw_rect(Rect2(-ww * 0.5, y, ww, 2), WOOD_L)
		var x := -ww * 0.5 + 3
		var i := 0
		while x < ww * 0.5 - 6:
			if (r + i) % 3 == 0:
				# 두루마리
				p.draw_rect(Rect2(x, y - 4, 7, 4), Color("#e8dcb8"))
				p.draw_rect(Rect2(x, y - 4, 1, 4), Color("#a89870"))
				x += 9
			else:
				# 씨앗 병
				var jc: Color = jars[(r * 3 + i) % jars.size()]
				p.draw_rect(Rect2(x, y - 7, 4, 7), Color(0.75, 0.9, 0.8, 0.3))
				p.draw_rect(Rect2(x + 1, y - 4, 2, 3), jc)
				p.draw_rect(Rect2(x, y - 8, 4, 1), Color("#8a6a3a"))
				x += 6
			i += 1


static func _bow_rack(p: Prop) -> void:
	p.draw_rect(Rect2(-14, -34, 2, 34), WOOD)
	p.draw_rect(Rect2(12, -34, 2, 34), WOOD)
	p.draw_rect(Rect2(-15, -30, 30, 2), WOOD_L)
	p.draw_rect(Rect2(-15, -12, 30, 2), WOOD_L)
	# 활 셋 (흰 활 하나, 나무 활 둘)
	var bows := [WOOD_L, Color("#e8e4d8"), WOOD_L.darkened(0.15)]
	for i in 3:
		var x := -8.0 + i * 8.0
		var bc: Color = bows[i]
		var pts := PackedVector2Array()
		for k in 9:
			var kk := float(k) / 8.0
			pts.append(Vector2(x + sin(kk * PI) * 3.0, -33 + kk * 30))
		p.draw_polyline(pts, bc, 1.5)
		p.draw_line(Vector2(x, -33), Vector2(x, -3), Color(1, 1, 1, 0.35), 1.0)
	# 화살통
	p.draw_rect(Rect2(10, -10, 5, 10), Color("#6a4a2a"))
	for k in 3:
		p.draw_line(Vector2(11 + k * 1.5, -10), Vector2(11 + k * 1.5, -15), Color("#e8e8e0"), 1.0)


static func _archery_target(p: Prop) -> void:
	# 다리 셋 + 둥근 짚 과녁 (엘프식: 초록·금 고리)
	p.draw_line(Vector2(-7, 0), Vector2(-2, -18), WOOD, 2.0)
	p.draw_line(Vector2(7, 0), Vector2(2, -18), WOOD, 2.0)
	p.draw_line(Vector2(0, 0), Vector2(0, -14), WOOD_D, 2.0)
	var c := Vector2(0, -22)
	p.draw_circle(c, 11.0, Color("#c8b878"))
	for i in 12:
		var a := TAU * i / 12.0
		p.draw_line(c + Vector2(cos(a), sin(a)) * 9.0, c + Vector2(cos(a), sin(a)) * 11.0, Color("#a89858"), 1.0)
	p.draw_circle(c, 8.0, Color("#3a6a3a"))
	p.draw_circle(c, 5.5, Color("#e8dcb0"))
	p.draw_circle(c, 3.0, GOLD)
	p.draw_circle(c, 1.2, Color("#8a2a1a"))
	# 꽂힌 화살 (흰 깃)
	for a2 in [[Vector2(1, -1), -0.4], [Vector2(-4, 2), 0.3]]:
		var hp: Vector2 = c + (a2[0] as Vector2)
		var ang: float = a2[1]
		var d := Vector2(cos(PI + ang), sin(PI + ang))
		p.draw_line(hp, hp + d * 9.0, Color("#c8a878"), 1.0)
		p.draw_line(hp + d * 7.0, hp + d * 10.0 + Vector2(0, -1.5), Color.WHITE, 1.0)
		p.draw_line(hp + d * 7.0, hp + d * 10.0 + Vector2(0, 1.5), Color.WHITE, 1.0)


static func _spirit_statue(p: Prop) -> void:
	var t := p.time()
	var st := Color("#4e5a4a")
	var st_l := Color("#6e7c66")
	# 받침
	p.draw_rect(Rect2(-14, -8, 28, 8), st.darkened(0.2))
	p.draw_rect(Rect2(-12, -10, 24, 2), st_l)
	# 긴 옷자락의 정령 (위로 갈수록 좁아짐)
	p.draw_colored_polygon(PackedVector2Array([Vector2(-10, -10), Vector2(10, -10), Vector2(6, -40), Vector2(-6, -40)]), st)
	p.draw_line(Vector2(-3, -12), Vector2(-2, -38), st.darkened(0.2), 1.0)
	p.draw_line(Vector2(4, -12), Vector2(3, -38), st_l, 1.0)
	# 얼굴 (매끈한 타원, 눈 감음)
	p.draw_colored_polygon(_ellipse(Vector2(0, -46), 5, 6, 12), st_l)
	p.draw_line(Vector2(-3, -46), Vector2(-1, -45.5), st.darkened(0.4), 1.0)
	p.draw_line(Vector2(1, -45.5), Vector2(3, -46), st.darkened(0.4), 1.0)
	# 사슴뿔 같은 가지 관
	for sx in [-1.0, 1.0]:
		var b := Vector2(sx * 3, -51)
		var a := b + Vector2(sx * 6, -10)
		p.draw_line(b, a, st, 2.0)
		p.draw_line(b + Vector2(sx * 3, -5), b + Vector2(sx * 10, -6), st, 1.0)
		p.draw_line(a, a + Vector2(sx * 3, -5), st, 1.0)
		p.draw_line(a, a + Vector2(-sx * 1, -6), st, 1.0)
		_leaf(p, a + Vector2(sx * 3, -5), -PI * 0.5 + sx * 0.6, 5, 2, Color("#4a7a3a"))
	# 두 손에 받친 씨앗 (빛)
	p.draw_line(Vector2(-6, -32), Vector2(-3, -34), st_l, 2.0)
	p.draw_line(Vector2(6, -32), Vector2(3, -34), st_l, 2.0)
	var k := 0.7 + 0.3 * sin(t * 1.4)
	p.draw_circle(Vector2(0, -35), 6.0, Color(SAP, 0.12 * k))
	p.draw_circle(Vector2(0, -35), 2.5, Color(0.9, 1.0, 0.7, 0.9 * k))
	# 이끼
	for i in 6:
		p.draw_rect(Rect2(-12 + i * 4, -11 - (i % 2), 3, 2), Color("#4a7a34"))
	p.draw_rect(Rect2(-7, -40, 4, 2), Color("#4a7a34"))


static func _sapling(p: Prop) -> void:
	# 세계수 묘목 (학교 온실): white 0~1 = 흰 역병으로 굳은 정도
	var t := p.time()
	var wv := clampf(float(p.params.get("white", 0.0)), 0.0, 1.0)
	var bark := Color("#5a4028").lerp(Color("#d8d8e2"), wv)
	var leaf := LEAF_L.lerp(Color("#e8e8f2"), wv)
	# 화분
	p.draw_rect(Rect2(-10, -10, 20, 10), Color("#8a4a3a"))
	p.draw_rect(Rect2(-12, -12, 24, 3), Color("#a85a46"))
	# 줄기와 가지
	p.draw_line(Vector2(0, -12), Vector2(0, -34), bark, 3.0)
	p.draw_line(Vector2(0, -24), Vector2(-8, -32), bark, 2.0)
	p.draw_line(Vector2(0, -28), Vector2(8, -36), bark, 2.0)
	# 잎 (굳은 쪽은 각진 수정처럼)
	var spots := [Vector2(-8, -32), Vector2(8, -36), Vector2(0, -36), Vector2(-4, -38), Vector2(5, -30)]
	for i in spots.size():
		var sp: Vector2 = spots[i]
		var white := float(i) / spots.size() < wv
		if white:
			p.draw_colored_polygon(PackedVector2Array([sp + Vector2(-3, 0), sp + Vector2(0, -5), sp + Vector2(3, 0), sp + Vector2(0, 2)]), Color("#e8e8f4"))
			p.draw_line(sp + Vector2(0, -5), sp + Vector2(0, 2), Color("#b8b8c8"), 1.0)
		else:
			_leaf(p, sp, -PI * 0.5 + sin(t + i) * 0.15 + (i - 2) * 0.3, 7, 3, leaf)
	# 줄기의 기하학 금
	if wv > 0.1:
		p.draw_line(Vector2(0, -14), Vector2(2, -18), Color(1, 1, 1, wv), 1.0)
		p.draw_line(Vector2(2, -18), Vector2(-1, -22), Color(1, 1, 1, wv), 1.0)
	var k := 0.6 + 0.4 * sin(t * 1.2)
	p.draw_circle(Vector2(0, -30), 8.0, Color(SAP.lerp(WHITE, wv), 0.08 * k))


# ─── 숲·동굴 ────────────────────────────────────────────

static func _mushroom_glow(p: Prop) -> void:
	var t := p.time()
	var s := maxf(p.h, 0.5)
	var specs := [[-6.0, 0.8, 0.0], [0.0, 1.2, 1.3], [5.0, 0.6, 2.4], [9.0, 0.9, 3.1], [-10.0, 0.5, 4.2]]
	for sp in specs:
		var x: float = sp[0] * s
		var k: float = sp[1] * s
		var ph: float = sp[2]
		var g := 0.65 + 0.35 * sin(t * 1.3 + ph)
		var base := Vector2(x, 0)
		p.draw_rect(Rect2(base.x - 1 * k, -6 * k, 2 * k, 6 * k), Color("#c8e8d8").darkened(0.3))
		var cap := PackedVector2Array()
		for i in 9:
			var a := PI + PI * i / 8.0
			cap.append(base + Vector2(cos(a) * 4.5 * k, -6 * k + sin(a) * 3.5 * k))
		p.draw_colored_polygon(cap, Color("#1e6a5a").lerp(MUSH, 0.25 * g))
		p.draw_line(base + Vector2(-4 * k, -6 * k), base + Vector2(4 * k, -6 * k), Color(MUSH, 0.9 * g), 1.0)
		p.draw_circle(base + Vector2(-1.5 * k, -8 * k), 0.8 * k, Color(MUSH, 0.8 * g))
		p.draw_circle(base + Vector2(0, -5 * k), 6.0 * k, Color(MUSH, 0.07 * g))


static func _mushroom_big(p: Prop) -> void:
	var t := p.time()
	var hh := maxf(p.h, 2.0) * T
	var cw := hh * 0.75
	var g := 0.7 + 0.3 * sin(t * 0.8)
	# 굵은 대
	p.draw_colored_polygon(PackedVector2Array([Vector2(-5, 0), Vector2(5, 0), Vector2(3, -hh * 0.8), Vector2(-3, -hh * 0.8)]), Color("#a8c8b8").darkened(0.45))
	p.draw_line(Vector2(2, -2), Vector2(1.5, -hh * 0.78), Color("#c8e8d8").darkened(0.2), 1.0)
	# 고리
	p.draw_rect(Rect2(-5, -hh * 0.55, 10, 2), Color("#c8e8d8").darkened(0.35))
	# 갓 (위)
	var cap := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		cap.append(Vector2(cos(a) * cw * 0.5, -hh * 0.8 + sin(a) * hh * 0.32))
	p.draw_colored_polygon(cap, Color("#163e38"))
	# 갓 위 점
	for i in 5:
		var a2 := PI + PI * (i + 0.5) / 5.0
		p.draw_circle(Vector2(cos(a2) * cw * 0.32, -hh * 0.8 + sin(a2) * hh * 0.2), 1.6, Color(MUSH, 0.55 * g))
	# 주름 (아래, 빛남)
	p.draw_colored_polygon(PackedVector2Array([Vector2(-cw * 0.5, -hh * 0.8), Vector2(cw * 0.5, -hh * 0.8), Vector2(cw * 0.3, -hh * 0.74), Vector2(-cw * 0.3, -hh * 0.74)]), Color(MUSH, 0.55 * g))
	for i in 7:
		var x := -cw * 0.42 + i * cw * 0.14
		p.draw_line(Vector2(x, -hh * 0.8), Vector2(x * 0.7, -hh * 0.745), Color(0.8, 1.0, 0.95, 0.6 * g), 1.0)
	# 떨어지는 빛 포자
	for i in 3:
		var k := fmod(t * 0.25 + i / 3.0, 1.0)
		p.draw_rect(Rect2(-cw * 0.3 + i * cw * 0.3 + sin(k * 6.0) * 3.0, -hh * 0.74 + k * hh * 0.7, 1, 1), Color(MUSH, 0.8 * (1.0 - k)))


static func _root_arch(p: Prop) -> void:
	var ww := maxf(p.w, 2.0) * T
	var hh := maxf(p.h, 2.0) * T
	var col := Color("#2e2a1e")
	var pts := PackedVector2Array()
	for i in 17:
		var a := PI + PI * i / 16.0
		pts.append(Vector2(cos(a) * ww * 0.5, sin(a) * hh))
	p.draw_polyline(pts, col, 9.0)
	var hi := PackedVector2Array()
	for q in pts:
		hi.append(q * 0.97 + Vector2(0, 1))
	p.draw_polyline(hi, col.lightened(0.15), 1.0)
	# 매달린 잔뿌리
	for i in 7:
		var q2: Vector2 = pts[2 + i * 2]
		p.draw_line(q2, q2 + Vector2(sin(i * 1.7) * 2.0, 6 + (i % 3) * 5), col, 1.0)
	# 발치 이끼
	for sx in [-1.0, 1.0]:
		for k in 3:
			p.draw_rect(Rect2(sx * ww * 0.5 - 4 + k * 3, -2 - k, 3, 2), LEAF)


static func _vine_curtain(p: Prop) -> void:
	var t := p.time()
	var ww := maxf(p.w, 1.0) * T
	var hh := maxf(p.h, 1.0) * T
	var n := int(ww / 4.0)
	for i in n:
		var x := -ww * 0.5 + 2 + i * 4
		var len := hh * (0.55 + 0.45 * absf(sin(i * 2.3)))
		var pts := PackedVector2Array()
		for k in 7:
			var kk := float(k) / 6.0
			pts.append(Vector2(x + sin(t * 0.9 + i * 0.7 + kk * 2.0) * 3.0 * kk * kk, len * kk))
		var col := LEAF_D.lerp(LEAF, float(i % 3) / 2.0)
		p.draw_polyline(pts, col, 1.0)
		for k in range(1, 7, 2):
			var lp: Vector2 = pts[k]
			p.draw_rect(Rect2(lp.x - 1, lp.y, 2, 2), col.lightened(0.15))
		# 작은 빛꽃
		if i % 4 == 1:
			var fp: Vector2 = pts[6]
			var g := 0.6 + 0.4 * sin(t * 2.0 + i)
			p.draw_rect(Rect2(fp.x - 1, fp.y, 2, 2), Color(SAP, g))


static func _moonwell(p: Prop) -> void:
	var t := p.time()
	var ww := maxf(p.w, 3.0) * T
	# 돌 테 (낮은 원형 우물, 앞면)
	p.draw_rect(Rect2(-ww * 0.5, -12, ww, 12), Color("#5a6470"))
	p.draw_rect(Rect2(-ww * 0.5, -12, ww, 2), Color("#8a94a0"))
	for i in int(ww / 12.0):
		p.draw_line(Vector2(-ww * 0.5 + 6 + i * 12, -10), Vector2(-ww * 0.5 + 6 + i * 12, 0), Color("#3e4650"), 1.0)
	# 은빛 물 (위에서 비스듬히 본 타원)
	p.draw_colored_polygon(_ellipse(Vector2(0, -13), ww * 0.46, 4, 20), Color("#22344a"))
	var k := 0.75 + 0.25 * sin(t * 0.9)
	p.draw_colored_polygon(_ellipse(Vector2(0, -13), ww * 0.42, 3, 20), Color(0.55, 0.75, 0.95, 0.55 * k))
	# 물에 비친 달
	p.draw_colored_polygon(_ellipse(Vector2(ww * 0.12, -13), 5, 1.6, 10), Color(0.95, 1.0, 0.9, 0.9 * k))
	# 물결
	for i in 3:
		var r := fmod(t * 6.0 + i * 8.0, 24.0)
		p.draw_arc(Vector2(-ww * 0.15, -13), r, PI * 1.1, PI * 1.9, 10, Color(1, 1, 1, 0.25 * (1.0 - r / 24.0)), 1.0)
	# 둘레의 룬 (은은히 빛남)
	for i in 5:
		var x := -ww * 0.4 + i * ww * 0.2
		p.draw_rect(Rect2(x - 1, -8, 2, 4), Color(0.8, 0.92, 1.0, 0.35 + 0.25 * sin(t * 1.5 + i)))
	# 떠 있는 꽃잎
	for i in 2:
		var fx := sin(t * 0.3 + i * 3.0) * ww * 0.3
		p.draw_rect(Rect2(fx, -14, 2, 1), Color("#f0e0f0"))


# ─── 흰 역병 ────────────────────────────────────────────

static func _hex_prism(p: Prop, base: Vector2, h: float, w: float, ang: float, col: Color) -> void:
	var d := Vector2(sin(ang), -cos(ang))
	var n := Vector2(-d.y, d.x)
	var shoulder := base + d * h * 0.8
	var tip := base + d * h
	p.draw_colored_polygon(PackedVector2Array([base - n * w * 0.5, shoulder - n * w * 0.5, tip, shoulder + n * w * 0.5, base + n * w * 0.5]), col)
	p.draw_colored_polygon(PackedVector2Array([base, shoulder, tip, shoulder - n * w * 0.5, base - n * w * 0.5]), col.lightened(0.18))
	p.draw_line(base, tip, Color(1, 1, 1, 0.8), 1.0)
	p.draw_line(shoulder - n * w * 0.5, tip, Color(1, 1, 1, 0.5), 1.0)


static func _blight_crystal(p: Prop) -> void:
	var t := p.time()
	var s := maxf(p.h, 1.0)
	var col := Color("#c8c8d6")
	var specs := [[0.0, 22.0, 7.0, 0.0], [-7.0, 14.0, 5.0, -0.5], [7.0, 16.0, 5.0, 0.45], [-3.0, 9.0, 4.0, -0.9], [4.0, 8.0, 3.0, 1.0]]
	for sp in specs:
		_hex_prism(p, Vector2(float(sp[0]) * s, 0), float(sp[1]) * s, float(sp[2]) * s, float(sp[3]), col.darkened(absf(float(sp[3])) * 0.2))
	# 맥동하는 흰빛 (바깥 신들의 숨)
	var k := clampf(sin(t * 0.9) * 1.5, 0.0, 1.0)
	p.draw_circle(Vector2(0, -12 * s), 6.0 * s, Color(WHITE, 0.12 * k))
	p.draw_line(Vector2(0, -2), Vector2(0, -22 * s), Color(1, 1, 1, 0.8 * k), 1.0)


static func _blight_tree(p: Prop) -> void:
	var hh := maxf(p.h, 3.0) * T
	var col := Color("#b8b8c4")
	var dark := Color("#7a7a88")
	p.draw_colored_polygon(PackedVector2Array([Vector2(-7, 0), Vector2(-3, -hh), Vector2(3, -hh), Vector2(7, 0)]), col)
	p.draw_line(Vector2(4, 0), Vector2(2, -hh), dark, 1.0)
	# 60도로만 꺾인 가지
	var spots := [0.45, 0.62, 0.8]
	for i in spots.size():
		var k: float = spots[i]
		var b := Vector2(0, -hh * k)
		var sx := -1.0 if i % 2 == 0 else 1.0
		var e := b + Vector2(sx * hh * 0.18, -hh * 0.18 * 0.58 * 1.7)
		p.draw_line(b, e, col, 3.0)
		p.draw_line(e, e + Vector2(0, -hh * 0.1), col, 2.0)
		p.draw_line(e, e + Vector2(sx * hh * 0.06, 0), col, 1.0)
	# 기하학 금
	var c := Vector2(0, -hh * 0.2)
	for i in 4:
		var n := c + Vector2((3 if i % 2 == 0 else -3), -hh * 0.07)
		p.draw_line(c, n, Color(1, 1, 1, 0.9), 1.0)
		c = n
	# 뿌리 쪽 수정
	_hex_prism(p, Vector2(-8, 0), 8, 4, -0.6, Color("#d0d0dc"))
	_hex_prism(p, Vector2(8, 0), 10, 4, 0.5, Color("#d0d0dc"))


static func _blight_growth(p: Prop) -> void:
	# 벽·바닥에 번진 흰 결정 (육각 격자 무늬)
	var t := p.time()
	var ww := maxf(p.w, 1.0) * T
	var n := int(ww / 6.0)
	for i in n:
		var x := -ww * 0.5 + 3 + i * 6
		var hgt := 3.0 + float((i * 5) % 7)
		var c := Vector2(x, -hgt * 0.5)
		var pts := PackedVector2Array()
		for k in 6:
			var a := TAU * k / 6.0 + PI / 6.0
			pts.append(c + Vector2(cos(a), sin(a)) * 3.0)
		p.draw_colored_polygon(pts, Color("#d8d8e4"))
		pts.append(pts[0])
		p.draw_polyline(pts, Color("#9a9aa8"), 1.0)
	var k2 := clampf(sin(t * 1.1) * 1.4, 0.0, 1.0)
	p.draw_line(Vector2(-ww * 0.5, -1), Vector2(ww * 0.5, -1), Color(1, 1, 1, 0.5 * k2), 1.0)
