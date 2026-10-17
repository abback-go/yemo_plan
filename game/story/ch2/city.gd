extends "res://story/ch2/common.gd"
## 2장 대본 — 5~7. 시계 구역·시계탑 · 대성당·지하 묘지 · 하수도·녹시스 · 귀족 구역.
## 메서드 이름 = 실행 ID (docs/dev/story.md). 장 공용 상수·도우미는 common.gd.


# ═══════════════════════════════════════════════════════════
# 5. 시계 구역 — 시계공 오토 · 톱니 시계 · 시계탑
# ═══════════════════════════════════════════════════════════

func enter_k_clock_street(c: Cut) -> void:
	if c.has("k_walls_talk") and not c.has("k_clock_arrived"):
		c.flag("k_clock_arrived")
	if c.has("k_clock_intro") or not c.has("k_walls_talk"):
		return
	c.flag("k_clock_intro")
	c.lock()
	await c.wait(0.4)
	await c.say("k_clockmaker", "거기, 마녀 아가씨! 지붕에서 내려온 거요? 다친 데는?", "surprised")
	await c.say("sera", "괜찮아요! 짐승 흔적을 따라왔는데… 이쪽으로 이어져 있어서요.")
	await c.say("k_clockmaker", "흔적이라면 시계탑이오. 별가루 묻은 도마뱀들이 밤마다 저 탑을 오르내리지.")
	await c.say("k_clockmaker", "헌데 탑 문이 안 열려. 태엽 공방의 톱니 시계 셋이 엉망이 됐거든. 그 셋이 맞아야 탑의 큰 태엽이 맞물려.")
	await c.say("k_clockmaker", "그 시계들은 대성당 종과 함께 울리게 돼 있소. 종이 언제 몇 번 치는지는… 대성당 게시판에 있을 거요.")
	await c.say("k_clockmaker", "아, 그리고 태엽 경비병들! 요즘 고장 나서 아무나 찔러. 정면은 단단하니 등의 태엽 열쇠를 노리시오.")
	await c.say("neoul", "종소리를 세어 시곗바늘을 맞추라는 게로구나. 바늘은 불을 쬐면 돈다 했지.")
	c.close_box()
	c.save()


func npc_k_clockmaker(c: Cut) -> void:
	if c.has("k_tower_top"):
		await c.say("k_clockmaker", "탑 꼭대기에 짐승 둥지가 있었다고? …평생 저 탑을 고쳤는데 몰랐다니.", "sad")
	elif c.has("k_gears_done"):
		await c.say("k_clockmaker", "들었소? 탑의 큰 태엽이 맞물리는 소리! 이제 탑 문이 열릴 거요. 꼭대기까지는 바람을 타야 하지만.", "happy")
	else:
		await c.say("k_clockmaker", "태엽 공방은 바로 저 아래 계단이오. 시계 셋 — 새벽, 정오, 저녁.")
		await c.say("k_clockmaker", "바늘은 불을 쬐면 한 시간씩 돌아가. 종 치는 횟수는 대성당 게시판에. 대성당은 이 거리 동쪽 끝이오.")


## 톱니 시계 셋이 맞았을 때 (태엽 공방 이벤트)
func k_gears_solved(c: Cut) -> void:
	await c.wait(0.6)
	c.lock()
	c.sfx("bell", 2.0)
	c.shake(0.2, 1.0)
	await c.wait(0.8)
	c.sfx("chain", 0.0)
	await c.say("sera", "…어디선가 큰 태엽이 철컥, 맞물리는 소리가…!", "surprised")
	await c.say("neoul", "탑이 깨어났구나. 가자, 세라. 시계탑 문은 거리 동쪽에 있었다.")
	c.close_box()
	Story.toast("시계탑 문이 열렸다.", 2.4)
	c.save()


## 시계탑 꼭대기: 짐승 둥지 + 성흔 늑대
func k_tower_top(c: Cut) -> void:
	if c.has("k_tower_top") or not c.has("k_gears_done"):
		return
	c.lock()
	await c.wait(0.3)
	await c.say("sera", "여기… 둥지야. 별 조각이 잔뜩…", "surprised")
	await c.say("neoul", "짐승 냄새. 그리고 — 사람 냄새. 누군가 짐승을 여기 불러 모았구나.", "sad")
	c.sfx("growl", 2.0)
	c.shake(0.2, 0.5)
	await c.wait(0.4)
	var w := c.spawn_enemy("star_wolf", 34.0, 12.0, "tower_wolf", {"engaged": true})
	c.freeze_enemies(true)
	c.emote("neoul", "!")
	await c.say("neoul", "몸에 별자리가 새겨진 늑대다! 울부짖으면 발밑을 보거라!")
	c.close_box()
	c.music("starbeast", 0.4)
	c.release()
	if w:
		await c.wait_enemy(w)
	if not c.ok():
		return
	c.lock()
	c.music("kingdom", 1.5)
	await c.wait(0.8)
	await c.say("sera", "하아… 하아…")
	await c.say("sera", "저기, 늑대가 끌고 온 자국이… 탑 아래로, 대성당 쪽으로 이어져.", "surprised")
	await c.say("neoul", "대성당 밑이라… 지하 묘지겠구나. 죽은 이들 곁에 숨는 놈들이라니, 고약하니라.")
	c.close_box()
	c.flag("k_tower_top")
	c.save()


# ═══════════════════════════════════════════════════════════
# 6. 대성당 · 지하 묘지 — 별 수정 장벽 (불꽃 방벽 수업으로)
# ═══════════════════════════════════════════════════════════

func enter_k_cathedral(c: Cut) -> void:
	if c.has("k_cathedral_intro"):
		return
	c.flag("k_cathedral_intro")
	c.lock()
	await c.wait(0.3)
	await c.say("sera", "…커다랗다. 그런데 좀 어둡네. 촛불이 이렇게 많은데.")
	await c.say("k_priest", "어서 오세요, 작은 마녀님. 빛의 신 루멘의 집입니다.")
	await c.say("k_priest", "…어둡지요? 요즘 루멘의 빛이 약해졌답니다. 촛불을 두 배로 켜도 예전만 못해요.", "sad")
	await c.say("k_priest", "성산의 대신전에서도 같은 소식이 들립니다. …별이 떨어진 뒤로, 하늘이 무언가를 잃어버린 것 같아요.", "sad")
	await c.say("neoul", "…신의 빛이 약해진다라. 남의 일 같지 않구나.", "sad")
	c.close_box()


func npc_k_priest(c: Cut) -> void:
	if _deliver_bread(c, "priest"):
		await c.say("k_priest", "미아가 보낸 빵이로군요. 고맙습니다. …그 아이 빵 덕분에 아침 기도가 덜 쓸쓸하답니다.", "happy")
		return
	if c.has("k_beast_down"):
		await c.say("k_priest", "별의 짐승이 쓰러졌다니. 루멘께 감사를… 아니, 작은 마녀님께 감사를 드려야겠군요.", "happy")
	elif c.has("k_tower_top") and not c.has("k_crypt_open"):
		await c.say("k_priest", "지하 묘지에 짐승이 드나든다고요? …요 며칠 밤마다 아래에서 유리 부딪는 소리가 났어요.", "surprised")
		await c.say("k_priest", "묘지 계단은 오른쪽 끝입니다. 루멘의 가호가… 약하게나마 함께하기를.")
	else:
		await c.say("k_priest", "종은 하루 세 번 칩니다. 새벽에 다섯 번, 정오에 열두 번, 저녁에 일곱 번.")
		await c.say("k_priest", "기도 시간을 알리는 종이에요. 시계 거리의 시계들도 이 종에 맞춰 왔지요.")


## 지하 묘지 입구: 별 수정 장벽 — 레오니 "막지도 못하면서"
func k_crypt_wall(c: Cut) -> void:
	if c.has("k_crypt_seen"):
		return
	c.flag("k_crypt_seen")
	c.lock()
	await c.wait(0.3)
	await c.camera_to(Vector2(41.0 * 16.0, 16.0 * 16.0), 0.8)
	await c.say("sera", "보라색 수정이… 길을 막고 있어. 안쪽에서 별빛이 뛰어.", "surprised")
	await c.camera_back(0.6)
	c.sfx("door")
	c.spawn_npc("leonie", 4.0, 19.0, 1)
	await c.walk("leonie", 21.0, 90.0)
	await c.say("leonie", "역시 이리로 이어졌군. 하수도에서 거슬러 올라왔다.")
	await c.say("leonie", "칼로는 흠집도 안 난다. 붙잡은 신도 말로는 '별의 방패'라더군.")
	await c.say("leonie", "저 수정이 쏘는 별 조각을 되받아쳐야 깨진다고 했다.")
	if GameState.has_ability("ward"):
		await c.say("sera", "되받아치는 거라면… 할 수 있어요. 방벽이면!", "happy")
		await c.say("leonie", "…배워 왔나. 보여 줘라.")
		c.close_box()
		await c.walk("leonie", 10.0, 80.0)
		c.face("leonie", 1)
		c.bubble("가까이 가면 조각이 날아온다. 닿기 직전에 방벽을 세우거라!", 3.0)
	else:
		await c.say("leonie", "넌 아까 대련에서 내 검을 한 번도 막지 못했지.", "stern")
		await c.say("leonie", "막지도 못하면서 되받아치겠다고?")
		await c.say("sera", "…배우면 되잖아요!", "angry")
		await c.say("leonie", "그럼 배워 와라. 그동안 이 묘지는 기사들이 지킨다.")
		c.close_box()
		await c.walk("leonie", 4.0, 80.0)
		c.hide_actor("leonie")
		await c.say("neoul", "엠버린에게 가자꾸나. 학교 수업 게시판에 '불꽃 방벽'이 있었지. 공관 전이진으로 가면 금방이니라.")
		c.close_box()
	c.save()


func k_crypt_broken(c: Cut) -> void:
	await c.wait(0.8)
	c.lock()
	if c.actor("leonie") and (c.actor("leonie") as Node2D).visible:
		await c.say("leonie", "…깨졌군.", "surprised")
		await c.say("leonie", "아래는 하수도다. 신도들의 굴이 그 끝에 있을 거다. 나는 기사들을 모아 뒤따르겠다.")
		c.close_box()
		await c.walk("leonie", 4.0, 80.0)
		c.hide_actor("leonie")
	else:
		await c.say("neoul", "되쏜 별이 제 방패를 깨뜨렸구나. 길이 열렸다. 아래는 하수도니라.")
		c.close_box()
	c.save()


# ═══════════════════════════════════════════════════════════
# 7. 하수도 — 수문 밸브 · 별철 · 녹시스
# ═══════════════════════════════════════════════════════════

func enter_k_sewer_1(c: Cut) -> void:
	if c.has("k_sewer_intro"):
		return
	c.flag("k_sewer_intro")
	c.bubble("…코가 떨어지겠구나. 물이 별빛으로 번들거리는 게 수상하니라.", 3.0)


func enter_k_sewer_2(c: Cut) -> void:
	if c.has("k_sewer2_intro"):
		return
	c.flag("k_sewer2_intro")
	c.bubble("다리 밑 굴에 뭔가 반짝인다. 수로 물을 빼면 닿겠구나.", 3.0)


func enter_k_sewer_3(c: Cut) -> void:
	if c.has("k_sewer3_intro"):
		return
	c.flag("k_sewer3_intro")
	c.bubble("물이 그득하구나. 뗏목을 밟고 건너거라. 빠지면 떠내려간다.", 3.0)


func enter_k_sewer_4(c: Cut) -> void:
	if c.has("k_sewer4_intro"):
		return
	c.flag("k_sewer4_intro")
	c.bubble("위로 뚫린 갱도다. 뗏목에 올라탄 채 밸브를 돌려 보거라.", 3.0)


func k_star_iron_got(c: Cut) -> void:
	if Quests.state("k_bron_ore") == 1:
		c.quest_step("k_bron_ore", 1)
	c.bubble("별철이다. 대장장이 브론이 반기겠구나.", 2.4)


func k_grate_open(c: Cut) -> void:
	if c.has("k_sewer_grate"):
		return
	c.flag("k_sewer_grate")
	c.sfx("chain")
	c.sfx("door", -2.0)
	Story.toast("녹슨 빗장을 풀었다. 위는 시장 뒷골목이다.", 2.4)


## 별 신도 은신처: 대사제 녹시스 (체력 절반에서 도망) → 기록 → 레오니의 결투 신청
func k_noxis(c: Cut) -> void:
	if c.has("k_noxis_fled") or not c.has("k_crypt_open"):
		return
	c.lock()
	c.flag("k_noxis_half", false)
	c.music("", 1.0)
	await c.player_walk(50.0)
	c.player_face(-1)
	c.spawn_npc("noxis", 28.0, 19.0, 1)
	c.sfx("reveal", 2.0)
	c.burst(Vector2(28.0 * 16.0 + 8.0, 19.0 * 16.0 - 20.0), 30, Color("#c89aff"),
		{spread = 180.0, speed_min = 40.0, speed_max = 140.0, lifetime = 0.7})
	await c.wait(0.6)
	await c.say("noxis", "어서 오십시오, 별에 이끌린 아이여.")
	await c.say("noxis", "녹시스라 합니다. '별을 좇는 자들'의 미천한 대사제지요.")
	await c.say("sera", "짐승들을 도시에 풀어놓은 게 당신이야?", "angry")
	await c.say("noxis", "풀어놓다니요. 짐승들은 스스로 옵니다. 별을 따라… 그리고 지금은—", "happy")
	await c.say("noxis", "당신에게로.", "zeal")
	c.emote("sera", "!")
	await c.say("neoul", "…이놈, 무슨 소리를 하는 게냐.", "scary")
	await c.say("noxis", "그분께서 보고 계십니다. 자, 보여 주십시오 — 별이 고른 그릇을!", "zeal")
	c.close_box()
	var nn := c.actor("noxis") as Node2D
	var nx := (nn.global_position.x / 16.0) if nn else 28.0
	c.hide_actor("noxis")
	var b := c.spawn_enemy("noxis", nx - 0.5, 19.0, "noxis", {"engaged": false, "auto_flee": false, "respawns": true})
	if b == null:
		c.flag("k_noxis_fled")
		return
	b.facing = 1
	c.music("boss", 0.4)
	b.engaged = true
	c.release()
	var nx_ref: WeakRef = weakref(b)
	await c.wait_until(func() -> bool: return c.has("k_noxis_half") or _dead(nx_ref), 900.0)
	if not c.ok():
		return
	c.lock()
	c.freeze_enemies(false)
	c.music("", 1.0)
	await c.wait(0.4)
	await c.say("noxis", "후후… 후후후. 충분합니다. 충분히 보았습니다.", "happy")
	await c.say("noxis", "그분은 소문 하나로 별을 움직이시지. …오늘 밤, 별이 떨어진 자리에서 다시 뵙지요.", "zeal")
	c.close_box()
	if is_instance_valid(b) and b.has_method("flee"):
		b.call("flee")
	await c.wait(1.4)
	c.flag("k_noxis_fled")
	await c.say("sera", "잠깐…! …사라졌어. 별빛 속으로.", "angry")
	c.close_box()
	# 레오니와 기사들
	c.sfx("door")
	c.spawn_npc("leonie", 79.0, 19.0, -1)
	c.spawn_npc("kael", 79.0, 19.0, -1)
	await c.walk("leonie", 56.0, 110.0)
	await c.say("leonie", "세라피나! …놈은?", "surprised")
	await c.say("sera", "도망쳤어요. 별빛 속으로.")
	await c.walk("kael", 62.0, 100.0)
	await c.say("kael", "단장님, 여기 책이…! 신도들의 기록 같습니다.", "surprised")
	await c.walk("leonie", 26.0, 70.0)
	c.face("leonie", 1)
	await c.wait(0.6)
	c.sfx("page")
	await c.say("leonie", "'짐승들은 별의 마력에 끌린다. 별이 떨어진 밤부터 늘 그랬다.'")
	await c.say("leonie", "'그런데 요즘 짐승들이 끌려가는 곳은 별이 아니다.'")
	await c.say("leonie", "'붉은 머리의 어린 마녀. 그 아이의 마력이 별보다 더 크게 운다.'", "surprised")
	await c.wait(0.6)
	await c.say("sera", "…나, 나는…", "sad")
	await c.say("leonie", "짐승들이 몰려든 이유가… 너였나.", "stern")
	await c.say("kael", "다, 단장님. 그건 마녀님 잘못이 아니잖아요…", "sad")
	await c.say("leonie", "잘잘못을 따지는 게 아니다, 카엘.")
	c.close_box()
	await c.walk("leonie", 46.0, 60.0)
	c.face("leonie", 1)
	await c.say("leonie", "세라피나. 오늘 밤, 황궁 광장으로 와라.", "stern")
	await c.say("leonie", "너를 지키는 방법이 이 도시에서 내보내는 것뿐이라면 — 그렇게 하겠다. 검으로.", "angry")
	c.close_box()
	await c.walk("leonie", 79.0, 90.0)
	c.hide_actor("leonie")
	await c.say("kael", "…마녀님. 단장님은, 그게… 원래 저런 분이 아니에요. 아니, 원래 저런 분이긴 한데…", "sad")
	c.close_box()
	await c.walk("kael", 79.0, 90.0)
	c.hide_actor("kael")
	await c.say("neoul", "…저 계집, 진심이구나.", "sad")
	await c.say("sera", "…내 마력이, 짐승을 부른다고.", "sad")
	await c.say("neoul", "세라. 넘치는 건 내가 받아 준다 하지 않았느냐. 부르는 게 짐승이든 별이든, 우린 도망치지 않느니라.")
	c.close_box()
	c.flag("k_duel_called")
	await c.fade_out(1.4)
	await c.narrate("그날 밤 — 시계탑 꼭대기.")
	c.close_box()
	await c.goto_room("k_clocktower", "top_save")
	c.music("kingdom_night", 1.0)
	await c.fade_in(1.4)
	c.player_face(-1)
	await c.wait(0.4)
	await c.say("neoul", "갈 테냐.")
	await c.say("sera", "응. 여기서 도망치면… 진짜 폐급이 되는 거니까.")
	await c.say("neoul", "흥. 그 말을 기다렸느니라. 다리 건너 귀족 구역, 그 너머가 황궁이다.")
	await c.say("neoul", "등불 든 태엽 경비병들이 깨어 있다. 들키면 싸움이 되니, 발코니 위로 가든 정면으로 가든 네 마음이니라.")
	c.close_box()
	c.save_here("top_save")


func enter_k_noble(c: Cut) -> void:
	if c.has("k_noble_intro") or not c.has("k_duel_called"):
		return
	c.flag("k_noble_intro")
	c.bubble("경비병 등불 앞은 피하거라. 등 뒤의 태엽 열쇠가 약점이니라.", 3.0)


func k_noble_alarm(c: Cut) -> void:
	c.sfx("bell_small", 2.0)
	Story.toast("들켰다! 경비병들이 몰려온다!", 2.2)
	c.bubble("들켰구나! 할 수 없지. 등 뒤로 돌아 들어가거라!", 2.4)


func npc_k_palace_guard(c: Cut) -> void:
	await c.say("k_knight", "단장님께서 광장에서 기다리십니다. 기사단 누구도 들이지 말라 하셨습니다.")
	await c.say("k_knight", "…마녀님. 부디, 몸조심하십시오.", "sad")
