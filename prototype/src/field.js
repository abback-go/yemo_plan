/* 저주 매입합니다 — 학교 필드 화면(아르피아식 탐험 지도), 마법 수업 미니게임, 필드 퍼즐 연출 */
(function () {
  'use strict';
  const W = globalThis.W;
  const D = W.DATA, R = W.rules, A = W.art, S = W.audio, F = W.world;
  const U = W.ui, L = U.lib, G = U.G, ACT = U.ACT;
  const { SCREENS, AFTER, $, esc, img, sprite, portrait, sleep, dpr, openSheet, closeSheet, ask, say, toast, statusBar, tabbar,
    addAnim, save, render, go, runBattle, defeat, badgeToast, lootSheet, refreshStatus, maybeEnding } = L;
  const STEP_MS = 110;

  // 구역 분위기(색)
  const THEME = {
    garden: { floor: '#3e5a3b', floor2: '#43603f', path: '#8c806b', path2: '#837760', outdoor: true },
    maze: { floor: '#4a4334', floor2: '#4e4738', path: '#4a4334', path2: '#4e4738', outdoor: true, night: true },
    hall: { floor: '#4d3f5c', floor2: '#524462', path: '#7a3346', path2: '#73304a', wall: '#21182c', wallTop: '#30243f' },
    club: { floor: '#6a4e3a', floor2: '#70543f', path: '#6a4e3a', path2: '#70543f', wall: '#23182a', wallTop: '#3a2a40' },
    classroom: { floor: '#6b5a43', floor2: '#715f47', path: '#6b5a43', path2: '#715f47', wall: '#1f2a24', wallTop: '#2f3d35' },
    classroom2: { floor: '#4a4266', floor2: '#4f466c', path: '#4a4266', path2: '#4f466c', wall: '#1a1530', wallTop: '#2a2246' },
    music: { floor: '#553c50', floor2: '#5a4155', path: '#553c50', path2: '#5a4155', wall: '#1f1420', wallTop: '#33223a' },
    library: { floor: '#4f3d33', floor2: '#544137', path: '#4f3d33', path2: '#544137', wall: '#1c1410', wallTop: '#2e221b' },
  };

  // ───────── 화면 ─────────
  SCREENS.field = () => {
    const s = G.state;
    const a = F.cur(s);
    const pushRoom = a.push && !s.field.libGate;
    const extra = a.id === 'maze' ? '<button class="btn small f-extra" data-act="mazeOut">입구로 돌아가기</button>' : '';
    // 수레 밀기 방에서는 지도를 가리지 않게 지도 아래에 한 줄 조작부를 둔다
    const ctrl = pushRoom ? `<div class="f-ctrl">
        <button class="btn small" data-act="cartReset">되돌리기 <em>${F.platesCovered(s)}/2</em></button>
        <button class="btn small" data-act="fmove" data-arg="-1,0" aria-label="왼쪽">◀</button>
        <button class="btn small" data-act="fmove" data-arg="0,-1" aria-label="위">▲</button>
        <button class="btn small" data-act="fmove" data-arg="0,1" aria-label="아래">▼</button>
        <button class="btn small" data-act="fmove" data-arg="1,0" aria-label="오른쪽">▶</button>
      </div>` : '';
    return `<div class="scr field">
      ${statusBar()}
      <div class="f-head"><b>${esc(a.name)}</b>${a.night ? '<span class="chip curse">밤</span>' : ''}<span class="f-day">${s.day}일째 · 실적 <b style="color:var(--gold)">${s.purified}/5</b></span></div>
      <div class="objective">${img('medal', 'ico sm', 40)}<span>${esc(R.objectiveText(s))}</span></div>
      <div class="f-map"><canvas id="field-cv" aria-label="${esc(a.name)} 지도"></canvas>${extra}
      </div>
      ${ctrl}
      ${tabbar()}
    </div>`;
  };
  function snapField() {
    const s = G.state;
    G.ui.fpos = { x: s.field.x, y: s.field.y }; G.ui.ftween = null; G.ui.fcat = { x: s.field.x, y: s.field.y };
  }
  AFTER.field = () => {
    const cv = $('#field-cv');
    const box = $('.f-map');
    const k = dpr();
    const vw = box.clientWidth, vh = box.clientHeight;
    cv.width = Math.round(vw * k); cv.height = Math.round(vh * k);
    cv.style.width = vw + 'px'; cv.style.height = vh + 'px';
    const a = F.cur(G.state);
    // 너비 11칸까지는 한 화면에 다 보이게 (출입구가 화면 밖으로 밀리지 않도록)
    G.ui.ftile = Math.max(30, Math.min(56, Math.floor(Math.min(vw / Math.min(a.w, 11), vh / Math.min(a.h, 12)))));
    G.ui.farea = a.id;
    snapField();
    const ctx = cv.getContext('2d');
    addAnim('screen', (t) => drawField(ctx, k, vw, vh, t));
    cv.addEventListener('pointerup', onFieldTap);
  };
  function refreshField() {
    if (G.ui.screen !== 'field') return;
    const o = $('.field .objective span'); if (o) o.textContent = R.objectiveText(G.state);
    const ex = $('.f-ctrl em'); if (ex) ex.textContent = `${F.platesCovered(G.state)}/2`;
    refreshStatus();
  }

  // ───────── 그리기 ─────────
  function camera(vw, vh, pv) {
    const a = F.cur(G.state);
    const ts = G.ui.ftile;
    const mw = a.w * ts, mh = a.h * ts;
    const cx = mw <= vw ? (mw - vw) / 2 : Math.max(0, Math.min(mw - vw, (pv.x + 0.5) * ts - vw / 2));
    const cy = mh <= vh ? (mh - vh) / 2 : Math.max(0, Math.min(mh - vh, (pv.y + 0.5) * ts - vh / 2));
    return { cx, cy, ts };
  }
  function visual(now) {
    const tw = G.ui.ftween;
    if (!tw) return G.ui.fpos;
    const p = Math.min(1, (now - tw.start) / tw.dur);
    if (p >= 1) { G.ui.ftween = null; return G.ui.fpos; }
    const e = p < 0.5 ? 2 * p * p : 1 - Math.pow(-2 * p + 2, 2) / 2;
    return { x: tw.fx + (tw.tx - tw.fx) * e, y: tw.fy + (tw.ty - tw.fy) * e };
  }
  function drawField(ctx, k, vw, vh, t) {
    const s = G.state;
    if (!s || G.ui.screen !== 'field') return;
    const a = F.cur(s);
    const th = THEME[a.theme] || THEME.hall;
    const now = performance.now();
    const pv = visual(now);
    const { cx, cy, ts } = camera(vw, vh, pv);
    G.ui.fcam = { cx, cy, ts };
    ctx.setTransform(k, 0, 0, k, 0, 0);
    ctx.fillStyle = th.outdoor ? (th.night ? '#0b0f0c' : '#1d2a1c') : th.wall || '#0c0812';
    ctx.fillRect(0, 0, vw, vh);
    ctx.save();
    ctx.translate(-Math.round(cx), -Math.round(cy));
    ctx.lineJoin = 'round'; ctx.lineCap = 'round';
    const x0 = Math.max(0, Math.floor(cx / ts)), y0 = Math.max(0, Math.floor(cy / ts));
    const x1 = Math.min(a.w - 1, Math.ceil((cx + vw) / ts)), y1 = Math.min(a.h - 1, Math.ceil((cy + vh) / ts));
    // 바닥·벽
    for (let y = y0; y <= y1; y++) for (let x = x0; x <= x1; x++) drawTile(ctx, a, th, x, y, ts, t);
    // 물체(위쪽부터 그려 겹침을 자연스럽게)
    const objs = F.objects(s).filter((o) => F.revealed(s, o.x, o.y));
    const carts = a.id === 'library' ? F.carts(s) : [];
    const route = F.routeExit(s);
    const items = [];
    for (const o of objs) items.push({ y: o.y, draw: () => drawObject(ctx, o, ts, t) });
    for (const [x, y] of carts) items.push({ y, draw: () => A.draw(ctx, 'cart', x * ts + ts * 0.06, y * ts + ts * 0.02, ts * 0.88, { t }) });
    const cat = G.ui.fcat || pv;
    items.push({ y: cat.y - 0.01, draw: () => A.draw(ctx, 'cat', (cat.x + 0.18) * ts, (cat.y + 0.3) * ts, ts * 0.64, { t: t + 0.4 }) });
    items.push({ y: pv.y, draw: () => A.draw(ctx, 'rumi', (pv.x - 0.12) * ts, (pv.y - 0.42) * ts, ts * 1.24, { t, shadow: s.flags.bossDefeated }) });
    // 출입구 이름표 + 목표 화살표 (인물보다 먼저 그려서 인물을 가리지 않게)
    for (const e of a.exits) drawExitLabel(ctx, a, e, ts, t, route && route.x === e.x && route.y === e.y);
    items.sort((p, q) => p.y - q.y).forEach((it) => it.draw());
    // 표시(!) — 지금 할 일이 있는 물체
    for (const o of objs) if (attention(s, o)) bubble(ctx, (o.x + 0.5) * ts, (o.y - 0.55) * ts + Math.sin(t * 4) * 2, ts);
    // 경로 미리보기
    if (G.ui.fpath && G.ui.fpath.length) {
      ctx.fillStyle = 'rgba(255,207,90,0.6)';
      for (const [px, py] of G.ui.fpath) { ctx.beginPath(); ctx.arc((px + 0.5) * ts, (py + 0.5) * ts, ts * 0.07, 0, Math.PI * 2); ctx.fill(); }
    }
    // 안개·밤
    if (a.fog) {
      for (let y = y0; y <= y1; y++) for (let x = x0; x <= x1; x++) {
        if (F.revealed(s, x, y)) continue;
        ctx.fillStyle = A.hash(x, y, 77) < 0.5 ? '#060807' : '#080a09';
        ctx.fillRect(x * ts, y * ts, ts + 0.5, ts + 0.5);
      }
    }
    if (th.night) {
      const px = (pv.x + 0.5) * ts, py = (pv.y + 0.5) * ts;
      const g = ctx.createRadialGradient(px, py, ts * 0.8, px, py, ts * (3.2 + R.stats(s).sight));
      g.addColorStop(0, 'rgba(255,200,120,0.08)'); g.addColorStop(1, 'rgba(4,6,10,0.62)');
      ctx.fillStyle = g; ctx.fillRect(x0 * ts, y0 * ts, (x1 - x0 + 1) * ts, (y1 - y0 + 1) * ts);
    }
    // 떠오르는 글자
    G.ui.ffloats = (G.ui.ffloats || []).filter((m) => now - m.start < 1000);
    for (const m of G.ui.ffloats) {
      const p = (now - m.start) / 1000;
      ctx.globalAlpha = 1 - p;
      ctx.font = `bold ${Math.round(ts * 0.36)}px sans-serif`; ctx.textAlign = 'center';
      ctx.lineWidth = 3; ctx.strokeStyle = '#000'; ctx.fillStyle = m.color;
      const y = (m.y - 0.3 - p * 0.8) * ts;
      ctx.strokeText(m.text, (m.x + 0.5) * ts, y); ctx.fillText(m.text, (m.x + 0.5) * ts, y);
      ctx.globalAlpha = 1;
    }
    ctx.restore();
  }
  function ffloat(x, y, text, color) { (G.ui.ffloats = G.ui.ffloats || []).push({ x, y, text, color: color || '#fff', start: performance.now() }); }
  function attention(s, o) {
    if (o.kind === 'customer') return true;
    if (o.kind === 'npc' && o.cls) return R.classSpells(o.cls).some((id) => R.canLearn(s, id).ok);
    if (o.id === 'desk') return D.QUESTS.some((q) => R.canPurifyQuest(s, q.id));
    if (o.id === 'locker') return !!F.fieldQuest(s, 'music', 'locker') && R.count(s, 'locker_key') > 0;
    if (o.id === 'lectern') return !!F.fieldQuest(s, 'library', 'lectern') && s.field.libGate;
    if (o.id === 'libchest') return s.field.libGate && !s.field.libChest;
    if (o.id === 'shed') return !!F.fieldQuest(s, 'maze', 'shed');
    if (o.id === 'well') return s.field.fountain && !s.field.well;
    return false;
  }
  function bubble(ctx, x, y, ts) {
    const r = ts * 0.2;
    ctx.fillStyle = '#ffcf5a'; ctx.strokeStyle = '#2a1508'; ctx.lineWidth = 2;
    ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.fill(); ctx.stroke();
    ctx.fillStyle = '#2a1508'; ctx.font = `bold ${Math.round(r * 1.5)}px sans-serif`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    ctx.fillText('!', x, y + 1); ctx.textBaseline = 'alphabetic';
  }
  function drawTile(ctx, a, th, x, y, ts, t) {
    const ch = F.tileAt(a, x, y);
    const px = x * ts, py = y * ts;
    const h = A.hash(x, y, 13);
    const floor = (c1, c2) => { ctx.fillStyle = h < 0.5 ? c1 : c2; ctx.fillRect(px, py, ts + 0.5, ts + 0.5); };
    if (ch === '#') {
      if (th.outdoor) return drawHedge(ctx, px, py, ts, x, y, th.night);
      const below = F.tileAt(a, x, y + 1);
      A.drawWall(ctx, x, y, ts, th, y + 1 < a.h && below !== '#' && below !== 'k');
      if (y === 0 && x % 3 === 1 && th !== THEME.library && below !== '#') drawWindow(ctx, px, py, ts, t);
      return;
    }
    // 바닥
    if (ch === ',' ) floor(th.path, th.path2); else floor(th.floor, th.floor2);
    if (th.outdoor && ch !== ',' && h > 0.62) { ctx.fillStyle = 'rgba(160,220,140,0.12)'; ctx.fillRect(px + ts * 0.2, py + ts * 0.3, ts * 0.06, ts * 0.18); ctx.fillRect(px + ts * 0.3, py + ts * 0.26, ts * 0.06, ts * 0.22); }
    if (!th.outdoor) { ctx.fillStyle = 'rgba(0,0,0,0.14)'; ctx.fillRect(px, py + ts - 1, ts, 1); }
    switch (ch) {
      case 'T': drawTree(ctx, px, py, ts, t, x); break;
      case '~': drawWater(ctx, a, px, py, ts, t, x, y); break;
      case '*': for (let i = 0; i < 3; i++) { ctx.fillStyle = ['#f394ad', '#ffcf5a', '#bfa2ee'][(i + x) % 3]; ctx.beginPath(); ctx.arc(px + ts * (0.25 + i * 0.25), py + ts * (0.4 + (i % 2) * 0.25), ts * 0.07, 0, Math.PI * 2); ctx.fill(); } break;
      case '=': drawShelf(ctx, px, py, ts, x + y); break;
      case 'd': drawDesk(ctx, px, py, ts); break;
      case 'k': drawBoard(ctx, px, py, ts, x); break;
      case 'G': if (!G.state.field.libGate) drawGate(ctx, px, py, ts); break;
      case 'o': drawLibPlate(ctx, px, py, ts, t, F.cartAt(G.state, x, y)); break;
      case 'E': drawExit(ctx, a, px, py, ts, x, y, th); break;
      default:
        if (/[1-4]/.test(ch)) drawRunePlate(ctx, px, py, ts, t, Number(ch));
    }
  }
  function drawHedge(ctx, px, py, ts, x, y, night) {
    ctx.fillStyle = night ? '#0f1a12' : '#1e3320'; ctx.fillRect(px, py, ts + 0.5, ts + 0.5);
    const cols = night ? ['#1d3324', '#22402b', '#183020'] : ['#2f5a33', '#376a3b', '#2a502d'];
    for (let i = 0; i < 4; i++) {
      const hx = A.hash(x, y, i + 3), hy = A.hash(y, x, i + 5);
      ctx.fillStyle = cols[i % 3];
      ctx.beginPath(); ctx.arc(px + ts * (0.2 + hx * 0.6), py + ts * (0.2 + hy * 0.6), ts * 0.32, 0, Math.PI * 2); ctx.fill();
    }
    ctx.fillStyle = 'rgba(255,255,255,0.05)'; ctx.fillRect(px, py, ts, 1.5);
  }
  function drawTree(ctx, px, py, ts, t, x) {
    const sw = Math.sin(t * 1.2 + x) * ts * 0.02;
    ctx.fillStyle = 'rgba(0,0,0,0.25)'; ctx.beginPath(); ctx.ellipse(px + ts / 2, py + ts * 0.9, ts * 0.32, ts * 0.08, 0, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#5f3b27'; ctx.fillRect(px + ts * 0.43, py + ts * 0.55, ts * 0.14, ts * 0.36);
    ctx.fillStyle = '#2c5530'; ctx.beginPath(); ctx.arc(px + ts / 2 + sw, py + ts * 0.38, ts * 0.38, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#3a6e3d'; ctx.beginPath(); ctx.arc(px + ts * 0.4 + sw, py + ts * 0.3, ts * 0.2, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#e5566e'; ctx.beginPath(); ctx.arc(px + ts * 0.62 + sw, py + ts * 0.42, ts * 0.05, 0, Math.PI * 2); ctx.fill();
  }
  function drawWater(ctx, a, px, py, ts, t, x, y) {
    const solved = G.state.field.fountain;
    ctx.fillStyle = '#8d84a0'; ctx.fillRect(px, py, ts + 0.5, ts + 0.5);
    const inset = (dx, dy) => F.tileAt(a, x + dx, y + dy) === '~' ? 0 : ts * 0.12;
    const l = inset(-1, 0), r = inset(1, 0), u = inset(0, -1), d = inset(0, 1);
    ctx.fillStyle = solved ? '#3a5a8a' : '#4f8fd0';
    ctx.fillRect(px + l, py + u, ts - l - r + 0.5, ts - u - d + 0.5);
    ctx.globalAlpha = 0.35 + Math.sin(t * 2 + x + y) * 0.15; ctx.fillStyle = solved ? '#ffe680' : '#cfeaff';
    ctx.fillRect(px + ts * 0.2, py + ts * (0.4 + Math.sin(t + x) * 0.1), ts * 0.3, 2);
    ctx.globalAlpha = 1;
    // 가운데 석상
    if (F.tileAt(a, x - 1, y) === '~' && F.tileAt(a, x + 1, y) === '~' && F.tileAt(a, x, y - 1) === '~' && F.tileAt(a, x, y + 1) === '~') {
      ctx.fillStyle = '#c9c3d6'; ctx.fillRect(px + ts * 0.36, py + ts * 0.3, ts * 0.28, ts * 0.5);
      ctx.beginPath(); ctx.arc(px + ts / 2, py + ts * 0.26, ts * 0.16, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = solved ? '#ffe680' : '#8fd3ff';
      for (let i = 0; i < 3; i++) { const p = ((t * 0.8 + i / 3) % 1); ctx.globalAlpha = 1 - p; ctx.beginPath(); ctx.arc(px + ts / 2 + (i - 1) * ts * 0.2 * p, py + ts * (0.1 - 0.1 * Math.sin(p * Math.PI)) + p * ts * 0.4, ts * 0.04, 0, Math.PI * 2); ctx.fill(); }
      ctx.globalAlpha = 1;
    }
  }
  function drawRunePlate(ctx, px, py, ts, t, n) {
    const f = G.state.field;
    const lit = f.fountain || f.plates.includes(n);
    ctx.fillStyle = '#5f5870'; ctx.beginPath(); ctx.arc(px + ts / 2, py + ts / 2, ts * 0.42, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = lit ? '#ffcf5a' : '#2f2a3e'; ctx.beginPath(); ctx.arc(px + ts / 2, py + ts / 2, ts * 0.34, 0, Math.PI * 2); ctx.fill();
    if (lit) { ctx.globalAlpha = 0.3 + Math.sin(t * 4) * 0.15; ctx.fillStyle = '#fff1b0'; ctx.beginPath(); ctx.arc(px + ts / 2, py + ts / 2, ts * 0.46, 0, Math.PI * 2); ctx.fill(); ctx.globalAlpha = 1; }
    drawSymbol(ctx, n, px + ts / 2, py + ts / 2, ts * 0.2, lit ? '#3b2400' : '#d9d2e6', lit ? '#ffcf5a' : '#2f2a3e');
  }
  // 룬 판 그림: 1 해 2 별 3 달 4 구름
  function drawSymbol(ctx, n, x, y, r, fg, bg) {
    ctx.fillStyle = fg; ctx.strokeStyle = fg; ctx.lineWidth = Math.max(1.5, r * 0.22);
    if (n === 1) {
      ctx.beginPath(); ctx.arc(x, y, r * 0.5, 0, Math.PI * 2); ctx.fill();
      for (let i = 0; i < 8; i++) { const a = (i * Math.PI) / 4; ctx.beginPath(); ctx.moveTo(x + Math.cos(a) * r * 0.72, y + Math.sin(a) * r * 0.72); ctx.lineTo(x + Math.cos(a) * r, y + Math.sin(a) * r); ctx.stroke(); }
    } else if (n === 2) {
      ctx.save(); ctx.translate(x, y); ctx.scale(r / 30, r / 30); A.star(ctx, 0, 0, 30, fg); ctx.restore();
    } else if (n === 3) {
      ctx.beginPath(); ctx.arc(x, y, r * 0.85, 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = bg; ctx.beginPath(); ctx.arc(x + r * 0.4, y - r * 0.2, r * 0.75, 0, Math.PI * 2); ctx.fill();
    } else {
      for (const [dx, dy, rr] of [[-0.45, 0.15, 0.42], [0.05, -0.15, 0.55], [0.5, 0.15, 0.4]]) { ctx.beginPath(); ctx.arc(x + dx * r, y + dy * r, rr * r, 0, Math.PI * 2); ctx.fill(); }
      ctx.fillRect(x - r * 0.85, y + r * 0.1, r * 1.7, r * 0.45);
    }
  }
  function drawLibPlate(ctx, px, py, ts, t, on) {
    ctx.strokeStyle = on ? '#ffcf5a' : '#9b7be0'; ctx.lineWidth = 3;
    ctx.strokeRect(px + ts * 0.12, py + ts * 0.12, ts * 0.76, ts * 0.76);
    ctx.fillStyle = on ? 'rgba(255,207,90,0.35)' : `rgba(155,123,224,${0.18 + Math.sin(t * 3) * 0.08})`;
    ctx.fillRect(px + ts * 0.16, py + ts * 0.16, ts * 0.68, ts * 0.68);
  }
  function drawShelf(ctx, px, py, ts, seed) {
    ctx.fillStyle = '#4a2e1f'; ctx.fillRect(px + 1, py + 1, ts - 2, ts - 2);
    const cols = ['#e5566e', '#5a8ee0', '#ffcf5a', '#90e4c0', '#bfa2ee', '#f7a84a'];
    for (let row = 0; row < 3; row++) {
      const y = py + ts * (0.08 + row * 0.3);
      ctx.fillStyle = '#2e1c12'; ctx.fillRect(px + 2, y + ts * 0.24, ts - 4, ts * 0.04);
      for (let i = 0; i < 5; i++) { ctx.fillStyle = cols[(seed + i * 2 + row) % cols.length]; ctx.fillRect(px + ts * (0.1 + i * 0.16), y + ts * (0.04 + ((i + row) % 2) * 0.04), ts * 0.12, ts * (0.2 - ((i + row) % 2) * 0.04)); }
    }
  }
  function drawDesk(ctx, px, py, ts) {
    ctx.fillStyle = 'rgba(0,0,0,0.25)'; ctx.fillRect(px + ts * 0.12, py + ts * 0.78, ts * 0.8, ts * 0.1);
    ctx.fillStyle = '#8a5a3c'; ctx.fillRect(px + ts * 0.1, py + ts * 0.3, ts * 0.8, ts * 0.32);
    ctx.fillStyle = '#5f3b27'; ctx.fillRect(px + ts * 0.14, py + ts * 0.62, ts * 0.08, ts * 0.22); ctx.fillRect(px + ts * 0.78, py + ts * 0.62, ts * 0.08, ts * 0.22);
    ctx.fillStyle = '#f7ecd9'; ctx.fillRect(px + ts * 0.3, py + ts * 0.34, ts * 0.22, ts * 0.14);
  }
  function drawBoard(ctx, px, py, ts, x) {
    ctx.fillStyle = '#30243f'; ctx.fillRect(px, py, ts + 0.5, ts + 0.5);
    ctx.fillStyle = '#5f3b27'; ctx.fillRect(px, py + ts * 0.18, ts + 0.5, ts * 0.66);
    ctx.fillStyle = '#25483a'; ctx.fillRect(px, py + ts * 0.24, ts + 0.5, ts * 0.54);
    ctx.strokeStyle = 'rgba(255,255,255,0.65)'; ctx.lineWidth = 1.5;
    const r = D.RUNES[x % 4];
    ctx.fillStyle = 'rgba(255,255,255,0.7)'; ctx.font = `${Math.round(ts * 0.3)}px serif`; ctx.textAlign = 'center';
    if (x % 2) ctx.fillText(r.glyph, px + ts / 2, py + ts * 0.62);
    else { ctx.beginPath(); ctx.arc(px + ts / 2, py + ts / 2, ts * 0.15, 0, Math.PI * 1.6); ctx.stroke(); }
  }
  function drawWindow(ctx, px, py, ts, t) {
    ctx.fillStyle = '#1a2a4a'; ctx.fillRect(px + ts * 0.22, py + ts * 0.14, ts * 0.56, ts * 0.42);
    ctx.fillStyle = '#ffe680'; ctx.globalAlpha = 0.85; ctx.beginPath(); ctx.arc(px + ts * 0.6, py + ts * 0.28, ts * 0.07, 0, Math.PI * 2); ctx.fill(); ctx.globalAlpha = 1;
    ctx.strokeStyle = '#5f3b27'; ctx.lineWidth = 2; ctx.strokeRect(px + ts * 0.22, py + ts * 0.14, ts * 0.56, ts * 0.42);
    ctx.beginPath(); ctx.moveTo(px + ts / 2, py + ts * 0.14); ctx.lineTo(px + ts / 2, py + ts * 0.56); ctx.stroke();
    void t;
  }
  function drawGate(ctx, px, py, ts) {
    ctx.fillStyle = '#1a1420'; ctx.fillRect(px, py, ts + 0.5, ts + 0.5);
    ctx.fillStyle = '#8d84a0';
    for (let i = 0; i < 5; i++) ctx.fillRect(px + ts * (0.08 + i * 0.2), py, ts * 0.06, ts);
    ctx.fillRect(px, py + ts * 0.2, ts, ts * 0.06); ctx.fillRect(px, py + ts * 0.7, ts, ts * 0.06);
    ctx.fillStyle = '#ffcf5a'; ctx.fillRect(px + ts * 0.4, py + ts * 0.4, ts * 0.2, ts * 0.18);
  }
  function drawExit(ctx, a, px, py, ts, x, y, th) {
    const side = y === 0 ? 'top' : y === a.h - 1 ? 'bottom' : x === 0 ? 'left' : 'right';
    if (th.outdoor) {
      ctx.fillStyle = '#8c806b'; ctx.fillRect(px, py, ts + 0.5, ts + 0.5);
      ctx.fillStyle = '#5f5870';
      if (side === 'top' || side === 'bottom') { ctx.fillRect(px - ts * 0.08, py, ts * 0.14, ts); ctx.fillRect(px + ts * 0.94, py, ts * 0.14, ts); }
      else { ctx.fillRect(px, py - ts * 0.08, ts, ts * 0.14); ctx.fillRect(px, py + ts * 0.94, ts, ts * 0.14); }
      return;
    }
    ctx.fillStyle = '#0c0812'; ctx.fillRect(px + ts * 0.1, py + ts * 0.05, ts * 0.8, ts * 0.95);
    ctx.strokeStyle = '#8a5a3c'; ctx.lineWidth = 3; ctx.strokeRect(px + ts * 0.1, py + ts * 0.05, ts * 0.8, ts * 0.95);
  }
  function drawExitLabel(ctx, a, e, ts, t, isRoute) {
    const side = e.y === 0 ? 'top' : e.y === a.h - 1 ? 'bottom' : e.x === 0 ? 'left' : 'right';
    let lx = (e.x + 0.5) * ts, ly = (e.y + 0.5) * ts;
    if (side === 'top') ly += ts * 0.95; else if (side === 'bottom') ly -= ts * 0.95; else ly -= ts * 0.72;
    const label = e.label;
    ctx.font = `bold ${Math.max(11, Math.round(ts * 0.3))}px sans-serif`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    const w = ctx.measureText(label).width + 12, h = Math.max(16, ts * 0.42);
    lx = Math.max(w / 2 + 2, Math.min(a.w * ts - w / 2 - 2, lx));
    ctx.fillStyle = isRoute ? 'rgba(255,207,90,0.95)' : 'rgba(20,14,28,0.78)';
    ctx.beginPath(); ctx.roundRect ? ctx.roundRect(lx - w / 2, ly - h / 2, w, h, 6) : ctx.rect(lx - w / 2, ly - h / 2, w, h); ctx.fill();
    ctx.fillStyle = isRoute ? '#2a1508' : '#f2e8ff'; ctx.fillText(label, lx, ly + 1);
    ctx.textBaseline = 'alphabetic';
    if (isRoute) {
      const dir = { top: [0, -1], bottom: [0, 1], left: [-1, 0], right: [1, 0] }[side];
      const bob = Math.sin(t * 6) * ts * 0.08;
      const ax = (e.x + 0.5) * ts + dir[0] * bob, ay = (e.y + 0.5) * ts + dir[1] * bob;
      ctx.save(); ctx.translate(ax, ay); ctx.rotate(Math.atan2(dir[1], dir[0]));
      ctx.fillStyle = '#ffcf5a'; ctx.strokeStyle = '#2a1508'; ctx.lineWidth = 2;
      ctx.beginPath(); ctx.moveTo(ts * 0.3, 0); ctx.lineTo(-ts * 0.12, -ts * 0.26); ctx.lineTo(-ts * 0.12, ts * 0.26); ctx.closePath(); ctx.fill(); ctx.stroke();
      ctx.restore();
    }
  }
  function drawObject(ctx, o, ts, t) {
    const px = o.x * ts, py = o.y * ts;
    ctx.fillStyle = 'rgba(0,0,0,0.25)'; ctx.beginPath(); ctx.ellipse(px + ts / 2, py + ts * 0.9, ts * 0.32, ts * 0.08, 0, 0, Math.PI * 2); ctx.fill();
    if (o.kind === 'npc' || o.kind === 'customer') {
      const p = A.portraitOf(o.npc);
      A.draw(ctx, p.name, px - ts * 0.08, py - ts * 0.32, ts * 1.16, { t: t + o.x, npc: p.npc, mood: o.kind === 'customer' ? 'worried' : undefined });
      return;
    }
    if (o.kind === 'monster') {
      A.drawSpriteTile(ctx, (c, tt) => A.MON[o.enemy](c, tt), px, py + Math.sin(t * 3 + o.x) * ts * 0.04, ts, t + o.x * 0.7, 0.95);
      return;
    }
    const f = G.state.field;
    const opts = { t };
    if (o.id === 'well') opts.open = f.fountain && !f.well;
    if (o.id === 'locker') opts.mine = true;
    if (o.id === 'lectern') opts.book = G.state.quests.q4.status === 'ready' || G.state.quests.q4.status === 'done';
    let name = o.sprite;
    if (o.id === 'libchest' && f.libChest) name = 'chestOpen';
    const big = o.sprite === 'shed' ? 1.3 : o.sprite === 'piano' || o.sprite === 'curtain' || o.sprite === 'locker' ? 1.05 : 0.92;
    A.draw(ctx, name, px + ts * (1 - big) / 2, py + ts * (1 - big) - ts * 0.04, ts * big, opts);
  }

  // ───────── 입력 ─────────
  function onFieldTap(e) {
    if (G.ui.dialog || $('#sheet').innerHTML || G.ui.battle) return;
    const cam = G.ui.fcam; if (!cam) return;
    const rect = e.currentTarget.getBoundingClientRect();
    const x = Math.floor((e.clientX - rect.left + cam.cx) / cam.ts);
    const y = Math.floor((e.clientY - rect.top + cam.cy) / cam.ts);
    if (G.ui.busy) { G.ui.fredirect = { x, y }; G.ui.fcancel = true; return; }
    fieldTap(x, y);
  }
  async function fieldTap(x, y) {
    const s = G.state;
    const a = F.cur(s);
    if (x < 0 || y < 0 || x >= a.w || y >= a.h) return;
    const f = s.field;
    if (x === f.x && y === f.y) { toast(F.cur(s).name); return; }
    if (!F.revealed(s, x, y)) { toast('어둠에 가려 보이지 않는다.'); S.play('error'); return; }
    const obj = F.objectAt(s, x, y);
    if (obj && obj.kind !== 'monster') {
      const p = F.pathToObject(s, obj);
      if (!p) { toast('그쪽으로 갈 길이 없다.'); S.play('error'); return; }
      const ok = await walk(p);
      if (ok && G.ui.screen === 'field' && F.cur(s).id === a.id) await interact(obj);
      return;
    }
    if (F.cartAt(s, x, y)) {
      if (Math.abs(x - f.x) + Math.abs(y - f.y) === 1) { await walk([[x, y]]); return; }
      toast('책수레 바로 옆에 서서 수레를 누르거나 십자 버튼으로 밀자.');
      return;
    }
    if (!F.isOpen(s, x, y)) { S.play('error'); return; }
    const p = F.findPath(s, x, y);
    if (!p || !p.length) { toast('그곳까지 가는 길을 모른다.'); S.play('error'); return; }
    await walk(p);
  }
  // 걸어가기. 끝까지 갔으면 true
  async function walk(path) {
    G.ui.busy = true; G.ui.fcancel = false; G.ui.fredirect = null;
    G.ui.fpath = path.slice();
    let done = true;
    for (const [nx, ny] of path) {
      if (G.ui.fcancel) { done = false; break; }
      const cont = await stepTo(nx, ny);
      if (G.ui.fpath) G.ui.fpath.shift();
      if (!cont) { done = false; break; }
    }
    G.ui.fpath = null;
    G.ui.busy = false;
    save();
    refreshField();
    const rd = G.ui.fredirect; G.ui.fredirect = null;
    if (rd && G.ui.screen === 'field') { fieldTap(rd.x, rd.y); return false; }
    return done;
  }
  function tweenTo(fx, fy, nx, ny) {
    G.ui.fcat = { x: fx, y: fy };
    G.ui.ftween = { fx: G.ui.fpos.x, fy: G.ui.fpos.y, tx: nx, ty: ny, start: performance.now(), dur: STEP_MS * (G.ui.speed || 1) };
    G.ui.fpos = { x: nx, y: ny };
  }
  async function stepTo(nx, ny) {
    const s = G.state;
    const fx = s.field.x, fy = s.field.y;
    const r = F.step(s, nx, ny);
    switch (r.type) {
      case 'moved':
        tweenTo(fx, fy, nx, ny); S.play('step');
        await sleep(STEP_MS);
        if (r.plate) return plateEvent(r.plate, nx, ny);
        return true;
      case 'push':
        tweenTo(fx, fy, s.field.x, s.field.y); S.play('door');
        await sleep(STEP_MS);
        refreshField();
        if (r.onPlate) { ffloat(r.cart[0], r.cart[1], '철컥!', '#ffcf5a'); S.play('coin'); }
        if (r.gateOpened) await gateOpened();
        return false;
      case 'pushBlocked': S.play('error'); toast('수레가 꿈쩍도 하지 않는다.'); return false;
      case 'exit': await useExit(r.exit); return false;
      case 'battle': await mazeBattle(r.obj); return false;
      default:
        if (r.obj) return false;
        S.play('error'); return false;
    }
  }
  async function plateEvent(p, x, y) {
    const f = G.state.field;
    if (p.result === 'done' || p.result === 'same') return true;
    if (p.result === 'progress') { S.play('tap'); ffloat(x, y, F.PLATES[p.n].name + ' ' + p.count + '/4', '#ffcf5a'); return true; }
    if (p.result === 'reset') { S.play('bad'); ffloat(x, y, '스르르…', '#c9c3d6'); toast('룬 판의 빛이 모두 꺼졌다. 순서가 틀린 것 같다.'); return false; }
    if (p.result === 'solved') {
      S.play('purify');
      await say([{ who: null, text: '네 번째 룬 판이 빛나자, 분수의 물이 금빛으로 물들었다.' }, { who: null, text: '그르르릉— 정원 동쪽의 마른 우물 뚜껑이 열리는 소리가 났다!' }]);
      R.checkBadges(G.state).forEach(badgeToast);
      save();
      void f;
      return false;
    }
    return true;
  }
  async function gateOpened() {
    S.play('purify');
    await say([{ who: null, text: '두 바닥 판이 동시에 눌리자— 끼이익, 금서 칸 철문이 천천히 올라갔다.' }]);
    R.checkBadges(G.state).forEach(badgeToast);
    save(); render();
  }
  async function useExit(e) {
    const s = G.state;
    S.play('door');
    if (e.screen) {
      if (e.screen === 'shop') G.ui.kikiLine = D.LINES.kiki[Math.floor(Math.random() * D.LINES.kiki.length)];
      if (e.screen === 'infirmary') G.ui.momoLine = D.LINES.momo[Math.floor(Math.random() * D.LINES.momo.length)];
      go(e.screen);
      return;
    }
    F.enterArea(s, e.to, e.at[0], e.at[1]);
    snapField();
    save();
    render();
    await areaTip(e.to);
  }
  async function areaTip(id) {
    const s = G.state;
    const k = 'visit_' + id;
    if (s.flags[k]) return;
    s.flags[k] = true;
    save();
    const tips = {
      hall: [{ who: 'rumi', text: '본관 복도. 문마다 이름표가 붙어 있네. 교실은 왼쪽·오른쪽, 위쪽은 도서관!' }],
      class1: [{ who: 'flam', text: '부엉. 새 얼굴이구나. 마법을 배우고 싶으면 내게 말을 걸렴.' }],
      class2: [{ who: 'serena', text: '여긴 고급마법반. 기본을 다 떼고 오면 가르쳐 줄게.' }],
      music: [{ who: 'rumi', text: '음악실… 여기저기 뒤져 볼 만한 곳이 많아. 물건을 누르면 살펴볼 수 있어.' }],
      library: [{ who: 'rumi', text: '금서 칸은 철문으로 막혀 있어. 바닥의 보라색 판 두 개…를 책수레로 누르면 열리려나?' }, { who: 'mukmul', text: '냐. (수레 옆에 서서 수레를 누르면 반대쪽으로 밀려. 막히면 「수레 되돌리기」)' }],
      maze: [{ who: 'rumi', text: '밤의 산울타리 미로… 어두워서 가까운 곳만 보여.' }, { who: 'mukmul', text: '냐아. (몬스터를 건드리면 전투야. 오두막은 한가운데. 미로는 날마다 바뀌어)' }],
      garden: [{ who: 'rumi', text: '안뜰 정원이다. 분수 둘레에 이상한 그림이 새겨진 돌판이 있네.' }],
    };
    if (tips[id]) await say(tips[id]);
  }
  async function mazeBattle(o) {
    const s = G.state;
    const res = await runBattle(o.enemy, {});
    if (res === 'win') { F.defeatMonster(s, o.x, o.y); save(); if (G.ui.screen === 'field') render(); }
    else if (res === 'lose') { await defeat(); }
  }

  // ───────── 상호작용 ─────────
  async function interact(o) {
    const s = G.state;
    S.play('tap');
    if (o.kind === 'customer') { await ACT.customer(o.qid); return; }
    if (o.kind === 'npc') {
      if (o.cls) return classSheet(o.cls);
      if (o.npc === 'gardener') { const ln = D.LINES.gardener; await say([{ who: 'gardener', text: ln[(s.day + (G.ui.gtalk = (G.ui.gtalk || 0) + 1)) % ln.length] }]); return; }
      if (o.npc === 'portraits') { await say([{ who: 'portraits', text: '"어머, 루미! 소문 하나 들려줄까?"' }, { who: 'portraits', text: `"${D.LINES.rumors[(s.day + (G.ui.ptalk = (G.ui.ptalk || 0) + 1)) % D.LINES.rumors.length]}"` }]); return; }
    }
    switch (o.id) {
      case 'desk': go('club'); if (!s.flags.clubTip) { s.flags.clubTip = true; await say([{ who: 'mukmul', text: '냐. (정화대에서 의뢰 물건을 정화하고, 찾은 골동품을 정화·장착·판매할 수 있어)' }]); } return;
      case 'bed': return bedSheet();
      case 'locker': {
        const r = F.useLocker(s);
        if (!r.ok) { toast(r.text); return; }
        const q = R.questDef(r.qid);
        S.play('chest');
        await say(q.found.map((text) => ({ who: null, text })));
        toast('의뢰 목표 달성! 부실 정화대로 가자.', 'gold');
        save(); refreshField(); return;
      }
      case 'lectern': {
        const r = F.useLectern(s);
        if (!r.ok) { toast(r.text); return; }
        const q = R.questDef(r.qid);
        S.play('purify');
        await say(q.found.map((text) => ({ who: null, text })));
        toast('의뢰 목표 달성! 부실 정화대로 가자.', 'gold');
        save(); refreshField(); return;
      }
      case 'libchest': {
        const r = F.openLibChest(s);
        if (!r.ok) { toast(r.text); return; }
        S.play('chest'); await lootSheet('금서 칸 상자를 열었다!', r.loot); save(); return;
      }
      case 'hintbook':
        await ask({ title: '『정원 분수의 비밀』', art: sprite('book', {}, '', false), body: '<p>「분수 둘레 네 룬 판은 밤에서 낮, 낮에서 밤으로 흐르는 하늘을 따라 밟을 것.」</p><p><b>처음엔 ☾ 달, 다음은 ☀ 해, 셋째는 ★ 별, 마지막은 ☁ 구름.</b></p><p class="tiny dim">「…순서가 맞으면 우물이 열린다.」 — 옛 사서의 메모</p>', choices: [{ label: '기억했다', value: 1, cls: 'primary' }] });
        return;
      case 'well': {
        const r = F.useWell(s);
        if (!r.ok) { toast(r.text); return; }
        S.play('chest'); await lootSheet('우물 바닥에서 달빛에 싸인 골동품을 건졌다!', r.loot); R.checkBadges(s).forEach(badgeToast); save(); return;
      }
      case 'shed': {
        const r = F.useShed(s);
        if (r.first) R.checkBadges(s).forEach(badgeToast);
        if (r.qid) { const q = R.questDef(r.qid); S.play('chest'); await say(q.found.map((text) => ({ who: null, text }))); toast('의뢰 목표 달성! 부실 정화대로 가자.', 'gold'); }
        else { if (r.silver) S.play('coin'); await ask({ title: '미로 한가운데 오두막', art: sprite('shed', {}, '', true), body: `<p>${esc(r.text)}</p>`, choices: [{ label: '확인', value: 1, cls: 'primary' }] }); }
        save(); refreshField(); return;
      }
      default: break;
    }
    if (o.id.startsWith('mchest:')) {
      const r = F.openMazeChest(s, o.x, o.y);
      if (!r.ok) { toast(r.text); return; }
      S.play('chest'); await lootSheet('상자를 열었다!', r.loot); save(); return;
    }
    if (F.SEARCH[o.id]) {
      const r = F.search(s, o.id);
      if (r.found) S.play('chest'); else if (r.silver) S.play('coin'); else S.play('tap');
      const extra = [];
      if (r.silver) extra.push(`은화 +${r.silver}`);
      if (r.item) extra.push(`${D.ITEMS[r.item].name} 획득`);
      await ask({ title: `${o.label} 살펴보기`, art: sprite(o.sprite, { mine: false }, '', true), body: `<p>${esc(r.text)}</p>${extra.length ? `<p class="small" style="color:var(--gold)">${extra.join(' · ')}</p>` : ''}`, choices: [{ label: '확인', value: 1, cls: 'primary' }] });
      save(); refreshField();
    }
  }
  async function bedSheet() {
    const s = G.state;
    const st = R.stats(s);
    const c = await ask({ title: '부실 침대', art: sprite('bed', {}, '', false), body: `<p>한숨 자고 내일을 맞을까? 마력이 가득 차고, 체력이 최대치의 ${Math.round(D.TUNING.sleepHealPct * 100)}% 회복된다.</p><p class="tiny dim">하루가 지나면 새 손님이 오고, 밤의 미로 길이 바뀐다. 지금 체력 ${s.player.hp}/${st.maxHp} · 마력 ${s.player.mp}/${st.maxMp}</p>`, choices: [{ label: '잔다 (하루 지남)', value: 'sleep', cls: 'primary' }, { label: '아직', value: null }] });
    if (c !== 'sleep') return;
    const r = R.sleepDay(s);
    S.play('heal');
    save(); render();
    const n = R.customers(s).length;
    toast(`${s.day}일째 아침. 체력 +${r.hp}, 마력 가득!${n ? ` 손님 ${n}명이 와 있다.` : ''}`, 'good');
    await maybeEnding();
  }

  // ───────── 마법 수업 ─────────
  async function classSheet(cls) {
    const s = G.state;
    const C = D.CLASSES[cls];
    const teacher = C.teacher;
    const lines = D.LINES[teacher];
    if (!R.classOpen(s, cls)) {
      await say([{ who: teacher, text: lines[1] }]);
      return;
    }
    const ids = R.classSpells(cls);
    while (true) {
      const rows = ids.map((id) => {
        const sp = D.SPELLS[id];
        const known = s.spells.includes(id);
        const chk = R.canLearn(s, id);
        const state = known ? '<span class="chip good">배움</span>' : chk.ok ? '<span class="chip weak">수강 가능</span>' : `<span class="chip">${esc(chk.reason)}</span>`;
        return { id, known, ok: chk.ok, html: `<div class="card small"><b>${sp.name}</b> <span class="dim">마력 ${sp.mp} · Lv${sp.learn}~ · 수강료 ${sp.tuition ? sp.tuition + '은화' : '무료'} · 룬 ${sp.seq}개</span> ${state}<div class="tiny muted">${esc(sp.desc)}</div></div>` };
      });
      const c = await ask({
        title: C.name, art: portrait(teacher, '', true),
        body: `<p class="small muted">"${esc(lines[Math.floor(Math.random() * lines.length)])}"</p><p class="tiny dim">${esc(C.desc)} 수강료는 합격해야 낸다. 보유 은화 ${s.silver}</p>${rows.map((r) => r.html).join('')}`,
        vertical: true,
        choices: rows.filter((r) => !r.known).map((r) => ({ label: `「${D.SPELLS[r.id].name}」 수업 듣기`, value: r.id, cls: r.ok ? 'primary' : '', disabled: !r.ok })).concat([{ label: '교실을 나선다', value: null, cls: 'ghost' }]),
      });
      if (!c) return;
      const passed = await runeLesson(c, cls);
      if (passed) {
        const r = R.learnSpell(s, c);
        if (r.ok) {
          S.play('levelup');
          save();
          await ask({ title: `새 마법: ${r.spell.name}`, art: sprite('rumi', { shadow: false }, '', true), body: `<p>${esc(r.spell.desc)}</p><p class="small muted">마력 ${r.spell.mp} · 전투의 「마법」 메뉴에서 쓸 수 있다.${r.spell.tuition ? ` 수강료 ${r.spell.tuition}은화를 냈다.` : ''}</p>`, choices: [{ label: '좋아!', value: 1, cls: 'primary' }] });
          R.checkBadges(s).forEach(badgeToast);
          save(); refreshField();
        }
      }
    }
  }
  // 룬 따라 그리기: 보여준 순서대로 룬을 누른다. 반환 true = 합격
  function runeLesson(spellId, cls) {
    const sp = D.SPELLS[spellId];
    return new Promise((resolve) => {
      G.ui.rune = { seq: R.runeSequence(sp.seq), i: 0, phase: 'intro', lit: -1, resolve, speed: cls === 'advanced' ? 430 : 620, spell: sp, tries: 0 };
      renderRune();
    });
  }
  function renderRune(msg) {
    const P = G.ui.rune; if (!P) return;
    const btns = D.RUNES.map((r) => `<button class="rune ${P.lit === r.id ? 'lit' : ''}" style="--rc:${r.color}" data-act="rune" data-arg="${r.id}" ${P.phase === 'input' ? '' : 'disabled'} aria-label="${r.name} 룬"><span>${r.glyph}</span><small>${r.name}</small></button>`).join('');
    const dots = P.seq.map((_, i) => `<i class="${P.phase === 'input' && i < P.i ? 'on' : ''}"></i>`).join('');
    const head = P.phase === 'intro' ? `칠판에 룬 <b>${P.seq.length}개</b>가 차례로 빛난다. 순서를 외워서 똑같이 누르자.`
      : P.phase === 'show' ? '<b>잘 봐!</b> 룬이 빛나는 순서를 외우자…'
        : P.phase === 'input' ? '<b>이제 네 차례.</b> 같은 순서로 룬을 누르자.' : '';
    openSheet({
      title: `수업 · ${sp(P).name}`, dismiss: false,
      body: `<p class="small">${msg || head}</p><div class="rune-dots">${dots}</div><div class="runes">${btns}</div>`,
      foot: P.phase === 'intro' ? '<button class="btn primary" data-act="runeStart">시작</button><button class="btn ghost" data-act="runeQuit">그만두기</button>'
        : P.phase === 'fail' ? '<button class="btn primary" data-act="runeStart">다시 도전</button><button class="btn ghost" data-act="runeQuit">그만두기</button>'
          : '<button class="btn ghost" data-act="runeQuit">그만두기</button>',
    });
  }
  const sp = (P) => P.spell;
  async function runeShow() {
    const P = G.ui.rune; if (!P) return;
    P.phase = 'show'; P.i = 0; P.lit = -1; renderRune();
    await sleep(500);
    for (const r of P.seq) {
      if (G.ui.rune !== P) return;
      P.lit = r; renderRune(); S.play(['fire', 'ice', 'light', 'heal'][r]);
      await sleep(P.speed);
      P.lit = -1; renderRune();
      await sleep(P.speed * 0.35);
    }
    if (G.ui.rune !== P) return;
    P.phase = 'input'; renderRune();
  }
  ACT.runeStart = () => {
    const P = G.ui.rune; if (!P) return;
    if (P.phase === 'fail') { P.seq = R.runeSequence(P.spell.seq); P.tries += 1; }
    runeShow();
  };
  ACT.rune = (arg) => {
    const P = G.ui.rune; if (!P || P.phase !== 'input') return;
    const r = Number(arg);
    if (r !== P.seq[P.i]) {
      S.play('bad');
      P.phase = 'fail'; P.lit = -1;
      renderRune(`틀렸다! ${P.i + 1}번째는 「${D.RUNES[P.seq[P.i]].name}」 룬이었다. 새 문제로 다시 도전할 수 있다. (수강료는 합격할 때만)`);
      return;
    }
    S.play('tap');
    P.i += 1; P.lit = r;
    renderRune();
    setTimeout(() => { if (G.ui.rune === P && P.phase === 'input') { P.lit = -1; renderRune(); } }, 180);
    if (P.i >= P.seq.length) {
      P.phase = 'done';
      S.play('purify');
      renderRune('<b>합격!</b> 룬이 손끝에서 마법으로 바뀌었다.');
      setTimeout(() => { if (G.ui.rune !== P) return; closeSheet(); G.ui.rune = null; P.resolve(true); }, 700);
    }
  };
  ACT.runeQuit = () => { const P = G.ui.rune; if (!P) return; G.ui.rune = null; closeSheet(); P.resolve(false); };

  // ───────── 버튼 ─────────
  ACT.fmove = (arg) => {
    if (G.ui.busy || G.ui.battle || G.ui.screen !== 'field') return;
    const [dx, dy] = arg.split(',').map(Number);
    const f = G.state.field;
    const tx = f.x + dx, ty = f.y + dy;
    const obj = F.objectAt(G.state, tx, ty);
    if (obj && obj.kind !== 'monster') { interact(obj); return; }
    walk([[tx, ty]]);
  };
  ACT.mazeOut = async () => {
    if (G.ui.busy) return;
    const s = G.state;
    const e = F.cur(s).exits[0];
    const p = F.findPath(s, e.x, e.y);
    if (!p) { toast('돌아가는 길을 모르겠다.'); return; }
    await walk(p);
  };
  ACT.cartReset = () => {
    if (G.ui.busy) return;
    F.resetCarts(G.state);
    S.play('door');
    toast('책수레를 처음 자리로 돌려놓았다.');
    save(); render();
  };

  W.ui.field = { fieldTap, walk, interact, snapField, useExit, classSheet, runeLesson };
})();
