extends "res://story/ch5/common.gd"
## 5장 대본 — 11~12. 반격·거신 · 하늘의 문(최종전).
## 메서드 이름 = 실행 ID (docs/dev/story.md). 장 공용 상수·도우미는 common.gd.


# ═══════════════════════════════════════════════════════════
# 11. 반격 — 다시 일어서는 사람들, 거신 위를 달려
# ═══════════════════════════════════════════════════════════

func enter_r5_courtyard_rise(c: Cut) -> void:
	_ensure_fox(c)
	if c.has("st_rise"):
		for k in TRIAL_ALLIES:
			c.ensure_ally(k)
		return
	c.lock()
	c.hud(false)
	await c.fade_out(0.01)
	c.music("nine_tails")
	c.letterbox(true)
	c.player_face(1)
	_ensure_fox(c)
	await c.wait(0.4)
	await c.fade_in(2.0)
	c.sfx("fox_storm", 4.0)
	c.flash(Color(0.6, 0.85, 1.0, 0.6), 0.6)
	Fx.ring(c.player.center(), 8.0, 260.0, StArt.FOX_BLUE, 1.2, 5.0)
	await c.wait(0.8)
	await c.narrate("푸른 불이 무너진 앞마당을 따라 번져 나갔다. 거신들의 발이 — 멈칫, 하고 느려졌다.")
	c.close_box()
	c.spawn_npc("pippa", 34.0, 19.0, 1)
	await c.say("pippa", "세라…? 너, 꼬리가… 아홉 개야…", "surprised")
	await c.say("sera", "피피. 괜찮아?")
	await c.say("pippa", "다리 좀 다쳤어. 근데 물약은 아직 있어! 마셔, 전부!", "happy")
	c.close_box()
	GameState.heal_full()
	c.player.restore_from_state()
	c.give_potions(maxi(GameState.potions_max, 3))
	c.spawn_npc("isolde", 30.0, 19.0, 1)
	c.spawn_npc("emberlyn", 26.0, 19.0, 1)
	await c.say("isolde", "…늦잠 잤어? 바보.", "sad")
	await c.say("emberlyn", "교사들이 학교에 결계를 다시 친다. 학생들은 우리가 지킨다.")
	await c.say("emberlyn", "세라. 너는— 앞만 봐라.", "happy")
	c.close_box()
	# 전이진이 빛난다 — 세 강자
	c.sfx("warp", 4.0)
	c.flash(Color(0.75, 0.6, 1.0, 0.5), 0.5)
	await c.wait(0.4)
	c.spawn_npc("leonie", 55.0, 19.0, -1)
	await c.say("leonie", "세라.")
	await c.say("leonie", "브론이 밤새 두드린 검이다. 이번엔 부러지지 않는다.", "happy")
	c.spawn_npc("elarien", 60.0, 19.0, -1)
	await c.say("elarien", "세계수의 가지로 깎은 활이다. 이건 튕기지 않는다.")
	c.spawn_npc("aurelia", 66.0, 19.0, -1)
	await c.say("aurelia", "루멘이 마지막으로 남긴 빛입니다.")
	await c.say("aurelia", "…이번엔, 저도 혼자 지키지 않겠습니다.")
	c.close_box()
	await c.wait(0.4)
	c.spawn_npc("astrid", 20.0, 19.0, 1)
	c.pose("astrid", "kneel")
	await c.say("astrid", "…세라피나 양. 그 빛, 정말 따뜻하네요.", "tired")
	await c.say("sera", "교장 선생님! 깨어나셨어요?!", "surprised")
	await c.say("astrid", "저에게도 마지막 한 번쯤은 날 수 있는 힘이 남아 있어요.", "tired")
	await c.say("astrid", "가장 큰 거신의 머리 위에서 기다리겠어요. 거기서— 당신을 하늘까지 쏘아 올려 드리죠.", "wink")
	c.close_box()
	if c.actor("astrid"):
		var ap := c.actor_pos("astrid")
		c.burst(ap + Vector2(0, -20), 30, StArt.STAR, {spread = 180.0, speed_min = 40.0, speed_max = 160.0, lifetime = 0.6})
	c.hide_actor("astrid")
	await c.say("neoul", "거신들은 지금 푸른 불에 졸고 있느니라. 그 몸을 밟고 올라가거라!")
	await c.say("sera", "다들— 가자!", "angry")
	c.close_box()
	await c.title_card("반격", "", 1.8)
	for who in ["pippa", "leonie", "elarien", "aurelia", "isolde", "emberlyn"]:
		c.hide_actor(who)
	for k in TRIAL_ALLIES:
		c.ensure_ally(k)
	c.flag("st_rise")
	c.letterbox(false)
	c.hud(true)
	c.music("final")
	c.save_here("wake")
	c.release()


func r5_rise_go(c: Cut) -> void:
	c.flag("st_rise_go")
	c.bubble("오른쪽이니라! 거신들의 발치로!", 2.4)


func enter_st_colossus_1(c: Cut) -> void:
	_ensure_fox(c)
	for k in TRIAL_ALLIES:
		c.ensure_ally(k)
	if c.has("st_c1_clear"):
		return
	if not c.has("st_c1_seen"):
		c.flag("st_c1_seen")
		c.save_here("start")
		c.lock()
		await c.wait(0.3)
		await c.say("leonie", "사도다. 셋.")
		await c.say("elarien", "푸른 불에 약하다. …세라, 네 불이다.")
		await c.say("aurelia", "거신의 발은 우리가 막습니다. 앞으로!")
		c.close_box()
		c.release()
	if not await _wait_clear(c, "outer_seraph"):
		return
	c.flag("st_c1_clear")
	c.sfx("ward", 0.0)
	c.bubble("길이 열렸느니라!", 2.0)


func enter_st_colossus_2(c: Cut) -> void:
	_ensure_fox(c)
	for k in TRIAL_ALLIES:
		c.ensure_ally(k)
	if c.has("st_c2_seen"):
		return
	c.flag("st_c2_seen")
	c.lock()
	await c.wait(0.4)
	await c.say("neoul", "거신의 손바닥에서 팔을 타고 어깨로, 머리로. 그리고 다음 거신의 손으로 건너뛰거라!")
	await c.say("leonie", "우리는 발치에서 사도를 막는다. 올라가라, 세라!")
	c.close_box()
	c.save_here("start")
	c.release()


func enter_st_colossus_3(c: Cut) -> void:
	_ensure_fox(c)
	for k in TRIAL_ALLIES:
		c.ensure_ally(k)
	if c.has("st_c3_seen"):
		return
	c.flag("st_c3_seen")
	c.save_here("start")
	await c.wait(0.4)
	c.bubble("가장 큰 거신이니라. 머리 꼭대기까지!", 2.6)


## 교장이 세라를 하늘로 쏘아 올린다 (가장 큰 거신의 머리, 트리거)
func st_launch(c: Cut) -> void:
	if c.has("st_launch"):
		return
	c.lock()
	c.letterbox(true)
	var p := c.player.global_position
	c.spawn_npc("astrid", p.x / 16.0 + 3.0, p.y / 16.0, -1)
	c.pose("astrid", "special")
	c.burst(p + Vector2(48, -24), 30, StArt.STAR, {spread = 180.0, speed_min = 30.0, speed_max = 120.0, lifetime = 0.6})
	await c.wait(0.5)
	await c.say("astrid", "기다렸어요.", "happy")
	await c.say("astrid", "백 년 동안 결계를 들던 손으로, 이번엔 학생 하나를 하늘로 던져 보죠.", "wink")
	await c.say("sera", "교장 선생님은요?", "sad")
	await c.say("astrid", "저는 여기서 별을 보며 기다리겠어요. 선배가 좋아하던 일이거든요.")
	await c.say("astrid", "…세라피나 양. 선배를— 리라를 부탁해요.", "sad")
	await c.say("sera", "데리고 올게요. 꼭.", "angry")
	c.close_box()
	c.pose("astrid", "cast")
	c.sfx("star_burst", 4.0)
	Fx.ring(c.player.global_position, 6.0, 120.0, StArt.STAR, 0.8, 4.0)
	c.flash(Color(1.0, 0.97, 0.85, 0.7), 0.5)
	c.flag("st_launch")
	for k in TRIAL_ALLIES:
		c.ally_leave(k)
	var tw := c.player.create_tween()
	tw.tween_property(c.player, "global_position", c.player.global_position + Vector2(0, -420), 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	c.sfx("whoosh", 4.0)
	await c.fade_out(1.0, Color(1.0, 0.97, 0.9))
	c.letterbox(false)
	await c.goto_room("st_sky_1", "launch")


func enter_st_sky_1(c: Cut) -> void:
	_ensure_fox(c)
	if c.has("st_sky_seen"):
		return
	c.flag("st_sky_seen")
	c.lock()
	await c.fade_out(0.01, Color(1.0, 0.97, 0.9))
	c.music("final")
	await c.fade_in(1.2)
	await c.say("neoul", "부서진 세계의 조각들이니라. 위로— 문이 보인다!")
	await c.say("sera", "교장 선생님이 깔아 둔 별빛 기둥도 있어. 가자!")
	c.close_box()
	c.save_here("launch")
	c.release()


# ═══════════════════════════════════════════════════════════
# 12. 하늘의 문 — 최종전
# ═══════════════════════════════════════════════════════════

const GATE_ALLY_SPOT := {"leonie": 0, "aurelia": 1, "isolde": 2, "emberlyn": 3, "elarien": 4}


func enter_st_skygate(c: Cut) -> void:
	if c.has("st_gate_done"):
		return
	_ensure_fox(c)
	c.save_here("start")
	if not await _close_arena(c, "st_gate_fight", 3.0):
		return
	c.lock()
	var gate := c.spawn_enemy("sky_gate", 20, 10, "gate")
	if gate == null:
		c.release()
		return
	await c.wait(0.4)
	if not c.has("st_gate_met"):
		c.flag("st_gate_met")
		c.letterbox(true)
		Music.stop(1.0)
		await c.camera_to(gate.global_position, 1.2)
		await c.say("lyra", "…세… 라…. 오지… 마…", "possessed")
		await c.narrate("「그릇. 그릇. 가장 큰 그릇의 문. 열려라. 열려라.」")
		await c.say("sera", "리라는 문이 아니야.", "angry")
		await c.say("sera", "데리러 왔어.", "angry")
		await c.camera_back(0.8)
		c.close_box()
	# 별빛 길을 타고 동료들이 도착한다
	c.sfx("star_burst", 2.0)
	c.flash(Color(1.0, 0.95, 0.8, 0.5), 0.4)
	for who in GATE_ALLY_SPOT:
		var m := c.marker("al%d" % int(GATE_ALLY_SPOT[who])) / 16.0
		var a := c.ensure_ally(String(who), m.x - 0.5, m.y)
		a.mode = "hold"
	await c.say("leonie", "교장의 별빛 길이다. 다 왔다, 세라.")
	await c.say("aurelia", "촉수는 레오니가, 눈은 엘라리엔이. 장막은 제가 꿰뚫겠습니다.")
	await c.say("isolde", "얼리는 건 내 몫이야.", "smug")
	await c.say("emberlyn", "불은 내가 보탠다. 세라— 문 가운데를 노려라!")
	c.close_box()
	c.letterbox(false)
	c.music("final")
	_gate_cd.clear()
	gate.support_needed.connect(_final_support.bind(gate, c))
	gate.phase_changed.connect(_gate_phase.bind(gate, c))
	gate.engaged = true
	c.release()
	_gate_side_loop(c, gate)
	await c.wait_enemy(gate)
	if not c.ok():
		return
	await _gate_end(c, gate)


## 문이 지원을 청할 때: 그 일을 맡은 동료가 대사와 함께 지원기를 쓴다 (동료별 재사용 대기)
func _final_support(kind: String, _pos: Vector2, gate: Node, c: Cut) -> void:
	if not is_instance_valid(gate) or not c.ok():
		return
	var who: String = {"tendril": "leonie", "hand": "leonie", "eye": "elarien", "veil": "aurelia", "shield": "astrid"}.get(kind, "")
	if who == "":
		return
	var cd := 6.0 if who != "astrid" else 9.0
	if _now() < float(_gate_cd.get(who, 0.0)):
		return
	_gate_cd[who] = _now() + cd
	var a := c.ally(who)
	var from := a.global_position + Vector2(0, -20) if a else Vector2.INF
	match kind:
		"tendril", "hand":
			if a:
				a.say(["촉수는 내가 벤다!", "손이다. 받는다!", "물러서라, 세라!"][randi() % 3])
				a.set_pose("special")
			gate.cut_tendril(-1, from)
		"eye":
			if a:
				a.say(["…거기.", "보인다.", "감아라."][randi() % 3])
				a.set_pose("special")
			gate.snipe_eye(-1, from)
		"veil":
			if a:
				a.say(["빛이여!", "장막을 꿰뚫습니다!"][randi() % 2])
				a.set_pose("special")
			gate.holy_lance(5.0, from)
		"shield":
			Story.toast("— 지켜 드리죠. (아스트리드의 별빛)", 1.6)
			gate.star_shield(3.0)


## 문이 청하지 않아도 이졸데(서리)와 엠버린(불꽃)은 틈틈이 돕는다
func _gate_side_loop(c: Cut, gate: Node) -> void:
	var t := 0.0
	var turn := 0
	while c.ok() and is_instance_valid(gate) and (gate as EnemyBase).is_alive():
		await c.wait(0.5)
		t += 0.5
		if Story.busy_count() > 1 or t < 12.0:
			continue
		t = 0.0
		turn += 1
		if turn % 2 == 1:
			var a := c.ally("isolde")
			if a:
				a.say("얼어붙어라!")
				a.set_pose("special")
			gate.frost_bind(4.0)
		else:
			var b := c.ally("emberlyn")
			if b:
				b.say("불을 보탠다!")
				b.set_pose("special")
			gate.fire_volley(300)


func _gate_phase(n: int, gate: Node, c: Cut) -> void:
	if not c.ok() or not is_instance_valid(gate):
		return
	match n:
		2:
			c.bubble("문 너머에서 거신의 손이 온다! 그림자를 피하거라!", 2.8)
			var a := c.ally("leonie")
			if a:
				a.say("손은 내가 받는다!")
		3:
			c.bubble("빨려 들어가지 말거라! 바깥쪽으로 버텨라!", 2.8)
			var b := c.ally("aurelia")
			if b:
				b.say("버티십시오, 세라피나!")
		4:
			c.lock()
			c.letterbox(true)
			await c.say("lyra", "세라… 나를… 막아 줘…", "weak")
			await c.say("sera", "막을 거야. 그리고 데려갈 거야.", "angry")
			await c.say("sera", "너를 막는 건, 너를 구하는 거야.", "angry")
			await c.say("neoul", "푸른 불은 잠재우는 불이니라. 문을 재우거라, 세라야!", "happy")
			c.close_box()
			c.letterbox(false)
			c.release()


func _gate_end(c: Cut, gate: Node) -> void:
	c.lock()
	c.flag("st_gate_fight", false)
	for k in TRIAL_ALLIES:
		var a := c.ally(k)
		if a:
			a.mode = "script"
	Music.stop(2.0)
	c.letterbox(true)
	await c.wait(3.2)
	await c.narrate("하늘의 틈이 — 푸른 실로 꿰매어지듯 닫혀 갔다.")
	c.close_box()
	c.flash(Color(0.6, 0.85, 1.0, 0.7), 1.0)
	c.sfx("fox_end", 2.0)
	c.spawn_npc("lyra", 20.0, 19.0, -1)
	c.pose("lyra", "down")
	if is_instance_valid(gate):
		(gate as Node2D).visible = false
	c.music("ending", 2.0)
	await c.wait(1.0)
	await c.player_walk(17.0, 90.0)
	c.player_face(1)
	c.pose("lyra", "kneel")
	await c.say("lyra", "…따뜻해. 이게, 잠재우는 불이구나.", "weak")
	await c.say("lyra", "별빛이… 다 빠져나갔어. 이제 나, 그냥 할머니가 되겠네.", "aged")
	await c.say("sera", "…같이 내려가. 교장 선생님이 기다린대. 별 보면서.", "sad")
	await c.say("lyra", "꼬마 아스트리드가…? …응.", "happy")
	await c.say("lyra", "고마워, 세라피나. 나를 넘어 줘서. 그리고— 나를 데리러 와 줘서.", "sad")
	c.close_box()
	await c.narrate("하늘 아래, 거신들이 하나둘 무릎을 꿇고 잠들었다. 푸른 불이 그 위로 이불처럼 내려앉았다.")
	c.close_box()
	c.flag("st_gate_done")
	await c.fade_out(2.4, Color(1, 1, 1))
	_leave_all(c)
	c.letterbox(false)
	await c.goto_room("st_rebuild", "wake")
