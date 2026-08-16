# yemo_plan

2D 메트로배니아 게임의 상세 기획서(GDD)를 작성하는 **문서 전용 리포**입니다.
게임 코드는 이 리포에 두지 않으며, 구현 대상 환경은 **Unity 6 / C# / PC**를 전제로 합니다.
모든 문서는 `reference/textbook.pdf`를 기준 교재로 삼아 한국어로 작성합니다.

## 기획 문서 목록 (docs/)

각 문서는 아래 역할을 가지며, 작성되는 대로 링크가 연결됩니다.

| 문서 | 역할 | 상태 |
|---|---|---|
| [`docs/00_game_concept.md`](docs/00_game_concept.md) | 게임 콘셉트: 장르, 핵심 재미, 타깃, MVP 범위를 정의한다 | 작성 완료 |
| [`docs/01_core_loop.md`](docs/01_core_loop.md) | 핵심 플레이 루프: 플레이어가 반복하는 행동 흐름을 정의한다 | 작성 완료 |
| [`docs/02_player_control.md`](docs/02_player_control.md) | 플레이어 조작: 입력 명세, 캐릭터 상태 머신, 애니메이션 전환 조건 | 작성 완료 |
| [`docs/03_combat_system.md`](docs/03_combat_system.md) | 전투 시스템: 공격 판정, 고정 데미지 규칙, 피격 처리, 적 행동 패턴 | 작성 완료 |
| [`docs/04_ability_gate.md`](docs/04_ability_gate.md) | 가호·신성 체계와 능력 게이트: 신성 15개 명세, 공용 이동 신성, 습득 경로, 게이트 판정 규칙 | 작성 완료 |
| `docs/05_map_progression.md` | 맵과 진행: 방 연결 구조, 역주행 동선, 세이브/체크포인트 | 예정 |
| `docs/06_item_reward.md` | 아이템과 보상: 아이템 종류, 획득 조건, 보상 테이블 | 예정 |
| `docs/07_ui_flow.md` | UI 흐름: 화면 목록, 버튼 동작, 화면 전환 조건 | 예정 |
| `docs/08_stage_design.md` | 스테이지 설계: 구역별 목표, 적 배치, 난이도 곡선 | 예정 |
| `docs/09_data_table.md` | 데이터 테이블: 캐릭터/적/아이템/스킬 수치 표 | 예정 |
| [`docs/99_change_log.md`](docs/99_change_log.md) | 변경 이력: 기획 변경 사항을 한 줄씩 기록한다 | 기록 중 |

## 참고 자료 (reference/)

| 문서 | 역할 |
|---|---|
| `reference/textbook.pdf` | 이 프로젝트의 유일한 기준 교재 |
| `reference/textbook_rules.md` | 교재 Part별 요약과 문서 작성 원칙 |
| `reference/templates/` | 교재 부록 기반 문서 템플릿 (기획서 기본 구조, 콘셉트, 플레이 루프) |

## 작업 규칙

문서 작성 규칙과 금지 사항은 루트의 `CLAUDE.md`를 따릅니다.
