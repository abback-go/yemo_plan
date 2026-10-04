# 적·전투 판정·효과 (개발자 안내)

이 문서만 보고 적을 고치거나 새로 만들 수 있게 쓴 안내다. 다루는 폴더는 `game/enemies/**`, `game/combat/**`, `game/fx/**`, `game/autoload/fx.gd`, `game/core/palette.gd`, `game/core/hit.gd`이다.

---

## 1. 구조 지도

### 1.1 파일

| 자리 | 내용 |
|---|---|
| `enemies/enemy_base.gd` (`EnemyBase`) | 모든 적의 바탕. 체력, 피격(흰 깜빡임·넉백·띄우기·피해 숫자), 중력, 위치 타임, 첫 조우 이름표, 기본 사망 연출, **공통 도우미**(2절) |
| `enemies/enemy_registry.gd` | 1장 적 종류(`KINDS`). 2장부터는 `enemies/chN/registry.gd`의 `KINDS`를 `ChapterRegistry.enemy_kinds()`가 `res://enemies/%s/registry.gd` 경로로 찾아 합친다 |
| `enemies/state_clock.gd` (`StateClock`) | 상태 시간 시계 (opt-in, 3.2절) |
| `enemies/boss_kit.gd` (`BossKit`) | 보스 도우미: 페이즈 문턱, 공격 고르기, 페이즈 배율 (4절) |
| `enemies/ch2/k_enemy.gd` (`KE`) | 2장 도우미: `KE.snd`, `KE.Vis`(그림 노드), `StarPillar`·`MeteorDrop`·`GroundWave`·`StarShard`, `KE.grad` |
| `enemies/ch3/ch3_sfx.gd` (`Ch3Sfx`) | 3장 소리 (없는 소리는 만들어 냄) |
| `enemies/ch4/holy.gd` (`H`) | 4장 도우미: `H.snd`, `H.gold_grad`, `HolyShot`, `SegmentArea`, `LanceDrop`, 빛줄기 추적 `H.trace` |
| `enemies/ch5/st_art.gd` (`StArt`), `st_strike.gd` (`StStrike`), `colossus_art.gd` | 5장 색·그림 도우미, 큰 공격용 "예고 → 타격" 영역 |
| `combat/enemy_attack_area.gd` (`EnemyAttackArea`) | 세라에게 피해를 주는 영역. 세라 쪽(`player.gd`)이 매 프레임 겹친 영역의 `active`·`dodgeable`·`damage`를 읽는다 |
| `combat/enemy_projectile.gd` (`EnemyProjectile`) | 적 탄 공용 (직선·포물선·유도). 불꽃 방벽에 닿으면 `reflect()`로 되쏘아진다 |
| `combat/telegraph_hazard.gd` (`TelegraphHazard`) | 단순한 "예고 → 타격 → 사라짐" 시간표 바탕 (5절) |
| `combat/fire_*.gd`, `meteor_fall.gd` … | 세라의 마법 (적 영역이 아니지만 같은 폴더) |
| `autoload/fx.gd` (`Fx`) | 히트스톱·슬로모션·위치 타임·흔들림·번쩍임·파티클(`burst`)·고리(`ring`)·피해 숫자 (6절) |
| `core/palette.gd` (`Palette`) | 색 상수 + 캐시된 파티클 색 변화(Gradient) |
| `core/hit.gd` (`Hit`) | 공격 한 번의 정보 + 공격 종류(kind) 묶음 (7절) |

큰 보스의 부품은 파일을 나눴다. 원래 내부 클래스 이름은 `const 이름 := preload(...)` 별칭으로 남아 있어 `SkyGateEye.new()`, `var e: SkyGateEye` 같은 코드가 그대로 동작한다.

- `ch5/sky_gate.gd` → `sky_gate_eye.gd`, `sky_gate_tendril.gd`, `sky_gate_visual.gd`, `sky_gate_shield.gd`
- `ch3/white_herald.gd` → `white_herald_lance.gd`, `white_herald_cage.gd`, `white_herald_sigil.gd`, `white_herald_visual.gd`
- `ch4/aurelia_boss.gd` → `aurelia_halo_disc.gd`, `haetae.gd` → `haetae_roof_tile.gd`

### 1.2 EnemyBase의 한 프레임

```
_ready:  그룹 enemy, 충돌층 → _build() (자식이 max_hp·body_size·그림 노드를 정함) → 난이도 체력 배율 → 몸·피격 상자 생성
_physics_process(delta):
  쓰러졌으면 _flash만 줄이고 끝 (쓰러진 뒤 움직임은 자식이 _physics_process를 덮어써서: 3.4절)
  d = delta × Fx.enemy_time (위치 타임)
  넉백 중 → 밀림 / 띄워져 공중 → 감속 / 아니면 → _ai(d)   ← 자식의 행동
  move_and_slide (속도 × enemy_time)
  그림 노드 queue_redraw (화면 밖이면 생략: 8절)
take_hit(hit): modify_damage(hit) → 0이면 _on_blocked / 피해·깜빡임·숫자 → _on_hit(hit, dir) → 넉백·띄우기 → 체력 0이면 _die(dir)
```

자식이 덮어쓰는 함수: `_build`, `_ai(delta)`, `modify_damage(hit)`, `_on_hit(hit, dir)`, `_on_blocked(hit)`, `_resists_knockback(hit)`, `_on_landed_from_launch`, `_die(dir)`.

### 1.3 그림 방식 (장마다 다름)

| 장 | 방식 |
|---|---|
| 1장 | `class_name`이 있는 `*_visual.gd` (예: `ChargerVisual`) |
| 2장 | `KE.Vis`에 그리기 함수(`Callable`)를 넘기고, 적 스크립트의 `_draw_body(c)`가 그림 |
| 3장 | 적 파일 안의 내부 클래스 (`StagVisual` 등) |
| 4장 | `class_name` 없는 `*_visual.gd` (적이 `preload`) |
| 5장 | 위가 섞임 (`StarConstructVisual`, 내부 클래스, `CharacterVisual`) |

**앞으로 쓸 방식(권장)**: 4장처럼 적 하나에 `*_visual.gd` 한 파일(`extends Node2D`, `var enemy: 그적`), 적의 `_build`에서 `_visual = VIS.new()`. 그림 노드는 `enemy.state`, `enemy.progress()`, `enemy.flash_amount()`, `enemy.facing`만 읽게 하고, 매 프레임 `queue_redraw()`를 직접 부르지 말 것 (EnemyBase가 부른다). 그림 노드가 따로 `_process`에서 다시 그려야 하면 `if enemy.should_redraw(): queue_redraw()`.

---

## 2. EnemyBase 도우미 (새 코드에서 먼저 찾을 것)

| 도우미 | 용도 |
|---|---|
| `player()`, `dist_to_player()`, `dir_to_player()`, `face_player()` | 세라 찾기·방향 |
| `shoot(pos, dir, speed, style, opts)` | `EnemyProjectile` 발사 |
| `add_attack_area(size, offset, cause, damage)` | 몸에 붙는 공격 영역 (켜고 끄기는 `active`) |
| `place_area(area, off)` | 공격 영역을 바라보는 쪽으로 옮김 (`off`는 오른쪽 기준) |
| `ray_point(from, to, mask)` | 광선이 처음 닿는 점, 없으면 `Vector2.INF` |
| `ledge_at(dir, ahead, depth)` / `ledge_ahead(ahead, depth)` | 앞쪽 발밑이 비었나 (기본 14px 앞, 20px 아래) |
| `floor_y_at(x, from_y, to_y, fallback)` | x 위치 아래 바닥 y |
| `wall_x(reach, y_off, gap)` | 바라보는 쪽 벽 바로 앞 x |
| `has_los(from, to)` | 벽(L_WORLD)에 가리지 않나 (발판은 시야를 막지 않음) |
| `hit_side(hit, deadzone, center)` | 맞은 쪽 1 정면 / −1 등 / 몸 가운데면 `center` |
| `is_fox_hit(hit)`, `dist_to_body(e, p)` | 여우 공격인가, 큰 적 몸까지 거리 |
| `play_sfx(name, fallback, …)` / `play_sfx_pitch` | 소리 + 없을 때 대체 소리 (`KE.snd`·`H.snd`·`StArt.sfx`가 이것을 부름) |
| `_record_defeat`, `_disable_body`, `_defeat_quiet`, `_post_death_fall` | 퇴장 (3.4절) |
| `should_redraw()`, `cull_offscreen`, `redraw_margin` | 화면 밖 다시 그리기 생략 (8절) |

---

## 3. 새 적 추가

### 3.1 체크리스트
1. `game/enemies/chN/새적.gd` — `extends EnemyBase` (+ 이름이 필요하면 `class_name`).
2. `_build()`: `max_hp`, `body_size`, `kind_id`, `display_name`, `subtitle`, `is_elite`/`is_boss`, 그림 노드(`_visual`), 공격 영역(`add_attack_area`).
3. `_ai(delta)`: 상태 기계 (3.2절). 피해는 `delta` 그대로 쓴다 (이미 위치 타임이 곱해져 있음).
4. `enemies/chN/registry.gd`의 `KINDS`에 `"kind": "res://enemies/chN/새적.gd"` 추가. **kind 이름은 방 데이터와 저장(`seen_` + kind_id 플래그)이 쓰므로 정한 뒤에는 바꾸지 않는다.**
5. 방 데이터가 `set()`으로 넣을 속성(예: `patrol`, `sleep`, `engaged`)은 `var`로 선언 (없으면 조용히 무시됨).
6. 시험: `tools/test/scenarios/`에 `spawn_enemy` 시나리오를 하나 만들고 `tools/test/regress.sh`로 돌린다.

### 3.2 상태와 시간: StateClock (opt-in)
지금 적들은 `state` + `_timer` + `_dur` + 전환 함수(`_enter`/`_go`/`_set_state`) + 진행도(`progress`/`state_k`/`state_progress`)를 저마다 갖고 있다. 새 적과 손보는 적은 `StateClock`을 쓴다.

```gdscript
var state: S = S.IDLE
var _clock := StateClock.new()        # dur 0일 때 k() = 1.0 (1·2·4장 관례). 3장·해태 관례는 StateClock.new(0.0)

func _go(s: S, time := 0.0) -> void:
	state = s
	_clock.enter(time)

func progress() -> float:            # 그림 노드가 읽는 이름은 그대로 둔다
	return _clock.k()

func _ai(delta: float) -> void:
	_clock.tick(delta)                # 예전에 _timer를 줄이던 바로 그 자리에서
	match state:
		S.WINDUP:
			if _clock.done(): …
```

- **기반 클래스는 자동으로 tick하지 않는다.** 적마다 `_timer`를 줄이는 위치가 달라(해태·등불 눈 등) 자동으로 하면 타이밍이 바뀐다.
- `state` 변수는 기반 클래스에 두지 않는다 (GDScript는 자식이 부모와 같은 이름의 멤버를 다시 선언할 수 없다).
- 지금 적용된 적: 4장 `pilgrim_shade`·`seraph_statue`·`bell_wraith`·`lumen_eye`, 2장 `gargoyle`·`cultist`·`star_lizard`·`star_wolf`·`sewer_jelly`·`watchman`. 나머지는 손볼 때 하나씩 옮기고 시나리오로 확인할 것.
- 그림 노드가 `enemy._timer`를 직접 읽는 적(1장 `charger`·`sniper`·`lantern_watcher`, `agwi`, `alchemy_slime`)은 그림 쪽도 함께 고쳐야 한다.

### 3.3 공격 판정
- 몸에 붙는 공격: `var a := add_attack_area(크기, 위치, &"원인", 피해)`, 휘두를 때 `place_area(a, off)` 후 `a.active = true`. 대시로 스치면 퍼펙트 회피가 되는 공격만 `dodgeable = true`.
- 탄: `shoot(...)` (EnemyProjectile). 불꽃 방벽에 닿으면 저절로 되쏘아진다(`reflected`, `Hit.kind = reflect`). 장별 탄(`StShot`, `HolyShot`, `StarShard`)도 이것을 상속한다.
- `SniperShot`(1장 저격탄)과 `ElfArrow`는 EnemyProjectile을 쓰지 않는다. **SniperShot은 `enemy_projectile` 그룹에 없어 되쏠 수 없다** — 합치면 되쏘기가 가능해져 동작이 바뀌므로 그대로 두었다.
- `cause`는 결과 화면의 피격 원인 이름이다.

### 3.4 퇴장 (쓰러짐)
- 기본: 아무것도 안 하면 `EnemyBase._die`가 기록·영혼 입자·흰 번쩍임 뒤 사라진다.
- 자기 연출로 쓰러지는 적: `_die`를 덮어쓰고 `super`를 부르지 않는다. 앞부분은 도우미로:
  - `_defeat_quiet(kill_stat := "kills", mark := true, style := true, hitstop := -1.0)` — 살아 있음 끄기 → 기록 → 멈춤 → `defeated` → 몸 끄기 (기본 `_die`와 같은 순서)
  - 순서가 다른 적(상태를 바꾼 뒤 `defeated`를 내야 하는 보스 등)은 `_record_defeat(kill_stat, style, mark)`와 `_disable_body(areas)`를 나눠 부른다.
  - 쓰러진 뒤 바닥까지 떨어뜨리기: `_physics_process`를 덮어쓰고 `super(delta)` 뒤 `if not _alive: _post_death_fall(delta)`.
- **보존한 차이 (의도인지 확인 필요)**: 결투 상대(`isolde_duel`·`shadow_sera`·`veronica_duel`)는 처치 표시·`kills`·등급을 남기지 않는다. `noxis`가 절반에서 도망칠 때(`_finish_flee`)는 처치 표시만 하고 `kills`·등급·`defeated` 없이 `fled`를 낸다(한 번에 쓰러지면 기본 `_die`). `white_herald`·`meteor_beast`·`leonie_duel`·`lyra_boss`·`sky_gate`는 등급 처치(`StyleRank.on_kill`)를 세지 않는다. `gold_herald`는 쓰러진 뒤 몸 접촉 판정을 끄지 않는다. `moss_stag`·`white_herald`·`aurelia_boss`는 쓰러진 뒤 `_flash`를 기반과 함께 한 번 더 줄여 2배 빨리 걷힌다.

---

## 4. 새 보스 만들기

1. 3절과 같이 만들고 `is_boss = true`, `engaged = false`(대본이 켬). HUD 체력바·화면 밖 그리기 생략 제외가 따라온다.
2. **페이즈**: `var phase := 1`(대본이 읽음), 문턱은 상수 배열로.
   ```gdscript
   const PHASE_AT: Array[float] = [0.66, 0.33]
   func take_hit(hit: Hit) -> void:
   	var before := hp
   	super(hit)
   	if not _alive: return
   	var n := BossKit.phase_cross(self, phase, before, PHASE_AT)   # 한 방에 문턱을 넘지 못하게 hp를 문턱에 멈춤
   	if n > 0:
   		phase = n
   		phase_changed.emit(n)   # 대본이 듣는다
   		… 전환 연출(무적 상태로) …
   ```
3. **공격 고르기**: 후보 목록 → `BossKit.pick_attack(pool, _last, test_queue, "기본공격")`. `test_queue`(방 데이터가 넣음)가 있으면 그 순서대로 나와 시나리오가 특정 공격을 시험할 수 있다.
4. **페이즈별 빠르기**: `Difficulty.telegraph(sec * BossKit.phase_mult(phase, [1.0, 0.9, 0.75]))`. 예고 시간은 늘 `Difficulty.telegraph`, 쉬는 시간은 `Difficulty.rest`로 감싼다(난이도 설정).
5. **예고**: 큰 공격은 `StStrike.spawn(...)`(띠·기둥·원·선·감옥, 따라다니기, 예고 색 규칙), 바닥 가시처럼 단순한 것은 `TelegraphHazard`를 상속(5절). 예고는 붉은색(위험), 바깥 신들만 흰색.
6. 다른 영역이 부르는 보스 API(대본·동료): `defeated`, `phase_changed`, `enraged`, `support_needed` 신호, `boss.resume()`, `gate.cut_tendril/…` — 이름을 바꾸지 말 것.

현재 `BossKit`을 쓰는 곳: `aurelia_boss`(문턱·공격 고르기·배율), `lyra_boss`(문턱), `meteor_beast`(배율). `white_herald`·`sky_gate`·`leonie_duel`·`gold_herald`는 비교 방식이 조금 달라(실수 비교, 한 번에 여러 페이즈) 그대로 두었다.

---

## 5. 예고 → 타격 위험 지대

`TelegraphHazard`(combat/)는 시간표만 맡는다: `0 ─ delay(예고) ─ 터짐(_on_fire, area 켜짐) ─ hit_time 뒤 area 끔 ─ life 뒤 사라짐`, 매 프레임 `queue_redraw`.

```gdscript
class IceSpikes extends TelegraphHazard:
	func _ready() -> void:
		hit_time = 0.3; life = 0.7
		area = EnemyAttackArea.with_rect(Vector2(w, 30), Vector2(0, -15)); area.active = false; add_child(area)
	func _on_fire() -> void: 소리·입자
	func _draw() -> void: if _t < delay: 예고 … else: 가시 …
```
옵션: `use_enemy_time`(위치 타임에 느려짐), `in_physics = false`(_process에서 셈), `end_inclusive`(끝 시각 비교 >= / >). 지금 쓰는 곳: `IceSpikes`(이졸데), `ShadowSpikes`(베로니카), `_ShadowPillar`(그림자 세라), `RainMark`(엘라리엔). 남은 비슷한 것(`KE.StarPillar`·`MeteorDrop`, `H.LanceDrop`, 해태 `RoofTile`, 바닥 파동 여럿)은 그림·판정이 더 복잡해 그대로 두었다.

---

## 6. 효과 API (Fx, Palette)

| 함수 | 메모 |
|---|---|
| `Fx.hitstop(sec)`, `Fx.slowmo(scale, real_sec)`, `Fx.witch_time(scale, real_sec)` | 실제 시간 기준 (시험에서는 `FRAME_CLOCK=1`이면 프레임 기준: 9절) |
| `Fx.enemy_time` | 위치 타임 중 적·적 탄의 시간 배율. 적이 직접 만든 노드(탄·위험 지대)는 `delta * Fx.enemy_time`을 써야 함께 느려진다 |
| `Fx.shake(T, sec)`, `Fx.flash(color, sec)`, `Fx.zoom_punch(k)`, `Fx.set_vignette(0~1)` | 화면 |
| `Fx.burst(pos, n, opts)` | 한 번 터지는 파티클. opts: direction, spread, speed_min/max, gravity, damping, lifetime, lifetime_random, size_min/max, gradient, box, radius, z, add, explosiveness |
| `Fx.ring(pos, r0, r1, color, sec, width, additive)` | 퍼지는 고리 |
| `Fx.effect_parent()` | 효과 노드를 붙일 곳 (방을 옮기면 비워짐) |
| `Palette.fade_gradient(c)`, `fire_gradient()`, `soul_gradient()`, `grad2(c0, c1)`, `cached_gradient(offsets, colors)` | **캐시된 같은 Gradient를 돌려준다 — 받은 것을 고치지 말 것** (고칠 일이 있으면 `duplicate()`) |

`Fx.burst`는 다 터진 노드를 풀에 모았다가 `restart()`로 다시 쓴다. 그래서 **반환값을 붙잡아 두거나 고치지 말 것.** 전역 난수 소비는 새로 만들 때와 같게 맞춰 두었다(새 노드는 생성자가, 다시 쓰는 노드는 `restart()`가 시드를 한 번 뽑음) — 풀을 고칠 때 이 규칙을 깨면 적 AI의 무작위 결과까지 바뀐다.

---

## 7. 공격 종류(kind) 묶음 — core/hit.gd

`Hit.kind`는 세라 쪽이 정한다(`bolt`, `bolt_heavy`, `blast`, `pillar`, `storm`, `storm_final`, `burst`, `reflect`, `ward`, `meteor`, `phoenix`, `ally`, 여우 모드 `fox*` …). 적이 "방패로 못 막는다·자세를 깬다·무겁다"를 정하는 목록은 `Hit`에 이름 붙여 모았다: `FIRE_BOLTS`, `PASS_SHIELD_ARMOR/WATCHMAN/GOLD_HERALD/MONK/ELF_WARDEN/STAR_KNIGHT`, `PARRYABLE_LEONIE`, `GUARD_BREAK_LEONIE`, `HEAVY_LIZARD/GLADIATOR`, `STONE_BLOCKS_STATUE`, `FOX_HEAVY`.
적마다 조금씩 다른 값은 예전 그대로다(의도 확인 전). **새 마법(kind)을 만들면 이 묶음들에 넣을지 함께 정할 것** — 빠뜨리면 그 마법만 방패에 막히는 식으로 조용히 달라진다.

---

## 8. 성능 규칙

- **매 프레임 다시 그리기는 화면 안에서만.** CanvasItem은 화면 밖이어도 `queue_redraw` 하면 `_draw` 스크립트를 실행한다(컬링은 렌더 단계에서만). EnemyBase가 `should_redraw()`로 카메라 사각형 + `redraw_margin`(96px) + 몸 크기 밖이면 그림 노드를 다시 그리지 않는다. 보스는 늘 다시 그린다.
  - 그림이 몸에서 멀리 뻗는 적(조준선·빛줄기·착지 표시·충격파·별자리 선·거신)은 `_build`에서 `cull_offscreen = false` (지금: sniper·lantern_watcher·lumen_eye·alchemy_slime·holy_monk·colossus·star_wisp).
  - 그림 노드가 자기 `_process`에서 다시 그리면 `if enemy.should_redraw(): queue_redraw()` (KE.Vis, StarConstructVisual, outer_seraph가 이렇게 함).
  - 측정(적 16마리, 화면 안 4 · 밖 12, 120프레임): 그림 노드 `_draw` 2640회 → 600회.
- **파티클은 `Fx.burst`로.** 직접 `CPUParticles2D.new()`를 자주 만들지 말 것. 측정(2프레임마다 burst 2개 × 600): 새로 만든 CPUParticles2D 796개 → 52개, burst 한 번 약 134~146µs → 76~81µs(다른 작업과 CPU를 나눠 쓰는 상태라 ±20%).
- **Gradient는 Palette 캐시로.** `Gradient.new()`를 프레임마다 하지 말 것. `fade_gradient` 2만 번: 29~33ms → 9.9ms.
- 짧은 간격으로 계속 뿜는 곳(해태 숨결 0.035초마다 2개, charger 꼬리, fire_bolt·phoenix 2프레임마다)은 풀 덕분에 노드 생성이 없어졌다. 켜 둔 방출기 하나로 바꾸면 더 줄지만 전역 난수 소비가 달라져 다른 무작위 동작이 바뀌므로 하지 않았다.
- 폭주 비네트는 세기 0이면 숨긴다(전체 화면 셰이더 생략).
- 무거운 그림: `sky_gate_visual.gd`(GateVisual)과 `colossus.gd`의 `ColossusVisual`은 보스전·절망 구간에서만 생긴다. 측정값은 리팩터 보고서 참고.

---

## 9. 함정 (조용히 깨지는 것)

- **방 데이터 속성**: 방이 `if k in en: en.set(k, v)`로 넣는다. 이름을 바꾸면 오류 없이 무시된다: patrol, stride, step_time, interval, sleep, mode, link, order, loop, orbit, source, beam_deg, alarm_flag, small, blighted, grand, line, free_flag, engaged, test_queue, auto_support.
- **종류 이름**: `kind`(레지스트리 키)와 `kind_id`(첫 조우 플래그 `seen_`+kind_id), 장별 레지스트리 경로 `res://enemies/%s/registry.gd`.
- **시험 실행기(runner.gd)가 읽는 것**: `res://enemies/sniper_shot.gd`, `res://combat/fire_pillar.gd`, `res://enemies/enemy_registry.gd` 경로, `find_children(…, "SniperShot"/"FirePillar")`, FirePillar의 `_t`·`_erupted`·`_w`·`_h`, STATUS 줄의 `kind_id:hp/max_hp`(체력 값을 옮길 때 정확히 같아야 함), 그룹 enemy·enemy_projectile.
- **그림 노드가 읽는 비공개 필드**: `enemy._timer`(1장 charger·sniper·lantern_watcher, agwi, alchemy_slime), `_t`, `_airborne_spin`, `Charger.S.*`, 5장 문자열 상태(star_construct_visual). `flame_ward.gd`는 탄의 `_vel`·`reflected`·`active`를 덕 타이핑으로 읽는다.
- **`extends "경로"`·`preload`**: `leonie_spar/duel ← leonie_base.gd`, `ash_moth ← ash_shade.gd`, 장별 도우미(`holy.gd`, `k_enemy.gd`, `st_art.gd`, `ch3_sfx.gd`)를 다른 영역도 preload한다. 파일을 옮기면 전부 grep.
- **시험의 시간**: 히트스톱·슬로모션·위치 타임은 실제 시간(ms) 기준이라 컴퓨터가 바쁘면 같은 시나리오도 결과·스크린샷이 달라진다. 비교할 때는 `FRAME_CLOCK=1 tools/test/regress.sh …`로 돌려 프레임 수 기준으로 잰다(`Fx.frame_clock`, 게임에서는 꺼짐). 전후를 모두 같은 방식으로 돌려야 비교가 된다.
