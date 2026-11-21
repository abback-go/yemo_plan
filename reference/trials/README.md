# 시험 자료 (다시 만들기 어려운 것만)

2026-11-21~22 밤샘 작업 때 임시 폴더(scratchpad)에만 있던 시험 결과를 줄여서 옮겼다. 결정 근거는 `game/DECISIONS.md`.
그림은 1920×1080 스크린샷을 1600 폭 webp(품질 72)로 줄인 것이다.

## 전투 배치 시험 (2026-11-21, `game/DECISIONS.md` 「버티컬 슬라이스 — 전투 배치·새 그림」)
| 파일 | 설명 |
|---|---|
| `layout_0_current.webp` | 시험 전 배치(5-9 값). 세라피나가 손패 뒤에 거의 가려짐 |
| `layout_A_hand_lower.patch` · `.webp` | A안: 손패·쥔 손을 240px 내림 → 노엘 손이 화면 밖으로 사라져 **거절** |
| `layout_B_hero_higher.patch` · `.webp` | B안: 세라피나 top 636 → 430 → 가운데 적 발·몸과 겹쳐 **거절** |
| `layout_C.patch` | C안(손 무리 80%·동료 셋 −50·회랑 세라피나 HP 판 옆으로). **사용자 승인**, `ab7a1a8`·`e236808`로 반영됨 |
| `layout_C_final_e236808.webp` | C안 반영 뒤 장례 회랑 전투 |
| `layout_C_giant.webp` | C안 거대한 발 전투. 세라피나 HP 판이 발 아랫변을 조금 덮음(아침 보고의 배치 문제) |

- 패치는 시험 당시 `game/data/game_data.gd`(C는 `game/ui/battle_view.gd`도) 기준이다. 지금 코드에 그대로 `git apply` 되지 않을 수 있다.

## 움직임 시험 A′ / C (2026-11-22, 밤샘 계획 4, `game/PROGRESS.md` 「움직임 시험 두 안」)
| 파일 | 설명 |
|---|---|
| `anim_compare_idle_nohand.webp` | 대기 프레임 표. 줄 = 기본 · A′(`?anim=a`) · C(`?anim=c`), 손패 숨김 |
| `anim_compare_attack_nohand.webp` | 세라피나 성검 베기(공격) 프레임 표, 같은 줄 순서 |
| `anim_compare_hit_nohand.webp` | 턴 종료 뒤 피격 프레임 표, 같은 줄 순서 |
| `anim_c_fit.webp` | C 부위 조립(쉬는 자세) ↔ 지금 뒷모습 그림. 머리 약 1.34배·팔이 몸에 붙음·성검이 발 아래로 |
| `anim_scripts/` | 비교 자료를 만든 스크립트(아래) |

- 15초 비교 영상(`anim_compare.webm`·`anim_compare_nohand.webm`, 약 6MB)은 넣지 않았다. 다시 만드는 법:
  1. 웹 내보내기: `anim_scripts/build.sh`(Godot 헤드리스 `--export-release "Web"` → `python3 tools/web_sw_patch.py <폴더>`).
  2. 그 폴더를 `python3 -m http.server 8140` 으로 띄운다.
  3. 안마다 녹화: `node anim_scripts/anim_shots.js http://127.0.0.1:8140/ <출력> <base|a|c> [nohand]` (Playwright, 장례 회랑 1턴: 대기 → 성검 베기 → 턴 종료 피격. `?test=1` 훅 `hideHand` 사용).
  4. 구간 프레임: `python3 anim_scripts/frames.py <출력>/anim_<안> 10 5` → 비교 표·영상: `python3 anim_scripts/compare.py` → 부위 맞춤 그림: `python3 anim_scripts/rig_fit.py <출력 파일>`.
  - 스크립트 안의 절대 경로(scratchpad·작업 사본·Godot 실행 파일·글꼴)는 그때 환경 기준이라 바꿔서 쓴다. 한 번에 돌리는 예: `anim_scripts/capture_all.sh`.

## 노엘 스탠딩 39 v1 디스필 (2026-11-21, `game/DECISIONS.md` 「노엘 스탠딩 39 v1 — [임시]」)
| 파일 | 설명 |
|---|---|
| `noel39_avg_final_dark_light.webp` | 지금 게임의 `stand_witch.png`(평균 디스필 `G = min(G, (R+B)/2)`)를 어두운·밝은 바탕에 얹은 확인 그림. 고친 39가 오면 비교용 |
