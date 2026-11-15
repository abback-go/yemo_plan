class_name PSpells
extends RefCounted
## 훈련장 마법 6종(일반마법 2 · 고급마법 2 · 대마법 2) + 여우방패(조작에서 빠짐) + 불사조 부활. try_cast가 쿨을 확인하고 각 마법을 시작한다(마나 없음, 쓰면 폭주 게이지가 참).
## 그림 기준(사용자 참고 이미지): 열선 = 흰 빛줄기 둘레를 감는 나선 화염 고리, 대유성 = 뒤쪽 하늘에서 떨어지는 거대 운석 한 방(앞쪽 절반 폭발),
## 파이어볼 = 세로 마법진에서 솟아 굴러가는 거대한 태양(메이플스토리 플레임 위자드 화염구 느낌).
## 평소엔 순수한 불 마법사(붉은 불), 변신 중에는 푸른 여우불 판(크기 ×1.2~1.25, 피해 ×1.3) + 여우 무늬(여우비의 불여우, 바인드의 아홉 꼬리 여우신 등).

## 가산 합성 노드 안에서 어두운 것(바위·먼지)을 그리는 일반 합성 자식 층
class NormalLayer extends PDraw.Canvas:
	var fn: Callable

	func _paint() -> void:
		if fn.is_valid():
			fn.call(pd)


static var last_fail := "" ## HUD가 칸을 빨갛게 번쩍이게 (마법 ID)
static var last_fail_t := 0.0


static func _mult(sera: PSera, id: String) -> float:
	return PData.lv_mult(PState.level(id)) * (PData.FOX_DAMAGE if sera.is_fox() else 1.0)


static func _pal(fox: bool) -> Array:
	return [PData.FOX_CORE, PData.FOX_HOT, PData.FOX_MID, PData.FOX_DARK] if fox else [PData.FIRE_CORE, PData.FIRE_HOT, PData.FIRE_MID, PData.FIRE_DARK]


static func try_cast(sera: PSera, id: String) -> bool:
	var s := PData.spell(id)
	# 폭주 봉인: 게이지가 가득 차면 변신(너울에게 넘기기) 전까지 마법이 막힌다 — 누르면 넘치는 마력이 튐
	if sera.overloaded():
		last_fail = id
		last_fail_t = 0.5
		PVfx.sparks(_hand(sera), 14, PData.FIRE_HOT, 160.0, 0.35)
		Fx.shake(0.06, 0.08)
		Sfx.play(&"overload_warn", -8.0)
		return false
	if float(sera.cooldowns.get(id, 0.0)) > 0.0:
		last_fail = id
		last_fail_t = 0.35
		Sfx.play(&"block", -10.0)
		return false
	sera.add_gauge(float(PData.OD_SPELL.get(String(s.grade), 0.0)))
	var sig := PVfx.CastSigil.new()
	sig.setup(["일반마법", "고급마법", "대마법"].find(String(s.grade)), sera.is_fox())
	sig.follow = sera
	PVfx.add(sig, sera.global_position, true)
	if not PState.no_cooldown:
		sera.cooldowns[id] = PState.spell_cd(id)
	match id:
		"fireball":
			_fireball(sera)
		"foxrain":
			_foxrain(sera)
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
# 1. 파이어볼 (일반마법) — 세라 앞에 세로 마법진이 열리고, 세라보다 훨씬 큰 태양 같은 불덩이가 진에서 솟아
#    천천히 굴러가며 지나가는 적을 태우고(닿는 동안 짧은 간격 피해), 끝에서 크게 터진다.
#    참고: 메이플스토리 플레임 위자드의 거대 화염구(흰 노란 중심 · 주황 몸 · 둘레에 일렁이는 불꽃 · 뒤의 마법진).
#    폭발 피해는 예전 파이어볼과 같다(48 × 레벨 배율). 각성 = 더 크고, 터질 때 작은 불덩이 다섯이 부채꼴로 튄다.
# ═══════════════════════════════════════════════════════════

static func _fireball(sera: PSera) -> void:
	var fox := sera.is_fox()
	var sun := Sun.new()
	sun.sera = sera
	sun.fox = fox
	sun.dir = sera.facing
	sun.dmg = 48.0 * _mult(sera, "fireball")
	sun.awake = PState.awakened("fireball")
	sun.R = 34.0 * (1.2 if fox else 1.0) * (1.2 if sun.awake else 1.0)
	# 세라 앞 바닥 위에 소환 (공중이면 아래 바닥, 바닥이 멀면 손 높이)
	var x := sera.global_position.x + sera.facing * (sun.R + 16.0)
	var y := sera.global_position.y - 20.0
	var q := PhysicsRayQueryParameters2D.create(Vector2(x, sera.global_position.y - 12.0), Vector2(x, sera.global_position.y + 140.0), 1)
	var hit := sera.get_world_2d().direct_space_state.intersect_ray(q)
	if hit:
		sun.floor_y = (hit.position as Vector2).y
		y = sun.floor_y - sun.R * 0.92
	PVfx.add(sun, Vector2(x, y)) # 몸통은 일반 합성(진한 주황·붉은 색), 빛무리만 가산 합성 자식 층
	var ring := SunCircle.new()
	ring.fox = fox
	ring.dir = sera.facing
	ring.size = sun.R * 1.55
	PVfx.add(ring, Vector2(x - sera.facing * sun.R * 0.35, y), true)
	sera.lock_cast(0.32)
	Sfx.play(&"ignite", -2.0)
	Sfx.play_pitch(&"blast", 0.55, -10.0)
	Fx.shake(0.06, 0.2)


## 세로로 선 마법진 (진행 방향을 향해 비스듬히 = 납작한 타원). 두 겹 고리 · 도는 글자 점 · 육망성 · 빛살.
## 변신 중엔 푸른 진 + 둘레에 아홉 개의 여우 꼬리 문양.
class SunCircle extends PVfx.Base:
	var dir := 1
	var size := 46.0

	func _init() -> void:
		life = 1.15
		z_index = 5

	func _paint() -> void:
		var kk := k()
		var open := 1.0 - pow(1.0 - minf(t / 0.28, 1.0), 3.0)
		var a := 1.0 - clampf((t - 0.6) / 0.55, 0.0, 1.0)
		var pal := PSpells._pal(fox)
		var R := size * open
		var rot := t * 2.4 * dir
		pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.34, 1.0))
		pd.glow(Vector2.ZERO, R * 1.35, Color(pal[2], 0.4 * a))
		pd.draw_arc(Vector2.ZERO, R, 0, TAU, 40, Color(pal[1], 0.95 * a), 3.0)
		pd.draw_arc(Vector2.ZERO, R * 0.9, 0, TAU, 36, Color(pal[0], 0.7 * a), 1.2)
		pd.draw_arc(Vector2.ZERO, R * 0.62, 0, TAU, 32, Color(pal[1], 0.8 * a), 1.8)
		# 고리 사이의 글자 점 (돎)
		for i in 24:
			var ang := rot + float(i) / 24.0 * TAU
			var d := Vector2(cos(ang), sin(ang))
			if i % 3 == 0:
				pd.draw_line(d * R * 0.66, d * R * 0.86, Color(pal[0], 0.9 * a), 2.0)
			else:
				pd.draw_circle(d * R * 0.76, 1.3, Color(pal[1], 0.85 * a))
		# 육망성 (반대로 돎)
		for tri in 2:
			var pts := PackedVector2Array()
			for j in 4:
				var ang := -rot * 0.6 + float(tri) * PI / 3.0 + float(j) * TAU / 3.0
				pts.append(Vector2(cos(ang), sin(ang)) * R * 0.6)
			pd.draw_polyline(pts, Color(pal[1], 0.75 * a), 1.4)
		pd.draw_circle(Vector2.ZERO, R * 0.16, Color(pal[0], 0.8 * a))
		if fox:
			# 아홉 꼬리 문양: 고리 바깥으로 말려 나간 작은 꼬리
			for i in 9:
				var ang := rot * 0.5 + float(i) / 9.0 * TAU
				var d := Vector2(cos(ang), sin(ang))
				PVfx.crescent(pd, d * R * 1.12, R * 0.16, ang + 1.2, ang + 3.6, R * 0.07, Color(pal[1], 0.85 * a), 8)
		pd.draw_set_transform(Vector2.ZERO)
		# 진에서 앞으로 뻗는 빛살 (열리는 순간)
		var ray_a := clampf(1.0 - t / 0.5, 0.0, 1.0)
		if ray_a > 0.0:
			for i in 5:
				var y := (float(i) - 2.0) * R * 0.32
				pd.line2(Vector2(0, y), Vector2(dir * R * (1.2 + 0.4 * float(i % 2)) * (0.4 + kk * 2.0), y * 1.15), Color(pal[0], 0.7 * ray_a), Color(pal[1], 0.0), 2.4, 0.5)


## 거대한 태양: 진에서 부풀어 나와(SUMMON) 천천히 굴러가며(ROLL) 닿는 적을 태우고 끝에서 폭발.
class Sun extends PDraw.Canvas:
	var sera: PSera
	var fox := false
	var dir := 1
	var dmg := 48.0
	var awake := false
	var R := 30.0
	var floor_y := INF
	var t := 0.0
	var _spin := 0.0
	var _dist := 0.0
	var _tick := {} ## 허수아비 → 다음 태우기 시각
	var _touched := {}
	var _trail: Array = [] ## 바닥에 남는 불 [x, 태어난 시각]
	var _trail_x := INF
	var _ember := 0.0
	var _done := false
	var _halo: NormalLayer ## 가산 합성 빛무리 (몸 뒤)
	const SUMMON := 0.42
	const ROLL := 2.1
	const SPEED := 105.0
	const TRAIL_LIFE := 1.1

	func _ready() -> void:
		z_index = 6
		_halo = NormalLayer.new()
		_halo.fn = _draw_halo
		_halo.z_index = -1
		_halo.material = Fx.add_material
		add_child(_halo)

	func _grow() -> float:
		var g := clampf((t - 0.12) / (SUMMON - 0.12), 0.0, 1.0)
		return 1.0 - pow(1.0 - g, 3.0)

	func _process(delta: float) -> void:
		t += delta
		if _done:
			_age_trail()
			if _trail.is_empty():
				queue_free()
			queue_redraw()
			_halo.queue_redraw()
			return
		var pal := PSpells._pal(fox)
		var g := _grow()
		if t >= SUMMON:
			var mv := dir * SPEED * delta * clampf((t - SUMMON) / 0.25, 0.3, 1.0)
			global_position.x += mv
			_dist += absf(mv)
		_spin = _dist / maxf(R, 1.0) * dir + t * 0.6 * dir
		# 바닥에 불 자국 (굴러간 거리 10px마다)
		if floor_y < INF and global_position.y + R * 1.3 >= floor_y and g > 0.6:
			if _trail_x == INF or absf(global_position.x - _trail_x) >= 10.0:
				_trail_x = global_position.x
				_trail.append([global_position.x + randf_range(-4, 4), t, randf_range(0.7, 1.2)])
		_age_trail()
		# 태우기: 닿는 동안 0.22초마다 (처음 닿을 땐 묵직하게)
		if is_instance_valid(sera) and g > 0.5:
			var rad := R * 1.05 * g
			for d: PDummy in PDummy.all(get_tree()):
				var rr := d.hit_rect()
				var q := Vector2(clampf(global_position.x, rr.position.x, rr.end.x), clampf(global_position.y, rr.position.y, rr.end.y))
				if q.distance_to(global_position) > rad:
					continue
				if t < float(_tick.get(d, 0.0)):
					continue
				_tick[d] = t + 0.22
				var first := not _touched.has(d)
				_touched[d] = true
				d.take_hit(int(round(dmg * 0.08)), global_position, {"fox": fox, "heavy": first, "launch": 1.0 if first else 0.3})
				PVfx.sparks(q, 6 if not first else 14, pal[1], 170.0, 0.3, Vector2(dir, -0.6), 60.0)
				if first:
					Fx.hitstop(0.035)
					Fx.shake(0.12, 0.15)
					PVfx.kick(Vector2(dir * 3.0, 0))
					Sfx.play_pitch(&"hit_heavy", 0.8, -6.0)
				else:
					Fx.shake(0.04, 0.06)
		# 불티·불꽃 (시간 간격으로 적당히)
		_ember -= delta
		if _ember <= 0.0 and g > 0.3:
			_ember = 0.03
			var ang := randf() * TAU
			var p := global_position + Vector2(cos(ang), sin(ang)) * R * g * 0.9
			PParticles.get_layer(true).spawn(p, Vector2(-dir * randf_range(20, 60), -randf_range(40, 110)), Vector2(0, -40),
				randf_range(0.35, 0.7), randf_range(1.5, 3.0), pal[0], pal[3], 0, 1.0)
		if t >= SUMMON + ROLL:
			_explode()
		queue_redraw()
		_halo.queue_redraw()

	func _age_trail() -> void:
		while not _trail.is_empty() and t - float(_trail[0][1]) > TRAIL_LIFE:
			_trail.pop_front()

	func _explode() -> void:
		_done = true
		var pal := PSpells._pal(fox)
		var pos := global_position
		if is_instance_valid(sera):
			PSpells.hit_circle(sera, pos, R * 2.3, dmg, fox, {}, {"heavy": true, "launch": 3.0})
		var b := SunBurst.new()
		b.fox = fox
		b.size = R
		b.floor_dy = (floor_y - pos.y) if floor_y < INF else R
		PVfx.add(b, pos, true)
		PVfx.sparks(pos, 34, pal[1], 380.0, 0.55)
		PVfx.sparks(pos, 16, pal[0], 240.0, 0.4, Vector2.UP, 50.0)
		PVfx.embers(pos, 26, fox, 200.0, Vector2(R * 0.8, R * 0.6))
		PVfx.smoke(pos + Vector2(0, -R * 0.4), 9, R * 0.9)
		Fx.hitstop(0.09)
		Fx.shake(0.5, 0.45)
		Fx.zoom_punch(0.05)
		Fx.flash(Color(pal[1], 0.18), 0.14)
		Sfx.play(&"explode", -1.0)
		Sfx.play_pitch(&"blast", 0.7, -4.0)
		if awake and is_instance_valid(sera):
			for i in 5:
				var f := Fireball.new()
				f.sera = sera
				f.fox = fox
				f.small = true
				f.dmg = dmg
				f.scale_k = 1.0 * (1.25 if fox else 1.0)
				var ang := -PI / 2.0 + (float(i) - 2.0) * 0.45
				f.vel = Vector2(cos(ang) * 1.6 + dir * 0.4, sin(ang)).normalized() * 240.0
				PVfx.add(f, pos, true)

	# ── 굴러간 바닥의 그을음 (몸통과 같은 일반 합성 층, 맨 먼저 그림 — 층을 따로 두지 않아 그리기 호출 1번 절약) ──
	func _draw_scorch(c: PDraw) -> void:
		if floor_y == INF:
			return
		var fy := floor_y - global_position.y
		for tr: Array in _trail:
			var age := t - float(tr[1])
			var a := 1.0 - age / TRAIL_LIFE
			c.draw_set_transform(Vector2(float(tr[0]) - global_position.x, fy + 0.5), 0.0, Vector2(1.0, 0.22))
			c.draw_circle(Vector2.ZERO, 9.0 * float(tr[2]), Color(0.05, 0.02, 0.02, 0.45 * a))
		c.draw_set_transform(Vector2.ZERO)

	# ── 가산 합성: 빛무리 · 바닥에 비치는 불빛 · 바닥의 불 ──
	func _draw_halo(c: PDraw) -> void:
		var pal := PSpells._pal(fox)
		var fy := floor_y - global_position.y
		if floor_y < INF:
			for tr: Array in _trail:
				var age := t - float(tr[1])
				var a := 1.0 - age / TRAIL_LIFE
				var x := float(tr[0]) - global_position.x
				var h := 12.0 * float(tr[2]) * a * (0.8 + 0.3 * sin(t * 22.0 + x))
				PVfx.spike(c, Vector2(x, fy), Vector2(sin(t * 9.0 + x) * 0.25, -1.0), h, 7.0 * a, Color(pal[2], 0.7 * a))
				PVfx.spike(c, Vector2(x, fy), Vector2(sin(t * 11.0 + x) * 0.2, -1.0), h * 0.55, 3.5 * a, Color(pal[1], 0.9 * a))
		if _done:
			return
		var r := R * _grow()
		if r < 0.5:
			return
		if floor_y < INF:
			c.draw_set_transform(Vector2(0, fy), 0.0, Vector2(1.0, 0.2))
			c.glow(Vector2.ZERO, r * 3.2, Color(pal[2], 0.5))
			c.draw_set_transform(Vector2.ZERO)
		c.glow(Vector2.ZERO, r * 2.8, Color(pal[2], 0.35))
		c.glow(Vector2.ZERO, r * 1.6, Color(pal[1], 0.3))

	func _paint() -> void:
		var pal := PSpells._pal(fox)
		_draw_scorch(pd)
		if _done:
			return
		var g := _grow()
		var r := R * g
		if r < 0.5:
			return
		# 둘레 불꽃(코로나): 두 겹 불 혀가 위·뒤로 일렁임 (열기는 위로, 구르면 뒤로 날림)
		var drift := Vector2(-dir * 0.45, -0.7)
		for layer in 2:
			var n := 22 if layer == 0 else 16
			for i in n:
				var ang := float(i) / float(n) * TAU + _spin * 0.25 + float(layer) * 0.2
				var d := Vector2(cos(ang), sin(ang))
				var up := maxf(d.dot(drift.normalized()), 0.0)
				var flick := 0.75 + 0.35 * sin(t * (17.0 + i) + i * 2.3)
				var L := r * (0.32 + 0.55 * up) * flick * (1.0 if layer == 0 else 0.6)
				var base := d * r * 0.9
				var tip := d * (r * 0.9 + L) + drift * L * 0.7
				var w := r * TAU / float(n) * (0.75 if layer == 0 else 0.55)
				var col: Color = Color(pal[3].lerp(pal[2], 0.35), 0.9) if layer == 0 else Color(pal[2].lerp(pal[1], 0.5), 0.92)
				pd.convex(PackedVector2Array([base + d.orthogonal() * w * 0.5, tip, base - d.orthogonal() * w * 0.5]), col)
		# 몸통: 짙은 테두리 → 주황 → 노랑 → 흰 중심 (둥근 그라데이션)
		pd.draw_circle(Vector2.ZERO, r * 1.03, pal[3])
		pd.draw_circle(Vector2.ZERO, r * 0.97, pal[2])
		pd.ring_grad(Vector2.ZERO, Vector2(r, r) * 0.55, Vector2(r, r) * 0.98, pal[1], Color(pal[3].lerp(pal[2], 0.5), 1.0), 36)
		pd.draw_circle(Vector2.ZERO, r * 0.56, pal[1])
		# 구르는 표면의 불 소용돌이 (도는 것이 보이게)
		for i in 3:
			var a0 := _spin + float(i) * TAU / 3.0
			PVfx.crescent(pd, Vector2.ZERO, r * 0.86, a0, a0 + 1.3, r * 0.2, Color(pal[0], 0.45), 12)
		for i in 2:
			var a0 := -_spin * 1.4 + float(i) * PI
			PVfx.crescent(pd, Vector2.ZERO, r * 0.5, a0, a0 + 1.6, r * 0.14, Color(pal[2], 0.5), 10)
		# 중심 (맥동)
		var pulse := 1.0 + 0.06 * sin(t * 18.0)
		pd.glow(Vector2.ZERO, r * 0.7 * pulse, Color(pal[0], 0.9))
		pd.draw_circle(Vector2.ZERO, r * 0.26 * pulse, Color(1, 1, 1, 0.95))
		# 홍염(프로미넌스): 표면 밖으로 휘어 나왔다 들어가는 불 고리 둘
		for i in 2:
			var c0 := float(i) * PI + t * 0.8
			var pc := Vector2(cos(c0), sin(c0)) * r * 1.02
			PVfx.crescent(pd, pc, r * 0.32, c0 - 1.6, c0 + 1.6, r * 0.07, Color(pal[1], 0.7), 10)
		# 열기 테두리
		pd.draw_arc(Vector2.ZERO, r * 1.12, 0, TAU, 36, Color(pal[0], 0.16), 2.0)
		# 앞으로 나가는 쪽의 밝은 테두리
		var fa := 0.0 if dir > 0 else PI
		PVfx.crescent(pd, Vector2.ZERO, r * 1.04, fa - 1.1, fa + 1.1, r * 0.12, Color(pal[0], 0.5), 14)


## 태양 폭발: 섬광 → 부풀어 오르는 불 돔 → 위로 솟는 불기둥 · 바닥을 따라 퍼지는 불 고리 · 사방 빛살 · 두 겹 충격파.
class SunBurst extends PVfx.Base:
	var size := 30.0
	var floor_dy := 30.0 ## 중심에서 바닥까지
	var _chunks: Array = [] ## [각도, 속도, 크기]
	var _rays: Array = []

	func _init() -> void:
		life = 0.85
		z_index = 8
		for i in 18:
			_chunks.append([randf() * TAU, randf_range(0.8, 1.4), randf_range(0.6, 1.3)])
		for i in 12:
			_rays.append([float(i) / 12.0 * TAU + randf_range(-0.12, 0.12), randf_range(0.8, 1.3)])

	var _fire: NormalLayer

	func _ready() -> void:
		# 일반 합성 층: 진한 붉은·주황 불 돔과 불 혀 (가산 빛만으로는 하얗게 타 버려서)
		_fire = NormalLayer.new()
		_fire.fn = _draw_fire
		_fire.z_index = -1
		add_child(_fire)

	func _tick(_d: float) -> void:
		_fire.queue_redraw()

	func _draw_fire(c: PDraw) -> void:
		var kk := k()
		var a := clampf(1.0 - (kk - 0.35) / 0.65, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - kk, 3.0)
		var pal := PSpells._pal(fox)
		var S := size
		var rr := S * (1.0 + 1.4 * e)
		# 둘레 불 혀 (위로 치솟음)
		for i in 20:
			var ang := float(i) / 20.0 * TAU
			var d := Vector2(cos(ang), sin(ang))
			var up := maxf(-d.y, 0.0)
			var L := rr * (0.35 + 0.7 * up) * (0.8 + 0.3 * sin(t * 30.0 + i * 1.7))
			PVfx.spike(c, d * rr * 0.85, (d + Vector2(0, -0.6)).normalized(), L, rr * 0.45, Color(pal[3], 0.85 * a))
		c.draw_circle(Vector2.ZERO, rr, Color(pal[3], 0.9 * a))
		c.draw_circle(Vector2(0, -rr * 0.08), rr * 0.82, Color(pal[2], 0.9 * a))
		c.draw_circle(Vector2(0, -rr * 0.12), rr * 0.55, Color(pal[1], 0.9 * a))

	func _paint() -> void:
		var kk := k()
		var a := 1.0 - kk
		var e := 1.0 - pow(1.0 - kk, 3.0)
		var pal := PSpells._pal(fox)
		var S := size
		pd.glow(Vector2.ZERO, S * 5.0 * (0.5 + 0.6 * e), Color(pal[2], 0.35 * a * a))
		# 바닥을 따라 퍼지는 납작한 불 고리
		pd.draw_set_transform(Vector2(0, floor_dy), 0.0, Vector2(1.0, 0.18))
		var fr := S * (0.8 + 4.0 * e)
		pd.ring_grad(Vector2.ZERO, Vector2(fr, fr) * 0.8, Vector2(fr, fr), Color(pal[1], 0.0), Color(pal[1], 0.8 * a), 40)
		pd.glow(Vector2.ZERO, fr, Color(pal[2], 0.45 * a))
		pd.draw_set_transform(Vector2.ZERO)
		# 위로 솟는 불기둥 (버섯처럼 위가 넓어짐)
		var ch := S * (1.0 + 3.5 * e)
		pd.convex(PackedVector2Array([Vector2(-S * 0.5, 0), Vector2(-S * (0.4 + 0.5 * e), -ch * 0.8), Vector2(0, -ch), Vector2(S * (0.4 + 0.5 * e), -ch * 0.8), Vector2(S * 0.5, 0)]), Color(pal[2], 0.35 * a))
		pd.glow(Vector2(0, -ch * 0.85), S * (0.8 + 0.9 * e), Color(pal[1], 0.4 * a))
		# 불 돔
		pd.draw_circle(Vector2.ZERO, S * (1.0 + 1.3 * e) * (1.0 - kk * 0.4), Color(pal[2], 0.2 * a))
		pd.draw_circle(Vector2.ZERO, S * (0.8 + 0.9 * e) * (1.0 - kk * 0.6), Color(pal[1], 0.2 * a))
		pd.draw_circle(Vector2.ZERO, S * 0.6 * (1.0 - kk), Color(pal[0], 0.5 * a))
		if kk < 0.1:
			pd.draw_circle(Vector2.ZERO, S * (0.8 + kk * 4.0), Color(pal[0], 0.55 * (1.0 - kk / 0.1)))
		# 사방 빛살
		var ra := clampf(1.0 - kk * 2.2, 0.0, 1.0)
		if ra > 0.0:
			for ry: Array in _rays:
				var d := Vector2(cos(float(ry[0])), sin(float(ry[0])))
				PVfx.blade(pd, d * S * 0.6, d * S * (1.5 + 2.6 * e) * float(ry[1]), S * 0.22 * ra, Color(pal[0], 0.85 * ra), 0.0)
		# 날아가는 불 조각
		for cnk: Array in _chunks:
			var d := Vector2(cos(float(cnk[0])), sin(float(cnk[0])))
			var p := d * S * (0.8 + 2.8 * e * float(cnk[1])) + Vector2(0, 30.0 * kk * kk)
			PVfx.crescent(pd, p, S * 0.18 * float(cnk[2]) + 1.0, float(cnk[0]) - 1.2, float(cnk[0]) + 1.2, 3.0 * a + 0.5, Color(pal[1], a), 8)
		# 두 겹 충격파
		for j in 2:
			var sw := 1.0 - pow(1.0 - clampf(kk * 2.2 - j * 0.25, 0.0, 1.0), 2.0)
			if sw <= 0.0:
				continue
			pd.draw_arc(Vector2.ZERO, S * (1.0 + 3.6 * sw), 0, TAU, 44, Color(pal[0] if j == 0 else pal[1], 0.85 * (1.0 - sw)), 4.0 * (1.0 - sw) + 0.5)


## 작은 불덩이: 각성 태양이 터질 때 부채꼴로 튀는 조각 (닿거나 잠깐 날면 터짐)
class Fireball extends PDraw.Canvas:
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
	var _floor_y := INF ## 아래 바닥 높이 (바닥에 비치는 불빛)

	func _ready() -> void:
		z_index = 6
		if vel == Vector2.ZERO:
			vel = Vector2(dir * 330.0, 0)
		var q := PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 80), 1)
		var hit := get_world_2d().direct_space_state.intersect_ray(q)
		if hit:
			_floor_y = hit.position.y

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
		PVfx.sparks(global_position, 10 if not small else 4, pal[1], 220.0, 0.35)
		PVfx.smoke(global_position, 4 if not small else 2, rad * 0.4)
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

	func _paint() -> void:
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
			PVfx.safe_poly(pd, pts, col)
		# 몸통: 바깥 짙은 불 → 밝은 → 흰 중심 (일렁임)
		var pulse := 1.0 + 0.08 * sin(t * 40.0)
		pd.draw_circle(Vector2.ZERO, 8.5 * s * pulse, Color(pal[2], 0.9))
		pd.draw_circle(back * -1.0, 6.6 * s, pal[1])
		pd.draw_circle(back * -1.6, 4.2 * s * pulse, pal[0])
		# 부드러운 빛무리
		pd.glow(Vector2.ZERO, 24.0 * s, Color(pal[2], 0.32))
		# 바닥에 비치는 불빛 (가까울수록 진하게)
		var dy := _floor_y - global_position.y
		if dy < 80.0:
			var k := 1.0 - dy / 80.0
			pd.draw_set_transform(Vector2(0, dy), 0.0, Vector2(1.0, 0.22))
			pd.glow(Vector2.ZERO, 34.0 * s, Color(pal[2], 0.35 * k))
			pd.draw_set_transform(Vector2.ZERO)


## 불 조각 고리 폭발 (참고: 파이어볼 위 그림)
class Explosion extends PVfx.Base:
	var size := 26.0
	var _shards: Array = []

	func _init() -> void:
		life = 0.42
		z_index = 7
		for i in 14:
			_shards.append([randf() * TAU, randf_range(0.7, 1.15), randf_range(0.6, 1.4)])

	func _paint() -> void:
		var kk := k()
		var pal := PSpells._pal(fox)
		var R := size * (0.5 + kk * 0.8)
		var a := 1.0 - kk
		# 큰 빛무리 + 중심 섬광
		pd.glow(Vector2.ZERO, size * 2.4 * (0.6 + kk * 0.6), Color(pal[2], 0.45 * a * a))
		pd.draw_circle(Vector2.ZERO, size * 0.8 * (1.0 - kk * 0.5), Color(pal[1], 0.7 * a))
		pd.draw_circle(Vector2.ZERO, size * 0.5 * (1.0 - kk), Color(pal[0], a))
		# 충격파 고리 (빠르게 퍼짐)
		var sw := 1.0 - pow(1.0 - minf(kk * 2.5, 1.0), 2.0)
		pd.draw_arc(Vector2.ZERO, size * (0.4 + 1.3 * sw), 0, TAU, 32, Color(pal[0], 0.8 * (1.0 - sw)), 3.0 * (1.0 - sw) + 0.5)
		# 고리 모양으로 흩어지는 불 조각(초승달 조각)
		for sh: Array in _shards:
			var ang := float(sh[0]) + kk * 0.6
			var rr := R * float(sh[1])
			PVfx.crescent(pd, Vector2.ZERO, rr, ang, ang + 0.45 * float(sh[2]), 4.0 * a + 1.0, Color(pal[2], a))
		pd.draw_arc(Vector2.ZERO, R * 1.05, 0, TAU, 28, Color(pal[1], 0.6 * a), 1.5)


# ═══════════════════════════════════════════════════════════
# 2. 불비 / 여우비 (일반마법) — 하늘로 불덩이를 던져 올리면 터지며 앞쪽에 불비가 쏟아진다.
#    평소 = 붉은·주황 불비, 변신 중 = 푸른 여우비(하늘에 여우 얼굴 문양, 각성 땐 불여우가 뛰어내림)
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
	fr.launch = sera.global_position + Vector2(sera.facing * 3, -36) - Vector2(cx, sera.global_position.y)
	PVfx.add(fr, Vector2(cx, sera.global_position.y), true)
	# 머리 위로 던져 올리는 동작 (기본공격 위 던지기 자세)
	sera._atk_aim = -1
	sera.art.atk_step = 0
	sera.art.atk_k = 0.0
	var mz := PShot.Muzzle.new()
	mz.dir = Vector2.UP
	mz.fox = fr.fox_form
	mz.size = 1.3
	PVfx.add(mz, sera.global_position + Vector2(sera.facing * 3, -36), true)
	Sfx.play_pitch(&"whoosh", 1.2, -6.0)
	Sfx.play(&"fox_rain", -2.0)


## 불비 (참고: 박일표의 여우비) — 하늘에서 비스듬히 꽂히는 날카로운 빛 바늘 + 흘러내리는 불꽃 리본.
## 평소 = 붉은·주황 리본, 변신 중 = 푸른 리본 + 하늘의 여우 얼굴 문양.
class FoxRainFx extends PDraw.Canvas:
	var sera: PSera
	var fox_form := false
	var launch := Vector2(0, -36) ## 던져 올린 손 자리 (이 노드 기준)
	var _shake_t := 0.0
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
			var ci: int = 2 if fox_form else [0, 1, 3, 1][i % 4] # 평소엔 붉은·주황 리본만
			_ribbons.append([lerpf(-width * 0.45, width * 0.45, float(i) / float(n - 1)) + randf_range(-10, 10), randf() * TAU, ci, randf_range(9.0, 14.0)])

	func _process(delta: float) -> void:
		t += delta
		if t < DUR:
			if t < 0.14:
				pass # 던져 올린 불덩이가 하늘에 닿기 전
			else:
				_spawn += delta * (60.0 if fox_form else 46.0)
			while _spawn >= 1.0:
				_spawn -= 1.0
				var a := randf_range(0.22, 0.5)
				var dir := Vector2(face * sin(a), cos(a))
				var x := randf_range(-width / 2, width / 2) + dir.x / dir.y * TOP
				needles.append([Vector2(x, TOP + randf_range(-30, 0)), dir * randf_range(760, 900), randf_range(24, 40), -1.0])
			if t >= 0.14 and t - delta < 0.14:
				# 하늘에서 터짐
				PVfx.sparks(global_position + Vector2(launch.x * 0.3, TOP + 30.0), 18, PData.FOX_HOT if fox_form else PData.FIRE_HOT, 200.0, 0.4)
				Fx.shake(0.08, 0.12)
				Sfx.play_pitch(&"explode", 1.4, -10.0)
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
					PVfx.sparks(global_position + p, 3, PData.FOX_HOT if fox_form else PData.FIRE_HOT, 90.0, 0.2)
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
				PVfx.sparks(global_position + Vector2(f[0], -2), 6, PData.FOX_HOT if fox_form else PData.FIRE_HOT, 90.0, 0.3)
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
					d.take_hit(int(dmg), global_position + Vector2(0, -100), {"fox": fox_form})
					if t >= _shake_t: # 맞는 동안 잘게 떨림 (프레임마다는 아님)
						_shake_t = t + 0.16
						Fx.shake(0.05, 0.08)
				for f: Array in foxes:
					if not f[3] and r.has_point(global_position + Vector2(f[0], f[1])):
						f[3] = true
						d.take_hit(int(dmg * 3.0), global_position + Vector2(f[0], f[1]), {"fox": fox_form, "heavy": true})
						Fx.shake(0.1, 0.1)
		if t > DUR + 0.6 and needles.is_empty() and foxes.is_empty():
			queue_free()
		queue_redraw()
		_solid.queue_redraw()

	## 리본: 위에서 쏟아져 내려와 흐르다 위로 걷힘. 가장자리는 뾰족한 불 혀
	func _draw_ribbons(c: PDraw) -> void:
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

	func _paint() -> void:
		var core := Color(0.8, 0.95, 1.0) if fox_form else Color(1.0, 0.9, 0.55)
		var glow := Color(PData.FOX_MID, 0.35) if fox_form else Color(1.0, 0.45, 0.15, 0.4)
		var pal := PSpells._pal(fox_form)
		# 던져 올린 불덩이: 손에서 하늘로 (0~0.14초), 하늘에서 터지는 빛 (0.14~0.5초)
		var top := Vector2(launch.x * 0.3, TOP + 30.0)
		if t < 0.14:
			var p := launch.lerp(top, t / 0.14)
			pd.line2(launch.lerp(top, maxf(t / 0.14 - 0.35, 0.0)), p, Color(pal[2], 0.0), Color(pal[1], 0.9), 1.0, 6.0)
			pd.glow(p, 16.0, Color(pal[1], 0.7))
			pd.draw_circle(p, 5.0, pal[0])
		var sk := clampf((t - 0.14) / 0.4, 0.0, 1.0)
		if t >= 0.14 and sk < 1.0:
			var a := 1.0 - sk
			pd.glow(top, 30.0 + 90.0 * sk, Color(pal[2], 0.45 * a))
			pd.draw_arc(top, 10.0 + 70.0 * sk, 0, TAU, 32, Color(pal[0], 0.8 * a), 3.0 * a + 0.5)
			if fox_form:
				_draw_fox_sigil(top, 1.0 + sk * 0.4, a)
		for nd: Array in needles:
			var p: Vector2 = nd[0]
			var v: Vector2 = nd[1]
			var dir := v.normalized()
			var l: float = nd[2]
			var a := 1.0 if float(nd[3]) < 0.0 else 1.0 - float(nd[3]) / 0.3
			var back := p - dir * l
			var n := dir.orthogonal()
			if float(nd[3]) < 0.0:
				pd.draw_line(back - dir * 26.0, back, Color(glow, 0.18), 1.0) # 빠르게 나는 자국
			pd.draw_line(back, p, Color(glow, glow.a * a), 4.0)
			# 날카로운 바늘: 뒤쪽이 넓고 끝이 뾰족한 가는 삼각형
			PVfx.safe_poly(pd, PackedVector2Array([back + n * 3.0, p, back - n * 3.0, back - dir * 4.0]), Color(core, a))
			pd.draw_line(back.lerp(p, 0.2), p, Color(1, 1, 1, a), 1.0)
		for f: Array in foxes:
			_draw_fox(Vector2(f[0], f[1]))

	## 하늘의 여우 얼굴 문양 (여우비: 큰 귀 둘 · 갸름한 얼굴 · 치켜뜬 눈)
	func _draw_fox_sigil(c: Vector2, s: float, a: float) -> void:
		var col := Color(PData.FOX_HOT, 0.7 * a)
		var face := PackedVector2Array([c + Vector2(-26, -8) * s, c + Vector2(-34, -40) * s, c + Vector2(-12, -18) * s, c + Vector2(12, -18) * s,
			c + Vector2(34, -40) * s, c + Vector2(26, -8) * s, c + Vector2(14, 12) * s, c + Vector2(0, 24) * s, c + Vector2(-14, 12) * s, c + Vector2(-26, -8) * s])
		pd.draw_polyline(face, col, 2.0)
		for side in [-1.0, 1.0]:
			var e := c + Vector2(side * 11, -2) * s
			pd.draw_line(e + Vector2(-side * 6, 2) * s, e + Vector2(side * 6, -3) * s, Color(PData.FOX_CORE, 0.9 * a), 2.0)

	func _draw_fox(p: Vector2) -> void:
		if not fox_form:
			# 평소: 뛰어내리는 여우 대신 길쭉한 불방울
			pd.glow(p + Vector2(0, -6), 10.0, Color(PData.FIRE_MID, 0.5))
			PVfx.spike(pd, p + Vector2(0, -4), Vector2.UP, 16.0, 7.0, Color(PData.FIRE_HOT, 0.85))
			pd.draw_circle(p + Vector2(0, -3), 3.2, PData.FIRE_CORE)
			return
		# 뛰어내리는 작은 불여우 (머리 아래)
		var c := Color(PData.FOX_HOT, 0.85)
		PVfx.safe_poly(pd, PackedVector2Array([p + Vector2(-3, -10), p + Vector2(3, -10), p + Vector2(4, -2), p + Vector2(0, 2), p + Vector2(-4, -2)]), c)
		PVfx.safe_poly(pd, PackedVector2Array([p + Vector2(-3, -1), p + Vector2(-5, 3), p + Vector2(-1, 0)]), c)
		PVfx.safe_poly(pd, PackedVector2Array([p + Vector2(3, -1), p + Vector2(5, 3), p + Vector2(1, 0)]), c)
		PVfx.safe_poly(pd, PackedVector2Array([p + Vector2(-2, -10), p + Vector2(0, -20), p + Vector2(2, -10)]), Color(PData.FOX_MID, 0.6))
		pd.draw_circle(p + Vector2(0, -4), 1.2, PData.FOX_CORE)


# ═══════════════════════════════════════════════════════════
# 3. 압축 열선 (고급마법) — 누를수록 굵어지는 레이저, 나선 화염 고리
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


class Laser extends PDraw.Canvas:
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

	func _paint() -> void:
		var pal := PSpells._pal(fox)
		var on := t < dur
		var a := 1.0 if on else clampf(1.0 - (t - dur) / 0.25, 0.0, 1.0)
		var grow := clampf(t / 0.08, 0.0, 1.0)
		var th := thick * (0.6 + 0.4 * grow) * (1.0 + 0.08 * sin(t * 60.0)) * a
		var L := length * grow
		pd.draw_set_transform(Vector2.ZERO, 0.0 if dir > 0 else PI, Vector2.ONE)
		# 위아래로 번지는 부드러운 빛 → 주황 → 노랑 → 흰 중심
		pd.rect_grad(Rect2(0, -th * 2.4, L, th * 1.5), Color(pal[2], 0.0), Color(pal[2], 0.3 * a))
		pd.rect_grad(Rect2(0, th * 0.9, L, th * 1.5), Color(pal[2], 0.3 * a), Color(pal[2], 0.0))
		pd.draw_rect(Rect2(0, -th * 0.9, L, th * 1.8), Color(pal[2], 0.25 * a))
		pd.draw_rect(Rect2(0, -th * 0.55, L, th * 1.1), Color(pal[2], 0.8 * a))
		pd.draw_rect(Rect2(0, -th * 0.35, L, th * 0.7), Color(pal[1], 0.95 * a))
		pd.draw_rect(Rect2(0, -th * 0.16, L, th * 0.32), Color(pal[0], a))
		# 나선 화염 고리 (빛줄기를 감아 도는 두 가닥)
		var pitch := 26.0
		var n := int(L / pitch * 2.0)
		for i in n:
			var x := fmod(float(i) * pitch * 0.5 + t * 420.0, L)
			var ph := x * 0.24 - t * 18.0
			var ry := th * 0.95
			var rx := th * 0.35
			pd.draw_set_transform(Vector2(x, 0) if dir > 0 else Vector2(-x, 0), 0.0 if dir > 0 else PI, Vector2.ONE)
			pd.draw_arc(Vector2.ZERO, ry, ph, ph + 1.6, 10, Color(pal[1], 0.85 * a), 1.6)
			pd.draw_set_transform(Vector2.ZERO, 0.0 if dir > 0 else PI, Vector2.ONE)
		for i in 2:
			var pts := PackedVector2Array()
			for s in 40:
				var x := L * float(s) / 39.0
				pts.append(Vector2(x, sin(x * 0.12 - t * 30.0 + i * PI) * th * 0.85))
			pd.draw_polyline(pts, Color(pal[1], 0.7 * a), 1.5)
		# 손끝 충격파
		var mz := 6.0 + th * 0.9
		pd.draw_circle(Vector2.ZERO, mz, Color(pal[1], 0.8 * a))
		pd.draw_circle(Vector2.ZERO, mz * 0.55, Color(pal[0], a))
		for i in 6:
			var ang := float(i) / 6.0 * TAU + t * 10.0
			PVfx.spike(pd, Vector2.ZERO, Vector2(cos(ang), sin(ang)), mz * 1.8, 3.0, Color(pal[0], 0.7 * a))
		pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# 각성: 바닥에 남는 불길
		for tr: Array in _trail:
			if tr[1] < 1.5:
				var fa: float = 1.0 - tr[1] / 1.5
				var y: float = tr[2] - global_position.y
				for i in 18:
					var x := float(i) * 30.0 * float(dir)
					var hh := 6.0 + 4.0 * sin(t * 20.0 + i)
					PVfx.safe_poly(pd, PackedVector2Array([Vector2(x - 6, y), Vector2(x, y - hh), Vector2(x + 6, y)]), Color(pal[2], 0.7 * fa))
				break


# ═══════════════════════════════════════════════════════════
# 4. 대유성 (고급마법) — 세라 뒤쪽 하늘에서 거대한 운석 한 방이 보는 방향 앞 땅에 떨어져 화면 앞쪽 절반을 덮는 폭발
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


class Meteor extends PDraw.Canvas:
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
	func _draw_solid(c: PDraw) -> void:
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
		# 그을린 자국 (천천히 사라짐)
		if t >= IMPACT:
			var sa := clampf(1.0 - (t - IMPACT - 0.9) / 0.6, 0.0, 1.0)
			c.draw_set_transform(_land + Vector2(0, 1), 0.0, Vector2(1.0, 0.16))
			c.glow(Vector2.ZERO, BLAST * 0.6, Color(0.04, 0.02, 0.03, 0.85 * sa), 0.0)
			c.draw_set_transform(Vector2.ZERO)

	func _paint() -> void:
		var pal := PSpells._pal(fox)
		# ① 세라 뒤쪽 하늘의 마법진 (운석이 빠져나오는 문)
		var ca := clampf(t / 0.2, 0.0, 1.0) * clampf((IMPACT + 0.1 - t) / 0.3, 0.0, 1.0)
		if ca > 0.0:
			pd.draw_set_transform(_start + Vector2(0, 30), 0.0, Vector2(1.0, 0.45))
			for i in 3:
				var r := 54.0 + i * 18.0
				var sp := t * (1.2 - i * 0.3) * (1 if i % 2 == 0 else -1)
				pd.draw_arc(Vector2.ZERO, r, sp, sp + TAU, 40, Color(pal[1], 0.8 * ca), 2.0)
			for i in 10:
				var a := float(i) / 10.0 * TAU - t
				PVfx.spike(pd, Vector2(cos(a), sin(a)) * 74.0, Vector2(cos(a), sin(a)), 12.0, 4.0, Color(pal[0], 0.8 * ca))
			pd.draw_circle(Vector2.ZERO, 50.0, Color(pal[2], 0.2 * ca))
			pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# ② 떨어지는 거대 운석 + 불타는 긴 꼬리
		if t >= SIGIL and t < IMPACT:
			var p := _pos()
			var dir := (_land - _start).normalized()
			var side := dir.orthogonal()
			var fl := sin(t * 30.0) * 6.0
			PVfx.safe_poly(pd, PackedVector2Array([p + side * R * 1.25, p - dir * R * 4.2 + side * (R * 0.5 + fl), p - dir * R * 5.2, p - dir * R * 4.2 - side * (R * 0.5 - fl), p - side * R * 1.25]), Color(pal[3], 0.55))
			PVfx.safe_poly(pd, PackedVector2Array([p + side * R * 1.0, p - dir * R * 3.2 + side * R * 0.3, p - dir * R * 3.8, p - dir * R * 3.2 - side * R * 0.3, p - side * R * 1.0]), Color(pal[2], 0.75))
			PVfx.safe_poly(pd, PackedVector2Array([p + side * R * 0.7, p - dir * R * 2.2, p - side * R * 0.7]), Color(pal[1], 0.9))
			pd.draw_circle(p, R * 1.45, Color(pal[2], 0.22))
			pd.draw_circle(p, R * 1.12, Color(pal[1], 0.35))
			# 바위 테두리의 달아오른 금 (일반 합성 바위 위로 비침)
			for i in 6:
				var a := float(i) / 6.0 * TAU + t * 2.0
				var q := p + Vector2(cos(a), sin(a)) * R * 0.5
				pd.draw_line(q, q + Vector2(cos(a + 0.6), sin(a + 0.6)) * R * 0.45, Color(pal[1], 0.9), 2.0)
			pd.draw_arc(p, R * 0.98, 0, TAU, 32, Color(pal[0], 0.8), 2.0)
			# 앞쪽 공기가 달아오르는 충격파 고깔
			pd.draw_arc(p + dir * R * 0.4, R * 1.2, dir.angle() - 1.1, dir.angle() + 1.1, 16, Color(pal[0], 0.6), 3.0)
		# ③ 폭발: 앞쪽 절반을 덮는 불의 돔 + 불기둥 + 충격파 고리
		if t >= IMPACT:
			var age := t - IMPACT
			var kk := clampf(age / 1.3, 0.0, 1.0)
			var a := 1.0 - kk
			pd.glow(_land + Vector2(0, -30), BLAST * 1.9, Color(pal[2], 0.3 * a))
			# 땅에 갈라진 불빛 금 (그을린 자국 위)
			var crack_a := clampf(1.0 - (age - 0.9) / 0.6, 0.0, 1.0)
			for i in 9:
				var ang := float(i) / 9.0 * TAU + 0.3
				var d := Vector2(cos(ang), sin(ang) * 0.16)
				var l := BLAST * (0.35 + 0.2 * sin(i * 3.1))
				pd.line2(_land + d * 8.0, _land + d * l, Color(pal[1], 0.9 * crack_a), Color(pal[2], 0.0), 2.0, 0.5)
			var grow := 1.0 - pow(1.0 - minf(age / 0.25, 1.0), 3.0)
			var rad := BLAST * grow
			pd.draw_circle(_land + Vector2(0, -rad * 0.25), rad * 1.05, Color(pal[3], 0.45 * a))
			pd.draw_circle(_land + Vector2(0, -rad * 0.25), rad * 0.8, Color(pal[2], 0.55 * a))
			pd.draw_circle(_land + Vector2(0, -rad * 0.3), rad * 0.5 * (1.0 - kk * 0.5), Color(pal[1], 0.85 * a))
			pd.draw_circle(_land + Vector2(0, -rad * 0.3), rad * 0.25 * (1.0 - kk), Color(pal[0], a))
			var h := BLAST * 1.6 * minf(age * 4.0, 1.0)
			PVfx.safe_poly(pd, PackedVector2Array([_land + Vector2(-50, 0), _land + Vector2(-18, -h), _land + Vector2(0, -h * 1.12), _land + Vector2(18, -h), _land + Vector2(50, 0)]), Color(pal[1], 0.75 * a))
			PVfx.safe_poly(pd, PackedVector2Array([_land + Vector2(-20, 0), _land + Vector2(0, -h), _land + Vector2(20, 0)]), Color(pal[0], 0.9 * a))
			for i in 3:
				var rr := BLAST * (0.4 + kk * (1.1 + i * 0.25))
				pd.draw_set_transform(_land + Vector2(0, -4), 0.0, Vector2(1.0, 0.22))
				pd.draw_arc(Vector2.ZERO, rr, 0, TAU, 40, Color(pal[1], 0.8 * a * (1.0 - i * 0.25)), 3.0)
				pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			for i in 14:
				var ang := -PI + float(i) / 13.0 * PI
				var d := Vector2(cos(ang), sin(ang))
				PVfx.spike(pd, _land + d * rad * 0.6, d, rad * 0.5 * a, 6.0 * a + 1.0, Color(pal[1], 0.8 * a))
		for d: Array in debris:
			pd.draw_rect(Rect2(d[0], Vector2(2, 2)), Color(pal[1], 1.0 - float(d[2]) / 1.2))
		# 각성: 앞쪽 땅에 남는 불바다
		if _fire_sea > 0.0:
			var fa := minf(_fire_sea, 1.0)
			var fr := _front_rect(0.0)
			for i in int(fr.size.x / 14.0):
				var x := fr.position.x + i * 14.0
				var hh := 10.0 + 7.0 * sin(t * 14.0 + i * 1.7)
				PVfx.safe_poly(pd, PackedVector2Array([Vector2(x, ground_y), Vector2(x + 7, ground_y - hh), Vector2(x + 14, ground_y)]), Color(pal[2], 0.75 * fa))
				PVfx.safe_poly(pd, PackedVector2Array([Vector2(x + 4, ground_y), Vector2(x + 7, ground_y - hh * 0.5), Vector2(x + 10, ground_y)]), Color(pal[1], 0.9 * fa))


# ═══════════════════════════════════════════════════════════
# 5. 불사조 (대마법) — 화면을 찢으며 날아옴 + 부활 1회
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
class Phoenix extends PDraw.Canvas:
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
	func _draw_solid(c: PDraw) -> void:
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

	func _paint() -> void:
		var pal := PSpells._pal(fox)
		if not revive_mode:
			var a := _fade()
			# 가운데 큰 빛무리
			var cc := view.get_center() + Vector2(0, -20)
			pd.draw_circle(cc, 150.0, Color(pal[3], 0.10 * a))
			pd.draw_circle(cc, 90.0, Color(pal[2], 0.10 * a))
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
				pd.draw_polyline(PackedVector2Array([base + Vector2(-float(cr[2]), 0), tip, base + Vector2(float(cr[2]), 0)]), Color(pal[1], 0.7 * a), 1.0)
				var fl := 5.0 + sin(t * 18.0 + float(cr[0])) * 2.0
				PVfx.safe_poly(pd, PackedVector2Array([tip + Vector2(-3, 2), tip + Vector2(0, -fl * 2.0), tip + Vector2(3, 2)]), Color(pal[1], 0.8 * a))
				pd.draw_circle(tip, 2.5, Color(pal[0], 0.8 * a))
				pd.draw_circle(base + Vector2(0, -2), float(cr[2]) * 1.4, Color(pal[2], 0.18 * a))
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
			pd.draw_line(p0, p1, Color(pal[2], 0.45), w * 2.0)
			pd.draw_line(p0, p1, Color(pal[1], 0.7), w)
			pd.draw_line(p0, p1, Color(pal[0], 0.9), maxf(w * 0.3, 1.0))
			pd.draw_line(p0 + n * w, p1 + n * w, Color(pal[0], 0.8), 1.0) # 찢긴 화면 가장자리
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
		pd.draw_circle(c, r, Color(pal[3], 0.08 * a))
		pd.draw_arc(c, r, 0, TAU, 48, gold, 1.5)
		pd.draw_arc(c, r * 0.84, 0, TAU, 40, dim, 1.0)
		# 바깥 톱니
		var teeth := maxi(int(r / 3.2), 8)
		for i in teeth:
			var ang := rot + float(i) * TAU / float(teeth)
			var d := Vector2(cos(ang), sin(ang))
			var tn := d.orthogonal()
			var tw := minf(1.4, r * 0.03)
			PVfx.safe_poly(pd, PackedVector2Array([c + d * r - tn * tw, c + d * (r + 3.5) - tn * tw * 0.7, c + d * (r + 3.5) + tn * tw * 0.7, c + d * r + tn * tw]), gold)
		# 고리 사이의 룬 글자 (짧은 획 묶음)
		var runes := maxi(int(r / 4.0), 8)
		for i in runes:
			var ang := -rot * 0.7 + float(i) * TAU / float(runes)
			var d := Vector2(cos(ang), sin(ang))
			var tn := d.orthogonal()
			var m := c + d * r * 0.92
			var hsh := (i * 7 + kind * 3) % 4
			pd.draw_line(m - d * 2.0, m + d * 2.0, gold, 1.0)
			if hsh != 0:
				pd.draw_line(m + d * (2.0 - hsh), m + d * (2.0 - hsh) + tn * 2.0, gold, 1.0)
			if hsh == 2:
				pd.draw_line(m - d * 2.0, m - d * 2.0 - tn * 1.5, gold, 1.0)
		# 안쪽 별 무늬: 0 = 육망성, 1 = 오망성, 2 = 겹친 사각
		var rr := r * 0.78
		var r0 := -rot * 1.3
		if kind == 1:
			var star := PackedVector2Array()
			for j in 6:
				var ang := r0 + float((j * 2) % 5) * TAU / 5.0 - PI / 2.0
				star.append(c + Vector2(cos(ang), sin(ang)) * rr)
			pd.draw_polyline(star, dim, 1.0)
		else:
			var corners := 3 if kind == 0 else 4
			for k in 2:
				var poly := PackedVector2Array()
				for j in corners + 1:
					var ang := r0 + float(k) * PI / float(corners) + float(j) * TAU / float(corners)
					poly.append(c + Vector2(cos(ang), sin(ang)) * rr)
				pd.draw_polyline(poly, dim, 1.0)
		pd.draw_arc(c, r * 0.4, 0, TAU, 24, gold, 1.0)
		pd.draw_circle(c, r * 0.12, Color(pal[0], 0.6 * a))

	## 정면 불사조 (나타날 때): 위로 펼친 큰 날개, 흰 금빛 몸, 아래로 흘러내리는 꼬리깃
	func _draw_front(p: Vector2, s: float, a: float) -> void:
		var pal := PSpells._pal(fox)
		var flap := sin(t * 7.0) * 0.12
		pd.draw_circle(p, 60.0 * s, Color(pal[2], 0.12 * a))
		pd.draw_circle(p, 30.0 * s, Color(pal[1], 0.2 * a))
		# 꼬리깃 5가닥
		for i in 5:
			var sx := (float(i) - 2.0) * 0.5
			var sw := sin(t * 5.0 + i) * 3.0
			var tail := PackedVector2Array([Vector2(-3, 6), Vector2(sx * 10.0 - 3.0 + sw, 26), Vector2(sx * 22.0 + sw * 1.5, 48 - absf(sx) * 8.0), Vector2(sx * 10.0 + 3.0 + sw, 26), Vector2(3, 6)])
			for j in tail.size():
				tail[j] = p + tail[j] * s
			PVfx.safe_poly(pd, tail, Color(pal[2 if i % 2 == 0 else 1], 0.75 * a))
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
				PVfx.safe_poly(pd, pts, col)
		# 몸 + 머리 + 볏
		PVfx.safe_poly(pd, PackedVector2Array([p + Vector2(0, -16) * s, p + Vector2(6, -4) * s, p + Vector2(4, 12) * s, p + Vector2(0, 18) * s, p + Vector2(-4, 12) * s, p + Vector2(-6, -4) * s]), Color(pal[1], a))
		PVfx.safe_poly(pd, PackedVector2Array([p + Vector2(0, -12) * s, p + Vector2(3, -3) * s, p + Vector2(0, 10) * s, p + Vector2(-3, -3) * s]), Color(pal[0], a))
		for i in 3:
			var cx := (float(i) - 1.0) * 3.0
			PVfx.safe_poly(pd, PackedVector2Array([p + Vector2(cx - 1.5, -15) * s, p + Vector2(cx * 2.0, -27 + absf(cx)) * s, p + Vector2(cx + 1.5, -15) * s]), Color(pal[1], 0.9 * a))
		pd.draw_circle(p + Vector2(0, -14) * s, 3.5 * s, Color(pal[0], a))

	## 옆모습 불사조 (날아갈 때)
	func _draw_side(p: Vector2, rot: float, face: float, sc: float, a: float) -> void:
		var pal := PSpells._pal(fox)
		var flap := sin(t * 16.0)
		pd.draw_set_transform(p, rot, Vector2(face, 1.0) * sc)
		pd.draw_circle(Vector2.ZERO, 34.0, Color(pal[2], 0.16 * a))
		for side in [-1, 1]:
			var wing := PackedVector2Array([Vector2(4, 0), Vector2(-10, side * (-20 - flap * 10)), Vector2(-38, side * (-38 - flap * 14)),
				Vector2(-58, side * (-30 - flap * 10)), Vector2(-40, side * (-16 - flap * 4)), Vector2(-52, side * (-10 - flap * 2)), Vector2(-18, side * -4)])
			PVfx.safe_poly(pd, wing, Color(pal[2], 0.85 * a))
			var inner := PackedVector2Array([Vector2(2, 0), Vector2(-12, side * (-16 - flap * 8)), Vector2(-34, side * (-28 - flap * 11)), Vector2(-20, side * -6)])
			PVfx.safe_poly(pd, inner, Color(pal[1], 0.95 * a))
			pd.draw_polyline(PackedVector2Array([Vector2(-10, side * (-20 - flap * 10)), Vector2(-38, side * (-38 - flap * 14)), Vector2(-58, side * (-30 - flap * 10))]), Color(pal[0], a), 1.5)
		for i in 3:
			var tail := PackedVector2Array([Vector2(-10, 0), Vector2(-40 - i * 10, (i - 1) * 6 + sin(t * 9.0 + i) * 4), Vector2(-70 - i * 14, (i - 1) * 10 + sin(t * 7.0 + i) * 7), Vector2(-44 - i * 10, (i - 1) * 3)])
			PVfx.safe_poly(pd, tail, Color(pal[1 if i == 1 else 2], 0.8 * a))
		PVfx.safe_poly(pd, PackedVector2Array([Vector2(16, -2), Vector2(6, -6), Vector2(-12, -3), Vector2(-12, 3), Vector2(6, 5)]), Color(pal[1], a))
		PVfx.safe_poly(pd, PackedVector2Array([Vector2(14, -2), Vector2(6, -4), Vector2(-8, -1), Vector2(6, 3)]), Color(pal[0], a))
		PVfx.safe_poly(pd, PackedVector2Array([Vector2(16, -2), Vector2(22, 0), Vector2(16, 2)]), Color(pal[0], a))
		PVfx.safe_poly(pd, PackedVector2Array([Vector2(12, -4), Vector2(8, -12), Vector2(4, -5)]), Color(pal[0], a))
		pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## 쓰러질 때 부활 (불사조가 세라 자리에서 솟아오름, 주변을 밀쳐 냄)
static func phoenix_revive(sera: PSera) -> void:
	var awake := PState.awakened("phoenix")
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
# 6. 너울 바인드 (대마법) — 화면에 거대한 여우가 나타나 모든 적을 5초 붙잡고, 그동안 무자비한 참격을 퍼붓는다.
#    평소 = 불로 빚은 붉은 여우 정령(꼬리 셋, 온몸에서 불꽃이 피어오름, 불 밧줄로 묶음) · 변신 중 = 푸른 아홉 꼬리 여우신
# ═══════════════════════════════════════════════════════════

static func _bind(sera: PSera) -> void:
	sera.lock_cast(0.9, true)
	var b := Bind.new()
	b.sera = sera
	b.fox_form = sera.is_fox()
	b.view = _view_rect(sera)
	b.awake = PState.awakened("bind")
	b.dmg = 14.0 * _mult(sera, "bind")
	PVfx.add(b, Vector2.ZERO, true)
	Sfx.play(&"roar", -2.0)
	Sfx.play_pitch(&"ignite", 0.6, -4.0)
	Fx.flash(Color(0.5, 0.75, 1.0, 0.4) if b.fox_form else Color(1.0, 0.45, 0.15, 0.4), 0.3)
	Fx.shake(0.2, 0.4)


class Bind extends PDraw.Canvas:
	var sera: PSera
	var fox_form := false
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
					d.bind(5.0, awake, fox_form)
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
					(d as PDummy).take_hit(int(dmg * 7.0), (d as PDummy).center(), {"fox": fox_form, "heavy": true, "launch": 2.5})
			Fx.flash(Color(0.8, 0.95, 1.0, 0.7) if fox_form else Color(1.0, 0.85, 0.6, 0.7), 0.35)
			Fx.zoom_punch(0.06)
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
				(dd as PDummy).take_hit(int(dmg), q, {"fox": fox_form})
			if randf() < 0.3:
				Fx.shake(0.06, 0.06)
		if randf() < 0.5:
			Sfx.play_pitch(&"swing", randf_range(1.1, 1.5), -6.0)

	func _fade() -> float:
		return clampf(t / 0.45, 0.0, 1.0) * clampf((END - t) / 0.6, 0.0, 1.0)

	# ── 일반 합성: 어두워지는 화면 + 참격 가장자리의 먹빛 ──
	func _draw_solid(c: PDraw) -> void:
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

	func _paint() -> void:
		var pal := PSpells._pal(fox_form)
		var a := _fade()
		var appear := clampf(t / BIND_AT, 0.0, 1.0)
		var c := Vector2(view.get_center().x, view.position.y + view.size.y * 0.46)
		var s := view.size.y / 360.0 * (0.75 + 0.25 * (1.0 - pow(1.0 - appear, 3.0)))
		var fa := a * (1.0 if t < SLASH_FROM else 0.7)
		_draw_fox_god(c, s, fa, pal)
		# 붙잡는 사슬: 변신 중 = 여우불 구슬 사슬, 평소 = 꿈틀거리는 불 밧줄
		if _bound:
			var ca := clampf((t - BIND_AT) / 0.15, 0.0, 1.0) * a
			for d in _targets:
				if not is_instance_valid(d):
					continue
				var tp: Vector2 = (d as PDummy).center()
				var from := c + Vector2(0, 30) * s
				if fox_form:
					pd.draw_line(from, tp, Color(pal[1], 0.4 * ca), 2.0)
					for i in 5:
						pd.draw_circle(from.lerp(tp, float(i + 1) / 6.0), 2.2, Color(pal[0], 0.6 * ca))
				else:
					var nrm := (tp - from).orthogonal().normalized()
					var prev := from
					for i in 12:
						var f := float(i + 1) / 12.0
						var q := from.lerp(tp, f) + nrm * sin(f * 9.0 - t * 14.0) * 6.0 * sin(f * PI)
						pd.line2(prev, q, Color(pal[2], 0.7 * ca), Color(pal[1], 0.8 * ca), 3.5, 3.0)
						if i % 2 == 0:
							PVfx.spike(pd, q, Vector2(sin(t * 10.0 + i) * 0.3, -1.0), 7.0 + 3.0 * sin(t * 20.0 + i), 4.0, Color(pal[1], 0.7 * ca))
						prev = q
				pd.draw_arc(tp, 22.0 + sin(t * 8.0) * 2.0, 0, TAU, 20, Color(pal[1], 0.6 * ca), 2.0)
		# 참격: 푸른 빛 날 + 흰 심 (먹빛 가장자리는 일반 합성 층)
		for st: Array in _streaks:
			var g := _streak_k(st)
			if g.x <= 0.0:
				continue
			var p0: Vector2 = st[0]
			var p1: Vector2 = (st[0] as Vector2).lerp(st[1], g.x)
			var w: float = float(st[3]) * g.y
			PVfx.blade(pd, p0, p1, w * 1.5, Color(pal[2], 0.55))
			PVfx.blade(pd, p0, p1, w, Color(pal[1], 0.85))
			PVfx.blade(pd, p0, p1, w * 0.35, Color(pal[0], 1.0))

	## 여우신 (정면): 날개처럼 펼친 꼬리, 불꽃 갈기, 빛나는 눈, 가슴의 문양.
	## 변신 중 = 푸른 아홉 꼬리 여우신 · 평소 = 불로 빚은 붉은 여우 정령(굵은 꼬리 셋 + 온몸 가장자리에서 피어오르는 불꽃)
	func _draw_fox_god(c: Vector2, s: float, a: float, pal: Array) -> void:
		if a <= 0.01:
			return
		var nt := 9 if fox_form else 3
		var tw := 32.0 if fox_form else 46.0
		pd.draw_circle(c + Vector2(0, -20) * s, 170.0 * s, Color(pal[3], 0.12 * a))
		pd.draw_circle(c + Vector2(0, -30) * s, 90.0 * s, Color(pal[2], 0.15 * a))
		if not fox_form:
			_draw_spirit_flames(c, s, a, pal)
		# 꼬리: 몸 뒤에서 양옆·위로 부채꼴, 가운데가 통통하고 끝이 말려 올라가는 여우 꼬리 (끝은 흰 불꽃)
		for i in nt:
			var f := float(i) / float(nt - 1)
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
				var w := tw * s * sin(minf(u * 1.15, 1.0) * PI * 0.88 + 0.12)
				var n := tan.orthogonal()
				left.append(p + n * w)
				right.append(p - n * w)
				tip = p
			# 띠로 바로 그림(삼각분할 없음): 바깥 짙은 털 → 안쪽 → 끝 흰 불
			pd.strip(left, right, Color(pal[3], 0.45 * a))
			var il := PackedVector2Array()
			var ir := PackedVector2Array()
			for k in left.size():
				il.append(root.lerp(left[k], 0.9))
				ir.append(root.lerp(right[k], 0.9))
			pd.strip_grad(il, ir, Color(pal[2], 0.3 * a), Color(pal[1], 0.5 * a))
			pd.glow(tip, 16.0 * s, Color(pal[1], 0.6 * a), 0.1)
			pd.draw_circle(tip, 7.0 * s, Color(pal[0], 0.8 * a))
			if not fox_form:
				# 불로 된 꼬리: 바깥 가장자리를 따라 위로 날리는 불 혀
				for k in range(2, left.size(), 2):
					var q: Vector2 = left[k] if (k / 2) % 2 == 0 else right[k]
					var fl := (16.0 + 10.0 * sin(t * 14.0 + k + i * 2.0)) * s
					PVfx.spike(pd, q, Vector2(sin(t * 6.0 + k) * 0.3, -1.0), fl, 9.0 * s, Color(pal[2], 0.55 * a))
		# 몸통 (가슴·앞다리)
		PVfx.safe_poly(pd, PackedVector2Array([c + Vector2(-34, -40) * s, c + Vector2(34, -40) * s, c + Vector2(26, 40) * s, c + Vector2(14, 90) * s,
			c + Vector2(-14, 90) * s, c + Vector2(-26, 40) * s]), Color(pal[2], 0.7 * a))
		PVfx.safe_poly(pd, PackedVector2Array([c + Vector2(-14, -30) * s, c + Vector2(14, -30) * s, c + Vector2(8, 60) * s, c + Vector2(-8, 60) * s]), Color(pal[1], 0.7 * a))
		# 가슴의 여우 문양(빛나는 고리)
		pd.draw_arc(c + Vector2(0, 0) * s, 14.0 * s, 0, TAU, 20, Color(pal[0], 0.9 * a), 2.0)
		pd.draw_circle(c, 6.0 * s, Color(pal[0], 0.9 * a))
		# 머리: 큰 세모 귀 둘 + 넓은 뺨 + 아래로 뾰족한 주둥이 (정면 여우 얼굴)
		var h := c + Vector2(0, -78) * s
		for side in [-1.0, 1.0]:
			PVfx.safe_poly(pd, PackedVector2Array([h + Vector2(side * 10, -26) * s, h + Vector2(side * 48, -86) * s, h + Vector2(side * 42, -14) * s]), Color(pal[1], 0.9 * a))
			PVfx.safe_poly(pd, PackedVector2Array([h + Vector2(side * 18, -26) * s, h + Vector2(side * 42, -70) * s, h + Vector2(side * 36, -20) * s]), Color(pal[3], 0.7 * a))
			# 뺨의 털 (옆으로 뻗은 불꽃)
			PVfx.spike(pd, h + Vector2(side * 34, 4) * s, Vector2(side, 0.5).normalized(), 26.0 * s, 14.0 * s, Color(pal[1], 0.75 * a))
		PVfx.safe_poly(pd, PackedVector2Array([h + Vector2(-40, -24) * s, h + Vector2(0, -36) * s, h + Vector2(40, -24) * s, h + Vector2(36, 6) * s,
			h + Vector2(14, 30) * s, h + Vector2(0, 50) * s, h + Vector2(-14, 30) * s, h + Vector2(-36, 6) * s]), Color(pal[1], 0.9 * a))
		PVfx.safe_poly(pd, PackedVector2Array([h + Vector2(-20, 4) * s, h + Vector2(20, 4) * s, h + Vector2(0, 48) * s]), Color(pal[0], 0.8 * a))
		pd.draw_circle(h + Vector2(0, 46) * s, 4.0 * s, Color(pal[3], a))
		# 이마의 불꽃 무늬
		PVfx.spike(pd, h + Vector2(0, -16) * s, Vector2(0, -1), 30.0 * s, 9.0 * s, Color(pal[0], 0.9 * a))
		# 날카롭게 치켜올라간 빛나는 눈
		for side in [-1.0, 1.0]:
			var e := h + Vector2(side * 17, -6) * s
			PVfx.safe_poly(pd, PackedVector2Array([e + Vector2(-side * 10, 4) * s, e + Vector2(side * 12, -6) * s, e + Vector2(side * 5, 5) * s]), Color(1, 1, 1, a))


	## 불 여우 정령의 몸에서 피어오르는 불꽃 (등·어깨·머리 둘레, 위로 일렁임)
	func _draw_spirit_flames(c: Vector2, s: float, a: float, pal: Array) -> void:
		for i in 14:
			var f := float(i) / 13.0
			var p := c + Vector2(lerpf(-60.0, 60.0, f), -40.0 - 70.0 * sin(f * PI)) * s
			var h := (34.0 + 18.0 * sin(t * (9.0 + i * 0.7) + i * 1.9)) * s * (0.6 + 0.4 * sin(f * PI))
			PVfx.spike(pd, p, Vector2(sin(t * 4.0 + i) * 0.35, -1.0), h, 22.0 * s, Color(pal[3], 0.55 * a))
			PVfx.spike(pd, p, Vector2(sin(t * 5.0 + i) * 0.3, -1.0), h * 0.6, 11.0 * s, Color(pal[1], 0.6 * a))


# ═══════════════════════════════════════════════════════════
# 여우방패 — 세라보다 훨씬 큰 여우 정령이 방패로 앞을 1.5초 완전히 막고(무적),
# 방패를 내리며 막은 피해만큼 커진 거대한 할퀴기로 반격한다. 평소 = 붉은 불, 변신 = 푸른 여우불.
# ═══════════════════════════════════════════════════════════

class ShieldSpirit extends PDraw.Canvas:
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

	func _paint() -> void:
		var pal := PSpells._pal(fox)
		var gold := Color(1.0, 0.8, 0.3)
		pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1.0))
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
			PVfx.safe_poly(pd, lp, Color(pal[3], 0.5 * aa))
			pd.draw_circle(tip, 6.0 * sc, Color(pal[1], 0.7 * aa))
			pd.draw_circle(tip, 3.0 * sc, Color(pal[0], 0.9 * aa))
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
			PVfx.safe_poly(pd, lpts, col)
		for i in 4:
			var x := (float(i) - 1.5) * 5.0
			pd.draw_line(o + Vector2(x, -6) * sc, o + Vector2(x * 0.6, -64) * sc, Color(pal[0], 0.35 * aa), 1.0)
		# 머리: 큰 귀 둘 + 앞으로 뻗은 주둥이 + 빛나는 눈 (옆모습)
		var hd := o + Vector2(2, -86) * sc
		PVfx.safe_poly(pd, PackedVector2Array([hd + Vector2(-10, -8) * sc, hd + Vector2(-8, -34) * sc, hd + Vector2(0, -14) * sc]), Color(pal[1], 0.85 * aa))
		PVfx.safe_poly(pd, PackedVector2Array([hd + Vector2(2, -12) * sc, hd + Vector2(10, -36) * sc, hd + Vector2(12, -10) * sc]), Color(pal[1], 0.85 * aa))
		PVfx.safe_poly(pd, PackedVector2Array([hd + Vector2(-14, -6) * sc, hd + Vector2(8, -14) * sc, hd + Vector2(16, -6) * sc, hd + Vector2(32, 2) * sc,
			hd + Vector2(14, 10) * sc, hd + Vector2(-8, 12) * sc, hd + Vector2(-16, 4) * sc]), Color(pal[2], 0.8 * aa))
		PVfx.safe_poly(pd, PackedVector2Array([hd + Vector2(0, -4) * sc, hd + Vector2(28, 2) * sc, hd + Vector2(8, 6) * sc]), Color(pal[0], 0.8 * aa))
		PVfx.safe_poly(pd, PackedVector2Array([hd + Vector2(4, -6) * sc, hd + Vector2(14, -8) * sc, hd + Vector2(10, -3) * sc]), Color(1, 1, 1, aa))
		if guard:
			# 방패: 여우 문장이 새겨진 큰 연 모양 방패를 앞에 세움 (세라보다 큼)
			var sp := o + Vector2(30, -44) * sc
			var shield := PackedVector2Array([sp + Vector2(-6, -44) * sc, sp + Vector2(14, -38) * sc, sp + Vector2(18, 0) * sc, sp + Vector2(10, 34) * sc, sp + Vector2(-2, 46) * sc, sp + Vector2(-10, 30) * sc, sp + Vector2(-12, -30) * sc])
			var fl := _flash
			PVfx.safe_poly(pd, shield, Color(pal[2].lerp(Color.WHITE, fl * 0.6), (0.75 + 0.2 * fl) * appear))
			var rim := shield.duplicate()
			rim.append(shield[0])
			pd.draw_polyline(rim, Color(gold, 0.9 * appear), 2.0)
			# 문장: 여우 얼굴 + 불꽃
			PVfx.safe_poly(pd, PackedVector2Array([sp + Vector2(-4, -12) * sc, sp + Vector2(-2, -22) * sc, sp + Vector2(2, -14) * sc, sp + Vector2(6, -22) * sc, sp + Vector2(8, -12) * sc, sp + Vector2(2, 2) * sc]), Color(pal[0], 0.9 * appear))
			pd.draw_arc(sp + Vector2(2, -6) * sc, 16.0 * sc, 0, TAU, 20, Color(gold, 0.6 * appear), 1.5)
			# 방패 앞 빛의 벽(완전히 막음) + 흡수 표시(막을수록 밝아짐)
			var wall := 0.25 + 0.1 * sin(t * 20.0) + 0.12 * float(mini(absorbed, 5))
			pd.draw_line(sp + Vector2(22, -50) * sc, sp + Vector2(22, 50) * sc, Color(pal[1], wall * appear), 3.0)
			for i in mini(absorbed, 5):
				pd.draw_circle(o + Vector2(-4, -50 + i * 9) * sc, 3.0, Color(pal[0], 0.9))
			# 팔: 방패를 받침
			pd.draw_line(o + Vector2(10, -56) * sc, sp + Vector2(-6, -8) * sc, Color(pal[1], 0.7 * aa), 6.0 * sc)
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
				PVfx.blade(pd, p0, p1, w * 1.6, Color(pal[3], 0.5 * a), -0.6)
				PVfx.blade(pd, p0, p1, w, Color(pal[1], 0.85 * a), -0.6)
				PVfx.blade(pd, p0, p1, w * 0.3, Color(pal[0], a), -0.6)
				# 뒤로 흩날리는 바람 결
				for j in 2:
					var yy := y + (float(j) - 0.5) * w * 1.4
					pd.draw_line(o + Vector2(-50 - j * 10, yy), o + Vector2(lerpf(-50.0, reach * 0.6, k), yy - 3), Color(pal[1], 0.35 * a), 1.0)
				if i == 1:
					tip = p1
			# 가운데 줄 끝의 커다란 정령 손 (앞으로 발톱을 세움)
			pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			if tip != Vector2.ZERO:
				PVfx.fire_paw(pd, Vector2(tip.x * dir, tip.y), 0.0 if dir > 0 else PI, 1.4 * p, fox, a)
		pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
