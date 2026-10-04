class_name Sniper
extends EnemyBase
## 저격형 (docs/prototype.md 6.2절): 높은 곳에 고정. 12T 안에서 시야가 트이면 조준 시작.
## 0.8초 동안 세라를 따라가는 조준선 → 마지막 0.2초는 고정(피할 틈) → 직선 탄 1발 → 2.5초 재장전.

enum S { IDLE, AIM, LOCK, RELOAD }

var state: S = S.IDLE
var aim_dir := Vector2.LEFT
var aim_end := Vector2.ZERO ## 조준선이 닿는 곳 (전역 좌표)
var _timer := 0.0


func _build() -> void:
	max_hp = tuning.sniper_hp
	body_size = Vector2(14, 26)
	cull_offscreen = false # 화면 밖 생략 안 함: 조준선이 화면을 가로지름
	_visual = SniperVisual.new()
	_visual.enemy = self
	add_child(_visual)


func eye() -> Vector2:
	return global_position + Vector2(facing * 3, -21)


func _ai(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	var p := player()
	match state:
		S.IDLE:
			if p and p.is_alive() and _in_range(p):
				_face(p)
				if _has_los(p):
					state = S.AIM
					_timer = tuning.sniper_aim_time
					Sfx.play(&"sniper_aim", -4.0)
		S.AIM:
			if p == null or not p.is_alive() or not _in_range(p) or not _has_los(p):
				state = S.IDLE
				return
			_face(p)
			aim_dir = (p.center() - eye()).normalized()
			_timer -= delta
			if _timer <= tuning.sniper_lock_time:
				state = S.LOCK
				Sfx.play(&"sniper_lock", -2.0, 0.0)
		S.LOCK:
			_timer -= delta
			if _timer <= 0.0:
				_fire()
		S.RELOAD:
			_timer -= delta
			if _timer <= 0.0:
				state = S.IDLE
	if state == S.AIM or state == S.LOCK:
		aim_end = _ray_end(eye(), aim_dir)


func _in_range(p: Player) -> bool:
	return eye().distance_to(p.center()) <= tuning.sniper_range_t * GameConst.TILE


func _has_los(p: Player) -> bool:
	return has_los(eye(), p.center())


func _ray_end(from: Vector2, dir: Vector2) -> Vector2:
	var space := get_world_2d().direct_space_state
	var to := from + dir * 30.0 * GameConst.TILE
	var r := space.intersect_ray(PhysicsRayQueryParameters2D.create(from, to, GameConst.L_WORLD))
	return r.position if r else to


func _face(p: Player) -> void:
	facing = 1 if p.global_position.x >= global_position.x else -1


func _fire() -> void:
	var shot := SniperShot.new()
	shot.setup(eye() + aim_dir * 6.0, aim_dir, tuning.sniper_shot_speed_t * GameConst.TILE)
	Fx.effect_parent().add_child(shot)
	Sfx.play(&"sniper_shot", -2.0)
	Fx.burst(eye() + aim_dir * 6.0, 6, {
		direction = aim_dir, spread = 30.0, speed_min = 30.0, speed_max = 90.0, lifetime = 0.2,
		gradient = Palette.fade_gradient(Palette.SHOT), size_min = 1.0, size_max = 2.0, gravity = Vector2.ZERO,
	})
	state = S.RELOAD
	_timer = tuning.sniper_reload


func _on_hit(hit: Hit, _dir: int) -> void:
	if hit.launch_t > 0.0 and (state == S.AIM or state == S.LOCK):
		state = S.RELOAD # 띄워지면 조준이 끊긴다
		_timer = 0.8
