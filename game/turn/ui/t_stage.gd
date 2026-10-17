class_name TStage
extends PDraw.Canvas
## 2.5D 무대: 뒤에서 본 마녀 마당 — 지평선 위는 밤하늘·먼 첨탑(EScenery 층 재사용), 아래는 원근이 있는 돌바닥.
## 바닥은 지평선(HORIZON_Y)에서 아래로 갈수록 넓어지는 돌판 격자. 멀수록 안개에 잠긴다. 정적(한 번 그림) — 촛불·빛 입자만 따로 움직인다.

const HORIZON_Y := 196.0
const BOTTOM_Y := 372.0
const NEAR_HALF := 520.0 ## 화면 아래 끝에서 바닥 반폭
const FAR_HALF := 150.0 ## 지평선에서 바닥 반폭
const VANISH_X := 330.0
const STONE := Color("#141019")
const STONE_HI := Color("#231c2c")
const STONE_LINE := Color("#2c2438")
const MIST := Color("#5a4290")
const RUNE := Color("#8a74c4")

var _drawn := false


func _ready() -> void:
	z_index = -4


## 깊이 z(0 = 화면 아래, 1 = 지평선)와 가로 u(-1..1)를 화면 좌표로
static func floor_point(u: float, z: float) -> Vector2:
	var half := lerpf(NEAR_HALF, FAR_HALF, z)
	var y := lerpf(BOTTOM_Y, HORIZON_Y, 1.0 - pow(1.0 - z, 1.6))
	return Vector2(VANISH_X + u * half, y)


func _paint() -> void:
	# 바닥 전체 (지평선 아래) — 멀수록 밝은 안개색으로
	var rows := 14
	for r in rows:
		var z0 := float(r) / float(rows)
		var z1 := float(r + 1) / float(rows)
		var a := floor_point(-1.0, z0)
		var b := floor_point(1.0, z0)
		var c := floor_point(1.0, z1)
		var d := floor_point(-1.0, z1)
		var fog := pow(z1, 1.8)
		var col := STONE.lerp(MIST, fog * 0.42)
		if r % 2 == 1:
			col = col.lightened(0.04)
		pd.draw_colored_polygon(PackedVector2Array([a, b, c, d]), col)
		pd.draw_line(a, b, Color(STONE_LINE.lerp(MIST, fog * 0.5), 0.6 - fog * 0.4), 1.0)
	# 세로 이음선 (소실점으로 모임)
	for i in range(-6, 7):
		var u := float(i) / 6.0
		var p0 := floor_point(u, 0.0)
		var p1 := floor_point(u, 1.0)
		pd.line2(p0, p1, Color(STONE_LINE, 0.5), Color(MIST, 0.0), 1.2, 0.6)
	# 마당 가운데 큰 마녀 문장 (일곱 갈래 별, 바닥에 눕힘)
	var cz := 0.42
	var cc := floor_point(0.08, cz)
	var rx := 118.0
	var ry := 26.0
	pd.draw_set_transform(cc, 0.0, Vector2(1.0, ry / rx))
	pd.draw_arc(Vector2.ZERO, rx, 0.0, TAU, 48, Color(RUNE, 0.22), 1.5)
	pd.draw_arc(Vector2.ZERO, rx * 0.82, 0.0, TAU, 40, Color(RUNE, 0.14), 1.0)
	for i in 7:
		var a0 := float(i) / 7.0 * TAU - PI / 2.0
		var a1 := float((i + 3) % 7) / 7.0 * TAU - PI / 2.0
		pd.draw_line(Vector2(cos(a0), sin(a0)) * rx * 0.8, Vector2(cos(a1), sin(a1)) * rx * 0.8, Color(RUNE, 0.16), 1.0)
	pd.draw_set_transform(Vector2.ZERO)
	# 지평선 안개 띠
	for i in 3:
		var y := HORIZON_Y + 4.0 + float(i) * 10.0
		pd.rect_grad(Rect2(-100, y - 14, 840, 14), Color(MIST, 0.0), Color(MIST, 0.16 - 0.04 * float(i)))
		pd.rect_grad(Rect2(-100, y, 840, 12), Color(MIST, 0.16 - 0.04 * float(i)), Color(MIST, 0.0))
	# 양옆 기둥 (가까운 것은 크게)
	for spec: Array in [[-0.98, 0.1, 1.0], [0.98, 0.14, 0.9], [-0.9, 0.55, 0.45], [0.92, 0.5, 0.5]]:
		var base := floor_point(float(spec[0]), float(spec[1]))
		var sc: float = spec[2]
		var w := 18.0 * sc
		var hgt := 190.0 * sc
		pd.outlined(PackedVector2Array([base + Vector2(-w, 0), base + Vector2(w, 0), base + Vector2(w * 0.8, -hgt), base + Vector2(-w * 0.8, -hgt)]), STONE, Color("#2c2438"), 1.0)
		pd.draw_line(base + Vector2(-w * 0.5, -4), base + Vector2(-w * 0.45, -hgt + 6), STONE_HI, 1.5 * sc)
		pd.draw_rect(Rect2(base + Vector2(-w * 1.1, -hgt - 6.0 * sc), Vector2(w * 2.2, 6.0 * sc)), STONE_HI)
