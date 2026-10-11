class_name EBossStage
extends EStage
## 검성 보스전 "달빛 폐정원": 달 아래 무너진 동방의 안뜰 — 대숲 실루엣, 기와 담, 석등, 바람에 날리는 꽃잎(먹·붉은빛·뼈흰).
## 왼쪽 입구에 가마솥(쉼터)과 무너진 문. 문을 지나 TRIGGER_X를 넘으면 싸움이 열리고 뒤로 먹빛 장막이 닫힌다.
## 쓰러지면 입구에서 다시 일어서고(물약 가득), 검성은 처음(체력 가득·1막)부터 다시 선다 — 문을 지나면 다시 시작.
## 이기면 끝 화면(다시 겨루기·훈련장·타이틀). 들어오는 길: 타이틀 메뉴 "에스카 보스전 (검성)" 또는 웹 주소 뒤 ?eska_boss
## 기준서: docs/eska/design.md 6장.

const W := 1120.0
const FLOOR := 300.0
const GATE_X := 300.0 ## 무너진 문 (싸움 중엔 여기에 장막)
const TRIGGER_X := 380.0 ## 이 줄을 넘으면 싸움 시작
const BOSS_X := 860.0
const CAULDRON_X := 84.0
const RESPAWN := Vector2(150, FLOOR)
const WIND := 46.0 ## 바람 세기 (꽃잎·머리칼·자락)
const INTRO_T := 3.2 ## 처음 만남 연출 길이 (실제 시간)
const FRAME_PULL := 0.85 ## 싸움 중 카메라를 둘 사이 가운데로 당기는 정도 (1 = 정가운데)

enum F { WAIT, INTRO, FIGHT, WON }

var boss: EKensei
var fight := F.WAIT
var deaths := 0
var hits_taken := 0
var _hp_seen := EEska.MAX_HP
var _first := true
var _intro_t := 0.0
var _clock := 0.0
var _real_ms := 0
var _barrier: StaticBody2D
var _curtain: Curtain
var _poise_bar: PoiseBar
var _wind_k := 1.0 ## 바람 배수 (연출이 올림)
var _wind_sfx := 3.0
var _petal_t := 0.0
var closeup := 0.0 ## 시험용: 검성을 확대해 보기 (카메라 추가 확대 배수)
var _cine_t := 0.0
var _cine_p := Vector2.ZERO
var _cine_w := 0.0
var _cine_zoom := 0.0


func _build() -> void:
	stage_w = W
	floor_y = FLOOR
	cam_top = FLOOR - 520.0
	respawn_at = RESPAWN
	music = "shingye"
	_backdrop()
	flat_ground()
	# 장막(싸움 중 입구를 막음): 처음엔 꺼 둠
	_barrier = StaticBody2D.new()
	_barrier.collision_layer = 0
	_barrier.collision_mask = 0
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(16, 400)
	cs.shape = rs
	cs.position = Vector2(GATE_X, FLOOR - 200.0)
	_barrier.add_child(cs)
	add_child(_barrier)
	ECauldron.place(self, Vector2(CAULDRON_X, FLOOR))


func _start() -> void:
	hud.boss_name = "검성"
	var layer := hud.get_parent()
	_poise_bar = PoiseBar.new()
	_poise_bar.stage = self
	layer.add_child(_poise_bar)
	eska.hurt_taken.connect(_on_hurt)
	_spawn_boss()
	EKenseiFx.wind = Vector2(WIND, 0)


func _spawn_boss() -> void:
	boss = EKensei.new()
	boss.position = Vector2(BOSS_X, FLOOR)
	boss.x_min = GATE_X + 24.0
	boss.x_max = W - 24.0
	add_child(boss)
	boss.died.connect(_on_boss_died)
	boss.phase_changed.connect(_on_phase)
	boss.phase_starting.connect(_on_phase_start)
	boss.poise_broken.connect(_on_break)


# ═══════════════════════════════════════════════════════════
# 진행
# ═══════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	super._process(delta)
	var now := Fx.now_ms()
	var real := minf(float(now - _real_ms) * 0.001, 0.1) if _real_ms > 0 else delta
	_real_ms = now
	match fight:
		F.WAIT:
			if eska.global_position.x > TRIGGER_X and not eska.is_dead():
				_open_fight()
		F.INTRO:
			_intro_t += real
			_tick_intro()
		F.FIGHT:
			_clock += real
			_frame_both(real)
	_tick_cine(real)
	if closeup > 0.0 and is_instance_valid(boss):
		cam.set("focus_p", boss.global_position + Vector2(0, -28))
		cam.set("focus_w", 1.0)
		cam.set("zoom_extra", closeup)
	_tick_wind(delta)


## 연출 카메라: dur초(실제 시간) 동안 p를 w만큼 가운데로, zoom만큼 더 확대 — 끝나면 부드럽게 돌아옴
func _cine(p: Vector2, w: float, zoom: float, dur: float) -> void:
	_cine_p = p
	_cine_w = w
	_cine_zoom = zoom
	_cine_t = dur


func _tick_cine(real: float) -> void:
	if closeup > 0.0:
		return
	var z := float(cam.get("zoom_extra"))
	if _cine_t > 0.0:
		_cine_t -= real
		var fp := cam.get("focus_p") as Vector2
		cam.set("focus_p", fp.lerp(_cine_p, 1.0 - exp(-real * 4.0)))
		cam.set("focus_w", move_toward(float(cam.get("focus_w")), _cine_w, real * 1.6))
		cam.set("zoom_extra", lerpf(z, _cine_zoom, 1.0 - exp(-real * 2.5)))
	elif z > 0.001:
		cam.set("zoom_extra", move_toward(z, 0.0, real * 0.8))


## 싸움 중 카메라: 에스카를 따라가되 검성 쪽으로 조금 당겨 둘 다 보이게
func _frame_both(real: float) -> void:
	if closeup > 0.0 or _cine_t > 0.0:
		return
	var want := 0.0
	if is_instance_valid(boss) and not boss.is_dead():
		var dx := absf(boss.global_position.x - eska.global_position.x)
		want = FRAME_PULL * (1.0 - smoothstep(420.0, 600.0, dx))
		var mid := (boss.global_position + eska.global_position) * 0.5 + Vector2(0, -70)
		cam.set("focus_p", (cam.get("focus_p") as Vector2).lerp(mid, 1.0 - exp(-real * 5.0)))
	cam.set("focus_w", move_toward(float(cam.get("focus_w")), want, real * 1.5))


## 문을 지남: 처음엔 긴 만남 연출, 다시 할 때는 짧게
func _open_fight() -> void:
	fight = F.INTRO
	_intro_t = 0.0
	_curtain_on(true)
	if _first:
		eska.controls_locked = true
		touch.release_all()
		touch.visible = false
		cam.set("focus_p", eska.global_position + Vector2(0, -70))
		_cine(boss.global_position + Vector2(-30, -46), 1.0, 0.55, INTRO_T - 0.3)
		_wind_k = 2.2
		Music.play("", 0.8)
	else:
		_intro_t = INTRO_T - 0.7


func _tick_intro() -> void:
	if _first and _intro_t >= 1.5 and not boss._eyes_open:
		boss.open_eyes()
		_wind_k = 1.0
		Fx.shake(0.3, 0.2)
	if _first and _intro_t >= 1.7 and hud.boss == null:
		_show_boss("칼을 뽑은 것을 본 이는 없다", 2.4)
	if _intro_t >= INTRO_T:
		if not _first:
			boss.open_eyes()
			_show_boss("다시 마주 선다", 1.4)
		fight = F.FIGHT
		_first = false
		eska.controls_locked = false
		touch.visible = true
		boss.begin()


func _show_boss(sub: String, dur: float) -> void:
	hud.boss = boss
	hud.banner("검성", sub, dur)
	Music.play("shingye_tension", 0.6)
	Sfx.play_pitch(&"kb_sheath", 0.8, -2.0)


## 막 전환이 시작됨: 검성 쪽으로 살짝 당겨 확대
func _on_phase_start() -> void:
	_cine((boss.global_position + eska.global_position) * 0.5 * 0.4 + boss.global_position * 0.6 + Vector2(0, -50), 0.9, 0.35, 2.4)


func _on_phase(_p: int) -> void:
	Music.play("boss", 0.4)
	hud.banner("검성 · 발검", "칼집을 버렸다", 2.2)
	_wind_k = 1.5


func _on_break(_e: EEnemy) -> void:
	hud.banner("무너짐", "지금 — 대마법을 넣을 때", 1.3)


func _on_hurt(hp: int) -> void:
	if hp < _hp_seen:
		hits_taken += 1
	_hp_seen = hp


func _curtain_on(on: bool) -> void:
	_barrier.collision_layer = 1 if on else 0
	if on and not is_instance_valid(_curtain):
		_curtain = Curtain.new()
		_curtain.position = Vector2(GATE_X, FLOOR)
		add_child(_curtain)
	elif not on and is_instance_valid(_curtain):
		_curtain.close()


## 바람: 꽃잎을 흘려보내고 가끔 바람 소리
func _tick_wind(delta: float) -> void:
	var gust := 0.75 + 0.35 * sin(_clock * 0.7 + float(Time.get_ticks_msec()) * 0.0004) * sin(float(Time.get_ticks_msec()) * 0.0011)
	EKenseiFx.wind = Vector2(WIND * _wind_k * gust, 0.0)
	var d := EKenseiFx.Drift.get_layer()
	if d == null:
		return
	_petal_t -= delta * _wind_k
	if _petal_t <= 0.0:
		_petal_t = randf_range(0.05, 0.16)
		var r := _view_rect()
		d.spawn(Vector2(r.position.x - 6.0, randf_range(r.position.y + 20.0, FLOOR - 4.0)), Vector2(EKenseiFx.wind.x * 1.4, randf_range(-10, 20)), randf_range(5.0, 9.0))
	_wind_sfx -= delta
	if _wind_sfx <= 0.0:
		_wind_sfx = randf_range(5.0, 9.0)
		Sfx.play_pitch(&"kb_wind", randf_range(0.85, 1.1), -14.0)


func _view_rect() -> Rect2:
	var inv := get_viewport().get_canvas_transform().affine_inverse()
	return inv * Rect2(Vector2.ZERO, get_viewport_rect().size)


# ═══════════════════════════════════════════════════════════
# 쓰러짐 · 다시 · 승리
# ═══════════════════════════════════════════════════════════

func _on_eska_died() -> void:
	deaths += 1
	hud.banner("쓰러졌다", "입구에서 다시 일어선다", RESPAWN_DELAY + 0.4)
	await get_tree().create_timer(RESPAWN_DELAY, true, false, true).timeout
	if not is_instance_valid(eska):
		return
	_reset_fight()
	eska.respawn(respawn_at)
	eska.belt.refill()


## 처음부터: 남은 칼빛을 거두고 검성을 새로 세움 (체력 가득·1막), 장막을 걷음
func _reset_fight() -> void:
	for n: Node in get_tree().get_nodes_in_group(EKenseiFx.GROUP):
		n.queue_free()
	for n: Node in get_children():
		if n is EKenseiFx.Sheath:
			n.queue_free()
	if is_instance_valid(boss):
		boss.queue_free()
	hud.boss = null
	_spawn_boss()
	_curtain_on(false)
	fight = F.WAIT
	_wind_k = 1.0
	Music.play("shingye", 1.0)
	cam.set("focus_w", 0.0)
	_cine_t = 0.0


func _on_boss_died(_e: EEnemy) -> void:
	fight = F.WON
	_cine(boss.global_position + Vector2(0, -34), 1.0, 0.7, EKensei.DEFEAT_T + 0.6)
	eska.invuln = 999.0
	_curtain_on(false)
	_wind_k = 0.6
	Music.play("", 1.5)
	await get_tree().create_timer(EKensei.DEFEAT_T - 0.4, true, false, true).timeout
	Music.jingle("jingle_chapter")
	hud.banner("검을 거두다", "검성을 넘었다", 2.4)
	await get_tree().create_timer(2.2, true, false, true).timeout
	eska.controls_locked = true
	touch.release_all()
	touch.visible = false
	var v := Victory.new()
	var secs := int(_clock)
	v.stats = [["걸린 시간", "%d분 %02d초" % [secs / 60, secs % 60]], ["쓰러짐", "%d번" % deaths], ["맞음", "%d번" % hits_taken]]
	v.chosen.connect(_on_victory_chosen)
	hud.get_parent().add_child(v)


func _on_victory_chosen(what: String) -> void:
	Fx.reset()
	match what:
		"retry":
			get_tree().reload_current_scene()
		"arena":
			get_tree().change_scene_to_file("res://proto/eska/eska_arena.tscn")
		_:
			GameState.go_title()


# ─── 시험 실행기 eval용 ──────────────────────────────────

## 만남 연출을 건너뛰고 바로 싸움 (에스카를 x에 둠)
func skip_intro(x := 520.0) -> String:
	_first = false
	eska.global_position = Vector2(x, FLOOR)
	eska.velocity = Vector2.ZERO
	_open_fight()
	_intro_t = INTRO_T
	_tick_intro()
	return boss.info()


func boss_info() -> String:
	return boss.info() if is_instance_valid(boss) else "none"


## 검성 체력을 비율로 (막 전환 시험)
func boss_hpf(f: float) -> String:
	boss.hp = int(float(boss.max_hp) * f)
	return boss.info()


func move(id: String) -> String:
	boss.start_move(id)
	return boss.info()


func fight_state() -> String:
	return "fight=%s deaths=%d hits=%d clock=%.1f eska_hp=%d eska_x=%d" % [F.keys()[fight], deaths, hits_taken, _clock, eska.hp, int(eska.global_position.x)]


# ═══════════════════════════════════════════════════════════
# 배경
# ═══════════════════════════════════════════════════════════

func _backdrop() -> void:
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -10
	add_child(sky_layer)
	sky_layer.add_child(NightSky.new())
	for spec: Array in [[0.06, 0, -9], [0.14, 1, -8]]:
		var px := Parallax2D.new()
		px.scroll_scale = Vector2(float(spec[0]), float(spec[0]) * 0.4)
		px.z_index = int(spec[2])
		add_child(px)
		var m := Mountains.new()
		m.layer = int(spec[1])
		m.width = W
		m.floor_y = FLOOR
		px.add_child(m)
	for spec: Array in [[0.32, 0, -7], [0.55, 1, -6]]:
		var px := Parallax2D.new()
		px.scroll_scale = Vector2(float(spec[0]), float(spec[0]) * 0.5)
		px.z_index = int(spec[2])
		add_child(px)
		var b := Bamboo.new()
		b.layer = int(spec[1])
		b.width = W
		b.floor_y = FLOOR
		px.add_child(b)
	var wall := Wall.new()
	wall.width = W
	wall.floor_y = FLOOR
	wall.z_index = -4
	add_child(wall)
	var ground := Ground.new()
	ground.width = W
	ground.floor_y = FLOOR
	ground.z_index = -2
	add_child(ground)
	var gate := Gate.new()
	gate.position = Vector2(GATE_X, FLOOR)
	gate.z_index = -1
	add_child(gate)
	var drift := EKenseiFx.Drift.new()
	drift.z_index = 9
	add_child(drift)
	var front_px := Parallax2D.new()
	front_px.scroll_scale = Vector2(1.3, 1.0)
	front_px.z_index = 12
	add_child(front_px)
	var front := Front.new()
	front.width = W
	front.floor_y = FLOOR
	front_px.add_child(front)
	# 처음부터 꽃잎이 화면에 흩어져 있게
	for i in 40:
		drift.spawn(Vector2(randf_range(0.0, W), randf_range(FLOOR - 220.0, FLOOR - 6.0)), Vector2(WIND, 0), randf_range(3.0, 9.0))


const INK := Color("#08070a")
const MOON := Color("#ebe3d6")
const HAZE := Color("#3a1418")


## 화면 고정 하늘: 먹빛 → 아래로 붉은 기운이 도는 밤 · 큰 달(뼈빛) · 달을 가로지르는 먹구름 몇 줄
class NightSky extends PDraw.Canvas:
	func _ready() -> void:
		get_viewport().size_changed.connect(queue_redraw)

	func _paint() -> void:
		var sz := get_viewport_rect().size
		var k := sz.y / 360.0
		pd.rect_grad(Rect2(Vector2.ZERO, sz), Color("#050406"), Color("#1a1315"))
		pd.rect_grad(Rect2(0, sz.y * 0.5, sz.x, sz.y * 0.5), Color(HAZE, 0.0), Color(HAZE, 0.35))
		var mc := Vector2(sz.x * 0.7, 84.0 * k)
		pd.glow(mc, 150.0 * k, Color(0.93, 0.88, 0.82, 0.08), 0.0)
		pd.glow(mc, 60.0 * k, Color(0.95, 0.9, 0.85, 0.16), 0.0)
		pd.draw_circle(mc, 31.0 * k, MOON)
		# 달의 바다 (얼굴처럼 보이지 않게 한쪽으로 몰아 흐리게)
		for spec: Array in [[Vector2(8, -6), 8.0], [Vector2(14, 6), 6.0], [Vector2(3, 3), 4.0], [Vector2(-10, 13), 3.5]]:
			pd.draw_circle(mc + (spec[0] as Vector2) * k, float(spec[1]) * k, Color("#e0d7c9"))
		pd.draw_circle(mc + Vector2(-9, -10) * k, 9.0 * k, Color("#f3eee5"))
		# 먹구름 띠
		for spec: Array in [[14.0, 150.0, 3.0], [-22.0, 70.0, 1.6]]:
			var y := mc.y + float(spec[0]) * k
			var hw := float(spec[1]) * k
			var th := float(spec[2]) * k
			var x0 := mc.x - hw * 0.6
			pd.draw_colored_polygon(PackedVector2Array([Vector2(x0 - hw * 0.5, y), Vector2(x0, y - th), Vector2(x0 + hw, y - th * 0.6), Vector2(x0 + hw * 1.3, y),
				Vector2(x0 + hw * 0.6, y + th * 0.8)]), Color("#0b090c", 0.92))
		# 희미한 별
		var rng := RandomNumberGenerator.new()
		rng.seed = 4242
		for i in 40:
			var p := Vector2(rng.randf() * sz.x, rng.randf() * sz.y * 0.5)
			if p.distance_to(mc) > 50.0 * k:
				pd.draw_rect(Rect2(p, Vector2(1, 1)), Color(MOON, rng.randf_range(0.15, 0.5)))


## 먼 산: 먹물 번지듯 겹친 봉우리 + 아래로 흐린 안개
class Mountains extends PDraw.Canvas:
	var layer := 0
	var width := 1120.0
	var floor_y := 300.0

	func _paint() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 900 + layer
		var c := Color("#120e12") if layer == 0 else Color("#0e0b0e")
		var base := floor_y - (150.0 if layer == 0 else 95.0)
		var pts := PackedVector2Array([Vector2(-300, floor_y + 300)])
		var x := -300.0
		while x < width + 600.0:
			var h := rng.randf_range(30.0, 110.0) * (1.0 if layer == 0 else 0.7)
			pts.append(Vector2(x, base - h * 0.3))
			pts.append(Vector2(x + rng.randf_range(30, 60), base - h))
			x += rng.randf_range(80.0, 150.0)
		pts.append(Vector2(x, floor_y + 300))
		pd.draw_colored_polygon(pts, c)
		pd.rect_grad(Rect2(-300, base - 20.0, width + 900.0, 120.0), Color(HAZE, 0.0), Color(HAZE, 0.22 if layer == 0 else 0.16))


## 대숲 실루엣: 몇 무더기로 모인 곧은 줄기 · 마디 · 위쪽에 바람 쪽으로 늘어진 잎 다발 (달빛 쪽 가장자리만 살짝 밝게)
class Bamboo extends PDraw.Canvas:
	var layer := 0
	var width := 1120.0
	var floor_y := 300.0

	func _paint() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 5150 + layer
		var c := Color("#130f13") if layer == 0 else Color("#0c090c")
		var rim := Color("#2e2629") if layer == 0 else Color("#251e21")
		var leaf := Color("#171216") if layer == 0 else Color("#0f0b0e")
		var scale_k := 1.0 if layer == 0 else 1.35
		var cx := -150.0 + rng.randf_range(0.0, 120.0)
		while cx < width + 500.0:
			var stalks := rng.randi_range(3, 7)
			for s in stalks:
				var x := cx + rng.randf_range(-34.0, 34.0)
				var w := rng.randf_range(2.4, 3.6) * scale_k
				var top := floor_y - rng.randf_range(300.0, 470.0)
				var bot := floor_y + 40.0
				var lean := rng.randf_range(-0.05, 0.03)
				var a := Vector2(x, bot)
				var b := Vector2(x + (bot - top) * lean, top)
				pd.line2(a, b, c, c, w, w * 0.6)
				pd.draw_line(a + Vector2(w * 0.35, 0), b + Vector2(w * 0.25, 0), rim, 0.7)
				var y := bot - rng.randf_range(10.0, 30.0)
				while y > top + 10.0:
					var f := (bot - y) / (bot - top)
					var p := a.lerp(b, f)
					pd.draw_line(p - Vector2(w * 0.7, 0), p + Vector2(w * 0.7, 0), rim, 1.0)
					y -= rng.randf_range(26.0, 38.0)
				# 잎 다발: 위쪽 마디마다 바람 쪽(왼쪽)으로 늘어진 가는 잎
				for k in rng.randi_range(3, 6):
					var f := rng.randf_range(0.62, 1.0)
					var p := a.lerp(b, f)
					for l in rng.randi_range(3, 6):
						var ang := rng.randf_range(-0.15, 0.55) # 바람 쪽(오른쪽)으로 늘어짐
						var len := rng.randf_range(9.0, 17.0) * scale_k
						var tip := p + Vector2.from_angle(ang) * len + Vector2(0, rng.randf_range(3, 9))
						var mid := (p + tip) * 0.5 + Vector2(0, -1.5)
						pd.draw_colored_polygon(PackedVector2Array([p, mid + Vector2(0, -1.4 * scale_k), tip, mid + Vector2(0, 1.0 * scale_k)]), leaf)
			cx += rng.randf_range(220.0, 380.0) * (1.0 if layer == 0 else 1.3)


## 안뜰 담: 흰 회벽은 바래 어둡고, 기와 지붕이 얹힌 낮은 담 (군데군데 무너짐) + 석등 둘
class Wall extends PDraw.Canvas:
	var width := 1120.0
	var floor_y := 300.0

	func _paint() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 77
		var x0 := GATE_X + 40.0
		var top := floor_y - 58.0
		var gaps := [[560.0, 610.0], [880.0, 905.0]]
		var x := x0
		while x < width:
			var seg_end := width
			for g: Array in gaps:
				if float(g[0]) > x and float(g[0]) < seg_end:
					seg_end = float(g[0])
			_wall(x, seg_end, top, rng)
			var nx := width
			for g: Array in gaps:
				if float(g[0]) == seg_end:
					nx = float(g[1])
			if nx <= seg_end:
				break
			# 무너진 자리: 돌무더기
			for i in 6:
				var p := Vector2(rng.randf_range(seg_end - 6.0, nx + 6.0), floor_y - rng.randf_range(0.0, 8.0))
				pd.draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 2), p + Vector2(-2, -3), p + Vector2(3, -2), p + Vector2(4, 2)]), Color("#2c2528"))
			x = nx
		for lx: float in [500.0, 1010.0]:
			_lantern(Vector2(lx, floor_y))

	func _wall(a: float, b: float, top: float, rng: RandomNumberGenerator) -> void:
		pd.rect_grad(Rect2(a, top, b - a, floor_y - top), Color("#4a4044"), Color("#2a2327"))
		pd.draw_rect(Rect2(a, top, b - a, 3.0), Color("#1a1518")) # 처마 그늘
		pd.draw_rect(Rect2(a, floor_y - 12.0, b - a, 12.0), Color("#1d181b"))
		pd.draw_rect(Rect2(a, floor_y - 13.0, b - a, 1.0), Color("#5a4e52"))
		var px := a + 8.0
		while px < b - 4.0:
			pd.draw_rect(Rect2(px, top + 3.0, 4.0, floor_y - top - 15.0), Color("#1d181b"))
			pd.draw_rect(Rect2(px + 3.0, top + 3.0, 1.0, floor_y - top - 15.0), Color("#5a4e52"))
			px += rng.randf_range(90.0, 130.0)
		# 회벽 얼룩·금
		for i in int((b - a) / 50.0):
			var p := Vector2(rng.randf_range(a, b), rng.randf_range(top + 10.0, floor_y - 16.0))
			pd.draw_line(p, p + Vector2(rng.randf_range(-6, 6), rng.randf_range(6, 14)), Color("#2a2326"), 1.0)
		# 기와 지붕: 처마가 살짝 들린 띠 + 기와 골
		var roof := PackedVector2Array([Vector2(a - 6.0, top + 2.0), Vector2(a - 2.0, top - 7.0), Vector2(b + 2.0, top - 7.0), Vector2(b + 6.0, top + 2.0)])
		pd.draw_colored_polygon(roof, Color("#0c0a0d"))
		pd.draw_line(Vector2(a - 2.0, top - 7.0), Vector2(b + 2.0, top - 7.0), Color("#3a3134"), 1.0)
		var tx := a
		while tx < b:
			pd.draw_line(Vector2(tx, top - 6.0), Vector2(tx - 1.0, top + 1.0), Color("#1d181b"), 1.0)
			tx += 5.0

	func _lantern(p: Vector2) -> void:
		var c := Color("#141014")
		pd.draw_rect(Rect2(p + Vector2(-8, -5), Vector2(16, 5)), c)
		pd.draw_rect(Rect2(p + Vector2(-3, -26), Vector2(6, 21)), c)
		pd.draw_rect(Rect2(p + Vector2(-7, -34), Vector2(14, 8)), c)
		pd.glow(p + Vector2(0, -30), 10.0, Color("#c0283a", 0.35), 0.0)
		pd.draw_rect(Rect2(p + Vector2(-3, -32), Vector2(6, 4)), Color("#d23a3a", 0.8))
		pd.draw_colored_polygon(PackedVector2Array([p + Vector2(-12, -34), p + Vector2(0, -42), p + Vector2(12, -34)]), c)
		pd.draw_line(p + Vector2(-12, -34), p + Vector2(0, -42), Color("#3a3134"), 1.0)
		pd.draw_circle(p + Vector2(0, -43), 1.6, c)


## 바닥: 박석 마당 (위쪽 띠에 돌 이음매, 달빛 테두리) + 흩어진 꽃잎 자국
class Ground extends PDraw.Canvas:
	var width := 1120.0
	var floor_y := 300.0

	func _paint() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 31
		pd.draw_rect(Rect2(-40, floor_y, width + 80.0, 400.0), Color("#100c0f"))
		pd.rect_grad(Rect2(-40, floor_y, width + 80.0, 30.0), Color("#1d171a"), Color("#100c0f"))
		pd.draw_rect(Rect2(-40, floor_y, width + 80.0, 1.0), Color("#5a4f52"))
		pd.draw_rect(Rect2(-40, floor_y + 1.0, width + 80.0, 1.0), Color("#2a2326"))
		for row in 2:
			var y := floor_y + 2.0 + float(row) * 9.0
			var x := -40.0 + float(row) * 14.0
			while x < width + 40.0:
				pd.draw_line(Vector2(x, y), Vector2(x, y + 8.0), Color("#080608"), 1.0)
				x += rng.randf_range(24.0, 38.0)
			pd.draw_line(Vector2(-40, y + 8.0), Vector2(width + 40.0, y + 8.0), Color("#0a0809"), 1.0)
		for i in 26:
			var p := Vector2(rng.randf_range(0.0, width), floor_y + rng.randf_range(1.0, 6.0))
			var c := Color("#9a1826", 0.5) if rng.randf() < 0.5 else Color("#d8cfc2", 0.3)
			pd.draw_rect(Rect2(p, Vector2(2, 1)), c)


## 무너진 문: 기둥 둘 + 부러진 윗보(한쪽은 땅에 떨어짐) + 금줄(흰 종이 술·붉은 끈)
class Gate extends PDraw.Canvas:
	func _paint() -> void:
		var c := Color("#120e11")
		var rim := Color("#3e3437")
		for sx in [-28.0, 28.0]:
			pd.draw_rect(Rect2(sx - 4.0, -118.0, 8.0, 118.0), c)
			pd.draw_line(Vector2(sx + 3.5, -118.0), Vector2(sx + 3.5, 0.0), rim, 1.0)
			pd.draw_rect(Rect2(sx - 6.0, -6.0, 12.0, 6.0), Color("#1a1518"))
		# 남은 윗보 (왼쪽 반) + 떨어진 오른쪽 반
		pd.draw_colored_polygon(PackedVector2Array([Vector2(-48, -126), Vector2(4, -124), Vector2(6, -118), Vector2(-44, -118)]), c)
		pd.draw_line(Vector2(-48, -126), Vector2(4, -124), rim, 1.0)
		pd.draw_rect(Rect2(-34, -110, 68, 5), c)
		pd.draw_colored_polygon(PackedVector2Array([Vector2(40, -2), Vector2(84, -16), Vector2(86, -10), Vector2(42, 3)]), c)
		pd.draw_line(Vector2(40, -2), Vector2(84, -16), rim, 1.0)
		# 금줄: 처진 줄 + 흰 종이 술 + 붉은 끈
		var rope := PackedVector2Array()
		for i in 13:
			var f := float(i) / 12.0
			rope.append(Vector2(lerpf(-24.0, 24.0, f), -92.0 + sin(f * PI) * 7.0))
		pd.draw_polyline(rope, Color("#6e6258"), 2.0)
		for f: float in [0.25, 0.5, 0.75]:
			var p := Vector2(lerpf(-24.0, 24.0, f), -92.0 + sin(f * PI) * 7.0)
			pd.draw_polyline(PackedVector2Array([p, p + Vector2(2, 3), p + Vector2(-1, 6), p + Vector2(2, 9), p + Vector2(-1, 12)]), Color("#e6ddcf"), 1.6)
		pd.draw_line(Vector2(-24, -92), Vector2(-26, -76), Color("#c81e2e"), 1.0)
		pd.draw_line(Vector2(24, -92), Vector2(27, -78), Color("#c81e2e"), 1.0)


## 전경: 화면 아래 마른 풀 실루엣 (바람 쪽으로 기욺)
class Front extends PDraw.Canvas:
	var width := 1120.0
	var floor_y := 300.0

	func _paint() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 808
		var c := Color("#050405")
		var x := -100.0
		while x < width * 1.3 + 200.0:
			if rng.randf() < 0.5:
				for i in rng.randi_range(4, 8):
					var bx := x + rng.randf_range(-10, 10)
					var h := rng.randf_range(14.0, 34.0)
					var tip := Vector2(bx + h * rng.randf_range(0.2, 0.5), floor_y + 26.0 - h)
					pd.draw_colored_polygon(PackedVector2Array([Vector2(bx - 1.5, floor_y + 40.0), tip, Vector2(bx + 1.5, floor_y + 40.0)]), c)
			x += rng.randf_range(60.0, 140.0)


## 싸움 중 입구를 막는 먹빛 장막 (붉은 실이 위로 흐름)
class Curtain extends PDraw.Canvas:
	var _t := 0.0
	var _a := 0.0
	var _closing := false

	func _ready() -> void:
		z_index = 3

	func close() -> void:
		_closing = true

	func _process(delta: float) -> void:
		_t += delta
		_a = move_toward(_a, 0.0 if _closing else 1.0, delta * 2.0)
		if _closing and _a <= 0.0:
			queue_free()
			return
		queue_redraw()

	func _paint() -> void:
		var a := _a
		# 먹빛 안개 막 (가운데가 짙음) + 바닥의 붉은 기운
		pd.rect_hgrad(Rect2(-24, -110, 24, 110), Color(INK, 0.0), Color(INK, 0.6 * a))
		pd.rect_hgrad(Rect2(0, -110, 24, 110), Color(INK, 0.6 * a), Color(INK, 0.0))
		pd.draw_set_transform(Vector2(0, -1), 0.0, Vector2(1.0, 0.25))
		pd.glow(Vector2.ZERO, 34.0, Color("#e0182f", 0.45 * a), 0.0)
		pd.draw_set_transform(Vector2.ZERO)
		# 위아래로 늘어진 붉은 실 (바람에 물결침)
		for i in 5:
			var x0 := (float(i) - 2.0) * 9.0
			var pts := PackedVector2Array()
			for k in 12:
				var f := float(k) / 11.0
				pts.append(Vector2(x0 + sin(_t * 2.0 + f * 5.0 + float(i)) * 2.0 * f, -96.0 + f * 96.0))
			pd.draw_polyline(pts, Color("#e0182f", (0.45 + 0.2 * sin(_t * 3.0 + float(i))) * a), 1.0)
		# 위로 흐르는 불티
		for i in 7:
			var x := (float(i) - 3.0) * 6.0 + sin(_t * 1.3 + float(i)) * 2.0
			var f := fmod(_t * 0.5 + float(i) * 0.37, 1.0)
			var y := -f * 100.0
			pd.line2(Vector2(x, y), Vector2(x, y - 5.0), Color("#ff6a5c", 0.0), Color("#ff6a5c", 0.8 * a * (1.0 - f)), 1.0, 0.6)
		# 줄에 매달린 흰 부적 셋 (희미하게 빛남)
		for i in 3:
			var x := (float(i) - 1.0) * 14.0
			var sway := sin(_t * 2.4 + float(i)) * 1.2
			pd.glow(Vector2(x + sway, -80.0), 7.0, Color("#ece4d6", 0.25 * a), 0.0)
			pd.draw_rect(Rect2(x - 2.0 + sway, -88.0, 4.0, 11.0), Color("#ece4d6", 0.9 * a))
			pd.draw_line(Vector2(x + sway, -86.0), Vector2(x + sway, -79.0), Color("#c81e2e", 0.9 * a), 1.0)


## 보스 체력바 아래 가는 버팀 막대 (뼈빛 — 무너지면 붉게 깜빡이며 다시 차오름)
class PoiseBar extends Control:
	var stage: EBossStage
	var _sig := ""
	var _t := 0.0

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta
		var vs := get_viewport_rect().size
		if size != vs:
			size = vs
		var b := stage.boss if is_instance_valid(stage) else null
		var sig := "none"
		if is_instance_valid(b) and stage.hud.boss == b and not b.is_dead():
			sig = "%d|%.2f" % [int(b.poise), b.break_t]
			if b.break_t > 0.0:
				sig += "|%.1f" % _t
		if sig != _sig:
			_sig = sig
			queue_redraw()

	func _draw() -> void:
		var b := stage.boss if is_instance_valid(stage) else null
		if not is_instance_valid(b) or stage.hud.boss != b or b.is_dead():
			return
		var w := minf(300.0, size.x * 0.46)
		var x := size.x * 0.5 - w * 0.5
		var y := 13.0 + 12.0
		if size.x < 520.0:
			w = size.x - 40.0
			x = 20.0
			y = 66.0 + 12.0
		draw_rect(Rect2(x - 1, y - 1, w + 2, 4), Color(0, 0, 0, 0.6))
		if b.break_t > 0.0:
			var k := 1.0 - b.break_t / b.break_time
			var blink := 0.6 + 0.4 * sin(_t * 18.0)
			draw_rect(Rect2(x, y, w * k, 2), Color(EKenseiFx.RED_HOT, blink))
		else:
			var f := clampf(b.poise / b.max_poise, 0.0, 1.0)
			draw_rect(Rect2(x, y, w * f, 2), Color(EKenseiFx.BONE, 0.85))


## 끝 화면: "검성을 넘었다" + 기록 + 버튼 셋 (튜토리얼 끝 화면과 같은 꼴, 색은 먹·뼈·붉은빛)
class Victory extends Control:
	signal chosen(what: String)
	var stats: Array = []
	var _t := 0.0
	var _font: Font
	var _buttons: Array[Button] = []

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		_font = get_theme_default_font()
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		add_child(box)
		for spec: Array in [["다시 겨루기", "retry"], ["훈련장으로", "arena"], ["타이틀로", "title"]]:
			var b := Button.new()
			b.text = String(spec[0])
			b.custom_minimum_size = Vector2(150, 26)
			b.add_theme_font_size_override("font_size", 13)
			b.add_theme_stylebox_override("normal", _style(Color(INK, 0.85), Color(EKenseiFx.BONE, 0.4)))
			b.add_theme_stylebox_override("hover", _style(Color("#2a1418", 0.9), Color(EKenseiFx.RED_HOT, 0.9)))
			b.add_theme_stylebox_override("focus", _style(Color("#2a1418", 0.9), Color(EKenseiFx.BONE, 1.0)))
			b.add_theme_stylebox_override("pressed", _style(Color(EKenseiFx.RED_DEEP, 0.8), Color(EKenseiFx.BONE, 1.0)))
			b.add_theme_color_override("font_color", EKenseiFx.BONE)
			b.add_theme_color_override("font_focus_color", Color.WHITE)
			b.add_theme_color_override("font_hover_color", Color.WHITE)
			var what := String(spec[1])
			b.pressed.connect(func() -> void:
				Sfx.play(&"ui_ok", -4.0)
				chosen.emit(what))
			box.add_child(b)
			_buttons.append(b)
		box.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(1.4)
		tw.tween_property(box, "modulate:a", 1.0, 0.4)
		tw.tween_callback(func() -> void: _buttons[0].grab_focus())
		resized.connect(func() -> void: box.position = Vector2(size.x * 0.5 - 75.0, size.y * 0.6))
		box.position = Vector2(get_viewport_rect().size.x * 0.5 - 75.0, get_viewport_rect().size.y * 0.6)

	func _style(bg: Color, border: Color) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = bg
		s.border_color = border
		s.set_border_width_all(1)
		s.set_corner_radius_all(3)
		return s

	func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("es_jump") or event.is_action_pressed("es_attack"):
			for b in _buttons:
				if b.has_focus():
					b.pressed.emit()
					get_viewport().set_input_as_handled()
					return

	func _process(delta: float) -> void:
		_t += delta
		var vs := get_viewport_rect().size
		if size != vs:
			size = vs
		if _t < 2.5:
			queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.01, 0.015, minf(_t / 0.6, 1.0) * 0.72))
		var c := Vector2(size.x * 0.5, size.y * 0.22)
		var inn := clampf(_t / 0.6, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - inn, 3.0)
		var title := "검성을 넘었다"
		var fs := 26
		var tw := _font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string_outline(_font, c + Vector2(-tw * 0.5, 0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(INK, inn))
		draw_string(_font, c + Vector2(-tw * 0.5, 0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(EKenseiFx.BONE, inn))
		var lw := (tw * 0.5 + 60.0) * e
		draw_line(c + Vector2(-lw, 12), c + Vector2(lw, 12), Color(EKenseiFx.RED, 0.8 * inn), 1.0)
		for i in stats.size():
			var k := clampf((_t - 0.6 - 0.18 * float(i)) / 0.25, 0.0, 1.0)
			if k <= 0.0:
				continue
			var y := c.y + 36.0 + 18.0 * float(i) + 6.0 * (1.0 - k)
			var nm := String(stats[i][0])
			var val := String(stats[i][1])
			var vw := _font.get_string_size(val, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			draw_string(_font, Vector2(c.x - 110.0, y), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(EKenseiFx.BONE, 0.7 * k))
			draw_string(_font, Vector2(c.x + 110.0 - vw, y), val, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, k))
			draw_line(Vector2(c.x - 110.0, y + 4), Vector2(c.x + 110.0, y + 4), Color(EKenseiFx.BONE, 0.15 * k), 1.0)
