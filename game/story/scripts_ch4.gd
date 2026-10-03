extends RefCounted
## 4장 대본 (docs/chapter4.md). 메서드 이름 = 실행 ID, func id(c: Cut) -> void.
## 지금(1단계)은 개발·시험용 대본만 있다 (dev_ch4_*). 이야기 대본은 2단계에서 docs/chapter4.md 9절 목록대로.

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


func dev_ch4_clear(c: Cut) -> void:
	_clear_dev(c)
	c.hud(true)


## 대사창에서 아우렐리아 말투 확인 (시나리오가 넘김)
func dev_ch4_lines(c: Cut) -> void:
	await c.say("aurelia", "이단의 마녀는 들어올 수 없습니다. 물러나십시오.")
	await c.say("aurelia", "…주께서 대답하지 않으십니다.", "sad")
	await c.say("aurelia_berserk", "물러—나—십시오. 빛을, 더럽히는—자.", "berserk")
	await c.say("aurelia", "…빛을 지킨 것은 당신이었습니다.", "smile")
