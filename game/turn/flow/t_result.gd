class_name TResult
extends Control
## 결과 화면: 승리/패배 · 소요 칸 · 최고 한 방과 배율 풀이 · 마녀별 피해 비중 · 얻은 점수·레벨. [다음] / [다시]

signal next

var run: TRun
var won := false
var summary := {}
var battle_name := ""
var points_gained := 0
var levels_before := {}
var finale := false
var _t := 0.0
var _btn := Rect2()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_btn = Rect2(440, 300, 180, 44)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _input(event: InputEvent) -> void:
	if _t < 0.4:
		return
	var hit := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hit = _btn.has_point((event as InputEventMouseButton).position)
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_Z]:
		hit = true
	if hit:
		Sfx.play(&"ui_ok", -4.0, 0.0)
		get_viewport().set_input_as_handled()
		next.emit()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("#0e0a16"))
	var title := ""
	if finale:
		title = "시험판 끝 — 재의 기사왕을 넘어섰다"
	elif won:
		title = "승리 — " + battle_name
	else:
		title = "쓰러졌다 — " + battle_name
	TUi.text(self, Vector2(20, 40), title, 20, TUi.GOLD if won else TUi.RED)
	var rounds := int(summary.get("rounds", 0))
	var turns := int(summary.get("turns", 0))
	TUi.text(self, Vector2(20, 64), "라운드 %d · 행동 %d · 물약 %d개" % [rounds, turns, int(summary.get("potions", 0))], 12, TUi.TEXT)
	# 최고 한 방 + 배율 풀이
	var mh := int(summary.get("max_hit", 0))
	var info: Dictionary = summary.get("max_hit_info", {})
	var y := 96.0
	TUi.text(self, Vector2(20, y), "이 전투의 최고 한 방", 12, TUi.PALE)
	if mh > 0:
		var who := String(TData.witch(String(info.get("unit", ""))).get("name", ""))
		var sp := String(TData.spell(String(info.get("spell", ""))).get("name", ""))
		TUi.text(self, Vector2(20, y + 28), TUi.fmt(mh), 30, TUi.EDGE)
		TUi.text(self, Vector2(20 + TUi.text_w(TUi.fmt(mh), 30) + 10, y + 28), who + " · " + sp + (" · 치명" if bool(info.get("crit", false)) else "") + (" · 약점" if bool(info.get("weak", false)) else ""), 12, TUi.TEXT)
		var m: Dictionary = info.get("mult", {})
		var names := {"atk": "공격", "elem": "속성", "crit": "치명", "final": "최종(틈)", "vuln": "취약", "aff": "상성", "def": "방어"}
		var parts: Array[String] = []
		for key in ["atk", "elem", "crit", "final", "vuln", "aff", "def"]:
			var v := float(m.get(key, 1.0))
			if absf(v - 1.0) > 0.005:
				parts.append(String(names[key]) + " ×%.2f" % v)
		TUi.text(self, Vector2(20, y + 46), "배율: " + (" · ".join(parts) if not parts.is_empty() else "기본"), 10, TUi.DIM, HORIZONTAL_ALIGNMENT_LEFT, 600)
	if run.best_hit > 0:
		TUi.text(self, Vector2(20, y + 64), "통산 최고 " + TUi.fmt(run.best_hit), 10, TUi.EDGE)
	# 피해 비중
	var dealt: Dictionary = summary.get("dealt", {})
	var total := 0
	for k in dealt.keys():
		total += int(dealt[k])
	var by := 190.0
	TUi.text(self, Vector2(20, by), "준 피해", 12, TUi.PALE)
	var bx := 20.0
	for w in run.party:
		var d: Dictionary = TData.witch(w)
		var v := int(dealt.get(w, 0))
		var f := float(v) / float(maxi(total, 1))
		TUi.text(self, Vector2(bx, by + 18), String(d.name), 11, Color(String(d.color)).lightened(0.2))
		TUi.bar(self, Rect2(bx, by + 24, 120, 8), f, Color(String(d.color)))
		TUi.text(self, Vector2(bx, by + 44), TUi.fmt(v) + " (" + TUi.pct(f) + ")", 10, TUi.TEXT)
		bx += 136.0
	# 보상
	var ry := 262.0
	if won and not finale:
		TUi.text(self, Vector2(20, ry), "수업 점수 +%d → %d점 · 교실에서 새 마법을 배우세요" % [points_gained, run.points], 11, TUi.GOLD)
		var ups: Array[String] = []
		for w in run.party:
			if int(run.levels.get(w, 1)) > int(levels_before.get(w, 1)):
				ups.append(String(TData.witch(w).name) + " Lv" + str(run.levels[w]))
		if not ups.is_empty():
			TUi.text(self, Vector2(20, ry + 16), "레벨 업: " + " · ".join(ups), 11, TUi.GREEN)
	elif finale:
		TUi.text(self, Vector2(20, ry), "다른 딜러·빗자루·해금으로 다시 해 보세요 — 최고 한 방을 갱신해 봅시다.", 11, TUi.GOLD, HORIZONTAL_ALIGNMENT_LEFT, 420)
	else:
		TUi.text(self, Vector2(20, ry), "물약은 돌려받았어요. 교실에서 빌드를 바꿔 다시 도전.", 11, TUi.TEXT, HORIZONTAL_ALIGNMENT_LEFT, 420)
		TUi.text(self, Vector2(20, ry + 16), "힌트: 시전은 봉공·물약으로 끊고, 취약(기름)을 깐 뒤 대마법.", 10, TUi.DIM, HORIZONTAL_ALIGNMENT_LEFT, 420)
	var label := "처음으로" if finale else ("다음 ▶" if won else "다시 도전")
	TUi.button(self, _btn, label, TUi.GOLD, 14, fmod(_t, 1.2) < 0.7)
