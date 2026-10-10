class_name EWaves
extends Node
## 훈련장의 끝없는 적 물결: 쉬는 시간 → "WAVE n" 알림 → 적들이 붉은 틈에서 나타남 → 모두 쓰러뜨리면 다음.
## 목록을 다 돌면 처음부터 다시, 한 바퀴마다 적 체력 +25%.
## 적 만들기(make·spawn)는 튜토리얼도 같이 쓴다.

const FIRST_WAIT := 3.0
const REST := 2.6
const SPAWN_GAP := 0.3
const WAVES := [
	["runner"],
	["runner", "runner"],
	["caster"],
	["runner", "caster"],
	["colossus"],
	["runner", "runner", "caster"],
	["colossus", "caster"],
	["runner", "caster", "caster", "runner"],
	["colossus", "runner", "runner"],
]

var enabled := true
var stage: EStage
var wave := 0
var _alive: Array[EEnemy] = []
var _wait := FIRST_WAIT
var _queue: Array = [] ## [남은 시간, 종류, 체력 배율]


static func make(kind: String) -> EEnemy:
	match kind:
		"caster":
			return ECaster.new()
		"colossus":
			return EColossus.new()
	return ERunner.new()


## 적 하나를 parent 아래 pos에 놓는다 (hp_mult = 체력 배율, 가로 범위는 장면 폭)
static func spawn(parent: Node, kind: String, pos: Vector2, hp_mult := 1.0, x_min := 24.0, x_max := 1256.0) -> EEnemy:
	var e := make(kind)
	e.max_hp = int(round(float(e.max_hp) * hp_mult))
	e.x_min = x_min
	e.x_max = x_max
	e.position = pos
	parent.add_child(e)
	return e


func _process(delta: float) -> void:
	if not enabled:
		return
	for i in range(_queue.size() - 1, -1, -1):
		_queue[i][0] -= delta
		if float(_queue[i][0]) <= 0.0:
			var q: Array = _queue.pop_at(i)
			_spawn_one(String(q[1]), float(q[2]))
	_alive = _alive.filter(func(e: EEnemy) -> bool: return is_instance_valid(e) and not e.is_dead())
	if _alive.is_empty() and _queue.is_empty():
		if wave > 0 and _wait >= REST:
			stage.hud.banner("CLEAR", "다음 물결까지 잠시", 1.3)
			Sfx.play(&"clear", -6.0)
		_wait -= delta
		if _wait <= 0.0:
			_next()


func _next() -> void:
	wave += 1
	var spec: Array = WAVES[(wave - 1) % WAVES.size()]
	var loop := (wave - 1) / WAVES.size()
	var mult := 1.0 + 0.25 * float(loop)
	stage.hud.banner("WAVE %d" % wave, "적 %d" % spec.size(), 1.6)
	for i in spec.size():
		_queue.append([0.5 + float(i) * SPAWN_GAP, spec[i], mult])
	_wait = REST


## 에스카에서 떨어진 곳에 하나 (양쪽을 번갈아)
func _spawn_one(kind: String, mult: float) -> void:
	var ex := stage.eska.global_position.x if is_instance_valid(stage.eska) else stage.stage_w * 0.5
	var side := 1.0 if (_alive.size() + wave) % 2 == 0 else -1.0
	var x := ex + side * randf_range(220.0, 300.0)
	if x < 60.0 or x > stage.stage_w - 60.0:
		x = ex - side * randf_range(220.0, 300.0)
	x = clampf(x, 60.0, stage.stage_w - 60.0)
	var y := stage.floor_y
	if kind == "caster":
		y -= 110.0
	var e := spawn(stage, kind, Vector2(x, y), mult, 24.0, stage.stage_w - 24.0)
	_alive.append(e)
