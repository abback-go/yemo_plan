class_name Charger
extends EnemyBase
## 돌진형 (docs/prototype.md 6.1절): 순찰 → 감지 → 예고(웅크리며 붉게 빛남) → 돌진 → 후딜레이.
## 거리를 벌리고 쏘기만 하는 플레이를 깨뜨린다. 화염 폭풍을 맞으면 돌진이 끊긴다.

enum S { PATROL, WINDUP, CHARGE, RECOVER, STAGGER }

@export var patrol_range_t := 4.0 ## 처음 자리에서 좌우로 순찰하는 거리 (T)

var state: S = S.PATROL
var _timer := 0.0
var _charge_start_x := 0.0
var _charge_frames := 0
var _home_x := 0.0
var _trail_timer := 0.0
var _contact: EnemyAttackArea


func _build() -> void:
	max_hp = tuning.charger_hp
	body_size = Vector2(24, 16)
	_visual = ChargerVisual.new()
	_visual.enemy = self
	add_child(_visual)
	_contact = EnemyAttackArea.with_rect(Vector2(22, 14), Vector2(0, -8))
	_contact.cause = &"charger"
	add_child(_contact)


func _ready() -> void:
	super()
	_home_x = global_position.x


func _ai(delta: float) -> void:
	var t := GameConst.TILE
	_contact.dodgeable = state == S.CHARGE # 걷는 몸에 부딪힌 건 회피가 아니다
	match state:
		S.PATROL:
			velocity.x = facing * tuning.charger_patrol_speed_t * t
			var too_far := (facing > 0 and global_position.x > _home_x + patrol_range_t * t) \
				or (facing < 0 and global_position.x < _home_x - patrol_range_t * t)
			if too_far or is_on_wall() or _ledge_ahead():
				facing = -facing
			if _sees_player():
				_start_windup()
		S.WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			_timer -= delta
			if _timer <= 0.0:
				_start_charge()
		S.CHARGE:
			velocity.x = facing * tuning.charger_speed_t * t
			_charge_frames += 1
			_trail_timer -= delta
			if _trail_timer <= 0.0:
				_trail_timer = 0.04
				Fx.burst(global_position + Vector2(-facing * 10, -2), 2, {
					direction = Vector2(-facing, -0.6), spread = 25.0, speed_min = 20.0, speed_max = 60.0,
					lifetime = 0.3, gradient = Palette.fade_gradient(Palette.GROUND_TOP), size_min = 1.0, size_max = 2.5,
					gravity = Vector2(0, -20),
				})
			var traveled := absf(global_position.x - _charge_start_x)
			var hit_wall := is_on_wall() and _charge_frames > 2
			if traveled >= tuning.charger_charge_distance_t * t or hit_wall or _ledge_ahead():
				_start_recover(hit_wall)
		S.RECOVER, S.STAGGER:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			_timer -= delta
			if _timer <= 0.0:
				state = S.PATROL
				_face_player()


func _sees_player() -> bool:
	var p := player()
	if p == null or not p.is_alive():
		return false
	var dx := p.global_position.x - global_position.x
	if signf(dx) != facing:
		return false
	if absf(dx) > tuning.charger_detect_t * GameConst.TILE:
		return false
	if absf(p.global_position.y - global_position.y) > 2.5 * GameConst.TILE:
		return false
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -8), p.center(), GameConst.L_WORLD)
	return space.intersect_ray(q).is_empty()


func _ledge_ahead() -> bool:
	var space := get_world_2d().direct_space_state
	var from := global_position + Vector2(facing * 14, -4)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 14), GameConst.L_WORLD | GameConst.L_PLATFORM)
	return space.intersect_ray(q).is_empty()


func _face_player() -> void:
	var p := player()
	if p:
		facing = 1 if p.global_position.x >= global_position.x else -1


func _start_windup() -> void:
	state = S.WINDUP
	_timer = tuning.charger_windup
	_face_player()
	Sfx.play(&"charger_windup", -2.0)


func _start_charge() -> void:
	state = S.CHARGE
	_charge_start_x = global_position.x
	_charge_frames = 0
	Sfx.play(&"charger_charge", -1.0)


func _start_recover(hit_wall: bool) -> void:
	state = S.RECOVER
	_timer = tuning.charger_recover
	if hit_wall:
		Fx.shake(0.12, 0.15)
		Sfx.play(&"land", 0.0, 0.1)
		Fx.burst(global_position + Vector2(facing * 12, -8), 8, {
			direction = Vector2(-facing, -1), spread = 60.0, speed_min = 30.0, speed_max = 90.0, lifetime = 0.35,
			gradient = Palette.fade_gradient(Palette.GROUND_TOP), size_min = 1.0, size_max = 2.5,
		})


func _resists_knockback(hit: Hit) -> bool:
	return state == S.CHARGE and not hit.breaks_charge


func _on_hit(hit: Hit, dir: int) -> void:
	if state == S.CHARGE and (hit.breaks_charge or hit.launch_t > 0.0):
		state = S.STAGGER
		_timer = 0.6
	elif state == S.PATROL:
		facing = -dir # 맞은 쪽(공격한 쪽)을 돌아본다
	if hit.launch_t > 0.0 and state == S.WINDUP:
		state = S.STAGGER
		_timer = 0.6
