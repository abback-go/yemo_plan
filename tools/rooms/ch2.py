"""2장 방 (docs/chapter2.md). roomgen.py가 불러온다.
from roomgen import Room, room, overlay — 1장 roomgen.py와 같은 문법.

1단계(지금): 개발용 시험 방 dev_k_* 만. 실제 장의 방 34개는 2단계에서 docs/chapter2.md 7절 설계대로 만든다.
    python3 tools/roomgen.py dev_k_city dev_k_night dev_k_hall dev_k_sewer dev_k_crater dev_k_poses
"""
from roomgen import Room, room, overlay  # noqa: F401


# ═══════════════════════════════════════════════════════════
# 개발용 시험 방 (지도에 나오지 않음 — area "dev")
#   배경·소품 견본 + 적 시험장. 공통 표식: start · mid · e1 · e2 · e_air
# ═══════════════════════════════════════════════════════════

def dev_arena(rid, title, theme, music, dark=0.0):
    r = Room(rid, title, "dev", theme, music, (0, 0), (2, 1), dark)
    F = 19
    r.box(wall=1, floor=r.h - F, ceil=1)
    r.plat(8, 14, F - 4)
    r.plat(64, 70, F - 4)
    r.plat(30, 36, F - 7)
    r.plat(44, 50, F - 7)
    r.add("spawn", id="start", x=6, y=F, face="right")
    r.add("spawn", id="mid", x=40, y=F, face="right")
    r.add("spawn", id="e1", x=50, y=F)
    r.add("spawn", id="e2", x=64, y=F)
    r.add("spawn", id="e_air", x=48, y=F - 8)
    return r, F


@room
def dev_k_city():
    r, F = dev_arena("dev_k_city", "시험장 · 황도 시장", "kingdom", "kingdom")
    r.add("prop", kind="k_stall", x=10, y=F, w=5, goods="bread", col="#a8323a")
    r.add("prop", kind="k_stall", x=22, y=F, w=4, goods="fruit", col="#2e5a8a")
    r.add("prop", kind="k_lamp", x=17, y=F, h=4)
    r.add("prop", kind="k_lamp", x=46, y=F, h=4)
    r.add("prop", kind="k_crates", x=28, y=F, n=3)
    r.add("prop", kind="k_barrel", x=31, y=F, fill="apples")
    r.add("prop", kind="k_barrel", x=32, y=F, fill="water")
    r.add("prop", kind="k_statue_leonie", x=40, y=F)
    r.add("prop", kind="k_fountain", x=54, y=F)
    r.add("prop", kind="k_noticeboard", x=60, y=F)
    r.add("prop", kind="k_cart", x=66, y=F)
    r.add("prop", kind="k_flowers", x=72, y=F, w=3)
    r.add("prop", kind="k_stall", x=75, y=F, w=4, goods="star", col="#4a2a6a")
    r.add("prop", kind="k_sign", x=4, y=F - 9, icon="bread")
    r.add("prop", kind="k_sign", x=58, y=F - 9, icon="sword")
    r.add("prop", kind="k_awning", x=36, y=F - 8, w=3, col="#2e6a5a")
    r.add("prop", kind="k_window", x=26, y=F - 8, w=2, h=2)
    r.add("prop", kind="k_window", x=70, y=F - 9, w=2, h=2, lit=False)
    r.add("prop", kind="k_bunting", x=2, y=2, w=36, sag=2)
    r.add("prop", kind="k_bunting", x=42, y=2, w=36, sag=1.5)
    r.add("prop", kind="k_chimney", x=33, y=F - 7, h=2)
    r.add("prop", kind="k_flag", x=62, y=F - 4, h=5)
    r.add("prop", kind="k_laundry", x=48, y=4, w=10)
    return r


@room
def dev_k_night():
    r, F = dev_arena("dev_k_night", "시험장 · 밤의 황궁 광장", "kingdom_night", "kingdom_night")
    for x in (6, 24, 56, 74):
        r.add("prop", kind="k_lamp", x=x, y=F, h=5)
    r.add("prop", kind="k_statue_lion", x=14, y=F)
    r.add("prop", kind="k_statue_lion", x=66, y=F, flip=True)
    r.add("prop", kind="k_fountain", x=40, y=F)
    r.add("prop", kind="k_flag", x=30, y=F, h=7)
    r.add("prop", kind="k_flag", x=50, y=F, h=7)
    r.add("prop", kind="k_banner", x=20, y=1, w=2, h=5)
    r.add("prop", kind="k_banner", x=60, y=1, w=2, h=5)
    r.add("prop", kind="k_lantern", x=34, y=1, len=3)
    r.add("prop", kind="k_lantern", x=46, y=1, len=3)
    return r


@room
def dev_k_hall():
    r, F = dev_arena("dev_k_hall", "시험장 · 대성당과 연무장", "kingdom_in", "kingdom")
    r.add("prop", kind="k_glass", x=8, y=F - 6, w=3, h=7)
    r.add("prop", kind="k_glass", x=40, y=F - 8, w=4, h=9)
    r.add("prop", kind="k_glass", x=72, y=F - 6, w=3, h=7)
    r.add("prop", kind="k_altar", x=40, y=F)
    r.add("prop", kind="k_candelabra", x=35, y=F)
    r.add("prop", kind="k_candelabra", x=45, y=F)
    r.add("prop", kind="k_pew", x=22, y=F, w=3)
    r.add("prop", kind="k_pew", x=28, y=F, w=3)
    r.add("prop", kind="k_rack", x=56, y=F)
    r.add("prop", kind="k_dummy", x=61, y=F)
    r.add("prop", kind="k_dummy", x=65, y=F)
    r.add("prop", kind="k_forge", x=14, y=F)
    r.add("prop", kind="k_bread", x=76, y=F, w=3, h=3)
    r.add("prop", kind="k_banner", x=18, y=1, w=2, h=6)
    r.add("prop", kind="k_banner", x=52, y=1, w=2, h=6)
    r.add("prop", kind="k_bell", x=30, y=1)
    r.add("prop", kind="k_portcullis", x=70, y=F, w=3, h=5)
    r.add("prop", kind="k_lantern", x=60, y=1, len=2)
    return r


@room
def dev_k_sewer():
    r, F = dev_arena("dev_k_sewer", "시험장 · 하수도", "sewer", "kingdom", dark=0.15)
    r.add("prop", kind="k_pipe", x=1, y=F - 10, w=8, dir="h")
    r.add("prop", kind="k_pipe", x=58, y=F - 12, w=6, dir="h")
    r.add("prop", kind="k_pipe", x=20, y=F, h=8, dir="v", drip=False)
    r.add("prop", kind="k_grate", x=12, y=F, w=3, h=3)
    r.add("prop", kind="k_grate", x=46, y=F - 9, w=2, h=2)
    r.add("prop", kind="k_valve", x=26, y=F - 4)
    r.add("prop", kind="k_cult_circle", x=40, y=F, w=8)
    r.add("prop", kind="k_crystal", x=34, y=F, h=2)
    r.add("prop", kind="k_crystal", x=70, y=F, h=3, col="#6af0e0")
    r.add("prop", kind="k_crates", x=76, y=F, n=2)
    r.add("prop", kind="k_lantern", x=52, y=1, len=2)
    return r


@room
def dev_k_crater():
    r, F = dev_arena("dev_k_crater", "시험장 · 옛 성곽 지구", "starfall", "starbeast")
    r.add("prop", kind="k_meteor", x=40, y=F, w=5, h=3)
    r.add("prop", kind="k_crystal", x=12, y=F, h=3)
    r.add("prop", kind="k_crystal", x=28, y=F, h=2)
    r.add("prop", kind="k_crystal", x=58, y=F, h=4)
    r.add("prop", kind="k_rubble", x=20, y=F, w=4)
    r.add("prop", kind="k_rubble", x=68, y=F, w=5)
    r.add("prop", kind="k_cult_circle", x=40, y=F, w=10)
    r.add("prop", kind="k_statue_lion", x=74, y=F)
    return r


@room
def dev_k_poses():
    """인물 자세 견본: 3배 확대 (k_pose 개체, 머리 위에 자세 이름). 화면마다 4개씩"""
    r = Room("dev_k_poses", "시험장 · 인물 자세", "dev", "kingdom_in", "", (0, 0), (5, 1))
    F = 20
    r.box(wall=1, floor=r.h - F, ceil=1)
    r.add("spawn", id="start", x=3, y=F, face="right")
    poses = ["idle", "run", "windup", "attack", "attack2", "guard",
             "charge", "special", "hurt", "kneel", "down", "walk"]
    x = 6
    for p in poses:
        if p == "walk":
            r.add("k_pose", who="leonie", pose="idle", x=x, y=F, face="right", label="walk(sheathed)", zoom=3, walk=True)
        else:
            r.add("k_pose", who="leonie", pose=p, x=x, y=F, face="right", loop=1.6, label=p, zoom=3)
        x += 10
    r.add("k_pose", who="leonie", pose="guard", x=x, y=F, face="left", label="wood", wood=True, zoom=3)
    x += 10
    for who, p in (("noxis", "idle"), ("noxis", "cast"), ("kael", "idle"), ("k_knight", "idle"), ("k_knight", "attack")):
        r.add("k_pose", who=who, pose=p, x=x, y=F, face="right", loop=1.6, label=who + ":" + p, zoom=3)
        x += 10
    return r
