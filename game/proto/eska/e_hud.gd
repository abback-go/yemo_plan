class_name EHud
extends Control
## 에스카 시제품 화면 표시
## - 왼쪽 위: 이름 + 빌드 번호(어느 버전이 떠 있는지 바로 확인) + 체력 마름모(잃으면 갈라져 흩어짐, 하나 남으면 맥박)
## - 가운데: 알림 글(banner — 물결 번호·쓰러짐·튜토리얼 단계 등)
## - 오른쪽 위: 연타 수(맞힐 때마다 튀어 오름) + 누적 피해, 끊기기 직전엔 흐려짐
## - 아래(키보드일 때만): 키 안내 + 스킬 쿨다운 (터치 중에는 버튼이 쿨다운을 보여 줌)
## 값이 바뀔 때만 다시 그린다 (글자 그리기는 비싸서).

const PALE := Color("#d9ccff")
const VIOLET := Color("#a98bff")
const MAGENTA := Color("#e352ff")
const INK := Color("#14081f")
const PIP_GAP := 11.0
const LOSE_T := 0.5

var eska: EEska
var touch: ETouch
var boss: EEnemy ## 화면 위 가운데 큰 체력바로 보여 줄 적 (튜토리얼 마지막 등)
var boss_name := ""
var _boss_trail := 1.0
var _boss_a := 0.0
var show_keys := true ## 아래쪽 키 안내 (튜토리얼은 자기 안내 칸을 쓰므로 끔)
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


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


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
	if _ban_t < _ban_dur:
		_ban_t += delta
	var sig := "%d|%d|%.1f|%s|%d|%d|%d|%d" % [eska.hit_count, eska.hit_damage, eska.combo_left, str(touch.active if touch else false),
		ceili(eska.cd_left("cheonyeol") * 10.0), ceili(eska.cd_left("dangong") * 10.0), ceili(eska.cd_left("bonggong") * 10.0), ceili(eska.cd_left("ult") * 10.0)]
	if _pop > 0.0:
		sig += "|%.2f" % _pop
	sig += "|%d|%.2f" % [eska.hp, _gain]
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
	_text(font, Vector2(10, 18), "에스카 · 종언의 마녀", 12, Color(1, 1, 1, 0.9))
	_text(font, Vector2(10, 32), "전투 시제품 · 빌드 " + BuildInfo.COMMIT, 11, VIOLET)
	if not is_instance_valid(eska):
		return
	_draw_hp()
	_draw_boss(font)
	_draw_combo(font)
	_draw_banner(font)
	if size.y > size.x and _t < 6.0:
		_draw_rotate_hint(font)
	if (touch and touch.active) or not show_keys:
		return
	var y := size.y - 20.0
	_text(font, Vector2(10, y), "←→ 이동  Z 점프  X 연격  C 순간이동  ↓ 빨리 떨어지기  W 적 물결  Esc 나가기", 11, Color(1, 1, 1, 0.6))
	var x := 10.0
	y = size.y - 36.0
	for spec: Array in [["A", "cheonyeol"], ["↑A", "dangong"], ["S", "bonggong"], ["D", "ult"]]:
		var id: String = spec[1]
		var left := eska.cd_left(id)
		var name: String = EEska.NAMES[id]
		var col := Color(1, 1, 1, 0.9) if left <= 0.0 else Color(1, 1, 1, 0.35)
		var label := "%s %s" % [spec[0], name]
		if left > 0.0:
			label += " %.1f" % left
		_text(font, Vector2(x, y), label, 11, col)
		x += font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 12.0


func _draw_combo(font: Font) -> void:
	if eska.hit_count <= 1:
		return
	var a := clampf(eska.combo_left / 0.4, 0.25, 1.0)
	var right := size.x - 12.0 if not (touch and touch.active) else size.x - 44.0
	var num := "%d" % eska.hit_count
	var fs := 22
	var sc := 1.0 + _pop * 0.35
	var nsz := font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var hit_w := font.get_string_size("HIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var base := Vector2(right - hit_w - 4.0, 62.0)
	draw_set_transform(base, 0.0, Vector2(sc, sc))
	draw_string_outline(font, Vector2(-nsz.x, 0), num, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(0.08, 0.02, 0.16, a))
	draw_string(font, Vector2(-nsz.x, 0), num, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(PALE.lerp(Color.WHITE, _pop), a))
	draw_set_transform(Vector2.ZERO)
	_text(font, Vector2(right - hit_w, 62.0), "HIT", 11, Color(VIOLET, a))
	# 끊기기까지 남은 시간 막대 + 누적 피해
	var bw := 60.0
	draw_rect(Rect2(right - bw, 68.0, bw, 2.0), Color(1, 1, 1, 0.12 * a))
	draw_rect(Rect2(right - bw, 68.0, bw * eska.combo_left / EEska.COMBO_WINDOW, 2.0), Color(VIOLET, 0.9 * a))
	var dmg := "%d" % eska.hit_damage
	var dw := font.get_string_size(dmg, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	_text(font, Vector2(right - dw, 82.0), dmg, 11, Color(1, 1, 1, 0.65 * a))


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
	var y := 13.0 if size.x >= 520.0 else 66.0 # 좁은(세로) 화면은 왼쪽 위 이름·체력 아래로
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
	var base := Vector2(16, 48)
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
