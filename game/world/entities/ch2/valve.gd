extends Interactable
## 수문 밸브 (하수도 수위 퍼즐, docs/archive/sera/chapter2.md 5절). ↑로 돌리면 flag를 뒤집는다(켜짐 ↔ 꺼짐).
## 같은 flag를 가진 밸브가 여럿이면 어느 쪽에서 돌려도 같은 수문이 열리고 닫힌다.
## {t = "k_valve", x, y, flag = "k_sw3_low", label = "배수 밸브", on_text = "물이 빠진다", off_text = "물이 찬다"}

const KE := preload("res://enemies/ch2/k_enemy.gd")

var flag := ""
var on_text := ""
var off_text := ""
var _t := 0.0
var _spin := 0.0
var _turning := 0.0


func setup(p_room: Room, e: Dictionary, _eid: String) -> void:
	room = p_room
	flag = String(e.get("flag", ""))
	on_text = String(e.get("on_text", ""))
	off_text = String(e.get("off_text", ""))
	prompt = String(e.get("label", "수문 밸브")) + " 돌리기"
	position = room.tile_pos(e) + Vector2(8, 0)
	area_size = Vector2(28, 36)
	z_index = 0
	_spin = 1.2 if GameState.has_flag(flag) else 0.0


func interact() -> void:
	if _turning > 0.0 or flag == "":
		return
	var now := not GameState.has_flag(flag)
	GameState.set_flag(flag, now)
	_turning = 0.9
	KE.snd(&"chain", &"chain", 0.0)
	KE.snd(&"door", &"door", -6.0)
	Fx.shake(0.15, 0.4)
	var txt := on_text if now else off_text
	if txt != "":
		Story.toast(txt, 2.0)


func _process(delta: float) -> void:
	_t += delta
	if _turning > 0.0:
		_turning -= delta
		_spin += delta * 5.0 * (1.0 if GameState.has_flag(flag) else -1.0)
	queue_redraw()


func _draw() -> void:
	var on := GameState.has_flag(flag)
	var pipe := Color("#3a4a48")
	draw_rect(Rect2(-5, -30, 10, 30), pipe)
	draw_rect(Rect2(-3, -30, 2, 30), pipe.lightened(0.2))
	draw_rect(Rect2(-8, -4, 16, 4), pipe.darkened(0.2))
	var c := Vector2(0, -22)
	var rust := Color("#a85a2a") if not on else Color("#c8a040")
	draw_arc(c, 10.0, 0, TAU, 20, Color("#07060c"), 4.0)
	draw_arc(c, 10.0, 0, TAU, 20, rust, 2.0)
	for k in 4:
		var a := _spin + TAU * k / 4.0
		draw_line(c, c + Vector2(cos(a), sin(a)) * 10.0, rust, 2.0)
	draw_circle(c, 3.0, rust.lightened(0.25))
	# 상태 표시등
	var lamp := Color("#6af0e0") if on else Color("#ff6a4a")
	draw_circle(Vector2(0, -36), 2.5, lamp)
	draw_circle(Vector2(0, -36), 5.0, Color(lamp, 0.25 + 0.1 * sin(_t * 4.0)))
