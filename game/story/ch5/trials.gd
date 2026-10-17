extends "res://story/ch5/common.gd"
## 5장 대본 — 3. 별의 문간 · 별의 시련 넷(제국·세계수·대신전·학교).
## 메서드 이름 = 실행 ID (docs/dev/story.md). 장 공용 상수·도우미는 common.gd.


# ═══════════════════════════════════════════════════════════
# 3. 별의 문간 · 별의 시련 넷
# ═══════════════════════════════════════════════════════════

func enter_st_crossroads(c: Cut) -> void:
	_leave_all(c)
	if c.has("st_cross_seen") or not c.has("st_lyra_came"):
		return
	c.flag("st_cross_seen")
	c.lock()
	await c.wait(0.4)
	await c.say("astrid", "…역시 왔군요, 세라피나 양.", "tired")
	await c.say("sera", "교장 선생님! 쉬셔야죠!", "surprised")
	await c.say("astrid", "쉬고 있어요. 서서 쉬는 것도 교장의 특기랍니다.", "wink")
	await c.say("astrid", "이곳은 선배가 만든 별의 문간이에요. 문 넷이 각각 제국, 세계수, 대신전, 학교의 정원으로 곧장 이어져요.")
	await c.say("astrid", "가운데 계단이 탑의 꼭대기로 가는 길. 별의 열쇠 넷을 받침대에 꽂아야 열리죠.")
	await c.say("astrid", "문마다 제가 작은 별을 하나씩 달아 두었어요. 시련을 마치면 그 별을 타고 곧장 이리로 돌아올 수 있게.")
	await c.say("astrid", "그리고 촛대도 하나. 다치면 언제든 여기서 쉬어 가세요.")
	await c.say("sera", "…고마워요. 순서는 상관없어요?")
	await c.say("astrid", "선배는 원래 순서 같은 걸 싫어했어요. 마음 가는 곳부터.", "happy")
	c.close_box()
	c.save()
	c.release()


# ─── 제국: 레오니와 별 기사 ─────────────────────────────

func enter_st_trial_k1(c: Cut) -> void:
	if c.has("st_key_k"):
		return
	if c.has("st_k_met"):
		c.ensure_ally("leonie")
		return
	c.flag("st_k_met")
	c.lock()
	c.music("kingdom_night")
	c.ensure_ally("leonie", 12.0, 19.0)
	await c.wait(0.5)
	await c.say("leonie", "왔군, 세라.")
	await c.say("leonie", "별빛 기사가 거리를 걷는다. 시민은 모두 집 안에 들였다. …내 검을 흉내 내는 놈들이다.")
	await c.say("sera", "레오니의 검을? 리라가 만든 거야?")
	await c.say("leonie", "그래. 잔상 베기, 받아치기까지 똑같다. 하지만 흉내는 흉내일 뿐이다.")
	await c.say("leonie", "같이 간다. 등 뒤는 맡겨라.")
	await c.say("neoul", "별 정령의 선은 숨을 쉬듯 켜졌다 꺼지느니라. 꺼졌을 때 지나가거나, 정령 하나를 끄거라.")
	c.close_box()
	c.save_here("start")
	c.release()


func enter_st_trial_k(c: Cut) -> void:
	if c.has("st_key_k"):
		return
	c.ensure_ally("leonie")
	if not await _close_arena(c, "st_k_fight", 5.0):
		return
	c.lock()
	var en := c.spawn_enemy("star_knight", 30, 19, "grand_knight", {"grand": true})
	await c.say("leonie", "…저건 나다. 열 살의 나. 처음 검을 쥐었을 때의 자세.")
	await c.say("sera", "레오니?")
	await c.say("leonie", "리라라는 마녀는 나를 오래 보아 온 모양이다. …괜찮다. 이번엔 둘이다.")
	c.close_box()
	c.music("knight_duel")
	if en:
		en.engaged = true
	c.release()
	await c.wait_enemy(en, 0.5)
	if not c.ok():
		return
	var a := c.ally("leonie")
	if a and is_instance_valid(en) and en.is_alive():
		a.say("세라, 지금이다!")
		a.special(en)
	await c.wait_enemy(en)
	if not c.ok():
		return
	c.flag("st_k_fight", false)
	c.lock()
	Music.stop(1.0)
	await c.wait(0.8)
	await c.say("leonie", "…끝났다. 나쁘지 않군, 세라.", "happy")
	await _key_get(c, "k")
	_spawn_star_door(c, "out", 20.0, 19.0, "st_crossroads", "k", "k")
	await c.say("leonie", "브론이 밤새 새 검을 벼리고 있다. 별빛 따위가 아니라— 진짜 적을 벨 검을.")
	await c.say("leonie", "그 마녀가 노리는 게 무엇이든, 그 검이 필요할 날이 올 것 같다.")
	c.close_box()
	c.music("kingdom_night")
	c.release()


# ─── 세계수: 엘라리엔의 엄호와 별 궁수 ──────────────────

func enter_st_trial_e1(c: Cut) -> void:
	if c.has("st_key_e"):
		return
	var cover := c.marker("cover") / 16.0
	var a := c.ensure_ally("elarien", cover.x - 0.5, cover.y)
	a.mode = "hold"
	if c.has("st_e_met"):
		return
	c.flag("st_e_met")
	c.lock()
	c.music("elf")
	await c.wait(0.5)
	await c.say("elarien", "…왔나. 위에 둘. 별을 쏘는 그림자다.")
	await c.say("elarien", "붉은 선이 너를 따라오다 굳으면, 그때 쏜다. 굳은 선에서 비켜라.")
	await c.say("elarien", "나는 여기서 쏜다. 네가 오를 길은 내가 비운다.")
	await c.say("sera", "엘라리엔이 엄호해 주면 든든하지.")
	await c.say("elarien", "…맞히는 건 쉽다. 안 맞히는 게 어렵지.", "smug")
	c.close_box()
	c.save_here("start")
	c.release()


func enter_st_trial_e(c: Cut) -> void:
	if c.has("st_key_e"):
		return
	var cover := c.marker("cover") / 16.0
	var a := c.ensure_ally("elarien", cover.x - 0.5, cover.y)
	a.mode = "hold"
	if not await _close_arena(c, "st_e_fight", 4.0):
		return
	c.lock()
	var en := c.spawn_enemy("star_archer", 20, 10, "grand_archer", {"grand": true})
	await c.say("elarien", "…저 자세. 내 활이다. 백 년 전의 나.")
	await c.say("elarien", "그해, 숲에 별을 보러 온 마녀가 있었다. 모자가 컸다. 내 활을 오래 보더니 웃었다.")
	await c.say("elarien", "그리고 밤새 별을 보면서… 울었다.")
	await c.say("sera", "리라가… 울었다고?", "surprised")
	await c.say("elarien", "이유는 몰랐다. 지금도 모른다. 쏴라, 세라.")
	c.close_box()
	c.music("elf_hunt")
	if en:
		en.engaged = true
	c.release()
	await c.wait_enemy(en, 0.5)
	if not c.ok():
		return
	if a and is_instance_valid(a) and is_instance_valid(en) and en.is_alive():
		a.special(en)
	await c.wait_enemy(en)
	if not c.ok():
		return
	c.flag("st_e_fight", false)
	c.lock()
	Music.stop(1.0)
	await c.wait(0.8)
	await c.say("elarien", "…맞혔군. 네 불은 여전히 숲을 태우지 않는다.", "happy")
	await _key_get(c, "e")
	_spawn_star_door(c, "out", 20.0, 19.0, "st_crossroads", "e", "e")
	await c.say("elarien", "장로님이 세계수의 가지 하나를 떼어 두셨다. 언젠가 활로 깎으라고.")
	await c.say("elarien", "…무엇을 쏘게 될지는 모르겠다. 다만, 튕기지 않는 화살이 필요할 거다.")
	c.close_box()
	c.music("elf")
	c.release()


# ─── 대신전: 아우렐리아와 별 창기사 ─────────────────────

func enter_st_trial_tp1(c: Cut) -> void:
	if c.has("st_key_tp"):
		return
	if c.has("st_tp_met"):
		c.ensure_ally("aurelia")
		return
	c.flag("st_tp_met")
	c.lock()
	c.music("temple")
	c.ensure_ally("aurelia", 12.0, 19.0)
	await c.wait(0.5)
	await c.say("aurelia", "왔군요, 세라피나. 회랑의 별빛 창기사는 제 창을 흉내 냅니다.")
	await c.say("aurelia", "바닥의 금빛 띠가 보이면 돌진이 옵니다. 돌진은 직선입니다. 기둥 뒤로.")
	await c.say("sera", "아우렐리아의 돌진이라면… 첨탑에서 질리도록 봤지.", "smug")
	await c.say("aurelia", "…그때는 실례했습니다.")
	c.close_box()
	c.save_here("start")
	c.release()


func enter_st_trial_tp(c: Cut) -> void:
	if c.has("st_key_tp"):
		return
	c.ensure_ally("aurelia")
	if not await _close_arena(c, "st_tp_fight", 5.0):
		return
	c.lock()
	var en := c.spawn_enemy("star_lancer", 30, 19, "grand_lancer", {"grand": true})
	c.sfx("bell", 0.0)
	await c.say("aurelia", "종루에 내린 별… 이 별빛 속에, 흰빛이 아주 조금 섞여 있습니다.", "surprised")
	await c.say("aurelia", "바깥 신들의 흰빛입니다. 리라라는 마녀는— 그들을 알고 있습니다.")
	await c.say("sera", "리라가 바깥 신들이랑 한편이라는 거야?")
	await c.say("aurelia", "모릅니다. 다만 이 별빛은… 무언가를 견디는 빛입니다. 제가 그랬던 것처럼.")
	c.close_box()
	c.music("aurelia")
	if en:
		en.engaged = true
	c.release()
	await c.wait_enemy(en, 0.5)
	if not c.ok():
		return
	var a := c.ally("aurelia")
	if a and is_instance_valid(en) and en.is_alive():
		a.special(en)
	await c.wait_enemy(en)
	if not c.ok():
		return
	c.flag("st_tp_fight", false)
	c.lock()
	Music.stop(1.0)
	c.sfx("bell", 2.0)
	await c.wait(1.0)
	await c.say("aurelia", "종이 울렸습니다. 별의 시련, 통과입니다.")
	await _key_get(c, "tp")
	_spawn_star_door(c, "out", 20.0, 19.0, "st_crossroads", "tp", "tp")
	await c.say("aurelia", "루멘이 마지막으로 남긴 빛이 제단에 조금 있습니다. 쓸 때가 오면… 당신 곁에서 쓰겠습니다.")
	c.close_box()
	c.music("temple")
	c.release()


# ─── 학교: 이졸데·엠버린과 별의 정원 ────────────────────

func enter_st_trial_s1(c: Cut) -> void:
	if c.has("st_key_s"):
		return
	c.ensure_ally("isolde")
	c.ensure_ally("emberlyn")
	if c.has("st_s_met"):
		return
	c.flag("st_s_met")
	c.lock()
	c.music("school_day")
	await c.wait(0.4)
	await c.say("isolde", "늦었어, 세라. …뭐, 나도 방금 왔지만.", "smug")
	await c.say("emberlyn", "별의 정원이다. 오필리아가 별 관측 수업에 쓰던 뜰이지.")
	await c.say("emberlyn", "떨어진 별을 화염탄으로 순서대로 이어라. 순서가 틀리면 별이 꺼진다. 표지판을 읽고.")
	await c.say("isolde", "별 쏘는 건 네가 해. 난 옆에서 틀렸다고 말해 줄게.", "smug")
	c.close_box()
	c.save_here("start")
	c.release()


func st_s1_done(c: Cut) -> void:
	await c.wait(0.3)
	c.sfx("star_burst", 0.0)
	await c.say("isolde", "…별자리가 다리가 됐어. 예쁘네. 인정해.", "surprised")
	c.close_box()


func enter_st_trial_s(c: Cut) -> void:
	if c.has("st_key_s"):
		return
	c.ensure_ally("isolde")
	c.ensure_ally("emberlyn")
	if c.has("st_s2_seen"):
		return
	c.flag("st_s2_seen")
	await c.wait(0.4)
	c.bubble("별 정령이 고리를 이루고 있구나. 하나를 끄면 고리가 끊어지느니라.", 3.2)


func st_s2_done(c: Cut) -> void:
	await c.wait(0.3)
	c.sfx("star_burst", 0.0)
	await c.say("emberlyn", "길이 열렸다. 테라스의 별을 지키는 정령은 셋이다. 서두르지 마라.")
	c.close_box()


func st_s_key(c: Cut) -> void:
	if c.has("st_key_s"):
		return
	c.lock()
	for e in c.world.room.enemies:
		if is_instance_valid(e) and e.is_alive() and String(e.get("link")) == "sgk":
			e.take_hit(Hit.make(99999, &"fox", e.global_position))
	await c.wait(0.4)
	await _key_get(c, "s")
	_spawn_star_door(c, "out", 76.0, 10.0, "st_crossroads", "s", "s")
	await c.say("emberlyn", "세라. 네 불은… 이제 내가 가르칠 게 별로 없구나.", "happy")
	await c.say("isolde", "다음 시련엔 나도 데려가. …싫으면 말고.", "smug")
	await c.say("sera", "싫다고 한 적 없어.", "happy")
	c.close_box()
	c.release()
