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
| `godmode` | 세라 무적 + 체력 3 미만이면 5로 |
| `kill` / `ehp` 값 / `ehpf` 비율 | 적 처치(붉은 불 999 피해라 해태·골렘 정면·아귀는 여러 번 필요) / 체력 설정 / 체력 비율로 |
| `spawn_enemy` 종류 x y {속성} | 적 생성 (종류는 `enemies/enemy_registry.gd`) |
| `flagset` 키 · `abil` 이름 · `run` 대본ID | 플래그·능력·대본 실행 |
| `record` 방 위치 · `continue` | 기록 → 이어하기 시험 |
| `status` / `worldinfo` / `logv` / `enemies` / `flags` 표시 | 상태 출력 |
| `shot` 이름 | 스크린샷 PNG |
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

## 웹 빌드 연기 시험
```bash
$G --headless --export-release "Web" /tmp/web/index.html
(cd /tmp/web && python3 -m http.server 8766 &)
node ../tools/test/web_smoke.mjs /tmp/out    # 타이틀 → 새로 시작 → 안내 → 지도 → 일시정지, 콘솔 로그 출력
```

## 방 도달 검사
```bash
python3 tools/roomgen.py check   # 저장소 루트에서. 출구·문·기록 지점·수집품이 서로 닿는지 (한 번 점프 / 2단 점프 / 여우창문)
```
