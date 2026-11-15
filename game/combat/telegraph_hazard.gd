class_name TelegraphHazard
extends Node2D
## "예고 → 타격 → 사라짐" 시간표만 맡는 공용 바탕 (바닥 가시·기둥·화살비 표시 같은 단순한 위험 지대).
## 자식은 _draw(모양)와 _on_fire(터질 때 소리·입자·탄)만 쓴다. 시간: 0 ─ delay(예고) ─ 터짐 ─ hit_time(판정 끔) ─ life(사라짐)
## 모양이 여럿이고 따라다니기·전역 예고 색 규칙이 필요한 큰 공격은 5장 StStrike(enemies/ch5/st_strike.gd)를 쓴다.
##
##   class IceSpikes extends TelegraphHazard:
##       func _ready(): area = EnemyAttackArea.with_rect(...); area.active = false; add_child(area); hit_time = 0.3; life = 0.7
##       func _on_fire(): 소리·입자
##       func _draw(): if _t < delay: 예고 … else: 가시 …

var delay := 0.8 ## 예고 시간 (s)
var hit_time := 0.3 ## 터진 뒤 판정이 켜져 있는 시간 (s)
var life := 0.7 ## 터진 뒤 사라질 때까지 (s)
var area: EnemyAttackArea ## 있으면 터질 때 켜고 hit_time 뒤 끈다
var use_enemy_time := false ## true면 위치 타임에 함께 느려진다
var in_physics := true ## false면 _process에서 시간을 센다 (예전에 _process로 돌던 것의 타이밍 보존)
var end_inclusive := true ## 판정 끄기·사라지기 시각 비교: true면 >=, false면 > (옮겨 온 것마다 예전 비교 그대로)
var _t := 0.0 ## 만든 뒤 흐른 시간 (그림이 읽음)
var _done := false ## 터졌는가


## 자식: 터지는 순간 (판정은 이미 켜짐)
func _on_fire() -> void:
	pass


func _physics_process(delta: float) -> void:
	if in_physics:
		_step(delta)


func _process(delta: float) -> void:
	if not in_physics:
		_step(delta)


func _step(delta: float) -> void:
	_t += delta * Fx.enemy_time if use_enemy_time else delta
	if _t >= delay and not _done:
		_done = true
		if area:
			area.active = true
		_on_fire()
	if area and _past(delay + hit_time):
		area.active = false
	if _past(delay + life):
		queue_free()
	queue_redraw()


func _past(at: float) -> bool:
	return _t >= at if end_inclusive else _t > at
