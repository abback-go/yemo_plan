// 브라우저 E2E (v0.2 학교 필드): 실제 탭으로 지도를 걸어 다니며 수업·퍼즐·미로·의뢰를 진행한다.
// 사용: node tests/e2e-field.cjs [--small]  (스크린샷: tests/out/f*.png)
const path = require('path');
const { chromium } = require('/opt/node22/lib/node_modules/playwright');

const SMALL = process.argv.includes('--small');
const VIEW = SMALL ? { width: 375, height: 667 } : { width: 390, height: 844 };
const OUT = path.join(__dirname, 'out');
const URL = 'file://' + path.join(__dirname, '..', 'dist', 'index.html');
const wait = (page, ms) => page.waitForTimeout(ms);
let n = 0;
const shot = (page, name) => page.screenshot({ path: path.join(OUT, `f${SMALL ? 's' : 'm'}${String(++n).padStart(2, '0')}-${name}.png`) });
const st = (page) => page.evaluate(() => JSON.parse(JSON.stringify(W.game.state)));
const checks = [];
function check(name, ok, detail) {
  void 0; checks.push({ name, ok }); console.log(`${ok ? '✓' : '✗'} ${name}${detail ? ' — ' + detail : ''}`); if (!ok) process.exitCode = 1; }

async function skipDialogs(page) {
  for (let i = 0; i < 40; i++) {
    if (!(await page.$('#dialog .dialog'))) return;
    await page.click('.dialog-skip'); await wait(page, 60);
  }
}
async function idle(page) {
  for (let i = 0; i < 300; i++) {
    const busy = await page.evaluate(() => W.game.ui.busy || !!W.game.ui.battle);
    if (await page.$('#dialog .dialog')) { await skipDialogs(page); continue; }
    if (await page.evaluate(() => !!W.game.ui.battle)) { await battleStep(page); continue; }
    if (!busy) return;
    await wait(page, 40);
  }
}
async function battleStep(page) {
  const can = await page.evaluate(() => { const B = W.game.ui.battle; return B && !B.busy && !B.b.over; });
  if (can) {
    const act = await page.evaluate(() => {
      const s = W.game.state, b = W.game.ui.battle.b, R = W.rules, D = W.DATA, st = R.stats(s);
      if (s.player.hp < st.maxHp * 0.35 && R.count(s, 'hp_potion')) return { menu: 'item', id: 'hp_potion' };
      if (b.weak && R.knownSpells(s).includes(b.weak) && s.player.mp >= D.SPELLS[b.weak].mp) return { menu: 'spell', id: b.weak };
      return { menu: 'attack' };
    });
    if (act.menu === 'attack') await page.click('[data-act="battack"]');
    else { await page.click(`[data-act="bmenu"][data-arg="${act.menu}"]`); await page.click(`[data-act="${act.menu === 'spell' ? 'bspell' : 'bitem'}"][data-arg="${act.id}"]`); }
  }
  await wait(page, 60);
  // 보상 시트
  const sheet = await page.$('#sheet .btn.primary');
  if (sheet && !(await page.evaluate(() => !!W.game.ui.battle))) await sheet.click();
}
// 지도 칸을 손가락으로 탭한다 (카메라 위치를 고려)
async function tap(page, x, y) {
  const p = await page.evaluate(([x, y]) => {
    const c = W.game.ui.fcam, r = document.querySelector('#field-cv').getBoundingClientRect();
    return { x: r.left + (x + 0.5) * c.ts - c.cx, y: r.top + (y + 0.5) * c.ts - c.cy, inside: true };
  }, [x, y]);
  await page.mouse.click(p.x, p.y);
  await wait(page, 30);
  await idle(page);
}
// 화면 밖 칸이면, 그쪽으로 가는 길 중 화면에 보이는 가장 먼 칸을 먼저 탭한다 (손으로 하는 것과 같다)
async function tapFar(page, x, y) {
  for (let i = 0; i < 6; i++) {
    const t = await page.evaluate(([x, y]) => {
      const c = W.game.ui.fcam, r = document.querySelector('#field-cv').getBoundingClientRect();
      const scr = (tx, ty) => ({ x: r.left + (tx + 0.5) * c.ts - c.cx, y: r.top + (ty + 0.5) * c.ts - c.cy });
      const inside = (p) => p.x > r.left + 4 && p.x < r.right - 4 && p.y > r.top + 4 && p.y < r.bottom - 4;
      if (inside(scr(x, y))) return [x, y];
      const path = W.world.findPath(W.game.state, x, y) || [];
      for (let k = path.length - 2; k >= 0; k--) if (inside(scr(path[k][0], path[k][1]))) return path[k];
      return null;
    }, [x, y]);
    if (!t) return;
    const area = (await st(page)).field.area;
    await tap(page, t[0], t[1]);
    if (t[0] === x && t[1] === y) return;
    if ((await st(page)).field.area !== area) return;
  }
}
async function pressSheet(page, label) {
  for (let i = 0; i < 50; i++) {
    const ok = await page.evaluate((label) => {
      const b = [...document.querySelectorAll('#sheet button')].find((x) => x.textContent.includes(label) && !x.disabled);
      if (b) { b.click(); return true; } return false;
    }, label);
    if (ok) { await wait(page, 80); return true; }
    await wait(page, 60);
  }
  return false;
}
// 목표 구역까지 출입구를 따라 걷는다
async function goArea(page, target) {
  for (let i = 0; i < 10; i++) {
    const s = await st(page);
    const scr = await page.evaluate(() => W.game.ui.screen);
    if (scr !== 'field') { await page.click('[data-act="backField"]'); await wait(page, 100); continue; }
    if (s.field.area === target) return true;
    const e = await page.evaluate((t) => W.world.routeExit(W.game.state, t), target);
    if (!e) return false;
    if (s.field.area === 'maze') await page.click('[data-act="mazeOut"]');
    else await tapFar(page, e.x, e.y);
    await idle(page);
    await skipDialogs(page);
    await wait(page, 100);
  }
  return (await st(page)).field.area === target;
}
async function tapObject(page, id) {
  const o = await page.evaluate((id) => { const list = W.world.objects(W.game.state); const o = list.find((q) => q.id === id) || list.find((q) => q.id.startsWith(id)); return o && { x: o.x, y: o.y }; }, id);
  if (!o) throw new Error('물체 없음: ' + id);
  await tap(page, o.x, o.y);
}

(async () => {
  require('fs').mkdirSync(OUT, { recursive: true });
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: VIEW, deviceScaleFactor: 2, hasTouch: false });
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));
  page.on('console', (m) => { if (m.type() === 'error' && !/ERR_CERT|fonts\.g/.test(m.text())) errors.push(m.text()); });
  await page.goto(URL);
  await page.evaluate(() => { W.game.ui.speed = 0.3; });
  await page.click('[data-act="newGame"]');
  await skipDialogs(page);
  let s = await st(page);
  check('새 게임은 부실 필드에서 시작', s.field.area === 'club' && (await page.evaluate(() => W.game.ui.screen)) === 'field');
  check('처음엔 마법이 없다', s.spells.length === 0);
  await shot(page, 'club');

  // 1) 기본마법반에서 불씨 배우기 (룬 미니게임)
  check('복도→기본마법반 이동', await goArea(page, 'class1'));
  await skipDialogs(page);
  await shot(page, 'class1');
  await tapObject(page, 'flam');
  await pressSheet(page, '「불씨」 수업 듣기');
  await pressSheet(page, '시작');
  await wait(page, 400);
  await shot(page, 'rune-show');
  for (let i = 0; i < 100 && (await page.evaluate(() => W.game.ui.rune && W.game.ui.rune.phase)) !== 'input'; i++) await wait(page, 80);
  const seq = await page.evaluate(() => W.game.ui.rune.seq.slice());
  for (const r of seq) { await page.click(`[data-act="rune"][data-arg="${r}"]`); await wait(page, 60); }
  await wait(page, 900);
  await pressSheet(page, '좋아!');
  await pressSheet(page, '교실을 나선다');
  s = await st(page);
  check('룬을 순서대로 눌러 불씨를 배움', s.spells.includes('fire'), `룬 ${seq.length}개`);

  // 2) 부실: 첫 손님 매입
  check('기본마법반→부실 이동', await goArea(page, 'club'));
  await tapObject(page, 'cust:q1');
  await skipDialogs(page);
  await pressSheet(page, '매입한다');
  await skipDialogs(page);
  s = await st(page);
  check('포포의 오르골 매입', s.quests.q1.status === 'active');

  // 3) 음악실: 숨은 물건 찾기
  check('부실→음악실 이동', await goArea(page, 'music'));
  await skipDialogs(page);
  await tapObject(page, 'locker');
  s = await st(page);
  check('열쇠 없이 사물함은 안 열림', s.quests.q1.status === 'active');
  await tapObject(page, 'stand'); await shot(page, 'music-note'); await pressSheet(page, '확인');
  await tapObject(page, 'drum'); await pressSheet(page, '확인');
  await tapObject(page, 'bench'); await pressSheet(page, '확인');
  await tapObject(page, 'locker'); await skipDialogs(page);
  s = await st(page);
  check('의자 밑 열쇠 → 사물함에서 태엽', s.quests.q1.status === 'ready' && s.inv.q_spring === 1);
  await shot(page, 'music');

  // 4) 부실 정화대에서 정화
  check('음악실→부실 이동', await goArea(page, 'club'));
  await tapObject(page, 'desk'); await skipDialogs(page);
  check('정화대 → 부실 관리 화면', (await page.evaluate(() => W.game.ui.screen)) === 'club');
  await page.click('[data-act="purifyQuest"][data-arg="q1"]');
  await wait(page, 200);
  await pressSheet(page, '장착'); await skipDialogs(page);
  s = await st(page);
  check('정화 실적 1', s.purified === 1);
  await page.click('[data-act="backField"]'); await wait(page, 150); await skipDialogs(page);

  // 5) 도서관: 책수레 밀기
  check('부실→도서관 이동', await goArea(page, 'library'));
  await skipDialogs(page);
  await shot(page, 'library');
  const dpad = async (dx, dy) => { await page.click(`[data-act="fmove"][data-arg="${dx},${dy}"]`); await wait(page, 60); await idle(page); };
  await tap(page, 5, 10); await tap(page, 5, 9);
  await dpad(-1, 0); await dpad(-1, 0);
  await tap(page, 2, 10); await dpad(0, -1); await dpad(0, -1);
  await shot(page, 'library-half');
  await tap(page, 5, 10); await tap(page, 5, 9);
  await dpad(1, 0); await dpad(1, 0);
  await tap(page, 8, 10); await dpad(0, -1); await dpad(0, -1);
  await skipDialogs(page);
  s = await st(page);
  check('수레 두 대로 판을 눌러 철문 열림', s.field.libGate === true);
  await tapObject(page, 'hintbook'); await shot(page, 'hintbook'); await pressSheet(page, '기억했다');
  await tapObject(page, 'libchest'); await pressSheet(page, '챙긴다');
  s = await st(page);
  check('금서 칸 상자 → 고급 골동품', s.field.libChest && s.antiques.some((a) => a.state === 'cursed' && a.grade === 'uncommon'));
  await shot(page, 'library-open');

  // 6) 정원: 분수 룬 판 순서
  check('도서관→정원 이동', await goArea(page, 'garden'));
  await skipDialogs(page);
  await tap(page, 3, 6); // 틀린 첫 판(해)
  s = await st(page);
  check('틀린 순서는 초기화', s.field.plates.length === 0 && !s.field.fountain);
  for (const [x, y] of [[3, 10], [3, 6], [7, 6], [7, 10]]) await tap(page, x, y);
  await skipDialogs(page);
  s = await st(page);
  check('달→해→별→구름 순서로 분수 퍼즐 해결', s.field.fountain === true);
  await tapObject(page, 'well'); await pressSheet(page, '챙긴다');
  s = await st(page);
  check('우물 → 희귀 골동품', s.field.well && s.antiques.some((a) => a.grade === 'rare'));
  await shot(page, 'garden');

  // 7) 밤의 미로: 한가운데 오두막 (UI 테스트이므로 레벨만 올려 전투를 빠르게)
  await page.evaluate(() => { const s = W.game.state; s.player.lv = 5; s.player.hp = W.rules.stats(s).maxHp; });
  check('정원→밤의 미로 이동', await goArea(page, 'maze'));
  await skipDialogs(page);
  await shot(page, 'maze');
  let guard = 0;
  while (guard++ < 120) {
    s = await st(page);
    if (s.field.area !== 'maze') break;
    // 지도를 다 아는 길(정답)을 한 칸씩 따라간다: 실제 플레이어는 안개 속에서 길을 찾는다
    const next = await page.evaluate(() => {
      const s = W.game.state, a = W.world.cur(s), m = a.maze;
      const key = (x, y) => x + ',' + y;
      const goal = m.shed;
      const prev = new Map([[key(s.field.x, s.field.y), null]]);
      const q = [[s.field.x, s.field.y]];
      while (q.length) {
        const [x, y] = q.shift();
        for (const [dx, dy] of [[0, -1], [1, 0], [0, 1], [-1, 0]]) {
          const nx = x + dx, ny = y + dy, k = key(nx, ny);
          if (prev.has(k)) continue;
          if (nx === goal.x && ny === goal.y) {
            let c = [x, y], path = [];
            while (c && !(c[0] === s.field.x && c[1] === s.field.y)) { path.unshift(c); c = prev.get(key(c[0], c[1])); }
            return path.length ? path[0] : 'adjacent';
          }
          if (a.rows[ny] == null || a.rows[ny][nx] !== '.') continue;
          prev.set(k, [x, y]); q.push([nx, ny]);
        }
      }
      return null;
    });
    if (next === 'adjacent' || !next) break;
    await tap(page, next[0], next[1]);
  }
  await shot(page, 'maze-center');
  await tapObject(page, 'shed'); await pressSheet(page, '확인'); await skipDialogs(page);
  s = await st(page);
  check('미로 한가운데 오두막 도착', !!s.flags.mazeCenter && s.field.area === 'maze', `전투 ${s.stats.battles}회`);

  // 8) 부실 침대: 하루 지나기
  check('미로→부실 이동', await goArea(page, 'club'));
  const day0 = (await st(page)).day;
  await tapObject(page, 'bed'); await pressSheet(page, '잔다');
  s = await st(page);
  check('침대에서 자면 하루가 지남', s.day === day0 + 1 && s.player.mp === (await page.evaluate(() => W.rules.stats(W.game.state).maxMp)));

  // 9) 봉인 창고 입구는 정원 남쪽 출입구
  check('정원 남쪽 → 봉인 창고 화면', (await goArea(page, 'garden')) && (await (async () => { const e = await page.evaluate(() => W.world.AREAS.garden.exits.find((x) => x.screen === 'gate')); await tapFar(page, e.x, e.y); return (await page.evaluate(() => W.game.ui.screen)) === 'gate'; })()));
  await shot(page, 'gate');

  check('콘솔/페이지 오류 0', errors.length === 0, errors.slice(0, 3).join(' | '));
  console.log(`\n${checks.filter((c) => c.ok).length}/${checks.length} 통과`);
  await browser.close();
})();
