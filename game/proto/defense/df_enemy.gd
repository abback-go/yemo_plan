class_name DfEnemy
extends CharacterBody2D
## 성 방어 시안의 적. 원점 = 발밑. 세상(층 1)에만 막히고 적끼리·궁수와는 서로 막지 않음 (겹치지 않게 밀어내기만).
## 구울: 성문으로 달려가다 궁수가 가까우면 쫓음 → 붙으면 0.3초 칼을 들었다(예고) 내려침 — 그새 피하면 빗나감.
## 어둠 마법사: 성문 쪽으로 걷다 궁수가 사정거리에 들면 멈춰 0.55초 지팡이를 들고(예고) 보라 구슬을 쏨. 궁수가 멀면 성문을 쏨.

enum Kind { GHOUL, MAGE }

const STATS := {
	Kind.GHOUL: {"hp": 30, "speed": 52.0, "aggro": 80.0, "reach": 14.0, "wind": 0.3, "cd": 1.0, "dmg": 8, "gate_dmg": 4},
	Kind.MAGE: {"hp": 24, "speed": 34.0, "aggro": 170.0, "reach": 150.0, "wind": 0.55, "cd": 2.2, "dmg": 10, "gate_dmg": 6},
}
const HIT_R := 8.0 ## 화살 맞는 반지름
const BODY_Y := -9.0 ## 몸 가운데 (발 기준)
const SEP := 13.0 ## 적끼리 이만큼 안이면 밀어냄

var kind := Kind.GHOUL
var hp := 30
var dead := false
var field: Node2D ## DfField
var sprite: Sprite2D
var _col: CollisionShape2D
var _cd := 0.0
var _wind := 0.0
var _wind_at_gate := false
var _flash := 0.0
var _anim := 0.0


func setup(k: int, f: Node2D) -> void:
	kind = k
	field = f
	hp = int(STATS[kind].hp)


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var sh := Sprite2D.new()
	sh.texture = PtArt.blob()
	add_child(sh)
	sprite = Sprite2D.new()
	sprite.centered = false
	if kind == Kind.GHOUL:
		sprite.texture = DfArt.ghoul_sheet()
		sprite.hframes = 5
		sprite.offset = -DfArt.GHOUL_FEET
	else:
		sprite.texture = DfArt.mage_sheet()
		sprite.hframes = 3
		sprite.offset = -DfArt.MAGE_FEET
	add_child(sprite)
	_col = CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 5.0
	_col.shape = cs
	add_child(_col)
	_cd = randf_range(0.2, 0.8)


func center() -> Vector2:
	return global_position + Vector2(0, BODY_Y)


func _physics_process(delta: float) -> void:
	if dead:
		return
	_cd -= delta
	var st: Dictionary = STATS[kind]
	var archer: DfArcher = field.get("archer")
	var gate: Vector2 = field.get("gate_point")
	var to_a := archer.global_position - global_position
	var near := archer.alive and to_a.length() < float(st.aggro)
	if _wind > 0.0: # 예고 중: 멈춰 있음
		_wind -= delta
		velocity = Vector2.ZERO
		if _wind <= 0.0:
			_strike(archer, gate, st)
		move_and_slide()
		return
	var target := archer.global_position if near else gate
	var dist := global_position.distance_to(target)
	var reach: float = float(st.reach) if near else (16.0 if kind == Kind.GHOUL else float(st.reach))
	if dist <= reach:
		velocity = Vector2.ZERO
		if _cd <= 0.0:
			_wind = float(st.wind)
			_wind_at_gate = not near
			if kind == Kind.MAGE:
				Sfx.play(&"tn_charge", -14.0)
	else:
		velocity = (target - global_position).normalized() * float(st.speed)
	var push := Vector2.ZERO
	for e: DfEnemy in field.get("enemies"):
		if e == self or e.dead:
			continue
		var dv := global_position - e.global_position
		var dl := dv.length()
		if dl < SEP and dl > 0.01:
			push += dv / dl * (SEP - dl)
	velocity += push * 6.0
	move_and_slide()
	if absf(velocity.x) > 4.0:
		sprite.flip_h = velocity.x > 0.0


## 예고가 끝남: 구울은 아직 닿으면 피해, 마법사는 구슬을 쏨
func _strike(archer: DfArcher, gate: Vector2, st: Dictionary) -> void:
	_cd = float(st.cd)
	if kind == Kind.GHOUL:
		if _wind_at_gate:
			if global_position.distance_to(gate) <= 22.0:
				field.call("damage_gate", int(st.gate_dmg))
		elif archer.alive and global_position.distance_to(archer.global_position) <= float(st.reach) + 6.0:
			archer.hurt(int(st.dmg))
		return
	var from := center() + Vector2(6, -10)
	var to := gate if _wind_at_gate else archer.global_position + DfArcher.HAND
	field.call("spawn_orb", from, (to - from).normalized(), int(st.gate_dmg if _wind_at_gate else st.dmg))


## 화살에 맞음 (dir = 화살이 날아온 쪽)
func hit(dmg: int, dir: Vector2) -> void:
	if dead:
		return
	hp -= dmg
	_flash = 0.1
	global_position += dir * 2.0
	Sfx.play(&"arrow_hit", -10.0)
	if hp <= 0:
		dead = true
		_col.set_deferred("disabled", true)
		Sfx.play(&"hit_heavy", -10.0)
		field.call("on_enemy_dead", self)
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.35)
		tw.parallel().tween_property(self, "scale", Vector2(1.3, 0.4), 0.35)
		tw.tween_callback(queue_free)


func _process(delta: float) -> void:
	_anim += delta
	_flash -= delta
	var f := 0
	if kind == Kind.GHOUL:
		f = 4 if _wind > 0.0 else (int(_anim * 8.0) % 4 if velocity.length() > 5.0 else int(_anim * 2.0) % 2)
	else:
		f = 2 if _wind > 0.0 else (int(_anim * 4.0) % 2 if velocity.length() > 5.0 else 0)
	sprite.frame = f
	sprite.modulate = Color(3, 3, 3) if _flash > 0.0 else (Color(1.4, 1.1, 1.6) if _wind > 0.0 and kind == Kind.MAGE else Color.WHITE)
	sprite.position = global_position.round() - global_position
