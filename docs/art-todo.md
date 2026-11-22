# 그림 할 일 (못 받은 것 · 고칠 것 · 정할 것)

- 고친 날: 2026-11-22(인수인계 정리). **이 문서 하나만 보고 그림을 받을 수 있게** 번호마다 프롬프트 전문·첨부·대화창을 둔다.
- 프롬프트 원본: `docs/prompts/vs_assets.md`(P01~P12) · `docs/prompts/vs_assets_rest.md`(11~74). 여기 블록은 사본이다 — **원본과 다르면 원본이 맞다.**
- 받아서 통과하면 그 번호 블록을 통째로 지운다.

## 0. 규칙
### 사용자에게 줄 때
- **코드 블록 하나에 프롬프트 하나**, 한 번에 하나씩 준다(사용자가 몰아 달라고 하면 블록을 나눠 한꺼번에). "여기부터 복사" 같은 표시는 넣지 않는다.
- 블록 바로 위에 **첨부**(파일 이름 + 누를 수 있는 GitHub 링크)와 **대화창**(같은 대화창 / 새 대화창)을 적는다.
- ChatGPT 기본 모델로 뽑는다. 거절되면 새 대화창에서 다시. 같은 그림을 2번 고쳐도 안 되면 프롬프트를 다시 써서 새 대화창에서 처음부터.
- "같은 대화창"이 남아 있지 않으면 새 대화창에 같은 첨부를 올리고 같은 프롬프트를 쓴다.
- 링크 앞부분: `https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/` + 파일 경로(로그인 필요).
  - 기준 그림 [`reference/style/style_D_seraphina_anchor.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/reference/style/style_D_seraphina_anchor.webp) · 브룬힐드 [`style_D_brunhild_v5.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/reference/style/style_D_brunhild_v5.webp) · 엘리안 [`style_D_elian_v1.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/reference/style/style_D_elian_v1.webp) · 노엘 [`style_D_noel_v1.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/reference/style/style_D_noel_v1.webp)

### 받은 뒤
1. **검수**: `docs/art-direction.md` 5-1 체크리스트로 기준 그림·시안과 부위별 비교. 하나라도 어긋나면 "통과"라고 하지 않고 고칠 곳 + 수정 프롬프트를 준다.
2. **저장**: `art/raw/vs/<번호>_<이름>.webp`(통과본). 고칠 1차본은 `_v1`(2차는 `_v2`)로 남긴다. 받는 즉시 저장·커밋 — 작업 중에 붙인 그림은 파일로 남지 않을 수 있어 그때는 다시 첨부를 부탁한다.
3. **게임 반영**: `python3 tools/vs_import.py --only <이름>` — 크로마 배경 제거(`remove_bg.py --soft 100`)·테두리 번짐 정리·크기 줄임 → `game/assets/`. 확인 그림은 `--check <폴더>`.
   - `--only` 값: 스프라이트는 원본 이름(예 `08_cultist`), 표정 스탠딩은 `hero`·`warrior`·`archer`·`noel`, 그 밖에 `cards`·`icons`·`dialog`·`bg`·`death`.
   - `_v1` 이름으로 걸린 대응(카드 45~53·55·60, 노엘 39)은 `vs_import.py` 대응표에서 새 이름으로 바꾼다.
   - 대응이 아직 없는 것(10 카드 틀, 61~65 컷인, 67~73 UI)은 반영 코드를 새로 짠다(번호별 메모).
4. 이 목록에서 그 번호 블록을 지우고 `game/DECISIONS.md` 대응표를 고친다.

## 1. 받을 순서 (추천 — 1층 데모에 늘 보이는 것부터)
| 순서 | 번호 | 무엇 | 대화창 | 이유 |
|---|---|---|---|---|
| 1 | 39 | 노엘 스탠딩 수정 | 노엘 스탠딩 | 주인공, VN 내내 보임. 지금은 초록이 물든 1차본을 임시로 씀 |
| 2 | 10 | 카드 틀 | 새 | 모든 카드에 보임. 지금은 옛 그림체 틀 |
| 3 | 45 → 46 → 51 → 60 | 카드: 인물이 틀림 · 3턴에 뒤집히는 죽음 카드 | 카드 | 다른 인물(짧은 금발 남자 기사)이 그려짐 / 60은 핵심 장면 |
| 4 | 47 → 50 → 48 → 49 → 52 → 55 (53 선택) | 카드: 작은 수정 | 카드 | 48·49·52는 배경만 바꾸는 같은 종류라 연달아 |
| 5 | 72 → 73 | 턴 종료 · 에너지 | UI(66번) | 전투 화면에 늘 보임. 지금은 코드로 그린 것 |
| 6 | 61 → 63 → 62 → 64 → 65 | 컷인 | 캐릭터마다 스탠딩 | 대표 카드를 낼 때마다 보임. 지금은 옛 그림체 |
| 7 | 68 → 69 → 70 → 71 | 선택지 · 지도 · 촛불 | UI(66번) | VN 선택지·지도 화면. 지금은 코드로 그린 것 |
| — | 18 · 67 · 74 | 계단 수정 · 이름표 · 타이틀 | — | 사용자 결정(4장) · 이야기·로고가 정해진 뒤 |

---

## 2. 아직 못 받은 그림

### 10 카드 틀
- 원본: `vs_assets.md` 「P10 카드 틀」
- 첨부 2장: [`art/raw/vs/ref/10_ref_card_frame_green.png`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/ref/10_ref_card_frame_green.png)(첫째) · 기준 그림(둘째) · **새 대화창**
- 저장(제안): `10_card_frame.webp` → `game/assets/card_frame.png` 를 바꾼다. 틀 속 창 자리(위 창 22,24 / 201×204, 비용 원 15,16 / 37×37 — 카드 240×360 기준)가 어긋나면 `game/ui/card_view.gd` 수치를 다시 맞춘다. 11번 뒷면(`11_card_back`)과 외곽선이 맞는지 비교.
```
Redraw the first attached image, a card frame for a card game, in the style of the decorative thorn-and-rose border of the second attached image (ignore the character and the scene inside the second image).

KEEP EXACTLY THE SAME AS THE FIRST IMAGE
The canvas size and proportions, the rounded outer outline, the round cost medallion at the top-left corner, the large upper window, the horizontal divider bar, and the lower window — the same positions, sizes and thicknesses. Everything that is green in the first image stays plain flat pure green (#00FF00): the inside of the cost medallion, the inside of both windows, and the area outside the card. Draw nothing inside the windows. No text, no numbers.

CHANGE
Draw the frame like the border of the second image: delicate, slightly rough black ink linework of thorny vines and small crimson roses over aged bone-white and sepia, with faded watercolor shading and a subtle parchment grain. A small crimson rose at each corner and at the center of the divider bar; thin thorny vines running along the frame. The cost medallion is a ring of ink-drawn thorns. The only vivid color is deep crimson.

AVOID
Changing the layout, filling the windows, text, numbers, letters, a 3D metal look, watermark, signature.
```

### 61~65 컷인 (공통)
- 대표 카드를 낼 때 화면을 가로지르는 앞모습 그림(지금 게임 1672×941, 16:9). 첨부는 그 캐릭터의 시안 한 장(세라피나는 기준 그림), **캐릭터마다 스탠딩을 뽑던 대화창**에서.
- 반영: `game/data/game_data.gd` 컷인 표(`holy_slash`→`cutin_hero.png`, `snipe`→`cutin_archer.png`, `cover`→`cutin_warrior.png`, `curse_flame`→`cutin_witch_cast.png`, `trample`→`cutin_witch_inherit.png`). 옛 컷인은 배경을 지운 그림이고 새 프롬프트는 배경까지 꽉 찬 그림이라, 넣을 때 컷인 연출(초점 `focus` 등)을 확인한다.
- 저장(제안): `61_cutin_holy_slash` · `62_cutin_snipe` · `63_cutin_cover` · `64_cutin_curse_flame` · `65_cutin_trample` (`.webp`)

#### 61 성검 베기 (세라피나)
- 원본: `vs_assets_rest.md` 「61」 · 첨부: 기준 그림 · 세라피나 스탠딩(28~31) 대화창
```
Using the attached image as the reference for both the art style and the character, draw a dramatic action cut-in for a card game: a wide 16:9 landscape, full bleed, no border, no text. A close, dynamic three-quarter front view of Seraphina mid-swing, slashing her sacred longsword in a sweeping crimson arc from upper right to lower left, her silver braid and crimson cape flying, eyes fierce. The sword is in her right hand. Strong ink speed lines; delicate, slightly rough ink linework with cross-hatching and faded watercolor in bone white, ash gray and sepia; the only vivid color is deep crimson. Natural adult proportions, not anime.
```

#### 62 저격 (엘리안)
- 원본: `vs_assets_rest.md` 「62」 · 첨부: `style_D_elian_v1.webp` · 엘리안 스탠딩(36~38) 대화창
```
Using the attached image as the reference for both the art style and the character, draw a dramatic action cut-in for a card game: a wide 16:9 landscape, full bleed, no border, no text. A close, dynamic three-quarter front view of Elian at full draw with her white longbow held in her left hand, the arrow just released, her eye narrowed along the shaft, her long golden hair and emerald cloak swept back. Strong ink speed lines; delicate, slightly rough ink linework with cross-hatching and faded watercolor in bone white, ash gray and sepia; the vivid colors are deep crimson and emerald. Natural adult proportions, not anime.
```

#### 63 감싸기 (브룬힐드)
- 원본: `vs_assets_rest.md` 「63」 · 첨부: `style_D_brunhild_v5.webp` · 브룬힐드 스탠딩(32~35) 대화창
```
Using the attached image as the reference for both the art style and the character, draw a dramatic action cut-in for a card game: a wide 16:9 landscape, full bleed, no border, no text. A close, dynamic three-quarter front view of Brunhild stepping in front with her massive black tower shield on her left arm as a heavy blow crashes into it, dried straw-colored wildflowers and sparks scattering, her black hair and crimson scarf whipping in the impact, a sly, fearless half-smile. Strong ink speed lines; delicate, slightly rough ink linework with cross-hatching and faded watercolor in bone white, ash gray and sepia; the only vivid color is deep crimson. Natural adult proportions, not anime.
```

#### 64 저주의 불꽃 (노엘)
- 원본: `vs_assets_rest.md` 「64」 · 첨부: `style_D_noel_v1.webp` · 노엘 스탠딩(39) 대화창
- 원본 39번 메모: 노엘 컷인도 반투명 옷이 있으면 끝에 `All the sheer chiffon and sleeves are painted as opaque smoky charcoal-black fabric: no background color shows through them.` 를 붙인다.
```
Using the attached image as the reference for both the art style and the character, draw a dramatic action cut-in for a card game: a wide 16:9 landscape, full bleed, no border, no text. A close, dynamic three-quarter front view of Noel thrusting her right hand forward, crimson threads around her fingers, releasing a curling crimson flame shaped like thorny vines; her wine-red hair and the brim of her witch hat swept by the blast, crimson eyes cold and sad. Strong ink speed lines; delicate, slightly rough ink linework with cross-hatching and faded watercolor in bone white, ash gray and sepia; the only vivid color is deep crimson. Natural adult proportions, not anime.
```

#### 65 짓밟힘 (노엘이 상속 카드를 낼 때)
- 원본: `vs_assets_rest.md` 「65」 · 첨부: `style_D_noel_v1.webp` · 노엘 스탠딩(39) 대화창
```
Using the attached image as the reference for both the art style and the character, draw a dramatic action cut-in for a card game: a wide 16:9 landscape, full bleed, no border, no text. Noel, seen from a low three-quarter front angle, slams her open hand downward; above her, the vast shadow of a colossal foot comes crashing down onto the enemies in front of her, cracked stone and dust bursting upward. Strong ink speed lines; delicate, slightly rough ink linework with cross-hatching and faded watercolor in bone white, ash gray and sepia; the only vivid color is deep crimson. No gore, no bodies.
```

### 66~73 UI (공통)
- 첨부: 기준 그림 · **66번(대화창 그림)을 만든 대화창**에서 이어서(테두리를 66번과 맞추려고). 모두 글자 없음.
- 지금 게임은 턴 종료·에너지·선택지·지도·촛불을 코드로 그린다 → 받으면 반영 코드를 새로 짠다. 늘여 쓰는 것(선택지·지도 바탕)은 9조각(`NinePatchRect`, 66번과 같은 방식).
- 저장(제안): `68_ui_choice_button` · `69_ui_map_parchment` · `70_ui_map_icons` · `71_ui_lantern_candle` · `72_ui_end_turn` · `73_ui_energy` (`.webp`)

#### 72 턴 종료 버튼
- 원본: `vs_assets_rest.md` 「72」 · 같은 대화창
```
Using the attached image only as a style reference, draw a game UI button: a round crimson wax seal pressed with a thorn-and-rose pattern, front view, flat, with a little light on its glossy edge. The center of the seal is plain so a word can be placed on it later. No text, no letters. Background: plain flat pure green (#00FF00).
```

#### 73 에너지 표시
- 원본: `vs_assets_rest.md` 「73」 · 같은 대화창
```
Using the attached image only as a style reference, draw a game UI element: an empty round black iron frame wrought into thorny vines, holding a round deep-crimson gem in its center, front view, flat. The gem's face is plain so a number can be placed on it later. Delicate ink linework and faded watercolor. No text, no numbers. Background: plain flat pure green (#00FF00).
```

#### 68 선택지 버튼 (66번 테두리에 맞춘 수정본)
- 원본: 대화에서 준 수정본(2026-11-21, `vs_assets_rest.md` 「68」을 66번 대화창 테두리에 맞게 고침 — 원본 문서에는 처음 판만 있다) · 첨부: 기준 그림 · 66번 대화창
```
Using the attached image only as a style reference, draw a game UI element: a horizontal button, about 6:1, front view, flat. Match the parchment color and the twisted thorn-vine border of the dialogue box you just made: the same aged tan parchment inside and the same thin border of twisted thorny vines, of even thickness all around, with a tiny crimson rose at the left and right ends only. The center is empty. Delicate ink linework and faded watercolor; the only vivid color is deep crimson. No text, no letters. Background: plain flat pure green (#00FF00).
```

#### 69 지도 바탕
- 원본: `vs_assets_rest.md` 「69」 · 같은 대화창
```
Using the attached image only as a style reference for its thorn-and-rose border, draw a blank sheet of aged parchment filling a wide 16:9 landscape image, with faint ink stains, folds and a thin border of ink-drawn thorny vines and small crimson roses along the edges. Nothing drawn in the middle. No text, no letters, no map lines.
```

#### 70 지도 아이콘 8종
- 원본: `vs_assets_rest.md` 「70」 · 같은 대화창. 받으면 한 줄로 잘라 8장(예고 아이콘 12번을 자른 방식 — `vs_import.py` `ICONS`).
```
Using the attached image only as a style reference, draw eight small round map icons in one row with clear space between them, each a small round parchment disc with a thin inked thorn border, front view, flat: 1) a single sword (battle), 2) a horned skull (elite enemy), 3) a question mark (event), 4) a candle flame (rest), 5) two crossed swords (training), 6) a small coffin with a coin on it (trade), 7) an open eye (omen), 8) a stone stairway going down (stairs to the next floor). Delicate, slightly rough ink linework and faded watercolor; the only vivid color is deep crimson. No text, no numbers. Background: plain flat pure green (#00FF00).
```

#### 71 랜턴 촛불 (켜짐 · 다 탐)
- 원본: `vs_assets_rest.md` 「71」 · 같은 대화창
```
Using the attached image only as a style reference, draw two small game UI icons side by side with clear space between them, front view, flat: 1) a single white candle burning with a pale, warm flame, 2) the same candle burnt down to a stub, the flame out, a thin curl of smoke. Delicate, slightly rough ink linework and faded watercolor; the only vivid color is deep crimson. No text. Background: plain flat pure green (#00FF00).
```

### 74 타이틀
- 이야기·로고가 정해진 뒤 프롬프트를 새로 짠다(`vs_assets_rest.md` 「74」). 지금 타이틀은 '가장 깊은 곳' 배경을 어둡게 해서 쓴다.

---

## 3. 수정본을 받아야 하는 그림
- 1차본: `art/raw/vs/<번호>_..._v1.webp`(게임에는 지금 1차본이 들어가 있다). **카드를 만들던 대화창**에서 고친다(39는 노엘 스탠딩 대화창).
- 반영: 통과본을 `_v1` 없는 이름으로 저장 → `vs_import.py` 대응표의 이름을 바꾸고 `--only cards`(39는 `--only noel`).

### 39 노엘 스탠딩 — 반투명 시폰·소매가 초록으로 물듦
- 원본: 대화에서 준 수정 프롬프트(2026-11-21) · 첨부: [`39_stand_noel_v1.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/39_stand_noel_v1.webp) · 노엘 스탠딩 대화창
- 저장: `39_stand_noel.webp`. 반영할 때 `vs_import.py` 의 `STANDS['noel']`·`FULL_DESPILL`(초록 물든 1차본용 몸 전체 디스필 — 새 그림에 초록이 없으면 뺀다)을 고친다. 노엘 VN 스탠딩이 모자 끝까지 높이 1010에 맞춰져 얼굴이 다른 인물보다 낮은 문제도 이때 맞춘다(밤샘 아침 보고). 얼굴 자리 `faces.noel` 도 새 그림에 맞춘다. 비교용: `reference/trials/noel39_avg_final_dark_light.webp`.
```
Edit this image: keep her face, pose, hair, hat, outfit, the cards, the crimson threads and the plain flat pure green (#00FF00) background exactly the same. Change only the color of all the sheer, see-through fabric (the tattered sleeve ends, the layered skirt hems and any chiffon): repaint it as opaque, smoky charcoal-black and dark brown fabric with no background color showing through. There must be no green or olive tint anywhere on her clothes.
```

### 45 선봉 — 다시 뽑기
- 1차 문제: 오른쪽이 짧은 금발 남자 기사, 망토 뒤 금 십자가, 하늘·성당·창병 군대
- 원본: `vs_assets_rest.md` 「45 다시 뽑기」 · 첨부 3장: 기준 그림 · `style_D_brunhild_v5.webp` · `style_D_elian_v1.webp` · 카드 대화창(1차 `45_card_vanguard_v1.webp` 는 첨부하지 않는다)
```
Using the attached images as references — the first for the art style and for the holy knight, the second for the black knight, the third for the elf archer — draw a square 1:1 card illustration, full bleed, no border, no text. Low angle from slightly behind: the holy knight from the first image (long silver braid tied with crimson ribbons, a crimson bow at the top of her head, silver plate armor, a torn crimson cape with no cross or emblem on it) strides forward at the head of the party, raising her sword with the winged gold guard and red gem high in her right hand. A step behind her on the right, the black knight from the second image: a woman with long straight black hair and blunt bangs, in black plate armor with fine silver filigree, carrying her tall black tower shield with silver thorns and a small bouquet tied with a crimson ribbon. A step behind on the left, the elf archer from the third image: long wavy blonde hair with a braided crown and white feathers, pointed ears, a white fur collar on a dark green cloak, a white bow and a quiver. They are deep underground in a vast crypt: massive stone arches, walls of bone-filled niches, hanging iron lanterns; no sky, no moon, no outdoor buildings. Ahead of them in the gloom stand a few hooded cultists in tattered charcoal robes. Delicate, slightly rough ink linework with cross-hatching and faded watercolor in bone white, ash gray and sepia; the only vivid color is deep crimson, and the archer's green cloak stays muted.
```

### 46 감싸기 — 방패 든 사람을 브룬힐드로
- 1차 문제: 방패 든 사람이 짧은 금발·은 갑옷
- 원본: `vs_assets_rest.md` 「46 수정」 · 첨부 2장: [`46_card_cover_v1.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/46_card_cover_v1.webp)(첫째) · `style_D_brunhild_v5.webp`(둘째) · 카드 대화창
```
Edit the first attached image. Use the second attached image only for the knight's look. The knight peeking over the shield is the woman in the second image, Brunhild: long, straight black hair with blunt bangs, amber-gold eyes, and black plate armor with fine silver thorn-and-flower filigree, with a torn crimson scarf at her neck. Replace the short pale hair and the silver armor with these. Keep everything else exactly the same: the shield and its silver thorns, the bouquet with the crimson ribbon, the sparks, the petals, the composition and the art style.
```

### 51 운명 전가
- 1차 문제: 레이스 장갑 없음·붉은 소매·긴 손톱, 달과 하늘, 오른쪽 사람이 짧은 머리 남자
- 원본: `vs_assets_rest.md` 「51 수정」 · 첨부: [`51_card_fate_shift_v1.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/51_card_fate_shift_v1.webp) · 카드 대화창
```
Edit the attached image. Change three things only: 1) the witch's hand wears a black lace fingerless glove that covers the back of the hand up to the knuckles, her nails are short and natural, and her sleeve is sheer, smoky charcoal-black chiffon instead of the crimson and white cloth; 2) remove the moon, the clouds and the open sky: the two small figures stand on stone ledges in the darkness of a vast underground crypt, with faint stone arches in the gloom; 3) the small figure on the right is a woman with long hair and a cape. Keep the crimson thread and its path, the bending blade, the figure on the left, the composition and the art style the same.
```

### 60 용사의 죽음 (세라피나 죽음 카드)
- 1차 문제: 그림자가 기둥 두 개 달린 덩어리 모양이라 '위에서 내려오는 발'로 읽히지 않음. 대본 221행과 맞출지는 4장 결정과 함께.
- 원본: `vs_assets_rest.md` 「60 수정」 · 첨부: [`60_card_hero_death_v1.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/60_card_hero_death_v1.webp) · 카드 대화창
```
Edit the attached image. Change only the shadow: make it the clear, vast shadow of a single colossal bare foot hovering high above, cast straight down as the shape of its sole — one heel and exactly five toes — covering most of the floor, its edge just reaching the braid. Keep the braid, the crimson ribbon, the cracked stone floor, the petals, the composition and the art style exactly the same.
```

### 47 방패 강타
- 1차 문제: 갑옷이 은갈색, 맞는 적의 로브가 밝음
- 원본: `vs_assets_rest.md` 「47 수정」 · 첨부: [`47_card_shield_bash_v1.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/47_card_shield_bash_v1.webp) · 카드 대화창
```
Edit the attached image. Change only two things: 1) the armored shoulder and arm on the left become black plate armor, dark iron with fine silver filigree, matching the black shield; 2) the hooded figure being struck wears a tattered charcoal-gray hooded robe instead of the pale one, keeping the bandaged arm and the crimson threads. Keep the shield, the bouquet, the impact burst, the composition and the art style exactly the same.
```

### 50 저주의 불꽃
- 1차 문제: 손톱이 길고 뾰족함(09번 손·52번과 다름)
- 원본: `vs_assets_rest.md` 「50 수정」 · 첨부: [`50_card_curse_flame_v1.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/50_card_curse_flame_v1.webp) · 카드 대화창
```
Edit the attached image. Change only the fingernails: short, natural, rounded nails instead of long pointed claws. Keep the hand, the black lace glove, the crimson threads, the thorny crimson flame, the composition and the art style exactly the same.
```

### 48 저격 — 배경만
- 1차 문제: 뒤에 하늘·성당·바깥 폐허
- 원본: `vs_assets_rest.md` 「48 수정」 · 첨부: [`48_card_snipe_v1.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/48_card_snipe_v1.webp) · 카드 대화창
```
Edit the attached image. Change only the background: replace the sky, the clouds, the cathedral and the outdoor ruins with a dark underground crypt — massive stone arches, walls of bone-filled niches, a few hanging iron lanterns; no sky, no moon, no buildings. The torn crimson banners stay, hanging from the arches. Keep the bow, the arrow, the lace-gloved hands, the green cloak, the crimson ribbons, the composition and the art style exactly the same.
```

### 49 견제 사격 — 배경만
- 1차 문제: 뒤에 하늘·성당·바깥 폐허
- 원본: `vs_assets_rest.md` 「49 수정」 · 첨부: [`49_card_suppressing_fire_v1.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/49_card_suppressing_fire_v1.webp) · 카드 대화창
```
Edit the attached image. Change only the background behind the hooded figures: replace the sky, the cathedral and the outdoor ruins with a dark underground crypt — massive stone arches, walls of bone-filled niches, a few hanging iron lanterns; no sky, no moon, no buildings. The torn crimson banners stay, hanging from the arches. Keep the three arrows, the hooded figures, the burst of stone where the arrows strike, the composition and the art style exactly the same.
```

### 52 대신 받기 — 배경만
- 1차 문제: 뒤에 성당·바깥 폐허
- 원본: `vs_assets_rest.md` 「52 수정」 · 첨부: [`52_card_take_hit_v1.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/52_card_take_hit_v1.webp) · 카드 대화창
```
Edit the attached image. Change only the background: replace the sky, the clouds, the cathedral and the outdoor ruins with a dark underground crypt — massive stone arches, walls of bone-filled niches, a few hanging iron lanterns; no sky, no moon, no buildings. Keep the hand, the black lace glove, the crimson threads, the blade, the thin line of crimson, the sleeve, the composition and the art style exactly the same.
```

### 55 짓밟힘 (상속 카드)
- 1차 문제: 발가락 자국이 6개
- 원본: `vs_assets_rest.md` 「55 수정」 · 첨부: [`55_card_trampled_v1.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/55_card_trampled_v1.webp) · 카드 대화창
```
Edit the attached image. Change only the toes of the footprint: it must have exactly five toe prints — one big toe and four smaller toes, each smaller toward the outside — not six. Keep the shape of the sole, the cracked stone floor, the crimson ribbon, the dust, the composition and the art style exactly the same.
```

### 53 죽음의 예지 — 선택
- 1차 문제: 눈에 비친 장면에 붉은 달·첨탑(게임 카드 크기에서 약 12px). 그대로 써도 된다.
- 원본: `vs_assets_rest.md` 「53 수정 — 선택」 · 첨부: [`53_card_foresight_v1.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/53_card_foresight_v1.webp) · 카드 대화창
```
Edit the attached image. Change only the small scene reflected in the eye: replace the moon, the spires and the open sky with a dark underground hall of stone arches; keep the small lone figure and the crosses. Keep the eye, the hair, the hat, the cards, the hand, the composition and the art style exactly the same.
```

---

## 4. 사용자 결정 대기 (2026-11-22 기준)
| 무엇 | 지금 | 추천 | 정해지면 |
|---|---|---|---|
| **18 계단 앞 홀** | 계단이 위로 올라가는 모양 | 아래로 내려가게 고치기 | 아래 「18 수정」 → `18_bg_stair_landing.webp`(지금 것은 `_v1`로) → `--only bg` |
| **23 죽은 마녀 CG** | 머리가 은백(노엘은 와인빛) | 그대로(반전을 숨기기 좋음) | — |
| **60 ↔ 대본 221행** | 대본 "세라피나의 얼굴", 그림은 땋은 머리 + 거대한 그림자 | 대본을 "세라피나의 땋은 머리, 그 위를 덮은 거대한 그림자"로 | 대본 고침은 사용자 결정 뒤에만 |
| **67 이름표** | 그림 없음. VN 대화창 안에 이름을 붉은 글자로 씀 | 생략 | 쓰기로 하면 아래 「67」 |
| **배경 제거 도구** | `tools/remove_bg.py` 기본값(soft 150)이 몸 안쪽 중간색까지 반투명으로 만듦 | — | 고칠지 정한다. 그때까지 `vs_import.py` 가 `--soft 100` 으로 피함 |
| ~~**움직임 A′ / C** (밤샘 4)~~ — 2026-11-22 결정: A′ 기본, C 지움(부위 시트 다시 뽑기 없음) | `?anim=a`·`?anim=c` 시험만, 기본 화면 그대로 | — | C(또는 섞기)를 고르면 `04_seraphina_parts` 부위 시트를 **뒷모습 비율에 맞게 다시 뽑는다**(지금 조립하면 머리 약 1.34배·팔이 몸에 붙음·성검이 발 아래로 67px — `reference/trials/anim_c_fit.webp`). 다른 동료도 C로 하면 부위 시트를 새로 뽑는다(프롬프트 없음 — `vs_assets.md` P04를 바탕으로 새로 쓴다) |

### 18 계단 앞 홀 수정 — 결정되면
- 원본: 대화에서 준 수정 프롬프트(2026-11-21) · 첨부: [`18_bg_stair_landing.webp`](https://github.com/abback-go/yemo_plan/blob/cc/amazing-darwin-nesbwh/art/raw/vs/18_bg_stair_landing.webp) · 배경을 뽑던 대화창
```
Edit this image: keep the same room, camera, style and lighting. Change only the staircase: it is a wide spiral staircase that goes DOWN from this landing into the depths. Remove the steps rising upward; instead, the first steps start at the edge of the landing and wind downward around a dark open stairwell, with the faint crimson glow coming from far below. Keep the candles along the inner wall and the iron railing. Change nothing else.
```

### 67 이름표 — 쓰기로 하면
- 원본: `vs_assets_rest.md` 「67」 · 첨부: 기준 그림 · 66번 대화창 · 저장(제안) `67_ui_name_plate.webp`
```
Using the attached image only as a style reference, draw a game UI element: a small horizontal name plate, about 4:1, front view, flat: aged parchment with a thin ink-drawn thorn border of even thickness and a short crimson ribbon tied at the left end. The center is empty. No text, no letters. Background: plain flat pure green (#00FF00).
```

## 5. 원하면 (선택)
- 37 엘리안 놀람: 몸이 기본(36)과 3% 달라, 36을 바탕으로 다시 뽑을 수 있음(`vs_assets_rest.md` 「37~38」 첫 블록, 36번 그림 첨부).
- 브룬힐드 흉터: 확대하면 피눈물처럼 보임 — 거슬리면 수정.

## 6. 다음 할 일 (목록은 아직 없음)
- **2·3층 그림 목록·프롬프트**(브룬힐드·엘리안 데스신, 2층 카드 「전사의 죽음」 등) — 1층 그림을 마친 뒤 만든다. 지금 2·3층은 옛 그림을 쓴다.
- 브룬힐드 데스신(관통)은 그림체 D 시안 7장이 `reference/deathscene/brunhild_*` 에 있고, 통과한 구도·막힌 구도는 `docs/art-direction.md` 4장에 있다. 그때 준 프롬프트는 저장소에 없다(대화에서만 줌, 대부분 거절) — 통과 컷을 첨부해 새로 쓴다.
- 42 묘지기 상인은 26 CG에 들어 있어 뽑지 않았다(원본 「42」의 "26번 CG에 이미 있으면 생략").

## 그림체 F 진행 (2026-11-22~)
- 기준: `docs/art-direction.md` 1-0장. 원본은 `art/raw/vs_f/`. 동료는 **첨부 두 장**(그림체 `reference/style/style_F_seraphina_stand.webp` + 예전 얼굴 `art/raw/vs/<번호>_stand_*.webp`).
- 통과: 28 세라피나 기본 · 36 엘리안 기본 · 39 노엘 기본(불투명 천 — 예전 초록 물듦 문제 해결) · 75 전투 돌판 탁자 v2(어둡고 잔혹하게 다시 — 피 얼룩·긁힌 자국·녹슨 못·사슬·붉은 실, 1차는 `_v1`) · 76 카드 틀 3종(동료·노엘 카드 / 적·적 행동 / 하수인, 한 장에 나란히) — **다시 뽑는 중**(더 어둡고 공포스럽게, 사용자 지시).
- 임시 통과(고칠 것 남음): 32 브룬힐드 — 오른쪽 눈 밑 흉터가 **빨간 선**(피눈물처럼 보임) → 회색으로. 프롬프트: "Change only the scar under her right eye: keep its shape as one thin straight line, but draw it in pale light-gray ink instead of red." (같은 대화창). 갑옷 무늬가 세라피나보다 촘촘함(선택).
- 행동 카드 그림(베기·막기·겨누기 등)은 **당분간 예전 그림체 D 카드 그림(44~60)을 재활용**(사용자 결정 2026-11-22). 그림체 F로 다시 뽑는 것은 나중에.
