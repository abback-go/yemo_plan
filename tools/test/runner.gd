extends SceneTree
# 시나리오 실행기: 장면을 열고 정해진 프레임에 입력·명령을 넣고 스크린샷을 찍는다 (tools/test/README.md)
# Usage: godot --rendering-driver opengl3 --fixed-fps 60 --script shoot.gd -- <scenario> <outdir>

var frame := 0
var steps: Array = []
var outdir := ""
var scene_path := ""
var _cp := 0
var _loaded := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var scenario: String = args[0]
	outdir = args[1]
	var sc = load("res://../../tmp_scenarios.gd") if false else null
	var f := FileAccess.open(scenario, FileAccess.READ)
	var json = JSON.parse_string(f.get_as_text())
	scene_path = json.scene
	steps = json.steps
	_cp = int(json.get("checkpoint", 0))
	# 전역 난수를 고정해 실행마다 결과가 같게 (리팩터 전후 비교용, tools/test/regress.sh)
	seed(int(json.get("seed", 20261004)))
	_world_room = String(json.get("room", ""))
	_world_spawn = String(json.get("spawn", "start"))
	_world_flags = json.get("flags", [])
	# 배경 움직임 다시 그리기 상한: 시험은 기본 0(매 프레임)이라 픽셀 비교가 안정적. 성능 시나리오는 "bg_hz": 30 처럼 지정
	load("res://world/themes/backdrop_kit.gd").Ticker.hz = float(json.get("bg_hz", 0))
	# 정적 배경 텍스처 굽기 (기본 켬). "bake_bg": false 면 예전처럼 명령을 직접 그림 — 구운 그림과 픽셀 비교용
	load("res://world/themes/backdrop_kit.gd").BAKE = bool(json.get("bake_bg", true))


var _release_next: Array = []
var _auto := false
var sframe := 0 ## 단계 시계 (waitidle 동안 멈춤)
var _hold := 0 ## 0이 아니면 대기 중 (남은 한도)
var _idle_n := 0
var _god := false
var _autoward := false
var _autokill := 0 ## 적 탄이 가까우면 방벽(장착 칸)을 자동으로 세움 (방벽 수업 시험)
var _dc_name := "" ## drawcount: 세는 중인 이름 ("" = 안 셈)
var _dc_left := 0
var _dc_n := 0
var _dc_nodes: Array = []


## 스크립트 class_name이 cls인 노드를 모두 모음 (find_children은 스크립트 클래스를 못 찾음)
func _collect_script_class(n: Node, cls: String, out: Array) -> void:
	var sc: Script = n.get_script()
	while sc != null:
		if sc.get_global_name() == cls:
			out.append(n)
			break
		sc = sc.get_base_script()
	for c in n.get_children():
		_collect_script_class(c, cls, out)


func _tap(a: String) -> void:
	var ev := InputEventAction.new()
	ev.action = a
	ev.pressed = true
	Input.parse_input_event(ev)
	_release_next.append(a)


## 대화·안내·습득 팝업을 자동으로 넘김
func _auto_advance() -> void:
	var w = get_first_node_in_group("world")
	if w == null:
		return
	if w.teach.is_active():
		var keys: Array = w.teach._wait
		var k: String = keys[0] if not keys.is_empty() else "jump"
		if k == "move":
			k = "move_right"
		print("AUTO teach ", w.teach._draw.title, " -> ", k, " f=", frame)
		_tap(k)
	elif w.get_node_or_null("EndScreen") != null and w.get_node("EndScreen")._root.visible:
		print("AUTO end screen f=", frame)
		_tap("jump")
	elif w.notice._waiting:
		print("AUTO notice f=", frame)
		_tap("jump")
	elif w.dialogue.is_open() and w.dialogue._waiting:
		print("AUTO line [", w.dialogue._name.text, "] ", w.dialogue._text.text.substr(0, 40), " f=", frame)
		_tap("jump")
		_tap("jump")
var _bg_f0 := 0 ## bgperf 구간 시작 프레임
var _world_room := ""
var _world_spawn := ""
var _world_flags: Array = []


func _process(_d: float) -> bool:
	if not _loaded:
		_loaded = true
		# FRAME_CLOCK=1: 히트스톱 등 시간 효과를 프레임 수로 재서 바쁜 컴퓨터에서도 결과가 같게 (Fx.frame_clock)
		if OS.get_environment("FRAME_CLOCK") == "1":
			root.get_node("Fx").frame_clock = true
		var gs = root.get_node("GameState")
		if _world_room != "":
			gs.new_game()
			gs.room = _world_room
			gs.spawn = _world_spawn
			for f in _world_flags:
				gs.set_flag(f)
			gs.running = true
		else:
			gs.checkpoint_index = _cp
		change_scene_to_file(scene_path)
		return false
	frame += 1
	for a in _release_next:
		var ev := InputEventAction.new()
		ev.action = a
		ev.pressed = false
		Input.parse_input_event(ev)
	_release_next.clear()
	if _auto and frame % 7 == 0:
		_auto_advance()
	if _autoward:
		var ap = get_first_node_in_group("player")
		if ap and ap.ward_cooldown_left <= 0.0 and not ap.is_warding():
			for pr in get_nodes_in_group("enemy_projectile"):
				if not pr.reflected and pr.global_position.distance_to(ap.center()) < 30.0:
					var slot := "s" if load("res://core/spells.gd").equipped("s") == "ward" else "a"
					ap.cast_slot(slot)
					print("AUTOWARD f=", frame)
					break
	if _autokill > 0 and frame % _autokill == 0:
		for e in get_nodes_in_group("enemy"):
			if e.is_alive() and not e.is_boss:
				e.take_hit(load("res://core/hit.gd").make(99999, &"bolt", e.global_position))
	if _god:
		var gp := get_first_node_in_group("player")
		if gp:
			gp.set_iframes(9999.0)
			if gp.hp < 3:
				gp.hp = 5
	if _hold > 0:
		_hold -= 1
		var busy: bool = root.get_node("Story").busy() or paused
		var w0 = get_first_node_in_group("world")
		if w0 and w0.transitioning:
			busy = true
		_idle_n = 0 if busy else _idle_n + 1
		if _idle_n >= 30 or _hold == 0:
			if _hold == 0:
				print("WAIT TIMEOUT at sframe ", sframe, " f=", frame)
			_hold = 0
		return false
	sframe += 1
	if _dc_name != "":
		_dc_left -= 1
		if _dc_left <= 0:
			print("DRAWS ", _dc_name, " nodes=", _dc_nodes.size(), " redraws=", _dc_n, " room=", get_first_node_in_group("world").room.data.id)
			_dc_name = ""
	for s in steps:
		if int(s[0]) != sframe:
			continue
		match s[1]:
			"press": Input.action_press(s[2])
			"release": Input.action_release(s[2])
			"tp":
				var p := get_first_node_in_group("player")
				if p:
					p.global_position = Vector2(float(s[2]), float(s[3])) * 16.0
					p.camera.reset_smoothing()
			"shot":
				var img := root.get_texture().get_image()
				img.save_png(outdir.path_join(s[2] + ".png"))
				print("SHOT ", s[2], " frame ", frame)
			"log":
				var p := get_first_node_in_group("player")
				print("LOG ", s[2], " pos=", p.global_position / 16.0 if p else null, " hp=", p.hp if p else -1, " overload=", p.overload if p else -1, " state=", p.state if p else -1, " enemies=", get_nodes_in_group("enemy").size(), " stats=", root.get_node("GameState").stats)
			"kill":
				for e in get_nodes_in_group("enemy"):
					if e.is_alive():
						var h := Hit.make(999, &"bolt", e.global_position)
						e.take_hit(h)
			"hurt":
				var p := get_first_node_in_group("player")
				p.take_damage(int(s[2]), &"charger", p.global_position.x - 10.0)
			"scene":
				print("SCENE ", current_scene.scene_file_path if current_scene else "none", " cp=", root.get_node("GameState").checkpoint_index)
			"logv":
				var p := get_first_node_in_group("player")
				print("LOGV ", s[2], " f=", frame, " pos=", (p.global_position / 16.0).snapped(Vector2(0.01, 0.01)), " vel=", (p.velocity / 16.0).snapped(Vector2(0.1, 0.1)), " floor=", p.is_on_floor(), " state=", p.state, " airdash=", p.air_dashes_left, " hp=", p.hp, " ovl=", snappedf(p.overload, 0.1), " jumpH=", snappedf(p.last_jump_height_t, 0.01))
			"style":
				var sr = root.get_node("StyleRank")
				var fx = root.get_node("Fx")
				print("STYLE ", s[2], " f=", frame, " combo=", sr.combo, " max=", sr.max_combo, " pts=", snappedf(sr.points, 0.1), " rank=", sr.rank_name(), " best=", sr.best_rank, " enemy_time=", fx.enemy_time, " witch=", fx.is_witch_time(), " ts=", Engine.time_scale, " event=", sr.last_event)
			"enemies":
				for e in get_nodes_in_group("enemy"):
					print("ENEMY ", s[2], " f=", frame, " ", e.name, " pos=", (e.global_position / 16.0).snapped(Vector2(0.01, 0.01)), " vel=", (e.velocity / 16.0).snapped(Vector2(0.1, 0.1)), " hp=", e.hp, " alive=", e.is_alive(), " floor=", e.is_on_floor(), " state=", e.get("state"))
			"shots":
				for n in current_scene.find_children("*", "SniperShot", true, false):
					print("SHOTPOS ", s[2], " f=", frame, " pos=", (n.global_position / 16.0).snapped(Vector2(0.01, 0.01)))
			"shot_at":
				# 세라 중심에서 dx(px) 떨어진 곳에 세라를 향해 날아오는 저격탄 생성
				var p := get_first_node_in_group("player")
				var shot = load("res://enemies/sniper_shot.gd").new()
				var from: Vector2 = p.center() + Vector2(float(s[2]), 0)
				shot.setup(from, (p.center() - from).normalized(), float(s[3]))
				current_scene.get_node("Effects").add_child(shot)
			"free":
				var n := current_scene.get_node_or_null(s[2])
				if n:
					n.free()
			"set":
				var p := get_first_node_in_group("player")
				p.set(s[2], s[3])
			"rm_enemies":
				for e in get_nodes_in_group("enemy"):
					e.free()
			"pillar":
				var fp = load("res://combat/fire_pillar.gd").new()
				fp.setup(Vector2(float(s[2]), float(s[3])) * 16.0, null, load("res://core/tuning.tres"))
				current_scene.get_node("Effects").add_child(fp)
			"pinfo":
				for n in current_scene.find_children("*", "FirePillar", true, false):
					print("PILLAR ", s[2], " f=", frame, " side=", n.side, " t=", snappedf(n._t, 0.001), " erupted=", n._erupted, " w=", n._w, " h=", n._h, " vis=", n.is_visible_in_tree(), " z=", n.z_index, " pos=", n.global_position / 16.0)
			"ehp":
				for e in get_nodes_in_group("enemy"):
					e.max_hp = int(s[2])
					e.hp = int(s[2])
			"face":
				var p := get_first_node_in_group("player")
				p.facing = int(s[2])
			"tap":
				var ev := InputEventAction.new()
				ev.action = s[2]
				ev.pressed = true
				Input.parse_input_event(ev)
				_release_next.append(s[2])
			"touch", "untouch":
				# [frame, "touch"|"untouch", index, x, y] — 화면 좌표(640×360 창)로 손가락 누름/뗌
				var te := InputEventScreenTouch.new()
				te.index = int(s[2])
				te.position = Vector2(float(s[3]), float(s[4]))
				te.pressed = s[1] == "touch"
				Input.parse_input_event(te)
			"drag":
				var de := InputEventScreenDrag.new()
				de.index = int(s[2])
				de.position = Vector2(float(s[3]), float(s[4]))
				Input.parse_input_event(de)
			"touchinfo":
				var tc = root.get_node("TouchControls")
				var held := []
				for a in ["move_left", "move_right", "move_up", "move_down", "jump", "attack", "dash", "skill_1", "skill_2", "fox_window", "potion", "map", "pause"]:
					if Input.is_action_pressed(a):
						held.append(a)
				print("TOUCH f=", frame, " ms=", Time.get_ticks_msec(), " active=", tc.active, " shown=", tc.shown, " input=", held, " stick=", tc.stick_state().on, " ", tc.stick_state().dirs)
			"spawn_enemy":
				# [frame, "spawn_enemy", kind, x_tile, y_tile, {props}]
				var en = load("res://enemies/enemy_registry.gd").create(s[2])
				if en == null:
					print("SPAWN FAILED ", s[2])
				else:
					en.position = Vector2(float(s[3]) * 16.0 + 8.0, float(s[4]) * 16.0)
					en.uid = "test:" + str(frame)
					if s.size() > 5:
						for k in s[5]:
							en.set(k, s[5][k])
					var w = get_first_node_in_group("world")
					w.room.add_entity(en)
					print("SPAWNED ", s[2], " at ", en.position / 16.0)
			"godmode":
				_god = true
			"engage":
				for e in get_nodes_in_group("enemy"):
					e.set("engaged", true)
			"flagset":
				root.get_node("GameState").set_flag(s[2])
			"worldinfo":
				var w = get_first_node_in_group("world")
				var p := get_first_node_in_group("player")
				print("WORLD ", s[2], " f=", frame, " room=", w.room.data.id if w and w.room else "-", " pos=", (p.global_position / 16.0).snapped(Vector2(0.1, 0.1)) if p else null, " busy=", root.get_node("Story").busy(), " paused=", paused, " hp=", p.hp if p else -1, " ctrl=", p.controls_enabled if p else null, " obj=", load("res://story/objectives.gd").current())
			"ehpf":
				for e in get_nodes_in_group("enemy"):
					if e.is_alive():
						e.hp = maxi(int(e.max_hp * float(s[2])), 1)
			"status":
				var w = get_first_node_in_group("world")
				var gs = root.get_node("GameState")
				var en := []
				for e in get_nodes_in_group("enemy"):
					en.append("%s:%d/%d%s" % [e.kind_id, e.hp, e.max_hp, "" if e.engaged else "(idle)"])
				print("STATUS ", s[2], " f=", frame, " room=", w.room.data.id, " busy=", root.get_node("Story").busy(), " paused=", paused, " ctrl=", w.player.controls_enabled, " hp=", w.player.hp, " fox=", snappedf(w.player.fox_time, 0.1), " obj=", load("res://story/objectives.gd").current(), " enemies=", en)
			"auto":
				_auto = bool(s[2])
			"waitidle":
				_hold = int(s[2]) if s.size() > 2 else 3000
				_idle_n = 0
			"run":
				root.get_node("Story").run(s[2])
			"record":
				root.get_node("GameState").record_at(String(s[2]), String(s[3]))
			"continue":
				var gs = root.get_node("GameState")
				gs.flags = {}
				print("CONTINUE ok=", gs.continue_game())
			"flags":
				var gs = root.get_node("GameState")
				print("FLAGS ", s[2], " n=", gs.flags.size(), " room=", gs.room, " spawn=", gs.spawn, " maxhp=", gs.max_hp, " pot=", gs.potions_max, " abil=", gs.flags.keys().filter(func(k): return String(k).begins_with("ab_")))
			"go":
				var w = get_first_node_in_group("world")
				w.go(s[2], s[3])
			"abil":
				root.get_node("GameState").unlock_ability(s[2])
			"setting":
				# [frame, "setting", 키, 값] — 저장된 설정이 시험에 끼어들지 않게
				root.get_node("GameState").settings[s[2]] = s[3]
			"potions":
				var gsp = root.get_node("GameState")
				gsp.potions_max = int(s[2])
				gsp.potions = int(s[2])
			"hp":
				var p := get_first_node_in_group("player")
				p.hp = int(s[2])
			"ovl":
				var p := get_first_node_in_group("player")
				p.overload = float(s[2])
			"quest":
				# [frame, "quest", id] — 퀘스트 상태·단계
				var qs = load("res://core/quests.gd")
				print("QUEST ", s[2], " f=", frame, " state=", qs.state(s[2]), " step=", qs.step(s[2]), " tracker=", qs.tracker_line())
			"spells":
				var sp = load("res://core/spells.gd")
				var ls := []
				for id in sp.ORDER:
					if sp.learned(id):
						ls.append("%s:%d" % [id, sp.level(id)])
				print("SPELLS ", s[2] if s.size() > 2 else "", " f=", frame, " learned=", ls, " eq=", [sp.equipped("a"), sp.equipped("s"), sp.equipped("f")], " stones=", sp.stones(), " total=", root.get_node("GameState").flag("mana_total", 0))
			"hitg":
				# [frame, "hitg", 그룹, 피해 종류, (속성, 값)] — 그룹의 장치를 order 순서로 맞힘 (별·과녁·촛불)
				var ns: Array = get_nodes_in_group(s[2])
				ns.sort_custom(func(a, b): return int(a.get("order") if a.get("order") != null else 0) < int(b.get("order") if b.get("order") != null else 0))
				var n_hit := 0
				for n in ns:
					if s.size() > 5 and str(n.get(s[4])) != str(s[5]):
						continue
					n.take_hit(load("res://core/hit.gd").make(100, StringName(s[3]), n.global_position))
					n_hit += 1
				print("HITG ", s[2], " n=", n_hit, " f=", frame)
			"projs":
				var pp = get_first_node_in_group("player")
				var ps := []
				for pr in get_nodes_in_group("enemy_projectile"):
					ps.append("%s r=%s" % [(pr.global_position / 16.0).snapped(Vector2(0.1, 0.1)), pr.reflected])
				print("PROJS f=", frame, " player=", (pp.center() / 16.0).snapped(Vector2(0.1, 0.1)), " cd=", pp.ward_cooldown_left, " ", ps)
			"litg":
				var lits := []
				for n in get_nodes_in_group(s[2]):
					lits.append(n.get("lit"))
				print("LIT ", s[2], " f=", frame, " ", lits)
			"ally":
				# [frame, "ally", 종류] — 동료 합류 (world.ally_join)
				var w = get_first_node_in_group("world")
				var a = w.ally_join(s[2])
				print("ALLY ", s[2], " ", a != null)
			"ally_special":
				var w = get_first_node_in_group("world")
				var a = w.ally(s[2])
				var tgt = null
				for e in get_nodes_in_group("enemy"):
					if e.is_alive():
						tgt = e
						break
				if a:
					a.special(tgt)
			"autoward":
				_autoward = bool(s[2])
			"flagval":
				root.get_node("GameState").set_flag(s[2], s[3])
			"talk":
				# [frame, "talk", 인물] — 그 인물에게 말 걸기 (NPC의 대본, 퀘스트 대화 가로채기 포함)
				var w = get_first_node_in_group("world")
				var npc = w.room.actors.get(s[2])
				if npc == null:
					print("TALK no actor ", s[2])
				else:
					var p := get_first_node_in_group("player")
					p.global_position = npc.global_position + Vector2(-24, 0)
					npc.interact()
			"board":
				# [frame, "board", 마법ID] — 수업 게시판 창을 열고 그 수업을 신청
				var w = get_first_node_in_group("world")
				w.class_ui.open()
				w.class_ui.sel = load("res://core/spells.gd").ORDER.find(s[2])
				print("BOARD ", s[2], " status=", w.class_ui.status(s[2]))
				if s.size() > 3 and s[3] == "peek":
					return false
				w.class_ui._apply()
			"board_close":
				get_first_node_in_group("world").class_ui.close()
			"autokill":
				# [frame, "autokill", n] — n프레임마다 보스 아닌 적을 모두 처치 (0 = 끔)
				_autokill = int(s[2])
			"savecode":
				# [frame, "savecode"] — 마지막 기록을 저장 코드로 출력
				print("SAVECODE ", root.get_node("GameState").export_code())
			"importcode":
				# [frame, "importcode", 코드] — 저장 코드로 이어하기
				var gsc = root.get_node("GameState")
				var ok: bool = gsc.import_code(String(s[2]))
				print("IMPORT ok=", ok)
				if ok:
					gsc.continue_game()
			"drawcount":
				# [frame, "drawcount", 이름, 클래스, 프레임 수] — 그 클래스 노드들이 N프레임 동안 다시 그린(_draw) 횟수
				_dc_name = String(s[2])
				_dc_left = int(s[4])
				_dc_n = 0
				_dc_nodes = []
				_collect_script_class(current_scene, String(s[3]), _dc_nodes)
				for n in _dc_nodes:
					n.draw.connect(func() -> void: _dc_n += 1)
			"perf":
				# [frame, "perf", 이름] — 프레임 시간·그리기 호출·노드 수
				print("PERF ", s[2], " fps=", Engine.get_frames_per_second(), " process_ms=", snappedf(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, 0.01), " physics_ms=", snappedf(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, 0.01), " draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " objects=", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), " nodes=", Performance.get_monitor(Performance.OBJECT_NODE_COUNT), " room=", get_first_node_in_group("world").room.data.id)
			"bghz":
				# [frame, "bghz", Hz] — 배경 움직임 다시 그리기 상한 바꾸기 (0 = 매 프레임)
				load("res://world/themes/backdrop_kit.gd").Ticker.hz = float(s[2])
			"bgperf":
				# [frame, "bgperf", 이름] — 직전 bgperf 이후 배경(정적·동적 부분) 그리기 계측 (world/themes/backdrop_kit.gd Stats)
				var st = load("res://world/themes/backdrop_kit.gd").Stats
				var nf: int = maxi(frame - _bg_f0, 1)
				print("BGPERF ", s[2], " frames=", nf, " anim_draw_us_per_frame=", snappedf(float(st.anim_us) / nf, 0.1), " anim_items_per_frame=", snappedf(float(st.anim_n) / nf, 0.1), " anim_draws_per_frame=", snappedf(float(st.anim_draws) / nf, 0.01), " static_draw_us=", st.static_us, " static_cmds_drawn=", st.static_n, " recorded_static=", st.static_cmds, " recorded_anim=", st.anim_items, " room=", get_first_node_in_group("world").room.data.id)
				st.reset()
				_bg_f0 = frame
			"eval":
				# [frame, "eval", "식"] — World를 바탕으로 GDScript 식 하나 실행·출력 (성능 원인 찾기 등: "room.get_node('Background').set('visible', false)")
				var ex := Expression.new()
				if ex.parse(String(s[2])) != OK:
					print("EVAL parse error: ", ex.get_error_text())
				else:
					var base: Object = get_first_node_in_group("world")
					if base == null:
						base = current_scene # 월드가 아닌 장면(전투 시제품 훈련장 등)
					print("EVAL ", s[2], " -> ", ex.execute([], base))
			"quit":
				return true
	return false
