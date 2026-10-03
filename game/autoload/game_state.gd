extends Node
## 진행 상태와 저장 (docs/chapter1.md 4.1~4.2절).
## 이야기 플래그, 해금 능력, 체력·물약, 현재 방, 마지막 기록 지점, 방문한 방, 처치한 적, 수집품, 통계, 설정.
## 오토로드라 씬을 바꿔도(타이틀 ↔ 월드) 값이 유지된다.

signal flag_changed(key: String)

const WORLD_SCENE := "res://world/world.tscn"
const TITLE_SCENE := "res://ui/title.tscn"
const SAVE_PATH := "user://save_1.json"
const SETTINGS_PATH := "user://settings.cfg"
const SAVE_VERSION := 1
const START_ROOM := "t_pass"
const START_SPAWN := "start"

# 프로토타입 스테이지(v0.3, levels/stage.tscn)용 — 연습장에서만 쓴다
const STAGE_SCENE := "res://levels/stage.tscn"
const RESULT_SCENE := "res://ui/result.tscn"
var checkpoint_index := 0
var cleared := false

var flags := {} ## 이야기 진행·해금 플래그 (문자열 → 값)
var max_hp := 5
var potions_max := 0 ## 피피에게 물약을 받기 전에는 0
var potions := 0
var hp := 5 ## 방을 옮겨도 유지되는 세라의 체력
var room := START_ROOM ## 지금 있는 방
var spawn := START_SPAWN ## 방에 들어갈 때 설 자리 (출구·문·기록 지점·표식 ID)
var respawn_room := START_ROOM ## 쓰러지면 돌아갈 방
var respawn_spawn := START_SPAWN
var visited := {} ## 방문한 방 ID → true
var killed := {} ## 처치한 적 고유 ID → true (다시 나타나지 않음)
var collected := {} ## 주운 물건 ID → true
var run_time := 0.0 ## 플레이 시간 (일시정지·대화 포함, 타이틀 제외)
var running := false
var stats := {}
var settings := {
	"master": 0.9, "music": 0.75, "sfx": 0.85,
	"fullscreen": false, "shake": true, "damage_numbers": true,
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 한글 픽셀 폰트를 모든 UI의 기본 글꼴로. (프로젝트 테마로 지정하면 처음 가져오기 때
	# 폰트보다 테마가 먼저 읽혀 오류가 나므로, 실행 시작 시점에 기본 글꼴을 바꾼다)
	var font := load("res://assets/fonts/Galmuri11.ttf") as Font
	if font:
		ThemeDB.fallback_font = font
		ThemeDB.fallback_font_size = 12
		var default_theme := ThemeDB.get_default_theme()
		default_theme.default_font = font
		default_theme.default_font_size = 12
	_ensure_bus(&"Music")
	_ensure_bus(&"SFX")
	load_settings()
	new_game()


func _process(delta: float) -> void:
	if running and Engine.time_scale > 0.0 and not get_tree().paused:
		run_time += delta / Engine.time_scale # 히트스톱·슬로모션 중에도 실제 시간으로 잼


# ─── 새 게임 / 진행 상태 ────────────────────────────────

func new_game() -> void:
	flags = {}
	max_hp = 5
	hp = max_hp
	potions_max = 0
	potions = 0
	room = START_ROOM
	spawn = START_SPAWN
	respawn_room = START_ROOM
	respawn_spawn = START_SPAWN
	visited = {}
	killed = {}
	collected = {}
	run_time = 0.0
	running = false
	new_run()


## 전투 통계 (결과 화면·데모 끝 화면용)
func new_run() -> void:
	checkpoint_index = 0
	cleared = false
	stats = {
		"deaths": 0, "hits_charger": 0, "hits_sniper": 0, "hits_overload": 0, "overloads": 0,
		"pillar": 0, "storm": 0, "dashes": 0, "bolts_fired": 0, "bolts_hit": 0, "kills": 0,
		"perfect_dodges": 0, "max_combo": 0, "best_rank": 0, "fox_modes": 0, "secrets": 0,
	}
	StyleRank.reset_run()


func add(key: String, amount := 1) -> void:
	stats[key] = stats.get(key, 0) + amount


func flag(key: String, default: Variant = false) -> Variant:
	return flags.get(key, default)


func has_flag(key: String) -> bool:
	return bool(flags.get(key, false))


func set_flag(key: String, value: Variant = true) -> void:
	flags[key] = value
	flag_changed.emit(key)


## 해금 능력: storm(화염 폭풍), double_jump(부양), fox_window(여우창문), fox_mode(여우 모드), neoul(너울 동행)
func has_ability(ability: String) -> bool:
	return has_flag("ab_" + ability)


func unlock_ability(ability: String) -> void:
	set_flag("ab_" + ability)


func mark_killed(uid: String) -> void:
	if uid != "":
		killed[uid] = true


func is_killed(uid: String) -> bool:
	return killed.has(uid)


func mark_collected(id: String) -> void:
	collected[id] = true


func is_collected(id: String) -> bool:
	return collected.has(id)


func heal_full() -> void:
	hp = max_hp
	potions = potions_max


# ─── 게임 시작·이어하기·장면 전환 ───────────────────────

func start_new_game() -> void:
	new_game()
	running = true
	get_tree().paused = false
	get_tree().change_scene_to_file(WORLD_SCENE)


func continue_game() -> bool:
	if not load_game():
		return false
	running = true
	get_tree().paused = false
	get_tree().change_scene_to_file(WORLD_SCENE)
	return true


func go_title() -> void:
	running = false
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(TITLE_SCENE)


## 기록 지점에서 기록: 부활 지점을 이곳으로 바꾸고 저장한다
func record_at(room_id: String, spawn_id: String) -> void:
	respawn_room = room_id
	respawn_spawn = spawn_id
	save_game()


# ─── 저장 / 불러오기 ────────────────────────────────────

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"flags": flags, "max_hp": max_hp, "potions_max": potions_max,
		"room": respawn_room, "spawn": respawn_spawn,
		"visited": visited.keys(), "killed": killed.keys(), "collected": collected.keys(),
		"run_time": run_time, "stats": stats,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("save failed: %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(data))
	f.close()


func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return false
	new_game()
	flags = data.get("flags", {})
	max_hp = int(data.get("max_hp", 5))
	potions_max = int(data.get("potions_max", 0))
	respawn_room = String(data.get("room", START_ROOM))
	respawn_spawn = String(data.get("spawn", START_SPAWN))
	room = respawn_room
	spawn = respawn_spawn
	for k in data.get("visited", []):
		visited[String(k)] = true
	for k in data.get("killed", []):
		killed[String(k)] = true
	for k in data.get("collected", []):
		collected[String(k)] = true
	run_time = float(data.get("run_time", 0.0))
	var s: Dictionary = data.get("stats", {})
	for k in s:
		stats[k] = s[k]
	heal_full()
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


# ─── 설정 ───────────────────────────────────────────────

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		for k in settings:
			settings[k] = cfg.get_value("settings", k, settings[k])
	apply_settings()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for k in settings:
		cfg.set_value("settings", k, settings[k])
	cfg.save(SETTINGS_PATH)


func apply_settings() -> void:
	_set_bus_volume(&"Master", float(settings.master))
	_set_bus_volume(&"Music", float(settings.music))
	_set_bus_volume(&"SFX", float(settings.sfx))
	if OS.get_name() != "Web":
		var want := DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != want and not (want == DisplayServer.WINDOW_MODE_WINDOWED and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED):
			DisplayServer.window_set_mode(want)


func _set_bus_volume(bus: StringName, linear: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i >= 0:
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(linear, 0.0001)))
		AudioServer.set_bus_mute(i, linear <= 0.001)


func _ensure_bus(bus: StringName) -> void:
	if AudioServer.get_bus_index(bus) != -1:
		return
	AudioServer.add_bus()
	var i := AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, bus)
	AudioServer.set_bus_send(i, &"Master")


# ─── 프로토타입 스테이지(연습장) 호환 ──────────────────

func start_stage() -> void:
	running = true
	get_tree().change_scene_to_file(STAGE_SCENE)


func restart_from_checkpoint() -> void:
	running = true
	get_tree().change_scene_to_file(STAGE_SCENE)


func restart_run() -> void:
	new_run()
	start_stage()


func finish_run() -> void:
	running = false
	cleared = true
	stats["max_combo"] = StyleRank.max_combo
	stats["best_rank"] = StyleRank.best_rank
	get_tree().change_scene_to_file(RESULT_SCENE)


static func format_time(sec: float) -> String:
	var total := int(sec)
	return "%02d:%02d.%d" % [total / 60, total % 60, int((sec - total) * 10.0)]
