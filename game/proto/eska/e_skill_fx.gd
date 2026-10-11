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

class Slash extends PVfx.Base:
	const SWEEP := 0.05 ## 호가 끝까지 그려지는 시간
	const HOLD := 0.08 ## 꽉 찬 채로 머무는 시간 (그 뒤 꼬리부터 걷히며 가늘어지고 옅어짐)
	var r := 60.0
	var w := 15.0
	var a0 := 0.0
	var a1 := 1.0
	var sq := 1.0
	var rot := 0.0 ## 납작한 회오리를 기울이는 각
	var dir := 1
	var big := false
	var _seed := 0

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

	## 호 위의 각 an 자리 (전역 좌표) — 납작하게 누르고 기울인 그대로
	func _arc_point(an: float, rr: float) -> Vector2:
		return position + Vector2(cos(an) * rr * dir, sin(an) * rr * sq).rotated(rot * dir)

	func _paint() -> void:
		pd.draw_set_transform(Vector2.ZERO, rot * dir, Vector2(dir, sq))
		# 공간이 먼저 한 줄로 갈라진다: 호 전체를 따라 가는 흰 금이 순간 번쩍이고, 그 금을 따라 참격이 지나간다
		var tear := 1.0 - clampf(t / (SWEEP + 0.07), 0.0, 1.0)
		if tear > 0.0:
			var tc := Color(EDGE, tear)
			EVfx.band(pd, r - w * 0.3 + 1.2, a0, a1, 2.4 * tear + 0.6, tc, tc, 40)
			EVfx.band(pd, r - w * 0.3 + 3.0, a0, a1, 5.0 * tear, Color(MAGENTA, 0.0), Color(MAGENTA, 0.35 * tear), 24)
		if t < SWEEP + HOLD:
			var p := clampf(t / SWEEP, 0.0, 1.0)
			var head := lerpf(a0, a1, 1.0 - pow(1.0 - p, 3.0))
			EVfx.dark_band(pd, r, a0, head, w, 1.0, _seed, 30 if big else 24)
			if p < 1.0:
				# 휘두르는 머리의 분홍빛 섬광 (부드럽게 꺼짐)
				var hp := Vector2(cos(head), sin(head)) * (r - w * 0.3)
				pd.glow(hp, w * 0.8, Color(EDGE, 0.6 * (1.0 - p * p)), 0.0)
		else:
			var e := clampf((t - SWEEP - HOLD) / maxf(life - SWEEP - HOLD, 0.01), 0.0, 1.0)
			var se := e * e * (3.0 - 2.0 * e) # 부드럽게 시작해 부드럽게 끝남
			var tail := lerpf(a0, a1, 0.88 * se)
			EVfx.dark_band(pd, r, tail, a1, w * (1.0 - 0.5 * se), pow(1.0 - e, 1.6), _seed, 30 if big else 24)
		pd.draw_set_transform(Vector2.ZERO)


# ═══════════════════════════════════════════════════════════
# 천열 · 단공 — 크고 긴 다크 참격(기본공격과 같은 Slash 그림)을 각도를 바꿔 가며 연달아 내보낸다
# ═══════════════════════════════════════════════════════════

## 다크 참격 여러 번을 차례로 내보내는 틀: 그림은 참격마다 Slash 노드, 이 노드는 순서와 판정만 맡는다
class SlashSeries extends Node2D:
	var eska: EEska
	var dir := 1
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

	func _fire(a: Dictionary, dmg: int, heavy: bool) -> void:
		var c: Vector2 = a.c
		var cen := position + Vector2(c.x * dir, c.y)
		var sl := Slash.new()
		sl.setup(a, dir, heavy)
		EVfx.add(sl, cen, false)
		Sfx.play_pitch(&"es_slash_big" if heavy else &"es_slash", (0.9 if heavy else randf_range(1.0, 1.2)), -1.0 if heavy else -6.0)
		_pending.append([t + 0.03, a, dmg, heavy, cen])

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

	func _judge(_a: Dictionary, dmg: int, heavy: bool, _cen: Vector2) -> void:
		var any := false
		for d: Node2D in ETarget.alive(get_tree()):
			if area.intersects(d.hit_rect()):
				eska.deal(d, dmg, heavy, Vector2(d.center().x - float(dir), area.end.y))
				any = true
		if heavy:
			EVfx.dark_burst(Vector2(area.get_center().x, area.position.y + area.size.y * 0.45), 52.0)
			EVfx.shards(area.get_center(), 10, 180.0, area.size * 0.3, 60.0)
			if any:
				Fx.hitstop(0.06)
				Fx.shake(0.34, 0.16)
		elif any:
			Fx.hitstop(0.02)
