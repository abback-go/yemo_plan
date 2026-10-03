class_name Snapvine
extends EnemyBase
## 독덩굴 (docs/chapter1.md 7절 — 선택 구역 온실의 정예): 깨진 화분을 뚫고 자란 덩굴. 움직이지 않는다.
## 긴 줄기 끝의 꽃머리 3개가 번갈아 움직인다.
## - 물기: 머리가 뒤로 젖혀지며 붉게 빛남(0.6초 예고, 마지막 0.2초는 목표 고정) → 최대 6T 뻗어 덥석 → 천천히 돌아옴.
## - 씨앗 뱉기: 머리가 볼을 부풀리며 붉게 빛남(0.5초) → 포물선 씨앗 3발이 세라 주변에 떨어짐.
## - 공략 포인트: 몸통(뿌리)은 껍질이 두꺼워 피해 60%. 머리가 뻗는 순간부터 1초 동안은 줄기 속살이 드러나 피해 2배.

enum H { REST, WIND, LUNGE, HOLD, RETRACT, SPIT_WIND, SPIT }

const T := GameConst.TILE
const REACH_T := 6.0
const WIND_TIME := 0.6
const WIND_LOCK := 0.2 ## 예고 마지막 이 시간은 목표 고정 (피할 틈)
const LUNGE_TIME := 0.12
const HOLD_TIME := 0.3
const RETRACT_TIME := 0.45
const SPIT_WIND_TIME := 0.5
const SPIT_TIME := 0.35
const SEED_FLIGHT := 0.85
const SEED_GRAVITY := 520.0
const EXPOSE_TIME := 1.0
const BARK_MULT := 0.6
const EXPOSED_MULT := 2.0
const ACTION_GAP := 1.0
const ACTION_GAP_HURT := 0.75 ## 체력 절반 아래에서 더 바빠짐


## 꽃머리 하나 (좌표는 발밑 원점 기준, 좌우 반전 없음)
class VineHead:
	extends RefCounted
	var state := 0
	var timer := 0.0
	var state_len := 1.0
	var root := Vector2.ZERO ## 줄기 뿌리
	var rest := Vector2.ZERO ## 쉬는 자리
	var pos := Vector2.ZERO ## 지금 위치
	var from := Vector2.ZERO
	var target := Vector2.ZERO
	var look := 0.0 ## 머리가 바라보는 각도
	var area: EnemyAttackArea
	var bob := 0.0

	func progress() -> float:
		return clampf(1.0 - timer / maxf(state_len, 0.001), 0.0, 1.0)


var heads: Array[VineHead] = []
## 기록용: 머리 셋의 상태 이름 (예: "WIND/REST/HOLD x2")
var state: String:
	get:
		var names := PackedStringArray()
		for h in heads:
			names.append(H.keys()[h.state])
		return "/".join(names) + (" x2" if _exposed > 0.0 else "")
var _next := 1.2
var _turn := 0
var _exposed := 0.0


func _build() -> void:
	max_hp = 420
	body_size = Vector2(30, 34)
	display_name = "독덩굴"
	subtitle = "온실 관리 소홀의 결과"
	kind_id = "snapvine"
	knock_mult = 0.0
	launch_mult = 0.0
	_visual = SnapvineVisual.new()
	_visual.enemy = self
	add_child(_visual)
	var roots := [Vector2(7, -30), Vector2(0, -34), Vector2(-7, -30)]
	var rests := [Vector2(26, -40), Vector2(3, -72), Vector2(-24, -48)]
	for i in 3:
		var h := VineHead.new()
		h.root = roots[i]
		h.rest = rests[i]
		h.pos = h.rest
		h.bob = i * 2.1
		h.look = -0.3 if i == 0 else (-PI * 0.5 if i == 1 else PI + 0.3)
		h.area = add_attack_area(Vector2(16, 14), Vector2.ZERO, &"snapvine", 1)
		h.area.active = false
		heads.append(h)


func is_exposed() -> bool:
	return _exposed > 0.0


func head_global(h: VineHead) -> Vector2:
	return global_position + h.pos


func _ai(delta: float) -> void:
	velocity.x = 0.0
	_exposed = maxf(_exposed - delta, 0.0)
	var p := player()
	for h in heads:
		_update_head(h, delta, p)
	_next -= delta
	if _next <= 0.0:
		_next = 0.2
		if p and p.is_alive() and global_position.distance_to(p.global_position) < 16.0 * T:
			for i in 3:
				var h := heads[(_turn + i) % 3]
				if h.state == H.REST:
					_turn = (_turn + i + 1) % 3
					_start_action(h, p)
					_next = ACTION_GAP_HURT if hp * 2 < max_hp else ACTION_GAP
					break


func _start_action(h: VineHead, p: Player) -> void:
	var reach := REACH_T * T
	var d := (p.center() - (global_position + h.root)).length()
	if d <= reach + 0.5 * T and randf() < 0.75:
		_set_head(h, H.WIND, WIND_TIME)
		h.target = _aim(h, p)
		Sfx.play(&"growl", -7.0, 0.15)
	else:
		_set_head(h, H.SPIT_WIND, SPIT_WIND_TIME)
		Sfx.play(&"squish", -6.0, 0.1)


func _set_head(h: VineHead, s: H, time: float) -> void:
	h.state = s
	h.timer = time
	h.state_len = time
	h.from = h.pos


## 세라 쪽 목표 (뿌리에서 최대 6T, 바닥 아래로는 안 감)
func _aim(h: VineHead, p: Player) -> Vector2:
	var want := p.center() - global_position
	var d := (want - h.root).limit_length(REACH_T * T)
	var tgt := h.root + d
	tgt.y = minf(tgt.y, -8.0)
	return tgt


func _update_head(h: VineHead, delta: float, p: Player) -> void:
	h.timer -= delta
	var k := h.progress()
	var idle := h.rest + Vector2(sin(_t * 1.7 + h.bob) * 2.0, sin(_t * 2.3 + h.bob) * 2.5)
	match h.state:
		H.REST:
			h.pos = h.pos.lerp(idle, minf(1.0, delta * 6.0))
			if p:
				h.look = lerp_angle(h.look, (p.center() - global_position - h.pos).angle(), minf(1.0, delta * 3.0))
		H.WIND:
			if p and h.timer > WIND_LOCK:
				h.target = _aim(h, p)
			var dir := (h.target - h.rest).normalized()
			h.pos = h.from.lerp(h.rest - dir * 12.0, minf(1.0, k * 2.0)) + Vector2(sin(_t * 50.0), 0) * k
			h.look = (h.target - h.pos).angle()
			if h.timer <= 0.0:
				_set_head(h, H.LUNGE, LUNGE_TIME)
				h.area.active = true
				_exposed = EXPOSE_TIME
				Sfx.play(&"swing", -2.0, 0.1)
		H.LUNGE:
			h.pos = h.from.lerp(h.target, 1.0 - pow(1.0 - k, 3.0))
			if h.timer <= 0.0:
				h.pos = h.target
				_set_head(h, H.HOLD, HOLD_TIME)
				Sfx.play(&"squish", -2.0, 0.2)
		H.HOLD:
			h.pos = h.target + Vector2(0, sin(_t * 40.0) * 1.0)
			if h.timer <= 0.0:
				h.area.active = false
				_set_head(h, H.RETRACT, RETRACT_TIME)
		H.RETRACT:
			h.pos = h.from.lerp(idle, k * k * (3.0 - 2.0 * k))
			if h.timer <= 0.0:
				_set_head(h, H.REST, 0.0)
		H.SPIT_WIND:
			h.pos = h.from.lerp(idle + Vector2(0, -6), minf(1.0, k * 2.0))
			if p:
				h.look = lerp_angle(h.look, (p.center() - global_position - h.pos).angle() - 0.6 * signf(p.global_position.x - global_position.x), minf(1.0, delta * 8.0))
			if h.timer <= 0.0:
				_spit(h, p)
				_set_head(h, H.SPIT, SPIT_TIME)
		H.SPIT:
			h.pos = h.from.lerp(idle, k)
			if h.timer <= 0.0:
				_set_head(h, H.REST, 0.0)
	h.area.position = h.pos + Vector2.from_angle(h.look) * 5.0


func _spit(h: VineHead, p: Player) -> void:
	if p == null:
		return
	var from_pos := head_global(h) + Vector2.from_angle(h.look) * 8.0
	var side := signf(p.global_position.x - global_position.x)
	for off: float in [-1.6, 0.0, 1.6]:
		var tgt := Vector2(p.global_position.x + off * side * T, p.global_position.y - 4.0)
		var flight := SEED_FLIGHT + off * 0.05
		var vx := (tgt.x - from_pos.x) / flight
		var vy := (tgt.y - from_pos.y - 0.5 * SEED_GRAVITY * flight * flight) / flight
		var v := Vector2(vx, vy)
		shoot(from_pos, v.normalized(), v.length(), "seed", {
			gravity = SEED_GRAVITY, damage = 1, radius = 3.5, cause = "snapvine", life = 3.0,
		})
	Sfx.play(&"shoot", -4.0, 0.15)
	Fx.burst(from_pos, 6, {
		direction = Vector2.from_angle(h.look), spread = 40.0, speed_min = 30.0, speed_max = 80.0, lifetime = 0.3,
		gradient = Palette.fade_gradient(Color("#a8c84a")), size_min = 1.0, size_max = 2.0,
	})


## 껍질은 두껍고, 머리가 뻗은 동안엔 줄기 속살이 드러난다
func modify_damage(_hit: Hit) -> float:
	return EXPOSED_MULT if _exposed > 0.0 else BARK_MULT
