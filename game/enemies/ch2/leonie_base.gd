extends EnemyBase
## 레오니 적(대련·결투) 공용: 전용 그림(CharacterVisual "leonie")과 자세, 잔상, 베기 판정, 받아치기 불꽃.
## 자식: leonie_spar.gd(목검 대련), leonie_duel.gd(진검 결투 보스).

const KE := preload("res://enemies/ch2/k_enemy.gd")
const KArt := preload("res://world/entities/ch2/k_art.gd")
const STEEL_FX := Color(0.92, 0.95, 1.0)
const AFTER_COL := Color(0.55, 0.7, 1.0, 0.55)
## 정면에서 오면 베어 내는 공격 (불덩이·여우불·화염 폭풍)
const PARRYABLE := Hit.PARRYABLE_LEONIE
## 받아치기 자세를 깨는 공격 (발밑에서 솟는 불기둥, 방벽에 닿은 화상, 폭발류)
const GUARD_BREAK := Hit.GUARD_BREAK_LEONIE

var vis: CharacterVisual
var _flip: Node2D
var _area_timers := {} ## EnemyAttackArea → 남은 시간
var _after_t := 0.0
var _after_every := 0.0 ## 0보다 크면 이 간격으로 잔상


func _setup_visual(wood: bool) -> void:
	_flip = Node2D.new()
	add_child(_flip)
	vis = CharacterVisual.new()
	vis.setup("leonie")
	if wood:
		var inf: Dictionary = vis.info.duplicate()
		inf["sword"] = "wood"
		vis.info = inf
	vis.set_pose("idle")
	_flip.add_child(vis)
	_visual = _flip


func pose(p: String) -> void:
	vis.set_pose(p)


## 검날의 붉은 예고 (0~1)
func warn(k: float) -> void:
	vis.set_meta("warn", clampf(k, 0.0, 1.0))


func _physics_process(delta: float) -> void:
	super(delta)
	if _flip:
		_flip.scale.x = float(facing)
	if vis:
		vis.modulate = Color(2.2, 2.2, 2.2) if flash_amount() > 0.0 and _alive else Color.WHITE
	for a in _area_timers.keys():
		var left: float = _area_timers[a] - delta
		if left <= 0.0:
			(a as EnemyAttackArea).active = false
			_area_timers.erase(a)
		else:
			_area_timers[a] = left
	if _after_every > 0.0:
		_after_t -= delta
		if _after_t <= 0.0:
			_after_t = _after_every
			afterimage()


## 잔상: 지금 자세를 푸른빛으로 남기고 사라짐
func afterimage(alpha := 0.55) -> void:
	var ghost := CharacterVisual.new()
	ghost.setup("leonie")
	ghost.info = vis.info
	ghost.set_pose(vis.pose)
	ghost.pose_t = vis.pose_t
	ghost.position = global_position # 효과 층은 원점에 있다
	ghost.scale.x = float(facing)
	ghost.modulate = Color(AFTER_COL, alpha)
	ghost.z_index = 3
	ghost.material = Fx.add_material
	Fx.effect_parent().add_child(ghost)
	var tw := ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.28)
	tw.tween_callback(ghost.queue_free)


## 판정 영역을 dur초 동안 켬
func strike(a: EnemyAttackArea, off: Vector2, dur: float, dmg := 1) -> void:
	place_area(a, off)
	a.damage = dmg
	a.active = true
	a.dodgeable = true
	_area_timers[a] = dur


## 앞쪽 벽까지 거리 (px, 없으면 limit)
func _room_ahead(dir: int, limit: float) -> float:
	var space := get_world_2d().direct_space_state
	var from := global_position + Vector2(0, -16)
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(dir * limit, 0), GameConst.L_WORLD)
	var r := space.intersect_ray(q)
	if r.is_empty():
		return limit
	var p: Vector2 = r.position
	return absf(p.x - from.x) - 12.0


## 받아치기: 날아온 불을 베어 냄 (불꽃이 두 갈래로 갈라져 흩어짐)
func parry_fx(hit: Hit) -> void:
	var at := global_position + Vector2(facing * 12.0, clampf(hit.source_pos.y - global_position.y, -34.0, -10.0))
	KE.snd(&"parry", &"block", 0.0, 0.05)
	KE.snd(&"sword_clash", &"swing", -4.0)
	Fx.hitstop(0.04)
	Fx.burst(at, 12, {spread = 50.0, direction = Vector2(-facing, -0.6), speed_min = 80.0, speed_max = 180.0, lifetime = 0.3,
		gradient = Palette.fire_gradient(), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 300)})
	Fx.burst(at, 12, {spread = 50.0, direction = Vector2(-facing, 0.6), speed_min = 80.0, speed_max = 180.0, lifetime = 0.3,
		gradient = Palette.fire_gradient(), size_min = 1.0, size_max = 2.0, gravity = Vector2(0, 300)})
	Fx.ring(at, 2.0, 18.0, STEEL_FX, 0.18, 1.0)
	var flash := ParryFlash.new()
	flash.position = at
	flash.dir = facing
	Fx.effect_parent().add_child(flash)


## 받아치기 섬광: 짧은 흰 사선 하나
class ParryFlash extends Node2D:
	var dir := 1
	var _t := 0.0

	func _ready() -> void:
		material = Fx.add_material
		z_index = 6

	func _process(delta: float) -> void:
		_t += delta
		if _t > 0.16:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var k := 1.0 - _t / 0.16
		draw_line(Vector2(-dir * 10, 10), Vector2(dir * 10, -10), Color(1, 1, 1, k), 2.0)
		draw_line(Vector2(-dir * 14, 14), Vector2(dir * 14, -14), Color(0.8, 0.9, 1.0, 0.5 * k), 1.0)
