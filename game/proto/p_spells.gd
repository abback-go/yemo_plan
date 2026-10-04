class_name PSpells
extends RefCounted
## 훈련장 마법 7종 + 여우방패 + 불사조 부활. try_cast가 마나·쿨을 확인하고 각 마법을 시작한다.
## 그림 기준(사용자 참고 이미지): 열선 = 흰 빛줄기 둘레를 감는 나선 화염 고리, 대유성 = 뒤쪽 하늘에서 떨어지는 거대 운석 한 방(앞쪽 절반 폭발),
## 파이어볼 = 흰 중심·주황 불 혀가 뒤로 흩날리는 덩어리, 터지면 불 조각 고리, 발톱 난무 = 날카로운 곡선 참격 다발 + 검은 연기.
## 변신 중에는 모두 푸른 여우불 판(크기 ×1.25, 피해 ×1.3).

## 가산 합성 노드 안에서 어두운 것(바위·먼지)을 그리는 일반 합성 자식 층
class NormalLayer extends Node2D:
	var fn: Callable

	func _draw() -> void:
		if fn.is_valid():
			fn.call(self)


static var last_fail := "" ## HUD가 칸을 빨갛게 번쩍이게 (마법 ID)
static var last_fail_t := 0.0


static func _mult(sera: PSera, id: String) -> float:
	return PData.lv_mult(PState.level(id)) * (PData.FOX_DAMAGE if sera.is_fox() else 1.0)


static func _pal(fox: bool) -> Array:
	return [PData.FOX_CORE, PData.FOX_HOT, PData.FOX_MID, PData.FOX_DARK] if fox else [PData.FIRE_CORE, PData.FIRE_HOT, PData.FIRE_MID, PData.FIRE_DARK]


static func try_cast(sera: PSera, id: String) -> bool:
	var s := PData.spell(id)
	var cost := int(s.cost)
	if float(sera.cooldowns.get(id, 0.0)) > 0.0 or (sera.mana + 0.0001 < float(cost) and not PState.infinite_mana):
		last_fail = id
		last_fail_t = 0.35
		Sfx.play(&"block", -10.0)
		return false
	if not PState.infinite_mana:
		sera.mana -= float(cost)
	sera.add_gauge(float(cost) * PData.GAUGE_PER_MANA)
	if not PState.no_cooldown:
		sera.cooldowns[id] = float(s.cd)
	match id:
		"fireball":
			_fireball(sera)
		"foxrain":
			_foxrain(sera)
		"asura":
			_asura(sera)
		"laser":
			sera.start_charge()
			Sfx.play(&"overload_warn", -10.0)
		"meteor":
			_meteor(sera)
		"phoenix":
			_phoenix(sera)
		"bind":
			_bind(sera)
	return true


## 범위 피해: 사각형 r과 겹치는 허수아비. once = 이미 맞은 것 사전(같은 시전에서 한 번만)
static func hit_rect(sera: PSera, r: Rect2, dmg: float, fox: bool, once: Dictionary = {}, opts := {}) -> int:
	var n := 0
	for d: PDummy in PDummy.all(sera.get_tree()):
		if once.has(d) or not r.intersects(d.hit_rect()):
			continue
		if not once.is_empty() or opts.get("track", false):
			once[d] = true
		var o := opts.duplicate()
		o["fox"] = fox
		d.take_hit(int(round(dmg)), r.get_center(), o)
		n += 1
	return n


static func hit_circle(sera: PSera, c: Vector2, rad: float, dmg: float, fox: bool, once: Dictionary = {}, opts := {}) -> int:
	var n := 0
	for d: PDummy in PDummy.all(sera.get_tree()):
		if once.has(d):
			continue
		var r := d.hit_rect()
		var q := Vector2(clampf(c.x, r.position.x, r.end.x), clampf(c.y, r.position.y, r.end.y))
		if q.distance_to(c) > rad:
			continue
		once[d] = true
		var o := opts.duplicate()
		o["fox"] = fox
		d.take_hit(int(round(dmg)), c, o)
		n += 1
	return n


static func _hand(sera: PSera) -> Vector2:
	return sera.global_position + Vector2(sera.facing * 11, -25)


static func _view_rect(sera: PSera) -> Rect2:
	var vp := sera.get_viewport()
	var xf := vp.get_canvas_transform().affine_inverse()
	return Rect2(xf * Vector2.ZERO, vp.get_visible_rect().size)


# ═══════════════════════════════════════════════════════════
# 1. 파이어볼 (초급) — 화염 덩어리 + 뒤로 날리는 불 혀
# ═══════════════════════════════════════════════════════════

static func _fireball(sera: PSera) -> void:
	var fb := Fireball.new()
	fb.sera = sera
	fb.fox = sera.is_fox()
	fb.dir = sera.facing
	fb.dmg = 48.0 * _mult(sera, "fireball")
	fb.awake = PState.awakened("fireball")
	fb.scale_k = 1.5 * (1.25 if fb.fox else 1.0) * (1.35 if fb.awake else 1.0)
	PVfx.add(fb, _hand(sera) + Vector2(sera.facing * 6, 0), true)
	Sfx.play(&"shoot_heavy", -2.0)
	PVfx.sparks(_hand(sera), 6, _pal(fb.fox)[1], 90.0, 0.2, Vector2(sera.facing, 0), 40.0)


class Fireball extends Node2D:
	var sera: PSera
	var fox := false
	var dir := 1
	var dmg := 48.0
	var awake := false
	var scale_k := 1.0
	var vel := Vector2.ZERO
	var t := 0.0
	var _hit := {}
	var small := false ## 각성 갈래 불덩이

	func _ready() -> void:
		z_index = 6
		if vel == Vector2.ZERO:
			vel = Vector2(dir * 330.0, 0)

	func _process(delta: float) -> void:
		t += delta
		position += vel * delta
		var rad := 7.0 * scale_k
		for d: PDummy in PDummy.all(get_tree()):
			if _hit.has(d):
				continue
			var r := d.hit_rect().grow(rad * 0.6)
			if r.has_point(global_position):
				_hit[d] = true
				if awake and not small:
					d.take_hit(int(dmg), global_position, {"fox": fox, "heavy": true})
					PVfx.sparks(global_position, 10, PSpells._pal(fox)[1], 140.0)
					Fx.hitstop(0.03)
				else:
					_explode()
					return
		if randf() < 0.6:
			PVfx.embers(global_position - vel.normalized() * 6.0, 1, fox, 30.0)
		if t > (1.25 if not small else 0.45):
			_explode()
			return
		queue_redraw()

	func _explode() -> void:
		var pal := PSpells._pal(fox)
		var rad := (24.0 if not small else 15.0) * scale_k
		if is_instance_valid(sera):
			PSpells.hit_circle(sera, global_position, rad, dmg * (0.5 if small else 1.0), fox, {}, {"heavy": not small})
		var ex := Explosion.new()
		ex.fox = fox
		ex.size = rad
		PVfx.add(ex, global_position, true)
		Fx.shake(0.08 if not small else 0.04, 0.12)
		Sfx.play(&"explode", -6.0 if not small else -12.0)
		if awake and not small and is_instance_valid(sera):
			for i in 3:
				var f := Fireball.new()
				f.sera = sera
				f.fox = fox
				f.small = true
				f.dmg = dmg
				f.scale_k = scale_k * 0.55
				var ang := (-0.6 + i * 0.6) + (0.0 if vel.x > 0 else PI)
				f.vel = Vector2(cos(ang), sin(ang)) * 220.0
				PVfx.add(f, global_position)
		queue_free()

	func _draw() -> void:
		var pal := PSpells._pal(fox)
		var s := scale_k
		var back := -vel.normalized()
		var side := back.orthogonal()
		# 뒤로 흩날리는 불 혀(꼬리) 여러 겹
		for layer in 3:
			var col: Color = [Color(pal[3], 0.55), Color(pal[2], 0.85), Color(pal[1], 0.95)][layer]
			var lw := (9.0 - layer * 2.6) * s
			var ll := (26.0 - layer * 6.0) * s
			var pts := PackedVector2Array()
			pts.append(side * lw)
			for k in 6:
				var f := float(k + 1) / 6.0
				var wob := sin(t * 30.0 + k * 1.7 + layer) * 2.2 * s * f
				pts.append(back * ll * f + side * (lw * (1.0 - f) + wob) * (1 if k % 2 == 0 else 0.55))
			pts.append(back * ll * 1.05)
			for k in range(5, -1, -1):
				var f := float(k + 1) / 6.0
				var wob := sin(t * 27.0 + k * 1.3 + layer) * 2.2 * s * f
				pts.append(back * ll * f - side * (lw * (1.0 - f) + wob) * (1 if k % 2 == 1 else 0.55))
			pts.append(-side * lw)
			PVfx.safe_poly(self, pts, col)
		# 몸통: 바깥 짙은 불 → 밝은 → 흰 중심
		draw_circle(Vector2.ZERO, 8.5 * s, Color(pal[2], 0.9))
		draw_circle(back * -1.0, 6.6 * s, pal[1])
		draw_circle(back * -1.6, 4.2 * s, pal[0])
		# 바깥 빛
		draw_circle(Vector2.ZERO, 13.0 * s, Color(pal[2], 0.18))


## 불 조각 고리 폭발 (참고: 파이어볼 위 그림)
class Explosion extends PVfx.Base:
	var size := 26.0
	var _shards: Array = []

	func _init() -> void:
		life = 0.42
		z_index = 7
		for i in 14:
			_shards.append([randf() * TAU, randf_range(0.7, 1.15), randf_range(0.6, 1.4)])

	func _draw() -> void:
		var kk := k()
		var pal := PSpells._pal(fox)
		var R := size * (0.5 + kk * 0.8)
		var a := 1.0 - kk
		# 중심 섬광
		draw_circle(Vector2.ZERO, size * 0.8 * (1.0 - kk * 0.5), Color(pal[1], 0.7 * a))
		draw_circle(Vector2.ZERO, size * 0.5 * (1.0 - kk), Color(pal[0], a))
		# 고리 모양으로 흩어지는 불 조각(초승달 조각)
		for sh: Array in _shards:
			var ang := float(sh[0]) + kk * 0.6
			var rr := R * float(sh[1])
			PVfx.crescent(self, Vector2.ZERO, rr, ang, ang + 0.45 * float(sh[2]), 4.0 * a + 1.0, Color(pal[2], a))
		draw_arc(Vector2.ZERO, R * 1.05, 0, TAU, 28, Color(pal[1], 0.6 * a), 1.5)


# ═══════════════════════════════════════════════════════════
# 2. 여우비 (초급) — 손에 여우불을 모아 내려치면 앞쪽에 푸른 불비
# ═══════════════════════════════════════════════════════════

static func _foxrain(sera: PSera) -> void:
	var fr := FoxRainFx.new()
	fr.sera = sera
	fr.fox_form = sera.is_fox()
	fr.dmg = 8.0 * _mult(sera, "foxrain")
	fr.awake = PState.awakened("foxrain")
	fr.width = 150.0 * (1.25 if fr.fox_form else 1.0)
	fr.face = sera.facing
	var cx := sera.global_position.x + sera.facing * 70.0
	PVfx.add(fr, Vector2(cx, sera.global_position.y), true)
	sera.art.claw_k = 0.0
	sera.art.claw_step = 1
	var slash := PVfx.ClawSlash.new()
	slash.dir = sera.facing
	slash.aim = 1
	slash.fox = true
	slash.reach = 26.0
	slash.follow = sera
	slash.offset = Vector2(sera.facing * 6, -21)
	PVfx.add(slash, sera.global_position + slash.offset)
	Sfx.play(&"fox_rain", -2.0)


## 여우비 (참고: 박일표의 여우비) — 하늘에서 비스듬히 꽂히는 날카로운 빛 바늘 + 흘러내리는 불꽃 리본(붉은·주황·푸른 불)
class FoxRainFx extends Node2D:
	var sera: PSera
	var fox_form := false
	var awake := false
	var dmg := 8.0
	var width := 120.0
	var face := 1
	var t := 0.0
	var needles: Array = [] ## [위치, 속도, 길이, 박힌 뒤 시간(-1 = 나는 중)]
	var foxes: Array = [] ## [x, y, vy, hit]
	var _spawn := 0.0
	var _tick := {}
	var _ribbons: Array = [] ## [x, 위상, 색 묶음, 굵기]
	var _solid: NormalLayer
	const DUR := 1.05
	const TOP := -260.0
	## 불꽃 리본 색 [어두운, 가운데, 밝은]
	const RIB_FIRE := [[Color("#7a1018"), Color("#e2381e"), Color("#ffb03a")], [Color("#b8280e"), Color("#ff7a1a"), Color("#ffe07a")],
		[Color("#2a3a9a"), Color("#5b8cff"), Color("#c8e0ff")], [Color("#5a1a10"), Color("#c0401a"), Color("#ff9a3a")]]

	func _ready() -> void:
		z_index = 6
		_solid = NormalLayer.new()
		_solid.fn = _draw_ribbons
		_solid.z_index = -1
		add_child(_solid)
		var n := 4
		for i in n:
			var ci := (2 if (fox_form and i != 1) else i % 4)
			_ribbons.append([lerpf(-width * 0.45, width * 0.45, float(i) / float(n - 1)) + randf_range(-10, 10), randf() * TAU, ci, randf_range(9.0, 14.0)])

	func _process(delta: float) -> void:
		t += delta
		if t < DUR:
			_spawn += delta * (60.0 if fox_form else 46.0)
			while _spawn >= 1.0:
				_spawn -= 1.0
				var a := randf_range(0.22, 0.5)
				var dir := Vector2(face * sin(a), cos(a))
				var x := randf_range(-width / 2, width / 2) + dir.x / dir.y * TOP
				needles.append([Vector2(x, TOP + randf_range(-30, 0)), dir * randf_range(760, 900), randf_range(24, 40), -1.0])
			if awake and randf() < delta * (14.0 if fox_form else 7.0):
				foxes.append([randf_range(-width / 2, width / 2), TOP + 100.0, 300.0, false])
		var rects: Array = []
		for d: PDummy in PDummy.all(get_tree()):
			var r := d.hit_rect()
			r.position -= global_position
			rects.append(r)
		var keep: Array = []
		for nd: Array in needles:
			if float(nd[3]) >= 0.0:
				nd[3] = float(nd[3]) + delta
				if float(nd[3]) < 0.3:
					keep.append(nd)
				continue
			var p: Vector2 = nd[0] + (nd[1] as Vector2) * delta
			nd[0] = p
			var stuck := p.y >= -1.0
			if not stuck and p.y > -120.0:
				for r: Rect2 in rects:
					if r.has_point(p) and randf() < 0.5:
						stuck = true
						break
			if stuck:
				nd[0] = Vector2(p.x, minf(p.y, 0.0) + randf_range(1.0, 3.0) * (1.0 if p.y >= -1.0 else 0.0))
				nd[3] = 0.0
				if randf() < 0.4:
					PVfx.sparks(global_position + p, 3, PData.FOX_HOT if fox_form else Color(1, 0.95, 0.6), 90.0, 0.2)
			keep.append(nd)
		needles = keep
		for f: Array in foxes:
			f[1] += f[2] * delta
			f[2] += 600.0 * delta
		var keepf: Array = []
		for f: Array in foxes:
			if f[1] < 0.0:
				keepf.append(f)
			else:
				PVfx.sparks(global_position + Vector2(f[0], -2), 6, PData.FOX_HOT, 90.0, 0.3)
		foxes = keepf
		# 피해: 바늘 하나하나 대신 범위 안 허수아비를 짧은 간격으로
		if is_instance_valid(sera):
			for d: PDummy in PDummy.all(get_tree()):
				var r := d.hit_rect()
				if r.end.x < global_position.x - width / 2 or r.position.x > global_position.x + width / 2:
					continue
				var nt: float = _tick.get(d, 0.0)
				if t >= nt and t > 0.18 and t < DUR + 0.25:
					_tick[d] = t + 0.085
					d.take_hit(int(dmg), global_position + Vector2(0, -100), {"fox": true})
				for f: Array in foxes:
					if not f[3] and r.has_point(global_position + Vector2(f[0], f[1])):
						f[3] = true
						d.take_hit(int(dmg * 3.0), global_position + Vector2(f[0], f[1]), {"fox": true, "heavy": true})
		if t > DUR + 0.6 and needles.is_empty() and foxes.is_empty():
			queue_free()
		queue_redraw()
		_solid.queue_redraw()

	## 리본: 위에서 쏟아져 내려와 흐르다 위로 걷힘. 가장자리는 뾰족한 불 혀
	func _draw_ribbons(c: CanvasItem) -> void:
		var head := clampf(t / 0.22, 0.0, 1.0) # 아래 끝이 내려온 정도
		var tail := clampf((t - DUR + 0.15) / 0.35, 0.0, 1.0) # 위 끝이 걷힌 정도
		if tail >= 1.0:
			return
		for rb: Array in _ribbons:
			var cols: Array = RIB_FIRE[int(rb[2])]
			var segs := 16
			var y0 := lerpf(TOP, 0.0, tail)
			var y1 := lerpf(TOP, 0.0, head)
			if y1 - y0 < 8.0:
				continue
			for layer in 3:
				var wk: float = [1.0, 0.62, 0.28][layer]
				var left := PackedVector2Array()
				var right := PackedVector2Array()
				for s in segs + 1:
					var f := float(s) / float(segs)
					var y := lerpf(y0, y1, f)
					var x := float(rb[0]) + sin(f * 5.0 + t * 9.0 + float(rb[1])) * 9.0 + face * (y * 0.32)
					var w := float(rb[3]) * wk * (0.35 + 0.65 * sin(f * PI)) * (1.0 + 0.25 * sin(t * 20.0 + s + float(rb[1])))
					var tongue := 1.0 + 0.7 * float((s + layer) % 2)
					left.append(Vector2(x - w * tongue, y))
					right.append(Vector2(x + w * (2.7 - tongue) * 0.75, y))
				right.reverse()
				left.append_array(right)
				PVfx.safe_poly(c, left, Color(cols[layer], 0.92))

	func _draw() -> void:
		var core := Color(0.8, 0.95, 1.0) if fox_form else Color(1.0, 0.93, 0.5)
		var glow := Color(PData.FOX_MID, 0.35) if fox_form else Color(1.0, 0.8, 0.3, 0.35)
		for nd: Array in needles:
			var p: Vector2 = nd[0]
			var v: Vector2 = nd[1]
			var dir := v.normalized()
			var l: float = nd[2]
			var a := 1.0 if float(nd[3]) < 0.0 else 1.0 - float(nd[3]) / 0.3
			var back := p - dir * l
			var n := dir.orthogonal()
			if float(nd[3]) < 0.0:
				draw_line(back - dir * 26.0, back, Color(glow, 0.18), 1.0) # 빠르게 나는 자국
			draw_line(back, p, Color(glow, glow.a * a), 4.0)
			# 날카로운 바늘: 뒤쪽이 넓고 끝이 뾰족한 가는 삼각형
			PVfx.safe_poly(self, PackedVector2Array([back + n * 3.0, p, back - n * 3.0, back - dir * 4.0]), Color(core, a))
			draw_line(back.lerp(p, 0.2), p, Color(1, 1, 1, a), 1.0)
		for f: Array in foxes:
			_draw_fox(Vector2(f[0], f[1]))

	func _draw_fox(p: Vector2) -> void:
		# 뛰어내리는 작은 불여우 (머리 아래)
		var c := Color(PData.FOX_HOT, 0.85)
		PVfx.safe_poly(self, PackedVector2Array([p + Vector2(-3, -10), p + Vector2(3, -10), p + Vector2(4, -2), p + Vector2(0, 2), p + Vector2(-4, -2)]), c)
		PVfx.safe_poly(self, PackedVector2Array([p + Vector2(-3, -1), p + Vector2(-5, 3), p + Vector2(-1, 0)]), c)
		PVfx.safe_poly(self, PackedVector2Array([p + Vector2(3, -1), p + Vector2(5, 3), p + Vector2(1, 0)]), c)
		PVfx.safe_poly(self, PackedVector2Array([p + Vector2(-2, -10), p + Vector2(0, -20), p + Vector2(2, -10)]), Color(PData.FOX_MID, 0.6))
		draw_circle(p + Vector2(0, -4), 1.2, PData.FOX_CORE)


# ═══════════════════════════════════════════════════════════
# 3. 여우불 발톱 난무 (중급, 아수라) — 주변 곡선 참격 다발, 무적, 걸으며
# ═══════════════════════════════════════════════════════════

static func _asura(sera: PSera) -> void:
	var dur := 2.4 + 0.2 * float(PState.level("asura") - 1)
	sera.start_asura(dur)
	var a := Asura.new()
	a.sera = sera
	a.dur = dur
	a.dmg = 9.0 * _mult(sera, "asura")
	a.awake = PState.awakened("asura")
	a.big = sera.is_fox()
	PVfx.add(a, sera.center(), true)
	Sfx.play(&"fox_storm", -4.0)


class Asura extends Node2D:
	var sera: PSera
	var dur := 2.4
	var dmg := 9.0
	var awake := false
	var big := false
	var t := 0.0
	var slashes: Array = [] ## [중심, 반지름, 시작각, 폭, 나이, 회전방향]
	var smoke: Array = [] ## [위치, 나이, 크기]
	var _spawn := 0.0
	var _tick := 0.0
	var _ended := false

	func _ready() -> void:
		z_index = 7

	func _process(delta: float) -> void:
		t += delta
		if is_instance_valid(sera):
			global_position = sera.center()
		var R := 54.0 * (1.25 if big else 1.0)
		if t < dur:
			_spawn += delta * 40.0
			while _spawn >= 1.0:
				_spawn -= 1.0
				var c := Vector2(randf_range(-R * 0.5, R * 0.5), randf_range(-R * 0.4, R * 0.4))
				slashes.append([c, randf_range(R * 0.6, R * 1.15), randf() * TAU, randf_range(1.8, 3.0), 0.0, 1.0 if randf() < 0.5 else -1.0])
				if randf() < 0.3:
					smoke.append([c + Vector2(randf_range(-10, 10), R * 0.4), 0.0, randf_range(4, 8)])
			_tick -= delta
			if _tick <= 0.0 and is_instance_valid(sera):
				_tick = 0.11
				var n := PSpells.hit_circle(sera, global_position, R + 4.0, dmg, true)
				if n > 0:
					Sfx.play_pitch(&"swing", randf_range(1.3, 1.6), -10.0)
		elif not _ended:
			_ended = true
			if awake and is_instance_valid(sera):
				# 아홉 갈래 꼬리 참격
				for i in 9:
					slashes.append([Vector2.ZERO, R * 1.9, float(i) / 9.0 * TAU, 1.0, 0.0, 1.0])
				PSpells.hit_circle(sera, global_position, 96.0, dmg * 6.0, true, {}, {"heavy": true, "launch": 2.0})
				Fx.shake(0.2, 0.25)
				Fx.flash(Color(0.6, 0.85, 1.0, 0.35), 0.15)
				Sfx.play(&"blast", -2.0)
		for s: Array in slashes:
			s[4] += delta
		for m: Array in smoke:
			m[1] += delta
		slashes = slashes.filter(func(s: Array) -> bool: return s[4] < 0.18)
		smoke = smoke.filter(func(m: Array) -> bool: return m[1] < 0.5)
		if t > dur + 0.3:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		for m: Array in smoke:
			var a: float = 1.0 - m[1] / 0.5
			draw_circle(m[0] + Vector2(0, -m[1] * 12.0), m[2] * (0.6 + m[1]), Color(0.1, 0.08, 0.16, 0.35 * a))
		for s: Array in slashes:
			var kk: float = s[4] / 0.18
			var a := 1.0 - kk
			var a0: float = s[2]
			var sweep: float = s[3] * s[5]
			var a1 := a0 + sweep * minf(kk * 2.2, 1.0)
			PVfx.crescent(self, s[0], s[1] + 3.0, a0, a1, 8.0, Color(PData.FOX_MID, 0.45 * a), 16)
			PVfx.crescent(self, s[0], s[1], a0, a1, 5.0, Color(PData.FOX_CORE, 0.95 * a), 16)
		if t < dur:
			draw_arc(Vector2.ZERO, 40.0 * (1.25 if big else 1.0), 0, TAU, 32, Color(PData.FOX_HOT, 0.12), 6.0)


# ═══════════════════════════════════════════════════════════
# 4. 압축 열선 (중급) — 누를수록 굵어지는 레이저, 나선 화염 고리
# ═══════════════════════════════════════════════════════════

static func fire_laser(sera: PSera, charge: float) -> void:
	var k := clampf((charge - 0.5) / 1.5, 0.0, 1.0)
	var l := Laser.new()
	l.sera = sera
	l.fox = sera.is_fox()
	l.k = k
	l.dir = sera.facing
	l.awake = PState.awakened("laser") and k >= 0.99
	l.dmg = lerpf(7.0, 15.0, k) * _mult(sera, "laser")
	l.dur = lerpf(0.45, 1.0, k)
	l.thick = lerpf(9.0, 28.0, k) * (1.25 if l.fox else 1.0)
	PVfx.add(l, _hand(sera), true)
	sera.velocity.x = -sera.facing * 60.0 * (0.5 + k)
	Fx.flash(Color(1, 0.95, 0.8, 0.25 + 0.25 * k), 0.12)
	Sfx.play(&"blast", -2.0 + 3.0 * k)


class Laser extends Node2D:
	var sera: PSera
	var fox := false
	var awake := false
	var k := 0.0
	var dir := 1
	var dmg := 10.0
	var dur := 0.6
	var thick := 14.0
	var t := 0.0
	var _tick := 0.0
	var length := 640.0
	var _trail: Array = [] ## 각성: 바닥 불길 [x, 나이]

	func _ready() -> void:
		z_index = 7

	func _process(delta: float) -> void:
		t += delta
		if is_instance_valid(sera) and t < dur:
			global_position = PSpells._hand(sera)
			dir = sera.facing
		Fx.shake(0.04 + 0.08 * k, 0.05)
		_tick -= delta
		if _tick <= 0.0 and t < dur and is_instance_valid(sera):
			_tick = 0.06
			var r := Rect2(global_position + Vector2(0 if dir > 0 else -length, -thick / 2), Vector2(length, thick))
			PSpells.hit_rect(sera, r, dmg, fox, {}, {"heavy": k > 0.8})
			if awake:
				_trail.append([global_position.x, 0.0, global_position.y + 18.0])
		for tr: Array in _trail:
			tr[1] += delta
		if awake and is_instance_valid(sera) and fmod(t, 0.2) < delta:
			for tr: Array in _trail:
				if tr[1] < 1.5:
					var gx: float = tr[0]
					PSpells.hit_rect(sera, Rect2(Vector2(gx + (0.0 if dir > 0 else -length), tr[2] - 14), Vector2(length, 14)), dmg * 0.25, fox)
					break
		if t > dur + 0.25 and (not awake or t > dur + 1.6):
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var pal := PSpells._pal(fox)
		var on := t < dur
		var a := 1.0 if on else clampf(1.0 - (t - dur) / 0.25, 0.0, 1.0)
		var grow := clampf(t / 0.08, 0.0, 1.0)
		var th := thick * (0.6 + 0.4 * grow) * (1.0 + 0.08 * sin(t * 60.0)) * a
		var L := length * grow
		draw_set_transform(Vector2.ZERO, 0.0 if dir > 0 else PI, Vector2.ONE)
		# 바깥 빛 → 주황 → 노랑 → 흰 중심
		draw_rect(Rect2(0, -th * 0.9, L, th * 1.8), Color(pal[2], 0.25 * a))
		draw_rect(Rect2(0, -th * 0.55, L, th * 1.1), Color(pal[2], 0.8 * a))
		draw_rect(Rect2(0, -th * 0.35, L, th * 0.7), Color(pal[1], 0.95 * a))
		draw_rect(Rect2(0, -th * 0.16, L, th * 0.32), Color(pal[0], a))
		# 나선 화염 고리 (빛줄기를 감아 도는 두 가닥)
		var pitch := 26.0
		var n := int(L / pitch * 2.0)
		for i in n:
			var x := fmod(float(i) * pitch * 0.5 + t * 420.0, L)
			var ph := x * 0.24 - t * 18.0
			var ry := th * 0.95
			var rx := th * 0.35
			draw_set_transform(Vector2(x, 0) if dir > 0 else Vector2(-x, 0), 0.0 if dir > 0 else PI, Vector2.ONE)
			draw_arc(Vector2.ZERO, ry, ph, ph + 1.6, 10, Color(pal[1], 0.85 * a), 1.6)
			draw_set_transform(Vector2.ZERO, 0.0 if dir > 0 else PI, Vector2.ONE)
		for i in 2:
			var pts := PackedVector2Array()
			for s in 40:
				var x := L * float(s) / 39.0
				pts.append(Vector2(x, sin(x * 0.12 - t * 30.0 + i * PI) * th * 0.85))
			draw_polyline(pts, Color(pal[1], 0.7 * a), 1.5)
		# 손끝 충격파
		var mz := 6.0 + th * 0.9
		draw_circle(Vector2.ZERO, mz, Color(pal[1], 0.8 * a))
		draw_circle(Vector2.ZERO, mz * 0.55, Color(pal[0], a))
		for i in 6:
			var ang := float(i) / 6.0 * TAU + t * 10.0
			PVfx.spike(self, Vector2.ZERO, Vector2(cos(ang), sin(ang)), mz * 1.8, 3.0, Color(pal[0], 0.7 * a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# 각성: 바닥에 남는 불길
		for tr: Array in _trail:
			if tr[1] < 1.5:
				var fa: float = 1.0 - tr[1] / 1.5
				var y: float = tr[2] - global_position.y
				for i in 18:
					var x := float(i) * 30.0 * float(dir)
					var hh := 6.0 + 4.0 * sin(t * 20.0 + i)
					PVfx.safe_poly(self, PackedVector2Array([Vector2(x - 6, y), Vector2(x, y - hh), Vector2(x + 6, y)]), Color(pal[2], 0.7 * fa))
				break


# ═══════════════════════════════════════════════════════════
# 5. 대유성 (중급) — 세라 뒤쪽 하늘에서 거대한 운석 한 방이 보는 방향 앞 땅에 떨어져 화면 앞쪽 절반을 덮는 폭발
# ═══════════════════════════════════════════════════════════

static func _meteor(sera: PSera) -> void:
	sera.lock_cast(0.45)
	var m := Meteor.new()
	m.sera = sera
	m.fox = sera.is_fox()
	m.dmg = 130.0 * _mult(sera, "meteor")
	m.awake = PState.awakened("meteor")
	m.view = _view_rect(sera)
	m.face = sera.facing
	m.origin_x = sera.global_position.x
	m.ground_y = sera.global_position.y
	PVfx.add(m, Vector2.ZERO, true)
	Sfx.play(&"sky_crack", -2.0)


class Meteor extends Node2D:
	var sera: PSera
	var fox := false
	var awake := false
	var dmg := 130.0
	var view := Rect2()
	var face := 1
	var origin_x := 0.0
	var ground_y := 0.0
	var t := 0.0
	var debris: Array = [] ## [위치, 속도, 나이]
	var _fire_sea := 0.0
	var _hit := false
	var _start := Vector2.ZERO
	var _land := Vector2.ZERO
	var _solid: NormalLayer
	const SIGIL := 0.3 ## 하늘 마법진이 열리는 시간
	const IMPACT := 1.05 ## 땅에 닿는 시각
	const R := 46.0 ## 운석 반지름 (세라 키보다 큼)
	const BLAST := 175.0 ## 폭발 반지름 — 화면(640) 앞쪽 절반을 덮음

	func _ready() -> void:
		z_index = 9
		_solid = NormalLayer.new()
		_solid.fn = _draw_solid
		_solid.z_index = -1
		add_child(_solid)
		_land = Vector2(origin_x + face * view.size.x * 0.27, ground_y)
		_start = Vector2(origin_x - face * view.size.x * 0.42, view.position.y - 70.0)

	func _pos() -> Vector2:
		var k := clampf((t - SIGIL) / (IMPACT - SIGIL), 0.0, 1.0)
		return _start.lerp(_land + Vector2(0, -R * 0.5), k * k)

	func _process(delta: float) -> void:
		t += delta
		if t >= SIGIL and t < IMPACT and randf() < 0.9:
			PVfx.embers(_pos(), 3, fox, 120.0, Vector2(R * 0.5, R * 0.5))
		if t >= IMPACT and not _hit:
			_hit = true
			_impact()
		for d: Array in debris:
			d[0] += d[1] * delta
			d[1].y += 520.0 * delta
			d[2] += delta
		debris = debris.filter(func(d: Array) -> bool: return d[2] < 1.2)
		if _fire_sea > 0.0:
			_fire_sea -= delta
			if is_instance_valid(sera) and fmod(t, 0.25) < delta:
				PSpells.hit_rect(sera, _front_rect(20.0), dmg * 0.08, fox)
		if t > IMPACT + 1.5 and _fire_sea <= 0.0:
			queue_free()
		queue_redraw()
		_solid.queue_redraw()

	## 세라 앞쪽 절반(보는 방향) 땅 위 영역
	func _front_rect(h: float) -> Rect2:
		var x0 := origin_x if face > 0 else view.position.x
		var x1 := view.end.x if face > 0 else origin_x
		return Rect2(Vector2(x0, ground_y - h), Vector2(x1 - x0, h))

	func _impact() -> void:
		for i in 40:
			debris.append([_land + Vector2(randf_range(-30, 30), -6), Vector2(randf_range(-260, 260), randf_range(-480, -160)), 0.0])
		if is_instance_valid(sera):
			PSpells.hit_rect(sera, _front_rect(BLAST * 1.1), dmg, fox, {}, {"heavy": true, "launch": 3.0})
		Fx.flash(Color(1, 0.85, 0.6, 0.4), 0.3)
		Fx.hitstop(0.14)
		Fx.shake(0.65, 0.55)
		Fx.zoom_punch(0.07)
		Sfx.play(&"meteor_impact")
		Sfx.play(&"explode", -4.0)
		PVfx.embers(_land, 40, fox, 260.0, Vector2(BLAST * 0.6, 6))
		if awake:
			_fire_sea = 3.0

	## 일반 합성: 운석의 검은 바위 몸통·흙먼지·파편
	func _draw_solid(c: CanvasItem) -> void:
		if t >= SIGIL and t < IMPACT:
			var p := _pos()
			var rock := Color("#2a120c") if not fox else Color("#0c1630")
			var rock2 := Color("#4a2216") if not fox else Color("#1a2c58")
			var pts := PackedVector2Array()
			for i in 14:
				var a := float(i) / 14.0 * TAU + t * 2.0
				pts.append(p + Vector2(cos(a), sin(a)) * R * (0.86 + 0.14 * sin(i * 2.7)))
			PVfx.safe_poly(c, pts, rock)
			c.draw_circle(p + Vector2(-face * 6, 8), R * 0.55, rock2)
		if t >= IMPACT:
			var kk := clampf((t - IMPACT) / 1.4, 0.0, 1.0)
			for i in 10:
				var x := (float(i) - 4.5) * BLAST * 0.22
				c.draw_circle(_land + Vector2(x * (1.0 + kk * 0.5), -10), BLAST * 0.14 * (1.0 + kk), Color(0.22, 0.14, 0.12, 0.6 * (1.0 - kk)))
		for d: Array in debris:
			c.draw_rect(Rect2(d[0], Vector2(4, 4)), Color(0.25, 0.15, 0.12, 1.0 - float(d[2]) / 1.2))

	func _draw() -> void:
		var pal := PSpells._pal(fox)
		# ① 세라 뒤쪽 하늘의 마법진 (운석이 빠져나오는 문)
		var ca := clampf(t / 0.2, 0.0, 1.0) * clampf((IMPACT + 0.1 - t) / 0.3, 0.0, 1.0)
		if ca > 0.0:
			draw_set_transform(_start + Vector2(0, 30), 0.0, Vector2(1.0, 0.45))
			for i in 3:
				var r := 54.0 + i * 18.0
				var sp := t * (1.2 - i * 0.3) * (1 if i % 2 == 0 else -1)
				draw_arc(Vector2.ZERO, r, sp, sp + TAU, 40, Color(pal[1], 0.8 * ca), 2.0)
			for i in 10:
				var a := float(i) / 10.0 * TAU - t
				PVfx.spike(self, Vector2(cos(a), sin(a)) * 74.0, Vector2(cos(a), sin(a)), 12.0, 4.0, Color(pal[0], 0.8 * ca))
			draw_circle(Vector2.ZERO, 50.0, Color(pal[2], 0.2 * ca))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# ② 떨어지는 거대 운석 + 불타는 긴 꼬리
		if t >= SIGIL and t < IMPACT:
			var p := _pos()
			var dir := (_land - _start).normalized()
			var side := dir.orthogonal()
			var fl := sin(t * 30.0) * 6.0
			PVfx.safe_poly(self, PackedVector2Array([p + side * R * 1.25, p - dir * R * 4.2 + side * (R * 0.5 + fl), p - dir * R * 5.2, p - dir * R * 4.2 - side * (R * 0.5 - fl), p - side * R * 1.25]), Color(pal[3], 0.55))
			PVfx.safe_poly(self, PackedVector2Array([p + side * R * 1.0, p - dir * R * 3.2 + side * R * 0.3, p - dir * R * 3.8, p - dir * R * 3.2 - side * R * 0.3, p - side * R * 1.0]), Color(pal[2], 0.75))
			PVfx.safe_poly(self, PackedVector2Array([p + side * R * 0.7, p - dir * R * 2.2, p - side * R * 0.7]), Color(pal[1], 0.9))
			draw_circle(p, R * 1.45, Color(pal[2], 0.22))
			draw_circle(p, R * 1.12, Color(pal[1], 0.35))
			# 바위 테두리의 달아오른 금 (일반 합성 바위 위로 비침)
			for i in 6:
				var a := float(i) / 6.0 * TAU + t * 2.0
				var q := p + Vector2(cos(a), sin(a)) * R * 0.5
				draw_line(q, q + Vector2(cos(a + 0.6), sin(a + 0.6)) * R * 0.45, Color(pal[1], 0.9), 2.0)
			draw_arc(p, R * 0.98, 0, TAU, 32, Color(pal[0], 0.8), 2.0)
			# 앞쪽 공기가 달아오르는 충격파 고깔
			draw_arc(p + dir * R * 0.4, R * 1.2, dir.angle() - 1.1, dir.angle() + 1.1, 16, Color(pal[0], 0.6), 3.0)
		# ③ 폭발: 앞쪽 절반을 덮는 불의 돔 + 불기둥 + 충격파 고리
		if t >= IMPACT:
			var age := t - IMPACT
			var kk := clampf(age / 1.3, 0.0, 1.0)
			var a := 1.0 - kk
			var grow := 1.0 - pow(1.0 - minf(age / 0.25, 1.0), 3.0)
			var rad := BLAST * grow
			draw_circle(_land + Vector2(0, -rad * 0.25), rad * 1.05, Color(pal[3], 0.45 * a))
			draw_circle(_land + Vector2(0, -rad * 0.25), rad * 0.8, Color(pal[2], 0.55 * a))
			draw_circle(_land + Vector2(0, -rad * 0.3), rad * 0.5 * (1.0 - kk * 0.5), Color(pal[1], 0.85 * a))
			draw_circle(_land + Vector2(0, -rad * 0.3), rad * 0.25 * (1.0 - kk), Color(pal[0], a))
			var h := BLAST * 1.6 * minf(age * 4.0, 1.0)
			PVfx.safe_poly(self, PackedVector2Array([_land + Vector2(-50, 0), _land + Vector2(-18, -h), _land + Vector2(0, -h * 1.12), _land + Vector2(18, -h), _land + Vector2(50, 0)]), Color(pal[1], 0.75 * a))
			PVfx.safe_poly(self, PackedVector2Array([_land + Vector2(-20, 0), _land + Vector2(0, -h), _land + Vector2(20, 0)]), Color(pal[0], 0.9 * a))
			for i in 3:
				var rr := BLAST * (0.4 + kk * (1.1 + i * 0.25))
				draw_set_transform(_land + Vector2(0, -4), 0.0, Vector2(1.0, 0.22))
				draw_arc(Vector2.ZERO, rr, 0, TAU, 40, Color(pal[1], 0.8 * a * (1.0 - i * 0.25)), 3.0)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			for i in 14:
				var ang := -PI + float(i) / 13.0 * PI
				var d := Vector2(cos(ang), sin(ang))
				PVfx.spike(self, _land + d * rad * 0.6, d, rad * 0.5 * a, 6.0 * a + 1.0, Color(pal[1], 0.8 * a))
		for d: Array in debris:
			draw_rect(Rect2(d[0], Vector2(2, 2)), Color(pal[1], 1.0 - float(d[2]) / 1.2))
		# 각성: 앞쪽 땅에 남는 불바다
		if _fire_sea > 0.0:
			var fa := minf(_fire_sea, 1.0)
			var fr := _front_rect(0.0)
			for i in int(fr.size.x / 14.0):
				var x := fr.position.x + i * 14.0
				var hh := 10.0 + 7.0 * sin(t * 14.0 + i * 1.7)
				PVfx.safe_poly(self, PackedVector2Array([Vector2(x, ground_y), Vector2(x + 7, ground_y - hh), Vector2(x + 14, ground_y)]), Color(pal[2], 0.75 * fa))
				PVfx.safe_poly(self, PackedVector2Array([Vector2(x + 4, ground_y), Vector2(x + 7, ground_y - hh * 0.5), Vector2(x + 10, ground_y)]), Color(pal[1], 0.9 * fa))


# ═══════════════════════════════════════════════════════════
# 6. 불사조 (대마법) — 화면을 찢으며 날아옴 + 부활 1회
# ═══════════════════════════════════════════════════════════

static func _phoenix(sera: PSera) -> void:
	sera.lock_cast(1.0, true)
	var p := Phoenix.new()
	p.sera = sera
	p.fox = sera.is_fox()
	p.awake = PState.awakened("phoenix")
	p.dmg = 150.0 * _mult(sera, "phoenix")
	p.view = _view_rect(sera)
	p.dir = sera.facing
	p.y = sera.global_position.y - 44.0
	p.ground_y = sera.global_position.y
	PVfx.add(p, Vector2.ZERO, true)
	sera.revive = 1
	Sfx.play(&"sky_crack", -2.0)
	Fx.flash(Color(1, 0.55, 0.2, 0.35), 0.3)
	Fx.shake(0.15, 0.3)


## 불사조 (참고 그림): 화면이 붉게 물들고 → 룬·톱니 마법진이 화면 가득 겹쳐 돌고 → 바닥에서 불붙은 결정 가시가 솟고 →
## 가운데에 흰 금빛 불사조가 날개를 펴고 나타났다가 → 뒤로 크게 돌아 화면 전체를 찢으며 가로지른다(피해). 부활 때는 세라 자리에서 솟음.
class Phoenix extends Node2D:
	var sera: PSera
	var fox := false
	var awake := false
	var dmg := 150.0
	var view := Rect2()
	var dir := 1
	var y := 0.0
	var ground_y := 0.0
	var t := 0.0
	var _hit := {}
	var _chit := {}
	var trail: Array = [] ## 지나간 자리 [위치, 시각] (찢어진 화면)
	var revive_mode := false ## 부활 때: 세라 자리에서 위로 솟음
	var origin := Vector2.ZERO
	var circles: Array = [] ## [중심, 반지름, 나타나는 시각, 회전 속도, 무늬 종류]
	var crystals: Array = [] ## [x, 높이, 너비, 기울기, 솟는 시각]
	var _solid: NormalLayer
	var _flew := false
	var _ember := 0.0
	const MANIFEST := 0.35 ## 가운데 불사조가 나타나는 시각
	const FLY0 := 1.05 ## 날아가기 시작
	const BACK := 0.28 ## 뒤로 크게 도는 시간
	const CROSS := 0.55 ## 화면을 가로지르는 시간
	const END := 2.3

	func _ready() -> void:
		z_index = 9
		if revive_mode:
			return
		_solid = NormalLayer.new()
		_solid.fn = _draw_solid
		_solid.z_index = -1
		add_child(_solid)
		var c := view.get_center()
		circles.append([c + Vector2(0, -10), 118.0, 0.05, 0.25 * dir, 0])
		circles.append([c + Vector2(0, -10), 70.0, 0.12, -0.6 * dir, 1])
		# 화면 곳곳에 겹치는 크고 작은 마법진 (격자 + 흔들림)
		var cols := 5
		var rows := 3
		for i in cols * rows:
			var gx := (float(i % cols) + 0.5) / float(cols)
			var gy := (floorf(float(i) / float(cols)) + 0.5) / float(rows)
			var pos := view.position + Vector2(gx * view.size.x, gy * view.size.y * 0.85) + Vector2(randf_range(-24, 24), randf_range(-18, 18))
			circles.append([pos, randf_range(22.0, 52.0), 0.08 + randf() * 0.4, randf_range(0.5, 1.6) * (1.0 if randf() < 0.5 else -1.0), i % 3])
		# 바닥의 결정 가시
		var x := view.position.x + randf_range(0, 14)
		while x < view.end.x:
			var big := randf() < 0.35
			crystals.append([x, randf_range(50.0, 96.0) if big else randf_range(18.0, 44.0), randf_range(13.0, 22.0) if big else randf_range(7.0, 12.0), randf_range(-0.35, 0.35), 0.15 + randf() * 0.5])
			x += randf_range(14.0, 34.0)

	func _pos() -> Vector2:
		if revive_mode:
			var kk := clampf(t / 0.9, 0.0, 1.0)
			return origin + Vector2(sin(kk * 6.0) * 6.0, -kk * kk * 220.0)
		var c := view.get_center() + Vector2(0, -20)
		if t < FLY0:
			return c + Vector2(0, sin(t * 3.0) * 3.0 - (1.0 - clampf((t - MANIFEST) / 0.4, 0.0, 1.0)) * 30.0)
		var rear := view.position.x - 50.0 if dir > 0 else view.end.x + 50.0
		var front := view.end.x + 120.0 if dir > 0 else view.position.x - 120.0
		if t < FLY0 + BACK:
			var k := clampf((t - FLY0) / BACK, 0.0, 1.0)
			var e := 1.0 - (1.0 - k) * (1.0 - k)
			return Vector2(lerpf(c.x, rear, e), lerpf(c.y, view.position.y + 40.0, sin(k * PI * 0.5)))
		var k := clampf((t - FLY0 - BACK) / CROSS, 0.0, 1.0)
		return Vector2(lerpf(rear, front, k * k * (3.0 - 2.0 * k) * 0.5 + k * 0.5), lerpf(view.position.y + 40.0, y, minf(k * 2.2, 1.0)) - sin(k * PI) * 10.0)

	func _flying() -> bool:
		return revive_mode or t >= FLY0

	func _process(delta: float) -> void:
		t += delta
		var p := _pos()
		if _flying():
			trail.append([p, t])
		trail = trail.filter(func(e: Array) -> bool: return t - float(e[1]) < 0.5)
		if not revive_mode:
			if t >= FLY0 and not _flew:
				_flew = true
				Sfx.play(&"phoenix_cry")
				Fx.flash(Color(1, 0.85, 0.5, 0.5), 0.25)
				Fx.shake(0.35, 0.5)
			if _flying() and is_instance_valid(sera):
				var n := PSpells.hit_circle(sera, p, 70.0, dmg, fox, _hit, {"heavy": true, "launch": 2.0})
				if n > 0:
					Fx.hitstop(0.06)
			# 결정 가시: 다 솟으면 위에 선 허수아비에게 한 번
			if is_instance_valid(sera) and t > 0.5 and t < 0.6:
				for cr: Array in crystals:
					var r := Rect2(float(cr[0]) - float(cr[2]), ground_y - float(cr[1]), float(cr[2]) * 2.0, float(cr[1]))
					PSpells.hit_rect(sera, r, dmg * 0.2, fox, _chit, {"track": true})
			_ember -= delta
			if _ember <= 0.0 and t < END - 0.3:
				_ember = 0.05
				PVfx.embers(Vector2(view.get_center().x, ground_y - 10), 6, fox, 120.0, Vector2(view.size.x * 0.5, 10))
			if t > 0.2 and t < FLY0:
				Fx.shake(0.04, 0.05)
			if _solid:
				_solid.queue_redraw()
		if randf() < 0.9 and _flying():
			PVfx.embers(p, 3, fox, 90.0)
		if t > (END if not revive_mode else 1.4):
			queue_free()
		queue_redraw()

	## 전체 밝기: 나타남 → 유지 → 사라짐
	func _fade() -> float:
		return clampf(t / 0.25, 0.0, 1.0) * clampf((END - t) / 0.45, 0.0, 1.0)

	# ── 일반 합성 층: 붉은 화면 + 결정 가시 몸통 ──
	func _draw_solid(c: CanvasItem) -> void:
		var a := _fade()
		var tint := Color(0.12, 0.03, 0.12) if fox else Color(0.22, 0.02, 0.02)
		c.draw_rect(view.grow(40), Color(tint, 0.55 * a))
		var dark := Color("#1a2a6a") if fox else Color("#7a1a08")
		var mid := Color("#3a6ad8") if fox else Color("#e0601a")
		var hi := Color("#bfe0ff") if fox else Color("#ffc060")
		for cr: Array in crystals:
			var k := _rise(cr)
			if k <= 0.0:
				continue
			var h := float(cr[1]) * k
			var w := float(cr[2])
			var base := Vector2(float(cr[0]), ground_y + 2.0)
			var tip := base + Vector2(sin(float(cr[3])) * h, -h)
			var l := base + Vector2(-w, 0)
			var r := base + Vector2(w, 0)
			var mid_pt := base.lerp(tip, 0.55) + Vector2(w * 0.15, 0)
			PVfx.safe_poly(c, PackedVector2Array([l, tip, mid_pt]), Color(dark, a))
			PVfx.safe_poly(c, PackedVector2Array([mid_pt, tip, r]), Color(mid, a))
			c.draw_line(mid_pt, tip, Color(hi, a), 1.0)

	func _rise(cr: Array) -> float:
		var k := clampf((t - float(cr[4])) / 0.18, 0.0, 1.0)
		var back := 1.0 + 0.25 * sin(k * PI) # 살짝 솟구쳤다 자리 잡음
		return k * back * clampf((END - 0.1 - t) / 0.4, 0.0, 1.0)

	func _draw() -> void:
		var pal := PSpells._pal(fox)
		if not revive_mode:
			var a := _fade()
			# 가운데 큰 빛무리
			var cc := view.get_center() + Vector2(0, -20)
			draw_circle(cc, 150.0, Color(pal[3], 0.10 * a))
			draw_circle(cc, 90.0, Color(pal[2], 0.10 * a))
			for ci: Array in circles:
				var k := clampf((t - float(ci[2])) / 0.22, 0.0, 1.0)
				if k <= 0.0:
					continue
				var s := 0.6 + 0.4 * (1.0 - (1.0 - k) * (1.0 - k))
				_rune_circle(ci[0], float(ci[1]) * s, t * float(ci[3]), a * k, int(ci[4]), pal)
			# 결정 가시의 빛 테두리 + 끝 불꽃
			for cr: Array in crystals:
				var k := _rise(cr)
				if k <= 0.0:
					continue
				var h := float(cr[1]) * k
				var base := Vector2(float(cr[0]), ground_y + 2.0)
				var tip := base + Vector2(sin(float(cr[3])) * h, -h)
				draw_polyline(PackedVector2Array([base + Vector2(-float(cr[2]), 0), tip, base + Vector2(float(cr[2]), 0)]), Color(pal[1], 0.7 * a), 1.0)
				var fl := 5.0 + sin(t * 18.0 + float(cr[0])) * 2.0
				PVfx.safe_poly(self, PackedVector2Array([tip + Vector2(-3, 2), tip + Vector2(0, -fl * 2.0), tip + Vector2(3, 2)]), Color(pal[1], 0.8 * a))
				draw_circle(tip, 2.5, Color(pal[0], 0.8 * a))
				draw_circle(base + Vector2(0, -2), float(cr[2]) * 1.4, Color(pal[2], 0.18 * a))
		# 찢어진 화면 자국: 지나간 길을 따라 조각 사각형(방향이 꺾여도 안전)
		for i in range(1, trail.size()):
			var e0: Array = trail[i - 1]
			var e1: Array = trail[i]
			var p0: Vector2 = e0[0]
			var p1: Vector2 = e1[0]
			if p0.distance_to(p1) < 0.5:
				continue
			var age := t - float(e1[1])
			var w := (1.0 - age / 0.5) * 20.0
			var n := (p1 - p0).normalized().orthogonal()
			draw_line(p0, p1, Color(pal[2], 0.45), w * 2.0)
			draw_line(p0, p1, Color(pal[1], 0.7), w)
			draw_line(p0, p1, Color(pal[0], 0.9), maxf(w * 0.3, 1.0))
			draw_line(p0 + n * w, p1 + n * w, Color(pal[0], 0.8), 1.0) # 찢긴 화면 가장자리
		# 불사조 본체
		if revive_mode:
			_draw_side(_pos(), -PI / 2, 1.0, 1.7, 1.0)
		elif t < FLY0:
			var k := clampf((t - MANIFEST) / 0.3, 0.0, 1.0)
			if k > 0.0:
				_draw_front(_pos(), 2.2 * (0.5 + 0.5 * k), k)
		elif t < FLY0 + BACK + CROSS + 0.4:
			var p := _pos()
			var prev: Vector2 = (trail[trail.size() - 2][0] as Vector2) if trail.size() > 1 else p - Vector2(dir, 0)
			var face := 1.0 if p.x >= prev.x else -1.0
			_draw_side(p, 0.0, face, 2.6, 1.0)

	## 룬·톱니 마법진 하나
	func _rune_circle(c: Vector2, r: float, rot: float, a: float, kind: int, pal: Array) -> void:
		var gold := Color(pal[1], 0.85 * a)
		var dim := Color(pal[2], 0.55 * a)
		draw_circle(c, r, Color(pal[3], 0.08 * a))
		draw_arc(c, r, 0, TAU, 48, gold, 1.5)
		draw_arc(c, r * 0.84, 0, TAU, 40, dim, 1.0)
		# 바깥 톱니
		var teeth := maxi(int(r / 3.2), 8)
		for i in teeth:
			var ang := rot + float(i) * TAU / float(teeth)
			var d := Vector2(cos(ang), sin(ang))
			var tn := d.orthogonal()
			var tw := minf(1.4, r * 0.03)
			PVfx.safe_poly(self, PackedVector2Array([c + d * r - tn * tw, c + d * (r + 3.5) - tn * tw * 0.7, c + d * (r + 3.5) + tn * tw * 0.7, c + d * r + tn * tw]), gold)
		# 고리 사이의 룬 글자 (짧은 획 묶음)
		var runes := maxi(int(r / 4.0), 8)
		for i in runes:
			var ang := -rot * 0.7 + float(i) * TAU / float(runes)
			var d := Vector2(cos(ang), sin(ang))
			var tn := d.orthogonal()
			var m := c + d * r * 0.92
			var hsh := (i * 7 + kind * 3) % 4
			draw_line(m - d * 2.0, m + d * 2.0, gold, 1.0)
			if hsh != 0:
				draw_line(m + d * (2.0 - hsh), m + d * (2.0 - hsh) + tn * 2.0, gold, 1.0)
			if hsh == 2:
				draw_line(m - d * 2.0, m - d * 2.0 - tn * 1.5, gold, 1.0)
		# 안쪽 별 무늬: 0 = 육망성, 1 = 오망성, 2 = 겹친 사각
		var rr := r * 0.78
		var r0 := -rot * 1.3
		if kind == 1:
			var star := PackedVector2Array()
			for j in 6:
				var ang := r0 + float((j * 2) % 5) * TAU / 5.0 - PI / 2.0
				star.append(c + Vector2(cos(ang), sin(ang)) * rr)
			draw_polyline(star, dim, 1.0)
		else:
			var corners := 3 if kind == 0 else 4
			for k in 2:
				var poly := PackedVector2Array()
				for j in corners + 1:
					var ang := r0 + float(k) * PI / float(corners) + float(j) * TAU / float(corners)
					poly.append(c + Vector2(cos(ang), sin(ang)) * rr)
				draw_polyline(poly, dim, 1.0)
		draw_arc(c, r * 0.4, 0, TAU, 24, gold, 1.0)
		draw_circle(c, r * 0.12, Color(pal[0], 0.6 * a))

	## 정면 불사조 (나타날 때): 위로 펼친 큰 날개, 흰 금빛 몸, 아래로 흘러내리는 꼬리깃
	func _draw_front(p: Vector2, s: float, a: float) -> void:
		var pal := PSpells._pal(fox)
		var flap := sin(t * 7.0) * 0.12
		draw_circle(p, 60.0 * s, Color(pal[2], 0.12 * a))
		draw_circle(p, 30.0 * s, Color(pal[1], 0.2 * a))
		# 꼬리깃 5가닥
		for i in 5:
			var sx := (float(i) - 2.0) * 0.5
			var sw := sin(t * 5.0 + i) * 3.0
			var tail := PackedVector2Array([Vector2(-3, 6), Vector2(sx * 10.0 - 3.0 + sw, 26), Vector2(sx * 22.0 + sw * 1.5, 48 - absf(sx) * 8.0), Vector2(sx * 10.0 + 3.0 + sw, 26), Vector2(3, 6)])
			for j in tail.size():
				tail[j] = p + tail[j] * s
			PVfx.safe_poly(self, tail, Color(pal[2 if i % 2 == 0 else 1], 0.75 * a))
		# 날개 (3겹: 바깥 진한 불 → 밝은 불 → 흰빛)
		for side in [-1.0, 1.0]:
			for layer in 3:
				var ls: float = [1.0, 0.72, 0.45][layer]
				var col: Color = [Color(pal[2], 0.85 * a), Color(pal[1], 0.9 * a), Color(pal[0], 0.95 * a)][layer]
				var pts := PackedVector2Array([p + Vector2(side * 3.0, 4.0) * s])
				for i in 8:
					var f := float(i) / 7.0
					var tip := Vector2(side * (8.0 + 58.0 * f), -6.0 - 46.0 * sin(f * PI * 0.85) * (1.0 + flap) + 14.0 * f) * ls
					var valley := tip * 0.8 + Vector2(0, 4.0)
					pts.append(p + tip * s)
					if i < 7:
						pts.append(p + valley * s)
				pts.append(p + Vector2(side * 4.0, 10.0) * s * ls)
				PVfx.safe_poly(self, pts, col)
		# 몸 + 머리 + 볏
		PVfx.safe_poly(self, PackedVector2Array([p + Vector2(0, -16) * s, p + Vector2(6, -4) * s, p + Vector2(4, 12) * s, p + Vector2(0, 18) * s, p + Vector2(-4, 12) * s, p + Vector2(-6, -4) * s]), Color(pal[1], a))
		PVfx.safe_poly(self, PackedVector2Array([p + Vector2(0, -12) * s, p + Vector2(3, -3) * s, p + Vector2(0, 10) * s, p + Vector2(-3, -3) * s]), Color(pal[0], a))
		for i in 3:
			var cx := (float(i) - 1.0) * 3.0
			PVfx.safe_poly(self, PackedVector2Array([p + Vector2(cx - 1.5, -15) * s, p + Vector2(cx * 2.0, -27 + absf(cx)) * s, p + Vector2(cx + 1.5, -15) * s]), Color(pal[1], 0.9 * a))
		draw_circle(p + Vector2(0, -14) * s, 3.5 * s, Color(pal[0], a))

	## 옆모습 불사조 (날아갈 때)
	func _draw_side(p: Vector2, rot: float, face: float, sc: float, a: float) -> void:
		var pal := PSpells._pal(fox)
		var flap := sin(t * 16.0)
		draw_set_transform(p, rot, Vector2(face, 1.0) * sc)
		draw_circle(Vector2.ZERO, 34.0, Color(pal[2], 0.16 * a))
		for side in [-1, 1]:
			var wing := PackedVector2Array([Vector2(4, 0), Vector2(-10, side * (-20 - flap * 10)), Vector2(-38, side * (-38 - flap * 14)),
				Vector2(-58, side * (-30 - flap * 10)), Vector2(-40, side * (-16 - flap * 4)), Vector2(-52, side * (-10 - flap * 2)), Vector2(-18, side * -4)])
			PVfx.safe_poly(self, wing, Color(pal[2], 0.85 * a))
			var inner := PackedVector2Array([Vector2(2, 0), Vector2(-12, side * (-16 - flap * 8)), Vector2(-34, side * (-28 - flap * 11)), Vector2(-20, side * -6)])
			PVfx.safe_poly(self, inner, Color(pal[1], 0.95 * a))
			draw_polyline(PackedVector2Array([Vector2(-10, side * (-20 - flap * 10)), Vector2(-38, side * (-38 - flap * 14)), Vector2(-58, side * (-30 - flap * 10))]), Color(pal[0], a), 1.5)
		for i in 3:
			var tail := PackedVector2Array([Vector2(-10, 0), Vector2(-40 - i * 10, (i - 1) * 6 + sin(t * 9.0 + i) * 4), Vector2(-70 - i * 14, (i - 1) * 10 + sin(t * 7.0 + i) * 7), Vector2(-44 - i * 10, (i - 1) * 3)])
			PVfx.safe_poly(self, tail, Color(pal[1 if i == 1 else 2], 0.8 * a))
		PVfx.safe_poly(self, PackedVector2Array([Vector2(16, -2), Vector2(6, -6), Vector2(-12, -3), Vector2(-12, 3), Vector2(6, 5)]), Color(pal[1], a))
		PVfx.safe_poly(self, PackedVector2Array([Vector2(14, -2), Vector2(6, -4), Vector2(-8, -1), Vector2(6, 3)]), Color(pal[0], a))
		PVfx.safe_poly(self, PackedVector2Array([Vector2(16, -2), Vector2(22, 0), Vector2(16, 2)]), Color(pal[0], a))
		PVfx.safe_poly(self, PackedVector2Array([Vector2(12, -4), Vector2(8, -12), Vector2(4, -5)]), Color(pal[0], a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## 쓰러질 때 부활 (불사조가 세라 자리에서 솟아오름, 주변을 밀쳐 냄)
static func phoenix_revive(sera: PSera) -> void:
	var awake := PState.awakened("phoenix")
	if awake:
		sera.hp2 = PData.MAX_HEARTS * 2
	var p := Phoenix.new()
	p.sera = sera
	p.fox = sera.is_fox()
	p.revive_mode = true
	p.origin = sera.global_position + Vector2(0, -10)
	PVfx.add(p, Vector2.ZERO, true)
	hit_circle(sera, sera.center(), 90.0 if awake else 60.0, 120.0 if awake else 40.0, false, {}, {"heavy": true, "launch": 2.0})
	sera.lock_cast(0.6, true)
	Fx.flash(Color(1, 0.85, 0.5, 0.6), 0.4)
	Fx.hitstop(0.15)
	Fx.shake(0.3, 0.3)
	Sfx.play(&"phoenix_cry")


# ═══════════════════════════════════════════════════════════
# 7. 너울 바인드 (대마법) — 화면에 거대한 아홉 꼬리 여우신이 나타나 모든 적을 5초 붙잡고, 그동안 무자비한 참격을 퍼붓는다
# ═══════════════════════════════════════════════════════════

static func _bind(sera: PSera) -> void:
	sera.lock_cast(0.9, true)
	var b := Bind.new()
	b.sera = sera
	b.view = _view_rect(sera)
	b.awake = PState.awakened("bind")
	b.dmg = 14.0 * _mult(sera, "bind")
	PVfx.add(b, Vector2.ZERO, true)
	Sfx.play(&"roar", -2.0)
	Fx.flash(Color(0.5, 0.75, 1.0, 0.4), 0.3)
	Fx.shake(0.2, 0.4)


class Bind extends Node2D:
	var sera: PSera
	var view := Rect2()
	var awake := false
	var dmg := 14.0 ## 참격 한 줄기 피해 (마지막 X 참격은 ×7)
	var t := 0.0
	var _bound := false
	var _finale := false
	var _targets: Array = []
	var _streaks: Array = [] ## [시작, 끝, 태어난 시각, 굵기]
	var _next := 0.0
	var _solid: NormalLayer
	const BIND_AT := 0.85 ## 여우신이 다 나타나고 붙잡는 시각
	const SLASH_FROM := 1.05
	const FINALE := 4.95 ## 마지막 X자 참격
	const END := 5.7
	const STREAK_LIFE := 0.38

	func _ready() -> void:
		z_index = 9
		_solid = NormalLayer.new()
		_solid.fn = _draw_solid
		_solid.z_index = -1
		add_child(_solid)

	func _process(delta: float) -> void:
		t += delta
		if not _bound and t >= BIND_AT:
			_bound = true
			for d: PDummy in PDummy.all(get_tree()):
				if view.grow(40).has_point(d.global_position):
					d.bind(5.0, awake)
					_targets.append(d)
			Fx.shake(0.3, 0.35)
			Sfx.play(&"chain", -2.0)
		# 무자비한 참격: 붙잡힌 적마다 비스듬한 거대 참격이 쉴 새 없이
		if t >= SLASH_FROM and t < FINALE:
			_next -= delta
			while _next <= 0.0:
				_next += 0.055 if awake else 0.075
				_slash_once()
		if not _finale and t >= FINALE:
			_finale = true
			var c := view.get_center()
			var d1 := Vector2(view.size.x * 0.55, view.size.y * 0.45)
			_streaks.append([c - d1, c + d1, t, 40.0])
			_streaks.append([c + Vector2(d1.x, -d1.y), c - Vector2(d1.x, -d1.y), t + 0.06, 40.0])
			for d in _targets:
				if is_instance_valid(d):
					(d as PDummy).take_hit(int(dmg * 7.0), (d as PDummy).center(), {"fox": true, "heavy": true, "launch": 2.5})
			Fx.flash(Color(0.8, 0.95, 1.0, 0.7), 0.35)
			Fx.hitstop(0.14)
			Fx.shake(0.7, 0.5)
			Sfx.play(&"fox_storm")
			Sfx.play(&"explode", -6.0)
		_streaks = _streaks.filter(func(s: Array) -> bool: return t - float(s[2]) < STREAK_LIFE + 0.1)
		if t > END:
			queue_free()
		queue_redraw()
		_solid.queue_redraw()

	func _slash_once() -> void:
		var live: Array = _targets.filter(func(d: Variant) -> bool: return is_instance_valid(d))
		# 참격은 화면 전체를 가로지름: 절반은 붙잡힌 적을 지나고, 절반은 화면 아무 곳이나 가른다
		var c := view.position + Vector2(randf_range(0.1, 0.9) * view.size.x, randf_range(0.15, 0.85) * view.size.y)
		var tgt: PDummy = null
		if not live.is_empty() and randf() < 0.6:
			tgt = live[randi() % live.size()]
			c = tgt.center() + Vector2(randf_range(-10, 10), randf_range(-12, 12))
		var ang := randf_range(0.08, 0.8) * (1.0 if randf() < 0.5 else -1.0) + (PI if randf() < 0.5 else 0.0)
		var d := Vector2(cos(ang), sin(ang))
		var half := randf_range(0.5, 0.8) * view.size.x
		var w := randf_range(12.0, 22.0)
		# 네 번에 한 번은 발톱 자국 셋(나란한 세 줄)
		var n := 3 if randi() % 4 == 0 else 1
		for i in n:
			var off := d.orthogonal() * (float(i) - float(n - 1) * 0.5) * 12.0
			_streaks.append([c - d * half + off, c + d * half + off, t + i * 0.02, w * (0.75 if n > 1 else 1.0)])
		for dd in live:
			var q: Vector2 = (dd as PDummy).center()
			var rel := q - c
			if dd == tgt or (absf(rel.dot(d)) < half and absf(rel.dot(d.orthogonal())) < 18.0):
				(dd as PDummy).take_hit(int(dmg), q, {"fox": true})
			if randf() < 0.3:
				Fx.shake(0.06, 0.06)
		if randf() < 0.5:
			Sfx.play_pitch(&"swing", randf_range(1.1, 1.5), -6.0)

	func _fade() -> float:
		return clampf(t / 0.45, 0.0, 1.0) * clampf((END - t) / 0.6, 0.0, 1.0)

	# ── 일반 합성: 어두워지는 화면 + 참격 가장자리의 먹빛 ──
	func _draw_solid(c: CanvasItem) -> void:
		c.draw_rect(view.grow(40), Color(0.01, 0.02, 0.08, 0.5 * _fade()))
		for s: Array in _streaks:
			var g := _streak_k(s)
			if g.x <= 0.0:
				continue
			var p0: Vector2 = s[0]
			var p1: Vector2 = s[1]
			var d := (p1 - p0).normalized()
			var n := d.orthogonal()
			PVfx.blade(c, p0 + n * float(s[3]) * 0.55, p0.lerp(p1, g.x) + n * float(s[3]) * 0.55, float(s[3]) * 0.7 * g.y, Color(0.0, 0.01, 0.04, 0.85))

	## x = 그어진 정도, y = 굵기 배율(사라지며 가늘어짐)
	func _streak_k(s: Array) -> Vector2:
		var age := t - float(s[2])
		if age < 0.0:
			return Vector2.ZERO
		return Vector2(clampf(age / 0.06, 0.0, 1.0), 1.0 - clampf((age - 0.1) / (STREAK_LIFE - 0.1), 0.0, 1.0))

	func _draw() -> void:
		var pal := PSpells._pal(true)
		var a := _fade()
		var appear := clampf(t / BIND_AT, 0.0, 1.0)
		var c := Vector2(view.get_center().x, view.position.y + view.size.y * 0.46)
		var s := view.size.y / 360.0 * (0.75 + 0.25 * (1.0 - pow(1.0 - appear, 3.0)))
		var fa := a * (1.0 if t < SLASH_FROM else 0.7)
		_draw_fox_god(c, s, fa, pal)
		# 붙잡는 여우불 사슬
		if _bound:
			var ca := clampf((t - BIND_AT) / 0.15, 0.0, 1.0) * a
			for d in _targets:
				if not is_instance_valid(d):
					continue
				var tp: Vector2 = (d as PDummy).center()
				var from := c + Vector2(0, 30) * s
				draw_line(from, tp, Color(pal[1], 0.4 * ca), 2.0)
				for i in 5:
					draw_circle(from.lerp(tp, float(i + 1) / 6.0), 2.2, Color(pal[0], 0.6 * ca))
				draw_arc(tp, 22.0 + sin(t * 8.0) * 2.0, 0, TAU, 20, Color(pal[1], 0.6 * ca), 2.0)
		# 참격: 푸른 빛 날 + 흰 심 (먹빛 가장자리는 일반 합성 층)
		for st: Array in _streaks:
			var g := _streak_k(st)
			if g.x <= 0.0:
				continue
			var p0: Vector2 = st[0]
			var p1: Vector2 = (st[0] as Vector2).lerp(st[1], g.x)
			var w: float = float(st[3]) * g.y
			PVfx.blade(self, p0, p1, w * 1.5, Color(pal[2], 0.55))
			PVfx.blade(self, p0, p1, w, Color(pal[1], 0.85))
			PVfx.blade(self, p0, p1, w * 0.35, Color(pal[0], 1.0))

	## 아홉 꼬리 여우신 (정면): 날개처럼 펼친 꼬리 아홉, 불꽃 갈기, 빛나는 눈, 가슴의 문양
	func _draw_fox_god(c: Vector2, s: float, a: float, pal: Array) -> void:
		if a <= 0.01:
			return
		draw_circle(c + Vector2(0, -20) * s, 170.0 * s, Color(pal[3], 0.12 * a))
		draw_circle(c + Vector2(0, -30) * s, 90.0 * s, Color(pal[2], 0.15 * a))
		# 꼬리 아홉: 몸 뒤에서 양옆·위로 부채꼴, 가운데가 통통하고 끝이 말려 올라가는 여우 꼬리 (끝은 흰 불꽃)
		for i in 9:
			var f := float(i) / 8.0
			var side := -1.0 if f < 0.5 else 1.0
			var base := lerpf(PI * 1.08, PI * 1.92, f)
			var sway := sin(t * 2.2 + i * 0.8) * 0.05
			var root := c + Vector2(0, 30) * s
			var dirv := Vector2(cos(base + sway), sin(base + sway))
			var perp := dirv.orthogonal() * side
			var left := PackedVector2Array()
			var right := PackedVector2Array()
			var tip := root
			for k in 13:
				var u := float(k) / 12.0
				var ln := 140.0 - absf(f - 0.5) * 30.0
				var p := root + dirv * ln * s * u + perp * 28.0 * s * u * u * u
				var tan := (dirv * ln + perp * 84.0 * u * u).normalized()
				var w := 32.0 * s * sin(minf(u * 1.15, 1.0) * PI * 0.88 + 0.12)
				var n := tan.orthogonal()
				left.append(p + n * w)
				right.append(p - n * w)
				tip = p
			right.reverse()
			left.append_array(right)
			PVfx.safe_poly(self, left, Color(pal[3], 0.45 * a))
			var inner := PackedVector2Array()
			for k in left.size():
				inner.append(root.lerp(left[k], 0.9))
			PVfx.safe_poly(self, inner, Color(pal[2], 0.4 * a))
			draw_circle(tip, 13.0 * s, Color(pal[1], 0.55 * a))
			draw_circle(tip, 7.0 * s, Color(pal[0], 0.8 * a))
		# 몸통 (가슴·앞다리)
		PVfx.safe_poly(self, PackedVector2Array([c + Vector2(-34, -40) * s, c + Vector2(34, -40) * s, c + Vector2(26, 40) * s, c + Vector2(14, 90) * s,
			c + Vector2(-14, 90) * s, c + Vector2(-26, 40) * s]), Color(pal[2], 0.7 * a))
		PVfx.safe_poly(self, PackedVector2Array([c + Vector2(-14, -30) * s, c + Vector2(14, -30) * s, c + Vector2(8, 60) * s, c + Vector2(-8, 60) * s]), Color(pal[1], 0.7 * a))
		# 가슴의 여우 문양(빛나는 고리)
		draw_arc(c + Vector2(0, 0) * s, 14.0 * s, 0, TAU, 20, Color(pal[0], 0.9 * a), 2.0)
		draw_circle(c, 6.0 * s, Color(pal[0], 0.9 * a))
		# 머리: 큰 세모 귀 둘 + 넓은 뺨 + 아래로 뾰족한 주둥이 (정면 여우 얼굴)
		var h := c + Vector2(0, -78) * s
		for side in [-1.0, 1.0]:
			PVfx.safe_poly(self, PackedVector2Array([h + Vector2(side * 10, -26) * s, h + Vector2(side * 48, -86) * s, h + Vector2(side * 42, -14) * s]), Color(pal[1], 0.9 * a))
			PVfx.safe_poly(self, PackedVector2Array([h + Vector2(side * 18, -26) * s, h + Vector2(side * 42, -70) * s, h + Vector2(side * 36, -20) * s]), Color(pal[3], 0.7 * a))
			# 뺨의 털 (옆으로 뻗은 불꽃)
			PVfx.spike(self, h + Vector2(side * 34, 4) * s, Vector2(side, 0.5).normalized(), 26.0 * s, 14.0 * s, Color(pal[1], 0.75 * a))
		PVfx.safe_poly(self, PackedVector2Array([h + Vector2(-40, -24) * s, h + Vector2(0, -36) * s, h + Vector2(40, -24) * s, h + Vector2(36, 6) * s,
			h + Vector2(14, 30) * s, h + Vector2(0, 50) * s, h + Vector2(-14, 30) * s, h + Vector2(-36, 6) * s]), Color(pal[1], 0.9 * a))
		PVfx.safe_poly(self, PackedVector2Array([h + Vector2(-20, 4) * s, h + Vector2(20, 4) * s, h + Vector2(0, 48) * s]), Color(pal[0], 0.8 * a))
		draw_circle(h + Vector2(0, 46) * s, 4.0 * s, Color(pal[3], a))
		# 이마의 불꽃 무늬
		PVfx.spike(self, h + Vector2(0, -16) * s, Vector2(0, -1), 30.0 * s, 9.0 * s, Color(pal[0], 0.9 * a))
		# 날카롭게 치켜올라간 빛나는 눈
		for side in [-1.0, 1.0]:
			var e := h + Vector2(side * 17, -6) * s
			PVfx.safe_poly(self, PackedVector2Array([e + Vector2(-side * 10, 4) * s, e + Vector2(side * 12, -6) * s, e + Vector2(side * 5, 5) * s]), Color(1, 1, 1, a))


# ═══════════════════════════════════════════════════════════
# 여우방패 — 세라보다 훨씬 큰 여우 정령이 방패로 앞을 1.5초 완전히 막고(무적),
# 방패를 내리며 막은 피해만큼 커진 거대한 할퀴기로 반격한다. 평소 = 붉은 불, 변신 = 푸른 여우불.
# ═══════════════════════════════════════════════════════════

class ShieldSpirit extends Node2D:
	var owner_sera: PSera
	var fox := false
	var dir := 1
	var t := 0.0
	var absorbed := 0 ## 막은 피해(하트 칸)
	var _flash := 0.0
	var _swung := false
	const SWIPE := 0.32 ## 할퀴기 길이

	func _ready() -> void:
		z_index = 8

	func absorb(hearts_n: int) -> void:
		absorbed += hearts_n
		_flash = 1.0
		Fx.shake(0.12, 0.1)
		PVfx.sparks(global_position + Vector2(dir * 40, -40), 10, PSpells._pal(fox)[1], 140.0, 0.3, Vector2(-dir, -0.3), 60.0)

	func _process(delta: float) -> void:
		t += delta
		_flash = maxf(_flash - delta * 4.0, 0.0)
		if is_instance_valid(owner_sera) and t < PData.SHIELD_TIME:
			global_position = owner_sera.global_position
		if not _swung and t >= PData.SHIELD_TIME + 0.05:
			_swung = true
			_swipe_hit()
		if t > PData.SHIELD_TIME + SWIPE + 0.3:
			queue_free()
		queue_redraw()

	func _power() -> float:
		return 1.0 + 0.22 * float(mini(absorbed, 5))

	func _swipe_hit() -> void:
		if not is_instance_valid(owner_sera):
			return
		var dmg := (PData.SHIELD_SWIPE_BASE + PData.SHIELD_SWIPE_PER_HEART * float(absorbed)) * (PData.FOX_DAMAGE if fox else 1.0)
		var w := 180.0 * _power()
		var x0 := global_position.x + (-20.0 if dir > 0 else -w + 20.0)
		PSpells.hit_rect(owner_sera, Rect2(Vector2(x0, global_position.y - 100.0 * _power()), Vector2(w, 100.0 * _power())), dmg, fox, {}, {"heavy": true, "launch": 1.5})
		Fx.shake(0.25 + 0.05 * absorbed, 0.25)
		Fx.hitstop(0.06)
		Sfx.play(&"swing", -2.0)
		Sfx.play(&"blast", -6.0 + absorbed)

	func _draw() -> void:
		var pal := PSpells._pal(fox)
		var gold := Color(1.0, 0.8, 0.3)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1.0))
		var appear := 1.0 - pow(1.0 - clampf(t / 0.15, 0.0, 1.0), 3.0)
		var guard := t < PData.SHIELD_TIME
		var st := t - PData.SHIELD_TIME
		var a := 1.0 if guard else clampf(1.0 - (st - SWIPE) / 0.3, 0.0, 1.0)
		var sc := 0.7 + 0.3 * appear
		# 여우 정령: 세라 뒤에 우뚝 선 키 약 100px의 불꽃 여우 (가장자리가 일렁이는 불꽃 실루엣)
		var o := Vector2(12, 0)
		var aa := a * appear
		# 꼬리 셋 (뒤로 휘어 올라가는 통통한 꼬리, 끝은 흰 불)
		for i in 3:
			var base := PI + 0.5 + (float(i) - 1.0) * 0.45
			var dv := Vector2(cos(base), sin(base))
			var pv := dv.orthogonal()
			var root := o + Vector2(-12, -34) * sc
			var lp := PackedVector2Array()
			var rp := PackedVector2Array()
			var tip := root
			for k in 10:
				var u := float(k) / 9.0
				var wv := sin(t * 5.0 + i + u * 3.0) * 4.0 * u
				var q := root + (dv * 52.0 * u + pv * (22.0 * u * u + wv)) * sc
				var w := 11.0 * sc * sin(minf(u * 1.2, 1.0) * PI * 0.88 + 0.12)
				lp.append(q + pv * w)
				rp.append(q - pv * w)
				tip = q
			rp.reverse()
			lp.append_array(rp)
			PVfx.safe_poly(self, lp, Color(pal[3], 0.5 * aa))
			draw_circle(tip, 6.0 * sc, Color(pal[1], 0.7 * aa))
			draw_circle(tip, 3.0 * sc, Color(pal[0], 0.9 * aa))
		# 몸: 일렁이는 불꽃 기둥 (바깥 → 안쪽 → 흰 결)
		for layer in 3:
			var shrink: float = [1.0, 0.68, 0.36][layer]
			var col: Color = [Color(pal[3], 0.45 * aa), Color(pal[2], 0.5 * aa), Color(pal[1], 0.55 * aa)][layer]
			var lpts := PackedVector2Array()
			var rpts := PackedVector2Array()
			for k in 10:
				var u := float(k) / 9.0
				var y := -u * 72.0
				var half := (13.0 + 7.0 * sin(u * PI * 0.9)) * shrink
				var jit := sin(t * 9.0 + k * 1.7 + layer) * 2.5
				lpts.append(o + Vector2(-half - jit, y) * sc)
				rpts.append(o + Vector2(half + jit * 0.6, y) * sc)
			rpts.reverse()
			lpts.append_array(rpts)
			PVfx.safe_poly(self, lpts, col)
		for i in 4:
			var x := (float(i) - 1.5) * 5.0
			draw_line(o + Vector2(x, -6) * sc, o + Vector2(x * 0.6, -64) * sc, Color(pal[0], 0.35 * aa), 1.0)
		# 머리: 큰 귀 둘 + 앞으로 뻗은 주둥이 + 빛나는 눈 (옆모습)
		var hd := o + Vector2(2, -86) * sc
		PVfx.safe_poly(self, PackedVector2Array([hd + Vector2(-10, -8) * sc, hd + Vector2(-8, -34) * sc, hd + Vector2(0, -14) * sc]), Color(pal[1], 0.85 * aa))
		PVfx.safe_poly(self, PackedVector2Array([hd + Vector2(2, -12) * sc, hd + Vector2(10, -36) * sc, hd + Vector2(12, -10) * sc]), Color(pal[1], 0.85 * aa))
		PVfx.safe_poly(self, PackedVector2Array([hd + Vector2(-14, -6) * sc, hd + Vector2(8, -14) * sc, hd + Vector2(16, -6) * sc, hd + Vector2(32, 2) * sc,
			hd + Vector2(14, 10) * sc, hd + Vector2(-8, 12) * sc, hd + Vector2(-16, 4) * sc]), Color(pal[2], 0.8 * aa))
		PVfx.safe_poly(self, PackedVector2Array([hd + Vector2(0, -4) * sc, hd + Vector2(28, 2) * sc, hd + Vector2(8, 6) * sc]), Color(pal[0], 0.8 * aa))
		PVfx.safe_poly(self, PackedVector2Array([hd + Vector2(4, -6) * sc, hd + Vector2(14, -8) * sc, hd + Vector2(10, -3) * sc]), Color(1, 1, 1, aa))
		if guard:
			# 방패: 여우 문장이 새겨진 큰 연 모양 방패를 앞에 세움 (세라보다 큼)
			var sp := o + Vector2(30, -44) * sc
			var shield := PackedVector2Array([sp + Vector2(-6, -44) * sc, sp + Vector2(14, -38) * sc, sp + Vector2(18, 0) * sc, sp + Vector2(10, 34) * sc, sp + Vector2(-2, 46) * sc, sp + Vector2(-10, 30) * sc, sp + Vector2(-12, -30) * sc])
			var fl := _flash
			PVfx.safe_poly(self, shield, Color(pal[2].lerp(Color.WHITE, fl * 0.6), (0.75 + 0.2 * fl) * appear))
			var rim := shield.duplicate()
			rim.append(shield[0])
			draw_polyline(rim, Color(gold, 0.9 * appear), 2.0)
			# 문장: 여우 얼굴 + 불꽃
			PVfx.safe_poly(self, PackedVector2Array([sp + Vector2(-4, -12) * sc, sp + Vector2(-2, -22) * sc, sp + Vector2(2, -14) * sc, sp + Vector2(6, -22) * sc, sp + Vector2(8, -12) * sc, sp + Vector2(2, 2) * sc]), Color(pal[0], 0.9 * appear))
			draw_arc(sp + Vector2(2, -6) * sc, 16.0 * sc, 0, TAU, 20, Color(gold, 0.6 * appear), 1.5)
			# 방패 앞 빛의 벽(완전히 막음) + 흡수 표시(막을수록 밝아짐)
			var wall := 0.25 + 0.1 * sin(t * 20.0) + 0.12 * float(mini(absorbed, 5))
			draw_line(sp + Vector2(22, -50) * sc, sp + Vector2(22, 50) * sc, Color(pal[1], wall * appear), 3.0)
			for i in mini(absorbed, 5):
				draw_circle(o + Vector2(-4, -50 + i * 9) * sc, 3.0, Color(pal[0], 0.9))
			# 팔: 방패를 받침
			draw_line(o + Vector2(10, -56) * sc, sp + Vector2(-6, -8) * sc, Color(pal[1], 0.7 * aa), 6.0 * sc)
		else:
			# 반격: 방패를 내리고 옆으로 세 줄 가로베기 (막은 만큼 길고 굵어짐)
			var p := _power()
			var reach := 170.0 * p
			var tip := Vector2.ZERO
			for i in 3:
				var k := clampf((st - i * 0.025) / 0.11, 0.0, 1.0)
				if k <= 0.0:
					continue
				var y := (-30.0 - i * 22.0) * p
				var p0 := o + Vector2(-34, y + 6)
				var p1 := o + Vector2(lerpf(-34.0, reach, k), y - 4)
				var w := 15.0 * p
				PVfx.blade(self, p0, p1, w * 1.6, Color(pal[3], 0.5 * a), -0.6)
				PVfx.blade(self, p0, p1, w, Color(pal[1], 0.85 * a), -0.6)
				PVfx.blade(self, p0, p1, w * 0.3, Color(pal[0], a), -0.6)
				# 뒤로 흩날리는 바람 결
				for j in 2:
					var yy := y + (float(j) - 0.5) * w * 1.4
					draw_line(o + Vector2(-50 - j * 10, yy), o + Vector2(lerpf(-50.0, reach * 0.6, k), yy - 3), Color(pal[1], 0.35 * a), 1.0)
				if i == 1:
					tip = p1
			# 가운데 줄 끝의 커다란 정령 손 (앞으로 발톱을 세움)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			if tip != Vector2.ZERO:
				PVfx.fire_paw(self, Vector2(tip.x * dir, tip.y), 0.0 if dir > 0 else PI, 1.4 * p, fox, a)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
