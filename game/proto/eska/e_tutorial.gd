extends EStage
## 에스카 튜토리얼 "종언의 문턱" (기획: docs/eska/tutorial.md).
## 가로 4500px 한 줄 길: 깨어남 → 턱(점프·이단점프) → 장막·공허 틈(순간이동) → 허수아비(연격·천열)
## → 등불 망령(단공) → 사냥개(피하기·봉공) → 검은 거상(종언참) → 끝 화면.
## 진행은 단계(STEPS) 하나씩: _enter_이름()으로 시작하고 _tick_이름()이 true를 돌려주면 다음 단계로.
## 들어오는 길: 타이틀 메뉴 "에스카 튜토리얼" 또는 웹 주소 뒤 ?eska_tut

const W := 4500.0
const FLOOR := 300.0
const PIT_X := 1500.0
const PIT_W := 250.0
const HINT_AFTER := 3.0 ## 같은 자리에서 이만큼 머물면 안내 칸을 다시 흔든다

const STEPS := ["wake", "move", "jump", "double", "blink", "gap", "combo", "cheonyeol", "dangong", "bonggong", "finale", "end"]

var tut: ETutHud
var gates := {} ## 이름 → ETutProps.Gate
var lanterns: Array[ETutProps.Lantern] = []
var dummies: Array[PDummy] = []
var foe: EEnemy ## 지금 구간의 적
var boss: EColossus

var _step := -1
var _st := 0.0 ## 단계 안 시간
var _sub := 0 ## 단계 안 작은 순서
var _idle := 0.0 ## 안내 다시 흔들기용 머문 시간
var _last_x := 0.0
var _clock := 0.0
var _deaths := 0
var _hits_taken := 0
var _best_combo := 0
var _hp_seen := EEska.MAX_HP
var _real_ms := 0


# ═══════════════════════════════════════════════════════════
# 만들기
# ═══════════════════════════════════════════════════════════

func _build() -> void:
	stage_w = W
	floor_y = FLOOR
	cam_top = FLOOR - 520.0
	respawn_at = Vector2(110, FLOOR)
	music = "temple_dark"
	EScenery.build(self, W, FLOOR)
	# 바닥 (공허 틈에서 끊김) + 양 끝 벽
	solid(Rect2(-40, FLOOR, PIT_X + 40, 160))
	solid(Rect2(PIT_X + PIT_W, FLOOR, W - PIT_X - PIT_W + 40, 160))
	solid(Rect2(-40, FLOOR - 500, 56, 620))
	solid(Rect2(W - 16, FLOOR - 500, 56, 620))
	var pit := ETutProps.Pit.new()
	pit.w = PIT_W
	pit.position = Vector2(PIT_X, FLOOR)
	add_child(pit)
	# 턱: 낮은 턱(34) → 높은 턱(66, 이단점프로만)
	_block(Rect2(620, FLOOR - 34, 140, 34))
	_block(Rect2(900, FLOOR - 66, 260, 66))
	# 장막
	var veil := ETutProps.Veil.new()
	veil.position = Vector2(1320, FLOOR)
	add_child(veil)
	# 봉인 문: 허수아비 끝 · 망령 끝 · 사냥개 끝 (구간에 들어서면 뒤도 닫힘)
	for spec: Array in [["dummies", 2560.0], ["caster", 3180.0], ["runner", 3800.0]]:
		var g := ETutProps.Gate.new()
		g.position = Vector2(float(spec[1]), FLOOR)
		add_child(g)
		gates[spec[0]] = g
	# 확인점 등불
	for x: float in [110.0, 560.0, 1220.0, 1830.0, 2620.0, 3240.0, 3860.0]:
		var l := ETutProps.Lantern.new()
		l.position = Vector2(x, FLOOR)
		add_child(l)
		lanterns.append(l)
	# 허수아비: 연격용 하나 + 천열용 셋
	for x: float in [2010.0, 2290.0, 2350.0, 2420.0]:
		var d := PDummy.new()
		d.setup("small")
		d.position = Vector2(x, FLOOR)
		add_child(d)
		dummies.append(d)


func _block(r: Rect2) -> void:
	var b := ETutProps.Ledge.new()
	b.rect = r
	add_child(b)


func _start() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 41
	add_child(layer)
	tut = ETutHud.new()
	tut.touch = touch
	layer.add_child(tut)
	hud.show_keys = false
	eska.hurt_taken.connect(_on_hurt)
	lanterns[0].light()
	_next()


# ═══════════════════════════════════════════════════════════
# 진행
# ═══════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	super._process(delta)
	# 단계 시계는 실제 시간 (느려짐·멈춤 연출 중에도 대사·순서가 제 속도로)
	var now := Fx.now_ms()
	var real := minf(float(now - _real_ms) * 0.001, 0.1) if _real_ms > 0 else delta
	_real_ms = now
	if _step < 0 or _step >= STEPS.size():
		return
	_st += real
	if STEPS[_step] != "end":
		_clock += real
	_best_combo = maxi(_best_combo, eska.hit_count)
	_track_idle(delta)
	_check_lanterns()
	_check_fall()
	if call("_tick_" + STEPS[_step]):
		_next()


func _next() -> void:
	_step += 1
	_st = 0.0
	_sub = 0
	_idle = 0.0
	if _step < STEPS.size():
		call("_enter_" + STEPS[_step])


## 거의 같은 자리에 머문 시간 (헤매는지 보기)
func _track_idle(delta: float) -> void:
	if absf(eska.global_position.x - _last_x) > 24.0:
		_last_x = eska.global_position.x
		_idle = 0.0
	else:
		_idle += delta
	if _idle > HINT_AFTER:
		_idle = 0.0
		tut.nudge()


func _check_lanterns() -> void:
	for i in lanterns.size():
		var l := lanterns[i]
		if not l.lit and eska.global_position.x > l.global_position.x - 8.0 and eska.is_on_floor():
			l.light()
			respawn_at = Vector2(l.global_position.x, FLOOR)


## 공허 틈에 떨어지면: 피해 없이 바로 앞 확인점으로 되돌림
func _check_fall() -> void:
	if eska.global_position.y > FLOOR + 110.0 and not eska.is_dead():
		_deaths += 1
		Fx.flash(Color(0.6, 0.2, 1.0, 0.3), 0.2)
		eska.respawn(respawn_at)
		tut.say("공허는 마녀를 삼키지 못한다.")


func _on_hurt(hp: int) -> void:
	if hp < _hp_seen:
		_hits_taken += 1
	_hp_seen = hp


func _on_eska_died() -> void:
	_deaths += 1
	super._on_eska_died()


func _on_floor_at(x0: float, x1: float, top: float) -> bool:
	var p := eska.global_position
	return eska.is_on_floor() and p.x >= x0 and p.x <= x1 and p.y <= top + 2.0


# ═══════════════════════════════════════════════════════════
# 단계들 (_enter_* 시작 · _tick_* 끝났으면 true)
# ═══════════════════════════════════════════════════════════

func _enter_wake() -> void:
	_cutscene(true)
	eska.art.visible = false
	tut.fade_to(0.0, 1.6)


func _tick_wake() -> bool:
	if _sub == 0 and _st > 0.6:
		_sub = 1
		tut.chapter("종언의 문턱", "에스카 · 종언의 마녀")
	if _sub == 1 and _st > 1.4:
		_sub = 2
		eska.art.visible = true
		eska.respawn(eska.global_position) # 공간 틈에서 나타남
	if _sub == 2 and _st > 3.4:
		_sub = 3
		tut.say("……봉인이 풀렸다. 다시, 걸어 볼까.")
	if _st > 4.6:
		_cutscene(false)
		return true
	return false


func _enter_move() -> void:
	tut.prompt(["es_left", "es_right"], "미끄러지듯 이동")


func _tick_move() -> bool:
	if eska.global_position.x > 380.0:
		tut.done()
		return true
	return false


func _enter_jump() -> void:
	pass


func _tick_jump() -> bool:
	if _sub == 0 and eska.global_position.x > 520.0:
		_sub = 1
		tut.prompt(["es_jump"], "점프")
	if _sub == 1 and _on_floor_at(620.0, 760.0, FLOOR - 34.0):
		tut.done()
		return true
	return false


func _enter_double() -> void:
	pass


func _tick_double() -> bool:
	if _sub == 0 and eska.global_position.x > 800.0:
		_sub = 1
		tut.say("높다. 허공을 한 번 더 딛는다.")
		tut.prompt(["es_jump", "공중에서 한 번 더", "es_jump"], "이단점프")
	if _sub == 1 and _on_floor_at(900.0, 1160.0, FLOOR - 66.0):
		tut.done()
		return true
	return false


func _enter_blink() -> void:
	pass


func _tick_blink() -> bool:
	if _sub == 0 and eska.global_position.x > 1180.0:
		_sub = 1
		tut.say("장막이다. 걸어서는 못 지난다.")
		tut.prompt(["es_blink"], "순간이동 — 장막을 꿰뚫는다")
	if eska.global_position.x > 1340.0:
		tut.done()
		return true
	return false


func _enter_gap() -> void:
	pass


func _tick_gap() -> bool:
	if _sub == 0 and eska.global_position.x > 1400.0:
		_sub = 1
		tut.prompt(["es_jump", "→", "es_jump", "→", "es_blink"], "이어서 건너기")
	if _on_floor_at(PIT_X + PIT_W, W, FLOOR):
		tut.done()
		return true
	return false


func _enter_combo() -> void:
	pass


func _tick_combo() -> bool:
	if _sub == 0 and eska.global_position.x > 1900.0:
		_sub = 1
		tut.say("허수아비. 손끝 하나면 충분하다.")
		tut.prompt(["es_attack", "×4"], "연격 — 끝까지 이어 베기")
	if _sub == 1 and eska.st == EEska.St.ATTACK and eska.combo_i == 3 and eska.hit_count >= 4:
		tut.done()
		return true
	return false


func _enter_cheonyeol() -> void:
	_sub = 0


func _tick_cheonyeol() -> bool:
	if _sub == 0 and _st > 1.2:
		_sub = 1
		_ready_skill("cheonyeol")
		tut.prompt(["es_skill"], "천열 — 앞의 공간을 통째로 벤다")
	if _sub == 1 and eska.st == EEska.St.CAST and eska.cast_kind == "cheonyeol":
		_sub = 2
		_st = 0.0
	if _sub == 2 and _st > 0.9:
		var hit := 0
		for d in dummies:
			if d._since_hit < 1.2:
				hit += 1
		if hit >= 2:
			tut.done()
			gates["dummies"].open()
			tut.say("길이 열렸다.")
			return true
		_sub = 1 # 너무 멀었다 — 다시
		tut.say("조금 더 다가가서.")
		tut.nudge()
	return false


func _enter_dangong() -> void:
	pass


func _tick_dangong() -> bool:
	if _sub == 0 and eska.global_position.x > 2640.0:
		_sub = 1
		gates["dummies"].close()
		foe = EWaves.spawn(self, "caster", Vector2(2950, FLOOR - 120.0), 1.0, 2580.0, 3160.0)
		tut.say("떠 있는 것은 머리 위로 벤다.")
		_ready_skill("dangong")
		tut.prompt(["es_up", "+", "es_skill"], "단공 — 위로 베어 올리기")
	if _sub == 1 and _orb_exists():
		_sub = 2
		tut.say("날아오는 구슬은 베어 없앨 수 있다.")
	if _sub >= 1 and _dead(foe):
		tut.done()
		gates["caster"].open()
		gates["dummies"].open()
		return true
	return false


func _orb_exists() -> bool:
	for n: Node in get_tree().get_nodes_in_group(PDummy.GROUP):
		if n is ECaster.Orb:
			return true
	return false


func _enter_bonggong() -> void:
	pass


func _tick_bonggong() -> bool:
	if _sub == 0 and eska.global_position.x > 3260.0:
		_sub = 1
		gates["caster"].close()
		gates["runner"].close()
		foe = EWaves.spawn(self, "runner", Vector2(3640, FLOOR), 1.0, 3200.0, 3780.0)
	if _sub == 1 and is_instance_valid(foe) and (foe as ERunner).st == ERunner.S.WIND:
		# 첫 돌진 예고: 잠깐 느려지며 피하는 법을 알려 줌
		_sub = 2
		Fx.slowmo(0.25, 0.6)
		tut.say("붉게 웅크리면 돌진한다 — 뛰거나, 사라져라.")
		tut.prompt(["es_jump", "/", "es_blink"], "피하기")
		_st = 0.0
	if _sub == 2 and _st > 2.0:
		_sub = 3
		tut.done()
	if _sub == 3 and not tut.has_prompt():
		_sub = 4
		_ready_skill("bonggong")
		tut.prompt(["es_bind"], "봉공 — 가두면 꼼짝 못 한다 (피해 +30%)")
	if _sub >= 4 and eska.cast_kind == "bonggong" and eska.st == EEska.St.CAST:
		tut.done()
	if _sub >= 1 and _dead(foe):
		tut.done()
		gates["runner"].open()
		gates["caster"].open()
		return true
	return false


func _enter_finale() -> void:
	pass


func _tick_finale() -> bool:
	match _sub:
		0:
			if eska.global_position.x > 3900.0:
				_sub = 1
				_st = 0.0
				gates["runner"].close()
				_cutscene(true)
				Music.play("boss", 1.2)
				cam.set("focus_p", Vector2(4250, FLOOR - 70.0))
				var tw := create_tween()
				tw.tween_property(cam, "focus_w", 1.0, 0.7).set_trans(Tween.TRANS_SINE)
		1:
			if _st > 0.8:
				_sub = 2
				boss = EWaves.spawn(self, "colossus", Vector2(4250, FLOOR), 1.0, 3830.0, W - 30.0) as EColossus
				EFoeFx.rift(Vector2(4250, FLOOR - 40.0), 60.0)
				Fx.shake(0.9, 0.5)
				Sfx.play_pitch(&"roar", 0.7, 0.0)
				hud.banner("검은 거상", "문턱을 지키는 것", 2.2)
				hud.boss = boss
				hud.boss_name = "검은 거상"
		2:
			if _st > 2.6:
				_sub = 3
				var tw := create_tween()
				tw.tween_property(cam, "focus_w", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
				_cutscene(false)
				_st = 0.0
		3:
			if _st > 3.0:
				_sub = 4
				tut.say("이것으로 끝을 낸다.")
				_ready_skill("ult")
				tut.prompt(["es_ult"], "종언참")
		4, 5:
			if eska.st == EEska.St.ULT:
				tut.done()
			if _sub == 4 and is_instance_valid(boss) and boss.hp < boss.max_hp / 2:
				_sub = 5
				EWaves.spawn(self, "caster", Vector2(4000, FLOOR - 120.0), 1.0, 3830.0, W - 30.0)
	if _sub >= 2 and _dead(boss):
		return true
	return false


func _enter_end() -> void:
	tut.done()
	Fx.slowmo(0.2, 1.4)
	Fx.flash(Color(1.0, 0.85, 1.0, 0.6), 0.5)
	for n: Node in get_children():
		if n is EEnemy and not (n as EEnemy).is_dead():
			(n as EEnemy).banish()
	eska.controls_locked = true
	eska.invuln = 999.0


func _tick_end() -> bool:
	if _sub == 0 and _st > 1.6:
		_sub = 1
		Music.play("")
		Music.jingle("jingle_chapter")
		tut.bars_to(1.0)
		touch.release_all()
		touch.process_mode = Node.PROCESS_MODE_DISABLED
		touch.visible = false
		var end := ETutEnd.new()
		var secs := int(_clock)
		end.stats = [["걸린 시간", "%d분 %02d초" % [secs / 60, secs % 60]], ["쓰러짐", "%d번" % _deaths],
			["맞음", "%d번" % _hits_taken], ["최고 연타", "%d HIT" % _best_combo]]
		end.chosen.connect(_on_end_chosen)
		tut.get_parent().add_child(end)
	return false


func _on_end_chosen(what: String) -> void:
	tut.fade_to(1.0, 0.4)
	await get_tree().create_timer(0.45, true, false, true).timeout
	Fx.reset()
	match what:
		"retry":
			get_tree().reload_current_scene()
		"arena":
			get_tree().change_scene_to_file("res://proto/eska/eska_arena.tscn")
		_:
			GameState.go_title()


## 배우라고 안내하는 순간에는 그 기술을 바로 쓸 수 있게 (먼저 써 버려 쿨다운 중이면 헷갈림)
func _ready_skill(id: String) -> void:
	eska.cooldowns[id] = 0.0


## 연출 중: 조작 막기 + 영화 띠 + 터치 버튼 숨김
func _cutscene(on: bool) -> void:
	eska.controls_locked = on
	tut.bars_to(1.0 if on else 0.0)
	touch.visible = not on
	if on:
		touch.release_all()


func _dead(e: EEnemy) -> bool:
	return not is_instance_valid(e) or e.is_dead()


## 시험 실행기 eval용: 지금 단계
func step_name() -> String:
	return "%s sub=%d x=%d hp=%d" % [STEPS[_step] if _step < STEPS.size() else "?", _sub, int(eska.global_position.x), eska.hp]
