"""2장 방 — 제국의 검 (docs/chapter2.md 3절·7절). roomgen.py가 불러온다.
from roomgen import Room, room, overlay — 1장 roomgen.py와 같은 문법.

    python3 tools/roomgen.py                 # 모든 방 다시 만들기
    python3 tools/roomgen.py check all k_    # 2장 방 도달 검사 (모든 능력)

지도 (영역 "kingdom", 칸 x 0~13 · y 0~6 — 지도 화면에서 방 이름이 보이게 14칸 안에 모음)
  y0  분화구(0,0)2x2 · 옛 성곽3(2,0) · 옛 성곽2(3,0)1x2
  y1  옛 성곽1(4,1)2x1 · 황궁 광장(6,1)2x1 · 황궁 문(8,1) · 귀족 구역(9,1)2x1 · 시계탑(11,1)1x3
  y2  지붕1(5,2)2x2 · 지붕2(7,2)2x1 · 지붕3(9,2)2x1
  y3  성벽(7,3)2x1 · 지붕4(9,3)2x1 · 대성당(12,3)2x2
  y4  공관(0,4) · 성문 거리(1,4)2x1 · 시장(3,4)3x1 · 뒷골목(6,4) · 연무장(7,4)2x1 · 시계 거리(9,4)3x1
  y5  투기장(1,5)2x1 · 빵집(3,5) · 대장간(5,5) · 막사(8,5) · 태엽 공방(9,5)2x1 · 지하 묘지(12,5)2x1
  y6  투기장 바닥(1,6)2x1 · 신도 은신처(4,6)2x1 · 하수도5(6,6) · 하수도4(7,6)2x1 · 하수도3(9,6)2x1 · 하수도2(11,6)2x1 · 하수도1(13,6)

게이트(지형이 아니라 개체·대본으로): 성벽 계단 k_spar_done · 지붕(성벽 서쪽 철창·뒷골목 사다리) ab_wings+k_walls_talk ·
  시계탑 문 k_gears_done · 지하 묘지 k_tower_top · 별 수정 장벽(방벽 되쏘기) · 하수도 수문 밸브 · 귀족 구역 다리 k_duel_called ·
  옛 성곽 철창 k_duel_done · 투기장 k_spar_done(+지배인 허락 k_arena_ok)
"""
from roomgen import Room, room, overlay, windows  # noqa: F401

A = "kingdom"


def city(rid, title, cell, cells, theme="kingdom", music="kingdom", dark=0.0):
    """바깥(하늘이 보이는) 방 — 지형은 각 방에서"""
    return Room(rid, "황도 아르덴 · " + title, A, theme, music, cell, cells, dark)


def hall(rid, title, cell, cells, theme="kingdom_in", music="kingdom", dark=0.0, ceil=2, floor=4):
    """사방이 막힌 실내 방 (바닥 윗면 = h - floor)"""
    r = Room(rid, "황도 아르덴 · " + title, A, theme, music, cell, cells, dark)
    r.box(wall=1, floor=floor, ceil=ceil)
    return r


def spikes_under(r, y, x0, x1):
    """지붕 사이 틈 바닥: y행 가시 + 그 아래 땅 (떨어지면 직전 땅으로)"""
    r.fill(x0, y + 1, x1, r.h - 1)
    r.fill(x0, y, x1, y, "^")


def stone(r, sid, x, y, text="보랏빛 결정이 빛난다."):
    r.add("pickup", id=sid, kind="stone", x=x, y=y, name="마도석", text=text)


def note(r, nid, x, y, n, text):
    r.add("pickup", id=nid, kind="note", x=x, y=y, name="제국 연대기 쪽지 (%d/3)" % n, text=text)


def book(r, bid, x, y, title):
    r.add("pickup", id=bid, kind="key", x=x, y=y, name="연체 도서 " + title, flag=bid,
          text="마녀학교 도서관 도장이 찍혀 있다. 그레타에게 돌려주자.")


# ═══════════════════════════════════════════════════════════
# 학교에 덧붙임 (2장 아침·사자·출발) — 지형은 그대로, cond로 2장에만
# ═══════════════════════════════════════════════════════════

# 식당: 아침 식사 (피피·이졸데)
overlay("s_cafeteria", "npc", id="k_pippa_am", who="pippa", x=18, y=19, face="left", cond="ch1_done,!k_breakfast")
overlay("s_cafeteria", "npc", id="k_isolde_am", who="isolde", x=21, y=19, face="left", cond="ch1_done,!k_breakfast")
overlay("s_cafeteria", "trigger", id="k_morning", x=7, y=13, w=4, h=6, run="k_cafe_morning", cond="ch1_done,!k_breakfast")
# 바람의 탑: 날개 수업이 끝나면 교장의 부름
overlay("s_windtower", "event", id="k_wings_ev", flag="ab_wings", run="k_after_wings", done="k_after_wings_seen", cond="ch1_done")
# 교장실: 제국의 사자
overlay("s_headmaster", "trigger", id="k_envoy_tg", x=6, y=13, w=4, h=6, run="k_envoy", cond="ab_wings,!k_envoy_seen")
# 앞마당: 파견 출발 (엠버린·피피·이졸데가 전이진 앞에서 기다림)
overlay("s_courtyard", "npc", id="k_emb_go", who="emberlyn", x=20, y=19, face="right", cond="k_envoy_seen,!k_departed")
overlay("s_courtyard", "npc", id="k_pip_go", who="pippa", x=17, y=19, face="right", cond="k_envoy_seen,!k_departed")
overlay("s_courtyard", "npc", id="k_iso_go", who="isolde", x=31, y=19, face="left", cond="k_envoy_seen,!k_departed")
overlay("s_courtyard", "trigger", id="k_depart_tg", x=26, y=13, w=6, h=6, run="k_depart", cond="k_envoy_seen,!k_departed")


# ═══════════════════════════════════════════════════════════
# 공관 · 성문 거리 · 시장
# ═══════════════════════════════════════════════════════════

@room
def k_embassy():
    """제국 주재 마녀학교 공관: 전이진(학교↔제국) + 기록 + 엠버린·피피·이졸데 거점"""
    r = hall("k_embassy", "공관", (0, 4), (1, 1))
    F = 19
    r.exit_right("east", F - 5, F - 1, "k_gate_street", "west")
    r.add("warp", id="warp_circle", x=20, y=F, area="kingdom")
    r.add("spawn", id="warp", x=20, y=F, face="right")
    r.add("save", id="candle", x=6, y=F, style="candle")
    r.plat(2, 9, 13)  # 서가 위 다락 (장식)
    r.add("npc", id="emberlyn", who="emberlyn", x=27, y=F, face="left", cond="k_departed")
    r.add("npc", id="pippa", who="pippa", x=12, y=F, face="right", cond="k_departed")
    r.add("npc", id="isolde", who="isolde", x=33, y=F, face="left", cond="k_departed,!k_race_ready")
    r.add("npc", id="isolde2", who="isolde", x=33, y=F, face="left", cond="k_race_won")
    r.add("prop", kind="magic_circle", x=20, y=F, w=6, col="#b8a8ff")
    r.add("prop", kind="cauldron", x=15, y=F)
    r.add("prop", kind="bookshelf", x=4, y=13, w=4, h=5)
    r.add("prop", kind="rug", x=20, y=F, w=12)
    r.add("prop", kind="chandelier", x=20, y=2, len=3)
    windows(r, (12, 28), F - 9, 3, 6)
    r.add("prop", kind="banner", x=8, y=3, h=6, col="#2a1e4a")
    r.add("prop", kind="k_banner", x=32, y=2, w=2, h=5)
    r.add("prop", kind="desk", x=30, y=F, w=3)
    r.add("prop", kind="plant", x=37, y=F)
    r.add("sign", x=24, y=F, look="board",
          text="제국 주재 마녀학교 공관|전이진: ↑ — 학교 앞마당과 이어져 있다.|공관장 부재 중. 용무는 엠버린 교수에게.|[주의] 공관 밖에서는 제국 법을 따를 것. 거리에서 불 쓰지 말 것. (특히 세라)")
    return r


@room
def k_gate_street():
    r = city("k_gate_street", "성문 거리", (1, 4), (2, 1))
    F = 19
    r.ground(F)
    r.exit_left("west", F - 5, F - 1, "k_embassy", "east")
    r.exit_right("east", F - 5, F - 1, "k_market", "west")
    # 계단 광장
    r.fill(30, F - 2, 46, F - 1)
    r.fill(28, F - 1, 29, F - 1)
    r.fill(47, F - 1, 48, F - 1)
    # 집 발코니 → 가로등 관리인의 선반 (마도석)
    r.plat(8, 13, 14)
    r.plat(16, 21, 9)
    r.plat(5, 9, 4)
    stone(r, "k_stone_gate", 7, 4, "가로등 관리인이 숨겨 둔 보라 결정.")
    r.door("colosseum", 64, F, "k_colosseum", "door", style="grand", label="투기장",
           lock="k_spar_done", lock_msg="투기장 — 오늘은 기사단 행사로 닫혀 있다. (기사단장과 인사한 뒤에)")
    r.add("npc", id="guard", who="k_knight", x=71, y=F, face="left", talk="npc_k_gate_guard")
    r.add("npc", id="cit_a", who="k_citizen_a", x=22, y=F, face="right", talk="npc_k_gate_a")
    r.add("npc", id="child", who="k_child", x=38, y=F - 2, face="left", talk="npc_k_gate_child")
    for x in (60, 68):
        r.add("prop", kind="k_statue_lion", x=x, y=F, flip=(x > 64))
    for x in (12, 26, 52, 76):
        r.add("prop", kind="k_lamp", x=x, y=F, h=4)
    r.add("prop", kind="k_fountain", x=38, y=F - 2)
    r.add("prop", kind="k_flowers", x=32, y=F - 2, w=2)
    r.add("prop", kind="k_flowers", x=44, y=F - 2, w=2)
    r.add("prop", kind="k_window", x=10, y=F - 7, w=2, h=2)
    r.add("prop", kind="k_window", x=18, y=F - 12, w=2, h=2, lit=False)
    r.add("prop", kind="k_flag", x=64, y=F - 6, h=4)
    r.add("prop", kind="k_bunting", x=2, y=2, w=36, sag=2)
    r.add("prop", kind="k_bunting", x=42, y=3, w=36, sag=1.5)
    r.add("prop", kind="k_noticeboard", x=50, y=F)
    r.add("sign", x=50, y=F, look="none",
          text="황도 아르덴 게시판|[공고] 별의 짐승 출몰. 해가 진 뒤 옛 성곽 지구 출입 금지. — 은사자 기사단|[투기장] 이번 주에도 챔피언 가론! 도전자 모집!|[찾습니다] 우리 고양이 '단장님'. 주황색, 뚱뚱함. — 미아네 빵집")
    return r


@room
def k_market():
    r = city("k_market", "시장", (3, 4), (3, 1))
    F = 19
    r.ground(F)
    r.exit_left("west", F - 5, F - 1, "k_gate_street", "east")
    r.exit_right("east", F - 5, F - 1, "k_market_alley", "west")
    r.door("bakery", 12, F, "k_bakery", "door", style="wood", label="미아네 빵집")
    r.door("smithy", 108, F, "k_smithy", "door", style="wood", label="브론의 대장간")
    # 노점 차양 (위에 올라설 수 있음)
    for x0, x1 in ((22, 28), (34, 40), (80, 86), (92, 98)):
        r.plat(x0, x1, F - 4)
    # 대장간 굴뚝 (열기 → 불꽃 날개로 타면 지붕 선반의 마도석)
    r.fill(102, F - 3, 103, F - 1)
    r.add("updraft", id="smithy_heat", x=101, y=3, w=4, h=13, style="heat")
    r.plat(108, 113, 6)
    stone(r, "k_stone_market", 110, 6, "대장간 굴뚝 연기에 그을린 결정.")
    # 별의 짐승 습격 (레오니 등장)
    r.add("trigger", id="beast_tg", x=52, y=11, w=4, h=8, run="k_market_beast", cond="k_departed,!k_met_leonie")
    r.add("spawn", id="beast", x=80, y=F)
    r.add("spawn", id="center", x=58, y=F)
    # 인물
    r.add("npc", id="merchant", who="k_merchant", x=37, y=F, face="left")
    r.add("npc", id="cit_b", who="k_citizen_b", x=68, y=F, face="left", talk="npc_k_market_b")
    r.add("npc", id="cit_c", who="k_citizen_c", x=88, y=F, face="right", talk="npc_k_market_c")
    # 소품
    r.add("prop", kind="k_stall", x=25, y=F, w=5, goods="bread", col="#a8323a")
    r.add("prop", kind="k_stall", x=37, y=F, w=5, goods="star", col="#4a2a6a")
    r.add("prop", kind="k_stall", x=83, y=F, w=5, goods="fruit", col="#2e5a8a")
    r.add("prop", kind="k_stall", x=95, y=F, w=5, goods="fish", col="#2e6a5a")
    r.add("prop", kind="k_statue_leonie", x=60, y=F)
    r.add("prop", kind="k_fountain", x=52, y=F)
    r.add("prop", kind="k_crates", x=46, y=F, n=3)
    r.add("prop", kind="k_barrel", x=44, y=F, fill="apples")
    r.add("prop", kind="k_barrel", x=74, y=F, fill="water")
    r.add("prop", kind="k_cart", x=70, y=F)
    r.add("prop", kind="k_flowers", x=16, y=F, w=3)
    r.add("prop", kind="k_sign", x=12, y=F - 6, icon="bread")
    r.add("prop", kind="k_sign", x=108, y=F - 6, icon="anvil")
    r.add("prop", kind="k_chimney", x=102, y=F - 3, h=1)
    for x in (6, 30, 66, 90, 116):
        r.add("prop", kind="k_lamp", x=x, y=F, h=4)
    r.add("prop", kind="k_bunting", x=2, y=2, w=36, sag=2)
    r.add("prop", kind="k_bunting", x=42, y=2, w=36, sag=2.5)
    r.add("prop", kind="k_bunting", x=82, y=2, w=36, sag=2)
    r.add("prop", kind="k_laundry", x=64, y=5, w=12)
    r.add("prop", kind="k_window", x=6, y=F - 9, w=2, h=2)
    r.add("prop", kind="k_window", x=116, y=F - 8, w=2, h=2)
    r.add("sign", x=60, y=F, look="none",
          text="레오니 발렌하르트 상|은사자 기사단장. 제국제일검.|받침돌에 아이 글씨로 누가 새겨 놓았다. '우리 단장님 최고' — 미아")
    return r


@room
def k_bakery():
    r = hall("k_bakery", "미아네 빵집", (3, 5), (1, 1))
    F = 19
    r.door("door", 5, F, "k_market", "bakery", style="wood", label="시장")
    r.fill(14, F - 2, 22, F - 1)  # 계산대
    r.add("npc", id="mia", who="mia", x=26, y=F, face="left")
    r.add("prop", kind="k_bread", x=33, y=F, w=4, h=4)
    r.add("prop", kind="k_bread", x=18, y=F - 2, w=4, h=1)
    r.add("prop", kind="k_forge", x=37, y=F)
    r.add("prop", kind="k_window", x=10, y=F - 7, w=2, h=2)
    r.add("prop", kind="k_lantern", x=24, y=2, len=2)
    r.add("prop", kind="k_flowers", x=30, y=F, w=1)
    r.add("prop", kind="painting", x=26, y=F - 8, w=2, h=2, col="#a8323a")
    r.add("sign", x=12, y=F, look="note",
          text="미아의 낙서|오늘의 빵: 사자 머리 빵(단장님 빵)!|단장님은 크림빵을 좋아하신다. 비밀이다. 아무도 모른다. 나만 안다.")
    return r


@room
def k_smithy():
    r = hall("k_smithy", "브론의 대장간", (5, 5), (1, 1))
    F = 19
    r.door("door", 5, F, "k_market", "smithy", style="wood", label="시장")
    # 안쪽 창고: 환영 벽 뒤 (여우창문)
    r.fill(30, 2, 31, F - 1)
    r.fill(30, F - 4, 31, F - 1, "I")
    stone(r, "k_stone_smithy", 35, F, "녹은 쇳물 속에서 굳은 보라 결정.")
    r.add("npc", id="bron", who="bron", x=21, y=F, face="left")
    r.add("prop", kind="k_forge", x=14, y=F)
    r.add("prop", kind="k_anvil", x=18, y=F)
    r.add("prop", kind="k_rack", x=26, y=F)
    r.add("prop", kind="k_barrel", x=10, y=F, fill="water")
    r.add("prop", kind="k_crates", x=34, y=F, n=2)
    r.add("prop", kind="chain", x=22, y=2, h=4)
    r.add("prop", kind="k_lantern", x=8, y=2, len=2)
    return r


@room
def k_market_alley():
    r = city("k_market_alley", "시장 뒷골목", (6, 4), (1, 1))
    F = 19
    r.ground(F)
    r.exit_left("west", F - 5, F - 1, "k_market", "east")
    r.exit_right("east", F - 5, F - 1, "k_knights_yard", "west")
    r.door("grate", 9, F, "k_sewer_5", "grate", style="iron", label="하수도 철창",
           lock="k_sewer_grate", lock_msg="녹슨 하수도 철창. 안쪽에서 빗장이 걸려 있다.")
    r.door("roof", 30, F, "k_roof_1", "alley", style="stair_up", label="지붕 사다리",
           lock="ab_wings,k_walls_talk", lock_msg="지붕으로 가는 사다리. 지금은 지붕에 올라갈 일이 없다.")
    r.fill(17, F - 2, 20, F - 1)  # 쌓인 나무 상자
    r.plat(22, 26, 12)
    r.add("npc", id="cit", who="k_citizen_c", x=24, y=F, face="left", talk="npc_k_alley")
    r.add("prop", kind="k_crates", x=18, y=F - 2, n=2)
    r.add("prop", kind="k_barrel", x=14, y=F, fill="water")
    r.add("prop", kind="k_laundry", x=2, y=5, w=16)
    r.add("prop", kind="k_laundry", x=20, y=8, w=16)
    r.add("prop", kind="k_grate", x=9, y=F, w=3, h=1)
    r.add("prop", kind="k_lamp", x=35, y=F, h=4)
    r.add("prop", kind="k_window", x=5, y=F - 8, w=2, h=2, lit=False)
    r.add("prop", kind="k_window", x=33, y=F - 10, w=2, h=2)
    return r


# ═══════════════════════════════════════════════════════════
# 은사자 기사단: 연무장 · 막사 · 성벽
# ═══════════════════════════════════════════════════════════

@room
def k_knights_yard():
    r = city("k_knights_yard", "기사단 연무장", (7, 4), (2, 1))
    F = 19
    r.ground(F)
    r.exit_left("west", F - 5, F - 1, "k_market_alley", "east")
    r.exit_right("east", F - 5, F - 1, "k_clock_street", "west")
    r.add("gate", id="east_gate", x=76, y=F - 5, w=1, h=5, open_if="k_clock_arrived", look="bars")
    r.door("barracks", 8, F, "k_barracks", "door", style="wood", label="막사")
    r.door("stair", 72, F, "k_walls", "stair", style="stair_up", label="성벽",
           lock="k_spar_done", lock_msg="성벽 계단. 기사가 막아선다. '단장님 허락 없이는 못 올라갑니다!'")
    # 관람대
    r.fill(58, F - 3, 67, F - 1)
    r.fill(56, F - 1, 57, F - 1)
    r.fill(57, F - 2, 57, F - 2)
    r.add("save", id="candle", x=3, y=F, style="candle")
    # 대련 (레오니가 기다림)
    r.add("trigger", id="spar_tg", x=30, y=F - 6, w=3, h=6, run="k_spar", cond="k_met_leonie,!k_spar_done", once=False)
    r.add("spawn", id="spar", x=34, y=F, face="right")
    r.add("spawn", id="spar_l", x=48, y=F, face="left")
    r.add("npc", id="leonie", who="leonie", x=46, y=F, face="left", cond="k_met_leonie,!k_spar_done")
    r.add("npc", id="leonie_after", who="leonie", x=46, y=F, face="left", cond="k_beast_down")
    r.add("npc", id="kael", who="kael", x=18, y=F, face="right", cond="k_met_leonie")
    r.add("npc", id="kn_a", who="k_knight", x=62, y=F - 3, face="left", talk="npc_k_yard_a")
    r.add("npc", id="kn_b", who="k_knight_b", x=24, y=F, face="right", talk="npc_k_yard_b")
    for x in (50, 53):
        r.add("prop", kind="k_dummy", x=x, y=F)
    r.add("prop", kind="k_rack", x=13, y=F)
    r.add("prop", kind="k_statue_lion", x=40, y=F)
    r.add("prop", kind="k_flag", x=59, y=F - 3, h=6)
    r.add("prop", kind="k_flag", x=66, y=F - 3, h=6)
    r.add("prop", kind="k_banner", x=28, y=2, w=2, h=5)
    r.add("prop", kind="k_banner", x=44, y=2, w=2, h=5)
    for x in (4, 36, 70):
        r.add("prop", kind="k_lamp", x=x, y=F, h=4)
    r.add("sign", x=69, y=F, look="board",
          text="은사자 기사단 수칙|하나, 검은 지키기 위해 뽑는다.|둘, 시민 앞에서 먼저 뽑지 않는다.|셋, 단장님 크림빵에 손대지 않는다. (부단장 카엘 추가)")
    return r


@room
def k_barracks():
    r = hall("k_barracks", "막사", (8, 5), (1, 1))
    F = 19
    r.door("door", 4, F, "k_knights_yard", "barracks", style="wood", label="연무장")
    r.plat(24, 28, 15)
    r.fill(30, 12, 36, F - 1)  # 옷장
    note(r, "k_note_1", 33, 12, 1,
         "10년 전 그 밤, 하늘이 둘로 갈라지고 별 하나가 옛 성곽 위로 떨어졌다.|불타는 거리에서 마력 한 톨 없는 빈민가 소녀가 막대기 하나로 아이들을 지켰다고 한다.|— 은사자 기사단 기록, '별이 떨어진 밤' 1")
    book(r, "k_book_1", 14, F, "『은사자 전기』")
    r.add("npc", id="kn", who="k_knight_b", x=22, y=F, face="left", talk="npc_k_barracks")
    for x in (10, 18):
        r.add("prop", kind="bed_prop", x=x, y=F)
    r.add("prop", kind="k_rack", x=26, y=F)
    r.add("prop", kind="desk", x=14, y=F, w=2)
    r.add("prop", kind="k_banner", x=20, y=2, w=2, h=4)
    r.add("prop", kind="k_lantern", x=12, y=2, len=2)
    windows(r, (8,), F - 9, 2, 4)
    return r


@room
def k_walls():
    r = city("k_walls", "성벽 위", (7, 3), (2, 1))
    F = 17
    r.ground(F)
    r.exit_left("west", F - 5, F - 1, "k_roof_1", "walls")
    r.exit_right("east", F - 5, F - 1, "k_roof_4", "walls")
    r.add("gate", id="west_gate", x=2, y=F - 5, w=1, h=5, open_if="k_walls_talk", look="bars")
    r.add("gate", id="east_gate", x=75, y=F - 5, w=1, h=5, open_if="k_clock_arrived", look="bars")
    r.door("stair", 10, F, "k_knights_yard", "stair", style="stair_down", label="연무장")
    for x in range(16, 72, 9):
        r.fill(x, F - 1, x + 1, F - 1)  # 성가퀴
    r.fill(56, F - 5, 61, F - 1)  # 망루 받침
    r.add("trigger", id="talk_tg", x=34, y=F - 6, w=3, h=6, run="k_walls_talk", cond="k_spar_done,!k_walls_talk")
    r.add("npc", id="leonie", who="leonie", x=44, y=F, face="left", cond="k_spar_done,!k_walls_talk")
    r.add("spawn", id="look", x=40, y=F, face="right")
    for x in (20, 47, 65):
        r.add("prop", kind="k_flag", x=x, y=F - 1, h=5)
    r.add("prop", kind="k_banner", x=30, y=F + 1, w=2, h=4)
    r.add("prop", kind="k_lamp", x=58, y=F - 5, h=3)
    r.add("sign", x=6, y=F, look="none", text="성벽 서쪽 끝 철창|너머로 시장 지붕들이 이어진다. 굴뚝마다 연기가 오른다.")
    return r


# ═══════════════════════════════════════════════════════════
# 지붕 (불꽃 날개: 활공 · 굴뚝 상승 기류 · 가고일 · 도마뱀) — 이졸데 지붕 경주
# ═══════════════════════════════════════════════════════════

@room
def k_roof_1():
    r = city("k_roof_1", "지붕 위 (굴뚝 숲)", (5, 2), (2, 2))
    # 맨 아래: 골목 바닥 가시 (떨어지면 직전 지붕으로)
    spikes_under(r, 42, 0, 79)
    # 아래층 지붕들
    r.fill(56, 38, 79, 45)          # R1: 성벽·사다리 쪽
    r.fill(38, 34, 50, 45)          # R2
    r.fill(14, 30, 28, 45)          # R3
    r.fill(18, 26, 19, 29)          # 굴뚝 (위로 열기)
    r.add("updraft", id="chimney", x=17, y=6, w=4, h=20, style="heat")
    # 위층 지붕들
    r.fill(4, 12, 12, 15)           # U1: 종루 지붕 (마도석)
    r.fill(26, 16, 40, 19)          # U2
    r.fill(50, 19, 79, 22)          # U3
    stone(r, "k_stone_roof1", 7, 12, "굴뚝 연기가 닿지 않는 종루 꼭대기의 결정.")
    r.exit_right("walls", 33, 37, "k_walls", "west")
    r.exit_right("east", 14, 18, "k_roof_2", "west")
    r.door("alley", 66, 38, "k_market_alley", "roof", style="stair_down", label="뒷골목")
    r.add("spawn", id="race", x=70, y=38, face="left")
    r.add("npc", id="isolde", who="isolde", x=74, y=38, face="left", cond="k_race_ready,!k_race_won")
    r.add("enemy", id="garg1", kind="gargoyle", x=40, y=16, face="left")
    r.add("enemy", id="garg2", kind="gargoyle", x=50, y=34, face="right")
    r.add("enemy", id="liz1", kind="star_lizard", x=62, y=38)
    r.add("enemy", id="liz2", kind="star_lizard", x=60, y=19)
    for x, y, h in ((60, 38, 2), (75, 38, 3), (44, 34, 2), (24, 30, 2), (34, 16, 2), (70, 19, 2), (8, 12, 3)):
        r.add("prop", kind="k_chimney", x=x, y=y, h=h)
    r.add("prop", kind="k_chimney", x=18, y=26, h=1)
    r.add("prop", kind="k_laundry", x=41, y=27, w=9)
    r.add("prop", kind="k_bunting", x=52, y=11, w=26, sag=2)
    r.add("prop", kind="k_flag", x=12, y=12, h=4)
    r.add("prop", kind="k_window", x=44, y=40, w=2, h=2)
    r.add("prop", kind="k_window", x=20, y=36, w=2, h=2, lit=False)
    r.add("sign", x=72, y=38, look="none", text="지붕 위|굴뚝마다 따뜻한 연기가 솟는다. 날개를 펴고 열기를 타면 위로 올라갈 수 있을 것 같다.")
    return r


@room
def k_roof_2():
    r = city("k_roof_2", "지붕 위 (빨래 골목)", (7, 2), (2, 1))
    spikes_under(r, 21, 0, 79)
    r.fill(0, 19, 12, 22)           # A
    r.fill(24, 15, 34, 22)          # B
    r.fill(44, 19, 60, 22)          # C
    r.fill(56, 16, 57, 18)          # 굴뚝 발판
    r.fill(61, 12, 79, 22)          # D: 큰 집 (지붕 위로 동쪽 출구)
    r.clear(64, 15, 74, 18)         # 숨은 다락
    r.fill(61, 15, 63, 18, "I")     # 다락 벽 (여우창문)
    stone(r, "k_stone_attic", 70, 19, "먼지 쌓인 다락 상자 속 결정.")
    r.exit_left("west", 14, 18, "k_roof_1", "east")
    r.exit_right("east", 7, 11, "k_roof_3", "west")
    r.add("save", id="candle", x=5, y=19, style="candle")
    r.add("enemy", id="garg", kind="gargoyle", x=33, y=15, face="left")
    r.add("enemy", id="liz", kind="star_lizard", x=48, y=19)
    for x, y, h in ((28, 15, 2), (68, 12, 3), (76, 12, 2), (9, 19, 2)):
        r.add("prop", kind="k_chimney", x=x, y=y, h=h)
    r.add("prop", kind="k_laundry", x=13, y=10, w=11)
    r.add("prop", kind="k_laundry", x=35, y=9, w=9)
    r.add("prop", kind="k_window", x=48, y=21, w=2, h=1, lit=False)
    r.add("prop", kind="k_crates", x=68, y=19, n=2)
    r.add("prop", kind="k_lantern", x=70, y=15, len=1)
    r.add("sign", x=72, y=19, look="note", text="다락의 쪽지|여긴 내 비밀 기지. 단장님 그림 모음은 상자 밑에 있음. 건드리면 혼남. — 미아")
    return r


@room
def k_roof_3():
    r = city("k_roof_3", "지붕 위 (풍향계)", (9, 2), (2, 1))
    spikes_under(r, 21, 0, 79)
    r.fill(0, 12, 10, 22)           # A (서쪽 높은 지붕)
    r.fill(28, 17, 40, 22)          # B
    r.fill(34, 14, 35, 16)          # 굴뚝
    r.add("updraft", id="chimney", x=29, y=2, w=8, h=12, style="heat")
    r.plat(18, 24, 10)              # 돌아가는 길: 기류 꼭대기에서 서쪽 처마로
    r.plat(41, 45, 6)               # 풍향계 들보 (카엘의 투구)
    r.fill(52, 19, 64, 22)          # C
    r.fill(70, 15, 79, 22)          # D
    r.exit_left("west", 7, 11, "k_roof_2", "east")
    r.door("down", 75, 15, "k_roof_4", "up", style="stair_down", label="아래 지붕")
    r.add("pickup", id="k_helmet", kind="key", x=43, y=6, name="카엘의 투구", flag="k_helmet",
          text="은사자 문장이 박힌 투구. 안쪽에 '카엘 — 잃어버리면 단장님께 혼남'이라고 쓰여 있다.")
    r.add("enemy", id="garg1", kind="gargoyle", x=56, y=19, face="left")
    r.add("enemy", id="garg2", kind="gargoyle", x=72, y=15, face="left")
    r.add("enemy", id="liz", kind="star_lizard", x=30, y=17)
    for x, y, h in ((4, 12, 2), (58, 19, 2), (77, 15, 2)):
        r.add("prop", kind="k_chimney", x=x, y=y, h=h)
    r.add("prop", kind="k_chimney", x=34, y=14, h=1)
    r.add("prop", kind="k_flag", x=45, y=6, h=3, col="#c8a040")
    r.add("prop", kind="chain", x=41, y=0, h=6)
    r.add("prop", kind="k_bunting", x=11, y=6, w=17, sag=2.5)
    r.add("prop", kind="k_window", x=36, y=20, w=2, h=1)
    return r


@room
def k_roof_4():
    r = city("k_roof_4", "지붕 위 (시계 거리)", (9, 3), (2, 1))
    F = 19
    r.ground(F)
    for x0, x1 in ((26, 31), (50, 55)):
        r.clear(x0, F, x1, r.h - 1)
        spikes_under(r, F + 2, x0, x1)
    r.fill(38, F - 3, 43, F - 1)
    r.exit_left("walls", F - 5, F - 1, "k_walls", "east")
    r.door("up", 66, F, "k_roof_3", "down", style="stair_up", label="위 지붕")
    r.door("ladder", 12, F, "k_clock_street", "roof", style="stair_down", label="시계 거리")
    r.add("spawn", id="finish", x=62, y=F, face="left")
    r.add("enemy", id="liz", kind="star_lizard", x=44, y=F)
    for x, h in ((20, 2), (34, 3), (60, 2), (74, 2)):
        r.add("prop", kind="k_chimney", x=x, y=F, h=h)
    r.add("prop", kind="k_bunting", x=2, y=8, w=30, sag=2)
    r.add("prop", kind="k_gear", x=70, y=8, w=4, speed=0.3)
    r.add("prop", kind="k_window", x=44, y=F + 1, w=2, h=1)
    return r


# ═══════════════════════════════════════════════════════════
# 시계 구역: 시계 거리 · 태엽 공방 · 시계탑
# ═══════════════════════════════════════════════════════════

@room
def k_clock_street():
    r = city("k_clock_street", "시계 거리", (9, 4), (3, 1))
    F = 19
    r.ground(F)
    r.exit_left("west", F - 5, F - 1, "k_knights_yard", "east")
    r.exit_right("east", F - 5, F - 1, "k_cathedral", "west")
    # 높은 보도
    r.fill(54, F - 3, 74, F - 1)
    r.fill(51, F - 1, 53, F - 1)
    r.fill(52, F - 2, 53, F - 2)
    r.fill(75, F - 1, 77, F - 1)
    r.fill(75, F - 2, 76, F - 2)
    r.door("roof", 8, F, "k_roof_4", "ladder", style="stair_up", label="지붕")
    r.door("gearworks", 40, F, "k_gearworks", "door", style="stair_down", label="태엽 공방")
    r.door("tower", 106, F, "k_clocktower", "door", style="iron", label="시계탑",
           lock="k_gears_done", lock_msg="시계탑 문. 안쪽 톱니가 맞물리지 않아 꿈쩍도 않는다.")
    r.add("save", id="candle", x=96, y=F, style="candle")
    r.add("npc", id="clockmaker", who="k_clockmaker", x=64, y=F - 3, face="left")
    r.add("enemy", id="watch1", kind="watchman", x=28, y=F, patrol=6.0)
    r.add("enemy", id="watch2", kind="watchman", x=86, y=F, patrol=6.0)
    r.add("prop", kind="k_clock", x=64, y=7, w=6, hour=4)
    for x, w, s in ((16, 5, 0.4), (110, 7, -0.25), (82, 4, 0.5)):
        r.add("prop", kind="k_gear", x=x, y=6, w=w, speed=s)
    for x in (4, 24, 48, 80, 100, 116):
        r.add("prop", kind="k_lamp", x=x, y=F, h=4)
    r.add("prop", kind="k_sign", x=40, y=F - 6, icon="star")
    r.add("prop", kind="k_window", x=30, y=F - 9, w=2, h=2)
    r.add("prop", kind="k_window", x=90, y=F - 8, w=2, h=2, lit=False)
    r.add("prop", kind="k_bunting", x=2, y=3, w=36, sag=2)
    r.add("prop", kind="k_flowers", x=58, y=F - 3, w=2)
    return r


@room
def k_gearworks():
    r = hall("k_gearworks", "태엽 공방", (9, 5), (2, 1))
    F = 19
    r.door("door", 4, F, "k_clock_street", "gearworks", style="stair_up", label="시계 거리")
    r.plat(32, 46, 11)
    r.plat(22, 28, 15)
    r.plat(58, 72, 14)
    r.plat(50, 55, 16)
    # 톱니 시계 셋 — 답은 대성당 종소리 (새벽 5 · 정오 12 · 저녁 7)
    r.add("k_clock_dial", id="d_dawn", x=16, y=17, group="gear", answer=5, start=2, label="새벽", done_flag="k_gears_done")
    r.add("k_clock_dial", id="d_noon", x=40, y=9, group="gear", answer=12, start=9, label="정오", done_flag="k_gears_done")
    r.add("k_clock_dial", id="d_dusk", x=66, y=12, group="gear", answer=7, start=4, label="저녁", done_flag="k_gears_done")
    r.add("event", id="gears_ev", flag="k_gears_done", run="k_gears_solved", done="k_gears_seen")
    r.add("enemy", id="watch", kind="watchman", x=50, y=F, patrol=5.0)
    book(r, "k_book_2", 76, F, "『시간을 거스르는 태엽』")
    for x, y, w, s in ((8, 6, 6, 0.3), (28, 4, 4, -0.5), (54, 5, 8, 0.2), (74, 9, 5, -0.4)):
        r.add("prop", kind="k_gear", x=x, y=y, w=w, speed=s)
    r.add("prop", kind="k_pipe", x=1, y=4, w=78, dir="h", drip=False)
    r.add("prop", kind="k_lantern", x=20, y=2, len=2)
    r.add("prop", kind="k_lantern", x=60, y=2, len=2)
    r.add("prop", kind="desk", x=72, y=F, w=3)
    r.add("sign", x=10, y=F, look="board",
          text="공방 일지|이 시계 셋은 대성당 종과 함께 울려야 시계탑 태엽이 맞물린다.|새벽·정오·저녁 — 종이 몇 번 치는지는 대성당 게시판에.|불을 쬐면 바늘이 한 시간씩 돈다. 태엽 쇠가 열을 먹으면 늘어나니까. — 시계공 오토")
    return r


@room
def k_clocktower():
    r = hall("k_clocktower", "시계탑", (11, 1), (1, 3), theme="kingdom_in")
    FB = r.h - 4  # 65
    r.door("door", 6, FB, "k_clock_street", "tower", style="iron", label="시계 거리")
    # 아래층
    r.plat(24, 32, 60)
    r.plat(14, 20, 55)
    r.fill(28, 51, 38, 52)          # 대성당 쪽 발코니
    r.door("balcony", 35, 51, "k_cathedral", "balcony", style="wood", label="대성당 위층")
    r.plat(4, 10, 50)
    # 톱니 사이 바람 (불꽃 날개로 꼭대기까지)
    r.add("updraft", id="shaft", x=11, y=8, w=4, h=41, style="wind")
    r.plat(22, 27, 30)
    stone(r, "k_stone_tower", 25, 30, "톱니 사이에 끼어 있던 결정.")
    r.plat(2, 8, 24)
    # 꼭대기 층 (가운데 구멍으로 바람이 솟음)
    r.fill(1, 12, 10, 13)
    r.fill(15, 12, 38, 13)
    r.exit_left("top", 7, 11, "k_noble", "east")
    r.add("gate", id="bridge_gate", x=2, y=7, w=1, h=5, open_if="k_duel_called", look="bars")
    r.add("save", id="top", x=30, y=12, style="candle")
    r.add("trigger", id="top_tg", x=20, y=6, w=5, h=6, run="k_tower_top", cond="k_gears_done,!k_tower_top")
    r.add("spawn", id="wolf", x=34, y=12)
    r.add("enemy", id="liz1", kind="star_lizard", x=6, y=50)
    r.add("enemy", id="liz2", kind="star_lizard", x=24, y=30)
    r.add("enemy", id="garg", kind="gargoyle", x=4, y=24, face="right")
    r.add("prop", kind="k_clock", x=27, y=5, w=8, hour=12)
    r.add("prop", kind="k_bell", x=20, y=2)
    for x, y, w, s in ((30, 40, 10, 0.15), (6, 34, 6, -0.3), (32, 20, 6, 0.4), (8, 58, 8, -0.2), (34, 62, 5, 0.5)):
        r.add("prop", kind="k_gear", x=x, y=y, w=w, speed=s)
    r.add("prop", kind="chain", x=24, y=14, h=10)
    r.add("prop", kind="chain", x=10, y=26, h=8)
    r.add("prop", kind="k_forge", x=20, y=FB)
    r.add("prop", kind="k_lantern", x=30, y=46, len=2)
    windows(r, (31,), 9, 3, 5)
    r.add("sign", x=12, y=FB, look="none", text="시계탑 바닥|태엽 화로의 바람이 톱니 사이로 위까지 솟는다. 날개를 펴고 바람을 타자.")
    return r


# ═══════════════════════════════════════════════════════════
# 대성당 · 지하 묘지
# ═══════════════════════════════════════════════════════════

@room
def k_cathedral():
    r = hall("k_cathedral", "대성당", (12, 3), (2, 2))
    F = r.h - 4  # 42
    r.exit_left("west", F - 5, F - 1, "k_clock_street", "east")
    # 위층 발코니 (서쪽: 시계탑 문 / 동쪽: 서고)
    r.fill(1, 19, 24, 20)
    r.fill(56, 19, 78, 20)
    r.door("balcony", 4, 19, "k_clocktower", "balcony", style="wood", label="시계탑")
    for x0, x1, y in ((20, 26, 36), (10, 16, 30), (18, 24, 24), (54, 60, 36), (62, 68, 30), (56, 62, 24)):
        r.plat(x0, x1, y)
    # 제단 촛불 열기 → 샹들리에 위 마도석
    r.plat(36, 44, 37)
    r.add("updraft", id="altar_heat", x=39, y=6, w=3, h=30, style="heat", power=0.8)
    r.plat(38, 42, 8)
    stone(r, "k_stone_cathedral", 40, 8, "샹들리에 위에서 촛농에 덮여 있던 결정.")
    r.door("crypt", 72, F, "k_crypt", "up", style="stair_down", label="지하 묘지",
           lock="k_tower_top", lock_msg="지하 묘지로 가는 계단. '죄송합니다, 지금은 아무도 내려가실 수 없습니다.' — 사제")
    r.add("save", id="candle", x=8, y=F, style="candle")
    r.add("npc", id="priest", who="k_priest", x=48, y=F, face="left")
    book(r, "k_book_3", 74, 19, "『빛의 기도서 (어린이용)』")
    r.add("sign", x=28, y=F, look="board",
          text="대성당 종 치는 시각|새벽 — 다섯 번|정오 — 열두 번|저녁 — 일곱 번|(빛의 신 루멘께 드리는 기도 시간을 알리는 종입니다)")
    r.add("prop", kind="k_altar", x=40, y=37)
    for x in (34, 46):
        r.add("prop", kind="k_candelabra", x=x, y=F)
    for x in (14, 20, 56, 62):
        r.add("prop", kind="k_pew", x=x, y=F, w=4)
    for x, y, w, h in ((12, 16, 4, 10), (40, 30, 6, 16), (68, 16, 4, 10)):
        r.add("prop", kind="k_glass", x=x, y=y, w=w, h=h)
    r.add("prop", kind="chandelier", x=40, y=2, len=5)
    r.add("prop", kind="k_banner", x=28, y=21, w=2, h=6)
    r.add("prop", kind="k_banner", x=52, y=21, w=2, h=6)
    for x in (30, 50):
        r.add("prop", kind="pillar", x=x, y=F, h=20)
    r.add("prop", kind="bookshelf", x=70, y=19, w=4, h=5)
    r.add("prop", kind="bookshelf", x=64, y=19, w=3, h=4)
    return r


@room
def k_crypt():
    r = hall("k_crypt", "지하 묘지", (12, 5), (2, 1), dark=0.35)
    F = 19
    r.door("up", 4, F, "k_cathedral", "crypt", style="stair_up", label="대성당")
    # 별 수정 장벽 (낮은 천장 아래 통로를 막음)
    r.fill(36, 2, 46, 13)
    r.add("k_crystal_wall", id="cw", x=40, y=14, w=2, h=5, done_flag="k_crypt_open", period=2.4, range=12)
    r.add("trigger", id="seen_tg", x=24, y=13, w=3, h=6, run="k_crypt_wall", cond="k_tower_top,!k_crypt_seen")
    r.add("event", id="open_ev", flag="k_crypt_open", run="k_crypt_broken", done="k_crypt_broken_seen")
    r.door("sewer", 74, F, "k_sewer_1", "crypt", style="stair_down", label="하수도")
    # 숨은 감실 (여우창문) — 수호의 깃털
    r.fill(20, 2, 34, 8)
    r.clear(24, 4, 31, 7)
    r.fill(20, 4, 23, 7, "I")
    r.plat(8, 13, 14)
    r.plat(14, 19, 8)
    r.add("pickup", id="k_feather_crypt", kind="feather", x=28, y=8, name="수호의 깃털", text="최대 체력이 1 늘었다.")
    note(r, "k_note_2", 62, F, 2,
         "별이 떨어진 다음 날, 별 조각을 줍던 이들이 하나둘 사라졌다.|그들은 스스로를 '별을 좇는 자들'이라 불렀다. 별 너머의 누군가가 자신들을 부른다고.|— 대성당 묘지기의 일기")
    r.add("spawn", id="leonie", x=30, y=F)
    r.add("enemy", id="liz", kind="star_lizard", x=60, y=F)
    for x in (10, 16, 52, 58, 66):
        r.add("prop", kind="candles", x=x, y=F)
    r.add("prop", kind="k_statue_lion", x=14, y=F)
    r.add("prop", kind="k_statue_lion", x=68, y=F, flip=True)
    r.add("prop", kind="k_rubble", x=50, y=F, w=3)
    r.add("prop", kind="k_crystal", x=34, y=F, h=2)
    r.add("prop", kind="k_crystal", x=48, y=F, h=3)
    r.add("prop", kind="chain", x=56, y=2, h=5)
    return r


# ═══════════════════════════════════════════════════════════
# 하수도 (수문 밸브 3개 · 별 수정 장벽 · 해파리) → 별 신도 은신처
# ═══════════════════════════════════════════════════════════

@room
def k_sewer_1():
    r = hall("k_sewer_1", "하수도 입구", (13, 6), (1, 1), theme="sewer", music="basement", dark=0.2)
    F = 19
    r.door("crypt", 34, F, "k_crypt", "sewer", style="stair_up", label="지하 묘지")
    r.exit_left("west", F - 5, F - 1, "k_sewer_2", "east")
    r.add("save", id="candle", x=28, y=F, style="candle")
    r.plat(10, 18, 14)
    r.add("enemy", id="jelly1", kind="sewer_jelly", x=14, y=F)
    r.add("enemy", id="jelly2", kind="sewer_jelly", x=6, y=F)
    r.add("prop", kind="k_pipe", x=1, y=5, w=38, dir="h")
    r.add("prop", kind="k_pipe", x=22, y=F, h=10, dir="v", drip=False)
    r.add("prop", kind="k_grate", x=16, y=8, w=2, h=2)
    r.add("prop", kind="k_lantern", x=30, y=2, len=2)
    r.add("prop", kind="k_crystal", x=4, y=F, h=2, col="#6af0e0")
    return r


@room
def k_sewer_2():
    r = hall("k_sewer_2", "하수도 · 수정 통로", (11, 6), (2, 1), theme="sewer", music="basement", dark=0.2)
    F = 19
    r.exit_right("east", F - 5, F - 1, "k_sewer_1", "west")
    # 별 수정 장벽 (방벽으로 되쏘기)
    r.fill(46, 2, 56, 13)
    r.add("k_crystal_wall", id="cw", x=50, y=14, w=2, h=5, done_flag="k_sw2_wall", period=2.2, range=12)
    # 서쪽: 높은 턱 + 수로 다리 (물이 빠지면 다리 밑 굴에 별철)
    r.fill(1, 14, 12, 16)
    r.exit_left("west", 9, 13, "k_sewer_3", "east")
    r.clear(1, 19, 35, 20)
    r.plat(13, 35, 14)
    r.add("k_water", id="channel", x=1, y=17, w=35, h=4, low_y=21, low_if="k_sw2_low", safe_x=38, safe_y=19)
    r.add("k_valve", id="valve", x=38, y=F, flag="k_sw2_low", label="수로 밸브",
          on_text="쿠르르… 수로 물이 빠진다.", off_text="수로에 물이 다시 찬다.")
    r.add("pickup", id="k_star_iron", kind="key", x=6, y=21, name="별철 조각", flag="k_star_iron",
          text="떨어진 별에서 나온 쇠. 차갑고, 희미하게 빛난다. 브론이 찾던 것이다.")
    r.add("enemy", id="cult", kind="cultist", x=64, y=F)
    r.add("enemy", id="jelly", kind="sewer_jelly", x=26, y=14)
    r.add("prop", kind="k_pipe", x=58, y=6, w=20, dir="h")
    r.add("prop", kind="k_pipe", x=2, y=8, w=10, dir="h")
    r.add("prop", kind="k_grate", x=70, y=F - 6, w=2, h=2)
    r.add("prop", kind="k_crystal", x=58, y=F, h=2)
    r.add("prop", kind="k_crystal", x=44, y=F, h=3)
    r.add("prop", kind="k_cult_circle", x=66, y=F, w=6)
    return r


@room
def k_sewer_3():
    r = hall("k_sewer_3", "하수도 · 배수조", (9, 6), (2, 1), theme="sewer", music="basement", dark=0.2, floor=3)
    FB = 20
    # 동쪽 높은 턱 (들어오는 곳)
    r.fill(64, 12, 78, FB - 1)
    r.exit_right("east", 7, 11, "k_sewer_2", "west")
    # 서쪽 선반 (밸브) + 그 아래 수문 굴 → 하수도4
    r.fill(1, 12, 15, 13)
    r.exit_left("west", 15, 19, "k_sewer_4", "east")
    r.add("gate", id="sluice", x=15, y=14, w=1, h=6, open_if="k_sw3_low", look="bars")
    # 배수조 계단 (물이 빠지면 밟고 나옴)
    r.fill(60, 16, 63, FB - 1)
    r.fill(19, 16, 21, FB - 1)
    r.add("k_water", id="basin", x=16, y=12, w=48, h=8, low_y=20, low_if="k_sw3_low", safe_x=70, safe_y=12)
    for x in (23, 31, 39, 47, 55):
        r.add("k_raft", id="raft%d" % x, x=x, y=12, w=4)
    r.add("k_valve", id="valve", x=8, y=12, flag="k_sw3_low", label="배수 밸브",
          on_text="콰르르… 물이 빠지고 수문이 열린다!", off_text="수문이 닫히고 물이 다시 찬다.")
    r.add("k_valve", id="valve_in", x=6, y=FB, flag="k_sw3_low", label="수문 밸브",
          on_text="콰르르… 물이 빠지고 수문이 열린다!", off_text="수문이 닫히고 물이 다시 찬다.")
    stone(r, "k_stone_basin", 42, FB, "배수조 바닥에 가라앉아 있던 결정.")
    r.add("enemy", id="jelly", kind="sewer_jelly", x=40, y=FB)
    r.add("prop", kind="k_pipe", x=66, y=4, w=12, dir="h")
    r.add("prop", kind="k_pipe", x=30, y=2, h=9, dir="v")
    r.add("prop", kind="k_grate", x=4, y=8, w=3, h=3)
    r.add("prop", kind="k_lantern", x=72, y=2, len=2)
    r.add("sign", x=74, y=12, look="board", text="배수조 관리 수칙|서쪽 밸브: 물 빼기(수문 열림) / 다시 돌리면 물 채우기.|물이 찼을 때 뗏목 말고 물에 들어가지 말 것. 떠내려감.")
    return r


@room
def k_sewer_4():
    r = hall("k_sewer_4", "하수도 · 수직 갱도", (7, 6), (2, 1), theme="sewer", music="basement", dark=0.2, ceil=1, floor=3)
    FB = 20
    r.exit_right("east", 15, 19, "k_sewer_3", "west")
    # 서쪽 높은 턱 → 하수도5
    r.fill(1, 6, 29, 8)
    r.exit_left("west", 1, 5, "k_sewer_5", "east")
    # 갱도 (물이 차면 뗏목이 위로)
    r.fill(40, 1, 42, 16)
    r.add("k_water", id="shaft", x=30, y=6, w=10, h=14, low_y=20, low_if="!k_sw4_high", safe_x=46, safe_y=FB)
    r.add("k_raft", id="raft", x=33, y=6, w=6)
    r.add("updraft", id="current", x=30, y=4, w=10, h=16, style="star", power=0.6, on_if="k_sw4_high")
    r.add("k_valve", id="valve_raft", x=36, y=FB, flag="k_sw4_high", label="갱도 밸브",
          on_text="콸콸… 갱도에 물이 차오른다!", off_text="갱도의 물이 빠진다.")
    r.add("k_valve", id="valve_out", x=46, y=FB, flag="k_sw4_high", label="갱도 밸브",
          on_text="콸콸… 갱도에 물이 차오른다!", off_text="갱도의 물이 빠진다.")
    r.add("k_valve", id="valve_top", x=26, y=6, flag="k_sw4_high", label="갱도 밸브",
          on_text="콸콸… 갱도에 물이 차오른다!", off_text="갱도의 물이 빠진다.")
    r.add("enemy", id="cult", kind="cultist", x=14, y=6)
    r.add("enemy", id="jelly", kind="sewer_jelly", x=60, y=FB)
    r.add("prop", kind="k_pipe", x=44, y=6, w=34, dir="h")
    r.add("prop", kind="k_pipe", x=4, y=FB, h=11, dir="v", drip=False)
    r.add("prop", kind="k_grate", x=60, y=10, w=3, h=3)
    r.add("prop", kind="k_crystal", x=10, y=6, h=2)
    r.add("sign", x=50, y=FB, look="board", text="수직 갱도|밸브를 돌리면 갱도에 물이 찬다. 뗏목에 올라탄 채로 돌릴 것.|위쪽 밸브로 다시 뺄 수 있다.")
    return r


@room
def k_sewer_5():
    r = hall("k_sewer_5", "하수도 · 갈림길", (6, 6), (1, 1), theme="sewer", music="basement", dark=0.2, ceil=1)
    F = 19
    r.fill(30, 6, 38, 7)
    r.exit_right("east", 1, 5, "k_sewer_4", "west")
    r.plat(24, 29, 15)
    r.plat(16, 21, 11)
    r.plat(24, 29, 7)
    r.exit_left("west", F - 5, F - 1, "k_cult_den", "east")
    r.door("grate", 6, F, "k_market_alley", "grate", style="stair_up", label="시장 뒷골목")
    r.add("trigger", id="grate_tg", x=4, y=F - 6, w=5, h=6, run="k_grate_open", cond="!k_sewer_grate")
    r.add("save", id="candle", x=14, y=F, style="candle")
    r.add("enemy", id="cult", kind="cultist", x=26, y=F)
    r.add("prop", kind="k_grate", x=6, y=2, w=3, h=3)
    r.add("prop", kind="k_cult_circle", x=26, y=F, w=5)
    r.add("prop", kind="k_pipe", x=1, y=9, w=12, dir="h")
    r.add("prop", kind="k_crystal", x=36, y=F, h=2)
    r.add("prop", kind="k_lantern", x=20, y=1, len=2)
    return r


@room
def k_cult_den():
    r = hall("k_cult_den", "별 신도 은신처", (4, 6), (2, 1), theme="sewer", music="basement", dark=0.25)
    F = 19
    r.exit_right("east", F - 5, F - 1, "k_sewer_5", "west")
    r.plat(10, 16, 14)
    r.plat(62, 68, 14)
    r.plat(34, 44, 10)
    r.add("trigger", id="noxis_tg", x=56, y=F - 6, w=3, h=6, run="k_noxis", cond="k_crypt_open,!k_noxis_fled", once=False)
    r.add("spawn", id="noxis", x=30, y=F)
    r.add("spawn", id="sera", x=50, y=F, face="left")
    r.add("sign", id="record", x=24, y=F, look="book", cond="k_noxis_fled",
          text="별 신도의 기록|짐승들은 별의 마력에 끌린다. 별이 떨어진 밤부터 늘 그랬다.|— 그런데 요즘 짐승들이 끌려가는 곳은 별이 아니다.|붉은 머리의 어린 마녀. 그 아이의 마력이 별보다 더 크게 운다.|대사제님께서 기뻐하셨다. '그분이 보신 그릇이 맞구나.'")
    r.add("prop", kind="k_cult_circle", x=40, y=F, w=14)
    r.add("prop", kind="k_meteor", x=40, y=10, w=3, h=2)
    for x, h in ((8, 3), (20, 2), (56, 2), (72, 3)):
        r.add("prop", kind="k_crystal", x=x, y=F, h=h)
    r.add("prop", kind="k_banner", x=26, y=2, w=2, h=5, col="#241c44")
    r.add("prop", kind="k_banner", x=52, y=2, w=2, h=5, col="#241c44")
    r.add("prop", kind="candles", x=30, y=F)
    r.add("prop", kind="candles", x=50, y=F)
    r.add("prop", kind="k_rubble", x=66, y=F, w=4)
    return r


# ═══════════════════════════════════════════════════════════
# 투기장 (서브: 챔피언 가론)
# ═══════════════════════════════════════════════════════════

@room
def k_colosseum():
    r = hall("k_colosseum", "투기장", (1, 5), (2, 1))
    F = 19
    r.door("door", 6, F, "k_gate_street", "colosseum", style="grand", label="성문 거리")
    r.door("pit", 72, F, "k_arena", "door", style="stair_down", label="투기장 바닥",
           lock="k_arena_ok", lock_msg="투기장 바닥으로 가는 계단. 지배인의 허락 없이는 내려갈 수 없다.")
    for x0, x1, y in ((20, 34, 15), (44, 58, 15), (26, 52, 11)):
        r.plat(x0, x1, y)
    r.add("save", id="candle", x=13, y=F, style="candle")
    r.add("npc", id="master", who="k_arena_master", x=40, y=F, face="left")
    r.add("npc", id="garon", who="garon", x=62, y=F, face="left")
    r.add("npc", id="fan", who="k_citizen_c", x=28, y=15, face="right", talk="npc_k_arena_fan")
    for x in (22, 30, 46, 54):
        r.add("prop", kind="k_pew", x=x, y=15, w=3)
    r.add("prop", kind="k_banner", x=18, y=2, w=2, h=5, col="#5a1a3a")
    r.add("prop", kind="k_banner", x=60, y=2, w=2, h=5, col="#5a1a3a")
    r.add("prop", kind="k_rack", x=68, y=F)
    r.add("prop", kind="k_flag", x=40, y=11, h=6)
    for x in (10, 36, 66):
        r.add("prop", kind="k_lantern", x=x, y=2, len=2)
    r.add("sign", x=34, y=F, look="board", text="투기장 규칙|하나, 죽이지 않는다.|둘, 관중을 즐겁게 한다.|셋, 챔피언에게 이기면 '수호의 깃털'을 준다. (지금까지 아무도 못 받아 감)")
    return r


@room
def k_arena():
    r = hall("k_arena", "투기장 바닥", (1, 6), (2, 1), music="boss", ceil=1)
    F = 19
    r.door("door", 4, F, "k_colosseum", "pit", style="stair_up", label="투기장")
    r.plat(14, 20, 14)
    r.plat(60, 66, 14)
    r.add("trigger", id="fight_tg", x=22, y=F - 6, w=3, h=6, run="k_arena_fight", cond="k_arena_ok,!k_arena_won", once=False)
    r.add("spawn", id="garon", x=62, y=F)
    for x in (10, 30, 50, 70):
        r.add("prop", kind="k_banner", x=x, y=1, w=2, h=4, col="#5a1a3a")
    r.add("prop", kind="k_rack", x=74, y=F)
    r.add("prop", kind="k_rubble", x=40, y=F, w=2)
    for x in (2, 38):
        r.add("prop", kind="k_lantern", x=x + 18, y=1, len=2)
    return r


# ═══════════════════════════════════════════════════════════
# 밤: 귀족 구역 · 황궁 문 · 황궁 광장 (결투)
# ═══════════════════════════════════════════════════════════

@room
def k_noble():
    r = city("k_noble", "귀족 구역", (9, 1), (2, 1), theme="kingdom_night", music="kingdom_night")
    F = 19
    r.ground(F)
    r.exit_right("east", F - 5, F - 1, "k_clocktower", "top")
    r.exit_left("west", F - 5, F - 1, "k_palace_gate", "east")
    # 정원 울타리 (낮은 덤불)
    for x in (12, 34, 56):
        r.fill(x, F - 2, x + 3, F - 1)
    # 저택 발코니 길 (경비병 등불 위로 지나가는 다른 길)
    for x0, x1, y in ((16, 25, 13), (30, 40, 12), (47, 57, 13), (63, 72, 12)):
        r.plat(x0, x1, y)
    r.plat(36, 39, 6)
    stone(r, "k_stone_noble", 37, 6, "정원 덩굴 시렁 꼭대기의 결정.")
    for i, (x, p) in enumerate(((22, 6.0), (44, 5.0), (66, 6.0))):
        r.add("enemy", id="watch%d" % i, kind="watchman", x=x, y=F, patrol=p, alarm_flag="k_noble_alarm")
    r.add("event", id="alarm_ev", flag="k_noble_alarm", run="k_noble_alarm", done="k_noble_alarm_seen")
    for x in (6, 28, 50, 74):
        r.add("prop", kind="k_lamp", x=x, y=F, h=5)
    for x in (13, 35, 57):
        r.add("prop", kind="k_flowers", x=x + 1, y=F - 2, w=2)
    r.add("prop", kind="k_fountain", x=46, y=F)
    r.add("prop", kind="k_statue_lion", x=2, y=F)
    r.add("prop", kind="k_window", x=20, y=10, w=2, h=2)
    r.add("prop", kind="k_window", x=52, y=10, w=2, h=2, lit=False)
    r.add("prop", kind="k_window", x=68, y=9, w=2, h=2)
    r.add("prop", kind="k_banner", x=34, y=5, w=2, h=4)
    return r


@room
def k_palace_gate():
    r = city("k_palace_gate", "황궁 문", (8, 1), (1, 1), theme="kingdom_night", music="kingdom_night")
    F = 19
    r.ground(F)
    r.exit_right("east", F - 5, F - 1, "k_noble", "west")
    r.exit_left("west", F - 5, F - 1, "k_palace_plaza", "east")
    r.add("save", id="candle", x=30, y=F, style="candle")
    r.add("npc", id="kn_a", who="k_knight", x=14, y=F, face="right", talk="npc_k_palace_guard", cond="k_duel_called,!k_duel_done")
    r.add("npc", id="kn_b", who="k_knight_b", x=24, y=F, face="left", talk="npc_k_palace_guard", cond="k_duel_called,!k_duel_done")
    r.add("prop", kind="k_portcullis", x=19, y=F, w=5, h=7)
    r.add("prop", kind="k_statue_lion", x=10, y=F)
    r.add("prop", kind="k_statue_lion", x=28, y=F, flip=True)
    r.add("prop", kind="k_flag", x=6, y=F, h=8)
    r.add("prop", kind="k_flag", x=34, y=F, h=8)
    r.add("prop", kind="k_lantern", x=16, y=2, len=3)
    r.add("prop", kind="k_lantern", x=24, y=2, len=3)
    return r


@room
def k_palace_plaza():
    r = city("k_palace_plaza", "황궁 광장", (6, 1), (2, 1), theme="kingdom_night", music="kingdom_night")
    F = 19
    r.ground(F)
    r.exit_right("east", F - 5, F - 1, "k_palace_gate", "west")
    r.exit_left("west", F - 5, F - 1, "k_oldquarter_1", "east")
    r.add("gate", id="west_gate", x=2, y=F - 5, w=1, h=5, open_if="k_duel_done", look="bars")
    r.add("trigger", id="duel_tg", x=58, y=F - 6, w=3, h=6, run="k_duel", cond="k_duel_called,!k_duel_done", once=False)
    r.add("npc", id="leonie", who="leonie", x=30, y=F, face="right", cond="k_duel_called,!k_duel_done")
    r.add("spawn", id="duel", x=52, y=F, face="left")
    r.add("spawn", id="duel_l", x=28, y=F, face="right")
    r.add("spawn", id="child", x=10, y=F, face="right")
    r.add("prop", kind="k_fountain", x=40, y=F)
    for x in (8, 72):
        r.add("prop", kind="k_statue_lion", x=x, y=F, flip=(x > 40))
    for x in (16, 32, 48, 64):
        r.add("prop", kind="k_lamp", x=x, y=F, h=5)
    for x in (24, 56):
        r.add("prop", kind="k_flag", x=x, y=F, h=9)
    r.add("prop", kind="k_banner", x=38, y=1, w=4, h=6)
    r.add("prop", kind="k_statue_leonie", x=76, y=F)
    return r


# ═══════════════════════════════════════════════════════════
# 옛 성곽 지구 · 분화구 (레오니와 함께 → 운석수)
# ═══════════════════════════════════════════════════════════

@room
def k_oldquarter_1():
    r = city("k_oldquarter_1", "옛 성곽 지구", (4, 1), (2, 1), theme="starfall", music="starbeast")
    F = 19
    r.ground(F)
    r.exit_right("east", F - 5, F - 1, "k_palace_plaza", "west")
    r.exit_left("west", F - 5, F - 1, "k_oldquarter_2", "east")
    # 무너진 성벽 덩어리와 운석 파편 웅덩이
    r.fill(18, F - 3, 24, F - 1)
    r.fill(46, F - 4, 50, F - 1)
    r.clear(32, F, 38, F)
    r.plat(52, 58, 12)
    r.plat(8, 14, 13)
    r.add("enemy", id="cult1", kind="cultist", x=36, y=F + 1)
    r.add("enemy", id="cult2", kind="cultist", x=62, y=F)
    r.add("enemy", id="liz", kind="star_lizard", x=12, y=F)
    r.add("prop", kind="k_rubble", x=21, y=F - 3, w=4)
    r.add("prop", kind="k_rubble", x=60, y=F, w=5)
    for x, h in ((30, 2), (40, 3), (54, 2), (6, 2)):
        r.add("prop", kind="k_crystal", x=x, y=F if x not in (54,) else 12, h=h)
    r.add("prop", kind="k_statue_lion", x=70, y=F)
    r.add("prop", kind="k_meteor", x=35, y=F + 1, w=2, h=1)
    return r


@room
def k_oldquarter_2():
    r = Room("k_oldquarter_2", "황도 아르덴 · 무너진 성벽", A, "starfall", "starbeast", (3, 0), (1, 2))
    FB = r.h - 4  # 42
    r.ground(FB)
    r.fill(r.w - 1, 0, r.w - 1, FB - 6)
    r.fill(0, 20, 0, FB - 1)
    r.exit_right("east", FB - 5, FB - 1, "k_oldquarter_1", "west")
    r.fill(1, 19, 14, 20)
    r.exit_left("west", 14, 18, "k_oldquarter_3", "east")
    # 운석 틈의 별빛 기류
    r.fill(19, FB - 1, 24, FB - 1)
    r.add("updraft", id="crack", x=20, y=10, w=4, h=30, style="star")
    r.plat(28, 35, 35)
    r.plat(6, 12, 32)
    r.plat(30, 36, 8)
    stone(r, "k_stone_ruins", 33, 8, "무너진 성벽 꼭대기에 박힌 별 조각 결정.")
    r.add("enemy", id="garg1", kind="gargoyle", x=8, y=32, face="right")
    r.add("enemy", id="garg2", kind="gargoyle", x=12, y=19, face="right")
    r.add("enemy", id="liz", kind="star_lizard", x=32, y=35)
    r.add("prop", kind="k_meteor", x=21, y=FB, w=3, h=2)
    r.add("prop", kind="k_crystal", x=28, y=FB, h=3)
    r.add("prop", kind="k_crystal", x=10, y=FB, h=2)
    r.add("prop", kind="k_rubble", x=4, y=19, w=3)
    r.add("prop", kind="k_rubble", x=34, y=FB, w=4)
    return r


@room
def k_oldquarter_3():
    r = city("k_oldquarter_3", "별이 떨어진 거리", (2, 0), (1, 1), theme="starfall", music="starbeast")
    F = 19
    r.ground(F)
    r.exit_right("east", F - 5, F - 1, "k_oldquarter_2", "west")
    r.exit_left("west", F - 5, F - 1, "k_crater", "east")
    r.fill(6, F - 6, 9, F - 1)  # 부러진 기둥
    note(r, "k_note_3", 7, F - 6, 3,
         "별은 아무것도 부수지 않고 옛 성곽 한가운데 조용히 내려앉았다. 이상한 일이었다.|그 밤 하늘 높이, 별빛으로 된 여인의 그림자를 보았다는 사람들이 있었다.|누군가 그 그림자를 '별의 마녀'라 불렀다. — 제국 연대기, 끝 장")
    r.add("save", id="candle", x=32, y=F, style="candle")
    r.add("enemy", id="wolf", kind="star_wolf", x=18, y=F)
    r.add("prop", kind="k_rubble", x=24, y=F, w=4)
    r.add("prop", kind="k_crystal", x=14, y=F, h=3)
    r.add("prop", kind="k_crystal", x=36, y=F, h=2)
    r.add("prop", kind="k_lamp", x=28, y=F, h=4)
    return r


@room
def k_crater():
    r = Room("k_crater", "황도 아르덴 · 별이 떨어진 자리", A, "starfall", "starbeast", (0, 0), (2, 2))
    F = r.h - 4  # 42
    r.box(wall=1, floor=4, ceil=1)
    r.clear(0, 0, r.w - 1, 0)
    r.clear(1, 1, r.w - 2, 1)
    # 동쪽 가장자리 (옛 성곽에서 들어옴) → 분화구로 내려가는 바위
    r.fill(58, 19, 78, 21)
    r.exit_right("east", 14, 18, "k_oldquarter_3", "west")
    r.plat(48, 54, 26)
    r.plat(60, 66, 32)
    r.plat(50, 56, 37)
    r.plat(8, 16, 34)
    r.plat(22, 28, 28)
    r.add("trigger", id="beast_tg", x=36, y=F - 8, w=6, h=8, run="k_crater", cond="k_duel_done,!k_beast_down", once=False)
    r.add("spawn", id="beast", x=22, y=F)
    r.add("spawn", id="sera", x=44, y=F, face="left")
    r.add("spawn", id="noxis", x=12, y=34)
    r.add("prop", kind="k_meteor", x=20, y=F, w=8, h=5)
    r.add("prop", kind="k_cult_circle", x=20, y=F, w=16)
    for x, h in ((6, 3), (32, 2), (52, 4), (70, 3), (64, 2)):
        r.add("prop", kind="k_crystal", x=x, y=F, h=h)
    r.add("prop", kind="k_rubble", x=60, y=19, w=5)
    r.add("prop", kind="k_rubble", x=74, y=F, w=4)
    r.add("prop", kind="k_statue_lion", x=72, y=19)
    return r


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
