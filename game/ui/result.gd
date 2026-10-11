extends Control
## 결과 화면 (docs/archive/sera/prototype.md 13.3절). 테스트 기록과 검증 질문 체크리스트를 보여 준다.

const BG := preload("res://levels/background.gd")

var _font: Font
var _menu: MenuList
var _t := 0.0


func _ready() -> void:
	Fx.reset()
	get_tree().paused = false
	_font = get_theme_default_font()
	add_child(BG.SkyDraw.new())
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.06, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var drawer := ResultDraw.new()
	drawer.set_anchors_preset(Control.PRESET_FULL_RECT)
	drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(drawer)

	_menu = MenuList.new()
	_menu.items = ["다시 하기", "타이틀로"]
	_menu.position = Vector2(470, 300)
	_menu.size = Vector2(150, 50)
	_menu.chosen.connect(_on_chosen)
	add_child(_menu)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		GameState.restart_run()
		return
	if _menu.handle_input(event) and is_inside_tree():
		get_viewport().set_input_as_handled()


func _on_chosen(index: int) -> void:
	if index == 0:
		GameState.restart_run()
	else:
		GameState.go_title()


class ResultDraw extends Control:
	var _t := 0.0
	var _font: Font

	func _ready() -> void:
		_font = get_theme_default_font()

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _row(y: float, label: String, value: String, col := Palette.UI_TEXT) -> void:
		draw_string(_font, Vector2(60, y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_DIM)
		draw_string(_font, Vector2(200, y), value, HORIZONTAL_ALIGNMENT_RIGHT, 80, 12, col)

	func _draw() -> void:
		var s: Dictionary = GameState.stats
		draw_string(_font, Vector2(60, 46), "클리어!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Palette.FIRE_HOT)
		draw_string(_font, Vector2(170, 46), GameState.format_time(GameState.run_time), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Palette.UI_TEXT)

		var hits: int = s.hits_charger + s.hits_sniper + s.hits_overload
		var acc: float = 0.0 if s.bolts_fired == 0 else 100.0 * s.bolts_hit / s.bolts_fired
		var y := 80.0
		_row(y, "사망", str(s.deaths)); y += 16
		_row(y, "피격 합계", str(hits)); y += 16
		_row(y, "  ㄴ 돌진형", str(s.hits_charger), Palette.ENEMY_EYE); y += 16
		_row(y, "  ㄴ 저격형", str(s.hits_sniper), Palette.SHOT); y += 16
		_row(y, "  ㄴ 폭주 자기 피해", str(s.hits_overload), Palette.FIRE_OUT); y += 16
		_row(y, "폭주 횟수", str(s.overloads), Palette.FIRE_OUT); y += 16
		_row(y, "불기둥 / 화염 폭풍", "%d / %d" % [s.pillar, s.storm]); y += 16
		_row(y, "대시", str(s.dashes)); y += 16
		_row(y, "화염탄 적중", "%d / %d (%.0f%%)" % [s.bolts_hit, s.bolts_fired, acc]); y += 16
		_row(y, "처치", str(s.kills)); y += 16
		_row(y, "최대 콤보", str(s.get("max_combo", 0)), Palette.FIRE_HOT); y += 16
		_row(y, "최고 스타일 랭크", StyleRank.RANKS[int(s.get("best_rank", 0))], Palette.GOLD); y += 16
		_row(y, "위치 타임 (퍼펙트 회피)", str(s.get("perfect_dodges", 0)), Color("#c9b8ff")); y += 16

		# 검증 질문 (docs/archive/sera/prototype.md 1.1절) — 녹화와 함께 '예/아니오/애매'로 기록
		var qx := 330.0
		draw_string(_font, Vector2(qx, 80), "검증 체크 (예 / 아니오 / 애매)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.GOLD)
		var qs := [
			"Q1 3타 리듬에 때리는 손맛이 있었나?",
			"Q2 좌우 조준만으로도 단조롭지 않았나?",
			"Q3 폭주가 위험이자 보상으로 느껴졌나?",
			"Q4 적 때문에 위치를 계속 바꿔야 했나?",
			"Q5 이동이 빠르고 전투가 화려하게 느껴졌나?",
		]
		for i in qs.size():
			draw_string(_font, Vector2(qx, 100 + i * 18), qs[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_TEXT)
		draw_string(_font, Vector2(qx, 204), "→ docs/archive/sera/prototype.md 1.2절 1인 테스트 보정법", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_DIM)
		draw_string(_font, Vector2(60, 330), "R 다시 하기", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_DIM)
