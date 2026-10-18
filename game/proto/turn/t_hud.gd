class_name THud
extends Control
## 턴제 전투 화면 표시 + 입력 (터치 우선, 키보드도 같은 흐름).
## 위: 차례 줄(다음 8명) · 가운데 위: 지금 행동 이름 · 머리 위: 체력 바 + 행동 게이지 + 크레딧 점 7개(마녀) / 의도·징표(적) + 버프 아이콘
## 차례가 온 마녀 오른쪽에 부채꼴 스킬 바퀴(기본 공격 + 장착 마법 4, 칸은 아이콘 TIcon): 한 번 누르면 고르고(아래 설명 상자에 이름·설명), 대상이 필요하면 적/아군을 누른다.
## 대상이 없는 마법은 같은 칸을 다시 누르면 쓴다. 키보드: ←→↑↓ 고르기 · Z 확인 · X 뒤로.
## 피해 숫자(쉼표, 크리는 금빛 크게, 약점은 주홍, 회복은 연둣빛, 버프는 라벤더 글)는 여기서 띄운다.

signal chosen(action: Dictionary)
signal banner_tapped
signal exit_tapped

const PALE := Color("#e6dcff")
const LAV := Color("#b9a2ff")
const INK := Color("#14081f")
const GOLD := Color("#ffe08a")
const FIRE := Color("#ff8a3a")
const RED := Color("#ff4f6a")
const GREEN := Color("#b8f0a0")
const DIM := Color("#8a7fa3")
const HP_COL := Color("#7ddc8a")
const HP_LOW := Color("#ff6a5a")
const GAUGE_COL := Color("#c9b8ff")
const WHEEL_R := 64.0
const SLOT_R := 19.0
const QUEUE_N := 8
const SHORT := {"eska": "에", "ignis": "이", "ember": "엠", "straw_golem": "골", "swamp_toad": "두", "ash_knight": "기"}
const CAT_GLYPH := {"atk": "공", "crit_dmg": "크", "crit_rate": "확", "special": "특", "final": "종", "dmg_taken": "막", "element": "화", "def_down": "방", "atk_down": "약", "invincible": "무"}
const CAT_COL := {"atk": Color("#ff7a5a"), "crit_dmg": Color("#ffe08a"), "crit_rate": Color("#ffd27a"), "special": Color("#ff9a3a"), "final": Color("#c9a0ff"),
	"dmg_taken": Color("#8ad0ff"), "element": Color("#ff6a3d"), "def_down": Color("#b0a8b8"), "atk_down": Color("#9a8aa6"), "invincible": Color("#ffffff")}

var stage: Node
var battle: TBattle
var actors := {} ## TUnit → TActor
var state := "idle" ## idle · wheel · target · banner
var actor: TActor
var slots: Array = [] ## [{id, name, cost, can, pos}]
var sel := -1 ## 고른 칸 (−1 = 없음)
var targets: Array = [] ## 고를 수 있는 대상 TActor
var tsel := 0
var banner_text := ""
var banner_sub := ""
var msg := ""
var msg_t := 0.0
var numbers: Array = [] ## [pos, text, kind, age]
var _t := 0.0
var _font: Font
var _queue: Array = []
var _banner_t := 0.0
var _touch_seen := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = get_theme_default_font()
	if _font == null:
		_font = ThemeDB.fallback_font


func bind(b: TBattle, a: Dictionary) -> void:
	battle = b
	actors = a
	numbers.clear()
	state = "idle"
	actor = null
	refresh()


func refresh() -> void:
	if battle != null:
		_queue = battle.preview(QUEUE_N)
	queue_redraw()


func to_screen(world: Vector2) -> Vector2:
	var vp := get_viewport()
	if vp == null:
		return world
	return vp.get_canvas_transform() * world


func _process(delta: float) -> void:
	_t += delta
	size = get_viewport_rect().size # 캔버스 층 아래 Control은 앵커로 화면 크기를 못 받는다
	msg_t = maxf(msg_t - delta, 0.0)
	_banner_t += delta
	for n: Array in numbers:
		n[3] = float(n[3]) + delta
	numbers = numbers.filter(func(n: Array) -> bool: return float(n[3]) < 1.1)
	queue_redraw()


# ═══════════════════════════════════════════════════════════
# 바깥에서 부르는 것
# ═══════════════════════════════════════════════════════════

## 마녀의 차례: 바퀴를 열고 chosen 신호를 기다린다
func open_wheel(a: TActor) -> void:
	actor = a
	state = "wheel"
	sel = -1
	targets.clear()
	_build_slots()
	_dim_others(true)
	Sfx.play(&"tn_turn", -8.0)
	queue_redraw()


func close_wheel() -> void:
	_dim_others(false)
	state = "idle"
	actor = null
	slots.clear()
	targets.clear()
	queue_redraw()


func show_msg(s: String) -> void:
	msg = s
	msg_t = 1.6


func banner(text: String, sub: String) -> void:
	banner_text = text
	banner_sub = sub
	state = "banner"
	_banner_t = 0.0
	queue_redraw()


func clear_banner() -> void:
	banner_text = ""
	state = "idle"


## 숫자·글 띄우기. kind: dmg · crit · weak · heal · buff · debuff · miss · credit · zero · mark · revive
func number(world: Vector2, text: String, kind := "dmg") -> void:
	var p := to_screen(world)
	# 같은 자리 위에 떠 있는 글이 있으면 위로 밀어 겹치지 않게
	for n: Array in numbers:
		var q: Vector2 = n[0]
		if absf(q.x - p.x) < 40.0 and absf(q.y - p.y) < 14.0 and float(n[3]) < 0.5:
			n[0] = q + Vector2(0, -13)
	numbers.append([p, text, kind, 0.0])
	if numbers.size() > 40:
		numbers.pop_front()


# ═══════════════════════════════════════════════════════════
# 입력
# ═══════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_seen = true
			_tap(event.position)
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION:
			_tap(event.position)
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_touch_seen = false
	if state == "banner":
		if event.is_action_pressed("es_jump") or event.is_action_pressed("es_attack"):
			_banner_go()
		return
	if state == "wheel":
		if event.is_action_pressed("es_right") or event.is_action_pressed("es_down"):
			_move_sel(1)
		elif event.is_action_pressed("es_left") or event.is_action_pressed("es_up"):
			_move_sel(-1)
		elif event.is_action_pressed("es_jump"):
			if sel < 0:
				_move_sel(1)
			else:
				_confirm_slot()
		elif event.is_action_pressed("es_attack"):
			sel = -1
			Sfx.play(&"tn_cancel", -10.0)
			queue_redraw()
	elif state == "target":
		if event.is_action_pressed("es_right") or event.is_action_pressed("es_down"):
			tsel = (tsel + 1) % targets.size()
			Sfx.play(&"tn_select", -12.0)
		elif event.is_action_pressed("es_left") or event.is_action_pressed("es_up"):
			tsel = (tsel - 1 + targets.size()) % targets.size()
			Sfx.play(&"tn_select", -12.0)
		elif event.is_action_pressed("es_jump"):
			_choose_target(targets[tsel])
		elif event.is_action_pressed("es_attack"):
			state = "wheel"
			targets.clear()
			Sfx.play(&"tn_cancel", -10.0)
		queue_redraw()


func _move_sel(d: int) -> void:
	if slots.is_empty():
		return
	if sel < 0:
		sel = 0 if d > 0 else slots.size() - 1
	else:
		sel = (sel + d + slots.size()) % slots.size()
	Sfx.play(&"tn_select", -12.0)
	queue_redraw()


func _tap(p: Vector2) -> void:
	# 오른쭉 위 X: 나가기
	if p.distance_to(Vector2(size.x - 16, 16)) < 16.0:
		exit_tapped.emit()
		return
	match state:
		"banner":
			if _banner_t > 0.5:
				_banner_go()
		"wheel":
			var i := _slot_at(p)
			if i >= 0:
				if i == sel:
					_confirm_slot()
				else:
					sel = i
					Sfx.play(&"tn_select", -10.0)
					queue_redraw()
				return
			var a := _actor_at(p)
			if a != null and sel >= 0:
				# 바퀴 칸을 고른 채 대상을 바로 누름 → 그 대상으로 바로 쓴다 (대상이 맞으면)
				var s: Dictionary = slots[sel]
				if bool(s.can):
					_begin_target(s)
					if targets.has(a):
						_choose_target(a)
						return
				state = "wheel"
				targets.clear()
		"target":
			var a := _actor_at(p)
			if a != null and targets.has(a):
				_choose_target(a)
				return
			var i := _slot_at(p)
			if i >= 0:
				state = "wheel"
				targets.clear()
				sel = i
				Sfx.play(&"tn_select", -10.0)
				queue_redraw()
				return
			# 빈 곳: 뒤로
			state = "wheel"
			targets.clear()
			Sfx.play(&"tn_cancel", -10.0)
			queue_redraw()


func _banner_go() -> void:
	Sfx.play(&"tn_confirm", -6.0)
	banner_tapped.emit()


func _slot_at(p: Vector2) -> int:
	var best := -1
	var bd := INF
	for i in slots.size():
		var d := p.distance_to(slots[i].pos)
		if d <= SLOT_R + 5.0 and d < bd:
			bd = d
			best = i
	return best


## 화면 자리의 유닛 (몸 사각형)
func _actor_at(p: Vector2) -> TActor:
	var best: TActor = null
	var bd := INF
	for u in actors:
		var a: TActor = actors[u]
		if not a.unit.alive and not (state == "target" and targets.has(a)):
			continue
		var feet := to_screen(a.feet())
		var head := to_screen(a.head())
		var hw := maxf(a.half_w(), 14.0) + 8.0
		var r := Rect2(Vector2(feet.x - hw, head.y - 6.0), Vector2(hw * 2.0, feet.y - head.y + 12.0))
		if r.has_point(p):
			var d := p.distance_to((feet + head) * 0.5)
			if d < bd:
				bd = d
				best = a
	return best


func _build_slots() -> void:
	slots.clear()
	var u := actor.unit
	var c := _wheel_center()
	var ids: Array = ["basic"]
	for sid in u.equipped:
		ids.append(sid)
	if String(u.data.get("ultimate", "")) != "":
		ids.append(String(u.data.ultimate)) # 대마법: 바퀴 끝 칸 (크레딧 7일 때만, §13) — 꾸밈은 단계 C
	var n := ids.size()
	var arc := _wheel_arc()
	for i in n:
		var f := float(i) / float(maxi(n - 1, 1))
		var ang := lerpf(float(arc[0]), float(arc[1]), f)
		var pos := c + Vector2(cos(ang), sin(ang)) * WHEEL_R
		var sid: String = ids[i]
		if sid == "basic":
			slots.append({"id": "basic", "name": "공격", "cost": 0, "can": true, "pos": pos, "kind": "attack", "target": "enemy", "icon": "strike"})
		else:
			var s := TData.skill(sid)
			slots.append({"id": sid, "name": String(s.name), "cost": int(s.cost), "can": battle.can_use(u, sid), "pos": pos, "kind": String(s.kind), "target": String(s.target), "icon": String(s.get("icon", "strike"))})


func _wheel_center() -> Vector2:
	return to_screen(actor.center()) + Vector2(4, -6)


## 부채꼴의 시작·끝 각 (라디안, 시계 방향이 +): 앞자리는 오른쪽으로, 중간은 오른쪽 위로, 뒷자리는 위로 펼쳐 다른 마녀와 덜 겹치게
func _wheel_arc() -> Array:
	match actor.unit.slot:
		0: return [-1.75, 1.75]
		1: return [-2.6, 0.55]
		_: return [-3.0, 0.1]


## 바퀴가 열린 동안 다른 마녀는 흐리게 (고르는 마녀가 또렷이)
func _dim_others(on: bool) -> void:
	for u in actors:
		var a: TActor = actors[u]
		if u.is_witch() and a != actor:
			a.modulate = Color(0.55, 0.5, 0.65) if on else Color.WHITE


func _confirm_slot() -> void:
	if sel < 0 or sel >= slots.size():
		return
	var s: Dictionary = slots[sel]
	if not bool(s.can):
		Sfx.play(&"tn_cancel", -8.0)
		show_msg("크레딧이 모자랍니다 (%d 필요)" % int(s.cost))
		return
	_begin_target(s)
	if state == "target":
		Sfx.play(&"tn_select", -8.0)
		queue_redraw()
	else:
		_emit(s, null)


## 대상이 필요한 마법이면 대상 고르기 상태로, 아니면 그대로
func _begin_target(s: Dictionary) -> void:
	targets.clear()
	var u := actor.unit
	if String(s.id) == "basic" or battle.needs_target_pick(String(s.id)):
		var us: Array[TUnit] = battle.alive_of(battle.enemies) if String(s.id) == "basic" else battle.valid_targets(u, String(s.id))
		for t in us:
			if actors.has(t):
				targets.append(actors[t])
		state = "target"
		tsel = 0
		# 기본값: 적이면 첫 적, 아군이면 자신이 아닌 첫 아군 (자기 버프는 보통 딜러에게)
		if String(s.target) in ["ally", "ally_any"]:
			for i in targets.size():
				if targets[i] != actor:
					tsel = i
					break
	else:
		state = "idle"


func _choose_target(a: TActor) -> void:
	var s: Dictionary = slots[sel]
	_emit(s, a.unit)


func _emit(s: Dictionary, tgt: TUnit) -> void:
	Sfx.play(&"tn_confirm", -6.0)
	var action := {"kind": "basic" if String(s.id) == "basic" else "skill", "skill": String(s.id), "target": tgt}
	close_wheel()
	chosen.emit(action)


# ═══════════════════════════════════════════════════════════
# 그림
# ═══════════════════════════════════════════════════════════

## 글자 + 먹 테두리. 오른쪽·가운데 맞춤은 폭이 없으면 글자 폭으로 자리를 옮겨 맞춘다 (Godot은 폭 0이면 맞춤을 무시한다)
func _text(p: Vector2, s: String, fs: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, w := -1) -> void:
	if w <= 0 and align != HORIZONTAL_ALIGNMENT_LEFT:
		var tw := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		p.x -= tw if align == HORIZONTAL_ALIGNMENT_RIGHT else tw * 0.5
		align = HORIZONTAL_ALIGNMENT_LEFT
		w = -1
	draw_string_outline(_font, p, s, align, w, fs, 3, Color(INK, 0.9 * col.a))
	draw_string(_font, p, s, align, w, fs, col)


func _draw() -> void:
	if battle == null:
		return
	_draw_heads()
	_draw_queue()
	if msg_t > 0.0 and msg != "":
		var a := minf(msg_t / 0.4, 1.0)
		_text(Vector2(size.x * 0.5, 46), msg, 12, Color(PALE, a), HORIZONTAL_ALIGNMENT_CENTER, 0)
	if state == "wheel" or state == "target":
		_draw_wheel()
	if state == "target":
		_draw_targets()
	_draw_numbers()
	if state == "banner":
		_draw_banner()
	# 나가기 X
	draw_circle(Vector2(size.x - 16, 16), 11.0, Color(INK, 0.5))
	draw_arc(Vector2(size.x - 16, 16), 11.0, 0.0, TAU, 24, Color(LAV, 0.6), 1.0)
	_text(Vector2(size.x - 16, 20), "X", 11, Color(PALE, 0.8), HORIZONTAL_ALIGNMENT_CENTER, 0)
	# 아래 안내
	var hint := ""
	match state:
		"wheel":
			hint = "마법을 고르세요 · 크레딧 %d" % actor.unit.credits if actor != null else ""
			if sel >= 0:
				var s: Dictionary = slots[sel]
				hint = ("대상을 누르세요" if (String(s.id) == "basic" or battle.needs_target_pick(String(s.id))) else "다시 눌러 사용") if _touch_seen else ("Z 확인 · X 뒤로")
		"target":
			hint = "대상을 누르세요 · 빈 곳을 누르면 뒤로" if _touch_seen else "←→ 대상 · Z 확인 · X 뒤로"
	if hint != "":
		_text(Vector2(size.x * 0.5, size.y - 6), hint, 11, Color(PALE, 0.75), HORIZONTAL_ALIGNMENT_CENTER, 0)


## 머리 위: 체력 바 · 게이지 · 크레딧 · 버프 · 의도 · 징표
func _draw_heads() -> void:
	for u in actors:
		var a: TActor = actors[u]
		var unit: TUnit = u
		var top := to_screen(a.head())
		if not unit.alive:
			if unit.is_witch():
				_text(top + Vector2(0, 28), "쓰러짐", 10, Color(DIM, 0.8), HORIZONTAL_ALIGNMENT_CENTER, 0)
			continue
		if (state == "wheel" or state == "target") and unit.is_witch() and a != actor:
			continue
		var w := 60.0 if unit.boss else (44.0 if unit.is_witch() else 50.0)
		var x := top.x - w * 0.5
		var y := top.y - 6.0
		var cur := battle.actor == unit
		if unit.stunned:
			_text(Vector2(top.x, y - (40.0 if not unit.is_witch() else 18.0)), "기절", 8, Color("#ffe34a", 0.95), HORIZONTAL_ALIGNMENT_CENTER, 0)
		# 이름 (지금 차례면 밝게)
		_text(Vector2(top.x, y - 7), unit.name, 10, Color(PALE if cur else DIM, 1.0 if cur else 0.85), HORIZONTAL_ALIGNMENT_CENTER, 0)
		# 체력 바
		draw_rect(Rect2(x - 1, y - 1, w + 2, 6), Color(INK, 0.85))
		var hp_r := a.shown_hp
		var real_r := unit.hp_ratio()
		var col := HP_COL.lerp(HP_LOW, clampf(1.0 - real_r * 2.0, 0.0, 1.0)) if unit.is_witch() else Color("#d85a4a")
		if not unit.is_witch():
			col = Color("#c84a3a")
		draw_rect(Rect2(x, y, w * hp_r, 4), Color(col, 0.5)) # 천천히 따라오는 부분
		draw_rect(Rect2(x, y, w * real_r, 4), col)
		# 게이지
		draw_rect(Rect2(x, y + 5, w, 2), Color(INK, 0.8))
		var g := clampf(unit.gauge / TData.GAUGE_MAX, 0.0, 1.0)
		draw_rect(Rect2(x, y + 5, w * g, 2), Color(GAUGE_COL, 0.95 if cur else 0.7))
		if cur:
			draw_rect(Rect2(x - 1, y - 2, w + 2, 10), Color(PALE, 0.9), false, 1.0)
		var by := y + 9.0
		if unit.is_witch():
			# 크레딧 점 7개
			for i in TData.CREDIT_MAX:
				var cx := x + 3.0 + float(i) * 6.2
				var on := i < unit.credits
				draw_circle(Vector2(cx, by + 2), 2.2, Color(INK, 0.8))
				draw_circle(Vector2(cx, by + 2), 1.6, GOLD if on else Color(DIM, 0.5))
			by += 6.0
		else:
			# 의도 (종류만)
			var it := unit.intent()
			var kname: String = TData.INTENT_NAME.get(it.get("k", "attack"), "")
			var icol := Color("#ff9a7a")
			match String(it.get("k", "")):
				"heavy": icol = RED
				"aoe": icol = Color("#ffcf7a")
				"buff": icol = Color("#c9a0ff")
				"stun_attack": icol = Color("#8fd8ff")
				"dispel": icol = Color("#a070ff")
				"finisher": icol = Color("#ff2a4a")
			var pulse := 0.7 + 0.3 * sin(_t * 4.0)
			var pw := _font.get_string_size(kname, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 16.0
			var pr := Rect2(top.x - pw * 0.5, y - 29, pw, 12)
			draw_rect(pr, Color(INK, 0.75))
			draw_rect(pr, Color(icol, 0.6 * pulse), false, 1.0)
			_intent_icon(pr.position + Vector2(7, 6), String(it.get("k", "attack")), Color(icol, pulse))
			_text(pr.position + Vector2(14, 10), kname, 9, Color(icol, 0.95))
			# 징표
			var mx := x
			for mk in unit.marks:
				_mark_icon(Vector2(mx + 4, by + 3), String(mk))
				_text(Vector2(mx + 10, by + 6), "%s %d겹·%d" % [TData.MARK_NAME.get(mk, mk), unit.mark_n(String(mk)), unit.mark_dur(String(mk))], 8, Color(FIRE, 0.95))
				mx += 50.0
			if not unit.marks.is_empty():
				by += 7.0
		# 버프 아이콘 (최대 6)
		var icons := unit.buff_icons()
		var ix := x
		var shown := 0
		for ic in icons:
			if shown >= 6:
				break
			var cat := String(ic.cat)
			var c2: Color = CAT_COL.get(cat, LAV)
			var bad := cat in ["def_down", "atk_down"]
			draw_rect(Rect2(ix, by, 8, 8), Color(INK, 0.85))
			draw_rect(Rect2(ix, by, 8, 8), Color(c2, 0.9), false, 1.0)
			if bad:
				draw_line(Vector2(ix + 1, by + 7), Vector2(ix + 7, by + 1), Color(c2, 0.9), 1.0)
			draw_string(_font, Vector2(ix + 1, by + 7), String(CAT_GLYPH.get(cat, "?")), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, c2)
			draw_string(_font, Vector2(ix + 8.5, by + 8.5), str(int(ic.dur)), HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(PALE, 0.9))
			ix += 14.0
			shown += 1


func _intent_icon(c: Vector2, kind: String, col: Color) -> void:
	match kind:
		"attack":
			draw_line(c + Vector2(-3, 3), c + Vector2(3, -3), col, 1.6)
			draw_line(c + Vector2(1, -3), c + Vector2(3, -3), col, 1.6)
			draw_line(c + Vector2(3, -1), c + Vector2(3, -3), col, 1.6)
		"heavy":
			draw_line(c + Vector2(-3, 3), c + Vector2(3, -3), col, 2.4)
			draw_line(c + Vector2(-3, -1), c + Vector2(1, 3), col, 1.2)
		"aoe":
			draw_arc(c, 3.5, 0.0, TAU, 12, col, 1.2)
			draw_circle(c, 1.2, col)
		"buff":
			draw_line(c + Vector2(0, 3), c + Vector2(0, -3), col, 1.6)
			draw_line(c + Vector2(-3, 0), c + Vector2(0, -3), col, 1.6)
			draw_line(c + Vector2(3, 0), c + Vector2(0, -3), col, 1.6)
		"stun_attack":
			draw_line(c + Vector2(-3, 3), c + Vector2(3, -3), col, 1.6)
			draw_circle(c + Vector2(-2, -2), 1.2, col)
		"dispel":
			draw_line(c + Vector2(-3, -3), c + Vector2(3, 3), col, 1.4)
			draw_line(c + Vector2(-3, 3), c + Vector2(3, -3), col, 1.4)
		"finisher":
			draw_arc(c, 3.5, 0.0, TAU, 12, col, 1.6)
			draw_line(c + Vector2(-3, 3), c + Vector2(3, -3), col, 1.6)


func _mark_icon(c: Vector2, kind: String) -> void:
	match kind:
		"burn":
			var f := 0.8 + 0.2 * sin(_t * 12.0)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-3, 3), c + Vector2(-2, -1), c + Vector2(0, -4 * f), c + Vector2(2, -1), c + Vector2(3, 3)]), Color("#e2452a"))
			draw_colored_polygon(PackedVector2Array([c + Vector2(-1.5, 3), c + Vector2(0, -1.5 * f), c + Vector2(1.5, 3)]), Color("#ffd27a"))
		"frost":
			draw_arc(c, 3.0, 0.0, TAU, 8, Color("#8ad0ff"), 1.0)
		"shock":
			draw_line(c + Vector2(-2, -3), c + Vector2(1, 0), Color("#ffe08a"), 1.2)
			draw_line(c + Vector2(1, 0), c + Vector2(-1, 3), Color("#ffe08a"), 1.2)


## 차례 줄 (화면 위): 지금 → 다음 7
func _draw_queue() -> void:
	var x := 22.0
	var y := 18.0
	_text(Vector2(8, 11), "차례", 8, Color(DIM, 0.9))
	for i in _queue.size():
		var u: TUnit = _queue[i]
		var r := 11.0 if i == 0 else 8.0
		var c := Vector2(x, y + (0.0 if i == 0 else 2.0))
		var col: Color = u.data.get("color", Color.GRAY)
		draw_circle(c, r + 1.5, Color(INK, 0.9))
		draw_circle(c, r, Color(col, 0.95 if i == 0 else 0.7))
		if i == 0:
			draw_arc(c, r + 2.5, 0.0, TAU, 24, Color(PALE, 0.9), 1.2)
		if not u.is_witch():
			draw_arc(c, r - 1.0, 0.0, TAU, 16, Color(INK, 0.5), 1.0)
		var glyph: String = SHORT.get(u.id, u.name.substr(0, 1))
		draw_string(_font, c + Vector2(-4.5, 4), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 9 if i == 0 else 8, INK if u.is_witch() else PALE)
		x += (28.0 if i == 0 else 22.0)
	if _queue.size() > 1:
		draw_line(Vector2(36, y + 2), Vector2(x - 10, y + 2), Color(DIM, 0.0), 1.0)


## 스킬 바퀴: 칸마다 원 + 이름 + 비용 점. 쓸 수 없으면 흐리게. 고른 칸은 밝고 크게 + 아래 설명 상자
func _draw_wheel() -> void:
	if actor == null:
		return
	var c := _wheel_center()
	var arc := _wheel_arc()
	draw_arc(c, WHEEL_R, float(arc[0]) - 0.2, float(arc[1]) + 0.2, 32, Color(LAV, 0.25), 1.0)
	for i in slots.size():
		var s: Dictionary = slots[i]
		var p: Vector2 = s.pos
		var on := i == sel
		var can := bool(s.can)
		var r := SLOT_R + (3.0 if on else 0.0)
		var is_attack := String(s.kind) == "attack"
		var ring := (FIRE if is_attack else LAV) if can else DIM
		draw_circle(p, r + 1.5, Color(INK, 0.92))
		draw_circle(p, r, Color(LAV if on else INK, 0.95 if on else 0.75))
		draw_arc(p, r, 0.0, TAU, 28, Color(ring, 0.95 if can else 0.4), 1.6 if on else 1.0)
		# 칸 안은 아이콘만 (이름은 아래 설명 상자에). 색: 속성 색, 고른 칸은 INK, 못 쓰면 흐리게
		var ecol: Color = TData.ELEMENT_COLOR.get(String(actor.unit.data.get("element", "")), LAV)
		var icol := INK if on else (ecol if can else Color(DIM, 0.6))
		TIcon.draw(self, p + Vector2(0, -2.5), String(s.icon), icol, r * 0.46)
		var tw := int(r * 2.0 - 2.0)
		# 비용 점 (칸 아래 테 안쪽)
		var cost := int(s.cost)
		if cost > 0:
			var cw := float(cost - 1) * 4.2
			for j in cost:
				var q := p + Vector2(-cw * 0.5 + float(j) * 4.2, r - 4.5)
				draw_circle(q, 1.7, Color(INK, 0.9))
				draw_circle(q, 1.2, GOLD if can else DIM)
		else:
			draw_string(_font, p + Vector2(-r + 1.0, r - 2.0), "+1", HORIZONTAL_ALIGNMENT_CENTER, tw, 7, Color(GOLD, 0.9) if not on else Color(INK, 0.9))
	# 설명 상자 (아래 가운데)
	if sel >= 0 and sel < slots.size():
		var s: Dictionary = slots[sel]
		var box := Rect2(130, size.y - 64, 380, 46)
		draw_rect(box, Color(INK, 0.86))
		draw_rect(box, Color(LAV, 0.6), false, 1.0)
		var title: String = s.name
		var desc := ""
		var cost := int(s.cost)
		if String(s.id) == "basic":
			desc = String(actor.unit.data.basic.desc)
		else:
			desc = String(TData.skill(String(s.id)).desc)
		var decol: Color = TData.ELEMENT_COLOR.get(String(actor.unit.data.get("element", "")), LAV)
		TIcon.draw(self, box.position + Vector2(14, 12), String(s.icon), decol if bool(s.can) else DIM, 7.0)
		_text(box.position + Vector2(26, 16), title, 12, PALE if bool(s.can) else DIM)
		var cx := box.position.x + 30.0 + _font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		for j in cost:
			draw_circle(Vector2(cx + float(j) * 7.0, box.position.y + 12), 2.6, Color(INK, 0.9))
			draw_circle(Vector2(cx + float(j) * 7.0, box.position.y + 12), 2.0, GOLD if bool(s.can) else DIM)
		if cost == 0:
			_text(Vector2(cx, box.position.y + 16), "크레딧 +1", 10, Color(GOLD, 0.9))
		else:
			var kname: String = {"attack": "공격", "support": "보조", "debuff": "디버프"}.get(String(s.kind), "")
			var tname: String = {"enemy": "적 1", "enemies": "적 전체", "ally": "아군 1", "ally_any": "아군 1", "allies": "아군 전체", "self": "자신"}.get(String(s.target), "")
			_text(Vector2(cx + float(cost) * 7.0 + 4.0, box.position.y + 16), "%s · %s" % [kname, tname], 9, Color(DIM, 0.95))
		# 예상 피해 (대상이 있으면 그 대상, 아니면 첫 적)
		var est_tgt: TUnit = null
		if state == "target" and not targets.is_empty():
			est_tgt = (targets[tsel] as TActor).unit
		elif not battle.alive_of(battle.enemies).is_empty():
			est_tgt = battle.alive_of(battle.enemies)[0]
		if String(s.kind) == "attack" and est_tgt != null and not est_tgt.is_witch():
			var est := battle.estimate(actor.unit, est_tgt, "" if String(s.id) == "basic" else String(s.id))
			_text(box.position + Vector2(box.size.x - 10, 16), "예상 %s" % TData.fmt(est), 10, Color(GOLD, 0.9), HORIZONTAL_ALIGNMENT_RIGHT, 0)
		draw_string(_font, box.position + Vector2(10, 34), desc, HORIZONTAL_ALIGNMENT_LEFT, int(box.size.x - 20), 9, Color(PALE, 0.9))


## 대상 표시: 고를 수 있는 대상 위 화살, 지금 고른 대상은 밝게 + 발밑 고리
func _draw_targets() -> void:
	for i in targets.size():
		var a: TActor = targets[i]
		var on := i == tsel
		var top := to_screen(a.head()) + Vector2(0, -16 + sin(_t * 6.0) * 2.0)
		var col := Color(GOLD if on else PALE, 1.0 if on else 0.6)
		draw_colored_polygon(PackedVector2Array([top + Vector2(-6, -9), top + Vector2(6, -9), top]), Color(INK, 0.9))
		draw_colored_polygon(PackedVector2Array([top + Vector2(-4.5, -8), top + Vector2(4.5, -8), top + Vector2(0, -2)]), col)
		var feet := to_screen(a.feet())
		draw_set_transform(feet, 0.0, Vector2(1.0, 0.35))
		draw_arc(Vector2.ZERO, a.half_w() + 8.0, 0.0, TAU, 28, Color(col, 0.9 if on else 0.4), 1.6 if on else 1.0)
		draw_set_transform(Vector2.ZERO)
		if on and not a.unit.is_witch():
			_text(feet + Vector2(0, 14), "%s  체력 %s" % [a.unit.name, TData.fmt_short(a.unit.hp)], 9, Color(PALE, 0.9), HORIZONTAL_ALIGNMENT_CENTER, 0)


func _draw_numbers() -> void:
	for n: Array in numbers:
		var age: float = n[3]
		var kind: String = n[2]
		var p: Vector2 = n[0]
		var rise := 18.0 * (1.0 - pow(1.0 - minf(age / 0.5, 1.0), 2.0))
		var a := 1.0 - clampf((age - 0.6) / 0.5, 0.0, 1.0)
		var pop := 1.0 - clampf(age / 0.12, 0.0, 1.0)
		var fs := 12
		var col := Color("#fff3e0")
		match kind:
			"crit":
				fs = 16
				col = GOLD
			"weak":
				fs = 13
				col = FIRE
			"heal":
				fs = 12
				col = GREEN
			"buff":
				fs = 9
				col = Color("#d9ccff")
			"debuff":
				fs = 9
				col = Color("#c9b8c8")
			"miss":
				fs = 11
				col = Color("#cfcfe0")
			"credit":
				fs = 10
				col = GOLD
			"zero":
				fs = 10
				col = RED
			"mark":
				fs = 9
				col = FIRE
			"revive":
				fs = 12
				col = PALE
			"hurt":
				fs = 13
				col = Color("#ff8a9a")
		fs += int(round(4.0 * pop))
		var text: String = n[1]
		var q := p + Vector2(0, -8 - rise)
		draw_string_outline(_font, q + Vector2(-80, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 160, fs, 4, Color(INK, a))
		draw_string(_font, q + Vector2(-80, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 160, fs, Color(col.lerp(Color.WHITE, pop * 0.6), a))


func _draw_banner() -> void:
	var k := clampf(_banner_t / 0.35, 0.0, 1.0)
	var e := 1.0 - pow(1.0 - k, 3.0)
	var h := 84.0 * e
	var cy := size.y * 0.5
	draw_rect(Rect2(0, cy - h * 0.5, size.x, h), Color(INK, 0.86 * e))
	draw_rect(Rect2(0, cy - h * 0.5, size.x, 1), Color(LAV, 0.8 * e))
	draw_rect(Rect2(0, cy + h * 0.5 - 1, size.x, 1), Color(LAV, 0.8 * e))
	if k >= 1.0:
		var win := banner_text == "승리"
		_text(Vector2(size.x * 0.5, cy + 2), banner_text, 30, GOLD if win else RED, HORIZONTAL_ALIGNMENT_CENTER, 0)
		if fmod(_banner_t, 1.0) < 0.7 and _banner_t > 0.5:
			_text(Vector2(size.x * 0.5, cy + 28), banner_sub, 11, Color(PALE, 0.9), HORIZONTAL_ALIGNMENT_CENTER, 0)
