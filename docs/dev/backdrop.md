# 배경(하늘·시차 층·안개·입자) 개발 안내

방 배경 그리기를 고치거나 새 테마를 넣는 사람을 위한 문서다. 코드는 `game/world/themes/`에 있다.
핵심 규칙은 하나다. **배경은 방에 들어갈 때 한 번 기록하고, 움직이는 요소만 다시 그린다.**
웹(단일 스레드 wasm)과 태블릿에서는 매 프레임 수천 개의 그리기 명령을 새로 만들면 바로 6fps까지 떨어진다(2장 시장 `k_market`).

## 1. 구조

### 파일

| 파일 | 하는 일 |
|---|---|
| `room_backdrop.gd` (`RoomBackdrop`) | `build(room, holder)`가 하늘·층 4개·안개·입자·어둠을 만든다. `build_foreground`는 전경 층을 만든다. 안쪽 클래스로 `SkyDraw`·`BackdropLayer`·`FogDraw`가 있다. 테마를 맡은 장 스크립트를 찾아 캐시하는 `layer_script`·`sky_script`도 여기에 있다. |
| `backdrop_kit.gd` (preload로 `Kit`) | 기록기 `Pen`, 기록을 그리는 `StaticPart`·`AnimPart`, `mount`, 다시 그리기 박자 `Ticker`, 공용 그림 도우미, 계측용 `Stats`가 있다. |
| `backdrop_ch1.gd` | 1장(학교·신계)과 기본 테마. 다른 장이 맡지 않은 테마는 모두 여기로 온다. 정해진 테마가 없으면 학교 실내로 그린다. |
| `backdrop_ch2~5.gd`, `backdrop_sys.gd` | 장별 테마. `ChapterRegistry.backdrop_scripts()` 순서는 sys→ch2→…→ch5이고, 앞에 있는 스크립트가 먼저 맡는다. |
| `room_theme.gd`, `themes_<장>.gd` | 색 사전(`sky_top`·`far`·`mid`·`near`·`fog`·`particles` …). |

### 노드 구조 (방 하나)

```
Room/_bg
  CanvasLayer(-30) ─ SkyDraw(Control) ─ StaticPart… / AnimPart…   ← 화면 고정 하늘
  Parallax2D(0.15) ─ BackdropLayer(FAR)  ─ StaticPart… / AnimPart… (/ 3장 Anim)
  Parallax2D(0.45) ─ BackdropLayer(MID)  ─ …
  Parallax2D(0.75) ─ BackdropLayer(NEAR) ─ …
  FogDraw, CPUParticles2D, (CanvasModulate)
Room/_front
  Parallax2D(1.18) ─ BackdropLayer(FRONT) ─ …
```

### 흐름

1. `BackdropLayer._ready()`가 `Kit.Pen`을 만든다. `theme`·`theme_name`·`room_size`·`scroll`·`depth`·`room_id`를 Pen에 복사하고, `_rng.seed = rng_seed`(방 ID 해시 + 층)로 맞춘다.
2. `RoomBackdrop.layer_script(theme)`가 장 스크립트를 찾는다. 찾으면 `draw_layer(pen, theme, depth, span, rng, 0.0)`을 부르고, 없거나 false가 돌아오면 `Ch1.draw_layer(...)`를 부른다. **딱 한 번 불린다.**
3. `Kit.mount(layer, pen, cull=true)`가 기록을 자식 노드로 붙인다.
   - 짝수 level은 `StaticPart`가 된다. 가로 320px 조각으로 나뉘고 `_draw`를 한 번만 한다.
   - 홀수 level은 `AnimPart`가 된다.
4. `BackdropLayer._process`는 `_t`를 늘린다. `on_process` 콜백은 매 프레임 부르고, `Ticker.step()`이 참인 프레임에만 `AnimPart.tick(_t)`를 부른다. `tick`은 `queue_redraw`를 하는데, 화면 밖이면 건너뛴다.
5. `SkyDraw`도 같은 방식이다(Pen 640×360, 화면 밖 생략 없음). 장 스크립트가 `has_sky(theme)`로 맡지 않으면 `Ch1.draw_sky`가 그린다.

## 2. 정적/동적 계약 (backdrop_kit.gd 머리말과 같음)

그리기 함수가 받는 `l`(층)과 `c`(하늘)는 진짜 캔버스가 아니라 **Pen**이다.

| 부르는 것 | 뜻 |
|---|---|
| `l.draw_rect / draw_circle / draw_line / draw_colored_polygon / draw_polyline / draw_arc / draw_set_transform` | 정적 그림. 이름과 기본값은 CanvasItem과 같다. 기록해 두었다가 한 번만 그린다. |
| `l.anim(bbox, func(cv: CanvasItem, tt: float) -> void: ...)` | 움직이는 요소. 틱마다 `tt`(층 시간)로 다시 그린다. `cv`는 진짜 노드라 KArt·ART·StArt를 그대로 쓸 수 있다. |
| `l.fn(bbox, func(cv: CanvasItem) -> void: ...)` | 정적이지만 `CanvasItem` 타입만 받는 도우미(KArt·ART·StArt)를 부를 때 쓴다. 예: `_art_column`, `_st_glow`, `Kit.glow`(이건 타입이 없어 Pen에 바로 쓸 수 있음). |
| `l.on_process(func(node: Node2D, tt: float) -> void: ...)` | 그리기가 아닌 매 프레임 일. 5장 땅울림(`position.y`)이 여기에 해당한다. **`_draw` 안에서 노드 속성을 바꾸지 말 것.** |
| `l.add_post(node)` | 모든 부분 위에 붙일 노드. 3장 `Anim`(정적 그림 위에 움직임을 겹쳐 그리는 3장 고유 방식)이 쓴다. |
| `l.theme` / `l.room_size` / `l.scroll` / `l.depth` / `l.room_id` | 층 정보(층 테마 조회는 이것으로 통일). 2장만 `kingdom_roof`→`kingdom` 별칭 때문에 `RoomTheme.get_theme(_alias(theme))`를 쓴다. |

**bbox**는 `anim` 하나가 움직이는 동안 그리는 범위 전체를 덮는 층 좌표 사각형이다. 두 곳에 쓰인다.
- 화면 밖 생략: 화면과 64px 여유(`CULL_MARGIN`)를 더한 범위와 겹치지 않으면 그리지 않는다.
- 그리는 순서 계산.

모자라면 화면 가장자리에서 요소가 늦게 나타나거나 겹침 순서가 틀어진다. 넉넉하게 잡는다. 정확히 모르면 `Kit.ALL`을 쓴다(항상 그림, 모든 것과 겹친다고 봄).
도우미: `Kit.bb_circle`, `bb_pennant`, `bb_banner`, `bb_smoke`, `bb_crystal`, ch4 `_bb_bell`·`_bb_banner`, ch5 `_bb_giant`·`_bb_crack`.

### 순서 보존 (그림이 바뀌지 않는 이유)

Pen은 명령마다 level을 정한다(64px 격자 칸 단위로 겹침을 판단하며, 보수적으로 잡는다).
- 정적 명령의 level은 겹치는 앞 정적 명령과 같거나 그보다 위이고, 겹치는 앞 동적 요소보다는 위다(짝수).
- 동적 요소의 level은 겹치는 앞 정적 명령보다 위이고, 겹치는 앞 동적 요소와 같거나 그보다 위다(홀수).
- 같은 정적 level 안에서는 bbox 왼쪽 끝 x로 320px 조각을 고른다. 다만 겹치는 앞 명령이 들어간 조각보다 앞 조각에는 넣지 않는다.

그래서 정적 그림 사이에 끼어 있던 연기·창 불빛도 원래와 같은 위·아래 관계로 그려진다. 겹치지 않는 것끼리만 같은 노드로 모인다.
`StaticPart`는 렌더러가 화면 밖에서 건너뛸 수 있도록 조각 단위로 나뉘어 있다.

### 다시 그리기 상한

`Kit.Ticker.hz`의 기본값은 **30Hz**다. 시간은 매 프레임 흐르고 `queue_redraw`만 이 주기로 한다. 0 이하로 두면 매 프레임 그린다.
`BackdropLayer`·`SkyDraw`·`FogDraw`·3장 `Anim`이 이 값을 따른다.
시험 실행기는 시나리오 키 `"bg_hz"`(기본 0 = 상한 끔, 픽셀 비교가 안정적)와 단계 `["bghz", Hz]`로 바꾼다.

## 3. 바꾸려면 / 추가하려면

### 새 테마(지역 배경) 추가
1. `themes_<장>.gd`의 `THEMES`에 색 사전을 넣는다. 키는 `room_theme.gd` 머리말과 같다.
2. `backdrop_<장>.gd`에서 다음을 고친다.
   - `has_theme(theme)`가 새 테마에 true를 돌려주게 한다. 하늘도 맡을 거면 `has_sky(theme)`도 고친다.
   - `draw_layer(l, theme, depth, span, rng, _t)`에서 depth 0 먼·1 중간·2 가까운·3 전경을 그리고 true를 돌려준다.
   - `draw_sky(c, theme, pal, _t)`를 쓴다(640×360 화면 고정).
3. 그릴 때는 다음을 지킨다.
   - 정적 그림은 `l.draw_*`로 그린다.
   - `sin(t…)`처럼 시간을 쓰는 것은 **반드시** `l.anim(bbox, func(cv, tt): …)` 안에서 그린다. 함수 인자 `t`는 0이라서 바깥에서 쓰면 멈춘 그림이 된다.
   - 난수는 람다 밖에서 미리 뽑아 지역 변수에 담는다. 람다는 값을 캡처한다.
4. 방 ID나 높이에 따라 달라지는 값(`l.room_id`, ch5 `_bot()` 등)은 기록할 때 지역 변수로 잡는다. ch5 `_bot()`은 층마다 바뀌는 정적 변수라 **람다 안에서 부르면 틀린다.**
5. 확인: `tools/test/check_scripts.gd`를 돌리고, 그 방을 도는 시나리오의 스크린샷과 `perf_*` 시나리오 `BGPERF`로 동적 항목 수·시간을 본다.

### 기존 그림에 움직임 추가 / 움직임 멈추기
- 움직이게 하려면 그 명령들을 `l.anim(bbox, …)`로 감싼다. 감싼 묶음 안에서는 원래 순서대로 그린다.
- 멈추게 하려면 람다를 풀어 `l.draw_*`로 바꾸고 `tt` 대신 고정값을 넣는다.
- 여러 명령이 서로 겹치며 번갈아 움직이면(예: ch2 하수도 물줄기) 묶음 하나로 감싼다. 노드 수가 줄어든다.

### 공용 그림 도우미 (`backdrop_kit.gd`)
| 도우미 | 쓰임 |
|---|---|
| `stepped_grad` | 1·2·3장·sys 하늘. KArt와 같음. |
| `grad_even` | 4장. |
| `grad_keyed` | 5장. |
| `glow` | KArt와 같음. |
| `star4`, `twinkles` | KArt와 같음. `anim_twinkles`는 Pen용. |

모두 타입이 없는 `c`를 받으므로 Pen과 노드 양쪽에 쓴다. 새 도우미를 만들기 전에 여기와 KArt(`world/entities/ch2/k_art.gd`)·ART(`entities/ch4/art.gd`)·StArt(`enemies/ch5/st_art.gd`)를 먼저 찾아본다.

## 4. 함정 (조용히 깨지는 것)

**rng 호출 순서가 곧 배치다.**
- 정적과 동적을 나눌 때 `rng.randf*()` 호출 순서와 횟수를 그대로 지킨다. 원래 식 안에서 불리던 순서(왼쪽→오른쪽)대로 람다 밖에서 미리 뽑는다.
  - 예: ch2 연기 seed는 `KArt.smoke(..., rng.randf(), ...)`의 인자 순서를 따른다.
  - 예: sys 재 조각은 x, y, 속도 순이다.
- 하나만 빠져도 그 뒤 배경 전체가 바뀐다.

**부동소수 순서도 그림이다.** `a * b * c`를 `a * (b * c)`로 바꾸면 드물게 알파가 1단계 달라진다. 원래 식 모양을 그대로 옮긴다. 미리 뽑아 둔 실수 배열은 `PackedFloat64Array`에 담는다(Float32는 값이 바뀐다).

**예전에 움직이지 않던 층은 t = 0으로 멈춘 그림이다.** 1장 시계탑 전경 톱니와 2장 성 실내 전경 깃발이 그렇다. "움직이게 고치면" 그림이 바뀌므로 의도를 확인하고 바꾼다.

**3장 Anim은 `add_post`로 붙고, 붙는 시점은 미뤄진다**(`call_deferred`). `_ready`의 전역 `randf()` 순서가 다른 개체 무늬에 영향을 준다.

**Pen 필드 이름**(`theme`·`room_size`·`scroll`·`depth`·`room_id`)은 테마 스크립트가 이름으로 읽는다. 이름을 바꾸면 조용히 null이 된다.

**거신 걸음은 실제 시각을 쓴다.** 5장 `march_clock()`이 실제 시각(`Time.get_ticks_msec`)이라 폐허 방의 스크린샷은 실행할 때마다 다르다(예전부터 그랬다).

**방 ID가 시드다.** 방 이름을 바꾸면 배경 배치가 바뀐다(`hash(room.data.id)`).

## 5. 성능 규칙

1. **층 전체를 매 프레임 다시 그리지 않는다.** 시간을 쓰는 요소만 `l.anim`으로 그린다. 큰 정적 그림(집·창틀·지붕)을 람다 안에 넣지 않는다.
2. `l.anim` 하나는 되도록 작게 잡는다(화면 밖 생략이 bbox 단위로 일어난다). 단 서로 겹치며 번갈아 그려지는 것들은 묶는다(노드 수 줄이기).
3. 람다 안에서 그룹 검색(`get_first_node_in_group`, `World.get_world()`)이나 난수 객체 생성을 하지 않는다. 기록할 때 잡아 둔다(4장 `_climb_k(w)` 참고).
4. `draw_circle`·`draw_colored_polygon`은 명령 하나가 그리기 호출 하나다(배치되지 않음). 움직이는 원을 수백 개 만들지 않는다.
5. 측정
   - `tools/test/scenarios/perf_market.json` 등 `perf_*` 시나리오를 돌린다.
   - `BGPERF` 줄에서 `anim_draw_us_per_frame`(동적 그리기 시간), `anim_items_per_frame`(그린 동적 항목), `recorded_static/anim`(기록 수)을 본다. `PERF` 줄에서 `draw_calls`·`objects`를 본다.
   - 헤드리스(`--headless`)로 돌리면 렌더링 없이 GDScript 비용만 볼 수 있다.
