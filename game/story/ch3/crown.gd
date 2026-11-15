extends "res://story/ch3/common.gd"
## 3장 대본 — 수관·사냥 시험 · 꼭대기·백색 사도 · 장로의 집·기숙사의 밤(장 끝).
## 메서드 이름 = 실행 ID (docs/dev/story.md). 장 공용 상수·도우미는 common.gd.


# ═══════════════════════════════════════════════════════════
# 수관 · 사냥 시험
# ═══════════════════════════════════════════════════════════

func enter_e_canopy_1(c: Cut) -> void:
	if not c.has("e_meteor_hint"):
		c.flag("e_meteor_hint")
	if not c.has("e_canopy_seen"):
		c.flag("e_canopy_seen")
		await c.wait(0.8)
		c.bubble("잎 사이로 하늘이 보이는구나. 저 등불의 나방들, 등불에 앉아 쉴 때가 빈틈이니라.", 3.4)


func e_hunt_offer(c: Cut) -> void:
	if c.has("e_hunt_offer"):
		return
	c.flag("e_meteor_hint")
	c.lock()
	c.face("elarien", -1)
	await c.say("elarien", "왔군.")
	await c.say("elarien", "규칙은 하나. 내가 경기장에서 너를 사냥한다. 너는 나에게 세 번 닿아라.", "focus")
	await c.say("sera", "닿기만 하면 돼요? 이기는 게 아니라?")
	await c.say("elarien", "가까이 와서 몸에 닿든, 곁에서 불을 맞히든, 내 화살을 돌려보내든. 셋.")
	await c.say("elarien", "멀리서 쏘는 불은 안 맞는다. 바람이 다 알려 주니까.", "smirk")
	await c.say("neoul", "…닿으라니. 사냥꾼이 사냥감에게 거리를 내주겠다는 게냐.")
	await c.say("elarien", "준비되면 올라와라. 기록은 해 두고.")
	c.close_box()
	c.flag("e_hunt_offer")
	await c.walk("elarien", 72.0, 90.0)
	c.sfx("door")
	c.hide_actor("elarien")


## 수관 경기장: 사냥 시험 (강자 보스 — 세 번 닿기). 쓰러지면 다시 들어올 때 "다시."
func e_hunt_begin(c: Cut) -> void:
	if c.has("e_hunt_done"):
		return
	var e := c.enemy("elarien_hunt") as ElarienHunt
	if e == null or not e.is_alive():
		await _hunt_after(c, null)
		return
	if e.engaged:
		return
	c.lock()
	if not c.has("e_hunt_seen"):
		c.flag("e_hunt_seen")
		await c.camera_to(e.global_position + Vector2(0, 30), 1.0)
		await c.say("elarien", "위다.", "focus")
		await c.say("elarien", "가지는 네 발판이고, 나는 바람이다. 올라와 봐라.")
		c.close_box()
		await c.camera_back(0.8)
		await c.teach("세 번 닿기", "엘라리엔에게 세 번 닿으면 끝 — 체력 싸움이 아니다.\n① 몸에 부딪치기  ② 4칸 안에서 불 맞히기  ③ 화살을 불꽃 방벽으로 되쏘기\n붉은 예고선이 흰색으로 깜빡이면 곧 화살 — 가지를 옮겨 피하자.", ["jump"])
	else:
		await c.say("elarien", "다시.", "focus")
		c.close_box()
	c.music("elf_hunt")
	var won := [false]
	e.defeated.connect(func(_who: Variant) -> void: won[0] = true)
	e.touched.connect(func(n: int) -> void:
		if n == 1:
			c.bubble("닿았다! 그 기세다, 세라!", 2.0)
		elif n == 2:
			c.bubble("하나만 더! 화살비가 온다 — 붉은 표시를 보거라!", 2.6))
	e.engaged = true
	c.release()
	await c.wait_enemy(e)
	if not c.ok() or not won[0]:
		return # 쓰러졌거나 경기장을 나감 → 다시 들어오면 "다시."
	await _hunt_after(c, e if is_instance_valid(e) else null)


func _hunt_after(c: Cut, e: EnemyBase) -> void:
	c.lock()
	c.flag("e_hunt_done")
	await c.wait(1.0)
	var at := Vector2(20, 17)
	if is_instance_valid(e):
		at = e.global_position / 16.0
		e.visible = false
	var p := c.player_tile()
	var side := 1.0 if at.x >= p.x else -1.0
	c.spawn_npc("elarien", at.x, at.y, -1)
	await c.move("elarien", clampf(p.x + side * 3.0, 2.0, 37.0), p.y, 0.5, Tween.TRANS_QUAD)
	c.face("elarien", -int(side))
	c.music("elf", 1.5)
	await c.say("elarien", "……셋.", "smirk")
	await c.say("sera", "헉… 헉… 닿았다…!", "happy")
	await c.say("elarien", "닿았다. 인정한다.")
	await c.say("sera", "근데… 화살이 한 번도 저를 제대로 안 노렸죠? 일부러.", "surprised")
	await c.say("elarien", "맞히는 건 쉽다. 안 맞히는 게 어렵지.", "smirk")
	await c.say("elarien", "…네 불도 그렇더군. 태우는 건 쉽다. 안 태우는 게 어렵지.")
	await c.say("neoul", "허. 사냥꾼이 철학을 하는구나.")
	c.close_box()
	c.beside("warden_a", -4.0)
	await c.say("warden_a", "엘라리엔! 큰일이다! 아이들이… 피오랑 아이들이 꼭대기로 올라갔어!", "surprised")
	await c.say("elarien", "…뭐?", "surprised")
	await c.say("warden_a", "하얀 것이 꼭대기에서 노래를 불렀다고… 아이들이 홀린 것처럼 따라갔다고!")
	await c.say("elarien", "………", "angry")
	await c.say("elarien", "세라피나. 따라와라. 경기장 꼭대기 계단이다.", "angry")
	c.close_box()
	c.flag("e_fio_gone")
	await c.move("elarien", 17.0, 9.0, 0.6, Tween.TRANS_QUAD)
	c.sfx("door")
	c.hide_actor("elarien")
	c.hide_actor("warden_a")
	c.bubble("서두르자, 세라!", 2.0)


# ═══════════════════════════════════════════════════════════
# 꼭대기 · 백색 사도 (엘라리엔 엄호)
# ═══════════════════════════════════════════════════════════

## 사도전에 지고 돌아오면 동료·결계를 처음 상태로
func _herald_reset(c: Cut) -> void:
	if c.has("e_herald_done"):
		return
	if c.ally("elarien"):
		c.ally_leave("elarien")
	if c.has("e_herald_fight"):
		c.flag("e_herald_fight", false)


func enter_e_crown_1(c: Cut) -> void:
	_herald_reset(c)


func enter_e_crown_2(c: Cut) -> void:
	_herald_reset(c)


func enter_e_crown_nest(c: Cut) -> void:
	_herald_reset(c)


func e_crown_arrive(c: Cut) -> void:
	c.lock()
	await c.wait(0.3)
	await c.say("sera", "꼭대기가… 전부 하얘.", "surprised")
	await c.say("neoul", "…아이들 냄새가 이 위로 이어지는구나. 서두르자, 세라.")
	c.close_box()
	c.save()


func e_herald_begin(c: Cut) -> void:
	if c.has("e_herald_done"):
		return
	var h := c.enemy("white_herald") as WhiteHerald
	if h == null or not h.is_alive():
		await _herald_after(c)
		return
	if h.engaged:
		return
	c.lock()
	c.flag("e_herald_fight")
	var kid := c.spawn_npc("elf_c", 3.0, 19.0, 1)
	kid.emote("sweat", 3.0)
	if not c.has("e_herald_seen"):
		c.flag("e_herald_seen")
		Music.stop(1.0)
		var el := c.spawn_npc("elarien", 5.0, 19.0, 1)
		el.visual.set_pose("kneel")
		await c.camera_to(h.global_position + Vector2(0, -50), 1.2)
		await c.narrate("「……불…… 꺼라…… 숲은…… 잠들어라……」")
		c.close_box()
		var pod := c.actor("pod")
		if pod and pod.has_method("struggle"):
			pod.struggle()
		await c.camera_to(Vector2(68 * 16 + 8, 8 * 16), 0.7)
		await c.say("fio", "누나…! 마녀 누나…!", "sad")
		await c.say("sera", "피오!", "surprised")
		c.close_box()
		await c.camera_back(0.6)
		await c.say("elarien", "…늦었다. 내가.", "hurt")
		await c.say("elarien", "아이들을 감싸다 한 대 맞았다. 다리가… 말을 안 듣는군.", "hurt")
		await c.say("sera", "엘라리엔!", "surprised")
		await c.say("elarien", "괜찮다. 화살 하나 빗나갔을 뿐이다.", "tired")
		await c.say("elarien", "저 위 가지로 오르겠다. 놈의 수정 눈을 쏜다 — 눈이 깨지면 놈이 땅에 떨어진다.", "focus")
		await c.say("elarien", "그때 쳐라. 네 불로.", "focus")
		await c.say("neoul", "…바깥에서 온 것이로구나. 세라, 저건 아귀와 다르다. 굶주림도, 미움도 없다. 그냥 '비어' 있느니라.", "scary")
		c.close_box()
		c.hide_actor("elarien")
	else:
		await c.say("neoul", "다시 가자, 세라. 아이들이 기다린다.")
		c.close_box()
	var a := c.ally_join("elarien", 27.0, 8.0)
	a.mode = "hold"
	a.say("엄호한다.")
	c.music("herald")
	var phase := [1]
	var won := [false]
	h.phase_changed.connect(func(n: int) -> void: phase[0] = n)
	h.defeated.connect(func(_who: Variant) -> void: won[0] = true)
	h.engaged = true
	c.release()
	await c.teach("엘라리엔의 엄호", "엘라리엔이 때때로 사도의 수정 눈을 쏜다 — 눈이 깨지면 사도가 땅에 떨어져 잠시 무방비(피해가 크게 들어감).\n흰 띠(빛창)·육각 감옥은 굵게 깜빡인 뒤 꽂힌다. 띠 밖으로, 감옥 밖으로!", ["attack"])
	var t := 4.0
	var said := 1
	while c.ok() and is_instance_valid(h) and h.is_alive():
		await c.wait(0.5)
		t += 0.5
		if t >= SNIPE_EVERY and is_instance_valid(a):
			t = 0.0
			a.special(h)
		if phase[0] >= 2 and said < 2:
			said = 2
			a.say("눈 하나 더. 버텨라!")
		if phase[0] >= 3 and said < 3:
			said = 3
			c.lock()
			await c.narrate("「……별의…… 그릇……」")
			await c.narrate("「……찾았다……」")
			await c.say("neoul", "……감히.", "scary")
			await c.say("sera", "그릇 아니라니까! 다들 왜 그래!", "angry")
			c.close_box()
			c.release()
	if not c.ok() or not won[0]:
		return
	await _herald_after(c)


func _herald_after(c: Cut) -> void:
	c.lock()
	c.flag("e_herald_done")
	c.flag("e_herald_fight", false)
	Music.stop(2.0)
	await c.wait(2.2)
	var pod := c.actor("pod")
	if pod and pod.has_method("crack"):
		await pod.crack()
	c.spawn_npc("fio", 68.0, 12.0, -1)
	await c.move("fio", 68.0, 19.0, 0.5, Tween.TRANS_QUAD)
	var a := c.ally("elarien")
	if a:
		a.mode = "script"
	c.flash(Color(0.85, 1.0, 0.7, 0.6), 1.2)
	Ch3Sfx.play(&"ch3_purify", 4.0, 0.0)
	_pollen(c)
	c.music("elf", 2.0)
	await c.narrate("사도가 흩어진 자리에서, 세계수 꼭대기의 하양이 녹듯 물러났다. 연둣빛 꽃가루가 비처럼 내렸다.")
	await c.approach("fio", 1.6, 120.0)
	await c.say("fio", "누나아…!", "sad")
	await c.say("sera", "피오! 다친 데 없어?", "surprised")
	await c.say("fio", "하얀 게 노래했어… 별 노래… 따라가면 안 되는 거였는데…", "sad")
	await c.say("sera", "괜찮아. 이제 다 끝났어.", "happy")
	c.close_box()
	if c.ally("elarien"):
		c.ally_leave("elarien")
	c.beside("elarien", -4.0)
	await c.say("elarien", "………")
	await c.say("elarien", "네 불은 숲을 태우지 않는구나.", "happy")
	await c.say("sera", "…응. 이제 나도 알았어.", "happy")
	await c.say("elarien", "세라피나. 숲은 너를 기억할 거다. …나도.", "smirk")
	c.close_box()
	c.flag("e_fio_gone", false)
	await c.fade_out(1.5)
	await c.goto_room("e_elder_hall", "door")
	await _ending_elder(c)


## 끝 1: 장로의 집 — "한 아이는 남고, 한 아이는 별을 보러 떠났지"
func _ending_elder(c: Cut) -> void:
	c.lock()
	c.spawn_npc("elarien", 15.0, 19.0, 1)
	c.spawn_npc("fio", 19.0, 19.0, 1)
	c.player.global_position = Vector2(22 * 16 + 8, 19 * 16)
	c.player_face(1)
	await c.fade_in(1.2)
	await c.say("ortia", "허허… 세계수가 다시 숨을 쉬는구먼. 꽃가루 냄새가 여기까지 나는군.", "happy")
	await c.say("ortia", "고맙네, 세라피나. 그리고 너울 님.", "happy")
	await c.say("neoul", "…흥. 인사는 받아 두마.", "happy")
	await c.say("sera", "장로님. 그 하얀 것이… 저를 '별의 그릇'이라고 불렀어요.", "sad")
	await c.say("ortia", "………", "serious")
	await c.say("ortia", "옛날, 별을 다루는 마녀가 있었네. 자네 학교를 세운 마녀지. 그분에게 두 제자가 있었어.", "serious")
	await c.say("ortia", "한 아이는 남고, 한 아이는 별을 보러 떠났지.", "serious")
	await c.say("sera", "남은 아이가… 교장 선생님?", "surprised")
	await c.say("ortia", "허허. 떠난 아이 이야기는, 언젠가 아스트리드가 직접 해 주겠지.", "happy")
	await c.say("ortia", "학교로 돌아가게. 오늘 밤은 푹 자야 할 얼굴이구먼.", "happy")
	await c.say("fio", "누나, 또 와! 별이 될 씨앗 심는 거 보여 줄게!", "happy")
	await c.say("elarien", "…다음엔 모자 말고 과녁을 맞혀 보자. 활터에서 기다리겠다.", "smirk")
	c.close_box()
	c.save_here("door")
	await c.fade_out(1.5)
	await c.goto_room("s_dorm", "ch3_night")
	await _ending_dorm(c)


## 끝 2: 기숙사의 밤 → 꼬리 셋 → 달 위의 그림자 → 4장
func _ending_dorm(c: Cut) -> void:
	c.lock()
	c.hud(false)
	await c.fade_out(0.01)
	c.music("ending")
	c.player_face(1)
	await c.wait(0.5)
	await c.fade_in(2.0)
	await c.wait(0.6)
	await c.say("sera", "…너울. 자?")
	await c.say("neoul", "…자는 중이니라.")
	await c.say("sera", "별의 그릇이 뭘까.", "sad")
	await c.say("neoul", "……모른다. 하지만 그 하얀 것이 너를 그릇이라 부를 때, 화가 났느니라.")
	await c.say("sera", "너도 맨날 그릇이라고 부르잖아.", "angry")
	await c.say("neoul", "…그래서 화가 났느니라. 세라.", "sad")
	await c.say("sera", "……방금 '세라'라고 했어?", "surprised")
	await c.say("neoul", "잠이나 자거라.", "angry")
	c.close_box()
	c.flag("e_end")
	await c.wait(0.6)
	await c.tails(3)
	await c.say("neoul", "…꼬리가 하나 더 돋았구나. 세계수의 숨이 내 구슬까지 닿았나 보다.", "happy")
	c.close_box()
	await c.fade_out(1.2)
	await c.narrate("그 밤. 학교 위, 아주 높은 곳.")
	c.close_box()
	await Ch3MoonScene.play(c.world, 6.5)
	c.save_here("bed")
	await ChapterFlow.finish(c, 3)
