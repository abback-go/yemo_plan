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
	_world_room = String(json.get("room", ""))
	_world_spawn = String(json.get("spawn", "start"))
	_world_flags = json.get("flags", [])


var _release_next: Array = []
var _auto := false
var sframe := 0 ## 단계 시계 (waitidle 동안 멈춤)
var _hold := 0 ## 0이 아니면 대기 중 (남은 한도)
var _idle_n := 0
var _god := false


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
		var k: String = keys[0]
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
var _world_room := ""
var _world_spawn := ""
var _world_flags: Array = []


func _process(_d: float) -> bool:
	if not _loaded:
		_loaded = true
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
	if _god:
		var gp := get_first_node_in_group("player")
		if gp:
			gp.set("_hurt_iframe", 9999.0)
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
			"hp":
				var p := get_first_node_in_group("player")
				p.hp = int(s[2])
			"ovl":
				var p := get_first_node_in_group("player")
				p.overload = float(s[2])
			"quit":
				return true
	return false
