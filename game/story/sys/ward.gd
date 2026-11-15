extends RefCounted
## 공통 시스템 대본 — 불꽃 방벽 수업 (엠버린·실습장).
## 메서드 이름 = 실행 ID (docs/dev/story.md).


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
