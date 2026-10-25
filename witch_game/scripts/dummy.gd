class_name Dummy
extends CharacterBody2D
## 허수아비 (적 1종, 임시 도형). 맞으면 하얗게 번쩍이고 밀려나며 피해 숫자를 띄운다.
## 쓰러지지 않는다 — 체력이 0이 되거나 DUMMY_REGEN_DELAY초 동안 안 맞으면 다시 가득 찬다.

const SIZE := Vector2(16, 30)
const GRAVITY := 900.0
const FRICTION := 700.0
const BODY_COLOR := Color(0.45, 0.33, 0.2)
const STRAW_COLOR := Color(0.72, 0.6, 0.32)

signal hit_taken(at: Vector2, dmg: int, heavy: bool)

var hp := Tuning.DUMMY_HP
var flash_t := 0.0
var since_hit := 99.0
var squash := 0.0


func _ready() -> void:
	add_to_group("hittable")
	var shape := RectangleShape2D.new()
	shape.size = SIZE
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(0, -SIZE.y * 0.5)
	add_child(col)
	collision_layer = 4
	collision_mask = 1


func hurt_rect() -> Rect2:
	return Rect2(global_position.x - SIZE.x * 0.5, global_position.y - SIZE.y, SIZE.x, SIZE.y)


func take_hit(dmg: int, dir: int, swing: Dictionary) -> void:
	var heavy: bool = swing.get("heavy", false)
	hp = maxi(hp - dmg, 0)
	flash_t = Tuning.DUMMY_FLASH
	since_hit = 0.0
	squash = 1.0
	velocity.x = dir * float(swing.get("kb", 60.0))
	if heavy:
		velocity.y = -110.0
	hit_taken.emit(global_position + Vector2(0, -SIZE.y - 4.0), dmg, heavy)
	if hp == 0:
		hp = Tuning.DUMMY_HP


func _physics_process(delta: float) -> void:
	velocity.y = minf(velocity.y + GRAVITY * delta, 420.0)
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	move_and_slide()
	flash_t = maxf(flash_t - delta, 0.0)
	squash = maxf(squash - delta * 6.0, 0.0)
	since_hit += delta
	if since_hit >= Tuning.DUMMY_REGEN_DELAY and hp < Tuning.DUMMY_HP:
		hp = Tuning.DUMMY_HP
	queue_redraw()


func _draw() -> void:
	# 맞으면 옆으로 찌그러졌다가 돌아온다
	var w := SIZE.x * (1.0 + squash * 0.25)
	var h := SIZE.y * (1.0 - squash * 0.15)
	var body := BODY_COLOR if flash_t <= 0.0 else Color.WHITE
	var straw := STRAW_COLOR if flash_t <= 0.0 else Color.WHITE
	draw_rect(Rect2(-1.0, -h, 2.0, h), body) # 기둥
	draw_rect(Rect2(-w * 0.5, -h + 6.0, w, h * 0.45), straw) # 몸통
	draw_rect(Rect2(-w * 0.5 - 4.0, -h + 9.0, w + 8.0, 3.0), body) # 팔
	draw_rect(Rect2(-4.0, -h - 2.0, 8.0, 8.0), straw) # 머리
	# 체력 막대
	var ratio := float(hp) / float(Tuning.DUMMY_HP)
	draw_rect(Rect2(-12.0, -h - 10.0, 24.0, 3.0), Color(0.15, 0.1, 0.12))
	draw_rect(Rect2(-12.0, -h - 10.0, 24.0 * ratio, 3.0), Color(0.75, 0.2, 0.25))
