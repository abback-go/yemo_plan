// 전체 플레이 E2E: 실제 UI(버튼·시트·대화·전투·퍼즐)를 조작해 엔딩까지 플레이한다.
// 사용: node tests/e2e-full.cjs [seed]
const path = require('path');
const { chromium } = require('/opt/node22/lib/node_modules/playwright');

const OUT = path.join(__dirname, 'out');
const URL = 'file://' + path.join(__dirname, '..', 'dist', 'index.html');
const SEED = Number(process.argv[2] || 7);
const MAX_DAYS = 70;

const ctx = { wantHome: false, wantDown: false, wantBoss: false, wantUp: false };
const stats = { sheets: {}, battles: 0, shots: [] };
let page;
const wait = (ms) => page.waitForTimeout(ms);
async function shot(name) { const f = path.join(OUT, `full-${String(stats.shots.length + 1).padStart(2, '0')}-${name}.png`); await page.screenshot({ path: f }); stats.shots.push(name); }
const ev = (fn, arg) => page.evaluate(fn, arg);

async function uiState() {
  return ev(() => {
    const sh = document.querySelector('#sheet .sheet');
    return {
      dialog: !!document.querySelector('#dialog .dialog'),
      battle: !!document.querySelector('#battle'),
      sheet: !!sh,
      sheetTitle: sh ? (sh.querySelector('.sh-head h2') || {}).textContent || '' : '',
      choices: sh ? Array.from(sh.querySelectorAll('[data-act="choose"]')).map((b) => ({ label: b.textContent.trim(), disabled: b.disabled, cls: b.className })) : [],
      puzzle: !!W.game.ui.puzzle,
      busy: W.game.ui.busy,
    };
  });
}
async function chooseLabel(re, fallbackIdx) {
  const st = await uiState();
  let i = st.choices.findIndex((c) => !c.disabled && re.test(c.label));
  if (i < 0) i = fallbackIdx != null ? fallbackIdx : st.choices.findIndex((c) => !c.disabled);
  if (i < 0) { await page.click('#sheet .sh-head [data-act="sheetDismiss"]'); return; }
  await page.click(`#sheet [data-act="choose"][data-arg="${i}"]`);
}

async function decideSheet(st) {
  const t = st.sheetTitle;
  stats.sheets[t.replace(/[0-9]+/g, '#')] = (stats.sheets[t.replace(/[0-9]+/g, '#')] || 0) + 1;
  if (t === '학교로 돌아갈까?') return chooseLabel(ctx.wantHome ? /돌아간다/ : /더 탐험/);
  if (t === '올라가는 계단') return chooseLabel(ctx.wantHome || ctx.wantUp ? /올라간다/ : /그만둔다/);
  if (/^B\d /.test(t)) return chooseLabel(ctx.wantDown ? /내려간다/ : /그만둔다/);
  if (t === '짙은 그림자') { if (ctx.wantBoss) await shot('boss-ask'); return chooseLabel(ctx.wantBoss ? /맞선다/ : /준비하고/); }
  if (t === '달빛 샘물') { const need = await ev(() => { const s = W.game.state, st = W.rules.stats(s); return s.player.hp < st.maxHp * 0.85 || s.player.mp < st.maxMp * 0.7; }); return chooseLabel(need ? /마신다/ : /나중에/); }
  if (t === '운명의 항아리') { const rich = await ev(() => W.game.state.silver > 220); return chooseLabel(rich ? /넣기/ : /지나간다/); }
  if (t === '수다쟁이 초상화 자매') {
    const idx = await ev(() => { const q = document.querySelector('#sheet .sh-body b').textContent; const d = W.DATA.QUIZ.find((x) => x.q === q); return d ? (Math.random() < 0.8 ? d.c : (d.c + 1) % 3) : 0; });
    return page.click(`#sheet [data-act="choose"][data-arg="${idx}"]`);
  }
  if (t === '잠긴 문' || t === '잠긴 상자') return chooseLabel(/열쇠를 쓴다/, st.choices.length - 1);
  if (t === '기묘한 방') return chooseLabel(/들어간다/);
  if (t === '방랑냥의 보따리') return chooseLabel(/그만 산다/);
  if (t === '귀환 깃털') return chooseLabel(/돌아간다/);
  if (t === '이대로 들어갈까요?') return chooseLabel(/그래도/);
  if (t === '정화 완료!') {
    const choice = await ev(() => {
      const s = W.game.state; const D = W.DATA;
      const name = document.querySelector('#sheet .card b').textContent;
      const def = Object.values(D.ANTIQUES).find((a) => name.startsWith(a.name));
      const score = (d) => { const e = d.effect; return (e.atk || 0) * 3 + (e.def || 0) * 2.5 + (e.maxHp || 0) * 0.4 + (e.maxMp || 0) * 0.5 + (e.mpRegen || 0) * 6 + (e.lightBoost || 0) * 12 + (e.iceBoost || 0) * 8 + (e.fireBoost || 0) * 6 + (e.crit || 0) * 30; };
      const eq = s.equip.map((u) => u == null ? null : s.antiques.find((a) => a.uid === u)).map((a) => a ? D.ANTIQUES[a.def] : null);
      if (eq.some((x) => !x)) return 'equip';
      const worst = Math.min(...eq.map(score));
      return def && score(def) > worst ? 'equip-swap' : 'sell';
    });
    if (choice === 'equip') return chooseLabel(/^장착/);
    if (choice === 'sell') return chooseLabel(/판매/);
    // 더 좋은 골동품: 가장 약한 칸을 비우고 장착
    await ev(() => { const s = W.game.state, D = W.DATA; const sc = (u) => { const a = s.antiques.find((x) => x.uid === u); const e = D.ANTIQUES[a.def].effect; return (e.atk || 0) * 3 + (e.def || 0) * 2.5 + (e.maxHp || 0) * 0.4 + (e.maxMp || 0) * 0.5; }; const i = sc(s.equip[0]) <= sc(s.equip[1]) ? 0 : 1; W.rules.unequip(s, i); });
    return chooseLabel(/^장착/);
  }
  if (/매입$/.test(t)) return chooseLabel(/매입한다/, st.choices.length - 1);
  if (t === '저주골동품부 존속 확정!') { await wait(400); await shot('ending-card'); return chooseLabel(/계속/); }
  // 기본: 주 버튼 > 첫 선택지 > 닫기
  const clicked = await ev(() => {
    const prim = document.querySelector('#sheet .sh-foot .btn.primary:not([disabled]), #sheet .choices .btn.primary:not([disabled])');
    if (prim) { prim.click(); return true; }
    const ch = document.querySelector('#sheet [data-act="choose"]:not([disabled])');
    if (ch) { ch.click(); return true; }
    return false;
  });
  if (!clicked) await page.click('#sheet .sh-head [data-act="sheetDismiss"]');
}

async function battleTurn() {
  const act = await ev(() => {
    const s = W.game.state, B = W.game.ui.battle, R = W.rules, D = W.DATA, st = R.stats(s);
    if (!B || B.busy || B.b.over) return null;
    const b = B.b;
    const can = (a) => R.canAct(s, b, a).ok;
    const spells = R.knownSpells(s);
    if (s.player.hp < st.maxHp * (b.boss || b.elite ? 0.45 : 0.35)) {
      if (R.count(s, 'big_potion') && can({ type: 'item', id: 'big_potion' })) return { m: 'item', id: 'big_potion' };
      if (R.count(s, 'hp_potion') && can({ type: 'item', id: 'hp_potion' })) return { m: 'item', id: 'hp_potion' };
      if (spells.includes('heal') && can({ type: 'spell', id: 'heal' })) return { m: 'spell', id: 'heal' };
      if (!b.noFlee) return { m: 'flee' };
    }
    if (b.pcurse > 0 && (b.boss || b.elite) && R.count(s, 'salt')) return { m: 'item', id: 'salt' };
    if (b.charging && spells.includes('ice') && s.player.mp >= D.SPELLS.ice.mp) return { m: 'spell', id: 'ice' };
    if (b.shield > 0 && spells.includes('light') && s.player.mp >= D.SPELLS.light.mp) return { m: 'spell', id: 'light' };
    if ((b.boss || b.elite) && s.player.mp < 8 && R.count(s, 'mp_potion') && can({ type: 'item', id: 'mp_potion' })) return { m: 'item', id: 'mp_potion' };
    const known = s.known[b.enemyId] || {};
    // 사람처럼: 약점을 모르면 마법을 돌아가며 시험해 본다
    if (b.weak && known.weak && spells.includes(b.weak) && s.player.mp >= D.SPELLS[b.weak].mp + (b.boss || b.elite ? 0 : 4)) return { m: 'spell', id: b.weak };
    if (!known.weak && (b.boss || b.elite || b.hp > 30)) {
      const tryList = ['fire', 'ice', 'light'].filter((x) => spells.includes(x) && s.player.mp >= D.SPELLS[x].mp + 4);
      const tried = (B.tried = B.tried || []);
      const next = tryList.find((x) => !tried.includes(x));
      if (next) { tried.push(next); return { m: 'spell', id: next }; }
    }
    return { m: 'attack' };
  });
  if (!act) return;
  if (act.m === 'attack') await page.click('[data-act="battack"]');
  else if (act.m === 'flee') await page.click('[data-act="bflee"]');
  else {
    await page.click(`[data-act="bmenu"][data-arg="${act.m}"]`);
    await page.click(`[data-act="${act.m === 'spell' ? 'bspell' : 'bitem'}"][data-arg="${act.id}"]`);
  }
}

async function settle() {
  for (let i = 0; i < 3000; i++) {
    const st = await uiState();
    if (st.dialog) { await page.click('.dialog-skip'); await wait(15); continue; }
    if (st.battle) { await battleTurn(); await wait(25); continue; }
    if (st.puzzle) {
      const presses = await ev(() => { const g0 = W.game.ui.puzzle.g.slice(); for (let m = 0; m < 512; m++) { const g = g0.slice(); const l = []; for (let k = 0; k < 9; k++) if (m & (1 << k)) { W.rules.puzzleToggle(g, k); l.push(k); } if (g.every(Boolean)) return l; } return []; });
      for (const k of presses) { await page.click(`[data-act="candle"][data-arg="${k}"]`); await wait(10); }
      await wait(650);
      continue;
    }
    if (st.sheet) { await decideSheet(st); await wait(25); continue; }
    if (st.busy) { await wait(20); continue; }
    return;
  }
  throw new Error('settle 시간 초과');
}

async function click(sel) { await page.click(sel); await wait(30); await settle(); }

async function hubPhase() {
  await settle();
  if (await ev(() => W.game.ui.screen !== 'hub')) await click('[data-act="go"][data-arg="hub"]');
  const s = await ev(() => JSON.parse(JSON.stringify(W.game.state)));
  if (s.flags.endingSeen) return 'end';
  // 치료
  const needHeal = await ev(() => { const s = W.game.state, st = W.rules.stats(s); return (s.player.hp < st.maxHp * 0.9 || s.player.mp < st.maxMp * 0.7 || s.player.status.poison) && (s.flags.infirmaryFree || s.silver >= 20); });
  if (needHeal) { await click('[data-act="go"][data-arg="infirmary"]'); const dis = await ev(() => document.querySelector('[data-act="heal"]').disabled); if (!dis) await click('[data-act="heal"]'); await click('[data-act="go"][data-arg="hub"]'); }
  // 매점: 소금(미정화·재료 의뢰), 재료, 물약
  const buyList = await ev(() => {
    const s = W.game.state, R = W.rules, D = W.DATA;
    const out = [];
    let money = s.silver;
    const add = (id, n) => { const it = D.ITEMS[id]; if (it.unlockFloor && s.floorsReached < it.unlockFloor) return; const k = Math.min(n, Math.floor((money - 40) / it.price)); if (k > 0) { out.push([id, k]); money -= k * it.price; } };
    for (const q of R.activeQuests(s)) if (q.objective.type === 'items') for (const id of Object.keys(q.objective.items)) { const need = q.objective.items[id] - R.count(s, id); if (need > 0) add(id, need); }
    const cursed = s.antiques.filter((a) => a.state === 'cursed').length;
    if (cursed > R.count(s, 'salt')) add('salt', Math.min(2, cursed - R.count(s, 'salt')));
    const hpWant = (s.floorsReached >= 3 ? 3 : 4) - R.count(s, 'hp_potion');
    if (hpWant > 0) add('hp_potion', hpWant);
    if (s.floorsReached >= 3 && R.count(s, 'big_potion') < 2) add('big_potion', 2 - R.count(s, 'big_potion'));
    if (s.player.lv >= 3 && R.count(s, 'mp_potion') < 2) add('mp_potion', 2 - R.count(s, 'mp_potion'));
    if (!R.count(s, 'feather')) add('feather', 1);
    return out;
  });
  if (buyList.length) {
    await click('[data-act="go"][data-arg="shop"]');
    for (const [id, n] of buyList) {
      const tab = await ev((i) => W.DATA.ITEMS[i].cat, id);
      await click(`[data-act="shopTab"][data-arg="${tab}"]`);
      await page.click(`[data-act="buySheet"][data-arg="${id}"]`); await wait(30);
      for (let k = 1; k < n; k++) { await page.click('[data-act="qty"][data-arg="1"]'); await wait(10); }
      const dis = await ev(() => document.querySelector('[data-act="buyConfirm"]').disabled);
      if (dis) await page.click('#sheet .sh-head [data-act="sheetDismiss"]'); else await page.click('[data-act="buyConfirm"]');
      await wait(30);
    }
    await click('[data-act="go"][data-arg="hub"]');
  }
  // 부실: 정화, 미정화 정화, 매입
  await click('[data-act="go"][data-arg="club"]');
  for (let i = 0; i < 10; i++) {
    const btn = await ev(() => { const b = document.querySelector('[data-act="purifyQuest"], [data-act="purifyFound"]:not([disabled])'); return b ? `[data-act="${b.dataset.act}"][data-arg="${b.dataset.arg}"]` : null; });
    if (!btn) break;
    await click(btn);
  }
  const ended = await ev(() => W.game.state.flags.endingSeen);
  if (ended) return 'end';
  for (let i = 0; i < 3; i++) {
    const q = await ev(() => { const s = W.game.state, R = W.rules; const c = R.customers(s).find((x) => s.silver >= x.buy + 60 && R.activeQuests(s).length < 3); return c ? c.id : null; });
    if (!q) break;
    await click(`[data-act="customer"][data-arg="${q}"]`);
  }
  await click('[data-act="go"][data-arg="hub"]');
  return (await ev(() => W.game.state.flags.endingSeen)) ? 'end' : 'ok';
}

function targetFloorJS() {
  const s = W.game.state, R = W.rules, D = W.DATA;
  for (const q of R.activeQuests(s)) {
    const o = q.objective;
    if (o.floor && s.quests[q.id].status === 'active' && s.floorsReached >= o.floor && s.player.lv >= D.FLOORS[o.floor].recLv) return { floor: o.floor, deeper: false };
  }
  const f = Math.min(s.floorsReached, Math.max(1, Math.min(5, s.player.lv)));
  return { floor: f, deeper: f === s.floorsReached && f < 5 };
}

async function walkTo(x, y) {
  const f0 = await ev(() => W.game.state.exp && W.game.state.exp.floor);
  for (let i = 0; i < 40; i++) {
    const at = await ev(() => { const s = W.game.state; return s.exp ? { x: s.exp.x, y: s.exp.y, f: s.exp.floor } : null; });
    if (!at) return 'left';
    if (at.f !== f0) return 'floor';
    if (at.x === x && at.y === y) return 'arrived';
    const ok = await ev(([tx, ty]) => { const s = W.game.state; if (W.game.ui.busy) return 'busy'; const p = W.rules.findPath(s, tx, ty, true); if (!p || !p.length) return false; W.ui.walk(p); return true; }, [x, y]);
    if (ok === false) return 'nopath';
    await wait(30);
    await settle();
  }
  return 'timeout';
}

async function expedition() {
  const tf = await ev(targetFloorJS);
  ctx.wantHome = false; ctx.wantDown = false; ctx.wantBoss = false; ctx.wantUp = false;
  await click('[data-act="go"][data-arg="gate"]');
  await click(`[data-act="enter"][data-arg="${tf.floor}"]`);
  for (let hop = 0; hop < 6; hop++) {
    const info = await ev(() => { const s = W.game.state; if (!s.exp) return null; const m = W.rules.genFloor(s.exp.floor); return { f: s.exp.floor, map: m }; });
    if (!info) return;
    const { f, map } = info;
    // 의뢰 표식
    for (const m of Object.keys(map.markers)) {
      const isQ = await ev(([x, y]) => W.rules.tileState(W.game.state, x, y).kind === 'quest', [map.markers[m].x, map.markers[m].y]);
      if (isQ) { await walkTo(map.markers[m].x, map.markers[m].y); if (!(await ev(() => !!W.game.state.exp))) return; }
    }
    // 상자·사건·열쇠·퍼즐
    const targets = await ev(() => {
      const s = W.game.state, R = W.rules, m = R.genFloor(s.exp.floor); const out = [];
      for (let y = 0; y < m.h; y++) for (let x = 0; x < m.w; x++) { const k = R.tileState(s, x, y).kind; if (['chest', 'event', 'key', 'puzzle'].includes(k) && !m.locked.includes(R.key(x, y))) out.push([x, y]); }
      if (m.door && m.treasure && R.count(s, 'key')) out.push([m.door.x, m.door.y], [m.treasure.x, m.treasure.y]);
      return out;
    });
    for (const [x, y] of targets) {
      const low = await ev(() => { const s = W.game.state, R = W.rules, st = R.stats(s); return s.player.hp < st.maxHp * 0.4 && !R.count(s, 'hp_potion') && !R.count(s, 'big_potion'); });
      if (low) break;
      const kind = await ev(([tx, ty]) => W.game.state.exp ? W.rules.tileState(W.game.state, tx, ty).kind : 'gone', [x, y]);
      if (kind === 'gone') return;
      if (kind === 'floor' || kind === 'chestOpen' || kind === 'doorOpen') continue;
      await walkTo(x, y);
      if (!(await ev(() => !!W.game.state.exp))) return;
    }
    // 더 내려가기 / 보스
    const plan = await ev(([deeper]) => { const s = W.game.state, D = W.DATA; const f = s.exp.floor; return { canDown: deeper && D.FLOORS[f].down && s.player.lv >= D.FLOORS[f + 1].recLv - 1, boss: f === 5 && !s.flags.bossDefeated && s.player.lv >= 6 }; }, [tf.deeper]);
    if (plan.boss) {
      ctx.wantBoss = true;
      await walkTo(map.goal.x, map.goal.y);
      ctx.wantBoss = false;
      break;
    }
    if (plan.canDown) {
      ctx.wantDown = true;
      await walkTo(map.goal.x, map.goal.y);
      ctx.wantDown = false;
      const nf = await ev(() => W.game.state.exp && W.game.state.exp.floor);
      if (nf === f + 1) { if (nf === 2 || nf === 5) await shot(`arrive-b${nf}`); continue; }
    }
    break;
  }
  // 귀환
  if (!(await ev(() => !!W.game.state.exp))) return;
  ctx.wantHome = true;
  const hasFeather = await ev(() => W.rules.count(W.game.state, 'feather') > 0);
  if (hasFeather) await click('[data-act="goHomeAsk"]');
  else {
    for (let i = 0; i < 8; i++) {
      const at = await ev(() => { const s = W.game.state; if (!s.exp) return null; return W.rules.genFloor(s.exp.floor).start; });
      if (!at) break;
      await walkTo(at.x, at.y);
      const still = await ev(() => !!W.game.state.exp);
      if (!still) break;
      await page.click('[data-act="here"]'); await wait(30); await settle();
    }
  }
  ctx.wantHome = false;
}

(async () => {
  const browser = await chromium.launch();
  const bctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1, isMobile: true, hasTouch: true });
  page = await bctx.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push('pageerror: ' + e.message));
  page.on('console', (m) => { if (m.type() === 'error' && !/ERR_CERT_AUTHORITY_INVALID|fonts\./.test(m.text())) errors.push('console: ' + m.text()); });
  await page.goto(URL);
  await wait(200);
  await ev((seed) => { W.game.ui.speed = 0.03; W.rules.setRng(W.rules.makeRng(seed)); }, SEED);
  await page.click('[data-act="newGame"]');
  await wait(100);
  await settle();
  const t0 = Date.now();
  let result = 'timeout';
  for (let d = 0; d < MAX_DAYS; d++) {
    const h = await hubPhase();
    if (h === 'end') { result = 'ending'; break; }
    await expedition();
    await settle();
    const s = await ev(() => ({ day: W.game.state.day, lv: W.game.state.player.lv, pur: W.game.state.purified, boss: W.game.state.flags.bossDefeated, silver: W.game.state.silver, floor: W.game.state.floorsReached, deaths: W.game.state.stats.defeats }));
    console.log(`Day ${s.day}: Lv${s.lv} 실적 ${s.pur}/5 B${s.floor} 보스${s.boss ? 'O' : 'X'} 은화 ${s.silver} 패배 ${s.deaths}`);
    if (await ev(() => W.game.state.flags.endingSeen)) { result = 'ending'; break; }
  }
  await settle();
  await shot('final');
  const fin = await ev(() => { const s = W.game.state; return { day: s.day, lv: s.player.lv, purified: s.purified, battles: s.stats.battles, badges: Object.keys(s.badges).length, codex: Object.keys(s.codex).length, deaths: s.stats.defeats, quiz: s.stats.quizCorrect, puzzles: s.stats.puzzles }; });
  console.log(JSON.stringify({ seed: SEED, result, seconds: Math.round((Date.now() - t0) / 1000), final: fin, errors, sheetsSeen: Object.keys(stats.sheets).length, shots: stats.shots }, null, 1));
  await browser.close();
  if (result !== 'ending' || errors.length) process.exit(1);
})().catch((e) => { console.error('E2E-full 실패:', e.message); process.exit(1); });
