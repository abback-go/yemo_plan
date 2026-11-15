class_name ArmorKnight
extends EnemyBase
## 갑옷 수호기사 (docs/archive/sera/chapter1.md 7절·12.4절·12.5절): 복도를 지키던 빈 갑옷이 지하에서 새어 나온 마력으로 움직인다.
## 커다란 탑 방패로 정면을 막는다: 정면 화염탄은 방패에 튕겨 나가고(피해 0, "팅"), 몸을 빨리 돌려 등 뒤 돌기도 잘 안 통한다.
## 답: 점프해서 방패 위(투구 높이)로 쏘기, 불기둥(발밑), 여우불(방패를 4초간 깸).
## 세라가 머리 위에 0.6초 넘게 있으면 방패를 머리 위로 올려친다 — 방패를 든 동안엔 정면이 열린다.
## 패턴: 방패 밀치기(0.5초 예고 → 짧은 돌진) / 내려베기(0.7초 예고, 앞쪽 큰 판정) / 대공 방패 올려치기(0.35초 예고).

enum S { IDLE, ADVANCE, TURN, BASH_WINDUP, BASH, BASH_RECOVER, SLAM_WINDUP, SLAM, SLAM_RECOVER, AA_WINDUP, AA_THRUST, AA_RECOVER, STAGGER }

const HP := 420
const SHIELD_TOP := 30.0 ## 발밑에서 방패 윗변까지 높이(px). 이보다 높은 곳에 맞으면 투구(방패 위)라 막히지 않는다
const WALK_SPEED_T := 2.2
const KEEP_DIST_T := 2.0
const TURN_DELAY := 0.12 ## 등 뒤로 돌아가도 이만큼 뒤 바로 돌아선다
const TURN_TIME := 0.1
const SLAM_RANGE_T := 2.8
const BASH_RANGE_T := 5.0
const BASH_WINDUP := 0.5
const BASH_TIME := 0.24
const BASH_SPEED_T := 15.0
const BASH_RECOVER := 0.45
const SLAM_WINDUP := 0.7
const SLAM_ACTIVE := 0.14
const SLAM_RECOVER := 0.8
const AA_TRIGGER := 0.6 ## 머리 위에 이만큼 머물면 대공
const AA_WINDUP := 0.35
const AA_ACTIVE := 0.2
const AA_RECOVER := 0.6
const SHIELD_BREAK_TIME := 4.0
const BASH_OFFSET := Vector2(15, -21)
const SLAM_OFFSET := Vector2(28, -22)
const AA_OFFSET := Vector2(2, -60)
const MANA := Color("#b77bff") ## 폭주 마력
const UNBLOCKABLE := Hit.PASS_SHIELD_ARMOR ## 발밑·위에서 오거나 방패를 넘는 공격

var state: S = S.ADVANCE
var shield_broken := 0.0 ## 방패가 깨진 채 남은 시간 (그림이 읽는다)
var shield_flash := 0.0 ## 막았을 때 방패 테두리 번쩍임
var _timer := 0.0
var _state_time := 0.0
var _behind_t := 0.0
var _above_t := 0.0
var _attack_cd := 0.8
var _wisp_t := 0.0
var _contact: EnemyAttackArea
var _bash: EnemyAttackArea
var _slam: EnemyAttackArea
var _aa: EnemyAttackArea


func _build() -> void:
	max_hp = HP
	body_size = Vector2(20, 46)
	knock_mult = 0.35
	launch_mult = 0.5
	display_name = "갑옷 수호기사"
	subtitle = "복도의 마지막 당직"
	kind_id = "armor"
	var v := ArmorKnightVisual.new()
	v.enemy = self
	_visual = v
	add_child(v)
	_contact = add_attack_area(Vector2(18, 40), Vector2(0, -21), &"armor")
	_contact.dodgeable = false
	_bash = add_attack_area(Vector2(16, 40), BASH_OFFSET, &"armor")
	_bash.active = false
	_slam = add_attack_area(Vector2(42, 46), SLAM_OFFSET, &"armor")
	_slam.active = false
	_aa = add_attack_area(Vector2(34, 30), AA_OFFSET, &"armor")
	_aa.active = false


## 상태 진행도 0→1 (예고 연출용)
func progress() -> float:
	if _state_time <= 0.0:
		return 1.0
	return clampf(1.0 - _timer / _state_time, 0.0, 1.0)


## 방패를 머리 위로 들고 있는가 (이때 정면이 열린다)
func shield_raised() -> bool:
	return state == S.AA_WINDUP or state == S.AA_THRUST or state == S.AA_RECOVER


func _set_state(s: S, time := 0.0) -> void:
	state = s
	_timer = time
	_state_time = time


func _ai(delta: float) -> void:
	var t := GameConst.TILE
	if shield_broken > 0.0:
		shield_broken -= delta
		if shield_broken <= 0.0:
			_reform_shield()
	shield_flash = maxf(shield_flash - delta, 0.0)
	place_area(_bash, BASH_OFFSET)
	place_area(_slam, SLAM_OFFSET)
	place_area(_aa, AA_OFFSET)
	_leak_mana(delta)

	var p := player()
	if not engaged or p == null or not p.is_alive():
		_set_state(S.IDLE)
		_attacks_off()
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		return
	if state == S.IDLE:
		_set_state(S.ADVANCE)

	var dx := p.global_position.x - global_position.x
	var dy := p.global_position.y - global_position.y
	var adx := absf(dx)
	# 머리 위 감시: 투구보다 높은 곳, 좌우 1.6T 안
	var above := adx < 1.6 * t and dy < -body_size.y and dy > -9.0 * t
	if above and (state == S.ADVANCE or state == S.TURN or state == S.BASH_RECOVER or state == S.SLAM_RECOVER):
		_above_t += delta
	else:
		_above_t = maxf(_above_t - delta * 2.0, 0.0)
	_timer -= delta
	match state:
		S.ADVANCE:
			_advance(delta, dx, dy, adx)
		S.TURN:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _timer <= 0.0:
				facing = -facing
				_behind_t = 0.0
				_set_state(S.ADVANCE)
				Sfx.play(&"chain", -10.0, 0.1)
		S.BASH_WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _timer <= 0.0:
				_set_state(S.BASH, BASH_TIME)
				_bash.active = true
				_bash.dodgeable = true
				Sfx.play(&"charger_charge", -2.0)
		S.BASH:
			velocity.x = facing * BASH_SPEED_T * t
			if _timer <= 0.0 or is_on_wall() or ledge_ahead(14.0, 16.0):
				_bash.active = false
				velocity.x = facing * 3.0 * t
				_set_state(S.BASH_RECOVER, BASH_RECOVER)
		S.SLAM_WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _timer <= 0.0:
				_do_slam()
		S.SLAM:
			velocity.x = 0.0
			if _timer <= 0.0:
				_slam.active = false
				_set_state(S.SLAM_RECOVER, SLAM_RECOVER)
		S.AA_WINDUP:
			velocity.x = 0.0
			if _timer <= 0.0:
				_set_state(S.AA_THRUST, AA_ACTIVE)
				_aa.active = true
				_aa.dodgeable = true
				if is_on_floor():
					velocity.y = -170.0 # 방패를 밀어 올리며 살짝 뛴다
				Sfx.play(&"swing", 0.0, 0.1)
				Sfx.play(&"block", -6.0)
		S.AA_THRUST:
			velocity.x = 0.0
			if _timer <= 0.0:
				_aa.active = false
				_set_state(S.AA_RECOVER, AA_RECOVER)
		S.BASH_RECOVER, S.SLAM_RECOVER, S.AA_RECOVER, S.STAGGER:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if _timer <= 0.0:
				_attack_cd = 0.4 if state == S.STAGGER else 0.6
				_set_state(S.ADVANCE)


func _advance(delta: float, dx: float, dy: float, adx: float) -> void:
	var t := GameConst.TILE
	_attack_cd -= delta
	var ahead := signf(dx) == float(facing)
	# 몸을 빨리 돌린다: 등 뒤로 돌아가도 금세 방패가 따라온다
	if not ahead and adx > 4.0:
		_behind_t += delta
		if _behind_t >= TURN_DELAY:
			_set_state(S.TURN, TURN_TIME)
			return
	else:
		_behind_t = 0.0
	if _above_t >= AA_TRIGGER:
		_above_t = 0.0
		_set_state(S.AA_WINDUP, AA_WINDUP)
		Sfx.play(&"charger_windup", -4.0, 0.0)
		return
	var want := 0.0
	if ahead and adx > KEEP_DIST_T * t and not ledge_ahead(14.0, 16.0):
		want = facing * WALK_SPEED_T * t
	velocity.x = move_toward(velocity.x, want, 500.0 * delta)
	if _attack_cd > 0.0 or not ahead or absf(dy) > 2.5 * t:
		return
	if adx <= SLAM_RANGE_T * t and randf() < 0.6:
		_set_state(S.SLAM_WINDUP, SLAM_WINDUP)
		Sfx.play(&"growl", -4.0, 0.1)
		Sfx.play(&"chain", -6.0, 0.1)
	elif adx <= BASH_RANGE_T * t:
		_set_state(S.BASH_WINDUP, BASH_WINDUP)
		Sfx.play(&"charger_windup", -3.0, 0.05)


func _do_slam() -> void:
	_set_state(S.SLAM, SLAM_ACTIVE)
	_slam.active = true
	_slam.dodgeable = true
	Sfx.play(&"swing", 0.0, 0.1)
	Sfx.play(&"slam", -2.0, 0.1)
	Fx.shake(0.2, 0.2)
	var tip := global_position + Vector2(facing * 32, -2)
	Fx.burst(tip, 10, {
		direction = Vector2(-facing, -1), spread = 60.0, speed_min = 50.0, speed_max = 150.0, lifetime = 0.3,
		gradient = Palette.fade_gradient(Color(1.0, 0.9, 0.7)), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 300),
	})
	Fx.ring(tip, 3.0, 22.0, Color(1.0, 0.55, 0.5), 0.2, 1.0)


func _attacks_off() -> void:
	_bash.active = false
	_slam.active = false
	_aa.active = false


func modify_damage(hit: Hit) -> float:
	if is_fox_hit(hit) or shield_broken > 0.0 or hit.kind in UNBLOCKABLE:
		return 1.0
	if shield_raised():
		return 1.0 # 방패를 머리 위로 든 동안은 정면이 열려 있다
	var high := hit.source_pos.y < global_position.y - SHIELD_TOP # 방패 위로 투구를 맞힘
	if hit_side(hit, 6.0) > 0 and not high:
		return 0.0
	return 1.0


func _resists_knockback(hit: Hit) -> bool:
	return (state == S.BASH or state == S.SLAM_WINDUP or state == S.SLAM or state == S.AA_THRUST) and not hit.breaks_charge


func _on_hit(hit: Hit, _dir: int) -> void:
	if is_fox_hit(hit) and shield_broken <= 0.0:
		_break_shield()
	elif state == S.ADVANCE and hit_side(hit, 6.0) < 0:
		_behind_t = TURN_DELAY # 등을 맞으면 곧장 돌아본다


## 방패에 막힘: 불꽃 + "팅". 화염탄은 방패에 맞고 튕겨 나가는 모습, 화염 폭풍은 막아도 조금 밀린다
func _on_blocked(hit: Hit) -> void:
	super(hit)
	shield_flash = 0.12
	var at := global_position + Vector2(facing * 14, clampf(hit.source_pos.y - global_position.y, -SHIELD_TOP, -6.0))
	if hit.kind == &"bolt" or hit.kind == &"bolt_heavy":
		var r := ReflectSpark.new()
		r.position = at
		var back := float(-hit.direction) if hit.direction != 0 else float(facing)
		r.vel = Vector2(back * randf_range(150.0, 200.0), randf_range(-190.0, -120.0))
		r.big = hit.kind == &"bolt_heavy"
		Fx.effect_parent().add_child(r)
	if hit.breaks_charge and hit.knockback_t > 0.0 and _knock_timer <= 0.0:
		_knock_vel = hit.dir_from(global_position) * 2.0 * minf(hit.knockback_t, 2.0) * knock_mult * GameConst.TILE / 0.14 * 0.5
		_knock_timer = 0.14


func _break_shield() -> void:
	shield_broken = SHIELD_BREAK_TIME
	_attacks_off()
	_set_state(S.STAGGER, 0.6)
	var at := global_position + Vector2(facing * 13, -20)
	Sfx.play(&"crumble", -2.0)
	Sfx.play(&"block", 0.0, 0.0)
	Fx.shake(0.15, 0.2)
	Fx.burst(at, 18, {
		direction = Vector2(facing, -0.6), spread = 80.0, speed_min = 60.0, speed_max = 170.0, lifetime = 0.5,
		gradient = Palette.fade_gradient(Color("#9aa4c0")), size_min = 1.5, size_max = 3.0, gravity = Vector2(0, 400),
	})
	Fx.burst(at, 14, {
		spread = 180.0, speed_min = 30.0, speed_max = 90.0, lifetime = 0.5,
		gradient = Palette.fade_gradient(Color(0.55, 0.85, 1.0)), size_min = 1.0, size_max = 2.5, gravity = Vector2(0, -40), add = true,
	})
	Fx.ring(at, 4.0, 26.0, Color(0.55, 0.85, 1.0), 0.3, 2.0)


func _reform_shield() -> void:
	shield_broken = 0.0
	var at := global_position + Vector2(facing * 13, -20)
	Sfx.play(&"chain", -4.0)
	Sfx.play(&"reveal", -10.0, 0.0)
	Fx.ring(at, 18.0, 4.0, MANA, 0.3, 1.0)


## 폭주 마력이 투구 틈과 관절에서 새어 나온다
func _leak_mana(delta: float) -> void:
	_wisp_t -= delta
	if _wisp_t > 0.0:
		return
	_wisp_t = 0.16
	var spots := [Vector2(2, -40), Vector2(0, -34), Vector2(-3, -14), Vector2(4, -14)]
	var s: Vector2 = spots[randi() % spots.size()]
	Fx.burst(global_position + Vector2(s.x * facing, s.y), 1, {
		direction = Vector2.UP, spread = 25.0, speed_min = 8.0, speed_max = 20.0, lifetime = 0.8,
		gradient = Palette.fade_gradient(MANA), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, -20), add = true,
	})


## 방패에 튕겨 나가는 화염탄 (보이기만 하는 연출, 피해 없음)
class ReflectSpark extends Node2D:
	const LIFE := 0.32

	var vel := Vector2.ZERO
	var big := false
	var _t := 0.0

	func _ready() -> void:
		material = Fx.add_material
		z_index = 5

	func _process(delta: float) -> void:
		_t += delta
		position += vel * delta
		vel.y += 520.0 * delta
		if _t >= LIFE:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := 1.0 - _t / LIFE
		var d := vel.normalized()
		var r := (3.0 if big else 2.0) * k + 0.5
		draw_line(-d * 12.0 * k, Vector2.ZERO, Color(Palette.FIRE_OUT, 0.7 * k), r * 1.4)
		draw_circle(Vector2.ZERO, r + 1.0, Color(Palette.FIRE_MID, 0.6 * k))
		draw_circle(Vector2.ZERO, r * 0.6, Color(Palette.FIRE_CORE, k))
