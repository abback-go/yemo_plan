"""공통 시스템 — 학교의 마법 수업 방과 1장 학교 방에 덧붙이는 개체 (docs/magic.md 4절, docs/systems2.md).
roomgen.py가 불러온다. 학교 지도 칸: 1장이 x 0~7, y 0~5 일부를 씀 → 빈 칸에 둔다.
  s_windtower (0,3) 1x3 · s_ashstacks (1,4) 2x2 · s_phoenix (3,4) 1x1 · s_duel (3,5) 2x1 · s_observatory (6,-1) 1x1
"""
from roomgen import Room, room, overlay, windows, school_room  # noqa: F401

# ─── 1장 방에 덧붙임 (지형은 그대로) ─────────────────────

# 중앙 홀: 수업 게시판 (2장부터)
overlay("s_hall", "class_board", id="board", x=27, y=42, cond="ch1_done")
overlay("s_hall", "trigger", id="board_tg", x=20, y=36, w=14, h=7, run="sys_board_intro", cond="ch1_done,!sys_board_seen")
# 앞마당: 전이진 + 도착 위치
overlay("s_courtyard", "warp", id="warp_circle", x=24, y=19, area="school", cond="ch1_done")
overlay("s_courtyard", "spawn", id="warp", x=24, y=19, face="right")
# 부양 실습실 왼쪽 끝: 바람의 탑 문 (불꽃 날개 수업)
overlay("s_levcourse", "door", id="tower", x=3, y=19, to="s_windtower", to_id="in", style="iron", label="바람의 탑",
        cond="cls_wings_open")
# 실습장: 불꽃 방벽 수업 — 마력탄 발사대 셋, 각 발사대 앞에 되쏜 탄으로만 켜지는 과녁
for i, (tx, ty, gx, ph) in enumerate(((3, 19, 5, 0.0), (36, 13, 34, 0.9), (64, 19, 62, 1.8))):
    overlay("s_training", "orb_turret", id="ot%d" % i, x=tx, y=ty, period=3.0, phase=ph,
            on_if="ward_trial_on,!ward_targets", cond="ch1_done")
    overlay("s_training", "reflect_target", id="rt%d" % i, x=gx, y=ty, group="ward", done_flag="ward_targets",
            cond="ch1_done,!ward_targets")
overlay("s_training", "event", id="ward_ev", flag="ward_targets", run="cls_ward_targets_done", done="cls_ward_targets_seen")
# 고급마법반: 결투장 계단 (유성 낙화 수업)
overlay("s_advclass", "door", id="duel", x=46, y=19, to="s_duel", to_id="in", style="stair_down", label="결투장",
        lock="cls_meteor_duel_ok", lock_msg="결투장. 베로니카 교수의 허락 없이는 내려갈 수 없다.", cond="q_cls_meteor")
# 시계탑 꼭대기: 지붕 별 관측대 (유성 낙화 수업)
overlay("s_clock", "door", id="roof", x=12, y=12, to="s_observatory", to_id="down", style="stair_up", label="지붕 — 별 관측대",
        cond="cls_meteor_roof")
# 금서 구역: 재의 서고 (불사조 수업)
overlay("s_archive", "door", id="ash", x=23, y=19, to="s_ashstacks", to_id="in", style="iron", label="재의 서고",
        cond="cls_phoenix_sign")


tower_room = school_room  # 수업 방도 학교 지역의 사방 막힌 방 (1장 학교 방과 같은 상자)


# ═══════════════════════════════════════════════════════════
# 불꽃 날개 — 바람의 탑 (오필리아)
# ═══════════════════════════════════════════════════════════

@room
def s_windtower():
    r = tower_room("s_windtower", "마녀학교 · 바람의 탑", "windtower", "school", (0, 3), (1, 3))
    F = r.h - 4  # 65
    r.door("in", 4, F, "s_levcourse", "tower", style="iron", label="부양 실습실")
    r.add("save", id="candle", x=10, y=F, style="candle")
    # ① 바닥 → 바람 기둥 1 → 오른쪽 턱 A
    r.add("updraft", id="u1", x=16, y=40, w=3, h=25, style="wind", power=1.0)
    r.fill(22, 41, 31, 42)
    # ② 턱 A 오른쪽 끝 → 바람 기둥 2(오른쪽 벽 곁) → 왼쪽 턱 B로 길게 활공
    r.add("updraft", id="u2", x=33, y=16, w=3, h=29, style="wind", power=1.0)
    r.plat(37, 38, 31)
    r.add("pickup", id="stone_tower", kind="stone", x=37, y=31, name="마도석", text="바람에 실려 온 보라 결정.")
    r.plat(26, 30, 17)  # 기둥 2 꼭대기 옆 쉼터
    r.fill(5, 22, 15, 23)
    # ③ 턱 B 왼쪽 끝 → 바람 기둥 3 → 꼭대기 층
    r.add("updraft", id="u3", x=2, y=3, w=3, h=19, style="wind", power=1.0)
    r.fill(9, 8, 30, 9)
    r.add("spawn", id="top", x=20, y=8, face="right")
    # 떠 있는 등불 다섯 (모두 밝히면 꼭대기 종이 울림)
    lanterns = ((17, 50), (38, 22), (10, 16), (6, 6), (35, 6))
    for i, (x, y) in enumerate(lanterns):
        r.add("float_lantern", id="wl%d" % i, group="wind", x=x, y=y, done_flag="windtower_done")
    r.add("event", id="ev", flag="windtower_done", run="cls_wings_tower_done", done="cls_wings_tower_seen")
    # 소품
    r.add("prop", kind="magic_circle", x=17, y=F, w=8, col="#b8a8ff")
    r.add("prop", kind="bell", x=20, y=3)
    for x, y, h in ((8, 2, 5), (32, 2, 5)):
        r.add("prop", kind="chain", x=x, y=y, h=h)
    for x, y in ((6, F - 9), (26, F - 12), (12, 34), (24, 12)):
        r.add("prop", kind="window", x=x, y=y, w=3, h=6)
    for x, y, c in ((26, 43, "#5a4a8a"), (12, 24, "#8a5a7a")):
        r.add("prop", kind="banner", x=x, y=y, h=6, col=c)
    r.add("sign", x=27, y=F, look="board",
          text="바람의 탑|날개를 펴고(공중에서 점프를 길게) 바람을 타렴~|등불 다섯 개를 모두 밝히면 꼭대기 종이 울린단다. 떨어져도 바람이 받아 줄 거야~ (아마도) — 오필리아")
    return r


# ═══════════════════════════════════════════════════════════
# 유성 낙화 — 시계탑 지붕 별 관측대 · 결투장 (오필리아 · 베로니카)
# ═══════════════════════════════════════════════════════════

@room
def s_observatory():
    r = Room("s_observatory", "마녀학교 · 시계탑 지붕", "school", "observatory", "school", (6, -1), (1, 1))
    F = 19
    r.ground(F)
    r.fill(0, 0, 0, F - 1)
    r.fill(r.w - 1, 0, r.w - 1, F - 1)
    r.door("down", 4, F, "s_clock", "roof", style="stair_down", label="시계탑")
    # 굴뚝과 지붕 마루 (별을 쏠 높이를 만드는 발판)
    r.fill(10, 15, 12, F - 1)
    r.fill(27, 14, 29, F - 1)
    r.plat(16, 22, 12)
    r.plat(32, 37, 10)
    r.plat(3, 7, 12)
    # 거문고자리 (리라) — 가장 밝은 별 베가부터
    stars = ((5, 6), (13, 4), (19, 7), (24, 3), (30, 5), (35, 2), (36, 13))
    for i, (x, y) in enumerate(stars):
        r.add("star_point", id="st%d" % i, group="lyra", x=x, y=y, order=i, count=len(stars), done_flag="stars_done",
              cond="q_cls_meteor")
    r.add("event", id="ev", flag="stars_done", run="cls_meteor_stars_done", done="cls_meteor_stars_seen")
    r.add("npc", id="ophelia", who="ophelia", x=20, y=F, face="left", cond="cls_meteor_roof,!stars_done")
    r.add("prop", kind="globe", x=22, y=F)
    r.add("prop", kind="magic_circle", x=20, y=F, w=8, col="#ffe39a")
    r.add("prop", kind="candles", x=8, y=F)
    r.add("sign", x=34, y=F, look="board",
          text="별 관측대|별자리는 정해진 순서로 이어야 빛난다.|가장 밝은 별에서 시작할 것. — 시계탑 관리인")
    return r


@room
def s_duel():
    r = tower_room("s_duel", "마녀학교 · 결투장", "duel", "school", (3, 5), (2, 1))
    F = 19
    r.door("in", 4, F, "s_advclass", "duel", style="stair_up", label="고급마법반")
    r.plat(12, 18, 15)
    r.plat(61, 67, 15)
    r.plat(36, 43, 12)
    r.add("save", id="candle", x=8, y=F, style="candle")
    r.add("control_trial", id="ctrl", x=40, y=F, need=20.0, done_flag="control_done", on_if="control_on")
    r.add("event", id="ev", flag="control_done", run="cls_meteor_control_done", done="cls_meteor_control_seen")
    for i, (x, y) in enumerate(((24, F), (40, 12), (56, F))):
        r.add("target", id="ct%d" % i, group="ctl", x=x, y=y, dx=0, period=2.0, hold=1.0, cond="control_on,!control_done")
    r.add("npc", id="veronica", who="veronica", x=70, y=F, face="left", cond="cls_meteor_duel_ok,!ab_meteor")
    r.add("prop", kind="magic_circle", x=40, y=F, w=14, col="#b67aff")
    for x in (20, 60):
        r.add("prop", kind="pillar", x=x, y=F, h=14)
    for x in (30, 50):
        r.add("prop", kind="banner", x=x, y=2, h=6, col="#2a1a3a")
    r.add("prop", kind="chandelier", x=40, y=2, len=3)
    r.add("sign", x=74, y=F, look="board",
          text="결투장|고급마법반 이상만 사용할 수 있다.|결투 중 생긴 화상·동상·그림자 자국은 각자 의무실로. — 베로니카 손")
    return r


# ═══════════════════════════════════════════════════════════
# 불사조 — 재의 서고 · 불사조의 둥지 (그레타 · 아스트리드)
# ═══════════════════════════════════════════════════════════

@room
def s_ashstacks():
    r = tower_room("s_ashstacks", "마녀학교 · 재의 서고", "ash", "school", (1, 4), (2, 2), dark=0.35)
    FB = r.h - 4  # 42
    r.door("in", 4, FB, "s_archive", "ash", style="iron", label="금서 구역")
    r.add("spawn", id="start", x=7, y=FB, face="right")
    r.add("ash_trial", id="trial", light=9.0, start="start", done_flag="ash_done")
    # 층: 바닥 42 → 32 → 22 → 12 (층 사이 빈 곳은 번갈아 오른쪽·왼쪽)
    r.fill(1, 32, 66, 33)
    r.fill(13, 22, 78, 23)
    r.fill(1, 12, 66, 13)
    # 층 사이 디딤 발판
    r.plat(70, 75, 37)
    r.plat(4, 9, 27)
    r.plat(70, 75, 17)
    # 그을린 책장 덩어리 (뛰어넘기·밑으로 지나기)
    r.fill(30, 38, 34, 41)
    r.fill(46, 39, 50, 41)
    r.fill(40, 24, 44, 28)
    r.fill(22, 29, 25, 31)
    r.fill(36, 18, 39, 21)
    r.fill(54, 19, 57, 21)
    r.fill(28, 3, 31, 7)
    r.fill(46, 8, 49, 11)
    # 막다른 갈래 (왼쪽 끝 2층: 기록 쪽지 / 4층 오른쪽 위: 마도석)
    r.add("pickup", id="ash_note", kind="note", x=3, y=32, name="그을린 쪽지",
          text="'불사조는 죽지 않는다. 다만 제 재 속에서, 자기 자신을 이겨야만 다시 날아오른다.' — 창립자의 필체")
    r.plat(60, 64, 6)
    r.add("pickup", id="stone_ash", kind="stone", x=62, y=6, name="마도석", text="재 속에서도 식지 않은 결정.")
    # 촛불: 화염탄으로 켜면 남은 시간이 다시 찬다. 마지막 촛불 = 둥지 문
    candles = ((20, FB), (72, 37), (52, 32), (16, 32), (6, 27), (30, 22), (62, 22), (72, 17), (40, 12))
    for i, (x, y) in enumerate(candles):
        r.add("ash_candle", id="c%d" % i, x=x, y=y)
    r.add("ash_candle", id="c_last", x=10, y=12, last=True)
    r.add("event", id="ev", flag="ash_done", run="cls_phoenix_ash_done", done="cls_phoenix_ash_seen")
    r.door("nest", 4, 12, "s_phoenix", "in", style="grand", label="불사조의 둥지", lock="ash_done",
           lock_msg="재로 덮인 문. 마지막 촛불이 꺼져 있다.")
    for x, y in ((14, FB), (58, FB), (24, 32), (60, 12)):
        r.add("prop", kind="bookshelf", x=x, y=y, w=4, h=8)
    for x, y, h in ((20, 2, 6), (66, 24, 6)):
        r.add("prop", kind="chain", x=x, y=y, h=h)
    r.add("prop", kind="debris", x=40, y=FB, w=6)
    r.add("sign", x=12, y=FB, look="board",
          text="재의 서고|이곳의 어둠은 빛을 먹는다.|촛불이 꺼지기 전에 다음 촛불을 밝힐 것. 꺼지면 재가 길을 지운다. — 그레타 잉크웰")
    return r


@room
def s_phoenix():
    r = tower_room("s_phoenix", "마녀학교 · 불사조의 둥지", "ash", "school", (3, 4), (1, 1), dark=0.15)
    F = 19
    r.door("in", 3, F, "s_ashstacks", "nest", style="grand", label="재의 서고")
    r.plat(6, 11, 14)
    r.plat(28, 33, 14)
    r.plat(16, 24, 10)
    r.add("phoenix_egg", id="egg", x=20, y=F, cond="q_cls_phoenix,!egg_done")
    r.add("prop", kind="magic_circle", x=20, y=F, w=10, col="#ff8a3a")
    r.add("prop", kind="altar", x=20, y=F)
    for x in (7, 33):
        r.add("prop", kind="candles", x=x, y=F)
    r.add("light", x=20, y=F - 3, r=6, color="#ff9a4a")
    return r
