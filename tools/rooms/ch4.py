"""4장 방 (docs/chapter4.md). roomgen.py가 불러온다.
from roomgen import Room, room, overlay — 1장 roomgen.py와 같은 문법.

지금(1단계)은 개발용 시험 방만 있다 (지도·ROOMS에 넣지 않음):
    dev_tp_temple  대신전 안 — 소품 진열, 성갑 수도사·빛의 감시안·날개 조각상·종지기 망령·진짜 종·거울
    dev_tp_dark    기록실(어두운 신전) — 백금 사도 시험장
    dev_tp_spire   첨탑 추격 시험 (세로 4칸) — 신성 돌진·차오르는 금빛·부서지는 비계
    dev_tp_mount   성산 순례길 — 순례자의 그림자
    dev_tp_arena   첨탑 꼭대기 — 아우렐리아 보스 시험장 (엄폐 기둥)
"""
from roomgen import Room, room, overlay  # noqa: F401


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
    r.add("prop", kind="tp_mirror", x=80, y=F, angle=45)
    r.add("prop", kind="tp_seal", x=95, y=F)
    r.add("prop", kind="tp_wing_statue", x=112, y=F)
    r.add("prop", kind="tp_books", x=70, y=F)
    r.add("prop", kind="tp_altar", x=66, y=F)
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
