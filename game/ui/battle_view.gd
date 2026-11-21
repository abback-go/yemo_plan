## battle_view.gd — 전투 화면: 배경·동료 뒷모습·적·HP·예고·마녀 HP·에너지, 붉은 실, 규칙 이벤트 연출.
## 화면은 규칙 상태를 직접 읽지 않고, 이벤트로 받은 값(vm)을 그린다 → 연출 중간 값이 자연스럽게 보인다.
## HTML 판 battleview.js + motion.js 를 옮긴 것.
##
## 레이어(z): 배경 0 < 광신도 10 < 그림자 12 < 거대한 발 15(짓밟힘 환영 17) < 동료 20 < 붉은 실 40 < 손패 41~141 < 피 85 < HUD 90~
class_name BattleView
extends Node2D

var vm := {}
var layers := {}
var allies := {}       # id → {"node", "pose", "body", "acts": {pose: Sprite2D}, "shades": [Sprite2D], "box"}
var enemies := {}      # id → {"node", "body"}
var hp_ally := {}      # id → Control
var hp_enemy := {}     # id → Control
var intents := {}      # id → Control
var witch_panel: Control
var energy_orb: Control
var end_btn: Btn
var piles := {}
var hand: HandView
var blood: BloodLayer
var foot: Node2D
var foot_y := 0.0
var shadow_v := 0.0
var shadow_rect: TextureRect
var shade_mats: Array = []
var hit_pad := 0.0
var highlight_enemy: Array = []
var highlight_mode := ""
var highlight_ally: Array = []
var hot_enemy := ""
var hot_ally := ""
var hover_intent := ""
var trembling := {}
var motion_log: Array = []
var fate_tint: ColorRect
var fate_hold := ""        # 운명의 시도 중인 동료 (붉은 실을 최대로)
var _t := 0.0
var _ly := {}              # 지금 전투의 배치: layout 에 battleLayouts[encounters.<전투>.layout] 을 덮어쓴 것 (build 에서 정함)
var anim: BattleAnim = null # 움직임 시험 ?anim=a|c (ui/battle_anim.gd). 옵션이 없으면 null — 기본 화면 그대로


func D() -> Dictionary:
	return GameData.D


## 화면 배치. 전투 중이면 그 전투 배경의 배치(battleLayouts)를 덮어쓴 것 — 적 발 높이·동료 자리·거대한 발·안내 상자 높이가 배경마다 다르다
func LY() -> Dictionary:
	return _ly if not _ly.is_empty() else GameData.D.layout


## 전투(enc)의 배치: layout + battleLayouts[enc.layout] (사전 값은 한 단계 합친다)
static func layout_for(enc_id: String) -> Dictionary:
	var base: Dictionary = GameData.D.layout
	var name := str(GameData.D.encounters.get(enc_id, {}).get("layout", ""))
	var ov: Dictionary = GameData.D.get("battleLayouts", {}).get(name, {})
	if ov.is_empty():
		return base
	var out := base.duplicate()
	for k in ov:
		if ov[k] is Dictionary and base.get(k) is Dictionary:
			var m: Dictionary = base[k].duplicate()
			for kk in ov[k]:
				m[kk] = ov[k][kk]
			out[k] = m
		else:
			out[k] = ov[k]
	return out


func _ready() -> void:
	for n in ["bg", "enemies", "shadow", "foot", "allies", "threads", "blood", "hud"]:
		var l := Node2D.new()
		l.name = n
		add_child(l)
		layers[n] = l
	layers.enemies.z_index = 10
	layers.shadow.z_index = 12
	layers.foot.z_index = 15
	layers.allies.z_index = 20
	layers.threads.z_index = 40
	layers.blood.z_index = 85
	layers.hud.z_index = 90
	layers.threads.draw.connect(func(): draw_threads(layers.threads))
	hand = HandView.new()
	hand.name = "hand"
	add_child(hand)
	blood = BloodLayer.new()
	layers.blood.add_child(blood)
	shadow_rect = UI.tex_rect(UI.grad([[0, Color(0.008, 0.008, 0.024, 0.97)], [0.26, Color(0.016, 0.012, 0.03, 0.9)], [0.46, Color(0.024, 0.016, 0.04, 0.62)], [0.62, Color(0.024, 0.016, 0.04, 0.25)], [0.78, Color(0, 0, 0, 0)], [1, Color(0, 0, 0, 0)]], "v", 4, 256), Rect2(0, 0, 1920, 1080))
	layers.shadow.add_child(shadow_rect)
	layers.shadow.modulate.a = 0.0
	visible = false


# ───────── 위치 계산 ─────────
func ally_box(id: String) -> Rect2:
	var a: Dictionary = LY().allies[id]
	var sz := Assets.size(a.img)
	var ar := sz.x / sz.y if sz.y > 0 else 0.42
	var w := float(a.h) * ar
	return Rect2(float(a.x) - w / 2.0, float(a.top), w, float(a.h))


func ally_anchor(id: String) -> Vector2:
	var a: Dictionary = LY().allies[id]
	var b := ally_box(id)
	var p := b.position + b.size * Vector2(a.anchor[0], a.anchor[1])
	if allies.has(id):
		var n: Node2D = allies[id].node
		p += n.position - Vector2(float(a.x), float(a.top))
	return p


func ally_hp_pos(id: String) -> Vector2:
	var a: Dictionary = LY().allies[id]
	return Vector2(float(a.x), float(a.top) - float(LY().allyHpOffset))


func ally_hit_rect(id: String) -> Rect2:
	var b := ally_box(id)
	var hp := ally_hp_pos(id)
	var y0 := hp.y - 6.0
	return Rect2(b.position.x + b.size.x * 0.12, y0, b.size.x * 0.76, (b.position.y + minf(b.size.y * 0.42, 330.0)) - y0)


func witch_rect() -> Rect2:
	var p: Dictionary = LY().witchPanel
	return Rect2(p.x, p.y, p.w, p.h)


func foot_rect() -> Rect2:
	var g: Dictionary = LY().giant
	var sz := Assets.size(D().enemies.giant.sprite)
	var h := float(g.w) * sz.y / maxf(1.0, sz.x)
	return Rect2(float(g.cx) - float(g.w) / 2.0, float(g.bottom) - h, float(g.w), h)


func enemy_aspect(type: String) -> float:
	var sz := Assets.size(D().enemies[type].sprite)
	return sz.x / sz.y if sz.y > 0 else 2.0 / 3.0


func enemy_box(id: String) -> Rect2:
	var e = Rules.enemy(G.ctl.st, id)
	if e == null:
		return Rect2(860, 200, 200, 200)
	if str(e.slot) == "giant":
		var f := foot_rect()
		var top := maxf(0.0, f.position.y)
		return Rect2(maxf(0.0, f.position.x), top, minf(1920.0, f.size.x), float(LY().giant.bottom) - top)
	var s: Dictionary = LY().enemySlots[int(e.slot)]
	var eh := float(s.h) * float(D().enemies[e.type].get("scale", 1.0))
	var w := eh * enemy_aspect(e.type)
	return Rect2(float(s.x) - w / 2.0, float(s.feet) - eh, w, eh)


func enemy_center(id: String) -> Vector2:
	var b := enemy_box(id)
	return Vector2(b.position.x + b.size.x / 2.0, b.position.y + b.size.y * 0.45)


func intent_rect(id: String):
	var it: Control = intents.get(id)
	if it == null or not it.visible:
		return null
	return Rect2(it.position, it.size)


func target_point(who: String) -> Vector2:
	if who == "witch":
		var r := witch_rect()
		return r.get_center()
	if LY().allies.has(who):
		return ally_hp_pos(who) + Vector2(0, 60)
	return enemy_center(who)


static func in_rect(r, p: Vector2, pad := 0.0) -> bool:
	return r != null and r.grow(pad).has_point(p)


func enemy_at(p: Vector2) -> String:
	var st: Dictionary = G.ctl.st
	if st.is_empty() or st.battle == null:
		return ""
	for e in st.battle.enemies:
		if e.alive and in_rect(intent_rect(e.id), p, 6 + hit_pad):
			return e.id
	for e in st.battle.enemies:
		if not e.alive:
			continue
		var b := enemy_box(e.id)
		if in_rect(b, p, 6 + hit_pad):
			return e.id
		if str(e.slot) != "giant" and Rect2(b.position.x, b.end.y, b.size.x, 34).has_point(p):
			return e.id
	return ""


func intent_at(p: Vector2) -> String:
	var st: Dictionary = G.ctl.st
	if st.is_empty() or st.battle == null:
		return ""
	for e in st.battle.enemies:
		if e.alive and in_rect(intent_rect(e.id), p, 4 + hit_pad):
			return e.id
	return ""


func ally_at(p: Vector2) -> String:
	if in_rect(witch_rect(), p, 4 + hit_pad):
		return "witch"
	var st: Dictionary = G.ctl.st
	for id in st.party.order:
		if st.party.allies[id].status == "dead":
			continue
		if in_rect(ally_hit_rect(id), p, hit_pad):
			return id
	return ""


# ───────── 화면 구성 ─────────
func clear() -> void:
	_ly = {}
	anim = null
	for n in ["bg", "enemies", "foot", "allies", "hud"]:
		for c in layers[n].get_children():
			c.queue_free()
	hand.clear()
	G.cutin.finish_all()
	layers.shadow.modulate.a = 0.0
	allies = {}
	enemies = {}
	hp_ally = {}
	hp_enemy = {}
	intents = {}
	shade_mats = []
	vm = {}
	foot = null
	foot_y = 0.0
	shadow_v = 0.0
	trembling = {}
	blood.clear_all()
	highlight_enemy = []
	highlight_ally = []
	hot_enemy = ""
	hot_ally = ""
	hover_intent = ""
	visible = false


func build(st: Dictionary) -> void:
	clear()
	visible = true
	layers.foot.z_index = 15
	var b: Dictionary = st.battle
	_ly = layout_for(str(b.enc))
	anim = BattleAnim.create(self)
	var ly := LY()
	var bg := Sprite2D.new()
	var enc_d: Dictionary = D().encounters[b.enc]
	var bg_file: String = str(enc_d.get("bg", ly.bg))
	bg.texture = Assets.tex(bg_file)
	bg.centered = false
	bg.scale = Vector2(1920, 1080) / Assets.size(bg_file)
	if enc_d.get("dim", false) and b.kind != "giant":   # (옛 배경을 어둡게 쓰던 전투)
		bg.modulate = Color(0.82, 0.78, 0.8)
	# 운명의 시도: 시간이 멈춘 붉은 덮개 (fate_freeze)
	fate_tint = ColorRect.new()
	fate_tint.color = Color(0.5, 0.0, 0.05, 0.0)
	fate_tint.size = Vector2(1920, 1080)
	fate_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fate_tint.z_index = 25
	layers.bg.add_child(fate_tint)
	layers.bg.add_child(bg)
	# 동료 뒷모습
	for id in st.party.order:
		_make_ally(st, id)
	for e in b.enemies:
		make_enemy(e)
	_make_hud(st)
	vm = {
		"kind": b.kind, "enc": b.enc, "turn": b.turn,
		"hp": {}, "maxHp": {}, "status": {}, "enemyAlive": {}, "intents": {},
		"hand": b.hand.duplicate(), "ghost": "", "ghostIndex": -1,
		"energy": b.energy, "drawCount": b.draw.size(), "discardCount": b.discard.size(),
		"shadow": (0.95 if b.shadow else 0.78) if b.kind == "giant" else 0.0, "tension": 0.0, "pull": 0.0, "broken": null}
	sync_from_state(st)
	set_shadow(vm.shadow, 0)
	hand.layout_static(true)
	render()
	for u in vm.hand:
		if hand.cards.has(u):
			hand.cards[u].alpha = 1.0


func _make_ally(st: Dictionary, id: String) -> void:
	var a: Dictionary = st.party.allies[id]
	var conf: Dictionary = LY().allies[id]
	var box := ally_box(id)
	var node := Node2D.new()
	node.position = Vector2(float(conf.x), float(conf.top))   # 기준점: 머리 위 가운데 (transform-origin 50% 0)
	layers.allies.add_child(node)
	var pose := Node2D.new()
	node.add_child(pose)
	var body := Node2D.new()
	pose.add_child(body)
	var spr := _sprite(conf.img, Rect2(-box.size.x / 2.0, 0, box.size.x, box.size.y))
	body.add_child(spr)
	var shades := [_shade_of(spr, float(conf.top))]
	body.add_child(shades[0])
	var acts := {}
	var poses: Dictionary = LY().poses.get(id, {})
	for pname in poses:
		var p: Dictionary = poses[pname]
		var base := Assets.size(conf.img)
		var sz := Assets.size(p.img)
		if base.y <= 0 or sz.y <= 0:
			continue
		var k := float(conf.h) / base.y
		var w := sz.x * k
		var h := sz.y * k
		var act := Node2D.new()
		act.modulate.a = 0.0
		var asp := _sprite(p.img, Rect2(-w / 2.0 + float(p.get("dx", 0)), box.size.y - h + float(p.get("dy", 0)), w, h))
		act.add_child(asp)
		var ash := _shade_of(asp, float(conf.top))
		act.add_child(ash)
		shades.append(ash)
		pose.add_child(act)
		acts[pname] = act
	allies[id] = {"node": node, "pose": pose, "body": body, "acts": acts, "shades": shades, "box": box, "base": node.position}
	if anim:
		anim.setup_ally(id, allies[id], float(conf.top))
	if a.status == "dead":
		node.visible = false


func _sprite(file: String, r: Rect2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = Assets.tex(file)
	s.centered = false
	s.position = r.position
	var sz := Assets.size(file)
	if sz.x > 0:
		s.scale = r.size / sz
	return s


func _shade_of(src: Sprite2D, base_y: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = src.texture
	s.centered = false
	s.position = src.position
	s.scale = src.scale
	var m := ShaderMaterial.new()
	m.shader = preload("res://ui/shaders/shade.gdshader")
	m.set_shader_parameter("opacity", shadow_v)
	# 그림 위·아래 끝의 화면 y (그림자 세로 그라데이션을 화면 기준으로 맞춘다)
	var y0 := base_y + src.position.y
	m.set_shader_parameter("y0", y0)
	m.set_shader_parameter("y1", y0 + src.texture.get_height() * src.scale.y)
	s.material = m
	shade_mats.append(m)
	return s


func make_enemy(e: Dictionary) -> void:
	var ly := LY()
	var node := Node2D.new()
	if str(e.slot) == "giant":
		node = _make_foot()
		foot = node
	else:
		var s: Dictionary = ly.enemySlots[int(e.slot)]
		var eh := float(s.h) * float(D().enemies[e.type].get("scale", 1.0))
		var w := eh * enemy_aspect(e.type)
		node.position = Vector2(float(s.x), float(s.feet))   # 기준점: 발 (transform-origin 50% 100%)
		var spr := _sprite(D().enemies[e.type].sprite, Rect2(-w / 2.0, -eh, w, eh))
		var tint = D().enemies[e.type].get("tint")
		if tint is Array:
			spr.modulate = Color(tint[0], tint[1], tint[2])
		node.add_child(spr)
		layers.enemies.add_child(node)
		if anim:
			anim.setup_enemy(str(e.id), node)
	enemies[e.id] = {"node": node}
	# HP
	var hp := EnemyHp.new()
	hp.giant = str(e.slot) == "giant"
	if hp.giant:
		hp.position = Vector2(ly.giant.cx, ly.giant.feetY)
	else:
		var es: Dictionary = ly.enemySlots[int(e.slot)]
		var top := float(es.feet) - float(es.h) * float(D().enemies[e.type].get("scale", 1.0))
		hp.position = Vector2(es.x, top - 30.0 if str(ly.get("enemyHp", "feet")) == "above" else float(es.feet) + 6.0)
	layers.hud.add_child(hp)
	hp_enemy[e.id] = hp
	var it := IntentBox.new()
	it.giant = hp.giant
	it.visible = false
	layers.hud.add_child(it)
	intents[e.id] = it
	if not e.alive:
		node.visible = false
		hp.visible = false


func _make_foot() -> Node2D:
	var r := foot_rect()
	var node := Node2D.new()
	node.position = r.position
	var spr := _sprite(D().enemies.giant.sprite, Rect2(Vector2.ZERO, r.size))
	var gt = D().enemies.giant.get("tint")
	spr.modulate = Color(gt[0], gt[1], gt[2]) if gt is Array else Color.WHITE
	node.add_child(spr)
	layers.foot.add_child(node)
	return node


func _make_hud(st: Dictionary) -> void:
	var ly := LY()
	for id in st.party.order:
		var hp := AllyHp.new()
		hp.who = id
		layers.hud.add_child(hp)
		hp.position = ally_hp_pos(id) - Vector2(hp.size.x / 2.0, 0)
		# hpPlate(배경마다): HP 판만 옮긴다(머리 옆 등). 조준 화살표·피해 숫자 자리는 그대로
		var plate: Dictionary = ly.get("hpPlate", {})
		if plate.has(id):
			hp.position += Vector2(float(plate[id][0]), float(plate[id][1]))
		hp_ally[id] = hp
	witch_panel = WitchPanel.new()
	var r := witch_rect()
	witch_panel.position = r.position
	witch_panel.size = r.size
	layers.hud.add_child(witch_panel)
	energy_orb = EnergyOrb.new()
	var en: Dictionary = ly.energy
	energy_orb.position = Vector2(float(en.x) - float(en.r), float(en.y) - float(en.r))
	energy_orb.size = Vector2(en.r, en.r) * 2.0
	layers.hud.add_child(energy_orb)
	var t: Dictionary = ly.endTurn
	end_btn = UI.button(G.ui("endTurn"), 26, func(): G.ctl.end_turn())
	end_btn.style_kind = "small"
	end_btn.position = Vector2(t.x, t.y)
	end_btn.size = Vector2(t.w, t.h)
	end_btn.lbl.size = end_btn.size
	end_btn.pivot_offset = end_btn.size / 2.0
	layers.hud.add_child(end_btn)
	for k in ["drawPile", "discardPile"]:
		var pl := UI.label("", 18, Color("#c9b9bc"), "sans_bold", HORIZONTAL_ALIGNMENT_CENTER)
		var pp := UI.panel(UI.box(Color(0, 0, 0, 0.65), Color("#4a3a3e"), 10, 1))
		pp.add_child(pl)
		pp.position = Vector2(ly[k].x, ly[k].y)
		layers.hud.add_child(pp)
		piles[k] = pl


func sync_from_state(st: Dictionary) -> void:
	var b = st.battle
	if vm.is_empty() or b == null:
		return
	vm.hp.witch = st.party.witch.hp
	vm.maxHp.witch = st.party.witch.maxHp
	for id in st.party.order:
		var a: Dictionary = st.party.allies[id]
		vm.hp[id] = a.hp
		vm.maxHp[id] = a.maxHp
		vm.status[id] = a.status
	for e in b.enemies:
		vm.hp[e.id] = e.hp
		vm.maxHp[e.id] = e.maxHp
		vm.enemyAlive[e.id] = e.alive
		vm.intents[e.id] = e.intent.duplicate(true) if e.intent != null else null
	if vm.ghost == "":
		vm.hand = b.hand.duplicate()
	vm.energy = b.energy
	vm.turn = b.turn
	vm.drawCount = b.draw.size()
	vm.discardCount = b.discard.size()
	vm.tension = clampf(float(b.turn if b.turn > 0 else 1), 1.0, 3.0) if b.kind == "giant" else 0.0


# ───────── 그리기 ─────────
func render() -> void:
	var st: Dictionary = G.ctl.st
	if vm.is_empty() or st.is_empty() or st.battle == null:
		return
	for id in st.party.order:
		var hp: AllyHp = hp_ally.get(id)
		if hp == null:
			continue
		var status: String = vm.status.get(id, "ok")
		hp.visible = status != "dead"
		hp.set_vals(int(vm.hp.get(id, 0)), int(vm.maxHp.get(id, 1)), status)
		hp.valid = highlight_ally.has(id)
		hp.hot = hot_ally == id
		var al: Dictionary = allies[id]
		al.node.visible = status != "dead"
		al.body.modulate = Color(0.45, 0.45, 0.45) if status == "down" else Color.WHITE
	witch_panel.set_vals(int(vm.hp.witch), int(vm.maxHp.witch))
	witch_panel.valid = highlight_ally.has("witch")
	witch_panel.hot = hot_ally == "witch"
	for e in st.battle.enemies:
		var hp2: EnemyHp = hp_enemy.get(e.id)
		if hp2 == null:
			continue
		var alive: bool = vm.enemyAlive.get(e.id, false)
		hp2.visible = alive
		hp2.set_vals(vm.hp.get(e.id), vm.maxHp.get(e.id))
		render_intent(e.id, vm.intents.get(e.id) if alive else null)
	energy_orb.set_vals(int(vm.energy), int(D().rules.energyPerTurn))
	var player_turn: bool = st.battle.phase == "player" and st.battle.result == null
	end_btn.disabled = not player_turn or G.ctl.busy
	end_btn.pulse = player_turn and not G.ctl.busy and not _any_playable(st)
	end_btn.queue_redraw()
	piles.drawPile.text = "%s %d" % [G.ui("deck"), vm.drawCount]
	piles.discardPile.text = "%s %d" % [G.ui("discard"), vm.discardCount]
	for k in piles:
		var pl: Label = piles[k]
		var sz := pl.get_combined_minimum_size() + Vector2(20, 6)
		var pp: Control = pl.get_parent()
		pp.size = sz
		pl.size = sz
		pp.position = Vector2(LY()[k].x, LY()[k].y) - sz / 2.0
	hand.layout()
	hand.update_classes(st, G.ctl.busy)


func _any_playable(st: Dictionary) -> bool:
	for u in st.battle.hand:
		if Rules.can_play(st, u).ok:
			return true
	return false


func render_intent(id: String, it) -> void:
	var box: IntentBox = intents.get(id)
	if box == null:
		return
	if it == null:
		box.visible = false
		return
	box.visible = true
	var e = Rules.enemy(G.ctl.st, id)
	box.valid = highlight_enemy.has(id) and highlight_mode == "intent"
	box.hot = hot_enemy == id
	box.hovered = hover_intent == id
	if box.giant:
		box.set_giant(it)
		box.position = Vector2(float(LY().giant.cx) - box.size.x / 2.0, float(LY().giant.intentY))
	else:
		box.set_attack(it)
		var s: Dictionary = LY().enemySlots[int(e.slot)]
		var eb := enemy_box(id)
		var above := 30.0 + 56.0 if str(LY().get("enemyHp", "feet")) == "above" else 50.0   # HP 막대가 머리 위면 예고는 그 위
		box.position = Vector2(clampf(float(s.x) - box.size.x / 2.0, 8.0, 1912.0 - box.size.x), maxf(8.0, eb.position.y - above))


func highlight(enemy_ids, mode: String, ally_ids) -> void:
	highlight_enemy = enemy_ids if enemy_ids is Array else []
	highlight_mode = mode
	highlight_ally = ally_ids if ally_ids is Array else []
	render()


func hot(enemy_id: String, ally_id: String) -> void:
	hot_enemy = enemy_id
	hot_ally = ally_id
	render()


## 거대 존재의 그림자: 배경·적에는 그림자 레이어(발보다 아래), 동료에게는 각 그림 모양대로 덮는 검은 덮개
func set_shadow(v: float, ms := 1200.0) -> void:
	var from := shadow_v
	vm["shadow"] = v
	if ms <= 0:
		_apply_shadow(v)
		return
	FX.anim(ms, [{"v": from, "e": "ease"}, {"v": v}], func(x): _apply_shadow(x.v), {"key": "shadow"})


func _apply_shadow(v: float) -> void:
	shadow_v = v
	layers.shadow.modulate.a = v
	for m in shade_mats:
		m.set_shader_parameter("opacity", v)


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	# 숨쉬기 (캐릭터마다 위상 다르게) + 떨림
	var br: Dictionary = D().motion.breathe
	var order: Array = D().party.order
	for id in allies:
		var al: Dictionary = allies[id]
		var i := maxi(0, order.find(id))
		var ph := (_t * 1000.0 / float(br.period) + i * 0.37 + 0.11) * TAU
		al.pose.position.y = -float(br.amp) * (0.5 - 0.5 * cos(ph)) if not FX.reduced and not (anim and anim.has_ally(id)) else 0.0
		if trembling.has(id):
			al.pose.position += Vector2(randf_range(-2, 2), randf_range(-1, 1))
		else:
			al.pose.position.x = 0
	if anim:
		anim.tick()
	layers.threads.queue_redraw()
	# 확대·선택 강조(맥박)
	for id in intents:
		intents[id].queue_redraw()


# ───────── 붉은 실 ─────────
func death_card_in_hand() -> Dictionary:
	var all := death_cards_in_hand()
	for a in all:
		return {"uid": all[a], "ally": a}
	return {}


## 손패(와 들어 올린 카드)의 죽음 카드 전부: 동료 id → uid (브룬힐드가 살아 있으면 둘)
func death_cards_in_hand() -> Dictionary:
	var st: Dictionary = G.ctl.st
	var out := {}
	if vm.is_empty() or st.is_empty():
		return out
	var list: Array = vm.hand.duplicate()
	if vm.ghost != "":
		list.append(vm.ghost)
	for u in list:
		if st.cards.has(u) and not Rules.is_face_down(st, u):
			var d: Dictionary = D().cards[st.cards[u].id]
			if d.kind == "death":
				out[str(d.ally)] = u
	return out


func draw_threads(ci: CanvasItem) -> void:
	var st: Dictionary = G.ctl.st
	if vm.is_empty() or st.is_empty() or st.battle == null or not G.ctl.in_battle:
		return
	var order: Array = st.party.order
	var list: Array = vm.hand.duplicate()
	if vm.ghost != "":
		list.insert(mini(list.size(), int(vm.ghostIndex)), vm.ghost)
	var tops := []
	for u in list:
		var tp = hand.top_point(u)
		if tp != null:
			tops.append(tp)
	var dcs := death_cards_in_hand()
	var tension: float = vm.tension
	var t := _t
	for idx in order.size():
		var id: String = order[idx]
		if vm.status.get(id, "ok") == "dead":
			continue
		var a := ally_anchor(id)
		var taut: bool = dcs.has(id)
		if taut and hand.raised.get("uid", "") == dcs[id]:
			continue   # 들어 올린 죽음 카드의 실은 카드 위 레이어에 그린다(draw_raised_thread)
		var b = null
		if taut:
			b = hand.top_point(dcs[id])
		if b == null:
			if not tops.is_empty():
				b = tops[int(round((tops.size() - 1) * idx / maxf(1.0, order.size() - 1.0)))]
			else:
				b = Vector2(960, 760)
		var m: Vector2 = (a + b) / 2.0
		if taut:
			draw_taut(ci, a, b, maxf(tension, 2.6 if fate_hold == id else 0.0), idx, t)
		else:
			var sag := 70.0 - tension * 6.0
			var sway := sin(t * 0.9 + idx * 1.7) * 10.0
			var dim := 0.14 if vm.status.get(id) == "down" else 0.4 + tension * 0.06
			UI.glow_curve(ci, a, m + Vector2(sway, sag), b, 1.5 + tension * 0.2, Color(0.9, 0.12, 0.19, dim), 3.0 if FX.low else 7.0)
	if vm.broken != null:
		var sw0 := sin(t * 1.6) * 8.0
		var hb := ally_anchor(str(vm.broken.get("ally", "hero")))
		UI.glow_curve(ci, hb + Vector2(0, -16), hb + Vector2(12 + sw0 * 0.4, 30), hb + Vector2(18 + sw0, 74), 1.6, Color(0.63, 0.05, 0.1, 0.6), 4.0)


## 죽음 카드에 걸린 팽팽한 실. pull: 1 = 카드를 낸 순간, 2 = 들어 올린 손에서 최대로 팽팽 (곧게 펴지고 굵게 떨린다)
func draw_taut(ci: CanvasItem, a: Vector2, b: Vector2, tension: float, idx: int, t: float) -> void:
	var pull: float = vm.get("pull", 0.0)
	var m := (a + b) / 2.0
	var k := 1.0 + tension * 0.55 + pull * (2.4 if pull > 1 else 3.0)
	var vib := (tension * 0.9 + pull * (3.2 if pull > 1 else 4.0)) * sin(t * 60.0 + idx)
	var c := Vector2(m.x + vib, m.y + (0.0 if pull > 1 else maxf(0.0, 14.0 - tension * 5.0)) + vib * 0.5)
	var g := maxf(10.0, 50.0 - tension * 12.0 - pull * 10.0) / 255.0
	UI.glow_curve(ci, a, c, b, 1.8 + k * 0.9, Color(1, g, 0.235, minf(1.0, 0.72 + tension * 0.09 + pull * 0.1)), (10.0 + k * 5.0) * (0.5 if FX.low else 1.0))
	ci.draw_circle(b, 3.0 + tension, Color(1, 0.24, 0.31, 0.95))
	ci.draw_circle(a, 2.5 + tension * 0.6, Color(1, 0.24, 0.31, 0.95))


## 들어 올린 죽음 카드 ↔ 그 동료의 등: 들어 올린 손(손패보다 위)에 걸리므로 효과 레이어에 그린다
func draw_raised_thread(ci: CanvasItem) -> void:
	var st: Dictionary = G.ctl.st
	if vm.is_empty() or st.is_empty() or st.battle == null or not G.ctl.in_battle or hand.raised.is_empty():
		return
	var dcs := death_cards_in_hand()
	for a in dcs:
		if hand.raised.uid == dcs[a] and vm.status.get(a) != "dead":
			draw_taut(ci, ally_anchor(a), hand.raise_top_point(), vm.tension, st.party.order.find(a), _t)


## 카드에 걸린 채 끊어져 늘어진 실 (카드 위에 그린다)
func draw_broken(ci: CanvasItem) -> void:
	if vm.is_empty() or vm.broken == null or not G.ctl.in_battle:
		return
	var p = hand.top_point(vm.broken.uid) if vm.broken.get("uid", "") != "" else null
	if p == null:
		p = vm.broken.at
	if p == null:
		return
	vm.broken.at = p
	var sw := sin(_t * 1.6) * 8.0
	var c1: Vector2 = p + Vector2(-30 + sw * 0.3, -54)
	var e1: Vector2 = p + Vector2(-46 + sw, 130)
	UI.glow_curve(ci, p, c1, e1, 2.4, Color(0.73, 0.06, 0.13, 0.92), 8.0)
	ci.draw_line(e1, e1 + Vector2(-6 + sw * 0.2, 11), Color(0.73, 0.06, 0.13, 0.85), 1.2, true)
	ci.draw_line(e1, e1 + Vector2(5, 12), Color(0.73, 0.06, 0.13, 0.85), 1.2, true)
	ci.draw_circle(p, 3.0, Color(0.86, 0.16, 0.24, 0.95))


## 대상 강조(맥박 테두리)·선택 강조 — 효과 레이어에 그린다
func draw_highlights(ci: CanvasItem) -> void:
	if vm.is_empty() or not visible:
		return
	var pulse := 0.55 + 0.45 * (0.5 + 0.5 * sin(_t * TAU))
	if highlight_mode == "enemy":
		for id in highlight_enemy:
			if not vm.enemyAlive.get(id, false):
				continue
			var r := enemy_box(id).grow(6)
			var hotc: bool = hot_enemy == id
			var col := Color(1, 0.83, 0.42) if hotc else Color(1, 0.27, 0.31, 0.9 * pulse)
			ci.draw_style_box(UI.box(Color(0, 0, 0, 0), Color(col.r, col.g, col.b, col.a * 0.35), 16, 10), r.grow(4))
			ci.draw_style_box(UI.box(Color(0, 0, 0, 0), col, 12, 3), r)
	for id in highlight_ally:
		if id == "witch" or not allies.has(id):
			continue
		var b := ally_box(id)
		var r2 := Rect2(b.position.x + b.size.x * 0.1, b.position.y, b.size.x * 0.8, b.size.y * 0.45)
		var hc: bool = hot_ally == id
		var col2 := Color(1, 0.83, 0.42) if hc else Color(1, 0.27, 0.31, 0.9 * pulse)
		ci.draw_style_box(UI.box(Color(0, 0, 0, 0), Color(col2.r, col2.g, col2.b, col2.a * 0.35), 16, 10), r2.grow(4))
		ci.draw_style_box(UI.box(Color(0, 0, 0, 0), col2, 12, 3), r2)


# ───────── 이벤트 연출 ─────────
func play_events(events: Array) -> void:
	for e in events:
		if G.params.has("trace"):
			G.ctl.note("ev " + str(e.t))
		var h := "_on_" + str(e.t)
		if has_method(h):
			await call(h, e)
		render()
	sync_from_state(G.ctl.st)
	render()


func _hp_float(who: Dictionary, amount, cls: String) -> Vector2:
	var p: Vector2
	if who.has("enemy"):
		p = enemy_center(who.enemy)
	elif who.ally == "witch":
		var r := witch_rect()
		p = Vector2(r.get_center().x, r.position.y - 20)
	else:
		p = ally_hp_pos(who.ally) + Vector2(0, 90)
	FX.float_text(p.x, p.y, amount, cls)
	return p


func flash_node(n: CanvasItem) -> void:
	if n == null:
		return
	FX.anim(350, [{"c": Color(2.4, 1.1, 0.9)}, {"c": Color.WHITE}], func(v): if is_instance_valid(n): n.self_modulate = v.c, {"node": n, "key": "hit_%d" % n.get_instance_id()})


func owner_color(id: String) -> Array:
	var d: Dictionary = D().cards.get(id, {})
	if d.is_empty():
		return ["#ffffff"]
	if d.kind == "inherit" or d.kind == "death":
		return ["#ff2a3c", "#7a0010"]
	if d.kind == "relic":
		return ["#dddddd", "#888888"]
	return {"witch": ["#c86bff", "#ff4a6a"], "hero": ["#ffffff", "#bfe6ff"], "warrior": ["#ffd36b", "#c9a24a"], "archer": ["#b6ff9a", "#ffffff"]}.get(d.owner, ["#ffffff"])


## 카드 사용 모션: 카드가 (세워 든 손에서) 대상 쪽으로 날아가며 사라진다
func fly_card(c: CardView, to: Vector2) -> void:
	if c == null:
		return
	c.smooth = false
	c.glow = 0
	var q0 := c.corners.duplicate()
	var cw := CardView.W
	var chh := CardView.H
	var mid_pos := Vector2(to.x - cw * 0.45, to.y - chh * 0.45 - 60)
	var end_pos := Vector2(to.x - cw * 0.2, to.y - chh * 0.2)
	var q_mid := CardView.rect_corners(mid_pos, 0.9)
	var q_end := CardView.rect_corners(end_pos, 0.4)
	var a := FX.anim(float(D().timing.cardFly), [{"k": 0.0, "a": 1.0, "b": 1.0}, {"o": 0.55, "k": 1.0, "a": 1.0, "b": 1.6}, {"k": 2.0, "a": 0.0, "b": 3.0}], func(v):
		if not is_instance_valid(c):
			return
		var q := PackedVector2Array()
		for i in 4:
			q.append(q0[i].lerp(q_mid[i], v.k) if v.k <= 1.0 else q_mid[i].lerp(q_end[i], v.k - 1.0))
		c.set_quad(q, true)
		c.alpha = v.a
		c.bright = v.b, {"node": c, "easing": "ease-in"})
	await FX.until(a)
	if is_instance_valid(c):
		c.queue_free()


func _on_turnStart(e: Dictionary) -> void:
	vm.turn = e.turn
	vm.energy = e.energy
	if vm.kind == "giant":
		vm.tension = minf(3.0, float(e.turn))
		var total: int = D().encounters.giant.countdown.size()
		var left := maxi(1, total - int(e.turn) + 1)
		await FX.banner(G.ui("giantTurn", {"n": e.turn, "left": left}), 1000)
	else:
		await FX.banner(G.ui("turn", {"n": e.turn}), 700)


func _on_energy(e: Dictionary) -> void:
	vm.energy = e.energy


func _on_draw(e: Dictionary) -> void:
	vm.hand = e.hand
	vm.drawCount = e.drawLeft
	if not hand.cards.has(e.uid):
		hand.create(G.ctl.st, e.uid, Vector2(LY().drawPile.x, LY().drawPile.y))
	render()
	await FX.wait(float(D().timing.drawGap))


func _on_reshuffle(_e: Dictionary) -> void:
	FX.toast(G.ui("reshuffle"))
	await FX.wait(300)


func _on_handFull(_e: Dictionary) -> void:
	FX.toast(G.ui("handFull"))


func _on_addCard(e: Dictionary) -> void:
	var st: Dictionary = G.ctl.st
	var d := Rules.def(st, e.uid)
	if e.reason == "effect" and vm.ghost != "":
		# 죽음 카드가 있던 자리에 짓밟힘이 남는다
		var g: CardView = hand.cards.get(vm.ghost)
		if g:
			g.queue_free()
			hand.cards.erase(vm.ghost)
		vm.broken = {"uid": e.uid, "at": null}
		vm.ghost = ""
		vm.hand = e.hand
		var c2 := hand.create(st, e.uid, Vector2(960, 760))
		render()
		var cc := c2.center()
		_appear(c2)
		FX.burst(cc.x, cc.y, {"count": 40, "colors": ["#ff2a3c", "#7a0010", "#ff8a90"], "speed": 260, "life": 900, "size": 3, "gravity": -60})
		await FX.wait(1000)
		return
	vm.hand = e.hand
	if not hand.cards.has(e.uid):
		var c := hand.create(st, e.uid, Vector2(960, 700))
		if d.kind == "death":
			_appear(c)
			FX.flash("#5a0010", 500, 0.45)
			FX.shake(4, 300)
			render()
			await FX.wait(900)
			return
	render()
	await FX.wait(250)


func _appear(c: CardView) -> void:
	FX.anim(900, [{"o": 0.0, "b": 3.0, "a": 0.0}, {"o": 0.4, "b": 2.0, "a": 1.0}, {"o": 1.0, "b": 1.0, "a": 1.0}], func(v):
		if is_instance_valid(c):
			c.bright = v.b
			c.alpha = v.a, {"node": c, "easing": "ease-out"})


## 뒤집힌 카드가 저절로 뒤집힌다 (거대한 발 3턴 「짓밟기」 순간 — 대본 v3 5.2): 옆으로 섰다가 앞면(세라피나의 얼굴)으로
func _on_flip(e: Dictionary) -> void:
	var c: CardView = hand.cards.get(e.uid)
	if c == null:
		return
	G.ctl.note("flip " + str(e.id))
	var p := c.center()
	FX.flash("#5a0010", 420, 0.5)
	var a := FX.anim(320, [{"k": 1.0}, {"k": 0.0}], func(v):
		if is_instance_valid(c):
			c.flip_k = v.k
			c.queue_redraw(), {"node": c, "easing": "ease-in", "key": "flip"})
	await FX.until(a)
	if not is_instance_valid(c):
		return
	c.refresh(G.ctl.st)
	c.redraw_face()
	FX.burst(p.x, p.y - 40, {"count": 30, "colors": ["#ff2a3c", "#ff8a90", "#7a0010"], "speed": 300, "life": 900, "size": 3, "gravity": 0, "shape": "line"})
	var b := FX.anim(380, [{"k": 0.0, "b": 2.6}, {"k": 1.0, "b": 1.0}], func(v):
		if is_instance_valid(c):
			c.flip_k = v.k
			c.bright = v.b
			c.queue_redraw(), {"node": c, "easing": "ease-out", "key": "flip"})
	await FX.until(b)
	c.flip_k = 1.0
	c.taut = 1.0
	vm.pull = 0.6
	render()
	await FX.wait(500)


func _on_intents(e: Dictionary) -> void:
	for x in e.intents:
		vm.intents[x.enemy] = x.intent
	render()
	await FX.wait(60)


func _on_play(e: Dictionary) -> void:
	var st: Dictionary = G.ctl.st
	var d: Dictionary = D().cards[e.id]
	var T: Dictionary = D().timing
	vm.energy = e.energy
	vm.discardCount = st.battle.discard.size()
	hand.hover_uid = ""
	hand.lifted_uid = ""
	hand.drag_uid = ""
	hand.drag_mode = ""
	if d.kind == "death":
		# 죽음 카드: 오른손이 손패에서 빠지고, 세운 손이 천천히 들어 올린 채 떨리며 세라피나의 등까지 이어진 붉은 실이 최대로 팽팽해진 뒤 컷신으로
		vm.ghost = e.uid
		vm.ghostIndex = e.handIndex
		vm.hand = e.hand
		var g: CardView = hand.cards.get(e.uid)
		if g:
			g.taut = 1.0
		vm.pull = 1.0
		render()
		if allies.has(str(d.ally)):
			trembling[str(d.ally)] = true
		await hand.raise_card(e.uid, g, true)
		vm.pull = 2.0
		hand.set_tremble(float(T.deathTremble))
		FX.shake(3, float(T.deathHold))
		await FX.wait(float(T.deathHold))
		return
	var to: Vector2
	if e.target.has("enemy"):
		if d.target == "intent":
			var r = intent_rect(e.target.enemy)
			to = r.get_center() if r != null else enemy_center(e.target.enemy)
		else:
			to = enemy_center(e.target.enemy)
	else:
		to = Vector2(960, 430)
	# 카드 내기: 오른손만 손패에서 빠지고, 세운 오른손이 그 카드를 든다 → (대표 카드면 컷인) → 카드가 날아간다 → 손이 돌아온다
	vm.hand = e.hand
	var cel := hand.detach(e.uid)
	render()
	await hand.raise_card(e.uid, cel)
	await FX.wait(float(T.raiseHold))
	if G.cutin.has(e.id):
		await G.cutin.play(e.id)
	var mv = D().motion.cards.get(e.id)
	var strike := {}
	if mv != null and st.party.allies.has(mv[0]):
		strike = ally_strike(mv[0], mv[1], to)
	var fly := hand.release_raised()
	hand.raise_down()
	await fly_card(fly, to)
	if not strike.is_empty() and not strike.hit.finished:
		await strike.hit.done
	FX.burst(to.x, to.y, {"count": 26, "colors": owner_color(e.id), "speed": 320, "life": 600, "size": 3, "gravity": 0})
	match str(d.art):
		"sword", "brokensword":
			FX.slash(to.x, to.y, {"len": 260, "width": 12, "color": "#dddddd" if d.kind == "relic" else "#eaf6ff", "ang": -0.9})
			FX.shake(8, 260)
		"arrow", "arrows":
			var a := ally_anchor("archer")
			await FX.streak(a.x, a.y - 120, to.x, to.y, {"color": "#f4f0d0", "width": 4, "dur": 180})
		"flame":
			FX.burst(to.x, to.y, {"count": 50, "colors": ["#ff3a1e", "#ff9a2a", "#ffe08a"], "speed": 260, "life": 800, "size": 5, "gravity": -200})
		"bash":
			FX.burst(to.x, to.y, {"count": 20, "colors": ["#ffd36b"], "speed": 500, "life": 400, "size": 3, "gravity": 0, "shape": "line"})
			FX.shake(10, 280)
	if d.kind == "relic":
		FX.flash("#300000", 300, 0.25)
	await FX.wait(120)
	if hand.busy_hands:
		await hand.hands_back


func _on_aoe(e: Dictionary) -> void:
	if e.src == "trample":
		await trample_strike()
		return
	var st: Dictionary = G.ctl.st
	var i := 0
	for en in Rules.alive_enemies(st):
		var c := enemy_center(en.id)
		get_tree().create_timer(FX.ms(i * 90) / 1000.0, false).timeout.connect(func(): FX.slash(c.x, c.y, {"len": 220, "width": 10, "color": "#ffffff", "ang": -0.6, "count": 2}))
		i += 1
	FX.shake(10, 360)
	await FX.wait(260)


func _on_damage(e: Dictionary) -> void:
	var w: Dictionary = e.who
	if w.has("enemy"):
		if e.get("immune", false):
			var c := enemy_center(w.enemy)
			FX.float_text(c.x, c.y + 120, G.ui("immune"), "immune")
			FX.burst(c.x, c.y + 160, {"count": 14, "colors": ["#999999", "#666666"], "speed": 200, "life": 500, "size": 3})
			G.guide.fire("immune", {"card": e.src, "enc": vm.enc})
			await FX.wait(380)
			return
		vm.hp[w.enemy] = e.hp
		_hp_float(w, e.amount, "enemy")
		if enemies.has(w.enemy):
			flash_node(enemies[w.enemy].node)
			if anim:
				anim.hit_enemy(w.enemy)
		if int(e.amount) >= 12:
			FX.shake(9, 300)
		render()
		await FX.wait(260)
		return
	vm.hp[w.ally] = e.hp
	_hp_float(w, "-" + str(e.amount), "ally" + (" small" if e.cause == "relic" else ""))
	if w.ally == "witch":
		flash_node(witch_panel)
	else:
		if allies.has(w.ally):
			flash_node(allies[w.ally].body)
		if e.cause != "stomp":
			ally_hurt(w.ally)
	if e.cause == "attack":
		FX.shake(6 + float(e.amount) * 0.6, 280)
	render()
	await FX.wait(120 if e.cause in ["aoe", "stomp"] else 300)


func _on_enemyDie(e: Dictionary) -> void:
	vm.enemyAlive[e.enemy] = false
	var en: Dictionary = enemies.get(e.enemy, {})
	if not en.is_empty():
		var c := enemy_center(e.enemy)
		FX.burst(c.x, c.y + 60, {"count": 30, "colors": ["#555555", "#333333", "#7a0010"], "speed": 220, "life": 900, "size": 4})
		var n: Node2D = en.node
		var by := n.position.y
		var a := FX.anim(420, [{"y": 0.0, "sx": 1.0, "sy": 1.0, "a": 1.0}, {"y": 30.0, "sx": 0.9, "sy": 0.6, "a": 0.0}], func(v):
			if is_instance_valid(n):
				n.position.y = by + v.y
				n.scale = Vector2(v.sx, v.sy)
				n.modulate.a = v.a, {"node": n, "easing": "ease-in"})
		await FX.until(a)
		n.visible = false
	render()


func _on_allyDown(e: Dictionary) -> void:
	vm.status[e.ally] = "down"
	render()
	FX.toast(G.ui("allyDown", {"name": G.name_of(e.ally)}), 1200)
	G.guide.fire("allyDown", {"enc": vm.enc})
	await FX.wait(500)


func _on_enemyPhase(_e: Dictionary) -> void:
	await FX.banner(G.ui("enemyPhase"), 600)


func _on_discardHand(e: Dictionary) -> void:
	var p := Vector2(LY().discardPile.x, LY().discardPile.y)
	var waits := []
	for uid in hand.cards.keys():
		if e.hand.has(uid):
			continue
		var c := hand.detach(uid)
		if c == null:
			continue
		c.smooth = false
		var q0 := c.corners.duplicate()
		var q1 := CardView.rect_corners(p - Vector2(CardView.W, CardView.H) * 0.1, 0.2)
		waits.append(FX.anim(360, [{"k": 0.0}, {"k": 1.0}], func(v):
			if is_instance_valid(c):
				var q := PackedVector2Array()
				for i in 4:
					q.append(q0[i].lerp(q1[i], v.k))
				c.set_quad(q, true)
				c.alpha = 1.0 - v.k, {"node": c, "easing": "ease-in"}))
		waits[-1].finished.connect(func(): if is_instance_valid(c): c.queue_free())
	vm.hand = e.hand
	vm.discardCount = G.ctl.st.battle.discard.size()
	render()
	await FX.all(waits)


func _on_enemyAct(e: Dictionary) -> void:
	if e.kind == "attack":
		# 몸을 젖혔다가 달려든다 → 맞는 순간 베기 자국 (맞은 동료의 흔들림은 이어지는 damage 에서)
		var tp := target_point(e.target)
		var ln := enemy_lunge(e.enemy, tp)
		await FX.wait(ln)
		FX.slash(tp.x, tp.y, {"len": 150, "width": 7, "color": "#ff4050", "ang": -0.8, "count": 3})
		await FX.wait(maxf(60.0, float(D().timing.enemyAttack) - 440.0))
	elif e.kind == "shadow":
		await giant_shadow()
	elif e.kind == "aoe" and vm.kind != "giant":
		await fire_wave(e.enemy)
	elif e.kind == "aoe":
		await pillar_collapse()
	elif e.kind == "blocked":
		var bc := enemy_center(e.enemy)
		enemy_lunge(e.enemy)
		await FX.wait(260)
		FX.float_text(bc.x, bc.y + 80, G.ui("blocked"), "immune")
		FX.burst(bc.x, bc.y + 120, {"count": 18, "colors": ["#c9c9c9", "#ff6b76"], "speed": 260, "life": 500, "size": 3})
		await FX.wait(300)
	elif e.kind == "fate":
		# 운명 공격: 집행자가 몸을 젖히고(쓰러지는 중이면 그 자리에서) 불길·창이 그 동료를 향한다 → 닿는 순간 멈춘다(fateTrial)
		var tp := target_point(e.target)
		var ec := enemy_center(e.enemy)
		var pierce := _fate_method(e) == "pierce"
		if e.get("dying", false):
			FX.flash("#ff2a3c", 220, 0.3)
			await FX.wait(260)
		else:
			enemy_lunge(e.enemy)
			await FX.wait(200)
		if pierce:
			FX.shake(10, 320)
			await FX.streak(ec.x, ec.y, tp.x, tp.y - 40, {"color": "#e4e2ea", "width": 8, "dur": 260})
			FX.burst(tp.x, tp.y - 40, {"count": 34, "colors": ["#d8d8e0", "#ff2a3c", "#7a0010"], "speed": 280, "life": 600, "size": 4, "gravity": 200, "shape": "line"})
		else:
			await FX.streak(ec.x, ec.y, tp.x, tp.y - 40, {"color": "#ff7a2a", "width": 10, "dur": 420})
			FX.burst(tp.x, tp.y - 40, {"count": 40, "colors": ["#ff3a1e", "#ff9a2a", "#ffe08a"], "speed": 200, "life": 700, "size": 5, "gravity": -160})
	elif e.kind == "stomp" and e.has("fate"):
		await giant_stomp_halt()
	elif e.kind == "stomp":
		await giant_stomp()


func _on_redirect(e: Dictionary) -> void:
	var r = intent_rect(e.enemy)
	var from: Vector2 = Vector2(r.get_center().x, r.end.y) if r != null else enemy_center(e.enemy)
	var to := target_point(e.to)
	await FX.streak(from.x, from.y, to.x, to.y, {"color": "#ff2a3c", "width": 5, "dur": 300})
	FX.burst(to.x, to.y, {"count": 16, "colors": ["#ff2a3c", "#ff8a90"], "speed": 160, "life": 500, "size": 3, "gravity": 0})
	G.guide.fire("redirect", {"enc": vm.enc, "card": e.card})


## 「이름 없는 마녀의 카드」: 예고가 지워진다
func _on_cancelIntent(e: Dictionary) -> void:
	var r = intent_rect(str(e.enemy))
	var c: Vector2 = r.get_center() if r != null else enemy_center(str(e.enemy))
	FX.burst(c.x, c.y, {"count": 30, "colors": ["#2a2a2a", "#555555", "#ff6b76"], "speed": 220, "life": 700, "size": 3, "gravity": -60, "shape": "flake"})
	FX.float_text(c.x, c.y - 20, G.ui("canceled"), "immune")
	await FX.wait(300)


## 「작은 손의 부적」: 동료 회복
func _on_heal(e: Dictionary) -> void:
	var w: Dictionary = e.who
	vm.hp[w.ally] = e.hp
	var p := ally_hp_pos(str(w.ally)) + Vector2(0, 90)
	FX.float_text(p.x, p.y, "+" + str(e.amount), "small")
	FX.burst(p.x, p.y + 30, {"count": 24, "colors": ["#b6ff9a", "#ffffff"], "speed": 160, "life": 700, "size": 3, "gravity": -120})
	render()
	await FX.wait(300)


func _on_weaken(e: Dictionary) -> void:
	var r = intent_rect(e.enemy)
	if r != null:
		FX.float_text(r.get_center().x, r.position.y - 10, "-" + str(e.amount), "small")
	await FX.wait(200)


## 화형 사제의 「불길」(모두에게): 아군 쪽에 불길이 번진다
func fire_wave(enemy_id: String) -> void:
	enemy_lunge(enemy_id)
	await FX.wait(220)
	FX.flash("#ff5a1e", 260, 0.35)
	FX.shake(12, 500)
	for id in allies:
		if vm.status.get(id) == "ok":
			var p := target_point(id)
			FX.burst(p.x, p.y + 40, {"count": 36, "colors": ["#ff3a1e", "#ff9a2a", "#ffe08a"], "speed": 240, "life": 800, "size": 5, "gravity": -260})
	FX.burst(960, 1000, {"count": 40, "colors": ["#ff3a1e", "#ff9a2a"], "speed": 300, "life": 700, "size": 5, "gravity": -300})
	await FX.wait(380)


## 운명의 시도: 시간이 멈춘다(붉게), 그 동료의 실이 최대로 팽팽 / 풀기
func fate_freeze(who: String, on: bool) -> void:
	if fate_tint == null:
		return
	fate_hold = who if on else ""
	if on:
		trembling[who] = true
		FX.shake(5, 300)
	else:
		trembling.erase(who)
	var a := FX.anim(500 if on else 350, [{"a": fate_tint.color.a}, {"a": 0.42 if on else 0.0}], func(v): if is_instance_valid(fate_tint): fate_tint.color.a = v.a, {"node": fate_tint})
	await FX.until(a)


func _on_fateTrial(_e: Dictionary) -> void:
	await FX.wait(150)


## 운명의 방식 (pierce | burn): 이벤트의 fate id 로
func _fate_method(e: Dictionary) -> String:
	var fd = D().fates.get(str(e.get("fate", "")))
	return str(fd.method) if fd != null else "burn"


## 거스름(전투): 불길(창)이 그 동료 주위에서 갈라진다(부서진다)
func _on_fateDefied(e: Dictionary) -> void:
	var p := target_point(str(e.who))
	FX.flash("#ff2a3c", 200, 0.4)
	FX.shake(10, 360)
	var cols: Array = ["#d8d8e0", "#8a8a96", "#ff2a3c"] if _fate_method(e) == "pierce" else ["#ff3a1e", "#ff9a2a", "#ffe08a"]
	for s in [-1, 1]:
		FX.burst(p.x + s * 60, p.y - 20, {"count": 30, "colors": cols, "speed": 340, "angle": PI / 2 - s * 1.2, "spread": 0.8, "life": 700, "size": 5, "gravity": -100})
	if allies.has(str(e.who)):
		flash_node(allies[str(e.who)].body)
	FX.float_text(p.x, p.y + 60, G.ui("defied"), "immune")
	await FX.wait(500)


## 「꿰뚫린 방패」: 막고 되돌린다
func _on_reflect(e: Dictionary) -> void:
	var r = intent_rect(str(e.enemy))
	var c: Vector2 = r.get_center() if r != null else enemy_center(str(e.enemy))
	var ec := enemy_center(str(e.enemy))
	FX.burst(c.x, c.y, {"count": 24, "colors": ["#ffd36b", "#ff6b76"], "speed": 300, "life": 500, "size": 3, "gravity": 0, "shape": "line"})
	await FX.streak(960, 760, ec.x, ec.y, {"color": "#ffcf6a", "width": 6, "dur": 220})
	FX.shake(8, 240)


## 흉터: 손에 든 채 턴이 끝나 노엘 HP 가 준다
func _on_scarBurn(e: Dictionary) -> void:
	var c: CardView = hand.cards.get(e.uid)
	if c:
		var p := c.center()
		FX.burst(p.x, p.y, {"count": 18, "colors": ["#7a0010", "#ff3a4a"], "speed": 140, "life": 600, "size": 3, "gravity": -80})
		FX.anim(500, [{"b": 2.2}, {"b": 1.0}], func(v): if is_instance_valid(c): c.bright = v.b, {"node": c})
	await FX.wait(250)


func _on_giantTrigger(e: Dictionary) -> void:
	await giant_appear(e.victims)


func _on_retreat(_e: Dictionary) -> void:
	await giant_retreat()


func _on_allyDeath(e: Dictionary) -> void:
	if e.cause == "deathCard":
		await death_sequence(e)


func _on_relicize(e: Dictionary) -> void:
	var st: Dictionary = G.ctl.st
	for ch in e.changes:
		if hand.cards.has(ch.uid):
			var c: CardView = hand.cards[ch.uid]
			c.build(st)
			FX.anim(1000, [{"b": 2.5}, {"b": 1.0}], func(v): if is_instance_valid(c): c.bright = v.b, {"node": c, "easing": "ease-out"})
	render()
	if not e.changes.is_empty():
		FX.toast(G.ui("relic", {"name": G.name_of(e.ally), "n": e.changes.size()}), 1800)
	await FX.wait(600)


func _on_wound(e: Dictionary) -> void:
	FX.toast(G.ui("wound", {"name": G.name_of(e.ally)}), 1800)
	await FX.wait(900)


func _on_revive(e: Dictionary) -> void:
	vm.hp[e.ally] = e.hp
	vm.status[e.ally] = "ok"


func _on_energyOut(_e: Dictionary) -> void:
	G.guide.fire("energyOut", {"enc": vm.enc})


# ───────── 동료·적 움직임 (motion.js) ─────────
## 동료 카드 연출: 준비(움츠림) → 기본·행동 자세 녹임 → 타격(대상 쪽으로 튀어나감, 순간 멈춤, 잔상) → 복귀
## 반환: {"hit": 타격 순간에 끝나는 Anim, "done": 다 끝나는 Anim}
func ally_strike(id: String, pose: String, to: Vector2) -> Dictionary:
	if not allies.has(id) or vm.status.get(id) != "ok":
		return {}
	var m: Dictionary = D().motion
	motion_log.append(id + ":" + pose)
	if anim and anim.has_ally(id):
		return anim.strike(id, to)
	var al: Dictionary = allies[id]
	var node: Node2D = al.node
	var act: Node2D = al.acts.get(pose)
	var L: Dictionary = m.lunge.get(id, {"toward": 0.1, "max": 60, "dy": -40, "scale": 1.05})
	var red := 0.3 if FX.reduced else 1.0
	var a := ally_anchor(id)
	var dx := clampf((to.x - a.x) * float(L.toward), -float(L.max), float(L.max)) * red
	var dyv := float(L.dy) * red
	var sc := 1.0 + (float(L.scale) - 1.0) * red
	var cr := float(m.crouch) * red
	var w: float = m.windup
	var bl: float = m.blend
	var s: float = m.strike
	var hs: float = m.hitstop
	var rc: float = m.recover
	var T := w + bl + s + hs + rc
	var base: Vector2 = al.base
	var main := FX.anim(T, [
		{"o": 0.0, "p": Vector2.ZERO, "s": 1.0, "e": "cubic-bezier(.3,0,.4,1)"},
		{"o": w / T, "p": Vector2(0, cr), "s": 0.985, "e": "linear"},
		{"o": (w + bl) / T, "p": Vector2(-dx * 0.05, cr * 1.2), "s": 0.98, "e": "cubic-bezier(.55,0,.9,.45)"},
		{"o": (w + bl + s) / T, "p": Vector2(dx, dyv), "s": sc, "e": "linear"},
		{"o": (w + bl + s + hs) / T, "p": Vector2(dx, dyv), "s": sc, "e": "cubic-bezier(.2,.7,.3,1)"},
		{"o": (w + bl + s + hs + rc * 0.6) / T, "p": Vector2(-dx * 0.06, cr * 0.5), "s": 0.995, "e": "ease-in-out"},
		{"o": 1.0, "p": Vector2.ZERO, "s": 1.0}], func(v):
			if is_instance_valid(node):
				node.position = base + v.p
				node.scale = Vector2(v.s, v.s), {"node": node, "key": "strike_" + id})
	if act:
		var body: Node2D = al.body
		var k1 := w / T
		var k2 := (w + bl) / T
		var k3 := (w + bl + s + hs + rc * 0.35) / T
		FX.anim(T, [{"o": 0.0, "a": 0.0}, {"o": k1, "a": 0.0}, {"o": k2, "a": 1.0}, {"o": k3, "a": 1.0}, {"o": 1.0, "a": 0.0}], func(v):
			if is_instance_valid(act):
				act.modulate.a = v.a
				body.modulate.a = 1.0 - v.a, {"node": act})
		get_tree().create_timer(FX.ms(w + bl) / 1000.0, false).timeout.connect(func(): _afterimage(id, act, 0.0))
		get_tree().create_timer(FX.ms(w + bl + s * 0.5) / 1000.0, false).timeout.connect(func(): _afterimage(id, act, 0.5))
	var hit := FX.anim(w + bl + s, [{"x": 0.0}, {"x": 1.0}], Callable())
	hit.finished.connect(func(): if not FX.reduced: FX.shake(5, 160))
	return {"hit": hit, "done": main}


func _afterimage(id: String, act: Node2D, k: float) -> void:
	if not is_instance_valid(act) or not allies.has(id):
		return
	var ghost := Node2D.new()
	for c in act.get_children():
		if c is Sprite2D and c.material == null:
			var s := Sprite2D.new()
			s.texture = c.texture
			s.centered = false
			s.position = c.position
			s.scale = c.scale
			ghost.add_child(s)
	var node: Node2D = allies[id].node
	ghost.position = node.position + allies[id].pose.position
	ghost.scale = node.scale
	ghost.modulate = Color(1.8, 1.8, 1.8, 0.45 - k * 0.2)
	ghost.z_index = -1
	layers.allies.add_child(ghost)
	var a0 := ghost.modulate.a
	var an := FX.anim(260, [{"a": a0}, {"a": 0.0}], func(v): if is_instance_valid(ghost): ghost.modulate.a = v.a, {"node": ghost, "easing": "ease-out"})
	an.finished.connect(func(): if is_instance_valid(ghost): ghost.queue_free())


## 맞은 동료가 흔들린다(앞으로 밀렸다가 좌우로 떨림)
func ally_hurt(id: String) -> void:
	if not allies.has(id):
		return
	if anim and anim.has_ally(id):
		anim.hurt(id)
		return
	var h: Dictionary = D().motion.hurt
	var p := float(h.power) * (0.3 if FX.reduced else 1.0)
	var fr := [{"p": Vector2.ZERO}]
	var n := 7
	for i in n:
		var k := 1.0 - float(i) / n
		fr.append({"p": Vector2((-1 if i % 2 else 1) * p * k, p * 0.6 * k)})
	fr.append({"p": Vector2.ZERO})
	var node: Node2D = allies[id].node
	var base: Vector2 = allies[id].base
	FX.anim(float(h.dur), fr, func(v): if is_instance_valid(node): node.position = base + v.p, {"node": node, "easing": "ease-out", "key": "hurt_" + id})


## 적의 공격: 몸을 젖힘 → 달려듦(화면 앞쪽으로 커지며) → 제자리. 반환: 타격까지의 시간(ms)
func enemy_lunge(id: String, to := Vector2.INF) -> float:
	var m: Dictionary = D().motion.enemy
	if not enemies.has(id):
		return 0.0
	if anim and anim.has_enemy(id):
		return anim.enemy_lunge(id, to)
	var node: Node2D = enemies[id].node
	var red := 0.3 if FX.reduced else 1.0
	var T := float(m.windup) + float(m.rush) + float(m.back)
	var base := node.position
	FX.anim(T, [
		{"o": 0.0, "y": 0.0, "s": 1.0, "e": "ease-out"},
		{"o": float(m.windup) / T, "y": -8.0 * red, "s": 1.0 - 0.03 * red, "e": "cubic-bezier(.5,0,.9,.5)"},
		{"o": (float(m.windup) + float(m.rush)) / T, "y": float(m.dy) * red, "s": 1.0 + (float(m.scale) - 1.0) * red, "e": "cubic-bezier(.2,.7,.3,1)"},
		{"o": 1.0, "y": 0.0, "s": 1.0}], func(v):
			if is_instance_valid(node):
				node.position = base + Vector2(0, v.y)
				node.scale = Vector2(v.s, v.s), {"node": node})
	return float(m.windup) + float(m.rush)


# ───────── 거대 존재 ─────────
func _foot_node() -> Node2D:
	if foot != null and is_instance_valid(foot):
		return foot
	foot = _make_foot()   # 일반 전투 중 등장: 임시로 만든다
	return foot


func move_foot(y0: float, y1: float, ms: float, easing := "ease-out") -> void:
	var f := _foot_node()
	var base := foot_rect().position
	var a := FX.anim(ms, [{"y": y0}, {"y": y1}], func(v):
		if is_instance_valid(f):
			f.position = base + Vector2(0, v.y), {"node": f, "easing": easing, "key": "foot"})
	await FX.until(a)
	foot_y = y1


func giant_appear(victims: Array) -> void:
	G.dialog.clear()
	G.dialog.say(G.S.giantAppear.before)
	set_shadow(0.78, 1400)
	FX.rain(0, 1920, -20, {"count": 50, "colors": ["#8a8580", "#5a5550"], "size": 3, "life": 1800})
	for i in 3:
		FX.shake(4 + i * 2, 300)
		await FX.wait(420)
	var f := _foot_node()
	f.position = foot_rect().position + Vector2(0, -1200)
	var v: String = victims[0] if not victims.is_empty() else ""
	var drop := 60.0
	await move_foot(-1200, drop, float(D().timing.footDrop), "cubic-bezier(.55,0,1,.45)")
	FX.flash("#ffffff", 200, 0.55)
	FX.shake(30, 800)
	if v != "" and enemies.has(v):
		var b := enemy_box(v)
		var c := enemy_center(v)
		var n: Node2D = enemies[v].node
		FX.anim(80, [{"s": 1.0}, {"s": 0.05}], func(x): if is_instance_valid(n): n.scale = Vector2(1, x.s), {"node": n})
		FX.anim(200, [{"a": 1.0}, {"a": 0.0}], func(x): if is_instance_valid(n): n.modulate.a = x.a, {"node": n})
		if hp_enemy.has(v):
			hp_enemy[v].visible = false
		if intents.has(v):
			intents[v].visible = false
		FX.burst(c.x, b.end.y, {"count": 70, "colors": ["#8a8580", "#6a6560", "#4a4540"], "speed": 620, "spread": PI * 1.1, "angle": -PI / 2, "gravity": 420, "size": 6, "life": 1500})
		FX.burst(c.x, b.end.y, {"count": 26, "colors": ["#5a5550", "#3a3530"], "speed": 700, "spread": PI, "angle": -PI / 2, "gravity": 900, "size": 10, "life": 1300, "shape": "rock"})
		FX.burst(c.x, b.end.y - 10, {"count": 24, "colors": ["#7a0010", "#4a0008"], "speed": 420, "spread": PI, "angle": -PI / 2, "gravity": 900, "size": 4, "life": 900})
	vm.enemyAlive[v] = false
	await FX.wait(800)
	await move_foot(drop, 0, 1000, "ease-out")
	await G.dialog.say(G.S.giantAppear.after)


func giant_shadow() -> void:
	FX.rain(0, 1920, -10, {"count": 40, "colors": ["#777777", "#555555"], "size": 3, "life": 2000})
	set_shadow(0.95, 1600)
	FX.shake(5, 900)
	await move_foot(foot_y, 40, 1600, "ease-in-out")


func pillar_collapse() -> void:
	move_foot(foot_y, 70, 300, "ease-in")
	FX.shake(22, 900)
	FX.rain(0, 1920, -60, {"count": 60, "colors": ["#6a6560", "#4a4540", "#7a7570"], "size": 16, "life": 1500, "gravity": 1400, "shape": "rock", "stagger": 300})
	FX.rain(0, 1920, -20, {"count": 80, "colors": ["#9a958f", "#777777"], "size": 3, "life": 1800})
	await FX.wait(700)
	FX.burst(400, 560, {"count": 50, "colors": ["#8a8580", "#5a5550"], "speed": 500, "spread": PI, "angle": -PI / 2, "gravity": 300, "size": 7, "life": 1300})
	FX.burst(1500, 560, {"count": 50, "colors": ["#8a8580", "#5a5550"], "speed": 500, "spread": PI, "angle": -PI / 2, "gravity": 300, "size": 7, "life": 1300})
	FX.shake(16, 500)
	await FX.wait(300)


func giant_stomp() -> void:
	set_shadow(0.97, 700)
	await move_foot(foot_y, -180, 700, "ease-out")
	await FX.wait(400)
	# 마지막 짓밟기만은 발이 일행을 덮친다(평소에는 동료 뒤 레이어)
	layers.foot.z_index = 34
	await move_foot(-180, 900, 260, "cubic-bezier(.6,0,1,.4)")
	FX.flash("#ffffff", 260, 1)
	FX.shake(40, 900)
	await FX.wait(200)


## 운명이 걸린 「짓밟기」: 발이 들렸다가 일행 위로 내려오는 도중에 화면이 멈춘다 (대본 v3 5.2 — 그 순간 카드가 뒤집힌다)
func giant_stomp_halt() -> void:
	set_shadow(0.97, 700)
	await move_foot(foot_y, -180, 700, "ease-out")
	await FX.wait(300)
	layers.foot.z_index = 34
	await move_foot(-180, 160, 220, "cubic-bezier(.6,0,1,.4)")
	FX.shake(8, 300)


func giant_retreat() -> void:
	G.dialog.clear()
	FX.shake(18, 900)
	FX.rain(0, 1920, -20, {"count": 70, "colors": ["#8a8580", "#5a5550"], "size": 4, "life": 2000})
	await move_foot(foot_y, -60, 300, "ease-out")
	for k in hp_enemy:
		hp_enemy[k].visible = false
	for k in intents:
		intents[k].visible = false
	vm.intents = {}
	for k in vm.enemyAlive:
		vm.enemyAlive[k] = false
	set_shadow(0, 2200)
	await move_foot(-60, -1300, 1600, "ease-in")


## 짓밟힘: 붉은 환영의 발이 내리찍는다 (거대 존재 = 동료 뒤 레이어)
func trample_strike() -> void:
	var ph := TrampleFoot.new()
	ph.position = Vector2(560, -700)
	ph.z_index = 17
	add_child(ph)
	FX.flash("#660000", 400, 0.5)
	var a := FX.anim(380, [{"y": -700.0}, {"y": 120.0}], func(v): if is_instance_valid(ph): ph.position.y = v.y, {"node": ph, "easing": "cubic-bezier(.6,0,1,.4)"})
	await FX.until(a)
	FX.flash("#ffffff", 220, 0.8)
	FX.shake(36, 900)
	FX.burst(960, 420, {"count": 80, "colors": ["#ff2a3c", "#7a0010", "#8a8580"], "speed": 700, "spread": PI * 2, "gravity": 500, "size": 6, "life": 1400})
	var b := FX.anim(700, [{"a": 0.85}, {"a": 0.0}], func(v): if is_instance_valid(ph): ph.modulate.a = v.a, {"node": ph})
	await FX.until(b)
	ph.queue_free()


# ───────── 용사의 죽음: 컷신(C1~C6) → 전투 화면 복귀(C7) ─────────
func death_sequence(e: Dictionary) -> void:
	var cs: Dictionary = D().cutscene
	var who: String = str(e.get("ally", "hero"))
	var key: String = "hero" if who == "hero" or str(e.get("fate", "")) == "" else str(e.fate)
	G.dialog.clear()
	G.scenes.cutscene(key, int(e.get("lv", 1)))     # 컷신 화면이 곧바로 덮는다
	# 컷신 뒤에서: 들어 올렸던 손을 내리고 죽음 카드를 원래 손패 자리로 (C7에서 그 자리에서 재가 된다)
	hand.raise_reset()
	fate_hold = ""
	if fate_tint:
		fate_tint.color.a = 0.0
	await G.scenes.cutscene_done
	G.ctl.note("death: back to battle")
	vm.pull = 0.0
	vm.status[who] = "dead"
	trembling.erase(who)
	vm.broken = {"uid": "", "at": hand.top_point(vm.ghost), "ally": who}
	render()
	# 마녀의 손·손패 위에 튄 피 (C7)
	blood.spray({"count": 3, "x0": 620, "x1": 820, "y0": 890, "y1": 1030, "min": 60, "max": 120, "seed": 4242})
	blood.spray({"count": 3, "x0": 1100, "x1": 1300, "y0": 890, "y1": 1030, "min": 60, "max": 120, "seed": 5151})
	blood.spray({"count": 2, "x0": 820, "x1": 1100, "y0": 650, "y1": 760, "min": 34, "max": 70, "seed": 99})
	blood.spray({"count": 5, "x0": 300, "x1": 1620, "y0": 280, "y1": 1000, "min": 14, "max": 34, "seed": 7})
	blood.modulate.a = 1.0
	await G.scenes.close_cutscene(float(cs.returnDelay))
	G.ctl.note("death: C7")
	# 죽음 카드가 재로 부서진다
	var g: CardView = hand.cards.get(vm.ghost)
	if g:
		g.taut = 0.0
		var q := g.corners
		FX.anim(1400, [{"b": 1.0, "a": 1.0}, {"b": 0.15, "a": 0.0}], func(v): if is_instance_valid(g): g.bright = v.b; g.alpha = v.a, {"node": g})
		var steps := 10
		for i in steps:
			var tt := float(i) / steps
			var x := lerpf(q[0].x, q[1].x, randf())
			var y := lerpf(q[0].y, q[3].y, 1.0 - tt)
			FX.burst(x, y, {"count": 14, "colors": ["#2a2a2a", "#555555", "#111111", "#7a0010"], "speed": 90, "angle": -PI / 2, "spread": 1.6, "gravity": -90, "size": 3, "life": 1400, "shape": "flake", "jitterX": 120})
			await FX.wait(float(cs.ashDuration) / steps)


## C8: 남은 동료의 반응 (굳고 떨림 + 짧은 대사). dead: 죽은 동료 (세라피나 = 대본 그대로, 그 밖 = reactionsBy)
func reactions(dead := "hero") -> void:
	var cs: Dictionary = D().cutscene
	var st: Dictionary = G.ctl.st
	var who := []
	for id in st.party.order:
		if st.party.allies[id].status != "dead":
			who.append(id)
			trembling[id] = true
	var stop := get_tree().create_timer(FX.ms(float(cs.reactionTremble)) / 1000.0, false)
	stop.timeout.connect(func():
		for id in who:
			trembling.erase(id))
	var lines: Array = G.S.reactions if dead == "hero" else G.S.reactionsBy.get(dead, [])
	var keep := []
	for ln in lines:
		var a = st.party.allies.get(str(ln.get("who", "")))
		if a == null or a.status != "dead":
			keep.append(ln)
	await G.dialog.say(keep)
	for id in who:
		trembling.erase(id)
	# 피 자국은 조금 옅어진 채 남는다 (손패를 읽을 수 있게)
	var a0 := blood.modulate.a
	FX.anim(1600, [{"a": a0}, {"a": float(cs.bloodRemain)}], func(v): if is_instance_valid(blood): blood.modulate.a = v.a, {"node": blood})


# ───────── HUD 부품 ─────────
class AllyHp extends Control:
	var who := ""
	var hp := 0
	var mx := 1
	var status := "ok"
	var valid := false
	var hot := false
	var nm: Label
	var v: Label

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(230, 50)
		nm = UI.label(G.name_of(who), 20, Color("#e8e8ee"), "sans_bold")
		nm.position = Vector2(14, 4)
		add_child(nm)
		v = UI.label("", 20, Color("#ffb3b9"), "sans_bold", HORIZONTAL_ALIGNMENT_RIGHT)
		v.position = Vector2(100, 4)
		v.size = Vector2(116, 26)
		add_child(v)

	func set_vals(h: int, m: int, s: String) -> void:
		hp = h
		mx = m
		status = s
		v.text = G.ui("down") if s == "down" else "%d / %d" % [h, m]
		v.add_theme_color_override("font_color", Color("#888888") if s == "down" else Color("#ffb3b9"))
		nm.add_theme_color_override("font_color", Color("#777777") if s == "down" else Color("#e8e8ee"))
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var border := Color("#333333") if status == "down" else Color("#5a5f6c")
		if valid:
			border = Color("#ff4d5a")
		if hot:
			border = Color("#ffd36b")
		if valid or hot:
			draw_style_box(UI.box(Color(0, 0, 0, 0), Color(border.r, border.g, border.b, 0.4), 20, 8), r.grow(5))
		draw_style_box(UI.box(Color(0.07, 0.07, 0.09, 0.95), border, 16, 1), r)
		var bar := Rect2(12, 34, size.x - 24, 10)
		draw_style_box(UI.box(Color("#2a0b10"), Color.BLACK, 6, 1), bar)
		var k := clampf(float(hp) / maxf(1.0, float(mx)), 0.0, 1.0)
		if k > 0:
			draw_style_box(UI.box(Color("#d02a3a"), Color.TRANSPARENT, 5), Rect2(bar.position + Vector2(1, 1), Vector2((bar.size.x - 2) * k, bar.size.y - 2)))
			draw_rect(Rect2(bar.position + Vector2(3, 2), Vector2(maxf(0, (bar.size.x - 6) * k), 2)), Color(1, 0.5, 0.55, 0.5))


class EnemyHp extends Control:
	var giant := false
	var hp = 0
	var mx = 0
	var v: Label

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(260 if giant else 160, 24)
		position.x -= size.x / 2.0
		v = UI.label("", 17, Color.WHITE, "sans_bold", HORIZONTAL_ALIGNMENT_CENTER, 3)
		v.size = size
		v.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(v)

	func set_vals(h, m) -> void:
		hp = h
		mx = m
		if m == null:
			v.text = "? ? ?"
			v.add_theme_color_override("font_color", Color("#c9c9c9"))
		else:
			v.text = "%d / %d" % [int(h), int(m)]
		queue_redraw()

	func _poly(r: Rect2) -> PackedVector2Array:
		var w := r.size.x
		var h := r.size.y
		var o := r.position
		return PackedVector2Array([o + Vector2(w * 0.08, 0), o + Vector2(w * 0.92, 0), o + Vector2(w, h / 2), o + Vector2(w * 0.92, h), o + Vector2(w * 0.08, h), o + Vector2(0, h / 2)])

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_colored_polygon(_poly(r), Color("#14070a"))
		if mx == null:
			for i in int(size.x / 12):
				draw_rect(Rect2(i * 12 + 4, 2, 6, size.y - 4), Color("#333333"))
		else:
			var k := clampf(float(hp) / maxf(1.0, float(mx)), 0.0, 1.0)
			if k > 0:
				var fill := _poly(r)
				var cut := size.x * k
				var clip := PackedVector2Array()
				for p in fill:
					clip.append(Vector2(minf(p.x, cut), p.y))
				draw_colored_polygon(clip, Color("#a0281f"))
		var loop := _poly(r)
		loop.append(loop[0])
		draw_polyline(loop, Color("#7b2a33"), 1.5, true)


class WitchPanel extends Control:
	var hp := 0
	var mx := 1
	var valid := false
	var hot := false
	var nm: Label
	var v: Label
	var sub: Label
	var face: TextureRect
	var _t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		face = TextureRect.new()
		face.texture = Assets.face_tex("noel")
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.position = Vector2(14, 13)
		face.size = Vector2(78, 78)
		var m := ShaderMaterial.new()
		m.shader = preload("res://ui/shaders/circle.gdshader")
		face.material = m
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(face)
		nm = UI.label(G.name_of("witch"), 22, Color("#f0d8dc"), "serif_bold")
		nm.position = Vector2(106, 10)
		add_child(nm)
		v = UI.label("", 22, Color("#ff9aa4"), "sans_bold", HORIZONTAL_ALIGNMENT_RIGHT)
		v.position = Vector2(180, 10)
		v.size = Vector2(124, 28)
		add_child(v)
		sub = UI.label(G.ui("witchSub"), 15, Color("#aa9999"), "sans")
		sub.position = Vector2(106, 68)
		add_child(sub)

	func set_vals(h: int, m: int) -> void:
		hp = h
		mx = m
		v.text = "%d / %d" % [h, m]
		queue_redraw()

	func _process(d: float) -> void:
		_t += d
		if valid:
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var border := Color("#6b2a3c")
		if valid:
			border = Color(1, 0.3, 0.35, 0.6 + 0.4 * sin(_t * TAU))
		if hot:
			border = Color("#ffd36b")
		if valid or hot:
			draw_style_box(UI.box(Color(0, 0, 0, 0), Color(border.r, border.g, border.b, 0.4), 18, 10), r.grow(6))
		draw_style_box(UI.box(Color(0.07, 0.04, 0.06, 0.92), border, 14, 1), r)
		draw_circle(Vector2(53, 52), 41, Color("#7a2232"))
		var bar := Rect2(106, 44, size.x - 122, 14)
		draw_style_box(UI.box(Color("#2a0b10"), Color.BLACK, 7, 1), bar)
		var k := clampf(float(hp) / maxf(1.0, float(mx)), 0.0, 1.0)
		if k > 0:
			draw_style_box(UI.box(Color("#d02a3a"), Color.TRANSPARENT, 6), Rect2(bar.position + Vector2(1, 1), Vector2((bar.size.x - 2) * k, bar.size.y - 2)))


class EnergyOrb extends Control:
	var e := 3
	var mx := 3
	var lab: Label
	var small: Label

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		lab = UI.label("", 44, Color.WHITE, "serif_black", HORIZONTAL_ALIGNMENT_CENTER, 4)
		lab.size = Vector2(size.x, size.y * 0.72)
		lab.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		add_child(lab)
		small = UI.label("", 15, Color(1, 1, 1, 0.8), "sans_bold", HORIZONTAL_ALIGNMENT_CENTER)
		small.position = Vector2(0, size.y * 0.68)
		small.size = Vector2(size.x, 20)
		add_child(small)

	func set_vals(v: int, m: int) -> void:
		e = v
		mx = m
		lab.text = str(v)
		small.text = "/ %d" % m
		queue_redraw()

	func _draw() -> void:
		var c := size / 2.0
		var r := size.x / 2.0
		if e > 0:
			for i in 4:
				draw_circle(c, r + 6 + i * 4, Color(1, 0.16, 0.24, 0.1 - i * 0.02))
			draw_circle(c, r, Color("#2a0a0e"))
			draw_circle(c, r - 3, Color("#3c050b"))
			draw_circle(c + Vector2(-2, -3), r - 8, Color("#8a0e18"))
			draw_circle(c + Vector2(-5, -8), r - 20, Color("#c2232f"))
			draw_circle(c + Vector2(-10, -14), r - 36, Color(1, 0.48, 0.53, 0.8))
		else:
			draw_circle(c, r, Color("#120d0e"))
			draw_circle(c + Vector2(-4, -6), r - 10, Color("#2a2224"))


class IntentBox extends Control:
	var giant := false
	var valid := false
	var hot := false
	var hovered := false
	var it = null
	var parts: Array = []
	var icon: TextureRect
	var _t := 0.0
	const ICON := {
		"attack": "<svg viewBox=\"0 0 32 32\" xmlns=\"http://www.w3.org/2000/svg\"><path d=\"M6 26 L22 10 L25 4 L28 7 L22 10\" stroke=\"#ff6b76\" stroke-width=\"3\" fill=\"none\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/><path d=\"M8 18 L14 24 M5 27 L9 23\" stroke=\"#ddd\" stroke-width=\"3\" stroke-linecap=\"round\"/></svg>",
		"shadow": "<svg viewBox=\"0 0 32 32\" xmlns=\"http://www.w3.org/2000/svg\"><ellipse cx=\"16\" cy=\"20\" rx=\"13\" ry=\"6\" fill=\"#000\" stroke=\"#777\" stroke-width=\"2\"/><path d=\"M8 4 C10 12 22 12 24 4\" stroke=\"#888\" stroke-width=\"2\" fill=\"none\"/></svg>",
		"aoe": "<svg viewBox=\"0 0 32 32\" xmlns=\"http://www.w3.org/2000/svg\"><rect x=\"11\" y=\"2\" width=\"10\" height=\"20\" fill=\"#888\" transform=\"rotate(18 16 12)\"/><g fill=\"#aaa\"><circle cx=\"7\" cy=\"26\" r=\"3\"/><circle cx=\"16\" cy=\"28\" r=\"2.5\"/><circle cx=\"25\" cy=\"25\" r=\"3\"/></g></svg>",
		"fate": "<svg viewBox=\"0 0 32 32\" xmlns=\"http://www.w3.org/2000/svg\"><path d=\"M16 2 C22 10 26 14 24 22 C22 29 10 29 8 22 C6 15 12 12 16 2Z\" fill=\"#ff3a1e\"/><path d=\"M16 12 C19 16 20 19 19 23 C18 26 14 26 13 23 C12 20 14 17 16 12Z\" fill=\"#ffe08a\"/><path d=\"M2 30 Q16 20 30 30\" stroke=\"#ff2a3c\" stroke-width=\"2\" fill=\"none\"/></svg>",
		"fate_pierce": "<svg viewBox=\"0 0 32 32\" xmlns=\"http://www.w3.org/2000/svg\"><path d=\"M16 1 L21 11 L17.5 13 L17.5 27 L14.5 27 L14.5 13 L11 11Z\" fill=\"#d8d8e0\"/><path d=\"M16 6 L18.5 11 L13.5 11Z\" fill=\"#ff2a3c\"/><rect x=\"14.5\" y=\"13\" width=\"3\" height=\"14\" fill=\"#6a4a36\"/><path d=\"M2 30 Q16 20 30 30\" stroke=\"#ff2a3c\" stroke-width=\"2\" fill=\"none\"/></svg>",
		"fire": "<svg viewBox=\"0 0 32 32\" xmlns=\"http://www.w3.org/2000/svg\"><path d=\"M16 3 C21 10 25 14 23 21 C21 28 11 28 9 21 C7 15 12 11 16 3Z\" fill=\"#ff7a2a\"/><path d=\"M16 13 C18 16 19 19 18 22 C17 25 15 25 14 22 C13 19 15 17 16 13Z\" fill=\"#ffe08a\"/></svg>",
		"hidden": "<svg viewBox=\"0 0 32 32\" xmlns=\"http://www.w3.org/2000/svg\"><circle cx=\"16\" cy=\"16\" r=\"13\" fill=\"#0a0608\" stroke=\"#6a5a60\" stroke-width=\"2\"/><path d=\"M11.5 12.5 C11.5 8.5 20.5 8.5 20.5 12.5 C20.5 15.5 16 15.5 16 19\" stroke=\"#b8a8ae\" stroke-width=\"3\" fill=\"none\" stroke-linecap=\"round\"/><circle cx=\"16\" cy=\"24\" r=\"1.9\" fill=\"#b8a8ae\"/></svg>",
		"stomp": "<svg viewBox=\"0 0 32 32\" xmlns=\"http://www.w3.org/2000/svg\"><path d=\"M10 12 C9 18 9 26 15 29 C21 31 24 27 23 21 C22 16 22 12 22 10 C22 7 11 7 10 12Z\" fill=\"#ff3346\"/><circle cx=\"10\" cy=\"6\" r=\"2.5\" fill=\"#ff3346\"/><circle cx=\"14.5\" cy=\"4\" r=\"2.4\" fill=\"#ff3346\"/><circle cx=\"19\" cy=\"4\" r=\"2.2\" fill=\"#ff3346\"/><circle cx=\"22.5\" cy=\"6\" r=\"2\" fill=\"#ff3346\"/></svg>",
	}

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon = TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(icon)

	func _process(d: float) -> void:
		_t += d

	## 예고 아이콘: 그림(game_data intentIcons)이 있으면 그 그림, 없으면 코드로 그린 SVG
	func _icon(key: String, svg_key: String) -> Texture2D:
		var f := str(GameData.D.get("intentIcons", {}).get(key, ""))
		if f != "" and Assets.ok(f):
			return Assets.tex(f)
		return Assets.svg("intent_" + svg_key, ICON.get(svg_key, ICON.attack), 2.0)

	func _clear_parts() -> void:
		for p in parts:
			p.queue_free()
		parts = []

	func _add(text: String, size: int, col: Color, font := "sans_bold") -> Label:
		var l := UI.label(text, size, col, font)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(l)
		parts.append(l)
		return l

	func _layout(h: float) -> void:
		var x := 10.0
		icon.position = Vector2(x, (h - 34) / 2.0)
		icon.size = Vector2(34, 34)
		x += 40
		for p in parts:
			if p.has_meta("pips"):
				p.position = Vector2(x + 4, (h - 12) / 2.0)
				x += p.size.x + 8
				continue
			var s: Vector2 = p.get_combined_minimum_size()
			p.position = Vector2(x, (h - s.y) / 2.0)
			p.size = s
			x += s.x + 7
		size = Vector2(x + 10, h)

	## 어둠에 가려진 예고: 「?」만 보인다 (무엇을 누구에게 할지 모른다 — 규칙은 그대로)
	func _set_hidden(v: Dictionary, h: float) -> void:
		icon.texture = _icon("hidden", "hidden")
		_add(G.ui("hidden"), 30, Color("#b8a8ae"), "sans_black")
		if v.get("blocked", false):
			_add(G.ui("canceled") if v.get("canceled", false) else G.ui("blocked"), 20, Color("#9be59b"), "sans_black")
		elif not v.get("by", []).is_empty():
			_add("(" + str(v.by[-1]) + ")", 16, Color("#ffcf7a"), "sans")
		_layout(h)
		queue_redraw()

	func set_attack(v: Dictionary) -> void:
		var key := str(v)
		if key == str(it):
			return
		it = v.duplicate(true)
		_clear_parts()
		if v.get("hidden", false):
			_set_hidden(v, 48)
			return
		if v.kind == "fate":
			# 운명의 불길 → 엘리안 · 치명 · 옮기기 불가 (관통 운명은 창 아이콘)
			var fdm = GameData.D.fates.get(str(v.get("fate", "")))
			if fdm != null and str(fdm.method) == "pierce":
				icon.texture = _icon("fate_pierce", "fate_pierce")
			else:
				icon.texture = _icon("fate", "fate")
			_add(str(v.get("label", "")), 28, Color("#ffd0a0"), "sans_black")
			_add("→", 22, Color("#ffb0a0"))
			_add(G.name_of(v.target), 28, Color("#ffffff"), "sans_black")
			_add(G.ui("lethal"), 22, Color("#ff6b76"), "sans_black")
			_add(G.ui("noRedirect"), 20, Color("#ffcf7a"), "sans_bold")
			_layout(60)
			queue_redraw()
			return
		if v.get("blocked", false):
			icon.texture = _icon("attack", "attack")
			_add(G.ui("canceled") if v.get("canceled", false) else G.ui("blocked"), 22, Color("#9be59b"), "sans_black")
			if not v.get("by", []).is_empty():
				_add("(" + str(v.by[-1]) + ")", 16, Color("#ffcf7a"), "sans")
			_layout(48)
			queue_redraw()
			return
		if v.kind == "aoe":
			icon.texture = Assets.svg("intent_fire", ICON.fire, 2.0)
			_add(str(v.get("label", "")), 22, Color("#ffd0d4"), "sans_bold")
			_add(str(v.value), 30, Color("#ff6b76"), "sans_black")
			_add("→", 20, Color("#b9a0a4"))
			_add(G.ui("allTargets"), 20, Color("#f0dede"))
			_layout(48)
			queue_redraw()
			return
		icon.texture = _icon("attack", "attack")
		if str(v.get("label", "")) != "":
			_add(str(v.label), 18, Color("#d9b9bd"), "sans_bold")
		var dmg := Rules.intent_damage(v)
		_add(str(dmg), 30, Color("#9be59b") if dmg < int(v.value) else Color("#ff6b76"), "sans_black")
		_add("→", 20, Color("#b9a0a4"))
		_add(G.name_of(v.target), 22, Color("#f0dede"))
		if not v.get("by", []).is_empty():
			_add("(" + str(v.by[-1]) + ")", 16, Color("#ffcf7a"), "sans")
		_layout(48)
		queue_redraw()

	func set_giant(v: Dictionary) -> void:
		var key := str(v)
		if key == str(it):
			return
		it = v.duplicate(true)
		_clear_parts()
		if v.get("hidden", false):
			_set_hidden(v, 56)
			return
		if v.get("blocked", false):
			icon.texture = Assets.svg("intent_" + str(v.kind), ICON.get(str(v.kind), ICON.attack), 2.0)
			_add(str(v.label), 26, Color("#ffd0d4"), "sans_bold")
			_add(G.ui("canceled") if v.get("canceled", false) else G.ui("blocked"), 22, Color("#9be59b"), "sans_black")
			_layout(56)
			queue_redraw()
			return
		icon.texture = Assets.svg("intent_" + str(v.kind), ICON.get(str(v.kind), ICON.attack), 2.0)
		_add(str(v.label), 26, Color("#ffd0d4"), "sans_bold")
		if v.kind == "aoe":
			_add(str(v.value), 28, Color("#ff6b76"), "sans_black")
			_add("→", 20, Color("#b9a0a4"))
			_add(str(v.detail), 20, Color("#f0dede"))
		else:
			_add(str(v.detail), 18, Color("#c8a9ad"), "sans")
		var pips := Control.new()
		pips.set_meta("pips", true)
		pips.size = Vector2(int(v.total) * 16, 12)
		pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var step := int(v.step)
		var tot := int(v.total)
		pips.draw.connect(func():
			for i in tot:
				var on := i + 1 <= step
				var c := Vector2(6 + i * 16, 6)
				if on:
					pips.draw_circle(c, 9, Color(1, 0.2, 0.27, 0.35))
				pips.draw_circle(c, 6, Color("#ff3346") if on else Color("#3a1418"))
				pips.draw_arc(c, 6, 0, TAU, 16, Color("#aa3333"), 1.0))
		add_child(pips)
		parts.append(pips)
		_layout(56)
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var lethal: bool = it != null and it.get("lethal", false) and not it.get("hidden", false)
		var bg := Color(0.24, 0, 0.024, 0.9) if lethal else Color(0.04, 0.024, 0.03, 0.85)
		var border := Color("#8a1a24") if giant else Color("#6e2a31")
		var glow := 0.0
		if lethal:
			border = Color("#ff2a3a")
			glow = 0.5 + 0.5 * sin(_t * TAU)
		if hovered or valid:
			border = Color("#ff5361")
			glow = 0.9 if hovered else 0.55 + 0.45 * sin(_t * TAU)
		if hot:
			border = Color("#ffd36b")
			glow = 1.0
		if glow > 0:
			draw_style_box(UI.box(Color(0, 0, 0, 0), Color(border.r, border.g, border.b, 0.35 * glow), int(size.y / 2) + 8, 10), r.grow(6))
		draw_style_box(UI.box(bg, border, int(size.y / 2), 2 if (glow > 0) else 1), r)


## 짓밟힘의 붉은 환영 발 (코드로 그린 모양)
class TrampleFoot extends Node2D:
	func _draw() -> void:
		var k := Vector2(800.0 / 212.0, 700.0 / 184.0)
		var pts := PackedVector2Array()
		var path := [[70, 10], [64, 60], [66, 130], [102, 166], [130, 186], [156, 160], [152, 120], [150, 90], [146, 40], [146, 10]]
		for i in range(path.size() - 1):
			var a := Vector2(path[i][0], path[i][1])
			var b := Vector2(path[i + 1][0], path[i + 1][1])
			for t in 6:
				pts.append(a.lerp(b, t / 6.0) * k)
		pts.append(Vector2(146, 10) * k)
		for i in 4:
			draw_colored_polygon(_grow(pts, 1.0 + 0.04 * (i + 1)), Color(1, 0.16, 0.24, 0.08))
		draw_colored_polygon(pts, Color(0.63, 0, 0.08, 0.75))
		var loop := pts.duplicate()
		loop.append(pts[0])
		draw_polyline(loop, Color("#ff3346"), 5.0, true)

	func _grow(p: PackedVector2Array, g: float) -> PackedVector2Array:
		var c := Vector2.ZERO
		for q in p:
			c += q
		c /= p.size()
		var out := PackedVector2Array()
		for q in p:
			out.append(c + (q - c) * g)
		return out
