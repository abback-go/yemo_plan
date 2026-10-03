#!/usr/bin/env python3
"""방 데이터 생성기 (docs/chapter1.md 5절).

방 지형을 사각형 명령으로 그려 ASCII 지도를 만들고, 개체 목록과 함께
game/world/rooms/<id>.gd (RoomData 상속) 파일로 써 낸다.
    python3 tools/roomgen.py          # 모든 방 다시 만들기
    python3 tools/roomgen.py s_hall   # 한 방만

좌표: x는 왼쪽→오른쪽, y는 위→아래 (타일). 화면 1칸 = 40×23타일.
지형 문자: # 벽  = 통과 발판  ^ 가시  I 환영 벽  H 숨은 발판  W 부서지는 벽  . 빈칸
개체의 y는 '발이 닿는 바닥 타일의 행'(바닥 윗면).
"""
import os
import sys

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
        for e in self.ents:
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


def room(fn):
    ROOMS[fn.__name__] = fn
    return fn


# ═══════════════════════════════════════════════════════════
# 신계 (프롤로그)
# ═══════════════════════════════════════════════════════════

@room
def t_pass():
    r = Room("t_pass", "신계 · 여우고개", "shingye", "shingye", "shingye", (0, 0), (2, 1))
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

def main():
    os.makedirs(OUT, exist_ok=True)
    names = sys.argv[1:] or list(ROOMS)
    for n in names:
        r = ROOMS[n]()
        path = os.path.join(OUT, r.id + ".gd")
        with open(path, "w", encoding="utf-8") as f:
            f.write(r.to_gd())
        print(f"wrote {path} ({r.w}x{r.h})")


if __name__ == "__main__":
    main()
