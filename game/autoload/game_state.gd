extends Node
## 한 번의 플레이(런) 동안 유지되는 정보: 체크포인트, 플레이 시간, 결과 화면용 기록.
## 오토로드라 씬을 다시 불러와도(사망 후 재시작) 값이 유지된다.

const STAGE_SCENE := "res://levels/stage.tscn"
const TITLE_SCENE := "res://ui/title.tscn"
const RESULT_SCENE := "res://ui/result.tscn"

var checkpoint_index := 0 ## 마지막으로 도달한 체크포인트 (0 = 시작 지점)
var run_time := 0.0 ## 일시정지를 뺀 플레이 시간 (s)
var running := false
var cleared := false
var stats := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	# 한글 픽셀 폰트를 모든 UI의 기본 글꼴로. (프로젝트 테마로 지정하면 처음 가져오기 때
	# 폰트보다 테마가 먼저 읽혀 오류가 나므로, 실행 시작 시점에 기본 글꼴을 바꾼다)
	var font := load("res://assets/fonts/Galmuri11.ttf") as Font
	if font:
		ThemeDB.fallback_font = font
		ThemeDB.fallback_font_size = 12
	new_run()


func _process(delta: float) -> void:
	if running and Engine.time_scale > 0.0:
		run_time += delta / Engine.time_scale # 히트스톱·슬로모션 중에도 실제 시간으로 잼


func new_run() -> void:
	checkpoint_index = 0
	run_time = 0.0
	running = false
	cleared = false
	stats = {
		"deaths": 0,
		"hits_charger": 0,
		"hits_sniper": 0,
		"hits_overload": 0,
		"overloads": 0,
		"pillar": 0,
		"storm": 0,
		"dashes": 0,
		"bolts_fired": 0,
		"bolts_hit": 0,
		"kills": 0,
	}


func add(key: String, amount := 1) -> void:
	stats[key] = stats.get(key, 0) + amount


func start_stage() -> void:
	running = true
	get_tree().change_scene_to_file(STAGE_SCENE)


func restart_from_checkpoint() -> void:
	running = true
	get_tree().change_scene_to_file(STAGE_SCENE)


func restart_run() -> void:
	new_run()
	start_stage()


func go_title() -> void:
	running = false
	get_tree().change_scene_to_file(TITLE_SCENE)


func finish_run() -> void:
	running = false
	cleared = true
	get_tree().change_scene_to_file(RESULT_SCENE)


static func format_time(sec: float) -> String:
	var total := int(sec)
	return "%02d:%02d.%d" % [total / 60, total % 60, int((sec - total) * 10.0)]
