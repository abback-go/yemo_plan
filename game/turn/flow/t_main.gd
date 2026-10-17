class_name TMain
extends Node
## 턴제 전투 시험판의 뿌리 장면: 타이틀 → 준비 → 전투 → 결과 → (다음 전투 | 끝). 상태는 TRun 하나.
## 자식: World(전투 장면) · Effects(연출 — Fx.effect_parent가 이 이름을 찾는다) · UI(CanvasLayer 10: 화면·전투 판)

var run: TRun
var world: Node2D
var effects: Node2D
var ui: CanvasLayer
var scene: TBattleScene
var screen: Control
var _pouch_backup := {}
var _bag_backup: Array[String] = []
var smoke := false ## 연기 시험(--smoke): 타이틀 없이 자동 전투로 3판을 돌리고 끝나면 종료. godot --headless --path game -- --smoke [--shots]
var shots := false ## 연기 시험 중 화면을 user://smoke_N.png로 저장 (렌더러가 있을 때)
var _smoke_frames := 0
var _shot_n := 0
var manual := false ## 연기 시험에서 자동 대신 탭을 흉내 내 아군 차례를 조작 (--manual)
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	run = TRun.new()
	TRun.current = run
	var args := OS.get_cmdline_user_args()
	if "--smoke" in args:
		smoke = true
		shots = "--shots" in args
		manual = "--manual" in args
		_rng.seed = 7
		Engine.time_scale = 3.0 if shots else 12.0
	world = Node2D.new()
	world.name = "World"
	add_child(world)
	effects = Node2D.new()
	effects.name = "Effects"
	effects.z_index = 50 ## 배우(z 10~23)보다 늘 앞
	add_child(effects)
	ui = CanvasLayer.new()
	ui.name = "UI"
	ui.layer = 10
	add_child(ui)
	run.auto = smoke and not manual
	_show_title()


func _clear_screen() -> void:
	if is_instance_valid(screen):
		screen.queue_free()
	screen = null


func _show_title() -> void:
	_clear_screen()
	var t := TTitle.new()
	t.run = run
	t.started.connect(_on_title_start)
	ui.add_child(t)
	screen = t
	Music.play("title", 1.0)


func _on_title_start(auto: bool) -> void:
	run.auto = auto
	if run.finished() or run.battle_i > 0 and run.won == 0:
		run.reset()
	_show_prep()


func _show_prep() -> void:
	_clear_screen()
	var p := TPrep.new()
	p.run = run
	p.go.connect(_start_battle)
	p.back.connect(_show_title)
	ui.add_child(p)
	screen = p
	Music.play("school", 1.0)


func _start_battle() -> void:
	_clear_screen()
	_pouch_backup = run.pouch.duplicate()
	_bag_backup = run.bag.duplicate()
	for c in effects.get_children():
		c.queue_free()
	scene = TBattleScene.new()
	world.add_child(scene)
	scene.setup(run, run.battle_i, ui)
	scene.finished.connect(_on_battle_finished)
	scene.start()


func _on_battle_finished(won: bool, summary: Dictionary) -> void:
	if is_instance_valid(scene):
		scene.queue_free()
	scene = null
	for c in effects.get_children():
		c.queue_free()
	var battle_name := String(run.current_battle().get("name", ""))
	var points_before := run.points
	var levels_before := run.levels.duplicate()
	if won:
		run.battle_won(summary)
	else:
		run.pouch = _pouch_backup.duplicate()
		run.bag = _bag_backup.duplicate()
		run.tidy_bag()
	var r := TResult.new()
	r.run = run
	r.won = won
	r.summary = summary
	r.battle_name = battle_name
	r.points_gained = run.points - points_before
	r.levels_before = levels_before
	r.finale = won and run.finished()
	r.next.connect(_on_result_next)
	ui.add_child(r)
	screen = r
	Music.play("ending" if r.finale else ("school_day" if won else "library"), 1.0)


func _on_result_next() -> void:
	if run.finished():
		run.reset()
		_show_title()
	else:
		_show_prep()


func _process(_delta: float) -> void:
	if not smoke:
		return
	_smoke_frames += 1
	if shots and _smoke_frames % 90 == 0:
		_shot()
	if is_instance_valid(screen) and screen is TTitle and _smoke_frames % 90 == 0:
		(screen as TTitle).started.emit(not manual)
	if manual and is_instance_valid(scene) and _smoke_frames % 25 == 0:
		_smoke_tap()
	if _smoke_frames % 300 == 0:
		var where := "scene" if is_instance_valid(scene) else (String(screen.get_class()) if is_instance_valid(screen) else "-")
		var extra := ""
		if is_instance_valid(scene) and scene.battle:
			extra = " phase=%d round=%d mana=%d over=%s" % [scene.phase, scene.battle.round, scene.battle.mana_left, str(scene.battle.over)]
		printerr("SMOKE f=%d %s%s" % [_smoke_frames, where, extra])
	if is_instance_valid(screen) and screen is TResult and _smoke_frames % 30 == 0:
		var r := screen as TResult
		print("RESULT ", r.battle_name, " won=", r.won, " max_hit=", int(r.summary.get("max_hit", 0)), " rounds=", int(r.summary.get("rounds", 0)))
		if r.finale or not r.won:
			print("SMOKE OK frames=", _smoke_frames)
			get_tree().quit()
			return
		r.next.emit()
	elif is_instance_valid(screen) and screen is TPrep and _smoke_frames % 90 == 0:
		for w in run.party:
			for s in TData.witch(w).get("spells", []):
				if run.can_learn(w, String(s)):
					run.learn(w, String(s))
		(screen as TPrep).go.emit()
	if _smoke_frames > 60 * 60 * 30:
		push_error("SMOKE TIMEOUT")
		get_tree().quit(1)


func _shot() -> void:
	var img := get_viewport().get_texture().get_image()
	if img == null:
		return
	_shot_n += 1
	img.save_png("user://smoke_%02d.png" % _shot_n)


## 탭 흉내 v2: 대상 고르는 중이면 대상 배우를, 마법창이 없으면 마녀 카드를, 있으면 쓸 수 있는 마법(가끔 물약)을 누른다. 아무도 못 쓰면 턴 종료
func _smoke_tap() -> void:
	var sc := scene
	if sc.phase == TBattleScene.Phase.OVER:
		return
	if _smoke_frames % 500 == 0:
		sc.on_tap(sc.hud.speed_rect().get_center())
	if not sc.waiting():
		return
	if sc.sel_spell != "" or sc.sel_potion != "":
		if sc.cand.is_empty():
			return
		var a := sc.actor_of(sc.cand[sc.cand_i].id)
		if a:
			sc.on_tap(a.hit_rect().get_center())
		return
	var b := sc.battle
	if sc.sel_unit == null:
		var al := b.allies()
		if al.is_empty():
			return
		sc.on_tap(sc.hud.card_rect(al[_rng.randi() % al.size()].slot).get_center())
		return
	if sc.potion_menu:
		if b.bag.is_empty():
			sc.on_tap(sc.hud.potion_close_rect().get_center())
		else:
			sc.on_tap(sc.hud.potion_rect(_rng.randi() % mini(b.bag.size(), 3)).get_center())
		return
	if _rng.randf() < 0.1 and not b.bag.is_empty():
		sc.on_tap(sc.hud.potion_btn_rect().get_center())
		return
	var spells: Array = TData.witch(sc.sel_unit.base).get("spells", [])
	for _try in 8:
		var i := _rng.randi() % spells.size()
		if b.can_use(sc.sel_unit, String(spells[i])):
			sc.on_tap(sc.hud.menu_rect(i).get_center())
			return
	# 이 마녀는 쓸 게 없다 → 다른 마녀가 쓸 수 있으면 카드 전환, 아니면 턴 종료
	for u in b.allies():
		if u.id == sc.sel_unit.id:
			continue
		for s0 in TData.witch(u.base).get("spells", []):
			if b.can_use(u, String(s0)):
				sc.on_tap(sc.hud.card_rect(u.slot).get_center())
				return
	sc.on_tap(sc.hud.end_rect().get_center())
