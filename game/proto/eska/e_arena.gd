extends EStage
## 에스카 훈련장: 마녀 분위기의 일자형 마당 + 허수아비 하나 + 공중 표적(매달린 모래주머니) + 구슬을 천천히 쏘는 망령 표적 + 적 물결(EWaves).
## 적 물결은 오른쪽 위 버튼이나 W 키로 켜고 끈다 (기본 꺼짐 — loop4 3장).
## 오른쪽 위 "마녀의 연습 과제" 5줄: 낙성으로 공중 표적 · 단공 딱 맞춤 · 새 물약 달이기 · 틈 달이기 · 대마법 — 해내면 체크.
## 평소엔 접힌 한 줄("연습 과제 1/5 ▸"), 체크될 때 잠깐 · 누르면(터치·클릭) 펼침. 안내판은 에스카가 가까이 가야 진해진다 (loop5 4장).
## 오른쪽 끝은 공간 고정 시험 구역: 떨어지는 돌을 봉공으로 굳혀 밟고 높은 턱(점프로는 안 닿음)에 오른다.
## 봉공 진화(굳은 동안 준 피해의 50%가 깨질 때 터짐)는 오른쪽 위 두 번째 버튼이나 T 키로 켜고 끈다.
## 종언 게이지는 오른쪽 위 세 번째 버튼 "게이지 가득"이나 G 키로 바로 채운다 (대마법 시험). 왼쪽 끝에 마녀의 가마솥.
## 가마솥 위에 틈 달이기 안내판 (천열로 찢은 틈에 물약을 던져 넣기 — loop3 1장). 안내판 글은 입력 방식(키보드/터치)을 따라 바뀐다 (EKeys.label).
## 들어오는 길: 타이틀 메뉴 "에스카 시제품" 또는 웹 주소 뒤 ?eska

const W := 1280.0
const FLOOR := 300.0
const SHELF := Rect2(1150, FLOOR - 200.0, 114, 14) ## 공간 고정 시험: 이단점프(81)로는 안 닿는 높은 턱
const ROCK_XS: Array[float] = [1040.0, 1096.0] ## 돌이 떨어지는 두 기둥 (반 간격씩 어긋남 → 굳히면 엇갈린 계단)
const CAULDRON_X := 250.0 ## 가마솥 자리 (부활 자리 왼쪽)
const RIFT_SIGN := Vector2(CAULDRON_X, FLOOR - 160.0) ## 틈 달이기 안내판: 가운데 위 (가마솥 위 — 물약과 같은 자리에)
const AIR_TARGET := Vector2(700, FLOOR - 140.0) ## 공중 표적(매달린 모래주머니) — 낙성 연습
const WISP_HOME := Vector2(880, FLOOR - 74.0) ## 연습용 망령이 떠 있는 자리 — 단공 딱 맞춤 연습
const WISP_BACK := 4.0 ## 연습용 망령이 쓰러지면 이만큼 뒤 다시 나타남
const SIGN_FAR_A := 0.3 ## 안내판: 멀리 있을 때 진하기
const SIGN_NEAR := 170.0 ## 안내판: 에스카가 이 가로 거리 안이면 다 진함
const SIGN_FADE := 150.0 ## 그 바깥 이만큼에 걸쳐 옅어짐
const SIGN_SPEED := 3.0 ## 진하기가 바뀌는 빠르기 (초당)
const BTN_TOP := [8.0, 34.0] ## 오른쪽 위 시험 버튼들의 위 끝 (적 물결 · 봉공 진화). 그 아래는 연타 수 자리
const BTN_W := 104.0 ## 시험 버튼 너비
const BTN_RIGHT := -42.0 ## 첫 줄 버튼 오른쪽 끝 (나가기 ✕ 왼쪽)
const BTN_COL2 := -110.0 ## "게이지 가득"은 왼쪽 옆 줄에 (연타 수와 겹치지 않게)

var dummy: PDummy
var waves: EWaves
var _wave_btn: Button
var _still_btn: Button
var _gauge_btn: Button
var cauldron: ECauldron
var shelf_hits := 0 ## 시험 구역 턱에 오른 횟수
var _on_shelf := false
var air_target: PDummy
var wisp: PracticeWisp
var practice: PracticeList
var signs: Array[Node2D] = [] ## 가까이 가야 진해지는 안내판들 (sign_x로 가운데 가로 위치를 알림)
var _wisp_wait := 0.0
var practice_on := false ## 연습 표적(공중 모래주머니·망령)이 있나 — 시험 실행기에서는 다른 시나리오 수치를 흔들지 않게 기본 끔 (eval set_practice(true))
var _air_hp := 0
var _book0 := 0 ## 들어올 때 마녀 수첩에 적힌 조합 수 (새 물약 과제)
var _rift0 := 0 ## 들어올 때 틈 달이기 수
var _star0 := 0


func _build() -> void:
	stage_w = W
	floor_y = FLOOR
	cam_top = FLOOR - 560.0
	respawn_at = Vector2(400, FLOOR)
	EScenery.build(self, W, FLOOR)
	flat_ground()
	dummy = PDummy.new()
	dummy.setup("small")
	dummy.position = Vector2(540, FLOOR)
	add_child(dummy)
	solid(SHELF)
	var mark := ShelfMark.new()
	mark.shelf = SHELF
	signs.append(mark)
	add_child(mark)
	var fall := EStill.RockFall.new()
	fall.xs = ROCK_XS
	fall.top = FLOOR - 430.0
	fall.floor_y = FLOOR
	add_child(fall)
	cauldron = ECauldron.place(self, Vector2(CAULDRON_X, FLOOR))
	var sign := RiftSign.new()
	sign.at = RIFT_SIGN
	signs.append(sign)
	add_child(sign)


func _start() -> void:
	waves = EWaves.new()
	waves.stage = self
	waves.enabled = false # 기본 꺼짐 (버튼·W로 켬)
	add_child(waves)
	_wave_btn = _make_button("적 물결: 꺼짐", BTN_TOP[0], _toggle_waves)
	hud.get_parent().add_child(_wave_btn)
	_still_btn = _make_button(_still_label(), BTN_TOP[1], _toggle_still)
	hud.get_parent().add_child(_still_btn)
	_gauge_btn = _make_button("게이지 가득", BTN_TOP[0], _fill_gauge, BTN_COL2)
	hud.get_parent().add_child(_gauge_btn)
	practice = PracticeList.new()
	practice.hud = hud
	hud.get_parent().add_child(practice)
	_book0 = EPotions.notebook.size()
	_rift0 = EPotions.rift_brews
	_star0 = EPotions.star_brews
	if get_tree().get_script() == null: # 시험 실행기(SceneTree 스크립트)가 아니면 = 실제 플레이
		set_practice(true)


func _process(delta: float) -> void:
	super._process(delta)
	var show_btns := not hud.cinematic # 연출 중엔 시험 버튼도 숨김
	for b: Button in [_wave_btn, _still_btn, _gauge_btn]:
		if b.visible != show_btns:
			b.visible = show_btns
	if Input.is_action_just_pressed("es_waves"):
		_toggle_waves()
	if Input.is_action_just_pressed("es_still_t"):
		_toggle_still()
	if Input.is_action_just_pressed("es_gauge_fill"):
		_fill_gauge()
	_track_practice()
	hud.combo_right_pad = PracticeList.W + 8.0 if practice.is_open() else 0.0 # 펼쳤을 땐 연타 수를 칸 왼쪽으로, 접혔을 땐 그 아래(원래 자리)
	for sg in signs:
		var d := absf(eska.global_position.x - float(sg.call("sign_x")))
		var want := lerpf(1.0, SIGN_FAR_A, clampf((d - SIGN_NEAR) / SIGN_FADE, 0.0, 1.0))
		sg.modulate.a = move_toward(sg.modulate.a, want, delta * SIGN_SPEED)
	if practice_on and (not is_instance_valid(wisp) or wisp.is_dead()):
		_wisp_wait += delta
		if _wisp_wait >= WISP_BACK:
			_spawn_wisp()
	var up := eska.is_on_floor() and eska.global_position.y <= SHELF.position.y + 2.0 and eska.global_position.x > SHELF.position.x
	if up and not _on_shelf:
		shelf_hits += 1
		hud.banner("공간 고정", "떨어지는 돌을 굳혀 올라왔다", 1.6)
		Sfx.play(&"checkpoint", -4.0)
	_on_shelf = up


## 연습 표적 켜기/끄기 (시험 실행기 eval용으로도 씀)
func set_practice(on: bool) -> String:
	practice_on = on
	if on and not is_instance_valid(air_target):
		air_target = PDummy.new()
		air_target.setup("hang")
		air_target.position = AIR_TARGET
		add_child(air_target)
		_air_hp = air_target.hp
		_spawn_wisp()
	elif not on:
		if is_instance_valid(air_target):
			air_target.queue_free()
		if is_instance_valid(wisp):
			wisp.queue_free()
	return "practice=%s" % str(on)


func _spawn_wisp() -> void:
	_wisp_wait = 0.0
	wisp = PracticeWisp.new()
	wisp.home = WISP_HOME
	wisp.x_min = 24.0
	wisp.x_max = W - 24.0
	wisp.position = WISP_HOME
	add_child(wisp)


## 연습 과제 확인 (해낸 순간 체크)
func _track_practice() -> void:
	if is_instance_valid(air_target):
		if air_target.hp < _air_hp and _nakseong_alive():
			practice.mark(PracticeList.T_NAKSEONG)
		_air_hp = air_target.hp
	if is_instance_valid(eska.last_upsweep) and int(eska.last_upsweep.get("perfects")) > 0:
		practice.mark(PracticeList.T_PERFECT)
	if EPotions.notebook.size() > _book0:
		practice.mark(PracticeList.T_BREW)
	if EPotions.rift_brews > _rift0 or EPotions.star_brews > _star0:
		practice.mark(PracticeList.T_RIFT)
	if eska.st == EEska.St.ULT:
		practice.mark(PracticeList.T_ULT)


## 낙성 이펙트가 지금 있나 (공중 표적이 낙성에 맞았는지 가림)
func _nakseong_alive() -> bool:
	for n: Node in Fx.effect_parent().get_children():
		if n is EMagicFx.Nakseong:
			return true
	return false


func _toggle_waves() -> void:
	waves.set_on(not waves.enabled)
	_wave_btn.text = "적 물결: 켜짐" if waves.enabled else "적 물결: 꺼짐"


## 봉공 진화 켜기/끄기 (1장 무구를 거둔 상태 시험)
func _toggle_still() -> void:
	eska.still_evolved = not eska.still_evolved
	_still_btn.text = _still_label()


## 시험용: 종언 게이지를 바로 가득 (대마법 시험)
func _fill_gauge() -> void:
	eska.fill_gauge()


func _still_label() -> String:
	return "봉공 진화: 켜짐" if eska.still_evolved else "봉공 진화: 꺼짐"


## 오른쪽 위(나가기 ✕ 왼쪽) 작은 버튼 — 터치·마우스 모두. shift = 옆 줄로 옮기는 양(음수 = 왼쪽). 키보드 포커스는 받지 않음 (Z·X가 눌러 버리지 않게)
func _make_button(text: String, top: float, on_press: Callable, shift := 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	b.offset_left = BTN_RIGHT - BTN_W + shift
	b.offset_right = BTN_RIGHT + shift
	b.offset_top = top
	b.offset_bottom = top + 22.0
	b.add_theme_font_size_override("font_size", 11)
	for st: Array in [["normal", 0.75, 0.5], ["hover", 0.9, 0.9], ["pressed", 0.95, 1.0]]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(EVfx.INK, float(st[1]))
		sb.border_color = Color(EVfx.VIOLET, float(st[2]))
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(4)
		b.add_theme_stylebox_override(String(st[0]), sb)
	b.add_theme_color_override("font_color", EVfx.PALE)
	b.pressed.connect(on_press)
	return b


## 시험 실행기 eval용: 적 하나 놓기
func spawn_foe(kind: String, x: float, y: float) -> String:
	var e := EWaves.spawn(self, kind, Vector2(x, y))
	return "%s hp=%d" % [kind, e.max_hp]


## 시험 실행기 eval용: 굳은 돌 하나 위에 에스카를 올려 놓기 (공간 고정 발판 시험)
func put_on_rock() -> String:
	for n: Node in get_tree().get_nodes_in_group(EStill.GROUP):
		var r := n as Node2D
		if r.position.y > FLOOR - 160.0 and r.position.y < FLOOR - 60.0:
			eska.global_position = r.position + Vector2(0, -EStill.Rock.SIZE.y * 0.5 - 1.0)
			eska.velocity = Vector2.ZERO
			return "rock x=%d y=%d" % [int(r.position.x), int(r.position.y)]
	return "none"


## 시험 실행기 eval용: 살아 있는 적 상태
func foes() -> String:
	var out := ""
	for n: Node in get_children():
		if n is EEnemy:
			var e := n as EEnemy
			out += "%s(x=%d hp=%d st=%d still=%.2f) " % [e.get_script().get_global_name(), int(e.global_position.x), e.hp, int(e.get("st")), float(e.get("_bound"))]
	return out


## 시험 구역 표시: 높은 턱(돌 난간) + 안내 글씨 (떨어지는 돌 기둥보다 왼쪽에서 끝나게 — 글이 돌에 가려 잘리지 않게, 입력 방식에 맞춰 다시 그림)
class ShelfMark extends Node2D:
	const TEXT_X := -245.0 ## 턱 왼쪽 끝 기준 글 시작 (905 — 터치 카메라 여유로 오른쪽 끝에 붙어도 화면 안, 돌 기둥 1040보다 왼쪽에서 끝남)
	const TEXT_W := 125.0 ## 글이 들어갈 너비 (넘으면 글자를 줄임)
	var shelf: Rect2
	var pd := PDraw.new()
	var _mode := false

	func _ready() -> void:
		z_index = -1

	func _process(_delta: float) -> void:
		if _mode != EKeys.touch_mode:
			_mode = EKeys.touch_mode
			queue_redraw()

	func _draw() -> void:
		pd.draw_rect(shelf, Color("#241d2c"))
		pd.draw_rect(Rect2(shelf.position, Vector2(shelf.size.x, 3)), Color("#6b5c80"))
		pd.draw_line(shelf.position + Vector2(0, 3), shelf.position + Vector2(shelf.size.x, 3), Color(EVfx.VIOLET, 0.6), 1.0)
		pd.flush(self)
		var f := ThemeDB.fallback_font
		var at := Vector2(shelf.position.x + TEXT_X, shelf.position.y + 50.0) # 돌 기둥 왼쪽
		var ls: Array[String] = ["떨어지는 돌을 봉공으로", "굳혀 밟고 턱에 오르기 →"]
		if EKeys.touch_mode:
			ls.append_array(["순환 버튼으로 봉공 고르기", "위 '게이지 가득' 누르기"])
		else:
			ls.append_array(["%s 봉공 고르기 · %s 쓰기" % [EKeys.label("es_ult_next"), EKeys.label("es_bind")], "G 게이지 채우기"])
		for i in ls.size():
			var fs := 11 if i < 2 else 10
			while fs > 8 and f.get_string_size(ls[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > TEXT_W:
				fs -= 1
			draw_string(f, at + Vector2(0, 14.0 * float(i)), ls[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(EVfx.PALE, 0.8 if i < 2 else 0.6))

	## 안내판 가운데 가로 위치 (가까이 가면 진해짐)
	func sign_x() -> float:
		return shelf.position.x + TEXT_X + TEXT_W * 0.5


## 틈 달이기 안내판 (가마솥 위): 작은 틈 그림 + 가운데 맞춘 안내 글씨. 입력 방식이 바뀌면 다시 그림
class RiftSign extends Node2D:
	const LINE_H := 14.0
	var at := Vector2.ZERO ## 첫 줄 가운데 위
	var pd := PDraw.new()
	var _mode := false

	func _ready() -> void:
		z_index = -1

	func _process(_delta: float) -> void:
		if _mode != EKeys.touch_mode:
			_mode = EKeys.touch_mode
			queue_redraw()

	func sign_x() -> float:
		return at.x

	func lines() -> Array[String]:
		return ["틈 달이기", "천열(%s)로 찢은 틈이 열려 있을 때" % EKeys.label("es_skill"),
			("%s 버튼으로 던져 넣으면" if EKeys.touch_mode else "%s로 물약을 던져 넣으면") % EKeys.with_dir("es_down", "es_potion"), "진하게 스며들어 강자에게도 다 걸린다"]

	func _draw() -> void:
		var f := ThemeDB.fallback_font
		var ls := lines()
		var w := 0.0
		for s in ls:
			w = maxf(w, f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x)
		# 왼쪽 작은 틈: 검은 무 + 마젠타 테 + 흰 금 (안내하는 대상을 그림으로)
		var c := at + Vector2(-w * 0.5 - 14.0, 26)
		var tear := PackedVector2Array([c + Vector2(0, -16), c + Vector2(3, -6), c + Vector2(2, 4), c + Vector2(0, 16), c + Vector2(-2, 5), c + Vector2(-3, -7)])
		pd.glow(c, 18.0, Color(EVfx.MAGENTA, 0.18), 0.0)
		pd.outlined(tear, EVfx.VOID, EVfx.MAGENTA, 1.0)
		pd.draw_line(c + Vector2(0, -11), c + Vector2(0, 11), Color(EVfx.EDGE, 0.8), 1.0)
		pd.flush(self)
		for i in ls.size():
			var fs := 12 if i == 0 else 11
			var lw := f.get_string_size(ls[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var col := Color(EVfx.EDGE, 0.85) if i == 0 else Color(EVfx.PALE, 0.75)
			draw_string(f, at + Vector2(-lw * 0.5, LINE_H * float(i) + 11.0), ls[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


## 연습용 망령: 제자리(home) 둘레에 떠서, 가까이(RANGE) 오면 천천히 조준해 느린 구슬을 쏜다 (단공 딱 맞춤 연습 — 맞으면 체력 1, 실전처럼)
class PracticeWisp extends ECaster:
	const RANGE := 280.0 ## 이 거리 안에 들어오면 쏜다 (부활 자리·가마솥에서는 안 쏨)
	const COOL := 3.2 ## 다음 구슬까지
	const ORB_SLOW := 90.0 ## 구슬 빠르기 (보통 망령 150)
	const DRIFT := Vector2(10.0, 8.0) ## 제자리 둘레 흔들림
	var home := Vector2.ZERO

	func _think(delta: float) -> void:
		st_t += delta
		_cool = maxf(_cool - delta, 0.0)
		var want := home + Vector2(sin(t * 0.8) * DRIFT.x, sin(t * 1.3) * DRIFT.y)
		velocity = velocity.move_toward((want - global_position) * 2.0, 200.0 * delta)
		if not eska_ok():
			return
		var ec := eska.center()
		facing = toward_eska()
		match st:
			S.FLOAT:
				if _cool <= 0.0 and global_position.distance_to(ec) < RANGE:
					st = S.AIM
					st_t = 0.0
					_aim = ec
					Sfx.play_pitch(&"sniper_aim", 1.0, -12.0)
			S.AIM:
				if st_t < AIM_T - LOCK_T:
					_aim = _aim.lerp(ec, 1.0 - exp(-delta * 12.0))
				if st_t >= AIM_T:
					_shoot()
					st = S.FLOAT
					st_t = 0.0
					_cool = COOL

	func _shoot() -> void:
		var o := ECaster.Orb.new()
		var from := core()
		o.vel = (_aim - from).normalized() * ORB_SLOW
		o.position = from
		Fx.effect_parent().add_child(o)
		Sfx.play_pitch(&"sniper_shot", 1.1, -10.0)


## "마녀의 연습 과제" 5줄 (오른쪽 위, 시험 버튼 아래 — 터치에서도 보임). 해내면 체크가 그어지고(튜토리얼 안내 칸과 같은 체크) 글이 옅어짐
class PracticeList extends Control:
	const T_NAKSEONG := 0
	const T_PERFECT := 1
	const T_BREW := 2
	const T_RIFT := 3
	const T_ULT := 4
	const W := 168.0 ## 칸 너비
	const TOP := 58.0 ## 시험 버튼(아래 끝 56) 바로 아래
	const RIGHT := 12.0
	const FS := 10 ## 글자 크기 (줄 간격은 글꼴 높이)
	const TICK_T := 0.25 ## 체크가 그어지는 시간
	const OPEN_T := 3.0 ## 체크되면 이만큼 펼쳐 보임
	const HEAD_W := 112.0 ## 접힌 한 줄의 너비
	const TAP_GAP := 0.3 ## 누름 한 번이 터치와 흉내 마우스로 두 번 들어와도 한 번만 열고 닫게
	var hud: EHud
	var pinned := false ## 눌러서 펼쳐 둠
	var _open_t := 0.0 ## 체크 뒤 펼쳐 둘 남은 시간
	var _tap_t := 9.0
	var done: Array[bool] = [false, false, false, false, false]
	var _since: Array[float] = [9.0, 9.0, 9.0, 9.0, 9.0]
	var _sig := ""

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	## 과제 i를 해냄 (처음 한 번만 소리)
	func mark(i: int) -> void:
		if done[i]:
			return
		done[i] = true
		_since[i] = 0.0
		_open_t = OPEN_T
		Sfx.play(&"checkpoint", -6.0)
		if not done.has(false) and is_instance_valid(hud):
			hud.banner("연습 과제 완료", "마녀의 손이 풀렸다", 1.8)

	func count() -> int:
		return done.count(true)

	func is_open() -> bool:
		return pinned or _open_t > 0.0

	## 접힌 줄(머리) 자리 — 누르면 펼침/접음
	func head_rect() -> Rect2:
		return Rect2(size.x - RIGHT - HEAD_W, TOP, HEAD_W, 16.0)

	func toggle() -> void:
		pinned = not is_open()
		_open_t = 0.0
		Sfx.play(&"ui_move", -8.0)

	func _input(event: InputEvent) -> void:
		if not visible:
			return
		var pos := Vector2(-1, -1)
		if event is InputEventScreenTouch and event.pressed:
			pos = event.position
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			pos = event.position
		if pos.x < 0.0 or not head_rect().grow(4.0).has_point(pos) or _tap_t < TAP_GAP:
			return
		_tap_t = 0.0
		toggle()
		get_viewport().set_input_as_handled()

	func texts() -> Array[String]:
		return ["%s 낙성으로 공중 표적" % EKeys.with_dir("es_down", "es_skill"), "%s 단공 딱 맞춤" % EKeys.with_dir("es_up", "es_skill"),
			"가마솥에서 새 물약 달이기", "틈 달이기 (열린 틈에 물약)", "대마법 쓰기" if EKeys.touch_mode else "%s 대마법 쓰기" % EKeys.label("es_bind")]

	func _process(delta: float) -> void:
		size = get_viewport_rect().size
		visible = not (is_instance_valid(hud) and hud.cinematic)
		_tap_t += delta
		_open_t = maxf(_open_t - delta, 0.0)
		var sig := "%s|%s|%s|%s" % [str(done), str(EKeys.touch_mode), str(size), str(is_open())]
		for i in _since.size():
			if _since[i] < TICK_T + 0.5:
				_since[i] += delta
				sig += "|%.2f" % _since[i]
		if sig != _sig:
			_sig = sig
			queue_redraw()

	## 그리기 호출을 줄이려고 같은 색 글은 여러 줄 글 하나로, 네모·체크는 선 묶음 하나로 그린다
	func _draw() -> void:
		var f := get_theme_default_font()
		if not is_open():
			_draw_head(f)
			return
		var x := size.x - RIGHT - W
		var ts := texts()
		var lh := f.get_height(FS)
		var h := 8.0 + lh * float(ts.size() + 1)
		draw_rect(Rect2(x, TOP, W, h), Color(EVfx.INK, 0.72))
		draw_rect(Rect2(x, TOP, W, h), Color(EVfx.VIOLET, 0.35), false, 1.0)
		var base := Vector2(x + 6.0, TOP + 3.0 + f.get_ascent(FS))
		draw_string(f, base, "마녀의 연습 과제 %d/%d" % [count(), ts.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, FS, Color(EVfx.EDGE, 0.9))
		var tc := Vector2(x + W - 9.0, TOP + 9.0) # 그린 ▾ (누르면 접힘)
		draw_colored_polygon(PackedVector2Array([tc + Vector2(-4.0, -2.5), tc + Vector2(4.0, -2.5), tc + Vector2(0.0, 3.0)]), Color(EVfx.PALE, 0.85))
		var todo := PackedStringArray([""])
		var got := PackedStringArray([""])
		var boxes := PackedVector2Array()
		var ticks := PackedVector2Array()
		for i in ts.size():
			todo.append("" if done[i] else ts[i])
			got.append(ts[i] if done[i] else "")
			var b := Rect2(x + 7.0, TOP + 3.0 + lh * float(i + 1) + (lh - 7.0) * 0.5, 7.0, 7.0)
			boxes.append_array([b.position, Vector2(b.end.x, b.position.y), Vector2(b.end.x, b.position.y), b.end, b.end, Vector2(b.position.x, b.end.y), Vector2(b.position.x, b.end.y), b.position])
			if done[i]:
				# 체크 표시가 그어짐 (ETutHud 안내 칸의 체크와 같은 획)
				var k := clampf(_since[i] / TICK_T, 0.0, 1.0)
				var c0 := b.position + Vector2(0.5, 3.0)
				var c1 := c0 + Vector2(2.5, 3.0)
				var c2 := c1 + Vector2(6.0, -8.0)
				ticks.append_array([c0, c0.lerp(c1, minf(k * 2.0, 1.0))])
				if k > 0.5:
					ticks.append_array([c1, c1.lerp(c2, (k - 0.5) * 2.0)])
		draw_multiline(boxes, Color(EVfx.PALE, 0.6), 1.0)
		var tp := Vector2(x + 19.0, base.y)
		draw_multiline_string(f, tp, "\n".join(todo), HORIZONTAL_ALIGNMENT_LEFT, -1, FS, -1, Color(EVfx.PALE, 0.85))
		if done.has(true):
			draw_multiline_string(f, tp, "\n".join(got), HORIZONTAL_ALIGNMENT_LEFT, -1, FS, -1, Color(EVfx.PALE, 0.45))
		if not ticks.is_empty():
			draw_multiline(ticks, Color(EVfx.MAGENTA.lerp(EVfx.EDGE, 0.5), 1.0), 2.0)

	## 접힌 한 줄: "연습 과제 n/5" + 그린 ▸ (웹 글꼴에 없을 수 있어 글자로 쓰지 않음)
	func _draw_head(f: Font) -> void:
		var r := head_rect()
		draw_rect(r, Color(EVfx.INK, 0.72))
		draw_rect(r, Color(EVfx.VIOLET, 0.35), false, 1.0)
		draw_string(f, r.position + Vector2(6.0, 3.0 + f.get_ascent(FS)), "연습 과제 %d/%d" % [count(), done.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, FS, Color(EVfx.EDGE, 0.9))
		var c := Vector2(r.end.x - 9.0, r.get_center().y)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-2.5, -4.0), c + Vector2(3.0, 0.0), c + Vector2(-2.5, 4.0)]), Color(EVfx.PALE, 0.85))
