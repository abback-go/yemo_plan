class_name EVfx
extends RefCounted
## 에스카 이펙트 (전부 코드 그림, 수명이 끝나면 스스로 사라짐).
## 색 언어: 흰 중심(갈라진 공간 너머의 공허) + 보라 테두리. 참격 레퍼런스 = 던전슬래셔 기본공격(캐릭터보다 몇 배 큰 초승달,
## 얇은 궤적선 2~3겹, 네모 픽셀 불티, 맞은 자리의 흰 금). 천열 = 백목련(부채처럼 펼쳐지는 수십 칼날),
## 단공 = 단혼파(공간 한 구역을 세로 참격이 찢음), 종언참 = 폭풍 속 거대 검(사방 참격선 + 화면을 가르는 일격).

const WHITE := Color(1, 1, 1)
const PALE := Color("#d9ccff")
const VIOLET := Color("#a98bff")
const DEEP := Color("#6b4fd0")


static func add(n: Node2D, pos: Vector2, additive := false) -> Node2D:
	return PVfx.add(n, pos, additive)


## 네모 픽셀 불티 (흰색 → 보라로 사라짐)
static func pixels(pos: Vector2, n: int, speed: float, dir := Vector2.ZERO, spread := 180.0, life := 0.3, grav := Vector2.ZERO) -> void:
	var pp := PParticles.get_layer(true)
	var base := dir.angle() if dir != Vector2.ZERO else 0.0
	for i in n:
		var a := base + deg_to_rad(randf_range(-spread, spread))
		var sp := randf_range(speed * 0.35, speed)
		pp.spawn(pos, Vector2(cos(a), sin(a)) * sp, grav, life * randf_range(0.6, 1.0), randf_range(1.0, 2.2), WHITE, VIOLET, 0, 3.0)


## 맞은 자리: 흰 금이 유리처럼 갈라지고 파편이 튄다
static func hit_crack(pos: Vector2, heavy: bool, dir: float) -> void:
	var c := HitCrack.new()
	c.heavy = heavy
	c.dir = dir if dir != 0.0 else 1.0
	add(c, pos, true)
	pixels(pos, 10 if heavy else 5, 190.0 if heavy else 130.0, Vector2(c.dir, -0.3), 70.0, 0.32, Vector2(0, 300))


static func land_dust(pos: Vector2) -> void:
	var pp := PParticles.get_layer(false)
	for i in 5:
		var s := -1.0 if i % 2 == 0 else 1.0
		pp.spawn(pos + Vector2(s * randf_range(2, 6), -1), Vector2(s * randf_range(20, 60), randf_range(-14, -4)), Vector2(0, 30), 0.35, randf_range(2.0, 3.0), Color(0.75, 0.7, 0.85, 0.45), Color(0.4, 0.36, 0.5, 0.2), 2, 3.0)


## 순간이동: 떠난 자리에 공간이 세로로 갈라졌다 닫힘
static func blink_out(pos: Vector2, dir: int) -> void:
	var r := Rift.new()
	r.dir = dir
	add(r, pos, true)
	pixels(pos, 8, 120.0, Vector2(-dir, 0), 50.0, 0.25)


static func blink_in(pos: Vector2, dir: int) -> void:
	var r := Rift.new()
	r.dir = dir
	r.arrive = true
	add(r, pos, true)
	pixels(pos, 6, 90.0, Vector2(dir, 0), 60.0, 0.22)


static func blink_trail(from: Vector2, to: Vector2) -> void:
	var s := Streak.new()
	s.to = to - from
	add(s, from, true)


# ═══════════════════════════════════════════════════════════
# 기본공격 참격
# ═══════════════════════════════════════════════════════════

class Slash extends PVfx.Base:
	const SWEEP := 0.055 ## 호가 끝까지 그려지는 시간
	var r := 60.0
	var w := 15.0
	var a0 := 0.0
	var a1 := 1.0
	var sq := 1.0
	var dir := 1
	var big := false
	var _crack := PackedVector2Array()

	func setup(a: Dictionary, facing: int, is_big: bool) -> void:
		r = float(a.r)
		w = float(a.w)
		a0 = deg_to_rad(float(a.a0))
		a1 = deg_to_rad(float(a.a1))
		sq = float(a.sq)
		dir = facing
		big = is_big
		life = 0.36 if big else 0.2
		z_index = 6
		if big:
			# 4타: 호를 따라 남았다 닫히는 공간의 금
			var n := 16
			for i in n + 1:
				var f := float(i) / float(n)
				var an := lerpf(a0, a1, f)
				var rr := r - w * 0.42 + randf_range(-2.5, 2.5)
				_crack.append(Vector2(cos(an) * rr, sin(an) * rr))

	func _ready() -> void:
		var n := 14 if big else 7
		for i in n:
			var an := lerpf(a0, a1, randf_range(0.35, 1.0))
			var p := position + Vector2(cos(an) * r * dir, sin(an) * r * sq)
			var tang := Vector2(-sin(an) * dir, cos(an) * sq) * signf(a1 - a0)
			var pp := PParticles.get_layer(true)
			pp.spawn(p, (tang * randf_range(40, 150) + Vector2(cos(an) * dir, sin(an)) * randf_range(20, 80)), Vector2.ZERO,
				randf_range(0.18, 0.32), randf_range(1.0, 2.2), WHITE, VIOLET, 0, 4.0)

	func _paint() -> void:
		var p := clampf(t / SWEEP, 0.0, 1.0)
		var head := lerpf(a0, a1, 1.0 - pow(1.0 - p, 2.0))
		var fade := 1.0 - clampf((t - SWEEP) / maxf(life - SWEEP, 0.01), 0.0, 1.0)
		var thin := lerpf(0.35, 1.0, fade)
		var span := head - a0
		pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, sq))
		PVfx.crescent(pd, Vector2.ZERO, r * 1.07, a0, head, w * 1.55 * thin, Color(DEEP, 0.5 * fade), 24)
		PVfx.crescent(pd, Vector2.ZERO, r, a0, head, w * thin, Color(VIOLET, 0.9 * fade), 24)
		PVfx.crescent(pd, Vector2.ZERO, r - w * 0.16, a0 + span * 0.08, head, w * 0.58 * thin, Color(PALE, fade), 22)
		PVfx.crescent(pd, Vector2.ZERO, r - w * 0.24, a0 + span * 0.18, head, w * 0.3 * thin, Color(WHITE, fade), 20)
		# 얇은 궤적선 두 겹 (살짝 어긋나게)
		PVfx.crescent(pd, Vector2.ZERO, r * 1.18, a0 + span * 0.22, head, 2.4, Color(PALE, 0.75 * fade), 18)
		PVfx.crescent(pd, Vector2.ZERO, r * 0.78, a0 + span * 0.35, head, 2.0, Color(VIOLET, 0.65 * fade), 16)
		if p < 1.0:
			var hp := Vector2(cos(head), sin(head)) * (r - w * 0.3)
			pd.glow(hp, w * 0.9, Color(WHITE, 0.8), 0.0)
		if big and t > SWEEP * 0.6:
			var ck := clampf((t - SWEEP) / (life - SWEEP), 0.0, 1.0)
			var cw := 2.6 * (1.0 - ck)
			if cw > 0.2:
				pd.draw_polyline(_crack, Color(WHITE, 0.95), cw)
		pd.draw_set_transform(Vector2.ZERO)


## 맞은 자리의 흰 금 (유리처럼)
class HitCrack extends PVfx.Base:
	var heavy := false
	var dir := 1.0
	var _lines: Array[PackedVector2Array] = []

	func _ready() -> void:
		life = 0.24 if heavy else 0.16
		z_index = 7
		var n := 7 if heavy else 5
		for i in n:
			var a := randf() * TAU
			var l := randf_range(8.0, 22.0 if heavy else 14.0)
			var pts := PackedVector2Array([Vector2.ZERO])
			var p := Vector2.ZERO
			for s in 3:
				a += randf_range(-0.6, 0.6)
				p += Vector2(cos(a), sin(a)) * l / 3.0
				pts.append(p)
			_lines.append(pts)

	func _paint() -> void:
		var f := 1.0 - k()
		pd.glow(Vector2.ZERO, (16.0 if heavy else 10.0) * (0.6 + 0.4 * f), Color(PALE, 0.7 * f), 0.0)
		for pts in _lines:
			pd.draw_polyline(pts, Color(WHITE, f), 1.6 if heavy else 1.2)
		pd.draw_arc(Vector2.ZERO, lerpf(4.0, 18.0 if heavy else 12.0, k()), 0.0, TAU, 18, Color(VIOLET, 0.8 * f), 1.4)


# ═══════════════════════════════════════════════════════════
# 순간이동
# ═══════════════════════════════════════════════════════════

## 세로로 갈라졌다 닫히는 공간의 틈
class Rift extends PVfx.Base:
	var dir := 1
	var arrive := false

	func _ready() -> void:
		life = 0.2
		z_index = 6

	func _paint() -> void:
		var x := k()
		var open := sin(x * PI) # 열렸다 닫힘
		var h := 22.0
		var w := 5.0 * open
		var pts := PackedVector2Array([Vector2(0, -h), Vector2(w * 0.6, -h * 0.4), Vector2(w, 0), Vector2(w * 0.5, h * 0.5), Vector2(0, h),
			Vector2(-w * 0.5, h * 0.4), Vector2(-w, 0), Vector2(-w * 0.6, -h * 0.5)])
		if w > 0.3:
			pd.draw_colored_polygon(pts, Color(VIOLET, 0.6 * open))
			pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.45, 1.0))
			pd.draw_colored_polygon(pts, Color(WHITE, 0.95))
			pd.draw_set_transform(Vector2.ZERO)
		pd.glow(Vector2.ZERO, 14.0 * open, Color(PALE, 0.35), 0.0)


## 출발점 → 도착점 한 줄 (아주 짧게)
class Streak extends PVfx.Base:
	var to := Vector2.ZERO

	func _ready() -> void:
		life = 0.12
		z_index = 5

	func _paint() -> void:
		var f := 1.0 - k()
		pd.line2(Vector2.ZERO, to, Color(VIOLET, 0.0), Color(WHITE, 0.9 * f), 1.0, 2.6 * f)


# ═══════════════════════════════════════════════════════════
# 천열 — 손가락을 튕기면 수십 칼날이 부채처럼 펼쳐진다
# ═══════════════════════════════════════════════════════════

class Fan extends PVfx.Base:
	const N := 16
	const SPREAD := 46.0 ## 위아래 각도(도)
	const LEN := 156.0
	const GAP := 0.011 ## 칼날 사이 시간
	const DMG := 14
	var eska: EEska
	var dir := 1
	var _ang := PackedFloat32Array()
	var _len := PackedFloat32Array()
	var _fired := PackedByteArray()
	var _hits := 0

	func _ready() -> void:
		life = N * GAP + 0.28
		z_index = 6
		var order := range(N)
		order.shuffle()
		for i in N:
			var f := float(order[i]) / float(N - 1)
			_ang.append(deg_to_rad(lerpf(-SPREAD, SPREAD, f) + randf_range(-2.0, 2.0)))
			_len.append(LEN * randf_range(0.78, 1.12))
			_fired.append(0)
		EVfx.pixels(position, 8, 80.0, Vector2(dir, 0), 90.0, 0.2)

	func _tick(_delta: float) -> void:
		for i in N:
			if _fired[i] == 0 and t >= float(i) * GAP:
				_fired[i] = 1
				_blade_hit(i)

	func _dirv(i: int) -> Vector2:
		return Vector2(cos(_ang[i]) * dir, sin(_ang[i]))

	func _blade_hit(i: int) -> void:
		if not is_instance_valid(eska):
			return
		var dv := _dirv(i)
		for d: PDummy in PDummy.all(get_tree()):
			var rect := d.hit_rect().grow(4.0)
			for s in 12:
				var p := global_position + dv * lerpf(10.0, _len[i], float(s) / 11.0)
				if rect.has_point(p):
					eska.deal(d, DMG, false, global_position)
					_hits += 1
					if _hits == 1:
						Fx.hitstop(0.03)
						Fx.shake(0.12, 0.1)
					break

	func _paint() -> void:
		# 손끝 튕김 섬광
		if t < 0.12:
			var sf := 1.0 - t / 0.12
			pd.glow(Vector2.ZERO, 12.0 * (1.0 + (1.0 - sf)), Color(WHITE, 0.9 * sf), 0.0)
			pd.draw_arc(Vector2.ZERO, lerpf(3.0, 22.0, 1.0 - sf), 0.0, TAU, 20, Color(PALE, sf), 1.5)
		for i in N:
			var age := t - float(i) * GAP
			if age < 0.0:
				continue
			var grow := clampf(age / 0.05, 0.0, 1.0)
			var fade := 1.0 - clampf((age - 0.07) / 0.2, 0.0, 1.0)
			if fade <= 0.0:
				continue
			var dv := _dirv(i)
			var nv := dv.orthogonal()
			var base := dv * 9.0
			var tip := dv * _len[i] * (1.0 - pow(1.0 - grow, 3.0))
			var mid := base.lerp(tip, 0.62)
			var wd := 3.4 * lerpf(0.4, 1.0, fade)
			pd.draw_colored_polygon(PackedVector2Array([base, mid + nv * wd * 1.7, tip, mid - nv * wd * 1.7]), Color(DEEP, 0.45 * fade))
			pd.draw_colored_polygon(PackedVector2Array([base, mid + nv * wd, tip, mid - nv * wd]), Color(VIOLET, 0.95 * fade))
			pd.draw_colored_polygon(PackedVector2Array([base + dv * 4.0, mid + nv * wd * 0.45, tip, mid - nv * wd * 0.45]), Color(WHITE, fade))


# ═══════════════════════════════════════════════════════════
# 단공 — 위쪽 공간 한 구역을 세로 참격이 갈가리 찢는다 (지상·공중)
# ═══════════════════════════════════════════════════════════

class Storm extends PVfx.Base:
	const TICKS := 8
	const DMG := 11
	const FINAL_DMG := 36
	var eska: EEska
	var area := Rect2() ## 전역 좌표
	var _streaks: Array = [] ## [시작 시각, 점들]
	var _next := 0.0
	var _ticks := 0
	var _final := false

	func _ready() -> void:
		life = 0.66
		z_index = 6

	func _tick(_delta: float) -> void:
		while _next <= t and t < 0.46:
			_next += 0.016
			var x := randf_range(area.position.x + 4.0, area.end.x - 4.0)
			var y0 := area.position.y + area.size.y * randf_range(0.0, 0.25)
			var y1 := area.position.y + area.size.y * randf_range(0.7, 1.0)
			var pts := PackedVector2Array()
			var n := 7
			for i in n + 1:
				var f := float(i) / float(n)
				pts.append(Vector2(x + randf_range(-4.5, 4.5) + (f - 0.5) * randf_range(-6, 6), lerpf(y0, y1, f)))
			_streaks.append([t, pts])
		if not is_instance_valid(eska):
			return
		if _ticks < TICKS and t >= 0.04 + float(_ticks) * 0.052:
			_ticks += 1
			_hit_all(DMG, false)
		if not _final and t >= 0.5:
			_final = true
			if _hit_all(FINAL_DMG, true):
				Fx.hitstop(0.06)
				Fx.shake(0.3, 0.16)
			EVfx.pixels(area.get_center(), 14, 200.0, Vector2.UP, 160.0, 0.3, Vector2(0, 200))

	func _hit_all(dmg: int, heavy: bool) -> bool:
		var any := false
		for d: PDummy in PDummy.all(get_tree()):
			if area.intersects(d.hit_rect()):
				eska.deal(d, dmg, heavy, Vector2(d.center().x - float(eska.facing), area.end.y))
				any = true
		if any and not heavy and _ticks % 3 == 1:
			Fx.hitstop(0.018)
		return any

	func _paint() -> void:
		var env := clampf(t / 0.06, 0.0, 1.0) * (1.0 - clampf((t - 0.46) / 0.2, 0.0, 1.0))
		pd.rect_grad(area, Color(DEEP, 0.0), Color(VIOLET, 0.22 * env))
		pd.draw_rect(Rect2(area.position.x, area.end.y - 2.0, area.size.x, 2.0), Color(PALE, 0.5 * env))
		for s: Array in _streaks:
			var age: float = t - float(s[0])
			if age > 0.16:
				continue
			var f := 1.0 - age / 0.16
			var pts: PackedVector2Array = s[1]
			pd.draw_polyline(pts, Color(VIOLET, 0.6 * f), 4.0 * f + 1.0)
			pd.draw_polyline(pts, Color(WHITE, f), 1.6 * f + 0.6)
		if _final:
			var ff := 1.0 - clampf((t - 0.5) / 0.16, 0.0, 1.0)
			if ff > 0.0:
				var cx := area.get_center().x
				pd.draw_line(Vector2(cx, area.position.y - 10.0), Vector2(cx, area.end.y), Color(WHITE, ff), 6.0 * ff)
				pd.glow(Vector2(cx, area.get_center().y), area.size.x * 0.6, Color(PALE, 0.35 * ff), 0.0)


# ═══════════════════════════════════════════════════════════
# 봉공 — 대상 둘레의 공간을 틀로 가둔다. 끝나면 유리처럼 깨지며 한 번 더 벤다.
# ═══════════════════════════════════════════════════════════

class BindFrame extends PVfx.Base:
	const HOLD := 2.4
	const SHATTER_DMG := 40
	var eska: EEska
	var target: PDummy
	var _size := Vector2(46, 58)
	var _cracks: Array[PackedVector2Array] = []
	var _broken := false
	var _break_at := HOLD

	func _ready() -> void:
		z_index = 6
		if is_instance_valid(target):
			var r := target.hit_rect().grow(9.0)
			_size = r.size
			position = r.get_center()
			target.bind(HOLD, true, true, "void")
			life = HOLD + 0.3
		else:
			_break_at = 0.28
			life = 0.55
		var hs := _size * 0.5
		for i in 6:
			var side := i % 4
			var start := Vector2.ZERO
			match side:
				0: start = Vector2(randf_range(-hs.x, hs.x), -hs.y)
				1: start = Vector2(hs.x, randf_range(-hs.y, hs.y))
				2: start = Vector2(randf_range(-hs.x, hs.x), hs.y)
				_: start = Vector2(-hs.x, randf_range(-hs.y, hs.y))
			var pts := PackedVector2Array([start])
			var p := start
			var aim := (-start).normalized()
			for s in 3:
				aim = aim.rotated(randf_range(-0.7, 0.7))
				p += aim * randf_range(5.0, 11.0)
				pts.append(p)
			_cracks.append(pts)
		EVfx.pixels(position, 10, 90.0, Vector2.ZERO, 180.0, 0.25)

	func _tick(_delta: float) -> void:
		if not _broken and is_instance_valid(target):
			position = target.hit_rect().get_center()
		if not _broken and t >= _break_at:
			_broken = true
			if is_instance_valid(target) and is_instance_valid(eska):
				target.unbind()
				eska.deal(target, SHATTER_DMG, true, position + Vector2(-eska.facing, 0))
				Fx.hitstop(0.05)
				Fx.shake(0.25, 0.14)
			Sfx.play(&"crumble", -4.0)
			var pp := PParticles.get_layer(true)
			var hs := _size * 0.5
			for i in 26:
				var p := position + Vector2(randf_range(-hs.x, hs.x), randf_range(-hs.y, hs.y))
				var v := (p - position).normalized() * randf_range(60.0, 190.0) + Vector2(0, -40)
				pp.spawn(p, v, Vector2(0, 380), randf_range(0.3, 0.55), randf_range(1.5, 3.0), WHITE, VIOLET, 0, 1.0)

	func _paint() -> void:
		var hs := _size * 0.5
		if _broken:
			var bf := 1.0 - clampf((t - _break_at) / 0.25, 0.0, 1.0)
			pd.draw_rect(Rect2(-hs * (1.0 + (1.0 - bf) * 0.3), _size * (1.0 + (1.0 - bf) * 0.3)), Color(PALE, 0.5 * bf), false, 2.0)
			pd.glow(Vector2.ZERO, maxf(hs.x, hs.y) * 1.3, Color(WHITE, 0.35 * bf), 0.0)
			return
		var form := clampf(t / 0.12, 0.0, 1.0)
		var pulse := 0.85 + 0.15 * sin(t * 10.0)
		pd.draw_rect(Rect2(-hs, _size), Color(DEEP, 0.18 * form))
		# 테두리 (모서리부터 그어짐)
		var cw := 2.0
		var lx := hs.x * 2.0 * form
		var ly := hs.y * 2.0 * form
		var col := Color(WHITE, 0.85 * pulse)
		pd.draw_line(Vector2(-hs.x, -hs.y), Vector2(-hs.x + lx, -hs.y), col, cw)
		pd.draw_line(Vector2(hs.x, hs.y), Vector2(hs.x - lx, hs.y), col, cw)
		pd.draw_line(Vector2(hs.x, -hs.y), Vector2(hs.x, -hs.y + ly), col, cw)
		pd.draw_line(Vector2(-hs.x, hs.y), Vector2(-hs.x, hs.y - ly), col, cw)
		# 모서리 쐐기
		for sx: float in [-1.0, 1.0]:
			for sy: float in [-1.0, 1.0]:
				var cpt := Vector2(hs.x * sx, hs.y * sy)
				pd.draw_line(cpt, cpt + Vector2(-sx * 9.0, 0), Color(VIOLET, form), 3.0)
				pd.draw_line(cpt, cpt + Vector2(0, -sy * 9.0), Color(VIOLET, form), 3.0)
				pd.draw_rect(Rect2(cpt - Vector2(2, 2), Vector2(4, 4)), Color(WHITE, form))
		# 갇힌 공간의 금 + 흔들리는 세로 일그러짐
		for pts in _cracks:
			pd.draw_polyline(pts, Color(WHITE, 0.6 * form), 1.0)
		for i in 3:
			var x := lerpf(-hs.x, hs.x, fmod(t * 0.7 + float(i) / 3.0, 1.0))
			pd.draw_line(Vector2(x, -hs.y + 2), Vector2(x, hs.y - 2), Color(PALE, 0.18 * form), 1.0)
		# 깨지기 직전 경고 깜빡임
		if t > _break_at - 0.35:
			var wf := 0.5 + 0.5 * sin(t * 40.0)
			pd.draw_rect(Rect2(-hs, _size), Color(WHITE, 0.25 * wf), false, 1.0)


# ═══════════════════════════════════════════════════════════
# 종언참 — 세상이 어두워지고, 사방으로 참격이 몰아친 뒤, 하늘의 거대한 공허의 칼날이 화면을 세로로 가른다
# ═══════════════════════════════════════════════════════════

class Ult extends Node2D:
	const SLAM := 0.62
	const END := 1.75
	const SLAM_DMG := 220
	const AFTER_DMG := 24
	var eska: EEska
	var target_x := 0.0
	var floor_y := 300.0
	var t := 0.0
	var lines: Array = [] ## [각도, 길이, 시작]
	var _slammed := false
	var _after := 0
	var _dark: UltDark
	var _glow: UltGlow
	var _banner: UltBanner

	func _ready() -> void:
		for i in 30:
			var a := -PI / 2.0 + randf_range(-PI * 0.95, PI * 0.95)
			lines.append([a, randf_range(90.0, 300.0), randf_range(0.04, 0.4)])
		_dark = UltDark.new()
		_dark.u = self
		_dark.z_index = 4
		add_child(_dark)
		_glow = UltGlow.new()
		_glow.u = self
		_glow.z_index = 7
		_glow.material = Fx.add_material
		add_child(_glow)
		var layer := CanvasLayer.new()
		layer.layer = 15
		add_child(layer)
		_banner = UltBanner.new()
		_banner.u = self
		_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
		_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(_banner)

	func hand() -> Vector2:
		if is_instance_valid(eska):
			return eska.global_position + Vector2(eska.facing * 2.0, -42.0)
		return Vector2(target_x, floor_y - 40.0)

	func _process(delta: float) -> void:
		t += delta
		if not _slammed and t >= SLAM:
			_slammed = true
			_slam()
		if _slammed and _after < 4 and t >= SLAM + 0.16 * float(_after + 1):
			_after += 1
			_hit_column(AFTER_DMG, false, 30.0)
			EVfx.pixels(Vector2(target_x, floor_y - randf_range(20.0, 120.0)), 6, 160.0, Vector2.ZERO, 180.0, 0.3)
		if t >= END:
			queue_free()
			return
		_dark.queue_redraw()
		_glow.queue_redraw()
		_banner.queue_redraw()

	func _slam() -> void:
		Fx.flash(Color(1, 1, 1, 0.7), 0.2)
		Fx.hitstop(0.12)
		Fx.shake(1.2, 0.5)
		Fx.zoom_punch(0.1)
		PVfx.kick(Vector2(0, 7))
		Sfx.play(&"explode", 0.0)
		Sfx.play(&"slam", -2.0)
		_hit_column(SLAM_DMG, true, 48.0)
		var pp := PParticles.get_layer(true)
		for i in 40:
			var p := Vector2(target_x + randf_range(-10, 10), floor_y - randf_range(0, 200))
			pp.spawn(p, Vector2(randf_range(-260, 260), randf_range(-220, 40)), Vector2(0, 420), randf_range(0.35, 0.7), randf_range(1.5, 3.0), WHITE, VIOLET, 0, 1.5)

	func _hit_column(dmg: int, heavy: bool, half_w: float) -> void:
		if not is_instance_valid(eska):
			return
		var col := Rect2(target_x - half_w, floor_y - 400.0, half_w * 2.0, 440.0)
		for d: PDummy in PDummy.all(get_tree()):
			if col.intersects(d.hit_rect()):
				eska.deal(d, dmg, heavy, Vector2(target_x, floor_y - 300.0))

	## 0 → 1 → 0 (어둠·현수막)
	func env() -> float:
		return clampf(t / 0.12, 0.0, 1.0) * (1.0 - clampf((t - (END - 0.35)) / 0.35, 0.0, 1.0))


## 세상을 어둡게 (보통 섞기 — 캐릭터·허수아비도 함께 어두워져 실루엣이 된다)
class UltDark extends PDraw.Canvas:
	var u: Ult

	func _paint() -> void:
		var cam := get_viewport().get_camera_2d()
		var c := cam.get_screen_center_position() if cam else Vector2(320, 180)
		var a := 0.62 * u.env()
		pd.draw_rect(Rect2(c - Vector2(400, 260), Vector2(800, 520)), Color(0.03, 0.01, 0.07, a))


## 빛나는 것들 (가산): 사방 참격선 · 공허의 칼날 · 세로로 갈라진 화면
class UltGlow extends PDraw.Canvas:
	var u: Ult

	func _paint() -> void:
		var t := u.t
		var h := u.hand()
		var tx := u.target_x
		var fy := u.floor_y
		# 손 위의 빛
		if t < Ult.SLAM + 0.1:
			var hf := clampf(t / 0.2, 0.0, 1.0)
			pd.glow(h, 10.0 + 6.0 * sin(t * 30.0), Color(WHITE, 0.9 * hf), 0.0)
		# 사방으로 몰아치는 참격선
		for l: Array in u.lines:
			var age: float = t - float(l[2])
			if age < 0.0 or age > 0.32:
				continue
			var f := age / 0.32
			var dv := Vector2(cos(float(l[0])), sin(float(l[0])))
			var a := h + dv * float(l[1]) * f * 0.35
			var b := h + dv * float(l[1]) * minf(f * 1.4, 1.0)
			pd.line2(a, b, Color(VIOLET, 0.0), Color(WHITE, 0.9 * (1.0 - f)), 1.0, 2.4)
		# 공허의 칼날 (하늘에서 형성 → 내리꽂힘)
		if t < Ult.SLAM:
			var form := clampf((t - 0.1) / (Ult.SLAM - 0.1), 0.0, 1.0)
			var len := 300.0
			var top := fy - 420.0 + 40.0 * form
			var w := 18.0 * form
			var tip := Vector2(tx, top + len)
			var blade := PackedVector2Array([Vector2(tx, top), Vector2(tx + w, top + len * 0.22), tip, Vector2(tx - w, top + len * 0.22)])
			pd.draw_colored_polygon(blade, Color(DEEP, 0.5 * form))
			pd.draw_polyline(PackedVector2Array([blade[0], blade[1], blade[2], blade[3], blade[0]]), Color(WHITE, form), 1.5)
			pd.draw_set_transform(Vector2(tx, top + len * 0.5), 0.0, Vector2(0.35, 0.92))
			pd.draw_colored_polygon(PackedVector2Array([Vector2(0, -len * 0.5), Vector2(w, -len * 0.28), Vector2(0, len * 0.5), Vector2(-w, -len * 0.28)]),
				Color(WHITE, 0.6 * form + 0.3 * form * sin(t * 40.0)))
			pd.draw_set_transform(Vector2.ZERO)
			pd.glow(tip, 18.0 * form, Color(PALE, 0.5 * form), 0.0)
		else:
			var s := t - Ult.SLAM
			# 화면을 세로로 가르는 일격
			var cf := 1.0 - clampf(s / 0.28, 0.0, 1.0)
			if cf > 0.0:
				pd.draw_rect(Rect2(tx - 26.0 * cf, fy - 420.0, 52.0 * cf, 460.0), Color(WHITE, cf))
				pd.glow(Vector2(tx, fy - 100.0), 160.0 * cf, Color(PALE, 0.4 * cf), 0.0)
			# 남아서 천천히 닫히는 공간의 금
			var close := 1.0 - clampf(s / (Ult.END - Ult.SLAM - 0.1), 0.0, 1.0)
			if close > 0.0:
				var pts := PackedVector2Array()
				var n := 14
				for i in n + 1:
					var y := lerpf(fy - 400.0, fy, float(i) / float(n))
					var jx := (5.0 if i % 2 == 0 else -5.0) * close + sin(float(i) * 1.7) * 2.0
					pts.append(Vector2(tx + jx, y))
				pd.draw_polyline(pts, Color(VIOLET, 0.7 * close), 7.0 * close + 1.0)
				pd.draw_polyline(pts, Color(WHITE, close), 3.0 * close + 0.6)
				pd.draw_rect(Rect2(tx - 40.0, fy - 2.0, 80.0, 3.0), Color(PALE, 0.6 * close))


## 기술명 현수막 (화면 고정)
class UltBanner extends Control:
	var u: Ult

	func _draw() -> void:
		var e := u.env()
		if e <= 0.0:
			return
		var font := get_theme_default_font()
		var txt := "종언참"
		var fs := 22
		var sz := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var cy := 64.0
		var slide := (1.0 - clampf(u.t / 0.18, 0.0, 1.0)) * 20.0
		draw_rect(Rect2(0, cy - 20, 640, 30), Color(0.02, 0.0, 0.05, 0.55 * e))
		draw_line(Vector2(320 - 140 + slide, cy - 20), Vector2(320 + 140 + slide, cy - 20), Color(VIOLET, 0.8 * e), 1.0)
		draw_line(Vector2(320 - 140 - slide, cy + 10), Vector2(320 + 140 - slide, cy + 10), Color(VIOLET, 0.8 * e), 1.0)
		var pos := Vector2(320 - sz.x * 0.5 + slide, cy + 2)
		draw_string_outline(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0.05, 0.0, 0.1, e))
		draw_string(font, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, e))
