class_name TFx
extends RefCounted
## 턴제 전투 연출 모음. play(fx, caster, targets)가 마법 하나의 연출을 띄우고 {"hits": [맞는 시각...], "total": 끝나는 시각}을 돌려준다 —
## 장면(TStage)이 그 시각에 피해·숫자·움찔을 보여 준다. 모든 그림은 코드(PDraw)이고 수명이 끝나면 스스로 사라진다.
## 에스카의 공격은 실시간 데모의 흑백 균열(BFx.Rift)을 그대로 쓰고, 불 마법·보조 마법은 여기서 새로 그린다.
## 불 색: 심 CORE(흰 노랑) → HOT(금) → FLAME(주홍) → DEEP(붉음) → 그을음. 보조 마법은 종류별 색(공격 붉은 금 · 크리 금 · 특공 주홍 · 최종 보라 · 회복 연둣빛).

const CORE := Color("#fff6d8")
const HOT := Color("#ffd27a")
const FLAME := Color("#ff8a3a")
const DEEP := Color("#e2452a")
const DARK := Color("#6b1a12")
const SMOKE := Color("#2a1a1a")
const GOLD := Color("#ffe08a")
const HEAL := Color("#b8f0a0")
const ASH := Color("#9a8aa6")
const LAV := Color("#b9a2ff")
const PALE := Color("#e6dcff")
const INK := Color("#14081f")
const WHITE := Color(1, 1, 1)

## 속성별 불 색 (불 마법 연출을 그대로 쓰되 색만 바꾼다 — 코드 그림 변형)
const PAL := {
	"fire": {"core": CORE, "hot": HOT, "flame": FLAME, "deep": DEEP, "dark": DARK, "gold": GOLD},
	"water": {"core": Color("#eafcff"), "hot": Color("#9fe8ff"), "flame": Color("#3fb0ff"), "deep": Color("#1e55c8"), "dark": Color("#0f2a66"), "gold": Color("#c8f4ff")},
	"bolt": {"core": Color("#ffffff"), "hot": Color("#fff3b0"), "flame": Color("#ffdd4a"), "deep": Color("#9a7cff"), "dark": Color("#3d2a7a"), "gold": Color("#fff8d0")},
	"time": {"core": Color("#fff9e8"), "hot": Color("#ffe8a8"), "flame": Color("#f2c75a"), "deep": Color("#b07a2a"), "dark": Color("#4a3414"), "gold": Color("#ffe08a")},
	"space": {"core": Color("#ffffff"), "hot": Color("#e6dcff"), "flame": Color("#b9a2ff"), "deep": Color("#6a46a0"), "dark": Color("#2a1540"), "gold": Color("#e6dcff")},
	"sword": {"core": Color("#ffffff"), "hot": Color("#f2eff7"), "flame": Color("#cfc9dc"), "deep": Color("#3b1268"), "dark": Color("#14081f"), "gold": Color("#ffffff")},
	# 대마법 전용 (단계 D): 같은 속성 안에서 마녀마다 결을 나눈다
	"ash": {"core": Color("#ffe6c0"), "hot": Color("#ffb070"), "flame": Color("#e8743a"), "deep": Color("#6e3a30"), "dark": Color("#241a22"), "gold": Color("#ffd9a0")},
	"tide": {"core": Color("#ffffff"), "hot": Color("#dff6ff"), "flame": Color("#8fd4ff"), "deep": Color("#3a8ac2"), "dark": Color("#123250"), "gold": Color("#f0fbff")},
	"ice": {"core": Color("#ffffff"), "hot": Color("#e8fbff"), "flame": Color("#bfe9ff"), "deep": Color("#5aa8e0"), "dark": Color("#16324e"), "gold": Color("#ffffff")},
	"star": {"core": Color("#ffffff"), "hot": Color("#fff6c8"), "flame": Color("#c9a0ff"), "deep": Color("#7a5fd0"), "dark": Color("#22164a"), "gold": Color("#ffe34a")},
	"storm": {"core": Color("#ffffff"), "hot": Color("#fff3b0"), "flame": Color("#ffe34a"), "deep": Color("#5a64e0"), "dark": Color("#161a3a"), "gold": Color("#fff8d0")},
}
static var cur: Dictionary = PAL.fire ## 지금 시전 중인 속성의 색 (play()가 바꾼다)


static func set_element(el: String) -> void:
	cur = PAL.get(el, PAL.fire)


static func add(n: Node2D, pos: Vector2, additive := false) -> Node2D:
	return PVfx.add(n, pos, additive)


## sec 뒤에 f를 부른다 (멈춤 중엔 같이 멈춤)
static func after(sec: float, f: Callable) -> void:
	var tree := Fx.get_tree()
	if sec <= 0.0:
		f.call()
		return
	tree.create_timer(sec).timeout.connect(f)


## 불티: dir 방향으로 튀는 가산 입자
static func embers(pos: Vector2, n: int, speed: float, dir := Vector2.UP, spread := 180.0, life := 0.5, grav := Vector2(0, 80)) -> void:
	var pp := PParticles.get_layer(true)
	var base := dir.angle()
	for i in n:
		var a := base + deg_to_rad(randf_range(-spread, spread))
		var sp := randf_range(speed * 0.3, speed)
		var c0: Color = cur.core if i % 4 == 0 else (cur.hot if i % 2 == 0 else cur.flame)
		pp.spawn(pos, Vector2(cos(a), sin(a)) * sp, grav, life * randf_range(0.6, 1.0), randf_range(1.2, 2.6), c0, Color(cur.deep, 0.0), 1 if sp > speed * 0.7 else 0, 2.5)


static func smoke(pos: Vector2, n: int, r := 8.0) -> void:
	var pp := PParticles.get_layer(false)
	for i in n:
		pp.spawn(pos + Vector2(randf_range(-r, r), randf_range(-r * 0.5, r * 0.5)), Vector2(randf_range(-20, 20), randf_range(-50, -20)), Vector2.ZERO,
			randf_range(0.5, 0.9), randf_range(5.0, 9.0), Color(SMOKE, 0.55), Color(SMOKE, 0.0), 2, 2.0)


## 맞는 순간: 속성별 섬광 (불은 주홍 별 + 불티, 공간은 흑백 금, 적 공격은 붉은 X)
static func impact(pos: Vector2, kind: String, heavy: bool, dir := 1.0) -> void:
	match kind:
		"fire":
			var b := FireBurst.new()
			b.size = 1.5 if heavy else 0.9
			add(b, pos, true)
			embers(pos, 18 if heavy else 8, 240.0 if heavy else 150.0, Vector2(dir, -0.6), 80.0, 0.5, Vector2(0, 260))
			if heavy:
				smoke(pos, 5, 10.0)
		"space":
			EVfx.hit_crack(pos, heavy, dir)
			BFx.ink_sparks(pos, 10 if heavy else 5, 260.0 if heavy else 160.0, Vector2(dir, -0.5))
		_:
			var x := EnemyHit.new()
			x.heavy = heavy
			add(x, pos, false)
			EVfx.pixels(pos, 6 if heavy else 3, 180.0, Vector2(-dir, -0.3), 80.0, 0.3, Vector2(0, 300))


# ═══════════════════════════════════════════════════════════
# 마법 연출 — 이름 → 연출 (시각 표)
# ═══════════════════════════════════════════════════════════

static func play(fx: String, caster: TActor, targets: Array) -> Dictionary:
	var hand := caster.hand()
	var hits: Array = []
	var total := 0.8
	var tp: Vector2 = targets[0].center() if not targets.is_empty() else hand
	if caster.unit != null:
		set_element(caster.unit.attack_element() if caster.unit.is_witch() else "fire")
	match fx:
		# ── 공통 (12명 확장)
		"hex", "hex_all":
			var i := 0
			for a in targets:
				var hx := Hex.new()
				add(hx, a.center(), true)
				hits.append(0.3 + 0.08 * float(i))
				i += 1
			Sfx.play(&"tn_buff", -9.0)
			total = 0.9 + 0.08 * float(targets.size())
		"warmth_one":
			var w := Aura.new()
			w.col = HEAL
			w.kind = "heal"
			add(w, targets[0].center(), true)
			LanternFlash.spawn(caster)
			Sfx.play(&"tn_heal", -6.0)
			hits = [0.4]
			total = 1.0
		"slash", "slash_big", "slash_doom":
			var big := fx != "slash"
			var spec := SLASH_BIG if big else SLASH_SMALL
			if fx == "slash_doom":
				spec = SLASH_DOOM
				EVfx.sigil(caster.feet() + Vector2(0, -2), 1.4)
			var d := 0.3 if fx == "slash_doom" else 0.08
			after(d, func() -> void:
				BFx.slash(tp + Vector2(0, 4), spec, 1)
				Sfx.play(&"bl_swish_big" if big else &"bl_swish", -4.0))
			after(d + float(spec.sw) + 0.02, func() -> void:
				BFx.cut(tp, Vector2(1, -0.5), 90.0 if big else 60.0, big)
				Sfx.play(&"bl_cut", -2.0 if big else -6.0)
				if big:
					Fx.hitstop(0.08)
					Fx.shake(0.6, 0.25)
				if fx == "slash_doom":
					EVfx.big_flash(0.3, true)
					Fx.hitstop(0.12)
					Fx.shake(0.9, 0.3))
			hits = [d + float(spec.sw) + 0.03]
			total = d + 0.9
		"slash_all", "slash_all_big":
			var big := fx == "slash_all_big"
			var i := 0
			for a in targets:
				var at: Vector2 = a.center()
				var d := 0.1 + 0.13 * float(i)
				after(d, func() -> void:
					BFx.slash(at + Vector2(0, 4), SLASH_BIG if big else SLASH_SMALL, 1 if i % 2 == 0 else -1)
					Sfx.play(&"bl_swish", -5.0))
				after(d + 0.07, func() -> void:
					BFx.cut(at, Vector2(1, 0.4 if i % 2 == 0 else -0.4), 70.0, big)
					Sfx.play(&"bl_cut", -6.0))
				hits.append(d + 0.08)
				i += 1
			if big:
				after(0.1, func() -> void:
					Fx.shake(0.7, 0.3))
			total = 0.1 + 0.13 * float(targets.size()) + 0.8
		# ── 에스카 (흑백 균열)
		"basic_eska":
			HandFlash.spawn(hand, false)
			after(0.14, func() -> void: rift(tp, 44.0, -0.35, false))
			hits = [0.16]
			total = 0.7
		"rift_small":
			HandFlash.spawn(hand, true)
			Sfx.play(&"bl_charge", -10.0)
			after(0.26, func() -> void: rift(tp, 64.0, -0.3, false))
			hits = [0.28]
			total = 0.9
		"compress":
			var im := Implode.new()
			add(im, tp, false)
			Sfx.play(&"bl_charge", -8.0)
			after(0.4, func() -> void:
				rift(tp, 58.0, 1.2, true)
				EVfx.dark_burst(tp, 30.0))
			hits = [0.42]
			total = 1.0
		"doom":
			var ch := ChargeOrb.new()
			ch.actor = caster
			ch.dur = 0.55
			add(ch, hand, false)
			EVfx.sigil(caster.feet() + Vector2(0, -2), 1.6)
			Sfx.play(&"bl_charge", -4.0)
			after(0.55, func() -> void:
				rift(tp, 124.0, -0.5, true)
				EVfx.dark_burst(tp, 44.0)
				EVfx.shards(tp, 10, 260.0, Vector2(8, 8), 120.0)
				EVfx.big_flash(0.3)
				Fx.hitstop(0.12)
				Fx.shake(0.9, 0.3))
			hits = [0.58]
			total = 1.5
		"blackstar":
			var c := Vector2.ZERO
			for a in targets:
				c += a.center()
			c /= float(maxi(targets.size(), 1))
			var bs := BlackStar.new()
			bs.fall = 0.7
			add(bs, c + Vector2(0, -150), false)
			Sfx.play(&"bl_charge", -6.0)
			var i := 0
			for a in targets:
				var at: Vector2 = a.center()
				var d := 0.72 + 0.09 * float(i)
				after(d, func() -> void:
					rift(at, 72.0, -0.45 + 0.3 * float(i), true)
					EVfx.dark_burst(at, 34.0))
				hits.append(d + 0.02)
				i += 1
			after(0.7, func() -> void:
				EVfx.big_flash(0.4)
				Fx.hitstop(0.14)
				Fx.shake(1.0, 0.4))
			total = 0.72 + 0.09 * float(targets.size()) + 0.9
		"void_gate":
			var g := VoidGate.new()
			add(g, targets[0].feet() + Vector2(-14 * targets[0].facing, -2), false)
			g.target = targets[0]
			Sfx.play(&"bl_unfold", -8.0)
			hits = [0.4]
			total = 1.1
		"leap":
			var a0: TActor = targets[0]
			EVfx.feathers(a0.center(), 6, 90.0, Vector2(8, 14), Vector2.UP)
			EVfx.pixels(a0.center(), 14, 160.0, Vector2.UP, 90.0, 0.4)
			if a0.eska != null:
				EVfx.afterimage(a0.eska.art, 0.35)
			Sfx.play(&"bl_fold", -8.0)
			hits = [0.15]
			total = 0.6
		"seal":
			var c := Vector2.ZERO
			for a in targets:
				c += a.center()
			c /= float(maxi(targets.size(), 1))
			EVfx.sigil(c + Vector2(0, -34), 2.4)
			after(0.25, func() -> void:
				for a in targets:
					var b := Barrier.new()
					add(b, a.center(), false)
				Sfx.play(&"bl_unfold", -6.0))
			hits = [0.4]
			total = 1.1
		"gap":
			var i := 0
			for a in targets:
				var at: Vector2 = a.center()
				var d := 0.12 + 0.1 * float(i)
				after(d, func() -> void:
					BFx.cut(at + Vector2(0, -6), Vector2(1, -0.35), 70.0, false)
					BFx.cut(at + Vector2(4, 5), Vector2(1, 0.3), 56.0, false)
					BFx.ink_sparks(at, 8, 220.0, Vector2.UP)
					Sfx.play(&"bl_cut", -10.0))
				hits.append(d + 0.02)
				i += 1
			total = 0.9
		"stigma":
			var s := Stigma.new()
			add(s, targets[0].center() + Vector2(0, -4), true)
			Sfx.play(&"es_sigil", -10.0)
			hits = [0.3]
			total = 0.9
		"cradle":
			var cr := Cradle.new()
			add(cr, targets[0].feet(), false)
			Sfx.play(&"bl_charge", -6.0)
			after(0.7, func() -> void:
				EMoveFx.blink_in(targets[0].center(), 1)
				EVfx.big_flash(0.3, true)
				Sfx.play(&"bl_unfold", -4.0))
			hits = [0.72]
			total = 1.4
		# ── 불 (이그니스·엠버)
		"basic_fire":
			shoot(hand, tp, 0.22, 0.8)
			hits = [0.24]
			total = 0.7
		"fireball":
			HandFlame.spawn(hand, 0.2)
			after(0.12, func() -> void: shoot(caster.hand(), tp, 0.24, 1.2))
			hits = [0.38]
			total = 0.9
		"fireball_small":
			var cone := FlameCone.new()
			cone.from = hand
			cone.to = tp
			add(cone, Vector2.ZERO, true)
			Sfx.play(&"tn_whoosh", -8.0)
			hits = [0.24]
			total = 0.7
		"whip":
			var w := Whip.new()
			w.from = hand
			w.to = tp
			add(w, Vector2.ZERO, true)
			Sfx.play(&"tn_whoosh", -4.0)
			hits = [0.22]
			total = 0.75
		"focus":
			var f := FocusAura.new()
			f.actor = caster
			add(f, Vector2.ZERO, true)
			Sfx.play(&"tn_buff", -6.0)
			hits = [0.45]
			total = 0.95
		"pillar":
			var p := Pillar.new()
			add(p, targets[0].feet(), true)
			Sfx.play(&"tn_whoosh", -6.0)
			after(0.18, func() -> void:
				Sfx.play(&"tn_fire", -3.0)
				Fx.hitstop(0.06)
				Fx.shake(0.5, 0.25))
			hits = [0.22]
			total = 1.1
		"meteor":
			var m := Meteor.new()
			m.to = tp
			add(m, tp + Vector2(160, -220), true)
			after(0.42, func() -> void:
				Sfx.play(&"tn_fire", -2.0)
				Fx.hitstop(0.08)
				Fx.shake(0.8, 0.3)
				smoke(tp + Vector2(0, 10), 6, 14.0))
			hits = [0.44]
			total = 1.2
		"breath":
			var a := Aura.new()
			a.col = cur.gold
			a.kind = "crit"
			add(a, targets[0].center(), true)
			Sfx.play(&"tn_buff", -6.0)
			hits = [0.35]
			total = 0.9
		"ash_storm":
			var st := AshStorm.new()
			add(st, Vector2.ZERO, true)
			Sfx.play(&"tn_storm", -2.0)
			var i := 0
			for a in targets:
				var at: Vector2 = a.center()
				var d := 0.5 + 0.14 * float(i)
				after(d, func() -> void:
					var b := FireBurst.new()
					b.size = 1.4
					add(b, at, true)
					embers(at, 12, 220.0, Vector2.UP, 100.0, 0.6)
					Fx.shake(0.4, 0.2))
				hits.append(d + 0.02)
				i += 1
			total = 1.7
		"blaze":
			var f := FocusAura.new()
			f.actor = caster
			f.dur = 0.3
			add(f, Vector2.ZERO, true)
			after(0.3, func() -> void:
				var b := Blaze.new()
				add(b, tp, true)
				Sfx.play(&"tn_fire", -1.0)
				Fx.hitstop(0.1)
				Fx.shake(0.8, 0.3)
				smoke(tp + Vector2(0, 12), 8, 16.0))
			hits = [0.5]
			total = 1.3
		"sun_spear":
			var s := SunSpear.new()
			s.to = tp
			add(s, tp + Vector2(0, -170), true)
			Sfx.play(&"tn_charge", -4.0)
			after(0.6, func() -> void:
				Sfx.play(&"tn_spear", 0.0)
				Fx.flash(Color(cur.gold, 0.45), 0.08)
				Fx.hitstop(0.16)
				Fx.shake(1.1, 0.4)
				EVfx.hit_crack(tp, true, -1.0)
				embers(tp, 30, 320.0, Vector2.UP, 180.0, 0.7, Vector2(0, 240))
				smoke(tp + Vector2(0, 14), 8, 18.0))
			hits = [0.64]
			total = 1.8
		"conflagration":
			var xs: Array = []
			for a in targets:
				xs.append(a.feet())
			var gf := GroundFire.new()
			gf.points = xs
			add(gf, Vector2.ZERO, true)
			Sfx.play(&"tn_storm", -3.0)
			var i := 0
			for a in targets:
				var at: Vector2 = a.center()
				var d := 0.5 + 0.1 * float(i)
				after(d, func() -> void:
					var b := FireBurst.new()
					b.size = 1.5
					add(b, at, true)
					Fx.shake(0.5, 0.25))
				hits.append(d + 0.02)
				i += 1
			after(0.5, func() -> void: Sfx.play(&"tn_fire", -1.0))
			total = 1.7
		"stake":
			var sk := Stake.new()
			add(sk, targets[0].feet(), true)
			Sfx.play(&"tn_whoosh", -6.0)
			after(0.4, func() -> void:
				Sfx.play(&"tn_fire", -5.0)
				Fx.shake(0.4, 0.2))
			hits = [0.42]
			total = 1.2
		"kindling":
			var a := Aura.new()
			a.col = cur.flame
			a.kind = "fire"
			add(a, targets[0].center(), true)
			LanternFlash.spawn(caster)
			Sfx.play(&"tn_buff", -6.0)
			hits = [0.35]
			total = 0.9
		"bellows":
			var b := Bellows.new()
			add(b, targets[0].center(), true)
			LanternFlash.spawn(caster)
			Sfx.play(&"tn_whoosh", -8.0)
			hits = [0.35]
			total = 0.9
		"warmth":
			for a in targets:
				var w := Aura.new()
				w.col = HEAL
				w.kind = "heal"
				add(w, a.center(), true)
			LanternFlash.spawn(caster)
			Sfx.play(&"tn_heal", -6.0)
			hits = [0.4]
			total = 1.0
		"blessing":
			var c := Vector2.ZERO
			for a in targets:
				c += a.center()
			c /= float(maxi(targets.size(), 1))
			var sh := LightShaft.new()
			sh.col = cur.hot
			sh.w = 150.0
			add(sh, Vector2(c.x, 0), true)
			after(0.2, func() -> void:
				for a in targets:
					var au := Aura.new()
					au.col = cur.hot
					au.kind = "atk"
					add(au, a.center(), true))
			LanternFlash.spawn(caster)
			Sfx.play(&"tn_bless", -4.0)
			hits = [0.4]
			total = 1.1
		"fire_wall":
			var fw := FireWall.new()
			var c := Vector2.ZERO
			for a in targets:
				c += a.center()
			c /= float(maxi(targets.size(), 1))
			add(fw, c + Vector2(44, 10), true)
			LanternFlash.spawn(caster)
			Sfx.play(&"tn_whoosh", -5.0)
			hits = [0.4]
			total = 1.0
		"god_descent":
			var g := GodDescent.new()
			add(g, targets[0].feet(), true)
			LanternFlash.spawn(caster)
			Sfx.play(&"tn_charge", -3.0)
			after(0.55, func() -> void:
				Fx.flash(Color(cur.flame, 0.35), 0.1)
				Fx.shake(0.6, 0.3)
				Sfx.play(&"tn_fire", -3.0))
			hits = [0.6]
			total = 1.5
		"share_ember":
			var str := SparkStream.new()
			str.from = caster.prop_pos()
			str.to = targets[0].center()
			add(str, Vector2.ZERO, true)
			LanternFlash.spawn(caster)
			Sfx.play(&"tn_buff", -6.0)
			hits = [0.5]
			total = 0.9
		"sun_blessing":
			var c := Vector2.ZERO
			for a in targets:
				c += a.center()
			c /= float(maxi(targets.size(), 1))
			var sh := LightShaft.new()
			sh.col = cur.gold
			sh.w = 220.0
			sh.rays = true
			add(sh, Vector2(c.x, 0), true)
			after(0.25, func() -> void:
				for a in targets:
					var au := Aura.new()
					au.col = cur.gold
					au.kind = "crit"
					add(au, a.center(), true))
			LanternFlash.spawn(caster)
			Sfx.play(&"tn_bless", -2.0)
			hits = [0.5]
			total = 1.3
		# ── 적
		"enemy_attack", "enemy_heavy":
			var heavy := fx == "enemy_heavy"
			var sl := EnemySlash.new()
			sl.heavy = heavy
			sl.kind = String(caster.unit.data.get("art", caster.unit.id))
			add(sl, tp, false)
			Sfx.play(&"bl_swish_big" if heavy else &"bl_swish", -6.0)
			hits = [0.26 if heavy else 0.2]
			total = 0.9 if heavy else 0.7
		"enemy_aoe":
			var sw := Shockwave.new()
			add(sw, caster.feet(), false)
			Sfx.play(&"bl_swish_big", -4.0)
			var i := 0
			for a in targets:
				hits.append(0.3 + 0.06 * float(i))
				i += 1
			total = 1.0
		"enemy_buff":
			var a := Aura.new()
			a.col = cur.flame
			a.kind = "atk"
			add(a, caster.center(), true)
			Sfx.play(&"tn_buff", -8.0)
			hits = [0.4]
			total = 0.9
		# ── 단계 F-2 새 의도 (피해 없는 것): 의도 알약과 같은 색·모양의 표식 (review_H §2.2)
		"enemy_guard", "enemy_cover", "enemy_purge":
			var k := fx.substr(6)
			intent_sign(caster, k)
			Sfx.play(&"tn_guard" if k != "purge" else &"tn_dispel", -6.0)
			hits = [0.35]
			total = 0.9
		"enemy_rally", "enemy_summon":
			var k := fx.substr(6)
			intent_sign(caster, k)
			Sfx.play(&"tn_summon" if k == "summon" else &"tn_buff", -6.0)
			var i := 0
			for t in targets:
				if t != caster:
					TFx.after(0.15 + 0.08 * float(i), func() -> void:
						if is_instance_valid(t):
							intent_sign(t, k))
				hits.append(0.35 + 0.08 * float(i))
				i += 1
			total = 1.0
		"enemy_weaken", "enemy_seal", "enemy_scatter":
			var k := fx.substr(6)
			var sw := Shockwave.new()
			sw.col = TTheme.INTENT_COL.get(k, ASH)
			add(sw, caster.feet(), false)
			Sfx.play(&"tn_scatter" if k == "scatter" else (&"tn_seal" if k == "seal" else &"tn_dispel"), -6.0)
			var i := 0
			for t in targets:
				hits.append(0.3 + 0.06 * float(i))
				i += 1
			total = 1.0
		_:
			hits = [0.2]
			total = 0.6
	return {"hits": hits, "total": total}


## 하르페의 참격 모양 (실시간 데모 BEska의 휘두름과 같은 사전 — r 반지름 · w 띠 폭 · a0→a1 각(도) · sq 납작함 · rot 기울기 · sw 휘두르는 시간)
const SLASH_SMALL := {"sw": 0.05, "a0": 175.0, "a1": 365.0, "r": 60.0, "w": 20.0, "sq": 0.32, "rot": 36.0}
const SLASH_BIG := {"sw": 0.06, "a0": 172.0, "a1": 372.0, "r": 96.0, "w": 30.0, "sq": 0.3, "rot": 30.0, "heavy": true}
const SLASH_DOOM := {"sw": 0.07, "a0": 105.0, "a1": -100.0, "r": 130.0, "w": 36.0, "sq": 0.22, "rot": 0.0, "heavy": true}


## 저주(디버프·징표를 거는 술사의 마법): 적 둘레를 도는 어두운 고리 + 위에서 내려 찍히는 문양 + 흩어지는 조각 (속성 색)
class Hex extends PVfx.Base:
	var _c: Dictionary = TFx.cur

	func _ready() -> void:
		life = 0.8
		z_index = 8

	func _tick(_d: float) -> void:
		if t < 0.5 and randf() < 0.8:
			var an := randf() * TAU
			PParticles.get_layer(true).spawn(global_position + Vector2(cos(an) * 20.0, sin(an) * 10.0), Vector2(randf_range(-10, 10), -randf_range(20, 60)), Vector2.ZERO, 0.45, randf_range(1.0, 2.0), _c.hot, Color(_c.deep, 0.0), 0, 1.0)

	func _paint() -> void:
		var x := k()
		var drop := 1.0 - pow(1.0 - minf(x * 2.5, 1.0), 3.0)
		var a := 1.0 - smoothstep(0.5, 1.0, x)
		pd.glow(Vector2(0, -6), 18.0 + 10.0 * drop, Color(_c.deep, 0.35 * a), 0.0)
		# 고리 둘 (반대로 돎)
		for i in 2:
			var r := 16.0 + 8.0 * float(i)
			var pts := PackedVector2Array()
			for j in 25:
				var an := TAU * float(j) / 24.0 + t * (4.0 if i == 0 else -3.0)
				pts.append(Vector2(cos(an) * r, 2.0 + sin(an) * r * 0.4))
			pd.draw_polyline(pts, Color(_c.dark, 0.7 * a), 2.4)
			pd.draw_polyline(pts, Color(_c.flame, 0.9 * a), 1.0)
		# 내려 찍히는 문양 (네 갈래 별 + 작은 고리)
		var y := -40.0 + 34.0 * drop
		EVfx.star4(pd, Vector2(0, y), 9.0 * drop, 0.785, Color(_c.core, a), Color(_c.flame, 0.0))
		pd.draw_arc(Vector2(0, y), 6.0 + 4.0 * drop, 0.0, TAU, 16, Color(_c.hot, 0.9 * a), 1.0)


## 흑백 균열 (실시간 데모의 것). heavy면 더 길고 소리도 크다
static func rift(at: Vector2, len: float, ang: float, heavy: bool) -> void:
	var r := BFx.Rift.new()
	r.len = len
	r.ang = ang
	add(r, at, false)
	Sfx.play(&"bl_rift", 0.0 if heavy else -6.0)
	if not heavy:
		Fx.hitstop(0.05)
		Fx.shake(0.4, 0.2)


## 불덩이 발사: from → to, 닿으면 터진다
static func shoot(from: Vector2, to: Vector2, dur: float, size: float) -> void:
	var p := Fireball.new()
	p.from = from
	p.to = to
	p.dur = dur
	p.size = size
	add(p, from, true)
	Sfx.play(&"tn_whoosh", -10.0)


# ═══════════════════════════════════════════════════════════
# 불
# ═══════════════════════════════════════════════════════════

## 불꽃 한 송이 (타오르는 혀): base에서 dir로 h만큼, 폭 w. 심 → 금 → 주홍 세 겹
static func tongue(pd: PDraw, base: Vector2, dir: Vector2, h: float, w: float, a: float, wob := 0.0, c: Dictionary = {}) -> void:
	if c.is_empty():
		c = cur
	var side := dir.orthogonal()
	var tip := base + dir * h + side * wob
	var outer := PackedVector2Array([base - side * w, base + dir * h * 0.35 - side * w * 0.9, tip, base + dir * h * 0.35 + side * w * 0.9, base + side * w])
	pd.draw_colored_polygon(outer, Color(c.deep, 0.85 * a))
	var mid := PackedVector2Array([base - side * w * 0.6, base + dir * h * 0.3 - side * w * 0.55, base + dir * h * 0.72 + side * wob * 0.7, base + dir * h * 0.3 + side * w * 0.55, base + side * w * 0.6])
	pd.draw_colored_polygon(mid, Color(c.flame, 0.95 * a))
	var inner := PackedVector2Array([base - side * w * 0.3, base + dir * h * 0.25 - side * w * 0.28, base + dir * h * 0.45 + side * wob * 0.4, base + dir * h * 0.25 + side * w * 0.28, base + side * w * 0.3])
	pd.draw_colored_polygon(inner, Color(c.hot, a))
	pd.draw_colored_polygon(PackedVector2Array([base - side * w * 0.14, base + dir * h * 0.22, base + side * w * 0.14]), Color(c.core, a))


## 터지는 불: 심 번짐 + 사방으로 뻗는 불꽃 혀 + 고리
class FireBurst extends PVfx.Base:
	var _c: Dictionary = TFx.cur ## 만들어지는 순간의 속성 색 (뒤에 다른 속성이 시전돼도 안 바뀜)
	var size := 1.0
	var _seed := 0

	func _ready() -> void:
		life = 0.42 * (0.7 + 0.3 * size)
		z_index = 8
		_seed = randi()

	func _paint() -> void:
		var x := k()
		var a := 1.0 - x
		var grow := 1.0 - pow(1.0 - minf(x * 1.6, 1.0), 2.0)
		var s := size
		pd.glow(Vector2.ZERO, (18.0 + 14.0 * grow) * s, Color(_c.flame, 0.5 * a), 0.0)
		pd.glow(Vector2.ZERO, (8.0 + 6.0 * grow) * s, Color(_c.core, 0.8 * a), 0.0)
		var n := 7
		for i in n:
			var an := TAU * float(i) / float(n) + EVfx.hash01(_seed + i) * 0.6 - 0.3
			var d := Vector2.from_angle(an)
			var h := (10.0 + 14.0 * EVfx.hash01(_seed * 3 + i)) * s * (0.4 + 0.6 * grow)
			TFx.tongue(pd, d * 4.0 * s, d, h, 3.4 * s * (1.0 - 0.4 * x), a, sin(t * 30.0 + float(i)) * 2.0, _c)
		pd.draw_arc(Vector2.ZERO, (10.0 + 26.0 * grow) * s, 0.0, TAU, 28, Color(_c.hot, 0.7 * a * a), 1.6 * s)


## 날아가는 불덩이 (꼬리를 끌며, 닿으면 터짐)
class Fireball extends PVfx.Base:
	var _c: Dictionary = TFx.cur ## 만들어지는 순간의 속성 색 (뒤에 다른 속성이 시전돼도 안 바뀜)
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var dur := 0.25
	var size := 1.0
	var _hist := PackedVector2Array()
	var _done := false

	func _ready() -> void:
		life = dur + 0.05 # 닿은 뒤 한 프레임 남아 터뜨린다 (예전 _exit_tree에서 터뜨리면 장면을 닫을 때 "Parent node is busy" 오류)
		z_index = 9

	func _tick(_d: float) -> void:
		if _done:
			return
		var f := minf(t / dur, 1.0)
		var p := from.lerp(to, f) + Vector2(0, -sin(f * PI) * 18.0 * size)
		global_position = p
		_hist.append(p)
		if _hist.size() > 7:
			_hist.remove_at(0)
		if randf() < 0.6:
			PParticles.get_layer(true).spawn(p, Vector2(randf_range(-20, 20), randf_range(-40, 10)), Vector2(0, 40), 0.3, randf_range(1.0, 2.0) * size, _c.hot, Color(_c.deep, 0.0), 0, 2.0)
		if f >= 1.0:
			_done = true
			var b := FireBurst.new()
			b._c = _c
			b.size = size
			TFx.add(b, to, true)
			TFx.embers(to, int(8 * size), 180.0 * size, Vector2.UP, 120.0, 0.45, Vector2(0, 220))
			Sfx.play(&"tn_fire", -8.0 + 3.0 * size)

	func _paint() -> void:
		if _done:
			return
		var inv := global_transform.affine_inverse()
		for i in range(1, _hist.size()):
			var f := float(i) / float(_hist.size())
			pd.line2(inv * _hist[i - 1], inv * _hist[i], Color(_c.deep, 0.3 * f), Color(_c.flame, 0.8 * f), 1.0 * size, 3.0 * size)
		pd.glow(Vector2.ZERO, 9.0 * size, Color(_c.flame, 0.6), 0.0)
		pd.draw_circle(Vector2.ZERO, 3.4 * size, _c.hot)
		pd.draw_circle(Vector2.ZERO, 1.8 * size, _c.core)


## 손에 잠깐 모이는 불 (시전 준비)
class HandFlame extends PVfx.Base:
	var _c: Dictionary = TFx.cur ## 만들어지는 순간의 속성 색 (뒤에 다른 속성이 시전돼도 안 바뀜)
	static func spawn(at: Vector2, dur: float) -> void:
		var h := HandFlame.new()
		h.life = dur
		TFx.add(h, at, true)

	func _paint() -> void:
		var x := k()
		var g := 1.0 - pow(1.0 - x, 2.0)
		pd.glow(Vector2.ZERO, 6.0 + 10.0 * g, Color(_c.flame, 0.5), 0.0)
		for i in 4:
			var an := t * 14.0 + float(i) * TAU / 4.0
			var p := Vector2.from_angle(an) * (10.0 * (1.0 - g) + 2.0)
			pd.draw_circle(p, 1.2, _c.hot)
		pd.draw_circle(Vector2.ZERO, 2.0 + 2.0 * g, _c.core)


## 등불이 환해짐 (엠버가 보조 마법을 걸 때)
class LanternFlash extends PVfx.Base:
	var _c: Dictionary = TFx.cur ## 만들어지는 순간의 속성 색 (뒤에 다른 속성이 시전돼도 안 바뀜)
	var actor: TActor

	static func spawn(a: TActor) -> void:
		if a.witch != null and a.witch.kind == "ember":
			var l := LanternFlash.new()
			l.actor = a
			l.life = 0.6
			TFx.add(l, a.prop_pos(), true)

	func _tick(_d: float) -> void:
		if is_instance_valid(actor):
			global_position = actor.prop_pos()

	func _paint() -> void:
		var x := k()
		var a := sin(x * PI)
		pd.glow(Vector2.ZERO, 14.0 + 10.0 * a, Color(_c.hot, 0.45 * a), 0.0)
		for i in 6:
			var an := -t * 6.0 + float(i) * TAU / 6.0
			var p := Vector2.from_angle(an) * (6.0 + 8.0 * x)
			pd.draw_rect(Rect2(p - Vector2(0.6, 0.6), Vector2(1.2, 1.2)), Color(_c.core, a))


## 입김: 부채꼴 불길이 from에서 to로 훅 뻗는다
class FlameCone extends PVfx.Base:
	var _c: Dictionary = TFx.cur ## 만들어지는 순간의 속성 색 (뒤에 다른 속성이 시전돼도 안 바뀜)
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var _done := false

	func _ready() -> void:
		life = 0.45
		z_index = 9

	func _tick(_d: float) -> void:
		if t >= 0.24 and not _done:
			_done = true
			var b := FireBurst.new()
			b.size = 0.8
			TFx.add(b, to, true)
			Sfx.play(&"tn_fire", -9.0)

	func _paint() -> void:
		var x := k()
		var reach := 1.0 - pow(1.0 - minf(t / 0.24, 1.0), 2.0)
		var a := 1.0 - smoothstep(0.5, 1.0, x)
		var d := (to - from).normalized()
		var len := from.distance_to(to) * reach
		var side := d.orthogonal()
		var n := 6
		for i in n:
			var f := (float(i) + 0.5) / float(n)
			var base := from + d * len * f
			var w := 2.0 + 7.0 * f
			var wob := sin(t * 28.0 + float(i) * 1.7) * 3.0 * f
			TFx.tongue(pd, base + side * wob, d, 12.0 + 10.0 * f, w, a * (1.0 - 0.3 * f), 0.0, _c)
		pd.glow(from + d * len * 0.5, len * 0.3 + 6.0, Color(_c.flame, 0.3 * a), 0.0)


## 불꽃 채찍: 손에서 표적까지 휘감기는 띠
class Whip extends PVfx.Base:
	var _c: Dictionary = TFx.cur ## 만들어지는 순간의 속성 색 (뒤에 다른 속성이 시전돼도 안 바뀜)
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var _done := false

	func _ready() -> void:
		life = 0.5
		z_index = 9

	func _tick(_d: float) -> void:
		if t >= 0.22 and not _done:
			_done = true
			var b := FireBurst.new()
			b.size = 1.0
			TFx.add(b, to, true)
			TFx.embers(to, 10, 200.0, Vector2.UP, 90.0, 0.45)
			Sfx.play(&"tn_fire", -6.0)

	func _paint() -> void:
		var x := k()
		var reach := 1.0 - pow(1.0 - minf(t / 0.22, 1.0), 3.0)
		var a := 1.0 - smoothstep(0.3, 1.0, x)
		var n := 18
		var l := PackedVector2Array()
		var r := PackedVector2Array()
		var pts := PackedVector2Array()
		for i in n + 1:
			var f := float(i) / float(n)
			var p := from.lerp(to, f * reach)
			var arc := sin(f * PI) * 40.0 * (1.0 - reach * 0.6) + sin(f * 9.0 - t * 30.0) * 5.0 * reach
			p += Vector2(0, -arc)
			pts.append(p)
		for i in n + 1:
			var a0 := pts[maxi(i - 1, 0)]
			var b0 := pts[mini(i + 1, n)]
			var nrm := (b0 - a0).normalized().orthogonal()
			var w := (1.0 + 2.5 * (1.0 - float(i) / float(n))) * a
			l.append(pts[i] + nrm * w)
			r.append(pts[i] - nrm * w)
		pd.strip_grad(l, r, Color(_c.deep, 0.8 * a), Color(_c.hot, a))
		pd.draw_polyline(pts, Color(_c.core, 0.9 * a), 0.8)
		var tip := pts[n]
		pd.glow(tip, 8.0, Color(_c.flame, 0.5 * a), 0.0)


## 불기둥: 바닥 빛 → 솟구치는 기둥 (세 겹 혀) → 사그라듦
class Pillar extends PVfx.Base:
	var _c: Dictionary = TFx.cur ## 만들어지는 순간의 속성 색 (뒤에 다른 속성이 시전돼도 안 바뀜)
	var h := 110.0
	var w := 14.0

	func _ready() -> void:
		life = 1.0
		z_index = 8

	func _tick(_d: float) -> void:
		if t > 0.18 and t < 0.6 and randf() < 0.7:
			var p := global_position + Vector2(randf_range(-w, w), -randf_range(0.0, h * 0.8))
			PParticles.get_layer(true).spawn(p, Vector2(randf_range(-30, 30), -randf_range(60, 160)), Vector2(0, 40), 0.5, randf_range(1.2, 2.4), _c.hot, Color(_c.deep, 0.0), 1, 1.5)

	func _paint() -> void:
		var pre := smoothstep(0.0, 0.18, t)
		var rise := smoothstep(0.18, 0.34, t)
		var fade := 1.0 - smoothstep(0.6, 1.0, t)
		# 바닥 원 (예고 → 타오름)
		pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
		pd.glow(Vector2.ZERO, (10.0 + 18.0 * pre) * (1.0 + 0.3 * rise), Color(_c.flame, 0.6 * fade), 0.0)
		pd.draw_arc(Vector2.ZERO, 14.0 + 8.0 * pre, 0.0, TAU, 28, Color(_c.hot, 0.9 * fade), 1.4)
		pd.draw_set_transform(Vector2.ZERO)
		if rise <= 0.0:
			return
		var hh := h * rise
		var ww := w * (0.6 + 0.4 * rise) * (0.6 + 0.4 * fade)
		pd.glow(Vector2(0, -hh * 0.5), hh * 0.35 + ww, Color(_c.flame, 0.3 * fade), 0.0)
		for i in 5:
			var ox := (float(i) - 2.0) * ww * 0.45
			var ph := t * 18.0 + float(i) * 1.3
			var th := hh * (0.75 + 0.25 * sin(ph)) * (1.0 - 0.1 * absf(float(i) - 2.0))
			TFx.tongue(pd, Vector2(ox, 0), Vector2.UP, th, ww * (0.5 - 0.08 * absf(float(i) - 2.0)), fade, sin(ph * 0.7) * 4.0, _c)
		# 심 (흰 줄기)
		pd.line2(Vector2(0, 0), Vector2(sin(t * 20.0) * 2.0, -hh * 0.7), Color(_c.core, fade), Color(_c.core, 0.0), ww * 0.5, 1.0)


## 유성: 비스듬히 떨어지는 큰 불덩이 → 바닥에서 터짐 + 땅 고리
class Meteor extends PVfx.Base:
	var _c: Dictionary = TFx.cur ## 만들어지는 순간의 속성 색 (뒤에 다른 속성이 시전돼도 안 바뀜)
	var to := Vector2.ZERO
	var _start := Vector2.ZERO
	var _hit := false
	var _hist := PackedVector2Array()

	func _ready() -> void:
		life = 1.0
		z_index = 9
		_start = global_position

	func _tick(_d: float) -> void:
		if t < 0.42:
			var f := pow(t / 0.42, 1.4)
			global_position = _start.lerp(to, f)
			_hist.append(global_position)
			if _hist.size() > 9:
				_hist.remove_at(0)
			for i in 2:
				PParticles.get_layer(true).spawn(global_position + Vector2(randf_range(-4, 4), randf_range(-4, 4)), Vector2(randf_range(-30, 30), randf_range(-30, 30)), Vector2.ZERO, 0.35, randf_range(1.5, 3.0), _c.hot, Color(_c.deep, 0.0), 0, 2.0)
		elif not _hit:
			_hit = true
			global_position = to
			var b := FireBurst.new()
			b.size = 2.0
			TFx.add(b, to, true)
			TFx.embers(to, 26, 300.0, Vector2.UP, 180.0, 0.7, Vector2(0, 260))

	func _paint() -> void:
		if t < 0.42:
			var inv := global_transform.affine_inverse()
			for i in range(1, _hist.size()):
				var f := float(i) / float(_hist.size())
				pd.line2(inv * _hist[i - 1], inv * _hist[i], Color(_c.deep, 0.2 * f), Color(_c.flame, 0.9 * f), 2.0, 7.0)
			pd.glow(Vector2.ZERO, 16.0, Color(_c.flame, 0.6), 0.0)
			pd.draw_circle(Vector2.ZERO, 6.0, _c.hot)
			pd.draw_circle(Vector2(-1, -1), 3.2, _c.core)
			return
		var x := (t - 0.42) / (life - 0.42)
		var a := 1.0 - x
		pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.32))
		pd.draw_arc(Vector2.ZERO, 10.0 + 60.0 * (1.0 - pow(1.0 - x, 2.0)), 0.0, TAU, 36, Color(_c.hot, 0.8 * a), 2.0)
		pd.glow(Vector2.ZERO, 30.0, Color(_c.flame, 0.4 * a), 0.0)
		pd.draw_set_transform(Vector2.ZERO)


## 재의 폭풍: 화면을 가로지르는 재바람 + 적 진영 위를 쓸어가는 불길 띠
class AshStorm extends PVfx.Base:
	var _c: Dictionary = TFx.cur ## 만들어지는 순간의 속성 색 (뒤에 다른 속성이 시전돼도 안 바뀜)
	var _bits: Array = []

	func _ready() -> void:
		life = 1.5
		z_index = 6
		for i in 90:
			_bits.append([Vector2(randf_range(0, 760), randf_range(120, 350)), randf_range(260.0, 520.0), randf_range(0.8, 2.2), randf() < 0.3])

	func _paint() -> void:
		var x := k()
		var a := sin(minf(x * 1.3, 1.0) * PI)
		pd.rect_grad(TTheme.screen(), Color(_c.dark, 0.0), Color(_c.dark, 0.35 * a))
		for b: Array in _bits:
			var p: Vector2 = (b[0] as Vector2) - Vector2(float(b[1]) * t, sin(t * 3.0 + float(b[0].y)) * 10.0)
			if p.x < -10.0:
				continue
			var ember: bool = b[3]
			var sz: float = b[2]
			pd.line2(p, p + Vector2(6.0 + sz * 4.0, 0.5), Color(_c.hot if ember else ASH, 0.0), Color(_c.core if ember else ASH, 0.8 * a), sz * 0.5, sz)
		# 불길 띠 세 줄 (적 진영: x 380~640)
		for i in 3:
			var ph := clampf((t - 0.3 - 0.14 * float(i)) / 0.5, 0.0, 1.0)
			if ph <= 0.0 or ph >= 1.0:
				continue
			var y := 300.0 - 36.0 * float(i)
			var head := 700.0 - 420.0 * ph
			var l := PackedVector2Array()
			var r := PackedVector2Array()
			for j in 12:
				var f := float(j) / 11.0
				var px := head + f * 160.0
				var w := (3.0 + 10.0 * sin(f * PI)) * (1.0 - ph * 0.5)
				var wob := sin(t * 25.0 + f * 12.0) * 3.0
				l.append(Vector2(px, y - w + wob))
				r.append(Vector2(px, y + w * 0.4 + wob))
			pd.strip_grad(l, r, Color(_c.core, 0.9), Color(_c.deep, 0.0))
			pd.glow(Vector2(head + 10.0, y), 22.0, Color(_c.flame, 0.5), 0.0)


## 폭염: 표적 위에서 크게 피어나는 불꽃 (세 겹 꽃잎)
class Blaze extends PVfx.Base:
	var _c: Dictionary = TFx.cur ## 만들어지는 순간의 속성 색 (뒤에 다른 속성이 시전돼도 안 바뀜)
	func _ready() -> void:
		life = 0.8
		z_index = 9

	func _tick(_d: float) -> void:
		if t < 0.4 and randf() < 0.8:
			PParticles.get_layer(true).spawn(global_position + Vector2(randf_range(-14, 14), randf_range(-10, 10)), Vector2(randf_range(-40, 40), -randf_range(80, 220)), Vector2(0, 60), 0.6, randf_range(1.4, 2.8), _c.hot, Color(_c.deep, 0.0), 1, 1.5)

	func _paint() -> void:
		var x := k()
		var grow := 1.0 - pow(1.0 - minf(x * 2.2, 1.0), 2.0)
		var a := 1.0 - smoothstep(0.45, 1.0, x)
		pd.glow(Vector2(0, -10), 36.0 * grow + 10.0, Color(_c.flame, 0.45 * a), 0.0)
		pd.glow(Vector2(0, -6), 14.0 * grow + 4.0, Color(_c.core, 0.8 * a), 0.0)
		for ring in 2:
			var n := 8 + ring * 4
			for i in n:
				var an := TAU * float(i) / float(n) + float(ring) * 0.3 + t * (1.0 - 2.0 * float(ring))
				var d := Vector2.from_angle(an)
				var h := (16.0 + 18.0 * (1.0 - float(ring) * 0.5)) * grow * (0.8 + 0.2 * sin(t * 25.0 + float(i)))
				TFx.tongue(pd, d * (6.0 + 10.0 * float(ring)) * grow, d, h, 4.0 * (1.0 - 0.3 * float(ring)), a * (1.0 - 0.3 * float(ring)), sin(t * 30.0 + float(i) * 2.0) * 2.5, _c)
		pd.draw_arc(Vector2(0, -6), 20.0 + 50.0 * grow, 0.0, TAU, 40, Color(_c.hot, 0.8 * a * a), 2.0)


## 태양의 창: 하늘에서 금빛 창이 맺혀 떨어지고, 꽂히는 순간 빛살이 사방으로
class SunSpear extends PVfx.Base:
	var _c: Dictionary = TFx.cur ## 만들어지는 순간의 속성 색 (뒤에 다른 속성이 시전돼도 안 바뀜)
	var to := Vector2.ZERO
	var _top := Vector2.ZERO

	func _ready() -> void:
		life = 1.6
		z_index = 9
		_top = global_position
		global_position = Vector2.ZERO

	func _tick(_d: float) -> void:
		if t < 0.6 and randf() < 0.9:
			var p := _top + Vector2(randf_range(-30, 30), randf_range(-20, 20))
			var v := (_top - p) * 3.0
			PParticles.get_layer(true).spawn(p, v, Vector2.ZERO, 0.3, randf_range(1.0, 2.0), _c.gold, Color(_c.hot, 0.0), 1, 0.0)

	func _paint() -> void:
		var charge := smoothstep(0.0, 0.5, t)
		var drop := clampf((t - 0.5) / 0.1, 0.0, 1.0)
		var after := clampf((t - 0.6) / 0.9, 0.0, 1.0)
		# 하늘이 따뜻해짐
		pd.rect_grad(Rect2(TTheme.left(), -TTheme.ofs.y, TTheme.view.x, 200 + TTheme.ofs.y), Color(_c.gold, 0.22 * charge * (1.0 - after)), Color(_c.gold, 0.0))
		var tip := _top.lerp(to, drop)
		var tail := tip + Vector2(0, -90.0 - 60.0 * charge) * (1.0 - after)
		if after < 1.0:
			var a := 1.0 - after
			# 창: 먹 테두리 → 금 → 흰 심
			pd.line2(tail, tip, Color(_c.dark, 0.0), Color(_c.dark, 0.6 * a), 1.0, 7.0 * charge)
			pd.line2(tail, tip, Color(_c.gold, 0.0), Color(_c.gold, a), 0.6, 5.0 * charge)
			pd.line2(tail, tip, Color(_c.core, 0.0), Color(_c.core, a), 0.3, 2.2 * charge)
			pd.glow(tip, 12.0 + 10.0 * charge, Color(_c.gold, 0.6 * a), 0.0)
			# 창끝 둘레의 도는 금빛 조각
			for i in 6:
				var an := t * 12.0 + float(i) * TAU / 6.0
				var r := 10.0 + 6.0 * charge
				var p := tip + Vector2(cos(an), sin(an) * 0.5) * r
				pd.draw_rect(Rect2(p - Vector2(0.7, 0.7), Vector2(1.4, 1.4)), Color(_c.core, a * charge))
		if drop >= 1.0:
			# 꽂힘: 빛살 + 고리 + 땅의 금빛
			var g := 1.0 - pow(1.0 - minf(after * 1.6, 1.0), 2.0)
			var a2 := 1.0 - after
			pd.glow(to, 40.0 * g + 10.0, Color(_c.gold, 0.6 * a2), 0.0)
			pd.glow(to, 16.0 * g + 4.0, Color(_c.core, 0.9 * a2), 0.0)
			for i in 12:
				var an := TAU * float(i) / 12.0 + 0.2
				var d := Vector2.from_angle(an)
				var len := (30.0 + 70.0 * g) * (0.6 + 0.4 * EVfx.hash01(i * 7))
				pd.line2(to + d * 6.0, to + d * len, Color(_c.core, a2), Color(_c.gold, 0.0), 3.0 * a2, 0.3)
			pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.32))
			var tc := Vector2(to.x, to.y / 0.32)
			pd.draw_arc(tc, 12.0 + 90.0 * g, 0.0, TAU, 40, Color(_c.gold, 0.9 * a2 * a2), 2.4)
			pd.draw_set_transform(Vector2.ZERO)


## 대화재: 땅을 따라 불이 달려가 적들 발밑에서 불벽이 선다
class GroundFire extends PVfx.Base:
	var _c: Dictionary = TFx.cur ## 만들어지는 순간의 속성 색 (뒤에 다른 속성이 시전돼도 안 바뀜)
	var points: Array = []

	func _ready() -> void:
		life = 1.6
		z_index = 8

	func _tick(_d: float) -> void:
		if t > 0.4 and t < 1.0 and randf() < 0.9:
			var p: Vector2 = points[randi_range(0, points.size() - 1)]
			p += Vector2(randf_range(-26, 26), -randf_range(0, 30))
			PParticles.get_layer(true).spawn(p, Vector2(randf_range(-20, 20), -randf_range(60, 150)), Vector2(0, 40), 0.6, randf_range(1.2, 2.4), _c.hot, Color(_c.deep, 0.0), 1, 1.5)

	func _paint() -> void:
		var run := smoothstep(0.0, 0.4, t)
		var wall := smoothstep(0.4, 0.62, t)
		var fade := 1.0 - smoothstep(0.95, 1.6, t)
		var x0 := 360.0
		var x1 := 640.0
		var head := lerpf(x0, x1 + 20.0, run)
		# 달리는 불줄 (바닥)
		for p: Vector2 in points:
			pass
		var ys := 300.0
		pd.line2(Vector2(x0, ys), Vector2(head, ys - 8.0), Color(_c.deep, 0.6 * fade), Color(_c.core, fade), 2.0, 5.0)
		pd.glow(Vector2(head, ys - 6.0), 14.0, Color(_c.flame, 0.6 * fade * (1.0 - wall)), 0.0)
		if wall <= 0.0:
			return
		for p: Vector2 in points:
			var hh := (70.0 + 20.0 * sin(t * 4.0 + p.x)) * wall
			pd.glow(p + Vector2(0, -hh * 0.4), hh * 0.4 + 10.0, Color(_c.flame, 0.3 * fade), 0.0)
			for i in 6:
				var ox := (float(i) - 2.5) * 9.0
				var ph := t * 16.0 + float(i) * 1.1 + p.x * 0.1
				TFx.tongue(pd, p + Vector2(ox, 0), Vector2.UP, hh * (0.7 + 0.3 * sin(ph)), 5.0, fade, sin(ph * 0.6) * 4.0, _c)


## 화형대: 표적 뒤에 검은 기둥이 솟고 불이 타고 오른다
class Stake extends PVfx.Base:
	var _c: Dictionary = TFx.cur ## 만들어지는 순간의 속성 색 (뒤에 다른 속성이 시전돼도 안 바뀜)
	func _ready() -> void:
		life = 1.2
		z_index = 8

	func _tick(_d: float) -> void:
		if t > 0.3 and t < 0.9 and randf() < 0.6:
			PParticles.get_layer(true).spawn(global_position + Vector2(randf_range(-8, 8), -randf_range(10, 60)), Vector2(randf_range(-20, 20), -randf_range(50, 120)), Vector2(0, 40), 0.5, randf_range(1.0, 2.0), _c.hot, Color(_c.deep, 0.0), 0, 1.5)

	func _paint() -> void:
		var rise := smoothstep(0.0, 0.3, t)
		var burn := smoothstep(0.3, 0.5, t)
		var fade := 1.0 - smoothstep(0.85, 1.2, t)
		var h := 64.0 * rise
		pd.draw_line(Vector2(0, 0), Vector2(0, -h), Color(INK, fade), 6.0)
		pd.draw_line(Vector2(0, 0), Vector2(0, -h), Color("#4a3328", fade), 4.0)
		pd.draw_line(Vector2(-12.0 * rise, -h * 0.72), Vector2(12.0 * rise, -h * 0.72), Color(INK, fade), 5.0)
		pd.draw_line(Vector2(-12.0 * rise, -h * 0.72), Vector2(12.0 * rise, -h * 0.72), Color("#4a3328", fade), 3.0)
		pd.draw_line(Vector2(-1.2, 0), Vector2(-1.2, -h), Color("#6b4a3a", fade), 1.0)
		pd.glow(Vector2(0, -h * 0.5), 10.0 * burn + 2.0, Color(_c.flame, 0.3 * fade), 0.0)
		if burn <= 0.0:
			return
		pd.glow(Vector2(0, -h * 0.4), 20.0 * burn + 6.0, Color(_c.flame, 0.4 * fade), 0.0)
		for i in 5:
			var ox := (float(i) - 2.0) * 5.0
			var ph := t * 17.0 + float(i) * 1.9
			TFx.tongue(pd, Vector2(ox, -2.0), Vector2.UP, (26.0 + 14.0 * sin(ph)) * burn, 3.6, fade, sin(ph * 0.5) * 3.0, _c)
		for i in 3: # 가로대에서도
			var ox := (float(i) - 1.0) * 10.0
			TFx.tongue(pd, Vector2(ox, -h * 0.72), Vector2.UP, (14.0 + 8.0 * sin(t * 15.0 + float(i))) * burn, 2.6, fade * 0.9, 0.0, _c)


## 불의 신 강림: 아군 뒤로 거대한 불의 형상(눈 둘)이 솟아오른다
class GodDescent extends PVfx.Base:
	var _c: Dictionary = TFx.cur ## 만들어지는 순간의 속성 색 (뒤에 다른 속성이 시전돼도 안 바뀜)
	func _ready() -> void:
		life = 1.5
		z_index = -3

	func _tick(_d: float) -> void:
		if t < 1.0 and randf() < 0.9:
			PParticles.get_layer(true).spawn(global_position + Vector2(randf_range(-30, 30), -randf_range(0, 60)), Vector2(randf_range(-30, 30), -randf_range(80, 200)), Vector2(0, 30), 0.7, randf_range(1.5, 3.0), _c.hot, Color(_c.deep, 0.0), 1, 1.2)

	func _paint() -> void:
		var rise := 1.0 - pow(1.0 - smoothstep(0.0, 0.6, t), 2.0)
		var fade := 1.0 - smoothstep(1.0, 1.5, t)
		var h := 150.0 * rise
		var w := 44.0 * rise
		pd.glow(Vector2(0, -h * 0.5), h * 0.5 + 20.0, Color(_c.flame, 0.35 * fade), 0.0)
		# 큰 불꽃 몸 (여러 혀가 겹쳐 사람 모양 실루엣)
		for i in 7:
			var ox := (float(i) - 3.0) * w * 0.3
			var ph := t * 9.0 + float(i) * 1.4
			var th := h * (0.55 + 0.45 * (1.0 - absf(float(i) - 3.0) / 3.0)) * (0.9 + 0.1 * sin(ph))
			TFx.tongue(pd, Vector2(ox, 0), Vector2.UP, th, w * 0.28, fade * 0.85, sin(ph * 0.7) * 8.0, _c)
		# 팔 (양쪽으로 펼친 불)
		for s: float in [-1.0, 1.0]:
			var base := Vector2(s * w * 0.6, -h * 0.62)
			TFx.tongue(pd, base, Vector2(s * 0.7, -0.7).normalized(), 40.0 * rise, 7.0, fade * 0.8, sin(t * 8.0) * 5.0, _c)
		# 눈 둘 (흰 심, 금 테)
		if rise > 0.6:
			var ea := (rise - 0.6) / 0.4 * fade
			for s: float in [-1.0, 1.0]:
				var e := Vector2(s * 9.0, -h * 0.78)
				pd.glow(e, 7.0, Color(_c.core, 0.7 * ea), 0.0)
				pd.draw_colored_polygon(PackedVector2Array([e + Vector2(-5 * s, 1), e + Vector2(0, -3.5), e + Vector2(5 * s, 1), e + Vector2(0, 2.5)]), Color(_c.core, ea))
				pd.draw_circle(e, 1.4, Color(_c.dark, ea))


## 불막이: 아군 앞에 서는 불씨 방패 호 세 겹
class FireWall extends PVfx.Base:
	var _c: Dictionary = TFx.cur ## 만들어지는 순간의 속성 색 (뒤에 다른 속성이 시전돼도 안 바뀜)
	func _ready() -> void:
		life = 1.1
		z_index = 8

	func _paint() -> void:
		var x := k()
		var grow := 1.0 - pow(1.0 - minf(x * 2.0, 1.0), 2.0)
		var a := 1.0 - smoothstep(0.6, 1.0, x)
		for i in 3:
			var r := 46.0 + float(i) * 12.0
			var span := (0.9 + 0.25 * float(i)) * grow
			var c := Vector2(-40.0 - float(i) * 14.0, 0)
			pd.draw_arc(c, r, -span, span, 24, Color(_c.deep, 0.5 * a), 4.0)
			pd.draw_arc(c, r, -span * 0.95, span * 0.95, 24, Color(_c.hot, 0.9 * a), 1.6)
			for j in 7:
				var an := lerpf(-span, span, float(j) / 6.0)
				var p := c + Vector2.from_angle(an) * r
				pd.draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Color(_c.core, a * (0.5 + 0.5 * sin(t * 20.0 + float(j)))))


## 보조 마법 공통 기운: 바닥 고리 + 몸 둘레를 도는 알갱이 + 위로 오르는 불티/빛. kind에 따라 결이 다르다
class Aura extends PVfx.Base:
	var _c: Dictionary = TFx.cur ## 만들어지는 순간의 속성 색 (뒤에 다른 속성이 시전돼도 안 바뀜)
	var col: Color = _c.hot
	var kind := "atk" ## atk · crit · fire · heal

	func _ready() -> void:
		life = 0.9
		z_index = 8

	func _tick(_d: float) -> void:
		if t < 0.6 and randf() < 0.7:
			var p := global_position + Vector2(randf_range(-12, 12), randf_range(0, 20))
			var c1 := Color(col, 0.0)
			PParticles.get_layer(true).spawn(p, Vector2(randf_range(-10, 10), -randf_range(40, 90)), Vector2.ZERO, 0.6, randf_range(1.0, 2.0), col, c1, 0, 1.0)

	func _paint() -> void:
		var x := k()
		var grow := 1.0 - pow(1.0 - minf(x * 1.8, 1.0), 2.0)
		var a := 1.0 - smoothstep(0.55, 1.0, x)
		pd.glow(Vector2.ZERO, 22.0 * grow + 6.0, Color(col, 0.3 * a), 0.0)
		# 바닥 고리 (타원)
		pd.draw_set_transform(Vector2(0, 22), 0.0, Vector2(1.0, 0.32))
		pd.draw_arc(Vector2.ZERO, 8.0 + 18.0 * grow, 0.0, TAU, 28, Color(col, 0.9 * a), 1.6)
		pd.draw_set_transform(Vector2.ZERO)
		match kind:
			"atk":
				for i in 3: # 위로 치솟는 화살 결
					var ox := (float(i) - 1.0) * 9.0
					var y := 20.0 - 50.0 * fmod(x * 1.4 + float(i) * 0.3, 1.0)
					pd.draw_colored_polygon(PackedVector2Array([Vector2(ox - 3, y + 4), Vector2(ox, y - 2), Vector2(ox + 3, y + 4)]), Color(col, a))
			"crit":
				for i in 5: # 반짝이는 별
					var an := t * 5.0 + float(i) * TAU / 5.0
					var p := Vector2(cos(an), sin(an) * 0.6) * (14.0 + 6.0 * grow)
					EVfx.star4(pd, p, 3.0 + 2.0 * sin(t * 18.0 + float(i)), an, Color(_c.core, a), Color(col, 0.0))
			"fire":
				for i in 6: # 둘레를 도는 불꽃 혀
					var an := -t * 6.0 + float(i) * TAU / 6.0
					var p := Vector2(cos(an), sin(an) * 0.45) * (16.0 * grow)
					TFx.tongue(pd, p, Vector2.UP, 8.0 + 4.0 * sin(t * 20.0 + float(i)), 2.4, a, 0.0, _c)
			"heal":
				for i in 4: # 떠오르는 둥근 빛
					var ph := fmod(x * 1.2 + float(i) * 0.25, 1.0)
					var p := Vector2((float(i) - 1.5) * 8.0 + sin(t * 4.0 + float(i)) * 3.0, 18.0 - ph * 42.0)
					pd.glow(p, 4.0, Color(col, (1.0 - ph) * a), 0.0)
					pd.draw_circle(p, 1.3, Color(_c.core, (1.0 - ph) * a))


## 화염 집중: 불이 자신에게 모여들다가 확 피어난다
class FocusAura extends PVfx.Base:
	var _c: Dictionary = TFx.cur ## 만들어지는 순간의 속성 색 (뒤에 다른 속성이 시전돼도 안 바뀜)
	var actor: TActor
	var dur := 0.9

	func _ready() -> void:
		life = dur
		z_index = 8

	func _tick(_d: float) -> void:
		if is_instance_valid(actor):
			global_position = actor.center()
		if t < life * 0.5 and randf() < 0.9:
			var an := randf() * TAU
			var p := global_position + Vector2.from_angle(an) * 40.0
			PParticles.get_layer(true).spawn(p, (global_position - p) * 3.5, Vector2.ZERO, 0.28, randf_range(1.0, 2.0), _c.hot, Color(_c.flame, 0.0), 1, 0.0)

	func _paint() -> void:
		var x := k()
		var gather := smoothstep(0.0, 0.5, x)
		var bloom := smoothstep(0.5, 0.65, x) * (1.0 - smoothstep(0.75, 1.0, x))
		pd.glow(Vector2.ZERO, 10.0 + 26.0 * bloom, Color(_c.flame, 0.45 * (gather * 0.5 + bloom)), 0.0)
		for i in 8:
			var an := t * 7.0 + float(i) * TAU / 8.0
			var r := lerpf(34.0, 10.0, gather) + 30.0 * bloom
			var p := Vector2(cos(an), sin(an) * 0.5) * r
			pd.line2(p, p + Vector2.from_angle(an + PI * 0.5) * 6.0, Color(_c.hot, 0.0), Color(_c.core, 0.9), 0.5, 1.6)
		if bloom > 0.0:
			for i in 10:
				var an := TAU * float(i) / 10.0
				TFx.tongue(pd, Vector2.from_angle(an) * 8.0, Vector2.from_angle(an), 18.0 * bloom, 3.0, bloom, 0.0, _c)


## 풀무: 바람 소용돌이가 불씨를 밝힌다 (옅은 바람 줄 + 불티)
class Bellows extends PVfx.Base:
	var _c: Dictionary = TFx.cur ## 만들어지는 순간의 속성 색 (뒤에 다른 속성이 시전돼도 안 바뀜)
	func _ready() -> void:
		life = 0.9
		z_index = 8

	func _tick(_d: float) -> void:
		if t < 0.6 and randf() < 0.8:
			var an := randf() * TAU
			var p := global_position + Vector2(cos(an), sin(an) * 0.5) * 18.0
			PParticles.get_layer(true).spawn(p, Vector2(cos(an + 1.3), sin(an + 1.3) * 0.5) * 70.0 + Vector2(0, -40), Vector2.ZERO, 0.5, randf_range(1.0, 2.2), _c.hot, Color(_c.flame, 0.0), 1, 1.0)

	func _paint() -> void:
		var x := k()
		var a := 1.0 - smoothstep(0.5, 1.0, x)
		for i in 4:
			var ph := t * 9.0 + float(i) * TAU / 4.0
			var pts := PackedVector2Array()
			for j in 10:
				var f := float(j) / 9.0
				var an := ph + f * 2.2
				var r := 14.0 + 10.0 * f + 4.0 * sin(t * 6.0)
				pts.append(Vector2(cos(an) * r, sin(an) * r * 0.45 - 10.0 * f))
			pd.draw_polyline(pts, Color(PALE, 0.6 * a * (0.4 + 0.6 * float(i % 2))), 1.2)
		pd.glow(Vector2.ZERO, 16.0, Color(_c.flame, 0.35 * a * (0.5 + 0.5 * sin(t * 30.0))), 0.0)


## 위에서 내리는 빛기둥 (전체 버프)
class LightShaft extends PVfx.Base:
	var _c: Dictionary = TFx.cur ## 만들어지는 순간의 속성 색 (뒤에 다른 속성이 시전돼도 안 바뀜)
	var col: Color = _c.hot
	var w := 150.0
	var rays := false

	func _ready() -> void:
		life = 1.1
		z_index = -2

	func _paint() -> void:
		var x := k()
		var a := sin(x * PI)
		var h := 320.0
		pd.draw_colored_polygon(PackedVector2Array([Vector2(-w * 0.35, 0), Vector2(w * 0.35, 0), Vector2(w * 0.6, h), Vector2(-w * 0.6, h)]), Color(col, 0.14 * a))
		pd.draw_colored_polygon(PackedVector2Array([Vector2(-w * 0.15, 0), Vector2(w * 0.15, 0), Vector2(w * 0.3, h), Vector2(-w * 0.3, h)]), Color(_c.core, 0.12 * a))
		if rays:
			for i in 7:
				var f := (float(i) - 3.0) / 3.0
				var ph := 0.5 + 0.5 * sin(t * 4.0 + float(i) * 1.7)
				pd.line2(Vector2(f * w * 0.25, 0), Vector2(f * w * 0.7, h), Color(col, 0.35 * a * ph), Color(col, 0.0), 2.0, 5.0)
		for i in 10: # 떠다니는 빛 조각
			var ph := fmod(x * 0.8 + float(i) * 0.1, 1.0)
			var p := Vector2((EVfx.hash01(i * 13) - 0.5) * w * 0.8, h * (1.0 - ph))
			pd.draw_rect(Rect2(p, Vector2(1.5, 1.5)), Color(_c.core, a * (1.0 - ph) * 0.8))


## 불씨 나눔: 등불에서 아군으로 흐르는 불티의 띠
class SparkStream extends PVfx.Base:
	var _c: Dictionary = TFx.cur ## 만들어지는 순간의 속성 색 (뒤에 다른 속성이 시전돼도 안 바뀜)
	var from := Vector2.ZERO
	var to := Vector2.ZERO

	func _ready() -> void:
		life = 0.9
		z_index = 9

	func _tick(_d: float) -> void:
		if t < 0.5:
			var f := t / 0.5
			var p := from.lerp(to, f) + Vector2(0, -sin(f * PI) * 30.0)
			for i in 2:
				PParticles.get_layer(true).spawn(p + Vector2(randf_range(-3, 3), randf_range(-3, 3)), Vector2(randf_range(-20, 20), randf_range(-20, 20)), Vector2.ZERO, 0.4, randf_range(1.2, 2.2), _c.hot, Color(_c.flame, 0.0), 0, 2.0)

	func _paint() -> void:
		var x := k()
		var reach := minf(t / 0.5, 1.0)
		var a := 1.0 - smoothstep(0.5, 1.0, x)
		var pts := PackedVector2Array()
		for i in 13:
			var f := float(i) / 12.0 * reach
			pts.append(from.lerp(to, f) + Vector2(0, -sin(f * PI) * 30.0))
		for i in range(1, pts.size()):
			var f := float(i) / 12.0
			pd.line2(pts[i - 1], pts[i], Color(_c.flame, 0.3 * a * f), Color(_c.core, 0.9 * a * f), 0.8, 2.2)
		if reach >= 1.0:
			pd.glow(to, 18.0 * a, Color(_c.hot, 0.5 * a), 0.0)


# ═══════════════════════════════════════════════════════════
# 공간 (에스카 보조)
# ═══════════════════════════════════════════════════════════

## 손끝 흑백 섬광 (기본 공격·균열 준비)
class HandFlash extends PVfx.Base:
	var big := false

	static func spawn(at: Vector2, b: bool) -> void:
		var h := HandFlash.new()
		h.big = b
		h.life = 0.3 if b else 0.18
		TFx.add(h, at, false)

	func _paint() -> void:
		var x := k()
		var a := 1.0 - x
		var s := 1.6 if big else 1.0
		pd.glow(Vector2.ZERO, (6.0 + 8.0 * x) * s, Color(PALE, 0.6 * a), 0.0)
		EVfx.star4(pd, Vector2.ZERO, (5.0 + 6.0 * x) * s, t * 6.0, Color(WHITE, a), Color(LAV, 0.0))
		pd.draw_circle(Vector2.ZERO, 2.0 * s * a, INK)
		pd.draw_arc(Vector2.ZERO, (3.0 + 12.0 * x) * s, 0.0, TAU, 16, Color(WHITE, 0.8 * a), 1.0)


## 종언 준비: 양손 사이에 흑백 구슬이 커지며 지직거린다
class ChargeOrb extends PVfx.Base:
	var actor: TActor
	var dur := 0.55

	func _ready() -> void:
		life = dur
		z_index = 9

	func _tick(_d: float) -> void:
		if is_instance_valid(actor):
			global_position = actor.hand()
		if randf() < 0.7:
			var an := randf() * TAU
			var p := global_position + Vector2.from_angle(an) * 34.0
			PParticles.get_layer(false).spawn(p, (global_position - p) * 3.0, Vector2.ZERO, 0.3, randf_range(1.2, 2.4), WHITE if randf() < 0.5 else INK, PALE, 0, 0.0)

	func _paint() -> void:
		var c := k()
		var r := 2.0 + 7.0 * c
		var pulse := 1.0 + 0.1 * sin(t * 40.0)
		pd.glow(Vector2.ZERO, (10.0 + 24.0 * c) * pulse, Color(PALE, 0.5), 0.0)
		pd.draw_circle(Vector2.ZERO, r + 1.6, LAV)
		pd.draw_circle(Vector2.ZERO, r, INK)
		pd.draw_circle(Vector2(-r * 0.3, -r * 0.3), r * 0.35, WHITE)
		var seed := int(t * 30.0)
		for kk in 4:
			var an := EVfx.hash01(seed * 7 + kk * 13) * TAU
			var len := (8.0 + 16.0 * c) * (0.6 + 0.4 * EVfx.hash01(seed + kk))
			var d := Vector2.from_angle(an)
			var mid := d * len * 0.5 + d.orthogonal() * (EVfx.hash01(seed * 3 + kk) - 0.5) * 5.0
			pd.draw_line(Vector2.ZERO, mid, Color(WHITE, 0.9), 1.0)
			pd.draw_line(mid, d * len, Color(LAV, 0.7), 1.0)


## 압축: 표적 둘레의 흑백 고리가 안으로 조여 든다
class Implode extends PVfx.Base:
	func _ready() -> void:
		life = 0.42
		z_index = 8

	func _paint() -> void:
		var x := k()
		var r := lerpf(60.0, 4.0, pow(x, 1.6))
		for i in 3:
			var rr := r * (1.0 + 0.25 * float(i))
			var sq := 0.55
			var pts := PackedVector2Array()
			for j in 33:
				var an := TAU * float(j) / 32.0 + t * (3.0 - float(i))
				pts.append(Vector2(cos(an) * rr, sin(an) * rr * sq))
			pd.draw_polyline(pts, Color(INK, 0.7), 3.0)
			pd.draw_polyline(pts, Color(WHITE, 0.9 - 0.2 * float(i)), 1.2)
		for j in 8:
			var an := TAU * float(j) / 8.0 + t * 2.0
			var p := Vector2(cos(an), sin(an) * 0.55) * r * 1.4
			pd.line2(p, p * 0.7, Color(WHITE, 0.0), Color(WHITE, 0.9), 0.4, 1.6)


## 흑성: 검은 별이 내려와 커지다가 터진다 (터짐은 Rift들이 맡음)
class BlackStar extends PVfx.Base:
	var fall := 0.7
	var _top := Vector2.ZERO

	func _ready() -> void:
		life = fall + 0.25
		z_index = 9
		_top = global_position

	func _tick(_d: float) -> void:
		var f := minf(t / fall, 1.0)
		global_position = _top + Vector2(0, 150.0 * pow(f, 1.3))
		if t < fall and randf() < 0.8:
			var an := randf() * TAU
			var p := global_position + Vector2.from_angle(an) * 50.0
			PParticles.get_layer(false).spawn(p, (global_position - p) * 2.5, Vector2.ZERO, 0.4, randf_range(1.5, 3.0), INK if randf() < 0.6 else WHITE, LAV, 0, 0.0)

	func _paint() -> void:
		var f := minf(t / fall, 1.0)
		var post := clampf((t - fall) / 0.25, 0.0, 1.0)
		var r := 6.0 + 22.0 * f
		var a := 1.0 - post
		pd.glow(Vector2.ZERO, r * 2.2, Color(LAV, 0.35 * a), 0.0)
		pd.glow(Vector2.ZERO, r * 1.4, Color(WHITE, 0.5 * a), 0.0)
		pd.draw_circle(Vector2.ZERO, r * (1.0 + post * 2.0), Color(INK, a))
		pd.draw_arc(Vector2.ZERO, r * (1.0 + post * 2.0), 0.0, TAU, 32, Color(WHITE, a), 1.6)
		for i in 5: # 별 가시
			var an := t * 3.0 + TAU * float(i) / 5.0
			var d := Vector2.from_angle(an)
			pd.line2(d * r * 0.8, d * r * (1.8 + 0.4 * sin(t * 20.0 + float(i))), Color(WHITE, 0.9 * a), Color(WHITE, 0.0), 2.0, 0.3)
		for i in 7: # 안의 별빛
			var p := Vector2(EVfx.hash01(i * 3) - 0.5, EVfx.hash01(i * 5) - 0.5) * r * 1.4
			if p.length() < r * 0.85:
				pd.draw_rect(Rect2(p, Vector2(1, 1)), Color(WHITE, (0.5 + 0.5 * sin(t * 15.0 + float(i))) * a))


## 공허의 문: 아군 뒤에 세로로 길게 찢긴 문이 열리고 라벤더 빛이 흘러들어 닫힌다
class VoidGate extends PVfx.Base:
	var target: TActor

	func _ready() -> void:
		life = 1.1
		z_index = -4

	func _tick(_d: float) -> void:
		if t > 0.2 and t < 0.8 and is_instance_valid(target) and randf() < 0.9:
			var p := global_position + Vector2(randf_range(-3, 3), -randf_range(10, 60))
			var v := (target.center() - p).normalized() * randf_range(60.0, 120.0)
			PParticles.get_layer(true).spawn(p, v, Vector2.ZERO, 0.4, randf_range(1.0, 2.2), PALE, Color(LAV, 0.0), 1, 0.0)

	func _paint() -> void:
		var x := k()
		var open := smoothstep(0.0, 0.3, t) * (1.0 - smoothstep(0.75, 1.0, x))
		var h := 72.0
		var w := 11.0 * open
		var n := 12
		var l := PackedVector2Array()
		var r := PackedVector2Array()
		for i in n + 1:
			var f := float(i) / float(n)
			var y := -h * f
			var ww := w * pow(sin(f * PI), 0.7)
			var jag := (EVfx.hash01(i * 11) - 0.5) * 3.0 * open
			l.append(Vector2(-ww + jag, y))
			r.append(Vector2(ww + jag, y))
		pd.strip(l, r, Color(LAV, 0.35 * open))
		var poly := l.duplicate()
		for i in range(n, -1, -1):
			poly.append(r[i])
		pd.draw_colored_polygon(poly, INK)
		pd.draw_polyline(l, Color(WHITE, open), 1.4)
		pd.draw_polyline(r, Color(WHITE, open), 1.4)
		for i in 6:
			var p := Vector2((EVfx.hash01(i * 7) - 0.5) * w * 1.2, -h * EVfx.hash01(i * 9))
			pd.draw_rect(Rect2(p, Vector2(1, 1)), Color(WHITE, open * (0.5 + 0.5 * sin(t * 20.0 + float(i)))))
		pd.glow(Vector2(0, -h * 0.5), 30.0 * open, Color(LAV, 0.25 * open), 0.0)


## 봉공: 아군 둘레의 육각 결계 (흰 테·라벤더 번짐), 열리고 잠깐 머물다 사라짐
class Barrier extends PVfx.Base:
	func _ready() -> void:
		life = 0.9
		z_index = 9

	func _paint() -> void:
		var x := k()
		var grow := 1.0 - pow(1.0 - minf(x * 2.5, 1.0), 2.0)
		var a := 1.0 - smoothstep(0.55, 1.0, x)
		var pts := PackedVector2Array()
		for i in 6:
			var an := TAU * float(i) / 6.0 + t * 1.5
			pts.append(Vector2(cos(an) * 24.0, sin(an) * 30.0) * grow)
		pts.append(pts[0])
		pd.glow(Vector2.ZERO, 30.0 * grow, Color(LAV, 0.25 * a), 0.0)
		pd.draw_polyline(pts, Color(INK, 0.5 * a), 3.0)
		pd.draw_polyline(pts, Color(WHITE, 0.95 * a), 1.2)
		for i in 6:
			EVfx.star4(pd, pts[i], 3.0 * a, t * 4.0, Color(WHITE, a), Color(LAV, 0.0))
		# 안쪽 격자 (옅게)
		for i in 3:
			pd.draw_line(pts[i], pts[i + 3], Color(PALE, 0.25 * a), 0.6)


## 성흔: 가슴에 찍히는 라벤더 별 인장 + 고리
class Stigma extends PVfx.Base:
	func _ready() -> void:
		life = 0.9
		z_index = 9

	func _tick(_d: float) -> void:
		if t < 0.5 and randf() < 0.8:
			PParticles.get_layer(true).spawn(global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8)), Vector2(randf_range(-10, 10), -randf_range(40, 90)), Vector2.ZERO, 0.5, randf_range(1.0, 2.0), PALE, Color(LAV, 0.0), 0, 1.0)

	func _paint() -> void:
		var x := k()
		var stamp := 1.0 - pow(1.0 - minf(x * 3.0, 1.0), 3.0)
		var a := 1.0 - smoothstep(0.5, 1.0, x)
		pd.glow(Vector2.ZERO, 14.0 + 10.0 * stamp, Color(LAV, 0.4 * a), 0.0)
		EVfx.star4(pd, Vector2.ZERO, 12.0 * stamp, 0.4, Color(WHITE, a), Color(LAV, 0.0))
		EVfx.star4(pd, Vector2.ZERO, 7.0 * stamp, 0.4 + PI * 0.25, Color(PALE, a), Color(LAV, 0.0))
		pd.draw_arc(Vector2.ZERO, 8.0 + 14.0 * stamp, 0.0, TAU, 24, Color(WHITE, 0.8 * a * a), 1.2)
		pd.draw_arc(Vector2.ZERO, 5.0 + 6.0 * stamp, 0.0, TAU, 16, Color(LAV, 0.9 * a), 0.8)


## 공허의 요람: 깃털이 모여들고 흰빛이 차오른 뒤 터진다 (되살림)
class Cradle extends PVfx.Base:
	func _ready() -> void:
		life = 1.3
		z_index = 9

	func _tick(_d: float) -> void:
		if t < 0.65 and randf() < 0.9:
			var an := randf() * TAU
			var p := global_position + Vector2(cos(an) * 60.0, -20.0 + sin(an) * 40.0)
			var tgt := global_position + Vector2(0, -22.0)
			PParticles.get_layer(true).spawn(p, (tgt - p) * 2.0, Vector2.ZERO, 0.5, randf_range(1.2, 2.4), PALE, Color(WHITE, 0.0), 1, 0.0)
		if t < 0.6 and randf() < 0.3:
			EVfx.feathers(global_position + Vector2(randf_range(-40, 40), -randf_range(0, 50)), 1, 40.0, Vector2.ZERO, Vector2.UP)

	func _paint() -> void:
		var x := k()
		var gather := smoothstep(0.0, 0.65, t)
		var burst := clampf((t - 0.7) / 0.5, 0.0, 1.0)
		var c := Vector2(0, -22.0)
		pd.glow(c, 10.0 + 24.0 * gather, Color(PALE, 0.5 * gather * (1.0 - burst)), 0.0)
		pd.glow(c, 4.0 + 12.0 * gather, Color(WHITE, 0.9 * gather * (1.0 - burst)), 0.0)
		# 요람 모양 둥근 호 둘 (아래를 받치듯)
		var oa := gather * (1.0 - burst)
		pd.draw_arc(c + Vector2(0, 6), 26.0 * gather, 0.3, PI - 0.3, 20, Color(WHITE, oa), 1.4)
		pd.draw_arc(c + Vector2(0, 2), 32.0 * gather, 0.5, PI - 0.5, 20, Color(LAV, 0.6 * oa), 1.0)
		if burst > 0.0:
			var a := 1.0 - burst
			pd.draw_arc(c, 10.0 + 60.0 * (1.0 - pow(1.0 - burst, 2.0)), 0.0, TAU, 36, Color(WHITE, a), 2.0)
			for i in 8:
				var d := Vector2.from_angle(TAU * float(i) / 8.0)
				pd.line2(c + d * 8.0, c + d * (20.0 + 50.0 * burst), Color(WHITE, a), Color(PALE, 0.0), 2.0, 0.3)


# ═══════════════════════════════════════════════════════════
# 적
# ═══════════════════════════════════════════════════════════

## 적 공격: 표적 앞에서 휘둘러지는 어두운 호 (골렘은 짚 팔, 두꺼비는 혀 찌름, 기사는 잿빛 검광)
class EnemySlash extends PVfx.Base:
	var heavy := false
	var kind := "straw_golem"

	func _ready() -> void:
		life = 0.5 if heavy else 0.4
		z_index = 9

	func _paint() -> void:
		var x := k()
		var sw := smoothstep(0.0, 0.2 if heavy else 0.16, t)
		var a := 1.0 - smoothstep(0.5, 1.0, x)
		var s := 1.4 if heavy else 1.0
		match kind:
			"swamp_toad":
				var from := Vector2(70, -10)
				var to := Vector2(0, 0)
				var p := from.lerp(to, sw)
				pd.draw_line(from, p, Color("#d9607a", a), 3.0 * s)
				pd.draw_circle(p, 3.0 * s, Color("#f08aa0", a))
			"ash_knight":
				var r := 34.0 * s
				var a0 := -2.4
				var a1 := lerpf(a0, 0.6, sw)
				pd.draw_arc(Vector2(10, -6), r, a0, a1, 18, Color(INK, 0.7 * a), 7.0 * s)
				pd.draw_arc(Vector2(10, -6), r, a0, a1, 18, Color("#9a93a6", 0.9 * a), 2.6 * s)
				pd.draw_arc(Vector2(10, -6), r * 0.95, a0 + 0.2, a1, 18, Color(FLAME, 0.7 * a), 0.9)
			_:
				var r := 26.0 * s
				var a0 := -2.6
				var a1 := lerpf(a0, 0.4, sw)
				pd.draw_arc(Vector2(8, -4), r, a0, a1, 16, Color("#6b3f1f", 0.6 * a), 6.0 * s)
				pd.draw_arc(Vector2(8, -4), r, a0, a1, 16, Color("#c9a85c", 0.9 * a), 2.2 * s)


## 적 전체 공격: 땅을 따라 퍼지는 충격파 (채운 타원 + 테 두 겹) + 먼지 12 + 흔들림 (review_C §8.4). col = 테 색 (번개 망치도 씀)
class Shockwave extends PVfx.Base:
	var col := ASH
	var _dust := false

	func _ready() -> void:
		life = 0.7
		z_index = 8

	func _tick(_d: float) -> void:
		if not _dust:
			_dust = true
			Fx.shake(0.3, 0.2)
			var pp := PParticles.get_layer(false)
			for i in 12:
				var an := randf_range(PI * 0.75, PI * 1.25) if i % 2 == 0 else randf_range(-PI * 0.25, PI * 0.25)
				pp.spawn(global_position + Vector2(randf_range(-10, 10), 0), Vector2.from_angle(an) * randf_range(120, 260) + Vector2(0, -40), Vector2(0, 300), 0.5, randf_range(2.0, 4.0), Color("#8a7a96"), Color("#4a3f55", 0.0), 2, 1.5)

	func _paint() -> void:
		var x := k()
		var a := 1.0 - x
		var r := 10.0 + 420.0 * (1.0 - pow(1.0 - x, 2.0))
		pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
		pd.glow(Vector2.ZERO, r, Color(col, 0.22 * a), 0.0)
		pd.draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(col, 0.85 * a), 3.4)
		pd.draw_arc(Vector2.ZERO, r * 0.8, 0.0, TAU, 48, Color(WHITE, 0.45 * a), 1.2)
		pd.draw_arc(Vector2.ZERO, r * 0.55, 0.0, TAU, 40, Color(col, 0.35 * a), 2.0)
		pd.draw_set_transform(Vector2.ZERO)


## 마녀가 맞는 순간: 붉은 X 섬광
class EnemyHit extends PVfx.Base:
	var heavy := false

	func _ready() -> void:
		life = 0.22
		z_index = 10

	func _paint() -> void:
		var x := k()
		var a := 1.0 - x
		var s := 1.5 if heavy else 1.0
		pd.glow(Vector2.ZERO, (10.0 + 10.0 * x) * s, Color("#ff2f58", 0.5 * a), 0.0)
		for i in 2:
			var an := 0.785 + float(i) * PI * 0.5
			var d := Vector2.from_angle(an)
			pd.line2(-d * 14.0 * s, d * 14.0 * s, Color(WHITE, 0.0), Color(WHITE, a), 0.4, 2.6)
			pd.line2(d * 14.0 * s, -d * 14.0 * s, Color(WHITE, 0.0), Color(WHITE, a), 0.4, 2.6)
		pd.draw_arc(Vector2.ZERO, (6.0 + 16.0 * x) * s, 0.0, TAU, 20, Color("#ff2f58", 0.8 * a), 1.2)


# ═══════════════════════════════════════════════════════════
# 대마법 (단계 D — combat_proto.md §13.4 · §22.2)
# 2.0초: 어둡게 0.2 → 컷인 띠 + 문장 고리 0.4 → 효과 1.0 → 숫자 0.4. 마녀마다 색·문장·효과 모양이 다르고,
# 효과 모양이 그 대마법이 하는 일(단일 한 방 · 광역 · 보조 · 차례 조작 · 다단)을 그림으로 보인다.
# 연쇄 2·3단계(§13.6)면 크기 ×1.15·×1.3 + 문장 고리 한 겹 더 + 컷인 금테·"연쇄 n단계" + 3단계는 금빛 섬광.
# 그리기: 효과 한 개 = 노드 1~3개(묶음 그리기 1번씩) + 공용 입자 층. 입자는 기존 큰 마법(태양의 창·재의 폭풍) 이하로 뿌린다.
# ═══════════════════════════════════════════════════════════

const ULT_DIM := 0.2 ## 어둡게
const ULT_CUT_AT := 0.15 ## 컷인 띠가 들어오는 시각
const ULT_FX := 0.6 ## 효과가 시작하는 시각 (어둡게 0.2 + 컷인 0.4)
const ULT_TOTAL := 2.0

## 대마법마다: 색(PAL 키) · 문장 무늬(emblem) · 효과 모양(읽혀야 할 것)
const ULT := {
	"ult_ignis": {"pal": "fire", "emblem": "sun", "shape": "단일 한 방 + 화상 번짐"},
	"ult_ember": {"pal": "fire", "emblem": "bird", "shape": "전체 버프 + 크레딧"},
	"ult_cinder": {"pal": "ash", "emblem": "urn", "shape": "광역 + 화상 3겹 + 방어 다운"},
	"ult_undine": {"pal": "water", "emblem": "drop", "shape": "단일 한 방 + 크레딧 환급"},
	"ult_nerei": {"pal": "tide", "emblem": "wave", "shape": "전체 무적·피해 감소·회복"},
	"ult_glacia": {"pal": "ice", "emblem": "flake", "shape": "전체 빙결 3겹 + 게이지·차지 감소"},
	"ult_fulgur": {"pal": "bolt", "emblem": "hammer", "shape": "단일 5단"},
	"ult_astra": {"pal": "star", "emblem": "star8", "shape": "전체 크리 버프 + 게이지(차례)"},
	"ult_tonan": {"pal": "storm", "emblem": "cloud", "shape": "광역 + 감전 3겹 + 크리 표적"},
	"ult_eska": {"pal": "space", "emblem": "rift", "shape": "광역 7배 (방어 무시)"},
	"ult_hora": {"pal": "time", "emblem": "clock", "shape": "적 차지·게이지 감소 + 버프 연장"},
	"ult_harpe": {"pal": "sword", "emblem": "blades", "shape": "단일 6단 확정 크리"},
}


static func is_ult(sid: String) -> bool:
	return ULT.has(sid)


## 대마법 연출. targets = 규칙의 대상(맞는 시각표가 이 순서를 따름), foes·allies = 살아 있는 적·아군(효과가 번지는 쪽 그림용).
## stage = 연쇄 단계 1~3. 돌려주는 시각표는 play()와 같다 ({hits, total, sub})
static func ultimate(sid: String, caster: TActor, targets: Array, stage := 1, foes: Array = [], allies: Array = []) -> Dictionary:
	var u: Dictionary = ULT.get(sid, ULT.ult_eska)
	set_element(String(u.pal))
	var pal: Dictionary = cur
	var s := 1.0 + 0.15 * float(clampi(stage, 1, 3) - 1)
	var hits: Array = []
	var sub := 0.09
	var tp: Vector2 = targets[0].center() if not targets.is_empty() else caster.center()
	# 공통 머리: 어둡게 + 문장 고리 + 컷인
	var dim := UltDim.new()
	dim._c = pal
	dim.caster = caster
	dim.stage = stage
	dim.mono = sid in ["ult_eska", "ult_harpe"]
	add(dim, Vector2.ZERO, false)
	var sg := UltSigil.new()
	sg._c = pal
	sg.emblem = String(u.emblem)
	sg.stage = stage
	sg.actor = caster
	add(sg, caster.feet(), true)
	# 연쇄 단계마다 시전 울림을 2·3반음 낮춤 (review_D B3) + 높은 종은 22050으로 따로 (B1)
	Sfx.play_pitch(&"tn_ult", [1.0, 1.0, 0.89, 0.84][clampi(stage, 1, 3)], -2.0)
	Sfx.play(&"tn_ult_bell", -2.0)
	if stage >= 2:
		Sfx.play(&"tn_bless", -8.0 + 2.0 * float(stage))
	var ttl := String(TData.skill(sid).get("name", ""))
	after(ULT_CUT_AT, func() -> void: cutin(caster, ttl, String(u.emblem), stage, pal))
	var fx_at := ULT_FX
	match sid:
		"ult_ignis":
			var t0: TActor = targets[0] if not targets.is_empty() else caster
			after(fx_at, func() -> void:
				var e := SunCollapse.new()
				e._c = pal
				e.s = s
				e.target = t0
				e.foes = foes
				add(e, Vector2.ZERO, true))
			hits = [fx_at + SunCollapse.HIT]
		"ult_undine":
			var t0: TActor = targets[0] if not targets.is_empty() else caster
			after(fx_at, func() -> void:
				var e := AbyssCollapse.new()
				e._c = pal
				e.s = s
				e.target = t0
				e.caster = caster
				add(e, Vector2.ZERO, false)) # 검푸른 구체는 가산이면 안 보임
			hits = [fx_at + AbyssCollapse.HIT]
		"ult_fulgur":
			after(fx_at, func() -> void:
				var e := ThunderHammer.new()
				e._c = pal
				e.s = s
				e.to = tp
				add(e, Vector2.ZERO, false)) # 먹 테 망치는 보통 합성
			hits = [fx_at + ThunderHammer.HIT0]
			sub = ThunderHammer.STEP
		"ult_harpe":
			var t0: TActor = targets[0] if not targets.is_empty() else caster
			after(fx_at, func() -> void:
				var e := FinalCurtain.new()
				e.s = s
				e.target = t0
				add(e, Vector2.ZERO, false))
			hits = [fx_at + FinalCurtain.HIT0]
			sub = FinalCurtain.STEP
		"ult_cinder", "ult_tonan", "ult_eska", "ult_glacia":
			var pts: Array = []
			for a in targets:
				pts.append(a)
			after(fx_at, func() -> void:
				var e: UltBase
				match sid:
					"ult_cinder": e = AshFuneral.new()
					"ult_tonan": e = ThunderVerdict.new()
					"ult_glacia": e = AbsoluteZero.new()
					_: e = WorldEnd.new()
				e._c = pal
				e.s = s
				e.foes = pts
				add(e, Vector2.ZERO, sid == "ult_glacia")) # 재구름·먹구름·검은 별은 보통 합성 (가산이면 어두운 색이 사라짐)
			var cls_hit := {"ult_cinder": AshFuneral.HIT0, "ult_tonan": ThunderVerdict.HIT0, "ult_glacia": AbsoluteZero.HIT0, "ult_eska": WorldEnd.HIT0}
			var cls_step := {"ult_cinder": AshFuneral.STEP, "ult_tonan": ThunderVerdict.STEP, "ult_glacia": AbsoluteZero.STEP, "ult_eska": WorldEnd.STEP}
			for i in targets.size():
				hits.append(fx_at + float(cls_hit[sid]) + float(cls_step[sid]) * float(i))
		_:
			# 보조 대마법: 불새(엠버) · 성소(네레이) · 별 행진(아스트라) · 시간의 정적(호라)
			var al: Array = []
			for a in targets:
				al.append(a)
			after(fx_at, func() -> void:
				var e: UltBase
				match sid:
					"ult_ember": e = Phoenix.new()
					"ult_nerei": e = TideSanctum.new()
					"ult_astra": e = StarParade.new()
					_: e = TimeStill.new()
				e._c = pal
				e.s = s
				e.allies = al
				e.foes = foes
				e.caster = caster
				add(e, Vector2.ZERO, sid != "ult_hora"))
			var h0 := {"ult_ember": Phoenix.HIT0, "ult_nerei": TideSanctum.HIT0, "ult_astra": StarParade.HIT0}.get(sid, TimeStill.HIT0) as float
			for i in targets.size():
				hits.append(fx_at + h0 + 0.05 * float(i))
	if stage >= 3:
		# 3단계: 효과 시작에 금 불티 비 40 + 첫 맞음에 짧은 금 섬광(0.2 이하 — B5)과 흔들림 1.4배
		after(fx_at, func() -> void: gold_rain(40))
		var hf: float = hits[0] if not hits.is_empty() else 1.2
		after(hf, func() -> void:
			Fx.flash(Color(GOLD, 0.2), 0.08)
			Fx.shake(1.4, 0.4))
	return {"hits": hits, "total": ULT_TOTAL, "sub": sub}


## 연쇄 3단계: 화면 위에서 금 불티가 비처럼 내림 (n개)
static func gold_rain(n: int) -> void:
	var layer := PParticles.get_layer(true)
	for i in n:
		var p := Vector2(randf_range(10, 630), randf_range(-20, 60))
		layer.spawn(p, Vector2(randf_range(-20, 20), randf_range(120, 260)), Vector2(0, 80), randf_range(0.7, 1.1), randf_range(1.2, 2.4), GOLD, Color(GOLD, 0.0), 0, 0.3)


## 대마법 컷인 띠: 화면 위 층(HUD 위)에 비스듬히(−12°) 가로지르는 높이 90 띠. 그 마녀를 4배로 띠 안에 잘라 보이고 대마법 이름을 30px로.
## 0.1초에 왼쪽에서 들어와 멈췄다가 끝 0.1초에 오른쪽으로 나간다 (장르 공통 구조 — 특정 작품의 컷인 모양 복제 아님)
static func cutin(caster: TActor, title: String, emblem_kind: String, stage: int, pal: Dictionary) -> void:
	if not is_instance_valid(caster) or caster.unit == null:
		return
	var c := UltCutin.new()
	c.unit = caster.unit
	c.title = title
	c.emblem_kind = emblem_kind
	c.stage = stage
	c._c = pal
	ui_layer().add_child(c)


## HUD(층 20) 위·화면 섬광(층 50) 아래의 연출 층 (컷인·브레이크 글)
static func ui_layer() -> CanvasLayer:
	var sc := Fx.get_tree().current_scene
	var l := sc.get_node_or_null("UltLayer") as CanvasLayer
	if l == null:
		l = CanvasLayer.new()
		l.name = "UltLayer"
		l.layer = 25
		l.offset = TTheme.ofs # 넓은 화면: 설계 화면 자리 (review_K K-01)
		sc.add_child(l)
	return l


## 마녀 문장 무늬 (대마법 문장 고리 가운데·컷인 띠 바탕에 같이 씀). r = 반지름, rot = 돌림
static func emblem(pd: PDraw, kind: String, c: Vector2, r: float, col: Color, rot := 0.0) -> void:
	if r <= 0.5 or col.a <= 0.0:
		return
	var w := maxf(r * 0.07, 0.8)
	var P := func(v: Vector2) -> Vector2: return c + v.rotated(rot) * r
	pd.draw_arc(c, r, 0.0, TAU, 36, col, w)
	pd.draw_arc(c, r * 0.84, 0.0, TAU, 36, Color(col, col.a * 0.55), w * 0.6)
	match kind:
		"sun":
			pd.draw_circle(c, r * 0.3, col)
			for i in 8:
				var an := TAU * float(i) / 8.0
				var d := Vector2.from_angle(an)
				pd.convex(PackedVector2Array([P.call(d * 0.4 + d.orthogonal() * 0.08), P.call(d * 0.74), P.call(d * 0.4 - d.orthogonal() * 0.08)]), col)
		"bird":
			pd.draw_colored_polygon(PackedVector2Array([P.call(Vector2(0, -0.12)), P.call(Vector2(-0.7, -0.5)), P.call(Vector2(-0.42, 0.02)), P.call(Vector2(-0.12, 0.08)),
				P.call(Vector2(0, 0.62)), P.call(Vector2(0.12, 0.08)), P.call(Vector2(0.42, 0.02)), P.call(Vector2(0.7, -0.5))]), col)
			pd.draw_circle(P.call(Vector2(0, -0.28)), r * 0.1, col)
		"urn":
			pd.draw_colored_polygon(PackedVector2Array([P.call(Vector2(-0.22, -0.32)), P.call(Vector2(0.22, -0.32)), P.call(Vector2(0.14, -0.2)), P.call(Vector2(0.4, 0.1)),
				P.call(Vector2(0.24, 0.5)), P.call(Vector2(-0.24, 0.5)), P.call(Vector2(-0.4, 0.1)), P.call(Vector2(-0.14, -0.2))]), col)
			for i in 3:
				pd.draw_circle(P.call(Vector2(-0.2 + 0.2 * float(i), -0.48 - 0.1 * float(i % 2))), r * 0.06, col)
		"drop":
			var pts := PackedVector2Array()
			for i in 17:
				var an := PI * 0.25 + (TAU - PI * 0.5) * float(i) / 16.0
				pts.append(P.call(Vector2(cos(an + PI * 0.5), sin(an + PI * 0.5)) * 0.36 + Vector2(0, 0.14)))
			pts.append(P.call(Vector2(0, -0.6)))
			pd.draw_colored_polygon(pts, col)
			pd.draw_arc(P.call(Vector2(0, 0.14)), r * 0.18, rot, rot + PI * 1.4, 10, Color(0, 0, 0, col.a * 0.6), w)
		"wave":
			for j in 3:
				var pts := PackedVector2Array()
				for i in 13:
					var f := float(i) / 12.0
					pts.append(P.call(Vector2(-0.6 + 1.2 * f, -0.3 + 0.3 * float(j) + sin(f * TAU * 1.5) * 0.08)))
				pd.draw_polyline(pts, col, w * 1.3)
		"flake":
			for i in 6:
				var d := Vector2.from_angle(TAU * float(i) / 6.0 + PI * 0.5)
				pd.draw_line(P.call(Vector2.ZERO), P.call(d * 0.7), col, w * 1.2)
				for kk in 2:
					var b := d * (0.3 + 0.2 * float(kk))
					pd.draw_line(P.call(b), P.call(b + d.rotated(0.8) * 0.16), col, w)
					pd.draw_line(P.call(b), P.call(b + d.rotated(-0.8) * 0.16), col, w)
		"hammer":
			pd.convex(PackedVector2Array([P.call(Vector2(-0.46, -0.48)), P.call(Vector2(0.46, -0.48)), P.call(Vector2(0.46, -0.14)), P.call(Vector2(-0.46, -0.14))]), col)
			pd.draw_line(P.call(Vector2(0, -0.14)), P.call(Vector2(0, 0.66)), col, w * 1.8)
			pd.draw_polyline(PackedVector2Array([P.call(Vector2(-0.3, 0.1)), P.call(Vector2(-0.12, 0.26)), P.call(Vector2(-0.3, 0.38)), P.call(Vector2(-0.12, 0.56))]), col, w)
		"star8":
			var pts := PackedVector2Array()
			for i in 16:
				var an := TAU * float(i) / 16.0 - PI * 0.5
				pts.append(P.call(Vector2.from_angle(an) * (0.66 if i % 2 == 0 else 0.26)))
			pd.draw_colored_polygon(pts, col)
		"cloud":
			for cc: Array in [[-0.26, -0.12, 0.22], [0.0, -0.26, 0.26], [0.26, -0.1, 0.22]]:
				pd.draw_circle(P.call(Vector2(cc[0], cc[1])), r * float(cc[2]), col)
			pd.convex(PackedVector2Array([P.call(Vector2(-0.5, -0.06)), P.call(Vector2(0.5, -0.06)), P.call(Vector2(0.44, 0.08)), P.call(Vector2(-0.44, 0.08))]), col)
			pd.draw_colored_polygon(PackedVector2Array([P.call(Vector2(0.06, 0.12)), P.call(Vector2(-0.14, 0.42)), P.call(Vector2(0.02, 0.4)), P.call(Vector2(-0.1, 0.7)),
				P.call(Vector2(0.18, 0.32)), P.call(Vector2(0.02, 0.34)), P.call(Vector2(0.18, 0.12))]), col)
		"rift":
			EVfx.star4(pd, c, r * 0.72, rot + 0.785, col, Color(col, 0.0))
			pd.draw_circle(c, r * 0.16, Color(INK, col.a))
		"clock":
			for i in 12:
				var d := Vector2.from_angle(TAU * float(i) / 12.0)
				pd.draw_line(P.call(d * (0.56 if i % 3 == 0 else 0.64)), P.call(d * 0.74), col, w * (1.4 if i % 3 == 0 else 0.8))
			pd.draw_line(c, P.call(Vector2(0, -0.52)), col, w * 1.4)
			pd.draw_line(c, P.call(Vector2(0.36, 0.1)), col, w * 1.8)
		"blades":
			for sgn: float in [-1.0, 1.0]:
				var d := Vector2(sgn * 0.7, -0.7)
				pd.convex(PackedVector2Array([P.call(-d * 0.95), P.call(d.orthogonal() * 0.07), P.call(d * 0.95), P.call(-d.orthogonal() * 0.07)]), col)
				pd.draw_line(P.call(-d * 0.62 + d.orthogonal() * 0.16), P.call(-d * 0.62 - d.orthogonal() * 0.16), col, w * 1.4)


## 대마법 효과의 공통 바탕
class UltBase extends PVfx.Base:
	var _c: Dictionary = TFx.cur
	var s := 1.0 ## 연쇄 배율 (1 · 1.15 · 1.3)
	var foes: Array = []
	var allies: Array = []
	var caster: TActor

	func _alive(a) -> bool:
		return is_instance_valid(a)


## 어둡게: 배경만 먹빛으로 덮고(유닛은 위라 밝게 남음) 시전자 둘레는 속성 빛. mono(에스카·하르페)는 흰빛 테 대신 흑백
class UltDim extends PVfx.Base:
	var _c: Dictionary = TFx.cur
	var caster: TActor
	var stage := 1
	var mono := false

	func _ready() -> void:
		life = TFx.ULT_TOTAL
		z_index = -6 # 배경(−10) 위 · 유닛(1~3)·땅 연출(−5~−2) 아래

	func _paint() -> void:
		var a := smoothstep(0.0, TFx.ULT_DIM, t) * (1.0 - smoothstep(TFx.ULT_TOTAL - 0.35, TFx.ULT_TOTAL, t))
		pd.draw_rect(TTheme.screen().grow(80.0), Color(Color(INK).lerp(_c.dark, 0.35), (0.78 if mono else 0.64) * a))
		var edge: Color = Color(GOLD, 0.0) if stage < 2 else Color(GOLD, (0.16 if stage == 2 else 0.35) * a) # 3단계는 화면 가장자리 금빛 고리 진하게 (B3)
		if mono:
			pd.rect_grad(Rect2(TTheme.left() - 80.0, -80 - TTheme.ofs.y, TTheme.view.x + 160.0, 140), Color(WHITE, 0.10 * a), Color(WHITE, 0.0))
		else:
			pd.rect_grad(Rect2(TTheme.left() - 80.0, 300, TTheme.view.x + 160.0, 140 + TTheme.ofs.y), Color(_c.deep, 0.0), Color(_c.deep, 0.28 * a))
		if edge.a > 0.0:
			pd.ring_grad(Vector2(320, 180), Vector2(260, 140), Vector2(420, 280), Color(edge, 0.0), edge, 32)
		if is_instance_valid(caster):
			pd.glow(caster.center() + Vector2(0, 10), 80.0, Color(_c.flame if not mono else PALE, 0.22 * a), 0.0)


## 문장 고리: 시전자 발밑 원근 고리 두 겹(연쇄 2단계부터 세 겹) + 도는 룬 + 등 뒤에 선 그 마녀의 문장 + 위로 오르는 빛
class UltSigil extends PVfx.Base:
	var _c: Dictionary = TFx.cur
	var emblem := "rift"
	var stage := 1
	var actor: TActor

	func _ready() -> void:
		life = 1.5
		z_index = -5

	func _tick(_d: float) -> void:
		if t < 0.9 and randf() < 0.5:
			var an := randf() * TAU
			var r := 36.0 + 8.0 * float(stage)
			PParticles.get_layer(true).spawn(global_position + Vector2(cos(an) * r, sin(an) * r * 0.34), Vector2(0, -randf_range(40, 100)), Vector2.ZERO, 0.6, randf_range(1.0, 2.0), _c.hot, Color(_c.flame, 0.0), 0, 0.5)

	func _paint() -> void:
		var appear := 1.0 - pow(1.0 - smoothstep(0.0, 0.3, t), 2.0)
		var a := appear * (1.0 - smoothstep(1.15, 1.5, t))
		var sc := 1.0 + 0.15 * float(stage - 1)
		var R := 40.0 * sc * appear
		var hot: Color = _c.hot
		# 오르는 빛 (고리 안 세로 띠)
		pd.rect_grad(Rect2(-R * 0.55, -130.0 * sc, R * 1.1, 130.0 * sc), Color(hot, 0.0), Color(hot, 0.16 * a))
		pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.34))
		pd.glow(Vector2.ZERO, R * 1.35, Color(_c.flame, 0.28 * a), 0.0)
		pd.draw_arc(Vector2.ZERO, R, 0.0, TAU, 40, Color(hot, 0.95 * a), 1.8)
		pd.draw_arc(Vector2.ZERO, R * 0.8, 0.0, TAU, 40, Color(_c.flame, 0.8 * a), 1.0)
		for i in 12: # 고리 사이 룬 (짧은 가로 획 + 점)
			var an := TAU * float(i) / 12.0 + t * 1.2
			var p := Vector2.from_angle(an) * R * 0.9
			pd.draw_line(p - Vector2.from_angle(an + PI * 0.5) * 2.4, p + Vector2.from_angle(an + PI * 0.5) * 2.4, Color(_c.core, a), 1.2)
		if stage >= 2:
			for i in 16: # 바깥 점선 고리 (금)
				var a0 := TAU * float(i) / 16.0 - t * 0.8
				pd.draw_arc(Vector2.ZERO, R * 1.24, a0, a0 + 0.24, 4, Color(GOLD, 0.9 * a), 1.4)
		if stage >= 3:
			pd.draw_arc(Vector2.ZERO, R * 1.45, 0.0, TAU, 44, Color(GOLD, 0.6 * a), 1.0)
		pd.draw_set_transform(Vector2.ZERO)
		# 등 뒤 문장 (세로로 선 원판)
		TFx.emblem(pd, emblem, Vector2(0, -46.0 * sc), 22.0 * sc * appear, Color(hot, 0.6 * a), t * 0.5)
		if stage >= 3:
			for i in 8:
				var d := Vector2.from_angle(TAU * float(i) / 8.0 + t)
				pd.line2(Vector2(0, -46.0 * sc) + d * 24.0 * sc, Vector2(0, -46.0 * sc) + d * 44.0 * sc, Color(GOLD, 0.6 * a), Color(GOLD, 0.0), 1.6, 0.3)


## 컷인 띠 (UltLayer 위). 뿌리는 돌리지 않고(글자가 픽셀 글꼴이라 똑바로), 띠만 −12° 돌린 자식에 그린다.
## 그 마녀(4배, 모자~가슴)는 띠 크기의 작은 SubViewport(940×90)에 그려 띠의 그림으로 붙인다 — 띠 밖으로 넘치지 않는다
## (clip_children은 호환 렌더러에서 믿을 수 없어 쓰지 않음)
class UltCutin extends Node2D:
	const LIFE := 0.45
	const ANG := -12.0
	const ANG2 := 8.0 ## 연쇄 3단계의 둘째 띠
	const C := Vector2(320, 160) ## 띠 가운데
	const BAND := Vector2(940, 90)
	const FIG_SC := 3.0 ## 컷인 그림 배율 (검토 O §5: 4배 → 3배 — 모자 끝부터 가슴까지 띠 안에)
	const FIG_FEET_Y := 150.0 ## SubViewport(높이 90) 안 발 자리: 모자 끝(로컬 −48 × 3 = −144) → y 6, 얼굴(−30) → y 60
	const SS := 2 ## 컷인 그림을 2배 해상도로 그려 줄여 씀 (웹 = GLES3라 2D MSAA가 없음 — 3배 다각형 가장자리 계단을 없앰, 검토 O §5)
	var unit: TUnit
	var title := ""
	var emblem_kind := "rift"
	var stage := 1
	var _c: Dictionary = TFx.cur
	var t := 0.0
	var _rot: Node2D
	var _band: CutBand
	var _rot2: Node2D
	var _band2: CutBand
	var _vp: SubViewport
	var _fig: TActor
	var _lab: CutLabel

	func _ready() -> void:
		_vp = SubViewport.new()
		_vp.size = Vector2i(BAND) * SS
		_vp.transparent_bg = true
		_vp.disable_3d = true
		_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(_vp)
		_vp.canvas_transform = Transform2D(0.0, Vector2(SS, SS), 0.0, Vector2.ZERO) # 트리에 넣은 뒤 (캔버스가 생긴 다음)
		_fig = TActor.new()
		_fig.deco = false
		_vp.add_child(_fig)
		_fig.setup(unit, Vector2(320, 160))
		_fig.scale = Vector2(FIG_SC, FIG_SC)
		_fig.z_index = 0
		_fig.pose("cast_big")
		var art: PDraw.Canvas = _fig.witch if _fig.witch != null else (_fig.eska.art if _fig.eska != null else null)
		if art != null:
			art.pd.seg_k = FIG_SC * SS # 원·빛무리를 6배 꼭짓점으로 다시 그림 (작은 원이 9각형으로 보이던 것)
		_rot = Node2D.new()
		_rot.rotation = deg_to_rad(ANG)
		_rot.position = C
		add_child(_rot)
		_band = CutBand.new()
		_band.cut = self
		_band.tex = _vp.get_texture()
		_band.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR # 2배 그림을 줄이고 −12° 돌린 띠 — 가장 가까운 픽셀이면 가장자리가 계단 (검토 O §5)
		_rot.add_child(_band)
		if stage >= 3: # 3단계: 반대로 기운 둘째 띠 (+8°, 0.05초 늦게) — 첫 띠 뒤에
			_rot2 = Node2D.new()
			_rot2.rotation = deg_to_rad(ANG2)
			_rot2.position = C + Vector2(0, 6)
			add_child(_rot2)
			move_child(_rot2, _rot.get_index())
			_band2 = CutBand.new()
			_band2.cut = self
			_band2.second = true
			_rot2.add_child(_band2)
		_lab = CutLabel.new()
		_lab.cut = self
		add_child(_lab)
		_place()

	## 들어오고(0.1초) 나가는(끝 0.1초) 가로 밀림
	func off() -> float:
		var a := clampf(t / 0.1, 0.0, 1.0)
		var b := clampf((t - (LIFE - 0.1)) / 0.1, 0.0, 1.0)
		return lerpf(-820.0, 0.0, 1.0 - pow(1.0 - a, 3.0)) + 820.0 * b * b

	func _place() -> void:
		var o := off()
		_band.position = Vector2(o, 0)
		if _band2 != null:
			var a := clampf((t - 0.05) / 0.1, 0.0, 1.0)
			var b := clampf((t - (LIFE - 0.1)) / 0.1, 0.0, 1.0)
			_band2.position = Vector2(lerpf(820.0, 0.0, 1.0 - pow(1.0 - a, 3.0)) - 820.0 * b * b, 0) # 반대쪽에서 들어옴
			_band2.queue_redraw()
		# 띠 안에서 천천히 밀림 — 눈이 띠 가운데에 오게 12px 내림 (review_D B6: 모자 챙 그늘에 얼굴이 묻혔다)
		_fig.home = Vector2(340.0 - 40.0 * t / LIFE, FIG_FEET_Y)
		_lab.position = Vector2(o * 1.15, 0)

	func _process(delta: float) -> void:
		t += delta
		if t >= LIFE:
			queue_free()
			return
		_place()
		_band.queue_redraw()
		_lab.queue_redraw()


class CutBand extends PDraw.Canvas:
	var cut: UltCutin
	var tex: Texture2D
	var second := false ## 연쇄 3단계의 둘째 띠 (금빛 바탕 · 그림 없음)

	func _paint() -> void:
		var c: Dictionary = cut._c
		var t := cut.t
		var H := 45.0
		if second:
			pd.rect_grad(Rect2(-470, -30, 940, 30), Color(c.dark, 0.0), Color(GOLD, 0.55))
			pd.rect_grad(Rect2(-470, 0, 940, 30), Color(GOLD, 0.55), Color(c.dark, 0.0))
			for i in 12:
				var y := -24.0 + 48.0 * EVfx.hash01(i * 11 + 5)
				var x := fposmod(EVfx.hash01(i * 29) * 940.0 + t * 1800.0, 940.0) - 470.0
				pd.line2(Vector2(x, y), Vector2(x + 90.0, y), Color(GOLD, 0.0), Color(WHITE, 0.7), 0.4, 1.4)
			return
		pd.rect_grad(Rect2(-470, -H, 940, H), Color(c.dark, 0.97), Color(c.deep, 0.97))
		pd.rect_grad(Rect2(-470, 0, 940, H), Color(c.deep, 0.97), Color(c.dark, 0.97))
		pd.glow(Vector2(-150, -8), 90.0, Color(c.flame, 0.45), 0.0)
		TFx.emblem(pd, cut.emblem_kind, Vector2(170, 0), 64.0, Color(c.hot, 0.16), t * 0.8)
		# 머리 뒤 역광 — 모자 챙 아래 얼굴이 뜨게 (B6). 마녀 그림은 SubViewport에서 x ≈ 300~340
		pd.glow(Vector2(-134, 12), 50.0, Color(c.hot, 0.35), 0.0) # 얼굴(SubViewport y 60) 뒤
		for i in 16: # 속도선 (왼쪽으로 흐름)
			var y := -40.0 + 80.0 * EVfx.hash01(i * 17 + 3)
			var len := 60.0 + 110.0 * EVfx.hash01(i * 5 + 1)
			var x := fposmod(EVfx.hash01(i * 31) * 940.0 - t * 1600.0, 940.0) - 470.0
			pd.line2(Vector2(x, y), Vector2(x + len, y), Color(c.core, 0.5), Color(c.hot, 0.0), 1.4, 0.4)
		if cut.stage >= 2: # 연쇄 2단계부터 금빛 속도선 8줄 더 (B3)
			for i in 8:
				var y := -38.0 + 76.0 * EVfx.hash01(i * 23 + 7)
				var len := 90.0 + 120.0 * EVfx.hash01(i * 13 + 2)
				var x := fposmod(EVfx.hash01(i * 41 + 9) * 940.0 - t * 2200.0, 940.0) - 470.0
				pd.line2(Vector2(x, y), Vector2(x + len, y), Color(WHITE, 0.85), Color(GOLD, 0.0), 2.0, 0.6)

	func _draw() -> void:
		super()
		if second:
			draw_rect(Rect2(-470, -31, 940, 2), GOLD)
			draw_rect(Rect2(-470, 29, 940, 2), GOLD)
			return
		if tex != null:
			draw_texture_rect(tex, Rect2(-470, -45, 940, 90), false)
		var c: Dictionary = cut._c
		var edge: Color = GOLD if cut.stage >= 2 else c.hot
		var ew := 3.5 if cut.stage >= 2 else 2.5 # 2단계부터 금테 굵게
		draw_rect(Rect2(-470, -45, 940, ew), edge)
		draw_rect(Rect2(-470, 45.0 - ew, 940, ew), edge)
		draw_rect(Rect2(-470, -41.5, 940, 1.0), Color(WHITE, 0.5))
		draw_rect(Rect2(-470, 40.5, 940, 1.0), Color(WHITE, 0.5))


class CutLabel extends Node2D:
	const T := preload("res://proto/turn/t_theme.gd")
	var cut: UltCutin

	func _draw() -> void:
		var x := 262.0
		var y := 168.0 # 띠 가운데 줄(−12°)을 따라 글을 놓는다
		T.text(self, Vector2(x, y - 30), cut.unit.name if cut.unit != null else "", 12, Color(T.TEXT, 0.95))
		T.text(self, Vector2(x, y), cut.title, 30, WHITE)
		if cut.stage == 2:
			T.text(self, Vector2(x + T.width(cut.title, 30) + 10.0, y - 2), "연쇄 2단계", 15, T.GOLD)
		elif cut.stage >= 3: # 3단계: 띠 가운데 위 24px 금 도장 (0.4초 동안 1.3 → 1.0배)
			var k := clampf(cut.t / 0.4, 0.0, 1.0)
			var sc := lerpf(1.3, 1.0, 1.0 - pow(1.0 - k, 3.0))
			var at := Vector2(330, 118)
			draw_set_transform(at, deg_to_rad(-12.0), Vector2(sc, sc))
			var w := T.width("연쇄 3단계", 24) + 16.0
			draw_rect(Rect2(-w * 0.5, -24, w, 30), Color(T.INK, 0.85))
			draw_rect(Rect2(-w * 0.5, -24, w, 30), T.GOLD, false, 2.0)
			T.text(self, Vector2(0, 0), "연쇄 3단계", 24, T.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
			draw_set_transform(Vector2.ZERO)


# ── 12개 효과 ─────────────────────────────────────────────

## 이그니스 · 태양 붕괴 (단일 한 방): 하늘에 태양이 맺혀 부풀고 → 한 점으로 무너져 표적에 내리꽂힘 → 빛살·불기둥 → 적 전체에 화상 불씨
class SunCollapse extends UltBase:
	const HIT := 0.62
	var target: TActor
	var _to := Vector2.ZERO
	var _sky := Vector2.ZERO
	var _hit := false
	var _spread := false

	func _ready() -> void:
		life = 1.3
		z_index = 9
		_to = target.center() if _alive(target) else Vector2(506, 210)
		_sky = Vector2(_to.x - 40.0, 122.0) # 적 카드(y 32~82) 아래 빈 하늘

	func _tick(_d: float) -> void:
		if t < 0.45 and randf() < 0.9:
			var an := randf() * TAU
			var p := _sky + Vector2.from_angle(an) * 90.0 * s
			PParticles.get_layer(true).spawn(p, (_sky - p) * 2.6, Vector2.ZERO, 0.36, randf_range(1.2, 2.4), _c.hot, Color(_c.flame, 0.0), 1, 0.0)
		if t >= HIT and not _hit:
			_hit = true
			Sfx.play(&"tn_ult_hit", 0.0)
			Fx.flash(Color(_c.gold, 0.18), 0.08) # 대마법 안의 화면 섬광은 0.2 이하·0.1초 이하 (review_D B5) — 밝기는 표적 둘레 빛이 맡음
			Fx.hitstop(0.16)
			Fx.shake(1.2, 0.45)
			var p := TFx.Pillar.new()
			p._c = _c
			p.h = 150.0 * s
			p.w = 22.0 * s
			TFx.add(p, Vector2(_to.x, _to.y + 40.0), true)
			TFx.embers(_to, 26, 320.0, Vector2.UP, 180.0, 0.7, Vector2(0, 240))
		if t >= HIT + 0.22 and not _spread:
			_spread = true
			for f in foes:
				if _alive(f):
					var b := TFx.FireBurst.new()
					b._c = _c
					b.size = 0.8
					TFx.add(b, (f as TActor).center(), true)

	func _paint() -> void:
		var form := 1.0 - pow(1.0 - smoothstep(0.0, 0.42, t), 2.0)
		var fall := clampf((t - 0.45) / (HIT - 0.45), 0.0, 1.0)
		var R := 30.0 * s * form * (1.0 - 0.6 * fall)
		var p := _sky.lerp(_to, fall * fall)
		# 하늘이 달아오름
		pd.rect_grad(Rect2(TTheme.left(), -TTheme.ofs.y, TTheme.view.x, 220 + TTheme.ofs.y), Color(_c.flame, 0.28 * form * (1.0 - smoothstep(HIT, 1.1, t))), Color(_c.flame, 0.0))
		if t < HIT:
			if fall > 0.0:
				pd.line2(_sky, p, Color(_c.flame, 0.0), Color(_c.hot, 0.9), 2.0, R * 1.6)
			pd.glow(p, R * 2.6, Color(_c.flame, 0.4), 0.0)
			pd.glow(p, R * 1.5, Color(_c.hot, 0.7), 0.0)
			for i in 14: # 코로나 (바깥으로 넘실대는 불꽃 혀)
				var d := Vector2.from_angle(TAU * float(i) / 14.0 + t * 1.5)
				TFx.tongue(pd, p + d * R * 0.85, d, R * (0.55 + 0.25 * sin(t * 18.0 + float(i) * 1.7)), R * 0.2, 0.95, sin(t * 20.0 + float(i)) * 2.0, _c)
			pd.draw_circle(p, R, _c.hot)
			pd.draw_circle(p, R * 0.72, _c.core)
			return
		var x := clampf((t - HIT) / (life - HIT), 0.0, 1.0)
		var g := 1.0 - pow(1.0 - minf(x * 1.8, 1.0), 2.0)
		var a := 1.0 - x
		pd.glow(_to, (50.0 + 50.0 * g) * s, Color(_c.flame, 0.55 * a), 0.0)
		pd.glow(_to, (18.0 + 14.0 * g) * s, Color(_c.core, 0.95 * a), 0.0)
		for i in 16:
			var d := Vector2.from_angle(TAU * float(i) / 16.0 + 0.1)
			var len := (60.0 + 120.0 * g) * s * (0.55 + 0.45 * EVfx.hash01(i * 7))
			pd.line2(_to + d * 8.0, _to + d * len, Color(_c.core, a), Color(_c.gold, 0.0), 4.0 * a, 0.3)
		pd.draw_set_transform(Vector2(_to.x, _to.y + 40.0), 0.0, Vector2(1.0, 0.3))
		pd.draw_arc(Vector2.ZERO, (20.0 + 150.0 * g) * s, 0.0, TAU, 44, Color(_c.gold, 0.9 * a * a), 3.0)
		pd.draw_set_transform(Vector2.ZERO)


## 엠버 · 불새의 축복 (전체 버프 + 다른 아군 크레딧): 파티 뒤에서 날개폭 220px 불새가 솟아 날개를 펴 파티를 감싸고 →
## 깃털 불티가 마녀마다 떨어지고(금빛 기운) → 다른 아군의 크레딧 칸으로 불씨가 날아가 박힘 (review_D B4: 예전엔 공격하러 날아가는 모양이었다)
class Phoenix extends UltBase:
	const HIT0 := 0.5
	const RISE := 0.3 ## 솟아 날개를 펴는 시간
	const FLY := 0.32 ## 불씨가 크레딧 칸까지 날아가는 시간
	var _given := false
	var _home := Vector2(170, 132) ## 날개 가운데 (파티 머리 위 빈 하늘)
	var _sparks: Array = [] ## [시작(월드), 끝(월드)]

	func _ready() -> void:
		life = 1.35
		z_index = 9
		Sfx.play(&"phoenix_cry", -6.0) # 마녀별 소리 한 겹 (review_D B2)
		var sx := 0.0
		var n := 0
		for a in allies:
			if _alive(a):
				sx += (a as TActor).center().x
				n += 1
		if n > 0:
			_home.x = sx / float(n)
		var inv := get_viewport().get_canvas_transform().affine_inverse()
		for a in allies:
			if not _alive(a) or a == caster:
				continue
			var ta := a as TActor
			var slot := int(ta.unit.slot)
			var cell := THud.panel_at(slot).position + Vector2(89.0, 32.0) + TTheme.ofs # 패널의 크레딧 칸 가운데 (화면 — 넓은 화면은 설계 자리 + ofs)
			_sparks.append([ta.head(), inv * cell])

	func _center() -> Vector2:
		var r := 1.0 - pow(1.0 - clampf(t / RISE, 0.0, 1.0), 3.0)
		var up := smoothstep(1.0, 1.35, t)
		return Vector2(_home.x, lerpf(320.0, _home.y, r) - 40.0 * up)

	func _tick(_d: float) -> void:
		var c := _center()
		if t > RISE * 0.6 and t < 1.0 and randf() < 0.9: # 깃털 불티가 파티 위로 떨어짐
			PParticles.get_layer(true).spawn(c + Vector2(randf_range(-100, 100) * s, randf_range(-6, 14)), Vector2(randf_range(-14, 14), randf_range(30, 80)), Vector2(0, 50), 0.8, randf_range(1.2, 2.6), _c.hot, Color(_c.deep, 0.0), 0, 0.6)
		if t >= HIT0 and not _given:
			_given = true
			Sfx.play(&"tn_bless", -3.0)
			for a in allies:
				if not _alive(a):
					continue
				var au := TFx.Aura.new()
				au._c = _c
				au.col = _c.gold
				au.kind = "atk"
				TFx.add(au, (a as TActor).center(), true)
		for sp: Array in _sparks: # 크레딧 칸에 박히는 순간
			if sp.size() == 2 and t >= HIT0 + FLY:
				sp.append(true)
				TFx.add(_credit_pop(), sp[1] as Vector2, true)

	func _credit_pop() -> Node2D:
		var cr := CreditRise.new()
		cr.n = 2
		return cr

	func _paint() -> void:
		var c := _center()
		var open := 1.0 - pow(1.0 - clampf((t - 0.05) / RISE, 0.0, 1.0), 2.0)
		var a := 1.0 - smoothstep(1.0, 1.35, t)
		var sz := s
		var beat := sin(t * 9.0) * (1.0 - open * 0.7) # 펴진 뒤엔 천천히 숨쉼
		pd.glow(c, 120.0 * sz * open, Color(_c.flame, 0.22 * a), 0.0)
		pd.glow(c + Vector2(0, 50), 150.0 * sz * open, Color(_c.hot, 0.12 * a), 0.0) # 파티를 감싸는 빛
		# 날개: 어깨 → 손목(위로 솟음) → 날개 끝(파티 양옆으로 내려옴) 활 모양 막 + 아래 가장자리에서 처진 깃 7개씩
		for sg: float in [-1.0, 1.0]:
			var arm := PackedVector2Array()
			var low := PackedVector2Array()
			for i in 9:
				var f := float(i) / 8.0
				var x := sg * (8.0 + 104.0 * f) * sz * open
				var y := (-34.0 * sin(f * PI * 0.8) + 30.0 * f * f) * sz * open - 6.0 * beat * f
				arm.append(c + Vector2(x, y))
				low.append(c + Vector2(x, y + (20.0 - 12.0 * f) * sz * open))
			var mem := PackedVector2Array(arm)
			for i in range(low.size() - 1, -1, -1):
				mem.append(low[i])
			pd.draw_colored_polygon(mem, Color(_c.deep, 0.75 * a))
			pd.draw_polyline(arm, Color(_c.hot, a), 2.4 * sz)
			pd.draw_polyline(arm, Color(_c.core, 0.8 * a), 1.0)
			for i in 7:
				var f := (float(i) + 0.5) / 7.0
				var base := low[int(f * 8.0)]
				var d := Vector2(sg * (0.35 + 0.5 * f), 1.0).normalized()
				TFx.tongue(pd, base + Vector2(0, -4) * sz, d, (14.0 + 16.0 * f) * sz * open, (4.6 - 1.2 * f) * sz, a, sin(t * 14.0 + float(i)) * 2.0 * sg, _c)
		# 꼬리 (아래로 셋)
		for i in 3:
			var td := Vector2.DOWN.rotated((float(i) - 1.0) * 0.32)
			TFx.tongue(pd, c + Vector2(0, 8) * sz, td, 46.0 * sz, 5.0 * sz, a, sin(t * 12.0 + float(i)) * 5.0, _c)
		# 몸·머리 (몸통 1.3배)
		TFx.tongue(pd, c + Vector2(0, 12) * sz, Vector2.UP, 38.0 * sz, 12.0 * sz, a, 0.0, _c)
		var hd := c + Vector2(0, -28) * sz
		pd.glow(hd, 12.0 * sz, Color(_c.hot, 0.5 * a), 0.0)
		pd.draw_circle(hd, 6.0 * sz, Color(_c.hot, a))
		pd.draw_circle(hd, 3.8 * sz, Color(_c.core, a))
		pd.convex(PackedVector2Array([hd + Vector2(0, -9) * sz, hd + Vector2(2.2, -3) * sz, hd + Vector2(-2.2, -3) * sz]), Color(_c.gold, a)) # 볏
		for sg: float in [-1.0, 1.0]:
			pd.draw_circle(hd + Vector2(sg * 1.8, 0.4) * sz, 0.9 * sz, Color(INK, a))
		# 크레딧 칸으로 날아가는 불씨
		for sp: Array in _sparks:
			var f := clampf((t - HIT0) / FLY, 0.0, 1.0)
			if f <= 0.0 or f >= 1.0:
				continue
			var p0: Vector2 = sp[0]
			var p1: Vector2 = sp[1]
			var mid := (p0 + p1) * 0.5 + Vector2(0, -50)
			var q := p0.lerp(mid, f).lerp(mid.lerp(p1, f), f)
			var q0 := p0.lerp(mid, maxf(f - 0.12, 0.0)).lerp(mid.lerp(p1, maxf(f - 0.12, 0.0)), maxf(f - 0.12, 0.0))
			pd.line2(q0, q, Color(_c.flame, 0.0), Color(_c.hot, 0.9), 0.5, 3.0)
			pd.glow(q, 9.0, Color(GOLD, 0.6), 0.0)
			pd.draw_circle(q, 2.2, Color(WHITE, 1.0))


## 크레딧 마름모가 머리 위로 솟아 사라짐 (n개) — 자원이 생긴 것을 그림으로
class CreditRise extends PVfx.Base:
	var n := 2

	func _ready() -> void:
		life = 0.8
		z_index = 10

	func _paint() -> void:
		var x := k()
		var a := 1.0 - smoothstep(0.6, 1.0, x)
		for i in n:
			var p := Vector2((float(i) - (float(n) - 1.0) * 0.5) * 10.0, -24.0 * (1.0 - pow(1.0 - minf(x * 1.6, 1.0), 2.0)) - 4.0 * float(i % 2))
			pd.glow(p, 7.0, Color(GOLD, 0.5 * a), 0.0)
			pd.convex(PackedVector2Array([p + Vector2(0, -4), p + Vector2(3.2, 0), p + Vector2(0, 4), p + Vector2(-3.2, 0)]), Color(GOLD, a))
			pd.convex(PackedVector2Array([p + Vector2(0, -2.2), p + Vector2(1.6, 0), p + Vector2(0, 2.2), p + Vector2(-1.6, 0)]), Color(WHITE, a))


## 신더 · 잿빛 장례 (광역 + 화상 3겹 + 방어 다운): 적 위로 재구름이 덮이고 재가 내린 뒤, 적마다 장작불이 솟고 화상 불씨 셋이 돌고 금 간 방패가 내려앉음
class AshFuneral extends UltBase:
	const HIT0 := 0.42
	const STEP := 0.12
	var _flakes: Array = []
	var _lit := {}

	func _ready() -> void:
		life = 1.4
		z_index = 8
		for i in 46:
			_flakes.append(Vector3(randf_range(360, 660), randf_range(90, 170), randf_range(0.8, 2.0)))

	func _fx_at(i: int) -> float:
		return HIT0 - 0.06 + STEP * float(i)

	func _tick(_d: float) -> void:
		for i in foes.size():
			if not _lit.has(i) and t >= _fx_at(i):
				_lit[i] = true
				if _alive(foes[i]):
					var at: Vector2 = (foes[i] as TActor).center()
					var b := TFx.FireBurst.new()
					b._c = _c
					b.size = 1.5 * s
					TFx.add(b, at, true)
					TFx.embers(at, 12, 220.0, Vector2.UP, 100.0, 0.6)
					TFx.smoke(at + Vector2(0, 16), 3, 14.0)
					Fx.shake(0.5, 0.2)
					if i == 0:
						Sfx.play(&"tn_storm", -2.0)
						Sfx.play(&"tn_ult_hit", -4.0)

	func _paint() -> void:
		var cloud := smoothstep(0.0, 0.3, t) * (1.0 - smoothstep(1.05, 1.4, t))
		# 재구름 (적 진영 위): 아래가 평평한 뭉게 실루엣 + 아래 가장자리 주황 그을림 (review_D B4: 예전엔 흐린 원 줄)
		var by := 138.0
		var ash_dark := Color("#3e343c")
		pd.rect_grad(Rect2(350, by - 4.0, 300, 16), Color(_c.flame, 0.4 * cloud * (0.75 + 0.25 * sin(t * 9.0))), Color(_c.flame, 0.0))
		pd.draw_rect(Rect2(350, by - 18.0, 300, 18), Color(ash_dark, 0.9 * cloud))
		for i in 12:
			var cx := 356.0 + 26.0 * float(i) + sin(t * 2.0 + float(i)) * 3.0
			var rr := (16.0 + 10.0 * EVfx.hash01(i * 3 + 1)) * s
			pd.draw_circle(Vector2(cx, by - 14.0 - 8.0 * EVfx.hash01(i * 7)), rr * cloud, Color(ash_dark, 0.9 * cloud))
		for i in 12:
			var cx := 360.0 + 26.0 * float(i) + sin(t * 2.0 + float(i)) * 3.0
			var rr := (10.0 + 7.0 * EVfx.hash01(i * 5 + 2)) * s
			pd.draw_circle(Vector2(cx, by - 20.0 - 8.0 * EVfx.hash01(i * 7)), rr * cloud, Color("#5e525a", 0.85 * cloud))
		pd.draw_rect(Rect2(350, by - 1.0, 300, 1.5), Color(_c.flame, 0.7 * cloud))
		# 내리는 재
		for fl: Vector3 in _flakes:
			var y := fl.y + fmod(t * 160.0 * fl.z * 0.6, 160.0)
			var x := fl.x + sin(t * 3.0 + fl.y) * 8.0 - t * 20.0
			if y > 300.0:
				continue
			var ember := int(fl.x) % 5 == 0
			pd.draw_rect(Rect2(x, y, fl.z, fl.z), Color(_c.hot if ember else ASH, 0.8 * cloud))
		# 적마다 장작불 + 화상 불씨 셋 + 금 간 방패
		for i in foes.size():
			var f: TActor = foes[i] if _alive(foes[i]) else null
			if f == null:
				continue
			var lt := t - _fx_at(i)
			if lt <= 0.0:
				continue
			var burn := 1.0 - pow(1.0 - minf(lt / 0.2, 1.0), 2.0)
			var fade := 1.0 - smoothstep(0.55, 0.95, lt)
			var ft := f.feet()
			pd.glow(ft + Vector2(0, -24), 44.0 * s * burn, Color(_c.flame, 0.35 * fade), 0.0)
			for j in 9: # 장작불: 높이·폭을 흩고 가운데 높게 (예전엔 같은 높이 빗살이 울타리처럼 줄지었다)
				var e := float(j) - 4.0
				var hr := EVfx.hash01(i * 31 + j * 7)
				var ox := e * 6.5 * s + (EVfx.hash01(i * 13 + j) - 0.5) * 4.0
				var ph := t * 15.0 + float(j) * 1.3 + float(i)
				var h := (64.0 - 9.0 * absf(e)) * (0.6 + 0.4 * hr) * s * burn * (0.85 + 0.15 * sin(ph))
				TFx.tongue(pd, ft + Vector2(ox, 0), Vector2.UP.rotated(e * 0.06), h, (3.6 + 2.6 * hr) * s, fade, sin(ph * 0.6) * 4.0, _c)
			for j in 8: # 떠오르는 재 조각 (사각 3px 회전)
				var ph := fposmod(lt * 0.9 + EVfx.hash01(i * 7 + j * 3), 1.0)
				var p := ft + Vector2((EVfx.hash01(j * 11 + i) - 0.5) * 50.0 + sin(t * 3.0 + float(j)) * 5.0, -20.0 - 90.0 * ph)
				var r := t * 4.0 + float(j)
				var q := Vector2.from_angle(r) * 1.6
				pd.convex(PackedVector2Array([p + q, p + q.orthogonal(), p - q, p - q.orthogonal()]), Color(ASH if j % 3 else _c.hot, fade * (1.0 - ph)))
			var c := f.center()
			for j in 3: # 화상 3겹 (도는 불씨)
				var an := t * 5.0 + TAU * float(j) / 3.0
				var p := c + Vector2(cos(an) * 24.0, sin(an) * 9.0 - 6.0)
				TFx.tongue(pd, p, Vector2.UP, 8.0 * burn, 2.6, burn * (1.0 - smoothstep(0.8, 1.0, lt)), 0.0, _c)
			if lt > 0.25: # 방어 다운: 머리 위로 내려앉는 금 간 방패
				var sa := smoothstep(0.25, 0.4, lt) * (1.0 - smoothstep(0.85, 1.0, lt))
				var sp := f.head() + Vector2(0, -16.0 + 8.0 * smoothstep(0.25, 0.5, lt))
				TFx.broken_shield(pd, sp, 7.0, Color(_c.hot, sa))


## 금 간 방패 (방어 다운 그림): 방패 윤곽 + 가운데 금 + 아래 화살
static func broken_shield(pd: PDraw, p: Vector2, r: float, col: Color) -> void:
	if col.a <= 0.0:
		return
	var sh := PackedVector2Array([p + Vector2(-r, -r), p + Vector2(r, -r), p + Vector2(r * 0.9, r * 0.3), p + Vector2(0, r * 1.2), p + Vector2(-r * 0.9, r * 0.3)])
	sh.append(sh[0])
	pd.draw_polyline(sh, Color(INK, col.a * 0.7), 3.0)
	pd.draw_polyline(sh, col, 1.4)
	pd.draw_polyline(PackedVector2Array([p + Vector2(-1, -r), p + Vector2(1.5, -r * 0.3), p + Vector2(-1.5, r * 0.2), p + Vector2(0.5, r * 1.1)]), col, 1.2)
	pd.convex(PackedVector2Array([p + Vector2(-r * 0.5, r * 1.6), p + Vector2(r * 0.5, r * 1.6), p + Vector2(0, r * 2.3)]), col)


## 운디네 · 심연 붕괴 (단일 한 방 + 크레딧 환급): 물줄기가 소용돌이치며 표적 위 검푸른 구체로 모임 → 내리눌러 터지는 물보라 왕관 → 빙결 + 크레딧 셋이 운디네에게 돌아감
class AbyssCollapse extends UltBase:
	const HIT := 0.62
	var target: TActor
	var _to := Vector2.ZERO
	var _sky := Vector2.ZERO
	var _hit := false
	var _refund := false

	func _ready() -> void:
		life = 1.35
		z_index = 9
		_to = target.center() if _alive(target) else Vector2(506, 210)
		_sky = _to + Vector2(0, -112)

	func _tick(_d: float) -> void:
		if t >= HIT and not _hit:
			_hit = true
			Sfx.play(&"tn_ult_hit", 0.0)
			Fx.flash(Color(_c.hot, 0.35), 0.1)
			Fx.hitstop(0.16)
			Fx.shake(1.1, 0.4)
			var pp := PParticles.get_layer(true)
			for i in 26:
				var an := randf_range(-PI * 0.95, -PI * 0.05)
				pp.spawn(_to, Vector2.from_angle(an) * randf_range(120, 320), Vector2(0, 420), randf_range(0.5, 0.8), randf_range(1.4, 2.8), _c.hot, Color(_c.flame, 0.0), 1, 0.5)
		if t >= HIT + 0.25 and not _refund:
			_refund = true
			if _alive(caster):
				var r := RefundOrbs.new()
				r._c = _c
				r.from = _to
				r.to = caster
				TFx.add(r, Vector2.ZERO, true)

	func _paint() -> void:
		var gather := smoothstep(0.0, 0.45, t)
		var fall := clampf((t - 0.48) / (HIT - 0.48), 0.0, 1.0)
		if t < HIT:
			# 빨려드는 물줄기 (나선 6줄)
			for i in 6:
				var pts := PackedVector2Array()
				for j in 12:
					var f := float(j) / 11.0
					var r := lerpf(130.0, 8.0, f) * s * (1.0 - 0.6 * gather)
					var an := float(i) * TAU / 6.0 + f * 3.2 + t * 7.0
					pts.append(_sky + Vector2(cos(an) * r, sin(an) * r * 0.6))
				pd.draw_polyline(pts, Color(_c.flame, 0.55 * (1.0 - fall)), 2.0)
				pd.draw_polyline(pts, Color(_c.core, 0.6 * (1.0 - fall)), 0.8)
			var R := 30.0 * s * gather
			var p := _sky.lerp(_to, fall * fall)
			var sq := Vector2(1.0 - 0.25 * fall, 1.0 + 0.4 * fall)
			pd.glow(p, R * 2.2, Color(_c.flame, 0.35), 0.0)
			pd.draw_set_transform(p, 0.0, sq)
			pd.draw_circle(Vector2.ZERO, R + 2.0, Color(_c.hot, 0.9))
			pd.draw_circle(Vector2.ZERO, R, _c.dark)
			pd.draw_circle(Vector2.ZERO, R * 0.75, Color(_c.deep, 0.9))
			for j in 3:
				pd.draw_arc(Vector2.ZERO, R * (0.3 + 0.18 * float(j)), t * (6.0 + float(j)), t * (6.0 + float(j)) + 2.4, 12, Color(_c.flame, 0.8), 1.2)
			pd.draw_circle(Vector2(-R * 0.35, -R * 0.4), R * 0.16, Color(_c.core, 0.9))
			pd.draw_set_transform(Vector2.ZERO)
			return
		var x := clampf((t - HIT) / (life - HIT), 0.0, 1.0)
		var g := 1.0 - pow(1.0 - minf(x * 2.0, 1.0), 2.0)
		var a := 1.0 - x
		var base := _to + Vector2(0, 30)
		pd.glow(_to, (44.0 + 30.0 * g) * s, Color(_c.flame, 0.5 * a), 0.0)
		for i in 12: # 물보라 왕관
			var an := -PI * 0.5 + (float(i) - 5.5) * 0.24
			var d := Vector2.from_angle(an)
			TFx.tongue(pd, base + Vector2(d.x * 16.0 * s, 0), d, (40.0 + 46.0 * g) * s * (0.7 + 0.3 * EVfx.hash01(i * 5)), 6.0 * s * (1.0 - 0.5 * x), a, 0.0, _c)
		pd.draw_set_transform(base, 0.0, Vector2(1.0, 0.3))
		pd.draw_arc(Vector2.ZERO, (20.0 + 130.0 * g) * s, 0.0, TAU, 44, Color(_c.core, 0.9 * a * a), 3.0)
		pd.draw_set_transform(Vector2.ZERO)
		# 빙결 (표적 둘레 얼음 조각)
		var fr := smoothstep(0.2, 0.4, x) * a
		for i in 5:
			var an := -PI * 0.5 + (float(i) - 2.0) * 0.5
			TFx.crystal(pd, base + Vector2((float(i) - 2.0) * 9.0, 0), Vector2.from_angle(an), 20.0 * fr, 4.0, Color(_c.hot, fr), Color(_c.core, fr))


## 얼음 결정 하나 (가늘고 긴 마름모 + 흰 심) — 빙결 연출 공용
static func crystal(pd: PDraw, base: Vector2, dir: Vector2, h: float, w: float, col: Color, core: Color) -> void:
	if h <= 0.5:
		return
	var side := dir.orthogonal()
	var tip := base + dir * h
	pd.convex(PackedVector2Array([base - side * w * 0.5, base + dir * h * 0.3 - side * w, tip, base + dir * h * 0.3 + side * w, base + side * w * 0.5]), col)
	pd.draw_line(base + dir * h * 0.2, tip - dir * h * 0.15, core, maxf(w * 0.25, 0.6))


## 크레딧 환급 구슬: 맞힌 자리에서 시전자에게 날아가 크레딧 마름모가 됨 (물의 자원 순환)
class RefundOrbs extends PVfx.Base:
	var _c: Dictionary = TFx.cur
	var from := Vector2.ZERO
	var to: TActor
	var _done := false

	func _ready() -> void:
		life = 0.75
		z_index = 10

	func _tick(_d: float) -> void:
		if t >= 0.5 and not _done:
			_done = true
			if is_instance_valid(to):
				var cr := TFx.CreditRise.new()
				cr.n = 3
				TFx.add(cr, to.head() + Vector2(0, -4), true)
				Sfx.play(&"tn_buff", -8.0)

	func _paint() -> void:
		if not is_instance_valid(to):
			return
		var f := clampf(t / 0.5, 0.0, 1.0)
		var a := 1.0 - smoothstep(0.5, 0.75, t)
		var dst := to.center()
		for i in 3:
			var ff := clampf(f - 0.08 * float(i), 0.0, 1.0)
			var e := ff * ff * (3.0 - 2.0 * ff)
			var p := from.lerp(dst, e) + Vector2(0, -sin(e * PI) * (50.0 + 16.0 * float(i)))
			pd.glow(p, 8.0, Color(_c.flame, 0.6 * a), 0.0)
			pd.convex(PackedVector2Array([p + Vector2(0, -3.6), p + Vector2(2.8, 0), p + Vector2(0, 3.6), p + Vector2(-2.8, 0)]), Color(GOLD, a))


## 네레이 · 해류의 성소 (무적 + 받는 피해 감소 + 회복 + 되살림): 아군 위로 물의 돔이 솟고 겉면을 해류가 돌며, 안에서 거품이 오른다 → 아군마다 결계·치유 빛
class TideSanctum extends UltBase:
	const HIT0 := 0.45
	var _given := false
	var _c0 := Vector2(160, 262)
	var _bub: Array = []

	func _ready() -> void:
		life = 1.3
		z_index = 7
		if not allies.is_empty():
			var c := Vector2.ZERO
			var n := 0
			for a in allies:
				if _alive(a):
					c += (a as TActor).feet()
					n += 1
			if n > 0:
				_c0 = c / float(n) + Vector2(0, 6)
		for i in 18:
			_bub.append(Vector3(randf_range(-110, 110), randf_range(0.0, 1.0), randf_range(1.0, 2.6)))

	func _tick(_d: float) -> void:
		if t >= HIT0 and not _given:
			_given = true
			Sfx.play(&"tn_heal", -2.0)
			Sfx.play(&"bl_unfold", -6.0)
			Sfx.play(&"ward", -6.0) # 돔이 닫힘 (review_D B2)
			for a in allies:
				if not _alive(a):
					continue
				var b := TFx.Barrier.new()
				TFx.add(b, (a as TActor).center(), false)
				var au := TFx.Aura.new()
				au._c = _c
				au.col = HEAL
				au.kind = "heal"
				TFx.add(au, (a as TActor).center(), true)

	func _paint() -> void:
		var rise := 1.0 - pow(1.0 - smoothstep(0.0, 0.35, t), 2.0)
		var a := 1.0 - smoothstep(1.0, 1.3, t)
		var rx := 150.0 * s
		var ry := 125.0 * s * rise
		# 돔 (반타원 면 + 테)
		var top := PackedVector2Array()
		for i in 25:
			var an := PI + PI * float(i) / 24.0
			top.append(_c0 + Vector2(cos(an) * rx, sin(an) * ry))
		var fill := top.duplicate()
		fill.append(_c0 + Vector2(rx, 0))
		pd.draw_colored_polygon(fill, Color(_c.flame, 0.13 * a))
		pd.draw_polyline(top, Color(_c.deep, 0.6 * a), 3.0)
		pd.draw_polyline(top, Color(_c.core, 0.85 * a), 1.2)
		# 겉면을 도는 해류 네 줄
		for j in 4:
			var pts := PackedVector2Array()
			var ph := t * 2.4 + float(j) * 0.9
			for i in 10:
				var f := fposmod(ph + float(i) * 0.05, 1.0)
				var an := PI + PI * f
				var k2 := 0.92 - 0.12 * float(j)
				pts.append(_c0 + Vector2(cos(an) * rx * k2, sin(an) * ry * k2 + sin(f * 12.0 + t * 6.0) * 2.0))
			for i in range(1, pts.size()):
				if pts[i].x > pts[i - 1].x:
					pd.line2(pts[i - 1], pts[i], Color(_c.core, 0.0), Color(_c.core, 0.7 * a), 0.6, 1.6)
		# 바닥 고리
		pd.draw_set_transform(_c0, 0.0, Vector2(1.0, 0.3))
		pd.draw_arc(Vector2.ZERO, rx, 0.0, TAU, 44, Color(_c.hot, 0.8 * a), 2.0)
		pd.glow(Vector2.ZERO, rx, Color(_c.flame, 0.14 * a), 0.0)
		pd.draw_set_transform(Vector2.ZERO)
		# 거품
		for b: Vector3 in _bub:
			var ph := fposmod(b.y + t * 0.7, 1.0)
			var p := _c0 + Vector2(b.x * (0.9 - 0.4 * ph), -ph * ry * 0.95)
			pd.draw_arc(p, b.z, 0.0, TAU, 8, Color(_c.core, 0.7 * a * (1.0 - ph)), 0.8)


## 글라시아 · 절대 영도 (적 전체 빙결 3겹 + 게이지 −50% + 방어 다운 + 차지 −1): 하늘에 큰 눈꽃 문장, 땅을 따라 서리 파도가 달려가 적마다 얼음 가시가 솟음 → 느려짐(아래 겹화살)
class AbsoluteZero extends UltBase:
	const HIT0 := 0.42
	const STEP := 0.1
	var _hitd := {}

	func _ready() -> void:
		life = 1.4
		z_index = 8

	func _fx_at(i: int) -> float:
		return HIT0 - 0.04 + STEP * float(i)

	func _tick(_d: float) -> void:
		for i in foes.size():
			if not _hitd.has(i) and t >= _fx_at(i):
				_hitd[i] = true
				if _alive(foes[i]):
					EVfx.shards((foes[i] as TActor).center(), 6, 180.0, Vector2(6, 10), 70.0)
					Fx.shake(0.5, 0.2)
					if i == 0:
						Sfx.play(&"tn_ult_hit", -4.0)
						Sfx.play(&"bl_unfold", -4.0)
						Sfx.play(&"kb_shatter", -4.0) # 얼음 기둥이 솟음 (review_D B2)

	func _paint() -> void:
		var cold := smoothstep(0.0, 0.25, t) * (1.0 - smoothstep(1.05, 1.4, t))
		pd.draw_rect(Rect2(-40, -40, 720, 440), Color(_c.deep, 0.14 * cold))
		TFx.emblem(pd, "flake", Vector2(470, 140), 56.0 * s * cold, Color(_c.hot, 0.4 * cold), t * 0.6)
		# 서리 파도 (왼쪽 → 오른쪽, 땅)
		var wx := lerpf(330.0, 680.0, smoothstep(0.08, 0.5, t))
		pd.draw_set_transform(Vector2(0, 0), 0.0, Vector2.ONE)
		var l := PackedVector2Array()
		var r := PackedVector2Array()
		for i in 12:
			var f := float(i) / 11.0
			var y := 214.0 + 90.0 * f
			var x := wx - 40.0 * f + sin(t * 20.0 + f * 7.0) * 4.0
			l.append(Vector2(x - 26.0, y))
			r.append(Vector2(x, y))
		pd.strip_grad(l, r, Color(_c.hot, 0.0), Color(_c.core, 0.8 * cold))
		# 지나간 땅의 서리 (옅은 띠)
		pd.draw_colored_polygon(PackedVector2Array([Vector2(330, 214), Vector2(wx, 214), Vector2(wx - 40, 304), Vector2(330, 304)]), Color(_c.flame, 0.12 * cold))
		for i in foes.size():
			var f: TActor = foes[i] if _alive(foes[i]) else null
			if f == null:
				continue
			var lt := t - _fx_at(i)
			if lt <= -0.08:
				continue
			var g := 1.0 - pow(1.0 - clampf((lt + 0.08) / 0.18, 0.0, 1.0), 2.0)
			var fade := 1.0 - smoothstep(0.6, 0.98, lt)
			var ft := f.feet()
			var hw := f.half_w()
			for j in 7: # 얼음 가시 (가운데가 가장 높음)
				var u := (float(j) - 3.0) / 3.0
				var dir := Vector2(u * 0.45, -1.0).normalized()
				TFx.crystal(pd, ft + Vector2(u * hw * 0.9, 2), dir, (70.0 - 30.0 * absf(u)) * s * g, 6.0 * s, Color(_c.flame, 0.85 * fade), Color(_c.core, fade))
			var c := f.center()
			for j in 3: # 빙결 3겹
				var an := t * 4.0 + TAU * float(j) / 3.0
				var p := c + Vector2(cos(an) * (hw + 10.0), sin(an) * 8.0)
				TFx.emblem(pd, "flake", p, 4.5 * g, Color(_c.core, fade), t * 2.0)
			if lt > 0.2: # 느려짐: 머리 위 아래 겹화살
				var sa := smoothstep(0.2, 0.35, lt) * fade
				var hp := f.head() + Vector2(0, -12.0 + 6.0 * fmod(lt * 2.0, 1.0))
				for q in 2:
					var y0 := hp.y + float(q) * 5.0
					pd.draw_polyline(PackedVector2Array([Vector2(hp.x - 6, y0 - 3), Vector2(hp.x, y0 + 2), Vector2(hp.x + 6, y0 - 3)]), Color(_c.core, sa), 2.0)


## 풀구르 · 뇌신의 철퇴 (단일 5단): 하늘이 어두워지고 표적 위에 번개 망치가 맺힘 → 번개 다섯 줄기가 차례로 내리치고 다섯째에 망치가 내려찍힘
class ThunderHammer extends UltBase:
	const HIT0 := 0.3
	const STEP := 0.1
	const SIZE := 1.4 ## 망치 크기 (review_D B4: 예전엔 작아 건전지처럼 보였다)
	var to := Vector2.ZERO
	var _n := 0
	var _cracks: Array = []

	func _ready() -> void:
		life = 1.25
		z_index = 9
		for i in 7: # 마지막 타의 바닥 금 (원근 타원 위 꺾은선)
			var an := TAU * float(i) / 7.0 + randf_range(-0.2, 0.2)
			var pts := PackedVector2Array([Vector2.ZERO])
			var p := Vector2.ZERO
			for j in 3:
				p += Vector2.from_angle(an + randf_range(-0.4, 0.4)) * randf_range(14.0, 26.0)
				pts.append(Vector2(p.x, p.y * 0.3))
			_cracks.append(pts)

	func _hammer_pos() -> Vector2:
		# 4타째 뒤 높이 들었다가(0.6 STEP) 5타째에 내려찍음
		var lift := smoothstep(HIT0 + STEP * 3.0, HIT0 + STEP * 3.6, t)
		var slam := clampf((t - (HIT0 + STEP * 3.6)) / (STEP * 0.4), 0.0, 1.0)
		var hover := Vector2(0, -96.0 * s - 18.0 * lift)
		return to + hover.lerp(Vector2(0, -30.0), slam * slam)

	func _tick(_d: float) -> void:
		while _n < 5 and t >= HIT0 + STEP * float(_n):
			_n += 1
			var last := _n == 5
			Sfx.play(&"tn_spear" if last else &"tn_crit", 0.0 if last else -6.0)
			Fx.shake(1.2 if last else 0.5, 0.4 if last else 0.12)
			if last:
				Sfx.play(&"tn_ult_hit", -2.0)
				Fx.flash(Color(_c.hot, 0.18), 0.08)
				Fx.hitstop(0.16)
				var sw := TFx.Shockwave.new()
				sw.col = _c.flame
				TFx.add(sw, to + Vector2(0, 40), true)
			TFx.embers(to, 10 if last else 5, 260.0, Vector2.UP, 180.0, 0.35, Vector2(0, 300))

	func _bolt(a: Vector2, b: Vector2, seed_i: int, w: float, al: float) -> void:
		var pts := PackedVector2Array([a])
		var n := 7
		for i in range(1, n):
			var f := float(i) / float(n)
			var p := a.lerp(b, f) + (b - a).normalized().orthogonal() * (EVfx.hash01(seed_i * 13 + i) - 0.5) * 26.0
			pts.append(p)
		pts.append(b)
		pd.draw_polyline(pts, Color(_c.deep, 0.6 * al), w * 2.6)
		pd.draw_polyline(pts, Color(_c.flame, al), w * 1.4)
		pd.draw_polyline(pts, Color(_c.core, al), w * 0.6)

	func _paint() -> void:
		var dark := smoothstep(0.0, 0.2, t) * (1.0 - smoothstep(0.9, 1.25, t))
		pd.rect_grad(Rect2(TTheme.left(), -TTheme.ofs.y, TTheme.view.x, 200 + TTheme.ofs.y), Color(_c.dark, 0.55 * dark), Color(_c.dark, 0.0))
		var form := 1.0 - pow(1.0 - smoothstep(0.0, 0.28, t), 2.0)
		var a := 1.0 - smoothstep(0.85, 1.15, t)
		# 휘두름 호 잔상: 1~4타마다 다른 각도 (흰 → 금 → 투명)
		for i in 4:
			var lt := t - (HIT0 + STEP * float(i)) + 0.04
			if lt < 0.0 or lt > 0.16:
				continue
			var x := lt / 0.16
			var a0 := [-2.4, -0.7, -2.0, -1.0][i] as float
			var span := 1.5
			var r := 62.0 * s
			var pts := PackedVector2Array()
			for q in 13:
				pts.append(to + Vector2.from_angle(a0 + span * float(q) / 12.0) * r)
			pd.draw_polyline(pts, Color(GOLD, 0.7 * (1.0 - x)), 7.0 * s * (1.0 - x * 0.5))
			pd.draw_polyline(pts, Color(WHITE, 0.95 * (1.0 - x)), 2.4)
		var hp := _hammer_pos()
		var sz := s * form * SIZE
		if sz > 0.05 and a > 0.0:
			# 망치: 위가 좁은 사다리꼴 쇠머리 + 금 테 + 가운데 룬 번개, 자루 + 감은 가죽 줄 둘 — 내려찍을 때 똑바로 선다
			var slam := smoothstep(HIT0 + STEP * 3.0, HIT0 + STEP * 4.0, t)
			var rot := lerpf(-0.45, 0.0, slam)
			var P := func(v: Vector2) -> Vector2: return hp + v.rotated(rot) * sz
			pd.glow(hp, 64.0 * sz, Color(_c.flame, 0.28 * a), 0.0)
			pd.draw_line(P.call(Vector2(0, -14)), P.call(Vector2(0, -62)), Color(INK, a), 7.5 * sz)
			pd.draw_line(P.call(Vector2(0, -14)), P.call(Vector2(0, -62)), Color("#6a4a2a", a), 4.6 * sz)
			for q in 2: # 감은 가죽 줄
				var y := -32.0 - 14.0 * float(q)
				pd.draw_line(P.call(Vector2(0, y)), P.call(Vector2(0, y - 5.0)), Color("#3a2414", a), 6.0 * sz)
				pd.draw_line(P.call(Vector2(-2.8, y - 1.0)), P.call(Vector2(2.8, y - 4.0)), Color("#9a6a3a", a), 1.2 * sz)
			pd.draw_circle(P.call(Vector2(0, -64)), 3.4 * sz, Color(GOLD, a))
			var head := PackedVector2Array()
			for v: Vector2 in [Vector2(-26, -18), Vector2(26, -18), Vector2(34, 16), Vector2(-34, 16)]:
				head.append(P.call(v))
			pd.outlined(head, Color(_c.dark, a), Color(INK, a), 1.4 * sz)
			var rim := PackedVector2Array(head)
			rim.append(head[0])
			pd.draw_polyline(rim, Color(GOLD, 0.9 * a), 1.2 * sz)
			for sg: float in [-1.0, 1.0]: # 양 끝 면 (밝은 쇠)
				pd.convex(PackedVector2Array([P.call(Vector2(sg * 26, -18)), P.call(Vector2(sg * 20, -18)), P.call(Vector2(sg * 26, 16)), P.call(Vector2(sg * 34, 16))]), Color(_c.deep, a))
			var rune := PackedVector2Array([P.call(Vector2(-4, -12)), P.call(Vector2(4, -2)), P.call(Vector2(-3, 1)), P.call(Vector2(5, 12))])
			pd.draw_polyline(rune, Color(_c.flame, 0.6 * a), 4.0 * sz)
			pd.draw_polyline(rune, Color(_c.core, a), 2.0 * sz)
			var sd := int(t * 30.0)
			for kk in 4: # 머리를 감는 지직임
				var an := EVfx.hash01(sd * 3 + kk) * TAU
				var p0: Vector2 = P.call(Vector2(cos(an) * 36.0, sin(an) * 20.0))
				var p1 := p0 + Vector2.from_angle(an + (EVfx.hash01(sd + kk) - 0.5)) * 12.0 * sz
				pd.draw_line(p0, p1, Color(_c.core, a), 1.2)
		# 번개 줄기: 맞는 시각마다 0.09초
		for i in 5:
			var lt := t - (HIT0 + STEP * float(i)) + 0.03
			if lt < 0.0 or lt > 0.1:
				continue
			var al := 1.0 - lt / 0.1
			_bolt(hp + Vector2((float(i) - 2.0) * 8.0, 18), to + Vector2((float(i) - 2.0) * 5.0, 0), i + 3, 1.8 * s, al)
			pd.glow(to, 30.0 * s, Color(_c.hot, 0.6 * al), 0.0)
		if t > HIT0 + STEP * 4.0:
			var x := clampf((t - (HIT0 + STEP * 4.0)) / 0.5, 0.0, 1.0)
			pd.glow(to, (40.0 + 60.0 * x) * s, Color(_c.hot, 0.5 * (1.0 - x)), 0.0)
			for i in 10:
				var d := Vector2.from_angle(TAU * float(i) / 10.0)
				pd.line2(to + d * 10.0, to + d * (40.0 + 90.0 * x) * s, Color(_c.core, 1.0 - x), Color(_c.flame, 0.0), 3.0, 0.3)
			# 바닥 금빛 균열 (발밑)
			var ca := 1.0 - smoothstep(0.6, 1.0, x)
			var gr := 1.0 - pow(1.0 - minf(x * 4.0, 1.0), 2.0)
			for pts: PackedVector2Array in _cracks:
				var seg := PackedVector2Array()
				for q: Vector2 in pts:
					seg.append(to + Vector2(0, 40) + q * s * gr * 1.6)
				pd.draw_polyline(seg, Color(INK, 0.8 * ca), 3.0)
				pd.draw_polyline(seg, Color(GOLD, ca), 1.4)


## 아스트라 · 유성의 행진 (전체 크리 버프 + 다른 아군 게이지 +100%): 유성들이 아군 머리 위로 왼쪽 → 오른쪽(적 쪽) 아치를 그리며 행진하고,
## 별 셋이 마녀 머리 위에 박혀 금별 표식 0.5초 → 다른 아군은 발밑 게이지 띠가 차오르고 위 띠 차례 칸이 금빛으로 깜빡 (review_D B4: 예전엔 적 쪽에서 아군 쪽으로 들어와 공격처럼 보였다)
class StarParade extends UltBase:
	const HIT0 := 0.52
	var _given := false

	func _ready() -> void:
		life = 1.3
		z_index = 9
		Sfx.play(&"meteor_fall", -6.0)

	func _tick(_d: float) -> void:
		if t >= HIT0 and not _given:
			_given = true
			Sfx.play(&"tn_bless", -3.0)
			Sfx.play(&"star_burst", -8.0)
			var hud: Variant = Fx.get_tree().current_scene.get("hud") if Fx.get_tree().current_scene != null else null
			for a in allies:
				if not _alive(a):
					continue
				var au := TFx.Aura.new()
				au._c = _c
				au.col = _c.gold
				au.kind = "crit"
				TFx.add(au, (a as TActor).center(), true)
				if a != caster and hud is THud: # 차례가 당겨진 마녀의 차례 칸을 금빛으로 깜빡
					(hud as THud)._flash[(a as TActor).unit] = 0.9

	func _arch(f: float, i: int) -> Vector2:
		# 아군 머리 위(왼쪽 아래)에서 솟아 화면 가운데 위를 지나 적 쪽(오른쪽)으로
		return Vector2(lerpf(-40.0, 680.0, f), 176.0 - 92.0 * sin(f * PI) + 6.0 * float(i % 3))

	func _paint() -> void:
		var a := 1.0 - smoothstep(1.0, 1.3, t)
		for i in 9:
			var st := 0.035 * float(i)
			var f := clampf((t - st) / 0.6, 0.0, 1.0)
			if f <= 0.0 or f >= 1.0:
				continue
			var head := _arch(f, i)
			var tail := _arch(maxf(f - 0.12, 0.0), i)
			pd.line2(tail, head, Color(_c.flame, 0.0), Color(_c.hot, 0.9), 0.4, 3.4 * s)
			EVfx.star4(pd, head, 6.0 * s, t * 8.0 + float(i), Color(WHITE, 1.0), Color(_c.gold, 0.5))
		# 아군마다 행진에서 떨어져 머리 위에 박히는 큰 별 → 0.5초 금별 표식
		for j in allies.size():
			var al: TActor = allies[j] if _alive(allies[j]) else null
			if al == null:
				continue
			var hd := al.head() + Vector2(0, -12)
			var f := clampf((t - 0.3 - 0.05 * float(j)) / 0.2, 0.0, 1.0)
			var from := hd + Vector2(-40, -90)
			if f > 0.0 and f < 1.0:
				var p := from.lerp(hd, f * f)
				pd.line2(from.lerp(hd, maxf(f * f - 0.3, 0.0)), p, Color(_c.gold, 0.0), Color(_c.gold, 0.9), 0.4, 3.0)
				EVfx.star4(pd, p, 7.0 * s, t * 6.0, Color(WHITE, 1.0), Color(_c.gold, 0.6))
			elif f >= 1.0:
				var lt := t - (0.5 + 0.05 * float(j))
				var ma := (1.0 - smoothstep(0.4, 0.55, lt)) * a
				if ma > 0.0:
					var pop := 1.0 + 0.6 * (1.0 - clampf(lt / 0.12, 0.0, 1.0))
					pd.glow(hd, 14.0 * pop, Color(GOLD, 0.5 * ma), 0.0)
					EVfx.star4(pd, hd, 6.5 * pop, 0.0, Color(GOLD, ma), Color(WHITE, 0.5 * ma))
			# 차례: 다른 아군 뒤로 흐르는 빛 띠 + 발밑 게이지 띠가 가득 참
			if al != caster and t > HIT0:
				var c := al.center()
				var g := clampf((t - HIT0) / 0.3, 0.0, 1.0) * a
				for q in 4:
					var y := c.y - 12.0 + 8.0 * float(q)
					var x0 := c.x - 18.0 - 50.0 * fposmod(t * 2.2 + float(q) * 0.27, 1.0)
					pd.line2(Vector2(x0 - 26.0, y), Vector2(x0, y), Color(_c.gold, 0.0), Color(_c.gold, 0.7 * g), 0.4, 1.6)
				var bar := Rect2(al.feet() + Vector2(-20, 6), Vector2(40, 3))
				pd.draw_rect(bar.grow(1.0), Color(INK, 0.8 * a))
				pd.draw_rect(Rect2(bar.position, Vector2(bar.size.x * g / maxf(a, 0.01), bar.size.y)), Color(_c.gold, a))


## 토난 · 천둥 선고 (광역 + 감전 3겹 + 이 적을 때리는 크리 확률 +30%): 적 진영 위(y 100~150) 가로 300px 먹구름 띠가 덮이고 안에서 번쩍 →
## 적마다 굵은 벼락(흰 심 + 금 + 보라 빛, 갈래 둘) + 발밑 충격 고리 → 감전 불꽃 셋이 돌고 금빛 표적 고리가 걸림 (review_D B4: 예전 구름은 UI 배지처럼 작았다)
class ThunderVerdict extends UltBase:
	const HIT0 := 0.36
	const STEP := 0.12
	const BOLT := 0.12 ## 벼락이 남는 시간
	const BAND_X := Vector2(330, 640) ## 먹구름 띠 가로 범위
	const BASE_Y := 142.0 ## 먹구름 아래 끝 (평평)
	var _struck := {}
	var _puffs: Array = [] ## [x, 위로 솟은 높이, 반지름]

	func _ready() -> void:
		life = 1.4
		z_index = 9
		for i in 14:
			var f := float(i) / 13.0
			_puffs.append(Vector3(lerpf(BAND_X.x, BAND_X.y, f) + randf_range(-6, 6), randf_range(14.0, 30.0), randf_range(20.0, 30.0)))

	func _fx_at(i: int) -> float:
		return HIT0 - 0.02 + STEP * float(i)

	func _tick(_d: float) -> void:
		for i in foes.size():
			if not _struck.has(i) and t >= _fx_at(i):
				_struck[i] = true
				if _alive(foes[i]):
					var f := foes[i] as TActor
					Sfx.play(&"tn_spear", -6.0)
					Sfx.play(&"sky_crack", -8.0)
					Fx.shake(0.8, 0.25)
					TFx.embers(f.center(), 10, 240.0, Vector2.UP, 180.0, 0.4, Vector2(0, 300))
					var sw := TFx.Shockwave.new()
					sw.col = _c.flame
					TFx.add(sw, f.feet(), true)
					if i == 0:
						Fx.flash(Color(_c.hot, 0.15), 0.08)
						Sfx.play(&"tn_ult_hit", -4.0)

	## 벼락 한 줄기 (흰 심 2 · 금 5 · 보라 빛 14) + 갈래 둘
	func _bolt(a0: Vector2, b0: Vector2, seed_i: int, al: float) -> void:
		var pts := PackedVector2Array([a0])
		for j in range(1, 8):
			var q := float(j) / 8.0
			pts.append(a0.lerp(b0, q) + Vector2((EVfx.hash01(seed_i * 17 + j) - 0.5) * 34.0, 0))
		pts.append(b0)
		pd.draw_polyline(pts, Color(_c.deep, 0.55 * al), 14.0 * s)
		pd.draw_polyline(pts, Color(GOLD, al), 5.0 * s)
		pd.draw_polyline(pts, Color(WHITE, al), 2.0 * s)
		for k in 2: # 갈래
			var at := 2 + k * 3
			var st := pts[at]
			var dir := Vector2(1.0 if k == 0 else -1.0, 1.2).normalized()
			var br := PackedVector2Array([st, st + dir * 14.0 + Vector2(4, 0), st + dir * 30.0])
			pd.draw_polyline(br, Color(GOLD, 0.8 * al), 2.4 * s)
			pd.draw_polyline(br, Color(WHITE, 0.8 * al), 1.0)

	func _paint() -> void:
		var cloud := smoothstep(0.0, 0.25, t) * (1.0 - smoothstep(1.05, 1.4, t))
		var drop := (1.0 - pow(1.0 - smoothstep(0.0, 0.25, t), 2.0)) * 12.0 # 위에서 내려앉음
		var flick := 1.0 if fmod(t, 0.2) < 0.1 and t < 1.0 else 0.0 # 0.1초 깜빡
		var y0 := BASE_Y - 12.0 + drop
		# 먹구름: 위는 뭉게(원 14) · 아래는 평평(띠) — 뒤 그림자 → 앞 몸통 두 겹
		var dark := Color("#262a52")
		pd.draw_rect(Rect2(BAND_X.x - 10.0, y0 - 22.0, BAND_X.y - BAND_X.x + 20.0, 22.0), Color(dark, 0.92 * cloud))
		for pf: Vector3 in _puffs:
			pd.draw_circle(Vector2(pf.x, y0 - pf.y), pf.z * s, Color(dark, 0.92 * cloud))
		for pf: Vector3 in _puffs:
			pd.draw_circle(Vector2(pf.x + 3.0, y0 - pf.y - 4.0), pf.z * 0.72 * s, Color(INK.lerp(dark, 0.6), 0.9 * cloud))
		pd.draw_rect(Rect2(BAND_X.x - 10.0, y0 - 1.0, BAND_X.y - BAND_X.x + 20.0, 1.0), Color(GOLD, 0.8 * cloud)) # 아래 가장자리 금 1px
		if flick > 0.0:
			pd.glow(Vector2(lerpf(BAND_X.x, BAND_X.y, EVfx.hash01(int(t * 10.0))), y0 - 20.0), 60.0, Color(_c.hot, 0.35 * cloud), 0.0)
		for i in foes.size():
			var f: TActor = foes[i] if _alive(foes[i]) else null
			if f == null:
				continue
			var lt := t - _fx_at(i)
			if lt < 0.0:
				continue
			var c := f.center()
			if lt < BOLT: # 벼락
				var al := 1.0 - lt / BOLT * 0.6
				_bolt(Vector2(c.x + 8.0, y0), c, i, al)
				pd.glow(c, 46.0 * s, Color(_c.hot, 0.6 * al), 0.0)
			var stay := smoothstep(0.1, 0.25, lt) * (1.0 - smoothstep(0.8, 1.0, lt))
			for j in 3: # 감전 3겹
				var an := t * 6.0 + TAU * float(j) / 3.0
				var p := c + Vector2(cos(an) * (f.half_w() + 10.0), sin(an) * 8.0)
				pd.draw_polyline(PackedVector2Array([p + Vector2(-2, -4), p + Vector2(1, -1), p + Vector2(-1, 1), p + Vector2(2, 4)]), Color(_c.flame, stay), 1.6)
			if stay > 0.0: # 크리 표적 고리 (아군이 이 적을 때리면 크리가 잘 남)
				var rr := 16.0 + 4.0 * sin(t * 8.0)
				pd.draw_arc(c, rr, 0.0, TAU, 24, Color(GOLD, 0.9 * stay), 1.4)
				for q in 4:
					var d := Vector2.from_angle(TAU * float(q) / 4.0 + t)
					pd.draw_line(c + d * (rr - 4.0), c + d * (rr + 5.0), Color(GOLD, stay), 1.4)


## 에스카 · 세계의 끝 (광역 7배, 방어 무시): 하늘이 바래고 적 진영 위에 검은 별이 열려 → 화면을 가로지르는 균열이 뻗고 → 적마다 흑백 균열이 터지며 세계가 조각남 (흑백만)
class WorldEnd extends UltBase:
	const HIT0 := 0.45
	const STEP := 0.09
	var _ripped := {}
	var _shatter := false
	var _cracks: Array = []
	var _c0 := Vector2(404, 128)

	func _ready() -> void:
		life = 1.4
		z_index = 9
		Sfx.play(&"es_blackstar", -8.0) # 검은 별이 열림 (review_D B2)
		for i in 11:
			var an := -PI * 0.15 + TAU * float(i) / 11.0 + randf_range(-0.15, 0.15)
			var pts := PackedVector2Array([Vector2.ZERO])
			var p := Vector2.ZERO
			for j in 5: # 마디 다섯 (화면 끝까지 가로지르지 않게 — 짧고 꺾인 금)
				p += Vector2.from_angle(an + randf_range(-0.55, 0.55)) * randf_range(26.0, 52.0)
				pts.append(p)
			_cracks.append(pts)

	func _tick(_d: float) -> void:
		for i in foes.size():
			if not _ripped.has(i) and t >= HIT0 - 0.03 + STEP * float(i):
				_ripped[i] = true
				if _alive(foes[i]):
					var at: Vector2 = (foes[i] as TActor).center()
					TFx.rift(at, 96.0 * s, -0.5 + 0.35 * float(i), true) # 균열 하나가 입자를 충분히 뿌린다 (흑성 이하로)
		if t >= HIT0 + 0.25 and not _shatter:
			_shatter = true
			EVfx.big_flash(0.18, true)
			Fx.hitstop(0.14)
			Fx.shake(1.2, 0.45)
			Sfx.play(&"tn_ult_hit", 0.0)
			EVfx.shards(_c0 + Vector2(60, 90), 12, 300.0, Vector2(110, 50), 60.0)

	func _paint() -> void:
		var open := 1.0 - pow(1.0 - smoothstep(0.0, 0.3, t), 2.0)
		var a := 1.0 - smoothstep(1.05, 1.4, t)
		# 어두워진 하늘 + 검은 별 (review_D B5: 예전엔 화면이 밝은 라벤더로 씻겨 숫자 대비가 무너졌다 — 이제 먹빛으로 가라앉음)
		pd.rect_grad(Rect2(TTheme.left(), -TTheme.ofs.y, TTheme.view.x, 300 + TTheme.ofs.y), Color(INK, 0.4 * open * a), Color(INK, 0.06 * a))
		var R := 34.0 * s * open
		pd.glow(_c0, R * 2.6, Color(WHITE, 0.55 * a), 0.0)
		pd.draw_circle(_c0, R + 2.0, Color(WHITE, a))
		pd.draw_circle(_c0, R, Color(INK, a))
		for i in 6:
			var d := Vector2.from_angle(t * 2.0 + TAU * float(i) / 6.0)
			pd.line2(_c0 + d * R, _c0 + d * R * (2.2 + 0.3 * sin(t * 20.0 + float(i))), Color(WHITE, 0.9 * a), Color(WHITE, 0.0), 2.4, 0.3)
		# 균열이 뻗음 (먹 테 + 흰 심)
		var grow := smoothstep(0.12, 0.42, t)
		for pts: PackedVector2Array in _cracks:
			var n := int(ceil(float(pts.size() - 1) * grow))
			if n < 1:
				continue
			for j in n: # 마디마다 가늘어짐 (2 → 0.6) — 고른 직선이 기계적으로 보이지 않게
				var w := lerpf(2.0, 0.6, float(j) / 4.0)
				var p0 := _c0 + pts[j] * s
				var p1 := _c0 + pts[j + 1] * s
				pd.draw_line(p0, p1, Color(INK, 0.9 * a), w + 2.6)
				pd.draw_line(p0, p1, Color(WHITE, a), w)


## 호라 · 시간의 정적 (적 차지 −1 + 게이지 −50% + 아군 버프 지속 +2): 전장 위에 큰 시계판이 떠 바늘이 거꾸로 돌다 멈춤 → 멈춘 순간 회색빛 파문, 떠다니던 재가 허공에 멎음 → 적 머리 위 모래시계 · 아군 금빛
class TimeStill extends UltBase:
	const HIT0 := 0.6
	const C := Vector2(320, 125) ## 빈 하늘 (§22.2: y 95~220) — 예전 (262, 146)·반지름 74는 가운데 마녀의 체력 막대·모자를 덮었다 (review_D B7)
	var _stopped := false
	var _motes: Array = []

	func _ready() -> void:
		life = 1.4
		z_index = 8
		for i in 36:
			_motes.append(Vector2(randf_range(20, 620), randf_range(40, 290)))

	func _tick(_d: float) -> void:
		if t >= 0.52 and not _stopped:
			_stopped = true
			Sfx.play(&"bell", -6.0) # 바늘이 멈춤 — 피해 없는 대마법이라 폭음(tn_ult_hit)은 뺌 (review_D B2)
			Sfx.play(&"tn_turn", -2.0)
			Fx.flash(Color(_c.gold, 0.15), 0.08)
			for a in allies:
				if _alive(a):
					var au := TFx.Aura.new()
					au._c = _c
					au.col = _c.gold
					au.kind = "atk"
					TFx.add(au, (a as TActor).center(), true)

	func _paint() -> void:
		var appear := 1.0 - pow(1.0 - smoothstep(0.0, 0.25, t), 2.0)
		var a := 1.0 - smoothstep(1.05, 1.4, t)
		var R := 56.0 * s * appear
		var stop := smoothstep(0.38, 0.52, t)
		# 시계판
		pd.glow(C, R * 1.2, Color(_c.flame, 0.16 * a), 0.0)
		pd.draw_circle(C, R, Color(_c.dark, 0.42 * a))
		pd.draw_arc(C, R, 0.0, TAU, 56, Color(_c.hot, 0.9 * a), 2.4)
		pd.draw_arc(C, R * 0.9, 0.0, TAU, 56, Color(_c.flame, 0.6 * a), 1.0)
		for i in 12:
			var d := Vector2.from_angle(TAU * float(i) / 12.0 - PI * 0.5)
			var big := i % 3 == 0
			pd.draw_line(C + d * R * (0.72 if big else 0.8), C + d * R * 0.88, Color(_c.hot, a), 3.0 if big else 1.4)
		# 바늘: 거꾸로 빠르게 돌다 12시 근처에서 멈춤
		var spin := -t * 26.0 * (1.0 - stop)
		var ang_m := lerpf(spin, -PI * 0.5 - 0.0, stop) if stop > 0.0 else spin
		var ang_h := lerpf(spin * 0.25, -PI * 0.5 + 0.9, stop) if stop > 0.0 else spin * 0.25
		pd.draw_line(C, C + Vector2.from_angle(ang_m) * R * 0.78, Color(INK, a), 5.0)
		pd.draw_line(C, C + Vector2.from_angle(ang_m) * R * 0.78, Color(_c.core, a), 2.4)
		pd.draw_line(C, C + Vector2.from_angle(ang_h) * R * 0.5, Color(INK, a), 6.0)
		pd.draw_line(C, C + Vector2.from_angle(ang_h) * R * 0.5, Color(_c.gold, a), 3.4)
		pd.draw_circle(C, 4.0, Color(_c.gold, a))
		if t < 0.52:
			return
		# 멈춤: 회색빛 파문 + 허공에 멎은 재
		var x := clampf((t - 0.52) / 0.6, 0.0, 1.0)
		pd.draw_arc(C, 20.0 + 560.0 * x, 0.0, TAU, 64, Color(_c.hot, 0.6 * (1.0 - x)), 3.0)
		for m: Vector2 in _motes:
			pd.draw_rect(Rect2(m, Vector2(1.6, 1.6)), Color(_c.core, 0.7 * a))
		for f in foes: # 적: 모래시계(차지 −1) + 아래 화살(게이지)
			if not _alive(f):
				continue
			var hp := (f as TActor).head() + Vector2(0, -20)
			TFx.hourglass(pd, hp, 6.0, Color(_c.hot, a * smoothstep(0.52, 0.65, t)))
		# 아군: 시계 바늘 끝에서 마녀 머리로 금 실 (버프 지속 연장)
		var tip := C + Vector2.from_angle(-PI * 0.5) * R * 0.78
		var th := smoothstep(0.52, 0.72, t) * a
		for al in allies:
			if not _alive(al):
				continue
			var hd := (al as TActor).head() + Vector2(0, -4)
			var mid := (tip + hd) * 0.5 + Vector2(0, 24)
			var pts := PackedVector2Array()
			for q in 9:
				var f := float(q) / 8.0 * th
				pts.append(tip.lerp(mid, f).lerp(mid.lerp(hd, f), f))
			pd.draw_polyline(pts, Color(GOLD, 0.75 * a), 1.2)
			if th >= 0.99 * a and a > 0.0:
				pd.glow(hd, 8.0, Color(GOLD, 0.6 * a), 0.0)


## 모래시계 (차지·시간 감소 그림)
static func hourglass(pd: PDraw, p: Vector2, r: float, col: Color) -> void:
	if col.a <= 0.0:
		return
	pd.draw_line(p + Vector2(-r, -r * 1.3), p + Vector2(r, -r * 1.3), col, 1.6)
	pd.draw_line(p + Vector2(-r, r * 1.3), p + Vector2(r, r * 1.3), col, 1.6)
	pd.draw_polyline(PackedVector2Array([p + Vector2(-r * 0.8, -r * 1.3), p + Vector2(r * 0.8, r * 1.3)]), col, 1.2)
	pd.draw_polyline(PackedVector2Array([p + Vector2(r * 0.8, -r * 1.3), p + Vector2(-r * 0.8, r * 1.3)]), col, 1.2)
	pd.convex(PackedVector2Array([p + Vector2(-r * 0.5, r * 1.2), p + Vector2(r * 0.5, r * 1.2), p + Vector2(0, r * 0.4)]), col)


## 하르페 · 종막의 검 (단일 6단 확정 크리, 방어 무시): 위아래 먹 띠가 들어와 화면을 막처럼 조이고 → 흑백 참격 여섯이 엇갈려 → 마지막에 화면을 세로로 가르는 흰 선 (흑백만)
class FinalCurtain extends PVfx.Base:
	const HIT0 := 0.18
	const STEP := 0.1
	var s := 1.0
	var target: TActor
	var _to := Vector2.ZERO
	var _n := 0
	var _split := false

	func _ready() -> void:
		life = 1.35
		z_index = 9
		_to = target.center() if is_instance_valid(target) else Vector2(506, 210)

	func _tick(_d: float) -> void:
		while _n < 6 and t >= HIT0 - 0.04 + STEP * float(_n):
			var i := _n
			_n += 1
			var flip := 1 if i % 2 == 0 else -1
			var spec: Dictionary = TFx.SLASH_BIG.duplicate()
			spec.rot = float(spec.rot) + 22.0 * float(i)
			BFx.slash(_to + Vector2(0, 4), spec, flip)
			BFx.cut(_to + Vector2(randf_range(-6, 6), randf_range(-8, 8)), Vector2.from_angle(-0.6 + 0.5 * float(i)), 90.0 * s, i >= 5)
			Sfx.play(&"bl_swish_big" if i % 2 == 0 else &"bl_cut", -2.0)
			if i == 0:
				Sfx.play(&"kb_draw", -4.0) # 첫 타: 검을 뽑음 (review_D B2)
		if t >= HIT0 + STEP * 5.0 and not _split:
			_split = true
			EVfx.big_flash(0.18, true)
			Fx.hitstop(0.16)
			Fx.shake(1.3, 0.45)
			Sfx.play(&"tn_ult_hit", 0.0)
			Sfx.play(&"bl_cut", 0.0)
			Sfx.play(&"kb_burst", -4.0) # 마지막 타
			BFx.ink_sparks(_to, 10, 320.0, Vector2.UP)

	func _paint() -> void:
		# 참격마다 표적 뒤 화면에 남는 큰 먹 붓 자국 (흰 테) — 여섯 개가 쌓여 엇갈린 무늬가 된다
		var fade := 1.0 - smoothstep(1.0, 1.35, t)
		for i in _n:
			var lt := t - (HIT0 - 0.04 + STEP * float(i))
			var g := 1.0 - pow(1.0 - clampf(lt / 0.06, 0.0, 1.0), 2.0)
			var an := -0.6 + 0.5 * float(i) + (PI if i % 2 == 1 else 0.0)
			var d := Vector2.from_angle(an)
			var half := 130.0 * s * g
			var w := (9.0 - float(i)) * s
			pd.line2(_to - d * half, _to + d * half, Color(INK, 0.0), Color(INK, 0.85 * fade), w * 0.4, w)
			pd.line2(_to - d * half * 0.9 + d.orthogonal() * w * 0.4, _to + d * half * 0.9 + d.orthogonal() * w * 0.4, Color(WHITE, 0.0), Color(WHITE, 0.9 * fade), 0.3, 1.2)
		var st := HIT0 + STEP * 5.0
		if t < st:
			return
		var x := clampf((t - st) / 0.5, 0.0, 1.0)
		var a := 1.0 - x
		# 화면을 세로로 가르는 흰 선 + 양옆 먹 번짐
		var w := (6.0 + 20.0 * (1.0 - pow(1.0 - minf(x * 3.0, 1.0), 2.0))) * s * a
		# 위 띠(차례 줄, y 0~31)는 지나가지 않게 y 32부터 (review_D §2)
		pd.draw_rect(Rect2(_to.x - w - 3.0, 32, 3.0, 368), Color(INK, a))
		pd.draw_rect(Rect2(_to.x + w, 32, 3.0, 368), Color(INK, a))
		pd.draw_rect(Rect2(_to.x - w, 32, w * 2.0, 368), Color(WHITE, a))
		pd.draw_rect(Rect2(_to.x - 200, _to.y - 1, 400, 2), Color(WHITE, a * 0.7))


# ═══════════════════════════════════════════════════════════
# 상태 연출 (단계 D — §22.2): 브레이크 · 기절 · 해제 · 근성 · 도발 · 관통 필살기 · 저항/면역 · 크리 · 웨이브
# ═══════════════════════════════════════════════════════════

## 브레이크 (1.0초: 멈춤 0.15 · 막대 깨짐 0.5 · 다음 줄 차오름 0.35). 그림 쪽 = 흰 번쩍 + 유리 조각 + 금 고리, HUD 쪽 = BarShatter
static func break_fx(a: TActor, bar_rect: Rect2, hud: CanvasItem) -> void:
	Fx.hitstop(0.15)
	Fx.shake(1.0, 0.35)
	Sfx.play(&"tn_break", 0.0)
	var b := BreakBurst.new()
	b.actor = a
	add(b, a.center(), true)
	EVfx.shards(a.center(), 14, 260.0, Vector2(a.half_w() * 0.6, 30), 80.0)
	if hud != null and bar_rect.size.x > 0.0:
		var sh := BarShatter.new()
		sh.bar = bar_rect
		var ct := (hud as CanvasItem).get_viewport().get_canvas_transform()
		sh.at = ct * a.center() - TTheme.ofs # HUD 층 설계 좌표 (넓은 화면, review_K K-01)
		sh.left = (ct * (a.center() - Vector2(a.half_w(), 0))).x - TTheme.ofs.x
		hud.add_child(sh)


class BreakBurst extends PVfx.Base:
	var actor: TActor

	func _ready() -> void:
		life = 0.7
		z_index = 10

	func _paint() -> void:
		var x := k()
		var a := 1.0 - x
		var g := 1.0 - pow(1.0 - minf(x * 2.2, 1.0), 2.0)
		pd.glow(Vector2.ZERO, 50.0 + 60.0 * g, Color(GOLD, 0.4 * a), 0.0)
		pd.glow(Vector2.ZERO, 26.0, Color(WHITE, 0.8 * a * a), 0.0)
		pd.draw_arc(Vector2.ZERO, 20.0 + 110.0 * g, 0.0, TAU, 44, Color(GOLD, 0.9 * a), 3.0)
		for i in 10: # 갈라지는 금
			var d := Vector2.from_angle(TAU * float(i) / 10.0 + 0.3)
			var mid := d * (16.0 + 30.0 * g) + d.orthogonal() * (EVfx.hash01(i * 7) - 0.5) * 12.0
			pd.draw_polyline(PackedVector2Array([d * 6.0, mid, d * (30.0 + 60.0 * g)]), Color(WHITE, a), 1.6)


## 보스 카드 막대 깨짐 (HUD 자식): 막대가 6조각으로 갈라져 돌며 떨어지고 → 빈 막대가 왼쪽부터 차오름 + 그림 쪽 "브레이크" 30px 금빛
class BarShatter extends PDraw.Canvas:
	const T := preload("res://proto/turn/t_theme.gd")
	const LIFE := 1.0
	var bar := Rect2()
	var at := Vector2.ZERO
	var left := 0.0 ## 보스 몸 왼쪽 끝 (화면 x)
	var t := 0.0
	var _pieces: Array = [] ## [중심, 속도, 회전 속도, 점들]

	func _ready() -> void:
		z_index = 5
		var n := 6
		var xs: Array = [0.0]
		for i in range(1, n):
			xs.append((float(i) + randf_range(-0.3, 0.3)) / float(n))
		xs.append(1.0)
		for i in n:
			var x0: float = bar.position.x + bar.size.x * float(xs[i])
			var x1: float = bar.position.x + bar.size.x * float(xs[i + 1])
			var y0 := bar.position.y
			var y1 := bar.end.y
			var sk := randf_range(-3.0, 3.0)
			var pts := PackedVector2Array([Vector2(x0 + sk, y0), Vector2(x1 - sk, y0), Vector2(x1 + sk, y1), Vector2(x0 - sk, y1)])
			var c := (pts[0] + pts[2]) * 0.5
			for j in 4:
				pts[j] -= c
			_pieces.append([c, Vector2(randf_range(-60, 60), randf_range(-120, -40)), randf_range(-8, 8), pts])

	func _process(delta: float) -> void:
		t += delta
		if t >= LIFE:
			queue_free()
			return
		queue_redraw()

	func _paint() -> void:
		var fill := clampf((t - 0.65) / 0.35, 0.0, 1.0)
		# 막대 자리를 덮음 (깨진 동안 빈 칸 → 왼쪽부터 다시 참)
		var cover := Rect2(bar.position.x + bar.size.x * fill, bar.position.y, bar.size.x * (1.0 - fill), bar.size.y)
		pd.draw_rect(cover.grow(0.5), T.INK)
		if fill > 0.0 and fill < 1.0:
			pd.draw_rect(Rect2(bar.position.x + bar.size.x * fill - 2.0, bar.position.y - 1, 3, bar.size.y + 2), Color(WHITE, 0.9))
		# 조각
		var x := clampf((t - 0.15) / 0.5, 0.0, 1.0)
		if t < 0.15:
			pd.draw_rect(bar, Color(WHITE, 0.9))
		elif x < 1.0:
			for pc: Array in _pieces:
				var c: Vector2 = (pc[0] as Vector2) + (pc[1] as Vector2) * x * 0.5 + Vector2(0, 260.0 * x * x * 0.5)
				var rot := float(pc[2]) * x * 0.5
				var pts := PackedVector2Array()
				for p: Vector2 in pc[3]:
					pts.append(c + p.rotated(rot))
				pd.convex(pts, Color(T.HP_FOE, 1.0 - x))
				pd.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color(WHITE, 0.8 * (1.0 - x)), 1.0)

	func _draw() -> void:
		super()
		var a := clampf(t / 0.08, 0.0, 1.0) * (1.0 - smoothstep(0.75, 1.0, t))
		var sc := 1.0 + 0.4 * (1.0 - clampf(t / 0.12, 0.0, 1.0))
		# 보스 몸 왼쪽 끝 바깥 빈 들판 (review_D A3: 고정 −92는 넓은 보스의 몸 가운데로 들어가 피해 숫자와 겹쳤다) — 좌우 금선 40px
		var w := T.width("브레이크", 30)
		var cx := clampf(minf(left, at.x - 40.0) - w * 0.5 - 10.0, TTheme.left() + w * 0.5 + 46.0, TTheme.right() - w * 0.5 - 46.0)
		var c := Vector2(cx, at.y + 4.0)
		draw_set_transform(c, 0.0, Vector2(sc, sc))
		T.text(self, Vector2.ZERO, "브레이크", 30, Color(T.GOLD, a), HORIZONTAL_ALIGNMENT_CENTER)
		for sd in [-1.0, 1.0]:
			draw_rect(Rect2(Vector2(sd * (w * 0.5 + 4.0) + (0.0 if sd > 0 else -40.0), -12.0), Vector2(40, 1)), Color(T.GOLD, 0.8 * a))
		draw_set_transform(Vector2.ZERO)


## 기절이 걸리는 순간: 머리 위 노란 별 셋이 튀어 돎 (쉬는 동안의 별은 HUD가 그린다)
static func stun_fx(a: TActor) -> void:
	Sfx.play(&"tn_stun", -4.0)
	var s := StunPop.new()
	add(s, a.head() + Vector2(0, -20), true) # 머리 위 막대보다 위 (review_D B8)


class StunPop extends PVfx.Base:
	func _ready() -> void:
		life = 0.6
		z_index = 10

	func _paint() -> void:
		var x := k()
		var a := 1.0 - smoothstep(0.6, 1.0, x)
		var g := 1.0 - pow(1.0 - minf(x * 3.0, 1.0), 2.0)
		pd.draw_arc(Vector2.ZERO, 6.0 + 16.0 * g, 0.0, TAU, 24, Color("#ffe34a", 0.8 * a), 1.4)
		for i in 3:
			var an := t * 9.0 + TAU * float(i) / 3.0
			var p := Vector2(cos(an) * 12.0 * g, sin(an) * 4.0 * g - 4.0 * g)
			EVfx.star4(pd, p, 4.0, an, Color("#fff6b0", a), Color("#ffe34a", 0.5 * a))


## 해제 (0.8초): 마녀들 위로 보라 바람 세 줄이 쓸고, 아군 패널의 버프 아이콘이 위로 튀어 흩어진다 (어디서 무엇을 잃었는지)
## lost = {TUnit: [아이콘 사전…]} — 해제 직전에 장면이 모아 둔다
static func dispel_fx(witches: Array, lost: Dictionary, hud: THud) -> void:
	Sfx.play(&"tn_dispel", -2.0)
	Sfx.play(&"tn_dispel_glint", -2.0) # 반짝임 층은 22050 (review_D B1)
	var w := DispelWind.new()
	var pts: Array = []
	for a in witches:
		if is_instance_valid(a):
			pts.append((a as TActor).center())
	w.points = pts
	add(w, Vector2.ZERO, true)
	if hud == null:
		return
	for u in lost:
		var icons: Array = lost[u]
		if icons.is_empty():
			continue
		var sc := BuffScatter.new()
		sc.icons = icons
		sc.origin = hud._panel_rect((u as TUnit).slot).position + Vector2(50, 43)
		hud.add_child(sc)


class DispelWind extends PVfx.Base:
	var points: Array = []

	func _ready() -> void:
		life = 0.8
		z_index = 9

	func _paint() -> void:
		var x := k()
		var a := sin(x * PI)
		for j in 3:
			var y := 200.0 + 34.0 * float(j)
			var head := lerpf(-60.0, 380.0, clampf(x * 1.3 - 0.1 * float(j), 0.0, 1.0))
			var l := PackedVector2Array()
			var r := PackedVector2Array()
			for i in 12:
				var f := float(i) / 11.0
				var px := head - 180.0 * f
				var wob := sin(f * 9.0 + t * 14.0 + float(j)) * 6.0
				l.append(Vector2(px, y + wob - 3.0 * (1.0 - f)))
				r.append(Vector2(px, y + wob + 3.0 * (1.0 - f)))
			pd.strip_grad(l, r, Color("#c9a0ff", 0.8 * a), Color("#7a4ad0", 0.0))
		for p: Vector2 in points:
			pd.glow(p, 24.0, Color("#a070ff", 0.3 * a), 0.0)


class BuffScatter extends Node2D:
	const T := preload("res://proto/turn/t_theme.gd")
	const LIFE := 0.7
	var icons: Array = []
	var origin := Vector2.ZERO
	var t := 0.0
	var _v: Array = []

	func _ready() -> void:
		z_index = 5
		for i in icons.size():
			_v.append(Vector2(randf_range(-40, 60), randf_range(-110, -60)))

	func _process(delta: float) -> void:
		t += delta
		if t >= LIFE:
			queue_free()
			return
		modulate.a = 1.0 - smoothstep(0.4, 1.0, t / LIFE)
		queue_redraw()

	func _draw() -> void:
		var x := t / LIFE
		var a := 1.0
		for i in mini(icons.size(), 6):
			var v: Vector2 = _v[i]
			var p := origin + Vector2(13.0 * float(i), 0) + v * t + Vector2(0, 160.0 * t * t)
			draw_set_transform(p + Vector2(5, 5), sin(float(i) * 2.0 + t * 6.0) * x * 1.2, Vector2.ONE)
			T.buff_icon(self, Vector2(-5, -5), icons[i], -1)
			# 흩어지며 보라 금
			draw_line(Vector2(-6, -6), Vector2(6, 6), Color("#c9a0ff", a * smoothstep(0.1, 0.3, x)), 1.0)
		draw_set_transform(Vector2.ZERO)


## 근성 (쓰러질 피해를 체력 1로 버팀): 붉은 심장 고동 두 번 + 금빛 기둥
static func guts_fx(a: TActor) -> void:
	Sfx.play(&"tn_guts", -2.0)
	var g := GutsPulse.new()
	add(g, a.center(), true)
	Fx.flash(Color(1.0, 0.3, 0.3, 0.16), 0.1)


class GutsPulse extends PVfx.Base:
	func _ready() -> void:
		life = 0.8
		z_index = 10

	func _paint() -> void:
		var x := k()
		var a := 1.0 - smoothstep(0.6, 1.0, x)
		for i in 2:
			var ph := clampf((t - 0.17 * float(i)) / 0.4, 0.0, 1.0)
			if ph <= 0.0 or ph >= 1.0:
				continue
			pd.draw_arc(Vector2.ZERO, 8.0 + 34.0 * ph, 0.0, TAU, 28, Color("#ff5a6a", 0.9 * (1.0 - ph)), 2.0)
		var beat := 1.0 + 0.3 * maxf(sin(t * 18.0), 0.0) * (1.0 - x)
		TFx.heart(pd, Vector2(0, -2), 7.0 * beat, Color("#ff5a6a", a))
		TFx.heart(pd, Vector2(0, -3), 3.5 * beat, Color("#ffd0d6", a))
		pd.rect_grad(Rect2(-10, -60, 20, 60), Color(GOLD, 0.0), Color(GOLD, 0.3 * a))


## 하트 (근성 그림)
static func heart(pd: PDraw, p: Vector2, r: float, col: Color) -> void:
	if col.a <= 0.0 or r <= 0.3:
		return
	pd.draw_circle(p + Vector2(-r * 0.5, -r * 0.2), r * 0.55, col)
	pd.draw_circle(p + Vector2(r * 0.5, -r * 0.2), r * 0.55, col)
	pd.convex(PackedVector2Array([p + Vector2(-r * 1.02, 0.0), p + Vector2(r * 1.02, 0.0), p + Vector2(0, r * 1.1)]), col)


## 적 새 의도 표식 (단계 F-2, review_H §2.2): 그 유닛 몸 위에 의도 아이콘을 크게(2.6배) 찍고 종류별로 움직인다 —
## guard 방패가 앞으로 내려앉음 · cover 펼친 팔이 좌우로 · rally 셰브론이 솟음 · summon 문이 열리며 흰빛 · purge 고리가 터지며 점이 흩어짐 ·
## weaken 분홍 화살이 내려꽂힘 · seal 자물쇠가 조여 듦 · scatter 마름모가 흩어져 떨어짐
static func intent_sign(a: TActor, kind: String) -> void:
	if a == null or not is_instance_valid(a):
		return
	var f := IntentSign.new()
	f.kind = kind
	f.col = TTheme.INTENT_COL.get(kind, PALE)
	add(f, a.center() + (Vector2(-14, 0) if kind in ["guard", "cover"] and not a.unit.is_witch() else Vector2.ZERO), true)


class IntentSign extends PVfx.Base:
	var kind := "guard"
	var col := PALE

	func _ready() -> void:
		life = 0.9
		z_index = 9

	func _tick(_d: float) -> void:
		if t < 0.5 and randf() < 0.6:
			var v := Vector2(randf_range(-30, 30), randf_range(-30, 30))
			if kind in ["rally", "summon"]:
				v = Vector2(randf_range(-12, 12), -randf_range(50, 100))
			elif kind in ["weaken", "scatter"]:
				v = Vector2(randf_range(-12, 12), randf_range(40, 90))
			PParticles.get_layer(true).spawn(global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10)), v, Vector2.ZERO, 0.5, randf_range(1.0, 2.0), col, Color(col, 0.0), 0, 1.0)

	func _paint() -> void:
		var x := k()
		var grow := 1.0 - pow(1.0 - minf(x * 2.4, 1.0), 3.0)
		var a := 1.0 - smoothstep(0.6, 1.0, x)
		pd.glow(Vector2.ZERO, 26.0 * grow + 4.0, Color(col, 0.28 * a), 0.0)
		var sc := 2.6
		var off := Vector2.ZERO
		match kind:
			"guard": off = Vector2(0, -10.0 * (1.0 - grow))
			"cover": sc = 2.0 + 1.2 * grow
			"rally": off = Vector2(0, 8.0 - 24.0 * x)
			"weaken": off = Vector2(0, -16.0 + 22.0 * grow)
			"seal": sc = 4.2 - 1.6 * grow
			"purge":
				pd.draw_arc(Vector2.ZERO, 6.0 + 30.0 * grow, 0.0, TAU, 28, Color(col, 0.8 * a), 1.6)
				for i in 8:
					var d := Vector2.from_angle(TAU * float(i) / 8.0 + 0.3)
					pd.draw_circle(d * (8.0 + 34.0 * grow), 2.0 * a + 0.5, Color(col, a))
			"scatter":
				for i in 5:
					var d := Vector2(-20.0 + 10.0 * float(i), -6.0 + 34.0 * x + 6.0 * sin(float(i) * 2.1))
					TTheme.diamond(pd, d, 3.0, Color(col, a))
				return
			"summon":
				var h := 34.0
				var w := 22.0 * grow
				pd.draw_rect(Rect2(Vector2(-w * 0.5, -h * 0.5), Vector2(w, h)), Color(WHITE, 0.5 * a))
				pd.draw_rect(Rect2(Vector2(-13, -h * 0.5 - 1), Vector2(26, h + 2)), Color(col, a), false, 1.6)
		pd.draw_set_transform(off, 0.0, Vector2(sc, sc))
		TTheme.intent_icon(pd, Vector2.ZERO, kind, Color(col, a))
		pd.draw_set_transform(Vector2.ZERO)


## 도발: 시전자에게서 붉은 방패 고리가 퍼지고 적 쪽으로 화살 셋 (적이 이쪽을 노린다)
## 도발: 탱커 앞에 붉은 육각 방패 문장이 0.3초 크게(반지름 30) 떴다 줄고 + 적들의 눈에서 탱커로 붉은 점선 시선 0.5초 (review_D B8)
static func taunt_fx(a: TActor, foes: Array = []) -> void:
	Sfx.play(&"tn_taunt", -4.0)
	var f := TauntRing.new()
	for e in foes:
		if is_instance_valid(e):
			f.eyes.append((e as TActor).head() + Vector2(0, 8) - a.center())
	add(f, a.center(), true)


class TauntRing extends PVfx.Base:
	var eyes: Array = [] ## 적 눈 자리 (탱커 기준)

	func _ready() -> void:
		life = 0.8
		z_index = 9

	func _paint() -> void:
		var x := k()
		var a := 1.0 - smoothstep(0.5, 1.0, x)
		# 육각 방패 문장: 0.3초에 반지름 30까지 튀었다가 18로 줄며 사라짐
		var g := t / 0.3
		var r := 30.0 * (1.0 - pow(1.0 - minf(g, 1.0), 3.0)) if g < 1.0 else lerpf(30.0, 18.0, smoothstep(0.3, 0.8, t))
		var hex := PackedVector2Array()
		for i in 7:
			hex.append(Vector2(16, -4) + Vector2.from_angle(TAU * float(i) / 6.0 + PI / 6.0) * r)
		pd.glow(Vector2(16, -4), r * 1.3, Color("#ff4f6a", 0.3 * a), 0.0)
		pd.draw_polyline(hex, Color(INK, 0.8 * a), 4.0)
		pd.draw_polyline(hex, Color("#ff6a5a", a), 2.0)
		pd.draw_line(Vector2(16, -4 - r * 0.5), Vector2(16, -4 + r * 0.5), Color("#ff6a5a", a), 2.0)
		pd.draw_line(Vector2(16 - r * 0.4, -4), Vector2(16 + r * 0.4, -4), Color("#ff6a5a", a), 2.0)
		# 적 시선 (붉은 점선, 0.5초)
		var la := 1.0 - smoothstep(0.4, 0.55, t)
		for e: Vector2 in eyes:
			var n := int(e.length() / 9.0)
			var grow := minf(t / 0.15, 1.0)
			for q in n:
				var f0 := float(q) / float(n)
				if f0 > grow:
					break
				var p0 := e.lerp(Vector2(16, -4), f0)
				var p1 := e.lerp(Vector2(16, -4), minf(f0 + 0.5 / float(n), 1.0))
				pd.draw_line(p0, p1, Color("#ff4f6a", 0.85 * la), 1.6)
		for i in 2:
			var ph := clampf(x * 1.4 - 0.25 * float(i), 0.0, 1.0)
			pd.draw_arc(Vector2.ZERO, 10.0 + 36.0 * ph, 0.0, TAU, 6, Color("#ff7a5a", 0.9 * (1.0 - ph)), 2.0)
		for i in 3:
			var y := -14.0 + 14.0 * float(i)
			var x0 := 22.0 + 30.0 * fmod(x * 1.6 + float(i) * 0.2, 1.0)
			pd.draw_polyline(PackedVector2Array([Vector2(x0 - 4, y - 5), Vector2(x0 + 2, y), Vector2(x0 - 4, y + 5)]), Color("#ffb08a", a), 2.0)


## 저항(디버프를 막음) · 면역(기절을 막음): 회색 육각 방패가 번쩍이며 튕긴 조각 / 면역은 금빛 사선 원
static func resist_fx(a: TActor, immune: bool) -> void:
	Sfx.play(&"tn_resist", -6.0)
	var r := ResistFlash.new()
	r.immune = immune
	add(r, a.center() + Vector2(0, -6), true)


class ResistFlash extends PVfx.Base:
	var immune := false

	func _ready() -> void:
		life = 0.5
		z_index = 10

	func _paint() -> void:
		var x := k()
		var a := 1.0 - smoothstep(0.4, 1.0, x)
		var g := 1.0 - pow(1.0 - minf(x * 3.0, 1.0), 2.0)
		var col := Color(GOLD) if immune else Color("#cfd2e0")
		var pts := PackedVector2Array()
		for i in 7:
			var an := TAU * float(i) / 6.0 + PI / 6.0
			pts.append(Vector2(cos(an), sin(an)) * (12.0 + 4.0 * g))
		pd.draw_polyline(pts, Color(INK, 0.6 * a), 3.0)
		pd.draw_polyline(pts, Color(col, a), 1.4)
		if immune:
			pd.draw_line(Vector2(-9, 9), Vector2(9, -9), Color(col, a), 1.6)
		for i in 4:
			var d := Vector2.from_angle(-PI * 0.75 + float(i) * 0.5)
			pd.draw_line(d * (14.0 + 10.0 * g), d * (18.0 + 14.0 * g), Color(col, a), 1.2)


## 크리 순간: 대상 둘레 금빛 십자 섬광 0.12초
static func crit_flash(pos: Vector2) -> void:
	var c := CritCross.new()
	add(c, pos, true)


class CritCross extends PVfx.Base:
	func _ready() -> void:
		life = 0.14
		z_index = 11

	func _paint() -> void:
		var x := k()
		var a := (1.0 - x) * (1.0 if bool(GameState.settings.get("flash", true)) else 0.5) # 화면 번쩍임 끔이면 반만 (review_I I-11)
		var r := 18.0 + 22.0 * x
		pd.glow(Vector2.ZERO, r, Color(GOLD, 0.4 * a), 0.0)
		EVfx.star4(pd, Vector2.ZERO, r, 0.0, Color(WHITE, a), Color(0, 0, 0, 0))
		EVfx.star4(pd, Vector2.ZERO, r * 0.55, 0.785, Color(GOLD, a), Color(0, 0, 0, 0))


## 필살기 예고 (적): 붉게 물드는 화면 가장자리 + 그 적 둘레의 붉은 기운 0.35초 — 그 뒤 공격이 나간다. pierce면 관통 창
static func finisher_warn(a: TActor) -> void:
	Sfx.play(&"tn_charge", -4.0)
	var w := FinisherWarn.new()
	w.actor = a
	add(w, Vector2.ZERO, true)


class FinisherWarn extends PVfx.Base:
	var actor: TActor

	func _ready() -> void:
		life = 0.7
		z_index = 7

	func _paint() -> void:
		var a := smoothstep(0.0, 0.2, t) * (1.0 - smoothstep(0.4, 0.7, t))
		pd.ring_grad(Vector2(320, 180), Vector2(240, 120), Vector2(420, 260), Color("#ff2f58", 0.0), Color("#ff2f58", 0.35 * a), 32)
		if is_instance_valid(actor):
			var c := actor.center()
			pd.glow(c, 60.0 + 20.0 * sin(t * 30.0), Color("#ff4f6a", 0.35 * a), 0.0)
			for i in 8:
				var d := Vector2.from_angle(TAU * float(i) / 8.0 + t * 3.0)
				pd.line2(c + d * 70.0 * (1.0 - smoothstep(0.0, 0.35, t)) + d * 10.0, c + d * 20.0, Color("#ff4f6a", 0.0), Color("#ffb0a0", a), 0.4, 2.0)


## 관통 필살기: 적에게서 표적을 꿰뚫고 지나가는 붉은 창 + 무적이면 육각 결계가 깨져 흩어짐
class PierceSpear extends PVfx.Base:
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var barrier := false
	var _broke := false

	func _ready() -> void:
		life = 0.6
		z_index = 10

	func _tick(_d: float) -> void:
		if t >= 0.12 and not _broke:
			_broke = true
			Sfx.play(&"tn_spear", -2.0)
			if barrier:
				Sfx.play(&"tn_break", -6.0)
				EVfx.shards(to, 10, 220.0, Vector2(14, 18), 60.0)

	func _paint() -> void:
		var f := clampf(t / 0.14, 0.0, 1.0)
		var a := 1.0 - smoothstep(0.3, 0.6, t)
		var d := (to - from).normalized()
		var tip := from.lerp(to + d * 80.0, f)
		pd.line2(from, tip, Color("#6b1a12", 0.0), Color("#ff2f58", 0.9 * a), 1.0, 7.0)
		pd.line2(from, tip, Color(WHITE, 0.0), Color(WHITE, a), 0.4, 2.4)
		pd.convex(PackedVector2Array([tip + d * 12.0, tip + d.orthogonal() * 5.0, tip - d.orthogonal() * 5.0]), Color(WHITE, a))
		if barrier and f >= 1.0:
			var x := clampf((t - 0.14) / 0.4, 0.0, 1.0)
			for i in 6: # 결계 조각이 바깥으로
				var an := TAU * float(i) / 6.0
				var p := to + Vector2(cos(an) * 24.0, sin(an) * 30.0) * (1.0 + 0.8 * x)
				pd.draw_line(p, p + Vector2.from_angle(an + 2.0) * 10.0, Color(WHITE, 1.0 - x), 1.4)


## 승리 자세의 반짝임 (손끝)
static func victory_sparkle(a: TActor) -> void:
	var v := VictorySpark.new()
	v.actor = a
	add(v, a.hand(), true)


class VictorySpark extends PVfx.Base:
	var actor: TActor

	func _ready() -> void:
		life = 1.2
		z_index = 10

	func _tick(_d: float) -> void:
		if is_instance_valid(actor):
			global_position = actor.hand()
		if t < 0.8 and randf() < 0.4:
			PParticles.get_layer(true).spawn(global_position + Vector2(randf_range(-6, 6), randf_range(-6, 6)), Vector2(randf_range(-20, 20), -randf_range(30, 70)), Vector2.ZERO, 0.6, randf_range(1.0, 1.8), WHITE, Color(GOLD, 0.0), 0, 0.5)

	func _paint() -> void:
		var x := k()
		var a := 1.0 - smoothstep(0.6, 1.0, x)
		EVfx.star4(pd, Vector2.ZERO, 6.0 + 3.0 * sin(t * 12.0), t * 3.0, Color(WHITE, a), Color(GOLD, 0.5 * a))


## 적 쓰러짐: 0.5초 동안 아래에서 위로 재 입자로 흩어짐 (그림은 TActor가 옅게 한다)
static func ash_dissolve(a: TActor) -> void:
	if a.enemy == null:
		return
	var ad := AshDissolve.new()
	ad.hw = a.enemy.half_w() * a.scale.x
	ad.h = a.enemy.height() * a.scale.y
	add(ad, a.global_position, false)


class AshDissolve extends PVfx.Base:
	var hw := 14.0
	var h := 50.0
	var col := Color("#9a8aa6")

	func _ready() -> void:
		life = 0.55

	func _tick(_d: float) -> void:
		var f := clampf(t / 0.5, 0.0, 1.0)
		var pp := PParticles.get_layer(false)
		for i in 3:
			var p := global_position + Vector2(randf_range(-hw, hw), -h * f + randf_range(-4, 4))
			pp.spawn(p, Vector2(randf_range(-20, 30), -randf_range(30, 80)), Vector2(10, -20), randf_range(0.5, 0.9), randf_range(1.5, 3.0), col, Color(col, 0.0), 0, 1.0)
		if randf() < 0.6:
			PParticles.get_layer(true).spawn(global_position + Vector2(randf_range(-hw, hw), -h * f), Vector2(randf_range(-10, 20), -randf_range(40, 90)), Vector2.ZERO, 0.6, 1.2, Color("#ffb070"), Color("#ff6a3d", 0.0), 0, 0.5)

	func _paint() -> void:
		var f := clampf(t / 0.5, 0.0, 1.0)
		pd.draw_rect(Rect2(-hw, -h * f - 1.0, hw * 2.0, 2.0), Color("#ffd9a0", 0.6 * (1.0 - f)))


## 웨이브 전환: 새 적이 걸어 들어올 때 발밑 먼지
static func walk_dust(pos: Vector2) -> void:
	var pp := PParticles.get_layer(false)
	for i in 6:
		pp.spawn(pos + Vector2(randf_range(-10, 10), 0), Vector2(randf_range(20, 80), -randf_range(10, 40)), Vector2(0, 60), 0.5, randf_range(2.0, 3.5), Color("#8a7a96"), Color("#4a3f55", 0.0), 2, 1.5)
