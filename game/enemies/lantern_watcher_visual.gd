class_name LanternWatcherVisual
extends Node2D
## 등롱 감시자 그림: 신계의 석등(지대석·연꽃 받침·기둥·불창·지붕돌·보주)과 불창 속의 눈 하나.
## 조준선(추적 중 붉은색 → 고정 시 흰색 깜빡임)도 여기서 그린다. 석등은 좌우 대칭이라 뒤집지 않고 눈동자만 움직인다.

const STONE := Color("#4c4b62")
const STONE_LIGHT := Color("#6e6d8a")
const STONE_DARK := Color("#2d2c40")
const LACQUER := Color("#b8322a")
const SCLERA := Color(1.0, 0.93, 0.8)
const IRIS := Color("#2a0f12")

var enemy: LanternWatcher


func _process(_delta: float) -> void:
	if enemy == null:
		return
	rotation = enemy._airborne_spin * enemy._t * 10.0 if enemy._airborne_spin != 0.0 else 0.0
	z_index = 2


func _draw() -> void:
	if enemy == null:
		return
	var white := enemy.flash_amount() > 0.0
	var st := enemy.state
	var t := enemy._t
	var stone := Color.WHITE if white else STONE
	var light := Color.WHITE if white else STONE_LIGHT
	var dark := Color(0.85, 0.85, 0.9) if white else STONE_DARK
	var outline := Color.WHITE if white else Palette.OUTLINE
	var flame := Color.WHITE if white else enemy.window_light()

	# 조준선 (전역 좌표 → 이 노드 기준 좌표)
	if (st == Sniper.S.AIM or st == Sniper.S.LOCK) and not white:
		var from := to_local(enemy.eye())
		var to := to_local(enemy.aim_end)
		if st == Sniper.S.AIM:
			var k := 1.0 - (enemy._timer - enemy.tuning.sniper_lock_time) / (enemy.tuning.sniper_aim_time - enemy.tuning.sniper_lock_time)
			draw_line(from, to, Color(Palette.DANGER, 0.25 + 0.35 * k), 1.0)
		else:
			var blink := int(t * 30.0) % 2 == 0
			draw_line(from, to, Color(1, 1, 1, 0.95 if blink else 0.5), 1.0 if blink else 2.0)
			draw_circle(to, 2.0, Color(1, 1, 1, 0.8))

	# 지대석 · 연꽃 받침 · 기둥
	draw_rect(Rect2(-10, -5, 20, 5), outline)
	draw_rect(Rect2(-9, -4, 18, 4), dark)
	draw_rect(Rect2(-9, -4, 18, 1), stone)
	draw_rect(Rect2(-8, -8, 16, 4), outline)
	draw_rect(Rect2(-7, -7, 14, 3), stone)
	if not white:
		for i in 4:
			draw_rect(Rect2(-6 + i * 3.5, -7, 2, 1), light) # 연꽃잎
	draw_rect(Rect2(-3.5, -16, 7, 9), outline)
	draw_rect(Rect2(-2.5, -16, 5, 9), stone)
	draw_rect(Rect2(-2.5, -16, 1, 9), light)
	# 붉은 금줄 (기둥에 맨 끈)
	if not white:
		draw_rect(Rect2(-3.5, -13, 7, 1.5), LACQUER)
		var sway := sin(t * 2.0) * 0.5
		draw_line(Vector2(2.5, -11.5), Vector2(3.5 + sway, -8.5), LACQUER, 1.0)
		draw_line(Vector2(1.5, -11.5), Vector2(2.0 + sway, -9.5), LACQUER.darkened(0.3), 1.0)
	# 상대석 (불창 받침)
	draw_rect(Rect2(-8, -19, 16, 4), outline)
	draw_rect(Rect2(-7, -18, 14, 2), light)

	# 화사석 (불창이 뚫린 돌)
	draw_rect(Rect2(-7, -30, 14, 12), outline)
	draw_rect(Rect2(-6, -29, 12, 10), stone)
	draw_rect(Rect2(-6, -29, 1, 10), light)
	# 불창: 안쪽 불빛
	draw_rect(Rect2(-4, -27.5, 8, 7), flame)
	if not white:
		draw_rect(Rect2(-4, -27.5, 8, 1), flame.darkened(0.35)) # 창 윗턱 그늘
		draw_rect(Rect2(-4, -21.5, 8, 1), flame.lightened(0.3)) # 아래쪽이 더 밝다

	# 눈: 흰자 → 눈동자 (세라 쪽을 본다)
	var look := Vector2(sin(t * 0.8) * 1.4, sin(t * 0.53) * 0.4)
	if st == Sniper.S.AIM or st == Sniper.S.LOCK:
		look = Vector2(clampf(enemy.aim_dir.x * 2.0, -1.6, 1.6), clampf(enemy.aim_dir.y * 1.5, -0.6, 0.6))
	var ec := Vector2(0, -24)
	if not white:
		# 눈두덩 (불빛이 하얗게 번쩍여도 눈 모양이 보이게 어두운 테두리)
		draw_rect(Rect2(ec + Vector2(-4, -2), Vector2(8, 4)), Palette.OUTLINE)
		draw_rect(Rect2(ec + Vector2(-3, -3), Vector2(6, 6)), Palette.OUTLINE)
	draw_rect(Rect2(ec + Vector2(-3, -1.5), Vector2(6, 3)), SCLERA if not white else Color.WHITE)
	draw_rect(Rect2(ec + Vector2(-2, -2.2), Vector2(4, 4.4)), SCLERA if not white else Color.WHITE)
	if not white:
		var iris := IRIS
		if st == Sniper.S.AIM or st == Sniper.S.LOCK:
			iris = Palette.DANGER.darkened(0.2)
		draw_rect(Rect2(ec + look + Vector2(-1, -1.6), Vector2(2, 3.2)), iris)
		if st == Sniper.S.LOCK:
			var blink := int(t * 30.0) % 2 == 0
			draw_rect(Rect2(ec + look + Vector2(-0.5, -0.5), Vector2(1, 1)), Color.WHITE if blink else Palette.FIRE_HOT)
		else:
			draw_rect(Rect2(ec + look + Vector2(-0.5, -1.4), Vector2(1, 1)), Color(1, 1, 1, 0.9))
		# 눈꺼풀: 재장전 중엔 반쯤 감았다가 천천히 뜸, 평소엔 가끔 깜빡임
		var lid := 0.0
		if st == Sniper.S.RELOAD:
			lid = 0.6 * clampf(enemy._timer / enemy.tuning.sniper_reload, 0.0, 1.0)
		elif st == Sniper.S.IDLE and fmod(t, 3.3) < 0.12:
			lid = 1.0
		if lid > 0.0:
			draw_rect(Rect2(ec + Vector2(-3, -2.4), Vector2(6, 4.8 * lid)), stone.darkened(0.15))

	# 옥개석 (지붕돌): 처마 끝이 살짝 들린 넓은 지붕 + 보주
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, -29), Vector2(12, -29), Vector2(7, -34), Vector2(-7, -34),
	]), outline)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-10.5, -30), Vector2(10.5, -30), Vector2(6.5, -33.5), Vector2(-6.5, -33.5),
	]), stone)
	draw_rect(Rect2(-6.5, -33.5, 13, 1), light)
	draw_rect(Rect2(-13, -31, 2.5, 2), light) # 들린 처마 끝
	draw_rect(Rect2(10.5, -31, 2.5, 2), light)
	draw_rect(Rect2(-2.5, -36, 5, 2.5), outline)
	draw_circle(Vector2(0, -37.5), 2.4, outline)
	draw_circle(Vector2(0, -37.5), 1.7, light)
	draw_rect(Rect2(-0.5, -40.5, 1, 1.5), light)
