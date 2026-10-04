extends "res://story/ch3/common.gd"
## 3장 대본 — 학교 인물 3장 덮어쓰기(npc_<who>_ch3) · 이졸데 결투.
## 메서드 이름 = 실행 ID (docs/dev/story.md). 장 공용 상수·도우미는 common.gd.


# ═══════════════════════════════════════════════════════════
# 학교 인물 (3장 덮어쓰기 npc_<who>_ch3) · 서브 퀘스트
# ═══════════════════════════════════════════════════════════

func npc_pippa_ch3(c: Cut) -> void:
	var st := Quests.state("e_pippa_moss")
	var n := Cut.count(MOSS)
	if st == 0 and c.has("e_start"):
		await c.say("pippa", "세라, 세라! 엘프 숲에 간다며? 부탁 하나만!", "happy")
		await c.say("pippa", "세계수 뿌리 쪽에 빛이끼가 자란대. 그걸로 약을 만들면 묘목이 덜 굳을지도 몰라!")
		await c.say("pippa", "표본 세 개! 동굴 같은 데, 축축한 곳에 있을 거야. 부탁해!", "happy")
		c.close_box()
		c.quest_start("e_pippa_moss")
		if n >= 3:
			c.quest_step("e_pippa_moss", 1)
		return
	if st == 1:
		if n >= 3:
			await e_pippa_moss_done(c)
		else:
			await c.say("pippa", "빛이끼는 세계수 뿌리 동굴 어딘가! 숨은 구석도 꼭 봐! (%d/3)" % n)
		return
	if c.has("e_herald_done"):
		await c.say("pippa", "묘목이 다시 초록이 됐어! 잎이 막 반짝여! 네 덕분이야, 세라!", "happy")
	else:
		await c.say("pippa", "묘목은 내가 지키고 있을게. 넌 엘프 숲 잘 다녀와!", "happy")


func e_pippa_moss_done(c: Cut) -> void:
	await c.say("pippa", "우와아! 반짝반짝해! …냄새는 좀 꾸리하지만!", "happy")
	await c.say("pippa", "이거 받아! 연금술 재료 사려고 모은 거지만… 네가 더 잘 쓸 거야.", "happy")
	c.close_box()
	await c.quest_done("e_pippa_moss")


func npc_butterworth_ch3(c: Cut) -> void:
	var st := Quests.state("e_honey")
	if st == 0 and c.has("e_start"):
		await c.say("butterworth", "세라, 엘프 숲에 간다고? 거기 숲 꿀 말이야… 한 숟갈이면 사흘을 버틴단다.", "happy")
		await c.say("butterworth", "구해 오면 기가 막힌 걸 만들어 주마. 꿀은 오래된 벌집에 있지. 그런 건 꼭 숨겨진 데 있더라.")
		c.close_box()
		c.quest_start("e_honey")
		if c.has("e_honey_got"):
			c.quest_step("e_honey", 1)
		return
	if st == 1:
		if c.has("e_honey_got"):
			await e_honey_done(c)
		else:
			await c.say("butterworth", "꿀은 오래된 벌집에 있단다. 사람 발길 안 닿는 숨겨진 곳 말이야.")
		return
	await c.say("butterworth", "숲빵 맛있었지? 배고프면 언제든 오너라.", "happy")


func e_honey_done(c: Cut) -> void:
	await c.say("butterworth", "이 빛깔 좀 봐라! 진짜 숲 꿀이구나!", "happy")
	await c.say("butterworth", "자, 꿀 바른 숲빵이다. 먹고 쑥쑥 크거라!", "happy")
	c.close_box()
	await c.quest_done("e_honey")


func npc_astrid_ch3(c: Cut) -> void:
	if c.has("e_herald_done"):
		await c.say("astrid", "세계수가 꽃을 피웠다고 오르티아에게서 소식이 왔어요. …잘했어요, 세라피나 양.", "happy")
		await c.say("astrid", "그분이 제 이야기를 하던가요? …나쁜 이야기만 아니면 좋겠네요.", "smug")
	elif c.has("e_letter"):
		await c.say("astrid", "숲의 화살은 조심하셨나요? …어머, 모자에 구멍이 났군요.", "smug")
	else:
		await c.say("astrid", "어서 오세요.")


## 학교 결투 대회 (s_duel_cup): 앞마당의 이졸데 → 결투장
func npc_isolde_ch3(c: Cut) -> void:
	var st := Quests.state("s_duel_cup")
	if st == 2:
		await c.say("isolde", "…뭘 봐. 다음엔 내가 이길 거야. 서리 마법 연습 중이니까.", "angry")
		return
	if not c.has("e_letter"):
		await c.say("isolde", "결투 대회 결승. 상대가 너라니. …교장실부터 다녀와. 기다려 줄 테니.", "smug")
		return
	if st == 0:
		await c.say("isolde", "세라. 결투 대회 결승이야. 네가 지하 괴물을 잡았다는 소문 때문에 다들 시끄러워.", "smug")
		await c.say("isolde", "내가 이기면 그 소문, 내 이름으로 바꿔 부르게 할 거야.")
		await c.say("sera", "…그거 그렇게 갖고 싶은 소문이야?", "surprised")
		await c.say("isolde", "시끄러워. 받을 거야, 말 거야?", "angry")
		c.quest_start("s_duel_cup")
	if Quests.active("cls_meteor") and Quests.step("cls_meteor") >= 3 and not GameState.has_ability("meteor"):
		await c.say("isolde", "…결투장은 지금 베로니카 교수님 시험 중이야. 그거 끝나고 와.")
		return
	var pick := await c.choose("isolde", "결투장으로. 지금 바로.", ["붙자", "나중에"])
	if pick != 0:
		await c.say("isolde", "도망치는 건 아니겠지?", "smug")
		return
	await c.say("isolde", "좋아. 봐주지 않아.", "smug")
	c.close_box()
	await c.fade_out(0.6)
	await c.goto_room("s_duel", "in")
	await _isolde_duel(c)


func _isolde_duel(c: Cut) -> void:
	c.lock()
	c.player.global_position = Vector2(20 * 16 + 8, 19 * 16)
	c.player_face(1)
	var b := c.spawn_enemy("isolde_duel", 34.0, 19.0, "isolde_duel", {"engaged": false})
	if b == null:
		return
	b.facing = -1
	var won := [false]
	b.defeated.connect(func(_who: Variant) -> void: won[0] = true)
	await c.wait(0.4)
	await c.say("isolde", "결투 대회 결승. 이졸데 폰 크레스트 — 서리의 고급반.", "smug")
	await c.say("sera", "…일반반 세라피나. 불.", "angry")
	c.close_box()
	c.music("boss")
	b.engaged = true
	c.release()
	await c.wait_enemy(b, 0.5)
	if not c.ok() or not is_instance_valid(b):
		return
	if b.is_alive():
		c.bubble("빙판 질주다! 붉은 띠 밖으로 피하거라!", 2.4)
	await c.wait_enemy(b)
	if not c.ok() or not won[0]:
		return # 쓰러졌거나 결투장을 나감 → 앞마당의 이졸데에게 다시
	c.lock()
	var at := b.global_position / 16.0 if is_instance_valid(b) else Vector2(34, 19)
	await c.wait(0.6)
	c.spawn_npc("isolde", at.x, 19.0, -1 if c.player.global_position.x < at.x * 16.0 else 1)
	c.music("school_day", 2.0)
	await c.say("isolde", "………", "angry")
	await c.say("isolde", "…졌네. 인정해.", "sad")
	await c.say("isolde", "네 불, 예전처럼 막 터지지 않더라. 꼭… 누굴 지키는 것처럼.", "surprised")
	await c.say("sera", "칭찬이야?", "happy")
	await c.say("isolde", "아니거든! 이건 우승 상품. 수호의 깃털. …내가 받으려던 건데.", "angry")
	c.close_box()
	await c.quest_done("s_duel_cup")
	c.flag("s_duel_won")
	c.save()
