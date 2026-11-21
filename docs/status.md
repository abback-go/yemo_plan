# 현재 상태와 다음 작업 (세션 인계용)

- 기준: 2026-11-22(밤샘 계획 5에서 짧게 정리). 줄이기 전 전체(5-2장 결정 요약·그림 진행·옛 시험판 기록)는 [`archive/status-2026-11-22-full.md`](archive/status-2026-11-22-full.md).
- 작업 브랜치 `cc/amazing-darwin-nesbwh`(초안 PR: https://github.com/abback-go/yemo_plan/pull/7) · 웹(Godot 판): https://abback-go.github.io/yemo_plan/godot/ (푸시하면 CI 가 gh-pages `godot/` 에 배포)
- 개발 방법(폴더·시험·새 그림·배포·주소 옵션): [`../game/README.md`](../game/README.md)

## 1. 지금 상태
- **버티컬 슬라이스 1층(장례 탑, 튜토리얼)** 이 Godot 판에 처음부터 끝까지 있다: 곁방 → 장례 회랑 전투 → 안치 홀 지도(방 8개·랜턴 촛불·어둠) → 가장 깊은 곳(광신도 → 거대한 발) → 세라피나 데스신 새 6컷 → 빈 곁방. 대본 v3, 그림체 D 새 그림 대부분. 2·3층은 시험판 v2 내용·옛 그림.
- 전투 승리 뒤 '카드 3장 중 1장' 보상은 뺐다(2026-11-21 사용자 지시 — 표절 주의). 무덤지기만 카드 1장(기본안).
- 데모 기본 기능: 타이틀·설정(창/전체 화면·글자 속도)·일시정지(Esc·메뉴 단추)·자동 저장/이어하기.
- 밤샘 작업(2026-11-22) 진행·결과·아침에 정할 것: [`overnight-plan.md`](overnight-plan.md) — 0~3 끝, 4(움직임 시험 `?anim=a`/`?anim=c`)·5(추가 개선)·6(인수인계).
- 그림: 받은 것·못 받은 것·고칠 것은 [`art-todo.md`](art-todo.md). 판단·변경 기록은 [`../game/DECISIONS.md`](../game/DECISIONS.md), 진행 기록은 [`../game/PROGRESS.md`](../game/PROGRESS.md).

## 2. 다음 할 일
1. 아침 보고의 '사용자가 정할 것'에 답 받기([`overnight-plan.md`](overnight-plan.md) 아침 보고 · [`balance-report.md`](balance-report.md) · [`text-review.md`](text-review.md) · [`originality-review.md`](originality-review.md)).
2. 움직임 시험 A′(`?anim=a`) vs C(`?anim=c`) 중 고르기 → 동작 그림.
3. 그림: [`art-todo.md`](art-todo.md) 순서대로(카드 틀·컷인·UI·타이틀·수정본).
4. 2·3층을 버티컬 슬라이스 방식으로: 그림 목록·프롬프트(브룬힐드·엘리안 데스신 포함), 대사 말투(`text-review.md` 제안).
5. 인수인계 문서(밤샘 계획 6) — 새 세션이 저장소만 읽고 이어 가게.

## 3. 사용자 작업 방식 (지켜야 할 것)
- 한국어, 간결하게. 근거 없이 동의하지 말고 반론할 것. 불확실하면 검색해서 확인. 저장소 규칙은 [`../CLAUDE.md`](../CLAUDE.md).
- 이미지 프롬프트는 **한 번에 하나씩, 코드 블록으로**(복사 버튼으로 바로 복사) 채팅에 준다. 무엇을 첨부할지(기준 그림·직전 컷)와 새 대화창 여부를 함께 적는다. 결과 그림을 받으면 검수 → `art/raw/vs/`에 원본 저장 → 커밋·푸시(게임에 넣는 배경 제거·크기 조정은 개발 쪽에서).
- 서브에이전트는 쓰기 전에 사용자에게 묻는다(이번 세션은 큰 개발 작업을 Opus 5.5 · xhigh 백그라운드 에이전트로 맡겨 왔음).
- 사용자는 휴대폰(앱)과 PC를 오가며 확인한다. 휴대폰 앱에서는 환경 변경 승인 카드가 뜨지 않는다.
- 사용자를 '교수님'으로 부르지 않는다(사용자 정정: 본인은 '아들'). 버티컬 슬라이스 목표일 2027-04-27은 사용자의 전역일.
- **그림 검수는 디테일까지**(2026-11-22 지시): `art-direction.md` 5-1 체크리스트(옷 앞뒤·뒷모습 무릎/겹침·좌우·장식 위치·노출·비율·지시 반영·그림체·반투명 옷 배경색 물듦·배경 제거)로 부위별 확인 후 보고. 어긋나면 "통과"라고 하지 않고 수정 프롬프트를 함께. 같은 그림 2번 넘게 고쳐도 안 되면 프롬프트를 다시 써서 새 대화창에서. 프롬프트를 쓰기 **전에** 시안에서 장식 위치·옷 길이·앞뒤 공통 부분 색을 확인.
- 대사는 AI 티 금지: 명언형·쉼표/말줄임 뜸·인물 소개형("이름. 직함. 특징.")·조각문·대비 구조 금지. 노엘 속마음은 '계산하는 사람의 생각'. 규칙: `tutorial-script-vs.md` 머리.
- 받은 그림은 `art/raw/vs/<번호>_<이름>.webp`로 저장해 바로 커밋·푸시(사용자가 대화 중 붙인 그림은 다음 메시지 전에 파일로 남지 않을 수 있음 — 저장 안 된 건 다시 첨부를 부탁).
- 이미지 생성은 ChatGPT 기본 모델로(Astra·High 추론은 사용량만 많이 씀).
- **표절 주의**(2026-11-21): 슬레이 더 스파이어의 화면 구성·문구·아이콘·연출을 따라 하지 않는다 — [`originality-review.md`](originality-review.md).

## 4. 문서 지도 (읽는 순서)
| 문서 | 역할 |
|---|---|
| [`status.md`](status.md) | 이 문서 — 지금 상태·다음 할 일·문서 지도 |
| [`overnight-plan.md`](overnight-plan.md) | 밤샘 작업 계획·진행·아침 보고(사용자가 정할 것) |
| [`vertical-slice.md`](vertical-slice.md) | **결정** 버티컬 슬라이스 기획: 진행 방식·규칙·층 구조·이야기 |
| [`tutorial-script-vs.md`](tutorial-script-vs.md) | **결정** 튜토리얼(1층) 대본 v3·말투 규칙 |
| [`art-direction.md`](art-direction.md) | **결정** 그림체 D·캐릭터·데스신 수위·5-1 검수 체크리스트 |
| [`prompts/vs_assets.md`](prompts/vs_assets.md) · [`prompts/vs_assets_rest.md`](prompts/vs_assets_rest.md) | **결정** 버티컬 슬라이스 그림 프롬프트(1~74번) |
| [`art-todo.md`](art-todo.md) | 그림 할 일(못 받은 것·고칠 것·정할 것) |
| [`fate-design.md`](fate-design.md) | 운명·죽음 카드 설계 결정(2026-11-16~17, 11-21 변경 표시) |
| [`combat-system.md`](combat-system.md) | 전투 규칙 기획 v0.1(수치 주석의 기준) |
| [`prototype-v2-spec.md`](prototype-v2-spec.md) | 시험판 v2 지시서 — 지금 2·3층 코드의 기준 |
| [`balance-report.md`](balance-report.md) · [`text-review.md`](text-review.md) · [`originality-review.md`](originality-review.md) | 밤샘 2·3·0-1 보고서: 난이도·버그 / 문구 검수 제안 / 슬레이 더 스파이어와 비교 |
| [`review-brief.md`](review-brief.md) | 외부(GPT) 검토용 기획 요약 |
| [`../game/README.md`](../game/README.md) · [`../game/PROGRESS.md`](../game/PROGRESS.md) · [`../game/DECISIONS.md`](../game/DECISIONS.md) | 개발 방법 · 진행 기록 · 판단 기록 |
| [`../HANDOFF.md`](../HANDOFF.md) | 처음 인계 문서(2026-11-15, 14장 결정) — 그 뒤 결정은 위 문서들이 우선 |
| [`archive/`](archive/README.md) | 지금은 쓰지 않는 옛 문서(옛 대본 v0.6·흐름 v0.1·HTML 프로토타입 범위·옛 그림 목록/프롬프트·이 문서의 옛 전체판) |

## 5. 남은 일 / 미정
- Godot 결과 검토 → 사이트 루트(지금 HTML 프로토타입)를 Godot 판으로 바꿀지.
- 실기기 확인: 아이폰 사파리(스탠딩 비율·노치·길게 누르기·전체 화면 안 됨 안내).
- 미결: 대표 카드 컷인을 AI 영상(2~3초)으로 바꿀지 — 컷인 1개 시험 후 결정.
- 미정 기획: 마녀만 죽음을 보는 이유, 죽음 카드의 정식 이름(인스크립션 'Deathcard'와 겹침), 사제·도적 이름·외형, 임시 동료 설계, 파티 성비(UNREASON X '미소녀 동료 사망'과의 겹침 완화 검토).
- 마케팅 원칙: 문구는 "동료가 죽는다"가 아니라 "죽음을 미리 보고 카드로 쓰는 마녀".
