class_name BurnGround
extends Node2D
## 불바다: 땅 위 직사각형 안의 적을 일정 시간 동안 태운다 (화염 폭풍 Lv3, 유성 낙화 Lv3, 불꽃 날개 Lv3 불씨).

var size := Vector2(64, 16)
var dps := 60.0
var life := 2.0
var kind := &"storm"
var fox := false
var _t := 0.0
var _tick := 0.0


static func spawn(at_ground: Vector2, w: float, p_dps: float, p_life: float, p_kind: StringName, p_fox := false) -> BurnGround:
	var b := BurnGround.new()
	b.global_position = at_ground
	b.size = Vector2(w, 18)
	b.dps = p_dps
	b.life = p_life
	b.kind = p_kind
	b.fox = p_fox
	b.material = Fx.add_material
	b.z_index = 3
	Fx.effect_parent().add_child(b)
	return b


func _physics_process(delta: float) -> void:
	_t += delta
	_tick -= delta
	if _t >= life:
		queue_free()
		return
	if _tick <= 0.0:
		_tick = 0.25
		var rect := Rect2(global_position + Vector2(-size.x * 0.5, -size.y - 8.0), size + Vector2(0, 8))
		for e in get_tree().get_nodes_in_group(GameConst.GROUP_ENEMY):
			var en := e as EnemyBase
			if en == null or not en.is_alive():
				continue
			var body := Rect2(en.global_position + Vector2(-en.body_size.x * 0.5, -en.body_size.y), en.body_size)
			if rect.intersects(body):
				var h := Hit.make(maxi(int(round(dps * 0.25)), 1), kind, global_position)
				h.hitstop = 0.0
				en.take_hit(h)
	queue_redraw()


func _draw() -> void:
	var fade := clampf(minf(_t / 0.15, (life - _t) / 0.4), 0.0, 1.0)
	var col := Color(0.45, 0.8, 1.0) if fox else Palette.FIRE_OUT
	var hot := Color(0.85, 0.97, 1.0) if fox else Palette.FIRE_HOT
	var n := maxi(int(size.x / 6.0), 3)
	for i in n:
		var x := -size.x * 0.5 + (i + 0.5) * size.x / n
		var h := (6.0 + 6.0 * absf(sin(_t * 9.0 + i * 1.3))) * fade
		draw_colored_polygon(PackedVector2Array([Vector2(x - 3, 0), Vector2(x + sin(_t * 7.0 + i) * 1.5, -h), Vector2(x + 3, 0)]), Color(col, 0.8 * fade))
		draw_line(Vector2(x, 0), Vector2(x, -h * 0.5), Color(hot, 0.7 * fade), 1.0)
	draw_rect(Rect2(-size.x * 0.5, -2, size.x, 2), Color(hot, 0.5 * fade))
