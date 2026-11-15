/*
 * 스모크 테스트 (Playwright + Chromium)
 *   node prototype/tests/smoke.js [스크린샷 폴더]
 *
 * 경로 A: 타이틀 → 캠프(대사 끝까지 클릭) → 일반 전투(실제 드래그로 성검·운명 전가·감싸기)
 *         → 거대 존재 등장 → 거대 존재 전투(공격 무효 확인) → 죽음 카드 → 컷신 C1~C6 → C7·C8
 *         → 짓밟힘 → 존재가 물러남 → 탈출 → 종료 화면
 * 경로 B: 다시 하기 → 캠프 건너뛰기 → 일반 전투(디버그 즉시 승리) → 거대 존재 전투에서 카드 없이 3턴
 *         → 짓밟기로 전멸 → 다시 → 거대 존재 등장 직후(1턴)부터 재시작
 * 경로 C: 1280×960 창(검은 여백)에서 드래그 좌표 확인 → 일반 전투 전멸 → 이 전투 처음부터 재시작
 * 콘솔 에러: 스크립트 에러 0 이어야 통과. 없는 그림 파일의 리소스 로드 실패 로그는 따로 집계한다.
 */
'use strict';
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const ROOT = path.resolve(__dirname, '..');
const URL = 'file://' + path.join(ROOT, 'index.html') + '?seed=7&speed=4';
const SHOTS = process.argv[2] || path.join(ROOT, 'tests', 'shots');
fs.mkdirSync(SHOTS, { recursive: true });

const results = [];
function check(name, ok, detail) {
  results.push({ name, ok: !!ok, detail });
  console.log((ok ? '  ✔ ' : '  ✘ ') + name + (detail ? ' — ' + detail : ''));
}

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 1 });
  const errors = [], missing = [], failedUrls = [];
  page.on('requestfailed', r => failedUrls.push(r.url()));
  page.on('console', m => {
    if (m.type() !== 'error') return;
    if (/Failed to load resource: net::ERR_FILE_NOT_FOUND/.test(m.text())) missing.push(m.text());
    else errors.push(m.text());
  });
  page.on('pageerror', e => errors.push('pageerror: ' + e.message));

  const shot = name => page.screenshot({ path: path.join(SHOTS, name) });
  const ev = (fn, arg) => page.evaluate(fn, arg);
  const state = () => ev(() => Game.debug.state());
  async function waitIdle(timeout) {
    await page.waitForFunction(() => Game.Ctl.inBattle && !Game.Ctl.busy && Game.Ctl.st.battle && Game.Ctl.st.battle.phase === 'player' && !Game.Scenes.current, null, { timeout: timeout || 60000 });
    await page.waitForTimeout(150);
  }
  async function cardPos(id) {
    return ev(id => {
      const st = Game.Ctl.st, u = st.battle.hand.find(x => st.cards[x].id === id);
      if (!u) return null;
      const c = Game.Hand.center(u);
      return { x: c.x, y: c.y + 30 };
    }, id);
  }
  const enemyPos = id => ev(id => Game.View.enemyCenter(id), id);
  const intentPos = id => ev(id => { const r = Game.View.intentRect(id); return { x: r.x + r.w / 2, y: r.y + r.h / 2 }; }, id);
  const allyPos = id => ev(id => { const r = id === 'witch' ? Game.View.witchRect() : Game.View.allyHitRect(id); return { x: r.x + r.w / 2, y: r.y + r.h / 2 }; }, id);
  // 1920×1080 논리 좌표 → 창 좌표 (창 크기가 달라도 동작하는지 확인하려고 항상 변환)
  async function toPage(p) {
    const r = await ev(() => { const b = document.getElementById('stage').getBoundingClientRect(); return { l: b.left, t: b.top, s: b.width / 1920 }; });
    return { x: r.l + p.x * r.s, y: r.t + p.y * r.s };
  }
  async function drag(from, to) {
    from = await toPage(from); to = await toPage(to);
    await page.mouse.move(from.x, from.y);
    await page.waitForTimeout(80);
    await page.mouse.down();
    await page.mouse.move((from.x + to.x) / 2, (from.y + to.y) / 2 + 20, { steps: 6 });
    await page.mouse.move(to.x, to.y, { steps: 8 });
    await page.waitForTimeout(60);
    await page.mouse.up();
  }
  async function clickAt(p) { p = await toPage(p); await page.mouse.click(p.x, p.y); }
  async function moveTo(p) { p = await toPage(p); await page.mouse.move(p.x, p.y); }
  async function playOn(cardId, to) {
    const p = await cardPos(cardId);
    if (!p) throw new Error('손패에 없음: ' + cardId);
    await drag(p, to);
  }
  async function clickEndTurn() {
    const r = await ev(() => { const e = document.getElementById('endTurn'); return { x: e.offsetLeft + e.offsetWidth / 2, y: e.offsetTop + e.offsetHeight / 2 }; });
    await clickAt(r);
  }
  async function waitScene(name, timeout) {
    await page.waitForFunction(n => Game.Scenes.current === n, name, { timeout: timeout || 60000 });
  }

  try {
    console.log('경로 A: 캠프 → 일반 전투 → 거대 존재 → 죽음 카드 → 컷신 → 짓밟힘 → 종료');
    await page.goto(URL);
    await waitScene('title', 20000);
    await shot('00_title.png');
    await page.click('[data-act=start]');
    await waitScene('camp');
    // 캠프: 끝까지 클릭으로 진행
    let lines = 0;
    for (let i = 0; i < 400; i++) {
      const sc = await ev(() => Game.Scenes.current);
      if (sc !== 'camp') break;
      const ln = await ev(() => +(document.querySelector('[data-scene=camp]') || { getAttribute: () => -1 }).getAttribute('data-line'));
      if (ln === 30 && !fs.existsSync(path.join(SHOTS, '01_camp.png'))) { await page.waitForTimeout(700); await shot('01_camp.png'); }
      lines = Math.max(lines, ln + 1);
      await clickAt({ x: 960, y: 900 });
      await page.waitForTimeout(45);
    }
    check('캠프 대화를 끝까지 진행', lines >= 40, lines + '줄');

    await waitIdle();
    let s = await state();
    check('일반 전투 시작: 광신도 3, 에너지 3, 손패 5', s.battle.kind === 'normal' && s.battle.enemies.length === 3 && s.battle.energy === 3 && s.battle.hand.length === 5, JSON.stringify(s.battle.hand));
    await shot('02_battle_normal.png');

    // 1턴: 성검 베기(드래그) → 광신도 B 일격
    await playOn('holy_slash', await enemyPos('c2'));
    await waitIdle();
    s = await state();
    check('성검 베기로 광신도를 일격에 쓰러뜨림 (드래그)', s.battle.enemies.find(e => e.id === 'c2').alive === false && s.battle.energy === 2);
    // 무효 위치에 놓으면 손으로 돌아감
    const before = (await state()).battle.hand.length;
    await drag(await cardPos('curse_flame'), { x: 120, y: 700 });
    await page.waitForTimeout(300);
    s = await state();
    check('무효 위치에 놓으면 카드가 손패로 돌아감', s.battle.hand.length === before && s.battle.energy === 2);
    await playOn('curse_flame', await enemyPos('c1'));
    await waitIdle();
    // 예고에 마우스를 올리면 선
    const ip = await intentPos('c3');
    await moveTo(ip);
    await page.waitForTimeout(400);
    check('예고에 마우스를 올리면 대상 표시', await ev(() => Game.Input.hoverIntent === 'c3'));
    await shot('03_intent_hover.png');
    await clickEndTurn();
    await waitIdle();
    s = await state();
    check('2턴 시작, 튜토리얼 손패(운명 전가·감싸기 포함)', s.battle.turn === 2 && s.battle.hand.includes('fate_shift') && s.battle.hand.includes('cover'), JSON.stringify(s.battle.hand));

    // 2턴: 운명 전가 ① 예고에 놓기 → ② 전사 클릭
    const tgtBefore = s.battle.enemies.find(e => e.id === 'c3').intent.target;
    await playOn('fate_shift', await intentPos('c3'));
    await page.waitForTimeout(300);
    check('운명 전가 ①단계 후 아군 선택 대기', await ev(() => Game.Input.mode === 'pick'));
    await shot('04_fate_shift_pick.png');
    const wp = await allyPos('warrior');
    await clickAt(wp);
    await waitIdle();
    s = await state();
    check('운명 전가: 예고 대상이 바뀜 (' + tgtBefore + ' → warrior)', s.battle.enemies.find(e => e.id === 'c3').intent.target === 'warrior');
    await playOn('cover', await intentPos('c1'));
    await waitIdle();
    s = await state();
    const c1i = s.battle.enemies.find(e => e.id === 'c1').intent;
    check('감싸기: 전사가 받되 절반', c1i.target === 'warrior' && c1i.halve === true);
    // 성검 베기 → 1명 남음 → 거대 존재 등장
    await playOn('holy_slash', await enemyPos('c3'));
    await page.waitForFunction(() => Game.Ctl.st.battle && Game.Ctl.st.battle.kind === 'giant', null, { timeout: 60000 });
    check('광신도 1명 남자 거대 존재가 짓밟고 전투 전환', true);
    await waitIdle();
    s = await state();
    check('거대 존재 1턴: 손패에 죽음 카드 + 4장', s.battle.hand.length === 5 && s.battle.hand.filter(x => x === 'hero_death').length === 1, JSON.stringify(s.battle.hand));
    await shot('05_giant_turn1.png');
    // 공격 무효
    const atk = ['curse_flame', 'snipe', 'shield_bash', 'suppress', 'holy_slash'].find(id => s.battle.hand.includes(id));
    if (atk) {
      await playOn(atk, await enemyPos('giant'));
      await waitIdle();
      s = await state();
      check('거대 존재에 공격 → 무효 (' + atk + ')', s.battle.enemies[0].alive === true && s.battle.enemies[0].hp === null);
    } else check('거대 존재에 공격 → 무효', false, '손패에 공격 카드 없음');
    // 1턴 종료 (그림자) → 2턴
    await clickEndTurn();
    await waitIdle();
    s = await state();
    check('카운트다운 2턴: 기둥 붕괴 예고, 죽음 카드 보존', s.battle.turn === 2 && s.battle.enemies[0].intent.kind === 'aoe' && s.battle.hand.includes('hero_death'));
    await shot('06_giant_turn2_thread.png');

    // 죽음 카드 사용 (위로 끌어올림, 에너지와 무관)
    const dp = await cardPos('hero_death');
    await drag(dp, { x: dp.x + 10, y: 360 });
    await page.waitForFunction(() => document.querySelector('[data-cut]'), null, { timeout: 20000 });
    const cuts = {};
    for (let i = 0; i < 600; i++) {
      const c = await ev(() => { const e = document.querySelector('[data-cut]'); return e ? e.getAttribute('data-cut') : null; });
      if (!c) { if (Object.keys(cuts).length) break; }
      else if (!cuts[c]) {
        cuts[c] = 1;
        await page.waitForTimeout(c === 'C3' ? 250 : c === 'C5' ? 700 : 300);
        await shot('07_cut_' + c + '.png');
      }
      await page.waitForTimeout(40);
    }
    const cutLog = await ev(() => Game.Scenes.cutLog || []);
    check('컷신 C1~C6 모두 재생', ['C1', 'C2', 'C3', 'C4', 'C5', 'C6'].every(c => cutLog.includes(c)), cutLog.join(',') + ' (캡처: ' + Object.keys(cuts).join(',') + ')');
    await page.waitForTimeout(500);
    await shot('08_after_death_C7.png');
    await waitIdle(60000);
    s = await state();
    check('용사 사망, 유품 3장, 짓밟힘(이번 턴 비용 0) 손패에', s.party.allies.hero.status === 'dead' &&
      s.party.deck.filter(x => x === 'broken_sword' || x === 'last_charge').length === 3 && s.battle.hand.includes('trample') &&
      await ev(() => { const st = Game.Ctl.st; const u = st.battle.hand.find(x => st.cards[x].id === 'trample'); return Game.Rules.cost(st, u) === 0; }));
    await shot('09_trample_in_hand.png');
    // 짓밟힘 사용 → 물러남 → 탈출 → 종료
    const tp = await cardPos('trample');
    await drag(tp, { x: tp.x, y: 380 });
    await waitScene('ending', 60000);
    await page.waitForTimeout(2500 / 4 * 4);
    check('짓밟힘 → 존재가 물러남 → 탈출 → 종료 화면', true);
    await page.waitForSelector('[data-act=again].on', { timeout: 20000 });
    await shot('10_ending.png');

    console.log('경로 B: 카드를 쓰지 않고 버텨 전멸 → 거대 존재 등장 직후부터 재시작');
    await page.click('[data-act=again]');
    await waitScene('camp');
    await page.click('.vn-skip');
    await waitIdle();
    await ev(() => Game.debug.win());
    await page.waitForFunction(() => Game.Ctl.st.battle && Game.Ctl.st.battle.kind === 'giant', null, { timeout: 60000 });
    await waitIdle();
    const snapHp = (await state()).party;
    for (let t = 1; t <= 3; t++) {
      s = await state();
      if (t === 3) { await page.waitForTimeout(300); await shot('11_giant_turn3_taut.png'); }
      check('버티기 ' + t + '턴 (죽음 카드 보존)', s.battle.turn === t && s.battle.hand.includes('hero_death'));
      await clickEndTurn();
      if (t < 3) await waitIdle();
    }
    await waitScene('wipe', 60000);
    await page.waitForTimeout(400);
    await shot('12_wipe.png');
    check('3턴째 짓밟기로 전멸 → 전멸 화면', true);
    await page.click('[data-act=retry]');
    await waitIdle();
    s = await state();
    check('거대 존재 등장 직후(1턴)부터 재시작, HP 복원', s.battle.kind === 'giant' && s.battle.turn === 1 && s.battle.hand.includes('hero_death') &&
      s.party.witch === snapHp.witch && s.party.allies.hero.status === 'ok', 'witch ' + s.party.witch + ', hero ' + s.party.allies.hero.hp);
    await shot('13_restart.png');

    console.log('경로 C: 다른 창 크기(1280×960, 위아래 검은 여백) + 일반 전투 전멸 → 이 전투 처음부터');
    await page.setViewportSize({ width: 1280, height: 960 });
    await page.goto(URL + '&scene=normal');
    await waitIdle();
    const box = await ev(() => { const b = document.getElementById('stage').getBoundingClientRect(); return { l: b.left, t: b.top, w: b.width, h: b.height }; });
    check('비율 유지 축소 + 검은 여백', Math.abs(box.w - 1280) < 1 && Math.abs(box.h - 720) < 1 && Math.abs(box.t - 120) < 1, JSON.stringify(box));
    await playOn('holy_slash', await enemyPos('c2'));
    await waitIdle();
    s = await state();
    check('축소된 화면에서도 드래그로 카드 사용', s.battle.enemies.find(e => e.id === 'c2').alive === false);
    await shot('14_letterbox_1280x960.png');
    await ev(() => { ['hero', 'warrior', 'archer'].forEach(a => Game.debug.setHp(a, 0)); });
    await clickEndTurn();
    await waitScene('wipe', 60000);
    check('일반 전투 전멸 → 전멸 화면', true);
    await page.click('[data-act=retry]');
    await waitIdle();
    s = await state();
    check('일반 전투 처음부터 재시작 (광신도 3, 동료 HP 복원)', s.battle.kind === 'normal' && s.battle.turn === 1 && s.battle.enemies.every(e => e.alive && e.hp === 14) && s.party.allies.archer.hp === 12);
  } catch (e) {
    check('예외 없이 진행', false, e.message);
    try { await shot('99_failure.png'); console.log(JSON.stringify(await state()).slice(0, 1500)); } catch (e2) { /* 무시 */ }
  }

  const missingFiles = [...new Set(failedUrls.map(u => decodeURIComponent(u).split('/').pop()))];
  check('콘솔 에러 0 (스크립트)', errors.length === 0, errors.slice(0, 5).join(' | '));
  console.log('\n없는 그림 파일 로드 실패 로그(예상된 동작, 회색 박스로 대체): ' + missing.length + '건 — ' + missingFiles.join(', '));
  const pass = results.filter(r => r.ok).length;
  console.log('\n결과: ' + pass + ' / ' + results.length + ' 통과');
  console.log('스크린샷: ' + SHOTS);
  await browser.close();
  process.exit(pass === results.length ? 0 : 1);
})();
