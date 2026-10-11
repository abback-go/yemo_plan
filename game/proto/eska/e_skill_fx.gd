class_name ESkillFx
extends RefCounted
## 에스카 공격 연출·판정: 기본 참격(Slash) · 천열(Flurry) · 단공(Upsweep). 봉공(공간 고정)은 EStill (e_still.gd).
## 판정은 표적 그룹(EEska.targets) 기준. 색·그리기 도구는 EVfx를 쓴다.

const WHITE := EVfx.WHITE
const PALE := EVfx.PALE
const VIOLET := EVfx.VIOLET
const DEEP := EVfx.DEEP
const INK := EVfx.INK
const PLUM := EVfx.PLUM
const BODY := EVfx.BODY
const MAGENTA := EVfx.MAGENTA
const STREAK := EVfx.STREAK
const EDGE := EVfx.EDGE


# ═══════════════════════════════════════════════════════════
# 기본공격 참격
# ═══════════════════════════════════════════════════════════

## 균열 베기 (design.md 3-1): 흰 금이 호를 따라 번쩍 → 공간이 초승달로 찢어져 벌어짐(안은 검은 무 + 별빛, 보랏빛·분홍빛 흰 테)
## → 유리 파편과 까마귀 깃털이 튐 → 꼬리부터 꿰매듯 닫혀 가는 빛 줄만 남았다 사라진다. 한두 프레임에 꽉 차는 빠르기는 그대로.
class Slash extends PVfx.Base:
	const SWEEP := 0.05 ## 호가 끝까지 찢어지는 시간
	const HOLD := 0.07 ## 꽉 벌어진 채 머무는 시간 (그 뒤 꼬리부터 꿰매어 닫힘)
	const OPEN := 0.035 ## 금이 틈으로 벌어지는 시간
	const CLOSE_BIG := 0.24 ## 꿰매어 닫히는 데 걸리는 시간 (큰 참격)
	const CLOSE := 0.18
	var r := 60.0
	var w := 15.0
	var a0 := 0.0
	var a1 := 1.0
	var sq := 1.0
	var rot := 0.0 ## 납작한 회오리를 기울이는 각
	var dir := 1
	var big := false
	var ghost := 0.0 ## 메아리(물약) 복사본: 1이면 옅고 비치는 틈, 깃털 없음
	var _seed := 0
	var _burst := false
	var _closed := false
	var _xf := Transform2D.IDENTITY

	func setup(a: Dictionary, facing: int, is_big: bool) -> void:
		r = float(a.r)
		w = float(a.w)
		a0 = deg_to_rad(float(a.a0))
		a1 = deg_to_rad(float(a.a1))
		sq = float(a.sq)
		rot = deg_to_rad(float(a.get("rot", 0.0)))
		dir = facing
		big = is_big
		life = 0.62 if big else 0.46
		z_index = 6
		_seed = randi() % 997
		_xf = Transform2D(rot * dir, Vector2(dir, sq), 0.0, Vector2.ZERO)

	## 호 위의 각 an 자리 (전역 좌표) — 납작하게 누르고 기울인 그대로
	func _arc_point(an: float, rr: float) -> Vector2:
		return position + Vector2(cos(an) * rr * dir, sin(an) * rr * sq).rotated(rot * dir)

	func _close_time() -> float:
		return CLOSE_BIG if big else CLOSE

	func _tick(_delta: float) -> void:
		# 틈이 다 벌어지는 순간: 찢긴 자리에서 유리 파편이 튀고, 그중 몇은 까마귀 깃털이 되어 흩날린다
		if not _burst and t >= SWEEP:
			_burst = true
			var n := (5 if big else 3) - int(ghost * 2.0)
			for i in n:
				var an := lerpf(a0, a1, (float(i) + 0.5 + randf_range(-0.3, 0.3)) / float(n))
				var p := _arc_point(an, r - w * 0.4)
				var out := (p - position).normalized()
				EVfx.shards(p, 2, 150.0, Vector2(3, 3), 40.0)
				EVfx.pixels(p, 2, 120.0, out, 50.0, 0.25)
			if ghost < 0.5:
				var fp := _arc_point(lerpf(a0, a1, randf_range(0.45, 0.85)), r - w * 0.3)
				EVfx.feathers(fp, 2 if big else 1, 70.0, Vector2(6, 4), (fp - position).normalized())
		if not _closed and t >= SWEEP + HOLD + _close_time() * 0.6 and ghost < 0.5 and big and r > 160.0:
			_closed = true
			Sfx.play_pitch(&"es_tear_close", randf_range(1.0, 1.15), -16.0)

	func _paint() -> void:
		var p := clampf(t / SWEEP, 0.0, 1.0)
		var head := lerpf(a0, a1, 1.0 - pow(1.0 - p, 3.0))
		# 공간이 먼저 한 줄로 갈라진다: 호 전체를 따라 흰 금이 순간 번쩍이고, 그 금을 따라 틈이 찢어진다
		var tear := (1.0 - clampf(t / (SWEEP + 0.04), 0.0, 1.0)) * (1.0 if big else 0.55)
		if tear > 0.0 and ghost < 0.5:
			var cp := PackedVector2Array()
			var cn := PackedVector2Array()
			for i in 17:
				var an := lerpf(a0, a1, float(i) / 16.0)
				var u := Vector2(cos(an), sin(an))
				cp.append(_xf * (u * (r - w * 0.3)))
				cn.append(_xf.basis_xform(u))
			EVfx.crack(pd, cp, cn, tear, _seed)
		var span := head - a0
		if absf(span) < 0.03:
			return
		# 틈 모양: 바깥 반지름 r, 가장 굵은 곳 w (꼬리 쪽이 굵은 초승달) — 납작하게 누르고 기울인 그대로
		var seg := clampi(int(absf(span) * r / 10.0), 10, 36)
		var pts := PackedVector2Array()
		var nrm := PackedVector2Array()
		var hw := PackedFloat32Array()
		pts.resize(seg + 1)
		nrm.resize(seg + 1)
		hw.resize(seg + 1)
		for i in seg + 1:
			var f := float(i) / float(seg)
			var an := lerpf(a0, head, f)
			var thick := w * sin(pow(f, 0.72) * PI)
			var u := Vector2(cos(an), sin(an))
			pts[i] = _xf * (u * (r - thick * 0.5))
			nrm[i] = _xf.basis_xform(u)
			hw[i] = thick * 0.5
		# 벌어짐: 금 → 틈 (살짝 더 벌어졌다 자리 잡음) · 닫힘: 꼬리부터 지퍼처럼 꿰맴 · 꿰맨 자국은 남았다 사라짐
		var o := clampf(t / OPEN, 0.0, 1.0)
		var open := o * o * (3.0 - 2.0 * o) * (1.0 + 0.14 * sin(clampf(t / 0.14, 0.0, 1.0) * PI))
		var ct := _close_time()
		var z := clampf((t - SWEEP - HOLD) / ct, 0.0, 1.0)
		var zip := z * z * (3.0 - 2.0 * z) * 1.02
		var after := clampf((t - SWEEP - HOLD - ct) / maxf(life - SWEEP - HOLD - ct, 0.01), 0.0, 1.0)
		var fade := 1.0 - after # 메아리는 rift의 ghost가 옅게 (진하기를 낮추면 무 밑의 번짐이 비쳐 납작한 보라 띠가 됨)
		var oz: Array = EVfx.rift_open(hw, open, zip, 0.9, fade)
		EVfx.rift(pd, pts, nrm, oz[0], oz[1], _seed, t, ghost, 0.5 if ghost > 0.5 else 1.0)
		if p < 1.0:
			# 찢어 나가는 머리의 분홍빛 섬광
			pd.glow(pts[seg], w * 0.7, Color(EDGE, 0.7 * (1.0 - p * p)), 0.0)
		elif zip > 0.0 and zip < 1.0:
			# 꿰매는 바늘 끝: 지퍼가 지나가는 자리에 작은 별빛
			var zi := clampi(int(zip * float(seg)), 0, seg)
			EVfx.star4(pd, pts[zi], 3.5 + w * 0.06, t * 9.0, Color(EDGE, 0.9 * fade), Color(MAGENTA, 0.45 * fade))


# ═══════════════════════════════════════════════════════════
# 천열 · 단공 — 크고 긴 다크 참격(기본공격과 같은 Slash 그림)을 각도를 바꿔 가며 연달아 내보낸다
# ═══════════════════════════════════════════════════════════

## 다크 참격 여러 번을 차례로 내보내는 틀: 그림은 참격마다 Slash 노드, 이 노드는 순서와 판정만 맡는다
## 범위는 eska.mods.size(확장 물약)를 곱한다 (반지름·굵기·중심 거리 — 그림과 판정 모두).
class SlashSeries extends Node2D:
	const ECHO_GHOST := 0.999 ## power가 이보다 작으면 메아리 복사본 — 옅고 비치는 틈
	var eska: EEska
	var dir := 1
	var power := 1.0 ## 피해 배수 (메아리 물약: 0.35초 뒤 50% 세기로 한 번 더 = 0.5)
	var t := 0.0
	var specs: Array = [] ## [나갈 시각, Slash 설정, 피해, 큼]
	var _next := 0
	var _pending: Array = [] ## [판정 시각, Slash 설정, 피해, 큼, 참격 중심(전역)]

	func _process(delta: float) -> void:
		t += delta
		while _next < specs.size() and t >= float(specs[_next][0]):
			var sp: Array = specs[_next]
			_next += 1
			_fire(sp[1], int(sp[2]), bool(sp[3]))
		var i := 0
		while i < _pending.size():
			if t >= float(_pending[i][0]):
				if is_instance_valid(eska):
					_judge(_pending[i][1], int(_pending[i][2]), bool(_pending[i][3]), _pending[i][4])
				_pending.remove_at(i)
			else:
				i += 1
		if _next >= specs.size() and _pending.is_empty():
			queue_free()

	func _size() -> float:
		return float(eska.mods.get("size", 1.0)) if is_instance_valid(eska) else 1.0

	func _fire(a0: Dictionary, dmg: int, heavy: bool) -> void:
		var a := a0.duplicate()
		var s := _size()
		if s != 1.0:
			a.r = float(a.r) * s
			a.w = float(a.w) * s
			a.c = (a.c as Vector2) * s
		var c: Vector2 = a.c
		var cen := position + Vector2(c.x * dir, c.y)
		var sl := Slash.new()
		sl.setup(a, dir, heavy)
		var echo := power < ECHO_GHOST
		if echo:
			sl.ghost = 1.0
		EVfx.add(sl, cen, false)
		Sfx.play_pitch(&"es_slash_big" if heavy else &"es_slash", (0.9 if heavy else randf_range(1.0, 1.2)) * (1.12 if echo else 1.0),
			(-1.0 if heavy else -6.0) - (6.0 if echo else 0.0))
		_pending.append([t + 0.03, a, int(round(float(dmg) * power)), heavy, cen])

	func _judge(_a: Dictionary, _dmg: int, _heavy: bool, _cen: Vector2) -> void:
		pass


## 천열: 앞쪽 한 점을 중심으로 거대한 납작한 회오리 참격 열 번이 0.5초 동안 감싼다 (중심은 앞으로 150px, 반지름 130~190 — 앞으로 약 300~340px까지). 80×9 + 176 = 896
class Flurry extends SlashSeries:
	const CENTER := Vector2(150, -34) ## 참격들이 둘러싸는 중심 (발 기준, 앞으로)

	func _ready() -> void:
		z_index = 6
		# 앞쪽 한 점(CENTER)을 중심으로 납작한 회오리 참격 아홉 번이 기울기·방향을 번갈아 가며 감싸고(조금씩만 어긋나게),
		# 마지막에 같은 중심으로 가장 큰 회오리 — 참격들이 한 점을 둘러싼 꽃처럼 모인다
		var pat := [[-24.0, 0.34, 132.0], [20.0, 0.42, 150.0], [-8.0, 0.3, 168.0], [32.0, 0.38, 140.0], [-34.0, 0.46, 158.0],
			[10.0, 0.32, 176.0], [-16.0, 0.4, 146.0], [26.0, 0.3, 164.0], [-2.0, 0.36, 154.0]]
		for i in pat.size():
			var q: Array = pat[i]
			var fwd := i % 2 == 0 # 짝수 번째는 뒤→앞, 홀수 번째는 앞→뒤로 휘감는다
			var jit := Vector2(float((i * 7) % 5) - 2.0, float((i * 3) % 5) - 2.0) * 1.5
			specs.append([0.05 * float(i), {"a0": -200.0 if fwd else 160.0, "a1": 120.0 if fwd else -160.0, "r": q[2], "w": 40.0 + 2.0 * float(i % 3),
				"sq": q[1], "rot": q[0], "c": CENTER + jit}, 80, false])
		specs.append([0.5, {"a0": -210.0, "a1": 140.0, "r": 186.0, "w": 52.0, "sq": 0.4, "rot": 0.0, "c": CENTER}, 176, true])

	func _judge(a: Dictionary, dmg: int, heavy: bool, cen: Vector2) -> void:
		var any := false
		for d: Node2D in ETarget.alive(get_tree()):
			# 회오리가 중심을 거의 한 바퀴 감싸므로 판정은 중심 둘레 전체
			if eska._sector_hits(d.hit_rect(), cen, float(a.r) + 8.0, -180.0, 180.0, float(a.sq), float(a.rot)):
				eska.deal(d, dmg, heavy, global_position) # 밀리는 방향은 에스카 쪽에서
				any = true
		if any:
			Fx.hitstop(0.07 if heavy else 0.025)
			Fx.shake(0.45 if heavy else 0.14, 0.16 if heavy else 0.08)
			PVfx.kick(Vector2(dir * (5.0 if heavy else 2.0), 0))
			if heavy:
				Fx.zoom_punch(0.05)


## 단공: 머리 위 한 점을 중심으로 세로로 세운 회오리 참격이 모두 같은 방향으로 아래에서 위로 베어 올린다
## (기울기 -42 · -118 · -80 · -58 · -96도로 들쭉날쭉, 납작한 정도도 제각각 — 좌우 대칭이면 하트처럼 보여서 피함). 납작한 호를 세운다.
## 마지막에 가장 큰 회오리 + 어둠 폭발. 22×4 + 36 = 124
class Upsweep extends SlashSeries:
	var area := Rect2() ## 판정 구역 (전역 좌표)

	func _ready() -> void:
		z_index = 6
		specs = [
			[0.0, {"a0": 170.0, "a1": -40.0, "r": 104.0, "w": 24.0, "sq": 0.34, "rot": -42.0, "c": Vector2(4, -100)}, 22, false],
			[0.06, {"a0": 170.0, "a1": -40.0, "r": 110.0, "w": 24.0, "sq": 0.28, "rot": -118.0, "c": Vector2(-4, -108)}, 22, false],
			[0.12, {"a0": 170.0, "a1": -40.0, "r": 96.0, "w": 26.0, "sq": 0.46, "rot": -80.0, "c": Vector2(0, -104)}, 22, false],
			[0.18, {"a0": 170.0, "a1": -40.0, "r": 116.0, "w": 24.0, "sq": 0.24, "rot": -58.0, "c": Vector2(2, -110)}, 22, false],
			[0.3, {"a0": 175.0, "a1": -50.0, "r": 128.0, "w": 40.0, "sq": 0.4, "rot": -96.0, "c": Vector2(0, -126)}, 36, true],
		]
		var s := _size()
		if s != 1.0: # 확장 물약: 판정 구역도 발밑 가운데를 기준으로 넓힌다
			var bc := Vector2(area.get_center().x, area.end.y)
			area = Rect2(bc + (area.position - bc) * s, area.size * s)

	func _judge(_a: Dictionary, dmg: int, heavy: bool, _cen: Vector2) -> void:
		var any := false
		for d: Node2D in ETarget.alive(get_tree()):
			if area.intersects(d.hit_rect()):
				eska.deal(d, dmg, heavy, Vector2(d.center().x - float(dir), area.end.y))
				any = true
		if heavy:
			EVfx.dark_burst(Vector2(area.get_center().x, area.position.y + area.size.y * 0.45), 52.0)
			EVfx.shards(area.get_center(), 10, 180.0, area.size * 0.3, 60.0)
			if power >= ECHO_GHOST:
				EVfx.feathers(area.get_center(), 3, 110.0, area.size * 0.15)
			if any:
				Fx.hitstop(0.06)
				Fx.shake(0.34, 0.16)
		elif any:
			Fx.hitstop(0.02)
