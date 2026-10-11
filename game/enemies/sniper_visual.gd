class_name SniperVisual
extends Node2D
## 저격형 그림: 외눈 두건 정령 + 긴 지팡이. 조준선(추적 중 붉은색 → 고정 시 흰색 깜빡임)도 여기서 그린다.

var enemy: Sniper


func _process(_delta: float) -> void:
	if enemy == null:
		return
	scale.x = enemy.facing
	rotation = enemy._airborne_spin * enemy._t * 10.0 if enemy._airborne_spin != 0.0 else 0.0
	z_index = 2


func _draw() -> void:
	if enemy == null:
		return
	var white := enemy.flash_amount() > 0.0
	var st := enemy.state
	var robe := Color.WHITE if white else Palette.ENEMY_DARK
	var robe_light := Color.WHITE if white else Palette.ENEMY_BODY
	var bob := sin(enemy._t * 2.5) * 0.8

	# 조준선 (전역 좌표 → 이 노드 기준 좌표)
	if (st == Sniper.S.AIM or st == Sniper.S.LOCK) and not white:
		var from := to_local(enemy.eye())
		var to := to_local(enemy.aim_end)
		if st == Sniper.S.AIM:
			var k := 1.0 - (enemy._timer - enemy.tuning.sniper_lock_time) / (enemy.tuning.sniper_aim_time - enemy.tuning.sniper_lock_time)
			draw_line(from, to, Color(Palette.DANGER, 0.25 + 0.35 * k), 1.0)
		else:
			var blink := int(enemy._t * 30.0) % 2 == 0
			draw_line(from, to, Color(1, 1, 1, 0.95 if blink else 0.5), 1.0 if blink else 2.0)
			draw_circle(to, 2.0, Color(1, 1, 1, 0.8))

	# 로브 (아래로 퍼지는 사다리꼴, 밑단이 살랑임)
	var hem := sin(enemy._t * 4.0) * 1.0
	var outline := Color.WHITE if white else Palette.OUTLINE
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5, -21 + bob), Vector2(5, -21 + bob), Vector2(8 + hem, 1), Vector2(-8 + hem, 1),
	]), outline)
	draw_circle(Vector2(0, -22 + bob), 7.0, outline)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4, -20 + bob), Vector2(4, -20 + bob), Vector2(7 + hem, 0), Vector2(-7 + hem, 0),
	]), robe)
	draw_colored_polygon(PackedVector2Array([
		Vector2(1, -20 + bob), Vector2(4, -20 + bob), Vector2(7 + hem, 0), Vector2(3 + hem, 0),
	]), robe_light)
	# 두건
	var hood := PackedVector2Array()
	for i in 10:
		var a := PI + PI * i / 9.0
		hood.append(Vector2(cos(a) * 6.0, -22 + sin(a) * 7.0 + bob))
	hood.append(Vector2(7, -17 + bob))
	hood.append(Vector2(-6, -17 + bob))
	draw_colored_polygon(hood, robe_light)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4, -26 + bob), Vector2(-9, -31 + bob), Vector2(-5, -24 + bob),
	]), robe_light) # 두건 끝
	# 얼굴 구멍과 외눈
	draw_circle(Vector2(2.5, -21 + bob), 3.2, Color(0.02, 0.02, 0.05) if not white else Color.WHITE)
	var eye_col := Palette.ENEMY_EYE
	if st == Sniper.S.AIM:
		eye_col = Palette.ENEMY_EYE.lerp(Palette.DANGER, 0.7)
	elif st == Sniper.S.LOCK:
		eye_col = Color.WHITE
	if not white:
		draw_circle(Vector2(3, -21 + bob), 1.6, eye_col)

	# 지팡이: 조준 방향을 따라 회전
	var dir := enemy.aim_dir
	dir.x *= enemy.facing
	if st == Sniper.S.IDLE or st == Sniper.S.RELOAD:
		dir = Vector2(1, 0.35).normalized()
	var hand := Vector2(3, -13 + bob)
	var staff_col := Color.WHITE if white else Color(0.75, 0.7, 0.62)
	draw_line(hand - dir * 5.0, hand + dir * 12.0, staff_col, 2.0)
	var gem := hand + dir * 12.0
	var gem_col := Palette.SHOT if st != Sniper.S.RELOAD else Palette.ENEMY_BODY_LIGHT
	if st == Sniper.S.RELOAD and not white:
		var k2 := 1.0 - enemy._timer / enemy.tuning.sniper_reload
		gem_col = Palette.ENEMY_BODY_LIGHT.lerp(Palette.SHOT, k2)
	draw_circle(gem, 2.0, Color.WHITE if white else gem_col)
