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
const FRESH_STAR := Color("#fffaf0") ## 갓 찢긴 틈 신호: 흰 별빛 (물약 색과 겹치지 않게 — 호박색 속박에서도 구별)
const FRESH_SPARKS := 10


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


## 방사형 거미줄 원반 (깨진 자리 그물 · 틈 속박에 걸린 표적): c 가운데(로컬), rr 반지름, sq 세로 눌림, spokes 바큇살 수, rings 둘레 실 자리(반지름 비율)
static func draw_web_disc(pd: PDraw, c: Vector2, rr: float, sq: float, col: Color, acc: Color, a: float, spokes := 12, rings: Array = [0.3, 0.55, 0.78, 0.98]) -> void:
	pd.draw_set_transform(c, 0.0, Vector2(1.0, sq))
	pd.glow(Vector2.ZERO, rr * 1.05, Color(col, 0.16 * a), 0.0)
	pd.draw_set_transform(Vector2.ZERO)
	for i in spokes:
		var d := Vector2.from_angle(float(i) / spokes * TAU)
		pd.draw_line(c, c + Vector2(d.x, d.y * sq) * rr, Color(col, 0.6 * a), 1.0)
	for ring: float in rings:
		for i in spokes:
			var a0 := float(i) / spokes * TAU
			var a1 := float(i + 1) / spokes * TAU
			var p0 := c + Vector2(cos(a0), sin(a0) * sq) * rr * ring
			var p1 := c + Vector2(cos(a1), sin(a1) * sq) * rr * ring
			var m := c + Vector2(cos((a0 + a1) * 0.5), sin((a0 + a1) * 0.5) * sq) * rr * ring * 0.86 # 살짝 처진 실
			pd.draw_line(p0, m, Color(acc, 0.45 * a), 1.0)
			pd.draw_line(m, p1, Color(acc, 0.45 * a), 1.0)


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
## pts = 틈 꺾은선(전역, 비어 있으면 흑성 — at에서 둥글게 퍼짐), w = 틈 굵기, at = 스며든 자리(전역), fresh = 갓 찢긴 틈(금빛 섬광·보상)
static func rift_brew(id: String, strong: bool, pts: PackedVector2Array, w: float, at: Vector2, fresh := true) -> RiftBrew:
	var r := RiftBrew.new()
	r.id = id
	r.strong = strong
	r.fresh = fresh
	r.pts_g = pts
	r.w = maxf(w, 6.0)
	EVfx.add(r, at, false)
	if fresh: # 갓 찢긴 틈: 멈춤·흔들림 + 금빛 반짝임이 튐
		Fx.hitstop(EPotions.RIFT_HITSTOP)
		Fx.shake(0.2, 0.14)
		PVfx.sparks(at, FRESH_SPARKS, FRESH_STAR, 150.0, 0.4, Vector2.UP, 180.0, Vector2(0, 120))
	else:
		Fx.shake(0.08, 0.08)
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


## 병이 이 안에 들어오면 흑성으로 빨려 든다 — absorb_radius()가 있으면 그것, 없으면 끌어당기는 반지름
static func star_absorb_radius(star: Node2D) -> float:
	if is_instance_valid(star) and star.has_method("absorb_radius"):
		return float(star.absorb_radius())
	return star_radius(star)


## 흑성이 끌어당기는 반지름 — pull_radius()가 있으면 그것
static func star_radius(star: Node2D) -> float:
	if not is_instance_valid(star):
		return 0.0
	if star.has_method("pull_radius"):
		return float(star.pull_radius())
	var sz: Variant = star.get("sz")
	return EMagicFx.BlackStar.PULL_R * (float(sz) if sz != null else 1.0)


## 시험용: 이펙트 층의 틈 달이기 그림(RiftBrew)을 한 번씩 그려 본 비용 — "개수 삼각형 꼭짓점"
static func brew_cost() -> String:
	var n := 0
	var tri := 0
	var vert := 0
	var info := ""
	for c: Node in Fx.effect_parent().get_children():
		if c is RiftBrew:
			var r := c as RiftBrew
			r._paint()
			n += 1
			info += " %s:t=%.2f web=%d s=%d" % [r.id, r.t, r._web_d.size(), r._s.size()]
			tri += r.pd.idx.size() / 3
			vert += r.pd.v.size()
			r.pd.clear()
	return "brews=%d tri=%d vert=%d%s" % [n, tri, vert, info]


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
	const HOLD_FRAMES := 3 ## 틈·흑성에 닿은 순간 병이 멈춰 있는 프레임 (흡수가 몸에 묻히지 않게)
	const RING_T := 0.2 ## 닿은 순간 병 둘레에 퍼지는 물약 색 고리
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
	var _start := Vector2.ZERO ## 손 (던진 자리)
	var _hold := 0 ## 닿은 뒤 멈춰 있을 남은 프레임
	var _ring := -1.0 ## 닿은 뒤 시간 (고리)
	var _fresh := false ## 갓 찢긴 틈에 닿았나

	func _ready() -> void:
		z_index = 4
		_start = global_position

	func _physics_process(delta: float) -> void:
		t += delta
		if _ring >= 0.0:
			_ring += delta
		if _mode != "":
			_suck(delta)
			return
		if t > BOTTLE_LIFE:
			queue_free()
			return
		var from := global_position
		var star := EPotionFx.active_blackstar(get_tree())
		if star != null and from.distance_to(EPotionFx.star_center(star)) <= EPotionFx.star_absorb_radius(star):
			_begin_star(star)
			return
		var rift_ok := _rift_ok()
		if rift_ok:
			_bend(delta)
		vel.y += BOTTLE_G * delta
		var to := from + vel * delta
		_rot += spin_v * delta
		if rift_ok:
			var rift := _live_rift(to, EPotions.RIFT_TOUCH)
			if rift.is_empty():
				rift = _live_rift((from + to) * 0.5, EPotions.RIFT_TOUCH)
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

	## 손을 떠나 RIFT_SELF_T초 + RIFT_SELF_R px을 지났나 (그 전엔 틈 무시 — 자기 손 근처 틈이 병을 삼키지 않게)
	func _rift_ok() -> bool:
		return t >= EPotions.RIFT_SELF_T and global_position.distance_to(_start) >= EPotions.RIFT_SELF_R

	## p 둘레 r 안의 열린 틈 중 스며들 만한 것 (적이 걸치지 않은 틈은 무시 — 흐린 물은 예외)
	func _live_rift(p: Vector2, r: float) -> Dictionary:
		var rf := ERifts.at(p, r)
		if rf.is_empty() or not EPotions.rift_live(get_tree(), rf, id):
			return {}
		return rf

	## 열린 틈 가까이(RIFT_AIM 안)를 지나면 그쪽으로 살짝 휜다 — 가까울수록 세게
	func _bend(delta: float) -> void:
		var near := _live_rift(global_position, EPotions.RIFT_AIM)
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
		_fresh = EPotions.rift_fresh(rift) # 닿은 순간으로 판단 (빨려 드는 0.12초는 셈에 안 넣음)
		_touch()
		if _fresh: # 갓 찢긴 틈: 금빛 종이 올라가는 다른 소리
			Sfx.play(&"es_rift_fresh", -1.0)
		else:
			Sfx.play(&"es_rift_brew", -4.0)
		EPotionFx.suction(_to, id)

	## 닿은 순간: 병이 몇 프레임 멈추고 물약 색 고리가 퍼진다
	func _touch() -> void:
		_hold = HOLD_FRAMES
		_ring = 0.0
		queue_redraw()

	func _begin_star(star: Node2D) -> void:
		_mode = "star"
		_star = star
		_to = EPotionFx.star_center(star)
		_from = global_position
		_r0 = _from.distance_to(_to)
		_a0 = (_from - _to).angle()
		_touch()
		Sfx.play_pitch(&"es_rift_brew", 0.8, -1.0)

	## 빨려 듦: 틈 = 날던 방향으로 조금 가다 꺾이는 호(빨라지며) · 흑성 = 소용돌이. 작아지며 빨리 돈다
	func _suck(delta: float) -> void:
		if _hold > 0:
			_hold -= 1
			queue_redraw()
			return
		if _mode == "star" and not _star_ok(): # 흑성이 사라졌거나 다른 병을 먼저 삼킴 → 그 자리에서 깨짐
			_shatter(global_position)
			return
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
				EPotions.rift_brew(get_tree(), eska, id, strong, _rift, _to, _fresh)
			elif not EPotions.star_brew(get_tree(), eska, id, strong, _star):
				_shatter(global_position)
				return
			queue_free()
			return
		queue_redraw()

	## 빨려 드는 동안 흑성이 아직 받아 줄 수 있나
	func _star_ok() -> bool:
		if not is_instance_valid(_star) or not _star.is_inside_tree():
			return false
		return not _star.has_method("can_absorb") or bool(_star.can_absorb())

	func _shatter(p: Vector2) -> void:
		EPotions.splash(get_tree(), eska, id, strong, p)
		queue_free()

	func _paint() -> void:
		var c := EPotions.color(id)
		if _ring >= 0.0 and _ring < RING_T: # 닿은 순간 물약 색 고리
			var f := _ring / RING_T
			pd.draw_arc(Vector2.ZERO, 5.0 + 12.0 * f, 0.0, TAU, 18, Color(EPotionFx.FRESH_STAR if _fresh else EPotions.accent(id), 1.0 - f), 2.0 * (1.0 - f) + 0.6)
			pd.draw_arc(Vector2.ZERO, 3.0 + 8.0 * f, 0.0, TAU, 14, Color(c, 0.8 * (1.0 - f)), 1.0)
		if _mode != "" and _hold <= 0: # 빨려 드는 쪽으로 늘어난 빛 꼬리
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
		EPotionFx.draw_web_disc(pd, Vector2.ZERO, r * e, 0.3, col, acc, a, 12)
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


## 틈 달이기: 물약 색의 밝은 머리가 스며든 자리에서 틈 가장자리를 타고 양쪽으로 번지고(틈 테가 물드는 그림은 ERifts가 그림),
## 번지는 머리가 표적의 가장 가까운 자리에 닿는 순간 효과가 걸린다. 틈이 꿰매지는 순간(ERifts.left(rift_id) = 0) 틈을 따라 번쩍이며 한 번 더(stitch_one).
## 물약마다 남는 그림:
## 속박 = 틈을 따라 쳐진 호박색 거미줄(불규칙 방사형 실 + 처진 줄 + 이슬, 지나간 자리부터 1초 안에 흐려짐) + 묶인 표적에 방사형 거미줄 원반 하나 · 비명 = 틈이 떨며 자리마다 음파 고리 + 머리 위 별
## 부식 = 틈을 따라 맺힌 디더 덩어리 4~6개가 늘어지며 뚝뚝 떨어져 바닥에 거품 점 있는 납작한 웅덩이로 고임(테두리선 없음, 틈 둘레·웅덩이에 든 적에게 부식) · 흐린 물 = 틈을 덮은 잿빛 일렁임 · 쓴 물 = 갈색 김.
## 흑성(pts 없음): 가운데서 물약 색 고리가 퍼지며 닿는 표적마다.
## 갓 찢긴 틈(fresh)이면 스며든 자리에서 흰 네 갈래 별빛이 튀고 금띠 두른 작은 병(진한 표시)이 떠오름 — 색이 아니라 모양으로 구별
## (틈 가장자리 섬광·꿰맴 선은 ERifts 쪽). 늦은 틈은 물약 색 고리만.
## 비용: 틈을 10px마다 표본으로 나누고, 부식은 디더 사각형(삼각형 2개)만 쓴다.
class RiftBrew extends PDraw.Canvas:
	const RACE_V := 700.0 ## 물약 색이 틈을 타고 번지는 빠르기 (px/s)
	const STAR_V := 520.0 ## 흑성: 물약 색 고리가 퍼지는 빠르기
	const STEP := 10.0 ## 틈을 이 간격으로 나눠 그림 (6 → 10: 그림 비용 줄임)
	const HOT_T := 0.35 ## 번진 머리가 밝게 남는 시간
	const STITCH_FX_T := 0.3 ## 꿰매질 때 틈을 따라 번쩍이는 시간
	const STITCH_WAIT := 6.0 ## 틈이 이보다 오래 열려 있으면 꿰매질 때 한 번 더는 포기 (안전장치)
	const WEB_ANCHOR := 3 ## 거미줄: 이 표본마다(약 30px) 방사형 실 묶음 하나
	const WEB_FADE_TO := 0.35 ## 거미줄: 묶는 시간 동안 이만큼까지 흐려짐
	const SCREAM_RING := 26.0 ## 비명: 자리마다 퍼지는 음파 고리 반지름
	const SCREAM_RING_T := 0.4
	const SCREAM_EVERY := 4 ## 비명: 이 표본마다(약 40px) 고리 하나
	const ENTRY_T := 0.22 ## 스며든 자리에서 고리가 조여드는 시간
	const ENTRY_R := 16.0
	const PUFF_EVERY := 3 ## 쓴 물: 이 표본마다 김 덩이 하나
	const ROT_TICK := 0.1
	const ROT_REACH := 8.0 ## 독안개는 틈 ± (RIFT_BAND + 이만큼)
	const DRIP_MIN_N := 4 ## 부식: 틈을 따라 맺히는 덩어리 수 (틈 길이 DRIP_SPAN마다 하나, 4~6개)
	const DRIP_MAX_N := 6
	const DRIP_SPAN := 70.0
	const BLOB_SAG := 0.6 ## 부식 방울: 한 번 도는 동안 이만큼은 맺혀 늘어지고 나머지는 떨어짐
	const BLOB_W := 8.0 ## 맺힌 방울 폭 (px)
	const BLOB_H0 := 8.0 ## 맺힌 방울 길이: 처음 → 끊어지기 직전 (8~12px)
	const BLOB_H1 := 12.0
	const DROP_W := 5.0 ## 떨어지는 방울 (끊어진 끝)
	const DROP_H := 7.0
	const POOL_BUBBLES := 3 ## 웅덩이마다 거품 3개 — POOL_POP초마다 하나씩 차례로 터짐
	const POOL_POP := 0.3
	const POOL_H := 6.0 ## 웅덩이 높이 (납작한 타원, 5~6px — 바닥선과 확실히 구분되게)
	const POOL_SINK := 1.0 ## 웅덩이 타원이 바닥선 아래로 걸치는 깊이 (바닥선을 덮어 띠로 안 보이게)
	const POOL_PTS := 12 ## 웅덩이 타원 둘레 점 수
	const POOL_FADE := 2.0 ## 안개가 끝난 뒤 웅덩이가 가장자리부터 디더로 줄어들며 사라지는 시간
	const FOG_EVERY := 2 ## 틈 둘레 디더 안개: 이 표본마다 칸 몇 개 (흩어진 자리 — 줄무늬 안 되게)
	const FOG_CELLS := 5
	const FOG_BAND := 8.0 ## 디더 안개: 틈 굵기와 관계없이 틈 둘레 ± 이만큼 (낙성 길처럼 가는 틈에서도 보이게 — loop7 3장)
	const DRIP_FALL := 400.0 ## 부식: 바닥을 찾는 아래 거리 (없으면 DRIP_NO_FLOOR 아래에서 끊김)
	const DRIP_NO_FLOOR := 40.0
	const POOL_W := 14.0 ## 부식 웅덩이 반폭 (자라는 끝)
	const POOL_GROW := 10.0 ## 웅덩이가 자라는 빠르기 (px/s)
	const DITHER := 2.0 ## 디더 칸 크기 (px)
	const FRESH_T := 0.35 ## 갓 찢긴 틈: 흰 별빛이 튀는 시간
	const FRESH_STARS := 6
	const FRESH_MARK_T := 0.7 ## 갓 찢긴 틈: 진한 표시(금띠 병)가 떠올랐다 사라지는 시간
	const STRAND_FADE := 1.0 ## 속박: 틈을 따라 남는 실이 스민 순간부터 이 시간 안에 모두 사라짐 (지나간 자리부터 먼저)
	const DISC_MIN := 16.0 ## 속박: 표적에 걸리는 거미줄 원반 반지름 (몸 크기에 맞춰 더 크게)
	const DISC_SPOKES := 8 ## 원반 바큇살 (깨진 자리 그물 12보다 적게 — 표적 여럿이면 그림 비용)
	const DISC_RINGS := [0.38, 0.7, 1.0]
	var id := ""
	var strong := false
	var rift_id := 0 ## 스며든 틈 번호 (꿰매지는 순간을 ERifts.left로 봄, 0 = 흑성 등)
	var stitch_only := false ## 흑성 붕괴 직전 두 번째: 효과 대신 꿰매질 때 한 번 더만
	var fresh := true ## 갓 찢긴 틈에 스몄나 (저항 무시 — 진함은 strong으로, 꿰맬 때 한 번 더는 rift_id로 받음)
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
	var _stitched := false
	var _stitch_t := -1.0 ## 꿰매진 시각 (-1 = 아직)
	var _web := PackedVector2Array() ## 거미줄 선분 (둘씩, 로컬)
	var _web_d := PackedFloat32Array() ## 선분마다 드러나는 번짐 거리
	var _web_k := PackedFloat32Array() ## 선분마다 밝기 (처진 줄 1 · 방사형 실 0.7)
	var _dew := PackedVector3Array() ## 이슬 (x, y, 드러나는 거리)
	var _drips: Array = [] ## 부식 줄기 [표본 번호, 위상, 빠르기, 바닥 y(로컬)]
	var _floor_pending := false

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
		if id == "rot": # 웅덩이가 줄어들며 사라질 시간까지
			life += POOL_FADE
		if not _star and id == "bitter_t":
			for i in range(0, _s.size(), PUFF_EVERY):
				_puffs.append([i, randf_range(8.0, 13.0), randf() * TAU])
		if not _star and id == "rot" and _s.size() > 1:
			var n := clampi(roundi(float(_s.size()) * STEP / DRIP_SPAN), DRIP_MIN_N, DRIP_MAX_N)
			for q in n: # 틈 양 끝을 조금 비우고 고르게
				var i := clampi(roundi((float(q) + 0.5) / float(n) * float(_s.size() - 1)), 0, _s.size() - 1)
				_drips.append([i, randf(), randf_range(0.7, 1.1), _s[i].y + DRIP_NO_FLOOR])
			_floor_pending = true
		if not _star and id == "bind" and _s.size() > 1:
			_build_web()

	## 부식 줄기마다 바닥 찾기 (물리 프레임에서 한 번)
	func _physics_process(_delta: float) -> void:
		if not _floor_pending:
			return
		_floor_pending = false
		var space := get_world_2d().direct_space_state
		for dr: Array in _drips:
			var from := to_global(_s[int(dr[0])])
			var hit := space.intersect_ray(PhysicsRayQueryParameters2D.create(from, from + Vector2(0, DRIP_FALL), 1))
			if not hit.is_empty():
				dr[3] = to_local(hit.position).y

	## 거미줄 모양: 틈을 따라 WEB_ANCHOR 표본마다 불규칙한 방사형 실 2~3가닥 + 묶음 사이에 아래로 처진 줄 두 겹 + 이슬
	func _build_web() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(pts_g)
		var anchors: Array[int] = []
		for i in range(0, _s.size(), WEB_ANCHOR):
			anchors.append(i)
		if anchors[anchors.size() - 1] != _s.size() - 1:
			anchors.append(_s.size() - 1)
		for i in anchors:
			var base := _s[i]
			for q in rng.randi_range(2, 3):
				var tip := base + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(7.0, 18.0) + Vector2(0, rng.randf_range(0.5, 2.5))
				_web_seg(base, tip, _sd[i], 0.7)
				if rng.randf() < 0.45:
					_dew.append(Vector3(tip.x, tip.y, _sd[i]))
		for k in anchors.size() - 1:
			var ia := anchors[k]
			var ib := anchors[k + 1]
			var reveal := maxf(_sd[ia], _sd[ib])
			for layer in 2:
				var p0 := _s[ia] + _n[ia] * rng.randf_range(-6.0, 6.0)
				var p2 := _s[ib] + _n[ib] * rng.randf_range(-6.0, 6.0)
				var sag := rng.randf_range(2.5, 6.5) * (1.0 + 0.5 * float(layer))
				var prev := p0
				var segs := 3 - layer # 앞 줄은 3마디(어두운 테), 뒷 줄은 2마디(테 없이 흐리게)
				for j in range(1, segs + 1):
					var f := float(j) / float(segs)
					var p := p0.lerp(p2, f) + Vector2(0, sag * 4.0 * f * (1.0 - f))
					_web_seg(prev, p, reveal, 1.0 if layer == 0 else 0.85)
					prev = p
				if rng.randf() < 0.6:
					var dp := p0.lerp(p2, 0.5) + Vector2(0, sag)
					_dew.append(Vector3(dp.x, dp.y + 0.8, reveal))

	func _web_seg(a: Vector2, b: Vector2, d: float, k: float) -> void:
		_web.append(a)
		_web.append(b)
		_web_d.append(d)
		_web_k.append(k)

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
				_hit(d)
		if rift_id > 0 and not _stitched and ERifts.left(rift_id) <= 0.0:
			_stitch()
		if id == "rot" and not _star and t < EPotions.ROT_CLOUD_T * _k: # 틈 전체에서 피어오르는 독안개
			_tick -= delta
			if _tick <= 0.0:
				_tick = ROT_TICK
				var hit: Array = EPotions.along(get_tree(), pts_g, EPotions.RIFT_BAND + ROT_REACH)
				for dr: Array in _drips: # 바닥에 고인 웅덩이에 선 적도
					var pw := _pool_w(int(dr[0]), front)
					if pw > 2.0:
						for d: Node2D in EPotions.in_radius(get_tree(), to_global(Vector2(_s[int(dr[0])].x, float(dr[3]))), pw):
							if not hit.has(d):
								hit.append(d)
				for d: Node2D in hit:
					EPotions.rot_one(d, strong)
					if not tracked.has(d):
						tracked.append(d)
		var keep := t < life or (_stitch_t >= 0.0 and t < _stitch_t + STITCH_FX_T)
		if rift_id > 0 and not _stitched and t < STITCH_WAIT: # 꿰매질 때까지 기다림
			keep = true
		if id == "rot":
			for d in tracked:
				if _alive(d) and float(d.get("vuln_t") if d.get("vuln_t") != null else 0.0) > 0.0:
					keep = true
		if not keep:
			queue_free()
			return
		queue_redraw()

	## 표적 하나에 걸기 (흑성 두 번째는 꿰매질 때 한 번 더만)
	func _hit(d: Node2D) -> void:
		tracked.append(d)
		if stitch_only:
			EPotions.stitch_one(d, id)
		else:
			EPotions.apply_one(d, id, strong, true, fresh)
		PVfx.sparks((d.hit_rect() as Rect2).get_center(), 6, acc, 90.0, 0.3)

	## 틈이 꿰매지는 순간: 아직 번짐이 안 닿은 표적에도 걸고, 걸린 표적 모두에게 한 번 더
	func _stitch() -> void:
		_stitched = true
		_stitch_t = t
		EPotions.stitches += 1
		for d in targets:
			if not tracked.has(d) and _alive(d):
				_hit(d)
		for d in tracked:
			if _alive(d):
				EPotions.stitch_one(d, id)
				PVfx.sparks((d.hit_rect() as Rect2).get_center(), 4, Color.WHITE, 70.0, 0.25)
		Sfx.play_pitch(&"es_sigil", 1.4, -8.0)

	func _paint() -> void:
		var front := _front()
		var fade := clampf((life - t) / 0.5, 0.0, 1.0)
		if _stitch_t >= 0.0 and t - _stitch_t < STITCH_FX_T and not _star: # 꿰매질 때: 틈을 따라 번쩍
			var sf := 1.0 - (t - _stitch_t) / STITCH_FX_T
			for i in _s.size() - 1:
				pd.draw_line(_s[i], _s[i + 1], Color(acc, 0.9 * sf), 1.0 + 1.5 * sf)
			for i in range(0, _s.size(), 6):
				pd.glow(_s[i], 5.0 * sf + 2.0, Color(col, 0.6 * sf), 0.0)
		# 스며든 순간: 조여드는 고리 둘 + 작고 밝은 심 (큰 원판 없이). 갓 찢긴 틈이면 금빛 빛살이 터짐
		if t < ENTRY_T:
			var f := t / ENTRY_T
			var e := f * f
			var ring := EPotionFx.FRESH_STAR if fresh else acc
			pd.glow(Vector2.ZERO, 7.0, Color(ring, 0.8 * (1.0 - f)), 0.0)
			pd.draw_arc(Vector2.ZERO, ENTRY_R * (1.0 - e) + 1.5, 0.0, TAU, 16, Color(ring, 1.0 - f), 1.4)
			pd.draw_arc(Vector2.ZERO, ENTRY_R * 1.5 * (1.0 - e) + 2.0, 0.0, TAU, 16, Color(col, 0.55 * (1.0 - f)), 1.0)
		if fresh and t < FRESH_T: # 흰 네 갈래 별빛이 튀어 나감
			var g := t / FRESH_T
			var ge := 1.0 - pow(1.0 - g, 3.0)
			for q in FRESH_STARS:
				var d := Vector2.from_angle(float(q) / FRESH_STARS * TAU + 0.5)
				var sp := d * (6.0 + 22.0 * ge) + Vector2(0, 10.0 * g * g)
				var sz := 3.6 * (1.0 - g) + 1.0
				EPotionFx.star4(pd, sp, sz + 0.8, Color(OUT, 0.5 * (1.0 - g)))
				EPotionFx.star4(pd, sp, sz, Color(EPotionFx.FRESH_STAR, 1.0 - g))
		if fresh and t < FRESH_MARK_T: # 진한 표시: 금띠 두른 작은 병이 떠올랐다 사라짐
			var m := t / FRESH_MARK_T
			EPotionFx.draw_bottle(pd, Vector2(0, -10.0 - 16.0 * m), id, 0.9, 0.85, 1.0 - m * m, 0.0, true)
		if _star:
			_paint_star(front, fade)
		else:
			_paint_race(front, fade)
			match id:
				"bind":
					_paint_strand(front, fade)
				"scream":
					_paint_rings(front)
				"rot":
					_paint_drip(front)
				"bitter_t":
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
			if hot <= 0.0: # 지나간 자리의 물듦은 ERifts가 그림
				continue
			if id == "rot": # 부식은 테두리선 없이 (덩어리·웅덩이만) — 번지는 머리만 아래에서
				continue
			var c := col.lerp(acc, hot)
			var a := hot * fade
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

	## 속박: 틈을 따라 쳐진 호박색 거미줄 (불규칙 방사형 실 + 처진 줄 + 이슬) — 번짐이 지나간 자리부터 드러나고 점점 흐려짐
	func _paint_strand(front: float, fade: float) -> void:
		var hold := EPotions.BIND_T * _k
		var a := fade * clampf((hold + _far / RACE_V - t) / 0.4, 0.0, 1.0) * lerpf(1.0, WEB_FADE_TO, clampf(t / (hold + 0.01), 0.0, 1.0))
		if a <= 0.0:
			return
		for q in _web_d.size():
			if _web_d[q] > front:
				continue
			var sa := a * _strand_a(_web_d[q], front) # 지나간 자리부터 STRAND_FADE 안에 흐려짐
			if sa <= 0.0:
				continue
			var p0 := _web[q * 2]
			var p1 := _web[q * 2 + 1]
			var k := _web_k[q]
			if k >= 1.0: # 처진 줄은 어두운 테 위에 (참격·틈 위에서도 보이게)
				pd.draw_line(p0, p1, Color(OUT, 0.4 * sa), 2.2)
			pd.draw_line(p0, p1, Color(acc if k >= 0.8 else col, 0.9 * k * sa), 1.0)
		for dw in _dew:
			if dw.z <= front:
				var da := a * _strand_a(dw.z, front)
				if da > 0.0:
					pd.draw_rect(Rect2(dw.x - 1.0, dw.y - 1.0, 2.0, 2.0), Color(col, da))
		# 표적으로 뻗은 실 (가장 가까운 표본에서 몸 가운데로, 같이 흐려짐)
		for d in tracked:
			if not _alive(d):
				continue
			var ta := a * _strand_a(float(_reach.get(d, 0.0)), front)
			if ta <= 0.0:
				continue
			var rc: Rect2 = d.hit_rect()
			var mid := to_local(rc.get_center())
			var from := _nearest(mid)
			pd.draw_line(from, mid, Color(OUT, 0.45 * ta), 2.2)
			pd.draw_line(from, mid, Color(acc, 0.85 * ta), 1.0)

	## 틈을 따라 남는 실의 진하기: 번짐이 지나간 뒤 STRAND_FADE초에 걸쳐 0으로
	func _strand_a(d: float, front: float) -> float:
		var by_pass := clampf(1.0 - (front - d) / RACE_V / STRAND_FADE, 0.0, 1.0) # 지나간 자리부터
		var by_t := clampf((STRAND_FADE - t) / 0.25, 0.0, 1.0) # 스민 뒤 STRAND_FADE초면 남은 실 모두 0
		return minf(by_pass, by_t)

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
				var segs := 6
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
			pd.draw_set_transform(Vector2.ZERO)

	## 부식 웅덩이 반폭 (줄기 i가 번진 뒤 자람, 0 = 아직)
	func _pool_w(i: int, front: float) -> float:
		if _sd[i] > front:
			return 0.0
		return minf((front - _sd[i]) / RACE_V * POOL_GROW, POOL_W)

	## 부식: 틈 안은 초록 디더 안개(흩어진 칸 — 줄무늬·사다리 없이), 틈을 따라 4~6자리에 8~12px 방울(어두운 초록 몸 + 연두 하이라이트 1px)이
	## 맺혀 늘어지다 끊어져 떨어지고, 바닥엔 납작한 웅덩이 + 거품 2~3개가 번갈아 터짐. 테두리선 없음
	func _paint_drip(front: float) -> void:
		var hold := EPotions.ROT_CLOUD_T * _k
		var body := col.darkened(0.5) # 어두운 초록 몸
		var hi := acc # 연두 하이라이트
		var tick := int(t * 6.0)
		# 틈 둘레 디더 안개: 표본마다 틈 ± FOG_BAND 안 흩어진 자리에 2px 칸 몇 개 (자리는 표본·시간으로 섞어 줄이 서지 않게)
		for i in range(0, _s.size(), FOG_EVERY):
			if _sd[i] > front:
				continue
			var age := (front - _sd[i]) / RACE_V
			var fa := clampf(age / 0.2, 0.0, 1.0) * clampf((hold + 0.6 - age) / 0.6, 0.0, 1.0)
			if fa <= 0.0:
				continue
			for q in FOG_CELLS:
				var hsh := absi(hash(Vector3i(i, q, tick))) # 매 1/6초 자리를 바꿔 일렁임
				var off := float(hsh % 100) / 100.0 - 0.5
				var along := float((hsh / 100) % 100) / 100.0 - 0.5
				var tg := _n[i].orthogonal()
				var cp := ((_s[i] + _n[i] * off * FOG_BAND * 2.0 + tg * along * STEP) / DITHER).round() * DITHER
				pd.draw_rect(Rect2(cp, Vector2(DITHER, DITHER)), Color(col if q % 2 == 0 else body, (0.75 if q % 2 == 0 else 0.6) * fa))
		for dr: Array in _drips:
			var i: int = dr[0]
			if _sd[i] > front:
				continue
			var age := (front - _sd[i]) / RACE_V
			var ca := clampf(age / 0.2, 0.0, 1.0) * clampf((hold + 0.6 - age) / 0.6, 0.0, 1.0)
			var p := _s[i].round()
			var fy: float = dr[3]
			_paint_pool(p.x, fy, _pool_w(i, front), age, hold, float(dr[1]), col.darkened(0.72), hi) # 안개가 끝난 뒤에도 줄어들며 남음
			if ca <= 0.0:
				continue
			var cyc := fmod(age * float(dr[2]) + float(dr[1]), 1.0)
			if cyc < BLOB_SAG: # 맺혀 늘어지는 방울 (위는 틈에 붙고 아래로 처짐)
				var g := cyc / BLOB_SAG
				_drop(p, BLOB_W * (1.0 - 0.15 * g), lerpf(BLOB_H0, BLOB_H1, g * g), body, hi, ca)
			else: # 끊어져 떨어지는 방울 + 틈에 다시 맺히기 시작한 작은 방울
				var f := (cyc - BLOB_SAG) / (1.0 - BLOB_SAG)
				_drop(p, BLOB_W * 0.6, BLOB_H0 * 0.5, body, hi, ca)
				if fy - p.y > BLOB_H1:
					var y := lerpf(p.y + BLOB_H1 - DROP_H, fy - DROP_H, f * f)
					_drop(Vector2(p.x, y), DROP_W, DROP_H, body, hi, ca)

	## 바닥 웅덩이 (x 가운데, fy 바닥): 높이 POOL_H 납작한 타원(어두운 초록 몸 + 위쪽 물빛 + 윗선 연두 1px), 바닥선 아래로 POOL_SINK 걸침.
	## 거품 3개가 POOL_POP초마다 차례로 부풀어 터짐. 안개가 끝나면(age > hold) POOL_FADE초 동안 가장자리부터 디더로 줄어들며 사라짐
	func _paint_pool(x: float, fy: float, w0: float, age: float, hold: float, ph0: float, body: Color, hi: Color) -> void:
		var shrink := 1.0 - clampf((age - hold) / POOL_FADE, 0.0, 1.0)
		var pw := w0 * shrink
		if pw < 2.0 or age < 0.0:
			return
		var pa := clampf(age / 0.2, 0.0, 1.0)
		var top := fy + POOL_SINK - POOL_H
		var pc := Vector2(roundf(x), top + POOL_H * 0.5)
		var core := maxf(pw - DITHER * 2.0, 1.0) # 가운데는 꽉 찬 타원, 바깥 2칸은 디더 가장자리
		var ell := PackedVector2Array()
		for k in POOL_PTS:
			var an := float(k) / float(POOL_PTS) * TAU
			ell.append(pc + Vector2(cos(an) * core, sin(an) * POOL_H * 0.5))
		pd.convex(ell, Color(body, pa))
		# 위쪽 물빛 (몸보다 밝은 초록 띠 — 액체 표면) + 윗선 연두 1px
		pd.draw_rect(Rect2(roundf(pc.x - core * 0.8), top + 1.0, maxf(roundf(core * 1.6), 1.0), 1.0), Color(col, 0.45 * pa))
		pd.draw_rect(Rect2(roundf(pc.x - core * 0.6), top, maxf(roundf(core * 1.2), 1.0), 1.0), Color(hi, 0.9 * pa))
		# 가장자리 디더 (양쪽 2칸 폭, 체크무늬 — 줄어들 때 이 무늬가 먼저 먹혀 들어감)
		var flick := int(t * 4.0) % 2
		for side: float in [-1.0, 1.0]:
			for cx in 2:
				for cy in 2:
					if (cx + cy + flick) % 2 == 0:
						var ex := pc.x + side * (core + float(cx) * DITHER) - (DITHER if side < 0.0 else 0.0)
						pd.draw_rect(Rect2(roundf(ex), top + 1.0 + float(cy) * DITHER, DITHER, DITHER), Color(body, 0.85 * pa))
		# 거품: 3개가 POOL_POP초 간격으로 차례로 부풀어 터짐 (한 바퀴 = POOL_POP × 3)
		var period := POOL_POP * float(POOL_BUBBLES)
		for q in POOL_BUBBLES:
			var ph := fmod(t / period + float(q) / float(POOL_BUBBLES) + ph0, 1.0)
			var bx := roundf(pc.x + sin(float(q) * 2.3 + ph0 * 6.0) * maxf(core - 2.0, 0.0))
			if ph < 0.75: # 부풂 (1 → 3px)
				var r := 1.0 + roundf(ph / 0.75 * 2.0)
				pd.draw_rect(Rect2(bx - floorf(r * 0.5), top - r + 1.0, r, r), Color(hi, 0.9 * pa))
			elif ph < 0.95: # 터짐: 작은 점 둘이 튐
				var sp := (ph - 0.75) / 0.2 * 3.0
				pd.draw_rect(Rect2(bx - 1.0 - sp, top - 2.0 - sp, 1.0, 1.0), Color(hi, 0.8 * pa))
				pd.draw_rect(Rect2(bx + sp, top - 2.0 - sp, 1.0, 1.0), Color(hi, 0.8 * pa))

	## 방울 하나: top 위 가운데에서 아래로 매달린 물방울 꼴(폭 bw, 길이 bh) — 어두운 몸 + 왼쪽 위 연두 하이라이트 1px
	func _drop(top: Vector2, bw: float, bh: float, body: Color, hi: Color, a: float) -> void:
		var hw := bw * 0.5
		var r := hw
		var cy := top.y + bh - r # 아래쪽 둥근 배
		var pts := PackedVector2Array([top + Vector2(-hw * 0.45, 0), top + Vector2(hw * 0.45, 0)])
		for k in 7:
			var an := -0.15 * PI + float(k) / 6.0 * 1.3 * PI
			pts.append(Vector2(top.x, cy) + Vector2(cos(an), sin(an)) * r)
		pd.convex(pts, Color(body, 0.95 * a))
		pd.draw_rect(Rect2(roundf(top.x - hw * 0.5), roundf(cy - r * 0.5), 1.0, maxf(roundf(r * 0.8), 1.0)), Color(hi, 0.95 * a))

	## 흐린 물: 틈을 덮은 잿빛 일렁임 (틈이 1초 더 열려 있는 동안)
	func _paint_murky(front: float, fade: float) -> void:
		for i in range(0, _s.size(), 3):
			if _sd[i] > front:
				continue
			var p := _s[i] + _n[i] * sin(t * 5.0 + float(i) * 0.6) * w * 0.3
			pd.glow(p, w * 0.7, Color(col, 0.18 * fade), 0.0)
			var bp := fmod(t * 0.8 + float(i) * 0.37, 1.0)
			pd.draw_rect(Rect2(p + Vector2(-0.8, -1.0 - bp * 14.0), Vector2(1.6, 1.6)), Color(acc, 0.5 * fade * (1.0 - bp)))

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
					if bound: # 표적엔 방사형 거미줄 원반 하나 (깨진 자리 그물과 같은 그림)
						var rr := maxf(DISC_MIN, maxf(rc.size.x, rc.size.y) * 0.75)
						EPotionFx.draw_web_disc(pd, rc.get_center() - global_position, rr, 0.6, col, acc, fade, DISC_SPOKES, DISC_RINGS)
				"scream":
					var left := EPotions.scream_time(strong) + float(_reach.get(d, 0.0)) / RACE_V - t
					if _stitch_t >= 0.0:
						left = maxf(left, _stitch_t + EPotions.RIFT_STITCH_STUN - t)
					if left > 0.0:
						EPotionFx.draw_stun_stars(pd, rc, global_position, t, clampf(left / 0.3, 0.0, 1.0), acc)
				"rot":
					if float(d.get("vuln_t") if d.get("vuln_t") != null else 0.0) > 0.0:
						var lp := rc.position - global_position
						for q in 3:
							var ph := fmod(t * 1.4 + float(q) * 0.33, 1.0)
							pd.draw_rect(Rect2(lp.x + rc.size.x * (0.25 + 0.25 * float(q)) - 1.0, lp.y + rc.size.y * (0.3 + 0.7 * ph) - 1.0, 2.0, 2.0), Color(col, 0.95 * (1.0 - ph)))

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
