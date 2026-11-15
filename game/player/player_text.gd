class_name PlayerText
extends RefCounted
## 세라·너울이 전투 중에 띄우는 문구 (토스트·배너·말풍선). 대사를 고칠 때는 여기만 보면 된다.
## 대본(story/) 대사는 여기에 두지 않는다.

# ─── 토스트 (Story.toast) ───
const NOT_LEARNED := "아직 배우지 않은 마법이다."
const EQUIP_ULT_HINT := "마법서(일시정지 → 마법서)에서 F 칸에 고급 마법을 끼우자."
const NO_POTION := "물약이 없다. 기록 지점에서 다시 채워진다."
const HP_FULL := "체력이 가득하다."
const REVIVE := "부활의 불꽃!"
## 피피 물약(pippa_potion 플래그)을 마셨을 때 하나를 고른다 (randi — 순서를 바꾸면 고르는 줄이 바뀜)
const PIPPA_POTION := ["…딸기 맛? 아니, 이건 양말 맛이야.", "쓰다! 그래도 힘이 난다.", "피피, 대체 뭘 넣은 거야…", "어, 의외로 맛있어.", "혀가 파래졌을 것 같아."]

# ─── 배너 (HUD.banner) ───
const BANNER_OVERHEAT := "과열! 화염탄 강화"
const BANNER_WITCH_TIME := "위치 타임!"
const BANNER_FOX_MODE := "빙의 — 여우 모드"

# ─── 스타일 점수 ───
const STYLE_WITCH_TIME := "위치 타임!"

# ─── 너울 말풍선 ───
## 여우 모드가 끝나고 떨어져 나올 때 (60% 확률로 하나)
const NEOUL_FOX_END := ["…후우. 꼬리 하나로는 이 정도니라.", "다음엔 좀 더 아껴 쓰거라.", "배고프다. 기운을 썼더니.", "흥, 이 정도야 껌이니라."]
