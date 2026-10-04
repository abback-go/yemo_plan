extends Node2D
## 빛의 수정 (docs/chapter4.md 5절·7.5절): 빛줄기가 hold초 동안 닿으면 깨어나 flag를 세운다(문·철창이 열림 — gate open_if).
## 방 데이터: {t:"light_crystal", x, y(바닥 행 — 받침 위에 놓임; hang=true면 천장 행에 매달림), flag, hold(기본 0.6), id}
## 한 번 밝히면 계속 빛난다(플래그 저장).

const H := preload("res://enemies/ch4/holy.gd")

var flag := ""
var hold := 0.6
var hang := false
var radius := 9.0
var _charge := 0.0
var _touch := 0.0
var _done := false
var _t := 0.0


func setup(room: Room, e: Dictionary, _eid: String) -> void:
	position = room.tile_pos(e) + Vector2(8, 0)
	flag = String(e.get("flag", ""))
	hold = float(e.get("hold", 0.6))
	hang = bool(e.get("hang", false))
	_done = flag != "" and GameState.has_flag(flag)
	z_index = 2


func _ready() -> void:
	add_to_group(&"light_crystal")


func center() -> Vector2:
	return global_position + (Vector2(0, 20) if hang else Vector2(0, -22))


func is_lit() -> bool:
	return _done


## 빛줄기 추적이 닿는 동안 매 프레임 부른다
func light_hit(delta: float) -> void:
	_touch = 0.12
	if _done:
		return
	_charge += delta
	if _charge >= hold:
		_awaken()


func _awaken() -> void:
	_done = true
	if flag != "":
		GameState.set_flag(flag)
	H.snd(&"bell_small", &"reveal", 0.0)
	Sfx.play(&"clear", -6.0, 0.0)
	Fx.ring(center(), 6.0, 60.0, H.GOLD, 0.5, 3.0)
	Fx.flash(Color(1.0, 0.95, 0.75, 0.15), 0.2)
	H.sparkle(center(), 26, 8.0, 30.0, 0.9)


func _process(delta: float) -> void:
	_t += delta
	_touch = maxf(_touch - delta, 0.0)
	if _touch <= 0.0 and not _done:
		_charge = maxf(_charge - delta * 0.5, 0.0)
	queue_redraw()


func _draw() -> void:
	var c := center() - global_position
	var k := 1.0 if _done else clampf(_charge / hold, 0.0, 1.0)
	if hang:
		draw_line(Vector2.ZERO, c + Vector2(0, -9), Color("#8a6428"), 1.0)
	else:
		# 받침
		draw_colored_polygon(PackedVector2Array([Vector2(-8, 0), Vector2(8, 0), Vector2(5, -8), Vector2(-5, -8)]), Color("#5c5676"))
		draw_rect(Rect2(-6, -10, 12, 2), Color("#e0b048"))
	# 빛 무리
	if k > 0.0 or _touch > 0.0:
		for i in 4:
			draw_circle(c, 10.0 + i * 5.0 * (0.4 + k), Color(1.0, 0.88, 0.5, (0.05 + 0.05 * k) * (1.0 + 0.3 * sin(_t * 6.0))))
	# 수정 (육각 기둥 모양)
	var dim := Color("#6a6a8a")
	var lit := Color("#fff4c8")
	var col := dim.lerp(lit, k)
	var pts := PackedVector2Array([c + Vector2(0, -11), c + Vector2(6, -5), c + Vector2(6, 5), c + Vector2(0, 11), c + Vector2(-6, 5), c + Vector2(-6, -5)])
	var o := PackedVector2Array()
	for p in pts:
		o.append(c + (p - c) * 1.15)
	draw_colored_polygon(o, Color("#16101f"))
	draw_colored_polygon(pts, col)
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -11), c + Vector2(6, -5), c + Vector2(6, 5), c + Vector2(0, 2)]), col.darkened(0.2))
	draw_line(c + Vector2(-3, -6), c + Vector2(-3, 5), Color(1, 1, 1, 0.5 + 0.4 * k), 1.0)
	if _touch > 0.0 and not _done:
		draw_arc(c, 13.0, -PI * 0.5, -PI * 0.5 + TAU * k, 24, Color(1.0, 0.9, 0.5), 2.0)
