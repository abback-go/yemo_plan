class_name Npc
extends Interactable
## 학교 인물. ↑로 말을 걸면 talk 스크립트(없으면 "npc_<who>")를 실행한다.
## 컷신에서는 Story가 walk_to·face·emote로 움직인다.

var who := ""
var talk := ""
var facing := 1
var visual: CharacterVisual
var _flip: Node2D
var _emote := ""
var _emote_t := 0.0
var _font: Font


func setup(p_room: Room, e: Dictionary, eid: String) -> void:
	room = p_room
	who = String(e.get("who", eid))
	talk = String(e.get("talk", "npc_" + who))
	position = room.tile_pos(e) + Vector2(8, 0)
	facing = -1 if String(e.get("face", "left")) == "left" else 1
	prompt = "말 걸기 — " + Characters.display_name(who)
	area_size = Vector2(30, 40)
	z_index = 1
	_flip = Node2D.new()
	add_child(_flip)
	visual = CharacterVisual.new()
	visual.setup(who)
	_flip.add_child(visual)
	_flip.scale.x = facing
	_font = ThemeDB.fallback_font
	GameState.flag_changed.connect(_on_flag_changed)


func actor_id() -> String:
	return who


func interact() -> void:
	var w := World.get_world()
	if w:
		# 말을 걸면 세라 쪽을 바라봄
		face(1 if w.player.global_position.x > global_position.x else -1)
	Story.run(talk)


func face(dir: int) -> void:
	if dir == 0:
		return
	facing = dir
	_flip.scale.x = facing


func walk_to(x: float, speed := 60.0) -> void:
	var dist := absf(x - global_position.x)
	if dist < 1.0:
		return
	face(1 if x > global_position.x else -1)
	visual.walking = true
	var t := create_tween()
	t.tween_property(self, "global_position:x", x, dist / speed)
	await t.finished
	visual.walking = false


func emote(kind: String, time := 1.2) -> void:
	_emote = kind
	_emote_t = time


var _mark := "" ## 퀘스트 표시: "!" 받을 수 있음 · "…" 진행 중
var _mark_t := 0.0
var _t := 0.0
## 퀘스트 상태는 GameState 플래그로만 바뀐다 → 플래그가 바뀐 뒤에만 다시 조회한다.
## 표시가 바뀌는 시점(0.5초 주기)은 예전 폴링과 같게 둔다.
var _quest_dirty := true
var _flags_seen: Dictionary ## 새 게임·불러오기는 flags 사전을 통째로 바꾸고 신호를 안 낸다 → 같은 사전인지 확인


func _on_flag_changed(_key: String) -> void:
	_quest_dirty = true


func _process(delta: float) -> void:
	_t += delta
	_mark_t -= delta
	if _mark_t <= 0.0:
		_mark_t = 0.5
		if _quest_dirty or not is_same(_flags_seen, GameState.flags):
			_quest_dirty = false
			_flags_seen = GameState.flags
			var m := ""
			if Quests.available_for(who) != "":
				m = "!"
			elif Quests.active_for(who):
				m = "…"
			if m != _mark:
				_mark = m
				queue_redraw()
	if _emote_t > 0.0:
		_emote_t -= delta
		if _emote_t <= 0.0:
			_emote = ""
		queue_redraw()
	elif _mark != "":
		queue_redraw()


func _draw() -> void:
	if _emote == "" and _mark != "":
		var hh := float(visual.info.get("height", 32))
		var y := -hh - 20.0 + sin(_t * 4.0) * 1.5
		var col := Palette.GOLD if _mark == "!" else Color(0.75, 0.85, 1.0)
		draw_string_outline(_font, Vector2(-3, y), _mark, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color(0, 0, 0, 0.7))
		draw_string(_font, Vector2(-3, y), _mark, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
		return
	if _emote == "":
		return
	var h := float(visual.info.get("height", 32))
	var pop := clampf((1.2 - _emote_t) * 8.0, 0.0, 1.0)
	BubbleDraw.draw_emote(self, _font, Vector2(0, -h - 22), pop, BubbleDraw.glyph(_emote, "npc"), false)
