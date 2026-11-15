extends SceneTree
## 턴제 효과음 크기 재기 (review_D_art.md §7 방법): 소리마다 최대·RMS + 300 Hz 고역 통과(폰 스피커 근사) 뒤 RMS (dBFS).
## "재생"은 그 소리를 부르는 곳의 재생 dB(Sfx 기본 −6 + 호출 값)를 더한 폰 근사 크기.
##   cd game && godot --headless --script ../tools/test/sfx_levels.gd [-- 이름 …]

const NAMES := ["tn_select", "tn_turn", "tn_fire", "tn_spear", "tn_ult", "tn_ult_bell", "tn_ult_hit", "tn_break", "tn_stun",
	"tn_dispel", "tn_dispel_glint", "tn_wave", "tn_guts", "tn_taunt", "tn_resist"]

var _sfx: Node
var _frames := 0


func _initialize() -> void:
	_sfx = load("res://autoload/sfx.gd").new()
	root.add_child(_sfx)


func _process(_d: float) -> bool:
	_frames += 1
	if _frames < 2:
		return false
	var names: Array = NAMES
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		names = args
	print("| 소리 | rate | 길이 | 최대 | RMS | HP300 |")
	print("|---|---|---|---|---|---|")
	for n: String in names:
		var s: AudioStreamWAV = _sfx._streams.get(StringName(n))
		if s == null:
			print("| %s | 없음 |" % n)
			continue
		var x := _samples(s)
		var peak := 0.0
		var sq := 0.0
		for v in x:
			peak = maxf(peak, absf(v))
			sq += v * v
		var rms := sqrt(sq / maxf(x.size(), 1))
		var hp := _hp(_hp(x, s.mix_rate), s.mix_rate)
		var sq2 := 0.0
		for v in hp:
			sq2 += v * v
		var rms2 := sqrt(sq2 / maxf(hp.size(), 1))
		print("| %s | %d | %.2f | %.1f | %.1f | %.1f |" % [n, s.mix_rate, float(x.size()) / s.mix_rate, _db(peak), _db(rms), _db(rms2)])
	return true


func _samples(s: AudioStreamWAV) -> PackedFloat32Array:
	var d := s.data
	var out := PackedFloat32Array()
	if s.format == AudioStreamWAV.FORMAT_16_BITS:
		out.resize(d.size() / 2)
		for i in out.size():
			out[i] = d.decode_s16(i * 2) / 32768.0
	elif s.format == AudioStreamWAV.FORMAT_8_BITS:
		out.resize(d.size())
		for i in out.size():
			out[i] = d.decode_s8(i) / 128.0
	return out


## 1차 고역 통과 300 Hz
func _hp(x: PackedFloat32Array, rate: int) -> PackedFloat32Array:
	var rc := 1.0 / (TAU * 300.0)
	var dt := 1.0 / float(rate)
	var al := rc / (rc + dt)
	var y := PackedFloat32Array()
	y.resize(x.size())
	var py := 0.0
	var px := 0.0
	for i in x.size():
		py = al * (py + x[i] - px)
		px = x[i]
		y[i] = py
	return y


func _db(v: float) -> float:
	return 20.0 * log(maxf(v, 1e-6)) / log(10.0)
