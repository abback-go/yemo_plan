extends SceneTree
## 홈 화면 웹앱 아이콘 생성기: 32×32 픽셀 그림(마녀 모자 + 끝의 푸른 여우불)을 그려 크기별 PNG로 저장한다.
## 실행 (game/ 폴더에서): $G --headless --script ../tools/make_icons.gd
## 결과: game/assets/icon/icon_144.png · icon_180.png · icon_512.png (export_presets.cfg의 PWA 아이콘, 프로젝트 아이콘)

const BG := Color("#1a1330")
const BG_EDGE := Color("#0b0914")
const HAT := Color("#4b3580")
const HAT_LIGHT := Color("#7a5cb5")
const HAT_DARK := Color("#2c1f4d")
const BAND := Color("#e8b04a")
const FIRE := Color("#6fc3ff")
const FIRE_CORE := Color("#e6f7ff")
const HAIR := Color("#e8506a")


func _init() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var cone := PackedVector2Array([Vector2(8.5, 21.5), Vector2(23.5, 21.5), Vector2(19.5, 12), Vector2(23.5, 6.5), Vector2(15, 11)])
	for y in 32:
		for x in 32:
			var p := Vector2(x + 0.5, y + 0.5)
			var c := BG.lerp(Color("#2a1f4a"), clampf(1.0 - p.distance_to(Vector2(16, 14)) / 20.0, 0.0, 1.0) * 0.6)
			if x == 0 or y == 0 or x == 31 or y == 31:
				c = BG_EDGE
			# 머리끝 붉은 머리칼 (모자 아래로 살짝)
			if y >= 23 and y <= 25 and (x in [9, 10, 22, 23]):
				c = HAIR
			# 챙: 납작한 타원
			var e := Vector2((p.x - 16.0) / 13.0, (p.y - 22.5) / 3.0)
			if e.length() <= 1.0:
				c = HAT_DARK if p.y > 22.5 else HAT
			# 원뿔 (끝이 꺾인 모자)
			if Geometry2D.is_point_in_polygon(p, cone):
				c = HAT_LIGHT if p.x > 17.5 + (21.5 - p.y) * 0.25 else HAT
			# 띠
			if (y == 19 or y == 20) and Geometry2D.is_point_in_polygon(p, cone):
				c = BAND
			# 모자 끝의 푸른 여우불
			var fd := p.distance_to(Vector2(25, 4.5))
			if fd <= 3.2:
				c = FIRE
			if fd <= 1.6:
				c = FIRE_CORE
			if Vector2(p.x - 25.5, (p.y - 1.5) * 0.8).length() <= 1.2:
				c = FIRE
			img.set_pixel(x, y, c)
	DirAccess.make_dir_recursive_absolute("res://assets/icon")
	for s in [144, 180, 512]:
		var out := img.duplicate() as Image
		out.resize(s, s, Image.INTERPOLATE_NEAREST)
		var err := out.save_png("res://assets/icon/icon_%d.png" % s)
		print("icon ", s, " -> ", error_string(err))
	quit()
