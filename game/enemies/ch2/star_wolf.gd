extends EnemyBase
## 성흔 늑대 (docs/chapter2.md 4절, 정예) — 몸에 별자리 낙인(성흔)이 박힌 검은 늑대. 빠르다.
## 패턴:
##   울부짖기: 앉아 고개를 젖히고(0.6초) → 세라 발밑에 붉은 원(0.9초) → 별기둥이 솟는 순간 그 자리로 덮쳐 듦(도약)
##            체력 절반 아래에선 별기둥 셋이 세라를 따라간다.
##   돌진 물기: 낮게 웅크림(0.45초, 눈이 붉게) → 땅을 따라 8칸 질주(퍼펙트 회피 가능) → 미끄러지며 멈춤(0.6초 빈틈)
##   물러서기: 세라가 너무 가까우면 뒤로 껑충 → 거리를 두고 다시 노린다.
## 빈틈: 덮친 뒤 착지 0.7초, 돌진 뒤 미끄럼 0.6초.

const KE := preload("res://enemies/ch2/k_enemy.gd")
const KArt := preload("res://world/entities/ch2/k_art.gd")

enum S { PROWL, HOWL, POUNCE_WAIT, POUNCE, LAND, CROUCH, DASH, SKID, HOP }

const HP := 1500
const RUN_T := 6.0
const KEEP_MIN_T := 4.0
const KEEP_MAX_T := 8.0
const PROWL_TIME := Vector2(0.9, 1.5)
const HOWL_TIME := 0.6
const PILLAR_WARN := 0.9
const POUNCE_TIME := 0.5
const LAND_TIME := 0.7
const CROUCH_TIME := 0.45
const DASH_SPEED_T := 17.0
const DASH_MAX_T := 9.0
const SKID_TIME := 0.6
const HOP_TIME := 0.4
const FUR := Color("#1c1a2a")
const FUR_L := Color("#3a3654")
const FUR_D := Color("#0c0a14")
const STIG := Color("#c89aff")

var state: S = S.PROWL
var _clock := StateClock.new() ## 상태 시간 (남은 시간·길이·진행도)
var _pounce_to := Vector2.ZERO
var _pounce_from := Vector2.ZERO
var _dash_start := 0.0
var _pillars_left := 0
var _pillar_t := 0.0
var _last := ""
var _run_phase := 0.0
var _contact: EnemyAttackArea
var _bite: EnemyAttackArea


func _build() -> void:
	max_hp = HP
	body_size = Vector2(30, 18)
	knock_mult = 0.3
	launch_mult = 0.3
	is_elite = true
	display_name = "성흔 늑대"
	subtitle = "별이 새겨진 사냥꾼"
	kind_id = "star_wolf"
	var v := KE.Vis.new()
	v.enemy = self
	v.fn = _draw_body
	_visual = v
	add_child(v)
	_contact = add_attack_area(Vector2(26, 14), Vector2(0, -9), &"star_wolf", 1)
	_contact.dodgeable = false
	_bite = add_attack_area(Vector2(18, 16), Vector2(16, -10), &"star_wolf", 1)
	_bite.active = false


func _ready() -> void:
	super()
	_enter(S.PROWL, 0.8)


func _enter(s: S, d: float) -> void:
	state = s
	_clock.enter(d)


func progress() -> float:
	return _clock.k()


func _ai(delta: float) -> void:
	var t := GameConst.TILE
	_clock.tick(delta)
	place_area(_bite, Vector2(16, -10))
	var p := player()
	if not engaged or p == null or not p.is_alive():
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		return
	var dx := p.global_position.x - global_position.x
	var adx := absf(dx)
	if absf(velocity.x) > 10.0:
		_run_phase += delta * absf(velocity.x) / 14.0
	# 따라오는 별기둥 (체력 절반 아래 울부짖기)
	if _pillars_left > 0:
		_pillar_t -= delta
		if _pillar_t <= 0.0:
			_pillars_left -= 1
			_pillar_t = 0.45
			KE.pillar(Vector2(p.global_position.x, KE.floor_at(self, p.global_position.x, p.global_position.y)), Difficulty.telegraph(PILLAR_WARN), 22.0, 110.0)
	match state:
		S.PROWL:
			face_player()
			var want := 0.0
			if adx > KEEP_MAX_T * t:
				want = signf(dx) * RUN_T * t
			elif adx < KEEP_MIN_T * t:
				want = -signf(dx) * RUN_T * 0.7 * t
			velocity.x = move_toward(velocity.x, want, 900.0 * delta)
			if adx < 2.2 * t and is_on_floor() and _clock.left < 0.5:
				_hop_back()
			elif _clock.done() and is_on_floor():
				_choose()
		S.HOWL:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _clock.done():
				var fx := p.global_position.x
				_pounce_to = Vector2(fx, KE.floor_at(self, fx, p.global_position.y))
				var warn := Difficulty.telegraph(PILLAR_WARN)
				KE.pillar(_pounce_to, warn, 24.0, 120.0)
				if hp * 2 <= max_hp:
					_pillars_left = 2
					_pillar_t = 0.45
				_enter(S.POUNCE_WAIT, warn - 0.12)
		S.POUNCE_WAIT:
			velocity.x = 0.0
			face_player()
			if _clock.done():
				_start_pounce()
		S.POUNCE:
			if is_on_floor() and _clock.dur - _clock.left > 0.1:
				_land()
			elif _clock.left < -1.0:
				_land()
		S.LAND:
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
			if _clock.done():
				_enter(S.PROWL, randf_range(PROWL_TIME.x, PROWL_TIME.y))
		S.CROUCH:
			velocity.x = 0.0
			if _clock.done():
				_enter(S.DASH, 0.0)
				_dash_start = global_position.x
				_bite.active = true
				_bite.dodgeable = true
				KE.snd(&"charger_charge", &"charger_charge", 0.0)
				KE.snd(&"growl", &"growl", -4.0)
		S.DASH:
			velocity.x = facing * DASH_SPEED_T * t
			_contact.dodgeable = true
			if int(_t * 25.0) % 2 == 0:
				KE.star_burst(global_position + Vector2(-facing * 12.0, -10), 2, STIG, 40.0, 0.3)
			if absf(global_position.x - _dash_start) > DASH_MAX_T * t or is_on_wall() or ledge_ahead(16.0):
				_bite.active = false
				_contact.dodgeable = false
				_enter(S.SKID, Difficulty.rest(SKID_TIME))
				KE.snd(&"land", &"land", -2.0)
		S.SKID:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if int(_t * 30.0) % 2 == 0 and absf(velocity.x) > 20.0:
				KE.debris(global_position + Vector2(facing * 8.0, 0), 2, Color("#7a7490"), Vector2(-facing, -1), 60.0)
			if _clock.done():
				_enter(S.PROWL, randf_range(PROWL_TIME.x, PROWL_TIME.y))
		S.HOP:
			if is_on_floor() and _clock.dur - _clock.left > 0.1:
				_enter(S.PROWL, 0.3)


func _choose() -> void:
	var p := player()
	face_player()
	var adx := absf(p.global_position.x - global_position.x) / GameConst.TILE
	var pick := "howl" if adx > 6.0 else "dash"
	if pick == _last and randf() < 0.6:
		pick = "dash" if pick == "howl" else "howl"
	_last = pick
	if pick == "howl":
		_enter(S.HOWL, Difficulty.telegraph(HOWL_TIME))
		KE.snd(&"roar", &"roar", -6.0, 0.1)
		KE.snd(&"star_twinkle", &"pillar_warn", -4.0)
	else:
		_enter(S.CROUCH, Difficulty.telegraph(CROUCH_TIME))
		KE.snd(&"growl", &"growl", -2.0, 0.1)


func _start_pounce() -> void:
	_enter(S.POUNCE, POUNCE_TIME)
	_pounce_from = global_position
	var dx := clampf(_pounce_to.x - global_position.x, -12.0 * GameConst.TILE, 12.0 * GameConst.TILE)
	facing = 1 if dx >= 0.0 else -1
	velocity.y = -0.5 * _gravity * POUNCE_TIME
	velocity.x = dx / POUNCE_TIME
	_bite.active = true
	_bite.dodgeable = true
	_contact.dodgeable = true
	KE.snd(&"whoosh", &"whoosh", 0.0)


func _land() -> void:
	_bite.active = false
	_contact.dodgeable = false
	velocity.x = 0.0
	_enter(S.LAND, Difficulty.rest(LAND_TIME))
	Fx.shake(0.15, 0.15)
	KE.snd(&"land", &"land", 0.0)
	KE.debris(global_position, 8, Color("#7a7490"), Vector2.UP, 100.0)


func _hop_back() -> void:
	_enter(S.HOP, HOP_TIME)
	face_player()
	velocity.y = -260.0
	velocity.x = -facing * 140.0
	KE.snd(&"jump", &"jump", -6.0)


func _resists_knockback(hit: Hit) -> bool:
	return state in [S.DASH, S.POUNCE] and not hit.breaks_charge


func _on_hit(hit: Hit, _dir: int) -> void:
	if state == S.DASH and hit.breaks_charge:
		_bite.active = false
		_enter(S.SKID, SKID_TIME)


func _die(dir: int) -> void:
	_pillars_left = 0
	KE.death_fx(global_position + Vector2(0, -10), STIG, true)
	super(dir)


# ─── 그림 ───────────────────────────────────────────────

func _draw_body(c: Node2D) -> void:
	var white := flash_amount() > 0.0
	var fur := Color.WHITE if white else FUR
	var fur_l := Color.WHITE if white else FUR_L
	var fur_d := Color(0.85, 0.85, 0.9) if white else FUR_D
	var k := progress()
	var run := sin(_run_phase)
	var body_y := -11.0
	var head_up := 0.0
	var crouch := 0.0
	var stretch := 0.0
	var eye_red := false
	match state:
		S.HOWL:
			head_up = k
			crouch = 2.0 * k
		S.POUNCE_WAIT:
			head_up = 0.3
			crouch = 3.0
			eye_red = true
		S.POUNCE:
			stretch = 1.0
		S.CROUCH:
			crouch = 4.0 * k
			eye_red = true
		S.DASH:
			stretch = 1.0
			eye_red = true
		S.SKID, S.LAND:
			crouch = 2.0
	body_y += crouch
	var o := Vector2(0, body_y)
	var leg_len := 9.0 - crouch * 0.8
	# 꼬리 (별빛 끝)
	var tail_base := o + Vector2(-12, -2)
	var tail_tip := tail_base + Vector2(-9 - stretch * 4.0, -4 + sin(_t * 6.0) * 2.0 + stretch * 4.0)
	c.draw_line(tail_base, tail_tip, KE.OUT, 5.0)
	c.draw_line(tail_base, tail_tip, fur, 3.0)
	if not white:
		KArt.star4(c, tail_tip, 2.0, Color(STIG, 0.8))
	# 다리 (뒤 둘)
	for i in 4:
		var front := i >= 2
		var lx := (7.0 if front else -8.0) + (2.0 if i % 2 == 1 else 0.0)
		var ph := run + (PI if i % 2 == 1 else 0.0) + (0.5 if front else 0.0)
		var swing := sin(ph) * 4.0 if absf(velocity.x) > 10.0 else 0.0
		if stretch > 0.0:
			swing = 6.0 if front else -6.0
		var col := fur_d if i % 2 == 0 else fur
		var hip := o + Vector2(lx, 2)
		var foot := Vector2(lx + swing, 0)
		if state == S.HOWL and not front:
			foot = Vector2(lx - 2, 0)
		c.draw_line(hip, foot + Vector2(0, -1), KE.OUT, 4.0)
		c.draw_line(hip, foot + Vector2(0, -1), col, 2.4)
		c.draw_rect(Rect2(foot + Vector2(-1, -2), Vector2(3, 2)), col)
	# 몸통 (길쭉, 갈기 털)
	var body := PackedVector2Array([o + Vector2(-13, 0), o + Vector2(-11, -5), o + Vector2(0, -6 - head_up), o + Vector2(10, -5 - head_up * 2.0), o + Vector2(12, 1), o + Vector2(2, 4), o + Vector2(-10, 4)])
	var outline := PackedVector2Array()
	for pnt in body:
		outline.append(pnt + (pnt - o).normalized() * 1.0)
	c.draw_colored_polygon(outline, KE.OUT)
	c.draw_colored_polygon(body, fur)
	c.draw_line(o + Vector2(-10, -4), o + Vector2(8, -5 - head_up * 2.0), fur_l, 1.0)
	# 갈기 털 뾰족뾰족
	for i in 4:
		var mx := 2.0 + i * 2.5
		c.draw_colored_polygon(PackedVector2Array([o + Vector2(mx - 1.5, -5 - head_up * 1.5), o + Vector2(mx, -9 - head_up * 2.0), o + Vector2(mx + 1.5, -5 - head_up * 1.5)]), fur)
	# 성흔: 몸의 별자리 (맥동)
	if not white:
		var pul := 0.6 + 0.4 * sin(_t * 4.0)
		if state in [S.HOWL, S.POUNCE_WAIT]:
			pul = 1.0
		var stars := [o + Vector2(-8, -2), o + Vector2(-4, -3), o + Vector2(0, -1), o + Vector2(4, -3), o + Vector2(-2, 1)]
		for i in stars.size() - 1:
			c.draw_line(stars[i], stars[i + 1], Color(STIG, 0.45 * pul), 1.0)
		for sp in stars:
			KArt.star4(c, sp, 1.6, Color(STIG.lightened(0.3), pul))
		KArt.glow(c, o + Vector2(-2, -2), 14.0, Color(STIG, 0.35 * pul), 2)
	# 머리 (주둥이 길게, 울부짖을 땐 위로)
	var ha := -head_up * 0.9
	var hc := o + Vector2(12, -6 - head_up * 3.0)
	var snout := hc + Vector2(cos(ha), sin(ha)) * 7.0
	var head := PackedVector2Array([hc + Vector2(-3, -3), hc + Vector2(2, -4).rotated(ha), snout + Vector2(0, -1).rotated(ha), snout + Vector2(0, 2).rotated(ha), hc + Vector2(-1, 4)])
	c.draw_colored_polygon(head, fur)
	c.draw_polyline(head + PackedVector2Array([head[0]]), KE.OUT, 1.0)
	# 귀
	c.draw_colored_polygon(PackedVector2Array([hc + Vector2(-2, -3), hc + Vector2(-3, -9), hc + Vector2(1, -4)]), fur)
	# 눈 (예고 땐 붉게)
	var eye := KE.DANGER if eye_red else Color(STIG.lightened(0.4))
	c.draw_rect(Rect2(hc + Vector2(1, -2).rotated(ha), Vector2(2, 1.2)), Color.WHITE if white else eye)
	if not white and eye_red:
		c.draw_circle(hc + Vector2(2, -1.5).rotated(ha), 3.0, Color(KE.DANGER, 0.35))
	# 벌린 입 (울부짖기·물기)
	if state in [S.HOWL, S.DASH, S.POUNCE]:
		c.draw_line(snout + Vector2(-3, 1).rotated(ha), snout + Vector2(0, 2).rotated(ha), Color("#ffe0ff") if not white else Color.WHITE, 1.0)
	# 울부짖을 때 별빛 음파
	if state == S.HOWL and not white:
		for i in 3:
			var rr := 6.0 + fmod(_t * 30.0 + i * 6.0, 18.0)
			c.draw_arc(snout, rr, ha - 0.6, ha + 0.6, 6, Color(STIG, 0.6 * (1.0 - rr / 24.0)), 1.0)
