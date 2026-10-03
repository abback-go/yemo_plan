extends RefCounted
## 2장 소품 그림 (Prop이 1장 목록에 없는 kind를 여기로 넘김). 모든 kind는 "k_" 접두사(다른 장과 겹치지 않게).
## 원점: 바닥에 서는 것은 발밑(가운데), 매달린 것(깃발·등불·간판·차양·깃발 줄)은 매다는 점, 벽에 붙는 톱니·시계는 중심.
## 공통 키: w, h(타일), flip, front, col(색), glow(빛 세기 0~1)
##
## kind 목록
##   거리·시장  k_stall(w, col, goods: bread·fruit·fish·cloth·star) · k_awning(w, col) · k_crates(n) · k_barrel(fill: water·apples)
##             k_lamp(h) · k_chimney(h) · k_bunting(w, sag) · k_sign(icon: bread·anvil·sword·potion·inn·star) · k_window(w,h, lit)
##             k_cart · k_flowers(w) · k_laundry(w) · k_noticeboard · k_fountain · k_bread(w,h) · k_forge · k_anvil
##   기사단     k_banner(w,h, col) · k_flag(h, col) · k_rack · k_dummy · k_statue_leonie · k_statue_lion
##   실내       k_glass(w,h) · k_pew(w) · k_candelabra · k_altar · k_bell · k_lantern(len) · k_portcullis(w,h)
##   시계 구역  k_gear(w=지름, speed, dir) · k_clock(w=지름, hour)
##   하수도     k_pipe(w,h, dir: h·v, drip) · k_grate(w,h) · k_valve
##   별·운석    k_crystal(h, col) · k_meteor(w,h) · k_rubble(w) · k_cult_circle(w)

const KArt := preload("res://world/entities/ch2/k_art.gd")
const T := 16.0
const WOOD := Color("#5e3e2a")
const WOOD_D := Color("#3c2618")
const WOOD_L := Color("#8a6040")
const IRON := Color("#3a3c46")
const IRON_L := Color("#6a6e7c")
const STONE := Color("#6a6a76")
const STONE_D := Color("#44444e")
const STONE_L := Color("#9a98a4")
const AMBER := Color("#ffb45a")
const TEAL := Color("#6af0e0")
const VIOLET := Color("#c89aff")

const ANIMATED := ["k_lamp", "k_chimney", "k_bunting", "k_sign", "k_banner", "k_flag", "k_dummy", "k_glass", "k_candelabra",
	"k_pipe", "k_grate", "k_crystal", "k_meteor", "k_gear", "k_forge", "k_fountain", "k_lantern", "k_cult_circle", "k_clock",
	"k_laundry", "k_altar", "k_stall"]


## 빛·움직임 정보: {animated, glow_pos, glow_r, glow_col} — 이 장 소품이 아니면 {}
static func setup_info(kind: String, p: Prop) -> Dictionary:
	if not kind.begins_with("k_"):
		return {}
	var info := {"animated": kind in ANIMATED}
	match kind:
		"k_lamp":
			info.glow_pos = Vector2(0, -p.h * T + 8)
			info.glow_r = 64.0
			info.glow_col = AMBER
		"k_lantern":
			info.glow_pos = Vector2(0, float(p.params.get("len", 2)) * T + 10)
			info.glow_r = 54.0
			info.glow_col = AMBER
		"k_candelabra":
			info.glow_pos = Vector2(0, -34)
			info.glow_r = 50.0
			info.glow_col = Color(1.0, 0.8, 0.5)
		"k_forge":
			info.glow_pos = Vector2(-8, -16)
			info.glow_r = 70.0
			info.glow_col = Color(1.0, 0.5, 0.2)
		"k_glass":
			info.glow_pos = Vector2(0, -p.h * T * 0.5)
			info.glow_r = 40.0 + p.w * 14.0
			info.glow_col = Color(1.0, 0.75, 0.6)
		"k_crystal":
			info.glow_pos = Vector2(0, -p.h * T * 0.5)
			info.glow_r = 30.0 + p.h * 12.0
			info.glow_col = Color(p.params.get("col", VIOLET))
		"k_meteor":
			info.glow_pos = Vector2(0, -p.h * T * 0.5)
			info.glow_r = 50.0 + p.w * 8.0
			info.glow_col = VIOLET
		"k_grate":
			info.glow_pos = Vector2(0, -p.h * T * 0.5)
			info.glow_r = 30.0 + p.w * 10.0
			info.glow_col = TEAL
		"k_cult_circle":
			info.glow_pos = Vector2(0, -4)
			info.glow_r = p.w * T * 0.7
			info.glow_col = VIOLET
		"k_altar":
			info.glow_pos = Vector2(0, -30)
			info.glow_r = 46.0
			info.glow_col = Color(1.0, 0.88, 0.55)
		"k_window":
			if bool(p.params.get("lit", true)):
				info.glow_pos = Vector2(0, -p.h * T * 0.5)
				info.glow_r = 30.0 + p.w * 8.0
				info.glow_col = AMBER
		"k_pipe":
			if bool(p.params.get("drip", true)):
				info.glow_pos = Vector2(0, -2)
				info.glow_r = 30.0
				info.glow_col = TEAL
		"k_fountain":
			info.glow_pos = Vector2(0, -12)
			info.glow_r = 50.0
			info.glow_col = Color(0.6, 0.85, 1.0)
		"k_statue_leonie":
			info.glow_pos = Vector2(0, -6)
			info.glow_r = 30.0
			info.glow_col = AMBER
	return info


## 그렸으면 true
static func draw(p: Prop, kind: String) -> bool:
	if not kind.begins_with("k_"):
		return false
	var t := p.time()
	match kind:
		"k_stall": _stall(p, t)
		"k_awning": _awning(p)
		"k_crates": _crates(p)
		"k_barrel": _barrel(p)
		"k_lamp": _lamp(p, t)
		"k_chimney": _chimney(p, t)
		"k_bunting": _bunting(p, t)
		"k_sign": _sign(p, t)
		"k_window": _window(p, t)
		"k_cart": _cart(p)
		"k_flowers": _flowers(p)
		"k_laundry": _laundry(p, t)
		"k_noticeboard": _noticeboard(p)
		"k_fountain": _fountain(p, t)
		"k_bread": _bread(p)
		"k_forge": _forge(p, t)
		"k_anvil": _anvil(p)
		"k_banner": _banner(p, t)
		"k_flag": _flag(p, t)
		"k_rack": _rack(p)
		"k_dummy": _dummy(p, t)
		"k_statue_leonie": _statue_leonie(p)
		"k_statue_lion": _statue_lion(p)
		"k_glass": _glass(p, t)
		"k_pew": _pew(p)
		"k_candelabra": _candelabra(p, t)
		"k_altar": _altar(p, t)
		"k_bell": _bell(p)
		"k_lantern": _lantern(p, t)
		"k_portcullis": _portcullis(p)
		"k_gear": _gear(p, t)
		"k_clock": _clock(p, t)
		"k_pipe": _pipe(p, t)
		"k_grate": _grate(p, t)
		"k_valve": _valve(p)
		"k_crystal": _crystal(p, t)
		"k_meteor": _meteor(p, t)
		"k_rubble": _rubble(p)
		"k_cult_circle": _cult_circle(p, t)
		_:
			return false
	return true


static func _col(p: Prop, def: Color) -> Color:
	return Color(p.params.get("col", def))


static func _outline_rect(p: Prop, r: Rect2, fill: Color, line := Color("#0a080e")) -> void:
	p.draw_rect(r.grow(1.0), line)
	p.draw_rect(r, fill)


# ─── 거리·시장 ──────────────────────────────────────────

## 시장 노점: 줄무늬 차양 + 판매대 + 물건
static func _stall(p: Prop, t: float) -> void:
	var w := (p.w if p.w > 1.0 else 4.0) * T
	var col := _col(p, Color("#a8323a"))
	var goods := String(p.params.get("goods", "bread"))
	var hw := w * 0.5
	# 뒤 기둥
	p.draw_rect(Rect2(-hw + 2, -46, 3, 46), WOOD_D)
	p.draw_rect(Rect2(hw - 5, -46, 3, 46), WOOD_D)
	# 판매대
	p.draw_rect(Rect2(-hw, -18, w, 4), WOOD_L)
	p.draw_rect(Rect2(-hw, -14, w, 14), WOOD)
	for i in int(w / 8.0):
		p.draw_rect(Rect2(-hw + i * 8 + 3, -13, 1, 12), WOOD_D)
	p.draw_rect(Rect2(-hw, -18, w, 1), WOOD_L.lightened(0.2))
	# 물건
	match goods:
		"bread":
			for i in int(w / 10.0):
				var x := -hw + 4 + i * 10
				p.draw_rect(Rect2(x, -22, 8, 4), Color("#c88a4a"))
				p.draw_rect(Rect2(x + 1, -23, 6, 1), Color("#e8b070"))
				p.draw_line(Vector2(x + 2, -21), Vector2(x + 4, -20), Color("#8a5a2a"), 1.0)
		"fruit":
			var fc := [Color("#d84a3a"), Color("#e8a040"), Color("#8ac04a"), Color("#a83a8a")]
			for i in int(w / 6.0):
				var c: Color = fc[i % fc.size()]
				p.draw_circle(Vector2(-hw + 4 + i * 6, -20 - (i % 2) * 2), 2.5, c)
				p.draw_rect(Rect2(-hw + 3 + i * 6, -22 - (i % 2) * 2, 1, 1), c.lightened(0.4))
		"fish":
			for i in int(w / 12.0):
				var x2 := -hw + 6 + i * 12
				p.draw_colored_polygon(PackedVector2Array([Vector2(x2 - 4, -20), Vector2(x2 + 3, -22), Vector2(x2 + 5, -20), Vector2(x2 + 3, -18)]), Color("#8aa0b8"))
				p.draw_colored_polygon(PackedVector2Array([Vector2(x2 - 4, -20), Vector2(x2 - 7, -22), Vector2(x2 - 7, -18)]), Color("#6a8098"))
		"cloth":
			var cc := [Color("#3a5aa8"), Color("#a8323a"), Color("#d8b040"), Color("#4a8a5a")]
			for i in int(w / 9.0):
				p.draw_rect(Rect2(-hw + 3 + i * 9, -24 + (i % 2), 7, 6), cc[i % cc.size()])
			# 걸린 천
			for i in 3:
				p.draw_rect(Rect2(-hw + 8 + i * 12, -40, 6, 14 - i * 2), cc[(i + 1) % cc.size()])
		"star":
			# 별 조각 부적 (별 신도가 파는 수상한 것)
			for i in int(w / 10.0):
				var gp := Vector2(-hw + 6 + i * 10, -22)
				var k := 0.6 + 0.4 * sin(t * 3.0 + i)
				KArt.star4(p, gp, 2.5 * k + 1.0, Color(VIOLET, 0.6 + 0.4 * k))
	# 차양 (줄무늬, 물결 모양 끝)
	var top := -52.0
	var aw := PackedVector2Array([Vector2(-hw - 4, top + 10), Vector2(-hw + 2, top), Vector2(hw - 2, top), Vector2(hw + 4, top + 10)])
	p.draw_colored_polygon(aw, col)
	var stripes := int(w / 8.0)
	for i in stripes:
		if i % 2 == 0:
			continue
		var x0 := -hw + 2 + i * (w - 4) / stripes
		var x1 := x0 + (w - 4) / stripes
		var b0 := x0 + (x0 / hw) * 6.0
		var b1 := x1 + (x1 / hw) * 6.0
		p.draw_colored_polygon(PackedVector2Array([Vector2(x0, top), Vector2(x1, top), Vector2(b1, top + 10), Vector2(b0, top + 10)]), Color("#ece0c8"))
	for i in stripes + 1:
		var sx := -hw - 4 + i * (w + 8) / (stripes + 1)
		p.draw_circle(Vector2(sx + (w + 8) / (stripes + 1) * 0.5, top + 10), (w + 8) / (stripes + 1) * 0.5, col if i % 2 == 0 else Color("#ece0c8"))
	p.draw_line(Vector2(-hw + 2, top), Vector2(hw - 2, top), col.lightened(0.25), 1.0)
	# 매달린 등불
	var lc := Vector2(hw - 8, top + 16 + sin(t * 1.4) * 0.5)
	p.draw_line(Vector2(hw - 8, top + 10), lc, IRON, 1.0)
	p.draw_rect(Rect2(lc.x - 2, lc.y, 5, 6), Color(AMBER, 0.9))
	p.draw_rect(Rect2(lc.x - 2, lc.y - 1, 5, 1), IRON)


## 벽에 붙은 차양 (원점 = 위 가운데)
static func _awning(p: Prop) -> void:
	var w := (p.w if p.w > 1.0 else 3.0) * T
	var col := _col(p, Color("#2e5a8a"))
	var hw := w * 0.5
	p.draw_rect(Rect2(-hw - 2, -2, w + 4, 3), IRON)
	p.draw_colored_polygon(PackedVector2Array([Vector2(-hw, 0), Vector2(hw, 0), Vector2(hw + 4, 14), Vector2(-hw - 4, 14)]), col)
	var n := int(w / 8.0)
	for i in n:
		if i % 2 == 0:
			continue
		var x0 := -hw + i * w / n
		var x1 := x0 + w / n
		p.draw_colored_polygon(PackedVector2Array([Vector2(x0, 0), Vector2(x1, 0), Vector2(x1 + x1 / hw * 4.0, 14), Vector2(x0 + x0 / hw * 4.0, 14)]), Color("#e8dcc4"))
	for i in n + 1:
		var sx := -hw - 4 + (i + 0.5) * (w + 8) / (n + 1)
		p.draw_circle(Vector2(sx, 14), (w + 8) / (n + 1) * 0.5, col if i % 2 == 0 else Color("#e8dcc4"))
	p.draw_line(Vector2(-hw, 1), Vector2(-hw - 4, 14), IRON, 1.0)
	p.draw_line(Vector2(hw, 1), Vector2(hw + 4, 14), IRON, 1.0)


## 쌓인 나무 상자 (n개)
static func _crates(p: Prop) -> void:
	var n := int(p.params.get("n", 2))
	var spots := [Vector2(-9, 0), Vector2(9, 0), Vector2(0, -16), Vector2(-18, 0)]
	for i in mini(n, 4):
		var o: Vector2 = spots[i]
		var r := Rect2(o + Vector2(-8, -16), Vector2(16, 16))
		_outline_rect(p, r, WOOD)
		p.draw_rect(Rect2(r.position, Vector2(16, 2)), WOOD_L)
		p.draw_rect(Rect2(r.position + Vector2(0, 7), Vector2(16, 1)), WOOD_D)
		p.draw_line(r.position + Vector2(1, 1), r.position + Vector2(15, 15), WOOD_D, 1.0)
		p.draw_rect(Rect2(r.position + Vector2(0, 0), Vector2(2, 16)), WOOD_D)
		p.draw_rect(Rect2(r.position + Vector2(14, 0), Vector2(2, 16)), WOOD_D)
		if i == 0:
			# 찍힌 은사자 낙인
			p.draw_circle(r.get_center() + Vector2(3, 2), 2.0, Color("#2a1a10"))


static func _barrel(p: Prop) -> void:
	var fill := String(p.params.get("fill", ""))
	var body := PackedVector2Array([Vector2(-6, 0), Vector2(-8, -9), Vector2(-6, -18), Vector2(6, -18), Vector2(8, -9), Vector2(6, 0)])
	p.draw_colored_polygon(body, WOOD)
	p.draw_colored_polygon(PackedVector2Array([Vector2(2, 0), Vector2(3, -9), Vector2(2, -18), Vector2(6, -18), Vector2(8, -9), Vector2(6, 0)]), WOOD_D)
	p.draw_line(Vector2(-4, -1), Vector2(-5, -17), WOOD_L, 1.0)
	for y in [-3.0, -15.0]:
		p.draw_rect(Rect2(-7, y - 1, 14, 2), IRON)
	p.draw_rect(Rect2(-8, -10, 16, 2), IRON_L.darkened(0.2))
	p.draw_rect(Rect2(-6, -19, 12, 2), WOOD_D)
	if fill == "apples":
		for i in 4:
			p.draw_circle(Vector2(-4 + i * 2.6, -20 - (i % 2)), 2.0, Color("#c83a2a"))
	elif fill == "water":
		p.draw_rect(Rect2(-5, -19, 10, 1), Color(0.5, 0.75, 0.9))


## 가로등: 쇠기둥 + 유리 등불 (불꽃 흔들림)
static func _lamp(p: Prop, t: float) -> void:
	var h := (p.h if p.h > 1.0 else 4.0) * T
	p.draw_rect(Rect2(-5, -4, 10, 4), IRON)
	p.draw_rect(Rect2(-2, -h + 10, 4, h - 10), IRON)
	p.draw_rect(Rect2(-1, -h + 10, 1, h - 12), IRON_L)
	p.draw_rect(Rect2(-3, -h * 0.5, 6, 2), IRON_L)
	# 등불 갓
	var top := -h + 10
	p.draw_colored_polygon(PackedVector2Array([Vector2(-7, top - 12), Vector2(7, top - 12), Vector2(4, top - 17), Vector2(-4, top - 17)]), IRON)
	p.draw_rect(Rect2(-1, top - 20, 2, 3), IRON)
	var fl := 0.85 + 0.15 * sin(t * 9.0) + 0.05 * sin(t * 23.0)
	p.draw_rect(Rect2(-5, top - 12, 10, 12), Color(AMBER.darkened(0.3), 0.9))
	p.draw_rect(Rect2(-4, top - 11, 8, 10), Color(AMBER, fl))
	p.draw_rect(Rect2(-2, top - 8, 4, 6), Color(1.0, 0.95, 0.75, fl))
	p.draw_rect(Rect2(-5, top - 12, 1, 12), IRON)
	p.draw_rect(Rect2(4, top - 12, 1, 12), IRON)
	p.draw_rect(Rect2(-6, top - 1, 12, 2), IRON)


## 지붕 위 굴뚝 + 연기
static func _chimney(p: Prop, t: float) -> void:
	var h := (p.h if p.h > 1.0 else 2.0) * T
	var brick := Color("#6a3a30")
	p.draw_rect(Rect2(-7, -h, 14, h), brick)
	for row in int(h / 4.0):
		var y := -h + row * 4
		p.draw_rect(Rect2(-7, y, 14, 1), brick.darkened(0.3))
		p.draw_rect(Rect2(-7 + (4 if row % 2 == 0 else 0), y, 1, 4), brick.darkened(0.3))
	p.draw_rect(Rect2(-9, -h - 3, 18, 4), brick.lightened(0.12))
	p.draw_rect(Rect2(-5, -h - 2, 10, 2), Color("#1a0e0c"))
	KArt.smoke(p, Vector2(0, -h - 4), t, float(int(p.position.x) % 97) / 97.0, Color(0.68, 0.66, 0.74, 0.3), 1.2, 7)
	p.draw_rect(Rect2(-4, -h - 2, 8, 1), Color(1.0, 0.5, 0.2, 0.4 + 0.2 * sin(t * 6.0)))


## 장식 깃발 줄 (원점 = 왼쪽 매다는 점, w = 오른쪽 끝까지 타일)
static func _bunting(p: Prop, t: float) -> void:
	var w := (p.w if p.w > 1.0 else 6.0) * T
	var sag := float(p.params.get("sag", 1.0)) * T
	var cols := [Color("#b8323a"), Color("#e0b040"), Color("#3a62b0"), Color("#ece4d4")]
	var n := int(w / 10.0)
	var sway := sin(t * 1.1) * 2.0
	var prev := Vector2.ZERO
	for i in range(1, n + 1):
		var k := float(i) / n
		var pt := Vector2(w * k, sin(k * PI) * (sag + sway))
		p.draw_line(prev, pt, Color("#2a2420"), 1.0)
		if i < n:
			var fc: Color = cols[i % cols.size()]
			var f := sin(t * 3.0 + i * 0.9) * 1.5
			p.draw_colored_polygon(PackedVector2Array([pt + Vector2(-3, 0), pt + Vector2(3, 0), pt + Vector2(f, 8)]), fc)
			p.draw_line(pt + Vector2(-3, 0), pt + Vector2(f * 0.5, 4), fc.lightened(0.25), 1.0)
		prev = pt


## 매달린 가게 간판 (원점 = 벽 쪽 받침대). icon: bread·anvil·sword·potion·inn·star
static func _sign(p: Prop, t: float) -> void:
	var icon := String(p.params.get("icon", "bread"))
	var swing := sin(t * 1.3) * 0.08
	p.draw_rect(Rect2(-2, -2, 4, 4), IRON)
	p.draw_line(Vector2(0, 0), Vector2(20, 0), IRON, 2.0)
	p.draw_line(Vector2(2, 0), Vector2(8, -6), IRON, 1.0)
	p.draw_set_transform(Vector2(13, 1), swing, Vector2.ONE)
	p.draw_line(Vector2(-6, 0), Vector2(-6, 4), IRON_L, 1.0)
	p.draw_line(Vector2(6, 0), Vector2(6, 4), IRON_L, 1.0)
	var board := Rect2(-9, 4, 18, 14)
	_outline_rect(p, board, WOOD)
	p.draw_rect(Rect2(board.position, Vector2(18, 1)), WOOD_L)
	var c := Vector2(0, 11)
	match icon:
		"bread":
			p.draw_rect(Rect2(c.x - 6, c.y - 2, 12, 5), Color("#d89a5a"))
			p.draw_rect(Rect2(c.x - 5, c.y - 3, 10, 1), Color("#f0c080"))
			p.draw_line(c + Vector2(-3, -1), c + Vector2(-1, 1), Color("#8a5a2a"), 1.0)
			p.draw_line(c + Vector2(1, -1), c + Vector2(3, 1), Color("#8a5a2a"), 1.0)
		"anvil":
			p.draw_rect(Rect2(c.x - 6, c.y - 3, 12, 3), Color("#9aa0b0"))
			p.draw_rect(Rect2(c.x - 2, c.y, 4, 3), Color("#7a8090"))
			p.draw_rect(Rect2(c.x - 4, c.y + 3, 8, 2), Color("#7a8090"))
		"sword":
			p.draw_line(c + Vector2(-6, 4), c + Vector2(5, -5), Color("#d8dce8"), 1.0)
			p.draw_line(c + Vector2(-4, 0), c + Vector2(-1, 3), Color("#c8a040"), 1.0)
		"potion":
			p.draw_circle(c + Vector2(0, 1), 3.5, Color("#c84a6a"))
			p.draw_rect(Rect2(c.x - 1, c.y - 5, 2, 3), Color("#c8b8a0"))
		"inn":
			p.draw_rect(Rect2(c.x - 4, c.y - 3, 6, 7), Color("#d8a040"))
			p.draw_arc(c + Vector2(3, 0), 2.0, -1.4, 1.4, 6, Color("#d8a040"), 1.0)
			p.draw_rect(Rect2(c.x - 3, c.y - 3, 4, 1), Color("#f8f0e0"))
		"star":
			KArt.star5(p, c, 5.0, Color(VIOLET, 0.9), t * 0.3)
	p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## 집 창문 (덧문 + 화분 받침). lit=false면 꺼진 창
static func _window(p: Prop, t: float) -> void:
	var w := (p.w if p.w > 1.0 else 2.0) * T * 0.7
	var h := (p.h if p.h > 1.0 else 2.0) * T * 0.8
	var lit := bool(p.params.get("lit", true))
	var r := Rect2(-w * 0.5, -h, w, h)
	p.draw_rect(r.grow(2.0), Color("#2a2028"))
	var fl := 0.85 + 0.15 * sin(t * 1.3 + p.position.x)
	p.draw_rect(r, Color(AMBER, fl) if lit else Color("#141820"))
	if lit:
		p.draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(w * 0.35, h * 0.4)), Color(1.0, 0.92, 0.7, 0.6 * fl))
	p.draw_rect(Rect2(-1, -h, 2, h), Color("#2a2028"))
	p.draw_rect(Rect2(-w * 0.5, -h * 0.5 - 1, w, 2), Color("#2a2028"))
	# 덧문
	p.draw_rect(Rect2(-w * 0.5 - 7, -h - 1, 5, h + 2), Color("#3a5a4a"))
	p.draw_rect(Rect2(w * 0.5 + 2, -h - 1, 5, h + 2), Color("#3a5a4a"))
	for i in int(h / 4.0):
		p.draw_rect(Rect2(-w * 0.5 - 7, -h + i * 4, 5, 1), Color("#2a4236"))
		p.draw_rect(Rect2(w * 0.5 + 2, -h + i * 4, 5, 1), Color("#2a4236"))
	# 화분 받침
	p.draw_rect(Rect2(-w * 0.5 - 3, 1, w + 6, 4), WOOD)
	for i in int(w / 4.0):
		p.draw_circle(Vector2(-w * 0.5 + 1 + i * 4, 0), 1.6, [Color("#d84a5a"), Color("#e8c040"), Color("#c86ad8")][i % 3])


## 손수레 (바퀴 둘 + 자루)
static func _cart(p: Prop) -> void:
	p.draw_rect(Rect2(-18, -16, 34, 8), WOOD)
	p.draw_rect(Rect2(-18, -16, 34, 2), WOOD_L)
	p.draw_line(Vector2(16, -12), Vector2(30, -18), WOOD_D, 2.0)
	for sx in [-10.0, 8.0]:
		var c := Vector2(sx, -6)
		p.draw_circle(c, 6.0, WOOD_D)
		p.draw_circle(c, 4.5, WOOD)
		p.draw_line(c + Vector2(-4, 0), c + Vector2(4, 0), WOOD_D, 1.0)
		p.draw_line(c + Vector2(0, -4), c + Vector2(0, 4), WOOD_D, 1.0)
		p.draw_circle(c, 1.2, IRON)
	# 자루
	p.draw_colored_polygon(PackedVector2Array([Vector2(-15, -16), Vector2(-14, -26), Vector2(-6, -27), Vector2(-4, -16)]), Color("#b8a074"))
	p.draw_colored_polygon(PackedVector2Array([Vector2(-4, -16), Vector2(-2, -24), Vector2(6, -25), Vector2(8, -16)]), Color("#a89060"))
	p.draw_line(Vector2(-11, -26), Vector2(-9, -28), Color("#6a5a3a"), 1.0)


## 화분 줄 (w 타일)
static func _flowers(p: Prop) -> void:
	var w := (p.w if p.w > 1.0 else 2.0) * T
	var cols := [Color("#d84a5a"), Color("#e8c040"), Color("#c86ad8"), Color("#ece8f0")]
	var n := int(w / 9.0)
	for i in n:
		var x := -w * 0.5 + 4 + i * 9
		p.draw_rect(Rect2(x - 3, -6, 7, 6), Color("#9a5a3a"))
		p.draw_rect(Rect2(x - 4, -7, 9, 2), Color("#b06a46"))
		for k in 3:
			var a := -PI * 0.5 + (k - 1) * 0.5
			var tip := Vector2(x + 0.5, -7) + Vector2(cos(a), sin(a)) * 5.0
			p.draw_line(Vector2(x + 0.5, -7), tip, Color("#3a7a3a"), 1.0)
			p.draw_circle(tip, 1.5, cols[(i + k) % cols.size()])


## 빨랫줄 (원점 = 왼쪽 끝, w 타일)
static func _laundry(p: Prop, t: float) -> void:
	var w := (p.w if p.w > 1.0 else 5.0) * T
	var cols := [Color("#e8e0d0"), Color("#8aa0c8"), Color("#c87a6a"), Color("#d8c8a0")]
	var n := 5
	var prev := Vector2.ZERO
	for i in range(1, 11):
		var k := float(i) / 10.0
		var pt := Vector2(w * k, sin(k * PI) * 8.0)
		p.draw_line(prev, pt, Color("#3a3430"), 1.0)
		prev = pt
	for i in n:
		var k2 := (i + 0.7) / (n + 0.4)
		var at := Vector2(w * k2, sin(k2 * PI) * 8.0)
		var sw := sin(t * 1.6 + i * 1.3) * 1.5
		var c: Color = cols[i % cols.size()]
		if i % 2 == 0:
			# 셔츠
			p.draw_colored_polygon(PackedVector2Array([at + Vector2(-6, 0), at + Vector2(6, 0), at + Vector2(5 + sw, 12), at + Vector2(-5 + sw, 12)]), c)
			p.draw_line(at + Vector2(-6, 0), at + Vector2(-9 + sw * 0.5, 5), c, 2.0)
			p.draw_line(at + Vector2(6, 0), at + Vector2(9 + sw * 0.5, 5), c, 2.0)
		else:
			# 천
			p.draw_rect(Rect2(at.x - 5 + sw * 0.3, at.y, 10, 9), c)
		p.draw_rect(Rect2(at.x - 1, at.y - 1, 2, 2), WOOD_L)


## 게시판 (현상 수배·포고문)
static func _noticeboard(p: Prop) -> void:
	p.draw_rect(Rect2(-16, -4, 3, 4), WOOD_D)
	p.draw_rect(Rect2(13, -4, 3, 4), WOOD_D)
	p.draw_rect(Rect2(-14, -30, 2, 28), WOOD_D)
	p.draw_rect(Rect2(12, -30, 2, 28), WOOD_D)
	_outline_rect(p, Rect2(-16, -32, 32, 22), WOOD)
	p.draw_colored_polygon(PackedVector2Array([Vector2(-19, -32), Vector2(0, -38), Vector2(19, -32)]), WOOD_D)
	# 종이들
	p.draw_rect(Rect2(-13, -29, 10, 13), Color("#e8dcc0"))
	p.draw_rect(Rect2(-11, -27, 6, 5), Color("#5a4a6a"))
	p.draw_circle(Vector2(-8, -24.5), 1.5, VIOLET) # 별의 짐승 수배
	p.draw_rect(Rect2(-12, -20, 8, 1), Color("#8a7a6a"))
	p.draw_rect(Rect2(-12, -18, 6, 1), Color("#8a7a6a"))
	p.draw_rect(Rect2(-1, -30, 12, 9), Color("#f0e8d4"))
	p.draw_rect(Rect2(1, -28, 8, 1), Color("#a8323a"))
	p.draw_rect(Rect2(1, -26, 7, 1), Color("#8a7a6a"))
	p.draw_rect(Rect2(1, -24, 6, 1), Color("#8a7a6a"))
	p.draw_rect(Rect2(2, -19, 9, 7), Color("#d8ccb0"))
	p.draw_circle(Vector2(-8, -29), 0.8, Color("#a8323a"))
	p.draw_circle(Vector2(5, -30), 0.8, Color("#a8323a"))


## 사자 머리 분수 (물이 흐름)
static func _fountain(p: Prop, t: float) -> void:
	var water := Color(0.55, 0.78, 0.95)
	# 수반
	p.draw_rect(Rect2(-30, -12, 60, 12), STONE_D)
	p.draw_rect(Rect2(-32, -14, 64, 3), STONE_L)
	p.draw_rect(Rect2(-28, -11, 56, 3), Color(water, 0.75))
	for i in 6:
		var wx := -26.0 + fmod(i * 11.0 + t * 6.0, 52.0)
		p.draw_rect(Rect2(wx, -10, 4, 1), Color(1, 1, 1, 0.5))
	# 가운데 기둥 + 위 수반
	p.draw_rect(Rect2(-5, -38, 10, 26), STONE)
	p.draw_rect(Rect2(-2, -38, 2, 26), STONE_L)
	p.draw_rect(Rect2(-14, -42, 28, 4), STONE_L)
	p.draw_rect(Rect2(-12, -40, 24, 2), Color(water, 0.7))
	# 사자 머리
	var hc := Vector2(0, -50)
	p.draw_circle(hc, 7.0, STONE)
	p.draw_circle(hc + Vector2(0, 1), 4.5, STONE_L)
	p.draw_rect(Rect2(hc.x - 1, hc.y + 2, 2, 2), STONE_D)
	p.draw_rect(Rect2(hc.x - 3, hc.y - 1, 1, 1), STONE_D)
	p.draw_rect(Rect2(hc.x + 2, hc.y - 1, 1, 1), STONE_D)
	# 물줄기 (양쪽으로 떨어짐)
	for side in [-1.0, 1.0]:
		var pts := PackedVector2Array()
		for i in 8:
			var k := i / 7.0
			pts.append(Vector2(side * (2 + k * 18), -46 + k * k * 34))
		p.draw_polyline(pts, Color(water, 0.6), 2.0)
		for j in 3:
			var ph := fmod(t * 1.8 + j * 0.33, 1.0)
			p.draw_rect(Rect2(side * (2 + ph * 18) - 0.5, -46 + ph * ph * 34 - 0.5, 1, 1), Color(1, 1, 1, 0.8))
	for i in 4:
		var sp := fmod(t * 2.0 + i * 0.25, 1.0)
		p.draw_circle(Vector2((i - 1.5) * 12.0, -13 - sp * 3.0), 1.0 + sp, Color(1, 1, 1, 0.35 * (1.0 - sp)))


## 빵 진열장 (w×h 타일)
static func _bread(p: Prop) -> void:
	var w := (p.w if p.w > 1.0 else 3.0) * T
	var h := (p.h if p.h > 1.0 else 3.0) * T
	p.draw_rect(Rect2(-w * 0.5, -h, w, h), WOOD_D)
	p.draw_rect(Rect2(-w * 0.5 + 2, -h + 2, w - 4, h - 4), Color("#2a1a12"))
	var shelves := int(h / 14.0)
	for s in shelves:
		var y := -h + 12 + s * 14
		p.draw_rect(Rect2(-w * 0.5, y, w, 2), WOOD_L)
		var x := -w * 0.5 + 3
		var k := s
		while x < w * 0.5 - 8:
			match (k + int(x)) % 3:
				0:
					p.draw_rect(Rect2(x, y - 5, 9, 5), Color("#c8884a"))
					p.draw_rect(Rect2(x + 1, y - 6, 7, 1), Color("#e8b070"))
					x += 10
				1:
					p.draw_circle(Vector2(x + 3, y - 3), 3.0, Color("#b87a3a"))
					p.draw_rect(Rect2(x + 2, y - 5, 2, 1), Color("#e8c890"))
					x += 7
				_:
					p.draw_colored_polygon(PackedVector2Array([Vector2(x, y), Vector2(x + 2, y - 5), Vector2(x + 9, y - 6), Vector2(x + 11, y)]), Color("#d8a060"))
					x += 12
			k += 1
	p.draw_rect(Rect2(-w * 0.5 - 2, -h - 3, w + 4, 3), WOOD)


## 대장간 화덕 (석탄이 빛나고 불티가 튐) + 풀무
static func _forge(p: Prop, t: float) -> void:
	var brick := Color("#5a3a32")
	p.draw_rect(Rect2(-26, -22, 34, 22), brick)
	for row in 5:
		p.draw_rect(Rect2(-26, -22 + row * 4.4, 34, 1), brick.darkened(0.3))
	p.draw_rect(Rect2(-28, -24, 38, 3), brick.lightened(0.15))
	# 화구
	var glow := 0.75 + 0.25 * sin(t * 4.0) + 0.1 * sin(t * 11.0)
	p.draw_rect(Rect2(-20, -16, 20, 9), Color("#1a0806"))
	p.draw_rect(Rect2(-19, -12, 18, 5), Color(1.0, 0.45, 0.15, glow))
	for i in 5:
		p.draw_rect(Rect2(-18 + i * 3.6, -11 + (i % 2), 2, 2), Color(1.0, 0.85, 0.45, glow))
	# 위 굴뚝 갓
	p.draw_colored_polygon(PackedVector2Array([Vector2(-24, -24), Vector2(4, -24), Vector2(-2, -40), Vector2(-18, -40)]), brick.darkened(0.15))
	p.draw_rect(Rect2(-14, -60, 8, 20), brick.darkened(0.1))
	# 불티
	for i in 6:
		var ph := fmod(t * 0.9 + i * 0.17, 1.0)
		var sx := -10.0 + sin(i * 2.3 + t) * 6.0 + ph * 4.0
		p.draw_rect(Rect2(sx, -18 - ph * 30.0, 1, 1), Color(1.0, 0.7, 0.3, 1.0 - ph))
	# 모루 (오른쪽)
	_anvil_at(p, Vector2(20, 0))
	# 꽂힌 쇠막대 (빨갛게 달궈짐)
	p.draw_line(Vector2(-6, -12), Vector2(10, -20), IRON_L, 1.0)
	p.draw_line(Vector2(-6, -12), Vector2(-1, -14), Color(1.0, 0.5, 0.2, glow), 1.0)


static func _anvil(p: Prop) -> void:
	_anvil_at(p, Vector2.ZERO)


static func _anvil_at(p: Prop, o: Vector2) -> void:
	p.draw_rect(Rect2(o + Vector2(-7, -4), Vector2(14, 4)), WOOD_D)
	p.draw_rect(Rect2(o + Vector2(-3, -10), Vector2(6, 6)), IRON)
	p.draw_colored_polygon(PackedVector2Array([o + Vector2(-10, -13), o + Vector2(9, -13), o + Vector2(7, -10), o + Vector2(-6, -10)]), IRON_L)
	p.draw_colored_polygon(PackedVector2Array([o + Vector2(9, -13), o + Vector2(14, -12), o + Vector2(9, -11)]), IRON_L)
	p.draw_rect(Rect2(o + Vector2(-10, -13), Vector2(19, 1)), IRON_L.lightened(0.3))
	# 망치
	p.draw_line(o + Vector2(-4, -14), o + Vector2(2, -19), WOOD, 1.0)
	p.draw_rect(Rect2(o + Vector2(1, -22), Vector2(3, 4)), IRON)


# ─── 기사단 ─────────────────────────────────────────────

## 은사자 깃발 (원점 = 매다는 막대 가운데)
static func _banner(p: Prop, t: float) -> void:
	var w := (p.w if p.w > 1.0 else 2.0) * T * 0.75
	var h := (p.h if p.h > 1.0 else 4.0) * T
	KArt.hanging_banner(p, Vector2.ZERO, w, h, t, _col(p, KArt.CRIMSON), true)


## 깃대 + 펄럭이는 은사자 깃발 (원점 = 바닥)
static func _flag(p: Prop, t: float) -> void:
	var h := (p.h if p.h > 1.0 else 6.0) * T
	var col := _col(p, KArt.CRIMSON)
	p.draw_rect(Rect2(-4, -4, 8, 4), STONE_D)
	p.draw_rect(Rect2(-1, -h, 2, h), IRON_L)
	p.draw_circle(Vector2(0, -h - 2), 2.0, Color("#c8a040"))
	# 깃발 (물결)
	var top := Vector2(1, -h + 2)
	var fw := 30.0
	var fh := 18.0
	var pts := PackedVector2Array()
	var n := 8
	for i in n + 1:
		var k := float(i) / n
		pts.append(top + Vector2(fw * k, sin(t * 4.0 - k * 5.0) * 2.5 * k))
	for i in range(n, -1, -1):
		var k2 := float(i) / n
		pts.append(top + Vector2(fw * k2, fh + sin(t * 4.0 - k2 * 5.0 + 0.4) * 2.5 * k2))
	p.draw_colored_polygon(pts, col)
	var mid := top + Vector2(fw * 0.45, fh * 0.5 + sin(t * 4.0 - 2.2) * 1.2)
	KArt.lion_crest(p, mid, 5.0, KArt.SILVER, col.darkened(0.25))
	p.draw_line(top, top + Vector2(0, fh), col.darkened(0.3), 1.0)


## 무기 거치대 (검·창·방패)
static func _rack(p: Prop) -> void:
	p.draw_rect(Rect2(-18, -30, 36, 3), WOOD)
	p.draw_rect(Rect2(-18, -10, 36, 3), WOOD)
	p.draw_rect(Rect2(-18, -30, 3, 30), WOOD_D)
	p.draw_rect(Rect2(15, -30, 3, 30), WOOD_D)
	# 창 두 자루
	for x in [-12.0, -7.0]:
		p.draw_line(Vector2(x, -2), Vector2(x, -44), WOOD_L, 1.0)
		p.draw_colored_polygon(PackedVector2Array([Vector2(x - 2, -44), Vector2(x, -50), Vector2(x + 2, -44)]), KArt.SILVER)
	# 검 세 자루
	for i in 3:
		var x2 := -1.0 + i * 5.0
		p.draw_line(Vector2(x2, -6), Vector2(x2, -34), KArt.SILVER, 1.0)
		p.draw_line(Vector2(x2 - 2, -33), Vector2(x2 + 2, -33), Color("#c8a040"), 1.0)
		p.draw_line(Vector2(x2, -34), Vector2(x2, -38), Color("#7a2a2a"), 1.0)
	# 방패 (은사자)
	KArt.lion_crest(p, Vector2(11, -18), 5.0, KArt.SILVER, KArt.CRIMSON)


## 훈련용 허수아비 (짚 몸통 + 과녁, 맞으면 흔들리는 듯 조금씩 흔들림)
static func _dummy(p: Prop, t: float) -> void:
	var wob := sin(t * 1.7) * 0.03
	p.draw_rect(Rect2(-6, -3, 12, 3), WOOD_D)
	p.draw_set_transform(Vector2(0, -2), wob, Vector2.ONE)
	p.draw_rect(Rect2(-1.5, -30, 3, 30), WOOD)
	p.draw_rect(Rect2(-12, -24, 24, 3), WOOD) # 팔
	var straw := Color("#c8a85a")
	p.draw_colored_polygon(PackedVector2Array([Vector2(-7, -26), Vector2(7, -26), Vector2(6, -10), Vector2(-6, -10)]), straw)
	for i in 4:
		p.draw_line(Vector2(-6 + i * 4, -25), Vector2(-5 + i * 4, -11), straw.darkened(0.2), 1.0)
	p.draw_rect(Rect2(-7, -19, 14, 2), Color("#7a4a2a"))
	# 머리 (자루) + 과녁 그림
	p.draw_circle(Vector2(0, -32), 5.5, Color("#d8c89a"))
	p.draw_circle(Vector2(0, -32), 3.5, Color("#b8323a"))
	p.draw_circle(Vector2(0, -32), 1.5, Color("#e8dcc0"))
	# 칼자국
	p.draw_line(Vector2(-4, -22), Vector2(2, -16), Color("#6a4a2a"), 1.0)
	p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## 레오니 석상: 받침대 위, 장검을 땅에 짚고 선 기사단장 (망토 자락). 발치엔 시민이 둔 꽃
static func _statue_leonie(p: Prop) -> void:
	var st := Color("#8a8a96")
	var st_d := Color("#5a5a68")
	var st_l := Color("#b8b8c4")
	# 받침대 + 명판
	p.draw_rect(Rect2(-20, -16, 40, 16), STONE_D)
	p.draw_rect(Rect2(-22, -18, 44, 3), STONE_L)
	p.draw_rect(Rect2(-18, -4, 36, 4), STONE_D.darkened(0.2))
	p.draw_rect(Rect2(-9, -12, 18, 6), Color("#a88a4a"))
	p.draw_rect(Rect2(-7, -10, 14, 1), Color("#6a5228"))
	# 꽃다발
	for i in 5:
		var fx := -16.0 + i * 3.0
		p.draw_line(Vector2(fx, 0), Vector2(fx + 2, -5), Color("#3a6a3a"), 1.0)
		p.draw_circle(Vector2(fx + 2, -5), 1.4, [Color("#e84a5a"), Color("#f0e0f0"), Color("#e8c040")][i % 3])
	# 몸 (두 배 크기 석상: 높이 약 56)
	var b := -18.0
	# 망토 (뒤로 흩날림)
	p.draw_colored_polygon(PackedVector2Array([Vector2(-6, b - 46), Vector2(4, b - 46), Vector2(2, b - 4), Vector2(-14, b - 2), Vector2(-18, b - 10)]), st_d)
	# 다리
	p.draw_rect(Rect2(-5, b - 18, 4, 18), st)
	p.draw_rect(Rect2(1, b - 18, 4, 18), st_d.lightened(0.1))
	# 몸통 (흉갑)
	p.draw_colored_polygon(PackedVector2Array([Vector2(-7, b - 44), Vector2(7, b - 44), Vector2(6, b - 20), Vector2(-6, b - 20)]), st)
	p.draw_line(Vector2(-4, b - 42), Vector2(-3, b - 24), st_l, 1.0)
	# 어깨갑
	p.draw_circle(Vector2(-7, b - 42), 3.5, st_l)
	p.draw_circle(Vector2(7, b - 42), 3.5, st)
	# 머리 (짧은 머리 + 땋은 머리)
	p.draw_circle(Vector2(0, b - 50), 5.0, st)
	p.draw_colored_polygon(PackedVector2Array([Vector2(-5, b - 50), Vector2(-4, b - 55), Vector2(3, b - 56), Vector2(6, b - 52), Vector2(5, b - 48), Vector2(-6, b - 46)]), st_d)
	p.draw_line(Vector2(-5, b - 48), Vector2(-7, b - 40), st_d, 1.0)
	# 장검: 두 손으로 자루를 잡고 칼끝을 땅에
	p.draw_line(Vector2(9, b - 28), Vector2(9, b + 0), st_l, 2.0)
	p.draw_line(Vector2(5, b - 28), Vector2(13, b - 28), st, 2.0)
	p.draw_line(Vector2(9, b - 29), Vector2(9, b - 35), st_d, 2.0)
	p.draw_circle(Vector2(9, b - 36), 1.5, st)
	p.draw_line(Vector2(4, b - 38), Vector2(8, b - 32), st, 2.0)
	p.draw_line(Vector2(-3, b - 38), Vector2(8, b - 31), st_d, 2.0)


## 은사자 석상 (받침대 위에 웅크린 사자)
static func _statue_lion(p: Prop) -> void:
	var st := Color("#9a9aa6")
	var st_d := Color("#62626e")
	p.draw_rect(Rect2(-18, -14, 36, 14), STONE_D)
	p.draw_rect(Rect2(-20, -16, 40, 3), STONE_L)
	# 몸
	p.draw_colored_polygon(PackedVector2Array([Vector2(-14, -16), Vector2(-12, -28), Vector2(4, -30), Vector2(10, -24), Vector2(12, -16)]), st)
	# 갈기 + 머리
	p.draw_circle(Vector2(8, -32), 8.0, st_d)
	p.draw_circle(Vector2(10, -31), 5.0, st)
	p.draw_rect(Rect2(13, -31, 4, 4), st)
	p.draw_rect(Rect2(11, -33, 1, 1), Color("#2a2a34"))
	# 앞발 + 꼬리
	p.draw_rect(Rect2(6, -20, 8, 4), st)
	p.draw_line(Vector2(-14, -20), Vector2(-19, -30), st, 2.0)
	p.draw_circle(Vector2(-19, -31), 2.0, st_d)


# ─── 실내 ───────────────────────────────────────────────

## 고딕 스테인드글라스 창 (원점 = 아래 가운데, 색유리가 은은하게 일렁임)
static func _glass(p: Prop, t: float) -> void:
	var w := (p.w if p.w > 1.0 else 3.0) * T
	var h := (p.h if p.h > 1.0 else 6.0) * T
	var frame := KArt.arch_points(0, 4, w + 8, h + 8, true, 10)
	p.draw_colored_polygon(frame, Color("#4a4652"))
	var arch := KArt.arch_points(0, 0, w, h, true, 10)
	p.draw_colored_polygon(arch, Color("#120e18"))
	var glass := [Color("#c8323e"), Color("#e0b048"), Color("#3a5ac8"), Color("#8a3ac0"), Color("#3a9a8a")]
	var rows := int((h - w * 0.4) / 10.0)
	var cols := maxi(int(w / 9.0), 3)
	for r in rows:
		for c in cols:
			var px := -w * 0.5 + 2 + c * (w - 4) / cols
			var py := -h + w * 0.55 + r * 10.0
			if py > -3:
				continue
			var gc: Color = glass[(r * 3 + c * 7 + floori(r / 3.0)) % glass.size()]
			var k := 0.62 + 0.18 * sin(t * 0.6 + r * 0.7 + c * 1.3)
			p.draw_rect(Rect2(px, py, (w - 4) / cols - 1.5, 8.5), Color(gc, k))
	# 위쪽 장미 무늬
	var rc := Vector2(0, -h + w * 0.42)
	for i in 8:
		var a := TAU * i / 8.0
		var gc2: Color = glass[i % glass.size()]
		p.draw_colored_polygon(PackedVector2Array([rc, rc + Vector2(cos(a), sin(a)) * w * 0.3, rc + Vector2(cos(a + TAU / 8.0), sin(a + TAU / 8.0)) * w * 0.3]), Color(gc2, 0.75))
	p.draw_circle(rc, 2.5, Color("#ffe8a0"))
	p.draw_polyline(arch, Color("#2a2632"), 2.0)
	p.draw_line(Vector2(0, -h + w * 0.72), Vector2(0, 0), Color("#2a2632"), 1.0)
	p.draw_rect(Rect2(-w * 0.5 - 6, -2, w + 12, 4), Color("#5a5662"))


## 성당 의자 (w 타일)
static func _pew(p: Prop) -> void:
	var w := (p.w if p.w > 1.0 else 3.0) * T
	var dark := Color("#3a2418")
	p.draw_rect(Rect2(-w * 0.5, -10, w, 3), WOOD)
	p.draw_rect(Rect2(-w * 0.5, -7, w, 2), dark)
	p.draw_rect(Rect2(-w * 0.5 + 2, -22, w - 4, 3), WOOD_L)
	p.draw_rect(Rect2(-w * 0.5 + 2, -20, w - 4, 8), WOOD)
	for x in [-w * 0.5, w * 0.5 - 3]:
		p.draw_rect(Rect2(x, -24, 3, 24), dark)
		p.draw_circle(Vector2(x + 1.5, -24), 2.0, WOOD_L)


## 촛대 (다섯 갈래)
static func _candelabra(p: Prop, t: float) -> void:
	var gold := Color("#b89040")
	p.draw_rect(Rect2(-6, -2, 12, 2), gold.darkened(0.2))
	p.draw_rect(Rect2(-1, -26, 2, 24), gold)
	p.draw_arc(Vector2(0, -26), 8.0, 0, PI, 10, gold, 1.0)
	p.draw_arc(Vector2(0, -26), 4.0, 0, PI, 8, gold, 1.0)
	for i in 5:
		var x := -8.0 + i * 4.0
		var top := -32.0 if i % 2 == 0 else -30.0
		if i == 2:
			top = -36.0
		p.draw_rect(Rect2(x - 1, top, 2, -26 - top + (2 if i in [0, 4] else 0)), Color("#efe4c8"))
		var f := sin(t * 8.0 + i * 1.7) * 0.7
		p.draw_colored_polygon(PackedVector2Array([Vector2(x - 1.5, top), Vector2(x + f, top - 5), Vector2(x + 1.5, top)]), Color(1.0, 0.78, 0.38))
		p.draw_rect(Rect2(x - 0.5, top - 2, 1, 1), Color(1, 1, 0.9))


## 루멘 제단: 흰 돌 + 금빛 해 원반 (빛이 약하게 깜빡임 — 4장 복선 "요즘 빛이 약해졌다")
static func _altar(p: Prop, t: float) -> void:
	var white := Color("#c8c4bc")
	p.draw_rect(Rect2(-20, -18, 40, 18), white.darkened(0.2))
	p.draw_rect(Rect2(-22, -20, 44, 3), white)
	p.draw_rect(Rect2(-14, -14, 28, 10), white.darkened(0.3))
	p.draw_rect(Rect2(-22, -20, 44, 1), Color("#d8b050"))
	# 해 원반 (흔들리는 약한 빛)
	var weak := 0.55 + 0.25 * sin(t * 0.7) - (0.3 if fmod(t, 5.3) < 0.15 else 0.0)
	var sc := Vector2(0, -34)
	for i in 8:
		var a := TAU * i / 8.0 + t * 0.05
		p.draw_line(sc + Vector2(cos(a), sin(a)) * 7.0, sc + Vector2(cos(a), sin(a)) * 12.0, Color(1.0, 0.85, 0.45, weak * 0.7), 1.0)
	p.draw_circle(sc, 6.0, Color("#c8a040"))
	p.draw_circle(sc, 4.0, Color(1.0, 0.9, 0.55, weak))
	p.draw_rect(Rect2(-1, -28, 2, 8), Color("#b89040"))
	# 양쪽 초
	for x in [-16.0, 16.0]:
		p.draw_rect(Rect2(x - 1, -26, 2, 6), Color("#efe4c8"))
		var f := sin(t * 7.0 + x) * 0.6
		p.draw_colored_polygon(PackedVector2Array([Vector2(x - 1.5, -26), Vector2(x + f, -30), Vector2(x + 1.5, -26)]), Color(1.0, 0.78, 0.38))


## 큰 청동 종 (원점 = 매다는 점)
static func _bell(p: Prop) -> void:
	var bronze := Color("#8a6a3a")
	p.draw_rect(Rect2(-14, -2, 28, 4), WOOD_D)
	p.draw_line(Vector2(0, 2), Vector2(0, 8), IRON, 2.0)
	p.draw_colored_polygon(PackedVector2Array([Vector2(-16, 34), Vector2(-12, 16), Vector2(-6, 8), Vector2(6, 8), Vector2(12, 16), Vector2(16, 34)]), bronze)
	p.draw_colored_polygon(PackedVector2Array([Vector2(4, 8), Vector2(6, 8), Vector2(12, 16), Vector2(16, 34), Vector2(10, 34)]), bronze.darkened(0.25))
	p.draw_line(Vector2(-8, 12), Vector2(-12, 30), bronze.lightened(0.3), 1.0)
	p.draw_rect(Rect2(-17, 32, 34, 3), bronze.lightened(0.15))
	p.draw_rect(Rect2(-12, 22, 24, 1), bronze.darkened(0.2))
	p.draw_circle(Vector2(0, 36), 2.5, IRON)


## 매달린 등불 (원점 = 천장)
static func _lantern(p: Prop, t: float) -> void:
	var len := float(p.params.get("len", 2)) * T
	var sway := sin(t * 1.4 + p.position.x * 0.03) * 1.5
	var c := Vector2(sway, len + 8)
	p.draw_line(Vector2.ZERO, c + Vector2(0, -8), IRON, 1.0)
	p.draw_colored_polygon(PackedVector2Array([c + Vector2(-6, -6), c + Vector2(6, -6), c + Vector2(3, -10), c + Vector2(-3, -10)]), IRON)
	var fl := 0.85 + 0.15 * sin(t * 9.0)
	p.draw_rect(Rect2(c.x - 5, c.y - 6, 10, 12), Color(AMBER.darkened(0.2), 0.95))
	p.draw_rect(Rect2(c.x - 3, c.y - 4, 6, 8), Color(1.0, 0.9, 0.6, fl))
	p.draw_rect(Rect2(c.x - 5, c.y - 6, 1, 12), IRON)
	p.draw_rect(Rect2(c.x + 4, c.y - 6, 1, 12), IRON)
	p.draw_rect(Rect2(c.x - 6, c.y + 6, 12, 2), IRON)


## 내리닫이 쇠창살문 (원점 = 아래 가운데, 장식용)
static func _portcullis(p: Prop) -> void:
	var w := (p.w if p.w > 1.0 else 3.0) * T
	var h := (p.h if p.h > 1.0 else 4.0) * T
	p.draw_rect(Rect2(-w * 0.5, -h, w, h), Color(0.02, 0.02, 0.04, 0.6))
	var x := -w * 0.5 + 2
	while x < w * 0.5:
		p.draw_rect(Rect2(x, -h, 2, h), IRON)
		p.draw_rect(Rect2(x, -h, 1, h), IRON_L)
		p.draw_colored_polygon(PackedVector2Array([Vector2(x - 1, 0), Vector2(x + 3, 0), Vector2(x + 1, 4)]), IRON)
		x += 7.0
	for k in int(h / 14.0):
		p.draw_rect(Rect2(-w * 0.5, -h + 6 + k * 14, w, 2), IRON)


# ─── 시계 구역 ──────────────────────────────────────────

## 벽의 큰 톱니 (원점 = 중심). w = 지름(타일), speed, dir
static func _gear(p: Prop, t: float) -> void:
	var r := (p.w if p.w > 1.0 else 3.0) * T * 0.5
	var spd := float(p.params.get("speed", 0.4))
	var dir := float(p.params.get("dir", 1.0))
	var col := _col(p, Color("#7a5a36"))
	KArt.gear(p, Vector2.ZERO, r, t * spd * dir * (24.0 / r), col, col.darkened(0.6))
	p.draw_arc(Vector2.ZERO, r * 0.8, -2.2, -1.0, 8, col.lightened(0.25), 1.0)


## 큰 시계판 (원점 = 중심). hour면 그 시각을 가리키고 멈춤(퍼즐 힌트)
static func _clock(p: Prop, t: float) -> void:
	var r := (p.w if p.w > 1.0 else 3.0) * T * 0.5
	var c := Vector2.ZERO
	KArt.glow(p, c, r * 1.4, Color(AMBER, 0.45), 3)
	p.draw_circle(c, r + 3, Color("#3a2a20"))
	p.draw_circle(c, r, Color("#e0cc9a"))
	p.draw_arc(c, r - 2, 0, TAU, 32, Color("#a88a5a"), 1.0)
	for i in 12:
		var a := TAU * i / 12.0 - PI * 0.5
		var big := i % 3 == 0
		p.draw_line(c + Vector2(cos(a), sin(a)) * (r - (6 if big else 4)), c + Vector2(cos(a), sin(a)) * (r - 2), Color("#3a2a20"), 2.0 if big else 1.0)
	var hour := float(p.params.get("hour", -1))
	var hm: float
	var mm: float
	if hour >= 0.0:
		hm = TAU * hour / 12.0 - PI * 0.5
		mm = -PI * 0.5
	else:
		mm = t * 0.4 - PI * 0.5
		hm = t * 0.4 / 12.0 + 1.2
	p.draw_line(c, c + Vector2(cos(hm), sin(hm)) * r * 0.5, Color("#2a1a10"), 2.0)
	p.draw_line(c, c + Vector2(cos(mm), sin(mm)) * r * 0.78, Color("#2a1a10"), 1.0)
	p.draw_circle(c, 2.0, Color("#c8a040"))


# ─── 하수도 ─────────────────────────────────────────────

## 관 (dir h: 원점 = 왼쪽 끝 가운데, w 길이 / v: 원점 = 아래 끝, h 길이). drip이면 끝에서 청록 물이 떨어짐
static func _pipe(p: Prop, t: float) -> void:
	var dir := String(p.params.get("dir", "h"))
	var pc := Color("#3a4a48")
	var pl := pc.lightened(0.2)
	var drip := bool(p.params.get("drip", true))
	if dir == "v":
		var h := (p.h if p.h > 1.0 else 3.0) * T
		p.draw_rect(Rect2(-6, -h, 12, h), pc)
		p.draw_rect(Rect2(-4, -h, 2, h), pl)
		var y := -h + 8.0
		while y < -4:
			p.draw_rect(Rect2(-8, y, 16, 4), pc.lightened(0.08))
			y += 26.0
	else:
		var w := (p.w if p.w > 1.0 else 3.0) * T
		p.draw_rect(Rect2(0, -6, w, 12), pc)
		p.draw_rect(Rect2(0, -4, w, 2), pl)
		var x := 10.0
		while x < w - 6:
			p.draw_rect(Rect2(x, -8, 4, 16), pc.lightened(0.08))
			p.draw_rect(Rect2(x + 1, -7, 1, 1), pl.lightened(0.2))
			x += 30.0
		# 끝의 입구 + 물
		p.draw_rect(Rect2(w - 2, -9, 6, 18), pc.lightened(0.1))
		p.draw_rect(Rect2(w + 1, -6, 2, 12), Color("#0a1414"))
		if drip:
			for i in 4:
				var ph := fmod(t * 1.1 + i * 0.25, 1.0)
				p.draw_rect(Rect2(w + 2 + ph * 3.0, 6 + ph * ph * 60.0, 1, 3), Color(TEAL, 0.8 * (1.0 - ph)))
			p.draw_rect(Rect2(w - 1, 4, 6, 3), Color(TEAL, 0.5 + 0.2 * sin(t * 3.0)))


## 벽 쇠창살 (뒤에서 청록 빛이 일렁임, 원점 = 아래 가운데)
static func _grate(p: Prop, t: float) -> void:
	var w := (p.w if p.w > 1.0 else 2.0) * T
	var h := (p.h if p.h > 1.0 else 2.0) * T
	var r := Rect2(-w * 0.5, -h, w, h)
	p.draw_rect(r.grow(3.0), Color("#24302e"))
	p.draw_rect(r, Color("#041010"))
	for i in 4:
		var yy := -h + h * (0.3 + i * 0.18) + sin(t * 1.5 + i) * 2.0
		p.draw_rect(Rect2(-w * 0.5, yy, w, h * 0.12), Color(TEAL, 0.12 + 0.06 * sin(t * 2.0 + i)))
	var x := -w * 0.5 + 3
	while x < w * 0.5 - 1:
		p.draw_rect(Rect2(x, -h, 2, h), Color("#3a4a48"))
		x += 6.0
	p.draw_rect(Rect2(-w * 0.5, -h * 0.5, w, 2), Color("#3a4a48"))
	for k in 4:
		p.draw_rect(Rect2(r.position + Vector2(-2 + (k % 2) * (w + 2), -2 + floorf(k / 2.0) * (h + 2)), Vector2(2, 2)), Color("#5a6a68"))


## 수문 밸브 바퀴 (원점 = 중심)
static func _valve(p: Prop) -> void:
	var rust := Color("#8a4a2a")
	p.draw_rect(Rect2(-4, -4, 8, 14), Color("#3a4a48"))
	p.draw_arc(Vector2.ZERO, 9.0, 0, TAU, 20, rust, 2.0)
	for k in 4:
		var a := TAU * k / 4.0 + 0.3
		p.draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * 9.0, rust, 2.0)
	p.draw_circle(Vector2.ZERO, 2.5, rust.lightened(0.2))
	p.draw_arc(Vector2.ZERO, 9.0, -2.4, -1.6, 4, rust.lightened(0.35), 1.0)


# ─── 별·운석 ────────────────────────────────────────────

## 별 수정 무리 (맥동)
static func _crystal(p: Prop, t: float) -> void:
	var h := (p.h if p.h > 1.0 else 2.0) * T
	var col := _col(p, VIOLET)
	var k := 0.75 + 0.25 * sin(t * 1.6 + p.position.x * 0.05)
	KArt.crystal(p, Vector2.ZERO, h, col, k, int(p.position.x) % 5)
	KArt.twinkles(p, Rect2(-h * 0.5, -h * 1.1, h, h), 4, t, Color(1, 0.95, 1.0, 0.8), int(p.position.x))


## 운석 조각: 검은 바위 + 빛나는 보라 균열
static func _meteor(p: Prop, t: float) -> void:
	var w := (p.w if p.w > 1.0 else 3.0) * T
	var h := (p.h if p.h > 1.0 else 2.0) * T
	var rock := Color("#26222e")
	var pts := PackedVector2Array([Vector2(-w * 0.5, 0), Vector2(-w * 0.45, -h * 0.55), Vector2(-w * 0.2, -h * 0.95), Vector2(w * 0.15, -h),
		Vector2(w * 0.42, -h * 0.7), Vector2(w * 0.5, -h * 0.2), Vector2(w * 0.4, 0)])
	var k := 0.7 + 0.3 * sin(t * 1.3)
	KArt.glow(p, Vector2(0, -h * 0.5), w * 0.9, Color(VIOLET, 0.45 * k), 4)
	p.draw_colored_polygon(pts, rock)
	p.draw_colored_polygon(PackedVector2Array([Vector2(-w * 0.2, -h * 0.95), Vector2(w * 0.15, -h), Vector2(w * 0.42, -h * 0.7), Vector2(0, -h * 0.6)]), rock.lightened(0.1))
	var crack := Color(VIOLET.lerp(Color.WHITE, 0.2), k)
	p.draw_polyline(PackedVector2Array([Vector2(-w * 0.35, -h * 0.3), Vector2(-w * 0.1, -h * 0.45), Vector2(0, -h * 0.8), Vector2(w * 0.1, -h * 0.55), Vector2(w * 0.35, -h * 0.4)]), crack, 1.0)
	p.draw_line(Vector2(-w * 0.1, -h * 0.45), Vector2(-w * 0.15, -h * 0.08), crack, 1.0)
	p.draw_line(Vector2(w * 0.1, -h * 0.55), Vector2(w * 0.25, -h * 0.1), crack, 1.0)
	p.draw_circle(Vector2(0, -h * 0.6), 2.0, Color(1, 0.95, 1.0, k))
	KArt.twinkles(p, Rect2(-w * 0.6, -h * 1.4, w * 1.2, h), 5, t, Color(VIOLET.lightened(0.4), 0.8), int(p.position.x))


## 무너진 돌무더기 (w 타일)
static func _rubble(p: Prop) -> void:
	var w := (p.w if p.w > 1.0 else 3.0) * T
	var rng := RandomNumberGenerator.new()
	rng.seed = int(p.position.x * 13.0 + p.position.y)
	var x := -w * 0.5
	while x < w * 0.5:
		var s := rng.randf_range(4, 10)
		var c := STONE_D.lerp(STONE, rng.randf())
		p.draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + s * 0.2, -s * rng.randf_range(0.6, 1.1)), Vector2(x + s * 0.9, -s * rng.randf_range(0.5, 0.9)), Vector2(x + s, 0)]), c)
		p.draw_line(Vector2(x + s * 0.2, -s * 0.6), Vector2(x + s * 0.8, -s * 0.5), c.lightened(0.2), 1.0)
		x += s * 0.8
	# 부러진 들보
	p.draw_line(Vector2(-w * 0.3, -2), Vector2(w * 0.1, -14), WOOD_D, 3.0)


## 별 신도의 바닥 마법진 (보라 오각별, 천천히 돈다)
static func _cult_circle(p: Prop, t: float) -> void:
	var r := (p.w if p.w > 1.0 else 4.0) * T * 0.5
	var c := Vector2(0, -2)
	var col := Color(VIOLET, 0.55 + 0.15 * sin(t * 2.0))
	p.draw_set_transform(c, 0.0, Vector2(1.0, 0.28))
	p.draw_arc(Vector2.ZERO, r, 0, TAU, 40, col, 2.0)
	p.draw_arc(Vector2.ZERO, r * 0.82, 0, TAU, 36, Color(col, col.a * 0.6), 1.0)
	var pts := PackedVector2Array()
	for i in 5:
		var a := t * 0.25 + TAU * i * 2.0 / 5.0 - PI * 0.5
		pts.append(Vector2(cos(a), sin(a)) * r * 0.8)
	pts.append(pts[0])
	p.draw_polyline(pts, col, 1.5)
	for i in 8:
		var a2 := -t * 0.4 + TAU * i / 8.0
		p.draw_circle(Vector2(cos(a2), sin(a2)) * r * 0.91, 2.0, Color(1.0, 0.9, 1.0, 0.7))
	p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in 5:
		var ph := fmod(t * 0.5 + i * 0.2, 1.0)
		var px := cos(i * 2.4) * r * 0.6
		p.draw_rect(Rect2(px, -2 - ph * 26.0, 1, 2), Color(VIOLET.lightened(0.3), 0.8 * (1.0 - ph)))
