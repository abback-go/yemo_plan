extends RefCounted
## 공통 시스템 대본 — 유성 낙화 수업 (오필리아 별 관측 · 베로니카 제어 시험과 결투).
## 메서드 이름 = 실행 ID (docs/dev/story.md).


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
