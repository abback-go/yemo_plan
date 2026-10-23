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
var zoom := 0.0 ## 카메라 순간 확대 비율
var direction := 0 ## 넉백 방향 -1/1. 0이면 source_pos 기준으로 계산
var source_pos := Vector2.ZERO
var kind := &"" ## bolt, bolt_heavy, blast, pillar, storm, storm_final, burst

# ─── 공격 종류(kind) 묶음 ───────────────────────────────
# 적이 "방패로 못 막는다·받아치기 자세를 깬다·무거운 공격이다"를 정할 때 쓰는 목록을 한곳에 모았다.
# 적마다 조금씩 다른 것은 의도인지 확인되지 않은 차이라 예전 값을 그대로 두고 이름만 붙였다.
# 새 적은 가장 가까운 묶음을 골라 쓰고, 새 마법(kind)을 만들면 여기 묶음들에 넣을지 함께 정한다 (docs/dev/enemies.md).

## 화염탄 (정면에서 날아와 방패로 막을 수 있는 기본 탄) — 성기사 수도승의 막기
const FIRE_BOLTS: Array[StringName] = [&"bolt", &"bolt_heavy"]
## 갑옷 기사: 발밑·위에서 오거나 방패를 넘는 공격
const PASS_SHIELD_ARMOR: Array[StringName] = [&"pillar", &"fox_pillar", &"blast", &"storm_final"]
## 감시자(2장): 등불 방패를 무시하고 그대로 들어가는 공격
const PASS_SHIELD_WATCHMAN: Array[StringName] = [&"pillar", &"fox_pillar", &"blast", &"meteor", &"phoenix", &"storm_final"]
## 금빛 전령(4장): 판을 무시하는 공격
const PASS_SHIELD_GOLD_HERALD: Array[StringName] = [&"pillar", &"fox_pillar", &"blast", &"meteor", &"phoenix", &"ally"]
## 성기사 수도승(4장): 방패를 뚫는 공격
const PASS_SHIELD_MONK: Array[StringName] = [&"pillar", &"fox_pillar", &"blast", &"meteor", &"phoenix", &"ally", &"ward"]
## 엘프 수호자(3장): 방패 자세를 무시하는 공격
const PASS_SHIELD_ELF_WARDEN: Array[StringName] = [&"pillar", &"fox_pillar", &"blast", &"storm", &"storm_final", &"reflect", &"meteor", &"phoenix", &"ward", &"ally"]
## 별 기사(5장): 막을 수 없는 공격
const PASS_SHIELD_STAR_KNIGHT: Array[StringName] = [&"pillar", &"fox_pillar", &"storm", &"storm_final", &"blast", &"ward", &"reflect", &"meteor", &"phoenix", &"fox_storm", &"ally"]
## 레오니: 받아칠 수 있는 날아오는 불
const PARRYABLE_LEONIE: Array[StringName] = [&"bolt", &"bolt_heavy", &"storm", &"fox", &"foxfire", &"foxfire_heavy", &"fox_storm", &"fox_storm_final", &"reflect"]
## 레오니: 받아치기 자세를 깨는 공격 (발밑에서 솟는 불기둥, 방벽에 닿은 화상, 폭발류)
const GUARD_BREAK_LEONIE: Array[StringName] = [&"pillar", &"fox_pillar", &"ward", &"blast", &"meteor", &"phoenix", &"storm_final", &"fox_burst"]
## 별 도마뱀(2장): 열린 등껍질을 뒤집는 무거운 공격
const HEAVY_LIZARD: Array[StringName] = [&"bolt_heavy", &"pillar", &"storm_final", &"blast", &"reflect", &"meteor", &"phoenix"]
## 검투사(2장): 도발 게이지를 2칸 채우는 무거운 공격
const HEAVY_GLADIATOR: Array[StringName] = [&"bolt_heavy", &"pillar", &"storm_final", &"blast", &"reflect", &"meteor", &"phoenix", &"ward"]
## 천사 석상(4장): 돌일 때 튕겨 내는 공격
const STONE_BLOCKS_STATUE: Array[StringName] = [&"bolt", &"bolt_heavy", &"storm", &"storm_final", &"foxfire", &"foxfire_heavy", &"fox_storm", &"fox_storm_final"]
## 해태: 여우 모드의 무거운 공격 (크게 휘청)
const FOX_HEAVY: Array[StringName] = [&"foxfire_heavy", &"fox_pillar", &"fox_storm_final", &"fox_burst"]


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
