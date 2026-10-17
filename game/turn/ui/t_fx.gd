class_name TFx
extends RefCounted
## 턴제 전투 연출 — 전부 코드 그림(PDraw 묶음, 노드 하나 = 그리기 호출 하나), 수명이 끝나면 스스로 사라진다.
## cast()가 마법 id에 맞는 연출을 띄우고 "맞는 순간까지의 선행 시간(초)"을 돌려준다. 장면은 그만큼 기다렸다가 hit 연출(impact·number)을 낸다.
## 공간 마법은 EVfx(찢긴 틈·문장·깃털)를 그대로 쓰고, 화염은 PVfx 불티·잉걸불을 쓴다.
## 대상 정보: {"feet": Vector2, "center": Vector2, "size": float} (전역 좌표 — Effects 노드는 원점에 있다)

const Z_BACK := -9
const Z_FX := 6
const Z_TOP := 8
const Z_TEXT := 20


static func add(n: Node2D, pos: Vector2, additive := false) -> Node2D:
	return PVfx.add(n, pos, additive)


# ═══════════════════════════════════════════════════════════
# 시전 연출 (마법 id → 그림·소리), 선행 시간을 돌려준다
# ═══════════════════════════════════════════════════════════

static func cast(id: String, spec: Dictionary, hand: Vector2, caster: Dictionary, targets: Array, ally: bool) -> float:
	var centers: Array[Vector2] = []
	var feet: Array[Vector2] = []
	for tg in targets:
		centers.append(tg.center)
		feet.append(tg.feet)
	var first_c: Vector2 = centers[0] if not centers.is_empty() else hand
	var first_f: Vector2 = feet[0] if not feet.is_empty() else hand
	var fire := TUi.FIRE_OUT
	var fire_hot := TUi.FIRE_HOT
	match id:
		# ── 에스카
		"crack":
			EVfx.sigil(hand, 1.4)
			add(_rift(first_c + Vector2(-9, 5), first_c + Vector2(9, -7), 5.0, 0.55, randi() % 97, 0.1), Vector2.ZERO)
			Sfx.play(&"es_snap", -4.0)
			return 0.22
		"skytear":
			EVfx.sigil(hand, 1.6)
			var sq := Sequence.new()
			for i in 4:
				var a := first_c + Vector2(-18 + 6 * (i % 2), -14 + float(i) * 6.0).rotated(0.0)
				var b := first_c + Vector2(18 - 6 * (i % 2), 10 - float(i) * 6.0)
				if i % 2 == 1:
					var tmp := a
					a = Vector2(b.x, a.y)
					b = Vector2(tmp.x, b.y)
				sq.steps.append([0.14 * float(i), _rift(a, b, 7.0, 0.6, 31 + i * 7, 0.05)])
			add(sq, Vector2.ZERO)
			Sfx.play(&"es_slash", -3.0)
			return 0.2
		"rift":
			EVfx.sigil(hand, 1.5)
			var r := _rift(first_f + Vector2(14, -2), first_f + Vector2(14, -52), 9.0, 0.9, randi() % 53, 0.3)
			add(r, Vector2.ZERO)
			Sfx.play(&"es_tear", -4.0)
			return 0.35
		"stareyes":
			EVfx.sigil(hand, 1.4)
			add(_aura(first_c + Vector2(0, -8), TUi.PALE, 0.9, 14.0, true), Vector2.ZERO, true)
			Sfx.play(&"star_twinkle", -4.0)
			return 0.35
		"seal":
			EVfx.sigil(hand, 1.6)
			add(_ring(first_c, 46.0, 10.0, TUi.MAGENTA, 0.55, 2.0), Vector2.ZERO, true)
			add(_aura(first_c, TUi.VIOLET, 0.8, 22.0, false), Vector2.ZERO, true)
			Sfx.play(&"es_tear_close", -3.0)
			return 0.45
		"blackstar":
			var mid := Vector2.ZERO
			for c in centers:
				mid += c
			mid /= float(maxi(centers.size(), 1))
			mid.y -= 10.0
			add(_sky(Color("#1a0630"), 2.2, 0.75), Vector2.ZERO)
			var ls := Lens.new()
			ls.r = 34.0 + 6.0 * float(centers.size())
			ls.life = 1.9
			add(ls, mid)
			EVfx.sigil(hand, 2.5)
			Sfx.play(&"es_blackstar", -2.0)
			return 1.45
		# ── 세라
		"firebolt":
			add(_bolt(hand, first_c, fire, fire_hot, 4.0, 0.3), Vector2.ZERO, true)
			Sfx.play(&"shoot", -4.0)
			return 0.3
		"pillar":
			var col := Column.new()
			col.col = fire
			col.hot = fire_hot
			col.life = 0.9
			add(col, first_f, true)
			Sfx.play(&"pillar_warn", -6.0)
			return 0.36
		"storm":
			var sw := Sweep.new()
			sw.x0 = minf(first_f.x, 400.0) - 60.0
			sw.x1 = 640.0
			sw.y = first_f.y - 8.0
			sw.col = fire
			sw.hot = fire_hot
			sw.life = 0.75
			add(sw, Vector2.ZERO, true)
			Sfx.play(&"storm", -3.0)
			return 0.3
		"meteor":
			add(_sky(Color("#6a1008"), 2.4, 0.55), Vector2.ZERO)
			var m := Meteors.new()
			m.targets = feet
			m.col = fire
			m.hot = fire_hot
			m.life = 2.0
			add(m, Vector2.ZERO, true)
			Sfx.play(&"meteor_fall", -2.0)
			return 0.95
		"ward":
			add(_ring(first_c, 8.0, 26.0, fire_hot, 0.6, 2.5), Vector2.ZERO, true)
			PVfx.embers(first_c, 10, false, 70.0, Vector2(10, 10))
			Sfx.play(&"ward", -3.0)
			return 0.3
		"embers":
			add(_aura(first_f + Vector2(0, -10), fire_hot, 0.9, 14.0, false), Vector2.ZERO, true)
			PVfx.embers(first_f, 14, false, 110.0, Vector2(12, 2))
			Sfx.play(&"ignite", -4.0)
			return 0.3
		# ── 아셰
		"flick":
			add(_bolt(hand, first_c, TUi.EMBER, fire_hot, 3.0, 0.3), Vector2.ZERO, true)
			Sfx.play(&"shoot", -6.0, 0.12)
			return 0.3
		"sparks":
			var sq := Sequence.new()
			for i in centers.size():
				var b := Burst.new()
				b.col = TUi.EMBER
				b.hot = fire_hot
				b.r = 16.0
				b.life = 0.45
				b.position = centers[i]
				sq.steps.append([0.06 * float(i), b])
			add(sq, Vector2.ZERO, true)
			Sfx.play(&"ignite", -3.0)
			return 0.3
		"bellows":
			add(_bolt(hand, first_c, TUi.FIRE_MID, fire_hot, 7.0, 0.35), Vector2.ZERO, true)
			var au := _aura(first_c, TUi.FIRE_MID, 0.9, 16.0, false)
			au.delay = 0.3
			add(au, Vector2.ZERO, true)
			Sfx.play(&"whoosh", -4.0)
			return 0.4
		"oil":
			add(_bolt(hand, first_c, Color("#2a1a12"), Color("#6a4a2a"), 4.0, 0.32), Vector2.ZERO)
			var sp := Splash.new()
			sp.col = Color("#2a1a12")
			sp.delay = 0.3
			sp.life = 0.9
			add(sp, first_c)
			Sfx.play(&"squish", -4.0)
			return 0.4
		"warmth":
			add(_aura(first_c, fire_hot, 1.0, 18.0, true), Vector2.ZERO, true)
			PVfx.embers(first_f, 10, false, 60.0, Vector2(10, 4))
			Sfx.play(&"checkpoint", -6.0)
			return 0.4
		"festival":
			var mid := Vector2.ZERO
			for c in centers:
				mid += c
			mid /= float(maxi(centers.size(), 1))
			add(_ring(mid, 10.0, 120.0, fire_hot, 0.8, 3.0), Vector2.ZERO, true)
			for c in centers:
				PVfx.embers(c, 8, false, 80.0, Vector2(8, 8))
			Sfx.play(&"storm_final", -4.0)
			return 0.5
		# ── 적
		"bite":
			Sfx.play(&"growl", -4.0)
			return 0.32
		"howl":
			add(_ring(caster.center, 6.0, 40.0, TUi.ENEMY_C, 0.5, 1.5), Vector2.ZERO, true)
			Sfx.play(&"roar", -8.0, 0.1)
			return 0.3
		"ash":
			add(_bolt(caster.center, first_c, Color("#7a6c66"), Color("#c9bdb6"), 4.0, 0.32), Vector2.ZERO)
			Sfx.play(&"whoosh", -6.0)
			return 0.32
		"chant", "roar":
			var ar := AshRain.new()
			ar.targets = centers
			ar.life = 0.9
			ar.col = Color("#9c8c86") if id == "chant" else Color("#ff8a6a")
			add(ar, Vector2.ZERO)
			add(_ring(caster.center, 10.0, 90.0, TUi.ENEMY_C if id == "roar" else Color("#9c8c86"), 0.6, 2.0), Vector2.ZERO, true)
			Sfx.play(&"roar" if id == "roar" else &"chain", -4.0)
			return 0.45
		"swing":
			var sl := Slash.new()
			sl.col = TUi.BONE
			sl.ang = 0.9
			sl.r = 30.0
			sl.delay = 0.28
			sl.life = 0.55
			add(sl, first_c, true)
			Sfx.play(&"sword_slash", -3.0)
			return 0.4
		"guard":
			add(_aura(caster.center, Color("#9fb0c0"), 0.7, 26.0, false), Vector2.ZERO, true)
			Sfx.play(&"block", -4.0)
			return 0.3
		"doom":
			var sl := Slash.new()
			sl.col = TUi.RED
			sl.ang = 1.4
			sl.r = 46.0
			sl.delay = 0.45
			sl.life = 0.9
			add(sl, first_c, true)
			add(_sky(Color("#4a0410"), 1.2, 0.5), Vector2.ZERO)
			Sfx.play(&"sword_wave", -2.0)
			return 0.6
	return 0.3


## 물약 연출 (마시기/던지기). 던지면 병이 날아가 깨진다
static func potion(id: String, spec: Dictionary, from: Vector2, targets: Array) -> float:
	var col := Color(String(spec.get("color", "#ffffff")))
	if bool(spec.get("throw", false)) and not targets.is_empty():
		var c: Vector2 = targets[0].center
		if targets.size() > 1:
			c = Vector2(520, 230)
		add(_bolt(from, c, col, col.lightened(0.5), 4.0, 0.35), Vector2.ZERO)
		var sp := Splash.new()
		sp.col = col
		sp.delay = 0.33
		sp.life = 0.8
		add(sp, c)
		Sfx.play(&"es_pot_throw", -4.0)
		return 0.4
	for tg in targets:
		add(_aura(tg.center, col, 0.9, 16.0, true), Vector2.ZERO, true)
	Sfx.play(&"es_pot_gulp", -4.0)
	return 0.35


# ═══════════════════════════════════════════════════════════
# 맞는 순간 · 숫자 · 글자
# ═══════════════════════════════════════════════════════════

static func impact(elem: String, pos: Vector2, heavy: bool, ally_target: bool) -> void:
	if ally_target:
		var b := Burst.new()
		b.col = TUi.RED
		b.hot = Color("#ffb0a6")
		b.r = 14.0 if heavy else 9.0
		b.life = 0.35
		add(b, pos, true)
		PVfx.sparks(pos, 6 if heavy else 3, TUi.RED, 120.0, 0.3, Vector2.LEFT, 70.0)
		Sfx.play(&"hit_heavy" if heavy else &"hit", -6.0)
		return
	if elem == TData.ELEM_SPACE:
		EVfx.hit_crack(pos, heavy, 1.0)
		Sfx.play(&"es_tear" if heavy else &"es_snap", -8.0)
		return
	var b := Burst.new()
	b.col = TUi.FIRE_OUT
	b.hot = TUi.FIRE_HOT
	b.r = 18.0 if heavy else 11.0
	b.life = 0.4
	add(b, pos, true)
	PVfx.sparks(pos, 9 if heavy else 5, TUi.FIRE_OUT, 150.0, 0.35, Vector2.UP, 120.0)
	Sfx.play(&"explode" if heavy else &"hit", -7.0 if heavy else -6.0)


## 피해 숫자: 값이 클수록 크게. tags는 아래 작은 글자 (치명·약점·무상성…)
static func number(pos: Vector2, value: int, col: Color, tags: Array[String] = [], big_scale := 1.0) -> void:
	var ft := FloatText.new()
	ft.text = TUi.fmt(value)
	ft.col = col
	var s := 13
	if value >= 3000:
		s = 30
	elif value >= 1200:
		s = 24
	elif value >= 500:
		s = 19
	elif value >= 200:
		s = 16
	ft.size = int(float(s) * big_scale)
	ft.tags = tags
	ft.life = 1.0 if value < 1200 else 1.5
	ft.glow = value >= 1200
	add(ft, pos + Vector2(randf_range(-6, 6), 0))


static func label(pos: Vector2, text: String, col: Color, size := 12, life := 1.0) -> void:
	var ft := FloatText.new()
	ft.text = text
	ft.col = col
	ft.size = size
	ft.life = life
	ft.rise = 14.0
	add(ft, pos)


# ═══════════════════════════════════════════════════════════
# 만들기 도우미
# ═══════════════════════════════════════════════════════════

static func _bolt(from: Vector2, to: Vector2, col: Color, hot: Color, size: float, dur: float) -> Bolt:
	var b := Bolt.new()
	b.from = from
	b.to = to
	b.col = col
	b.hot = hot
	b.size = size
	b.life = dur
	return b


static func _rift(a: Vector2, b: Vector2, w: float, life: float, seed_v: int, hold := 0.2) -> Rift:
	var r := Rift.new()
	r.a = a
	r.b = b
	r.w = w
	r.life = life
	r.seed_v = seed_v
	r.hold = hold
	return r


static func _ring(pos: Vector2, r0: float, r1: float, col: Color, life: float, w: float) -> Ring:
	var r := Ring.new()
	r.position = pos
	r.r0 = r0
	r.r1 = r1
	r.col = col
	r.life = life
	r.w = w
	return r


static func _aura(pos: Vector2, col: Color, life: float, r: float, stars: bool) -> Aura:
	var a := Aura.new()
	a.position = pos
	a.col = col
	a.life = life
	a.r = r
	a.stars = stars
	return a


static func _sky(col: Color, life: float, peak: float) -> SkyTint:
	var s := SkyTint.new()
	s.col = col
	s.life = life
	s.peak = peak
	return s


# ═══════════════════════════════════════════════════════════
# 연출 노드들
# ═══════════════════════════════════════════════════════════

## 여러 연출을 시간차로 띄운다: steps = [[지연, 노드], ...]
class Sequence extends Node2D:
	var steps: Array = []
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		var i := 0
		while i < steps.size():
			if _t >= float(steps[i][0]):
				var n: Node2D = steps[i][1]
				get_parent().add_child(n)
				n.z_index = maxi(n.z_index, 6)
				steps.remove_at(i)
			else:
				i += 1
		if steps.is_empty():
			queue_free()


## 날아가는 덩이 (불꽃탄·잿불·기름·병): 빛 + 꼬리
class Bolt extends PVfx.Base:
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var col := Color.WHITE
	var hot := Color.WHITE
	var size := 4.0
	var _hist := PackedVector2Array()

	func _ready() -> void:
		z_index = 7

	func _paint() -> void:
		var x := k()
		var e := x * x * (3.0 - 2.0 * x)
		var p := from.lerp(to, e) + Vector2(0, -sin(x * PI) * 18.0)
		_hist.append(p)
		if _hist.size() > 7:
			_hist.remove_at(0)
		for i in _hist.size():
			var f := float(i + 1) / float(_hist.size())
			pd.draw_circle(_hist[i], size * 0.7 * f, Color(col, 0.5 * f))
		pd.glow(p, size * 3.0, Color(col, 0.55), 0.0)
		pd.draw_circle(p, size, col)
		pd.draw_circle(p, size * 0.5, hot)
		if x >= 0.98:
			pd.glow(p, size * 5.0, Color(hot, 0.7), 0.0)


## 불기둥: 바닥 균열 예고 → 솟음 → 사그라듦
class Column extends PVfx.Base:
	var col := Color.WHITE
	var hot := Color.WHITE
	var w := 22.0
	var h := 96.0

	func _ready() -> void:
		z_index = 6

	func _tick(_d: float) -> void:
		if t > 0.3 and t < 0.5 and randf() < 0.5:
			PVfx.embers(global_position, 2, false, 160.0, Vector2(w * 0.4, 4))

	func _paint() -> void:
		var x := t
		if x < 0.3:
			var a := x / 0.3
			pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
			pd.glow(Vector2.ZERO, w * (0.5 + a), Color(col, 0.6 * a), 0.0)
			pd.draw_set_transform(Vector2.ZERO)
			for i in 5:
				var an := float(i) * 1.26 + 0.4
				pd.draw_line(Vector2.ZERO, Vector2(cos(an), sin(an) * 0.4) * w * a, Color(hot, a), 1.0)
			return
		var up := clampf((x - 0.3) / 0.08, 0.0, 1.0)
		var fade := 1.0 - clampf((x - 0.55) / (life - 0.55), 0.0, 1.0)
		var hh := h * up * (0.85 + 0.15 * sin(t * 40.0))
		var ww := w * (0.6 + 0.4 * fade)
		pd.glow(Vector2(0, -hh * 0.5), ww * 2.2, Color(col, 0.35 * fade), 0.0)
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		var n := 8
		for i in n + 1:
			var f := float(i) / float(n)
			var y := -hh * f
			var wob := sin(t * 30.0 + f * 9.0) * 3.0 * f
			var half := ww * (1.0 - 0.6 * f * f) * 0.5
			left.append(Vector2(-half + wob, y))
			right.append(Vector2(half + wob, y))
		pd.strip_grad(left, right, Color(col, 0.95 * fade), Color(col, 0.0))
		var l2 := PackedVector2Array()
		var r2 := PackedVector2Array()
		for i in n + 1:
			var f := float(i) / float(n)
			var y := -hh * f * 0.8
			var wob := sin(t * 30.0 + f * 9.0) * 3.0 * f
			var half := ww * (1.0 - 0.6 * f * f) * 0.22
			l2.append(Vector2(-half + wob, y))
			r2.append(Vector2(half + wob, y))
		pd.strip_grad(l2, r2, Color(hot, fade), Color(hot, 0.0))


## 화염 폭풍: 오른쪽으로 휩쓰는 불 띠
class Sweep extends PVfx.Base:
	var x0 := 0.0
	var x1 := 640.0
	var y := 240.0
	var col := Color.WHITE
	var hot := Color.WHITE

	func _ready() -> void:
		z_index = 6

	func _tick(_d: float) -> void:
		if randf() < 0.6:
			var x := k()
			PVfx.embers(Vector2(lerpf(x0, x1, minf(x * 1.6, 1.0)), y - 10.0), 2, false, 120.0, Vector2(20, 10))

	func _paint() -> void:
		var x := k()
		var head := lerpf(x0, x1, minf(x * 1.5, 1.0))
		var tail := lerpf(x0, x1, maxf(x * 1.5 - 0.5, 0.0))
		var fade := 1.0 - clampf((x - 0.6) / 0.4, 0.0, 1.0)
		var top := PackedVector2Array()
		var bot := PackedVector2Array()
		var n := 14
		for i in n + 1:
			var f := float(i) / float(n)
			var px := lerpf(tail, head, f)
			var lick := sin(t * 28.0 + f * 14.0) * 8.0 + sin(f * 30.0 + t * 9.0) * 5.0
			var hgt := (26.0 + lick) * sin(minf(f * 1.4, 1.0) * PI * 0.5 + 0.2)
			top.append(Vector2(px, y - hgt))
			bot.append(Vector2(px, y + 4.0))
		pd.strip_grad(top, bot, Color(col, 0.0), Color(col, 0.9 * fade))
		var top2 := PackedVector2Array()
		var bot2 := PackedVector2Array()
		for i in n + 1:
			var f := float(i) / float(n)
			var px := lerpf(tail, head, f)
			var hgt := (12.0 + sin(t * 25.0 + f * 11.0) * 4.0) * sin(minf(f * 1.4, 1.0) * PI * 0.5 + 0.2)
			top2.append(Vector2(px, y - hgt))
			bot2.append(Vector2(px, y + 2.0))
		pd.strip_grad(top2, bot2, Color(hot, 0.0), Color(hot, 0.9 * fade))
		pd.glow(Vector2(head, y - 8.0), 30.0, Color(hot, 0.5 * fade), 0.0)


## 유성 낙화: 하늘에서 유성이 세 번 떨어진다 (대상마다)
class Meteors extends PVfx.Base:
	var targets: Array[Vector2] = []
	var col := Color.WHITE
	var hot := Color.WHITE
	var _list: Array = [] ## [시작 시각, 목표, 시작점]
	var _hit := {}

	func _ready() -> void:
		z_index = 7
		var i := 0
		for wave in 3:
			for tg in targets:
				var start := 0.35 + float(wave) * 0.3 + randf_range(-0.04, 0.04)
				_list.append([start, tg + Vector2(randf_range(-8, 8), 0), tg + Vector2(randf_range(60, 140), -260)])
				i += 1

	func _paint() -> void:
		for mi in _list.size():
			var m: Array = _list[mi]
			var st: float = m[0]
			var dur := 0.3
			if t < st:
				continue
			var f := clampf((t - st) / dur, 0.0, 1.0)
			var tg: Vector2 = m[1]
			var sp: Vector2 = m[2]
			var p := sp.lerp(tg, f)
			if f < 1.0:
				var d := (tg - sp).normalized()
				pd.line2(p - d * 40.0, p, Color(col, 0.0), Color(col, 0.9), 2.0, 7.0)
				pd.glow(p, 12.0, Color(hot, 0.7), 0.0)
				pd.draw_circle(p, 4.0, hot)
			else:
				if not _hit.has(mi):
					_hit[mi] = t
					PVfx.sparks(tg, 10, col, 220.0, 0.4, Vector2.UP, 80.0)
					Sfx.play(&"meteor_impact", -6.0, 0.1)
				var age := t - float(_hit[mi])
				var a := 1.0 - clampf(age / 0.45, 0.0, 1.0)
				pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
				pd.glow(Vector2(tg.x, tg.y / 0.35), 34.0 * (1.0 + (1.0 - a)), Color(col, 0.6 * a), 0.0)
				pd.draw_set_transform(Vector2.ZERO)
				pd.glow(tg + Vector2(0, -8), 16.0 + 14.0 * (1.0 - a), Color(hot, 0.5 * a), 0.0)


## 찢긴 틈 (EVfx.rift): 흰 금 → 벌어짐 → 꿰매어 닫힘
class Rift extends PVfx.Base:
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	var w := 6.0
	var seed_v := 0
	var hold := 0.2
	var _shape: Array = []

	func _ready() -> void:
		z_index = 7
		_shape = EVfx.rift_line(a, b, w, 10, seed_v, 1.5, 0.08)

	func _paint() -> void:
		var pts: PackedVector2Array = _shape[0]
		var nrm: PackedVector2Array = _shape[1]
		var hw: PackedFloat32Array = _shape[2]
		var crack_t := 0.08
		if t < crack_t:
			EVfx.crack(pd, pts, nrm, 1.0, seed_v)
			return
		var open_t := 0.1
		var open := clampf((t - crack_t) / open_t, 0.0, 1.0)
		open = 1.0 - pow(1.0 - open, 2.0)
		var close_start := crack_t + open_t + hold
		var zip := 0.0
		if t > close_start:
			zip = clampf((t - close_start) / maxf(life - close_start, 0.05), 0.0, 1.0)
		var oa := EVfx.rift_open(hw, open, zip, 0.6, 1.0)
		EVfx.rift(pd, pts, nrm, oa[0], oa[1], seed_v, t, 0.0, 1.0, 1.0)
		if t < crack_t + 0.12:
			EVfx.crack(pd, pts, nrm, 1.0 - (t - crack_t) / 0.12, seed_v)


## 흑성: 검은 별이 커지며 빛을 끌어모으고, 한순간 무너진다
class Lens extends PVfx.Base:
	var r := 40.0
	var _flashed := false

	func _ready() -> void:
		z_index = 7

	func _tick(_d: float) -> void:
		var x := k()
		if x > 0.1 and x < 0.72 and randf() < 0.7:
			var an := randf() * TAU
			var p := global_position + Vector2(cos(an), sin(an)) * (r * 2.2)
			EVfx.pixels(p, 1, 160.0, (global_position - p).normalized(), 8.0, 0.35)
		if x >= 0.74 and not _flashed:
			_flashed = true
			EVfx.big_flash(0.5)
			EVfx.dark_burst(global_position, 60.0)
			EVfx.shards(global_position, 14, 260.0, Vector2(10, 10), 90.0)
			EVfx.feathers(global_position, 8, 120.0, Vector2(20, 10))
			Sfx.play(&"es_doom", -3.0)

	func _paint() -> void:
		var x := k()
		if x < 0.74:
			var grow := clampf(x / 0.6, 0.0, 1.0)
			grow = 1.0 - pow(1.0 - grow, 3.0)
			var R := r * grow * (1.0 + 0.04 * sin(t * 25.0))
			var pulse := 0.5 + 0.5 * sin(t * 9.0)
			pd.glow(Vector2.ZERO, R * 2.4, Color(EVfx.MAGENTA, 0.22 + 0.1 * pulse), 0.0)
			pd.draw_circle(Vector2.ZERO, R + 3.0, Color(EVfx.BODY, 0.8))
			pd.draw_circle(Vector2.ZERO, R + 1.2, EVfx.EDGE)
			pd.draw_circle(Vector2.ZERO, R, EVfx.VOID)
			var n := 10
			for i in n:
				var an := float(i) / float(n) * TAU + t * 0.6
				var rr := R * (0.3 + 0.5 * EVfx.hash01(i * 7 + 3))
				var p := Vector2(cos(an), sin(an)) * rr
				var tw := 0.5 + 0.5 * sin(t * 6.0 + float(i) * 1.7)
				if i % 3 == 0:
					EVfx.star4(pd, p, 2.5 * tw + 1.0, t * 2.0, Color(EVfx.WHITE, 0.9 * grow), Color(EVfx.PALE, 0.3 * grow))
				else:
					pd.draw_rect(Rect2(p - Vector2(0.5, 0.5), Vector2(1, 1)), Color(EVfx.PALE, (0.4 + 0.6 * tw) * grow))
			for i in 7:
				var an := t * 2.5 + float(i) * TAU / 7.0
				pd.draw_arc(Vector2.ZERO, R + 9.0, an, an + 0.5, 6, Color(EVfx.PALE, 0.8 * grow), 1.2)
		else:
			var c := clampf((x - 0.74) / 0.26, 0.0, 1.0)
			var R := r * (1.0 - c)
			pd.glow(Vector2.ZERO, r * 3.0 * (1.0 - c), Color(EVfx.EDGE, 0.8 * (1.0 - c)), 0.0)
			pd.draw_circle(Vector2.ZERO, R, EVfx.VOID)
			for i in 8:
				var an := float(i) * TAU / 8.0 + 0.3
				pd.draw_line(Vector2.ZERO, Vector2(cos(an), sin(an)) * r * 3.0 * c, Color(EVfx.EDGE, 1.0 - c), 2.0 * (1.0 - c) + 0.5)


## 고리: r0 → r1로 퍼지며 옅어짐
class Ring extends PVfx.Base:
	var r0 := 10.0
	var r1 := 40.0
	var col := Color.WHITE
	var w := 2.0

	func _ready() -> void:
		z_index = 7

	func _paint() -> void:
		var x := k()
		var e := 1.0 - pow(1.0 - x, 2.0)
		var R := lerpf(r0, r1, e)
		pd.draw_arc(Vector2.ZERO, R, 0.0, TAU, 32, Color(col, 1.0 - x), w)
		pd.glow(Vector2.ZERO, R, Color(col, 0.25 * (1.0 - x)), 0.3)


## 버프 빛무리: 빛이 번지고 작은 별·불티가 떠오른다
class Aura extends PVfx.Base:
	var col := Color.WHITE
	var r := 16.0
	var stars := false
	var delay := 0.0

	func _ready() -> void:
		z_index = 7

	func _paint() -> void:
		if t < delay:
			return
		var x := clampf((t - delay) / maxf(life - delay, 0.05), 0.0, 1.0)
		var a := sin(x * PI)
		pd.glow(Vector2.ZERO, r * (1.0 + 0.6 * x), Color(col, 0.45 * a), 0.0)
		for i in 8:
			var ph := float(i) * 0.785 + float(i) * 0.37
			var rise := x * (30.0 + 10.0 * float(i % 3))
			var p := Vector2(cos(ph + x * 2.0) * r * 0.9, -rise + r * 0.5)
			if stars:
				EVfx.star4(pd, p, 2.2 * a + 0.5, x * 3.0 + float(i), Color(col.lightened(0.4), a), Color(col, 0.0))
			else:
				pd.draw_rect(Rect2(p - Vector2(0.75, 0.75), Vector2(1.5, 1.5)), Color(col.lightened(0.3), a))


## 터짐: 번쩍 + 고리 + 가시
class Burst extends PVfx.Base:
	var col := Color.WHITE
	var hot := Color.WHITE
	var r := 12.0

	func _ready() -> void:
		z_index = 8

	func _paint() -> void:
		var x := k()
		var f := 1.0 - x
		var grow := 1.0 - pow(1.0 - minf(x * 2.5, 1.0), 2.0)
		pd.glow(Vector2.ZERO, r * (1.0 + grow) * 1.4, Color(col, 0.6 * f), 0.0)
		pd.draw_circle(Vector2.ZERO, r * 0.5 * f + 1.0, Color(hot, f))
		pd.draw_arc(Vector2.ZERO, r * (0.4 + grow), 0.0, TAU, 16, Color(hot, 0.9 * f), 1.5)
		for i in 5:
			var an := float(i) * 1.256 + 0.3
			PVfx.spike(pd, Vector2.ZERO, Vector2(cos(an), sin(an)), r * (0.6 + grow) * 1.3, 3.0 * f, Color(hot, 0.8 * f))


## 튄 액체 (기름·깨진 물약)
class Splash extends PVfx.Base:
	var col := Color.WHITE
	var delay := 0.0
	var _drops: Array = []

	func _ready() -> void:
		z_index = 7
		for i in 9:
			_drops.append([Vector2(randf_range(-70, 70), randf_range(-120, -40)), randf_range(1.0, 2.4)])

	func _paint() -> void:
		if t < delay:
			return
		var x := clampf((t - delay) / maxf(life - delay, 0.05), 0.0, 1.0)
		var a := 1.0 - x
		pd.glow(Vector2.ZERO, 14.0 * (1.0 + x), Color(col, 0.5 * a), 0.0)
		for d in _drops:
			var v: Vector2 = d[0]
			var p := v * x + Vector2(0, 260.0 * x * x)
			pd.draw_circle(p, float(d[1]) * a + 0.3, Color(col, a))
		pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
		pd.draw_circle(Vector2(0, 20.0 / 0.3 * x), 10.0 + 8.0 * x, Color(col, 0.5 * a))


## 참격 (적의 검): 초승달 호가 한순간 긋고 사라진다
class Slash extends PVfx.Base:
	var col := Color.WHITE
	var ang := 0.9
	var r := 30.0
	var delay := 0.2

	func _ready() -> void:
		z_index = 8

	func _paint() -> void:
		if t < delay:
			if col == TUi.RED:
				var pre := t / delay
				pd.glow(Vector2.ZERO, r * pre, Color(col, 0.3 * pre), 0.0)
			return
		var x := clampf((t - delay) / maxf(life - delay, 0.05), 0.0, 1.0)
		var f := 1.0 - x
		var a0 := -ang - 1.2
		var a1 := a0 + ang * 1.6 * minf(x * 3.0, 1.0)
		PVfx.crescent(pd, Vector2.ZERO, r * (1.0 + 0.2 * x), a0, a1, 7.0 * f + 1.0, Color(col, f))
		pd.glow(Vector2.ZERO, r * 0.6, Color(col, 0.35 * f), 0.0)


## 잿비·불비: 머리 위에서 입자가 쏟아진다
class AshRain extends PVfx.Base:
	var targets: Array[Vector2] = []
	var col := Color.WHITE

	func _ready() -> void:
		z_index = 7

	func _tick(_d: float) -> void:
		for tg in targets:
			var pp := PParticles.get_layer(false)
			for i in 2:
				pp.spawn(tg + Vector2(randf_range(-14, 14), -70), Vector2(randf_range(-10, 10), randf_range(140, 220)), Vector2.ZERO, 0.4, randf_range(1.0, 2.0), col, col.darkened(0.4), 0, 0.0)

	func _paint() -> void:
		var x := k()
		for tg in targets:
			pd.glow(tg + Vector2(0, -60), 24.0, Color(col, 0.25 * sin(x * PI)), 0.0)


## 하늘 물들이기 (대마법 때 화면 전체) — 세상 뒤편에 깔린다
class SkyTint extends PVfx.Base:
	var col := Color.BLACK
	var peak := 0.5

	func _ready() -> void:
		z_index = -9

	func _paint() -> void:
		var x := k()
		var a := peak * sin(x * PI)
		pd.rect_grad(Rect2(-160, -120, 960, 600), Color(col, a), Color(col, a * 0.35))


## 떠오르는 글자·숫자 (글자는 PDraw가 못 그려 노드에 직접)
class FloatText extends Node2D:
	var text := ""
	var col := Color.WHITE
	var size := 13
	var life := 1.0
	var rise := 26.0
	var glow := false
	var tags: Array[String] = []
	var _t := 0.0

	func _ready() -> void:
		z_index = 20

	func _process(delta: float) -> void:
		_t += delta
		if _t >= life:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var x := clampf(_t / life, 0.0, 1.0)
		var pop := 1.0 + 0.45 * (1.0 - clampf(_t / 0.12, 0.0, 1.0))
		var a := 1.0 if x < 0.7 else (1.0 - (x - 0.7) / 0.3)
		var y := -rise * (1.0 - pow(1.0 - x, 2.0))
		draw_set_transform(Vector2(0, y), 0.0, Vector2(pop, pop))
		var f := TUi.font()
		var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var p := Vector2(-w * 0.5, 0)
		if glow:
			draw_string_outline(f, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 6, Color(col, 0.25 * a))
		draw_string_outline(f, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 3, Color(0, 0, 0, 0.85 * a))
		draw_string(f, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(col, a))
		var ty := 11.0
		for tg in tags:
			var tw := f.get_string_size(tg, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
			draw_string_outline(f, Vector2(-tw * 0.5, ty), tg, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, Color(0, 0, 0, 0.8 * a))
			draw_string(f, Vector2(-tw * 0.5, ty), tg, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(col.lightened(0.3), a))
			ty += 11.0
