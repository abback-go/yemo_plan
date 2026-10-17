# 세라(플레이어) 구조 — 고치는 사람용 안내

대상 코드: `game/player/`, `game/fox/`, `game/core/tuning.gd`·`tuning.tres`, `game/core/enemy_query.gd`.
인물 그림·동료는 [characters.md](characters.md).

## 1. 구조 지도

```
Player (player.gd, CharacterBody2D)  ← 겉(파사드). 바깥은 이 이름들만 쓴다 (참조 약 185곳)
 ├ motor  : PlayerMotor  (player_motor.gd)  달리기·점프·중력·활공·발판·천장 보정·대시·2단 점프·착지
 ├ caster : PlayerCaster (player_caster.gd) 화염탄·장착 칸 마법·물약·여우창문·재사용 대기(cooldowns)
 ├ gauge  : PlayerGauge  (player_gauge.gd)  폭주 게이지·과열·폭주 폭발·여우 모드 시작/끝
 ├ health : PlayerHealth (player_health.gd) 체력·피격·가시·퍼펙트 회피·사망·불사조 부활
 └ 자식 노드 (player.tscn): Visual/Flip/Body(PlayerVisual) · Camera2D(GameCamera) · Hurtbox
PlayerText (player_text.gd)  전투 중 토스트·배너·너울 말풍선 문구
FoxPalette (fox/fox_palette.gd)  여우불 색 3개
EnemyQuery (core/enemy_query.gd)  "가장 가까운 적"·"범위 안 적마다" 공용
```

- 컴포넌트는 `RefCounted`이고 `p: Player`를 들고 있다. 노드가 아니므로 물리 프레임 순서는 **player.gd의 `_physics_process`가 부르는 순서 그대로**다.
- 상태 값의 자리:
  - 바깥이 읽고 쓰는 값은 Player에 그대로 있다: `state`, `facing`, `hp`, `overload`, `fox_time`, `fox_energy`, `controls_enabled`, `no_overload`, `air_dashes_left`, `air_jumps_left`, `last_jump_height_t`, `tuning`, `camera`.
  - 바깥이 **문자열**로 쓰는 비공개 이름도 Player에 그대로 있다: `_hurt_iframe`, `_stun_timer`, `_ward_time` (3절).
  - 나머지 타이머·내부 상태는 각 컴포넌트에 있다. 형제 컴포넌트가 읽는 것만 `_` 없이 둔다 (예: `motor.dash_iframe`, `caster.storm_timer`, `caster.ult_float`, `caster.potion_timer`, `gauge.fuse`, `health.hazard_cool`).
  - 컴포넌트는 Player의 연출 함수 `_squash_to`·`_spawn_afterimage`·`_banner`와 `_body`·`_visual`·`_hurtbox`를 친구처럼 직접 쓴다.
- 재사용 대기는 `caster.cooldowns` 사전 하나다 (`pillar`·`storm`·`ward`·`meteor`·`phoenix`). 옛 이름 `pillar_cooldown_left`·`storm_cooldown_left`·`ward_cooldown_left`는 이 사전을 읽고 쓰는 속성으로 남아 있다(HUD·시험 실행기가 읽음).
- 상태 → 그림 자세는 `Player.POSE_OF` 표로 정한다. `State`와 `PlayerVisual.Pose`의 enum 순서에 기대지 않는다.

### 한 물리 프레임의 순서 (`Player._physics_process`)

1. `_tick_timers` → `motor.tick` · `caster.tick`(물약이 끝나면 회복) · `gauge.tick` · `health.tick`(피격·경직이 끝나면 FALL)
2. DEAD면 `motor.process_dead` → 그림 → 끝
3. 입력: 좌우 축 → `motor.walk_input`(컷신 걷기) → 물약 중 30% → `_can_act()`면 `_read_action_input`
4. 상태별 이동: DASH `motor.process_dash` / HURT·STUN `motor.process_hurt` / 그 밖 방향 전환 + `process_run` + `process_jump` + `apply_gravity`
5. `motor.move()`(move_and_slide + 천장 모서리 보정) → `motor.after_move()`(착지·안전한 땅·먼지·잔상)
6. `_update_state` → `health.check_hurtbox` → `gauge.update` → `_update_visual`

이 순서를 바꾸면 점프 높이·피격 판정 프레임이 달라진다. 바꿔야 하면 회귀 시험(5절)의 STATUS 줄을 꼭 비교한다.

### 입력 → 동작

| 입력 동작 | 처리 |
|---|---|
| `jump` | 공중이면 활공 준비 → 발판 위 ↓+점프면 `drop_through`, 공중 점프 가능하면 `double_jump`, 아니면 점프 버퍼 |
| `attack` | `caster.buffer_attack` + `caster.try_fire`(누르고 있으면 `shot_interval`마다) |
| `dash` | `motor.can_dash` → `motor.start_dash` |
| `skill_1/2/3` | `cast_slot("a"/"s"/"f")` → 장착된 마법 id로 분기 |
| `potion` · `fox_window` | `caster.drink_potion` · `caster.open_window` |

멈춤 안내(teach) 중에 누른 키는 `buffer_action(a)`가 같은 처리로 이어서 실행한다.

### 마법 시전 흐름

`cast_slot(slot)` → `Spells.equipped(slot)`로 id → `caster.cast_slot`의 `match id`:
- `pillar` → `_cast_skill_1`(여우 모드면 `FoxRain`, 아니면 `_cast_pillar`: `_find_pillar_target` → `FirePillar`)
- `storm` → `_cast_skill_2`(여우 모드면 `NineTailStorm`, 아니면 `_cast_storm`: `FireStorm` + Lv3 `BurnGround`)
- `ward` → `cast_ward`(`FlameWard`, `_ward_time` = 무적)
- `meteor`·`phoenix` → `_cast_meteor`·`cast_phoenix` (`ult_float` 동안 떠 있음·무적·조작 잠김)

각 시전은 ① 효과 노드 생성 ② `cooldowns[id]` 설정 ③ `_pose(시간, 종류)` ④ `GameState.add(통계)` ⑤ `gauge.add(폭주량)` 순서다.
피해·재사용의 레벨 배율은 `Spells.dmg_mult`·`Spells.cooldown_for`(core/spells.gd), 레벨별 그 밖의 차이는 tuning "Spell Levels" 묶음.

## 2. 이럴 때는 여기를 고친다

### 수치 조정
- 거의 모든 수치: `core/tuning.gd`(기본값) / `core/tuning.tres`(에디터에서 바꾼 값). 묶음: Move·Jump·Dash·Fire Bolt·Skill·Overload·Health·**Fox Mode**·**Potion · Revive**·**Spell Levels**.
- 여우 모드 시간·기운 회복: `fox_duration*`, `fox_recharge*`. 여우 모드 재사용 배수: `fox_pillar_cd_mult`, `fox_storm_cd_mult`.
- 물약 회복·시간: `potion_heal`, `potion_time`. 불사조 회복·부활 체력: `phoenix_*`.
- 레벨별 차이(2단 점프 배수, 활공 속도, 불씨, 연쇄 기둥 수, 불바다): `levitate_*`, `wings_*`, `ember_*`, `pillar_lv3_extra_sides`, `storm_lv3_burn_*`.
- 마법 재사용 기본값: `pillar_cooldown`·`storm_cooldown`(tuning), 고급 마법·방벽은 `Spells.ULT_CD`·`WARD_CD`.
- 문구: `player/player_text.gd`. 피피 물약 대사·너울 퇴장 대사는 `randi()`로 고르므로 줄 수를 바꾸면 고르는 줄이 바뀐다(시험 로그가 달라질 수 있음).

### 새 마법/능력 추가 (체크리스트)
1. `core/spells.gd` `DATA`·`ORDER`에 id 추가(이름·등급·장착 칸·설명). 재사용 대기 계산은 `Spells.cooldown_for`.
2. 효과 노드를 `game/combat/`(또는 여우면 `game/fox/`)에 만든다. 적을 찾을 때는 `EnemyQuery.nearest`/`within`.
3. `player_caster.gd`:
   - `cooldowns`에 id 키 추가(없으면 `spell_cooldown`이 `Vector2.ZERO`를 돌려 HUD에 안 보임).
   - `cast_slot`의 `match id`에 분기 추가 → `_cast_<id>()`에서 1절의 ①~⑤ 순서로.
   - 여우 모드에서 다른 효과면 `_full_cooldown`에 배수 추가.
4. 수치는 tuning에 `@export`로(기본값 = 지금 값), 문구는 `player_text.gd`에.
5. 무적·조작 잠금이 필요하면 `ult_float`을 쓰거나 `Player.is_invincible`/`_can_act`에 조건 추가.
6. HUD 아이콘·터치 버튼은 `spell_cooldown(id)`만 읽게(ui 쪽).
7. 회귀: `training_targets`, `sys_ui`, `touch_controls` + 그 마법을 쓰는 시나리오.

### 새 이동 능력 (예: 벽 점프)
`player_motor.gd`에 상태·함수를 두고, 입력은 `Player._read_action_input`에서 분기, 매 프레임 처리는 `_physics_process`의 상태별 분기에서 부른다. 새 `State`를 더하면 `PlayerVisual.Pose`와 `POSE_OF` 표에도 짝을 더한다.

### 바깥에서 세라를 바꿀 때 (대본·적)
| 하고 싶은 것 | 쓰는 API |
|---|---|
| 잠깐 무적 (더 길면 유지) | `grant_iframes(t)` |
| 무적 시간을 정확히 (줄이기 포함) | `set_iframes(t)` |
| 경직 | `stun(t)` |
| 체력 정하기 (GameState·HUD 반영) | `set_hp(v)` · `heal(n)` · `heal_full()` |
| 재사용 대기 정하기 | `set_cooldown(id, t)` |
| 방벽 무적만 | `set_ward_time(t)` |
| 방벽 바로 시전 | `cast_ward()` (옛 이름 `_cast_ward`도 남아 있음) |
| 폭주·여우 | `force_overload_full()`, `start_fox_mode()` |
| 컷신 | `halt()`, `walk_to(x)`, `place_at(pos, face)`, `controls_enabled` |

## 3. 함정 (조용히 깨지는 것)

- **문자열 `set`/`call`이 쓰는 이름**: 이름을 바꾸면 오류 없이 동작만 사라진다.
  - `_hurt_iframe`: `story/scripts_ch5.gd`(`set`), `enemies/ch5/sky_gate.gd`(`set`/`get`). 시험 실행기 godmode는 이제 `set_iframes`를 쓴다.
  - `_stun_timer`: `enemies/ch2/gladiator.gd`(`set`, `state = STUN`과 함께) → `stun(t)`로 바꾸면 된다.
  - `_ward_time`: 시나리오 `ch4_full.json`·`ch4_mirrors.json`의 `["set", "_ward_time", 3.0]`.
  - `fox_time`: 시나리오 `shot_single_vs_fox_pierce.json`의 `set`.
  - `_cast_ward`: `story/scripts_ch2.gd`의 `call("_cast_ward")`.
- **`tools/test/runner.gd`는 타입 없는 변수**라 이름이 틀려도 컴파일 오류가 없다. 읽는 이름: `camera`, `hp`, `overload`, `state`, `facing`, `velocity`, `air_dashes_left`, `last_jump_height_t`, `controls_enabled`, `fox_time`, `ward_cooldown_left`, `is_warding()`, `cast_slot()`, `center()`, `take_damage()`, `set_iframes()`.
- **시나리오 76개가 godmode를 쓴다.** `set_iframes`·`_hurt_iframe`이 깨지면 시험 중 세라가 죽는다.
- `take_damage`는 `set_hp`를 쓰지 않는다: 알림(`hp_changed`) 전에 통계(`hits_*`)와 스타일 점수를 먼저 갱신하는 원래 순서를 지킨다. `restore_from_state`는 GameState에 다시 쓰지 않는다(일부러 다름).
- `_update_visual`의 피격 깜빡임은 `_hurt_iframe`에서 계산한다 → godmode(무적 9999초) 중에는 세라가 반투명으로 깜빡인다. 스크린샷 비교에서 정상.
- 대본이 `player.hp = …`로 직접 쓰면 GameState·HUD에는 반영되지 않는다(`scripts_prologue.gd` 한 곳이 이렇게 씀). 반영이 필요하면 `set_hp`.
- 컴포넌트를 노드로 바꾸면 `_physics_process` 호출 순서가 트리 순서로 바뀐다 — 지금처럼 Player가 명시적으로 부르게 둘 것.

## 4. 성능 규칙

- PlayerVisual은 매 물리 프레임 1회 다시 그린다(세라 하나라 괜찮음). 잔상(`_spawn_afterimage`)은 한 번만 그린다.
- 적 탐색은 `EnemyQuery`로: 그룹 순서대로 보고 동점이면 먼저 나온 것 — 기존 루프와 결과가 같다. 매 프레임 부르는 곳(여우불 유도)은 메서드 Callable(`_ahead_dist`)을 넘겨 람다를 만들지 않는다.
- `EnemyQuery.within`은 적마다 그 자리에서 `is_alive`를 확인한다(앞의 타격으로 죽은 적은 건너뜀). 목록을 먼저 모아 두었다가 때리는 식으로 바꾸지 말 것.
- 여우 대시 잔불(`FoxTrail`)은 0.035초마다 Area2D를 만든다 — 짧게만 돌아 그대로 둠.

## 5. 회귀 시험

```
JOBS=2 tools/test/regress.sh $G <출력> drop_through room_bounds_haetae shot_single_vs_fox_pierce training_targets \
  haetae_demo_fight agwi_pace sys_glide sys_allies sys_ui touch_controls save_continue ch4_chase \
  ch5_climb_colossus ch2_sewer ch2_boss_beast ch5_awaken_ride
```
전후 `summary.txt`(`#` 줄 제외)와 `python3 tools/test/imgdiff.py 전/shots_X 후/shots_X`가 같아야 한다. `SCRIPT ERROR`·`engine_err` 0.

**주의 — 전투 시나리오는 CPU가 바쁘면 실행마다 달라진다.** `Fx.hitstop`·`slowmo`·`witch_time`(autoload/fx.gd)이 실제 시간(`Time.get_ticks_msec`)으로 끝나서, 느리게 돌면 경직이 더 적은 프레임 동안 걸린다(같은 코드로 `agwi_pace` 보스 체력이 1560/1500으로 갈림). 전후 비교는 두 사본에서 `Time.get_ticks_msec()`를 프레임 시계 `(Engine.get_process_frames() * 50 / 3)`로 바꿔 돌렸다(시험 사본에서만).

성능 확인: 시험 명령 `[프레임, "drawcount", 이름, "CharacterVisual", N]`이 N프레임 동안 그 클래스 노드의 다시 그리기 횟수를 `DRAWS` 줄로 출력한다(CPU 경쟁과 상관없는 지표).
