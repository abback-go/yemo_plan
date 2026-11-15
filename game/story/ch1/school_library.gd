extends RefCounted
## 1장 대본 — 마녀학교 S4~S5 — 도서관·비속성마법반·서가 미로·금서 구역.
## 메서드 이름 = 실행 ID (docs/dev/story.md).


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
