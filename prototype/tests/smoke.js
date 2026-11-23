/*
 * 스모크 테스트 (Playwright + Chromium)
 *   node prototype/tests/smoke.js [스크린샷 폴더]
 *
 * 경로 A: 타이틀 → 캠프(대사 끝까지 클릭, 노엘 스탠딩 비율·표정 얼굴) → 일반 전투(실제 드래그로 성검·운명 전가·감싸기,
 *         카드 내기 손 들기·컷인·동료 공격 모션) → 거대 존재 등장(발이 동료 뒤) → 거대 존재 전투(공격 무효 확인)
 *         → 죽음 카드(들어 올린 손 + 팽팽한 실) → 컷신 C1~C6 → C7·C8(동료 표정) → 짓밟힘(컷인) → 존재가 물러남 → 탈출 → 종료 화면
 * 경로 B: 다시 하기 → 캠프 건너뛰기 → 일반 전투(디버그 즉시 승리) → 거대 존재 전투에서 카드 없이 3턴
 *         → 짓밟기로 전멸 → 다시 → 거대 존재 등장 직후(1턴)부터 재시작
 * 경로 C: 1280×960 창(검은 여백)에서 드래그 좌표 확인 → 일반 전투 전멸 → 이 전투 처음부터 재시작
 * 경로 D: 손패 0~6장 — 손 그림의 카드 자리(투명)가 비어 손이 잘려 보이지 않는지(배경을 마젠타로 바꿔 픽셀 검사) + 스크린샷
 * 경로 E: 보통 속도 연출 스크린샷 — 컷인 5종, 손 들기 중간, 동료 타격 순간
 * 경로 F: 휴대폰(가로) 터치 — iPhone 13: 캠프 탭 → 일반 전투 터치 드래그·운명 전가 2단계·예고 탭 → 거대 존재 → 죽음 카드 → 컷신 → C8
 *         Pixel 7: 터치 드래그·턴 종료 탭·누르는 영역 44px · 세로 화면 "가로로 돌려 주세요"
 * 콘솔 에러: 스크립트 에러 0 이어야 통과. 없는 그림 파일의 리소스 로드 실패 로그는 따로 집계한다.
 */
'use strict';
const { chromium, devices } = require('playwright');
const path = require('path');
const fs = require('fs');

const ROOT = path.resolve(__dirname, '..');
const BASE = 'file://' + path.join(ROOT, 'index.html');
const URL = BASE + '?seed=7&speed=4';
const SHOTS = process.argv[2] || path.join(ROOT, 'tests', 'shots');
fs.mkdirSync(SHOTS, { recursive: true });

// 손 그림(ui_witch_hands.png) 원본 좌표: 카드 자리 안쪽에서 손이 끊긴 곳 바로 안(왼손바닥·손가락 끝·오른손바닥).
// 카드가 없으면 이 점들로 배경이 보여 손이 잘려 보인다.
const HAND_CUT_PTS = [[472, 506], [476, 511], [479, 519], [482, 524], [491, 541], [494, 544], [500, 553], [503, 559], [521, 595],
  [523, 599], [527, 604], [530, 608], [532, 614], [904, 589], [908, 590], [917, 590], [924, 591], [931, 593], [1124, 613],
  [1129, 607], [1134, 599], [1139, 590], [1145, 581], [1149, 570], [1153, 564], [1157, 559], [1161, 553], [1169, 540],
  [1170, 533], [1176, 528], [1181, 518], [1188, 507]];

const results = [];
function check(name, ok, detail) {
  results.push({ name, ok: !!ok, detail });
  console.log((ok ? '  ✔ ' : '  ✘ ') + name + (detail ? ' — ' + detail : ''));
}

const errors = [], missing = [], failedUrls = [];
function watch(page, tag) {
  page.on('requestfailed', r => failedUrls.push(r.url()));
  page.on('console', m => {
    if (m.type() !== 'error') return;
    if (/Failed to load resource: net::ERR_FILE_NOT_FOUND/.test(m.text())) missing.push(m.text());
    else errors.push(tag + ': ' + m.text());
  });
  page.on('pageerror', e => errors.push(tag + ' pageerror: ' + e.message));
}

// 페이지 하나에 묶인 도우미들
function helpers(page, opts) {
  opts = opts || {};
  const H = {};
  H.shot = name => page.screenshot({ path: path.join(SHOTS, name) });
  H.ev = (fn, arg) => page.evaluate(fn, arg);
  H.state = () => H.ev(() => Game.debug.state());
  H.waitIdle = async timeout => {
    await page.waitForFunction(() => Game.Ctl.inBattle && !Game.Ctl.busy && Game.Ctl.st.battle && Game.Ctl.st.battle.phase === 'player' && !Game.Scenes.current, null, { timeout: timeout || 60000 });
    await page.waitForTimeout(150);
  };
  H.cardPos = id => H.ev(id => {
    const st = Game.Ctl.st, u = st.battle.hand.find(x => st.cards[x].id === id);
    if (!u) return null;
    const c = Game.Hand.center(u);
    return { x: c.x, y: c.y + 30 };
  }, id);
  H.enemyPos = id => H.ev(id => Game.View.enemyCenter(id), id);
  H.intentPos = id => H.ev(id => { const r = Game.View.intentRect(id); return { x: r.x + r.w / 2, y: r.y + r.h / 2 }; }, id);
  H.allyPos = id => H.ev(id => { const r = id === 'witch' ? Game.View.witchRect() : Game.View.allyHitRect(id); return { x: r.x + r.w / 2, y: r.y + r.h / 2 }; }, id);
  // 1920×1080 논리 좌표 → 창 좌표 (창 크기가 달라도 동작하는지 확인하려고 항상 변환)
  H.toPage = async p => {
    const r = await H.ev(() => { const b = document.getElementById('stage').getBoundingClientRect(); return { l: b.left, t: b.top, s: b.width / 1920 }; });
    return { x: r.l + p.x * r.s, y: r.t + p.y * r.s };
  };
  let cdp = null;
  async function touch(type, p) {
    if (!cdp) cdp = await page.context().newCDPSession(page);
    await cdp.send('Input.dispatchTouchEvent', { type, touchPoints: type === 'touchEnd' ? [] : [{ x: p.x, y: p.y, radiusX: 6, radiusY: 6, force: 1, id: 1 }] });
  }
  H.drag = async (from, to) => {
    from = await H.toPage(from); to = await H.toPage(to);
    if (opts.touch) {
      await touch('touchStart', from);
      await page.waitForTimeout(80);
      const mid = { x: (from.x + to.x) / 2, y: (from.y + to.y) / 2 + 8 };
      for (let i = 1; i <= 6; i++) await touch('touchMove', { x: from.x + (mid.x - from.x) * i / 6, y: from.y + (mid.y - from.y) * i / 6 });
      for (let i = 1; i <= 8; i++) await touch('touchMove', { x: mid.x + (to.x - mid.x) * i / 8, y: mid.y + (to.y - mid.y) * i / 8 });
      await page.waitForTimeout(60);
      await touch('touchEnd', to);
      return;
    }
    await page.mouse.move(from.x, from.y);
    await page.waitForTimeout(80);
    await page.mouse.down();
    await page.mouse.move((from.x + to.x) / 2, (from.y + to.y) / 2 + 20, { steps: 6 });
    await page.mouse.move(to.x, to.y, { steps: 8 });
    await page.waitForTimeout(60);
    await page.mouse.up();
  };
  H.tap = async p => {
    p = await H.toPage(p);
    if (opts.touch) { await touch('touchStart', p); await page.waitForTimeout(30); await touch('touchEnd', p); return; }
    await page.mouse.click(p.x, p.y);
  };
  H.moveTo = async p => { p = await H.toPage(p); await page.mouse.move(p.x, p.y); };
  H.playOn = async (cardId, to) => {
    const p = await H.cardPos(cardId);
    if (!p) throw new Error('손패에 없음: ' + cardId);
    await H.drag(p, to);
  };
  H.endTurnPos = () => H.ev(() => { const e = document.getElementById('endTurn'); return { x: e.offsetLeft + e.offsetWidth / 2, y: e.offsetTop + e.offsetHeight / 2 }; });
  H.clickEndTurn = async () => H.tap(await H.endTurnPos());
  H.waitScene = (name, timeout) => page.waitForFunction(n => Game.Scenes.current === n, name, { timeout: timeout || 60000 });
  return H;
}

// (페이지 안에서 실행) 요소를 가운데로 가로·세로로 1px씩 훑어, 그 요소가 눌리는 길이(실제 화면 px)를 잰다
function touchSpan(sel) {
  const e = document.querySelector(sel), r = e.getBoundingClientRect(), cx = r.left + r.width / 2, cy = r.top + r.height / 2;
  const hit = (x, y) => { const el = document.elementFromPoint(x, y); return !!el && (el === e || e.contains(el)); };
  function span(dx, dy) { let n = 0; for (let d = 1; d < 200; d++) { if (!hit(cx + dx * d, cy + dy * d)) break; n++; } return n; }
  return { w: span(-1, 0) + span(1, 0) + 1, h: span(0, -1) + span(0, 1) + 1, visibleH: Math.round(r.height), visibleW: Math.round(r.width) };
}

// 손 그림의 잘린 자리가 보이는지: 배경·동료·적·실·피를 숨기고 바탕을 마젠타로 → 잘린 점들의 픽셀이 마젠타면 구멍
async function handHoles(page, H) {
  await H.ev(() => {
    document.body.classList.add('test-magenta');
    ['bgLayer', 'enemyLayer', 'allyLayer', 'shadowLayer', 'threadCanvas', 'bloodCanvas', 'hudLayer'].forEach(id => { document.getElementById(id).style.visibility = 'hidden'; });
    document.getElementById('world').style.background = '#ff00ff';
  });
  await page.waitForTimeout(60);
  const png = await page.screenshot({ type: 'png' });
  await H.ev(() => {
    ['bgLayer', 'enemyLayer', 'allyLayer', 'shadowLayer', 'threadCanvas', 'bloodCanvas', 'hudLayer'].forEach(id => { document.getElementById(id).style.visibility = ''; });
    document.getElementById('world').style.background = '';
  });
  return H.ev(async ({ b64, pts }) => {
    const img = new Image();
    img.src = 'data:image/png;base64,' + b64;
    await img.decode();
    const cv = document.createElement('canvas'); cv.width = img.width; cv.height = img.height;
    const cx = cv.getContext('2d'); cx.drawImage(img, 0, 0);
    const st = document.getElementById('stage').getBoundingClientRect(), s = st.width / 1920, k = img.width / window.innerWidth;
    const hl = Game.DATA.layout.hand, bad = [];
    pts.forEach(p => {
      const x = (st.left + (hl.x + p[0] * hl.scale) * s) * k, y = (st.top + (hl.y + Game.Hand.dy + p[1] * hl.scale) * s) * k;
      const d = cx.getImageData(Math.round(x), Math.round(y), 1, 1).data;
      if (d[0] > 200 && d[1] < 80 && d[2] > 200) bad.push(p.join(','));
    });
    return bad;
  }, { b64: png.toString('base64'), pts: HAND_CUT_PTS });
}

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 1 });
  watch(page, 'pc');
  const H = helpers(page);
  const { ev, state, shot } = H;
  let s;

  try {
    console.log('경로 A: 캠프 → 일반 전투 → 거대 존재 → 죽음 카드 → 컷신 → 짓밟힘 → 종료');
    await page.goto(URL);
    await H.waitScene('title', 20000);
    await shot('00_title.png');
    // data.js 의 손 들기 카드 자리가 json 원본과 같은지
    const rq = JSON.parse(fs.readFileSync(path.join(ROOT, 'assets', 'ui_witch_hand_raise.json'), 'utf8')).card_quad_tl_tr_br_bl;
    check('손 들기 카드 자리 = ui_witch_hand_raise.json', JSON.stringify(await ev(() => Game.DATA.layout.raise.quad)) === JSON.stringify(rq));
    await page.click('[data-act=start]');
    await H.waitScene('camp');
    // 캠프: 끝까지 클릭으로 진행
    let lines = 0, ratioOk = null, faceSeen = {};
    for (let i = 0; i < 400; i++) {
      const sc = await ev(() => Game.Scenes.current);
      if (sc !== 'camp') break;
      const ln = await ev(() => +(document.querySelector('[data-scene=camp]') || { getAttribute: () => -1 }).getAttribute('data-line'));
      if (ln === 9 && ratioOk == null) {
        // 노엘이 처음 나오는 대사: 스탠딩 4명 모두 그림 원래 비율인지
        await page.waitForTimeout(700);
        const r = await ev(() => Array.from(document.querySelectorAll('.stand')).map(st => {
          const img = st.querySelector('img'), b = img.getBoundingClientRect(), sb = st.getBoundingClientRect();
          return { k: st.dataset.char, ratio: b.width / b.height, nat: img.naturalWidth / img.naturalHeight, box: sb.width / sb.height };
        }));
        ratioOk = r.every(x => Math.abs(x.ratio - x.nat) / x.nat < 0.01 && Math.abs(x.box - x.nat) / x.nat < 0.01);
        check('캠프 스탠딩 4명 그림 원래 비율 유지(노엘 577×1505 포함)', ratioOk, r.map(x => x.k + ' ' + x.ratio.toFixed(3) + '/' + x.nat.toFixed(3)).join(', '));
        await shot('01_camp_noel_first.png');
      }
      if (ln === 25 && !faceSeen.shot) { await page.waitForTimeout(500); await shot('01b_camp_face_archer_shocked.png'); faceSeen.shot = 1; }
      const f = await ev(() => { const e = document.querySelector('.vn-box.has-face .vn-face'); return e ? e.getAttribute('data-face-img') : null; });
      if (f) faceSeen[f] = 1;
      lines = Math.max(lines, ln + 1);
      await H.tap({ x: 960, y: 900 });
      await page.waitForTimeout(45);
    }
    check('캠프 대화를 끝까지 진행', lines >= 40, lines + '줄');
    check('캠프 대화창 큰 얼굴에 표정 그림', ['face_hero_smile.png', 'face_archer_shocked.png', 'face_warrior_stern.png'].every(k => faceSeen[k]), Object.keys(faceSeen).filter(k => k.endsWith('.png')).join(', '));

    await H.waitIdle();
    s = await state();
    check('일반 전투 시작: 광신도 3, 에너지 3, 손패 5', s.battle.kind === 'normal' && s.battle.enemies.length === 3 && s.battle.energy === 3 && s.battle.hand.length === 5, JSON.stringify(s.battle.hand));
    await shot('02_battle_normal.png');
    // 대기 중 숨쉬기(동료마다 위상이 다름)
    const br = await ev(() => ['archer', 'hero', 'warrior'].map(id => { const p = document.querySelector('[data-ally=' + id + '] .pose'); return getComputedStyle(p).animationName + ' ' + getComputedStyle(p).animationDelay; }));
    check('동료 대기 숨쉬기(위상 다르게)', br.every(x => x.startsWith('breathe')) && new Set(br).size === 3, br.join(' | '));

    // 1턴: 성검 베기(드래그) → 광신도 B 일격 — 손 들기·컷인·세라피나 공격 자세
    await ev(() => { Game.Hand.raiseLog.length = 0; Game.Cutin.log.length = 0; Game.Motion.log.length = 0; });
    await H.playOn('holy_slash', await H.enemyPos('c2'));
    await H.waitIdle();
    s = await state();
    check('성검 베기로 광신도를 일격에 쓰러뜨림 (드래그)', s.battle.enemies.find(e => e.id === 'c2').alive === false && s.battle.energy === 2);
    const lg = await ev(() => ({ raise: Game.Hand.raiseLog.slice(), cutin: Game.Cutin.log.slice(), motion: Game.Motion.log.slice() }));
    check('카드 내기: 손 들기 → 컷인(성검 베기) → 세라피나 공격 자세', lg.raise[0] === 'holy_slash' && lg.cutin[0] === 'holy_slash' && lg.motion[0] === 'hero:attack', JSON.stringify(lg));
    // 무효 위치에 놓으면 손으로 돌아감
    const before = (await state()).battle.hand.length;
    await H.drag(await H.cardPos('curse_flame'), { x: 120, y: 700 });
    await page.waitForTimeout(300);
    s = await state();
    check('무효 위치에 놓으면 카드가 손패로 돌아감', s.battle.hand.length === before && s.battle.energy === 2);
    await H.playOn('curse_flame', await H.enemyPos('c1'));
    await H.waitIdle();
    check('저주의 불꽃 컷인(노엘 일반 시전)', (await ev(() => Game.Cutin.log.slice())).includes('curse_flame'));
    // 예고에 마우스를 올리면 선
    const ip = await H.intentPos('c3');
    await H.moveTo(ip);
    await page.waitForTimeout(400);
    check('예고에 마우스를 올리면 대상 표시', await ev(() => Game.Input.hoverIntent === 'c3'));
    await shot('03_intent_hover.png');
    await H.clickEndTurn();
    await H.waitIdle();
    s = await state();
    check('2턴 시작, 튜토리얼 손패(운명 전가·감싸기 포함)', s.battle.turn === 2 && s.battle.hand.includes('fate_shift') && s.battle.hand.includes('cover'), JSON.stringify(s.battle.hand));

    // 2턴: 운명 전가 ① 예고에 놓기 → ② 전사 클릭
    const tgtBefore = s.battle.enemies.find(e => e.id === 'c3').intent.target;
    await H.playOn('fate_shift', await H.intentPos('c3'));
    await page.waitForTimeout(300);
    check('운명 전가 ①단계 후 아군 선택 대기', await ev(() => Game.Input.mode === 'pick'));
    await shot('04_fate_shift_pick.png');
    await H.tap(await H.allyPos('warrior'));
    await H.waitIdle();
    s = await state();
    check('운명 전가: 예고 대상이 바뀜 (' + tgtBefore + ' → warrior)', s.battle.enemies.find(e => e.id === 'c3').intent.target === 'warrior');
    await H.playOn('cover', await H.intentPos('c1'));
    await H.waitIdle();
    s = await state();
    const c1i = s.battle.enemies.find(e => e.id === 'c1').intent;
    check('감싸기: 전사가 받되 절반 (컷인·방패 자세)', c1i.target === 'warrior' && c1i.halve === true && (await ev(() => Game.Cutin.log.includes('cover') && Game.Motion.log.includes('warrior:guard'))));
    // 성검 베기 → 1명 남음 → 거대 존재 등장
    await H.playOn('holy_slash', await H.enemyPos('c3'));
    await page.waitForFunction(() => Game.Ctl.st.battle && Game.Ctl.st.battle.kind === 'giant', null, { timeout: 60000 });
    check('광신도 1명 남자 거대 존재가 짓밟고 전투 전환', true);
    await H.waitIdle();
    s = await state();
    check('거대 존재 1턴: 손패에 죽음 카드 + 4장', s.battle.hand.length === 5 && s.battle.hand.filter(x => x === 'hero_death').length === 1, JSON.stringify(s.battle.hand));
    // 발은 동료 뒤: 세라피나(그림·HP판)가 발 위에 그려진다
    const z = await ev(() => {
      const foot = document.querySelector('.enemy.giant'), hero = document.querySelector('[data-ally=hero]'), hp = document.querySelector('.hp-ally');
      const fz = +getComputedStyle(foot).zIndex, hz = +getComputedStyle(hero).zIndex;
      const sameCtx = foot.parentElement.parentElement === hero.parentElement.parentElement;
      // 세라피나 머리 근처 점에서 위에 있는 요소 순서
      const st = document.getElementById('stage').getBoundingClientRect(), s = st.width / 1920;
      const a = Game.View.allyAnchor('hero'), fr = foot.getBoundingClientRect();
      const px = st.left + a.x * s, py = st.top + (a.y - 30) * s;
      const stack = document.elementsFromPoint(px, py);
      const iHero = stack.findIndex(e => hero.contains(e)), iFoot = stack.findIndex(e => foot.contains(e));
      const overlap = py >= fr.top && py <= fr.bottom;
      const shade = document.querySelector('[data-ally=hero] .body img.shade');
      return { fz, hz, sameCtx, iHero, iFoot, overlap, shadeOp: +getComputedStyle(shade).opacity, shadowZ: +getComputedStyle(document.getElementById('shadowLayer')).zIndex, hpZ: +getComputedStyle(document.querySelector('.hp-ally')).zIndex };
    });
    check('거대한 발이 세라피나 뒤(z-order): 발 z < 동료 z, 겹치는 점에서 세라피나가 위', z.sameCtx && z.fz < z.hz && z.overlap && z.iHero >= 0 && z.iFoot >= 0 && z.iHero < z.iFoot && z.hpZ > z.fz, JSON.stringify(z));
    check('발 그림자(위쪽 어둠)는 동료 위에 계속 드리움', z.shadeOp > 0.5 && z.shadowZ < z.fz, 'shade ' + z.shadeOp + ', shadowLayer z ' + z.shadowZ);
    await shot('05_giant_turn1_foot_behind.png');
    // 공격 무효
    const atk = ['curse_flame', 'snipe', 'shield_bash', 'suppress', 'holy_slash'].find(id => s.battle.hand.includes(id));
    if (atk) {
      await H.playOn(atk, await H.enemyPos('giant'));
      await H.waitIdle();
      s = await state();
      check('거대 존재에 공격 → 무효 (' + atk + ')', s.battle.enemies[0].alive === true && s.battle.enemies[0].hp === null);
    } else check('거대 존재에 공격 → 무효', false, '손패에 공격 카드 없음');
    // 1턴 종료 (그림자) → 2턴
    await H.clickEndTurn();
    await H.waitIdle();
    s = await state();
    check('카운트다운 2턴: 기둥 붕괴 예고, 죽음 카드 보존', s.battle.turn === 2 && s.battle.enemies[0].intent.kind === 'aoe' && s.battle.hand.includes('hero_death'));
    await shot('06_giant_turn2_thread.png');

    // 죽음 카드 사용 (위로 끌어올림, 에너지와 무관) → 손을 들어 올린 채 떨림 + 실이 최대로 팽팽
    const dp = await H.cardPos('hero_death');
    await H.drag(dp, { x: dp.x + 10, y: 360 });
    await page.waitForFunction(() => Game.Hand.raised && Game.View.vm.pull === 2, null, { timeout: 20000 });
    await page.waitForTimeout(120);
    const dr = await ev(() => ({ id: Game.Ctl.st.cards[Game.Hand.raised.uid].id, pull: Game.View.vm.pull, tremble: !!Game.Hand.trembleAnim, rig: getComputedStyle(document.getElementById('raiseRig')).opacity }));
    check('죽음 카드: 오른손이 들어 올린 채 떨림, 붉은 실 최대 팽팽', dr.id === 'hero_death' && dr.pull === 2 && dr.tremble && +dr.rig > 0.9, JSON.stringify(dr));
    await shot('07a_death_card_raised.png');
    await page.waitForFunction(() => document.querySelector('[data-cut]'), null, { timeout: 20000 });
    const cuts = {};
    for (let i = 0; i < 600; i++) {
      const c = await ev(() => { const e = document.querySelector('[data-cut]'); return e ? e.getAttribute('data-cut') : null; });
      if (!c) { if (Object.keys(cuts).length) break; }
      else if (!cuts[c]) {
        cuts[c] = 1;
        if (c === 'C6') await ev(() => { Game.FX.speed = 1; });   // C6 → C7·C8 은 보통 속도로 보고 찍는다
        await page.waitForTimeout(c === 'C3' ? 250 : c === 'C5' ? 700 : c === 'C6' ? 1200 : 300);
        await shot('07_cut_' + c + '.png');
      }
      await page.waitForTimeout(40);
    }
    const cutLog = await ev(() => Game.Scenes.cutLog || []);
    check('컷신 C1~C6 모두 재생', ['C1', 'C2', 'C3', 'C4', 'C5', 'C6'].every(c => cutLog.includes(c)), cutLog.join(',') + ' (캡처: ' + Object.keys(cuts).join(',') + ')');
    await page.waitForTimeout(900);
    await shot('08_after_death_C7.png');
    // C8: 엘리안 놀람 → 슬픔 → 텅 빔, 브룬힐드 놀람 → 슬픔
    const c8 = [];
    for (let i = 0; i < 400; i++) {
      const f = await ev(() => { const d = document.getElementById('dialog'); if (d.classList.contains('hidden')) return null; const e = d.querySelector('.dlg-face'); return (d.querySelector('.dlg-name').textContent) + '|' + (e.getAttribute('data-face-img') || ''); });
      if (f && !c8.includes(f)) { c8.push(f); await shot('08b_C8_' + (c8.length) + '.png'); }
      if (await ev(() => !Game.Ctl.busy)) break;
      if (c8.length >= 5) await ev(() => { Game.FX.speed = 4; });
      await page.waitForTimeout(30);
    }
    await ev(() => { Game.FX.speed = 4; });
    const c8f = c8.map(x => x.split('|')[1]);
    check('C8 동료 반응 표정 (엘리안 shocked→grief→hollow, 브룬힐드 shocked→grief)',
      ['face_archer_shocked.png', 'face_archer_grief.png', 'face_archer_hollow.png', 'face_warrior_shocked.png', 'face_warrior_grief.png'].every(k => c8f.includes(k)), c8.join(', '));
    await H.waitIdle(60000);
    s = await state();
    check('용사 사망, 유품 3장, 짓밟힘(이번 턴 비용 0) 손패에', s.party.allies.hero.status === 'dead' &&
      s.party.deck.filter(x => x === 'broken_sword' || x === 'last_charge').length === 3 && s.battle.hand.includes('trample') &&
      await ev(() => { const st = Game.Ctl.st; const u = st.battle.hand.find(x => st.cards[x].id === 'trample'); return Game.Rules.cost(st, u) === 0; }));
    await shot('09_trample_in_hand.png');
    // 짓밟힘 사용 → (무거운 컷인) → 물러남 → 탈출 → 종료
    const tp = await H.cardPos('trample');
    await H.drag(tp, { x: tp.x, y: 380 });
    await H.waitScene('ending', 60000);
    check('짓밟힘 → 상속 컷인 → 존재가 물러남 → 탈출 → 종료 화면', (await ev(() => Game.Cutin.log.includes('trample'))));
    await page.waitForSelector('[data-act=again].on', { timeout: 20000 });
    await shot('10_ending.png');

    console.log('경로 B: 카드를 쓰지 않고 버텨 전멸 → 거대 존재 등장 직후부터 재시작');
    await page.click('[data-act=again]');
    await H.waitScene('camp');
    await page.click('.vn-skip');
    await H.waitIdle();
    await ev(() => Game.debug.win());
    await page.waitForFunction(() => Game.Ctl.st.battle && Game.Ctl.st.battle.kind === 'giant', null, { timeout: 60000 });
    await H.waitIdle();
    const snapHp = (await state()).party;
    for (let t = 1; t <= 3; t++) {
      s = await state();
      if (t === 3) { await page.waitForTimeout(300); await shot('11_giant_turn3_taut.png'); }
      check('버티기 ' + t + '턴 (죽음 카드 보존)', s.battle.turn === t && s.battle.hand.includes('hero_death'));
      await H.clickEndTurn();
      if (t < 3) await H.waitIdle();
    }
    await H.waitScene('wipe', 60000);
    await page.waitForTimeout(400);
    await shot('12_wipe.png');
    check('3턴째 짓밟기로 전멸 → 전멸 화면', true);
    await page.click('[data-act=retry]');
    await H.waitIdle();
    s = await state();
    check('거대 존재 등장 직후(1턴)부터 재시작, HP 복원', s.battle.kind === 'giant' && s.battle.turn === 1 && s.battle.hand.includes('hero_death') &&
      s.party.witch === snapHp.witch && s.party.allies.hero.status === 'ok', 'witch ' + s.party.witch + ', hero ' + s.party.allies.hero.hp);
    await shot('13_restart.png');

    console.log('경로 C: 다른 창 크기(1280×960, 위아래 검은 여백) + 일반 전투 전멸 → 이 전투 처음부터');
    await page.setViewportSize({ width: 1280, height: 960 });
    await page.goto(URL + '&scene=normal');
    await H.waitIdle();
    const box = await ev(() => { const b = document.getElementById('stage').getBoundingClientRect(); return { l: b.left, t: b.top, w: b.width, h: b.height }; });
    check('비율 유지 축소 + 검은 여백', Math.abs(box.w - 1280) < 1 && Math.abs(box.h - 720) < 1 && Math.abs(box.t - 120) < 1, JSON.stringify(box));
    await H.playOn('holy_slash', await H.enemyPos('c2'));
    await H.waitIdle();
    s = await state();
    check('축소된 화면에서도 드래그로 카드 사용', s.battle.enemies.find(e => e.id === 'c2').alive === false);
    await shot('14_letterbox_1280x960.png');
    await ev(() => { ['hero', 'warrior', 'archer'].forEach(a => Game.debug.setHp(a, 0)); });
    await H.clickEndTurn();
    await H.waitScene('wipe', 60000);
    check('일반 전투 전멸 → 전멸 화면', true);
    await page.click('[data-act=retry]');
    await H.waitIdle();
    s = await state();
    check('일반 전투 처음부터 재시작 (광신도 3, 동료 HP 복원)', s.battle.kind === 'normal' && s.battle.turn === 1 && s.battle.enemies.every(e => e.alive && e.hp === 14) && s.party.allies.archer.hp === 12);

    console.log('경로 D: 손패 0~6장 — 손 그림이 잘려 보이지 않는지');
    await page.setViewportSize({ width: 1920, height: 1080 });
    await page.goto(URL + '&scene=normal');
    await H.waitIdle();
    await ev(() => Game.Dialog.clear());
    const holes = {};
    for (let n = 0; n <= 6; n++) {
      await ev(n => Game.debug.setHandSize(n), n);
      await page.waitForTimeout(450);
      const cnt = await ev(() => Game.Ctl.st.battle.hand.length);
      holes[n] = await handHoles(page, H);
      await shot('20_hand_' + n + '.png');
      if (cnt !== n) holes[n] = ['손패 ' + cnt + '장'];
    }
    // 대조: 뒷면 카드를 숨기면 0장일 때 구멍이 보여야 검사가 의미 있다
    await ev(() => Game.debug.setHandSize(0));
    await ev(() => document.querySelectorAll('.card-back').forEach(b => { b.style.visibility = 'hidden'; }));
    await page.waitForTimeout(300);
    const ctrl = await handHoles(page, H);
    await ev(() => document.querySelectorAll('.card-back').forEach(b => { b.style.visibility = ''; }));
    check('검사 대조: 덮개가 없으면 잘린 자리가 보인다', ctrl.length > HAND_CUT_PTS.length * 0.8, ctrl.length + '/' + HAND_CUT_PTS.length + '점');
    for (let n = 0; n <= 6; n++) check('손패 ' + n + '장: 손 그림에 잘린 자국 없음', holes[n].length === 0, holes[n].length ? holes[n].slice(0, 6).join(' ') : '');

    console.log('경로 E: 보통 속도 연출 스크린샷 (컷인 5종, 손 들기 중간, 동료 타격)');
    await page.goto(BASE + '?seed=7&speed=1&scene=normal');
    await H.waitIdle();
    await ev(() => Game.Dialog.clear());
    for (const id of ['holy_slash', 'snipe', 'cover', 'curse_flame', 'trample']) {
      const dur = await ev(id => { window.__ci = false; Game.Cutin.play(id).then(() => { window.__ci = true; }); const c = Game.DATA.cutin; return c.cards[id].heavy ? c.heavyDuration : c.duration; }, id);
      await page.waitForTimeout(Math.round(dur * 0.42));
      const shown = await ev(id => !!document.querySelector('.cutin[data-cutin=' + id + '] .ci-char'), id);
      await shot('30_cutin_' + id + '.png');
      await page.waitForFunction(() => window.__ci, null, { timeout: 5000 });
      check('컷인 표시: ' + id, shown);
    }
    // 클릭하면 건너뜀
    const skip = await ev(async () => { const t0 = performance.now(); const p = Game.Cutin.play('snipe'); await new Promise(r => setTimeout(r, 60)); document.querySelector('.cutin').dispatchEvent(new PointerEvent('pointerdown', { bubbles: true })); await p; return performance.now() - t0; });
    check('컷인은 클릭하면 건너뜀', skip < 300, Math.round(skip) + 'ms');
    // 손 들기 중간 (대상 없는 카드: 죽음의 예지 — 컷인 없음)
    await ev(() => { const st = Game.Ctl.st; const u = st.battle.hand.find(x => st.cards[x].id === 'foresight'); Game.Ctl.playCard(u, {}); });
    await page.waitForTimeout(130);
    const mid = await ev(() => ({ raised: !!Game.Hand.raised, dy: Game.Hand.dy, rig: +getComputedStyle(document.getElementById('raiseRig')).opacity }));
    await shot('31_raise_mid.png');
    check('카드 내기 모션: 부채꼴 손이 내려가고 오른손이 카드를 세워 듦', mid.raised && mid.dy > 0 && mid.rig > 0.9, JSON.stringify(mid));
    await H.waitIdle();
    // 동료 타격 순간 (저격: 엘리안)
    await ev(() => Game.debug.addCard('snipe'));
    await H.waitIdle();
    await ev(() => { window.__hit = false; const st = Game.Ctl.st; const u = st.battle.hand.find(x => st.cards[x].id === 'snipe'); const f = Game.Motion.strike; Game.Motion.strike = function () { const r = f.apply(this, arguments); r.hit.then(() => { window.__hit = true; }); Game.Motion.strike = f; return r; }; Game.Ctl.playCard(u, { enemy: 'c3' }); });
    await page.waitForFunction(() => window.__hit, null, { timeout: 10000 });
    await shot('32_strike_archer.png');
    await H.waitIdle();
    await ev(() => Game.debug.addCard('holy_slash'));
    await H.waitIdle();
    // 세라피나: 녹임 중간과 타격 순간을 찍으려고 타격 모션만 1/4 속도로 (컷인은 생략)
    await ev(() => { window.__cutinPlay = Game.Cutin.play; Game.Cutin.play = () => Promise.resolve(); });
    await ev(() => { window.__hit = false; const st = Game.Ctl.st; const u = st.battle.hand.find(x => st.cards[x].id === 'holy_slash'); const f = Game.Motion.strike; Game.Motion.strike = function () { Game.FX.speed = 0.25; const r = f.apply(this, arguments); setTimeout(() => { window.__mid = true; }, 850); r.hit.then(() => { window.__hit = true; Game.FX.speed = 1; }); Game.Motion.strike = f; return r; }; Game.Ctl.playCard(u, { enemy: 'c2' }); });
    const pauseShot = async name => {
      await ev(() => { window.__paused = document.getAnimations().filter(a => a.playState === 'running'); window.__paused.forEach(a => a.pause()); });
      await shot(name);
      await ev(() => { window.__paused.forEach(a => a.play()); });
    };
    await page.waitForFunction(() => window.__mid, null, { timeout: 10000 });
    await pauseShot('33_strike_hero_blend.png');
    await page.waitForFunction(() => window.__hit, null, { timeout: 10000 });
    await pauseShot('34_strike_hero_hit.png');
    await H.waitIdle();
    await ev(() => { Game.Cutin.play = window.__cutinPlay; });
    // 적의 돌진 + 맞는 동료 흔들림 (스크린샷이 늦지 않게 잠깐 느리게)
    await ev(() => { window.__lunge = false; const f = Game.Motion.enemyLunge; Game.Motion.enemyLunge = function (el) { Game.FX.speed = 0.1; const r = f.apply(this, arguments); r.hit.then(() => { window.__lunge = true; }); Game.Motion.enemyLunge = f; return r; }; });
    await H.clickEndTurn();
    await page.waitForFunction(() => window.__lunge, null, { timeout: 20000 });
    // 스크린샷이 1초 가까이 걸려 그동안 움직임이 끝나므로, 찍는 동안만 애니메이션을 멈춘다
    await ev(() => { window.__paused = document.getAnimations().filter(a => a.playState === 'running'); window.__paused.forEach(a => a.pause()); });
    await shot('35_enemy_lunge_hurt.png');
    await ev(() => { window.__paused.forEach(a => a.play()); });
    await ev(() => { Game.FX.speed = 1; });
    await H.waitIdle();
  } catch (e) {
    check('예외 없이 진행 (PC)', false, e.message);
    try { await shot('99_failure.png'); console.log(JSON.stringify(await state()).slice(0, 1500)); } catch (e2) { /* 무시 */ }
  }
  await page.close();

  // ───────── 경로 F: 휴대폰 ─────────
  for (const devName of ['iPhone 13 landscape', 'Pixel 7 landscape']) {
    console.log('경로 F: 휴대폰 터치 — ' + devName);
    const ctx = await browser.newContext({ ...devices[devName] });
    const mp = await ctx.newPage();
    watch(mp, devName);
    const M = helpers(mp, { touch: true });
    const tag = devName.startsWith('iPhone') ? 'iphone' : 'pixel';
    try {
      if (tag === 'iphone') {
        await mp.goto(URL);
        await M.waitScene('title', 20000);
        const env = await M.ev(() => ({ touch: document.body.classList.contains('touch'), k: Game.FX.canvasK, cw: document.getElementById('fxCanvas').width, s: Game.stageScale }));
        check('[' + tag + '] 터치 기기 인식 + 캔버스 해상도 낮춤', env.touch && env.k < 1 && env.cw < 1920, JSON.stringify(env));
        await M.shot('40_' + tag + '_title.png');
        const tb = await M.ev(touchSpan, '[data-act=start]');
        check('[' + tag + '] 시작 버튼 누르는 영역 ≥ 44px', tb.w >= 44 && tb.h >= 44, JSON.stringify(tb));
        await M.tap(await M.ev(() => { const b = document.querySelector('[data-act=start]'); const st = document.getElementById('stage').getBoundingClientRect(), s = st.width / 1920, r = b.getBoundingClientRect(); return { x: (r.left + r.width / 2 - st.left) / s, y: (r.top + r.height / 2 - st.top) / s }; }));
        await M.waitScene('camp');
        const sk = await M.ev(touchSpan, '.vn-skip');
        check('[' + tag + '] 캠프 건너뛰기 누르는 영역 ≥ 44px', sk.w >= 44 && sk.h >= 44, JSON.stringify(sk));
        let n = 0;
        for (let i = 0; i < 300 && (await M.ev(() => Game.Scenes.current)) === 'camp'; i++) {
          if (i === 22) await M.shot('41_' + tag + '_camp.png');
          await M.tap({ x: 960, y: 600 }); n++;
          await mp.waitForTimeout(40);
        }
        check('[' + tag + '] 캠프 대화를 탭으로 끝까지', (await M.ev(() => Game.Scenes.current)) !== 'camp', n + '번 탭');
        await M.waitIdle();
        await M.shot('42_' + tag + '_battle.png');
        // 누르고 있으면 확대 (끌지 않음)
        const hp = await M.cardPos('foresight');
        const pp = await M.toPage(hp);
        const cdp = await ctx.newCDPSession(mp);
        await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: pp.x, y: pp.y, id: 1 }] });
        await mp.waitForTimeout(250);
        const lifted = await M.ev(() => !!Game.Hand.liftedUid && Game.Ctl.st.cards[Game.Hand.liftedUid].id);
        await M.shot('43_' + tag + '_hold_preview.png');
        await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
        await mp.waitForTimeout(200);
        check('[' + tag + '] 카드를 누르고 있으면 확대, 떼면 손패로', lifted === 'foresight' && (await M.ev(() => !Game.Hand.liftedUid && Game.Input.mode === 'idle')), String(lifted));
        await M.playOn('holy_slash', await M.enemyPos('c2'));
        await M.waitIdle();
        let ms = await M.state();
        check('[' + tag + '] 터치 드래그로 성검 베기', ms.battle.enemies.find(e => e.id === 'c2').alive === false && ms.battle.energy === 2);
        // 예고 탭 → 대상 선
        await M.tap(await M.intentPos('c3'));
        await mp.waitForTimeout(200);
        check('[' + tag + '] 예고를 탭하면 대상 선', await M.ev(() => Game.Input.hoverIntent === 'c3'));
        await M.shot('44_' + tag + '_intent_tap.png');
        await M.tap({ x: 960, y: 560 });
        await M.clickEndTurn();
        await M.waitIdle();
        // 운명 전가: 예고에 놓기 → 아군 탭
        await M.playOn('fate_shift', await M.intentPos('c3'));
        await mp.waitForTimeout(300);
        const pick = await M.ev(() => Game.Input.mode === 'pick');
        await M.tap(await M.allyPos('warrior'));
        await M.waitIdle();
        ms = await M.state();
        check('[' + tag + '] 운명 전가 2단계(예고에 놓기 → 아군 탭)', pick && ms.battle.enemies.find(e => e.id === 'c3').intent.target === 'warrior');
        await M.ev(() => Game.debug.win());
        await mp.waitForFunction(() => Game.Ctl.st.battle && Game.Ctl.st.battle.kind === 'giant', null, { timeout: 60000 });
        await M.waitIdle();
        await M.shot('45_' + tag + '_giant.png');
        const dp2 = await M.cardPos('hero_death');
        await M.drag(dp2, { x: dp2.x, y: 360 });
        await mp.waitForFunction(() => Game.Hand.raised && Game.View.vm.pull === 2, null, { timeout: 20000 });
        await M.shot('46_' + tag + '_death_raised.png');
        await mp.waitForFunction(() => document.querySelector('[data-cut]'), null, { timeout: 20000 });
        let taps = 0;
        while ((await M.ev(() => !!document.querySelector('[data-cut]'))) && taps < 60) { await M.tap({ x: 960, y: 540 }); taps++; await mp.waitForTimeout(250); }
        check('[' + tag + '] 컷신을 탭으로 넘김', (await M.ev(() => (Game.Scenes.cutLog || []).length)) === 6, taps + '번 탭');
        await mp.waitForFunction(() => !document.getElementById('dialog').classList.contains('hidden'), null, { timeout: 20000 });
        await M.shot('47_' + tag + '_C8.png');
        await M.waitIdle(60000);
        ms = await M.state();
        check('[' + tag + '] 죽음 카드 → 컷신 → C8 → 짓밟힘 손패', ms.party.allies.hero.status === 'dead' && ms.battle.hand.includes('trample'));
      } else {
        await mp.goto(URL + '&scene=normal');
        await M.waitIdle();
        await M.shot('50_' + tag + '_battle.png');
        // 누르는 영역: 실제 화면에서 턴 종료 버튼을 가운데로 가로·세로로 훑어 버튼이 잡히는 길이가 44px 이상
        const tt = await M.ev(touchSpan, '#endTurn');
        check('[' + tag + '] 턴 종료 버튼 누르는 영역 ≥ 44px', tt.w >= 44 && tt.h >= 44, JSON.stringify(tt));
        await M.playOn('curse_flame', await M.enemyPos('c1'));
        await M.waitIdle();
        let ms = await M.state();
        check('[' + tag + '] 터치 드래그로 저주의 불꽃', ms.battle.energy === 2 && ms.battle.enemies.find(e => e.id === 'c1').hp < 14);
        // 대상 없는 카드(죽음의 예지)를 위로 끌어올려 사용
        await M.playOn('foresight', { x: 960, y: 380 });
        await M.waitIdle();
        ms = await M.state();
        check('[' + tag + '] 대상 없는 카드를 위로 끌어올려 사용', ms.battle.energy === 1);
        await M.clickEndTurn();
        await M.waitIdle();
        ms = await M.state();
        check('[' + tag + '] 턴 종료 탭 → 2턴', ms.battle.turn === 2);
        // 디버그 패널: 오른쪽 위 구석 3번 탭
        for (let i = 0; i < 3; i++) { await M.tap({ x: 1880, y: 40 }); await mp.waitForTimeout(80); }
        check('[' + tag + '] 오른쪽 위 구석 3번 탭 → 디버그 패널', await M.ev(() => !document.getElementById('debugPanel').classList.contains('hidden')));
        await M.shot('51_' + tag + '_debug.png');
        // 세로 화면
        await mp.setViewportSize({ width: 412, height: 839 });
        await mp.waitForTimeout(300);
        const rot = await M.ev(() => getComputedStyle(document.getElementById('rotateHint')).display);
        await M.shot('52_' + tag + '_portrait.png');
        check('[' + tag + '] 세로 화면 → "가로로 돌려 주세요"', rot === 'flex', rot);
      }
    } catch (e) {
      check('[' + tag + '] 예외 없이 진행', false, e.message);
      try { await M.shot('99_' + tag + '_failure.png'); } catch (e2) { /* 무시 */ }
    }
    await ctx.close();
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
