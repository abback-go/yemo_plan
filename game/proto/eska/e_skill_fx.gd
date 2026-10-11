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
	const FAST_CLOSE := 0.1 ## 새 틈에 밀려 일찍 닫힐 때 (천열: 동시에 보이는 틈 수 제한)
	const RIFT_PTS := 12 ## 틈 등록부(ERifts)에 올리는 가운데 선 마디 수
	const DIM_T := 0.08 ## 흐려지는 데 걸리는 시간
	const DIM_A := 0.4 ## 흐려진 밝기
	const DIM_OPEN := 0.12 ## 흐려진 벌어짐 (얇은 선)
	const SEG_MAX := 24 ## 틈 마디 수 상한 (루프3: 36 → 24, 도형 수 — 판정과 상관없음)
	const SEG_LEN := 13.0 ## 호 길이 이만큼(px)마다 한 마디
	const BUSY_SEG_K := 0.7
	var r := 60.0
	var w := 15.0
	var a0 := 0.0
	var a1 := 1.0
	var sq := 1.0
	var rot := 0.0 ## 납작한 회오리를 기울이는 각
	var dir := 1
	var big := false
	var ghost := 0.0 ## 메아리(물약) 복사본: 1이면 옅고 비치는 틈, 깃털 없음
	var void_a := 1.0 ## 틈 안 검은 무의 진하기 (1보다 작으면 EVfx.rift 테만 모드 — 지금은 쓰지 않음)
	var open_for := 0.0 ## > 0 이면 고급 마법의 틈: 등록부(ERifts)에 올리고 이만큼(초) 열어 둔 뒤 꿰맴. 0 = 기본 베기(등록 안 함)
	var rift_id := 0
	var _zip_at := SWEEP + HOLD ## 꿰매기 시작하는 시각
	var _ct := CLOSE ## 꿰매는 데 걸리는 시간
	var _tail := 0.16 ## 다 꿰맨 뒤 자국이 사라지는 시간
	var _zipping := false
	var seg_k := 1.0 ## 마디 수 배수 (천열·단공 큰 틈은 낮춰 도형 수를 줄임)
	var _dim_at := -1.0 ## 흐려지기 시작한 시각 (단공: 판정이 끝나면 밝기 40%·얇은 선만 — 다음 예고를 가리지 않게)
	var dim_after := -1.0 ## >= 0 이면 나온 뒤 이만큼(초) 지나 스스로 흐려짐 (처음엔 두껍게 열린 밤하늘 몸통 — loop4_plan 6장)
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
		_ct = CLOSE_BIG if big else CLOSE
		_tail = life - SWEEP - HOLD - _ct

	func _ready() -> void:
		if open_for <= 0.0:
			return
		# 고급 마법의 틈: 다 찢긴 모양(가운데 선)을 전역 좌표로 등록 — 던진 물약이 여기 닿으면 스며든다
		var gp := PackedVector2Array()
		for i in RIFT_PTS + 1:
			var f := float(i) / float(RIFT_PTS)
			var an := lerpf(a0, a1, f)
			var thick := w * sin(pow(f, 0.72) * PI)
			gp.append(position + _xf * (Vector2(cos(an), sin(an)) * (r - thick * 0.5)))
		rift_id = ERifts.open(gp, w * 0.6, open_for)
		life = open_for + _ct + _tail

	## 판정이 끝난 틈: DIM_T 동안 밝기 DIM_A·벌어짐 DIM_OPEN으로 줄어 얇은 선만 남음
	func dim() -> void:
		if _dim_at < 0.0:
			_dim_at = t

	## 새 틈에 밀려 일찍 닫힘 (더 빨리 꿰맴)
	func close_fast() -> void:
		_ct = minf(_ct, FAST_CLOSE)
		_tail = minf(_tail, 0.08)
		if rift_id > 0:
			ERifts.close(rift_id)
		elif not _zipping:
			_zipping = true
			_zip_at = maxf(t, SWEEP)
			life = _zip_at + _ct + _tail

	## 호 위의 각 an 자리 (전역 좌표) — 납작하게 누르고 기울인 그대로
	func _arc_point(an: float, rr: float) -> Vector2:
		return position + Vector2(cos(an) * rr * dir, sin(an) * rr * sq).rotated(rot * dir)

	func _tick(_delta: float) -> void:
		if dim_after >= 0.0 and t >= dim_after:
			dim()
		# 등록된 틈: 등록부가 닫혔다고 하는 순간 꿰매기 시작 (흐린 물로 늘어나면 그만큼 더 열려 있음)
		if rift_id > 0 and not _zipping:
			var left := ERifts.left(rift_id)
			if left <= 0.0:
				_zipping = true
				_zip_at = maxf(t, SWEEP)
			else:
				_zip_at = maxf(t + left, SWEEP + HOLD)
			life = _zip_at + _ct + _tail
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
		if not _closed and t >= _zip_at + _ct * 0.6 and ghost < 0.5 and big and r > 160.0:
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
		var sk := seg_k * (BUSY_SEG_K if EMagicFx.busy() else 1.0) # 큰 마법이 겹친 때는 더 거칠게 (도형 수)
		var seg := clampi(int(absf(span) * r / SEG_LEN * sk), 8, int(SEG_MAX * sk))
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
		var z := clampf((t - _zip_at) / _ct, 0.0, 1.0)
		var zip := z * z * (3.0 - 2.0 * z) * 1.02
		var after := clampf((t - _zip_at - _ct) / maxf(_tail, 0.01), 0.0, 1.0)
		var fade := 1.0 - after # 메아리는 rift의 ghost가 옅게 (진하기를 낮추면 무 밑의 번짐이 비쳐 납작한 보라 띠가 됨)
		if _dim_at >= 0.0:
			var dk := clampf((t - _dim_at) / DIM_T, 0.0, 1.0)
			fade *= lerpf(1.0, DIM_A, dk)
			open *= lerpf(1.0, DIM_OPEN, dk)
		var oz: Array = EVfx.rift_open(hw, open, zip, 0.9, fade)
		EVfx.rift(pd, pts, nrm, oz[0], oz[1], _seed, t, ghost, 0.5 if ghost > 0.5 else 1.0, void_a)
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
	const OPEN_FOR := 1.0 ## 찢긴 틈이 열려 있는 시간 (틈 달이기: 이 동안 던진 물약이 스며든다 — loop2_plan 2장)
	const MAX_OPEN := 3 ## 동시에 보이는 틈 수 (넘으면 가장 오래된 것부터 빨리 꿰맴 — 표적·숫자가 가려지지 않게)
	const THICK_T := 0.1 ## 처음 이만큼은 두껍게 열린 밤하늘 몸통(검은 무 + 별빛) — 판정(0.03초)을 지나 보이게 (루프3의 얇은 "철사 틀"을 되돌림, loop4_plan 6장)
	const HITSTOP_FIRST := 0.03 ## 처음 맞힌 타격만 짧게 멈춤 (나머지 작은 타격은 흔들림만 — 떨림 방지)
	const HITSTOP_FINAL := 0.08 ## 마지막 큰 타격
	const MAX_OPEN_ALL := 3 ## 모든 연속 참격(메아리 복사본 포함)을 합쳐 동시에 보이는 틈 수 — 도형 수 상한 (loop3_plan 5장)
	const SEG_K := 0.55 ## 큰 틈의 마디 수 배수
	static var _all_open: Array = [] ## 모든 연속 참격의 열린 틈 (나온 순서)
	var dim_all := false ## true = 모든 참격이 THICK_T 뒤 흐려짐 (단공), false = 마지막 큰 참격만 (천열)
	var eska: EEska
	var dir := 1
	var power := 1.0 ## 피해 배수 (메아리 물약: 0.35초 뒤 50% 세기로 한 번 더 = 0.5)
	var t := 0.0
	var specs: Array = [] ## [나갈 시각, Slash 설정, 피해, 큼]
	var _next := 0
	var _pending: Array = [] ## [판정 시각, Slash 설정, 피해, 큼, 참격 중심(전역)]
	var _open: Array = [] ## 아직 열려 있는 이 연속 참격의 틈 (Slash, 나온 순서)
	var _hits := 0 ## 맞힌 판정 수 (히트스톱: 첫 타·마지막만)

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
		sl.open_for = OPEN_FOR
		if dim_all or heavy:
			sl.dim_after = THICK_T
		sl.seg_k = SEG_K
		_open = _open.filter(func(o: Variant) -> bool: return is_instance_valid(o))
		while _open.size() >= MAX_OPEN:
			(_open.pop_front() as Slash).close_fast()
		_open.append(sl)
		SlashSeries._all_open = SlashSeries._all_open.filter(func(o: Variant) -> bool: return is_instance_valid(o) and not (o as Slash)._zipping)
		while SlashSeries._all_open.size() >= MAX_OPEN_ALL:
			(SlashSeries._all_open.pop_front() as Slash).close_fast()
		SlashSeries._all_open.append(sl)
		EVfx.add(sl, cen, false)
		Sfx.play_pitch(&"es_slash_big" if heavy else &"es_slash", (0.9 if heavy else randf_range(1.0, 1.2)) * (1.12 if echo else 1.0),
			(-1.0 if heavy else -6.0) - (6.0 if echo else 0.0))
		_pending.append([t + 0.03, a, int(round(float(dmg) * power)), heavy, cen])

	func _judge(_a: Dictionary, _dmg: int, _heavy: bool, _cen: Vector2) -> void:
		pass

	## 맞힌 판정 하나의 멈춤: 첫 타 HITSTOP_FIRST, 마지막(final) HITSTOP_FINAL, 그 사이는 멈추지 않음 (흔들림은 부르는 쪽이)
	func _hit_stop(final: bool) -> void:
		_hits += 1
		if final:
			Fx.hitstop(HITSTOP_FINAL)
		elif _hits == 1:
			Fx.hitstop(HITSTOP_FIRST)


## 천열: 앞쪽 한 점을 중심으로 거대한 납작한 회오리 참격 열 번이 0.5초 동안 감싼다 (중심은 앞으로 150px, 반지름 130~190 — 앞으로 약 300~340px까지). 80×9 + 176 = 896
class Flurry extends SlashSeries:
	const CENTER := Vector2(150, -34) ## 참격들이 둘러싸는 중심 (발 기준, 앞으로)

	func _ready() -> void:
		z_index = 6 # 마지막 큰 고리만 THICK_T 뒤 흐려짐 (가장 커서 표적을 가장 많이 가림), 앞의 틈들은 원래 굵기
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
			_hit_stop(heavy)
			Fx.shake(0.45 if heavy else 0.14, 0.16 if heavy else 0.08)
			PVfx.kick(Vector2(dir * (5.0 if heavy else 2.0), 0))
			if heavy:
				Fx.zoom_punch(0.05)


## 단공 「가르는 틈」: 머리 위 한 점을 중심으로 세로로 세운 회오리 참격이 모두 같은 방향으로 아래에서 위로 베어 올린다
## (기울기 -42 · -118 · -80 · -58 · -96도로 들쭉날쭉, 납작한 정도도 제각각 — 좌우 대칭이면 하트처럼 보여서 피함). 납작한 호를 세운다.
## 마지막에 가장 큰 회오리 + 찢김 렌즈. 22×4 + 36 = 124
## 찢는 동안(ACTIVE) 구역 안의 발사체(그룹 PROJ_GROUP, deflect(by) -> bool)를 지운다. 발사체가 몸 PERFECT_R 안까지 왔을 때 지우면 "딱 맞춤" —
## 단공 쿨다운 초기화 + 종언 게이지 +4% + 강한 불꽃(시전에 한 번). 그보다 이르면 지우기만 (loop3_plan 2장)
## 판정이 끝나면 남은 틈은 밝기 40%·얇은 선으로 (다음 예고를 가리지 않게)
## 판정 구역은 그림에 맞춰 발 기준 좌우 HALF_W (예전 ±140은 그림 ±60~90보다 훨씬 넓었음), 바라보는 쪽으로 AREA_FWD 치우침
class Upsweep extends SlashSeries:
	const HALF_W := 64.0 ## 판정 반 너비 (loop3_plan 2장: ±90 → ±64)
	const AREA_FWD := 12.0
	const ACTIVE := 0.22 ## 발사체를 지우는 시간 (loop3_plan 2장: 0.36 → 0.22 — 점프 회피를 대신하는 무위험 정답이 되지 않게)
	const PERFECT_R := 70.0 ## "딱 맞춤": 발사체가 에스카 몸 가운데에서 이 안일 때 지우면 쿨다운 초기화 + 게이지 + 강한 불꽃
	const PROJ_GROUP := "es_projectile"
	const PROJ_PAD := 6.0 ## 발사체 몸 크기만큼 구역을 넓혀 봄
	const DEFLECT_GAUGE := 0.04 ## 지웠을 때 종언 게이지 (가득의 비율, 한 번 시전에 한 번)
	var area := Rect2() ## 판정 구역 (전역 좌표) — 만드는 쪽(EEska)이 넣고, _ready에서 그림에 맞게 좁힘
	var deflected := 0 ## 이번 시전에 지운 발사체 수
	var perfects := 0 ## 그중 "딱 맞춤" (보상은 시전에 한 번)
	var perfect := false ## 이번 시전에 "딱 맞춤" 성공 (튜토리얼 통과 조건 등이 읽음)

	func _ready() -> void:
		z_index = 6
		dim_all = true # 단공은 틈마다 THICK_T 뒤 흐린 얇은 선으로 (다음 예고를 가리지 않게)
		specs = [
			[0.0, {"a0": 170.0, "a1": -40.0, "r": 104.0, "w": 24.0, "sq": 0.34, "rot": -42.0, "c": Vector2(4, -100)}, 22, false],
			[0.06, {"a0": 170.0, "a1": -40.0, "r": 110.0, "w": 24.0, "sq": 0.28, "rot": -118.0, "c": Vector2(-4, -108)}, 22, false],
			[0.12, {"a0": 170.0, "a1": -40.0, "r": 96.0, "w": 26.0, "sq": 0.46, "rot": -80.0, "c": Vector2(0, -104)}, 22, false],
			[0.18, {"a0": 170.0, "a1": -40.0, "r": 116.0, "w": 24.0, "sq": 0.24, "rot": -58.0, "c": Vector2(2, -110)}, 22, false],
			[0.3, {"a0": 175.0, "a1": -50.0, "r": 128.0, "w": 40.0, "sq": 0.4, "rot": -96.0, "c": Vector2(0, -126)}, 36, true],
		]
		# 만드는 쪽이 높이·크기(확장 물약)는 이미 맞춰 넣으므로 너비만 그림에 맞춘다
		var s := _size()
		var cx := area.get_center().x + AREA_FWD * float(dir) * s
		area = Rect2(cx - HALF_W * s, area.position.y, HALF_W * 2.0 * s, area.size.y)

	func _process(delta: float) -> void:
		if t <= ACTIVE:
			_deflect()
		super(delta)

	## 구역 안 발사체 지우기
	func _deflect() -> void:
		if not is_instance_valid(eska):
			return
		var zone := area.grow(PROJ_PAD)
		for n: Node in get_tree().get_nodes_in_group(PROJ_GROUP):
			var p := n as Node2D
			if p == null or not p.has_method("deflect"):
				continue
			# 땅을 타는 비검·천검은 위치가 바닥 높이라, 판정 사각형(deflect_rect)이 있으면 그것으로 고른다
			var inside := zone.intersects(p.call("deflect_rect")) if p.has_method("deflect_rect") else zone.has_point(p.global_position)
			if not inside:
				continue
			var at := p.global_position
			var r: Rect2 = p.call("deflect_rect") if p.has_method("deflect_rect") else Rect2(at, Vector2.ZERO)
			var ec := eska.center()
			var near := Vector2(clampf(ec.x, r.position.x, r.end.x), clampf(ec.y, r.position.y, r.end.y))
			var is_perfect := near.distance_to(ec) <= PERFECT_R
			if not p.call("deflect", eska):
				continue
			deflected += 1
			EVfx.deflect_spark(at, is_perfect)
			Sfx.play_pitch(&"es_deflect", 1.0 if is_perfect else 1.25, -1.0 if is_perfect else -7.0)
			Fx.shake(0.22 if is_perfect else 0.08, 0.08)
			if is_perfect and perfects == 0:
				perfects += 1
				perfect = true
				eska.cooldowns["dangong"] = 0.0
				eska.add_gauge(DEFLECT_GAUGE * EEska.GAUGE_MAX)
				Fx.hitstop(HITSTOP_FIRST)

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
			_hit_stop(heavy)
			if heavy:
				Fx.shake(0.34, 0.16)
			else:
				Fx.shake(0.1, 0.06)
