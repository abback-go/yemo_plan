extends EnemyBase
## 녹시스 — 별 신도 대사제 (docs/archive/sera/chapter2.md 4절, 하수도 미니보스). 별 마법으로 싸우고, 체력 절반에서 도망친다(컷신).
## 패턴 (예고 → 공격 → 빈틈):
##   유성 셋: 지팡이를 들어 별을 부름(0.8초) → 세라 자리와 양옆에 붉은 원(1초) → 차례로 유성 낙하
##   별 감옥: 세라 둘레에 붉은 원이 조여 옴(1.1초) → 다 조여지면 별빛 창살이 닫히며 안쪽에 피해 + 0.5초 묶임 → 대시로 빠져나간다
##   별 조각 부채: 다섯 갈래 별 조각 (불꽃 방벽으로 되쏠 수 있음)
##   순간이동: 별가루로 흩어졌다가 다른 자리에서 나타남(나타날 자리가 먼저 반짝)
## 체력 50%: 싸움을 멈추고 웃으며(무적) 신호 flee_requested + 플래그 half_flag(기본 "k_noxis_half")를 세운다.
##   대본이 auto_flee = false로 두고 flee()를 부르면 그때 사라지고, 아니면 3초 뒤 스스로 별빛 속으로 사라진다(fled 신호).
## 그림은 CharacterVisual("noxis") 전용 그림을 쓴다.

signal flee_requested
signal fled

const KE := preload("res://enemies/ch2/k_enemy.gd")
const KArt := preload("res://world/entities/ch2/k_art.gd")

enum S { IDLE, FLOAT, CAST_METEOR, CAST_PRISON, CAST_FAN, VANISH, APPEAR, HALF, FLEEING }

const HP := 1600
const FLOAT_TIME := Vector2(1.0, 1.6)
const METEOR_CAST := 0.8
const METEOR_WARN := 1.0
const PRISON_CAST := 0.6
const PRISON_WARN := 1.1
const FAN_CAST := 0.55
const VANISH_TIME := 0.5
const APPEAR_TIME := 0.45
const FLEE_DELAY := 3.0
const STAR := Color("#c89aff")

var auto_flee := true
var half_flag := "k_noxis_half"
var fled_flag := ""
var state: S = S.IDLE
var _timer := 0.0
var _dur := 0.0
var _home := Vector2.ZERO
var _spots: Array[Vector2] = []
var _next := Vector2.ZERO
var _last := ""
var _halfed := false
var _vis: CharacterVisual
var _flip: Node2D


func _init() -> void:
	engaged = false


func _build() -> void:
	max_hp = HP
	body_size = Vector2(16, 36)
	knock_mult = 0.0
	launch_mult = 0.0
	is_boss = true
	is_elite = false
	display_name = "녹시스"
	subtitle = "별을 좇는 자들의 대사제"
	kind_id = "noxis"
	_flip = Node2D.new()
	add_child(_flip)
	_vis = CharacterVisual.new()
	_vis.setup("noxis")
	_vis.set_pose("idle")
	_flip.add_child(_vis)
	_visual = _flip
	var fx := KE.Vis.new()
	fx.enemy = self
	fx.fn = _draw_fx
	fx.flip = false
	fx.z_index = 5
	add_child(fx)
	var hb := add_attack_area(Vector2(14, 30), Vector2(0, -16), &"noxis", 1)
	hb.dodgeable = false


func _ready() -> void:
	super()
	_home = global_position
	_spots = [_home]
	for dx in [-7.0, 7.0]:
		var x: float = _home.x + dx * GameConst.TILE
		var q := PhysicsRayQueryParameters2D.create(_home + Vector2(0, -12), Vector2(x, _home.y - 12), GameConst.L_WORLD)
		if get_world_2d().direct_space_state.intersect_ray(q).is_empty():
			_spots.append(Vector2(x, KE.floor_at(self, x, _home.y, 64.0)))
	_enter(S.IDLE, 0.0)


func _enter(s: S, d: float) -> void:
	state = s
	_timer = d
	_dur = d


func progress() -> float:
	return clampf(1.0 - _timer / _dur, 0.0, 1.0) if _dur > 0.0 else 1.0


func _physics_process(delta: float) -> void:
	super(delta)
	_flip.scale.x = float(facing)
	var a := progress() if state == S.APPEAR else 1.0
	_vis.modulate = Color(2.0, 2.0, 2.0, a) if flash_amount() > 0.0 else Color(1, 1, 1, a)


func _ai(delta: float) -> void:
	_timer -= delta
	velocity.x = 0.0
	var p := player()
	if state == S.HALF:
		_vis.set_pose("kneel")
		if _timer <= 0.0 and auto_flee:
			flee()
		return
	if state == S.FLEEING:
		_vis.set_pose("special")
		if _timer <= 0.0:
			_finish_flee()
		return
	if not engaged or p == null or not p.is_alive():
		_vis.set_pose("idle")
		return
	if state not in [S.VANISH]:
		face_player()
	match state:
		S.IDLE:
			_enter(S.FLOAT, 0.6)
		S.FLOAT:
			_vis.set_pose("idle")
			if _timer <= 0.0:
				_choose()
		S.CAST_METEOR:
			_vis.set_pose("cast")
			if _timer <= 0.0:
				var px := p.global_position.x
				var fy := KE.floor_at(self, px, p.global_position.y)
				var t := GameConst.TILE
				var xs: Array[float] = [px, px - 4.5 * t, px + 4.5 * t]
				for i in xs.size():
					KE.meteor(Vector2(xs[i], KE.floor_at(self, xs[i], fy)), Difficulty.telegraph(METEOR_WARN) + i * 0.3, 26.0)
				KE.snd(&"meteor_fall", &"whoosh", -2.0)
				_enter(S.FLOAT, Difficulty.rest(randf_range(FLOAT_TIME.x, FLOAT_TIME.y)) + 0.6)
		S.CAST_PRISON:
			_vis.set_pose("cast")
			if _timer <= 0.0:
				var prison := StarPrison.new()
				prison.setup(p.center(), Difficulty.telegraph(PRISON_WARN))
				Fx.effect_parent().add_child(prison)
				_enter(S.FLOAT, Difficulty.rest(randf_range(FLOAT_TIME.x, FLOAT_TIME.y)) + 0.8)
		S.CAST_FAN:
			_vis.set_pose("attack" if _timer < 0.15 else "cast")
			if _timer <= 0.0:
				var from := global_position + Vector2(facing * 12.0, -30)
				var aim := (p.center() - from).normalized()
				for i in 5:
					KE.shard(from, aim.rotated((i - 2) * 0.22), 7.5 * GameConst.TILE, {"radius": 3.5, "life": 3.5})
				KE.snd(&"star_burst", &"sniper_shot", -2.0)
				_enter(S.FLOAT, Difficulty.rest(randf_range(FLOAT_TIME.x, FLOAT_TIME.y)))
		S.VANISH:
			_vis.set_pose("special")
			if _timer <= 0.0:
				global_position = _next
				_enter(S.APPEAR, APPEAR_TIME)
				KE.star_burst(global_position + Vector2(0, -20), 18, STAR, 100.0, 0.5)
				KE.snd(&"warp", &"reveal", -4.0)
		S.APPEAR:
			_vis.set_pose("idle")
			if _timer <= 0.0:
				_enter(S.FLOAT, 0.3)


func _choose() -> void:
	var options := ["meteor", "prison", "fan", "warp"]
	var pick: String = options[randi() % options.size()]
	if pick == _last:
		pick = options[(options.find(pick) + 1) % options.size()]
	if dist_to_player() < 3.0 * GameConst.TILE:
		pick = "warp" # 가까이 붙으면 순간이동으로 거리를 벌림
	_last = pick
	match pick:
		"meteor":
			_enter(S.CAST_METEOR, Difficulty.telegraph(METEOR_CAST))
			KE.snd(&"star_twinkle", &"pillar_warn", -2.0)
		"prison":
			_enter(S.CAST_PRISON, Difficulty.telegraph(PRISON_CAST))
			KE.snd(&"star_twinkle", &"pillar_warn", -2.0)
		"fan":
			_enter(S.CAST_FAN, Difficulty.telegraph(FAN_CAST))
			KE.snd(&"star_twinkle", &"sniper_aim", -4.0)
		_:
			var p := player()
			var best := _home
			var best_d := -1.0
			for sp in _spots:
				var d := sp.distance_to(p.global_position) if p else 0.0
				if sp.distance_to(global_position) > 8.0 and d > best_d:
					best_d = d
					best = sp
			_next = best
			_enter(S.VANISH, VANISH_TIME)
			KE.snd(&"whoosh", &"whoosh", -4.0)


func modify_damage(_hit: Hit) -> float:
	if not engaged or state in [S.HALF, S.FLEEING] or (state == S.VANISH and progress() > 0.5):
		return 0.0
	return 1.0


func _on_blocked(hit: Hit) -> void:
	if state in [S.HALF, S.FLEEING]:
		KE.star_burst(global_position + Vector2(0, -20), 6, STAR, 60.0, 0.3)
		return
	super(hit)


func _on_hit(_hit: Hit, _dir: int) -> void:
	if not _halfed and hp * 2 <= max_hp:
		_halfed = true
		hp = maxi(hp, 1)
		_enter(S.HALF, FLEE_DELAY)
		enraged.emit()
		flee_requested.emit()
		if half_flag != "":
			GameState.set_flag(half_flag)
		KE.snd(&"giggle", &"giggle", 0.0)
		Fx.flash(Color(STAR, 0.25), 0.25)
		for e in get_tree().get_nodes_in_group(&"enemy_attack"):
			if e is EnemyProjectile:
				(e as EnemyProjectile).pop()


## 대본용: 별빛 속으로 사라진다 (처치 기록을 남겨 다시 나오지 않음)
func flee() -> void:
	if state == S.FLEEING:
		return
	_enter(S.FLEEING, 0.8)
	KE.snd(&"warp", &"reveal", 0.0)
	KE.star_burst(global_position + Vector2(0, -20), 30, STAR, 160.0, 0.9)


func _finish_flee() -> void:
	_alive = false
	_record_defeat("", false) # 도망: 처치 표시만 (kills·등급은 세지 않음 — 예전 동작 그대로), defeated 대신 fled
	if fled_flag != "":
		GameState.set_flag(fled_flag)
	_disable_body()
	fled.emit()
	KE.star_burst(global_position + Vector2(0, -20), 40, STAR, 200.0, 1.0)
	Fx.ring(global_position + Vector2(0, -20), 6.0, 60.0, STAR, 0.5, 2.0)
	queue_free()


func _die(dir: int) -> void:
	# 원래는 절반에서 도망치지만, 시험 명령 등으로 한 번에 쓰러지면 그냥 별빛으로 흩어진다
	KE.death_fx(global_position + Vector2(0, -20), STAR, true)
	super(dir)


func _draw_fx(c: Node2D) -> void:
	# 순간이동할 자리가 먼저 반짝 (붉은 별 문양)
	if state == S.VANISH:
		var rel := _next - global_position
		var a := KE.warn_pulse(_t, progress())
		c.draw_set_transform(rel + Vector2(0, -1), 0.0, Vector2(1.0, 0.3))
		c.draw_arc(Vector2.ZERO, 14.0, 0, TAU, 18, Color(STAR.lerp(KE.DANGER, 0.5), a), 1.5)
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if state == S.HALF:
		for i in 5:
			var ang := _t * 2.0 + TAU * i / 5.0
			KArt.star4(c, Vector2(cos(ang) * 16.0, -24 + sin(ang) * 6.0), 2.0, Color(STAR, 0.9))


## 별 감옥: 세라 둘레에 붉은 원이 조여 오다가, 다 조여지면 별빛 창살이 닫히며 안쪽에 피해
class StarPrison extends EnemyAttackArea:
	var warn := 1.1
	var radius := 40.0
	var _t := 0.0
	var _closed := false
	var _ct := 0.0

	func setup(center: Vector2, p_warn: float) -> void:
		global_position = center
		warn = p_warn

	func _ready() -> void:
		cause = &"star_prison"
		damage = 1
		dodgeable = true
		active = false
		z_index = 4
		var s := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 18.0
		s.shape = c
		add_child(s)

	func _physics_process(delta: float) -> void:
		_t += delta * Fx.enemy_time
		if not _closed and _t >= warn:
			_closed = true
			active = true
			if Sfx.has_sound(&"star_burst"):
				Sfx.play(&"star_burst", -2.0)
			else:
				Sfx.play(&"block", 0.0)
			Fx.shake(0.15, 0.15)
		if _closed:
			_ct += delta
			if _ct > 0.15:
				active = false
			if _ct > 0.8:
				queue_free()
		queue_redraw()

	func _draw() -> void:
		var col := Color("#c89aff")
		if not _closed:
			var k := clampf(_t / warn, 0.0, 1.0)
			var r := lerpf(radius, 20.0, k)
			var pulse := 0.6 + 0.4 * sin(_t * (16.0 + 20.0 * k))
			draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(1.0, 0.23, 0.23, (0.4 + 0.5 * k) * pulse), 2.0)
			draw_arc(Vector2.ZERO, 18.0, 0, TAU, 24, Color(1.0, 0.23, 0.23, 0.25 * k), 1.0)
			for i in 8:
				var a := _t * 1.5 + TAU * i / 8.0
				var p := Vector2(cos(a), sin(a)) * r
				draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Color(col, 0.9))
			return
		var kk := clampf(1.0 - _ct / 0.8, 0.0, 1.0)
		for i in 10:
			var x := -18.0 + i * 4.0
			var hh := sqrt(maxf(18.0 * 18.0 - x * x, 0.0))
			draw_line(Vector2(x, -hh), Vector2(x, hh), Color(col.lightened(0.3), 0.85 * kk), 1.0)
		draw_arc(Vector2.ZERO, 18.0, 0, TAU, 24, Color(1, 1, 1, kk), 2.0)
