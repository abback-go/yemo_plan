"""3장 방 (docs/chapter3.md 8~9절). roomgen.py가 불러온다.
from roomgen import Room, room, overlay — 1장 roomgen.py와 같은 문법.

본편: e_gate ~ e_crown_nest 32방 (아래 "3장 본편" 절) + 학교 덧붙임(overlay).
개발용 시험 방(dev_e_*) — 지도·ROOMS에 넣지 않는다.
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


@room
def dev_e_hunt():
    """사냥 시험 경기장 시험판: 세로 3칸. 4행 간격 가지(통과 발판)를 지그재그로 — 한 번 점프로 오를 수 있다.
    엘라리엔은 꼭대기 횃대(perch_1)에서 시작, 닿을 때마다 세라에게서 먼 횃대로 뛴다."""
    r = dev_room("dev_e_hunt", "시험장 · 사냥 시험", "elf", (1, 3), "elf_hunt")
    F = r.h - 4  # 65
    r.box(wall=1, floor=4, ceil=1)
    r.clear(1, 1, r.w - 2, 2)
    levels = [
        (61, [(4, 12), (27, 35)]),
        (57, [(14, 24)]),
        (53, [(3, 10), (29, 37)]),
        (49, [(13, 21)]),
        (45, [(4, 11), (27, 35)]),
        (41, [(15, 24)]),
        (37, [(3, 9), (30, 37)]),
        (33, [(13, 21)]),
        (29, [(4, 11), (28, 36)]),
        (25, [(15, 23)]),
        (21, [(3, 10), (29, 37)]),
        (17, [(15, 24)]),
    ]
    for y, spans in levels:
        for x0, x1 in spans:
            r.plat(x0, x1, y)
    for i, (x, y) in enumerate([(20, 17), (6, 29), (33, 37), (17, 49), (7, 45), (33, 21)]):
        r.add("spawn", id="perch_%d" % (i + 1), x=x, y=y)
    r.add("spawn", id="start", x=6, y=F, face="right")
    r.add("enemy", id="elarien", kind="elarien_hunt", x=20, y=17, face="left", engaged=False)
    for x, y in ((9, 29), (32, 21), (19, 41)):
        r.add("prop", kind="elf_lantern", x=x, y=y + 1, len=1)
    r.add("prop", kind="vine_curtain", x=34, y=1, w=3, h=6)
    r.add("prop", kind="elf_banner", x=6, y=1, h=6)
    return r


@room
def dev_e_crown():
    """백색 사도 둥지 시험판: 넓은 바닥 + 왼쪽 높은 가지(엘라리엔 엄호 자리 ally)"""
    r = dev_room("dev_e_crown", "시험장 · 사도의 둥지", "blight", (2, 1), "herald")
    F = 19
    r.box(wall=1, floor=4, ceil=1)
    r.clear(1, 1, r.w - 2, 2)
    r.plat(2, 8, 8)
    r.plat(16, 22, F - 5)
    r.plat(58, 64, F - 5)
    r.add("spawn", id="start", x=10, y=F, face="right")
    r.add("spawn", id="ally", x=5, y=8, face="right")
    r.add("enemy", id="herald", kind="white_herald", x=44, y=F, face="left", engaged=False)
    for x, h in ((26, 1.5), (52, 2), (70, 1)):
        r.add("prop", kind="blight_crystal", x=x, y=F, h=h)
    r.add("prop", kind="blight_growth", x=36, y=F, w=5)
    return r


@room
def dev_e_border():
    """장치 시험: 저격 구간(엄폐물 셋) → 바람 밸브·상승 기류·옆바람 → 역병 덩굴 → 빛버섯 순서 퍼즐·뿌리 문 → 달빛 퍼즐 → 활터 과녁"""
    r = dev_room("dev_e_border", "시험장 · 장치", "elf", (3, 1), "elf")
    F = 19
    r.box(wall=1, floor=4, ceil=1)
    r.clear(1, 1, r.w - 2, 2)
    markers(r, F)
    # 저격 구간 (엄폐 바위)
    for x0, x1, h in ((12, 13, 3), (22, 24, 2), (32, 33, 3)):
        r.fill(x0, F - h, x1, F - 1)
    r.plat(40, 44, 5)
    r.add("sniper_cover_arrows", id="snipe", x=3, y=0, w=37, h=23, ox=42, oy=5, done="dev_snipe_done")
    # 바람길
    r.add("wind_valve", id="valve", x=48, y=F, flag="dev_valve")
    r.add("updraft", id="draft", x=52, y=3, w=3, h=16, style="wind", on_if="dev_valve")
    r.add("crosswind", id="cross", x=56, y=7, w=20, h=5, dir=1, on_if="!dev_valve")
    r.plat(50, 57, 3)
    r.add("wind_valve", id="valve2", x=62, y=F, flag="dev_valve2", broken=True, fix_flag="dev_valve2_fixed")
    # 역병 덩굴 + 빛버섯 순서 퍼즐 → 뿌리 문
    r.add("blight_vine", id="vine", x=80, y=F - 5, w=2, h=5, hp=3)
    for i, (x, o, s) in enumerate(((86, 2, 1.0), (90, 3, 1.4), (94, 1, 0.7))):
        r.add("glow_mushroom", id="gm%d" % i, x=x, y=F, group="dm", order=o, size=s, done_flag="dev_mush")
    r.add("puzzle", id="pz", group="dm", mode="order", done_flag="dev_mush")
    r.add("root_gate", id="rg", x=98, y=F - 5, w=1, h=5, open_if="dev_mush")
    # 달빛 퍼즐
    r.add("moon_crystal", id="mc", x=104, y=1, group="moon", done_flag="dev_moon")
    r.add("moon_drop", id="md", x=104, y=5)
    r.add("puzzle", id="pz2", group="moon", mode="all", done_flag="dev_moon")
    # 활터
    r.add("archery_mark", id="am1", x=110, y=F, active_if="dev_arch")
    r.add("archery_mark", id="am2", x=115, y=8, hang=True, dy=2, active_if="dev_arch")
    return r


# ═══════════════════════════════════════════════════════════
# 3장 본편 — 엘프의 숲 · 세계수 에일라흐 (docs/chapter3.md 8절 지도·9절 방별 설계)
#   지도 영역 "elf". 아래(경계의 숲·뿌리 마을·동굴) → 줄기·바람길 → 가지·흰 역병 → 수관 → 꼭대기.
#   1칸 방 바닥 윗면 19행·좌우 출구 14~18행, 2칸 높이 방 바닥 42행, 3칸 높이 65행.
#   장의 게이트는 지형이 아니라 개체로: 문 잠금(lock) · 뿌리 문(root_gate) · 역병 덩굴(blight_vine) · 바람(updraft on_if)
# ═══════════════════════════════════════════════════════════
AREA = "elf"


def elf(rid, title, cell, cells, theme="elf", music="elf", dark=0.0, ceil=1, floor=4):
    r = Room(rid, title, AREA, theme, music, cell, cells, dark)
    r.box(wall=1, floor=floor, ceil=ceil)
    return r


def lanterns(r, xs, y=1, ln=2):
    for i, x in enumerate(xs):
        r.add("prop", kind="elf_lantern", x=x, y=y, len=ln + (i % 3))


def ferns(r, xs, y):
    for x in xs:
        r.add("prop", kind="fern", x=x, y=y)


def shrooms(r, spots):
    """(x, y, h) — h ≥ 3이면 큰 버섯"""
    for x, y, h in spots:
        r.add("prop", kind="mushroom_big" if h >= 3 else "mushroom_glow", x=x, y=y, h=h)


def blight(r, spots):
    """(종류, x, y, 크기) — 흰 역병 소품"""
    for k, x, y, s in spots:
        if k == "crystal":
            r.add("prop", kind="blight_crystal", x=x, y=y, h=s)
        elif k == "tree":
            r.add("prop", kind="blight_tree", x=x, y=y, h=s)
        else:
            r.add("prop", kind="blight_growth", x=x, y=y, w=s)


def stone(r, sid, x, y):
    r.add("pickup", id=sid, kind="stone", x=x, y=y, name="마도석")


def note(r, nid, x, y, title, text):
    r.add("pickup", id=nid, kind="note", x=x, y=y, name=title, text=text)


def item(r, iid, x, y, name, flag, text):
    r.add("pickup", id=iid, kind="key", x=x, y=y, name=name, flag=flag, text=text)


# 퀘스트 모으기 세기 (quest_counter): 종류 → (퀘스트, 플래그들, 다 모이면 단계, 알림 이름)
COUNTERS = {
    "seed": ("e_fio_seeds", ["e_seed_%d" % i for i in range(1, 6)], 1, "반짝이 씨앗"),
    "moss": ("e_pippa_moss", ["e_moss_%d" % i for i in range(1, 4)], 1, "빛이끼 표본"),
    "valve": ("e_tiel_valve", ["e_valve_fix_%d" % i for i in range(1, 4)], 1, "고친 밸브"),
    "tea": ("e_ortia_tea", ["e_tea_leaf", "e_tea_dew"], 1, "차 재료"),
    "honey": ("e_honey", ["e_honey_got"], 1, ""),
}


def counter(r, kind):
    """방마다 종류별로 하나만"""
    key = "_ctr_" + kind
    if getattr(r, key, False):
        return
    setattr(r, key, True)
    q, flags, step, label = COUNTERS[kind]
    r.add("quest_counter", id="qc_" + kind, quest=q, flags=flags, step=step, label=label)


def seed(r, n, x, y):
    """피오의 반짝이 씨앗 (e_fio_seeds) — 퀘스트를 받기 전에 주워도 센다"""
    item(r, "seed_%d" % n, x, y, "반짝이 씨앗", "e_seed_%d" % n, "손바닥 위에서 별처럼 깜빡이는 씨앗. 피오가 찾던 거다.")
    counter(r, "seed")


def moss(r, n, x, y):
    """피피의 빛이끼 표본 (e_pippa_moss)"""
    item(r, "moss_%d" % n, x, y, "빛이끼 표본", "e_moss_%d" % n, "축축한 뿌리에서 살살 떼어 낸 빛이끼. 피피가 좋아하겠다.")
    counter(r, "moss")


def rocks(r, F, spans):
    """엄폐 바위·쓰러진 나무 (x0, x1, 높이) — 저격 구간의 숨을 곳"""
    for x0, x1, h in spans:
        r.fill(x0, F - h, x1, F - 1)


SONG1 = ("엘프 노래 가사 · 첫째 장",
         "뿌리는 깊이, 가지는 높이.|세계수 에일라흐는 하늘의 상처를 덮으려 자랐다네.|"
         "하얀 것들이 별 너머에서 내려오던 밤, 나무는 처음으로 잎을 떨궜지.")
SONG2 = ("엘프 노래 가사 · 둘째 장",
         "불을 든 마녀가 숲에 왔네. 태우지 않는 불, 잠재우는 불.|"
         "마녀는 굳은 가지에 손을 얹고 웃었지. \"나무야, 조금만 자거라.\"|"
         "그 봄에 숲은 다시 초록이 되었다네.")
SONG3 = ("엘프 노래 가사 · 셋째 장",
         "마녀에겐 두 제자가 있었네. 하나는 별을 세고, 하나는 별을 지켰지.|"
         "별을 세던 아이는 밤마다 하늘 너머를 오래 올려다봤다네.|"
         "…그 아이는 끝내, 별이 되고 싶어 했다지.")


# ─── 학교 덧붙임 (3장 아침·편지·결투 대회·밤) ─────────────
overlay("s_greenhouse", "prop", kind="eilach_sapling", x=22, y=19, white=0.6, cond="e_start,!e_herald_done")
overlay("s_greenhouse", "prop", kind="eilach_sapling", x=22, y=19, white=0.0, cond="e_herald_done")
overlay("s_greenhouse", "spawn", id="ch3", x=16, y=19, face="right")
overlay("s_greenhouse", "npc", id="pippa_gh", who="pippa", x=27, y=19, face="left", cond="e_start,!ch3_done")
overlay("s_headmaster", "trigger", id="t_ch3", x=8, y=11, w=3, h=8, run="e_headmaster", cond="e_start,!e_letter")
overlay("s_courtyard", "npc", id="isolde_ch3", who="isolde", x=60, y=19, face="left", cond="e_start,!s_duel_won")
overlay("s_dorm", "spawn", id="ch3_night", x=20, y=19, face="right")


# ─── 입구 · 경계의 숲 ───────────────────────────────────

@room
def e_gate():
    """숲 입구 야영지: 전이진·기록. 오른쪽으로 경계의 숲"""
    r = elf("e_gate", "엘프의 숲 · 숲 입구", (0, 8), (1, 1))
    F = 19
    r.exit_right("east", F - 5, F - 1, "e_border_1", "west")
    r.add("warp", id="warp_circle", x=10, y=F, area="elf")
    r.add("spawn", id="warp", x=10, y=F, face="right")
    r.add("spawn", id="start", x=6, y=F, face="right")
    r.add("save", id="camp", x=22, y=F, style="candle")
    r.fill(31, F - 1, 34, F - 1)
    r.add("prop", kind="spirit_statue", x=3, y=F)
    r.add("prop", kind="flower_bed", x=14, y=F, w=2)
    r.add("prop", kind="bench_log", x=18, y=F, w=2)
    r.add("prop", kind="elf_lantern_post", x=25, y=F)
    ferns(r, (28, 37), F)
    r.add("prop", kind="root_arch", x=36, y=F, w=5, h=7)
    r.add("prop", kind="vine_curtain", x=30, y=1, w=3, h=5)
    r.add("prop", kind="wind_chime", x=20, y=1, len=4)
    r.add("prop", kind="elf_lantern", x=8, y=1, len=4)
    r.add("sign", x=27, y=F, look="stone", text="세계수 에일라흐의 숲.|이 너머는 엘프의 땅. 장로의 허락 없이 들어오지 말 것.|…(아래에 작은 글씨) 마녀는 특히.")
    return r


@room
def e_border_1():
    """경계의 숲 1: 경고 사격(모자) → 저격 구간. 바위·쓰러진 나무 다섯 뒤로 숨으며 전진. 높은 가지에 마도석(노출됨)"""
    r = elf("e_border_1", "엘프의 숲 · 경계의 숲", (1, 8), (2, 1))
    F = 19
    r.exit_left("west", F - 5, F - 1, "e_gate", "east")
    r.exit_right("east", F - 5, F - 1, "e_border_2", "west")
    rocks(r, F, ((16, 17, 3), (28, 30, 3), (40, 41, 4), (52, 54, 3), (64, 65, 3)))
    r.plat(33, 37, F - 7)
    stone(r, "stone_border1", 35, F - 7)
    r.plat(70, 78, 5)
    r.add("sniper_cover_arrows", id="snipe", x=8, y=0, w=60, h=23, ox=75, oy=5, done="e_border_passed", first="e_snipe_seen")
    r.add("trigger", id="t_warn", x=4, y=F - 8, w=2, h=8, run="e_warning_shot", cond="!e_hat")
    r.add("event", id="ev_snipe", flag="e_snipe_seen", run="e_snipe_teach", done="e_snipe_taught")
    ferns(r, (15, 27, 39, 51, 63), F)
    r.add("prop", kind="vine_curtain", x=22, y=1, w=3, h=6)
    r.add("prop", kind="vine_curtain", x=58, y=1, w=4, h=5)
    r.add("prop", kind="root_arch", x=46, y=F, w=4, h=5)
    shrooms(r, ((9, F, 1), (24, F, 1.2), (60, F, 1)))
    r.add("prop", kind="fern", x=72, y=5)
    return r


@room
def e_border_2():
    """경계의 숲 2: 가운데 높은 가지의 사수(엄폐 셋) → 둔덕 위 파수꾼(비살상, 첫 대면)"""
    r = elf("e_border_2", "엘프의 숲 · 경계의 숲", (3, 8), (2, 1))
    F = 19
    r.exit_left("west", F - 5, F - 1, "e_border_1", "east")
    r.exit_right("east", F - 5, F - 1, "e_border_3", "west")
    rocks(r, F, ((10, 11, 3), (20, 22, 3), (31, 33, 4)))
    r.plat(42, 50, 6)
    r.add("sniper_cover_arrows", id="snipe", x=2, y=0, w=38, h=23, ox=46, oy=6, done="e_border_passed")
    r.fill(52, F - 1, 53, F - 1)
    r.fill(54, F - 2, 70, F - 1)
    r.add("enemy", id="warden1", kind="elf_warden", x=63, y=F - 2, face="left", cond="!e_border_passed")
    r.add("trigger", id="t_warden", x=47, y=F - 8, w=2, h=8, run="e_warden_seen", cond="!e_border_passed")
    ferns(r, (9, 19, 30, 56, 74), F)
    r.add("prop", kind="vine_curtain", x=26, y=1, w=3, h=5)
    r.add("prop", kind="elf_banner", x=60, y=1, h=5)
    r.add("prop", kind="root_arch", x=74, y=F, w=5, h=6)
    shrooms(r, ((15, F, 1), (37, F, 1.4), (68, F - 2, 1)))
    r.add("sign", x=50, y=F, look="stone", text="경고.|여기서부터 세계수 파수대의 눈이 닿는다.|돌아갈 길은 뒤에 있다.")
    return r


@room
def e_border_3():
    """경계의 숲 3: 처음 보는 흰 역병(포자 덩어리 둘), 순한 이끼 사슴, 둘째 파수꾼.
    오른쪽 위 턱의 환영 벽 뒤 감실 — 노래 가사 첫째 장·마도석"""
    r = elf("e_border_3", "엘프의 숲 · 하얀 얼룩", (5, 8), (2, 1))
    F = 19
    r.exit_left("west", F - 5, F - 1, "e_border_2", "east")
    r.exit_right("east", F - 5, F - 1, "e_border_4", "west")
    r.fill(12, F - 2, 18, F - 1)
    r.fill(14, F - 3, 16, F - 3)
    r.plat(26, 32, F - 5)
    r.plat(52, 58, F - 4)
    r.plat(58, 62, 11)
    # 감실: 바닥 8행, 왼쪽 환영 벽
    r.fill(64, 8, 78, 9)
    r.fill(68, 3, 78, 3)
    r.fill(68, 4, 68, 7, "I")
    stone(r, "stone_border3", 71, 8)
    note(r, "note_song1", 75, 8, *SONG1)
    r.add("enemy", id="spore1", kind="blight_spore", x=24, y=F, face="left")
    r.add("enemy", id="spore2", kind="blight_spore", x=46, y=F, face="left")
    r.add("enemy", id="warden2", kind="elf_warden", x=38, y=F, face="left", cond="!e_border_passed")
    r.add("enemy", id="stag0", kind="moss_stag", x=66, y=F, face="left")
    r.add("trigger", id="t_blight", x=19, y=F - 8, w=2, h=8, run="e_blight_first")
    blight(r, (("growth", 22, F, 3), ("crystal", 27, F, 1), ("crystal", 44, F, 1.5), ("growth", 48, F, 2), ("tree", 34, F, 5)))
    ferns(r, (6, 10, 56, 74), F)
    r.add("prop", kind="vine_curtain", x=50, y=1, w=3, h=5)
    r.add("prop", kind="elf_lantern", x=73, y=4, len=1)
    shrooms(r, ((60, F, 1.2), (70, F, 3)))
    return r


@room
def e_border_4():
    """뿌리 문: 거목 뿌리가 얽힌 마을 입구. 파수꾼 둘. 엘라리엔이 편지를 확인하면 뿌리가 물러난다(e_border_passed)"""
    r = elf("e_border_4", "엘프의 숲 · 뿌리 문", (7, 8), (1, 1))
    F = 19
    r.exit_left("west", F - 5, F - 1, "e_border_3", "east")
    r.exit_right("east", F - 5, F - 1, "e_roots", "west")
    r.fill(30, 1, 31, F - 7)
    r.add("root_gate", id="rg", x=30, y=F - 6, w=2, h=6, open_if="e_border_passed")
    r.add("npc", id="warden_a", who="warden_a", x=26, y=F, face="left")
    r.add("npc", id="warden_b", who="warden_b", x=35, y=F, face="left")
    r.add("trigger", id="t_gate", x=18, y=F - 8, w=2, h=8, run="e_border_gate", cond="!e_border_passed")
    r.add("prop", kind="spirit_statue", x=12, y=F)
    r.add("prop", kind="elf_lantern_post", x=23, y=F)
    r.add("prop", kind="elf_lantern_post", x=38, y=F)
    r.add("prop", kind="elf_banner", x=27, y=1, h=6)
    r.add("prop", kind="elf_banner", x=34, y=1, h=6)
    r.add("prop", kind="round_window", x=31, y=6, r=2)
    ferns(r, (4, 9, 16), F)
    r.add("prop", kind="flower_bed", x=33, y=F, w=2)
    return r


# ─── 뿌리 마을 ──────────────────────────────────────────

@room
def e_roots():
    """뿌리 마을 (거점): 아래층 길(장로의 집·기록·뿌리 동굴 계단), 가운데 뿌리 둔덕(승강기 — 바람길을 고치면 움직임),
    오른쪽 위 뿌리 선반(피오네 집·씨앗)"""
    r = elf("e_roots", "세계수 · 뿌리 마을", (8, 7), (3, 2))
    F = r.h - 4  # 42
    r.exit_left("west", F - 5, F - 1, "e_border_4", "east")
    r.add("save", id="roots", x=20, y=F, style="candle")
    r.door("elder", 36, F, "e_elder_hall", "door", style="grand", label="장로의 집")
    # 뿌리 둔덕 + 승강기
    r.fill(46, F - 3, 64, F - 1)
    r.fill(50, F - 6, 60, F - 4)
    r.door("lift", 55, F - 6, "e_trunk_lift", "bottom", style="iron", label="세계수 승강기", lock="e_lift_fixed",
           lock_msg="승강기가 멈춰 있다. 줄기 위쪽의 바람길이 막혀 바람이 내려오지 않는다고 한다.")
    # 오른쪽 위 뿌리 선반
    r.plat(62, 66, 33)
    r.fill(68, 30, 104, 31)
    r.door("homes", 88, 30, "e_roots_homes", "door", style="wood", label="피오네 집")
    seed(r, 1, 101, 30)
    r.door("cave", 112, F, "e_cave_1", "up", style="stair_down", label="뿌리 동굴")
    # 사람들
    r.add("npc", id="fio", who="fio", x=41, y=F, face="left", cond="!e_fio_gone")
    r.add("npc", id="elf_a", who="elf_a", x=27, y=F, face="right", talk="npc_e_roots_a")
    r.add("npc", id="elf_b", who="elf_b", x=48, y=F - 3, face="left", talk="npc_e_roots_b")
    r.add("npc", id="elf_c", who="elf_c", x=106, y=F, face="left", talk="npc_e_roots_c")
    r.add("npc", id="elf_warden", who="elf_warden", x=116, y=F, face="left", talk="npc_e_roots_warden")
    # 소품
    r.add("prop", kind="spirit_statue", x=4, y=F)
    r.add("prop", kind="flower_bed", x=8, y=F, w=3)
    r.add("prop", kind="bench_log", x=14, y=F, w=2)
    r.add("prop", kind="market_stall", x=24, y=F, w=4)
    r.add("prop", kind="herb_rack", x=30, y=F)
    r.add("prop", kind="round_window", x=31, y=F - 8, r=2)
    r.add("prop", kind="leaf_awning", x=36, y=F - 6, w=4)
    r.add("prop", kind="round_window", x=42, y=F - 8, r=2)
    r.add("prop", kind="tea_set", x=44, y=F)
    r.add("prop", kind="elf_lantern_post", x=52, y=F - 6)
    r.add("prop", kind="elf_lantern_post", x=59, y=F - 6)
    r.add("prop", kind="seed_house", x=74, y=30, w=4, h=5)
    r.add("prop", kind="leaf_awning", x=88, y=24, w=4)
    r.add("prop", kind="round_window", x=82, y=26, r=2)
    r.add("prop", kind="seed_house", x=97, y=30, w=3, h=4)
    r.add("prop", kind="elf_banner", x=70, y=32, h=4)
    r.add("prop", kind="hammock", x=78, y=F, w=3)
    r.add("prop", kind="loom", x=92, y=F)
    r.add("prop", kind="firefly_jar", x=98, y=F)
    r.add("prop", kind="wind_chime", x=84, y=32, len=3)
    r.add("prop", kind="root_arch", x=112, y=F, w=6, h=7)
    r.add("prop", kind="hanging_bridge", x=104, y=30, w=10, sag=2)
    lanterns(r, (10, 22, 34, 46, 62, 72, 96, 110), y=1, ln=3)
    ferns(r, (66, 86, 102, 118), F)
    r.add("sign", x=16, y=F, look="board", text="뿌리 마을 알림판|· 흰 얼룩(역병)이 묻은 열매는 먹지 말 것.|· 승강기 고장. 줄기 시장엔 뿌리 동굴로 돌아서 갈 것.|· 아이들은 꼭대기 쪽 가지에 올라가지 말 것! — 장로")
    return r


@room
def e_elder_hall():
    """장로의 집: 거목 뿌리 속 둥근 방. 오르티아 장로"""
    r = elf("e_elder_hall", "세계수 · 장로의 집", (11, 8), (1, 1), ceil=2)
    F = 19
    r.door("door", 5, F, "e_roots", "elder", style="wood", label="뿌리 마을")
    r.add("npc", id="ortia", who="ortia", x=27, y=F, face="left")
    r.add("prop", kind="elder_shelf", x=12, y=F, w=3, h=5)
    r.add("prop", kind="elder_shelf", x=35, y=F, w=2, h=4)
    r.add("prop", kind="tea_set", x=31, y=F)
    r.add("prop", kind="herb_rack", x=18, y=F)
    r.add("prop", kind="round_window", x=22, y=9, r=3)
    r.add("prop", kind="spirit_statue", x=8, y=F)
    r.add("prop", kind="firefly_jar", x=24, y=F)
    r.add("prop", kind="elf_banner", x=30, y=2, h=5)
    r.add("prop", kind="eilach_sapling", x=33, y=F, white=0.0)
    lanterns(r, (16, 26), y=2, ln=2)
    return r


@room
def e_roots_homes():
    """피오네 집: 피오의 엄마, 씨앗 하나 (선반 위)"""
    r = elf("e_roots_homes", "세계수 · 피오네 집", (11, 7), (1, 1), ceil=2)
    F = 19
    r.door("door", 5, F, "e_roots", "homes", style="wood", label="뿌리 마을")
    r.add("npc", id="fio_mom", who="fio_mom", x=22, y=F, face="left")
    r.plat(28, 35, F - 5)
    seed(r, 2, 33, F - 5)
    r.add("prop", kind="hammock", x=12, y=F, w=3)
    r.add("prop", kind="loom", x=17, y=F)
    r.add("prop", kind="tea_set", x=26, y=F)
    r.add("prop", kind="round_window", x=20, y=9, r=2)
    r.add("prop", kind="flower_bed", x=36, y=F, w=2)
    r.add("prop", kind="firefly_jar", x=30, y=F - 5)
    lanterns(r, (14, 24), y=2, ln=2)
    r.add("sign", x=9, y=F, look="note", text="벽에 삐뚤빼뚤 그린 그림|엘라리엔 언니(활), 피오(더 큼), 별, 별, 별.|아래에 엄마 글씨: \"벽에 그리지 말라고 했지!\"")
    return r


# ─── 뿌리 동굴 ──────────────────────────────────────────

@room
def e_cave_1():
    """뿌리 동굴 1: 어둠 속 빛버섯 셋 — 작은 것부터 순서대로 밝히면(order) 뿌리 문이 물러난다. 빛이끼 하나, 순한 사슴"""
    r = elf("e_cave_1", "세계수 · 뿌리 동굴", (8, 9), (2, 1), theme="elf_deep", dark=0.45, ceil=2)
    F = 19
    r.door("up", 4, F, "e_roots", "cave", style="stair_up", label="뿌리 마을")
    r.exit_right("east", F - 5, F - 1, "e_cave_2", "west")
    r.fill(1, 2, 18, 3)
    r.fill(22, 2, 38, 4)
    for i, (x, o, s) in enumerate(((14, 2, 1.0), (26, 3, 1.5), (35, 1, 0.6))):
        r.add("glow_mushroom", id="gm%d" % (i + 1), x=x, y=F, group="cave1", order=o, size=s, done_flag="e_cave_mush")
    r.add("puzzle", id="pz", group="cave1", mode="order", done_flag="e_cave_mush")
    r.add("event", id="ev_mush", flag="e_cave_mush", run="e_cave_mush_done", done="e_cave_mush_seen")
    r.fill(46, 2, 47, F - 7)
    r.add("root_gate", id="rg", x=46, y=F - 6, w=2, h=6, open_if="e_cave_mush")
    r.add("trigger", id="t_dark", x=8, y=F - 8, w=2, h=8, run="e_cave_dark", cond="!e_cave_mush")
    r.add("sign", x=20, y=F, look="stone", text="버섯지기의 낙서|아기 버섯부터 깨워라. 큰 버섯은 잠꾸러기.|(순서가 틀리면 다들 다시 잠든다)")
    r.fill(54, F - 2, 60, F - 1)
    r.plat(62, 68, F - 5)
    moss(r, 1, 66, F - 5)
    r.add("enemy", id="stag_calm", kind="moss_stag", x=72, y=F, face="left")
    shrooms(r, ((6, F, 1), (31, F, 3), (42, F, 1), (52, F, 4), (75, F, 1.2)))
    r.add("prop", kind="root_arch", x=58, y=F - 2, w=5, h=6)
    r.add("prop", kind="vine_curtain", x=64, y=2, w=3, h=6)
    ferns(r, (49, 70), F)
    return r


@room
def e_cave_2():
    """뿌리 동굴 2: 역병 든 이끼 사슴(쓰러뜨리면 정화), 포자. 왼쪽 위 턱의 환영 벽 뒤 → 숨은 빈터(e_hollow)"""
    r = elf("e_cave_2", "세계수 · 뿌리 동굴", (10, 9), (2, 1), theme="elf_deep", dark=0.35, ceil=2)
    F = 19
    r.exit_left("west", F - 5, F - 1, "e_cave_1", "east")
    r.exit_right("east", F - 5, F - 1, "e_cave_3", "west")
    r.fill(18, F - 2, 26, F - 1)
    r.plat(16, 22, 14)
    r.fill(1, 10, 14, 11)
    r.fill(1, 5, 11, 5)
    r.fill(11, 6, 11, 9, "I")
    r.door("hollow", 5, 10, "e_hollow", "door", style="wood", label="뿌리 틈")
    r.plat(32, 38, F - 5)
    r.fill(48, F - 3, 52, F - 1)
    r.plat(60, 66, F - 6)
    r.add("enemy", id="stag1", kind="moss_stag", x=40, y=F, face="left", blighted=True)
    r.add("enemy", id="spore1", kind="blight_spore", x=58, y=F, face="left")
    r.add("trigger", id="t_stag", x=28, y=F - 8, w=2, h=8, run="e_stag_teach")
    shrooms(r, ((24, F - 2, 1), (44, F, 3), (70, F, 1.4), (76, F, 4)))
    blight(r, (("crystal", 55, F, 1), ("growth", 62, F, 2)))
    r.add("prop", kind="vine_curtain", x=28, y=2, w=4, h=6)
    r.add("prop", kind="root_arch", x=6, y=F, w=5, h=6)
    return r


@room
def e_hollow():
    """숨은 빈터: 여우창문으로만 찾는 뿌리 틈 안쪽. 달빛이 새는 작은 샘 — 마도석·노래 가사 둘째 장·빛이끼"""
    r = elf("e_hollow", "세계수 · 숨은 빈터", (10, 10), (1, 1), theme="elf_deep", dark=0.25, ceil=2)
    F = 19
    r.door("door", 4, F, "e_cave_2", "hollow", style="wood", label="뿌리 동굴")
    r.plat(12, 18, F - 4)
    r.plat(22, 28, F - 7)
    stone(r, "stone_hollow", 25, F - 7)
    note(r, "note_song2", 34, F, *SONG2)
    moss(r, 3, 15, F - 4)
    r.add("prop", kind="moonwell", x=28, y=F, w=5)
    shrooms(r, ((9, F, 1), (20, F, 3), (37, F, 1.3)))
    r.add("prop", kind="vine_curtain", x=30, y=2, w=4, h=5)
    r.add("light", x=28, y=3, r=5, color="#9ab8ff")
    return r


@room
def e_cave_3():
    """뿌리 굴 (세로 3칸): 지그재그 뿌리 발판(4칸 간격)으로 오른다. 덩굴 사냥꾼 둘. 오른쪽 감실(환영 벽) 깃털, 왼쪽 마도석.
    꼭대기 오른쪽 턱 → 줄기 시장"""
    r = elf("e_cave_3", "세계수 · 뿌리 굴", (12, 7), (1, 3), theme="elf_deep", dark=0.3, ceil=2)
    F = r.h - 4  # 65
    r.exit_left("west", F - 5, F - 1, "e_cave_2", "east")
    r.exit_right("east", 8, 12, "e_trunk_market", "west")
    for x0, x1, y in ((24, 31, 61), (12, 21, 57), (2, 9, 53), (12, 21, 49), (24, 31, 45), (12, 21, 41), (2, 9, 37),
                      (12, 19, 33), (12, 19, 25), (2, 9, 21), (12, 19, 17)):
        r.plat(x0, x1, y)
    r.fill(26, 53, 38, 54)
    r.fill(24, 29, 31, 30)
    r.fill(26, 37, 38, 38)
    r.fill(29, 32, 38, 32)
    r.fill(29, 33, 29, 36, "I")
    r.add("pickup", id="feather_cave", kind="feather", x=35, y=37, name="수호의 깃털", text="최대 체력이 1 늘었다.")
    r.fill(24, 13, 38, 14)
    stone(r, "stone_cave3", 4, 21)
    moss(r, 2, 36, 53)
    r.add("enemy", id="stalker1", kind="vine_stalker", x=32, y=53, face="left")
    r.add("enemy", id="stalker2", kind="vine_stalker", x=28, y=29, face="left")
    shrooms(r, ((6, F, 3), (34, F, 1), (4, 53, 1), (30, 45, 1), (14, 33, 1), (36, 13, 1.4)))
    r.add("prop", kind="vine_curtain", x=34, y=15, w=3, h=7)
    r.add("prop", kind="vine_curtain", x=4, y=40, w=3, h=6)
    r.add("prop", kind="root_arch", x=20, y=F, w=6, h=6)
    r.add("light", x=33, y=34, r=3, color="#5affd0")
    return r


# ─── 줄기 ───────────────────────────────────────────────

@room
def e_trunk_market():
    """줄기 시장: 줄기 둘레의 장터. 승강기 문(고장)·티엘의 공방·바람길 계단(티엘을 만나야 열림). 위층 지붕 길에 씨앗"""
    r = elf("e_trunk_market", "세계수 · 줄기 시장", (13, 7), (3, 1))
    F = 19
    r.exit_left("west", F - 5, F - 1, "e_cave_3", "east")
    r.door("lift", 14, F, "e_trunk_lift", "mid", style="iron", label="세계수 승강기", lock="e_lift_fixed",
           lock_msg="승강기가 멈춰 있다. \"바람길이 막혀서 바람이 안 내려와.\" — 누군가 써 붙인 쪽지")
    r.add("save", id="market", x=56, y=F, style="candle")
    r.door("workshop", 100, F, "e_workshop", "door", style="wood", label="티엘의 공방")
    r.door("wind", 114, F, "e_wind_1", "bottom", style="stair_up", label="바람길", lock="e_met_tiel",
           lock_msg="바람길 입구. 바람이 거꾸로 불어 올라갈 수가 없다. 바람길 장인을 먼저 만나 보자.")
    r.fill(20, F - 2, 22, F - 1)
    r.plat(24, 34, 14)
    r.plat(38, 48, 11)
    r.plat(64, 76, 14)
    seed(r, 3, 43, 11)
    r.add("npc", id="elf_a", who="elf_a", x=30, y=F, face="right", talk="npc_e_market_a")
    r.add("npc", id="elf_c", who="elf_c", x=70, y=F, face="left", talk="npc_e_market_c")
    r.add("npc", id="warden_b", who="warden_b", x=110, y=F, face="left")
    r.add("trigger", id="t_market", x=6, y=F - 8, w=2, h=8, run="e_market_arrive")
    for x, w in ((28, 4), (44, 4), (66, 5), (80, 4)):
        r.add("prop", kind="market_stall", x=x, y=F, w=w)
    r.add("prop", kind="herb_rack", x=36, y=F)
    r.add("prop", kind="tea_set", x=50, y=F)
    r.add("prop", kind="bench_log", x=60, y=F, w=2)
    r.add("prop", kind="bow_rack", x=86, y=F)
    r.add("prop", kind="loom", x=90, y=F)
    r.add("prop", kind="firefly_jar", x=94, y=F)
    r.add("prop", kind="leaf_awning", x=100, y=F - 6, w=4)
    r.add("prop", kind="round_window", x=105, y=F - 7, r=2)
    r.add("prop", kind="seed_house", x=8, y=F, w=4, h=5)
    r.add("prop", kind="hanging_bridge", x=48, y=11, w=16, sag=3)
    r.add("prop", kind="elf_banner", x=58, y=1, h=6)
    r.add("prop", kind="wind_chime", x=112, y=1, len=6)
    lanterns(r, (18, 32, 52, 70, 88, 104), y=1, ln=3)
    r.add("sign", x=62, y=F, look="board", text="줄기 시장|오늘의 물건: 달잎 차, 꿀떡, 화살깃, 바람 밸브 기름.|※ 바람길 고장으로 승강기 쉼. 불편을 드려 죄송합니다. — 티엘")
    return r


@room
def e_workshop():
    """티엘의 공방: 바람길 장인 티엘. 시범용 밸브(불로 돌리면 바람 방향이 바뀌는 걸 보여 줌)"""
    r = elf("e_workshop", "세계수 · 티엘의 공방", (16, 7), (1, 1), ceil=2)
    F = 19
    r.door("door", 5, F, "e_trunk_market", "workshop", style="wood", label="줄기 시장")
    r.add("npc", id="tiel", who="tiel", x=24, y=F, face="left")
    r.add("wind_valve", id="demo", x=12, y=F, flag="e_ws_demo")
    r.add("updraft", id="demo_up", x=15, y=7, w=3, h=12, style="wind", power=0.8, on_if="e_ws_demo")
    r.add("crosswind", id="demo_side", x=15, y=9, w=10, h=4, dir=1, power=0.6, on_if="!e_ws_demo")
    r.plat(30, 37, 12)
    r.add("prop", kind="wind_vane", x=33, y=12)
    r.add("prop", kind="wind_vane", x=36, y=F)
    r.add("prop", kind="elder_shelf", x=31, y=F, w=2, h=4)
    r.add("prop", kind="loom", x=20, y=F)
    r.add("prop", kind="firefly_jar", x=28, y=F)
    r.add("prop", kind="wind_chime", x=22, y=2, len=4)
    r.add("prop", kind="round_window", x=26, y=8, r=2)
    lanterns(r, (9, 34), y=2, ln=2)
    r.add("sign", x=8, y=F, look="board", text="티엘의 공방|바람 밸브 사용법: 불로 데우면 한 칸 돈다.|위 화살표 = 위로 부는 바람. 옆 화살표 = 옆으로 부는 바람.|고장 난 밸브는 세 번 데울 것. (네 번은 안 됨! 녹음)")
    return r


@room
def e_trunk_lift():
    """세계수 승강기 굴 (세로 3칸): 고친 뒤(e_lift_fixed) 가운데 바람 기둥이 켜져, 불꽃 날개로 활공하면 오르내린다.
    아래 뿌리 마을 · 가운데 줄기 시장 · 위 가지 마을"""
    r = elf("e_trunk_lift", "세계수 · 승강기 굴", (10, 4), (1, 3))
    F = r.h - 4  # 65
    r.door("bottom", 6, F, "e_roots", "lift", style="iron", label="뿌리 마을")
    r.fill(24, 42, 38, 43)
    r.door("mid", 33, 42, "e_trunk_market", "lift", style="iron", label="줄기 시장")
    r.fill(1, 8, 12, 9)
    r.door("top", 6, 8, "e_branch_homes", "lift", style="iron", label="가지 마을")
    r.add("updraft", id="lift", x=16, y=10, w=5, h=55, style="wind", power=1.3, on_if="e_lift_fixed")
    r.plat(26, 32, 26)
    r.plat(2, 8, 34)
    r.add("prop", kind="wind_vane", x=10, y=8)
    r.add("prop", kind="wind_chime", x=28, y=44, len=4)
    r.add("prop", kind="elf_banner", x=36, y=1, h=7)
    lanterns(r, (4, 24, 34), y=10, ln=2)
    r.add("sign", x=10, y=F, look="board", text="세계수 승강기|바람이 오면 날개를 펴고 몸을 맡기시오.|(불꽃 날개: 공중에서 Z를 다시 누르고 있기)")
    return r


# ─── 바람길 ─────────────────────────────────────────────

@room
def e_wind_1():
    """바람길 1 (2×2): ① 밸브 A — 옆바람 ↔ 상승 기류, 가운데 턱으로 ② 밸브 B — 꼭대기 역풍 ↔ 오른쪽 상승 기류.
    고장 난 밸브(티엘의 부탁) → 왼쪽 위 둥지(마도석)"""
    r = elf("e_wind_1", "세계수 · 바람길", (13, 5), (2, 2))
    F = r.h - 4  # 42
    r.door("bottom", 5, F, "e_trunk_market", "wind", style="stair_down", label="줄기 시장")
    r.exit_right("east", 14, 18, "e_wind_2", "west")
    r.add("wind_valve", id="va", x=10, y=F, flag="e_valveA")
    r.add("crosswind", id="ca", x=14, y=22, w=26, h=8, dir=-1, on_if="!e_valveA")
    r.add("updraft", id="ua", x=14, y=27, w=3, h=15, style="wind", on_if="e_valveA")
    r.fill(21, 30, 46, 31)
    r.add("wind_valve", id="vb", x=28, y=30, flag="e_valveB")
    r.add("updraft", id="ub", x=50, y=10, w=3, h=32, style="wind", on_if="e_valveB")
    r.add("crosswind", id="cb", x=46, y=8, w=14, h=10, dir=-1, on_if="!e_valveB")
    r.fill(56, 19, 78, 20)
    r.add("wind_valve", id="vx", x=38, y=30, flag="e_valveX1", broken=True, fix_flag="e_valve_fix_1")
    counter(r, "valve")
    r.add("updraft", id="ux", x=17, y=10, w=3, h=20, style="wind", on_if="e_valveX1")
    r.fill(2, 12, 12, 13)
    stone(r, "stone_wind1", 6, 12)
    r.add("enemy", id="moth1", kind="lantern_moth", x=66, y=12, face="left")
    r.add("trigger", id="t_wind", x=7, y=F - 8, w=2, h=8, run="e_wind_teach", cond="!e_valveA")
    lanterns(r, (60, 68, 74), y=1, ln=4)
    r.add("prop", kind="wind_vane", x=44, y=30)
    r.add("prop", kind="wind_vane", x=76, y=19)
    r.add("prop", kind="wind_chime", x=32, y=1, len=6)
    r.add("prop", kind="elf_banner", x=24, y=32, h=4)
    r.add("prop", kind="hanging_bridge", x=46, y=19, w=10, sag=2)
    ferns(r, (3, 26, 62), F)
    return r


@room
def e_wind_2():
    """바람길 2 (세로 3칸): 밸브 C가 바닥의 기류 기둥을 오른쪽↔왼쪽으로, 밸브 D(오른쪽 턱)가 꼭대기 역풍을 상승 기류로.
    순서: 오른쪽 기둥 → 밸브 D → 내려와 밸브 C → 왼쪽 기둥 → 위로. 고장 난 밸브 → 오른쪽 위 둥지(마도석)"""
    r = elf("e_wind_2", "세계수 · 바람길", (15, 3), (1, 3))
    F = r.h - 4  # 65
    r.exit_left("west", F - 5, F - 1, "e_wind_1", "east")
    r.exit_right("east", 14, 18, "e_wind_3", "west")
    r.add("wind_valve", id="vc", x=5, y=F, flag="e_valveC")
    r.add("updraft", id="uc_r", x=33, y=46, w=3, h=19, style="wind", on_if="!e_valveC")
    r.fill(24, 46, 32, 47)
    r.add("wind_valve", id="vd", x=26, y=46, flag="e_valveD")
    r.add("updraft", id="uc_l", x=8, y=36, w=3, h=29, style="wind", on_if="e_valveC")
    r.fill(12, 36, 20, 37)
    r.add("updraft", id="ud", x=22, y=14, w=3, h=22, style="wind", on_if="e_valveD")
    r.add("crosswind", id="cd", x=12, y=10, w=26, h=9, dir=-1, on_if="!e_valveD")
    r.fill(28, 19, 38, 20)
    r.add("wind_valve", id="vx", x=30, y=46, flag="e_valveX2", broken=True, fix_flag="e_valve_fix_2")
    counter(r, "valve")
    r.add("updraft", id="ux", x=34, y=26, w=3, h=19, style="wind", on_if="e_valveX2")
    r.fill(26, 28, 33, 29)
    stone(r, "stone_wind2", 28, 28)
    r.add("enemy", id="moth2", kind="lantern_moth", x=18, y=26, face="left")
    lanterns(r, (14, 30), y=1, ln=5)
    r.add("prop", kind="elf_lantern", x=16, y=38, len=2)
    r.add("prop", kind="wind_vane", x=37, y=19)
    r.add("prop", kind="wind_chime", x=6, y=1, len=8)
    r.add("prop", kind="vine_curtain", x=2, y=1, w=3, h=10)
    r.add("sign", x=12, y=F, look="board", text="바람길 둘째 굴 (티엘의 메모)|바닥 밸브: 기둥 바람을 오른쪽 ↔ 왼쪽으로.|위쪽 밸브: 꼭대기 역풍을 끈다. 먼저 오른쪽으로 올라가서 돌릴 것!")
    return r


@room
def e_wind_3():
    """바람길 3: 넓은 틈 — 밸브 E로 역풍을 멈추면 가운데 쉼 기둥이 켜진다. 섬 발판을 활공으로 건넘(아래는 가시덤불).
    오른쪽 고장 난 밸브 → 오른쪽 위 둥지(씨앗). 출구 앞 덩굴 사냥꾼"""
    r = elf("e_wind_3", "세계수 · 바람길", (16, 3), (2, 1))
    F = 19
    r.exit_left("west", F - 5, F - 1, "e_wind_2", "east")
    r.exit_right("east", F - 5, F - 1, "e_branch_homes", "west")
    r.clear(21, F, 60, F + 2)
    r.fill(21, F + 3, 60, F + 3, "^")
    r.add("wind_valve", id="ve", x=12, y=F, flag="e_valveE")
    r.add("crosswind", id="ce", x=21, y=3, w=40, h=16, dir=-1, power=1.2, on_if="!e_valveE")
    r.plat(32, 37, F - 3)
    r.plat(46, 51, F - 3)
    r.add("updraft", id="ue", x=40, y=6, w=3, h=14, style="wind", on_if="e_valveE")
    r.add("wind_valve", id="vx", x=64, y=F, flag="e_valveX3", broken=True, fix_flag="e_valve_fix_3")
    counter(r, "valve")
    r.add("updraft", id="ux", x=67, y=4, w=3, h=15, style="wind", on_if="e_valveX3")
    r.fill(70, 4, 78, 5)
    seed(r, 5, 75, 4)
    r.add("enemy", id="stalker3", kind="vine_stalker", x=74, y=F, face="left")
    r.add("prop", kind="wind_vane", x=18, y=F)
    r.add("prop", kind="wind_chime", x=44, y=1, len=4)
    r.add("prop", kind="hanging_bridge", x=21, y=8, w=40, sag=4)
    r.add("prop", kind="elf_lantern", x=35, y=1, len=6)
    r.add("prop", kind="elf_lantern", x=49, y=1, len=6)
    ferns(r, (3, 8, 62, 77), F)
    r.add("sign", x=16, y=F, look="board", text="⚠ 역풍 구간|밸브를 돌리기 전엔 건너지 말 것.|아래는 가시덤불. 떨어지면 따끔함. — 티엘")
    return r


# ─── 가지 ───────────────────────────────────────────────

@room
def e_branch_homes():
    """가지 마을: 아래층 가지(승강기·기록) → 지그재그 발판 → 위층 큰 가지(집들·수관 계단 — 숲 정화 뒤 열림).
    왼쪽 위 디딤 가지 끝 환영 벽 너머 숨은 숲(문). 높은 등불 발판에 마도석"""
    r = elf("e_branch_homes", "세계수 · 가지 마을", (18, 2), (3, 2))
    F = r.h - 4  # 42
    r.exit_left("west", F - 5, F - 1, "e_wind_3", "east")
    r.exit_right("east_low", F - 5, F - 1, "e_archery", "west")
    r.exit_right("east_high", 14, 18, "e_moonwell", "west")
    r.door("lift", 12, F, "e_trunk_lift", "top", style="iron", label="세계수 승강기", lock="e_lift_fixed",
           lock_msg="승강기가 멈춰 있다.")
    r.add("save", id="branch", x=28, y=F, style="candle")
    for x0, x1, y in ((36, 42, 38), (44, 50, 34), (36, 42, 30), (44, 50, 26), (36, 42, 22)):
        r.plat(x0, x1, y)
    r.fill(46, 19, 118, 20)
    r.door("canopy", 62, 19, "e_canopy_1", "bottom", style="stair_up", label="수관", lock="e_grove_purified",
           lock_msg="수관으로 오르는 계단. 파수꾼이 막아섰다. \"위는 흰 역병이 짙다. 숲이 낫기 전엔 아무도 못 올라간다.\"")
    # 왼쪽 위: 디딤 가지 + 환영 벽 너머 숨은 숲
    r.fill(1, 19, 30, 20)
    r.fill(17, 1, 17, 12)
    r.fill(17, 13, 17, 18, "I")
    r.door("secret", 8, 19, "e_secret_grove", "door", style="wood", label="가지 틈")
    r.plat(84, 90, 12)
    stone(r, "stone_branch", 87, 12)
    seed(r, 4, 104, F)
    r.add("npc", id="elf_b", who="elf_b", x=72, y=19, face="left", talk="npc_e_branch_b")
    r.add("npc", id="elf_a", who="elf_a", x=94, y=F, face="right", talk="npc_e_branch_a")
    r.add("npc", id="elf_c", who="elf_c", x=58, y=F, face="right", talk="npc_e_branch_c")
    # 소품
    r.add("prop", kind="seed_house", x=6, y=F, w=4, h=5)
    r.add("prop", kind="hammock", x=20, y=F, w=3)
    r.add("prop", kind="flower_bed", x=24, y=F, w=2)
    r.add("prop", kind="seed_house", x=78, y=19, w=4, h=6)
    r.add("prop", kind="round_door", x=78, y=19)
    r.add("prop", kind="seed_house", x=100, y=19, w=3, h=5)
    r.add("prop", kind="leaf_awning", x=62, y=13, w=4)
    r.add("prop", kind="elf_lantern_post", x=56, y=19)
    r.add("prop", kind="elf_lantern_post", x=68, y=19)
    r.add("prop", kind="tea_set", x=92, y=19)
    r.add("prop", kind="bench_log", x=108, y=19, w=2)
    r.add("prop", kind="wind_vane", x=114, y=19)
    r.add("prop", kind="market_stall", x=66, y=F, w=4)
    r.add("prop", kind="herb_rack", x=74, y=F)
    r.add("prop", kind="loom", x=84, y=F)
    r.add("prop", kind="firefly_jar", x=110, y=F)
    r.add("prop", kind="hanging_bridge", x=90, y=12, w=12, sag=2)
    r.add("prop", kind="wind_chime", x=52, y=21, len=4)
    r.add("prop", kind="elf_banner", x=96, y=21, h=5)
    lanterns(r, (8, 24, 40, 58, 76, 88, 106), y=1, ln=3)
    lanterns(r, (60, 80, 100, 116), y=21, ln=1)
    ferns(r, (3, 32, 116), F)
    r.add("sign", x=50, y=19, look="board", text="가지 마을|↑ 수관 (출입 금지 — 역병)|→ 달샘 (위 가지) / → 활터 (아래 가지)")
    return r


@room
def e_archery():
    """활터 (아래 가지 끝): 엘라리엔의 부탁 e_archery — 과녁 넷을 화염탄으로 제한 시간 안에. 사냥 시험 전엔 파수꾼이 연습 중"""
    r = elf("e_archery", "세계수 · 활터", (21, 3), (1, 1))
    F = 19
    r.exit_left("west", F - 5, F - 1, "e_branch_homes", "east_low")
    r.plat(16, 22, F - 5)
    r.plat(28, 34, 9)
    r.add("archery_mark", id="am1", x=14, y=F, group="archery", active_if="e_archery_on")
    r.add("archery_mark", id="am2", x=25, y=8, group="archery", hang=True, dy=2, period=2.6, active_if="e_archery_on")
    r.add("archery_mark", id="am3", x=31, y=F, group="archery", dx=3, period=3.0, active_if="e_archery_on")
    r.add("archery_mark", id="am4", x=36, y=4, group="archery", hang=True, dx=1, dy=1, period=2.2, phase=1.0, active_if="e_archery_on")
    r.add("npc", id="elarien", who="elarien", x=6, y=F, face="right", cond="e_hunt_done")
    r.add("npc", id="warden_b", who="warden_b", x=6, y=F, face="right", cond="!e_hunt_done")
    r.add("prop", kind="bow_rack", x=3, y=F)
    r.add("prop", kind="bench_log", x=9, y=F, w=2)
    r.add("prop", kind="archery_target", x=38, y=F)
    r.add("prop", kind="elf_banner", x=20, y=1, h=4)
    r.add("prop", kind="wind_vane", x=33, y=9)
    lanterns(r, (10, 30), y=1, ln=2)
    r.add("sign", x=11, y=F, look="board", text="활터|과녁에 박힌 화살은 뽑아서 제자리에.|바람을 읽지 못하는 자, 활을 들지 말 것. — 엘라리엔")
    return r


@room
def e_moonwell():
    """달샘 (위 가지 끝): 천장 틈에서 떨어지는 달빛 방울을 불꽃 방벽으로 되쏘아 매달린 수정 셋을 밝힌다 →
    너울의 가르침 '잠재우는 불'(e_moon_lesson) → 오른쪽 뿌리 문이 열려 흰 역병의 숲으로. 달잎(장로의 차)"""
    r = elf("e_moonwell", "세계수 · 달샘", (21, 2), (1, 1))
    F = 19
    r.exit_left("west", F - 5, F - 1, "e_branch_homes", "east_high")
    r.exit_right("east", F - 5, F - 1, "e_blight_1", "west")
    for i, x in enumerate((10, 18, 26)):
        r.add("moon_crystal", id="mc%d" % i, x=x, y=1, group="moon", done_flag="e_moon_puzzle")
        r.add("moon_drop", id="md%d" % i, x=x, y=4, period=2.4, phase=i * 0.8, on_if="e_moon_talk")
    r.add("puzzle", id="pz", group="moon", mode="all", done_flag="e_moon_puzzle")
    r.add("event", id="ev", flag="e_moon_puzzle", run="e_moon_lesson", done="e_moon_lesson_run")
    r.add("trigger", id="t_moon", x=4, y=F - 8, w=2, h=8, run="e_moon_arrive", cond="e_wind_done,!e_moon_talk")
    r.fill(34, 1, 35, F - 7)
    r.add("root_gate", id="rg", x=34, y=F - 6, w=2, h=6, open_if="e_moon_lesson")
    counter(r, "tea")
    item(r, "moonleaf", 30, F, "달샘의 달잎", "e_tea_leaf", "달빛을 머금어 은빛으로 빛나는 잎. 장로님 차에 들어간다고 했다.")
    r.add("prop", kind="moonwell", x=18, y=F, w=8)
    ferns(r, (3, 31), F)
    r.add("prop", kind="vine_curtain", x=2, y=1, w=3, h=6)
    r.add("prop", kind="spirit_statue", x=7, y=F)
    r.add("light", x=18, y=2, r=6, color="#b8c8ff")
    blight(r, (("crystal", 37, F, 1), ("growth", 38, F, 1)))
    return r


# ─── 흰 역병의 숲 ───────────────────────────────────────

@room
def e_blight_1():
    """흰 역병의 숲 1: 길을 막은 역병 덩굴(잠재우는 불을 배운 뒤에야 탐) → 포자 덩어리, 백색 진드기"""
    r = elf("e_blight_1", "흰 역병의 숲", (22, 2), (2, 1), theme="blight", music="")
    F = 19
    r.exit_left("west", F - 5, F - 1, "e_moonwell", "east")
    r.exit_right("east", F - 5, F - 1, "e_blight_2", "west")
    r.fill(20, 1, 21, F - 6)
    r.add("blight_vine", id="v1", x=20, y=F - 5, w=2, h=5, hp=3, need="e_moon_lesson", hint="e_vine_hint", first="e_vine_first")
    r.fill(30, F - 2, 36, F - 1)
    r.plat(40, 46, F - 5)
    r.fill(50, F - 3, 54, F - 1)
    r.add("enemy", id="spore1", kind="blight_spore", x=33, y=F - 2, face="left")
    r.add("enemy", id="mite1", kind="white_mite", x=64, y=F, face="left")
    r.add("trigger", id="t_blight", x=6, y=F - 8, w=2, h=8, run="e_blight_arrive")
    blight(r, (("tree", 10, F, 6), ("crystal", 16, F, 1.5), ("growth", 26, F, 3), ("tree", 44, F, 8), ("crystal", 58, F, 2),
               ("growth", 68, F, 4), ("tree", 74, F, 5)))
    return r


@room
def e_blight_2():
    """흰 역병의 숲 2: 덩굴 둘, 역병 든 사슴, 포자 둘. 높은 굳은 가지 끝에 마도석"""
    r = elf("e_blight_2", "흰 역병의 숲", (24, 2), (2, 1), theme="blight", music="")
    F = 19
    r.exit_left("west", F - 5, F - 1, "e_blight_1", "east")
    r.exit_right("east", F - 5, F - 1, "e_blight_3", "west")
    r.fill(14, F - 2, 20, F - 1)
    r.fill(28, 1, 29, F - 6)
    r.add("blight_vine", id="v2", x=28, y=F - 5, w=2, h=5, hp=3)
    r.plat(36, 42, F - 5)
    r.plat(44, 50, F - 9)
    r.plat(52, 56, 6)
    stone(r, "stone_blight2", 54, 6)
    r.fill(60, 1, 61, F - 7)
    r.add("blight_vine", id="v3", x=60, y=F - 6, w=2, h=6, hp=3)
    r.add("enemy", id="stag2", kind="moss_stag", x=46, y=F, face="left", blighted=True)
    r.add("enemy", id="spore1", kind="blight_spore", x=17, y=F - 2, face="left")
    r.add("enemy", id="spore2", kind="blight_spore", x=70, y=F, face="left")
    blight(r, (("tree", 6, F, 7), ("crystal", 24, F, 1), ("growth", 34, F, 3), ("tree", 66, F, 6), ("crystal", 76, F, 2)))
    return r


@room
def e_blight_3():
    """굳은 숲의 심장 (2×2): 높은 턱 위의 거대한 역병 결정(체력 6)을 정화하면 숲이 되살아난다(e_grove_purified)"""
    r = elf("e_blight_3", "흰 역병의 숲 · 굳은 심장", (26, 1), (2, 2), theme="blight", music="")
    F = r.h - 4  # 42
    r.exit_left("west", F - 5, F - 1, "e_blight_2", "east")
    r.add("save", id="blight", x=8, y=F, style="candle")
    for x0, x1, y in ((20, 27, 38), (30, 37, 34), (40, 47, 30), (50, 57, 26), (40, 47, 22)):
        r.plat(x0, x1, y)
    r.fill(52, 18, 78, 19)
    r.add("blight_vine", id="heart", x=66, y=12, w=4, h=6, hp=6, done_flag="e_heart_burnt", need="e_moon_lesson",
          hint="e_vine_hint")
    r.add("event", id="ev_heart", flag="e_heart_burnt", run="e_grove_purify", done="e_grove_purify_run")
    r.add("enemy", id="mite_heart", kind="white_mite", x=56, y=F, face="left")
    r.add("enemy", id="spore1", kind="blight_spore", x=33, y=34, face="left")
    r.add("trigger", id="t_heart", x=14, y=F - 8, w=2, h=8, run="e_heart_arrive")
    blight(r, (("tree", 4, F, 8), ("crystal", 16, F, 1.5), ("growth", 26, F, 4), ("tree", 44, F, 10), ("crystal", 64, F, 2),
               ("growth", 70, F, 5), ("tree", 58, 18, 6), ("crystal", 74, 18, 2.5), ("growth", 54, 18, 3)))
    return r


@room
def e_secret_grove():
    """숨은 숲: 여우창문으로만 찾는 가지 틈. 오래된 벌집(숲 꿀 — 버터워스), 수호의 깃털, 노래 가사 셋째 장, 마도석"""
    r = elf("e_secret_grove", "세계수 · 숨은 숲", (17, 2), (1, 1))
    F = 19
    r.door("door", 35, F, "e_branch_homes", "secret", style="wood", label="가지 마을")
    r.plat(22, 28, F - 4)
    r.plat(12, 18, F - 8)
    r.plat(4, 9, F - 12)
    r.add("pickup", id="feather_grove", kind="feather", x=6, y=F - 12, name="수호의 깃털", text="최대 체력이 1 늘었다.")
    stone(r, "stone_grove", 15, F - 8)
    note(r, "note_song3", 8, F, *SONG3)
    counter(r, "honey")
    item(r, "honey", 25, F - 4, "숲 꿀", "e_honey_got", "오래된 벌집에서 흘러내린 황금빛 꿀. 버터워스 아주머니가 찾던 거다.")
    r.add("prop", kind="flower_bed", x=14, y=F, w=4)
    r.add("prop", kind="flower_bed", x=28, y=F, w=3)
    r.add("prop", kind="eilach_sapling", x=20, y=F, white=0.0)
    r.add("prop", kind="firefly_jar", x=32, y=F)
    r.add("prop", kind="vine_curtain", x=24, y=1, w=4, h=5)
    r.add("prop", kind="elf_lantern", x=7, y=1, len=3)
    ferns(r, (3, 10, 37), F)
    r.add("light", x=20, y=6, r=6, color="#e8ff9a")
    return r


# ─── 수관 ───────────────────────────────────────────────

@room
def e_canopy_1():
    """수관 1: 잎 사이 가지길 — 등불 나방 둘(등불에 내려앉아 쉴 때가 빈틈)"""
    r = elf("e_canopy_1", "세계수 · 수관", (19, 1), (2, 1))
    F = 19
    r.door("bottom", 6, F, "e_branch_homes", "canopy", style="stair_down", label="가지 마을")
    r.exit_right("east", F - 5, F - 1, "e_canopy_2", "west")
    r.fill(14, F - 3, 22, F - 1)
    r.plat(26, 32, F - 6)
    r.fill(36, F - 5, 44, F - 1)
    r.plat(48, 54, F - 8)
    r.fill(58, F - 3, 66, F - 1)
    r.add("enemy", id="moth1", kind="lantern_moth", x=30, y=6, face="left")
    r.add("enemy", id="moth2", kind="lantern_moth", x=60, y=5, face="left")
    lanterns(r, (12, 29, 40, 51, 63, 72), y=1, ln=3)
    r.add("prop", kind="vine_curtain", x=46, y=1, w=4, h=6)
    r.add("prop", kind="hanging_bridge", x=22, y=F - 3, w=14, sag=2)
    ferns(r, (4, 24, 70, 76), F)
    return r


@room
def e_canopy_2():
    """수관 2 (세로 2칸): 위쪽엔 늘 오른쪽으로 부는 바람. 지그재그 가지 → 꼭대기 오른쪽 턱. 포자·사냥꾼, 수관의 이슬(장로의 차), 마도석"""
    r = elf("e_canopy_2", "세계수 · 수관", (21, 0), (1, 2))
    F = r.h - 4  # 42
    r.exit_left("west", F - 5, F - 1, "e_canopy_1", "east")
    r.exit_right("east", 14, 18, "e_canopy_3", "west")
    for x0, x1, y in ((24, 31, 38), (12, 19, 34), (2, 9, 30), (12, 19, 26), (20, 27, 22)):
        r.plat(x0, x1, y)
    r.fill(30, 19, 38, 20)
    r.add("crosswind", id="cw", x=2, y=8, w=26, h=10, dir=1, power=0.7)
    stone(r, "stone_canopy2", 4, 30)
    counter(r, "tea")
    item(r, "dew", 15, 26, "수관의 이슬", "e_tea_dew", "높은 잎에 고인 맑은 이슬. 장로님 차에 들어간다.")
    r.add("enemy", id="spore1", kind="blight_spore", x=26, y=38, face="left")
    r.add("enemy", id="stalker1", kind="vine_stalker", x=34, y=19, face="left")
    lanterns(r, (8, 22, 34), y=1, ln=4)
    r.add("prop", kind="vine_curtain", x=34, y=21, w=3, h=7)
    r.add("prop", kind="wind_vane", x=6, y=30)
    ferns(r, (4, 36), F)
    return r


@room
def e_canopy_3():
    """수관 경기장 앞: 기록, 엘라리엔이 기다림(e_hunt_offer) → 경기장 계단"""
    r = elf("e_canopy_3", "세계수 · 경기장 앞", (22, 0), (2, 1))
    F = 19
    r.exit_left("west", F - 5, F - 1, "e_canopy_2", "east")
    r.add("save", id="pre_hunt", x=56, y=F, style="candle")
    r.door("arena", 72, F, "e_hunt_arena", "bottom", style="stair_up", label="수관 경기장", lock="e_hunt_offer",
           lock_msg="경기장으로 오르는 계단. 누군가 위에서 내려다보고 있다.")
    r.add("npc", id="elarien", who="elarien", x=66, y=F, face="left", cond="!e_hunt_done")
    r.add("trigger", id="t_offer", x=48, y=F - 8, w=2, h=8, run="e_hunt_offer", cond="!e_hunt_offer")
    r.fill(16, F - 2, 24, F - 1)
    r.plat(28, 34, F - 6)
    r.fill(38, F - 1, 42, F - 1)
    r.add("prop", kind="bow_rack", x=62, y=F)
    r.add("prop", kind="archery_target", x=76, y=F)
    r.add("prop", kind="elf_banner", x=70, y=1, h=7)
    r.add("prop", kind="elf_banner", x=74, y=1, h=7)
    r.add("prop", kind="bench_log", x=50, y=F, w=2)
    lanterns(r, (10, 26, 44, 60), y=1, ln=3)
    ferns(r, (4, 12, 36), F)
    return r


@room
def e_hunt_arena():
    """수관 경기장 (세로 3칸): 사냥 시험 — 엘라리엔 '세 번 닿기'. 4행 간격 가지(통과 발판) 지그재그, 횃대 perch_1~6.
    꼭대기 턱의 계단(시험 뒤 열림) → 꼭대기 가지"""
    r = elf("e_hunt_arena", "세계수 · 수관 경기장", (24, -2), (1, 3), music="elf_hunt")
    F = r.h - 4  # 65
    levels = [
        (61, [(4, 12), (27, 35)]),
        (57, [(14, 24)]),
        (53, [(3, 10), (29, 37)]),
        (49, [(13, 21)]),
        (45, [(4, 11), (27, 35)]),
        (41, [(15, 24)]),
        (37, [(3, 9), (30, 37)]),
        (33, [(13, 21)]),
        (29, [(4, 11), (28, 36)]),
        (25, [(15, 23)]),
        (21, [(3, 10), (29, 37)]),
        (17, [(15, 24)]),
    ]
    for y, spans in levels:
        for x0, x1 in spans:
            r.plat(x0, x1, y)
    for i, (x, y) in enumerate([(20, 17), (6, 29), (33, 37), (17, 49), (7, 45), (33, 21)]):
        r.add("spawn", id="perch_%d" % (i + 1), x=x, y=y)
    r.door("bottom", 6, F, "e_canopy_3", "arena", style="stair_down", label="수관")
    r.fill(12, 9, 22, 10)
    r.plat(26, 32, 13)
    r.door("crown", 17, 9, "e_crown_1", "bottom", style="stair_up", label="꼭대기 가지", lock="e_hunt_done",
           lock_msg="꼭대기로 가는 계단. 엘라리엔이 활을 겨누고 있다. 먼저 시험부터.")
    r.add("enemy", id="elarien", kind="elarien_hunt", x=20, y=17, face="left", engaged=False, cond="!e_hunt_done")
    r.add("trigger", id="t_hunt", x=3, y=F - 8, w=10, h=8, run="e_hunt_begin", once=False, cond="!e_hunt_done")
    for x, y in ((9, 29), (32, 21), (19, 41), (20, 61)):
        r.add("prop", kind="elf_lantern", x=x, y=y + 1, len=1)
    r.add("prop", kind="vine_curtain", x=34, y=1, w=3, h=6)
    r.add("prop", kind="elf_banner", x=6, y=1, h=6)
    r.add("prop", kind="elf_banner", x=36, y=40, h=5)
    r.add("prop", kind="bow_rack", x=30, y=F)
    ferns(r, (2, 12, 37), F)
    return r


# ─── 꼭대기 ─────────────────────────────────────────────

@room
def e_crown_1():
    """꼭대기 가지 1: 하얗게 굳은 꼭대기. 기록, 역병 덩굴, 작은 백색 진드기 둘, 포자"""
    r = elf("e_crown_1", "세계수 · 꼭대기 가지", (25, -3), (2, 1), theme="blight", music="")
    F = 19
    r.door("bottom", 5, F, "e_hunt_arena", "crown", style="stair_down", label="수관 경기장")
    r.exit_right("east", F - 5, F - 1, "e_crown_2", "west")
    r.add("save", id="crown", x=12, y=F, style="candle")
    r.add("trigger", id="t_crown", x=18, y=F - 8, w=2, h=8, run="e_crown_arrive")
    r.fill(26, F - 2, 32, F - 1)
    r.fill(40, 1, 41, F - 6)
    r.add("blight_vine", id="cv1", x=40, y=F - 5, w=2, h=5, hp=3)
    r.plat(46, 52, F - 5)
    r.fill(58, F - 3, 62, F - 1)
    r.add("enemy", id="mite_s1", kind="white_mite", x=52, y=F, face="left", small=True)
    r.add("enemy", id="mite_s2", kind="white_mite", x=66, y=F, face="left", small=True)
    r.add("enemy", id="spore1", kind="blight_spore", x=29, y=F - 2, face="left")
    blight(r, (("tree", 8, F, 7), ("crystal", 22, F, 1.5), ("growth", 36, F, 3), ("tree", 56, F, 9), ("crystal", 70, F, 2),
               ("growth", 74, F, 4)))
    return r


@room
def e_crown_2():
    """꼭대기 가지 2 (세로 2칸): 굳은 가지를 지그재그로. 위 턱을 막은 덩굴, 아래의 큰 백색 진드기"""
    r = elf("e_crown_2", "세계수 · 꼭대기 가지", (27, -4), (1, 2), theme="blight", music="")
    F = r.h - 4  # 42
    r.exit_left("west", F - 5, F - 1, "e_crown_1", "east")
    r.exit_right("east", 14, 18, "e_crown_nest", "west")
    for x0, x1, y in ((24, 31, 38), (12, 19, 34), (2, 9, 30), (12, 19, 26), (2, 9, 23)):
        r.plat(x0, x1, y)
    r.fill(12, 19, 38, 20)
    r.fill(30, 1, 31, 13)
    r.add("blight_vine", id="cv2", x=30, y=14, w=2, h=5, hp=3)
    r.add("enemy", id="mite_big", kind="white_mite", x=18, y=F, face="left")
    blight(r, (("tree", 34, F, 8), ("crystal", 6, F, 2), ("crystal", 15, 19, 1.5), ("growth", 22, 19, 3), ("tree", 36, 19, 5)))
    return r


@room
def e_crown_nest():
    """사도의 둥지 (꼭대기): 백색 사도. 엘라리엔은 왼쪽 높은 엄호 가지(ally)에서 수정 눈을 저격.
    피오가 갇힌 흰 꼬투리(white_pod)가 오른쪽에 매달림. 싸움 중엔 왼쪽 출구에 결계"""
    r = elf("e_crown_nest", "세계수 · 사도의 둥지", (28, -4), (2, 1), theme="blight", music="")
    F = 19
    r.exit_left("west", F - 5, F - 1, "e_crown_2", "east")
    r.add("gate", id="seal", x=1, y=F - 5, w=1, h=5, open_if="!e_herald_fight", look="barrier")
    r.plat(24, 30, 8)
    r.add("spawn", id="ally", x=27, y=8, face="right")
    r.plat(14, 20, F - 5)
    r.plat(58, 64, F - 5)
    r.add("enemy", id="herald", kind="white_herald", x=46, y=F, face="left", engaged=False, cond="!e_herald_done")
    r.add("white_pod", id="pod", x=68, y=F - 8, cond="!e_herald_done")
    r.add("trigger", id="t_herald", x=8, y=F - 8, w=2, h=8, run="e_herald_begin", once=False, cond="!e_herald_done")
    r.add("spawn", id="kids", x=3, y=F, face="right")
    blight(r, (("crystal", 6, F, 1.5), ("tree", 12, F, 9), ("growth", 34, F, 5), ("crystal", 54, F, 2.5), ("tree", 74, F, 8),
               ("crystal", 78, F, 1)))
    r.add("prop", kind="eilach_sapling", x=40, y=F, white=1.0, cond="!e_herald_done")
    r.add("prop", kind="eilach_sapling", x=40, y=F, white=0.0, cond="e_herald_done")
    return r
