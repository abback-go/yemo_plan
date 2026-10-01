/* 저주 매입합니다 — 그래픽. 모든 그림은 100×100 상자 좌표로 그린 뒤 원하는 크기로 확대한다. */
(function () {
  'use strict';
  const W = (globalThis.W = globalThis.W || {});

  const C = {
    ink: '#1d1327', line2: '#55427a',
    cream: '#f7ecd9', cream2: '#e6d4b6', skin: '#f7dcc5', skin2: '#eabda0',
    plum: '#4b2f66', plum2: '#33214a', violet: '#7d5cc6', lilac: '#bfa2ee',
    gold: '#ffcf5a', gold2: '#d9a53f', amber: '#f7a84a', ember: '#ff7d47',
    rose: '#f394ad', red: '#e5566e', red2: '#b93a52',
    mint: '#90e4c0', teal: '#4cb59f', sky: '#9dd0ff', blue: '#5a8ee0', ice: '#d6efff',
    moss: '#7fc46e', moss2: '#4f8c47', brown: '#8a5a3c', brown2: '#5f3b27', tan: '#cfa071',
    bone: '#efe6d2', grey: '#a39bb5', grey2: '#6f6784', slate: '#4a4359', white: '#ffffff', night: '#130d1b',
  };
  const LW = 4;
  const TAU = Math.PI * 2;
  const pathCache = new Map();
  const P = (d) => { let p = pathCache.get(d); if (!p) { p = new Path2D(d); pathCache.set(d, p); } return p; };
  const circ = (x, y, r) => { const p = new Path2D(); p.arc(x, y, r, 0, TAU); return p; };
  const ell = (x, y, rx, ry, rot) => { const p = new Path2D(); p.ellipse(x, y, rx, ry, rot || 0, 0, TAU); return p; };
  function rr(x, y, w, h, r) {
    const p = new Path2D();
    const k = Math.min(r, w / 2, h / 2);
    p.moveTo(x + k, y); p.lineTo(x + w - k, y); p.arcTo(x + w, y, x + w, y + k, k); p.lineTo(x + w, y + h - k);
    p.arcTo(x + w, y + h, x + w - k, y + h, k); p.lineTo(x + k, y + h); p.arcTo(x, y + h, x, y + h - k, k);
    p.lineTo(x, y + k); p.arcTo(x, y, x + k, y, k); p.closePath();
    return p;
  }
  function fp(ctx, p, fill, lw, stroke) {
    if (fill) { ctx.fillStyle = fill; ctx.fill(p); }
    const w = lw == null ? LW : lw;
    if (w > 0) { ctx.lineWidth = w; ctx.strokeStyle = stroke || C.ink; ctx.stroke(p); }
  }
  function line(ctx, pts, color, lw) {
    ctx.beginPath(); ctx.moveTo(pts[0], pts[1]);
    for (let i = 2; i < pts.length; i += 2) ctx.lineTo(pts[i], pts[i + 1]);
    ctx.strokeStyle = color || C.ink; ctx.lineWidth = lw || LW; ctx.stroke();
  }
  function curve(ctx, d, color, lw) { ctx.strokeStyle = color || C.ink; ctx.lineWidth = lw || LW; ctx.stroke(P(d)); }
  function shine(ctx, x, y, rx, ry, a) { ctx.globalAlpha = a == null ? 0.85 : a; fp(ctx, ell(x, y, rx, ry || rx * 0.6, -0.5), C.white, 0); ctx.globalAlpha = 1; }
  function blush(ctx, x, y, r) { ctx.globalAlpha = 0.45; fp(ctx, ell(x, y, r || 5, (r || 5) * 0.6), C.rose, 0); ctx.globalAlpha = 1; }
  function eyes(ctx, x1, x2, y, r, o) {
    const opt = o || {};
    for (const x of [x1, x2]) {
      if (opt.blink) { line(ctx, [x - r, y, x + r, y], opt.color || C.ink, r * 0.55); continue; }
      fp(ctx, ell(x, y, r * 0.82, r), opt.color || C.ink, 0);
      if (opt.iris) fp(ctx, ell(x, y + r * 0.25, r * 0.6, r * 0.6), opt.iris, 0);
      fp(ctx, circ(x - r * 0.28, y - r * 0.38, r * 0.33), C.white, 0);
      fp(ctx, circ(x + r * 0.3, y + r * 0.35, r * 0.14), C.white, 0);
    }
  }
  function smile(ctx, x, y, w, color) { curve(ctx, `M${x - w} ${y} Q${x} ${y + w * 0.9} ${x + w} ${y}`, color || C.ink, 3); }
  function catMouth(ctx, x, y, s) { curve(ctx, `M${x - s} ${y} Q${x - s / 2} ${y + s * 0.8} ${x} ${y} Q${x + s / 2} ${y + s * 0.8} ${x + s} ${y}`, C.ink, 2.6); }
  function shadow(ctx, x, y, rx) { ctx.globalAlpha = 0.28; fp(ctx, ell(x, y, rx, rx * 0.22), '#000', 0); ctx.globalAlpha = 1; }
  function star(ctx, x, y, r, fill) {
    const p = new Path2D();
    for (let i = 0; i < 10; i++) { const a = -Math.PI / 2 + (i * Math.PI) / 5; const rr2 = i % 2 ? r * 0.45 : r; p.lineTo(x + Math.cos(a) * rr2, y + Math.sin(a) * rr2); }
    p.closePath(); fp(ctx, p, fill || C.gold, 2.4);
  }
  function flame(ctx, x, y, s, outer, inner, t) {
    const w = Math.sin((t || 0) * 9) * 1.2;
    fp(ctx, P(`M${x} ${y - 14 * s} C${x + 9 * s + w} ${y - 4 * s} ${x + 8 * s} ${y + 7 * s} ${x} ${y + 8 * s} C${x - 8 * s} ${y + 7 * s} ${x - 9 * s + w} ${y - 4 * s} ${x} ${y - 14 * s} Z`), outer, 2.6);
    fp(ctx, P(`M${x} ${y - 6 * s} C${x + 4 * s} ${y} ${x + 4 * s} ${y + 5 * s} ${x} ${y + 6 * s} C${x - 4 * s} ${y + 5 * s} ${x - 4 * s} ${y} ${x} ${y - 6 * s} Z`), inner, 0);
  }
  function crown(ctx, x, y, s) {
    fp(ctx, P(`M${x - 14 * s} ${y + 6 * s} L${x - 16 * s} ${y - 8 * s} L${x - 7 * s} ${y - 1 * s} L${x} ${y - 11 * s} L${x + 7 * s} ${y - 1 * s} L${x + 16 * s} ${y - 8 * s} L${x + 14 * s} ${y + 6 * s} Z`), C.gold, 2.6);
    fp(ctx, circ(x, y + 1 * s, 2.2 * s), C.red, 0);
  }
  const blinkAt = (t, off) => ((t || 0) + (off || 0)) % 3.4 > 3.27;

  // ───────── 인물 ─────────
  function drawRumi(ctx, o) {
    const t = o.t || 0;
    const b = Math.sin(t * 3) * 1.2;
    if (o.shadow) shadow(ctx, 50, 98, 22);
    ctx.save(); ctx.translate(0, b);
    // 망토
    fp(ctx, P('M30 74 Q28 86 22 97 L78 97 Q72 86 70 74 Z'), C.plum2);
    fp(ctx, P('M42 74 L50 86 L58 74 Z'), C.cream, 2.4);
    fp(ctx, circ(50, 78, 3.2), C.gold, 2);
    fp(ctx, ell(41, 98, 7, 3.5), C.ink, 0); fp(ctx, ell(59, 98, 7, 3.5), C.ink, 0);
    // 머리카락 뒤
    fp(ctx, P('M24 50 Q20 70 28 76 L72 76 Q80 70 76 50 Z'), C.violet);
    // 얼굴
    fp(ctx, ell(50, 58, 21, 19), C.skin);
    // 앞머리
    fp(ctx, P('M28 52 Q34 38 50 38 Q66 38 72 52 Q64 46 58 50 Q54 44 48 49 Q42 45 36 51 Z'), C.violet, 3);
    eyes(ctx, 42, 58, 61, 4.4, { blink: blinkAt(t), iris: '#5b3a8c' });
    blush(ctx, 35, 67, 4.5); blush(ctx, 65, 67, 4.5);
    smile(ctx, 50, 68, 3.2);
    // 모자
    fp(ctx, P('M22 44 Q36 36 46 10 Q50 0 64 4 Q72 7 70 12 Q62 10 60 16 Q66 30 78 44 Z'), C.plum, 3.6);
    fp(ctx, P('M27 40 Q50 32 74 40 L76 44 Q50 37 25 44 Z'), C.violet, 0);
    fp(ctx, ell(50, 44, 36, 7.5), C.plum, 3.6);
    star(ctx, 52, 36, 5.5);
    ctx.restore();
  }
  function drawCat(ctx, o) {
    const t = o.t || 0;
    const outline = C.line2;
    const tail = Math.sin(t * 2.5) * 4;
    if (o.shadow !== false) shadow(ctx, 50, 96, 26);
    curve(ctx, `M76 84 Q${94 + tail} 70 ${86 + tail} 46`, outline, 9);
    curve(ctx, `M76 84 Q${94 + tail} 70 ${86 + tail} 46`, '#1b1424', 5.5);
    fp(ctx, ell(50, 74, 28, 22), '#1b1424', LW, outline);
    fp(ctx, P('M28 40 L30 14 L46 28 Z'), '#1b1424', LW, outline);
    fp(ctx, P('M72 40 L70 14 L54 28 Z'), '#1b1424', LW, outline);
    fp(ctx, P('M32 30 L32 20 L40 27 Z'), C.rose, 0);
    fp(ctx, P('M68 30 L68 20 L60 27 Z'), C.rose, 0);
    fp(ctx, ell(50, 46, 26, 22), '#1b1424', LW, outline);
    const bl = blinkAt(t, 1.3);
    for (const x of [40, 60]) {
      if (bl) { line(ctx, [x - 6, 45, x + 6, 45], C.gold, 3); continue; }
      fp(ctx, ell(x, 45, 6.5, 7.5), C.gold, 0);
      fp(ctx, ell(x, 45, 1.8, 5.5), C.ink, 0);
      fp(ctx, circ(x - 2.2, 42, 1.6), C.white, 0);
    }
    fp(ctx, P('M47.5 53 L52.5 53 L50 56 Z'), C.rose, 0);
    catMouth(ctx, 50, 57, 4);
    for (const s of [-1, 1]) { line(ctx, [50 + s * 12, 55, 50 + s * 26, 52], '#6d5b86', 1.6); line(ctx, [50 + s * 12, 58, 50 + s * 26, 59], '#6d5b86', 1.6); }
  }
  function drawStudent(ctx, o) {
    const n = o.npc || {};
    const t = o.t || 0;
    const hair = n.hair || C.violet;
    const style = n.style || 0;
    // 뒷머리
    if (style === 2) fp(ctx, P('M24 40 Q18 70 22 96 L78 96 Q82 70 76 40 Z'), hair);
    else fp(ctx, P('M25 44 Q22 66 30 74 L70 74 Q78 66 75 44 Z'), hair);
    if (style === 1) { fp(ctx, circ(26, 26, 11), hair); fp(ctx, circ(74, 26, 11), hair); }
    if (style === 3) fp(ctx, P('M70 34 Q92 40 88 70 Q84 60 74 54 Z'), hair);
    // 몸
    fp(ctx, P('M14 100 Q16 84 30 80 L70 80 Q84 84 86 100 Z'), '#2c2645');
    fp(ctx, P('M38 80 L50 92 L62 80 Z'), C.cream, 2.6);
    fp(ctx, P('M44 86 L50 92 L56 86 L56 96 L50 92 L44 96 Z'), n.ribbon || hair, 2.2);
    fp(ctx, rr(44, 70, 12, 12, 3), C.skin, 0);
    // 얼굴
    fp(ctx, ell(50, 54, 23, 21), C.skin);
    // 앞머리
    if (style === 0) fp(ctx, P('M26 52 Q28 30 50 30 Q72 30 74 52 L68 44 L62 50 L56 42 L50 48 L44 42 L38 50 L32 44 Z'), hair, 3);
    else if (style === 1) fp(ctx, P('M27 50 Q30 31 50 31 Q70 31 73 50 Q60 40 50 44 Q40 40 27 50 Z'), hair, 3);
    else if (style === 2) fp(ctx, P('M26 56 Q26 30 50 30 Q74 30 74 56 Q70 42 60 40 Q58 50 44 44 Q34 46 26 56 Z'), hair, 3);
    else fp(ctx, P('M27 52 Q28 30 50 29 Q72 30 73 52 Q66 38 56 42 L52 34 L46 42 Q36 38 27 52 Z'), hair, 3);
    const worried = o.mood === 'worried';
    eyes(ctx, 41, 59, 56, 4.6, { blink: blinkAt(t, 0.7), iris: n.eye || '#3b2a55' });
    if (worried) { line(ctx, [35, 47, 44, 45], C.ink, 2.4); line(ctx, [65, 47, 56, 45], C.ink, 2.4); }
    if (n.glasses) { fp(ctx, circ(41, 56, 8), null, 2.4, '#3b2a55'); fp(ctx, circ(59, 56, 8), null, 2.4, '#3b2a55'); line(ctx, [49, 56, 51, 56], '#3b2a55', 2.4); }
    blush(ctx, 34, 64, 4); blush(ctx, 66, 64, 4);
    if (worried) curve(ctx, 'M45 67 Q50 64 55 67', C.ink, 2.8); else smile(ctx, 50, 66, 3.4);
    if (n.hat) {
      fp(ctx, P('M18 36 Q34 28 44 4 Q48 -4 60 2 Q66 6 64 10 Q58 8 56 14 Q64 26 82 36 Z'), '#2c2350', 3.4);
      fp(ctx, ell(50, 36, 38, 7), '#2c2350', 3.4);
      fp(ctx, P('M24 32 Q50 24 76 32 L78 35 Q50 28 22 35 Z'), C.gold2, 0);
    }
  }
  // 플람 교수 (부엉이)
  function drawOwl(ctx, o) {
    const t = o.t || 0;
    const b = Math.sin(t * 2) * 1;
    ctx.save(); ctx.translate(0, b);
    fp(ctx, P('M22 96 Q16 60 30 40 Q50 26 70 40 Q84 60 78 96 Z'), '#8a6a4f');
    fp(ctx, P('M34 96 Q30 66 50 58 Q70 66 66 96 Z'), '#e9d6b4');
    for (const y of [68, 78, 88]) for (const x of [42, 50, 58]) curve(ctx, `M${x - 3} ${y} Q${x} ${y + 3} ${x + 3} ${y}`, '#b99a74', 2);
    fp(ctx, P('M22 60 Q10 72 18 90 Q26 80 30 66 Z'), '#6f5440');
    fp(ctx, P('M78 60 Q90 72 82 90 Q74 80 70 66 Z'), '#6f5440');
    fp(ctx, P('M28 34 L22 14 L40 26 Z'), '#6f5440'); fp(ctx, P('M72 34 L78 14 L60 26 Z'), '#6f5440');
    fp(ctx, ell(50, 40, 26, 20), '#8a6a4f');
    fp(ctx, circ(39, 40, 10), C.cream, 2.6); fp(ctx, circ(61, 40, 10), C.cream, 2.6);
    eyes(ctx, 39, 61, 40, 5, { blink: blinkAt(t, 1.3), iris: '#e0a020' });
    fp(ctx, circ(39, 40, 12), null, 2.4, C.gold2); fp(ctx, circ(61, 40, 12), null, 2.4, C.gold2); line(ctx, [49, 38, 51, 38], C.gold2, 2.4);
    fp(ctx, P('M46 48 L54 48 L50 56 Z'), C.amber, 2.4);
    fp(ctx, P('M30 22 Q50 10 70 22 L66 26 Q50 18 34 26 Z'), '#2c2350', 3);
    fp(ctx, rr(36, 4, 28, 18, 2), '#2c2350', 3);
    line(ctx, [64, 6, 74, 0], C.gold, 2.4); fp(ctx, circ(75, 0, 2.6), C.gold, 0);
    ctx.restore();
  }
  // 송이 아저씨 (버섯 정원사)
  function drawGardener(ctx, o) {
    const t = o.t || 0;
    const b = Math.sin(t * 2.4) * 1.2;
    ctx.save(); ctx.translate(0, b);
    fp(ctx, P('M30 98 Q30 70 50 66 Q70 70 70 98 Z'), '#6f9a5a');
    fp(ctx, rr(38, 74, 24, 18, 4), '#4f7a40', 2.4);
    fp(ctx, P('M34 66 Q32 46 50 44 Q68 46 66 66 Z'), C.cream);
    eyes(ctx, 43, 57, 56, 3.6, { blink: blinkAt(t, 0.9) });
    smile(ctx, 50, 62, 3);
    blush(ctx, 38, 60, 3.4); blush(ctx, 62, 60, 3.4);
    fp(ctx, P('M12 46 Q14 14 50 10 Q86 14 88 46 Q70 40 50 40 Q30 40 12 46 Z'), '#c0473a');
    for (const [x, y, r2] of [[30, 26, 6], [52, 18, 5], [70, 30, 6], [44, 34, 3.5]]) fp(ctx, circ(x, y, r2), C.cream, 0);
    line(ctx, [72, 98, 84, 60], C.brown, 4);
    fp(ctx, P('M78 60 L92 58 L90 50 L80 54 Z'), '#a39bb5', 2.4);
    ctx.restore();
  }
  function drawBatGranny(ctx, o) {
    const t = o.t || 0;
    const flap = Math.sin(t * 4) * 3;
    fp(ctx, P(`M50 60 Q30 ${40 - flap} 6 ${46 - flap} Q14 58 10 70 Q22 66 26 76 Q34 70 42 80 Z`), '#4a3560');
    fp(ctx, P(`M50 60 Q70 ${40 - flap} 94 ${46 - flap} Q86 58 90 70 Q78 66 74 76 Q66 70 58 80 Z`), '#4a3560');
    fp(ctx, P('M26 100 Q30 74 50 70 Q70 74 74 100 Z'), '#8b5fb7');
    for (let i = 0; i < 5; i++) fp(ctx, circ(34 + i * 8, 88 + (i % 2) * 4, 2), C.lilac, 0);
    fp(ctx, P('M30 34 L24 8 L42 24 Z'), '#7a6a8f');
    fp(ctx, P('M70 34 L76 8 L58 24 Z'), '#7a6a8f');
    fp(ctx, ell(50, 46, 22, 20), '#7a6a8f');
    fp(ctx, circ(50, 22, 8), C.cream);
    eyes(ctx, 42, 58, 46, 3.4, { blink: blinkAt(t, 2) });
    fp(ctx, circ(42, 46, 7.5), null, 2.2, C.gold2); fp(ctx, circ(58, 46, 7.5), null, 2.2, C.gold2);
    line(ctx, [49.5, 46, 50.5, 46], C.gold2, 2.2);
    smile(ctx, 50, 55, 4);
    fp(ctx, P('M46 57 L48 61 L50 57 Z'), C.white, 1.4);
    blush(ctx, 35, 53, 3.5); blush(ctx, 65, 53, 3.5);
  }
  function drawMummy(ctx, o) {
    const t = o.t || 0;
    fp(ctx, P('M18 100 Q20 80 36 76 L64 76 Q80 80 82 100 Z'), '#dff3ea');
    fp(ctx, P('M44 76 L50 86 L56 76 Z'), C.mint, 2.2);
    fp(ctx, ell(50, 50, 24, 25), C.bone);
    for (const y of [36, 44, 52, 60, 66]) curve(ctx, `M28 ${y} Q50 ${y + 4} 72 ${y - 2}`, '#cdbfa6', 2.2);
    fp(ctx, ell(50, 50, 24, 25), null, LW);
    eyes(ctx, 58, 58, 50, 4.4, { blink: blinkAt(t, 0.4) });
    line(ctx, [36, 47, 46, 52], '#cdbfa6', 3);
    fp(ctx, rr(34, 18, 32, 14, 4), C.white, 3);
    fp(ctx, rr(47, 20, 6, 10, 1), C.red, 0); fp(ctx, rr(45, 22, 10, 6, 1), C.red, 0);
    blush(ctx, 63, 58, 4);
    smile(ctx, 52, 61, 3);
  }
  function drawMerchantCat(ctx, o) {
    const t = o.t || 0;
    fp(ctx, rr(56, 46, 34, 40, 8), C.brown);
    fp(ctx, rr(60, 52, 26, 10, 3), C.tan, 2.4);
    fp(ctx, ell(48, 74, 24, 20), '#f0a35e');
    fp(ctx, P('M30 40 L32 18 L44 30 Z'), '#f0a35e'); fp(ctx, P('M66 40 L64 18 L52 30 Z'), '#f0a35e');
    fp(ctx, ell(48, 46, 22, 19), '#f0a35e');
    curve(ctx, 'M36 46 Q40 42 44 46', C.ink, 2.6); curve(ctx, 'M52 46 Q56 42 60 46', C.ink, 2.6);
    catMouth(ctx, 48, 54, 3.4);
    blush(ctx, 34, 52, 3.5); blush(ctx, 62, 52, 3.5);
    fp(ctx, ell(48, 26, 26, 6), C.tan); fp(ctx, P('M36 26 Q38 10 48 10 Q58 10 60 26 Z'), C.tan);
    line(ctx, [36, 22, 60, 22], C.red2, 3);
    void t;
  }
  function drawPortraits(ctx, o) {
    const t = o.t || 0;
    const sway = Math.sin(t * 1.5) * 1.5;
    for (const [x, hair, mouthY] of [[28, '#f394ad', 0], [72, '#9dd0ff', 1]]) {
      fp(ctx, ell(x, 50, 21, 30), C.gold2, 3.4);
      fp(ctx, ell(x, 50, 16, 25), '#3d3049', 2);
      fp(ctx, P(`M${x - 12} ${58} Q${x - 14} ${32} ${x} ${30} Q${x + 14} ${32} ${x + 12} ${58} Z`), hair, 2);
      fp(ctx, ell(x, 52, 9, 11), C.skin, 2);
      eyes(ctx, x - 4 + sway * (x < 50 ? 1 : -1), x + 4 + sway * (x < 50 ? 1 : -1), 50, 2, { blink: blinkAt(t, x) });
      if (mouthY) fp(ctx, ell(x, 58, 2.5, 2), C.red2, 0); else smile(ctx, x, 57, 2.4);
    }
  }
  function drawLetter(ctx) {
    fp(ctx, rr(18, 28, 64, 46, 4), C.cream);
    curve(ctx, 'M18 30 L50 56 L82 30', C.ink, 3);
    fp(ctx, circ(50, 56, 8), C.red);
    star(ctx, 50, 56, 4, C.gold);
  }
  function drawScroll(ctx) {
    fp(ctx, rr(24, 22, 52, 56, 3), C.cream);
    fp(ctx, rr(18, 16, 64, 10, 5), C.tan); fp(ctx, rr(18, 74, 64, 10, 5), C.tan);
    for (const y of [36, 44, 52, 60]) line(ctx, [32, y, 68, y], C.cream2, 3);
    fp(ctx, circ(64, 64, 7), C.red2);
  }

  // ───────── 몬스터 ─────────
  function bumpy(ctx, cx, cy, r, n, bump, fill, outline) {
    const pts = [];
    for (let i = 0; i < n; i++) { const a = (i / n) * TAU; pts.push([cx + Math.cos(a) * r, cy + Math.sin(a) * r]); }
    ctx.fillStyle = outline || C.ink;
    for (const [x, y] of pts) { ctx.beginPath(); ctx.arc(x, y, bump + 2, 0, TAU); ctx.fill(); }
    ctx.beginPath(); ctx.arc(cx, cy, r + 2, 0, TAU); ctx.fill();
    ctx.fillStyle = fill;
    for (const [x, y] of pts) { ctx.beginPath(); ctx.arc(x, y, bump, 0, TAU); ctx.fill(); }
    ctx.beginPath(); ctx.arc(cx, cy, r, 0, TAU); ctx.fill();
  }
  const MON = {};
  MON.dustwisp = (ctx, t) => {
    shadow(ctx, 50, 94, 24);
    const b = Math.sin(t * 3) * 3;
    ctx.save(); ctx.translate(0, b);
    flame(ctx, 50, 30, 1.1, C.lilac, '#efe3ff', t);
    bumpy(ctx, 50, 62, 22, 11, 8, '#b4aac6');
    fp(ctx, ell(43, 58, 9, 6), '#cfc6dd', 0);
    eyes(ctx, 42, 58, 62, 4.6, { blink: blinkAt(t, 0.2) });
    fp(ctx, ell(50, 72, 3, 3.6), C.ink, 0);
    blush(ctx, 34, 68, 4); blush(ctx, 66, 68, 4);
    ctx.restore();
    for (let i = 0; i < 4; i++) { const a = t * 1.5 + i * 1.6; fp(ctx, circ(50 + Math.cos(a) * 36, 60 + Math.sin(a) * 14, 2), '#cfc6dd', 0); }
  };
  MON.teacup = (ctx, t) => {
    shadow(ctx, 50, 95, 32);
    for (let i = 0; i < 2; i++) curve(ctx, `M${42 + i * 14} 30 q-5 -6 0 -12 q5 -6 0 -12`, 'rgba(255,255,255,0.7)', 3);
    fp(ctx, ell(50, 88, 38, 8), C.cream);
    curve(ctx, 'M78 50 Q96 52 90 68 Q86 76 74 72', C.ink, 10); curve(ctx, 'M78 50 Q96 52 90 68 Q86 76 74 72', C.cream, 5);
    fp(ctx, P('M18 42 L82 42 Q80 82 50 84 Q20 82 18 42 Z'), C.cream);
    fp(ctx, P('M22 56 Q50 64 78 56'), null, 3, C.sky);
    for (const x of [30, 50, 70]) { fp(ctx, circ(x, 70, 3.4), C.sky, 0); fp(ctx, circ(x, 70, 1.4), C.white, 0); }
    fp(ctx, ell(50, 42, 32, 8), '#9c6238');
    fp(ctx, P('M66 36 L74 36 L70 44 Z'), C.ink, 0);
    eyes(ctx, 40, 60, 54, 4.2, { blink: blinkAt(t, 1.1) });
    line(ctx, [33, 46, 44, 49], C.ink, 3); line(ctx, [67, 46, 56, 49], C.ink, 3);
    curve(ctx, 'M44 66 Q50 61 56 66', C.ink, 3);
  };
  MON.waxslime = (ctx, t) => {
    shadow(ctx, 50, 95, 32);
    const sq = Math.sin(t * 3) * 1.5;
    ctx.save(); ctx.translate(50, 90); ctx.scale(1 + sq * 0.01, 1 - sq * 0.01); ctx.translate(-50, -90);
    line(ctx, [50, 38, 50, 28], C.ink, 3);
    flame(ctx, 50, 22, 0.9, C.amber, C.gold, t);
    fp(ctx, P('M16 90 Q12 60 30 46 Q50 34 70 46 Q88 60 84 90 Q76 92 74 86 Q72 94 64 92 Q60 86 54 92 Q46 96 42 90 Q36 94 30 90 Q24 94 16 90 Z'), '#f6e7b8');
    fp(ctx, P('M26 52 Q34 46 42 47'), null, 3, C.white);
    eyes(ctx, 40, 60, 64, 4.8, { blink: blinkAt(t, 2.1) });
    curve(ctx, 'M42 76 Q46 72 50 76 Q54 80 58 76', C.ink, 3);
    blush(ctx, 31, 72, 4); blush(ctx, 69, 72, 4);
    ctx.restore();
  };
  MON.giggledoll = (ctx, t, o) => {
    const king = o && o.director;
    shadow(ctx, 50, 97, 30);
    const rock = Math.sin(t * 2.2) * 0.05;
    ctx.save(); ctx.translate(50, 95); ctx.rotate(rock); ctx.translate(-50, -95);
    fp(ctx, P('M30 66 L70 66 L82 96 L18 96 Z'), king ? '#5a2a4a' : C.rose);
    for (let i = 0; i < 6; i++) fp(ctx, circ(22 + i * 11.2, 95, 5.5), king ? C.red2 : C.white, 2.4);
    if (!king) { fp(ctx, circ(28, 30, 10), C.gold); fp(ctx, circ(72, 30, 10), C.gold); }
    fp(ctx, circ(50, 42, 24), '#fbf3ea');
    if (!king) fp(ctx, P('M27 38 Q30 18 50 18 Q70 18 73 38 Q60 28 50 32 Q40 28 27 38 Z'), C.gold, 3);
    for (const x of [40, 60]) { fp(ctx, circ(x, 44, 5.6), C.ink, 0); fp(ctx, circ(x - 1.6, 42.4, 1.2), C.white, 0); fp(ctx, circ(x + 1.6, 45.6, 1.2), C.white, 0); }
    blush(ctx, 33, 52, 5); blush(ctx, 67, 52, 5);
    fp(ctx, P('M36 54 Q50 68 64 54 Q50 60 36 54 Z'), C.red2, 2.6);
    for (const x of [42, 47, 53, 58]) line(ctx, [x, 56.5 + Math.abs(50 - x) * -0.08, x, 59], C.white, 1.4);
    if (king) {
      fp(ctx, rr(30, 2, 40, 20, 3), C.ink, 0); fp(ctx, ell(50, 22, 30, 5), C.ink, 0); fp(ctx, rr(30, 14, 40, 5, 1), C.red, 0);
      fp(ctx, circ(60, 44, 8.5), null, 2.4, C.gold);
      fp(ctx, P('M42 66 L50 70 L58 66 L58 74 L50 70 L42 74 Z'), C.red, 2.2);
      line(ctx, [86, 54, 82, 96], C.brown2, 5); fp(ctx, circ(86, 52, 4), C.gold, 2);
    } else fp(ctx, P('M40 18 L50 24 L60 18 L60 28 L50 24 L40 28 Z'), C.red, 2.2);
    ctx.restore();
  };
  MON.mirrorbat = (ctx, t, o) => {
    const flap = Math.sin(t * 8) * 6;
    shadow(ctx, 50, 96, 24);
    ctx.save(); ctx.translate(0, Math.sin(t * 4) * 3);
    for (const s of [-1, 1]) {
      ctx.save(); ctx.translate(50, 52); ctx.scale(s, 1); ctx.translate(-50, -52);
      fp(ctx, P(`M56 48 Q74 ${30 - flap} 96 ${34 - flap} Q90 46 94 58 Q84 54 80 64 Q72 56 66 66 Q62 58 56 60 Z`), '#cfeaff');
      line(ctx, [70, 42 - flap / 2, 78, 54], C.white, 2.2); line(ctx, [80, 38 - flap / 2, 86, 50], C.white, 2.2);
      ctx.restore();
    }
    fp(ctx, P('M40 40 L42 26 L48 36 Z'), '#6a4aa0'); fp(ctx, P('M60 40 L58 26 L52 36 Z'), '#6a4aa0');
    fp(ctx, ell(50, 54, 14, 16), '#6a4aa0');
    eyes(ctx, 45, 55, 51, 3.2, { blink: blinkAt(t, 0.5), color: '#1d1327' });
    fp(ctx, P('M46 60 L47.5 64 L49 60 Z'), C.white, 1.2); fp(ctx, P('M51 60 L52.5 64 L54 60 Z'), C.white, 1.2);
    if (o && o.king) crown(ctx, 50, 32, 0.8);
    ctx.restore();
  };
  MON.shroomella = (ctx, t) => {
    shadow(ctx, 50, 96, 26);
    const spin = Math.sin(t * 2) * 0.06;
    for (let i = 0; i < 5; i++) { const a = t * 1.3 + i * 1.25; fp(ctx, circ(50 + Math.cos(a) * 40, 50 + Math.sin(a * 1.3) * 22, 2.2), C.moss, 0); }
    fp(ctx, rr(36, 50, 28, 42, 12), C.cream);
    line(ctx, [36, 70, 28, 78], C.ink, 3.4); line(ctx, [64, 70, 72, 78], C.ink, 3.4);
    eyes(ctx, 44, 56, 66, 3.6, { blink: blinkAt(t, 1.7) });
    smile(ctx, 50, 75, 3);
    ctx.save(); ctx.translate(50, 40); ctx.rotate(spin); ctx.translate(-50, -40);
    fp(ctx, P('M12 52 Q14 16 50 14 Q86 16 88 52 Q50 62 12 52 Z'), C.red);
    for (const [x, y, r] of [[32, 30, 6], [54, 24, 5], [70, 36, 6.5], [44, 44, 4], [24, 46, 3.5]]) fp(ctx, circ(x, y, r), C.cream, 0);
    ctx.restore();
  };
  MON.cursedframe = (ctx, t) => {
    const glow = 0.4 + Math.sin(t * 3) * 0.2;
    ctx.globalAlpha = glow; fp(ctx, rr(8, 4, 84, 92, 10), C.violet, 0); ctx.globalAlpha = 1;
    fp(ctx, rr(14, 8, 72, 84, 6), C.gold2);
    fp(ctx, rr(22, 16, 56, 68, 3), '#3a3448', 3);
    for (const [x, y] of [[14, 8], [86, 8], [14, 92], [86, 92]]) fp(ctx, circ(x, y, 5), C.gold, 2.6);
    fp(ctx, P('M30 84 Q32 50 50 46 Q68 50 70 84 Z'), '#5b3a5e', 0);
    fp(ctx, ell(50, 46, 12, 15), '#e9d6c4', 2.6);
    fp(ctx, P('M37 44 Q38 28 50 28 Q62 28 63 44 Q58 36 50 38 Q42 36 37 44 Z'), '#2e2238', 2);
    const look = Math.sin(t * 1.2) * 1.5;
    for (const x of [45, 55]) { fp(ctx, ell(x, 47, 3.4, 2.2), C.white, 0); fp(ctx, circ(x + look, 47, 1.6), C.red, 0); }
    line(ctx, [41, 42, 48, 44], C.ink, 2); line(ctx, [59, 42, 52, 44], C.ink, 2);
    curve(ctx, 'M46 55 Q50 53 54 55', C.ink, 2);
  };
  MON.rustarmor = (ctx, t) => {
    shadow(ctx, 50, 97, 30);
    fp(ctx, P('M28 54 L72 54 L78 94 L22 94 Z'), '#8f93a8');
    for (const [x, y, r] of [[36, 70, 4], [62, 80, 5], [48, 88, 3]]) fp(ctx, circ(x, y, r), '#b2683f', 0);
    line(ctx, [50, 56, 50, 92], C.slate, 3);
    fp(ctx, circ(24, 56, 10), '#a6aabd'); fp(ctx, circ(76, 56, 10), '#a6aabd');
    fp(ctx, P('M50 10 Q54 2 62 4'), null, 5, C.red);
    fp(ctx, P('M30 34 Q30 12 50 12 Q70 12 70 34 L70 50 Q50 56 30 50 Z'), '#a6aabd');
    fp(ctx, rr(34, 30, 32, 8, 3), C.ink, 0);
    const g = 0.6 + Math.sin(t * 4) * 0.4;
    ctx.globalAlpha = g; fp(ctx, ell(42, 34, 3, 2), C.gold, 0); fp(ctx, ell(58, 34, 3, 2), C.gold, 0); ctx.globalAlpha = 1;
    fp(ctx, circ(56, 46, 3), '#b2683f', 0);
  };
  MON.broomghost = (ctx, t) => {
    const b = Math.sin(t * 3) * 3;
    shadow(ctx, 50, 97, 26);
    ctx.save(); ctx.translate(0, b);
    line(ctx, [26, 92, 72, 24], C.ink, 9); line(ctx, [26, 92, 72, 24], C.brown, 5);
    fp(ctx, P('M14 84 L32 100 L40 88 L28 74 Z'), C.tan);
    for (let i = 0; i < 4; i++) line(ctx, [20 + i * 4, 84 + i * 2, 30 + i * 3, 96], C.brown2, 1.6);
    fp(ctx, P('M44 54 Q40 22 62 18 Q86 18 84 50 Q84 64 88 72 Q80 70 76 76 Q70 68 64 76 Q58 68 52 74 Q50 64 44 54 Z'), '#f2edf8');
    fp(ctx, ell(58, 40, 4, 6), C.ink, 0); fp(ctx, ell(72, 40, 4, 6), C.ink, 0);
    fp(ctx, ell(65, 54, 3.5, 4.5), C.ink, 0);
    blush(ctx, 52, 48, 3.5); blush(ctx, 79, 48, 3.5);
    ctx.restore();
  };
  MON.shadowhand = (ctx, t) => {
    const g = '#7a5ab0';
    ctx.globalAlpha = 0.6; fp(ctx, ell(50, 88, 38, 10), '#5b3a8a', 0); ctx.globalAlpha = 1;
    fp(ctx, ell(50, 88, 32, 7), '#24163a', 0);
    const w = Math.sin(t * 2) * 3;
    fp(ctx, P(`M34 88 L36 52 Q30 44 32 36 Q36 34 39 44 L40 22 Q44 18 47 22 L48 40 L50 14 Q54 10 57 14 L57 40 L60 20 Q64 17 66 21 L64 46 Q${74 + w} 38 ${78 + w} 42 Q${76 + w} 52 66 60 L66 88 Z`), '#251a36', LW, g);
    fp(ctx, ell(51, 62, 8, 5.5), C.white, 2, g);
    fp(ctx, circ(51 + Math.sin(t) * 2, 62, 3), '#b07cff', 0);
    fp(ctx, circ(51 + Math.sin(t) * 2, 62, 1.3), C.ink, 0);
  };
  MON.skelibrarian = (ctx, t) => {
    shadow(ctx, 50, 97, 28);
    fp(ctx, P('M26 100 Q28 60 50 58 Q72 60 74 100 Z'), '#2f3a5f');
    fp(ctx, rr(30, 70, 40, 24, 3), '#8a3b3b');
    fp(ctx, rr(33, 72, 34, 20, 2), C.cream, 2);
    line(ctx, [50, 72, 50, 92], '#8a3b3b', 2.4);
    for (const x of [30, 70]) fp(ctx, ell(x, 82, 5, 7), C.bone, 2.4);
    fp(ctx, P('M28 38 Q28 14 50 14 Q72 14 72 38 Q72 52 62 56 L62 62 L38 62 L38 56 Q28 52 28 38 Z'), C.bone);
    const g = 0.6 + Math.sin(t * 5) * 0.4;
    fp(ctx, ell(41, 38, 6.5, 7.5), C.ink, 0); fp(ctx, ell(59, 38, 6.5, 7.5), C.ink, 0);
    ctx.globalAlpha = g; fp(ctx, circ(41, 39, 2), C.gold, 0); fp(ctx, circ(59, 39, 2), C.gold, 0); ctx.globalAlpha = 1;
    fp(ctx, circ(41, 38, 9.5), null, 2.4, C.gold2); fp(ctx, circ(59, 38, 9.5), null, 2.4, C.gold2);
    fp(ctx, P('M48 48 L50 44 L52 48 Z'), C.ink, 0);
    for (const x of [42, 46, 50, 54, 58]) line(ctx, [x, 55, x, 60], C.ink, 1.6);
  };
  MON.stuffedcrow = (ctx, t) => {
    fp(ctx, rr(24, 88, 52, 9, 3), C.brown);
    line(ctx, [50, 88, 50, 78], C.brown2, 5);
    const out = C.line2;
    fp(ctx, P('M22 74 L10 86 L18 88 L30 78 Z'), '#2b2433', LW, out);
    fp(ctx, ell(48, 62, 24, 18), '#2b2433', LW, out);
    fp(ctx, P('M36 58 Q48 52 62 62 Q48 70 36 58 Z'), '#3d3348', 2.4, out);
    for (const x of [44, 50, 56]) line(ctx, [x, 72, x + 2, 76], C.bone, 1.6);
    const tilt = Math.sin(t * 1.5) * 0.12;
    ctx.save(); ctx.translate(62, 38); ctx.rotate(tilt); ctx.translate(-62, -38);
    fp(ctx, circ(62, 38, 15), '#2b2433', LW, out);
    fp(ctx, P('M74 36 L92 42 L74 46 Z'), C.amber);
    fp(ctx, circ(64, 34, 6), '#d6efff', 2.2, C.red);
    fp(ctx, circ(64, 34, 2.6), C.ink, 0); fp(ctx, circ(62, 32, 1.6), C.white, 0);
    ctx.restore();
  };
  MON.lockmimic = (ctx, t, o) => {
    const king = o && o.king;
    const body = king ? C.gold2 : C.brown;
    const trim = king ? '#fff1a8' : C.gold;
    const open = 8 + Math.sin(t * 3) * 4;
    shadow(ctx, 50, 96, 36);
    fp(ctx, rr(14, 54, 72, 38, 6), body);
    fp(ctx, rr(14, 54, 72, 8, 3), trim, 2.6);
    fp(ctx, P(`M18 ${54 - open} L82 ${54 - open} L80 56 L20 56 Z`), '#2a0f18', 0);
    for (let i = 0; i < 6; i++) { fp(ctx, P(`M${22 + i * 10} 54 L${27 + i * 10} 47 L${32 + i * 10} 54 Z`), C.white, 1.6); }
    fp(ctx, P(`M44 54 Q50 ${74 + open / 2} 58 54 Z`), C.rose, 2.2);
    ctx.save(); ctx.translate(0, -open);
    fp(ctx, P('M12 52 Q14 26 50 24 Q86 26 88 52 Z'), body);
    fp(ctx, P('M14 44 Q50 36 86 44'), null, 4, trim);
    for (let i = 0; i < 6; i++) { fp(ctx, P(`M${22 + i * 10} 52 L${27 + i * 10} 59 L${32 + i * 10} 52 Z`), C.white, 1.6); }
    if (king) crown(ctx, 50, 18, 1);
    ctx.restore();
    const g = 0.7 + Math.sin(t * 6) * 0.3;
    ctx.globalAlpha = g; fp(ctx, ell(38, 50 - open / 2, 3.4, 2.2), C.gold, 0); fp(ctx, ell(62, 50 - open / 2, 3.4, 2.2), C.gold, 0); ctx.globalAlpha = 1;
    fp(ctx, rr(44, 66, 12, 14, 3), '#c9c3d6', 2.4); fp(ctx, circ(50, 72, 2), C.ink, 0);
  };
  MON.sealcandle = (ctx, t) => {
    shadow(ctx, 50, 96, 26);
    fp(ctx, ell(50, 90, 26, 7), C.gold2);
    fp(ctx, P('M34 32 L66 32 L66 86 Q50 92 34 86 Z'), '#e9edff');
    fp(ctx, P('M40 32 Q40 42 44 44 Q46 36 50 32 Z'), C.white, 0);
    fp(ctx, P('M60 32 Q62 50 58 52 Q56 40 54 32 Z'), C.white, 0);
    fp(ctx, circ(50, 70, 9), null, 2.4, C.violet); fp(ctx, P('M50 62 L50 78 M43 70 L57 70'), null, 2.4, C.violet);
    line(ctx, [50, 32, 50, 24], C.ink, 3);
    flame(ctx, 50, 18, 1, C.sky, C.white, t);
    eyes(ctx, 44, 56, 48, 3.6, { blink: blinkAt(t, 0.9) });
    smile(ctx, 50, 56, 2.6);
  };
  MON.nocturne = (ctx, t) => {
    const out = '#8b78c0';
    const b = Math.sin(t * 2) * 2;
    ctx.globalAlpha = 0.35; fp(ctx, ell(50, 95, 36, 6), '#5b3a8a', 0); ctx.globalAlpha = 1;
    ctx.save(); ctx.translate(0, b);
    fp(ctx, P('M30 40 Q50 34 70 40 L76 92 L62 98 L56 80 L44 80 L38 98 L24 92 Z'), '#1a1324', LW, out);
    fp(ctx, P('M44 40 L50 60 L56 40 Z'), C.white, 2);
    fp(ctx, P('M45 42 L50 46 L55 42 L55 49 L50 46 L45 49 Z'), C.red2, 1.6);
    // 촛대
    line(ctx, [20, 70, 20, 40], C.gold2, 3.4);
    line(ctx, [10, 48, 30, 48], C.gold2, 3);
    for (const x of [10, 20, 30]) { fp(ctx, rr(x - 2.5, 36, 5, 12, 1.5), C.cream, 1.6); flame(ctx, x, 31, 0.45, C.lilac, C.white, t + x); }
    fp(ctx, ell(24, 70, 6, 5), C.white, 2.4);
    // 그림자 조각
    ctx.globalAlpha = 0.85; fp(ctx, P(`M80 ${52 + Math.sin(t * 3) * 2} q8 -8 12 2 q-4 10 -12 6 q-6 -4 0 -8 Z`), '#6b4aa8', 2, out); ctx.globalAlpha = 1;
    fp(ctx, ell(76, 64, 6, 5), C.white, 2.4);
    // 머리
    fp(ctx, ell(50, 24, 14, 17), '#1a1324', LW, out);
    fp(ctx, P('M37 18 Q50 4 63 18 Q56 12 50 14 Q44 12 37 18 Z'), '#2a1f3a', 0);
    const g = 0.75 + Math.sin(t * 4) * 0.25;
    ctx.globalAlpha = g; fp(ctx, circ(55, 24, 3.4), C.gold, 0); ctx.globalAlpha = 1;
    fp(ctx, circ(55, 24, 6), null, 2, C.gold2);
    line(ctx, [55, 30, 57, 40], C.gold2, 1.4);
    curve(ctx, 'M44 32 Q48 34 52 32', C.white, 1.8);
    ctx.restore();
  };
  MON.mirrorbat_king = (ctx, t) => MON.mirrorbat(ctx, t, { king: true });
  MON.director = (ctx, t) => MON.giggledoll(ctx, t, { director: true });
  MON.lockmimic_king = (ctx, t) => MON.lockmimic(ctx, t, { king: true });

  // ───────── 아이콘 ─────────
  function flask(ctx, liquid, big) {
    const s = big ? 1.12 : 1;
    ctx.save(); ctx.translate(50, 56); ctx.scale(s, s); ctx.translate(-50, -56);
    fp(ctx, P('M40 18 L60 18 L60 34 Q80 42 80 62 Q80 88 50 88 Q20 88 20 62 Q20 42 40 34 Z'), '#e9f2ff');
    fp(ctx, P('M24 60 Q50 52 76 60 Q76 84 50 84 Q24 84 24 60 Z'), liquid, 0);
    fp(ctx, P('M40 18 L60 18 L60 34 Q80 42 80 62 Q80 88 50 88 Q20 88 20 62 Q20 42 40 34 Z'), null, LW);
    fp(ctx, rr(37, 10, 26, 12, 3), C.tan);
    shine(ctx, 34, 52, 6, 10, 0.8);
    if (big) fp(ctx, rr(36, 36, 28, 6, 2), C.gold, 2);
    ctx.restore();
  }
  const ICON = {
    potion_red: (c) => flask(c, C.red),
    potion_big: (c) => flask(c, '#ff6f8f', true),
    potion_blue: (c) => flask(c, C.blue),
    herb: (c) => {
      for (const [r, x] of [[-0.5, 38], [0, 50], [0.5, 62]]) { c.save(); c.translate(x, 70); c.rotate(r); fp(c, P('M0 0 Q-14 -24 0 -48 Q14 -24 0 0 Z'), C.moss); line(c, [0, -4, 0, -40], C.moss2, 2); c.restore(); }
      fp(c, rr(40, 66, 20, 10, 3), C.tan); line(c, [50, 76, 50, 92], C.moss2, 4);
    },
    salt: (c) => {
      fp(c, P('M28 38 Q26 88 50 90 Q74 88 72 38 Z'), C.cream);
      fp(c, P('M30 38 Q50 26 70 38 Q50 46 30 38 Z'), C.cream2);
      fp(c, rr(30, 26, 40, 8, 4), C.violet);
      for (const [x, y] of [[44, 60], [56, 70], [48, 76], [58, 56]]) { fp(c, P(`M${x} ${y - 4} L${x + 4} ${y} L${x} ${y + 4} L${x - 4} ${y} Z`), C.white, 1.6); }
    },
    smoke: (c) => { fp(c, circ(50, 56, 30), '#a8a2b8'); curve(c, 'M34 56 Q44 40 56 52 Q64 60 58 68', C.white, 4); shine(c, 40, 42, 7); },
    feather: (c) => {
      fp(c, P('M30 86 Q34 40 74 14 Q82 44 52 72 Q42 80 30 86 Z'), C.white);
      line(c, [30, 86, 70, 22], C.grey, 2.6);
      for (let i = 0; i < 4; i++) line(c, [42 + i * 7, 66 - i * 11, 52 + i * 8, 64 - i * 12], C.grey2, 1.4);
    },
    charm: (c) => {
      fp(c, rr(30, 16, 40, 68, 3), C.red);
      fp(c, rr(36, 24, 28, 52, 2), null, 2.4, C.gold);
      star(c, 50, 50, 10, C.gold);
      line(c, [50, 16, 50, 6], C.ink, 3); fp(c, circ(50, 6, 3), C.amber, 0);
    },
    lamp: (c) => {
      fp(c, P('M30 40 L70 40 L74 84 L26 84 Z'), '#f7c26a');
      fp(c, rr(26, 80, 48, 8, 3), C.brown);
      fp(c, rr(36, 30, 28, 12, 3), C.brown);
      flame(c, 50, 24, 0.8, C.amber, C.gold, 0);
      shine(c, 38, 56, 4, 10);
    },
    key: (c) => {
      fp(c, circ(32, 40, 16), null, 8, C.ink); fp(c, circ(32, 40, 16), null, 4.5, '#c08a55');
      line(c, [44, 50, 80, 82], C.ink, 9); line(c, [44, 50, 80, 82], '#c08a55', 5);
      line(c, [68, 72, 60, 80], C.ink, 8); line(c, [68, 72, 60, 80], '#c08a55', 4);
      line(c, [76, 80, 70, 86], C.ink, 8); line(c, [76, 80, 70, 86], '#c08a55', 4);
    },
    dew: (c) => {
      fp(c, P('M50 12 Q76 46 74 62 Q72 86 50 86 Q28 86 26 62 Q24 46 50 12 Z'), '#bfe6ff');
      fp(c, P('M50 50 A10 10 0 1 0 60 66 A8 8 0 1 1 50 50 Z'), C.gold, 0);
      shine(c, 40, 56, 5, 9);
    },
    sand: (c) => {
      fp(c, rr(24, 10, 52, 8, 3), C.brown); fp(c, rr(24, 82, 52, 8, 3), C.brown);
      fp(c, P('M30 18 L70 18 Q70 40 52 50 Q70 60 70 82 L30 82 Q30 60 48 50 Q30 40 30 18 Z'), '#eaf3ff');
      fp(c, P('M36 74 L64 74 L66 80 L34 80 Z'), C.gold, 0);
      fp(c, P('M42 30 L58 30 Q56 40 50 44 Q44 40 42 30 Z'), C.gold, 0);
      line(c, [50, 48, 50, 72], C.gold, 2);
    },
    spring: (c) => { for (let i = 0; i < 5; i++) curve(c, `M30 ${24 + i * 12} Q50 ${16 + i * 12} 70 ${24 + i * 12} Q50 ${32 + i * 12} 30 ${24 + i * 12}`, C.grey2, 4); },
    strap: (c) => { fp(c, P('M20 30 Q50 10 80 30 L76 40 Q50 22 24 40 Z'), C.brown); fp(c, rr(40, 34, 20, 50, 4), C.brown); fp(c, rr(42, 74, 16, 12, 2), C.gold, 2.4); },
    cursed: (c, t) => {
      const g = 0.45 + Math.sin((t || 0) * 3) * 0.2;
      c.globalAlpha = g; fp(c, circ(50, 52, 42), C.violet, 0); c.globalAlpha = 1;
      fp(c, rr(22, 30, 56, 50, 6), C.plum);
      line(c, [22, 40, 78, 72], '#c9c3d6', 5); line(c, [22, 72, 78, 40], '#c9c3d6', 5);
      fp(c, rr(42, 46, 16, 16, 3), C.gold, 2.4);
      c.fillStyle = C.ink; c.font = 'bold 13px sans-serif'; c.textAlign = 'center'; c.fillText('?', 50, 59);
    },
    jar: (c, t) => {
      const g = 0.35 + Math.sin((t || 0) * 3) * 0.15;
      c.globalAlpha = g; fp(c, circ(50, 56, 40), C.violet, 0); c.globalAlpha = 1;
      fp(c, P('M32 30 L68 30 Q90 44 86 66 Q82 90 50 92 Q18 90 14 66 Q10 44 32 30 Z'), '#b8673f');
      fp(c, rr(30, 20, 40, 12, 4), '#9a5232');
      fp(c, P('M18 58 Q50 66 82 58'), null, 3, '#7a3d22');
      curve(c, 'M40 70 Q50 60 60 70 Q52 78 46 72', C.lilac, 3);
      eyes(c, 40, 60, 50, 3.4, { blink: blinkAt(t, 0.3) });
      smile(c, 50, 58, 3);
      shine(c, 30, 46, 4, 8, 0.5);
    },
    coin: (c) => { fp(c, circ(50, 50, 30), '#d9d6e6'); fp(c, circ(50, 50, 22), null, 3, '#9a95ad'); star(c, 50, 50, 10, '#f3f0fb'); shine(c, 38, 36, 6); },
    // 골동품
    musicbox: (c) => { fp(c, rr(18, 44, 64, 40, 5), C.brown); fp(c, rr(18, 44, 64, 10, 3), C.gold2, 2.6); fp(c, P('M18 44 L28 22 L92 22 L82 44 Z'), C.tan); line(c, [82, 64, 94, 64], C.ink, 4); fp(c, circ(94, 64, 4), C.gold, 2); curve(c, 'M44 36 L44 14 L56 10 L56 30', C.ink, 3); fp(c, ell(41, 37, 4, 3), C.ink, 0); fp(c, ell(53, 32, 4, 3), C.ink, 0); },
    mirror: (c) => { fp(c, rr(44, 60, 12, 34, 4), C.gold2); fp(c, ell(50, 36, 24, 28), C.gold2); fp(c, ell(50, 36, 18, 22), '#cfeaff', 2.4); shine(c, 42, 28, 5, 9); },
    teapot: (c) => { curve(c, 'M24 52 Q8 42 12 30', C.ink, 9); curve(c, 'M24 52 Q8 42 12 30', C.cream, 5); curve(c, 'M76 46 Q92 52 84 70', C.ink, 9); curve(c, 'M76 46 Q92 52 84 70', C.cream, 5); fp(c, ell(50, 60, 30, 24), C.cream); fp(c, ell(50, 36, 18, 6), C.cream); fp(c, circ(50, 28, 5), C.rose); for (const x of [38, 50, 62]) fp(c, circ(x, 62, 3.4), C.rose, 0); },
    diary: (c) => { fp(c, rr(22, 14, 54, 72, 4), '#5b3a8c'); fp(c, rr(26, 18, 50, 66, 3), C.cream, 2); fp(c, rr(22, 14, 14, 72, 3), '#4a2e74'); fp(c, rr(70, 42, 12, 16, 2), C.gold, 2.4); for (const y of [32, 42, 52, 62]) line(c, [42, y, 64, y], C.cream2, 3); },
    broom: (c) => { line(c, [74, 12, 38, 64], C.ink, 9); line(c, [74, 12, 38, 64], C.brown, 5); fp(c, P('M38 56 L20 88 L44 92 L50 66 Z'), C.tan); line(c, [36, 62, 48, 70], C.red2, 4); },
    doll: (c) => { fp(c, P('M32 60 L68 60 L76 92 L24 92 Z'), C.rose); fp(c, circ(50, 40, 20), '#fbf3ea'); fp(c, P('M30 38 Q32 18 50 18 Q68 18 70 38 Q58 28 50 32 Q42 28 30 38 Z'), C.gold, 3); eyes(c, 43, 57, 42, 3); smile(c, 50, 49, 4); blush(c, 37, 47, 3.5); blush(c, 63, 47, 3.5); },
    watch: (c) => { fp(c, circ(50, 56, 30), C.gold2); fp(c, circ(50, 56, 23), C.cream, 2.4); fp(c, rr(44, 14, 12, 12, 3), C.gold2); line(c, [50, 56, 50, 40], C.ink, 3); line(c, [50, 56, 62, 60], C.ink, 3); fp(c, circ(50, 56, 2.6), C.ink, 0); },
    brooch: (c) => { fp(c, P('M50 10 L86 50 L50 90 L14 50 Z'), C.gold2); fp(c, circ(50, 50, 20), '#2c2a52', 2.6); fp(c, P('M48 36 A14 14 0 1 0 62 58 A11 11 0 1 1 48 36 Z'), C.gold, 0); },
    mirror2: (c) => { ICON.mirror(c); line(c, [40, 22, 52, 40, 46, 52, 58, 60], C.ink, 2.2); },
    candle: (c) => { fp(c, ell(50, 86, 26, 7), '#9d7e5b'); line(c, [50, 82, 50, 52], '#9d7e5b', 7); fp(c, ell(50, 52, 14, 4), '#9d7e5b'); fp(c, rr(43, 26, 14, 26, 3), C.cream); flame(c, 50, 18, 0.7, C.amber, C.gold, 0); },
    ribbon: (c) => { fp(c, P('M50 44 L18 26 L22 62 Z'), C.rose); fp(c, P('M50 44 L82 26 L78 62 Z'), C.rose); fp(c, P('M46 48 L36 88 L46 80 L50 90 Z'), C.rose); fp(c, P('M54 48 L64 88 L54 80 L50 90 Z'), C.rose); fp(c, circ(50, 46, 8), '#e7799a'); },
    cup: (c) => { curve(c, 'M76 46 Q92 50 84 66 Q80 72 72 68', C.ink, 9); curve(c, 'M76 46 Q92 50 84 66 Q80 72 72 68', C.cream, 5); fp(c, P('M20 40 L80 40 Q78 82 50 84 Q22 82 20 40 Z'), C.cream); fp(c, ell(50, 40, 30, 7), '#9c6238'); fp(c, P('M64 34 L72 34 L68 42 Z'), C.ink, 0); },
    bell: (c) => { fp(c, P('M24 72 Q24 30 50 26 Q76 30 76 72 Z'), C.gold); fp(c, rr(18, 68, 64, 8, 4), C.gold2); fp(c, circ(50, 80, 6), C.gold2); fp(c, circ(50, 22, 5), null, 3, C.gold2); line(c, [30, 50, 70, 50], C.red, 4); },
    magnifier: (c) => { line(c, [62, 62, 86, 88], C.ink, 11); line(c, [62, 62, 86, 88], C.brown, 7); fp(c, circ(42, 42, 26), '#d9f0ff'); fp(c, circ(42, 42, 26), null, 6, C.gold2); shine(c, 34, 32, 6, 9); },
    thimble: (c) => { fp(c, P('M28 84 L32 30 Q50 16 68 30 L72 84 Z'), '#d9d6e6'); for (let y = 36; y < 80; y += 10) for (let x = 38; x < 66; x += 8) fp(c, circ(x + ((y / 10) % 2) * 4, y, 1.8), C.grey2, 0); fp(c, rr(26, 78, 48, 8, 3), '#c4c0d4'); },
    skull: (c) => { fp(c, circ(50, 30, 9), null, 4, C.gold2); fp(c, P('M28 56 Q28 34 50 34 Q72 34 72 56 Q72 68 64 70 L64 80 L36 80 L36 70 Q28 68 28 56 Z'), C.bone); fp(c, ell(41, 56, 6, 7), C.ink, 0); fp(c, ell(59, 56, 6, 7), C.ink, 0); for (const x of [44, 50, 56]) line(c, [x, 72, x, 78], C.ink, 1.8); },
    eye: (c) => { fp(c, circ(50, 50, 32), C.white); fp(c, circ(56, 50, 16), C.red); fp(c, circ(56, 50, 8), C.ink, 0); shine(c, 40, 38, 7); },
    quill: (c) => { fp(c, P('M24 90 Q30 50 78 12 Q80 40 60 62 Q46 74 24 90 Z'), '#4a3560'); line(c, [24, 90, 72, 24], C.ice, 3); fp(c, P('M18 96 L24 90 L28 94 Z'), C.ink, 1.6); },
    pin: (c) => { line(c, [24, 84, 70, 30], C.grey2, 4); star(c, 72, 28, 16, C.gold); fp(c, circ(72, 28, 4), C.violet, 0); },
    moonkey: (c) => { fp(c, P('M30 18 A22 22 0 1 0 52 52 A17 17 0 1 1 30 18 Z'), C.gold); line(c, [46, 50, 82, 86], C.ink, 9); line(c, [46, 50, 82, 86], C.gold, 5); line(c, [70, 74, 62, 82], C.ink, 8); line(c, [70, 74, 62, 82], C.gold, 4); },
    // UI
    bag: (c) => { fp(c, P('M22 44 Q22 90 50 90 Q78 90 78 44 Q50 36 22 44 Z'), C.tan); fp(c, P('M34 42 Q36 20 50 20 Q64 20 66 42'), null, 6, C.brown); fp(c, rr(42, 52, 16, 12, 3), C.gold, 2.4); },
    book: (c) => { fp(c, rr(20, 16, 60, 70, 5), '#3f6b8f'); fp(c, rr(24, 18, 54, 64, 3), C.cream, 2); fp(c, rr(20, 16, 12, 70, 3), '#2f5574'); star(c, 56, 48, 12, C.gold); },
    medal: (c) => { fp(c, P('M36 10 L50 40 L64 10 Z'), C.red); fp(c, circ(50, 60, 26), C.gold); star(c, 50, 60, 13, '#fff1a8'); },
    gear: (c) => { for (let i = 0; i < 8; i++) { c.save(); c.translate(50, 50); c.rotate((i * Math.PI) / 4); fp(c, rr(-7, -42, 14, 18, 3), C.grey); c.restore(); } fp(c, circ(50, 50, 28), C.grey); fp(c, circ(50, 50, 11), C.plum2); },
    heart: (c) => { fp(c, P('M50 84 Q14 58 18 34 Q24 14 42 20 Q50 24 50 32 Q50 24 58 20 Q76 14 82 34 Q86 58 50 84 Z'), C.red); shine(c, 32, 34, 5); },
    witch: (c, t) => drawRumi(c, { t }),
  };

  // ───────── 타일 ─────────
  function hash(x, y, f) { let h = (x * 374761393 + y * 668265263 + f * 2147483647) | 0; h = (h ^ (h >>> 13)) * 1274126177; return ((h ^ (h >>> 16)) >>> 0) / 4294967296; }
  function drawFloor(ctx, x, y, s, pal, f) {
    const h = hash(x, y, f);
    ctx.fillStyle = h < 0.5 ? pal.floor : pal.floor2;
    ctx.fillRect(x * s, y * s, s + 0.5, s + 0.5);
    ctx.fillStyle = 'rgba(255,255,255,0.05)';
    if (h > 0.3) ctx.fillRect(x * s + s * 0.15, y * s + s * 0.2, s * 0.3, s * 0.08);
    if (h > 0.6) ctx.fillRect(x * s + s * 0.55, y * s + s * 0.62, s * 0.28, s * 0.07);
    ctx.fillStyle = 'rgba(0,0,0,0.12)';
    ctx.fillRect(x * s, y * s + s - 1, s, 1);
    ctx.fillRect(x * s + s - 1, y * s, 1, s);
  }
  function drawWall(ctx, x, y, s, pal, frontVisible) {
    ctx.fillStyle = pal.wallTop;
    ctx.fillRect(x * s, y * s, s + 0.5, s + 0.5);
    if (frontVisible) {
      const fh = s * 0.42;
      ctx.fillStyle = pal.wall;
      ctx.fillRect(x * s, y * s + s - fh, s + 0.5, fh + 0.5);
      ctx.fillStyle = 'rgba(0,0,0,0.25)';
      ctx.fillRect(x * s, y * s + s - fh + fh * 0.5, s, 1);
      ctx.fillRect(x * s + s * ((x % 2) ? 0.3 : 0.65), y * s + s - fh, 1, fh * 0.5);
      ctx.fillRect(x * s + s * ((x % 2) ? 0.7 : 0.25), y * s + s - fh * 0.5, 1, fh * 0.5);
    }
    ctx.fillStyle = 'rgba(255,255,255,0.07)';
    ctx.fillRect(x * s, y * s, s, 1.5);
  }
  function drawStairsDown(ctx, px, py, s, glow) {
    const g = ctx.createRadialGradient(px + s / 2, py + s / 2, 1, px + s / 2, py + s / 2, s * 0.6);
    g.addColorStop(0, '#000'); g.addColorStop(1, 'rgba(0,0,0,0.2)');
    ctx.fillStyle = g; ctx.fillRect(px + s * 0.1, py + s * 0.1, s * 0.8, s * 0.8);
    ctx.fillStyle = glow; ctx.globalAlpha = 0.85;
    for (let i = 0; i < 3; i++) ctx.fillRect(px + s * (0.2 + i * 0.08), py + s * (0.28 + i * 0.18), s * (0.6 - i * 0.16), s * 0.07);
    ctx.globalAlpha = 1;
    ctx.strokeStyle = glow; ctx.lineWidth = 1.5; ctx.strokeRect(px + s * 0.1, py + s * 0.1, s * 0.8, s * 0.8);
  }
  function drawStairsUp(ctx, px, py, s) {
    ctx.fillStyle = 'rgba(255,240,200,0.12)'; ctx.fillRect(px + 2, py + 2, s - 4, s - 4);
    ctx.fillStyle = '#d8c9a8';
    for (let i = 0; i < 3; i++) ctx.fillRect(px + s * (0.2 + i * 0.1), py + s * (0.62 - i * 0.18), s * (0.6 - i * 0.2), s * 0.12);
    ctx.fillStyle = '#fff3c9';
    ctx.beginPath(); ctx.moveTo(px + s * 0.5, py + s * 0.08); ctx.lineTo(px + s * 0.66, py + s * 0.24); ctx.lineTo(px + s * 0.34, py + s * 0.24); ctx.closePath(); ctx.fill();
  }
  function drawDoor(ctx, px, py, s, open) {
    if (open) { ctx.fillStyle = '#0c0812'; ctx.fillRect(px + s * 0.18, py + s * 0.12, s * 0.64, s * 0.88); return; }
    ctx.fillStyle = C.brown; ctx.fillRect(px + s * 0.1, py + s * 0.06, s * 0.8, s * 0.94);
    ctx.fillStyle = C.brown2; for (const k of [0.35, 0.6]) ctx.fillRect(px + s * k, py + s * 0.06, 1.2, s * 0.94);
    ctx.fillStyle = '#5c5468'; ctx.fillRect(px + s * 0.1, py + s * 0.3, s * 0.8, s * 0.08); ctx.fillRect(px + s * 0.1, py + s * 0.72, s * 0.8, s * 0.08);
    ctx.fillStyle = '#c9c3d6'; ctx.fillRect(px + s * 0.4, py + s * 0.45, s * 0.2, s * 0.2);
    ctx.fillStyle = C.ink; ctx.fillRect(px + s * 0.48, py + s * 0.5, s * 0.04, s * 0.1);
  }
  function drawChestTile(ctx, px, py, s, kind) {
    const k = s / 100;
    ctx.save(); ctx.translate(px, py); ctx.scale(k, k);
    const lw = 6;
    if (kind === 'open') {
      fp(ctx, rr(20, 50, 60, 30, 5), C.brown2, lw); fp(ctx, P('M20 50 L28 26 L72 26 L80 50 Z'), C.brown, lw);
    } else {
      fp(ctx, rr(18, 44, 64, 38, 6), kind === 'locked' ? '#6f6784' : C.brown, lw);
      fp(ctx, P('M16 48 Q18 22 50 20 Q82 22 84 48 Z'), kind === 'locked' ? '#8d84a0' : C.tan, lw);
      fp(ctx, rr(16, 44, 68, 9, 3), C.gold, 4);
      fp(ctx, rr(42, 50, 16, 18, 3), kind === 'locked' ? '#c9c3d6' : C.gold, 4);
    }
    ctx.restore();
  }
  function drawSpriteTile(ctx, fn, px, py, s, t, scale) {
    const k = (s / 100) * (scale || 1);
    ctx.save();
    ctx.translate(px + (s - 100 * k) / 2, py + (s - 100 * k) / 2);
    ctx.scale(k, k);
    fn(ctx, t);
    ctx.restore();
  }

  // ───────── 필드 소품 (100×100 상자) ─────────
  const PROP = {
    well: (c, t, o) => {
      fp(c, ell(50, 72, 34, 14), '#7d7590'); fp(c, rr(16, 50, 68, 24, 6), '#8d84a0');
      for (const x of [28, 44, 60]) line(c, [x, 52, x + 4, 72], '#6f6784', 2);
      fp(c, ell(50, 50, 34, 12), o && o.open ? '#152040' : '#5f3b27');
      if (o && o.open) { c.globalAlpha = 0.5 + Math.sin(t * 3) * 0.3; fp(c, ell(50, 50, 18, 6), C.gold, 0); c.globalAlpha = 1; }
      else { line(c, [22, 48, 78, 52], C.brown2, 3); line(c, [24, 54, 76, 46], C.brown2, 3); }
      line(c, [18, 50, 18, 16], C.brown, 5); line(c, [82, 50, 82, 16], C.brown, 5);
      fp(c, P('M10 20 L50 4 L90 20 Z'), '#7b4a8e');
    },
    cauldron: (c, t) => {
      fp(c, ell(50, 88, 30, 6), '#000', 0);
      line(c, [30, 80, 26, 92], C.ink, 5); line(c, [70, 80, 74, 92], C.ink, 5);
      fp(c, P('M18 46 Q18 86 50 86 Q82 86 82 46 Z'), '#3a3348');
      fp(c, ell(50, 46, 34, 10), '#2a2438');
      fp(c, ell(50, 46, 28, 7), '#9b7be0', 0);
      for (let i = 0; i < 3; i++) { const y = 40 - ((t * 18 + i * 12) % 30); c.globalAlpha = 0.6 - (40 - y) / 60; fp(c, circ(40 + i * 10, y, 4), C.lilac, 0); }
      c.globalAlpha = 1;
      for (const x of [30, 50, 70]) flame(c, x, 96, 0.35, C.amber, C.gold, t + x);
    },
    bed: (c) => {
      fp(c, rr(12, 30, 76, 60, 8), '#5f3b27'); fp(c, rr(16, 34, 68, 52, 6), '#e6d4b6');
      fp(c, rr(16, 52, 68, 34, 6), '#7d5cc6'); for (const x of [30, 50, 70]) star(c, x, 68, 5, C.gold);
      fp(c, rr(26, 38, 48, 12, 6), C.white, 2.4);
    },
    piano: (c) => {
      fp(c, rr(8, 18, 84, 66, 4), '#2b2236'); fp(c, rr(12, 54, 76, 14, 2), C.white, 2);
      for (let i = 0; i < 7; i++) if (i !== 2 && i !== 6) fp(c, rr(20 + i * 10, 54, 5, 8, 1), C.ink, 0);
      line(c, [14, 84, 14, 96], C.ink, 5); line(c, [86, 84, 86, 96], C.ink, 5);
      fp(c, rr(30, 24, 40, 20, 2), C.cream, 2); for (const y of [30, 36]) line(c, [34, y, 66, y], C.grey2, 1.4);
    },
    bench: (c) => { fp(c, rr(14, 40, 72, 18, 4), '#2b2236'); line(c, [22, 58, 22, 88], C.ink, 6); line(c, [78, 58, 78, 88], C.ink, 6); fp(c, rr(16, 38, 68, 6, 3), '#7d5cc6', 0); },
    locker: (c, t, o) => {
      fp(c, rr(18, 6, 64, 90, 3), o && o.mine ? '#5a8ee0' : '#6f6784');
      for (const y of [20, 26, 32]) line(c, [30, y, 70, y], C.ink, 2);
      fp(c, rr(62, 52, 8, 14, 2), C.gold, 2);
      if (o && o.mine) fp(c, rr(34, 70, 32, 12, 2), C.cream, 2);
    },
    stand: (c) => { line(c, [50, 50, 50, 92], C.ink, 4); line(c, [36, 94, 64, 94], C.ink, 4); fp(c, P('M20 16 L80 16 L74 54 L26 54 Z'), '#4a4359'); fp(c, rr(30, 18, 40, 30, 1), C.cream, 2); for (const y of [26, 32, 38]) line(c, [34, y, 66, y], C.grey2, 1.4); },
    drum: (c) => { fp(c, ell(50, 74, 34, 12), '#b93a52'); fp(c, rr(16, 40, 68, 34, 2), '#e5566e', 0); fp(c, ell(50, 40, 34, 12), C.cream); for (const x of [24, 40, 60, 76]) line(c, [x, 46, x + 4, 78], C.gold, 2.4); line(c, [70, 14, 54, 36], C.brown, 4); fp(c, circ(72, 12, 5), C.cream); },
    curtain: (c, t) => { const w2 = Math.sin(t * 1.5) * 3; fp(c, rr(6, 4, 88, 8, 3), C.gold2); fp(c, P(`M10 10 Q20 50 ${12 + w2} 96 L50 96 Q42 50 48 10 Z`), '#8e2f45'); fp(c, P(`M52 10 Q58 50 50 96 L${88 + w2} 96 Q80 50 90 10 Z`), '#8e2f45'); },
    trash: (c) => { fp(c, P('M26 30 L74 30 L68 92 L32 92 Z'), '#6f6784'); fp(c, rr(22, 24, 56, 8, 3), '#8d84a0'); for (const x of [40, 50, 60]) line(c, [x, 38, x, 84], '#4a4359', 2); fp(c, P('M38 24 Q44 10 56 16 Q62 22 54 24 Z'), C.cream, 2); },
    lectern: (c, t, o) => { fp(c, P('M18 30 L82 30 L74 50 L26 50 Z'), C.brown); line(c, [50, 50, 50, 90], C.brown2, 8); fp(c, rr(30, 88, 40, 8, 3), C.brown2); if (o && o.book) { fp(c, P('M24 28 L50 34 L76 28 L76 18 L50 24 L24 18 Z'), '#5b3a8c', 2.4); } },
    chest: (c) => drawChestTile(c, 0, 0, 100, 'closed'),
    chestOpen: (c) => drawChestTile(c, 0, 0, 100, 'open'),
    book: (c) => { fp(c, rr(30, 70, 40, 24, 2), C.brown); fp(c, P('M14 30 L50 38 L86 30 L86 70 L50 78 L14 70 Z'), C.cream); line(c, [50, 38, 50, 78], C.cream2, 3); for (const y of [46, 54, 62]) { line(c, [22, y - 4, 44, y], C.grey2, 1.6); line(c, [56, y, 78, y - 4], C.grey2, 1.6); } star(c, 66, 46, 5, C.gold); },
    shed: (c, t) => { fp(c, rr(14, 40, 72, 54, 3), '#6b4a34'); fp(c, P('M6 44 L50 10 L94 44 Z'), '#3e5a34'); fp(c, rr(40, 62, 20, 32, 2), '#3a261a'); fp(c, rr(22, 52, 14, 12, 2), C.gold, 2); c.globalAlpha = 0.3 + Math.sin(t * 2) * 0.15; fp(c, circ(29, 58, 14), C.gold, 0); c.globalAlpha = 1; },
    cart: (c) => { fp(c, rr(14, 30, 72, 44, 5), '#8a5a3c'); for (let i = 0; i < 5; i++) fp(c, rr(20 + i * 12, 14 + (i % 2) * 6, 10, 20 - (i % 2) * 6, 2), ['#e5566e', '#5a8ee0', '#ffcf5a', '#90e4c0', '#bfa2ee'][i], 2.4); fp(c, circ(28, 80, 9), C.ink, 0); fp(c, circ(72, 80, 9), C.ink, 0); fp(c, circ(28, 80, 4), C.grey, 0); fp(c, circ(72, 80, 4), C.grey, 0); },
  };

  // 스프라이트 그리기 진입점
  function draw(ctx, name, x, y, size, opts) {
    const o = opts || {};
    const k = size / 100;
    ctx.save();
    ctx.translate(x, y);
    ctx.scale(k, k);
    ctx.lineJoin = 'round'; ctx.lineCap = 'round';
    if (name === 'rumi') drawRumi(ctx, o);
    else if (name === 'cat') drawCat(ctx, o);
    else if (MON[name]) MON[name](ctx, o.t || 0, o);
    else if (ICON[name]) ICON[name](ctx, o.t || 0);
    else if (name === 'student') drawStudent(ctx, o);
    else if (name === 'batgranny') drawBatGranny(ctx, o);
    else if (name === 'mummy') drawMummy(ctx, o);
    else if (name === 'cat2') drawMerchantCat(ctx, o);
    else if (name === 'portraits') drawPortraits(ctx, o);
    else if (name === 'letter') drawLetter(ctx, o);
    else if (name === 'scroll') drawScroll(ctx, o);
    else if (name === 'owl') drawOwl(ctx, o);
    else if (name === 'gardener') drawGardener(ctx, o);
    else if (PROP[name]) PROP[name](ctx, o.t || 0, o);
    ctx.restore();
  }
  function portraitOf(npcId) {
    const n = W.DATA.NPCS[npcId];
    if (!n) return { name: 'letter' };
    switch (n.kind) {
      case 'witch': return { name: 'rumi' };
      case 'cat': return { name: 'cat' };
      case 'letter': return { name: npcId === 'council' ? 'scroll' : 'letter' };
      case 'batgranny': return { name: 'batgranny' };
      case 'mummy': return { name: 'mummy' };
      case 'cat2': return { name: 'cat2' };
      case 'portraits': return { name: 'portraits' };
      case 'owl': return { name: 'owl' };
      case 'gardener': return { name: 'gardener' };
      case 'enemy': return { name: n.enemy };
      default: return { name: 'student', npc: n };
    }
  }

  // 아이콘 이미지 캐시 (DOM의 <img>용)
  const urlCache = new Map();
  function iconURL(name, px, opts) {
    const size = px || 64;
    const ck = name + ':' + size + ':' + (opts ? JSON.stringify(opts) : '');
    if (urlCache.has(ck)) return urlCache.get(ck);
    if (typeof document === 'undefined') return '';
    const cv = document.createElement('canvas');
    cv.width = size * 2; cv.height = size * 2;
    const ctx = cv.getContext('2d');
    draw(ctx, name, 0, 0, size * 2, Object.assign({ t: 0, shadow: false }, opts || {}));
    const url = cv.toDataURL('image/png');
    urlCache.set(ck, url);
    return url;
  }

  // 학교 전경 (허브)
  function drawSchool(ctx, w, h, t) {
    const g = ctx.createLinearGradient(0, 0, 0, h);
    g.addColorStop(0, '#1a1030'); g.addColorStop(1, '#3a2452');
    ctx.fillStyle = g; ctx.fillRect(0, 0, w, h);
    for (let i = 0; i < 40; i++) {
      const sx = hash(i, 1, 3) * w, sy = hash(i, 2, 3) * h * 0.6;
      ctx.globalAlpha = 0.4 + 0.6 * Math.abs(Math.sin(t * 1.5 + i));
      ctx.fillStyle = '#fff6d8'; ctx.fillRect(sx, sy, 1.5, 1.5);
    }
    ctx.globalAlpha = 1;
    const mx = w * 0.8, my = h * 0.28, mr = h * 0.16;
    ctx.fillStyle = 'rgba(255,230,160,0.15)'; ctx.beginPath(); ctx.arc(mx, my, mr * 1.8, 0, TAU); ctx.fill();
    ctx.fillStyle = '#ffeab0'; ctx.beginPath(); ctx.arc(mx, my, mr, 0, TAU); ctx.fill();
    ctx.fillStyle = 'rgba(200,170,110,0.4)'; ctx.beginPath(); ctx.arc(mx - mr * 0.3, my - mr * 0.2, mr * 0.2, 0, TAU); ctx.fill(); ctx.beginPath(); ctx.arc(mx + mr * 0.35, my + mr * 0.3, mr * 0.14, 0, TAU); ctx.fill();
    // 건물
    const base = h * 0.92;
    ctx.fillStyle = '#120b1c';
    const bw = w * 0.62, bx = w * 0.16;
    ctx.fillRect(bx, base - h * 0.42, bw, h * 0.42);
    const tower = (cx, tw, th) => { ctx.fillRect(cx - tw / 2, base - th, tw, th); ctx.beginPath(); ctx.moveTo(cx - tw * 0.7, base - th); ctx.lineTo(cx, base - th - tw * 1.3); ctx.lineTo(cx + tw * 0.7, base - th); ctx.closePath(); ctx.fill(); };
    tower(bx + bw * 0.12, w * 0.08, h * 0.62); tower(bx + bw * 0.5, w * 0.11, h * 0.74); tower(bx + bw * 0.88, w * 0.08, h * 0.58);
    for (let r = 0; r < 2; r++) for (let c = 0; c < 7; c++) {
      const lit = hash(c, r, 9) > 0.45;
      ctx.fillStyle = lit ? `rgba(255,${200 + Math.floor(Math.sin(t * 2 + c) * 20)},120,0.9)` : '#2a1d36';
      ctx.fillRect(bx + bw * (0.08 + c * 0.13), base - h * (0.33 - r * 0.14), w * 0.025, h * 0.07);
    }
    ctx.fillStyle = '#ffd36a'; ctx.fillRect(bx + bw * 0.5 - w * 0.012, base - h * 0.6, w * 0.024, h * 0.05);
    // 봉인 창고 문
    ctx.fillStyle = '#2a1840'; ctx.fillRect(bx + bw * 0.45, base - h * 0.14, bw * 0.1, h * 0.14);
    ctx.globalAlpha = 0.5 + Math.sin(t * 2) * 0.3; ctx.strokeStyle = '#c9a0ff'; ctx.lineWidth = 1.5;
    ctx.strokeRect(bx + bw * 0.45, base - h * 0.14, bw * 0.1, h * 0.14); ctx.globalAlpha = 1;
    // 땅
    ctx.fillStyle = '#0b0712'; ctx.fillRect(0, base, w, h - base);
    // 박쥐
    for (let i = 0; i < 3; i++) {
      const bx2 = ((t * 18 + i * 120) % (w + 60)) - 30, by2 = h * (0.2 + i * 0.08) + Math.sin(t * 3 + i) * 6;
      const f = Math.sin(t * 14 + i) * 3;
      ctx.fillStyle = '#0b0712'; ctx.beginPath(); ctx.moveTo(bx2 - 7, by2 - f); ctx.lineTo(bx2, by2 + 2); ctx.lineTo(bx2 + 7, by2 - f); ctx.lineTo(bx2, by2 - 1); ctx.closePath(); ctx.fill();
    }
  }
  function drawGate(ctx, w, h, t) {
    const g = ctx.createRadialGradient(w / 2, h * 0.55, 10, w / 2, h * 0.55, h);
    g.addColorStop(0, '#3b2a55'); g.addColorStop(1, '#120b1c');
    ctx.fillStyle = g; ctx.fillRect(0, 0, w, h);
    const dw = Math.min(w * 0.5, h * 0.8), dh = h * 0.86, dx = w / 2 - dw / 2, dy = h - dh;
    ctx.fillStyle = '#24183a';
    ctx.beginPath(); ctx.moveTo(dx, h); ctx.lineTo(dx, dy + dw / 2); ctx.arc(w / 2, dy + dw / 2, dw / 2, Math.PI, 0); ctx.lineTo(dx + dw, h); ctx.closePath(); ctx.fill();
    ctx.strokeStyle = '#6b4aa8'; ctx.lineWidth = 3; ctx.stroke();
    ctx.globalAlpha = 0.55 + Math.sin(t * 2) * 0.25;
    ctx.strokeStyle = '#d6b8ff'; ctx.lineWidth = 2;
    const cx = w / 2, cy = dy + dh * 0.5, r = dw * 0.28;
    ctx.beginPath(); ctx.arc(cx, cy, r, 0, TAU); ctx.stroke();
    ctx.beginPath(); for (let i = 0; i < 6; i++) { const a = -Math.PI / 2 + (i * TAU) / 6 + t * 0.3; ctx.lineTo(cx + Math.cos(a) * r, cy + Math.sin(a) * r); } ctx.closePath(); ctx.stroke();
    ctx.globalAlpha = 1;
    ctx.strokeStyle = '#8d84a0'; ctx.lineWidth = 4;
    ctx.beginPath(); ctx.moveTo(dx + 4, dy + dw * 0.3); ctx.lineTo(dx + dw - 4, dy + dh * 0.7); ctx.moveTo(dx + dw - 4, dy + dw * 0.3); ctx.lineTo(dx + 4, dy + dh * 0.7); ctx.stroke();
  }

  W.art = { C, PROP, draw, drawFloor, drawWall, drawStairsDown, drawStairsUp, drawDoor, drawChestTile, drawSpriteTile, ICON, MON, iconURL, portraitOf, drawSchool, drawGate, star, flame, hash };
})();
