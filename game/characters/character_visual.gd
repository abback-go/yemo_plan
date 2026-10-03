class_name CharacterVisual
extends Node2D
## 학교 인물들의 작은 몸 그림 (코드 그래픽). 원점은 발밑, +x가 바라보는 쪽(부모가 scale.x로 뒤집음).
## Characters.DB의 값(옷·머리·모자·장식)으로 인물마다 다르게 그린다. 숨쉬기·눈 깜빡임·걷기·말하기 움직임.

var who := "student_a"
var info := {}
var walking := false
var talking := false
var _t := 0.0
var _blink := 0.0
var _phase := 0.0


func setup(p_who: String) -> void:
	who = p_who
	info = Characters.info(who)
	_t = randf() * 5.0


func _process(delta: float) -> void:
	_t += delta
	if walking:
		_phase += delta * 10.0
	_blink -= delta
	if _blink < -3.2 - fmod(_t, 1.7):
		_blink = 0.12
	queue_redraw()


func _draw() -> void:
	if info.is_empty():
		info = Characters.info(who)
	var h := float(info.get("height", 32))
	var robe: Color = info.robe
	var robe2: Color = info.robe2
	var skin: Color = info.skin
	var hair: Color = info.hair
	var extra: Array = info.get("extra", [])
	var bob := sin(_t * 2.2) * 0.5 if not walking else -absf(sin(_phase)) * 1.0
	if talking:
		bob += sin(_t * 14.0) * 0.4
	var s := h / 32.0 # 키에 비례
	var head_c := Vector2(1, -h + 7 * s + bob)
	var head_r := 6.0 * s

	# 등 뒤 은은한 윤곽 빛 (어두운 배경과 분리)
	draw_circle(Vector2(0, -h * 0.55), h * 0.5, Color(robe2, 0.06))

	# 다리
	var leg := sin(_phase) * 2.5 if walking else 0.0
	draw_rect(Rect2(-3 + leg, -5 * s, 2, 5 * s), Color("#16121c"))
	draw_rect(Rect2(1 - leg, -5 * s, 2, 5 * s), Color("#16121c"))

	# 망토·로브 (아래로 넓은 사다리꼴)
	var top_y := -h + 13 * s + bob
	var robe_pts := PackedVector2Array([
		Vector2(-4 * s, top_y), Vector2(5 * s, top_y),
		Vector2(7 * s + sin(_t * 2.0) * 0.5, -4 * s), Vector2(-7 * s + sin(_t * 2.0 + 1.0) * 0.5, -4 * s),
	])
	draw_colored_polygon(robe_pts, robe)
	draw_line(Vector2(-6.5 * s, -4 * s), Vector2(6.5 * s, -4 * s), robe2, 1.0)
	draw_line(Vector2(0.5, top_y + 1), Vector2(0.5, -5 * s), robe.lightened(0.12), 1.0)
	if "apron" in extra:
		draw_rect(Rect2(-3 * s, top_y + 4 * s, 7 * s, h - 18 * s), Color("#f0e8dc"))
	# 팔
	var arm_swing := sin(_phase) * 2.0 if walking else (sin(_t * 9.0) * 1.5 if talking else 0.0)
	draw_line(Vector2(4 * s, top_y + 2), Vector2(5 * s + arm_swing, top_y + 9 * s), robe.lightened(0.08), 2.0)
	draw_circle(Vector2(5 * s + arm_swing, top_y + 9.5 * s), 1.2, skin)
	if "ladle" in extra:
		draw_line(Vector2(5 * s + arm_swing, top_y + 9 * s), Vector2(8 * s + arm_swing, top_y - 2 * s), Color("#a8a8b8"), 1.0)
		draw_circle(Vector2(8 * s + arm_swing, top_y - 3 * s), 2.0, Color("#a8a8b8"))
	if "gloves" in extra:
		draw_circle(Vector2(5 * s + arm_swing, top_y + 9.5 * s), 1.6, Color("#101014"))

	# 머리카락 뒤쪽
	match String(info.get("hair_style", "short")):
		"long":
			draw_colored_polygon(PackedVector2Array([
				head_c + Vector2(-6 * s, -2 * s), head_c + Vector2(4 * s, -3 * s), head_c + Vector2(2 * s, 12 * s), head_c + Vector2(-7 * s, 13 * s),
			]), hair)
		"twin":
			draw_circle(head_c + Vector2(-6 * s, 3 * s), 2.6 * s, hair)
			draw_circle(head_c + Vector2(6 * s, 3 * s), 2.6 * s, hair)
			draw_rect(Rect2(head_c.x - 8 * s, head_c.y + 3 * s, 2.5 * s, 6 * s), hair)
			draw_rect(Rect2(head_c.x + 5.5 * s, head_c.y + 3 * s, 2.5 * s, 6 * s), hair)
		"tied":
			draw_colored_polygon(PackedVector2Array([
				head_c + Vector2(-5 * s, 0), head_c + Vector2(-9 * s, 6 * s), head_c + Vector2(-7 * s, 11 * s), head_c + Vector2(-3 * s, 3 * s),
			]), hair)
		"bun":
			draw_circle(head_c + Vector2(-2 * s, -6 * s), 3.2 * s, hair)
	# 얼굴
	draw_circle(head_c, head_r, skin)
	# 앞머리
	var bangs := PackedVector2Array([
		head_c + Vector2(-6.5 * s, 0), head_c + Vector2(-5 * s, -5.5 * s), head_c + Vector2(1 * s, -7 * s),
		head_c + Vector2(6.5 * s, -3 * s), head_c + Vector2(6 * s, 0), head_c + Vector2(3 * s, -2.5 * s), head_c + Vector2(-1 * s, -1.5 * s),
	])
	if String(info.get("hair_style", "")) == "bob":
		bangs.append(head_c + Vector2(-6.5 * s, 4 * s))
	draw_colored_polygon(bangs, hair)
	draw_line(head_c + Vector2(-5 * s, -5 * s), head_c + Vector2(1 * s, -6.5 * s), hair.lightened(0.25), 1.0)
	# 눈
	var eye: Color = info.eye
	if _blink > 0.0:
		draw_line(head_c + Vector2(2 * s, 1 * s), head_c + Vector2(4 * s, 1 * s), Color("#2a1020"), 1.0)
	else:
		draw_rect(Rect2(head_c.x + 2.5 * s, head_c.y - 0.5 * s, 1.5, 2.5), eye)
		draw_rect(Rect2(head_c.x + 2.5 * s, head_c.y - 0.5 * s, 1, 1), Color(1, 1, 1, 0.8))
	if talking and int(_t * 10.0) % 2 == 0:
		draw_rect(Rect2(head_c.x + 3 * s, head_c.y + 3 * s, 2, 1), Color("#8a3a3a"))
	if "glasses" in extra:
		draw_arc(head_c + Vector2(3.2 * s, 0.5 * s), 2.2 * s, 0, TAU, 10, Color("#c8c8d8"), 1.0)
	if "goggles" in extra:
		draw_rect(Rect2(head_c.x - 6 * s, head_c.y - 5 * s, 12 * s, 2.5 * s), Color("#6a4a2a"))
		draw_circle(head_c + Vector2(2 * s, -4 * s), 2.2 * s, Color("#8ad0d8"))
	if "ribbon" in extra:
		draw_colored_polygon(PackedVector2Array([head_c + Vector2(-7 * s, -2 * s), head_c + Vector2(-11 * s, -5 * s), head_c + Vector2(-11 * s, 1 * s)]), Color("#4a6ad8"))

	# 모자
	var hc: Color = info.hat_col
	match String(info.get("hat", "none")):
		"witch":
			var brim_y := head_c.y - 4 * s
			draw_colored_polygon(PackedVector2Array([
				Vector2(head_c.x - 11 * s, brim_y + 1), Vector2(head_c.x + 11 * s, brim_y + 1), Vector2(head_c.x + 9 * s, brim_y - 1.5), Vector2(head_c.x - 9 * s, brim_y - 1.5),
			]), hc)
			var tip := Vector2(head_c.x - 6 * s + sin(_t * 1.6) * 1.0, brim_y - 16 * s)
			draw_colored_polygon(PackedVector2Array([
				Vector2(head_c.x - 6 * s, brim_y - 1), Vector2(head_c.x + 6 * s, brim_y - 1), Vector2(head_c.x + 1 * s, brim_y - 10 * s), tip,
			]), hc)
			draw_line(Vector2(head_c.x - 6 * s, brim_y - 2.5), Vector2(head_c.x + 6 * s, brim_y - 2.5), robe2, 1.5)
		"witch_small":
			var by := head_c.y - 4 * s
			draw_rect(Rect2(head_c.x - 8 * s, by - 1, 16 * s, 2), hc)
			draw_colored_polygon(PackedVector2Array([
				Vector2(head_c.x - 5 * s, by - 1), Vector2(head_c.x + 5 * s, by - 1), Vector2(head_c.x - 2 * s + sin(_t * 1.8), by - 11 * s),
			]), hc)
			draw_line(Vector2(head_c.x - 5 * s, by - 2.5), Vector2(head_c.x + 5 * s, by - 2.5), robe2, 1.0)
		"nurse":
			draw_rect(Rect2(head_c.x - 6 * s, head_c.y - 9 * s, 12 * s, 4 * s), hc)
			draw_rect(Rect2(head_c.x - 1, head_c.y - 8.5 * s, 2, 3 * s), Color("#d84a5a"))
			draw_rect(Rect2(head_c.x - 2 * s, head_c.y - 7.5 * s, 4 * s, 1), Color("#d84a5a"))
	if "feather" in extra:
		var fy := sin(_t * 2.0) * 2.0
		draw_line(head_c + Vector2(-9 * s, -14 * s + fy), head_c + Vector2(-4 * s, -20 * s + fy), Color("#e8e0ff"), 2.0)
	if "stars" in extra:
		for i in 3:
			var a := _t * 0.8 + TAU * i / 3.0
			draw_circle(head_c + Vector2(cos(a) * 12 * s, -10 * s + sin(a) * 4 * s), 1.0, Color(0.9, 0.9, 1.0, 0.7))
	if "owl" in extra:
		var oc := Vector2(-5 * s, top_y - 2)
		draw_circle(oc, 3.5, Color("#8a6a48"))
		draw_circle(oc + Vector2(0, -3), 3.0, Color("#9a7a58"))
		draw_rect(Rect2(oc.x - 2, oc.y - 4, 1, 1), Color("#f0d060"))
		draw_rect(Rect2(oc.x + 1, oc.y - 4, 1, 1), Color("#f0d060"))
