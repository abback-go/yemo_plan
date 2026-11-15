class_name DfArcher
extends PtHero
## 성 방어 시안의 엘프 궁수 (조작 캐릭터). 걷기 입력·속도·충돌은 PtHero 그대로 (WASD·방향키·패드 왼쪽 스틱).
## 조준: 마우스 (패드는 오른쪽 스틱, 폰 시험은 화면 오른쪽 절반을 누른 자리) — 늘 조준 쪽을 바라봄.
## 사격: 왼클릭을 누르고 있으면 연사 (패드 R1·RT) — 쏘는 동안은 조금 느리게 걸음.
## 구르기: Space (패드 A) — 짧게 미끄러지며 그동안 무적. 맞으면 잠깐 무적 + 깜빡임.

signal shot(from: Vector2, dir: Vector2)
signal died

const HP_MAX := 100
const FIRE_INTERVAL := 0.3
const FIRE_SLOW := 0.75 ## 쏘는 동안 걷는 속도 배율
const ROLL_SPEED := 230.0
const ROLL_TIME := 0.3
const ROLL_CD := 0.6 ## 구르기가 끝나고 다시 구를 수 있기까지
const HURT_INVULN := 0.6
const HAND := Vector2(0, -12) ## 화살이 나가는 자리 (발 기준)

var hp := HP_MAX
var alive := true
var aim := Vector2.DOWN
var rolling := 0.0
var touch_fire := false ## 폰 시험: 오른쪽 절반을 누르고 있음 (PtField 방식, DfField가 넣음)
var touch_aim := Vector2.DOWN
var _roll_dir := Vector2.DOWN
var _roll_cd := 0.0
var _fire_cd := 0.0
var _shoot_pose := 0.0
var _invuln := 0.0
var _hurt_flash := 0.0


func _ready() -> void:
	super()
	collision_layer = 4 # 적(층 2)과 서로 막지 않음 — 세상(층 1)에만 막힘
	collision_mask = 1
	sprite.texture = DfArt.archer_sheet()
	sprite.hframes = 7
	sprite.vframes = 3
	sprite.offset = -DfArt.PERSON_FEET


func _aim_input() -> Vector2:
	var stick := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if stick.length() > 0.35:
		return stick.normalized()
	if touch_fire:
		return touch_aim
	var m := get_global_mouse_position() - (global_position + HAND)
	return m.normalized() if m.length() > 3.0 else Vector2.ZERO


func wants_fire() -> bool:
	return touch_fire or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) \
		or Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_SHOULDER) or Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) > 0.5


func _unhandled_input(ev: InputEvent) -> void:
	var k := ev as InputEventKey
	if k != null and k.pressed and not k.echo and k.physical_keycode == KEY_SPACE:
		try_roll()
	var jb := ev as InputEventJoypadButton
	if jb != null and jb.pressed and jb.button_index == JOY_BUTTON_A:
		try_roll()


func try_roll() -> void:
	if not alive or rolling > 0.0 or _roll_cd > 0.0:
		return
	var d := input_dir()
	_roll_dir = (d if d.length() > 0.2 else aim).normalized()
	rolling = ROLL_TIME
	_roll_cd = ROLL_TIME + ROLL_CD
	Sfx.play(&"tn_whoosh", -8.0)


func _physics_process(delta: float) -> void:
	_fire_cd -= delta
	_roll_cd -= delta
	_invuln -= delta
	_shoot_pose -= delta
	if not alive:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		move_and_slide()
		return
	var a := _aim_input()
	if a != Vector2.ZERO:
		aim = a
	if rolling > 0.0:
		rolling -= delta
		velocity = _roll_dir * ROLL_SPEED
		move_and_slide()
		_face_to(_roll_dir)
		return
	var d := input_dir()
	var fire := wants_fire()
	velocity = velocity.move_toward(d * SPEED * (FIRE_SLOW if fire else 1.0), (ACCEL if d != Vector2.ZERO else FRICTION) * delta)
	move_and_slide()
	_face_to(aim)
	if fire and _fire_cd <= 0.0:
		_fire_cd = FIRE_INTERVAL
		_shoot_pose = 0.16
		shot.emit(global_position + HAND + aim * 6.0, aim)
		Sfx.play(&"whoosh", -14.0)


func _face_to(v: Vector2) -> void:
	if absf(v.x) > absf(v.y):
		face = 2
		face_left = v.x < 0.0
	else:
		face = 1 if v.y < 0.0 else 0


## 맞음: 구르는 중·잠깐 무적이면 무시하고 거짓
func hurt(dmg: int) -> bool:
	if not alive or rolling > 0.0 or _invuln > 0.0:
		return false
	hp = maxi(hp - dmg, 0)
	_invuln = HURT_INVULN
	_hurt_flash = 0.15
	Sfx.play(&"hurt", -4.0)
	if hp <= 0:
		alive = false
		died.emit()
	return true


func _process(delta: float) -> void:
	_t += delta
	_hurt_flash -= delta
	var sp := velocity.length()
	var col := 0
	if not alive:
		col = 0
	elif _shoot_pose > 0.0:
		col = 6
	elif sp > 12.0 and rolling <= 0.0:
		_walk += delta * WALK_FPS * clampf(sp / SPEED, 0.6, 1.2)
		col = 2 + int(_walk) % 4
	elif rolling > 0.0:
		col = 3
	else:
		_walk = 0.0
		col = int(_t * 1.6) % 2
	sprite.frame = face * 7 + col
	sprite.flip_h = face == 2 and face_left
	sprite.position = global_position.round() - global_position
	var c := Color.WHITE
	if _hurt_flash > 0.0:
		c = Color(2.0, 0.6, 0.6)
	if rolling > 0.0:
		c.a = 0.55
	elif _invuln > 0.0 and int(_invuln * 20.0) % 2 == 0:
		c.a = 0.35
	if not alive:
		c = Color(0.5, 0.45, 0.6, 0.7)
	sprite.modulate = c
