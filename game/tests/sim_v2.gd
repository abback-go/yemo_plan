## 새 전투(v2) 난이도 재기 — 규칙만으로 자동 진행(RulesV2.auto_step)을 여러 시드로 돌려 승률·남은 HP·턴을 표로 (밤샘 계획 2 D1·D2, docs/balance-report.md 「새 전투 1층」)
##   godot --headless --path game --script res://tests/sim_v2.gd -- --seeds=1-40 [--mode=test,iso,chain] [--ai=simple]
## --ai=simple: 예전 판단(RulesV2.auto_simple — 규칙 몇 줄, 서툰 사람 쪽 비교). 없으면 지금 자동 진행(RulesV2.auto_step — 이번 턴을 내다보고 고름)
## test : 시험 전투(?battle=v2) — 지금까지 '해 볼 만한가'를 잰 잣대(시드 1~30)
## iso  : 1층 전투 다섯 곳을 새 파티(HP 가득)로 하나씩
## chain: 1층을 처음부터(장례 회랑 → 기도실 → 무덤지기(+승리 카드) → [예배당 휴식] → 가장 깊은 곳 → 거대한 발) — HP·상처·덱이 이어진다.
##        지면 그 전투 처음부터(Ctl._battle_v2 와 같게 — 난수는 이어 가고 노엘 HP 는 retryWitchHp 까지). 「첫 판 이김」 = 다시 하기 없이 이긴 비율
## 화면 없이 규칙만 돈다(한 판 수 ms). 게임 흐름 전체(VN·지도 포함)는 tools/batch_autoplay.py
extends SceneTree

const ENCS := ["normal", "prayer", "gravekeeper", "deep", "giant"]
var ai := ""
var trace := false
var encs: Array = ENCS
const NAMES := {"test": "시험 전투", "normal": "장례 회랑", "prayer": "기도실", "gravekeeper": "무덤지기", "deep": "가장 깊은 곳 광신도", "giant": "거대한 발"}


func _init() -> void:
	var seeds := range(1, 31)
	var modes := ["test", "iso", "chain"]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = _parse_seeds(a.substr(8))
		elif a.begins_with("--mode="):
			modes = Array(a.substr(7).split(","))
		elif a.begins_with("--ai="):
			ai = a.substr(5)
		elif a == "--trace":
			trace = true   # 판마다 둔 수를 찍는다(시드 하나로)
		elif a.begins_with("--encs="):
			encs = Array(a.substr(7).split(","))
	print("sim_v2 시드 %d개 (%d~%d)%s" % [seeds.size(), seeds[0], seeds[-1], " · 예전 판단(simple)" if ai == "simple" else ""])
	var t0 := Time.get_ticks_msec()
	if modes.has("test"):
		_report("시험 전투(?battle=v2)", _run_test(seeds))
	if modes.has("iso"):
		var rows := {}
		for enc in encs:
			rows[enc] = []
			for sd in seeds:
				var gs := Rules.new_game(sd)
				RulesV2.init_party(gs)
				var st := auto_run(RulesV2.new_battle(null, RulesV2.battle_opts(gs, enc)))
				rows[enc].append(_row(st, 0))
		for enc in encs:
			_report("새 파티 · " + NAMES[enc], rows[enc])
	if modes.has("chain"):
		for rest in [false, true]:
			var rows2 := {}
			for enc in ENCS:
				rows2[enc] = []
			for sd in seeds:
				var out := chain(sd, rest)
				for enc in out:
					rows2[enc].append(out[enc])
			for enc in ENCS:
				_report(("1층 이어서(예배당 휴식) · " if rest else "1층 이어서(휴식 없음) · ") + NAMES[enc], rows2[enc])
	print("sim_v2 끝 %.1f초" % ((Time.get_ticks_msec() - t0) / 1000.0))
	quit(0)


func _parse_seeds(s: String) -> Array:
	var out := []
	for part in s.split(","):
		if part.contains("-"):
			var ab := part.split("-")
			for i in range(int(ab[0]), int(ab[1]) + 1):
				out.append(i)
		elif part != "":
			out.append(int(part))
	return out


func _run_test(seeds: Array) -> Array:
	var out := []
	for sd in seeds:
		var st := RulesV2.new_battle(sd)
		out.append(_row(auto_run(st), 0))
	return out


## 자동 진행으로 끝까지(규칙만 — tests/test_rules_v2.gd auto_run 과 같은 길)
func auto_run(st: Dictionary) -> Dictionary:
	var steps := 0
	while st.result == null and st.turn < 40 and steps < 3000:
		steps += 1
		var a := RulesV2.auto_simple(st) if ai == "simple" else RulesV2.auto_step(st)
		var r := {"ok": true}
		if trace:
			_trace(st, a)
		match str(a.kind):
			"start":
				r = RulesV2.start_battle(st)
			"place":
				r = RulesV2.place(st, a.uid, a.ally, a.opts)
			"cast":
				r = RulesV2.cast(st, a.uid, a.target, a.opts)
			"move":
				r = RulesV2.move_ally(st, a.ally, a.to)
			_:
				RulesV2.end_turn(st)
				if st.result == null:
					RulesV2.start_turn(st)
		if not r.ok:
			push_error("auto_step 거절: %s %s" % [str(a), str(r)])
			st.bad = true
			break
	return st


func _trace(st: Dictionary, a: Dictionary) -> void:
	var k := str(a.kind)
	var s := "  t%d e%d %s" % [int(st.turn), int(st.energy), k]
	if k in ["place", "cast"]:
		s += " %s → %s %s" % [st.cards[a.uid].id, str(a.get("ally", a.get("target", ""))), str(a.get("opts", {})) if not a.get("opts", {}).is_empty() else ""]
	elif k == "move":
		s += " %s → %s" % [a.ally, str(a.to)]
	elif k == "end" and st.phase == "battle":
		var its := []
		for e in st.enemies:
			if e.alive and e.intent != null:
				its.append("%s:%s %s→%s" % [e.id, e.intent.kind, str(RulesV2.act_value(e.intent)), str(e.intent.slot)])
		var al := []
		for id in st.order:
			al.append("%s %d%s" % [id, int(st.allies[id].hp), "@" + str(RulesV2.col_of(st, id))])
		var en := []
		for e in st.enemies:
			if e.alive:
				en.append("%s %d" % [e.id, int(e.hp)])
		s += " | 적 행동 %s | 동료 %s | 적 %s | 노엘 %d" % [str(its), str(al), str(en), int(st.noelHp)]
	print(s)


## 1층 처음부터. 반환 {enc: row}
func chain(sd: int, rest: bool) -> Dictionary:
	var gs := Rules.new_game(sd)
	RulesV2.init_party(gs)
	var out := {}
	var rooms := ["prayer", "gravekeeper"] + (["chapel"] if rest else []) + ["deep"]
	MapRules.enter_room(gs, "corridor")
	gs = _fight(gs, "normal", out)
	MapRules.enter_room(gs, "hall")
	for room in rooms:
		MapRules.enter_room(gs, room)
		if room == "chapel":
			MapRules.apply_rest(gs)
			continue
		var enc := str(MapRules.room_def(gs, room).get("enc", "deep"))
		gs = _fight(gs, enc, out)
		if room == "gravekeeper":
			MapRules.win_card(gs, "elite")
	return out


## 한 전투(지면 처음부터 다시 — Ctl._battle_v2). deep 에서 발이 내려오면 이어서 giant
func _fight(gs: Dictionary, enc: String, out: Dictionary) -> Dictionary:
	var snap: Dictionary = gs.duplicate(true)
	var wipes := 0
	var E: Dictionary = BattleV2Data.D.encounters[enc]
	while true:
		var dark := MapRules.darkness_level(gs, str(E.get("v1", enc)))
		var st := auto_run(RulesV2.new_battle(null, RulesV2.battle_opts(gs, enc, dark)))
		if st.result == "lose" or st.result == null:
			wipes += 1
			gs = Rules.restore(snap, int(st.rng))
			if wipes >= 20:
				out[enc] = _row(st, wipes)
				return gs
			continue
		out[enc] = _row(st, wipes)
		RulesV2.apply_result(gs, st)
		if st.result == "giant":
			return _fight(gs, "giant", out)
		return gs
	return gs


func _row(st: Dictionary, wipes: int) -> Dictionary:
	var r := {"result": str(st.result), "wipes": wipes, "turn": int(st.turn), "noel": int(st.noelHp), "noelMax": int(st.noelMax), "allies": {}, "downs": 0}
	for id in st.order:
		var a: Dictionary = st.allies[id]
		r.allies[id] = {"hp": int(a.hp), "max": int(a.maxHp), "down": bool(a.down), "dead": bool(a.dead)}
		if a.down and not a.dead:
			r.downs = int(r.downs) + 1
	return r


func _report(title: String, rows: Array) -> void:
	if rows.is_empty():
		return
	var n := rows.size()
	var first := rows.filter(func(r): return int(r.wipes) == 0 and str(r.result) in ["win", "giant", "retreat"]).size()
	var wipes := 0
	var turns := 0.0
	var noel := 0.0
	var nmin := 999
	var downs := 0
	var hp := {"hero": 0.0, "warrior": 0.0, "archer": 0.0}
	var res := {}
	for r in rows:
		wipes += int(r.wipes)
		turns += int(r.turn)
		noel += int(r.noel)
		nmin = mini(nmin, int(r.noel))
		downs += int(r.downs)
		res[r.result] = int(res.get(r.result, 0)) + 1
		for id in hp:
			hp[id] += int(r.allies[id].hp)
	var tot := 0.0
	var mx := 0.0
	for id in hp:
		tot += hp[id]
		mx += int(rows[0].allies[id].max)
	print("%s | %d판 | 첫 판 이김 %d%% | 다시 하기 %d | 결과 %s | 노엘 %.1f (최저 %d) | 세라피나 %.1f · 브룬힐드 %.1f · 엘리안 %.1f | 동료 합 %.0f%% | 쓰러짐 %.2f/판 | 턴 %.1f"
		% [title, n, int(round(100.0 * first / n)), wipes, str(res), noel / n, nmin, hp.hero / n, hp.warrior / n, hp.archer / n, 100.0 * tot / n / maxf(1.0, mx),
			float(downs) / n, turns / n])
