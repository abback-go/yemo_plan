#!/usr/bin/env python3
"""대본·진행 데이터 검사 (docs/dev/story.md "story_lint").

저장소 루트에서:  python3 tools/story_lint.py [--flags] [--quiet]
  오류(ERROR) — 있으면 종료 코드 1:
    · 대본 ID가 두 파일에 있음 (Story는 앞 파일을 쓰고 오류를 남긴다)
    · data_<장>.gd SCRIPTS의 파일이 없음 / story 폴더에 있는데 SCRIPTS에 없는 대본 파일
    · 없는 대본 ID를 부름: 방의 run=/talk=, 퀘스트 talk 훅, ch<N>_start(다음 장), 코드의 Story.run("…")·
      Story.has_script("…")·c.call_script("…"), 시험 시나리오의 run
  경고(WARN):
    · 기본 대화 npc_<who>(또는 npc_<who>_ch<N>)가 없는 인물, 없는 방의 enter_<방>, 수업 cls_<마법>_begin 없음,
      blight_vine의 first/hint 대본 없음
    · (--flags) 읽기만 하고 어디서도 세우지 않는 플래그 / 세우기만 하고 아무도 읽지 않는 플래그
      — 정규식 추정이라 오탐이 있다. 확인한 것은 아래 ALLOW_* 목록에 이유와 함께 넣는다.
파이썬 표준 라이브러리만 쓴다. 대본 파일은 GDScript 그대로 정규식으로 읽는다(실행하지 않음).
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GAME = os.path.join(ROOT, 'game')

# 이름 규칙으로 자동으로 생기는 플래그 (세우는 곳을 찾지 않음): docs/dev/story.md "플래그 이름 규칙"
AUTO_FLAG = re.compile(r'^(trig_|evt_|teach_|q_|ab_|lv_|eq_|mana_|warp_|temp_|seen_|pure_|seal_|ch\d+_done$|chapter$|tails$)')

# 방 개체 중 flag 칸을 "기다리기만" 하는 종류 (세우지 않음)
WATCH_FLAG_KINDS = {'event', 'tp_ally'}

# 확인한 오탐: 읽기만 하는 것처럼 보이지만 괜찮은 플래그 (이유)
ALLOW_UNSET = {
    'ch5_after': '마지막 목표 줄 — 일부러 끝나지 않는다 (data_ch5.gd OBJECTIVES)',
    'never_open': '열리지 않는 문 (t_trial 방)',
    'tp_never': '추격자를 대본이 직접 출발시킴 — 시작 플래그는 일부러 없음 (tp_sanctum)',
    'dev_arch': '시험용 방(dev_e_border) 조건',
    'st_comm_e': 'ch5 _comm(c, "st_comm_e", …)이 변수로 세움',
    'st_comm_k': 'ch5 _comm(c, "st_comm_k", …)이 변수로 세움',
    'tp_trial_mirror': 'ch4 _trial_done(c, key, …)이 변수로 세움',
    'tp_trial_bell': 'ch4 _trial_done(c, key, …)이 변수로 세움',
    'tp_trial_archive': 'ch4 _trial_done(c, key, …)이 변수로 세움',
}
# 확인한 오탐: 세우기만 하는 것처럼 보이지만 괜찮은 플래그 (이유)
ALLOW_UNREAD = {
    'tp_leonie_on': '방 개체 tp_ally(ally_keeper.gd)가 기본값으로 읽음',
}


def rd(path):
    with open(path, encoding='utf-8') as f:
        return f.read()


def rel(path):
    return os.path.relpath(path, ROOT)


def res_to_path(res):
    return os.path.join(GAME, res[len('res://'):])


def strip_comments(code):
    """# 주석 지우기 (문자열 안의 #은 남김)."""
    out = []
    for line in code.split('\n'):
        q = None
        cut = len(line)
        i = 0
        while i < len(line):
            ch = line[i]
            if q:
                if ch == '\\':
                    i += 2
                    continue
                if ch == q:
                    q = None
            elif ch in '"\'':
                q = ch
            elif ch == '#':
                cut = i
                break
            i += 1
        out.append(line[:cut])
    return '\n'.join(out)


def cond_flags(expr):
    """Cond 식 → 플래그 이름들 (core/cond.gd 문법: 쉼표 = 그리고, ! = 아님, mana>=N)."""
    out = []
    for tok in expr.split(','):
        t = tok.strip().lstrip('!')
        if t and not t.startswith('mana>='):
            out.append(t)
    return out


def lit_pattern(lit):
    """"ch%d_done" 같은 서식 문자열 → 정규식 (%d·%s 자리 아무 낱말)."""
    return re.compile('^' + re.sub(r'%[ds]', r'\\w+', re.escape(lit).replace(r'\%', '%')) + '$')


class Lint:
    def __init__(self):
        self.errors = []
        self.warns = []

    def err(self, msg):
        self.errors.append(msg)

    def warn(self, msg):
        self.warns.append(msg)

    # ─── 확장(장) 목록·data 파일 ─────────────────────────
    def load_exts(self):
        reg = rd(os.path.join(GAME, 'core/chapter_registry.gd'))
        m = re.search(r'const EXTS := \[([^\]]*)\]', reg)
        self.exts = re.findall(r'"(\w+)"', m.group(1))
        self.data = {}
        for ext in self.exts:
            p = os.path.join(GAME, 'story/data_%s.gd' % ext)
            if os.path.exists(p):
                self.data[ext] = strip_comments(rd(p))

    def const_block(self, text, name):
        m = re.search(r'^const %s := ([\[{])' % name, text, re.M)
        if not m:
            return ''
        close = ']' if m.group(1) == '[' else '}'
        end = re.compile(r'^\%s$' % close, re.M).search(text, m.end())
        if end is None:  # 한 줄짜리
            line_end = text.index('\n', m.start())
            return text[m.start():line_end]
        return text[m.start():end.end()]

    # ─── 대본 파일·ID ────────────────────────────────────
    def load_scripts(self):
        self.ids = {}  # id -> 파일
        self.script_files = []
        for ext in self.exts:
            block = self.const_block(self.data.get(ext, ''), 'SCRIPTS')
            for res in re.findall(r'"(res://[^"]+)"', block):
                p = res_to_path(res)
                if not os.path.exists(p):
                    self.err('data_%s.gd SCRIPTS: 파일 없음 %s' % (ext, res))
                    continue
                self.script_files.append(p)
                for name in re.findall(r'^func ([a-zA-Z]\w*)\(', rd(p), re.M):
                    if name in self.ids:
                        self.err('대본 ID 중복: %s — %s 와 %s (앞 파일이 이김)' % (name, rel(self.ids[name]), rel(p)))
                    else:
                        self.ids[name] = p
        # 목록에 없는 대본 파일 (common.gd는 도우미라 제외)
        listed = set(os.path.abspath(p) for p in self.script_files)
        for p in glob.glob(os.path.join(GAME, 'story/*/*.gd')):
            if os.path.basename(p) == 'common.gd' or os.path.abspath(p) in listed:
                continue
            if re.search(r'^func [a-zA-Z]\w*\(c: Cut\)', rd(p), re.M):
                self.err('%s: 대본이 있는데 어느 data_<장>.gd SCRIPTS에도 없음 (Story가 읽지 않음)' % rel(p))

    def need(self, sid, where, warn=False):
        if sid in self.ids:
            return
        (self.warn if warn else self.err)('없는 대본 ID "%s" — %s' % (sid, where))

    # ─── 방 ─────────────────────────────────────────────
    def load_rooms(self):
        self.rooms = {}
        for p in sorted(glob.glob(os.path.join(GAME, 'world/rooms/*.gd'))):
            t = rd(p)
            m = re.search(r'^\tid = "([^"]+)"', t, re.M)
            if not m:
                continue
            ents = []
            for line in t.split('\n'):
                if '{t = "' not in line:
                    continue
                d = dict(re.findall(r'\b(\w+) = "([^"]*)"', line))
                arrs = {k: re.findall(r'"([^"]*)"', v) for k, v in re.findall(r'\b(\w+) = \[([^\]]*)\]', line)}
                ents.append((d, arrs))
            self.rooms[m.group(1)] = (p, ents)

    def check_rooms(self):
        has_npc = set()
        for rid, (p, ents) in self.rooms.items():
            for d, _a in ents:
                t = d.get('t', '')
                where = '방 %s (%s)' % (rid, rel(p))
                for key in ('run', 'talk'):
                    if d.get(key):
                        self.need(d[key], '%s %s %s=' % (where, t, key))
                if t == 'npc' and not d.get('talk'):
                    has_npc.add(d.get('who', d.get('id', '')))
                if t == 'blight_vine':
                    for key in ('first', 'hint'):
                        if d.get(key):
                            self.need(d[key], '%s blight_vine %s=' % (where, key), warn=True)
        for who in sorted(has_npc):
            if 'npc_' + who in self.ids or any(k.startswith('npc_%s_ch' % who) for k in self.ids):
                continue
            self.warn('인물 %s: 기본 대화 npc_%s(또는 npc_%s_ch<N>)가 없음 — 말을 걸면 아무 일도 없다' % (who, who, who))
        for sid, p in sorted(self.ids.items()):
            if sid.startswith('enter_') and sid[6:] not in self.rooms:
                self.warn('%s: 방 %s가 없어 불리지 않음 (%s)' % (sid, sid[6:], rel(p)))

    # ─── data: 장·퀘스트 ─────────────────────────────────
    def check_data(self):
        chapters = []
        for ext, t in self.data.items():
            block = self.const_block(t, 'CHAPTER')
            m = re.search(r'"n": (\d+)', block)
            if m:
                chapters.append((int(m.group(1)), ext))
            qb = self.const_block(t, 'QUESTS')
            for qm in re.finditer(r'^\t"(\w+)": \{(.*?)^\t\},?$', qb, re.M | re.S):
                qid, body = qm.group(1), qm.group(2)
                for step, who, sid in re.findall(r'\[(\d+), "(\w+)", "(\w+)"\]', body):
                    self.need(sid, 'data_%s.gd 퀘스트 %s talk[%s, %s]' % (ext, qid, step, who))
                if re.search(r'"kind": "class"', body):
                    sp = re.search(r'"spell": "(\w+)"', body)
                    if sp:
                        self.need('cls_%s_begin' % sp.group(1), 'data_%s.gd 수업 %s (게시판 신청)' % (ext, qid), warn=True)
        chapters.sort()
        for n, ext in chapters[1:]:
            self.need('ch%d_start' % n, 'data_%s.gd CHAPTER n=%d (ChapterFlow.finish가 부름)' % (ext, n))
        self.chapter_ns = {n for n, _e in chapters}
        for sid, p in sorted(self.ids.items()):
            m = re.match(r'npc_\w+_ch(\d+)$', sid)
            if m and int(m.group(1)) not in self.chapter_ns:
                self.warn('%s: %s장이 없어 쓰이지 않음 (%s)' % (sid, m.group(1), rel(p)))

    # ─── 코드·시나리오의 대본 ID 문자열 ───────────────────
    def check_code_refs(self):
        for p in glob.glob(os.path.join(GAME, '**/*.gd'), recursive=True):
            if '/.godot/' in p or '/world/rooms/' in p:
                continue
            code = strip_comments(rd(p))
            for m in re.finditer(r'(Story\.run|Story\.has_script|call_script)\("([^"%]+)"\s*[,)]', code):
                self.need(m.group(2), '%s %s' % (rel(p), m.group(1)))
        for p in sorted(glob.glob(os.path.join(ROOT, 'tools/test/scenarios/*.json'))):
            try:
                steps = json.loads(rd(p)).get('steps', [])
            except ValueError as e:
                self.err('%s: JSON 오류 %s' % (rel(p), e))
                continue
            for s in steps:
                if isinstance(s, list) and len(s) >= 3 and s[1] == 'run':
                    self.need(str(s[2]), '시나리오 %s' % rel(p))

    # ─── 플래그 (추정) ───────────────────────────────────
    def check_flags(self):
        sets, reads = {}, {}
        set_pats, read_pats = [], []
        story_consts, counted = {}, set()

        def add(dct, name, where):
            dct.setdefault(name, where)

        for p in glob.glob(os.path.join(GAME, '**/*.gd'), recursive=True):
            if '/.godot/' in p or '/world/rooms/' in p:
                continue
            code = strip_comments(rd(p))
            w = rel(p)
            for m in re.finditer(r'(?:\bc\.flag|set_flag)\("([^"]+)"(\s*[%+])?', code):
                if m.group(2):
                    set_pats.append(lit_pattern(m.group(1)) if '%' in m.group(1) else re.compile('^' + re.escape(m.group(1))))
                else:
                    add(sets, m.group(1), w)
            for m in re.finditer(r'(?:\bc\.has|has_flag|GameState\.flag)\("([^"]+)"(\s*[%+])?', code):
                if m.group(2):
                    read_pats.append(lit_pattern(m.group(1)) if '%' in m.group(1) else re.compile('^' + re.escape(m.group(1))))
                else:
                    add(reads, m.group(1), w)
            for m in re.finditer(r'(?:Cond\.ok|cond_ok)\("([^"]*)"\)', code):
                for f in cond_flags(m.group(1)):
                    add(reads, f, w)
            # Cut.count([...]) 안의 문자열, Cut.count(상수)의 상수 목록은 읽기로 본다
            for m in re.finditer(r'Cut\.count\(\[([^\]]*)\]', code):
                for f in re.findall(r'"([a-z]\w*)"', m.group(1)):
                    add(reads, f, w)
            if '/story/' in p:
                for m in re.finditer(r'^const (\w+)(?:: Array\[String\])? := \[([^\]]*)\]', code, re.M):
                    story_consts[m.group(1)] = (re.findall(r'"([a-z]\w*)"', m.group(2)), w)
                counted.update(re.findall(r'Cut\.count\(([A-Z_]+)\)', code))
        for name in counted:
            for f in story_consts.get(name, ([], ''))[0]:
                add(reads, f, story_consts[name][1])
        for ext, t in self.data.items():
            w = 'data_%s.gd' % ext
            for done, req in re.findall(r'\["(\w*)", "[^"]*", "([^"]*)"\]', self.const_block(t, 'OBJECTIVES')):
                add(reads, done, w)
                for f in cond_flags(req):
                    add(reads, f, w)
            for key in ('need', 'unlock'):
                for v in re.findall(r'"%s": "([^"]*)"' % key, t):
                    for f in cond_flags(v):
                        add(reads, f, w)
            for v in re.findall(r'"warps": \[(.*?)\]\],', t, re.S):
                for f in re.findall(r'"(warp_\w+)"', v):
                    add(reads, f, w)
        cond_keys = {'cond', 'open_if', 'on_if', 'lock', 'active_if', 'lit_if', 'done_if', 'need', 'low_if'}
        flag_keys = {'flag', 'done', 'done_flag', 'fix_flag', 'alarm_flag', 'start_flag', 'free_flag', 'seen', 'first'}
        for rid, (p, ents) in self.rooms.items():
            w = rel(p)
            for d, arrs in ents:
                for k, v in d.items():
                    if k in cond_keys:
                        for f in cond_flags(v):
                            add(reads, f, w)
                    elif k in flag_keys and not (d.get('t') == 'blight_vine' and k == 'first') and v and ' ' not in v:
                        if (d.get('t') in WATCH_FLAG_KINDS and k == 'flag') or k == 'start_flag':
                            add(reads, v, w)  # 이 플래그가 서기를 기다리기만 함 (flag_event·tp_ally·추격 시작)
                            continue
                        # 그 밖의 방 개체는 자기 플래그를 세우고(줍기·장치 완료) 다시 읽어 상태를 되살린다 — 둘 다로 본다
                        add(sets, v, w)
                        add(reads, v, w)
                for f in arrs.get('flags', []):
                    add(reads, f, w)

        def is_set(f):
            return f in sets or any(pt.match(f) for pt in set_pats)

        def is_read(f):
            return f in reads or any(pt.match(f) for pt in read_pats)

        for f, w in sorted(reads.items()):
            if AUTO_FLAG.match(f) or f in ALLOW_UNSET or is_set(f):
                continue
            self.warn('플래그 "%s": 읽기만 하고 세우는 곳이 없음 (%s)' % (f, w))
        for f, w in sorted(sets.items()):
            if AUTO_FLAG.match(f) or f in ALLOW_UNREAD or is_read(f):
                continue
            self.warn('플래그 "%s": 세우기만 하고 읽는 곳이 없음 (%s)' % (f, w))

    def run(self, flags):
        self.load_exts()
        self.load_scripts()
        self.load_rooms()
        self.check_rooms()
        self.check_data()
        self.check_code_refs()
        if flags:
            self.check_flags()


def main():
    flags = '--flags' in sys.argv
    quiet = '--quiet' in sys.argv
    lint = Lint()
    lint.run(flags)
    for e in lint.errors:
        print('ERROR', e)
    if not quiet:
        for w in lint.warns:
            print('WARN ', w)
    print('story_lint: 대본 ID %d개 · 파일 %d개 · 방 %d개 — 오류 %d, 경고 %d%s' % (
        len(lint.ids), len(lint.script_files), len(lint.rooms), len(lint.errors), len(lint.warns),
        '' if flags else ' (플래그 검사는 --flags)'))
    sys.exit(1 if lint.errors else 0)


if __name__ == '__main__':
    main()
