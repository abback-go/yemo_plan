class_name TAsheArt
extends PDraw.Canvas
## 아셰 — 잿불의 마녀 (새 코드 그림, 키 약 37px). 원점 = 발밑 가운데, 오른쪽을 본다.
## 잿빛 단발(끝이 잉걸불처럼 주황으로 타오름) · 잿빛 숄(주황 자수 테) · 적갈색 드레스 + 크림색 앞치마 · 사슬에 매단 작은 향로(잉걸불이 피어오름).
## 세라(붉은 머리·남색 코트)·에스카(흑백+보라)와 색이 겹치지 않게 잿빛·주황·크림으로.
## pose: idle · cast · hurt · down. 향로가 그녀의 마법 도구 — 무기가 아니라 불씨를 담는 그릇.

const OUT := Color("#1a1214")
const SKIN := Color("#f6e2cf")
const SKIN_SH := Color("#d9b59c")
const HAIR := Color("#aaa3a8")
const HAIR_SH := Color("#7c767c")
const HAIR_HI := Color("#d2cbd0")
const EMBER := Color("#ff8a3a")
const EMBER_HOT := Color("#ffd27a")
const EMBER_CORE := Color("#fff4d6")
const SHAWL := Color("#6e6a70")
const SHAWL_SH := Color("#4c484f")
const TRIM := Color("#e0863a")
const DRESS := Color("#4a2a2a")
const DRESS_HI := Color("#6a3c38")
const APRON := Color("#d8c8a8")
const APRON_SH := Color("#b3a284")
const BRONZE := Color("#6b4a2a")
const BRONZE_HI := Color("#a3783f")
const SHOE := Color("#2a1c1e")
const EYE := Color("#f0c050")

var pose := "idle"
var t := 0.0
var cast_k := 0.0 ## 시전 세기 0~1 (향로를 들어 올림)
var flash := 0.0
var _blink := 0.0
var _next_blink := 2.5
var _hair := 0.0 ## 머리칼 흔들림
var _chain := 0.0 ## 향로 흔들림 각


func step(delta: float) -> void:
	t += delta
	_next_blink -= delta
	if _next_blink <= 0.0:
		_blink = 0.12
		_next_blink = randf_range(2.0, 4.5)
	_blink = maxf(_blink - delta, 0.0)
	flash = maxf(flash - delta * 5.0, 0.0)
	var want := 1.0 if pose == "cast" else 0.0
	cast_k = move_toward(cast_k, want, delta * 6.0)
	_hair = sin(t * 2.2) * 0.6
	_chain = sin(t * 3.1) * 0.18 * (1.0 - cast_k) + sin(t * 12.0) * 0.05 * cast_k
	queue_redraw()


func _paint() -> void:
	var lean := 0.0
	var bob := sin(t * 2.4) * 0.5
	var sq := Vector2.ONE
	match pose:
		"cast":
			lean = 0.08
			bob = 1.2
		"hurt":
			lean = -0.32
			sq = Vector2(1.08, 0.94)
		"down":
			lean = -0.9
			sq = Vector2(1.0, 0.55)
	# 바닥 그림자
	pd.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.25))
	pd.glow(Vector2.ZERO, 9.0, Color(0, 0, 0, 0.5), 0.0)
	pd.draw_set_transform(Vector2(0, bob * 0.3), lean, sq)
	# ── 다리 + 구두
	for side in [-1, 1]:
		var hip := Vector2(side * 1.6, -15.0)
		var foot := Vector2(side * 2.2 + 0.6, -0.6)
		pd.draw_line(hip, foot, OUT, 3.2)
		pd.draw_line(hip, foot, Color("#3a2c30"), 2.0)
		pd.draw_colored_polygon(PackedVector2Array([foot + Vector2(-1.6, -1.4), foot + Vector2(1.2, -1.4), foot + Vector2(3.2, 0.2), foot + Vector2(3.0, 1.0), foot + Vector2(-1.8, 1.0)]), OUT)
		pd.draw_colored_polygon(PackedVector2Array([foot + Vector2(-1.0, -0.9), foot + Vector2(1.0, -0.9), foot + Vector2(2.4, 0.1), foot + Vector2(2.2, 0.4), foot + Vector2(-1.1, 0.4)]), SHOE)
	# ── 드레스 (적갈색) + 앞치마
	var hem := -2.0
	pd.outlined(PackedVector2Array([Vector2(-3.4, -16.5), Vector2(3.6, -16.5), Vector2(7.4 + _hair * 0.3, hem), Vector2(5.0, hem + 1.0), Vector2(-5.2, hem + 1.0), Vector2(-7.6 - _hair * 0.3, hem)]), DRESS, OUT, 0.7)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(0.4, -16.0), Vector2(3.4, -16.0), Vector2(6.6, hem - 0.4), Vector2(2.6, hem - 0.4)]), DRESS_HI)
	pd.outlined(PackedVector2Array([Vector2(-2.2, -14.5), Vector2(2.6, -14.5), Vector2(4.2, hem - 1.6), Vector2(-3.6, hem - 1.6)]), APRON, OUT, 0.5)
	pd.draw_line(Vector2(-2.0, hem - 4.0), Vector2(3.6, hem - 4.0), APRON_SH, 0.7)
	pd.draw_line(Vector2(-2.2, -14.5), Vector2(2.6, -14.5), TRIM, 1.0) # 허리 끈
	# ── 몸통 + 숄
	pd.outlined(PackedVector2Array([Vector2(-3.2, -25.0), Vector2(3.4, -25.0), Vector2(3.6, -16.0), Vector2(-3.4, -16.0)]), DRESS, OUT, 0.6)
	var sh := PackedVector2Array([Vector2(-6.6, -24.4), Vector2(6.8, -24.4), Vector2(4.6, -19.0), Vector2(0.4, -14.0), Vector2(-4.2, -19.0)])
	pd.outlined(sh, SHAWL, OUT, 0.7)
	pd.draw_colored_polygon(PackedVector2Array([Vector2(0.6, -24.0), Vector2(6.4, -24.0), Vector2(4.4, -19.2), Vector2(1.2, -15.4)]), SHAWL_SH.lerp(SHAWL, 0.5))
	pd.draw_polyline(PackedVector2Array([Vector2(-6.2, -24.0), Vector2(-4.0, -19.0), Vector2(0.4, -14.6), Vector2(4.4, -19.0), Vector2(6.4, -24.0)]), TRIM, 0.8)
	# 목
	pd.draw_rect(Rect2(Vector2(-0.4, -27.4), Vector2(2.0, 2.8)), SKIN_SH)
	# ── 뒷팔 (아래로)
	var bsh := Vector2(-2.2, -23.2)
	var bhand := Vector2(-3.6, -14.8)
	pd.draw_line(bsh, bhand, OUT, 3.0)
	pd.draw_line(bsh, bhand, SHAWL_SH, 1.8)
	pd.draw_circle(bhand, 1.2, SKIN_SH)
	# ── 머리 (잿빛 단발, 끝이 주황)
	var hc := Vector2(0.9, -31.0)
	pd.draw_circle(hc + Vector2(-1.0, 0.2), 4.6, HAIR_SH) # 뒷머리
	pd.draw_circle(hc, 3.5, SKIN)
	pd.draw_rect(Rect2(hc + Vector2(1.4, 1.2), Vector2(1.4, 0.9)), SKIN_SH)
	pd.draw_rect(Rect2(hc + Vector2(2.0, 0.5), Vector2(0.9, 0.4)), Color("#c98077")) # 입술
	# 앞머리·옆머리 (끝이 불타는 잉걸불)
	var fr := PackedVector2Array([hc + Vector2(-4.4, -1.0), hc + Vector2(-3.4, -4.6), hc + Vector2(0.2, -5.4), hc + Vector2(3.6, -4.0), hc + Vector2(4.4, -1.0),
		hc + Vector2(3.6, -1.6), hc + Vector2(2.2, -3.0), hc + Vector2(0.2, -1.8), hc + Vector2(-1.4, -3.2), hc + Vector2(-2.8, -1.2)])
	pd.outlined(fr, HAIR, OUT, 0.6)
	pd.draw_colored_polygon(PackedVector2Array([hc + Vector2(-2.6, -4.4), hc + Vector2(1.0, -5.0), hc + Vector2(2.6, -3.8), hc + Vector2(-0.6, -3.2)]), HAIR_HI)
	# 옆머리 두 가닥 (볼 옆으로 내려와 끝이 타오름)
	for side in [-1, 1]:
		var top := hc + Vector2(side * 4.0, -1.4)
		var tip := hc + Vector2(side * 4.6 + _hair * 0.3 * side, 4.4)
		pd.draw_line(top, tip, OUT, 2.6)
		pd.draw_line(top, tip, HAIR, 1.6)
		var f := 0.6 + 0.4 * sin(t * 9.0 + float(side))
		pd.glow(tip, 3.0, Color(EMBER, 0.45 * f), 0.0)
		pd.draw_line(tip + Vector2(0, -2.2), tip + Vector2(0, 0.8), EMBER, 1.4)
		pd.draw_rect(Rect2(tip + Vector2(-0.5, -0.4), Vector2(1.0, 1.0)), Color(EMBER_HOT, f))
	# 눈 (호박빛 하나, 뒷눈은 가늘게)
	var eye := hc + Vector2(1.9, 0.2)
	if _blink > 0.0 or pose == "down":
		pd.draw_line(eye + Vector2(-1.0, 0.2), eye + Vector2(1.0, 0.0), OUT, 0.9)
	elif pose == "hurt":
		pd.draw_line(eye + Vector2(-0.9, -0.9), eye + Vector2(0.9, 0.9), OUT, 0.9)
		pd.draw_line(eye + Vector2(-0.9, 0.9), eye + Vector2(0.9, -0.9), OUT, 0.9)
	else:
		pd.draw_rect(Rect2(eye + Vector2(-0.9, -1.0), Vector2(1.9, 2.2)), OUT)
		pd.draw_rect(Rect2(eye + Vector2(-0.5, -0.5), Vector2(1.2, 1.4)), EYE)
		pd.draw_rect(Rect2(eye + Vector2(-0.5, -0.5), Vector2(0.5, 0.5)), Color(1, 1, 1, 0.9))
		pd.draw_line(eye + Vector2(-1.2, -1.1), eye + Vector2(1.3, -1.2), OUT, 0.8)
	pd.draw_line(hc + Vector2(-1.0, -0.4), hc + Vector2(-1.0, 0.8), OUT, 0.8)
	# 머리핀 (작은 불꽃 모양)
	pd.draw_colored_polygon(PackedVector2Array([hc + Vector2(-3.2, -3.2), hc + Vector2(-2.0, -5.6), hc + Vector2(-1.2, -3.4)]), TRIM)
	# ── 앞팔 + 향로
	var fsh := Vector2(2.4, -23.0)
	var hand_idle := Vector2(7.0, -17.5)
	var hand_cast := Vector2(9.5, -27.5)
	var hand := hand_idle.lerp(hand_cast, cast_k)
	if pose == "hurt":
		hand = Vector2(5.0, -20.0)
	var el := fsh.lerp(hand, 0.5) + Vector2(0.4, 1.6 * (1.0 - cast_k))
	pd.draw_line(fsh, el, OUT, 3.0)
	pd.draw_line(el, hand, OUT, 2.8)
	pd.draw_line(fsh, el, SHAWL, 1.8)
	pd.draw_line(el, hand, SKIN, 1.5)
	pd.draw_circle(hand, 1.2, SKIN)
	_paint_censer(hand)


## 향로: 손에서 사슬로 늘어진 작은 청동 그릇, 안에서 잉걸불이 피어오른다. 시전하면 불이 커진다
func _paint_censer(hand: Vector2) -> void:
	var ang := _chain
	var len := 4.0
	var c := hand + Vector2(sin(ang), cos(ang)) * len + Vector2(0, 1.6)
	pd.draw_line(hand, c + Vector2(0, -1.6), BRONZE_HI, 0.7)
	var glow := 0.35 + 0.65 * cast_k + 0.1 * sin(t * 11.0)
	pd.glow(c, 5.0 + 3.0 * cast_k, Color(EMBER, 0.35 * glow), 0.0)
	var body := PackedVector2Array([c + Vector2(-2.2, -1.6), c + Vector2(2.2, -1.6), c + Vector2(2.6, 0.6), c + Vector2(1.4, 2.4), c + Vector2(-1.4, 2.4), c + Vector2(-2.6, 0.6)])
	pd.outlined(body, BRONZE, OUT, 0.6)
	pd.draw_line(c + Vector2(-1.8, -0.8), c + Vector2(1.8, -0.8), BRONZE_HI, 0.7)
	pd.draw_rect(Rect2(c + Vector2(-1.2, -1.0), Vector2(2.4, 1.0)), Color(EMBER_HOT, 0.9 * glow))
	pd.draw_rect(Rect2(c + Vector2(-0.6, -1.3), Vector2(1.2, 0.6)), Color(EMBER_CORE, glow))
	# 피어오르는 불티
	var n := 2 + int(3.0 * cast_k)
	for i in n:
		var ph := t * (2.4 + float(i) * 0.37) + float(i) * 1.7
		var rise := fmod(ph * 7.0, 11.0 + 7.0 * cast_k)
		var x := sin(ph * 2.3) * (1.4 + cast_k)
		var a := (0.9 - rise / (11.0 + 7.0 * cast_k)) * (0.5 + 0.5 * cast_k)
		pd.draw_rect(Rect2(c + Vector2(x - 0.5, -1.8 - rise), Vector2(1.0, 1.0)), Color(EMBER_HOT if i % 2 == 0 else EMBER, a))
