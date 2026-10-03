class_name Ch3Sfx
extends RefCounted
## 3장 효과음. 공용 Sfx에 없는 소리를 처음 쓸 때 같은 합성 방식(Sfx._add)으로 한 번 만들어 둔다.
## 오디오 담당이 같은 이름(arrow_shot·arrow_hit·bow_draw·wind — docs/systems2.md 9절)을 만들면 그쪽이 우선한다
## (이미 있으면 만들지 않음). ch3_* 는 이 장 전용 소리.

static var _done := false


static func ensure() -> void:
	if _done:
		return
	_done = true
	_reg(&"arrow_shot", [
		{wave = "noise", dur = 0.16, vol = 0.3, lp = 0.6, lp1 = 0.15, attack = 0.005, decay = 2.0},
		{wave = "tri", f0 = 260, f1 = 150, dur = 0.12, vol = 0.22, decay = 3.0},
	])
	_reg(&"arrow_hit", [
		{wave = "sine", f0 = 220, f1 = 90, dur = 0.09, vol = 0.35, decay = 2.0},
		{wave = "noise", dur = 0.05, vol = 0.22, lp = 0.4, decay = 3.0},
	])
	_reg(&"bow_draw", [
		{wave = "saw", f0 = 80, f1 = 150, dur = 0.38, vol = 0.1, lp = 0.2, attack = 0.12, decay = 1.0},
		{wave = "noise", dur = 0.32, vol = 0.06, lp = 0.12, attack = 0.1, decay = 1.2},
	])
	_reg(&"wind", [
		{wave = "noise", dur = 0.7, vol = 0.32, lp = 0.05, lp1 = 0.2, attack = 0.25, decay = 1.3},
		{wave = "sine", f0 = 300, f1 = 520, dur = 0.6, vol = 0.05, attack = 0.2, decay = 1.5, vib = 5.0, vib_depth = 0.04},
	])
	_reg(&"ch3_glass", [
		{wave = "sine", f0 = 2400, f1 = 2380, dur = 0.55, vol = 0.16, decay = 2.4},
		{wave = "sine", f0 = 3610, f1 = 3600, dur = 0.38, vol = 0.09, decay = 3.0, delay = 0.02},
		{wave = "sine", f0 = 1805, f1 = 1790, dur = 0.7, vol = 0.08, decay = 1.6, vib = 6.0, vib_depth = 0.01},
	])
	_reg(&"ch3_glass_low", [
		{wave = "sine", f0 = 1200, f1 = 1190, dur = 0.7, vol = 0.14, decay = 2.0},
		{wave = "sine", f0 = 1810, f1 = 1800, dur = 0.5, vol = 0.07, decay = 2.6, delay = 0.03},
		{wave = "sine", f0 = 70, f1 = 62, dur = 0.8, vol = 0.22, attack = 0.08, decay = 1.4},
	])
	_reg(&"ch3_crystal_break", [
		{wave = "noise", dur = 0.3, vol = 0.3, lp = 0.9, lp1 = 0.4, decay = 2.6},
		{wave = "sine", f0 = 2700, f1 = 1700, dur = 0.25, vol = 0.14, decay = 2.0},
		{wave = "sine", f0 = 3300, f1 = 3300, dur = 0.22, vol = 0.09, decay = 3.0, delay = 0.03},
	])
	_reg(&"ch3_spore", [
		{wave = "noise", dur = 0.36, vol = 0.28, lp = 0.18, attack = 0.04, decay = 1.6},
		{wave = "sine", f0 = 170, f1 = 80, dur = 0.26, vol = 0.22, decay = 2.0},
	])
	_reg(&"ch3_flutter", [
		{wave = "noise", dur = 0.22, vol = 0.14, lp = 0.25, crush = 40, decay = 1.2},
	])
	_reg(&"ch3_whip", [
		{wave = "noise", dur = 0.12, vol = 0.34, lp = 0.95, lp1 = 0.3, decay = 3.0},
		{wave = "saw", f0 = 700, f1 = 180, dur = 0.08, vol = 0.14, lp = 0.6, decay = 2.5},
	])
	_reg(&"ch3_rustle", [
		{wave = "noise", dur = 0.4, vol = 0.18, lp = 0.35, attack = 0.03, decay = 1.4, crush = 6},
	])
	_reg(&"ch3_purify", [
		{wave = "sine", f0 = 520, f1 = 1040, dur = 0.7, vol = 0.22, decay = 1.2},
		{wave = "sine", f0 = 780, f1 = 1560, dur = 0.7, vol = 0.13, decay = 1.4, delay = 0.1},
		{wave = "sine", f0 = 1040, f1 = 2080, dur = 0.6, vol = 0.07, decay = 1.6, delay = 0.2},
	])
	_reg(&"ch3_bellow", [
		{wave = "saw", f0 = 150, f1 = 90, dur = 0.55, vol = 0.22, lp = 0.18, attack = 0.05, decay = 1.2, vib = 5.0, vib_depth = 0.05},
		{wave = "noise", dur = 0.4, vol = 0.08, lp = 0.1, attack = 0.05, decay = 1.5},
	])
	_reg(&"ch3_lance", [
		{wave = "saw", f0 = 200, f1 = 60, dur = 0.5, vol = 0.18, lp = 0.3, decay = 1.4},
		{wave = "sine", f0 = 1600, f1 = 3200, dur = 0.35, vol = 0.1, decay = 2.0},
		{wave = "noise", dur = 0.3, vol = 0.12, lp = 0.7, decay = 2.0},
	])
	_reg(&"ch3_tick", [
		{wave = "square", f0 = 2900, f1 = 2900, dur = 0.025, vol = 0.12, lp = 0.7, decay = 3.0},
		{wave = "sine", f0 = 4200, f1 = 4200, dur = 0.05, vol = 0.06, decay = 3.0, delay = 0.01},
	])


static func _reg(name: StringName, layers: Array) -> void:
	if not Sfx.has_sound(name):
		Sfx._add(name, layers)


static func play(name: StringName, vol := 0.0, pv := 0.06) -> void:
	ensure()
	Sfx.play(name, vol, pv)


## 바깥 신들의 낮은 겹울림 (반복 재생용 스트림 — 백색 사도가 곁에 둔다). 겹친 저음 + 맥놀이 + 아주 옅은 높은 유리음
static func hum_stream() -> AudioStreamWAV:
	var rate := 22050
	var dur := 4.0
	var n := int(rate * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		var v := sin(TAU * 55.0 * t) * 0.32 + sin(TAU * 55.5 * t) * 0.22 + sin(TAU * 82.5 * t) * 0.16 + sin(TAU * 110.25 * t) * 0.07
		v += sin(TAU * 2475.0 * t) * 0.012 * (0.5 + 0.5 * sin(TAU * 0.25 * t))
		data.encode_s16(i * 2, int(clampf(v * 0.6, -1.0, 1.0) * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = rate
	s.stereo = false
	s.data = data
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = n
	return s
