#!/usr/bin/env python3
"""방 데이터 생성기 (docs/archive/sera/chapter1.md 5절).

방 지형을 사각형 명령으로 그려 ASCII 지도를 만들고, 개체 목록과 함께
game/world/rooms/<id>.gd (RoomData 상속) 파일로 써 낸다. 방 메타 색인 game/world/rooms/_index.gd(RoomIndex가 읽음)도 함께.
    python3 tools/roomgen.py              # 모든 방 다시 만들기 (+ 색인)
    python3 tools/roomgen.py s_hall       # 한 방만 (색인은 언제나 전부로)
    python3 tools/roomgen.py check all k_ # 도달 검사 (아래 check 참고)
    python3 tools/roomgen.py validate     # 개체 종류·소품 kind·인물·출구/문 연결·좌표 검사 (ERR가 있으면 종료 코드 1)
방 정의는 1장이 이 파일, 2장부터는 tools/rooms/<장>.py (docs/dev/world.md).

좌표: x는 왼쪽→오른쪽, y는 위→아래 (타일). 화면 1칸 = 40×23타일.
지형 문자: # 벽  = 통과 발판  ^ 가시  I 환영 벽  H 숨은 발판  W 부서지는 벽  . 빈칸
개체의 y는 '발이 닿는 바닥 타일의 행'(바닥 윗면).
"""
import glob
import importlib
import os
import re
import sys

# 장별 모듈(tools/rooms/*.py)이 `from roomgen import Room, room, overlay` 로 같은 모듈을 쓰게
sys.modules.setdefault("roomgen", sys.modules[__name__])

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "game", "world", "rooms")
SW, SH = 40, 23  # 화면 1칸 (타일)


class Room:
    def __init__(self, rid, title, area, theme, music, cell, cells, dark=0.0):
        self.id = rid
        self.title = title
        self.area = area
        self.theme = theme
        self.music = music
        self.cell = cell
        self.cells = cells
        self.dark = dark
        self.w = SW * cells[0]
        self.h = SH * cells[1]
        self.g = [["." for _ in range(self.w)] for _ in range(self.h)]
        self.ents = []
        self.src = ""  # 정의한 곳 "tools/rooms/ch2.py k_market()" (build가 채움)
        self.ent_src = {}  # id(개체) → 덧붙인 파일 (overlay)

    # ─── 지형 ───
    def fill(self, x0, y0, x1, y1, ch="#"):
        """[x0, x1] × [y0, y1] (양끝 포함) 칠하기. 범위 밖은 잘라냄"""
        for y in range(max(0, y0), min(self.h - 1, y1) + 1):
            for x in range(max(0, x0), min(self.w - 1, x1) + 1):
                self.g[y][x] = ch

    def clear(self, x0, y0, x1, y1):
        self.fill(x0, y0, x1, y1, ".")

    def box(self, wall=1, floor=3, ceil=1):
        """사방을 막은 방 (나중에 출구를 뚫음)"""
        self.fill(0, 0, self.w - 1, ceil - 1)
        self.fill(0, self.h - floor, self.w - 1, self.h - 1)
        self.fill(0, 0, wall - 1, self.h - 1)
        self.fill(self.w - wall, 0, self.w - 1, self.h - 1)

    def ground(self, top):
        """top 행부터 아래를 모두 땅으로"""
        self.fill(0, top, self.w - 1, self.h - 1)

    def plat(self, x0, x1, y):
        self.fill(x0, y, x1, y, "=")

    def floor_y(self):
        return self.h - 3

    # ─── 출구 ───
    def exit_left(self, eid, y_top, y_bot, to, to_id):
        self.clear(0, y_top, 0, y_bot)
        self.ents.append(dict(t="exit", id=eid, x=0, y=y_top, w=1, h=y_bot - y_top + 1, to=to, to_id=to_id))

    def exit_right(self, eid, y_top, y_bot, to, to_id):
        self.clear(self.w - 1, y_top, self.w - 1, y_bot)
        self.ents.append(dict(t="exit", id=eid, x=self.w - 1, y=y_top, w=1, h=y_bot - y_top + 1, to=to, to_id=to_id))

    def door(self, eid, x, y, to, to_id, style="wood", label="", lock="", lock_msg=""):
        e = dict(t="door", id=eid, x=x, y=y, to=to, to_id=to_id, style=style)
        if label:
            e["label"] = label
        if lock:
            e["lock"] = lock
        if lock_msg:
            e["lock_msg"] = lock_msg
        self.ents.append(e)

    def add(self, t, **kw):
        e = dict(t=t)
        e.update(kw)
        self.ents.append(e)
        return e

    # ─── 출력 ───
    def to_gd(self):
        rows = ["".join(r) for r in self.g]
        lines = []
        lines.append("extends RoomData")
        lines.append("## 자동 생성: tools/roomgen.py — 직접 고치지 말고 생성기를 고친 뒤 다시 만들 것")
        if self.src:
            lines.append("## 정의: " + self.src)
        lines.append("")
        lines.append("")
        lines.append("func _init() -> void:")
        lines.append(f'\tid = "{self.id}"')
        lines.append(f'\ttitle = "{self.title}"')
        lines.append(f'\tarea = "{self.area}"')
        lines.append(f'\ttheme = "{self.theme}"')
        lines.append(f'\tmusic = "{self.music}"')
        lines.append(f"\tcell = Vector2i({self.cell[0]}, {self.cell[1]})")
        lines.append(f"\tcells = Vector2i({self.cells[0]}, {self.cells[1]})")
        if self.dark:
            lines.append(f"\tdark = {self.dark}")
        lines.append('\tmap = """')
        lines.extend(rows)
        lines.append('"""')
        lines.append("\tentities = [")
        last_src = ""
        for e in self.ents:
            src = self.ent_src.get(id(e), "")
            if src and src != last_src:
                lines.append("\t\t# 덧붙임(overlay): " + src)
            last_src = src
            lines.append("\t\t" + gd_dict(e) + ",")
        lines.append("\t]")
        return "\n".join(lines) + "\n"


def gd_val(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(v)
    if isinstance(v, str):
        if v.startswith("#") and len(v) in (7, 9) and all(c in "0123456789abcdefABCDEF" for c in v[1:]):
            return f'Color("{v}")'
        return '"' + v.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'
    if isinstance(v, (list, tuple)):
        return "[" + ", ".join(gd_val(x) for x in v) + "]"
    if isinstance(v, dict):
        return gd_dict(v)
    raise TypeError(v)


def gd_dict(d):
    return "{" + ", ".join(f"{k} = {gd_val(v)}" for k, v in d.items()) + "}"


ROOMS = {}
OVERLAYS = {}  # 방 ID → 덧붙일 개체 목록 (다른 장 모듈이 학교 방 등에 NPC·문·장치를 더할 때)
_OVERLAY_SRC = {}  # id(개체 사전) → 덧붙인 파일 (생성물에 출처 주석을 달려고)


def _rel(path):
    """절대 경로 → 저장소 기준 경로 (tools/rooms/ch2.py)"""
    return os.path.relpath(os.path.abspath(path), ROOT).replace(os.sep, "/")


def room(fn):
    ROOMS[fn.__name__] = fn
    return fn


def overlay(room_id, t, **kw):
    """이미 있는 방(1장 학교 방 등)에 개체를 덧붙인다. 지형은 못 바꾼다(문·NPC·트리거·장치만).
    보통 cond="플래그"(그 장에만 보이게)를 함께 준다."""
    e = dict(t=t)
    e.update(kw)
    OVERLAYS.setdefault(room_id, []).append(e)
    _OVERLAY_SRC[id(e)] = _rel(sys._getframe(1).f_code.co_filename)
    return e


def build(name):
    fn = ROOMS[name]
    r = fn()
    r.src = "%s %s()" % (_rel(fn.__code__.co_filename), fn.__name__)
    for e in OVERLAYS.get(r.id, []):
        r.ents.append(e)
        r.ent_src[id(e)] = _OVERLAY_SRC.get(id(e), "")
    return r


# ─── 장마다 쓰는 방·개체 도우미 (tools/rooms/*.py가 불러 씀) ───

def boxed_room(rid, title, area, theme, music, cell, cells, dark=0.0, ceil=2, floor=4, wall=1):
    """사방이 막힌 방 (바닥 윗면 = h - floor, 출구는 나중에 뚫음). 장별 상자 헬퍼는 기본값만 바꿔 이것을 부른다"""
    r = Room(rid, title, area, theme, music, cell, cells, dark)
    r.box(wall=wall, floor=floor, ceil=ceil)
    return r


def stone(r, sid, x, y, text=None):
    """마도석 줍기 (text가 없으면 습득 창 기본 문구)"""
    e = r.add("pickup", id=sid, kind="stone", x=x, y=y, name="마도석")
    if text is not None:
        e["text"] = text
    return e


def note(r, nid, x, y, name, text):
    """읽을 수 있는 쪽지 줍기"""
    return r.add("pickup", id=nid, kind="note", x=x, y=y, name=name, text=text)


def hanging_row(r, kind, xs, y, ln, cycle):
    """천장에 매단 소품 줄: i번째 줄 길이 = ln + i % cycle (길이가 들쭉날쭉하게)"""
    for i, x in enumerate(xs):
        r.add("prop", kind=kind, x=x, y=y, len=ln + (i % cycle))


def load_modules():
    """tools/rooms/*.py (2장부터의 방 모듈)를 불러온다. 파일 이름 순서 = 장 순서"""
    here = os.path.dirname(os.path.abspath(__file__))
    if here not in sys.path:
        sys.path.insert(0, here)
    for path in sorted(glob.glob(os.path.join(here, "rooms", "*.py"))):
        name = os.path.splitext(os.path.basename(path))[0]
        if name.startswith("_"):
            continue
        importlib.import_module("rooms." + name)


# ═══════════════════════════════════════════════════════════
# 신계 (프롤로그)
# ═══════════════════════════════════════════════════════════

@room
def t_pass():
    r = Room("t_pass", "신계 · 여우고개", "shingye", "shingye", "shingye", (0, 1), (2, 1))
    F = 19  # 바닥 윗면 행
    r.ground(F)
    r.fill(0, 0, 0, F)  # 왼쪽 벽
    # 1) 낮은 턱 (점프 안내)
    r.fill(14, F - 2, 19, F - 1)
    # 2) 가시 구덩이 (6칸)
    r.clear(24, F, 29, r.h - 1)
    r.fill(24, F + 2, 29, r.h - 1)
    r.fill(24, F + 1, 29, F + 1, "^")
    # 3) 높은 턱 4칸 (길게 눌러 높이)
    r.fill(34, F - 4, 40, F - 1)
    r.fill(41, F - 2, 43, F - 1)
    # 4) 넓은 구덩이 9칸 (대시 안내)
    r.clear(48, F, 56, r.h - 1)
    r.fill(48, F + 2, 56, r.h - 1)
    r.fill(48, F + 1, 56, F + 1, "^")
    # 5) 홍살문 너머 신계 숲으로
    r.exit_right("east", F - 5, F - 1, "t_forest", "west")
    r.add("spawn", id="start", x=4, y=F, face="right")
    # 안내 (멈춤)
    r.add("trigger", id="tj", x=10, y=F - 6, w=2, h=6, run="teach_jump")
    r.add("trigger", id="th", x=30, y=F - 8, w=2, h=8, run="teach_high_jump")
    r.add("trigger", id="td", x=44, y=F - 8, w=2, h=8, run="teach_dash")
    r.add("trigger", id="tgate", x=64, y=F - 8, w=2, h=8, run="p_pass_gate")
    # 소품
    for x in (6, 22, 33, 46, 60, 72):
        r.add("prop", kind="lantern_red", x=x, y=F - 9, len=2)
    for x, flip in ((12, False), (62, True)):
        r.add("prop", kind="fox_statue", x=x, y=F, flip=flip)
    r.add("prop", kind="pine", x=2, y=F, h=9)
    r.add("prop", kind="pine", x=31, y=F, h=8)
    r.add("prop", kind="rock", x=58, y=F, w=3, h=1)
    r.add("prop", kind="hongsal", x=70, y=F)
    r.add("sign", x=8, y=F, look="stone", text="여우고개.|이 너머는 신계(神界)다. 산 자는 돌아가라.|…라고 적혀 있다. 세라는 못 본 척했다.")
    return r


@room
def t_forest():
    r = Room("t_forest", "신계 · 도깨비불 숲길", "shingye", "shingye", "shingye", (2, 1), (2, 1))
    F = 19
    r.ground(F)
    r.fill(0, 0, 0, F - 6)
    r.exit_left("west", F - 5, F - 1, "t_pass", "east")
    # 낮은 둔덕
    r.fill(18, F - 2, 25, F - 1)
    r.fill(20, F - 3, 23, F - 3)
    # 가시 구덩이 5칸 (위로 나뭇가지 발판)
    r.clear(33, F, 37, r.h - 1)
    r.fill(33, F + 2, 37, r.h - 1)
    r.fill(33, F + 1, 37, F + 1, "^")
    r.plat(30, 34, F - 5)
    # 한 단 높은 땅
    r.fill(44, F - 1, 51, F - 1)
    # 석상 여우가 부딪힐 바위
    r.fill(73, F - 3, 74, F - 1)
    r.exit_right("east", F - 5, F - 1, "t_stairs", "west")
    # 적: 한 마리씩
    r.add("enemy", id="wisp1", kind="wisp", x=27, y=F - 6)
    r.add("enemy", id="wisp2", kind="wisp", x=47, y=F - 8)
    r.add("enemy", id="fox1", kind="stone_fox", x=65, y=F, face="left")
    r.add("trigger", id="ta", x=12, y=F - 8, w=2, h=8, run="p_wisp_seen")
    r.add("trigger", id="tf", x=54, y=F - 8, w=2, h=8, run="p_fox_seen")
    # 소품
    for x, hh in ((3, 10), (16, 8), (40, 11), (58, 9), (77, 10)):
        r.add("prop", kind="pine", x=x, y=F, h=hh)
    for x in (9, 29, 52, 70):
        r.add("prop", kind="lantern_red", x=x, y=F - 11, len=3)
    r.add("prop", kind="fox_statue", x=61, y=F, flip=True)
    r.add("prop", kind="fox_statue", x=69, y=F)
    r.add("prop", kind="rock", x=42, y=F - 1, w=2, h=1)
    r.add("prop", kind="debris", x=74, y=F - 3)
    r.add("sign", x=6, y=F, look="stone", text="신단 가는 길.|도깨비불을 만나거든 놀라지 말 것. 저들은 장난을 좋아할 뿐이다.|…다만 맞으면 화를 낸다.")
    for x in (24, 47, 66):
        r.add("light", x=x, y=F - 4, r=4, color="#6ab0ff")
    return r


@room
def t_stairs():
    r = Room("t_stairs", "신계 · 신단 계단", "shingye", "shrine", "shingye", (4, 0), (1, 2))
    F = r.h - 3  # 43
    r.box(wall=1, floor=3, ceil=1)
    r.exit_left("west", F - 5, F - 1, "t_forest", "east")
    # 지그재그 오르막 (한 단 3칸)
    r.plat(8, 13, 40)
    r.plat(16, 21, 37)
    r.fill(26, 34, 38, 35)  # 중간 단 (기록 석등)
    r.plat(18, 23, 31)
    r.plat(9, 14, 28)
    r.fill(1, 25, 7, 26)
    r.plat(10, 15, 22)
    r.plat(18, 23, 19)
    r.fill(24, 16, 29, 17)  # 꼭대기 왼쪽 턱
    # 다리(통과 발판) 아래의 감실 → 출구
    r.plat(30, 38, 16)
    r.fill(30, 17, 30, 24)  # 감실 왼쪽 벽
    r.fill(30, 25, 38, 27)  # 감실 바닥
    r.plat(32, 34, 22)  # 감실에서 다시 올라가는 발판
    r.plat(36, 38, 19)
    r.exit_right("east", 20, 24, "t_trial", "west")
    # 등롱 감시자의 높은 받침
    r.fill(32, 11, 38, 12)
    r.add("enemy", id="watch1", kind="lantern_watcher", x=36, y=11, face="left")
    r.add("save", id="save", x=34, y=34, style="lantern")
    r.add("trigger", id="tw", x=18, y=12, w=6, h=7, run="p_watcher_seen")
    r.add("trigger", id="tdrop", x=33, y=12, w=5, h=4, run="teach_drop")
    # 소품
    for x, y in ((4, 43), (36, 34)):
        r.add("prop", kind="fox_statue", x=x, y=y)
    for x, y, ln in ((12, 1, 6), (26, 1, 4), (20, 24, 2)):
        r.add("prop", kind="lantern_red", x=x, y=y, len=ln)
    r.add("prop", kind="hongsal", x=27, y=34)
    r.add("prop", kind="banner", x=33, y=1, h=6, col="#7a1e24")
    r.add("prop", kind="banner", x=5, y=1, h=8, col="#7a1e24")
    r.add("sign", x=3, y=F, look="stone", text="신단 계단.|오르는 자, 등롱의 눈을 조심하라.")
    return r


@room
def t_trial():
    r = Room("t_trial", "신계 · 봉화 시련", "shingye", "shrine", "shingye_tension", (5, 0), (1, 1))
    F = 19
    r.box(wall=1, floor=4, ceil=2)
    r.exit_left("west", F - 5, F - 1, "t_stairs", "east")
    r.fill(16, F - 4, 23, F - 1)  # 가운데 높은 단
    r.fill(27, F - 3, 27, F - 1)  # 낮은 담
    r.add("brazier", id="b1", x=7, y=F, group="trial", done_flag="t_braziers")
    r.add("brazier", id="b2", x=20, y=F - 4, group="trial", done_flag="t_braziers")
    r.add("brazier", id="b3", x=31, y=F, group="trial", done_flag="t_braziers")
    r.add("puzzle", id="pz", group="trial", mode="all", done_flag="t_braziers")
    r.add("event", id="ev", flag="t_braziers", run="p_trial_burst", done="t_trial_burst")
    r.add("gate", id="g", x=38, y=F - 6, w=1, h=6, open_if="never_open", look="seal")
    r.add("prop", kind="altar", x=35, y=F)
    r.add("prop", kind="fox_statue", x=33, y=F, flip=True)
    r.add("prop", kind="banner", x=12, y=2, h=7, col="#7a1e24")
    r.add("prop", kind="banner", x=28, y=2, h=7, col="#7a1e24")
    r.add("prop", kind="chain", x=4, y=2, h=5)
    r.add("prop", kind="chain", x=36, y=2, h=4)
    r.add("trigger", id="tin", x=3, y=F - 6, w=2, h=6, run="p_trial_enter")
    r.add("sign", x=11, y=F, look="stone", text="시련의 봉화.|세 불을 밝힌 자에게 문이 열리리라.|…그 불을 감당할 수 있다면.")
    return r


@room
def t_throne():
    r = Room("t_throne", "신계 · 왕좌의 전당", "shingye", "shrine", "shingye_tension", (6, 0), (1, 1))
    F = 19
    r.box(wall=1, floor=4, ceil=1)
    r.fill(25, F - 2, 36, F - 1)  # 왕좌 단
    r.fill(23, F - 1, 24, F - 1)
    r.exit_right("east", F - 5, F - 1, "t_collapse", "west")
    r.add("spawn", id="chained", x=10, y=F, face="right")
    r.add("spawn", id="after", x=14, y=F, face="right")
    r.add("prop", kind="throne", x=31, y=F - 2)
    r.add("prop", kind="altar", x=19, y=F)
    r.add("actor", id="bead", who="bead", kind="bead", x=19, y=F - 3, cond="!p_bead_done")
    r.add("actor", id="god", who="neoul_god", kind="neoul_god", x=30, y=F - 2, face="left", hidden=True, cond="!p_bead_done")
    r.add("actor", id="chains", who="chains", kind="chains", x=10, y=F, cond="!p_bead_done")
    for x in (3, 37):
        r.add("prop", kind="curtain", x=x, y=1, w=2, h=12)
    for x in (22, 38):
        r.add("prop", kind="fox_statue", x=x, y=F if x == 22 else F, flip=(x == 38))
    for x in (8, 16, 24):
        r.add("prop", kind="chain", x=x, y=1, h=3)
    r.add("prop", kind="banner", x=31, y=1, h=7, col="#2a3a7a")
    for x in (26, 36):
        r.add("light", x=x, y=F - 6, r=4, color="#6ab0ff")
    return r


@room
def t_collapse():
    r = Room("t_collapse", "신계 · 무너지는 회랑", "shingye", "shrine", "shingye_tension", (7, 0), (3, 1))
    F = 19
    r.box(wall=1, floor=4, ceil=2)
    r.exit_left("west", F - 5, F - 1, "t_throne", "east")

    def pit(x0, x1):
        r.clear(x0, F, x1, r.h - 1)
        r.fill(x0, F + 2, x1, r.h - 1)
        r.fill(x0, F + 1, x1, F + 1, "^")

    pit(15, 18)
    r.fill(24, F - 3, 27, F - 1)
    pit(33, 37)
    r.fill(42, 2, 50, F - 4)  # 낮은 천장
    pit(54, 60)
    r.plat(56, 58, F - 3)
    pit(68, 76)  # 대시 점프 구간 9칸
    r.fill(82, F - 2, 84, F - 1)
    r.fill(86, F - 4, 89, F - 1)
    pit(94, 98)
    r.fill(104, 2, 108, F - 5)
    r.exit_right("east", F - 5, F - 1, "t_gate", "west")
    r.add("spawn", id="start", x=4, y=F, face="right")
    r.add("chaser", id="chaser", x=-10, stop_x=112)
    r.add("trigger", id="tdj", x=63, y=F - 8, w=2, h=8, run="teach_dash_jump")
    for x in (10, 30, 52, 79, 100, 114):
        r.add("prop", kind="pillar", x=x, y=F, h=15)
    for x in (20, 46, 64, 90):
        r.add("prop", kind="chain", x=x, y=2, h=4)
    for x in (12, 40, 70, 110):
        r.add("prop", kind="lantern_red", x=x, y=2, len=2)
    return r


@room
def t_gate():
    r = Room("t_gate", "신계 · 수문", "shingye", "shingye", "shingye_tension", (10, 0), (1, 1))
    F = 19
    r.box(wall=1, floor=4, ceil=1)
    r.exit_left("west", F - 5, F - 1, "t_collapse", "east")
    r.add("save", id="save", x=4, y=F, style="lantern")
    r.add("trigger", id="tb", x=10, y=F - 8, w=2, h=8, run="p_haetae", once=False)
    r.add("enemy", id="haetae", kind="haetae", x=29, y=F, face="left", engaged=False)
    # 싸움이 시작되면 왼쪽 통로에 철창이 내려와 투기장을 막는다 (해태·세라가 통로 틈으로 나가지 않게)
    r.add("gate", id="arena", x=1, y=F - 5, w=1, h=5, open_if="!t_gate_fight", look="bars")
    r.add("gate", id="g", x=38, y=F - 7, w=1, h=7, open_if="haetae_down", look="seal")
    r.add("door", id="portal", x=36, y=F, to="s_infirmary", to_id="bed", style="portal", cond="haetae_down")
    r.add("prop", kind="hongsal", x=34, y=F)
    for x in (14, 26):
        r.add("prop", kind="lantern_red", x=x, y=1, len=3)
    for x in (2, 37):
        r.add("prop", kind="pine", x=x, y=F, h=9)
    r.add("prop", kind="fox_statue", x=7, y=F)
    return r


# ═══════════════════════════════════════════════════════════
# 마녀학교 (docs/archive/sera/chapter1.md 5.2절, 12.2절)
#   층: y0 상층 · y1 2층 · y2 1층 · y3 앞마당(언덕 아래)·비속성반 · y4 지하 · y5 봉인의 방
#   1칸 방의 바닥 윗면 = 19행, 좌우 출구 = 14~18행
# ═══════════════════════════════════════════════════════════

def school_room(rid, title, theme, music, cell, cells, dark=0.0, ceil=2, floor=4):
    return boxed_room(rid, title, "school", theme, music, cell, cells, dark, ceil, floor)


def windows(r, xs, y, w=3, h=6):
    for x in xs:
        r.add("prop", kind="window", x=x, y=y, w=w, h=h)


@room
def s_infirmary():
    r = school_room("s_infirmary", "마녀학교 · 의무실", "room", "school", (7, 2), (1, 1))
    F = 19
    r.exit_left("west", F - 5, F - 1, "s_eastcorr", "east")
    r.door("stair", 35, F, "s_dorm", "stair", style="stair_up", label="기숙사")
    r.add("save", id="bed", x=28, y=F, style="bed")
    r.add("npc", id="mirabel", who="mirabel", x=21, y=F, face="right")
    r.add("npc", id="pippa", who="pippa", x=31, y=F, face="left", cond="!s_woke")
    windows(r, (8, 17), F - 4, 3, 7)
    for x in (12, 32):
        r.add("prop", kind="bed_prop", x=x, y=F)
    r.add("prop", kind="potion_shelf", x=4, y=F, w=3, h=4)
    r.add("prop", kind="curtain", x=24, y=2, w=2, h=10)
    r.add("prop", kind="candles", x=25, y=F)
    r.add("prop", kind="plant", x=37, y=F)
    r.add("prop", kind="chandelier", x=20, y=2, len=3)
    r.add("sign", x=6, y=F, look="board", text="의무실 수칙|하나, 폭주한 학생은 침대에 눕혀 식힐 것.|둘, 물약은 하루 두 병까지.|셋, 사역마의 침대 출입 금지. …털이 날려요! — 미라벨")
    return r


@room
def s_dorm():
    r = school_room("s_dorm", "마녀학교 · 기숙사", "room", "school", (7, 1), (1, 1))
    F = 19
    r.door("stair", 35, F, "s_infirmary", "stair", style="stair_down", label="의무실")
    r.add("save", id="bed", x=20, y=F, style="bed")
    # 벽장 (환영 벽 뒤 깃털)
    r.fill(1, 2, 6, 12)
    r.fill(6, 13, 6, 18, "I")
    r.add("pickup", id="feather_dorm", kind="feather", x=3, y=F, name="수호의 깃털", text="최대 체력이 1 늘었다.")
    r.add("prop", kind="bed_prop", x=12, y=F)
    r.add("prop", kind="bed_prop", x=26, y=F)
    windows(r, (16, 30), F - 4, 3, 7)
    r.add("prop", kind="desk", x=9, y=F, w=2)
    r.add("prop", kind="cauldron", x=29, y=F)
    r.add("prop", kind="rug", x=20, y=F, w=8)
    r.add("prop", kind="painting", x=10, y=F - 6, w=2, h=2, col="#3a2a4a")
    r.add("sign", x=24, y=F, look="note", text="피피의 쪽지|세라, 내 실험 재료 건드리지 마. 진짜로.|…특히 초록색 병. 그거 아직 살아 있어.")
    return r


@room
def s_eastcorr():
    r = school_room("s_eastcorr", "마녀학교 · 동관 복도", "hall", "school", (6, 2), (1, 1))
    F = 19
    r.exit_left("west", F - 5, F - 1, "s_hall", "east1")
    r.exit_right("east", F - 5, F - 1, "s_infirmary", "west")
    r.door("down", 6, F, "s_cafeteria", "up", style="stair_down", label="식당")
    r.plat(18, 24, F - 5)
    r.add("enemy", id="broom1", kind="broom", x=22, y=F - 8, face="right")
    windows(r, (12, 28), F - 4, 3, 8)
    r.add("prop", kind="banner", x=20, y=2, h=5)
    r.add("prop", kind="painting", x=34, y=F - 5, w=3, h=3, col="#4a2a2a")
    r.add("prop", kind="candles", x=16, y=F)
    r.add("prop", kind="plant", x=2, y=F)
    r.add("sign", x=33, y=F, look="board", text="동관 게시판|[공지] 어젯밤부터 물건이 제멋대로 움직이는 일이 잦습니다.|움직이는 물건을 보면 교사에게 알리고, 맞서지 말 것. — 교무실")
    return r


@room
def s_hall():
    r = school_room("s_hall", "마녀학교 · 중앙 홀", "hall", "school", (4, 1), (2, 2))
    F1 = r.h - 4  # 42: 1층 바닥
    F2 = 19       # 2층 발코니
    # 출구: 1층 좌우, 2층 좌우
    r.exit_left("west1", F1 - 5, F1 - 1, "s_westcorr", "east")
    r.exit_right("east1", F1 - 5, F1 - 1, "s_eastcorr", "west")
    r.exit_left("west2", F2 - 5, F2 - 1, "s_library", "east")
    r.exit_right("east2", F2 - 5, F2 - 1, "s_clock", "west1")
    # 2층 발코니 (안쪽 끝은 통과 발판 — 아래에서 뛰어오름)
    r.fill(1, F2, 9, F2 + 1)
    r.plat(10, 17, F2)
    r.fill(70, F2, 78, F2 + 1)
    r.plat(62, 69, F2)
    # 계단 (지그재그 통과 발판, 3칸 간격)
    for x0, x1, y in ((9, 15, 39), (2, 7, 36), (9, 15, 33), (2, 7, 30), (10, 16, 27), (12, 17, 24), (10, 15, 21)):
        r.plat(x0, x1, y)
    for x0, x1, y in ((64, 70, 39), (72, 77, 36), (64, 70, 33), (72, 77, 30), (63, 69, 27), (62, 67, 24), (64, 69, 21)):
        r.plat(x0, x1, y)
    # 샹들리에 깃털 (2단 점프): 발코니 → 5칸 위 턱 → 샹들리에 위
    r.plat(20, 23, 14)
    r.plat(56, 59, 14)
    r.plat(30, 33, 11)
    r.plat(46, 49, 11)
    r.plat(38, 42, 10)
    r.add("prop", kind="chandelier", x=40, y=2, len=7)
    r.add("pickup", id="feather_hall", kind="feather", x=40, y=10, name="수호의 깃털", text="최대 체력이 1 늘었다.")
    # 1층: 창립자 동상(기록), 정문
    r.add("save", id="statue", x=32, y=F1, style="statue")
    r.door("gate", 48, F1, "s_courtyard", "gate", style="grand", label="정문 — 앞마당")
    r.door("up", 74, F2, "s_advclass", "down", style="stair_up", label="고급반", lock="adv_done", lock_msg="고급반 계단 — 안쪽에서 잠겨 있다. 위층으로 가는 다른 길을 찾아야 한다.")
    # 인물
    r.add("npc", id="isolde", who="isolde", x=36, y=F1, face="left", cond="s_woke,!adv_done")
    r.add("npc", id="stu_a", who="student_a", x=22, y=F1, face="right", talk="npc_hall_a")
    r.add("npc", id="stu_b", who="student_b", x=56, y=F1, face="left", talk="npc_hall_b")
    r.add("npc", id="stu_c", who="student_c", x=8, y=F2, face="right", talk="npc_hall_c")
    # 소품
    windows(r, (22, 58), F1 - 6, 5, 14)
    windows(r, (30, 50), F2 - 6, 3, 8)
    r.add("prop", kind="rug", x=40, y=F1, w=24)
    for x in (18, 62):
        r.add("prop", kind="pillar", x=x, y=F1, h=20)
    for x, c in ((26, "#6a1e30"), (54, "#1e2a6a")):
        r.add("prop", kind="banner", x=x, y=F2 + 2, h=7, col=c)
    for x in (4, 76):
        r.add("prop", kind="candles", x=x, y=F1)
    r.add("prop", kind="painting", x=40, y=F2 - 3, w=4, h=3, col="#2a2a4a")
    r.add("sign", x=44, y=F1, look="board", text="중앙 홀 안내|1층 서관: 마법반·실습장 / 1층 동관: 의무실·식당|2층 서쪽: 도서관 / 2층 동쪽: 시계탑|정문 아래: 앞마당·온실. 지하 출입 금지.")
    return r


@room
def s_westcorr():
    r = school_room("s_westcorr", "마녀학교 · 서관 복도", "hall", "school", (3, 2), (1, 1))
    F = 19
    r.exit_right("east", F - 5, F - 1, "s_hall", "west1")
    r.exit_left("west", F - 5, F - 1, "s_class", "east")
    r.door("down", 22, F, "s_nonelem", "up", style="stair_down", label="비속성마법반", lock="golem_done", lock_msg="공사 중 — 계단 보수 중이니 돌아가시오.")
    r.add("npc", id="stu", who="student_c", x=31, y=F, face="left", talk="npc_westcorr")
    windows(r, (8, 30), F - 4, 3, 8)
    r.add("prop", kind="painting", x=16, y=F - 6, w=3, h=3, col="#2a4a3a")
    r.add("prop", kind="candles", x=14, y=F)
    r.add("prop", kind="banner", x=26, y=2, h=5, col="#6a1e30")
    r.add("sign", x=18, y=F, look="board", text="서관 게시판|[마법반] 오늘 실습: 화염 제어. 늦는 학생은 그을음 청소.|[비속성반] 계단 보수 중. 오필리아 교수님은 어차피 주무십니다.")
    return r


@room
def s_class():
    r = school_room("s_class", "마녀학교 · 마법반", "room", "school", (2, 2), (1, 1))
    F = 19
    r.exit_right("east", F - 5, F - 1, "s_westcorr", "west")
    r.exit_left("west", F - 5, F - 1, "s_training", "east")
    r.add("save", id="candle", x=33, y=F, style="candle")
    r.add("npc", id="emberlyn", who="emberlyn", x=11, y=F, face="right")
    r.add("prop", kind="blackboard", x=11, y=F - 4, w=6, h=4)
    for x in (17, 21, 25, 29):
        r.add("prop", kind="desk", x=x, y=F, w=2)
    r.add("npc", id="stu_a", who="student_a", x=21, y=F, face="left", talk="npc_class_a")
    r.add("npc", id="stu_b", who="student_b", x=26, y=F, face="left", talk="npc_class_b")
    r.add("prop", kind="chandelier", x=22, y=2, len=3)
    r.add("prop", kind="globe", x=4, y=F)
    r.add("prop", kind="potion_shelf", x=37, y=F, w=2, h=4)
    windows(r, (6, 36), F - 9, 2, 5)
    return r


@room
def s_training():
    r = school_room("s_training", "마녀학교 · 실습장", "hall", "school", (0, 2), (2, 1), ceil=1)
    F = 19
    r.exit_right("east", F - 8, F - 4, "s_class", "west")
    # 관람석과 발판 (한 번 점프 3칸 간격: 아직 2단 점프 없음)
    r.fill(70, F - 3, 78, F - 1)
    r.plat(24, 28, F - 3)
    r.plat(29, 37, F - 6)
    r.plat(50, 55, F - 3)
    # 과녁 3개: 바닥 둘(좌우)·높은 발판 위 하나. 맞으면 4초 동안 불이 남고, 셋이 동시에 타야 합격 (폭주 70 미만)
    # 화염탄 사거리 11T 안에서 쏠 수 있게 가운데에 모음
    r.add("target", id="t1", group="tg", x=22, y=F, dx=2, period=2.6, hold=5.0)
    r.add("target", id="t2", group="tg", x=33, y=F - 6, dx=2, period=2.4, hold=5.0)
    r.add("target", id="t3", group="tg", x=42, y=F, dx=-2, period=3.0, phase=1.0, hold=5.0)
    r.add("puzzle", id="pz", group="tg", mode="targets", done_flag="t_targets_done", max_overload=70)
    r.add("event", id="ev", flag="t_targets_done", run="s_golem", done="s_golem_started")
    r.add("enemy", id="golem", kind="golem", x=58, y=F, face="left", cond="s_golem_started,!golem_done")
    r.add("npc", id="emberlyn", who="emberlyn", x=74, y=F - 3, face="left", cond="met_emberlyn")
    r.add("prop", kind="target_board", x=8, y=F)
    r.add("prop", kind="target_board", x=62, y=F)
    r.add("prop", kind="magic_circle", x=40, y=F, w=8)
    for x in (6, 26, 44, 66):
        r.add("prop", kind="torch", x=x, y=F - 6)
    r.add("prop", kind="banner", x=40, y=1, h=6, col="#8a3a1e")
    r.add("sign", x=67, y=F, look="board", text="실습장 수칙|하나, 과녁 외의 것에 불을 붙이지 말 것.|둘, 훈련 골렘은 교사의 허락 없이 깨우지 말 것.")
    return r


@room
def s_nonelem():
    r = school_room("s_nonelem", "마녀학교 · 비속성마법반", "room", "school", (3, 3), (1, 1))
    F = 19
    r.door("up", 22, F, "s_westcorr", "down", style="stair_up", label="서관 복도")
    r.exit_left("west", F - 5, F - 1, "s_levcourse", "east")
    r.add("npc", id="ophelia", who="ophelia", x=28, y=5, face="left", cond="!ophelia_awake")
    r.add("npc", id="ophelia2", who="ophelia", x=28, y=F, face="left", cond="ophelia_awake")
    r.add("prop", kind="blackboard", x=31, y=F - 4, w=6, h=4)
    for x in (10, 14, 18):
        r.add("prop", kind="desk", x=x, y=F, w=2)
    r.add("prop", kind="magic_circle", x=28, y=F, w=6, col="#b8a8ff")
    r.add("prop", kind="globe", x=36, y=F)
    windows(r, (6, 16), F - 9, 2, 5)
    r.add("prop", kind="chandelier", x=12, y=2, len=2)
    return r


@room
def s_levcourse():
    r = school_room("s_levcourse", "마녀학교 · 부양 실습실", "room", "school", (1, 3), (2, 1), ceil=1)
    F = 19
    r.exit_right("east", F - 5, F - 1, "s_nonelem", "west")
    # 2단 점프 코스: 6칸 턱, 높이 뜬 발판
    r.fill(60, F - 6, 66, F - 1)
    r.plat(50, 54, F - 9)
    r.fill(38, F - 12, 44, F - 11)
    r.plat(26, 30, F - 9)
    r.fill(12, F - 6, 18, F - 1)
    r.plat(4, 8, F - 12)
    r.fill(20, 1, 22, 6)
    lanterns = ((63, F - 9), (52, F - 13), (41, F - 15), (28, F - 13), (6, F - 15))
    for i, (x, y) in enumerate(lanterns):
        r.add("float_lantern", id="l%d" % i, group="lev", x=x, y=y, done_flag="lev_done")
    r.add("event", id="ev", flag="lev_done", run="s_lev_done")
    r.add("prop", kind="magic_circle", x=70, y=F, w=6, col="#b8a8ff")
    for x in (34, 58):
        r.add("prop", kind="pillar", x=x, y=F, h=17)
    r.add("sign", x=74, y=F, look="board", text="부양 실습실|떠 있는 등불 다섯 개를 모두 모으면 합격.|떨어져도 다치지 않게 바닥을 푹신하게 해 두었단다~ (거짓말) — 오필리아")
    return r


@room
def s_library():
    r = school_room("s_library", "마녀학교 · 도서관 열람실", "library", "library", (2, 1), (2, 1))
    F = 19
    r.exit_right("east", F - 5, F - 1, "s_hall", "west2")
    # 서가 미로 입구: 6칸 높이 책장 턱 → 2단 점프
    r.fill(1, 9, 7, 10)
    r.fill(8, F - 6, 13, F - 6)
    r.exit_left("west", 4, 8, "s_stacks", "east1")
    r.add("save", id="candle", x=66, y=F, style="candle")
    r.add("npc", id="greta", who="greta", x=48, y=F, face="left")
    r.add("prop", kind="desk", x=50, y=F, w=4, books=True)
    for x in (18, 24, 30, 36, 58, 72):
        r.add("prop", kind="bookshelf", x=x, y=F, w=4, h=9)
    for x in (27, 63):
        r.add("prop", kind="chandelier", x=x, y=2, len=3)
    for x in (21, 33, 61, 75):
        r.add("prop", kind="lamp_green", x=x, y=F)
    windows(r, (42, 55), F - 9, 3, 7)
    r.add("actor", id="book", who="book", kind="book", x=49, y=F - 2, hidden=True, cond="!key_stolen")
    r.add("sign", x=40, y=F, look="board", text="도서관 이용 수칙|하나, 정숙.|둘, 정숙.|셋, 책이 날아다니면 사서에게 알릴 것. 그리고 정숙. — 그레타 잉크웰")
    return r


@room
def s_stacks():
    r = school_room("s_stacks", "마녀학교 · 서가 미로", "library", "library", (1, 0), (1, 2))
    FB = r.h - 4  # 42
    r.exit_right("east1", FB - 5, FB - 1, "s_library", "west")
    # 꼭대기 (마도서 결전) 바닥 12행, 왼쪽 구멍은 통과 발판
    r.fill(1, 12, 38, 13)
    r.clear(3, 12, 8, 13)
    r.plat(3, 8, 12)
    r.door("archive", 3, 12, "s_archive", "out", style="iron", label="금서 구역", lock="key_recovered", lock_msg="금서 구역. 열쇠 없이는 열리지 않는다.")
    # 상층 회랑으로: 환영 벽
    r.fill(37, 7, 38, 11, "I")
    r.exit_right("east2", 7, 11, "s_gallery", "west")
    # 미로 (3칸 간격 층)
    r.plat(29, 36, 39)
    r.fill(19, 36, 33, 36)
    r.plat(11, 18, 36)
    r.plat(3, 10, 33)
    r.fill(23, 33, 38, 33)
    r.fill(11, 30, 21, 30)
    r.plat(1, 6, 30)
    r.plat(7, 13, 27)
    r.fill(25, 27, 34, 27)
    r.fill(15, 24, 24, 24)
    r.plat(31, 38, 24)
    r.plat(5, 11, 21)
    r.fill(19, 21, 29, 21)
    r.fill(1, 18, 7, 18)
    r.plat(12, 18, 18)
    r.fill(30, 18, 38, 18)
    r.plat(2, 9, 15)
    r.plat(22, 27, 15)
    # 막다른 곳의 보상
    r.add("pickup", id="page1", kind="page", x=36, y=33, name="낡은 쪽지", text="'창립자의 일지 — 굶주린 것은 언제나 배가 고프다. 그래서 우리는 불로 배를 채워 재운다.'")
    r.add("pickup", id="page2", kind="page", x=36, y=18, name="찢어진 책장", text="'동방의 여우신은 아홉 꼬리를 가졌다. 그 불은 푸르고, 결코 무엇도 태워 없애지 않는다.'")
    r.add("npc", id="hodu", who="hodu", x=29, y=27, face="left", talk="npc_hodu_maze")
    r.add("enemy", id="grimoire", kind="grimoire", x=24, y=8, face="left", cond="key_stolen")
    r.add("trigger", id="tg", x=10, y=2, w=4, h=10, run="s_grimoire", once=False)
    r.add("save", id="candle", x=34, y=FB, style="candle")
    for x in (6, 15, 27):
        r.add("prop", kind="bookshelf", x=x, y=FB, w=4, h=8)
    for x in (20, 32):
        r.add("prop", kind="lamp_green", x=x, y=12)
    r.add("prop", kind="chandelier", x=20, y=2, len=2)
    return r


@room
def s_archive():
    r = school_room("s_archive", "마녀학교 · 금서 구역", "library", "library", (0, 0), (1, 1), dark=0.25)
    F = 19
    r.door("out", 35, F, "s_stacks", "archive", style="iron", label="서가 미로")
    r.add("sign", id="record", x=18, y=F, look="book", prompt="금서 기록 읽기", run="s_archive_read")
    r.add("actor", id="founder", who="founder", kind="founder", x=12, y=F, hidden=True)
    for x in (4, 9, 26, 31):
        r.add("prop", kind="bookshelf", x=x, y=F, w=4, h=10)
    for x in (6, 28):
        r.add("prop", kind="chain", x=x, y=2, h=7)
    r.add("prop", kind="magic_circle", x=18, y=F, w=6, col="#8ad0ff")
    r.add("light", x=18, y=F - 3, r=5, color="#8ad0ff")
    r.add("prop", kind="candles", x=22, y=F)
    return r


@room
def s_gallery():
    r = school_room("s_gallery", "마녀학교 · 상층 회랑", "hall", "school", (2, 0), (2, 1))
    F = 19
    r.exit_left("west", F - 5, F - 1, "s_stacks", "east2")
    r.exit_right("east", F - 5, F - 1, "s_advclass", "west")
    # 시간 문: 촛대에 화염탄 → 3초 열림
    r.add("switch", id="sw", x=22, y=F - 5, flag="gal_door", time=3.5)
    r.add("gate", id="door", x=36, y=F - 6, w=1, h=6, open_if="gal_door", look="bars")
    r.fill(36, 2, 36, F - 7)
    r.add("enemy", id="knight1", kind="armor", x=58, y=F, face="left")
    windows(r, (8, 16, 46, 54, 66, 74), F - 4, 3, 10)
    for x in (28, 62):
        r.add("prop", kind="banner", x=x, y=2, h=6, col="#1e2a6a")
    r.add("prop", kind="painting", x=30, y=F - 6, w=4, h=3, col="#3a2a3a")
    r.add("sign", x=12, y=F, look="board", text="상층 회랑|이 문은 촛대의 불이 켜져 있는 동안만 열린다.|…달려라. — 경비 갑옷 관리인")
    return r


@room
def s_advclass():
    r = school_room("s_advclass", "마녀학교 · 고급마법반", "room", "school", (4, 0), (2, 1))
    F = 19
    r.exit_left("west", F - 5, F - 1, "s_gallery", "east")
    r.exit_right("east", F - 5, F - 1, "s_clock", "west2")
    r.add("gate", id="sc", x=78, y=F - 5, w=1, h=5, open_if="rev_s_clock_I1", look="bars")
    r.door("down", 8, F, "s_hall", "up", style="stair_down", label="중앙 홀 2층")
    r.add("enemy", id="knight2", kind="armor", x=46, y=F, face="left", cond="ab_fox_window")
    r.add("npc", id="isolde", who="isolde", x=56, y=F, face="left", cond="ab_fox_window")
    r.add("npc", id="veronica", who="veronica", x=64, y=F, face="left", cond="ab_fox_window")
    r.add("prop", kind="blackboard", x=30, y=F - 4, w=8, h=5)
    for x in (16, 22, 40, 70):
        r.add("prop", kind="desk", x=x, y=F, w=2)
    r.add("prop", kind="magic_circle", x=52, y=F, w=10)
    r.add("prop", kind="globe", x=74, y=F)
    windows(r, (12, 36, 60), F - 9, 3, 6)
    r.add("prop", kind="chandelier", x=30, y=2, len=3)
    r.add("prop", kind="chandelier", x=56, y=2, len=3)
    return r


@room
def s_clock():
    r = school_room("s_clock", "마녀학교 · 시계탑", "clock", "school", (6, 0), (1, 2))
    FB = r.h - 4  # 42
    r.exit_left("west1", FB - 5, FB - 1, "s_hall", "east2")
    # 꼭대기 바닥 12행
    r.fill(1, 12, 38, 13)
    r.clear(30, 12, 35, 13)
    r.plat(30, 35, 12)
    r.fill(1, 7, 2, 11, "I")
    r.exit_left("west2", 7, 11, "s_advclass", "east")
    r.door("hm", 20, 12, "s_headmaster", "door", style="grand", label="교장실", lock="adv_done", lock_msg="교장실. 부르심 없이는 들어갈 수 없다.")
    # 아래: 6칸 높이 톱니 사이 (2단 점프) — 톱니 받침이 좌우로 엇갈림
    r.fill(10, 36, 16, 37)
    r.fill(20, 30, 26, 31)
    r.fill(15, 24, 21, 25)
    r.fill(25, 18, 32, 19)
    r.plat(2, 6, 30)
    r.plat(33, 37, 24)
    r.add("save", id="mid", x=17, y=24, style="candle")
    r.add("enemy", id="broom1", kind="broom", x=30, y=33, face="left")
    r.add("enemy", id="broom2", kind="broom", x=8, y=20, face="right")
    r.add("prop", kind="clock_face", x=20, y=6, w=8)
    for x, y, h in ((6, 2, 10), (34, 14, 12), (10, 26, 8)):
        r.add("prop", kind="chain", x=x, y=y, h=h)
    r.add("prop", kind="bell", x=27, y=2)
    r.add("sign", x=36, y=FB, look="board", text="시계탑|톱니 사이로 오를 수 있는 사람은 오필리아 교수님 제자뿐.|빗자루 보관함이 열려 있으면 닫아 주세요.")
    return r


@room
def s_headmaster():
    r = school_room("s_headmaster", "마녀학교 · 교장실", "room", "school", (7, 0), (1, 1))
    F = 19
    r.door("door", 4, F, "s_clock", "hm", style="grand", label="시계탑")
    r.add("npc", id="astrid", who="astrid", x=26, y=F, face="left")
    r.add("prop", kind="desk", x=29, y=F, w=4)
    r.add("prop", kind="bookshelf", x=12, y=F, w=4, h=10)
    r.add("prop", kind="bookshelf", x=36, y=F, w=3, h=10)
    r.add("prop", kind="window", x=20, y=F - 5, w=5, h=10)
    r.add("prop", kind="globe", x=33, y=F)
    r.add("prop", kind="fox_statue", x=17, y=F)
    r.add("prop", kind="painting", x=26, y=F - 8, w=4, h=4, col="#1a2a5a")
    r.add("prop", kind="candles", x=8, y=F)
    return r


@room
def s_courtyard():
    r = Room("s_courtyard", "마녀학교 · 앞마당", "school", "exterior", "school", (4, 3), (2, 1))
    F = 19
    r.ground(F)
    r.fill(0, 0, 0, F - 1)
    r.fill(r.w - 1, 0, r.w - 1, F - 1)
    # 정문 계단 (위쪽이 학교)
    r.fill(34, F - 2, 46, F - 1)
    r.fill(36, F - 3, 44, F - 3)
    r.door("gate", 40, F - 3, "s_hall", "gate", style="grand", label="학교 정문")
    r.door("greenhouse", 10, F, "s_greenhouse", "up", style="stair_down", label="유리 온실")
    r.door("cellar", 68, F, "s_cellar", "up", style="iron", label="지하 저장고", lock="key_basement", lock_msg="지하 철문. 굳게 잠겨 있다. 교장의 허락 없이는 열 수 없다.")
    r.add("save", id="yard", x=28, y=F, style="candle")
    r.add("prop", kind="fountain", x=54, y=F)
    for x, hh in ((4, 9), (20, 11), (60, 10), (76, 9)):
        r.add("prop", kind="pine", x=x, y=F, h=hh)
    for x in (16, 32, 48, 64):
        r.add("prop", kind="torch", x=x, y=F)
    r.add("npc", id="stu", who="student_b", x=50, y=F, face="left", talk="npc_courtyard")
    r.add("sign", x=72, y=F, look="board", text="지하 저장고|교장의 명으로 출입을 금함.|…밤마다 안에서 무언가 씹는 소리가 난다는 소문은 사실무근. — 관리인")
    return r


@room
def s_greenhouse():
    r = school_room("s_greenhouse", "마녀학교 · 유리 온실", "greenhouse", "school", (4, 4), (1, 1))
    F = 19
    r.door("up", 4, F, "s_courtyard", "greenhouse", style="stair_up", label="앞마당")
    r.plat(12, 18, F - 4)
    r.plat(28, 34, F - 5)
    r.add("enemy", id="vine", kind="snapvine", x=24, y=F, face="left")
    r.add("pickup", id="moonherb", kind="moonherb", x=35, y=F, name="월광초", flag="moonherb", text="달빛을 머금은 약초. 피피가 찾던 것이다.")
    for x in (8, 15, 20, 31, 37):
        r.add("prop", kind="plant", x=x, y=F)
    windows(r, (10, 22, 32), F - 8, 4, 6)
    return r


@room
def s_cafeteria():
    r = school_room("s_cafeteria", "마녀학교 · 식당", "room", "school", (6, 3), (1, 1))
    F = 19
    r.door("up", 4, F, "s_eastcorr", "down", style="stair_up", label="동관 복도")
    r.exit_right("east", F - 5, F - 1, "s_alchemy", "west")
    r.add("npc", id="butter", who="butterworth", x=26, y=F, face="left")
    r.add("npc", id="stu", who="student_a", x=13, y=F, face="right", talk="npc_cafe")
    r.add("prop", kind="cauldron", x=30, y=F)
    for x in (10, 17):
        r.add("prop", kind="desk", x=x, y=F, w=3, books=False)
    r.add("prop", kind="potion_shelf", x=35, y=F, w=3, h=4)
    r.add("prop", kind="chandelier", x=14, y=2, len=3)
    windows(r, (20,), F - 9, 3, 5)
    return r


@room
def s_alchemy():
    r = school_room("s_alchemy", "마녀학교 · 연금술실", "room", "school", (7, 3), (1, 1))
    F = 19
    r.exit_left("west", F - 5, F - 1, "s_cafeteria", "east")
    r.add("npc", id="pippa", who="pippa", x=22, y=F, face="left", cond="s_woke")
    for x in (16, 28):
        r.add("prop", kind="cauldron", x=x, y=F)
    for x in (5, 33):
        r.add("prop", kind="potion_shelf", x=x, y=F, w=3, h=5)
    r.add("prop", kind="desk", x=11, y=F, w=3)
    r.add("prop", kind="lamp_green", x=24, y=F - 6)
    r.add("sign", x=37, y=F, look="note", text="피피의 실험 노트|월광초만 있으면 물약 병을 하나 더 만들 수 있는데!|온실 안쪽에 자라는데, 요즘 덩굴이 사나워져서 못 가겠다…")
    return r


@room
def s_cellar():
    r = school_room("s_cellar", "마녀학교 · 지하 저장고", "basement", "basement", (5, 4), (1, 1), dark=0.2)
    F = 19
    r.door("up", 4, F, "s_courtyard", "cellar", style="stair_up", label="앞마당")
    # 출구는 높은 턱 위, 그 아래 금 간 벽 너머 깃털
    r.fill(26, 14, 38, 14)
    r.exit_right("east", 9, 13, "s_sealcorr", "west")
    r.plat(18, 23, 15)
    r.add("cracked", id="crack", x=26, y=15, w=2, h=4)
    r.add("pickup", id="feather_cellar", kind="feather", x=34, y=F, name="수호의 깃털", text="최대 체력이 1 늘었다.")
    r.add("enemy", id="slime", kind="slime", x=17, y=F, face="left")
    for x in (8, 12, 22):
        r.add("prop", kind="barrel", x=x, y=F)
    for x in (10, 20):
        r.add("prop", kind="crate", x=x, y=F)
    r.add("prop", kind="chain", x=14, y=2, h=5)
    r.add("prop", kind="torch", x=24, y=F - 6)
    return r


@room
def s_sealcorr():
    r = school_room("s_sealcorr", "마녀학교 · 봉인 회랑", "basement", "basement", (6, 4), (2, 1), dark=0.4)
    F = 19
    r.exit_left("west", F - 5, F - 1, "s_cellar", "east")
    r.add("enemy", id="hound", kind="hound", x=24, y=F, face="left")
    # 봉화 순서 퍼즐 (봉인 결계 안: 폭주 없음, 불기둥 자동 조준)
    r.add("calm", id="calm", x=40, y=F - 10, w=28, h=10)
    r.add("brazier", id="b1", x=44, y=F, group="seal", order=2, symbol="moon", style="seal", done_flag="seal_open")
    r.add("brazier", id="b2", x=52, y=F, group="seal", order=3, symbol="flame", style="seal", done_flag="seal_open")
    r.add("brazier", id="b3", x=60, y=F, group="seal", order=1, symbol="fox", style="seal", done_flag="seal_open")
    r.add("puzzle", id="pz", group="seal", mode="order", done_flag="seal_open")
    r.add("hint_mural", id="mural", x=46, y=F - 9, w=8, h=4, symbols=["fox", "moon", "flame"], text="여우가 깨우고, 달이 달래고, 불이 잠재운다")
    r.add("gate", id="g", x=68, y=F - 7, w=1, h=7, open_if="seal_open", look="seal")
    r.fill(68, 2, 68, F - 8)
    r.add("save", id="end", x=72, y=F, style="candle")
    r.door("down", 77, F, "s_sealroom", "up", style="stair_down", label="봉인의 방")
    r.add("trigger", id="tin", x=38, y=F - 6, w=2, h=6, run="s_seal_puzzle_hint")
    for x in (10, 30, 64):
        r.add("prop", kind="chain", x=x, y=2, h=8)
    for x in (36, 66):
        r.add("prop", kind="pillar", x=x, y=F, h=16)
    r.add("prop", kind="magic_circle", x=52, y=F, w=16, col="#9a6aff")
    return r


@room
def s_sealroom():
    r = school_room("s_sealroom", "마녀학교 · 봉인의 방", "basement", "basement", (7, 5), (1, 1), dark=0.25, ceil=1)
    F = 19
    r.door("up", 3, F, "s_sealcorr", "down", style="stair_up", label="봉인 회랑")
    r.add("actor", id="seal", who="seal", kind="seal", x=26, y=F)
    r.add("enemy", id="agwi", kind="agwi", x=28, y=F, face="left", engaged=False)
    r.add("trigger", id="tb", x=8, y=F - 8, w=2, h=8, run="s_agwi", once=False)
    for x in (12, 38):
        r.add("prop", kind="pillar", x=x, y=F, h=17)
    for x in (16, 22, 32):
        r.add("prop", kind="chain", x=x, y=1, h=9)
    return r


# ═══════════════════════════════════════════════════════════
# 개발용 시험 방 (지도에 나오지 않음)
# ═══════════════════════════════════════════════════════════

@room
def dev_lab():
    r = Room("dev_lab", "시험장", "dev", "hall", "", (0, 0), (2, 1))
    F = 19
    r.box(wall=1, floor=r.h - F, ceil=2)
    r.plat(10, 16, F - 4)
    r.plat(60, 66, F - 4)
    r.fill(30, F - 7, 34, F - 7)  # 공중 발판(벽)
    r.fill(46, F - 7, 50, F - 7)
    r.add("spawn", id="start", x=6, y=F, face="right")
    r.add("spawn", id="mid", x=40, y=F, face="right")
    r.add("spawn", id="e1", x=50, y=F)
    r.add("spawn", id="e2", x=64, y=F)
    r.add("spawn", id="e_air", x=48, y=F - 8)
    return r


# ═══════════════════════════════════════════════════════════

# ─── 도달 검사 (대략적인 이동 모형) ─────────────────────
SOLID = "#IW"
REVEAL = [False]


def standable(g, x, y):
    h, w = len(g), len(g[0])
    if not (0 <= x < w and 0 < y < h):
        return False
    if g[y][x] not in "#=" and not (g[y][x] in "IW"):
        return False
    for k in (1, 2):
        if y - k < 0 or g[y - k][x] in SOLID or g[y - k][x] == "=" and k == 2 and False:
            return False
        if y - k >= 0 and g[y - k][x] in SOLID:
            return False
    return True


def clear(g, x, y):
    h, w = len(g), len(g[0])
    if not (0 <= x < w):
        return False
    if y < 0:
        return True
    if y >= h:
        return False
    return g[y][x] not in SOLID


def updrafts(r):
    """상승 기류(불꽃 날개로 탐): updraft 개체의 칸 범위 (x0, x1, y_top, y_bot)"""
    out = []
    for e in r.ents:
        if e.get("t") == "updraft":
            out.append((e["x"], e["x"] + e.get("w", 2) - 1, e["y"], e["y"] + e.get("h", 8) - 1))
    return out


def reach(r, start, dj, wings=False):
    g = r.g if not REVEAL[0] else [[("." if c == "I" else c) for c in row] for row in r.g]
    H = 7 if dj else 4
    drafts = updrafts(r) if wings else []
    seen = {start}
    stack = [start]
    while stack:
        x, y = stack.pop()
        nxt = []
        for dx in (-1, 1):
            if standable(g, x + dx, y):
                nxt.append((x + dx, y))
            elif clear(g, x + dx, y - 1) and clear(g, x + dx, y - 2) and not (0 <= y < r.h and g[y][x + dx] in "#=" if 0 <= x + dx < r.w else False):
                # 떨어짐: 옆 칸 아래로
                for drift in range(0, 4):
                    cx = x + dx * (1 + drift)
                    if not (0 <= cx < r.w):
                        break
                    yy = y
                    while yy < r.h - 1 and clear(g, cx, yy):
                        yy += 1
                    if standable(g, cx, yy):
                        nxt.append((cx, yy))
        if g[y][x] == "=":
            yy = y + 1
            while yy < r.h - 1 and clear(g, x, yy) and g[yy][x] != "=":
                yy += 1
            if standable(g, x, yy):
                nxt.append((x, yy))
        # 상승 기류: 기류 기둥 안(또는 바로 옆)에서는 기류 꼭대기까지 솟아 그 근처에 내릴 수 있다
        for (x0, x1, yt, yb) in drafts:
            if x0 - 2 <= x <= x1 + 2 and yt - 2 <= y <= yb + 2:
                for tx in range(x0 - 8, x1 + 9):
                    for ty in range(yt - 3, yb + 1):
                        if standable(g, tx, ty):
                            nxt.append((tx, ty))
        # 점프 (불꽃 날개면 아래로 갈수록 활공으로 더 멀리: 떨어진 높이 1칸당 약 3칸)
        for dy in range(-12 if wings else -6, H + 1):
            wmax = max(3, 11 - max(dy, 0)) + (3 * max(-dy, 0) + 6 if wings else 0)
            for dx in range(-wmax, wmax + 1):
                tx, ty = x + dx, y - dy
                if (tx, ty) in seen or not standable(g, tx, ty):
                    continue
                top = min(y, ty) - 2 - (1 if dy > 0 else 0)
                ok = all(clear(g, x, yy) for yy in range(top, y - 1 + 1) if yy < y)
                if not ok:
                    continue
                step = 1 if dx >= 0 else -1
                for cx in range(x, tx + step, step):
                    if not (clear(g, cx, min(y, ty) - 1 - (1 if dy > 0 else 0)) and clear(g, cx, min(y, ty) - 2 - (1 if dy > 0 else 0))):
                        ok = False
                        break
                if ok and all(clear(g, tx, yy) for yy in range(top, ty)):
                    nxt.append((tx, ty))
        for n in nxt:
            if n not in seen:
                seen.add(n)
                stack.append(n)
    return seen


def points(r):
    out = []
    for e in r.ents:
        t = e["t"]
        if t == "exit":
            x = 1 if e["x"] == 0 else e["x"] - 1
            out.append(("exit:" + e["id"], (x, e["y"] + e["h"])))
        elif t in ("door", "save", "spawn") or (t == "pickup"):
            out.append((t + ":" + e.get("id", ""), (e["x"], e["y"])))
    return out


def check(r, modes=("1j", "dj", "fox", "all")):
    """도달 검사. 1j 한 번 점프 / dj 2단 점프 / fox 2단+여우창문 / all 모든 능력(2단+여우창문+불꽃 날개·상승 기류).
    2장부터의 방은 all에서 문제가 없어야 한다(그 장의 게이트는 대본·개체로 막는다)."""
    pts = points(r)
    starts = [p for p in pts if p[0].startswith(("exit", "door"))]
    if not starts:
        return []
    probs = []
    for mode in modes:
        dj = mode != "1j"
        REVEAL[0] = mode in ("fox", "all")
        g = r.g if not REVEAL[0] else [[("." if c == "I" else c) for c in row] for row in r.g]
        for name, st in starts:
            if not standable(g, *st):
                if mode == "fox":
                    probs.append(f"{name} at {st} not standable")
                continue
            got = reach(r, st, dj, wings=(mode == "all"))
            for n2, p2 in pts:
                if n2 == name:
                    continue
                near = any((p2[0] + d, p2[1]) in got for d in (-1, 0, 1))
                if not near and (mode in ("fox", "all") or n2.startswith(("exit", "door"))):
                    probs.append(f"[{mode}] {name} -/-> {n2} {p2}")
    REVEAL[0] = False
    return probs


# ─── 방 메타 색인 (game/world/rooms/_index.gd) ──────────
INDEX_FILE = "_index.gd"


def _index_rank(r):
    """색인 순서 = 지도 목록 순서: 1장(roomgen.py) → sys → ch2 → ch3 … (ChapterRegistry.EXTS와 같게 sys가 먼저)"""
    src = r.src.split(" ")[0]
    if src == "tools/roomgen.py":
        return (0, "")
    name = os.path.splitext(os.path.basename(src))[0]
    return (1, "") if name == "sys" else (2, name)


def _vec(v):
    return "Vector2i(%d, %d)" % (v[0], v[1])


def index_gd(rooms):
    """모든 방의 메타(제목·지역·지도 칸·기록 지점)를 한 파일로. 지도·미니맵이 방 스크립트를 통째로 읽지 않게"""
    lines = [
        "extends RefCounted",
        "## 자동 생성: tools/roomgen.py — 방 메타 색인 (RoomIndex가 읽는다). 직접 고치지 말 것.",
        "## 순서 = 지도 목록 순서. dev = 개발용 시험 방(ID가 dev_로 시작 — 지도 목록에서 뺀다).",
        "## saves = 기록 지점 개체 ID들(cond와 상관없이 전부 — 지도 화면의 기록 지점 표시).",
        "",
        "const ROOMS := {",
    ]
    for r in sorted(rooms, key=_index_rank):
        saves = [e.get("id", "save_%d" % i) for i, e in enumerate(r.ents) if e.get("t") == "save"]
        row = [
            '"title": ' + gd_val(r.title), '"area": ' + gd_val(r.area), '"theme": ' + gd_val(r.theme),
            '"music": ' + gd_val(r.music), '"cell": ' + _vec(r.cell), '"cells": ' + _vec(r.cells),
            '"dark": ' + gd_val(float(r.dark)), '"saves": ' + gd_val(saves), '"dev": ' + gd_val(r.id.startswith("dev_")),
            '"src": ' + gd_val(r.src),
        ]
        lines.append('\t"%s": {%s},' % (r.id, ", ".join(row)))
    lines.append("}")
    return "\n".join(lines) + "\n"


def write_index(rooms):
    path = os.path.join(OUT, INDEX_FILE)
    with open(path, "w", encoding="utf-8") as f:
        f.write(index_gd(rooms))
    print(f"wrote {path} ({len(rooms)} rooms)")


# ─── 방 데이터 검사 (python3 tools/roomgen.py validate) ─
GAME = os.path.join(ROOT, "game")


def _read(rel):
    with open(os.path.join(GAME, rel), encoding="utf-8") as f:
        return f.read()


def _block(src, start_pat):
    """start_pat로 시작하는 줄부터 다음 맨 앞 줄(들여쓰기 없는 줄)까지"""
    m = re.search(start_pat, src, re.M)
    if not m:
        return ""
    nl = src.find("\n", m.end())
    rest = src[nl + 1:] if nl >= 0 else ""
    end = re.search(r"^\S", rest, re.M)
    return rest[: end.start()] if end else rest


def _keys(block, indent):
    """사전 블록에서 indent 탭 들여쓴 "키": 줄의 키들 (한 줄에 "a", "b": 처럼 여러 개도)"""
    out = []
    for m in re.finditer(r'^\t{%d}((?:"[\w]+"(?:, )?)+):' % indent, block, re.M):
        out += re.findall(r'"([\w]+)"', m.group(1))
    return out


def _glob_rel(pattern):
    return sorted(os.path.relpath(p, GAME) for p in glob.glob(os.path.join(GAME, pattern)))


def game_kinds():
    """게임 코드에서 개체 종류·적·소품·인물 이름 목록을 읽어 온다 (정규식 — 코드 모양이 바뀌면 여기도)"""
    room_src = _read("world/room.gd")
    ents = set(_keys(_block(room_src, r"^func _spawn_entity"), 2))
    for rel in ["world/world_entities.gd"] + _glob_rel("world/entities/*/entities.gd"):
        ents |= set(_keys(_block(_read(rel), r"^const KINDS"), 1))
    enemies = set()
    for rel in ["enemies/enemy_registry.gd"] + _glob_rel("enemies/*/registry.gd"):
        enemies |= set(_keys(_block(_read(rel), r"^const KINDS"), 1))
    props, prop_draw, prop_dup = {}, {}, []
    for rel in ["world/entities/base_props.gd"] + _glob_rel("world/entities/*/props.gd"):
        src = _read(rel)
        for k in _keys(_block(src, r"^const PROPS"), 1):
            if k in props:
                prop_dup.append(f"{k} ({props[k]}, {rel})")  # Prop은 앞 모듈 것만 씀
            props.setdefault(k, rel)
        for k in _keys(_block(src, r"^static func draw\("), 2):
            prop_draw[k] = rel
    who = set(_keys(_block(_read("story/characters.gd"), r"^const DB"), 1))
    for rel in _glob_rel("story/data_*.gd"):
        who |= set(_keys(_block(_read(rel), r"^const CHARACTERS"), 1))
    return ents, enemies, props, prop_draw, prop_dup, who


STAND = ("npc", "save", "door")  # 바닥 위에 서야 하는 개체
RECT_T = ("exit", "gate", "trigger", "updraft")  # x·y·w·h 영역 개체


def validate():
    """개체 종류·적 kind·소품 kind·인물(who)·출구/문 연결과 왕복·좌표 범위·서 있는 개체의 바닥을 검사한다.
    문제(ERR)가 있으면 종료 코드 1. 참고(NOTE)는 일부러 그런 경우가 있어 목록만 보여 준다. 대본 ID는 story_lint가 본다."""
    ents, enemies, props, prop_draw, prop_dup, who = game_kinds()
    rooms = {n: build(n) for n in ROOMS}
    errs, notes = [], []
    for d in prop_dup:
        errs.append(f"(소품 표) 같은 kind가 두 모듈에: {d}")
    for k, rel in sorted(props.items()):
        if k not in prop_draw:
            errs.append(f"(소품 표) {rel}: {k} 가 PROPS에는 있고 draw()에는 없음")
    for k, rel in sorted(prop_draw.items()):
        if k not in props:
            errs.append(f"(소품 표) {rel}: {k} 가 draw()에는 있고 PROPS에는 없음")
    for n, r in rooms.items():
        ids = {}
        for e in r.ents:
            if "id" in e:
                if e["id"] in ids and e["t"] not in ("spawn",):
                    notes.append(f"{n}: 개체 ID 중복 {e['id']} ({ids[e['id']]}, {e['t']})")
                ids.setdefault(e["id"], e["t"])
        for e in r.ents:
            t = e["t"]
            tag = f"{n}: {t} {e.get('id', e.get('kind', ''))}"
            if t not in ents:
                errs.append(f"{tag}: 개체 종류 없음")
            if t == "enemy" and e.get("kind", "charger") not in enemies:
                errs.append(f"{tag}: 적 kind 없음 ({e.get('kind')})")
            if t == "prop" and e.get("kind", "") not in props:
                errs.append(f"{tag}: 소품 kind 없음")
            if t == "npc" and e.get("who", e.get("id")) not in who:
                errs.append(f"{tag}: 인물(who) 없음 ({e.get('who')})")
            if t in ("exit", "door"):
                to, to_id = e.get("to", ""), e.get("to_id", "")
                if to not in rooms:
                    errs.append(f"{tag}: 가는 방 없음 ({to})")
                else:
                    back = [b for b in rooms[to].ents if b.get("id") == to_id and b["t"] in ("exit", "door", "spawn", "save")]
                    if not back:
                        errs.append(f"{tag}: {to}에 도착 지점 {to_id} 없음 (방 왼쪽 바닥으로 떨어짐)")
                    elif back[0]["t"] in ("exit", "door") and back[0].get("to") != n:
                        notes.append(f"{tag} → {to}.{to_id}: 돌아오는 길이 다른 방({back[0].get('to')})으로")
            if "x" in e and "y" in e:
                x, y = e["x"], e["y"]
                w = e.get("w", 1) if t in RECT_T else 1
                h = e.get("h", 1) if t in RECT_T else 0
                if x < 0 or y < 0 or x + w > r.w or y + h > r.h:
                    notes.append(f"{tag}: 방 범위 밖 ({x}, {y}) 방 {r.w}x{r.h}")
                elif t in STAND and isinstance(x, int) and isinstance(y, int) and not e.get("cond", "").startswith("never"):
                    if not (0 < y < r.h) or r.g[y][x] not in "#=IWH" or r.g[y - 1][x] in "#IW":
                        notes.append(f"{tag}: 바닥 위가 아님 ({x}, {y})")
    for m in errs:
        print("ERR ", m)
    for m in notes:
        print("NOTE", m)
    print(f"validate: rooms {len(rooms)}, ERR {len(errs)}, NOTE {len(notes)}")
    return 1 if errs else 0


def main():
    load_modules()
    args = sys.argv[1:]
    if args[:1] == ["validate"]:
        sys.exit(validate())
    if args[:1] == ["check"]:
        # check            모든 방(모든 모드)
        # check all k_     ID가 k_로 시작하는 방만, all 모드만
        modes = ("1j", "dj", "fox", "all")
        prefix = ""
        if len(args) >= 2:
            modes = tuple(args[1].split(","))
        if len(args) >= 3:
            prefix = args[2]
        for n in ROOMS:
            if prefix and not n.startswith(prefix):
                continue
            r = build(n)
            for p in check(r, modes):
                print(n, p)
        return
    os.makedirs(OUT, exist_ok=True)
    names = args or list(ROOMS)
    built = {}
    for n in names:
        r = build(n)
        built[n] = r
        path = os.path.join(OUT, r.id + ".gd")
        with open(path, "w", encoding="utf-8") as f:
            f.write(r.to_gd())
        print(f"wrote {path} ({r.w}x{r.h})")
    # 색인은 언제나 모든 방으로 (한 방만 다시 만들어도 맞게)
    write_index([built[n] if n in built else build(n) for n in ROOMS])


if __name__ == "__main__":
    main()
