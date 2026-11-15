class_name StShot
extends EnemyProjectile
## 5장 탄 (EnemyProjectile을 그대로 이어받아 불꽃 방벽에 되쏘아지는 규칙도 따른다). 모양만 다르다.
## style: star(도는 금빛 별) · arrow(긴 빛 화살) · comet(꼬리 긴 큰 별) · white_spear(바깥 신들의 흰 빛창)
##        white_orb(지우는 흰 구) · lance(별창 투척)

static func fire(pos: Vector2, p_dir: Vector2, p_speed: float, p_style: String, opts := {}) -> StShot:
	var s := StShot.new()
	s.setup(pos, p_dir, p_speed, p_style, opts)
	Fx.effect_parent().add_child(s)
	return s


func _ready() -> void:
	super._ready()
	material = null if style.begins_with("white") or style == "shock" else Fx.add_material


func _color() -> Color:
	match style:
		"white_spear", "white_orb": return StArt.GOD_GLOW
		"comet": return StArt.STAR_GOLD
	return StArt.STAR


func _draw() -> void:
	var c := _color()
	var d := _vel.normalized() if _vel.length() > 1.0 else dir
	# 꼬리
	var prev := Vector2.ZERO
	for i in _trail.size():
		var p := to_local(_trail[i])
		var k := 1.0 - float(i) / _trail.size()
		var w := radius * (1.6 if style == "comet" else 0.9) * k + 0.5
		draw_line(prev, p, Color(c, 0.4 * k), w)
		prev = p
	match style:
		"shock":
			# 거신 발밑에서 바닥을 달리는 흙먼지 충격파
			var sx := signf(d.x)
			for i in 4:
				var r := 7.0 - i * 1.2
				draw_circle(Vector2(-sx * i * 5.0, 2.0 - i * 0.5), r, Color(0.5, 0.46, 0.48, 0.55 - i * 0.1))
			draw_arc(Vector2(sx * 2.0, 2.0), 8.0, -PI * 0.5 - 0.9 * sx, -PI * 0.5 + 0.9 * sx, 8, Color(1, 1, 1, 0.7), 2.0)
		"wave":
			# 바닥을 달리는 검압 (초승달 빛)
			var pts := PackedVector2Array()
			for i in 9:
				var a := lerpf(-1.3, 1.3, float(i) / 8.0)
				pts.append(Vector2(cos(a) * 6.0 * signf(d.x) - d.x * 4.0, sin(a) * 9.0 - 2.0))
			draw_polyline(pts, Color(c, 0.4), 4.0)
			draw_polyline(pts, StArt.STAR_CORE, 1.0)
			draw_rect(Rect2(-6, 5, 12, 2), Color(c, 0.5))
		"arrow":
			draw_line(-d * 14.0, d * 4.0, Color(c, 0.35), 3.0)
			draw_line(-d * 12.0, d * 4.0, StArt.STAR_CORE, 1.0)
			var n := d.orthogonal()
			draw_colored_polygon(PackedVector2Array([d * 6.0, d * 1.0 + n * 2.5, d * 1.0 - n * 2.5]), StArt.STAR_CORE)
			for i in 3:
				draw_rect(Rect2(-d * (14.0 + i * 3.0) - Vector2(0.5, 0.5), Vector2.ONE), Color(c, 0.6 - i * 0.15))
		"lance":
			var n2 := d.orthogonal()
			draw_line(-d * 16.0, d * 2.0, Color(StArt.STAR_GOLD, 0.8), 2.0)
			draw_colored_polygon(PackedVector2Array([d * 10.0, d * 2.0 + n2 * 4.0, d * 3.0, d * 2.0 - n2 * 4.0]), StArt.STAR_CORE)
			draw_circle(d * 4.0, 6.0, Color(c, 0.2))
		"comet":
			draw_circle(Vector2.ZERO, radius + 4.0, Color(c, 0.18))
			StArt.star(self, Vector2.ZERO, radius + 1.0, c, _spin)
			draw_circle(Vector2.ZERO, radius * 0.4, StArt.STAR_CORE)
		"white_spear":
			var n3 := d.orthogonal()
			draw_line(-d * 18.0, d * 6.0, Color(0.4, 0.4, 0.5, 0.8), 3.0)
			draw_line(-d * 18.0, d * 6.0, StArt.GOD_GLOW, 1.0)
			draw_colored_polygon(PackedVector2Array([d * 12.0, d * 4.0 + n3 * 3.0, d * 6.0, d * 4.0 - n3 * 3.0]), StArt.GOD_WHITE)
			draw_polyline(PackedVector2Array([d * 12.0, d * 4.0 + n3 * 3.0, d * 6.0, d * 4.0 - n3 * 3.0, d * 12.0]), StArt.GOD_LINE, 1.0)
		"white_orb":
			var r := radius + sin(_t * 9.0)
			draw_circle(Vector2.ZERO, r + 3.0, Color(0.1, 0.1, 0.15, 0.5))
			draw_circle(Vector2.ZERO, r, StArt.GOD_WHITE)
			draw_arc(Vector2.ZERO, r + 5.0, _spin, _spin + PI * 1.2, 10, StArt.GOD_LINE, 1.0)
			StArt.god_eye(self, Vector2.ZERO, r * 0.7, 0.8, Vector2(cos(_spin * 0.3), 0), 0.0)
		_:
			draw_circle(Vector2.ZERO, radius + 3.0, Color(c, 0.2))
			StArt.star(self, Vector2.ZERO, radius + 1.0, c, _spin)
			StArt.star(self, Vector2.ZERO, radius * 0.5, StArt.STAR_CORE, _spin)
