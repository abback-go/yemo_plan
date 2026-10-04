extends RefCounted
## 1장 대본 — 마녀학교 S6~S10 — 고급마법반·시계탑·교장실·지하·봉인의 방(아귀)·기숙사의 밤.
## 메서드 이름 = 실행 ID (docs/dev/story.md).


# ─── S6 상층 회랑·고급마법반 ────────────────────────────

func enter_s_gallery(c: Cut) -> void:
	if c.has("s_gallery_seen"):
		return
	c.flag("s_gallery_seen")
	await c.wait(0.6)
	c.bubble("상층이니라. 저 문, 촛대 불이 켜져 있을 때만 열리는 모양이구나.", 3.2)


func enter_s_advclass(c: Cut) -> void:
	if c.has("adv_done") or not c.has("ab_fox_window"):
		return
	var k := c.enemy("armor")
	if k == null:
		await _adv_after(c)
		return
	c.lock()
	if not c.has("adv_met"):
		c.flag("adv_met")
		await c.wait(0.3)
		await c.say("veronica", "물러서라, 이졸데. 이건 수업이 아니다.")
		await c.say("isolde", "제가 막을 수 있어요, 선생님! 빙결의—", "angry")
		c.close_box()
		c.sfx("block", 2.0)
		c.flash(Color(0.6, 0.8, 1.0, 0.4), 0.2)
		await c.say("isolde", "…방패에 튕겨 나가잖아!", "surprised")
		c.emote("isolde", "!")
		c.face("isolde", -1)
		await c.say("isolde", "폐급?! 네가 왜 여기—", "surprised")
		await c.say("sera", "설명은 나중에! 그 갑옷, 정면은 안 통해!", "angry")
		await c.say("neoul", "방패는 앞만 막는다. 뛰어올라 투구를 쏘거나, 발밑에서 불을 피우거라.")
		await c.say("veronica", "…해 봐라, 학생.")
	else:
		await c.say("veronica", "다시 왔군. 이번엔 투구를 노려라.")
	c.close_box()
	c.music("boss")
	c.release()
	await c.wait_enemy(k)
	if not c.ok():
		return
	await _adv_after(c)


func _adv_after(c: Cut) -> void:
	c.lock()
	c.music("school", 2.0)
	await c.wait(1.0)
	await c.say("veronica", "…훌륭하다. 이름이?")
	await c.say("sera", "세라피나요. 일반반이에요.")
	await c.say("veronica", "기억해 두지.")
	c.close_box()
	await c.approach("isolde", 2.0, 70.0)
	c.emote("neoul", "note")
	await c.wait(1.0)
	await c.say("sera", "…이졸데, 너 지금 내 여우 쓰다듬었어?", "smug")
	await c.say("isolde", "…먼지 털어 준 거야.", "angry")
	await c.say("isolde", "그, 그리고! 교장 선생님이 너를 부르셔. 시계탑 꼭대기 교장실로 오래.")
	await c.say("isolde", "…폐급치고는, 나쁘지 않았어.")
	c.close_box()
	await c.say("neoul", "흥. 손길은 나쁘지 않더구나.", "smug")
	await c.say("sera", "…배신자.", "angry")
	c.flag("adv_done")
	c.save()


# ─── S7 시계탑·교장실 ───────────────────────────────────

func enter_s_clock(c: Cut) -> void:
	if c.has("s_clock_seen"):
		return
	c.flag("s_clock_seen")
	await c.wait(0.6)
	if GameState.has_ability("double_jump"):
		c.bubble("톱니 사이로 오르거라. 빗자루가 벽에 박히면 밟을 수 있겠구나.", 3.2)
	else:
		c.bubble("…높구나. 한 번 더 뛸 수 있다면 모를까.", 3.0)


func enter_s_headmaster(c: Cut) -> void:
	if c.has("met_astrid") or not c.has("adv_done"):
		return
	c.lock()
	await c.wait(0.4)
	await c.say("astrid", "어서 오세요, 세라피나 양. 그리고—")
	c.face("astrid", -1)
	await c.say("astrid", "처음 뵙겠습니다… 라고 해 두죠.", "smug")
	await c.say("neoul", "……이 마녀, 나를 보는구나.", "surprised")
	await c.say("sera", "교장 선생님, 저 사실은—")
	await c.say("astrid", "알고 있어요. 지하의 봉인이 흔들리고 있다는 것도, 그 까닭도.")
	await c.say("astrid", "그리고 그것을 다시 잠재울 수 있는 불이, 지금 학생 곁에 있다는 것도요.")
	await c.say("sera", "…혼나는 거 아니에요? 퇴학이라든가…", "sad")
	await c.say("astrid", "퇴학시킬 학생에게 이 열쇠를 드릴 리 없겠죠.", "happy")
	c.close_box()
	c.flag("key_basement")
	await c.item("지하실 열쇠", "앞마당의 지하 철문을 연다.")
	await c.say("astrid", "봉인의 방은 지하 저장고 너머, 봉인 회랑의 끝에 있어요.")
	await c.say("astrid", "회랑의 불에는 순서가 있답니다. 참모습을 보는 눈이라면 읽을 수 있을 거예요.")
	await c.say("astrid", "교사들은 위에서 결계를 붙잡고 있겠어요. 굶주린 것은… 푸른 불을 두려워하니까요.")
	await c.say("neoul", "흥. 수백 년 전 그 마녀와 눈빛이 똑같구나.")
	c.close_box()
	c.flag("met_astrid")
	c.save()
	c.bubble("시계탑의 왼쪽 벽… 저것도 환영이니라. 돌아갈 땐 그리로 가자꾸나.", 3.4)


# ─── S8 지하 ────────────────────────────────────────────

func enter_s_cellar(c: Cut) -> void:
	if c.has("s_cellar_seen"):
		return
	c.flag("s_cellar_seen")
	await c.wait(0.6)
	c.bubble("이 냄새… 굶주린 것이 가깝구나.", 2.6)


func s_seal_puzzle_hint(c: Cut) -> void:
	if c.has("seal_open"):
		return
	await c.say("neoul", "결계 안이니라. 여기선 네 폭주도 잠잠하겠구나.")
	await c.say("neoul", "봉인의 불은 순서대로 켜야 한다. 벽 어딘가에 새겨 두었을 게야 — 눈으로는 안 보이게.")
	c.close_box()


# ─── S9 봉인의 방: 아귀 ─────────────────────────────────

func s_agwi(c: Cut) -> void:
	if c.has("agwi_defeated"):
		return
	var a := c.enemy("agwi")
	var seal := c.actor("seal")
	if a == null:
		await _ending(c, seal)
		return
	if not c.has("agwi_met"):
		c.flag("agwi_met")
		Music.stop(1.0)
		await c.camera_to(a.global_position + Vector2(-40, -30), 1.0)
		if seal:
			seal.set_power(1.0, 1.0)
			seal.pulse(1.0)
		c.sfx("chain", 2.0)
		c.shake(0.2, 1.2)
		await c.wait(1.0)
		c.freeze_enemies(false)
		c.sfx("roar", 4.0)
		await c.wait(0.6)
		c.freeze_enemies(true)
		await c.narrate("「배… 고… 파……」")
		await c.narrate("「푸른… 불… 냄새…… 먹… 고… 싶어……」")
		c.vignette(0.5)
		await c.say("neoul", "굶주린 것아. 그 아이는 내 그릇이다. 손대지 마라.", "scary")
		c.vignette(0.0)
		await c.say("sera", "그릇이라고 부르지 말랬지! …하지만 이번만 봐줄게.", "angry")
		await c.say("neoul", "저것은 푸른 불을 두려워한다. 폭주가 차오르면 — 내게 맡겨라.")
		c.close_box()
		await c.camera_back(0.6)
	else:
		await c.say("neoul", "다시 가자, 세라. 굶주린 것을 재우러.")
		c.close_box()
	c.music("boss")
	a.engaged = true
	c.release()
	await c.wait_enemy(a, 0.5)
	if not c.ok():
		return
	if is_instance_valid(a) and a.is_alive():
		c.sfx("chain", 4.0)
		c.shake(0.3, 1.0)
		c.bubble("사슬이 끊어진다! 조심하거라!", 2.4)
	await c.wait_enemy(a)
	if not c.ok():
		return
	await _ending(c, seal)


func _ending(c: Cut, seal: Node) -> void:
	c.lock()
	c.flag("agwi_defeated")
	Music.stop(2.0)
	await c.wait(2.0)
	if seal:
		seal.set_power(0.0, 2.0)
		seal.pulse(1.0)
	c.flash(Color(0.6, 0.85, 1.0, 0.7), 1.0)
	c.sfx("fox_end")
	await c.say("neoul", "잠들거라, 굶주린 것아. 이번엔 배부르게.", "sad")
	c.close_box()
	c.music("ending", 2.0)
	await c.wait(1.0)
	c.sfx("door")
	c.spawn_npc("emberlyn", 2.0, 19.0, 1)
	c.spawn_npc("astrid", 1.0, 19.0, 1)
	await c.walk("emberlyn", 10.0, 90.0)
	await c.say("emberlyn", "세라!", "surprised")
	c.close_box()
	await c.walk("astrid", 7.0, 60.0)
	await c.say("astrid", "…봉인이 다시 다져졌군요. 푸른 불로.")
	await c.say("emberlyn", "너… 이걸 혼자?", "surprised")
	await c.say("sera", "혼자는 아니에요.", "happy")
	c.emote("neoul", "note")
	await c.say("astrid", "이번 일은 교사들의 결계 실습 중에 생긴 사고로 처리하겠습니다. 학생은 아무것도 보지 못했어요. 그렇죠?", "smug")
	await c.say("sera", "…네! 아무것도요!", "happy")
	await c.say("emberlyn", "(작게) …폐급이라니. 누가 그런 소리를.", "happy")
	c.close_box()
	await c.fade_out(1.5)
	await c.narrate("그날 밤.")
	c.close_box()
	await c.goto_room("s_dorm", "bed")


# ─── S10 에필로그: 기숙사의 밤 ──────────────────────────

func enter_s_dorm(c: Cut) -> void:
	if not c.has("agwi_defeated") or c.has("chapter_end"):
		return
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
	await c.say("sera", "나… 진짜 폐급 아니야?", "sad")
	await c.say("neoul", "……")
	await c.say("neoul", "네 마력은 폐급이 아니니라. 그릇이 아직 덜 자랐을 뿐.")
	await c.say("neoul", "그릇이 자랄 때까지… 넘치는 건 내가 받아 주마. 구슬을 되찾을 때까지만이다.")
	await c.say("sera", "…응. 고마워.", "happy")
	await c.say("neoul", "그리고 배고프다. 내일 아침엔 식당의 그 국자 든 마녀에게 가자꾸나.")
	await c.say("sera", "버터워스 아주머니? …하하, 알았어.", "happy")
	c.close_box()
	await c.fade_out(2.0)
	c.flag("chapter_end")
	c.save_here("bed")
	# 1장 끝 → 너울·저장 → "2장" 카드 → ch2_start (ChapterFlow, docs/systems2.md 7절)
	await ChapterFlow.finish(c, 1)
