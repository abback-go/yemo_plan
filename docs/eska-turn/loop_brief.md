# 개발 루프 공통 지침 (개발자·검토자 에이전트용)

> 총괄(Claude 메인 세션)이 개발자·검토자 에이전트에게 주는 공통 지침. 라운드마다 이 파일 + `loop_status.md`를 먼저 읽는다.

## 꼭 읽을 것
- `CLAUDE.md` (상비 규칙), `docs/eska-turn/README.md` §0 전체(특히 §0-12 결정 50항목, §0-12-2 11차 지시)
- `docs/eska-turn/combat_proto.md` (우리 전투 기획서 1.0 — 규칙의 기준)
- `docs/eska-turn/witches_12.md` (12명·마법 120개 수치 = `game/proto/turn/t_data.gd`)
- `docs/eska-turn/fgo_battle_reverse.md` (FGO 참고 명세 — 구조만 참고, 이름·고유 요소 복제 금지)
- 코드: `game/proto/turn/` (`t_data` 표 · `t_unit`/`t_battle` 규칙 · `t_stage` 흐름 · `t_hud` 표시·입력 · `t_setup` 편성 · `t_fx` 연출 · `t_icon` 아이콘 · `t_witch_art`/`t_enemy_art` 그림 · `t_backdrop` 배경 · `t_auto` 자동 선택)

## 늘 지킬 것 (사용자 규칙)
- 모든 글은 한국어. 코드 식별자·경로·명령은 원문. 기존 코드의 주석 밀도·이름·문체를 따른다.
- 특정 작품 고유 요소 복제 금지(FGO 서번트·보구 이름, 버스터/아츠/퀵 이름 등 쓰지 않음 — **구조만**). 받아치기·패리 금지. 내 공격 타이밍 입력 없음. 에스카는 무기·베기 없음. 폭주 상태 없음.
- 사용자는 **안드로이드 폰 웹(가로)** 으로 플레이 → 터치 우선, 글자·버튼이 작은 화면에서 읽히고 눌려야 한다.
- 질문하지 않는다. 애매하면 추천안으로 정하고 문서에 [제안]으로 남긴다.
- DRY: 새 함수 전에 비슷한 것이 있는지 찾는다.
- "보통·아마·대체로" 같은 흐린 말 금지. 모르는 FGO 사실은 웹 검색으로 확인(Atlas Academy·GamePress 등).

## 사용자가 특히 원하는 것 (11차 지시)
- **FGO처럼 보기 쉽고 직관적이며 조잡하지 않은 UI**. 전투 화면(UI·캐릭터 배치)을 신경 써서 개선. 출시 가능한 수준. 아트는 최대한 예쁘게.
- 마법은 효과를 마구 조합하지 말고 **FGO의 인기 서포터·딜러 스킬 구조**를, 대마법은 **강력한 보구들**을, 패시브는 **클래스 스킬·기본 패시브**를 참고. 조합했을 때 재밌고 강력한 빌드가 나오게 **계산해서**.
- **속성별 플레이스타일**이 달라야 함 (예: 불 = 버스터처럼 한 방, 물 = 아츠처럼 자원 순환·버티기, 번개 = 퀵처럼 크리·차례 — 이름·규칙은 그대로 쓰지 않음).
- **빌드 원형**: 강력한 평타 크리(초인 오리온 같은), 대마법 3연속(FGO "시스템" 같은 — 크레딧 배터리로), 아주 강한 적을 버티며 피해를 쌓는 예능 빌드(수행사제팟 같은) 등. 여기에 매몰되지 말고 다양하게.

## 작업 방법
- Godot: `/tmp/godot/Godot_v4.7.2-stable_linux.x86_64` (없으면 `tools/test/README.md`대로 내려받기). 명령은 `game/`에서.
  - 스크립트 검사: `$G --headless --script ../tools/test/check_scripts.gd` → `failures: 0`
  - 밸런스: `$G --headless --script ../tools/test/turn_sim.gd -- 30`
  - 화면 확인: `xvfb-run -a -s "-screen 0 1280x720x24" $G --rendering-driver opengl3 --fixed-fps 60 --resolution 640x360 --script ../tools/test/runner.gd -- ../tools/test/scenarios/turn_touch.json /tmp/out` 뒤 PNG를 Read로 직접 본다. 턴제 시나리오는 `turn_*.json`.
  - 표 다시 찍기: `$G --headless --script ../tools/test/dump_skills.gd` → `witches_12.md` §4에 붙임.
- 문서 = 코드: 규칙을 바꾸면 `combat_proto.md`의 해당 절과 (구현됨)/(미구현) 표시를 고친다. 수치를 바꾸면 표를 다시 찍는다.
- 커밋: 라운드 끝에 브랜치 `cc/vigilant-dirac-751x7b`에 커밋·`git push origin cc/vigilant-dirac-751x7b`. force push·rebase 금지. 커밋 메시지 끝에 두 줄:
  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01DHvRxWhf9XPxXtwMcNcps4
  ```
  커밋·PR·코드 주석에 모델 이름/ID를 쓰지 않는다. push하면 GitHub Actions가 웹 빌드를 gh-pages에 올린다(`?turn`).
- 라운드 끝에 `loop_status.md`의 라운드 기록·다음 할 일을 고친다.
- 끝낼 때 보고: 한 일 · 실행한 검증(명령과 결과 숫자) · 못 한 것 · 다음에 할 것. 짧게.
