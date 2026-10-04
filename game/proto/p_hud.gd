class_name PHud
extends Control
## 훈련장 HUD — 결정: 왼쪽 위 체력 하트·마나 칸·변신 게이지·물약, 아래 가운데 마법 7칸 퀵슬롯(키 글자·쿨 가림·마나 부족).
## H = 조작 안내 켜기/끄기, Tab = 시험 패널.

var sera: PSera
var _t := 0.0
var _pip_flash := 0.0
var _font: Font


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font


func _process(delta: float) -> void:
	_t += delta
	_pip_flash = maxf(_pip_flash - delta * 3.0, 0.0)
	PSpells.last_fail_t = maxf(PSpells.last_fail_t - delta, 0.0)
	if Input.is_action_just_pressed("pr_keys"):
		PState.show_keys = not PState.show_keys
	queue_redraw()


func flash_pip() -> void:
	_pip_flash = 1.0


func _text(p: Vector2, s: String, col := Color(1, 1, 1), size := 12, align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0) -> void:
	draw_string(_font, p + Vector2(1, 1), s, align, w, size, Color(0, 0, 0, 0.7 * col.a))
	draw_string(_font, p, s, align, w, size, col)


func _draw() -> void:
	if sera == null:
		return
	_draw_status()
	_draw_slots()
	if PState.show_keys:
		_draw_keys()
	_text(Vector2(452, 352), "Tab 시험 패널 · H 조작 안내 · Esc 나가기", Color(1, 1, 1, 0.55), 10)


# ─── 왼쪽 위: 체력·마나·변신·물약 ───────────────────────

func _draw_status() -> void:
	var o := Vector2(10, 10)
	# 반투명 받침
	draw_rect(Rect2(o - Vector2(4, 4), Vector2(150, 56)), Color(0.04, 0.02, 0.08, 0.35))
	# 체력 하트 (반 칸)
	for i in PData.MAX_HEARTS:
		var full := sera.hp2 - i * 2
		var p := o + Vector2(i * 15, 0)
		_heart(p, 0, Color(0.15, 0.1, 0.18))
		if full >= 2:
			_heart(p, 0, Color("#ff5a6e"))
		elif full == 1:
			_heart(p, 1, Color("#ff5a6e"))
	if sera.revive > 0:
		# 불사조 부활 표시
		var p := o + Vector2(PData.MAX_HEARTS * 15 + 4, 1)
		var g := 0.6 + 0.4 * sin(_t * 4.0)
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, 10), p + Vector2(-6, 2), p + Vector2(-3, 4), p + Vector2(0, -2), p + Vector2(3, 4), p + Vector2(6, 2)]), Color(1, 0.6, 0.2, g))
	# 마나 칸
	var mo := o + Vector2(2, 20)
	for i in PState.mana_max:
		var c := mo + Vector2(i * 14 + 5, 5)
		draw_circle(c, 5.6, Color(0.05, 0.03, 0.1))
		draw_arc(c, 5.6, 0, TAU, 18, Color(1, 0.7, 0.4, 0.5), 1.0)
		var fill := clampf(sera.mana - float(i), 0.0, 1.0)
		if fill >= 1.0:
			draw_circle(c, 4.4, Color("#ffb347"))
			draw_circle(c + Vector2(-1.2, -1.2), 1.8, Color("#fff3d6"))
		elif fill > 0.0:
			draw_arc(c, 3.0, -PI / 2, -PI / 2 + TAU * fill, 16, Color("#ffb347"), 2.6)
	if _pip_flash > 0.0:
		draw_rect(Rect2(mo - Vector2(2, 0), Vector2(PState.mana_max * 14 + 4, 12)), Color(1, 0.8, 0.4, 0.25 * _pip_flash))
	# 변신 게이지 / 변신 남은 시간
	var go := o + Vector2(0, 36)
	draw_rect(Rect2(go, Vector2(84, 6)), Color(0.05, 0.03, 0.1))
	if sera.is_fox():
		var k := sera.fox_time / PState.transform_time()
		draw_rect(Rect2(go + Vector2(1, 1), Vector2(82 * k, 4)), PData.FOX_HOT)
		_text(go + Vector2(88, 7), "변신 중", PData.FOX_HOT, 10)
	else:
		var full := sera.gauge >= 1.0
		var col := PData.FOX_MID.lerp(PData.FOX_CORE, 0.5 + 0.5 * sin(_t * 8.0)) if full else PData.FOX_MID
		draw_rect(Rect2(go + Vector2(1, 1), Vector2(82 * sera.gauge, 4)), col)
		if full:
			_text(go + Vector2(88, 7), "Space 변신!", PData.FOX_HOT, 10)
	# 물약
	var po := o + Vector2(0, 46)
	for i in sera.potions_max:
		var p := po + Vector2(i * 10, 0)
		var have := i < sera.potions
		draw_rect(Rect2(p + Vector2(2, 0), Vector2(3, 2)), Color(0.8, 0.7, 0.6, 0.8 if have else 0.3))
		draw_rect(Rect2(p + Vector2(0, 2), Vector2(7, 7)), Color("#e0405a") if have else Color(0.2, 0.15, 0.2))
	_text(po + Vector2(sera.potions_max * 10 + 3, 9), "G", Color(1, 1, 1, 0.6), 10)
	_text(po + Vector2(60, 9), "꼬리 %d" % PState.tails, Color(0.85, 0.92, 1.0, 0.8), 10)


func _heart(p: Vector2, half: int, col: Color) -> void:
	var pts := PackedVector2Array([p + Vector2(6, 11), p + Vector2(0, 5), p + Vector2(0, 2), p + Vector2(2, 0), p + Vector2(4, 0),
		p + Vector2(6, 2), p + Vector2(8, 0), p + Vector2(10, 0), p + Vector2(12, 2), p + Vector2(12, 5)])
	if half == 1:
		pts = PackedVector2Array([p + Vector2(6, 11), p + Vector2(0, 5), p + Vector2(0, 2), p + Vector2(2, 0), p + Vector2(4, 0), p + Vector2(6, 2)])
	draw_colored_polygon(pts, col)
	if col.r > 0.5:
		draw_rect(Rect2(p + Vector2(2, 2), Vector2(2, 2)), Color(1, 1, 1, 0.7))


# ─── 아래 가운데: 마법 7칸 ────────────────────────────

func _draw_slots() -> void:
	# 칸 순서: 등급 키면 키 묶음(A·S·D)대로, 전용 키면 마법 표 순서
	var order: Array = ["fireball", "foxrain", "laser", "meteor", "asura", "bind", "phoenix"] if PState.key_mode == 0 else PData.SPELLS.map(func(x: Dictionary) -> String: return String(x.id))
	var groups: Array = [0, 0, 1, 1, 1, 2, 2] if PState.key_mode == 0 else [0, 0, 0, 0, 0, 1, 1]
	var n := order.size()
	var w := 26.0
	var gap := 3.0
	var total := n * w + (n - 1) * gap + 6.0 * float(groups[n - 1])
	var x0 := (640.0 - total) / 2.0 + 3.0
	var y0 := 360.0 - w - 14.0
	draw_rect(Rect2(x0 - 5, y0 - 5, total + 4, w + 16), Color(0.04, 0.02, 0.08, 0.45))
	for i in n:
		var s: Dictionary = PData.spell(order[i])
		var x := x0 + i * (w + gap) + 6.0 * float(groups[i]) # 키 묶음(등급)마다 살짝 떨어뜨림
		var r := Rect2(x, y0, w, w)
		var fox_line: bool = s.line == "fox"
		var lack := sera.mana + 0.0001 < float(s.cost) and not PState.infinite_mana
		draw_rect(r, Color(0.1, 0.07, 0.16))
		draw_rect(r.grow(-1), Color(0.18, 0.12, 0.28) if not fox_line else Color(0.1, 0.14, 0.3))
		_icon(String(s.id), r.get_center(), lack)
		var cd := float(sera.cooldowns.get(s.id, 0.0))
		if cd > 0.0:
			var k := cd / float(s.cd)
			draw_rect(Rect2(r.position, Vector2(w, w * k)), Color(0, 0, 0, 0.65))
			_text(r.position + Vector2(0, 17), "%d" % ceili(cd) if cd >= 1.0 else "%.1f" % cd, Color(1, 1, 1, 0.9), 10, HORIZONTAL_ALIGNMENT_CENTER, w)
		if lack:
			draw_rect(r, Color(0.05, 0.05, 0.15, 0.45))
		if PSpells.last_fail == s.id and PSpells.last_fail_t > 0.0:
			draw_rect(r, Color(1, 0.2, 0.2, PSpells.last_fail_t * 1.6), false, 2.0)
		var border := Color("#ffb347") if not fox_line else PData.FOX_HOT
		if PState.awakened(String(s.id)):
			border = Color(1, 1, 0.6, 0.6 + 0.4 * sin(_t * 5.0))
		draw_rect(r, border, false, 1.0)
		# 키 글자 + 소모 칸
		_text(r.position + Vector2(2, 9), PState.spell_label(String(s.id)), Color(1, 1, 1, 0.9), 10)
		for c in int(s.cost):
			draw_circle(r.position + Vector2(w - 4 - c * 4, w + 5), 1.6, Color("#ffb347"))
		_text(r.position + Vector2(0, w + 12), "Lv%d" % PState.level(String(s.id)), Color(1, 1, 1, 0.45), 8, HORIZONTAL_ALIGNMENT_LEFT)


## 퀵슬롯 아이콘 (간단한 상징 그림)
func _icon(id: String, c: Vector2, dim: bool) -> void:
	var a := 0.45 if dim else 1.0
	var fire := Color(PData.FIRE_MID, a)
	var hot := Color(PData.FIRE_HOT, a)
	var fx := Color(PData.FOX_MID, a)
	var fh := Color(PData.FOX_HOT, a)
	match id:
		"fireball":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-8, -3), c + Vector2(2, -5), c + Vector2(2, 5), c + Vector2(-8, 3), c + Vector2(-4, 0)]), fire)
			draw_circle(c + Vector2(3, 0), 5.0, fire)
			draw_circle(c + Vector2(4, -1), 3.0, hot)
		"foxrain":
			for i in 4:
				var x := -7 + i * 4.6
				draw_line(c + Vector2(x, -8 + i % 2 * 3), c + Vector2(x + 1, 2 + i % 2 * 3), fh, 2.0)
			draw_line(c + Vector2(-9, 8), c + Vector2(9, 8), fx, 1.0)
		"asura":
			for i in 3:
				var ang := i * 2.1
				PVfx.crescent(self, c, 8.0, ang, ang + 1.8, 2.4, fh, 10)
		"laser":
			draw_rect(Rect2(c + Vector2(-9, -2), Vector2(18, 4)), hot)
			draw_rect(Rect2(c + Vector2(-9, -1), Vector2(18, 2)), Color(1, 1, 1, a))
			for i in 4:
				draw_arc(c + Vector2(-6 + i * 4, 0), 4.0, -1.0, 1.0, 6, fire, 1.0)
		"meteor":
			draw_circle(c + Vector2(3, 3), 5.0, fire)
			draw_circle(c + Vector2(4, 2), 3.0, hot)
			for i in 3:
				draw_line(c + Vector2(-8 + i * 2, -8 + i * 2), c + Vector2(-1 + i, -1 + i), Color(hot, 0.6 * a), 1.0)
			draw_arc(c + Vector2(0, -7), 6.0, 0, TAU, 12, Color(hot, 0.5 * a), 1.0)
		"phoenix":
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -2), c + Vector2(-9, -8), c + Vector2(-5, 0), c + Vector2(-9, 6), c + Vector2(0, 2), c + Vector2(9, 6), c + Vector2(5, 0), c + Vector2(9, -8)]), fire)
			draw_circle(c, 2.4, hot)
		"bind":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-8, -2), c + Vector2(-9, -9), c + Vector2(-4, -5), c + Vector2(4, -5), c + Vector2(9, -9), c + Vector2(8, -2), c + Vector2(0, 8)]), fx)
			draw_rect(Rect2(c + Vector2(-4, -2), Vector2(2, 2)), fh)
			draw_rect(Rect2(c + Vector2(2, -2), Vector2(2, 2)), fh)


# ─── 오른쪽 위: 조작 안내 ─────────────────────────────

const KEY_GUIDE_GRADE := [
	["← →", "이동"], ["Z", "점프 · 공중 2단 · 다시 꾹 = 활공"], ["벽 + Z", "벽 점프 (붙으면 미끄러짐)"],
	["X", "발톱 3연타 (↑위 · 공중↓아래)"], ["C", "대시 (변신 중 = 의태 돌진)"], ["마나", "발톱으로 때리면 참 · 저절로 천천히"],
	["Space", "변신 (게이지 가득)"], ["G", "물약"],
	["A", "초급: 파이어볼 · ↓여우비"], ["S", "중급: 열선(꾹) · ↑대유성 · ↓난무"], ["D", "대마법: 바인드 · ↑불사조"], ["↑", "석등에서 쉬기"],
]
const KEY_GUIDE_DIRECT := [
	["← →", "이동"], ["Z", "점프 · 공중 2단 · 다시 꾹 = 활공"], ["벽 + Z", "벽 점프 (붙으면 미끄러짐)"],
	["X", "발톱 3연타 (↑위 · 공중↓아래)"], ["Shift", "대시 (변신 중 = 의태 돌진)"], ["마나", "발톱으로 때리면 참 · 저절로 천천히"],
	["Space", "변신 (게이지 가득)"], ["G", "물약"],
	["A S F", "파이어볼·여우비·발톱 난무"], ["Q W", "압축 열선(꾹)·대유성"], ["E R", "불사조·너울 바인드"], ["↑", "석등에서 쉬기"],
]


func _draw_keys() -> void:
	var x := 424.0
	var y := 8.0
	var guide: Array = KEY_GUIDE_GRADE if PState.key_mode == 0 else KEY_GUIDE_DIRECT
	draw_rect(Rect2(x - 6, y - 4, 218, guide.size() * 12 + 8), Color(0.04, 0.02, 0.08, 0.55))
	for i in guide.size():
		var row: Array = guide[i]
		_text(Vector2(x, y + 9 + i * 12), String(row[0]), Color("#ffd27a"), 10)
		_text(Vector2(x + 48, y + 9 + i * 12), String(row[1]), Color(1, 1, 1, 0.85), 10)
