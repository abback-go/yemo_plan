## board_table.gd — 전투 시험판 v2.1 「3D 탁자」의 탁자와 카드 (docs/battle-v2-spec.md 9-1). scenes/board_battle.gd 가 만들고 카드 자리를 정한다.
## 3D: 돌판 탁자(바닥 판에 bg_f_battle_table — art/raw/vs_f/75) + 카드(앞면 그림을 붙인 얇은 판) + 고정 카메라(table3d.pitch 도로 내려다봄).
##   SubViewport(own_world_3d) 하나에 그리고 TextureRect 로 2D 화면 맨 뒤에 깐다 → 그 위에 노엘의 손·손패·HUD(2D)가 겹친다.
##   렌더러는 gl_compatibility 그대로, 조명·실시간 그림자·후처리 없음(카드·탁자 모두 unshaded 셰이더, 그림자는 카드 밑 번진 판) — 웹(WebGL 2)용.
## 카메라: 격자(① 맨 뒤 끝 ~ ④ 맨 앞 끝)가 화면 fitY 에 오도록 높이·위치를 계산하고, 양옆(벤치·적 덱)이 fitX 를 넘으면 물린다 → pitch 하나만 바꿔도 맞는다.
## 화면 좌표(무대 1920×1080) ↔ 탁자: ground()(화면 점 → 탁자 평면과 교차) · to_screen()(3D → 화면) · pick()(화면 점의 맨 위 카드).
## 카드 손맛(Card3D): 들림(lift)·기울어짐(tilt)·떨어짐(드롭 후 살짝 튐)·뒤집기(flip, 긴 축으로 180°)·처리될 때 밀려나 사라짐(push_out).
class_name BoardTable
extends Control

const SW := 1920.0
const SH := 1080.0

var vp: SubViewport
var view: TextureRect
var cam: Camera3D
var world: Node3D
var cards := {}          # key → Card3D
var labels := {}         # 이름 → Label3D
var back_tex: Texture2D
var _shader_card: Shader
var _shader_shadow: Shader
var _fit_y1 := 0.0
var table_mat: ShaderMaterial


static func TL() -> Dictionary:
	return BattleV2Data.D.table3d


func setup() -> void:
	size = Vector2(SW, SH)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shader_card = preload("res://ui/shaders/card3d.gdshader")
	_shader_shadow = preload("res://ui/shaders/shadow3d.gdshader")
	back_tex = Assets.tex(str(GameData.D.cardBackImg))
	vp = SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = false
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.size = _vp_size()
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	world = Node3D.new()
	vp.add_child(world)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012, 0.008, 0.01)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	we.environment = env
	world.add_child(we)
	cam = Camera3D.new()
	cam.fov = float(TL().fov)
	cam.near = 0.2
	cam.far = 80.0
	world.add_child(cam)
	cam.current = true
	fit_camera()
	_make_table()
	view = TextureRect.new()
	view.texture = vp.get_texture()
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_SCALE
	view.size = size
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(view)
	get_viewport().size_changed.connect(_on_resize)


## 3D 화면 해상도: 무대가 실제 창에서 보이는 픽셀 크기(가로 960~2400)
func _vp_size() -> Vector2i:
	var ws := Vector2(DisplayServer.window_get_size())
	var s := clampf(minf(ws.x / SW, ws.y / SH), 0.5, 1.25)
	return Vector2i(int(SW * s), int(SH * s))


func _on_resize() -> void:
	if is_instance_valid(vp):
		vp.size = _vp_size()


# ───────── 카메라 ─────────
## pitch 도로 내려다보며 격자 z 범위가 화면 y 범위 [y0, y1] 에 오는 카메라(높이 h, 앞뒤 zc)를 계산한다.
## 그 뒤 양옆 기준점(격자 양 끝·벤치·적 덱)이 fitX 밖이면 y1 을 줄여(카메라를 물려) 다시 맞춘다
func fit_camera() -> void:
	var T := TL()
	var th := deg_to_rad(float(T.pitch))
	var f := 1.0 / tan(deg_to_rad(float(T.fov)) / 2.0)
	var rows: Array = T.rows
	var ch: float = T.card[1]
	var z0 := float(rows[0]) - ch / 2.0
	var z1 := float(rows[rows.size() - 1]) + ch / 2.0
	var y0 := float(T.fitY[0])
	var y1 := float(T.fitY[1])
	for it in 80:
		var a0 := th + atan((y0 - SH / 2.0) / (f * SH / 2.0))
		var a1 := th + atan((y1 - SH / 2.0) / (f * SH / 2.0))
		var h := (z1 - z0) / (1.0 / tan(a0) - 1.0 / tan(a1))
		var zc := z1 + h / tan(a1)
		cam.position = Vector3(0, h, zc)
		cam.rotation = Vector3(-th, 0, 0)
		_fit_y1 = y1
		if _fits_x():
			break
		y1 -= 8.0
	cam.fov = float(T.fov)


func _fits_x() -> bool:
	var T := TL()
	var cw: float = T.card[0]
	var ch: float = T.card[1]
	var cols: Array = T.cols
	var half := float(T.cellW) / 2.0
	var pts := []
	for r in T.rows:
		pts.append(Vector3(float(cols[0]) - half, 0, float(r) + ch / 2.0))
		pts.append(Vector3(float(cols[cols.size() - 1]) + half, 0, float(r) + ch / 2.0))
	for k in ["bench", "enemyDeck", "note"]:
		var b: Dictionary = T[k]
		pts.append(Vector3(float(b.x) + cw / 2.0 + 0.05, 0, float(b.z) + ch / 2.0))
		pts.append(Vector3(float(b.x) - cw / 2.0 - 0.05, 0, float(b.z) + ch / 2.0))
	for p in pts:
		var s := to_screen(p)
		if s.x < float(T.fitX[0]) or s.x > float(T.fitX[1]):
			return false
	return true


# ───────── 화면 ↔ 탁자 ─────────
func _k() -> float:
	return float(vp.size.x) / SW


func to_screen(p: Vector3) -> Vector2:
	if cam.is_position_behind(p):
		return Vector2(-9999, -9999)
	return cam.unproject_position(p) / _k()


## 화면 점에서 나가는 광선이 높이 y 의 평면과 만나는 점 (없으면 null)
func ground(p: Vector2, y := 0.0):
	var vpp := p * _k()
	var o := cam.project_ray_origin(vpp)
	var d := cam.project_ray_normal(vpp)
	if absf(d.y) < 1e-5:
		return null
	var t := (y - o.y) / d.y
	if t <= 0:
		return null
	return o + d * t


## 화면 점 아래 맨 위 카드 (pickable 인 것만, 우선순위 높은 것부터) — "" 없음
func pick(p: Vector2, filter := Callable()) -> String:
	var best := ""
	var bp := -1e9
	for key in cards:
		var c: Card3D = cards[key]
		if not c.pickable or not c.visible or c.dying:
			continue
		if filter.is_valid() and not filter.call(key):
			continue
		var hit = ground(p, c.position.y)
		if hit == null:
			continue
		var l: Vector3 = c.global_transform.affine_inverse() * hit
		if absf(l.x) <= c.csize.x / 2.0 and absf(l.z) <= c.csize.y / 2.0:
			var pr := float(c.prio) + c.position.y * 10.0
			if pr > bp:
				bp = pr
				best = key
	return best


## 카드가 화면에서 차지하는 사각형(네 모서리를 투영한 상자)
func screen_rect(key: String) -> Rect2:
	var c: Card3D = cards.get(key)
	if c == null:
		return Rect2()
	return rect_of(c.global_transform, c.csize)


## sz: 카드 크기(없으면 보통 카드 — 거대한 발처럼 큰 카드는 그 카드의 csize)
func rect_of(xf: Transform3D, sz := Vector2.ZERO) -> Rect2:
	var cw: float = sz.x if sz.x > 0.0 else float(TL().card[0])
	var ch: float = sz.y if sz.y > 0.0 else float(TL().card[1])
	var r := Rect2()
	var first := true
	for v in [Vector3(-cw / 2, 0, -ch / 2), Vector3(cw / 2, 0, -ch / 2), Vector3(cw / 2, 0, ch / 2), Vector3(-cw / 2, 0, ch / 2)]:
		var s := to_screen(xf * v)
		if first:
			r = Rect2(s, Vector2.ZERO)
			first = false
		else:
			r = r.expand(s)
	return r


## 탁자 위 자리(카드가 놓일 Transform)의 화면 사각형
func rect_at(pos: Vector3, yaw := 0.0) -> Rect2:
	return rect_of(Transform3D(Basis(Vector3.UP, yaw), pos))


# ───────── 탁자 · 글자 ─────────
func _make_table() -> void:
	var T: Dictionary = TL().table
	var t := Assets.tex(str(T.img)) if Assets.ok(str(T.img)) else null
	var w := float(T.w)
	var d := w * (t.get_height() / float(t.get_width()) if t != null else 9.0 / 16.0)
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(w, d)
	mi.mesh = pm
	var m := ShaderMaterial.new()
	m.shader = preload("res://ui/shaders/table3d.gdshader")
	if t != null:
		m.set_shader_parameter("tex", t)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(mi)
	table_mat = m


## 그 방의 VN 배경을 탁자 너머(화면 위쪽, 진하게)와 탁자 전체(옅게)에 어둡게 비춘다 — 밤샘 계획 2 A(1층 전투). null 이면 끔
func set_room(t: Texture2D) -> void:
	if table_mat == null:
		return
	table_mat.set_shader_parameter("room_on", 1.0 if t != null else 0.0)
	if t != null:
		table_mat.set_shader_parameter("room", t)


## 탁자에 눕힌 글자 (화면 쪽에서 읽히게)
func label(name: String, text: String, pos: Vector3, px: int, col := Color(0.85, 0.78, 0.72, 0.85), prio := 0) -> Label3D:
	var l: Label3D = labels.get(name)
	if l == null:
		l = Label3D.new()
		l.font = Assets.font("sans_bold")
		l.shaded = false
		l.double_sided = true
		l.no_depth_test = false
		l.alpha_cut = Label3D.ALPHA_CUT_DISABLED
		l.outline_size = 8
		l.outline_modulate = Color(0, 0, 0, 0.8)
		l.pixel_size = 0.0042
		l.rotation = Vector3(-PI / 2.0, 0, 0)
		world.add_child(l)
		labels[name] = l
	l.text = text
	l.render_priority = prio
	l.font_size = px
	l.modulate = col
	l.position = pos + Vector3(0, 0.003, 0)
	return l


# ───────── 카드 ─────────
func card(key: String) -> Card3D:
	return cards.get(key)


## size: 카드 크기(탁자 단위) — 없으면 보통 카드(table3d.card). 거대한 발은 세 칸을 덮는 큰 카드
func make_card(key: String, face: Dictionary, pos: Vector3, size := Vector2.ZERO) -> Card3D:
	var c := Card3D.new()
	c.key = key
	c.table = self
	if size.x > 0.0:
		c.csize = size
	world.add_child(c)
	c.setup(face, back_tex, float(TL().faceScale), _shader_card, _shader_shadow)
	c.tpos = pos
	c.position = pos
	cards[key] = c
	return c


func remove_card(key: String) -> void:
	var c: Card3D = cards.get(key)
	cards.erase(key)
	if c != null:
		c.free_all()


## 화면 밖으로 밀어내며 사라짐(처리된 카드 — "툭 밀려남")
func push_out(key: String, dir := Vector3(0.9, 0, -0.35), ms := 300.0) -> void:
	var c: Card3D = cards.get(key)
	if c == null:
		return
	cards.erase(key)
	c.dying = true
	c.pinned = true
	var p0 := c.position
	var a := FX.anim(ms, [{"k": 0.0}, {"k": 1.0}], func(v):
		if is_instance_valid(c):
			c.position = p0 + dir * v.k + Vector3(0, 0.15 * sin(v.k * PI), 0)
			c.set_alpha(1.0 - v.k), {"node": c, "easing": "ease-in"})
	a.finished.connect(func(): if is_instance_valid(c): c.free_all())


func clear_cards() -> void:
	for k in cards.keys():
		remove_card(k)


# ───────── 카드 한 장 (3D) ─────────
class Card3D extends Node3D:
	var key := ""
	var table: BoardTable
	var face := {}
	var mesh: MeshInstance3D
	var mat: ShaderMaterial
	var fvp: SubViewport
	var fctl: Control
	var shadow_mi: MeshInstance3D
	var smat: ShaderMaterial
	var tpos := Vector3.ZERO     # 놓일 자리
	var tyaw := 0.0
	var tlift := 0.0             # 들린 높이(목표)
	var ttilt := 0.0             # 기울기(목표, 먼 쪽이 들림 +)
	var tflip := 0.0             # 0 앞면 · 1 뒷면
	var lift := 0.0
	var tilt := 0.0
	var flip := 0.0
	var yaw := 0.0
	var wobble := 0.0            # 노려진 동료: 흔들림 세기
	var pinned := false          # 연출이 직접 움직이는 중(따라가기 멈춤)
	var dying := false
	var pickable := true
	var prio := 0
	var _alpha := 1.0
	var _t := 0.0
	var _glow := 0.0
	var tglow := 0.0
	var glow_color := Color(1, 0.78, 0.38)
	var csize := Vector2(BoardTable.TL().card[0], BoardTable.TL().card[1])   # 카드 크기(탁자 단위)

	func setup(f: Dictionary, back: Texture2D, fs: float, shader: Shader, sh_shader: Shader) -> void:
		face = f
		_t = randf() * 10.0
		fvp = SubViewport.new()
		var c0: Array = BoardTable.TL().card
		fvp.size = Vector2i(int(BoardPieces.CW * fs * csize.x / float(c0[0])), int(BoardPieces.CH * fs * csize.y / float(c0[1])))
		fvp.transparent_bg = true
		fvp.disable_3d = true
		fvp.render_target_update_mode = SubViewport.UPDATE_ONCE
		fvp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(fvp)
		fctl = Control.new()
		fctl.size = Vector2(fvp.size)
		fctl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fctl.draw.connect(func(): BoardPieces.draw_face(fctl, Rect2(Vector2.ZERO, fctl.size), face))
		fvp.add_child(fctl)
		var cw: float = csize.x
		var ch: float = csize.y
		var m := 0.12
		mesh = MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(cw + 2 * m, ch + 2 * m)
		mesh.mesh = qm
		mesh.rotation = Vector3(-PI / 2.0, 0, 0)
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mat = ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("front", fvp.get_texture())
		mat.set_shader_parameter("back", back)
		mat.set_shader_parameter("margin", Vector2(m / (cw + 2 * m), m / (ch + 2 * m)))
		mesh.material_override = mat
		add_child(mesh)
		shadow_mi = MeshInstance3D.new()
		var sq := QuadMesh.new()
		sq.size = Vector2(cw + 0.3, ch + 0.3)
		shadow_mi.mesh = sq
		shadow_mi.rotation = Vector3(-PI / 2.0, 0, 0)
		smat = ShaderMaterial.new()
		smat.shader = sh_shader
		smat.render_priority = -100
		shadow_mi.material_override = smat
		table.world.add_child(shadow_mi)
		set_prio(0)

	func set_face(f: Dictionary) -> void:
		face = f
		if is_instance_valid(fctl):
			fctl.queue_redraw()
			fvp.render_target_update_mode = SubViewport.UPDATE_ONCE

	func set_back(t: Texture2D, tint := Color.WHITE) -> void:
		mat.set_shader_parameter("back", t)
		mat.set_shader_parameter("back_tint", tint)

	func set_prio(p: int) -> void:
		prio = p
		mat.render_priority = clampi(p, -90, 127)

	func set_alpha(a: float) -> void:
		_alpha = a
		mat.set_shader_parameter("alpha", a)

	func set_tint(c: Color) -> void:
		mat.set_shader_parameter("tint", c)

	func set_flash(v: float) -> void:
		mat.set_shader_parameter("flash", v)

	func set_glow(v: float, col := Color(1, 0.78, 0.38)) -> void:
		tglow = v
		glow_color = col
		mat.set_shader_parameter("glow_color", col)

	func _process(delta: float) -> void:
		_t += delta
		var k := 1.0 - exp(-delta * FX.speed / 0.075)
		if not pinned:
			lift = lerpf(lift, tlift, k)
			tilt = lerpf(tilt, ttilt, k)
			flip = lerpf(flip, tflip, k)
			yaw = lerp_angle(yaw, tyaw, k)
			var p := tpos + Vector3(0, lift, 0)
			if wobble > 0.0:
				p += Vector3(sin(_t * 9.0) * 0.025 * wobble, 0, 0)
			position = position.lerp(p, k) if position.distance_to(p) > 0.0005 else p
		var wr := sin(_t * 7.0) * 0.035 * wobble if wobble > 0.0 else 0.0
		basis = Basis(Vector3.UP, yaw + wr) * Basis(Vector3.RIGHT, tilt) * Basis(Vector3.BACK, flip * PI)
		_glow = move_toward(_glow, tglow, delta * FX.speed * 6.0)
		mat.set_shader_parameter("glow", _glow)
		# 그림자: 들릴수록 옅고 넓게, 빛(먼 쪽 위)의 반대인 앞쪽으로 조금
		if is_instance_valid(shadow_mi):
			var h := maxf(0.0, position.y)
			shadow_mi.visible = visible and _alpha > 0.02
			shadow_mi.position = Vector3(position.x + h * 0.12, 0.002, position.z + h * 0.3)
			shadow_mi.rotation = Vector3(-PI / 2.0, 0, 0)
			shadow_mi.rotate_y(yaw)
			var sc := 1.0 + h * 0.35
			shadow_mi.scale = Vector3(sc, 1, sc)
			smat.set_shader_parameter("strength", 0.55 * _alpha * clampf(1.0 - h * 0.9, 0.12, 1.0) * (1.0 - 0.5 * sin(clampf(flip, 0.0, 1.0) * PI)))

	## 탁자로 떨어진다(높이 from 에서, 살짝 튐)
	func drop_in(from := 0.9, ms := 320.0) -> void:
		pinned = true
		var p := tpos
		position = p + Vector3(0, from, 0)
		lift = 0.0
		tilt = 0.0
		var a := FX.anim(ms, [{"y": from, "t": 0.18}, {"y": 0.0, "t": 0.0, "o": 0.75}, {"y": 0.05, "t": 0.0, "o": 0.87}, {"y": 0.0, "t": 0.0}], func(v):
			if is_instance_valid(self):
				position = tpos + Vector3(0, v.y, 0)
				tilt = v.t, {"node": self, "easing": "ease-in"})
		await FX.until(a)
		if is_instance_valid(self):
			pinned = false

	## 뒤집기: 긴 축으로 돌아 face_up 쪽이 보이게(들렸다 떨어짐)
	func flip_to(face_up: bool, ms := 360.0) -> void:
		pinned = true
		var f0 := flip
		var f1 := 0.0 if face_up else 1.0
		var p0 := position
		var a := FX.anim(ms, [{"k": 0.0}, {"k": 1.0}], func(v):
			if is_instance_valid(self):
				flip = lerpf(f0, f1, v.k)
				position = p0.lerp(tpos, v.k) + Vector3(0, 0.45 * sin(v.k * PI), 0), {"node": self, "easing": "ease-in-out"})
		await FX.until(a)
		if is_instance_valid(self):
			flip = f1
			tflip = f1
			pinned = false

	## 뒤집어 다른 앞면으로(옆으로 선 순간 앞면을 바꾼다 — 죽은 동료 등)
	func flip_swap(f: Dictionary, ms := 420.0) -> void:
		pinned = true
		var p0 := tpos
		var swapped := [false]
		var a := FX.anim(ms, [{"k": 0.0}, {"k": 1.0}], func(v):
			if is_instance_valid(self):
				var k: float = v.k
				if k >= 0.5 and not swapped[0]:
					swapped[0] = true
					set_face(f)
				flip = k if k < 0.5 else k - 1.0
				position = p0 + Vector3(0, 0.5 * sin(k * PI), 0), {"node": self, "easing": "ease-in-out"})
		await FX.until(a)
		if is_instance_valid(self):
			flip = 0.0
			tflip = 0.0
			if not swapped[0]:
				set_face(f)
			pinned = false

	## 처리될 때: 살짝 들려 앞으로 툭
	func hop(dir := Vector3(0, 0, -0.25), ms := 260.0) -> void:
		pinned = true
		var p0 := tpos
		var a := FX.anim(ms, [{"k": 0.0}, {"k": 1.0, "o": 0.45}, {"k": 0.0}], func(v):
			if is_instance_valid(self):
				position = p0 + dir * v.k + Vector3(0, 0.3 * v.k, 0)
				tilt = 0.25 * v.k, {"node": self})
		await FX.until(a)
		if is_instance_valid(self):
			tilt = 0.0
			pinned = false

	## 맞음: 흔들림 + 붉게
	func hit_shake(power := 1.0) -> void:
		pinned = true
		var p0 := tpos
		var a := FX.anim(300, [{"x": 0.0, "f": 0.0}, {"x": 0.09 * power, "f": 1.0}, {"x": -0.07 * power, "f": 0.7}, {"x": 0.04 * power, "f": 0.3}, {"x": 0.0, "f": 0.0}], func(v):
			if is_instance_valid(self):
				position = p0 + Vector3(v.x, 0, 0)
				set_flash(v.f), {"node": self})
		await FX.until(a)
		if is_instance_valid(self):
			set_flash(0.0)
			pinned = false

	## 자리로 날아감(높이 arc 의 포물선)
	func fly_to(to: Vector3, ms := 380.0, arc := 0.6, face_up = null) -> void:
		pinned = true
		var p0 := position
		var f0 := flip
		var f1 := f0 if face_up == null else (0.0 if face_up else 1.0)
		var a := FX.anim(ms, [{"k": 0.0}, {"k": 1.0}], func(v):
			if is_instance_valid(self):
				position = p0.lerp(to, v.k) + Vector3(0, arc * sin(v.k * PI), 0)
				flip = lerpf(f0, f1, v.k), {"node": self, "easing": "ease-in-out"})
		await FX.until(a)
		if is_instance_valid(self):
			tpos = to
			flip = f1
			tflip = f1
			pinned = false

	func free_all() -> void:
		if is_instance_valid(shadow_mi):
			shadow_mi.queue_free()
		queue_free()
