class_name BlightSpore
extends EnemyBase
## 역병 포자 덩어리 (docs/chapter3.md 4절) — 흰 역병이 뭉쳐 자란 붙박이 덩어리. 움직이지 않는다.
## 주기적으로 부풀어 하얗게 빛나다가(예고) 포자 셋을 포물선으로 뱉는다 → 떨어진 자리에 하얀 바닥(역병 웅덩이).
## 하얀 바닥: 밟으면 느려지고(좌우 속도 55%), 1.6초 이상 서 있으면 1 피해. 6초 뒤 사그라든다.
## 불로 태우면(불기둥·화염 폭풍·화염탄 등 불 종류) 바닥이 즉시 타서 사라진다. 덩어리를 쓰러뜨리면 바닥도 모두 사라진다.
## 공략: 불기둥으로 덩어리와 발밑 웅덩이를 한꺼번에. 몸통 피해 100%, 부풀었을 때(예고 중) 150%.

enum S { IDLE, SWELL, PUFF }

const HP := 560
const SWELL_TIME := 0.9
const PUFF_TIME := 0.35
const GAP := Vector2(2.6, 3.4)
const SPORES := 3
const FLIGHT := 0.8
const ZONE_LIFE := 6.0
const ZONE_W := 40.0

var state: S = S.IDLE
var _timer := 1.5
var _dur := 1.0
var _zones: Array[Node] = []


func _build() -> void:
	max_hp = HP
	body_size = Vector2(26, 20)
	knock_mult = 0.0
	launch_mult = 0.0
	kind_id = "blight_spore"
	display_name = "역병 포자 덩어리"
	subtitle = "숨을 쉬는 흰 곰팡이"
	_visual = SporeVisual.new()
	(_visual as SporeVisual).enemy = self
	add_child(_visual)
	var c := add_attack_area(Vector2(22, 14), Vector2(0, -8), &"blight_spore")
	c.dodgeable = false
	_timer = randf_range(1.0, 2.0)


func swell_k() -> float:
	return clampf(1.0 - _timer / _dur, 0.0, 1.0) if state == S.SWELL else 0.0


func _ai(delta: float) -> void:
	velocity.x = 0.0
	_timer -= delta
	var p := player()
	if not engaged or p == null or not p.is_alive():
		return
	match state:
		S.IDLE:
			if _timer <= 0.0 and dist_to_player() < 15.0 * GameConst.TILE:
				state = S.SWELL
				_dur = Difficulty.telegraph(SWELL_TIME)
				_timer = _dur
				Ch3Sfx.play(&"ch3_glass_low", -10.0, 0.1)
		S.SWELL:
			if _timer <= 0.0:
				state = S.PUFF
				_timer = PUFF_TIME
				_puff(p)
		S.PUFF:
			if _timer <= 0.0:
				state = S.IDLE
				_timer = Difficulty.rest(randf_range(GAP.x, GAP.y))


func _puff(p: Player) -> void:
	Ch3Sfx.play(&"ch3_spore", 0.0, 0.1)
	Fx.burst(global_position + Vector2(0, -18), 20, {direction = Vector2.UP, spread = 70.0, speed_min = 30.0, speed_max = 90.0,
		lifetime = 0.6, gradient = Palette.fade_gradient(Color(0.95, 0.95, 1.0)), size_min = 1.5, size_max = 3.0, gravity = Vector2(0, 40)})
	# 세라 자리와 그 양옆으로 하나씩
	var xs := [p.global_position.x, p.global_position.x - 56.0, p.global_position.x + 56.0]
	for i in SPORES:
		var tx: float = xs[i]
		var b := SporeBlob.new()
		b.setup(self, global_position + Vector2(0, -20), Vector2(tx, global_position.y), FLIGHT + i * 0.08)
		Fx.effect_parent().add_child(b)


## 포자가 땅에 닿아 하얀 바닥이 생김
func make_zone(at: Vector2) -> void:
	# 바닥 높이 찾기
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(at + Vector2(0, -24), at + Vector2(0, 200), GameConst.L_WORLD | GameConst.L_PLATFORM)
	var r := space.intersect_ray(q)
	var ground := at if r.is_empty() else (r.position as Vector2)
	var z := BlightZone.new()
	z.setup(ground, ZONE_W, ZONE_LIFE)
	Fx.effect_parent().add_child(z)
	_zones.append(z)


func modify_damage(_hit: Hit) -> float:
	return 1.5 if state == S.SWELL else 1.0


func _die(dir: int) -> void:
	for z in _zones:
		if is_instance_valid(z):
			(z as BlightZone).burn()
	_zones.clear()
	Ch3Sfx.play(&"ch3_crystal_break", -2.0, 0.1)
	super(dir)


## 포물선으로 날아가는 포자 하나
class SporeBlob extends Node2D:
	var owner_spore: WeakRef
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var dur := 0.8
	var _t := 0.0

	func setup(o: Node, p_from: Vector2, p_to: Vector2, p_dur: float) -> void:
		owner_spore = weakref(o)
		from = p_from
		to = p_to
		dur = p_dur
		global_position = from
		z_index = 5

	func _physics_process(delta: float) -> void:
		_t += delta * Fx.enemy_time
		var k := clampf(_t / dur, 0.0, 1.0)
		global_position = from.lerp(to, k) + Vector2(0, -sin(k * PI) * 70.0)
		if k >= 1.0:
			var o: Node = owner_spore.get_ref()
			if o and o is BlightSpore:
				(o as BlightSpore).make_zone(to)
			Fx.burst(to, 8, {direction = Vector2.UP, spread = 60.0, speed_min = 20.0, speed_max = 50.0, lifetime = 0.4,
				gradient = Palette.fade_gradient(Color(0.95, 0.95, 1.0)), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 100)})
			queue_free()
		queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 4.5, Color(1, 1, 1, 0.25))
		draw_circle(Vector2.ZERO, 3.0, Color("#e8e8f4"))
		for i in 4:
			var a := _t * 6.0 + TAU * i / 4.0
			draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * 4.5, Color("#b8b8c8"), 1.0)


## 하얀 역병 바닥: 느려짐 + 오래 서 있으면 피해. 불에 타면 사라진다
class BlightZone extends Node2D:
	var w := 40.0
	var life := 6.0
	var _t := 0.0
	var _stand := 0.0
	var _burning := -1.0
	var _hurt: Area2D

	func setup(ground: Vector2, p_w: float, p_life: float) -> void:
		global_position = ground
		w = p_w
		life = p_life
		z_index = 3

	func _ready() -> void:
		# 불에 타는 판정 (세라의 불 공격이 맞힘)
		_hurt = Area2D.new()
		_hurt.collision_layer = GameConst.L_ENEMY_HURT
		_hurt.collision_mask = 0
		_hurt.monitoring = false
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(w, 8)
		cs.shape = rs
		cs.position = Vector2(0, -4)
		_hurt.add_child(cs)
		add_child(_hurt)

	func is_alive() -> bool:
		return _burning < 0.0

	func is_on_floor() -> bool:
		return true

	## 세라의 공격에 맞음: 불이면 타서 사라짐
	func take_hit(hit: Hit) -> void:
		if _burning >= 0.0:
			return
		if hit.kind in [&"ally"]:
			return
		burn()

	func burn() -> void:
		if _burning >= 0.0:
			return
		_burning = 0.0
		_hurt.set_deferred("monitorable", false)
		Sfx.play(&"ignite", -4.0, 0.1)
		Fx.burst(global_position + Vector2(0, -3), 14, {box = Vector2(w * 0.5, 2), direction = Vector2.UP, spread = 30.0,
			speed_min = 20.0, speed_max = 60.0, lifetime = 0.5, gravity = Vector2(0, -60)})

	func _physics_process(delta: float) -> void:
		_t += delta
		if _burning >= 0.0:
			_burning += delta
			if _burning > 0.45:
				queue_free()
			queue_redraw()
			return
		if _t >= life:
			queue_free()
			return
		var p := get_tree().get_first_node_in_group(GameConst.GROUP_PLAYER) as Player
		if p and p.is_alive():
			var dx := absf(p.global_position.x - global_position.x)
			var dy := absf(p.global_position.y - global_position.y)
			if dx < w * 0.5 and dy < 6.0 and p.is_on_floor():
				# 끈적여 느려짐 (속도를 매 프레임 깎음)
				p.velocity.x *= 0.55
				_stand += delta
				if _stand >= 1.6:
					_stand = 0.0
					p.take_damage(1, &"blight", global_position.x)
				if Engine.get_physics_frames() % 6 == 0:
					Fx.burst(p.global_position, 1, {direction = Vector2.UP, spread = 30.0, speed_min = 10.0, speed_max = 30.0,
						lifetime = 0.5, gradient = Palette.fade_gradient(Color(0.95, 0.95, 1.0)), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, -10)})
			else:
				_stand = maxf(_stand - delta * 2.0, 0.0)
		queue_redraw()

	func _draw() -> void:
		var fade := clampf((life - _t) / 0.6, 0.0, 1.0) * clampf(_t / 0.2, 0.0, 1.0)
		if _burning >= 0.0:
			fade = 1.0 - _burning / 0.45
			# 타는 불꽃
			for i in int(w / 6.0):
				var x := -w * 0.5 + 3 + i * 6
				var h := 4.0 + 4.0 * sin(_burning * 30.0 + i)
				draw_colored_polygon(PackedVector2Array([Vector2(x - 2, 0), Vector2(x, -h), Vector2(x + 2, 0)]), Color(Palette.FIRE_OUT, fade))
		# 하얀 결정 바닥 (육각 무늬) + 피어오르는 가루
		draw_rect(Rect2(-w * 0.5, -2, w, 3), Color(0.92, 0.92, 1.0, 0.75 * fade))
		draw_rect(Rect2(-w * 0.5 + 2, -3, w - 4, 1), Color(1, 1, 1, 0.6 * fade))
		for i in int(w / 7.0):
			var x2 := -w * 0.5 + 4 + i * 7
			var hh := 2.0 + float((i * 5) % 3)
			draw_colored_polygon(PackedVector2Array([Vector2(x2 - 2, -2), Vector2(x2, -2 - hh), Vector2(x2 + 2, -2)]), Color(0.95, 0.95, 1.0, 0.8 * fade))
		for i in 3:
			var ph := fmod(_t * 0.7 + i * 0.33, 1.0)
			draw_rect(Rect2(-w * 0.3 + i * w * 0.3, -3 - ph * 10.0, 1, 1), Color(1, 1, 1, 0.6 * (1.0 - ph) * fade))


## 포자 덩어리 그림: 흰 곰팡이 덩이 + 기하학 수정 가시 + 숨 쉬는 구멍들. 부풀면 하얗게 빛난다
class SporeVisual extends Node2D:
	var enemy: BlightSpore

	func _process(_d: float) -> void:
		z_index = 1

	func _draw() -> void:
		if enemy == null:
			return
		var t := enemy._t
		var sk := enemy.swell_k()
		var white := enemy.flash_amount() > 0.0
		var breath := 1.0 + sin(t * 2.2) * 0.04 + sk * 0.28
		var base := Color("#c8c8d0")
		var shade := Color("#8a8a96")
		if white:
			base = Color.WHITE
		# 아래 뿌리 (바닥에 퍼진 흰 실)
		for i in 7:
			var a := PI + PI * i / 6.0
			draw_line(Vector2(0, -2), Vector2(cos(a) * 18.0, 0), Color("#d8d8e0"), 1.0)
		# 덩어리 (겹친 원)
		var lumps := [[Vector2(-7, -7), 7.0], [Vector2(6, -6), 6.5], [Vector2(0, -12), 8.0], [Vector2(-3, -4), 6.0], [Vector2(5, -14), 4.5]]
		for l in lumps:
			var c: Vector2 = l[0]
			var r: float = l[1]
			draw_circle(c * breath, r * breath + 1.0, shade)
		for l in lumps:
			var c2: Vector2 = l[0]
			var r2: float = l[1]
			draw_circle(c2 * breath + Vector2(-0.5, -0.5), r2 * breath, base)
		# 숨 쉬는 구멍 (어두운 점, 부풀면 안쪽이 빛남)
		for h in [Vector2(-6, -8), Vector2(2, -13), Vector2(7, -6), Vector2(-2, -4)]:
			var hp: Vector2 = h * breath
			draw_circle(hp, 1.6, Color("#4a4a56"))
			if sk > 0.0:
				draw_circle(hp, 1.0, Color(1, 1, 1, sk))
		# 기하학 수정 가시 (바깥 신들의 흔적)
		for sp in [[Vector2(-10, -12), -0.7, 9.0], [Vector2(3, -19), 0.1, 10.0], [Vector2(10, -10), 0.8, 8.0]]:
			var b: Vector2 = (sp[0] as Vector2) * breath
			var ang: float = sp[1]
			var ln: float = sp[2]
			var d := Vector2(sin(ang), -cos(ang))
			var n := Vector2(-d.y, d.x)
			draw_colored_polygon(PackedVector2Array([b - n * 2.0, b + d * ln * 0.75 - n * 2.0, b + d * ln, b + d * ln * 0.75 + n * 2.0, b + n * 2.0]), Color("#f0f0ff") if not white else Color.WHITE)
			draw_line(b, b + d * ln, Color("#a8a8b8"), 1.0)
		# 예고: 하얗게 빛나며 부풂 (바깥 신들 계열 — 흰 예고, 굵게 깜빡임)
		if sk > 0.0:
			var bl := 0.5 + 0.5 * sin(t * 26.0)
			draw_circle(Vector2(0, -10), 16.0 * breath, Color(1, 1, 1, 0.12 * sk + 0.08 * bl * sk))
			draw_arc(Vector2(0, -10), 18.0 * breath, 0, TAU, 20, Color(1, 1, 1, 0.6 * sk * bl), 2.0)
