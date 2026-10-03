extends Node
## 효과음을 녹음 파일 없이 코드로 합성한다 (docs/prototype.md 13.2절).
## 게임 시작 시 한 번 파형을 계산해 AudioStreamWAV로 만들어 두고, Sfx.play("shoot")처럼 재생한다.
## 각 소리는 여러 '층'(layer)을 더해 만든다. 층 하나 = 파형 + 주파수 변화 + 노이즈 + 필터 + 감쇠.

const RATE := 22050
const POOL_SIZE := 16

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 7
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
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
	_add(&"ui_move", [
		{wave = "square", f0 = 880, f1 = 880, dur = 0.04, vol = 0.1, lp = 0.5},
	])
	_add(&"ui_ok", [
		{wave = "square", f0 = 660, f1 = 660, dur = 0.06, vol = 0.13, lp = 0.5},
		{wave = "square", f0 = 990, f1 = 990, dur = 0.1, vol = 0.13, lp = 0.5, delay = 0.06},
	])


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
