# 시험 도구 (tools/test)

Godot 4.7.2 리눅스 실행 파일(아래 `$G`)로 헤드리스·가상 화면 시험을 돌린다. 모든 명령은 `game/` 폴더에서 실행한다.

```bash
# Godot 내려받기 (클라우드 세션은 매번 새 컴퓨터라 다시 받아야 함)
curl -sSLo godot.zip https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip
unzip godot.zip && G=$PWD/Godot_v4.7.2-stable_linux.x86_64

cd game
$G --headless --import                                   # 처음 한 번 (클래스 목록 갱신)
$G --headless --script ../tools/test/check_scripts.gd    # 모든 스크립트 불러오기 → "CHECKED N scripts, failures: 0"
$G --headless --quit-after 200 res://world/world.tscn    # 실행 중 오류 빠른 확인 (SCRIPT ERROR가 없어야 함)
```

## 시나리오 실행기 `runner.gd`

```bash
xvfb-run -a -s "-screen 0 1280x720x24" $G --rendering-driver opengl3 --fixed-fps 60 --resolution 640x360 \
  --script ../tools/test/runner.gd -- ../tools/test/scenarios/full_playthrough.json /tmp/out
```

시나리오 JSON: `{"scene": "res://world/world.tscn", "room": 방ID, "spawn": 등장 위치, "flags": [미리 세울 플래그], "steps": [[프레임, 명령, 인자...], ...]}`

| 명령 | 뜻 |
|---|---|
| `press`/`release`/`tap` 동작 | 입력 (`tap`은 `_input`까지 전달됨) |
| `tp` x y | 세라 순간이동 (타일) |
| `go` 방 등장위치 | 방 이동 (문 대신) |
| `auto` true/false | 대사·멈춤 안내·습득 팝업·끝 화면 자동 넘김 |
| `waitidle` [한도] | 대본이 끝날 때까지 단계 시계를 멈춤 (보스전 중엔 한도까지 기다림 → `WAIT TIMEOUT`) |
| `attach` 스크립트 | 시험용 노드(자동 플레이 봇 등)를 지금 장면에 붙임 (game/ 기준 상대 경로) |
| `godmode` | 세라 무적 + 체력 3 미만이면 5로 |
| `kill` / `ehp` 값 / `ehpf` 비율 | 적 처치(붉은 불 999 피해라 해태·골렘 정면·아귀는 여러 번 필요) / 체력 설정 / 체력 비율로 |
| `spawn_enemy` 종류 x y {속성} | 적 생성 (종류는 `enemies/enemy_registry.gd`) |
| `flagset` 키 · `abil` 이름 · `run` 대본ID | 플래그·능력·대본 실행 |
| `record` 방 위치 · `continue` | 기록 → 이어하기 시험 |
| `status` / `worldinfo` / `logv` / `enemies` / `flags` 표시 | 상태 출력 |
| `shot` 이름 | 스크린샷 PNG |
| `touch`/`untouch` 번호 x y · `drag` 번호 x y | 손가락 누름·뗌·끌기 (화면 좌표 640×360, 번호 = 손가락 index) |
| `touchinfo` | 터치 조작 상태 (터치 모드·표시 여부·눌린 동작·조이스틱 방향) |
| `setting` 키 값 · `potions` 개수 | 설정 값 지정(저장된 설정이 시험에 끼어들지 않게) · 물약 수 |
| `quit` | 종료 |

## 시나리오 (scenarios/)
| 파일 | 확인하는 것 |
|---|---|
| `full_playthrough.json` | 여우고개 → 1장 끝 화면까지 (대사 자동, 순간이동·처치로 진행). 끝에 `STATUS end2 ... room=s_dorm ... obj=` 이면 통과 |
| `school_flow.json` | 의무실 → 끝 (학교만) |
| `haetae_demo_fight.json` | 해태 시범전: 10초 뒤 첫 빙의, 철창, 승리 → 학교 |
| `training_targets.json` | 실습장 과녁 셋을 1.2초 간격으로 맞혀 합격 → 골렘 |
| `shot_single_vs_fox_pierce.json` | 기본 공격 단일 대상(6초 5발 = 1000), 여우불 관통(두 적 모두 피해) |
| `save_continue.json` | 기록 → 이어하기 복원 |
| `drop_through.json` | 통과 발판 ↓+Z |
| `room_bounds_haetae.json` | 보스전 중 방 밖으로 못 나감 |
| `agwi_pace.json` | 아귀를 제자리 사격으로 깎는 속도 |
| `touch_controls.json` | 터치: 조이스틱(대각선 아래로 달려도 ↓ 아님), ↓+점프 발판 내려가기, 공격 누르고 있기, 지도·일시정지·설정(버튼 크기), 멈춤 안내 버튼, 대화 탭 넘기기. 끝에 `after_dialogue ... busy=false paused=false` 이면 통과 |
| `eska_moves.json` | 에스카 시제품: 대기·달리기·4타 연격·순간이동·천열·단공·봉공·공중 연격·터치(공격 버튼, 고정 방향키·대각선 끌기, ↑+스킬) · 이단점프 · 활주 스크린샷 |
| `eska_hits.json` | 에스카 시제품 피해 확인 (사양: `docs/eska/combat_spec.md`)(측정마다 체력을 다시 채움): 4타 158 · 천열 896(앞쪽 한 점을 감싸는 회오리 10번: 80×9+176) · 단공 124(머리 위 한 점을 감싸는 회오리 5번: 22×4+36) · 공중 연격 128 · 공중 연격 중 떠 있음 · 순간이동 거리(150 + 이동 관성: 501 → 659.8) |
| `eska_foes.json` | 에스카 시제품 적: 돌진형(웅크림·돌진 맞으면 체력 6→5) · 원거리(조준선·구슬) · 거구(들기·내려찍기 충격파 → 4) · 9 피해로 쓰러짐(0) → 1.5초 뒤 부활(6, 400,300). 모든 에스카 시나리오는 첫 프레임에 적 물결을 끈다(`waves.set('enabled', false)`) |
| `eska_tutorial.json` | 에스카 튜토리얼 "종언의 문턱"을 처음부터 끝 화면까지 (순간이동 eval로 구간을 건너뛰며 각 단계 `step_name()` 확인, 적은 eval 피해로 처치). 끝에 `end sub=1` 이면 통과 · 기획 `docs/eska/tutorial.md` |
| `eska_tutorial_bot.json` | 튜토리얼을 **실제 입력만으로** 끝까지 (자동 플레이 봇 `tools/test/eska_tut_bot.gd`를 `attach`로 붙임 — 턱·장막·틈·허수아비·적 셋을 직접 넘고 벰). 3000프레임에 `end sub=1` 이면 통과 |
| `eska_perf.json` | 에스카 시제품 성능: 대기·연격·스킬 겹침·연격 중 `perf()` (그리기 호출·도형·노드·처리 시간·입자). 그림 코드별 비용은 eval `bench(400)` (µs) |
| `title_touch.json` | 터치: 타이틀 탭 → 설정 → 돌아가기 → 구버전 (세라 데모) → 새로 시작 → 확인 (저장 기록이 있을 때 기준 좌표). 끝에 `STATUS title_end ... room=t_pass` 이면 통과 |

## 웹 빌드 연기 시험
```bash
$G --headless --export-release "Web" /tmp/web/index.html
(cd /tmp/web && python3 -m http.server 8766 &)
node ../tools/test/web_smoke.mjs /tmp/out    # 타이틀 → 새로 시작 → 안내 → 지도 → 일시정지, 콘솔 로그 출력
```

## 모바일(터치·오프라인) 웹 시험
```bash
$G --headless --export-release "Web" /tmp/web/index.html
python3 ../tools/web_sw_patch.py /tmp/web   # 배포(web-build.yml)와 같게 서비스 워커 바꾸기
(cd /tmp/web && python3 -m http.server 8766 &)
node ../tools/test/web_mobile.mjs /tmp/out
```
가로 태블릿(CSS 1280×800, 픽셀 비율 1.5, 터치)으로 타이틀 탭 → 새로 시작 → 대화 탭 → 조이스틱+점프 두 손가락 → 일시정지 → **인터넷을 끊고 다시 열기**. 출력의 `SW ... files`에 `index.wasm`·`index.pck`가 있고 `OFFLINE title`이 게임 제목이면 통과(오프라인 안내 페이지면 제목이 "YEMO — 오프라인").

## 웹앱 아이콘
`$G --headless --script ../tools/make_icons.gd` (game/ 에서) → `game/assets/icon/icon_{144,180,512}.png`

## 방 도달 검사
```bash
python3 tools/roomgen.py check   # 저장소 루트에서. 출구·문·기록 지점·수집품이 서로 닿는지 (한 번 점프 / 2단 점프 / 여우창문)
```
