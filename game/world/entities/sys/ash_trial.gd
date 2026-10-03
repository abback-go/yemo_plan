extends Node2D
## 재의 서고 (불사조 수업 2단계): 어둠 속 촛불의 시간이 다 하면 입구로 되돌아간다.
## 촛불(ash_candle)을 화염탄으로 켤 때마다 시간이 light초로 다시 찬다. 위쪽에 남은 시간 막대.
## {t = "ash_trial", light = 12.0, start = "start" (표식 ID), done_flag = "ash_done"}

var light := 12.0
var left := 12.0
var start_id := "start"
var done_flag := ""
var room: Room
var _layer: CanvasLayer
var _bar: Control
var _busy := false


func setup(p_room: Room, e: Dictionary, _eid: String) -> void:
	room = p_room
	light = float(e.get("light", 12.0))
	left = light
	start_id = String(e.get("start", "start"))
	done_flag = String(e.get("done_flag", "ash_done"))
	add_to_group(&"ash_trial")


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 21
	_bar = Bar.new()
	_bar.trial = self
	_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_bar)
	add_child(_layer)


func refill() -> void:
	left = light


func _physics_process(delta: float) -> void:
	if GameState.has_flag(done_flag) or Story.busy() or _busy:
		_layer.visible = false
		return
	_layer.visible = true
	left -= delta
	_bar.queue_redraw()
	if left <= 0.0:
		_reset()


func _reset() -> void:
	_busy = true
	var w := World.get_world()
	Story.toast("촛불이 꺼졌다… 재가 길을 지운다.", 2.0)
	Sfx.play(&"crumble", -2.0, 0.0)
	if w:
		await w.fade.fade_out(0.4)
		var sp := room.spawn_point(start_id)
		w.player.place_at(sp.pos, 1)
		for c in get_tree().get_nodes_in_group(&"ash_candle"):
			c.extinguish()
		await w.fade.fade_in(0.4)
	left = light
	_busy = false


class Bar extends Control:
	var trial: Node

	func _draw() -> void:
		var k: float = clampf(trial.left / trial.light, 0.0, 1.0)
		var col := Color(1.0, 0.75, 0.4).lerp(Color(1.0, 0.3, 0.2), 1.0 - k)
		draw_rect(Rect2(220, 68, 200, 6), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(220, 68, 200 * k, 6), col)
		draw_string(ThemeDB.fallback_font, Vector2(220, 64), "촛불", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_DIM)
