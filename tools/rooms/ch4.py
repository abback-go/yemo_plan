"""4장 방 — 황금창의 수호자 (docs/archive/sera/chapter4.md 3절·7.2절). roomgen.py가 불러온다.
from roomgen import Room, room, overlay — 1장 roomgen.py와 같은 문법.

지도 영역 "temple" (칸 좌표 x, y — 1칸 = 40×23타일):

  y -7                                    [spire_top 12~13]
  y -7..-5                           [S5 11]
  y -5..-3                                [S4 12]
  y -3..-1                           [S3 11]
  y -1.. 1                                [S2 12]
  y  1.. 3                           [S1 11]           [bell_3 13~14]
  y  2.. 4                                                   [bell_2 14 (3~4)]
  y  3                     [sanctum 9~10]
  y  4                     [nave 9~10][monk_cells 11~12][bell_1 13 (4~5)]
  y  5   [mirror_3 3~4][mirror_2 5~6][mirror_1 7~8][cloister 9~10][garden 11][choir 12]
  y  6                          [road_4 7~8 (6~7)][gate 9~10][archive_1 11~12][scriptorium 13]
  y  7   [cave 2][road_2 3 (7~8)][road_3 4~5][hut 6]   [crypt_1 9~10][archive_2 11~12]
  y  8   [road 0][road_1 1~2]                          [crypt_2 9~10]

흐름: 학교 앞마당(ch4_start) → tp_road(전이진) → 순례길 → 정문(아우렐리아) → 회랑(거점) → 시련 셋(거울·종·기록, 순서 자유)
      → 본당(아우렐리아와의 대화) → 내전(폭주) → 첨탑 추격 1~5 → 꼭대기 결전 → 끝.
선택 구역: 얼음 동굴(여우창문), 필사실, 지하 묘소·성유물실(유성 낙화 봉인석).
게이트: 불꽃 날개(바람의 능선·대신전 오르막의 낭떠러지), 불꽃 방벽(거울 Ⅲ의 빛 되돌리기), 유성 낙화(지하 봉인석 — 선택).

개발용 시험 방(지도·ROOMS에 넣지 않음): dev_tp_temple · dev_tp_dark · dev_tp_spire · dev_tp_mount · dev_tp_court · dev_tp_arena
"""
from roomgen import Room, room, overlay  # noqa: F401

AREA = "temple"


def troom(rid, title, theme, music, cell, cells, dark=0.0):
    """4장 방: 영역 temple + 동료 유지 장치(tp_ally — 저장·부활 뒤에도 레오니가 곁에)"""
    r = Room(rid, title, AREA, theme, music, cell, cells, dark)
    r.add("tp_ally", id="ally")
    return r


def spike_pit(r, x0, x1, top):
    """top 행부터 판 낭떠러지: 바닥 두 줄 + 가시 한 줄 (떨어지면 다치고 가까운 발판으로)"""
    r.clear(x0, top, x1, r.h - 1)
    r.fill(x0, r.h - 2, x1, r.h - 1)
    r.fill(x0, r.h - 3, x1, r.h - 3, "^")


def deco(r, items):
    """소품 여러 개: (종류, x, y, {추가 값})"""
    for it in items:
        kind, x, y = it[0], it[1], it[2]
        kw = it[3] if len(it) > 3 else {}
        r.add("prop", kind=kind, x=x, y=y, **kw)


def candle(r, n, x, y):
    """베네딕타의 기도 촛불 (서브 퀘스트 tp_candles): 불을 붙이면 tp_candle_<n>"""
    g = "tp_candle_%d" % n
    r.add("brazier", id="candle%d" % n, x=x, y=y, style="seal", group=g, done_flag=g)
    r.add("puzzle", id="candle_pz%d" % n, group=g, mode="all", done_flag=g)
    r.add("event", id="candle_ev%d" % n, flag=g, run="tp_candle_lit", done="tp_candle_seen_%d" % n)


# ═══════════════════════════════════════════════════════════
# 순례길 (성산) — 눈 덮인 산길, 길 잃은 순례자의 그림자, 낭떠러지 활공
# ═══════════════════════════════════════════════════════════

@room
def tp_road():
    r = troom("tp_road", "성산 · 순례길 입구", "holymount", "temple", (0, 8), (1, 1))
    F = 19
    r.ground(F)
    r.fill(0, 0, 0, F - 1)
    r.exit_right("east", F - 5, F - 1, "tp_road_1", "west")
    r.add("warp", id="warp_circle", x=7, y=F, area="temple")
    r.add("spawn", id="warp", x=7, y=F, face="right")
    r.add("spawn", id="start", x=4, y=F, face="right")
    r.add("save", id="road", x=15, y=F, style="lantern")
    r.add("npc", id="pilgrim", who="tp_pilgrim", x=22, y=F, face="left")
    r.door("short", 33, F, "tp_gate", "short", style="stair_up", label="대신전 정문 (지름길)")
    r.ents[-1]["cond"] = "tp_gate_open"
    r.add("sign", x=11, y=F, look="stone",
          text="성산 순례길.|대신전까지 걸어서 반나절. 눈길과 벼랑을 조심할 것.|…요즘 길 잃은 순례자의 하얀 그림자가 나온다는 소문이 있다. 만나거든 등불을 비춰 줄 것.")
    deco(r, [
        ("tp_cairn", 3, F), ("tp_flags", 2, F - 10, dict(w=16, h=2)), ("tp_lantern", 19, F),
        ("tp_pine", 28, F, dict(h=9)), ("tp_shrine", 37, F), ("tp_pine", 25, F, dict(h=6)),
    ])
    return r


@room
def tp_road_1():
    """눈 덮인 산길: 낮은 턱 → 작은 낭떠러지 → 고원. 순례자의 그림자 둘, 높은 바위 위 마도석"""
    r = troom("tp_road_1", "성산 · 눈 덮인 산길", "holymount", "temple", (1, 8), (2, 1))
    F = 19
    r.ground(F)
    r.exit_left("west", F - 5, F - 1, "tp_road", "east")
    r.fill(22, F - 2, 33, F - 1)  # 오르막 턱
    spike_pit(r, 34, 38, F)  # 작은 낭떠러지
    r.fill(39, F - 4, 54, F - 1)  # 고원
    r.fill(55, F - 2, 62, F - 1)
    r.plat(44, 48, F - 10)  # 높은 바위 (2단 점프)
    r.fill(r.w - 1, 0, r.w - 1, F - 1)
    r.exit_right("east", F - 5, F - 1, "tp_road_2", "west")
    r.add("pickup", id="stone_road1", kind="stone", x=46, y=F - 10)
    r.add("enemy", id="shade1", kind="pilgrim_shade", x=29, y=F - 2, face="left")
    r.add("enemy", id="shade2", kind="pilgrim_shade", x=51, y=F - 4, face="left")
    r.add("trigger", id="talk", x=12, y=F - 6, w=2, h=6, run="tp_road1_talk")
    r.add("sign", x=60, y=F - 2, look="stone",
          text="순례자의 돌무더기.|돌 하나를 얹고 소원을 빈다.|대부분은 '무사히 내려가게 해 주세요'다.")
    deco(r, [
        ("tp_pine", 4, F, dict(h=8)), ("tp_cairn", 17, F), ("tp_lantern", 24, F - 2),
        ("tp_flags", 20, F - 11, dict(w=14, h=2)), ("tp_pine", 42, F - 4, dict(h=10)),
        ("tp_cairn", 58, F - 2), ("tp_pine", 66, F, dict(h=7)), ("tp_flags", 62, F - 10, dict(w=16, h=3)),
        ("tp_lantern", 72, F), ("tp_pine", 76, F, dict(h=9)),
    ])
    return r


@room
def tp_road_2():
    """벼랑길 (세로 2칸): 바위 턱을 지그재그로 올라 위로. 꼭대기 왼쪽 바위 틈(환영 벽) 너머가 얼음 동굴"""
    r = troom("tp_road_2", "성산 · 벼랑길", "holymount", "temple", (3, 7), (1, 2))
    F = r.h - 4  # 42
    r.fill(0, F, r.w - 1, r.h - 1)
    r.fill(0, 0, 0, F - 6)
    r.fill(r.w - 1, 0, r.w - 1, r.h - 1)
    r.exit_left("west", F - 5, F - 1, "tp_road_1", "east")
    # 순례자들이 벼랑에 박아 둔 나무 발판 (한 번 점프 높이 4칸씩, 지그재그)
    for x0, x1, y in ((26, 33, 38), (16, 22, 34), (6, 12, 30), (14, 20, 26), (14, 28, 22)):
        r.plat(x0, x1, y)
    r.fill(35, 30, 38, 31)  # 오른쪽 벽의 바위 턱 (쉼터)
    r.fill(30, 19, 38, 20)  # 꼭대기 (오른쪽 → 바람의 능선)
    r.exit_right("east", 14, 18, "tp_road_3", "west")
    # 꼭대기 왼쪽: 바위 턱 + 환영 벽 너머 얼음 동굴
    r.plat(8, 12, 19)
    r.fill(1, 19, 6, 20)
    r.exit_left("cave", 14, 18, "tp_cave", "east")
    r.fill(1, 13, 3, 18, "I")
    r.fill(0, 0, 0, 13)
    r.add("enemy", id="shade1", kind="pilgrim_shade", x=18, y=34, face="left")
    r.add("sign", x=4, y=F, look="stone", text="벼랑길.|발 디딜 곳을 잘 보고 오를 것.|— 바람이 바위 틈으로 휘파람을 분다. 어디선가 오래된 동굴 냄새가 난다.")
    deco(r, [
        ("tp_pine", 36, 30, dict(h=6)), ("tp_cairn", 9, 30), ("tp_lantern", 30, 38),
        ("tp_scaffold", 14, 42, dict(w=3, h=8)), ("tp_flags", 14, 12, dict(w=14, h=2)), ("tp_cairn", 34, 19),
        ("tp_pine", 6, F, dict(h=7)), ("tp_pine", 36, F, dict(h=8)), ("tp_lantern", 20, 22), ("tp_pine", 3, 19, dict(h=5)),
    ])
    return r


@room
def tp_cave():
    """얼음 동굴 (숨은 곳): 어린 레오니가 눈보라를 피했던 곳 — 견습 기사 배지, 마도석, 순례자의 일기"""
    r = troom("tp_cave", "성산 · 얼음 동굴", "icecave", "temple", (2, 7), (1, 1), dark=0.25)
    F = 19
    r.box(wall=1, floor=4, ceil=2)
    r.exit_right("east", F - 5, F - 1, "tp_road_2", "cave")
    r.fill(14, F - 2, 20, F - 1)  # 얼음 바위
    r.fill(4, F - 6, 10, F - 5)  # 배지가 있는 턱
    r.plat(24, 29, F - 9)  # 높은 턱 (마도석)
    r.fill(30, 2, 39, 6)  # 낮은 천장
    r.add("pickup", id="badge", kind="key", x=7, y=F - 6, flag="tp_badge_found", name="낡은 견습 기사 배지",
          text="작은 은 배지. 뒷면에 서툰 글씨로 '레오니'라고 새겨져 있다.")
    r.add("event", id="badge_ev", flag="tp_badge_found", run="tp_badge_found", done="tp_badge_seen")
    r.add("pickup", id="stone_cave", kind="stone", x=26, y=F - 9)
    r.add("pickup", id="diary", kind="note", x=33, y=F, name="얼어붙은 순례자의 일기",
          text="…눈보라가 그치지 않는다. 신부님은 아이들을 동굴 안쪽에 재웠다.|가장 작은 아이가 은 배지를 꼭 쥐고 잤다. 커서 기사가 될 거라고 했다. 마력도 없는 아이가.|…신부님은 웃지 않으셨다. '빛은 쓸모를 묻지 않는다'고만 하셨다.")
    r.add("enemy", id="shade1", kind="pilgrim_shade", x=24, y=F, face="left")
    deco(r, [
        ("tp_candles", 9, F), ("tp_shrine", 12, F), ("tp_cairn", 3, F), ("tp_rubble", 22, F, dict(w=2)),
        ("tp_candles", 6, F - 6), ("tp_chain", 18, 2, dict(h=3)),
    ])
    r.add("light", x=7, y=F - 8, r=4, color="#9ad0ff")
    r.add("light", x=26, y=F - 11, r=3, color="#c8b0ff")
    return r


@room
def tp_road_3():
    """바람의 능선: 끊긴 다리(16칸 낭떠러지)를 불꽃 날개로 활공. 아래에서 부는 바람을 타면 떠 있는 바위(마도석).
    건너편 얼음 사당 곁에 성가대원의 그림자(서브 퀘스트 tp_choir_voice)"""
    r = troom("tp_road_3", "성산 · 바람의 능선", "holymount", "temple", (4, 7), (2, 1))
    F = 19
    r.ground(F)
    r.exit_left("west", F - 5, F - 1, "tp_road_2", "east")
    r.fill(14, F - 3, 20, F - 1)  # 뛰어내리는 턱
    spike_pit(r, 21, 36, F)  # 끊긴 다리
    r.add("updraft", id="wind", x=27, y=4, w=3, h=16, style="wind", power=1.0)
    r.fill(24, 6, 26, 7)  # 떠 있는 바위
    r.add("pickup", id="stone_road3", kind="stone", x=25, y=6)
    r.fill(53, F - 3, 60, F - 1)
    spike_pit(r, 61, 64, F)
    r.fill(r.w - 1, 0, r.w - 1, F - 1)
    r.exit_right("east", F - 5, F - 1, "tp_hut", "west")
    r.add("enemy", id="choir_shade", kind="pilgrim_shade", x=47, y=F, face="left", free_flag="tp_choir_found",
          line="…아… 끝 소절이… 이제야 생각났어… 고마워요. 성가대로… 돌아가야지…")
    r.add("event", id="choir_ev", flag="tp_choir_found", run="tp_choir_found", done="tp_choir_seen")
    r.add("enemy", id="shade1", kind="pilgrim_shade", x=57, y=F - 3, face="left")
    r.add("sign", x=10, y=F, look="stone",
          text="바람의 능선.|건너편까지 다리가 끊겼다. 골짜기 아래에서 위로 바람이 분다.|— 날개가 있는 이라면 건널 수 있으리라.")
    r.add("trigger", id="glide", x=12, y=F - 9, w=2, h=6, run="tp_road3_glide")
    deco(r, [
        ("tp_pine", 3, F, dict(h=9)), ("tp_cairn", 8, F), ("tp_flags", 14, F - 13, dict(w=26, h=3)),
        ("tp_lantern", 18, F - 3), ("tp_lantern", 38, F), ("tp_shrine", 50, F), ("tp_candles", 44, F),
        ("tp_pine", 56, F - 3, dict(h=7)), ("tp_cairn", 68, F), ("tp_pine", 73, F, dict(h=10)),
        ("tp_flags", 62, F - 11, dict(w=14, h=2)),
    ])
    return r


@room
def tp_hut():
    """순례자 쉼터: 돌집 처마 아래 화로·기록 지점. 쉼터지기 수도사, 길을 멈춘 순례자들"""
    r = troom("tp_hut", "성산 · 순례자 쉼터", "holymount", "temple", (6, 7), (1, 1))
    F = 19
    r.ground(F)
    r.exit_left("west", F - 5, F - 1, "tp_road_3", "east")
    r.fill(8, 9, 32, 10)  # 처마 (돌 지붕)
    r.fill(7, 8, 33, 8)
    r.fill(8, 11, 8, 12)  # 처마 기둥 머리
    r.fill(32, 11, 32, 12)
    r.fill(r.w - 1, 0, r.w - 1, F - 1)
    r.exit_right("east", F - 5, F - 1, "tp_road_4", "west")
    r.add("save", id="hut", x=20, y=F, style="candle")
    r.add("npc", id="pilgrim_b", who="tp_pilgrim_b", x=13, y=F, face="right")
    r.add("npc", id="anselm", who="tp_anselm", x=27, y=F, face="left")
    r.add("trigger", id="hut", x=4, y=F - 6, w=2, h=6, run="tp_hut_scene")
    deco(r, [
        ("tp_brazier", 17, F), ("tp_pew", 22, F, dict(w=3)), ("tp_candles", 30, F), ("tp_banner", 12, 11, dict(h=4)),
        ("tp_banner", 28, 11, dict(h=4)), ("tp_lantern", 36, F), ("tp_pine", 2, F, dict(h=8)), ("tp_cairn", 37, F),
        ("tp_flags", 9, 12, dict(w=22, h=1)),
    ])
    r.add("light", x=17, y=F - 3, r=5, color="#ffb060")
    return r


@room
def tp_road_4():
    """대신전 오르막 (2×2): 아래 왼쪽에서 들어와 18칸 낭떠러지를 활공 → 오른쪽 바위 턱을 올라 가운데 단 → 왼쪽으로 꺾어
    꼭대기 바깥 회랑을 따라 정문으로. 골짜기의 긴 바람을 끝까지 타면 높은 바위의 수호의 깃털, 중간 턱엔 눈꽃 약초(tp_herbs).
    빛의 감시안 둘이 오르는 길을 쓸어 본다(첫 만남)."""
    r = troom("tp_road_4", "성산 · 대신전 오르막", "temple_out", "temple", (7, 6), (2, 2))
    F = r.h - 4  # 42
    r.fill(0, 0, 0, F - 6)
    r.exit_left("west", F - 5, F - 1, "tp_hut", "east")
    r.fill(0, F, 21, r.h - 1)
    spike_pit(r, 22, 39, F)
    r.fill(40, F, r.w - 1, r.h - 1)
    r.add("updraft", id="wind", x=28, y=10, w=3, h=34, style="wind", power=1.0)
    r.fill(22, 30, 26, 31)  # 약초 턱
    r.add("pickup", id="herb", kind="key", x=24, y=30, flag="tp_herb_found", name="눈꽃 약초",
          text="눈 속에서만 피는 하얀 약초. 버터워스 아주머니가 찾던 것이다.")
    r.add("event", id="herb_ev", flag="tp_herb_found", run="tp_herb_found", done="tp_herb_seen")
    r.fill(16, 12, 21, 13)  # 높은 바위 (깃털)
    r.add("pickup", id="feather_road4", kind="feather", x=18, y=12)
    # 오른쪽 바위 턱 → 가운데 단 → 왼쪽 턱 → 꼭대기 바깥 회랑
    r.fill(66, 38, 72, 39)
    r.fill(74, 34, 78, 35)
    r.fill(62, 30, 69, 31)
    r.fill(40, 27, 58, 28)  # 가운데 단
    r.fill(32, 23, 37, 24)
    r.fill(38, 19, r.w - 1, 20)  # 꼭대기 바깥 회랑
    r.fill(r.w - 1, 0, r.w - 1, r.h - 1)
    r.exit_right("east", 14, 18, "tp_gate", "west")
    r.add("enemy", id="eye1", kind="lumen_eye", x=52, y=22, face="left")
    r.add("enemy", id="eye2", kind="lumen_eye", x=66, y=11, face="left")
    r.add("enemy", id="shade1", kind="pilgrim_shade", x=56, y=F, face="left")
    r.add("trigger", id="eyes", x=44, y=F - 7, w=2, h=7, run="tp_road4_eyes")
    r.add("sign", x=8, y=F, look="stone",
          text="대신전 오르막.|순례자는 여기서 마지막 숨을 고른다.|— 바람 거센 날엔 골짜기 아래에서 위로 분다. 날개 있는 이는 그 바람을 타라.")
    deco(r, [
        ("tp_pine", 3, F, dict(h=9)), ("tp_cairn", 14, F), ("tp_lantern", 18, F),
        ("tp_flags", 4, F - 12, dict(w=16, h=2)), ("tp_pine", 46, F, dict(h=8)), ("tp_cairn", 62, F),
        ("tp_lantern", 70, 38), ("tp_broken_column", 44, 27, dict(h=4)), ("tp_statue", 52, 27, dict(h=6)),
        ("tp_column", 44, 19, dict(h=12)), ("tp_column", 56, 19, dict(h=12)), ("tp_column", 68, 19, dict(h=12)),
        ("tp_banner", 50, 8, dict(h=5)), ("tp_banner", 62, 8, dict(h=5)), ("tp_brazier", 74, 19),
        ("tp_wing_statue", 40, 19),
    ])
    return r


# ═══════════════════════════════════════════════════════════
# 정문·회랑 — 아우렐리아 첫 대면, 거점, 서브 퀘스트
# ═══════════════════════════════════════════════════════════

@room
def tp_gate():
    """대신전 정문: 넓은 앞뜰과 세 단 계단 위의 황금 정문. 아우렐리아가 막아서는 곳(tp_gate_scene).
    시련을 허락받으면 정문이 열리고(tp_gate_open), 순례길 입구로 내려가는 지름길 계단이 생긴다."""
    r = troom("tp_gate", "성산 대신전 · 황금 정문", "temple_out", "temple", (9, 6), (2, 1))
    F = 19
    r.ground(F)
    r.exit_left("west", F - 5, F - 1, "tp_road_4", "east")
    r.fill(r.w - 1, 0, r.w - 1, F - 1)
    r.fill(42, F - 1, 78, F - 1)
    r.fill(46, F - 2, 78, F - 2)
    r.fill(50, F - 3, 78, F - 3)
    r.add("prop", kind="tp_great_gate", x=64, y=F - 3, w=8, h=11, open_if="tp_gate_open")
    r.door("gate", 64, F - 3, "tp_cloister", "gate", style="grand", label="대신전", lock="tp_gate_open",
           lock_msg="황금 정문. 굳게 닫혀 있다. 문틈으로 낮은 성가가 새어 나온다.")
    r.door("short", 4, F, "tp_road", "short", style="stair_down", label="순례길 입구 (지름길)")
    r.ents[-1]["cond"] = "tp_gate_open"
    r.add("save", id="gate", x=11, y=F, style="lantern")
    r.add("spawn", id="scene", x=30, y=F, face="right")
    r.add("trigger", id="scene", x=28, y=F - 8, w=2, h=8, run="tp_gate_scene")
    r.ents[-1]["cond"] = "!tp_gate_scene"
    deco(r, [
        ("tp_font", 20, F), ("tp_lantern", 7, F), ("tp_pine", 2, F, dict(h=10)), ("tp_pine", 36, F, dict(h=8)),
        ("tp_wing_statue", 46, F - 2), ("tp_wing_statue", 76, F - 3), ("tp_brazier", 54, F - 3), ("tp_brazier", 74, F - 3),
        ("tp_column", 52, F - 3, dict(h=13)), ("tp_column", 57, F - 3, dict(h=13)), ("tp_column", 71, F - 3, dict(h=13)),
        ("tp_banner", 55, 2, dict(h=6)), ("tp_banner", 73, 2, dict(h=6)),
        ("tp_flags", 22, 4, dict(w=18, h=2)),
    ])
    return r


@room
def tp_cloister():
    """회랑 (거점): 정문·본당·기록실·거울 시련(왼쪽)·정원(오른쪽)이 모두 이어진다. 기록 지점, 전이진(학교로), 성수반(tp_pippa_water),
    시련의 석판(진행 상황). 시련 동안 레오니와 베네딕타가 여기서 기다린다."""
    r = troom("tp_cloister", "대신전 · 회랑", "temple", "temple", (9, 5), (2, 1))
    F = 19
    r.box(wall=1, floor=4, ceil=2)
    r.exit_left("west", F - 5, F - 1, "tp_mirror_1", "east")
    r.exit_right("east", F - 5, F - 1, "tp_garden", "west")
    r.door("mirror_back", 6, F, "tp_mirror_3", "back", style="wood", label="빛의 근원 (지름길)")
    r.ents[-1]["cond"] = "tp_trial_mirror"
    r.door("gate", 13, F, "tp_gate", "gate", style="grand", label="정문")
    r.add("warp", id="warp_circle", x=20, y=F, area="temple")
    r.add("save", id="cloister", x=30, y=F, style="candle")
    r.add("sign", x=34, y=F, look="stone", run="tp_trials_status", prompt="시련의 석판")
    r.door("nave", 40, F, "tp_nave", "down", style="stair_up", label="본당")
    r.add("prop", kind="tp_font", x=48, y=F)
    r.add("sign", x=48, y=F, look="none", run="tp_font", prompt="성수반")
    r.door("archive", 58, F, "tp_archive_1", "up", style="stair_down", label="기록실 (시련 ③)")
    r.add("npc", id="leonie", who="leonie", x=26, y=F, face="right", cond="tp_gate_scene,!tp_aurelia_talk")
    r.add("npc", id="bene", who="benedicta", x=44, y=F, face="left", cond="tp_gate_scene,!tp_aurelia_talk")
    r.add("npc", id="bene2", who="benedicta", x=44, y=F, face="left", cond="tp_aurelia_defeated")
    r.add("npc", id="priest", who="tp_priest", x=66, y=F, face="left")
    r.add("npc", id="monk", who="tp_monk", x=72, y=F, face="left", talk="npc_tp_monk_cloister")
    deco(r, [
        ("tp_column", 3, F, dict(h=15)), ("tp_column", 17, F, dict(h=15)), ("tp_column", 37, F, dict(h=15)),
        ("tp_column", 53, F, dict(h=15)), ("tp_column", 62, F, dict(h=15)), ("tp_column", 76, F, dict(h=15)),
        ("tp_glass", 8, 4, dict(w=4, h=6)), ("tp_glass", 26, 4, dict(w=4, h=6)), ("tp_glass", 44, 4, dict(w=4, h=6)),
        ("tp_glass", 67, 4, dict(w=4, h=6)), ("tp_banner", 22, 2, dict(h=6)), ("tp_banner", 56, 2, dict(h=6)),
        ("tp_candelabra", 24, F), ("tp_candelabra", 51, F), ("tp_pew", 68, F, dict(w=3)), ("tp_wing_statue", 10, F),
        ("tp_censer", 33, 2, dict(len=4)), ("tp_sun_relief", 38, 4, dict(w=4)),
    ])
    return r


@room
def tp_garden():
    """회랑 정원: 지붕 없는 안뜰. 견습 사제 루카(종 추 찾기), 기도 촛불 ①"""
    r = troom("tp_garden", "대신전 · 회랑 정원", "temple_out", "temple", (11, 5), (1, 1))
    F = 19
    r.ground(F)
    r.fill(0, 0, 0, F - 6)
    r.fill(r.w - 1, 0, r.w - 1, F - 6)
    r.exit_left("west", F - 5, F - 1, "tp_cloister", "east")
    r.exit_right("east", F - 5, F - 1, "tp_choir", "west")
    r.fill(14, F - 2, 26, F - 1)  # 화단 단
    r.add("npc", id="luca", who="luca", x=22, y=F - 2, face="left", cond="tp_gate_scene")
    candle(r, 1, 8, F)
    deco(r, [
        ("tp_font", 19, F - 2), ("tp_pine", 15, F - 2, dict(h=8)), ("tp_pine", 26, F - 2, dict(h=7)),
        ("tp_statue", 33, F, dict(h=7)), ("tp_column", 2, F, dict(h=13)), ("tp_column", 37, F, dict(h=13)),
        ("tp_bell_small", 30, 1, dict(len=3)), ("tp_flags", 4, 3, dict(w=32, h=2)), ("tp_lantern", 11, F),
    ])
    return r


@room
def tp_choir():
    """성가대석: 성가대 소녀 엘사(사라진 성가대원 — tp_choir_voice)와 성가대장. 오른쪽이 종탑(시련 ②)"""
    r = troom("tp_choir", "대신전 · 성가대석", "temple", "temple", (12, 5), (1, 1))
    F = 19
    r.box(wall=1, floor=4, ceil=2)
    r.exit_left("west", F - 5, F - 1, "tp_garden", "east")
    r.exit_right("east", F - 5, F - 1, "tp_bell_1", "west")
    r.fill(8, F - 1, 30, F - 1)  # 성가대 단
    r.add("npc", id="choir", who="tp_choir", x=14, y=F - 1, face="right")
    r.add("npc", id="choirmaster", who="tp_priest", x=24, y=F - 1, face="left", talk="npc_tp_choirmaster")
    r.add("sign", x=34, y=F, look="board", text="종탑 — 자격의 시련 ②|종은 아래에서 솟는 불로 울린다.|박자를 잃은 종지기의 혼이 아직 종을 친다. 진짜 종소리를 두려워하니 기억할 것.")
    deco(r, [
        ("tp_pew", 9, F - 1, dict(w=3)), ("tp_pew", 26, F - 1, dict(w=3)), ("tp_lectern", 19, F - 1),
        ("tp_candelabra", 6, F), ("tp_candelabra", 31, F), ("tp_glass", 10, 3, dict(w=3, h=7)),
        ("tp_glass", 26, 3, dict(w=3, h=7)), ("tp_glass", 18, 2, dict(w=4, h=8)), ("tp_banner", 3, 2, dict(h=6)),
        ("tp_column", 36, F, dict(h=15)),
    ])
    return r


@room
def tp_nave():
    """본당: 순례자를 받는 큰 예배당. 아우렐리아가 제단 앞에서 기도한다. 세 시련을 마치면 그녀와의 대화(tp_aurelia_talk),
    그 뒤 내전 계단이 열린다. 오른쪽은 수도사 숙소."""
    r = troom("tp_nave", "대신전 · 본당", "temple", "temple", (9, 4), (2, 1))
    F = 19
    r.box(wall=1, floor=4, ceil=2)
    r.exit_right("east", F - 5, F - 1, "tp_monk_cells", "west")
    r.door("down", 8, F, "tp_cloister", "nave", style="stair_down", label="회랑")
    r.fill(54, F - 1, 68, F - 1)  # 제단 단
    r.door("sanctum", 72, F, "tp_sanctum", "down", style="stair_up", label="내전", lock="tp_aurelia_talk",
           lock_msg="내전으로 오르는 계단. 금빛 결계가 막고 있다. 시련을 마친 이만 들 수 있다.")
    r.add("npc", id="aurelia", who="aurelia", x=61, y=F - 1, face="right", cond="tp_gate_scene,!tp_aurelia_talk")
    r.add("npc", id="aurelia2", who="aurelia", x=61, y=F - 1, face="left", cond="tp_aurelia_defeated")
    r.add("trigger", id="talk", x=44, y=F - 8, w=2, h=8, run="tp_aurelia_talk")
    r.ents[-1]["cond"] = "tp_trials_done,!tp_aurelia_talk"
    r.add("npc", id="pilgrim", who="tp_pilgrim_b", x=24, y=F, face="right", talk="npc_tp_pilgrim_nave")
    deco(r, [
        ("tp_column", 4, F, dict(h=15)), ("tp_column", 20, F, dict(h=15)), ("tp_column", 36, F, dict(h=15)),
        ("tp_column", 50, F, dict(h=15)), ("tp_column", 76, F, dict(h=15)),
        ("tp_pew", 12, F, dict(w=3)), ("tp_pew", 26, F, dict(w=3)), ("tp_pew", 31, F, dict(w=3)), ("tp_pew", 41, F, dict(w=3)),
        ("tp_altar", 61, F - 1), ("tp_sun_relief", 59, 4, dict(w=5)), ("tp_candelabra", 56, F - 1), ("tp_candelabra", 66, F - 1),
        ("tp_glass", 9, 3, dict(w=4, h=8)), ("tp_glass", 27, 3, dict(w=4, h=8)), ("tp_glass", 42, 3, dict(w=4, h=8)),
        ("tp_censer", 47, 2, dict(len=5)), ("tp_censer", 70, 2, dict(len=4)), ("tp_banner", 54, 2, dict(h=7)),
        ("tp_banner", 68, 2, dict(h=7)), ("tp_statue", 72, F, dict(h=9)),
    ])
    return r


@room
def tp_monk_cells():
    """수도사 숙소: 침상과 서가. 침묵 서원을 한 수도사, 기도 촛불 ⑤, 경전 조각. 오른쪽 끝 철창은 종 시련을 마치면 열린다(지름길)."""
    r = troom("tp_monk_cells", "대신전 · 수도사 숙소", "temple", "temple", (11, 4), (2, 1))
    F = 19
    r.box(wall=1, floor=4, ceil=2)
    r.exit_left("west", F - 5, F - 1, "tp_nave", "east")
    r.exit_right("east", F - 5, F - 1, "tp_bell_1", "cells")
    r.add("gate", id="shortcut", x=76, y=F - 6, w=1, h=6, open_if="tp_trial_bell", look="bars")
    for x in (24, 46):  # 방 사이 칸막이 (위가 뚫림)
        r.fill(x, 2, x, F - 6)
    r.plat(30, 35, F - 4)  # 위 침상
    r.plat(52, 57, F - 4)
    r.plat(64, 69, F - 8)  # 높은 선반 (마도석)
    r.add("npc", id="monk", who="tp_monk", x=16, y=F, face="right", talk="npc_tp_monk_cells")
    candle(r, 5, 58, F)
    r.add("pickup", id="scripture_1", kind="page", x=33, y=F - 4, name="루멘 경전 조각 (1/3)",
          text="「빛은 묻지 않는다. 그대가 무엇을 가졌는지, 무엇을 갖지 못했는지.」|「빛은 다만 비춘다. 어둠 속에서 서로를 찾을 수 있도록.」")
    r.add("pickup", id="stone_cells", kind="stone", x=66, y=F - 8)
    deco(r, [
        ("tp_pew", 8, F, dict(w=3)), ("tp_pew", 30, F, dict(w=3)), ("tp_pew", 52, F, dict(w=3)), ("tp_pew", 70, F, dict(w=3)),
        ("tp_books", 19, F), ("tp_candles", 40, F), ("tp_lectern", 38, F), ("tp_books", 62, F),
        ("tp_scrolls", 42, F, dict(w=2, h=4)), ("tp_glass", 12, 4, dict(w=3, h=5)), ("tp_glass", 34, 4, dict(w=3, h=5)),
        ("tp_glass", 58, 4, dict(w=3, h=5)), ("tp_banner", 70, 2, dict(h=5)),
    ])
    return r


# ═══════════════════════════════════════════════════════════
# 시련 ① 빛의 거울 — 빛줄기를 거울·수정·방벽으로
#   거울 중심 = 바닥 행 × 16 - 28px → 같은 바닥의 거울로 수평 빛을 보내려면 광원(빛의 감시안)을 바닥 행 - 1에 둔다.
#   '/'(45°): 오른쪽→위, 왼쪽→아래, 위→오른쪽, 아래→왼쪽 · '\'(135°): 오른쪽→아래, 왼쪽→위, 위→왼쪽, 아래→오른쪽
# ═══════════════════════════════════════════════════════════

@room
def tp_mirror_1():
    """거울 Ⅰ (입문): 광원 → 바닥 거울(돌려서 위로) → 높은 거울(돌려서 왼쪽) → 수정 → 결계 열림. 성갑 수도사 첫 만남."""
    r = troom("tp_mirror_1", "시련의 회랑 · 빛의 거울 Ⅰ", "temple", "temple", (7, 5), (2, 1))
    F = 19
    r.box(wall=1, floor=4, ceil=2)
    r.exit_right("east", F - 5, F - 1, "tp_cloister", "west")
    r.exit_left("west", F - 5, F - 1, "tp_mirror_2", "east")
    r.add("gate", id="seal", x=2, y=F - 6, w=1, h=6, open_if="tp_mir1", look="barrier")
    r.add("enemy", id="src", kind="lumen_eye", x=72, y=F - 1, source=True, beam_deg=180.0)
    r.add("light_mirror", id="m1", x=56, y=F, angle=45, angles=[45, 135])
    r.plat(44, 49, F - 4)
    r.plat(53, 59, 9)
    r.add("light_mirror", id="m2", x=56, y=9, angle=45, angles=[45, 135])
    r.fill(16, 9, 24, 10)
    r.add("light_crystal", id="c1", x=20, y=9, flag="tp_mir1")
    r.add("enemy", id="monk", kind="holy_monk", x=32, y=F, face="right")
    r.add("sign", x=66, y=F, look="stone",
          text="자격의 시련 ① — 빛의 거울.|빛을 수정에 이르게 하라.|거울은 손으로 돌리거나(↑), 불로 두드려 돌린다(불기둥).")
    deco(r, [
        ("tp_column", 4, F, dict(h=15)), ("tp_column", 40, F, dict(h=15)), ("tp_column", 76, F, dict(h=15)),
        ("tp_sun_relief", 70, 4, dict(w=4)), ("tp_glass", 28, 3, dict(w=4, h=6)), ("tp_banner", 12, 2, dict(h=5)),
        ("tp_candelabra", 62, F), ("tp_mirror", 9, F, dict(angle=135)), ("tp_wing_statue", 46, F),
    ])
    return r


@room
def tp_mirror_2():
    """거울 Ⅱ: 천장 광원(아래로) → A를 돌려 오른쪽 수정(작은 결계 열기) → A를 되돌려 왼쪽 → B(위로) → 높은 C(왼쪽) → 수정.
    날개 조각상 둘이 등을 돌릴 때마다 다가온다. 기도 촛불 ②, 왼쪽 위 구석에 마도석."""
    r = troom("tp_mirror_2", "시련의 회랑 · 빛의 거울 Ⅱ", "temple", "temple", (5, 5), (2, 1))
    F = 19
    r.box(wall=1, floor=4, ceil=2)
    r.exit_right("east", F - 5, F - 1, "tp_mirror_1", "west")
    r.exit_left("west", F - 5, F - 1, "tp_mirror_3", "east")
    r.add("gate", id="seal", x=2, y=F - 6, w=1, h=6, open_if="tp_mir2", look="barrier")
    r.add("enemy", id="src", kind="lumen_eye", x=70, y=3, source=True, beam_deg=90.0)
    r.add("light_mirror", id="a", x=70, y=F, angle=45, angles=[45, 135])
    r.add("light_crystal", id="cs", x=76, y=F, flag="tp_mir2a")
    r.add("gate", id="inner", x=60, y=F - 5, w=1, h=5, open_if="tp_mir2a", look="barrier")
    r.add("light_mirror", id="b", x=44, y=F, angle=45, angles=[45, 135])
    r.plat(33, 38, F - 4)
    r.plat(41, 47, 10)
    r.add("light_mirror", id="c", x=44, y=10, angle=45, angles=[45, 135])
    r.plat(21, 26, F - 4)
    r.fill(10, 10, 18, 11)
    r.add("light_crystal", id="c2", x=13, y=10, flag="tp_mir2")
    candle(r, 2, 17, 10)
    r.fill(2, 6, 6, 7)
    r.add("pickup", id="stone_mirror2", kind="stone", x=4, y=6)
    r.add("enemy", id="statue1", kind="seraph_statue", x=28, y=F, face="right")
    r.add("enemy", id="statue2", kind="seraph_statue", x=52, y=F, face="right")
    deco(r, [
        ("tp_column", 8, F, dict(h=15)), ("tp_column", 56, F, dict(h=15)), ("tp_column", 64, F, dict(h=15)),
        ("tp_glass", 30, 3, dict(w=4, h=5)), ("tp_banner", 50, 2, dict(h=5)), ("tp_banner", 22, 2, dict(h=5)),
        ("tp_candelabra", 74, F), ("tp_wing_statue", 38, F),
    ])
    return r


@room
def tp_mirror_3():
    """거울 Ⅲ (빛의 근원): 광원이 왼쪽으로 쏜다 — 빛 앞에 서서 불꽃 방벽을 펼치면 빛이 되돌아가(오른쪽) 광원을 지나
    M(위로) → 높은 N(오른쪽) → 수정. 시련을 마치면 회랑으로 가는 지름길 문."""
    r = troom("tp_mirror_3", "시련의 회랑 · 빛의 근원", "temple", "temple", (3, 5), (2, 1))
    F = 19
    r.box(wall=1, floor=4, ceil=2)
    r.exit_right("east", F - 5, F - 1, "tp_mirror_2", "west")
    r.door("back", 5, F, "tp_cloister", "mirror_back", style="wood", label="회랑 (지름길)")
    r.add("enemy", id="src", kind="lumen_eye", x=46, y=F - 1, source=True, beam_deg=180.0)
    r.add("light_mirror", id="m", x=58, y=F, angle=135, angles=[135, 45])
    r.plat(48, 52, F - 4)
    r.plat(55, 61, 10)
    r.add("light_mirror", id="n", x=58, y=10, angle=135, angles=[135, 45])
    r.fill(68, 10, 76, 11)
    r.add("light_crystal", id="c3", x=72, y=10, flag="tp_mir3", hold=0.25)
    r.add("event", id="done", flag="tp_mir3", run="tp_mirror_trial_done", done="tp_mir3_seen")
    r.add("enemy", id="monk", kind="holy_monk", x=66, y=F, face="left")
    r.add("enemy", id="eye", kind="lumen_eye", x=22, y=8, face="right")
    r.add("sign", x=12, y=F, look="stone",
          text="빛의 근원.|빛은 늘 등을 돌린 쪽으로만 흐른다.|— 빛을 마주 보고, 불의 원으로 되돌려 보내라.")
    deco(r, [
        ("tp_sun_relief", 44, 3, dict(w=5)), ("tp_column", 30, F, dict(h=15)), ("tp_column", 64, F, dict(h=15)),
        ("tp_column", 3, F, dict(h=15)), ("tp_glass", 16, 3, dict(w=4, h=6)), ("tp_banner", 52, 2, dict(h=5)),
        ("tp_candelabra", 40, F), ("tp_candelabra", 52, F), ("tp_mirror", 26, F, dict(angle=45)),
    ])
    return r


# ═══════════════════════════════════════════════════════════
# 시련 ② 종탑 — 진짜 종(불기둥으로 울림)·종지기 망령·박자 퍼즐
# ═══════════════════════════════════════════════════════════

@room
def tp_bell_1():
    """종탑 아래층 (세로 2칸): 바위 턱을 올라 꼭대기 오른쪽(박자의 방)으로. 종 둘(망령 멈추기 연습), 망령 둘.
    꼭대기 왼쪽은 수도사 숙소로 가는 지름길(숙소 쪽 철창은 시련을 마치면 열림). 루카의 종 추, 기도 촛불 ③."""
    r = troom("tp_bell_1", "종탑 · 아래층", "temple", "temple", (13, 4), (1, 2))
    F = r.h - 4  # 42
    r.box(wall=1, floor=4, ceil=1)
    r.exit_left("west", F - 5, F - 1, "tp_choir", "east")
    # 종탑 안의 나무 들보 (통과 발판)
    for x0, y, x1 in ((26, 38, 34), (14, 34, 22), (2, 30, 10), (14, 26, 32), (9, 22, 13), (26, 23, 29)):
        r.plat(x0, x1, y)
    r.fill(1, 19, 8, 20)
    r.fill(30, 19, 38, 20)
    r.exit_left("cells", 14, 18, "tp_monk_cells", "east")
    r.exit_right("east", 14, 18, "tp_bell_2", "west")
    r.add("temple_bell", id="b1", x=6, y=F, top=31, size="big", note=0)
    r.add("temple_bell", id="b2", x=20, y=26, top=6, size="small", note=4)
    r.add("enemy", id="wraith1", kind="bell_wraith", x=24, y=33, face="left")
    r.add("enemy", id="wraith2", kind="bell_wraith", x=18, y=20, face="right")
    r.add("pickup", id="clapper", kind="key", x=3, y=19, flag="tp_clapper_found", name="종 추",
          text="손바닥만 한 청동 종 추. 끈에 서툰 글씨로 '루카'라고 적힌 쪽지가 매여 있다.")
    r.add("event", id="clapper_ev", flag="tp_clapper_found", run="tp_clapper_found", done="tp_clapper_seen")
    candle(r, 3, 32, 38)
    r.add("trigger", id="intro", x=4, y=F - 6, w=2, h=6, run="tp_bell_intro")
    r.add("sign", x=36, y=F, look="stone",
          text="종탑.|진짜 종은 아래에서 솟는 큰 불(불기둥)로 울린다.|망령은 진짜 종소리를 두려워한다 — 종 곁에서 싸울 것.")
    deco(r, [
        ("tp_chain", 12, 1, dict(h=10)), ("tp_chain", 34, 1, dict(h=8)), ("tp_scaffold", 34, F, dict(w=4, h=6)),
        ("tp_bell_small", 26, 1, dict(len=5)), ("tp_bell_small", 4, 1, dict(len=7)), ("tp_glass", 17, 9, dict(w=3, h=6)),
        ("tp_banner", 30, 26, dict(h=4)), ("tp_candles", 18, 34), ("tp_rubble", 30, F, dict(w=2)),
    ])
    return r


@room
def tp_bell_2():
    """박자의 방 (세로 2칸): 받침 문양이 다른 종 넷. 벽화(여우창문으로만 보임)가 울릴 차례 — 달·불꽃·별·여우.
    순서와 박자(다음 종까지 5초)를 지키면 위층 계단의 결계가 걷힌다. 종을 치면 망령도 멈추지만 순서가 흐트러질 수 있다."""
    r = troom("tp_bell_2", "종탑 · 박자의 방", "temple", "temple", (14, 3), (1, 2))
    F = r.h - 4  # 42
    r.box(wall=1, floor=4, ceil=1)
    r.exit_left("west", F - 5, F - 1, "tp_bell_1", "east")
    r.fill(2, 36, 12, 37)  # 왼쪽 턱 (별 종)
    r.plat(17, 23, 38)  # 가운데 발판 (여우 종을 겨누는 자리)
    r.fill(26, 31, 37, 32)  # 오른쪽 턱 (여우 종)
    r.plat(14, 20, 27)
    r.fill(2, 23, 10, 24)
    r.fill(16, 19, 30, 20)  # 위층 계단 단
    r.door("up", 24, 19, "tp_bell_3", "down", style="stair_up", label="큰 종 다락", lock="tp_beat_done",
           lock_msg="계단을 금빛 빛살이 막고 있다. 아래의 종소리를 맞춰야 걷힐 것 같다.")
    bells = [("ba", 16, F, 28, "big", 1, "moon", 0), ("bb", 34, F, 33, "big", 2, "flame", 2),
             ("bc", 7, 36, 25, "small", 3, "star", 4), ("bd", 32, 31, 1, "small", 4, "fox", 6)]
    for bid, x, y, top, size, order, sym, note in bells:
        r.add("temple_bell", id=bid, x=x, y=y, top=top, size=size, group="tp_beat", order=order, symbol=sym, note=note)
    r.add("bell_puzzle", id="beat", group="tp_beat", beat=5.0, done_flag="tp_beat_done",
          hint="종소리가 어긋났다… 벽의 그림이 무언가를 말하는 것 같다. (여우창문)")
    r.add("event", id="beat_ev", flag="tp_beat_done", run="tp_beat_done", done="tp_beat_seen")
    r.add("hint_mural", id="score", x=24, y=F - 6, w=8, h=4, symbols=["moon", "flame", "star", "fox"], text="종을 울리는 차례")
    r.add("enemy", id="wraith1", kind="bell_wraith", x=24, y=27, face="left")
    r.add("pickup", id="stone_bell2", kind="stone", x=3, y=23)
    r.add("trigger", id="intro", x=4, y=F - 6, w=2, h=6, run="tp_beat_intro")
    deco(r, [
        ("tp_chain", 10, 1, dict(h=12)), ("tp_chain", 36, 1, dict(h=10)), ("tp_glass", 17, 6, dict(w=4, h=8)),
        ("tp_scaffold", 2, 23, dict(w=3, h=4)), ("tp_banner", 32, 6, dict(h=6)), ("tp_candles", 28, 19),
        ("tp_bell_small", 22, 1, dict(len=3)),
    ])
    return r


@room
def tp_bell_3():
    """큰 종 다락: 종탑 꼭대기. 가운데 큰 종을 울리면 시련 ② 끝(tp_trial_bell). 망령 둘이 마지막으로 지킨다.
    종지기 그레고르의 조율(tp_gregor_bells): 작은 종 셋(낮음·가운데·높음)을 그가 흥얼거린 차례로."""
    r = troom("tp_bell_3", "종탑 · 큰 종 다락", "temple_out", "temple", (13, 2), (2, 1))
    F = 19
    r.box(wall=1, floor=4, ceil=1)
    r.door("down", 6, F, "tp_bell_2", "up", style="stair_down", label="박자의 방")
    r.add("temple_bell", id="great", x=40, y=F, top=1, size="big", hang=4.5, group="tp_great", order=1, note=0)
    r.add("bell_puzzle", id="great_pz", group="tp_great", seq=[1], beat=9.0, done_flag="tp_great_rung")
    r.add("event", id="great_ev", flag="tp_great_rung", run="tp_bell_trial_done", done="tp_great_seen")
    for bid, x, order, note in (("t_low", 50, 1, 0), ("t_mid", 58, 2, 3), ("t_high", 74, 3, 6)):
        r.add("temple_bell", id=bid, x=x, y=F, top=1, size="small", group="tp_tune", order=order, note=note)
    r.add("bell_puzzle", id="tune_pz", group="tp_tune", seq=[3, 1, 2, 3], beat=6.0, done_flag="tp_tuned", need="q_tp_gregor_bells",
          hint="…그레고르 할아버지가 흥얼거린 차례가 아닌 것 같다.")
    r.add("event", id="tune_ev", flag="tp_tuned", run="tp_gregor_tuned", done="tp_tuned_seen")
    r.add("npc", id="gregor", who="gregor", x=66, y=F, face="left", cond="tp_gate_scene")
    r.add("enemy", id="wraith1", kind="bell_wraith", x=26, y=13, face="right")
    r.add("enemy", id="wraith2", kind="bell_wraith", x=54, y=13, face="left")
    r.plat(60, 64, 12)
    r.add("pickup", id="stone_bell3", kind="stone", x=62, y=12)
    r.plat(20, 26, F - 5)
    deco(r, [
        ("tp_column", 2, F, dict(h=17)), ("tp_column", 30, F, dict(h=17)), ("tp_column", 48, F, dict(h=17)),
        ("tp_column", 77, F, dict(h=17)), ("tp_scaffold", 12, F, dict(w=4, h=5)), ("tp_chain", 18, 1, dict(h=6)),
        ("tp_flags", 3, 3, dict(w=26, h=2)), ("tp_flags", 50, 3, dict(w=26, h=2)), ("tp_rubble", 70, F, dict(w=2)),
    ])
    return r


# ═══════════════════════════════════════════════════════════
# 시련 ③ 기록실 — 조각상·수도사, 백금 사도, 가장 오래된 기록 (tp_archive_read)
# ═══════════════════════════════════════════════════════════

@room
def tp_archive_1():
    """기록실 입구: 높은 서가 사이. 날개 조각상 둘(등을 돌리면 다가옴), 성갑 수도사. 오른쪽은 필사실, 깊은 서고로 내려가는 계단."""
    r = troom("tp_archive_1", "대신전 · 기록실", "temple_dark", "temple_dark", (11, 6), (2, 1), dark=0.15)
    F = 19
    r.box(wall=1, floor=4, ceil=2)
    r.door("up", 6, F, "tp_cloister", "archive", style="stair_up", label="회랑")
    r.door("down", 72, F, "tp_archive_2", "up", style="stair_down", label="깊은 서고")
    r.exit_right("east", F - 5, F - 1, "tp_scriptorium", "west")
    r.plat(14, 20, F - 4)
    r.plat(34, 44, F - 6)
    r.plat(56, 62, F - 4)
    r.add("enemy", id="statue1", kind="seraph_statue", x=30, y=F, face="left")
    r.add("enemy", id="statue2", kind="seraph_statue", x=50, y=F, face="left")
    r.add("enemy", id="monk", kind="holy_monk", x=64, y=F, face="left")
    r.add("sign", x=11, y=F, look="stone",
          text="기록실 — 자격의 시련 ③.|열람자는 침묵할 것. 조각상은 등 돌린 자를 꾸짖는다.|가장 깊은 서고에 가장 오래된 기록이 있다.")
    r.add("trigger", id="intro", x=9, y=F - 6, w=2, h=6, run="tp_archive_intro")
    deco(r, [
        ("tp_scrolls", 2, F, dict(w=3, h=7)), ("tp_scrolls", 22, F, dict(w=4, h=8)), ("tp_scrolls", 40, F, dict(w=3, h=6)),
        ("tp_scrolls", 66, F, dict(w=4, h=8)), ("tp_candles", 18, F), ("tp_candles", 46, F), ("tp_lectern", 36, F),
        ("tp_books", 54, F), ("tp_chain", 28, 2, dict(h=5)), ("tp_censer", 48, 2, dict(len=4)), ("tp_candelabra", 76, F),
    ])
    return r


@room
def tp_scriptorium():
    """필사실 (선택): 필사 수도사, 기도 촛불 ④, 경전 조각, 높은 서가 위 마도석"""
    r = troom("tp_scriptorium", "대신전 · 필사실", "temple_dark", "temple_dark", (13, 6), (1, 1), dark=0.1)
    F = 19
    r.box(wall=1, floor=4, ceil=2)
    r.exit_left("west", F - 5, F - 1, "tp_archive_1", "east")
    r.plat(18, 24, F - 5)
    r.plat(30, 35, F - 10)
    r.add("npc", id="scribe", who="tp_monk", x=12, y=F, face="right", talk="npc_tp_scribe")
    candle(r, 4, 30, F)
    r.add("pickup", id="scripture_2", kind="page", x=21, y=F - 5, name="루멘 경전 조각 (2/3)",
          text="「빛의 주재는 말하지 않는다. 다만 수호자에게 금빛을 맡기고, 짧은 계시로 길을 일러 줄 뿐.」|「계시가 끊기는 날이 오거든, 수호자여, 너의 창을 믿어라.」")
    r.add("pickup", id="stone_script", kind="stone", x=33, y=F - 10)
    deco(r, [
        ("tp_lectern", 8, F), ("tp_lectern", 16, F), ("tp_books", 24, F), ("tp_scrolls", 34, F, dict(w=4, h=8)),
        ("tp_candles", 5, F), ("tp_candelabra", 27, F), ("tp_glass", 12, 3, dict(w=3, h=5)), ("tp_censer", 22, 2, dict(len=3)),
    ])
    return r


@room
def tp_archive_2():
    """깊은 서고: 가장 오래된 기록을 흰빛이 감싸고 있다 — 백금 사도(미니보스). 쓰러뜨리면 기록을 읽을 수 있다(tp_archive_read).
    왼쪽은 지하 묘소(선택 구역)."""
    r = troom("tp_archive_2", "대신전 · 깊은 서고", "temple_dark", "temple_dark", (11, 7), (2, 1), dark=0.2)
    F = 19
    r.box(wall=1, floor=4, ceil=2)
    r.door("up", 74, F, "tp_archive_1", "down", style="stair_up", label="기록실")
    r.exit_left("west", F - 5, F - 1, "tp_crypt_1", "east")
    r.add("gate", id="arena_l", x=8, y=F - 6, w=1, h=6, open_if="!tp_herald_fight", look="bars")
    r.add("gate", id="arena_r", x=66, y=F - 6, w=1, h=6, open_if="!tp_herald_fight", look="bars")
    r.plat(14, 20, F - 4)
    r.plat(52, 58, F - 4)
    r.plat(30, 42, F - 8)
    r.add("enemy", id="herald", kind="gold_herald", x=36, y=F - 6, engaged=False)
    r.ents[-1]["cond"] = "!tp_herald_down"
    r.add("trigger", id="fight", x=60, y=F - 8, w=2, h=8, run="tp_herald_fight", once=False)
    r.ents[-1]["cond"] = "!tp_herald_down"
    r.add("sign", x=22, y=F, look="book", run="tp_archive_record", prompt="가장 오래된 기록")
    r.add("spawn", id="record", x=24, y=F, face="left")
    deco(r, [
        ("tp_scrolls", 2, F, dict(w=4, h=9)), ("tp_scrolls", 12, F, dict(w=3, h=7)), ("tp_scrolls", 46, F, dict(w=4, h=9)),
        ("tp_scrolls", 60, F, dict(w=3, h=7)), ("tp_lectern", 22, F), ("tp_candles", 26, F), ("tp_candles", 50, F),
        ("tp_chain", 20, 2, dict(h=7)), ("tp_chain", 54, 2, dict(h=6)), ("tp_censer", 36, 2, dict(len=3)),
        ("tp_candelabra", 70, F), ("tp_books", 30, F),
    ])
    r.add("light", x=22, y=F - 3, r=4, color="#fff0c0")
    return r


# ═══════════════════════════════════════════════════════════
# 지하 (선택) — 금빛 봉인석(유성 낙화로만): 마도석·깃털·경전 조각
# ═══════════════════════════════════════════════════════════

@room
def tp_crypt_1():
    """지하 묘소: 역대 수호자의 무덤. 길 잃은 그림자·조각상. 왼쪽 낮은 통로는 금빛 봉인석이 막고 있다(성유물실 — 유성 낙화)."""
    r = troom("tp_crypt_1", "대신전 · 지하 묘소", "temple_dark", "temple_dark", (9, 7), (2, 1), dark=0.3)
    F = 19
    r.box(wall=1, floor=4, ceil=2)
    r.exit_right("east", F - 5, F - 1, "tp_archive_2", "west")
    r.fill(1, 2, 13, F - 4)  # 낮은 통로 천장 (높이 3칸)
    r.door("down", 5, F, "tp_crypt_2", "up", style="stair_down", label="성유물실")
    r.add("seal_stone", id="seal1", x=11, y=F, h=3)
    r.fill(36, F - 2, 40, F - 1)  # 석관
    r.add("pickup", id="stone_crypt1", kind="stone", x=38, y=F - 2)
    r.add("enemy", id="shade1", kind="pilgrim_shade", x=28, y=F, face="right")
    r.add("enemy", id="shade2", kind="pilgrim_shade", x=58, y=F, face="left")
    r.add("enemy", id="statue1", kind="seraph_statue", x=46, y=F, face="right")
    r.add("sign", x=66, y=F, look="stone",
          text="역대 수호자들의 잠자리.|…맨 끝의 빈 감실에 이름이 미리 새겨져 있다. 「아우렐리아」.|날짜 자리는 비어 있다.")
    r.add("sign", x=18, y=F, look="stone", text="성유물실.|하늘의 불만이 이 봉인을 연다. — 초대 대사제")
    deco(r, [
        ("tp_statue", 24, F, dict(h=5, pose=1)), ("tp_statue", 52, F, dict(h=5, pose=2)), ("tp_statue", 70, F, dict(h=5, pose=1)),
        ("tp_candles", 34, F), ("tp_candles", 62, F), ("tp_rubble", 44, F, dict(w=2)), ("tp_chain", 30, 2, dict(h=4)),
        ("tp_chain", 56, 2, dict(h=5)), ("tp_censer", 40, 2, dict(len=3)),
    ])
    return r


@room
def tp_crypt_2():
    """성유물실 (유성 낙화로만): 초대 수호자의 유물. 안쪽 봉인석 너머 수호의 깃털, 경전 조각, 아우렐리아의 서원."""
    r = troom("tp_crypt_2", "대신전 · 성유물실", "temple_dark", "temple_dark", (9, 8), (2, 1), dark=0.25)
    F = 19
    r.box(wall=1, floor=4, ceil=2)
    r.door("up", 5, F, "tp_crypt_1", "down", style="stair_up", label="지하 묘소")
    r.fill(46, 2, 56, F - 4)
    r.add("seal_stone", id="seal2", x=52, y=F, h=3)
    r.plat(27, 33, F - 7)
    r.plat(18, 22, F - 3)
    r.add("pickup", id="stone_crypt2", kind="stone", x=30, y=F - 7)
    r.add("pickup", id="feather_crypt", kind="feather", x=68, y=F)
    r.add("pickup", id="scripture_3", kind="page", x=74, y=F, name="루멘 경전 조각 (3/3)",
          text="「하늘 바깥에는 굶주린 것들이 있다. 빛이 약한 세계를 먹는 것들.」|「그들이 문을 두드리거든, 빛의 자녀여, 그 문이 되지 말라.」")
    r.add("pickup", id="vow", kind="note", x=40, y=F, name="어린 수호자의 서원",
          text="「저는 웃지 않겠습니다. 울지도 않겠습니다. 빛이 흔들리지 않도록, 제가 흔들리지 않겠습니다.」|— 열 살의 아우렐리아. 서툰 글씨 위에 금박이 덧입혀져 있다.")
    r.add("enemy", id="monk", kind="holy_monk", x=40, y=F, face="left")
    r.add("enemy", id="statue1", kind="seraph_statue", x=22, y=F, face="right")
    deco(r, [
        ("tp_altar", 70, F), ("tp_sun_relief", 68, 4, dict(w=4)), ("tp_candelabra", 64, F), ("tp_candelabra", 76, F),
        ("tp_statue", 60, F, dict(h=8)), ("tp_candles", 12, F), ("tp_chain", 36, 2, dict(h=5)), ("tp_rubble", 26, F, dict(w=2)),
    ])
    return r


# ═══════════════════════════════════════════════════════════
# 내전 — 폭주
# ═══════════════════════════════════════════════════════════

@room
def tp_sanctum():
    """내전: 루멘의 제단. 아우렐리아가 연결을 되살리려 기도 → 바깥 신들이 대답 → 폭주(tp_sanctum_berserk).
    폭주 뒤엔 오른쪽 첨탑 문이 부서져 열리고, 본당으로 내려가는 계단은 무너진 결계가 막는다(추격이 끝날 때까지)."""
    r = troom("tp_sanctum", "대신전 · 내전", "temple", "temple", (9, 3), (2, 1))
    F = 19
    r.box(wall=1, floor=4, ceil=2)
    r.door("down", 6, F, "tp_nave", "sanctum", style="stair_down", label="본당")
    r.add("gate", id="lock", x=10, y=F - 6, w=1, h=6, open_if="tp_aurelia_defeated", look="seal")
    r.ents[-1]["cond"] = "tp_sanctum_berserk,!tp_aurelia_defeated"
    r.exit_right("east", F - 5, F - 1, "tp_spire_1", "down")
    r.add("gate", id="spire", x=77, y=F - 6, w=1, h=6, open_if="tp_sanctum_berserk", look="seal")
    r.fill(50, F - 2, 72, F - 1)  # 제단 단
    r.add("npc", id="bene", who="benedicta", x=54, y=F - 2, face="left", cond="tp_aurelia_talk,!tp_sanctum_berserk")
    r.add("npc", id="aurelia", who="aurelia", x=63, y=F - 2, face="right", cond="tp_aurelia_talk,!tp_sanctum_berserk")
    r.add("trigger", id="scene", x=34, y=F - 8, w=2, h=8, run="tp_sanctum_scene")
    r.ents[-1]["cond"] = "tp_aurelia_talk,!tp_sanctum_berserk"
    r.add("holy_chaser", id="chaser", start_flag="tp_never", stop_y=0, interval=0)
    r.ents[-1]["cond"] = "tp_aurelia_talk,!tp_sanctum_berserk"
    r.add("spawn", id="scene", x=36, y=F, face="right")
    deco(r, [
        ("tp_altar", 63, F - 2), ("tp_sun_relief", 60, 2, dict(w=6)), ("tp_candelabra", 52, F - 2), ("tp_candelabra", 71, F - 2),
        ("tp_column", 4, F, dict(h=15)), ("tp_column", 24, F, dict(h=15)), ("tp_column", 44, F, dict(h=15)), ("tp_column", 75, F, dict(h=15)),
        ("tp_glass", 14, 3, dict(w=4, h=8)), ("tp_glass", 32, 3, dict(w=4, h=8)), ("tp_censer", 56, 2, dict(len=5)),
        ("tp_censer", 69, 2, dict(len=4)), ("tp_banner", 48, 2, dict(h=7)), ("tp_wing_statue", 40, F),
    ])
    r.add("prop", kind="tp_rubble", x=30, y=F, w=3, cond="tp_sanctum_berserk")
    r.add("prop", kind="tp_broken_column", x=44, y=F, h=4, cond="tp_sanctum_berserk")
    r.add("prop", kind="tp_rubble", x=58, y=F - 2, w=2, cond="tp_sanctum_berserk")
    return r


# ═══════════════════════════════════════════════════════════
# 첨탑 추격 (tp_spire_1~5, 각 세로 3칸) — 폭주한 아우렐리아에게서 위로 도망 (docs/archive/sera/chapter4.md 7.6절)
#   아래에서 금빛이 차오르고(holy_chaser), 몇 초마다 신성 돌진이 세라가 선 높이를 가로지른다(비계 발판은 부서짐).
#   발판은 한 번 점프(4칸)로 오를 수 있게 3~4칸 간격. 쓰러지면 그 방 아래(start)에서 바로 다시.
#   칸이 지그재그로 이어진다: S1(x11) → S2(x12) → S3(x11) → S4(x12) → S5(x11) → 꼭대기(x12~13)
# ═══════════════════════════════════════════════════════════

def spire_room(rid, title, cell, enter, leave, nxt, nxt_id, prev, prev_id, steps, rests, planks, chaser):
    """enter/leave: "left"|"right" — 아래 입구 쪽, 위 출구 쪽. steps: 통과 발판 (x0, x1, y). rests: 돌 쉼터 (x0, x1, y) 두께 2"""
    r = troom(rid, title, "spire", "chase", cell, (1, 3))
    F = r.h - 4  # 65
    r.box(wall=1, floor=4, ceil=1)
    if enter == "left":
        r.exit_left("down", F - 5, F - 1, prev, prev_id)
        r.add("spawn", id="start", x=3, y=F, face="right")
    else:
        r.exit_right("down", F - 5, F - 1, prev, prev_id)
        r.add("spawn", id="start", x=36, y=F, face="left")
    if leave == "left":
        r.fill(1, 9, 9, 10)
        r.exit_left("up", 4, 8, nxt, nxt_id)
    else:
        r.fill(30, 9, 38, 10)
        r.exit_right("up", 4, 8, nxt, nxt_id)
    for x0, x1, y in steps:
        r.plat(x0, x1, y)
    for x0, x1, y in rests:
        r.fill(x0, y, x1, y + 1)
    for i, (x, y, w) in enumerate(planks):
        r.add("spire_plank", id="pk%d" % (i + 1), x=x, y=y, w=w)
    c = dict(start_y=F + 2, stop_y=10, delay=2.5, first=4.0)
    c.update(chaser)
    r.add("holy_chaser", id="chaser", **c)
    r.ents[-1]["cond"] = "!tp_aurelia_defeated"
    return r


def spire_deco(r, items):
    deco(r, items)
    for x, y in ((2, 3), (37, 3)):
        r.add("prop", kind="tp_chain", x=x, y=y, h=6)


@room
def tp_spire_1():
    r = spire_room("tp_spire_1", "첨탑 · 아래층", (11, 1), "left", "right", "tp_spire_2", "down", "tp_sanctum", "east",
                   steps=[(8, 14, 62), (17, 23, 59), (26, 32, 56), (17, 22, 53), (8, 13, 50), (9, 14, 44), (17, 22, 41),
                          (25, 31, 38), (24, 29, 32), (15, 20, 29), (6, 11, 26), (13, 18, 23), (21, 26, 20), (28, 33, 17),
                          (21, 26, 13)],
                   rests=[(1, 6, 47), (32, 38, 35)],
                   planks=[(30, 47, 6), (2, 35, 5), (31, 24, 5)],
                   chaser=dict(rise=1.0, interval=5.2, first=4.5))
    r.add("trigger", id="go", x=3, y=r.h - 10, w=3, h=6, run="tp_spire1_enter")
    spire_deco(r, [
        ("tp_scaffold", 33, 65, dict(w=5, h=8)), ("tp_bell", 20, 44, dict(len=3, size=0.8)), ("tp_glass", 16, 6, dict(w=3, h=7)),
        ("tp_banner", 6, 30, dict(h=5)), ("tp_stairs_broken", 28, 65, dict(w=4)), ("tp_rubble", 12, 65, dict(w=2)),
        ("tp_bell_small", 30, 12, dict(len=3)), ("tp_glass", 16, 50, dict(w=3, h=6)),
    ])
    return r


@room
def tp_spire_2():
    r = spire_room("tp_spire_2", "첨탑 · 종틀", (12, -1), "left", "left", "tp_spire_3", "down", "tp_spire_1", "up",
                   steps=[(7, 12, 62), (15, 20, 59), (23, 28, 56), (23, 28, 50), (14, 19, 47), (5, 10, 44), (9, 14, 38),
                          (17, 22, 35), (25, 30, 32), (24, 29, 26), (15, 20, 23), (6, 11, 20), (13, 18, 17), (12, 17, 13)],
                   rests=[(31, 38, 53), (1, 6, 41), (32, 38, 29)],
                   planks=[(31, 44, 5), (2, 30, 5), (24, 17, 5)],
                   chaser=dict(rise=1.1, interval=4.8))
    spire_deco(r, [
        ("tp_bell", 20, 26, dict(len=4, size=1.1)), ("tp_bell_small", 8, 30, dict(len=3)), ("tp_bell_small", 33, 40, dict(len=4)),
        ("tp_scaffold", 3, 65, dict(w=4, h=10)), ("tp_glass", 17, 6, dict(w=3, h=6)), ("tp_banner", 34, 16, dict(h=5)),
        ("tp_stairs_broken", 30, 65, dict(w=5)),
    ])
    return r


@room
def tp_spire_3():
    """가운데 넓은 돌 층계참에서 레오니가 신성 돌진을 정면으로 받아낸다(tp_spire3_leonie): "올라가라, 세라!" """
    r = spire_room("tp_spire_3", "첨탑 · 부서진 층계참", (11, -3), "right", "right", "tp_spire_4", "down", "tp_spire_2", "up",
                   steps=[(27, 32, 62), (18, 23, 59), (9, 14, 56), (10, 15, 50), (18, 23, 47), (26, 31, 44), (24, 29, 38),
                          (1, 5, 31), (8, 13, 28), (16, 21, 25), (24, 29, 22), (31, 36, 19), (23, 28, 16), (22, 27, 13)],
                   rests=[(1, 7, 53), (32, 38, 41), (6, 22, 35)],
                   planks=[(2, 44, 5), (32, 26, 6)],
                   chaser=dict(rise=1.15, interval=4.6))
    r.add("spawn", id="landing", x=12, y=35, face="right")
    r.add("trigger", id="leonie", x=6, y=29, w=17, h=6, run="tp_spire3_leonie")  # 층계참 전체 (위로 가는 길은 층계참 왼쪽 끝에서만 이어짐)
    r.ents[-1]["cond"] = "!tp_spire3_leonie"
    spire_deco(r, [
        ("tp_broken_column", 8, 35, dict(h=4)), ("tp_rubble", 16, 35, dict(w=3)), ("tp_glass", 16, 6, dict(w=3, h=7)),
        ("tp_bell", 30, 48, dict(len=3, size=0.9)), ("tp_scaffold", 2, 65, dict(w=4, h=9)), ("tp_banner", 4, 14, dict(h=5)),
        ("tp_stairs_broken", 20, 35, dict(w=3)),
    ])
    return r


@room
def tp_spire_4():
    """계단이 통째로 무너진 구간 — 교장의 목소리와 함께 별빛 발판이 놓인다(tp_spire4_astrid, 교장이 돕는 장면 4)."""
    r = spire_room("tp_spire_4", "첨탑 · 무너진 계단", (12, -5), "left", "left", "tp_spire_5", "down", "tp_spire_3", "up",
                   steps=[(7, 12, 62), (15, 20, 59), (23, 28, 56), (22, 27, 50), (13, 18, 47), (20, 25, 44), (12, 17, 13)],
                   rests=[(31, 38, 53), (4, 17, 41), (4, 14, 17)],
                   planks=[(30, 47, 6), (2, 53, 5)],
                   chaser=dict(rise=1.2, interval=4.4))
    r.add("star_steps", id="stars", flag="tp_star_steps",
          steps=[[19, 38, 4], [25, 35, 4], [31, 32, 4], [25, 29, 4], [19, 26, 4], [25, 23, 4], [18, 20, 4]])
    r.add("updraft", id="starwind", x=18, y=14, w=3, h=27, style="star", power=1.0, on_if="tp_star_steps")
    r.add("trigger", id="astrid", x=4, y=35, w=14, h=6, run="tp_spire4_astrid")  # 무너진 층계참 전체
    r.ents[-1]["cond"] = "!tp_star_steps"
    spire_deco(r, [
        ("tp_stairs_broken", 16, 41, dict(w=3)), ("tp_rubble", 8, 41, dict(w=3)), ("tp_broken_column", 12, 17, dict(h=3)),
        ("tp_glass", 28, 8, dict(w=3, h=7)), ("tp_scaffold", 33, 65, dict(w=4, h=8)), ("tp_bell_small", 6, 22, dict(len=3)),
        ("tp_chain", 24, 1, dict(h=10)),
    ])
    return r


@room
def tp_spire_5():
    r = spire_room("tp_spire_5", "첨탑 · 꼭대기 계단", (11, -7), "right", "right", "tp_spire_top", "west", "tp_spire_4", "up",
                   steps=[(27, 32, 62), (18, 23, 59), (9, 14, 56), (10, 15, 50), (18, 23, 47), (26, 31, 44), (17, 22, 41),
                          (8, 13, 38), (9, 14, 32), (17, 22, 29), (25, 30, 26), (24, 29, 20), (16, 21, 17), (23, 28, 13)],
                   rests=[(1, 7, 53), (1, 6, 35), (32, 38, 23)],
                   planks=[(30, 56, 6), (32, 50, 5), (28, 38, 6), (4, 26, 6)],
                   chaser=dict(rise=1.3, interval=3.9, first=3.5))
    spire_deco(r, [
        ("tp_bell", 22, 52, dict(len=3, size=1.0)), ("tp_bell_small", 6, 44, dict(len=3)), ("tp_scaffold", 2, 65, dict(w=4, h=8)),
        ("tp_glass", 16, 4, dict(w=3, h=6)), ("tp_banner", 34, 30, dict(h=5)), ("tp_stairs_broken", 22, 65, dict(w=4)),
    ])
    return r


@room
def tp_spire_top():
    """첨탑 꼭대기 (종루 위 열린 하늘): 아우렐리아 결전장. 가운데 양쪽 엄폐 기둥(심판의 창을 피하는 곳), 위쪽 발판 두 층.
    싸움이 시작되면 왼쪽 출구에 봉인이 내려온다. 끝나면 첨탑 끝(가운데 위)에 리라가 나타난다."""
    r = troom("tp_spire_top", "대신전 · 첨탑 꼭대기", "spire_top", "aurelia", (12, -7), (2, 1))
    F = 19
    r.box(wall=1, floor=4, ceil=1)
    r.clear(1, 0, r.w - 2, 4)
    r.exit_left("west", F - 5, F - 1, "tp_spire_5", "up")
    r.add("gate", id="arena", x=1, y=F - 6, w=1, h=6, open_if="!tp_boss_fight", look="seal")
    for x in (18, 60):
        r.fill(x, F - 4, x + 1, F - 1)
    r.plat(8, 14, F - 5)
    r.plat(65, 71, F - 5)
    r.plat(30, 36, F - 7)
    r.plat(44, 50, F - 7)
    r.add("spawn", id="start", x=5, y=F, face="right")
    r.add("spawn", id="center", x=40, y=F, face="right")
    r.add("enemy", id="aurelia", kind="aurelia_boss", x=56, y=F, face="left")
    r.ents[-1]["cond"] = "!tp_aurelia_defeated"
    r.add("trigger", id="boss", x=9, y=F - 8, w=2, h=8, run="tp_boss", once=False)
    r.ents[-1]["cond"] = "!tp_aurelia_defeated"
    deco(r, [
        ("tp_broken_column", 19, F - 4, dict(h=3)), ("tp_broken_column", 61, F - 4, dict(h=3)), ("tp_rubble", 24, F, dict(w=3)),
        ("tp_rubble", 54, F, dict(w=2)), ("tp_bell", 27, 1, dict(len=2, size=0.7)), ("tp_bell", 53, 1, dict(len=2, size=0.7)), ("tp_flags", 3, 6, dict(w=30, h=2)),
        ("tp_flags", 47, 6, dict(w=30, h=2)), ("tp_brazier", 4, F), ("tp_brazier", 75, F), ("tp_wing_statue", 77, F),
    ])
    return r


# ═══════════════════════════════════════════════════════════
# 학교 덧붙임 (지형은 그대로) — 4장 시작 장면은 대본이 인물을 세운다
# ═══════════════════════════════════════════════════════════

# (없음: 피피는 연금술실, 버터워스는 식당에 이미 있다 — 퀘스트 대화 걸이로 이어짐)


# ═══════════════════════════════════════════════════════════
# 개발용 시험 방 (지도에 나오지 않음)
# ═══════════════════════════════════════════════════════════

@room
def dev_tp_temple():
    r = Room("dev_tp_temple", "시험장 · 대신전", "dev", "temple", "temple", (0, 0), (4, 1))
    F = 19
    r.box(wall=1, floor=r.h - F, ceil=2)
    r.add("spawn", id="start", x=4, y=F, face="right")
    # 1) 소품 진열 (0~38)
    r.add("spawn", id="props", x=20, y=F, face="right")
    # 2) 수도사 구역 (40~70)
    r.add("spawn", id="monk", x=44, y=F, face="right")
    r.plat(52, 58, F - 4)
    # 3) 감시안·거울 구역 (72~100)
    r.add("spawn", id="eye", x=76, y=F, face="right")
    r.plat(84, 90, F - 4)
    # 4) 조각상·종 구역 (100~158)
    r.add("spawn", id="statue", x=104, y=F, face="right")
    r.add("spawn", id="bell", x=132, y=F, face="right")
    r.fill(118, F - 3, 120, F - 1)  # 낮은 턱
    r.add("temple_bell", id="bell1", x=140, y=F, top=2, size="big", note=0)
    r.add("temple_bell", id="bell2", x=150, y=F, top=2, size="small", note=2)
    # 빛 퍼즐 시험: (74,18) 광원 감시안(시나리오가 둠) → 거울(84) → 위의 수정(84, 6)
    r.add("light_mirror", id="mir1", x=84, y=F, angle=135, angles=[135, 45])
    r.add("light_crystal", id="cry1", x=84, y=6, hang=True, flag="dev_crystal")
    r.add("gate", id="cgate", x=96, y=F - 6, w=1, h=6, open_if="dev_crystal", look="barrier")
    r.add("seal_stone", id="seal1", x=70, y=F, h=2)
    # 소품
    props = [
        ("tp_column", 3, dict(h=15)), ("tp_brazier", 7, {}), ("tp_statue", 11, dict(h=9)),
        ("tp_candles", 15, {}), ("tp_pew", 18, dict(w=3)), ("tp_lectern", 22, {}),
        ("tp_font", 25, {}), ("tp_scrolls", 29, dict(w=3, h=5)), ("tp_candelabra", 33, {}),
        ("tp_column", 37, dict(h=15)),
    ]
    for kind, x, kw in props:
        r.add("prop", kind=kind, x=x, y=F, **kw)
    r.add("prop", kind="tp_glass", x=20, y=F - 6, w=4, h=7)
    r.add("prop", kind="tp_banner", x=9, y=2, h=7)
    r.add("prop", kind="tp_banner", x=31, y=2, h=7)
    r.add("prop", kind="tp_censer", x=14, y=2, len=4)
    r.add("prop", kind="tp_censer", x=26, y=2, len=3)
    r.add("prop", kind="tp_bell_small", x=46, y=2, len=3)
    r.add("prop", kind="tp_sun_relief", x=62, y=F - 9, w=4)
    r.add("prop", kind="tp_seal", x=92, y=F)
    r.add("prop", kind="tp_wing_statue", x=112, y=F)
    r.add("prop", kind="tp_books", x=66, y=F)
    r.add("prop", kind="tp_altar", x=62, y=F)
    r.add("prop", kind="tp_chain", x=124, y=2, h=5)
    r.add("prop", kind="tp_rubble", x=128, y=F, w=3)
    for x in (40, 72, 100):
        r.add("prop", kind="tp_column", x=x, y=F, h=15)
    return r


@room
def dev_tp_dark():
    r = Room("dev_tp_dark", "시험장 · 기록실", "dev", "temple_dark", "temple_dark", (0, 1), (2, 1), dark=0.1)
    F = 19
    r.box(wall=1, floor=r.h - F, ceil=2)
    r.add("spawn", id="start", x=4, y=F, face="right")
    r.add("spawn", id="mid", x=40, y=F, face="right")
    r.add("spawn", id="herald", x=56, y=F - 5)
    r.plat(14, 20, F - 4)
    r.plat(60, 66, F - 4)
    r.plat(36, 44, F - 8)
    for x in (8, 24, 52, 70):
        r.add("prop", kind="tp_scrolls", x=x, y=F, w=4, h=7)
    for x in (12, 30, 48, 66):
        r.add("prop", kind="tp_candles", x=x, y=F)
    r.add("prop", kind="tp_lectern", x=40, y=F)
    r.add("prop", kind="tp_books", x=44, y=F)
    r.add("prop", kind="tp_candelabra", x=34, y=F)
    r.add("prop", kind="tp_chain", x=20, y=2, h=6)
    r.add("prop", kind="tp_censer", x=58, y=2, len=5)
    return r


@room
def dev_tp_spire():
    """첨탑 추격 시험: 세로 4칸. 아래 바닥에서 출발해 비계·종틀·부서지는 발판을 밟고 꼭대기 출구까지.
    발판 간격은 한 번 점프(3칸)로 오를 수 있게, 갈림길(왼쪽 빠른 길은 부서지는 비계)을 하나 둔다."""
    r = Room("dev_tp_spire", "시험장 · 첨탑 추격", "dev", "spire", "chase", (0, 2), (1, 4))
    H = r.h  # 92
    F = H - 4  # 88: 바닥
    r.box(wall=1, floor=4, ceil=1)
    # 꼭대기 출구 (오른쪽 위)
    r.clear(39, 4, 39, 8)
    r.ents.append(dict(t="exit", id="top", x=39, y=4, w=1, h=5, to="dev_tp_arena", to_id="west"))
    r.fill(30, 9, 38, 10)  # 꼭대기 층
    r.add("spawn", id="start", x=6, y=F, face="right")
    # 오르는 길 (y는 발판 행). 3칸씩 오른다. 좌우로 지그재그
    steps = [
        (10, 16, 85), (20, 26, 82), (12, 18, 79), (24, 30, 76), (31, 37, 73),
        (22, 27, 70), (12, 18, 67), (4, 10, 64), (12, 17, 61), (20, 26, 58),
        (28, 34, 55), (20, 25, 52), (10, 16, 49), (3, 8, 46), (11, 16, 43),
        (19, 24, 40), (27, 33, 37), (19, 25, 34), (10, 16, 31), (18, 23, 28),
        (26, 31, 25), (32, 37, 22), (24, 29, 19), (16, 21, 16), (24, 29, 13),
    ]
    for x0, x1, y in steps:
        r.plat(x0, x1, y)
    # 단단한 층 (돌 바닥 — 쉬어 갈 자리)
    r.fill(1, 64, 10, 65)
    r.fill(28, 37, 38, 38)
    # 부서지는 비계 (신성 돌진에 무너짐): 개체
    r.add("spire_plank", id="pk1", x=30, y=67, w=6)
    r.add("spire_plank", id="pk2", x=3, y=55, w=6)
    r.add("spire_plank", id="pk3", x=4, y=25, w=5)
    # 종 (매달림)
    r.add("prop", kind="tp_bell", x=20, y=60 - 14, len=3, size=1.0)
    r.add("prop", kind="tp_scaffold", x=33, y=F, w=6, h=14)
    r.add("prop", kind="tp_scaffold", x=6, y=46, w=5, h=10)
    r.add("prop", kind="tp_chain", x=26, y=1, h=8)
    # 추격 장치
    r.add("holy_chaser", id="chaser", start_y=F + 2, stop_y=10, rise=1.3, delay=2.0, interval=4.2,
          first=3.5, start_flag="")
    return r


@room
def dev_tp_mount():
    r = Room("dev_tp_mount", "시험장 · 순례길", "dev", "holymount", "temple", (0, 6), (3, 1))
    F = 19
    r.ground(F)
    r.fill(0, 0, 0, F)
    r.fill(r.w - 1, 0, r.w - 1, F)
    # 오르막 산길
    r.fill(30, F - 2, 44, F - 1)
    r.fill(38, F - 4, 44, F - 3)
    r.fill(60, F - 3, 119, F - 1)
    r.plat(48, 54, F - 6)
    r.add("spawn", id="start", x=4, y=F, face="right")
    r.add("spawn", id="mid", x=24, y=F, face="right")
    r.add("spawn", id="far", x=70, y=F - 3, face="right")
    r.add("prop", kind="tp_cairn", x=12, y=F)
    r.add("prop", kind="tp_cairn", x=66, y=F - 3)
    r.add("prop", kind="tp_flags", x=6, y=F - 9, w=14, h=2)
    r.add("prop", kind="tp_flags", x=70, y=F - 12, w=16, h=3)
    r.add("prop", kind="tp_lantern", x=20, y=F)
    r.add("prop", kind="tp_lantern", x=80, y=F - 3)
    r.add("prop", kind="tp_pine", x=26, y=F, h=8)
    r.add("prop", kind="tp_pine", x=90, y=F - 3, h=10)
    r.add("prop", kind="tp_shrine", x=100, y=F - 3)
    return r


@room
def dev_tp_court():
    """대신전 바깥(정문 앞 정원) 배경 시험"""
    r = Room("dev_tp_court", "시험장 · 대신전 정문", "dev", "temple_out", "temple", (0, 8), (2, 1))
    F = 19
    r.ground(F)
    r.fill(0, 0, 0, F)
    r.fill(r.w - 1, 0, r.w - 1, F)
    r.fill(50, F - 2, 79, F - 1)
    r.add("spawn", id="start", x=4, y=F, face="right")
    r.add("prop", kind="tp_column", x=46, y=F, h=12)
    r.add("prop", kind="tp_statue", x=62, y=F - 2, h=10)
    r.add("prop", kind="tp_brazier", x=54, y=F - 2)
    r.add("prop", kind="tp_brazier", x=70, y=F - 2)
    r.add("prop", kind="tp_font", x=24, y=F)
    r.add("prop", kind="tp_banner", x=50, y=6, h=6)
    return r


@room
def dev_tp_arena():
    """첨탑 꼭대기 결전장 시험: 2칸 너비. 가운데 양쪽에 엄폐 기둥(심판의 창을 피하는 곳), 위쪽 발판 두 층."""
    r = Room("dev_tp_arena", "시험장 · 첨탑 꼭대기", "dev", "spire_top", "aurelia", (0, 7), (2, 1))
    F = 19
    r.box(wall=1, floor=r.h - F, ceil=1)
    r.clear(1, 1, r.w - 2, 4)  # 열린 하늘 (천장 없음 느낌: 위쪽 벽을 비움)
    r.clear(0, F - 5, 0, F - 1)
    r.ents.append(dict(t="exit", id="west", x=0, y=F - 5, w=1, h=5, to="dev_tp_spire", to_id="top"))
    # 엄폐 기둥 (부서진 대리석 기둥: 높이 4)
    for x in (18, 60):
        r.fill(x, F - 4, x + 1, F - 1)
    # 위쪽 발판
    r.plat(8, 14, F - 5)
    r.plat(65, 71, F - 5)
    r.plat(30, 36, F - 7)
    r.plat(44, 50, F - 7)
    r.add("spawn", id="start", x=6, y=F, face="right")
    r.add("spawn", id="boss", x=56, y=F, face="left")
    r.add("prop", kind="tp_rubble", x=24, y=F, w=3)
    r.add("prop", kind="tp_rubble", x=54, y=F, w=2)
    r.add("prop", kind="tp_broken_column", x=19, y=F - 4)
    r.add("prop", kind="tp_broken_column", x=61, y=F - 4)
    return r
