extends RefCounted
## 공통 시스템 대본 — 수업 게시판 안내, 마법 수업 4종(불꽃 날개·불꽃 방벽·유성 낙화·불사조), 1장 끝 기록 이어하기.
## 수업 정의는 story/data_sys.gd (QUESTS), 방은 tools/rooms/sys.py. 흐름은 docs/magic.md 4절.
## 인물 말투: 오필리아 "~란다~" 몽롱 · 엠버린 따뜻하고 엄격 · 베로니카 냉철하고 짧게 · 그레타 과묵 · 아스트리드 존댓말(가끔 장난).


# ─── 1장 끝 기록으로 이어하기 ────────────────────────────

## 예전 기록(1장 데모 끝 화면에서 이어한 것)을 2장으로 넘김
func sys_chapter1_resume(c: Cut) -> void:
	if c.has("ch1_done"):
		return
	c.lock()
	await c.wait(0.5)
	await c.say("neoul", "…세라. 푹 잤느냐. 이 학교에 새 바람이 부는 냄새가 나는구나.")
	c.close_box()
	await ChapterFlow.finish(c, 1)


# ─── 수업 게시판 ─────────────────────────────────────────

func sys_board_intro(c: Cut) -> void:
	c.flag("sys_board_seen")
	c.lock()
	var board := Vector2(27 * 16 + 8, 42 * 16)
	await c.camera_to(board + Vector2(0, -30), 0.7)
	c.emote("neoul", "!")
	await c.say("neoul", "세라, 저 게시판이 반짝이는구나. 무어라 쓰여 있느냐?")
	await c.say("sera", "실기 수업 게시판! 듣고 싶은 수업을 여기서 신청하는 거야.", "happy")
	await c.say("sera", "수업을 끝까지 마치면… 새 마법을 정식으로 배울 수 있어.")
	await c.say("neoul", "흥. 마법이야 내 구슬이 다 해 주는 것을. …뭐, 배워 두면 나쁠 건 없지.")
	c.close_box()
	await c.camera_back(0.5)
	await c.teach("마법 배우기", "중앙 홀의 수업 게시판 앞에서 ↑ — 들을 수 있는 수업을 골라 신청한다.\n수업(퀘스트)을 마치면 새 마법을 배운다. 수업은 한 번에 하나.\n진행 중인 수업은 일시정지 → 퀘스트 → 수업 칸에서 볼 수 있다.", ["move_up"])


# ═══════════════════════════════════════════════════════════
# 불꽃 날개 (중급) — 오필리아 · 바람의 탑
# ═══════════════════════════════════════════════════════════

func cls_wings_begin(c: Cut) -> void:
	c.bubble("오필리아라는 그 잠꾸러기 마녀에게 가 보자꾸나. 비속성마법반이었지.", 3.0)


func cls_wings_lesson(c: Cut) -> void:
	await c.approach("ophelia", 3.0, 80.0)
	await c.say("ophelia", "어머~ 세라~ 날개 수업을 신청했구나~", "happy")
	await c.say("ophelia", "부양이 무게를 잠깐 잊는 거라면~ 날개는… 바람을 기억하는 거란다~")
	await c.say("sera", "바람을… 기억해요?")
	await c.say("ophelia", "떨어질 때 무서워서 몸을 웅크리면 그냥 떨어지지~ 대신 팔을 활짝 펴고, 불을 등 뒤로 흘려 보내면~")
	c.emote("ophelia", "note")
	await c.say("ophelia", "…훨훨~ 바람이 받아 준단다~ 특히 아래에서 위로 부는 바람은~ 쭈욱 위로~", "happy")
	await c.say("neoul", "말이 길구나. 요컨대 떨어질 때 날개를 펴라는 게지.")
	c.close_box()
	c.flag("temp_wings")
	await c.item("연습용 날개깃", "공중에서 점프를 다시 길게 누르고 있으면 불꽃 날개로 활공한다. (수업 동안 빌린 것)")
	await c.teach("불꽃 날개 (연습)", "공중에서 점프를 다시 누르고 있으면 활공한다.\n위로 부는 바람(상승 기류) 안에서 활공하면 높이 솟아오른다.", ["jump"])
	await c.say("ophelia", "부양 실습실 왼쪽 끝에 '바람의 탑' 문을 열어 두었어~ 꼭대기까지 등불 다섯 개를 밝히면 합격~")
	await c.say("ophelia", "나는 꼭대기에서… 기다릴게… 쿨…", "happy")
	c.close_box()
	c.flag("cls_wings_open")
	c.quest_step("cls_wings", 1)
	c.save()


func enter_s_windtower(c: Cut) -> void:
	if c.has("windtower_intro") or c.has("windtower_done"):
		return
	c.flag("windtower_intro")
	c.lock()
	await c.wait(0.3)
	await c.camera_to(c.player.global_position + Vector2(0, -260), 1.6)
	c.sfx("wind", -2.0)
	await c.say("sera", "우와… 탑 안에 바람이 기둥처럼 불어…", "surprised")
	await c.camera_back(1.0)
	await c.say("neoul", "점프하고, 떨어지려 할 때 다시 눌러 날개를 펴거라. 바람 기둥에 몸을 맡기면 된다.")
	c.close_box()


func cls_wings_tower_done(c: Cut) -> void:
	await c.wait(0.5)
	c.lock()
	c.sfx("bell", 2.0)
	c.flash(Color(0.85, 0.8, 1.0, 0.5), 0.5)
	await c.wait(0.8)
	var p := c.player_tile()
	c.spawn_npc("ophelia", p.x + 3.0, p.y - 8.0, -1)
	await c.move("ophelia", p.x + 3.0, p.y, 1.4, Tween.TRANS_QUAD)
	await c.say("ophelia", "띵동~ 종이 울렸네~ 합격이란다~", "happy")
	await c.say("ophelia", "바람을 기억했구나~ 이제 그 날개는 빌린 게 아니라 세라 거야~")
	c.close_box()
	c.flag("temp_wings", false)
	await c.spell_learned("wings")
	await c.quest_done("cls_wings")
	await c.say("ophelia", "그리고 이거~ 바람에 실려 온 마도석이야~ 마법서에서 마법을 더 단단하게 다듬을 수 있단다~")
	await c.say("sera", "마법서… 일시정지해서 보는 그거요?")
	await c.say("ophelia", "응~ 등급이 높은 마법일수록 마도석이 많이 들지~ 아껴 쓰렴~")
	c.close_box()
	c.save()


# ═══════════════════════════════════════════════════════════
# 불꽃 방벽 (중급) — 엠버린 · 실습장
# ═══════════════════════════════════════════════════════════

func cls_ward_begin(c: Cut) -> void:
	c.bubble("방벽이라. 막을 줄도 알아야지. 엠버린은 실습장에 있겠구나.", 3.0)


func cls_ward_lesson(c: Cut) -> void:
	await c.approach("emberlyn", 3.0, 80.0)
	await c.say("emberlyn", "왔구나. 레오니 발렌하르트와 붙었다고 들었다.")
	await c.say("emberlyn", "…검 한 번 막지 못했다는 얼굴이구나.", "smug")
	await c.say("sera", "막을 틈이 없었어요! 칼이 안 보였다고요…", "sad")
	await c.say("emberlyn", "그래서 이 수업이 있는 거다. 불은 쏘기만 하는 게 아니야. 두를 수도 있지.")
	await c.say("emberlyn", "몸 둘레에 아주 짧게 — 숨 한 번 사이만큼 — 불의 원을 세워라. 그 안에선 무엇도 너를 다치게 못 한다.")
	await c.say("emberlyn", "날아오는 건 되돌려 보내고, 다가오는 건 데게 한다. 그게 방벽이다.")
	c.close_box()
	c.flag("temp_ward")
	Spells.equip("s", "ward")
	await c.teach("불꽃 방벽 (연습)", "S 칸에 방벽을 끼웠다. S — 잠깐 불의 원을 두른다.\n그동안 다치지 않고, 날아온 탄은 되쏜다. 닿은 적은 불에 덴다.\n(마법서에서 A·S 칸을 언제든 바꿔 끼울 수 있다)", ["skill_2"])
	await c.say("emberlyn", "발사대 셋을 깨웠다. 마력탄이 날아오면, 닿기 직전에 방벽을 세워 되쳐라.")
	await c.say("emberlyn", "과녁은 발사대 바로 앞에 있다. 되돌아간 탄만 과녁을 밝힐 수 있어. 셋 다 밝혀라.")
	c.close_box()
	c.flag("ward_trial_on")
	c.quest_step("cls_ward", 1)


func cls_ward_targets_done(c: Cut) -> void:
	await c.wait(0.4)
	c.lock()
	c.sfx("ignite", 2.0)
	await c.say("emberlyn", "좋다. 셋 다.", "happy")
	await c.say("emberlyn", "이제 실전이다. 내 화염구 열 발. 피하지 말고 — 막든 되쏘든 전부 받아 내라.")
	c.close_box()
	c.quest_step("cls_ward", 2)
	await _ward_duel(c)


## 진행 중 다시 말을 걸면 (쓰러졌다 돌아왔을 때 등)
func cls_ward_duel(c: Cut) -> void:
	await c.say("emberlyn", "다시 간다. 열 발이다.")
	c.close_box()
	await _ward_duel(c)


func _ward_duel(c: Cut) -> void:
	var em := c.actor("emberlyn") as Node2D
	if em == null:
		return
	# 관람석에서 내려와 세라와 같은 바닥에 선다
	if em.global_position.y < 19 * 16 - 4:
		await c.move("emberlyn", 68.0, 19.0, 0.5, Tween.TRANS_QUAD)
		c.sfx("land")
	c.face("emberlyn", -1 if c.player.global_position.x < em.global_position.x else 1)
	c.release()
	var blocked := 0
	await c.wait(1.0)
	while blocked < 10 and c.ok():
		if not is_instance_valid(em):
			return
		var side := -1.0 if c.player.global_position.x < em.global_position.x else 1.0
		c.face("emberlyn", int(side))
		var from := em.global_position + Vector2(side * 10.0, -22)
		var pr := EnemyProjectile.new()
		pr.setup(from, c.player.center() - from, 150.0, "fireball", {"radius": 5.0, "life": 4.0, "hits_world": false})
		Fx.effect_parent().add_child(pr)
		c.sfx("shoot", -2.0)
		var hp0 := GameState.hp
		var wr: WeakRef = weakref(pr)
		while c.ok():
			var o: EnemyProjectile = wr.get_ref()
			if o == null or o.reflected:
				break
			await c.world.get_tree().physics_frame
		if not c.ok():
			return
		var o2: EnemyProjectile = wr.get_ref()
		if o2 != null and o2.reflected:
			blocked += 1
			Story.toast("막았다! %d / 10" % blocked, 1.2)
		elif GameState.hp < hp0:
			c.bubble("방벽을 세워라! 닿기 직전에!", 1.6)
		else:
			c.bubble("피하지 말고 막아라!", 1.6)
		await c.wait(2.8)
	if not c.ok():
		return
	c.lock()
	await c.wait(0.6)
	await c.say("emberlyn", "…열 발 전부.", "surprised")
	await c.say("emberlyn", "레오니에게 가서 전해라. 다음엔 그쪽 검이 튕겨 나갈 거라고.", "happy")
	c.close_box()
	c.flag("temp_ward", false)
	await c.spell_learned("ward")
	await c.quest_done("cls_ward")
	await c.say("emberlyn", "방벽은 쓰고 나면 숨 고를 시간이 필요하다. 아무 때나 세우지 말고, 날아오는 걸 봐라.")
	c.close_box()
	c.save()


# ═══════════════════════════════════════════════════════════
# 유성 낙화 (고급) — 오필리아의 별 관측 · 베로니카의 제어 시험과 결투
# ═══════════════════════════════════════════════════════════

func cls_meteor_begin(c: Cut) -> void:
	c.bubble("유성이라… 먼저 별을 읽으라 했지. 오필리아에게 가 보자꾸나.", 3.0)


func cls_meteor_lesson(c: Cut) -> void:
	await c.approach("ophelia", 3.0, 80.0)
	await c.say("ophelia", "유성 낙화~ 고급 마법이네~ 베로니카 선생님 수업이지만~ 첫 시간은 내 몫이란다~", "happy")
	await c.say("ophelia", "별을 떨어뜨리려면~ 먼저 별이 어디 있는지 알아야 하거든~")
	await c.say("ophelia", "오늘 밤~ 시계탑 지붕에서 만나자~ 별 관측 수업이야~")
	c.close_box()
	c.flag("cls_meteor_roof")
	c.quest_step("cls_meteor", 1)
	await c.fade_out(1.0)
	await c.narrate("그날 밤 — 시계탑 지붕.")
	c.close_box()
	await c.goto_room("s_observatory", "down")
	await c.fade_in(1.0)


func enter_s_observatory(c: Cut) -> void:
	if c.has("stars_done") or c.has("obs_intro") or Quests.step("cls_meteor") != 1:
		return
	c.flag("obs_intro")
	c.lock()
	await c.wait(0.4)
	await c.camera_to(Vector2(320, 90), 1.4)
	await c.say("sera", "…하늘이 이렇게 가까웠나.", "surprised")
	await c.say("ophelia", "저기 보이니~ 별 일곱 개~ 거문고자리란다~")
	await c.say("ophelia", "옛날 옛적에~ 별을 너무 사랑해서 별이 되고 싶었던 마녀가 있었대~ 그 마녀 이름을 딴 별자리야~ '리라'~")
	await c.camera_back(0.8)
	await c.say("ophelia", "가장 밝은 별~ 왼쪽의 베가부터~ 화염탄으로 콕콕~ 순서대로 이어 보렴~")
	await c.say("ophelia", "순서가 틀리면 별들이 토라져서 다 꺼진단다~ 굴뚝이랑 발판에 올라가서 쏘면 닿을 거야~")
	await c.say("neoul", "…별을 사랑한 마녀라. 흥.")
	c.close_box()


func cls_meteor_stars_done(c: Cut) -> void:
	await c.wait(0.8)
	c.lock()
	c.sfx("star_burst", 2.0)
	c.flash(Color(1.0, 0.95, 0.7, 0.4), 0.6)
	await c.camera_to(Vector2(320, 90), 1.0)
	await c.wait(0.6)
	await c.say("ophelia", "어머어머~ 다 이었네~ 리라가 반짝반짝~", "happy")
	await c.camera_back(0.8)
	await c.say("ophelia", "별을 읽을 줄 알게 됐으니~ 이제는 별을 붙드는 손을 배울 차례야~")
	await c.say("ophelia", "그건 베로니카 선생님 몫이란다~ …조금 무섭지만~ 고급마법반으로 가 보렴~")
	c.close_box()
	c.emote("neoul", "...")
	await c.say("neoul", "…세라. 저 별들 사이에 무언가 우리를 내려다보는 것 같지 않느냐.")
	await c.say("sera", "에이, 별이잖아.")
	await c.say("neoul", "…그렇겠지.")
	c.close_box()
	c.quest_step("cls_meteor", 2)
	c.save()


func cls_meteor_veronica(c: Cut) -> void:
	await c.approach("veronica", 3.0, 80.0)
	await c.say("veronica", "오필리아가 보냈나.")
	await c.say("veronica", "유성 낙화. 모든 마력을 하늘에 바치는 마법이다. 쓰고 나면 바닥난 채로 땅에 서 있어야 해.")
	await c.say("veronica", "넘치는 힘을 붙들지 못하는 자는 하늘이 아니라 제 발밑에 별을 떨어뜨린다.")
	await c.say("veronica", "…결투장으로 내려와라. 네 폭주부터 본다.")
	c.close_box()
	c.flag("cls_meteor_duel_ok")
	c.quest_step("cls_meteor", 3)
	c.bubble("저 계단이 결투장으로 가는 길이구나.", 2.4)


func enter_s_duel(c: Cut) -> void:
	if GameState.has_ability("meteor") or not Quests.active("cls_meteor"):
		return
	var st := Quests.step("cls_meteor")
	if st == 4:
		c.lock()
		await c.say("veronica", "다시.")
		c.close_box()
		await _meteor_duel(c)
		return
	if st != 3 or c.has("control_on"):
		return
	c.lock()
	await c.wait(0.4)
	await c.say("veronica", "폭주 게이지. 70에서 95 사이에 붙들어라. 합쳐서 20초.")
	await c.say("veronica", "과녁을 쳐서 끌어올려라. 100이 되어 터지면 처음부터다.")
	await c.say("veronica", "모자라면 채우고, 넘칠 것 같으면 멈춰라. 그게 '붙든다'는 거다.")
	c.close_box()
	c.flag("control_on")


func cls_meteor_control_done(c: Cut) -> void:
	await c.wait(0.5)
	c.lock()
	c.sfx("ignite", 0.0)
	await c.say("veronica", "…제법이군.")
	await c.say("veronica", "그 붙든 손으로 — 나를 쳐 봐라. 그림자는 봐주지 않는다.")
	c.close_box()
	c.quest_step("cls_meteor", 4)
	c.save()
	await _meteor_duel(c)


func _meteor_duel(c: Cut) -> void:
	var nx := 70.0
	var v := c.actor("veronica") as Node2D
	if v:
		nx = v.global_position.x / 16.0
	c.hide_actor("veronica")
	var b := c.spawn_enemy("veronica_duel", nx, 19.0, "veronica_duel", {"engaged": false, "respawns": true})
	if b == null:
		return
	c.music("boss")
	await c.wait(0.6)
	b.engaged = true
	c.release()
	await c.wait_enemy(b, 0.5)
	if not c.ok():
		return
	if is_instance_valid(b) and b.is_alive():
		c.bubble("그림자 손이다! 붉은 선을 피하거라!", 2.2)
	await c.wait_enemy(b)
	if not c.ok():
		return
	c.lock()
	var at := b.global_position / 16.0 if is_instance_valid(b) else Vector2(60, 19)
	await c.wait(0.6)
	c.spawn_npc("veronica", at.x, 19.0, -1 if c.player.global_position.x < at.x * 16.0 else 1)
	c.music("school", 2.0)
	await c.say("veronica", "…졌군. 오랜만이야, 이 감각.")
	await c.say("veronica", "폐급이라는 말. 처음 꺼낸 건 내가 아니지만, 바로잡지도 않았다.")
	await c.say("veronica", "…정정한다. 넌 하늘을 다룰 수 있는 마녀다.")
	await c.say("sera", "…교수님.", "happy")
	await c.say("veronica", "착각하지 마라. 별을 떨어뜨린 뒤의 너는 텅 빈다. 쓸 때를 골라라.")
	c.close_box()
	await c.spell_learned("meteor")
	await c.quest_done("cls_meteor")
	await c.teach("유성 낙화", "F (패드 R3) — 하늘로 떠올라 넓은 범위에 유성을 쏟는다. 떠오르는 동안 다치지 않는다.\n재사용 대기가 아주 길다(40초). 쓰면 폭주 게이지가 0이 된다.", ["skill_3"])
	c.save()


# ═══════════════════════════════════════════════════════════
# 불사조 (고급 · 금서) — 그레타 · 아스트리드 서명 · 재의 서고 · 둥지 · 불 속의 나
# ═══════════════════════════════════════════════════════════

func cls_phoenix_begin(c: Cut) -> void:
	c.bubble("금서라… 먼저 사서 그레타에게 열람을 부탁해야겠구나.", 3.0)


func cls_phoenix_lesson(c: Cut) -> void:
	await c.approach("greta", 3.0, 80.0)
	await c.say("sera", "그레타 선생님, 불사조… 그 책을 보고 싶어요.")
	await c.say("greta", "…불사조.")
	await c.say("greta", "…금서다.")
	await c.say("greta", "교장 선생님 서명. …가져오면, 열어 주지.")
	await c.say("hodu", "호우.")
	c.close_box()
	c.quest_step("cls_phoenix", 1)
	c.bubble("교장실은 시계탑 꼭대기였지.", 2.4)


func cls_phoenix_sign(c: Cut) -> void:
	await c.approach("astrid", 3.0, 70.0)
	await c.say("astrid", "불사조… 그 책을 찾는 학생이 다시 나타날 줄은 몰랐네요.")
	await c.say("astrid", "창립자께서 그 책을 금서로 묶으신 이유를 아시나요?")
	await c.say("astrid", "그 불은 쓰는 사람을 먼저 한 번 태웁니다. 재가 된 자기 자신을 이겨 낸 사람만이 다시 일어나지요.")
	await c.say("sera", "…자기 자신을요?")
	await c.say("astrid", "네. 세상에서 가장 이기기 어려운 상대랍니다.")
	c.close_box()
	c.emote("astrid", "...")
	await c.wait(0.6)
	await c.say("astrid", "…세라 학생이라면 괜찮을 거라고, 해 두죠.", "happy")
	c.close_box()
	c.sfx("page", 0.0)
	await c.item("교장의 서명", "금서 구역 안쪽 '재의 서고'를 열람해도 좋다는 허락.")
	c.emote("neoul", "...")
	await c.say("neoul", "(…저 손. 서명하는 손이 떨리고 있구나.)")
	c.close_box()
	c.flag("cls_phoenix_sign")
	c.quest_step("cls_phoenix", 2)
	c.save()


func enter_s_ashstacks(c: Cut) -> void:
	if c.has("ash_done") or c.has("ash_intro"):
		return
	c.flag("ash_intro")
	c.lock()
	await c.wait(0.4)
	await c.say("sera", "…깜깜해. 책이 전부 타 버렸어.", "surprised")
	await c.say("neoul", "이 어둠은 빛을 먹는구나. 촛불이 꺼지기 전에 다음 촛불을 화염탄으로 밝히거라.")
	await c.say("neoul", "꺼지면 재가 길을 지운다. 처음부터니라.")
	c.close_box()


func cls_phoenix_ash_done(c: Cut) -> void:
	await c.wait(0.5)
	c.lock()
	c.sfx("door", 0.0)
	await c.say("neoul", "마지막 촛불이다. 문 너머에서… 뜨거운 숨결이 느껴지는구나.")
	c.close_box()
	c.quest_step("cls_phoenix", 3)
	c.save()


func enter_s_phoenix(c: Cut) -> void:
	if GameState.has_ability("phoenix") or not Quests.active("cls_phoenix"):
		return
	var st := Quests.step("cls_phoenix")
	if st == 4:
		c.lock()
		await c.say("neoul", "다시 가자, 세라. 이번엔 이겨라.")
		c.close_box()
		await _shadow_fight(c)
		return
	if st != 3:
		return
	c.lock()
	await c.wait(0.4)
	await c.camera_to(Vector2(20 * 16 + 8, 19 * 16 - 40), 1.0)
	await c.say("sera", "알…? 불타고 있는 알이야.", "surprised")
	await c.say("neoul", "불사조의 알이다. 수백 년 동안 한 번도 꺼진 적 없는 불이지.")
	c.sfx("growl", -2.0)
	await c.say("neoul", "…그리고 그 불을 노리는 것들이 오는구나. 재가 된 것들이.")
	await c.camera_back(0.6)
	await c.say("neoul", "알 곁을 지켜라. 그림자가 알에 들러붙으면 불이 줄어든다. 네가 곁에 있으면 조금씩 다시 차오른다.")
	c.close_box()
	await _egg_defense(c)


func _clear_enemies(c: Cut) -> void:
	for e in c.world.room.enemies:
		if is_instance_valid(e) and e.is_alive():
			e.queue_free()
	c.world.room.enemies = c.world.room.enemies.filter(func(e: Variant) -> bool: return is_instance_valid(e) and not e.is_queued_for_deletion())


func _egg_defense(c: Cut) -> void:
	var egg := c.world.get_tree().get_first_node_in_group(&"phoenix_egg") as Node2D
	if egg == null:
		return
	const LEN := 120.0
	c.music("boss")
	c.release()
	var t := 0.0
	var next_spawn := 2.0
	var n := 0
	while c.ok():
		await c.world.get_tree().physics_frame
		if not c.ok() or not is_instance_valid(egg):
			return
		var d := c.world.get_physics_process_delta_time()
		if Story.busy_count() <= 1:
			t += d
		egg.set("progress", t / LEN)
		if float(egg.get("flame")) <= 0.0:
			# 실패: 알의 불이 꺼져 간다 → 처음부터
			c.lock()
			_clear_enemies(c)
			c.sfx("crumble", 0.0)
			await c.say("neoul", "알의 불이 꺼져 간다! …세라, 다시 불을 지펴라. 처음부터니라!", "angry")
			c.close_box()
			egg.set("flame", 100.0)
			t = 0.0
			next_spawn = 2.0
			c.release()
			continue
		if t >= LEN:
			break
		next_spawn -= d
		var alive := 0
		for e in c.world.room.enemies:
			if is_instance_valid(e) and e.is_alive():
				alive += 1
		if next_spawn <= 0.0 and alive < 7:
			var k := t / LEN
			var count := 1 if k < 0.3 else (2 if k < 0.7 else 3)
			for i in count:
				n += 1
				var left := (n % 2) == 0
				if k > 0.35 and i == count - 1:
					c.spawn_enemy("ash_moth", randf_range(6.0, 33.0), 3.0, "moth_%d" % n, {"respawns": true})
				else:
					c.spawn_enemy("ash_shade", 2.0 if left else 37.0, 19.0, "shade_%d" % n, {"respawns": true})
			next_spawn = lerpf(7.0, 4.5, k)
		if absf(fmod(t, 30.0) - 0.0) < d and t > 1.0:
			Story.toast("부화까지 %d초" % int(round(LEN - t)), 1.6)
	if not c.ok():
		return
	c.lock()
	_clear_enemies(c)
	c.flag("egg_done")
	c.quest_step("cls_phoenix", 4)
	c.save()
	await c.wait(0.6)
	# 알이 깨지고 — 불길이 세라를 삼킨다
	c.sfx("ignite", 4.0)
	c.shake(0.3, 1.2)
	await c.wait(0.6)
	c.flash(Color(1.0, 0.6, 0.2, 0.9), 0.8)
	if is_instance_valid(egg):
		egg.queue_free()
	c.burst(Vector2(20 * 16 + 8, 19 * 16 - 14), 60, Palette.FIRE_HOT, {spread = 180.0, speed_min = 60.0, speed_max = 260.0, lifetime = 0.9})
	await c.say("sera", "앗 뜨— …뜨겁지 않아?", "surprised")
	await c.say("neoul", "세라! 불이 너를— 세라!!", "angry")
	c.close_box()
	await _shadow_fight(c)


func _shadow_fight(c: Cut) -> void:
	c.lock()
	c.tint(Color(1.0, 0.35, 0.1, 0.22), 1.0)
	c.vignette(0.5)
	await c.wait(1.0)
	var p := c.player_tile()
	var sx := 30.0 if p.x < 20.0 else 9.0
	var b := c.spawn_enemy("shadow_sera", sx, 19.0, "shadow_sera", {"engaged": false, "respawns": true})
	if b == null:
		return
	await c.wait(0.8)
	await c.say("shadow_sera", "폐급.")
	await c.say("shadow_sera", "넌 아무것도 못 해. 너울이 없으면. 교수님들이 없으면. 친구들이 없으면.")
	await c.say("shadow_sera", "그 불도 네 것이 아니잖아. 빌린 구슬. 빌린 날개. 빌린 이름.")
	await c.say("sera", "…….", "sad")
	await c.say("sera", "맞아. 나 혼자서는 못 해.", "sad")
	await c.say("sera", "그래서 혼자 안 하기로 했어. 그게 내가 찾은 내 불이야.", "angry")
	c.close_box()
	c.music("boss")
	b.engaged = true
	c.release()
	await c.wait_enemy(b, 0.5)
	if not c.ok():
		return
	if is_instance_valid(b) and b.is_alive():
		c.bubble("세라, 들리느냐! 붉은 고리가 크면 물러나거라!", 2.4)
	await c.wait_enemy(b)
	if not c.ok():
		return
	c.lock()
	var at := b.global_position / 16.0 if is_instance_valid(b) else Vector2(20, 19)
	await c.wait(0.8)
	c.tint(Color(1.0, 0.8, 0.4, 0.0), 1.5)
	c.vignette(0.0)
	await c.say("shadow_sera", "……그럼, 같이 가.")
	c.close_box()
	c.burst(Vector2(at.x * 16.0 + 8.0, at.y * 16.0 - 16.0), 50, Color(1.0, 0.85, 0.5),
		{spread = 180.0, speed_min = 30.0, speed_max = 160.0, lifetime = 1.0, gravity = Vector2(0, -60)})
	c.sfx("phoenix_cry", 2.0)
	c.flash(Color(1.0, 0.85, 0.5, 0.8), 1.0)
	await c.wait(1.0)
	await c.say("neoul", "…세라. 너, 지금 등 뒤에— 불사조가.", "surprised")
	await c.say("sera", "응. 따뜻해.", "happy")
	c.close_box()
	c.music("school", 2.0)
	await c.spell_learned("phoenix")
	await c.quest_done("cls_phoenix")
	await c.teach("불사조", "F (패드 R3) — 거대한 불사조가 화면을 세 번 가르고, 체력을 회복한다.\n재사용 대기 60초. 고급 마법은 F 칸에 하나만 끼울 수 있다(마법서에서 바꾸기).", ["skill_3"])
	c.save()
