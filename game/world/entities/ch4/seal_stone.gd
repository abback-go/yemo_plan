extends StaticBody2D
## 금빛 봉인석 (docs/bible/progression.md 4절·docs/chapter4.md 7.5절): 길을 막는 둥근 돌에 금빛 봉인 문양. **유성 낙화(Hit.kind = meteor)**로만 부서진다.
## 다른 공격은 "팅" — 처음 한 번 안내 문구("하늘에서 떨어지는 큰 힘이라면…"). 부수면 flag(기본 "seal_<방>_<id>")가 서고 다시 나오지 않는다.
## 방 데이터: {t:"seal_stone", x, y(바닥 행), h(막는 높이 칸, 기본 2 — 2칸마다 돌 하나), flag, id}

const ART := preload("res://world/entities/ch4/art.gd")
const H := preload("res://enemies/ch4/holy.gd")

var flag := ""
var stones := 1
var _broken := false
var _crack := 0.0
var _t := 0.0
var _hurt: Area2D
var _shape: CollisionShape2D


func setup(room: Room, e: Dictionary, eid: String) -> void:
	position = room.tile_pos(e) + Vector2(8, 0)
	flag = String(e.get("flag", "seal_%s_%s" % [room.data.id, eid]))
	stones = maxi(int(float(e.get("h", 2)) / 2.0), 1)
	collision_layer = GameConst.L_WORLD
	collision_mask = 0
	z_index = 1
	if GameState.has_flag(flag):
		_broken = true


func _ready() -> void:
	if _broken:
		queue_free()
		return
	var h := stones * 32.0
	_shape = CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(28, h)
	_shape.shape = rs
	_shape.position = Vector2(0, -h * 0.5)
	add_child(_shape)
	_hurt = Area2D.new()
	_hurt.collision_layer = GameConst.L_ENEMY_HURT
	_hurt.collision_mask = 0
	_hurt.monitoring = false
	var cs := CollisionShape2D.new()
	var rs2 := RectangleShape2D.new()
	rs2.size = Vector2(30, h + 2)
	cs.shape = rs2
	cs.position = Vector2(0, -h * 0.5)
	_hurt.add_child(cs)
	add_child(_hurt)


func is_alive() -> bool:
	return not _broken


func take_hit(hit: Hit) -> void:
	if _broken:
		return
	if hit.kind == &"meteor":
		_crack += 0.55 if hit.damage < 500 else 1.0
		H.snd(&"meteor_impact", &"crumble", -2.0)
		if _crack >= 1.0:
			_shatter()
		return
	Sfx.play(&"block", -4.0, 0.1)
	H.sparkle(global_position + Vector2(0, -16), 6, 6.0)
	if not GameState.has_flag("tp_seal_hint"):
		GameState.set_flag("tp_seal_hint")
		Story.toast("금빛 봉인이다. 불길로는 꿈쩍도 않는다… 하늘에서 떨어지는 큰 힘이라면?", 3.2)


func _shatter() -> void:
	_broken = true
	GameState.set_flag(flag)
	_shape.set_deferred("disabled", true)
	_hurt.set_deferred("monitorable", false)
	Sfx.play(&"crumble", 2.0, 0.0)
	Fx.shake(0.4, 0.4)
	Fx.flash(Color(1.0, 0.9, 0.6, 0.25), 0.25)
	for i in stones:
		var c := global_position + Vector2(0, -16 - i * 32)
		Fx.burst(c, 30, {
			spread = 180.0, speed_min = 60.0, speed_max = 220.0, lifetime = 0.8, gravity = Vector2(0, 500),
			gradient = Palette.fade_gradient(Color("#7a7690")), size_min = 2.0, size_max = 4.0,
		})
		H.sparkle(c, 24, 12.0, 40.0, 1.0)
		Fx.ring(c, 6.0, 50.0, H.GOLD, 0.5, 3.0)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(queue_free)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	for i in stones:
		ART.seal_stone(self, Vector2(0, -i * 32.0), _t + i, 1.0 if not _broken else 0.0, _crack)
