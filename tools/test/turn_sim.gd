extends SceneTree
## 턴제 전투 헤드리스 시뮬레이션 (tools/test/README.md): 규칙 엔진(TBattle)만 돌려 밸런스를 잰다.
##   cd game && godot --headless --script ../tools/test/turn_sim.gd -- [반복 수] [전투 id]
##   전투 id(normal_01 · boss_01)를 주면 그 전투만 TAuto로 돌린다 (기본 파티 + 12명 무작위 파티).
## 출력: 전략별 승률·걸린 차례·마녀별 준 피해·최대 한 방·남은 체력, 스킬 효율표, 문서의 숫자 규모 확인,
##       전투별 승률·행동 수·시간 모형(전체 행동 × 1.3초 + 마녀 행동 × 3초, combat_proto.md §1.4)·대마법·기절·터뜨리기 횟수.

var _done := false


func _process(_d: float) -> bool:
	if _done:
		return true
	_done = true
	var args := OS.get_cmdline_user_args()
	var runs := int(args[0]) if args.size() > 0 else 20
	if args.size() > 1:
		_run_battle(String(args[1]), runs)
		return true
	print("=== 스킬 효율 (배율/비용, 버프 없음, 방어 0 기준) ===")
	for wid in TData.BATTLE.party:
		var line := "%s:" % TData.WITCHES[wid].name
		for sid in TData.WITCHES[wid].skills:
			var s: Dictionary = TData.SKILLS[sid]
			if s.kind == "attack":
				line += " %s %.1f/%d=%.2f" % [s.name, float(s.mult), int(s.cost), float(s.mult) / float(s.cost)]
		print(line)
	print("")
	_scale_check()
	print("")
	for strat in ["basic", "default", "eska_fire", "ignis_burst"]:
		_run_many(strat, runs)
	print("")
	_run_roster(runs)
	print("")
	for bid in TData.BATTLES:
		_run_battle(String(bid), runs)
	return true


## 문서 §3의 숫자 규모 표를 엔진으로 다시 계산 (난수 고정 1.0 대신 중앙값 근사: 여러 번 평균)
func _scale_check() -> void:
	print("=== 숫자 규모 확인 (이그니스 공격력 12,000, 짚 골렘 상대) ===")
	var b := TBattle.new()
	b.setup(["eska", "ignis", "ember"], ["straw_golem"], {}, 7)
	var ig := b.witches[1]
	var em := b.witches[2]
	var g := b.enemies[0]
	g.max_hp = 999999999
	g.hp = g.max_hp
	print("기본 공격 예상: ", TData.fmt(b.estimate(ig, g, "")), " (약점 불 1.5배 포함)")
	print("태양의 창 단독 예상: ", TData.fmt(b.estimate(ig, g, "sun_spear")))
	g.add_mark("burn", 3, 1)
	b.actor = em
	b.use_skill(em, "bellows", ig)
	print("+ 풀무(화상 특공 50%): ", TData.fmt(b.estimate(ig, g, "sun_spear")))
	b.use_skill(em, "blessing", null)
	b.actor = ig
	b.use_skill(ig, "focus", ig)
	print("+ 불의 축복 30% + 화염 집중 50%: ", TData.fmt(b.estimate(ig, g, "sun_spear")))
	b.actor = em
	b.use_skill(em, "god_descent", ig)
	print("+ 불의 신 강림 100%: ", TData.fmt(b.estimate(ig, g, "sun_spear")), " (크리 아님)")
	ig.credits = 7
	b.actor = ig
	var best := 0
	var n := 0
	var crit_n := 0
	for i in 200:
		var hp0 := g.hp
		var ev := b.use_skill(ig, "sun_spear", g)
		ig.credits = 7
		ig.buffs = ig.buffs.filter(func(x: Dictionary) -> bool: return x.cat != "crit_dmg" or x.dur > 1)
		for e in ev:
			if e.t == "hit":
				best = maxi(best, int(e.dmg))
				if bool(e.crit):
					crit_n += 1
				n += 1
	print("태양의 창 200번 중 크리 %d번, 최대 한 방 %s" % [crit_n, TData.fmt(best)])


func _run_many(strat: String, runs: int) -> void:
	var wins := 0
	var turns_sum := 0
	var dealt := {"eska": 0, "ignis": 0, "ember": 0}
	var biggest := 0
	var biggest_who := ""
	var hp_left := 0.0
	var downs := 0
	for i in runs:
		var r := _run_one(strat, 1000 + i)
		if r.win:
			wins += 1
		turns_sum += int(r.turns)
		for k in dealt:
			dealt[k] = int(dealt[k]) + int(r.dealt[k])
		if int(r.biggest) > biggest:
			biggest = int(r.biggest)
			biggest_who = String(r.biggest_who)
		hp_left += float(r.hp_left)
		downs += int(r.downs)
	print("=== 전략 %s: %d판 승 %d, 평균 차례(마녀 행동) %.1f, 쓰러진 마녀 평균 %.2f, 남은 체력 평균 %.0f%%" % [strat, runs, wins, float(turns_sum) / float(runs), float(downs) / float(runs), 100.0 * hp_left / float(runs)])
	print("   준 피해 평균: 에스카 %s · 이그니스 %s · 엠버 %s · 최대 한 방 %s (%s)" % [TData.fmt(int(dealt.eska) / runs), TData.fmt(int(dealt.ignis) / runs), TData.fmt(int(dealt.ember) / runs), TData.fmt(biggest), biggest_who])


## 한 판: strat에 따라 마녀가 고르는 규칙이 다르다. 적은 엔진이 알아서
func _run_one(strat: String, seed_v: int) -> Dictionary:
	var b := TBattle.new()
	var state := {}
	if strat == "eska_fire":
		state = {"eska": {"equipped": ["crack", "void_gate", "seal", "doom", "blackstar"], "equip": "black_cup"},
			"ember": {"equipped": ["flame_breath", "kindling", "bellows", "blessing", "share_ember"], "equip": "notebook"},
			"ignis": {"equipped": ["spark", "focus", "pillar", "ash_storm", "sun_spear"], "equip": "kaleido"}}
	b.setup(TData.BATTLE.party, TData.BATTLE.battle, state, seed_v)
	var r := _play(b, func(u: TUnit) -> Dictionary: return {"ev": _witch_act(b, u, strat), "sid": ""})
	r["turns"] = r.witch_acts
	return r


## 한 판을 끝까지: 기절이면 쉬고, 웨이브가 전멸하면 다음 웨이브. choose(u) → {ev, sid}
func _play(b: TBattle, choose: Callable) -> Dictionary:
	var r := {"witch_acts": 0, "all_acts": 0, "biggest": 0, "biggest_who": "", "downs": 0, "ults": 0, "stuns": 0, "bursts": 0, "breaks": 0, "resists": 0}
	var guard := 0
	while guard < 1500:
		var oc := b.outcome()
		if oc == "wave":
			b.next_wave()
			continue
		if oc != "":
			break
		guard += 1
		var u := b.next_actor()
		var ev: Array = []
		r.all_acts = int(r.all_acts) + 1
		if u.stunned:
			ev = b.rest(u)
		elif u.is_witch():
			r.witch_acts = int(r.witch_acts) + 1
			var a: Dictionary = choose.call(u)
			ev = a.ev
			if bool(TData.skill(String(a.sid)).get("ultimate", false)):
				r.ults = int(r.ults) + 1
		else:
			ev = b.enemy_action(u)
		for e in ev:
			match String(e.t):
				"hit":
					if e.src.is_witch() and int(e.dmg) > int(r.biggest):
						r.biggest = int(e.dmg)
						r.biggest_who = "%s %s" % [e.src.name, b.last_action]
					if bool(e.killed) and e.tgt.is_witch():
						r.downs = int(r.downs) + 1
					if bool(e.broke):
						r.breaks = int(r.breaks) + 1
				"stun": r.stuns = int(r.stuns) + 1
				"burst": r.bursts = int(r.bursts) + 1
				"resist": r.resists = int(r.resists) + 1
		b.end_action(u)
	var hp_left := 0.0
	for w in b.witches:
		hp_left += w.hp_ratio() / float(b.witches.size())
	var dealt := {}
	for w in b.witches:
		dealt[w.id] = w.dealt
	r["win"] = b.outcome() == "win"
	r["hp_left"] = hp_left
	r["dealt"] = dealt
	r["wave"] = b.wave_i + 1
	return r


## TAuto로 한 차례
func _auto(b: TBattle, u: TUnit) -> Dictionary:
	var a := TAuto.pick(b, u)
	if a.kind == "basic":
		return {"ev": b.basic_attack(u, a.target), "sid": ""}
	return {"ev": b.use_skill(u, String(a.skill), a.target), "sid": String(a.skill)}


## 전투 id 하나: 기본 파티(TAuto) + 12명 무작위 파티 — 승률·행동 수·시간 모형
func _run_battle(bid: String, runs: int) -> void:
	print("=== 전투 %s (%s, 웨이브 %d) — %d판씩 ===" % [bid, TData.BATTLES[bid].name, (TData.BATTLES[bid].waves as Array).size(), runs])
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for mode in ["기본 파티", "12명 무작위"]:
		var agg := {"win": 0, "w_acts": 0, "a_acts": 0, "biggest": 0, "ults": 0, "stuns": 0, "bursts": 0, "breaks": 0, "resists": 0, "downs": 0, "wave_sum": 0}
		for i in runs:
			var party: Array = TData.BATTLE.party
			if mode != "기본 파티":
				var pool: Array = TData.ROSTER.duplicate()
				party = []
				for j in 3:
					party.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
			var b := TBattle.new()
			b.setup(party, bid, {}, 9000 + i)
			var r := _play(b, func(u: TUnit) -> Dictionary: return _auto(b, u))
			agg.wave_sum = int(agg.wave_sum) + int(r.wave)
			for k in ["ults", "stuns", "bursts", "breaks", "resists", "downs"]:
				agg[k] = int(agg[k]) + int(r[k])
			agg.biggest = maxi(int(agg.biggest), int(r.biggest))
			if bool(r.win):
				agg.win = int(agg.win) + 1
				agg.w_acts = int(agg.w_acts) + int(r.witch_acts)
				agg.a_acts = int(agg.a_acts) + int(r.all_acts)
		var wn := maxf(float(agg.win), 1.0)
		var w_avg := float(agg.w_acts) / wn
		var a_avg := float(agg.a_acts) / wn
		print("  %s: 승 %d/%d · 승리 평균 마녀 행동 %.1f · 전체 행동 %.1f · 시간 모형 %.1f분 · 도달 웨이브 평균 %.2f" % [mode, int(agg.win), runs, w_avg, a_avg, (a_avg * 1.3 + w_avg * 3.0) / 60.0, float(agg.wave_sum) / float(runs)])
		print("     판당: 대마법 %.1f · 기절 %.1f · 터뜨리기 %.1f · 브레이크 %.1f · 저항 %.1f · 쓰러진 마녀 %.1f · 최대 한 방 %s" % [float(agg.ults) / runs, float(agg.stuns) / runs, float(agg.bursts) / runs, float(agg.breaks) / runs, float(agg.resists) / runs, float(agg.downs) / runs, TData.fmt(int(agg.biggest))])


func _front_enemy(b: TBattle) -> TUnit:
	return TAuto.enemy_for(b) # 불 약점(짚 골렘)이 살아 있으면 그쪽, 아니면 체력이 가장 적은 적


func _by_id(b: TBattle, wid: String) -> TUnit:
	for w in b.witches:
		if w.id == wid:
			return w
	return null


func _try(b: TBattle, u: TUnit, sid: String, tgt: TUnit) -> Array:
	if u.equipped.has(sid) and b.can_use(u, sid):
		return b.use_skill(u, sid, tgt)
	return []


func _witch_act(b: TBattle, u: TUnit, strat: String) -> Array:
	var en := _front_enemy(b)
	if strat == "basic":
		return b.basic_attack(u, en)
	var ig := _by_id(b, "ignis")
	var es := _by_id(b, "eska")
	var dealer: TUnit = ig if (ig != null and ig.alive) else es
	if strat == "eska_fire" and es != null and es.alive:
		dealer = es
	var ev: Array = []
	match u.id:
		"ember":
			# 버퍼: 딜러에게 장작·풀무 → 전체 축복 → 크레딧 몰아주기 → 강림(딜러 크레딧이 5 이상일 때) → 아니면 징표 기본 공격
			if dealer.alive:
				if not dealer.has_buff("element") and strat == "eska_fire":
					ev = _try(b, u, "kindling", dealer)
				if ev.is_empty() and not dealer.has_buff("special"):
					ev = _try(b, u, "bellows", dealer)
				if ev.is_empty() and not u.has_buff("atk"):
					ev = _try(b, u, "blessing", null)
				if ev.is_empty() and dealer.credits <= 3:
					ev = _try(b, u, "share_ember", dealer)
				if ev.is_empty() and dealer.credits >= 5 and not dealer.has_buff("atk"):
					ev = _try(b, u, "god_descent", dealer)
				if ev.is_empty() and u.credits >= 3:
					ev = _try(b, u, "flame_breath", en)
			if ev.is_empty():
				ev = b.basic_attack(u, en)
		"ignis":
			if strat == "eska_fire" and es != null and es.alive:
				# 에스카가 딜러: 이그니스는 징표를 깔고 쓸 수 있는 가장 큰 공격
				if not en.marks.has("burn"):
					ev = _try(b, u, "spark", en)
				if ev.is_empty():
					ev = _biggest_attack(b, u, en)
			else:
				if u.credits >= 7 or (strat == "ignis_burst" and u.credits >= 5):
					if not u.has_buff("atk") and u.credits >= 7:
						ev = _try(b, u, "focus", u)
					if ev.is_empty():
						ev = _try(b, u, "sun_spear", en)
					if ev.is_empty():
						ev = _try(b, u, "ash_storm", en)
				if ev.is_empty() and not en.marks.has("burn") and u.credits >= 1 and strat != "ignis_burst":
					ev = _try(b, u, "spark", en)
				if ev.is_empty() and strat == "default" and u.credits >= 3 and en.marks.has("burn"):
					ev = _try(b, u, "pillar", en)
			if ev.is_empty():
				ev = b.basic_attack(u, en)
		"eska":
			if strat == "eska_fire":
				if u.credits >= 4 and u.has_buff("element"):
					ev = _try(b, u, "doom", en)
				if ev.is_empty() and u.credits >= 5:
					ev = _try(b, u, "blackstar", en)
			else:
				# 범용: 딜러에게 공허의 문, 전체 봉공(적 강공격 예정이면), 아니면 공격
				if dealer != u and dealer.alive and not dealer.has_buff("final"):
					ev = _try(b, u, "void_gate", dealer)
				if ev.is_empty() and _heavy_coming(b) and u.credits >= 3:
					ev = _try(b, u, "seal", null)
				if ev.is_empty() and u.credits >= 5:
					ev = _try(b, u, "blackstar", en)
				if ev.is_empty() and u.credits >= 4:
					ev = _try(b, u, "doom", en)
				if ev.is_empty() and u.credits >= 2:
					ev = _try(b, u, "crack", en)
			if ev.is_empty():
				ev = b.basic_attack(u, en)
	return ev


func _biggest_attack(b: TBattle, u: TUnit, en: TUnit) -> Array:
	var best := ""
	var best_cost := 0
	for sid in u.equipped:
		var s: Dictionary = TData.SKILLS[sid]
		if s.kind == "attack" and b.can_use(u, sid) and int(s.cost) > best_cost:
			best = sid
			best_cost = int(s.cost)
	if best != "":
		return b.use_skill(u, best, en)
	return []


func _heavy_coming(b: TBattle) -> bool:
	return TAuto.heavy_coming(b)


## 12명: 명단에서 무작위 3명(기본 장착)으로 TAuto 규칙 플레이 — 마녀마다 승률·준 피해를 모은다
func _run_roster(runs: int) -> void:
	print("=== 12명 무작위 파티 (%d판, TAuto 규칙) ===" % runs)
	var wins := 0
	var turns := 0
	var per := {}
	for wid in TData.ROSTER:
		per[wid] = {"n": 0, "win": 0, "dealt": 0}
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in runs:
		var pool: Array = TData.ROSTER.duplicate()
		var party: Array = []
		for j in 3:
			party.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
		var b := TBattle.new()
		b.setup(party, TData.BATTLE.battle, {}, 5000 + i)
		var r := _play(b, func(u: TUnit) -> Dictionary: return _auto(b, u))
		var t := int(r.witch_acts)
		var win := bool(r.win)
		if win:
			wins += 1
			turns += t
		for w in b.witches:
			per[w.id].n += 1
			per[w.id].win += 1 if win else 0
			per[w.id].dealt += w.dealt
	print("승 %d/%d, 승리 평균 마녀 행동 %.1f" % [wins, runs, float(turns) / maxf(float(wins), 1.0)])
	for wid in TData.ROSTER:
		var d: Dictionary = per[wid]
		if int(d.n) > 0:
			print("  %s: 출전 %d 승 %d 평균 피해 %s" % [TData.WITCHES[wid].name, int(d.n), int(d.win), TData.fmt(int(d.dealt) / int(d.n))])
