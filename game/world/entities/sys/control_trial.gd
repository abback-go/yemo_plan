extends Node2D
## 폭주 제어 시험 (유성 낙화 수업 2단계 — 베로니카): 폭주 게이지를 70~95% 사이로 합계 20초 유지하면 done_flag.
## 100%가 되어 터지면 처음부터. 화면 위에 띠 모양 계기판을 그린다. on_if 플래그가 설 때만 진행.
## {t = "control_trial", x, y, need = 20.0, done_flag = "control_done", on_if = "control_on"}

var need := 20.0
var done_flag := ""
var on_if := ""
var held := 0.0
var _t := 0.0
var _layer: CanvasLayer
var _draw: Control
var _was_fuse := false


func setup(_room: Room, e: Dictionary, _eid: String) -> void:
	need = float(e.get("need", 20.0))
	done_flag = String(e.get("done_flag", "control_done"))
	on_if = String(e.get("on_if", ""))


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 21
	_draw = Gauge.new()
	_draw.trial = self
	_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_draw)
	add_child(_layer)


func active() -> bool:
	return RoomData.cond_ok(on_if) and not GameState.has_flag(done_flag)


func _physics_process(delta: float) -> void:
	_t += delta
	_layer.visible = active()
	if not active():
		return
	var p := get_tree().get_first_node_in_group(GameConst.GROUP_PLAYER) as Player
	if p == null:
		return
	var r := p.overload_ratio()
	var fuse := p.overload_fusing()
	if fuse and not _was_fuse:
		held = 0.0
		Story.toast("폭주했다! 처음부터 — 70~95% 사이를 지켜라.", 2.4)
	_was_fuse = fuse
	if r >= 0.7 and r <= 0.95 and not fuse:
		held += delta
		if held >= need:
			GameState.set_flag(done_flag)
			Sfx.play(&"quest_done", 0.0, 0.0)
	_draw.queue_redraw()


class Gauge extends Control:
	var trial: Node

	func _draw() -> void:
		var p := get_tree().get_first_node_in_group(GameConst.GROUP_PLAYER) as Player
		if p == null:
			return
		var font := ThemeDB.fallback_font
		var box := Rect2(170, 70, 300, 10)
		draw_rect(box.grow(2), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(box.position.x + box.size.x * 0.7, box.position.y, box.size.x * 0.25, box.size.y), Color(0.3, 0.8, 0.4, 0.5))
		var r := p.overload_ratio()
		draw_rect(Rect2(box.position, Vector2(box.size.x * r, box.size.y)), Palette.FIRE_OUT.lerp(Palette.FIRE_HOT, r))
		var k: float = clampf(trial.held / trial.need, 0.0, 1.0)
		draw_string(font, Vector2(170, 64), "제어 시험 — 70~95%%를 유지: %.1f / %d초" % [trial.held, int(trial.need)], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_TEXT)
		draw_rect(Rect2(170, 86, 300 * k, 3), Palette.GOLD)
