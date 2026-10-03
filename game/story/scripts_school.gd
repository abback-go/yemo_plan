extends RefCounted
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
	await c.say("emberlyn", "과녁은 맞으면 4초 동안 불이 남는다. 셋이 동시에 타오르면 합격이다.")
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


# ─── S5a 도서관: 금서 열쇠를 문 마도서 ──────────────────

func enter_s_library(c: Cut) -> void:
	if c.has("key_stolen") or not c.has("golem_done"):
		return
	c.lock()
	await c.wait(0.3)
	await c.walk("greta", 44.0, 50.0)
	c.face("greta", 1 if c.player.global_position.x > 44 * 16.0 else -1)
	await c.say("greta", "도서관에서는 정숙.")
	await c.say("sera", "아직 아무 말도 안 했는데요…", "sad")
	await c.say("greta", "…무슨 일이냐.")
	await c.say("sera", "학교 봉인에 관한 기록을 찾아요. 엠버린 교수님이 여기 있을 거라고 하셨어요.")
	await c.say("greta", "금서 구역의 기록이다. 학생에겐 보여 줄 수 없지만… 엠버린이 보냈다면.")
	await c.say("greta", "열쇠는 여기—")
	c.close_box()
	var book := c.actor("book")
	if book:
		book.global_position = Vector2(30 * 16.0, 9 * 16.0)
		book.appear(0.2)
		c.sfx("page", 2.0)
		await book.move_to(Vector2(44 * 16.0, 17 * 16.0), 0.45)
		book.power = 1.0
		c.sfx("whoosh")
		c.emote("hodu", "!")
		await c.say("hodu", "호우!")
		c.close_box()
		book.face(-1)
		await book.move_to(Vector2(10 * 16.0, 6 * 16.0), 0.9)
		await book.move_to(Vector2(-2 * 16.0, 5 * 16.0), 0.4)
		book.visible = false
	await c.wait(0.5)
	await c.say("greta", "……")
	await c.say("greta", "…연체 도서가 하나 늘었군.")
	await c.say("sera", "쫓아가야죠! 저 책, 어디로 간 거예요?", "angry")
	await c.say("greta", "서가 미로. 꼭대기까지 올라갔겠지.")
	if not GameState.has_ability("double_jump"):
		await c.say("greta", "하지만 부양도 못 하는 학생은 서가에 못 오른다. 저 책장 턱, 보이나.")
		await c.say("greta", "비속성마법반의 오필리아에게 부양을 배워 오너라. 서관 복도의 계단 아래다.")
		await c.say("sera", "부양…! 알겠어요.")
	else:
		await c.say("greta", "…부양은 할 줄 아는구나. 그럼 가라. 서가에선 뛰지 말고— 아니, 뛰어도 된다. 이번만.")
	c.flag("key_stolen")
	c.save()


# ─── S4 비속성마법반: 오필리아 ──────────────────────────

func enter_s_nonelem(c: Cut) -> void:
	if c.has("ophelia_awake"):
		return
	c.lock()
	await c.wait(0.4)
	c.emote("ophelia", "...")
	await c.say("sera", "…교수님? 오필리아 교수님!")
	await c.say("ophelia", "으음~… 오 분만 더어~…")
	await c.say("neoul", "천장에 붙어 자는 마녀라. 이 학교는 정말 재미있구나.")
	await c.say("sera", "교수님!!", "angry")
	c.close_box()
	c.shake(0.08, 0.3)
	c.emote("ophelia", "!")
	await c.move("ophelia", 28.0, 19.0, 0.7, Tween.TRANS_BOUNCE)
	c.sfx("land")
	await c.say("ophelia", "착지까지가~ 수업이란다~", "happy")
	await c.say("ophelia", "어머~ 세라구나. 무슨 일이니~?")
	if c.has("key_stolen"):
		await c.say("sera", "부양을 배우고 싶어요! 지금 당장요!")
	else:
		await c.say("sera", "그냥… 부양이 궁금해서요.")
	await c.say("ophelia", "부양은 말이지~ 몸을 띄우는 게 아니라, 무게를 잠깐 잊어버리는 거란다~")
	await c.say("ophelia", "자, 연습용 깃털을 빌려줄게~ 이걸 쥐고 있으면 공중에서 한 번 더 뛸 수 있어~")
	c.close_box()
	c.flag("temp_double_jump")
	await c.item("연습용 깃털", "공중에서 Z — 한 번 더 뛰어오른다. (빌린 것)")
	await c.say("ophelia", "왼쪽 실습실에 떠 있는 등불 다섯 개를 모아 오렴~ 다 모으면 몸이 기억할 거야~")
	await c.say("ophelia", "그럼 나는 다시… 쿨…")
	c.close_box()
	c.flag("ophelia_awake")


func s_lev_done(c: Cut) -> void:
	await c.wait(0.6)
	await c.say("sera", "됐다…! 다섯 개 전부!", "happy")
	await c.say("neoul", "흥. 깃털 없이도 이제 뛸 수 있겠구나. 몸이 무게 잊는 법을 기억했느니라.")
	c.close_box()
	await c.learn("double_jump")
	c.flag("temp_double_jump", false)
	c.save()
	if c.has("key_stolen") and not c.has("key_recovered"):
		c.bubble("이제 서가 꼭대기로 가자꾸나. 책 도둑을 잡아야지.", 3.0)


# ─── S5b 서가 미로: 마도서 ──────────────────────────────

func enter_s_stacks(c: Cut) -> void:
	if not c.has("key_stolen") or c.has("s_stacks_seen") or c.has("key_recovered"):
		return
	var g := c.enemy("grimoire")
	if g == null:
		return
	c.flag("s_stacks_seen")
	c.lock()
	await c.camera_to(g.global_position + Vector2(0, 40), 1.2)
	await c.say("sera", "저기 있다! 꼭대기!", "angry")
	await c.say("neoul", "책장이 미로처럼 얽혀 있구나. 서두르지 말고 길을 찾거라.")
	c.close_box()
	await c.camera_back(0.8)


func s_grimoire(c: Cut) -> void:
	if c.has("key_recovered"):
		return
	var g := c.enemy("grimoire")
	if g == null:
		await _grimoire_after(c)
		return
	if not c.has("grim_met"):
		c.flag("grim_met")
		c.sfx("page", 2.0)
		await c.say("sera", "열쇠 내놔, 이 책벌레야!", "angry")
		await c.say("neoul", "책이 웃는구나. 덮였다 펼쳐지는 순간을 조심하거라.")
		c.close_box()
	c.music("boss")
	c.release()
	await c.wait_enemy(g)
	if not c.ok():
		return
	await _grimoire_after(c)


func _grimoire_after(c: Cut) -> void:
	c.lock()
	c.music("library", 1.5)
	await c.wait(1.0)
	await c.item("금서 구역 열쇠", "서가 미로 꼭대기의 철문을 연다.")
	await c.say("neoul", "책이 열쇠를 삼키다니. 너와 똑같구나.", "smug")
	await c.say("sera", "나는 삼킨 게 아니라니까!", "angry")
	c.flag("key_recovered")
	c.save()


# ─── S5c 금서 구역: 기록과 너울의 기억 ──────────────────

func s_archive_read(c: Cut) -> void:
	if c.has("ab_fox_window"):
		await c.narrate("『학교 창립 기록 — 비(秘)』\n…굶주린 것은 푸른 불 아래 잠들어 있다.")
		return
	c.music("library")
	await c.narrate("『학교 창립 기록 — 비(秘)』")
	await c.narrate("학교의 터 아래에는 '굶주린 것'이 잠들어 있다.\n먹어도 먹어도 배부르지 않은 것. 우리는 그것을 아귀라 불렀다.")
	c.close_box()
	var f := c.actor("founder")
	if f:
		await f.appear(1.0)
	await c.narrate("창립자는 동방의 여우신을 찾아가 푸른 불을 빌렸다.\n무엇도 태워 없애지 않고, 다만 잠재우는 불.")
	await c.narrate("그 불로 굶주린 것을 봉인하였다.\n봉인은 여우신의 불에 응답하리라.")
	c.close_box()
	if f:
		await f.vanish(1.0)
	await c.say("sera", "동방의 여우신… 푸른 불… 너잖아!", "surprised")
	await c.say("neoul", "……")
	await c.say("neoul", "…기억났다. 수백 년 전, 배고픈 얼굴의 마녀 하나가 내 신단에 찾아왔었지. 친구들을 지키고 싶다며.", "sad")
	await c.say("neoul", "내 불을 꼬리 하나만큼 빌려주었느니라. 그 불이 아직 이 아래에서 타고 있구나.")
	await c.say("neoul", "그래서 봉인이 구슬에 반응한 게야. 구슬이 네 안에 있으니, 봉인은 주인이 돌아온 줄 알고 문을 연 게지.")
	await c.say("sera", "그럼 어떻게 해야 해?")
	await c.say("neoul", "봉인을 다시 다져야지. 그러려면 숨은 것을 보는 눈이 필요하니라.")
	await c.say("neoul", "손을 이리 내 보거라. 손가락을 겹쳐서 — 여우 모양 창을 만들어라.")
	c.close_box()
	await c.learn("fox_window")
	await c.teach("여우창문", "D 로 여우창문. 창 안에서는 둔갑한 것의 참모습이 보인다.\n환영 벽은 사라지고, 숨은 발판과 표식이 드러난다.", ["fox_window"])
	c.lock()
	await c.wait(1.0)
	await c.say("neoul", "…서가 꼭대기 끝의 벽. 냄새가 이상하더구나. 이 학교, 숨긴 게 많구먼.")
	c.save()


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
	c.save()
	var keep := await c.world.end_screen()
	if not keep:
		GameState.go_title()
		return
	c.hud(true)
	await c.fade_in(1.0)
	c.bubble("…자, 학교를 좀 더 둘러볼까. 숨긴 게 많은 학교니라.", 3.0)
