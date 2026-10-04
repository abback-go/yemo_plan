extends RefCounted
## 2장 적 공용 도우미: 소리(새 소리 이름이 아직 없으면 1장 소리로), 그림 노드, 예고 뒤 터지는 공격(별기둥·유성·충격파),
## 별 조각 탄(불꽃 방벽으로 되쏠 수 있는 EnemyProjectile), 죽음 연출.
## `const KE := preload("res://enemies/ch2/k_enemy.gd")` 뒤 `KE.snd(...)`, `KE.Vis.new()` 처럼 쓴다.

const KArt := preload("res://world/entities/ch2/k_art.gd")
const STAR := Color("#c89aff")
const STAR_HOT := Color("#f0e0ff")
const TEAL := Color("#6af0e0")
const DANGER := Color("#ff3b3b")
const OUT := Color("#07060c")


## 효과음: docs/systems2.md 9절의 새 이름이 있으면 그것, 없으면 비슷한 1장 소리
static func snd(name: StringName, fallback: StringName = &"", vol := 0.0, pv := 0.06) -> void:
	EnemyBase.play_sfx(name, fallback, vol, pv)


## 두 색 사이 Gradient (같은 색이면 캐시된 같은 자원 — Palette.grad2)
static func grad(c0: Color, c1: Color) -> Gradient:
	return Palette.grad2(c0, c1)


## 별가루 폭발 (가산 합성)
static func star_burst(pos: Vector2, amount: int, col := STAR, speed := 120.0, life := 0.6) -> void:
	Fx.burst(pos, amount, {
		spread = 180.0, speed_min = speed * 0.3, speed_max = speed, damping = speed * 0.4, lifetime = life,
		gradient = grad(Color(STAR_HOT, 1.0), Color(col, 0.0)), size_min = 1.0, size_max = 2.5, gravity = Vector2(0, -20), add = true,
	})


## 돌·잔해 튐 (불투명)
static func debris(pos: Vector2, amount: int, col: Color, dir := Vector2.UP, speed := 140.0) -> void:
	Fx.burst(pos, amount, {
		direction = dir, spread = 70.0, speed_min = speed * 0.4, speed_max = speed, lifetime = 0.5,
		gradient = grad(col, Color(col, 0.0)), size_min = 1.5, size_max = 3.0, gravity = Vector2(0, 420),
	})


## 2장 적의 죽음: 별빛으로 흩어짐 (기본 영혼 입자 대신)
static func death_fx(pos: Vector2, col := STAR, big := false) -> void:
	star_burst(pos, 46 if big else 28, col, 200.0 if big else 150.0, 0.9)
	Fx.ring(pos, 4.0, 46.0 if big else 30.0, col, 0.4, 2.0)
	if big:
		Fx.ring(pos, 8.0, 90.0, Color(1, 1, 1, 0.8), 0.6, 3.0)
		Fx.flash(Color(col, 0.25), 0.2)


# ─── 그림 노드 ───────────────────────────────────────────

## 적이 넘겨준 그리기 함수(fn(c: Node2D))로 그리는 노드. flip이면 적의 facing으로 좌우를 뒤집는다
class Vis extends Node2D:
	var enemy: EnemyBase
	var fn: Callable
	var flip := true

	func _process(_d: float) -> void:
		var live := enemy != null and is_instance_valid(enemy)
		if live and flip:
			scale.x = float(enemy.facing)
		if not live or enemy.should_redraw(): # 화면에서 먼 적은 다시 그리지 않음
			queue_redraw()

	func _draw() -> void:
		if fn.is_valid():
			fn.call(self)


# ─── 예고 뒤 터지는 공격 ─────────────────────────────────

## 바닥에서 솟는 별기둥: 붉은 예고(타원 + 기둥 윤곽) → warn초 뒤 기둥이 솟음(active초 동안 피해)
class StarPillar extends EnemyAttackArea:
	var warn := 0.8
	var active_time := 0.35
	var w := 22.0
	var h := 120.0
	var col := STAR
	var _t := 0.0
	var _fired := false

	func setup(floor_pos: Vector2, p_warn: float, p_w := 22.0, p_h := 120.0, p_col := STAR) -> void:
		global_position = floor_pos
		warn = p_warn
		w = p_w
		h = p_h
		col = p_col

	func _ready() -> void:
		cause = &"star_pillar"
		damage = 1
		dodgeable = true
		active = false
		z_index = 4
		var s := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(w * 0.8, h)
		s.shape = r
		s.position = Vector2(0, -h * 0.5)
		add_child(s)
		KE_snd(&"star_twinkle", &"pillar_warn", -6.0)

	func KE_snd(n: StringName, fb: StringName, vol: float) -> void:
		EnemyBase.play_sfx(n, fb, vol)

	func _physics_process(delta: float) -> void:
		_t += delta * Fx.enemy_time
		if not _fired and _t >= warn:
			_fired = true
			active = true
			KE_snd(&"star_burst", &"pillar", -2.0)
			Fx.shake(0.12, 0.15)
			Fx.burst(global_position + Vector2(0, -6), 16, {
				direction = Vector2.UP, spread = 25.0, speed_min = 80.0, speed_max = 220.0, lifetime = 0.5,
				gradient = Palette.fade_gradient(col.lightened(0.3)), size_min = 1.0, size_max = 2.5, gravity = Vector2(0, -60), add = true,
			})
		if _fired and _t >= warn + active_time:
			active = false
		if _t >= warn + active_time + 0.25:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		if not _fired:
			var k := clampf(_t / warn, 0.0, 1.0)
			var pulse := 0.6 + 0.4 * sin(_t * 28.0)
			var rw := w * (0.6 + 0.4 * k)
			draw_set_transform(Vector2(0, -2), 0.0, Vector2(1.0, 0.32))
			draw_arc(Vector2.ZERO, rw * 0.7, 0, TAU, 20, Color(DANGER, (0.4 + 0.5 * k) * pulse), 2.0)
			draw_circle(Vector2.ZERO, rw * 0.5 * k, Color(DANGER, 0.25 * pulse))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_rect(Rect2(-w * 0.4, -h, 1, h), Color(DANGER, 0.12 * k))
			draw_rect(Rect2(w * 0.4, -h, 1, h), Color(DANGER, 0.12 * k))
			return
		var at := _t - warn
		var life := active_time + 0.25
		var kk := clampf(1.0 - at / life, 0.0, 1.0)
		var grow := clampf(at / 0.06, 0.0, 1.0)
		var top := -h * grow
		draw_rect(Rect2(-w * 0.5 * kk, top, w * kk, -top), Color(col, 0.35 * kk))
		draw_rect(Rect2(-w * 0.3 * kk, top, w * 0.6 * kk, -top), Color(col.lightened(0.4), 0.6 * kk))
		draw_rect(Rect2(-1.5, top, 3, -top), Color(1, 1, 1, 0.9 * kk))
		for i in 5:
			var y := fmod(at * 300.0 + i * 31.0, h)
			KArtStar.draw(self, Vector2(sin(i * 2.0) * w * 0.3, -y), 2.5 * kk, Color(1, 0.95, 1.0, kk))


## 하늘에서 떨어지는 유성: 바닥에 붉은 원 → 위에서 불덩이 별이 떨어져 폭발 (반지름 radius)
class MeteorDrop extends EnemyAttackArea:
	var warn := 1.0
	var radius := 26.0
	var col := STAR
	var big := false
	var harmless := false
	var _t := 0.0
	var _done := false
	var _boom_t := 0.0
	const FALL := 0.35

	func setup(floor_pos: Vector2, p_warn: float, p_radius := 26.0, p_col := STAR) -> void:
		global_position = floor_pos
		warn = p_warn
		radius = p_radius
		col = p_col

	func _ready() -> void:
		cause = &"meteor"
		damage = 2 if big else 1
		dodgeable = true
		active = false
		z_index = 4
		var s := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = radius
		s.shape = c
		s.position = Vector2(0, -radius * 0.4)
		add_child(s)

	func _physics_process(delta: float) -> void:
		_t += delta * Fx.enemy_time
		if not _done and _t >= warn:
			_done = true
			active = not harmless
			_boom_t = 0.0
			if Sfx.has_sound(&"meteor_impact"):
				Sfx.play(&"meteor_impact", -2.0 if not big else 2.0)
			else:
				Sfx.play(&"explode", -6.0 if not big else 0.0)
			Fx.shake(0.25 if not big else 0.6, 0.25)
			Fx.burst(global_position + Vector2(0, -4), 24 if not big else 50, {
				direction = Vector2.UP, spread = 80.0, speed_min = 60.0, speed_max = 220.0 if not big else 320.0, lifetime = 0.6,
				gradient = Palette.fade_gradient(col.lightened(0.4)), size_min = 1.5, size_max = 3.0, gravity = Vector2(0, 300), add = true,
			})
			Fx.burst(global_position, 10, {
				direction = Vector2.UP, spread = 60.0, speed_min = 60.0, speed_max = 160.0, lifetime = 0.6,
				gradient = Palette.fade_gradient(Color("#4a4458")), size_min = 2.0, size_max = 3.5, gravity = Vector2(0, 500),
			})
			Fx.ring(global_position + Vector2(0, -6), 6.0, radius * 1.6, col, 0.35, 3.0)
		if _done:
			_boom_t += delta
			if _boom_t > 0.12:
				active = false
			if _boom_t > 0.45:
				queue_free()
		queue_redraw()

	func _draw() -> void:
		if not _done:
			var k := clampf(_t / warn, 0.0, 1.0)
			var pulse := 0.6 + 0.4 * sin(_t * 26.0)
			draw_set_transform(Vector2(0, -2), 0.0, Vector2(1.0, 0.3))
			draw_arc(Vector2.ZERO, radius, 0, TAU, 28, Color(DANGER, (0.35 + 0.55 * k) * pulse), 2.0)
			draw_circle(Vector2.ZERO, radius * k, Color(DANGER, 0.22 * pulse))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			# 떨어지는 별 (마지막 FALL초)
			var fk := clampf((_t - (warn - FALL)) / FALL, 0.0, 1.0)
			if fk > 0.0:
				var start := Vector2(-radius * 2.0, -320.0)
				var p := start.lerp(Vector2(0, -radius * 0.3), fk * fk)
				var dir := (Vector2(0, 0) - start).normalized()
				var r := (7.0 if not big else 16.0)
				for i in 6:
					var tp := p - dir * i * r * 0.9
					draw_circle(tp, r * (1.0 - i * 0.14), Color(col, 0.5 - i * 0.07))
				draw_circle(p, r, Color("#3a3048"))
				draw_circle(p, r * 0.7, Color(col.lightened(0.3), 0.9))
				draw_circle(p, r * 0.35, Color.WHITE)
			return
		var kk := clampf(1.0 - _boom_t / 0.45, 0.0, 1.0)
		draw_circle(Vector2(0, -radius * 0.3), radius * (1.0 + (1.0 - kk) * 0.3), Color(col, 0.45 * kk))
		draw_circle(Vector2(0, -radius * 0.3), radius * 0.6 * kk, Color(1, 0.95, 1.0, 0.8 * kk))


## 땅을 따라 달리는 충격파 (검압 파동·전기 고리·쿵 내려찍기). 점프로 넘는다. dir = -1·1, height = 판정 높이(px)
class GroundWave extends EnemyAttackArea:
	var dir := 1
	var speed := 260.0
	var max_dist := 420.0
	var height := 20.0
	var col := Color(0.92, 0.95, 1.0)
	var style := "sword" # sword(흰 검압) · spark(청록 전기) · rock(돌 파편)
	var _t := 0.0
	var _dist := 0.0

	func setup(floor_pos: Vector2, p_dir: int, p_speed := 260.0, p_dist := 420.0, p_style := "sword") -> void:
		global_position = floor_pos
		dir = p_dir
		speed = p_speed
		max_dist = p_dist
		style = p_style
		match style:
			"spark": col = TEAL
			"rock": col = Color("#c8b8e0")

	func _ready() -> void:
		cause = &"wave"
		damage = 1
		dodgeable = true
		z_index = 4
		var s := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(16, height - 3.0)
		s.shape = r
		s.position = Vector2(0, -height * 0.5 - 1.5) # 바닥에 닿지 않게 살짝 띄움 (바닥에 닿으면 벽으로 여겨 사라짐)
		add_child(s)
		monitoring = true
		collision_mask = GameConst.L_WORLD
		body_entered.connect(func(_b: Node) -> void: _end())

	func _end() -> void:
		if not active:
			return
		active = false
		set_deferred("monitoring", false)
		Fx.burst(global_position + Vector2(0, -6), 10, {spread = 120.0, direction = Vector2(-dir, -1), speed_min = 40.0, speed_max = 120.0,
			lifetime = 0.3, gradient = Palette.fade_gradient(col), add = true})
		var tw := create_tween()
		tw.tween_interval(0.12)
		tw.tween_callback(queue_free)

	func _physics_process(delta: float) -> void:
		if not active:
			return
		var d := delta * Fx.enemy_time
		_t += d
		var step := speed * d
		# 바닥이 끊기면 사라짐
		var space := get_world_2d().direct_space_state
		var from := global_position + Vector2(dir * 8.0, -4.0)
		var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 14), GameConst.L_WORLD | GameConst.L_PLATFORM)
		if space.intersect_ray(q).is_empty():
			_end()
			return
		global_position.x += dir * step
		_dist += step
		if _dist >= max_dist:
			_end()
		if int(_t * 30.0) % 2 == 0:
			Fx.burst(global_position + Vector2(0, -2), 2, {direction = Vector2(-dir, -1), spread = 30.0, speed_min = 20.0,
				speed_max = 60.0, lifetime = 0.3, gradient = Palette.fade_gradient(col), size_min = 1.0, size_max = 2.0, add = style != "rock"})
		queue_redraw()

	func _draw() -> void:
		var flick := 0.8 + 0.2 * sin(_t * 40.0)
		match style:
			"spark":
				for i in 4:
					var y := -2.0 - i * 4.0
					var pts := PackedVector2Array()
					for k in 5:
						pts.append(Vector2(-8 + k * 4, y + (randf() - 0.5) * 4.0))
					draw_polyline(pts, Color(col, 0.9 * flick), 1.0)
				draw_rect(Rect2(-8, -1, 16, 2), Color(1, 1, 1, 0.8))
			"rock":
				for i in 4:
					var x := -6.0 + i * 4.0
					var hh := 6.0 + (i % 2) * 6.0
					draw_colored_polygon(PackedVector2Array([Vector2(x - 2, 0), Vector2(x, -hh), Vector2(x + 2, 0)]), Color("#5a5068"))
				draw_rect(Rect2(-8, -2, 16, 2), Color(col, 0.7))
			_:
				# 초승달 모양 흰 검압 (진행 방향으로 볼록)
				var pts2 := PackedVector2Array()
				for k in 9:
					var a := -PI * 0.5 + PI * k / 8.0
					pts2.append(Vector2(cos(a) * 9.0 * dir, -height * 0.5 + sin(a) * height * 0.5))
				for k in range(8, -1, -1):
					var a2 := -PI * 0.5 + PI * k / 8.0
					pts2.append(Vector2(cos(a2) * 4.0 * dir - dir * 3.0, -height * 0.5 + sin(a2) * height * 0.42))
				draw_colored_polygon(pts2, Color(col, 0.75 * flick))
				draw_line(Vector2(-dir * 14.0, -2), Vector2(0, -2), Color(col, 0.4), 2.0)
				draw_line(Vector2(dir * 6.0, -height * 0.85), Vector2(dir * 6.0, -height * 0.15), Color(1, 1, 1, 0.9), 1.0)


## 작은 별 그리기 (내부 클래스에서 쓰는 정적 도우미)
class KArtStar:
	static func draw(c: CanvasItem, pos: Vector2, s: float, col: Color) -> void:
		c.draw_colored_polygon(PackedVector2Array([
			pos + Vector2(0, -s), pos + Vector2(s * 0.22, -s * 0.22), pos + Vector2(s, 0), pos + Vector2(s * 0.22, s * 0.22),
			pos + Vector2(0, s), pos + Vector2(-s * 0.22, s * 0.22), pos + Vector2(-s, 0), pos + Vector2(-s * 0.22, -s * 0.22),
		]), col)


# ─── 별 조각 탄 ─────────────────────────────────────────

## 빙글 도는 별 조각 (보랏빛 꼬리). EnemyProjectile이라 불꽃 방벽에 되쏘아진다
class StarShard extends EnemyProjectile:
	var tint := STAR

	func _ready() -> void:
		super()
		material = Fx.add_material

	func _color() -> Color:
		return Palette.FIRE_HOT if reflected else tint

	func _draw() -> void:
		if reflected:
			super() # 되쏘아진 뒤에는 세라의 불빛으로
			return
		var prev := Vector2.ZERO
		for i in _trail.size():
			var p := to_local(_trail[i])
			var k := 1.0 - float(i) / _trail.size()
			draw_line(prev, p, Color(tint, 0.5 * k), radius * 1.3 * k + 0.5)
			prev = p
		var s := radius + 2.0
		var rot := _spin
		var pts := PackedVector2Array()
		for i in 8:
			var a := rot + TAU * i / 8.0
			var rr := s if i % 2 == 0 else s * 0.38
			pts.append(Vector2(cos(a), sin(a)) * rr)
		draw_colored_polygon(pts, tint)
		draw_circle(Vector2.ZERO, radius * 0.5, Color(1, 0.97, 1.0))


static func shard(pos: Vector2, dir: Vector2, speed: float, opts := {}, tint := STAR) -> EnemyProjectile:
	var pr := StarShard.new()
	pr.tint = tint
	var o := opts.duplicate()
	if not o.has("radius"):
		o["radius"] = 3.5
	if not o.has("cause"):
		o["cause"] = "star_shard"
	pr.setup(pos, dir, speed, "star", o)
	Fx.effect_parent().add_child(pr)
	return pr


static func pillar(floor_pos: Vector2, warn: float, w := 22.0, h := 120.0, col := STAR) -> StarPillar:
	var p := StarPillar.new()
	p.setup(floor_pos, warn, w, h, col)
	Fx.effect_parent().add_child(p)
	return p


static func meteor(floor_pos: Vector2, warn: float, radius := 26.0, col := STAR, big := false) -> MeteorDrop:
	var m := MeteorDrop.new()
	m.setup(floor_pos, warn, radius, col)
	m.big = big
	Fx.effect_parent().add_child(m)
	return m


static func wave(floor_pos: Vector2, dir: int, speed := 260.0, dist := 420.0, style := "sword", height := 20.0) -> GroundWave:
	var g := GroundWave.new()
	g.height = height
	g.setup(floor_pos, dir, speed, dist, style)
	Fx.effect_parent().add_child(g)
	return g


## 바닥 찾기: x 위치에서 아래로 (없으면 ref_y)
static func floor_at(node: Node2D, x: float, ref_y: float, depth := 160.0) -> float:
	var space := node.get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(Vector2(x, ref_y - 40.0), Vector2(x, ref_y + depth), GameConst.L_WORLD | GameConst.L_PLATFORM)
	var r := space.intersect_ray(q)
	if r.is_empty():
		return ref_y
	var p: Vector2 = r.position
	return p.y


## 예고용 붉은 깜빡임 세기 (0~1, 진행도 k가 오를수록 진하고 빠르게)
static func warn_pulse(t: float, k: float) -> float:
	return clampf((0.45 + 0.55 * k) * (0.6 + 0.4 * sin(t * (18.0 + 22.0 * k))), 0.0, 1.0)
