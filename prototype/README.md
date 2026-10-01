# 저주 매입합니다 — 플레이 가능한 프로토타입 v0.1

마녀학교 저주골동품부 부원 **루미**가 되어, 학생들의 저주 물건을 **매입**하고 학교 지하 **봉인 창고**의 미로를 탐험·턴제 전투로 해결한 뒤 **정화**해서 팔거나 장착하는 세로형 모바일 RPG 프로토타입입니다.

- 기획: [`docs/one-page.md`](../docs/one-page.md), 수치·검증: [`docs/prototype-spec.md`](../docs/prototype-spec.md)
- 형식: **HTML 한 파일** — 설치 없이 휴대폰 브라우저에서 바로 실행. (정식 엔진은 미정)

| 학교 | 부실(매입·정화) | 매점 |
|---|---|---|
| ![](screenshots/hub.png) | ![](screenshots/club.png) | ![](screenshots/shop.png) |
| **봉인 창고(미로)** | **턴제 전투** | **보스전** |
| ![](screenshots/dungeon-after-quest.png) | ![](screenshots/battle.png) | ![](screenshots/boss-battle.png) |

## 플레이 방법

1. 부실에서 손님의 저주 물건을 **매입**하면 의뢰가 시작됩니다.
2. 봉인 창고에서 바닥을 **탭**하면 그곳까지 걸어갑니다(아르피아식 클릭 이동). 십자 버튼으로 한 칸씩도 움직입니다.
3. 몬스터 칸에 들어가면 **턴제 전투**(동물농장 탐험식 메뉴): 공격 · 마법 · 물약 · 도망.
4. **약점 속성** 마법은 더 아픕니다. 기를 모으는 적은 **얼음 가시**로 끊습니다.
5. 의뢰를 마치면 부실에서 **정화** → 판매하거나 장신구로 장착합니다.
6. 정화 실적 **5건** + B5의 **그림자 집사 녹턴** 격파 → 엔딩(이후 자유 탐험).
7. 길을 잃으면 **먹물** 버튼(냄새로 방향 안내, 층마다 3번). 돌아갈 땐 처음 계단(↑)이나 귀환 깃털.

진행은 브라우저(localStorage)에 자동 저장됩니다.

## 실행

- 바로 실행: `dist/index.html` 을 브라우저로 엽니다. (휴대폰은 파일을 내려받아 열거나, 아무 정적 호스팅에 올려 링크로 엽니다.)
- 다시 빌드: `node prototype/build.cjs` → `dist/index.html`(단독 실행), `dist/artifact.html`(아티팩트 게시용)

## 구조

| 파일 | 내용 |
|---|---|
| `src/data.js` | 게임 데이터: 아이템·골동품·몬스터·층·의뢰·대사·훈장·퀴즈·조정값 |
| `src/rules.js` | 규칙(화면과 분리): 미로 생성, 이동·시야, 전투, 의뢰, 상점, 경제, 저장 |
| `src/art.js` | 그래픽: 캐릭터·몬스터·아이템·타일을 코드로 그림(외부 이미지 없음) |
| `src/ui.js` | 화면·흐름: 타이틀, 학교, 부실, 매점, 양호실, 봉인 창고, 전투, 퍼즐, 대화, 엔딩 |
| `src/audio.js` | 효과음(Web Audio 합성음) |
| `src/style.css` | 스타일 |
| `build.cjs` | 위 파일을 HTML 한 파일로 합침 |

## 테스트

```bash
node --test prototype/tests/rules.test.cjs   # 규칙 단위 테스트 25개
node prototype/tests/simulate.cjs 200        # 봇이 처음부터 엔딩까지 200판 (밸런스)
node prototype/tests/battle-sim.cjs          # 레벨별 보스·몬스터 승률
node prototype/tests/e2e.cjs [--small]       # 모바일 브라우저 E2E + 스크린샷 (Playwright 필요)
node prototype/tests/e2e-full.cjs [시드]     # 실제 UI를 조작해 엔딩까지 완주 (Playwright 필요)
```

E2E 스크립트는 전역 설치된 Playwright(`/opt/node22/lib/node_modules/playwright`)를 사용합니다. 다른 환경에서는 그 경로를 `playwright`로 바꿔 쓰면 됩니다.
