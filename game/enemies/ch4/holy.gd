extends RefCounted
## 4장 적·장치 공용 도우미 (docs/chapter4.md 7.4절). `const H := preload("res://enemies/ch4/holy.gd")`
##   소리: H.snd(이름, 대체) — 오디오 담당이 만들 소리(holy_charge, bell 등)가 아직 없으면 1장 소리로 대신 낸다
##   빛: H.gold_grad(), H.white_grad(), H.sparkle()
##   탄: H.HolyShot (EnemyProjectile 상속 → 불꽃 방벽에 자동으로 되쏘아짐) 모양 orb·lance·reflect·shard
##   선 판정: H.SegmentArea (기울어진 긴 직사각형 공격 영역 — 빛줄기·돌진 띠)
##   낙하 창: H.LanceDrop (붉은 예고선 → 금빛 창이 떨어져 꽂힘)
##   빛줄기 추적: H.trace(...) — 벽에서 멈추고 거울(light_mirror)에서 꺾이고 수정(light_crystal)을 밝히며, 방벽에 닿으면 세라가 보는 쪽으로 되쏨

const GOLD := Color(1.0, 0.86, 0.45)
const GOLD_DEEP := Color(1.0, 0.7, 0.25)
const WHITE := Color(1.0, 0.98, 0.9)
const DANGER := Color("#ff3b3b")
const WARD_RADIUS := 32.0


## 대체 소리가 있는지 확인하지 않는다 (KE.snd·StArt.sfx와 다른 점 — 예전 동작 그대로)
static func snd(name: StringName, fallback: StringName, vol := 0.0, variation := 0.06) -> void:
	EnemyBase.play_sfx(name, fallback, vol, variation, false)


static func snd_pitch(name: StringName, fallback: StringName, pitch: float, vol := 0.0) -> void:
	EnemyBase.play_sfx_pitch(name, fallback, pitch, vol, false)


## 금빛·흰빛 파티클 색 (캐시된 같은 자원을 돌려줌 — 고치지 말 것)
static func gold_grad() -> Gradient:
	return Palette.cached_gradient(PackedFloat32Array([0.0, 0.35, 1.0]),
		PackedColorArray([Color(1, 1, 0.95), GOLD, Color(GOLD_DEEP, 0.0)]))


static func white_grad() -> Gradient:
	return Palette.cached_gradient(PackedFloat32Array([0.0, 0.5, 1.0]),
		PackedColorArray([Color.WHITE, Color(0.92, 0.94, 1.0), Color(0.8, 0.85, 1.0, 0.0)]))


## 금빛 반짝임 (가산)
static func sparkle(pos: Vector2, amount: int, radius := 10.0, up := 40.0, life := 0.6, white := false) -> void:
	Fx.burst(pos, amount, {
		spread = 180.0, speed_min = 10.0, speed_max = 60.0, lifetime = life, radius = radius,
		gradient = white_grad() if white else gold_grad(), size_min = 1.0, size_max = 2.5, gravity = Vector2(0, -up), add = true,
	})


static func player() -> Player:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group(GameConst.GROUP_PLAYER) as Player


## 세라가 불꽃 방벽을 펼친 중인가 (공통 시스템이 아직 없으면 false)
static func player_warding(p: Player) -> bool:
	return p != null and p.has_method("is_warding") and bool(p.call("is_warding"))


static func ward_center(p: Player) -> Vector2:
	if p != null and p.has_method("ward_center"):
		return p.call("ward_center")
	return p.center() if p else Vector2.ZERO


# ═══════════════════════════════════════════════════════════
# 신성 탄
# ═══════════════════════════════════════════════════════════

## 금빛 탄. EnemyProjectile을 상속하므로 공통 시스템의 불꽃 방벽이 그대로 되쏠 수 있다.
## look: orb(금빛 구) · lance(작은 빛의 창) · reflect(수도사 방패가 되돌려 보낸 화염탄 — 금테 두른 붉은 불) · shard(백금 기하 조각)
class HolyShot extends EnemyProjectile:
	var look := "orb"

	func _ready() -> void:
		super()
		material = Fx.add_material

	func _color() -> Color:
		match look:
			"reflect": return Color(1.0, 0.55, 0.3)
			"shard": return Color(0.92, 0.94, 1.0)
		return Color(1.0, 0.86, 0.45)

	func _draw() -> void:
		var c := _color()
		var prev := Vector2.ZERO
		for i in _trail.size():
			var p := to_local(_trail[i])
			var k := 1.0 - float(i) / maxf(_trail.size(), 1.0)
			draw_line(prev, p, Color(c, 0.5 * k), radius * 1.4 * k + 0.5)
			prev = p
		var d := _vel.normalized() if _vel.length() > 1.0 else Vector2.RIGHT
		var n := Vector2(-d.y, d.x)
		match look:
			"lance":
				draw_line(-d * 9.0, d * 7.0, Color(c, 0.4), 5.0)
				draw_colored_polygon(PackedVector2Array([d * 9.0, n * 2.5, -d * 6.0, -n * 2.5]), c)
				draw_line(-d * 5.0, d * 8.0, Color(1, 1, 0.95), 1.0)
			"reflect":
				draw_circle(Vector2.ZERO, radius + 3.0, Color(1.0, 0.85, 0.4, 0.35))
				draw_circle(Vector2.ZERO, radius + 1.0, c)
				draw_circle(Vector2.ZERO, radius * 0.5, Color(1, 1, 0.9))
				draw_arc(Vector2.ZERO, radius + 2.0, _spin, _spin + 2.0, 6, Color(1.0, 0.95, 0.6), 1.0)
			"shard":
				var r := radius + 1.0
				draw_colored_polygon(PackedVector2Array([d * r * 1.6, n * r * 0.7, -d * r, -n * r * 0.7]), Color(c, 0.9))
				draw_line(-d * r, d * r * 1.6, Color.WHITE, 1.0)
			_:
				draw_circle(Vector2.ZERO, radius + 2.5, Color(c, 0.3))
				draw_circle(Vector2.ZERO, radius, c)
				draw_circle(Vector2.ZERO, radius * 0.45, Color(1, 1, 0.95))


static func shoot(pos: Vector2, dir: Vector2, speed: float, look := "orb", opts := {}) -> HolyShot:
	var s := HolyShot.new()
	s.look = look
	s.setup(pos, dir, speed, "holy", opts)
	Fx.effect_parent().add_child(s)
	return s


# ═══════════════════════════════════════════════════════════
# 기울어진 선 공격 영역
# ═══════════════════════════════════════════════════════════

## a → b (전역) 굵기 width의 공격 판정. 빛줄기·돌진 띠에 쓴다.
class SegmentArea extends EnemyAttackArea:
	var _cs: CollisionShape2D
	var _rs: RectangleShape2D

	func _init() -> void:
		super()
		_cs = CollisionShape2D.new()
		_rs = RectangleShape2D.new()
		_rs.size = Vector2(4, 4)
		_cs.shape = _rs
		add_child(_cs)
		top_level = true

	func set_segment(a: Vector2, b: Vector2, width: float) -> void:
		var len := maxf(a.distance_to(b), 1.0)
		global_position = (a + b) * 0.5
		rotation = (b - a).angle()
		_rs.size = Vector2(len, width)


# ═══════════════════════════════════════════════════════════
# 떨어지는 빛의 창 (빛의 창 비)
# ═══════════════════════════════════════════════════════════

## 바닥 x에 붉은 예고(warn초) → 하늘에서 금빛 창이 내리꽂힘 (피해 damage, 대시로 스치면 퍼펙트 회피). white = 폭주(흰금)
class LanceDrop extends EnemyAttackArea:
	const FALL := 0.16
	const LINGER := 0.22
	var floor_y := 0.0
	var top_y := 0.0
	var warn := 0.8
	var white := false
	var big := false
	var _t := 0.0
	var _hit := false

	func setup(x: float, p_floor_y: float, p_top_y: float, p_warn: float, p_damage := 1, p_white := false, p_big := false) -> void:
		global_position = Vector2(x, p_floor_y)
		floor_y = p_floor_y
		top_y = p_top_y
		warn = p_warn
		damage = p_damage
		white = p_white
		big = p_big
		cause = &"aurelia_lance"

	func _ready() -> void:
		active = false
		dodgeable = true
		z_index = 6
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(14.0 if not big else 26.0, 40.0)
		cs.shape = rs
		cs.position = Vector2(0, -20)
		add_child(cs)

	func _physics_process(delta: float) -> void:
		_t += delta * Fx.enemy_time
		active = _t >= warn and _t < warn + LINGER
		if _t >= warn and not _hit:
			_hit = true
			Fx.shake(0.12 if not big else 0.3, 0.15)
			Fx.burst(global_position + Vector2(0, -2), 14 if not big else 30, {
				direction = Vector2.UP, spread = 70.0, speed_min = 40.0, speed_max = 160.0, lifetime = 0.45,
				gradient = (H_white() if white else H_gold()), size_min = 1.0, size_max = 3.0, gravity = Vector2(0, 300), add = true,
			})
			Fx.ring(global_position + Vector2(0, -4), 3.0, 22.0 if not big else 40.0, Color(1.0, 0.9, 0.6), 0.25, 2.0)
			Sfx.play(&"pillar" if big else &"hit", -6.0, 0.15)
		if _t >= warn + LINGER + 0.35:
			queue_free()
		queue_redraw()

	static func H_gold() -> Gradient:
		return Palette.cached_gradient(PackedFloat32Array([0.0, 0.35, 1.0]),
			PackedColorArray([Color(1, 1, 0.95), Color(1.0, 0.86, 0.45), Color(1.0, 0.7, 0.25, 0.0)]))

	static func H_white() -> Gradient:
		return Palette.cached_gradient(PackedFloat32Array([0.0, 1.0]), PackedColorArray([Color.WHITE, Color(0.9, 0.92, 1.0, 0.0)]))

	func _draw() -> void:
		var fy := 0.0
		var ty := top_y - floor_y
		var w := 10.0 if not big else 20.0
		var pulse := 0.6 + 0.4 * sin(_t * 28.0)
		if _t < warn:
			var k := clampf(_t / warn, 0.0, 1.0)
			# 붉은 예고: 떨어질 줄기 + 바닥 표식
			draw_rect(Rect2(-1, ty, 2, fy - ty), Color(1.0, 0.25, 0.2, 0.12 + 0.25 * k))
			draw_rect(Rect2(-w * 0.5 - 2, fy - 3, w + 4, 3), Color(1.0, 0.23, 0.23, (0.4 + 0.5 * k) * pulse))
			draw_rect(Rect2(-w * 0.5 - 4, fy - 8, 2, 8), Color(1.0, 0.23, 0.23, 0.6 * k))
			draw_rect(Rect2(w * 0.5 + 2, fy - 8, 2, 8), Color(1.0, 0.23, 0.23, 0.6 * k))
			# 하늘에 모이는 창 (끝 무렵)
			if k > 0.55:
				var a := (k - 0.55) / 0.45
				var col := Color(1, 1, 1, a) if white else Color(1.0, 0.9, 0.55, a)
				draw_colored_polygon(PackedVector2Array([Vector2(0, ty + 30), Vector2(-3, ty + 8), Vector2(0, ty), Vector2(3, ty + 8)]), col)
			return
		var e := _t - warn
		var fall := clampf(e / FALL, 0.0, 1.0)
		var tipy := lerpf(ty + 30.0, fy, fall)
		var col2 := Color.WHITE if white else Color(1.0, 0.9, 0.55)
		var fade := clampf(1.0 - (e - LINGER) / 0.35, 0.0, 1.0)
		var L := 40.0 if not big else 70.0
		draw_rect(Rect2(-w * 0.9, tipy - L * 1.6, w * 1.8, L * 1.6), Color(col2, 0.12 * fade))
		draw_colored_polygon(PackedVector2Array([Vector2(0, tipy), Vector2(-w * 0.35, tipy - L * 0.35), Vector2(-w * 0.12, tipy - L), Vector2(w * 0.12, tipy - L), Vector2(w * 0.35, tipy - L * 0.35)]), Color(col2, fade))
		draw_line(Vector2(0, tipy - L * 0.9), Vector2(0, tipy - 2), Color(1, 1, 1, fade), 1.0)
		for s: float in [-1.0, 1.0]:
			draw_colored_polygon(PackedVector2Array([Vector2(s * w * 0.3, tipy - L * 0.32), Vector2(s * w * 0.95, tipy - L * 0.5), Vector2(s * w * 0.3, tipy - L * 0.45)]), Color(col2, fade * 0.9))


static func lance_drop(x: float, floor_y: float, top_y: float, warn: float, damage := 1, white := false, big := false) -> LanceDrop:
	var l := LanceDrop.new()
	l.setup(x, floor_y, top_y, warn, damage, white, big)
	Fx.effect_parent().add_child(l)
	return l


## x 위치 아래쪽 바닥 (L_WORLD·발판), 없으면 INF
static func floor_below(space: PhysicsDirectSpaceState2D, at: Vector2, depth := 400.0) -> float:
	var r := space.intersect_ray(PhysicsRayQueryParameters2D.create(at, at + Vector2(0, depth), GameConst.L_WORLD | GameConst.L_PLATFORM))
	if r.is_empty():
		return INF
	var p: Vector2 = r.position
	return p.y


static func ceiling_above(space: PhysicsDirectSpaceState2D, at: Vector2, height := 400.0) -> float:
	var r := space.intersect_ray(PhysicsRayQueryParameters2D.create(at, at - Vector2(0, height), GameConst.L_WORLD))
	if r.is_empty():
		return at.y - height
	var p: Vector2 = r.position
	return p.y


# ═══════════════════════════════════════════════════════════
# 빛줄기 추적 (거울·수정·방벽)
# ═══════════════════════════════════════════════════════════

## from에서 dir로 max_len까지 빛을 쏜다. 꺾인 점들을 돌려준다 [from, p1, ...].
## notify면 닿은 수정(light_crystal)의 light_hit(delta)를 부른다. 세라가 방벽 중이면 세라가 보는 쪽(수평)으로 되쏜다.
static func trace(space: PhysicsDirectSpaceState2D, from: Vector2, dir: Vector2, max_len: float, notify := false, delta := 0.0, bounces := 6) -> PackedVector2Array:
	var tree := Engine.get_main_loop() as SceneTree
	var pts := PackedVector2Array([from])
	var pos := from
	var d := dir.normalized()
	var remaining := max_len
	var ignore: Node = null
	var ward_used := false
	var p := player()
	for step in bounces + 1:
		if remaining <= 1.0:
			break
		var end := pos + d * remaining
		var best_t := INF
		var best_kind := ""
		var best_node: Node = null
		var wr := space.intersect_ray(PhysicsRayQueryParameters2D.create(pos, end, GameConst.L_WORLD))
		if not wr.is_empty():
			var wp: Vector2 = wr.position
			best_t = pos.distance_to(wp)
			best_kind = "wall"
		for m in tree.get_nodes_in_group(&"light_mirror"):
			if m == ignore or not m.has_method("segment"):
				continue
			var seg: Array = m.call("segment")
			var hit: Variant = Geometry2D.segment_intersects_segment(pos, end, seg[0], seg[1])
			if hit != null:
				var hp: Vector2 = hit
				var dist := pos.distance_to(hp)
				if dist > 0.5 and dist < best_t:
					best_t = dist
					best_kind = "mirror"
					best_node = m
		for c in tree.get_nodes_in_group(&"light_crystal"):
			if not c.has_method("light_hit"):
				continue
			var cc: Vector2 = c.call("center")
			var cr: float = c.get("radius")
			var f := Geometry2D.segment_intersects_circle(pos, end, cc, cr)
			if f >= 0.0:
				var dist2 := f * remaining
				if dist2 < best_t:
					best_t = dist2
					best_kind = "crystal"
					best_node = c
		if not ward_used and player_warding(p):
			var f2 := Geometry2D.segment_intersects_circle(pos, end, ward_center(p), WARD_RADIUS)
			if f2 >= 0.0 and f2 * remaining < best_t:
				best_t = f2 * remaining
				best_kind = "ward"
		if best_kind == "":
			pts.append(end)
			break
		var hp2 := pos + d * best_t
		pts.append(hp2)
		remaining -= best_t
		match best_kind:
			"wall":
				break
			"crystal":
				if notify:
					best_node.call("light_hit", delta)
				break
			"mirror":
				d = best_node.call("reflect_dir", d)
				pos = hp2 + d * 0.5
				ignore = best_node
			"ward":
				ward_used = true
				d = Vector2(float(p.facing), 0.0)
				pos = hp2 + d * 2.0
				ignore = null
				if notify and p.has_method("on_ward_block"):
					p.call("on_ward_block", &"light")
	return pts


## 빛줄기 그리기 (가산 노드에서): 바깥 빛 + 심
static func draw_beam(c: CanvasItem, pts: PackedVector2Array, width: float, col: Color, core: Color, flicker := 1.0) -> void:
	if pts.size() < 2:
		return
	c.draw_polyline(pts, Color(col, 0.18 * flicker), width * 2.6)
	c.draw_polyline(pts, Color(col, 0.55 * flicker), width)
	c.draw_polyline(pts, Color(core, 0.95 * flicker), maxf(width * 0.35, 1.0))
	for i in range(1, pts.size() - 1):
		c.draw_circle(pts[i], width * 0.9, Color(core, 0.6 * flicker))
