#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
gen_music.py — 「마녀학교 × 여우신」 배경음악 / 징글 절차적 생성기 (1~5장)
=========================================================================

* 외부 샘플·다운로드 에셋·AI 오디오 서비스를 전혀 쓰지 않는다. 모든 소리는 이 파일 안의
  합성 코드(가산 합성, 파형표 톱니파, 1극 필터, Karplus-Strong 현 모델, 잡음 타악기,
  ADSR, 피드백 지연선 잔향)로 만들어진다.
* 파이썬 3 표준 라이브러리만 사용한다 (numpy 불필요).
* 고정 시드를 쓰므로 몇 번을 돌려도 같은 결과가 나온다(결정적).

사용법 (저장소 루트에서)::

    python3 tools/gen_music.py                 # 전체 33곡 생성 (1장 11곡 + 2~5장 22곡)
    python3 tools/gen_music.py --only title    # 특정 곡만
    python3 tools/gen_music.py --jobs 2        # 병렬 프로세스 수 지정
    python3 tools/gen_music.py --wav-dir /tmp/wav   # 중간 WAV 저장 위치

결과물: game/assets/music/<이름>.ogg  (ffmpeg + libvorbis 필요)

곡 목록 (곡마다 track_<이름>() / jingle_<이름>() 함수 하나)
-----------------------------------------------------------
* 1장   : title, shingye, shingye_tension, school, library, basement, boss, ending,
          jingle_ability, jingle_quest, jingle_save
* 2~5장 : school_day, kingdom, kingdom_night, knight_duel, starbeast, elf, elf_hunt, herald,
          temple, temple_dark, chase, aurelia, star_tower, lyra, despair, nine_tails, final,
          ending2, festival, jingle_spell, jingle_levelup, jingle_chapter
  곡끼리 주제 동기(학교·여우·제국·숲·신전·별)를 서로 인용한다 — '2~5장 곡들' 머리말 참고.

루프 곡 처리 방식
-----------------
1. (루프 길이 + 꼬리) 만큼 렌더링한다. 루프 길이는 항상 정수 마디.
2. 잔향/지연까지 모두 섞은 뒤, 꼬리 부분을 곡의 앞부분에 더해(wrap) 접는다.
   → 마지막 음의 잔향이 처음으로 자연스럽게 이어져 이음매 없이 반복된다.
3. 음표 시작 시각도 루프 길이로 나눈 나머지로 배치하므로, 못갖춘마디(앞당김음)도
   루프 끝에서 시작해 처음으로 넘어간다.
4. 최대 피크를 -1 dBFS 로 맞춘다(클리핑 없음).
"""

import argparse
import math
import os
import random
import re
import subprocess
import sys
import tempfile
import time
import wave
import zlib
from array import array

# ---------------------------------------------------------------------------
# 전역 설정
# ---------------------------------------------------------------------------
SR = 32000                       # 샘플레이트 (순수 파이썬 속도를 위해 32 kHz)
TWO_PI = 2.0 * math.pi
PEAK_DB = -1.0                   # 최종 피크 정규화 목표 (dBFS)
TAIL_SEC = 8.0                   # 루프 곡의 꼬리(잔향 감쇠) 렌더 길이

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(REPO, 'game', 'assets', 'music')


# ---------------------------------------------------------------------------
# 음 이름 ↔ MIDI ↔ 주파수
# ---------------------------------------------------------------------------
_NOTE_PC = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}


def midi(name):
    """'A4', 'C#5', 'Bb3' 같은 음 이름을 MIDI 번호로 바꾼다 (A4 = 69)."""
    m = re.match(r'^([A-G])([#b]?)(-?\d)$', name)
    if not m:
        raise ValueError('음 이름 오류: ' + name)
    pc = _NOTE_PC[m.group(1)] + {'': 0, '#': 1, 'b': -1}[m.group(2)]
    return 12 * (int(m.group(3)) + 1) + pc


def mtof(m):
    """MIDI 번호 → 주파수(Hz). 평균율, A4 = 440 Hz."""
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def notes(names):
    """공백으로 구분된 음 이름 문자열 → MIDI 리스트."""
    return [midi(x) for x in names.split()]


# ---------------------------------------------------------------------------
# 악보 파서
#   토큰 형식:  음이름[:길이][장식]   또는   r[:길이]  (쉼표)
#   길이는 'unit' 배수 (예: unit=1/3 이면 8분음표 단위로 적는 12/8 박자)
#   길이를 생략하면 직전 길이를 그대로 쓴다.
#   '|' 는 마디선 — bar 값을 주면 마디마다 길이 합을 검사해서 박자 오류를 잡는다.
#   장식(꾸밈) 기호:
#     v : 농현/비브라토      w : 깊은 떠는음(넓은 비브라토)
#     k : 꺾는음(반음 아래로 꺾임)   ^ : 추성(끝을 밀어 올림)   _ : 퇴성(끝을 흘려 내림)
#     s : 아래에서 미끄러져 들어감   ! : 강세   ? : 약하게
# ---------------------------------------------------------------------------
_TOK = re.compile(r'^(r|[A-G][#b]?-?\d)(?::([0-9./]+))?([vwk^_s!?]*)$')


def _frac(s):
    if '/' in s:
        a, b = s.split('/')
        return float(a) / float(b)
    return float(s)


def seq(text, unit=1.0, bar=None, offset=0.0):
    """악보 문자열 → [(시작 박, 길이 박, midi, 장식문자열), ...]"""
    events = []
    t = 0.0
    acc = 0.0
    bar_no = 1
    last = 1.0
    for tok in text.replace('|', ' | ').split():
        if tok == '|':
            if bar is not None and abs(acc - bar) > 1e-6:
                raise ValueError('%d번째 마디 길이 %.3f != %.3f : %s' % (bar_no, acc, bar, text[:60]))
            acc = 0.0
            bar_no += 1
            continue
        m = _TOK.match(tok)
        if not m:
            raise ValueError('토큰 오류: ' + tok)
        name, d, flags = m.groups()
        if d:
            last = _frac(d)
        if name != 'r':
            events.append((offset + t * unit, last * unit, midi(name), flags))
        t += last
        acc += last
    if bar is not None and acc > 1e-9 and abs(acc - bar) > 1e-6:
        raise ValueError('마지막 마디 길이 %.3f != %.3f : %s' % (acc, bar, text[:60]))
    return events


def ev_transpose(events, semi):
    return [(b, d, m + semi, f) for (b, d, m, f) in events]


def ev_map(events, src_tonic, dst_tonic, pc_map):
    """선법 변환: 원래 조의 음계 도수를 새 조의 같은 도수로 옮긴다.
    pc_map: 원래 조 기준 반음거리 → 새 조 기준 반음거리."""
    out = []
    for (b, d, m, f) in events:
        octv, pc = divmod(m - src_tonic, 12)
        out.append((b, d, dst_tonic + 12 * octv + pc_map[pc], f))
    return out


# ---------------------------------------------------------------------------
# 작은 DSP 도구들
# ---------------------------------------------------------------------------
TN = 4096                         # 파형표 길이 (2의 거듭제곱 → & 마스크로 빠른 순환)
TM = TN - 1
_SIN = [math.sin(TWO_PI * i / TN) for i in range(TN)]
_TABLES = {}


def smooth(u):
    """0~1 구간 부드러운 S자 곡선."""
    if u <= 0.0:
        return 0.0
    if u >= 1.0:
        return 1.0
    return u * u * (3.0 - 2.0 * u)


def make_table(amps):
    """배음 진폭 리스트로 한 주기 파형표를 만든다 (가산 합성)."""
    t = [0.0] * TN
    for k, a in enumerate(amps, 1):
        if abs(a) < 2e-4:
            continue
        t = [x + a * _SIN[(k * i) & TM] for i, x in enumerate(t)]
    pk = max(abs(x) for x in t) or 1.0
    return [x / pk for x in t]


# 오르간 배음별 세기 (배음 번호 → 진폭)
_ORGAN = {1: 1.0, 2: 0.6, 3: 0.32, 4: 0.36, 5: 0.1, 6: 0.16, 8: 0.14, 10: 0.04, 12: 0.05, 16: 0.03}
# 합창 모음 포먼트 (중심 주파수 Hz, 대역폭 Hz, 세기) — 혼성 합창 평균값에 가깝게
_VOWELS = {
    'a': [(780.0, 110.0, 1.0), (1150.0, 130.0, 0.55), (2800.0, 200.0, 0.2), (3600.0, 250.0, 0.08)],
    'o': [(470.0, 90.0, 1.0), (820.0, 110.0, 0.45), (2700.0, 200.0, 0.1)],
    'u': [(330.0, 80.0, 1.0), (750.0, 120.0, 0.18), (2500.0, 200.0, 0.05)],
}


def _spec(kind, f):
    """악기별 배음 스펙트럼. 기본 주파수 f 에 따라 고역을 제한해 거친 고음을 막는다."""
    lim = min(9000.0, 0.45 * SR)
    amps = []
    k = 1
    while k * f < lim:
        x = k * f
        if kind == 'saw':            # 따뜻한 톱니파 (현악 패드·베이스)
            a = (1.0 / k) / (1.0 + (x / 2600.0) ** 2)
        elif kind == 'saw_dark':     # 어두운 톱니파 (드론)
            a = (1.0 / k) / (1.0 + (x / 700.0) ** 2)
        elif kind == 'saw_bright':   # 보스 베이스용 (뒤에서 필터로 깎음)
            a = (1.0 / k) / (1.0 + (x / 6000.0) ** 2)
        elif kind == 'daegeum':      # 대금: 기음 + 적당한 배음 (취구 소리는 잡음으로 따로)
            base = [1.0, 0.42, 0.26, 0.15, 0.10, 0.06, 0.04, 0.025]
            a = base[k - 1] if k <= len(base) else 0.0
            a /= (1.0 + (x / 3800.0) ** 2)
        elif kind == 'clar':         # 클라리넷풍 목관: 홀수 배음 위주
            a = (1.0 / k) if k % 2 == 1 else (0.10 / k)
            a /= (1.0 + (x / 2800.0) ** 2)
        elif kind == 'sine':
            a = 1.0 if k == 1 else 0.0
        elif kind == 'brass':        # 금관: 톱니에 가까운 배음 + 1.2 kHz 근처 포먼트 (밝기는 필터 엔벨로프가 정함)
            a = (1.0 / k ** 0.8) * (1.0 + 2.0 * math.exp(-((x - 1300.0) / 900.0) ** 2)) / (1.0 + (x / 6500.0) ** 2)
        elif kind == 'flute':        # 플루트: 기음 위주, 2·3배음 조금 (숨소리는 잡음으로 따로)
            base = [1.0, 0.28, 0.11, 0.045, 0.02, 0.01]
            a = base[k - 1] if k <= len(base) else 0.0
            a /= (1.0 + (x / 4500.0) ** 2)
        elif kind == 'organ':        # 파이프 오르간: 8'·4'·2⅔'·2'·1⅗'·1⅓'·1' 스톱을 섞은 배음
            a = _ORGAN.get(k, 0.0) / (1.0 + (x / 5000.0) ** 2)
        elif kind.startswith('choir_'):   # 합창 '아·오·우': 성대 원음(배음이 점점 약해짐) × 모음 포먼트
            src = 1.0 / k ** 0.8
            env = sum(g / (1.0 + ((x - fc) / bw) ** 2) for fc, bw, g in _VOWELS[kind[6:]])
            a = src * (0.04 + env)
        else:
            raise ValueError(kind)
        amps.append(a)
        k += 1
    return amps


def get_table(kind, m):
    """(종류, MIDI) 별로 대역 제한 파형표를 캐시한다."""
    key = (kind, m)
    tab = _TABLES.get(key)
    if tab is None:
        tab = _SIN if kind == 'sine' else make_table(_spec(kind, mtof(m)))
        _TABLES[key] = tab
    return tab


def osc(table, freq, n, phase=0.0, pitch_fn=None, block=64):
    """파형표 발진기. pitch_fn(초)→반음 오프셋 을 주면 64샘플마다 음높이를 갱신."""
    p = phase * TN
    if pitch_fn is None:
        inc = freq * TN / SR
        return [table[int(p + inc * i) & TM] for i in range(n)]
    out = []
    i = 0
    while i < n:
        m = block if n - i > block else n - i
        inc = freq * 2.0 ** (pitch_fn(i / SR) / 12.0) * TN / SR
        out.extend([table[int(p + inc * j) & TM] for j in range(m)])
        p = (p + inc * m) % TN
        i += m
    return out


def adsr(n, a, d, s, r, gate):
    """ADSR 엔벨로프. a/d/r/gate 는 초, s 는 서스테인 레벨. 길이 n 리스트 반환."""
    A = max(1, int(a * SR))
    D = max(1, int(d * SR))
    G = max(0, min(n, int(gate * SR)))
    R = max(1, int(r * SR))
    env = [math.sin(0.5 * math.pi * i / A) for i in range(min(A, G))]
    if len(env) < G:
        nd = min(D, G - len(env))
        env.extend([s + (1.0 - s) * math.exp(-4.0 * i / D) for i in range(nd)])
    if len(env) < G:
        env.extend([s] * (G - len(env)))
    lvl = env[-1] if env else 0.0
    rest = n - len(env)
    if rest > 0:
        env.extend([lvl * (1.0 - i / R) ** 2 if i < R else 0.0 for i in range(rest)])
    return env


def fade_tail(sig, sec):
    """신호 끝을 sec 초 동안 부드럽게 줄인다(잘림 클릭 방지)."""
    n = len(sig)
    k = min(n, max(1, int(sec * SR)))
    s = n - k
    sig[s:] = [x * (0.5 + 0.5 * math.cos(math.pi * i / k)) for i, x in enumerate(sig[s:])]
    return sig


def bandnoise(n, lo, hi, rnd):
    """백색잡음 → 1극 저역통과(hi) → 1극 고역통과(lo) 로 만든 대역 잡음."""
    ah = 1.0 - math.exp(-TWO_PI * hi / SR)
    al = 1.0 - math.exp(-TWO_PI * lo / SR)
    y1 = y2 = 0.0
    out = [0.0] * n
    u = rnd.random
    for i in range(n):
        y1 += ah * (2.0 * u() - 1.0 - y1)
        y2 += al * (y1 - y2)
        out[i] = y1 - y2
    return out


_BREATH = None


def breath_noise():
    """관악기 숨소리용 대역 잡음 (프로세스당 한 번, 고정 시드)."""
    global _BREATH
    if _BREATH is None:
        b = bandnoise(SR * 3, 600.0, 3200.0, random.Random(4242))
        pk = max(abs(x) for x in b)
        _BREATH = [x / pk for x in b]
    return _BREATH


def onepole_lp(x, hz):
    a = 1.0 - math.exp(-TWO_PI * hz / SR)
    y = 0.0
    out = [0.0] * len(x)
    for i, v in enumerate(x):
        y += a * (v - y)
        out[i] = y
    return out


# ---------------------------------------------------------------------------
# 음높이 곡선 (국악 시김새 흉내)
# ---------------------------------------------------------------------------
def pitch_curve(flags, dur, style):
    """장식 기호 → (시간[초] → 반음 오프셋) 함수. style 'pluck'(가야금) / 'wind'(대금·목관)."""
    parts = []
    if 's' in flags:                       # 아래(온음)에서 미끄러져 들어가기
        T = 0.08 if style == 'pluck' else 0.14
        parts.append(lambda t, T=T: -2.0 * (1.0 - t / T) ** 2 if t < T else 0.0)
    if 'v' in flags or 'w' in flags:
        wide = 'w' in flags
        if style == 'pluck':
            # 가야금 농현: 줄을 눌러 음을 '위로' 흔든다 (0 → +depth 사이 진동)
            depth = 0.9 if wide else 0.5
            rate = 3.4 if wide else 4.4
            onset = min(0.22, dur * 0.3)
            parts.append(lambda t, d=depth, r=rate, o=onset:
                         0.0 if t < o else d * (0.5 - 0.5 * math.cos(TWO_PI * r * (t - o))) * min(1.0, (t - o) / 0.3))
        else:
            # 대금/목관: 늦게 시작해 점점 깊어지는 중심 비브라토
            depth = 0.42 if wide else 0.2
            rate = 4.3 if wide else 5.2
            onset = min(0.32, dur * 0.35)
            parts.append(lambda t, d=depth, r=rate, o=onset:
                         0.0 if t < o else d * math.sin(TWO_PI * r * (t - o)) * min(1.0, (t - o) / 0.6))
    if 'k' in flags:                       # 꺾는음: 살짝 밀었다가 반음 아래로 꺾음
        tk = min(0.16, dur * 0.35)

        def kf(t, tk=tk):
            if t < tk:
                return 0.0
            u = t - tk
            if u < 0.05:
                return 0.3 * u / 0.05
            if u < 0.15:
                return 0.3 - 1.3 * smooth((u - 0.05) / 0.1)
            return -1.0
        parts.append(kf)
    if '^' in flags:                       # 추성: 끝을 온음 위로 밀어 올림
        t0 = dur * 0.5
        T = max(0.12, dur * 0.3)
        parts.append(lambda t, t0=t0, T=T: 0.0 if t < t0 else 2.0 * smooth((t - t0) / T))
    if '_' in flags:                       # 퇴성: 끝을 온음 아래로 흘림
        t0 = dur * 0.55
        T = max(0.15, dur * 0.35)
        parts.append(lambda t, t0=t0, T=T: 0.0 if t < t0 else -2.0 * smooth((t - t0) / T))
    if not parts:
        return None
    if len(parts) == 1:
        return parts[0]
    return lambda t: sum(p(t) for p in parts)


# ---------------------------------------------------------------------------
# 악기 1: Karplus-Strong 현 (가야금, 하프시코드, 피치카토, 하프)
# ---------------------------------------------------------------------------
def ks(freq, n, t60, bright=0.5, pick=0.2, loss=0.3, seed=1, pitch_fn=None, low_ratio=1.0):
    """Karplus-Strong 뜯는 현.
    - 지연선 길이 = 주기, 1극 저역통과 손실필터 + 감쇠 이득으로 '현'을 흉내낸다.
    - 손실필터의 위상지연을 계산해 빼 주므로 음정이 정확하다.
    - pitch_fn 이 있으면 지연 길이를 선형보간으로 연속 변화 → 농현/꺾는음/추성 표현.
    bright: 여기 잡음의 밝기(0~1), pick: 뜯는 위치(줄 길이 비율), loss: 손실필터 계수."""
    rnd = random.Random(seed)
    c = loss
    w = TWO_PI * freq / SR
    pd = math.atan2(c * math.sin(w), 1.0 - c * math.cos(w)) / w           # 위상지연(샘플)
    mag = (1.0 - c) / math.sqrt(1.0 - 2.0 * c * math.cos(w) + c * c)     # 기음에서의 손실
    g = min(0.99995, 10.0 ** (-3.0 / (t60 * freq)) / mag)                 # t60 에 맞춘 루프 이득
    period = SR / freq
    L = max(2, int(period))
    # 여기(勵起) 신호: 잡음 → 두 번 저역통과(손가락/깃 뜯음의 부드러움) → 뜯는 위치 빗살필터
    exc = [rnd.uniform(-1.0, 1.0) for _ in range(L)]
    for _ in range(2):
        y = 0.0
        for i in range(L):
            y += bright * (exc[i] - y)
            exc[i] = y
    P = max(1, int(pick * L))
    exc = [exc[i] - (exc[i - P] if i >= P else 0.0) for i in range(L)]
    mean = sum(exc) / L
    exc = [e - mean for e in exc]
    pk = max(abs(e) for e in exc) or 1.0
    exc = [e / pk for e in exc]
    # 순환 버퍼 (음높이를 내릴 때도 충분하도록 넉넉하게)
    need = period / low_ratio + 8
    N = 64
    while N < need:
        N <<= 1
    M = N - 1
    buf = [0.0] * N
    wi = 4 * N                                # 쓰기 위치 (항상 양수 유지)
    for k in range(L):
        buf[(wi - L + k) & M] = exc[k]
    out = [0.0] * n
    s = 0.0
    D = period - pd
    i = 0
    while i < n:
        m = 64 if n - i > 64 else n - i
        if pitch_fn is not None:
            D = SR / (freq * 2.0 ** (pitch_fn(i / SR) / 12.0)) - pd
        for j in range(i, i + m):
            r = wi - D
            ri = int(r)
            fr = r - ri
            a0 = buf[ri & M]
            v = a0 + fr * (buf[(ri + 1) & M] - a0)
            s = v + c * (s - v)
            y = s * g
            buf[wi & M] = y
            out[j] = y
            wi += 1
        i += m
    A = min(n, int(0.001 * SR))               # 1 ms 페이드인: 뜯는 순간의 '딸깍' 클릭 완화
    for j in range(A):
        out[j] *= j / A
    return out


def inst_gayageum(m, dur, flags, seed, ring=2.6, bright=0.5, gain_lo=1.0):
    """가야금풍: 따뜻한 명주실 뜯음 + 농현/꺾는음/추성/퇴성."""
    f = mtof(m)
    t60 = max(1.2, min(4.5, 3.0 * (220.0 / f) ** 0.4))
    n = int(min(t60, dur + ring) * SR)
    pf = pitch_curve(flags, dur, 'pluck')
    sig = ks(f, n, t60, bright=bright, pick=0.23, loss=0.34, seed=seed, pitch_fn=pf,
             low_ratio=2.0 ** (-2.5 / 12))
    return fade_tail(sig, 0.15)


def inst_harp(m, dur, flags, seed, ring=2.2):
    """부드러운 하프풍 뜯음 (자장가 반주용)."""
    f = mtof(m)
    t60 = max(1.0, min(3.5, 2.4 * (262.0 / f) ** 0.35))
    n = int(min(t60, dur + ring) * SR)
    sig = ks(f, n, t60, bright=0.42, pick=0.5, loss=0.4, seed=seed)
    return fade_tail(sig, 0.2)


def inst_harpsi(m, dur, flags, seed):
    """하프시코드풍: 밝은 뜯음 2줄(8'+8', 약간 어긋난 조율) + 건반을 놓으면 댐퍼로 멈춤."""
    f = mtof(m)
    t60 = max(0.8, min(3.0, 2.0 * (262.0 / f) ** 0.5))
    gate = dur
    n = int((gate + 0.09) * SR)
    a = ks(f, n, t60, bright=0.62, pick=0.12, loss=0.2, seed=seed)
    b = ks(f * 2.0 ** (4.0 / 1200), n, t60 * 0.9, bright=0.55, pick=0.17, loss=0.24, seed=seed + 7)
    sig = [0.6 * x + 0.4 * y for x, y in zip(a, b)]
    return fade_tail(sig, 0.09)


def inst_pizz(m, dur, flags, seed):
    """현악 피치카토 베이스: 어두운 KS + 기음 사인 몸통."""
    f = mtof(m)
    n = int(0.95 * SR)
    a = ks(f, n, 0.85, bright=0.3, pick=0.27, loss=0.55, seed=seed)
    w = TWO_PI * f / SR
    k = 1.0 / (0.22 * SR)
    sig = [x + 0.55 * math.exp(-k * i) * math.sin(w * i) for i, x in enumerate(a)]
    A = int(0.004 * SR)
    for i in range(A):
        sig[i] *= i / A
    return fade_tail(sig, 0.15)


# ---------------------------------------------------------------------------
# 악기 2: 가산 합성 타악 선율 (첼레스타, 오르골, 풍경, 종)
# ---------------------------------------------------------------------------
def partial_sum(freq, n, partials, attack=0.003, maxf=7000.0):
    """감쇠하는 사인 부분음들의 합. partials = [(주파수비, 진폭, t60초), ...]"""
    out = [0.0] * n
    for ratio, amp, t60 in partials:
        f = freq * ratio
        if f >= maxf or amp <= 0.0:
            continue
        m = min(n, int(t60 * SR))
        if m <= 0:
            continue
        w = TWO_PI * f / SR
        k = 6.9078 / (t60 * SR)              # ln(1000): t60 동안 -60 dB
        seg = [amp * math.exp(-k * i) * math.sin(w * i) for i in range(m)]
        out[:m] = [x + y for x, y in zip(out, seg)]
    A = max(1, int(attack * SR))
    for i in range(min(A, n)):
        out[i] *= i / A
    return out


def inst_celesta(m, dur, flags, seed):
    """첼레스타풍: 기음 위주, 옥타브 배음이 빨리 사라짐."""
    f = mtof(m)
    T = 2.6 * (440.0 / f) ** 0.35
    P = [(1.0, 1.0, T), (2.0, 0.22, T * 0.4), (3.0, 0.06, T * 0.18), (4.0, 0.03, T * 0.1)]
    return partial_sum(f, int(T * SR), P, attack=0.003)


def inst_musicbox(m, dur, flags, seed):
    """오르골풍: 빗살(외팔보) 진동의 비조화 배음(≈5.4배)이 살짝."""
    f = mtof(m)
    T = 2.2 * (440.0 / f) ** 0.3
    P = [(1.0, 1.0, T), (2.0, 0.10, T * 0.5), (5.4, 0.05, 0.09), (3.0, 0.03, T * 0.15)]
    return partial_sum(f, int(T * SR), P, attack=0.002)


def inst_chime(m, dur, flags, seed):
    """풍경(風磬)/등불 반짝임: 부드러운 금속 울림."""
    f = mtof(m)
    T = 3.2
    P = [(1.0, 1.0, T), (2.76, 0.16, 1.1), (5.4, 0.05, 0.3), (1.0 + 0.003, 0.5, T)]
    return partial_sum(f, int(T * SR), P, attack=0.006, maxf=6500.0)


# Risset 의 종소리 부분음표 (주파수비, 진폭, 길이비율, 주파수 오프셋 Hz)
_RISSET = [(0.56, 1.0, 1.0, 0.0), (0.56, 0.67, 0.9, 1.0), (0.92, 1.0, 0.65, 0.0), (0.92, 1.8, 0.55, 1.7),
           (1.19, 2.67, 0.325, 0.0), (1.70, 1.67, 0.35, 0.0), (2.00, 1.46, 0.25, 0.0), (2.74, 1.33, 0.2, 0.0),
           (3.00, 1.33, 0.15, 0.0), (3.76, 1.0, 0.1, 0.0), (4.07, 1.33, 0.075, 0.0)]


def inst_bell(m, dur, flags, seed, T=6.0, lp=1800.0):
    """멀리서 울리는 종 (Risset 종 모델 + 고역 감쇠로 '먼' 느낌)."""
    f = mtof(m)
    P = []
    for r, a, dr, off in _RISSET:
        fr = f * r + off
        P.append((fr / f, a / (1.0 + (fr / lp) ** 2), T * dr))
    sig = partial_sum(f, int(T * SR), P, attack=0.004, maxf=6000.0)
    pk = max(abs(x) for x in sig) or 1.0
    return [x / pk for x in sig]


# ---------------------------------------------------------------------------
# 악기 3: 관악 (대금, 목관), 패드, 드론, 유리 음
# ---------------------------------------------------------------------------
def inst_wind(m, dur, flags, seed, kind='daegeum', breath=0.09, attack=0.09, release=0.16,
              chiff=0.22, auto_vib=None):
    """관악기: 파형표 + 숨소리 잡음 + 시김새 음높이 곡선 + 비브라토에 맞춘 미세 음량 떨림."""
    if auto_vib is not None and dur >= auto_vib and not any(c in flags for c in 'vw'):
        flags = flags + 'v'
    f = mtof(m)
    n = int((dur + release + 0.04) * SR)
    rnd = random.Random(seed)
    pf = pitch_curve(flags, dur, 'wind')
    tone = osc(get_table(kind, m), f, n, phase=rnd.random(), pitch_fn=pf)
    env = adsr(n, attack, 0.25, 0.82, release, dur + 0.03)
    # 긴 음은 살짝 크레셴도 (대금의 숨을 밀어 넣는 느낌)
    dn = max(1.0, dur * SR)
    vib = ('v' in flags or 'w' in flags)
    vr = 4.3 if 'w' in flags else 5.2
    on = int(min(0.32, dur * 0.35) * SR)
    nz = breath_noise()
    off = rnd.randrange(len(nz) - 1)
    NL = len(nz)
    ck = 1.0 / (0.045 * SR)
    wv = TWO_PI * vr / SR
    out = [0.0] * n
    for i in range(n):
        e = env[i]
        amp = e * (0.88 + 0.12 * min(1.0, i / dn))
        if vib and i > on:
            amp *= 1.0 + 0.07 * math.sin(wv * (i - on))
        out[i] = tone[i] * amp + nz[(off + i) % NL] * e * (breath + chiff * math.exp(-ck * i))
    return out


def inst_pad(m, dur, flags, seed, kind='saw', attack=0.5, release=1.0, detune=7.0, voices=2):
    """현악/신스 패드: 대역제한 톱니파 여러 개를 약간씩 어긋나게 겹침."""
    f = mtof(m)
    n = int((dur + release) * SR)
    rnd = random.Random(seed)
    tab = get_table(kind, m)
    sig = None
    for v in range(voices):
        cents = 0.0 if voices == 1 else detune * (2.0 * v / (voices - 1) - 1.0)
        o = osc(tab, f * 2.0 ** (cents / 1200.0), n, phase=rnd.random())
        sig = o if sig is None else [a + b for a, b in zip(sig, o)]
    env = adsr(n, attack, 0.4, 0.9, release, dur)
    g = 1.0 / voices
    return [s * e * g for s, e in zip(sig, env)]


def inst_glass(m, dur, flags, seed, beat_hz=0.35):
    """유리처럼 맑은 사인 두 개의 느린 맥놀이 (지하실의 섬뜩함)."""
    f = mtof(m)
    n = int((dur + 2.5) * SR)
    w1 = TWO_PI * f / SR
    w2 = TWO_PI * (f + beat_hz) / SR
    env = adsr(n, 2.2, 0.5, 1.0, 2.5, dur)
    return [0.5 * (math.sin(w1 * i) + 0.6 * math.sin(w2 * i)) * e for i, e in enumerate(env)]


def inst_wind_noise(m, dur, flags, seed):
    """지하 통로의 바람 소리: 저역통과 잡음, 차단주파수가 천천히 움직임."""
    rnd = random.Random(seed)
    n = int(dur * SR)
    out = [0.0] * n
    y1 = y2 = 0.0
    u = rnd.random
    ph = rnd.random() * TWO_PI
    for i0 in range(0, n, 64):
        t = i0 / SR
        fc = 260.0 + 200.0 * math.sin(ph + TWO_PI * 0.11 * t)
        a = 1.0 - math.exp(-TWO_PI * fc / SR)
        e = math.sin(math.pi * t / dur) ** 2
        for i in range(i0, min(n, i0 + 64)):
            y1 += a * (2.0 * u() - 1.0 - y1)
            y2 += a * (y1 - y2)
            out[i] = y2 * e
    pk = max(abs(x) for x in out) or 1.0
    return [x / pk for x in out]


def inst_sawbass(m, dur, flags, seed, accent=1.0):
    """보스용 거친 톱니파 베이스: 2개 디튠 + 서브 사인, 필터 엔벨로프, tanh 포화."""
    f = mtof(m)
    rnd = random.Random(seed)
    rel = 0.035
    n = int((dur + rel) * SR)
    tab = get_table('saw_bright', m)
    o1 = osc(tab, f * 2.0 ** (8.0 / 1200), n, rnd.random())
    o2 = osc(tab, f * 2.0 ** (-8.0 / 1200), n, rnd.random())
    out = [0.0] * n
    y1 = y2 = 0.0
    for i0 in range(0, n, 32):
        fc = 200.0 + accent * 2300.0 * math.exp(-(i0 / SR) / 0.09)
        a = 1.0 - math.exp(-TWO_PI * fc / SR)
        for i in range(i0, min(n, i0 + 32)):
            y1 += a * (0.5 * (o1[i] + o2[i]) - y1)
            y2 += a * (y1 - y2)
            out[i] = y2
    env = adsr(n, 0.004, 0.12, 0.8, rel, dur)
    ws = TWO_PI * (f if f < 70 else f * 0.5) / SR
    drive = 2.4
    td = math.tanh(drive)
    out = [math.tanh(drive * (v * 1.6 + 0.55 * math.sin(ws * i))) / td * e for i, (v, e) in enumerate(zip(out, env))]
    return onepole_lp(out, 2600.0)


# ---------------------------------------------------------------------------
# 악기 5 (2~5장 추가): 금관, 합창, 오르간, 플루트, 스피카토 현, 큰 종, 글로켄슈필, 팀파니, FM 유리음, 스웰
# ---------------------------------------------------------------------------
def inst_brass(m, dur, flags, seed, bright=1.0, attack=0.045, release=0.14, voices=2, detune=6.0):
    """금관풍(트럼펫·호른·트롬본): 금관 파형표 + '필터 엔벨로프'.
    입술이 떨리기 시작하는 순간 소리가 확 밝아졌다가(컷오프 상승) 조금 어두워지는 금관 특유의 어택을 흉내낸다.
    처음 40 ms 는 음높이가 살짝 아래에서 올라붙고, 긴 음에는 늦은 비브라토가 걸린다.
    bright: 필터가 열리는 정도 (호른 0.5 ~ 트럼펫 1.2)."""
    f = mtof(m)
    rel = release
    n = int((dur + rel + 0.03) * SR)
    rnd = random.Random(seed)
    tab = get_table('brass', m)
    vib = dur >= 0.9 or 'v' in flags

    def pf(t):
        p = -0.35 * (1.0 - t / 0.04) ** 2 if t < 0.04 else 0.0
        if vib and t > 0.35:
            p += 0.11 * math.sin(TWO_PI * 5.0 * (t - 0.35)) * min(1.0, (t - 0.35) / 0.4)
        return p
    sig = None
    for v in range(voices):
        cents = 0.0 if voices == 1 else detune * (2.0 * v / (voices - 1) - 1.0)
        o = osc(tab, f * 2.0 ** (cents / 1200.0), n, phase=rnd.random(), pitch_fn=pf)
        sig = o if sig is None else [a + b for a, b in zip(sig, o)]
    env = adsr(n, attack, 0.3, 0.8, rel, dur)
    g = 1.0 / voices
    out = [0.0] * n
    y1 = y2 = 0.0
    for i0 in range(0, n, 32):
        t = i0 / SR
        e = t / attack if t < attack else 0.5 + 0.5 * math.exp(-(t - attack) / 0.22)
        if t > dur:
            e *= max(0.0, 1.0 - (t - dur) / rel)
        fc = min(8000.0, f * (1.5 + bright * 9.0 * e) + 300.0)
        a = 1.0 - math.exp(-TWO_PI * fc / SR)
        for i in range(i0, min(n, i0 + 32)):
            y1 += a * (sig[i] * g - y1)
            y2 += a * (y1 - y2)
            out[i] = y2 * env[i]
    return out


def inst_choir(m, dur, flags, seed, vowel='a', voices=3, attack=0.35, release=0.9, breath=0.035):
    """합창 '아/오/우': 모음 포먼트로 깎은 가산 합성 파형 여러 개를 서로 다른 비브라토로 겹친다.
    성부마다 음높이가 몇 센트씩 어긋나고 떨림 속도도 달라서 여러 사람이 부르는 느낌이 난다."""
    f = mtof(m)
    n = int((dur + release) * SR)
    rnd = random.Random(seed)
    tab = get_table('choir_' + vowel, m)
    sig = [0.0] * n
    for v in range(voices):
        det = rnd.uniform(-9.0, 9.0) / 100.0
        rate = rnd.uniform(4.6, 5.7)
        dep = rnd.uniform(0.07, 0.15)
        ph0 = rnd.random() * TWO_PI
        o = osc(tab, f, n, phase=rnd.random(),
                pitch_fn=lambda t, det=det, rate=rate, dep=dep, ph0=ph0: det + dep * math.sin(ph0 + TWO_PI * rate * t))
        sig = [a + b for a, b in zip(sig, o)]
    env = adsr(n, attack, 0.5, 0.9, release, dur)
    nz = breath_noise()
    off = rnd.randrange(len(nz))
    NL = len(nz)
    g = 1.0 / voices
    return [(s * g + breath * nz[(off + i) % NL]) * e for i, (s, e) in enumerate(zip(sig, env))]


def inst_organ(m, dur, flags, seed, attack=0.06, release=0.35, chiff=0.05):
    """파이프 오르간: 오르간 파형표 2개(2.5센트 어긋난 셀레스테) + 파이프가 말할 때의 짧은 '칙' 바람 소리."""
    f = mtof(m)
    n = int((dur + release) * SR)
    rnd = random.Random(seed)
    tab = get_table('organ', m)
    a = osc(tab, f, n, rnd.random())
    b = osc(tab, f * 2.0 ** (2.5 / 1200.0), n, rnd.random())
    env = adsr(n, attack, 0.2, 0.92, release, dur)
    nz = breath_noise()
    off = rnd.randrange(len(nz))
    NL = len(nz)
    ck = 1.0 / (0.03 * SR)
    return [(0.6 * x + 0.4 * y) * e + chiff * nz[(off + i) % NL] * math.exp(-ck * i)
            for i, (x, y, e) in enumerate(zip(a, b, env))]


def inst_flute(m, dur, flags, seed, **kw):
    """플루트: 관악기 모델에 플루트 파형표 + 숨소리를 조금 더."""
    kw.setdefault('breath', 0.11)
    kw.setdefault('chiff', 0.26)
    kw.setdefault('attack', 0.06)
    return inst_wind(m, dur, flags, seed, kind='flute', auto_vib=0.7, **kw)


def inst_spicc(m, dur, flags, seed, bright=1.0):
    """현악 스피카토(짧게 튀기는 활): 디튠 톱니 2개 + 활이 줄을 긁는 잡음 + 짧은 엔벨로프. 오스티나토용."""
    f = mtof(m)
    rel = 0.07
    gate = min(dur, 0.6)
    n = int((gate + rel) * SR)
    rnd = random.Random(seed)
    tab = get_table('saw', m)
    o1 = osc(tab, f * 2.0 ** (5.0 / 1200.0), n, rnd.random())
    o2 = osc(tab, f * 2.0 ** (-5.0 / 1200.0), n, rnd.random())
    env = adsr(n, 0.006, 0.09, 0.45, rel, gate)
    nz = breath_noise()
    off = rnd.randrange(len(nz) - n - 1)
    kz = 1.0 / (0.02 * SR)
    sig = [(0.5 * (a + b) + 0.22 * nz[off + i] * math.exp(-kz * i)) * e
           for i, (a, b, e) in enumerate(zip(o1, o2, env))]
    return onepole_lp(sig, 2500.0 + 3000.0 * bright) if bright < 1.0 else sig


# 교회 종 부분음 (기본음 대비 주파수비, 진폭, 길이 비율): 험·프라임·티어스(단3도)·퀸트·노미널 …
_CBELL = [(0.5, 0.55, 1.0), (1.0, 0.7, 0.75), (1.2, 0.5, 0.55), (1.5, 0.25, 0.42), (2.0, 0.8, 0.35),
          (2.51, 0.3, 0.22), (2.66, 0.25, 0.2), (3.01, 0.2, 0.15), (4.17, 0.12, 0.1), (5.43, 0.08, 0.07)]


def inst_cbell(m, dur, flags, seed, T=7.0, lp=2600.0):
    """큰 교회 종 (신전·성당): 실제 종의 부분음 비율(단3도 티어스가 섞여 쓸쓸하고 장엄함).
    험·프라임에 0.6 Hz 어긋난 쌍둥이 부분음을 더해 종 특유의 '웅-웅' 맥놀이를 만든다."""
    f = mtof(m)
    P = []
    for r, a, dr in _CBELL:
        fr = f * r
        P.append((r, a / (1.0 + (fr / lp) ** 2), T * dr))
    P.append((0.5 + 0.6 / f, 0.3, T))
    P.append((1.0 + 0.6 / f, 0.35, T * 0.7))
    sig = partial_sum(f, int(T * SR), P, attack=0.002, maxf=8000.0)
    pk = max(abs(x) for x in sig) or 1.0
    return [x / pk for x in sig]


def inst_glock(m, dur, flags, seed):
    """글로켄슈필: 밝고 짧은 금속 막대 (자유막대 부분음 2.76·5.40배)."""
    f = mtof(m)
    T = 1.7 * (880.0 / f) ** 0.3
    P = [(1.0, 1.0, T), (2.76, 0.25, T * 0.25), (5.40, 0.1, T * 0.1), (8.93, 0.04, 0.05)]
    return partial_sum(f, int(T * SR), P, attack=0.0008, maxf=11000.0)


def inst_timp(m, dur, flags, seed, T=1.8):
    """팀파니: 가죽 고유진동(1 : 1.50 : 1.74 : 2.00 : 2.44) + 처음 50 ms 음높이가 살짝 위에서 내려옴
    + 말렛 타격 잡음. 롤은 악보에서 짧은 음을 빠르게 반복해서 만든다."""
    f = mtof(m)
    rnd = random.Random(seed)
    n = int(T * SR)
    out = [0.0] * n
    tau = 0.05 * SR
    bend = 0.025
    ph = [i + bend * tau * (1.0 - math.exp(-i / tau)) for i in range(n)]   # 음높이 하강을 반영한 위상(샘플)
    for r, a, t60 in [(1.0, 1.0, T), (1.504, 0.45, T * 0.6), (1.742, 0.22, T * 0.45), (2.0, 0.28, T * 0.5),
                      (2.44, 0.1, T * 0.3)]:
        w = TWO_PI * f * r / SR
        k = 6.9078 / (t60 * SR)
        mm = min(n, int(t60 * SR))
        out[:mm] = [o + a * math.exp(-k * i) * math.sin(w * p) for i, (o, p) in enumerate(zip(out[:mm], ph[:mm]))]
    nz = bandnoise(int(0.06 * SR), 120.0, 1600.0, rnd)
    kn = 1.0 / (0.012 * SR)
    for i, v in enumerate(nz):
        out[i] += 0.6 * v * math.exp(-kn * i)
    A = int(0.0015 * SR)
    for i in range(A):
        out[i] *= i / A
    pk = max(abs(x) for x in out) or 1.0
    return fade_tail([x / pk for x in out], 0.1)


def inst_fmglass(m, dur, flags, seed, ratio=3.53, index=1.8, T=3.0, attack=0.004):
    """외신(外神)의 유리 소리: 비조화 FM (반송파 : 변조파 = 1 : ratio).
    변조 지수가 서서히 줄어 처음엔 거칠게 반짝이다가 맑은 사인으로 가라앉는다."""
    f = mtof(m)
    n = int(max(T, dur + 0.5) * SR)
    wc = TWO_PI * f / SR
    wm = wc * ratio
    k = 6.9078 / (T * SR)
    ki = 1.0 / (0.5 * SR)
    A = max(1, int(attack * SR))
    return [min(1.0, i / A) * math.exp(-k * i) * math.sin(wc * i + index * math.exp(-ki * i) * math.sin(wm * i))
            for i in range(n)]


def inst_swell(m, dur, flags, seed, lo=2500.0, hi=9000.0, power=2.5):
    """서스펜디드 심벌 롤 / 차오르는 바람: 대역 잡음이 dur 동안 점점 커지다가 끝에서 짧게 사라진다.
    (m 은 쓰지 않음 — 악보 형식을 맞추기 위한 자리)"""
    rnd = random.Random(seed)
    n = int((dur + 0.3) * SR)
    nz = bandnoise(n, lo, hi, rnd)
    D = max(1.0, dur * SR)
    kr = 1.0 / (0.08 * SR)
    out = [v * ((i / D) ** power if i < D else math.exp(-(i - D) * kr)) for i, v in enumerate(nz)]
    pk = max(abs(x) for x in out) or 1.0
    return [x / pk for x in out]


def metal_hit(seed, sec=0.7, f=1650.0):
    """칼날·쇠붙이가 부딪히는 '챙' (비조화 부분음 + 짧은 잡음)."""
    rnd = random.Random(seed)
    f *= rnd.uniform(0.96, 1.04)
    P = [(1.0, 1.0, 0.55), (1.47, 0.6, 0.38), (2.09, 0.5, 0.26), (2.56, 0.35, 0.2), (3.42, 0.25, 0.12)]
    sig = partial_sum(f, int(sec * SR), P, attack=0.0005, maxf=12000.0)
    nz = bandnoise(int(0.05 * SR), 2000.0, 8000.0, rnd)
    kn = 1.0 / (0.008 * SR)
    pk0 = max(abs(x) for x in sig) or 1.0
    for i, v in enumerate(nz):
        sig[i] += 1.2 * pk0 * v * math.exp(-kn * i)
    pk = max(abs(x) for x in sig) or 1.0
    return fade_tail([x / pk for x in sig], 0.05)


def debris_hit(seed, sec=1.5):
    """무너지는 돌 부스러기: 시간이 지날수록 드문드문해지는 작은 충격음 알갱이 + 낮은 웅웅거림."""
    rnd = random.Random(seed)
    n = int(sec * SR)
    imp = [0.0] * n
    for i in range(n):
        p = 0.012 * math.exp(-i / (0.35 * SR))
        if rnd.random() < p:
            imp[i] = rnd.uniform(-1.0, 1.0)
    # 알갱이마다 짧은 울림: 1극 공진(저역통과 두 번) → 고역 일부 제거
    y1 = y2 = 0.0
    a1 = 1.0 - math.exp(-TWO_PI * 2200.0 / SR)
    out = [0.0] * n
    for i in range(n):
        y1 += a1 * (imp[i] - y1)
        y2 += 0.15 * (y1 - y2)
        out[i] = y1 - y2
    rum = bandnoise(n, 40.0, 300.0, rnd)
    pk_r = max(abs(x) for x in rum) or 1.0
    kr = 1.0 / (0.4 * SR)
    pk_o = max(abs(x) for x in out) or 1.0
    out = [o / pk_o + 0.5 * r / pk_r * math.exp(-i * kr) for i, (o, r) in enumerate(zip(out, rum))]
    pk = max(abs(x) for x in out) or 1.0
    return fade_tail([x / pk for x in out], 0.2)


def tri_hit(seed, sec=1.6):
    """오케스트라 트라이앵글: 높은 비조화 부분음이 오래 남는다."""
    rnd = random.Random(seed)
    f = 1850.0 * rnd.uniform(0.99, 1.01)
    P = [(1.0, 0.7, 1.4), (2.13, 1.0, 1.2), (3.31, 0.8, 0.9), (4.62, 0.5, 0.6)]
    sig = partial_sum(f, int(sec * SR), P, attack=0.0005, maxf=12000.0)
    pk = max(abs(x) for x in sig) or 1.0
    return fade_tail([x / pk for x in sig], 0.1)


# ---------------------------------------------------------------------------
# 악기 4: 타악 (북, 장구, 킥, 스네어, 셰이커 …) — 모두 잡음/사인 합성
# ---------------------------------------------------------------------------
def membrane(seed, sec, f0, f1, ptau, atau, nz=0.3, nlo=150.0, nhi=1500.0, ntau=0.03, mode2=0.0):
    """가죽 북 모델: 음높이가 떨어지는 사인 몸통 + 대역 잡음 타격음."""
    rnd = random.Random(seed)
    n = int(sec * SR)
    noise = bandnoise(n, nlo, nhi, rnd) if nz > 0 else None
    out = [0.0] * n
    kp = math.exp(-1.0 / (ptau * SR))
    ka = math.exp(-1.0 / (atau * SR))
    kn = math.exp(-1.0 / (ntau * SR))
    ep = ea = en = 1.0
    ph = 0.0
    df = f0 - f1
    tw = TWO_PI / SR
    for i in range(n):
        ph += tw * (f1 + df * ep)
        ep *= kp
        v = ea * (math.sin(ph) + mode2 * math.sin(1.59 * ph))
        ea *= ka
        if noise is not None:
            v += nz * en * noise[i]
            en *= kn
        out[i] = v
    A = int(0.0015 * SR)
    for i in range(A):
        out[i] *= i / A
    pk = max(abs(x) for x in out) or 1.0
    return fade_tail([x / pk for x in out], 0.05)


def noise_hit(seed, sec, lo, hi, tau, attack=0.001, body_f=0.0, body_amp=0.0, body_tau=0.05, body_end=None):
    """잡음 중심 타악(장구 채편, 스네어, 하이햇, 셰이커)."""
    rnd = random.Random(seed)
    n = int(sec * SR)
    nzs = bandnoise(n, lo, hi, rnd)
    k = math.exp(-1.0 / (tau * SR))
    kb = math.exp(-1.0 / (body_tau * SR))
    A = max(1, int(attack * SR))
    out = [0.0] * n
    e = 1.0
    eb = body_amp
    ph = 0.0
    f_end = body_end if body_end else body_f
    for i in range(n):
        a = i / A if i < A else 1.0
        v = nzs[i] * e
        if body_amp > 0.0:
            fr = f_end + (body_f - f_end) * math.exp(-i / (0.01 * SR))
            ph += TWO_PI * fr / SR
            v += eb * math.sin(ph)
            eb *= kb
        out[i] = v * a
        e *= k
    pk = max(abs(x) for x in out) or 1.0
    return fade_tail([x / pk for x in out], 0.02)


DRUMS = {
    # 이름: (함수, 인자)
    'buk':    lambda s: membrane(s, 1.4, 125.0, 62.0, 0.06, 0.42, nz=0.22, nlo=80, nhi=900, ntau=0.03, mode2=0.18),
    'taiko':  lambda s: membrane(s, 1.6, 105.0, 50.0, 0.07, 0.55, nz=0.3, nlo=60, nhi=800, ntau=0.035, mode2=0.2),
    'kung':   lambda s: membrane(s, 0.6, 115.0, 80.0, 0.035, 0.2, nz=0.14, nlo=100, nhi=700, ntau=0.02, mode2=0.12),
    'ttak':   lambda s: noise_hit(s, 0.22, 1100.0, 4200.0, 0.028, body_f=560.0, body_end=430.0, body_amp=0.7, body_tau=0.045),
    'kick':   lambda s: membrane(s, 0.5, 150.0, 47.0, 0.032, 0.24, nz=0.12, nlo=200, nhi=3000, ntau=0.004),
    'snare':  lambda s: noise_hit(s, 0.3, 900.0, 5200.0, 0.075, body_f=210.0, body_end=185.0, body_amp=0.9, body_tau=0.055),
    'hat':    lambda s: noise_hit(s, 0.08, 5000.0, 8500.0, 0.018),
    'shaker': lambda s: noise_hit(s, 0.12, 2800.0, 7000.0, 0.035, attack=0.01),
    'thump':  lambda s: membrane(s, 0.7, 75.0, 42.0, 0.05, 0.22, nz=0.06, nlo=40, nhi=300, ntau=0.02),
    'tom':    lambda s: membrane(s, 0.6, 160.0, 105.0, 0.05, 0.22, nz=0.15, nlo=120, nhi=1500, ntau=0.02, mode2=0.15),
    # --- 2~5장 추가 ---
    'crash':  lambda s: noise_hit(s, 2.2, 2600.0, 9500.0, 0.5, attack=0.002),          # 크래시 심벌
    'tamb':   lambda s: noise_hit(s, 0.22, 4500.0, 9500.0, 0.05, attack=0.003),         # 탬버린
    'rim':    lambda s: noise_hit(s, 0.08, 1500.0, 5000.0, 0.008, body_f=1700.0, body_end=1600.0,
                                  body_amp=0.8, body_tau=0.012),                        # 림샷 '딱'
    'sroll':  lambda s: noise_hit(s, 0.14, 1300.0, 6500.0, 0.03, body_f=230.0, body_end=200.0,
                                  body_amp=0.35, body_tau=0.02),                        # 스네어 롤 한 타
    'btaiko': lambda s: membrane(s, 2.4, 82.0, 40.0, 0.09, 0.8, nz=0.32, nlo=50, nhi=700, ntau=0.04, mode2=0.22),
    'boom':   lambda s: membrane(s, 3.2, 70.0, 30.0, 0.15, 1.15, nz=0.45, nlo=40, nhi=600, ntau=0.12, mode2=0.25),
    'debris': lambda s: debris_hit(s),                                                   # 돌 부스러기
    'heart':  lambda s: membrane(s, 0.4, 95.0, 58.0, 0.03, 0.1, nz=0.12, nlo=60, nhi=600, ntau=0.012),
    'wood':   lambda s: membrane(s, 0.18, 1050.0, 900.0, 0.02, 0.045, nz=0.25, nlo=700, nhi=4500, ntau=0.004),
    'clang':  lambda s: metal_hit(s),                                                    # 칼날 부딪힘
    'tri':    lambda s: tri_hit(s),                                                      # 트라이앵글
}


# ---------------------------------------------------------------------------
# 잔향 / 지연 (블록 단위로 계산하는 빗살·전대역통과 필터 → 순수 파이썬에서도 빠름)
# ---------------------------------------------------------------------------
def comb_fb(x, D, g, damp=0.0):
    """y[n] = x[n] + g*((1-damp)*y[n-D] + damp*y[n-D-1])  (피드백 빗살 + 2탭 감쇠)
    D 샘플 단위 블록으로 한 번에 계산 (의존성이 D 이상 떨어져 있으므로 가능)."""
    n = len(x)
    a = g * (1.0 - damp)
    b = g * damp
    y = list(x[:D])
    s = D
    while s < n:
        e = min(s + D, n)
        p1 = y[s - D:e - D]
        if b == 0.0:
            y.extend([xi + a * u for xi, u in zip(x[s:e], p1)])
        else:
            p2 = y[s - D - 1:e - D - 1] if s - D - 1 >= 0 else [0.0] + y[0:e - D - 1]
            y.extend([xi + a * u + b * v for xi, u, v in zip(x[s:e], p1, p2)])
        s = e
    return y


def delayed(y, D):
    return [0.0] * D + y[:len(y) - D]


def allpass(x, D, g=0.5):
    """Freeverb 식 전대역통과 확산기."""
    v = comb_fb(x, D, g)
    return [a - b for a, b in zip(delayed(v, D), x)]


_REV_L = ([401, 433, 463, 491, 521, 547], [199, 157, 127, 83])
_REV_R = ([409, 439, 467, 499, 523, 557], [193, 151, 131, 89])


def reverb(send, size=0.86, damp=0.35, predelay=0.02):
    """Freeverb 구조의 스테레오 잔향 (6 빗살 + 4 전대역통과).
    연산량을 줄이기 위해 1/2 로 다운샘플(16 kHz)해서 처리 → 잔향은 원래 고역이 적어 충분하다."""
    n = len(send)
    # 1) 반으로 줄이기 (0.25, 0.5, 0.25 필터 후 솎기) + 한 번 더 부드럽게
    d = [0.5 * b + 0.25 * (a + c) for a, b, c in zip([0.0] + send[1::2], send[0::2], send[1::2])]
    d = [0.5 * b + 0.25 * (a + c) for a, b, c in zip([0.0] + d[:-1], d, d[1:] + [0.0])]
    pdn = int(predelay * SR / 2)
    if pdn > 0:
        d = [0.0] * pdn + d[:len(d) - pdn]
    outs = []
    for combs, aps in (_REV_L, _REV_R):
        cs = [delayed(comb_fb(d, D, size, damp), D) for D in combs]
        acc = [a + b + c + e + f + h for a, b, c, e, f, h in zip(*cs)]
        for D in aps:
            acc = allpass(acc, D)
        # 2) 원래 샘플레이트로 선형보간 업샘플
        up = [0.0] * n
        h = len(acc)
        m = min(h, (n + 1) // 2)
        up[0:2 * m:2] = acc[:m]
        mids = [0.5 * (a + b) for a, b in zip(acc, acc[1:] + [0.0])]
        k = min(len(mids), n // 2)
        up[1:2 * k:2] = mids[:k]
        outs.append(up)
    return outs[0], outs[1]


def rms(x, step=7):
    s = x[::step]
    return math.sqrt(sum(v * v for v in s) / max(1, len(s)))


# ---------------------------------------------------------------------------
# 버스 / 트랙
# ---------------------------------------------------------------------------
class Bus:
    """악기 그룹 하나 (모노). 팬, 음량, 잔향/지연 센드 양을 가진다."""

    def __init__(self, name, n, gain, pan, rev, dly):
        self.name, self.gain, self.pan, self.rev, self.dly = name, gain, pan, rev, dly
        self.buf = [0.0] * n
        self.used = False

    def add(self, sig, s, g):
        e = s + len(sig)
        b = self.buf
        b[s:e] = [x + g * y for x, y in zip(b[s:e], sig)]
        self.used = True


class Track:
    def __init__(self, name, bpm, bpb, bars=None, seed=1, loop=True, length=None, tail=TAIL_SEC):
        self.name, self.bpm, self.bpb, self.bars, self.seed, self.loop = name, bpm, bpb, bars, seed, loop
        self.spb = SR * 60.0 / bpm                       # 한 박의 샘플 수
        if loop:
            self.loop_n = int(round(bars * bpb * self.spb))
            self.n = self.loop_n + int(tail * SR)
        else:
            self.loop_n = int(round(length * SR))
            self.n = self.loop_n
        self.rng = random.Random(seed)
        self.buses = []
        self.cache = {}

    # 시간 변환
    def sec(self, beats):
        return beats * 60.0 / self.bpm

    def bar(self, k):
        """k번째 마디(0부터)의 시작 박."""
        return k * self.bpb

    def bus(self, name, gain=1.0, pan=0.0, rev=0.0, dly=0.0):
        b = Bus(name, self.n, gain, pan, rev, dly)
        self.buses.append(b)
        return b

    def place(self, bus, sig, beat, gain=1.0, jitter=0.0):
        s = int(round(beat * self.spb))
        if jitter:
            s += int(self.rng.uniform(-jitter, jitter) * SR)
        if self.loop:
            s %= self.loop_n                              # 루프 길이로 접어서 배치
        else:
            s = max(0, s)
            if s >= self.n:
                return
        if s + len(sig) > self.n:
            sig = sig[:self.n - s]
        bus.add(sig, s, gain)

    def note(self, fn, m, dur_beats, flags='', var=0, **kw):
        """악기 음을 캐시와 함께 렌더 (같은 음·길이·장식이면 재사용 → 속도 향상)."""
        dsec = round(self.sec(dur_beats), 4)
        key = (fn.__name__, m, dsec, flags, var, tuple(sorted(kw.items())))
        sig = self.cache.get(key)
        if sig is None:
            seed = zlib.crc32(repr((self.seed,) + key).encode())
            sig = array('d', fn(m, dsec, flags, seed, **kw))
            self.cache[key] = sig
        return sig

    def play(self, bus, events, fn, vel=0.8, human=0.06, jitter=0.004, variants=2, **kw):
        """이벤트 목록을 연주해 버스에 넣는다. ! 는 강세, ? 는 약음."""
        for (b, d, m, f) in events:
            v = vel
            if '!' in f:
                v *= 1.25
            if '?' in f:
                v *= 0.6
            f2 = f.replace('!', '').replace('?', '')
            var = self.rng.randrange(variants) if variants > 1 else 0
            sig = self.note(fn, m, d, f2, var, **kw)
            self.place(bus, sig, b, v * (1.0 + self.rng.uniform(-human, human)), jitter)

    def chord(self, bus, beat, dur, names, fn, vel=0.5, **kw):
        for m in (notes(names) if isinstance(names, str) else names):
            self.play(bus, [(beat, dur, m, '')], fn, vel=vel, human=0.03, jitter=0.0, variants=1, **kw)

    def hit(self, bus, kind, beat, vel=0.8, variants=3, jitter=0.002):
        var = self.rng.randrange(variants)
        key = ('drum', kind, var)
        sig = self.cache.get(key)
        if sig is None:
            sig = array('d', DRUMS[kind](zlib.crc32(repr((self.seed,) + key).encode())))
            self.cache[key] = sig
        self.place(bus, sig, beat, vel * (1.0 + self.rng.uniform(-0.05, 0.05)), jitter)

    def pattern(self, bus, start_beat, pat, unit, kit, jitter=0.002):
        """문자 패턴(한 글자 = unit 박)으로 타악 연주. kit: 문자 → [(종류, 세기), ...]"""
        for i, ch in enumerate(pat):
            if ch in kit:
                for kind, vel in kit[ch]:
                    self.hit(bus, kind, start_beat + i * unit, vel, jitter=jitter)

    # -----------------------------------------------------------------------
    def finish(self, rev_size=0.86, rev_damp=0.35, rev_level=0.3, predelay=0.02,
               dly_beats=0.75, dly_fb=0.3, dly_level=0.15, master_lp=10500.0, fade=0.0, drive=0.0):
        """믹스다운 → 잔향/지연 → 마스터 필터 → (루프면) 꼬리 접기 → (선택) 부드러운 포화 → 피크 정규화.
        drive > 0 이면 tanh 소프트 클리핑으로 순간 피크만 눌러 체감 음량/긴장감을 올린다."""
        n = self.n
        L = [0.0] * n
        R = [0.0] * n
        rs = None
        ds = None
        info = {}
        for b in self.buses:
            if not b.used:
                continue
            ang = (b.pan + 1.0) * math.pi / 4.0
            gl = b.gain * math.cos(ang) * math.sqrt(2.0)
            gr = b.gain * math.sin(ang) * math.sqrt(2.0)
            buf = b.buf
            L = [x + gl * y for x, y in zip(L, buf)]
            R = [x + gr * y for x, y in zip(R, buf)]
            if b.rev > 0.0:
                gs = b.rev * b.gain
                rs = [gs * y for y in buf] if rs is None else [x + gs * y for x, y in zip(rs, buf)]
            if b.dly > 0.0:
                gs = b.dly * b.gain
                ds = [gs * y for y in buf] if ds is None else [x + gs * y for x, y in zip(ds, buf)]
            info[b.name] = rms(buf) * b.gain
            b.buf = None
        dry = 0.5 * (rms(L) + rms(R)) or 1e-9
        # 지연(에코): 왼쪽 = 설정 박, 오른쪽 = 1.5배 → 좌우로 퍼지는 메아리
        if ds is not None and dly_level > 0:
            D1 = int(round(dly_beats * self.spb))
            D2 = int(round(dly_beats * 1.5 * self.spb))
            el = delayed(comb_fb(ds, D1, dly_fb, 0.45), D1)
            er = delayed(comb_fb(ds, D2, dly_fb, 0.45), D2)
            el = onepole_lp(el, 3500.0)
            er = onepole_lp(er, 3500.0)
            g = dly_level * dry / (0.5 * (rms(el) + rms(er)) or 1e-9)
            L = [x + g * y for x, y in zip(L, el)]
            R = [x + g * y for x, y in zip(R, er)]
        # 잔향: 젖은 소리 RMS 를 마른 소리 RMS 의 rev_level 배로 맞춘다
        if rs is not None and rev_level > 0:
            wl, wr = reverb(rs, rev_size, rev_damp, predelay)
            g = rev_level * dry / (0.5 * (rms(wl) + rms(wr)) or 1e-9)
            L = [x + g * y for x, y in zip(L, wl)]
            R = [x + g * y for x, y in zip(R, wr)]
        # 마스터: 직류 제거 + 부드러운 저역통과(귀 피로 방지)
        L = master_filter(L, master_lp)
        R = master_filter(R, master_lp)
        if self.loop:
            ln = self.loop_n
            for X in (L, R):
                s = ln
                while s < n:                      # 꼬리를 앞부분에 접어 더한다
                    e = min(n, s + ln)
                    X[0:e - s] = [a + b for a, b in zip(X[0:e - s], X[s:e])]
                    s = e
            L = L[:ln]
            R = R[:ln]
        else:
            if fade > 0:
                fade_tail(L, fade)
                fade_tail(R, fade)
        peak = max(max(L), -min(L), max(R), -min(R)) or 1.0
        info['_raw_peak_db'] = 20 * math.log10(peak)
        if drive > 0.0:
            k = drive / peak
            td = math.tanh(drive)
            L = [math.tanh(k * x) / td for x in L]
            R = [math.tanh(k * x) / td for x in R]
            peak = max(max(L), -min(L), max(R), -min(R)) or 1.0
        g = 10.0 ** (PEAK_DB / 20.0) / peak
        L = [x * g for x in L]
        R = [x * g for x in R]
        # 이음매 검사(루프 곡만): 끝→처음 샘플 차이를 평균 샘플 간 차이와 비교.
        # 1 근처면 매끈함. 0박에 뜯는 음(어택)이 있으면 다른 마디 시작과 비슷한 수준(2~10)까지 커질 수 있다.
        if self.loop:
            seam = max(abs(L[0] - L[-1]), abs(R[0] - R[-1]))
            avgd = sum(abs(L[i] - L[i - 1]) for i in range(1, len(L), 13)) / (len(L) / 13)
            info['_seam_ratio'] = seam / (avgd or 1e-9)
            info['_bars'] = self.bars
            info['_bpm'] = self.bpm
        return L, R, info


def master_filter(x, lp_hz):
    """직류 차단(약 8 Hz) + 1극 저역통과."""
    a = 1.0 - math.exp(-TWO_PI * lp_hz / SR)
    Rk = 0.9985
    out = [0.0] * len(x)
    px = py = lp = 0.0
    for i, v in enumerate(x):
        py = v - px + Rk * py
        px = v
        lp += a * (py - lp)
        out[i] = lp
    return out


# ---------------------------------------------------------------------------
# 반주 도우미
# ---------------------------------------------------------------------------
def arpeggio(t, bus, chord_seq, voicings, pattern, unit, fn, vel=0.35, accent=1.2, bars=None, **kw):
    """마디별 화음 이름 목록 + 보이싱 + 인덱스 패턴 → 분산화음."""
    for k, ch in enumerate(chord_seq):
        if bars is not None and k not in bars:
            continue
        v = notes(voicings[ch])
        for i, idx in enumerate(pattern):
            if idx is None:
                continue
            vv = vel * (accent if i == 0 else 1.0)
            t.play(bus, [(t.bar(k) + i * unit, unit, v[idx], '')], fn, vel=vv, **kw)


# ---------------------------------------------------------------------------
# 화성 도우미 (2~5장 추가): 화음 이름 → 구성음, 보이싱, 화음 진행 이벤트, 2성부 화성
#   화음 이름 형식: 근음[#b] + 성격 + (/베이스)   예) 'F#m7', 'Bb/D', 'E7sus4', 'Gmaj7#11'
# ---------------------------------------------------------------------------
_CHORD_Q = {
    '': (0, 4, 7), 'm': (0, 3, 7), '7': (0, 4, 7, 10), 'm7': (0, 3, 7, 10), 'maj7': (0, 4, 7, 11),
    'sus4': (0, 5, 7), 'sus2': (0, 2, 7), 'dim': (0, 3, 6), 'aug': (0, 4, 8), 'add9': (0, 4, 7, 14),
    'madd9': (0, 3, 7, 14), 'm9': (0, 3, 7, 10, 14), 'maj9': (0, 4, 7, 11, 14), '6': (0, 4, 7, 9),
    'm6': (0, 3, 7, 9), '7sus4': (0, 5, 7, 10), '5': (0, 7), 'dim7': (0, 3, 6, 9), 'm7b5': (0, 3, 6, 10),
    'maj7#11': (0, 4, 7, 11, 18), '9': (0, 4, 7, 10, 14), 'mmaj7': (0, 3, 7, 11),
}


def _pc(name):
    return (_NOTE_PC[name[0]] + {'': 0, '#': 1, 'b': -1}[name[1:]]) % 12


def chord_parse(sym):
    """화음 이름 → (근음 pc, 구성음 반음거리, 베이스 pc)."""
    mm = re.match(r'^([A-G][#b]?)([^/]*)(?:/([A-G][#b]?))?$', sym)
    if not mm or mm.group(2) not in _CHORD_Q:
        raise ValueError('화음 이름 오류: ' + sym)
    root = _pc(mm.group(1))
    bass = _pc(mm.group(3)) if mm.group(3) else root
    return root, _CHORD_Q[mm.group(2)], bass


def chord_pcs(sym):
    root, q, _ = chord_parse(sym)
    return sorted(set((root + iv) % 12 for iv in q))


def voicing(sym, lo, count):
    """lo(음 이름 또는 MIDI) 이상에서 화음 구성음을 아래부터 count 개 쌓는다 (닫힌 자리바꿈).
    lo 를 고정해 두면 화음이 바뀌어도 성부가 가까이 머물러 자연스럽게 이어진다."""
    m = midi(lo) if isinstance(lo, str) else lo
    pcs = chord_pcs(sym)
    out = []
    while len(out) < count:
        if m % 12 in pcs:
            out.append(m)
        m += 1
    return out


def open_voicing(sym, lo, count):
    """열린 보이싱: 근음(또는 베이스) + 5도 + 그 위에 닫힌 화음 (합창·오르간·금관 화음용)."""
    base = bass_of(sym, lo)
    root, q, _ = chord_parse(sym)
    out = [base, base + 7 if (base + 7 - root) % 12 in [iv % 12 for iv in q] else base + 12]
    out += voicing(sym, out[-1] + 1, max(0, count - 2))
    return out[:count]


def bass_of(sym, lo):
    """lo 이상에서 가장 낮은 베이스음 (슬래시 화음이면 슬래시 뒤의 음)."""
    m = midi(lo) if isinstance(lo, str) else lo
    b = chord_parse(sym)[2]
    return m + (b - m) % 12


def prog_events(prog, bpb):
    """마디별 화음 목록 → [(시작 박, 길이 박, 화음), ...]. 'C G' 처럼 띄어 쓰면 마디를 똑같이 나눈다."""
    out = []
    for k, item in enumerate(prog):
        parts = item.split()
        d = bpb / len(parts)
        for j, sym in enumerate(parts):
            out.append((k * bpb + j * d, d, sym))
    return out


def chord_at(pev, beat):
    for b, d, sym in pev:
        if b - 1e-6 <= beat < b + d - 1e-6:
            return sym
    return pev[-1][2]


def harmonize(events, pev, gap=3, offset=0.0):
    """선율 아래에 그때 화음의 구성음으로 한 성부를 더한다 (금관·합창 2성부). gap: 최소 반음 간격.
    offset: 선율 이벤트의 박이 화음 진행보다 앞서 있으면 그만큼 빼고 화음을 찾는다."""
    out = []
    for (b, d, m, f) in events:
        pcs = chord_pcs(chord_at(pev, b - offset))
        h = m - gap
        while h % 12 not in pcs:
            h -= 1
        out.append((b, d, h, f))
    return out


def articulate(events, short=0.5, stacc=0.8, legato=0.95):
    """짧은 음(≤ short 박)은 스타카토(길이 × stacc), 긴 음은 레가토(× legato)."""
    return [(b, d * (stacc if d <= short + 1e-6 else legato), m, f) for (b, d, m, f) in events]


def roll(t, bus, kind, start, beats, step, v0, v1):
    """북·스네어·팀파니 롤: step 박 간격으로 v0 → v1 크레셴도."""
    n = max(1, int(round(beats / step)))
    for i in range(n):
        t.hit(bus, kind, start + i * step, v0 + (v1 - v0) * i / max(1, n - 1), jitter=0.001)


def timp_roll(t, bus, note, start, beats, v0, v1, step=0.125):
    """팀파니 롤 (음높이 있는 북): 짧은 타격을 빠르게 반복하며 크레셴도."""
    n = max(1, int(round(beats / step)))
    m = midi(note) if isinstance(note, str) else note
    for i in range(n):
        t.play(bus, [(start + i * step, step, m, '')], inst_timp, vel=v0 + (v1 - v0) * i / max(1, n - 1),
               human=0.08, jitter=0.002, variants=3, T=0.9)


def gliss(t, bus, start, names, step, fn, vel=0.5, **kw):
    """하프 글리산도·빠른 상행: 음 이름 목록을 step 박 간격으로 차례로 뜯는다."""
    ms = notes(names) if isinstance(names, str) else names
    for i, m in enumerate(ms):
        t.play(bus, [(start + i * step, step * 2, m, '')], fn, vel=vel, human=0.05, jitter=0.0, **kw)


def scale_run(lo, hi, pcs):
    """lo~hi(MIDI) 사이에서 pcs(반음 집합)에 속한 음을 오름차순으로."""
    lo = midi(lo) if isinstance(lo, str) else lo
    hi = midi(hi) if isinstance(hi, str) else hi
    return [m for m in range(lo, hi + 1) if m % 12 in pcs]


def pad_prog(t, bus, pev, lo, count, fn=inst_pad, vel=0.5, offset=0.0, voicer=voicing, **kw):
    """화음 진행 이벤트마다 패드 화음을 깐다."""
    for b, d, sym in pev:
        t.chord(bus, offset + b, d, voicer(sym, lo, count), fn, vel=vel, **kw)


# ===========================================================================
# 곡 1: title — '실패한 마녀'의 자장가 (A단조 ↔ C장조, 3/4 왈츠, 72 bpm, 24마디 = 60초)
# ===========================================================================
TITLE_A = ("A4:1 C5 E5 | F5:2 E5:1 | E5:1 D5 C5 | B4:2 G4:1 | "
           "A4:1 C5 E5 | A5:2 G5:1 | F5:1 E5 D5 | E5:1.5 D5:0.5 B4:1")
TITLE_B = ("G4:1 C5 E5 | D5:2 B4:1 | C5:1 E5 A5 | G5:2 E5:1 | "
           "A4:1 C5 F5 | E5:2 C5:1 | D5:1 F5 A5 | G#5:1.5 F5:0.5 E5:1")
TITLE_C = ("A5:2 E5:1 | F5:1 E5 C5 | E5:1 D5 C5 | B4:2 G4:1 | "
           "A4:1 C5 F5 | G5:1.5 A5:0.5 B5:1 | C6:2 G5:1 | E5:1.5 D5:0.5 B4:1")
TITLE_PROG = ['Am', 'F', 'C', 'G', 'Am', 'F', 'Dm', 'E',
              'C', 'G', 'Am', 'Em', 'F', 'C', 'Dm', 'E',
              'Am', 'F', 'C', 'G', 'F', 'G', 'C', 'E']


def title_melody():
    return (seq(TITLE_A, bar=3) + seq(TITLE_B, bar=3, offset=24) + seq(TITLE_C, bar=3, offset=48))


def track_title():
    t = Track('title', bpm=72, bpb=3, bars=24, seed=101)
    pad_v = {'Am': 'A2 E3 A3 C4 E4', 'F': 'F2 C3 A3 C4 F4', 'C': 'C3 G3 C4 E4', 'G': 'G2 D3 B3 D4',
             'Dm': 'D3 A3 D4 F4', 'E': 'E2 B2 G#3 B3 E4', 'Em': 'E2 B2 G3 B3 E4'}
    arp_v = {'Am': 'A3 E4 A4 C5', 'F': 'F3 C4 F4 A4', 'C': 'C4 G4 C5 E5', 'G': 'G3 D4 G4 B4',
             'Dm': 'D4 A4 D5 F5', 'E': 'E3 B3 E4 G#4', 'Em': 'E3 B3 E4 G4'}
    root = {'Am': 'A2', 'F': 'F2', 'C': 'C3', 'G': 'G2', 'Dm': 'D3', 'E': 'E2', 'Em': 'E2'}
    fifth = {'Am': 'E3', 'F': 'C3', 'C': 'G2', 'G': 'D3', 'Dm': 'A2', 'E': 'B2', 'Em': 'B2'}

    mel = t.bus('celesta', gain=0.95, pan=0.05, rev=1.0, dly=0.6)
    sparkle = t.bus('musicbox', gain=0.22, pan=0.3, rev=1.0, dly=0.8)
    pad = t.bus('strings', gain=0.26, pan=-0.1, rev=1.0)
    harp = t.bus('harp', gain=0.85, pan=-0.35, rev=1.0)
    bass = t.bus('pizz', gain=0.9, pan=0.0, rev=0.5)

    m = title_melody()
    t.play(mel, m, inst_celesta, vel=0.8)
    # 후반부(17~24마디)는 오르골이 한 옥타브 위에서 살며시 겹친다
    t.play(sparkle, ev_transpose([e for e in m if e[0] >= 48], 12), inst_musicbox, vel=0.6)

    for k, ch in enumerate(TITLE_PROG):
        t.chord(pad, t.bar(k), 3, pad_v[ch], inst_pad, vel=0.5, attack=0.45, release=0.9, kind='saw')
        t.play(bass, [(t.bar(k), 1, midi(root[ch]), '')], inst_pizz, vel=0.85)
        if k >= 8:   # B 부분부터 3박째에 5음을 살짝
            t.play(bass, [(t.bar(k) + 2, 1, midi(fifth[ch]), '')], inst_pizz, vel=0.45)
    # 하프 분산화음: B·A' 부분(9~24마디)에서 8분음표로 흐름을 만든다
    arpeggio(t, harp, TITLE_PROG, arp_v, [0, 1, 2, 3, 2, 1], 0.5, inst_harp, vel=0.42,
             bars=set(range(8, 24)))
    return t.finish(rev_size=0.88, rev_damp=0.4, rev_level=0.34, dly_beats=1.5, dly_fb=0.28, dly_level=0.1)


# ===========================================================================
# 곡 2: shingye — 신계의 밤 (A 계면조풍 오음음계, 12/8, 점4분 = 64 bpm, 16마디 = 60초)
#   계면조의 특징을 흉내낸다: E 는 떠는음(깊은 농현), A 는 평으로 내는 음, C→B 는 꺾는음.
# ===========================================================================
def track_shingye():
    t = Track('shingye', bpm=64, bpb=4, bars=16, seed=202)
    U = 1.0 / 3.0            # 8분음표 = 1/3 박 (박 = 점4분음표)
    gy = t.bus('gayageum', gain=1.45, pan=-0.2, rev=1.0, dly=0.5)
    dg = t.bus('daegeum', gain=0.5, pan=0.18, rev=1.0)
    drone = t.bus('drone', gain=0.25, pan=0.0, rev=1.0)
    drum = t.bus('buk', gain=0.45, pan=0.0, rev=0.8)
    chime = t.bus('chime', gain=0.16, pan=0.45, rev=1.0, dly=1.0)

    # --- 가야금 ---
    g_intro = ("A2:3 E3:3 A3:6v | r:1 G3:2 E3:1 D3:2 E3:6w | A3:3 C4:2 D4:1 E4:6v | "
               "G4:2 E4:1 D4:3 C4:2k A3:4")
    g_answer = "A2:6 r:3 E4:3 | A3:6 r:2 C4:1 D4:3 | E4:6v r:6 | r:6 A3:3 E4:3"
    g_ost = ("D3:1 A3 D4 E4 D4 A3 D3 A3 D4 G4 E4 D4 | D3:1 A3 D4 E4 D4 A3 D3 A3 D4 G4 E4 D4 | "
             "G2:1 D3 G3 A3 G3 D3 G2 D3 G3 C4 A3 G3 | A2:1 E3 A3 C4 A3 E3 A2:3 E3:3")
    g_theme = "E4:9w D4:3 | C4:3k A3:9v | r:3 A3:2 C4:1 D4:3 E4:3 | G4:3s E4:3 D4:2 C4:1k A3:3"
    t.play(gy, seq(g_intro, U, 12), inst_gayageum, vel=0.85)
    t.play(gy, seq(g_answer, U, 12, offset=16), inst_gayageum, vel=0.6)
    ost = seq(g_ost, U, 12, offset=32)
    ost = [(b, d, m, '!' if round(b * 3) % 3 == 0 else '') for (b, d, m, f) in ost]
    t.play(gy, ost, inst_gayageum, vel=0.45, ring=1.6)
    t.play(gy, seq(g_theme, U, 12, offset=48), inst_gayageum, vel=0.9)

    # --- 대금 ---
    d_theme = "E5:9w D5:3 | C5:3k A4:9v | r:3 A4:2 C5:1 D5:3 E5:3 | G5:3s E5:3 D5:6v"
    d_high = "D5:3 E5:3 G5:6v | A5:6w G5:2 E5:1 D5:3 | E5:6w D5:3 C5:3k | A4:12v"
    d_low = "r:6 A4:6v | E4:12w | r:12 | r:6 A4:6v"
    t.play(dg, seq(d_theme, U, 12, offset=16), inst_wind, vel=0.8, jitter=0.0)
    t.play(dg, seq(d_high, U, 12, offset=32), inst_wind, vel=0.72, jitter=0.0)
    t.play(dg, seq(d_low, U, 12, offset=48), inst_wind, vel=0.6, jitter=0.0)

    # --- 드론 (5도만 → 장·단조가 모호한 신비감) ---
    dr = [(0, 16, 'A2 E3'), (16, 16, 'A2 E3 A3'), (32, 8, 'D2 A2 D3'), (40, 4, 'G2 D3'),
          (44, 4, 'A2 E3'), (48, 16, 'A2 E3')]
    for b, d, ns in dr:
        t.chord(drone, b, d, ns, inst_pad, vel=0.5, kind='saw_dark', attack=2.0, release=2.5, detune=5.0)

    # --- 북: 강박에만 드물게 ---
    for k in range(16):
        t.hit(drum, 'buk', t.bar(k), 0.75 if k % 4 == 0 else 0.55)
        if 8 <= k < 12:
            t.hit(drum, 'kung', t.bar(k) + 2, 0.4)
        if k % 4 == 3:
            t.hit(drum, 'buk', t.bar(k) + 3, 0.45)
            t.hit(drum, 'buk', t.bar(k) + 3 + 2 * U, 0.6)

    # --- 등불/여우불 같은 풍경 소리 (무작위지만 시드 고정) ---
    scale = notes('A5 C6 D6 E6 G6')
    for k in range(16):
        if t.rng.random() < 0.55:
            pos = t.bar(k) + t.rng.randrange(12) * U
            t.play(chime, [(pos, 1, t.rng.choice(scale), '')], inst_chime, vel=t.rng.uniform(0.5, 0.9))
    return t.finish(rev_size=0.92, rev_damp=0.4, rev_level=0.48, predelay=0.04,
                    dly_beats=1.0, dly_fb=0.25, dly_level=0.1)


# ===========================================================================
# 곡 3: shingye_tension — 탈출/해태 (12/8 자진모리풍, 점4분 = 120 bpm, 24마디 = 48초)
# ===========================================================================
def track_shingye_tension():
    t = Track('shingye_tension', bpm=120, bpb=4, bars=24, seed=303)
    U = 1.0 / 3.0
    gy = t.bus('gayageum', gain=1.05, pan=-0.25, rev=0.7, dly=0.3)
    low = t.bus('gy_low', gain=0.6, pan=0.0, rev=0.5)
    dg = t.bus('daegeum', gain=0.52, pan=0.2, rev=0.8)
    pad = t.bus('ajaeng', gain=0.24, pan=0.1, rev=0.8)
    jg = t.bus('janggu', gain=0.55, pan=0.05, rev=0.4)
    big = t.bus('buk', gain=0.6, pan=-0.05, rev=0.6)

    P = {'A': 'A3 E4 A4 G4 E4 D4 A3 E4 A4 C5 A4 E4',
         'A2': 'A3 E4 A4 G4 E4 D4 E4 G4 A4 C5 D5 E5',
         'D': 'D3 A3 D4 C4 A3 G3 D3 A3 D4 E4 D4 A3',
         'G': 'G3 D4 G4 E4 D4 C4 G3 D4 G4 A4 G4 D4',
         'E': 'E3 B3 E4 D4 B3 A3 E3 B3 E4 G4 E4 B3'}
    form = ['A', 'A', 'A', 'A2'] * 3 + ['D', 'D', 'G', 'E'] + ['A', 'A', 'A', 'A2'] * 2
    lows = {'A': 'A2', 'A2': 'A2', 'D': 'D2', 'G': 'G2', 'E': 'E2'}
    for k, key in enumerate(form):
        ms = notes(P[key])
        for i, mm in enumerate(ms):
            acc = (i % 3 == 0)
            t.play(gy, [(t.bar(k) + i * U, U, mm, '')], inst_gayageum, vel=0.85 if acc else 0.55,
                   ring=0.45, jitter=0.002)
        r = midi(lows[key])
        t.play(low, [(t.bar(k), 1, r, ''), (t.bar(k) + 2, 1, r, '')], inst_gayageum, vel=0.9, ring=1.0)

    # 대금 선율
    d_a = ("E5:3 E5:1 D5:2 E5:3 G5:3 | A5:6w G5:3 E5:3 | D5:3 E5:2 D5:1 C5:3k A4:3 | E5:12w | "
           "E5:3 E5:1 D5:2 E5:3 G5:3 | A5:3 G5:2 E5:1 G5:3 A5:3 | G5:3 E5:2 D5:1 E5:3 D5:2 C5:1k | A4:12v")
    d_b = "r:6 D5:2 E5:1 G5:3 | A5:6w r:6 | r:6 D5:3 G5:3 | E5:6w r:3 E5:1 G5:1 A5:1"
    d_c = ("A5:3 G5:1 E5:2 G5:3 A5:3 | C6:3k A5:3 G5:3 E5:3 | A5:2 G5:1 E5:3 D5:2 E5:1 G5:3 | E5:12w | "
           "E5:3 E5:1 D5:2 E5:3 G5:3 | A5:6w G5:3 E5:3 | D5:3 E5:2 D5:1 C5:3k A4:3 | A4:9v r:3")
    t.play(dg, seq(d_a, U, 12, offset=16), inst_wind, vel=0.8, jitter=0.0, attack=0.05, chiff=0.3)
    t.play(dg, seq(d_b, U, 12, offset=48), inst_wind, vel=0.8, jitter=0.0, attack=0.05, chiff=0.3)
    t.play(dg, seq(d_c, U, 12, offset=64), inst_wind, vel=0.85, jitter=0.0, attack=0.05, chiff=0.3)

    # 낮은 활 소리(아쟁풍) 지속음 — 긴장감
    for b, d, ns in [(0, 16, 'A2 E3'), (16, 16, 'A2 E3'), (32, 16, 'A2 E3'), (48, 8, 'D2 A2'),
                     (56, 4, 'G2 D3'), (60, 4, 'E2 B2'), (64, 16, 'A2 E3'), (80, 16, 'A2 E3')]:
        t.chord(pad, b, d, ns, inst_pad, vel=0.5, kind='saw', attack=1.2, release=1.0, detune=9.0)

    # 장구 (덩=북편+채편, 쿵=북편, 덕=채편, t=채편 약하게)
    kit = {'D': [('kung', 0.9), ('ttak', 0.75)], 'K': [('kung', 0.8)], 'T': [('ttak', 0.75)],
           't': [('ttak', 0.4)]}
    PAT_A = 'D.tK.TK.tK.T'
    PAT_B = 'D.tK.TD.tDTT'
    for k in range(24):
        if k < 2:
            pat = 'K..K..K..K..'
        elif k % 4 == 3:
            pat = PAT_B
        else:
            pat = PAT_A
        t.pattern(jg, t.bar(k), pat, U, kit)
        if k % 2 == 0 or k >= 16:
            t.hit(big, 'buk', t.bar(k), 0.8)
        if k == 23:
            t.hit(big, 'buk', t.bar(k) + 3, 0.6)
            t.hit(big, 'buk', t.bar(k) + 3 + 2 * U, 0.8)
    return t.finish(rev_size=0.82, rev_damp=0.4, rev_level=0.22, dly_beats=2.0 / 3.0, dly_fb=0.2,
                    dly_level=0.07, drive=1.2)


# ===========================================================================
# 곡 4: school — 낮의 마녀학교 (D 도리안 ↔ D장조, 4/4, 100 bpm, 24마디 = 57.6초)
# ===========================================================================
def track_school():
    t = Track('school', bpm=100, bpb=4, bars=24, seed=404)
    prog = ['Dm', 'G', 'Dm', 'G', 'F', 'C', 'G', 'A',
            'D', 'G', 'Em', 'A', 'Bm', 'G', 'Em7', 'A7',
            'Dm', 'G', 'Dm', 'G', 'Bb', 'C', 'Dm', 'A7']
    hv = {'Dm': 'D3 A3 D4 F4', 'G': 'G2 B3 D4 G4', 'F': 'F3 A3 C4 F4', 'C': 'C3 G3 C4 E4',
          'A': 'A2 A3 C#4 E4', 'D': 'D3 A3 D4 F#4', 'Em': 'E3 B3 E4 G4', 'Bm': 'B2 B3 D4 F#4',
          'Em7': 'E3 B3 D4 G4', 'A7': 'A2 G3 C#4 E4', 'Bb': 'Bb2 Bb3 D4 F4'}
    root = {'Dm': 'D2', 'G': 'G2', 'F': 'F2', 'C': 'C3', 'A': 'A2', 'D': 'D2', 'Em': 'E2', 'Bm': 'B2',
            'Em7': 'E2', 'A7': 'A2', 'Bb': 'Bb2'}
    lead = t.bus('woodwind', gain=0.5, pan=0.12, rev=1.0, dly=0.6)
    hp = t.bus('harpsichord', gain=1.5, pan=-0.3, rev=0.8)
    bass = t.bus('pizz', gain=0.6, pan=0.05, rev=0.4)
    glock = t.bus('musicbox', gain=0.2, pan=0.4, rev=1.0, dly=1.0)
    perc = t.bus('shaker', gain=0.25, pan=0.35, rev=0.3)

    MA = ("r:1 A4:0.5 D5:0.5 F5:1 E5:0.5 D5:0.5 | B4:1.5 G4:0.5 B4:1 D5:1 | "
          "C5:0.5 D5:0.5 F5:1 A5:1 G5:0.5 F5:0.5 | E5:1.5 D5:0.5 B4:2 | "
          "A4:0.5 C5:0.5 F5:1 E5:0.5 F5:0.5 G5:1 | E5:1.5 D5:0.5 C5:1 G4:1 | "
          "D5:0.5 E5:0.5 F5:0.5 G5:0.5 A5:1 B5:1 | A5:2 E5:1 C#5:1")
    MB = ("F#5:1.5 E5:0.5 D5:1 A4:1 | B4:1 D5:1 G5:1.5 F#5:0.5 | E5:1 G5:1 B5:1 A5:0.5 G5:0.5 | "
          "A5:2 r:1 A4:0.5 C#5:0.5 | D5:1.5 C#5:0.5 B4:1 F#5:1 | G5:1 F#5:0.5 E5:0.5 D5:1 B4:1 | "
          "E5:1 F#5:1 G5:1 B5:1 | A5:1.5 G5:0.5 E5:1 C#5:1")
    MC = ("r:1 A4:0.5 D5:0.5 F5:1 E5:0.5 D5:0.5 | B4:1.5 G4:0.5 B4:1 D5:1 | "
          "C5:0.5 D5:0.5 F5:1 A5:1 G5:0.5 F5:0.5 | E5:1.5 D5:0.5 B4:2 | "
          "D5:1 F5:0.5 D5:0.5 Bb4:1 D5:1 | E5:1 G5:0.5 E5:0.5 C5:1 E5:1 | "
          "F5:1.5 E5:0.5 D5:1 A4:1 | C#5:1 E5:0.5 G5:0.5 A5:1 r:1")
    mel = seq(MA, bar=4) + seq(MB, bar=4, offset=32) + seq(MC, bar=4, offset=64)
    # 짧은 음은 스타카토(길이 80%), 긴 음은 레가토
    mel = [(b, d * 0.8 if d <= 0.5 else d * 0.95, m, f) for (b, d, m, f) in mel]
    t.play(lead, mel, inst_wind, vel=0.8, jitter=0.003, kind='clar', breath=0.035, attack=0.035,
           release=0.08, chiff=0.12, auto_vib=0.9)

    # 하프시코드: A 부분은 알베르티 분산화음, B 부분은 엇박 화음
    alberti = [0, 2, 1, 2, 3, 2, 1, 2]
    for k, ch in enumerate(prog):
        v = notes(hv[ch])
        if 8 <= k < 16:
            for bt in (0.5, 1.5, 2.5, 3.5):
                for mm in v[1:]:
                    t.play(hp, [(t.bar(k) + bt, 0.3, mm, '')], inst_harpsi, vel=0.45, jitter=0.002)
        else:
            for i, idx in enumerate(alberti):
                t.play(hp, [(t.bar(k) + i * 0.5, 0.45, v[idx], '')], inst_harpsi,
                       vel=0.7 if i % 2 == 0 else 0.5, jitter=0.003)
        # 피치카토 워킹 베이스: 근음 - 5음 - 옥타브 - 다음 근음의 반음 아래(장난스러운 경과음)
        r = midi(root[ch])
        nr = midi(root[prog[(k + 1) % len(prog)]])
        walk = [r, r + 7, r + 12, nr - 1 if nr != r else r + 7]
        for i, mm in enumerate(walk):
            t.play(bass, [(t.bar(k) + i, 1, mm, '')], inst_pizz, vel=0.85 if i == 0 else 0.62)
        # 셰이커 (B 부분부터)
        if k >= 8:
            for i in range(8):
                t.hit(perc, 'shaker', t.bar(k) + i * 0.5, 0.55 if i % 2 else 0.35)
    # 프레이즈 끝마다 오르골 반짝임
    tw = {3: 'G5 B5 D6', 7: 'A5 C#6 E6', 11: 'A5 C#6 E6', 15: 'G5 A5 C#6', 19: 'G5 B5 D6', 23: 'A5 C#6 E6'}
    for k, ns in tw.items():
        for i, mm in enumerate(notes(ns)):
            t.play(glock, [(t.bar(k) + 2.5 + i * 0.25, 0.25, mm, '')], inst_musicbox, vel=0.6)
    return t.finish(rev_size=0.8, rev_damp=0.45, rev_level=0.2, dly_beats=0.75, dly_fb=0.25, dly_level=0.08)


# ===========================================================================
# 곡 5: library — 먼지 쌓인 도서관 (E단조/선법, 4/4, 60 bpm, 16마디 = 64초)
# ===========================================================================
def track_library():
    t = Track('library', bpm=60, bpb=4, bars=16, seed=505)
    prog = ['Em9', 'Cmaj7', 'Am9', 'Bsus4', 'Em9', 'Cmaj7', 'Fmaj7#11', 'B7sus4',
            'Cmaj7', 'Am7', 'Em/G', 'F#m7b5', 'Cmaj7#11', 'Am9', 'Fmaj7#11', 'Bsus4']
    pv = {'Em9': 'E3 B3 F#4 G4', 'Cmaj7': 'C3 G3 B3 E4', 'Am9': 'A2 E3 G3 B3 C4', 'Bsus4': 'B2 F#3 B3 E4',
          'Fmaj7#11': 'F2 C3 E3 A3 B3', 'B7sus4': 'B2 F#3 A3 E4', 'Am7': 'A2 E3 G3 C4',
          'Em/G': 'G2 E3 G3 B3', 'F#m7b5': 'F#2 C3 E3 A3', 'Cmaj7#11': 'C3 G3 B3 F#4'}
    lows = {'Em9': 'E2', 'Cmaj7': 'C2', 'Am9': 'A1', 'Bsus4': 'B1', 'Fmaj7#11': 'F2', 'B7sus4': 'B1',
            'Am7': 'A1', 'Em/G': 'G2', 'F#m7b5': 'F#2', 'Cmaj7#11': 'C2'}
    mb = t.bus('musicbox', gain=0.8, pan=0.15, rev=1.0, dly=1.0)
    pad = t.bus('pad', gain=0.3, pan=-0.1, rev=1.0)
    harp = t.bus('harp_low', gain=0.8, pan=-0.25, rev=1.0)
    dust = t.bus('dust', gain=0.05, pan=0.0, rev=0.5)

    LM = ("r:2 E5:0.5 G5:0.5 B5:1 | C6:2 B5:1 r:1 | r:1 E5:1 r:0.5 B4:0.5 C5:1 | F#5:3 r:1 | "
          "r:2 E5:0.5 G5:0.5 B5:1 | C6:1 B5:1 G5:2 | r:1 A5:1 B5:1 E5:1 | E5:2 F#5:2 | "
          "r:4 | r:1 C5:1 E5:1 G5:1 | B5:1.5 A5:0.5 G5:2 | r:2 A5:1 C6:1 | "
          "B5:2 F#5:2 | r:1 E5:1 G5:1 B5:1 | A5:1 r:1 E5:2 | r:2 F#5:1 E5:1")
    t.play(mb, seq(LM, bar=4), inst_musicbox, vel=0.7, jitter=0.01, human=0.12)
    for k, ch in enumerate(prog):
        t.chord(pad, t.bar(k), 4, pv[ch], inst_pad, vel=0.5, kind='saw_dark', attack=1.5, release=2.5, detune=6.0)
        lo = midi(lows[ch]) + 12
        t.play(harp, [(t.bar(k), 2, lo, '')], inst_harp, vel=0.6)
        if k % 2 == 1:
            t.play(harp, [(t.bar(k) + 2.5, 1, lo + 7, '')], inst_harp, vel=0.35)
    # 먼지 같은 아주 작은 공기 소리
    for b in (2.0, 26.0, 45.0):
        t.play(dust, [(b, 14, 60, '')], inst_wind_noise, vel=1.0, jitter=0.0, variants=1)
    return t.finish(rev_size=0.9, rev_damp=0.45, rev_level=0.45, predelay=0.03,
                    dly_beats=1.5, dly_fb=0.35, dly_level=0.16)


# ===========================================================================
# 곡 6: basement — 봉인된 지하 (D 프리지안풍, 4/4, 50 bpm, 12마디 = 57.6초)
# ===========================================================================
def track_basement():
    t = Track('basement', bpm=50, bpb=4, bars=12, seed=606)
    drone = t.bus('drone', gain=0.55, pan=0.0, rev=0.8)
    up = t.bus('drone_hi', gain=0.3, pan=0.15, rev=1.0)
    pulse = t.bus('pulse', gain=0.6, pan=0.0, rev=0.5)
    bell = t.bus('bell', gain=0.8, pan=-0.3, rev=1.0, dly=0.6)
    glass = t.bus('glass', gain=0.07, pan=0.35, rev=1.0)
    gy = t.bus('gayageum', gain=0.9, pan=-0.15, rev=1.0)
    wind = t.bus('wind', gain=0.16, pan=0.0, rev=0.6)

    for b in (0, 16, 32):
        t.chord(drone, b, 16, 'D2', inst_pad, vel=0.7, kind='saw_dark', attack=3.0, release=4.0, detune=4.0)
    for b, d, ns in [(0, 16, 'A2'), (16, 8, 'Bb2'), (24, 8, 'A2'), (32, 8, 'Ab2'), (40, 8, 'A2')]:
        t.chord(up, b, d, ns, inst_pad, vel=0.6, kind='saw_dark', attack=2.5, release=3.0, detune=6.0)
    # 느린 심장 박동 같은 맥동
    for k in range(12):
        t.hit(pulse, 'thump', t.bar(k), 0.8)
        t.hit(pulse, 'thump', t.bar(k) + 0.3, 0.5)
        t.hit(pulse, 'thump', t.bar(k) + 2, 0.4)
    # 먼 종소리
    for b, nm, v in [(0, 'D4', 0.8), (10, 'A3', 0.6), (16, 'Eb4', 0.75), (26, 'D4', 0.6),
                     (32, 'Ab3', 0.75), (42, 'A3', 0.6)]:
        t.play(bell, [(b, 4, midi(nm), '')], inst_bell, vel=v, variants=1)
    # 유리 같은 맥놀이 음
    for b, nm in [(8, 'A4'), (28, 'D5'), (40, 'Bb4')]:
        t.play(glass, [(b, 6, midi(nm), '')], inst_glass, vel=0.8, variants=1)
    # 낮은 가야금 — 봉인된 동양의 기운 (퇴성/꺾는음)
    t.play(gy, seq('D3:1.5v Eb3:0.5 D3:1 A2:1_ | r:4', bar=4, offset=16), inst_gayageum, vel=0.8)
    t.play(gy, seq('A2:1 D3:1 Eb3:2k', bar=4, offset=40), inst_gayageum, vel=0.8)
    for b, d in [(4.0, 14.0), (22.0, 12.0), (36.0, 14.0)]:
        t.play(wind, [(b, d, 50, '')], inst_wind_noise, vel=1.0, jitter=0.0, variants=1)
    return t.finish(rev_size=0.93, rev_damp=0.5, rev_level=0.5, predelay=0.05,
                    dly_beats=1.5, dly_fb=0.3, dly_level=0.1, master_lp=8000.0)


# ===========================================================================
# 곡 7: boss — 아귀 (E단조, 4/4, 140 bpm, 28마디 = 48초)
#   동양: 가야금 동기(계면조풍 + 꺾는음), 대금 / 서양: 화성단조 V(B장조), 프리지안 bII(F), 거친 톱니 베이스
# ===========================================================================
def track_boss():
    t = Track('boss', bpm=140, bpb=4, bars=28, seed=707)
    prog = ['Em', 'Em', 'Em', 'F',
            'Em', 'Em', 'C', 'B', 'Em', 'Em', 'C', 'B',
            'Am', 'Am', 'F', 'F', 'C', 'Am', 'B', 'B7',
            'Em', 'C', 'Am', 'B', 'Em', 'F', 'Em', 'B7']
    broot = {'Em': 'E1', 'F': 'F1', 'C': 'C2', 'B': 'B1', 'B7': 'B1', 'Am': 'A1'}
    pv = {'Em': 'E3 G3 B3 E4', 'F': 'F3 A3 C4 F4', 'C': 'E3 G3 C4 E4', 'B': 'D#3 F#3 B3 D#4',
          'B7': 'D#3 A3 B3 F#4', 'Am': 'E3 A3 C4 E4'}
    av = {'Am': 'A3 E4 A4 C5', 'F': 'F3 C4 F4 A4', 'C': 'C4 G4 C5 E5', 'B': 'B3 F#4 B4 D#5',
          'B7': 'B3 F#4 A4 D#5'}
    bass = t.bus('sawbass', gain=0.4, pan=0.0, rev=0.1)
    gy = t.bus('gayageum', gain=1.3, pan=-0.22, rev=0.6, dly=0.5)
    dg = t.bus('daegeum', gain=0.55, pan=0.22, rev=0.8)
    pad = t.bus('strings', gain=0.26, pan=0.1, rev=0.8)
    kit_b = t.bus('drums', gain=0.62, pan=0.0, rev=0.25)
    tk = t.bus('taiko', gain=0.6, pan=-0.05, rev=0.5)
    hat = t.bus('hat', gain=0.09, pan=0.3, rev=0.2)
    jg = t.bus('janggu', gain=0.35, pan=0.25, rev=0.4)

    Ma = "E4:0.5 E4:0.25 E4:0.25 G4:0.5 A4:0.5 B4:0.75 A4:0.25 G4:0.5 E4:0.5"
    Mb = "D4:0.5 E4:0.5 G4:0.5 E4:0.5 C5:2k"
    Mc = "E4:0.5 G4:0.5 C5:0.5 B4:0.5 G4:1 E4:1"
    Md = "B3:0.5 D#4:0.5 F#4:0.5 A4:0.5 B4:2v"
    Me = "A4:0.5 A4:0.25 A4:0.25 C5:0.5 D5:0.5 E5:0.75 D5:0.25 C5:0.5 A4:0.5"
    Mf = "F4:0.5 A4:0.5 C5:0.5 A4:0.5 F4:1 E4:1"
    motif_bars = {0: Ma, 1: Mb, 2: Ma, 3: Mf,
                  4: Ma, 5: Mb, 6: Mc, 7: Md, 8: Ma, 9: Mb, 10: Mc, 11: Md,
                  20: Ma, 21: Mc, 22: Me, 23: Md, 24: Ma, 25: Mf, 26: Mb, 27: Md}
    for k, txt in motif_bars.items():
        ev = seq(txt, bar=4, offset=t.bar(k))
        ev = [(b, d, m, f + ('!' if abs(b - round(b)) < 1e-6 and round(b) % 2 == 0 else '')) for (b, d, m, f) in ev]
        t.play(gy, ev, inst_gayageum, vel=0.75, ring=0.9, bright=0.6, jitter=0.002)
    # B 부분: 가야금 8분음표 분산화음 (약하게)
    arpeggio(t, gy, prog, av, [0, 1, 2, 3, 2, 1, 2, 1], 0.5, inst_gayageum, vel=0.38,
             bars=set(range(12, 20)), ring=0.6)
    # 대금: B 부분 서양식 단조 선율, C 부분 긴 대선율
    DB = ("A4:1.5 C5:0.5 E5:2v | D5:1 C5:1 B4:1 A4:1 | C5:3w A4:1 | F5:2 E5:1 C5:1 | "
          "E5:1.5 D5:0.5 C5:1 G4:1 | A4:3v C5:1 | B4:2w D#5:1 F#5:1 | A5:2w F#5:1 D#5:1")
    DC = "E5:4w | G5:3 E5:1 | E5:2 C5:2 | D#5:4w | E5:4w | F5:3 E5:1 | E5:4w | D#5:2 F#5:2"
    t.play(dg, seq(DB, bar=4, offset=t.bar(12)), inst_wind, vel=0.82, jitter=0.0, attack=0.06, chiff=0.3)
    t.play(dg, seq(DC, bar=4, offset=t.bar(20)), inst_wind, vel=0.72, jitter=0.0, attack=0.08)

    for k, ch in enumerate(prog):
        r = midi(broot[ch])
        b0 = t.bar(k)
        # --- 베이스 ---
        if k < 4:
            t.play(bass, [(b0, 1.9, r, ''), (b0 + 2, 1.9, r, '')], inst_sawbass, vel=0.8, jitter=0.0,
                   variants=1, accent=0.6)
        else:
            pat = [0, 0, 12, 0, 0, 12, 0, 7]
            for i, iv in enumerate(pat):
                acc = 1.0 if i in (0, 4) else 0.55
                t.play(bass, [(b0 + i * 0.5, 0.45, r + iv, '')], inst_sawbass, vel=0.9 if i in (0, 4) else 0.7,
                       jitter=0.0, variants=1, accent=acc)
        # --- 패드 ---
        if k >= 4:
            t.chord(pad, b0, 4, pv[ch], inst_pad, vel=0.5, kind='saw', attack=0.06 if k < 12 or k >= 20 else 0.4,
                    release=0.35, detune=10.0)
        # --- 북/드럼 ---
        if k < 4:
            t.hit(tk, 'taiko', b0, 0.95)
            t.hit(tk, 'taiko', b0 + 2, 0.8)
            if k == 3:
                for i, bt in enumerate((2.0, 2.5, 3.0, 3.25, 3.5, 3.75)):
                    t.hit(tk, 'taiko' if i < 3 else 'tom', b0 + bt, 0.55 + 0.07 * i)
            else:
                t.hit(jg, 'ttak', b0 + 3.5, 0.6)
            continue
        if k % 2 == 0:
            t.hit(tk, 'taiko', b0, 0.85)
        half = 12 <= k < 20
        if half:
            for bt in (0.0, 2.5):
                t.hit(kit_b, 'kick', b0 + bt, 0.9)
            t.hit(kit_b, 'snare', b0 + 2, 0.8)
            for bt in (0.5, 1.5, 2.5, 3.5):
                t.hit(jg, 'ttak', b0 + bt, 0.5)
            t.hit(jg, 'kung', b0 + 1, 0.6)
        else:
            for bt in (0.0, 1.5, 2.0):
                t.hit(kit_b, 'kick', b0 + bt, 0.95 if bt == 0 else 0.8)
            t.hit(kit_b, 'snare', b0 + 1, 0.78)
            t.hit(kit_b, 'snare', b0 + 3, 0.82)
            for i in range(8):
                t.hit(hat, 'hat', b0 + i * 0.5, 0.75 if i % 2 else 0.45)
        if k in (11, 19, 27):        # 필인
            for i in range(4):
                t.hit(kit_b, 'snare', b0 + 3 + i * 0.25, 0.45 + 0.15 * i)
            t.hit(tk, 'taiko', b0 + 3.5, 0.8)
    return t.finish(rev_size=0.8, rev_damp=0.45, rev_level=0.18, dly_beats=0.75, dly_fb=0.25,
                    dly_level=0.07, master_lp=10000.0, drive=1.5)


# ===========================================================================
# 곡 8: ending — 따뜻한 재현 (G장조, 3/4, 80 bpm, 24마디 = 54초)
#   타이틀 선율을 A자연단조 → G장조로 '도수 그대로' 옮겨 재현한다.
#   마녀(첼레스타)와 여우신(대금·가야금)이 함께 연주하는 화해의 편성.
# ===========================================================================
# A단조 기준 반음거리 → G장조 기준 반음거리 (G# = 이끎음 → F#)
_MINOR_TO_MAJOR = {0: 0, 2: 2, 3: 4, 5: 5, 7: 7, 8: 9, 10: 11, 11: 11, 1: 1, 4: 4, 6: 6, 9: 9}


def track_ending():
    t = Track('ending', bpm=80, bpb=3, bars=24, seed=808)
    prog = ['G', 'Cadd9', 'G/B', 'D', 'G', 'Em9', 'Am7', 'D7',
            'Bm', 'Am7', 'G', 'D', 'Cmaj7', 'G', 'Am7', 'D',
            'G', 'C', 'G/B', 'D', 'Em', 'D', 'Gmaj7', 'D7']
    pv = {'G': 'G2 D3 G3 B3 D4', 'Cadd9': 'C3 G3 D4 E4', 'G/B': 'B2 D3 G3 D4', 'D': 'D3 A3 D4 F#4',
          'Em9': 'E2 B2 G3 D4 F#4', 'Am7': 'A2 E3 G3 C4', 'D7': 'D3 A3 C4 F#4', 'Bm': 'B2 F#3 B3 D4',
          'Cmaj7': 'C3 G3 B3 E4', 'C': 'C3 G3 C4 E4', 'Em': 'E2 B2 G3 B3', 'Gmaj7': 'G2 D3 F#3 B3'}
    arp = {'G': 'G3 D4 G4 B4', 'Cadd9': 'C4 G4 D5 E5', 'G/B': 'B3 D4 G4 B4', 'D': 'D4 A4 D5 F#5',
           'Em9': 'E3 B3 F#4 G4', 'Am7': 'A3 E4 G4 C5', 'D7': 'D4 A4 C5 F#5', 'Bm': 'B3 F#4 B4 D5',
           'Cmaj7': 'C4 G4 B4 E5', 'C': 'C4 G4 C5 E5', 'Em': 'E3 B3 E4 G4', 'Gmaj7': 'G3 D4 F#4 B4'}
    root = {'G': 'G2', 'Cadd9': 'C3', 'G/B': 'B2', 'D': 'D3', 'Em9': 'E2', 'Am7': 'A2', 'D7': 'D3',
            'Bm': 'B2', 'Cmaj7': 'C3', 'C': 'C3', 'Em': 'E2', 'Gmaj7': 'G2'}
    mel = t.bus('celesta', gain=0.9, pan=0.08, rev=1.0, dly=0.5)
    dg = t.bus('daegeum', gain=0.45, pan=0.25, rev=1.0)
    gy = t.bus('gayageum', gain=0.8, pan=-0.35, rev=1.0)
    pad = t.bus('strings', gain=0.28, pan=-0.05, rev=1.0)
    bass = t.bus('pizz', gain=0.55, pan=0.0, rev=0.5)
    mbx = t.bus('musicbox', gain=0.2, pan=0.4, rev=1.0, dly=1.0)

    m = ev_map(title_melody(), midi('A4'), midi('G4'), _MINOR_TO_MAJOR)
    a_part = [e for e in m if e[0] < 24]
    b_part = [e for e in m if 24 <= e[0] < 48]
    c_part = [e for e in m if e[0] >= 48]
    t.play(mel, a_part + c_part, inst_celesta, vel=0.8)
    # B 부분은 대금이 노래한다 (긴 음에는 농현)
    b_part = [(b, d, mm, 'v' if d >= 2 else '') for (b, d, mm, f) in b_part]
    t.play(dg, b_part, inst_wind, vel=0.8, jitter=0.0, breath=0.07, attack=0.1)
    # C 부분: 대금의 따뜻한 대선율 (화음음 위주)
    DC = "B4:2 D5:1 | C5:3v | B4:3 | A4:3v | B4:2 G4:1 | A4:3v | D5:2 B4:1 | A4:1.5 C5:1.5"
    t.play(dg, seq(DC, bar=3, offset=48), inst_wind, vel=0.62, jitter=0.0, breath=0.07, attack=0.12)

    for k, ch in enumerate(prog):
        t.chord(pad, t.bar(k), 3, pv[ch], inst_pad, vel=0.5, kind='saw', attack=0.5, release=1.0)
        r = midi(root[ch])
        t.play(bass, [(t.bar(k), 1, r, ''), (t.bar(k) + 2, 1, r + 7, '')], inst_pizz, vel=0.8)
    # 가야금 분산화음 (여우신의 손길)
    arpeggio(t, gy, prog, arp, [0, 1, 2, 3, 2, 1], 0.5, inst_gayageum, vel=0.5, ring=1.8)
    for k in (3, 7, 15, 23):
        for i, mm in enumerate(notes(arp[prog[k]])[1:]):
            t.play(mbx, [(t.bar(k) + 1.5 + i * 0.5, 0.5, mm + 12, '')], inst_musicbox, vel=0.55)
    return t.finish(rev_size=0.88, rev_damp=0.4, rev_level=0.36, dly_beats=1.5, dly_fb=0.3, dly_level=0.1)


# ===========================================================================
# 징글 (반복 없음)
# ===========================================================================
def jingle_ability():
    """새 마법 습득: 밝고 당당한 상승 아르페지오 + C장조 화음."""
    t = Track('jingle_ability', bpm=120, bpb=4, loop=False, length=3.4, seed=901)
    cel = t.bus('celesta', gain=0.9, pan=0.1, rev=1.0)
    hp = t.bus('harpsichord', gain=0.45, pan=-0.25, rev=0.8)
    pad = t.bus('pad', gain=0.45, pan=0.0, rev=1.0)
    bell = t.bus('bell', gain=0.3, pan=0.2, rev=1.0)
    gy = t.bus('gayageum', gain=0.5, pan=-0.35, rev=1.0)
    spk = t.bus('sparkle', gain=0.25, pan=0.45, rev=1.0)
    run = notes('G4 C5 E5 G5')
    for i, mm in enumerate(run):
        t.play(cel, [(i * 0.25, 0.25, mm, '')], inst_celesta, vel=0.75, jitter=0.0)
        t.play(hp, [(i * 0.25, 0.22, mm - 12, '')], inst_harpsi, vel=0.6, jitter=0.0)
    t.play(cel, [(1.0, 2, midi('C6'), '')], inst_celesta, vel=0.95, jitter=0.0)
    t.play(cel, [(1.0, 2, midi('E5'), '')], inst_celesta, vel=0.5, jitter=0.0)
    t.play(hp, [(1.0, 1.5, midi('C4'), ''), (1.0, 1.5, midi('G4'), '')], inst_harpsi, vel=0.6, jitter=0.0)
    t.chord(pad, 1.0, 2.2, 'C3 G3 C4 E4 G4', inst_pad, vel=0.5, kind='saw', attack=0.12, release=1.2)
    t.play(bell, [(1.0, 2, midi('C5'), '')], inst_bell, vel=0.7, T=3.0, lp=3500.0, variants=1)
    t.play(gy, [(1.0, 2, midi('G4'), 's')], inst_gayageum, vel=0.8, jitter=0.0)
    for i, nm in enumerate(['E6', 'G6', 'D6', 'C6', 'E6']):
        t.play(spk, [(1.4 + i * 0.3, 0.5, midi(nm), '')], inst_chime, vel=0.6 - 0.07 * i)
    return t.finish(rev_size=0.84, rev_damp=0.4, rev_level=0.3, fade=0.6)


def jingle_quest():
    """목표 갱신: 짧고 가벼운 '띵-띵'."""
    t = Track('jingle_quest', bpm=120, bpb=4, loop=False, length=1.7, seed=902)
    cel = t.bus('celesta', gain=0.9, pan=0.05, rev=1.0)
    harp = t.bus('harp', gain=0.5, pan=-0.25, rev=1.0)
    mb = t.bus('musicbox', gain=0.3, pan=0.35, rev=1.0)
    t.play(cel, [(0.0, 0.3, midi('D5'), ''), (0.0, 0.3, midi('A4'), ''), (0.3, 1, midi('A5'), '')],
           inst_celesta, vel=0.85, jitter=0.0)
    t.play(harp, [(0.0, 0.3, midi('D4'), ''), (0.3, 1, midi('A4'), ''), (0.3, 1, midi('D4'), '')],
           inst_harp, vel=0.6, jitter=0.0)
    t.play(mb, [(0.3, 1, midi('D6'), '')], inst_musicbox, vel=0.6, jitter=0.0)
    return t.finish(rev_size=0.8, rev_damp=0.45, rev_level=0.25, fade=0.5)


def jingle_save():
    """세이브 포인트: 차분하고 따뜻한 종소리 + Fmaj7 화음."""
    t = Track('jingle_save', bpm=80, bpb=4, loop=False, length=3.6, seed=903)
    cel = t.bus('celesta', gain=0.85, pan=0.1, rev=1.0)
    bell = t.bus('bell', gain=0.35, pan=-0.2, rev=1.0)
    pad = t.bus('pad', gain=0.4, pan=0.0, rev=1.0)
    for i, nm in enumerate(['F4', 'A4', 'C5', 'E5']):
        t.play(cel, [(i * 0.5, 1, midi(nm), '')], inst_celesta, vel=0.7, jitter=0.0)
    t.play(cel, [(2.5, 1, midi('F5'), '')], inst_celesta, vel=0.75, jitter=0.0)
    t.play(bell, [(0.0, 2, midi('F4'), '')], inst_bell, vel=0.7, T=4.0, lp=2200.0, variants=1)
    t.chord(pad, 0.0, 2.6, 'F2 C3 E3 A3 C4', inst_pad, vel=0.5, kind='saw_dark', attack=0.7, release=1.4)
    return t.finish(rev_size=0.86, rev_damp=0.45, rev_level=0.32, fade=0.7)


# ===========================================================================
# 2~5장 곡들
#   주제 동기(라이트모티프) — 곡끼리 서로 인용한다
#     학교 동기  : 'r A4 D5 F5 E5 D5' (D 도리안, school 곡의 첫 선율)
#     여우 동기  : 'E5 — D5 C5(꺾는음) A4' (A 계면조풍, shingye 곡의 주제)
#     제국 동기  : 'F4 F4 Bb4 D5 F5' (5-1-3-5 팡파르, 레오니 / 아르덴 제국)
#     숲 동기    : 'A4 D5 E5 F#5 | G#5' (D 리디안 — #4 가 신비로움, 엘라리엔 / 세계수)
#     신전 동기  : 'B4 E5 F#5 G5 | F#5 E5' (E 에올리안 성가풍, 루멘 신전 / 아우렐리아)
#     별 동기    : 'B4 F#5 G#5 | F#5 E5 D5' (B 도리안 — 6음 G# 이 쓸쓸하면서 밝음, 별의 마녀 리라)
# ===========================================================================

# ---------------------------------------------------------------------------
# school_day — 2~5장 아침의 학교 (D장조, 4/4, 108 bpm, 24마디 = 53.3초)
#   school 곡의 선율을 D 도리안 → D장조로 옮겨(F→F#, C→C#) 밝고 가볍게. 플루트·하프·글로켄슈필.
# ---------------------------------------------------------------------------
SCHOOL_DAY_A = ("r:1 A4:0.5 D5:0.5 F#5:1 E5:0.5 D5:0.5 | B4:1.5 G4:0.5 B4:1 D5:1 | "
                "C#5:0.5 D5:0.5 F#5:1 A5:1 G5:0.5 F#5:0.5 | E5:1.5 D5:0.5 B4:2 | "
                "A4:0.5 C#5:0.5 F#5:1 E5:0.5 F#5:0.5 G5:1 | E5:1.5 D5:0.5 C#5:1 G4:1 | "
                "D5:0.5 E5:0.5 F#5:0.5 G5:0.5 A5:1 B5:1 | A5:2 E5:1 C#5:1")


def track_school_day():
    t = Track('school_day', bpm=108, bpb=4, bars=24, seed=1101)
    prog = ['D', 'G', 'D', 'Em7', 'F#m', 'A7', 'G', 'A',
            'G', 'A', 'F#m', 'Bm', 'Em', 'A7', 'D/F# G', 'A7',
            'D', 'G', 'D', 'Em7', 'Bm', 'Em', 'G', 'A7']
    pev = prog_events(prog, 4)
    SB = ("B4:0.5 D5:0.5 G5:1.5 F#5:0.5 E5:1 | E5:1 C#5:0.5 D5:0.5 E5:2 | F#5:1.5 E5:0.5 C#5:1 A4:1 | "
          "B4:1 D5:1 F#5:2 | G5:1.5 F#5:0.5 E5:1 B4:1 | C#5:1 E5:1 A5:1.5 G5:0.5 | "
          "F#5:1 A5:0.5 F#5:0.5 G5:1 B5:1 | A5:2 E5:1 C#5:1")
    SC = ("r:1 A4:0.5 D5:0.5 F#5:1 E5:0.5 D5:0.5 | B4:1.5 G4:0.5 B4:1 D5:1 | "
          "C#5:0.5 D5:0.5 F#5:1 A5:1 G5:0.5 F#5:0.5 | E5:1.5 D5:0.5 B4:2 | "
          "D5:1 F#5:0.5 D5:0.5 B4:1 D5:1 | E5:1 G5:0.5 E5:0.5 B4:1 E5:1 | "
          "D5:1.5 E5:0.5 D5:1 B4:1 | C#5:1 E5:0.5 G5:0.5 A5:1 r:1")
    fl = t.bus('flute', gain=0.62, pan=0.1, rev=1.0, dly=0.5)
    cl = t.bus('clarinet', gain=0.5, pan=0.18, rev=1.0, dly=0.4)
    gl = t.bus('glock', gain=0.2, pan=0.35, rev=1.0, dly=0.8)
    hp = t.bus('harp', gain=0.75, pan=-0.3, rev=1.0)
    hc = t.bus('harpsichord', gain=1.25, pan=-0.2, rev=0.7)
    bass = t.bus('pizz', gain=0.62, pan=0.0, rev=0.4)
    st = t.bus('strings', gain=0.16, pan=-0.05, rev=1.0)
    perc = t.bus('perc', gain=0.2, pan=0.3, rev=0.3)

    a = articulate(seq(SCHOOL_DAY_A, bar=4))
    b = articulate(seq(SB, bar=4, offset=32))
    c = articulate(seq(SC, bar=4, offset=64))
    t.play(fl, a + c, inst_flute, vel=0.8, jitter=0.003)
    t.play(cl, b, inst_wind, vel=0.8, jitter=0.003, kind='clar', breath=0.035, attack=0.035,
           release=0.08, chiff=0.12, auto_vib=0.9)
    # 마지막 A' 는 글로켄슈필이 한 옥타브 위에서 살짝 겹친다
    t.play(gl, ev_transpose([e for e in c if e[1] <= 1.0], 12), inst_glock, vel=0.55)

    for k, ch in enumerate(prog):
        b0 = t.bar(k)
        syms = ch.split()
        main = syms[0]
        r = bass_of(main, 'D2')
        if 8 <= k < 16:
            # B: 하프시코드 엇박 화음 + 피치카토 워킹 베이스 (다음 화음 근음의 반음 아래로 다가감)
            for bt in (0.5, 1.5, 2.5, 3.5):
                sym = chord_at(pev, b0 + bt)
                for mm in voicing(sym, 'F#3', 3):
                    t.play(hc, [(b0 + bt, 0.3, mm, '')], inst_harpsi, vel=0.42, jitter=0.002)
            nr = bass_of(prog[(k + 1) % len(prog)].split()[0], 'D2')
            walk = [r, r + 7, r + 12, nr - 1 if nr != r else r + 7]
            if len(syms) > 1:
                r2 = bass_of(syms[1], 'D2')
                walk = [r, voicing(main, r + 1, 1)[0], r2, r2 + 7]
            for i, mm in enumerate(walk):
                t.play(bass, [(b0 + i, 1, mm, '')], inst_pizz, vel=0.85 if i == 0 else 0.62)
            for i in range(4):
                t.hit(perc, 'tamb', b0 + i + 0.5, 0.4)
        else:
            # A·A': 하프 8분음표 분산화음 + 근음·5음 피치카토
            v = voicing(main, 'A3', 4)
            for i, idx in enumerate([0, 1, 2, 3, 2, 1, 2, 1]):
                t.play(hp, [(b0 + i * 0.5, 0.5, v[idx], '')], inst_harp, vel=0.5 if i == 0 else 0.38)
            t.play(bass, [(b0, 1, r, ''), (b0 + 2, 1, r + 7, '')], inst_pizz, vel=0.8)
        if k >= 8:
            t.chord(st, b0, 4, voicing(main, 'D4', 3), inst_pad, vel=0.5, attack=0.6, release=0.9)
        # 셰이커 (가볍게, 내내)
        for i in range(8):
            t.hit(perc, 'shaker', b0 + i * 0.5, 0.5 if i % 2 else 0.3)
        if k >= 16 and k % 2 == 1:
            t.hit(perc, 'tamb', b0 + 1, 0.45)
            t.hit(perc, 'tamb', b0 + 3, 0.45)
    # 프레이즈 끝 반짝임
    for k, ns in {7: 'A5 C#6 E6', 15: 'A5 C#6 E6 G6', 23: 'G5 A5 C#6 E6'}.items():
        for i, mm in enumerate(notes(ns)):
            t.play(gl, [(t.bar(k) + 2.5 + i * 0.25, 0.25, mm, '')], inst_glock, vel=0.6)
    return t.finish(rev_size=0.8, rev_damp=0.45, rev_level=0.2, dly_beats=0.75, dly_fb=0.25, dly_level=0.08)


# ---------------------------------------------------------------------------
# kingdom — 아르덴 제국 수도의 낮 (B♭장조, 4/4, 112 bpm, 28마디 = 60초)
#   서주 팡파르 4 + A(트럼펫 제국 주제) 8 + B(시장의 북적임: 클라리넷·하프시코드) 8 + A'(총주) 8
# ---------------------------------------------------------------------------
KINGDOM_A = ("F4:0.75 F4:0.25 Bb4:1 D5:1 F5:1 | G5:1.5 F5:0.5 Eb5:1 Bb4:1 | "
             "A4:0.75 Bb4:0.25 C5:1 F5:1 Eb5:1 | D5:3 r:1 | "
             "D5:0.75 D5:0.25 G5:1 Bb5:1 A5:0.5 G5:0.5 | G5:1.5 F5:0.5 Eb5:1 G5:1 | "
             "G5:0.5 F5:0.5 Eb5:0.5 C5:0.5 F5:1 A4:1 | Bb4:2 r:2")
KINGDOM_A_PROG = ['Bb', 'Eb', 'F7', 'Bb', 'Gm', 'Eb', 'Cm7 F', 'Bb']


def march_snare(t, bus, b0, pat, vel=0.7):
    kit = {'X': [('snare', 1.0)], 'x': [('sroll', 0.6)], 'o': [('sroll', 0.35)]}
    for i, ch in enumerate(pat):
        if ch in kit:
            kind, v = kit[ch][0]
            t.hit(bus, kind, b0 + i * 0.25, v * vel, jitter=0.001)


def track_kingdom():
    t = Track('kingdom', bpm=112, bpb=4, bars=28, seed=1201)
    prog = (['Bb', 'Eb', 'Cm F', 'F7'] + KINGDOM_A_PROG +
            ['Gm', 'D7', 'Gm', 'F', 'Eb', 'Bb/D', 'Cm7', 'F7'] + KINGDOM_A_PROG)
    pev = prog_events(prog, 4)
    tp = t.bus('trumpet', gain=0.55, pan=0.12, rev=0.9, dly=0.3)
    hn = t.bus('horns', gain=0.55, pan=-0.2, rev=1.0)
    tb = t.bus('lowbrass', gain=0.5, pan=-0.05, rev=0.7)
    ww = t.bus('woodwind', gain=0.3, pan=0.22, rev=0.9, dly=0.4)
    fl = t.bus('flute', gain=0.2, pan=0.3, rev=1.0)
    st = t.bus('strings', gain=0.4, pan=-0.28, rev=0.7)
    hc = t.bus('harpsichord', gain=1.4, pan=-0.35, rev=0.6)
    bass = t.bus('pizz', gain=0.4, pan=0.0, rev=0.4)
    gl = t.bus('glock', gain=0.16, pan=0.4, rev=1.0)
    sn = t.bus('snare', gain=0.5, pan=0.08, rev=0.4)
    bd = t.bus('bassdrum', gain=0.27, pan=0.0, rev=0.5)
    cy = t.bus('cymbal', gain=0.12, pan=0.25, rev=0.6)
    tim = t.bus('timpani', gain=0.5, pan=-0.1, rev=0.6)

    # --- 서주 팡파르 (트럼펫 + 호른 화성) ---
    INTRO = ("D5:0.75 D5:0.25 D5:1 F5:1.5 r:0.5 | Eb5:0.75 Eb5:0.25 Eb5:1 G5:1.5 r:0.5 | "
             "G5:0.75 G5:0.25 G5:1 A5:1 F5:1 | F5:4")
    intro = articulate(seq(INTRO, bar=4), short=0.75, stacc=0.75)
    t.play(tp, intro, inst_brass, vel=0.85, jitter=0.0, bright=1.1)
    t.play(hn, harmonize(intro, pev, 3), inst_brass, vel=0.75, jitter=0.0, bright=0.55)
    t.play(hn, harmonize(intro, pev, 8), inst_brass, vel=0.65, jitter=0.0, bright=0.5)
    # --- A, A': 트럼펫 주제 (A' 는 호른 3도 아래 화성 + 글로켄슈필) ---
    ka = articulate(seq(KINGDOM_A, bar=4, offset=16), short=0.75, stacc=0.8)
    ka2 = articulate(seq(KINGDOM_A, bar=4, offset=80), short=0.75, stacc=0.8)
    t.play(tp, ka + ka2, inst_brass, vel=0.85, jitter=0.0, bright=1.1)
    t.play(hn, harmonize(ka2, pev, 3), inst_brass, vel=0.72, jitter=0.0, bright=0.55)
    t.play(gl, ev_transpose(ka2, 12), inst_glock, vel=0.5)
    # A 부분 호른: 2분음표 대선율
    HCOUNT = "Bb3:2 D4:2 | Eb4:2 G4:2 | F4:2 A4:2 | Bb4:2 F4:2 | G4:2 D4:2 | Eb4:2 Bb3:2 | C4:2 F4:2 | D4:2 r:2"
    t.play(hn, seq(HCOUNT, bar=4, offset=16), inst_brass, vel=0.6, jitter=0.0, bright=0.45)
    # --- B: 시장의 북적임 (클라리넷 8분음표, 뒤 4마디는 플루트가 옥타브 위로) ---
    KB = ("G4:0.5 A4:0.5 Bb4:0.5 D5:0.5 G5:1 D5:1 | F#5:0.5 E5:0.5 D5:0.5 C5:0.5 A4:1 F#4:1 | "
          "G4:0.5 Bb4:0.5 D5:0.5 G5:0.5 Bb5:1 A5:0.5 G5:0.5 | F5:1.5 C5:0.5 A4:1 F4:1 | "
          "Eb5:0.5 F5:0.5 G5:0.5 Bb5:0.5 G5:1 Eb5:1 | D5:0.5 Eb5:0.5 F5:0.5 Bb5:0.5 F5:1 D5:1 | "
          "C5:0.5 D5:0.5 Eb5:0.5 G5:0.5 Bb5:1 G5:1 | A5:1 F5:0.5 Eb5:0.5 C5:1 A4:1")
    kb = articulate(seq(KB, bar=4, offset=48), stacc=0.7)
    t.play(ww, kb, inst_wind, vel=0.8, jitter=0.003, kind='clar', breath=0.035, attack=0.03,
           release=0.07, chiff=0.14, auto_vib=0.9)
    t.play(fl, ev_transpose([e for e in kb if e[0] >= 64], 12), inst_flute, vel=0.6)

    for k, ch in enumerate(prog):
        b0 = t.bar(k)
        main = ch.split()[0]
        sec_b = k >= 12 and k < 20
        # 베이스: A 는 행진곡 '쿵-짝'(1·3박 근음/5음), B 는 8분음표 워킹
        if not sec_b:
            for i, sym in enumerate([chord_at(pev, b0), chord_at(pev, b0 + 2)]):
                r = bass_of(sym, 'Bb1')
                t.play(bass, [(b0 + 2 * i, 1, r, ''), (b0 + 2 * i + 1, 1, r + 7 if r + 7 < midi('C3') else r - 5, '')],
                       inst_pizz, vel=0.85)
            # 현악 '짝' 화음 (2·4박) + 저음 금관 2분음표
            for bt in (1, 3):
                t.chord(st, b0 + bt, 0.45, voicing(chord_at(pev, b0 + bt), 'D4', 3), inst_spicc, vel=0.5)
            if k >= 20 or k < 4:
                for i in (0, 2):
                    sym = chord_at(pev, b0 + i)
                    t.play(tb, [(b0 + i, 1.8, bass_of(sym, 'Bb1') + 12, '')], inst_brass, vel=0.7, jitter=0.0,
                           bright=0.5)
        else:
            r = bass_of(main, 'Bb1')
            pat = [0, 12, 7, 12, 0, 12, 7, 5]
            for i, iv in enumerate(pat):
                t.play(bass, [(b0 + i * 0.5, 0.5, r + iv, '')], inst_pizz, vel=0.8 if i % 4 == 0 else 0.55)
            v = voicing(main, 'F4', 4)
            for i, idx in enumerate([0, 2, 1, 3, 0, 2, 1, 3]):
                t.play(hc, [(b0 + i * 0.5, 0.45, v[idx], '')], inst_harpsi, vel=0.5 if i % 2 == 0 else 0.38)
            t.chord(st, b0, 4, voicing(main, 'D4', 3), inst_pad, vel=0.32, attack=0.3, release=0.6)
        # --- 타악 ---
        if k < 3:
            t.hit(bd, 'taiko', b0, 0.8)
            t.play(tim, [(b0, 1, bass_of(main, 'F2'), '')], inst_timp, vel=0.8)
            march_snare(t, sn, b0, 'X..xX...X..x....', 0.75)
        elif k == 3:
            roll(t, sn, 'sroll', b0, 3.5, 0.125, 0.25, 0.95)
            timp_roll(t, tim, 'F2', b0, 3.5, 0.3, 0.9)
            t.hit(sn, 'snare', b0 + 3.5, 0.95)
        elif sec_b:
            t.hit(bd, 'taiko', b0, 0.55)
            for i in range(4):
                t.hit(sn, 'tamb', b0 + i + 0.5, 0.55)
                t.hit(sn, 'tamb', b0 + i, 0.3)
            if k == 19:
                roll(t, sn, 'sroll', b0 + 2, 2, 0.125, 0.3, 0.9)
        else:
            t.hit(bd, 'taiko', b0, 0.8)
            t.hit(bd, 'taiko', b0 + 2, 0.6)
            march_snare(t, sn, b0, 'X..xX.x.X..xX.xx' if k % 4 != 3 else 'X..xX.x.Xxxxxxxx', 0.7)
        if k in (4, 20):
            t.hit(cy, 'crash', b0, 0.9)
            t.play(tim, [(b0, 1, midi('Bb2'), '')], inst_timp, vel=0.9)
        if k in (11, 27):
            t.play(tim, [(b0, 1, midi('Bb2'), ''), (b0 + 2, 1, midi('F2'), '')], inst_timp, vel=0.75)
    return t.finish(rev_size=0.82, rev_damp=0.45, rev_level=0.22, dly_beats=0.75, dly_fb=0.2,
                    dly_level=0.05, drive=0.8)


# ---------------------------------------------------------------------------
# kingdom_night — 밤의 수도 · 수사 (G단조, 4/4, 80 bpm, 20마디 = 60초)
#   제국 동기를 단조로 낮춰 클라리넷 저음이 몰래 읊조린다. 살금살금 피치카토, 먼 시계탑 종.
# ---------------------------------------------------------------------------
def track_kingdom_night():
    t = Track('kingdom_night', bpm=80, bpb=4, bars=20, seed=1301)
    prog = ['Gm', 'Gm', 'Eb', 'D', 'Gm', 'Cm', 'Am7b5', 'D7',
            'Eb', 'Bb/D', 'Cm', 'Gm', 'Ab', 'Eb/G', 'Am7b5', 'D7',
            'Gm', 'Gm', 'Eb/G', 'D/F#']
    cl = t.bus('clarinet', gain=0.55, pan=0.12, rev=1.0, dly=0.4)
    fl = t.bus('flute', gain=0.55, pan=0.2, rev=1.0, dly=0.6)
    bass = t.bus('pizz', gain=0.75, pan=-0.05, rev=0.5)
    hp = t.bus('harp', gain=1.0, pan=-0.3, rev=1.0)
    st = t.bus('strings', gain=0.2, pan=0.0, rev=1.0)
    cel = t.bus('celesta', gain=0.22, pan=0.4, rev=1.0, dly=0.9)
    bell = t.bus('bell', gain=0.42, pan=-0.25, rev=1.0)
    perc = t.bus('perc', gain=0.18, pan=0.2, rev=0.6)
    low = t.bus('drone', gain=0.18, pan=0.0, rev=0.8)

    NA = ("D4:0.75 D4:0.25 G4:1 Bb4:2 | A4:1 G4:0.5 F#4:0.5 G4:2 | Bb4:0.75 Bb4:0.25 Eb5:1 G5:1.5 F5:0.5 | "
          "D5:1 C5:0.5 Bb4:0.5 A4:2 | D4:0.75 D4:0.25 G4:1 Bb4:1 D5:1 | Eb5:1.5 D5:0.5 C5:1 G4:1 | "
          "A4:1 C5:1 Eb5:1.5 D5:0.5 | C5:1 Bb4:0.5 A4:0.5 F#4:2")
    NB = ("G5:2 F5:1 Eb5:1 | D5:3 r:1 | Eb5:1 G5:1 C6:1.5 Bb5:0.5 | G5:2 D5:2 | "
          "C5:1 Eb5:1 Ab5:1.5 G5:0.5 | G5:2 Bb4:2 | C5:1 Eb5:1 A5:1 G5:1 | F#5:3 r:1")
    NC = "r:2 D4:1 G4:1 | Bb4:2 A4:2 | G4:3 r:1 | F#4:2 r:2"
    t.play(cl, articulate(seq(NA, bar=4), short=0.75, stacc=0.6) + seq(NC, bar=4, offset=64), inst_wind,
           vel=0.8, jitter=0.004, kind='clar', breath=0.05, attack=0.05, release=0.12, chiff=0.1, auto_vib=1.2)
    t.play(fl, seq(NB, bar=4, offset=32), inst_flute, vel=0.7, breath=0.13)

    for k, ch in enumerate(prog):
        b0 = t.bar(k)
        r = bass_of(ch, 'C2')
        if k < 16:
            for i, iv in enumerate([0, 7, 12, 7]):
                t.play(bass, [(b0 + i, 0.5, r + iv, '')], inst_pizz, vel=0.8 if i == 0 else 0.55)
        else:
            v = voicing(ch, r, 4)
            for i, idx in enumerate([0, 1, 2, 1, 3, 1, 2, 1]):
                t.play(bass, [(b0 + i * 0.5, 0.5, v[idx], '')], inst_pizz, vel=0.75 if i == 0 else 0.5)
            t.chord(low, b0, 4, [midi('G1'), midi('D2')], inst_pad, vel=0.6, kind='saw_dark', attack=1.0,
                    release=1.5, detune=5.0)
            t.hit(perc, 'thump', b0, 0.7)
        # 하프: A 는 4분음표 상행 분산화음, B 는 2박마다 화음
        hv = voicing(ch, 'G3', 4)
        if k < 8:
            for i in range(4):
                t.play(hp, [(b0 + i + 0.5, 0.5, hv[i], '')], inst_harp, vel=0.42)
        elif k < 16:
            t.chord(hp, b0, 2, hv[1:], inst_harp, vel=0.32)
            t.chord(hp, b0 + 2, 2, hv[:3], inst_harp, vel=0.25)
        t.chord(st, b0, 4, voicing(ch, 'Bb3', 3), inst_pad, vel=0.5, kind='saw_dark', attack=1.2, release=1.5)
        # 밤의 시계 소리 같은 림 (B·다리 부분)
        if k >= 8:
            t.hit(perc, 'rim', b0 + 1, 0.35)
            t.hit(perc, 'rim', b0 + 3, 0.3)
    # 별빛 같은 첼레스타 (G 단조 오음음계, 무작위지만 시드 고정)
    pent = notes('G5 Bb5 C6 D6 F6 G6')
    for k in range(8, 20):
        for _ in range(2):
            if t.rng.random() < 0.6:
                pos = t.bar(k) + t.rng.randrange(8) * 0.5
                t.play(cel, [(pos, 1, t.rng.choice(pent), '')], inst_celesta, vel=t.rng.uniform(0.4, 0.75))
    # 먼 시계탑 종
    t.play(bell, [(0.0, 4, midi('G3'), '')], inst_cbell, vel=0.8, variants=1, T=7.0, lp=1800.0)
    t.play(bell, [(t.bar(16), 4, midi('D3'), '')], inst_cbell, vel=0.7, variants=1, T=7.0, lp=1800.0)
    return t.finish(rev_size=0.9, rev_damp=0.45, rev_level=0.4, predelay=0.03,
                    dly_beats=1.5, dly_fb=0.3, dly_level=0.1)


# 학교 동기 원형 (school 곡 A 부분, D 도리안) — 다른 곡에서 옮겨 인용한다
SCHOOL_MOTIF = ("r:1 A4:0.5 D5:0.5 F5:1 E5:0.5 D5:0.5 | B4:1.5 G4:0.5 B4:1 D5:1 | "
                "C5:0.5 D5:0.5 F5:1 A5:1 G5:0.5 F5:0.5 | E5:1.5 D5:0.5 B4:2 | "
                "A4:0.5 C5:0.5 F5:1 E5:0.5 F5:0.5 G5:1 | E5:1.5 D5:0.5 C5:1 G4:1 | "
                "D5:0.5 E5:0.5 F5:0.5 G5:0.5 A5:1 B5:1 | A5:2 E5:1 C#5:1")
SCHOOL_MOTIF_PROG = ['Dm', 'G', 'Dm', 'G', 'F', 'C', 'G', 'A']
# 드럼 문자 패턴용 악기표 (16분음표 한 글자)
KIT_ORCH = {'T': [('taiko', 0.95)], 't': [('taiko', 0.6)], 'S': [('snare', 0.85)], 's': [('sroll', 0.5)],
            'o': [('tom', 0.7)], 'B': [('btaiko', 1.0)], 'K': [('kick', 0.9)]}


def drum_bar(t, bus, b0, pat, vel=1.0, kit=None):
    """16분음표 문자 패턴 한 마디 (KIT_ORCH 기본)."""
    kit = kit or KIT_ORCH
    for i, ch in enumerate(pat):
        for kind, v in kit.get(ch, ()):
            t.hit(bus, kind, b0 + i * 0.25, v * vel, jitter=0.001)


# ---------------------------------------------------------------------------
# knight_duel — 기사단장 레오니와의 밤의 결투 (D단조, 4/4, 150 bpm, 36마디 = 57.6초)
#   마법 없이 검 하나 — 쉬지 않는 현악 오스티나토(3+3+2 강세) 위로 제국 동기를 단조로 바꾼 호른.
#   서주 4 + A 8 + B(F장조로 영웅적으로) 8 + C(트럼펫과 현의 주고받기, 칼날 부딪힘) 8 + A' 8
# ---------------------------------------------------------------------------
def track_knight_duel():
    t = Track('knight_duel', bpm=150, bpb=4, bars=36, seed=1401)
    A = ['Dm', 'Dm', 'Bb', 'C', 'Dm', 'Gm', 'Bb', 'A7']
    prog = (['Dm', 'Dm', 'Bb', 'A7'] + A + ['F', 'C/E', 'Dm', 'Bb', 'Gm', 'C', 'A7sus4', 'A7'] +
            ['Dm', 'Eb', 'Dm', 'Eb', 'Bb', 'C', 'A', 'A7'] + A)
    pev = prog_events(prog, 4)
    hn = t.bus('horns', gain=0.6, pan=-0.15, rev=0.8)
    tp = t.bus('trumpet', gain=0.5, pan=0.15, rev=0.7, dly=0.25)
    lo = t.bus('cellos', gain=0.55, pan=-0.2, rev=0.4)
    vn = t.bus('violins', gain=0.45, pan=0.3, rev=0.5)
    cb = t.bus('contrabass', gain=0.24, pan=0.0, rev=0.3)
    dr = t.bus('drums', gain=0.34, pan=0.0, rev=0.35)
    tim = t.bus('timpani', gain=0.5, pan=-0.1, rev=0.5)
    cy = t.bus('cymbal', gain=0.13, pan=0.2, rev=0.5)
    clang = t.bus('clang', gain=0.18, pan=0.35, rev=0.7)

    DA = ("A3:0.75 A3:0.25 D4:1 F4:1 A4:1 | G4:1.5 F4:0.5 E4:1 D4:1 | F4:0.75 F4:0.25 Bb4:1 D5:1.5 C5:0.5 | "
          "C5:2 G4:2 | A4:0.75 A4:0.25 D5:1 F5:1 E5:0.5 D5:0.5 | D5:1.5 Bb4:0.5 G4:1 Bb4:1 | "
          "A4:1 Bb4:1 D5:1 F5:1 | E5:2 C#5:1 A4:1")
    DB = ("C5:0.75 C5:0.25 F5:1 A5:1.5 G5:0.5 | G5:1 E5:1 C5:1 E5:1 | F5:0.75 F5:0.25 A5:1 D6:1.5 C6:0.5 | "
          "Bb5:2 F5:1 D5:1 | G5:1.5 A5:0.5 Bb5:1 G5:1 | E5:1.5 F5:0.5 G5:1 C5:1 | D5:2 E5:2 | C#5:2 E5:1 A5:1")
    DC_TP = ("D5:0.5 F5:0.5 A5:1 r:2 | r:4 | F5:0.5 A5:0.5 D6:1 r:2 | r:4 | "
             "F5:1 D5:0.5 F5:0.5 Bb5:2 | G5:1 E5:0.5 G5:0.5 C6:2 | E5:0.5 F5:0.5 E5:0.5 C#5:0.5 A4:2 | r:4")
    DC_VN = "r:4 | Bb5:0.5 G5:0.5 Eb5:1 r:2 | r:4 | G5:0.5 Eb5:0.5 Bb4:1 r:2"
    da = articulate(seq(DA, bar=4, offset=16), short=0.75, stacc=0.75)
    da2 = articulate(seq(DA, bar=4, offset=112), short=0.75, stacc=0.75)
    db = articulate(seq(DB, bar=4, offset=48), short=0.75, stacc=0.75)
    t.play(hn, da + da2, inst_brass, vel=0.85, jitter=0.0, bright=0.65)
    t.play(tp, ev_transpose(da2, 12), inst_brass, vel=0.7, jitter=0.0, bright=1.1)
    t.play(tp, db, inst_brass, vel=0.85, jitter=0.0, bright=1.15)
    t.play(hn, harmonize(db, pev, 3), inst_brass, vel=0.7, jitter=0.0, bright=0.6)
    t.play(tp, articulate(seq(DC_TP, bar=4, offset=80)), inst_brass, vel=0.9, jitter=0.0, bright=1.2)
    t.play(hn, harmonize([e for e in seq(DC_TP, bar=4, offset=80) if e[0] >= 96], pev, 3), inst_brass,
           vel=0.7, jitter=0.0, bright=0.6)
    t.play(vn, seq(DC_VN, bar=4, offset=80), inst_spicc, vel=1.0, jitter=0.0)
    t.play(vn, ev_transpose(seq(DC_VN, bar=4, offset=80), -12), inst_spicc, vel=0.8, jitter=0.0)

    for k, ch in enumerate(prog):
        b0 = t.bar(k)
        sym = ch.split()[0]
        r = bass_of(sym, 'A2')
        # 첼로 오스티나토: 8분음표, 3+3+2 강세
        for i, iv in enumerate([0, 0, 0, 12, 0, 0, 7, 0]):
            acc = i in (0, 3, 6)
            t.play(lo, [(b0 + i * 0.5, 0.4, r + iv, '')], inst_spicc, vel=0.95 if acc else 0.55, jitter=0.002)
        t.play(cb, [(b0, 3.8, bass_of(sym, 'C2'), '')], inst_pad, vel=0.7, jitter=0.0, variants=1,
               kind='saw', attack=0.03, release=0.2, detune=6.0)
        # 바이올린 16분음표 (B · A')
        if 12 <= k < 20 or k >= 28:
            v = voicing(sym, 'D5', 3)
            for i in range(16):
                t.play(vn, [(b0 + i * 0.25, 0.22, v[[0, 1, 2, 1][i % 4]], '')], inst_spicc,
                       vel=0.7 if i % 4 == 0 else 0.45, jitter=0.0)
        # --- 타악 ---
        sec = 0 if k < 4 else 1 if k < 12 else 2 if k < 20 else 3 if k < 28 else 4
        if sec == 0:
            drum_bar(t, dr, b0, 'T.....t.T.......', 0.9)
            if k == 3:
                roll(t, dr, 'sroll', b0 + 1, 3, 0.125, 0.2, 0.9)
                timp_roll(t, tim, 'A2', b0 + 1, 3, 0.3, 0.9)
        elif sec == 3:
            drum_bar(t, dr, b0, 'T.....t.T...S...' if k % 2 == 0 else 'T.....t.T.S.S.ss', 0.9)
            if k in (21, 23):
                t.hit(clang, 'clang', b0, 0.9)
            if k == 27:
                for bt in (0.0, 1.0, 1.5):
                    t.hit(clang, 'clang', b0 + bt, 0.8)
                roll(t, dr, 'sroll', b0 + 2, 2, 0.125, 0.3, 1.0)
                timp_roll(t, tim, 'A2', b0 + 2, 2, 0.3, 1.0)
        else:
            last = (k % 8 == 3)
            drum_bar(t, dr, b0, 'T..s..t.T.s.S.s.' if not last else 'T..s..t.Tsssoooo', 0.95)
        if k in (4, 12, 20, 28):
            t.hit(cy, 'crash', b0, 0.9)
            t.play(tim, [(b0, 1, midi('D2'), '')], inst_timp, vel=0.95)
        elif sec in (1, 2, 4) and k % 2 == 0:
            t.play(tim, [(b0, 1, bass_of(sym, 'F2'), '')], inst_timp, vel=0.6)
    return t.finish(rev_size=0.8, rev_damp=0.45, rev_level=0.2, dly_beats=0.75, dly_fb=0.2,
                    dly_level=0.05, drive=1.3)


# ---------------------------------------------------------------------------
# starbeast — 운석 짐승, 레오니와 함께 (G단조 → B♭장조, 4/4, 128 bpm, 32마디 = 60초) · 2장 절정
#   A: 위협적인 저음 금관 리프 + 합창 / B: 제국 주제(트럼펫) 장조로 / C: 학교 동기(호른) + 가야금 /
#   D: 제국 동기 상승 반복 + 합창 '아' 절정
# ---------------------------------------------------------------------------
def track_starbeast():
    t = Track('starbeast', bpm=128, bpb=4, bars=32, seed=1501)
    prog = (['Gm', 'Gm', 'Eb', 'D', 'Gm', 'Gm', 'Cm', 'D'] + KINGDOM_A_PROG +
            ['Gm', 'C', 'Gm', 'C', 'Bb', 'F', 'C', 'D'] + ['Eb', 'F', 'Gm', 'Gm/F', 'Eb', 'F', 'D', 'D7'])
    pev = prog_events(prog, 4)
    tp = t.bus('trumpet', gain=0.5, pan=0.15, rev=0.8, dly=0.2)
    hn = t.bus('horns', gain=0.55, pan=-0.18, rev=0.9)
    lb = t.bus('lowbrass', gain=0.5, pan=-0.05, rev=0.5)
    ch = t.bus('choir', gain=0.42, pan=0.0, rev=1.0)
    st = t.bus('strings', gain=0.3, pan=0.25, rev=0.6)
    lo = t.bus('cellos', gain=0.45, pan=-0.25, rev=0.4)
    gy = t.bus('gayageum', gain=1.05, pan=-0.35, rev=0.6)
    dr = t.bus('drums', gain=0.4, pan=0.0, rev=0.4)
    tim = t.bus('timpani', gain=0.5, pan=-0.1, rev=0.6)
    cy = t.bus('cymbal', gain=0.13, pan=0.25, rev=0.6)

    SA = ("D4:1 G4:1 Bb4:1.5 A4:0.5 | G4:3 D4:1 | Eb4:1 G4:1 Bb4:1.5 C5:0.5 | A4:3 F#4:1 | "
          "D5:1 G5:1 Bb5:1.5 A5:0.5 | G5:2 F5:1 D5:1 | Eb5:1 G5:1 C6:1.5 Bb5:0.5 | A5:2 F#5:1 D5:1")
    sa = seq(SA, bar=4)
    t.play(hn, [e for e in sa if e[0] < 16], inst_brass, vel=0.9, jitter=0.0, bright=0.7)
    t.play(tp, [e for e in sa if e[0] >= 16], inst_brass, vel=0.85, jitter=0.0, bright=1.1)
    t.play(hn, harmonize([e for e in sa if e[0] >= 16], pev, 3), inst_brass, vel=0.7, jitter=0.0, bright=0.6)
    kb = articulate(seq(KINGDOM_A, bar=4, offset=32), short=0.75, stacc=0.8)
    t.play(tp, kb, inst_brass, vel=0.9, jitter=0.0, bright=1.15)
    t.play(hn, harmonize(kb, pev, 3), inst_brass, vel=0.72, jitter=0.0, bright=0.6)
    sm = articulate(ev_transpose(seq(SCHOOL_MOTIF, bar=4, offset=64), -7), stacc=0.85)
    t.play(hn, sm, inst_brass, vel=0.9, jitter=0.0, bright=0.75)
    t.play(tp, ev_transpose([e for e in sm if e[0] >= 80], 12), inst_brass, vel=0.6, jitter=0.0, bright=0.9)
    SD = ("Bb4:0.75 Bb4:0.25 Eb5:1 G5:2 | C5:0.75 C5:0.25 F5:1 A5:2 | D5:0.75 D5:0.25 G5:1 Bb5:2 | "
          "A5:2 G5:1 F5:1 | G5:2 Bb5:2 | A5:2 C6:2 | F#5:2 A5:2 | D5:2 r:2")
    sd = articulate(seq(SD, bar=4, offset=96), short=0.75, stacc=0.8)
    t.play(tp, sd, inst_brass, vel=0.95, jitter=0.0, bright=1.2)
    t.play(hn, harmonize(sd, pev, 3), inst_brass, vel=0.8, jitter=0.0, bright=0.65)
    t.play(hn, harmonize(sd, pev, 8), inst_brass, vel=0.65, jitter=0.0, bright=0.55)

    riff = [0, 0, 3, 0, 5, 0, 6, 5]
    for k, c in enumerate(prog):
        b0 = t.bar(k)
        sym = c.split()[0]
        r = bass_of(sym, 'A1')
        sec = k // 8
        # 저음: A 는 반음계 리프, 나머지는 8분음표 근음 박동
        if sec == 0:
            for i, iv in enumerate(riff):
                t.play(lb, [(b0 + i * 0.5, 0.45, r + iv, '')], inst_brass, vel=0.85 if i % 2 == 0 else 0.7,
                       jitter=0.0, variants=1, bright=0.55)
                t.play(lo, [(b0 + i * 0.5, 0.4, r + 12 + iv, '')], inst_spicc, vel=0.8, jitter=0.0)
        else:
            for i in range(8):
                t.play(lo, [(b0 + i * 0.5, 0.4, r + 12 + (12 if i % 4 == 2 else 0), '')], inst_spicc,
                       vel=0.85 if i % 2 == 0 else 0.55, jitter=0.0)
            t.play(lb, [(b0, 1.8, r + 12, ''), (b0 + 2, 1.8, bass_of(chord_at(pev, b0 + 2), 'A1') + 12, '')],
                   inst_brass, vel=0.75, jitter=0.0, bright=0.5)
        # 합창: A 는 어두운 '오', D 는 밝은 '아'
        if sec == 0:
            t.chord(ch, b0, 4, open_voicing(sym, 'G2', 4), inst_choir, vel=0.6, vowel='o', attack=0.5)
        elif sec == 3:
            for sy_b, sy_d, sy in [(b, d, s) for (b, d, s) in pev if b0 <= b < b0 + 4]:
                t.chord(ch, sy_b, sy_d, open_voicing(sy, 'Bb2', 5), inst_choir, vel=0.7, vowel='a', attack=0.25)
        # 현악: B·D 는 16분음표 트레몰로풍, C 는 가야금 분산화음
        if sec in (1, 3):
            v = voicing(sym, 'G4', 3)
            for i in range(16):
                t.play(st, [(b0 + i * 0.25, 0.22, v[[0, 1, 2, 1][i % 4]], '')], inst_spicc,
                       vel=0.6 if i % 4 == 0 else 0.4, jitter=0.0)
        if sec == 2:
            v = voicing(sym, 'G3', 4)
            for i, idx in enumerate([0, 1, 2, 3, 2, 3, 1, 2, 0, 1, 2, 3, 2, 3, 1, 2]):
                t.play(gy, [(b0 + i * 0.25, 0.25, v[idx] + 12, '')], inst_gayageum, vel=0.55 if i % 4 == 0 else 0.4,
                       ring=0.4, jitter=0.002)
            t.chord(st, b0, 4, voicing(sym, 'D4', 3), inst_pad, vel=0.4, attack=0.3, release=0.5)
        # --- 타악 ---
        if sec == 0:
            drum_bar(t, dr, b0, 'B.....t.T.......' if k % 2 == 0 else 'B.....t.T...oooo', 0.95)
        elif sec == 1:
            drum_bar(t, dr, b0, 'T..s..t.S..sT.s.' if k % 4 != 3 else 'T..s..t.Sssssooo', 0.9)
        elif sec == 2:
            drum_bar(t, dr, b0, 'T.s.S.s.T.s.S.ss', 0.85)
        else:
            drum_bar(t, dr, b0, 'B..s..t.S..sT.S.' if k != 31 else 'B..s..t.SsssoooT', 1.0)
        if k % 8 == 0:
            t.hit(cy, 'crash', b0, 0.95)
            t.play(tim, [(b0, 1, midi('G2'), '')], inst_timp, vel=1.0)
        elif k % 2 == 0:
            t.play(tim, [(b0, 1, bass_of(sym, 'F2'), '')], inst_timp, vel=0.65)
        if k in (7, 15, 23):
            timp_roll(t, tim, 'D2', b0 + 2, 2, 0.3, 0.95)
        if sec == 3 and k % 2 == 0:
            t.hit(cy, 'crash', b0, 0.6)
    return t.finish(rev_size=0.84, rev_damp=0.45, rev_level=0.24, dly_beats=0.75, dly_fb=0.2,
                    dly_level=0.04, drive=1.4)


# ---------------------------------------------------------------------------
# elf — 세계수 위 엘프 마을 (D 리디안, 12/8, 점4분 = 60 bpm, 16마디 = 64초)
#   하프 12/8 분산화음, 플루트(숲 동기: #4 = G# 이 신비로움), 합창 '우' 바람 패드, 반딧불 글로켄슈필
# ---------------------------------------------------------------------------
ELF_A = ("A4:3 D5:3 E5:3 F#5:3 | G#5:6 F#5:3 E5:3 | F#5:3 A5:3 D6:3 C#6:3 | B5:9 G#5:3 | "
         "F#5:6 D5:3 B4:3 | D5:3 E5:3 G5:4 F#5:2 | E5:6 D5:3 B4:3 | C#5:9 r:3")
ELF_A_PROG = ['D', 'E/D', 'D', 'E/D', 'Bm', 'G', 'Em7', 'A']


def track_elf():
    t = Track('elf', bpm=60, bpb=4, bars=16, seed=1601)
    U = 1.0 / 3.0
    prog = ELF_A_PROG + ['G', 'A', 'F#m', 'Bm', 'Gmaj7', 'E/G#', 'Asus4', 'A']
    pev = prog_events(prog, 4)
    fl = t.bus('flute', gain=0.6, pan=0.12, rev=1.0, dly=0.5)
    fl2 = t.bus('flute2', gain=0.3, pan=-0.12, rev=1.0)
    hp = t.bus('harp', gain=1.2, pan=-0.25, rev=1.0)
    hp_hi = t.bus('harp_hi', gain=0.9, pan=0.3, rev=1.0, dly=0.6)
    ch = t.bus('choir', gain=0.2, pan=0.0, rev=1.0)
    st = t.bus('cello', gain=0.22, pan=-0.05, rev=0.8)
    gl = t.bus('fireflies', gain=0.18, pan=0.45, rev=1.0, dly=1.0)
    wind = t.bus('wind', gain=0.12, pan=0.0, rev=0.6)
    perc = t.bus('perc', gain=0.22, pan=0.15, rev=0.6)

    EB = ("D5:2 E5:1 G5:3 B5:6 | A5:3 G5:2 F#5:1 E5:6 | F#5:2 E5:1 C#5:3 A4:6 | B4:3 C#5:3 D5:3 F#5:3 | "
          "F#5:6 B5:6 | G#5:6 E5:3 B4:3 | D5:6 E5:6 | C#5:6 r:6")
    ea = seq(ELF_A, U, 12)
    eb = seq(EB, U, 12, offset=32)
    t.play(fl, ea + eb, inst_flute, vel=0.8, jitter=0.0)
    t.play(fl2, harmonize(eb, pev, 3), inst_flute, vel=0.7, jitter=0.0)

    for k, c in enumerate(prog):
        b0 = t.bar(k)
        v = voicing(c, 'D3', 4)
        for i, idx in enumerate([0, 1, 2, 3, 2, 1, 0, 1, 2, 3, 2, 1]):
            t.play(hp, [(b0 + i * U, 2 * U, v[idx], '')], inst_harp, vel=0.55 if i % 3 == 0 else 0.38)
        t.play(hp, [(b0, 4, bass_of(c, 'D2'), '')], inst_harp, vel=0.6)
        if k >= 8:
            vh = voicing(c, 'D5', 4)
            for i, idx in enumerate([3, 2, 1, 2]):
                t.play(hp_hi, [(b0 + i + 2 * U, U, vh[idx], '')], inst_harp, vel=0.45)
        t.chord(ch, b0, 4, voicing(c, 'A3', 3), inst_choir, vel=0.6, vowel='u', attack=1.2, release=1.5)
        t.play(st, [(b0, 4, bass_of(c, 'D2'), '')], inst_pad, vel=0.6, jitter=0.0, variants=1,
               kind='saw_dark', attack=0.8, release=1.2)
        # 부드러운 타악: 1박 낮은 북, B 부분은 셰이커 '둥-다닥'
        t.hit(perc, 'tom', b0, 0.35)
        if k >= 8:
            for i in range(12):
                if i % 3 != 1:
                    t.hit(perc, 'shaker', b0 + i * U, 0.45 if i % 3 == 0 else 0.3)
            t.hit(perc, 'tom', b0 + 2, 0.25)
    # 반딧불: D 리디안 높은 음이 여기저기서 반짝
    sc = notes('D6 E6 F#6 G#6 A6 B6 C#7')
    for k in range(16):
        for _ in range(3):
            if t.rng.random() < 0.55:
                pos = t.bar(k) + t.rng.randrange(12) * U
                t.play(gl, [(pos, 1, t.rng.choice(sc), '')], inst_glock, vel=t.rng.uniform(0.35, 0.8))
    for b in (2.0, 22.0, 42.0):
        t.play(wind, [(b, 16, 60, '')], inst_wind_noise, vel=1.0, jitter=0.0, variants=1)
    return t.finish(rev_size=0.9, rev_damp=0.4, rev_level=0.4, predelay=0.03,
                    dly_beats=1.0, dly_fb=0.3, dly_level=0.1)


# ---------------------------------------------------------------------------
# elf_hunt — 엘라리엔의 사냥 (E 프리지안, 4/4, 96 bpm, 24마디 = 60초)
#   어디서 화살이 날아올지 모르는 숲. 드문 뜯음, 팽팽한 침묵, 빨라지는 심장 박동.
# ---------------------------------------------------------------------------
def track_elf_hunt():
    t = Track('elf_hunt', bpm=96, bpb=4, bars=24, seed=1701)
    pz = t.bus('pizz', gain=0.8, pan=0.2, rev=0.8, dly=0.6)
    hp = t.bus('harp', gain=0.75, pan=-0.3, rev=0.9, dly=0.4)
    fl = t.bus('flute', gain=0.42, pan=0.1, rev=1.0, dly=0.5)
    dr = t.bus('drone', gain=0.3, pan=0.0, rev=0.8)
    trem = t.bus('tremolo', gain=0.2, pan=-0.15, rev=0.6)
    gl = t.bus('glass', gain=0.07, pan=0.35, rev=1.0)
    heart = t.bus('heart', gain=0.47, pan=0.0, rev=0.3)
    tk = t.bus('taiko', gain=0.3, pan=0.0, rev=0.9)
    sw = t.bus('swell', gain=0.12, pan=0.0, rev=0.8)

    # 심장 박동: 쿵-쿵 (조용한 곳은 2박마다, 긴장되면 매 박)
    for k in range(24):
        fast = 8 <= k < 20
        for bt in (range(4) if fast else (0, 2)):
            t.hit(heart, 'heart', t.bar(k) + bt, 0.85)
            t.hit(heart, 'heart', t.bar(k) + bt + 0.3, 0.55)
    # 저음 드론 (E 지속음 + 긴장 구간은 F 반음 충돌)
    for b, d, ns in [(0, 32, 'E1 B1 E2'), (32, 16, 'E1 E2 F2'), (48, 16, 'E1 B1 F2'), (64, 16, 'E1 B1 E2'),
                     (80, 16, 'E1 B1')]:
        t.chord(dr, b, d, ns, inst_pad, vel=0.6, kind='saw_dark', attack=2.5, release=3.0, detune=5.0)
    # 뜯는 동기 (드문드문, 사이가 비어 있는 게 핵심)
    M1 = "E4:0.5 F4:0.5 r:1 E4:0.5 B3:0.5 r:1"
    M2 = "r:2 F4:0.25 E4:0.25 r:0.5 B3:1"
    M3 = "E4:0.25 F4:0.25 G4:0.25 F4:0.25 E4:1 r:2"
    for k, mt in {1: M1, 3: M2, 7: M1, 12: M1, 13: M3, 14: M2, 15: M3, 17: M2, 20: M1, 22: M2}.items():
        t.play(pz, seq(mt, bar=4, offset=t.bar(k)), inst_pizz, vel=0.8, jitter=0.0)
    # 하프 오스티나토 조각
    for k in (4, 5, 6, 16, 17, 18, 19):
        for i, nm in enumerate(['E3', 'B3', 'F4', 'B3']):
            t.play(hp, [(t.bar(k) + i * 0.75, 0.75, midi(nm), '')], inst_harp, vel=0.45 if i else 0.6)
    # 엘라리엔의 플루트: 숲 동기를 프리지안으로 비튼 조각
    FA = "B4:1 E5:1 F5:1 G5:1 | F5:3 r:1"
    FB = "B4:1 E5:1 F5:1 A5:1 | G5:2 F5:1 E5:1 | E5:4 | r:4"
    t.play(fl, seq(FA, bar=4, offset=t.bar(4)), inst_flute, vel=0.75, breath=0.16)
    t.play(fl, seq(FB, bar=4, offset=t.bar(16)), inst_flute, vel=0.8, breath=0.16)
    # 팽팽한 침묵: 높은 유리음
    for b, nm in [(t.bar(8), 'B5'), (t.bar(9) + 2, 'C6'), (t.bar(10), 'F6')]:
        t.play(gl, [(b, 6, midi(nm), '')], inst_glass, vel=0.8, variants=1)
    t.play(sw, [(t.bar(11), 4, 60, '')], inst_swell, vel=1.0, jitter=0.0, variants=1, lo=800.0, hi=5000.0)
    # 긴장 구간: 낮은 현 트레몰로 (16분음표 E-F 반복) + 북
    for k in range(12, 16):
        for i in range(16):
            t.play(trem, [(t.bar(k) + i * 0.25, 0.2, midi('E3') + (1 if (i // 2) % 2 else 0), '')], inst_spicc,
                   vel=0.55 + 0.03 * i, jitter=0.0)
        t.hit(tk, 'taiko', t.bar(k), 0.9)
        if k % 2 == 1:
            t.hit(tk, 'tom', t.bar(k) + 2.5, 0.6)
            t.hit(tk, 'tom', t.bar(k) + 3, 0.7)
    t.hit(tk, 'btaiko', t.bar(16), 0.9)
    return t.finish(rev_size=0.9, rev_damp=0.45, rev_level=0.38, predelay=0.04,
                    dly_beats=0.75, dly_fb=0.35, dly_level=0.12, drive=0.8)


# ---------------------------------------------------------------------------
# herald — 하얀 전령(외신의 사자)과의 싸움 (C# 중심의 무조, 4/4, 120 bpm, 30마디 = 60초)
#   외신의 소리 = 겹겹이 맥놀이하는 낮은 웅웅거림 + 높은 유리음. 3+3+2 로 비틀거리는 북,
#   오염된 숲 동기(E→E♭, F#→F, G#→G) 를 반음 어긋나게 조율한 플루트가 부른다.
# ---------------------------------------------------------------------------
def track_herald():
    t = Track('herald', bpm=120, bpb=4, bars=30, seed=1801)
    hum = t.bus('hum', gain=0.35, pan=0.0, rev=0.7)
    sub = t.bus('sub', gain=0.21, pan=0.0, rev=0.2)
    gl = t.bus('glass', gain=0.18, pan=0.3, rev=1.0, dly=0.6)
    fm = t.bus('fmglass', gain=0.25, pan=-0.3, rev=1.0, dly=0.8)
    ch = t.bus('choir', gain=0.28, pan=0.0, rev=1.0)
    bass = t.bus('sawbass', gain=0.3, pan=0.0, rev=0.1)
    dr = t.bus('drums', gain=0.55, pan=0.0, rev=0.4)
    tick = t.bus('ticks', gain=0.28, pan=0.4, rev=0.6)
    br = t.bus('brass', gain=0.42, pan=-0.15, rev=0.6)
    fl = t.bus('flute', gain=0.4, pan=0.15, rev=1.0, dly=0.5)

    # 낮은 웅웅거림: C#1·G#1 + 0.3 반음 어긋난 층 → 느린 맥놀이, 그 아래 사인 서브
    for b in range(0, 120, 16):
        t.chord(hum, b, 16, [25, 32], inst_pad, vel=0.6, kind='saw_dark', attack=2.0, release=2.5, detune=4.0)
        t.chord(hum, b, 16, [25.3, 37.2], inst_pad, vel=0.45, kind='saw_dark', attack=3.0, release=2.5, detune=9.0)
        t.chord(sub, b, 16, [37], inst_pad, vel=0.6, kind='sine', attack=2.0, release=2.0, voices=1)
    # 높은 유리음 (오래 끄는 맥놀이) + 비조화 FM 반짝임
    for b, nm, d in [(0, 'C#6', 10), (12, 'D6', 10), (24, 'G6', 8), (40, 'C#6', 12), (56, 'G#6', 10),
                     (72, 'D6', 12), (88, 'G6', 10), (100, 'C#6', 14)]:
        t.play(gl, [(b, d, midi(nm), '')], inst_glass, vel=0.8, variants=1, beat_hz=0.9)
    fmset = notes('C#6 D6 G6 G#6 D7 C#7')
    for k in range(30):
        if t.rng.random() < 0.7:
            pos = t.bar(k) + t.rng.randrange(16) * 0.25
            t.play(fm, [(pos, 1, t.rng.choice(fmset), '')], inst_fmglass, vel=t.rng.uniform(0.4, 0.9),
                   ratio=3.53, index=2.2, T=2.5)
    # 합창 '우' 불협 덩어리 (멀리서)
    for b, d, ns in [(32, 16, 'C#4 D4 G4'), (48, 16, 'C4 C#4 G4'), (64, 16, 'C#4 D4 G#4'), (80, 16, 'D4 G4 G#4'),
                     (96, 16, 'C#4 D4 G4')]:
        t.chord(ch, b, d, ns, inst_choir, vel=0.6, vowel='u', attack=2.5, release=2.0)
    # 리듬: 8분음표 베이스 오스티나토 + 3+3+2 북 (9~28마디)
    ost = [0, 0, 1, 0, 0, 6, 0, 1]
    for k in range(8, 28):
        b0 = t.bar(k)
        for i, iv in enumerate(ost):
            acc = i in (0, 3, 6)
            t.play(bass, [(b0 + i * 0.5, 0.42, 37 + iv, '')], inst_sawbass, vel=0.85 if acc else 0.6,
                   jitter=0.0, variants=1, accent=1.0 if acc else 0.5)
        if k < 24:
            drum_bar(t, dr, b0, 'T.....T.....t...' if k < 16 else 'T..s..T..s..S.ss', 0.9)
        else:
            drum_bar(t, dr, b0, 'T.....t.........', 0.8)
        if k % 4 == 3 and k < 24:
            drum_bar(t, dr, b0 + 2, 'oooo....', 0.75)
    for k in range(30):
        for i in range(16):
            if t.rng.random() < 0.18:
                t.hit(tick, 'rim', t.bar(k) + i * 0.25, t.rng.uniform(0.3, 0.8))
    t.hit(dr, 'boom', t.bar(16), 1.0)
    t.hit(dr, 'boom', t.bar(24), 0.9)
    # 금관 불협 찌르기 (17~24마디, 엇박)
    for k in range(16, 24):
        for bt in (1.5, 3.0):
            t.chord(br, t.bar(k) + bt, 0.4, [49, 50, 55], inst_brass, vel=0.75, bright=0.9, release=0.1)
    # 오염된 숲 동기 (반음의 1/3 만큼 어긋난 조율)
    CF = "A4:1 D5:1 Eb5:1 F5:1 | G5:3 r:1 | A4:1 D5:1 Eb5:1 F5:1 | Gb5:2 F5:1 Eb5:1 | " \
         "D5:4 | r:4 | A5:1 G5:1 Eb5:1 D5:1 | A4:4"
    cf = [(b, d, m + 0.33, f) for (b, d, m, f) in seq(CF, bar=4, offset=t.bar(16))]
    t.play(fl, cf, inst_flute, vel=0.8, jitter=0.0, breath=0.15)
    t.play(fm, ev_transpose(cf, 12), inst_fmglass, vel=0.45, jitter=0.0, ratio=3.53, index=1.2, T=1.5)
    return t.finish(rev_size=0.9, rev_damp=0.4, rev_level=0.36, predelay=0.04, dly_beats=0.75,
                    dly_fb=0.35, dly_level=0.1, master_lp=9500.0, drive=1.0)


# ---------------------------------------------------------------------------
# temple — 관리자 신 루멘의 대신전 (E 에올리안, 4/4, 60 bpm, 16마디 = 64초)
#   흰 대리석과 금, 차갑고 성스러운 공기. 오르간 화음, 합창 성가(신전 동기), 큰 종, 빛의 거울 같은 첼레스타.
#   장3도 대신 v 화음을 단화음(Bm)·sus4 로 써서 따뜻함을 빼고, C 화음 위의 F# (#11) 로 차가운 빛을 낸다.
# ---------------------------------------------------------------------------
TEMPLE_MOTIF = ("B4:1 E5:1 F#5:1 G5:1 | F#5:2 E5:2 | D5:1 E5:1 F#5:1 A5:1 | F#5:4 | "
                "G5:1 F#5:1 E5:1 B4:1 | C5:1 E5:1 A5:2 | G5:1 F#5:1 E5:1 G5:1 | F#5:2 E5:2")
TEMPLE_PROG = ['Em', 'C', 'D', 'Bm', 'Em', 'Am', 'C', 'Bsus4']


def track_temple():
    t = Track('temple', bpm=60, bpb=4, bars=16, seed=1901)
    prog = TEMPLE_PROG + ['C', 'D', 'Bm', 'Em', 'Am', 'C', 'D', 'Bsus4']
    pev = prog_events(prog, 4)
    org = t.bus('organ', gain=0.3, pan=-0.1, rev=1.0)
    solo = t.bus('organ_solo', gain=0.4, pan=0.15, rev=1.0, dly=0.4)
    ch = t.bus('choir', gain=0.5, pan=0.05, rev=1.0)
    chb = t.bus('choir_low', gain=0.32, pan=-0.05, rev=1.0)
    bell = t.bus('bell', gain=0.6, pan=-0.2, rev=1.0)
    bsm = t.bus('bell_small', gain=0.22, pan=0.3, rev=1.0, dly=0.6)
    cel = t.bus('celesta', gain=0.2, pan=0.4, rev=1.0, dly=1.0)
    hp = t.bus('harp', gain=0.8, pan=-0.3, rev=1.0)

    ta = seq(TEMPLE_MOTIF, bar=4)
    t.play(ch, ta, inst_choir, vel=0.8, jitter=0.0, vowel='a', attack=0.25, release=0.8)
    t.play(ch, harmonize(ta, pev, 3), inst_choir, vel=0.6, jitter=0.0, vowel='a', attack=0.3, release=0.8)
    TB = ("G5:2 E5:1 G5:1 | A5:2 F#5:1 A5:1 | B5:2 F#5:1 D5:1 | E5:4 | "
          "C6:2 B5:1 A5:1 | G5:2 E5:1 G5:1 | F#5:2 A5:2 | B5:2 F#5:2")
    tb = seq(TB, bar=4, offset=32)
    t.play(solo, tb, inst_organ, vel=0.8, jitter=0.0, attack=0.04, release=0.3)
    for b, d, sym in pev:
        t.chord(org, b, d, open_voicing(sym, 'E2', 5), inst_organ, vel=0.55, attack=0.12, release=0.9)
        if b >= 32:
            t.chord(chb, b, d, open_voicing(sym, 'E3', 4), inst_choir, vel=0.6, vowel='o', attack=0.6,
                    release=1.2)
            # 하프: 차가운 4분음표 분산화음
            v = voicing(sym, 'B3', 4)
            for i in range(4):
                t.play(hp, [(b + i, 1, v[i], '')], inst_harp, vel=0.45 if i else 0.55)
        else:
            t.chord(chb, b, d, [bass_of(sym, 'E2'), bass_of(sym, 'E2') + 7], inst_choir, vel=0.55, vowel='u',
                    attack=0.8, release=1.2)
    # 큰 종 (탑의 종)
    for k, nm, v in [(0, 'E3', 0.9), (4, 'B2', 0.7), (8, 'C3', 0.8), (12, 'E3', 0.9)]:
        t.play(bell, [(t.bar(k), 4, midi(nm), '')], inst_cbell, vel=v, variants=1, T=7.0, lp=2400.0)
    # 작은 종 연타 (프레이즈 끝)
    for k in (7, 15):
        for i, nm in enumerate(['E5', 'D5', 'B4', 'G4', 'E4']):
            t.play(bsm, [(t.bar(k) + i * 0.5, 1, midi(nm), '')], inst_cbell, vel=0.7 - 0.06 * i, variants=1,
                   T=3.0, lp=5000.0)
    # 빛의 거울: 높은 첼레스타가 지연음과 함께 반짝인다 (B 부분)
    for k in range(8, 16):
        sym = prog[k]
        hv = voicing(sym, 'E6', 3)
        for i, idx in enumerate([0, 1, 2, 1]):
            t.play(cel, [(t.bar(k) + 1.5 + i * 0.25, 0.25, hv[idx], '')], inst_celesta, vel=0.5)
    return t.finish(rev_size=0.94, rev_damp=0.35, rev_level=0.5, predelay=0.05,
                    dly_beats=1.5, dly_fb=0.3, dly_level=0.08)


# ---------------------------------------------------------------------------
# temple_dark — 신전 지하 서고 (C단조, 4/4, 56 bpm, 14마디 = 60초)
#   촛불만 흔들리는 조용한 어둠. 신전 동기를 단조로 낮춘 첼레스타, 낮은 오르간, 멀리 웅얼거리는 합창,
#   물방울, 촛불 깜박임 같은 아주 작은 잡음. D♭(나폴리 화음)·#11 로 섬뜩함.
# ---------------------------------------------------------------------------
def track_temple_dark():
    t = Track('temple_dark', bpm=56, bpb=4, bars=14, seed=2001)
    prog = ['Cm', 'Ab', 'Fm', 'G', 'Cm', 'Db', 'G', 'Ab', 'Fm', 'Cm/Eb', 'Db', 'Bbm', 'Gsus4', 'G']
    cel = t.bus('celesta', gain=0.75, pan=0.1, rev=1.0, dly=0.6)
    mb = t.bus('musicbox', gain=0.35, pan=0.35, rev=1.0, dly=0.8)
    gl = t.bus('glass', gain=0.05, pan=-0.3, rev=1.0)
    org = t.bus('organ', gain=0.2, pan=-0.1, rev=1.0)
    ch = t.bus('choir', gain=0.22, pan=0.0, rev=1.0)
    drone = t.bus('drone', gain=0.17, pan=0.0, rev=0.8)
    drip = t.bus('drip', gain=0.3, pan=0.3, rev=1.0, dly=0.8)
    cand = t.bus('candle', gain=0.15, pan=-0.2, rev=0.5)
    bell = t.bus('bell', gain=0.3, pan=-0.25, rev=1.0)
    hp = t.bus('harp', gain=0.7, pan=-0.35, rev=1.0)

    TD = ("G4:1 C5:1 D5:1 Eb5:1 | D5:2 C5:2 | r:1 Ab4:1 C5:1 F5:1 | D5:3 r:1 | Eb5:1 D5:1 C5:1 G4:1 | "
          "Ab4:2 F4:2 | G4:3 r:1 | C5:2 Eb5:2 | Ab5:2 G5:1 F5:1 | G5:3 r:1 | F5:1 Eb5:1 Db5:2 | "
          "Db5:2 Bb4:2 | C5:2 D5:2 | B4:3 r:1")
    td = seq(TD, bar=4)
    t.play(cel, td, inst_celesta, vel=0.75, jitter=0.006, human=0.1)
    t.play(mb, ev_transpose([e for e in td if e[0] >= 28], 12), inst_musicbox, vel=0.5, jitter=0.008)
    for b, nm, d in [(0, 'G5', 8), (20, 'Db6', 8), (36, 'G5', 10)]:
        t.play(gl, [(b, d, midi(nm), '')], inst_glass, vel=0.8, variants=1)
    for k, c in enumerate(prog):
        b0 = t.bar(k)
        t.chord(org, b0, 4, voicing(c, 'G3', 3), inst_organ, vel=0.5, attack=0.4, release=1.0, chiff=0.02)
        t.chord(ch, b0, 4, voicing(c, 'C4', 3), inst_choir, vel=0.5, vowel='u', attack=1.5, release=1.5)
        t.play(hp, [(b0, 2, bass_of(c, 'C2') + 12, '')], inst_harp, vel=0.55)
        if k % 2 == 1:
            t.play(hp, [(b0 + 2.5, 1, bass_of(c, 'C2') + 19, '')], inst_harp, vel=0.3)
    for b in (0, 16, 32, 48):
        t.chord(drone, b, min(16, 56 - b), 'C1 G1 C2', inst_pad, vel=0.6, kind='saw_dark', attack=3.0,
                release=3.0, detune=4.0)
    t.play(bell, [(0.0, 4, midi('C3'), '')], inst_cbell, vel=0.8, variants=1, T=7.0, lp=1500.0)
    t.play(bell, [(t.bar(7), 4, midi('Ab2'), '')], inst_cbell, vel=0.7, variants=1, T=7.0, lp=1500.0)
    # 물방울 (높은 피치카토가 지연음으로 메아리) · 촛불 깜박임
    dropn = notes('C6 G6 Eb6 Bb6')
    for k in range(14):
        if t.rng.random() < 0.5:
            t.play(drip, [(t.bar(k) + t.rng.randrange(8) * 0.5, 0.5, t.rng.choice(dropn), '')], inst_pizz,
                   vel=t.rng.uniform(0.5, 0.9))
        for _ in range(3):
            t.hit(cand, 'shaker', t.bar(k) + t.rng.random() * 4, t.rng.uniform(0.3, 0.8))
    return t.finish(rev_size=0.93, rev_damp=0.5, rev_level=0.5, predelay=0.05,
                    dly_beats=1.5, dly_fb=0.35, dly_level=0.12, master_lp=8500.0)


# ---------------------------------------------------------------------------
# chase — 폭주한 수호자를 피해 첨탑을 오른다 (E단조, 4/4, 168 bpm, 40마디 = 57.1초)
#   쉬지 않는 8분음표 저음 현, 다급한 종(경보), 북. A: 신전 동기(호른) / B: 아우렐리아 동기(트럼펫, 창을 찌르듯
#   솟구치는 분산화음) / C: 프리지안 ♭II(F) 와 금관 찌르기 + 종 / A' / 북 쉼표 4마디
# ---------------------------------------------------------------------------
AURELIA_MOTIF = ("C5:0.5 E5:0.5 G5:0.5 C6:0.5 B5:1 A5:0.5 G5:0.5 | A5:1.5 F#5:0.5 D5:2 | "
                 "B4:0.5 E5:0.5 G5:0.5 B5:0.5 A5:1 G5:0.5 F#5:0.5 | E5:4 | "
                 "C5:0.5 E5:0.5 G5:0.5 C6:0.5 D6:1 C6:0.5 B5:0.5 | A5:1 F#5:1 A5:1 D6:1 | "
                 "B5:2 F#5:2 | D#5:2 F#5:1 B5:1")


def track_chase():
    t = Track('chase', bpm=168, bpb=4, bars=40, seed=2101)
    A = ['Em', 'C', 'D', 'B', 'Em', 'Am', 'C', 'Bsus4']      # 신전 동기의 화성 (temple 과 같은 뼈대)
    prog = (['Em', 'Em', 'C', 'B7'] + A + ['C', 'D', 'Em', 'Em', 'C', 'D', 'B', 'B'] +
            ['Em', 'F', 'Em', 'F', 'Am', 'Bb', 'B', 'B7'] + A + ['Em', 'Em', 'F', 'B7'])
    pev = prog_events(prog, 4)
    hn = t.bus('horns', gain=0.6, pan=-0.15, rev=0.7)
    tp = t.bus('trumpet', gain=0.48, pan=0.15, rev=0.6, dly=0.2)
    lb = t.bus('lowbrass', gain=0.45, pan=-0.05, rev=0.4)
    lo = t.bus('cellos', gain=0.55, pan=-0.2, rev=0.35)
    vn = t.bus('violins', gain=0.56, pan=0.3, rev=0.45)
    ch = t.bus('choir', gain=0.35, pan=0.0, rev=0.9)
    bell = t.bus('bells', gain=0.48, pan=0.3, rev=0.9)
    dr = t.bus('drums', gain=0.36, pan=0.0, rev=0.3)
    hat = t.bus('hat', gain=0.14, pan=0.25, rev=0.2)
    cy = t.bus('cymbal', gain=0.12, pan=0.2, rev=0.5)
    tim = t.bus('timpani', gain=0.45, pan=-0.1, rev=0.5)

    ca = articulate(seq(TEMPLE_MOTIF, bar=4, offset=16), stacc=0.85)
    ca2 = articulate(seq(TEMPLE_MOTIF, bar=4, offset=112), stacc=0.85)
    t.play(hn, ca + ca2, inst_brass, vel=0.85, jitter=0.0, bright=0.75)
    t.play(tp, ev_transpose(ca2, 12), inst_brass, vel=0.6, jitter=0.0, bright=1.0)
    au = articulate(seq(AURELIA_MOTIF, bar=4, offset=48))
    t.play(tp, au, inst_brass, vel=0.9, jitter=0.0, bright=1.2)
    t.play(hn, harmonize(au, pev, 3), inst_brass, vel=0.7, jitter=0.0, bright=0.65)
    # C: 다급한 종 선율 + 금관 찌르기 (3+3+2)
    BELLS = "E5:2 B4:2 | F5:2 C5:2 | E5:2 B4:2 | F5:2 C5:2 | E5:2 A4:2 | F5:2 Bb4:2 | F#5:2 D#5:2 | B4:4"
    t.play(bell, seq(BELLS, bar=4, offset=80), inst_cbell, vel=0.85, jitter=0.0, T=2.6, lp=4500.0)
    for k in range(20, 28):
        b0 = t.bar(k)
        for bt in (0.0, 1.5, 3.0):
            t.chord(hn, b0 + bt, 0.5, voicing(chord_at(pev, b0 + bt), 'E4', 3), inst_brass, vel=0.8,
                    bright=0.9, release=0.08)
    # 서주·끝: 경보 종
    for k in (0, 1, 2, 3, 36, 37, 38, 39):
        for i in range(2):
            nm = {'F': ['F5', 'C5'], 'B7': ['F#5', 'B4']}.get(prog[k], ['E5', 'B4'])[i]
            t.play(bell, [(t.bar(k) + 2 * i, 2, midi(nm), '')], inst_cbell, vel=0.75, jitter=0.0, T=2.6, lp=4500.0)
    t.play(bell, [(0.0, 4, midi('E3'), '')], inst_cbell, vel=0.9, variants=1, T=6.0, lp=2500.0)

    for k, c in enumerate(prog):
        b0 = t.bar(k)
        sym = c.split()[0]
        r = bass_of(sym, 'A2')
        sec = 0 if k < 4 else 1 if k < 12 else 2 if k < 20 else 3 if k < 28 else 4 if k < 36 else 5
        for i, iv in enumerate([0, 0, 12, 0, 7, 0, 12, 7]):
            t.play(lo, [(b0 + i * 0.5, 0.4, r + iv, '')], inst_spicc, vel=0.9 if i % 2 == 0 else 0.6, jitter=0.0)
        t.play(lb, [(b0, 1.8, r - 12, ''), (b0 + 2, 1.8, r - 12, '')], inst_brass, vel=0.6, jitter=0.0,
               variants=1, bright=0.4)
        if sec in (2, 4):
            t.chord(ch, b0, 4, open_voicing(sym, 'E3', 5), inst_choir, vel=0.6, vowel='a', attack=0.2,
                    release=0.6)
        if sec == 4:
            v = voicing(sym, 'E5', 3)
            for i in range(16):
                t.play(vn, [(b0 + i * 0.25, 0.2, v[[0, 1, 2, 1][i % 4]], '')], inst_spicc,
                       vel=0.65 if i % 4 == 0 else 0.42, jitter=0.0)
        elif sec in (1, 2):
            v = voicing(sym, 'B4', 3)
            for i in range(8):
                t.play(vn, [(b0 + i * 0.5, 0.4, v[[0, 1, 2, 1][i % 4]], '')], inst_spicc, vel=0.5, jitter=0.0)
        # --- 타악 ---
        if sec == 0:
            drum_bar(t, dr, b0, 'T.......T.......' if k < 3 else 'T.......ssssssss', 0.9)
        elif sec == 5:
            drum_bar(t, dr, b0, ['T.T.S.T.TT.SS.SS', 'T..T..T.S.S.S.ss', 'T.T.S.T.TT.SS.SS', 'TsTsSsTsoooooooo'][k - 36], 0.95)
        elif sec == 3:
            drum_bar(t, dr, b0, 'T..t..T.S...S.s.', 0.95)
        else:
            drum_bar(t, dr, b0, 'T..s..t.S..sT.s.' if k % 4 != 3 else 'T..s..t.Sssssooo', 0.95)
        if sec in (1, 2, 4):
            for i in range(8):
                t.hit(hat, 'hat', b0 + i * 0.5, 0.7 if i % 2 else 0.45)
        if k in (4, 12, 20, 28):
            t.hit(cy, 'crash', b0, 0.95)
            t.play(tim, [(b0, 1, midi('E2'), '')], inst_timp, vel=0.95)
        elif k % 2 == 0 and sec in (1, 2, 3, 4):
            t.play(tim, [(b0, 1, bass_of(sym, 'E2'), '')], inst_timp, vel=0.6)
    return t.finish(rev_size=0.8, rev_damp=0.45, rev_level=0.2, dly_beats=0.75, dly_fb=0.2,
                    dly_level=0.04, drive=1.4)


# ---------------------------------------------------------------------------
# aurelia — 첨탑 꼭대기, 황금창의 수호자 아우렐리아와의 결전 (E단조, 4/4, 144 bpm, 36마디 = 60초)
#   성스러운 전투: 합창 + 북 + 종. 서주(종 · 합창) 4 + A(아우렐리아 동기, 현 + 합창) 8 +
#   B(신전 동기를 G장조 금관으로 당당하게) 8 + C(대금 · 가야금의 여우 동기 — 세라의 여우신 힘) 8 + A' 8
# ---------------------------------------------------------------------------
def track_aurelia():
    t = Track('aurelia', bpm=144, bpb=4, bars=36, seed=2201)
    A = ['Em', 'C', 'Am', 'B', 'Em', 'C', 'D', 'B']
    prog = (['Em', 'C', 'Am', 'B'] + A + ['G', 'D', 'Em', 'C', 'G', 'D/F#', 'Am', 'B7'] +
            ['Am', 'F', 'Am', 'Em', 'Am', 'F', 'G', 'B7'] + A)
    pev = prog_events(prog, 4)
    ch = t.bus('choir', gain=0.5, pan=0.0, rev=1.0)
    chl = t.bus('choir_low', gain=0.32, pan=-0.05, rev=1.0)
    vn = t.bus('violins', gain=0.63, pan=0.3, rev=0.5)
    lo = t.bus('cellos', gain=0.5, pan=-0.25, rev=0.4)
    tp = t.bus('trumpet', gain=0.5, pan=0.15, rev=0.7, dly=0.2)
    hn = t.bus('horns', gain=0.55, pan=-0.15, rev=0.8)
    dg = t.bus('daegeum', gain=0.4, pan=0.2, rev=0.9)
    gy = t.bus('gayageum', gain=1.25, pan=-0.35, rev=0.6)
    bell = t.bus('bell', gain=0.6, pan=-0.2, rev=1.0)
    bsm = t.bus('bell_small', gain=0.18, pan=0.35, rev=1.0)
    dr = t.bus('drums', gain=0.45, pan=0.0, rev=0.4)
    tim = t.bus('timpani', gain=0.5, pan=-0.1, rev=0.6)
    cy = t.bus('cymbal', gain=0.13, pan=0.2, rev=0.6)

    AU_A = ("B4:0.5 E5:0.5 G5:0.5 B5:0.5 A5:1 G5:0.5 F#5:0.5 | G5:2 E5:2 | "
            "A4:0.5 C5:0.5 E5:0.5 A5:0.5 G5:1 F#5:0.5 E5:0.5 | F#5:2 D#5:2 | "
            "B4:0.5 E5:0.5 G5:0.5 B5:0.5 C6:1 B5:0.5 A5:0.5 | G5:1.5 E5:0.5 C5:2 | "
            "F#5:1 A5:1 D6:1 C6:0.5 A5:0.5 | B5:4")
    AU_CH = "E5:4 | G5:2 E5:2 | E5:4 | D#5:4 | E5:2 G5:2 | G5:2 E5:2 | F#5:2 A5:2 | B5:4"
    for off in (16, 112):
        a = articulate(seq(AU_A, bar=4, offset=off))
        t.play(vn, a, inst_spicc, vel=0.9, jitter=0.0)
        t.play(vn, ev_transpose(a, -12), inst_spicc, vel=0.6, jitter=0.0)
        c = seq(AU_CH, bar=4, offset=off)
        t.play(ch, c, inst_choir, vel=0.85, jitter=0.0, vowel='a', attack=0.15, release=0.6)
        t.play(ch, harmonize(c, pev, 3), inst_choir, vel=0.65, jitter=0.0, vowel='a', attack=0.2, release=0.6)
    t.play(tp, articulate(seq(AU_A, bar=4, offset=112)), inst_brass, vel=0.7, jitter=0.0, bright=1.1)
    AU_B = ("D5:1 G5:1 A5:1 B5:1 | A5:2 F#5:2 | E5:1 G5:1 B5:2 | C6:2 G5:2 | D5:1 G5:1 A5:1 B5:1 | "
            "A5:1.5 G5:0.5 F#5:2 | E5:1 A5:1 C6:2 | B5:2 A5:1 F#5:1")
    ab = articulate(seq(AU_B, bar=4, offset=48))
    t.play(tp, ab, inst_brass, vel=0.9, jitter=0.0, bright=1.15)
    t.play(hn, harmonize(ab, pev, 3), inst_brass, vel=0.75, jitter=0.0, bright=0.6)
    t.play(hn, harmonize(ab, pev, 8), inst_brass, vel=0.6, jitter=0.0, bright=0.5)
    AU_C = ("E5:3w D5:1 | C5:1k A4:3v | A4:1 C5:1 D5:1 E5:1 | G5:2s E5:1 D5:1 | E5:3w D5:1 | "
            "C5:1 A4:1 C5:1 D5:1 | D5:2 G5:2v | F#5:2 D#5:2")
    t.play(dg, seq(AU_C, bar=4, offset=80), inst_wind, vel=0.85, jitter=0.0, attack=0.05, chiff=0.3)
    t.play(hn, ev_transpose([e for e in seq(AU_C, bar=4, offset=80) if e[0] >= 96], -12), inst_brass,
           vel=0.6, jitter=0.0, bright=0.5)

    for k, c in enumerate(prog):
        b0 = t.bar(k)
        sym = c.split()[0]
        r = bass_of(sym, 'A2')
        sec = 0 if k < 4 else 1 if k < 12 else 2 if k < 20 else 3 if k < 28 else 4
        # 첼로 8분음표 (3+3+2)
        for i, iv in enumerate([0, 0, 0, 12, 0, 0, 7, 0]):
            t.play(lo, [(b0 + i * 0.5, 0.4, r + iv, '')], inst_spicc, vel=0.9 if i in (0, 3, 6) else 0.55,
                   jitter=0.0)
        t.chord(chl, b0, 4, open_voicing(sym, 'E2', 4), inst_choir, vel=0.6, vowel='o', attack=0.3, release=0.7)
        if sec == 0:
            t.chord(ch, b0, 4, voicing(sym, 'B4', 3), inst_choir, vel=0.6, vowel='a', attack=0.4, release=0.8)
        if sec == 2:
            v = voicing(sym, 'D5', 3)
            for i in range(16):
                t.play(vn, [(b0 + i * 0.25, 0.2, v[[0, 1, 2, 1][i % 4]], '')], inst_spicc,
                       vel=0.55 if i % 4 == 0 else 0.35, jitter=0.0)
        if sec == 3:
            v = voicing(sym, 'A3', 4)
            for i, idx in enumerate([0, 1, 2, 3, 2, 3, 1, 2]):
                t.play(gy, [(b0 + i * 0.5, 0.5, v[idx] + 12, '')], inst_gayageum, vel=0.6 if i % 4 == 0 else 0.45,
                       ring=0.6)
        # --- 타악 ---
        if sec == 0:
            drum_bar(t, dr, b0, 'B.......t.......' if k < 3 else 'B.......ssssoooo', 0.95)
        elif sec == 3:
            drum_bar(t, dr, b0, 'T.....t.T.......' if k % 4 != 3 else 'T.....t.T...oooo', 0.85)
            t.hit(dr, 'kung', b0 + 1, 0.6)
            t.hit(dr, 'ttak', b0 + 3, 0.5)
        else:
            drum_bar(t, dr, b0, 'T..s..t.S..sT.s.' if k % 4 != 3 else 'T..s..t.Sssssooo', 0.95)
        if k in (4, 12, 20, 28):
            t.hit(cy, 'crash', b0, 0.95)
            t.play(tim, [(b0, 1, midi('E2'), '')], inst_timp, vel=1.0)
        elif k % 2 == 0:
            t.play(tim, [(b0, 1, bass_of(sym, 'E2'), '')], inst_timp, vel=0.6)
        if k in (11, 19, 27, 35):
            timp_roll(t, tim, 'B1', b0 + 2, 2, 0.3, 0.9)
    # 종: 서주는 큰 종이 울리고, A·A' 는 2마디마다, 작은 종 연타
    for k, nm in [(0, 'E3'), (2, 'B2'), (4, 'E3'), (8, 'E3'), (28, 'E3'), (30, 'C3'), (32, 'E3'), (34, 'B2')]:
        t.play(bell, [(t.bar(k), 4, midi(nm), '')], inst_cbell, vel=0.85, variants=1, T=6.0, lp=2600.0)
    for k in (11, 19, 35):
        for i, nm in enumerate(['B5', 'G5', 'E5', 'B4']):
            t.play(bsm, [(t.bar(k) + i * 0.5, 1, midi(nm), '')], inst_cbell, vel=0.7, variants=1, T=2.5, lp=6000.0)
    return t.finish(rev_size=0.88, rev_damp=0.4, rev_level=0.28, predelay=0.03, dly_beats=0.75, dly_fb=0.2,
                    dly_level=0.04, drive=1.4)


# ---------------------------------------------------------------------------
# star_tower — 학교 위, 별의 마녀 리라의 탑 (B 도리안/단조, 3/4, 84 bpm, 28마디 = 60초)
#   첼레스타 · 하프의 반짝임, 우주처럼 넓은 합창 '우'. 아름답지만 불길하다 — 마지막 4마디는 낮은 드론과 종.
# ---------------------------------------------------------------------------
LYRA_A = ("B4:1 F#5:1 G#5:1 | F#5:1.5 E5:0.5 D5:1 | B4:1 D5:1 F#5:1 | B4:1.5 A#4:1.5 | "
          "B4:1 F#5:1 G#5:1 | B5:1.5 A5:0.5 G#5:1 | F#5:1 D5:1 B4:1 | C#5:3")
LYRA_A_PROG = ['Bm', 'E/G#', 'Gmaj7', 'F#sus4 F#', 'Bm', 'E/G#', 'Gmaj7', 'F#']


def track_star_tower():
    t = Track('star_tower', bpm=84, bpb=3, bars=28, seed=2301)
    prog = LYRA_A_PROG + ['Em', 'A', 'Dmaj7', 'Gmaj7', 'C#m7b5', 'F#', 'Bm', 'F#7'] + LYRA_A_PROG + \
        ['Gmaj7', 'F#sus4', 'Bm', 'F#']
    pev = prog_events(prog, 3)
    cel = t.bus('celesta', gain=0.85, pan=0.08, rev=1.0, dly=0.6)
    mb = t.bus('musicbox', gain=0.25, pan=0.35, rev=1.0, dly=0.9)
    hp = t.bus('harp', gain=0.8, pan=-0.3, rev=1.0)
    hpm = t.bus('harp_mel', gain=2.0, pan=-0.1, rev=1.0, dly=0.5)
    ch = t.bus('choir', gain=0.24, pan=0.0, rev=1.0)
    st = t.bus('strings', gain=0.16, pan=0.05, rev=1.0)
    gl = t.bus('glass', gain=0.06, pan=0.4, rev=1.0)
    star = t.bus('stars', gain=0.13, pan=-0.4, rev=1.0, dly=1.0)
    drone = t.bus('drone', gain=0.19, pan=0.0, rev=0.8)
    bell = t.bus('bell', gain=0.3, pan=-0.2, rev=1.0)

    la = seq(LYRA_A, bar=3)
    la2 = seq(LYRA_A, bar=3, offset=48)
    t.play(cel, la + la2, inst_celesta, vel=0.8)
    t.play(mb, ev_transpose(la2, 12), inst_musicbox, vel=0.5)
    SB = ("E5:1 G5:1 B5:1 | C#6:2 A5:1 | F#5:1 A5:1 C#6:1 | B5:2 F#5:1 | E5:1 G5:1 B5:1 | "
          "A#5:2 C#6:1 | D6:1.5 C#6:0.5 B5:1 | A#5:1 C#6:1 E6:1")
    sb = seq(SB, bar=3, offset=24)
    t.play(hpm, sb, inst_harp, vel=0.8)
    t.play(cel, harmonize(sb, pev, 3), inst_celesta, vel=0.45)
    SD = "D6:1.5 B5:1.5 | C#6:3 | B5:1 F#5:1 D5:1 | C#5:3"
    t.play(cel, seq(SD, bar=3, offset=72), inst_celesta, vel=0.6)

    for k, c in enumerate(prog):
        b0 = t.bar(k)
        sym = c.split()[0]
        if k < 24:
            v = voicing(sym, 'B2', 4)
            for i, idx in enumerate([0, 1, 2, 3, 2, 1]):
                t.play(hp, [(b0 + i * 0.5, 0.5, v[idx], '')], inst_harp, vel=0.5 if i == 0 else 0.36)
            t.chord(st, b0, 3, voicing(sym, 'F#3', 3), inst_pad, vel=0.5, attack=0.8, release=1.2)
        t.chord(ch, b0, 3, voicing(sym, 'D4', 3), inst_choir, vel=0.55, vowel='u', attack=1.0, release=1.5)
    # 마지막 4마디: 낮은 드론 + 종 (불길함)
    t.chord(drone, t.bar(24), 12, 'B1 F#2 B2', inst_pad, vel=0.7, kind='saw_dark', attack=2.0, release=3.0)
    t.play(bell, [(t.bar(24), 3, midi('B2'), '')], inst_cbell, vel=0.8, variants=1, T=7.0, lp=2000.0)
    t.play(bell, [(0.0, 3, midi('F#3'), '')], inst_cbell, vel=0.5, variants=1, T=6.0, lp=2000.0)
    for b, nm, d in [(t.bar(8), 'F#6', 9), (t.bar(16), 'B6', 9), (t.bar(24), 'C7', 9)]:
        t.play(gl, [(b, d, midi(nm), '')], inst_glass, vel=0.8, variants=1)
    # 별빛: B 도리안 높은 음이 무작위로 반짝 (첼레스타)
    sc = notes('B5 C#6 D6 E6 F#6 G#6 A6 B6')
    for k in range(28):
        if t.rng.random() < 0.6:
            pos = t.bar(k) + t.rng.randrange(6) * 0.5
            t.play(star, [(pos, 1, t.rng.choice(sc), '')], inst_celesta, vel=t.rng.uniform(0.4, 0.8))
    return t.finish(rev_size=0.93, rev_damp=0.38, rev_level=0.48, predelay=0.04,
                    dly_beats=1.5, dly_fb=0.35, dly_level=0.12, drive=0.8)


def inst_violin(m, dur, flags, seed, **kw):
    """독주 바이올린풍: 관악기 모델에 따뜻한 톱니 파형표 + 아주 작은 활 잡음 + 이른 비브라토."""
    kw.setdefault('breath', 0.012)
    kw.setdefault('chiff', 0.06)
    kw.setdefault('attack', 0.09)
    kw.setdefault('release', 0.25)
    return inst_wind(m, dur, flags, seed, kind='saw', auto_vib=0.45, **kw)


# ---------------------------------------------------------------------------
# lyra — 별의 마녀 리라 (B단조, 4/4, 140 bpm, 36마디 = 61.7초)
#   웅장하고 화려하면서도 씁쓸하다. 서주(하프·첼레스타 질주) 4 + A(별 동기, 현 + 첼레스타) 8 +
#   B(남의 마법을 그대로 베끼는 리라: 제국 → 숲 → 신전 → 학교 동기를 차례로 인용하고, 첼레스타가 반 박 늦게
#   한 옥타브 위에서 그대로 따라 한다) 8 + C(반으로 느려진 듯한 바이올린 독주, 씁쓸함) 8 + A'(총주) 8
# ---------------------------------------------------------------------------
def track_lyra():
    t = Track('lyra', bpm=140, bpb=4, bars=36, seed=2401)
    A = ['Bm', 'E/G#', 'G', 'F#', 'Bm', 'E/G#', 'Em7', 'F#7']
    prog = (['Bm', 'G', 'Em', 'F#'] + A + ['D', 'G', 'D', 'E/D', 'Em', 'C', 'Bm', 'E'] +
            ['G', 'D/F#', 'Em', 'A', 'F#m', 'Bm', 'G', 'F#'] + A)
    pev = prog_events(prog, 4)
    st = t.bus('strings_lead', gain=0.67, pan=0.1, rev=0.8)
    cel = t.bus('celesta', gain=0.55, pan=0.3, rev=1.0, dly=0.5)
    hp = t.bus('harp', gain=1.05, pan=-0.3, rev=0.8)
    lo = t.bus('cellos', gain=0.45, pan=-0.2, rev=0.4)
    pad = t.bus('strings', gain=0.2, pan=0.0, rev=0.9)
    ch = t.bus('choir', gain=0.35, pan=0.0, rev=1.0)
    hn = t.bus('horns', gain=0.5, pan=-0.15, rev=0.8)
    tp = t.bus('trumpet', gain=0.42, pan=0.15, rev=0.7)
    fl = t.bus('flute', gain=0.36, pan=0.2, rev=1.0)
    cl = t.bus('clarinet', gain=0.3, pan=0.12, rev=1.0)
    vs = t.bus('violin_solo', gain=0.45, pan=0.08, rev=1.0, dly=0.3)
    dr = t.bus('drums', gain=0.4, pan=0.0, rev=0.4)
    tim = t.bus('timpani', gain=0.45, pan=-0.1, rev=0.6)
    cy = t.bus('cymbal', gain=0.12, pan=0.2, rev=0.6)

    LY = ("B4:1 F#5:1 G#5:2 | F#5:1.5 E5:0.5 D5:1 B4:1 | D5:1 G5:1 B5:1.5 A5:0.5 | F#5:3 C#5:1 | "
          "B4:1 F#5:1 G#5:1 B5:1 | C#6:1.5 B5:0.5 G#5:1 E5:1 | G5:1 F#5:1 E5:1 D5:1 | C#5:2 A#4:2")
    for off in (16, 112):
        ly = seq(LY, bar=4, offset=off)
        t.play(st, ly, inst_pad, vel=0.8, jitter=0.0, attack=0.06, release=0.3, voices=3, detune=9.0)
        t.play(cel, ev_transpose(ly, 12), inst_celesta, vel=0.6)
    ly2 = seq(LY, bar=4, offset=112)
    t.play(hn, harmonize(ly2, pev, 3), inst_brass, vel=0.7, jitter=0.0, bright=0.6)
    t.play(tp, ly2, inst_brass, vel=0.65, jitter=0.0, bright=0.9)
    # 서주: 호른이 별 동기 머리를 낮게
    t.play(hn, seq("r:4 | r:4 | B3:1 F#4:1 G#4:2 | F#4:4", bar=4), inst_brass, vel=0.85, jitter=0.0, bright=0.6)
    # B: 인용 (제국 → 숲 → 신전 → 학교), 첼레스타가 반 박 늦게 옥타브 위에서 흉내
    q_k = articulate(seq("A4:0.75 A4:0.25 D5:1 F#5:1 A5:1 | B5:1.5 A5:0.5 G5:1 D5:1", bar=4, offset=48),
                     short=0.75, stacc=0.8)
    q_e = seq("A4:1 D5:1 E5:1 F#5:1 | G#5:2 F#5:1 E5:1", bar=4, offset=56)
    q_t = seq("B4:1 E5:1 F#5:1 G5:1 | F#5:2 E5:2", bar=4, offset=64)
    q_s = articulate(seq("r:1 F#4:0.5 B4:0.5 D5:1 C#5:0.5 B4:0.5 | G#4:1.5 E4:0.5 G#4:1 B4:1", bar=4, offset=72))
    t.play(tp, q_k, inst_brass, vel=0.9, jitter=0.0, bright=1.1)
    t.play(fl, q_e, inst_flute, vel=0.85, jitter=0.0)
    t.play(ch, q_t, inst_choir, vel=0.9, jitter=0.0, vowel='a', attack=0.15, release=0.5)
    t.play(ch, harmonize(q_t, pev, 3), inst_choir, vel=0.7, jitter=0.0, vowel='a', attack=0.15, release=0.5)
    t.play(cl, q_s, inst_wind, vel=0.85, jitter=0.0, kind='clar', breath=0.035, attack=0.03, release=0.08,
           chiff=0.12)
    copy = [(b + 0.5, d, m + 12, f) for (b, d, m, f) in q_k + q_e + q_t + q_s]
    t.play(cel, copy, inst_celesta, vel=0.5)
    # C: 바이올린 독주 (씁쓸하게)
    LC = "B5:3 A5:1 | F#5:3 D5:1 | G5:2 F#5:1 E5:1 | E5:4 | A5:2 C#6:1 B5:1 | B5:2 F#5:2 | G5:1 A5:1 B5:1 D6:1 | C#6:4"
    t.play(vs, seq(LC, bar=4, offset=80), inst_violin, vel=0.85, jitter=0.0)

    for k, c in enumerate(prog):
        b0 = t.bar(k)
        sym = c.split()[0]
        sec = 0 if k < 4 else 1 if k < 12 else 2 if k < 20 else 3 if k < 28 else 4
        r = bass_of(sym, 'A2')
        # 하프: 서주·A·A' 는 16분음표 질주, B·C 는 8분음표
        v = voicing(sym, 'B3', 5)
        if sec in (0, 1, 4):
            for i, idx in enumerate([0, 1, 2, 3, 4, 3, 2, 1, 0, 1, 2, 3, 4, 3, 2, 1]):
                t.play(hp, [(b0 + i * 0.25, 0.25, v[idx], '')], inst_harp, vel=0.5 if i % 4 == 0 else 0.36)
        else:
            for i, idx in enumerate([0, 2, 4, 2, 1, 3, 4, 3]):
                t.play(hp, [(b0 + i * 0.5, 0.5, v[idx], '')], inst_harp, vel=0.45 if i % 4 == 0 else 0.33)
        if sec == 3:
            t.play(lo, [(b0, 2, r, ''), (b0 + 2, 2, r + 7, '')], inst_pizz, vel=0.8)
        else:
            for i, iv in enumerate([0, 0, 12, 0, 0, 12, 7, 12]):
                t.play(lo, [(b0 + i * 0.5, 0.4, r + iv, '')], inst_spicc, vel=0.8 if i % 2 == 0 else 0.5,
                       jitter=0.0)
        t.chord(pad, b0, 4, voicing(sym, 'D4', 3), inst_pad, vel=0.5, attack=0.4, release=0.8)
        if sec in (0, 4):
            t.chord(ch, b0, 4, open_voicing(sym, 'B2', 5), inst_choir, vel=0.55, vowel='a', attack=0.3, release=0.8)
        # --- 타악 ---
        if sec == 0:
            drum_bar(t, dr, b0, 'T.......t.......' if k < 3 else 'T.......ssssoooo', 0.85)
        elif sec == 2:
            drum_bar(t, dr, b0, 'T.......S.......', 0.7)
        elif sec == 3:
            drum_bar(t, dr, b0, 'T...............', 0.55)
        else:
            drum_bar(t, dr, b0, 'T..s..t.S..sT.s.' if k % 4 != 3 else 'T..s..t.Sssssooo', 0.9)
        if k in (4, 28):
            t.hit(cy, 'crash', b0, 0.95)
            t.play(tim, [(b0, 1, midi('B1'), '')], inst_timp, vel=1.0)
        elif k % 2 == 0 and sec != 3:
            t.play(tim, [(b0, 1, bass_of(sym, 'F#1') + 12, '')], inst_timp, vel=0.55)
        if k in (27,):
            timp_roll(t, tim, 'F#2', b0, 4, 0.2, 0.95)
    # 서주: 첼레스타가 B 단조 음계를 위아래로 질주 (가상악기 같은 화려함)
    run = scale_run('B4', 'B6', {11, 1, 2, 4, 6, 7, 9})
    gliss(t, cel, 0.0, run + run[::-1][1:], 0.25, inst_celesta, vel=0.45)
    return t.finish(rev_size=0.86, rev_damp=0.4, rev_level=0.26, predelay=0.03, dly_beats=0.75, dly_fb=0.2,
                    dly_level=0.05, drive=1.2)


# ---------------------------------------------------------------------------
# despair — 거대한 흰 외신들의 행진, 무너지는 학교 (C단조, 4/4, 48 bpm, 12마디 = 60초)
#   절망: 짓누르는 저음 드론, 2박마다 땅을 울리는 거대한 '발소리'(서브 저음 + 돌 부스러기),
#   멀리서 들리는 합창의 하행 탄식, 외신의 높은 유리음, 장례의 종.
# ---------------------------------------------------------------------------
def track_despair():
    t = Track('despair', bpm=48, bpb=4, bars=12, seed=2501, tail=12.0)
    prog = ['Cm', 'Gm/Bb', 'Ab', 'G', 'Fm', 'Db', 'Ab/C', 'G', 'Cm', 'Db', 'Cm', 'G7sus4']
    step = t.bus('footsteps', gain=0.62, pan=0.0, rev=0.6)
    deb = t.bus('debris', gain=0.45, pan=0.2, rev=0.7)
    drone = t.bus('drone', gain=0.32, pan=0.0, rev=0.7)
    lb = t.bus('lowbrass', gain=0.42, pan=-0.1, rev=0.8)
    hn = t.bus('horns', gain=0.36, pan=0.15, rev=1.0)
    ch = t.bus('choir', gain=0.3, pan=0.0, rev=1.0)
    chs = t.bus('choir_sop', gain=0.3, pan=0.1, rev=1.0)
    gl = t.bus('glass', gain=0.08, pan=0.35, rev=1.0)
    bell = t.bus('bell', gain=0.35, pan=-0.3, rev=1.0)
    rum = t.bus('rumble', gain=0.25, pan=0.0, rev=0.4)
    tim = t.bus('timpani', gain=0.4, pan=-0.1, rev=0.8)

    for k in range(12):
        for bt in (0, 2):
            t.hit(step, 'boom', t.bar(k) + bt, 1.0 if bt == 0 else 0.85)
            t.hit(step, 'btaiko', t.bar(k) + bt + 0.02, 0.5)
            t.hit(deb, 'debris', t.bar(k) + bt + 0.08, 0.9)
    for b in (0, 16, 32):
        t.chord(drone, b, 16, 'C1 G1 C2', inst_pad, vel=0.7, kind='saw_dark', attack=3.0, release=4.0, detune=6.0)
        t.chord(drone, b, 16, [25.2], inst_pad, vel=0.35, kind='saw_dark', attack=4.0, release=4.0, detune=12.0)
        t.play(rum, [(b, 16, 40, '')], inst_wind_noise, vel=1.0, jitter=0.0, variants=1)
    LB = "C3:4 | Bb2:4 | Ab2:4 | G2:4 | F2:4 | Db3:4 | C3:4 | B2:4 | C3:2 Eb3:2 | Db3:4 | C3:2 G2:2 | G2:4"
    t.play(lb, seq(LB, bar=4), inst_brass, vel=0.8, jitter=0.0, bright=0.35, attack=0.4, release=1.0)
    t.play(lb, ev_transpose(seq(LB, bar=4), -12), inst_brass, vel=0.55, jitter=0.0, bright=0.3, attack=0.4,
           release=1.0)
    HN = "r:4 | r:4 | r:4 | r:4 | Ab3:2 G3:2 | F3:4 | Eb3:2 F3:2 | D3:4 | G3:2 Ab3:2 | F3:4 | Eb3:2 D3:2 | D3:4"
    t.play(hn, seq(HN, bar=4), inst_brass, vel=0.85, jitter=0.0, bright=0.45, attack=0.25, release=0.8)
    SOP = "Eb5:4 | D5:4 | C5:4 | B4:4 | C5:2 Ab4:2 | F4:4 | Eb4:4 | D4:4 | G4:4 | Ab4:4 | G4:4 | F4:2 G4:2"
    t.play(chs, seq(SOP, bar=4), inst_choir, vel=0.8, jitter=0.0, vowel='o', attack=1.2, release=2.0)
    for k, c in enumerate(prog):
        t.chord(ch, t.bar(k), 4, open_voicing(c, 'C3', 4), inst_choir, vel=0.6, vowel='o', attack=1.5, release=2.0)
    for b, nm, d in [(16, 'C6', 12), (20, 'Db6', 12), (32, 'G6', 14), (36, 'Ab6', 10)]:
        t.play(gl, [(b, d, midi(nm), '')], inst_glass, vel=0.8, variants=1, beat_hz=1.3)
    t.play(bell, [(0.0, 4, midi('C3'), '')], inst_cbell, vel=0.9, variants=1, T=8.0, lp=1600.0)
    t.play(bell, [(t.bar(6), 4, midi('C3'), '')], inst_cbell, vel=0.75, variants=1, T=8.0, lp=1600.0)
    for k in (3, 7, 11):
        timp_roll(t, tim, 'G2', t.bar(k) + 2, 2, 0.2, 0.9, step=0.1)
    return t.finish(rev_size=0.95, rev_damp=0.45, rev_level=0.5, predelay=0.06, dly_beats=1.0, dly_fb=0.2,
                    dly_level=0.0, master_lp=7500.0, drive=0.5)


# ---------------------------------------------------------------------------
# nine_tails — 아홉 꼬리를 되찾다 (A 계면조 → A장조, 12/8, 점4분 = 76 bpm, 20마디 = 63.2초)
#   신계 주제 가야금 독주로 조용히 시작 → 대금 · 현 패드 → 오스티나토와 팀파니 롤로 차오름 →
#   A장조 총주(가야금 · 대금 · 장구 + 서양 관현악 · 합창)로 터진다 → 마지막 마디는 가야금만 남아 처음으로.
# ---------------------------------------------------------------------------
def track_nine_tails():
    t = Track('nine_tails', bpm=76, bpb=4, bars=20, seed=2601)
    U = 1.0 / 3.0
    prog = ['Am', 'Am', 'Am', 'Am', 'Am', 'F', 'C', 'G', 'F', 'G', 'E7sus4', 'E7',
            'A', 'F#m', 'D', 'E', 'A', 'D E', 'A', 'Asus4']
    pev = prog_events(prog, 4)
    gy = t.bus('gayageum', gain=1.25, pan=-0.2, rev=0.9, dly=0.3)
    dg = t.bus('daegeum', gain=0.5, pan=0.2, rev=1.0)
    st = t.bus('strings', gain=0.26, pan=0.05, rev=0.9)
    vn = t.bus('violins', gain=0.5, pan=0.3, rev=0.6)
    lo = t.bus('cellos', gain=0.38, pan=-0.2, rev=0.5)
    ch = t.bus('choir', gain=0.36, pan=0.0, rev=1.0)
    tp = t.bus('trumpet', gain=0.5, pan=0.15, rev=0.8)
    hn = t.bus('horns', gain=0.48, pan=-0.15, rev=0.9)
    drone = t.bus('drone', gain=0.2, pan=0.0, rev=1.0)
    jg = t.bus('janggu', gain=0.42, pan=0.2, rev=0.4)
    dr = t.bus('drums', gain=0.42, pan=0.0, rev=0.5)
    tim = t.bus('timpani', gain=0.45, pan=-0.1, rev=0.6)
    cy = t.bus('cymbal', gain=0.12, pan=0.25, rev=0.6)

    # 1) 가야금 독주 — 신계 주제
    G1 = ("E4:9w D4:3 | C4:3k A3:9v | r:3 A3:2 C4:1 D4:3 E4:3 | G4:3s E4:3 D4:2 C4:1k A3:3")
    t.play(gy, seq(G1, U, 12), inst_gayageum, vel=1.3)
    t.chord(drone, 0, 32, 'A2 E3', inst_pad, vel=0.5, kind='saw_dark', attack=3.0, release=3.0, detune=5.0)
    # 2) 대금 + 현 패드 + 가야금 반주
    D2 = "E5:9w D5:3 | C5:3k A4:9v | r:3 A4:2 C5:1 D5:3 E5:3 | G5:3s E5:3 D5:6v"
    t.play(dg, seq(D2, U, 12, offset=16), inst_wind, vel=0.8, jitter=0.0)
    # 3) 차오름: 호른이 여우 동기를 넓게, 가야금 8분음표 오스티나토
    H3 = "A3:6 C4:6 | D4:6 E4:6 | G4:6 E4:6 | E4:12"
    t.play(hn, seq(H3, U, 12, offset=32), inst_brass, vel=0.8, jitter=0.0, bright=0.55, attack=0.12)
    t.play(dg, seq("r:6 E5:6v | r:6 G5:6v | A5:12w | B5:6 G#5:6", U, 12, offset=32), inst_wind, vel=0.75,
           jitter=0.0)
    # 4) A장조 총주: 여우 동기 장조 변형 (트럼펫 + 대금 옥타브)
    T4 = ("E5:9 D5:3 | C#5:3 A4:9 | r:3 A4:2 C#5:1 D5:3 E5:3 | G#5:3 E5:3 D5:2 C#5:1 B4:3 | "
          "A5:9 E5:3 | F#5:6 G#5:6 | A5:12")
    t4 = seq(T4, U, 12, offset=48)
    t.play(tp, t4, inst_brass, vel=0.9, jitter=0.0, bright=1.1)
    t.play(hn, harmonize(t4, pev, 3), inst_brass, vel=0.72, jitter=0.0, bright=0.6)
    t.play(dg, [(b, d, m + 12, 'v' if d >= 1.5 else '') for (b, d, m, f) in t4], inst_wind, vel=0.55, jitter=0.0)
    # 5) 마지막 마디: 가야금만 남아 처음으로 이어짐
    t.play(gy, seq("A4:6v r:3 E4:3", U, 12, offset=76), inst_gayageum, vel=0.75)

    for k, c in enumerate(prog):
        b0 = t.bar(k)
        sym = c.split()[0]
        r = bass_of(sym, 'A1')
        if 4 <= k < 8:
            v = voicing(sym, 'A3', 4)
            for i, idx in enumerate([0, 1, 2, 3, 2, 1]):
                t.play(gy, [(b0 + i * 2 * U, 2 * U, v[idx], '')], inst_gayageum, vel=0.42, ring=1.2)
            t.chord(st, b0, 4, voicing(sym, 'E3', 4), inst_pad, vel=0.5, attack=1.2, release=1.2)
            t.play(lo, [(b0, 4, r + 12, '')], inst_pad, vel=0.5, jitter=0.0, variants=1, kind='saw', attack=0.8,
                   release=1.0)
            t.hit(dr, 'buk', b0, 0.55)
        elif 8 <= k < 19:
            # 가야금 8분음표 오스티나토 (강세 3·3·3·3), 현 · 첼로
            v = voicing(sym, 'A3', 4)
            for i, idx in enumerate([0, 1, 2, 3, 2, 1, 0, 1, 2, 3, 2, 1]):
                t.play(gy, [(b0 + i * U, U, v[idx] + (12 if k >= 12 else 0), '')], inst_gayageum,
                       vel=0.7 if i % 3 == 0 else 0.45, ring=0.5)
            t.chord(st, b0, 4, voicing(sym, 'E3', 4), inst_pad, vel=0.5 + 0.03 * (k - 8), attack=0.4, release=0.8)
            for i in range(4):
                t.play(lo, [(b0 + i, 0.6, r + 12, ''), (b0 + i + 2 * U, 0.3, r + 12, '')], inst_spicc, vel=0.7,
                       jitter=0.0)
            if k >= 12:
                vv = voicing(sym, 'C#5', 3)
                for i in range(12):
                    t.play(vn, [(b0 + i * U, U * 0.9, vv[[0, 1, 2][i % 3]], '')], inst_spicc,
                           vel=0.6 if i % 3 == 0 else 0.4, jitter=0.0)
            sy_list = [(b, d, s) for (b, d, s) in pev if b0 <= b < b0 + 4]
            for sb, sd, sy in sy_list:
                t.chord(ch, sb, sd, open_voicing(sy, 'A2', 5), inst_choir, vel=0.4 + (0.3 if k >= 12 else 0.03 * (k - 8)),
                        vowel='a', attack=0.6 if k < 12 else 0.2, release=1.0)
        # --- 타악 ---
        if 8 <= k < 12:
            t.hit(dr, 'buk', b0, 0.6 + 0.08 * (k - 8))
            t.hit(dr, 'buk', b0 + 2, 0.5 + 0.08 * (k - 8))
            t.pattern(jg, b0, 'K..K..K..K..' if k < 10 else 'D.tK.TK.tK.T', U,
                      {'D': [('kung', 0.9), ('ttak', 0.7)], 'K': [('kung', 0.7)], 'T': [('ttak', 0.7)],
                       't': [('ttak', 0.4)]})
        if k == 11:
            timp_roll(t, tim, 'E2', b0, 4, 0.2, 1.0, step=1.0 / 6.0)
            roll(t, dr, 'sroll', b0 + 2, 2, 1.0 / 6.0, 0.2, 0.9)
        if 12 <= k < 19:
            t.hit(dr, 'btaiko', b0, 1.0)
            t.hit(dr, 'taiko', b0 + 2, 0.8)
            t.pattern(jg, b0, 'D.tK.TD.tDTT' if k % 2 else 'D.tK.TK.tK.T', U,
                      {'D': [('kung', 0.9), ('ttak', 0.75)], 'K': [('kung', 0.8)], 'T': [('ttak', 0.75)],
                       't': [('ttak', 0.4)]})
            t.play(tim, [(b0, 1, bass_of(sym, 'E2'), '')], inst_timp, vel=0.8)
            if k in (12, 16, 18):
                t.hit(cy, 'crash', b0, 1.0)
    return t.finish(rev_size=0.88, rev_damp=0.4, rev_level=0.3, predelay=0.03, dly_beats=2.0 / 3.0, dly_fb=0.2,
                    dly_level=0.05, drive=1.6)


# ---------------------------------------------------------------------------
# final — 하늘 문에서의 마지막 싸움 (D단조 → D장조, 4/4, 150 bpm, 40마디 = 64초) · 가장 웅장한 곡
#   서주 4 (학교 동기 머리 팡파르) + A(학교 동기, D단조 총주) 8 + B(여우 동기, 대금 + 호른) 8 +
#   C(동료들: 제국 → 숲 → 신전 → 별 동기 2마디씩) 8 + D(D장조, 학교 동기 + 가야금 · 합창 절정) 8 +
#   끝(단조로 돌아와 처음으로) 4
# ---------------------------------------------------------------------------
def track_final():
    t = Track('final', bpm=150, bpb=4, bars=40, seed=2701)
    prog = (['Dm', 'Bb', 'C', 'A7'] + SCHOOL_MOTIF_PROG + ['Dm', 'Bb', 'F', 'C', 'Dm', 'Bb', 'Gm', 'A'] +
            ['F', 'Bb', 'F', 'G/F', 'Dm', 'Bb', 'Dm', 'A7'] +
            ['D', 'G', 'D', 'Em7', 'F#m', 'A7', 'G', 'A'] + ['Bb', 'C', 'Dm', 'A7'])
    pev = prog_events(prog, 4)
    tp = t.bus('trumpet', gain=0.48, pan=0.15, rev=0.7, dly=0.15)
    hn = t.bus('horns', gain=0.55, pan=-0.15, rev=0.8)
    lb = t.bus('lowbrass', gain=0.66, pan=-0.05, rev=0.5)
    ch = t.bus('choir', gain=0.4, pan=0.0, rev=1.0)
    vn = t.bus('violins', gain=0.4, pan=0.3, rev=0.5)
    lo = t.bus('cellos', gain=0.48, pan=-0.25, rev=0.4)
    dg = t.bus('daegeum', gain=0.45, pan=0.22, rev=0.9)
    gy = t.bus('gayageum', gain=1.0, pan=-0.35, rev=0.6)
    fl = t.bus('flute', gain=0.3, pan=0.25, rev=1.0)
    cel = t.bus('celesta', gain=0.3, pan=0.35, rev=1.0, dly=0.4)
    dr = t.bus('drums', gain=0.3, pan=0.0, rev=0.4)
    jg = t.bus('janggu', gain=0.3, pan=0.2, rev=0.4)
    tim = t.bus('timpani', gain=0.45, pan=-0.1, rev=0.6)
    cy = t.bus('cymbal', gain=0.13, pan=0.2, rev=0.6)

    # 서주: 학교 동기 머리(5-1-3)를 화음마다 쌓아 올리는 팡파르
    IN = "r:1 A4:0.5 D5:0.5 F5:2 | r:1 F4:0.5 Bb4:0.5 D5:2 | r:1 G4:0.5 C5:0.5 E5:2 | C#5:2 E5:1 A5:1"
    inn = seq(IN, bar=4)
    t.play(tp, inn, inst_brass, vel=0.9, jitter=0.0, bright=1.1)
    t.play(hn, harmonize(inn, pev, 3), inst_brass, vel=0.75, jitter=0.0, bright=0.6)
    # A: 학교 동기 (D단조), 호른 + 트럼펫 옥타브
    sa = articulate(seq(SCHOOL_MOTIF, bar=4, offset=16), stacc=0.85)
    t.play(hn, ev_transpose(sa, -12), inst_brass, vel=0.85, jitter=0.0, bright=0.7)
    t.play(tp, sa, inst_brass, vel=0.85, jitter=0.0, bright=1.1)
    # B: 여우 동기 (D 계면조풍으로 옮김) — 대금 + 호른 한 옥타브 아래
    FX = "A5:3w G5:1 | F5:1k D5:3v | D5:1 F5:1 G5:1 A5:1 | C6:2s A5:1 G5:1 | A5:3w G5:1 | " \
         "F5:1 D5:1 F5:1 G5:1 | G5:2 Bb5:2 | A5:2 C#6:2"
    fx = seq(FX, bar=4, offset=48)
    t.play(dg, fx, inst_wind, vel=0.85, jitter=0.0, attack=0.05, chiff=0.3)
    t.play(hn, ev_transpose([(b, d, m, '') for (b, d, m, f) in fx], -12), inst_brass, vel=0.7, jitter=0.0,
           bright=0.55)
    # C: 동료들의 동기 2마디씩
    ck = articulate(seq("C5:0.75 C5:0.25 F5:1 A5:1 C6:1 | D6:1.5 C6:0.5 Bb5:1 F5:1", bar=4, offset=80),
                    short=0.75, stacc=0.8)
    ce = seq("C5:1 F5:1 G5:1 A5:1 | B5:2 A5:1 G5:1", bar=4, offset=88)
    ctm = seq("A4:1 D5:1 E5:1 F5:1 | E5:2 D5:2", bar=4, offset=96)
    cl = seq("D5:1 A5:1 B5:2 | A5:1.5 G5:0.5 E5:1 C#5:1", bar=4, offset=104)
    t.play(tp, ck, inst_brass, vel=0.9, jitter=0.0, bright=1.15)
    t.play(hn, harmonize(ck, pev, 3), inst_brass, vel=0.7, jitter=0.0, bright=0.6)
    t.play(fl, ce, inst_flute, vel=0.9, jitter=0.0)
    t.play(ch, ctm, inst_choir, vel=0.9, jitter=0.0, vowel='a', attack=0.12, release=0.5)
    t.play(ch, harmonize(ctm, pev, 3), inst_choir, vel=0.7, jitter=0.0, vowel='a', attack=0.12, release=0.5)
    t.play(cel, cl + ev_transpose(cl, 12), inst_celesta, vel=0.8)
    t.play(vn, cl, inst_pad, vel=0.6, jitter=0.0, attack=0.06, release=0.3, voices=3, detune=9.0)
    # D: D장조 학교 동기 — 트럼펫 + 호른 화성, 대금이 옥타브 위에서 겹침 (뒤 4마디)
    sd = articulate(seq(SCHOOL_DAY_A, bar=4, offset=112), stacc=0.85)
    t.play(tp, sd, inst_brass, vel=0.95, jitter=0.0, bright=1.2)
    t.play(hn, harmonize(sd, pev, 3), inst_brass, vel=0.75, jitter=0.0, bright=0.6)
    t.play(dg, ev_transpose([e for e in sd if e[0] >= 128], 12), inst_wind, vel=0.6, jitter=0.0, attack=0.04)
    # 끝: 단조로 돌아오며 첼로·호른 하행
    OUT = "F5:2 D5:2 | G5:2 E5:2 | A5:3 F5:1 | E5:2 C#5:2"
    ot = seq(OUT, bar=4, offset=144)
    t.play(tp, ot, inst_brass, vel=0.85, jitter=0.0, bright=1.0)
    t.play(hn, harmonize(ot, pev, 3), inst_brass, vel=0.7, jitter=0.0, bright=0.55)

    for k, c in enumerate(prog):
        b0 = t.bar(k)
        sym = c.split()[0]
        r = bass_of(sym, 'A2')
        sec = 0 if k < 4 else 1 if k < 12 else 2 if k < 20 else 3 if k < 28 else 4 if k < 36 else 5
        for i, iv in enumerate([0, 0, 0, 12, 0, 0, 7, 0]):
            t.play(lo, [(b0 + i * 0.5, 0.4, r + iv, '')], inst_spicc, vel=0.9 if i in (0, 3, 6) else 0.55,
                   jitter=0.0)
        t.play(lb, [(b0, 1.8, r - 12, ''), (b0 + 2, 1.8, bass_of(chord_at(pev, b0 + 2), 'A2') - 12, '')],
               inst_brass, vel=0.65, jitter=0.0, variants=1, bright=0.45)
        if sec in (0, 1, 4, 5):
            for sb, sd_, sy in [(b, d, s) for (b, d, s) in pev if b0 <= b < b0 + 4]:
                t.chord(ch, sb, sd_, open_voicing(sy, 'A2', 5), inst_choir, vel=0.6, vowel='a', attack=0.2,
                        release=0.6)
        if sec in (1, 4):
            v = voicing(sym, 'D5', 3)
            for i in range(16):
                t.play(vn, [(b0 + i * 0.25, 0.2, v[[0, 1, 2, 1][i % 4]], '')], inst_spicc,
                       vel=0.6 if i % 4 == 0 else 0.4, jitter=0.0)
        if sec in (2, 4):
            v = voicing(sym, 'A3', 4)
            for i, idx in enumerate([0, 1, 2, 3, 2, 3, 1, 2, 0, 1, 2, 3, 2, 3, 1, 2]):
                t.play(gy, [(b0 + i * 0.25, 0.25, v[idx] + 12, '')], inst_gayageum, vel=0.5 if i % 4 == 0 else 0.36,
                       ring=0.4, jitter=0.0)
        if sec == 3:
            t.chord(vn, b0, 4, voicing(sym, 'F4', 3), inst_pad, vel=0.4, attack=0.2, release=0.5)
        # --- 타악 ---
        if sec == 0:
            drum_bar(t, dr, b0, 'B.....t.T.......' if k < 3 else 'B.....t.Sssssooo', 0.95)
        elif sec == 2:
            drum_bar(t, dr, b0, 'T..s..t.S..sT.s.' if k % 4 != 3 else 'T..s..t.Sssssooo', 0.9)
            t.pattern(jg, b0, 'D..T..D.T.T.tTt.', 0.25,
                      {'D': [('kung', 0.9), ('ttak', 0.7)], 'T': [('ttak', 0.7)], 't': [('ttak', 0.35)]})
        elif sec == 3:
            drum_bar(t, dr, b0, 'T.......S.......' if k % 2 == 0 else 'T.....t.S...S.s.', 0.85)
        elif sec == 5:
            drum_bar(t, dr, b0, ['B..s..t.S..sB.s.', 'B..s..t.S..sB.s.', 'B.T.S.T.BB.SS.SS', 'BsTsSsTsoooooooo'][k - 36], 1.0)
        else:
            drum_bar(t, dr, b0, 'B..s..t.S..sT.S.' if k % 4 != 3 else 'B..s..t.SsssoooT', 1.0)
        if k in (4, 12, 20, 28, 36):
            t.hit(cy, 'crash', b0, 1.0)
            t.play(tim, [(b0, 1, midi('D2'), '')], inst_timp, vel=1.0)
        elif k % 2 == 0:
            t.play(tim, [(b0, 1, bass_of(sym, 'F2'), '')], inst_timp, vel=0.6)
        if sec == 4 and k % 2 == 1:
            t.hit(cy, 'crash', b0, 0.55)
        if k == 27:
            timp_roll(t, tim, 'A2', b0, 4, 0.2, 1.0)
    return t.finish(rev_size=0.86, rev_damp=0.42, rev_level=0.25, predelay=0.03, dly_beats=0.75, dly_fb=0.2,
                    dly_level=0.04, drive=1.5)


# ---------------------------------------------------------------------------
# ending2 — 에필로그 · 엔딩 크레디트 (D장조, 3/4, 80 bpm, 40마디 = 90초)
#   타이틀 자장가(첼레스타) → 학교 동기(플루트) → 여우 동기(대금 · 가야금) → 별 동기를 장조의 희망으로(호른) →
#   자장가 절정을 모두가 함께(현 · 합창 · 호른). 따뜻하고 그리운, 그래도 앞을 보는 끝.
# ---------------------------------------------------------------------------
def track_ending2():
    t = Track('ending2', bpm=80, bpb=3, bars=40, seed=2801)
    prog = (['D', 'Gadd9', 'D/F#', 'A', 'D', 'Bm9', 'Em7', 'A7'] +
            ['D', 'G', 'D', 'Em7', 'D/F#', 'A7', 'Bm', 'Asus4 A'] +
            ['Bm', 'G', 'Em', 'D', 'A', 'Bm', 'G', 'A'] +
            ['E', 'D', 'Bm', 'A', 'E', 'E/G#', 'D', 'A'] +
            ['D', 'G', 'D/F#', 'A', 'Bm', 'A', 'Dmaj7', 'A7'])
    pev = prog_events(prog, 3)
    cel = t.bus('celesta', gain=0.8, pan=0.08, rev=1.0, dly=0.5)
    fl = t.bus('flute', gain=0.5, pan=0.18, rev=1.0, dly=0.4)
    cl = t.bus('clarinet', gain=0.2, pan=-0.12, rev=1.0)
    dg = t.bus('daegeum', gain=0.45, pan=0.22, rev=1.0)
    gy = t.bus('gayageum', gain=1.1, pan=-0.35, rev=1.0)
    hn = t.bus('horn', gain=0.75, pan=-0.1, rev=1.0)
    vs = t.bus('strings_mel', gain=0.56, pan=0.05, rev=1.0)
    hp = t.bus('harp', gain=1.05, pan=-0.3, rev=1.0)
    pad = t.bus('strings', gain=0.24, pan=0.0, rev=1.0)
    ch = t.bus('choir', gain=0.26, pan=0.0, rev=1.0)
    bass = t.bus('pizz', gain=0.5, pan=0.0, rev=0.5)
    gl = t.bus('glock', gain=0.16, pan=0.4, rev=1.0, dly=1.0)

    tm = title_melody()
    m_hi = ev_map(tm, midi('A4'), midi('D5'), _MINOR_TO_MAJOR)
    m_lo = ev_map(tm, midi('A4'), midi('D4'), _MINOR_TO_MAJOR)
    # A (1~8): 자장가 A 부분 — 첼레스타
    t.play(cel, [e for e in m_hi if e[0] < 24], inst_celesta, vel=0.8)
    # B (9~16): 학교 동기 3/4 변형 — 플루트, 클라리넷이 3도 아래
    SB = ("A4:0.5 D5:0.5 F#5:1 E5:0.5 D5:0.5 | B4:1.5 G4:0.5 B4:1 | C#5:0.5 D5:0.5 F#5:1 A5:1 | "
          "G5:1.5 F#5:0.5 E5:1 | D5:0.5 E5:0.5 F#5:1 E5:0.5 F#5:0.5 | G5:1.5 E5:0.5 C#5:1 | "
          "D5:1 E5:1 F#5:1 | A5:2 r:1")
    sb = articulate(seq(SB, bar=3, offset=24))
    t.play(fl, sb, inst_flute, vel=0.8, jitter=0.0)
    t.play(cl, harmonize(sb, pev, 3), inst_wind, vel=0.75, jitter=0.0, kind='clar', breath=0.035,
           attack=0.04, release=0.1, chiff=0.1, auto_vib=0.8)
    # C (17~24): 여우 동기 — 대금
    SC = "F#5:2w E5:1 | D5:1k B4:2v | B4:1 D5:1 E5:1 | F#5:1 A5:1 F#5:1 | E5:2w D5:1 | B4:3v | A4:1 B4:1 D5:1 | E5:3w"
    t.play(dg, seq(SC, bar=3, offset=48), inst_wind, vel=0.8, jitter=0.0, breath=0.07, attack=0.1)
    # D (25~32): 별 동기를 장조의 희망으로 — 호른 + 현
    SD = "B4:1 F#5:1 G#5:1 | F#5:1.5 E5:0.5 D5:1 | B4:1 D5:1 F#5:1 | E5:3 | B4:1 F#5:1 G#5:1 | B5:1.5 A5:0.5 G#5:1 | A5:1 F#5:1 D5:1 | E5:3"
    sd = seq(SD, bar=3, offset=72)
    t.play(hn, ev_transpose(sd, -12), inst_brass, vel=0.8, jitter=0.0, bright=0.45, attack=0.08)
    t.play(vs, sd, inst_pad, vel=0.6, jitter=0.0, attack=0.15, release=0.6, voices=3, detune=8.0)
    # E (33~40): 자장가 절정 — 현 · 호른 · 합창, 첼레스타가 옥타브 위
    me = [(b - 48 + 96, d, m, f) for (b, d, m, f) in m_lo if b >= 48]
    t.play(vs, me, inst_pad, vel=0.75, jitter=0.0, attack=0.12, release=0.6, voices=3, detune=8.0)
    t.play(hn, harmonize(me, pev, 3), inst_brass, vel=0.65, jitter=0.0, bright=0.4, attack=0.08)
    t.play(cel, ev_transpose(me, 12), inst_celesta, vel=0.55)

    for k, c in enumerate(prog):
        b0 = t.bar(k)
        sym = c.split()[0]
        r = bass_of(sym, 'D2')
        sec = k // 8
        t.chord(pad, b0, 3, voicing(sym, 'F#3', 3), inst_pad, vel=0.5, attack=0.6, release=1.0)
        t.play(bass, [(b0, 1, r, ''), (b0 + 2, 1, r + 7, '')], inst_pizz, vel=0.75 if sec else 0.6)
        if sec == 2:
            v = voicing(sym, 'B3', 4)
            for i, idx in enumerate([0, 1, 2, 3, 2, 1]):
                t.play(gy, [(b0 + i * 0.5, 0.5, v[idx], '')], inst_gayageum, vel=0.45 if i else 0.55, ring=1.6)
        else:
            v = voicing(sym, 'A3', 4)
            for i, idx in enumerate([0, 1, 2, 3, 2, 1]):
                t.play(hp, [(b0 + i * 0.5, 0.5, v[idx], '')], inst_harp, vel=0.42 if i else 0.52)
        if sec == 4:
            t.chord(ch, b0, 3, open_voicing(sym, 'D3', 4), inst_choir, vel=0.6, vowel='a', attack=0.5, release=1.0)
        elif sec == 3:
            t.chord(ch, b0, 3, voicing(sym, 'D4', 3), inst_choir, vel=0.45, vowel='u', attack=0.8, release=1.0)
    for k in (7, 15, 23, 31):
        for i, mm in enumerate(voicing(prog[k].split()[-1], 'A5', 3)):
            t.play(gl, [(t.bar(k) + 1.5 + i * 0.5, 0.5, mm, '')], inst_glock, vel=0.5)
    return t.finish(rev_size=0.88, rev_damp=0.4, rev_level=0.36, dly_beats=1.5, dly_fb=0.3, dly_level=0.1)


# ---------------------------------------------------------------------------
# festival — 학교 축제 (5장, 폭풍 전의 고요) (F장조, 4/4, 132 bpm, 32마디 = 58.2초)
#   쿵-짝 폴카풍. 플루트 · 클라리넷 축제 가락, 트럼펫의 장난스러운 대답, 학교 동기(F장조, 글로켄슈필),
#   축제 오르간(칼리오페풍) 엇박 화음, 탬버린 · 우드블록 · 트라이앵글.
# ---------------------------------------------------------------------------
def track_festival():
    t = Track('festival', bpm=132, bpb=4, bars=32, seed=2901)
    A = ['F', 'C7', 'C7', 'F', 'F', 'Bb', 'C7', 'F']
    prog = (A + ['Dm', 'Am', 'Bb', 'F', 'Gm', 'C', 'Dm G7', 'C7'] +
            ['F', 'Bb', 'F', 'Gm7', 'Am', 'C7', 'Bb', 'C'] + A)
    pev = prog_events(prog, 4)
    fl = t.bus('flute', gain=0.55, pan=0.12, rev=0.8, dly=0.3)
    cl = t.bus('clarinet', gain=0.32, pan=-0.12, rev=0.8)
    tp = t.bus('trumpet', gain=0.75, pan=0.2, rev=0.7)
    hn = t.bus('horns', gain=0.5, pan=-0.2, rev=0.8)
    gl = t.bus('glock', gain=0.42, pan=0.35, rev=0.9, dly=0.4)
    org = t.bus('organ', gain=0.32, pan=-0.25, rev=0.6)
    hc = t.bus('harpsichord', gain=1.1, pan=-0.3, rev=0.5)
    tuba = t.bus('tuba', gain=0.9, pan=0.0, rev=0.3)
    bass = t.bus('pizz', gain=0.45, pan=0.0, rev=0.3)
    perc = t.bus('perc', gain=0.22, pan=0.25, rev=0.4)
    dr = t.bus('drums', gain=0.42, pan=0.0, rev=0.4)
    cy = t.bus('cymbal', gain=0.1, pan=0.2, rev=0.6)

    FA = ("C5:0.5 A4:0.5 C5:0.5 F5:0.5 A5:1 F5:1 | G5:0.5 E5:0.5 C5:0.5 E5:0.5 G5:1 Bb5:1 | "
          "A5:0.5 G5:0.5 F5:0.5 E5:0.5 D5:1 C5:1 | F5:1 A5:1 F5:1 r:1 | "
          "C5:0.5 A4:0.5 C5:0.5 F5:0.5 A5:1 C6:1 | D6:1 Bb5:0.5 A5:0.5 G5:1 F5:1 | "
          "E5:0.5 F5:0.5 G5:0.5 A5:0.5 Bb5:1 E5:1 | F5:2 r:2")
    FB = ("A5:1.5 F5:0.5 D5:1 A4:1 | C5:1.5 E5:0.5 A5:2 | Bb5:1 A5:0.5 G5:0.5 F5:1 D5:1 | C5:1 F5:1 A5:2 | "
          "G5:1.5 Bb5:0.5 D6:1 Bb5:1 | C6:1 G5:1 E5:1 C5:1 | D5:0.5 F5:0.5 A5:1 B5:1 D6:1 | C6:1 Bb5:1 G5:1 E5:1")
    fa = articulate(seq(FA, bar=4), stacc=0.6)
    fa2 = articulate(seq(FA, bar=4, offset=96), stacc=0.6)
    t.play(fl, fa + fa2, inst_flute, vel=0.85, jitter=0.002, attack=0.03, chiff=0.3)
    t.play(cl, ev_transpose(fa + fa2, -12), inst_wind, vel=0.75, jitter=0.002, kind='clar', breath=0.03,
           attack=0.025, release=0.06, chiff=0.12)
    fb = articulate(seq(FB, bar=4, offset=32), stacc=0.7)
    t.play(tp, fb, inst_brass, vel=0.85, jitter=0.0, bright=1.0, attack=0.03)
    t.play(hn, harmonize(fb, pev, 3), inst_brass, vel=0.7, jitter=0.0, bright=0.55, attack=0.03)
    sc = articulate(ev_transpose(seq(SCHOOL_DAY_A, bar=4, offset=64), 3), stacc=0.7)
    t.play(gl, sc, inst_glock, vel=0.75)
    t.play(fl, sc, inst_flute, vel=0.7, jitter=0.002)
    # A' 트럼펫 대선율 (2분음표, 화음 구성음)
    TC = "A4:2 C5:2 | Bb4:2 G4:2 | C5:2 E5:2 | F5:2 C5:2 | A4:2 F4:2 | Bb4:2 D5:2 | C5:2 E5:2 | F5:2 r:2"
    t.play(tp, seq(TC, bar=4, offset=96), inst_brass, vel=0.6, jitter=0.0, bright=0.7)
    t.play(gl, ev_transpose([e for e in fa2 if e[1] <= 0.5], 12), inst_glock, vel=0.45)

    for k, c in enumerate(prog):
        b0 = t.bar(k)
        sec = k // 8
        for half in (0, 2):
            sym = chord_at(pev, b0 + half)
            r = bass_of(sym, 'C2')
            # 쿵(1·3박: 튜바풍 저음 금관 + 피치카토) - 짝(2·4박: 축제 오르간 + 하프시코드)
            t.play(tuba, [(b0 + half, 0.45, r if half == 0 else (r + 7 if r + 7 <= midi('C3') else r - 5), '')],
                   inst_brass, vel=0.8, jitter=0.0, bright=0.4, attack=0.02, release=0.08)
            t.play(bass, [(b0 + half, 0.5, r + 12 if half == 0 else r + 7, '')], inst_pizz, vel=0.6)
            v = voicing(sym, 'A3', 3)
            t.chord(org, b0 + half + 1, 0.4, v, inst_organ, vel=0.55, attack=0.01, release=0.08)
            for mm in v:
                t.play(hc, [(b0 + half + 1, 0.3, mm + 12, '')], inst_harpsi, vel=0.4, jitter=0.002)
            if sec == 1:
                t.chord(org, b0 + half + 1.5, 0.3, v, inst_organ, vel=0.35, attack=0.01, release=0.06)
        # --- 타악 ---
        for i in range(8):
            t.hit(perc, 'tamb', b0 + i * 0.5, 0.6 if i % 2 else 0.35)
        t.hit(dr, 'taiko', b0, 0.45)
        t.hit(dr, 'taiko', b0 + 2, 0.35)
        t.hit(dr, 'snare', b0 + 1, 0.4)
        t.hit(dr, 'snare', b0 + 3, 0.45)
        if sec == 1:
            for bt in (0.5, 1.5, 2.5, 3.5):
                t.hit(perc, 'wood', b0 + bt, 0.55)
        if k % 8 == 7:
            roll(t, dr, 'sroll', b0 + 2, 2, 0.125, 0.2, 0.7)
        if k % 8 == 0:
            t.hit(perc, 'tri', b0, 0.8)
        if k == 24:
            t.hit(cy, 'crash', b0, 0.9)
    return t.finish(rev_size=0.78, rev_damp=0.45, rev_level=0.18, dly_beats=0.75, dly_fb=0.2, dly_level=0.05,
                    drive=0.6)


# ===========================================================================
# 2~5장 징글 (반복 없음)
# ===========================================================================
def jingle_spell():
    """마법 습득(웅장): 하프 글리산도 + 팀파니 롤 → 학교 동기 머리(5-1-3) 금관 팡파르 → D장조 총주 · 합창 · 종."""
    t = Track('jingle_spell', bpm=100, bpb=4, loop=False, length=5.2, seed=3001)
    hp = t.bus('harp', gain=0.7, pan=-0.3, rev=1.0)
    tp = t.bus('trumpet', gain=0.55, pan=0.12, rev=0.9)
    hn = t.bus('horns', gain=0.5, pan=-0.15, rev=1.0)
    ch = t.bus('choir', gain=0.42, pan=0.0, rev=1.0)
    cel = t.bus('celesta', gain=0.45, pan=0.35, rev=1.0, dly=0.6)
    bell = t.bus('bell', gain=0.6, pan=-0.2, rev=1.0)
    tim = t.bus('timpani', gain=0.5, pan=-0.1, rev=0.8)
    sw = t.bus('swell', gain=0.14, pan=0.1, rev=0.8)
    cy = t.bus('cymbal', gain=0.14, pan=0.2, rev=0.8)
    pad = t.bus('strings', gain=0.3, pan=0.0, rev=1.0)
    lb = t.bus('lowbrass', gain=0.4, pan=0.0, rev=0.8)

    gliss(t, hp, 0.0, scale_run('D4', 'D6', {2, 4, 6, 7, 9, 11, 1}), 0.1, inst_harp, vel=0.5)
    timp_roll(t, tim, 'A2', 0.0, 1.5, 0.2, 0.8, step=0.1)
    t.play(sw, [(0.0, 1.5, 60, '')], inst_swell, vel=1.0, jitter=0.0, variants=1)
    fan = seq("r:1.5 A4:0.5 D5:0.5 F#5:0.5 A5:3", bar=6)
    t.play(tp, fan, inst_brass, vel=0.9, jitter=0.0, bright=1.2)
    t.play(hn, seq("r:1.5 F#4:0.5 A4:0.5 D5:0.5 F#5:3", bar=6), inst_brass, vel=0.7, jitter=0.0, bright=0.6)
    t.chord(hn, 3.0, 3.0, 'D4 F#4', inst_brass, vel=0.6, bright=0.55)
    t.chord(lb, 3.0, 3.0, 'D2 A2 D3', inst_brass, vel=0.7, bright=0.45)
    t.chord(ch, 3.0, 3.2, open_voicing('D', 'D3', 6), inst_choir, vel=0.7, vowel='a', attack=0.15, release=1.2)
    t.chord(pad, 3.0, 3.2, 'D3 A3 D4 F#4 A4', inst_pad, vel=0.5, attack=0.08, release=1.2)
    t.hit(cy, 'crash', 3.0, 1.0)
    t.play(tim, [(3.0, 1, midi('D2'), '')], inst_timp, vel=1.0, T=2.0)
    t.play(bell, [(3.0, 3, midi('D4'), '')], inst_cbell, vel=0.8, variants=1, T=4.0, lp=3500.0)
    for i, nm in enumerate(['A6', 'F#6', 'D6', 'A5', 'F#5', 'E6', 'D6']):
        t.play(cel, [(3.5 + i * 0.4, 0.5, midi(nm), '')], inst_celesta, vel=0.65 - 0.05 * i)
    return t.finish(rev_size=0.86, rev_damp=0.4, rev_level=0.3, fade=1.0, drive=0.8)


def jingle_levelup():
    """마법 레벨 업: 짧고 반짝이는 상승 아르페지오 (1.5초)."""
    t = Track('jingle_levelup', bpm=140, bpb=4, loop=False, length=1.5, seed=3002)
    cel = t.bus('celesta', gain=0.8, pan=0.1, rev=1.0)
    gl = t.bus('glock', gain=0.4, pan=0.35, rev=1.0)
    hp = t.bus('harp', gain=0.5, pan=-0.3, rev=1.0)
    chm = t.bus('chime', gain=0.25, pan=-0.1, rev=1.0)
    for i, nm in enumerate(['D5', 'F#5', 'A5', 'D6']):
        t.play(cel, [(i * 0.25, 0.25, midi(nm), '')], inst_celesta, vel=0.75, jitter=0.0)
        t.play(gl, [(i * 0.25, 0.25, midi(nm) + 12, '')], inst_glock, vel=0.6, jitter=0.0)
        t.play(hp, [(i * 0.25, 0.25, midi(nm) - 12, '')], inst_harp, vel=0.55, jitter=0.0)
    t.play(cel, [(1.0, 1, midi('A6'), ''), (1.0, 1, midi('F#6'), '')], inst_celesta, vel=0.7, jitter=0.0)
    t.play(chm, [(1.0, 1, midi('D7'), ''), (1.35, 1, midi('A6'), '')], inst_chime, vel=0.7, jitter=0.0)
    return t.finish(rev_size=0.8, rev_damp=0.45, rev_level=0.25, fade=0.4)


def jingle_chapter():
    """장 제목 카드: 큰 종 + 북 + 낮은 합창 → 호른이 학교 동기 머리를 부르고 D장조로 열린다 (3초)."""
    t = Track('jingle_chapter', bpm=90, bpb=4, loop=False, length=3.2, seed=3003)
    bell = t.bus('bell', gain=0.45, pan=-0.15, rev=1.0)
    dr = t.bus('drums', gain=0.5, pan=0.0, rev=0.7)
    ch = t.bus('choir', gain=0.4, pan=0.0, rev=1.0)
    hn = t.bus('horns', gain=0.55, pan=0.1, rev=1.0)
    gy = t.bus('gayageum', gain=1.1, pan=-0.35, rev=1.0)
    cel = t.bus('celesta', gain=0.35, pan=0.35, rev=1.0)
    t.play(bell, [(0.0, 3, midi('D3'), '')], inst_cbell, vel=0.9, variants=1, T=5.0, lp=2200.0)
    t.hit(dr, 'btaiko', 0.0, 1.0)
    t.chord(ch, 0.0, 3.2, 'D2 A2 D3 A3', inst_choir, vel=0.7, vowel='o', attack=0.4, release=1.0)
    hm = seq("r:1 A3:0.5 D4:0.5 F#4:2.5", bar=4.5)
    t.play(hn, hm, inst_brass, vel=0.85, jitter=0.0, bright=0.7)
    t.play(hn, seq("r:1 F#3:0.5 A3:0.5 D4:2.5", bar=4.5), inst_brass, vel=0.65, jitter=0.0, bright=0.5)
    t.play(gy, [(2.0, 2, midi('A4'), 's')], inst_gayageum, vel=0.8, jitter=0.0)
    t.chord(ch, 2.0, 1.2, 'F#3 A3 D4', inst_choir, vel=0.55, vowel='a', attack=0.3, release=1.0)
    for i, nm in enumerate(['D6', 'F#6', 'A6']):
        t.play(cel, [(2.0 + i * 0.25, 0.5, midi(nm), '')], inst_celesta, vel=0.55)
    return t.finish(rev_size=0.86, rev_damp=0.4, rev_level=0.32, fade=0.8)


# ---------------------------------------------------------------------------
# 출력 (WAV → Ogg Vorbis)
# ---------------------------------------------------------------------------
TRACKS = [
    ('title', track_title), ('shingye', track_shingye), ('shingye_tension', track_shingye_tension),
    ('school', track_school), ('library', track_library), ('basement', track_basement),
    ('boss', track_boss), ('ending', track_ending),
    ('jingle_ability', jingle_ability), ('jingle_quest', jingle_quest), ('jingle_save', jingle_save),
    # 2~5장
    ('school_day', track_school_day), ('kingdom', track_kingdom), ('kingdom_night', track_kingdom_night),
    ('knight_duel', track_knight_duel), ('starbeast', track_starbeast), ('elf', track_elf),
    ('elf_hunt', track_elf_hunt), ('herald', track_herald), ('temple', track_temple),
    ('temple_dark', track_temple_dark), ('chase', track_chase), ('aurelia', track_aurelia),
    ('star_tower', track_star_tower), ('lyra', track_lyra), ('despair', track_despair),
    ('nine_tails', track_nine_tails), ('final', track_final), ('ending2', track_ending2),
    ('festival', track_festival),
    ('jingle_spell', jingle_spell), ('jingle_levelup', jingle_levelup), ('jingle_chapter', jingle_chapter),
]
LOOP_KB_PER_SEC = 10.5         # 루프 곡 용량 상한: 초당 약 10.5 KB (≈ 86 kbps)
LOOP_MAX_KB = 700              # 곡 하나의 최대 용량 (90초짜리 엔딩 곡도 이 안에서 품질을 고른다)
JINGLE_BUDGET = 70 * 1024


def write_wav(path, L, R):
    inter = [0] * (2 * len(L))
    inter[0::2] = [int(x * 32767.0 + 32768.5) - 32768 for x in L]
    inter[1::2] = [int(x * 32767.0 + 32768.5) - 32768 for x in R]
    data = array('h', inter)
    if sys.byteorder != 'little':
        data.byteswap()
    with wave.open(path, 'wb') as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def encode_ogg(wav_path, ogg_path, budget):
    """용량 상한 안에서 가장 높은 품질로 인코딩 (q4 → q0 순서로 시도).
    bitexact 플래그: Ogg 스트림 시리얼 번호를 무작위로 정하지 않게 해서 출력 파일까지 매번 동일하게 만든다."""
    for q in (4, 3, 2, 1, 0):
        subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', wav_path, '-map_metadata', '-1',
                        '-fflags', '+bitexact', '-flags:a', '+bitexact',
                        '-c:a', 'libvorbis', '-q:a', str(q), ogg_path], check=True)
        if os.path.getsize(ogg_path) <= budget:
            break
    return q


def render(job):
    name, wav_dir, out_dir = job
    t0 = time.time()
    fn = dict(TRACKS)[name]
    L, R, info = fn()
    synth_t = time.time() - t0
    wav_path = os.path.join(wav_dir, name + '.wav')
    ogg_path = os.path.join(out_dir, name + '.ogg')
    write_wav(wav_path, L, R)
    dur = len(L) / SR
    budget = JINGLE_BUDGET if name.startswith('jingle') else int(min(dur * LOOP_KB_PER_SEC, LOOP_MAX_KB) * 1024)
    q = encode_ogg(wav_path, ogg_path, budget)
    return {'name': name, 'sec': dur, 'time': time.time() - t0, 'synth': synth_t, 'q': q,
            'kb': os.path.getsize(ogg_path) / 1024.0, 'info': info}


def main():
    ap = argparse.ArgumentParser(description='마녀학교 × 여우신 절차적 음악 생성기')
    ap.add_argument('--only', nargs='*', help='생성할 곡 이름(들)')
    ap.add_argument('--jobs', type=int, default=min(4, os.cpu_count() or 1), help='병렬 프로세스 수')
    ap.add_argument('--wav-dir', default=os.path.join(tempfile.gettempdir(), 'yemo_music_wav'),
                    help='중간 WAV 저장 폴더')
    ap.add_argument('--verbose', action='store_true', help='버스별 RMS 등 상세 정보 출력')
    args = ap.parse_args()
    names = [n for n, _ in TRACKS]
    if args.only:
        bad = [n for n in args.only if n not in names]
        if bad:
            ap.error('알 수 없는 곡: ' + ', '.join(bad))
        names = [n for n in names if n in args.only]
    os.makedirs(args.wav_dir, exist_ok=True)
    os.makedirs(OUT_DIR, exist_ok=True)
    if subprocess.run(['ffmpeg', '-version'], capture_output=True).returncode != 0:
        sys.exit('ffmpeg 를 찾을 수 없습니다.')
    jobs = [(n, args.wav_dir, OUT_DIR) for n in names]
    t0 = time.time()
    print('생성 시작: %d곡, 프로세스 %d개, SR=%d Hz' % (len(jobs), args.jobs, SR), flush=True)
    if args.jobs > 1 and len(jobs) > 1:
        from multiprocessing import Pool
        with Pool(args.jobs) as pool:
            results = pool.imap(render, jobs)
            for r in results:
                report(r, args.verbose)
    else:
        for j in jobs:
            report(render(j), args.verbose)
    print('전체 소요 시간: %.1f초' % (time.time() - t0))


def report(r, verbose):
    info = r['info']
    loop = ('  %3d마디 @%3g bpm  이음매비 %.2f' % (info['_bars'], info['_bpm'], info['_seam_ratio'])
            if '_seam_ratio' in info else '  (징글, 반복 없음)')
    print('  %-16s %6.2f초  %6.1f KB (q%d)  처리 %5.1f초  원피크 %+5.1f dB%s'
          % (r['name'], r['sec'], r['kb'], r['q'], r['time'], info['_raw_peak_db'], loop), flush=True)
    if verbose:
        print('      버스 RMS: ' + ', '.join('%s=%.3f' % (k, v) for k, v in info.items() if not k.startswith('_')))


if __name__ == '__main__':
    main()
