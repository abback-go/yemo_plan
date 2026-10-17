extends Node
## 땅울림 (방 개체 "st_quake"): 배경의 거신 행진(backdrop_ch5.gd)과 같은 박자로 화면을 흔들고 쿵 소리를 낸다.
## 침공·절망 방에 하나씩 둔다. on_if(플래그 식)가 서 있을 때만. 세기 strength(T, 기본 0.25).

var strength := 0.25
var on_if := ""
var _last := 0.0


func setup(_room: Room, e: Dictionary, _eid: String) -> void:
	strength = float(e.get("strength", 0.25))
	on_if = String(e.get("on_if", ""))
	_last = (load("res://world/themes/backdrop_ch5.gd") as GDScript).march_clock()


func _process(_d: float) -> void:
	var bd: GDScript = load("res://world/themes/backdrop_ch5.gd")
	var now: float = bd.march_clock()
	if bd.step_between(_last, now) and (on_if == "" or RoomData.cond_ok(on_if)):
		Fx.shake(strength, 0.3)
		StArt.sfx_pitch(&"colossus_step", &"slam", 0.5, -8.0)
	_last = now
