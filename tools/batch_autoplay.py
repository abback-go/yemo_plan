#!/usr/bin/env python3
"""batch_autoplay.py — 헤드리스 자동 진행을 경로·시드를 바꿔 여러 판 병렬로 돌리고, 전투별 표를 만든다.
(밤샘 계획 2 — 결과 보고서는 docs/balance-report.md)

  # 경로 전부(CI 6경로 + 방 조합 4개) × 시드 1~20, 3개씩 동시에
  python3 tools/batch_autoplay.py --godot ~/godot/godot --seeds 1-20 --jobs 3 --out /tmp/batch
  # 경로·시드 골라서 (같은 시드는 같은 결과 — 재현 확인)
  python3 tools/batch_autoplay.py --godot ~/godot/godot --paths ci2 --seeds 7,7 --out /tmp/batch_re
  # 이미 돌린 로그로 표만 다시
  python3 tools/batch_autoplay.py --summary /tmp/batch

각 판: <out>/<경로>_s<시드>.log(--trace 기록) + <out>/runs.jsonl 한 줄.
찾는 것: 시간 초과(멈춤·무한 루프), SCRIPT ERROR·ERROR, 결과 요약(] result)에 닿지 못함.
전투 기록은 ctl.gd 의 「battle end enc=… result=… turn=… deck=… witch=hp/max 동료=hp/max:상태」 줄을 읽는다.
"""
import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# CI(.github/workflows/witch-web-build.yml)와 같은 6경로 + 방 조합을 바꾼 경로
PATHS = {
    "ci1": "--scene=camp --rooms=prayer,gravekeeper,buried,corpse,stall,chapel,training,footprints --choice=open,card --fates=defy,defy,defy",
    "ci2": "--scene=camp --rooms=prayer,buried,corpse,stall,chapel --choice=leave,candle --reward=skip --fates=accept,accept",
    "ci3": "--scene=camp --rooms=none --fates=defy,defy,offer",
    "ci4": "--scene=floor2 --fates=offer,offer",
    "ci5": "--scene=floor2 --fates=defy,defy,defy",
    "ci6": "--scene=giant --hp=warrior:3,archer:4 --fates=defy,defy,defy",   # 거대한 발 끝없는 전멸 되풀이 막힘(고침) 재현
    # 방 조합: 전투 많이(강적 포함·휴식 없음) / 강적+휴식 / 거래로 카드 사기+훈련 / 전조만
    "x1": "--scene=camp --rooms=prayer,gravekeeper,footprints --fates=defy,defy,defy",
    "x2": "--scene=camp --rooms=prayer,gravekeeper,chapel --choice=open --fates=accept,accept",
    "x3": "--scene=camp --rooms=stall,buried,training --choice=card,open --fates=defy,defy,offer",
    "x4": "--scene=camp --rooms=corpse,footprints,training --fates=offer,offer",
}

COMMON = "--autoguide --guides=reset --nosave --trace --quit-on-end --autoplay"
END_RE = re.compile(r"battle end enc=(\S+) result=(\S+) turn=(\d+) deck=(\d+) witch=(-?\d+)/(\d+)(.*)")
ALLY_RE = re.compile(r"(\w+)=(-?\d+)/(\d+):(\w+)")
ENC_NAMES = {"normal": "장례 회랑", "prayer": "기도실", "gravekeeper": "무덤지기", "deep": "가장 깊은 곳 광신도",
             "giant": "거대한 발", "ossuary": "납골당 창 기사", "pyre": "화형대 화형 사제"}
# 같은 시드면 같아야 하는 줄(카드·턴 종료·승패·고르기·얻기) — 시간 표시는 떼고 비교한다 (재현 확인)
SEQ_RE = re.compile(r"^\[[ \d.]+\] ((?:play|endTurn|win|wipe|battle|pick|picked|trade|train|fate pick|gain|card gain|enter|choice|newGame) .*)$")
ENC_ORDER = ["normal", "prayer", "gravekeeper", "deep", "giant", "ossuary", "pyre"]


def parse_seeds(s):
    out = []
    for part in s.split(","):
        if "-" in part:
            a, b = part.split("-")
            out.extend(range(int(a), int(b) + 1))
        elif part:
            out.append(int(part))
    return out


def parse_log(text):
    """로그 → 판 결과 (전투마다: 전멸 수, 마지막(이긴) 판의 턴·HP)"""
    battles = []
    pending = {}
    for line in text.splitlines():
        m = END_RE.search(line)
        if not m:
            continue
        enc, res, turn, deck, whp, wmax, rest = m.groups()
        allies = {a: {"hp": int(h), "max": int(mx), "status": stt} for a, h, mx, stt in ALLY_RE.findall(rest)}
        cur = pending.setdefault(enc, {"enc": enc, "wipes": 0, "wipe_turns": []})
        if res == "lose":
            cur["wipes"] += 1
            cur["wipe_turns"].append(int(turn))
            continue
        cur.update({"result": res, "turn": int(turn), "deck": int(deck), "witch": int(whp), "witchMax": int(wmax), "allies": allies})
        battles.append(cur)
        del pending[enc]
    for enc, cur in pending.items():   # 전멸만 하고 끝까지 못 이긴 전투
        cur["result"] = "unfinished"
        battles.append(cur)
    return battles


def run_one(godot, project, out, path, seed, speed, timeout, rep=0, extra=""):
    args = [godot, "--headless", "--path", project, "--", "--speed=%s" % speed] + COMMON.split() \
        + ["--seed=%d" % seed] + PATHS[path].split() + extra.split()
    log_path = os.path.join(out, "%s_s%d%s.log" % (path, seed, "_r%d" % rep if rep else ""))
    t0 = time.time()
    timed_out = False
    with open(log_path, "w") as f:
        try:
            rc = subprocess.run(args, stdout=f, stderr=subprocess.STDOUT, timeout=timeout).returncode
        except subprocess.TimeoutExpired:
            rc, timed_out = -9, True
    secs = time.time() - t0
    text = open(log_path, errors="replace").read()
    r = summarize_run(path, seed, rc, secs, timed_out, text)
    r["rep"] = rep
    return r


def summarize_run(path, seed, rc, secs, timed_out, text):
    errs = [l for l in text.splitlines() if "SCRIPT ERROR" in l or l.startswith("ERROR")]
    last = ""
    for l in text.splitlines():
        if l.startswith("["):
            last = l
    seq = [m.group(1) for m in map(SEQ_RE.match, text.splitlines()) if m]
    return {"path": path, "seed": seed, "rc": rc, "secs": round(secs, 1), "timeout": timed_out,
            "seq": hashlib.sha1("\n".join(seq).encode()).hexdigest()[:12], "nseq": len(seq),
            "result": "] result" in text, "errors": errs[:10], "nerrors": len(errs), "last": last[:200],
            "battles": parse_log(text)}


def fmt_hp(vals):
    if not vals:
        return "-"
    vals = sorted(vals)
    return "%.1f (%d~%d)" % (sum(vals) / len(vals), vals[0], vals[-1])


def report(runs, out=sys.stdout):
    p = lambda *a: print(*a, file=out)
    paths = sorted({r["path"] for r in runs}, key=lambda x: list(PATHS).index(x) if x in PATHS else 99)
    p("## 판 (경로별)\n")
    p("| 경로 | 판 | 결과 도달 | 시간 초과 | 에러 판 | 전멸(합) | 걸린 시간(초, 평균) |")
    p("|---|---|---|---|---|---|---|")
    for path in paths:
        rs = [r for r in runs if r["path"] == path]
        wipes = sum(b["wipes"] for r in rs for b in r["battles"])
        p("| %s | %d | %d | %d | %d | %d | %.0f |" % (path, len(rs), sum(r["result"] for r in rs), sum(r["timeout"] for r in rs),
                                                  sum(1 for r in rs if r["nerrors"]), wipes, sum(r["secs"] for r in rs) / len(rs)))
    p("\n## 전투별\n")
    p("| 전투 | 판 | 전멸 없이 이김 | 전멸(합) | 최다 전멸 | 노엘 HP 끝 | 세라피나 | 브룬힐드 | 엘리안 | 턴 | 덱 |")
    p("|---|---|---|---|---|---|---|---|---|---|---|")
    encs = [e for e in ENC_ORDER if any(b["enc"] == e for r in runs for b in r["battles"])]
    for enc in encs:
        bs = [b for r in runs for b in r["battles"] if b["enc"] == enc]
        done = [b for b in bs if b["result"] != "unfinished"]
        clean = sum(1 for b in done if b["wipes"] == 0)

        def ally_hp(aid):
            return [b["allies"][aid]["hp"] for b in done if aid in b.get("allies", {}) and b["allies"][aid]["status"] != "dead"]
        p("| %s | %d | %d (%.0f%%) | %d | %d | %s | %s | %s | %s | %s | %s |" % (
            ENC_NAMES.get(enc, enc), len(bs), clean, 100.0 * clean / max(1, len(bs)), sum(b["wipes"] for b in bs),
            max([b["wipes"] for b in bs] or [0]), fmt_hp([b["witch"] for b in done]),
            fmt_hp(ally_hp("hero")), fmt_hp(ally_hp("warrior")), fmt_hp(ally_hp("archer")),
            fmt_hp([b["turn"] for b in done]), fmt_hp([b["deck"] for b in done])))
    groups = {}
    for r in runs:
        groups.setdefault((r["path"], r["seed"]), []).append(r)
    reps = {k: v for k, v in groups.items() if len(v) > 1}
    if reps:
        same = sum(1 for v in reps.values() if len({r["seq"] for r in v}) == 1)
        p("\n## 재현 (같은 경로·시드를 여러 번)\n")
        p("- %d묶음 중 %d묶음이 카드·턴·승패 순서까지 같음" % (len(reps), same))
        for k, v in reps.items():
            if len({r["seq"] for r in v}) > 1:
                p("  - 다름: %s seed=%d %s" % (k[0], k[1], [r["seq"] for r in v]))
    bad = [r for r in runs if r["timeout"] or r["nerrors"] or not r["result"]]
    p("\n## 문제 판 (%d)\n" % len(bad))
    for r in bad:
        p("- %s seed=%d rc=%d timeout=%s result=%s errors=%d last=`%s`" % (r["path"], r["seed"], r["rc"], r["timeout"], r["result"], r["nerrors"], r["last"]))
        for e in r["errors"][:3]:
            p("  - `%s`" % e[:180])


def load_runs(dirs):
    """쉼표로 여러 폴더 — 같은 경로·시드가 여러 폴더에 있으면 재현 확인에 쓰인다"""
    runs = []
    for d in dirs.split(","):
        with open(os.path.join(d, "runs.jsonl")) as f:
            for line in f:
                if line.strip():
                    runs.append(json.loads(line))
    return runs


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--godot", default=os.environ.get("GODOT", "godot"))
    ap.add_argument("--paths", default=",".join(PATHS), help="쉼표로: " + ",".join(PATHS))
    ap.add_argument("--seeds", default="1-10", help="예: 1-40 또는 3,7,7")
    ap.add_argument("--speed", default="100", help="연출 속도 배율(--speed). 100 이면 헤드리스 한 판 약 10~20초")
    ap.add_argument("--jobs", type=int, default=3)
    ap.add_argument("--timeout", type=int, default=300, help="한 판 시간 초과(초) — 넘으면 멈춤으로 센다")
    ap.add_argument("--out", default="batch_out")
    ap.add_argument("--project", default=os.path.join(ROOT, "game"),
                    help="Godot 프로젝트 폴더(기본 game/). 도는 동안 코드를 고칠 거면 복사본을 가리킨다 — 판마다 시작할 때 스크립트를 읽는다")
    ap.add_argument("--extra", default="", help="모든 판에 더할 인자 (예: --ai=careful)")
    ap.add_argument("--summary", help="이미 돌린 폴더(쉼표로 여러 개)의 runs.jsonl 로 표만")
    a = ap.parse_args()
    if a.summary:
        report(load_runs(a.summary))
        return
    os.makedirs(a.out, exist_ok=True)
    jobs, seen = [], {}
    for s in parse_seeds(a.seeds):
        for path in a.paths.split(","):
            seen[(path, s)] = seen.get((path, s), -1) + 1   # 같은 시드를 다시 돌리면 로그 이름에 _r1, _r2 …
            jobs.append((path, s, seen[(path, s)]))
    runs = []
    jl = open(os.path.join(a.out, "runs.jsonl"), "a")
    t0 = time.time()
    with ThreadPoolExecutor(a.jobs) as ex:
        futs = [ex.submit(run_one, a.godot, a.project, a.out, path, s, a.speed, a.timeout, rep, a.extra) for path, s, rep in jobs]
        for i, fu in enumerate(futs):
            r = fu.result()
            runs.append(r)
            jl.write(json.dumps(r, ensure_ascii=False) + "\n")
            jl.flush()
            flag = "" if (r["result"] and not r["nerrors"] and not r["timeout"]) else "  <-- 문제"
            print("[%4.0fs] %d/%d %s seed=%d %.0fs result=%s wipes=%d%s" % (time.time() - t0, i + 1, len(jobs), r["path"], r["seed"], r["secs"],
                  r["result"], sum(b["wipes"] for b in r["battles"]), flag), flush=True)
    report(runs)


if __name__ == "__main__":
    main()
