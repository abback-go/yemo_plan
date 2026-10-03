extends Node2D
## 첨탑 추격 장치 (docs/chapter4.md 2절 7·7.6절) — 1장 무너지는 회랑(collapse_chaser)을 훨씬 크게.
## 폭주한 아우렐리아에게서 첨탑을 위로 도망치는 방(tp_spire_1~5)에 하나씩 둔다.
##   ① 아래에서 차오르는 금빛 (rise 칸/초): 세라의 발이 잠기면 1 피해 + 위로 튕겨 오르고 금빛이 5칸 물러남(초보자도 다시 붙을 수 있게).
##      쓰러지면 이 방 입구(spawn)에서 바로 다시 (방에 들어올 때 부활 지점을 이 방으로 정함).
##   ② 신성 돌진 (interval초마다): 화면 끝에 아우렐리아가 나타남(0.35초) → 방을 가로지르는 금빛 예고 띠(세라가 선 높이, 붉은 가장자리,
##      Difficulty.telegraph(0.9)) → 잔상을 끌며 반대편 끝까지 돌진(띠에 있으면 1 피해) → 그 띠의 비계 발판(spire_plank)은 부서진다.
##   ③ 배경: 이따금 거대한 금빛 그림자가 첨탑 바깥을 스치고 지나간다(쫓기는 느낌).
## 방 데이터: {t:"holy_chaser", start_y(처음 금빛 수면 행, 기본 방 바닥+2), stop_y(이 행보다 위로 올라가면 추격 끝),
##            rise(칸/초, 기본 1.2), delay(시작 뒤 차오르기까지 초, 기본 1.5), first(첫 돌진까지 초, 기본 4), interval(돌진 간격, 0이면 없음),
##            start_flag(이 플래그가 서야 시작; 비우면 방에 들어오자마자), spawn(부활 등장 위치, 기본 "start"), id}
## 대본: actor("holy_chaser") → start() · stop() · set_paused(bool) · await charge_at(띠 가운데 y, 방향, 막는 노드) · signal charge_blocked
## 레오니 장면(tp_spire_3): set_paused(true) 뒤 await charge_at(y, -1, 레오니) — 레오니 앞에서 돌진이 막히고 아우렐리아가 튕겨 나간다.

signal charge_blocked
signal charge_done
signal finished

const H := preload("res://enemies/ch4/holy.gd")
const T := 16.0
const BAND := 36.0
const DASH_SPEED_T := 46.0
const APPEAR := 0.35
const CATCH_PUSH := -640.0
const RECEDE_T := 5.0

enum C { NONE, APPEAR, WARN, DASH, AFTER }

var start_flag := ""
var spawn_id := "start"
var rise := 1.2
var delay := 1.5
var first := 4.0
var interval := 0.0
var stop_row := 0.0
var surface_y := 0.0 ## 금빛 수면 (전역 y)
var running := false
var paused := false
var done := false
var cstate: C = C.NONE
var band_y := 0.0
var cdir := 1
var cx := 0.0 ## 돌진하는 아우렐리아 x
var _start_surface := 0.0
var _room_w := 640.0
var _room_h := 368.0
var _room_id := ""
var _t := 0.0
var _delay_left := 0.0
var _charge_t := 0.0
var _ct := 0.0
var _cdur := 0.0
var _grace := 0.0
var _rumble := 0.0
var _blocker: Node2D = null
var _scripted := false
var _wake := 0.0
var _wake_y := 0.0
var _ghost_t := 5.0
var _ghost_k := -1.0
var _ghost_dir := 1
var _ghost_y := 0.0
var _band: H.SegmentArea
var _aurelia: CharacterVisual
var _bg: Node2D
var _bg_ghost: CharacterVisual
var _glow: Node2D
var _warned := false


func setup(room: Room, e: Dictionary, _eid: String) -> void:
	position = Vector2.ZERO
	_room_w = room.size_px.x
	_room_h = room.size_px.y
	_room_id = room.data.id
	start_flag = String(e.get("start_flag", ""))
	spawn_id = String(e.get("spawn", "start"))
	rise = float(e.get("rise", 1.2))
	delay = float(e.get("delay", 1.5))
	first = float(e.get("first", 4.0))
	interval = float(e.get("interval", 0.0))
	stop_row = float(e.get("stop_y", 6))
	_start_surface = float(e.get("start_y", room.data.row_count() + 2)) * T
	surface_y = _start_surface
	z_index = 25


func actor_id() -> String:
	return "holy_chaser"


func _ready() -> void:
	_band = H.SegmentArea.new()
	_band.cause = &"aurelia_charge"
	_band.damage = 1
	_band.dodgeable = true
	_band.active = false
	add_child(_band)
	_aurelia = CharacterVisual.new()
	_aurelia.setup("aurelia_berserk")
	_aurelia.set_pose("berserk_charge")
	_aurelia.visible = false
	_aurelia.z_index = 2
	add_child(_aurelia)
	_bg = Node2D.new()
	_bg.z_as_relative = false
	_bg.z_index = -12
	add_child(_bg)
	_bg_ghost = CharacterVisual.new()
	_bg_ghost.setup("aurelia_berserk")
	_bg_ghost.set_pose("berserk_charge")
	_bg_ghost.scale = Vector2(3, 3)
	_bg_ghost.modulate = Color(1.0, 0.92, 0.65, 0.0)
	_bg.add_child(_bg_ghost)
	_glow = GlowDraw.new()
	_glow.set("ch", self)
	add_child(_glow)
	if start_flag == "":
		call_deferred("start")


class GlowDraw extends Node2D:
	var ch: Node2D

	func _ready() -> void:
		material = Fx.add_material
		z_index = 1

	func _process(_d: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if ch:
			ch.call("draw_glow", self)


# ─── 대본용 ─────────────────────────────────────────────

func start() -> void:
	if running or done:
		return
	running = true
	_delay_left = delay
	_charge_t = first
	GameState.respawn_room = _room_id
	GameState.respawn_spawn = spawn_id
	H.snd(&"crumble", &"crumble", 0.0)
	Fx.shake(0.3, 0.5)


func stop() -> void:
	running = false
	done = true
	_band.active = false
	finished.emit()


func set_paused(v: bool) -> void:
	paused = v


## 대본: 정한 높이로 돌진 한 번 (blocker가 있으면 그 앞에서 막힘). 끝날 때까지 기다린다
func charge_at(y_center: float, dir: int, blocker: Node2D = null, warn := -1.0) -> void:
	if cstate != C.NONE:
		await charge_done
	_scripted = true
	_blocker = blocker
	_begin_charge(y_center, dir, warn)
	await charge_done
	_scripted = false


# ─── 매 프레임 ──────────────────────────────────────────

func _physics_process(delta: float) -> void:
	_t += delta
	_grace = maxf(_grace - delta, 0.0)
	_wake = maxf(_wake - delta * 1.5, 0.0)
	var w := World.get_world()
	if w == null or w.player == null:
		return
	var p := w.player
	if not running and not done and start_flag != "" and GameState.has_flag(start_flag):
		start()
	_tick_ghost(delta, p)
	_tick_charge(delta, p)
	if not running or done:
		queue_redraw()
		return
	# 꼭대기에 닿으면 끝
	if p.global_position.y < stop_row * T:
		stop()
		return
	if not paused and not Story.busy():
		if _delay_left > 0.0:
			_delay_left -= delta
		else:
			surface_y -= rise * T * delta
			# 세라에게서 너무 멀어지면 조금 빨리 따라붙음 (긴장 유지)
			var gap := surface_y - p.global_position.y
			if gap > 12.0 * T:
				surface_y -= rise * T * delta * 1.2
		surface_y = maxf(surface_y, stop_row * T + 2.0 * T)
		if interval > 0.0 and cstate == C.NONE:
			_charge_t -= delta
			if _charge_t <= 0.0 and p.is_alive() and surface_y - p.global_position.y > 2.5 * T:
				_charge_t = interval
				_auto_charge(p)
		_rumble -= delta
		if _rumble <= 0.0:
			_rumble = randf_range(1.6, 2.6)
			Sfx.play(&"crumble", -14.0, 0.2)
			Fx.shake(0.05, 0.3)
		if p.is_alive() and _grace <= 0.0 and p.global_position.y > surface_y + 6.0:
			_catch(p)
	queue_redraw()


func _catch(p: Player) -> void:
	_grace = 1.3
	p.take_damage(1, &"holy_light", p.global_position.x)
	if p.is_alive():
		p.velocity = Vector2(p.velocity.x * 0.3, CATCH_PUSH)
		surface_y = minf(surface_y + RECEDE_T * T, _start_surface)
		H.sparkle(p.center(), 20, 10.0, 60.0, 0.7)
		Fx.flash(Color(1.0, 0.9, 0.6, 0.25), 0.2)
		if not _warned:
			_warned = true
			Story.toast("금빛에 잠기면 밀려 올라가지만 다친다! 멈추지 말고 올라가!", 3.0)


# ─── 신성 돌진 ──────────────────────────────────────────

func _auto_charge(p: Player) -> void:
	var space := get_world_2d().direct_space_state
	var stand := H.floor_below(space, p.global_position + Vector2(0, -6), 4.0 * T)
	if stand == INF:
		stand = p.global_position.y
	# 세라에게서 먼 쪽 끝에 나타나 세라 쪽으로 (예고 띠를 볼 시간이 길게)
	var dir := 1 if p.global_position.x > _room_w * 0.5 else -1
	_blocker = null
	_begin_charge(stand - BAND * 0.5, dir, -1.0)


func _begin_charge(y_center: float, dir: int, warn: float) -> void:
	band_y = y_center
	cdir = dir if dir != 0 else 1
	cx = -40.0 if cdir > 0 else _room_w + 40.0
	cstate = C.APPEAR
	_ct = 0.0
	_cdur = APPEAR
	_aurelia.visible = true
	_aurelia.modulate = Color(1, 1, 1, 0.0)
	_aurelia.position = Vector2((12.0 if cdir > 0 else _room_w - 12.0), band_y + BAND * 0.5 - 4.0)
	_aurelia.scale = Vector2(float(cdir), 1)
	_aurelia.set_pose("berserk_charge")
	H.snd(&"holy_charge", &"charger_windup", 0.0)
	H.sparkle(_aurelia.position + Vector2(0, -20), 24, 10.0, 0.0, 0.5, true)
	Fx.ring(_aurelia.position + Vector2(0, -20), 40.0, 4.0, Color(1, 1, 1), 0.3, 2.0)
	if warn < 0.0:
		warn = Difficulty.telegraph(0.9)
	set_meta("warn", warn)
	for pl in get_tree().get_nodes_in_group(&"spire_plank"):
		if pl.has_method("in_band") and pl.call("in_band", band_y - BAND * 0.5, band_y + BAND * 0.5):
			pl.call("tremble")


func _tick_charge(delta: float, p: Player) -> void:
	if cstate == C.NONE:
		return
	_ct += delta
	match cstate:
		C.APPEAR:
			_aurelia.modulate = Color(1, 1, 1, clampf(_ct / APPEAR, 0.0, 1.0))
			if _ct >= _cdur:
				cstate = C.WARN
				_ct = 0.0
				_cdur = float(get_meta("warn", 0.9))
				Sfx.play(&"charger_windup", -2.0, 0.0)
		C.WARN:
			if Engine.get_physics_frames() % 3 == 0:
				H.sparkle(_aurelia.position + Vector2(cdir * 50, -18), 3, 12.0, 0.0, 0.3, true)
			if _ct >= _cdur:
				cstate = C.DASH
				_ct = 0.0
				cx = _aurelia.position.x
				_band.active = true
				H.snd(&"holy_charge", &"charger_charge", 4.0)
				Sfx.play(&"dash", 0.0, 0.0)
				Fx.shake(0.4, 0.35)
				Fx.flash(Color(1, 1, 0.95, 0.2), 0.12)
		C.DASH:
			cx += cdir * DASH_SPEED_T * T * delta
			_aurelia.position.x = cx
			_band.set_segment(Vector2(cx - cdir * 80.0, band_y), Vector2(cx + cdir * 50.0, band_y), BAND)
			_wake = 1.0
			_wake_y = band_y
			if Engine.get_physics_frames() % 2 == 0:
				_afterimage()
				Fx.burst(Vector2(cx - cdir * 10, band_y + 10), 4, {
					direction = Vector2(-cdir, -0.5), spread = 40.0, speed_min = 40.0, speed_max = 160.0, lifetime = 0.45,
					gradient = H.white_grad(), size_min = 1.0, size_max = 3.0, gravity = Vector2(0, 200), add = true,
				})
			# 지나간 자리의 비계 발판이 부서짐
			for pl in get_tree().get_nodes_in_group(&"spire_plank"):
				var pn := pl as Node2D
				if pn == null or not pl.call("in_band", band_y - BAND * 0.5, band_y + BAND * 0.5):
					continue
				var px0 := pn.global_position.x
				var px1 := px0 + float(pl.get("w_px"))
				if (cdir > 0 and cx >= px0) or (cdir < 0 and cx <= px1):
					pl.call("shatter")
			if _blocker and is_instance_valid(_blocker):
				var bx := _blocker.global_position.x
				if (cdir > 0 and cx + 34.0 >= bx) or (cdir < 0 and cx - 34.0 <= bx):
					_clash(bx)
					return
			if (cdir > 0 and cx > _room_w + 60.0) or (cdir < 0 and cx < -60.0):
				_end_charge()
		C.AFTER:
			_aurelia.modulate.a = maxf(1.0 - _ct / 0.6, 0.0)
			_aurelia.position += Vector2(-cdir * 140.0 * delta, -60.0 * delta)
			if _ct >= 0.6:
				cstate = C.NONE
				_aurelia.visible = false
				charge_done.emit()


func _clash(bx: float) -> void:
	_band.active = false
	_blocker = null
	cx = bx - cdir * 34.0
	_aurelia.position.x = cx
	_aurelia.set_pose("berserk_hurt")
	cstate = C.AFTER
	_ct = 0.0
	H.snd(&"sword_clash", &"block", 4.0)
	H.snd(&"parry", &"hit_heavy", 2.0)
	Fx.hitstop(0.15)
	Fx.shake(0.8, 0.5)
	Fx.flash(Color(1, 1, 1, 0.5), 0.25)
	var at := Vector2(bx - cdir * 16.0, band_y)
	Fx.ring(at, 4.0, 80.0, Color(1, 1, 1), 0.4, 4.0)
	Fx.burst(at, 50, {
		spread = 180.0, speed_min = 80.0, speed_max = 300.0, lifetime = 0.6, damping = 30.0,
		gradient = H.gold_grad(), size_min = 1.5, size_max = 3.5, gravity = Vector2(0, 300), add = true,
	})
	charge_blocked.emit()


func _end_charge() -> void:
	_band.active = false
	cstate = C.NONE
	_aurelia.visible = false
	charge_done.emit()


func _afterimage() -> void:
	var cv := CharacterVisual.new()
	cv.setup("aurelia_berserk")
	cv.set_pose("berserk_charge")
	cv.pose_t = 1.0
	cv.set_meta("halo", 0.001)
	cv.scale = Vector2(float(cdir), 1)
	cv.global_position = _aurelia.global_position
	cv.modulate = Color(1.0, 0.95, 0.8, 0.5)
	cv.z_index = 24
	Fx.effect_parent().add_child(cv)
	var tw := cv.create_tween()
	tw.tween_property(cv, "modulate:a", 0.0, 0.25)
	tw.tween_callback(cv.queue_free)


# ─── 배경의 거대한 그림자 ───────────────────────────────

func _tick_ghost(delta: float, p: Player) -> void:
	if not running or done:
		_bg_ghost.modulate.a = 0.0
		return
	if _ghost_k < 0.0:
		_ghost_t -= delta
		if _ghost_t <= 0.0 and cstate == C.NONE:
			_ghost_k = 0.0
			_ghost_dir = 1 if randf() < 0.5 else -1
			_ghost_y = p.global_position.y - randf_range(40.0, 110.0)
			Sfx.play(&"whoosh", -10.0, 0.2)
		return
	_ghost_k += delta / 1.8
	var x := lerpf(-120.0, _room_w + 120.0, _ghost_k) if _ghost_dir > 0 else lerpf(_room_w + 120.0, -120.0, _ghost_k)
	_bg_ghost.position = Vector2(x, _ghost_y + sin(_ghost_k * PI) * -30.0)
	_bg_ghost.scale = Vector2(3.0 * _ghost_dir, 3.0)
	_bg_ghost.modulate = Color(1.0, 0.9, 0.6, 0.32 * sin(_ghost_k * PI))
	if _ghost_k >= 1.0:
		_ghost_k = -1.0
		_ghost_t = randf_range(5.0, 8.0)
		_bg_ghost.modulate.a = 0.0


# ─── 그림 ───────────────────────────────────────────────

func _draw() -> void:
	if surface_y < _room_h + 40.0:
		# 차오르는 금빛 몸통 (수면 아래)
		var top := surface_y
		var steps := 8
		for i in steps:
			var y0 := top + i * 14.0
			var a := 0.55 + i * 0.05
			draw_rect(Rect2(-20, y0, _room_w + 40, 15), Color(1.0, 0.78 - i * 0.03, 0.35 - i * 0.02, minf(a, 0.9)))
		draw_rect(Rect2(-20, top + steps * 14.0, _room_w + 40, maxf(_room_h + 200.0 - top, 0.0)), Color(0.9, 0.62, 0.22, 0.92))


## 가산 합성: 수면의 빛·물결, 돌진 예고 띠, 돌진 자국
func draw_glow(c: CanvasItem) -> void:
	var gold := Color(1.0, 0.86, 0.45)
	if surface_y < _room_h + 40.0:
		var pts := PackedVector2Array()
		var n := int(_room_w / 16.0) + 3
		for i in n:
			var x := -16.0 + i * 16.0
			pts.append(Vector2(x, surface_y + sin(x * 0.05 + _t * 3.0) * 3.0 + sin(x * 0.11 - _t * 2.0) * 2.0))
		c.draw_polyline(pts, Color(1, 1, 0.9, 0.95), 2.0)
		c.draw_rect(Rect2(-20, surface_y - 40, _room_w + 40, 40), Color(gold, 0.06))
		c.draw_rect(Rect2(-20, surface_y - 16, _room_w + 40, 16), Color(gold, 0.1))
		for i in 18:
			var k := fmod(_t * 0.5 + i * 0.137, 1.0)
			var x2 := fmod(i * 97.0 + _t * 9.0, _room_w)
			c.draw_rect(Rect2(x2, surface_y - k * 60.0, 2, 2), Color(1, 0.95, 0.75, 1.0 - k))
	if cstate == C.WARN:
		var k2 := clampf(_ct / maxf(_cdur, 0.01), 0.0, 1.0)
		var half := BAND * 0.5
		var pulse := 0.5 + 0.5 * sin(_t * 26.0)
		var fill := Color(gold, 0.08 + 0.16 * k2)
		if k2 > 0.75 and pulse > 0.5:
			fill = Color(1, 1, 1, 0.28)
		c.draw_rect(Rect2(0, band_y - half, _room_w, half * 2.0), fill)
		c.draw_line(Vector2(0, band_y - half), Vector2(_room_w, band_y - half), Color(1.0, 0.25, 0.25, 0.5 + 0.4 * pulse), 2.0)
		c.draw_line(Vector2(0, band_y + half), Vector2(_room_w, band_y + half), Color(1.0, 0.25, 0.25, 0.5 + 0.4 * pulse), 2.0)
		c.draw_line(Vector2(0, band_y), Vector2(_room_w, band_y), Color(gold, 0.5 + 0.5 * k2), 1.0 + 2.0 * k2)
		var sp := 34.0
		var off := fmod(_t * 260.0, sp)
		var x3 := off if cdir > 0 else _room_w - off
		while (x3 < _room_w if cdir > 0 else x3 > 0.0):
			c.draw_polyline(PackedVector2Array([Vector2(x3 - cdir * 6, band_y - 8), Vector2(x3, band_y), Vector2(x3 - cdir * 6, band_y + 8)]), Color(gold, 0.35 + 0.45 * k2), 2.0)
			x3 += cdir * sp
	if _wake > 0.0:
		var x0 := 0.0 if cdir > 0 else cx
		var x1 := cx if cdir > 0 else _room_w
		c.draw_rect(Rect2(x0, _wake_y - 14, x1 - x0, 28), Color(1, 0.97, 0.88, 0.2 * _wake))
		c.draw_rect(Rect2(x0, _wake_y - 4, x1 - x0, 8), Color(1, 1, 1, 0.5 * _wake))
