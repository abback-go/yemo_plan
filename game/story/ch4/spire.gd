extends "res://story/ch4/common.gd"
## 4장 대본 — 8~11. 내전 · 첨탑 추격 · 꼭대기 결전 · 기숙사의 밤(장 끝).
## 메서드 이름 = 실행 ID (docs/dev/story.md). 장 공용 상수·도우미는 common.gd.


# ═══════════════════════════════════════════════════════════
# 8. 내전 — 기도, 겹친 메아리, 폭주. 레오니가 대사제를 감싼다
# ═══════════════════════════════════════════════════════════

func tp_sanctum_scene(c: Cut) -> void:
	if c.has("tp_sanctum_berserk") or not c.has("tp_aurelia_talk"):
		return
	c.lock()
	var a := _leonie(c)
	if a == null:
		a = _leonie_join(c)
	a.mode = "script"
	await c.player_walk(44.0, 60.0)
	await a.move_to(41.0)
	a.facing = 1
	c.player_face(1)
	c.tint(Color(0.04, 0.05, 0.2, 0.3), 1.0)
	c.pose("aurelia", "kneel")
	await c.say("benedicta", "와 주었군요. 수호자의 기도는 대신전의 모든 빛을 한곳에 모아요. …조금 위험할 수도 있어요.")
	await c.say("aurelia", "빛의 주재여.")
	c.sfx("bell", -2.0)
	await c.say("aurelia", "당신의 수호자가 묻습니다. 어찌하여 침묵하십니까.")
	c.close_box()
	c.tint(Color(1.0, 0.85, 0.4, 0.18), 1.2)
	await c.wait(1.2)
	await c.say("aurelia", "…대답하소서.")
	c.close_box()
	await c.wait(1.2)
	c.shake(0.2, 0.8)
	await c.say("aurelia", "대답하소서!", "angry")
	c.close_box()
	Music.stop(0.5)
	await c.wait(1.4)
	c.flash(Color(1, 1, 1, 0.9), 0.4)
	c.sfx("sky_crack", 4.0)
	c.tint(Color(0.9, 0.92, 1.0, 0.22), 0.3)
	await c.say("tp_voice", "…대답… 하마…")
	c.emote("sera", "!")
	c.emote("benedicta", "!")
	await c.say("aurelia", "주…여?", "surprised")
	await c.say("tp_voice", "그릇… 빛의 그릇… 단단하구나… 아주… 단단해…")
	await c.say("tp_voice", "문이… 되어라…")
	await c.say("neoul", "아니다! 저건 루멘이 아니니라! 듣지 마라, 수호자!", "angry")
	await c.say("aurelia", "아… 아아……", "sad")
	c.close_box()
	# 광륜이 흰빛으로 금 가며 폭주
	var n := c.npc("aurelia")
	var pos := n.global_position if n else Vector2(63 * 16 + 8, 17 * 16)
	c.hide_actor("aurelia")
	var b := c.spawn_npc("aurelia_berserk", pos.x / 16.0 - 0.5, pos.y / 16.0, -1)
	b.visual.set_pose("berserk_kneel")
	c.sfx("holy_charge", 4.0)
	c.shake(0.6, 1.2)
	c.flash(Color(1, 1, 1, 1), 0.5)
	for i in 3:
		Fx.ring(pos + Vector2(0, -30), 6.0, 60.0 + i * 30.0, Color(1.0, 0.97, 0.9), 0.6, 3.0)
	c.burst(pos + Vector2(0, -30), 50, Color(1.0, 0.95, 0.8), {spread = 180.0, speed_min = 60.0, speed_max = 220.0, lifetime = 0.8})
	await c.wait(1.0)
	b.visual.set_pose("berserk_idle")
	await c.say("aurelia_berserk", "물러—나—십시오.", "berserk")
	await c.say("aurelia_berserk", "빛을—더럽히는—모든—것을—", "berserk")
	await c.say("benedicta", "아우렐리아…!", "surprised")
	c.close_box()
	# 레오니가 대사제 앞으로 — 신성 돌진을 정면으로 받아낸다
	c.flash(Color(1, 1, 1, 0.5), 0.2)
	c.hide_actor("aurelia_berserk")
	a.global_position = Vector2(57 * 16 + 8, 17 * 16)
	a.velocity = Vector2.ZERO
	a.facing = 1
	a.set_pose("guard")
	await c.say("leonie", "대사제님, 뒤로!")
	c.close_box()
	var ch := _chaser(c)
	if ch:
		await ch.charge_at(17 * 16 - 18.0, -1, a, 0.9)
	c.shake(0.5, 0.5)
	await c.say("leonie", "크윽…!", "angry")
	await c.say("leonie", "세라! 대사제님은 내가 맡는다! 너는 위로 — 첨탑으로 도망쳐라!")
	await c.say("sera", "레오니! 혼자서는—", "surprised")
	await c.say("leonie", "가라! 지금의 우리로는 저걸 못 막는다! 위에서 버텨라, 곧 따라간다!")
	await c.say("neoul", "세라, 가자! 저 기사 계집은 쉽게 안 쓰러진다!")
	c.close_box()
	c.flag("tp_sanctum_berserk")
	c.sfx("crumble", 4.0)
	c.shake(0.4, 0.8)
	_leonie_leave(c)
	var ln := c.spawn_npc("leonie", 57.0, 17.0, 1)
	ln.visual.set_pose("guard")
	c.tint(Color(0, 0, 0, 0), 0.8)
	c.music("chase", 0.6)
	Story.toast("첨탑으로! 오른쪽 봉인 문이 부서졌다.", 2.6)


# ═══════════════════════════════════════════════════════════
# 9. 첨탑 추격 — 차오르는 금빛, 신성 돌진, 레오니가 받아내고, 교장이 별을 깐다
# ═══════════════════════════════════════════════════════════

func tp_spire1_enter(c: Cut) -> void:
	if c.has("tp_spire1_seen"):
		return
	c.flag("tp_spire1_seen")
	c.lock()
	await c.say("sera", "하아, 하아… 계단이 끝이 없어!", "surprised")
	await c.say("neoul", "아래를 보거라 — 금빛이 차오른다! 멈추면 잡힌다, 위로!", "angry")
	c.close_box()
	await c.teach("첨탑 추격", "멈추지 말고 위로! 아래에서 금빛이 차오른다.\n금빛 띠가 층을 가로지르면(예고) 다른 높이로 뛰거나 대시로 피한다.\n띠가 지나간 나무 발판은 부서진다.", ["jump"])


func tp_spire3_leonie(c: Cut) -> void:
	if c.has("tp_spire3_leonie"):
		return
	c.lock()
	var ch := _chaser(c)
	if ch:
		ch.set_paused(true)
		if ch.cstate != HolyChaser.C.NONE:
			await ch.charge_done
	var a := _leonie_join(c, 7.0, 35.0)
	a.mode = "script"
	await c.say("leonie", "세라!")
	c.player_face(-1)
	await c.say("sera", "레오니?! 대사제님은?", "surprised")
	await c.say("leonie", "수도사들에게 맡겼다. 무사하다.")
	await c.say("leonie", "…온다. 뒤로 물러서라.")
	c.close_box()
	await c.player_walk(9.0, 90.0)
	await a.move_to(17.0)
	a.facing = 1
	a.set_pose("guard")
	c.player_face(1)
	if ch:
		await ch.charge_at(35 * 16 - 18.0, -1, a, 0.9)
	c.shake(0.6, 0.6)
	await c.say("leonie", "크으…! …이 정도는.", "angry")
	await c.say("leonie", "올라가라, 세라! 여기는 내가 막는다!")
	await c.say("sera", "같이 가!", "sad")
	await c.say("leonie", "빈민가에서 맨손으로 여기까지 왔다. 이 정도 돌진, 몇 번이고 받아 준다.")
	await c.say("leonie", "꼭대기에서 보자. …가라!")
	c.close_box()
	var lx := a.global_position.x / 16.0 - 0.5
	_leonie_leave(c)
	var ln := c.spawn_npc("leonie", lx, 35.0, 1)
	ln.visual.set_pose("guard")
	c.flag("tp_spire3_leonie")
	if ch:
		ch.set_paused(false)


func tp_spire4_astrid(c: Cut) -> void:
	if c.has("tp_star_steps"):
		return
	c.lock()
	var ch := _chaser(c)
	if ch:
		ch.set_paused(true)
	await c.camera_to(c.player.global_position + Vector2(90, -170), 0.9)
	await c.say("sera", "계단이… 통째로 없어! 위까지 너무 멀어!", "surprised")
	await c.say("neoul", "아래는 금빛, 위는 허공… 날개로도 저 높이는…", "sad")
	c.close_box()
	await c.camera_back(0.5)
	c.sfx("star_twinkle", 2.0)
	await c.wait(0.6)
	await c.say("astrid", "세라. 위를 보세요.")
	await c.say("sera", "교장 선생님?! 어디서—", "surprised")
	await c.say("astrid", "전이진에 남겨 둔 별 하나를 통해서요. 멀리서는 이 정도가 한계군요.")
	c.close_box()
	c.flag("tp_star_steps")
	c.sfx("star_burst", 2.0)
	c.flash(Color(0.75, 0.8, 1.0, 0.6), 0.6)
	await c.camera_to(c.player.global_position + Vector2(90, -150), 1.6)
	await c.wait(0.6)
	await c.say("astrid", "나머지는 당신 발로. …서두르세요. 금빛 아가씨가 화가 많이 났네요.", "happy")
	await c.say("neoul", "흥, 그 할망구… 별을 다 깔아 주는구나. 가자, 세라!", "happy")
	c.close_box()
	await c.camera_back(0.5)
	if ch:
		ch.set_paused(false)


func enter_tp_spire_top(c: Cut) -> void:
	if c.has("tp_aurelia_defeated"):
		return
	c.flag("tp_spire_top_reached")


# ═══════════════════════════════════════════════════════════
# 10. 꼭대기 결전 — 아우렐리아 (레오니 합류), 푸른 불의 정화, 리라
# ═══════════════════════════════════════════════════════════

func tp_boss(c: Cut) -> void:
	if c.has("tp_aurelia_defeated"):
		return
	var boss := c.enemy("aurelia_boss") as AureliaBoss
	if boss == null:
		return
	c.lock()
	if not c.has("tp_boss_met"):
		c.flag("tp_boss_met")
		Music.stop(1.0)
		c.sfx("wind", 0.0)
		await c.wait(0.6)
		await c.camera_to(boss.global_position + Vector2(-60, -50), 1.2)
		await c.say("sera", "꼭대기… 하늘이 열려 있어.", "surprised")
		c.sfx("holy_charge", 4.0)
		c.flash(Color(1.0, 0.95, 0.85, 0.7), 0.4)
		c.shake(0.4, 0.6)
		await c.say("aurelia_berserk", "도망—칠 곳은—없습니다.", "berserk")
		await c.say("aurelia", "…세라… 님… 피하십시오… 제 창이… 멈추지 않습니다…", "sad")
		await c.say("sera", "아우렐리아! 안에 아직 있구나!", "surprised")
		await c.say("neoul", "세라. 저 안의 흰 것만 태우면 된다. 푸른 불로. 그러려면 먼저 저 금빛을 꺾어야 하느니라.", "angry")
		await c.say("sera", "…알았어. 기다려, 아우렐리아. 꺼내 줄게.", "angry")
		c.close_box()
		await c.camera_back(0.6)
	else:
		await c.say("neoul", "다시 가자, 세라. 돌진은 예고 띠를 보고, 심판의 창은 기둥 뒤로!")
		c.close_box()
	c.music("aurelia", 0.5)
	c.flag("tp_boss_fight")
	c.save_here("start")
	boss.engaged = true
	c.release()
	# 2페이즈(66%): 레오니 합류
	await c.wait_until(func() -> bool: return not is_instance_valid(boss) or not boss.is_alive() or boss.phase >= 2, 1200.0)
	if not c.ok():
		return
	if is_instance_valid(boss) and boss.is_alive() and _leonie(c) == null:
		var a := _leonie_join(c, 3.0, 19.0)
		c.sfx("sword_slash", 2.0)
		a.say("기다렸지! 다리를 끊어 주마!", 3.0)
		c.bubble("기사 계집이 왔구나! 돌진이 오면 저 계집이 받아칠 게다!", 3.5)
	# 싸우는 동안: 돌진 예고가 보이면 레오니가 받아친다 (12초에 한 번)
	var cd := 2.0
	var shown3 := false
	while c.ok() and is_instance_valid(boss) and boss.is_alive():
		await c.world.get_tree().physics_frame
		cd -= c.world.get_physics_process_delta_time()
		var al := _leonie(c)
		if al and cd <= 0.0 and boss.charge_windup_active():
			al.special(boss)
			cd = 12.0
		if boss.phase >= 3 and not shown3:
			shown3 = true
			if al:
				al.say("흰빛이 짙어졌다! 조심해라, 세라!", 3.0)
			c.bubble("심판의 창이 오면 기둥 뒤, 파란 그늘로!", 3.2)
	if not c.ok():
		return
	await _boss_end(c, boss)


func _boss_end(c: Cut, boss: AureliaBoss) -> void:
	c.lock()
	c.flag("tp_aurelia_defeated")
	c.flag("tp_boss_fight", false)
	Music.stop(2.0)
	var a := _leonie(c)
	if a:
		a.mode = "script"
	await c.wait(1.6)
	var bpos := boss.global_position if is_instance_valid(boss) else Vector2(40 * 16, 19 * 16)
	await c.camera_to(bpos + Vector2(0, -30), 0.8)
	await c.say("tp_voice", "그릇이… 부서지지… 않는다… 놓지… 않는다…")
	await c.say("neoul", "지금이니라, 세라! 내 불을 쓰거라 — 푸른 불로, 저 흰 것만 태워라!", "angry")
	await c.say("sera", "응…!", "angry")
	c.close_box()
	# 푸른 불 (잠재우는 불): 바깥 신들의 연결만 태운다
	c.player_face(1 if bpos.x > c.player.global_position.x else -1)
	c.sfx("fox_transform", 2.0)
	for i in 3:
		Fx.ring(bpos + Vector2(0, -20), 6.0, 70.0 + i * 25.0, Color(0.5, 0.8, 1.0), 0.7, 3.0)
		c.burst(bpos + Vector2(0, -20), 40, Color(0.55, 0.85, 1.0), {spread = 180.0, speed_min = 40.0, speed_max = 160.0, lifetime = 0.9})
		await c.wait(0.35)
	c.flash(Color(0.6, 0.85, 1.0, 0.9), 0.8)
	c.shake(0.5, 1.0)
	await c.say("tp_voice", "…아아… 또… 다른… 그릇이… 있으니…")
	c.close_box()
	# 빛이 걷히는 동안(암전) 투기장 가운데로 모은다 — 리라가 그 위 첨탑 끝에 나타난다
	await c.fade_out(0.6, Color(0.75, 0.88, 1.0))
	var floor_y := 19.0 * 16.0
	if is_instance_valid(boss):
		boss.purify()
		boss.global_position = Vector2(42 * 16 + 8, floor_y)
		boss.velocity = Vector2.ZERO
		boss.facing = -1
	c.player.global_position = Vector2(38 * 16 + 8, floor_y)
	c.player.velocity = Vector2.ZERO
	c.player_face(1)
	if a:
		a.global_position = Vector2(35 * 16 + 8, floor_y)
		a.velocity = Vector2.ZERO
		a.facing = 1
		a.set_pose("idle")
	c.tint(Color(0.05, 0.08, 0.25, 0.3), 0.01)
	await c.camera_back(0.01)
	c.player.camera.reset_smoothing()
	await c.fade_in(1.2)
	await c.wait(0.6)
	await c.say("aurelia", "……", "sad")
	await c.say("aurelia", "…저는… 무엇을…", "surprised")
	await c.say("sera", "괜찮아? 흰 것한테 홀렸었어. 이제 다 태웠어.")
	await c.say("aurelia", "…기억납니다. 대답한 것은 주가 아니었습니다.", "sad")
	await c.say("aurelia", "저는 그 목소리에 기뻐했습니다. 열흘 만에 들린 대답이라고.", "sad")
	await c.say("aurelia", "흔들리지 않겠다고 서원한 수호자가, 가장 먼저 흔들렸습니다.", "sad")
	await c.say("sera", "…흔들린 게 나쁜 거야? 대답 없는 기도를 열흘이나 했잖아. 나 같으면 사흘 만에 그만뒀어.")
	await c.wait(0.4)
	await c.say("aurelia", "……")
	await c.say("aurelia", "…빛을 지킨 것은 당신이었습니다.", "smile")
	if a:
		await c.say("leonie", "…웃었다.", "surprised")
	await c.say("aurelia", "웃지 않겠다는 서원은… 오늘로 깨진 것 같군요.", "smile")
	await c.say("aurelia", "그 목소리. 기록에 있던 자들입니다. 천외(天外)의 신들 — 하늘 바깥에서, 빛이 약한 세계를 먹는 것들.")
	await c.say("aurelia", "그들은 저를 문으로 쓰려 했습니다. 그리고 제 안을 지나가며… 다른 이름을 불렀습니다.")
	await c.say("aurelia", "'별의 그릇'. 그리고 — '별의 마녀'.")
	c.emote("neoul", "!")
	await c.say("neoul", "…별의, 마녀.", "sad")
	c.close_box()
	# 달빛 아래 첨탑 끝 — 리라
	await c.wait(0.6)
	c.music("lyra", 1.5)
	c.sfx("star_twinkle", 2.0)
	var lyra_at := Vector2(40 * 16 + 8, 7 * 16)
	c.spawn_npc("lyra", 40.0, 7.0, -1)
	c.burst(lyra_at + Vector2(0, -16), 40, Color(0.85, 0.85, 1.0), {spread = 180.0, speed_min = 20.0, speed_max = 90.0, lifetime = 1.2})
	await c.camera_to(lyra_at + Vector2(0, -10), 1.4)
	await c.say("lyra", "어머. 다 끝나 버렸네.", "happy")
	await c.say("sera", "…누구?", "surprised")
	await c.say("lyra", "……")
	await c.say("lyra", "잘 자랐구나, 나의 별.", "happy")
	await c.say("neoul", "너… 네 이놈…! 그 별빛, 그 냄새… 너였느냐!", "angry")
	await c.say("lyra", "오랜만이야, 꼬마 여우님. 꼬리가 또 하나 돋으려나 보네? 귀여워라.", "happy")
	if is_instance_valid(boss):
		boss.pose("guard")
	await c.say("aurelia", "물러나십시오.", "angry")
	await c.say("lyra", "무서워라. 금빛 아가씨, 오늘은 인사만 하러 왔어.")
	await c.say("lyra", "세라피나. 조금만 더 자라렴. 너를 만나러 갈게. …곧.", "happy")
	c.close_box()
	c.sfx("star_burst", 2.0)
	c.flash(Color(0.8, 0.85, 1.0, 0.9), 0.6)
	c.burst(lyra_at + Vector2(0, -16), 60, Color(0.9, 0.9, 1.0), {spread = 180.0, speed_min = 40.0, speed_max = 200.0, lifetime = 1.0})
	c.hide_actor("lyra")
	await c.wait(1.0)
	await c.camera_back(0.8)
	await c.say("sera", "…나의 별…?", "sad")
	c.close_box()
	c.flag("tp_lyra_seen")
	if a:
		await c.say("leonie", "제국에 보고하러 돌아가겠다. …세라.")
		await c.say("leonie", "오늘, 나쁘지 않았다.", "happy")
	await c.say("aurelia", "세라 님. 대신전의 문은 이제 당신에게 닫히지 않습니다.", "smile")
	c.close_box()
	await c.fade_out(1.6)
	_leonie_leave(c)
	c.tint(Color(0, 0, 0, 0), 0.01)
	await c.narrate("그날 밤, 성산의 큰 종이 열흘 만에 울렸다.")
	await c.narrate("루멘은 여전히 침묵했지만, 수호자는 다시 창을 들었다.")
	c.close_box()
	await _dorm_night(c)


# ═══════════════════════════════════════════════════════════
# 11. 끝 — 기숙사의 밤 (짧게, 불안)
# ═══════════════════════════════════════════════════════════

func _dorm_night(c: Cut) -> void:
	await c.goto_room("s_dorm", "bed")
	c.lock()
	c.hud(false)
	Music.stop(0.5)
	c.tint(Color(0.02, 0.03, 0.12, 0.45), 0.01)
	c.player_face(1)
	await c.wait(0.5)
	await c.fade_in(2.0)
	await c.wait(0.6)
	await c.say("sera", "…너울. 자?")
	await c.say("neoul", "…자는 중이니라.")
	await c.say("sera", "리라라는 사람. 나를 '나의 별'이라고 불렀어. 나, 저 사람 몰라.", "sad")
	await c.say("neoul", "……")
	await c.say("neoul", "그 별빛… 네 마력 속에 섞인 그것과 같은 냄새였느니라.", "sad")
	await c.say("sera", "…무슨 뜻이야.")
	await c.say("neoul", "나도 모른다. 모르니까… 자거라. 내일 일은 내일 생각하자꾸나.")
	await c.wait(0.5)
	await c.say("neoul", "…세라. 오늘 푸른 불, 잘 썼다.")
	await c.say("sera", "…응.", "happy")
	c.close_box()
	await c.fade_out(2.0)
	c.tint(Color(0, 0, 0, 0), 0.01)
	c.save_here("bed")
	await ChapterFlow.finish(c, 4)
