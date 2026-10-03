extends Node
## 배경음악 (docs/chapter1.md 9절). 음악 파일은 tools/gen_music.py가 코드로 합성한 것.
## Music.play("school")처럼 부르면 지금 곡과 다를 때만 0.8초 교차 재생한다.
## Music.jingle("jingle_ability")는 배경음악을 잠깐 줄이고 짧은 곡을 한 번 재생한다.

const DIR := "res://assets/music/"

var current := ""
var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _jingle: AudioStreamPlayer
var _cache := {}
var _duck := 1.0
var _duck_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = &"Music"
		p.volume_db = -80.0
		add_child(p)
		_players.append(p)
	_jingle = AudioStreamPlayer.new()
	_jingle.bus = &"Music"
	add_child(_jingle)
	_jingle.finished.connect(_unduck)


func _stream(name: String, loop: bool) -> AudioStream:
	if _cache.has(name):
		return _cache[name]
	var path := DIR + name + ".ogg"
	if not ResourceLoader.exists(path):
		return null
	var s := load(path) as AudioStream
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = loop
	_cache[name] = s
	return s


## 지역 음악 재생. 같은 곡이면 이어서 재생, ""이면 정지
func play(name: String, fade := 0.8) -> void:
	if name == current:
		return
	current = name
	var old := _players[_active]
	_fade(old, -80.0, fade, true)
	if name == "":
		return
	var s := _stream(name, true)
	if s == null:
		return
	_active = 1 - _active
	var p := _players[_active]
	p.stream = s
	p.volume_db = -40.0
	p.play()
	_fade(p, 0.0, fade, false)


func stop(fade := 1.0) -> void:
	play("", fade)


func jingle(name: String) -> void:
	var s := _stream(name, false)
	if s == null:
		return
	_jingle.stream = s
	_jingle.play()
	_set_duck(0.25, 0.2)


func _unduck() -> void:
	_set_duck(1.0, 1.0)


func _set_duck(target: float, time: float) -> void:
	if _duck_tween:
		_duck_tween.kill()
	_duck_tween = create_tween().set_ignore_time_scale(true)
	_duck_tween.tween_method(func(v: float) -> void:
		_duck = v
		var p := _players[_active]
		if p.playing:
			p.volume_db = linear_to_db(maxf(_duck, 0.001))
	, _duck, target, time)


func _fade(p: AudioStreamPlayer, to_db: float, time: float, stop_after: bool) -> void:
	var t := create_tween().set_ignore_time_scale(true)
	t.tween_property(p, "volume_db", to_db + linear_to_db(maxf(_duck, 0.001)) if to_db > -79.0 else to_db, maxf(time, 0.01))
	if stop_after:
		t.tween_callback(p.stop)
