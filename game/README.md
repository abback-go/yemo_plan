# 죽음을 보는 마녀(가제) — Godot 프로젝트

카드 RPG 버티컬 슬라이스. Godot 4.7.2 · GDScript · 무대 1920×1080(창에 맞춰 비율 유지) · 한국어.
웹(CI 배포): https://abback-go.github.io/yemo_plan/godot/ · 작업 브랜치 `cc/amazing-darwin-nesbwh`.

- 판단·변경 기록: [`DECISIONS.md`](DECISIONS.md) · 진행 기록: [`PROGRESS.md`](PROGRESS.md) · 시작점·기획 문서 지도: [`../docs/handoff.md`](../docs/handoff.md) 7장
- 장면 파일(.tscn)은 `main.tscn` 하나뿐이고, 화면은 모두 코드로 만든다.

## 1. 폴더·파일 역할
| 위치 | 역할 |
|---|---|
| `main.gd` · `main.tscn` | 시작점. 화면 층(무대·연출·장면·메뉴)을 만들고 부분들을 등록, 주소 옵션을 읽어 타이틀·바로 가기·이어하기로 |
| `project.godot` · `export_presets.cfg` | 프로젝트 설정(자동 로드 `G`·`FX`·`Assets`), 웹 내보내기 설정("Web") |
| `data/game_data.gd` | 수치·카드·적·전투·지도·랜턴·운명·배치(`layout`, 배경별 `battleLayouts`)·그림 대응. **수치는 여기만** |
| `data/script_data.gd` | 화면 글자 전부: 대본 v3 대사·안내·선택지·지도·메뉴·결과 문구 |
| `core/rules.gd` · `core/rules_map.gd` | 규칙(상태 사전 `st` 만 바꾸는 정적 함수). `Rules`: 상태 구조·카드·전투·예고·피해 옮기기·운명·층 내려가기 · `MapRules`: 지도·랜턴 촛불·어둠·방에서 얻는 카드(좌판·무덤지기)·휴식·훈련 |
| `core/ctl.gd` | 장면 흐름(곁방 → 장례 회랑 → 안치 홀 → 지도의 방 → 가장 깊은 곳 → 빈 곁방 → 2·3층 → 결과), 전투 진행(1층은 새 전투 `_battle_v2` — `scenes/board_battle.gd` 게임 모드), 자동 저장·이어하기, 바로 가기 |
| `core/game.gd` | 자동 로드 `G`: 주소 옵션(`params`), 데이터·문구 읽기, 장면·화면 부분 참조 |
| `core/fx.gd` | 자동 로드 `FX`: 연출 시계(일시정지하면 멈춤)·트윈·입자·화면 배율(휴대폰 글씨 확대) |
| `core/save_game.gd` · `core/game_settings.gd` | `user://save.json`(자동 저장) · `user://settings.cfg`(화면·글자 속도) |
| `core/guide.gd` | 튜토리얼 안내를 상황에 맞춰 대사창으로 |
| `core/assets.gd` · `core/ui.gd` · `core/ease.gd` | 자동 로드 `Assets`: 그림·글꼴 읽기 · 화면 부품(글자·상자) · 이징 곡선 |
| `core/autoplay.gd` | 자동 진행(헤드리스 시험·대량 시험). `--ai=careful` 은 비교용 |
| `core/test_api.gd` · `core/check_scripts.gd` | `?test=1` 웹 시험 훅(스모크가 씀) · `--check-scripts` 모든 스크립트 컴파일 검사 |
| `ui/battle_view.gd` | 전투 화면: 동료 뒷모습·적·예고·붉은 실·HUD·타격 연출·데스신 재생 |
| `ui/hand.gd` · `ui/card_view.gd` · `ui/battle_input.gd` | 노엘의 두 손과 손패 · 카드 앞면/뒷면 · 끌어서 내기·대상 고르기 |
| `ui/dialog_box.gd` · `ui/game_menu.gd` | 대사창·안내 상자 · 메뉴 단추·일시정지·설정·확인 창·타이틀 단추 |
| `ui/cutin.gd` · `ui/blood.gd` · `ui/icons.gd` · `ui/card_art.gd` · `ui/card_pick.gd` · `ui/btn.gd` · `ui/shaders/` | 컷인 · 피 · 지도 아이콘 · 코드로 그린 카드 그림 · 카드 고르기(좌판·훈련) · 단추 · 셰이더 |
| `scenes/scenes.gd` | 타이틀·데스신·전멸·운명 선택·카드 획득·층 끝·결과 요약 |
| `scenes/vn.gd` · `scenes/floor_map.gd` · `scenes/omen.gd` | VN 장면(배경·스탠딩·대화·선택) · 지도 거점 · 죽음 카드가 떠오르는 연출 |
| `assets/` | 게임에 들어가는 그림·글꼴(`assets/fonts/`: 한글 2,350자 부분 글꼴). 원본은 저장소 `art/raw/` |
| `tests/test_rules.gd` · `tests/web/smoke.js` | 규칙·데이터·저장 시험(헤드리스) · 웹 빌드를 실제로 누르는 Playwright 스모크 |
| `tools/make_fonts.py` | 부분 글꼴 만들기(글꼴에 없는 글자가 생기면 규칙 시험이 알려 준다) |

저장소 `tools/`: `vs_import.py`(그림 들여오기) · `vs_f_import.py`(그림체 F → 전투 시험판 v2.1 그림) · `remove_bg.py`(크로마 배경 제거) · `fix_imports.py`(.import 크기 제한) · `batch_autoplay.py`(대량 자동 진행) · `web_sw_patch.py`·`web_sw.js`(웹 빌드 서비스 워커 교체). `build_web.py`·`make_char_prompts.py`·`pixel_sheet.py` 는 HTML 프로토타입·옛 탑뷰 때 도구.

## 2. 주소 옵션
웹은 `index.html?seed=7&scene=giant`, 데스크톱·헤드리스는 `godot --path game -- --seed=7 --scene=giant` 처럼 같은 이름을 쓴다(`G.params`).

| 옵션 | 뜻 |
|---|---|
| `?scene=` | 바로 가기: `camp` · `corridor` · `hall` · `map` · `room:<방>`(prayer·gravekeeper·buried·corpse·stall·chapel·training·footprints·stairs·deep) · `giant` · `emptycamp` · `floor2` · `ossuary` · `f2stairs` · `floor3`(+`&brun=alive|dead`) · `pyre` · `result`. **바로 가기 판은 저장하지 않는다**(`?nosave=1` 처럼 — 플레이어 저장을 덮어쓰지 않게). 일부러 저장하려면 `&save=1` |
| `?seed=N` | 난수 고정(같은 시드·같은 선택이면 같은 결과) |
| `?nosave=1` | 자동 저장·설정 파일을 쓰지도 읽지도 않는다(시험 실행) |
| `?continue=1` | 타이틀 없이 이어하기 |
| `?speed=N` | 연출 빠르기 배율(헤드리스 시험은 10, 대량 시험은 1000) |
| `?guides=reset` | 본 안내 기록을 지워 안내를 다시 보이게 |
| `?darkness=N` · `?omen=1` · `?hp=누구:HP,…` | 시험용(바로 가기와 함께): 어둠 단계 · 전조를 본 상태 · HP(`witch`·`hero`·`warrior`·`archer`) |
| `?run=N` | 회차 번호 |
| (옵션 없음) | **1층 전투는 새 전투(v2 「3D 탁자」)가 기본**(2026-11-22 밤샘 계획 2): 장례 회랑·기도실·무덤지기·가장 깊은 곳(→ 거대한 발)을 3D 탁자로. 2·3층은 아직 옛 전투. 판단은 DECISIONS.md 「1층에 새 전투 · 데스신 연결」 |
| `?battle=v1` | 옛 전투(1인칭 손패 — `ui/battle_view.gd`)로 — 지금까지와 같은 옛 게임(헤드리스 `--battle=v1`). 스모크와 CI 의 옛 경로가 쓴다 |
| `?battle=v2` | 전투 시험판 v2.1 「3D 탁자」 **시험 전투 하나로 바로 가기**(`docs/battle-v2-spec.md` 9장): 타이틀 없이 출전 배치 → 광신도 둘 + 무덤지기(죽음 카드)(헤드리스 `--battle=v2`, `--autoplay` 로 끝까지). 저장하지 않는다. `&seed=N` 이면 같은 전투. 파일 `scenes/board_battle.gd`·`ui/board_table.gd`(3D 탁자)·`core/rules_v2.gd`·`data/battle_v2_data.gd`·`ui/board_hand.gd`·`ui/board_pieces.gd`·`ui/shaders/card3d·table3d·shadow3d` |
| `?anim=off` | 전투 움직임을 그 전 기본(튀어 나가기·흔들림)으로 — 비교용. 옵션이 없으면 A′(2026-11-22부터 기본, `ui/battle_anim.gd`). 예전 `?anim=a`·`c` 는 A′ |
| `?test=1` | 웹 시험 훅(`window.witch.*`, 스모크가 씀) |
| `?autoguide=1` · `?autoplay=1` | 대사·안내 자동 넘김 · 자동 진행 |
| 자동 진행 선택 | `--rooms=방,…`(지도에서 들를 순서, `none` = 정해진 길만) · `--choice=값,…`(VN 선택) · `--reward=카드|skip`(묘지기의 좌판) · `--train=카드` · `--fates=accept|offer|defy,…`(운명의 시도 순서대로) · `--ai=careful` |
| 헤드리스 전용 | `--trace`(흐름 기록 출력) · `--quit-on-end`(결과 요약에서 끝냄) · `--check-scripts` |

## 3. 시험 돌리는 법
Godot 바이너리를 `godot` 라고 쓴다(로컬 예: 스크래치패드의 `godot/godot`). 저장소 루트에서:

1. 가져오기 두 번(처음은 글꼴 경고가 날 수 있다): `godot --headless --path game --import` ×2
2. 스크립트 검사: `godot --headless --path game -- --check-scripts` → `scripts: N ok, failures: 0`
3. 규칙 시험: `godot --headless --path game --script res://tests/test_rules.gd` → `rules: N passed, failures: 0`
4. 헤드리스 자동 진행(처음부터 끝까지): CI 와 같은 11경로(옛 전투 `--battle=v1` 6 + 새 기본 흐름 4 + 시험 전투 `--battle=v2` 1)는 `.github/workflows/witch-web-build.yml` 의 `for args in …`. 한 경로 예(옵션이 없으면 1층은 새 전투)
   `godot --headless --path game -- --speed=10 --autoguide --guides=reset --nosave --trace --quit-on-end --scene=camp --rooms=prayer,gravekeeper,buried,corpse,stall,chapel,training,footprints --choice=open,card --fates=defy,defy,defy --autoplay`
   → 기록에 `] result` 가 있고 `SCRIPT ERROR`·`ERROR` 가 없으면 통과.
5. 스모크(웹 빌드를 Playwright 로 실제 클릭·드래그·터치, 스크린샷):
   ```
   godot --headless --path game --export-release "Web" <빌드폴더>/index.html
   python3 tools/web_sw_patch.py <빌드폴더>
   (cd <빌드폴더> && python3 -m http.server 8150 &)
   node game/tests/web/smoke.js http://localhost:8150/ <스크린샷폴더> [ABCDEFS 중 고른 경로]
   ```
   경로: A 처음부터 데스신·빈 곁방 · B 어둠 · C 골라 들어가는 방 · D 휴대폰 터치 · E 느린 연출 · F 2·3층 운명 · S 타이틀·설정·일시정지·저장 · N 새 전투(기본) 처음부터 장례 회랑(출전·실제 끌기·턴 끝) → 승리 → 지도. A~S 는 옛 전투(`battle=v1`)를 누르고 N 만 새 전투(약 100초). 전체 약 12~21분(소프트웨어 렌더링, 지난 기록 707~1280초). Playwright 가 필요하다(`npm install playwright` 또는 `NODE_PATH`).
6. 대량 자동 진행(멈춤·에러·난이도 표): `python3 tools/batch_autoplay.py --godot <godot> --seeds 1-20 --jobs 3 --out <폴더>` — 결과 읽는 법은 [`../docs/balance-report.md`](../docs/balance-report.md).
   - 새 전투 난이도만 빠르게(규칙만, 화면·VN 없이): `godot --headless --path game --script res://tests/sim_v2.gd -- --seeds=1-40 [--mode=test,iso,chain] [--ai=simple] [--encs=gravekeeper] [--trace]` — 시험 전투 · 1층 다섯 곳(새 파티) · 1층 처음부터 이어서의 승률·남은 HP·턴(밤샘 계획 2 D, `../docs/balance-report.md` 「새 전투 1층」)

커밋마다 2·3·4(한 경로), 큰 작업이 끝나면 4(6경로)·5 전부.

## 4. 새 그림 넣는 법
1. 받은 원본을 `art/raw/vs/<번호>_<이름>.webp` 로 저장한다(번호는 `docs/prompts/vs_assets.md`·`vs_assets_rest.md`). 고친 판이 오면 앞 판은 `_v1` 로 남긴다.
2. 검수: [`../docs/art-direction.md`](../docs/art-direction.md) **5-1 체크리스트**(옷 앞뒤·뒷모습·좌우·장식 위치·노출·비율·그림체·반투명 옷 물듦·배경 제거)로 부위별로 본다.
3. `tools/vs_import.py` 의 대응표에 줄을 더한다: `SPRITES`(투명 그림·최대 높이) · `STANDS`(표정 스탠딩 — 같은 캔버스로 맞춤) · `BGS`(16:9 배경·CG, 그대로 복사) · `CARDS`(카드 그림 → `card_art_<카드 id>.jpg` 512) · `DEATH`(데스신 컷, `reference/deathscene/`) · `ICONS` · `DIALOG`.
4. `python3 tools/vs_import.py --only <원본 이름|hero|warrior|archer|noel|bg|cards|death|icons|dialog> --check <확인 그림 폴더>`
   - 크로마 배경(초록 #00FF00, 엘리안은 마젠타 #FF00FF)은 `tools/remove_bg.py` 를 **`--soft 100`** 으로 불러 지운다(기본 150 은 몸 안쪽 중간색까지 반투명으로 만든다 — 기본값은 사용자 결정 전이라 바꾸지 않음). 따로 돌릴 때도 `python3 tools/remove_bg.py 입력 출력.png --soft 100`.
   - 출력의 "안쪽 반투명 %" 가 약 0% 인지, `--check` 그림(어두운 배경 위)에서 테두리 번짐이 없는지 본다.
5. 게임이 쓰게 `data/game_data.gd` 의 파일 이름을 맞춘다(VN 배경 `vnScenes`·전투 배경 `encounters.bg`, 적 `enemies.sprite`, 스탠딩 `standing`·`expressions`, 카드 `cardArtImg`, 데스신 `cutscene.cuts`). 같은 이름으로 바꾸는 그림이면 이 단계는 없다.
6. 가져오기 두 번 → 시험(3장). 큰 그림은 `tools/fix_imports.py` 로 크기 제한(.import)을 맞춘다. 대응을 `DECISIONS.md` 에 적는다.

## 5. 배포
- `cc/amazing-darwin-nesbwh` 에 `game/**`(또는 워크플로·`tools/web_sw*`)가 바뀐 커밋을 푸시하면 GitHub Actions `Witch web build (Godot)` 가 돈다: 가져오기 → 스크립트 검사 → 규칙 시험 → 웹 내보내기 → 서비스 워커 교체 → gh-pages 의 **`godot/`** 에 올림(약 2~3분).
- 전체 검증(헤드리스 6경로 + 스모크 + 스크린샷)은 Actions 에서 수동 실행(Run workflow, full) — 스크린샷·기록은 gh-pages `godot-ci/`. 스모크가 실패하면 `godot/` 에 올리지 않는다.
- 사이트 루트(HTML 프로토타입)·`eska/` 는 건드리지 않는다.
