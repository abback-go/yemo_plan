class_name World
extends Node2D
## 게임 화면 (docs/chapter1.md 4.1절). 방을 바꿔 끼우고, 세라·너울·HUD·대화창 등은 유지한다.
## 방 전환(페이드), 상호작용(↑), 쓰러짐과 부활, 지도·일시정지 열기를 맡는다.

const PLAYER_SCENE := preload("res://player/player.tscn")

var room: Room
var player: Player
var pet: NeoulPet
var effects: Node2D
var hud: Node
var dialogue: DialogueBox
var teach: TeachPrompt
var notice: Notice
var map_screen: MapScreen
var pause_menu: Node
var fade: ScreenFade
var transitioning := false

var _room_holder: Node2D
var _focus: Interactable
var _hint: InteractHint
var _last_area := ""


static func get_world() -> World:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.get_first_node_in_group(&"world") as World


func _ready() -> void:
	add_to_group(&"world")
	Fx.reset()
	get_tree().paused = false
	_room_holder = Node2D.new()
	_room_holder.name = "RoomHolder"
	add_child(_room_holder)

	player = PLAYER_SCENE.instantiate()
	add_child(player)
	player.died.connect(_on_player_died)

	pet = NeoulPet.new()
	pet.name = "Neoul"
	add_child(pet)
	pet.attach(player)

	effects = Node2D.new()
	effects.name = "Effects"
	effects.z_index = 5
	add_child(effects)

	_hint = InteractHint.new()
	_hint.z_index = 40
	add_child(_hint)

	hud = load("res://ui/hud.gd").new()
	hud.name = "HUD"
	add_child(hud)
	notice = Notice.new()
	add_child(notice)
	dialogue = DialogueBox.new()
	add_child(dialogue)
	teach = TeachPrompt.new()
	add_child(teach)
	map_screen = MapScreen.new()
	add_child(map_screen)
	pause_menu = load("res://ui/pause_menu.gd").new()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)
	var dbg := CanvasLayer.new()
	dbg.name = "DebugOverlay"
	dbg.set_script(load("res://ui/debug_overlay.gd"))
	dbg.visible = false
	add_child(dbg)
	fade = ScreenFade.new()
	add_child(fade)

	Story.attach(self)
	GameState.running = true
	fade.set_black()
	load_room(GameState.room, GameState.spawn)
	player.restore_from_state()
	await get_tree().process_frame
	_enter_room(0.6)


# ─── 방 불러오기 ────────────────────────────────────────

func load_room(id: String, spawn_id: String) -> void:
	var path := "res://world/rooms/%s.gd" % id
	if not ResourceLoader.exists(path):
		push_error("room not found: " + id)
		return
	if room:
		room.queue_free()
		_room_holder.remove_child(room)
	for c in effects.get_children():
		c.queue_free()
	Fx.reset_time()
	var data: RoomData = (load(path) as GDScript).new()
	room = Room.new()
	room.build(data)
	_room_holder.add_child(room)
	GameState.room = id
	GameState.spawn = spawn_id
	var first := not GameState.visited.has(id)
	GameState.visited[id] = true

	var sp := room.spawn_point(spawn_id)
	player.place_at(sp.pos, int(sp.get("face", 1)))
	if sp.get("jump", false):
		player.velocity.y = -420.0
	pet.snap_to_player()
	var cam := player.camera
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(room.size_px.x)
	cam.limit_bottom = int(room.size_px.y)
	cam.reset_smoothing()
	Music.play(data.music)
	if data.title != "" and (first or data.area != _last_area):
		notice.area_name(data.title)
	_last_area = data.area
	_focus = null


## 방 이동 (페이드). spawn_id: 도착 방의 출구·문·기록 지점·표식 ID
func go(to_room: String, spawn_id: String, keep_velocity := false) -> void:
	if transitioning:
		return
	transitioning = true
	var vel := player.velocity
	var was := player.controls_enabled
	player.controls_enabled = false
	await fade.fade_out(0.22)
	load_room(to_room, spawn_id)
	if keep_velocity:
		player.velocity.x = vel.x
	await get_tree().physics_frame
	player.controls_enabled = was if not Story.busy() else false
	transitioning = false
	_enter_room(0.25)


## 화면을 밝히기 시작한 뒤 방 입장 대본을 부른다 (대본이 암전을 원하면 대본 쪽 페이드가 이김)
func _enter_room(fade_time: float) -> void:
	fade.fade_in(fade_time)
	Story.on_room_entered(room.data.id, false)


func request_exit(x: RoomExit) -> void:
	if transitioning or Story.busy() or not player.is_alive():
		return
	go(x.to_room, x.to_id, true)


# ─── 상호작용 ───────────────────────────────────────────

func _physics_process(_delta: float) -> void:
	if room == null:
		return
	_update_focus()


func _update_focus() -> void:
	var best: Interactable = null
	if player.controls_enabled and player.is_alive() and not transitioning and not Story.busy():
		var pc := player.center()
		var best_d := INF
		for n in get_tree().get_nodes_in_group(&"interactable"):
			var it := n as Interactable
			if it == null or not it.can_interact():
				continue
			var r := it.interact_rect()
			if r.has_point(pc) or r.has_point(player.global_position + Vector2(0, -4)):
				var d := absf(it.global_position.x - pc.x)
				if d < best_d:
					best_d = d
					best = it
	_focus = best
	_hint.target = _focus


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_up") and _focus and player.controls_enabled and player.is_on_floor() and not Story.busy():
		get_viewport().set_input_as_handled()
		_focus.interact()
	elif event.is_action_pressed("map") and not Story.busy() and player.controls_enabled:
		get_viewport().set_input_as_handled()
		map_screen.open()
	elif event.is_action_pressed("debug"):
		var dbg := get_node_or_null("DebugOverlay") as CanvasLayer
		if dbg:
			dbg.visible = not dbg.visible


# ─── 쓰러짐과 부활 ──────────────────────────────────────

func _on_player_died() -> void:
	await get_tree().create_timer(1.5, true, false, true).timeout
	await fade.fade_out(0.6)
	Story.reset()
	GameState.heal_full()
	Fx.reset_time()
	load_room(GameState.respawn_room, GameState.respawn_spawn)
	player.revive()
	await get_tree().process_frame
	_enter_room(0.6)
