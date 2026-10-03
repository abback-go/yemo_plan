"""3장 방 (docs/chapter3.md). roomgen.py가 불러온다.
from roomgen import Room, room, overlay — 1장 roomgen.py와 같은 문법.

지금(1단계)은 개발용 시험 방(dev_e_*)만 있다 — 지도·ROOMS에 넣지 않는다.
  dev_e_tree    세계수 마을 배경·소품·인물 전시 (elf, 3×1)
  dev_e_stage   빈 무대 — 인물 자세·초상화 점검 (elf, 3×1)
  dev_e_cave    뿌리 동굴 배경·버섯 퍼즐·적 (elf_deep, 2×1)
  dev_e_blight  흰 역병 배경·역병 덩굴·적 (blight, 2×1)
  dev_e_hunt    사냥 시험 경기장 (elf, 1×3 세로, 가지 횃대)
  dev_e_crown   백색 사도 둥지 (blight, 2×1, 엄호 가지)
  dev_e_border  경계의 숲 저격 구간·바람 밸브·옆바람 시험 (elf, 3×1)
"""
from roomgen import Room, room, overlay  # noqa: F401


def dev_room(rid, title, theme, cells, music=""):
    return Room(rid, title, "dev", theme, music, (0, 0), cells)


def markers(r, F):
    r.add("spawn", id="start", x=4, y=F, face="right")
    r.add("spawn", id="mid", x=r.w // 2, y=F, face="right")
    r.add("spawn", id="e1", x=r.w // 2 + 10, y=F)
    r.add("spawn", id="e2", x=r.w // 2 + 24, y=F)
    r.add("spawn", id="e_air", x=r.w // 2 + 8, y=F - 8)


@room
def dev_e_tree():
    """세계수 마을 전시: 왼쪽 마을 소품 → 가운데 인물 → 오른쪽 숲·활터 소품"""
    r = dev_room("dev_e_tree", "시험장 · 세계수 마을", "elf", (3, 1), "elf")
    F = 19
    r.box(wall=1, floor=4, ceil=1)
    r.clear(1, 1, r.w - 2, 2)
    r.plat(30, 38, F - 6)
    r.plat(84, 92, F - 6)
    markers(r, F)
    # 마을 소품 (왼쪽 화면)
    r.add("prop", kind="seed_house", x=8, y=F, w=4, h=5)
    r.add("prop", kind="round_door", x=16, y=F)
    r.add("prop", kind="round_window", x=16, y=F - 4)
    r.add("prop", kind="leaf_awning", x=16, y=F - 6, w=4)
    r.add("prop", kind="elf_lantern_post", x=20, y=F)
    r.add("prop", kind="market_stall", x=25, y=F, w=4)
    r.add("prop", kind="herb_rack", x=30, y=F)
    r.add("prop", kind="tea_set", x=33, y=F)
    r.add("prop", kind="bench_log", x=37, y=F, w=2)
    r.add("prop", kind="elf_lantern", x=12, y=1, len=3)
    r.add("prop", kind="elf_lantern", x=27, y=1, len=5)
    r.add("prop", kind="elf_banner", x=22, y=1, h=5)
    r.add("prop", kind="wind_chime", x=34, y=1, len=6)
    r.add("prop", kind="hanging_bridge", x=30, y=F - 6, w=8)
    # 인물 (가운데 화면) — 대사 없이 서 있기만
    for i, who in enumerate(["elarien", "ortia", "fio", "tiel", "elf_warden", "elf_a", "elf_b", "elf_c"]):
        r.add("npc", id="n_" + who, who=who, x=44 + i * 4, y=F, face="left" if i % 2 else "right", talk="dev_ch3_silent")
    r.add("prop", kind="spirit_statue", x=78, y=F)
    r.add("prop", kind="loom", x=74, y=F)
    # 숲·활터 (오른쪽 화면)
    r.add("prop", kind="archery_target", x=86, y=F)
    r.add("prop", kind="archery_target", x=90, y=F - 6)
    r.add("prop", kind="bow_rack", x=95, y=F)
    r.add("prop", kind="firefly_jar", x=99, y=F)
    r.add("prop", kind="flower_bed", x=103, y=F, w=3)
    r.add("prop", kind="fern", x=107, y=F)
    r.add("prop", kind="wind_vane", x=110, y=F)
    r.add("prop", kind="hammock", x=114, y=F, w=3)
    r.add("prop", kind="elder_shelf", x=82, y=F, w=2, h=3)
    r.add("prop", kind="eilach_sapling", x=70, y=F, white=0.0)
    r.add("prop", kind="eilach_sapling", x=72, y=F, white=0.6)
    r.add("prop", kind="vine_curtain", x=104, y=1, w=3, h=5)
    return r


@room
def dev_e_stage():
    """빈 무대: 인물 자세·초상화 점검용 (소품 없음)"""
    r = dev_room("dev_e_stage", "시험장 · 무대", "elf", (3, 1), "")
    F = 19
    r.box(wall=1, floor=4, ceil=1)
    r.clear(1, 1, r.w - 2, 2)
    markers(r, F)
    return r


@room
def dev_e_cave():
    r = dev_room("dev_e_cave", "시험장 · 뿌리 동굴", "elf_deep", (2, 1), "")
    F = 19
    r.box(wall=1, floor=4, ceil=2)
    r.plat(10, 16, F - 4)
    r.plat(60, 66, F - 4)
    markers(r, F)
    r.add("prop", kind="mushroom_glow", x=6, y=F, h=1)
    r.add("prop", kind="mushroom_big", x=20, y=F, h=4)
    r.add("prop", kind="mushroom_glow", x=24, y=F, h=1.5)
    r.add("prop", kind="root_arch", x=32, y=F, w=6, h=5)
    r.add("prop", kind="vine_curtain", x=44, y=2, w=4, h=6)
    r.add("prop", kind="moonwell", x=54, y=F, w=5)
    r.add("prop", kind="mushroom_big", x=70, y=F, h=6)
    r.add("prop", kind="fern", x=74, y=F)
    return r


@room
def dev_e_blight():
    r = dev_room("dev_e_blight", "시험장 · 흰 역병", "blight", (2, 1), "")
    F = 19
    r.box(wall=1, floor=4, ceil=1)
    r.clear(1, 1, r.w - 2, 2)
    r.plat(10, 16, F - 4)
    r.plat(60, 66, F - 4)
    markers(r, F)
    r.add("prop", kind="blight_crystal", x=8, y=F, h=1)
    r.add("prop", kind="blight_tree", x=22, y=F, h=6)
    r.add("prop", kind="blight_crystal", x=28, y=F, h=2)
    r.add("prop", kind="blight_growth", x=34, y=F, w=4)
    r.add("prop", kind="blight_tree", x=70, y=F, h=8)
    r.add("prop", kind="blight_crystal", x=74, y=F, h=1.5)
    return r
