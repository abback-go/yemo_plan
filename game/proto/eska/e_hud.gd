class_name EHud
extends Control
## 에스카 시제품 화면 표시
## - 왼쪽 위: 옅은 어둠 바탕(배경이 밝아도 읽히게) + 이름 + 체력 마름모(잃으면 갈라져 흩어짐, 하나 남으면 맥박)
##   + 종언 게이지 = 그믐달이 보름달로 차오르는 달(가득이면 맥박) + 고른 대마법 이름 (design.md 3-4 #6)
##   + 허리띠 물약 3칸(없음·↑·↓ 표시, 남은 병 점, 빈 칸은 흐리게, F가 지금 고를 칸은 테두리)
## - 가운데: 알림 글(banner — 물결 번호·쓰러짐·튜토리얼 단계 등)
## - 오른쪽 위: 연타 수(맞힐 때마다 튀어 오름) + 누적 피해, 끊기기 직전엔 흐려짐 — 시험 버튼 아래(y COMBO_Y)
## - 아래(키보드일 때만): 키 안내 + 스킬 쿨다운 (터치 중에는 버튼이 쿨다운을 보여 줌).
##   장면 안내 context_hints가 있으면 기본 키 안내 대신 그 줄들을, cinematic(연출 중)이면 안내를 모두 숨긴다
## - 오른쪽 아래 구석: 아주 작은 빌드 번호 (어느 버전이 떠 있는지 확인용)
## 값이 바뀔 때만 다시 그린다 (글자 그리기는 비싸서).

const PALE := Color("#d9ccff")
const VIOLET := Color("#a98bff")
const MAGENTA := Color("#e352ff")
const INK := Color("#14081f")
const PIP_GAP := 11.0
const LOSE_T := 0.5
const ROW_UP := 14.0 ## 예전 "전투 시제품 · 빌드" 줄을 지운 만큼 체력·달·허리띠를 위로 올림
const HP_POS := Vector2(16, 48.0 - ROW_UP) ## 체력 마름모 첫 칸 (이름 아래)
const MOON_C := Vector2(89, 47.0 - ROW_UP) ## 종언 게이지 달 중심 (체력 마름모 오른쪽)
const MOON_R := 7.0
const MOON_MIN := 0.04 ## 이보다 적게 차면 밝은 부분을 그리지 않음 (너무 얇은 초승달은 삼각분할이 안 됨)
const MOON_PULSE := 15.0 ## 가득일 때 맥박 그림을 초당 이만큼만 다시 그림 (글자 그리기가 비싸서)
const FULL_FLASH := 0.6 ## 막 가득 찼을 때 퍼지는 고리 시간
const POP_T := 0.35 ## 대마법을 바꿨을 때 이름이 튀어 오르는 시간
const BELT_X := 18.0 ## 허리띠 첫 칸 병 가운데
const BELT_Y := 72.0 - ROW_UP
const BELT_GAP := 24.0
const BELT_MARKS := ["", "↑", "↓"] ## 칸마다 누르는 방향 (F와 같이). 0칸(그냥)은 글자 대신 그린 점 — 웹 글꼴에 "•"가 없어 상자로 깨짐 (belt_mark)
const MARK_DOT := 1.6 ## 0칸 표시 점 반지름
const POTION_DEFAULT := Color("#c06bff") ## EPotions가 색을 알려 주지 않을 때 병 색
const DENY_SHAKE := 2.5 ## 게이지가 모자라 막혔을 때 달이 흔들리는 폭(px)
const COMBO_Y := 104.0 ## 연타 숫자 글자 바닥선 (숫자 윗끝 약 y 86 — 오른쪽 위 시험 버튼(아래 끝 56)과 겹치지 않게)
const SHADE_R := Vector2(220, 90) ## 왼쪽 위 옅은 어둠 바탕의 크기 (모서리에서 타원으로 옅어짐)
const SHADE_IN := 0.55 ## 어둠 바탕: 이 비율 안쪽은 고른 진하기
const SHADE_A := 0.42 ## 어둠 바탕 진하기
const SHADE_SEG := 12
const HINT_LINE := 16.0 ## 아래 안내 줄 간격
const BUILD_FS := 8 ## 빌드 번호 글자 크기
const CTX_TOUCH_FIRST := 30.0 ## 장면 안내(context_hints)를 돌리는 시간: 싸움 처음 이만큼 (연출 중엔 세지 않음 — loop8 3장, 그 뒤엔 숨김)
const CTX_TOUCH_RESPAWN := 10.0 ## 부활 직후 다시 이만큼
const CTX_FADE := 1.0 ## 사라지기 전 옅어지는 시간
const CTX_NEXT_SHOW := 3.5 ## hold_hints가 끝난 뒤 next 문구를 한 번 보여 주는 시간
const CTX_ROTATE := 3.5 ## 장면 안내는 한 줄씩 이 간격으로 돌아가며
const CTX_SWAP := 0.3 ## 줄이 바뀔 때 옅어졌다 나타나는 시간
const CTX_GAP := 34.0 ## 보스바 이름 줄 아래로 이만큼 (버팀 막대 아래)

var eska: EEska
var touch: ETouch
var boss: EEnemy ## 화면 위 가운데 큰 체력바로 보여 줄 적 (튜토리얼 마지막 등)
var boss_name := ""
var _boss_trail := 1.0
var _boss_a := 0.0
var show_keys := true ## 아래쪽 기본 키 안내 (튜토리얼은 자기 안내 칸을 쓰므로 끔)
var context_hints: Array[String] = [] ## 장면 안내 (비어 있지 않으면 기본 키 안내 대신 이 줄들 — 위에서 아래 순서, 보스장 등)
var cinematic := false ## 연출 중: 아래 안내를 모두 숨김 (훈련장 시험 버튼도 이 값을 보고 숨는다)
var combo_right_pad := 0.0 ## 연타 수를 오른쪽 끝에서 이만큼 더 왼쪽에 (훈련장 연습 과제 칸과 겹치지 않게)
var _ctx_t := CTX_TOUCH_FIRST ## 장면 안내를 진하게 보여 줄 남은 시간 (처음 · 부활 직후)
var _ctx_clock := 0.0 ## 장면 안내 줄 돌리기 시계
var _hold_t := 0.0 ## hold_hints: 장면 안내를 숨겨 둘 남은 시간
var _next_line := "" ## hold_hints가 끝나면 한 번 보여 줄 문구
var _next_t := 0.0 ## 그 문구를 보여 줄 남은 시간
var _sig := ""
var _last_hits := 0
var _pop := 0.0
var _hp_shown := -1
var _lose: Array[float] = [] ## 마름모마다 갈라지는 중 남은 시간
var _gain := 0.0 ## 다시 찼을 때 반짝임
var _ban_title := ""
var _ban_sub := ""
var _ban_t := 0.0
var _ban_dur := 0.0
var _t := 0.0
var _ult_shown := -1
var _ult_pop := 0.0

static var _look_cache := {} ## 물약 id → {"name", "color"}
var _shade_v := PackedVector2Array() ## 왼쪽 위 어둠 바탕 (한 번 만들어 둠)
var _shade_c := PackedColorArray()
var _shade_i := PackedInt32Array()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(eska):
		eska.respawned.connect(func() -> void: _ctx_t = CTX_TOUCH_RESPAWN)


func _process(delta: float) -> void:
	# 부모가 CanvasLayer라 앵커만으로는 크기가 0으로 남는다 → 화면 크기를 직접 따라감 (화면 회전·창 크기 변경 포함)
	var vs := get_viewport_rect().size
	if size != vs:
		size = vs
		_sig = ""
	if not is_instance_valid(eska):
		return
	if eska.hit_count != _last_hits:
		if eska.hit_count > _last_hits:
			_pop = 1.0
		_last_hits = eska.hit_count
	_pop = maxf(_pop - delta * 6.0, 0.0)
	_t += delta
	_track_hp(delta)
	_track_boss(delta)
	if eska.ult_index != _ult_shown:
		if _ult_shown >= 0:
			_ult_pop = POP_T
		_ult_shown = eska.ult_index
	_ult_pop = maxf(_ult_pop - delta, 0.0)
	if _ban_t < _ban_dur:
		_ban_t += delta
	if not cinematic: # 연출 중엔 세지 않음 (보스 등장 연출이 끝나야 "싸움 처음")
		_ctx_t = maxf(_ctx_t - delta, 0.0)
	_ctx_clock += delta
	if _hold_t > 0.0:
		_hold_t = maxf(_hold_t - delta, 0.0)
		if _hold_t <= 0.0 and _next_line != "":
			_next_t = CTX_NEXT_SHOW
	elif _next_t > 0.0:
		_next_t = maxf(_next_t - delta, 0.0)
		if _next_t <= 0.0:
			_next_line = ""
	var sig := "%d|%d|%.1f|%s|%s|%s|%s" % [eska.hit_count, eska.hit_damage, eska.combo_left, str(touch.active if touch else false), str(cinematic), str(context_hints), str(EKeys.touch_mode)]
	if (not context_hints.is_empty() or _next_t > 0.0 or _hold_t > 0.0) and not cinematic:
		sig += "|c%.2f|%d|%.2f|h%.2f|%.2f" % [minf(_ctx_t, CTX_FADE), _ctx_line(), _ctx_swap_a(), minf(_hold_t, 0.01), minf(_next_t, CTX_FADE)]
	for id: String in EEska.CD:
		sig += "|%d" % ceili(eska.cd_left(id) * 10.0)
	if _pop > 0.0:
		sig += "|%.2f" % _pop
	sig += "|%d|%.2f" % [eska.hp, _gain]
	sig += "|g%d|%d|%.2f|%.2f|%d" % [int(eska.gauge_ratio() * 200.0), eska.ult_index, _ult_pop, eska.ult_denied, eska.potion_slot_for_dir()]
	if eska.gauge_ratio() >= 1.0:
		sig += "|%d" % int(_t * MOON_PULSE)
		if eska.ult_full_t < FULL_FLASH:
			sig += "|%.2f" % eska.ult_full_t
	for sl: Dictionary in eska.belt.slots:
		sig += "|%s%d" % [String(sl.get("id", "")), int(sl.get("left", 0))]
	for l in _lose:
		sig += "|%.2f" % l
	if _boss_a > 0.0:
		sig += "|b%.3f|%.3f" % [_boss_a, _boss_trail]
		if is_instance_valid(boss):
			sig += "|%d" % boss.hp
	if eska.hp == 1 or _ban_t < _ban_dur or (size.y > size.x and _t < 6.5):
		sig += "|%.2f" % _t
	if sig != _sig:
		_sig = sig
		queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	_draw_shade()
	_text(font, Vector2(10, 18), "에스카 · 종언의 마녀", 12, Color(1, 1, 1, 0.9))
	_draw_build(font)
	if not is_instance_valid(eska):
		return
	_draw_hp()
	_draw_gauge(font)
	_draw_belt(font)
	_draw_boss(font)
	_draw_combo(font)
	_draw_banner(font)
	if size.y > size.x and _t < 6.0:
		_draw_rotate_hint(font)
	if cinematic:
		return
	if not context_hints.is_empty() or _next_t > 0.0:
		_draw_context_line(font) # 키보드·터치 모두 보스바 아래 가운데 한 줄 (왼쪽 아래 기본 키 안내 대신)
		return
	if touch and touch.active:
		return
	if not show_keys:
		return
	var y := size.y - 20.0
	var keys := "%s%s 이동  %s 점프  %s 베기  %s 순간이동  %s 빨리 떨어지기  %s·%s·%s 물약  W 적 물결  G 게이지  Esc 나가기" % [
		EKeys.label("es_left"), EKeys.label("es_right"), EKeys.label("es_jump"), EKeys.label("es_attack"), EKeys.label("es_blink"), EKeys.label("es_down"),
		EKeys.label("es_potion"), EKeys.with_dir("es_up", "es_potion"), EKeys.with_dir("es_down", "es_potion")]
	_text(font, Vector2(10, y), keys, 11, Color(1, 1, 1, 0.6))
	var x := 10.0
	y = size.y - 36.0
	for spec: Array in [[EKeys.label("es_skill"), "cheonyeol"], [EKeys.with_dir("es_up", "es_skill"), "dangong"], [EKeys.with_dir("es_down", "es_skill"), "nakseong"]]:
		var id: String = spec[1]
		var left := eska.cd_left(id)
		var name: String = EEska.NAMES[id]
		var col := Color(1, 1, 1, 0.9) if left <= 0.0 else Color(1, 1, 1, 0.35)
		var label := "%s %s" % [spec[0], name]
		if left > 0.0:
			label += " %.1f" % left
		_text(font, Vector2(x, y), label, 11, col)
		x += font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 12.0
	var full := eska.gauge_ratio() >= 1.0
	var ult := "%s 대마법 %s %s  %s 고르기" % [EKeys.label("es_bind"), EEska.ULT_NAMES[eska.selected_ult()], "가득" if full else "%d%%" % int(eska.gauge_ratio() * 100.0), EKeys.label("es_ult_next")]
	_text(font, Vector2(x, y), ult, 11, Color(1, 1, 1, 0.9) if full else Color(1, 1, 1, 0.5))


## 지금 보여 줄 장면 안내 줄 번호 (CTX_ROTATE마다 다음 줄)
func _ctx_line() -> int:
	return int(_ctx_clock / CTX_ROTATE) % maxi(context_hints.size(), 1)


## 줄이 바뀌는 순간 옅어졌다 나타남 (0~1)
func _ctx_swap_a() -> float:
	if context_hints.size() <= 1:
		return 1.0
	var ph := fmod(_ctx_clock, CTX_ROTATE)
	return clampf(minf(ph, CTX_ROTATE - ph) / CTX_SWAP, 0.0, 1.0)


## 장면 안내를 sec초 숨긴다 (보스 작업자가 배움·쓰러짐 때 부름). 끝나면 next가 있으면 그 문구를 CTX_NEXT_SHOW초 한 번 보여 주고 돌리기로 돌아간다
func hold_hints(sec: float, next: String = "") -> void:
	_hold_t = maxf(sec, 0.01)
	_next_line = next
	_next_t = 0.0


## 장면 안내: 보스바(+버팀 막대) 아래 가운데에 한 줄씩 돌아가며 (키보드·터치 모두 — loop7 3장).
## 돌리기는 싸움 처음 CTX_TOUCH_FIRST초와 부활 직후 CTX_TOUCH_RESPAWN초만, 그 뒤엔 숨김 (loop8 3장). hold_hints 중엔 숨김, 끝나면 next 한 번.
## {es_동작}은 지금 입력 방식 이름으로 (EKeys.fmt)
func _draw_context_line(font: Font) -> void:
	if _hold_t > 0.0:
		return
	var s := ""
	var a := 0.0
	if _next_t > 0.0:
		s = EKeys.fmt(_next_line)
		a = minf(_next_t / CTX_FADE, 1.0)
	else:
		a = minf(_ctx_t / CTX_FADE, 1.0) * _ctx_swap_a()
		if a <= 0.01:
			return
		s = EKeys.fmt(context_hints[_ctx_line()])
	var y := (13.0 if size.x >= 520.0 else BELT_Y + 20.0) + CTX_GAP
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	draw_rect(Rect2(size.x * 0.5 - w * 0.5 - 8.0, y - 12.0, w + 16.0, HINT_LINE + 2.0), Color(INK, 0.55 * a))
	_text(font, Vector2(size.x * 0.5 - w * 0.5, y), s, 11, Color(1, 1, 1, 0.9 * a))


## 왼쪽 위 옅은 어둠 바탕: 모서리에서 타원으로 옅어진다 (안쪽은 고른 진하기, 바깥 띠에서 0으로) — 삼각형 묶음 하나로 한 번에 그림
func _draw_shade() -> void:
	if _shade_v.is_empty():
		_build_shade()
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), _shade_i, _shade_v, _shade_c)


## 어둠 바탕 모양: 0 = 모서리, 1~SEG+1 = 안쪽 고리, 그 뒤 SEG+1개 = 바깥 고리 (모양이 고정이라 한 번만 만듦)
func _build_shade() -> void:
	var dark := Color(INK, SHADE_A)
	var clear := Color(INK, 0.0)
	_shade_v.append(Vector2.ZERO)
	_shade_c.append(dark)
	for ring in 2:
		for i in SHADE_SEG + 1:
			var a := PI * 0.5 * float(i) / float(SHADE_SEG)
			var d := Vector2(cos(a) * SHADE_R.x, sin(a) * SHADE_R.y)
			_shade_v.append(d * (SHADE_IN if ring == 0 else 1.0))
			_shade_c.append(dark if ring == 0 else clear)
	var o := SHADE_SEG + 2 # 바깥 고리 첫 번호
	for i in SHADE_SEG:
		_shade_i.append_array([0, 1 + i, 2 + i]) # 안쪽 부채
		_shade_i.append_array([1 + i, o + i, o + i + 1, 1 + i, o + i + 1, 2 + i]) # 바깥 띠


## 빌드 번호: 오른쪽 아래 구석에 아주 작게
func _draw_build(font: Font) -> void:
	var s := "빌드 " + BuildInfo.COMMIT
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, BUILD_FS).x
	draw_string(font, Vector2(size.x - w - 4.0, size.y - 4.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, BUILD_FS, Color(PALE, 0.3))


func _draw_combo(font: Font) -> void:
	if eska.hit_count <= 1:
		return
	var a := clampf(eska.combo_left / 0.4, 0.25, 1.0)
	var right := (size.x - 12.0 if not (touch and touch.active) else size.x - 44.0) - combo_right_pad
	var num := "%d" % eska.hit_count
	var fs := 22
	var sc := 1.0 + _pop * 0.35
	var nsz := font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var hit_w := font.get_string_size("HIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var base := Vector2(right - hit_w - 4.0, COMBO_Y)
	draw_set_transform(base, 0.0, Vector2(sc, sc))
	draw_string_outline(font, Vector2(-nsz.x, 0), num, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(0.08, 0.02, 0.16, a))
	draw_string(font, Vector2(-nsz.x, 0), num, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(PALE.lerp(Color.WHITE, _pop), a))
	draw_set_transform(Vector2.ZERO)
	_text(font, Vector2(right - hit_w, COMBO_Y), "HIT", 11, Color(VIOLET, a))
	# 끊기기까지 남은 시간 막대 + 누적 피해
	var bw := 60.0
	draw_rect(Rect2(right - bw, COMBO_Y + 6.0, bw, 2.0), Color(1, 1, 1, 0.12 * a))
	draw_rect(Rect2(right - bw, COMBO_Y + 6.0, bw * eska.combo_left / EEska.COMBO_WINDOW, 2.0), Color(VIOLET, 0.9 * a))
	var dmg := "%d" % eska.hit_damage
	var dw := font.get_string_size(dmg, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	_text(font, Vector2(right - dw, COMBO_Y + 20.0), dmg, 11, Color(1, 1, 1, 0.65 * a))


## 세로 화면: 가로로 돌리라는 작은 안내 (처음 6초만, 막지는 않음 — 휴대폰을 돌리는 그림이 천천히 기울어짐)
func _draw_rotate_hint(font: Font) -> void:
	var c := Vector2(size.x * 0.5, size.y * 0.16)
	var k := 0.5 - 0.5 * cos(_t * 2.0)
	draw_set_transform(c, -k * PI * 0.5, Vector2.ONE)
	draw_rect(Rect2(-9, -15, 18, 30), Color(PALE, 0.8), false, 1.5)
	draw_rect(Rect2(-3, 11, 6, 1.5), Color(PALE, 0.8))
	draw_set_transform(Vector2.ZERO)
	var msg := "가로로 돌리면 더 넓게 보여요"
	var mw := font.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	_text(font, c + Vector2(-mw * 0.5, 34), msg, 13, Color(PALE, 0.85))


## 가운데 알림 글: 커지며 나타나 잠시 머물다 사라짐
func banner(title: String, sub := "", dur := 1.8) -> void:
	_ban_title = title
	_ban_sub = sub
	_ban_t = 0.0
	_ban_dur = dur
	queue_redraw()


func _track_hp(delta: float) -> void:
	if _lose.size() != EEska.MAX_HP:
		_lose.resize(EEska.MAX_HP)
		_lose.fill(0.0)
	for i in _lose.size():
		_lose[i] = maxf(_lose[i] - delta, 0.0)
	_gain = maxf(_gain - delta * 2.0, 0.0)
	if _hp_shown < 0:
		_hp_shown = eska.hp
	if eska.hp < _hp_shown:
		for i in range(eska.hp, _hp_shown):
			_lose[i] = LOSE_T
	elif eska.hp > _hp_shown:
		_gain = 1.0
	_hp_shown = eska.hp


func _track_boss(delta: float) -> void:
	var alive := is_instance_valid(boss) and not boss.is_dead()
	_boss_a = move_toward(_boss_a, 1.0 if alive else 0.0, delta * (3.0 if alive else 1.2))
	if is_instance_valid(boss):
		var f := clampf(float(boss.hp) / float(boss.max_hp), 0.0, 1.0)
		_boss_trail = move_toward(_boss_trail, f, delta * 0.5) if _boss_trail > f else f
	elif _boss_a <= 0.0:
		_boss_trail = 1.0


## 보스 체력바: 화면 위 가운데 — 이름 + 긴 막대(막 깎인 부분은 밝게 남았다 따라 내려감)
func _draw_boss(font: Font) -> void:
	if _boss_a <= 0.0:
		return
	var a := _boss_a
	var w := minf(300.0, size.x * 0.46)
	var x := size.x * 0.5 - w * 0.5
	var f := clampf(float(boss.hp) / float(boss.max_hp), 0.0, 1.0) if is_instance_valid(boss) else 0.0
	var y := 13.0 if size.x >= 520.0 else BELT_Y + 20.0 # 좁은(세로) 화면은 왼쪽 위 이름·체력·허리띠 아래로
	if size.x < 520.0:
		w = size.x - 40.0
		x = 20.0
	var nw := font.get_string_size(boss_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	_text(font, Vector2(size.x * 0.5 - nw * 0.5, y), boss_name, 11, Color(1.0, 0.85, 0.85, a))
	draw_rect(Rect2(x - 2, y + 4, w + 4, 7), Color(0, 0, 0, 0.75 * a))
	draw_rect(Rect2(x, y + 6, w * _boss_trail, 3), Color(1.0, 0.8, 0.75, 0.85 * a))
	draw_rect(Rect2(x, y + 6, w * f, 3), Color(EEnemy.RED, a))
	draw_rect(Rect2(x, y + 6, w * f, 1), Color(EEnemy.RED_HOT, 0.8 * a))
	for q in [0.25, 0.5, 0.75]:
		draw_rect(Rect2(x + w * q, y + 5, 1, 5), Color(0, 0, 0, 0.6 * a))


## 체력 마름모 (왼쪽 위, 이름 아래)
func _draw_hp() -> void:
	var base := HP_POS
	var beat := 0.5 + 0.5 * sin(_t * 9.0) if eska.hp == 1 else 0.0
	for i in EEska.MAX_HP:
		var p := base + Vector2(PIP_GAP * i, 0)
		var full := i < eska.hp
		_diamond(p, 4.6, Color(INK, 0.85))
		if full:
			var s := 3.4 + beat * 0.8 + _gain * 0.8
			_diamond(p, s, MAGENTA.lerp(Color.WHITE, _gain * 0.6 + beat * 0.3))
			_diamond(p + Vector2(0, -0.8), s * 0.45, Color(1, 1, 1, 0.75))
		else:
			_diamond(p, 3.0, Color(VIOLET, 0.18))
		var l := _lose[i] if i < _lose.size() else 0.0
		if l > 0.0:
			# 갈라짐: 흰 섬광 → 좌우 반쪽이 떨어지며 사라짐
			var f := 1.0 - l / LOSE_T
			var a := 1.0 - f
			var off := Vector2(3.0 + f * 7.0, f * f * 10.0)
			for sd in [-1.0, 1.0]:
				var q: Vector2 = p + Vector2(sd * off.x, off.y)
				draw_colored_polygon(PackedVector2Array([q + Vector2(0, -4), q + Vector2(sd * 4.0, 0), q + Vector2(0, 4)]), Color(MAGENTA.lerp(Color.WHITE, a), a))
			if f < 0.3:
				draw_circle(p, 7.0 * (1.0 - f / 0.3) + 2.0, Color(1, 1, 1, 0.8 * (1.0 - f / 0.3)))


## 종언 게이지: 그믐(빈 검은 원)에서 오른쪽부터 차올라 보름달이 된다. 가득이면 맥박 + 막 찼을 때 퍼지는 고리.
## 옆에 고른 대마법 이름 (바꾸면 튀어 오름). 게이지가 모자란데 S를 누르면 달이 흔들린다
func _draw_gauge(font: Font) -> void:
	var f := eska.gauge_ratio()
	var full := f >= 1.0
	var c := MOON_C
	if eska.ult_denied > 0.0:
		c.x += sin(eska.ult_denied * 70.0) * DENY_SHAKE * (eska.ult_denied / EEska.ULT_DENY_GAP)
	var beat := 0.5 + 0.5 * sin(_t * 6.0) if full else 0.0
	if full:
		draw_circle(c, MOON_R + 4.0 + beat * 2.0, Color(MAGENTA, 0.16 + 0.12 * beat))
	draw_circle(c, MOON_R + 1.2, Color(INK, 0.9))
	draw_circle(c, MOON_R, Color(VIOLET, 0.14))
	if f >= MOON_MIN:
		draw_colored_polygon(moon_shape(c, MOON_R, f), PALE.lerp(Color.WHITE, 0.4 + 0.4 * beat) if full else Color(PALE, 0.9))
	draw_arc(c, MOON_R + 1.2, 0.0, TAU, 24, Color(VIOLET, 0.8 if full else 0.45), 1.0)
	if full and eska.ult_full_t < FULL_FLASH:
		var k := eska.ult_full_t / FULL_FLASH
		draw_arc(c, MOON_R + 2.0 + k * 14.0, 0.0, TAU, 28, Color(EVfx.EDGE, 1.0 - k), 1.5)
	var name: String = EEska.ULT_NAMES[eska.selected_ult()]
	var sc := 1.0 + 0.35 * (_ult_pop / POP_T)
	var p := Vector2(MOON_C.x + MOON_R + 8.0, MOON_C.y + 4.0)
	draw_set_transform(p, 0.0, Vector2(sc, sc))
	var col := Color.WHITE if full else Color(PALE, 0.7)
	draw_string_outline(font, Vector2.ZERO, name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 3, Color(0, 0, 0, 0.7))
	draw_string(font, Vector2.ZERO, name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col.lerp(EVfx.EDGE, _ult_pop / POP_T))
	draw_set_transform(Vector2.ZERO)


## 달 모양(밝은 부분): 오른쪽 가장자리 반원 + 명암 경계(타원). f 0 = 그믐, 0.5 = 반달, 1 = 보름 (터치 버튼도 씀)
static func moon_shape(c: Vector2, r: float, f: float, n := 12) -> PackedVector2Array:
	var k := cos(clampf(f, 0.0, 1.0) * PI) # 경계 타원의 가로 배수 (1 → -1)
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := -PI / 2.0 + PI * float(i) / float(n)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	for i in range(1, n):
		var a := PI / 2.0 - PI * float(i) / float(n)
		pts.append(c + Vector2(cos(a) * r * k, sin(a) * r))
	return pts


## 허리띠 3칸: 병(빈 칸은 테두리만) · 칸 방향 표시 · 남은 병 점. F가 지금 고를 칸은 밝은 테두리
func _draw_belt(font: Font) -> void:
	var slots: Array = eska.belt.slots
	var pick := eska.potion_slot_for_dir()
	for i in slots.size():
		var sl: Dictionary = slots[i]
		var c := Vector2(BELT_X + BELT_GAP * i, BELT_Y)
		var has := String(sl.get("id", "")) != ""
		var left := int(sl.get("left", 0))
		var mx := int(sl.get("max", 0))
		var look := potion_look(sl)
		var a := 1.0 if has and left > 0 else 0.35
		if i == pick and (touch == null or not touch.active):
			draw_rect(Rect2(c + Vector2(-9, -13), Vector2(20, 26)), Color(VIOLET, 0.16)) # F가 지금 고를 칸
		bottle(self, c, 1.0, look.color if has else Color(VIOLET, 0.0), a, has and left > 0)
		belt_mark(self, font, c + Vector2(6.0, -6.0), i, 9, Color(PALE, 0.75))
		for d in mx:
			var dp := c + Vector2((float(d) - float(mx - 1) * 0.5) * 3.5, 9.0)
			draw_rect(Rect2(dp - Vector2(1, 1), Vector2(2, 2)), Color(PALE, 0.9) if d < left else Color(PALE, 0.2))


## 허리띠 칸 방향 표시 (HUD·터치 버튼이 같이 씀): 0칸 = 그린 점, 1·2칸 = ↑·↓ 글자. p = 글자 바닥선 왼쪽
static func belt_mark(ci: CanvasItem, font: Font, p: Vector2, i: int, fs: int, col: Color) -> void:
	if i == 0:
		var c := p + Vector2(fs * 0.3, -fs * 0.35)
		ci.draw_circle(c, MARK_DOT + 1.0, Color(0, 0, 0, 0.6 * col.a))
		ci.draw_circle(c, MARK_DOT, col)
		return
	var m: String = BELT_MARKS[i]
	ci.draw_string_outline(font, p, m, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0, 0, 0, 0.7 * col.a))
	ci.draw_string(font, p, m, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


## 물약 병 그림 (HUD·터치 버튼이 같이 씀): c = 몸통 가운데, s = 배율, liquid = 물약 색, filled = 차 있음
static func bottle(ci: CanvasItem, c: Vector2, s: float, liquid: Color, a: float, filled: bool) -> void:
	var r := 4.2 * s
	ci.draw_circle(c, r + 1.0 * s, Color(INK, 0.85 * a))
	ci.draw_rect(Rect2(c + Vector2(-1.8 * s, -r - 4.2 * s), Vector2(3.6 * s, 4.6 * s)), Color(INK, 0.85 * a))
	if filled:
		ci.draw_circle(c + Vector2(0, 0.6 * s), r * 0.8, Color(liquid, a))
		ci.draw_circle(c + Vector2(-1.4, -1.2) * s, 0.9 * s, Color(1, 1, 1, 0.85 * a))
	ci.draw_arc(c, r, 0.0, TAU, 16, Color(PALE, 0.7 * a), 1.0)
	ci.draw_rect(Rect2(c + Vector2(-1.1 * s, -r - 3.4 * s), Vector2(2.2 * s, 3.0 * s)), Color(PALE, 0.5 * a), false, 1.0)
	ci.draw_rect(Rect2(c + Vector2(-1.4 * s, -r - 5.2 * s), Vector2(2.8 * s, 1.8 * s)), Color(0.55, 0.42, 0.31, a)) # 코르크


## 물약 표시용 이름·색: 허리띠 칸 {"id", ...} → {"name", "color"} (EPotions 자료)
static func potion_look(sl: Dictionary) -> Dictionary:
	var id := String(sl.get("id", ""))
	if id == "":
		return {"name": "", "color": POTION_DEFAULT}
	if not _look_cache.has(id):
		_look_cache[id] = {"name": EPotions.display_name(id), "color": EPotions.color(id)}
	return _look_cache[id]


func _diamond(p: Vector2, r: float, c: Color) -> void:
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r * 1.25), p + Vector2(r, 0), p + Vector2(0, r * 1.25), p + Vector2(-r, 0)]), c)


func _draw_banner(font: Font) -> void:
	if _ban_t >= _ban_dur or _ban_title == "":
		return
	var inn := clampf(_ban_t / 0.22, 0.0, 1.0)
	var out := clampf((_ban_dur - _ban_t) / 0.35, 0.0, 1.0)
	var a := minf(inn, out)
	var e := 1.0 - pow(1.0 - inn, 3.0)
	var c := Vector2(size.x * 0.5, size.y * 0.3)
	var fs := 26
	var sc := 1.25 - 0.25 * e
	var tw := font.get_string_size(_ban_title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	# 양옆으로 뻗는 가는 선
	var lw := (60.0 + tw * 0.5) * e
	draw_line(c + Vector2(-lw - tw * 0.5, -8), c + Vector2(-tw * 0.5 - 10, -8), Color(MAGENTA, 0.7 * a), 1.0)
	draw_line(c + Vector2(tw * 0.5 + 10, -8), c + Vector2(lw + tw * 0.5, -8), Color(MAGENTA, 0.7 * a), 1.0)
	draw_set_transform(c, 0.0, Vector2(sc, sc))
	draw_string_outline(font, Vector2(-tw * 0.5, 0), _ban_title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(INK, 0.9 * a))
	draw_string(font, Vector2(-tw * 0.5, 0), _ban_title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(PALE.lerp(Color.WHITE, 1.0 - e), a))
	draw_set_transform(Vector2.ZERO)
	if _ban_sub != "":
		var sw := font.get_string_size(_ban_sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		_text(font, c + Vector2(-sw * 0.5, 18), _ban_sub, 12, Color(VIOLET, a))


func _text(font: Font, p: Vector2, s: String, fs: int, col: Color) -> void:
	draw_string_outline(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0, 0, 0, 0.7 * col.a))
	draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
