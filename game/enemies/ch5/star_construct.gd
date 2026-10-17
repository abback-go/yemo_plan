class_name StarConstruct
extends EnemyBase
## 별빛 구조체 공통 (별 기사·별 궁수·별 창기사). 리라가 각 지역 강자의 싸우는 모습을 별빛으로 빚어낸 시련의 상대.
## 남색 유리 같은 몸 + 금빛 테두리, 관절마다 별, 몸을 가로지르는 별자리 선, 얼굴 자리엔 별 하나.
## 쓰러지면 부서지지 않고 별가루로 흩어져 하늘로 올라간다 (리라에게 돌아감).
## grand = true: 시련의 마지막 상대(큰 구조체) — 몸 1.3배, 체력 2배 남짓, 그 강자의 대표 기술 하나가 더 붙는다.

var grand := false
var state := "idle"
var afterimages: Array = [] ## [{pos, t, pose}] 잔상 (그림이 읽음)
var _timer := 0.0
var _state_len := 1.0
var _cd := 1.0 ## 다음 공격까지
var _contact: EnemyAttackArea
var _blink_cd := 0.0


func _setup_construct(hp: int, size: Vector2, name_text: String, sub: String, kind: String, visual_kind: String) -> void:
	max_hp = int(hp * (2.0 if grand else 1.0))
	body_size = size * (1.25 if grand else 1.0)
	display_name = ("큰 " if grand else "") + name_text
	subtitle = sub
	kind_id = kind + ("_grand" if grand else "")
	is_elite = true
	knock_mult = 0.4 if grand else 0.7
	launch_mult = 0.3 if grand else 0.6
	var v := StarConstructVisual.new()
	v.enemy = self
	v.kind = visual_kind
	v.scale_k = 1.3 if grand else 1.0
	_visual = v
	add_child(v)
	_contact = add_attack_area(body_size * Vector2(0.8, 0.9), Vector2(0, -body_size.y * 0.45), StringName(kind), 1)
	_contact.dodgeable = false


func set_state(s: String, time := 0.0) -> void:
	state = s
	_timer = time
	_state_len = maxf(time, 0.001)


func progress() -> float:
	return clampf(1.0 - _timer / _state_len, 0.0, 1.0)


func _tick(delta: float) -> void:
	_timer -= delta
	_blink_cd -= delta
	for a in afterimages:
		a.t += delta
	for i in range(afterimages.size() - 1, -1, -1):
		if float(afterimages[i].t) > 0.45:
			afterimages.remove_at(i)


func add_afterimage(pose: String) -> void:
	afterimages.append({"pos": global_position, "t": 0.0, "pose": pose, "facing": facing})


## 별빛으로 흩어졌다가 다른 자리에서 모임 (궁수·창기사)
func star_blink(to: Vector2) -> void:
	Fx.burst(global_position + Vector2(0, -body_size.y * 0.5), 18, {spread = 180.0, speed_min = 20.0, speed_max = 80.0, lifetime = 0.5,
		gradient = Palette.fade_gradient(StArt.STAR), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, -40), add = true})
	global_position = to
	velocity = Vector2.ZERO
	Fx.burst(global_position + Vector2(0, -body_size.y * 0.5), 18, {spread = 180.0, speed_min = 60.0, speed_max = 20.0, lifetime = 0.4,
		gradient = Palette.fade_gradient(StArt.STAR), size_min = 1.0, size_max = 2.0, add = true})
	StArt.sfx(&"star_twinkle", &"reveal", -4.0)


## 바닥 높이 (발 아래로 광선, 20칸까지). 없으면 지금 발 높이. 벽 x는 EnemyBase.wall_x
func ground_y(x: float, from_y := INF) -> float:
	var y0 := global_position.y - 8.0 if from_y == INF else from_y
	return floor_y_at(x, y0, y0 + 20.0 * GameConst.TILE, global_position.y)


## 별가루로 흩어지며 사라짐
func _die(dir: int) -> void:
	var c := global_position + Vector2(0, -body_size.y * 0.5)
	Fx.burst(c, 46, {spread = 180.0, speed_min = 30.0, speed_max = 170.0, damping = 50.0, lifetime = 1.1,
		gradient = Palette.fade_gradient(StArt.STAR), size_min = 1.0, size_max = 3.0, gravity = Vector2(0, -90), add = true})
	Fx.ring(c, 4.0, 40.0 * (1.3 if grand else 1.0), StArt.STAR, 0.4, 2.0)
	StArt.sfx(&"star_burst", &"reveal", -2.0)
	super._die(dir)
