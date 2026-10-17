extends RefCounted
## 5장 소품 그림 (Prop이 아래 PROPS 표로 kind를 찾아 draw(p, kind)를 부름). 모두 "st_" 접두사 (다른 장 소품과 이름이 겹치지 않게).
## 원점은 바닥(발밑) 기준, 매달린 것(별 등롱·등불 줄·화환)은 천장 기준. 공통 키: w, h(타일), flip, front, len(매단 줄 길이 타일).
##
## 별의 탑    st_star_lantern(len) · st_const_pedestal · st_memory_crystal(lit) · st_orrery · st_telescope · st_star_chart(w,h) · st_star_shard · st_photo_frame
## 축제       st_festival_stall(style: potion·food·star·mask·kingdom·elf·temple) · st_garland(w) · st_lantern_string(w, sag) · st_festival_banner(h) · st_balloon_cluster · st_flower_arch · st_tea_table
## 침공·폐허  st_rubble(w) · st_burning_beam(w) · st_broken_bell · st_cracked_statue · st_fire(size) · st_broken_pillar(h) · st_white_growth · st_fallen_banner · st_comm_crystal(on) · st_crater(w) · st_ash_tree
## 에필로그   st_scaffold(w,h) · st_fox_altar
## 2단계      st_star_door(open_if, col: k·e·tp·s·tower) 별의 문(문 개체 style="st"와 겹쳐 둠) · st_flip_sigil 중력 반전 문양
## 공통 추가  vflip(위아래 뒤집기 — 뒤집힌 층) · st_const_pedestal(lit_if: 별의 열쇠가 꽂힘) · st_memory_crystal(seen: 본 기억이면 밝음)

const T := 16.0
const FIRE := Color("#ff6a3a")
const FIRE_HOT := Color("#ffc870")


## 소품 표 (Prop이 합침): kind → {anim, glow, split} — 뜻은 world/entities/base_props.gd 머리 참고.
## DEFAULTS는 이 장의 모든 kind에 깔리는 값: vflip = 방 데이터의 vflip 키(위아래 뒤집기 — 뒤집힌 층)를 받는다.
const DEFAULTS := {"vflip": true}
const PROPS := {
	"st_star_lantern": {"anim": true, "glow": &"_glow_star_lantern"},
	"st_const_pedestal": {"anim": true, "glow": [Vector2(0, -30), 50.0, StArt.STAR]},
	"st_memory_crystal": {"anim": true, "glow": &"_glow_memory_crystal"},
	"st_orrery": {"anim": true, "glow": [Vector2(0, -24), 30.0, StArt.STAR_GOLD]},
	"st_telescope": {},
	"st_star_chart": {"anim": true},
	"st_star_shard": {"anim": true, "glow": [Vector2(0, -8), 40.0, StArt.STAR]},
	"st_photo_frame": {"anim": true},
	"st_festival_stall": {"anim": true, "glow": [Vector2(0, -26), 48.0, Color(1.0, 0.75, 0.45)]},
	"st_garland": {"anim": true},
	"st_lantern_string": {"anim": true},
	"st_festival_banner": {"anim": true},
	"st_balloon_cluster": {"anim": true},
	"st_flower_arch": {"anim": true},
	"st_tea_table": {"anim": true},
	"st_rubble": {},
	"st_burning_beam": {"anim": true, "glow": &"_glow_burning_beam"},
	"st_broken_bell": {},
	"st_cracked_statue": {},
	"st_fire": {"anim": true, "glow": &"_glow_fire"},
	"st_broken_pillar": {},
	"st_white_growth": {"anim": true},
	"st_fallen_banner": {"anim": true},
	"st_comm_crystal": {"anim": true, "glow": [Vector2(0, -26), 36.0, Color(0.6, 0.85, 1.0)]},
	"st_crater": {"anim": true},
	"st_ash_tree": {},
	"st_scaffold": {},
	"st_fox_altar": {"anim": true, "glow": [Vector2(0, -22), 46.0, StArt.FOX_BLUE]},
	"st_star_door": {"anim": true, "glow": &"_glow_star_door"},
	"st_flip_sigil": {"anim": true, "glow": [Vector2(0, -4), 40.0, StArt.STAR]},
}


# ─── 크기·값에 따라 달라지는 빛 (PROPS의 glow = &"함수") ──────

static func _glow_star_lantern(p: Prop) -> Array:
	return [Vector2(0, float(p.params.get("len", 3)) * T + 8), 56.0, StArt.STAR]


static func _glow_memory_crystal(p: Prop) -> Array:
	return [Vector2(0, -22), 44.0 if bool(p.params.get("lit", false)) else 28.0, Color(0.8, 0.7, 1.0)]


static func _glow_burning_beam(p: Prop) -> Array:
	return [Vector2(0, -14), 22.0 * maxf(p.w, 2.0), FIRE]


static func _glow_fire(p: Prop) -> Array:
	return [Vector2(0, -16), 60.0 * float(p.params.get("size", 1.0)), FIRE]


static func _glow_star_door(p: Prop) -> Array:
	return [Vector2(0, -26), 52.0, _door_col(String(p.params.get("col", "tower")))]


## 그렸으면 true
static func draw(p: Prop, kind: String) -> bool:
	var t := p.time()
	match kind:
		"st_star_lantern": _star_lantern(p, t)
		"st_const_pedestal": _const_pedestal(p, t)
		"st_memory_crystal": _memory_crystal(p, t)
		"st_orrery": _orrery(p, t)
		"st_telescope": _telescope(p)
		"st_star_chart": _star_chart(p, t)
		"st_star_shard": _star_shard(p, t)
		"st_photo_frame": _photo_frame(p, t)
		"st_festival_stall": _stall(p, t)
		"st_garland": _garland(p, t)
		"st_lantern_string": _lantern_string(p, t)
		"st_festival_banner": _fest_banner(p, t)
		"st_balloon_cluster": _balloons(p, t)
		"st_flower_arch": _flower_arch(p, t)
		"st_tea_table": _tea_table(p, t)
		"st_rubble": _rubble(p)
		"st_burning_beam": _burning_beam(p, t)
		"st_broken_bell": _broken_bell(p)
		"st_cracked_statue": _cracked_statue(p)
		"st_fire": _fire(p, Vector2.ZERO, float(p.params.get("size", 1.0)), t)
		"st_broken_pillar": _broken_pillar(p)
		"st_white_growth": _white_growth(p, t)
		"st_fallen_banner": _fallen_banner(p, t)
		"st_comm_crystal": _comm_crystal(p, t)
		"st_crater": _crater(p, t)
		"st_ash_tree": _ash_tree(p, t)
		"st_scaffold": _scaffold(p)
		"st_fox_altar": _fox_altar(p, t)
		"st_star_door": _star_door(p, t)
		"st_flip_sigil": _flip_sigil(p, t)
	return true


# ─── 공용 ───────────────────────────────────────────────

static func _flame(p: Prop, at: Vector2, h: float, t: float, seed: float, col := FIRE) -> void:
	var f := sin(t * 9.0 + seed) * h * 0.12
	p.draw_colored_polygon(PackedVector2Array([at + Vector2(-h * 0.35, 0), at + Vector2(-h * 0.2, -h * 0.55), at + Vector2(f, -h), at + Vector2(h * 0.22, -h * 0.5), at + Vector2(h * 0.35, 0)]), col)
	p.draw_colored_polygon(PackedVector2Array([at + Vector2(-h * 0.17, 0), at + Vector2(f * 0.6, -h * 0.6), at + Vector2(h * 0.17, 0)]), FIRE_HOT)


static func _fire(p: Prop, at: Vector2, size: float, t: float) -> void:
	var s := 14.0 * size
	_flame(p, at + Vector2(-s * 0.5, 0), s * 0.9, t, 1.0)
	_flame(p, at + Vector2(s * 0.45, 0), s * 0.8, t, 2.3)
	_flame(p, at, s * 1.3, t, 0.0)
	# 튀는 불씨
	for i in 3:
		var k := fmod(t * 0.8 + i * 0.33, 1.0)
		var e := at + Vector2(sin(i * 2.1 + t) * s * 0.5, -s * 0.8 - k * s * 2.2)
		p.draw_rect(Rect2(e, Vector2(1, 1)), Color(FIRE_HOT, 1.0 - k))
	p.draw_rect(Rect2(at.x - s * 0.7, at.y - 2, s * 1.4, 2), Color("#2a1a14"))


# ─── 별의 탑 ────────────────────────────────────────────

static func _star_lantern(p: Prop, t: float) -> void:
	var len := float(p.params.get("len", 3)) * T
	var sway := sin(t * 1.2) * 0.06
	var tip := Vector2(sin(sway) * len, cos(sway) * len)
	p.draw_line(Vector2.ZERO, tip, Color("#6a6040"), 1.0)
	var c := tip + Vector2(0, 9)
	# 별 모양 틀(남색) 안에 따뜻한 별빛
	StArt.star(p, c, 10.0, Color("#1a1e48"), -PI * 0.5 + sway)
	StArt.star(p, c, 8.0, Color(StArt.STAR_GOLD, 0.95), -PI * 0.5 + sway)
	StArt.star(p, c, 4.5, StArt.STAR_CORE, -PI * 0.5 + sway)
	p.draw_rect(Rect2(tip + Vector2(-2, -1), Vector2(4, 2)), Color("#c8a860"))
	var tw := StArt.twinkle(t, p.anchor.x)
	StArt.sparkle(p, c + Vector2(6, -6), 3.0, StArt.STAR, tw)


static func _const_pedestal(p: Prop, t: float) -> void:
	var stone := Color("#2c3470")
	var stone_d := Color("#181e48")
	var gold := Color("#d8bc6a")
	# 받침대
	p.draw_rect(Rect2(-12, -4, 24, 4), stone_d)
	p.draw_rect(Rect2(-9, -20, 18, 16), stone)
	p.draw_rect(Rect2(-9, -20, 3, 16), stone.lightened(0.12))
	p.draw_rect(Rect2(-11, -23, 22, 3), gold.darkened(0.2))
	for i in 3:
		p.draw_rect(Rect2(-5 + i * 4, -15 + (i % 2) * 4, 1, 1), StArt.STAR)
	# 떠 있는 구슬 + 그 둘레를 도는 별자리 고리
	var oc := Vector2(0, -34 + sin(t * 1.5) * 2.0)
	StArt.glow(p, oc, 14.0, StArt.STAR, 0.3)
	p.draw_circle(oc, 5.0, Color("#3a4aa8"))
	p.draw_circle(oc + Vector2(-1.5, -1.5), 3.0, Color("#8a9aff"))
	var pts: Array = []
	for i in 6:
		var a := t * 0.6 + TAU * i / 6.0
		pts.append(oc + Vector2(cos(a) * 13.0, sin(a) * 4.0))
	pts.append(pts[0])
	StArt.constellation(p, pts, StArt.STAR, 0.8, 1.0)
	# 별의 열쇠가 꽂힘 (lit_if 플래그)
	var lit_if := String(p.params.get("lit_if", ""))
	if lit_if != "" and RoomData.cond_ok(lit_if):
		var kc := oc + Vector2(0, -12)
		StArt.glow(p, kc, 18.0, StArt.STAR, 0.4 + 0.1 * sin(t * 3.0))
		StArt.star(p, kc, 7.0, StArt.STAR_GOLD, -PI * 0.5 + t * 0.4)
		StArt.star(p, kc, 3.5, StArt.STAR_CORE, -PI * 0.5 + t * 0.4)


static func _memory_crystal(p: Prop, t: float) -> void:
	var lit := bool(p.params.get("lit", false)) or GameState.has_flag(String(p.params.get("seen", "")))
	var c := Vector2(0, -22 + sin(t * 1.3) * 2.0)
	var col := Color(0.78, 0.68, 1.0) if lit else Color(0.5, 0.45, 0.75)
	var shards := [[Vector2(0, 0), 11.0, 0.0], [Vector2(-6, 4), 7.0, -0.4], [Vector2(6, 5), 6.0, 0.45]]
	for s in shards:
		var o: Vector2 = s[0]
		var h: float = s[1]
		var r: float = s[2]
		var pts := PackedVector2Array([Vector2(0, -h), Vector2(h * 0.38, 0), Vector2(0, h * 0.7), Vector2(-h * 0.38, 0)])
		for i in pts.size():
			pts[i] = c + o + pts[i].rotated(r)
		p.draw_colored_polygon(pts, Color(col, 0.75))
		p.draw_line(pts[0], pts[2], Color(1, 1, 1, 0.5), 1.0)
	# 안쪽에 비치는 기억 (작은 두 소녀의 실루엣이 깜빡)
	var k := 0.3 + 0.4 * StArt.twinkle(t, 3.0, 0.4)
	if lit:
		p.draw_rect(Rect2(c + Vector2(-3, -3), Vector2(2, 5)), Color(1, 0.95, 0.8, k))
		p.draw_rect(Rect2(c + Vector2(1, -2), Vector2(2, 4)), Color(1, 0.95, 0.8, k))
	StArt.sparkle(p, c + Vector2(4, -8), 3.0, Color(1, 1, 1), StArt.twinkle(t, 7.0))
	# 받침 바위
	p.draw_colored_polygon(PackedVector2Array([Vector2(-10, 0), Vector2(-6, -6), Vector2(5, -7), Vector2(10, 0)]), Color("#22264e"))


static func _orrery(p: Prop, t: float) -> void:
	var gold := Color("#c8a860")
	p.draw_rect(Rect2(-8, -3, 16, 3), Color("#4a3a2a"))
	p.draw_line(Vector2(0, -3), Vector2(0, -22), gold, 1.0)
	var c := Vector2(0, -24)
	StArt.star(p, c, 3.5, StArt.STAR, t)
	for r in 3:
		var rx := 7.0 + r * 5.0
		p.draw_arc(c, rx, 0, TAU, 20, Color(gold, 0.6), 1.0)
		var a := t * (1.2 - r * 0.35) + r * 2.0
		var pp := c + Vector2(cos(a) * rx, sin(a) * rx * 0.35)
		p.draw_circle(pp, 1.5 + r * 0.5, [Color("#8a9aff"), Color("#ff9a6a"), Color("#9affc8")][r])


static func _telescope(p: Prop) -> void:
	var brass := Color("#b89a5a")
	var wood := Color("#4a3426")
	# 세 다리
	p.draw_line(Vector2(0, -16), Vector2(-8, 0), wood, 2.0)
	p.draw_line(Vector2(0, -16), Vector2(8, 0), wood, 2.0)
	p.draw_line(Vector2(0, -16), Vector2(1, 0), wood, 2.0)
	# 경통 (하늘로)
	var a := Vector2(-8, -12)
	var b := Vector2(12, -34)
	var n := (b - a).normalized().orthogonal()
	p.draw_colored_polygon(PackedVector2Array([a + n * 2.0, b + n * 3.5, b - n * 3.5, a - n * 2.0]), brass)
	p.draw_line(a.lerp(b, 0.4) + n * 3.0, a.lerp(b, 0.4) - n * 3.0, brass.darkened(0.3), 1.0)
	p.draw_circle(b, 3.5, Color("#2a2a40"))
	p.draw_circle(b + Vector2(-1, -1), 1.0, Color(0.8, 0.9, 1.0))


static func _star_chart(p: Prop, t: float) -> void:
	var ww := maxf(p.w, 2.0) * T
	var hh := maxf(p.h, 2.0) * T
	var r := Rect2(-ww * 0.5, -hh, ww, hh)
	p.draw_rect(r.grow(2), Color("#4a3426"))
	p.draw_rect(r, Color("#1c2050"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var pts: Array = []
	for i in 6:
		pts.append(Vector2(r.position.x + 4 + rng.randf() * (ww - 8), r.position.y + 4 + rng.randf() * (hh - 8)))
	StArt.constellation(p, pts, Color("#e8cf86"), 0.7 + 0.2 * sin(t), 1.0)
	p.draw_arc(r.get_center(), minf(ww, hh) * 0.4, 0, TAU, 24, Color("#e8cf86", 0.35), 1.0)


static func _star_shard(p: Prop, t: float) -> void:
	var k := 0.7 + 0.3 * sin(t * 2.0)
	p.draw_colored_polygon(PackedVector2Array([Vector2(-10, 0), Vector2(-6, -4), Vector2(6, -5), Vector2(11, 0)]), Color("#3a3446"))
	for s in [[Vector2(-2, 0), 13.0, -0.2], [Vector2(4, 0), 8.0, 0.4], [Vector2(-6, 0), 6.0, -0.6]]:
		var o: Vector2 = s[0]
		var h: float = s[1]
		var r: float = s[2]
		var pts := PackedVector2Array([Vector2(-2.5, 0), Vector2(0, -h), Vector2(2.5, 0)])
		for i in pts.size():
			pts[i] = o + pts[i].rotated(r)
		p.draw_colored_polygon(pts, Color(StArt.STAR, k))
	StArt.sparkle(p, Vector2(-3, -12), 3.0, StArt.STAR_CORE, StArt.twinkle(t, 2.0))


## 창립자와 두 소녀(아스트리드·리라)의 오래된 사진. 액자 받침대
static func _photo_frame(p: Prop, t: float) -> void:
	var fr := Rect2(-9, -22, 18, 14)
	p.draw_line(Vector2(0, -8), Vector2(-4, 0), Color("#4a3426"), 1.0)
	p.draw_rect(fr.grow(2), Color("#8a6a3a"))
	p.draw_rect(fr, Color("#c8b898"))
	# 세 사람 (흐린 세피아)
	var sep := Color("#5a4a3a")
	p.draw_rect(Rect2(-6, -16, 3, 7), sep) # 창립자
	p.draw_circle(Vector2(-4.5, -17), 1.5, sep)
	p.draw_colored_polygon(PackedVector2Array([Vector2(-7, -18), Vector2(-2, -18), Vector2(-4.5, -22)]), sep)
	p.draw_rect(Rect2(-1, -14, 2, 5), Color("#7a6a5a")) # 꼬마 아스트리드
	p.draw_circle(Vector2(0, -15), 1.2, Color("#7a6a5a"))
	p.draw_rect(Rect2(3, -14, 2, 5), Color("#6a5a7a")) # 꼬마 리라 (긴 머리)
	p.draw_circle(Vector2(4, -15), 1.2, Color("#6a5a7a"))
	p.draw_line(Vector2(5, -15), Vector2(6, -9), Color("#d8d8e8"), 1.0)
	p.draw_rect(Rect2(fr.position + Vector2(fr.size.x - 4, 1), Vector2(2, 2)), Color(1, 1, 1, 0.3 + 0.2 * sin(t)))


# ─── 축제 ───────────────────────────────────────────────

static func _stall(p: Prop, t: float) -> void:
	var style := String(p.params.get("style", "potion"))
	var stripe: Color = {"potion": Color("#4aa858"), "food": Color("#d8483a"), "star": Color("#3a4aa8"), "mask": Color("#a84aa8"),
		"kingdom": Color("#8a2a3a"), "elf": Color("#3a7a4a"), "temple": Color("#c8a040")}.get(style, Color("#d8483a"))
	var wood := Color("#5a3e2e")
	# 기둥·판매대
	p.draw_rect(Rect2(-22, -40, 3, 40), wood)
	p.draw_rect(Rect2(19, -40, 3, 40), wood)
	p.draw_rect(Rect2(-24, -14, 48, 14), wood.darkened(0.1))
	p.draw_rect(Rect2(-24, -14, 48, 2), wood.lightened(0.25))
	p.draw_rect(Rect2(-20, -10, 40, 8), Color("#3a2a20"))
	# 줄무늬 차양 (살짝 펄럭)
	var flap := sin(t * 2.0) * 1.0
	for i in 8:
		var x := -26.0 + i * 6.5
		var col := stripe if i % 2 == 0 else Color("#f4ecd8")
		p.draw_colored_polygon(PackedVector2Array([Vector2(x, -48), Vector2(x + 6.5, -48), Vector2(x + 7, -38 + flap), Vector2(x + 3.5, -35 + flap), Vector2(x, -38 + flap)]), col)
	p.draw_rect(Rect2(-27, -50, 54, 3), stripe.darkened(0.3))
	# 상품
	match style:
		"potion":
			for i in 5:
				var c: Color = [Color("#ff6a8a"), Color("#6ad0ff"), Color("#9aff6a"), Color("#ffd27a"), Color("#c89aff")][i]
				p.draw_rect(Rect2(-17 + i * 7, -21, 4, 6), Color(c, 0.9))
				p.draw_rect(Rect2(-16 + i * 7, -23, 2, 2), Color("#e8dcc0"))
		"food":
			for i in 3:
				p.draw_circle(Vector2(-12 + i * 12, -17), 4.0, Color("#c88a4a"))
				p.draw_circle(Vector2(-12 + i * 12, -18), 2.5, Color("#e8b06a"))
			p.draw_line(Vector2(10, -16), Vector2(12, -30 - 3.0 * sin(t * 2.0)), Color(1, 1, 1, 0.25), 2.0)
		"star":
			for i in 4:
				StArt.star(p, Vector2(-14 + i * 9, -19), 3.5, StArt.STAR_GOLD, -PI * 0.5 + t * 0.5 + i)
		"kingdom":
			# 제국 소시지 꼬치와 방패 문장
			for i in 4:
				p.draw_line(Vector2(-15 + i * 7, -15), Vector2(-15 + i * 7, -27), Color("#c8b090"), 1.0)
				p.draw_rect(Rect2(-17 + i * 7, -26, 4, 8), Color("#a85a3a"))
			p.draw_rect(Rect2(10, -24, 7, 8), Color("#d8bc6a"))
			p.draw_rect(Rect2(12, -22, 3, 4), Color("#8a2a3a"))
		"elf":
			# 꿀빵과 꽃 화분
			for i in 3:
				p.draw_circle(Vector2(-13 + i * 9, -17), 3.5, Color("#e8b860"))
				p.draw_rect(Rect2(-14 + i * 9, -19, 2, 1), Color("#ffe8a0"))
			p.draw_circle(Vector2(14, -20), 3.0, Color("#ff9ac8"))
			p.draw_circle(Vector2(12, -18), 2.0, Color("#fff0a0"))
		"temple":
			# 둥근 성찬 빵과 작은 종
			for i in 3:
				p.draw_circle(Vector2(-12 + i * 10, -17), 4.0, Color("#f4e4c0"))
				p.draw_line(Vector2(-14 + i * 10, -17), Vector2(-10 + i * 10, -17), Color("#c8a060"), 1.0)
			p.draw_colored_polygon(PackedVector2Array([Vector2(10, -16), Vector2(12, -24), Vector2(16, -24), Vector2(18, -16)]), Color("#d8bc6a"))
		_:
			for i in 3:
				p.draw_circle(Vector2(-12 + i * 12, -19), 4.0, Color("#f4ecd8"))
				p.draw_rect(Rect2(-14 + i * 12, -20, 1, 1), Color("#2a1a2a"))
				p.draw_rect(Rect2(-11 + i * 12, -20, 1, 1), Color("#2a1a2a"))
	# 등불 하나
	var lp := Vector2(16, -34 + sin(t * 1.4) * 1.0)
	p.draw_rect(Rect2(lp - Vector2(2, 3), Vector2(4, 6)), Color("#ffb05a"))


static func _garland(p: Prop, t: float) -> void:
	var ww := maxf(p.w, 2.0) * T
	var pts := PackedVector2Array()
	for k in 17:
		var u := float(k) / 16.0
		pts.append(Vector2(u * ww, sin(u * PI) * 12.0 + sin(t * 1.3 + u * 4.0) * 1.0))
	p.draw_polyline(pts, Color("#3a2a20"), 1.0)
	var cols := [Color("#ff7a6a"), Color("#ffd27a"), Color("#6ad0a8"), Color("#8a9aff"), Color("#f4ecd8")]
	for k in range(1, 16):
		var a: Vector2 = pts[k]
		var col: Color = cols[k % cols.size()]
		var sw := sin(t * 2.0 + k) * 1.0
		p.draw_colored_polygon(PackedVector2Array([a + Vector2(-3, 0), a + Vector2(3, 0), a + Vector2(sw, 7)]), col)


static func _lantern_string(p: Prop, t: float) -> void:
	var ww := maxf(p.w, 2.0) * T
	var sag := float(p.params.get("sag", 2)) * T * 0.5
	var pts := PackedVector2Array()
	for k in 17:
		var u := float(k) / 16.0
		pts.append(Vector2(u * ww, sin(u * PI) * sag))
	p.draw_polyline(pts, Color("#2a2028"), 1.0)
	var cols := [Color("#ff9a5a"), Color("#ffd27a"), Color("#ff6a7a"), Color("#8ad0ff")]
	for k in range(1, 16, 2):
		var a: Vector2 = pts[k]
		var c: Color = cols[k / 2 % cols.size()]
		var sw := sin(t * 1.6 + k) * 1.0
		var lc := a + Vector2(sw, 6)
		p.draw_line(a, lc + Vector2(0, -4), Color("#2a2028"), 1.0)
		p.draw_circle(lc, 7.0, Color(c, 0.12))
		p.draw_rect(Rect2(lc - Vector2(3, 4), Vector2(6, 8)), c)
		p.draw_rect(Rect2(lc - Vector2(2, 3), Vector2(4, 6)), c.lightened(0.35))
		p.draw_rect(Rect2(lc - Vector2(3, 5), Vector2(6, 1)), Color("#3a2a20"))


static func _fest_banner(p: Prop, t: float) -> void:
	var hh := maxf(p.h, 3.0) * T
	p.draw_rect(Rect2(-1, -hh, 3, hh), Color("#6a5a4a"))
	StArt.star(p, Vector2(0.5, -hh - 2), 3.0, StArt.STAR_GOLD)
	var wav := sin(t * 2.2) * 1.5
	var top := -hh + 4
	var pts := PackedVector2Array([Vector2(2, top), Vector2(18, top + wav), Vector2(18, top + 28 + wav), Vector2(10, top + 23 + wav * 0.5), Vector2(2, top + 28)])
	p.draw_colored_polygon(pts, Color("#3a2a6a"))
	p.draw_rect(Rect2(2, top + 2, 16, 2), Color("#c8a040"))
	# 학교 문장: 별을 품은 마녀 모자
	var cc := Vector2(10, top + 14 + wav * 0.6)
	p.draw_colored_polygon(PackedVector2Array([cc + Vector2(-5, 3), cc + Vector2(5, 3), cc + Vector2(1, -6)]), Color("#e8d8a0"))
	StArt.star(p, cc + Vector2(0, 1), 1.6, Color("#3a2a6a"))


static func _balloons(p: Prop, t: float) -> void:
	p.draw_rect(Rect2(-3, -4, 6, 4), Color("#6a5a4a"))
	var cols := [Color("#ff7a8a"), Color("#8ad0ff"), Color("#ffd27a"), Color("#a8ff8a")]
	for i in 4:
		var bx := -9.0 + i * 6.0 + sin(t * 1.3 + i) * 2.0
		var by := -36.0 - (i % 2) * 8.0 + sin(t * 1.7 + i * 2.0) * 1.5
		p.draw_line(Vector2(0, -4), Vector2(bx, by + 6), Color(1, 1, 1, 0.4), 1.0)
		p.draw_circle(Vector2(bx, by), 5.5, cols[i])
		p.draw_rect(Rect2(bx - 2, by - 3, 2, 2), Color(1, 1, 1, 0.6))


static func _flower_arch(p: Prop, t: float) -> void:
	var w := 40.0
	var h := 52.0
	var wood := Color("#5a4632")
	p.draw_rect(Rect2(-w * 0.5, -h * 0.7, 3, h * 0.7), wood)
	p.draw_rect(Rect2(w * 0.5 - 3, -h * 0.7, 3, h * 0.7), wood)
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		pts.append(Vector2(cos(a) * w * 0.5, -h * 0.7 + sin(a) * h * 0.3))
	p.draw_polyline(pts, wood, 3.0)
	var cols := [Color("#ff9ab0"), Color("#fff0a0"), Color("#ffffff"), Color("#c8a0ff")]
	for i in pts.size():
		var q: Vector2 = pts[i] + Vector2(sin(t + i) * 0.5, 0)
		p.draw_circle(q, 3.0, Color("#3a6a3a"))
		p.draw_circle(q + Vector2(1, -1), 2.0, cols[i % cols.size()])
	for side: float in [-1.0, 1.0]:
		for j in 4:
			p.draw_circle(Vector2(side * (w * 0.5 - 1), -h * 0.6 + j * 8.0), 2.0, cols[(j + 1) % cols.size()])


static func _tea_table(p: Prop, t: float) -> void:
	var wood := Color("#6a4a32")
	p.draw_rect(Rect2(-1, -12, 3, 12), wood.darkened(0.2))
	p.draw_rect(Rect2(-7, -2, 14, 2), wood.darkened(0.3))
	p.draw_rect(Rect2(-13, -14, 26, 3), wood)
	p.draw_rect(Rect2(-13, -14, 26, 1), wood.lightened(0.3))
	# 찻주전자·찻잔 둘
	p.draw_circle(Vector2(-2, -18), 4.0, Color("#e8e0f0"))
	p.draw_rect(Rect2(-4, -23, 4, 2), Color("#e8e0f0"))
	p.draw_line(Vector2(2, -18), Vector2(5, -21), Color("#e8e0f0"), 1.0)
	for x in [-10.0, 7.0]:
		p.draw_rect(Rect2(x, -17, 4, 3), Color("#f4ecd8"))
		p.draw_rect(Rect2(x, -17, 4, 1), Color("#8a5a3a"))
		var k := fmod(t * 0.6 + x, 1.0)
		p.draw_rect(Rect2(x + 1.5 + sin(t * 2.0 + x) * 1.0, -20 - k * 8.0, 1, 2), Color(1, 1, 1, 0.35 * (1.0 - k)))


# ─── 침공·폐허 ──────────────────────────────────────────

static func _rubble(p: Prop) -> void:
	var ww := maxf(p.w, 2.0) * T
	var rng := RandomNumberGenerator.new()
	rng.seed = int(p.anchor.x * 13.0 + p.anchor.y)
	var stone := Color(p.theme.base).lightened(0.05)
	for i in int(ww / 5.0):
		var x := rng.randf_range(-ww * 0.5, ww * 0.5)
		var hh := rng.randf_range(3, 10) * (1.0 - absf(x) / (ww * 0.6))
		var w := rng.randf_range(4, 9)
		var col := stone.darkened(rng.randf_range(0.0, 0.35))
		p.draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.5, 0), Vector2(x - w * 0.4, -hh), Vector2(x + w * 0.3, -hh - 1), Vector2(x + w * 0.5, 0)]), col)
		if i % 3 == 0:
			p.draw_rect(Rect2(x - w * 0.4, -hh, w * 0.5, 1), col.lightened(0.2))
	# 재
	p.draw_rect(Rect2(-ww * 0.5, -1, ww, 1), Color(0.75, 0.72, 0.72, 0.5))


static func _burning_beam(p: Prop, t: float) -> void:
	var ww := maxf(p.w, 2.0) * T
	var a := Vector2(-ww * 0.5, -2)
	var b := Vector2(ww * 0.5, -18)
	var n := (b - a).normalized().orthogonal()
	var wood := Color("#3a2418")
	p.draw_colored_polygon(PackedVector2Array([a + n * 4.0, b + n * 4.0, b - n * 4.0, a - n * 4.0]), wood)
	p.draw_line(a + n * 3.0, b + n * 3.0, wood.lightened(0.2), 1.0)
	# 숯이 된 부분(붉게 달아오름)
	for i in 5:
		var q := a.lerp(b, 0.15 + i * 0.17)
		p.draw_rect(Rect2(q - Vector2(2, 1), Vector2(3, 2)), Color(FIRE, 0.55 + 0.4 * sin(t * 5.0 + i)))
	for i in 3:
		_flame(p, a.lerp(b, 0.25 + i * 0.28) - n * 3.0, 12.0 + 3.0 * i, t, i * 1.7)
	p.draw_line(b, b + Vector2(-4, 22), wood, 3.0) # 땅을 짚은 끝


static func _broken_bell(p: Prop) -> void:
	var bronze := Color("#8a6a3a")
	var dark := Color("#4a3620")
	# 쓰러져 기운 종
	var pts := PackedVector2Array([Vector2(-16, 0), Vector2(-12, -10), Vector2(-4, -22), Vector2(6, -24), Vector2(14, -18), Vector2(18, -4), Vector2(14, 0)])
	p.draw_colored_polygon(pts, bronze)
	p.draw_colored_polygon(PackedVector2Array([Vector2(-16, 0), Vector2(-12, -10), Vector2(-8, -12), Vector2(-10, 0)]), dark)
	p.draw_line(Vector2(-12, -10), Vector2(16, -12), bronze.lightened(0.2), 1.0)
	# 금 + 떨어진 조각
	p.draw_polyline(PackedVector2Array([Vector2(2, -23), Vector2(0, -16), Vector2(4, -11), Vector2(1, -4)]), Color("#1a1008"), 1.0)
	p.draw_colored_polygon(PackedVector2Array([Vector2(20, 0), Vector2(22, -4), Vector2(26, -3), Vector2(25, 0)]), bronze.darkened(0.15))
	p.draw_rect(Rect2(-6, -26, 6, 3), dark)


static func _cracked_statue(p: Prop) -> void:
	var st := Color("#8a8494")
	var sd := Color("#5a5664")
	# 받침
	p.draw_rect(Rect2(-12, -8, 24, 8), sd)
	p.draw_rect(Rect2(-12, -8, 24, 2), st.lightened(0.1))
	# 마녀 석상 (머리가 떨어져 나감) — 창립자
	p.draw_colored_polygon(PackedVector2Array([Vector2(-8, -8), Vector2(-5, -34), Vector2(5, -34), Vector2(9, -8)]), st)
	p.draw_colored_polygon(PackedVector2Array([Vector2(-5, -34), Vector2(-3, -36), Vector2(2, -35), Vector2(5, -34)]), sd)
	p.draw_line(Vector2(5, -28), Vector2(12, -20), st, 3.0) # 팔
	p.draw_polyline(PackedVector2Array([Vector2(-2, -34), Vector2(1, -26), Vector2(-3, -19), Vector2(0, -10)]), Color("#2a2830"), 1.0)
	p.draw_polyline(PackedVector2Array([Vector2(4, -30), Vector2(7, -24)]), Color("#2a2830"), 1.0)
	# 바닥에 떨어진 머리와 모자
	p.draw_circle(Vector2(18, -4), 4.0, st)
	p.draw_colored_polygon(PackedVector2Array([Vector2(13, -2), Vector2(26, -5), Vector2(21, -12)]), sd)


static func _broken_pillar(p: Prop) -> void:
	var hh := maxf(p.h, 3.0) * T
	var col := Color(p.theme.base).lightened(0.12)
	var top := PackedVector2Array([Vector2(-8, 0), Vector2(-8, -hh), Vector2(-4, -hh - 6), Vector2(0, -hh + 2), Vector2(4, -hh - 4), Vector2(8, -hh + 3), Vector2(8, 0)])
	p.draw_colored_polygon(top, col)
	p.draw_rect(Rect2(-8, -hh, 3, hh), col.lightened(0.1))
	p.draw_rect(Rect2(4, -hh, 4, hh), col.darkened(0.2))
	for g in 2:
		p.draw_line(Vector2(-2 + g * 4, -hh + 6), Vector2(-2 + g * 4, -2), col.darkened(0.15), 1.0)
	p.draw_rect(Rect2(-10, -4, 20, 4), col.darkened(0.1))
	p.draw_polyline(PackedVector2Array([Vector2(-6, -hh * 0.6), Vector2(-1, -hh * 0.5), Vector2(-4, -hh * 0.35)]), Color(0, 0, 0, 0.5), 1.0)


## 바깥 신들의 흰 결정 (침공에 물든 땅) — 기하학 가시가 천천히 숨쉰다
static func _white_growth(p: Prop, t: float) -> void:
	var k := 0.85 + 0.15 * sin(t * 1.5)
	var spikes := [[-8.0, 18.0, -0.25], [-2.0, 30.0, -0.05], [5.0, 22.0, 0.2], [10.0, 12.0, 0.45], [-12.0, 10.0, -0.5]]
	for s in spikes:
		var x: float = s[0]
		var h: float = s[1] * k
		var r: float = s[2]
		var pts := PackedVector2Array([Vector2(-3, 0), Vector2(0, -h), Vector2(3, 0)])
		for i in pts.size():
			pts[i] = Vector2(x, 0) + pts[i].rotated(r)
		p.draw_colored_polygon(pts, StArt.GOD_WHITE)
		p.draw_line(pts[0], pts[1], StArt.GOD_SHADE, 1.0)
	p.draw_arc(Vector2(0, -12), 16.0, PI * 1.1, PI * 1.9, 12, Color(1, 1, 1, 0.25 + 0.15 * sin(t * 2.0)), 1.0)
	p.draw_rect(Rect2(-14, -1, 28, 1), StArt.GOD_SHADE)


static func _fallen_banner(p: Prop, t: float) -> void:
	# 부러져 기운 깃대 + 찢어진 학교 깃발
	p.draw_line(Vector2(-10, 0), Vector2(8, -34), Color("#5a4a3a"), 2.0)
	var wav := sin(t * 1.8) * 1.0
	var top := Vector2(8, -34)
	p.draw_colored_polygon(PackedVector2Array([top, top + Vector2(14, 4 + wav), top + Vector2(10, 12 + wav), top + Vector2(15, 18), top + Vector2(4, 22), top + Vector2(2, 8)]), Color("#3a2a5a"))
	p.draw_line(top + Vector2(2, 2), top + Vector2(13, 6 + wav), Color("#a88a40"), 1.0)
	# 탄 자국
	p.draw_rect(Rect2(top + Vector2(6, 14), Vector2(3, 3)), Color("#1a1018"))


static func _comm_crystal(p: Prop, t: float) -> void:
	var on := bool(p.params.get("on", true))
	var wood := Color("#4a3426")
	p.draw_rect(Rect2(-6, -4, 12, 4), wood)
	p.draw_colored_polygon(PackedVector2Array([Vector2(-4, -4), Vector2(-6, -12), Vector2(6, -12), Vector2(4, -4)]), Color("#8a7a5a"))
	var c := Vector2(0, -20)
	var flick := 0.6 + 0.4 * sin(t * 13.0) * sin(t * 3.0) if on else 0.2
	p.draw_circle(c, 9.0, Color(0.25, 0.35, 0.55, 0.85))
	p.draw_circle(c, 7.0, Color(0.55, 0.8, 1.0, 0.35 * flick))
	if on:
		# 잡음 낀 얼굴 그림자 (멀리서 오는 소식)
		for i in 3:
			var y := -24.0 + i * 3.0
			p.draw_line(Vector2(-5, y + sin(t * 20.0 + i)), Vector2(5, y), Color(0.8, 0.95, 1.0, 0.3 * flick), 1.0)
	p.draw_rect(Rect2(c + Vector2(-4, -5), Vector2(2, 2)), Color(1, 1, 1, 0.7))


## 떨어진 흰 빛이 판 구덩이: 가운데가 하얗게 달아올라 있다
static func _crater(p: Prop, t: float) -> void:
	var ww := maxf(p.w, 2.0) * T
	p.draw_colored_polygon(PackedVector2Array([Vector2(-ww * 0.5, 0), Vector2(-ww * 0.4, -4), Vector2(-ww * 0.2, -2), Vector2(ww * 0.2, -2), Vector2(ww * 0.4, -5), Vector2(ww * 0.5, 0)]), Color("#2a2228"))
	p.draw_rect(Rect2(-ww * 0.3, -2, ww * 0.6, 2), Color(1, 1, 1, 0.5 + 0.3 * sin(t * 3.0)))
	for i in 4:
		var k := fmod(t * 0.5 + i * 0.25, 1.0)
		p.draw_rect(Rect2(Vector2(-ww * 0.2 + i * ww * 0.13, -3 - k * 16.0), Vector2(1, 2)), Color(1, 1, 1, 0.6 * (1.0 - k)))


static func _ash_tree(p: Prop, t: float) -> void:
	var char_c := Color("#1e1814")
	p.draw_colored_polygon(PackedVector2Array([Vector2(-6, 0), Vector2(-3, -40), Vector2(3, -40), Vector2(6, 0)]), char_c)
	p.draw_line(Vector2(0, -30), Vector2(-16, -48), char_c, 3.0)
	p.draw_line(Vector2(0, -36), Vector2(14, -54), char_c, 3.0)
	p.draw_line(Vector2(-10, -42), Vector2(-14, -56), char_c, 2.0)
	p.draw_line(Vector2(8, -46), Vector2(18, -50), char_c, 2.0)
	# 아직 남은 불씨
	for i in 4:
		var q := Vector2(-2 + (i % 2) * 4, -8 - i * 8)
		p.draw_rect(Rect2(q, Vector2(2, 1)), Color(FIRE, 0.5 + 0.4 * sin(t * 4.0 + i)))
	var k := fmod(t * 0.4, 1.0)
	p.draw_rect(Rect2(Vector2(10 + sin(t) * 4.0, -50 - k * 20.0), Vector2(1, 1)), Color(0.8, 0.78, 0.75, 1.0 - k))


# ─── 에필로그 ───────────────────────────────────────────

static func _scaffold(p: Prop) -> void:
	var ww := maxf(p.w, 2.0) * T
	var hh := maxf(p.h, 3.0) * T
	var wood := Color("#7a5a3a")
	for x in [-ww * 0.5, ww * 0.5 - 3]:
		p.draw_rect(Rect2(x, -hh, 3, hh), wood)
	var y := -hh * 0.33
	while y > -hh:
		p.draw_rect(Rect2(-ww * 0.5, y, ww, 3), wood.lightened(0.1))
		y -= hh * 0.33
	p.draw_line(Vector2(-ww * 0.5, 0), Vector2(ww * 0.5, -hh * 0.33), wood.darkened(0.2), 1.0)
	p.draw_line(Vector2(ww * 0.5, 0), Vector2(-ww * 0.5, -hh * 0.33), wood.darkened(0.2), 1.0)
	# 새 벽돌 더미
	for i in 3:
		p.draw_rect(Rect2(-6 + i * 5, -4, 4, 4), Color("#9a6a4a"))


## 작은 여우 제단 — 너울의 푸른 불이 깃든 곳 (어둠·에필로그)
static func _fox_altar(p: Prop, t: float) -> void:
	var red := Color("#9a2a24")
	p.draw_rect(Rect2(-10, -6, 20, 6), Color("#3a3446"))
	p.draw_rect(Rect2(-8, -16, 16, 10), Color("#4a4458"))
	p.draw_rect(Rect2(-12, -20, 24, 4), red)
	p.draw_rect(Rect2(-9, -22, 18, 2), red.lightened(0.15))
	# 작은 여우 석상 둘
	for s: float in [-1.0, 1.0]:
		var c := Vector2(s * 7.0, -22)
		p.draw_rect(Rect2(c + Vector2(-2, -6), Vector2(4, 6)), Color("#d8d4cc"))
		p.draw_colored_polygon(PackedVector2Array([c + Vector2(-2, -6), c + Vector2(-1, -9), c + Vector2(0, -6)]), Color("#d8d4cc"))
		p.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -6), c + Vector2(1, -9), c + Vector2(2, -6)]), Color("#d8d4cc"))
	StArt.foxfire(p, Vector2(0, -28), 4.0, t, 1.0)


# ─── 2단계: 별의 문 · 중력 반전 문양 ────────────────────

static func _door_col(k: String) -> Color:
	match k:
		"k": return Color("#ffb070") # 제국: 노을빛 주황
		"e": return Color("#9af0a8") # 숲: 잎빛 초록
		"tp": return Color("#fff0a0") # 신전: 금빛
		"s": return Color("#c8a8ff") # 학교: 보라
	return StArt.STAR


## 별의 문: 별빛으로 세운 아치. 문 개체(style="st", 그림 없음)와 같은 자리에 둔다.
## open_if 조건이 아직이면 닫힌 별자리 봉인, 맞으면 안쪽에 별의 길이 소용돌이친다. 시련을 마친 문은 done_if로 별이 꽂힘
static func _star_door(p: Prop, t: float) -> void:
	var col := _door_col(String(p.params.get("col", "tower")))
	var open := RoomData.cond_ok(String(p.params.get("open_if", "")))
	var done_if := String(p.params.get("done_if", ""))
	var done := done_if != "" and RoomData.cond_ok(done_if)
	var w := 18.0
	var h := 44.0
	# 돌 아치
	var frame := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		frame.append(Vector2(cos(a) * (w + 5), -h + w + sin(a) * (w + 5)))
	frame.append(Vector2(w + 5, 0))
	frame.append(Vector2(-w - 5, 0))
	p.draw_colored_polygon(frame, Color("#1a1e48"))
	var inner := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		inner.append(Vector2(cos(a) * w, -h + w + sin(a) * w))
	inner.append(Vector2(w, 0))
	inner.append(Vector2(-w, 0))
	p.draw_colored_polygon(inner, Color("#05061a") if not open else Color(col.darkened(0.75), 1.0))
	# 아치 테두리의 별 줄
	for i in 9:
		var a := PI + PI * i / 8.0
		var q := Vector2(cos(a) * (w + 2.5), -h + w + sin(a) * (w + 2.5))
		StArt.star(p, q, 1.8, Color(col, 0.5 + 0.5 * StArt.twinkle(t, i * 1.3)), -PI * 0.5)
	p.draw_line(Vector2(-w - 5, 0), Vector2(-w - 5, -h + w), Color(col, 0.35), 1.0)
	p.draw_line(Vector2(w + 5, 0), Vector2(w + 5, -h + w), Color(col, 0.35), 1.0)
	if open:
		# 안쪽: 별의 길 (도는 별무리)
		var c := Vector2(0, -h * 0.45)
		StArt.glow(p, c, 22.0, col, 0.35 + 0.08 * sin(t * 2.0))
		for i in 14:
			var a := t * (0.9 + (i % 3) * 0.3) + i * 0.9
			var r := 3.0 + fmod(i * 2.7 + t * 4.0, 15.0)
			var q := c + Vector2(cos(a) * r * 0.8, sin(a) * r * 1.2)
			p.draw_rect(Rect2(q, Vector2(1, 1)), Color(1, 1, 1, 0.8 * (1.0 - r / 18.0)))
		StArt.star(p, c, 4.0, Color(StArt.STAR_CORE, 0.9), -PI * 0.5 + t)
	else:
		# 봉인: 별자리 빗장
		var pts: Array = [Vector2(-w * 0.6, -h * 0.25), Vector2(0, -h * 0.55), Vector2(w * 0.6, -h * 0.25), Vector2(0, -h * 0.05), Vector2(-w * 0.6, -h * 0.25)]
		StArt.constellation(p, pts, col, 0.5 + 0.2 * sin(t * 1.5), 1.5)
	if done:
		var kc := Vector2(0, -h - 6)
		StArt.glow(p, kc, 12.0, StArt.STAR, 0.4)
		StArt.star(p, kc, 5.0, StArt.STAR_GOLD, -PI * 0.5 + t * 0.5)
	# 문턱
	p.draw_rect(Rect2(-w - 7, -2, w * 2 + 14, 2), Color("#d8bc6a"))


## 중력 반전 문양: 바닥에 새겨진 위아래 화살표 별 원. 밟으면 대본이 층을 뒤집는다
static func _flip_sigil(p: Prop, t: float) -> void:
	var k := 0.6 + 0.4 * sin(t * 3.0)
	var c := Vector2(0, -3)
	for i in 2:
		var pts := PackedVector2Array()
		var r := 18.0 - i * 6.0
		for j in 33:
			var a := TAU * j / 32.0 + t * (0.5 if i == 0 else -0.8)
			pts.append(c + Vector2(cos(a) * r, sin(a) * r * 0.3))
		p.draw_polyline(pts, Color(StArt.STAR, 0.4 * k + 0.2), 1.0)
	# 위·아래 화살표 별
	for s: float in [-1.0, 1.0]:
		var ty := -14.0 - 6.0 * s + sin(t * 2.0) * 2.0 * s
		var tip := Vector2(0, ty - 6.0 * s)
		p.draw_colored_polygon(PackedVector2Array([tip, Vector2(-4, ty), Vector2(4, ty)]), Color(StArt.STAR, 0.5 * k))
	StArt.star(p, Vector2(0, -14), 4.0, Color(StArt.STAR_CORE, k), -PI * 0.5 + t)
	for i in 4:
		var f := fmod(t * 0.5 + i * 0.25, 1.0)
		p.draw_rect(Rect2(Vector2(sin(i * 2.0) * 10.0, -2.0 - f * 30.0), Vector2(1, 2)), Color(StArt.STAR, 0.7 * (1.0 - f)))
