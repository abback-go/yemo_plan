class_name PShot
extends PDraw.Canvas
## 기본공격(X) 불덩이 — 사이퍼즈 타라의 '홍염화'처럼 붉은 불꽃 꽃잎이 소용돌이치는 덩어리를 집어던진다.
## 세라 둘레에 불덩이 3개가 늘 떠서 돈다(Orbit). X를 누를 때마다 하나를 손으로 끌어와 던진다:
## 1타 오른손 · 2타 왼손 · 3타 = 마지막 하나가 부풀어 두 손으로 던지는 큰 덩이(조금 느리고, 크고, 폭발도 큼).
## 셋을 다 쓰면 잠깐 뒤(0.3초, 변신 중 0.2초) 불꽃 고리에서 다시 셋이 피어난다. 간격·피해·게이지는 옛 발톱과 같다.
## 꼬리 수(= 기본공격 레벨 1~9)에 따라 불덩이·폭발·사거리가 커진다(9개면 3타 불덩이가 세라 키만 함).
## 변신 중 = 푸른 여우불: 불꽃 귀 둘 + 여우 꼬리 모양 자국, 맞은 자리에 여우 발자국.
## 타격감: 손을 떠날 때 손 섬광·불티, 맞으면 멈춤(hitstop)·던진 방향으로 카메라가 밀렸다 돌아옴·불꽃 꽃잎이 활짝 터짐·불티·연기.
## 지형에 닿아도 터진다(작은 폭발, 피해는 폭발 반경 안에만). 사거리 끝에서는 피식 꺼진다.

var sera: PSera
var dir := Vector2.RIGHT
var step := 0 ## 0 오른손 · 1 왼손 · 2 두 손
var fox := false
var dmg := 21
var r := 6.0 ## 불덩이 반지름
var blast := 15.0 ## 폭발 반경
var speed := 560.0
var range_px := 300.0
var t := 0.0
var _dist := 0.0
var _spin := 0.0
var _ember := 0.0
var _q := PhysicsRayQueryParameters2D.new()


func _ready() -> void:
	z_index = 7
	_spin = randf() * TAU
	_q.collision_mask = 1


func _process(delta: float) -> void:
	t += delta
	var mv := dir * speed * delta
	# 지형: 이번 프레임 이동 길이만큼 광선 한 번
	_q.from = global_position
	_q.to = global_position + mv + dir * r * 0.4
	var wall := get_world_2d().direct_space_state.intersect_ray(_q)
	if wall:
		global_position = (wall.position as Vector2) - dir * 2.0
		_explode()
		return
	global_position += mv
	_dist += mv.length()
	_spin += delta * (17.0 if step < 2 else 12.0) * (1.0 if dir.x >= 0.0 else -1.0)
	for d: PDummy in PDummy.all(get_tree()):
		if d.hit_rect().grow(r * 0.7).has_point(global_position):
			_explode()
			return
	# 지나간 자리에 불티 (적게: 프레임마다가 아니라 시간 간격으로)
	_ember -= delta
	if _ember <= 0.0:
		_ember = 0.035 if step < 2 else 0.025
		var pal := PSpells._pal(fox)
		var p := global_position - dir * r * 1.2 + dir.orthogonal() * randf_range(-r, r) * 0.6
		PParticles.get_layer(true).spawn(p, -dir * randf_range(20, 60) + Vector2(0, -randf_range(10, 40)), Vector2(0, -30),
			randf_range(0.25, 0.45), randf_range(1.2, 2.2) * (1.0 if step < 2 else 1.4), pal[0], pal[3], 0, 1.0)
	if _dist >= range_px:
		_fizzle()
		return
	queue_redraw()


## 맞으면: 반경 안 허수아비 모두에게 피해(대상마다 게이지) + 큰 꽃잎 폭발 + 타격감
func _explode() -> void:
	var pos := global_position
	var pal := PSpells._pal(fox)
	var hits := 0
	for d: PDummy in PDummy.all(get_tree()):
		var rr := d.hit_rect()
		var q := Vector2(clampf(pos.x, rr.position.x, rr.end.x), clampf(pos.y, rr.position.y, rr.end.y))
		if q.distance_to(pos) > blast:
			continue
		d.take_hit(dmg, pos - dir * 12.0, {"fox": fox, "heavy": step == 2, "launch": 1.5 if step == 2 else 0.0})
		hits += 1
		if is_instance_valid(sera):
			sera.add_gauge(PData.OD_SHOT)
	var b := Burst.new()
	b.fox = fox
	b.size = blast
	b.dir = dir
	b.heavy = step == 2
	b.hit = hits > 0
	PVfx.add(b, pos, true)
	var big := step == 2
	PVfx.sparks(pos, 9 if not big else 16, pal[1], 260.0 if not big else 320.0, 0.32, dir, 55.0)
	PVfx.sparks(pos, 5 if not big else 10, pal[0], 140.0, 0.26)
	PVfx.embers(pos, 3 if not big else 7, fox, 80.0, Vector2(blast * 0.4, blast * 0.3))
	PVfx.smoke(pos, 1 if not big else 3, blast * 0.45)
	if hits > 0:
		Fx.hitstop(PData.SHOT_HITSTOP if not big else 0.075)
		Fx.shake(0.07 if not big else 0.14, 0.1 if not big else 0.17)
		PVfx.kick(dir * (2.5 if not big else 5.0))
		if big:
			Fx.zoom_punch(0.025)
			Sfx.play(&"hit_heavy", -3.0)
			Sfx.play_pitch(&"explode", 1.15, -6.0)
		else:
			Sfx.play(&"hit", -4.0)
			Sfx.play_pitch(&"explode", 1.75, -13.0)
		if fox:
			var paw := PVfx.FoxPaw.new()
			paw.dir = 1 if dir.x >= 0.0 else -1
			paw.size = 0.9 if not big else 1.3
			PVfx.add(paw, pos, true)
	else:
		Fx.shake(0.03, 0.06)
		Sfx.play_pitch(&"explode", 1.9, -16.0)
	queue_free()


## 사거리 끝: 작아지며 연기 한 줌
func _fizzle() -> void:
	var b := Burst.new()
	b.fox = fox
	b.size = r * 1.4
	b.dir = dir
	b.hit = false
	b.life = 0.2
	PVfx.add(b, global_position, true)
	PVfx.smoke(global_position, 1, r * 0.6)
	queue_free()


func _paint() -> void:
	var pal := PSpells._pal(fox) # 흰 중심 · 밝은 · 가운데 · 짙은
	var k_in := minf(t / 0.06, 1.0) # 손을 떠나며 부풀어 오름
	var R := r * (0.55 + 0.45 * k_in)
	var back := -dir
	var side := dir.orthogonal()
	var big := step == 2
	# 1) 부드러운 빛무리 + 열기 고리
	pd.glow(Vector2.ZERO, R * (3.4 if not big else 3.9), Color(pal[2], 0.22))
	pd.glow(Vector2.ZERO, R * 1.9, Color(pal[1], 0.25))
	# 2) 뒤로 길게 날리는 꼬리 (여우 모드 = 끝이 흰 여우 꼬리)
	if fox:
		_fox_tail(R, back, side, pal, k_in)
	else:
		_flame_tail(R, back, side, pal, k_in)
	# 3) 홍염화 꽃잎: 몸통 둘레를 도는 불꽃 꽃잎 두 겹. 뒤쪽 꽃잎일수록 길게 휘날린다
	var n := 6 if not big else 8
	for layer in 2:
		for i in n:
			var a := _spin * (1.0 if layer == 0 else -0.6) + float(i) / float(n) * TAU + float(layer) * PI / float(n)
			var d := Vector2(cos(a), sin(a))
			var behind := maxf(d.dot(back), 0.0)
			var L := R * (1.3 + 1.0 * behind + 0.18 * sin(t * 38.0 + i * 1.7)) * (1.0 if layer == 0 else 0.74)
			var col: Color = Color(pal[3], 0.95).lerp(Color(pal[2], 0.95), behind * 0.6) if layer == 0 else Color(pal[2].lerp(pal[1], 0.5), 0.95)
			_petal(d * R * 0.35, d, L, R * (0.62 if layer == 0 else 0.48), back * behind * R * 0.6, col)
	# 4) 몸통: 가운데 불 → 밝은 불 → 흰 중심. 소용돌이 무늬 두 줄이 굴러감
	var pulse := 1.0 + 0.07 * sin(t * 45.0)
	pd.draw_circle(Vector2.ZERO, R * pulse * 1.06, pal[3])
	pd.draw_circle(Vector2.ZERO, R * pulse * 0.92, pal[2])
	pd.draw_circle(dir * R * 0.12, R * 0.7, pal[1])
	var sw := _spin * 1.4
	PVfx.crescent(pd, Vector2.ZERO, R * 0.86, sw, sw + 2.1, R * 0.26, Color(pal[0], 0.55), 10)
	PVfx.crescent(pd, Vector2.ZERO, R * 0.86, sw + PI, sw + PI + 2.1, R * 0.26, Color(pal[0], 0.55), 10)
	pd.draw_circle(dir * R * 0.2, R * 0.4 * pulse, pal[0])
	# 5) 앞쪽 공기를 가르는 흰 테두리
	var fa := dir.angle()
	PVfx.crescent(pd, Vector2.ZERO, R * 1.32, fa - 1.0, fa + 1.0, R * 0.2, Color(pal[1], 0.6), 10)
	# 6) 여우: 뒤로 젖힌 불꽃 귀 둘
	if fox:
		var up := Vector2(0, -1)
		for s: float in [-1.0, 1.0]:
			var base: Vector2 = up * R * 0.55 + side * s * R * 0.42 * signf(dir.x if dir.x != 0.0 else 1.0)
			var ear: Vector2 = (up * 1.0 + back * 0.55 + side * s * 0.25).normalized()
			PVfx.spike(pd, base, ear, R * 1.35, R * 0.7, Color(pal[1], 0.95))
			PVfx.spike(pd, base + ear * R * 0.1, ear, R * 0.9, R * 0.32, Color(pal[0], 0.95))
	# 7) 3타: 바깥을 도는 끊어진 열기 고리
	if big:
		for i in 5:
			var a0 := -_spin * 0.8 + float(i) / 5.0 * TAU
			pd.draw_arc(Vector2.ZERO, R * 1.85, a0, a0 + 0.7, 6, Color(pal[1], 0.5), 1.4)


## 꽃잎 하나: 밑동에서 dir 방향으로 L, 너비 w. 끝이 회전 반대쪽으로 말리고(소용돌이) drift만큼 뒤로 날림
func _petal(base: Vector2, d: Vector2, L: float, w: float, drift: Vector2, col: Color) -> void:
	var n := d.orthogonal()
	var tip := base + d * L + drift - n * L * 0.28
	var mid := base + d * L * 0.5 + drift * 0.5
	pd.convex(PackedVector2Array([base + n * w * 0.5, mid + n * w * 0.55, tip, mid - n * w * 0.35, base - n * w * 0.5]), col)


## 불꽃 꼬리 세 겹(짙은 → 가운데 → 흰): 뒤로 갈수록 가늘어지고 물결치며 투명해짐
func _flame_tail(R: float, back: Vector2, side: Vector2, pal: Array, k_in: float) -> void:
	var big := step == 2
	for layer in 3:
		var w0: float = R * ([1.05, 0.78, 0.42][layer] as float)
		var L: float = R * ([5.4, 4.0, 2.6][layer] as float) * (0.35 + 0.65 * k_in) * (0.85 if big else 1.0)
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		for i in 9:
			var f := float(i) / 8.0
			var wob := sin(f * 7.0 - t * 36.0 + layer * 1.3) * R * 0.38 * f
			var p := back * L * f + side * wob
			var w := w0 * pow(1.0 - f, 0.75) * (1.0 + 0.2 * sin(t * 50.0 + i * 2.0))
			left.append(p + side * w)
			right.append(p - side * w)
		var c0: Color = [Color(pal[3], 0.85), Color(pal[2], 0.9), Color(pal[1], 0.95)][layer]
		var c1: Color = [Color(pal[3], 0.0), Color(pal[3], 0.0), Color(pal[2], 0.0)][layer]
		pd.strip_grad(left, right, c0, c1)


## 여우 꼬리: 가운데가 통통하게 부풀었다 끝이 흰 불로 말려 올라가는 꼬리 (S자로 흔들림)
func _fox_tail(R: float, back: Vector2, side: Vector2, pal: Array, k_in: float) -> void:
	var L := R * 5.6 * (0.35 + 0.65 * k_in)
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var inl := PackedVector2Array()
	var inr := PackedVector2Array()
	var tip := Vector2.ZERO
	for i in 11:
		var f := float(i) / 10.0
		var p := back * L * f + side * sin(f * 4.0 - t * 14.0) * R * 0.7 * f + Vector2(0, -R * 0.9 * f * f)
		var w := R * (0.95 * sin(minf(f * 1.1, 1.0) * PI * 0.92 + 0.25)) + R * 0.1
		left.append(p + side * w)
		right.append(p - side * w)
		inl.append(p + side * w * 0.55)
		inr.append(p - side * w * 0.55)
		tip = p
	pd.strip_grad(left, right, Color(pal[3], 0.75), Color(pal[2], 0.55))
	pd.strip_grad(inl, inr, Color(pal[2], 0.85), Color(pal[0], 0.9))
	pd.glow(tip, R * 1.3, Color(pal[0], 0.7), 0.1)


# ═══════════════════════════════════════════════════════════
# 손을 떠날 때의 섬광 (던진 방향으로 짧은 가시 + 고리)
# ═══════════════════════════════════════════════════════════

class Muzzle extends PVfx.Base:
	var dir := Vector2.RIGHT
	var size := 1.0
	var from := Vector2.ZERO ## 끌어온 불덩이가 있던 자리(손 기준) — 거기서 손까지 불꽃 줄기

	func _init() -> void:
		life = 0.13
		z_index = 8

	func _paint() -> void:
		var kk := k()
		var a := 1.0 - kk
		var pal := PSpells._pal(fox)
		var s := size
		if from != Vector2.ZERO:
			pd.line2(from, Vector2.ZERO, Color(pal[2], 0.0), Color(pal[1], 0.85 * a), 1.0, 4.0 * s * a + 0.5)
		pd.glow(Vector2.ZERO, 14.0 * s, Color(pal[1], 0.6 * a))
		pd.draw_circle(Vector2.ZERO, 4.0 * s * a, Color(pal[0], a))
		for i in 5:
			var ang := dir.angle() + (float(i) - 2.0) * 0.32
			var l := (18.0 - absf(float(i) - 2.0) * 4.0) * s * (0.5 + kk)
			PVfx.spike(pd, Vector2.ZERO, Vector2(cos(ang), sin(ang)), l, 2.6 * a + 0.6, Color(pal[0], 0.9 * a))
		pd.draw_arc(Vector2.ZERO, (4.0 + 12.0 * kk) * s, 0, TAU, 16, Color(pal[1], 0.8 * a), 1.6 * a + 0.4)


# ═══════════════════════════════════════════════════════════
# 맞은 자리의 꽃잎 폭발 (홍염화가 피어나듯): 섬광 → 불덩이 → 바깥으로 활짝 펴지는 불꽃 꽃잎 + 충격파 고리.
# 꽃잎은 던진 방향 쪽으로 더 많이·멀리. 3타(heavy)는 더 크고 X자 빛살이 겹친다.
# ═══════════════════════════════════════════════════════════

class Burst extends PVfx.Base:
	var size := 15.0
	var dir := Vector2.RIGHT
	var heavy := false
	var hit := true
	var _petals: Array = [] ## [각도, 길이 배율, 너비 배율, 말림]

	func _init() -> void:
		life = 0.34
		z_index = 8

	func _ready() -> void:
		if heavy:
			life = 0.44
		var n := 9 if not heavy else 13
		for i in n:
			# 절반은 던진 방향 ±60도, 나머지는 둘레 전체
			var a := dir.angle() + randf_range(-1.05, 1.05) if i % 2 == 0 else randf() * TAU
			_petals.append([a, randf_range(0.75, 1.25) * (1.25 if i % 2 == 0 else 1.0), randf_range(0.7, 1.2), randf_range(-0.5, 0.5)])

	func _paint() -> void:
		var kk := k()
		var a := 1.0 - kk
		var e := 1.0 - pow(1.0 - kk, 3.0) # 빠르게 펴지고 천천히 멈춤
		var pal := PSpells._pal(fox)
		var S := size
		# 빛무리 + 중심 섬광
		pd.glow(Vector2.ZERO, S * 2.4 * (0.55 + 0.6 * e), Color(pal[2], 0.4 * a * a))
		if hit and kk < 0.15:
			pd.draw_circle(Vector2.ZERO, S * (0.45 + kk * 1.5), Color(pal[0], 0.85 * (1.0 - kk / 0.15)))
		# 불덩이 (부풀었다 꺼짐)
		pd.draw_circle(Vector2.ZERO, S * (0.4 + 0.4 * e) * (1.0 - kk * 0.5), Color(pal[2], 0.6 * a))
		pd.draw_circle(dir * S * 0.1, S * (0.3 + 0.25 * e) * (1.0 - kk * 0.7), Color(pal[1], 0.7 * a))
		pd.draw_circle(dir * S * 0.15, S * 0.25 * (1.0 - kk), Color(pal[0], 0.8 * a))
		# 꽃잎: 안쪽 밑동에서 바깥으로 길어지고, 끝이 말리며 사라짐
		for p: Array in _petals:
			var ang := float(p[0]) + float(p[3]) * kk
			var d := Vector2(cos(ang), sin(ang))
			var n := d.orthogonal()
			var r0 := S * 0.25 * e
			var r1 := S * (0.7 + 0.9 * float(p[1])) * e
			var w := S * 0.42 * float(p[2]) * (1.0 - kk * 0.6)
			var base := d * r0
			var tip := d * r1 + n * S * 0.25 * float(p[3])
			var mid := d * (r0 + r1) * 0.5
			pd.convex(PackedVector2Array([base + n * w * 0.3, mid + n * w * 0.6, tip, mid - n * w * 0.6, base - n * w * 0.3]), Color(pal[3].lerp(pal[2], 0.6), 0.75 * a))
			pd.convex(PackedVector2Array([base + n * w * 0.15, mid + n * w * 0.3, d * r1 * 0.92, mid - n * w * 0.3, base - n * w * 0.15]), Color(pal[1], 0.7 * a))
		# 충격파 고리 (재빨리 퍼짐)
		var swk := 1.0 - pow(1.0 - minf(kk * 2.6, 1.0), 2.0)
		pd.draw_arc(Vector2.ZERO, S * (0.4 + 1.5 * swk), 0, TAU, 28, Color(pal[0], 0.85 * (1.0 - swk)), 3.0 * (1.0 - swk) + 0.4)
		# 던진 방향으로 뿜어지는 불꽃 세 줄기
		if hit:
			for i in 3:
				var ang := dir.angle() + (float(i) - 1.0) * 0.38
				var dd := Vector2(cos(ang), sin(ang))
				PVfx.spike(pd, dd * S * 0.3, dd, S * (1.2 + 1.3 * e) * (1.2 if i == 1 else 0.85), S * 0.5 * a, Color(pal[1], 0.8 * a))
		# 3타: X자 빛살 + 두 번째 고리
		if heavy and hit:
			var xa := minf(kk * 4.0, 1.0)
			for i in 4:
				var ang := dir.angle() + PI / 4.0 + float(i) * PI / 2.0
				var dd := Vector2(cos(ang), sin(ang))
				PVfx.blade(pd, -dd * S * 0.2, dd * S * 2.6 * xa, S * 0.32 * a, Color(pal[0], 0.9 * a), 0.0)
			var sw2 := 1.0 - pow(1.0 - clampf((kk - 0.12) * 2.2, 0.0, 1.0), 2.0)
			if sw2 > 0.0:
				pd.draw_arc(Vector2.ZERO, S * (0.5 + 2.1 * sw2), 0, TAU, 32, Color(pal[1], 0.6 * (1.0 - sw2)), 2.0 * (1.0 - sw2) + 0.4)


# ═══════════════════════════════════════════════════════════
# 세라 둘레를 도는 불덩이 셋 (기본공격 탄창). 납작한 타원 궤도를 돌아서 뒤쪽 절반은 세라 몸 뒤에 그린다
# (front = false 노드가 몸 뒤 층, true가 앞 층 — 노드 둘이라 그리기 호출 2번).
# 남은 수는 sera.orbs. 하나 남으면 그 하나가 부풀어 앞쪽으로 나와 3타(큰 덩이)를 예고한다.
# ═══════════════════════════════════════════════════════════

class Orbit extends PDraw.Canvas:
	var sera: PSera
	var front := true
	var t := 0.0
	var _born := [-9.0, -9.0, -9.0] ## 칸마다 피어난 시각 (커지며 나타남)
	var _shown := 3
	const RX := 17.0
	const RY := 6.0
	const SPIN := 4.2

	func _ready() -> void:
		add_to_group(&"p_orbit")
		z_index = 3 if front else -6 # 효과 층(5) 기준: 앞 = 세라 위, 뒤 = 세라(0) 아래·지형(-4) 위

	func _process(delta: float) -> void:
		t += delta
		if not is_instance_valid(sera):
			queue_free()
			return
		global_position = sera.global_position + Vector2(0, -17)
		if sera.orbs > _shown:
			for i in range(_shown, sera.orbs):
				_born[i] = t
		_shown = sera.orbs
		visible = sera.art.visible and not sera.art.blink_hidden
		queue_redraw()

	## 칸 i의 궤도 각도와 위치 (세라 몸 기준, 손 쪽으로 살짝 치우침)
	func slot_angle(i: int) -> float:
		return t * SPIN + float(i) * TAU / 3.0

	func slot_pos(i: int) -> Vector2:
		var a := slot_angle(i)
		if sera.orbs == 1 and i == 0:
			# 마지막 하나: 앞쪽 머리 높이에서 크게 맴돎(3타 예고)
			return Vector2(sera.facing * (10.0 + cos(t * 6.0) * 3.0), -9.0 + sin(t * 6.0) * 2.0)
		return Vector2(cos(a) * RX, sin(a) * RY - 2.0)

	func _paint() -> void:
		var pal := PSpells._pal(sera.is_fox())
		var lv := PState.shot_size()
		for i in sera.orbs:
			var a := slot_angle(i)
			var last := sera.orbs == 1 and i == 0
			var depth := 1.0 if last else sin(a) # +1 = 앞(화면 아래쪽 궤도), −1 = 몸 뒤
			if (depth >= 0.0) != front:
				continue
			var grow := clampf((t - float(_born[i])) / 0.18, 0.0, 1.0)
			grow = 1.0 - pow(1.0 - grow, 3.0)
			var R := 3.6 * lv * grow * (1.55 if last else 1.0) * (0.8 + 0.2 * (depth * 0.5 + 0.5))
			if R < 0.3:
				continue
			var al := 0.55 + 0.45 * (depth * 0.5 + 0.5)
			var p := slot_pos(i)
			# 궤도를 따라 뒤로 끌리는 짧은 불꽃 꼬리 (궤도 접선 반대쪽)
			var tan := Vector2(-sin(a) * RX, cos(a) * RY).normalized() if not last else Vector2(0, 1)
			pd.line2(p - tan * R * 3.2, p, Color(pal[3], 0.0), Color(pal[2], 0.8 * al), 0.5, R * 1.3)
			pd.glow(p, R * 3.2, Color(pal[2], 0.25 * al))
			# 작은 홍염화 꽃잎 넷 (각자 돎)
			var sp := t * 11.0 + float(i) * 1.3
			for k in 4:
				var pa := sp + float(k) * TAU / 4.0
				var d := Vector2(cos(pa), sin(pa))
				PVfx.spike(pd, p + d * R * 0.3, d - tan * 0.4, R * (1.25 + 0.2 * sin(t * 30.0 + k)), R * 0.7, Color(pal[3].lerp(pal[2], 0.5), 0.9 * al))
			pd.draw_circle(p, R * 1.05, Color(pal[3], al))
			pd.draw_circle(p, R * 0.9, Color(pal[2], al))
			pd.draw_circle(p, R * 0.6, Color(pal[1], al))
			pd.draw_circle(p, R * 0.3, Color(pal[0], al))
			if sera.is_fox():
				for s: float in [-1.0, 1.0]:
					PVfx.spike(pd, p + Vector2(s * R * 0.45, -R * 0.6), Vector2(s * 0.3, -1.0), R * 1.1, R * 0.55, Color(pal[1], 0.9 * al))
			if last:
				# 부푼 마지막 덩이: 도는 열기 고리
				pd.draw_arc(p, R * 1.8, t * 8.0, t * 8.0 + 2.2, 8, Color(pal[1], 0.55), 1.0)
				pd.draw_arc(p, R * 1.8, t * 8.0 + PI, t * 8.0 + PI + 2.2, 8, Color(pal[1], 0.55), 1.0)


## 다시 피어나는 불덩이 셋: 세라 둘레에 불꽃 고리가 번쩍 (기본공격 재장전)
class Refill extends PVfx.Base:
	func _init() -> void:
		life = 0.3
		z_index = 3

	func _paint() -> void:
		var kk := k()
		var a := 1.0 - kk
		var pal := PSpells._pal(fox)
		var e := 1.0 - pow(1.0 - kk, 2.0)
		pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.36))
		pd.draw_arc(Vector2.ZERO, 8.0 + 14.0 * e, 0, TAU, 28, Color(pal[1], 0.85 * a), 2.5 * a + 0.5)
		pd.glow(Vector2.ZERO, 26.0 * e + 6.0, Color(pal[2], 0.3 * a))
		pd.draw_set_transform(Vector2.ZERO)
		for i in 3:
			var ang := float(i) / 3.0 * TAU + kk * 3.0
			var q := Vector2(cos(ang) * 17.0, sin(ang) * 6.0 - 2.0)
			pd.glow(q, 9.0 * a, Color(pal[0], 0.8 * a))
