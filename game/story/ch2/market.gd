extends "res://story/ch2/common.gd"
## 2장 대본 — 2~4. 시장 습격(레오니) · 연무장 대련·성벽 대화 · 지붕 경주(이졸데).
## 메서드 이름 = 실행 ID (docs/dev/story.md). 장 공용 상수·도우미는 common.gd.


# ═══════════════════════════════════════════════════════════
# 2. 시장 습격 — 레오니 등장
# ═══════════════════════════════════════════════════════════

func k_market_beast(c: Cut) -> void:
	if c.has("k_met_leonie") or not c.has("k_departed"):
		return
	c.lock()
	c.sfx("roar", 2.0)
	c.shake(0.3, 0.6)
	await c.wait(0.4)
	await c.say("k_citizen_b", "지, 짐승이다! 별의 짐승이 또 나타났어!", "surprised")
	c.close_box()
	var w := c.spawn_enemy("star_wolf", 82.0, 19.0, "beast_wolf", {"engaged": true})
	c.freeze_enemies(true)
	if w:
		await c.camera_to(w.global_position + Vector2(0, -30), 0.6)
		await c.wait(0.5)
		await c.camera_back(0.5)
	c.emote("neoul", "!")
	await c.say("neoul", "세라, 온다! 사람들 쪽으로 보내지 마라!")
	c.close_box()
	c.music("starbeast", 0.4)
	c.release()
	if w:
		await c.wait_enemy(w, 0.55, 22.0)
	if not c.ok():
		return
	# 은사자 기사단장
	c.lock()
	var alive := w != null and is_instance_valid(w) and w.is_alive()
	var tx := (w.global_position.x / 16.0) if alive else c.player_tile().x + 5.0
	c.spawn_npc("leonie", 118.0, 19.0, -1)
	c.sfx("whoosh", 2.0)
	await c.wait(0.2)
	await _flash_step(c, "leonie", tx + (2.0 if alive else 0.0))
	if alive:
		c.sfx("sword_slash", 4.0)
		c.flash(Color(1, 1, 1, 0.7), 0.25)
		c.shake(0.4, 0.4)
		w.take_hit(Hit.make(99999, &"ally", w.global_position + Vector2(20, -10)))
	await c.wait(0.8)
	c.pose("leonie", "idle")
	c.music("kingdom", 1.0)
	c.sfx("crowd", 2.0)
	await c.say("k_citizen_c", "단장님이다! 레오니 단장님!", "happy")
	await c.say("k_citizen_b", "한 칼이야, 한 칼! 봤어? 칼이 안 보였어!", "happy")
	c.close_box()
	if not alive:
		await c.say("leonie", "…쓰러뜨렸나. 혼자서.")
	await c.say("leonie", "다친 사람은.")
	await c.say("k_citizen_c", "없습니다, 단장님!", "happy")
	await c.say("leonie", "…좋다.")
	c.close_box()
	await c.approach("leonie", 3.5, 60.0)
	await c.say("leonie", "그 모자. 마녀학교에서 왔다는 학생들인가.")
	await c.say("sera", "아, 네! 세라피나예요. 다들 세라라고…", "happy")
	await c.say("leonie", "레오니 발렌하르트. 은사자 기사단장이다.")
	await c.say("leonie", "여긴 마녀 놀이터가 아니다. 짐승은 우리가 벤다.", "stern")
	await c.say("sera", "놀러 온 거 아니거든요!", "angry")
	await c.say("leonie", "…그렇다면 연무장으로 와라. 놀러 온 게 아닌지, 내 눈으로 보겠다.")
	c.close_box()
	await c.walk("leonie", 119.0, 80.0)
	c.hide_actor("leonie")
	await c.say("neoul", "…저 계집, 마력이 한 톨도 없구나. 헌데 그 검은 바람보다 빨랐다.", "sad")
	await c.say("sera", "…멋있다.", "happy")
	await c.say("neoul", "흥. 감탄은 나중에 하거라. 연무장이라 했지.")
	c.close_box()
	c.flag("k_met_leonie")
	c.save()


# ═══════════════════════════════════════════════════════════
# 3. 기사단 연무장 — 목검 대련 · 성벽 위 대화
# ═══════════════════════════════════════════════════════════

func k_spar(c: Cut) -> void:
	if c.has("k_spar_done") or not c.has("k_met_leonie"):
		return
	c.lock()
	await c.player_walk(34.0)
	c.player_face(1)
	await c.say("leonie", "왔군.")
	await c.say("leonie", "목검이다. 규칙은 간단하다. 내게 세 번 맞히거나 — 일 분을 버텨라.")
	await c.say("kael", "단장님 상대로 일 분이요?! 저는 십 초도 못 버티는데!", "surprised")
	await c.say("leonie", "카엘. 조용.")
	await c.say("sera", "불은… 써도 돼요?", "surprised")
	await c.say("leonie", "써라. 안 쓰면 일 초도 못 버틴다.")
	c.close_box()
	var n := c.actor("leonie") as Node2D
	var lx := (n.global_position.x / 16.0) if n else 46.0
	c.hide_actor("leonie")
	var sp := c.spawn_enemy("leonie_spar", lx - 0.5, 19.0, "spar", {"engaged": false})
	if sp == null:
		c.flag("k_spar_done")
		return
	sp.facing = -1
	c.music("knight_duel", 0.4)
	await c.title_card("대련", "세 번 맞히거나 · 60초 버티기", 1.4)
	sp.engaged = true
	c.release()
	var sp_ref: WeakRef = weakref(sp)
	await c.wait_until(func() -> bool: return _gone_or(sp_ref, "result"), 240.0)
	if not c.ok():
		return
	c.lock()
	var result := String(sp.get("result")) if is_instance_valid(sp) else "time"
	await c.wait(0.8)
	var ln := c.actor("leonie") as Node2D
	if is_instance_valid(sp):
		var pos := sp.global_position
		sp.queue_free()
		if ln:
			ln.global_position = pos
	if ln:
		ln.visible = true
		ln.process_mode = Node.PROCESS_MODE_INHERIT
		c.face("leonie", -1 if c.player.global_position.x < ln.global_position.x else 1)
	c.music("kingdom", 1.0)
	match result:
		"hits":
			await c.say("leonie", "…세 번.", "surprised")
			await c.say("leonie", "나쁘지 않군.", "happy")
		"time":
			await c.say("leonie", "…일 분. 끝까지 눈을 감지 않았군.")
			await c.say("leonie", "나쁘지 않군.", "happy")
		_:
			await c.say("leonie", "그만. 오늘은 여기까지다.")
			await c.say("sera", "아, 아직… 할 수 있어요…!", "sad")
			await c.say("leonie", "알고 있다. 넘어져도 불을 꺼뜨리지 않더군. …나쁘지 않군.", "happy")
	c.emote("kael", "!")
	await c.say("kael", "단장님이 '나쁘지 않군'이라니! 마녀님, 그거 단장님 최고 칭찬이에요! 저는 삼 년 동안 한 번도…!", "surprised")
	await c.say("leonie", "카엘.")
	await c.say("kael", "…조용히 하겠습니다.", "sad")
	await c.say("leonie", "세라피나라고 했지. 따라와라. 성벽 위에서 할 말이 있다.")
	c.close_box()
	c.flag("k_spar_done")
	await c.walk("leonie", 72.0, 70.0)
	c.hide_actor("leonie")
	await c.say("neoul", "…칼이 보이지도 않더구나. 막는 법을 배워야겠어, 세라.", "sad")
	await c.say("sera", "막는 법… 엠버린 선생님이 '불꽃 방벽' 수업을 하신다고 했었지.")
	c.close_box()
	c.bubble("학교 수업 게시판에 '불꽃 방벽'이 열렸을 게다. 언제든 공관 전이진으로.", 3.4)
	c.save()


## 성벽 위: 무력(無力)과 폐급 — 2장의 정서 핵심
func k_walls_talk(c: Cut) -> void:
	if c.has("k_walls_talk") or not c.has("k_spar_done"):
		return
	c.lock()
	await c.player_walk(40.0)
	c.player_face(1)
	c.face("leonie", -1)
	await c.wait(0.4)
	await c.say("leonie", "시장에서. 짐승이 덤빌 때 겁도 없이 앞으로 나서더군.")
	await c.say("sera", "…겁은 났어요. 근데 뒤에 사람들이 있었으니까.")
	c.face("leonie", 1)
	await c.wait(0.6)
	await c.say("leonie", "나는 마력이 없다. 한 톨도.")
	await c.say("leonie", "그래서 '무력(無力)'이라 불렸지. 빈민가에서도, 기사 시험장에서도.", "sad")
	await c.wait(0.4)
	await c.say("sera", "……")
	await c.say("sera", "…나는 마력이 너무 많아서 '폐급'이에요.", "sad")
	c.face("leonie", -1)
	c.emote("leonie", "?")
	await c.say("leonie", "너무 많아서?", "surprised")
	await c.say("sera", "조절을 못 하거든요. 쏘면 터지고, 참으면 넘치고. 그래서 일반반.")
	await c.say("leonie", "…이상한 일이군.")
	await c.say("leonie", "없어서 버림받은 자와, 넘쳐서 버림받은 자가 같은 성벽 위에 서 있다니.", "happy")
	c.close_box()
	c.bubble("…흥.", 1.4)
	await c.wait(0.8)
	await c.say("leonie", "세라피나. 저기 — 굴뚝 그을음 사이로 별가루 자국이 보이나?")
	await c.camera_to(Vector2(80.0, 120.0), 1.2)
	await c.say("leonie", "짐승들은 밤마다 지붕을 타고 다닌다. 흔적은 저 지붕들을 넘어 시계 구역 쪽으로 이어진다.")
	await c.camera_back(0.8)
	await c.say("leonie", "나는 기사단과 땅 밑을 뒤진다. 너는 위를 맡아라.")
	await c.say("sera", "지붕 위요? …아, 날개!", "happy")
	await c.say("leonie", "서쪽 끝 철창을 열어 두지. 굴뚝 열기를 타면 높이 오를 수 있을 거다.")
	await c.say("leonie", "떨어지지 마라. 주워 담을 기사가 없다.")
	c.close_box()
	c.flag("k_walls_talk")
	c.sfx("door")
	await c.walk("leonie", 12.0, 70.0)
	c.hide_actor("leonie")
	c.save()


# ═══════════════════════════════════════════════════════════
# 4. 지붕 — 이졸데 지붕 경주(서브)
# ═══════════════════════════════════════════════════════════

func _race_time() -> float:
	return GameState.run_time - float(GameState.flag("k_race_t0", 0.0))


func enter_k_roof_1(c: Cut) -> void:
	if not c.has("k_roof_intro"):
		c.flag("k_roof_intro")
		c.bubble("굴뚝 연기가 따뜻하구나. 날개를 펴고 그 열기를 타 보거라.", 3.2)
	elif c.has("k_race_on"):
		Story.toast("경주 — %d초" % int(_race_time()), 1.4)


func enter_k_roof_2(c: Cut) -> void:
	if c.has("k_race_on"):
		Story.toast("경주 — %d초 / %d초" % [int(_race_time()), int(RACE_LIMIT)], 1.6)
	elif not c.has("k_roof2_intro"):
		c.flag("k_roof2_intro")
		c.bubble("빨래 너머 저 집… 벽이 어딘가 어색하구나. 여우창문으로 들여다보거라.", 3.2)


func enter_k_roof_3(c: Cut) -> void:
	if c.has("k_race_on"):
		Story.toast("경주 — %d초 / %d초" % [int(_race_time()), int(RACE_LIMIT)], 1.6)


## 지붕4(시계 거리 위): 시계 구역 도착 + 경주 결승
func enter_k_roof_4(c: Cut) -> void:
	if c.has("k_walls_talk") and not c.has("k_clock_arrived"):
		c.flag("k_clock_arrived")
	if c.has("k_race_on"):
		await _race_finish(c)


func _race_finish(c: Cut) -> void:
	var t := _race_time()
	c.flag("k_race_on", false)
	c.lock()
	await c.wait(0.3)
	var p := c.player_tile()
	if t <= RACE_LIMIT:
		Story.toast("결승! %d초" % int(t), 2.0)
		c.sfx("checkpoint", 2.0)
		await c.wait(0.8)
		c.spawn_npc("isolde", p.x - 8.0, p.y - 8.0, 1)
		c.sfx("glide")
		await c.move("isolde", p.x - 3.0, p.y, 0.9, Tween.TRANS_QUAD)
		c.sfx("land")
		await c.say("isolde", "…헉, 헉. 쳇.", "angry")
		await c.say("isolde", "졌어. 인정할게.", "sad")
		await c.say("sera", "어? 이졸데가 인정을 다 하네?", "smug")
		await c.say("isolde", "…시끄러워, 세라.", "smug")
		c.emote("sera", "!")
		await c.say("sera", "…방금 나 이름으로 불렀어?", "surprised")
		await c.say("isolde", "착각이야. 바람 소리겠지. …다음엔 안 져.", "happy")
		c.close_box()
		c.flag("k_race_won")
		await c.quest_done("k_isolde_race")
		c.bubble("흐흥. 저 아이, 귀가 빨갛구나.", 2.4)
	else:
		Story.toast("시간 초과 — %d초" % int(t), 2.0)
		await c.wait(0.6)
		c.spawn_npc("isolde", p.x - 3.0, p.y, 1)
		await c.say("isolde", "늦었어, 폐급. 난 벌써 차 한 잔 마셨는데.", "smug")
		await c.say("isolde", "…다시 할 거면 굴뚝 숲으로 와. 기다려 줄 테니까.")
		c.close_box()
		c.quest_step("k_isolde_race", 0)
		c.hide_actor("isolde")
