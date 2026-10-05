class_name PHud
extends Control
## 훈련장 HUD — 왼쪽 위: 문장·체력 하트·폭주 게이지·물약·꼬리 / 아래 가운데: 마법 6칸(등급 묶음, 원형 쿨, 레벨 점).
## 도형은 PDraw로 모아 그리기 호출 1번, 글자는 그 위에 따로(글자는 같은 글꼴 텍스처라 엔진이 묶어 그린다).
## H = 조작 안내 켜기/끄기, Tab = 시험 패널.

var sera: PSera
var pd := PDraw.new()
var _t := 0.0
var _font: Font
var _texts: Array = [] ## 이번 프레임 글자 [위치, 글, 색, 크기, 정렬, 폭]
var _gauge_shown := 0.0 ## 화면에 보이는 폭주 게이지 (실제 값을 부드럽게 따라감)
var _gauge_gain := 0.0 ## 막 찬 부분 (흰빛으로 먼저 보임)
var _hp_prev := -1
var _heart_break: Array = [] ## [하트 번호, 남은 시간]
var _cd_prev := {} ## 마법 ID → 지난 프레임 쿨 (끝나는 순간 반짝임)
var _ready_flash := {} ## 마법 ID → 남은 반짝임
var _seal_t := 0.0

const PANEL := Color(0.04, 0.02, 0.08, 0.62)
const EDGE := Color("#4a3a66")
const GOLD := Color("#d8a855")
const HEART := Color("#ff4d64")
const HEART_D := Color("#a81d3a")
const BREAK := 0.45


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font


func _process(delta: float) -> void:
	_t += delta
	PSpells.last_fail_t = maxf(PSpells.last_fail_t - delta, 0.0)
	if Input.is_action_just_pressed("pr_keys"):
		PState.show_keys = not PState.show_keys
	if sera:
		_track(delta)
	queue_redraw()


## 바뀐 것 따라가기: 게이지 부드럽게, 하트 깨짐, 쿨 끝 반짝임
func _track(delta: float) -> void:
	var g := 0.0 if sera.is_fox() else sera.gauge
	if g > _gauge_shown:
		_gauge_gain = g
		_gauge_shown = move_toward(_gauge_shown, g, delta * 1.2)
	else:
		_gauge_shown = g
		_gauge_gain = g
	if _hp_prev >= 0 and sera.hp2 < _hp_prev:
		for u in range(sera.hp2, _hp_prev):
			var hi := int(u / 2.0)
			if not _heart_break.any(func(hb: Array) -> bool: return int(hb[0]) == hi):
				_heart_break.append([hi, BREAK])
	_hp_prev = sera.hp2
	for hb: Array in _heart_break:
		hb[1] = float(hb[1]) - delta
	_heart_break = _heart_break.filter(func(hb: Array) -> bool: return float(hb[1]) > 0.0)
	for s: Dictionary in PData.SPELLS:
		var id: String = s.id
		var cd := float(sera.cooldowns.get(id, 0.0))
		if float(_cd_prev.get(id, 0.0)) > 0.0 and cd <= 0.0:
			_ready_flash[id] = 0.35
		_cd_prev[id] = cd
		if _ready_flash.has(id):
			_ready_flash[id] = float(_ready_flash[id]) - delta
			if float(_ready_flash[id]) <= 0.0:
				_ready_flash.erase(id)
	_seal_t = _seal_t + delta if sera.overloaded() else 0.0


func _text(p: Vector2, s: String, col := Color(1, 1, 1), size := 10, align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0) -> void:
	_texts.append([p, s, col, size, align, w])


func _draw() -> void:
	if sera == null:
		return
	_texts.clear()
	_draw_status()
	_draw_slots()
	if PState.show_keys:
		_draw_keys()
	_text(Vector2(332, 355), "Tab 시험 패널 · H 조작 안내 · Esc 나가기", Color(1, 1, 1, 0.4), 9, HORIZONTAL_ALIGNMENT_RIGHT, 300.0)
	pd.flush(self)
	for tx: Array in _texts:
		var p: Vector2 = tx[0]
		var col: Color = tx[2]
		draw_string(_font, p + Vector2(1, 1), tx[1], tx[4], tx[5], tx[3], Color(0, 0, 0, 0.75 * col.a))
		draw_string(_font, p, tx[1], tx[4], tx[5], tx[3], col)


# ─── 왼쪽 위: 문장·체력·폭주 게이지·물약 ───────────────────

func _panel(r: Rect2) -> void:
	pd.draw_rect(r, PANEL)
	pd.draw_rect(r, EDGE, false, 1.0)
	# 금 모서리
	var e := r.end - Vector2.ONE
	for c: Vector2 in [r.position, Vector2(e.x, r.position.y), Vector2(r.position.x, e.y), e]:
		var left := c.x < r.get_center().x
		var top := c.y < r.get_center().y
		pd.draw_rect(Rect2(c.x if left else c.x - 4, c.y, 5, 1), GOLD)
		pd.draw_rect(Rect2(c.x, c.y if top else c.y - 4, 1, 5), GOLD)


func _draw_status() -> void:
	var o := Vector2(8, 6)
	_panel(Rect2(o, Vector2(176, 58)))
	_emblem(o + Vector2(17, 20))
	# 하트 (반 칸 단위). 잃은 칸은 흰빛으로 부풀며 사라지고, 1칸 이하면 두근거림
	var hx := o + Vector2(35, 5)
	for i in PData.MAX_HEARTS:
		var full := sera.hp2 - i * 2
		var p := hx + Vector2(i * 14, 0)
		var lost := 0.0
		for hb: Array in _heart_break:
			if int(hb[0]) == i:
				lost = float(hb[1]) / BREAK
		var beat := 1.0 + (0.14 * maxf(sin(_t * 9.0), 0.0) if sera.hp2 <= 2 and full > 0 else 0.0)
		_heart(p, 2, Color(0.12, 0.08, 0.16), 1.0)
		if full >= 2:
			_heart(p, 2, HEART, beat)
		elif full == 1:
			_heart(p, 1, HEART, beat)
		if lost > 0.0:
			_heart(p, 2, Color(1, 1, 1, lost * 0.9), 1.0 + (1.0 - lost) * 0.7)
	if sera.revive > 0:
		var p := hx + Vector2(PData.MAX_HEARTS * 14 + 7, 6)
		var g := 0.6 + 0.4 * sin(_t * 4.0)
		pd.glow(p, 10.0, Color(1, 0.5, 0.15, 0.35 * g))
		pd.draw_colored_polygon(PackedVector2Array([p + Vector2(0, 6), p + Vector2(-7, -3), p + Vector2(-3, -1), p + Vector2(0, -7), p + Vector2(3, -1), p + Vector2(7, -3)]), Color(1, 0.62, 0.22, 0.6 + 0.4 * g))
	# 폭주 게이지 / 변신 남은 시간
	var bx := o + Vector2(35, 30)
	var bw := 128.0
	var bh := 7.0
	pd.draw_rect(Rect2(bx - Vector2(1, 1), Vector2(bw + 2, bh + 2)), Color(0.02, 0.01, 0.04, 0.95))
	if sera.is_fox():
		var k := clampf(sera.fox_time / PState.transform_time(), 0.0, 1.0)
		pd.rect_hgrad(Rect2(bx, Vector2(bw * k, bh)), PData.FOX_DARK, PData.FOX_HOT)
		pd.draw_rect(Rect2(bx, Vector2(bw * k, 2)), Color(1, 1, 1, 0.35))
		pd.draw_rect(Rect2(bx + Vector2(bw * k - 1, 0), Vector2(2, bh)), PData.FOX_CORE)
		pd.draw_rect(Rect2(bx - Vector2(1, 1), Vector2(bw + 2, bh + 2)), Color(PData.FOX_HOT, 0.7), false, 1.0)
		_text(bx + Vector2(0, -2), "변신  %.1f초" % sera.fox_time, PData.FOX_HOT, 9)
	else:
		var g := _gauge_shown
		var full := sera.gauge >= 1.0
		if _gauge_gain > g:
			pd.draw_rect(Rect2(bx, Vector2(bw * _gauge_gain, bh)), Color(1, 0.85, 0.55, 0.55))
		var end_col := PData.FIRE_HOT.lerp(Color("#ff2a1a"), g)
		if full:
			end_col = end_col.lerp(PData.FIRE_CORE, 0.5 + 0.5 * sin(_t * 8.0))
		elif g >= 0.9:
			end_col = end_col.lerp(Color.WHITE, 0.3 + 0.3 * sin(_t * 14.0))
		if g > 0.005:
			pd.rect_hgrad(Rect2(bx, Vector2(bw * g, bh)), Color("#7a160f"), end_col)
			pd.draw_rect(Rect2(bx, Vector2(bw * g, 2)), Color(1, 1, 1, 0.25))
			pd.draw_rect(Rect2(bx + Vector2(bw * g - 1, 0), Vector2(2, bh)), Color(1, 0.95, 0.8, 0.9))
		pd.draw_rect(Rect2(bx + Vector2(bw * 0.7, 0), Vector2(1, bh)), Color(1, 1, 1, 0.3)) # 70%: 불티가 이는 지점
		var edge_a := 0.55 + (0.4 * sin(_t * 8.0) if full else 0.0)
		pd.draw_rect(Rect2(bx - Vector2(1, 1), Vector2(bw + 2, bh + 2)), Color(1, 0.55, 0.3, edge_a), false, 1.0)
		if full:
			# 막대 위로 일렁이는 불 혀
			for i in 9:
				var x := bx.x + 6.0 + i * 14.5
				var h := 4.0 + 3.0 * sin(_t * 12.0 + i * 1.7)
				pd.draw_colored_polygon(PackedVector2Array([Vector2(x - 3, bx.y), Vector2(x + sin(_t * 9.0 + i) * 1.5, bx.y - h), Vector2(x + 3, bx.y)]), Color(1.0, 0.55 + 0.2 * sin(_t * 7.0 + i), 0.2, 0.85))
		_text(bx + Vector2(0, -2), "폭주", Color(1, 0.72, 0.5, 0.95), 9)
		_text(bx + Vector2(bw - 60, -2), "%d%%" % int(floor(sera.gauge * 100.0 + 0.001)), Color(1, 0.8, 0.6, 0.7), 8, HORIZONTAL_ALIGNMENT_RIGHT, 60.0)
		if full:
			var blink := 0.65 + 0.35 * sin(_t * 6.0)
			pd.draw_rect(Rect2(o + Vector2(0, 61), Vector2(150, 14)), Color(0.25, 0.03, 0.02, 0.7 * blink))
			_text(o + Vector2(5, 72), "마법 봉인 — Space로 변신!", Color(1, 0.82, 0.5, blink), 10)
	# 물약 · 꼬리
	var po := o + Vector2(35, 41)
	for i in sera.potions_max:
		var p := po + Vector2(i * 11, 0)
		var have := i < sera.potions
		pd.draw_rect(Rect2(p + Vector2(2.5, 0), Vector2(3, 3)), Color(0.8, 0.7, 0.6, 0.85 if have else 0.3))
		pd.draw_circle(p + Vector2(4, 8), 4.4, Color(0.05, 0.02, 0.06))
		pd.draw_circle(p + Vector2(4, 8), 3.5, Color("#e0405a") if have else Color(0.22, 0.16, 0.24))
		if have:
			pd.draw_rect(Rect2(p + Vector2(2, 6), Vector2(1, 2)), Color(1, 1, 1, 0.7))
	_text(po + Vector2(sera.potions_max * 11 + 2, 11), "G", Color(1, 1, 1, 0.5), 9)
	var tx := po + Vector2(62, 4)
	var tn := mini(PState.tails, 9)
	for i in tn:
		var q := tx + Vector2(i * 4.5, 0)
		pd.draw_colored_polygon(PackedVector2Array([q + Vector2(0, 7), q + Vector2(1, 1), q + Vector2(4, -1), q + Vector2(3, 6)]), PData.FOX_HOT if sera.is_fox() else Color(0.92, 0.95, 1.0, 0.85))
	_text(tx + Vector2(tn * 4.5 + 4, 7), "꼬리 %d" % PState.tails, Color(0.85, 0.92, 1.0, 0.75), 9)


## 왼쪽 문장: 평소 = 남색 마녀 모자, 변신 = 흰 여우 얼굴. 봉인되면 붉게 달아오름
func _emblem(c: Vector2) -> void:
	var fox := sera.is_fox()
	var ring := PData.FOX_HOT if fox else GOLD
	if sera.overloaded():
		pd.glow(c, 20.0, Color(1, 0.35, 0.15, 0.3 + 0.15 * sin(_t * 8.0)))
	pd.draw_circle(c, 12.5, Color(0.02, 0.01, 0.05))
	pd.draw_circle(c, 11.0, Color("#1b1430") if not fox else Color("#0f1a3a"))
	pd.draw_arc(c, 12.0, 0, TAU, 28, Color(ring, 0.9), 1.5)
	if fox:
		pd.draw_colored_polygon(PackedVector2Array([c + Vector2(-7, -2), c + Vector2(-6, -9), c + Vector2(-2, -4), c + Vector2(2, -4), c + Vector2(6, -9), c + Vector2(7, -2), c + Vector2(0, 7)]), Color("#f6f8ff"))
		pd.draw_rect(Rect2(c + Vector2(-4, -2), Vector2(2, 1)), PData.FOX_MID)
		pd.draw_rect(Rect2(c + Vector2(2, -2), Vector2(2, 1)), PData.FOX_MID)
		pd.draw_circle(c + Vector2(0, 6), 1.2, Color("#1b1430"))
	else:
		pd.draw_circle(c + Vector2(0, 5), 4.0, Color("#d8352c")) # 붉은 머리
		pd.draw_colored_polygon(PackedVector2Array([c + Vector2(-9, 3), c + Vector2(9, 3), c + Vector2(6, 1), c + Vector2(2, 0), c + Vector2(-1, -9), c + Vector2(-7, -7), c + Vector2(-3, -5), c + Vector2(-3, 0), c + Vector2(-6, 1)]), Color("#34457e"))
		pd.draw_rect(Rect2(c + Vector2(-4, -1), Vector2(7, 2)), GOLD)
		pd.draw_circle(c + Vector2(2, 0), 1.4, Color("#e3303f"))


func _heart(p: Vector2, half: int, col: Color, sc: float) -> void:
	var c := p + Vector2(6, 5.5)
	var pts := PackedVector2Array([Vector2(0, 5.5), Vector2(-6, -0.5), Vector2(-6, -3.5), Vector2(-4, -5.5), Vector2(-2, -5.5), Vector2(0, -3.5)])
	if half == 2:
		pts.append_array(PackedVector2Array([Vector2(2, -5.5), Vector2(4, -5.5), Vector2(6, -3.5), Vector2(6, -0.5)]))
	for i in pts.size():
		pts[i] = c + pts[i] * sc
	pd.draw_colored_polygon(pts, col)
	if col == HEART:
		pd.draw_rect(Rect2(c + Vector2(-4, -4) * sc, Vector2(2, 2)), Color(1, 1, 1, 0.75))
		pd.draw_rect(Rect2(c + Vector2(-1, 2) * sc, Vector2(2, 1)), Color(HEART_D, 0.8))


# ─── 아래 가운데: 마법 6칸 ────────────────────────────

func _draw_slots() -> void:
	# 칸 순서: 등급 키면 키 묶음(A·S·D)대로, 전용 키면 마법 표 순서. 둘 다 초급·중급·대마법으로 묶음
	var grade := PState.key_mode == 0
	var order: Array = ["fireball", "foxrain", "laser", "meteor", "bind", "phoenix"] if grade else PData.SPELLS.map(func(x: Dictionary) -> String: return String(x.id))
	var groups: Array = [0, 0, 1, 1, 2, 2]
	var n := order.size()
	var w := 26.0
	var gap := 3.0
	var ggap := 10.0
	var total := n * w + (n - 1) * gap + ggap * 2.0
	var x0 := (640.0 - total) / 2.0
	var y0 := 360.0 - w - 12.0
	var sealed := sera.overloaded()
	# 묶음 받침 + 이름
	var names := ["초급 A", "중급 S", "대마법 D"] if grade else ["초급", "중급", "대마법"]
	for gi in 3:
		var gx0 := x0 + groups.find(gi) * (w + gap) + ggap * gi
		var gx1 := x0 + groups.rfind(gi) * (w + gap) + ggap * gi + w
		pd.draw_rect(Rect2(gx0 - 3, y0 - 3, gx1 - gx0 + 6, w + 11), Color(0.03, 0.02, 0.07, 0.62))
		pd.draw_rect(Rect2(gx0 - 3, y0 - 3, gx1 - gx0 + 6, 1), Color(GOLD, 0.4))
		_text(Vector2(gx0 - 2, y0 - 5), names[gi], Color(1, 0.86, 0.6, 0.65), 8)
	for i in n:
		var s: Dictionary = PData.spell(order[i])
		var id := String(s.id)
		var x := x0 + i * (w + gap) + ggap * float(groups[i])
		var r := Rect2(x, y0, w, w)
		var fox_line := sera.is_fox() # 변신 중엔 모든 마법이 푸른 여우불 판
		# 테두리(빛·그늘) + 안쪽 바탕
		pd.draw_rect(r.grow(1), Color(0.01, 0.0, 0.03))
		pd.rect_grad(r, Color("#3a2850") if not fox_line else Color("#22305a"), Color("#1a1028") if not fox_line else Color("#0e1630"))
		pd.draw_rect(Rect2(r.position, Vector2(w, 1)), Color(1, 1, 1, 0.14))
		var cd := float(sera.cooldowns.get(id, 0.0))
		_icon(id, r.get_center(), 0.45 if (sealed or cd > 0.0) else 1.0)
		if cd > 0.0:
			# 원형 쿨: 남은 만큼 시계 방향으로 어둡게 (칸 모서리까지)
			var k := clampf(cd / PState.spell_cd(id), 0.0, 1.0)
			var pie := PackedVector2Array([r.get_center()])
			var steps := maxi(int(24 * k), 2)
			for j in steps + 1:
				var a := -PI / 2 + TAU * (1.0 - k) + TAU * k * float(j) / float(steps)
				var d := Vector2(cos(a), sin(a))
				pie.append(r.get_center() + d / maxf(absf(d.x), absf(d.y)) * (w * 0.5))
			pd.draw_colored_polygon(pie, Color(0, 0, 0, 0.62))
			_text(r.position + Vector2(0, 18), "%d" % ceili(cd) if cd >= 1.0 else "%.1f" % cd, Color(1, 1, 1, 0.95), 10, HORIZONTAL_ALIGNMENT_CENTER, w)
		if sealed:
			pd.draw_rect(r, Color(0.25, 0.02, 0.02, 0.35))
		if PSpells.last_fail == id and PSpells.last_fail_t > 0.0:
			pd.draw_rect(r.grow(1), Color(1, 0.25, 0.2, minf(PSpells.last_fail_t * 2.0, 1.0)), false, 2.0)
		var border := Color("#ffb347", 0.85) if not fox_line else Color(PData.FOX_HOT, 0.85)
		if PState.awakened(id):
			border = Color(1, 0.95, 0.55, 0.65 + 0.35 * sin(_t * 5.0 + i))
		pd.draw_rect(r, border, false, 1.0)
		var rf := float(_ready_flash.get(id, 0.0))
		if rf > 0.0:
			var k2 := rf / 0.35
			pd.draw_rect(r, Color(1, 1, 1, 0.45 * k2))
			pd.draw_rect(r.grow(1.0 + 4.0 * (1.0 - k2)), Color(1, 0.95, 0.8, k2), false, 1.0)
		# 키 글자 (작은 키캡)
		var label := PState.spell_label(id)
		pd.draw_rect(Rect2(r.position + Vector2(-1, -1), Vector2(5.0 + 6.0 * label.length(), 9)), Color(0.02, 0.01, 0.05, 0.85))
		_text(r.position + Vector2(1, 7), label, Color(1, 0.95, 0.85, 0.95), 8)
		# 레벨 점 (각성 = 금)
		var mx := int(s.max_lv)
		var lv := PState.level(id)
		var aw := PState.awakened(id)
		for j in mx:
			var dp := Vector2(r.get_center().x - (mx - 1) * 2.5 + j * 5.0 - 1.0, r.end.y + 3)
			pd.draw_rect(Rect2(dp, Vector2(3, 3)), (Color(1, 0.88, 0.35) if aw else Color(1, 1, 1, 0.8)) if j < lv else Color(1, 1, 1, 0.18))
	if sealed:
		# 봉인: 칸 위를 가로지르는 붉은 사슬 (봉인되는 순간 흔들림)
		var y := y0 + w * 0.5
		var shake := sin(_seal_t * 40.0) * maxf(0.0, 1.0 - _seal_t * 3.0) * 2.0
		var x := x0 - 6.0
		while x < x0 + total + 6.0:
			pd.draw_rect(Rect2(x, y - 2 + shake, 6, 4), Color(0.7, 0.15, 0.1, 0.95), false, 1.0)
			pd.draw_rect(Rect2(x + 5, y - 0.5 + shake, 4, 1), Color(0.85, 0.25, 0.18, 0.95))
			x += 9.0


## 퀵슬롯 아이콘 (간단한 상징 그림). a = 밝기(쿨·봉인이면 어둡게)
## 변신 중엔 같은 그림이 푸른 여우불 색 (평소 = 불 마법사의 붉은 불)
func _icon(id: String, c: Vector2, a: float) -> void:
	var pal := PSpells._pal(sera.is_fox())
	var fire := Color(pal[2], a)
	var hot := Color(pal[1], a)
	var core := Color(pal[0], a)
	match id:
		"fireball":
			# 세로 마법진 앞의 큰 태양
			pd.draw_set_transform(c + Vector2(-6, 0), 0.0, Vector2(0.35, 1.0))
			pd.draw_arc(Vector2.ZERO, 10.0, 0, TAU, 20, Color(pal[1], 0.8 * a), 1.5)
			pd.draw_set_transform(Vector2.ZERO)
			pd.glow(c + Vector2(2, 0), 11.0, Color(pal[2], 0.4 * a))
			for i in 8:
				var ang := float(i) / 8.0 * TAU
				PVfx.spike(pd, c + Vector2(2, 0) + Vector2(cos(ang), sin(ang)) * 5.5, Vector2(cos(ang), sin(ang)), 3.5, 3.0, fire)
			pd.draw_circle(c + Vector2(2, 0), 6.5, fire)
			pd.draw_circle(c + Vector2(2, 0), 4.6, hot)
			pd.draw_circle(c + Vector2(2.5, -0.5), 2.2, core)
		"foxrain":
			for i in 4:
				var tip := c + Vector2(-4.0 + i * 4.6, 4 + i % 2 * 3)
				pd.draw_colored_polygon(PackedVector2Array([tip + Vector2(-4, -11), tip + Vector2(-2, -12), tip]), core)
				pd.draw_line(tip + Vector2(-3, -11), tip, hot, 1.0)
			pd.draw_line(c + Vector2(-10, 9), c + Vector2(10, 9), fire, 1.0)
		"laser":
			pd.draw_rect(Rect2(c + Vector2(-10, -3), Vector2(20, 6)), Color(PData.FIRE_MID, 0.5 * a))
			pd.draw_rect(Rect2(c + Vector2(-10, -2), Vector2(20, 4)), hot)
			pd.draw_rect(Rect2(c + Vector2(-10, -1), Vector2(20, 2)), core)
			for i in 4:
				pd.draw_arc(c + Vector2(-6 + i * 4, 0), 4.5, -1.0, 1.0, 6, fire, 1.0)
		"meteor":
			pd.glow(c + Vector2(3, 3), 10.0, Color(PData.FIRE_MID, 0.35 * a))
			pd.draw_colored_polygon(PackedVector2Array([c + Vector2(-9, -9), c + Vector2(0, 0), c + Vector2(5, -1), c + Vector2(1, 5), c + Vector2(-2, 2)]), Color(PData.FIRE_MID, 0.6 * a))
			pd.draw_circle(c + Vector2(3, 3), 5.0, Color(0.25, 0.12, 0.1, a))
			pd.draw_arc(c + Vector2(3, 3), 5.0, -2.5, 0.5, 8, hot, 1.5)
		"phoenix":
			pd.glow(c, 11.0, Color(PData.FIRE_MID, 0.35 * a))
			pd.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -2), c + Vector2(-10, -9), c + Vector2(-6, 0), c + Vector2(-10, 6), c + Vector2(0, 2), c + Vector2(10, 6), c + Vector2(6, 0), c + Vector2(10, -9)]), fire)
			pd.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -1), c + Vector2(-6, -5), c + Vector2(-3, 0), c + Vector2(0, 1), c + Vector2(3, 0), c + Vector2(6, -5)]), hot)
			pd.draw_circle(c, 2.4, core)
		"bind":
			pd.glow(c, 11.0, Color(pal[2], 0.35 * a))
			pd.draw_colored_polygon(PackedVector2Array([c + Vector2(-8, -2), c + Vector2(-9, -10), c + Vector2(-4, -5), c + Vector2(4, -5), c + Vector2(9, -10), c + Vector2(8, -2), c + Vector2(0, 8)]), fire)
			pd.draw_colored_polygon(PackedVector2Array([c + Vector2(-4, 1), c + Vector2(4, 1), c + Vector2(0, 7)]), core)
			pd.draw_rect(Rect2(c + Vector2(-5, -2), Vector2(3, 1)), core)
			pd.draw_rect(Rect2(c + Vector2(2, -2), Vector2(3, 1)), core)


# ─── 오른쪽 위: 조작 안내 ─────────────────────────────

const KEY_GUIDE_GRADE := [
	["← →", "이동"], ["Z", "점프 · 공중 2단 · 다시 꾹 = 활공"], ["벽 + Z", "벽 점프 (붙으면 미끄러짐)"],
	["X", "불덩이 던지기 3연타 (↑위 · 공중↓아래)"], ["C", "대시 (변신 중 = 의태 돌진)"], ["폭주", "마법을 쓰거나 불덩이를 맞히면 참"],
	["Space", "변신 (폭주 가득 = 마법 봉인 해제)"], ["G", "물약"],
	["A", "초급: 파이어볼 · ↓불비"], ["S", "중급: 열선(꾹) · ↑대유성"], ["D", "대마법: 바인드 · ↑불사조"], ["↑", "석등에서 쉬기"],
]
const KEY_GUIDE_DIRECT := [
	["← →", "이동"], ["Z", "점프 · 공중 2단 · 다시 꾹 = 활공"], ["벽 + Z", "벽 점프 (붙으면 미끄러짐)"],
	["X", "불덩이 던지기 3연타 (↑위 · 공중↓아래)"], ["Shift", "대시 (변신 중 = 의태 돌진)"], ["폭주", "마법을 쓰거나 불덩이를 맞히면 참"],
	["Space", "변신 (폭주 가득 = 마법 봉인 해제)"], ["G", "물약"],
	["A S", "파이어볼·불비"], ["Q W", "압축 열선(꾹)·대유성"], ["E R", "불사조·너울 바인드"], ["↑", "석등에서 쉬기"],
]


func _draw_keys() -> void:
	var x := 420.0
	var y := 8.0
	var guide: Array = KEY_GUIDE_GRADE if PState.key_mode == 0 else KEY_GUIDE_DIRECT
	_panel(Rect2(x - 6, y - 4, 218, guide.size() * 12 + 8))
	for i in guide.size():
		var row: Array = guide[i]
		_text(Vector2(x, y + 9 + i * 12), String(row[0]), Color("#ffd27a"), 10)
		_text(Vector2(x + 48, y + 9 + i * 12), String(row[1]), Color(1, 1, 1, 0.85), 10)
