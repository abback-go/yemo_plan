class_name EPotionFx
extends RefCounted
## 에스카 물약 그림 (전부 코드 그림, PDraw 묶음): 병·재료 아이콘 · 던진 병(돌며 포물선) · 깨짐(유리·물보라·색 연기)
## · 틈 달이기(병이 틈에 빨려 들어 물약 색이 틈을 타고 번짐 · 흑성이 병을 삼킴)
## · 마신 순간 몸에 색이 도는 빛 · 걸린 동안 몸 둘레의 은은한 빛 + 머리 위 작은 시간 아이콘 · "없음" 표시.
## 자료·효과는 EPotions(e_potions.gd). 파랑 없음.

const INK := Color("#14081f")
const OUT := Color("#0a090e")
const GLASS := Color("#d9ccff")
const CORK := Color("#8a5a3c")
const CORK_HI := Color("#c08a5e")
const GOLD := Color("#ffd77a") ## 진한 물약 목 띠

# 던지기 (손에서 앞으로 약 150px 떨어지는 포물선 — 땅에서 던질 때)
const THROW_VX := 245.0
const THROW_VY := -240.0
const BOTTLE_G := 900.0
const CARRY := 0.25 ## 달리던 빠르기의 이만큼이 병에 실린다
const HAND := Vector2(9, -22) ## 발밑 기준 던지는 손 (앞쪽 = facing)
const BOTTLE_LIFE := 2.5 ## 아무 데도 안 닿으면 (낭떠러지 등) 사라짐
const BOTTLE_PAD := 3.0 ## 표적 판정 사각형을 이만큼 넓혀 맞힘
const BOTTLE_SPIN := 14.0 ## 도는 빠르기 (rad/s)
const RIFT_BEND := 1400.0 ## 열린 틈 가까이를 지나는 병이 그쪽으로 휘는 세기 (px/s²)
const SUCK_BITS := 12 ## 틈에 빨려 드는 자리로 모여드는 알갱이 수


# ═══════════════════════════════════════════════════════════
# 병 · 재료 아이콘 (가마솥 화면·머리 위 아이콘·던진 병이 같이 쓴다)
# ═══════════════════════════════════════════════════════════

## 물약 병 하나: pos 가운데, s 배율(1 = 높이 약 14px), fill 물 높이(0~1), rot 기울기.
## 마시는 물약 = 둥근 병, 던지는 물약 = 원뿔 병. 진한 물약은 목에 금띠. 끝나면 변환을 없앰으로 되돌린다
static func draw_bottle(pd: PDraw, pos: Vector2, id: String, s := 1.0, fill := 0.85, a := 1.0, rot := 0.0, strong := false) -> void:
	var c := Color(EPotions.color(id), a)
	var ac := Color(EPotions.accent(id), a)
	pd.draw_set_transform(pos, rot, Vector2(s, s))
	var throw := EPotions.kind(id) == "throw"
	# 테두리 → 유리 → 물 → 마개
	pd.draw_rect(Rect2(-2.1, -5.8, 4.2, 4.6), Color(OUT, a))
	pd.draw_rect(Rect2(-2.4, -8.6, 4.8, 3.4), Color(OUT, a))
	if throw:
		pd.convex(PackedVector2Array([Vector2(-2.4, -2.7), Vector2(2.4, -2.7), Vector2(5.5, 5.9), Vector2(-5.5, 5.9)]), Color(OUT, a))
		pd.convex(PackedVector2Array([Vector2(-1.6, -2.0), Vector2(1.6, -2.0), Vector2(4.6, 5.0), Vector2(-4.6, 5.0)]), Color(GLASS, 0.22 * a))
		if id != "" and fill > 0.0:
			var lv := 5.0 - clampf(fill, 0.0, 1.0) * 6.8
			var w := lerpf(1.6, 4.6, (lv + 2.0) / 7.0)
			pd.convex(PackedVector2Array([Vector2(-w, lv), Vector2(w, lv), Vector2(4.6, 5.0), Vector2(-4.6, 5.0)]), c)
			pd.draw_line(Vector2(-w + 0.4, lv + 0.3), Vector2(w - 0.4, lv + 0.3), ac, 0.7)
		pd.draw_line(Vector2(-1.2, -1.2), Vector2(-3.4, 4.0), Color(1, 1, 1, 0.55 * a), 0.8)
	else:
		pd.draw_circle(Vector2(0, 1.5), 5.0, Color(OUT, a))
		pd.draw_circle(Vector2(0, 1.5), 4.2, Color(GLASS, 0.22 * a))
		if id != "" and fill > 0.0:
			var lv2 := 5.7 - clampf(fill, 0.0, 1.0) * 8.6
			var liq := disc_below(Vector2(0, 1.5), 4.2, lv2)
			if liq.size() >= 3:
				pd.convex(liq, c)
				var hw := sqrt(maxf(4.2 * 4.2 - pow(lv2 - 1.5, 2.0), 0.0))
				pd.draw_line(Vector2(-hw + 0.5, lv2 + 0.3), Vector2(hw - 0.5, lv2 + 0.3), ac, 0.7)
		pd.draw_arc(Vector2(0, 1.5), 3.0, PI * 1.08, PI * 1.42, 4, Color(1, 1, 1, 0.6 * a), 0.9)
	pd.draw_rect(Rect2(-1.4, -5.2, 2.8, 4.0), Color(GLASS, 0.3 * a))
	pd.draw_rect(Rect2(-1.8, -8.0, 3.6, 2.6), Color(CORK, a))
	pd.draw_rect(Rect2(-1.8, -8.0, 3.6, 0.8), Color(CORK_HI, a))
	if strong:
		pd.draw_rect(Rect2(-2.2, -4.0, 4.4, 1.1), Color(GOLD, a))
	pd.draw_set_transform(Vector2.ZERO)


## 원(c, r) 가운데 y ≥ level 인 부분 (볼록 다각형) — 병 속 물
static func disc_below(c: Vector2, r: float, level: float, n := 12) -> PackedVector2Array:
	var pts := PackedVector2Array()
	if level >= c.y + r:
		return pts
	var a0 := asin(clampf((level - c.y) / r, -1.0, 1.0))
	for i in n + 1:
		var an := lerpf(a0, PI - a0, float(i) / float(n))
		pts.append(c + Vector2(cos(an), sin(an)) * r)
	return pts


## 재료 아이콘 하나: pos 가운데, s 배율(1 = 약 16px)
static func draw_ingredient(pd: PDraw, pos: Vector2, ing: String, s := 1.0, a := 1.0) -> void:
	pd.draw_set_transform(pos, 0.0, Vector2(s, s))
	match ing:
		"mandrake":
			for k in 3:
				var an := -PI / 2.0 + (float(k) - 1.0) * 0.55
				var d := Vector2.from_angle(an)
				var n := d.orthogonal() * 1.7
				var base := Vector2(0, -4.0)
				pd.draw_colored_polygon(PackedVector2Array([base, base + d * 3.5 + n, base + d * 7.5, base + d * 3.5 - n]), Color("#6fbf4a" if k != 1 else "#8fd960", a))
			var body := PackedVector2Array([Vector2(-3.8, -4.6), Vector2(3.8, -4.6), Vector2(4.6, -1.0), Vector2(3.6, 2.6), Vector2(1.6, 5.2), Vector2(0.2, 8.0), Vector2(-1.4, 5.2), Vector2(-3.6, 2.6), Vector2(-4.6, -1.0)])
			pd.outlined(body, Color("#e3c39a", a), Color(OUT, a), 0.8)
			pd.draw_line(Vector2(-2.6, 3.4), Vector2(-4.6, 7.6), Color("#a8805a", a), 1.0)
			pd.draw_line(Vector2(2.6, 3.4), Vector2(4.4, 8.0), Color("#a8805a", a), 1.0)
			pd.draw_line(Vector2(-3.0, -2.6), Vector2(-1.0, -3.6), Color("#fff1dc", 0.7 * a), 0.8)
			pd.draw_circle(Vector2(-1.5, -1.4), 0.75, Color("#3a2418", a))
			pd.draw_circle(Vector2(1.5, -1.4), 0.75, Color("#3a2418", a))
			pd.draw_circle(Vector2(0, 1.3), 1.0, Color("#3a2418", a)) # 비명 지르는 입
		"web":
			var wc := Color("#f3e3c0", 0.92 * a)
			var spokes := 8
			for k in spokes:
				var d := Vector2.from_angle(float(k) / spokes * TAU + 0.2)
				pd.draw_line(Vector2.ZERO, d * 7.8, wc, 0.7)
			for ring: float in [2.6, 5.0, 7.4]:
				for k in spokes:
					var a0 := float(k) / spokes * TAU + 0.2
					var a1 := float(k + 1) / spokes * TAU + 0.2
					var p0 := Vector2.from_angle(a0) * ring
					var p1 := Vector2.from_angle(a1) * ring
					var mid := Vector2.from_angle((a0 + a1) * 0.5) * ring * 0.86 # 살짝 처진 실
					pd.draw_line(p0, mid, wc, 0.6)
					pd.draw_line(mid, p1, wc, 0.6)
			pd.draw_circle(Vector2(3.2, -3.4), 1.1, Color("#ffb347", a)) # 이슬 한 방울
		"toadstool":
			pd.outlined(PackedVector2Array([Vector2(-1.6, 0.6), Vector2(1.6, 0.6), Vector2(2.3, 7.2), Vector2(-2.3, 7.2)]), Color("#efe6d8", a), Color(OUT, a), 0.8)
			var cap := PackedVector2Array()
			for k in 13:
				var an := PI + float(k) / 12.0 * PI
				cap.append(Vector2(cos(an) * 7.2, 1.2 + sin(an) * 7.2))
			pd.outlined(cap, Color("#e0354a", a), Color(OUT, a), 0.8)
			pd.draw_line(Vector2(-6.6, 1.0), Vector2(6.6, 1.0), Color("#7d0c1f", a), 1.2)
			for dot: Vector3 in [Vector3(-3.2, -2.4, 1.2), Vector3(1.6, -4.0, 1.0), Vector3(4.2, -1.0, 0.9), Vector3(-0.4, -0.8, 0.7)]:
				pd.draw_circle(Vector2(dot.x, dot.y), dot.z, Color("#fff4e8", a))
		"dew":
			var drop := PackedVector2Array([Vector2(0, -8.0)])
			for k in 11:
				var an := deg_to_rad(-38.0 + float(k) / 10.0 * 256.0)
				drop.append(Vector2(0, 2.4) + Vector2(cos(an), sin(an)) * 5.2)
			pd.outlined(drop, Color("#e9dcff", 0.9 * a), Color(OUT, a), 0.8)
			pd.draw_circle(Vector2(0.4, 3.0), 3.2, Color("#c9b2ff", 0.8 * a))
			pd.draw_circle(Vector2(0.6, 3.0), 2.2, Color("#ffe08a", a)) # 안에 비친 그믐달
			pd.draw_circle(Vector2(1.6, 2.2), 2.0, Color("#c9b2ff", a))
			pd.draw_line(Vector2(-2.4, -1.0), Vector2(-3.0, 2.6), Color(1, 1, 1, 0.8 * a), 0.9)
		"feather":
			var p0 := Vector2(-5.0, 7.5)
			var p1 := Vector2(5.0, -7.5)
			var dv := (p1 - p0).normalized()
			var nv := dv.orthogonal()
			var lpts := PackedVector2Array()
			var rpts := PackedVector2Array()
			for k in 9:
				var f := 0.15 + float(k) / 8.0 * 0.85
				var w := sin(f * PI) * 3.6 * (1.0 if f < 0.92 else 0.6)
				var cpt := p0.lerp(p1, f)
				lpts.append(cpt + nv * w)
				rpts.append(cpt - nv * w * 0.8)
			var vane := lpts.duplicate()
			rpts.reverse()
			vane.append_array(rpts)
			pd.outlined(vane, Color("#2c2140", a), Color("#8f7bb8", a), 0.8)
			pd.draw_line(p0, p1, Color("#b9a8dc", a), 0.8)
			pd.draw_line(p0.lerp(p1, 0.35) + nv * 1.2, p0.lerp(p1, 0.8) + nv * 1.6, Color("#c9a6ff", 0.9 * a), 0.8) # 보랏빛 윤기
		"soil":
			pd.outlined(PackedVector2Array([Vector2(-1.6, -7.6), Vector2(1.6, -7.6), Vector2(3.6, -5.6), Vector2(3.6, 2.0), Vector2(-3.6, 2.0), Vector2(-3.6, -5.6)]), Color("#6e6878", a), Color(OUT, a), 0.8)
			pd.draw_line(Vector2(0, -6.0), Vector2(0, -1.6), Color("#2b2733", a), 0.9)
			pd.draw_line(Vector2(-1.6, -4.4), Vector2(1.6, -4.4), Color("#2b2733", a), 0.9)
			var mound := PackedVector2Array()
			for k in 11:
				var an := PI + float(k) / 10.0 * PI
				mound.append(Vector2(cos(an) * 7.6, 6.6 + sin(an) * 5.0))
			pd.outlined(mound, Color("#4a3426", a), Color(OUT, a), 0.8)
			pd.draw_line(Vector2(-4.6, 4.2), Vector2(-1.4, 2.6), Color("#6b4c36", a), 1.0)
			pd.draw_line(Vector2(1.6, 4.6), Vector2(4.2, 5.0), Color("#e6dccb", a), 0.9) # 작은 뼈
			for sp: Vector2 in [Vector2(-2.6, 5.2), Vector2(2.4, 3.2), Vector2(0.2, 5.6), Vector2(-5.0, 5.8)]:
				pd.draw_rect(Rect2(sp, Vector2(0.9, 0.9)), Color("#2a1d16", a))
	pd.draw_set_transform(Vector2.ZERO)


# ═══════════════════════════════════════════════════════════
# 쓰는 순간들
# ═══════════════════════════════════════════════════════════

## 빈 칸·병 0: 머리 위에 빈 병 + ✕가 흔들리다 사라짐
static func no_potion(eska: EEska) -> void:
	var n := NoFx.new()
	n.eska = eska
	EVfx.add(n, eska.global_position + Vector2(0, -50), false)


## 마신 순간: 몸에 물약 색이 확 돈다 (빛 고리 + 피어오르는 거품)
static func drink_burst(eska: EEska, id: String) -> void:
	var b := DrinkBurst.new()
	b.eska = eska
	b.col = EPotions.color(id)
	b.acc = EPotions.accent(id)
	EVfx.add(b, eska.center(), true)
	var pp := PParticles.get_layer(true)
	for i in 12:
		var p := eska.center() + Vector2(randf_range(-8, 8), randf_range(-4, 14))
		pp.spawn(p, Vector2(randf_range(-10, 10), randf_range(-60, -25)), Vector2(0, -20), randf_range(0.45, 0.8), randf_range(1.2, 2.4), b.acc, b.col, 2, 1.5)


## 치유: 장밋빛 마름모가 몸에서 피어오름
static func heal_rise(eska: EEska) -> void:
	var pp := PParticles.get_layer(true)
	var c := EPotions.color("heal")
	for i in 8:
		var p := eska.center() + Vector2(randf_range(-10, 10), randf_range(-6, 12))
		pp.spawn(p, Vector2(randf_range(-6, 6), randf_range(-70, -40)), Vector2.ZERO, randf_range(0.5, 0.8), randf_range(1.6, 2.6), Color("#ffd3dc"), c, 0, 2.0)


## 던지기: 손에서 병이 돌며 포물선으로 날아간다
static func throw_bottle(eska: EEska, id: String, strong: bool) -> void:
	var b := Bottle.new()
	b.eska = eska
	b.id = id
	b.strong = strong
	var f := float(eska.facing)
	b.vel = Vector2(f * THROW_VX + eska.velocity.x * CARRY, THROW_VY)
	b.spin_v = BOTTLE_SPIN * f
	EVfx.add(b, eska.global_position + Vector2(HAND.x * f, HAND.y), false)


## 깨진 자리의 그림 (효과 적용은 EPotions.splash가 하고 이 노드에 track으로 맞은 표적을 알려 준다)
static func splash(id: String, strong: bool, pos: Vector2) -> Splash:
	var s := Splash.new()
	s.id = id
	s.strong = strong
	s.k = EPotions.STRONG_MULT if strong else 1.0
	EVfx.add(s, pos, false)
	# 유리 파편 + 물방울
	EVfx.shards(pos + Vector2(0, -3), 7, 150.0, Vector2(3, 2), 90.0)
	var pp := PParticles.get_layer(false)
	var c := EPotions.color(id)
	for i in 16:
		var an := deg_to_rad(randf_range(-160, -20))
		pp.spawn(pos + Vector2(0, -2), Vector2(cos(an), sin(an)) * randf_range(60, 170), Vector2(0, 520), randf_range(0.3, 0.55), randf_range(1.2, 2.4), c.lightened(0.25), c.darkened(0.3), 0, 1.0)
	Sfx.play(&"es_pot_shatter", -2.0)
	Fx.shake(0.22, 0.12)
	return s


## 쓴 물을 맞은 적: 잠깐 빨라짐 (EEnemy에 haste가 없을 때 대신 — 걷는 속도만큼 더 밀어 줌)
static func hasten(e: EEnemy, sec: float, mult: float) -> void:
	var old := e.get_node_or_null("PotionHaste") as Hasten
	if old:
		old.left = maxf(old.left, sec)
		return
	var h := Hasten.new()
	h.name = "PotionHaste"
	h.e = e
	h.left = sec
	h.mult = mult
	e.add_child(h)


## 묶인 표적을 X자로 감은 실(고치). rc = 표적 판정 사각형(전역), origin = 그리는 노드 위치(전역). pulled = 아래 그물에서 당겨진 실도
static func draw_cocoon(pd: PDraw, rc: Rect2, origin: Vector2, t: float, a: float, col: Color, acc: Color, pulled: bool) -> void:
	var lp := rc.position - origin
	var w := rc.size.x
	var h := rc.size.y
	if pulled: # 그물에서 몸 위쪽으로 당겨진 실
		for sd: float in [-1.0, 1.0]:
			var top := Vector2(lp.x + w * (0.5 + 0.35 * sd), lp.y + 2.0)
			pd.draw_line(top, Vector2(top.x + sd * 14.0, minf(lp.y + h, 2.0)), Color(acc, 0.7 * a), 1.0)
	# 몸을 X자로 감은 실 (어두운 테두리 위 밝은 실 — 적의 검은 몸 위에서도 보이게)
	var n := maxi(int(h / 7.0), 2)
	for q in n:
		var y0 := lp.y + h * (float(q) + 0.3) / float(n) + sin(t * 3.0 + float(q)) * 0.8
		for dd: float in [-1.0, 1.0]:
			var p0 := Vector2(lp.x - 2.0, y0 - dd * 3.0)
			var p1 := Vector2(lp.x + w + 2.0, y0 + dd * 3.0)
			pd.draw_line(p0, p1, Color(OUT, 0.55 * a), 2.4)
			pd.draw_line(p0, p1, Color(acc, 0.95 * a), 1.0)
		pd.draw_rect(Rect2(lp.x + w * 0.5 - 0.8, y0 - 0.8, 1.6, 1.6), Color(col, a))


## 기절한 표적 머리 위에 도는 별 셋
static func draw_stun_stars(pd: PDraw, rc: Rect2, origin: Vector2, t: float, a: float, acc: Color) -> void:
	var head := Vector2(rc.get_center().x, rc.position.y - 6.0) - origin
	for q in 3:
		var an := t * 6.0 + float(q) * TAU / 3.0
		var p := head + Vector2(cos(an) * 9.0, sin(an) * 3.0)
		star4(pd, p, 3.0, Color(OUT, 0.6 * a))
		star4(pd, p, 2.4, Color(acc, a))


## 네 갈래 별
static func star4(pd: PDraw, p: Vector2, s: float, c: Color) -> void:
	pd.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s), p + Vector2(s * 0.3, -s * 0.3), p + Vector2(s, 0), p + Vector2(s * 0.3, s * 0.3),
		p + Vector2(0, s), p + Vector2(-s * 0.3, s * 0.3), p + Vector2(-s, 0), p + Vector2(-s * 0.3, -s * 0.3)]), c)


# ═══════════════════════════════════════════════════════════
# 틈 달이기 (loop2_plan.md 2장)
# ═══════════════════════════════════════════════════════════

## 틈 달이기 그림: 물약 색이 들어간 자리에서 틈 가장자리를 타고 양쪽으로 번지고, 닿는 표적마다 효과가 걸린다.
## pts = 틈 꺾은선(전역, 비어 있으면 흑성 — at에서 둥글게 퍼짐), w = 틈 굵기, at = 스며든 자리(전역)
static func rift_brew(id: String, strong: bool, pts: PackedVector2Array, w: float, at: Vector2) -> RiftBrew:
	var r := RiftBrew.new()
	r.id = id
	r.strong = strong
	r.pts_g = pts
	r.w = maxf(w, 6.0)
	EVfx.add(r, at, false)
	Fx.hitstop(EPotions.RIFT_HITSTOP)
	Fx.shake(0.2, 0.14)
	match id: # 물약마다 덧붙는 소리 (틈 자체는 es_rift_brew)
		"bind":
			Sfx.play_pitch(&"es_brew_plop", 0.6, -4.0)
		"scream":
			Sfx.play_pitch(&"es_sigil", 0.55, -2.0)
		"rot":
			Sfx.play_pitch(&"es_brew_bubble", 0.8, -6.0)
		"bitter_t":
			Sfx.play_pitch(&"es_pot_no", 0.8, -10.0)
		_:
			Sfx.play_pitch(&"es_brew_plop", 1.3, -10.0)
	return r


## 병이 빨려 드는 자리: 둘레에서 가운데로 모여드는 물약 색 알갱이
static func suction(pos: Vector2, id: String) -> void:
	var pp := PParticles.get_layer(true)
	var c := EPotions.color(id)
	var ac := EPotions.accent(id)
	for i in SUCK_BITS:
		var an := float(i) / float(SUCK_BITS) * TAU + randf() * 0.3
		var r := randf_range(16.0, 28.0)
		var from := pos + Vector2.from_angle(an) * r
		pp.spawn(from, (pos - from) / 0.14, Vector2.ZERO, 0.14, randf_range(1.4, 2.4), ac, c, 0, 0.0)


## 흑성이 병을 삼킴 (마법 쪽 연출이 없을 때도 보이게): 물약 색 고리가 검은 별로 조여듦
static func star_gulp(id: String, c: Vector2) -> void:
	var g := Gulp.new()
	g.col = EPotions.color(id)
	g.acc = EPotions.accent(id)
	EVfx.add(g, c, true)


## 가속: 고급 마법 쿨다운이 확 풀림 (손끝에서 튀는 반짝임)
static func haste_reset(eska: EEska) -> void:
	PVfx.sparks(eska.center(), 10, EPotions.accent("haste"), 140.0, 0.35, Vector2.UP, 160.0, Vector2.ZERO)
	Sfx.play_pitch(&"es_pot_refill", 1.3, -6.0)


## 메아리 한 번 씀: 머리 위로 라벤더 빛 알갱이 (남은 횟수만큼)
static func echo_tick(eska: EEska, left: int) -> void:
	var pp := PParticles.get_layer(true)
	var c := EPotions.color("echo")
	for i in 4 + 2 * maxi(left, 0):
		pp.spawn(eska.center() + Vector2(randf_range(-8, 8), -10), Vector2(randf_range(-30, 30), randf_range(-70, -30)), Vector2.ZERO, 0.45, 1.8, Color.WHITE, c, 0, 1.5)


## 지금 끌어당기는 중인 흑성 (없으면 null). 마법 쪽 EMagicFx.active_blackstar()가 있으면 그것, 없으면 이펙트 층에서 찾는다
static func active_blackstar(_tree: SceneTree) -> Node2D:
	if has_static(EMagicFx, "active_blackstar"):
		var scr: GDScript = EMagicFx
		var s: Variant = scr.call("active_blackstar")
		if is_instance_valid(s) and s is Node2D:
			return s
		return null
	for n: Node in Fx.effect_parent().get_children():
		if n is EMagicFx.BlackStar:
			var st := float(n.get("t"))
			if st >= EMagicFx.BlackStar.PULL_AT and st < EMagicFx.BlackStar.PULL_AT + EMagicFx.BlackStar.PULL_T:
				return n
	return null


## 흑성 가운데(전역) — pull_center()가 있으면 그것
static func star_center(star: Node2D) -> Vector2:
	if not is_instance_valid(star):
		return Vector2.ZERO
	if star.has_method("pull_center"):
		return star.pull_center()
	var c: Variant = star.get("c")
	return star.to_global(c) if c is Vector2 else star.global_position


## 흑성이 끌어당기는 반지름 — pull_radius()가 있으면 그것
static func star_radius(star: Node2D) -> float:
	if not is_instance_valid(star):
		return 0.0
	if star.has_method("pull_radius"):
		return float(star.pull_radius())
	var sz: Variant = star.get("sz")
	return EMagicFx.BlackStar.PULL_R * (float(sz) if sz != null else 1.0)


## 스크립트에 정적 함수 fn이 있나 (다른 작업자가 나중에 넣는 함수를 이름으로 부를 때 — 결과는 기억해 둠)
static var _statics := {}
static func has_static(scr: GDScript, fn: String) -> bool:
	var key := "%s:%s" % [scr.resource_path, fn]
	if not _statics.has(key):
		var found := false
		for m: Dictionary in scr.get_script_method_list():
			if String(m.get("name", "")) == fn:
				found = true
				break
		_statics[key] = found
	return bool(_statics[key])


# ═══════════════════════════════════════════════════════════
# 노드들
# ═══════════════════════════════════════════════════════════

## 던진 병: 돌며 포물선, 땅·벽·표적에 닿으면 깨짐.
## 틈 달이기: 열린 틈(ERifts) 40px 안을 지나면 살짝 휘고, 틈에 닿으면 깨지지 않고 호를 그리며 빨려 들어 스며든다.
## 끌어당기는 흑성 곁이면 소용돌이치며 검은 별 속으로 빨려 든다.
class Bottle extends PDraw.Canvas:
	const SUCK_T := 0.12 ## 틈에 빨려 드는 시간
	const SUCK_LEAD := 0.06 ## 빨려 들 때 날던 방향으로 이 시간만큼 더 가다 꺾임 (호)
	const SUCK_SHRINK := 0.25 ## 빨려 들며 이만큼까지 작아짐
	const STAR_SUCK_T := 0.42 ## 흑성으로 휘감겨 드는 시간
	const STAR_TURN := 3.2 ## 흑성으로 빨려 들며 도는 각 (rad)
	var eska: EEska
	var id := ""
	var strong := false
	var vel := Vector2.ZERO
	var spin_v := 12.0
	var t := 0.0
	var _rot := 0.0
	var _drip := 0
	var _mode := "" ## "" 날아감 · "rift" 틈에 빨려 듦 · "star" 흑성에 빨려 듦
	var _mt := 0.0
	var _from := Vector2.ZERO
	var _ctrl := Vector2.ZERO
	var _to := Vector2.ZERO
	var _rift := {}
	var _star: Node2D
	var _r0 := 0.0
	var _a0 := 0.0
	var _scale := 1.0

	func _ready() -> void:
		z_index = 4

	func _physics_process(delta: float) -> void:
		t += delta
		if _mode != "":
			_suck(delta)
			return
		if t > BOTTLE_LIFE:
			queue_free()
			return
		var from := global_position
		var star := EPotionFx.active_blackstar(get_tree())
		if star != null and from.distance_to(EPotionFx.star_center(star)) <= EPotionFx.star_radius(star):
			_begin_star(star)
			return
		_bend(delta)
		vel.y += BOTTLE_G * delta
		var to := from + vel * delta
		_rot += spin_v * delta
		var rift := ERifts.at(to, EPotions.RIFT_TOUCH)
		if rift.is_empty():
			rift = ERifts.at((from + to) * 0.5, EPotions.RIFT_TOUCH)
		if not rift.is_empty():
			_begin_rift(rift, to)
			return
		var q := PhysicsRayQueryParameters2D.create(from, to, 1)
		var hit := get_world_2d().direct_space_state.intersect_ray(q)
		if not hit.is_empty():
			_shatter(hit.position)
			return
		for d: Node2D in ETarget.alive(get_tree()):
			if (d.hit_rect() as Rect2).grow(BOTTLE_PAD).has_point(to):
				_shatter(to)
				return
		global_position = to
		_drip += 1
		if _drip % 3 == 0: # 병 꼬리에 흘리는 작은 물방울
			PParticles.get_layer(false).spawn(global_position, -vel * 0.05, Vector2(0, 200), 0.3, 1.4, EPotions.accent(id), EPotions.color(id), 0, 0.0)
		queue_redraw()

	## 열린 틈 가까이(RIFT_AIM 안)를 지나면 그쪽으로 살짝 휜다 — 가까울수록 세게
	func _bend(delta: float) -> void:
		var near := ERifts.at(global_position, EPotions.RIFT_AIM)
		if near.is_empty():
			return
		var q := EPotions.closest_on(near.pts, global_position)
		var d := q - global_position
		var dist := d.length()
		if dist < 0.5:
			return
		var reach := EPotions.RIFT_AIM + float(near.get("w", 0.0)) * 0.5
		var pull := EPotionFx.RIFT_BEND * (1.0 - 0.6 * clampf(dist / reach, 0.0, 1.0))
		vel += d / dist * pull * delta

	func _begin_rift(rift: Dictionary, at: Vector2) -> void:
		_mode = "rift"
		_rift = rift
		_from = global_position
		_to = EPotions.closest_on(rift.pts, at)
		_ctrl = _from + vel * SUCK_LEAD
		Sfx.play(&"es_rift_brew", -1.0)
		EPotionFx.suction(_to, id)

	func _begin_star(star: Node2D) -> void:
		_mode = "star"
		_star = star
		_to = EPotionFx.star_center(star)
		_from = global_position
		_r0 = _from.distance_to(_to)
		_a0 = (_from - _to).angle()
		Sfx.play_pitch(&"es_rift_brew", 0.8, -1.0)

	## 빨려 듦: 틈 = 날던 방향으로 조금 가다 꺾이는 호(빨라지며) · 흑성 = 소용돌이. 작아지며 빨리 돈다
	func _suck(delta: float) -> void:
		_mt += delta
		var dur := SUCK_T if _mode == "rift" else STAR_SUCK_T
		var f := clampf(_mt / dur, 0.0, 1.0)
		var e := f * f
		var prev := global_position
		if _mode == "rift":
			global_position = _from.lerp(_ctrl, e).lerp(_ctrl.lerp(_to, e), e)
		else:
			if is_instance_valid(_star):
				_to = EPotionFx.star_center(_star)
			var an := _a0 + STAR_TURN * e * signf(spin_v)
			global_position = _to + Vector2.from_angle(an) * _r0 * (1.0 - e)
		_scale = lerpf(1.0, SUCK_SHRINK, e)
		_rot += spin_v * 3.0 * delta
		var c := EPotions.color(id)
		PParticles.get_layer(true).spawn(global_position, (prev - global_position) / maxf(delta, 0.001) * 0.15, Vector2.ZERO, 0.18, 1.8, EPotions.accent(id), c, 0, 2.0)
		if f >= 1.0:
			if _mode == "rift":
				EPotions.rift_brew(get_tree(), eska, id, strong, _rift, _to)
			else:
				EPotions.star_brew(get_tree(), eska, id, strong, _star)
			queue_free()
			return
		queue_redraw()

	func _shatter(p: Vector2) -> void:
		EPotions.splash(get_tree(), eska, id, strong, p)
		queue_free()

	func _paint() -> void:
		var c := EPotions.color(id)
		if _mode != "": # 빨려 드는 쪽으로 늘어난 빛 꼬리
			var d := _to - global_position
			pd.line2(Vector2.ZERO, -d.limit_length(14.0), Color(EPotions.accent(id), 0.9), Color(c, 0.0), 3.0 * _scale + 1.0, 0.5)
			pd.glow(Vector2.ZERO, 12.0, Color(c, 0.4), 0.0)
		pd.glow(Vector2.ZERO, 9.0 * _scale, Color(c, 0.22), 0.0)
		EPotionFx.draw_bottle(pd, Vector2.ZERO, id, 1.2 * _scale, 0.8, 1.0, _rot, strong)


## 깨진 자리: 물약마다 다른 그림 — 속박 호박색 거미줄 그물 · 비명 은백 음파 · 부식 독초록 안개 · 흐린/쓴 물 물보라
class Splash extends PDraw.Canvas:
	const ROT_TICK := 0.1 ## 독안개가 안에 든 적에게 부식을 거는 간격
	var id := ""
	var k := 1.0 ## 진한 물약 시간 배수
	var strong := false
	var rot_on := false ## 독안개 (EPotions.splash가 정함)
	var t := 0.0
	var life := 0.8
	var r := 56.0
	var col := Color.WHITE
	var acc := Color.WHITE
	var tracked: Array = [] ## 맞은 표적 (그물·별을 그 위에 그림)
	var marked: Array = [] ## 독안개에 든 적 (부식 동안 초록 방울)
	var _tick := 0.0
	var _puffs: Array = [] ## 독안개 덩이 [위치, 크기, 위상]

	func _ready() -> void:
		z_index = 3
		col = EPotions.color(id)
		acc = EPotions.accent(id)
		match id:
			"bind":
				r = EPotions.BIND_R
				life = EPotions.BIND_T * k + 0.5
			"scream":
				r = EPotions.SCREAM_R
				life = EPotions.scream_time(strong) + 0.3
			"rot":
				r = EPotions.ROT_R
				life = EPotions.ROT_CLOUD_T * k + 0.6
				for i in 14:
					var x := randf_range(-1.0, 1.0) * r * 0.85
					var y := -randf_range(2.0, 14.0) - (1.0 - absf(x) / r) * 12.0 # 가운데가 조금 더 높은 낮은 둔덕
					_puffs.append([Vector2(x, y), randf_range(9.0, 15.0), randf() * TAU])
			"bitter_t":
				r = EPotions.BIND_R
				life = 0.9
			_:
				r = EPotions.MURKY_R
				life = 0.7

	func track(d: Node2D) -> void:
		tracked.append(d)

	## 아직 살아 있는 표적인가 (허수아비는 is_dead가 없다)
	func _alive(d: Variant) -> bool:
		return is_instance_valid(d) and (not d.has_method("is_dead") or not d.is_dead())

	func _process(delta: float) -> void:
		t += delta
		if rot_on and t < EPotions.ROT_CLOUD_T * k:
			_tick -= delta
			if _tick <= 0.0:
				_tick = ROT_TICK
				for d: Node2D in EPotions.in_radius(get_tree(), global_position + Vector2(0, -8), r):
					EPotions.rot_one(d, strong)
					if not marked.has(d):
						marked.append(d)
		var keep := t < life
		if id == "rot": # 부식이 걸린 적이 남아 있으면 초록 방울을 계속 그림
			for d in marked:
				if _alive(d) and float(d.get("vuln_t") if d.get("vuln_t") != null else 0.0) > 0.0:
					keep = true
		if not keep:
			queue_free()
			return
		queue_redraw()

	func _paint() -> void:
		var inn := clampf(t / 0.18, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - inn, 3.0)
		var fade := clampf((life - t) / 0.5, 0.0, 1.0)
		# 깨진 순간: 섬광 + 땅 위로 퍼지는 고리
		if t < 0.25:
			var f := 1.0 - t / 0.25
			pd.glow(Vector2(0, -4), 22.0 * (0.6 + 0.4 * e), Color(acc, 0.8 * f), 0.0)
			pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.32))
			pd.draw_arc(Vector2.ZERO, r * e, 0.0, TAU, 32, Color(acc, 0.9 * f), 3.0 * f + 1.0)
			pd.draw_arc(Vector2.ZERO, r * e * 0.92, 0.0, TAU, 32, Color(col, 0.7 * f), 2.0)
			pd.draw_set_transform(Vector2.ZERO)
		match id:
			"bind":
				_paint_web(e, fade)
			"scream":
				_paint_scream()
			"rot":
				_paint_rot(fade)
			_:
				_paint_puddle(fade)

	## 속박: 땅에 펼쳐진 호박색 거미줄 그물 + 묶인 적을 감는 실(고치)
	func _paint_web(e: float, fade: float) -> void:
		var a := fade
		var spokes := 12
		var sq := 0.3
		var rr := r * e
		pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, sq))
		pd.glow(Vector2.ZERO, rr * 1.05, Color(col, 0.16 * a), 0.0)
		pd.draw_set_transform(Vector2.ZERO)
		for i in spokes:
			var d := Vector2.from_angle(float(i) / spokes * TAU)
			pd.draw_line(Vector2.ZERO, Vector2(d.x, d.y * sq) * rr, Color(col, 0.6 * a), 1.0)
		for ring: float in [0.3, 0.55, 0.78, 0.98]:
			for i in spokes:
				var a0 := float(i) / spokes * TAU
				var a1 := float(i + 1) / spokes * TAU
				var p0 := Vector2(cos(a0), sin(a0) * sq) * rr * ring
				var p1 := Vector2(cos(a1), sin(a1) * sq) * rr * ring
				var m := Vector2(cos((a0 + a1) * 0.5), sin((a0 + a1) * 0.5) * sq) * rr * ring * 0.86 # 살짝 처진 실
				pd.draw_line(p0, m, Color(acc, 0.45 * a), 1.0)
				pd.draw_line(m, p1, Color(acc, 0.45 * a), 1.0)
		for d in tracked:
			if not _alive(d):
				continue
			var bound: bool = d.is_bound() if d.has_method("is_bound") else t < EPotions.BIND_T * k
			if bound:
				EPotionFx.draw_cocoon(pd, d.hit_rect(), global_position, t, a, col, acc, true)

	## 비명: 은백 음파(끊어지고 일렁이는 고리) 셋이 퍼짐 + 처음 순간 터지는 외침 줄기 + 기절한 적 머리 위 도는 별
	func _paint_scream() -> void:
		var c0 := Vector2(0, -10)
		if t < 0.16:
			var f0 := t / 0.16
			for i in 10:
				var d := Vector2.from_angle(float(i) / 10.0 * TAU + 0.3)
				pd.draw_line(c0 + d * (8.0 + 20.0 * f0), c0 + d * (16.0 + 34.0 * f0), Color(acc, 1.0 - f0), 1.6)
		for q in 3:
			var tt := t - float(q) * 0.09
			if tt <= 0.0 or tt > 0.55:
				continue
			var f := tt / 0.55
			var rr := r * (0.2 + 0.95 * (1.0 - pow(1.0 - f, 2.0)))
			var a := 1.0 - f
			var segs := 14
			for i in segs:
				var a0 := float(i) / segs * TAU + float(q) * 0.2
				var wob := 2.0 * (1.0 if i % 2 == 0 else -1.0) * (1.0 - f)
				pd.draw_arc(c0, rr + wob, a0, a0 + TAU / segs * 0.72, 4, Color(acc, 0.9 * a), 2.2 * a + 0.8)
			pd.draw_arc(c0, rr * 0.9, 0.0, TAU, 40, Color(col, 0.25 * a), 1.0)
		var stun_t := EPotions.scream_time(strong)
		if t < stun_t:
			var a2 := clampf((stun_t - t) / 0.3, 0.0, 1.0)
			for d in tracked:
				if not _alive(d):
					continue
				EPotionFx.draw_stun_stars(pd, d.hit_rect(), global_position, t, a2, acc)

	## 부식: 땅에 낮게 깔려 일렁이는 독초록 안개(납작한 덩이들) + 거품 + 부식된 적에서 떨어지는 방울
	func _paint_rot(_fade: float) -> void:
		var cloud_t := EPotions.ROT_CLOUD_T * k
		var ca := clampf((cloud_t + 0.6 - t) / 0.6, 0.0, 1.0)
		if ca > 0.0:
			var dark := col.darkened(0.55)
			pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.24))
			pd.glow(Vector2.ZERO, r * 1.1, Color(dark, 0.5 * ca), 0.2)
			pd.draw_set_transform(Vector2.ZERO)
			for layer in 3:
				for i in _puffs.size():
					var pf: Array = _puffs[i]
					var ph: float = pf[2]
					var grow := clampf((t - float(i) * 0.025) / 0.3, 0.0, 1.0)
					if grow <= 0.0:
						continue
					var s: float = float(pf[1]) * (0.5 + 0.5 * grow) * (1.0 + 0.08 * sin(t * 2.0 + ph))
					var p: Vector2 = pf[0] + Vector2(sin(t * 1.3 + ph) * 3.0, cos(t * 1.1 + ph) * 1.5)
					pd.draw_set_transform(p, 0.0, Vector2(1.5, 0.8))
					match layer:
						0:
							pd.glow(Vector2.ZERO, s * 1.4, Color(dark, 0.4 * ca), 0.0)
						1:
							pd.glow(Vector2.ZERO, s, Color(col, 0.26 * ca), 0.05)
						_:
							pd.glow(Vector2(-s * 0.2, -s * 0.3), s * 0.45, Color(acc, 0.14 * ca), 0.0)
			pd.draw_set_transform(Vector2.ZERO)
			# 거품: 올라가다 터짐
			for i in 8:
				var ph := fmod(t * 0.9 + float(i) * 0.37, 1.0)
				var bx := sin(float(i) * 7.1) * r * 0.75
				var by := -2.0 - ph * 30.0
				var br := 1.0 + 1.4 * sin(ph * PI)
				pd.draw_arc(Vector2(bx, by), br, 0.0, TAU, 8, Color(acc, 0.8 * ca * (1.0 - ph)), 0.8)
		for d in marked:
			if not _alive(d) or float(d.get("vuln_t") if d.get("vuln_t") != null else 0.0) <= 0.0:
				continue
			var rc: Rect2 = d.hit_rect()
			var lp := rc.position - global_position
			for q in 3:
				var ph := fmod(t * 1.4 + float(q) * 0.33, 1.0)
				var x := lp.x + rc.size.x * (0.25 + 0.25 * float(q))
				var y := lp.y + rc.size.y * (0.3 + 0.7 * ph)
				pd.draw_circle(Vector2(x, y), 1.4, Color(col, 0.95 * (1.0 - ph)))

	## 흐린 물·쓴 물: 물웅덩이 + 김
	func _paint_puddle(fade: float) -> void:
		pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.28))
		pd.draw_circle(Vector2.ZERO, r * 0.55 * clampf(t / 0.15, 0.0, 1.0), Color(col, 0.45 * fade))
		pd.draw_set_transform(Vector2.ZERO)
		for i in 4:
			var ph := clampf(t / life, 0.0, 1.0)
			var x := (float(i) - 1.5) * 9.0
			pd.draw_circle(Vector2(x + sin(t * 4.0 + i) * 2.0, -4.0 - ph * 22.0), 3.0 + ph * 4.0, Color(acc, 0.25 * (1.0 - ph)))


## 마신 순간: 몸 둘레에 물약 색 고리가 퍼지고 빛이 확 돈다 (가산, 에스카를 따라감)
class DrinkBurst extends PVfx.Base:
	var eska: EEska
	var col := Color.WHITE
	var acc := Color.WHITE

	func _ready() -> void:
		life = 0.5
		z_index = 2

	func _tick(_d: float) -> void:
		if is_instance_valid(eska):
			global_position = eska.center()

	func _paint() -> void:
		var f := k()
		var a := 1.0 - f
		pd.glow(Vector2.ZERO, 14.0 + 10.0 * f, Color(col, 0.35 * a * a), 0.0)
		pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.7, 1.0))
		pd.draw_arc(Vector2.ZERO, 10.0 + 18.0 * (1.0 - pow(1.0 - f, 2.0)), 0.0, TAU, 28, Color(acc, 0.7 * a), 1.2 * a + 0.5)
		pd.draw_set_transform(Vector2.ZERO)


## "없음": 머리 위 빈 병 + ✕ (좌우로 떨다 사라짐)
class NoFx extends PVfx.Base:
	var eska: EEska

	func _ready() -> void:
		life = 0.6
		z_index = 6

	func _tick(_d: float) -> void:
		if is_instance_valid(eska):
			global_position = eska.global_position + Vector2(0, -52)

	func _paint() -> void:
		var f := k()
		var a := 1.0 - f * f
		var sh := sin(t * 50.0) * 2.0 * (1.0 - f)
		EPotionFx.draw_bottle(pd, Vector2(sh, 0), "", 1.1, 0.0, a)
		var xc := Color("#ff6b7d", a)
		pd.draw_line(Vector2(sh + 3, 2), Vector2(sh + 9, 8), xc, 1.6)
		pd.draw_line(Vector2(sh + 9, 2), Vector2(sh + 3, 8), xc, 1.6)


## 쓴 물을 맞은 적: 잠깐 빨라짐 — 걷는 빠르기에 덧붙여 밀어 주고, 붉은 갈색 김을 흘림
class Hasten extends Node:
	var e: EEnemy
	var left := 2.0
	var mult := 1.5
	var _puff := 0.0

	func _physics_process(delta: float) -> void:
		left -= delta
		if left <= 0.0 or not is_instance_valid(e) or e.is_dead():
			queue_free()
			return
		if e.is_bound() or e.stagger > 0.0 or e.spawn_t > 0.0:
			return
		e.global_position.x = clampf(e.global_position.x + e.velocity.x * delta * (mult - 1.0), e.x_min, e.x_max)
		_puff -= delta
		if _puff <= 0.0:
			_puff = 0.08
			PParticles.get_layer(false).spawn(e.center() + Vector2(randf_range(-6, 6), randf_range(-8, 8)), Vector2(-signf(e.velocity.x) * 30.0, -10.0), Vector2.ZERO, 0.35, 2.4, Color(EPotions.color("bitter_t"), 0.6), Color(EPotions.color("bitter_t"), 0.0), 2, 1.0)


## 걸린 물약: 몸 둘레의 은은한 빛(가산, 몸 뒤) 또는 머리 위 작은 시간 아이콘(보통). EPotions.Buffs의 자식
class BuffView extends PDraw.Canvas:
	const ICON_Y := -54.0 ## 발밑 기준 아이콘 줄 높이
	const ICON_GAP := 13.0
	const BODY := Vector2(0, -16) ## 발밑 기준 몸 가운데
	var buffs: Node ## EPotions.Buffs
	var icons := false
	var t := 0.0
	var _shown := false

	func _ready() -> void:
		if icons:
			z_index = 1
		else:
			z_index = -1
			material = Fx.add_material

	func _process(delta: float) -> void:
		t += delta
		var any := not (buffs.list as Dictionary).is_empty()
		if any or _shown: # 걸린 동안만 매 프레임, 다 풀리면 한 번 지우고 멈춤
			queue_redraw()
		_shown = any

	func _paint() -> void:
		var list: Dictionary = buffs.list
		if list.is_empty():
			return
		var ids: Array = list.keys()
		if icons:
			_paint_icons(ids, list)
		else:
			_paint_aura(ids, list)

	func _alpha(left: float) -> float:
		if left > 2.0:
			return 1.0
		return 0.45 + 0.55 * (0.5 + 0.5 * cos(t * 16.0)) # 끝나기 2초 전부터 깜빡임

	func _paint_aura(ids: Array, list: Dictionary) -> void:
		var n := ids.size()
		for i in n:
			var id: String = ids[i]
			var c := EPotions.color(id)
			var ac := EPotions.accent(id)
			var a := 1.0 if bool(list[id]["charges"]) else _alpha(float(list[id]["left"])) * minf((float(list[id]["dur"]) - float(list[id]["left"])) / 0.3 + 0.3, 1.0)
			var ph := float(i) * TAU / float(n)
			pd.glow(BODY, 19.0 + 1.5 * sin(t * 3.0 + ph), Color(c, 0.13 * a), 0.0)
			# 몸 둘레를 도는 빛 알갱이
			for q in 3:
				var an := t * 2.2 + ph + float(q) * TAU / 3.0
				var p := BODY + Vector2(cos(an) * 12.0, sin(an) * 17.0)
				pd.glow(p, 3.2, Color(c, 0.55 * a), 0.0)
				pd.draw_rect(Rect2(p - Vector2(0.8, 0.8), Vector2(1.6, 1.6)), Color(ac, 0.9 * a))
			# 발밑에서 피어오르는 작은 거품
			for q in 2:
				var f := fmod(t * 0.8 + float(q) * 0.5 + ph * 0.1, 1.0)
				var x := sin(float(q) * 3.7 + ph + t * 2.0) * 7.0
				pd.draw_arc(Vector2(x, -2.0 - f * 32.0), 1.3, 0.0, TAU, 8, Color(ac, 0.6 * a * (1.0 - f)), 0.8)

	func _paint_icons(ids: Array, list: Dictionary) -> void:
		var n := ids.size()
		var x0 := -float(n - 1) * ICON_GAP * 0.5
		for i in n:
			var id: String = ids[i]
			var p := Vector2(x0 + float(i) * ICON_GAP, ICON_Y)
			var charges := bool(list[id]["charges"])
			var a := 1.0 if charges else _alpha(float(list[id]["left"]))
			var frac := 1.0 if charges else clampf(float(list[id]["left"]) / maxf(float(list[id]["dur"]), 0.01), 0.0, 1.0)
			if charges: # 횟수로 세는 버프(메아리): 아이콘 밑에 남은 횟수만큼 점
				var n_left := int(list[id]["left"])
				for q in n_left:
					var dp := p + Vector2((float(q) - float(n_left - 1) * 0.5) * 3.4, 8.4)
					pd.draw_rect(Rect2(dp - Vector2(1.2, 1.2), Vector2(2.4, 2.4)), Color(INK, 0.8))
					pd.draw_rect(Rect2(dp - Vector2(0.8, 0.8), Vector2(1.6, 1.6)), EPotions.accent(id))
			pd.draw_circle(p, 5.6, Color(INK, 0.8 * a))
			pd.draw_arc(p, 5.6, -PI / 2.0, -PI / 2.0 + TAU * frac, maxi(int(24.0 * frac), 2), Color(EPotions.color(id), a), 1.4)
			pd.draw_circle(p + Vector2(0, 0.6), 2.4, Color(EPotions.color(id), a))
			pd.draw_rect(Rect2(p + Vector2(-0.9, -3.4), Vector2(1.8, 1.6)), Color(EPotions.accent(id), a))


## 틈 달이기: 물약 색이 스며든 자리에서 틈 가장자리를 타고 양쪽으로 번지고(머리는 밝게, 지나간 자리는 물약 색으로 남음),
## 번지는 머리가 표적의 가장 가까운 자리에 닿는 순간 효과가 걸린다. 물약마다 남는 그림:
## 속박 = 틈을 따라 쳐진 호박색 거미줄 한 줄 + 표적으로 뻗은 실·고치 · 비명 = 틈이 떨며 자리마다 음파 고리 + 머리 위 별
## 부식 = 틈 전체에서 피어오르는 독안개(안에 든 적에게 부식) · 흐린 물 = 틈을 덮은 잿빛 일렁임 · 쓴 물 = 갈색 김.
## 흑성(pts 없음): 가운데서 물약 색 고리가 퍼지며 닿는 표적마다.
class RiftBrew extends PDraw.Canvas:
	const RACE_V := 700.0 ## 물약 색이 틈을 타고 번지는 빠르기 (px/s)
	const STAR_V := 520.0 ## 흑성: 물약 색 고리가 퍼지는 빠르기
	const STEP := 6.0 ## 틈을 이 간격으로 나눠 그림
	const HOT_T := 0.35 ## 번진 머리가 밝게 남는 시간
	const STAIN_A := 0.3 ## 효과가 남은 동안 틈 가장자리에 남는 물약 색 진하기
	const SCREAM_RING := 26.0 ## 비명: 자리마다 퍼지는 음파 고리 반지름
	const SCREAM_RING_T := 0.4
	const SCREAM_EVERY := 5 ## 비명: 이 표본마다 고리 하나
	const ENTRY_T := 0.22 ## 스며든 자리에서 고리가 조여드는 시간
	const ENTRY_R := 16.0
	const PUFF_EVERY := 3 ## 부식·쓴 물: 이 표본마다 안개 덩이 하나
	const ROT_TICK := 0.1
	const ROT_REACH := 8.0 ## 독안개는 틈 ± (RIFT_BAND + 이만큼)
	var id := ""
	var strong := false
	var pts_g := PackedVector2Array() ## 틈 꺾은선 (전역)
	var w := 12.0
	var targets: Array = [] ## 걸릴 표적 (EPotions가 넣음)
	var tracked: Array = [] ## 이미 걸린 표적 (고치·별을 그 위에)
	var t := 0.0
	var life := 1.0
	var col := Color.WHITE
	var acc := Color.WHITE
	var _star := false
	var _s := PackedVector2Array() ## 틈 표본 (로컬)
	var _n := PackedVector2Array() ## 표본마다 틈의 법선
	var _sd := PackedFloat32Array() ## 표본마다 스며든 자리에서의 틈 길이 거리
	var _far := 0.0 ## 가장 먼 표본까지
	var _reach := {} ## 표적 → 번지는 머리가 닿는 거리
	var _puffs: Array = [] ## [표본 번호, 크기, 위상]
	var _tick := 0.0
	var _k := 1.0

	func _ready() -> void:
		z_index = 5
		col = EPotions.color(id)
		acc = EPotions.accent(id)
		_k = EPotions.STRONG_MULT if strong else 1.0
		_star = pts_g.size() < 2
		if not _star:
			_sample()
		var race := _far / (STAR_V if _star else RACE_V)
		var hold := 0.4
		match id:
			"bind":
				hold = EPotions.BIND_T * _k
			"scream":
				hold = EPotions.scream_time(strong)
			"rot":
				hold = EPotions.ROT_CLOUD_T * _k
			"murky", "murky_t":
				hold = EPotions.RIFT_MURKY_EXTEND
			"bitter_t":
				hold = 1.0
		life = race + maxf(hold, HOT_T) + 0.5
		if not _star and (id == "rot" or id == "bitter_t"):
			for i in range(0, _s.size(), PUFF_EVERY):
				_puffs.append([i, randf_range(8.0, 13.0), randf() * TAU])

	## 틈을 STEP 간격으로 나누고, 스며든 자리(원점)에서 틈을 따라 잰 거리를 표본마다 적는다
	func _sample() -> void:
		var loc := PackedVector2Array()
		for p in pts_g:
			loc.append(to_local(p))
		var acc_len := 0.0
		var lens := PackedFloat32Array()
		for i in loc.size() - 1:
			var a := loc[i]
			var b := loc[i + 1]
			var seg := a.distance_to(b)
			var n := maxi(int(ceil(seg / STEP)), 1)
			var nv := (b - a).orthogonal().normalized()
			for q in n:
				var f := float(q) / float(n)
				_s.append(a.lerp(b, f))
				_n.append(nv)
				lens.append(acc_len + seg * f)
			acc_len += seg
		_s.append(loc[loc.size() - 1])
		_n.append(_n[_n.size() - 1] if _n.size() > 0 else Vector2.UP)
		lens.append(acc_len)
		# 원점(스며든 자리)에 가장 가까운 표본의 길이
		var s0 := 0.0
		var best := INF
		for i in _s.size():
			var dd := _s[i].length_squared()
			if dd < best:
				best = dd
				s0 = lens[i]
		for i in _s.size():
			var d := absf(lens[i] - s0)
			_sd.append(d)
			_far = maxf(_far, d)

	## 번지는 머리가 표적에 닿는 거리 (틈: 가장 가까운 표본의 거리 · 흑성: 가운데서 거리)
	func _reach_of(d: Node2D) -> float:
		var c: Vector2 = to_local((d.hit_rect() as Rect2).get_center())
		if _star:
			return c.length()
		var bi := 0
		var best := INF
		for i in _s.size():
			var dd := _s[i].distance_squared_to(c)
			if dd < best:
				best = dd
				bi = i
		return _sd[bi]

	func _alive(d: Variant) -> bool:
		return is_instance_valid(d) and (not d.has_method("is_dead") or not d.is_dead())

	func _front() -> float:
		return t * (STAR_V if _star else RACE_V)

	func _process(delta: float) -> void:
		t += delta
		var front := _front()
		for d in targets: # 번지는 머리가 닿는 순간 효과
			if tracked.has(d) or not _alive(d):
				continue
			if not _reach.has(d):
				_reach[d] = _reach_of(d)
			if front >= float(_reach[d]):
				tracked.append(d)
				EPotions.apply_one(d, id, strong, true)
				PVfx.sparks((d.hit_rect() as Rect2).get_center(), 6, acc, 90.0, 0.3)
		if id == "rot" and not _star and t < EPotions.ROT_CLOUD_T * _k: # 틈 전체에서 피어오르는 독안개
			_tick -= delta
			if _tick <= 0.0:
				_tick = ROT_TICK
				for d: Node2D in EPotions.along(get_tree(), pts_g, EPotions.RIFT_BAND + ROT_REACH):
					EPotions.rot_one(d, strong)
					if not tracked.has(d):
						tracked.append(d)
		var keep := t < life
		if id == "rot":
			for d in tracked:
				if _alive(d) and float(d.get("vuln_t") if d.get("vuln_t") != null else 0.0) > 0.0:
					keep = true
		if not keep:
			queue_free()
			return
		queue_redraw()

	func _paint() -> void:
		var front := _front()
		var fade := clampf((life - t) / 0.5, 0.0, 1.0)
		# 스며든 순간: 조여드는 고리 둘 + 작고 밝은 심 (큰 원판 없이)
		if t < ENTRY_T:
			var f := t / ENTRY_T
			var e := f * f
			pd.glow(Vector2.ZERO, 7.0, Color(acc, 0.8 * (1.0 - f)), 0.0)
			pd.draw_arc(Vector2.ZERO, ENTRY_R * (1.0 - e) + 1.5, 0.0, TAU, 20, Color(acc, 1.0 - f), 1.4)
			pd.draw_arc(Vector2.ZERO, ENTRY_R * 1.5 * (1.0 - e) + 2.0, 0.0, TAU, 20, Color(col, 0.55 * (1.0 - f)), 1.0)
		if _star:
			_paint_star(front, fade)
		else:
			_paint_race(front, fade)
			match id:
				"bind":
					_paint_strand(front, fade)
				"scream":
					_paint_rings(front)
				"rot", "bitter_t":
					_paint_mist(front)
				_:
					_paint_murky(front, fade)
		_paint_marks(fade)

	## 틈 가장자리 두 줄을 타고 번지는 물약 색: 머리는 흰빛에 가깝게, 지나간 자리는 물약 색으로 남음
	func _paint_race(front: float, fade: float) -> void:
		var half := w * 0.5
		for i in _s.size() - 1:
			if _sd[i] > front or _sd[i + 1] > front:
				continue
			var age := (front - maxf(_sd[i], _sd[i + 1])) / RACE_V
			var hot := clampf(1.0 - age / HOT_T, 0.0, 1.0)
			var c := col.lerp(acc, hot)
			var a := maxf(hot, STAIN_A) * fade
			var o0 := _n[i] * half
			var o1 := _n[i + 1] * half
			pd.draw_line(_s[i] + o0, _s[i + 1] + o1, Color(c, a), 1.0 + 1.6 * hot)
			pd.draw_line(_s[i] - o0, _s[i + 1] - o1, Color(c, a), 1.0 + 1.6 * hot)
			if hot > 0.0:
				pd.draw_line(_s[i], _s[i + 1], Color(acc, 0.5 * hot), 1.0)
		# 번지는 머리 (양쪽으로)
		if front < _far + STEP:
			for i in _s.size():
				if absf(_sd[i] - front) < STEP * 0.5:
					pd.glow(_s[i], 7.0, Color(acc, 0.9), 0.0)
					pd.draw_rect(Rect2(_s[i] - Vector2(1.2, 1.2), Vector2(2.4, 2.4)), Color.WHITE)

	## 속박: 틈을 따라 쳐진 호박색 거미줄 한 줄 (살짝 처진 실 + 가로 실 + 이슬)
	func _paint_strand(front: float, fade: float) -> void:
		var hold := EPotions.BIND_T * _k
		var a := fade * clampf((hold + _far / RACE_V - t) / 0.4, 0.0, 1.0)
		if a <= 0.0:
			return
		for i in _s.size() - 1:
			if _sd[i + 1] > front:
				continue
			var sag0 := _n[i] * sin(float(i) * 0.9) * 1.2
			var sag1 := _n[i + 1] * sin(float(i + 1) * 0.9) * 1.2
			pd.draw_line(_s[i] + sag0, _s[i + 1] + sag1, Color(OUT, 0.5 * a), 2.6)
			pd.draw_line(_s[i] + sag0, _s[i + 1] + sag1, Color(acc, 0.95 * a), 1.0)
			if i % 3 == 0:
				var cr := _n[i] * (w * 0.5 + 3.0)
				pd.draw_line(_s[i] - cr, _s[i] + cr, Color(col, 0.75 * a), 1.0)
			if i % 5 == 2:
				pd.draw_circle(_s[i] + sag0 + Vector2(0, 1.5), 1.3, Color(col, a))
		# 표적으로 뻗은 실 (가장 가까운 표본에서 몸 위쪽으로)
		for d in tracked:
			if not _alive(d):
				continue
			var rc: Rect2 = d.hit_rect()
			var top := to_local(Vector2(rc.get_center().x, rc.position.y + 4.0))
			var from := _nearest(top)
			pd.draw_line(from, top, Color(OUT, 0.45 * a), 2.2)
			pd.draw_line(from, top, Color(acc, 0.85 * a), 1.0)

	## 비명: 번진 자리마다 떨리는 틈 + 끊어져 퍼지는 음파 고리
	func _paint_rings(front: float) -> void:
		for i in _s.size() - 1:
			if _sd[i] > front:
				continue
			var age := (front - _sd[i]) / RACE_V
			if age < SCREAM_RING_T: # 틈이 울려 떨림
				var j := (1.0 - age / SCREAM_RING_T) * 2.2
				var o := _n[i] * sin(t * 70.0 + float(i) * 1.7) * j
				pd.draw_line(_s[i] + o, _s[i + 1] - o, Color(acc, 0.9 * (1.0 - age / SCREAM_RING_T)), 1.4)
			if i % SCREAM_EVERY == 0 and age < SCREAM_RING_T:
				var f := age / SCREAM_RING_T
				var rr := 3.0 + SCREAM_RING * (1.0 - pow(1.0 - f, 2.0))
				var segs := 8
				for q in segs:
					var a0 := float(q) / segs * TAU + float(i)
					pd.draw_arc(_s[i], rr, a0, a0 + TAU / segs * 0.7, 3, Color(acc, 0.9 * (1.0 - f)), 1.6 * (1.0 - f) + 0.6)

	## 부식(독안개) · 쓴 물(갈색 김): 틈을 따라 피어오르는 덩이들
	func _paint_mist(front: float) -> void:
		var rot := id == "rot"
		var hold := EPotions.ROT_CLOUD_T * _k if rot else 1.0
		var dark := col.darkened(0.55)
		for pf: Array in _puffs:
			var i: int = pf[0]
			if _sd[i] > front:
				continue
			var age := (front - _sd[i]) / RACE_V
			var ca := clampf(age / 0.25, 0.0, 1.0) * clampf((hold + 0.6 - age) / 0.6, 0.0, 1.0)
			if ca <= 0.0:
				continue
			var ph: float = pf[2]
			var s: float = float(pf[1]) * (0.6 + 0.4 * clampf(age / 0.3, 0.0, 1.0)) * (1.0 + 0.08 * sin(t * 2.0 + ph))
			var rise := 0.0 if rot else age * 18.0 # 쓴 물 김은 올라감
			var p := _s[i] + Vector2(sin(t * 1.3 + ph) * 3.0, -2.0 - rise + cos(t * 1.1 + ph) * 1.5)
			pd.draw_set_transform(p, 0.0, Vector2(1.4, 0.85))
			pd.glow(Vector2.ZERO, s * 1.4, Color(dark, 0.38 * ca), 0.0)
			pd.glow(Vector2.ZERO, s, Color(col, 0.26 * ca), 0.05)
			pd.glow(Vector2(-s * 0.2, -s * 0.3), s * 0.45, Color(acc, 0.14 * ca), 0.0)
			pd.draw_set_transform(Vector2.ZERO)
			var bp := fmod(t * 0.9 + ph, 1.0) # 터지는 거품
			pd.draw_arc(p + Vector2(0, -bp * 16.0), 1.0 + 1.4 * sin(bp * PI), 0.0, TAU, 8, Color(acc, 0.7 * ca * (1.0 - bp)), 0.8)

	## 흐린 물: 틈을 덮은 잿빛 일렁임 (틈이 1초 더 열려 있는 동안)
	func _paint_murky(front: float, fade: float) -> void:
		for i in range(0, _s.size(), 2):
			if _sd[i] > front:
				continue
			var p := _s[i] + _n[i] * sin(t * 5.0 + float(i) * 0.6) * w * 0.3
			pd.glow(p, w * 0.7, Color(col, 0.18 * fade), 0.0)
			var bp := fmod(t * 0.8 + float(i) * 0.37, 1.0)
			pd.draw_arc(p + Vector2(0, -bp * 14.0), 1.2, 0.0, TAU, 6, Color(acc, 0.5 * fade * (1.0 - bp)), 0.8)

	## 흑성: 가운데서 물약 색 고리가 퍼져 끌려온 적에게 닿음
	func _paint_star(front: float, _fade: float) -> void:
		var f := clampf(t / 0.6, 0.0, 1.0)
		if f < 1.0:
			pd.draw_arc(Vector2.ZERO, front, 0.0, TAU, 40, Color(acc, 0.9 * (1.0 - f)), 3.0 * (1.0 - f) + 1.0)
			pd.draw_arc(Vector2.ZERO, front * 0.92, 0.0, TAU, 40, Color(col, 0.6 * (1.0 - f)), 2.0)

	## 걸린 표적 위: 속박 고치 · 비명 별 · 부식 초록 방울
	func _paint_marks(fade: float) -> void:
		for d in tracked:
			if not _alive(d):
				continue
			var rc: Rect2 = d.hit_rect()
			match id:
				"bind":
					var bound: bool = d.is_bound() if d.has_method("is_bound") else t < EPotions.BIND_T * _k
					if bound:
						EPotionFx.draw_cocoon(pd, rc, global_position, t, fade, col, acc, false)
				"scream":
					var left := EPotions.scream_time(strong) + float(_reach.get(d, 0.0)) / RACE_V - t
					if left > 0.0:
						EPotionFx.draw_stun_stars(pd, rc, global_position, t, clampf(left / 0.3, 0.0, 1.0), acc)
				"rot":
					if float(d.get("vuln_t") if d.get("vuln_t") != null else 0.0) > 0.0:
						var lp := rc.position - global_position
						for q in 3:
							var ph := fmod(t * 1.4 + float(q) * 0.33, 1.0)
							pd.draw_circle(Vector2(lp.x + rc.size.x * (0.25 + 0.25 * float(q)), lp.y + rc.size.y * (0.3 + 0.7 * ph)), 1.4, Color(col, 0.95 * (1.0 - ph)))

	func _nearest(p: Vector2) -> Vector2:
		var best := _s[0] if _s.size() > 0 else Vector2.ZERO
		var bd := INF
		for q in _s:
			var dd := q.distance_squared_to(p)
			if dd < bd:
				bd = dd
				best = q
		return best


## 흑성이 병을 삼킴: 물약 색 고리가 가운데로 조여들며 별이 그 색으로 번쩍 (가산)
class Gulp extends PVfx.Base:
	var col := Color.WHITE
	var acc := Color.WHITE

	func _ready() -> void:
		life = 0.55
		z_index = 7

	func _paint() -> void:
		var f := k()
		var e := 1.0 - pow(1.0 - f, 2.0)
		pd.draw_arc(Vector2.ZERO, 48.0 * (1.0 - e) + 6.0, 0.0, TAU, 32, Color(acc, 0.9 * (1.0 - f)), 2.5 * (1.0 - f) + 0.8)
		pd.glow(Vector2.ZERO, 30.0, Color(col, 0.55 * sin(f * PI)), 0.0)
