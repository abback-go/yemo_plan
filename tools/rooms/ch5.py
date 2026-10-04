"""5장 방 (docs/chapter5.md). roomgen.py가 불러온다.
from roomgen import Room, room, overlay — 1장 roomgen.py와 같은 문법.

1단계(에셋·설계): 시험장 dev_st_* 만 있다 (ROOMS 목록에 넣지 않음, 지도 영역 "dev").
  dev_st_tower   별의 탑 꼭대기 (리라 결전장, star 테마)
  dev_st_ruin    무너진 학교 (ruin_school, 소품 진열 + 별 구조체·사도 시험)
  dev_st_ruin_k  무너진 황도 (ruin_kingdom)
  dev_st_ruin_e  불타는 세계수 (ruin_elf)
  dev_st_ruin_tp 금 간 대신전 (ruin_temple)
  dev_st_march   절망: 거신의 행진 속을 도망 (ruin_school, 3칸)
  dev_st_sky     하늘의 문 (sky, 최종전장)
  dev_st_void    어둠 (void, 아홉 꼬리 각성)
  dev_st_ride    반격: 거신 위를 달리기 (rise, 3칸)
  dev_st_fest    축제 저녁 (festival, 축제 소품 진열)
2단계에서 st_*·r5_* 실제 방과 다른 장 방 overlay를 이 파일에 더한다.
"""
from roomgen import Room, room, overlay, boxed_room, hanging_row  # noqa: F401

F = 19  # 바닥 윗면 행 (1칸 방 기준)


def _arena(r, ceil=0):
    r.box(wall=1, floor=r.h - F, ceil=ceil)


@room
def dev_st_tower():
    r = Room("dev_st_tower", "시험장 · 별의 탑 꼭대기", "dev", "star", "lyra", (0, 0), (1, 1))
    _arena(r)
    r.plat(4, 10, F - 5)
    r.plat(29, 35, F - 5)
    r.plat(15, 24, F - 9)
    r.add("spawn", id="start", x=6, y=F, face="right")
    r.add("spawn", id="mid", x=20, y=F, face="right")
    r.add("spawn", id="boss", x=30, y=F)
    r.add("prop", kind="st_const_pedestal", x=3, y=F)
    r.add("prop", kind="st_const_pedestal", x=36, y=F, flip=True)
    r.add("prop", kind="st_star_lantern", x=13, y=1, len=3)
    r.add("prop", kind="st_star_lantern", x=26, y=1, len=4)
    return r


@room
def dev_st_ruin():
    r = Room("dev_st_ruin", "시험장 · 무너진 학교", "dev", "ruin_school", "despair", (0, 0), (2, 1))
    _arena(r)
    r.fill(30, F - 3, 37, F - 1)
    r.fill(55, F - 2, 58, F - 1)
    r.plat(44, 50, F - 5)
    r.plat(62, 70, F - 6)
    r.add("spawn", id="start", x=4, y=F, face="right")
    r.add("spawn", id="mid", x=40, y=F, face="right")
    r.add("spawn", id="e1", x=48, y=F)
    r.add("spawn", id="e2", x=68, y=F)
    r.add("prop", kind="st_rubble", x=8, y=F, w=4)
    r.add("prop", kind="st_burning_beam", x=14, y=F, w=5)
    r.add("prop", kind="st_broken_bell", x=21, y=F)
    r.add("prop", kind="st_cracked_statue", x=26, y=F)
    r.add("prop", kind="st_fire", x=33, y=F - 3)
    r.add("prop", kind="st_broken_pillar", x=41, y=F, h=6)
    r.add("prop", kind="st_white_growth", x=53, y=F)
    r.add("prop", kind="st_fallen_banner", x=60, y=F)
    r.add("prop", kind="st_comm_crystal", x=65, y=F)
    r.add("prop", kind="st_crater", x=74, y=F, w=4)
    return r


@room
def dev_st_ruin_k():
    r = Room("dev_st_ruin_k", "시험장 · 무너진 황도", "dev", "ruin_kingdom", "despair", (1, 0), (1, 1))
    _arena(r)
    r.plat(24, 31, F - 5)
    r.add("spawn", id="start", x=4, y=F, face="right")
    r.add("prop", kind="st_rubble", x=10, y=F, w=5)
    r.add("prop", kind="st_burning_beam", x=18, y=F, w=4)
    r.add("prop", kind="st_fire", x=33, y=F)
    return r


@room
def dev_st_ruin_e():
    r = Room("dev_st_ruin_e", "시험장 · 불타는 세계수", "dev", "ruin_elf", "despair", (2, 0), (1, 1))
    _arena(r)
    r.plat(24, 31, F - 5)
    r.add("spawn", id="start", x=4, y=F, face="right")
    r.add("prop", kind="st_ash_tree", x=12, y=F)
    r.add("prop", kind="st_fire", x=20, y=F)
    r.add("prop", kind="st_rubble", x=33, y=F, w=4)
    return r


@room
def dev_st_ruin_tp():
    r = Room("dev_st_ruin_tp", "시험장 · 금 간 대신전", "dev", "ruin_temple", "despair", (3, 0), (1, 1))
    _arena(r)
    r.plat(24, 31, F - 5)
    r.add("spawn", id="start", x=4, y=F, face="right")
    r.add("prop", kind="st_broken_pillar", x=10, y=F, h=7)
    r.add("prop", kind="st_broken_bell", x=18, y=F)
    r.add("prop", kind="st_cracked_statue", x=33, y=F)
    return r


@room
def dev_st_march():
    r = Room("dev_st_march", "시험장 · 거신의 행진", "dev", "ruin_school", "despair", (0, 1), (3, 1))
    _arena(r)
    r.fill(40, F - 2, 44, F - 1)
    r.fill(80, F - 3, 86, F - 1)
    r.plat(60, 66, F - 5)
    r.add("spawn", id="start", x=4, y=F, face="right")
    r.add("spawn", id="mid", x=60, y=F, face="right")
    r.add("st_quake", x=0, y=0)
    r.add("prop", kind="st_rubble", x=20, y=F, w=4)
    r.add("prop", kind="st_burning_beam", x=52, y=F, w=4)
    r.add("prop", kind="st_fire", x=72, y=F)
    r.add("prop", kind="st_rubble", x=100, y=F, w=5)
    return r


@room
def dev_st_sky():
    r = Room("dev_st_sky", "시험장 · 하늘의 문", "dev", "sky", "final", (1, 1), (1, 1))
    r.fill(0, F, r.w - 1, r.h - 1)
    r.fill(0, 0, 0, r.h - 1)
    r.fill(r.w - 1, 0, r.w - 1, r.h - 1)
    # 떠 있는 땅 조각 (바닥은 구름 위 부서진 다리)
    r.plat(3, 9, F - 4)
    r.plat(30, 36, F - 4)
    r.plat(12, 17, F - 8)
    r.plat(22, 27, F - 8)
    r.plat(17, 22, F - 12)
    r.add("spawn", id="start", x=6, y=F, face="right")
    r.add("spawn", id="mid", x=20, y=F, face="right")
    r.add("spawn", id="gate", x=20, y=F - 9)
    return r


@room
def dev_st_void():
    r = Room("dev_st_void", "시험장 · 어둠", "dev", "void", "nine_tails", (2, 1), (1, 1))
    _arena(r)
    r.add("spawn", id="start", x=12, y=F, face="right")
    r.add("st_awaken", id="neoul_god", who="neoul_god", x=24, y=F, face="left", tails=4)
    return r


@room
def dev_st_ride():
    # 3×2칸: 왼쪽 무너진 탑 꼭대기에서 출발 → 거신 셋의 손·팔·어깨·머리를 밟고 → 오른쪽 탑으로
    r = Room("dev_st_ride", "시험장 · 거신 위를 달려", "dev", "rise", "final", (0, 2), (3, 2))
    G = r.h - 2  # 바닥 윗면 행 (안전용 바닥)
    r.fill(0, G, r.w - 1, r.h - 1)
    r.fill(0, 0, 0, r.h - 1)
    r.fill(r.w - 1, 0, r.w - 1, r.h - 1)
    r.fill(1, 22, 14, G)          # 출발 탑
    r.fill(108, 17, 118, G)       # 도착 탑
    r.add("spawn", id="start", x=8, y=22, face="right")
    r.add("spawn", id="low", x=30, y=G, face="right")
    r.add("st_colossus_ride", id="c1", x=40, y=G, h=34, dir="left", speed=0.35, travel=8)
    r.add("st_colossus_ride", id="c2", x=64, y=G, h=34, dir="left", speed=0.3, phase=0.5, travel=8)
    r.add("st_colossus_ride", id="c3", x=88, y=G, h=34, dir="left", speed=0.3, phase=0.25, travel=8)
    return r


@room
def dev_st_fest():
    r = Room("dev_st_fest", "시험장 · 축제 저녁", "dev", "festival", "festival", (3, 1), (2, 1))
    _arena(r)
    r.plat(36, 44, F - 5)
    r.add("spawn", id="start", x=4, y=F, face="right")
    r.add("prop", kind="st_festival_stall", x=10, y=F, style="potion")
    r.add("prop", kind="st_festival_stall", x=22, y=F, style="food")
    r.add("prop", kind="st_festival_stall", x=34, y=F, style="star")
    r.add("prop", kind="st_lantern_string", x=6, y=4, w=12, sag=2)
    r.add("prop", kind="st_lantern_string", x=18, y=3, w=14, sag=3)
    r.add("prop", kind="st_garland", x=46, y=5, w=10)
    r.add("prop", kind="st_festival_banner", x=50, y=F, h=6)
    r.add("prop", kind="st_balloon_cluster", x=56, y=F)
    r.add("prop", kind="st_flower_arch", x=64, y=F)
    r.add("prop", kind="st_star_lantern", x=72, y=1, len=4)
    r.add("prop", kind="st_tea_table", x=74, y=F)
    return r


# ═══════════════════════════════════════════════════════════
# 2단계: 실제 방 (docs/chapter5.md 3절 · 8절)
# ═══════════════════════════════════════════════════════════
# 플래그 흐름: st_fest(축제) → st_fest_ready(교장의 사진) → st_lyra_came(리라 방문) → st_key_k·e·tp·s(별의 열쇠)
#   → st_tower_open → st_lyra_beaten → st_truth → st_invaded(침공) → st_escort(학생 데려가기) → st_fallen(쓰러짐)
#   → st_void_done(아홉 꼬리) → st_rise → st_colossus_done → st_launch → st_gate_done → st_epilogue → ch5_done
FEST = "st_fest,!st_invaded"          # 축제 장식 (침공 전까지)
FEST_DAY = "st_fest,!st_lyra_came"    # 축제 낮 인물
AFTER_LYRA = "st_lyra_came,!st_invaded"
EPI = "st_epilogue"                   # 에필로그·엔딩 뒤
KEYS = "st_key_k,st_key_e,st_key_tp,st_key_s"


def out_room(rid, title, area, theme, music, cell, cells, dark=0.0, floor=F):
    """바깥 방: 바닥 + 양옆 벽, 위는 하늘"""
    r = Room(rid, title, area, theme, music, cell, cells, dark)
    r.ground(floor if cells[1] == 1 else r.h - 4)
    r.fill(0, 0, 0, r.h - 1)
    r.fill(r.w - 1, 0, r.w - 1, r.h - 1)
    return r


def in_room(rid, title, area, theme, music, cell, cells, dark=0.0, ceil=1, floor=4):
    return boxed_room(rid, title, area, theme, music, cell, cells, dark, ceil, floor)


def star_door(r, eid, x, y, to, to_id, label, col="tower", open_if="", done_if="", lock="", lock_msg="", cond=""):
    """별의 문: 그림은 소품(st_star_door), 드나들기는 문 개체(style="st" — 그림 없음)"""
    d = dict(t="door", id=eid, x=x, y=y, to=to, to_id=to_id, style="st", label=label)
    if lock:
        d["lock"] = lock
        d["lock_msg"] = lock_msg
    if cond:
        d["cond"] = cond
    r.ents.append(d)
    p = dict(t="prop", kind="st_star_door", x=x, y=y, col=col, open_if=open_if or lock)
    if done_if:
        p["done_if"] = done_if
    if cond:
        p["cond"] = cond
    r.ents.append(p)


def memory(r, n, x, y):
    """리라의 기억 조각 n (1~7): 수정 소품 + ↑로 들여다보면 기억 대본 st_mem_n (본 뒤엔 수정이 밝게 남음)"""
    r.add("prop", kind="st_memory_crystal", x=x, y=y, seen="st_mem_%d" % n)
    r.add("sign", id="mem%d" % n, x=x, y=y, look="none", prompt="기억 조각 — 들여다보기", run="st_mem_%d" % n)


def lanterns(r, xs, y=1, ln=3):
    hanging_row(r, "st_star_lantern", xs, y, ln, 2)


def stars(r, group, pts, done_flag, cond=""):
    """별자리 별 (sys star_point): 순서대로 화염탄으로 밝힘"""
    for i, (x, y) in enumerate(pts):
        e = dict(t="star_point", id="%s%d" % (group, i), group=group, x=x, y=y, order=i, count=len(pts), done_flag=done_flag)
        if cond:
            e["cond"] = cond
        r.ents.append(e)


# ─── 1장 학교 방 덧붙임: 축제 (5장) ─────────────────────

# 앞마당: 축제 광장 문 · 별의 문(리라 방문 뒤) · 장식 · 다시 세우는 앞마당 문(에필로그)
overlay("s_courtyard", "prop", kind="st_flower_arch", x=76, y=19, cond="st_fest")
overlay("s_courtyard", "door", id="festival", x=76, y=19, to="st_festival", to_id="yard", style="grand", label="축제 광장", cond="st_fest")
overlay("s_courtyard", "door", id="star", x=62, y=19, to="st_crossroads", to_id="yard", style="st", label="별의 문 — 별의 탑", cond=AFTER_LYRA)
overlay("s_courtyard", "prop", kind="st_star_door", x=62, y=19, col="tower", open_if="st_lyra_came", cond=AFTER_LYRA)
overlay("s_courtyard", "door", id="rebuild", x=4, y=19, to="st_rebuild", to_id="yard", style="wood", label="공사 중인 안뜰", cond=EPI)
for x, y, w, sag in ((2, 3, 14, 2), (18, 2, 14, 3), (48, 2, 14, 3), (64, 3, 14, 2)):
    overlay("s_courtyard", "prop", kind="st_lantern_string", x=x, y=y, w=w, sag=sag, cond=FEST)
overlay("s_courtyard", "prop", kind="st_garland", x=33, y=11, w=15, cond=FEST)
for x in (14, 66):
    overlay("s_courtyard", "prop", kind="st_festival_banner", x=x, y=19, h=6, cond=FEST)
overlay("s_courtyard", "prop", kind="st_balloon_cluster", x=57, y=19, cond=FEST)
overlay("s_courtyard", "npc", id="stu5", who="student_a", x=22, y=19, face="right", talk="npc_st_yard_a", cond=FEST_DAY)
overlay("s_courtyard", "npc", id="hodu5", who="hodu", x=46, y=19, face="left", cond=FEST_DAY)
overlay("s_courtyard", "trigger", id="st_yard", x=36, y=12, w=10, h=8, run="st_yard_first", cond=FEST_DAY)
# 에필로그: 공사 소품
overlay("s_courtyard", "prop", kind="st_scaffold", x=36, y=16, w=10, h=8, cond=EPI)

# 중앙 홀: 축제 장식 + 동상 앞 인물
overlay("s_hall", "prop", kind="st_garland", x=28, y=24, w=24, cond=FEST)
for x in (22, 58):
    overlay("s_hall", "prop", kind="st_festival_banner", x=x, y=42, h=7, cond=FEST)
# 식당: 요리 대회 (버터워스는 원래 자리) / 연금술실: 피피는 축제 광장의 가게에
overlay("s_cafeteria", "prop", kind="st_garland", x=4, y=6, w=30, cond=FEST)
overlay("s_cafeteria", "pickup", id="st_ing_honey", kind="key", x=36, y=19, name="별사탕 꿀", flag="st_ing_honey",
        text="축제용 별사탕 꿀 한 병. 피피의 물약 재료다.", cond="q_st_pippa_stall")
# 유리 온실 · 시계탑: 피피의 축제 물약 재료
overlay("s_greenhouse", "pickup", id="st_ing_moss", kind="key", x=31, y=14, name="반딧불 이끼", flag="st_ing_moss",
        text="밤마다 빛나는 이끼. 피피의 물약 재료다.", cond="q_st_pippa_stall")
overlay("s_clock", "pickup", id="st_ing_dew", kind="key", x=4, y=30, name="시계탑 이슬", flag="st_ing_dew",
        text="자정에 맺힌다는 시계탑 이슬. 피피의 물약 재료다.", cond="q_st_pippa_stall")
# 교장실: 창립자의 사진 (축제 낮, 한 번) / 에필로그 뒤 기억 조각을 다시 보는 사진첩 · 엔딩 사진
overlay("s_headmaster", "prop", kind="st_photo_frame", x=12, y=14)
overlay("s_headmaster", "trigger", id="st_photo", x=4, y=13, w=10, h=7, run="st_photo_scene", cond="st_fest,!st_fest_ready")
overlay("s_headmaster", "sign", id="st_album", x=16, y=19, look="book", prompt="기억의 사진첩 보기", cond="ch5_done", run="st_mem_album")
overlay("s_headmaster", "prop", kind="st_tea_table", x=33, y=19, cond="ch5_done")
overlay("s_headmaster", "npc", id="lyra5", who="lyra", x=35, y=19, face="left", cond="ch5_done")


# ═══════════════════════════════════════════════════════════
# 축제 광장 (학교 영역)
# ═══════════════════════════════════════════════════════════

@room
def st_festival():
    r = out_room("st_festival", "마녀학교 · 축제 광장", "school", "festival", "festival", (8, 3), (3, 1))
    # 무대 (가운데)와 별 관측대(오른쪽 비계)
    r.fill(54, F - 3, 70, F - 1)
    r.plat(50, 53, F - 2)
    r.plat(98, 103, 15)
    r.plat(104, 114, 11)
    r.door("yard", 4, F, "s_courtyard", "festival", style="grand", label="앞마당")
    r.add("save", id="fest", x=9, y=F, style="candle")
    r.add("spawn", id="stage", x=62, y=F - 3, face="left")
    r.add("spawn", id="evening", x=44, y=F, face="right")
    r.add("spawn", id="deck", x=106, y=11, face="right")
    # 가게: 피피(물약) · 레오니(제국 소시지) · 엘라리엔(엘프 꿀빵) · 가면 · 아우렐리아(성찬 빵) · 버터워스(요리 대회 심사)
    for x, style in ((16, "potion"), (28, "kingdom"), (40, "elf"), (46, "mask"), (80, "temple"), (91, "food")):
        r.add("prop", kind="st_festival_stall", x=x, y=F, style=style)
    r.add("npc", id="pippa", who="pippa", x=19, y=F, face="left", cond=FEST_DAY)
    r.add("npc", id="leonie", who="leonie", x=31, y=F, face="left", cond=FEST_DAY)
    r.add("npc", id="elarien", who="elarien", x=43, y=F, face="left", cond=FEST_DAY)
    r.add("npc", id="aurelia", who="aurelia", x=83, y=F, face="left", cond=FEST_DAY)
    r.add("npc", id="butterworth", who="butterworth", x=94, y=F, face="left", cond=FEST_DAY)
    r.add("npc", id="isolde", who="isolde", x=60, y=F - 3, face="right", cond=FEST_DAY)
    r.add("npc", id="emberlyn", who="emberlyn", x=68, y=F - 3, face="left", cond=FEST_DAY)
    r.add("npc", id="mirabel", who="mirabel", x=100, y=F, face="left", cond=FEST_DAY)
    r.add("npc", id="ophelia", who="ophelia", x=110, y=11, face="right", cond=FEST_DAY)
    r.add("npc", id="stu_a", who="student_a", x=34, y=F, face="right", talk="npc_st_fest_a", cond=FEST_DAY)
    r.add("npc", id="stu_b", who="student_b", x=52, y=F, face="right", talk="npc_st_fest_b", cond=FEST_DAY)
    r.add("npc", id="stu_c", who="student_c", x=75, y=F, face="left", talk="npc_st_fest_c", cond=FEST_DAY)
    # 리라 방문 뒤: 텅 빈 광장 / 엔딩 뒤: 다시 연 축제
    r.add("npc", id="mirabel_after", who="mirabel", x=100, y=F, face="left", cond=AFTER_LYRA)
    for x, who in ((19, "pippa"), (94, "butterworth"), (60, "isolde"), (34, "student_a"), (75, "student_c")):
        r.add("npc", id=who + "_epi", who=who, x=x, y=F if x not in (60,) else F - 3, face="left", cond="ch5_done")
    # 저녁 축제를 여는 무대 (교장의 사진 장면 뒤)
    r.add("trigger", id="st_evening", x=55, y=10, w=15, h=6, run="st_evening_ask", once=False, cond="st_fest_ready,!st_lyra_came")
    # 장식
    r.add("prop", kind="st_flower_arch", x=6, y=F)
    for x, y, w, sag in ((2, 3, 18, 3), (20, 2, 16, 2), (36, 3, 18, 3), (72, 2, 18, 3), (90, 3, 16, 2)):
        r.add("prop", kind="st_lantern_string", x=x, y=y, w=w, sag=sag)
    r.add("prop", kind="st_garland", x=54, y=6, w=17)
    for x in (53, 71):
        r.add("prop", kind="st_festival_banner", x=x, y=F - 3, h=7)
    for x in (24, 97):
        r.add("prop", kind="st_balloon_cluster", x=x, y=F)
    r.add("prop", kind="st_tea_table", x=86, y=F)
    r.add("prop", kind="st_telescope", x=112, y=11)
    r.add("prop", kind="st_star_chart", x=107, y=11, w=2, h=2)
    for x in (12, 50, 74, 96):
        r.add("prop", kind="torch", x=x, y=F)
    r.add("prop", kind="magic_circle", x=62, y=F - 3, w=12, col="#ffc870")
    r.add("sign", x=11, y=F, look="board",
          text="마녀학교 축제|낮: 가게와 요리 대회 / 해 질 녘: 무도회와 불꽃놀이|별 관측대는 오른쪽 비계 위. 오필리아 교수님이 (아마) 깨어 계십니다.")
    r.add("light", x=62, y=F - 6, r=7, color="#ffc870")
    return r


# ═══════════════════════════════════════════════════════════
# 별의 문간 (별의 탑 1층 · 네 시련으로 가는 별의 문)
# ═══════════════════════════════════════════════════════════

@room
def st_crossroads():
    r = in_room("st_crossroads", "별의 탑 · 별의 문간", "star", "star", "star_tower", (2, 0), (2, 1))
    star_door(r, "yard", 4, F, "s_courtyard", "star", "마녀학교 앞마당", open_if="st_lyra_came")
    r.add("save", id="candle", x=9, y=F, style="candle")
    star_door(r, "k", 16, F, "st_trial_k1", "in", "별의 시련 — 황도 아르덴", col="k", open_if="st_lyra_came", done_if="st_key_k")
    star_door(r, "e", 25, F, "st_trial_e1", "in", "별의 시련 — 세계수", col="e", open_if="st_lyra_came", done_if="st_key_e")
    star_door(r, "tp", 55, F, "st_trial_tp1", "in", "별의 시련 — 성산 대신전", col="tp", open_if="st_lyra_came", done_if="st_key_tp")
    star_door(r, "s", 64, F, "st_trial_s1", "in", "별의 시련 — 별의 정원", col="s", open_if="st_lyra_came", done_if="st_key_s")
    star_door(r, "up", 40, F, "st_tower_1", "in", "별의 탑 — 위로", lock=KEYS,
              lock_msg="별자리 봉인이 걸려 있다. 네 개의 별의 열쇠를 모아야 열린다.")
    for x, k in ((33, "st_key_k"), (36, "st_key_e"), (44, "st_key_tp"), (47, "st_key_s")):
        r.add("prop", kind="st_const_pedestal", x=x, y=F, lit_if=k)
    r.add("npc", id="astrid", who="astrid", x=30, y=F, face="right", cond="st_lyra_came,!st_tower_open")
    lanterns(r, (12, 21, 30, 50, 59, 68))
    r.add("prop", kind="st_orrery", x=76, y=F)
    r.add("sign", x=72, y=F, look="board",
          text="별빛으로 쓴 글씨|네 곳에 별을 내려 두었어. 각자의 땅에서, 각자의 강함으로.|열쇠 넷을 모으면 위로 올라오렴. — 리라")
    return r


# ═══════════════════════════════════════════════════════════
# 별의 시련 · 제국 (레오니와 함께, 별 기사)
# ═══════════════════════════════════════════════════════════

@room
def st_trial_k1():
    r = out_room("st_trial_k1", "황도 아르덴 · 별이 내린 거리", "star", "st_kingdom", "kingdom_night", (-1, 1), (2, 1))
    star_door(r, "in", 4, F, "st_crossroads", "k", "별의 문간", col="k", open_if="st_lyra_came")
    r.add("spawn", id="start", x=7, y=F, face="right")
    r.exit_right("east", F - 5, F - 1, "st_trial_k", "west")
    # 발코니·짐수레
    r.plat(14, 22, 14)
    r.plat(30, 40, 12)
    r.plat(52, 60, 13)
    r.plat(66, 74, 14)
    r.fill(26, 17, 28, 18)
    r.fill(46, 16, 48, 18)
    r.fill(62, 17, 63, 18)
    # 별 기사 둘 + 거리를 가로막는 별 정령의 선
    r.add("enemy", id="knight1", kind="star_knight", x=36, y=F, face="left")
    r.add("enemy", id="knight2", kind="star_knight", x=70, y=F, face="left")
    r.add("enemy", id="wisp1", kind="star_wisp", x=44, y=7, link="kst", order=0)
    r.add("enemy", id="wisp2", kind="star_wisp", x=44, y=17, link="kst", order=1)
    r.add("pickup", id="st_stone_k", kind="stone", x=56, y=13, name="마도석", text="별빛에 물든 보라 결정.")
    r.add("prop", kind="fountain", x=20, y=F)
    for x in (10, 34, 58, 76):
        r.add("prop", kind="torch", x=x, y=F)
    for x, c in ((18, "#6a2a3a"), (56, "#6a2a3a")):
        r.add("prop", kind="banner", x=x, y=2, h=5, col=c)
    r.add("prop", kind="crate", x=27, y=17)
    r.add("prop", kind="barrel", x=63, y=17)
    r.add("sign", x=12, y=F, look="board", text="황도 아르덴 — 별이 내린 밤|별빛 기사가 거리를 걷는다는 신고가 잇따름.|기사단 외 시민은 집 안에 머물 것. — 제국 기사단")
    return r


@room
def st_trial_k():
    r = out_room("st_trial_k", "황도 아르덴 · 별의 결투장", "star", "st_kingdom", "kingdom_night", (-2, 1), (1, 1))
    r.exit_left("west", F - 5, F - 1, "st_trial_k1", "east")
    r.plat(5, 10, 14)
    r.plat(29, 34, 14)
    r.plat(15, 24, 10)
    r.add("spawn", id="start", x=6, y=F, face="right")
    r.add("spawn", id="boss", x=30, y=F)
    r.add("gate", id="lock", x=1, y=F - 5, w=1, h=5, look="barrier", open_if="!st_k_fight")
    star_door(r, "out", 20, F, "st_crossroads", "k", "별의 문간", col="k", open_if="st_key_k", cond="st_key_k")
    r.add("prop", kind="magic_circle", x=20, y=F, w=16, col="#ffb070")
    for x in (3, 37):
        r.add("prop", kind="pillar", x=x, y=F, h=10)
    r.add("prop", kind="statue", x=20, y=10)
    for x in (8, 32):
        r.add("prop", kind="torch", x=x, y=F)
    return r


# ═══════════════════════════════════════════════════════════
# 별의 시련 · 엘프의 숲 (엘라리엔의 엄호, 별 궁수)
# ═══════════════════════════════════════════════════════════

@room
def st_trial_e1():
    r = out_room("st_trial_e1", "세계수 · 별빛 가지", "star", "st_elf", "elf", (6, -1), (1, 2))
    FB = r.h - 4  # 42
    star_door(r, "in", 4, FB, "st_crossroads", "e", "별의 문간", col="e", open_if="st_lyra_came")
    r.add("spawn", id="start", x=7, y=FB, face="right")
    r.exit_right("top", 5, 9, "st_trial_e", "west")
    for x0, x1, y in ((10, 17, 38), (20, 28, 34), (30, 37, 30), (18, 25, 26), (6, 13, 22), (15, 22, 18), (26, 33, 14), (30, 38, 10)):
        r.plat(x0, x1, y)
    r.plat(2, 5, 26)
    r.add("pickup", id="st_stone_e", kind="stone", x=3, y=26, name="마도석", text="세계수 잎에 맺힌 별빛 결정.")
    r.add("enemy", id="archer1", kind="star_archer", x=35, y=30, face="left")
    r.add("enemy", id="archer2", kind="star_archer", x=31, y=14, face="left")
    r.add("enemy", id="wisp1", kind="star_wisp", x=12, y=20, link="ebr", order=0)
    r.add("enemy", id="wisp2", kind="star_wisp", x=26, y=20, link="ebr", order=1)
    r.add("spawn", id="cover", x=8, y=22, face="right")
    for x, y in ((12, 38), (24, 34), (10, 22), (30, 14)):
        r.add("prop", kind="plant", x=x, y=y)
    r.add("light", x=20, y=30, r=6, color="#c8ffb0")
    r.add("sign", x=14, y=FB, look="stone", text="세계수의 가지|별을 쏘는 그림자가 가지 위에 있다.|붉은 선이 굳으면 몸을 숨길 것. — 숲지기의 새김")
    return r


@room
def st_trial_e():
    r = out_room("st_trial_e", "세계수 · 꼭대기", "star", "st_elf", "elf", (6, -2), (1, 1))
    r.exit_left("west", F - 5, F - 1, "st_trial_e1", "top")
    r.plat(5, 10, 14)
    r.plat(29, 34, 14)
    r.plat(15, 24, 10)
    r.plat(7, 12, 6)
    r.plat(27, 32, 6)
    r.add("spawn", id="start", x=4, y=F, face="right")
    r.add("spawn", id="boss", x=20, y=10)
    r.add("spawn", id="cover", x=8, y=6, face="right")
    r.add("gate", id="lock", x=1, y=F - 5, w=1, h=5, look="barrier", open_if="!st_e_fight")
    star_door(r, "out", 20, F, "st_crossroads", "e", "별의 문간", col="e", open_if="st_key_e", cond="st_key_e")
    r.add("prop", kind="magic_circle", x=20, y=F, w=14, col="#9af0a8")
    for x in (3, 37):
        r.add("prop", kind="plant", x=x, y=F)
    r.add("light", x=20, y=6, r=8, color="#c8ffb0")
    return r


# ═══════════════════════════════════════════════════════════
# 별의 시련 · 성산 대신전 (아우렐리아와 함께, 별 창기사)
# ═══════════════════════════════════════════════════════════

@room
def st_trial_tp1():
    r = in_room("st_trial_tp1", "성산 · 별빛 회랑", "star", "st_temple", "temple", (3, 1), (2, 1))
    star_door(r, "in", 4, F, "st_crossroads", "tp", "별의 문간", col="tp", open_if="st_lyra_came")
    r.add("spawn", id="start", x=7, y=F, face="right")
    r.exit_right("east", F - 5, F - 1, "st_trial_tp", "west")
    # 돌진을 막아 주는 기둥들 (위로 올라설 수 있음) + 높은 회랑
    for x in (20, 34, 48, 62):
        r.fill(x, 13, x + 1, F - 1)
    r.plat(10, 16, 13)
    r.plat(38, 44, 12)
    r.plat(66, 72, 13)
    r.add("enemy", id="lancer1", kind="star_lancer", x=30, y=F, face="left")
    r.add("enemy", id="lancer2", kind="star_lancer", x=58, y=F, face="left")
    r.add("enemy", id="wisp1", kind="star_wisp", x=41, y=4, link="tpw", order=0)
    r.add("enemy", id="wisp2", kind="star_wisp", x=41, y=10, link="tpw", order=1)
    r.add("pickup", id="st_stone_tp", kind="stone", x=41, y=12, name="마도석", text="성스러운 빛과 별빛이 섞인 결정.")
    for x in (27, 55):
        r.add("prop", kind="banner", x=x, y=2, h=6, col="#c8a040")
    for x in (8, 40, 74):
        r.add("prop", kind="candles", x=x, y=F)
    r.add("prop", kind="chandelier", x=41, y=1, len=2)
    r.add("sign", x=12, y=F, look="stone", text="빛의 회랑|창을 든 별빛이 회랑을 달린다.|기둥 뒤에서 숨을 고를 것. — 신전 수호대")
    return r


@room
def st_trial_tp():
    r = in_room("st_trial_tp", "대신전 · 종루", "star", "st_temple", "temple", (5, 1), (1, 1))
    r.exit_left("west", F - 5, F - 1, "st_trial_tp1", "east")
    r.plat(5, 10, 14)
    r.plat(29, 34, 14)
    r.plat(15, 24, 10)
    r.add("spawn", id="start", x=4, y=F, face="right")
    r.add("spawn", id="boss", x=30, y=F)
    r.add("gate", id="lock", x=1, y=F - 5, w=1, h=5, look="barrier", open_if="!st_tp_fight")
    star_door(r, "out", 20, F, "st_crossroads", "tp", "별의 문간", col="tp", open_if="st_key_tp", cond="st_key_tp")
    r.add("prop", kind="bell", x=20, y=2)
    r.add("prop", kind="magic_circle", x=20, y=F, w=14, col="#fff0a0")
    for x in (3, 37):
        r.add("prop", kind="pillar", x=x, y=F, h=17)
    return r


# ═══════════════════════════════════════════════════════════
# 별의 시련 · 학교 (이졸데·엠버린과 함께, 별의 정원)
# ═══════════════════════════════════════════════════════════

@room
def st_trial_s1():
    r = out_room("st_trial_s1", "별의 정원 · 첫째 뜰", "star", "st_garden", "school_day", (1, 1), (1, 1))
    star_door(r, "in", 3, F, "st_crossroads", "s", "별의 문간", col="s", open_if="st_lyra_came")
    r.add("spawn", id="start", x=6, y=F, face="right")
    # 오른쪽 높은 뜰 (별자리 다리로만 닿음)
    r.clear(15, F, 27, r.h - 1)
    r.fill(15, r.h - 1, 27, r.h - 1)
    r.fill(15, r.h - 2, 27, r.h - 2, "^")
    r.fill(28, 13, 38, r.h - 1)
    r.exit_right("east", 8, 12, "st_trial_s", "west")
    # 별을 쏠 발판 (별 높이 = 발판 바로 위)
    r.plat(3, 8, 15)
    r.plat(9, 13, 11)
    r.plat(4, 8, 7)
    stars(r, "sg1", ((13, 18), (2, 14), (14, 14), (5, 10), (12, 6)), "st_s1_stars")
    r.add("st_bridge", id="bridge", pts=[[14, 19], [18, 17], [23, 15], [27, 13]], on_if="st_s1_stars")
    r.add("updraft", id="sd", x=21, y=6, w=3, h=13, style="star", on_if="st_s1_stars")
    r.add("prop", kind="st_star_chart", x=34, y=13, w=3, h=2)
    r.add("event", id="ev", flag="st_s1_stars", run="st_s1_done")
    for x in (2, 36):
        r.add("prop", kind="plant", x=x, y=F if x < 15 else 13)
    r.add("sign", x=10, y=F, look="board", text="별의 정원 · 첫째 뜰|별은 아래에서 위로, 가까운 것부터 먼 것으로 잇는다.|틀리면 별이 꺼지니 처음부터. — 오필리아 (별 관측반)")
    return r


@room
def st_trial_s():
    r = out_room("st_trial_s", "별의 정원 · 별자리 뜰", "star", "st_garden", "school_day", (1, 2), (2, 1))
    r.fill(1, 13, 8, r.h - 1)
    r.exit_left("west", 8, 12, "st_trial_s1", "east")
    r.add("spawn", id="start", x=4, y=13, face="right")
    # 생울타리 발판과 오른쪽 높은 테라스 (별의 열쇠)
    r.plat(14, 20, 15)
    r.plat(26, 32, 12)
    r.plat(38, 44, 15)
    r.fill(22, 17, 24, F - 1)
    r.fill(62, 10, 78, r.h - 1)
    stars(r, "sg2", ((21, 14), (33, 11), (45, 14), (37, 18), (13, 18)), "st_s2_stars")
    r.add("st_bridge", id="bridge", pts=[[50, 19], [55, 16], [60, 13], [61, 13]], on_if="st_s2_stars")
    r.add("updraft", id="sd", x=54, y=6, w=3, h=13, style="star", on_if="st_s2_stars")
    # 별 정령: 가운데를 가르는 넷의 고리 + 열쇠를 지키는 셋
    for i, (x, y) in enumerate(((18, 9), (34, 6), (48, 10), (31, 16))):
        r.add("enemy", id="sw%d" % i, kind="star_wisp", x=x, y=y, link="sga", order=i, loop=True)
    for i, (x, y) in enumerate(((66, 6), (75, 6), (70, 2))):
        r.add("enemy", id="sk%d" % i, kind="star_wisp", x=x, y=y, link="sgk", order=i, loop=True)
    r.add("prop", kind="st_star_shard", x=71, y=10, cond="!st_key_s")
    r.add("trigger", id="key", x=69, y=6, w=5, h=4, run="st_s_key", cond="!st_key_s")
    star_door(r, "out", 76, 10, "st_crossroads", "s", "별의 문간", col="s", open_if="st_key_s", cond="st_key_s")
    r.add("event", id="ev", flag="st_s2_stars", run="st_s2_done")
    r.add("prop", kind="st_star_chart", x=11, y=F, w=3, h=2)
    for x in (10, 30, 46):
        r.add("prop", kind="plant", x=x, y=F)
    r.add("pickup", id="st_stone_s", kind="stone", x=29, y=12, name="마도석", text="정원에 떨어진 별 부스러기가 굳은 결정.")
    return r


# ═══════════════════════════════════════════════════════════
# 별의 탑 (st_tower_1 ~ 5, 꼭대기)
# ═══════════════════════════════════════════════════════════

@room
def st_tower_1():
    r = in_room("st_tower_1", "별의 탑 · 1층 별자리 계단", "star", "star", "star_tower", (3, -2), (1, 2))
    FB = r.h - 4  # 42
    star_door(r, "in", 34, FB, "st_crossroads", "up", "별의 문간")
    # 쏘는 자리 (오른쪽 계단) → 별 넷을 아래에서 위로 → 왼쪽 위로 오르는 별자리 다리
    r.plat(30, 37, 38)
    r.plat(24, 30, 34)
    r.plat(32, 38, 30)
    r.fill(1, 14, 9, 15)
    r.door("up", 4, 14, "st_tower_2", "in", style="stair_up", label="2층")
    stars(r, "t1", ((20, 41), (18, 37), (12, 33), (24, 29)), "st_t1_stars")
    r.add("st_bridge", id="bridge", pts=[[36, 30], [28, 26], [20, 22], [12, 18], [10, 18]], on_if="st_t1_stars")
    r.add("updraft", id="sd", x=14, y=12, w=3, h=29, style="star", on_if="st_t1_stars")
    r.add("event", id="ev", flag="st_t1_stars", run="st_t1_done")
    memory(r, 1, 6, FB)
    lanterns(r, (8, 20, 32), ln=4)
    r.add("prop", kind="st_star_chart", x=26, y=FB, w=3, h=2)
    r.add("sign", x=24, y=FB, look="board", text="별자리 계단|별은 아래에서 위로 잇는다.|다 이으면 별의 길이 생길 것이다. — 리라")
    for x in (3, 37):
        r.add("light", x=x, y=FB - 3, r=4, color="#fff3c0")
    return r


@room
def st_tower_2():
    r = in_room("st_tower_2", "별의 탑 · 2층 별 정령의 회랑", "star", "star", "star_tower", (2, -3), (2, 1))
    r.door("in", 4, F, "st_tower_1", "up", style="stair_down", label="1층")
    r.door("up", 76, F, "st_tower_3", "in", style="stair_up", label="3층")
    r.add("save", id="candle", x=9, y=F, style="candle")
    for x0, x1, y in ((12, 18, 15), (28, 34, 13), (40, 46, 15), (54, 60, 15), (62, 70, 13), (48, 52, 8)):
        r.plat(x0, x1, y)
    r.add("enemy", id="wisp_a0", kind="star_wisp", x=22, y=5, link="t2a", order=0)
    r.add("enemy", id="wisp_a1", kind="star_wisp", x=22, y=17, link="t2a", order=1)
    for i, (x, y) in enumerate(((42, 8), (50, 14), (58, 8))):
        r.add("enemy", id="wisp_b%d" % i, kind="star_wisp", x=x, y=y, link="t2b", order=i, loop=True)
    r.add("enemy", id="knight", kind="star_knight", x=36, y=F, face="left")
    r.add("enemy", id="archer", kind="star_archer", x=67, y=13, face="left")
    memory(r, 2, 50, 8)
    lanterns(r, (14, 30, 46, 62))
    r.add("prop", kind="st_orrery", x=26, y=F)
    return r


@room
def st_tower_3():
    r = in_room("st_tower_3", "별의 탑 · 3층 별의 우물", "star", "star", "star_tower", (1, -5), (1, 2))
    FB = r.h - 4
    r.door("in", 36, FB, "st_tower_2", "up", style="stair_down", label="2층")
    for x0, x1, y in ((28, 34, 38), (18, 24, 34), (8, 14, 30), (20, 26, 26), (30, 36, 22)):
        r.plat(x0, x1, y)
    r.plat(2, 5, 30)
    r.fill(1, 10, 10, 11)
    r.door("up", 4, 10, "st_tower_4", "in", style="stair_up", label="4층")
    stars(r, "t3", ((24, 37), (29, 33), (19, 29), (16, 25)), "st_t3_stars")
    r.add("st_bridge", id="bridge", pts=[[30, 22], [22, 18], [14, 14], [12, 13]], on_if="st_t3_stars")
    r.add("updraft", id="sd", x=18, y=8, w=3, h=33, style="star", on_if="st_t3_stars")
    r.add("event", id="ev", flag="st_t3_stars", run="st_t3_done")
    r.add("enemy", id="archer", kind="star_archer", x=34, y=22, face="left")
    memory(r, 3, 3, 30)
    # 벽의 별 그림 (순서 힌트): 별자리판 넷
    for x, y in ((37, 34), (2, 22)):
        r.add("prop", kind="st_star_chart", x=x, y=y, w=2, h=2)
    r.add("sign", x=31, y=FB, look="board", text="별의 우물|이번엔 별이 지그재그로 오른다.|벽의 별 그림을 잘 볼 것. 틀리면 처음부터. — 리라")
    lanterns(r, (8, 30), ln=6)
    return r


def _tower4_base():
    """4층 '뒤집힌 하늘'의 지형 (바로 선 판). 천장(0~3행)이 두꺼워 뒤집으면 바닥이 된다"""
    r = in_room("st_tower_4", "별의 탑 · 4층 뒤집힌 하늘", "star", "star", "star_tower", (1, -6), (2, 1), ceil=4)
    r.clear(30, F, 44, r.h - 1)
    r.fill(30, r.h - 1, 44, r.h - 1, "^")
    r.fill(50, 4, 53, 8)
    r.clear(58, 0, 66, 3)
    r.fill(58, 0, 66, 0, "^")
    return r


@room
def st_tower_4():
    r = _tower4_base()
    r.door("in", 4, F, "st_tower_3", "up", style="stair_down", label="3층")
    r.door("up", 76, F, "st_tower_5", "in", style="stair_up", label="5층")
    r.add("spawn", id="back", x=55, y=F, face="right")
    r.add("prop", kind="st_flip_sigil", x=26, y=F)
    r.add("trigger", id="flip", x=25, y=F - 3, w=3, h=3, run="st_flip_down", once=False)
    for x in (12, 20, 52, 70):
        r.add("prop", kind="st_star_lantern", x=x, y=4, len=2 + (x % 3))
    r.add("prop", kind="st_const_pedestal", x=8, y=F)
    r.add("sign", x=16, y=F, look="board", text="뒤집힌 하늘|위가 아래가 되면, 닿지 않던 길이 발밑에 있다.|별 문양을 밟을 것. — 리라")
    return r


@room
def st_tower_4r():
    # 같은 층을 위아래로 뒤집은 판: 바로 선 판의 천장이 바닥, 구덩이는 천장의 구멍이 된다
    base = _tower4_base()
    r = Room("st_tower_4r", "별의 탑 · 4층 (뒤집힘)", "star", "star_flip", "star_tower", (1, -7), (2, 1))
    for y in range(r.h):
        r.g[y] = list(base.g[r.h - 1 - y])
    r.add("spawn", id="in", x=26, y=F, face="right")
    r.add("prop", kind="st_flip_sigil", x=55, y=F)
    r.add("trigger", id="flip", x=54, y=F - 3, w=3, h=3, run="st_flip_up", once=False)
    # 바로 선 판에서 매달려 있던 별 등롱이 여기선 바닥에서 솟아 있다
    for x in (12, 20, 52, 70):
        r.add("prop", kind="st_star_lantern", x=x, y=F, len=2 + (x % 3), vflip=True)
    r.add("prop", kind="st_const_pedestal", x=8, y=4, vflip=True)
    memory(r, 4, 40, F)
    r.add("pickup", id="st_stone_t4", kind="stone", x=72, y=F, name="마도석", text="뒤집힌 하늘에 떨어져 있던 결정.")
    return r


@room
def st_tower_5():
    r = in_room("st_tower_5", "별의 탑 · 5층 기억의 회랑", "star", "star", "lyra", (2, -8), (2, 1))
    r.door("in", 4, F, "st_tower_4", "up", style="stair_down", label="4층")
    r.door("up", 76, F, "st_tower_top", "in", style="stair_up", label="꼭대기", lock="st_t5_open",
           lock_msg="별자리 봉인. 리라의 별빛이 아닌, 다른 별빛이 필요하다…")
    r.add("save", id="candle", x=9, y=F, style="candle")
    r.plat(24, 32, 13)
    r.plat(46, 52, 14)
    r.add("enemy", id="knight", kind="star_knight", x=38, y=F, face="left")
    r.add("enemy", id="archer", kind="star_archer", x=49, y=14, face="left")
    r.add("enemy", id="lancer", kind="star_lancer", x=60, y=F, face="left")
    r.add("gate", id="seal", x=72, y=F - 6, w=1, h=6, look="seal", open_if="st_t5_open")
    r.add("trigger", id="astrid", x=64, y=F - 4, w=6, h=4, run="st_t5_astrid", cond="!st_t5_open")
    r.add("spawn", id="astrid_in", x=66, y=F, face="left")
    memory(r, 5, 14, F)
    memory(r, 6, 28, 13)
    memory(r, 7, 68, F)
    lanterns(r, (16, 34, 52, 70), ln=3)
    for x in (20, 44):
        r.add("prop", kind="st_photo_frame", x=x, y=F - 6)
    return r


@room
def st_tower_top():
    r = in_room("st_tower_top", "별의 탑 · 꼭대기", "star", "star", "lyra", (3, -9), (1, 1))
    r.plat(4, 10, F - 5)
    r.plat(29, 35, F - 5)
    r.plat(15, 24, F - 9)
    r.door("in", 3, F, "st_tower_5", "up", style="stair_down", label="5층")
    r.add("spawn", id="start", x=6, y=F, face="right")
    r.add("spawn", id="mid", x=20, y=F, face="right")
    r.add("spawn", id="boss", x=30, y=F)
    r.add("prop", kind="st_const_pedestal", x=2, y=F)
    r.add("prop", kind="st_const_pedestal", x=37, y=F, flip=True)
    r.add("prop", kind="st_star_lantern", x=13, y=1, len=3)
    r.add("prop", kind="st_star_lantern", x=26, y=1, len=4)
    r.add("prop", kind="magic_circle", x=20, y=F, w=16, col="#fff3c0")
    return r


# ═══════════════════════════════════════════════════════════
# 침공 · 절망: 무너진 학교 (학교 영역, 원래 학교 오른쪽 칸)
# ═══════════════════════════════════════════════════════════

@room
def r5_clock():
    r = in_room("r5_clock", "무너진 학교 · 시계탑", "school", "ruin_school", "despair", (12, -1), (1, 2), dark=0.1)
    FB = r.h - 4
    r.fill(10, 10, 30, 11)
    for x0, x1, y in ((4, 10, 16), (14, 22, 21), (26, 34, 26), (16, 24, 31), (4, 12, 36)):
        r.plat(x0, x1, y)
    r.add("spawn", id="land", x=20, y=10, face="left")
    r.exit_left("west", FB - 5, FB - 1, "r5_hall", "east")
    r.add("st_quake", x=0, y=0, strength=0.6)
    r.add("prop", kind="clock_face", x=20, y=4)
    r.add("prop", kind="st_broken_bell", x=30, y=FB)
    r.add("prop", kind="st_rubble", x=24, y=10, w=4)
    r.add("prop", kind="st_rubble", x=8, y=FB, w=5)
    for x, y in ((12, 16), (28, 26), (34, FB)):
        r.add("prop", kind="st_fire", x=x, y=y)
    r.add("prop", kind="st_comm_crystal", x=18, y=FB, on=True)
    r.add("trigger", id="comm", x=15, y=FB - 4, w=6, h=4, run="r5_comm_leonie", cond="!st_comm_k")
    r.add("spawn", id="comm", x=16, y=FB, face="right")
    r.add("prop", kind="st_white_growth", x=36, y=31)
    return r


@room
def r5_hall():
    r = in_room("r5_hall", "무너진 학교 · 중앙 홀", "school", "ruin_school", "despair", (10, -1), (2, 2), dark=0.05)
    FB = r.h - 4
    r.exit_right("east", FB - 5, FB - 1, "r5_clock", "west")
    r.exit_left("west", FB - 5, FB - 1, "r5_westcorr", "east")
    # 무너진 2층 발코니와 잔해
    r.fill(1, 19, 9, 20)
    r.plat(10, 17, 19)
    r.fill(70, 19, 78, 20)
    r.plat(62, 69, 19)
    r.fill(46, 37, 54, 41)
    r.fill(20, 40, 24, 41)
    r.plat(30, 38, 34)
    r.plat(58, 64, 34)
    r.add("spawn", id="start", x=76, y=FB, face="left")
    r.add("enemy", id="seraph1", kind="outer_seraph", x=58, y=36, face="left")
    r.add("enemy", id="seraph2", kind="outer_seraph", x=30, y=33, face="right")
    for x, who in ((8, "pippa"), (12, "student_a"), (5, "student_b")):
        r.add("npc", id=who, who=who, x=x, y=FB, face="right", cond="!st_escort")
    r.add("st_follow", id="followers", who=["pippa", "student_a", "student_b"], cond="st_escort")
    r.add("st_quake", x=0, y=0, strength=0.5)
    r.add("prop", kind="st_cracked_statue", x=34, y=FB)
    r.add("prop", kind="st_rubble", x=50, y=37, w=7)
    r.add("prop", kind="st_burning_beam", x=40, y=FB, w=5)
    r.add("prop", kind="st_fallen_banner", x=26, y=FB)
    r.add("prop", kind="st_white_growth", x=66, y=FB)
    for x, y in ((16, FB), (44, 37), (72, 19), (60, FB)):
        r.add("prop", kind="st_fire", x=x, y=y, size=1.2)
    r.add("prop", kind="chandelier", x=40, y=1, len=3)
    return r


@room
def r5_westcorr():
    r = in_room("r5_westcorr", "무너진 학교 · 서관 복도", "school", "ruin_school", "despair", (8, 0), (2, 1))
    r.clear(8, 0, 72, 0)
    r.exit_right("east", F - 5, F - 1, "r5_hall", "west")
    r.exit_left("west", F - 5, F - 1, "r5_library", "east")
    r.fill(30, F - 2, 32, F - 1)
    r.fill(52, F - 3, 54, F - 1)
    r.fill(14, F - 2, 15, F - 1)
    r.plat(40, 46, 14)
    r.add("spawn", id="start", x=76, y=F, face="left")
    r.add("enemy", id="hand", kind="colossus", x=40, y=F, mode="hand", interval=3.2)
    r.add("st_follow", id="followers", who=["pippa", "student_a", "student_b"], cond="st_escort")
    r.add("st_quake", x=0, y=0, strength=0.8)
    for x in (20, 44, 66):
        r.add("prop", kind="st_crater", x=x, y=F, w=3)
    r.add("prop", kind="st_rubble", x=31, y=F - 2, w=3)
    r.add("prop", kind="st_rubble", x=53, y=F - 3, w=3)
    r.add("prop", kind="st_fire", x=60, y=F)
    r.add("prop", kind="st_fallen_banner", x=8, y=F)
    return r


@room
def r5_library():
    r = in_room("r5_library", "무너진 학교 · 도서관", "school", "ruin_school", "despair", (8, -1), (2, 1), dark=0.1)
    r.exit_right("east", F - 5, F - 1, "r5_westcorr", "west")
    r.exit_left("west", F - 5, F - 1, "r5_dorm", "east")
    r.plat(30, 36, 14)
    r.plat(44, 50, 12)
    r.plat(12, 18, 14)
    r.add("spawn", id="start", x=76, y=F, face="left")
    r.add("enemy", id="seraph", kind="outer_seraph", x=40, y=12, face="right")
    r.add("npc", id="greta", who="greta", x=20, y=F, face="right", cond="!st_lib_saved")
    r.add("npc", id="hodu", who="hodu", x=24, y=F, face="right", cond="!st_lib_saved")
    r.add("st_follow", id="followers", who=["pippa", "student_a", "student_b"], cond="st_escort")
    r.add("prop", kind="st_comm_crystal", x=60, y=F, on=True)
    r.add("trigger", id="comm", x=57, y=F - 4, w=6, h=4, run="r5_comm_elarien", cond="!st_comm_e")
    r.add("spawn", id="comm", x=58, y=F, face="right")
    r.add("st_quake", x=0, y=0, strength=0.5)
    for x in (8, 28, 52, 70):
        r.add("prop", kind="bookshelf", x=x, y=F, w=4, h=8)
    for x in (10, 30, 54):
        r.add("prop", kind="st_fire", x=x, y=F, size=0.9)
    r.add("prop", kind="st_rubble", x=40, y=F, w=4)
    return r


@room
def r5_dorm():
    r = in_room("r5_dorm", "무너진 학교 · 기숙사 대피소", "school", "ruin_school", "despair", (8, 1), (1, 1), dark=0.1)
    r.exit_right("east", F - 5, F - 1, "r5_library", "west")
    r.exit_left("west", F - 5, F - 1, "r5_courtyard", "east")
    r.add("spawn", id="start", x=36, y=F, face="left")
    r.add("save", id="bed", x=30, y=F, style="bed")
    r.add("npc", id="astrid", who="astrid", x=14, y=F, face="right", cond="!st_dorm_seen")
    r.add("npc", id="mirabel", who="mirabel", x=8, y=F, face="right", cond="!st_dorm_seen")
    r.add("npc", id="stu_c", who="student_c", x=20, y=F, face="left", talk="npc_r5_stu", cond="!st_dorm_seen")
    r.add("st_follow", id="followers", who=["pippa", "student_a", "student_b"], cond="st_escort")
    r.add("prop", kind="st_comm_crystal", x=24, y=F, on=True)
    r.add("spawn", id="comm", x=22, y=F, face="right")
    r.add("prop", kind="bed_prop", x=12, y=F)
    r.add("prop", kind="bed_prop", x=26, y=F)
    r.add("prop", kind="st_rubble", x=34, y=F, w=3)
    r.add("prop", kind="candles", x=17, y=F)
    r.add("st_quake", x=0, y=0, strength=0.4)
    return r


@room
def r5_courtyard():
    r = out_room("r5_courtyard", "무너진 학교 · 앞마당", "school", "ruin_school", "despair", (9, 1), (3, 1))
    r.exit_right("east", F - 5, F - 1, "r5_dorm", "west")
    r.fill(84, F - 2, 88, F - 1)
    r.fill(60, F - 3, 63, F - 1)
    r.fill(24, F - 2, 27, F - 1)
    r.plat(70, 76, 14)
    r.add("spawn", id="start", x=116, y=F, face="left")
    r.add("spawn", id="fall", x=43, y=F, face="left")
    r.add("spawn", id="barrier", x=30, y=F, face="right")
    r.add("enemy", id="giant", kind="colossus", x=100, y=F, face="left", mode="walk", stride=7.0, step_time=2.6)
    r.add("enemy", id="hand", kind="colossus", x=60, y=F, mode="hand", interval=4.0)
    r.add("st_follow", id="followers", who=["pippa", "student_a", "student_b"], cond="st_escort")
    r.add("st_quake", x=0, y=0, strength=1.0)
    r.add("trigger", id="despair", x=40, y=F - 6, w=6, h=6, run="r5_despair", cond="!st_fallen")
    for x, w in ((8, 5), (36, 4), (96, 5)):
        r.add("prop", kind="st_crater", x=x, y=F, w=w)
    r.add("prop", kind="st_rubble", x=86, y=F - 2, w=5)
    r.add("prop", kind="st_rubble", x=61, y=F - 3, w=4)
    r.add("prop", kind="st_cracked_statue", x=50, y=F)
    r.add("prop", kind="st_fallen_banner", x=70, y=F)
    r.add("prop", kind="st_white_growth", x=18, y=F)
    r.add("prop", kind="st_white_growth", x=104, y=F)
    for x in (30, 66, 92, 110):
        r.add("prop", kind="st_fire", x=x, y=F, size=1.3)
    return r


# ═══════════════════════════════════════════════════════════
# 어둠 · 반격 · 하늘 · 에필로그
# ═══════════════════════════════════════════════════════════

@room
def st_void():
    r = in_room("st_void", "어둠", "star", "void", "nine_tails", (5, -9), (1, 1))
    r.add("spawn", id="start", x=12, y=F, face="right")
    r.add("st_awaken", id="neoul_god", who="neoul_god", x=26, y=F, face="left", tails=4, hidden=True)
    return r


@room
def r5_courtyard_rise():
    r = out_room("r5_courtyard_rise", "무너진 학교 · 앞마당 (새벽)", "school", "rise", "nine_tails", (9, 2), (3, 1))
    r.fill(84, F - 2, 88, F - 1)
    r.fill(60, F - 3, 63, F - 1)
    r.fill(24, F - 2, 27, F - 1)
    r.plat(70, 76, 14)
    r.exit_right("east", F - 5, F - 1, "st_colossus_1", "west")
    r.add("spawn", id="wake", x=43, y=F, face="right")
    for i, x in enumerate((50, 55, 66, 80, 92, 34, 30)):
        r.add("spawn", id="a%d" % i, x=x, y=F, face="left")
    r.add("trigger", id="go", x=100, y=F - 6, w=4, h=6, run="r5_rise_go", cond="st_rise,!st_rise_go")
    r.add("st_quake", x=0, y=0, strength=0.25)
    for x, w in ((8, 5), (36, 4), (96, 5)):
        r.add("prop", kind="st_crater", x=x, y=F, w=w)
    r.add("prop", kind="st_rubble", x=86, y=F - 2, w=5)
    r.add("prop", kind="st_rubble", x=61, y=F - 3, w=4)
    r.add("prop", kind="st_cracked_statue", x=50, y=F)
    r.add("prop", kind="st_fox_altar", x=40, y=F)
    for x in (30, 66, 92, 110):
        r.add("prop", kind="st_fire", x=x, y=F, size=1.0)
    return r


@room
def st_colossus_1():
    r = out_room("st_colossus_1", "반격 · 거신의 발치", "star", "rise", "final", (5, -4), (2, 1))
    r.exit_left("west", F - 5, F - 1, "r5_courtyard_rise", "east")
    r.exit_right("east", F - 5, F - 1, "st_colossus_2", "west")
    r.fill(20, F - 2, 24, F - 1)
    r.fill(50, F - 3, 53, F - 1)
    r.plat(30, 38, 14)
    r.plat(58, 66, 13)
    r.add("spawn", id="start", x=3, y=F, face="right")
    for i, (x, y) in enumerate(((34, 10), (52, 9), (68, 8))):
        r.add("enemy", id="seraph%d" % i, kind="outer_seraph", x=x, y=y, face="left")
    r.add("enemy", id="giant", kind="colossus", x=62, y=F, face="left", mode="walk", stride=6.0, step_time=3.4, sleep=0.5)
    r.add("gate", id="lock", x=78, y=F - 5, w=1, h=5, look="barrier", open_if="st_c1_clear")
    r.add("st_quake", x=0, y=0, strength=0.3)
    for x in (12, 44, 70):
        r.add("prop", kind="st_fire", x=x, y=F, size=1.1)
    r.add("prop", kind="st_rubble", x=22, y=F - 2, w=5)
    r.add("prop", kind="st_rubble", x=51, y=F - 3, w=4)
    r.add("prop", kind="st_white_growth", x=40, y=F)
    return r


@room
def st_colossus_2():
    # 3×2칸: 왼쪽 무너진 탑 꼭대기 → 거신 셋의 손·팔·어깨·머리를 밟고 → 오른쪽 탑으로 (dev_st_ride 시험장의 실제 판)
    r = Room("st_colossus_2", "반격 · 거신 위를 달려", "star", "rise", "final", (7, -5), (3, 2))
    G = r.h - 2
    r.fill(0, G, r.w - 1, r.h - 1)
    r.fill(0, 0, 0, r.h - 1)
    r.fill(r.w - 1, 0, r.w - 1, r.h - 1)
    r.fill(1, 22, 14, G)          # 출발 탑
    r.fill(108, 17, 118, G)       # 도착 탑
    r.exit_left("west", 17, 21, "st_colossus_1", "east")
    r.exit_right("east", 12, 16, "st_colossus_3", "west")
    # 떨어졌을 때 출발 탑으로 다시 오르는 사다리 발판
    for y in (40, 36, 32, 28, 24):
        r.plat(15, 19, y)
    r.add("spawn", id="start", x=8, y=22, face="right")
    r.add("spawn", id="low", x=30, y=G, face="right")
    r.add("st_colossus_ride", id="c1", x=40, y=G, h=34, dir="left", speed=0.35, travel=8)
    r.add("st_colossus_ride", id="c2", x=64, y=G, h=34, dir="left", speed=0.3, phase=0.5, travel=8)
    r.add("st_colossus_ride", id="c3", x=88, y=G, h=34, dir="left", speed=0.3, phase=0.25, travel=8)
    # 불타는 폐허의 열기 (불꽃 날개가 있으면 바닥에서 도착 탑으로 오를 수 있다)
    r.add("updraft", id="heat", x=104, y=16, w=3, h=28, style="heat", power=1.0)
    r.add("st_quake", x=0, y=0, strength=0.3)
    r.add("enemy", id="seraph", kind="outer_seraph", x=76, y=10, face="left")
    r.add("prop", kind="st_fire", x=105, y=G, size=1.4)
    r.add("prop", kind="st_rubble", x=6, y=22, w=4)
    r.add("prop", kind="st_rubble", x=112, y=17, w=4)
    return r


@room
def st_colossus_3():
    # 가장 큰 거신 (움직이지 않음): 손바닥 → 팔 → 어깨 → 머리 꼭대기. 거기서 교장이 세라를 하늘로 쏘아 올린다
    r = Room("st_colossus_3", "반격 · 가장 큰 거신", "star", "rise", "final", (10, -6), (1, 2))
    G = r.h - 2
    r.fill(0, G, r.w - 1, r.h - 1)
    r.fill(0, 0, 0, r.h - 1)
    r.fill(r.w - 1, 0, r.w - 1, r.h - 1)
    r.fill(1, 37, 7, G)
    r.exit_left("west", 32, 36, "st_colossus_2", "east")
    r.add("spawn", id="start", x=4, y=37, face="right")
    # 무너진 탑의 잔해를 딛고 손바닥(약 17행, x 2~3)까지 → 팔 오르막 → 어깨 → 머리 꼭대기(약 10행, x 20~22)
    for x0, x1, y in ((9, 14, 33), (2, 7, 29), (9, 14, 25), (5, 10, 21)):
        r.plat(x0, x1, y)
    r.add("st_colossus_ride", id="big", x=24, y=G, h=40, dir="left", speed=0.0, travel=0)
    r.add("trigger", id="launch", x=17, y=6, w=8, h=4, run="st_launch", cond="!st_launch")
    r.add("st_quake", x=0, y=0, strength=0.2)
    r.add("prop", kind="st_rubble", x=4, y=37, w=4)
    r.add("prop", kind="st_fire", x=12, y=G, size=1.2)
    return r


@room
def st_sky_1():
    r = Room("st_sky_1", "하늘 · 부서진 세계 사이로", "star", "sky", "final", (10, -9), (1, 3))
    B = r.h - 3  # 66
    r.fill(0, 0, 0, r.h - 1)
    r.fill(r.w - 1, 0, r.w - 1, r.h - 1)
    r.fill(14, B, 26, r.h - 1)
    r.add("spawn", id="launch", x=20, y=B, face="right")
    # 떠다니는 땅 조각 (지그재그로 위로)
    pieces = ((28, 34, 62), (18, 24, 58), (6, 12, 54), (14, 20, 50), (26, 32, 46), (32, 37, 42), (22, 28, 38),
              (10, 16, 34), (3, 8, 30), (12, 18, 26), (24, 30, 22), (32, 37, 18), (22, 27, 14), (12, 18, 10))
    for x0, x1, y in pieces:
        r.fill(x0, y, x1, y)
    r.fill(1, 5, 10, 6)
    r.exit_left("top", 0, 4, "st_skygate", "west")
    # 교장이 깔아 둔 별빛 기둥 (날개로 타면 빠르다)
    r.add("updraft", id="s1", x=7, y=36, w=3, h=20, style="star", power=1.0)
    r.add("updraft", id="s2", x=33, y=8, w=3, h=30, style="star", power=1.0)
    for i, (x, y) in enumerate(((10, 44), (30, 28), (16, 16))):
        r.add("enemy", id="seraph%d" % i, kind="outer_seraph", x=x, y=y, face="left")
    r.add("pickup", id="st_stone_sky", kind="stone", x=4, y=30, name="마도석", text="세계의 조각에 박혀 있던 결정.")
    return r


@room
def st_skygate():
    r = Room("st_skygate", "하늘의 문", "star", "sky", "final", (10, -10), (1, 1))
    r.fill(0, F, r.w - 1, r.h - 1)
    r.fill(0, 0, 0, r.h - 1)
    r.fill(r.w - 1, 0, r.w - 1, r.h - 1)
    r.exit_left("west", F - 5, F - 1, "st_sky_1", "top")
    r.plat(3, 9, F - 4)
    r.plat(30, 36, F - 4)
    r.plat(12, 17, F - 8)
    r.plat(22, 27, F - 8)
    r.plat(17, 22, F - 12)
    r.add("gate", id="lock", x=1, y=F - 5, w=1, h=5, look="barrier", open_if="!st_gate_fight")
    r.add("spawn", id="start", x=4, y=F, face="right")
    r.add("spawn", id="mid", x=20, y=F, face="right")
    for i, x in enumerate((6, 10, 30, 34, 14, 26)):
        r.add("spawn", id="al%d" % i, x=x, y=F if i < 4 else F - 8, face="right" if x < 20 else "left")
    return r


@room
def st_rebuild():
    r = out_room("st_rebuild", "마녀학교 · 다시 세우는 안뜰", "school", "dawn", "ending2", (8, 4), (2, 1))
    r.door("yard", 4, F, "s_courtyard", "rebuild", style="wood", label="앞마당")
    r.add("save", id="yard", x=9, y=F, style="candle")
    r.add("spawn", id="wake", x=14, y=F, face="right")
    r.fill(46, F - 3, 52, F - 1)
    r.plat(54, 60, 14)
    # 다시 세우기를 돕는 사람들 (st_rebuild 퀘스트)
    for x, who, face in ((20, "emberlyn", "left"), (27, "pippa", "right"), (35, "butterworth", "left"), (44, "hodu", "right"),
                         (57, "isolde", "left"), (63, "leonie", "left"), (67, "elarien", "right"), (71, "aurelia", "left")):
        r.add("npc", id=who, who=who, x=x, y=F if who != "isolde" else 14, face=face)
    # 차 탁자: 리라와 교장
    r.add("prop", kind="st_tea_table", x=33, y=F)
    r.add("npc", id="lyra", who="lyra", x=31, y=F, face="right")
    r.add("npc", id="astrid", who="astrid", x=36, y=F, face="left")
    r.add("trigger", id="tea", x=29, y=F - 4, w=10, h=4, run="st_tea", cond="st_epilogue,!st_tea_done")
    r.add("prop", kind="st_scaffold", x=48, y=F - 3, w=6, h=7)
    r.add("prop", kind="st_scaffold", x=74, y=F, w=8, h=10)
    r.add("prop", kind="st_rubble", x=12, y=F, w=4)
    r.add("prop", kind="st_fox_altar", x=40, y=F)
    r.add("prop", kind="st_photo_frame", x=76, y=F - 1, cond="st_photo_taken")
    for x, y, w, sag in ((10, 3, 16, 2), (48, 2, 18, 3)):
        r.add("prop", kind="st_lantern_string", x=x, y=y, w=w, sag=sag)
    r.add("sign", x=7, y=F, look="board", text="다시 세우는 안뜰|공사 중. 머리 조심.|도울 사람은 엠버린 교수에게 이름을 적을 것. 간식은 버터워스 님 제공.")
    return r


# ═══════════════════════════════════════════════════════════
# 절망의 환상: 같은 시각 다른 지역 (통신 수정 구슬이 울릴 때 잠깐 보여 주는 장면 전용 방)
# 지도 영역 "vision" — 장면 중에만 머무르므로 지도에 나오지 않는다. 문·출구 없음.
# ═══════════════════════════════════════════════════════════

def _vision_room(rid, title, theme, cell):
    r = Room(rid, title, "vision", theme, "despair", cell, (1, 1))
    r.ground(F)
    r.fill(0, 0, 0, F - 1)
    r.fill(r.w - 1, 0, r.w - 1, F - 1)
    r.add("spawn", id="view", x=20, y=F, face="right")
    r.add("st_quake", x=0, y=0, strength=1.0)
    return r


@room
def r5_vision_k():
    r = _vision_room("r5_vision_k", "황도 아르덴 — 같은 시각", "ruin_kingdom", (0, 0))
    r.add("enemy", id="giant", kind="colossus", x=36, y=F, face="left", mode="walk", stride=6.0, step_time=2.4)
    r.add("prop", kind="st_rubble", x=6, y=F, w=5)
    r.add("prop", kind="st_burning_beam", x=25, y=F, w=4)
    r.add("prop", kind="st_fallen_banner", x=11, y=F)
    r.add("prop", kind="st_broken_pillar", x=30, y=F, h=7)
    for x in (3, 20, 33):
        r.add("prop", kind="st_fire", x=x, y=F, size=1.2)
    return r


@room
def r5_vision_e():
    r = _vision_room("r5_vision_e", "세계수 — 같은 시각", "ruin_elf", (1, 0))
    r.add("enemy", id="giant", kind="colossus", x=34, y=F, face="left", mode="walk", stride=6.0, step_time=2.6)
    r.add("prop", kind="st_ash_tree", x=8, y=F)
    r.add("prop", kind="st_ash_tree", x=27, y=F)
    r.add("prop", kind="st_white_growth", x=22, y=F)
    for x in (4, 14, 31):
        r.add("prop", kind="st_fire", x=x, y=F, size=1.1)
    return r


@room
def r5_vision_tp():
    r = _vision_room("r5_vision_tp", "대신전 — 같은 시각", "ruin_temple", (2, 0))
    r.add("enemy", id="giant", kind="colossus", x=35, y=F, face="left", mode="walk", stride=6.0, step_time=2.5)
    r.add("prop", kind="st_broken_bell", x=8, y=F)
    r.add("prop", kind="st_cracked_statue", x=27, y=F)
    r.add("prop", kind="st_broken_pillar", x=4, y=F, h=8)
    r.add("prop", kind="st_broken_pillar", x=32, y=F, h=5)
    for x in (12, 24):
        r.add("prop", kind="st_fire", x=x, y=F, size=1.0)
    return r
