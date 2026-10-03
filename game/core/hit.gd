class_name Hit
extends RefCounted
## 공격 한 번의 정보. 공격하는 쪽이 만들어 맞는 쪽의 take_hit(hit)에 넘긴다.

var damage := 0
var knockback_t := 0.0 ## 밀려나는 거리 (T)
var launch_t := 0.0 ## 위로 띄우는 높이 (T). 0이면 띄우지 않음
var breaks_charge := false ## 돌진 중인 적의 돌진을 끊는가 (화염 폭풍)
var ignores_knock_resist := false ## 돌진 중 넉백 저항을 무시하는가
var hitstop := 0.0 ## 멈춤 연출 시간 (s)
var shake_t := 0.0 ## 화면 흔들림 진폭 (T)
var direction := 0 ## 넉백 방향 -1/1. 0이면 source_pos 기준으로 계산
var source_pos := Vector2.ZERO
var kind := &"" ## bolt, bolt_heavy, pillar, storm, burst


static func make(p_damage: int, p_kind: StringName, p_source: Vector2, p_direction := 0) -> Hit:
	var h := Hit.new()
	h.damage = p_damage
	h.kind = p_kind
	h.source_pos = p_source
	h.direction = p_direction
	return h


## 맞는 쪽 위치 기준 넉백 방향
func dir_from(target_pos: Vector2) -> int:
	if direction != 0:
		return direction
	return 1 if target_pos.x >= source_pos.x else -1
