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
		life = dur
		z_index = 9

	func _tick(_d: float) -> void:
		var f := k()
		var p := from.lerp(to, f) + Vector2(0, -sin(f * PI) * 18.0 * size)
		global_position = p
		_hist.append(p)
		if _hist.size() > 7:
			_hist.remove_at(0)
		if randf() < 0.6:
			PParticles.get_layer(true).spawn(p, Vector2(randf_range(-20, 20), randf_range(-40, 10)), Vector2(0, 40), 0.3, randf_range(1.0, 2.0) * size, _c.hot, Color(_c.deep, 0.0), 0, 2.0)

	func _exit_tree() -> void:
		if not _done:
			_done = true
			var b := FireBurst.new()
			b.size = size
			TFx.add(b, to, true)
			TFx.embers(to, int(8 * size), 180.0 * size, Vector2.UP, 120.0, 0.45, Vector2(0, 220))
			Sfx.play(&"tn_fire", -8.0 + 3.0 * size)

	func _paint() -> void:
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
		pd.rect_grad(Rect2(0, 0, 640, 360), Color(_c.dark, 0.0), Color(_c.dark, 0.35 * a))
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
		pd.rect_grad(Rect2(0, 0, 640, 200), Color(_c.gold, 0.22 * charge * (1.0 - after)), Color(_c.gold, 0.0))
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


## 적 전체 공격: 발밑에서 퍼지는 충격파 (땅 고리 + 먼지)
class Shockwave extends PVfx.Base:
	func _ready() -> void:
		life = 0.7
		z_index = 8

	func _tick(_d: float) -> void:
		if t < 0.3 and randf() < 0.8:
			var an := randf_range(PI * 0.8, PI * 1.2)
			PParticles.get_layer(false).spawn(global_position + Vector2(randf_range(-10, 10), 0), Vector2.from_angle(an) * randf_range(120, 260), Vector2(0, 300), 0.5, randf_range(2.0, 4.0), Color("#8a7a96"), Color("#4a3f55", 0.0), 2, 1.5)

	func _paint() -> void:
		var x := k()
		var a := 1.0 - x
		var r := 10.0 + 420.0 * (1.0 - pow(1.0 - x, 2.0))
		pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
		pd.draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(ASH, 0.8 * a), 3.0)
		pd.draw_arc(Vector2.ZERO, r * 0.8, 0.0, TAU, 48, Color(WHITE, 0.4 * a), 1.0)
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
