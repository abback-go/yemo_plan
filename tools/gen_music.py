#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
gen_music.py — 「마녀학교 × 여우신」 데모용 배경음악 / 징글 절차적 생성기
=====================================================================

* 외부 샘플·다운로드 에셋·AI 오디오 서비스를 전혀 쓰지 않는다. 모든 소리는 이 파일 안의
  합성 코드(가산 합성, 파형표 톱니파, 1극 필터, Karplus-Strong 현 모델, 잡음 타악기,
  ADSR, 피드백 지연선 잔향)로 만들어진다.
* 파이썬 3 표준 라이브러리만 사용한다 (numpy 불필요).
* 고정 시드를 쓰므로 몇 번을 돌려도 같은 결과가 나온다(결정적).

사용법 (저장소 루트에서)::

    python3 tools/gen_music.py                 # 전체 11곡 생성
    python3 tools/gen_music.py --only title    # 특정 곡만
    python3 tools/gen_music.py --jobs 2        # 병렬 프로세스 수 지정
    python3 tools/gen_music.py --wav-dir /tmp/wav   # 중간 WAV 저장 위치

결과물: game/assets/music/<이름>.ogg  (ffmpeg + libvorbis 필요)

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


# ---------------------------------------------------------------------------
# 출력 (WAV → Ogg Vorbis)
# ---------------------------------------------------------------------------
TRACKS = [
    ('title', track_title), ('shingye', track_shingye), ('shingye_tension', track_shingye_tension),
    ('school', track_school), ('library', track_library), ('basement', track_basement),
    ('boss', track_boss), ('ending', track_ending),
    ('jingle_ability', jingle_ability), ('jingle_quest', jingle_quest), ('jingle_save', jingle_save),
]
LOOP_KB_PER_SEC = 10.5         # 루프 곡 용량 상한: 초당 약 10.5 KB (≈ 86 kbps) → 8곡 합계 최대 약 4.7 MB
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
    budget = JINGLE_BUDGET if name.startswith('jingle') else int(dur * LOOP_KB_PER_SEC * 1024)
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
