class_name H3Castle
extends RefCounted
## 마녀성 시안의 큰 구조물 (2026-10-23 사용자 성 그림 참고): 성 본체(고딕 첨탑 · 불 켜진 창 · 큰 스테인드글라스 · 성문 ·
## 탑 사이 다리) · 떠 있는 섬 · 보라 밤하늘(달 · 소용돌이 · 구름) · 구름 바다 · 먼 구름 덩어리 · 비룡 그림자.
## 기하 도우미는 SurfaceTool에 면을 더한다 (재질마다 메시 하나로 묶어 그리기 호출을 줄임).

# ─── 기하 도우미 ─────────────────────────────────────

## 사각 면 a-b(위) · d-c(아래). uv는 a,b,c,d 순
static func quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2) -> void:
	var n := (b - a).cross(d - a).normalized()
	st.set_normal(n)
	st.set_uv(ua); st.add_vertex(a)
	st.set_uv(ub); st.add_vertex(b)
	st.set_uv(uc); st.add_vertex(c)
	st.set_uv(ua); st.add_vertex(a)
	st.set_uv(uc); st.add_vertex(c)
	st.set_uv(ud); st.add_vertex(d)


static func tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ua: Vector2, ub: Vector2, uc: Vector2) -> void:
	st.set_normal((b - a).cross(c - a).normalized())
	st.set_uv(ua); st.add_vertex(a)
	st.set_uv(ub); st.add_vertex(b)
	st.set_uv(uc); st.add_vertex(c)


## 상자 (가운데 · 크기 · Y축 회전). uvs = 그림 한 장이 덮는 세계 크기 (가로, 세로)
static func box(st: SurfaceTool, c: Vector3, s: Vector3, rot := 0.0, uvs := Vector2(2, 2)) -> void:
	var bs := Basis(Vector3.UP, rot)
	var h := s * 0.5
	var p := func(x: float, y: float, z: float) -> Vector3: return c + bs * Vector3(x * h.x, y * h.y, z * h.z)
	var faces := [
		[p.call(-1, 1, 1), p.call(1, 1, 1), p.call(1, -1, 1), p.call(-1, -1, 1), s.x, s.y],
		[p.call(1, 1, -1), p.call(-1, 1, -1), p.call(-1, -1, -1), p.call(1, -1, -1), s.x, s.y],
		[p.call(1, 1, 1), p.call(1, 1, -1), p.call(1, -1, -1), p.call(1, -1, 1), s.z, s.y],
		[p.call(-1, 1, -1), p.call(-1, 1, 1), p.call(-1, -1, 1), p.call(-1, -1, -1), s.z, s.y],
		[p.call(-1, 1, -1), p.call(1, 1, -1), p.call(1, 1, 1), p.call(-1, 1, 1), s.x, s.z],
		[p.call(-1, -1, 1), p.call(1, -1, 1), p.call(1, -1, -1), p.call(-1, -1, -1), s.x, s.z],
	]
	for f: Array in faces:
		var uw: float = float(f[4]) / uvs.x
		var vh: float = float(f[5]) / uvs.y
		quad(st, f[0], f[1], f[2], f[3], Vector2(0, 0), Vector2(uw, 0), Vector2(uw, vh), Vector2(0, vh))


## 기둥 (n각 · 바닥 가운데 · 반지름 · 높이). 벽 그림이 세로로 서게 v는 위에서 아래로
static func prism(st: SurfaceTool, base: Vector3, r: float, h: float, n: int, uvs: Vector2, cap := true) -> void:
	var per := TAU * r / float(n)
	for i in n:
		var a0 := TAU * float(i) / float(n)
		var a1 := TAU * float(i + 1) / float(n)
		var p0 := base + Vector3(cos(a0) * r, 0, sin(a0) * r)
		var p1 := base + Vector3(cos(a1) * r, 0, sin(a1) * r)
		var u0 := float(i) * per / uvs.x
		var u1 := float(i + 1) * per / uvs.x
		quad(st, p1 + Vector3(0, h, 0), p0 + Vector3(0, h, 0), p0, p1, Vector2(u1, 0), Vector2(u0, 0), Vector2(u0, h / uvs.y), Vector2(u1, h / uvs.y))
		if cap:
			tri(st, base + Vector3(0, h, 0), p0 + Vector3(0, h, 0), p1 + Vector3(0, h, 0), Vector2(0.5, 0.5), Vector2(0, 0), Vector2(1, 0))


## 첨탑 지붕 (n각뿔)
static func cone(st: SurfaceTool, base: Vector3, r: float, h: float, n: int, uvs: Vector2) -> void:
	var tip := base + Vector3(0, h, 0)
	var sl := sqrt(h * h + r * r)
	var per := TAU * r / float(n)
	for i in n:
		var a0 := TAU * float(i) / float(n)
		var a1 := TAU * float(i + 1) / float(n)
		var p0 := base + Vector3(cos(a0) * r, 0, sin(a0) * r)
		var p1 := base + Vector3(cos(a1) * r, 0, sin(a1) * r)
		tri(st, tip, p0, p1, Vector2((float(i) + 0.5) * per / uvs.x, 0), Vector2(float(i) * per / uvs.x, sl / uvs.y), Vector2(float(i + 1) * per / uvs.x, sl / uvs.y))


## 거꾸로 선 바위 뿔 (떠 있는 섬 밑). 아래 꼭짓점은 살짝 비켜 남
static func inv_cone(st: SurfaceTool, top: Vector3, r: float, h: float, n: int, uvs: Vector2, rng: RandomNumberGenerator) -> void:
	var tip := top + Vector3(rng.randf_range(-r, r) * 0.2, -h, rng.randf_range(-r, r) * 0.2)
	var per := TAU * r / float(n)
	var rs: Array = []
	for i in n:
		rs.append(r * rng.randf_range(0.82, 1.08))
	for i in n:
		var j := (i + 1) % n
		var a0 := TAU * float(i) / float(n)
		var a1 := TAU * float(j) / float(n)
		var p0 := top + Vector3(cos(a0) * float(rs[i]), 0, sin(a0) * float(rs[i]))
		var p1 := top + Vector3(cos(a1) * float(rs[j]), 0, sin(a1) * float(rs[j]))
		var mid0 := p0.lerp(tip, 0.45) + Vector3(cos(a0), 0, sin(a0)) * r * 0.12
		var mid1 := p1.lerp(tip, 0.45) + Vector3(cos(a1), 0, sin(a1)) * r * 0.12
		var u0 := float(i) * per / uvs.x
		var u1 := float(i + 1) * per / uvs.x
		quad(st, p1, p0, mid0, mid1, Vector2(u1, 0), Vector2(u0, 0), Vector2(u0, h * 0.45 / uvs.y), Vector2(u1, h * 0.45 / uvs.y))
		tri(st, mid1, mid0, tip, Vector2(u1, h * 0.45 / uvs.y), Vector2(u0, h * 0.45 / uvs.y), Vector2((u0 + u1) * 0.5, h / uvs.y))


static func mat(tex: Texture2D, em: Texture2D = null, energy := 1.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 1.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	if em != null:
		m.emission_enabled = true
		m.emission_texture = em
		m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY # 기본(ADD)은 발광색이 텍스처에 더해져 벽 전체가 빛남
		m.emission = Color(1, 1, 1)
		m.emission_energy_multiplier = energy
	return m


static func commit(root: Node3D, st: SurfaceTool, m: Material, shadow := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	return mi


static func new_st() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


# ─── 성 ─────────────────────────────────────────────

const WALL_UV := Vector2(8, 12) ## 성벽 그림 한 장 = 8×12칸 (castle_wall 256×384)
const ROOF_UV := Vector2(1, 2)
const TRIM_UV := Vector2(2, 2)

## 탑: 몸통 · 난간 고리 · 첨탑 · 작은 첨탑 넷
static func _tower(sw: SurfaceTool, sr: SurfaceTool, stt: SurfaceTool, base: Vector3, r: float, h: float, spire: float, n := 8) -> void:
	prism(sw, base, r, h, n, WALL_UV, false)
	prism(stt, base + Vector3(0, h, 0), r * 1.15, 0.7, n, TRIM_UV)
	cone(sr, base + Vector3(0, h + 0.7, 0), r * 1.05, spire, n, ROOF_UV)
	if r > 1.3:
		for k in 4:
			var a := TAU * (float(k) + 0.5) / 4.0
			var pp := base + Vector3(cos(a) * r * 1.05, h + 0.7, sin(a) * r * 1.05)
			prism(stt, pp, 0.22, 0.8, 4, TRIM_UV)
			cone(sr, pp + Vector3(0, 0.8, 0), 0.28, spire * 0.32, 4, ROOF_UV)


## 박공지붕 (긴 쪽이 x)
static func _roof(sr: SurfaceTool, c: Vector3, w: float, d: float, h: float) -> void:
	var x0 := c.x - w * 0.5
	var x1 := c.x + w * 0.5
	var z0 := c.z - d * 0.5
	var z1 := c.z + d * 0.5
	var ridge := c.y + h
	var sl := sqrt(h * h + d * d * 0.25)
	quad(sr, Vector3(x0, ridge, c.z), Vector3(x1, ridge, c.z), Vector3(x1, c.y, z1), Vector3(x0, c.y, z1), Vector2(0, 0), Vector2(w / ROOF_UV.x, 0), Vector2(w / ROOF_UV.x, sl / ROOF_UV.y), Vector2(0, sl / ROOF_UV.y))
	quad(sr, Vector3(x1, ridge, c.z), Vector3(x0, ridge, c.z), Vector3(x0, c.y, z0), Vector3(x1, c.y, z0), Vector2(0, 0), Vector2(w / ROOF_UV.x, 0), Vector2(w / ROOF_UV.x, sl / ROOF_UV.y), Vector2(0, sl / ROOF_UV.y))
	tri(sr, Vector3(x0, ridge, c.z), Vector3(x0, c.y, z1), Vector3(x0, c.y, z0), Vector2(0.5, 0), Vector2(0, 1), Vector2(1, 1))
	tri(sr, Vector3(x1, ridge, c.z), Vector3(x1, c.y, z0), Vector3(x1, c.y, z1), Vector2(0.5, 0), Vector2(0, 1), Vector2(1, 1))


## 성 본체. c = 성 가운데 바닥 (광장 높이). 돌려주는 것 = 성문 쇠창살 (위 가운데가 원점 — scale.y를 줄이면 올라가 열림)
static func build_castle(root: Node3D, c: Vector3) -> MeshInstance3D:
	var cw: Array = H3Art.castle_wall()
	var sw := new_st()
	var sr := new_st()
	var stt := new_st()
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	# 앞 성벽 (z = c.z + 9) + 톱니 + 문탑 둘
	var fz := c.z + 9.0
	box(sw, Vector3(c.x, c.y + 3.5, fz), Vector3(26, 7, 2), 0.0, WALL_UV)
	for k in 13:
		box(stt, Vector3(c.x - 12.0 + float(k) * 2.0, c.y + 7.4, fz + 0.6), Vector3(1.0, 0.8, 0.8), 0.0, TRIM_UV)
	_tower(sw, sr, stt, Vector3(c.x - 3.2, c.y, fz + 0.4), 1.5, 11.0, 6.0)
	_tower(sw, sr, stt, Vector3(c.x + 3.2, c.y, fz + 0.4), 1.5, 11.0, 6.0)
	_tower(sw, sr, stt, Vector3(c.x - 13.5, c.y, fz), 1.7, 13.0, 7.0)
	_tower(sw, sr, stt, Vector3(c.x + 13.5, c.y, fz), 1.7, 14.0, 7.0)
	# 본관 (큰 창이 난 높은 집) + 박공지붕 + 앞 꼭대기 작은 첨탑 줄
	var kz := c.z + 1.0
	box(sw, Vector3(c.x, c.y + 12.0, kz), Vector3(14, 24, 12), 0.0, WALL_UV)
	_roof(sr, Vector3(c.x, c.y + 24.0, kz), 14.0, 12.0, 7.0)
	for k in 7:
		var px := c.x - 6.5 + float(k) * (13.0 / 6.0)
		prism(stt, Vector3(px, c.y + 24.0, kz + 6.0), 0.3, 1.2, 4, TRIM_UV)
		cone(sr, Vector3(px, c.y + 25.2, kz + 6.0), 0.36, 3.0, 4, ROOF_UV)
	# 본관 앞 높은 쌍탑
	_tower(sw, sr, stt, Vector3(c.x - 8.2, c.y, kz + 5.0), 2.4, 30.0, 13.0)
	_tower(sw, sr, stt, Vector3(c.x + 8.2, c.y, kz + 5.0), 2.4, 32.0, 14.0)
	# 가운데 가장 높은 탑 (본관 뒤)
	_tower(sw, sr, stt, Vector3(c.x, c.y, kz - 8.0), 3.0, 40.0, 18.0)
	# 둘레 탑들
	var ring := [[-14, -6, 1.8, 20, 8], [14, -7, 1.8, 22, 9], [-11, -16, 2.0, 27, 11], [12, -17, 2.0, 29, 11],
		[-4, -20, 1.7, 33, 12], [6, -21, 1.6, 31, 12], [-19, 2, 1.3, 15, 6], [19, 1, 1.3, 16, 6],
		[-20, -12, 1.4, 18, 7], [21, -13, 1.4, 19, 7], [0, -27, 1.8, 26, 10]]
	for t: Array in ring:
		_tower(sw, sr, stt, Vector3(c.x + float(t[0]), c.y, kz + float(t[1])), float(t[2]), float(t[3]), float(t[4]))
	# 둘레 낮은 건물
	box(sw, Vector3(c.x - 14, c.y + 5, kz - 10), Vector3(8, 10, 10), 0.2, WALL_UV)
	box(sw, Vector3(c.x + 14, c.y + 6, kz - 11), Vector3(8, 12, 10), -0.2, WALL_UV)
	_roof(sr, Vector3(c.x - 14, c.y + 10, kz - 10), 8.0, 10.0, 4.0)
	_roof(sr, Vector3(c.x + 14, c.y + 12, kz - 11), 8.0, 10.0, 4.0)
	box(sw, Vector3(c.x, c.y + 8, kz - 16), Vector3(18, 16, 8), 0.0, WALL_UV)
	# 탑 사이 하늘다리 (아래 아치 띠)
	var sa := new_st()
	var bridges := [[Vector3(c.x - 8.2, c.y + 18, kz + 5), Vector3(c.x - 14, c.y + 18, kz - 6)],
		[Vector3(c.x + 8.2, c.y + 20, kz + 5), Vector3(c.x + 14, c.y + 20, kz - 7)],
		[Vector3(c.x - 8.2, c.y + 26, kz + 5), Vector3(c.x, c.y + 26, kz - 8)],
		[Vector3(c.x + 14, c.y + 12, kz - 7), Vector3(c.x + 30, c.y + 9, kz - 2)]]
	for b: Array in bridges:
		var a: Vector3 = b[0]
		var e: Vector3 = b[1]
		var mid := (a + e) * 0.5
		var blen := Vector2(e.x - a.x, e.z - a.z).length()
		var rot := -atan2(e.z - a.z, e.x - a.x)
		box(stt, mid, Vector3(blen, 0.8, 1.4), rot, TRIM_UV)
		var dir := Vector3(e.x - a.x, 0, e.z - a.z).normalized()
		var side := dir.cross(Vector3.UP) * 0.7
		for sgn in [-1.0, 1.0]:
			var o: Vector3 = side * float(sgn)
			var p0 := Vector3(a.x, a.y - 0.4, a.z) + o
			var p1 := Vector3(e.x, e.y - 0.4, e.z) + o
			quad(sa, p0, p1, p1 + Vector3(0, -2.0, 0), p0 + Vector3(0, -2.0, 0), Vector2(0, 0), Vector2(blen / 4.0, 0), Vector2(blen / 4.0, 1), Vector2(0, 1))
	# 오른쪽 멀리 외딴 탑 (하늘다리 끝)
	_tower(sw, sr, stt, Vector3(c.x + 31, c.y - 4, kz - 2), 1.8, 17.0, 8.0)
	var lone := new_st()
	inv_cone(lone, Vector3(c.x + 31, c.y - 4, kz - 2), 3.2, 9.0, 7, TRIM_UV, rng)
	commit(root, lone, mat(H3Art.cliff()))
	commit(root, sw, mat(cw[0], cw[1], 2.2))
	commit(root, sr, mat(H3Art.slate()))
	commit(root, stt, mat(H3Art.masonry()))
	var am := mat(H3Art.arch_band())
	am.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	commit(root, sa, am)
	# 큰 스테인드글라스 (본관 앞면) · 쌍탑 사이 작은 창들
	var sg: Array = H3Art.stained()
	var gl := new_st()
	var gz := kz + 6.05
	quad(gl, Vector3(c.x - 3.0, c.y + 22.0, gz), Vector3(c.x + 3.0, c.y + 22.0, gz), Vector3(c.x + 3.0, c.y + 7.0, gz), Vector3(c.x - 3.0, c.y + 7.0, gz), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
	for sx in [-1.0, 1.0]:
		var gx := c.x + float(sx) * 8.2
		var tz := kz + 5.0 + 2.45
		quad(gl, Vector3(gx - 0.9, c.y + 24.0, tz), Vector3(gx + 0.9, c.y + 24.0, tz), Vector3(gx + 0.9, c.y + 18.5, tz), Vector3(gx - 0.9, c.y + 18.5, tz), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
	var gm := mat(sg[0], sg[1], 3.2)
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	commit(root, gl, gm, false)
	# 성문: 안쪽 불빛(문간) + 그 앞 쇠창살 (열리면 위로 감김)
	var dz := fz + 1.05
	var door := new_st()
	quad(door, Vector3(c.x - 1.6, c.y + 4.6, dz - 0.03), Vector3(c.x + 1.6, c.y + 4.6, dz - 0.03), Vector3(c.x + 1.6, c.y, dz - 0.03), Vector3(c.x - 1.6, c.y, dz - 0.03), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
	var dm := mat(H3Art.gate(false), H3Art.gate(false), 2.6) # 성 안 불빛
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	commit(root, door, dm, false)
	var gt := new_st()
	quad(gt, Vector3(-1.6, 0, 0), Vector3(1.6, 0, 0), Vector3(1.6, -4.6, 0), Vector3(-1.6, -4.6, 0), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
	var gtm := mat(H3Art.gate(true))
	gtm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	var gate := commit(root, gt, gtm, false)
	gate.position = Vector3(c.x, c.y + 4.6, dz)
	return gate


# ─── 떠 있는 섬 ─────────────────────────────────────

## 섬 하나: 거꾸로 선 바위 · 이끼 윗면 · 작은 첨탑들
static func _island(srock: SurfaceTool, stop: SurfaceTool, sw: SurfaceTool, sr: SurfaceTool, stt: SurfaceTool, p: Vector3, size: float, towers: int, rng: RandomNumberGenerator) -> void:
	var n := 7
	prism(srock, p + Vector3(0, -size * 0.25, 0), size, size * 0.25, n, TRIM_UV, false)
	inv_cone(srock, p + Vector3(0, -size * 0.25, 0), size, size * 1.7, n, TRIM_UV, rng)
	for i in n: # 윗면 (이끼)
		var a0 := TAU * float(i) / float(n)
		var a1 := TAU * float(i + 1) / float(n)
		tri(stop, p, p + Vector3(cos(a1), 0, sin(a1)) * size, p + Vector3(cos(a0), 0, sin(a0)) * size, Vector2(0.5, 0.5), Vector2(0.5 + cos(a1) * 0.5, 0.5 + sin(a1) * 0.5), Vector2(0.5 + cos(a0) * 0.5, 0.5 + sin(a0) * 0.5))
	for k in towers:
		var a := rng.randf() * TAU
		var d := rng.randf_range(0.0, size * 0.45)
		var tp := p + Vector3(cos(a) * d, 0, sin(a) * d)
		var r := rng.randf_range(0.35, 0.7) * clampf(size / 5.0, 0.6, 1.6)
		var h := rng.randf_range(3.0, 7.0) * clampf(size / 5.0, 0.6, 1.8)
		prism(sw, tp, r, h, 6, WALL_UV, false)
		prism(stt, tp + Vector3(0, h, 0), r * 1.15, 0.4, 6, TRIM_UV)
		cone(sr, tp + Vector3(0, h + 0.4, 0), r * 1.05, h * 0.55, 6, ROOF_UV)


static func build_islands(root: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var srock := new_st()
	var stop := new_st()
	var sw := new_st()
	var sr := new_st()
	var stt := new_st()
	# [자리, 크기, 탑 수] — 그림처럼 왼쪽 위 · 오른쪽에 성 붙은 섬, 멀리 작은 바위
	var specs := [[Vector3(-14, 9, -20), 6.5, 4], [Vector3(-26, 18, -48), 5.0, 3], [Vector3(-4, 22, -70), 4.0, 2],
		[Vector3(74, 12, -30), 5.5, 3], [Vector3(82, 4, 4), 3.5, 2], [Vector3(66, 24, -64), 4.0, 2],
		[Vector3(-30, 4, 14), 3.5, 1], [Vector3(14, 30, -96), 6.0, 4], [Vector3(96, 20, -10), 3.0, 1]]
	for sp: Array in specs:
		_island(srock, stop, sw, sr, stt, sp[0], float(sp[1]), int(sp[2]), rng)
	for i in 14: # 작은 떠 있는 바위
		var p := Vector3(rng.randf_range(-30, 100), rng.randf_range(-4, 26), rng.randf_range(-80, 40))
		if p.x > 0 and p.x < 66 and p.z > -40 and p.z < 46:
			continue
		var s := rng.randf_range(0.6, 1.6)
		inv_cone(srock, p, s, s * 1.8, 5, TRIM_UV, rng)
		prism(srock, p, s, s * 0.3, 5, TRIM_UV)
	var cw: Array = H3Art.castle_wall()
	commit(root, srock, mat(H3Art.cliff()))
	commit(root, stop, mat(H3Art.moss()))
	commit(root, sw, mat(cw[0], cw[1], 2.2))
	commit(root, sr, mat(H3Art.slate()))
	commit(root, stt, mat(H3Art.masonry()))


# ─── 하늘 · 구름 ────────────────────────────────────

const SKY_CODE := """
shader_type sky;
uniform vec3 moon_dir = vec3(0.861, 0.156, -0.484); // 시작 시점에서 성 오른쪽 낮게 (게임 시점은 하늘이 지평선 위 10°쯤만 보임)
uniform vec3 vortex_dir = vec3(0.08, 0.139, -0.987); // 시작 시점에서 성 왼쪽 위
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) { float v = 0.0; float a = 0.5; for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.03; a *= 0.5; } return v; }
void sky() {
	vec3 d = normalize(EYEDIR);
	float h = d.y;
	vec3 top = vec3(0.07, 0.05, 0.19), mid = vec3(0.30, 0.20, 0.50), hor = vec3(0.78, 0.55, 0.72), low = vec3(0.34, 0.26, 0.50);
	vec3 c = mix(hor, mid, smoothstep(0.0, 0.28, h));
	c = mix(c, top, smoothstep(0.28, 0.85, h));
	if (h < 0.0) c = mix(hor, low, smoothstep(0.0, 0.25, -h));
	// 별
	if (h > 0.25 && hash(floor(d.xz / (h + 0.3) * 260.0)) > 0.9965) c += vec3(0.8, 0.75, 0.95) * smoothstep(0.25, 0.6, h);
	// 구름 (지평선 위 띠, 달 쪽이 밝음)
	vec2 cuv = d.xz / (abs(h) + 0.12);
	float n = fbm(cuv * 0.9 + vec2(TIME * 0.004, 0.0));
	float band = smoothstep(-0.02, 0.12, h) * (1.0 - smoothstep(0.3, 0.65, h));
	float lit = clamp(dot(d, normalize(moon_dir)) * 0.5 + 0.5, 0.0, 1.0);
	float q = floor(n * 6.0) / 6.0;
	if (q > 0.5) {
		vec3 cc = mix(vec3(0.42, 0.30, 0.58), vec3(0.96, 0.80, 0.90), clamp((q - 0.5) * 2.2 * lit + 0.15, 0.0, 1.0));
		c = mix(c, cc, band * 0.92);
	}
	// 달
	vec3 md = normalize(moon_dir);
	float ang = acos(clamp(dot(d, md), -1.0, 1.0));
	c += vec3(0.55, 0.38, 0.75) * exp(-ang * 7.0) * 0.55;
	if (ang < 0.09) {
		vec3 t1 = normalize(cross(md, vec3(0, 1, 0))); vec3 t2 = cross(t1, md);
		vec2 mp = vec2(dot(d, t1), dot(d, t2)) / 0.09;
		float cr = fbm(mp * 3.0 + 7.0);
		vec3 mc = mix(vec3(0.95, 0.88, 1.0), vec3(0.72, 0.62, 0.86), smoothstep(0.45, 0.75, cr));
		mc *= 1.0 - 0.25 * smoothstep(0.6, 1.0, length(mp));
		c = mc;
	}
	// 보라 소용돌이 (왼쪽 위)
	vec3 vd = normalize(vortex_dir);
	vec3 v1 = normalize(cross(vd, vec3(0, 1, 0))); vec3 v2 = cross(v1, vd);
	vec2 vp = vec2(dot(d, v1), dot(d, v2));
	float vr = length(vp);
	if (dot(d, vd) > 0.0 && vr < 0.3) {
		float va = atan(vp.y, vp.x);
		float sp = sin(va * 2.0 + log(vr + 0.002) * 7.0 + TIME * 0.5);
		float k = 1.0 - smoothstep(0.06, 0.3, vr);
		c = mix(c, vec3(0.10, 0.05, 0.20), k * 0.75);
		if (sp > 0.25) c += vec3(0.55, 0.22, 0.95) * k * (0.6 + 0.4 * sp);
		c += vec3(0.85, 0.6, 1.0) * (1.0 - smoothstep(0.0, 0.03, vr));
	}
	// 소용돌이 가운데에서 아래로 떨어지는 빛기둥
	vec2 hz = normalize(d.xz);
	vec2 hv = normalize(vd.xz);
	float da = acos(clamp(dot(hz, hv), -1.0, 1.0));
	if (d.y < vd.y && d.y > -0.05 && da < 0.03) {
		float bk = (1.0 - da / 0.03) * smoothstep(-0.05, 0.02, d.y);
		c += vec3(0.62, 0.36, 1.0) * bk * (0.7 + 0.3 * sin(TIME * 3.0 + d.y * 80.0));
	}
	COLOR = c;
}
"""


static func sky_env(env: Environment) -> void:
	var sm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SKY_CODE
	sm.shader = sh
	var sky := Sky.new()
	sky.sky_material = sm
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	env.background_mode = Environment.BG_SKY
	env.sky = sky


const CLOUD_SEA := """
shader_type spatial;
render_mode unshaded, cull_disabled;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) { float v = 0.0; float a = 0.5; for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.07; a *= 0.5; } return v; }
void fragment() {
	vec2 p = floor(wp.xz * 3.0) / 3.0;
	float n = fbm(p * 0.07 + vec2(TIME * 0.012, TIME * 0.007));
	float n2 = fbm(p * 0.07 + vec2(0.04, 0.05) + vec2(TIME * 0.012, TIME * 0.007));
	float lit = clamp((n - n2) * 6.0 + 0.5, 0.0, 1.0);
	vec3 c = vec3(0.22, 0.15, 0.40);
	if (n > 0.42) c = vec3(0.42, 0.29, 0.64);
	if (n > 0.52) c = mix(vec3(0.60, 0.42, 0.76), vec3(0.86, 0.66, 0.88), step(0.55, lit));
	if (n > 0.62 && lit > 0.6) c = vec3(0.97, 0.84, 0.94);
	ALBEDO = c;
}
"""


static func build_clouds(root: Node3D, sea_y: float, near: Array) -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(900, 900)
	pm.subdivide_width = 0
	var sm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = CLOUD_SEA
	sm.shader = sh
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	mi.material_override = sm
	mi.position = Vector3(30, sea_y, -20)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	# 섬·다리 밑을 감싸는 구름 덩어리 (near = 감쌀 자리들) + 하늘 높이 뜬 구름
	for p: Vector3 in near:
		for k in 3:
			_cloud_sprite(root, p + Vector3(rng.randf_range(-6, 6), rng.randf_range(-1.5, 2.5), rng.randf_range(-4, 4)), rng.randf_range(0.18, 0.3), rng)
	for i in 26:
		var p := Vector3(rng.randf_range(-60, 120), rng.randf_range(sea_y + 1.0, sea_y + 6.0), rng.randf_range(-120, 50))
		_cloud_sprite(root, p, rng.randf_range(0.3, 0.6), rng)
	for i in 10:
		var p := Vector3(rng.randf_range(-50, 110), rng.randf_range(14, 40), rng.randf_range(-130, -60))
		if p.x > -25.0 and p.x < 45.0:
			p.x += 70.0 # 시작 시점에서 소용돌이(성 왼쪽 위)를 가리지 않게 비킴
		_cloud_sprite(root, p, rng.randf_range(0.5, 0.9), rng)


static func _cloud_sprite(root: Node3D, p: Vector3, px: float, rng: RandomNumberGenerator) -> void:
	var s := Sprite3D.new()
	s.texture = H3Art.cloud(rng.randi_range(0, 3))
	s.pixel_size = px
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.shaded = false
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	s.flip_h = rng.randf() < 0.5
	s.position = p
	root.add_child(s)


## 먼 하늘을 도는 비룡 그림자. 매 프레임 fly()로 움직인다
static func build_dragons(root: Node3D, center: Vector3) -> Array:
	var out: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 3:
		var s := Sprite3D.new()
		s.texture = H3Art.dragon()
		s.hframes = 2
		s.pixel_size = rng.randf_range(0.09, 0.14)
		s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		s.shaded = false
		s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		s.set_meta("orbit", Vector4(center.x, center.z, rng.randf_range(34.0, 52.0), rng.randf_range(12.0, 20.0))) # 높이: 게임 시점 하늘 띠 안
		s.set_meta("phase", rng.randf() * TAU)
		s.set_meta("speed", rng.randf_range(0.05, 0.09) * (1.0 if i % 2 == 0 else -1.0))
		root.add_child(s)
		out.append(s)
	return out


static func fly(dragons: Array, t: float) -> void:
	for s: Sprite3D in dragons:
		var o: Vector4 = s.get_meta("orbit")
		var a: float = float(s.get_meta("phase")) + t * float(s.get_meta("speed"))
		s.position = Vector3(o.x + cos(a) * o.z, o.w + sin(t * 0.7 + a) * 2.0, o.y + sin(a) * o.z * 0.6)
		s.frame = int(t * 5.0 + a * 3.0) % 2
		s.flip_h = float(s.get_meta("speed")) < 0.0
