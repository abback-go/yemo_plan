# 이미지 생성 프롬프트 (ChatGPT 이미지 생성용, 확정본)

- 영어 프롬프트가 더 안정적이라 영어로 작성했다.
- 카드·UI 위 글자는 깨지기 쉬워서 모두 `No text`로 지정했다.
- 거대 존재의 외형은 임시값(갈라진 회색 돌 같은 피부 + 마른 피). 디자인이 정해지면 그 문장만 모든 프롬프트에서 똑같이 바꾼다.
- 같은 동료 묘사를 모든 프롬프트에 그대로 붙여넣어야 캐릭터가 덜 바뀐다. 캐릭터 시트를 만든 뒤에는 그 이미지를 레퍼런스로 함께 첨부한다.

---

## ① 일반 전투 화면 — 정면 눈높이, 사람 크기 적 여러 마리
결과물: `reference/images/04_mock_battle_normal_eyelevel_APPROVED.png`

```
Dark fantasy turn-based card game battle screen, 16:9, anime illustration style.
Fixed eye-level camera placed behind the party. Three adult female adventurers stand in the lower-left and lower-right foreground in three-quarter rear view (a swordswoman, an archer, a priestess), kept small enough to leave the center of the screen open.
In the open center, three human-sized enemies face the viewer: hollow-eyed cultists in tattered robes holding rusted blades.
Ruined gothic dungeon, cold blue-gray palette with a single deep red accent.
UI: a small fanned hand of five blank cards at the bottom center, small HP bars near each character. No text, no letters, no logos.
```

## ② 거대 보스 전투 화면 — 같은 각도, 일부만 보이게
결과물: `reference/images/05_mock_battle_giant_eyelevel_APPROVED.png`

```
Dark fantasy turn-based card game battle screen, 16:9, anime illustration style.
Same fixed eye-level camera behind the party. Three adult female adventurers stand in the lower-left and lower-right foreground in three-quarter rear view, small in frame.
A colossal creature far too big for the screen: only part of one enormous foot is visible, descending from the top edge and cropped by the frame. Its skin is cracked, gray, stone-like, and stained with dried blood.
Collapsed pillars and falling debris show the scale. Its shadow darkens the upper half of the scene.
UI: a small fanned hand of five blank cards at the bottom center, small HP bars. No text, no letters, no logos.
```

## ③ 사망 컷신 — 리버스 샷 (최종)
결과물: `reference/images/07_cutscene_archer_v3_APPROVED.png`

```
Cinematic anime illustration, 16:9, dark fantasy.
Eye-level medium close-up, the camera directly facing an adult female elf archer: long blonde braided hair tied with a dark green ribbon bow, pointed elf ears, green eyes, a dark green hooded cloak with gold embroidery, brown leather armor, a quiver of white-feathered arrows on her back.
She makes direct eye contact with the viewer, looking straight into the camera lens, with a soft, gentle, closed-mouth smile. She is calm and trusting.
She has her back turned to the danger and cannot see it. Behind her head, in the background, a colossal foot descends from the top of the frame, cropped by the top edge. Its skin is cracked, gray, and stone-like, stained with dried blood, and sunk in deep shadow.
Setting: a ruined gothic cathedral with a glowing red stained-glass window and tattered red banners in the distance.
Lighting: warm, soft light on her face from the front; cold darkness from the foot's shadow creeping down from above. Dust and small stones begin to fall around her hair, which lifts slightly in the wind pressure.
Mood: tragic, beautiful, ominous, quiet. No gore, no text, no letters.
```

다듬을 때 추가할 문장
- 발가락이 통나무처럼 보이면: `anatomically shaped toes with cracked toenails`
- 긴박감을 더하려면: `the upper third of the frame is already swallowed by the foot's shadow`
- 시선이 위로 가면 첫 줄 다음에: `She is not looking up.`

## 트러블슈팅 메모

- 동료가 정면을 보면: `three-quarter rear view` → `over-the-shoulder view from behind`
- 거대 존재가 화면에 다 들어오면: `cropped by the top edge of the frame` 추가
- 폐기한 방향: 로우앵글 정면(아래에서 올려다보는 구도) — 다양한 적에 맞지 않고 하체가 강조되어 폐기

---

## 캐릭터 시트 프롬프트 (2026-11-15 추가)

캐릭터별 파일로 분리했다. 각 파일에 1단계 시트 · 편집 프롬프트 · 2단계 단일 뷰 · 3단계 표정 · 체크리스트가 모두 들어 있다.

| 파일 | 캐릭터 | 2단계 산출물 |
|---|---|---|
| [`prompts/01_seraphina.txt`](prompts/01_seraphina.txt) | 용사 세라피나 | `stand_hero.png`, `spr_hero_back.png` |
| [`prompts/02_brunhild.txt`](prompts/02_brunhild.txt) | 전사 브룬힐드 | `stand_warrior.png`, `spr_warrior_back.png` |
| [`prompts/03_elian.txt`](prompts/03_elian.txt) | 궁수 엘리안 | `stand_archer.png`, `spr_archer_back.png` |
| [`prompts/04_noel.txt`](prompts/04_noel.txt) | 마녀 노엘 | `stand_witch.png` |

- 1단계 시트는 `reference/sheets/`에, 2단계 결과물은 배경 제거 후 `prototype/assets/`에 넣는다.
- 위 ③ 사망 컷신 프롬프트는 궁수 기준이다. 용사 버전(`cut_hero_reverse.png`)은 캐릭터 시트가 나온 뒤 작성한다.
