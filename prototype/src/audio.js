/* 저주 매입합니다 — 효과음 (Web Audio 합성음, 외부 파일 없음) */
(function () {
  'use strict';
  const W = (globalThis.W = globalThis.W || {});
  let ctx = null;
  let enabled = true;
  function ensure() {
    if (ctx || typeof window === 'undefined') return ctx;
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return null;
    try { ctx = new AC(); } catch (e) { ctx = null; }
    return ctx;
  }
  function tone(freq, dur, type, vol, when, slideTo) {
    const c = ctx; if (!c) return;
    const t0 = c.currentTime + (when || 0);
    const o = c.createOscillator();
    const g = c.createGain();
    o.type = type || 'square';
    o.frequency.setValueAtTime(freq, t0);
    if (slideTo) o.frequency.exponentialRampToValueAtTime(slideTo, t0 + dur);
    g.gain.setValueAtTime(0.0001, t0);
    g.gain.exponentialRampToValueAtTime(vol || 0.08, t0 + 0.01);
    g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    o.connect(g).connect(c.destination);
    o.start(t0); o.stop(t0 + dur + 0.02);
  }
  function noise(dur, vol, when, lp) {
    const c = ctx; if (!c) return;
    const t0 = c.currentTime + (when || 0);
    const len = Math.max(1, Math.floor(c.sampleRate * dur));
    const buf = c.createBuffer(1, len, c.sampleRate);
    const d = buf.getChannelData(0);
    for (let i = 0; i < len; i++) d[i] = (Math.random() * 2 - 1) * (1 - i / len);
    const src = c.createBufferSource(); src.buffer = buf;
    const f = c.createBiquadFilter(); f.type = 'lowpass'; f.frequency.value = lp || 1800;
    const g = c.createGain(); g.gain.value = vol || 0.12;
    src.connect(f).connect(g).connect(c.destination);
    src.start(t0);
  }
  const SFX = {
    tap: () => tone(720, 0.05, 'square', 0.035),
    step: () => tone(170, 0.04, 'triangle', 0.035),
    hit: () => { noise(0.12, 0.16, 0, 1400); tone(140, 0.12, 'square', 0.06, 0, 70); },
    crit: () => { noise(0.18, 0.2, 0, 2400); tone(220, 0.16, 'sawtooth', 0.06, 0, 90); },
    hurt: () => { tone(260, 0.18, 'square', 0.07, 0, 120); noise(0.1, 0.08); },
    fire: () => { noise(0.3, 0.12, 0, 900); tone(300, 0.25, 'sawtooth', 0.04, 0, 600); },
    ice: () => { [1320, 1760, 2093].forEach((f, i) => tone(f, 0.12, 'sine', 0.05, i * 0.05)); },
    light: () => { [523, 659, 784, 1047].forEach((f, i) => tone(f, 0.22, 'triangle', 0.05, i * 0.06)); },
    heal: () => { [392, 523, 659].forEach((f, i) => tone(f, 0.18, 'triangle', 0.06, i * 0.07)); },
    coin: () => { tone(988, 0.07, 'square', 0.04); tone(1319, 0.12, 'square', 0.04, 0.07); },
    chest: () => { [523, 659, 784].forEach((f, i) => tone(f, 0.1, 'square', 0.04, i * 0.08)); },
    door: () => { tone(110, 0.2, 'triangle', 0.1, 0, 70); noise(0.08, 0.06, 0.05, 600); },
    win: () => { [523, 659, 784, 1047, 784, 1047].forEach((f, i) => tone(f, 0.14, 'square', 0.045, i * 0.09)); },
    lose: () => { [392, 330, 262, 196].forEach((f, i) => tone(f, 0.28, 'triangle', 0.06, i * 0.2)); },
    levelup: () => { [523, 659, 784, 1047, 1319].forEach((f, i) => tone(f, 0.16, 'square', 0.045, i * 0.07)); },
    error: () => tone(150, 0.14, 'square', 0.05),
    charge: () => tone(200, 0.4, 'sawtooth', 0.04, 0, 520),
    purify: () => { [659, 784, 988, 1319, 1568].forEach((f, i) => tone(f, 0.3, 'sine', 0.05, i * 0.09)); },
    good: () => { tone(784, 0.1, 'triangle', 0.06); tone(1047, 0.16, 'triangle', 0.06, 0.09); },
    bad: () => { tone(330, 0.12, 'square', 0.05); tone(247, 0.2, 'square', 0.05, 0.1); },
    meow: () => { tone(900, 0.18, 'sine', 0.05, 0, 600); },
  };
  function play(name) {
    if (!enabled) return;
    const c = ensure();
    if (!c) return;
    if (c.state === 'suspended') c.resume().catch(() => {});
    const f = SFX[name];
    if (f) { try { f(); } catch (e) { /* 소리는 실패해도 게임은 계속 */ } }
  }
  W.audio = {
    play,
    unlock() { const c = ensure(); if (c && c.state === 'suspended') c.resume().catch(() => {}); },
    setEnabled(v) { enabled = !!v; },
    get enabled() { return enabled; },
  };
})();
