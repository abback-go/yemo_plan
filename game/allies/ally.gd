class_name Ally
extends CharacterBody2D
## 동료 (docs/systems2.md 5절): 강자·친구가 세라 곁에서 함께 싸운다. 체력이 없고(쓰러지지 않음), 피해는 보조 수준.
## 역할은 강자 보스전에서 틈을 만드는 것 — 대본이 special()로 큰 지원기를 부른다.
## mode: follow(따라다니며 싸움) · hold(지금 자리에서 원거리 지원, 엘라리엔 저격 등) · script(AI 끔, 대본이 움직임)

const T := 16.0
## 종류별 값: who(그림), attack(slash·arrow·spear·star·frost·fireball), range(T), cd(초), dmg, speed(T/s), keep(원거리 거리 T), float(떠다님)
const SPECS := {
	"leonie": {"who": "leonie", "attack": "slash", "range": 2.4, "cd": 1.0, "dmg": 90, "speed": 12.0, "keep": 0.0},
	"elarien": {"who": "elarien", "attack": "arrow", "range": 18.0, "cd": 1.5, "dmg": 85, "speed": 10.0, "keep": 7.0},
	"aurelia": {"who": "aurelia", "attack": "spear", "range": 3.2, "cd": 1.2, "dmg": 110, "speed": 11.0, "keep": 0.0},
	"astrid": {"who": "astrid", "attack": "star", "range": 14.0, "cd": 1.7, "dmg": 90, "speed": 9.0, "keep": 5.0, "float": true},
	"isolde": {"who": "isolde", "attack": "frost", "range": 12.0, "cd": 1.5, "dmg": 70, "speed": 10.0, "keep": 5.0},
	"emberlyn": {"who": "emberlyn", "attack": "fireball", "range": 12.0, "cd": 1.5, "dmg": 80, "speed": 10.0, "keep": 5.0},
	"lyra": {"who": "lyra", "attack": "star", "range": 16.0, "cd": 1.2, "dmg": 120, "speed": 11.0, "keep": 5.0, "float": true},
}
## 큰 지원기(special) 값: line 말풍선, delay 기술 전 멈춤(초), mult 피해 배수(× dmg), stagger 대상 경직(초), iframes 세라 무적(초).
## 동작 자체는 special()의 종류별 분기에 있다. 표에 없는 종류는 기본 공격 × SPECIAL_DEFAULT_MULT 원거리.
const SPECIAL := {
	"leonie": {"line": "다리를 벤다!", "delay": 0.15, "mult": 3.0, "stagger": 2.0},
	"elarien": {"line": "…거기.", "delay": 0.3, "mult": 3.5},
	"aurelia": {"line": "빛이여.", "mult": 3.0, "stagger": 1.8},
	"astrid": {"line": "지켜 드리죠.", "iframes": 3.0},
	"isolde": {"line": "얼어붙어라!", "mult": 2.5, "stagger": 1.5},
}
const SPECIAL_DEFAULT_MULT := 2.5

var kind := "leonie"
var spec := {}
var mode := "follow"
var facing := 1
var visual: CharacterVisual
var active := true
var _flip: Node2D
var _cd := 0.6
var _act_t := 0.0 ## 공격 동작 남은 시간
var _act_kind := ""
var _target: EnemyBase
var _t := 0.0
var _bubble := ""
var _bubble_t := 0.0
var _font: Font
var _move_target := Vector2.INF
var _dash_v := 0.0
var _hit_done := false
var _player: Player ## 세라 (그룹 탐색 결과 캐시 — 나가면 다시 찾음)
var _drawn_bubble := "" ## 지금 그려져 있는 말풍선 글 (바뀔 때만 다시 그림)


static func create(p_kind: String) -> Ally:
	var path: String = ChapterRegistry.ally_kinds().get(p_kind, "")
	var a: Ally = null
	if path != "" and ResourceLoader.exists(path):
		a = (load(path) as GDScript).new() as Ally
	if a == null:
		a = Ally.new()
	a.kind = p_kind
	return a


func _ready() -> void:
	add_to_group(&"ally")
	spec = SPECS.get(kind, SPECS["leonie"])
	collision_layer = 0
	collision_mask = GameConst.L_WORLD | GameConst.L_PLATFORM
	floor_snap_length = 4.0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(10, 26)
	cs.shape = r
	cs.position = Vector2(0, -13)
	add_child(cs)
	_flip = Node2D.new()
	add_child(_flip)
	visual = CharacterVisual.new()
	visual.setup(String(spec.get("who", kind)))
	_flip.add_child(visual)
	_font = ThemeDB.fallback_font
	z_index = 2


func player() -> Player:
	if _player == null or not is_instance_valid(_player) or not _player.is_inside_tree():
		_player = get_tree().get_first_node_in_group(GameConst.GROUP_PLAYER) as Player
	return _player


func is_float() -> bool:
	return bool(spec.get("float", false))


## 방을 옮겼을 때: 세라 곁(뒤쪽)에 나타남
func place_near(p: Player) -> void:
	var off := Vector2(-p.facing * 26.0, 0)
	global_position = p.global_position + off
	velocity = Vector2.ZERO
	facing = p.facing
	_poof()


func say(text: String, time := 2.6) -> void:
	_bubble = text
	_bubble_t = time


func set_pose(p: String) -> void:
	visual.set_pose(p)


## 쓰러짐/일어섬 연출 (5장 절망 등)
func down() -> void:
	active = false
	mode = "script"
	visual.set_pose("down")


func up() -> void:
	active = true
	mode = "follow"
	visual.set_pose("idle")
	Fx.burst(global_position + Vector2(0, -16), 14, {spread = 180.0, speed_min = 30.0, speed_max = 90.0, lifetime = 0.5,
		gradient = Palette.fade_gradient(Color(1.0, 0.9, 0.6)), add = true})


## 대본: 걸어서(떠서) 이동. 막히면 순간이동
func move_to(x_t: float, y_t: float = INF) -> void:
	mode = "script"
	_move_target = Vector2(x_t * T + 8.0, (y_t * T) if y_t != INF else global_position.y)
	var left := 4.0
	while left > 0.0 and is_inside_tree():
		await get_tree().physics_frame
		left -= get_physics_process_delta_time()
		if absf(global_position.x - _move_target.x) < 4.0:
			break
	if is_inside_tree() and absf(global_position.x - _move_target.x) >= 4.0:
		global_position = _move_target
		_poof()
	_move_target = Vector2.INF
	velocity.x = 0.0


func _physics_process(delta: float) -> void:
	_t += delta
	_bubble_t = maxf(_bubble_t - delta, 0.0)
	_cd -= delta
	var p := player()
	if p == null:
		return
	if _act_t > 0.0:
		_act_t -= delta
		_update_attack(delta)
	elif mode == "script":
		_scripted_move(delta)
	elif active:
		_ai(p, delta)
	_apply_physics(delta)
	_flip.scale.x = facing
	visual.walking = absf(velocity.x) > 20.0 and is_on_floor()
	if _act_t <= 0.0 and active:
		visual.set_pose("run" if visual.walking else "idle")
	# 그리는 것은 말풍선뿐 — 보일 글이 바뀔 때만 다시 그린다
	var shown := _bubble if _bubble_t > 0.0 else ""
	if shown != _drawn_bubble:
		_drawn_bubble = shown
		queue_redraw()


func _apply_physics(delta: float) -> void:
	if is_float():
		velocity.y = move_toward(velocity.y, sin(_t * 2.0) * 10.0, 600.0 * delta)
	elif not is_on_floor():
		velocity.y = minf(velocity.y + 1500.0 * delta, 600.0)
	move_and_slide()


func _scripted_move(delta: float) -> void:
	if _move_target == Vector2.INF:
		velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
		return
	var dx := _move_target.x - global_position.x
	facing = 1 if dx > 0.0 else -1
	velocity.x = signf(dx) * float(spec.speed) * T * 0.8
	if is_float():
		velocity.y = (_move_target.y - global_position.y) * 4.0


func _ai(p: Player, delta: float) -> void:
	# 너무 멀어지면 순간이동
	if global_position.distance_to(p.global_position) > 15.0 * T and mode == "follow":
		place_near(p)
		return
	_target = _pick_target(p)
	var home_x := p.global_position.x - p.facing * 28.0
	if mode == "hold":
		home_x = global_position.x
	var want_x := home_x
	if _target:
		var tx := _target.global_position.x
		var keep := float(spec.keep) * T
		if keep <= 0.0:
			want_x = tx - signf(tx - global_position.x) * (float(spec.range) * T * 0.7)
		elif absf(tx - global_position.x) < keep:
			want_x = global_position.x - signf(tx - global_position.x) * T
		elif mode == "follow":
			want_x = home_x
		facing = 1 if tx > global_position.x else -1
		if _cd <= 0.0 and _in_range(_target):
			_start_attack()
	elif mode == "follow" and absf(want_x - global_position.x) > 8.0:
		facing = 1 if want_x > global_position.x else -1
	if mode == "hold":
		velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
		return
	var dx := want_x - global_position.x
	if absf(dx) > 10.0:
		velocity.x = move_toward(velocity.x, signf(dx) * float(spec.speed) * T, 1800.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 1800.0 * delta)
	# 막히면 점프 (세라가 위에 있으면 따라 뜀)
	if not is_float() and is_on_floor() and (is_on_wall() or p.global_position.y < global_position.y - 3.0 * T):
		velocity.y = -470.0
	if is_float():
		var ty := p.global_position.y - 2.0 * T
		velocity.y = (ty - global_position.y) * 3.0


## 세라 18칸 안, 내 사거리(+8칸, 최소 14칸) 안에서 가장 가까운 적 (전투 시작 전 보스는 뺌)
func _pick_target(p: Player) -> EnemyBase:
	var reach := maxf(float(spec.range) * T + 8.0 * T, 14.0 * T)
	var from := global_position
	var metric := func(en: EnemyBase) -> float:
		if (en.is_boss and not en.engaged) or en.global_position.distance_to(p.global_position) > 18.0 * T:
			return INF
		return en.global_position.distance_to(from)
	return EnemyQuery.nearest(get_tree(), metric, reach) as EnemyBase


func _in_range(en: EnemyBase) -> bool:
	return EnemyBase.dist_to_body(en, global_position + Vector2(0, -14)) <= float(spec.range) * T


func _start_attack() -> void:
	_act_kind = String(spec.attack)
	_hit_done = false
	_cd = float(spec.cd)
	match _act_kind:
		"slash":
			_act_t = 0.32
			visual.set_pose("attack")
			_dash_v = facing * 260.0
			Sfx.play(&"sword_slash", -6.0, 0.1)
		"spear":
			_act_t = 0.36
			visual.set_pose("attack")
			_dash_v = facing * 300.0
			Sfx.play(&"spear", -6.0, 0.1)
		"arrow":
			_act_t = 0.55
			visual.set_pose("aim")
			Sfx.play(&"bow_draw", -8.0, 0.1)
		_:
			_act_t = 0.4
			visual.set_pose("cast")


func _update_attack(delta: float) -> void:
	velocity.x = move_toward(velocity.x if absf(_dash_v) < 1.0 else _dash_v, 0.0, 1400.0 * delta)
	_dash_v = move_toward(_dash_v, 0.0, 1600.0 * delta)
	var tgt: EnemyBase = _target if is_instance_valid(_target) else null
	match _act_kind:
		"slash", "spear":
			if not _hit_done and _act_t < 0.2:
				_hit_done = true
				_melee_hit(tgt, 1.0)
		"arrow":
			if not _hit_done and _act_t < 0.15:
				_hit_done = true
				visual.set_pose("attack")
				_shoot(tgt, "arrow", 1.0)
		_:
			if not _hit_done and _act_t < 0.2:
				_hit_done = true
				visual.set_pose("attack")
				_shoot(tgt, _act_kind, 1.0)


func _melee_hit(en: EnemyBase, mult: float) -> void:
	var c := global_position + Vector2(facing * 18.0, -16.0)
	var col := Color(0.85, 0.9, 1.0) if _act_kind == "slash" else Color(1.0, 0.85, 0.4)
	var fx := SlashFx.new()
	fx.global_position = c
	fx.dir = facing
	fx.col = col
	fx.big = mult > 1.5
	Fx.effect_parent().add_child(fx)
	if en and is_instance_valid(en) and en.is_alive() and EnemyBase.dist_to_body(en, c) <= float(spec.range) * T * 1.3:
		_deal(en, int(round(float(spec.dmg) * mult)))


func _shoot(en: EnemyBase, style: String, mult: float) -> void:
	if en == null or not is_instance_valid(en) or not en.is_alive():
		return
	var pr := AllyShot.new()
	pr.global_position = global_position + Vector2(facing * 8.0, -18.0)
	pr.target = en
	pr.style = style
	pr.damage = int(round(float(spec.dmg) * mult))
	pr.ally = self
	Fx.effect_parent().add_child(pr)
	Sfx.play(&"arrow_shot" if style == "arrow" else &"shoot", -7.0, 0.1)


func _deal(en: EnemyBase, dmg: int) -> void:
	var h := Hit.make(dmg, &"ally", global_position, int(signf(en.global_position.x - global_position.x)))
	h.knockback_t = 1.0
	h.hitstop = 0.03
	h.shake_t = 0.08
	en.take_hit(h)


## 큰 지원기 (대본·보스전). 대상이 지원기 반응 함수를 가지고 있으면 부른다(stagger·snipe_eye 등)
func special(en: EnemyBase = null) -> void:
	if en == null:
		en = _pick_target(player()) if player() else null
	visual.set_pose("special")
	_act_t = 0.5
	_act_kind = "special"
	var sp: Dictionary = SPECIAL.get(kind, {})
	match kind:
		"leonie":
			say(sp.line)
			if en:
				global_position = en.global_position + Vector2(-facing * 28.0, 0)
				_poof()
			await get_tree().create_timer(sp.delay).timeout
			_act_kind = "slash"
			_melee_hit(en, sp.mult)
			if en and is_instance_valid(en) and en.has_method("stagger"):
				en.stagger(sp.stagger)
		"elarien":
			say(sp.line)
			await get_tree().create_timer(sp.delay).timeout
			if en and is_instance_valid(en):
				if en.has_method("snipe_eye"):
					en.snipe_eye()
				_shoot(en, "arrow", sp.mult)
		"aurelia":
			say(sp.line)
			if en and is_instance_valid(en):
				_deal(en, int(float(spec.dmg) * sp.mult))
				if en.has_method("stagger"):
					en.stagger(sp.stagger)
				Fx.flash(Color(1.0, 0.92, 0.6, 0.4), 0.2)
		"astrid":
			say(sp.line)
			var p := player()
			if p:
				p.grant_iframes(sp.iframes)
				Fx.ring(p.center(), 6.0, 40.0, Color(0.85, 0.85, 1.0), 0.6, 3.0)
		"isolde":
			say(sp.line)
			if en and is_instance_valid(en):
				_shoot(en, "frost", sp.mult)
				if en.has_method("stagger"):
					en.stagger(sp.stagger)
		_:
			if en and is_instance_valid(en):
				_shoot(en, String(spec.attack), SPECIAL_DEFAULT_MULT)


func _poof() -> void:
	Fx.burst(global_position + Vector2(0, -14), 10, {spread = 180.0, speed_min = 20.0, speed_max = 70.0, lifetime = 0.35,
		gradient = Palette.fade_gradient(Color(1, 1, 1, 0.8)), add = true})


func _draw() -> void:
	if _bubble_t <= 0.0 or _bubble == "":
		return
	var border := Color(Characters.info(String(spec.get("who", kind))).get("color", Color.WHITE), 0.8)
	BubbleDraw.draw_speech(self, _font, _bubble, -66.0, Color(0.04, 0.03, 0.08, 0.85), Palette.UI_TEXT, border)


## 베기 궤적 (반달)
class SlashFx extends Node2D:
	var dir := 1
	var col := Color.WHITE
	var big := false
	var _t := 0.0

	func _ready() -> void:
		material = Fx.add_material
		z_index = 7

	func _process(delta: float) -> void:
		_t += delta
		if _t > 0.18:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := _t / 0.18
		var r := (22.0 if not big else 40.0) * (0.7 + 0.3 * k)
		var a0 := -1.2 if dir > 0 else PI - 1.2
		draw_arc(Vector2.ZERO, r, a0, a0 + 2.4 * signf(dir), 16, Color(col, 1.0 - k), 3.0 if not big else 5.0)
		draw_arc(Vector2.ZERO, r - 3.0, a0, a0 + 2.4 * signf(dir), 16, Color(1, 1, 1, 0.8 * (1.0 - k)), 1.0)


## 원거리 지원 탄 (화살·별·서리·화염구): 대상에게 날아가 맞힘
class AllyShot extends Node2D:
	var target: EnemyBase
	var style := "arrow"
	var damage := 80
	var ally: Ally
	var _v := Vector2.ZERO
	var _t := 0.0
	var _trail: Array[Vector2] = []

	func _ready() -> void:
		z_index = 6
		if style != "arrow":
			material = Fx.add_material
		var spd := 520.0 if style == "arrow" else 300.0
		var aim := target.global_position + Vector2(0, -target.body_size.y * 0.5) if is_instance_valid(target) else global_position + Vector2.RIGHT * 100.0
		_v = (aim - global_position).normalized() * spd

	func _physics_process(delta: float) -> void:
		_t += delta
		if is_instance_valid(target) and target.is_alive():
			var aim := target.global_position + Vector2(0, -target.body_size.y * 0.5)
			var want := (aim - global_position).normalized() * _v.length()
			_v = _v.lerp(want, minf(delta * (4.0 if style == "arrow" else 6.0), 1.0))
			if EnemyBase.dist_to_body(target, global_position) < 8.0:
				_hit()
				return
		elif _t > 0.2:
			queue_free()
			return
		_trail.push_front(global_position)
		if _trail.size() > 8:
			_trail.pop_back()
		global_position += _v * delta
		if _t > 2.0:
			queue_free()
		queue_redraw()

	func _col() -> Color:
		match style:
			"star": return Color(1.0, 0.95, 0.7)
			"frost": return Color(0.7, 0.9, 1.0)
			"fireball": return Palette.FIRE_OUT
		return Color(0.95, 0.95, 0.9)

	func _hit() -> void:
		var h := Hit.make(damage, &"ally", global_position, int(signf(_v.x)))
		h.knockback_t = 0.8
		h.hitstop = 0.03
		target.take_hit(h)
		Fx.burst(global_position, 8, {spread = 180.0, speed_min = 30.0, speed_max = 110.0, lifetime = 0.25,
			gradient = Palette.fade_gradient(_col()), add = true})
		Sfx.play(&"arrow_hit" if style == "arrow" else &"hit", -8.0, 0.1)
		queue_free()

	func _draw() -> void:
		var c := _col()
		var prev := Vector2.ZERO
		for i in _trail.size():
			var p := to_local(_trail[i])
			var k := 1.0 - float(i) / _trail.size()
			draw_line(prev, p, Color(c, 0.6 * k), 2.0 * k + 0.5)
			prev = p
		var d := _v.normalized()
		if style == "arrow":
			draw_line(-d * 8.0, d * 4.0, Color("#e8e0c8"), 1.0)
			draw_line(d * 4.0, d * 7.0, Color.WHITE, 1.0)
			draw_line(-d * 8.0, -d * 8.0 + d.orthogonal() * 2.0, Color(1, 1, 1, 0.8), 1.0)
		else:
			draw_circle(Vector2.ZERO, 4.0, Color(c, 0.5))
			draw_circle(Vector2.ZERO, 2.0, Color(1, 1, 1, 0.9))
