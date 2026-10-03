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


func _init(w: World) -> void:
	world = w
	player = w.player


func begin() -> void:
	player.controls_enabled = false
	player.halt()


func finish() -> void:
	world.dialogue.close()
	if not _released:
		player.controls_enabled = true
	world.hud.visible = true


func release() -> void:
	_released = true
	world.dialogue.close()
	player.controls_enabled = true


func lock() -> void:
	_released = false
	player.controls_enabled = false
	player.halt()


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


# ─── 인물·세라 ──────────────────────────────────────────

func actor(who: String) -> Node:
	if who == "neoul":
		return world.pet
	if world.room and world.room.actors.has(who):
		return world.room.actors[who]
	return null


func walk(who: String, x_tiles: float, speed := 60.0) -> void:
	var a := actor(who)
	if a and a.has_method("walk_to"):
		await a.walk_to(x_tiles * 16.0 + 8.0, speed)


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


# ─── 진행 ───────────────────────────────────────────────

func flag(key: String, value: Variant = true) -> void:
	GameState.set_flag(key, value)


func has(key: String) -> bool:
	return GameState.has_flag(key)


## 마법·능력 습득 연출 (확인할 때까지 멈춤)
func learn(ability: String) -> void:
	GameState.unlock_ability(ability)
	var info: Array = {
		"storm": ["화염 폭풍", "S (패드 RB)", "앞쪽으로 몰아치는 불길. 가까운 적을 날려 보내고\n돌진하는 적을 끊어 낸다."],
		"double_jump": ["부양", "공중에서 Z (패드 A)", "공중에서 한 번 더 뛰어오른다.\n높은 곳에 닿을 수 있다."],
		"fox_window": ["여우창문", "D (패드 Y)", "손으로 여우 모양 창을 만들어 들여다본다.\n둔갑한 것의 참모습 — 환영 벽과 숨은 발판이 드러난다."],
		"fox_mode": ["빙의 — 여우 모드", "폭주 게이지가 가득 차면 자동", "너울이 폭주를 받아 다스린다. 12초 동안 푸른 여우불의 기술.\n쓰고 나면 너울의 기운이 다시 차오를 때까지 기다려야 한다."],
	}.get(ability, [ability, "", ""])
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


func give_potions(n: int) -> void:
	GameState.potions_max = n
	GameState.potions = n
