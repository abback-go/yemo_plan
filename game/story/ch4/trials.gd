extends "res://story/ch4/common.gd"
## 4장 대본 — 4~7. 시련 셋(빛의 거울·종탑·기록실) · 본당 대화.
## 메서드 이름 = 실행 ID (docs/dev/story.md). 장 공용 상수·도우미는 common.gd.


# ═══════════════════════════════════════════════════════════
# 4. 시련 ① 빛의 거울
# ═══════════════════════════════════════════════════════════

func enter_tp_mirror_1(c: Cut) -> void:
	if c.has("tp_mirror1_seen") or c.has("tp_trial_mirror"):
		return
	c.flag("tp_mirror1_seen")
	c.lock()
	await c.wait(0.4)
	await c.camera_to(Vector2(60 * 16, 12 * 16), 0.9)
	await c.say("sera", "빛줄기가… 거울에 꺾여서 바닥으로 사라져.")
	await c.say("neoul", "저 위 수정에 빛을 닿게 하라는 게로구나. 거울은 손으로 돌리거나, 불기둥으로 두드려 돌릴 수 있겠다.")
	c.close_box()
	await c.camera_back(0.6)
	await c.teach("빛의 거울", "거울 앞에서 ↑ — 거울을 돌린다. 손이 닿지 않는 거울은 불기둥을 맞혀도 돌아간다.\n빛줄기가 수정에 닿으면 길이 열린다.", ["move_up"])


func enter_tp_mirror_3(c: Cut) -> void:
	if c.has("tp_mirror3_seen") or c.has("tp_trial_mirror"):
		return
	c.flag("tp_mirror3_seen")
	c.lock()
	await c.wait(0.4)
	await c.say("neoul", "빛이 저 눈에서 왼쪽으로만 흐르는구나. 수정은 오른쪽 위인데.")
	await c.say("sera", "'빛을 마주 보고, 불의 원으로 되돌려 보내라'… 석판에 그렇게 쓰여 있었어.")
	if Spells.learned("ward"):
		await c.say("neoul", "불꽃 방벽이니라. 빛줄기 속에 서서 빛이 오는 쪽을 보고 방벽을 펼치면, 빛이 네가 보는 쪽으로 튕겨 나갈 게다.")
		c.close_box()
		var key := "skill_1" if Spells.equipped("a") == "ward" else "skill_2"
		await c.teach("빛 되돌리기", "빛줄기 안에 서서, 빛이 오는 쪽을 바라보고 불꽃 방벽.\n빛이 세라가 바라보는 쪽으로 되돌아간다. (오른쪽 거울 둘도 먼저 맞춰 둘 것)\n방벽은 마법서에서 A·S 칸에 끼워 두어야 쓸 수 있다.", [key])
	else:
		await c.say("neoul", "…방벽을 아직 못 배웠느냐. 학교 실습장의 엠버린에게 배워 오거라. 회랑의 전이진으로 다녀올 수 있다.", "sad")
		c.close_box()


func tp_mirror_trial_done(c: Cut) -> void:
	c.lock()
	await c.wait(0.4)
	c.sfx("reveal")
	await c.say("sera", "됐다! 수정이 빛나!", "happy")
	c.close_box()
	var first := _trials_count() == 0
	await _trial_done(c, "tp_trial_mirror", "빛의 거울")
	if first:
		await _aurelia_cameo(c, "…빛의 길을 읽는군요. 우연이겠지요.")
	Story.toast("왼쪽 문으로 회랑에 바로 돌아갈 수 있다.", 2.6)


# ═══════════════════════════════════════════════════════════
# 5. 시련 ② 종탑
# ═══════════════════════════════════════════════════════════

func tp_bell_intro(c: Cut) -> void:
	if c.has("tp_bell_intro"):
		return
	c.flag("tp_bell_intro")
	c.lock()
	await c.say("sera", "종탑… 저 위에서 유령이 종을 치고 있어.", "surprised")
	await c.say("neoul", "종지기의 혼이로구나. 박자를 잃고 영원히 종을 치는 게지.")
	await c.say("neoul", "저 진짜 청동 종 — 불기둥으로 아래에서 쳐 보거라. 진짜 종소리엔 망령도 귀를 막을 게다.")
	c.close_box()
	await c.teach("진짜 종", "종 아래에서 불기둥 — 종이 울린다.\n가까운 종지기 망령은 귀를 막고 주저앉는다(그동안 받는 피해 1.5배).", ["skill_1"])


func tp_beat_intro(c: Cut) -> void:
	if c.has("tp_beat_intro") or c.has("tp_beat_done"):
		return
	c.flag("tp_beat_intro")
	c.lock()
	await c.say("sera", "종이 넷… 받침마다 문양이 달라. 달, 불꽃, 별, 여우.")
	await c.say("neoul", "위층 계단을 빛살이 막고 있구나. 정해진 차례로 쳐야 열리는 게지. 박자를 놓치면 처음부터일 게다.")
	await c.say("neoul", "…저 벽, 그림이 지워진 것 같지 않으냐? 여우창문으로 들여다보거라.")
	c.close_box()


func tp_beat_done(c: Cut) -> void:
	c.sfx("reveal")
	Story.toast("종소리가 맞았다! 위층 계단의 빛살이 걷혔다.", 2.6)
	c.bubble("…박자도 맞았구나. 제법이니라.", 2.6)


func tp_bell_trial_done(c: Cut) -> void:
	c.lock()
	await c.wait(0.8)
	for e in c.world.room.enemies:
		if is_instance_valid(e) and e is BellWraith and e.is_alive():
			e.take_hit(Hit.make(99999, &"bell", e.global_position + Vector2(0, -10)))
	await c.narrate("큰 종소리가 탑을 타고 산 아래까지 굴러갔다. 망령들이 귀를 막은 채… 고개를 숙이더니, 흩어졌다.")
	c.close_box()
	var first := _trials_count() == 0
	await _trial_done(c, "tp_trial_bell", "종탑")
	if c.actor("gregor"):
		c.face("gregor", 1 if c.player.global_position.x > c.npc("gregor").global_position.x else -1)
		await c.say("gregor", "누가 큰 종을 쳤어?! …아, 시련이로구먼! 잘했다, 아가씨! 소리가 맑다!", "happy")
		c.close_box()
	if first:
		await _aurelia_cameo(c, "…종이 당신을 받아들였군요. 종은 마음이 굽은 자에게 울리지 않습니다.")
	Story.toast("종탑 아래층에서 수도사 숙소로 가는 지름길 철창이 열렸다.", 3.0)


# ═══════════════════════════════════════════════════════════
# 6. 시련 ③ 기록실 — 백금 사도, 가장 오래된 기록 (tp_archive_read)
# ═══════════════════════════════════════════════════════════

func tp_archive_intro(c: Cut) -> void:
	if c.has("tp_archive_intro"):
		return
	c.flag("tp_archive_intro")
	c.lock()
	await c.say("sera", "어두워… 조각상이 잔뜩이야.")
	await c.say("neoul", "세라, 저 날개 달린 석상들 — 등을 보이지 말거라. 눈을 떼면 움직이는 놈들이니라.")
	await c.say("neoul", "마주 보고 있을 땐 돌이다. 화염탄은 튕겨 나겠지만… 발밑에서 솟는 불이라면 금이 갈 게다.")
	c.close_box()


func tp_herald_fight(c: Cut) -> void:
	if c.has("tp_herald_down"):
		return
	var h := c.enemy("gold_herald")
	if h == null:
		await _herald_end(c)
		return
	c.lock()
	if not c.has("tp_herald_met"):
		c.flag("tp_herald_met")
		await c.camera_to(h.global_position + Vector2(0, -20), 0.8)
		c.freeze_enemies(false)
		c.sfx("sky_crack", 2.0)
		c.shake(0.3, 0.8)
		await c.wait(0.8)
		c.freeze_enemies(true)
		await c.say("sera", "저건… 사람이 아니야. 금빛인데… 하얘.", "surprised")
		await c.say("neoul", "흰빛… 세계수에서 본 그 사도와 같은 냄새니라! 여기까지 와 있었구나.", "angry")
		await c.say("tp_voice", "…그릇… 별의… 그릇…")
		await c.say("sera", "또 그 말…!", "angry")
		await c.say("neoul", "거울판이 막는 쪽으로 쏘면 튕겨 나온다. 판 사이 틈을 노리거나, 튕겨 온 조각을 방벽으로 되쏘거라!")
		await c.say("neoul", "바닥에 내려앉을 때가 기회니라. 그땐 불기둥도 닿는다!")
		c.close_box()
		await c.camera_back(0.5)
	else:
		await c.say("neoul", "다시니라. 판 사이를 노려라.")
		c.close_box()
	c.music("herald", 0.5)
	c.flag("tp_herald_fight")
	c.save_here("record")
	h.engaged = true
	c.release()
	await c.wait_enemy(h, 0.5)
	if not c.ok():
		return
	if is_instance_valid(h) and h.is_alive():
		c.bubble("판이 빨라졌다! 안쪽이나 바깥으로 피하거라!", 2.6)
	await c.wait_enemy(h)
	if not c.ok():
		return
	await _herald_end(c)


func _herald_end(c: Cut) -> void:
	c.lock()
	c.flag("tp_herald_down")
	c.flag("tp_herald_fight", false)
	Music.stop(1.5)
	await c.wait(1.2)
	await c.say("sera", "하아… 사라졌어. 흰 조각이 되어서.")
	await c.say("neoul", "기록을 지키던 게 아니라… 먹고 있었던 게로구나. 저 오래된 책을.", "sad")
	c.close_box()
	c.music("temple_dark", 1.5)
	c.save_here("record")


func tp_archive_record(c: Cut) -> void:
	if not c.has("tp_herald_down"):
		await c.narrate("하얀 빛이 책을 감싸고 있다. 손을 대려 하자 차가운 기운에 손끝이 저렸다.")
		c.close_box()
		return
	if c.has("tp_archive_read"):
		await c.narrate("초대 대사제의 기록. 「…수호자여. 계시가 끊기는 날이 오거든, 대답하는 목소리를 믿지 말라.」")
		c.close_box()
		return
	c.lock()
	await c.narrate("가장 오래된 기록. 표지에 해 문양, 그 아래 초대 대사제의 이름이 새겨져 있다.")
	await c.narrate("「…빛의 주재는 영원하지 않다. 나는 그것을 별을 보다 알았다. 수백 년에 걸쳐, 아주 천천히, 그분의 빛이 엷어지고 있다.」")
	await c.narrate("「주재가 약해진 세계에는 하늘 바깥의 것들이 냄새를 맡고 온다. 얼굴 없는 흰 것들. 그들은 세계를 먹는다 — 관리자가 약한 세계부터.」")
	await c.narrate("「그들은 먼저 사도를 보내 길을 닦고, 그 세계에서 가장 강한 그릇을 문으로 삼아 들어온다.」")
	await c.narrate("「…수호자여. 계시가 끊기는 날이 오거든, 대답하는 목소리를 믿지 말라.」")
	await c.narrate("마지막 장에는 다른 손으로 쓴 짧은 메모가 덧붙어 있다.")
	await c.narrate("「재 속에서 다시 타오르는 불이 있다 했다. 마녀들의 창립자가 끝내 금서로 묶은 마지막 불 — 불사조.」")
	c.close_box()
	await c.say("sera", "…수백 년째 약해지고 있었다고? 루멘이?", "surprised")
	await c.say("neoul", "…그래서였구나. 세계수의 흰 역병도, 방금 그 흰 사도도.", "sad")
	await c.say("neoul", "'가장 강한 그릇을 문으로'… 세라, 이 기록은 잘 기억해 두거라.")
	await c.say("sera", "불사조… 학교 도서관 금서 구역에서 본 이름이야. 그레타 선생님이라면 알지도.")
	c.close_box()
	c.flag("tp_archive_read")
	var first := _trials_count() == 0
	await _trial_done(c, "tp_trial_archive", "기록실")
	Story.toast("학교 도서관의 그레타에게 금서 '불사조' 열람을 부탁할 수 있다. (수업 게시판)", 3.4)
	if first:
		await _aurelia_cameo(c, "…그 기록을 읽었군요. 수호자 말고는 아무도 읽지 않던 것을.")


# ═══════════════════════════════════════════════════════════
# 7. 본당 — 아우렐리아와의 대화 ("주께서 대답하지 않으십니다", "별빛이 섞였다")
# ═══════════════════════════════════════════════════════════

func npc_aurelia(c: Cut) -> void:
	if c.has("tp_aurelia_defeated"):
		await c.say("aurelia", "세라 님. 다시 찾아 주셨군요.", "smile")
		await c.say("aurelia", "주께서는 여전히 침묵하십니다. 하지만 이제는… 침묵 속에서도 창을 들 수 있습니다.")
	elif c.has("tp_trials_done"):
		await tp_aurelia_talk(c)
		return
	else:
		var n := _trials_count()
		if n == 0:
			await c.say("aurelia", "기도 중입니다. 시련은 회랑에서 시작됩니다. 물러나십시오.")
		else:
			await c.say("aurelia", "%d개. …아직 끝나지 않았습니다." % n)
			await c.say("aurelia", "남은 것은 %s." % _trials_left())
	c.close_box()


func tp_aurelia_talk(c: Cut) -> void:
	if c.has("tp_aurelia_talk") or not c.has("tp_trials_done"):
		return
	c.lock()
	await c.player_walk(52.0, 70.0)
	c.player_face(1)
	c.pose("aurelia", "kneel")
	await c.wait(0.6)
	await c.say("aurelia", "…세 시련을 모두 마쳤군요.")
	c.pose("aurelia", "idle")
	c.face("aurelia", -1)
	await c.say("aurelia", "인정하겠습니다. 빛의 거울은 거짓을 비추지 않고, 큰 종은 마음이 굽은 자에게 울리지 않습니다.")
	await c.say("aurelia", "기록실의 것도… 읽었겠지요.")
	await c.say("sera", "루멘이 수백 년째 약해지고 있었다고.")
	await c.say("aurelia", "압니다. 수호자는 모두 압니다. 그래서 지켜 왔습니다. 더 단단히, 흔들리지 않게.")
	await c.wait(0.5)
	await c.say("aurelia", "…열흘 전부터, 주께서 대답하지 않으십니다.", "sad")
	await c.say("aurelia", "아침 기도에도, 저녁 기도에도. 계시가 끊겼습니다. 수호자가 된 뒤로 처음입니다.", "sad")
	await c.say("sera", "그래서 문을 닫은 거야?")
	await c.say("aurelia", "흔들리는 수호자를 순례자에게 보일 수는 없으니까요.")
	c.close_box()
	await c.walk("aurelia", 56.0, 40.0)
	await c.say("aurelia", "…잠깐.")
	c.emote("aurelia", "?")
	await c.say("aurelia", "당신의 마력. 붉은 불 속에… 별빛이 섞여 있습니다.", "surprised")
	await c.say("sera", "별빛?", "surprised")
	c.emote("neoul", "!")
	await c.say("neoul", "(……!)")
	await c.say("aurelia", "…착각이겠지요. 마녀의 불이니.")
	await c.say("aurelia", "오늘 밤, 내전의 제단에서 마지막 기도를 올리겠습니다. 수호자의 모든 빛을 바쳐서라도 주와의 연결을 되살리겠습니다.")
	await c.say("aurelia", "대사제님께서 당신도 증인으로 세우고 싶어 하십니다. 내전으로 오십시오. 제단 옆 계단입니다.")
	c.close_box()
	c.flash(Color(1.0, 0.92, 0.7, 0.35), 0.3)
	c.hide_actor("aurelia")
	await c.wait(0.5)
	var a := _leonie_join(c, 10.0, 19.0)
	await a.move_to(c.player_tile().x - 2.5)
	a.mode = "follow"
	await c.say("leonie", "세라. 끝났나.")
	await c.say("sera", "응. 오늘 밤 내전에서 아우렐리아가 마지막 기도를 올린대.")
	await c.say("leonie", "…나도 가겠다. 수도사들 말로는, 저 사람 열흘째 잠을 자지 않았다고 한다.")
	await c.say("neoul", "…세라. 아까 그 계집이 한 말. 별빛이라 했지.", "sad")
	await c.say("sera", "응. 무슨 뜻이야?")
	await c.say("neoul", "…아무것도 아니니라. 가자.")
	c.close_box()
	c.flag("tp_aurelia_talk")
	c.save()
