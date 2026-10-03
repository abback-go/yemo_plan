extends Node
## 콤보와 스타일 랭크 (v0.3, docs/prototype.md 14절). Devil May Cry의 스타일 미터처럼
## 다양한 공격을 섞어 끊김 없이 맞힐수록 점수가 오르고, 같은 공격만 반복하면 덜 오른다.
## 피격당하면 크게 깎이고, 아무것도 못 맞히면 콤보가 끊기며 점수가 서서히 줄어든다.

signal rank_changed(rank: int, up: bool)

const TUNING: Tuning = preload("res://core/tuning.tres")
const RANKS := ["D", "C", "B", "A", "S", "SS"]
const NAMES := ["Dull", "Cool", "Blaze", "Ardent", "Searing", "Supernova"]
const THRESHOLDS := [0.0, 8.0, 20.0, 36.0, 58.0, 85.0]
const MAX_POINTS := 110.0

## 공격 종류별 기본 점수
const BASE := {
	&"bolt": 1.0, &"bolt_heavy": 3.0, &"blast": 1.5, &"pillar": 5.0,
	&"storm": 1.2, &"storm_final": 5.0, &"burst": 8.0,
	&"foxfire": 1.5, &"foxfire_heavy": 4.0, &"fox_rain": 0.8, &"fox_pillar": 6.0, &"fox_storm": 1.0, &"fox_burst": 8.0,
	&"fox_trail": 0.5,
}

var combo := 0
var max_combo := 0
var points := 0.0
var rank := 0
var best_rank := 0
var last_event := "" ## HUD에 잠깐 띄우는 문구 (예: "위치 타임!")
var last_event_time := 0.0

var _timer := 0.0
var _recent: Array[StringName] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


func reset_run() -> void:
	combo = 0
	max_combo = 0
	points = 0.0
	rank = 0
	best_rank = 0
	_recent.clear()


## 적을 맞혔을 때. airborne = 공중에 뜬 적을 맞힘(띄워 맞히기 보너스)
func register_hit(kind: StringName, airborne: bool) -> void:
	combo += 1
	max_combo = maxi(max_combo, combo)
	_timer = TUNING.combo_timeout
	var gain: float = BASE.get(kind, 1.0)
	# 다양성: 최근 4번 안에 없던 공격이면 1.6배, 같은 공격만 반복하면 0.6배
	if not _recent.has(kind):
		gain *= 1.6
	elif _recent.size() >= 3 and _recent[-1] == kind and _recent[-2] == kind:
		gain *= 0.6
	if airborne:
		gain += 1.0
	_recent.append(kind)
	if _recent.size() > 4:
		_recent.pop_front()
	_add(gain)


func bonus(text: String, amount: float) -> void:
	last_event = text
	last_event_time = Time.get_ticks_msec() / 1000.0
	_timer = TUNING.combo_timeout
	_add(amount)


func on_kill() -> void:
	_add(3.0)


func on_hurt() -> void:
	combo = 0
	points *= 0.35
	_update_rank()


## 콤보가 끊기기까지 남은 시간 비율 (HUD 막대용)
func combo_ratio() -> float:
	return clampf(_timer / TUNING.combo_timeout, 0.0, 1.0)


func rank_name() -> String:
	return RANKS[rank]


func progress_in_rank() -> float:
	var lo: float = THRESHOLDS[rank]
	var hi: float = THRESHOLDS[rank + 1] if rank + 1 < THRESHOLDS.size() else MAX_POINTS
	return clampf((points - lo) / maxf(hi - lo, 0.001), 0.0, 1.0)


func _add(amount: float) -> void:
	points = minf(points + amount, MAX_POINTS)
	_update_rank()


func _update_rank() -> void:
	var r := 0
	for i in THRESHOLDS.size():
		if points >= THRESHOLDS[i]:
			r = i
	if r != rank:
		var up := r > rank
		rank = r
		if up:
			best_rank = maxi(best_rank, rank)
			Sfx.play(&"rank_up", -2.0, 0.0)
		rank_changed.emit(rank, up)


func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.0001)
	if _timer > 0.0:
		_timer -= real
		if _timer <= 0.0:
			combo = 0
	elif points > 0.0:
		points = maxf(points - TUNING.style_decay * real, 0.0)
		_update_rank()
