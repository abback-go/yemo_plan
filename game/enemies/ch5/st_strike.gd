class_name StStrike
extends EnemyAttackArea
## 5장 공용 "예고 → 타격" 영역. 예고(피해 없음, 붉은 테두리가 차오름) → 짧은 타격(피해) → 사라짐.
## 리라의 일섬·신성 돌진 길·별기둥·별의 비, 거신의 발·손, 사도의 감옥 등 큰 공격이 모두 이것을 쓴다.
## 예고 색 규칙(docs/archive/sera/systems2.md 3절): 기본은 붉은색(위험). 바깥 신들(style "white")만 흰색 — 대신 굵고 깜빡인다.
##
## 모양(shape)
##   band    가운데 기준 가로 띠 (size = 폭×높이)          — 일섬, 돌진 길
##   pillar  바닥 기준 세로 기둥 (size = 폭×높이, 위로 솟음) — 별기둥, 빛의 창
##   circle  원 (size.x = 반지름)                           — 폭발, 착지
##   beam    from→to 선 (size.y = 두께), position = from    — 저격선, 하늘에서 떨어지는 빛
##   box     네모 감옥 (size = 폭×높이, 가운데 기준) — 예고 동안 네 변이 닫혀 들어옴
## style: star(금·흰 별빛) · white(바깥 신들) · fox(푸른 여우불) · fire(붉은 불)

signal fired(strike: StStrike)

var shape := "band"
var size := Vector2(64, 16)
var to := Vector2.ZERO ## beam 끝 (전역)
var warn := 0.8 ## 예고 시간 (만드는 쪽이 Difficulty.telegraph로 감쌈)
var hold := 0.14 ## 피해가 들어가는 시간
var fade := 0.3
var style := "star"
var shake := 0.0 ## 타격 순간 화면 흔들림 (T)
var sound: StringName = &""
var follow: Node2D = null ## 예고 동안 따라다닐 대상 (위치만)
var follow_offset := Vector2.ZERO
var lock_at := 0.0 ## 이 시간(초) 전에 따라다니기를 멈추고 고정 (예: 마지막 0.25초)
var _t := 0.0
var _fired := false
var _cs: CollisionShape2D


static func spawn(pos: Vector2, p_shape: String, p_size: Vector2, p_warn: float, opts := {}) -> StStrike:
	var s := StStrike.new()
	s.global_position = pos
	s.shape = p_shape
	s.size = p_size
	s.warn = p_warn
	s.hold = float(opts.get("hold", 0.14))
	s.fade = float(opts.get("fade", 0.3))
	s.style = String(opts.get("style", "star"))
	s.damage = int(opts.get("damage", 1))
	s.cause = StringName(opts.get("cause", "lyra"))
	s.shake = float(opts.get("shake", 0.0))
	s.sound = StringName(opts.get("sound", ""))
	s.to = opts.get("to", pos)
	s.dodgeable = bool(opts.get("dodgeable", true))
	s.lock_at = float(opts.get("lock_at", 0.0))
	var f: Variant = opts.get("follow", null)
	if f is Node2D:
		s.follow = f
		s.follow_offset = opts.get("follow_offset", Vector2.ZERO)
	Fx.effect_parent().add_child(s)
	return s


func _ready() -> void:
	active = false
	z_index = 6
	if style != "white":
		material = Fx.add_material
	_cs = CollisionShape2D.new()
	add_child(_cs)
	_rebuild_shape()


func _rebuild_shape() -> void:
	match shape:
		"circle":
			var c := CircleShape2D.new()
			c.radius = size.x
			_cs.shape = c
			_cs.position = Vector2.ZERO
			_cs.rotation = 0.0
		"beam":
			var r := RectangleShape2D.new()
			var d := to - global_position
			r.size = Vector2(maxf(d.length(), 1.0), size.y)
			_cs.shape = r
			_cs.position = d * 0.5
			_cs.rotation = d.angle()
		"pillar":
			var r2 := RectangleShape2D.new()
			r2.size = size
			_cs.shape = r2
			_cs.position = Vector2(0, -size.y * 0.5)
			_cs.rotation = 0.0
		_:
			var r3 := RectangleShape2D.new()
			r3.size = size
			_cs.shape = r3
			_cs.position = Vector2.ZERO
			_cs.rotation = 0.0


## 예고 진행도 0→1
func warn_k() -> float:
	return clampf(_t / maxf(warn, 0.001), 0.0, 1.0)


func _physics_process(delta: float) -> void:
	var d := delta * Fx.enemy_time
	_t += d
	if not _fired and is_instance_valid(follow) and (warn - _t) > lock_at:
		var old_to := to - global_position
		global_position = follow.global_position + follow_offset
		if shape == "beam":
			to = global_position + old_to
	if not _fired and _t >= warn:
		_fired = true
		if shape == "beam":
			_rebuild_shape()
		active = damage > 0 # 피해 0 = 보이기만 하는 예고선
		fired.emit(self)
		if shake > 0.0:
			Fx.shake(shake, 0.25)
		if sound != &"":
			StArt.sfx(sound, &"slam", -2.0)
		_burst()
	if _fired and active and _t >= warn + hold:
		active = false
	if _t >= warn + hold + fade:
		queue_free()
	queue_redraw()


func _col() -> Color:
	match style:
		"white": return StArt.GOD_GLOW
		"fox": return StArt.FOX_BLUE
		"fire": return Color(1.0, 0.5, 0.25)
	return StArt.STAR


func _burst() -> void:
	var c := _col()
	var at := global_position
	match shape:
		"pillar": at += Vector2(0, -8)
		"beam": at = to
	Fx.burst(at, 18, {spread = 180.0, speed_min = 40.0, speed_max = 160.0, lifetime = 0.45,
		gradient = Palette.fade_gradient(c), size_min = 1.0, size_max = 2.5, add = style != "white"})


func _draw() -> void:
	if not _fired:
		_draw_warn()
	else:
		_draw_hit()


func _danger() -> Color:
	return Palette.DANGER if style != "white" else Color(1, 1, 1)


func _draw_warn() -> void:
	var k := warn_k()
	var dc := _danger()
	var blink := 1.0
	if k > 0.7:
		blink = 0.55 + 0.45 * sin(_t * 40.0)
	var white := style == "white"
	var lw := 2.0 if white else 1.0
	var fill_a := (0.08 + 0.22 * k) * blink
	match shape:
		"circle":
			draw_circle(Vector2.ZERO, size.x * k, Color(dc, fill_a))
			draw_arc(Vector2.ZERO, size.x, 0, TAU, 32, Color(dc, 0.8 * blink), lw)
		"beam":
			var d := to - global_position
			var w := maxf(1.0, size.y * (0.25 + 0.75 * k))
			draw_line(Vector2.ZERO, d, Color(dc, 0.25 * blink), w)
			draw_line(Vector2.ZERO, d, Color(dc, 0.85 * blink), lw)
		"pillar":
			var r := Rect2(-size.x * 0.5, -size.y, size.x, size.y)
			draw_rect(Rect2(r.position.x, r.end.y - r.size.y * k, r.size.x, r.size.y * k), Color(dc, fill_a))
			draw_rect(r, Color(dc, 0.75 * blink), false, lw)
			draw_line(Vector2(-size.x * 0.7, 0), Vector2(size.x * 0.7, 0), Color(dc, blink), lw + 1.0)
		"box":
			var half := size * 0.5
			var inset := half * (1.0 - k) * 0.0
			var r2 := Rect2(-half + inset, size - inset * 2.0)
			draw_rect(r2, Color(dc, fill_a * 0.6))
			draw_rect(r2, Color(dc, 0.9 * blink), false, lw + 1.0)
			# 닫혀 들어오는 테
			var r3 := r2.grow(18.0 * (1.0 - k))
			draw_rect(r3, Color(dc, 0.4 * blink), false, lw)
		_:
			var r4 := Rect2(-size * 0.5, size)
			var grow := Rect2(r4.position.x, r4.position.y + r4.size.y * 0.5 * (1.0 - k), r4.size.x, r4.size.y * k)
			draw_rect(grow, Color(dc, fill_a))
			draw_rect(r4, Color(dc, 0.8 * blink), false, lw)
			draw_line(Vector2(r4.position.x, 0), Vector2(r4.end.x, 0), Color(dc, 0.9 * blink), lw)


func _draw_hit() -> void:
	var c := _col()
	var k := clampf((_t - warn) / maxf(hold + fade, 0.001), 0.0, 1.0)
	var a := 1.0 - k
	var core := StArt.STAR_CORE if style != "fox" else StArt.FOX_CORE
	match shape:
		"circle":
			draw_circle(Vector2.ZERO, size.x * (0.6 + 0.5 * k), Color(c, 0.35 * a))
			draw_circle(Vector2.ZERO, size.x * 0.5 * (1.0 - k), Color(core, 0.8 * a))
			draw_arc(Vector2.ZERO, size.x * (0.9 + 0.4 * k), 0, TAU, 32, Color(c, 0.8 * a), 2.0)
		"beam":
			var d := to - global_position
			draw_line(Vector2.ZERO, d, Color(c, 0.4 * a), size.y * 1.6)
			draw_line(Vector2.ZERO, d, Color(core, a), maxf(1.0, size.y * 0.5))
		"pillar":
			var w := size.x * (1.0 - 0.6 * k)
			draw_rect(Rect2(-w * 0.5, -size.y, w, size.y), Color(c, 0.45 * a))
			draw_rect(Rect2(-w * 0.2, -size.y, w * 0.4, size.y), Color(core, 0.85 * a))
			draw_circle(Vector2(0, -2), size.x * 0.9, Color(c, 0.3 * a))
		"box":
			var r := Rect2(-size * 0.5, size)
			draw_rect(r, Color(c, 0.4 * a))
			draw_rect(r, Color(core, a), false, 3.0)
		_:
			var h := size.y * (1.0 - 0.7 * k)
			draw_rect(Rect2(-size.x * 0.5, -h * 0.5, size.x, h), Color(c, 0.45 * a))
			draw_rect(Rect2(-size.x * 0.5, -h * 0.15, size.x, h * 0.3), Color(core, 0.9 * a))
