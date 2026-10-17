extends SceneTree
## 턴제 전투 v0.3(마력제) 헤드리스 시뮬레이션 — 코어(TBattle)를 자동 조작(TPolicy)으로 돌려 밸런스를 잰다.
## 실행: godot --headless --path game --script ../tools/test/turn_sim.gd -- [판수] [빌드이름...]
## 빌드(최종진화판 — 마법은 전부 열려 있다): eska(에스카 딜러) · sera(세라 딜러) · bare(빗자루 없이 에스카 딜러) · bare_sera · all
## 출력: 전투마다 승률 · 평균 라운드 · 평균 마법 수 · 최고 한 방(평균/최대) · 최고 연계 배율 평균 · 남은 체력 · 끊기 · 적 시전 발동 · 아군 KO · 물약 · 딜러 피해 비중 · 대마법 한 타 평균

const BUILDS := {
	"eska": {"dealer": "eska", "brooms": {"eska": "glass", "sera": "cinder", "ashe": "raven"}},
	"sera": {"dealer": "sera", "brooms": {"sera": "cinder", "eska": "raven", "ashe": "glass"}},
	"bare": {"dealer": "eska", "brooms": {"eska": "", "sera": "", "ashe": ""}},
	"bare_sera": {"dealer": "sera", "brooms": {"eska": "", "sera": "", "ashe": ""}},
}

var _done := false


func _process(_d: float) -> bool:
	if _done:
		return true
	_done = true
	var args := OS.get_cmdline_user_args()
	var n := 200
	var names: Array[String] = []
	for a in args:
		if a.is_valid_int():
			n = int(a)
		elif a == "all":
			for k in BUILDS.keys():
				names.append(String(k))
		elif BUILDS.has(a):
			names.append(a)
	if names.is_empty():
		names = ["eska", "sera"]
	for name in names:
		_run_build(name, n)
	return true


func _run_build(name: String, n: int) -> void:
	var build: Dictionary = BUILDS[name]
	print("\n=== 빌드 %s (딜러 %s) × %d판 ===" % [name, build.dealer, n])
	var stats: Array = []
	for i in TData.BATTLES.size():
		stats.append({"wins": 0, "plays": 0, "rounds": 0, "turns": 0, "max_hit": 0.0, "max_max": 0, "hp_left": 0.0, "interrupts": 0, "dealer_share": 0.0,
			"potions": 0, "casts_fired": 0, "ko": 0, "max_info": {}, "ult_hits": 0.0, "ult_n": 0, "combo": 0.0})
	for s in n:
		var run := TRun.new()
		for w in build.brooms.keys():
			run.brooms[w] = String(build.brooms[w])
		var pol := TPolicy.new(String(build.dealer))
		run.dealer = pol.dealer
		for bi in TData.BATTLES.size():
			var b := TBattle.new()
			b.setup(run, TData.BATTLES[bi], 1000 + s * 17 + bi)
			var st: Dictionary = stats[bi]
			st.plays += 1
			var interrupts := 0
			var casts := 0
			var ko := 0
			var guard := 0
			while not b.over and guard < 200:
				guard += 1
				var inner := 0
				while not b.over and b.mana_left > 0 and inner < 30:
					inner += 1
					var p := pol.potion(b)
					if not p.is_empty():
						b.use_potion(b.find(String(p.unit)), String(p.potion), String(p.get("target", "")))
					var c := pol.choose(b)
					if c.has("end"):
						break
					if not b.act(b.find(String(c.unit)), String(c.spell), String(c.get("target", ""))):
						break
				if not b.over:
					b.end_player_turn()
				for ev in b.take_events():
					match String(ev.type):
						"interrupt":
							if not b.find(String(ev.unit)).ally:
								interrupts += 1
						"cast_fire":
							if not b.find(String(ev.unit)).ally:
								casts += 1
						"die":
							if b.find(String(ev.unit)).ally:
								ko += 1
						"hit":
							var sp := TData.spell(String(ev.spell))
							if String(sp.get("kind", "")) == "ult":
								st.ult_hits += float(ev.dmg)
								st.ult_n += 1
			var sum := b.summary()
			st.rounds += b.round
			st.turns += b.turns
			st.max_hit += float(b.max_hit)
			st.combo += b.best_combo
			st.interrupts += interrupts
			st.casts_fired += casts
			st.ko += ko
			st.potions += b.potions_used
			if b.max_hit > int(st.max_max):
				st.max_max = b.max_hit
				st.max_info = b.max_hit_info
			var total_dealt := 0
			var dealer_dealt := 0
			for a in b.allies(false):
				total_dealt += a.dealt
				if a.id == pol.dealer:
					dealer_dealt = a.dealt
			st.dealer_share += float(dealer_dealt) / float(maxi(total_dealt, 1))
			var hp_left := 0.0
			for a in b.allies(false):
				hp_left += a.hp_ratio()
			st.hp_left += hp_left / 3.0
			if not b.won:
				break
			st.wins += 1
			run.battle_won(sum)
	for bi in TData.BATTLES.size():
		var st: Dictionary = stats[bi]
		var p := maxi(int(st.plays), 1)
		var info: Dictionary = st.max_info
		var mult_s := ""
		if info.has("mult"):
			var m: Dictionary = info.mult
			if m.has("atk"):
				mult_s = "atk×%.2f elem×%.2f crit×%.2f final×%.2f vuln×%.2f aff×%.2f def×%.2f 소모×%.2f = 총 ×%.1f" % [m.atk, m.elem, m.crit, m.final, m.vuln, m.aff, m.def, m.get("consume", 1.0), m.get("total", 0.0)]
			else:
				mult_s = "기폭 ×%.1f" % float(m.get("detonate", 0.0))
		print("[%d %s] 승률 %3d%% (%d/%d) · 라운드 %.1f · 마법 %.1f · 최고한방 평균 %.0f / 최대 %d (%s %s) · 최고연계 ×%.1f · 남은체력 %.0f%% · 끊기 %.2f · 적시전발동 %.2f · 아군KO %.2f · 물약 %.2f · 딜러비중 %.0f%% · 대마법 한타 평균 %.0f"
			% [bi + 1, TData.BATTLES[bi].name, int(100.0 * float(st.wins) / float(p)), st.wins, p, float(st.rounds) / float(p), float(st.turns) / float(p),
			float(st.max_hit) / float(p), int(st.max_max), String(info.get("unit", "")), String(info.get("spell", "")), float(st.combo) / float(p),
			100.0 * float(st.hp_left) / float(p), float(st.interrupts) / float(p), float(st.casts_fired) / float(p), float(st.ko) / float(p),
			float(st.potions) / float(p), 100.0 * float(st.dealer_share) / float(p), float(st.ult_hits) / float(maxi(int(st.ult_n), 1))])
		if mult_s != "":
			print("      최대 한 방 배율: " + mult_s)
