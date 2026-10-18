extends SceneTree
## 턴제 전투 헤드리스 시뮬레이션 (tools/test/README.md): 규칙 엔진(TBattle)만 돌려 밸런스를 잰다.
##   cd game && godot --headless --script ../tools/test/turn_sim.gd -- [반복 수] [전투 id | builds [원형 id]]
##   전투 id(normal_01 · boss_01 · trial_01)를 주면 그 전투만 TAuto로 돌린다 (기본 파티 + 12명 무작위 파티).
##   builds: 빌드 원형 프리셋(BUILDS — 파티·장착·장비·TAuto.plan) × 전투 3개를 돌려 원형다움 지표를 찍는다 (combat_proto.md §15.9).
## 출력: 전략별 승률·걸린 차례·마녀별 준 피해·최대 한 방·남은 체력, 스킬 효율표, 문서의 숫자 규모 확인,
##       전투별 승률·행동 수·시간 모형(전체 행동 × 1.3초 + 마녀 행동 × 3초, combat_proto.md §1.4)·대마법·기절·터뜨리기 횟수.

var _done := false

## 빌드 원형 프리셋 (combat_proto.md §15.9). state = TBattle.setup의 편성 상태, plan = TAuto.plan
const BUILDS := {
	"B1": {"name": "평타 크리", "party": ["fulgur", "astra", "nerei"], "plan": {"dealer": "fulgur"},
		"state": {"fulgur": {"equipped": ["charge_up", "spark_bolt", "thunderbolt", "thunder_lance"], "equip": "mirror_shard"},
			"astra": {"equipped": ["star_touch", "starlight", "rod", "spur"], "equip": "star_shard"},
			"nerei": {"equipped": ["spring", "wave_hold", "current", "water_veil"], "equip": "iron_heart"}}},
	"B2": {"name": "대마법 연쇄", "party": ["undine", "nerei", "astra"], "plan": {"dealer": "undine", "ult_only": ["undine"], "battery": ["nerei", "astra"]},
		"state": {"undine": {"equipped": ["water_lance", "return_tide", "glacier", "abyss_lance"], "equip": "kaleido"},
			"nerei": {"equipped": ["high_tide", "droplet", "water_veil", "spring"], "equip": "notebook"},
			"astra": {"equipped": ["lightning_share", "spur", "starlight", "rod"], "equip": "swift_boots"}}},
	"B3": {"name": "버티며 쌓기", "party": ["nerei", "eska", "harpe"], "plan": {"dealer": "harpe"},
		"state": {"nerei": {"equipped": ["wave_hold", "spring", "ocean_blessing", "sea_embrace"], "equip": "iron_heart"},
			"eska": {"equipped": ["gap", "seal", "cradle", "void_gate"], "equip": "hourglass_charm"},
			"harpe": {"equipped": ["sword_ki", "heaven_split", "doom_slash", "return_cut"], "equip": "feather_charm"}}},
	"B4": {"name": "징표 터뜨리기", "party": ["cinder", "ember", "ignis"], "plan": {"dealer": "ignis"},
		"state": {"cinder": {"equipped": ["kindle_up", "ash_dust", "ash_spread", "ash_heap"], "equip": "ash_charm"},
			"ember": {"equipped": ["bellows", "crown", "blessing", "tinder"], "equip": "notebook"},
			"ignis": {"equipped": ["burst_fire", "spark", "focus", "conflagration"], "equip": "star_shard"}}},
	"B5": {"name": "차례 몰아주기", "party": ["harpe", "astra", "nerei"], "plan": {"dealer": "harpe", "push": ["astra"]},
		"state": {"harpe": {"equipped": ["bw_slash", "heaven_split", "doom_slash", "sword_ki"], "equip": "star_shard"},
			"astra": {"equipped": ["spur", "guide_bolt", "lightning_share", "starlight"], "equip": "swift_boots"},
			"nerei": {"equipped": ["spring", "wave_hold", "current", "water_veil"], "equip": "iron_heart"}}},
	"B6": {"name": "무상성→속성 딜러", "party": ["eska", "ember", "nerei"], "plan": {"dealer": "eska"},
		"state": {"eska": {"equipped": ["doom", "blackstar", "crack", "compress"], "equip": "black_cup"},
			"ember": {"equipped": ["kindling", "bellows", "blessing", "god_descent"], "equip": "notebook"},
			"nerei": {"equipped": ["spring", "wave_hold", "current", "water_veil"], "equip": "iron_heart"}}},
	"B7": {"name": "지연·잠금", "party": ["glacia", "hora", "undine"], "plan": {"dealer": "undine"},
		"state": {"glacia": {"equipped": ["still_frost", "deep_freeze", "ice_wall", "rime"], "equip": "swift_boots"},
			"hora": {"equipped": ["stopped_clock", "doomsday_clock", "rewind", "time_haste"], "equip": "hourglass_charm"},
			"undine": {"equipped": ["water_lance", "return_tide", "glacier", "abyss_lance"], "equip": "notebook"}}},
	"B8": {"name": "대가 몰빵", "party": ["ignis", "ember", "astra"], "plan": {"dealer": "ignis", "ult_only": ["ignis"], "trigger": {"astra": {"skill": "overcharge", "at": 7}}},
		"state": {"ignis": {"equipped": ["spark", "pillar", "sun_spear", "focus"], "equip": "kaleido"},
			"ember": {"equipped": ["crown", "bellows", "flame_breath", "blessing"], "equip": "notebook"},
			"astra": {"equipped": ["overcharge", "rod", "static", "starlight"], "equip": "star_shard"}}},
}


func _process(_d: float) -> bool:
	if _done:
		return true
	_done = true
	var args := OS.get_cmdline_user_args()
	var runs := int(args[0]) if args.size() > 0 else 20
	if args.size() > 1 and String(args[1]) == "builds":
		_conditions()
		for bid in BUILDS:
			if args.size() > 2 and String(args[2]) != bid:
				continue
			for battle in ["normal_01", "boss_01", "trial_01"]:
				_run_build(String(bid), battle, runs)
		return true
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
	var r := {"witch_acts": 0, "all_acts": 0, "biggest": 0, "biggest_who": "", "downs": 0, "ults": 0, "stuns": 0, "bursts": 0, "breaks": 0, "resists": 0,
		"dmg_basic": 0, "dmg_skill": 0, "dmg_ult": 0, "basic_hits": 0, "basic_crits": 0, "chain2": 0, "chain3": 0, "burst_n": 0, "charge_downs": 0,
		"finishers": 0, "enemy_acts": 0, "enemy_rounds": 0.0, "stack_max": 0, "oneshots": 0, "acts": {}}
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
			r.acts[u.id] = int(r.acts.get(u.id, 0)) + 1
			var a: Dictionary = choose.call(u)
			ev = a.ev
			var src := "basic" if String(a.sid) == "" else ("ult" if bool(TData.skill(String(a.sid)).get("ultimate", false)) else "skill")
			if src == "ult":
				r.ults = int(r.ults) + 1
			for e in ev:
				if e.t == "hit" and e.src == u:
					r["dmg_" + src] = int(r["dmg_" + src]) + int(e.dmg)
					if src == "basic":
						r.basic_hits = int(r.basic_hits) + 1
						r.basic_crits = int(r.basic_crits) + (1 if bool(e.crit) else 0)
		else:
			r.enemy_acts = int(r.enemy_acts) + 1
			r.enemy_rounds = float(r.enemy_rounds) + 1.0 / float(b.alive_of(b.enemies).size()) # 적 1체당 행동 (적 수로 나눔)
			if String(u.intent().get("k", "")) == "finisher":
				r.finishers = int(r.finishers) + 1
			ev = b.enemy_action(u)
		for e in ev:
			match String(e.t):
				"hit":
					if e.src.is_witch() and int(e.dmg) > int(r.biggest):
						r.biggest = int(e.dmg)
						r.biggest_who = "%s %s" % [e.src.name, b.last_action]
					if e.src.is_witch() and int(e.dmg) >= 1200000:
						r.oneshots = int(r.oneshots) + 1 # 보스 한 줄(120만)을 한 방에
					if bool(e.killed) and e.tgt.is_witch():
						r.downs = int(r.downs) + 1
					if bool(e.broke):
						r.breaks = int(r.breaks) + 1
				"stun": r.stuns = int(r.stuns) + 1
				"burst":
					r.bursts = int(r.bursts) + 1
					r.burst_n = int(r.burst_n) + int(e.n)
				"resist": r.resists = int(r.resists) + 1
				"chain":
					if int(e.stage) == 2:
						r.chain2 = int(r.chain2) + 1
					elif int(e.stage) == 3:
						r.chain3 = int(r.chain3) + 1
				"charge_down": r.charge_downs = int(r.charge_downs) + int(e.v)
				"stack": r.stack_max = maxi(int(r.stack_max), int(e.n))
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


# ═══════════════════════════════════════════════════════════
# 빌드 원형 (combat_proto.md §15.9)
# ═══════════════════════════════════════════════════════════

## 원형 하나 × 전투 하나: 프리셋(plan 켬)과 같은 파티의 기본 장착(plan 끔) — 승률·길이·원형다움 지표
func _run_build(bid: String, battle: String, runs: int) -> void:
	var bd: Dictionary = BUILDS[bid]
	for mode in ["프리셋", "기본 장착"]:
		var agg := {}
		var wins := 0
		var w_acts := 0
		var a_acts := 0
		var wave_sum := 0
		var dealer_acts := 0
		for i in runs:
			var b := TBattle.new()
			TAuto.plan = bd.plan if mode == "프리셋" else {}
			b.setup(bd.party, battle, bd.state if mode == "프리셋" else {}, 7000 + i)
			var r := _play(b, func(u: TUnit) -> Dictionary: return _auto(b, u))
			for k in ["dmg_basic", "dmg_skill", "dmg_ult", "basic_hits", "basic_crits", "chain2", "chain3", "burst_n", "bursts", "charge_downs", "finishers", "enemy_acts", "ults", "downs", "stuns", "witch_acts", "oneshots"]:
				agg[k] = int(agg.get(k, 0)) + int(r[k])
			agg["enemy_rounds"] = float(agg.get("enemy_rounds", 0.0)) + float(r.enemy_rounds)
			agg["stack_max"] = maxi(int(agg.get("stack_max", 0)), int(r.stack_max))
			agg["biggest"] = maxi(int(agg.get("biggest", 0)), int(r.biggest))
			agg["max_chain"] = maxi(int(agg.get("max_chain", 0)), b.max_chain)
			dealer_acts += int(r.acts.get(String(bd.plan.get("dealer", "")), 0))
			var dd := 0
			for w in b.witches:
				if w.id == String(bd.plan.get("dealer", "")):
					dd = w.dealt
			agg["dealer_dmg"] = int(agg.get("dealer_dmg", 0)) + dd
			wave_sum += int(r.wave)
			if bool(r.win):
				wins += 1
				w_acts += int(r.witch_acts)
				a_acts += int(r.all_acts)
		TAuto.plan = {}
		var wn := maxf(float(wins), 1.0)
		var tot := maxf(float(int(agg.dmg_basic) + int(agg.dmg_skill) + int(agg.dmg_ult)), 1.0)
		var w_avg := float(w_acts) / wn
		var a_avg := float(a_acts) / wn
		var line := "  %s %s %-10s [%s]: 승 %2d/%d · 승리 평균 마녀 행동 %5.1f · 시간 %4.1f분 · 웨이브 %.2f · 피해 기본 %2d%% 마법 %2d%% 대마법 %2d%% · 딜러 몫 %2d%%" % [bid, bd.name, battle, mode,
			wins, runs, w_avg, (a_avg * 1.3 + w_avg * 3.0) / 60.0, float(wave_sum) / float(runs), int(100.0 * float(agg.dmg_basic) / tot), int(100.0 * float(agg.dmg_skill) / tot), int(100.0 * float(agg.dmg_ult) / tot),
			int(100.0 * float(agg.dealer_dmg) / tot)]
		print(line)
		print("      판당 대마법 %.1f · 연쇄2 %.1f · 연쇄3 %.1f (최고 단계 %d) · 기본 공격 크리 %d%% · 터뜨리기 %.1f번 (평균 %.1f겹) · 차지 감소 %.1f · 필살기 맞음 %.1f · 쌓기 최고 %d겹 · 딜러 행동/적 1체 행동 %.2f · 적 행동/마녀 행동 %.2f · 쓰러짐 %.1f · 120만+ 한 방 %.1f · 최대 한 방 %s" % [
			float(agg.ults) / runs, float(agg.chain2) / runs, float(agg.chain3) / runs, int(agg.max_chain), int(100.0 * float(agg.basic_crits) / maxf(float(agg.basic_hits), 1.0)),
			float(agg.bursts) / runs, float(agg.burst_n) / maxf(float(agg.bursts), 1.0), float(agg.charge_downs) / runs, float(agg.finishers) / runs, int(agg.stack_max),
			float(dealer_acts) / maxf(float(agg.enemy_rounds), 1.0), float(agg.enemy_acts) / maxf(float(agg.witch_acts), 1.0), float(agg.downs) / runs, float(agg.oneshots) / runs, TData.fmt(int(agg.biggest))])


## 원형의 성립 조건 — 문서 §15.9 표의 숫자를 엔진으로 다시 계산 (난수 1.0, 크리는 적힌 대로, 패시브 켬)
func _conditions() -> void:
	print("=== 원형 성립 조건 (엔진 계산, 난수 1.0) ===")
	# B4: 화상 겹마다 — 겹 유지 + 태양의 창 vs 터뜨리기 (이그니스, 풀무질 2명분 +25%×2/겹, 불 약점, 크리 아님, 패시브 끔)
	for n in [1, 3, 5]:
		var b := _cb(["ignis", "ember", "cinder"], ["straw_golem"])
		var ig := _wu(b, "ignis")
		ig.passive = []
		var g := b.enemies[0]
		b.use_skill(_wu(b, "ember"), "bellows", ig)
		b.use_skill(_wu(b, "ember"), "bellows", ig)
		g.add_mark("burn", 3, n)
		var keep := b.estimate(ig, g, "sun_spear")
		var bu := b.estimate(ig, g, "burst_fire")
		var ul := b.estimate(ig, g, "ult_ignis")
		print("B4 화상 %d겹: 유지+태양의 창(5) %s (크레딧당 %s) · 불씨 터뜨리기(3) %s (크레딧당 %s) · 태양 붕괴(7) %s" % [n, TData.fmt(keep), TData.fmt(keep / 5), TData.fmt(bu), TData.fmt(bu / 3), TData.fmt(ul)])
	# B1: 풀구르 기본 공격 한 번 (3히트 합) — 크리 100% 조건과 크리 데미지
	var b1 := _cb(["fulgur", "astra", "nerei"], ["swamp_toad"], {"fulgur": {"equip": "mirror_shard"}})
	var fu := _wu(b1, "fulgur")
	var td := b1.enemies[0]
	td.add_mark("shock", 3, 1)
	b1.actor = fu
	b1.use_skill(fu, "charge_up", fu)
	var t1 := b1._terms(fu, td, 1.2, {}, false)
	b1.use_skill(_wu(b1, "astra"), "star_touch", fu)
	var t2 := b1._terms(fu, td, 1.2, {}, false)
	print("B1 풀구르 → 늪 두꺼비(감전): 충전 + 거울 조각 크리 확률 %d%% · 크리 배율 ×%.2f → 기본 공격 %s · + 별의 손길 ×%.2f → %s" % [
		int(round(float(t1.crit_rate) * 100.0)), float(t1.crit_mult), TData.fmt(int(round(float(t1.base) * float(t1.crit_mult)))), float(t2.crit_mult), TData.fmt(int(round(float(t2.base) * float(t2.crit_mult))))])
	var c_rate := 2.0 / 3.0 # 충전(2) 뒤 기본 공격 3번: 4차례에 크레딧 +1(충전 차례) +2×3 = +7 → 4차례마다 대마법 1번 몫
	print("B1 4차례(충전 + 기본 공격 3번) 피해 합 %s · 같은 4차례 크레딧 순증 +5 (대마법 7까지 4차례 남짓) · 마법 순환(태양의 창급 6배 + 기본 공격, 턴당 %.2f배)과 비교: 기본 공격 턴당 %.2f배" % [
		TData.fmt(int(round(float(t2.base) * float(t2.crit_mult))) * 3), 1.0 / 3.0 * 6.0 + c_rate * 1.0, 3.0 * float(t2.crit_mult) * 1.2 / 4.0])
	# B6: 에스카 화염 부여 종언 / 이그니스 태양의 창 (짚 골렘, 크리 아님)
	var b6 := _cb(["eska", "ember", "ignis"], ["straw_golem"])
	var es := _wu(b6, "eska")
	es.passive = []
	var ig6 := _wu(b6, "ignis")
	es.add_buff({"cat": "atk", "v": 0.15, "dur": 1, "clock": "own"}) # 종언의 선버프 (예상 피해에는 선버프가 안 들어가므로 직접)
	var est_plain := b6.estimate(es, b6.enemies[0], "doom")
	b6.use_skill(_wu(b6, "ember"), "kindling", es)
	var est_fire := b6.estimate(es, b6.enemies[0], "doom")
	var est_ig := b6.estimate(ig6, b6.enemies[0], "sun_spear")
	var basic_es := 13000.0 * 1.5
	var basic_ig := 12000.0 * 1.5
	var turn_es := 0.4 * float(est_fire) + 0.6 * basic_es # 4비용: 쓰는 차례 비율 2/5
	var turn_ig := (1.0 / 3.0) * float(est_ig) + (2.0 / 3.0) * basic_ig # 5비용: 1/3
	# 크리 기대: 에스카 화염 부여(크리 데미지 +50%, 확률 10%) ×1.10 · 이그니스 태양의 창(확률 50%, 화상 2겹 패시브 +16%) ×1.33
	var turn_es_c := 0.4 * float(est_fire) * 1.10 + 0.6 * basic_es * 1.10
	var turn_ig_c := (1.0 / 3.0) * float(est_ig) * (1.0 + 0.5 * 0.66) + (2.0 / 3.0) * basic_ig * (1.0 + 0.1 * 0.66)
	print("B6 짚 골렘: 에스카 종언(4, 선버프 +15%%) 무상성 %s → 화염 부여 %s · 이그니스 태양의 창(5) %s → 턴당 에스카/이그니스 크리 없이 %d%% · 크리 기대 %d%%" % [TData.fmt(est_plain), TData.fmt(est_fire), TData.fmt(est_ig),
		int(round(100.0 * turn_es / turn_ig)), int(round(100.0 * turn_es_c / turn_ig_c))])
	# B3: 시련의 일격 (단일 3.0배, 무적 관통) — 도발이 없으면 하르페가 맞아 쓰러지고, 강철 심장 네레이가 받으면 버틴다
	var b3 := _cb(["nerei", "eska", "harpe"], ["trial_colossus"], {"nerei": {"equip": "iron_heart"}})
	var hp3 := _wu(b3, "harpe")
	var ne3 := _wu(b3, "nerei")
	ne3.passive = TData.WITCHES.nerei.passive.effects
	var col := b3.enemies[0]
	var h_a := b3._enemy_hit(col, hp3, 3.0, true)
	var h_b := b3._enemy_hit(col, ne3, 3.0, true)
	print("B3 시련의 일격(단일 3.0배 관통) → 하르페(체력 75,000) %s · 강철 심장 네레이(체력 143,000, 도발 중) %s" % [TData.fmt(int(h_a.dmg)), TData.fmt(int(h_b.dmg))])


func _cb(party: Array, foes: Array, state := {}) -> TBattle:
	var b := TBattle.new()
	b.setup(party, foes, state, 1)
	b.fix_rand = 1.0
	b.fix_crit = 0
	for e in b.enemies:
		if e.bars.is_empty():
			e.max_hp = 1000000000
			e.hp = e.max_hp
	return b


func _wu(b: TBattle, wid: String) -> TUnit:
	for w in b.witches:
		if w.id == wid:
			return w
	return null
