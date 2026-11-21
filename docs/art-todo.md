# 그림 할 일 목록 (못 받은 것 · 고칠 것 · 정할 것)

- 만든 날: 2026-11-22. ChatGPT 생성 한도로 중단된 지점에서 정리.
- 그림을 받을 때마다 이 목록에서 지우고, 통과하면 `art/raw/vs/`에 저장 → 개발 반영(`game/assets/`) 순서.
- 원본 프롬프트: `docs/prompts/vs_assets.md`(P01~P12) · `docs/prompts/vs_assets_rest.md`(11~74). 검수 기준: `docs/art-direction.md` 5-1.

## 1. 아직 못 받은 그림
| 번호 | 이름 | 프롬프트 위치 | 첨부 · 대화창 | 메모 |
|---|---|---|---|---|
| 10 | 카드 틀 | `vs_assets.md` P10 | `art/raw/vs/ref/10_ref_card_frame_green.png` | 결과 미수신. 받으면 11번 뒷면과 외곽선 맞는지 비교 |
| 61 | 컷인: 성검 베기(세라피나) | `vs_assets_rest.md` 61 | 기준 그림 | |
| 62 | 컷인: 저격(엘리안) | 62 | `style_D_elian_v1` | |
| 63 | 컷인: 감싸기(브룬힐드) | 63 | `style_D_brunhild_v5` | |
| 64 | 컷인: 저주의 불꽃(노엘) | 64 | `style_D_noel_v1` | |
| 65 | 컷인: 짓밟힘(노엘이 상속 카드 낼 때) | 65 | `style_D_noel_v1` | |
| 67 | 이름표 | 67 | — | **생략 권장**(이름을 대화창 안에 붉은 글자로). 결정 대기 |
| 68 | 선택지 버튼 | 대화에 준 수정본(아래 4장) | 기준 그림 · 66번 만든 대화창 | 66번 테두리에 맞춤 |
| 69 | 지도 바탕 | 69 | 기준 그림 · 66번 대화창 | |
| 70 | 지도 아이콘 8종 | 70 | 같은 대화창 | |
| 71 | 랜턴 촛불(켜짐·다 탐) | 71 | 같은 대화창 | |
| 72 | 턴 종료 버튼 | 72 | 같은 대화창 | |
| 73 | 에너지 표시 | 73 | 같은 대화창 | |
| 74 | 타이틀 | — | — | 이야기·로고가 정해진 뒤 |

## 2. 수정본을 받아야 하는 그림 (1차는 `art/raw/vs/<번호>_..._v1.webp`)
| 번호 | 이름 | 문제 | 할 일 · 프롬프트 위치 | 첨부 |
|---|---|---|---|---|
| 39 | 노엘 스탠딩 | 반투명 시폰·소매가 초록으로 물듦 | 수정 — 아래 4장 | 39번 1차 결과 · 같은 대화창 |
| 45 | 선봉 | 오른쪽이 짧은 금발 남자 기사, 망토 뒤 금 십자가, 하늘·성당·창병 | **다시 뽑기** — `vs_assets_rest.md` "45 다시 뽑기" | 기준 그림 · 브룬힐드 v5 · 엘리안 v1 |
| 46 | 감싸기 | 방패 든 사람이 짧은 금발·은 갑옷 | 수정 — "46 수정" | 46번 1차(첫째) · 브룬힐드 v5(둘째) |
| 47 | 방패 강타 | 갑옷 은갈색, 맞는 적 로브가 밝음 | 수정 — "47 수정" | 47번 1차 |
| 48 | 저격 | 뒤에 하늘·성당 | 배경만 수정 — "48 수정" | 48번 1차 |
| 49 | 견제 사격 | 뒤에 하늘·성당 | 배경만 수정 — "49 수정" | 49번 1차 |
| 50 | 저주의 불꽃 | 손톱이 길고 뾰족 | 수정 — "50 수정" | 50번 1차 |
| 51 | 운명 전가 | 레이스 장갑 없음·붉은 소매·긴 손톱, 달과 하늘, 오른쪽이 남자 | 수정 — "51 수정" | 51번 1차 |
| 52 | 대신 받기 | 뒤에 성당 | 배경만 수정 — "52 수정" | 52번 1차 |
| 55 | 짓밟힘 | 발가락 자국 6개 | 수정 — "55 수정" | 55번 1차 |
| 60 | 용사의 죽음 | 그림자가 발로 안 읽힘 | 수정 — "60 수정"(아래 3장 결정과 함께) | 60번 1차 |
| 53 | 죽음의 예지 | 눈에 비친 장면에 붉은 달(카드 크기에서 약 12px) | **선택** — "53 수정" | 53번 1차 |

- 모든 수정은 카드를 만들던 대화창에서. 같은 그림을 2번 고쳐도 안 되면 새 대화창에서 다시 뽑는다.

## 3. 사용자 결정 대기
- **18 계단 앞 홀**: 계단이 위로 올라가는 모양 → 아래로 내려가게 고칠지(프롬프트 아래 4장).
- **23 죽은 마녀 CG**: 머리가 은백(노엘은 와인빛) → 반전을 숨기기 좋아 그대로 두기를 추천.
- **60 용사의 죽음 ↔ 대본**: 대본 221행은 "세라피나의 얼굴", 그림은 땋은 머리 + 거대한 그림자 → 대본을 "세라피나의 땋은 머리, 그 위를 덮은 거대한 그림자"로 바꾸기를 추천.
- **67 이름표**: 생략할지.
- **배경 제거 도구**: `tools/remove_bg.py`가 몸 안쪽 중간 톤까지 반투명하게 만듦 → 도구를 고칠지(그때까지 개발 반영은 `--soft 100`으로 피함).

## 4. 대화에서만 줬던 프롬프트 (여기 보관)
### 39 노엘 스탠딩 수정 (첨부: 39번 1차 결과 · 같은 대화창)
```
Edit this image: keep her face, pose, hair, hat, outfit, the cards, the crimson threads and the plain flat pure green (#00FF00) background exactly the same. Change only the color of all the sheer, see-through fabric (the tattered sleeve ends, the layered skirt hems and any chiffon): repaint it as opaque, smoky charcoal-black and dark brown fabric with no background color showing through. There must be no green or olive tint anywhere on her clothes.
```
### 18 계단 앞 홀 수정 — 결정되면 (첨부: 18번 결과 · 같은 대화창)
```
Edit this image: keep the same room, camera, style and lighting. Change only the staircase: it is a wide spiral staircase that goes DOWN from this landing into the depths. Remove the steps rising upward; instead, the first steps start at the edge of the landing and wind downward around a dark open stairwell, with the faint crimson glow coming from far below. Keep the candles along the inner wall and the iron railing. Change nothing else.
```
### 68 선택지 버튼 (첨부: 기준 그림 · 66번 만든 대화창)
```
Using the attached image only as a style reference, draw a game UI element: a horizontal button, about 6:1, front view, flat. Match the parchment color and the twisted thorn-vine border of the dialogue box you just made: the same aged tan parchment inside and the same thin border of twisted thorny vines, of even thickness all around, with a tiny crimson rose at the left and right ends only. The center is empty. Delicate ink linework and faded watercolor; the only vivid color is deep crimson. No text, no letters. Background: plain flat pure green (#00FF00).
```

## 5. 원하면 (선택)
- 37 엘리안 놀람: 몸이 기본(36)과 3% 달라 36을 바탕으로 다시 뽑을 수 있음.
- 브룬힐드 흉터: 확대하면 피눈물처럼 보임 — 거슬리면 수정.

## 6. 아직 목록도 안 만든 것
- 2·3층 그림(브룬힐드·엘리안 데스신 포함) — 목록·프롬프트부터.
