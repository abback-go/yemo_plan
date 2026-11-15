class_name PtHero
extends CharacterBody2D
## 틀 시안의 조작 캐릭터 (검사 임시 그림). 원점 = 발밑, 충돌 = 발밑 원(반지름 5)이라 몸 윗부분은 기둥·나무 앞뒤로 겹쳐 보인다(y 정렬).
## 8방향 걷기: 방향키·패드 왼쪽 스틱(move_* 동작) + WASD(물리 키) + 터치 조이스틱(touch_vec, 폰 시험용). 대각선도 같은 속도.
## 그림 방향은 4개(아래·위·옆, 왼쪽은 옆을 뒤집음) — 가로 입력이 세로보다 크면 옆, 아니면 위·아래.

const SPEED := 90.0 ## px/초 (칸 16px → 초당 약 5.6칸)
const ACCEL := 1000.0
const FRICTION := 1400.0
const WALK_FPS := 9.0 ## 걷기 4장 한 바퀴 ≈ 0.44초

var touch_vec := Vector2.ZERO ## 터치 조이스틱 (PtField가 넣음)
var face := 0 ## 시트 줄: 0 아래 · 1 위 · 2 옆
var face_left := false
var _t := 0.0
var _walk := 0.0
var sprite: Sprite2D


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var sh := Sprite2D.new()
	sh.texture = PtArt.blob()
	sh.position = Vector2(0, 0)
	add_child(sh)
	sprite = Sprite2D.new()
	sprite.texture = PtArt.hero_sheet()
	sprite.hframes = 6
	sprite.vframes = 3
	sprite.centered = false
	sprite.offset = -PtArt.HERO_FEET
	add_child(sprite)
	var col := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = 5.0
	col.shape = cs
	add_child(col)


func input_dir() -> Vector2:
	var d := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	d += Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	d += touch_vec
	return d.normalized() if d.length() > 1.0 else d


func _physics_process(delta: float) -> void:
	var d := input_dir()
	velocity = velocity.move_toward(d * SPEED, (ACCEL if d != Vector2.ZERO else FRICTION) * delta)
	move_and_slide()
	if d.length() > 0.2:
		if absf(d.x) > absf(d.y) + 0.05:
			face = 2
			face_left = d.x < 0.0
		else:
			face = 1 if d.y < 0.0 else 0


func _process(delta: float) -> void:
	_t += delta
	var sp := velocity.length()
	var col := 0
	if sp > 12.0:
		_walk += delta * WALK_FPS * clampf(sp / SPEED, 0.6, 1.2)
		col = 2 + int(_walk) % 4
	else:
		_walk = 0.0
		col = int(_t * 1.6) % 2 # 숨쉬기
	sprite.frame = face * 6 + col
	sprite.flip_h = face == 2 and face_left
	sprite.position = global_position.round() - global_position # 화면 픽셀에 맞춤 (반 픽셀 떨림 없게)
