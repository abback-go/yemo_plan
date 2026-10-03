@tool
class_name Arena
extends Node2D
## 구간 4 혼합 아레나 (docs/prototype.md 7절).
## 입구 영역(EntranceTrigger)에 들어오면 양쪽 문이 잠기고 Wave1, Wave2 순서로 적이 소환된다.
## 모든 웨이브를 처치하면 문이 열린다.

signal cleared

var started := false
var done := false
var _wave := -1
var _alive := 0
var _waves: Array[Node] = []


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	for c in get_children():
		if c.name.begins_with("Wave"):
			_waves.append(c)
	var trigger := get_node_or_null("EntranceTrigger") as Area2D
	if trigger:
		trigger.collision_layer = GameConst.L_TRIGGER
		trigger.collision_mask = GameConst.L_PLAYER
		trigger.body_entered.connect(_on_enter)


func _on_enter(body: Node) -> void:
	if started or not body is Player:
		return
	started = true
	for d in _doors():
		d.close()
	_hud_banner("봉인! 모든 적을 처치하세요", 1.6)
	get_tree().create_timer(0.8, false).timeout.connect(_next_wave)


func _doors() -> Array:
	var out := []
	for c in get_children():
		if c is Door:
			out.append(c)
	return out


func _next_wave() -> void:
	_wave += 1
	if _wave >= _waves.size():
		_finish()
		return
	_hud_banner("웨이브 %d / %d" % [_wave + 1, _waves.size()], 1.2)
	_alive = 0
	for sp in _waves[_wave].get_children():
		if sp is SpawnPoint:
			_alive += 1
			sp.spawn(self, _on_spawned)


func _on_spawned(e: EnemyBase) -> void:
	e.defeated.connect(_on_enemy_defeated)


func _on_enemy_defeated(_e: EnemyBase) -> void:
	_alive -= 1
	if _alive <= 0:
		get_tree().create_timer(1.0, false).timeout.connect(_next_wave)


func _finish() -> void:
	done = true
	for d in _doors():
		d.open()
	Sfx.play(&"clear")
	_hud_banner("봉인 해제!", 1.6)
	cleared.emit()


func _hud_banner(text: String, sec: float) -> void:
	var hud := get_tree().get_first_node_in_group(&"hud")
	if hud:
		hud.banner(text, sec)
