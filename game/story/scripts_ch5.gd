extends RefCounted
## 5장 대본 (docs/chapter5.md). 메서드 이름 = 실행 ID, func id(c: Cut) -> void.
## 1단계(에셋·설계): 시험용 대본(dev_ch5_*)만 있다. 실제 장면 대본은 2단계에서 docs/chapter5.md 11절 목록대로.
##   dev_ch5_portrait  초상화 진열 (리라 8·교장 7·너울 본모습 6 표정)
##   dev_ch5_poses     리라 자세 진열 (2배 확대)
##   dev_ch5_poses_b   교장 자세 진열 (2배) + 실제 크기 리라·교장
##   dev_ch5_awaken    아홉 꼬리 각성 연출 시험 (dev_st_void)
##   dev_ch5_lyra      리라 결전 시험 (dev_st_tower): 페이즈마다 짧은 대사 (phase_changed 대본 연결 예시)
##   dev_ch5_gate      하늘의 문 동료 지원 시험 (dev_st_sky): support_needed → 지원 함수 호출 예시

const LYRA_EXPRS := ["normal", "happy", "sad", "serious", "surprised", "possessed", "weak", "aged"]
const ASTRID_EXPRS := ["normal", "happy", "sad", "angry", "surprised", "tired", "wink"]
const NEOUL_EXPRS := ["normal", "angry", "sad", "gentle", "tearful", "awaken"]
const LYRA_POSES := ["idle", "run", "cast", "attack", "windup", "special", "guard", "hurt", "kneel", "down",
	"sword", "sword_windup", "sword_attack", "bow", "bow_draw", "bow_release", "spear", "spear_windup", "spear_charge", "possessed"]
const ASTRID_POSES := ["idle", "run", "cast", "attack", "windup", "shield", "hurt", "kneel", "down", "special"]


## 화면 위에 진열대를 하나 깐다 (방을 옮기면 사라짐)
func _gallery_layer(c: Cut, dim := 0.0) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 40
	c.world.room.add_child(layer)
	if dim > 0.0:
		var bg := ColorRect.new()
		bg.color = Color(0.02, 0.02, 0.05, dim)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.size = Vector2(640, 360)
		layer.add_child(bg)
	return layer


func _label(layer: CanvasLayer, text: String, pos: Vector2) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color(0.85, 0.85, 1.0, 0.8))
	layer.add_child(l)


func dev_ch5_portrait(c: Cut) -> void:
	c.hud(false)
	var layer := _gallery_layer(c, 0.85)
	var rows := [["lyra", LYRA_EXPRS], ["astrid", ASTRID_EXPRS], ["neoul_god", NEOUL_EXPRS]]
	for ri in rows.size():
		var who: String = rows[ri][0]
		var exprs: Array = rows[ri][1]
		for i in exprs.size():
			var p := Portrait.new()
			p.position = Vector2(8 + i * 78, 14 + ri * 112)
			p.size = Vector2(72, 72)
			p.set_speaker(who, String(exprs[i]))
			layer.add_child(p)
			_label(layer, String(exprs[i]), p.position + Vector2(2, 74))
	await c.wait(0.2)


func dev_ch5_poses(c: Cut) -> void:
	await _lyra_page(c, 0)


func dev_ch5_poses2(c: Cut) -> void:
	await _lyra_page(c, 1)


## 리라 자세 10개씩 (5개 × 2줄, 2배 확대)
func _lyra_page(c: Cut, page: int) -> void:
	c.hud(false)
	var layer := _gallery_layer(c, 0.55)
	for k in 10:
		var i := page * 10 + k
		if i >= LYRA_POSES.size():
			break
		var v := CharacterVisual.new()
		v.setup("lyra")
		v.set_pose(String(LYRA_POSES[i]))
		v.position = Vector2(64 + (k % 5) * 128, 160 + (k / 5) * 178)
		v.scale = Vector2(2, 2)
		layer.add_child(v)
		_label(layer, String(LYRA_POSES[i]), v.position + Vector2(-30, 2))
	await c.wait(0.2)


func dev_ch5_poses_b(c: Cut) -> void:
	c.hud(false)
	var layer := _gallery_layer(c, 0.45)
	for i in ASTRID_POSES.size():
		var v := CharacterVisual.new()
		v.setup("astrid")
		v.set_pose(String(ASTRID_POSES[i]))
		v.position = Vector2(34 + i * 62, 140)
		v.scale = Vector2(2, 2)
		layer.add_child(v)
		_label(layer, String(ASTRID_POSES[i]), v.position + Vector2(-26, 4))
	# 실제 크기 (1배): 세라 키와 나란히 보는 용도
	var sample := ["idle", "cast", "sword_windup", "bow_draw", "spear_charge", "special", "kneel", "possessed"]
	for i in sample.size():
		var v2 := CharacterVisual.new()
		v2.setup("lyra")
		v2.set_pose(String(sample[i]))
		v2.position = Vector2(40 + i * 46, 300)
		layer.add_child(v2)
	for i in 4:
		var v3 := CharacterVisual.new()
		v3.setup("astrid")
		v3.set_pose(["idle", "cast", "shield", "special"][i])
		v3.position = Vector2(430 + i * 52, 300)
		layer.add_child(v3)
	await c.wait(0.2)


## 아홉 꼬리 각성 시험 (dev_st_void): 천을 걷고 → 각성 → 빛이 되어 세라에게
func dev_ch5_awaken(c: Cut) -> void:
	c.lock()
	var g := c.actor("neoul_god")
	if g == null:
		return
	g.set_talking(true)
	await c.wait(0.6)
	g.set_talking(false)
	g.unveil(true)
	await c.wait(1.6)
	await g.awaken()
	await c.wait(0.8)
	await g.merge_into(c.player.center(), 1.4)
	await c.wait(0.5)


## 리라 결전 대본 연결 예시 (dev_st_tower): 페이즈마다 전환을 붙잡고 짧은 대사를 넣은 뒤 resume()
func dev_ch5_lyra(c: Cut) -> void:
	c.release()
	var boss := c.spawn_enemy("lyra_boss", 30, 19, "lyra")
	if boss == null:
		return
	boss.set("hold_transition", true)
	boss.set("auto_lines", true)
	boss.phase_changed.connect(func(n: int) -> void:
		Story.toast("리라 — %d페이즈" % n, 1.6)
		await c.wait(1.2)
		if is_instance_valid(boss):
			boss.resume())
	boss.engaged = true
	await c.wait_enemy(boss)


## 하늘의 문 지원 연결 예시 (dev_st_sky): 동료 시스템 대신 support_needed에 바로 지원 함수를 잇는다
func dev_ch5_gate(c: Cut) -> void:
	c.release()
	var gate := c.spawn_enemy("sky_gate", 20, 10, "gate")
	if gate == null:
		return
	gate.support_needed.connect(_gate_support.bind(gate))
	gate.engaged = true
	await c.wait_enemy(gate)


## 하늘의 문이 지원을 청할 때 (동료 시스템이 들어오면 동료가 이 자리에서 special 연출 + 같은 함수를 부른다)
func _gate_support(kind: String, _pos: Vector2, gate: Node) -> void:
	if not is_instance_valid(gate):
		return
	match kind:
		"tendril", "hand":
			gate.cut_tendril()
		"eye":
			gate.snipe_eye()
		"veil":
			gate.holy_lance(5.0)
		"shield":
			gate.star_shield(3.0)
