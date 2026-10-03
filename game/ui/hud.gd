extends CanvasLayer
## 화면 정보 (docs/prototype.md 8절): 좌상단 체력 5칸 + 폭주 게이지, 우하단 스킬 2개와 재사용 대기,
## 우상단 구간·시간, 가운데 알림 문구(banner).

var _draw_node: HudDraw
var _banner: Label
var _banner_tween: Tween


func _ready() -> void:
	layer = 10
	add_to_group(&"hud")
	_draw_node = HudDraw.new()
	_draw_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draw_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_draw_node)

	_banner = Label.new()
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.position = Vector2(0, 92)
	_banner.size = Vector2(640, 20)
	var ls := LabelSettings.new()
	ls.font_size = 12
	ls.font_color = Palette.GOLD
	ls.outline_size = 5
	ls.outline_color = Color("#0b0914")
	_banner.label_settings = ls
	_banner.modulate.a = 0.0
	add_child(_banner)


func banner(text: String, sec := 1.5) -> void:
	_banner.text = text
	if _banner_tween:
		_banner_tween.kill()
	_banner.modulate.a = 0.0
	_banner.position.y = 98
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.15)
	_banner_tween.parallel().tween_property(_banner, "position:y", 92.0, 0.15)
	_banner_tween.tween_interval(sec)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.3)


class HudDraw extends Control:
	var _t := 0.0
	var _shown_hp := -1
	var _hp_shake := 0.0
	var _ready_flash := [0.0, 0.0]
	var _was_ready := [true, true]
	var _font: Font

	func _ready() -> void:
		_font = get_theme_default_font()

	func _process(delta: float) -> void:
		_t += delta
		_hp_shake = maxf(_hp_shake - delta, 0.0)
		for i in 2:
			_ready_flash[i] = maxf(_ready_flash[i] - delta * 3.0, 0.0)
		queue_redraw()

	func _draw() -> void:
		var p := get_tree().get_first_node_in_group(GameConst.GROUP_PLAYER) as Player
		if p == null:
			return
		_draw_hp(p)
		_draw_overload(p)
		_draw_skills(p)
		_draw_info()

	func _draw_hp(p: Player) -> void:
		if _shown_hp != p.hp:
			if _shown_hp > p.hp:
				_hp_shake = 0.35
			_shown_hp = p.hp
		var origin := Vector2(12, 12)
		if _hp_shake > 0.0:
			origin += Vector2(randf_range(-1.5, 1.5), randf_range(-1, 1))
		for i in p.tuning.max_hp:
			var c := origin + Vector2(i * 13, 0)
			var full := i < p.hp
			var pts := PackedVector2Array([c + Vector2(5, 0), c + Vector2(10, 6), c + Vector2(5, 12), c + Vector2(0, 6)])
			draw_colored_polygon(pts, Color("#0b0914"))
			var inner := PackedVector2Array([c + Vector2(5, 1.5), c + Vector2(8.5, 6), c + Vector2(5, 10.5), c + Vector2(1.5, 6)])
			if full:
				var pulse := 0.0
				if p.hp == 1:
					pulse = 0.4 + 0.4 * sin(_t * 8.0) # 마지막 한 칸은 깜빡임
				draw_colored_polygon(inner, Palette.HP.lerp(Color.WHITE, pulse * 0.4))
				draw_rect(Rect2(c + Vector2(3.5, 3), Vector2(1.5, 1.5)), Color(1, 1, 1, 0.7))
			else:
				draw_colored_polygon(inner, Palette.HP_EMPTY)

	func _draw_overload(p: Player) -> void:
		var r := Rect2(12, 30, 72, 6)
		var ratio := p.overload_ratio()
		var warn := ratio >= p.tuning.overload_warn_ratio
		draw_rect(r.grow(1), Color("#0b0914"))
		draw_rect(r, Color("#2a1e2e"))
		var fill_col := Palette.FIRE_MID.lerp(Palette.FIRE_OUT, ratio)
		if warn or p.overload_fusing():
			var blink := 0.5 + 0.5 * sin(_t * (30.0 if p.overload_fusing() else 12.0))
			fill_col = fill_col.lerp(Palette.DANGER, blink)
		draw_rect(Rect2(r.position, Vector2(r.size.x * ratio, r.size.y)), fill_col)
		draw_rect(Rect2(r.position, Vector2(r.size.x * ratio, 1)), Color(1, 1, 1, 0.35))
		var mark_x := r.position.x + r.size.x * p.tuning.overload_warn_ratio
		draw_line(Vector2(mark_x, r.position.y - 1), Vector2(mark_x, r.end.y + 1), Color(1, 1, 1, 0.5), 1.0)
		var label_col := Palette.DANGER if warn else Palette.UI_DIM
		draw_string(_font, Vector2(r.end.x + 5, r.end.y + 2), "폭주", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, label_col)

	func _draw_skills(p: Player) -> void:
		var skills := [
			[p.pillar_cooldown_left, p.tuning.pillar_cooldown, "A", 0],
			[p.storm_cooldown_left, p.tuning.storm_cooldown, "S", 1],
		]
		for i in 2:
			var left: float = skills[i][0]
			var total: float = skills[i][1]
			var key: String = skills[i][2]
			var box := Rect2(576 + i * 30, 318, 24, 24)
			var ready := left <= 0.0
			if ready and not _was_ready[i]:
				_ready_flash[i] = 1.0
			_was_ready[i] = ready
			draw_rect(box.grow(1), Color("#0b0914"))
			draw_rect(box, Color("#241a35"))
			_draw_skill_icon(i, box.get_center(), ready)
			if not ready:
				var k := left / total
				draw_rect(Rect2(box.position, Vector2(box.size.x, box.size.y * k)), Color(0, 0, 0, 0.6))
			if _ready_flash[i] > 0.0:
				draw_rect(box, Color(1, 0.9, 0.7, 0.5 * _ready_flash[i]), false, 1.0)
			draw_string(_font, box.position + Vector2(2, -3), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_DIM)

	func _draw_skill_icon(kind: int, c: Vector2, ready: bool) -> void:
		var a := 1.0 if ready else 0.5
		if kind == 0:
			# 불기둥
			draw_rect(Rect2(c + Vector2(-3, -9), Vector2(6, 16)), Color(Palette.FIRE_OUT, a))
			draw_rect(Rect2(c + Vector2(-1.5, -7), Vector2(3, 13)), Color(Palette.FIRE_HOT, a))
			draw_line(c + Vector2(-8, 8), c + Vector2(8, 8), Color(Palette.GROUND_TOP, a), 1.0)
		else:
			# 부채꼴 화염
			for j in 3:
				var ang := -0.5 + j * 0.5
				var d := Vector2(cos(ang), sin(ang))
				draw_colored_polygon(PackedVector2Array([c + Vector2(-7, 0) + Vector2(0, -2), c + Vector2(-7, 0) + d * 16.0, c + Vector2(-7, 0) + Vector2(0, 2)]), Color(Palette.FIRE_OUT, a))
			draw_circle(c + Vector2(-7, 0), 2.5, Color(Palette.FIRE_HOT, a))

	func _draw_info() -> void:
		var stage := get_tree().current_scene
		var sec_text := ""
		if stage and stage.has_method("current_section"):
			var s: Section = stage.current_section()
			if s:
				sec_text = "%d/4 %s" % [s.index + 1, s.title]
		var time_text := GameState.format_time(GameState.run_time)
		draw_string(_font, Vector2(420, 20), sec_text, HORIZONTAL_ALIGNMENT_RIGHT, 160, 12, Palette.UI_DIM)
		draw_string(_font, Vector2(586, 20), time_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_TEXT)
