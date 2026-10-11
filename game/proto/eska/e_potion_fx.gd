class_name EPotionFx
extends RefCounted
## 에스카 물약 그림 (전부 코드 그림, PDraw 묶음): 병·재료 아이콘 · 던진 병(돌며 포물선) · 깨짐(유리·물보라·색 연기)
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


# ═══════════════════════════════════════════════════════════
# 노드들
# ═══════════════════════════════════════════════════════════

## 던진 병: 돌며 포물선, 땅·벽·표적에 닿으면 깨짐
class Bottle extends PDraw.Canvas:
	var eska: EEska
	var id := ""
	var strong := false
	var vel := Vector2.ZERO
	var spin_v := 12.0
	var t := 0.0
	var _rot := 0.0
	var _drip := 0

	func _ready() -> void:
		z_index = 4

	func _physics_process(delta: float) -> void:
		t += delta
		if t > BOTTLE_LIFE:
			queue_free()
			return
		vel.y += BOTTLE_G * delta
		var from := global_position
		var to := from + vel * delta
		_rot += spin_v * delta
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

	func _shatter(p: Vector2) -> void:
		EPotions.splash(get_tree(), eska, id, strong, p)
		queue_free()

	func _paint() -> void:
		pd.glow(Vector2.ZERO, 9.0, Color(EPotions.color(id), 0.22), 0.0)
		EPotionFx.draw_bottle(pd, Vector2.ZERO, id, 1.2, 0.8, 1.0, _rot, strong)


## 깨진 자리: 물약마다 다른 그림 — 속박 호박색 거미줄 그물 · 비명 은백 음파 · 부식 독초록 안개 · 흐린/쓴 물 물보라
class Splash extends PDraw.Canvas:
	const ROT_TICK := 0.1 ## 독안개가 안에 든 적에게 부식을 거는 간격
	var id := ""
	var k := 1.0 ## 진한 물약 배수
	var rot_k := 0.0 ## 0이 아니면 독안개 (EPotions.splash가 정함)
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
				life = EPotions.SCREAM_T * k + 0.3
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
		if rot_k > 0.0 and t < EPotions.ROT_CLOUD_T * k:
			_tick -= delta
			if _tick <= 0.0:
				_tick = ROT_TICK
				for d: Node2D in EPotions.in_radius(get_tree(), global_position + Vector2(0, -8), r):
					if d.has_method("set_vuln"):
						d.set_vuln(EPotions.ROT_VULN_T * rot_k, EPotions.ROT_VULN)
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
			if not bound:
				continue
			var rc: Rect2 = d.hit_rect()
			var lp := rc.position - global_position
			var w := rc.size.x
			var h := rc.size.y
			# 그물에서 몸 위쪽으로 당겨진 실
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
		var stun_t := EPotions.SCREAM_T * k
		if t < stun_t:
			var a2 := clampf((stun_t - t) / 0.3, 0.0, 1.0)
			for d in tracked:
				if not _alive(d):
					continue
				var rc: Rect2 = d.hit_rect()
				var head := Vector2(rc.get_center().x, rc.position.y - 6.0) - global_position
				for q in 3:
					var an := t * 6.0 + float(q) * TAU / 3.0
					var p := head + Vector2(cos(an) * 9.0, sin(an) * 3.0)
					_star(p, 3.0, Color(OUT, 0.6 * a2))
					_star(p, 2.4, Color(acc, a2))

	func _star(p: Vector2, s: float, c: Color) -> void:
		pd.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s), p + Vector2(s * 0.3, -s * 0.3), p + Vector2(s, 0), p + Vector2(s * 0.3, s * 0.3),
			p + Vector2(0, s), p + Vector2(-s * 0.3, s * 0.3), p + Vector2(-s, 0), p + Vector2(-s * 0.3, -s * 0.3)]), c)

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
		pd.glow(Vector2.ZERO, 26.0 * (0.5 + 0.5 * f), Color(col, 0.5 * a), 0.0)
		pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.75, 1.0))
		pd.draw_arc(Vector2.ZERO, 8.0 + 22.0 * (1.0 - pow(1.0 - f, 2.0)), 0.0, TAU, 28, Color(acc, 0.9 * a), 2.0 * a + 0.6)
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

	func _ready() -> void:
		if icons:
			z_index = 1
		else:
			z_index = -1
			material = Fx.add_material

	func _process(delta: float) -> void:
		t += delta
		if (buffs.list as Dictionary).is_empty():
			if not pd.is_empty() or visible:
				queue_redraw()
			return
		queue_redraw()

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
			var a := _alpha(float(list[id]["left"])) * minf((float(list[id]["dur"]) - float(list[id]["left"])) / 0.3 + 0.3, 1.0)
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
			var a := _alpha(float(list[id]["left"]))
			var frac := clampf(float(list[id]["left"]) / maxf(float(list[id]["dur"]), 0.01), 0.0, 1.0)
			pd.draw_circle(p, 5.6, Color(INK, 0.8 * a))
			pd.draw_arc(p, 5.6, -PI / 2.0, -PI / 2.0 + TAU * frac, maxi(int(24.0 * frac), 2), Color(EPotions.color(id), a), 1.4)
			pd.draw_circle(p + Vector2(0, 0.6), 2.4, Color(EPotions.color(id), a))
			pd.draw_rect(Rect2(p + Vector2(-0.9, -3.4), Vector2(1.8, 1.6)), Color(EPotions.accent(id), a))
