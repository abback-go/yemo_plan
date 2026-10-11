extends Node2D
## 반격 구간의 거신 발판 (방 개체 "st_colossus_ride", docs/archive/sera/chapter5.md 8.10절): 세라가 거신의 팔 위를 달려 올라
## 어깨·머리를 밟고 다음 거신으로 뛰어 건넌다(진격의 거인의 "팔 위를 달리는" 장면).
## 거신은 앞팔을 앞으로 뻗은 채(세라를 붙잡으려다 푸른 불에 잠들어 가는 중) 천천히 걷는다.
##   발판(한쪽 통과, AnimatableBody2D가 몸과 함께 움직여 세라를 실어 나름): 손바닥 위 → 팔 위(완만한 오르막) → 어깨 → 머리 꼭대기
##   걸음: 발은 그림으로만 내딛고, 몸 전체가 걸음마다 살짝 오르내리며 speed칸/초로 나아간다.
##   세라가 올라타 있으면 밟은 자리에 푸른 여우불이 번지고(잠듦 sleep 증가), 다 잠들면 무릎을 꿇듯 멈춘다(slept 신호).
## 방 데이터 키: x, y(발이 닿는 바닥 행), h(키, 칸, 기본 34), dir(right·left, 걷는 쪽), speed(칸/초, 기본 0.4),
##              phase(걸음 위상 0~1), travel(최대 이동 칸, 기본 12), sleep_need(잠들기까지 밟는 초, 기본 6)

signal slept

const T := GameConst.TILE

var h := 544.0
var dir := 1.0
var speed := 0.4
var travel := 12.0
var sleep_need := 6.0
var sleep := 0.0
var ph := 0.0
var _origin := Vector2.ZERO
var _moved := 0.0
var _t := 0.0
var _body: AnimatableBody2D
var _pose := {}
var _pal := {}
var _ride_t := 0.0
var _stopped := false
var _step_shaken := 0


func setup(room: Room, e: Dictionary, _eid: String) -> void:
	h = float(e.get("h", 34)) * T
	dir = -1.0 if String(e.get("dir", "right")) == "left" else 1.0
	speed = float(e.get("speed", 0.4))
	travel = float(e.get("travel", 12.0))
	sleep_need = float(e.get("sleep_need", 6.0))
	ph = float(e.get("phase", 0.0))
	_origin = room.tile_pos(e) + Vector2(8, 0)
	position = _origin
	z_index = -1
	_pose = pose_points(h, dir)
	_build_body()


## 고정 자세의 관절 (지역 좌표, 원점 = 엉덩이 아래 바닥)
static func pose_points(hh: float, d: float) -> Dictionary:
	var lean := 0.16
	var hip := Vector2(0, -hh * 0.48)
	var sh := hip + Vector2(sin(lean) * d, -cos(lean)) * hh * 0.26
	var head := sh + Vector2(d * hh * 0.04, -hh * 0.065)
	var sf := sh + Vector2(d * hh * 0.118 * 0.75, hh * 0.015)
	var hand := sf + Vector2(d * hh * 0.4, hh * 0.07)
	return {"hip": hip, "shoulder": sh, "head": head, "sf": sf, "hand": hand,
		"foot_f": Vector2(d * hh * 0.1, 0), "foot_b": Vector2(-d * hh * 0.12, 0)}


func _seg(a: Vector2, b: Vector2, thick := 6.0) -> CollisionShape2D:
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	var d := b - a
	r.size = Vector2(d.length(), thick)
	cs.shape = r
	cs.position = (a + b) * 0.5
	cs.rotation = d.angle() if d.x >= 0.0 else (d.angle() + PI)
	cs.one_way_collision = true
	return cs


func _build_body() -> void:
	_body = AnimatableBody2D.new()
	_body.sync_to_physics = true
	_body.collision_layer = GameConst.L_PLATFORM
	_body.collision_mask = 0
	add_child(_body)
	var hand: Vector2 = _pose.hand
	var sf: Vector2 = _pose.sf
	var sh: Vector2 = _pose.shoulder
	var head: Vector2 = _pose.head
	# 손바닥 위 (평평, 손끝 쪽 절반) → 그대로 팔 위 오르막으로 이어짐 (끊김 없이 걸어 오르게)
	var palm := hand + Vector2(0, -h * 0.03)
	_body.add_child(_seg(palm + Vector2(dir * h * 0.035, 0), palm))
	_body.add_child(_seg(palm, sf + Vector2(0, -h * 0.034)))
	# 어깨 (어깨 끝 → 목)
	_body.add_child(_seg(sf + Vector2(0, -h * 0.034), sh + Vector2(-dir * h * 0.04, -h * 0.022)))
	# 머리 꼭대기
	_body.add_child(_seg(head + Vector2(-h * 0.03, -h * 0.056), head + Vector2(h * 0.03, -h * 0.056)))


func _physics_process(delta: float) -> void:
	_t += delta
	if not _stopped:
		ph = fmod(ph + delta / 3.4, 1.0)
		if _moved < travel * T:
			_moved += speed * T * delta
	var bob := -absf(sin(ph * TAU)) * h * 0.012
	if _stopped:
		bob = move_toward(_body.position.y, h * 0.03, delta * 20.0)
	_body.position = Vector2(dir * _moved, bob)
	# 걸음마다 쿵 (화면 흔들림)
	var step := int(ph * 2.0)
	if step != _step_shaken and not _stopped:
		_step_shaken = step
		Fx.shake(0.18, 0.2)
		StArt.sfx_pitch(&"colossus_step", &"slam", 0.6, -10.0)
	# 세라가 올라타 있으면 푸른 불이 번진다
	var w := World.get_world()
	if w and w.player and w.player.is_on_floor():
		var col := w.player.get_last_slide_collision()
		if col and col.get_collider() == _body:
			_ride_t += delta
			sleep = clampf(_ride_t / maxf(sleep_need, 0.1), 0.0, 1.0)
			if fmod(_t, 0.12) < delta:
				Fx.burst(w.player.global_position, 3, {direction = Vector2.UP, spread = 30.0, speed_min = 20.0, speed_max = 60.0, lifetime = 0.6,
					gradient = Palette.fade_gradient(StArt.FOX_BLUE), add = true})
			if sleep >= 1.0 and not _stopped:
				_stopped = true
				slept.emit()
				StArt.sfx(&"fox_end", &"foxfire", 0.0)
	queue_redraw()


func _draw() -> void:
	var o: Vector2 = _body.position if _body else Vector2.ZERO
	var pal := StColossusArt.palette(0.1, 1.0, StColossusArt.FOG, maxf(sleep, 0.25))
	# 다리: 그림으로만 걷는다 (발은 엉덩이를 따라 내딛음)
	var w := ph * TAU
	var swing := sin(w) * h * 0.06
	var lift_f := maxf(0.0, sin(w)) * h * 0.05
	var lift_b := maxf(0.0, -sin(w)) * h * 0.05
	var hip: Vector2 = (_pose.hip as Vector2) + o
	var ff := Vector2(dir * h * 0.08 + swing * dir + o.x, -lift_f)
	var fb := Vector2(-dir * h * 0.1 - swing * dir + o.x, -lift_b)
	var hand: Vector2 = (_pose.hand as Vector2) + o
	var res := StColossusArt.draw_walker(self, hip, ff, fb, h, dir, pal, hand, hip + Vector2(-dir * h * 0.04, h * 0.14), 0.16)
	# 발밑 그림자
	draw_rect(Rect2(o.x - h * 0.16, -2, h * 0.32, 4), Color(0, 0, 0, 0.3))
	# 잠들어 가는 푸른 불 (팔·어깨·머리)
	if sleep > 0.0:
		var pts := [hand, res.elbow_f, res.shoulder_f, res.head]
		for i in pts.size():
			StArt.foxfire(self, pts[i], 6.0 + sleep * 4.0, _t + i, sleep)
	# 손바닥 위를 밝게 (발판 표시)
	draw_line(hand + Vector2(-dir * h * 0.03, -h * 0.03), hand + Vector2(dir * h * 0.03, -h * 0.03), Color(StArt.FOX_CORE, 0.35), 1.0)
