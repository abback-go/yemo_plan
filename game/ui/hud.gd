extends CanvasLayer
## 화면 정보 (docs/prototype.md 8절): 좌상단 체력 5칸 + 폭주 게이지, 우하단 스킬 2개와 재사용 대기,
## 우상단 구간·시간 + 콤보·스타일 랭크(v0.3, 14절), 가운데 알림 문구(banner).

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


func enemy_card(name_text: String, sub: String, boss := false) -> void:
	var w := World.get_world()
	if w:
		w.notice.enemy_card(name_text, sub, boss)


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
	## 랭크별 글자색 (D C B A S SS)
	const RANK_COLORS := [
		Color("#8a7fa3"), Color("#c9b8ff"), Color("#ffb347"), Color("#ff5a2a"), Color("#ffd27a"), Color("#fff4d6"),
	]

	var _t := 0.0
	var _shown_hp := -1
	var _hp_shake := 0.0
	var _ready_flash := [0.0, 0.0]
	var _was_ready := [true, true]
	var _font: Font
	var _shown_rank := 0
	var _rank_pop := 0.0
	var _shown_combo := 0
	var _combo_pop := 0.0
	var _style_alpha := 0.0
	var _obj_text := ""
	var _obj_flash := 0.0
	var _boss_shown := 0.0

	func _ready() -> void:
		_font = get_theme_default_font()

	func _process(delta: float) -> void:
		# 히트스톱·슬로모션 중에도 HUD 연출은 실제 시간으로
		var real := delta / maxf(Engine.time_scale, 0.0001)
		_t += real
		_hp_shake = maxf(_hp_shake - real, 0.0)
		for i in 2:
			_ready_flash[i] = maxf(_ready_flash[i] - real * 3.0, 0.0)
		_rank_pop = maxf(_rank_pop - real * 4.0, 0.0)
		_combo_pop = maxf(_combo_pop - real * 8.0, 0.0)
		var active := StyleRank.points > 0.5 or StyleRank.combo >= 2
		_style_alpha = move_toward(_style_alpha, 1.0 if active else 0.0, real * 4.0)
		queue_redraw()

	func _draw() -> void:
		var p := get_tree().get_first_node_in_group(GameConst.GROUP_PLAYER) as Player
		if p == null:
			return
		_draw_hp(p)
		_draw_overload(p)
		var w := World.get_world()
		if w:
			_draw_potions(p)
			_draw_fox(p)
			if not TouchControls.shown:
				_draw_skills3(p)
			_draw_objective()
			_draw_minimap(w)
			_draw_boss()
			_draw_elite_bars(w)
		else:
			_draw_skills(p)
			_draw_info()
		_draw_style()

	func _draw_hp(p: Player) -> void:
		if _shown_hp != p.hp:
			if _shown_hp > p.hp:
				_hp_shake = 0.35
			_shown_hp = p.hp
		var origin := Vector2(12, 12)
		if _hp_shake > 0.0:
			origin += Vector2(randf_range(-1.5, 1.5), randf_range(-1, 1))
		for i in p.max_hp():
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
		if p.is_overheated():
			# 과열: 화염탄 강화 중임을 알림 (위험을 감수한 보상)
			var hot := Palette.FIRE_HOT.lerp(Palette.FIRE_CORE, 0.5 + 0.5 * sin(_t * 18.0))
			draw_string(_font, Vector2(r.end.x + 33, r.end.y + 2), "과열!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, hot)

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

	## 우상단 콤보 수 + 스타일 랭크 글자 + 랭크 진행 막대 + 최근 보너스 문구
	func _draw_style() -> void:
		var sr := StyleRank
		if sr.rank != _shown_rank:
			if sr.rank > _shown_rank:
				_rank_pop = 1.0
			_shown_rank = sr.rank
		if sr.combo > _shown_combo:
			_combo_pop = 1.0
		_shown_combo = sr.combo
		if _style_alpha <= 0.0:
			return
		var a := _style_alpha
		var right := 628.0
		# 1장 데모 HUD에서는 오른쪽 위에 미니맵이 있으므로 스타일 랭크를 그 아래로
		if World.get_world() != null:
			draw_set_transform(Vector2(0, 48), 0.0, Vector2.ONE)

		# 랭크 글자 (36px). 오를 때 크게 튀고, S 이상은 떨린다
		var col: Color = RANK_COLORS[sr.rank]
		if sr.rank >= 5:
			col = col.lerp(Palette.FIRE_OUT, 0.5 + 0.5 * sin(_t * 20.0))
		var text := sr.rank_name()
		var size := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 36)
		var center := Vector2(right - size.x * 0.5, 50)
		if sr.rank >= 4:
			center += Vector2(randf_range(-0.8, 0.8), randf_range(-0.8, 0.8))
		var sc := 1.0 + _rank_pop * 0.7
		draw_set_transform(center, -0.12 * _rank_pop, Vector2(sc, sc))
		var origin := Vector2(-size.x * 0.5, 12)
		draw_string_outline(_font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 36, 6, Color(Palette.OUTLINE, a))
		draw_string(_font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color(col, a))
		draw_set_transform(Vector2.ZERO)

		# 랭크 이름 + 진행 막대
		draw_string_outline(_font, Vector2(right - 90, 76), StyleRank.NAMES[sr.rank], HORIZONTAL_ALIGNMENT_RIGHT, 90, 12, 4, Color(Palette.OUTLINE, a))
		draw_string(_font, Vector2(right - 90, 76), StyleRank.NAMES[sr.rank], HORIZONTAL_ALIGNMENT_RIGHT, 90, 12, Color(col, a))
		var bar := Rect2(right - 56, 80, 56, 3)
		draw_rect(bar.grow(1), Color(Palette.OUTLINE, a))
		draw_rect(bar, Color(0.16, 0.12, 0.2, a))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * sr.progress_in_rank(), bar.size.y)), Color(col, a))

		# 콤보 수 (2 이상일 때). 끊기기까지 남은 시간을 아래 막대로
		if sr.combo >= 2:
			var cx := right - 60.0
			var num := str(sr.combo)
			var csc := 1.0 + _combo_pop * 0.35
			var nsize := _font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
			draw_set_transform(Vector2(cx - nsize.x * 0.5, 44), 0.0, Vector2(csc, csc))
			draw_string_outline(_font, Vector2(-nsize.x * 0.5, 8), num, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 5, Color(Palette.OUTLINE, a))
			draw_string(_font, Vector2(-nsize.x * 0.5, 8), num, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(Palette.UI_TEXT, a))
			draw_set_transform(Vector2.ZERO)
			draw_string_outline(_font, Vector2(cx - 60, 64), "HIT", HORIZONTAL_ALIGNMENT_RIGHT, 60, 12, 4, Color(Palette.OUTLINE, a))
			draw_string(_font, Vector2(cx - 60, 64), "HIT", HORIZONTAL_ALIGNMENT_RIGHT, 60, 12, Color(Palette.FIRE_HOT, a))
			var cbar := Rect2(cx - 28, 68, 28, 2)
			draw_rect(cbar, Color(0.16, 0.12, 0.2, a))
			draw_rect(Rect2(cbar.position, Vector2(cbar.size.x * sr.combo_ratio(), cbar.size.y)), Color(Palette.FIRE_HOT, a))

		# 최근 보너스 문구 (예: 위치 타임!) 1.2초
		var since := Time.get_ticks_msec() / 1000.0 - sr.last_event_time
		if sr.last_event != "" and since < 1.2:
			var ea := a * clampf((1.2 - since) / 0.3, 0.0, 1.0)
			draw_string_outline(_font, Vector2(right - 160, 96), sr.last_event, HORIZONTAL_ALIGNMENT_RIGHT, 160, 12, 4, Color(Palette.OUTLINE, ea))
			draw_string(_font, Vector2(right - 160, 96), sr.last_event, HORIZONTAL_ALIGNMENT_RIGHT, 160, 12, Color(Palette.GOLD, ea))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# ─── 1장 데모용 HUD (docs/chapter1.md 10절) ─────────────

	func _draw_potions(p: Player) -> void:
		if GameState.potions_max <= 0:
			return
		var x := 12.0 + p.max_hp() * 13 + 8
		for i in GameState.potions_max:
			var full := i < GameState.potions
			var c := Vector2(x + i * 10, 12)
			draw_rect(Rect2(c + Vector2(1, 0), Vector2(4, 3)), Color("#c8b8a0") if full else Color("#4a4048"))
			draw_rect(Rect2(c + Vector2(0, 3), Vector2(6, 8)), Color("#e8506a") if full else Color("#3a2a32"))
			if full:
				draw_rect(Rect2(c + Vector2(1, 4), Vector2(1, 3)), Color(1, 1, 1, 0.6))

	## 여우 모드 남은 시간(푸른 막대) / 너울의 기운(여우 문양)
	func _draw_fox(p: Player) -> void:
		if not GameState.has_ability("neoul"):
			return
		var r := Rect2(12, 30, 72, 6)
		if p.is_fox():
			var k := clampf(p.fox_time / p.fox_duration(), 0.0, 1.0)
			draw_rect(r.grow(1), Color("#0b0914"))
			draw_rect(r, Color(0.08, 0.12, 0.25))
			draw_rect(Rect2(r.position, Vector2(r.size.x * k, r.size.y)), Color(0.45, 0.78, 1.0).lerp(Color(0.9, 0.97, 1.0), 0.5 + 0.5 * sin(_t * 10.0)))
			draw_string(_font, Vector2(r.end.x + 5, r.end.y + 2), "빙의", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.88, 1.0))
		if GameState.has_ability("fox_mode"):
			# 너울의 기운: 작은 여우 얼굴, 차오르는 만큼 밝아짐
			var c := Vector2(150, 33)
			var e := p.fox_energy
			var col := Color(0.3, 0.35, 0.5).lerp(Color(0.6, 0.88, 1.0), e)
			if e >= 1.0:
				col = col.lerp(Color.WHITE, 0.3 + 0.3 * sin(_t * 4.0))
			draw_colored_polygon(PackedVector2Array([c + Vector2(-6, -3), c + Vector2(-7, -9), c + Vector2(-2, -5), c + Vector2(2, -5), c + Vector2(7, -9), c + Vector2(6, -3), c + Vector2(0, 4)]), col)
			if e < 1.0:
				draw_arc(c + Vector2(0, -2), 9, -PI * 0.5, -PI * 0.5 + TAU * e, 16, Color(0.6, 0.88, 1.0, 0.8), 1.0)
			# 꼬리 수 (장이 지날수록 늘어남)
			var nt := p.tails()
			if nt > 1:
				draw_string(_font, c + Vector2(11, 5), "×%d" % nt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.88, 1.0, 0.9))

	## 오른쪽 아래 마법 칸: A·S(장착 마법) · F(고급 마법, 배웠을 때) · D(여우창문) — docs/magic.md 3절
	func _draw_skills3(p: Player) -> void:
		var fox := p.is_fox()
		var slots := []
		for sl in [["A", "a"], ["S", "s"]]:
			var id := Spells.equipped(String(sl[1]))
			if id == "" and sl[1] == "s" and fox:
				id = "storm"
			slots.append([sl[0], id])
		if GameState.has_ability("meteor") or GameState.has_ability("phoenix"):
			slots.append(["F", Spells.equipped("f")])
		if GameState.has_ability("fox_window"):
			slots.append(["D", "window"])
		for i in slots.size():
			var sl: Array = slots[i]
			var id: String = sl[1]
			var big := String(sl[0]) == "F"
			var bs := 30.0 if big else 26.0
			var box := Rect2(640 - 34 * slots.size() + i * 34 - 2 - (4.0 if big else 0.0), 344 - bs, bs, bs)
			var unlocked := id != ""
			var cd := Vector2.ZERO
			if unlocked and id != "window":
				cd = p.spell_cooldown(id)
			var ready := unlocked and cd.x <= 0.0
			if i < 2:
				if ready and not _was_ready[i]:
					_ready_flash[i] = 1.0
				_was_ready[i] = ready
			var frame_col := Color(0.55, 0.85, 1.0, 0.6) if fox and unlocked else (Color(Palette.GOLD, 0.7) if big else Color("#0b0914"))
			draw_rect(box.grow(1), frame_col)
			draw_rect(box, Color("#241a35") if not fox else Color("#14223a"))
			if not unlocked:
				draw_string(_font, box.position + Vector2(box.size.x * 0.5 - 3, box.size.y * 0.5 + 5), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_DIM)
			else:
				_spell_icon(id, box.get_center(), ready or id == "window", fox)
				if cd.x > 0.0 and cd.y > 0.0:
					var k: float = clampf(cd.x / cd.y, 0.0, 1.0)
					draw_rect(Rect2(box.position, Vector2(box.size.x, box.size.y * k)), Color(0, 0, 0, 0.6))
					if big:
						draw_string(_font, box.position + Vector2(4, box.size.y - 4), "%d" % int(ceil(cd.x)), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.UI_TEXT)
			if i < 2 and _ready_flash[i] > 0.0:
				draw_rect(box, Color(1, 0.9, 0.7, 0.5 * _ready_flash[i]), false, 1.0)
			draw_string(_font, box.position + Vector2(2, -3), String(sl[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.GOLD if big else Palette.UI_DIM)

	## 마법별 칸 그림
	func _spell_icon(id: String, c: Vector2, ready: bool, fox: bool) -> void:
		match id:
			"pillar": _skill_icon3(0, c, ready, fox)
			"storm": _skill_icon3(1, c, ready, fox)
			"window": _skill_icon3(2, c, ready, fox)
			_:
				var a := 1.0 if ready else 0.5
				var out := Color(0.35, 0.65, 1.0) if fox else Palette.FIRE_OUT
				var hot := Color(0.85, 0.96, 1.0) if fox else Palette.FIRE_HOT
				match id:
					"ward":
						draw_arc(c, 8.0, 0.0, TAU, 16, Color(out, a), 3.0)
						draw_arc(c, 5.0, 0.0, TAU, 12, Color(hot, a), 1.0)
					"meteor":
						for j in 3:
							var o := Vector2(-6 + j * 6, -7 + j * 4)
							draw_line(c + o + Vector2(5, -5), c + o, Color(out, a * 0.7), 2.0)
							draw_circle(c + o, 2.0, Color(hot, a))
					"phoenix":
						draw_colored_polygon(PackedVector2Array([c + Vector2(-9, -5), c + Vector2(0, 2), c + Vector2(9, -5), c + Vector2(3, 6), c + Vector2(-3, 6)]), Color(out, a))
						draw_circle(c + Vector2(0, -2), 2.5, Color(hot, a))

	func _skill_icon3(kind: int, c: Vector2, ready: bool, fox: bool) -> void:
		var a := 1.0 if ready else 0.5
		var out := Color(0.35, 0.65, 1.0) if fox else Palette.FIRE_OUT
		var hot := Color(0.85, 0.96, 1.0) if fox else Palette.FIRE_HOT
		match kind:
			0:
				if fox:
					for j in 4:
						draw_line(c + Vector2(-7 + j * 4, -9), c + Vector2(-9 + j * 4, -1), Color(hot, a), 1.0)
					draw_rect(Rect2(c + Vector2(-2, -2), Vector2(4, 10)), Color(out, a))
				else:
					draw_rect(Rect2(c + Vector2(-3, -9), Vector2(6, 16)), Color(out, a))
					draw_rect(Rect2(c + Vector2(-1.5, -7), Vector2(3, 13)), Color(hot, a))
				draw_line(c + Vector2(-8, 8), c + Vector2(8, 8), Color(Palette.GROUND_TOP, a), 1.0)
			1:
				if fox:
					for j in 9:
						var ang := TAU * j / 9.0
						draw_line(c, c + Vector2(cos(ang), sin(ang)) * 9.0, Color(out, a), 2.0)
					draw_circle(c, 3.0, Color(hot, a))
				else:
					for j in 3:
						var ang2 := -0.5 + j * 0.5
						var d := Vector2(cos(ang2), sin(ang2))
						draw_colored_polygon(PackedVector2Array([c + Vector2(-7, -2), c + Vector2(-7, 0) + d * 16.0, c + Vector2(-7, 2)]), Color(out, a))
					draw_circle(c + Vector2(-7, 0), 2.5, Color(hot, a))
			2:
				# 여우창문: 마름모 창
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -9), c + Vector2(9, 0), c + Vector2(0, 9), c + Vector2(-9, 0)]), Color(0.55, 0.85, 1.0, 0.35 * a))
				draw_arc(c, 5.0, 0, TAU, 12, Color(0.85, 0.96, 1.0, a), 1.0)

	func _draw_objective() -> void:
		var text := Objectives.current()
		if text != _obj_text:
			_obj_text = text
			_obj_flash = 1.0
			if text != "" and Engine.get_frames_drawn() > 60:
				Music.jingle("jingle_quest")
		_obj_flash = maxf(_obj_flash - get_process_delta_time(), 0.0)
		if text == "":
			return
		var in_combat := StyleRank.combo >= 2 or _boss_shown > 0.0
		var a := 0.45 if in_combat else 0.9
		var y := 52.0
		var tr := Quests.tracker_line()
		# 밝은 배경(하늘·창)에서도 읽히게 옅은 어둠 띠
		var bw := minf(_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x, 300.0)
		if tr != "":
			bw = maxf(bw, minf(_font.get_string_size(tr, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x, 320.0))
		draw_rect(Rect2(9, y - 4, bw + 16, 30 if tr != "" else 17), Color(0.02, 0.01, 0.05, 0.35 * a))
		draw_rect(Rect2(12, y - 2, 3, 13), Color(Palette.GOLD, a))
		draw_string(_font, Vector2(19, y + 9), text, HORIZONTAL_ALIGNMENT_LEFT, 300, 12, Color(Palette.UI_TEXT, a).lerp(Palette.GOLD, _obj_flash))
		if tr != "":
			draw_rect(Rect2(12, y + 14, 3, 11), Color(0.6, 0.8, 1.0, a * 0.8))
			draw_string(_font, Vector2(19, y + 23), tr, HORIZONTAL_ALIGNMENT_LEFT, 320, 12, Color(Palette.UI_DIM, a))

	func _draw_boss() -> void:
		var boss: EnemyBase = null
		for e in get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
			if e is EnemyBase and e.is_boss and e.is_alive() and e.get("engaged") != false:
				boss = e
				break
		_boss_shown = move_toward(_boss_shown, 1.0 if boss else 0.0, get_process_delta_time() * 3.0)
		if boss == null:
			return
		var a := _boss_shown
		var r := Rect2(110, 336, 340, 6) if TouchControls.shown else Rect2(120, 336, 400, 6) # 터치 버튼과 겹치지 않게
		draw_string(_font, Vector2(r.position.x, 330), boss.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(Palette.UI_TEXT, a))
		if boss.subtitle != "":
			draw_string(_font, Vector2(r.end.x - _font.get_string_size(boss.subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x, 330), boss.subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(Palette.UI_DIM, a))
		draw_rect(r.grow(1), Color(0.03, 0.02, 0.05, a))
		draw_rect(r, Color(0.2, 0.08, 0.1, a))
		var k := clampf(float(boss.hp) / boss.max_hp, 0.0, 1.0)
		draw_rect(Rect2(r.position, Vector2(r.size.x * k, r.size.y)), Color(0.85, 0.2, 0.25, a))
		draw_rect(Rect2(r.position, Vector2(r.size.x * k, 1)), Color(1, 0.6, 0.6, a))
		# 첫 빙의 지점 (대본이 boss에 fox_mark를 달아 둔 동안): 푸른 눈금 + "빙의"
		if boss.has_meta("fox_mark"):
			var mx: float = r.position.x + r.size.x * float(boss.get_meta("fox_mark"))
			var blue := Color(0.55, 0.85, 1.0, a * (0.75 + 0.25 * sin(Time.get_ticks_msec() * 0.008)))
			draw_rect(Rect2(mx - 1, r.position.y - 4, 2, r.size.y + 8), blue)
			draw_string(_font, Vector2(mx - 10, r.end.y + 13), "빙의", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, blue)

	## 정예 적 머리 위 작은 체력바 (맞은 직후 2.5초)
	func _draw_elite_bars(w: World) -> void:
		var xf := w.get_viewport().get_canvas_transform()
		for e in get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
			if not (e is EnemyBase) or not e.show_bar():
				continue
			var sp: Vector2 = xf * (e.global_position + Vector2(0, -e.body_size.y - 10))
			var r := Rect2(sp.x - 14, sp.y, 28, 3)
			draw_rect(r.grow(1), Color(0.03, 0.02, 0.05, 0.8))
			draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(float(e.hp) / e.max_hp, 0.0, 1.0), r.size.y)), Color(0.9, 0.3, 0.3))

	## 오른쪽 위 미니맵: 지금 지역의 다녀간 방들 (칸 하나 = 화면 1칸). 터치하면 지도가 열림 (docs/systems2.md)
	func _draw_minimap(w: World) -> void:
		if w.room == null or w.room.data == null:
			return
		var box := Rect2(506, 6, 96, 52)
		draw_rect(box, Color(0.02, 0.015, 0.04, 0.55))
		draw_rect(box, Color(0.55, 0.5, 0.75, 0.5), false, 1.0)
		var cur := w.room.data
		var cw := 12.0
		var ch := 7.0
		var center := box.get_center()
		var pr := (w.player.global_position / w.room.size_px).clamp(Vector2.ZERO, Vector2.ONE)
		var focus := Vector2(cur.cell) + Vector2(cur.cells) * pr
		for id in RoomIndex.all():
			var d := RoomIndex.data(id)
			if d == null or d.area != cur.area or not GameState.visited.has(id):
				continue
			var r := Rect2(center + (Vector2(d.cell) - focus) * Vector2(cw, ch), Vector2(d.cells) * Vector2(cw, ch))
			r = r.grow(-0.5)
			var clip := r.intersection(box.grow(-2))
			if clip.size.x <= 0.0 or clip.size.y <= 0.0:
				continue
			var is_cur: bool = d.id == cur.id
			draw_rect(clip, Color("#4a3a6a") if is_cur else Color("#2a2440"))
			draw_rect(clip, Color("#8a80b0", 0.8), false, 1.0)
		draw_circle(center, 2.0 + 0.6 * sin(_t * 6.0), Color(1.0, 0.45, 0.35))
