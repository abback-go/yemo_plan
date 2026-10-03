extends StaticBody2D
## 별 수정 장벽 (docs/chapter2.md 5절 · bible/progression.md 4절 "별 수정 장벽 — 불꽃 방벽"). 길을 막는 보랏빛 수정 덩어리.
## 장벽 한가운데의 별 수정 심장이 가까이 온 세라에게 별 조각을 쏜다 → **불꽃 방벽으로 되쏘아(Hit.kind = reflect) 맞히면 산산조각.**
## 다른 불은 튕겨 낸다. 깨진 기록은 영구(GameState collected "cw_<방>_<id>") + done_flag.
## {t = "k_crystal_wall", x, y, w = 2, h = 5, done_flag = "", period = 2.2, range = 12}  (x·y = 왼쪽 위 칸)

const KE := preload("res://enemies/ch2/k_enemy.gd")
const KArt := preload("res://world/entities/ch2/k_art.gd")
const STAR := Color("#c89aff")

var key := ""
var done_flag := ""
var period := 2.2
var reach_t := 12.0
var size_px := Vector2(32, 80)
var _t := 0.0
var _shot_t := 1.0
var _broken := false
var _break_t := 0.0
var _flash := 0.0
var _shape: CollisionShape2D
var _hurt: Area2D


func setup(room: Room, e: Dictionary, eid: String) -> void:
	key = "cw_%s_%s" % [room.data.id, eid]
	done_flag = String(e.get("done_flag", ""))
	period = float(e.get("period", 2.2))
	reach_t = float(e.get("range", 12.0))
	size_px = Vector2(float(e.get("w", 2)), float(e.get("h", 5))) * 16.0
	position = room.tile_pos(e)
	add_to_group(&"k_crystal_wall")
	collision_layer = GameConst.L_WORLD
	collision_mask = 0
	z_index = 0
	_shape = CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = size_px
	_shape.shape = rs
	_shape.position = size_px * 0.5
	add_child(_shape)
	_hurt = Area2D.new()
	_hurt.collision_layer = GameConst.L_ENEMY_HURT
	_hurt.collision_mask = 0
	_hurt.monitoring = false
	var hs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = size_px + Vector2(6, 6)
	hs.shape = hr
	hs.position = size_px * 0.5
	_hurt.add_child(hs)
	add_child(_hurt)
	add_child(LightGlow.make(size_px * 0.5, size_px.y * 0.9, STAR, 0.35))
	if GameState.is_collected(key) or (done_flag != "" and GameState.has_flag(done_flag)):
		_broken = true
		_break_t = 9.0
		_shape.disabled = true
		_hurt.monitorable = false
		visible = false


func is_alive() -> bool:
	return not _broken


func _heart() -> Vector2:
	return global_position + size_px * 0.5


func take_hit(hit: Hit) -> void:
	if _broken:
		return
	if hit.kind != &"reflect":
		_flash = 0.12
		KE.snd(&"block", &"block", -4.0, 0.1)
		KE.star_burst(_heart() + Vector2(signf(hit.source_pos.x - _heart().x) * size_px.x * 0.5, 0), 5, STAR, 70.0, 0.25)
		return
	_shatter()


func _shatter() -> void:
	_broken = true
	_break_t = 0.0
	GameState.mark_collected(key)
	if done_flag != "":
		GameState.set_flag(done_flag)
	_shape.set_deferred("disabled", true)
	_hurt.set_deferred("monitorable", false)
	Fx.shake(0.35, 0.3)
	Fx.hitstop(0.05)
	KE.snd(&"crumble", &"crumble", 2.0)
	KE.snd(&"star_burst", &"explode", 0.0)
	for i in 4:
		KE.star_burst(global_position + Vector2(randf() * size_px.x, randf() * size_px.y), 14, STAR, 180.0, 0.7)
	Fx.ring(_heart(), 6.0, size_px.y, STAR, 0.45, 3.0)
	var hud := get_tree().get_first_node_in_group(&"hud")
	if hud and hud.has_method("banner"):
		hud.banner("별 수정 장벽이 깨졌다!", 1.2)


func _physics_process(delta: float) -> void:
	_t += delta
	_flash = maxf(_flash - delta, 0.0)
	if _broken:
		_break_t += delta
		if _break_t > 0.8:
			visible = false
			set_physics_process(false)
		queue_redraw()
		return
	var p := get_tree().get_first_node_in_group(GameConst.GROUP_PLAYER) as Player
	if p and p.is_alive() and not Story.busy() and _heart().distance_to(p.center()) < reach_t * GameConst.TILE:
		_shot_t -= delta * Fx.enemy_time
		if _shot_t <= 0.0:
			_shot_t = period
			var from := _heart() + Vector2(signf(p.center().x - _heart().x) * (size_px.x * 0.5 + 6.0), 0)
			KE.shard(from, (p.center() - from).normalized(), 5.5 * GameConst.TILE, {"radius": 4.0, "life": 5.0, "cause": "crystal_wall"})
			KE.snd(&"star_twinkle", &"sniper_shot", -6.0)
	else:
		_shot_t = minf(_shot_t, 1.0)
	queue_redraw()


func _draw() -> void:
	var w := size_px.x
	var h := size_px.y
	if _broken:
		var k := clampf(1.0 - _break_t / 0.8, 0.0, 1.0)
		for i in 8:
			var a := i * 2.4
			var p := size_px * 0.5 + Vector2(cos(a), sin(a)) * (_break_t * 70.0) + Vector2(0, _break_t * _break_t * 120.0)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-3, 2), p + Vector2(0, -4), p + Vector2(3, 2)]), Color(STAR, k))
		return
	var warn := clampf(1.0 - _shot_t / 0.6, 0.0, 1.0)
	var base := STAR.darkened(0.45)
	# 수정 기둥 여럿이 뭉친 덩어리
	var cols := int(w / 8.0) + 1
	for i in cols:
		var x := 2.0 + i * (w - 4.0) / maxf(cols - 1, 1)
		var top := 4.0 + float((i * 7) % 5) * 3.0
		draw_colored_polygon(PackedVector2Array([Vector2(x - 6, h), Vector2(x - 4, top + 6), Vector2(x, top), Vector2(x + 4, top + 6), Vector2(x + 6, h)]), base.lerp(STAR, 0.2 + 0.1 * (i % 2)))
		draw_line(Vector2(x, top + 2), Vector2(x - 2, h - 2), Color(1, 1, 1, 0.25), 1.0)
	draw_rect(Rect2(0, h * 0.35, w, h * 0.65), Color(base, 0.55))
	# 심장 (쏘기 직전 붉게)
	var c := size_px * 0.5
	var hc := STAR.lerp(KE.DANGER, warn * 0.8)
	KArt.glow(self, c, 16.0 + 4.0 * sin(_t * 3.0), Color(hc, 0.8), 3)
	KArt.star4(self, c, 6.0 + warn * 3.0, Color(1, 0.95, 1.0, 0.95))
	if _flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size_px), Color(1, 1, 1, 0.35))
	KArt.twinkles(self, Rect2(Vector2(-4, -6), size_px + Vector2(8, 8)), 5, _t, Color(1, 0.95, 1.0, 0.8), int(position.x))
