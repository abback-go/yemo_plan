# 월드·방·소품·방 생성기 (개발 문서)

다음 사람이 이 문서만 보고 방을 고치고, 개체·소품을 더하고, 성능을 해치지 않게 하려고 쓴 문서다.
배경 그리기(`game/world/themes/**`)는 `docs/dev/backdrop.md`, 조건식(`cond`)과 대본은 `docs/dev/story.md`를 본다.

## 1. 구조 지도

### 방 데이터가 흘러가는 길

```
tools/roomgen.py (1장 방 + 공용 도우미)  ─┐
tools/rooms/ch2.py · ch3.py · ch4.py ·    ├─ python3 tools/roomgen.py ─→ game/world/rooms/<방ID>.gd   (RoomData 상속, 방 하나)
          ch5.py · sys.py (장별 방·덧붙임) ─┘                         └→ game/world/rooms/_index.gd  (모든 방 메타 색인)

World.load_room(id) ─ RoomIndex.load_full(id) ─ Room.build(data)
   ├ RoomBackdrop.build        배경 (W1 영역, 시드 = hash(방 ID))
   ├ TilePainter.paint         타일을 이미지 한 장으로 굽기 (진입할 때 한 번)
   ├ merge_rects / _build_*    충돌(# = 통과 발판 ^ 가시) · 특수 영역(I 환영 벽 · W 부서지는 벽 · H 숨은 발판)
   ├ _spawn_entity(e, i)       개체 (cond가 거짓이면 건너뜀)
   └ RoomBackdrop.build_foreground
HUD 미니맵·지도 화면 ─ RoomIndex.all() / RoomIndex.data(id)  ← _index.gd만 읽음 (방 스크립트를 불러오지 않음)
```

### 파일과 역할

| 파일 | 역할 |
|---|---|
| `game/world/world.gd` (`World`) | 방 교체·페이드 전환, ↑ 상호작용 대상 고르기, 쓰러짐·부활, 동료. 다른 영역이 쓰는 API: `get_world()`, `load_room`, `go`, `ally_join/leave/ally`, `request_exit`, `end_screen`, 필드 `room/player/effects/notice/cinema/fade` |
| `game/world/room.gd` (`Room`) | `build(d)`로 방 하나를 만든다. 공용 필드 `data/theme/size_px/markers/exits/doors/saves/actors/enemies`, 함수 `tile_pos`, `add_entity`, `spawn_point` |
| `game/world/room_data.gd` (`RoomData`) | ASCII `map` + `entities` + 메타. `char_at`, static `cond_ok`(조건식 — S1 영역) |
| `game/world/room_index.gd` (`RoomIndex`) | `_index.gd` 색인을 읽는다. `all()` 지도에 나오는 방 ID, `info(id)` 색인 한 줄, `data(id)` 지도용 가벼운 RoomData, `load_full(id)` 방 전체 |
| `game/world/rooms/_index.gd` | 생성물. `ROOMS := {id: {title, area, theme, music, cell, cells, dark, saves, dev, src}}` |
| `game/world/tile_painter.gd` | 타일 굽기. `IllusionWall`·`BreakableWall`도 같은 함수로 자기 영역만 굽는다 |
| `game/world/world_entities.gd` (`WorldEntities`) | 기본 목록에 없는 개체 종류 → 스크립트 (`KINDS` + 장별 `world/entities/<장>/entities.gd`의 `KINDS`) |
| `game/world/entities/prop.gd` (`Prop`) | 장식 소품 엔진: kind 표 합치기, 빛(LightGlow), 화면 밖 생략, 정적/움직임 층 |
| `game/world/entities/base_props.gd` | 1장 소품 그림 + `PROPS` 표 |
| `game/world/entities/<장>/props.gd` | 2장부터의 소품 그림 + `PROPS` 표 (`ChapterRegistry.prop_scripts()` 순서: sys → ch2 → ch3 → ch4 → ch5) |
| `game/world/entities/ch2/k_art.gd`, `ch4/art.gd` | 장별 그림 조각(static). 적·인물·배경도 preload해서 쓴다 — 함수 이름·인자를 바꾸면 그쪽도 깨진다 |
| `game/levels/**` | 프로토타입 "전투 연습장"(`title.gd` → `GameState.start_stage` → `levels/stage.tscn`). `levels/background.gd`는 타이틀·결과 화면이 쓴다. `test_room.tscn`은 참조 0(에디터 메타데이터에만) |

### 쓰인 패턴과 이유

- **생성기 + 생성물**: 방은 Python 사각형 명령으로 그리고(`r.fill`, `r.plat`, `r.exit_left` …) GDScript 파일로 굳힌다. 지형을 손으로 그리지 않아 출구 높이·바닥 행이 일정하고, `check`(도달 검사)·`validate`(무결성)를 돌릴 수 있다. 생성물은 **직접 고치지 않는다** — 머리의 `## 정의:` 줄이 고칠 곳(파일과 함수)을 알려 준다.
- **덧붙임(overlay)**: 다른 장이 1장 학교 방 등에 NPC·문·트리거를 더할 때 `overlay(방ID, 종류, …)`. 지형은 못 바꾼다. 생성물에는 `# 덧붙임(overlay): tools/rooms/ch2.py` 주석이 붙는다. 보통 `cond`로 그 장에만 보이게 한다.
- **장별 레지스트리**: 공용 파일을 고치지 않고 장 파일에 상수만 적으면 합쳐진다(`ChapterRegistry`, `WorldEntities`, `Prop.kind_info`). 여러 사람이 동시에 장을 만들어도 충돌하지 않게.
- **소품 kind 표 하나**: 예전에는 kind 하나를 "움직이는 목록 · 빛 정보 함수 · 그리기 match" 세 곳에 등록했다. 지금은 모듈의 `PROPS` 표 한 줄 + `draw` match 한 줄이다(둘이 어긋나면 `roomgen.py validate`가 ERR).
- **조건이 바뀔 때만 다시 계산**: `flag_event`·`updraft`는 `GameState.flag_changed` 신호로 "다시 볼 차례"만 표시하고, 판정 시점(물리 프레임 처음)은 예전과 같다.

## 2. 이렇게 고친다 (절차)

### 방을 고치거나 배치를 바꾸려면
1. 생성물 머리 `## 정의: tools/rooms/ch2.py k_market()`를 보고 그 함수를 고친다(1장은 `tools/roomgen.py`).
2. `python3 tools/roomgen.py k_market` (또는 인자 없이 전부). 색인 `_index.gd`도 함께 갱신된다.
3. `python3 tools/roomgen.py validate` → `ERR 0`. `python3 tools/roomgen.py check all k_market` → 출력 없음(도달 문제 0).
4. 게임에서 확인. **시나리오가 타일 좌표(`tp`)·방 ID(`go`)를 쓴다** — 지형을 옮기면 `tools/test/scenarios/*.json`의 해당 좌표도 확인.
5. 개체 순서를 바꿀 때: `id`가 없는 개체는 ID가 `종류_순번`이 된다(`Room._spawn_entity`). 트리거·이벤트 자동 플래그(`trig_<방>_<id>`, `evt_<방>_<id>`)와 줍는 물건 수집 기록이 이 ID를 쓴다 → **트리거·이벤트·pickup에는 `id`를 꼭 준다**.

### 새 방을 추가하려면
1. 장 파일(`tools/rooms/<장>.py`)에 `@room` 함수. 상자 방은 장 도우미(`hall`·`elf`·`in_room`·`school_room` — 모두 `roomgen.boxed_room`의 기본값만 다른 것)로 시작한다.
2. 지도 칸 `cell`·`cells`가 같은 `area`의 다른 방과 겹치지 않게(미니맵·지도는 겹침을 가정하지 않음).
3. 출구 `exit_left/right`의 `to`, `to_id`와 상대 방의 돌아오는 출구를 맞춘다. 문은 `r.door(...)`.
4. 생성 → validate → check. **방 목록에 손으로 넣을 곳은 없다** — 색인이 자동(`dev_`로 시작하면 지도 목록에서 빠짐).
5. 방 입장 대본은 `enter_<방ID>`(docs/dev/story.md).

### 개체 종류(entity `t`)를 추가하려면
| 할 일 | 파일 |
|---|---|
| 스크립트 작성: `setup(room: Room, e: Dictionary, eid: String)` | `game/world/entities/<장>/<이름>.gd` |
| 종류 이름 등록 | 그 장의 `game/world/entities/<장>/entities.gd` `KINDS` (공용이면 `world_entities.gd`) |
| 방에 배치 | `r.add("<종류>", id=..., x=..., y=..., …)` — 사전 키는 그대로 `e`로 전달 |
| 확인 | `python3 tools/roomgen.py validate` (모르는 종류면 ERR) |

`Room._spawn_entity`의 기본 목록(exit·door·spawn·save·trigger·sign·light·prop·pickup·brazier·gate·npc·enemy)은 `match`로 직접 만든다.
적은 `enemy` + `kind`(`enemies/enemy_registry.gd`·`enemies/<장>/registry.gd`), 키 중 적 속성과 이름이 같은 것은 `set()`으로 들어간다(이름을 바꾸면 조용히 무시됨).

### 소품 kind를 추가하려면
1. 그 장의 소품 모듈(`base_props.gd` 또는 `world/entities/<장>/props.gd`)의 `PROPS` 표에 한 줄:
   ```gdscript
   "k_well": {"anim": true, "glow": [Vector2(0, -20), 40.0, AMBER]},   # 빛 없는 정적 소품이면 {}
   ```
   - `anim`: 매 프레임 다시 그림. **없으면 처음 한 번만 그린다**(그림이 `t`를 써도 멈춰 보임).
   - `glow`: `[위치, 반지름, 색]`(색 `null` = 테마 강조색) 또는 `&"_glow_x"` — `static func _glow_x(p: Prop) -> Array`가 같은 배열을 돌려줌(빈 배열·반지름 0이면 빛 없음). 세기는 방 데이터 `glow` 키(기본 0.45).
   - `split`: 큰 소품의 작은 빛 하나 때문에 통째로 다시 그리지 않게(아래 4절).
2. 같은 모듈 `draw()`의 `match`에 `"k_well": _well(p, t)` 한 줄과 그림 함수. 그림은 `p.draw_*`로, 시간은 `p.time()`, 크기는 `p.w`·`p.h`·`p.params`, 시드·위상은 **`p.anchor`**(방 안 위치 — `p.position` 대신).
3. `python3 tools/roomgen.py validate` → 표와 match가 어긋나거나 kind가 두 모듈에 있으면 ERR.

**kind 이름 규칙(바꾸지 말 것 — 방 데이터·시나리오가 문자열로 씀)**: 1장은 접두사 없음(`window`, `chandelier` …), 2장 `k_`, 3장 접두사 없음(엘프 말: `elf_lantern`, `seed_house` …), 4장 `tp_`, 5장 `st_`. 앞 모듈이 이기므로(1장 → sys → ch2 → …) 새 장은 **새 접두사**를 쓴다.
5장 모듈은 `DEFAULTS := {"vflip": true}`로 방 데이터 `vflip` 키(위아래 뒤집기)를 받는다.

### 덧붙임(overlay) 규칙
- 지형은 그대로, 개체만 더한다. 같은 방에 여러 장이 덧붙이면 모듈 파일 이름 순서(ch2 → ch3 → … → sys)로 뒤에 붙는다.
- `id`를 꼭 주고, `cond`로 그 장에만 보이게. 덧붙인 개체는 원래 개체 **뒤**에 붙으므로 원래 개체의 순번 ID는 바뀌지 않는다.

## 3. 함정 (조용히 깨지는 것)

- **배경 시드 = `hash(방 ID)`**: 방 이름을 바꾸면 배경 모양이 달라진다. 소품 `bookshelf` 등의 무늬 시드는 `p.anchor`(위치)라 소품을 옮기면 무늬가 바뀐다.
- **전역 난수 순서**: `Prop.setup`의 `randf()`(시간 위상)와 `LightGlow._ready`의 `randf()` 호출 순서·횟수가 그림 위상을 정한다. 시험 실행기가 전역 난수를 고정하므로 스크린샷 비교가 가능하다 — 소품을 만들 때 `randf()`를 더 부르면 그 뒤 모든 위상이 바뀐다(움직임 층 자식은 `setup`을 거치지 않게 만든 이유).
- **자동 플래그**: 트리거 `trig_<방>_<id>`, 플래그 이벤트 `evt_<방>_<id>`(기본 done). 방 ID·개체 ID를 바꾸면 본 장면이 다시 나온다.
- **동적 경로**: `res://world/rooms/%s.gd`(RoomIndex), `res://world/rooms/_index.gd`(preload), `ChapterRegistry`의 `%s` 패턴, `WorldEntities.KINDS`의 경로 문자열. 파일을 옮기면 `ResourceLoader.exists`가 조용히 false.
- **`RoomIndex.data(id)`는 지도용**: `entities`에는 기록 지점만 있고 `map`은 비어 있다. 지형·개체가 필요하면 `RoomIndex.load_full(id)`.
- **시험 실행기 의존**: `runner.gd`가 `current_scene.get_node("Effects")`, `"EndScreen"`, `w.room.add_entity`, `w.room.actors`, `room.data.id`, 그룹 `world/player/enemy/enemy_projectile`을 쓴다.
- **`p.draw_*`는 그 소품 노드에만 그려진다**: 움직임 층(자식 Prop)은 같은 그림 함수를 `p.layer = LAYER_ANIM`으로 다시 부르는 방식이다. 그림 함수 안에서 `p.position`·`p.scale`을 읽으면 자식에선 값이 다르다 → `p.anchor`를 쓴다.
- **방 데이터의 이상한 점(validate NOTE)**: 바닥 위가 아닌 NPC(`s_nonelem` ophelia, `s_courtyard` hodu5, `k_walls` leonie), 같은 방 안 개체 ID 중복(`tp_hut` hut, `tp_gate` gate·scene, `st_rebuild` yard) — 의도인지 확인 전이라 그대로 둠.

## 4. 성능 규칙

웹(단일 스레드 wasm)에서는 GDScript가 만드는 그리기 명령 수가 곧 프레임 시간이다.

1. **매 프레임 다시 그리는 것은 움직이는 것만.** `anim`이 아닌 소품은 `_process`가 꺼진다(`Prop._ready`). 새 노드에서 `_process`를 정의하면 Godot가 준비될 때 처리를 **자동으로 켠다** — 끄려면 `_ready`에서 `set_process(false)`.
2. **화면 밖이면 다시 그리지 않는다.** Godot는 화면 밖이어도 `queue_redraw()`하면 `_draw`를 실행한다(렌더 컬링은 그 뒤). `Prop.near_view(item, 월드 사각형)`으로 화면(+32px)과 겹칠 때만 `queue_redraw` — 시간(`_t`)은 계속 흐르게. 소품의 닿는 범위는 `w·h·len·sag`로 넉넉히 잡는다(`Prop._reach`). 그림이 그보다 크게 뻗는 새 소품이면 화면 가장자리에서 잠깐 멈춰 보일 수 있다 → `_reach` 계산을 늘린다.
3. **큰 소품의 작은 빛은 `split`.** 정적 부분은 부모 노드에 한 번, 움직이는 부분은 자식 Prop(`LAYER_ANIM`)이 매 프레임. 그림 함수는 `p.static_part()`/`p.anim_part()`로 나눈다. 자식은 부모 **위에** 그려지므로, 원래 순서에서 움직이는 것 **뒤에** 그리던 정적 그림이 움직이는 것과 겹치면 그 정적 그림(불투명한 것만)을 움직임 층에서도 다시 그려야 같은 그림이 된다(`seed_house` 창살, `round_door` 문턱). 반투명한 것이 겹치면 split하지 않는다.
4. **반복 도형은 한 번에.** 깃발 줄(`k_bunting`)처럼 같은 모양이 수십 개면 `RenderingServer.canvas_item_add_triangle_array` 한 번으로. 픽셀까지 같게 하려면 세 가지를 지킨다:
   선은 `draw_line`(굵기 1)과 같은 사각형(`(a - b).orthogonal().normalized() * 굵기 * 0.5`, 꼭짓점 from+o, from−o, to−o / from+o, to−o, to+o),
   선 색은 `Prop.line_color(색)`(draw_line은 색을 반정밀도로 넘긴다 — 그대로 쓰면 CanvasModulate와 곱해질 때 1 차이),
   그리는 순서는 원래 명령 순서 그대로(삼각형 배열 안에서도 앞 삼각형 위에 뒤 삼각형이 그려진다). 소품 자체의 modulate가 흰색이 아니면 이 방법은 1 차이가 날 수 있다.
5. **매 프레임 문자열 처리·그룹 탐색 금지.** 조건식은 `GameState.flag_changed`가 올 때만 다시 계산(`updraft`, `flag_event`), 플레이어 같은 노드는 한 번 찾아 `is_instance_valid`로 확인하며 재사용.
6. **방 진입 비용**: 타일은 진입할 때 한 번 굽는다(`TilePainter`). 지도·미니맵은 색인만 읽는다 — 방 스크립트를 통째로 `load`하는 코드를 지도·HUD 쪽에 다시 넣지 말 것.

측정: 시험 실행기 `perf` 명령(fps·process_ms·draw_calls·nodes). `_draw` 시간은 `Time.get_ticks_usec()`로 임시 계측해 전후를 같은 시점에 번갈아 잰다(다른 프로그램이 CPU를 같이 쓰면 값이 크게 흔들림).

## 5. 생성기 도구 요약

| 명령 | 하는 일 |
|---|---|
| `python3 tools/roomgen.py [방ID…]` | 방 생성물 + `_index.gd` |
| `python3 tools/roomgen.py check [모드] [접두사]` | 도달 검사 (1j·dj·fox·all) |
| `python3 tools/roomgen.py validate` | 개체 종류·적 kind·소품 kind(표와 draw 일치, 중복)·NPC `who`·출구/문 도착 지점·왕복·좌표 범위·바닥 위 |

공용 도우미(`roomgen.py`): `boxed_room`(사방 막힌 방), `stone`·`note`(줍는 물건), `hanging_row`(천장에 매단 소품 줄), `windows`, `overlay`. 장 파일의 `hall`·`elf`·`in_room`·`school_room`·`tower_room`·`lanterns`는 이것들의 기본값만 바꾼 것이다(`troom`은 상자 없이 `tp_ally` 장치를 붙이는 4장 전용, `out_room`은 5장 바깥 방).
