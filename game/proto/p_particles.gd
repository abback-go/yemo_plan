class_name PParticles
extends PDraw.Canvas
## 훈련장 불티·불꽃·먼지를 한 노드에서 모두 움직이고 그리기 호출 1번으로 그린다.
## 예전에는 불티 한 번(때로는 입자 1개)마다 CPUParticles2D 노드를 하나씩 만들어 그리기 호출이 수십~수백 번 생겼다.
## 두 개가 있다: 가산(불·빛) / 보통(먼지·연기). PVfx.sparks·embers·dust가 이리로 보낸다.
## 입자 모양: 0 = 네모(불티), 1 = 속도 방향 줄(튀는 불꽃), 2 = 둥근 덩이(먼지·연기, 커지며 옅어짐),
##           3 = 제자리 속도선(대시 — vel이 방향·길이, 움직이지 않고 길어지며 사라짐)

const MAX := 900 ## 넘으면 새 입자를 버린다 (큰 마법이 겹쳐도 프레임이 무너지지 않게)

var pos := PackedVector2Array()
var vel := PackedVector2Array()
var grav := PackedVector2Array()
var age := PackedFloat32Array()
var life := PackedFloat32Array()
var size := PackedFloat32Array()
var drag := PackedFloat32Array()
var c0 := PackedColorArray()
var c1 := PackedColorArray()
var kind := PackedInt32Array()

static var _add_inst: PParticles
static var _norm_inst: PParticles


## 지금 장면의 가산(true)/보통(false) 입자 노드 (없으면 만든다)
static func get_layer(additive: bool) -> PParticles:
	var inst := _add_inst if additive else _norm_inst
	if is_instance_valid(inst) and inst.is_inside_tree():
		return inst
	inst = PParticles.new()
	inst.z_index = 8 if additive else 3
	if additive:
		inst.material = Fx.add_material
		_add_inst = inst
	else:
		_norm_inst = inst
	Fx.effect_parent().add_child(inst)
	return inst


func count() -> int:
	return pos.size()


## 입자 하나. col_end는 끝 색(알파는 따로 사라짐)
func spawn(p: Vector2, v: Vector2, g: Vector2, lifetime: float, sz: float, col: Color, col_end: Color, k := 0, drg := 0.0) -> void:
	if pos.size() >= MAX:
		return
	pos.append(p)
	vel.append(v)
	grav.append(g)
	age.append(0.0)
	life.append(maxf(lifetime, 0.01))
	size.append(sz)
	drag.append(drg)
	c0.append(col)
	c1.append(col_end)
	kind.append(k)


func _process(delta: float) -> void:
	var n := pos.size()
	if n == 0:
		if not pd.is_empty():
			queue_redraw()
		return
	var w := 0
	for i in n:
		var a := age[i] + delta
		if a >= life[i]:
			continue
		if kind[i] == 3:
			if w != i:
				pos[w] = pos[i]
				vel[w] = vel[i]
				grav[w] = grav[i]
				life[w] = life[i]
				size[w] = size[i]
				drag[w] = drag[i]
				c0[w] = c0[i]
				c1[w] = c1[i]
				kind[w] = 3
			age[w] = a
			w += 1
			continue
		var v := vel[i] + grav[i] * delta
		var dr := drag[i]
		if dr > 0.0:
			v *= maxf(1.0 - dr * delta, 0.0)
		var p := pos[i] + v * delta
		if w != i:
			pos[w] = p
			vel[w] = v
			grav[w] = grav[i]
			age[w] = a
			life[w] = life[i]
			size[w] = size[i]
			drag[w] = dr
			c0[w] = c0[i]
			c1[w] = c1[i]
			kind[w] = kind[i]
		else:
			pos[i] = p
			vel[i] = v
			age[i] = a
		w += 1
	if w != n:
		pos.resize(w)
		vel.resize(w)
		grav.resize(w)
		age.resize(w)
		life.resize(w)
		size.resize(w)
		drag.resize(w)
		c0.resize(w)
		c1.resize(w)
		kind.resize(w)
	queue_redraw()


func _paint() -> void:
	for i in pos.size():
		var k := age[i] / life[i]
		var col := c0[i].lerp(c1[i], k)
		var p := pos[i]
		match kind[i]:
			0:
				col.a *= 1.0 - k * k
				var s := size[i] * (1.0 - k * 0.6)
				pd.draw_rect(Rect2(p.x - s * 0.5, p.y - s * 0.5, s, s), col)
			1:
				col.a *= 1.0 - k
				var v := vel[i]
				var tail := v * 0.028
				if tail.length_squared() < 4.0:
					tail = v.normalized() * 2.0
				pd.draw_line(p - tail, p, col, size[i] * (1.0 - k * 0.5))
			2:
				col.a *= (1.0 - k) * minf(k * 6.0, 1.0)
				pd.draw_circle(p, size[i] * (0.6 + k * 0.9), col)
			_:
				col.a *= 1.0 - k
				pd.draw_line(p, p + vel[i] * (0.5 + k), col, size[i])
