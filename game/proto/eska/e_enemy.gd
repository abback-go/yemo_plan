class_name EEnemy
extends CharacterBody2D
## 에스카 시제품의 적 공통 바탕 — 허수아비와 같은 표적 약속(ETarget)을 지키고, 에스카를 맞힐 수 있다.
## 하위 종류(ERunner 돌진 · ECaster 원거리 · EColossus 거구)는 _think(생각·움직임)와 _paint_body(그림)만 채운다.
## 공통: 틈에서 나타남 · 피격 번쩍임·피해 숫자·넉백(knock_resist만큼 버팀)·경직 · 봉공에 묶이면 멈춤(+30%)
##       · 몸통 닿으면 피해(_contact_now가 참일 때) · 쓰러지면 흩어져 사라짐.
## 색: 검정·뼈흰색·핏빛 빨강 (에스카의 보라와 섞이지 않게, 파랑 없음).
## 그림 좌표: 원점 = 발밑 가운데, 오른쪽을 보는 모습으로 그린다(facing이 -1이면 뒤집힘).

signal died(e: EEnemy)

const GRAVITY := 980.0
const FALL_MAX := 520.0
const SPAWN_TIME := 0.55
const DEATH_TIME := 0.6

const BLACK := Color("#0c090f")
const SHADE := Color("#251b29")
const BONE := Color("#ece4d6")
const BONE_DIM := Color("#a3978a")
const RED := Color("#ff2b3d")
const RED_DEEP := Color("#7d0c1f")
const RED_HOT := Color("#ffb0a6")

var max_hp := 300
var hp := 300
var size := Vector2(20, 28) ## 피격 사각형 (원점 = 발밑 가운데)
var knock_resist := 0.0 ## 0 = 잘 밀림 · 1 = 넉백·경직 없음
var contact_dmg := 1
var lockable := true ## 봉공·종언참이 겨눌 수 있나
var flying := false
var facing := -1
var x_min := 24.0 ## 움직일 수 있는 가로 범위 (장면이 정함)
var x_max := 1256.0
var eska: EEska

var pd := PDraw.new()
var t := 0.0 ## 나타난 뒤 시간 (그림 흔들림 등)
var flash := 0.0
var stagger := 0.0
var spawn_t := SPAWN_TIME ## 나타나는 중 남은 시간 (이동·공격 안 함)
var dead_t := -1.0 ## 쓰러진 뒤 시간 (-1 = 살아 있음)
var _bound := 0.0
var _bind_awake := false
var _bar := 0.0
var _hp_trail := 0.0
var _base := Transform2D.IDENTITY


func _ready() -> void:
	add_to_group(PDummy.GROUP)
	collision_layer = 4
	collision_mask = 1
	floor_snap_length = 4.0
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = size
	cs.shape = rs
	cs.position = Vector2(0, -size.y / 2)
	add_child(cs)
	hp = max_hp
	_hp_trail = max_hp
	t = randf() * 2.0
	z_index = 2
	eska = EEska.find(get_tree())
	EFoeFx.rift(center(), size.y * 0.75)
	Sfx.play_pitch(&"spawn", randf_range(0.8, 1.0), -10.0)


# ═══════════════════════════════════════════════════════════
# 표적 약속 (ETarget)
# ═══════════════════════════════════════════════════════════

func hit_rect() -> Rect2:
	return Rect2(global_position + Vector2(-size.x * 0.5, -size.y), size)


func center() -> Vector2:
	return global_position + Vector2(0, -size.y * 0.5)


func is_dead() -> bool:
	return dead_t >= 0.0


func take_hit(dmg: int, from: Vector2, opts := {}) -> void:
	if is_dead():
		return
	var d := dmg
	if _bound > 0.0 and _bind_awake:
		d = int(round(float(d) * 1.3))
	hp -= d
	flash = 1.0
	_bar = 2.5
	var heavy := bool(opts.get("heavy", false))
	var dir := signf(global_position.x - from.x)
	if dir == 0.0:
		dir = -float(facing)
	var give := 0.0 if _armored() else 1.0 - knock_resist
	if _bound <= 0.0 and give > 0.3:
		stagger = maxf(stagger, (0.26 if heavy else 0.17) * give)
		velocity.x = dir * (150.0 if heavy else 85.0) * give
		if flying:
			velocity.y = (center().y - from.y) * 0.6 * give
		elif heavy:
			velocity.y = -130.0 * give
		_interrupted()
	elif _bound <= 0.0 and not flying:
		velocity.x += dir * 40.0 * give # 거구: 밀리지 않고 살짝만 흔들림
	if PState.damage_numbers:
		PVfx.number(self, center() + Vector2(0, -size.y * 0.45), d, heavy)
	if hp <= 0:
		_die(dir)


func bind(sec: float, awake: bool, _fox := true, _style := "") -> void:
	_bound = sec
	_bind_awake = awake
	_interrupted()


func unbind() -> void:
	_bound = 0.0


func is_bound() -> bool:
	return _bound > 0.0


# ═══════════════════════════════════════════════════════════
# 하위 종류가 채우는 것
# ═══════════════════════════════════════════════════════════

## 한 프레임 생각·움직임 (나타남·경직·묶임이 아닐 때만 불림)
func _think(_delta: float) -> void:
	pass


## 맞아서 경직되거나 묶였을 때 — 준비하던 공격을 끊는다
func _interrupted() -> void:
	pass


## 지금 넉백·경직을 무시하나 (돌진 중 등)
func _armored() -> bool:
	return false


## 지금 몸통이 닿으면 아픈가
func _contact_now() -> bool:
	return false


## 몸 그림 (오른쪽을 보는 모습, a = 나타남·쓰러짐 투명도)
func _paint_body(_a: float) -> void:
	pass


# ═══════════════════════════════════════════════════════════
# 한 프레임
# ═══════════════════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	t += delta
	flash = maxf(flash - delta * 6.0, 0.0)
	_bar = maxf(_bar - delta, 0.0)
	_hp_trail = maxf(float(hp), _hp_trail - float(max_hp) * delta * 0.8) if _bar < 2.2 else _hp_trail
	if is_dead():
		dead_t += delta
		if dead_t >= DEATH_TIME:
			queue_free()
		queue_redraw()
		return
	if not is_instance_valid(eska):
		eska = EEska.find(get_tree())
	_bound = maxf(_bound - delta, 0.0)
	if spawn_t > 0.0:
		spawn_t -= delta
		velocity.x = 0.0
	elif _bound > 0.0:
		velocity = Vector2.ZERO
	elif stagger > 0.0:
		stagger -= delta
		velocity.x = move_toward(velocity.x, 0.0, 520.0 * delta)
		if flying:
			velocity.y = move_toward(velocity.y, 0.0, 520.0 * delta)
	else:
		_think(delta)
	if not flying and _bound <= 0.0:
		velocity.y = minf(velocity.y + GRAVITY * delta, FALL_MAX)
	move_and_slide()
	global_position.x = clampf(global_position.x, x_min, x_max)
	if spawn_t <= 0.0 and _bound <= 0.0 and stagger <= 0.0 and contact_dmg > 0 and _contact_now() and eska_ok():
		if eska.hurt_rect().intersects(hit_rect()):
			eska.hurt(contact_dmg, center())
	queue_redraw()


## 에스카가 살아서 겨눌 수 있나
func eska_ok() -> bool:
	return is_instance_valid(eska) and not eska.is_dead()


## 에스카 쪽 방향 (-1/1)
func toward_eska() -> int:
	if not is_instance_valid(eska):
		return facing
	return 1 if eska.global_position.x >= global_position.x else -1


func _die(dir: float) -> void:
	dead_t = 0.0
	hp = 0
	remove_from_group(PDummy.GROUP)
	collision_layer = 0
	velocity = Vector2(dir * 60.0, -40.0 if not flying else 0.0)
	EFoeFx.death(center(), size, dir)
	Sfx.play_pitch(&"enemy_die", randf_range(0.9, 1.1), -4.0)
	Fx.shake(0.35 + size.y * 0.004, 0.18)
	died.emit(self)


# ═══════════════════════════════════════════════════════════
# 그림
# ═══════════════════════════════════════════════════════════

func _draw() -> void:
	var a := 1.0
	var sc := Vector2.ONE
	if spawn_t > 0.0:
		var f := 1.0 - spawn_t / SPAWN_TIME
		a = smoothstep(0.15, 0.9, f)
		sc = Vector2(0.4 + 0.6 * f, 1.25 - 0.25 * f)
	elif is_dead():
		var f := dead_t / DEATH_TIME
		a = 1.0 - f
		sc = Vector2(1.0 + 0.35 * f, 1.0 - 0.4 * f)
	if _bound <= 0.0 and stagger > 0.0:
		sc *= Vector2(1.08, 0.94)
	_base = Transform2D(0.0, Vector2(float(facing) * sc.x, sc.y), 0.0, Vector2.ZERO)
	# 바닥 그림자
	if not flying:
		pd.draw_set_transform(Vector2(0, 1), 0.0, Vector2(1.0, 0.22))
		pd.glow(Vector2.ZERO, size.x * 0.9, Color(0, 0, 0, 0.5 * a), 0.0)
	xf()
	_paint_body(a)
	pd.draw_set_transform(Vector2.ZERO)
	if _bar > 0.0 and not is_dead():
		_paint_bar(minf(_bar / 0.4, 1.0))
	pd.flush(self)


## 그림 좌표 정하기: 몸 기준(뒤집힘·눌림 포함) 위에 pos·rot·sc를 얹는다
func xf(pos := Vector2.ZERO, rot := 0.0, sc := Vector2.ONE) -> void:
	pd.draw_set_transform_matrix(_base * Transform2D(rot, sc, 0.0, pos))


## 색 하나: 맞으면 흰빛, 묶이면 검붉게 굳음, a = 투명도
func col(c: Color, a := 1.0) -> Color:
	var out := c
	if _bound > 0.0:
		out = out.lerp(Color("#3a1030"), 0.35)
	out = out.lerp(Color.WHITE, flash * 0.85)
	out.a *= a
	return out


## 머리 위 작은 체력바 (맞은 뒤 잠깐)
func _paint_bar(a: float) -> void:
	var w := clampf(size.x * 1.4, 24.0, 64.0)
	var p := Vector2(-w * 0.5, -size.y - 10.0)
	var f := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	var ft := clampf(_hp_trail / float(max_hp), 0.0, 1.0)
	pd.draw_rect(Rect2(p - Vector2(1, 1), Vector2(w + 2, 4)), Color(0, 0, 0, 0.75 * a))
	pd.draw_rect(Rect2(p, Vector2(w * ft, 2)), Color(RED_HOT, 0.8 * a))
	pd.draw_rect(Rect2(p, Vector2(w * f, 2)), Color(RED, a))
