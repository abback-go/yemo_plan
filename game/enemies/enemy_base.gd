class_name EnemyBase
extends CharacterBody2D
## 적 공통 기반 (docs/prototype.md 10절): 체력, 피격(흰색 깜빡임·넉백·띄우기·피해 숫자), 중력, 사망 연출.
## 원점은 발밑. 자식 클래스가 _build()에서 몸 크기를 정하고 _ai(delta)에서 행동을 결정한다.

signal defeated(enemy: EnemyBase)
signal phase_changed(phase: int) ## 보스: 페이즈가 바뀔 때 (대본이 듣는다)
signal enraged ## 미니보스·보스: 체력이 기준 아래로 처음 내려갈 때 (대본이 듣는다)

const TUNING: Tuning = preload("res://core/tuning.tres")

var tuning: Tuning = TUNING
var max_hp := 50
var hp := 50
var facing := -1
var body_size := Vector2(20, 16) ## 충돌·피격 판정 크기 (px)
var uid := "" ## 방ID:개체ID. 처치하면 GameState에 기록되어 다시 나오지 않음
var kind_id := "" ## 처음 만날 때 이름표를 한 번만 띄우기 위한 종류 이름
var display_name := "" ## 처음 만날 때 띄우는 이름 (예: "폭주 빗자루")
var subtitle := "" ## 이름 아래 한 줄 (예: "청소 당번의 원한")
var is_boss := false ## 화면 아래 보스 체력바
var is_elite := true ## 맞으면 머리 위에 작은 체력바
var flying := false ## 중력을 받지 않음
var knock_mult := 1.0 ## 넉백 배율 (0 = 밀리지 않음)
var launch_mult := 1.0 ## 띄우기 배율 (0 = 뜨지 않음)
var respawns := false ## true면 처치 기록을 남기지 않음 (보스 재도전 등은 방 쪽에서 처리)
var contact_damage := 1
var engaged := true ## 보스: 대본이 전투 시작을 알릴 때까지 false로 두고 기다림 (HUD 체력바도 이때부터)

var _alive := true
var _flash := 0.0
var _knock_vel := 0.0
var _knock_timer := 0.0
var _airborne_spin := 0.0 ## 띄워졌을 때 회전 연출
var _t := 0.0
var _gravity := 1500.0
var _hurtbox: Area2D
var _visual: Node2D
var _bar_t := 0.0 ## 작은 체력바 표시 남은 시간
var _seen_checked := false


func _ready() -> void:
	add_to_group(GameConst.GROUP_ENEMY)
	collision_layer = GameConst.L_ENEMY
	collision_mask = GameConst.L_WORLD | GameConst.L_PLATFORM
	floor_snap_length = 4.0
	_build()
	max_hp = maxi(int(round(max_hp * GameState.difficulty_hp_mult(is_boss))), 1)
	hp = max_hp

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = body_size
	col.shape = rect
	col.position = Vector2(0, -body_size.y / 2.0)
	add_child(col)

	_hurtbox = Area2D.new()
	_hurtbox.name = "Hurtbox"
	_hurtbox.collision_layer = GameConst.L_ENEMY_HURT
	_hurtbox.collision_mask = 0
	_hurtbox.monitoring = false
	var hcol := CollisionShape2D.new()
	var hrect := RectangleShape2D.new()
	hrect.size = body_size + Vector2(4, 4)
	hcol.shape = hrect
	hcol.position = Vector2(0, -body_size.y / 2.0)
	_hurtbox.add_child(hcol)
	add_child(_hurtbox)


## 자식 클래스: max_hp, body_size, 시각 노드 등을 정한다
func _build() -> void:
	pass


## 자식 클래스: 매 물리 프레임 행동 (넉백·띄우기 중엔 호출되지 않음)
func _ai(_delta: float) -> void:
	pass


func is_alive() -> bool:
	return _alive


func _physics_process(delta: float) -> void:
	if not _alive:
		_flash = maxf(_flash - delta, 0.0) # 쓰러진 뒤 사라지는 동안에도 흰 번쩍임은 걷힘
		return
	# 위치 타임 중에는 적의 시간만 느려진다: 타이머·중력·AI에 배율을 곱한 시간을 쓰고,
	# 이동은 속도에 배율을 곱해 move_and_slide 한 뒤 되돌린다.
	var et := Fx.enemy_time
	var d := delta * et
	_t += d
	_flash = maxf(_flash - delta, 0.0)
	_bar_t = maxf(_bar_t - delta, 0.0)
	if not _seen_checked and display_name != "" and Engine.get_physics_frames() % 10 == 0:
		_check_first_sight()
	if not is_on_floor() and (not flying or _airborne_spin != 0.0):
		velocity.y = minf(velocity.y + _gravity * d, 600.0)
	if _knock_timer > 0.0:
		_knock_timer -= d
		velocity.x = _knock_vel * clampf(_knock_timer / 0.14, 0.0, 1.0)
	elif not is_on_floor() and _airborne_spin != 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 200.0 * d)
	else:
		_ai(d)
	velocity *= et
	move_and_slide()
	velocity /= et
	if is_on_floor() and _airborne_spin != 0.0:
		_airborne_spin = 0.0
		_on_landed_from_launch()
	if _visual:
		_visual.queue_redraw()


func _on_landed_from_launch() -> void:
	Fx.burst(global_position, 6, {
		direction = Vector2.UP, spread = 80.0, speed_min = 20.0, speed_max = 60.0, lifetime = 0.3,
		gradient = Palette.fade_gradient(Palette.GROUND_TOP), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 80),
	})


## 넉백을 버티는가 (돌진 중인 돌진형 등)
func _resists_knockback(_hit: Hit) -> bool:
	return false


## 자식 클래스: 피해 배율 (방패로 막으면 0, 약점이면 2 등). hit.kind로 불 종류를 구분할 수 있다
func modify_damage(_hit: Hit) -> float:
	return 1.0


## 여우 모드 공격(푸른 여우불)인가
static func is_fox_hit(hit: Hit) -> bool:
	return String(hit.kind).begins_with("fox")


## 범위 공격용: 점 p에서 적의 몸(피격 상자)까지의 거리. 아귀처럼 큰 적도 몸 어디에 닿든 맞게 한다
static func dist_to_body(e: Node2D, p: Vector2) -> float:
	var be := e as EnemyBase
	if be == null:
		return (e.global_position + Vector2(0, -10)).distance_to(p)
	var bs := be.body_size
	var r := Rect2(be.global_position + Vector2(-bs.x * 0.5, -bs.y), bs)
	var q := Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))
	return q.distance_to(p)


func take_hit(hit: Hit) -> void:
	if not _alive:
		return
	var airborne := not is_on_floor() and not flying
	var mult := modify_damage(hit)
	if mult <= 0.0:
		_on_blocked(hit)
		return
	var dmg := maxi(int(round(hit.damage * mult)), 1)
	hp -= dmg
	_bar_t = 2.5
	_flash = tuning.enemy_flash_time + 0.03
	var heavy := dmg >= 25
	if GameState.settings.get("damage_numbers", true):
		Fx.damage_number(global_position + Vector2(0, -body_size.y - 4), dmg, heavy, is_fox_hit(hit))
	Fx.hitstop(hit.hitstop)
	Fx.shake(hit.shake_t)
	Fx.zoom_punch(hit.zoom)
	StyleRank.register_hit(hit.kind, airborne)
	var p := player()
	if p:
		p.on_hit_landed(hit)
	if hit.kind == &"bolt" or hit.kind == &"bolt_heavy":
		Sfx.play(&"hit_heavy" if heavy else &"hit", -2.0 if heavy else -4.0)
	var dir := hit.dir_from(global_position)
	_on_hit(hit, dir)
	if hit.knockback_t > 0.0 and knock_mult > 0.0 and (hit.ignores_knock_resist or not _resists_knockback(hit)):
		_knock_vel = dir * 2.0 * hit.knockback_t * knock_mult * GameConst.TILE / 0.14
		_knock_timer = 0.14
	if hit.launch_t > 0.0 and launch_mult > 0.0:
		velocity.y = -sqrt(2.0 * _gravity * hit.launch_t * launch_mult * GameConst.TILE)
		_airborne_spin = float(dir)
	elif airborne and _airborne_spin != 0.0 and tuning.juggle_lift_t > 0.0 and launch_mult > 0.0:
		# 띄워 맞히기: 공중에 뜬 적은 화염탄에 맞을 때마다 조금씩 다시 떠올라 공중에 머문다
		velocity.y = minf(velocity.y, -sqrt(2.0 * _gravity * tuning.juggle_lift_t * GameConst.TILE))
	if hp <= 0:
		_die(dir)


## 자식 클래스: 맞았을 때 반응 (돌진 끊기, 맞은 쪽 돌아보기 등)
func _on_hit(_hit: Hit, _dir: int) -> void:
	pass


## 막혔을 때 (방패 등): 불꽃 튀김 + "팅"
func _on_blocked(hit: Hit) -> void:
	var p := hit.source_pos if hit.source_pos != Vector2.ZERO else global_position
	var at := global_position + Vector2(signf(p.x - global_position.x) * body_size.x * 0.5, -body_size.y * 0.6)
	Fx.burst(at, 8, {spread = 60.0, direction = Vector2(signf(p.x - global_position.x), -0.3), speed_min = 60.0,
		speed_max = 140.0, lifetime = 0.2, gradient = Palette.fade_gradient(Color(0.9, 0.95, 1.0)), gravity = Vector2(0, 300)})
	Sfx.play(&"block", -2.0, 0.08)


func _check_first_sight() -> void:
	var p := player()
	if p == null:
		return
	if global_position.distance_to(p.global_position) > 15.0 * GameConst.TILE:
		return
	_seen_checked = true
	var key := "seen_" + (kind_id if kind_id != "" else display_name)
	if GameState.has_flag(key):
		return
	GameState.set_flag(key)
	var hud := get_tree().get_first_node_in_group(&"hud")
	if hud and hud.has_method("enemy_card"):
		hud.enemy_card(display_name, subtitle, is_boss)


func show_bar() -> bool:
	return is_elite and not is_boss and _bar_t > 0.0 and _alive


func _die(dir: int) -> void:
	_alive = false
	if not respawns:
		GameState.mark_killed(uid)
	GameState.add("kills")
	StyleRank.on_kill()
	Fx.hitstop(tuning.hitstop_kill)
	defeated.emit(self)
	Sfx.play(&"enemy_die")
	var c := global_position + Vector2(0, -body_size.y / 2.0)
	Fx.burst(c, 34, {
		spread = 180.0, speed_min = 40.0, speed_max = 190.0, damping = 60.0, lifetime = 0.8,
		gradient = Palette.soul_gradient(), size_min = 1.5, size_max = 3.5, gravity = Vector2(0, -40),
		direction = Vector2(dir, -0.5), add = true,
	})
	Fx.burst(c, 12, {
		spread = 180.0, speed_min = 30.0, speed_max = 90.0, lifetime = 0.5,
		size_min = 1.0, size_max = 2.5, gravity = Vector2(0, 100),
	})
	Fx.ring(c, 4.0, 30.0, Palette.ENEMY_SOUL, 0.35, 2.0)
	collision_layer = 0
	_hurtbox.set_deferred("monitorable", false)
	for c2 in get_children():
		if c2 is EnemyAttackArea:
			c2.active = false
	# 하얗게 번쩍인 뒤 위로 흩어지며 사라짐
	if _visual:
		_flash = 1.0
		var t := create_tween()
		t.tween_property(_visual, "scale", Vector2(1.3, 0.2), 0.18).set_trans(Tween.TRANS_QUAD)
		t.parallel().tween_property(_visual, "modulate:a", 0.0, 0.18)
		t.tween_callback(queue_free)
	else:
		queue_free()


## 시각 노드가 그릴 때 쓰는 흰색 깜빡임 양 (0~1)
func flash_amount() -> float:
	return 1.0 if _flash > 0.0 else 0.0


func player() -> Player:
	return get_tree().get_first_node_in_group(GameConst.GROUP_PLAYER) as Player


# ─── 자식 클래스용 도우미 ───────────────────────────────

func dist_to_player() -> float:
	var p := player()
	return INF if p == null else global_position.distance_to(p.global_position)


func dir_to_player() -> int:
	var p := player()
	if p == null:
		return facing
	return 1 if p.global_position.x >= global_position.x else -1


func face_player() -> void:
	facing = dir_to_player()


## 직선·포물선 탄 발사 (EnemyProjectile)
func shoot(pos: Vector2, dir: Vector2, speed: float, style := "fireball", opts := {}) -> EnemyProjectile:
	var pr := EnemyProjectile.new()
	pr.setup(pos, dir, speed, style, opts)
	Fx.effect_parent().add_child(pr)
	return pr


## 공격 판정 영역을 붙이고 돌려줌 (켜고 끄기는 active)
func add_attack_area(size: Vector2, offset: Vector2, cause := &"enemy", damage := 1) -> EnemyAttackArea:
	var a := EnemyAttackArea.with_rect(size, offset)
	a.cause = cause
	a.damage = damage
	add_child(a)
	return a
