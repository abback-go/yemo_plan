class_name EBossStage
extends EStage
## 검성 보스전 "달빛 폐정원": 달 아래 무너진 동방의 안뜰 — 대숲 실루엣, 기와 담, 석등, 바람에 날리는 꽃잎(먹·붉은빛·뼈흰).
## 왼쪽 입구에 가마솥(쉼터)과 무너진 문. 문을 지나 TRIGGER_X를 넘으면 싸움이 열리고 뒤로 먹빛 장막이 닫힌다.
## 쓰러지면 입구에서 다시 일어서고(물약 가득), 검성은 처음(체력 가득·1막)부터 다시 선다 — 문을 지나면 다시 시작.
## 이기면 끝 화면(다시 겨루기·훈련장·타이틀). 들어오는 길: 타이틀 메뉴 "에스카 보스전 (검성)" 또는 웹 주소 뒤 ?eska_boss
## 기준서: docs/eska/design.md 6장. 루프2(loop2_plan.md 6장): 등장 근접 연출 · 뼈흰+붉은 선 이름 자막(BossTitle) · 발도 예고 때 배경이 살짝 어두워짐(Dim)
##   · 입구 장막 = 먹빛 연기 + 부적 · 보스장 안내(hud.context_hints) · 연출 중 안내 숨김(hud.cinematic) · 터치 카메라 여유만큼 오른쪽 배경 연장.

const W := 1120.0
const FLOOR := 300.0
const GATE_X := 300.0 ## 무너진 문 (싸움 중엔 여기에 장막)
const TRIGGER_X := 380.0 ## 이 줄을 넘으면 싸움 시작
const BOSS_X := 860.0
const CAULDRON_X := 252.0 ## 가마솥 (loop4: 터치 방향키 밖 — 예전 84는 엄지 밑)
const RESPAWN := Vector2(300, FLOOR) ## 부활 자리 (문 아래, 가마솥 곁 — 방향키 밖)
const WIND := 46.0 ## 바람 세기 (꽃잎·머리칼·자락)
const INTRO_T := 3.2 ## (시험 호환) 처음 만남 연출을 건너뛸 때 쓰는 값
const INTRO_PAN := 1.1 ## 처음 만남: 카메라가 검성 쪽으로 다가가는 시간 (실제 시간)
const CLOSE_T := 0.8 ## 처음 만남: 얼굴 근접 (눈을 뜨고 바람이 몰아침)
const CLOSE_EYES := 0.22 ## 근접이 시작되고 이만큼 뒤 눈을 뜸
const CLOSE_ZOOM := 2.3 ## 근접 때 카메라 추가 확대 (얼굴이 화면을 채우게)
const TITLE_T := 2.2 ## 처음 만남 이름 자막 길이 — 자막이 끝나야 싸움이 열림 (검성은 그 전엔 움직이지 않음)
const RETRY_TITLE_T := 1.3 ## 다시 할 때 짧은 자막
const PHASE_TITLE_T := 2.2
const BREAK_TITLE_T := 1.2
const GUST_WIND := 3.4 ## 눈을 뜰 때 바람 배수
const CALM_WIND := 0.5 ## 다가갈 때 고요한 바람
const DIM_MAX := 0.3 ## 발도 예고 때 배경 어두움 최대 (먹빛 막의 진하기)
const CAM_MARGIN_DEFAULT := 240.0 ## 터치 카메라 여유 (EStage.cam_margin_touch가 없을 때)
const ART_SHAKE_PAD := 60.0 ## 흔들림·확대 펀치 여유 — 카메라 여유에 더해 오른쪽 배경을 더 그림
const ART_EXTRA_MIN := 300.0 ## 오른쪽 끝 너머로 그리는 배경 최소 폭
const HINTS: Array[String] = ["{es_up}+{es_skill} 단공: 비검·천검을 가른다", "물약을 열린 틈에 던지면 스며든다", "눈 감은 반격 자세엔 비명·속박"]
const FRAME_PULL := 0.85 ## 싸움 중 카메라를 둘 사이 가운데로 당기는 정도 (1 = 정가운데)

enum F { WAIT, INTRO, FIGHT, WON }
enum I { PAN, CLOSE, TITLE } ## 처음 만남 연출 단계

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
var _margin := CAM_MARGIN_DEFAULT ## 오른쪽 끝 너머로 더 그리는 배경 폭 (터치 카메라 여유)
var _cine_t := 0.0
var _cine_p := Vector2.ZERO
var _cine_w := 0.0
var _cine_zoom := 0.0
var _cine_rate := 2.5 ## 연출 카메라 확대가 따라가는 빠르기
var _intro_step := I.PAN
var _title: BossTitle
var _dim: Dim
var _cine_hold := false ## 연출 중 (막 전환 등) — 끝나면 안내를 다시 보임


func _build() -> void:
	stage_w = W
	var m: Variant = get("cam_margin_touch")
	_margin = float(m) if m != null else CAM_MARGIN_DEFAULT
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
	hud.set("context_hints", HINTS) # 코어가 안내 칸을 더함 (없으면 아무 일 없음)
	var layer := hud.get_parent()
	_poise_bar = PoiseBar.new()
	_poise_bar.stage = self
	layer.add_child(_poise_bar)
	_title = BossTitle.new()
	layer.add_child(_title)
	_dim = Dim.new()
	_dim.stage = self
	add_child(_dim)
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
			if _cine_hold and is_instance_valid(boss) and boss.st != EKensei.S.PHASE:
				_cine_hold = false
				_cinematic(false)
	_title.advance(real)
	_tick_cine(real)
	if eska.hp > _hp_seen: # 물약으로 차오른 체력 (신호 없이 오름) — 맞은 횟수를 셀 기준을 맞춤
		_hp_seen = eska.hp
	if closeup > 0.0 and is_instance_valid(boss):
		cam.set("focus_p", boss.global_position + Vector2(0, -28))
		cam.set("focus_w", 1.0)
		cam.set("zoom_extra", closeup)
	_tick_wind(delta)


## 연출 카메라: dur초(실제 시간) 동안 p를 w만큼 가운데로, zoom만큼 더 확대 — 끝나면 부드럽게 돌아옴 (rate = 확대 따라가는 빠르기)
func _cine(p: Vector2, w: float, zoom: float, dur: float, rate := 2.5) -> void:
	_cine_p = p
	_cine_w = w
	_cine_zoom = zoom
	_cine_t = dur
	_cine_rate = rate


## 연출 중: 화면 키 안내·시험 버튼 숨김 (코어 HUD가 cinematic을 읽음 — 없으면 아무 일 없음)
func _cinematic(on: bool) -> void:
	hud.set("cinematic", on)


func _tick_cine(real: float) -> void:
	if closeup > 0.0:
		return
	var z := float(cam.get("zoom_extra"))
	if _cine_t > 0.0:
		_cine_t -= real
		var fp := cam.get("focus_p") as Vector2
		cam.set("focus_p", fp.lerp(_cine_p, 1.0 - exp(-real * maxf(4.0, _cine_rate))))
		cam.set("focus_w", move_toward(float(cam.get("focus_w")), _cine_w, real * maxf(1.6, _cine_rate * 0.6)))
		cam.set("zoom_extra", lerpf(z, _cine_zoom, 1.0 - exp(-real * _cine_rate)))
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


## 문을 지남: 처음엔 긴 만남 연출(다가감 → 얼굴 근접 → 이름 자막), 다시 할 때는 짧은 자막만. 자막이 끝나야 싸움이 열린다
func _open_fight() -> void:
	fight = F.INTRO
	_intro_t = 0.0
	_intro_step = I.PAN
	_curtain_on(true)
	_cinematic(true)
	eska.controls_locked = true
	touch.release_all()
	touch.visible = false
	if _first:
		cam.set("focus_p", eska.global_position + Vector2(0, -70))
		_cine(boss.global_position + Vector2(-30, -46), 1.0, 0.55, INTRO_PAN + 0.4)
		_wind_k = CALM_WIND
		Music.play("", 0.8)
	else:
		_intro_step = I.TITLE
		boss.open_eyes()
		_show_boss("다시 마주 선다", RETRY_TITLE_T)


func _tick_intro() -> void:
	match _intro_step:
		I.PAN:
			if _intro_t >= INTRO_PAN:
				_intro_step = I.CLOSE
				# 얼굴 근접: 빠르게 당겨 머리를 화면 가운데로
				_cine(boss.global_position + Vector2(float(boss.facing) * 3.0, -46), 1.0, CLOSE_ZOOM, CLOSE_T, 9.0)
		I.CLOSE:
			if _intro_t >= INTRO_PAN + CLOSE_EYES and not boss._eyes_open:
				boss.open_eyes()
				_gust()
			if _intro_t >= INTRO_PAN + CLOSE_T:
				_intro_step = I.TITLE
				_wind_k = 1.2
				_cine(boss.global_position + Vector2(-40, -40), 1.0, 0.4, TITLE_T, 3.0)
				_show_boss("칼을 뽑은 것을 본 이는 없다", TITLE_T)
		I.TITLE:
			if not _title.busy():
				_begin_fight()


## 근접 중 눈을 뜨는 순간: 바람이 몰아쳐 머리칼·자락·꽃잎이 한쪽으로 쏠림
func _gust() -> void:
	_wind_k = GUST_WIND
	Fx.shake(0.25, 0.25)
	Sfx.play_pitch(&"kb_gust", 1.0, -3.0)
	var d := EKenseiFx.Drift.get_layer()
	if d != null:
		var r := _view_rect()
		for i in 26:
			d.spawn(Vector2(r.position.x + randf_range(-10.0, r.size.x * 0.6), randf_range(r.position.y, r.end.y)), Vector2(WIND * GUST_WIND * randf_range(1.2, 2.0), randf_range(-30, 30)), randf_range(1.2, 2.4))


## 싸움을 엶: 조작이 풀리고 검성이 움직이기 시작
func _begin_fight() -> void:
	fight = F.FIGHT
	_first = false
	_cinematic(false)
	eska.controls_locked = false
	touch.visible = true
	boss.begin()


func _show_boss(sub: String, dur: float) -> void:
	hud.boss = boss
	_title.show_title("검성", sub, dur)
	Music.play("shingye_tension", 0.6)
	Sfx.play_pitch(&"kb_sheath", 0.8, -2.0)


## 막 전환이 시작됨: 검성 쪽으로 살짝 당겨 확대 · 안내 숨김 (검성이 PHASE를 벗어나면 다시 보임)
func _on_phase_start() -> void:
	_cine((boss.global_position + eska.global_position) * 0.5 * 0.4 + boss.global_position * 0.6 + Vector2(0, -50), 0.9, 0.35, 2.4)
	_cinematic(true)
	_cine_hold = true


func _on_phase(_p: int) -> void:
	Music.play("boss", 0.4)
	_title.show_title("검성 · 발검", "칼집을 버렸다", PHASE_TITLE_T)
	_wind_k = 1.5


func _on_break(_e: EEnemy) -> void:
	_title.show_title("무너짐", "지금 — 대마법을 넣을 때", BREAK_TITLE_T, true)


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
	_cinematic(false)
	_cine_hold = false
	fight = F.WAIT
	_wind_k = 1.0
	Music.play("shingye", 1.0)
	cam.set("focus_w", 0.0)
	_cine_t = 0.0


func _on_boss_died(_e: EEnemy) -> void:
	fight = F.WON
	_cinematic(true)
	_cine(boss.global_position + Vector2(0, -34), 1.0, 0.7, EKensei.DEFEAT_T + 0.6)
	eska.invuln = 999.0
	_curtain_on(false)
	_wind_k = 0.6
	Music.play("", 1.5)
	await get_tree().create_timer(EKensei.DEFEAT_T - 0.4, true, false, true).timeout
	Music.jingle("jingle_chapter")
	_title.show_title("검을 거두다", "검성을 넘었다", 2.4)
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
	_title.show_title("", "", 0.0)
	_intro_t = INTRO_T
	_begin_fight()
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

## 배경: 오른쪽 끝(W) 너머로 (터치 카메라 여유 + 흔들림, 최소 ART_EXTRA_MIN) 더 그린다 (터치 카메라 여유로 그쪽이 보일 때 빈 곳이 아니라 그림이 보이게)
func _backdrop() -> void:
	var art_w := W + maxf(_margin + ART_SHAKE_PAD, ART_EXTRA_MIN)
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
		m.width = art_w
		m.floor_y = FLOOR
		_place_static(px, m, Rect2(-320, FLOOR - 300.0, art_w + 1100.0, 620.0), 0)
	for spec: Array in [[0.32, 0, -7], [0.55, 1, -6]]:
		var px := Parallax2D.new()
		px.scroll_scale = Vector2(float(spec[0]), float(spec[0]) * 0.5)
		px.z_index = int(spec[2])
		add_child(px)
		var b := Bamboo.new()
		b.layer = int(spec[1])
		b.width = art_w
		b.floor_y = FLOOR
		_place_static(px, b, Rect2(-260, FLOOR - 500.0, art_w + 900.0, 560.0), 0)
	var wall := Wall.new()
	wall.width = art_w
	wall.floor_y = FLOOR
	_place_static(self, wall, Rect2(GATE_X, FLOOR - 80.0, art_w - GATE_X + 20.0, 82.0), -4)
	var ground := Ground.new()
	ground.width = art_w
	ground.floor_y = FLOOR
	_place_static(self, ground, Rect2(-40, FLOOR, art_w + 80.0, 400.0), -2)
	var gate := Gate.new()
	_place_static(self, gate, Rect2(GATE_X - 56.0, FLOOR - 134.0, 150.0, 140.0), -1, Vector2(GATE_X, FLOOR))
	var drift := EKenseiFx.Drift.new()
	drift.z_index = 9
	add_child(drift)
	var front_px := Parallax2D.new()
	front_px.scroll_scale = Vector2(1.3, 1.0)
	front_px.z_index = 12
	add_child(front_px)
	var front := Front.new()
	front.width = art_w
	front.floor_y = FLOOR
	_place_static(front_px, front, Rect2(-130, FLOOR - 20.0, art_w * 1.3 + 400.0, 62.0), 0)
	# 처음부터 꽃잎이 화면에 흩어져 있게
	for i in 40:
		drift.spawn(Vector2(randf_range(0.0, W), randf_range(FLOOR - 220.0, FLOOR - 6.0)), Vector2(WIND, 0), randf_range(3.0, 9.0))


## 정지 배경 조각 c(그리기 명령 수천 개)를 parent에 붙인다. 굽기가 켜져 있으면(시험 실행기 "bake_bg"를 따름 — 기본 켬)
## r(부모 좌표, at = c의 자리) 크기 텍스처에 한 번 그려 Sprite2D 한 장으로 보인다 — 겉모습은 같고 매 프레임 도형 수가 크게 준다 (loop4 5장).
## 투명 바탕에 섞어 그린 결과는 알파가 곱해진 색이라 Sprite는 PREMULT_ALPHA로 그린다 (world/themes/backdrop_kit.gd _bake와 같은 방식)
func _place_static(parent: Node, c: CanvasItem, r: Rect2, z: int, at := Vector2.ZERO) -> void:
	if not BACKDROP_KIT.BAKE:
		c.position = at
		c.z_index = z
		parent.add_child(c)
		return
	var org := r.position.floor()
	var vp := SubViewport.new()
	vp.size = Vector2i((r.end - org).ceil())
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	c.position = at - org
	vp.add_child(c)
	parent.add_child(vp)
	var spr := Sprite2D.new()
	spr.centered = false
	spr.position = org
	spr.texture = vp.get_texture()
	spr.z_index = z
	if _premult == null:
		_premult = CanvasItemMaterial.new()
		_premult.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	spr.material = _premult
	parent.add_child(spr)


const BACKDROP_KIT := preload("res://world/themes/backdrop_kit.gd") ## 굽기 켜고 끄기(BAKE)를 같이 씀
static var _premult: CanvasItemMaterial
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
		# 줄 끝 붉은 매듭 (세로 붉은 선은 천검 예고와 헷갈려 쓰지 않음)
		for sx: float in [-24.0, 24.0]:
			pd.draw_circle(Vector2(sx, -92), 1.8, Color("#c81e2e"))
			pd.draw_colored_polygon(PackedVector2Array([Vector2(sx - 2.5, -88), Vector2(sx, -91), Vector2(sx + 2.5, -88), Vector2(sx, -86)]), Color("#8a1420"))


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


## 싸움 중 입구를 막는 장막: 피어오르며 소용돌이치는 먹빛 연기 + 금줄에 매달려 펄럭이는 흰 부적, 연기 속을 맴도는 부적 둘
## (붉은 세로선은 쓰지 않는다 — 천검 예고와 겹쳐 보임. 붉은빛은 부적의 작은 인장만)
class Curtain extends PDraw.Canvas:
	const H := 112.0 ## 장막 높이
	const HALF := 26.0 ## 장막 반폭
	const PUFFS := 16 ## 연기 덩이 수
	const TAGS := 4 ## 금줄에 매달린 부적 수
	const ROPE_Y := -100.0
	const PAPER := Color("#e9e1d2")
	const SEAL := Color("#b8182a")
	const SMOKE := Color("#09070a")
	const SMOKE_MID := Color("#2b2429") ## 연기 몸 (어두운 배경에서도 덩이가 읽히게 잿빛을 섞음)
	const SMOKE_HI := Color("#6d6266") ## 달빛 받은 연기 가장자리
	const ROPE := Color("#6e6258")
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
		var w := EKenseiFx.wind.x / WIND
		# 바닥에 고인 먹빛
		pd.draw_set_transform(Vector2(0, -2), 0.0, Vector2(1.0, 0.3))
		pd.glow(Vector2.ZERO, 40.0, Color(SMOKE, 0.8 * a), 0.0)
		pd.draw_set_transform(Vector2.ZERO)
		# 먹빛 연기: 아래에서 피어올라 커지며 옅어지는 덩이 (바람 쪽으로 살짝 쏠림)
		for i in PUFFS:
			var f := fmod(_t * 0.32 + float(i) / float(PUFFS), 1.0)
			var x := sin(_t * 0.8 + float(i) * 1.7) * (6.0 + 10.0 * f) + w * 6.0 * f
			var p := Vector2(x, -4.0 - f * H)
			var r := 10.0 + 12.0 * f
			var al := sin(f * PI) * a
			pd.glow(p + Vector2(-r * 0.25, -r * 0.3), r * 0.9, Color(SMOKE_HI, 0.3 * al), 0.0) # 달빛 받은 연기 윗면
			pd.glow(p, r, Color(SMOKE_MID, 0.7 * al), 0.3 * al)
			pd.glow(p + Vector2(r * 0.2, r * 0.2), r * 0.6, Color(SMOKE, 0.8 * al), 0.0) # 아래쪽 짙은 먹
		# 연기 결: 위로 말려 올라가는 가는 잿빛 줄 몇 가닥
		for i in 4:
			var f := fmod(_t * 0.45 + float(i) * 0.25, 1.0)
			var wisp := PackedVector2Array()
			for k in 6:
				var g := float(k) / 5.0
				wisp.append(Vector2(sin(_t * 1.4 + float(i) * 2.0 + g * 3.0) * (5.0 + 6.0 * g) + w * 4.0 * g, -10.0 - (f * 0.6 + g * 0.35) * H))
			pd.draw_polyline(wisp, Color(SMOKE_HI, 0.35 * sin(f * PI) * a), 1.0)
		# 금줄 (가로로 처진 새끼줄)
		var rope := PackedVector2Array()
		for k in 9:
			var f := float(k) / 8.0
			rope.append(Vector2(lerpf(-HALF, HALF, f), ROPE_Y + sin(f * PI) * 6.0 + sin(_t * 1.8 + f * 4.0) * 0.8))
		pd.draw_polyline(rope, Color(ROPE, 0.9 * a), 2.0)
		# 매달린 부적: 바람에 펄럭이며 흔들림
		for i in TAGS:
			var f := (float(i) + 0.5) / float(TAGS)
			var top := Vector2(lerpf(-HALF, HALF, f), ROPE_Y + sin(f * PI) * 6.0 + 1.0)
			var ang := sin(_t * 2.6 + float(i) * 1.3) * 0.25 - w * 0.18
			_talisman(top, ang, 1.0, a)
		# 연기 속을 맴도는 부적 둘
		for i in 2:
			var an := _t * (0.9 + 0.2 * float(i)) + float(i) * PI
			var c := Vector2(cos(an) * 14.0, -40.0 - 26.0 * float(i) + sin(an * 1.3) * 10.0)
			_talisman(c + Vector2(0, -6), an * 1.6, 0.8, a * (0.6 + 0.4 * sin(an)))

	## 흰 부적 한 장: 위 끝 top에서 ang만큼 기울어 매달림 (붉은 인장 + 먹 획 몇 개)
	func _talisman(top: Vector2, ang: float, sc: float, a: float) -> void:
		if a <= 0.02:
			return
		var d := Vector2(-sin(ang), cos(ang))
		var n := d.orthogonal()
		var l := 13.0 * sc
		var hw := 2.6 * sc
		var flap := sin(_t * 9.0 + top.x) * 0.8 * sc # 끝단이 펄럭임
		pd.glow(top + d * l * 0.5, 7.0 * sc, Color(PAPER, 0.18 * a), 0.0)
		pd.draw_colored_polygon(PackedVector2Array([top + n * hw, top - n * hw, top + d * l - n * (hw + flap), top + d * l + n * (hw - flap)]), Color(PAPER, 0.92 * a))
		pd.draw_circle(top + d * l * 0.3, 1.3 * sc, Color(SEAL, 0.95 * a))
		for k in 3:
			var q := top + d * l * (0.5 + 0.13 * float(k))
			pd.draw_line(q - n * hw * 0.6, q + n * hw * 0.5, Color(INK, 0.8 * a), 0.7)


## 발도 예고 때 배경을 살짝 어둡게: 땅·담·하늘 위, 검성·에스카·이펙트 아래 (z -1) 먹빛 막
class Dim extends Node2D:
	var stage: EBossStage
	var _shown := 0.0

	func _ready() -> void:
		z_index = -1

	func _process(_delta: float) -> void:
		var k := 0.0
		if is_instance_valid(stage) and is_instance_valid(stage.boss) and not stage.boss.is_dead():
			k = stage.boss.dim_k()
		if absf(k - _shown) > 0.002 or (k == 0.0 and _shown != 0.0):
			_shown = k
			queue_redraw()

	func _draw() -> void:
		if _shown <= 0.0:
			return
		draw_rect(stage._view_rect().grow(40.0), Color(INK, DIM_MAX * _shown))


## 이름 자막: 뼈흰 큰 글자 + 가운데에서 양옆으로 그어지는 붉은 가로선 + 아래 작은 글 (보랏빛 알림 대신 검성 전용)
## 시간은 장면이 advance(실제 시간)로 흘려 준다 — 멈춤·느려짐 연출에 흔들리지 않게
class BossTitle extends Control:
	const BONE := Color("#ece4d6")
	const BONE_DIM := Color("#a3978a")
	const LINE := Color("#d01c2c")
	const LINE_HOT := Color("#ff6a5c")
	const IN_T := 0.35
	const OUT_T := 0.4
	const LINE_STEPS := 12 ## 붉은 선이 끝으로 옅어지는 단계
	var _name := ""
	var _sub := ""
	var _t := 0.0
	var _dur := 0.0
	var _small := false
	var _font: Font

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_font = get_theme_default_font()

	## 자막을 띄움 (small = 무너짐 같은 짧은 알림 — 글자가 작음)
	func show_title(title: String, sub: String, dur: float, small := false) -> void:
		_name = title
		_sub = sub
		_t = 0.0
		_dur = dur
		_small = small
		queue_redraw()

	## 아직 자막이 떠 있나
	func busy() -> bool:
		return _name != "" and _t < _dur

	func advance(real: float) -> void:
		var vs := get_viewport_rect().size
		if size != vs:
			size = vs
		if _t < _dur:
			_t += real
			queue_redraw()

	func _draw() -> void:
		if _name == "" or _t >= _dur:
			return
		var inn := clampf(_t / IN_T, 0.0, 1.0)
		var out := clampf((_dur - _t) / OUT_T, 0.0, 1.0)
		var a := minf(inn, out)
		var e := 1.0 - pow(1.0 - inn, 3.0)
		var fs := 20 if _small else 30
		var c := Vector2(size.x * 0.5, size.y * (0.3 if _small else 0.34))
		var tw := _font.get_string_size(_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		# 글자 뒤 옅은 먹빛 띠 (어느 배경에서도 읽히게)
		var band_h := 34.0 if _small else 50.0
		var bw := tw * 0.5 + 120.0
		_hband(Rect2(c.x - bw, c.y - float(fs) * 0.95, bw * 2.0, band_h), 0.5 * a)
		# 이름: 살짝 크게 시작해 제자리로 (뼈흰, 먹 테두리)
		var sc := 1.12 - 0.12 * e
		draw_set_transform(c, 0.0, Vector2(sc, sc))
		draw_string_outline(_font, Vector2(-tw * 0.5, 0), _name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(INK, 0.9 * a))
		draw_string(_font, Vector2(-tw * 0.5, 0), _name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(BONE.lerp(Color.WHITE, 1.0 - e), a))
		draw_set_transform(Vector2.ZERO)
		# 붉은 가로선: 가운데에서 양옆으로 그어짐 (가운데가 진하고 끝으로 옅어짐)
		var ly := c.y + (7.0 if _small else 10.0)
		var lw := (tw * 0.5 + (50.0 if _small else 80.0)) * e
		for i in LINE_STEPS:
			var f0 := float(i) / float(LINE_STEPS)
			var f1 := float(i + 1) / float(LINE_STEPS)
			var col := Color(LINE, (0.95 - 0.75 * f0) * a)
			draw_line(Vector2(c.x + lw * f0, ly), Vector2(c.x + lw * f1, ly), col, 1.0)
			draw_line(Vector2(c.x - lw * f0, ly), Vector2(c.x - lw * f1, ly), col, 1.0)
		draw_rect(Rect2(c.x - 2.0, ly - 1.0, 4.0, 2.0), Color(LINE_HOT, a))
		if _sub != "":
			var sfs := 11 if _small else 12
			var sw := _font.get_string_size(_sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sfs).x
			var k := clampf((_t - 0.15) / IN_T, 0.0, 1.0) * out
			var sp := Vector2(c.x - sw * 0.5, ly + float(sfs) + 5.0)
			draw_string_outline(_font, sp, _sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sfs, 3, Color(0, 0, 0, 0.7 * k))
			draw_string(_font, sp, _sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sfs, Color(BONE_DIM, k))

	## 가운데가 짙고 양옆으로 옅어지는 가로 띠
	func _hband(r: Rect2, al: float) -> void:
		var half := r.size.x * 0.5
		var n := 10
		var w := half / float(n)
		for i in n:
			var f := float(i) / float(n)
			var c := Color(INK, al * (1.0 - f) * (1.0 - f))
			draw_rect(Rect2(r.position.x + half + w * float(i), r.position.y, w + 0.5, r.size.y), c)
			draw_rect(Rect2(r.position.x + half - w * float(i + 1), r.position.y, w + 0.5, r.size.y), c)


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
