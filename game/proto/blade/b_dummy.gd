class_name BDummy
extends PDummy
## 빗자루 검 데모 허수아비 (PDummy 그대로 + 두 가지).
## 1) 맞으면 1~2프레임 새하얗게 (PDummy의 흰빛을 1 넘게 올려 둠 — 멈춤 동안엔 그대로 하얗다).
## 2) 틈 자국: 큰 검기(회전 가르기·공간참, opts.scar)에 맞으면 벤 자리에 보랏빛 틈 자국이 남는다(최대 SCAR_MAX, SCAR_LIFE초).
##    검이 아닌 공격(마법, opts.blade 없음)이 닿으면 자국이 한꺼번에 터진다 — 자국 하나당 SCAR_DMG.
##    두 모드를 오가게 만드는 연결 (docs/eska-turn/README.md §0-3).

const SCAR_MAX := 3
const SCAR_LIFE := 5.0
const SCAR_DMG := 110
const SCAR_LEN := 24.0
const SCAR_OPEN := 0.08

var scars: Array = [] ## [자리(이 노드 기준), 각도(전역), 나이]
var bursts := 0 ## 자국이 터진 횟수 (시험용)


func take_hit(dmg: int, from: Vector2, opts := {}) -> void:
	super.take_hit(dmg, from, opts)
	_flash = 1.2 if bool(opts.get("heavy", false)) else 1.1
	if bool(opts.get("scar", false)):
		_add_scar(opts.get("scar_at", center()), float(opts.get("scar_angle", 0.0)))
	elif not bool(opts.get("blade", false)) and not scars.is_empty():
		_burst_scars(from)


func _add_scar(at: Vector2, angle: float) -> void:
	if scars.size() >= SCAR_MAX:
		scars.pop_front()
	var p := at - global_position
	var r := hit_rect()
	var top := r.position.y - global_position.y + 6.0
	var bot := r.end.y - global_position.y - 6.0
	p.y = clampf(p.y - 7.0 * float(scars.size()), top, bot) # 겹치지 않게 조금씩 위로
	p.x = clampf(p.x, r.position.x - global_position.x + 3.0, r.end.x - global_position.x - 3.0)
	scars.append([p, angle, 0.0])
	_dirty = true


## 자국이 한꺼번에 터진다: 자국마다 찢김 렌즈 + 깃털 + 참격선, 피해는 합쳐서 한 번 (다시 터지지 않게 blade로)
func _burst_scars(from: Vector2) -> void:
	var n := scars.size()
	for s: Array in scars:
		var p: Vector2 = global_position + (s[0] as Vector2)
		var tan := Vector2.from_angle(float(s[1]))
		BFx.cut(p, tan, 90.0, true)
		EVfx.dark_burst(p, 30.0)
		EVfx.pixels(p, 6, 220.0, Vector2.ZERO, 180.0, 0.3, Vector2(0, 200))
	scars.clear()
	bursts += 1
	take_hit(SCAR_DMG * n, from, {"heavy": true, "launch": 2.5, "blade": true})
	Fx.hitstop(0.08)
	Fx.flash(Color(0.86, 0.78, 1.0, 0.16), 0.12)
	PVfx.kick(Vector2(signf(global_position.x - from.x) * 6.0, -2.0))
	Fx.shake(0.5, 0.2)
	Fx.zoom_punch(0.05)
	Sfx.play(&"kb_burst", -2.0)
	Sfx.play_pitch(&"es_tear", 0.8, -4.0)


func _process(delta: float) -> void:
	super._process(delta)
	if scars.is_empty():
		return
	for s: Array in scars:
		s[2] = float(s[2]) + delta
	scars = scars.filter(func(s: Array) -> bool: return float(s[2]) < SCAR_LIFE)
	queue_redraw()


func _paint() -> void:
	super._paint()
	for s: Array in scars:
		_paint_scar(s[0], float(s[1]), float(s[2]))


## 틈 자국: 가는 검은 무(틈) + 양쪽 라벤더 테 + 안의 별빛 두 점, 숨 쉬듯 번짐. 처음엔 툭 벌어지고 끝 1초는 옅어진다
func _paint_scar(p: Vector2, angle: float, age: float) -> void:
	var open := minf(age / SCAR_OPEN, 1.0)
	var fade := clampf((SCAR_LIFE - age) / 1.0, 0.0, 1.0)
	var pulse := 0.75 + 0.25 * sin(age * 9.0)
	var a := fade
	var d := Vector2.from_angle(angle)
	var o := d.orthogonal()
	var hl := SCAR_LEN * 0.5 * (0.6 + 0.4 * open)
	var e0 := p - d * hl
	var e1 := p + d * hl
	pd.glow(p, 10.0, Color(BFx.MAG, 0.22 * pulse * a), 0.0)
	BFx.needle(pd, e0, e1, 3.4 * open, Color(BFx.INK, 0.95 * a))
	BFx.needle(pd, e0 - o * 1.4 * open, e1 - o * 1.4 * open, 0.9, Color(BFx.PALE, a * pulse))
	BFx.needle(pd, e0 + o * 1.4 * open, e1 + o * 1.4 * open, 0.9, Color(BFx.LAV, a * pulse))
	for i in 2:
		var q := p + d * hl * (0.45 * (float(i) * 2.0 - 1.0)) + o * 0.2
		pd.draw_rect(Rect2(q - Vector2(0.5, 0.5), Vector2(1, 1)), Color(1, 1, 1, a * (0.5 + 0.5 * sin(age * 13.0 + float(i) * 2.0))))
