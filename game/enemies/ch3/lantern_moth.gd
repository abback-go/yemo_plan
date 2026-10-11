class_name LanternMoth
extends EnemyBase
## 등불 나방 (docs/archive/sera/chapter3.md 4절) — 세계수 등불 빛에 홀린 커다란 나방. 배가 등불처럼 따뜻하게 빛난다.
## - 나선 비행: 세라 둘레를 크게 돌며 반짝이는 가루를 흘린다 → 가루 구름이 천천히 내려앉으며 3.5초 떠 있다(닿으면 1).
## - 급강하: 제자리에서 날개가 붉게 달아오르고 붉은 선(경로)이 보임(0.7초) → 그 선을 따라 쏜살같이 지나가며 가루 줄.
## - 휴식: 급강하 두 번(또는 9초)마다 가까운 등불(방의 elf_lantern·elf_lantern_post·firefly_jar 소품)로 날아가 내려앉아
##   날개를 접고 2.6초 쉰다 — 빈틈(피해 1.6배, 띄워지지 않고 바로 맞는다). 등불이 없으면 처음 자리로 돌아가 쉰다.
## 공략: 가루 구름을 피해 휴식 때를 노린다. 불기둥은 공중이라 안 닿으니 화염탄·화염 폭풍으로.

enum S { SPIRAL, DIVE_WINDUP, DIVE, SEEK, REST, TAKEOFF }

const HP := 640
const SPIRAL_R := 4.2
const SPIRAL_SPEED := 1.3 ## 라디안/초
const DUST_EVERY := 0.85
const DIVE_WINDUP := 0.7
const DIVE_SPEED_T := 15.0
const REST_TIME := 2.6
const REST_MULT := 1.6
const LANTERN_KINDS := ["elf_lantern", "elf_lantern_post", "firefly_jar"]

var state: S = S.SPIRAL
var dive_from := Vector2.ZERO
var dive_to := Vector2.ZERO
var _timer := 0.0
var _dur := 0.0
var _ang := 0.0
var _dust_t := 0.0
var _dives := 0
var _since_rest := 0.0
var _home := Vector2.ZERO
var _rest_at := Vector2.ZERO
var _line: AimLine
var _body: EnemyAttackArea


func _build() -> void:
	max_hp = HP
	body_size = Vector2(26, 20)
	flying = true
	knock_mult = 0.5
	launch_mult = 0.0
	kind_id = "lantern_moth"
	display_name = "등불 나방"
	subtitle = "빛에 홀린 숲의 밤손님"
	_visual = MothVisual.new()
	(_visual as MothVisual).enemy = self
	add_child(_visual)
	_body = add_attack_area(Vector2(20, 14), Vector2(0, -11), &"lantern_moth")
	_body.dodgeable = true


func _ready() -> void:
	super()
	_home = global_position
	_ang = randf() * TAU
	collision_mask = GameConst.L_WORLD


func state_k() -> float:
	return clampf(1.0 - _timer / _dur, 0.0, 1.0) if _dur > 0.0 else 0.0


func _enter(s: S, dur := 0.0) -> void:
	state = s
	_timer = dur
	_dur = dur


func _ai(delta: float) -> void:
	var t := GameConst.TILE
	_timer -= delta
	var p := player()
	if not engaged or p == null or not p.is_alive():
		velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
		return
	_since_rest += delta
	match state:
		S.SPIRAL:
			_ang += SPIRAL_SPEED * delta * (1.0 if hp > max_hp * 0.5 else 1.3)
			var center := p.center() + Vector2(0, -3.4 * t)
			var want := center + Vector2(cos(_ang) * SPIRAL_R * t, sin(_ang) * SPIRAL_R * t * 0.45)
			velocity = velocity.lerp((want - global_position) * 2.2, clampf(delta * 3.0, 0.0, 1.0))
			velocity = velocity.limit_length(9.0 * t)
			facing = 1 if velocity.x >= 0.0 else -1
			_dust_t -= delta
			if _dust_t <= 0.0:
				_dust_t = DUST_EVERY
				_drop_dust(global_position + Vector2(0, -6))
			if _since_rest > 9.0 or _dives >= 2:
				_go_rest()
			elif _timer <= -Difficulty.rest(3.2):
				_start_dive(p)
		S.DIVE_WINDUP:
			velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
			dive_to = p.center() + (p.center() - global_position).normalized() * 2.0 * t
			if _timer < _dur * 0.3:
				_line.lock()
			else:
				dive_from = global_position
				_line.aim(global_position + Vector2(0, -8), (dive_to - global_position).normalized())
			_line.k = state_k()
			if _timer <= 0.0:
				_line.queue_free()
				_line = null
				_enter(S.DIVE, dive_from.distance_to(dive_to) / (DIVE_SPEED_T * t) + 0.15)
				velocity = (dive_to - dive_from).normalized() * DIVE_SPEED_T * t
				facing = 1 if velocity.x >= 0.0 else -1
				Ch3Sfx.play(&"ch3_flutter", 2.0, 0.1)
				Sfx.play(&"whoosh", -4.0, 0.1)
		S.DIVE:
			if Engine.get_physics_frames() % 4 == 0:
				_drop_dust(global_position + Vector2(0, -6), 2.4)
			if _timer <= 0.0 or is_on_wall() or is_on_floor():
				_dives += 1
				_enter(S.SPIRAL, 0.0)
				_ang = (global_position - p.center()).angle()
		S.SEEK:
			var to := _rest_at - global_position
			velocity = velocity.lerp(to.normalized() * minf(8.0 * t, to.length() * 3.0), clampf(delta * 4.0, 0.0, 1.0))
			facing = 1 if velocity.x >= 0.0 else -1
			if to.length() < 4.0 or _timer <= 0.0:
				global_position = _rest_at
				velocity = Vector2.ZERO
				_enter(S.REST, Difficulty.rest(REST_TIME))
				Ch3Sfx.play(&"ch3_flutter", -6.0, 0.1)
		S.REST:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_enter(S.TAKEOFF, 0.35)
				Ch3Sfx.play(&"ch3_flutter", 0.0, 0.1)
		S.TAKEOFF:
			velocity = Vector2(0, -3.0 * t)
			if _timer <= 0.0:
				_dives = 0
				_since_rest = 0.0
				_enter(S.SPIRAL, 0.0)
				_ang = (global_position - p.center()).angle()


func _start_dive(p: Player) -> void:
	_enter(S.DIVE_WINDUP, Difficulty.telegraph(DIVE_WINDUP))
	dive_from = global_position
	dive_to = p.center()
	_line = AimLine.new()
	_line.max_len = global_position.distance_to(dive_to) + 2.0 * GameConst.TILE
	Fx.effect_parent().add_child(_line)
	_line.aim(global_position + Vector2(0, -8), (dive_to - global_position).normalized())
	Ch3Sfx.play(&"ch3_flutter", -2.0, 0.1)


func _go_rest() -> void:
	_rest_at = _find_lantern()
	_enter(S.SEEK, 3.0)


## 가장 가까운 등불 소품 위 (없으면 처음 자리)
func _find_lantern() -> Vector2:
	var best := _home
	var best_d := INF
	var room := get_parent()
	if room == null:
		return best
	for n in room.get_children():
		if not n is Prop:
			continue
		var pr := n as Prop
		if not pr.kind in LANTERN_KINDS:
			continue
		var at := pr.global_position
		match pr.kind:
			"elf_lantern":
				at += Vector2(0, float(pr.params.get("len", 2)) * 16.0 + 1.0)
			"elf_lantern_post":
				at += Vector2(9, -43)
			"firefly_jar":
				at += Vector2(0, -23)
		var d := at.distance_to(global_position)
		if d < best_d and d < 22.0 * GameConst.TILE:
			best_d = d
			best = at
	return best + Vector2(0, 2)


func _drop_dust(at: Vector2, life := 3.5) -> void:
	var d := MothDust.new()
	d.setup(at, life)
	Fx.effect_parent().add_child(d)


func modify_damage(_hit: Hit) -> float:
	return REST_MULT if state == S.REST else 1.0


func _on_hit(hit: Hit, _dir: int) -> void:
	if state == S.DIVE_WINDUP and hit.breaks_charge:
		if _line:
			_line.queue_free()
			_line = null
		_enter(S.SPIRAL, 0.0)


func _exit_tree() -> void:
	if _line and is_instance_valid(_line):
		_line.queue_free()


func _die(dir: int) -> void:
	if _line and is_instance_valid(_line):
		_line.queue_free()
		_line = null
	Fx.burst(global_position + Vector2(0, -8), 26, {spread = 180.0, speed_min = 20.0, speed_max = 80.0, lifetime = 1.0,
		gradient = Palette.fade_gradient(Color(1.0, 0.95, 0.6)), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 30), add = true})
	super(dir)


## 반짝이는 가루 구름: 천천히 내려앉으며 반짝임, 닿으면 1
class MothDust extends EnemyAttackArea:
	var life := 3.5
	var _t := 0.0
	var _seed := 0.0

	func setup(at: Vector2, p_life: float) -> void:
		global_position = at
		life = p_life
		_seed = randf() * 10.0

	func _ready() -> void:
		cause = &"moth_dust"
		damage = 1
		dodgeable = true
		active = false
		z_index = 4
		material = Fx.add_material
		var cs := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 7.0
		cs.shape = c
		add_child(cs)

	func _physics_process(delta: float) -> void:
		var d := delta * Fx.enemy_time
		_t += d
		global_position += Vector2(sin(_t * 1.3 + _seed) * 6.0, 7.0) * d
		active = _t > 0.3 and _t < life - 0.3
		if _t >= life:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var a := clampf(_t / 0.3, 0.0, 1.0) * clampf((life - _t) / 0.5, 0.0, 1.0)
		draw_circle(Vector2.ZERO, 9.0, Color(1.0, 0.92, 0.55, 0.07 * a))
		for i in 7:
			var ang := _seed + i * 0.9 + _t * (0.6 + i * 0.1)
			var r := 2.0 + fmod(i * 2.7, 6.0)
			var p := Vector2(cos(ang), sin(ang)) * r
			var tw := 0.5 + 0.5 * sin(_t * 8.0 + i * 1.7)
			draw_rect(Rect2(p - Vector2(0.5, 0.5), Vector2(1, 1)), Color(1.0, 0.95, 0.65, (0.5 + 0.5 * tw) * a))


## 등불 나방 그림: 복슬복슬한 몸, 깃털 더듬이, 눈알 무늬 앞날개 + 작은 뒷날개, 등불처럼 빛나는 배
class MothVisual extends Node2D:
	const FUR := Color("#d8c8a0")
	const FUR_SH := Color("#9a8a68")
	const WING := Color("#7a6a52")
	const WING_SH := Color("#4e4434")
	const WING_HI := Color("#b8a682")
	const SPOT := Color("#e8f0a0")
	const GLOW := Color("#ffe08a")
	var enemy: LanternMoth

	func _process(_d: float) -> void:
		if enemy == null:
			return
		scale = Vector2(enemy.facing * 1.45, 1.45) # 세라 키만 한 큰 나방
		z_index = 2

	## 날개처럼 펄럭이며 모양이 바뀌는 다각형은 꼬일 수 있어 볼록 껍질로 그린다
	func _hull(pts: PackedVector2Array, col: Color) -> void:
		var h := Geometry2D.convex_hull(pts)
		if h.size() >= 4:
			h.remove_at(h.size() - 1)
			draw_colored_polygon(h, col)

	func _draw() -> void:
		if enemy == null:
			return
		var t := enemy._t
		var st := enemy.state
		var k := enemy.state_k()
		var wh := enemy.flash_amount() > 0.0
		var c := Vector2(0, -8 + (sin(t * 3.0) * 1.5 if st != LanternMoth.S.REST else 0.0))
		var resting := st == LanternMoth.S.REST
		var flap := sin(t * (22.0 if st == LanternMoth.S.DIVE else 14.0)) if not resting else 0.0
		var red := 0.0
		if st == LanternMoth.S.DIVE_WINDUP:
			red = k * (0.7 + 0.3 * sin(t * 30.0))
			flap = sin(t * 30.0)
		var wcol := WING if not wh else Color.WHITE
		if red > 0.0:
			wcol = wcol.lerp(Palette.DANGER, red * 0.7)
		# 배의 등불 빛
		var g := 0.7 + 0.3 * sin(t * 2.5)
		draw_circle(c + Vector2(-5, 2), 14.0, Color(GLOW, 0.08 * g))
		if resting:
			# 날개를 지붕처럼 접음
			draw_colored_polygon(PackedVector2Array([c + Vector2(6, -3), c + Vector2(-12, 3), c + Vector2(-8, 6), c + Vector2(5, 2)]), wcol.darkened(0.15))
			draw_colored_polygon(PackedVector2Array([c + Vector2(6, -4), c + Vector2(-11, 0), c + Vector2(-12, 3), c + Vector2(6, -1)]), wcol)
			draw_line(c + Vector2(4, -3), c + Vector2(-9, 1), WING_HI, 1.0)
			draw_circle(c + Vector2(-4, 0), 1.5, Color(SPOT, 0.8))
		else:
			# 뒷날개 (작게)
			var hw := 7.0 * (0.35 + 0.65 * absf(flap))
			_hull(PackedVector2Array([c + Vector2(-2, 1), c + Vector2(-9, 1 + hw * 0.6), c + Vector2(-4, 3 + hw * 0.8), c + Vector2(0, 3)]), wcol.darkened(0.25))
			# 앞날개 (위로 펄럭) — 먼 날개, 가까운 날개
			for far in [true, false]:
				var span := 15.0 * (0.25 + 0.75 * absf(flap))
				var up := -1.0 if flap > 0.0 else 0.4
				var col := wcol.darkened(0.2) if far else wcol
				var off := Vector2(-2 if far else 1, 0)
				var wing := PackedVector2Array([c + off + Vector2(2, -1), c + off + Vector2(-3, -1 + up * span), c + off + Vector2(-13, -1 + up * span * 0.8),
					c + off + Vector2(-12, 1 + up * span * 0.3), c + off + Vector2(-2, 1)])
				_hull(wing, col)
				if not far:
					draw_line(c + off + Vector2(1, -1), c + off + Vector2(-12, -1 + up * span * 0.8), WING_HI if not wh else Color.WHITE, 1.0)
					# 눈알 무늬 (빛남)
					var sp := c + off + Vector2(-7, -1 + up * span * 0.55)
					draw_circle(sp, 2.6, WING_SH)
					draw_circle(sp, 1.6, Color(SPOT, 0.7 + 0.3 * g))
					draw_rect(Rect2(sp.x - 0.5, sp.y - 0.5, 1, 1), Color(0.2, 0.2, 0.1))
		# 몸통 (복슬복슬) + 빛나는 배
		draw_circle(c + Vector2(2, -1), 3.2, FUR if not wh else Color.WHITE)
		draw_circle(c + Vector2(-2, 1), 3.4, FUR_SH if not wh else Color.WHITE)
		draw_circle(c + Vector2(-5, 2), 3.0, Color(GLOW, 0.85 * g))
		draw_circle(c + Vector2(-5, 2), 1.5, Color(1, 1, 0.9, g))
		for i in 3:
			draw_line(c + Vector2(-3 - i * 1.5, -1), c + Vector2(-3 - i * 1.5, 4), FUR_SH.darkened(0.2), 1.0)
		# 머리·눈·깃털 더듬이
		draw_circle(c + Vector2(5, -2), 2.2, FUR)
		draw_rect(Rect2(c.x + 6, c.y - 3, 1.5, 1.5), Color("#2a2010"))
		for side in [0.0, 1.0]:
			var base := c + Vector2(5 + side, -4)
			var tip := base + Vector2(4 - side * 2.0, -6 + sin(t * 3.0 + side) * 0.8)
			draw_line(base, tip, FUR_SH, 1.0)
			for j in 3:
				var q := base.lerp(tip, 0.3 + j * 0.25)
				draw_line(q, q + Vector2(1.5, 0.5), FUR_SH, 1.0)
