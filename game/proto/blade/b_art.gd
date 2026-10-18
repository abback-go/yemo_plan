class_name BArt
extends EArt
## 빗자루 검 데모의 에스카 그림: EArt(몸·머리칼·옷) 위에 빗자루 / 검을 그린다.
## 빗자루: 검은 자루 + 보라 구슬 끝 + 흰 솔(보라 띠로 묶음). 검: 먹 테두리의 가는 흰 날 + 보랏빛 홈 + 날밑의 보라 구슬,
## 칼자루 끝에 흰 술 두 가닥(빗자루 솔의 흔적). 모드가 바뀌는 동안(BEska.morph)엔 솔이 줄어들며 날이 뻗는다.
## 휘두를 땐 BEska가 정한 손 자리·무기 방향을 그대로 쓴다(3프레임 휘두름을 부드럽게 따라가면 늦으므로). 그 밖엔 자세별 방향으로 부드럽게.
## 무기 방향 벡터의 길이 = 원근으로 줄어든 비율 (납작한 가로 휘두름에서 칼이 앞·뒤로 갈 때 짧아 보임).

const BROOM_UP := 14.0 ## 손 위로 나온 자루
const BROOM_DOWN := 12.0 ## 손 아래 자루 (끝에 솔)
const BRISTLE := 7.0
const BLADE_LEN := 25.0
const GRIP := 3.5
const HANDLE := Color("#3a3046")
const HANDLE_HI := Color("#6b5a86")
const BRISTLE_COL := Color("#d8d2e6")
const STEEL := Color("#e9e4f2")
const BROOM_FLOAT := Vector2(-7.0, -17.0) ## 흑백 균열을 모을 때 빗자루가 등 뒤에 떠 있는 자리 (자루 가운데)
const BROOM_FLOAT_ANGLE := 2.05

var _vec := Vector2(-0.5, 0.86)
var _back_hand := Vector2(-1.5, -16.0) ## 흑백 균열을 모을 때 뒷손 (그림 좌표)


func kick_lean(v: float) -> void:
	_lean_v += v


func tick(delta: float) -> void:
	var b := body as BEska
	if b.pose_on:
		_hand = b.hand_local
	super.tick(delta)
	if delta <= 0.0:
		return
	var c := b.rift_charge()
	var want_back := Vector2(-1.5, -16.0)
	if b.act == "rift":
		var open := 1.0 - pow(1.0 - minf(maxf(c, 0.0) * 3.0, 1.0), 3.0) if c >= 0.0 else 1.0
		want_back = Vector2(-1.5, -16.0).lerp(BEska.BACK_HAND, open)
	_back_hand = want_back
	if b.pose_on:
		_vec = b.blade_vec
		return
	var want := _idle_vec()
	var k := 1.0 - exp(-minf(delta, 1.0 / 30.0) * 20.0)
	_vec = Vector2.from_angle(lerp_angle(_vec.angle(), want.angle(), k)) * lerpf(_vec.length(), want.length(), k)


func _hand_target() -> Vector2:
	var b := body as BEska
	if b != null and b.pose_on:
		return b.hand_local
	return super._hand_target()


## 자세별 무기 방향 (오른쪽을 보는 기준 각도)
func _idle_vec() -> Vector2:
	var sword := (body as BEska).morph >= 0.5
	var a := 2.5 if sword else 2.1 # 서 있음: 검은 낮게 뒤로, 빗자루는 옆에 비스듬히
	if body.st == EEska.St.CAST:
		a = -1.25 # 낙성: 빗자루를 하늘로
	elif not _floor():
		a = 2.2 if sword else 1.95
	elif absf(body.velocity.x) > 20.0 or _glide > 0.3:
		a = 2.85 if sword else 2.65 # 달림: 뒤로 끌듯이
	return Vector2.from_angle(a)


func _hand_local() -> Vector2:
	return _hand + Vector2(0, _bob())


func _dir_len() -> Array:
	var l := _vec.length()
	return [_vec / maxf(l, 0.001), clampf(l, 0.15, 1.0)]


func hand_global() -> Vector2:
	return to_global(_hand_local())


func back_hand_global() -> Vector2:
	return to_global(_back_hand + Vector2(0, _bob()))


func blade_tip() -> Vector2:
	var dl := _dir_len()
	return to_global(_hand_local() + (dl[0] as Vector2) * (1.6 + BLADE_LEN * float(dl[1])))


func broom_tip() -> Vector2:
	var dl := _dir_len()
	return to_global(_hand_local() - (dl[0] as Vector2) * BROOM_UP * float(dl[1]))


func _paint() -> void:
	var b := body as BEska
	var casting := b.act == "rift"
	if _ready_done and casting: # 흑백 균열: 뒷팔을 뒤로 벌리고, 빗자루는 등 뒤에 떠 있다 (몸 뒤에 먼저 그림)
		_paint_back_arm()
		_paint_broom(BROOM_FLOAT + Vector2(0, sin(_t * 7.0) * 0.8), Vector2.from_angle(BROOM_FLOAT_ANGLE), 1.0, 1.0 - b.morph)
	super._paint()
	if not _ready_done:
		return
	var hand := _hand_local()
	var dl := _dir_len()
	var d: Vector2 = dl[0]
	var fl: float = dl[1]
	if b.morph < 1.0 and not casting:
		_paint_broom(hand, d, fl, 1.0 - b.morph)
	if b.morph > 0.0:
		_paint_sword(hand, d, fl, b.morph, b)
	pd.draw_circle(hand, 1.15, SKIN) # 손가락이 자루를 감싼다


func _paint_back_arm() -> void:
	var o := Vector2(0, _bob())
	var sh := o + Vector2(-1.6, -23.0)
	var bh := _back_hand + o
	var el := sh.lerp(bh, 0.5) + Vector2(0, 1.0)
	pd.draw_line(sh, el, SKIN_SH, 1.6)
	pd.draw_line(el, bh, SKIN_SH, 1.4)
	pd.draw_circle(bh, 1.1, SKIN_SH)


func _paint_broom(hand: Vector2, d: Vector2, fl: float, k: float) -> void:
	var side := d.orthogonal()
	var top := hand - d * BROOM_UP * fl * (0.4 + 0.6 * k)
	var bind := hand + d * BROOM_DOWN * fl * (0.4 + 0.6 * k)
	pd.draw_line(top, bind, OUT, 2.6)
	pd.draw_line(top, bind, HANDLE, 1.4)
	pd.draw_line(top + side * 0.4, bind + side * 0.4, HANDLE_HI, 0.5)
	pd.draw_circle(top, 1.4, OUT)
	pd.draw_circle(top, 0.8, GLOW)
	if k < 0.03:
		return
	var end := bind + d * BRISTLE * fl * k
	var w0 := 1.6 * k
	var w1 := 4.4 * k
	pd.outlined(PackedVector2Array([bind + side * w0, end + side * w1, end + d * 1.0, end - side * w1, bind - side * w0]), BRISTLE_COL, OUT, 0.7)
	for j in 3:
		var o := float(j - 1)
		pd.draw_line(bind + side * o * w0 * 0.6, end + side * o * w1 * 0.7, HAIR_DEEP, 0.5)
	pd.draw_line(end + side * w1 * 0.9, end - side * w1 * 0.9, Color(1, 1, 1, 0.9 * k), 0.6) # 솔 끝 흰빛
	pd.draw_line(bind + side * 2.0 * k, bind - side * 2.0 * k, LINING_HI, 1.4) # 보라 묶음 띠


func _paint_sword(hand: Vector2, d: Vector2, fl: float, m: float, b: BEska) -> void:
	var side := d.orthogonal()
	var g := 1.0 - pow(1.0 - m, 3.0)
	var pommel := hand - d * GRIP
	var guard := hand + d * 1.6
	var tip := guard + d * BLADE_LEN * fl * g
	# 흰 술 두 가닥 (빗자루 솔의 흔적) — 아래로 늘어진다
	var hang := (Vector2(0, 1) - d * 0.5).normalized()
	pd.draw_line(pommel, pommel + hang * 4.5, HAIR, 1.0)
	pd.draw_line(pommel, pommel + hang * 3.6 + side * 1.2, HAIR_MID, 0.8)
	# 자루
	pd.draw_line(pommel, guard, OUT, 2.6)
	pd.draw_line(pommel, guard, CLOTH_HI, 1.4)
	# 날: 먹 테두리 → 흰 강철 → 바늘 끝, 한쪽 날에 흰 빛, 보랏빛 홈
	pd.line2(guard, tip + d * 0.6, OUT, OUT, 3.2, 1.0)
	pd.line2(guard, tip, STEEL, Color(1, 1, 1), 1.8, 0.4)
	pd.line2(guard + side * 0.5, tip, Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.9), 0.6, 0.2)
	pd.line2(guard, guard.lerp(tip, 0.6), Color(GLOW, 0.85), Color(GLOW, 0.0), 0.6, 0.3)
	# 날밑 + 보라 구슬
	pd.draw_line(guard + side * 3.0, guard - side * 3.0, OUT, 2.4)
	pd.draw_line(guard + side * 2.4, guard - side * 2.4, LINING_HI, 1.0)
	pd.draw_circle(guard, 1.0, GLOW_PALE)
	# 마검술 준비: 날을 따라 보랏빛이 차오른다
	if b.act == "swing" and b.cur_id == "skill" and b.act_t < float(b.cur.wu):
		var c := clampf(b.act_t / float(b.cur.wu), 0.0, 1.0)
		pd.line2(guard, guard.lerp(tip, c), Color(GLOW_PALE, 0.9), Color(1, 1, 1, 1), 2.2, 1.0)
		pd.glow(tip, 6.0 + 4.0 * c, Color(GLOW, 0.45 * c), 0.0)
	# 모드가 막 바뀜: 날 전체가 하얗게
	if m < 1.0:
		pd.line2(guard, tip, Color(1, 1, 1, 1.0 - m), Color(1, 1, 1, 1.0 - m), 2.6, 1.0)
