extends "res://story/ch5/common.gd"
## 5장 대본 — 8~10. 무너진 학교(통신·환상) · 절망 · 어둠(아홉 꼬리).
## 메서드 이름 = 실행 ID (docs/dev/story.md). 장 공용 상수·도우미는 common.gd.


# ═══════════════════════════════════════════════════════════
# 8. 절망 — 무너진 학교 (r5_*)
# ═══════════════════════════════════════════════════════════

func enter_r5_clock(c: Cut) -> void:
	if c.has("st_r5_woke"):
		return
	c.flag("st_r5_woke")
	c.lock()
	c.hud(false)
	await c.fade_out(0.01)
	c.music("despair")
	c.letterbox(true)
	c.player_face(1)
	await c.wait(0.6)
	await c.say("neoul", "세라! 눈을 떠라, 세라!", "angry")
	await c.fade_in(2.0)
	await c.say("sera", "…으. 여기… 시계탑?")
	await c.say("neoul", "교장이 별빛으로 너를 받아 내던졌느니라. 교장은— 모르겠다. 빛이 흩어졌다.")
	await c.say("sera", "리라는…?", "sad")
	await c.say("neoul", "하늘로 끌려갔느니라. 그리고… 보거라.")
	c.close_box()
	c.zoom(0.82, 2.0)
	await c.camera_to(c.player.global_position + Vector2(200, -60), 2.4)
	for k in 3:
		c.sfx("colossus_step", 4.0)
		c.shake(0.45, 0.5)
		await c.wait(1.2)
	await c.narrate("지평선을 하얀 거신들이 메우고 있었다.")
	await c.narrate("도시보다 큰 발이 땅을 디딜 때마다, 세계가 울렸다.")
	await c.say("sera", "…저게, 뭐야.", "surprised")
	await c.say("neoul", "바깥 신들의 손발이니라. 저것들은 생각하지 않는다. 그저 걷고, 밟고, 지운다.")
	await c.say("sera", "학교에… 학교에 다들 있어! 피피, 이졸데…!")
	await c.say("neoul", "가자. 아래로!")
	c.close_box()
	await c.camera_back(1.0)
	c.zoom(1.0, 0.8)
	c.letterbox(false)
	c.hud(true)
	c.save_here("land")
	c.release()


## 통신 수정 구슬: 각 지역 강자에게서 오는 소식
func _comm(c: Cut, flag: String, lines: Array, vision := "", who := "", pose := "kneel", caption := "") -> void:
	if c.has(flag):
		return
	c.flag(flag)
	c.lock()
	c.sfx("window", 0.0)
	await c.narrate("깨진 통신 수정 구슬이 지직거리며 빛났다.")
	c.close_box()
	if vision != "":
		await _vision(c, vision, who, pose, caption, lines)
	else:
		for l in lines:
			var row: Array = l
			await c.say(String(row[0]), String(row[1]), String(row[2]) if row.size() > 2 else "normal")
	c.close_box()
	c.release()


## 같은 시각, 다른 지역 (침공의 땅울림): 통신이 울리는 동안 그 땅을 보여 주고 돌아온다.
## 세라는 보이지 않고 다치지 않는다. 돌아오는 자리는 지금 방의 "comm" 표식
func _vision(c: Cut, room_id: String, who: String, pose: String, _caption: String, lines: Array) -> void:
	var back := c.world.room.data.id
	await c.fade_out(0.6)
	c.hud(false)
	c.letterbox(true)
	c.player.set_iframes(999.0)
	await c.goto_room(room_id, "view")
	c.lock()
	await c.fade_out(0.01)
	c.player.visible = false
	_pet_away(c)
	var n := c.spawn_npc(who, 14.0, 19.0, 1)
	if n:
		n.visual.set_pose(pose)
	c.freeze_enemies(false)
	await c.fade_in(1.0)
	for k in 2:
		c.sfx("colossus_step", 4.0)
		c.shake(0.5, 0.5)
		await c.wait(0.9)
	for l in lines:
		var row: Array = l
		await c.say(String(row[0]), String(row[1]), String(row[2]) if row.size() > 2 else "normal")
	c.close_box()
	await c.fade_out(0.6)
	c.player.visible = true
	await c.goto_room(back, "comm")
	_pet_away(c, false)
	c.lock()
	c.player.set_iframes(1.0)
	c.letterbox(false)
	c.hud(true)


func r5_comm_leonie(c: Cut) -> void:
	await _comm(c, "st_comm_k", [
		["leonie", "…세라, 들리나. 황도에 거신이 들어왔다.", "sad"],
		["leonie", "검을 맞혔다. 흠집 하나 나지 않았다. …검이 부러졌다.", "sad"],
		["leonie", "시민은 성 지하로 옮겼다. 나는 아직 서 있다. 너도— 서 있어라."],
	], "r5_vision_k", "leonie", "kneel", "같은 시각 — 황도 아르덴")
	await c.say("sera", "레오니! 레오니!!", "surprised")
	await c.say("neoul", "…끊겼느니라.", "sad")
	c.close_box()
	c.release()


func enter_r5_hall(c: Cut) -> void:
	if c.has("st_escort"):
		return
	if not c.has("st_hall_seen"):
		c.flag("st_hall_seen")
		c.lock()
		await c.wait(0.4)
		await c.say("pippa", "세라!! 여기야, 여기!", "sad")
		await c.say("sera", "피피!", "surprised")
		await c.say("pippa", "발코니가 무너져서 못 나가! 저 하얀 것들이 계속 내려와…!", "sad")
		await c.say("neoul", "흰 사도니라. 저것들은 푸른 불을 싫어하지만— 지금 네 불로도 끌 수는 있다. 가거라!")
		c.close_box()
		c.release()
	if not await _wait_clear(c, "outer_seraph"):
		return
	c.lock()
	await c.wait(0.5)
	await c.approach("pippa", 2.0, 90.0)
	await c.say("pippa", "…세라. 고마워. 다리가 좀 아프지만, 걸을 수 있어.", "sad")
	await c.say("pippa", "얘들아, 세라 따라가! 절대 손 놓지 마!")
	await c.say("sera", "기숙사 쪽 대피소로 가자. 서관을 돌아서!")
	c.close_box()
	c.flag("st_escort")
	for who in ["pippa", "student_a", "student_b"]:
		c.hide_actor(who)
	_spawn_followers(c)
	c.save_here("start")
	c.release()


func enter_r5_westcorr(c: Cut) -> void:
	if c.has("st_westcorr_seen"):
		return
	c.flag("st_westcorr_seen")
	await c.wait(0.5)
	var f := c.actor("followers")
	if f and f.has_method("say"):
		f.say(0, "천장이…!", 2.0)
	c.bubble("위니라! 손이 내려온다 — 멈추지 말고 달려라!", 3.0)


func enter_r5_library(c: Cut) -> void:
	if c.has("st_lib_saved"):
		return
	if not c.has("st_lib_seen"):
		c.flag("st_lib_seen")
		c.lock()
		await c.wait(0.4)
		await c.say("greta", "…세라피나. 이쪽으로 오지 마라. 위에 하나 있다.")
		await c.say("sera", "그레타 선생님! 빨리 나가요, 책은 두고!")
		await c.say("greta", "책은 두고 가지 않는다.")
		await c.say("hodu", "호우…!")
		c.close_box()
		c.release()
	if not await _wait_clear(c, "outer_seraph"):
		return
	c.lock()
	await c.wait(0.4)
	await c.say("greta", "…고맙다. 금서 몇 권은 챙겼다. 나머지는— 다시 쓰면 된다.")
	await c.say("greta", "기억해 둬라. 불사조는 제 재 속에서 다시 일어난다.")
	await c.say("hodu", "호우.")
	c.close_box()
	c.flag("st_lib_saved")
	c.walk("greta", 2.0, 100.0)
	c.walk("hodu", 2.0, 100.0)
	await c.wait(1.0)
	c.hide_actor("greta")
	c.hide_actor("hodu")
	c.release()
	# 싸우는 동안 수정 구슬 곁을 지나쳤어도 소식은 듣는다
	await c.wait(0.6)
	await r5_comm_elarien(c)


func r5_comm_elarien(c: Cut) -> void:
	await _comm(c, "st_comm_e", [
		["elarien", "…세라. 숲이다.", "sad"],
		["elarien", "거신의 눈을 맞혔다. 세 번. 화살이 튕겼다.", "sad"],
		["elarien", "세계수가 탄다. 아이들은 뿌리 아래에 숨겼다. …살아라."],
	], "r5_vision_e", "elarien", "hurt", "같은 시각 — 세계수")
	await c.say("sera", "엘라리엔…!", "sad")
	c.close_box()
	c.release()


func enter_r5_dorm(c: Cut) -> void:
	if c.has("st_dorm_seen") or c.has("st_dorm_vision"):
		return
	c.lock()
	await c.wait(0.4)
	await c.say("astrid", "…세라피나 양. 다행이에요. 살아 있었군요.", "tired")
	await c.say("sera", "교장 선생님! 탑에서 저를—", "surprised")
	await c.say("astrid", "던진 건 저예요. 받는 건 조금 서툴렀네요. 미안해요.", "tired")
	c.close_box()
	c.flag("st_dorm_vision")
	await _comm(c, "st_comm_tp", [
		["aurelia", "…세라피나. 대신전입니다. 창이… 부서졌습니다.", "sad"],
		["aurelia", "루멘의 빛이 닿지 않습니다. 종루도 무너졌습니다.", "sad"],
		["aurelia", "그래도 저는 아직 서 있습니다. 당신도.", "sad"],
	], "r5_vision_tp", "aurelia", "kneel", "같은 시각 — 루멘 대신전")
	c.lock()
	await c.wait(0.3)
	await c.say("mirabel", "교장 선생님 얼굴이 하얘요… 더 이상은 무리예요!", "sad")
	await c.say("astrid", "괜찮아요. 아직은.", "tired")
	await c.say("astrid", "학생들을 앞마당으로 모읍시다. 제가 결계를 치겠어요.")
	await c.say("astrid", "백 년 동안 떠받치던 것보다는… 작은 결계라 다행이네요.", "wink")
	await c.say("sera", "제가 앞장설게요.")
	c.close_box()
	c.flag("st_dorm_seen")
	for who in ["astrid", "mirabel", "student_c"]:
		c.walk(who, 1.0, 90.0)
	await c.wait(1.2)
	for who in ["astrid", "mirabel", "student_c"]:
		c.hide_actor(who)
	c.save()
	c.release()


## 9. 절망: 무너진 앞마당 (트리거)
func r5_despair(c: Cut) -> void:
	if c.has("st_fallen"):
		return
	c.lock()
	c.letterbox(true)
	var giant: EnemyBase = null
	for e in c.world.room.enemies:
		if not is_instance_valid(e) or e.kind_id != "colossus":
			continue
		if String(e.get("mode")) == "hand":
			e.set("walking", false)
		else:
			giant = e
	await c.wait(0.4)
	c.player_face(1)
	await c.say("sera", "더는 도망칠 데가 없어… 그럼—!", "angry")
	c.close_box()
	# 세라의 공격이 통하지 않는다
	var target := c.player.global_position + Vector2(140, -60)
	if giant and is_instance_valid(giant):
		target = giant.global_position + Vector2(0, -80)
	for k in 3:
		c.sfx("shoot_heavy", 0.0)
		var from := c.player.center()
		StStrike.spawn(from, "beam", Vector2(0, 4), 0.01, {"to": target + Vector2(0, k * 10.0), "damage": 0, "style": "fire", "hold": 0.08, "fade": 0.3})
		c.burst(target + Vector2(0, k * 10.0), 18, Color(1.0, 0.6, 0.3), {spread = 180.0, speed_min = 30.0, speed_max = 120.0, lifetime = 0.4})
		if giant and is_instance_valid(giant):
			giant.take_hit(Hit.make(60, &"bolt", target + Vector2(0, k * 10.0)))
		await c.wait(0.45)
	await c.narrate("…흠집 하나 나지 않았다.")
	await c.say("sera", "왜… 왜 안 통하는 거야!", "angry")
	await c.say("neoul", "세라, 저것은 싸울 수 있는 것이 아니니라! 물러서라!", "angry")
	c.close_box()
	# 교장의 마지막 결계
	c.spawn_npc("astrid", 22.0, 19.0, 1)
	c.spawn_npc("mirabel", 20.0, 19.0, 1)
	c.spawn_npc("student_c", 18.0, 19.0, 1)
	await c.walk("astrid", 30.0, 80.0)
	c.pose("astrid", "shield")
	await c.say("astrid", "학생들은 제 뒤로. 세라피나 양도!")
	c.close_box()
	c.sfx("ward", 4.0)
	var dome := Vector2(28 * 16.0, 19 * 16.0)
	var shield := StStrike.spawn(dome + Vector2(0, -24), "circle", Vector2(80, 80), 0.01, {"damage": 0, "style": "star", "hold": 9.0, "fade": 1.2})
	await c.player_walk(32.0, 140.0)
	c.player_face(1)
	var f := c.actor("followers")
	if f and f.has_method("scatter"):
		f.scatter()
	# 발이 내려온다
	c.sfx("colossus_step", 6.0)
	StStrike.spawn(dome + Vector2(0, -20), "band", Vector2(260, 40), 1.2, {"damage": 0, "style": "white", "hold": 0.2, "fade": 0.3})
	await c.wait(1.2)
	c.shake(0.9, 0.8)
	c.flash(Color(1, 1, 1, 0.8), 0.3)
	c.sfx("slam", 6.0)
	await c.say("astrid", "…학생들에게는, 손가락 하나… 대게 하지 않아요.", "tired")
	c.close_box()
	await c.wait(0.8)
	c.sfx("colossus_step", 6.0)
	await c.wait(0.9)
	c.shake(1.0, 1.0)
	c.flash(Color(1, 1, 1, 0.9), 0.4)
	c.sfx("crumble", 6.0)
	if is_instance_valid(shield):
		shield.queue_free()
	c.burst(dome + Vector2(0, -60), 60, StArt.STAR, {spread = 180.0, speed_min = 60.0, speed_max = 240.0, lifetime = 0.9})
	c.pose("astrid", "down")
	await c.say("astrid", "세라피나 양… 미안해요… 조금만… 쉬었다가…", "tired")
	await c.say("sera", "교장 선생님!!", "surprised")
	c.close_box()
	await c.player_walk(31.0, 160.0)
	# 손이 세라를 덮친다
	c.sfx("colossus_step", 6.0)
	StStrike.spawn(c.player.global_position + Vector2(0, -30), "band", Vector2(100, 60), 0.8, {"damage": 0, "style": "white", "hold": 0.1, "fade": 0.3})
	await c.wait(0.8)
	c.shake(1.2, 1.2)
	c.flash(Color(1, 1, 1, 1.0), 0.6)
	c.sfx("hit_heavy", 6.0)
	c.player.velocity = Vector2(-220, -200)
	await c.wait(0.8)
	await c.say("neoul", "세라! 세라!!", "angry")
	c.close_box()
	Music.stop(3.0)
	await c.fade_out(3.0)
	await c.narrate("발소리가 멀어지지 않았다.")
	await c.narrate("세라는 차가운 돌바닥 위에서, 손가락 하나 움직일 수 없었다.")
	await c.narrate("……")
	c.close_box()
	c.flag("st_fallen")
	c.letterbox(false)
	await c.goto_room("st_void", "start")


# ═══════════════════════════════════════════════════════════
# 10. 어둠 — 아홉 꼬리
# ═══════════════════════════════════════════════════════════

func enter_st_void(c: Cut) -> void:
	if c.has("st_void_done"):
		await c.goto_room("r5_courtyard_rise", "wake")
		return
	c.lock()
	c.hud(false)
	await c.fade_out(0.01)
	Music.stop(0.1)
	c.player_face(1)
	_pet_away(c)
	await c.wait(1.0)
	await c.fade_in(3.0)
	await c.wait(0.8)
	await c.say("sera", "…여기는.", "sad")
	await c.say("sera", "아무것도 안 보여. 아무 소리도… 발소리도.", "sad")
	c.close_box()
	await c.wait(1.0)
	var g := c.actor("neoul_god")
	c.music("nine_tails", 3.0)
	if g:
		await g.appear(1.6)
	await c.say("neoul_god", "일어나거라, 그릇아.", "normal")
	await c.say("sera", "……그릇이라고 부르지 마.", "sad")
	await c.say("neoul_god", "…", "sad")
	c.close_box()
	await c.wait(0.6)
	await c.say("sera", "나 말이야. 처음부터 남이 만든 거였대.", "sad")
	await c.say("sera", "폭주도, 마력도, 너의 구슬을 삼킨 것도. 전부 리라가 정해 놓은 길이었대.", "sad")
	await c.say("sera", "그럼 나는… 뭐야? 누군가를 막으려고 만든 도구야?", "sad")
	await c.say("sera", "그 도구는 거신 발가락 하나 못 긁었어. 교장 선생님도… 아무도 못 지켰어.", "sad")
	c.close_box()
	await c.wait(1.2)
	if g:
		g.unveil(true, 1.6)
		g.face(-1)
	await c.wait(1.6)
	await c.say("neoul_god", "……세라야.", "gentle")
	c.close_box()
	await c.wait(1.0)
	await c.say("sera", "…방금. 이름…", "surprised")
	await c.say("neoul_god", "구슬이 네 안에 들어간 그날부터, 나는 너를 쭉 보아 왔느니라.", "gentle")
	await c.say("neoul_god", "폐급이라 손가락질받던 날도, 남을 지키겠다고 불 속에 뛰어든 날도.", "gentle")
	await c.say("neoul_god", "별의 씨앗이 누구의 것이든, 구슬이 누구의 것이든— 그 힘으로 누구를 지킬지 정한 것은, 언제나 너였다.", "gentle")
	await c.say("neoul_god", "레오니의 시장에서. 엘라리엔의 숲에서. 아우렐리아의 첨탑에서. 그건 리라가 그려 둔 길이 아니었느니라.", "gentle")
	await c.say("neoul_god", "네 발로 걸어간 길이었다.", "tearful")
	await c.say("sera", "…너울.", "sad")
	await c.say("neoul_god", "그러니 이번엔 내가 묻겠다. 너는 무엇이냐.", "normal")
	c.close_box()
	await c.wait(0.8)
	await c.say("sera", "나는… 세라피나. 폐급 마녀.", "sad")
	await c.say("sera", "그리고— 너의 짝이야.", "happy")
	await c.say("neoul_god", "…그래. 너는 그릇이 아니니라. 너는 나의 짝이다.", "tearful")
	await c.say("neoul_god", "구슬은 이미 네 안에서 울고 있다. 끝까지 울려 보자꾸나. 아홉 꼬리 전부.", "awaken")
	c.close_box()
	if g:
		await g.awaken()
	await c.tails(9)
	c.flag("fox_permanent")
	await c.title_card("아홉 꼬리", "구미호 — 너울과 하나 되어", 2.6)
	if g:
		await g.merge_into(c.player.center(), 1.4)
	_pet_away(c, false)
	c.player.start_fox_mode()
	await c.wait(0.8)
	await c.say("neoul", "가자, 세라야. 깨워야 할 것들이 있느니라. 그리고— 잠재워야 할 것들도.", "happy")
	c.close_box()
	c.flag("st_void_done")
	await c.fade_out(1.6, Color(0.7, 0.85, 1.0))
	await c.goto_room("r5_courtyard_rise", "wake")
