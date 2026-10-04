extends RefCounted
## 1장 대본 — 마녀학교 S1~S3 — 의무실·동관·중앙 홀·마법반·실습장(골렘).
## 대본: 마녀학교 본편 (docs/chapter1.md 2절 S1~S10, 12절).
## enter_<방ID>는 방에 들어올 때 잠그지 않고 시작한다 — 컷신이면 c.lock()부터.


# ─── S1 의무실: 깨어남 ──────────────────────────────────

func enter_s_infirmary(c: Cut) -> void:
	if c.has("s_woke") or not c.has("t_escaped"):
		return
	c.lock()
	c.hud(false)
	await c.fade_out(0.01)
	c.music("school", 2.0)
	await c.wait(0.6)
	await c.say("pippa", "세라! 정신 차려! 세라!!", "sad")
	c.close_box()
	c.player_face(-1)
	await c.fade_in(1.4)
	c.emote("sera", "...")
	await c.wait(0.8)
	await c.say("pippa", "…아! 떴다! 눈 떴어요, 미라벨 선생님!", "happy")
	await c.say("mirabel", "어머, 다행이에요! 정문 앞에 쓰러져 있었대요. 파란 비에 흠뻑 젖어서요.", "happy")
	await c.say("sera", "…정문? 나 분명히 신계에…", "surprised")
	await c.say("neoul", "쉿. 여기서 나는 그저 작은 여우니라. 다른 이들에겐 내 말이 들리지 않는다.")
	c.emote("pippa", "!")
	await c.say("pippa", "근데 이 여우는 뭐야?! 너 사역마 계약했어? 폐급이 사역마를… 아, 아니, 미안.", "surprised")
	await c.say("sera", "어… 응. 사역마. 그런 걸로 해 둘게.", "smug")
	c.emote("neoul", "anger")
	await c.say("neoul", "사역마라니… 감히.", "angry")
	await c.say("pippa", "털 봐, 털! 만져 봐도 돼?", "happy")
	c.close_box()
	await c.approach("pippa", 1.2, 60.0)
	c.emote("neoul", "heart")
	await c.say("neoul", "무엄하… 거기, 거기 좀 더 긁거라.", "happy")
	await c.say("mirabel", "몸은 괜찮아 보이네요. 엠버린 교수님이 오늘 실습엔 꼭 나오래요. 서관 1층 마법반이에요.")
	await c.say("pippa", "아 맞다! 이거 받아. 내가 만든 회복 물약.", "happy")
	await c.say("pippa", "…맛은 보장 못 해.", "smug")
	c.close_box()
	c.give_potions(2)
	GameState.heal_full()
	c.player.restore_from_state()
	c.flag("pippa_potion")
	await c.item("회복 물약 ×2", "Q 로 마신다. 체력 2 회복. 기록 지점에서 다시 채워진다.")
	await c.say("pippa", "그리고 조심해. 어젯밤부터 학교 물건들이 이상해. 빗자루가 사람을 쫓아다닌다니까!", "sad")
	await c.say("pippa", "난 연금술실에 있을게. 식당 옆이야! 무슨 일 있으면 와!", "happy")
	c.close_box()
	await c.walk("pippa", 19.0, 130.0)
	c.hide_actor("pippa")
	c.sfx("door", -6.0)
	c.flag("s_woke")
	c.save_here("bed")
	c.save()
	c.hud(true)
	await c.teach("상호작용", "↑ 로 말을 걸고, 문을 드나들고, 기록한다.\n침대·촛대에서 기록하면 체력과 물약이 회복된다.", ["move_up"])
	c.bubble("…배고프다.", 2.0)


# ─── S2 동관 복도: 첫 폭주 물건 ─────────────────────────

func enter_s_eastcorr(c: Cut) -> void:
	if c.has("s_broom_seen") or c.enemy("broom") == null:
		return
	c.flag("s_broom_seen")
	await c.wait(0.5)
	c.bubble("저 빗자루, 마력이 새어 들었구나.", 2.6)


# ─── 중앙 홀: 이졸데 ────────────────────────────────────

func enter_s_hall(c: Cut) -> void:
	if c.has("hall_intro") or not c.has("s_woke"):
		return
	if c.player.global_position.y < 30 * 16.0:
		return # 2층으로 처음 들어온 경우엔 1층에서 만나도록 미룸
	c.flag("hall_intro")
	c.lock()
	await c.wait(0.3)
	await c.say("student_a", "…저기 봐, 세라야. 어젯밤에 사라졌다던.")
	await c.say("student_b", "또 폭주했다며? 이번엔 신계까지 날아갔다던데.")
	c.close_box()
	await c.approach("isolde", 3.5, 80.0)
	await c.say("isolde", "어머. 폐급이 살아 돌아왔네.", "smug")
	await c.say("isolde", "그 꼴로 실습에 나올 생각은 아니겠지? 이번엔 교실을 통째로 태우려고?", "smug")
	await c.say("sera", "…신경 꺼, 이졸데.", "angry")
	c.close_box()
	c.vignette(0.45)
	c.shake(0.06, 0.8)
	await c.say("neoul", "…감히.", "scary")
	c.vignette(0.0)
	c.emote("isolde", "?")
	await c.say("isolde", "…갑자기 왜 춥지.", "surprised")
	await c.say("isolde", "흥. 실습장에서 보든가, 폐급.")
	c.close_box()
	c.walk("isolde", 36.0, 80.0)
	await c.wait(0.5)
	await c.say("sera", "…너, 방금 뭐 한 거야?", "surprised")
	await c.say("neoul", "아무것도. 그저 조금 노려봤을 뿐이니라.", "smug")
	c.close_box()
	c.release()
	await c.teach("지도", "Tab (또는 M) 으로 지도를 연다.\n가 본 방과 기록 지점, 지금 있는 곳이 표시된다.", ["map"])


# ─── S3 마법반: 엠버린 ──────────────────────────────────

func enter_s_class(c: Cut) -> void:
	if c.has("met_emberlyn") or not c.has("s_woke"):
		return
	c.lock()
	await c.wait(0.3)
	await c.say("emberlyn", "…그러니까 불의 크기는 마음의 크기가 아니다. 다스리는 손의 크기지. 알겠니?")
	c.emote("emberlyn", "!")
	c.face("emberlyn", 1)
	await c.say("emberlyn", "세라! 몸은 괜찮니? 미라벨에게 들었다.", "surprised")
	await c.say("emberlyn", "…세라, 또 사고 쳤니?", "sad")
	await c.say("sera", "이번엔 진짜 사고였어요. …아마도요.", "sad")
	await c.say("emberlyn", "칠판 봐라. 이 그을음 반은 네 작품이다.", "smug")
	await c.say("student_a", "(킥킥)")
	await c.say("emberlyn", "오늘 과제는 '제어'다. 실습장의 과녁 세 개에 동시에 불을 붙여라.")
	await c.say("emberlyn", "단, 폭주 게이지를 70 아래로 유지한 채로. 세게 쏘는 건 누구나 한다. 다스리는 게 마법이야.")
	await c.say("neoul", "흥. 이 아이에게 다스림이라. 재미있는 선생이구나.")
	await c.say("emberlyn", "실습장은 왼쪽 문이다. 먼저 가 있어라 — 기록 촛대도 저기 있으니 써 두고.")
	c.flag("met_emberlyn")
	c.save()


# ─── S3 실습장: 과녁 → 골렘 ─────────────────────────────

func enter_s_training(c: Cut) -> void:
	if c.has("s_golem_started") and not c.has("golem_done"):
		c.lock()
		await c.say("emberlyn", "다시 간다, 세라! 등의 핵을 노려라!")
		c.close_box()
		await _golem_fight(c)
		return
	if not c.has("met_emberlyn") or c.has("t_targets_done") or c.has("s_training_intro"):
		return
	c.flag("s_training_intro")
	c.lock()
	await c.wait(0.3)
	await c.say("emberlyn", "왔구나. 시작해라.")
	await c.say("emberlyn", "과녁은 맞으면 5초 동안 불이 남는다. 셋이 동시에 타오르면 합격이다.")
	await c.say("emberlyn", "높은 과녁은 발판을 밟고 올라가서 쏴라. 화염탄은 멀리 못 간다 — 가까이 가서.")
	await c.say("emberlyn", "서두르면 폭주 게이지가 넘친다. 70을 넘기면 처음부터다.")
	c.close_box()


func s_golem(c: Cut) -> void:
	await c.wait(0.4)
	await c.say("emberlyn", "좋아! 바로 그거다, 세라—", "happy")
	c.close_box()
	c.sfx("slam", 2.0)
	c.shake(0.3, 0.8)
	await c.wait(0.6)
	await c.say("emberlyn", "…잠깐. 훈련 골렘이 왜 깨어나지?", "surprised")
	c.close_box()
	c.flash(Color(0.7, 0.4, 1.0, 0.5), 0.4)
	c.sfx("growl", 2.0)
	c.spawn_enemy("golem", 58.0, 19.0, "golem")
	await c.wait(0.8)
	await c.say("sera", "골렘이… 보라색으로 빛나?!", "surprised")
	await c.say("neoul", "폭주한 마력이 깃들었구나. 이 학교 어딘가에서 새어 나온 것이니라.")
	await c.say("emberlyn", "세라, 물러서라! …아니. 같이 막는다.", "angry")
	await c.say("emberlyn", "폐급이란 말, 내 수업에선 금지다. 넌 할 수 있어.")
	c.close_box()
	await _golem_fight(c)


func _golem_fight(c: Cut) -> void:
	var g := c.enemy("golem")
	if g == null:
		await _golem_after(c)
		return
	c.music("boss")
	c.release()
	if not GameState.has_ability("storm"):
		await c.wait_enemy(g, 0.6)
		if not c.ok():
			return
		if is_instance_valid(g) and g.is_alive():
			c.lock()
			await c.say("emberlyn", "세라, 내가 가르친 대로! 손을 앞으로 — 불을 감아서 던져라!", "angry")
			c.close_box()
			await c.learn("storm")
			await c.teach("화염 폭풍", "S 로 앞쪽에 불길을 몰아친다. 가까운 적을 날려 보낸다.\n골렘은 앞이 단단하다 — 등 뒤의 핵을 노려라!", ["skill_2"])
			c.release()
	await c.wait_enemy(g)
	if not c.ok():
		return
	await _golem_after(c)


func _golem_after(c: Cut) -> void:
	c.lock()
	c.music("school", 2.0)
	await c.wait(1.2)
	GameState.unlock_ability("storm")
	await c.approach("emberlyn", 3.0, 100.0)
	if int(GameState.stats.get("fox_modes", 0)) > 1:
		await c.say("emberlyn", "그 푸른 불… 사역마 계약이라도 한 거니?", "surprised")
		await c.say("sera", "에, 에헤헤… 그런 셈이에요.", "smug")
		c.bubble("사역마 아니니라!!", 2.0)
	await c.say("emberlyn", "잘했다. 그런데… 이상하구나. 훈련 골렘이 혼자 깨어날 리가 없어.")
	await c.say("emberlyn", "어젯밤부터 학교 지하 쪽에서 마력이 새고 있다. 교사들도 아직 원인을 못 찾았고.")
	await c.say("emberlyn", "도서관에 학교 봉인에 관한 오래된 기록이 있을 거다. 사서 그레타에게 물어봐라. 중앙 홀 2층 서쪽이다.")
	c.close_box()
	await c.say("neoul", "…봉인이 흔들린다라. 냄새가 고약하구나.")
	await c.say("neoul", "세라. 이 학교 아래에 무언가 잠들어 있다. 그것이 내 구슬에 반응해 깨어나려는 게야.")
	await c.say("sera", "구슬에…? 그럼, 이게 다 나 때문이야?", "surprised")
	await c.say("neoul", "봉인이 흔들리는 건 내 구슬 탓, 곧 네 탓이니라.")
	await c.say("sera", "…들키면 퇴학이야. 아무도 모르게 해결해야 해.", "sad")
	c.flag("golem_done")
	c.save()
