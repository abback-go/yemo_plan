@tool
class_name SpawnPoint
extends Marker2D
## 적이 소환진과 함께 나타나는 자리. SpawnTrigger나 Arena의 웨이브가 사용한다.

enum Kind { CHARGER, SNIPER }

const SCENES := {
	Kind.CHARGER: preload("res://enemies/charger.tscn"),
	Kind.SNIPER: preload("res://enemies/sniper.tscn"),
}

@export var kind: Kind = Kind.CHARGER
@export var delay := 0.0 ## 소환 시작까지 기다리는 시간 (s)
@export var face_left := true


## parent 아래에 소환진을 띄우고 0.5초 뒤 적을 만든다. 만들어진 적을 callback으로 알려 준다.
func spawn(parent: Node, callback: Callable) -> void:
	# 소환진은 실제로 띄울 때 만든다 (기다리는 사이 씬이 바뀌어도 고아 노드가 남지 않음)
	var start := func() -> void:
		if not is_instance_valid(parent):
			return
		var portal := SpawnPortal.new()
		portal.global_position = global_position
		portal.on_done = func() -> void:
			var e: EnemyBase = SCENES[kind].instantiate()
			e.position = parent.to_local(global_position) if parent is Node2D else global_position
			e.facing = -1 if face_left else 1
			parent.add_child(e)
			callback.call(e)
		Fx.effect_parent().add_child(portal)
	if delay > 0.0:
		# 자식 Timer라 씬이 바뀌면 함께 사라져, 사라진 parent로 소환하지 않는다
		var timer := Timer.new()
		timer.one_shot = true
		timer.wait_time = delay
		timer.timeout.connect(start)
		timer.timeout.connect(timer.queue_free)
		add_child(timer)
		timer.start()
	else:
		start.call()


func _draw() -> void:
	if Engine.is_editor_hint():
		var c := Palette.ENEMY_EYE if kind == Kind.CHARGER else Palette.SHOT
		draw_circle(Vector2(0, -8), 6.0, Color(c, 0.4))
		draw_arc(Vector2(0, -8), 7.0, 0.0, TAU, 16, c, 1.0)
