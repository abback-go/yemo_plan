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
from roomgen import Room, room, overlay  # noqa: F401

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
