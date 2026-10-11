class_name StoneFox
extends Charger
## 석상 여우 (docs/archive/sera/chapter1.md 7절·12.5절): 돌진형(Charger)의 신계판. 공략 포인트 = 돌진 직전 대시(위치 타임) / 벽으로 유도.
## 처음엔 석상인 척 가만히 있다가 세라가 8T 안으로 오면(또는 맞으면) 돌가루를 털며 깨어난다.
## 순찰 → 붉게 빛나는 눈(예고 0.65초) → 돌진(17 T/s, 이때만 퍼펙트 회피 대상) → 후딜레이.
## 돌진하다 벽에 부딪히면 금이 가며 1.2초 기절하고, 기절한 동안은 1.5배 피해를 받는다.

const HP := 160
const WINDUP := 0.65 ## 돌진 예고 (기존 돌진형 0.55보다 조금 길게: 퍼펙트 회피 안내용)
const WALL_STUN := 1.2
const STUN_DAMAGE_MULT := 1.5
const WAKE_RANGE_T := 8.0
const WAKE_TIME := 0.7
const STONE := Color("#4a4a5e")

var awake := false
var wall_stunned := false
var cracks := 0 ## 벽에 부딪힌 횟수 (금 그림)
var wake_left := 0.0


func _build() -> void:
	max_hp = HP
	body_size = Vector2(26, 18)
	knock_mult = 0.5 # 돌이라 덜 밀린다
	kind_id = "stone_fox"
	display_name = "석상 여우"
	subtitle = "수문의 파수꾼"
	_visual = StoneFoxVisual.new()
	_visual.enemy = self
	add_child(_visual)
	_contact = EnemyAttackArea.with_rect(Vector2(24, 15), Vector2(0, -8))
	_contact.cause = &"stone_fox"
	add_child(_contact)


func windup_k() -> float:
	return clampf(1.0 - _timer / WINDUP, 0.0, 1.0) if state == S.WINDUP else 0.0


func _ai(delta: float) -> void:
	_contact.active = awake # 잠든 석상은 그냥 돌덩이
	if not awake:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		_contact.dodgeable = false
		var p := player()
		if p and p.is_alive() and dist_to_player() <= WAKE_RANGE_T * GameConst.TILE \
				and absf(p.global_position.y - global_position.y) < 4.0 * GameConst.TILE:
			_wake()
		return
	if wake_left > 0.0:
		# 돌가루를 털며 일어나는 중
		wake_left -= delta
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		_contact.dodgeable = false
		if wake_left <= 0.0:
			state = S.PATROL
			face_player()
		return
	super(delta)
	if wall_stunned and state == S.PATROL:
		wall_stunned = false


func _wake() -> void:
	if awake:
		return
	awake = true
	wake_left = WAKE_TIME
	face_player()
	_home_x = global_position.x
	Sfx.play(&"crumble", -12.0, 0.1)
	Fx.burst(global_position + Vector2(0, -10), 12, {
		spread = 180.0, speed_min = 15.0, speed_max = 60.0, lifetime = 0.5, box = Vector2(12, 6),
		gradient = Palette.fade_gradient(Color("#8a8aa0")), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 120),
	})


func _start_windup() -> void:
	super()
	_timer = WINDUP


func _start_recover(hit_wall: bool) -> void:
	super(hit_wall)
	if hit_wall:
		wall_stunned = true
		_timer = WALL_STUN
		cracks = mini(cracks + 1, 3)
		Sfx.play(&"crumble", -4.0, 0.1)
		Fx.shake(0.2, 0.2)
		Fx.burst(global_position + Vector2(facing * 12, -10), 12, {
			direction = Vector2(-facing, -1), spread = 70.0, speed_min = 40.0, speed_max = 120.0, lifetime = 0.5,
			gradient = Palette.fade_gradient(STONE.lightened(0.3)), size_min = 1.5, size_max = 3.0, gravity = Vector2(0, 400),
		})


## 벽에 박혀 기절한 동안은 밀리지 않는다 (넉백 중엔 _ai가 멈춰 기절이 끝없이 늘어나는 것을 막음)
func _resists_knockback(hit: Hit) -> bool:
	return wall_stunned or super(hit)


## 벽에 박혀 기절한 동안은 금 간 돌이라 더 아프다
func modify_damage(_hit: Hit) -> float:
	return STUN_DAMAGE_MULT if wall_stunned else 1.0


func _on_hit(hit: Hit, dir: int) -> void:
	if not awake:
		_wake()
		return
	if wake_left > 0.0:
		return
	super(hit, dir)
