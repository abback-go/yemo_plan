extends EnemyBase
## 천외 사도 (docs/chapter5.md 4절): 침공 때 거신들 앞에 내려오는 흰 사도. 3장 백색 사도·4장 백금 사도의 상위.
## 발 없는 흰 몸, 등 뒤로 기하학 날개판 여섯, 얼굴 자리의 세로 틈 속 눈, 머리 위를 도는 네모 고리. 말은 겹친 메아리.
## 예고는 바깥 신들의 규칙대로 흰색 — 대신 굵고 깜빡인다.
##   빛창 셋: 0.9초 동안 주위에 흰 창 셋이 세라를 겨눔(깜빡이는 흰 선) → 하나씩 날아옴
##   기하학 감옥: 세라 자리에 흰 네모 → 1.1초 뒤 닫힘 (대시로 빠져나가기)
##   가로지르기: 세라 높이에 흰 띠 → 0.9초 뒤 날개를 접고 띠를 따라 돌진
##   지우는 구: 느리게 따라오는 흰 구 (5초, 닿거나 맞히면 터짐)
## 푸른 여우불에 약하다(피해 1.5배 + 움찔): "푸른 불은 잠재운다".

const T := GameConst.TILE
const HOVER := 4.5

var state := "idle"
var _timer := 0.0
var _state_len := 1.0
var _cd := 1.2
var _attacks := 0
var _spears: Array = [] ## 준비된 빛창 (그림)
var _fired_n := 0
var _aim_lines: Array = []
var _dive_to := Vector2.ZERO
var _dive_area: EnemyAttackArea
var _flinch_cd := 0.0
var _home := Vector2.ZERO


func _build() -> void:
	max_hp = 2400
	body_size = Vector2(22, 44)
	display_name = "천외 사도"
	subtitle = "바깥 신들의 길을 닦는 자"
	kind_id = "outer_seraph"
	flying = true
	is_elite = true
	knock_mult = 0.25
	launch_mult = 0.0
	var v := SeraphVisual.new()
	v.enemy = self
	_visual = v
	add_child(v)
	var c := add_attack_area(Vector2(16, 34), Vector2(0, -22), &"outer_seraph", 1)
	c.dodgeable = false
	_dive_area = add_attack_area(Vector2(30, 34), Vector2(0, -22), &"outer_seraph", 1)
	_dive_area.active = false


func _ready() -> void:
	super._ready()
	_home = global_position


func set_state(s: String, time := 0.0) -> void:
	state = s
	_timer = time
	_state_len = maxf(time, 0.001)


func progress() -> float:
	return clampf(1.0 - _timer / _state_len, 0.0, 1.0)


func spears() -> Array:
	return _spears


func _ai(delta: float) -> void:
	_timer -= delta
	_flinch_cd -= delta
	var p := player()
	if not engaged or p == null or not p.is_alive():
		velocity = velocity.lerp(Vector2.ZERO, minf(delta * 4.0, 1.0))
		_clear_aims()
		return
	match state:
		"idle":
			_cd -= delta
			face_player()
			# 세라 위쪽 비스듬히 떠 있으려 함
			var side := -1.0 if p.global_position.x < global_position.x else 1.0
			var want := p.global_position + Vector2(-side * 7.0 * T, -HOVER * T) + Vector2(sin(_t * 0.7) * 1.5 * T, sin(_t * 1.3) * 0.6 * T)
			velocity = velocity.lerp((want - global_position) * 1.6, minf(delta * 2.0, 1.0)).limit_length(6.0 * T)
			if _cd <= 0.0:
				_choose(p)
		"spears_wind":
			velocity = velocity.lerp(Vector2.ZERO, minf(delta * 5.0, 1.0))
			face_player()
			for i in _aim_lines.size():
				var l: Variant = _aim_lines[i]
				if is_instance_valid(l):
					var ls: StStrike = l
					ls.global_position = _spear_pos(i)
					if _timer > 0.25:
						ls.to = ls.global_position + (p.center() - ls.global_position).normalized() * 30.0 * T
			if _timer <= 0.0:
				set_state("spears", 0.75)
		"spears":
			velocity = Vector2.ZERO
			var due := mini(int(floor((_state_len - _timer) / 0.25)) + 1, 3)
			while _fired_n < due:
				var i := _fired_n
				var l2: Variant = _aim_lines[i] if i < _aim_lines.size() else null
				var dir := (p.center() - _spear_pos(i)).normalized()
				if is_instance_valid(l2):
					var ls2: StStrike = l2
					dir = (ls2.to - ls2.global_position).normalized()
					ls2.queue_free()
				StShot.fire(_spear_pos(i), dir, 18.0 * T, "white_spear", {"radius": 4.0, "damage": 1, "cause": "outer_seraph", "life": 2.5, "hits_world": false})
				StArt.sfx(&"holy_charge", &"sniper_shot", -4.0)
				if not _spears.is_empty():
					_spears.pop_front()
				_fired_n += 1
			if _timer <= 0.0:
				_clear_aims()
				_end_attack(0.9)
		"prison_wind":
			velocity = velocity.lerp(Vector2.ZERO, minf(delta * 5.0, 1.0))
			if _timer <= 0.0:
				_end_attack(0.6)
		"dive_wind":
			# 띠 높이로 미끄러져 내려와 날개를 접는다
			velocity = Vector2(0, (_dive_to.y - global_position.y) * 6.0)
			if _timer <= 0.0:
				set_state("dive", 0.9)
				_dive_area.active = true
				_dive_area.dodgeable = true
				StArt.sfx(&"holy_charge", &"charger_charge", 0.0)
		"dive":
			var to := _dive_to - global_position
			velocity = to.normalized() * 24.0 * T
			if to.length() < 12.0 or _timer <= 0.0:
				_dive_area.active = false
				velocity = Vector2.ZERO
				_end_attack(1.0)
		"orb_wind":
			velocity = velocity.lerp(Vector2.ZERO, minf(delta * 5.0, 1.0))
			if _timer <= 0.0:
				var s := StShot.fire(global_position + Vector2(facing * 12, -26), Vector2(facing, 0), 3.0 * T, "white_orb", {"radius": 6.0, "damage": 1, "cause": "outer_seraph", "homing": 1.2, "life": 5.0, "hits_world": false})
				s.z_index = 5
				StArt.sfx(&"sky_crack", &"reveal", -4.0)
				_end_attack(0.8)
		"flinch":
			velocity = velocity.lerp(Vector2.ZERO, minf(delta * 6.0, 1.0))
			if _timer <= 0.0:
				set_state("idle", 0.0)
		"recover":
			velocity = velocity.lerp(Vector2.ZERO, minf(delta * 3.0, 1.0))
			if _timer <= 0.0:
				set_state("idle", 0.0)


func _choose(p: Player) -> void:
	_attacks += 1
	face_player()
	var pick: String = ["spears", "prison", "dive", "spears", "orb"][_attacks % 5]
	match pick:
		"spears":
			set_state("spears_wind", Difficulty.telegraph(0.9))
			_spears = [0, 1, 2]
			_fired_n = 0
			_clear_aims()
			for i in 3:
				var from := _spear_pos(i)
				_aim_lines.append(StStrike.spawn(from, "beam", Vector2(0, 3), _timer, {"to": p.center(), "style": "white", "damage": 0, "hold": 0.8, "fade": 0.05}))
			_echo()
		"prison":
			set_state("prison_wind", 0.4)
			StStrike.spawn(p.center(), "box", Vector2(4.0 * T, 4.0 * T), Difficulty.telegraph(1.1), {"style": "white", "damage": 1, "cause": "outer_seraph", "hold": 0.18, "fade": 0.35, "sound": "sky_crack", "shake": 0.1})
			_echo()
		"dive":
			var y := p.center().y
			var side := -1.0 if p.global_position.x < global_position.x else 1.0
			_dive_to = Vector2(p.global_position.x + side * 8.0 * T, y + 22.0)
			var mid := Vector2((global_position.x + _dive_to.x) * 0.5, y)
			var len := absf(_dive_to.x - global_position.x) + 30.0
			set_state("dive_wind", Difficulty.telegraph(0.9))
			StStrike.spawn(mid, "band", Vector2(len, 34), _timer, {"style": "white", "damage": 0, "hold": 0.0, "fade": 0.05})
		_:
			set_state("orb_wind", Difficulty.telegraph(0.6))
	StArt.sfx(&"sky_crack", &"reveal", -6.0)


func _spear_pos(i: int) -> Vector2:
	var a := -PI * 0.5 + (i - 1) * 0.9
	return global_position + Vector2(0, -26) + Vector2(cos(a) * 20.0, sin(a) * 16.0)


func _end_attack(rest: float) -> void:
	_cd = Difficulty.rest(rest)
	set_state("recover", 0.3)


func _clear_aims() -> void:
	for l in _aim_lines:
		if is_instance_valid(l):
			l.queue_free()
	_aim_lines.clear()


## 겹친 메아리 (낮은 울림 + 높은 유리 소리)
func _echo() -> void:
	StArt.sfx_pitch(&"sky_crack", &"window", 0.6, -8.0)
	StArt.sfx_pitch(&"sky_crack", &"blip", 1.8, -12.0)


func modify_damage(hit: Hit) -> float:
	if EnemyBase.is_fox_hit(hit):
		return 1.5
	return 1.0


func _on_hit(hit: Hit, _dir: int) -> void:
	if EnemyBase.is_fox_hit(hit) and _flinch_cd <= 0.0 and state in ["idle", "recover", "orb_wind"]:
		_flinch_cd = 2.0
		set_state("flinch", 0.5)
		Fx.ring(global_position + Vector2(0, -24), 6.0, 30.0, StArt.FOX_BLUE, 0.3, 2.0)


func _die(dir: int) -> void:
	_clear_aims()
	var c := global_position + Vector2(0, -24)
	for i in 6:
		var a := TAU * i / 6.0
		Fx.burst(c + Vector2(cos(a), sin(a)) * 14.0, 6, {direction = Vector2(cos(a), sin(a)), spread = 20.0, speed_min = 40.0, speed_max = 120.0,
			lifetime = 0.6, gradient = Palette.fade_gradient(StArt.GOD_WHITE), size_min = 2.0, size_max = 4.0, add = false})
	Fx.flash(Color(1, 1, 1, 0.3), 0.2)
	StArt.sfx(&"sky_crack", &"crumble", 0.0)
	super._die(dir)


## 사도 그림: 흰 몸 + 기하학 날개판 여섯 + 세로 틈 속 눈 + 네모 고리
class SeraphVisual extends Node2D:
	var enemy: Node

	func _process(_d: float) -> void:
		if enemy:
			scale.x = float(enemy.facing)
		queue_redraw()

	func _draw() -> void:
		if enemy == null:
			return
		var t: float = enemy._t
		var st: String = enemy.state
		var k: float = enemy.progress()
		var white: bool = enemy.flash_amount() > 0.0
		var body := StArt.GOD_WHITE if not white else Color(1, 1, 1)
		var shade := StArt.GOD_SHADE
		var line := StArt.GOD_LINE
		var c := Vector2(0, -26 + sin(t * 1.6) * 2.0)
		var spread := 1.0
		var wing_rot := t * 0.25
		match st:
			"dive", "dive_wind":
				spread = 0.45
			"spears_wind", "prison_wind", "orb_wind":
				spread = 1.25
			"flinch":
				spread = 0.7
		# 날개판 여섯 (뒤에서 부채꼴)
		for i in 6:
			var a := -PI * 0.5 + (i - 2.5) * 0.42 * spread + sin(wing_rot + i) * 0.04
			var base := c + Vector2(-3, -6)
			var tip := base + Vector2(cos(a) * -1.0, sin(a)) * Vector2(1, 1) * (26.0 - absf(i - 2.5) * 2.0)
			tip = base + Vector2(-absf(cos(a)) * 18.0 - 6.0, sin(a) * 22.0)
			var n := (tip - base).normalized().orthogonal()
			var plate := PackedVector2Array([base + n * 2.0, tip + n * 4.0, tip + (tip - base).normalized() * 6.0, tip - n * 3.0, base - n * 2.0])
			draw_colored_polygon(plate, shade if i % 2 == 0 else body)
			draw_polyline(plate + PackedVector2Array([plate[0]]), line, 1.0)
		# 몸 (발 없이 아래로 가늘어짐 + 떨어지는 파편)
		var robe := PackedVector2Array([c + Vector2(-6, -4), c + Vector2(6, -4), c + Vector2(9, 12), c + Vector2(3, 22), c + Vector2(0, 28), c + Vector2(-4, 20), c + Vector2(-8, 10)])
		draw_colored_polygon(robe, body)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-6, -4), c + Vector2(-2, -4), c + Vector2(-3, 18), c + Vector2(-8, 10)]), shade)
		draw_polyline(robe + PackedVector2Array([robe[0]]), line, 1.0)
		draw_line(c + Vector2(0, -3), c + Vector2(1, 20), line, 1.0)
		for i in 3:
			var fy := fmod(t * 14.0 + i * 9.0, 26.0)
			draw_rect(Rect2(c + Vector2(-1 + i - 1, 26 + fy), Vector2(2, 2)), Color(body, 1.0 - fy / 26.0))
		# 팔 대신 늘어진 천
		draw_colored_polygon(PackedVector2Array([c + Vector2(5, -2), c + Vector2(13, 6 + sin(t * 2.0)), c + Vector2(8, 10)]), body)
		# 머리: 매끈한 알 + 세로 틈 + 그 안의 눈
		var h := c + Vector2(1, -12)
		var head := PackedVector2Array()
		for i in 12:
			var a2 := TAU * i / 12.0
			head.append(h + Vector2(cos(a2) * 5.0, sin(a2) * 7.0))
		draw_colored_polygon(head, body)
		draw_polyline(head + PackedVector2Array([head[0]]), line, 1.0)
		var open := 1.0
		match st:
			"spears_wind", "prison_wind", "dive_wind", "orb_wind":
				open = 1.0
			"flinch":
				open = 0.2
			_:
				open = 0.35 + 0.15 * sin(t * 1.2)
		draw_line(h + Vector2(2, -6), h + Vector2(2, 5), Color(0.03, 0.03, 0.06), 2.0 + open * 2.0)
		if open > 0.3:
			draw_circle(h + Vector2(2, 0), 1.5 + open, StArt.GOD_WHITE)
			draw_circle(h + Vector2(2.5, 0), 1.0, Color(0.02, 0.02, 0.05))
		# 네모 고리 (머리 위를 돈다)
		for i in 8:
			var a3 := t * 0.8 + TAU * i / 8.0
			var q := h + Vector2(cos(a3) * 11.0, -9.0 + sin(a3) * 3.0)
			draw_rect(Rect2(q - Vector2(1.5, 1.5), Vector2(3, 3)), body if sin(a3) > 0 else shade)
		# 빛창 준비 (spears_wind/spears)
		if st == "spears_wind" or st == "spears":
			var sp: Array = enemy.spears()
			for i in sp.size():
				var idx: int = sp[i]
				var a4 := -PI * 0.5 + (idx - 1) * 0.9
				var pos := Vector2(0, -26) + Vector2(cos(a4) * 20.0, sin(a4) * 16.0)
				draw_line(pos + Vector2(-8, 0), pos + Vector2(8, 0), StArt.GOD_GLOW, 2.0)
				draw_line(pos + Vector2(-8, 0), pos + Vector2(8, 0), line, 1.0)
		if st == "flinch":
			draw_arc(c, 18.0, 0, TAU, 20, Color(StArt.FOX_BLUE, 0.6 * (1.0 - k)), 2.0)
