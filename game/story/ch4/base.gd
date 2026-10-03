extends RefCounted
## 4장 대본 — 바탕: 공용 도우미 + 개발·시험용 대본(dev_ch4_*). (docs/chapter4.md 7.8절)
## 대본 파일 사슬: story/scripts_ch4.gd(메인 이야기) → story/ch4/talk.gd(인물 대화·서브 퀘스트) → 이 파일.
## Story는 scripts_ch4.gd 하나만 읽지만, 상속이라 세 파일의 메서드가 모두 대본 ID가 된다.

const T := 16.0
const HolyChaser := preload("res://world/entities/ch4/holy_chaser.gd")


# ─── 공용 도우미 ─────────────────────────────────────────

func _ptile(c: Cut) -> Vector2:
	return c.player.global_position / T


func _npc(c: Cut, who: String) -> Npc:
	return c.actor(who) as Npc


## 인물(Npc)의 자세 (아우렐리아 전용 그림: idle·guard·cast·kneel·special·berserk_* …)
func _pose(c: Cut, who: String, p: String) -> void:
	var n := _npc(c, who)
	if n:
		n.visual.set_pose(p)


func _leonie(c: Cut) -> Ally:
	return c.ally("leonie")


## 레오니 동행 시작 (tp_leonie_on — 방 장치 tp_ally가 저장·부활 뒤에도 다시 불러 줌)
func _leonie_join(c: Cut, x_t := INF, y_t := INF) -> Ally:
	c.flag("tp_leonie_on")
	var a := c.ally_join("leonie", x_t, y_t)
	a.mode = "follow"
	return a


func _leonie_leave(c: Cut) -> void:
	c.flag("tp_leonie_on", false)
	c.ally_leave("leonie")


## 레오니가 곁에 있으면 대사창으로, 없으면 아무것도 하지 않음
func _leonie_say(c: Cut, text: String, expr := "normal") -> void:
	if _leonie(c):
		await c.say("leonie", text, expr)


func _chaser(c: Cut) -> HolyChaser:
	return c.actor("holy_chaser") as HolyChaser


func _trials_count() -> int:
	var n := 0
	for k: String in ["tp_trial_mirror", "tp_trial_bell", "tp_trial_archive"]:
		if GameState.has_flag(k):
			n += 1
	return n


## 이름 순서대로 남은 시련
func _trials_left() -> String:
	var out: Array[String] = []
	if not GameState.has_flag("tp_trial_mirror"):
		out.append("빛의 거울(회랑 왼쪽)")
	if not GameState.has_flag("tp_trial_bell"):
		out.append("종탑(정원 → 성가대석 너머)")
	if not GameState.has_flag("tp_trial_archive"):
		out.append("기록실(회랑 아래)")
	return ", ".join(out)


## 시련 하나를 마침: 플래그·알림. 셋을 다 마치면 tp_trials_done
func _trial_done(c: Cut, key: String, title: String) -> void:
	c.flag(key)
	var n := _trials_count()
	c.sfx("quest_done")
	c.flash(Color(1.0, 0.9, 0.6, 0.35), 0.5)
	await c.title_card("자격의 시련 — " + title, "%d / 3" % n, 2.2)
	if n >= 3:
		c.flag("tp_trials_done")
		Story.toast("세 시련을 모두 마쳤다. 본당의 아우렐리아에게 가자.", 3.2)
	else:
		Story.toast("남은 시련: " + _trials_left(), 3.2)


## 기도 촛불 (tp_candles) 켠 수
func _candles_lit() -> int:
	var n := 0
	for i in range(1, 6):
		if GameState.has_flag("tp_candle_%d" % i):
			n += 1
	return n


# ─── 개발용: 그림 확인 ──────────────────────────────────

const AURELIA_POSES: Array[String] = ["idle", "run", "windup", "attack", "attack2", "charge", "cast", "guard", "hurt", "kneel", "down", "special"]
const PORTRAIT_EXPRS: Array[String] = ["normal", "angry", "surprised", "sad", "smile", "berserk"]
const FOLK: Array[String] = ["benedicta", "luca", "gregor", "tp_monk", "tp_priest", "tp_pilgrim", "tp_pilgrim_b", "tp_choir"]


# ─── 개발용: 그림 확인 ──────────────────────────────────

## 시험 그림 지우기
static func _clear_dev(c: Cut) -> void:
	for n in c.world.get_tree().get_nodes_in_group(&"dev_ch4_overlay"):
		n.queue_free()


## 세라 둘레 화면 좌표 기준 (방 안 전역 좌표) — 카메라 왼쪽 위
static func _screen_origin(c: Cut) -> Vector2:
	var cam := c.world.player.camera
	return cam.get_screen_center_position() - Vector2(320, 180)


static func _lineup(c: Cut, who: String, poses: Array[String], cols: int, start: Vector2, gap: Vector2, scale := 1.0) -> void:
	var holder := Node2D.new()
	holder.add_to_group(&"dev_ch4_overlay")
	holder.z_index = 40
	c.world.room.add_entity(holder)
	for i in poses.size():
		var v := CharacterVisual.new()
		v.setup(who)
		v.set_pose(poses[i])
		v.position = start + Vector2(gap.x * (i % cols), gap.y * int(i / cols))
		v.scale = Vector2.ONE * scale
		holder.add_child(v)


## 아우렐리아 자세 12종 (2줄). 시나리오 ch4_aurelia_art.json이 찍는다
func dev_ch4_poses(c: Cut) -> void:
	_clear_dev(c)
	c.hud(false)
	var o := _screen_origin(c)
	_lineup(c, "aurelia", AURELIA_POSES, 6, o + Vector2(60, 150), Vector2(100, 150))


func dev_ch4_poses_berserk(c: Cut) -> void:
	_clear_dev(c)
	c.hud(false)
	var o := _screen_origin(c)
	_lineup(c, "aurelia_berserk", AURELIA_POSES, 6, o + Vector2(60, 150), Vector2(100, 150))


## 세부 확인용 3배 확대
func dev_ch4_poses_zoom(c: Cut) -> void:
	_clear_dev(c)
	c.hud(false)
	var o := _screen_origin(c)
	var zp: Array[String] = ["idle", "windup", "charge", "cast"]
	_lineup(c, "aurelia", zp, 4, o + Vector2(70, 300), Vector2(160, 0), 3.0)


func dev_ch4_poses_zoom2(c: Cut) -> void:
	_clear_dev(c)
	c.hud(false)
	var o := _screen_origin(c)
	var zp: Array[String] = ["attack", "kneel", "berserk_idle", "berserk_special"]
	_lineup(c, "aurelia", zp, 4, o + Vector2(60, 300), Vector2(160, 0), 3.0)


## 머리 세부 (8배)
func dev_ch4_head(c: Cut) -> void:
	_clear_dev(c)
	c.hud(false)
	var o := _screen_origin(c)
	var zp: Array[String] = ["idle", "berserk_idle"]
	_lineup(c, "aurelia", zp, 2, o + Vector2(160 - 12, 190 + 37 * 12), Vector2(320, 0), 12.0)


## 초상화 표정 6종을 2배로 (화면 위 겹침 층)
func dev_ch4_portrait(c: Cut) -> void:
	_clear_dev(c)
	c.hud(false)
	var layer := CanvasLayer.new()
	layer.layer = 60
	layer.add_to_group(&"dev_ch4_overlay")
	c.world.add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.04, 0.08)
	bg.size = Vector2(640, 360)
	layer.add_child(bg)
	for i in PORTRAIT_EXPRS.size():
		var p := Portrait.new()
		p.set_speaker("aurelia", PORTRAIT_EXPRS[i])
		p.size = Vector2(72, 72)
		p.scale = Vector2(2, 2)
		p.position = Vector2(40 + (i % 3) * 196, 20 + int(i / 3) * 170)
		layer.add_child(p)
		var l := Label.new()
		l.text = PORTRAIT_EXPRS[i]
		l.position = p.position + Vector2(0, 146)
		layer.add_child(l)


## 신전 사람들 몸 그림 + 초상화
func dev_ch4_folk(c: Cut) -> void:
	_clear_dev(c)
	c.hud(false)
	var o := _screen_origin(c)
	var poses: Array[String] = []
	for i in FOLK.size():
		poses.append("idle")
	var holder := Node2D.new()
	holder.add_to_group(&"dev_ch4_overlay")
	holder.z_index = 40
	c.world.room.add_entity(holder)
	for i in FOLK.size():
		var v := CharacterVisual.new()
		v.setup(FOLK[i])
		v.position = o + Vector2(50 + i * 72, 330)
		v.scale = Vector2(2, 2)
		holder.add_child(v)
	var layer := CanvasLayer.new()
	layer.layer = 60
	layer.add_to_group(&"dev_ch4_overlay")
	c.world.add_child(layer)
	for i in FOLK.size():
		var p := Portrait.new()
		p.set_speaker(FOLK[i], "normal" if i % 2 == 0 else "happy")
		p.size = Vector2(72, 72)
		p.position = Vector2(8 + i * 79, 8)
		layer.add_child(p)


## 시험: 불꽃 방벽으로 되쏜 탄(Hit.kind = reflect)이 정면에서 맞은 것처럼 (공통 방벽이 아직 없을 때)
func dev_ch4_reflect_hit(c: Cut) -> void:
	for n in c.world.get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
		var e := n as EnemyBase
		if e and e.is_alive():
			var h := Hit.make(150, &"reflect", e.global_position + Vector2(e.facing * 40, -18))
			e.take_hit(h)


func dev_ch4_clear(c: Cut) -> void:
	_clear_dev(c)
	c.hud(true)


## 대사창에서 아우렐리아 말투 확인 (시나리오가 넘김)
func dev_ch4_lines(c: Cut) -> void:
	await c.say("aurelia", "이단의 마녀는 들어올 수 없습니다. 물러나십시오.")
	await c.say("aurelia", "…주께서 대답하지 않으십니다.", "sad")
	await c.say("aurelia_berserk", "물러—나—십시오. 빛을, 더럽히는—자.", "berserk")
	await c.say("aurelia", "…빛을 지킨 것은 당신이었습니다.", "smile")
