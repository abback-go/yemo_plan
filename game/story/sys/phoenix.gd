extends RefCounted
## 공통 시스템 대본 — 불사조 수업 (그레타·교장 서명·재의 서고·둥지·불 속의 나).
## 메서드 이름 = 실행 ID (docs/dev/story.md).


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
