class_name Cut
extends RefCounted
## 컷신 도우미. 대본 메서드가 이것을 받아 순서대로 연출한다.
##   await c.say("pippa", "세라!", "happy")      대사 (초상화·이름·타자 효과)
##   await c.narrate("…")                        해설 (초상화 없음)
##   var i = await c.choose("세라", "질문", ["예", "아니오"])
##   await c.wait(0.5) · await c.walk("pippa", 12) · c.face("pippa", -1) · c.emote("pippa", "!")
##   await c.player_walk(20) · c.player_face(1) · await c.camera_to(Vector2(..)) · c.camera_back()
##   c.shake(0.2) · c.flash(Color.WHITE) · c.sfx("door") · c.music("school") · await c.fade_out() · await c.fade_in()
##   c.flag("met_pippa") · await c.learn("storm") · await c.teach("제목", "설명", ["jump"]) · c.bubble("너울의 혼잣말")
##   c.release() — 조작을 먼저 돌려줌 (대본이 계속 돌아도 플레이 가능)

var world: World
var player: Player
var _released := false
var _gen := 0


func _init(w: World) -> void:
	world = w
	player = w.player
	_gen = Story.generation()


## 대본이 아직 유효한가 (쓰러져 부활했으면 false → 대본은 그만둘 것)
func ok() -> bool:
	return _gen == Story.generation() and is_instance_valid(world)


func begin() -> void:
	player.controls_enabled = false
	player.halt()
	freeze_enemies(true)


func finish() -> void:
	if Story.busy_count() > 1:
		return # 방을 옮기며 다음 방의 대본에 넘겨줌 — 그쪽이 조작·HUD를 정한다
	world.dialogue.close()
	world.pet.release_script()
	freeze_enemies(false)
	if not _released:
		player.controls_enabled = true
	world.hud.visible = true


## 잠그지 않고 시작 (조작은 그대로). 끝날 때 조작을 건드리지 않음
func soft() -> void:
	_released = true


func release() -> void:
	_released = true
	world.dialogue.close()
	player.controls_enabled = true
	freeze_enemies(false)


func lock() -> void:
	_released = false
	player.controls_enabled = false
	player.halt()
	freeze_enemies(true)


## 컷신 동안 적과 적의 탄을 멈춤 (보스 등장처럼 움직여야 하면 대본에서 freeze_enemies(false))
func freeze_enemies(on: bool) -> void:
	if not is_instance_valid(world) or world.room == null:
		return
	var mode := Node.PROCESS_MODE_DISABLED if on else Node.PROCESS_MODE_INHERIT
	for e in world.room.enemies:
		if is_instance_valid(e):
			e.process_mode = mode
	for a in world.get_tree().get_nodes_in_group(&"enemy_attack"):
		if a is EnemyProjectile:
			a.process_mode = mode


# ─── 대사 ───────────────────────────────────────────────

func say(who: String, text: String, expr := "normal") -> void:
	var a := actor(who)
	if a and a.has_method("set_talking"):
		a.set_talking(true)
	await world.dialogue.show_line(who, text, expr)
	if a and a.has_method("set_talking"):
		a.set_talking(false)


func narrate(text: String) -> void:
	await world.dialogue.show_line("narration", text)


func choose(who: String, text: String, options: Array) -> int:
	world.dialogue.show_line(who, text)
	await world.get_tree().create_timer(0.05, true, false, true).timeout
	var i: int = await world.dialogue.choose(options)
	world.dialogue.advanced.emit()
	return i


func close_box() -> void:
	world.dialogue.close()


func bubble(text: String, time := 2.5) -> void:
	world.pet.bubble(text, time)


# ─── 시간·연출 ──────────────────────────────────────────

func wait(sec: float) -> void:
	await world.get_tree().create_timer(sec, true, false, true).timeout


func shake(amp := 0.2, dur := 0.3) -> void:
	Fx.shake(amp, dur)


func flash(color := Color(1, 1, 1, 0.8), dur := 0.3) -> void:
	Fx.flash(color, dur)


func sfx(name: String, vol := 0.0) -> void:
	Sfx.play(StringName(name), vol, 0.0)


func music(name: String, fade := 1.0) -> void:
	Music.play(name, fade)


func fade_out(t := 0.5, color := Color.BLACK) -> void:
	await world.fade.fade_out(t, color)


func fade_in(t := 0.5) -> void:
	await world.fade.fade_in(t)


func hud(on: bool) -> void:
	world.hud.visible = on


func vignette(strength: float) -> void:
	Fx.set_vignette(strength)


## 날씨 입자 (방을 옮기면 사라짐): fox_rain(푸른 여우비) · dust(무너지는 먼지)
func weather(kind: String) -> void:
	var p := CPUParticles2D.new()
	var size := world.room.size_px
	p.position = Vector2(size.x * 0.5, -8)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(size.x * 0.5 + 40, 4)
	p.local_coords = false
	p.z_index = 24
	match kind:
		"fox_rain":
			p.amount = 220
			p.lifetime = 1.1
			p.direction = Vector2(-0.15, 1)
			p.spread = 2.0
			p.initial_velocity_min = 380.0
			p.initial_velocity_max = 460.0
			p.gravity = Vector2.ZERO
			p.scale_amount_min = 1.0
			p.scale_amount_max = 1.0
			p.color = Color(0.55, 0.8, 1.0, 0.55)
			var g := Gradient.new()
			g.set_color(0, Color(0.6, 0.85, 1.0, 0.0))
			g.add_point(0.15, Color(0.6, 0.85, 1.0, 0.7))
			g.set_color(1, Color(0.6, 0.85, 1.0, 0.5))
			p.color_ramp = g
			p.material = Fx.add_material
		_:
			p.amount = 60
			p.lifetime = 2.0
			p.direction = Vector2.DOWN
			p.spread = 10.0
			p.initial_velocity_min = 40.0
			p.initial_velocity_max = 120.0
			p.gravity = Vector2(0, 200)
			p.scale_amount_min = 1.0
			p.scale_amount_max = 3.0
			p.color = Color(0.35, 0.32, 0.42, 0.8)
	world.effects.add_child(p)


# ─── 인물·세라 ──────────────────────────────────────────

func actor(who: String) -> Node:
	if who == "neoul":
		return world.pet
	if world.room and world.room.actors.has(who):
		return world.room.actors[who]
	return null


func walk(who: String, x_tiles: float, speed := 60.0) -> void:
	world.dialogue.close()
	var a := actor(who)
	if a and a.has_method("walk_to"):
		await a.walk_to(x_tiles * 16.0 + 8.0, speed)


## 인물이 세라 쪽으로 걸어와 dist 타일 떨어져 섬 (세라를 바라봄)
func approach(who: String, dist := 3.0, speed := 70.0) -> void:
	var a := actor(who)
	if a == null:
		return
	var px := player.global_position.x / 16.0
	var side := -1.0 if a.global_position.x < player.global_position.x else 1.0
	var room_w := world.room.size_px.x / 16.0
	var tx := clampf(px + side * dist, 1.5, room_w - 2.5)
	await walk(who, tx, speed)
	face(who, 1 if player.global_position.x > a.global_position.x else -1)


func face(who: String, dir: int) -> void:
	var a := actor(who)
	if a and a.has_method("face"):
		a.face(dir)


func emote(who: String, kind: String, time := 1.2) -> void:
	if who == "sera":
		player.emote(kind, time)
		return
	var a := actor(who)
	if a and a.has_method("emote"):
		a.emote(kind, time)


func player_walk(x_tiles: float, speed := 90.0) -> void:
	await player.walk_to(x_tiles * 16.0 + 8.0, speed)


func player_face(dir: int) -> void:
	player.facing = dir


func camera_to(pos: Vector2, time := 0.8) -> void:
	await player.camera.pan_to(pos, time)


func camera_back(time := 0.6) -> void:
	await player.camera.pan_back(time)


func marker(id: String) -> Vector2:
	if world.room and world.room.markers.has(id):
		return world.room.markers[id]
	return player.global_position


## 세라가 선 자리 (타일 좌표, 소수). 인물을 세라 곁에 세울 때 기준
func player_tile() -> Vector2:
	return player.global_position / 16.0


## 방 인물(Npc) — 다른 등장물(너울·actor)이면 null
func npc(who: String) -> Npc:
	return actor(who) as Npc


## 인물의 위치 (없으면 세라 위치)
func actor_pos(who: String) -> Vector2:
	var a := actor(who)
	if a is Node2D:
		return (a as Node2D).global_position
	return player.global_position


## 인물(Npc)의 자세 (그림 Pose 이름: idle·kneel·cast… 전용 그림은 그 파일의 이름). Npc가 아니면 무시
func pose(who: String, p: String) -> void:
	var n := npc(who)
	if n and n.visual:
		n.visual.set_pose(p)


## 세라 곁(같은 높이, dx 타일 옆)에 인물을 세움. 세라 쪽을 바라본다
func beside(who: String, dx: float) -> Npc:
	var p := player_tile()
	return spawn_npc(who, p.x + dx, p.y, -1 if dx > 0.0 else 1)


## 빛 입자 한 번 (가산 합성, col에서 투명으로 사라짐). opts는 Fx.burst와 같음 (spread·speed_min·lifetime …)
func burst(pos: Vector2, amount: int, col: Color, opts := {}) -> CPUParticles2D:
	var o := {gradient = Palette.fade_gradient(col), add = true}
	o.merge(opts, true)
	return Fx.burst(pos, amount, o)


# ─── 진행 ───────────────────────────────────────────────

func flag(key: String, value: Variant = true) -> void:
	GameState.set_flag(key, value)


func has(key: String) -> bool:
	return GameState.has_flag(key)


## 선 플래그 수 (모으기 퀘스트: 씨앗·책·촛불 …). 대본 밖에서도 Cut.count([...])
static func count(flags: Array) -> int:
	var n := 0
	for k in flags:
		if GameState.has_flag(String(k)):
			n += 1
	return n


## 마법·능력 습득 연출 (확인할 때까지 멈춤)
func learn(ability: String) -> void:
	GameState.unlock_ability(ability)
	var info := Spells.ability_text(ability) # [이름, 조작, 설명] — 문구는 core/spells.gd ABILITY_TEXT
	await world.notice.ability_get(info[0], info[1], info[2])


## 멈춤 조작 안내. 누른 동작 이름을 돌려줌
func teach(title: String, text: String, keys: Array, wait_for: Array = []) -> String:
	var key := "teach_" + title
	var got: String = await world.teach.ask(title, text, keys, wait_for)
	GameState.set_flag(key)
	return got


func goto_room(room_id: String, spawn: String) -> void:
	await world.go(room_id, spawn)
	player.controls_enabled = false


func save_here(spawn: String) -> void:
	GameState.record_at(world.room.data.id, spawn)


## 위험한 공격이 세라 가까이 왔을 때까지 기다림 (퍼펙트 회피 안내용). 시간이 지나면 false
func wait_for_threat(radius := 80.0, timeout := 30.0) -> bool:
	var left := timeout
	while left > 0.0:
		if not is_instance_valid(player) or not player.is_alive():
			return false
		for a in world.get_tree().get_nodes_in_group(&"enemy_attack"):
			var area := a as EnemyAttackArea
			if area and area.active and area.dodgeable and area.global_position.distance_to(player.center()) < radius:
				return true
		await world.get_tree().physics_frame
		left -= world.get_physics_process_delta_time()
	return false


## 조건이 될 때까지 기다림 (매 물리 프레임 검사)
func wait_until(cond: Callable, timeout := 600.0) -> bool:
	var left := timeout
	while left > 0.0:
		if cond.call():
			return true
		await world.get_tree().physics_frame
		left -= world.get_physics_process_delta_time()
	return false


## 적이 쓰러지거나 체력이 hp_frac 이하가 될 때까지 기다림 (적이 사라져도 안전). timeout초가 지나도 돌아옴
func wait_enemy(e: EnemyBase, hp_frac := 0.0, timeout := 0.0) -> void:
	var wr: WeakRef = weakref(e)
	var t := 0.0
	while ok():
		var o: EnemyBase = wr.get_ref()
		if o == null or not o.is_alive() or (hp_frac > 0.0 and o.hp <= o.max_hp * hp_frac):
			return
		if timeout > 0.0 and t >= timeout:
			return
		await world.get_tree().physics_frame
		t += world.get_physics_process_delta_time()


## 방의 적 (종류로 찾기)
func enemy(kind: String) -> EnemyBase:
	if world.room == null:
		return null
	for e in world.room.enemies:
		if is_instance_valid(e) and e.kind_id == kind:
			return e
	return null


## 대본에서 적 등장 (eid가 같으면 처치 기록도 같음)
func spawn_enemy(kind: String, x_t: float, y_t: float, eid: String, props := {}) -> EnemyBase:
	var en: EnemyBase = EnemyRegistry.create(kind)
	if en == null:
		return null
	en.position = Vector2(x_t * 16.0 + 8.0, y_t * 16.0)
	en.uid = world.room.data.id + ":" + eid
	for k in props:
		en.set(k, props[k])
	en.facing = -1
	world.room.add_entity(en)
	world.room.enemies.append(en)
	burst(en.position + Vector2(0, -20), 30, Color(0.75, 0.45, 1.0), {spread = 180.0, speed_min = 40.0, speed_max = 140.0, lifetime = 0.6})
	return en


## 대본에서 인물 등장 (방을 다시 만들면 사라짐)
func spawn_npc(who: String, x_t: float, y_t: float, dir := 1) -> Npc:
	var n := Npc.new()
	n.setup(world.room, {"who": who, "x": x_t, "y": y_t, "face": "right" if dir > 0 else "left"}, who)
	world.room.add_entity(n)
	world.room.actors[who] = n
	return n


## 인물을 타일 좌표로 옮김 (떨어지기·날기 등)
func move(who: String, x_t: float, y_t: float, time := 0.6, trans := Tween.TRANS_SINE) -> void:
	var a := actor(who)
	if a == null:
		return
	var t := a.create_tween()
	t.tween_property(a, "global_position", Vector2(x_t * 16.0 + 8.0, y_t * 16.0), time).set_trans(trans).set_ease(Tween.EASE_OUT)
	await t.finished


func hide_actor(who: String) -> void:
	var a := actor(who)
	if a:
		a.visible = false
		if a is Interactable:
			a.process_mode = Node.PROCESS_MODE_DISABLED


func item(title: String, desc: String) -> void:
	world.notice.item_get(title, desc)
	await wait(1.2)


## 큰 장면 직후 자동 저장: 이 방에 기록 지점이 있으면 부활 지점도 이곳으로
func save() -> void:
	if world.room and not world.room.saves.is_empty():
		var sid: String = world.room.saves.keys()[0]
		GameState.record_at(world.room.data.id, sid)
	else:
		GameState.save_game()


func give_potions(n: int) -> void:
	GameState.potions_max = n
	GameState.potions = n


# ─── 전체판 도구 (docs/systems2.md 8절) ─────────────────

## 화면 가운데 큰 글씨 카드 (레터박스)
func title_card(title: String, sub := "", sec := 2.5) -> void:
	await world.cinema.title_card(title, sub, sec)


## 장 카드 ("2장 — 제국의 검")
func chapter_card(n: int) -> void:
	await world.cinema.chapter_card(n)


func letterbox(on: bool) -> void:
	world.cinema.letterbox(on)


## 화면 전체 색 덮기 (투명색이면 걷힘)
func tint(color: Color, time := 0.5) -> void:
	world.cinema.tint(color, time)


## 카메라 확대 (1.0 = 원래)
func zoom(z: float, time := 0.6) -> void:
	var cam := player.camera
	var tw := cam.create_tween()
	tw.tween_property(cam, "base_zoom", z, maxf(time, 0.01)).set_trans(Tween.TRANS_SINE)


## 동료 합류: 세라 옆에 나타나 함께 싸운다 (방을 옮겨도 따라옴)
func ally_join(kind: String, x_t := INF, y_t := INF) -> Ally:
	return world.ally_join(kind, x_t, y_t)


func ally_leave(kind: String) -> void:
	world.ally_leave(kind)


func ally(kind: String) -> Ally:
	return world.ally(kind)


## 동료가 없으면 합류시키고, 이미 있으면 그대로 둔다(x_t를 주면 그 자리로만 옮김 — ally_join과 달리 세라 곁으로 다시 놓지 않음)
func ensure_ally(kind: String, x_t := INF, y_t := INF) -> Ally:
	var a := ally(kind)
	if a == null:
		a = ally_join(kind, x_t, y_t)
	elif x_t != INF:
		a.global_position = Vector2(x_t * 16.0 + 8.0, y_t * 16.0)
	return a


func quest_start(id: String) -> void:
	Quests.start(id)


func quest_step(id: String, n: int) -> void:
	Quests.set_step(id, n)


## 퀘스트 완료 + 보상 알림 (확인할 때까지)
func quest_done(id: String) -> void:
	var rewards := Quests.complete(id)
	Sfx.play(&"quest_done", 0.0, 0.0)
	var title := String(Quests.def(id).get("title", id))
	var desc := "보상: " + ", ".join(rewards) if not rewards.is_empty() else "퀘스트를 마쳤다."
	world.notice.item_get("퀘스트 완료 — " + title, desc, "quest")
	await wait(1.4)


## 보상 알림 (숫자는 Rewards — core/rewards.gd). 퀘스트 보상은 quest_done이 한꺼번에 준다
func give_stones(n: int) -> void:
	Spells.add_stones(n)
	world.notice.item_get("마도석 %d개" % n, "가진 마도석 %d개. 마법서에서 마법 레벨을 올릴 수 있다." % Spells.stones(), "stone")
	await wait(1.0)


func give_feather() -> void:
	Rewards.add_max_hp(1)
	world.notice.item_get("수호의 깃털", "최대 체력이 1 늘었다.", "feather")
	await wait(1.0)


func give_heart() -> void:
	Rewards.add_max_hp(1)
	world.notice.item_get("든든한 한 끼", "최대 체력이 1 늘었다.", "food")
	await wait(1.0)


func give_potion_slot() -> void:
	Rewards.add_potion_slot(1)
	world.notice.item_get("물약 주머니", "물약을 하나 더 가지고 다닐 수 있다. (%d개)" % GameState.potions_max, "potion")
	await wait(1.0)


## 너울의 꼬리가 n개로: 짧은 연출 (너울이 빛나며 꼬리가 하나씩 돋아남)
func tails(n: int) -> void:
	var before := int(GameState.flag("tails", 1))
	GameState.set_flag("tails", n)
	var pet := world.pet
	Music.jingle("jingle_ability")
	Sfx.play(&"fox_transform", -2.0, 0.0)
	if pet:
		for i in range(before, n):
			Fx.ring(pet.global_position + Vector2(0, -8), 4.0, 40.0, Color(0.55, 0.85, 1.0), 0.5, 2.0)
			burst(pet.global_position + Vector2(0, -8), 24, Color(0.6, 0.88, 1.0),
				{spread = 180.0, speed_min = 40.0, speed_max = 140.0, lifetime = 0.6})
			await wait(0.45)
	world.notice.item_get("너울의 꼬리 %d개" % n, "너울의 힘이 조금 돌아왔다. 여우 모드가 %d초로 늘고 기운이 더 빨리 찬다." % int(player.fox_duration()), "fox")
	await wait(1.2)


func warp_unlock(area: String) -> void:
	GameState.set_flag("warp_" + area)


## 마법 습득 연출 (수업 퀘스트 끝)
func spell_learned(id: String) -> void:
	var inf := Spells.info(id)
	var ab := String(inf.get("ability", ""))
	if ab != "":
		GameState.unlock_ability(ab)
	Spells.auto_equip(id)
	Music.jingle("jingle_spell")
	await world.notice.ability_get(String(inf.get("name", id)) + " — " + Spells.grade_name(id) + " 마법", String(inf.get("keys", "")), String(inf.get("desc", "")))


## 엔딩 크레디트 (점프·공격을 누르고 있으면 빨리)
func credits(lines: Array = [], sec := 45.0) -> void:
	if lines.is_empty():
		lines = Credits.LINES
	await world.cinema.credits(lines, sec)
