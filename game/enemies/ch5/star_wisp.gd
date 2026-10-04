extends EnemyBase
## 별 정령 (docs/chapter5.md 4절): 리라의 사역마. 졸린 얼굴의 작은 별. 같은 별자리(link)의 정령끼리 별자리 선으로 이어진다.
##   선: 꺼짐(1.4초, 희미) → 깜빡이는 붉은 예고(0.6초) → 켜짐(2.0초, 닿으면 피해). 한 별자리의 선은 함께 숨쉰다.
##   정령 하나를 끄면(처치) 그 정령에 이어진 선이 모두 끊어진다 → 길이 열린다 (퍼즐·전투 겸용).
##   가까이 가면 몸을 부풀렸다가(0.5초) 작은 별을 하나 뱉는다(느리게 따라옴).
## 방 데이터: link(별자리 이름), order(잇는 순서), loop(true면 마지막과 처음도 이음 — order 0인 정령에), orbit(맴도는 반지름, 칸)

const T := GameConst.TILE
const CYCLE := 4.0
const OFF_T := 1.4
const WARN_T := 0.6

var link := ""
var order := 0
var loop := false
var orbit := 0.0
var _anchor := Vector2.ZERO
var _shoot_cd := 2.0
var _puff := 0.0
var _lines: Array = [] ## [{partner, area}]
var _visual_node: StarWispVisual


func _build() -> void:
	max_hp = 450
	body_size = Vector2(14, 14)
	cull_offscreen = false # 화면 밖 생략 안 함: 짝과 잇는 별자리 선
	display_name = "별 정령"
	subtitle = "리라의 졸린 사역마"
	kind_id = "star_wisp"
	flying = true
	knock_mult = 0.3
	launch_mult = 0.0
	is_elite = true
	contact_damage = 1
	_visual_node = StarWispVisual.new()
	_visual_node.enemy = self
	_visual = _visual_node
	add_child(_visual_node)
	var c := add_attack_area(Vector2(10, 10), Vector2(0, -7), &"star_wisp", 1)
	c.dodgeable = false


func _ready() -> void:
	super._ready()
	_anchor = global_position
	if link != "":
		add_to_group(StringName("st_wisp_" + link))
	_relink.call_deferred()


## 같은 별자리 정령을 order 순으로 잇는다 (낮은 쪽이 선을 가진다)
func _relink() -> void:
	for l in _lines:
		if is_instance_valid(l.area):
			l.area.queue_free()
	_lines.clear()
	if link == "" or not is_inside_tree():
		return
	var mates: Array = []
	for n in get_tree().get_nodes_in_group(StringName("st_wisp_" + link)):
		if n != self and is_instance_valid(n) and n.is_alive():
			mates.append(n)
	mates.sort_custom(func(a: Node, b: Node) -> bool: return int(a.get("order")) < int(b.get("order")))
	var next: Node = null
	for m in mates:
		if int(m.get("order")) > order:
			next = m
			break
	if next != null:
		_add_line(next)
	if loop and order == 0 and mates.size() >= 2:
		var last: Node = mates[mates.size() - 1]
		if last != next:
			_add_line(last)


func _add_line(partner: Node) -> void:
	var a := EnemyAttackArea.new()
	a.cause = &"star_wisp"
	a.damage = 1
	a.dodgeable = true
	var cs := CollisionShape2D.new()
	var seg := SegmentShape2D.new()
	cs.shape = seg
	a.add_child(cs)
	a.active = false
	add_child(a)
	_lines.append({"partner": partner, "area": a, "seg": seg})


## 별자리 선의 상태: 0 꺼짐 · 1 예고 · 2 켜짐
func line_state() -> int:
	var ph := fmod(Fx.now_ms() / 1000.0 + float(absi(hash(link)) % 97) * 0.03, CYCLE) # Fx.now_ms: 게임에선 실제 시간, 시험에선 프레임 기준
	if ph < OFF_T:
		return 0
	if ph < OFF_T + Difficulty.telegraph(WARN_T):
		return 1
	return 2


func lines() -> Array:
	return _lines


func center() -> Vector2:
	return global_position + Vector2(0, -7)


func _ai(delta: float) -> void:
	# 둥실 + 맴돌기
	var bob := sin(_t * 2.2 + order) * 3.0
	var target := _anchor + Vector2(0, bob)
	if orbit > 0.0:
		target += Vector2(cos(_t * 0.8 + order), sin(_t * 0.8 + order) * 0.6) * orbit * T
	velocity = (target - global_position) * 4.0
	var ls := line_state() if engaged else 0
	for l in _lines:
		var partner: Node = l.partner
		var area: EnemyAttackArea = l.area
		if not is_instance_valid(partner) or not partner.is_alive():
			area.active = false
			continue
		var seg: SegmentShape2D = l.seg
		seg.a = Vector2(0, -7)
		seg.b = to_local((partner as Node2D).global_position + Vector2(0, -7))
		area.active = ls == 2
	# 침 뱉기
	var p := player()
	_shoot_cd -= delta
	if _puff > 0.0:
		_puff -= delta
		if _puff <= 0.0 and p:
			StShot.fire(center(), (p.center() - center()).normalized(), 6.0 * T, "star", {"radius": 3.0, "damage": 1, "cause": "star_wisp", "homing": 0.8, "life": 4.0})
			StArt.sfx(&"star_twinkle", &"blip", -6.0)
	elif engaged and p and _shoot_cd <= 0.0 and global_position.distance_to(p.global_position) < 9.0 * T:
		_shoot_cd = randf_range(3.5, 4.8)
		_puff = Difficulty.telegraph(0.5)


func puffing() -> float:
	return clampf(_puff / 0.5, 0.0, 1.0) if _puff > 0.0 else 0.0


func _die(dir: int) -> void:
	for l in _lines:
		if is_instance_valid(l.area):
			l.area.active = false
	_lines.clear()
	# 이 정령을 향하던 다른 정령의 선도 끊김 (상대 쪽 is_alive 검사로 꺼짐)
	Fx.burst(center(), 24, {spread = 180.0, speed_min = 30.0, speed_max = 120.0, lifetime = 0.7, gradient = Palette.fade_gradient(StArt.STAR),
		gravity = Vector2(0, -60), add = true})
	StArt.sfx(&"star_burst", &"reveal", -4.0)
	super._die(dir)


## 별 정령 그림: 다섯 꼭짓점의 통통한 별, 선이 꺼져 있으면 졸고(눈 감음) 켜지면 눈을 뜬다
class StarWispVisual extends Node2D:
	var enemy: Node

	func _draw() -> void:
		if enemy == null:
			return
		var t: float = enemy._t
		var ls: int = enemy.line_state() if enemy.engaged else 0
		var white: bool = enemy.flash_amount() > 0.0
		# 선 (몸보다 먼저)
		for l in enemy.lines():
			var partner: Node = l.partner
			if not is_instance_valid(partner) or not partner.is_alive():
				continue
			var b: Vector2 = to_local((partner as Node2D).global_position + Vector2(0, -7))
			var a := Vector2(0, -7)
			match ls:
				0:
					draw_line(a, b, Color(StArt.STAR, 0.15), 1.0)
				1:
					var bl := 0.4 + 0.6 * absf(sin(t * 18.0))
					draw_line(a, b, Color(Palette.DANGER, 0.7 * bl), 1.0)
				_:
					draw_line(a, b, Color(StArt.STAR, 0.3), 5.0)
					draw_line(a, b, Color(StArt.STAR_CORE, 0.95), 1.0)
					var k := fmod(t * 1.5, 1.0)
					draw_circle(a.lerp(b, k), 2.0, Color(StArt.STAR_CORE, 0.8))
		var puff: float = enemy.puffing()
		var c := Vector2(0, -7)
		var r := 6.0 + puff * 2.5 + sin(t * 3.0) * 0.4
		var col := StArt.STAR_GOLD if not white else Color.WHITE
		draw_circle(c, r + 4.0, Color(StArt.STAR, 0.12 + (0.1 if ls == 2 else 0.0)))
		StArt.star(self, c, r, col.darkened(0.15), -PI * 0.5 + sin(t * 1.3) * 0.15, 0.55)
		StArt.star(self, c + Vector2(-0.5, -0.5), r * 0.8, col, -PI * 0.5 + sin(t * 1.3) * 0.15, 0.55)
		# 얼굴
		var eye_y := c.y + 0.5
		if ls == 2 or puff > 0.0:
			draw_rect(Rect2(c.x - 3, eye_y - 1, 1, 2), Color("#3a2a40"))
			draw_rect(Rect2(c.x + 2, eye_y - 1, 1, 2), Color("#3a2a40"))
		else:
			draw_line(Vector2(c.x - 3.5, eye_y), Vector2(c.x - 1.5, eye_y), Color("#3a2a40"), 1.0)
			draw_line(Vector2(c.x + 1.5, eye_y), Vector2(c.x + 3.5, eye_y), Color("#3a2a40"), 1.0)
			# 졸음 "z"
			var zk := fmod(t * 0.5, 1.0)
			draw_string(ThemeDB.fallback_font, c + Vector2(5 + zk * 4.0, -6 - zk * 8.0), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.6 * (1.0 - zk)))
		if puff > 0.0:
			draw_circle(Vector2(c.x, eye_y + 2.5), 1.2 + puff, Color("#3a2a40"))
		draw_rect(Rect2(c.x - 4.5, eye_y + 1.5, 1.5, 1), Color(1.0, 0.6, 0.6, 0.6))
		draw_rect(Rect2(c.x + 3, eye_y + 1.5, 1.5, 1), Color(1.0, 0.6, 0.6, 0.6))

	func _process(_d: float) -> void:
		queue_redraw()
