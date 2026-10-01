// 브라우저 E2E: 모바일 세로 화면에서 실제 UI로 핵심 순환을 플레이한다.
// 사용: node tests/e2e.cjs [--small]  (스크린샷: tests/out/*.png)
const path = require('path');
const { chromium } = require('/opt/node22/lib/node_modules/playwright');

const SMALL = process.argv.includes('--small');
const VIEW = SMALL ? { width: 375, height: 667 } : { width: 390, height: 844 };
const OUT = path.join(__dirname, 'out');
const URL = 'file://' + path.join(__dirname, '..', 'dist', 'index.html');

let shotN = 0;
async function shot(page, name) {
  const file = path.join(OUT, `${SMALL ? 's' : 'm'}${String(++shotN).padStart(2, '0')}-${name}.png`);
  await page.screenshot({ path: file });
  return file;
}
const wait = (page, ms) => page.waitForTimeout(ms);

async function state(page) { return page.evaluate(() => JSON.parse(JSON.stringify(W.game.state))); }

// 열린 대화/시트/전투를 자동으로 처리한다
async function settle(page, opts) {
  const o = opts || {};
  for (let i = 0; i < 400; i++) {
    const ui = await page.evaluate(() => ({
      dialog: !!document.querySelector('#dialog .dialog'),
      battle: !!document.querySelector('#battle'),
      sheet: !!document.querySelector('#sheet .sheet'),
      puzzle: !!(W.game.ui.puzzle),
      busy: W.game.ui.busy,
    }));
    if (ui.dialog) { await page.click('.dialog-skip'); await wait(page, 60); continue; }
    if (ui.battle) {
      const can = await page.evaluate(() => { const B = W.game.ui.battle; return B && !B.busy && !B.b.over; });
      if (can) {
        const act = await page.evaluate(() => {
          const s = W.game.state, B = W.game.ui.battle, b = B.b, R = W.rules, D = W.DATA, st = R.stats(s);
          if (s.player.hp < st.maxHp * 0.35 && R.count(s, 'hp_potion')) return { menu: 'item', id: 'hp_potion' };
          if (b.charging && R.knownSpells(s).includes('ice') && s.player.mp >= D.SPELLS.ice.mp) return { menu: 'spell', id: 'ice' };
          if (b.weak && R.knownSpells(s).includes(b.weak) && s.player.mp >= D.SPELLS[b.weak].mp + 3) return { menu: 'spell', id: b.weak };
          return { menu: 'attack' };
        });
        if (o.battleShot && !o.battleShotDone) { o.battleShotDone = true; await shot(page, 'battle'); }
        if (act.menu === 'attack') await page.click('[data-act="battack"]');
        else {
          await page.click(`[data-act="bmenu"][data-arg="${act.menu}"]`);
          if (o.menuShot && !o.menuShotDone && act.menu === 'spell') { o.menuShotDone = true; await shot(page, 'battle-spells'); }
          await page.click(`[data-act="${act.menu === 'spell' ? 'bspell' : 'bitem'}"][data-arg="${act.id}"]`);
        }
      }
      await wait(page, 120);
      continue;
    }
    if (ui.puzzle) {
      // 촛불 퍼즐: 512가지 조합 중 해답을 찾아 누른다
      const presses = await page.evaluate(() => {
        const g0 = W.game.ui.puzzle.g.slice();
        for (let m = 0; m < 512; m++) {
          const g = g0.slice();
          const list = [];
          for (let i = 0; i < 9; i++) if (m & (1 << i)) { W.rules.puzzleToggle(g, i); list.push(i); }
          if (g.every(Boolean)) return list;
        }
        return [];
      });
      if (o.puzzleShot && !o.puzzleShotDone) { o.puzzleShotDone = true; await shot(page, 'puzzle'); }
      for (const i of presses) { await page.click(`[data-act="candle"][data-arg="${i}"]`); await wait(page, 40); }
      await wait(page, 700);
      continue;
    }
    if (ui.sheet) {
      if (o.sheetShot && !o.sheetShotDone) { o.sheetShotDone = true; await shot(page, o.sheetShot); }
      const clicked = await page.evaluate(() => {
        const prim = document.querySelector('#sheet .btn.primary:not([disabled]), #sheet .btn.curse:not([disabled])');
        if (prim) { prim.click(); return 'primary'; }
        const ch = document.querySelector('#sheet [data-act="choose"]:not([disabled])');
        if (ch) { ch.click(); return 'choose'; }
        const close = document.querySelector('#sheet [data-act="sheetDismiss"]');
        if (close) { close.click(); return 'close'; }
        return null;
      });
      if (!clicked) throw new Error('시트를 닫을 수 없음');
      await wait(page, 120);
      continue;
    }
    if (ui.busy) { await wait(page, 80); continue; }
    return;
  }
  throw new Error('settle 시간 초과');
}

// 전체 지도 기준으로 목표까지 걸어간다 (사건이 생기면 처리하고 이어서)
async function walkTo(page, tx, ty, opts) {
  for (let i = 0; i < 60; i++) {
    const at = await page.evaluate(() => ({ x: W.game.state.exp && W.game.state.exp.x, y: W.game.state.exp && W.game.state.exp.y, inDungeon: !!W.game.state.exp }));
    if (!at.inDungeon) return 'left';
    if (at.x === tx && at.y === ty) return 'arrived';
    const ok = await page.evaluate(([x, y]) => {
      const p = W.rules.findPath(W.game.state, x, y, true);
      if (!p || !p.length) return false;
      W.ui.walk(p);
      return true;
    }, [tx, ty]);
    if (!ok) return 'nopath';
    await wait(page, 200);
    await settle(page, opts);
  }
  return 'timeout';
}

(async () => {
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ viewport: VIEW, deviceScaleFactor: 2, isMobile: true, hasTouch: true, locale: 'ko-KR' });
  const page = await ctx.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push('pageerror: ' + e.message));
  page.on('console', (m) => { if (m.type() === 'error' && !/fonts\.(googleapis|gstatic)|ERR_CERT_AUTHORITY_INVALID/.test(m.text())) errors.push('console: ' + m.text()); });
  page.on('requestfailed', (r) => { if (!/fonts\.(googleapis|gstatic)/.test(r.url())) errors.push('requestfailed: ' + r.url()); });

  await page.goto(URL);
  await wait(page, 400);
  await shot(page, 'title');

  // 새 게임 + 인트로
  await page.click('[data-act="newGame"]');
  await wait(page, 300);
  await shot(page, 'intro-dialog');
  await settle(page);
  await shot(page, 'field');
  // v0.2: 첫 마법은 기본마법반 수업으로 배운다 (수업 화면은 e2e-field.cjs 가 검증)
  await page.evaluate(() => { W.rules.learnSpell(W.game.state, 'fire'); W.ui.save(); });

  // 부실: 손님 매입
  await page.evaluate(() => W.ui.go('club'));
  await wait(page, 250);
  await settle(page);
  await shot(page, 'club');
  await page.click('[data-act="customer"][data-arg="q1"]');
  await wait(page, 200);
  await page.click('.dialog-skip');
  await wait(page, 200);
  await shot(page, 'customer-sheet');
  await settle(page);
  let s = await state(page);
  if (s.quests.q1.status !== 'active') throw new Error('q1 매입 실패');

  // 매점: 체력 물약 2개
  await page.evaluate(() => W.ui.go('field'));
  await wait(page, 150);
  await page.evaluate(() => W.ui.go('shop'));
  await wait(page, 200);
  await shot(page, 'shop');
  await page.click('[data-act="buySheet"][data-arg="hp_potion"]');
  await wait(page, 150);
  await page.click('[data-act="qty"][data-arg="1"]');
  await wait(page, 100);
  await shot(page, 'buy-sheet');
  await page.click('[data-act="buyConfirm"]');
  await wait(page, 150);
  s = await state(page);
  if (s.inv.hp_potion !== 5) throw new Error('물약 구매 실패: ' + s.inv.hp_potion);

  // 봉인 창고 B1
  await page.evaluate(() => W.ui.go('field'));
  await wait(page, 150);
  await page.evaluate(() => W.ui.go('gate'));
  await wait(page, 200);
  await shot(page, 'gate');
  await page.click('[data-act="enter"][data-arg="1"]');
  await wait(page, 300);
  await settle(page);
  await shot(page, 'dungeon-start');

  // 지도 탭으로 한 칸 이동 (실제 탭 입력 검증)
  const tapped = await page.evaluate(() => {
    const s = W.game.state; const R = W.rules;
    for (const [dx, dy] of [[0, -1], [1, 0], [0, 1], [-1, 0]]) {
      const x = s.exp.x + dx, y = s.exp.y + dy;
      if (R.tileState(s, x, y).walk) return { x, y };
    }
    return null;
  });
  const box = await page.locator('#map-cv').boundingBox();
  const tile = await page.evaluate(() => W.game.ui.tile);
  await page.mouse.click(box.x + (tapped.x + 0.5) * tile, box.y + (tapped.y + 0.5) * tile);
  await wait(page, 400);
  await settle(page);
  s = await state(page);
  if (s.exp && !(s.exp.x === tapped.x && s.exp.y === tapped.y) && s.stats.battles === 0) throw new Error('탭 이동 실패');

  // 아래층 계단 바로 앞까지 이동 (전투·사건 자동 처리). v0.2부터 q1은 학교 음악실 의뢰라 B1 표식이 없다.
  const near = await page.evaluate(() => { const m = W.rules.genFloor(1); for (const [dx, dy] of [[0, -1], [1, 0], [0, 1], [-1, 0]]) { const ch = W.rules.tileCh(m, m.goal.x + dx, m.goal.y + dy); if (ch !== '#') return { x: m.goal.x + dx, y: m.goal.y + dy }; } return null; });
  const r1 = await walkTo(page, near.x, near.y, { battleShot: true, menuShot: true, sheetShot: 'first-event' });
  await shot(page, 'dungeon-after-walk');
  s = await state(page);
  if (!s.exp || s.stats.battles < 1) throw new Error('B1 탐험 중 전투가 없었다: walk=' + r1 + ' battles=' + s.stats.battles);

  // 먹물 힌트
  await page.click('[data-act="petHint"]');
  await wait(page, 300);
  await shot(page, 'pet-hint');

  // 가방 열기
  await page.click('.d-btns [data-act="openBag"]');
  await wait(page, 200);
  await shot(page, 'bag');
  await page.click('#sheet .sh-head [data-act="sheetDismiss"]');

  // 귀환 깃털
  await page.click('[data-act="goHomeAsk"]');
  await wait(page, 200);
  await settle(page);
  await wait(page, 300);
  s = await state(page);
  if (s.exp) throw new Error('귀환 실패');
  await shot(page, 'field-day2');

  // 음악실 의뢰 해결 (필드 조작은 e2e-field.cjs 가 검증)
  await page.evaluate(() => { const s = W.game.state; W.world.enterArea(s, 'music', 8, 4); W.world.search(s, 'bench'); W.world.useLocker(s); W.world.enterArea(s, 'club', 4, 5); });
  // 정화
  await page.evaluate(() => W.ui.go('club'));
  await wait(page, 200);
  await settle(page);
  await page.click('[data-act="purifyQuest"][data-arg="q1"]');
  await wait(page, 700);
  await shot(page, 'purify-reveal');
  await settle(page);
  s = await state(page);
  if (s.purified !== 1) throw new Error('정화 실패');
  await shot(page, 'club-after');

  // 상태·도감·훈장·설정 시트
  await page.evaluate(() => W.ui.go('field'));
  await wait(page, 200);
  for (const [act, name] of [['openStatus', 'status'], ['openCodex', 'codex'], ['openBadges', 'badges'], ['openSettings', 'settings']]) {
    await page.click(`.tabbar [data-act="${act}"]`);
    await wait(page, 250);
    await shot(page, name);
    await page.click('#sheet .sh-head [data-act="sheetDismiss"]');
    await wait(page, 120);
  }

  // B2 진입 후 더 깊이: 디버그로 층 개방 후 이상한 방(B2 퍼즐) 확인
  await page.evaluate(() => { W.game.state.floorsReached = 2; W.rules.gainExp(W.game.state, 100); W.game.state.inv.hp_potion = 8; W.game.state.inv.mp_potion = 3; W.ui.save(); });
  await page.evaluate(() => W.ui.go('gate'));
  await wait(page, 150);
  await page.click('[data-act="enter"][data-arg="2"]');
  await wait(page, 300);
  await settle(page);
  const p2 = await page.evaluate(() => { const m = W.rules.genFloor(2); for (let y = 0; y < m.h; y++) for (let x = 0; x < m.w; x++) if (m.tiles[y][x] === 'P') return { x, y }; return null; });
  await walkTo(page, p2.x, p2.y, { puzzleShot: true });
  s = await state(page);
  await shot(page, 'b2-after-puzzle');

  // 작은 화면에서는 레이아웃만, 큰 화면은 보스전 화면도 확인
  if (!SMALL) {
    await page.evaluate(() => { const s = W.game.state; s.floorsReached = 5; W.rules.gainExp(s, 600); s.inv.hp_potion = 9; s.inv.mp_potion = 5; s.inv.salt = 2; });
    const res = page.evaluate(() => W.ui.runBattle('nocturne', {}));
    await wait(page, 900);
    await shot(page, 'boss-battle');
    await settle(page);
    await res;
    await shot(page, 'after-boss');
  }

  console.log(JSON.stringify({ viewport: VIEW, shots: shotN, errors, final: { day: s.day, lv: s.player.lv, purified: s.purified, silver: s.silver } }, null, 1));
  await browser.close();
  if (errors.length) process.exit(1);
})().catch(async (e) => { console.error('E2E 실패:', e.message); process.exit(1); });
