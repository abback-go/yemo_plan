class_name PilgrimShade
extends EnemyBase
## 순례자의 그림자 (docs/chapter4.md 4절·7.4절): 성산을 오르다 길을 잃고 흰빛(바깥 신들의 색)에 물든 순례자. 느리고, 등불을 든 채
## 중얼거리며("…빛이… 보이지 않아…") 다가와 붙잡으려 한다.
## - 붙잡기: 팔을 뻗음(0.7초 예고 — 손이 붉게) → 짧게 덮침(1 피해) → 1초 동안 웅크려 흐느낌(빈틈).
## - 쓰러뜨리면 터지지 않는다: 흰빛이 걷히고 따뜻한 빛깔로 돌아와 고개 숙여 "고맙다…" 하고 금빛으로 흩어진다.
##   free_flag(방 데이터)가 있으면 그 플래그를 세움, line(방 데이터)이 있으면 그 말을 함(성가대원 찾기 등).

enum S { WANDER, REACH, GRAB, SOB, FREED }

const H := preload("res://enemies/ch4/holy.gd")
const VIS := preload("res://enemies/ch4/pilgrim_shade_visual.gd")

const HP := 600
const WALK_T := 1.2
const REACH_T := 2.4
const REACH_TIME := 0.7
const GRAB_TIME := 0.28
const GRAB_SPEED_T := 9.0
const SOB_TIME := 1.0
const FREED_TIME := 2.2
const MURMURS: Array[String] = ["…빛이… 보이지 않아…", "…정상은… 어디…", "…추워…", "…주여… 어디 계십니까…"]
const THANKS: Array[String] = ["…고맙다. 이제 길이 보이는구나.", "…아, 따뜻해… 고맙다, 아이야.", "…빛이… 돌아왔어. 고맙다.", "…어머니께 가야지. 고맙다."]

var state: S = S.WANDER
var free_flag := ""
var line := ""
var look := 0 ## 옷 모양 (그림)
var freed_k := 0.0 ## 풀려나는 진행도 (그림)
var _clock := StateClock.new() ## 상태 시간 (남은 시간·길이·진행도)
var _say_t := 3.0
var _grab: EnemyAttackArea
var _freed_done := false


func _build() -> void:
	max_hp = HP
	body_size = Vector2(16, 30)
	knock_mult = 0.8
	launch_mult = 0.8
	display_name = "순례자의 그림자"
	subtitle = "길을 잃은 자"
	kind_id = "pilgrim_shade"
	look = randi() % 3
	var v: Node2D = VIS.new()
	v.set("enemy", self)
	_visual = v
	add_child(v)
	var c := add_attack_area(Vector2(12, 24), Vector2(0, -13), &"pilgrim_shade")
	c.dodgeable = false
	_grab = add_attack_area(Vector2(20, 18), Vector2(12, -16), &"pilgrim_shade")
	_grab.active = false


func progress() -> float:
	return _clock.k()


func _go(s: S, time := 0.0) -> void:
	state = s
	_clock.enter(time)


func _ai(delta: float) -> void:
	var t := GameConst.TILE
	var cs := _grab.get_child(0) as CollisionShape2D
	cs.position = Vector2(12 * facing, -16)
	_clock.tick(delta)
	var p := player()
	if state == S.FREED:
		velocity.x = 0.0
		return
	_say_t -= delta
	if _say_t <= 0.0 and engaged and p and global_position.distance_to(p.global_position) < 10.0 * t:
		_say_t = randf_range(5.0, 8.0)
		_float_text(MURMURS[randi() % MURMURS.size()], Color(0.85, 0.88, 1.0, 0.85))
	if not engaged or p == null or not p.is_alive():
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
		return
	var dx := p.global_position.x - global_position.x
	match state:
		S.WANDER:
			facing = 1 if dx >= 0.0 else -1
			var want := facing * WALK_T * t if absf(dx) > 1.5 * t and not ledge_ahead(10.0, 16.0) else 0.0
			velocity.x = move_toward(velocity.x, want, 300.0 * delta)
			if absf(dx) < REACH_T * t and absf(p.global_position.y - global_position.y) < 2.5 * t and _clock.done():
				_go(S.REACH, Difficulty.telegraph(REACH_TIME))
				velocity.x = 0.0
				H.snd(&"growl", &"growl", -10.0)
		S.REACH:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if _clock.done():
				_go(S.GRAB, GRAB_TIME)
				_grab.active = true
				H.snd(&"whoosh", &"whoosh", -6.0)
		S.GRAB:
			velocity.x = facing * GRAB_SPEED_T * t
			if _clock.done() or is_on_wall() or ledge_ahead(10.0, 16.0):
				_grab.active = false
				_go(S.SOB, SOB_TIME)
		S.SOB:
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			if _clock.done():
				_go(S.WANDER, Difficulty.rest(0.8))


func _float_text(text: String, col: Color) -> void:
	var l := Label.new()
	l.text = text
	var ls := LabelSettings.new()
	ls.font_size = 10
	ls.font_color = col
	ls.outline_size = 3
	ls.outline_color = Color("#10101c")
	l.label_settings = ls
	l.position = global_position + Vector2(-40, -body_size.y - 20)
	l.z_index = 20
	Fx.effect_parent().add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 10.0, 2.2).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.6).set_delay(1.8)
	tw.tween_callback(l.queue_free)


## 쓰러짐: 터지지 않고 풀려난다
func _die(_dir: int) -> void:
	if _freed_done:
		return
	_freed_done = true
	_alive = false
	_record_defeat()
	GameState.add("tp_shades_freed")
	defeated.emit(self)
	_go(S.FREED, FREED_TIME)
	velocity = Vector2.ZERO
	_disable_body()
	if free_flag != "":
		GameState.set_flag(free_flag)
	H.snd(&"reveal", &"reveal", -2.0)
	Fx.ring(global_position + Vector2(0, -16), 4.0, 30.0, H.GOLD, 0.5, 2.0)
	var say := line if line != "" else THANKS[randi() % THANKS.size()]
	var tw := create_tween()
	tw.tween_property(self, "freed_k", 1.0, 0.8)
	tw.tween_callback(func() -> void: _float_text(say, Color(1.0, 0.92, 0.7)))
	tw.tween_interval(1.0)
	tw.tween_callback(func() -> void: H.sparkle(global_position + Vector2(0, -16), 26, 8.0, 50.0, 1.2))
	if _visual:
		tw.tween_property(_visual, "modulate:a", 0.0, 0.8)
	tw.tween_callback(queue_free)


func _physics_process(delta: float) -> void:
	super(delta)
	if state == S.FREED and _visual:
		_visual.queue_redraw()
