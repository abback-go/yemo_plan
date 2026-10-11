extends Node
## 효과음을 녹음 파일 없이 코드로 합성한다 (docs/archive/sera/prototype.md 13.2절).
## 게임 시작 시 한 번 파형을 계산해 AudioStreamWAV로 만들어 두고, Sfx.play("shoot")처럼 재생한다.
## 각 소리는 여러 '층'(layer)을 더해 만든다. 층 하나 = 파형 + 주파수 변화 + 노이즈 + 필터 + 감쇠.

const RATE := 22050
const POOL_SIZE := 16
const FX_BLOCK := 64 # 빠른 합성기: 엔벨로프·음높이·필터 계수를 다시 계산하는 간격(샘플)
const NOISE_LEN := 32768 # 빠른 합성기가 함께 쓰는 잡음표 길이 (2의 거듭제곱)
const _FX_WAVES := {"sine": 0, "noise": 2, "saw": 3, "tri": 4, "square": 5}

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _rng := RandomNumberGenerator.new()
var _noise := PackedFloat32Array()
var _noise_pos := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 7
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		p.bus = &"SFX"
		add_child(p)
		_players.append(p)
	_build_all()


func play(sound: StringName, volume_db := 0.0, pitch_variation := 0.06) -> void:
	var stream: AudioStreamWAV = _streams.get(sound)
	if stream == null:
		push_warning("Sfx: unknown sound %s" % sound)
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = stream
	p.volume_db = -6.0 + volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	p.play()


## 음높이를 직접 정해 재생 (대화 목소리 삑삑음)
func play_pitch(sound: StringName, pitch: float, volume_db := 0.0) -> void:
	var stream: AudioStreamWAV = _streams.get(sound)
	if stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = stream
	p.volume_db = -6.0 + volume_db
	p.pitch_scale = clampf(pitch, 0.3, 3.0)
	p.play()


func has_sound(sound: StringName) -> bool:
	return _streams.has(sound)


# ─── 소리 목록 ──────────────────────────────────────────
# 층 키: wave(sine/square/saw/tri/noise), f0→f1 주파수(Hz), dur 길이, vol 크기, delay 시작 지연,
#        noise 노이즈 섞는 양, lp→lp1 저역 통과 필터(작을수록 둔탁), attack 상승 시간, decay 감쇠 곡선,
#        vib/vib_depth 떨림, crush 비트 깎기

func _build_all() -> void:
	_add(&"shoot", [
		{wave = "saw", f0 = 950, f1 = 240, dur = 0.11, vol = 0.32, lp = 0.5, decay = 2.0},
		{wave = "noise", dur = 0.08, vol = 0.30, lp = 0.35, decay = 3.0},
	])
	_add(&"shoot_heavy", [
		{wave = "saw", f0 = 720, f1 = 130, dur = 0.2, vol = 0.36, lp = 0.45, decay = 1.8},
		{wave = "noise", dur = 0.16, vol = 0.42, lp = 0.25, decay = 2.0},
		{wave = "sine", f0 = 170, f1 = 60, dur = 0.18, vol = 0.5, decay = 2.0},
	])
	_add(&"hit", [
		{wave = "noise", dur = 0.07, vol = 0.45, lp = 0.6, decay = 3.0},
		{wave = "sine", f0 = 230, f1 = 90, dur = 0.09, vol = 0.55, decay = 2.0},
	])
	_add(&"hit_heavy", [
		{wave = "noise", dur = 0.14, vol = 0.55, lp = 0.4, decay = 2.5},
		{wave = "sine", f0 = 190, f1 = 48, dur = 0.17, vol = 0.8, decay = 1.6},
		{wave = "square", f0 = 95, f1 = 40, dur = 0.1, vol = 0.18, lp = 0.3},
	])
	_add(&"dash", [
		{wave = "noise", dur = 0.18, vol = 0.42, lp = 0.12, lp1 = 0.6, attack = 0.03, decay = 1.5},
	])
	_add(&"jump", [
		{wave = "square", f0 = 300, f1 = 620, dur = 0.09, vol = 0.12, lp = 0.3, decay = 1.5},
	])
	_add(&"land", [
		{wave = "noise", dur = 0.06, vol = 0.3, lp = 0.18, decay = 3.0},
		{wave = "sine", f0 = 120, f1 = 60, dur = 0.06, vol = 0.3},
	])
	_add(&"hurt", [
		{wave = "saw", f0 = 520, f1 = 110, dur = 0.24, vol = 0.38, lp = 0.5, vib = 30, vib_depth = 0.08, crush = 3},
		{wave = "noise", dur = 0.15, vol = 0.35, lp = 0.5, decay = 2.0},
	])
	_add(&"pillar_warn", [
		{wave = "noise", dur = 0.35, vol = 0.38, lp = 0.06, lp1 = 0.18, attack = 0.25, decay = 0.6},
		{wave = "sine", f0 = 70, f1 = 120, dur = 0.35, vol = 0.3, attack = 0.3, decay = 0.5},
	])
	_add(&"pillar", [
		{wave = "noise", dur = 0.5, vol = 0.6, lp = 0.12, lp1 = 0.5, decay = 1.4},
		{wave = "saw", f0 = 130, f1 = 60, dur = 0.4, vol = 0.28, lp = 0.2},
		{wave = "sine", f0 = 95, f1 = 40, dur = 0.45, vol = 0.6, decay = 1.5},
	])
	_add(&"storm", [
		{wave = "noise", dur = 0.4, vol = 0.55, lp = 0.22, lp1 = 0.6, attack = 0.03, decay = 1.0},
		{wave = "saw", f0 = 210, f1 = 90, dur = 0.36, vol = 0.2, lp = 0.3},
	])
	_add(&"overload_pulse", [
		{wave = "sine", f0 = 110, f1 = 110, dur = 0.25, vol = 0.25, vib = 8, vib_depth = 0.06, attack = 0.04, decay = 1.0},
		{wave = "square", f0 = 55, f1 = 55, dur = 0.25, vol = 0.06, lp = 0.1, attack = 0.04},
	])
	_add(&"overload_warn", [
		{wave = "square", f0 = 220, f1 = 900, dur = 0.3, vol = 0.18, lp = 0.4, attack = 0.02, decay = 0.3},
		{wave = "sine", f0 = 440, f1 = 1800, dur = 0.3, vol = 0.14, decay = 0.3},
	])
	_add(&"explode", [
		{wave = "noise", dur = 0.9, vol = 0.8, lp = 0.3, lp1 = 0.04, decay = 1.2},
		{wave = "sine", f0 = 95, f1 = 28, dur = 0.8, vol = 0.9, decay = 1.3},
		{wave = "saw", f0 = 62, f1 = 30, dur = 0.5, vol = 0.28, lp = 0.1},
	])
	_add(&"charger_windup", [
		{wave = "saw", f0 = 70, f1 = 150, dur = 0.55, vol = 0.3, lp = 0.14, vib = 22, vib_depth = 0.1, attack = 0.2, decay = 0.4},
		{wave = "noise", dur = 0.55, vol = 0.25, lp = 0.05, attack = 0.3, decay = 0.5},
	])
	_add(&"charger_charge", [
		{wave = "noise", dur = 0.35, vol = 0.4, lp = 0.1, decay = 1.0},
		{wave = "square", f0 = 90, f1 = 60, dur = 0.3, vol = 0.14, lp = 0.2},
	])
	_add(&"sniper_aim", [
		{wave = "sine", f0 = 900, f1 = 1300, dur = 0.12, vol = 0.12, attack = 0.05, decay = 1.0},
	])
	_add(&"sniper_lock", [
		{wave = "square", f0 = 1800, f1 = 1800, dur = 0.05, vol = 0.14, lp = 0.6},
		{wave = "square", f0 = 1800, f1 = 1800, dur = 0.05, vol = 0.14, lp = 0.6, delay = 0.09},
	])
	_add(&"sniper_shot", [
		{wave = "square", f0 = 1300, f1 = 280, dur = 0.15, vol = 0.22, lp = 0.5, decay = 2.0},
		{wave = "noise", dur = 0.08, vol = 0.22, lp = 0.7, decay = 3.0},
	])
	_add(&"enemy_die", [
		{wave = "sine", f0 = 600, f1 = 1500, dur = 0.25, vol = 0.22, decay = 1.5},
		{wave = "noise", dur = 0.2, vol = 0.3, lp = 0.3, decay = 2.0},
		{wave = "tri", f0 = 1200, f1 = 2400, dur = 0.3, vol = 0.12, attack = 0.05},
	])
	_add(&"spawn", [
		{wave = "sine", f0 = 300, f1 = 900, dur = 0.45, vol = 0.18, vib = 12, vib_depth = 0.1, attack = 0.25, decay = 0.8},
		{wave = "noise", dur = 0.45, vol = 0.14, lp = 0.2, attack = 0.3, decay = 0.8},
	])
	_add(&"checkpoint", [
		{wave = "tri", f0 = 660, f1 = 660, dur = 0.2, vol = 0.25},
		{wave = "tri", f0 = 990, f1 = 990, dur = 0.35, vol = 0.22, delay = 0.1},
	])
	_add(&"door", [
		{wave = "noise", dur = 0.4, vol = 0.45, lp = 0.08, decay = 1.0},
		{wave = "square", f0 = 62, f1 = 45, dur = 0.35, vol = 0.18, lp = 0.15},
	])
	_add(&"clear", [
		{wave = "tri", f0 = 523, f1 = 523, dur = 0.16, vol = 0.22},
		{wave = "tri", f0 = 659, f1 = 659, dur = 0.16, vol = 0.22, delay = 0.11},
		{wave = "tri", f0 = 784, f1 = 784, dur = 0.16, vol = 0.22, delay = 0.22},
		{wave = "tri", f0 = 1046, f1 = 1046, dur = 0.4, vol = 0.24, delay = 0.33},
	])
	# v0.3 추가
	_add(&"rank_up", [
		{wave = "square", f0 = 660, f1 = 660, dur = 0.07, vol = 0.12, lp = 0.6},
		{wave = "square", f0 = 990, f1 = 990, dur = 0.07, vol = 0.12, lp = 0.6, delay = 0.06},
		{wave = "square", f0 = 1320, f1 = 1320, dur = 0.14, vol = 0.12, lp = 0.6, delay = 0.12},
	])
	_add(&"witch_time", [
		{wave = "sine", f0 = 880, f1 = 880, dur = 1.2, vol = 0.22, decay = 2.5},
		{wave = "sine", f0 = 1320, f1 = 1318, dur = 1.0, vol = 0.14, decay = 2.5, delay = 0.02},
		{wave = "tri", f0 = 2640, f1 = 2600, dur = 0.8, vol = 0.06, decay = 3.0},
		{wave = "noise", dur = 0.3, vol = 0.12, lp = 0.05, lp1 = 0.4, attack = 0.2, decay = 0.5},
	])
	_add(&"blast", [
		{wave = "noise", dur = 0.3, vol = 0.6, lp = 0.35, lp1 = 0.08, decay = 1.6},
		{wave = "sine", f0 = 140, f1 = 45, dur = 0.28, vol = 0.7, decay = 1.6},
	])
	_add(&"dash_jump", [
		{wave = "noise", dur = 0.25, vol = 0.4, lp = 0.15, lp1 = 0.7, attack = 0.02, decay = 1.3},
		{wave = "square", f0 = 260, f1 = 700, dur = 0.12, vol = 0.1, lp = 0.3},
	])
	_add(&"storm_final", [
		{wave = "noise", dur = 0.6, vol = 0.75, lp = 0.4, lp1 = 0.06, decay = 1.3},
		{wave = "sine", f0 = 110, f1 = 32, dur = 0.55, vol = 0.85, decay = 1.4},
		{wave = "saw", f0 = 80, f1 = 40, dur = 0.35, vol = 0.25, lp = 0.12},
	])
	_add(&"overheat", [
		{wave = "noise", dur = 0.4, vol = 0.3, lp = 0.5, lp1 = 0.2, attack = 0.05, decay = 1.0},
		{wave = "saw", f0 = 220, f1 = 440, dur = 0.3, vol = 0.12, lp = 0.3, decay = 1.0},
	])
	_add(&"blip", [
		{wave = "square", f0 = 520, f1 = 500, dur = 0.035, vol = 0.18, lp = 0.35, decay = 2.0},
	])
	_add(&"block", [
		{wave = "square", f0 = 1800, f1 = 1500, dur = 0.06, vol = 0.22, lp = 0.6, decay = 3.0},
		{wave = "noise", dur = 0.04, vol = 0.2, lp = 0.7, decay = 4.0},
	])
	_add(&"reveal", [
		{wave = "sine", f0 = 620, f1 = 1240, dur = 0.5, vol = 0.3, decay = 1.2, vib = 7.0, vib_depth = 0.02},
		{wave = "sine", f0 = 930, f1 = 1860, dur = 0.5, vol = 0.18, decay = 1.4, delay = 0.08},
	])
	_add(&"pickup", [
		{wave = "sine", f0 = 880, f1 = 880, dur = 0.12, vol = 0.3, decay = 1.5},
		{wave = "sine", f0 = 1320, f1 = 1320, dur = 0.2, vol = 0.3, decay = 1.5, delay = 0.08},
	])
	_add(&"ignite", [
		{wave = "noise", dur = 0.3, vol = 0.4, lp = 0.3, attack = 0.03, decay = 1.5},
		{wave = "sine", f0 = 200, f1 = 320, dur = 0.25, vol = 0.3, decay = 1.6},
	])
	_add(&"teach", [
		{wave = "sine", f0 = 660, f1 = 660, dur = 0.09, vol = 0.25, decay = 1.6},
		{wave = "sine", f0 = 990, f1 = 990, dur = 0.14, vol = 0.22, decay = 1.6, delay = 0.07},
	])
	_add(&"fox_transform", [
		{wave = "sine", f0 = 220, f1 = 880, dur = 0.7, vol = 0.4, decay = 0.8, vib = 6.0, vib_depth = 0.03},
		{wave = "noise", dur = 0.7, vol = 0.3, lp = 0.2, lp1 = 0.6, attack = 0.2, decay = 1.0},
		{wave = "sine", f0 = 1320, f1 = 1760, dur = 0.5, vol = 0.18, decay = 1.2, delay = 0.25},
	])
	_add(&"foxfire", [
		{wave = "sine", f0 = 900, f1 = 1400, dur = 0.12, vol = 0.24, decay = 2.0},
		{wave = "noise", dur = 0.1, vol = 0.18, lp = 0.5, decay = 3.0},
	])
	_add(&"fox_rain", [
		{wave = "noise", dur = 0.9, vol = 0.35, lp = 0.4, attack = 0.1, decay = 1.0},
		{wave = "sine", f0 = 1200, f1 = 600, dur = 0.8, vol = 0.15, decay = 1.2, vib = 9.0, vib_depth = 0.04},
	])
	_add(&"fox_storm", [
		{wave = "noise", dur = 0.8, vol = 0.45, lp = 0.25, lp1 = 0.7, attack = 0.05, decay = 1.0},
		{wave = "saw", f0 = 110, f1 = 440, dur = 0.7, vol = 0.22, lp = 0.3, decay = 1.2},
		{wave = "sine", f0 = 880, f1 = 1760, dur = 0.5, vol = 0.18, decay = 1.4, delay = 0.2},
	])
	_add(&"fox_end", [
		{wave = "sine", f0 = 880, f1 = 330, dur = 0.5, vol = 0.3, decay = 1.2},
		{wave = "noise", dur = 0.4, vol = 0.2, lp = 0.3, decay = 2.0},
	])
	_add(&"double_jump", [
		{wave = "sine", f0 = 500, f1 = 1000, dur = 0.14, vol = 0.25, decay = 1.8},
		{wave = "noise", dur = 0.1, vol = 0.15, lp = 0.6, decay = 3.0},
	])
	_add(&"window", [
		{wave = "sine", f0 = 740, f1 = 740, dur = 0.6, vol = 0.22, decay = 1.0, vib = 5.0, vib_depth = 0.03},
		{wave = "sine", f0 = 1110, f1 = 1110, dur = 0.6, vol = 0.16, decay = 1.0, delay = 0.1},
		{wave = "sine", f0 = 1480, f1 = 1480, dur = 0.5, vol = 0.12, decay = 1.0, delay = 0.2},
	])
	_add(&"potion", [
		{wave = "sine", f0 = 300, f1 = 520, dur = 0.3, vol = 0.3, decay = 1.4, vib = 14.0, vib_depth = 0.06},
		{wave = "noise", dur = 0.2, vol = 0.12, lp = 0.3, decay = 2.0, delay = 0.1},
	])
	_add(&"roar", [
		{wave = "saw", f0 = 140, f1 = 70, dur = 0.9, vol = 0.4, lp = 0.2, attack = 0.08, decay = 1.0, vib = 18.0, vib_depth = 0.08},
		{wave = "noise", dur = 0.9, vol = 0.35, lp = 0.15, attack = 0.1, decay = 1.0},
	])
	_add(&"slam", [
		{wave = "sine", f0 = 110, f1 = 40, dur = 0.35, vol = 0.6, decay = 1.6},
		{wave = "noise", dur = 0.3, vol = 0.45, lp = 0.2, decay = 2.0},
	])
	_add(&"whoosh", [
		{wave = "noise", dur = 0.25, vol = 0.3, lp = 0.2, lp1 = 0.6, attack = 0.08, decay = 1.5},
	])
	_add(&"swing", [
		{wave = "noise", dur = 0.18, vol = 0.3, lp = 0.5, lp1 = 0.2, decay = 1.8},
		{wave = "saw", f0 = 300, f1 = 120, dur = 0.15, vol = 0.12, lp = 0.3, decay = 2.0},
	])
	_add(&"page", [
		{wave = "noise", dur = 0.08, vol = 0.22, lp = 0.7, decay = 3.0},
	])
	_add(&"giggle", [
		{wave = "sine", f0 = 900, f1 = 1100, dur = 0.07, vol = 0.18, decay = 1.6},
		{wave = "sine", f0 = 950, f1 = 1150, dur = 0.07, vol = 0.16, decay = 1.6, delay = 0.1},
		{wave = "sine", f0 = 1000, f1 = 1250, dur = 0.08, vol = 0.14, decay = 1.6, delay = 0.2},
	])
	_add(&"squish", [
		{wave = "sine", f0 = 200, f1 = 90, dur = 0.2, vol = 0.35, decay = 1.5, vib = 20.0, vib_depth = 0.1},
	])
	_add(&"growl", [
		{wave = "saw", f0 = 90, f1 = 70, dur = 0.5, vol = 0.3, lp = 0.15, decay = 1.2, vib = 22.0, vib_depth = 0.1},
	])
	_add(&"chain", [
		{wave = "noise", dur = 0.15, vol = 0.3, lp = 0.8, decay = 3.0},
		{wave = "square", f0 = 1400, f1 = 1300, dur = 0.08, vol = 0.1, lp = 0.6, decay = 3.0, delay = 0.03},
	])
	_add(&"crumble", [
		{wave = "noise", dur = 0.6, vol = 0.45, lp = 0.15, decay = 1.2},
		{wave = "sine", f0 = 80, f1 = 40, dur = 0.5, vol = 0.4, decay = 1.4},
	])
	_add(&"ui_move", [
		{wave = "square", f0 = 880, f1 = 880, dur = 0.04, vol = 0.1, lp = 0.5},
	])
	_add(&"ui_ok", [
		{wave = "square", f0 = 660, f1 = 660, dur = 0.06, vol = 0.13, lp = 0.5},
		{wave = "square", f0 = 990, f1 = 990, dur = 0.1, vol = 0.13, lp = 0.5, delay = 0.06},
	])
	_build_chapters()


# ─── 2~5장 추가 소리 (빠른 합성기 _add_fast, 키 설명은 _add_fast 위 주석) ─────────
func _build_chapters() -> void:
	# 검 · 창 · 활 (레오니, 아우렐리아, 엘라리엔)
	_add_fast(&"sword_slash", [
		{wave = "noise", dur = 0.18, vol = 0.6, bp = 3800.0, bp1 = 1100.0, q = 0.6, attack = 0.012, decay = 1.6},
		{wave = "noise", dur = 0.14, vol = 0.22, lp = 0.25, attack = 0.01, decay = 2.0},
		{wave = "sine", f0 = 2600.0, f1 = 2300.0, fm = 1.41, fm_i = 1.4, fm_i1 = 0.2, dur = 0.14, vol = 0.07, tau = 0.04},
	])
	_add_fast(&"sword_clash", [
		{wave = "sine", f0 = 1650.0, fm = 1.47, fm_i = 3.0, fm_i1 = 0.3, dur = 0.5, vol = 0.32, tau = 0.13},
		{wave = "sine", f0 = 2480.0, fm = 2.09, fm_i = 2.0, fm_i1 = 0.2, dur = 0.38, vol = 0.18, tau = 0.09},
		{wave = "sine", f0 = 3730.0, dur = 0.3, vol = 0.06, tau = 0.1},
		{wave = "noise", dur = 0.07, vol = 0.55, bp = 4200.0, q = 0.7, decay = 3.0},
	])
	_add_fast(&"parry", [
		{wave = "sine", f0 = 2093.0, fm = 2.76, fm_i = 1.0, fm_i1 = 0.0, dur = 0.6, vol = 0.26, tau = 0.2},
		{wave = "sine", f0 = 3136.0, dur = 0.4, vol = 0.12, tau = 0.12, delay = 0.004},
		{wave = "noise", dur = 0.03, vol = 0.4, bp = 4400.0, q = 0.5, decay = 3.0},
	])
	_add_fast(&"sword_wave", [
		{wave = "noise", dur = 0.38, vol = 0.65, bp = 350.0, bp1 = 2600.0, q = 0.35, attack = 0.04, decay = 1.3},
		{wave = "sine", f0 = 170.0, f1 = 70.0, dur = 0.26, vol = 0.4, decay = 1.6},
		{wave = "saw", f0 = 220.0, f1 = 110.0, dur = 0.26, vol = 0.1, lp = 0.25, decay = 1.4},
	])
	_add_fast(&"spear", [
		{wave = "noise", dur = 0.16, vol = 0.55, bp = 1500.0, bp1 = 4200.0, q = 0.45, attack = 0.01, decay = 1.8},
		{wave = "sine", f0 = 1250.0, f1 = 1650.0, fm = 1.5, fm_i = 0.8, dur = 0.14, vol = 0.1, tau = 0.05, delay = 0.03},
		{wave = "sine", f0 = 220.0, f1 = 110.0, dur = 0.1, vol = 0.28, decay = 2.0},
	])
	_add_fast(&"arrow_shot", [
		{wave = "tri", f0 = 190.0, f1 = 120.0, dur = 0.14, vol = 0.3, tau = 0.04},
		{wave = "noise", dur = 0.13, vol = 0.45, bp = 2500.0, bp1 = 4400.0, q = 0.5, attack = 0.005, decay = 2.0},
		{wave = "sine", f0 = 900.0, f1 = 500.0, dur = 0.05, vol = 0.12, decay = 2.0},
	])
	_add_fast(&"arrow_hit", [
		{wave = "noise", dur = 0.08, vol = 0.5, lp = 0.35, decay = 3.0},
		{wave = "sine", f0 = 260.0, f1 = 120.0, dur = 0.1, vol = 0.5, decay = 2.0},
		{wave = "tri", f0 = 720.0, f1 = 640.0, dur = 0.12, vol = 0.1, vib = 45.0, vib_depth = 0.05, tau = 0.04, delay = 0.01},
	])
	_add_fast(&"bow_draw", [
		{wave = "saw", f0 = 95.0, f1 = 150.0, dur = 0.5, vol = 0.3, lp = 0.2, am = 26.0, am_depth = 0.7, attack = 0.15, decay = 0.6},
		{wave = "noise", dur = 0.5, vol = 0.28, bp = 1300.0, q = 0.3, am = 34.0, am_depth = 0.85, attack = 0.2, decay = 0.7},
	])
	# 신성한 힘 · 종 (루멘 신전)
	_add_fast(&"holy_charge", [
		{wave = "saw", f0 = 220.0, f1 = 440.0, curve = "exp", dur = 0.9, vol = 0.42, bp = 800.0, bp1 = 1200.0, q = 0.35,
			attack = 0.6, decay = 0.3, vib = 5.5, vib_depth = 0.012},
		{wave = "saw", f0 = 330.0, f1 = 660.0, curve = "exp", dur = 0.9, vol = 0.28, bp = 800.0, bp1 = 1200.0, q = 0.35,
			attack = 0.6, decay = 0.3, vib = 4.8, vib_depth = 0.012},
		{wave = "noise", dur = 0.9, vol = 0.42, bp = 1200.0, bp1 = 2200.0, q = 0.5, attack = 0.7, decay = 0.4},
		{wave = "sine", f0 = 880.0, f1 = 1760.0, curve = "exp", dur = 0.9, vol = 0.1, attack = 0.7, decay = 0.5},
	], 11025)
	_add_fast(&"holy_hit", [
		{wave = "noise", dur = 0.22, vol = 0.42, lp = 0.5, decay = 2.5},
		{wave = "sine", f0 = 1320.0, fm = 2.0, fm_i = 2.0, fm_i1 = 0.0, dur = 0.55, vol = 0.2, tau = 0.15},
		{wave = "sine", f0 = 1980.0, dur = 0.45, vol = 0.09, tau = 0.12, delay = 0.01},
		{wave = "sine", f0 = 180.0, f1 = 70.0, dur = 0.26, vol = 0.42, decay = 1.8},
	])
	_add_fast(&"bell", [
		{wave = "sine", f0 = 196.0, fm = 1.4, fm_i = 2.5, fm_i1 = 0.3, dur = 2.4, vol = 0.42, tau = 0.8},
		{wave = "sine", f0 = 98.0, f1 = 97.6, dur = 2.4, vol = 0.28, tau = 1.1},
		{wave = "sine", f0 = 235.0, dur = 1.6, vol = 0.14, tau = 0.5},
		{wave = "noise", dur = 0.04, vol = 0.3, lp = 0.3, decay = 2.0},
	], 11025)
	_add_fast(&"bell_small", [
		{wave = "sine", f0 = 1318.0, fm = 2.4, fm_i = 1.2, fm_i1 = 0.1, dur = 0.8, vol = 0.24, tau = 0.28},
		{wave = "sine", f0 = 1582.0, dur = 0.55, vol = 0.09, tau = 0.18},
		{wave = "sine", f0 = 659.0, dur = 0.8, vol = 0.08, tau = 0.35},
	])
	# 별 (리라)
	_add_fast(&"star_twinkle", [
		{wave = "sine", f0 = 2637.0, dur = 0.25, vol = 0.18, tau = 0.08},
		{wave = "sine", f0 = 3520.0, dur = 0.24, vol = 0.14, tau = 0.07, delay = 0.06},
		{wave = "sine", f0 = 4186.0, dur = 0.2, vol = 0.1, tau = 0.06, delay = 0.12},
	])
	_add_fast(&"star_burst", [
		{wave = "noise", dur = 0.6, vol = 0.5, bp = 3200.0, bp1 = 700.0, q = 0.6, decay = 1.5},
		{wave = "sine", f0 = 2000.0, f1 = 3000.0, fm = 1.5, fm_i = 1.0, fm_i1 = 0.0, dur = 0.5, vol = 0.13, tau = 0.15},
		{wave = "sine", f0 = 150.0, f1 = 60.0, dur = 0.25, vol = 0.42, decay = 1.6},
		{wave = "tri", f0 = 1568.0, dur = 0.4, vol = 0.08, tau = 0.12, vib = 18.0, vib_depth = 0.03, delay = 0.1},
	])
	# 여우불 날개 · 바람 · 결계 (세라의 새 능력)
	_add_fast(&"glide", [ # 처음과 끝이 0 이라 이어 붙여 반복해도 '딸깍' 없음
		{wave = "noise", dur = 0.5, vol = 0.6, lp = 0.15, lp1 = 0.25, attack = 0.25, decay = 1.0, am = 11.0, am_depth = 0.6},
		{wave = "noise", dur = 0.5, vol = 0.32, bp = 900.0, q = 0.5, attack = 0.25, decay = 1.0, am = 11.0, am_depth = 0.5},
	], 11025)
	_add_fast(&"updraft", [
		{wave = "noise", dur = 0.75, vol = 0.6, bp = 300.0, bp1 = 1600.0, q = 0.4, attack = 0.25, decay = 0.9},
		{wave = "noise", dur = 0.75, vol = 0.3, lp = 0.1, lp1 = 0.25, attack = 0.2, decay = 1.0},
	], 11025)
	_add_fast(&"ward", [
		{wave = "noise", dur = 0.5, vol = 0.45, lp = 0.2, lp1 = 0.5, attack = 0.05, decay = 1.0},
		{wave = "noise", dur = 0.5, vol = 0.22, bp = 1800.0, q = 0.4, am = 25.0, am_depth = 0.5, attack = 0.05, decay = 1.2},
		{wave = "sine", f0 = 200.0, f1 = 330.0, dur = 0.45, vol = 0.28, decay = 1.4},
		{wave = "sine", f0 = 660.0, f1 = 990.0, dur = 0.35, vol = 0.1, decay = 1.5, delay = 0.05},
	], 11025)
	_add_fast(&"reflect", [
		{wave = "sine", f0 = 1760.0, fm = 1.5, fm_i = 1.5, fm_i1 = 0.0, dur = 0.3, vol = 0.26, tau = 0.08},
		{wave = "noise", dur = 0.26, vol = 0.32, lp = 0.4, attack = 0.02, decay = 1.6, delay = 0.03},
		{wave = "sine", f0 = 880.0, f1 = 1320.0, dur = 0.2, vol = 0.12, decay = 1.5},
	])
	_add_fast(&"phoenix_cry", [
		{wave = "saw", f0 = 1300.0, f1 = 2500.0, curve = "exp", dur = 0.28, vol = 0.34, bp = 2600.0, q = 0.5,
			attack = 0.03, decay = 0.4, vib = 32.0, vib_depth = 0.025},
		{wave = "saw", f0 = 2500.0, f1 = 1400.0, curve = "exp", dur = 0.6, vol = 0.34, bp = 2400.0, bp1 = 1600.0, q = 0.5,
			attack = 0.02, decay = 1.3, vib = 28.0, vib_depth = 0.03, delay = 0.24},
		{wave = "sine", f0 = 2600.0, f1 = 1800.0, dur = 0.7, vol = 0.1, decay = 1.2, delay = 0.2},
		{wave = "noise", dur = 0.9, vol = 0.45, lp = 0.35, attack = 0.05, decay = 1.0, am = 17.0, am_depth = 0.45},
	])
	_add_fast(&"warp", [
		{wave = "sine", f0 = 400.0, f1 = 1600.0, curve = "exp", fm = 0.5, fm_i = 2.0, fm_i1 = 0.5, dur = 0.5, vol = 0.22,
			attack = 0.1, decay = 1.0, am = 16.0, am_depth = 0.5},
		{wave = "sine", f0 = 1600.0, f1 = 400.0, curve = "exp", dur = 0.5, vol = 0.12, attack = 0.1, decay = 1.0, am = 22.0, am_depth = 0.5},
		{wave = "noise", dur = 0.5, vol = 0.15, bp = 3000.0, q = 0.5, attack = 0.2, decay = 1.0},
	])
	# 운석 · 거신 · 하늘 (재앙)
	_add_fast(&"meteor_fall", [
		{wave = "sine", f0 = 2400.0, f1 = 450.0, curve = "exp", dur = 1.1, vol = 0.2, attack = 0.3, decay = 0.35, vib = 7.0, vib_depth = 0.012},
		{wave = "noise", dur = 1.1, vol = 0.45, bp = 2200.0, bp1 = 500.0, q = 0.35, attack = 0.4, decay = 0.5},
		{wave = "noise", dur = 1.1, vol = 0.25, lp = 0.05, lp1 = 0.15, attack = 0.6, decay = 0.4},
	], 11025)
	_add_fast(&"meteor_impact", [
		{wave = "sine", f0 = 75.0, f1 = 26.0, dur = 1.4, vol = 0.78, decay = 1.3},
		{wave = "sine", f0 = 140.0, f1 = 60.0, dur = 0.35, vol = 0.34, decay = 1.8},
		{wave = "noise", dur = 1.6, vol = 0.68, lp = 0.5, lp1 = 0.04, decay = 1.4},
		{wave = "saw", f0 = 55.0, f1 = 30.0, dur = 0.8, vol = 0.26, lp = 0.08},
		{wave = "noise", dur = 0.15, vol = 0.38, bp = 2200.0, q = 0.6, decay = 2.5},
	], 11025)
	_add_fast(&"colossus_step", [
		{wave = "sine", f0 = 55.0, f1 = 28.0, dur = 1.0, vol = 0.8, decay = 1.6},
		{wave = "sine", f0 = 120.0, f1 = 60.0, dur = 0.3, vol = 0.34, decay = 2.0},
		{wave = "noise", dur = 0.6, vol = 0.5, lp = 0.08, decay = 1.6},
		{wave = "noise", dur = 1.0, vol = 0.28, bp = 1500.0, q = 0.5, am = 23.0, am_depth = 0.9, attack = 0.05, decay = 1.2, delay = 0.08},
	], 11025)
	_add_fast(&"sky_crack", [
		{wave = "sine", f0 = 3200.0, fm = 1.73, fm_i = 4.0, fm_i1 = 0.0, dur = 0.35, vol = 0.26, tau = 0.1},
		{wave = "sine", f0 = 4700.0, f1 = 4500.0, fm = 2.3, fm_i = 2.0, fm_i1 = 0.0, dur = 0.3, vol = 0.12, tau = 0.08, delay = 0.04},
		{wave = "noise", dur = 0.12, vol = 0.5, bp = 4400.0, q = 0.4, decay = 3.0},
		{wave = "noise", dur = 1.15, vol = 0.6, lp = 0.06, attack = 0.1, decay = 0.8, delay = 0.05},
		{wave = "sine", f0 = 48.0, f1 = 34.0, dur = 1.1, vol = 0.4, attack = 0.15, decay = 1.0, delay = 0.05},
	])
	# 도시 · 자연
	_add_fast(&"crowd", [
		{wave = "noise", dur = 1.5, vol = 0.55, bp = 520.0, q = 0.5, am = 4.3, am_depth = 0.7, attack = 0.25, decay = 0.4},
		{wave = "noise", dur = 1.5, vol = 0.38, bp = 1150.0, q = 0.5, am = 5.9, am_depth = 0.7, attack = 0.25, decay = 0.4},
		{wave = "saw", f0 = 135.0, f1 = 128.0, dur = 1.5, vol = 0.14, bp = 650.0, q = 0.6, am = 3.7, am_depth = 0.85,
			vib = 5.0, vib_depth = 0.04, attack = 0.3, decay = 0.4},
		{wave = "saw", f0 = 205.0, f1 = 196.0, dur = 1.5, vol = 0.12, bp = 950.0, q = 0.6, am = 4.9, am_depth = 0.85,
			vib = 4.3, vib_depth = 0.05, attack = 0.3, decay = 0.4},
	], 11025)
	_add_fast(&"wind", [
		{wave = "noise", dur = 1.6, vol = 0.7, bp = 450.0, bp1 = 850.0, q = 0.3, am = 0.9, am_depth = 0.35, attack = 0.45, decay = 0.7},
		{wave = "noise", dur = 1.6, vol = 0.38, lp = 0.06, attack = 0.4, decay = 0.6},
	], 11025)
	_add_fast(&"heartbeat", [
		{wave = "sine", f0 = 75.0, f1 = 48.0, dur = 0.16, vol = 0.5, decay = 2.0},
		{wave = "sine", f0 = 150.0, f1 = 95.0, dur = 0.1, vol = 0.19, decay = 2.0},
		{wave = "noise", dur = 0.08, vol = 0.19, lp = 0.08, decay = 2.5},
		{wave = "sine", f0 = 85.0, f1 = 52.0, dur = 0.14, vol = 0.38, decay = 2.0, delay = 0.22},
		{wave = "sine", f0 = 160.0, f1 = 100.0, dur = 0.09, vol = 0.14, decay = 2.0, delay = 0.22},
	], 11025)
	# 퀘스트 · 메뉴 · 마법 성장
	_add_fast(&"quest", [
		{wave = "sine", f0 = 1175.0, fm = 2.0, fm_i = 0.6, fm_i1 = 0.0, dur = 0.3, vol = 0.22, tau = 0.12},
		{wave = "sine", f0 = 1568.0, fm = 2.0, fm_i = 0.6, fm_i1 = 0.0, dur = 0.32, vol = 0.2, tau = 0.13, delay = 0.09},
		{wave = "sine", f0 = 2349.0, fm = 2.0, fm_i = 0.6, fm_i1 = 0.0, dur = 0.5, vol = 0.18, tau = 0.2, delay = 0.18},
	])
	_add_fast(&"quest_done", [
		{wave = "tri", f0 = 1047.0, dur = 0.14, vol = 0.18, tau = 0.08},
		{wave = "tri", f0 = 1319.0, dur = 0.14, vol = 0.18, tau = 0.08, delay = 0.08},
		{wave = "tri", f0 = 1568.0, dur = 0.14, vol = 0.18, tau = 0.08, delay = 0.16},
		{wave = "sine", f0 = 2093.0, fm = 2.0, fm_i = 0.5, fm_i1 = 0.0, dur = 0.55, vol = 0.22, tau = 0.22, delay = 0.24},
		{wave = "sine", f0 = 2637.0, dur = 0.5, vol = 0.1, tau = 0.2, delay = 0.24},
	])
	_add_fast(&"levelup", [
		{wave = "sine", f0 = 880.0, f1 = 1760.0, curve = "exp", dur = 0.35, vol = 0.22, decay = 1.2, vib = 20.0, vib_depth = 0.02},
		{wave = "tri", f0 = 1760.0, f1 = 3520.0, curve = "exp", dur = 0.35, vol = 0.12, decay = 1.4, delay = 0.1},
		{wave = "sine", f0 = 2637.0, dur = 0.4, vol = 0.14, tau = 0.12, am = 30.0, am_depth = 0.5, delay = 0.25},
	])
	_add_fast(&"menu_open", [
		{wave = "noise", dur = 0.12, vol = 0.22, bp = 1500.0, bp1 = 3500.0, q = 0.5, attack = 0.03, decay = 1.5},
		{wave = "sine", f0 = 660.0, f1 = 990.0, dur = 0.08, vol = 0.18, decay = 1.5},
		{wave = "sine", f0 = 1320.0, dur = 0.1, vol = 0.12, decay = 1.6, delay = 0.05},
	])
	_add_fast(&"menu_close", [
		{wave = "noise", dur = 0.12, vol = 0.2, bp = 3200.0, bp1 = 1200.0, q = 0.5, attack = 0.01, decay = 1.6},
		{wave = "sine", f0 = 990.0, f1 = 620.0, dur = 0.09, vol = 0.18, decay = 1.5},
	])
	_add_fast(&"magic_learn", [
		{wave = "sine", f0 = 110.0, fm = 2.0, fm_i = 1.5, fm_i1 = 0.3, dur = 1.4, vol = 0.32, attack = 0.15, decay = 0.9, vib = 4.0, vib_depth = 0.01},
		{wave = "sine", f0 = 165.0, fm = 1.0, fm_i = 0.8, fm_i1 = 0.1, dur = 1.4, vol = 0.2, attack = 0.2, decay = 1.0},
		{wave = "sine", f0 = 440.0, f1 = 880.0, curve = "exp", dur = 1.2, vol = 0.1, attack = 0.5, decay = 0.8, am = 6.0, am_depth = 0.4},
		{wave = "noise", dur = 1.2, vol = 0.1, bp = 2000.0, q = 0.4, attack = 0.5, decay = 0.8},
		{wave = "sine", f0 = 1320.0, f1 = 1760.0, dur = 0.8, vol = 0.04, attack = 0.4, decay = 1.0, delay = 0.4},
	], 11025)
	_build_eska()


# ─── 에스카 시제품 (proto/eska) ─────────────────────────
# 손짓 한 번에 공간이 찢어지는 마녀: 칼 소리 대신 '튕김 → 찢김 → 낮은 울림'.
func _build_eska() -> void:
	_add_fast(&"es_snap", [ # 손가락 튕김: 짧고 마른 딱 + 아주 작은 울림
		{wave = "noise", dur = 0.035, vol = 0.55, bp = 2700.0, q = 0.45, decay = 3.0},
		{wave = "sine", f0 = 1900.0, f1 = 1300.0, dur = 0.05, vol = 0.12, tau = 0.012},
		{wave = "sine", f0 = 240.0, f1 = 160.0, dur = 0.06, vol = 0.18, tau = 0.02},
	])
	_add_fast(&"es_slash", [ # 공간을 찢는 참격: 위로 쓸려 올라가는 '쉬익' + 낮은 무게 + 희미한 쇳빛
		{wave = "noise", dur = 0.22, vol = 0.55, bp = 700.0, bp1 = 3400.0, q = 0.35, attack = 0.008, decay = 1.5},
		{wave = "sine", f0 = 150.0, f1 = 55.0, dur = 0.2, vol = 0.32, tau = 0.07},
		{wave = "sine", f0 = 1250.0, fm = 1.41, fm_i = 1.2, fm_i1 = 0.1, dur = 0.16, vol = 0.05, tau = 0.05, delay = 0.02},
	])
	_add_fast(&"es_slash_big", [ # 큰 참격(마무리·천열 끝): 길게 찢기 + 깊은 울림
		{wave = "noise", dur = 0.42, vol = 0.6, bp = 350.0, bp1 = 2600.0, q = 0.3, attack = 0.015, decay = 1.3},
		{wave = "sine", f0 = 110.0, f1 = 38.0, dur = 0.4, vol = 0.5, tau = 0.14},
		{wave = "noise", dur = 0.35, vol = 0.25, lp = 0.06, attack = 0.02, decay = 1.2},
		{wave = "sine", f0 = 880.0, fm = 2.01, fm_i = 1.5, fm_i1 = 0.0, dur = 0.3, vol = 0.05, tau = 0.09, delay = 0.04},
	], 11025)
	_add_fast(&"es_tear", [ # 공간 틈이 갈라짐: 지지직 떨리는 잡음 + 떨어지는 음
		{wave = "noise", dur = 0.2, vol = 0.45, bp = 1900.0, bp1 = 500.0, q = 0.55, am = 55.0, am_depth = 0.7, decay = 1.4},
		{wave = "sine", f0 = 620.0, f1 = 140.0, curve = "exp", dur = 0.18, vol = 0.14, decay = 1.6},
	])
	_add_fast(&"es_blink", [ # 순간이동: 빨려 들어가는 바람 + 위로 튀는 음 + 틈 소리
		{wave = "noise", dur = 0.16, vol = 0.5, lp = 0.05, lp1 = 0.7, attack = 0.09, decay = 1.0},
		{wave = "sine", f0 = 320.0, f1 = 1500.0, curve = "exp", dur = 0.12, vol = 0.1, decay = 1.4},
		{wave = "noise", dur = 0.12, vol = 0.3, bp = 2400.0, q = 0.5, am = 70.0, am_depth = 0.6, decay = 2.0, delay = 0.1},
	])
	_add_fast(&"es_air_step", [ # 허공을 밟음: 유리 같은 맑은 '팅' + 짧은 바람
		{wave = "sine", f0 = 720.0, f1 = 1080.0, fm = 2.0, fm_i = 0.8, fm_i1 = 0.1, dur = 0.18, vol = 0.2, tau = 0.05},
		{wave = "noise", dur = 0.08, vol = 0.25, bp = 2200.0, q = 0.5, decay = 2.5},
	])
	_add_fast(&"es_glide", [ # 미끄러지듯 떠오름: 부드럽게 부푸는 바람
		{wave = "noise", dur = 0.3, vol = 0.5, bp = 450.0, bp1 = 1400.0, q = 0.4, attack = 0.05, decay = 1.3},
	], 11025)


func _add(sound: StringName, layers: Array) -> void:
	var length := 0.0
	for l in layers:
		length = maxf(length, l.get("delay", 0.0) + l.dur)
	var n := int(length * RATE) + 1
	var mix := PackedFloat32Array()
	mix.resize(n)
	for l in layers:
		_render_layer(mix, l)

	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		data.encode_s16(i * 2, int(clampf(mix[i], -1.0, 1.0) * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	_streams[sound] = s


func _render_layer(mix: PackedFloat32Array, l: Dictionary) -> void:
	var wave: String = l.get("wave", "sine")
	var dur: float = l.dur
	var f0: float = l.get("f0", 440.0)
	var f1: float = l.get("f1", f0)
	var vol: float = l.get("vol", 0.3)
	var noise_mix: float = l.get("noise", 0.0)
	var lp0: float = l.get("lp", 1.0)
	var lp1: float = l.get("lp1", lp0)
	var attack: float = l.get("attack", 0.002)
	var decay: float = l.get("decay", 1.0)
	var vib: float = l.get("vib", 0.0)
	var vib_depth: float = l.get("vib_depth", 0.0)
	var crush: int = l.get("crush", 1)
	var start := int(l.get("delay", 0.0) * RATE)
	var count := int(dur * RATE)

	var phase := 0.0
	var filtered := 0.0
	var held := 0.0
	for i in count:
		var t := float(i) / RATE
		var k := t / dur
		var f := lerpf(f0, f1, k * k * (3.0 - 2.0 * k)) # 부드러운 주파수 변화
		if vib > 0.0:
			f *= 1.0 + sin(TAU * vib * t) * vib_depth
		phase = fmod(phase + f / RATE, 1.0)

		var v := 0.0
		match wave:
			"sine": v = sin(TAU * phase)
			"square": v = 1.0 if phase < 0.5 else -1.0
			"saw": v = phase * 2.0 - 1.0
			"tri": v = 1.0 - absf(phase * 4.0 - 2.0)
			_: v = _rng.randf_range(-1.0, 1.0)
		if noise_mix > 0.0:
			v = lerpf(v, _rng.randf_range(-1.0, 1.0), noise_mix)

		# 1차 저역 통과 필터: 값이 작을수록 고음이 깎여 둔탁해짐
		var a := lerpf(lp0, lp1, k)
		filtered += a * (v - filtered)
		v = filtered

		if crush > 1:
			if i % crush == 0:
				held = v
			v = held

		var env := minf(t / attack, 1.0) * pow(1.0 - k, decay)
		var idx := start + i
		if idx < mix.size():
			mix[idx] += v * env * vol


# ─── 빠른 합성기 (2~5장 추가 소리) ─────────────────────────
# 기존 _add 와 같은 층 키(wave, f0→f1, dur, vol, delay, lp→lp1, attack, decay, vib/vib_depth)를 쓰되,
# 엔벨로프·음높이·필터 계수는 FX_BLOCK(64) 샘플마다 한 번만 계산하고 그 사이는 직선으로 이어 붙인다.
# 샘플마다 하는 일이 적어 기존 합성기보다 3~4배 빠르다 (게임 시작 시간이 늘지 않게). 기존 소리는 그대로 _add.
# 추가 키: fm 변조파 주파수 비, fm_i→fm_i1 변조 지수 (쇠·종·유리처럼 비조화 배음이 있는 소리)
#          tau 지수 감쇠 시간(초, 주면 decay 대신 씀) · curve = "exp" 음높이를 지수로 바꿈(떨어지는 휘파람)
#          bp→bp1 대역 통과 중심(Hz) · q 대역 폭(작을수록 날카롭게 공명) (쉭·바람·웅성거림·모음)
#          am 진폭 떨림 빠르기(Hz) · am_depth 떨림 깊이(0~1) (날갯짓·불꽃·사람 말소리)
# 지원하지 않는 키: noise, crush (기존 합성기 전용)
# rate: 소리 전체의 샘플레이트. 낮은 소리(쿵·바람·종)는 11025 로 계산량을 절반으로 줄인다.
# lp 는 기존처럼 '22050 Hz 기준 1차 필터 계수'로 적고, 다른 샘플레이트에서도 같은 차단 주파수가 되게 바꿔 쓴다.
func _add_fast(sound: StringName, layers: Array, rate := RATE) -> void:
	if _noise.is_empty():
		var r := RandomNumberGenerator.new()
		r.seed = 23
		_noise.resize(NOISE_LEN)
		for i in NOISE_LEN:
			_noise[i] = r.randf_range(-1.0, 1.0)
	var length := 0.0
	for l in layers:
		length = maxf(length, l.get("delay", 0.0) + l.dur)
	var mix := PackedFloat32Array()
	mix.resize(int(length * rate) + 1)
	for l in layers:
		_render_fast(mix, l, rate)
	# 32비트 float WAV 로 감싸 엔진이 한 번에 16비트로 바꾸게 한다 (샘플마다 encode 하는 것보다 훨씬 빠름)
	var s := AudioStreamWAV.load_from_buffer(_wav_bytes(mix, rate))
	if s == null:
		s = AudioStreamWAV.new()
		var data := PackedByteArray()
		data.resize(mix.size() * 2)
		for i in mix.size():
			data.encode_s16(i * 2, int(clampf(mix[i], -1.0, 1.0) * 32767.0))
		s.format = AudioStreamWAV.FORMAT_16_BITS
		s.mix_rate = rate
		s.stereo = false
		s.data = data
	_streams[sound] = s


func _wav_bytes(mix: PackedFloat32Array, rate: int) -> PackedByteArray:
	var body := mix.to_byte_array()
	var h := PackedByteArray()
	h.resize(44)
	h.encode_u32(0, 0x46464952) # "RIFF"
	h.encode_u32(4, 36 + body.size())
	h.encode_u32(8, 0x45564157) # "WAVE"
	h.encode_u32(12, 0x20746d66) # "fmt "
	h.encode_u32(16, 16)
	h.encode_u16(20, 3) # IEEE float
	h.encode_u16(22, 1) # 모노
	h.encode_u32(24, rate)
	h.encode_u32(28, rate * 4)
	h.encode_u16(32, 4)
	h.encode_u16(34, 32)
	h.encode_u32(36, 0x61746164) # "data"
	h.encode_u32(40, body.size())
	h.append_array(body)
	return h


func _render_fast(mix: PackedFloat32Array, l: Dictionary, rate: int) -> void:
	var w: int = _FX_WAVES.get(l.get("wave", "sine"), 0)
	var dur: float = l.dur
	var f0: float = l.get("f0", 440.0)
	var f1: float = l.get("f1", f0)
	var exp_curve: bool = l.get("curve", "") == "exp"
	var vol: float = l.get("vol", 0.3) * 0.9766 # 기존 소리(× 32000)와 같은 크기 (여기서는 × 32767)
	var lp0: float = l.get("lp", 1.0)
	var lp1: float = l.get("lp1", lp0)
	var bp0: float = l.get("bp", 0.0)
	var bp1: float = l.get("bp1", bp0)
	var q: float = l.get("q", 0.5)
	var attack: float = l.get("attack", 0.002)
	var decay: float = l.get("decay", 1.0)
	var tau: float = l.get("tau", 0.0)
	var vib: float = l.get("vib", 0.0)
	var vib_depth: float = l.get("vib_depth", 0.0)
	var am: float = l.get("am", 0.0)
	var am_depth: float = l.get("am_depth", 0.0)
	var fm: float = l.get("fm", 0.0)
	var fm_i0: float = l.get("fm_i", 0.0)
	var fm_i1: float = l.get("fm_i1", fm_i0)
	if w == 0 and fm > 0.0:
		w = 1
	var start := int(l.get("delay", 0.0) * rate)
	var count := mini(int(dur * rate), mix.size() - start)
	var use_lp := lp0 < 1.0 or lp1 < 1.0
	var use_bp := bp0 > 0.0
	var lp_pow := 22050.0 / rate
	var bp_max := rate * 0.2 # 상태변수 필터가 안정한 범위
	var lp_fixed := lp0 == lp1
	var bp_fixed := bp0 == bp1
	var f_fixed := f0 == f1 and vib <= 0.0
	var a := 1.0 - pow(1.0 - lp0, lp_pow) if use_lp else 1.0
	var sf := 2.0 * sin(PI * minf(bp0, bp_max) / rate) if use_bp else 0.0
	var inc := f0 / rate
	var nz := _noise
	_noise_pos = (_noise_pos + 7919) & (NOISE_LEN - 1)
	var np := _noise_pos
	var ph := 0.0
	var mph := 0.0
	var y := 0.0
	var low := 0.0
	var band := 0.0
	var env := 0.0
	var b := 0
	while b < count:
		var e := mini(b + FX_BLOCK, count)
		# 블록 끝의 엔벨로프 (블록 안은 직선으로)
		var t1 := e / float(rate)
		var k1 := minf(t1 / dur, 1.0)
		var env1 := vol * minf(t1 / attack, 1.0) * minf((dur - t1) * 200.0, 1.0)
		env1 *= exp(-t1 / tau) if tau > 0.0 else pow(1.0 - k1, decay)
		if am > 0.0:
			env1 *= 1.0 - am_depth * (0.5 - 0.5 * cos(TAU * am * t1))
		env1 = maxf(env1, 0.0)
		var denv := (env1 - env) / (e - b)
		# 블록 가운데의 음높이 · 필터 계수
		var tm := (b + e) * 0.5 / rate
		var km := minf(tm / dur, 1.0)
		if not f_fixed:
			var f := f0 * pow(f1 / f0, km) if exp_curve else lerpf(f0, f1, km * km * (3.0 - 2.0 * km))
			if vib > 0.0:
				f *= 1.0 + sin(TAU * vib * tm) * vib_depth
			inc = f / rate
		if use_lp and not lp_fixed:
			a = 1.0 - pow(1.0 - lerpf(lp0, lp1, km), lp_pow)
		if use_bp and not bp_fixed:
			sf = 2.0 * sin(PI * minf(lerpf(bp0, bp1, km), bp_max) / rate)
		match w:
			0: # 사인
				for i in range(b, e):
					ph += inc
					if ph >= 1.0:
						ph -= 1.0
					var v := sin(TAU * ph)
					if use_lp:
						y += a * (v - y)
						v = y
					mix[start + i] += v * env
					env += denv
			1: # FM 사인
				var minc := inc * fm
				var fmi := lerpf(fm_i0, fm_i1, km)
				for i in range(b, e):
					ph += inc
					if ph >= 1.0:
						ph -= 1.0
					mph += minc
					if mph >= 1.0:
						mph -= 1.0
					mix[start + i] += sin(TAU * ph + fmi * sin(TAU * mph)) * env
					env += denv
			2: # 잡음 (공용 잡음표)
				for i in range(b, e):
					var v: float = nz[(np + i) & (NOISE_LEN - 1)]
					if use_lp:
						y += a * (v - y)
						v = y
					if use_bp:
						low += sf * band
						band += sf * (v - low - q * band)
						v = band * q
					mix[start + i] += v * env
					env += denv
			_: # 톱니 · 삼각 · 사각
				for i in range(b, e):
					ph += inc
					if ph >= 1.0:
						ph -= 1.0
					var v := ph * 2.0 - 1.0
					if w == 4:
						v = 1.0 - absf(ph * 4.0 - 2.0)
					elif w == 5:
						v = 1.0 if ph < 0.5 else -1.0
					if use_lp:
						y += a * (v - y)
						v = y
					if use_bp:
						low += sf * band
						band += sf * (v - low - q * band)
						v = band * q
					mix[start + i] += v * env
					env += denv
		env = env1
		b = e
