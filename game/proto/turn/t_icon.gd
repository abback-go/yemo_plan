class_name TIcon
extends RefCounted
## 마법 아이콘 — 전부 코드 그림. 모양 이름은 `t_data.gd` SKILLS[].icon(기본 공격은 "strike")에 적고, 색은 호출 쪽이 정한다
## (속성 색 `TData.ELEMENT_COLOR`, 바퀴에서 고른 칸은 INK). 같은 마녀의 마법 10개는 모양이 전부 다르고, 다른 마녀와는 색으로 가른다.
## 좌표는 단위 원(-1~1) × r. 쓰는 곳: THud 바퀴 칸·설명 상자, TSetup 장착 목록·설명 상자.

const NAMES := ["strike", "crack", "gate", "dash", "shield", "rift", "converge", "eclipse", "eye", "blackstar", "cradle",
	"spark", "whip", "focus", "pillar", "meteor", "breath", "storm", "bloom", "spear", "inferno",
	"flame", "kindle", "bellows", "heart", "up", "wall", "stake", "descent", "ascend", "link", "sun",
	"dust", "smoke", "wind", "ring", "heap", "brand", "oath", "whirl", "wave", "tide", "drop", "cloak", "nail",
	"snow", "net", "shard", "lock", "coffin", "burst", "chain", "bolt", "bolt_big", "rod", "clock_fwd", "rewind", "cycle",
	"sparkle", "starfall", "needle", "wave_out", "fence", "clock", "clock_doom", "hourglass",
	"slash", "cut_curve", "slash2", "cut_h", "aura", "cut_v", "fan", "slash_doom", "slash_x"]


static func draw(ci: Object, c: Vector2, icon: String, col: Color, r: float) -> void:
	var w := maxf(1.0, r * 0.2)
	var soft := Color(col, 0.55)
	match icon:
		"strike":
			_poly(ci, c, r, [-0.55, -0.6, 0.55, -0.6, 0.0, 0.85], col)
			_ln(ci, c, r, Vector2(-0.7, -0.85), Vector2(0.7, -0.85), col, w)
		"crack":
			_pl(ci, c, r, [-0.1, -0.95, 0.25, -0.4, -0.2, 0.0, 0.3, 0.45, -0.05, 0.95], col, w * 1.1)
			_ln(ci, c, r, Vector2(-0.2, 0.0), Vector2(-0.65, -0.2), soft, w * 0.7)
			_ln(ci, c, r, Vector2(0.3, 0.45), Vector2(0.7, 0.6), soft, w * 0.7)
		"gate":
			_arc(ci, c, r, Vector2(0, -0.2), 0.6, PI, TAU, col, w)
			_ln(ci, c, r, Vector2(-0.6, -0.2), Vector2(-0.6, 0.9), col, w)
			_ln(ci, c, r, Vector2(0.6, -0.2), Vector2(0.6, 0.9), col, w)
			_ln(ci, c, r, Vector2(-0.8, 0.9), Vector2(0.8, 0.9), col, w * 0.8)
			_dot(ci, c, r, Vector2(0, 0.25), 0.2, soft)
		"dash":
			_ln(ci, c, r, Vector2(-0.95, -0.45), Vector2(-0.35, -0.45), soft, w * 0.8)
			_ln(ci, c, r, Vector2(-0.95, 0.0), Vector2(-0.15, 0.0), col, w * 0.8)
			_ln(ci, c, r, Vector2(-0.95, 0.45), Vector2(-0.35, 0.45), soft, w * 0.8)
			_poly(ci, c, r, [0.05, -0.6, 0.95, 0.0, 0.05, 0.6], col)
		"shield":
			_pl(ci, c, r, [0, -0.92, 0.75, -0.6, 0.65, 0.25, 0, 0.92, -0.65, 0.25, -0.75, -0.6, 0, -0.92], col, w)
			_ln(ci, c, r, Vector2(0, -0.55), Vector2(0, 0.55), soft, w * 0.8)
		"rift":
			_poly(ci, c, r, _lens(0.45), Color(col, 0.3))
			_pl(ci, c, r, _lens(0.45) + [0.0, -0.95], col, w * 0.9)
			_ln(ci, c, r, Vector2(0.0, -0.6), Vector2(0.06, 0.6), col.lightened(0.5), w * 0.6)
		"converge":
			for d in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
				var dd: Vector2 = d.normalized()
				_ln(ci, c, r, dd * 0.95, dd * 0.4, col, w * 0.8)
				_head(ci, c, r, dd * 0.4, -dd, 0.2, col)
			_dot(ci, c, r, Vector2.ZERO, 0.16, col)
		"eclipse":
			_dot(ci, c, r, Vector2.ZERO, 0.55, col)
			_arc(ci, c, r, Vector2.ZERO, 0.78, -0.4, 2.4, soft, w)
			for k in 4:
				var a := -0.9 + float(k) * 0.75
				_ln(ci, c, r, Vector2(cos(a), sin(a)) * 0.82, Vector2(cos(a), sin(a)) * 0.98, soft, w * 0.6)
		"eye":
			_arc(ci, c, r, Vector2(0, 0.6), 1.05, -2.25, -0.9, col, w)
			_arc(ci, c, r, Vector2(0, -0.6), 1.05, 0.9, 2.25, col, w)
			_dot(ci, c, r, Vector2.ZERO, 0.3, col)
			_dot(ci, c, r, Vector2(0.1, -0.1), 0.09, col.darkened(0.7))
		"blackstar":
			_poly(ci, c, r, _star(5, 0.95, 0.42, -PI * 0.5), col)
			_dot(ci, c, r, Vector2.ZERO, 0.2, col.darkened(0.65))
		"cradle":
			_arc(ci, c, r, Vector2(0, -0.1), 0.75, 0.2, PI - 0.2, col, w * 1.3)
			_dot(ci, c, r, Vector2(0, 0.1), 0.22, col)
			_dot(ci, c, r, Vector2(-0.35, -0.65), 0.08, soft)
			_dot(ci, c, r, Vector2(0.4, -0.75), 0.1, soft)
		"spark":
			_ln(ci, c, r, Vector2(0, -0.9), Vector2(0, 0.9), col, w)
			_ln(ci, c, r, Vector2(-0.9, 0), Vector2(0.9, 0), col, w)
			_ln(ci, c, r, Vector2(-0.5, -0.5), Vector2(0.5, 0.5), soft, w * 0.7)
			_ln(ci, c, r, Vector2(-0.5, 0.5), Vector2(0.5, -0.5), soft, w * 0.7)
			_dot(ci, c, r, Vector2.ZERO, 0.18, col)
		"whip":
			_pl(ci, c, r, [-0.85, 0.75, -0.5, 0.2, 0.0, 0.35, 0.4, -0.2, 0.85, -0.7], col, w)
			_ln(ci, c, r, Vector2(-0.85, 0.75), Vector2(-0.6, 0.45), col, w * 1.8)
			_dot(ci, c, r, Vector2(0.85, -0.7), 0.15, col)
		"focus":
			_ring(ci, c, r, Vector2.ZERO, 0.85, col, w)
			_ring(ci, c, r, Vector2.ZERO, 0.45, soft, w * 0.8)
			_dot(ci, c, r, Vector2.ZERO, 0.18, col)
		"pillar":
			_poly(ci, c, r, [-0.3, -0.6, 0.3, -0.6, 0.3, 0.75, -0.3, 0.75], Color(col, 0.85))
			_poly(ci, c, r, [-0.55, -0.8, 0.55, -0.8, 0.55, -0.58, -0.55, -0.58], col)
			_poly(ci, c, r, [-0.55, 0.73, 0.55, 0.73, 0.55, 0.92, -0.55, 0.92], col)
			_ln(ci, c, r, Vector2(-0.1, -0.5), Vector2(-0.1, 0.65), col.lightened(0.4), w * 0.5)
		"meteor":
			_dot(ci, c, r, Vector2(-0.35, 0.35), 0.42, col)
			_ln(ci, c, r, Vector2(0.0, 0.0), Vector2(0.9, -0.9), soft, w * 0.8)
			_ln(ci, c, r, Vector2(0.15, 0.4), Vector2(0.95, -0.35), soft, w * 0.7)
			_ln(ci, c, r, Vector2(-0.4, -0.15), Vector2(0.35, -0.95), soft, w * 0.7)
		"breath":
			_pl(ci, c, r, [-0.8, 0.0, 0.0, -0.4, 0.9, -0.6], col, w)
			_pl(ci, c, r, [-0.8, 0.0, 0.2, 0.0, 0.95, 0.0], col, w)
			_pl(ci, c, r, [-0.8, 0.0, 0.0, 0.4, 0.9, 0.6], col, w)
			_dot(ci, c, r, Vector2(-0.8, 0.0), 0.16, col)
		"storm":
			_dot(ci, c, r, Vector2(-0.4, -0.3), 0.36, col)
			_dot(ci, c, r, Vector2(0.1, -0.5), 0.44, col)
			_dot(ci, c, r, Vector2(0.5, -0.25), 0.3, col)
			_poly(ci, c, r, [-0.7, -0.3, 0.75, -0.3, 0.75, 0.05, -0.7, 0.05], col)
			_ln(ci, c, r, Vector2(-0.45, 0.25), Vector2(-0.65, 0.85), soft, w * 0.8)
			_ln(ci, c, r, Vector2(0.05, 0.25), Vector2(-0.15, 0.9), soft, w * 0.8)
			_ln(ci, c, r, Vector2(0.55, 0.25), Vector2(0.35, 0.85), soft, w * 0.8)
		"bloom":
			for k in 6:
				var a := float(k) * TAU / 6.0
				_dot(ci, c, r, Vector2(cos(a), sin(a)) * 0.52, 0.33, Color(col, 0.8))
			_dot(ci, c, r, Vector2.ZERO, 0.3, col.darkened(0.5))
		"spear":
			_ln(ci, c, r, Vector2(-0.9, 0.9), Vector2(0.4, -0.4), col, w * 1.1)
			_poly(ci, c, r, [0.15, -0.6, 0.95, -0.95, 0.6, -0.15], col)
			_ln(ci, c, r, Vector2(0.05, -0.05), Vector2(0.3, 0.2), soft, w * 0.7)
		"inferno":
			_flame(ci, c, r, Vector2(-0.55, 0.25), 0.6, Color(col, 0.75))
			_flame(ci, c, r, Vector2(0.55, 0.25), 0.6, Color(col, 0.75))
			_flame(ci, c, r, Vector2(0, 0), 0.95, col)
		"flame":
			_flame(ci, c, r, Vector2(0, 0), 0.95, col)
			_flame(ci, c, r, Vector2(0, 0.35), 0.4, col.lightened(0.55))
		"kindle":
			_ln(ci, c, r, Vector2(-0.85, 0.55), Vector2(0.85, 0.85), col, w)
			_ln(ci, c, r, Vector2(-0.85, 0.85), Vector2(0.85, 0.55), col, w)
			_flame(ci, c, r, Vector2(0, -0.1), 0.6, col)
		"bellows":
			_poly(ci, c, r, [-0.95, -0.55, -0.1, -0.85, -0.1, 0.85, -0.95, 0.55], Color(col, 0.85))
			_poly(ci, c, r, [-0.1, -0.3, 0.3, -0.3, 0.3, 0.3, -0.1, 0.3], col)
			_ln(ci, c, r, Vector2(0.4, -0.35), Vector2(0.9, -0.6), soft, w * 0.7)
			_ln(ci, c, r, Vector2(0.4, 0.0), Vector2(0.98, 0.0), soft, w * 0.7)
			_ln(ci, c, r, Vector2(0.4, 0.35), Vector2(0.9, 0.6), soft, w * 0.7)
		"heart":
			_dot(ci, c, r, Vector2(-0.38, -0.3), 0.42, col)
			_dot(ci, c, r, Vector2(0.38, -0.3), 0.42, col)
			_poly(ci, c, r, [-0.78, -0.12, 0.78, -0.12, 0.0, 0.88], col)
		"up":
			_pl(ci, c, r, [-0.7, 0.3, 0.0, -0.5, 0.7, 0.3], col, w * 1.3)
			_ln(ci, c, r, Vector2(-0.45, 0.75), Vector2(0.45, 0.75), soft, w)
		"wall":
			_rect(ci, c, r, Rect2(-0.85, -0.6, 1.7, 1.2), col, w)
			_ln(ci, c, r, Vector2(-0.85, -0.2), Vector2(0.85, -0.2), col, w * 0.7)
			_ln(ci, c, r, Vector2(-0.85, 0.2), Vector2(0.85, 0.2), col, w * 0.7)
			for x in [-0.3, 0.3]:
				_ln(ci, c, r, Vector2(x, -0.6), Vector2(x, -0.2), soft, w * 0.6)
				_ln(ci, c, r, Vector2(x, 0.2), Vector2(x, 0.6), soft, w * 0.6)
			_ln(ci, c, r, Vector2(0.0, -0.2), Vector2(0.0, 0.2), soft, w * 0.6)
		"stake":
			_poly(ci, c, r, [-0.13, -0.95, 0.13, -0.95, 0.13, 0.55, -0.13, 0.55], col)
			_ln(ci, c, r, Vector2(-0.5, -0.5), Vector2(0.5, -0.5), col, w)
			_flame(ci, c, r, Vector2(-0.4, 0.65), 0.38, Color(col, 0.85))
			_flame(ci, c, r, Vector2(0.4, 0.65), 0.38, Color(col, 0.85))
		"descent":
			_descent(ci, c, r, col, w, 1.0)
		"ascend":
			_descent(ci, c, r, col, w, -1.0)
		"link":
			_ring(ci, c, r, Vector2(-0.35, 0), 0.42, col, w)
			_ring(ci, c, r, Vector2(0.35, 0), 0.42, col, w)
		"sun":
			_dot(ci, c, r, Vector2.ZERO, 0.42, col)
			for k in 8:
				var a := float(k) * TAU / 8.0
				_ln(ci, c, r, Vector2(cos(a), sin(a)) * 0.6, Vector2(cos(a), sin(a)) * 0.95, col, w * 0.8)
		"dust":
			var pts := [Vector2(-0.6, -0.5), Vector2(0.1, -0.7), Vector2(0.65, -0.3), Vector2(-0.3, 0.0), Vector2(0.4, 0.25), Vector2(-0.65, 0.5), Vector2(0.05, 0.7), Vector2(0.7, 0.65)]
			for k in pts.size():
				_dot(ci, c, r, pts[k], 0.12 + 0.08 * float(k % 3), Color(col, 0.65 + 0.12 * float(k % 3)))
		"smoke":
			_ring(ci, c, r, Vector2(-0.4, 0.3), 0.42, col, w * 0.9)
			_ring(ci, c, r, Vector2(0.1, -0.25), 0.5, col, w * 0.9)
			_ring(ci, c, r, Vector2(0.52, 0.35), 0.36, col, w * 0.9)
			_dot(ci, c, r, Vector2(0.1, -0.25), 0.2, soft)
		"wind":
			_pl(ci, c, r, [-0.7, -0.5, -0.35, -0.65, 0.0, -0.5, 0.35, -0.65, 0.7, -0.5], col, w)
			_pl(ci, c, r, [-0.95, 0.0, -0.55, -0.15, -0.15, 0.0, 0.25, -0.15, 0.65, 0.0, 0.95, -0.1], col, w)
			_pl(ci, c, r, [-0.7, 0.5, -0.35, 0.35, 0.0, 0.5, 0.35, 0.35, 0.7, 0.5], col, w)
		"ring":
			_ring(ci, c, r, Vector2.ZERO, 0.68, col, w * 1.5)
			for k in 6:
				var a := float(k) * TAU / 6.0
				_ln(ci, c, r, Vector2(cos(a), sin(a)) * 0.74, Vector2(cos(a), sin(a)) * 0.97, soft, w * 0.7)
		"heap":
			var pts: Array = []
			for k in 9:
				var a := PI + float(k) * PI / 8.0
				pts.append(cos(a) * 0.85)
				pts.append(0.5 + sin(a) * 0.85)
			_poly(ci, c, r, pts, col)
			_dot(ci, c, r, Vector2(-0.3, -0.7), 0.1, soft)
			_dot(ci, c, r, Vector2(0.25, -0.85), 0.08, soft)
			_dot(ci, c, r, Vector2(0.5, -0.55), 0.09, soft)
		"brand":
			_ln(ci, c, r, Vector2(0, -0.95), Vector2(0, 0.2), col, w * 1.2)
			_rect(ci, c, r, Rect2(-0.5, 0.2, 1.0, 0.6), col, w)
			_ln(ci, c, r, Vector2(-0.25, 0.3), Vector2(0.25, 0.7), col.lightened(0.4), w * 0.6)
			_ln(ci, c, r, Vector2(0.25, 0.3), Vector2(-0.25, 0.7), col.lightened(0.4), w * 0.6)
		"oath":
			_poly(ci, c, r, [-0.22, -0.1, 0.22, -0.1, 0.22, 0.92, -0.22, 0.92], Color(col, 0.9))
			_ln(ci, c, r, Vector2(0, -0.35), Vector2(0, -0.1), col, w * 0.6)
			_flame(ci, c, r, Vector2(0, -0.6), 0.42, col.lightened(0.3))
		"whirl":
			var pts: Array = []
			for k in 14:
				var a := float(k) * 0.52
				var rad := 0.1 + float(k) * 0.062
				pts.append(cos(a) * rad)
				pts.append(sin(a) * rad)
			_pl(ci, c, r, pts, col, w)
		"wave":
			_pl(ci, c, r, [-0.95, -0.1, -0.6, -0.5, -0.3, -0.1, 0.0, -0.5, 0.3, -0.1, 0.6, -0.5, 0.95, -0.1], col, w * 1.2)
			_pl(ci, c, r, [-0.75, 0.55, -0.45, 0.25, -0.15, 0.55, 0.15, 0.25, 0.45, 0.55, 0.75, 0.25], soft, w * 0.8)
		"tide":
			_pl(ci, c, r, [-0.95, 0.65, -0.55, 0.15, -0.05, -0.45, 0.4, -0.78, 0.8, -0.6, 0.55, -0.35, 0.25, -0.35], col, w * 1.2)
			_ln(ci, c, r, Vector2(-0.95, 0.85), Vector2(0.95, 0.85), soft, w * 0.8)
			_dot(ci, c, r, Vector2(0.75, -0.1), 0.1, soft)
			_dot(ci, c, r, Vector2(0.55, 0.25), 0.08, soft)
		"drop":
			_poly(ci, c, r, [0, -0.92, 0.42, -0.1, 0.55, 0.35, 0.3, 0.8, 0, 0.92, -0.3, 0.8, -0.55, 0.35, -0.42, -0.1], col)
			_dot(ci, c, r, Vector2(-0.22, 0.3), 0.12, col.lightened(0.55))
		"cloak":
			_pl(ci, c, r, [-0.35, -0.85, 0.35, -0.85, 0.8, 0.9, -0.8, 0.9, -0.35, -0.85], col, w)
			_arc(ci, c, r, Vector2(0, -0.85), 0.35, 0.0, PI, col, w * 0.8)
			_ln(ci, c, r, Vector2(0.0, -0.5), Vector2(0.0, 0.85), soft, w * 0.6)
		"nail":
			_ln(ci, c, r, Vector2(0, -0.55), Vector2(0, 0.75), col, w * 1.2)
			_poly(ci, c, r, [-0.5, -0.85, 0.5, -0.85, 0.5, -0.58, -0.5, -0.58], col)
			_poly(ci, c, r, [-0.16, 0.65, 0.16, 0.65, 0.0, 0.95], col)
		"snow":
			for k in 3:
				var a := float(k) * PI / 3.0
				var d := Vector2(cos(a), sin(a))
				_ln(ci, c, r, -d * 0.92, d * 0.92, col, w * 0.8)
				for s: float in [-1.0, 1.0]:
					var e: Vector2 = d * s
					var p: Vector2 = e * 0.55
					_ln(ci, c, r, p, p + e.rotated(0.65) * 0.3, soft, w * 0.6)
					_ln(ci, c, r, p, p + e.rotated(-0.65) * 0.3, soft, w * 0.6)
		"net":
			for x in [-0.5, 0.0, 0.5]:
				_ln(ci, c, r, Vector2(x, -0.85), Vector2(x, 0.85), col, w * 0.8)
				_ln(ci, c, r, Vector2(-0.85, x), Vector2(0.85, x), col, w * 0.8)
		"shard":
			_poly(ci, c, r, [0, -0.95, 0.4, -0.45, 0.3, 0.6, 0, 0.95, -0.3, 0.6, -0.4, -0.45], Color(col, 0.9))
			_ln(ci, c, r, Vector2(-0.12, -0.55), Vector2(-0.12, 0.5), col.lightened(0.55), w * 0.6)
		"lock":
			_arc(ci, c, r, Vector2(0, -0.3), 0.42, PI, TAU, col, w * 1.1)
			_poly(ci, c, r, [-0.62, -0.1, 0.62, -0.1, 0.62, 0.85, -0.62, 0.85], col)
			_dot(ci, c, r, Vector2(0, 0.3), 0.13, col.darkened(0.7))
			_ln(ci, c, r, Vector2(0, 0.3), Vector2(0, 0.6), col.darkened(0.7), w * 0.7)
		"coffin":
			_pl(ci, c, r, [-0.35, -0.92, 0.35, -0.92, 0.55, -0.45, 0.4, 0.92, -0.4, 0.92, -0.55, -0.45, -0.35, -0.92], col, w)
			_ln(ci, c, r, Vector2(0, -0.55), Vector2(0, 0.45), soft, w * 0.8)
			_ln(ci, c, r, Vector2(-0.25, -0.25), Vector2(0.25, -0.25), soft, w * 0.8)
		"burst":
			for k in 8:
				var a := float(k) * TAU / 8.0 + PI / 8.0
				var d := Vector2(cos(a), sin(a))
				var n := d.orthogonal() * 0.17
				_poly(ci, c, r, [d.x * 0.97, d.y * 0.97, d.x * 0.3 + n.x, d.y * 0.3 + n.y, d.x * 0.3 - n.x, d.y * 0.3 - n.y], Color(col, 0.85 if k % 2 == 0 else 0.6))
			_dot(ci, c, r, Vector2.ZERO, 0.3, col)
		"chain":
			_pl(ci, c, r, [-0.85, 0.6, -0.4, -0.15, -0.1, 0.3, 0.3, -0.55, 0.85, 0.0], col, w)
			_dot(ci, c, r, Vector2(-0.85, 0.6), 0.16, col)
			_dot(ci, c, r, Vector2(-0.1, 0.3), 0.14, col)
			_dot(ci, c, r, Vector2(0.85, 0.0), 0.16, col)
		"bolt":
			_poly(ci, c, r, _bolt_pts(1.0, 0.0), col)
		"bolt_big":
			_poly(ci, c, r, _bolt_pts(0.82, -0.15), col)
			_ln(ci, c, r, Vector2(-0.7, 0.95), Vector2(-0.35, 0.65), soft, w * 0.8)
			_ln(ci, c, r, Vector2(0.7, 0.95), Vector2(0.35, 0.65), soft, w * 0.8)
			_ln(ci, c, r, Vector2(-0.95, 0.97), Vector2(0.95, 0.97), soft, w * 0.7)
		"rod":
			_ln(ci, c, r, Vector2(0, -0.6), Vector2(0, 0.9), col, w)
			_dot(ci, c, r, Vector2(0, -0.7), 0.22, col)
			_ln(ci, c, r, Vector2(-0.65, 0.92), Vector2(0.65, 0.92), col, w * 0.8)
			_ln(ci, c, r, Vector2(-0.45, -0.95), Vector2(-0.3, -0.75), soft, w * 0.6)
			_ln(ci, c, r, Vector2(0.45, -0.95), Vector2(0.3, -0.75), soft, w * 0.6)
		"clock_fwd":
			_arc_arrow(ci, c, r, 0.72, -2.4, 1.5, col, w)
			_dot(ci, c, r, Vector2.ZERO, 0.14, soft)
		"rewind":
			_arc_arrow(ci, c, r, 0.72, -0.75, -4.65, col, w)
			_dot(ci, c, r, Vector2.ZERO, 0.14, soft)
		"cycle":
			_arc_arrow(ci, c, r, 0.72, -2.95, -0.35, col, w)
			_arc_arrow(ci, c, r, 0.72, 0.2, 2.8, col, w)
		"sparkle":
			_sparkle(ci, c, r, Vector2.ZERO, 0.95, col)
			_dot(ci, c, r, Vector2(0.62, -0.62), 0.1, soft)
		"starfall":
			_ln(ci, c, r, Vector2(0.95, -0.95), Vector2(0.15, -0.15), soft, w * 0.6)
			_ln(ci, c, r, Vector2(0.4, -0.95), Vector2(-0.45, 0.45), soft, w * 0.5)
			_sparkle(ci, c, r, Vector2(0.1, -0.1), 0.6, col)
			_sparkle(ci, c, r, Vector2(-0.55, 0.55), 0.45, col)
			_sparkle(ci, c, r, Vector2(0.65, 0.5), 0.3, Color(col, 0.8))
		"needle":
			_ln(ci, c, r, Vector2(-0.8, 0.85), Vector2(0.6, -0.65), col, w * 0.8)
			_ring(ci, c, r, Vector2(0.7, -0.75), 0.17, col, w * 0.7)
			_dot(ci, c, r, Vector2(-0.8, 0.85), 0.08, col.lightened(0.5))
		"wave_out":
			_dot(ci, c, r, Vector2(-0.65, 0.0), 0.18, col)
			_arc(ci, c, r, Vector2(-0.65, 0.0), 0.55, -0.95, 0.95, col, w)
			_arc(ci, c, r, Vector2(-0.65, 0.0), 0.95, -0.85, 0.85, col, w)
			_arc(ci, c, r, Vector2(-0.65, 0.0), 1.35, -0.6, 0.6, soft, w * 0.8)
		"fence":
			for x in [-0.55, 0.0, 0.55]:
				_ln(ci, c, r, Vector2(x, -0.55), Vector2(x, 0.85), col, w * 1.1)
				_poly(ci, c, r, [x - 0.15, -0.5, x + 0.15, -0.5, x, -0.9], col)
			_ln(ci, c, r, Vector2(-0.9, -0.15), Vector2(0.9, -0.15), col, w * 0.8)
			_ln(ci, c, r, Vector2(-0.9, 0.4), Vector2(0.9, 0.4), col, w * 0.8)
		"clock":
			_clock(ci, c, r, col, soft, w)
		"clock_doom":
			_clock(ci, c, r, col, soft, w)
			_pl(ci, c, r, [0.2, -0.98, 0.0, -0.4, 0.3, 0.0, 0.05, 0.5, 0.25, 0.98], col.lightened(0.6), w * 0.7)
		"hourglass":
			_pl(ci, c, r, [-0.6, -0.88, 0.6, -0.88, -0.6, 0.88, 0.6, 0.88, -0.6, -0.88], col, w)
			_poly(ci, c, r, [-0.38, 0.86, 0.38, 0.86, 0.0, 0.4], col)
			_dot(ci, c, r, Vector2(0, 0.0), 0.08, col)
		"slash":
			_cut(ci, c, r, Vector2(-0.9, 0.78), Vector2(0.9, -0.78), col, 0.18)
			_ln(ci, c, r, Vector2(-0.15, -0.5), Vector2(0.05, -0.2), soft, w * 0.6)
			_ln(ci, c, r, Vector2(0.15, -0.65), Vector2(0.35, -0.35), soft, w * 0.6)
		"cut_curve":
			_arc(ci, c, r, Vector2(0.35, 0.75), 1.15, -2.7, -0.95, col, w * 1.7)
			_head(ci, c, r, Vector2(0.35 + cos(-0.95) * 1.15, 0.75 + sin(-0.95) * 1.15), Vector2(cos(-0.95 + PI * 0.5), sin(-0.95 + PI * 0.5)), 0.26, col)
			_dot(ci, c, r, Vector2(-0.75, -0.1), 0.1, soft)
		"slash2":
			_cut(ci, c, r, Vector2(-0.95, 0.45), Vector2(0.55, -0.95), col, 0.14)
			_cut(ci, c, r, Vector2(-0.55, 0.95), Vector2(0.95, -0.45), col, 0.14)
		"cut_h":
			_cut(ci, c, r, Vector2(-0.98, 0.1), Vector2(0.98, 0.1), col, 0.16)
			_ln(ci, c, r, Vector2(-0.8, -0.45), Vector2(-0.3, -0.45), soft, w * 0.6)
			_ln(ci, c, r, Vector2(-0.6, -0.25), Vector2(0.0, -0.25), soft, w * 0.6)
		"aura":
			_ring(ci, c, r, Vector2.ZERO, 0.95, Color(col, 0.35), w * 0.7)
			_poly(ci, c, r, [0, -0.95, 0.15, -0.7, 0.15, 0.25, -0.15, 0.25, -0.15, -0.7], col)
			_poly(ci, c, r, [-0.45, 0.25, 0.45, 0.25, 0.45, 0.4, -0.45, 0.4], col)
			_ln(ci, c, r, Vector2(0, 0.4), Vector2(0, 0.85), col, w * 1.1)
		"cut_v":
			_cut(ci, c, r, Vector2(0.05, -0.98), Vector2(-0.05, 0.98), col, 0.22)
			_ln(ci, c, r, Vector2(-0.6, -0.65), Vector2(-0.3, -0.35), soft, w * 0.7)
			_ln(ci, c, r, Vector2(0.6, -0.65), Vector2(0.3, -0.35), soft, w * 0.7)
		"fan":
			_cut(ci, c, r, Vector2(-0.75, 0.85), Vector2(0.0, -0.95), col, 0.1)
			_cut(ci, c, r, Vector2(-0.75, 0.85), Vector2(0.72, -0.55), col, 0.1)
			_cut(ci, c, r, Vector2(-0.75, 0.85), Vector2(0.95, 0.2), col, 0.1)
			_dot(ci, c, r, Vector2(-0.75, 0.85), 0.14, col)
		"slash_doom":
			_dot(ci, c, r, Vector2(0.15, -0.1), 0.5, Color(col, 0.35))
			_ring(ci, c, r, Vector2(0.15, -0.1), 0.58, soft, w * 0.8)
			_cut(ci, c, r, Vector2(-0.95, 0.85), Vector2(0.95, -0.85), col, 0.2)
		"slash_x":
			_cut(ci, c, r, Vector2(-0.9, 0.8), Vector2(0.9, -0.8), col, 0.15)
			_cut(ci, c, r, Vector2(-0.9, -0.8), Vector2(0.9, 0.8), col, 0.15)
		_:
			_ring(ci, c, r, Vector2.ZERO, 0.7, col, w)
			_ln(ci, c, r, Vector2(-0.4, -0.4), Vector2(0.4, 0.4), col, w)


## 장비 아이콘 15 (R6 review_P §5 ① — 장비 목록이 이름 글 상자뿐이었다). 마법 아이콘과 달리 장비마다 제 색(재질)으로 그린다.
## 반지 셋은 같은 금 띠 + 속성 색 보석. 그림자는 호출 쪽. 쓰는 곳: TSetup 장비 목록 칸 왼쪽 (반지름 10 = 20px)
static func equip(ci: Object, c: Vector2, id: String, r: float) -> void:
	var w := maxf(1.0, r * 0.16)
	match id:
		"black_cup": # 검은 잔: 먹 잔 + 붉은 술 + 연보라 테
			_poly(ci, c, r, [-0.7, -0.55, 0.7, -0.55, 0.42, 0.1, -0.42, 0.1], Color("#3a3048"))
			_poly(ci, c, r, [-0.62, -0.5, 0.62, -0.5, 0.56, -0.36, -0.56, -0.36], Color("#ff4f6a"))
			_ln(ci, c, r, Vector2(-0.72, -0.58), Vector2(0.72, -0.58), Color("#d8c8ff"), w)
			_ln(ci, c, r, Vector2(0, 0.1), Vector2(0, 0.62), Color("#5a4c6a"), w * 1.4)
			_poly(ci, c, r, [-0.45, 0.72, 0.45, 0.72, 0.3, 0.56, -0.3, 0.56], Color("#5a4c6a"))
			_ln(ci, c, r, Vector2(-0.3, -0.3), Vector2(-0.18, -0.05), Color(1, 1, 1, 0.35), w * 0.8)
		"kaleido": # 만화경: 기운 놋쇠 통 + 끝의 색유리 셋
			_poly(ci, c, r, [-0.85, 0.45, -0.6, 0.72, 0.38, -0.2, 0.12, -0.47], Color("#b88a3a"))
			_ln(ci, c, r, Vector2(-0.5, 0.2), Vector2(-0.25, 0.47), Color("#ffe08a"), w)
			_dot(ci, c, r, Vector2(0.45, -0.5), 0.42, Color("#2a1e3d"))
			_ring(ci, c, r, Vector2(0.45, -0.5), 0.42, Color("#ffe08a"), w)
			_dot(ci, c, r, Vector2(0.32, -0.62), 0.13, Color("#ff7ad8"))
			_dot(ci, c, r, Vector2(0.6, -0.55), 0.13, Color("#7ad8ff"))
			_dot(ci, c, r, Vector2(0.42, -0.32), 0.13, Color("#ffcf4a"))
		"notebook": # 마녀의 수첩: 가죽 표지 + 종이 끝 + 금 별
			_poly(ci, c, r, [-0.5, -0.75, 0.62, -0.75, 0.62, 0.75, -0.5, 0.75], Color("#f0e6d0"))
			_poly(ci, c, r, [-0.62, -0.82, 0.5, -0.82, 0.5, 0.68, -0.62, 0.68], Color("#8a4a2a"))
			_ln(ci, c, r, Vector2(-0.45, -0.82), Vector2(-0.45, 0.68), Color("#5a2e18"), w)
			_sparkle(ci, c, r, Vector2(0.04, -0.08), 0.32, Color("#ffe08a"))
		"swift_boots": # 바람 신발: 장화 + 날개 + 바람 줄
			_poly(ci, c, r, [-0.3, -0.75, 0.15, -0.75, 0.2, 0.25, 0.75, 0.42, 0.75, 0.72, -0.35, 0.72], Color("#6a8a5a"))
			_ln(ci, c, r, Vector2(-0.35, 0.62), Vector2(0.75, 0.62), Color("#3a4a30"), w * 1.2)
			_poly(ci, c, r, [0.15, -0.55, 0.62, -0.85, 0.5, -0.5, 0.75, -0.55, 0.2, -0.25], Color("#e6f0ff"))
			_ln(ci, c, r, Vector2(-0.95, -0.2), Vector2(-0.5, -0.2), Color("#b9e8ff", 0.8), w * 0.8)
			_ln(ci, c, r, Vector2(-0.95, 0.15), Vector2(-0.55, 0.15), Color("#b9e8ff", 0.8), w * 0.8)
		"mana_spring": # 마력 샘: 보랏빛 물방울 + 물결 고리
			_arc(ci, c, r, Vector2(0, 0.62), 0.75, PI * 0.1, PI * 0.9, Color("#9a7cff", 0.8), w)
			_flame(ci, c, r, Vector2(0, -0.12), 0.62, Color("#9a7cff"))
			_dot(ci, c, r, Vector2(0, 0.08), 0.32, Color("#c9b8ff"))
			_dot(ci, c, r, Vector2(-0.12, -0.05), 0.1, Color(1, 1, 1, 0.8))
		"ember_ring", "tide_ring", "storm_ring": # 속성 반지: 금 띠 + 보석
			var gem: Color = {"ember_ring": Color("#ff7a3a"), "tide_ring": Color("#3fb0ff"), "storm_ring": Color("#ffdd4a")}[id]
			_ring(ci, c, r, Vector2(0, 0.22), 0.52, Color("#a07a2a"), w * 2.0)
			_ring(ci, c, r, Vector2(0, 0.22), 0.52, Color("#ffe08a"), w * 0.9)
			_poly(ci, c, r, [0, -0.85, 0.36, -0.45, 0, -0.12, -0.36, -0.45], gem)
			_poly(ci, c, r, [0, -0.85, 0.36, -0.45, 0, -0.45], gem.lightened(0.4))
		"mirror_shard": # 거울 조각: 비스듬한 유리 조각 + 반짝
			_poly(ci, c, r, [-0.45, -0.85, 0.55, -0.4, 0.3, 0.85, -0.6, 0.35], Color("#b9e0f0"))
			_poly(ci, c, r, [-0.45, -0.85, 0.55, -0.4, -0.05, -0.15], Color("#eafcff"))
			_ln(ci, c, r, Vector2(-0.6, 0.35), Vector2(0.3, 0.85), Color("#5a8aa0"), w)
		"star_shard": # 별 조각: 금 별 + 흰 속
			_poly(ci, c, r, _star(5, 0.95, 0.42, -PI * 0.5), Color("#ffcf4a"))
			_poly(ci, c, r, _star(5, 0.45, 0.2, -PI * 0.5), Color("#fff6d6"))
		"iron_heart": # 강철 심장: 회색 하트 + 징 + 윤기
			_poly(ci, c, r, [0.0, 0.85, -0.85, -0.05, -0.75, -0.55, -0.4, -0.75, 0.0, -0.45, 0.4, -0.75, 0.75, -0.55, 0.85, -0.05], Color("#8a94a4"))
			_poly(ci, c, r, [0.0, 0.85, 0.85, -0.05, 0.75, -0.55, 0.4, -0.75, 0.0, -0.45], Color("#5a6474"))
			_dot(ci, c, r, Vector2(-0.45, -0.3), 0.1, Color("#d8e0ea"))
			_dot(ci, c, r, Vector2(0.45, -0.3), 0.1, Color("#d8e0ea"))
			_dot(ci, c, r, Vector2(0, 0.35), 0.1, Color("#d8e0ea"))
		"hourglass_charm": # 모래시계 펜던트: 금 모래시계 + 고리
			_ring(ci, c, r, Vector2(0, -0.88), 0.14, Color("#ffe08a"), w * 0.8)
			draw(ci, c + Vector2(0, 0.1 * r), "hourglass", Color("#ffcf7a"), r * 0.82)
		"ash_charm": # 재의 부적: 누런 종이 부적 + 붉은 표식 + 재 점
			_poly(ci, c, r, [-0.42, -0.8, 0.42, -0.8, 0.42, 0.7, 0.0, 0.88, -0.42, 0.7], Color("#d8c8a8"))
			_ln(ci, c, r, Vector2(0, -0.55), Vector2(0, 0.45), Color("#c0304a"), w * 1.2)
			_ln(ci, c, r, Vector2(-0.25, -0.2), Vector2(0.25, -0.2), Color("#c0304a"), w * 1.2)
			_ring(ci, c, r, Vector2(0, 0.18), 0.18, Color("#c0304a"), w * 0.8)
			_dot(ci, c, r, Vector2(0.7, -0.5), 0.08, Color("#8a8090"))
			_dot(ci, c, r, Vector2(0.62, 0.1), 0.06, Color("#8a8090"))
		"feather_charm": # 깃털 부적: 흰 깃털 + 깃대
			_poly(ci, c, r, [0.55, -0.85, 0.25, 0.1, -0.35, 0.65, -0.1, -0.05], Color("#f4f0ff"))
			_poly(ci, c, r, [0.55, -0.85, -0.1, -0.05, -0.35, 0.65, -0.35, 0.1], Color("#c9c0dc"))
			_ln(ci, c, r, Vector2(0.55, -0.85), Vector2(-0.6, 0.9), Color("#8a7fa3"), w)
		_: # 없음: 점선 원
			for k in 8:
				var a := TAU * float(k) / 8.0
				_arc(ci, c, r, Vector2.ZERO, 0.6, a, a + 0.42, Color("#8a7fa3"), w)


# ── 공통 조각 ─────────────────────────────────────────────

static func _ln(ci: Object, c: Vector2, r: float, a: Vector2, b: Vector2, col: Color, w: float) -> void:
	ci.draw_line(c + a * r, c + b * r, col, w)


## 짝수 개의 float(x, y, x, y …)로 꺾은선
static func _pl(ci: Object, c: Vector2, r: float, xy: Array, col: Color, w: float) -> void:
	var p := PackedVector2Array()
	for i in range(0, xy.size() - 1, 2):
		p.append(c + Vector2(float(xy[i]), float(xy[i + 1])) * r)
	ci.draw_polyline(p, col, w)


static func _poly(ci: Object, c: Vector2, r: float, xy: Array, col: Color) -> void:
	var p := PackedVector2Array()
	for i in range(0, xy.size() - 1, 2):
		p.append(c + Vector2(float(xy[i]), float(xy[i + 1])) * r)
	ci.draw_colored_polygon(p, col)


static func _dot(ci: Object, c: Vector2, r: float, o: Vector2, rad: float, col: Color) -> void:
	ci.draw_circle(c + o * r, rad * r, col)


static func _ring(ci: Object, c: Vector2, r: float, o: Vector2, rad: float, col: Color, w: float) -> void:
	ci.draw_arc(c + o * r, rad * r, 0.0, TAU, 28, col, w)


static func _arc(ci: Object, c: Vector2, r: float, o: Vector2, rad: float, a0: float, a1: float, col: Color, w: float) -> void:
	ci.draw_arc(c + o * r, rad * r, a0, a1, 18, col, w)


static func _rect(ci: Object, c: Vector2, r: float, rc: Rect2, col: Color, w: float) -> void:
	ci.draw_rect(Rect2(c + rc.position * r, rc.size * r), col, false, w)


## 화살촉: tip 쪽으로 향하는 작은 삼각형 (at = 밑변 가운데, dir = 방향)
static func _head(ci: Object, c: Vector2, r: float, at: Vector2, dir: Vector2, s: float, col: Color) -> void:
	var n := dir.orthogonal() * s * 0.7
	_poly(ci, c, r, [at.x + dir.x * s, at.y + dir.y * s, at.x + n.x, at.y + n.y, at.x - n.x, at.y - n.y], col)


## 둥근 화살 (a0 → a1, 끝에 화살촉)
static func _arc_arrow(ci: Object, c: Vector2, r: float, rad: float, a0: float, a1: float, col: Color, w: float) -> void:
	ci.draw_arc(c, rad * r, a0, a1, 20, col, w)
	var end := Vector2(cos(a1), sin(a1)) * rad
	var dir := Vector2(-sin(a1), cos(a1)) * (1.0 if a1 > a0 else -1.0)
	_head(ci, c, r, end - dir * 0.05, dir, 0.3, col)


## 베인 자국: a→b 로 가늘어지는 마름모 띠 (가운데 두께 t)
static func _cut(ci: Object, c: Vector2, r: float, a: Vector2, b: Vector2, col: Color, t: float) -> void:
	var m := (a + b) * 0.5
	var n := (b - a).normalized().orthogonal() * t
	_poly(ci, c, r, [a.x, a.y, m.x + n.x, m.y + n.y, b.x, b.y, m.x - n.x, m.y - n.y], col)


static func _flame(ci: Object, c: Vector2, r: float, o: Vector2, s: float, col: Color) -> void:
	var base := [0.0, -1.0, 0.45, -0.35, 0.3, 0.15, 0.55, 0.55, 0.0, 1.0, -0.55, 0.55, -0.3, 0.15, -0.45, -0.35]
	var pts: Array = []
	for i in range(0, base.size(), 2):
		pts.append(o.x + float(base[i]) * s)
		pts.append(o.y + float(base[i + 1]) * s)
	_poly(ci, c, r, pts, col)


static func _sparkle(ci: Object, c: Vector2, r: float, o: Vector2, s: float, col: Color) -> void:
	var base := [0.0, -1.0, 0.22, -0.22, 1.0, 0.0, 0.22, 0.22, 0.0, 1.0, -0.22, 0.22, -1.0, 0.0, -0.22, -0.22]
	var pts: Array = []
	for i in range(0, base.size(), 2):
		pts.append(o.x + float(base[i]) * s)
		pts.append(o.y + float(base[i + 1]) * s)
	_poly(ci, c, r, pts, col)


static func _star(n: int, ro: float, ri: float, a0: float) -> Array:
	var pts: Array = []
	for k in n * 2:
		var a := a0 + float(k) * PI / float(n)
		var rad := ro if k % 2 == 0 else ri
		pts.append(cos(a) * rad)
		pts.append(sin(a) * rad)
	return pts


## 세로 렌즈(위 (0,-0.95) → 아래 (0,0.95) → 위, 가운데 폭 hw)
static func _lens(hw: float) -> Array:
	var pts: Array = []
	for k in 7:
		var t := float(k) / 6.0
		var y := -0.95 + 1.9 * t
		pts.append(-hw * sin(t * PI))
		pts.append(y)
	for k in range(1, 6):
		var t := float(k) / 6.0
		var y := 0.95 - 1.9 * t
		pts.append(hw * sin(t * PI))
		pts.append(y)
	return pts


static func _bolt_pts(s: float, dy: float) -> Array:
	var base := [0.25, -0.95, -0.45, 0.1, 0.0, 0.1, -0.25, 0.95, 0.5, -0.2, 0.05, -0.2]
	var pts: Array = []
	for i in range(0, base.size(), 2):
		pts.append(float(base[i]) * s)
		pts.append(float(base[i + 1]) * s + dy)
	return pts


static func _descent(ci: Object, c: Vector2, r: float, col: Color, w: float, sg: float) -> void:
	_ln(ci, c, r, Vector2(-0.6, -0.92 * sg), Vector2(-0.3, -0.35 * sg), Color(col, 0.55), w * 0.8)
	_ln(ci, c, r, Vector2(0.0, -0.98 * sg), Vector2(0.0, -0.3 * sg), Color(col, 0.55), w * 0.8)
	_ln(ci, c, r, Vector2(0.6, -0.92 * sg), Vector2(0.3, -0.35 * sg), Color(col, 0.55), w * 0.8)
	_ln(ci, c, r, Vector2(0, -0.15 * sg), Vector2(0, 0.45 * sg), col, w * 1.3)
	_poly(ci, c, r, [-0.5, 0.35 * sg, 0.5, 0.35 * sg, 0.0, 0.92 * sg], col)


static func _clock(ci: Object, c: Vector2, r: float, col: Color, soft: Color, w: float) -> void:
	_dot(ci, c, r, Vector2.ZERO, 0.85, Color(col, 0.18))
	_ring(ci, c, r, Vector2.ZERO, 0.85, col, w)
	_ln(ci, c, r, Vector2(0, 0), Vector2(0, -0.58), col, w)
	_ln(ci, c, r, Vector2(0, 0), Vector2(0.42, 0.22), col, w * 0.9)
	_dot(ci, c, r, Vector2.ZERO, 0.1, col)
	_ln(ci, c, r, Vector2(0, -0.85), Vector2(0, -0.68), soft, w * 0.7)
