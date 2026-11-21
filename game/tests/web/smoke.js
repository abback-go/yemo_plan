/*
 * 웹 빌드 스모크 테스트 (Playwright + Chromium) — Godot 판 "죽음을 보는 마녀" 버티컬 슬라이스 (장례 탑 1층 + 2·3층)
 *   node game/tests/web/smoke.js <웹 빌드 주소, 예: http://localhost:8000/> <스크린샷 폴더> [경로들, 예: AB]
 *
 * Godot 캔버스에는 DOM 이 없으므로 게임이 ?test=1 일 때 붙이는 window.witch 훅(core/test_api.gd)으로 상태를 읽고 장면을 옮긴다.
 * 중요한 조작(카드 끌기·뒤집힌 카드·지도의 방·카드 고르기(거래·훈련)·선택지·턴 종료·운명 선택)은 좌표로 실제 마우스·터치 입력을 보낸다.
 * 화면은 PC 1920×1080 기준(창 1280×720, deviceScaleFactor 1). 휴대폰은 돌아가게만(경로 D·F).
 *
 * 경로 A: 타이틀(실제 클릭) → 곁방(파티 소개 이름표) → 장례 회랑 VN → 전투 ①(뒤집힌 카드를 끌어도 못 냄, 성검 베기 조준·취소·드래그, 턴 종료, 운명 전가 2단계)
 *         → 승리 뒤 카드 보상 화면 없이 안치 홀(덱 그대로) → 지도(방·랜턴 안내) → 핏자국 통로 끝(촛불 4 → 3, 이름 없는 마녀의 카드) → 지나간 방 공짜 이동
 *         → 계단 앞 홀(「들어간다」) → 가장 깊은 곳(광신도 → 발 → 거대한 발: 흠집, 3턴 「짓밟기」 → 뒤집힌 카드가 뒤집힘 → "알고 있었는데."
 *         → 데스신 C1~C6 → 카드 문구 → 안내 → 반응) → 빈 캠프(브룬힐드 카드, 문구 번짐) → 1층 끝 → 2층(촛불 이월)
 * 경로 B: 어둠 — 층 끝 전투 예고 「?」·어둠 안내, 거대한 발 1턴 가려짐·3턴 짓밟기는 보임, 전조를 보았으면 가려지지 않음, 강적은 전조와 상관없이 가려짐
 * 경로 C: 골라 들어가는 방 — 순장된 자의 방 [꺼낸다] · 묘지기의 좌판(카드 — HP 4) · 무너진 훈련장 · 촛불 예배당 · 발자국 방 · 기도실(승리 뒤 보상 화면 없음)
 *         · 무덤지기(이기면 고르지 않고 카드 1장이 강화된 채 덱에)
 * (전투 승리 뒤 '카드 3장 중 1장' 보상은 2026-11-21 사용자 지시로 뺐다 — game/DECISIONS.md)
 * 경로 D: 휴대폰 가로(iPhone 13 에뮬레이션, 터치) — 작은 화면 글씨, 터치 탭·터치 드래그로 카드 내기, 지도 터치 두 번, 세로 화면 "가로로 돌려 주세요"
 * 경로 E: 느린 속도 연출 스크린샷 (손 들기 중간·컷인·동료 타격)
 * 경로 F: 2·3층 운명 — 휴대폰: 납골당 「운명의 관통」 받아들임(데스신·상속) → 계단 → 화형대 「운명의 불길」 거스름(흉터) → 결과 → 2층부터 다시
 *         / PC: 3층 두 운명(엘리안 거스름 → 브룬힐드 Lv2 받아들임), 죽음 카드는 끌어도 못 냄, 집행자를 먼저 쓰러뜨림
 * 경로 S: 기본 기능 — 타이틀(저장이 없으면 이어하기 꺼짐, 웹은 끝내기 없음) → 설정(전체 화면 켜고 끄기·글자 속도) 열고 닫기(Esc) → 시작
 *         → 일시정지(Esc: 대사·연출이 멈춤) → 계속 → 장례 회랑에 들어감(자동 저장) → 새로고침 → 이어하기(설정도 남음) → 같은 방의 처음
 *         → 일시정지 → 타이틀로(확인) → 시작(저장이 지워진다는 확인 → 취소 → 처음부터) / 휴대폰: 타이틀·설정·메뉴 단추로 일시정지
 *         / 카드 연출·데스신 도중 일시정지 → 멈춘 동안 그대로 → 계속하면 이어서 끝남
 *   경로만 고르기: node smoke.js <주소> <폴더> AB   (기본: ABCDEFS 전부)
 * 통과 조건: 모든 확인 통과 + 브라우저 콘솔 에러 0 (Godot 의 ERROR / SCRIPT ERROR 포함)
 * (탑뷰 시험판 경로 T 는 탑뷰 코드와 함께 없앴다 — 2026-11-21, game/DECISIONS.md)
 */
'use strict';
const { chromium, devices } = require('playwright');
const fs = require('fs');
const path = require('path');

const BASE = (process.argv[2] || 'http://localhost:8000/').replace(/\/?$/, '/');
const SHOTS = process.argv[3] || path.join(__dirname, 'shots');
fs.mkdirSync(SHOTS, { recursive: true });

// 손 그림(ui_witch_hands.png) 원본 좌표: 카드 자리 안쪽에서 손이 끊긴 곳 (HTML 판 smoke.js 와 같은 점)
const HAND_CUT_PTS = [[472, 506], [476, 511], [479, 519], [482, 524], [491, 541], [494, 544], [500, 553], [503, 559], [521, 595],
  [523, 599], [527, 604], [530, 608], [532, 614], [904, 589], [908, 590], [917, 590], [924, 591], [931, 593], [1124, 613],
  [1129, 607], [1134, 599], [1139, 590], [1145, 581], [1149, 570], [1153, 564], [1157, 559], [1161, 553], [1169, 540],
  [1170, 533], [1176, 528], [1181, 518], [1188, 507]];

const results = [];
const log = [];
function say(s) { log.push(s); console.log(s); }
function check(name, ok, detail) {
  results.push({ name, ok: !!ok, detail });
  say((ok ? '  ✔ ' : '  ✘ ') + name + (detail ? ' — ' + (typeof detail === 'string' ? detail : JSON.stringify(detail)).slice(0, 400) : ''));
}
const errors = [];

async function launch() {
  return chromium.launch({ args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--autoplay-policy=no-user-gesture-required'] });
}

function helpers(page, tag) {
  const H = {};
  page.on('console', m => {
    const t = m.text();
    if (m.type() === 'error' || /^(SCRIPT )?ERROR:/.test(t)) errors.push(tag + ': ' + t);
  });
  page.on('pageerror', e => errors.push(tag + ' pageerror: ' + e.message));
  H.shot = async name => { await page.screenshot({ path: path.join(SHOTS, name) }); say('    📷 ' + name); };
  H.open = async q => {
    await page.goto(BASE + 'index.html?test=1&seed=7&' + (q || ''));
    await page.waitForFunction(() => window.__witchReady === true, null, { timeout: 90000 });
  };
  H.W = (name, ...args) => page.evaluate(([n, a]) => { window.__witchOut = null; window.witch[n](...a); return JSON.parse(window.__witchOut || 'null'); }, [name, args]);
  H.state = () => H.W('state');
  H.sleep = ms => page.waitForTimeout(ms);
  H.until = async (pred, timeout, what, step) => {
    const t0 = Date.now();
    let s;
    while (Date.now() - t0 < (timeout || 30000)) {
      s = await H.state();
      if (await pred(s)) return s;
      if (step) await step(s);
      await H.sleep(120);
    }
    throw new Error('시간 초과: ' + (what || '') + ' · stage=' + (s && s.stage) + ' scene=' + (s && s.scene));
  };
  // 무대(1920×1080) 좌표 → 페이지 좌표 (캔버스 안에서 비율 유지·가운데)
  H.toPage = async (x, y) => page.evaluate(([x, y]) => {
    const c = document.querySelector('canvas');
    const r = c.getBoundingClientRect();
    const s = Math.min(r.width / 1920, r.height / 1080);
    return { x: r.left + (r.width - 1920 * s) / 2 + x * s, y: r.top + (r.height - 1080 * s) / 2 + y * s };
  }, [x, y]);
  H.click = async (x, y) => { const p = await H.toPage(x, y); await page.mouse.click(p.x, p.y); };
  H.drag = async (a, b, steps) => {
    const p = await H.toPage(a.x, a.y), q = await H.toPage(b.x, b.y);
    await page.mouse.move(p.x, p.y);
    await page.mouse.down();
    for (let i = 1; i <= (steps || 12); i++) {
      await page.mouse.move(p.x + (q.x - p.x) * i / (steps || 12), p.y + (q.y - p.y) * i / (steps || 12));
      await H.sleep(16);
    }
    await page.mouse.up();
  };
  // 터치 (CDP)
  H.cdp = null;
  H.touchTap = async (x, y) => {
    const p = await H.toPage(x, y);
    H.cdp = H.cdp || await page.context().newCDPSession(page);
    await H.cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: p.x, y: p.y }] });
    await H.sleep(60);
    await H.cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
  };
  // 터치를 누른 채로 두기 (조이스틱): touchStart → touchMove … → touchEnd
  H.touchStart = async (x, y) => {
    const p = await H.toPage(x, y);
    H.cdp = H.cdp || await page.context().newCDPSession(page);
    await H.cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: p.x, y: p.y }] });
  };
  H.touchMove = async (x, y) => {
    const p = await H.toPage(x, y);
    await H.cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ x: p.x, y: p.y }] });
  };
  H.touchEnd = async () => { await H.cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] }); };
  H.touchDrag = async (a, b, steps) => {
    const p = await H.toPage(a.x, a.y), q = await H.toPage(b.x, b.y);
    H.cdp = H.cdp || await page.context().newCDPSession(page);
    await H.cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: p.x, y: p.y }] });
    for (let i = 1; i <= (steps || 12); i++) {
      await H.sleep(20);
      await H.cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ x: p.x + (q.x - p.x) * i / (steps || 12), y: p.y + (q.y - p.y) * i / (steps || 12) }] });
    }
    await H.sleep(30);
    await H.cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
  };
  // 대사·안내 넘기기
  H.advanceAll = async (pred, timeout, what) => H.until(pred, timeout || 60000, what, async s => {
    if (s.guideOpen || s.dialogBusy || s.vn) await H.W('advance');
  });
  // 전투 한 수 (사람처럼): 낼 수 있는 카드 → 대상, 없으면 턴 종료
  H.botStep = async (s, opts) => {
    opts = opts || {};
    if (s.guideOpen) { await H.W('advance'); return; }
    if (s.dialogBusy) { await H.W('advance'); return; }
    if (s.vn && !s.inBattle) { await H.W('advance'); return; }   // 전투 앞 방 장면(VN)
    const b = s.battle;
    if (!s.inBattle || s.busy || !b || b.phase !== 'player' || b.result) return;
    for (const c of b.hand) {
      if (!c.playable) continue;
      const alive = b.enemies.filter(e => e.alive);
      if (['curse_flame', 'holy_slash', 'shield_bash', 'snipe', 'suppress', 'broken_sword'].includes(c.id)) { await H.W('play', c.id, JSON.stringify({ enemy: alive[0].id })); return; }
      if (['foresight', 'vanguard', 'last_charge', 'trample'].includes(c.id)) { await H.W('play', c.id, ''); return; }
      if (c.id === 'fate_shift' || c.id === 'cover') {
        const tgt = alive.find(e => e.intent && e.intent.kind === 'attack' && !e.intent.blocked && e.intent.target !== 'warrior');
        if (!tgt) continue;
        await H.W('play', c.id, JSON.stringify(c.id === 'fate_shift' ? { enemy: tgt.id, to: 'warrior' } : { enemy: tgt.id }));
        return;
      }
    }
    await H.W('endTurn');
  };
  H.fight = async (pred, timeout, what, opts) => H.until(pred, timeout || 120000, what, async s => { await H.botStep(s, opts); });
  // 조준 중: 작은 오른손이 그 카드를 쥐었는지, 손은 둘 이하인지, 쥔 카드가 손패 영역(화면 아래쪽) 안인지
  H.gripOk = (s, uid) => {
    const b = s.handGripBox || [];
    const inHand = b.length === 4 && b[1] >= 470 && b[3] <= 1080 && b[0] >= 200 && b[2] <= 1720;
    return { ok: s.handDragMode === 'aim' && s.handLifted === '' && s.handGrip === uid && s.handsNow <= 2 && inHand,
      detail: { mode: s.handDragMode, lifted: s.handLifted, grip: s.handGrip, uid, hands: s.handsNow, box: b.map(v => Math.round(v)) } };
  };
  // 두 단추(geom: 가운데 x·y, 크기 w·h — 무대 px)가 겹치는가. 누르는 영역은 Btn 처럼 실제 화면 44px 이상으로 넓혀 본다
  H.overlap = (a, b, css) => {
    const need = 44 / Math.max(0.05, css || 1);
    const box = g => { const w = Math.max(g.w || 0, need), h = Math.max(g.h || 0, need); return [g.x - w / 2, g.y - h / 2, g.x + w / 2, g.y + h / 2]; };
    const p = box(a), q = box(b);
    return p[0] < q[2] && q[0] < p[2] && p[1] < q[3] && q[1] < p[3];
  };
  H.handsOk = async label => {
    const s = await H.state();
    return { ok: s.maxHands <= 2, detail: label + ' maxHands=' + s.maxHands + ' now=' + s.handsNow };
  };
  return H;
}

const has = (s, re) => (s.dialog || []).some(l => re.test(l));


// ───────── 경로 A: 튜토리얼 정해진 길 (PC, 실제 클릭·드래그) ─────────
async function pathA(browser) {
  say('경로 A: 타이틀 → 곁방(파티 소개) → 장례 회랑(VN → 전투 ①: 뒤집힌 카드·조준·드래그·운명 전가) → 보상 화면 없이 안치 홀 → 지도(안내·촛불)'
    + ' → 핏자국 통로 끝 → 계단 앞 홀 → 가장 깊은 곳(광신도 → 거대한 발: 3턴 짓밟기에 카드가 뒤집힘 → 데스신 → 문구 → 안내) → 빈 캠프(브룬힐드, 문구 번짐) → 1층 끝 → 2층');
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: 1 });
  const H = helpers(page, 'A');
  await H.open('guides=reset');
  let s = await H.until(s => s.scene === 'title', 20000, '타이틀');
  await H.sleep(500);
  await H.shot('A00_title.png');
  const btn = await H.W('geom', 'button', 'start');
  await H.click(btn.x, btn.y);
  s = await H.until(s => s.scene === 'vn:camp' && s.vn, 15000, '곁방 시작');
  check('타이틀 「시작」 실제 클릭 → 곁방(VN, 탑뷰 없음)', s.vn.name === 'camp' && !s.topdown);
  s = await H.advanceAll(s => s.vn && s.vn.line >= 8 && !s.guideOpen && !s.dialogBusy && !s.vn.typing, 60000, '파티 소개');
  await H.sleep(900);
  await H.shot('A01_camp_party_intro.png');
  s = await H.advanceAll(s => s.stage === 'battle:normal' && s.battle && s.battle.turn === 1 && s.guideOpen, 120000, '장례 회랑 전투');
  const deckStart = s.party.deck;   // 승리 뒤 덱 수와 비교 (승리를 알아챈 때는 이미 카드가 들어왔을 수 있어 전투 시작 때 잰다)
  check('곁방 대사(대본 v3) → 장례 회랑 VN → 같은 배경에서 전투 ①', has(s, /장례 탑이다/) && has(s, /바쳐라\. 탑은 죽음을 받고/) && has(s, /순서 잡아 줘/), (s.dialog || []).slice(-3));
  check('캠프에서 죽음 카드를 보여 주지 않는다(대본 v3)', !(s.log || []).some(l => /omen/.test(l)));
  s = await H.advanceAll(s => s.battle && s.battle.turn === 1 && !s.guideOpen && !s.dialogBusy && !s.busy, 60000, '1턴 안내');
  check('1턴 안내: 뒤집힌 카드·비용·테두리·내는 법', has(s, /뒤집힌 카드는 낼 수 없습니다/) && has(s, /테두리 색은 카드의 주인/), (s.dialog || []).slice(-4));
  const ids = s.battle.hand.map(c => c.id);
  check('1턴: 손패 맨 오른쪽에 뒤집힌 카드(낼 수 없음) + 4장, 에너지 3', ids.length === 5 && ids[4] === 'hero_death' && s.battle.hand[4].faceDown && !s.battle.hand[4].playable && s.battle.energy === 3, ids);
  await H.shot('A02_corridor_face_down_card.png');
  // 뒤집힌 카드를 실제로 끌어 올려 본다 → 손패로 돌아간다
  const dc = await H.W('geom', 'card', 'hero_death');
  await H.drag({ x: dc.x, y: dc.y }, { x: 960, y: 380 });
  await H.sleep(600);
  s = await H.state();
  check('뒤집힌 카드를 끌어도 낼 수 없다(손패에 그대로, 세라피나 멀쩡)', s.battle.hand.some(c => c.id === 'hero_death' && c.faceDown) && s.party.allies.hero.status === 'ok' && !s.busy);
  // 성검 베기: 대상을 고르다가 빈 곳에 놓아 취소 → 오른손이 카드를 손패로 돌려놓는다
  const hs = await H.W('geom', 'card', 'holy_slash');
  const en = await H.W('geom', 'enemy', 'c2');
  const hsUid = s.battle.hand.find(c => c.id === 'holy_slash').uid;
  {
    const a = await H.toPage(hs.x, hs.y), b = await H.toPage(en.x, en.y);
    await page.mouse.move(a.x, a.y);
    await page.mouse.down();
    for (let i = 1; i <= 6; i++) { await page.mouse.move(a.x + (b.x - a.x) * i / 12, a.y + (b.y - a.y) * i / 12); await H.sleep(16); }
    await H.sleep(350);
    const m = await H.state();
    await H.shot('A03_aiming_grip.png');
    const g = H.gripOk(m, hsUid);
    check('PC: 대상 고르는 중 오른손이 그 카드를 손패 높이에서 작게 쥠(손은 둘, 화면 아래쪽 안)', g.ok, g.detail);
    const c = await H.toPage(1500, 760);
    await page.mouse.move(c.x, c.y, { steps: 4 });
    await page.mouse.up();
    await H.sleep(600);
    const m2 = await H.state();
    check('대상 고르기를 취소하면 카드가 손패로 돌아가고 오른손도 손패로', m2.handGrip === '' && m2.handDragMode === '' && m2.handRightOut === 0 && m2.handsNow <= 2 && m2.battle.hand.some(x => x.uid === hsUid) && !m2.busy,
      { grip: m2.handGrip, mode: m2.handDragMode, rightOut: m2.handRightOut, hands: m2.handsNow, max: m2.maxHands });
  }
  await H.drag({ x: hs.x, y: hs.y }, { x: en.x, y: en.y }, 14);
  await H.sleep(330);
  await H.shot('A04_raise_two_hands.png');
  s = await H.until(s => !s.busy, 15000, '성검 베기 끝');
  const c2 = s.battle.enemies.find(e => e.id === 'c2');
  check('성검 베기(실제 드래그) → 광신도 일격, 손 들기·컷인·공격 자세', !c2.alive && s.raiseLog.includes('holy_slash') && s.cutinLog.includes('holy_slash') && s.motionLog.includes('hero:attack'), { raise: s.raiseLog, cutin: s.cutinLog, motion: s.motionLog });
  let h = await H.handsOk('성검 베기');
  check('카드를 낼 때 보이는 손은 언제나 둘 이하', h.ok, h.detail);
  const cut = await H.W('handCut', JSON.stringify(HAND_CUT_PTS));
  check('손 그림의 잘린 자리가 카드·덱 덮개로 가려짐', cut.uncovered.length === 0, cut.uncovered.slice(0, 4));
  s = await H.until(s => !s.busy && !s.guideOpen, 20000, '1턴 대기', async s => { if (s.guideOpen || s.dialogBusy) await H.W('advance'); });
  const et = await H.W('geom', 'endTurn');
  await H.click(et.x, et.y);
  s = await H.advanceAll(s => s.battle && s.battle.turn === 2 && !s.busy && !s.guideOpen && !s.dialogBusy, 60000, '2턴');
  check('턴 종료(실제 클릭) → 예고 안내 → 2턴, 뒤집힌 카드는 그대로', has(s, /머리 위에 미리 보여 줍니다/) && s.battle.hand.length === 5 && s.battle.hand[4].id === 'hero_death' && s.battle.hand[4].faceDown, s.battle.hand.map(c => c.id));
  check('2턴: 셋 다 엘리안 → 피해 옮기기 안내', has(s, /셋 다 엘리안이야/) && has(s, /피해 옮기기/));
  const fs1 = await H.W('geom', 'card', 'fate_shift');
  const it1 = await H.W('geom', 'intent', s.battle.enemies.find(e => e.alive).id);
  if (fs1.x && it1.x) {
    await H.drag({ x: fs1.x, y: fs1.y }, { x: it1.x, y: it1.y });
    await H.sleep(300);
    await H.shot('A05_fate_shift_pick.png');
    const wp = await H.W('geom', 'ally', 'warrior');
    await H.click(wp.x, wp.y);
    s = await H.until(s => !s.busy, 15000, '운명 전가');
    check('운명 전가(실제 드래그 + 아군 클릭): 예고 대상이 브룬힐드로', s.battle.enemies.some(e => e.alive && e.intent && e.intent.target === 'warrior'), s.battle.enemies.map(e => e.intent && e.intent.target));
  }
  // 승리 뒤 '카드 3장 중 1장' 보상 화면은 없다(2026-11-21 사용자 지시로 뺌) → 승리 대사 뒤 바로 안치 홀, 덱 수 그대로
  let sawPick = false;
  s = await H.fight(s => { if (s.picker) sawPick = true; return (s.log || []).includes('win normal'); }, 180000, '장례 회랑 승리');
  s = await H.until(s => s.stage === 'vn:hall' || s.scene === 'vn:hall', 60000, '안치 홀', async s => {
    if (s.picker) sawPick = true;
    if (s.guideOpen || s.dialogBusy) await H.W('advance');
  });
  await H.sleep(400);
  await H.shot('A06_win_no_reward_hall.png');
  check('승리 대사(긁힌 거예요) 뒤 카드 보상 안내·고르기 화면 없이 안치 홀로', has(s, /긁힌 거예요/) && !has(s, /카드 3장 중 1장/) && !sawPick && !s.picker
    && !(s.log || []).some(l => /overlay cardPick|^reward|^win card|card gain/.test(l)), { sawPick, log: (s.log || []).slice(-8) });
  check('장례 회랑 승리 뒤 덱 수 그대로(카드가 들어오지 않음)', s.party.deck === deckStart, { before: deckStart, after: s.party.deck });
  s = await H.advanceAll(s => s.scene === 'map' && s.guideOpen, 60000, '지도');
  await H.sleep(600);
  await H.shot('A07_map_first_guide.png');
  s = await H.advanceAll(s => s.scene === 'map' && has(s, /넉넉하진 않네/) && s.guideOpen, 60000, '랜턴 안내');
  await H.sleep(500);
  await H.shot('A08_map_lantern_guide.png');
  s = await H.advanceAll(s => s.scene === 'map' && !s.guideOpen && !s.dialogBusy && s.map && !s.map.busy, 60000, '지도 안내 끝');
  check('지도: 방 안내 → 랜턴 촛불 4개 안내, 안치 홀에 붙은 방만 열림', has(s, /랜턴의 촛불/) && s.progress.candles === 4 && s.map.rooms.corpse === 'open' && s.map.rooms.deep === 'locked' && s.map.rooms.gravekeeper === 'locked', s.map.rooms);
  // 방을 한 번 누르면 설명, 한 번 더 누르면 들어간다
  const rc = await H.W('geom', 'room', 'corpse');
  await H.click(rc.x, rc.y);
  s = await H.until(s => s.map && s.map.sel === 'corpse' && s.map.enter, 5000, '방 고름');
  await H.sleep(300);
  await H.shot('A09_map_room_selected.png');
  check('방을 누르면 오른쪽에 설명 + 「들어간다」(아직 들어가지 않음)', s.scene === 'map' && s.progress.candles === 4);
  await H.click(rc.x, rc.y);
  s = await H.until(s => s.scene === 'vn:corpse', 15000, '핏자국 통로 끝');
  check('한 번 더 누르면 들어간다 → 촛불 1개가 탄다(4 → 3)', s.progress.candles === 3, s.progress);
  s = await H.advanceAll(s => (s.log || []).some(l => /card gain inherit nameless_card/.test(l)), 60000, '죽은 마녀의 카드');
  await H.sleep(900);
  await H.shot('A10_corpse_card.png');
  s = await H.advanceAll(s => s.scene === 'map' && !s.guideOpen && !s.dialogBusy && s.map && !s.map.busy, 60000, '지도로');
  check('핏자국 통로 끝: 「이름 없는 마녀의 카드」 획득 + 안내 → 지도', has(s, /이 카드 한 장은 안 탔네/) && has(s, /예고 하나를 지웁니다/));
  // 지나간 방(안치 홀)으로는 공짜로 이동
  const rh = await H.W('geom', 'room', 'hall');
  await H.click(rh.x, rh.y);
  await H.click(rh.x, rh.y);
  s = await H.until(s => s.progress.room === 'hall', 5000, '지나간 방으로 이동');
  check('지나간 방은 공짜로 지나간다(촛불 그대로, 장면 없음)', s.progress.candles === 3 && s.scene === 'map');
  // 계단 앞 홀 → 가장 깊은 곳 (「들어간다」 버튼 실제 클릭)
  const rs = await H.W('geom', 'room', 'stairs');
  await H.click(rs.x, rs.y);
  await H.until(s => s.map && s.map.sel === 'stairs' && s.map.enter, 5000, '계단 앞 홀 고름');
  const eb = await H.W('geom', 'enter', '');
  await H.click(eb.x, eb.y);
  s = await H.advanceAll(s => s.scene === 'map' && s.map && s.map.rooms.deep === 'open' && !s.map.busy && !s.dialogBusy, 60000, '계단 앞 홀');
  check('계단 앞 홀(「들어간다」 실제 클릭) → 짧은 대화 → 가장 깊은 곳이 열림', has(s, /너 그거 물으면 꼭 일 생기더라/) && s.progress.candles === 2, s.progress);
  await H.sleep(300);
  await H.shot('A11_map_after_stairs.png');
  const rd = await H.W('geom', 'room', 'deep');
  await H.click(rd.x, rd.y);
  await H.click(rd.x, rd.y);
  s = await H.advanceAll(s => s.stage === 'battle:deep' && s.battle && s.battle.turn === 1 && !s.busy && !s.guideOpen && !s.dialogBusy, 90000, '가장 깊은 곳 전투');
  check('가장 깊은 곳: VN → 광신도 전투(촛불이 남아 있으니 어둠 없음)', has(s, /오신다\. 오신다/) && s.battle.darkness === 0 && s.battle.enemies.every(e => !e.intent || !e.intent.hidden));
  s = await H.fight(s => s.stage === 'battle:giant', 180000, '거대한 발');
  check('광신도 1명 남으면 발이 내려와 짓밟고 → 거대한 발 전투', (s.log || []).some(l => /giant appears/.test(l)) && has(s, /원정대 납작하게 만든 거/));
  s = await H.advanceAll(s => s.battle && s.battle.kind === 'giant' && s.battle.turn === 1 && !s.busy && !s.guideOpen && !s.dialogBusy, 90000, '거대한 발 1턴');
  await H.shot('A12_giant_turn1.png');
  check('거대한 발: HP 「???」, 1턴 손패에 뒤집힌 카드 그대로, 짓밟기 안내', s.battle.enemies[0].hp === null && s.battle.hand.some(c => c.id === 'hero_death' && c.faceDown) && has(s, /3턴째에 「짓밟기」/));
  check('거대한 발은 동료 뒤 레이어(z 발 < 동료)', s.battle.footZ < s.battle.alliesZ, { foot: s.battle.footZ, allies: s.battle.alliesZ });
  const atk = s.battle.hand.find(c => c.playable && ['holy_slash', 'snipe', 'curse_flame', 'shield_bash', 'suppress'].includes(c.id));
  if (atk) { await H.W('play', atk.id, JSON.stringify({ enemy: 'giant' })); s = await H.advanceAll(s => !s.busy && has(s, /흠집밖에 안 나/) && has(s, /계속 쳐!/), 30000, '흠집'); }
  check('공격은 흠집만 낸다 → 브룬힐드·세라피나 반응', !atk || has(s, /계속 쳐!/), atk && atk.id);
  // 2턴 → 3턴: 「짓밟기」 예고 → 턴 종료 → 카드가 뒤집힘
  s = await H.until(s => s.battle && s.battle.turn === 3 && s.battle.phase === 'player' && !s.busy && !s.guideOpen && !s.dialogBusy, 120000, '3턴', async s => {
    if (s.guideOpen || s.dialogBusy) { await H.W('advance'); return; }
    if (s.battle && s.battle.phase === 'player' && !s.busy && s.battle.turn < 3) await H.W('endTurn');
  });
  const gi = s.battle.enemies[0].intent;
  await H.shot('A13_giant_turn3_stomp_intent.png');
  check('3턴 예고 「짓밟기 · 모두에게 큰 피해」(누가 죽는지는 보이지 않는다)', gi && gi.kind === 'stomp' && gi.label === '짓밟기' && gi.target === 'all' && gi.fate === 'hero_stomp' && has(s, /다시 들려요/), gi);
  await H.W('setSpeed', 0.4);
  const et3 = await H.W('geom', 'endTurn');
  await H.click(et3.x, et3.y);
  s = await H.until(s => (s.log || []).some(l => /^flip hero_death/.test(l)), 30000, '카드가 뒤집힘');
  await H.sleep(900);
  await H.shot('A14_flip_card.png');
  s = await H.until(s => has(s, /알고 있었는데\./), 20000, '속마음');
  await H.sleep(500);
  await H.shot('A15_inner_knew.png');
  await H.W('setSpeed', 1);
  check('짓밟기 순간 손패의 뒤집힌 카드가 저절로 뒤집힘 → 속마음 "알고 있었는데."(안내 상자·선택 화면 없음)', !s.fatePicker && !s.guideOpen, (s.log || []).slice(-6));
  s = await H.until(s => s.scene === 'cutscene', 30000, '데스신', async s => { if (s.dialogBusy) await H.W('advance'); });
  await H.sleep(1400);
  await H.shot('A16_cut_C1.png');
  s = await H.until(s => (s.cutLog || []).includes('C3b'), 40000, 'C3b');
  await H.sleep(800);
  await H.shot('A17_cut_C3b.png');
  s = await H.until(s => (s.log || []).some(l => /card gain note hero_death/.test(l)), 60000, '카드 문구');
  await H.sleep(1200);
  await H.shot('A18_death_card_text.png');
  check('데스신 C1~C6(대본 v3 대사) → 노엘의 손에 남은 카드(이제야 문구가 보인다)', ['C1', 'C2', 'C3a', 'C3b', 'C4', 'C6'].every(c => s.cutLog.includes(c)) && has(s, /어\? 잠깐, 이거—/) && has(s, /안 움직여/), s.cutLog);
  s = await H.advanceAll(s => s.stage === 'vn:emptycamp' || s.scene === 'vn:emptycamp', 90000, '빈 캠프');
  check('사망 직후: 죽음 카드·상속·유품 안내 → 엘리안·브룬힐드 반응 → 물러남 → 빈 캠프', has(s, /노엘만 보는 카드입니다/) && has(s, /대장! 대장!!/) && has(s, /또 내려와\. 뛰어!/) && s.party.allies.hero.status === 'dead', (s.dialog || []).slice(-4));
  check('세라피나는 거스를 수 없다(선택 화면 없음), 흉터 0', s.scars === 0 && (s.log || []).some(l => /fate accept \(no choice\) hero_stomp/.test(l)) && !(s.log || []).some(l => /fate choice hero/.test(l)));
  s = await H.advanceAll(s => s.vn && s.vn.name === 'emptycamp' && s.vn.omen && s.fates.some(f => f.who === 'warrior'), 90000, '다음 죽음 카드');
  await H.sleep(2200);
  await H.shot('A19_empty_camp_brunhild_masked.png');
  check('빈 캠프: 브룬힐드의 죽음 카드(얼굴은 보이고 문구는 번짐), 2층', s.fates.find(f => f.who === 'warrior').floor === 2 && has(s, /이것도 보였어\?/));
  s = await H.advanceAll(s => s.scene === 'chapter', 90000, '1층 끝');
  check('빈 캠프 끝: 「운명은 거스를 수 있습니다」 안내 → 「1층 — 끝」', has(s, /운명은 거스를 수 있습니다/));
  await H.sleep(2500);
  await H.shot('A20_chapter1.png');
  h = await H.handsOk('경로 A 전체');
  check('경로 A 전체에서 동시에 보인 손은 최대 둘', h.ok, h.detail);
  const nx = await H.W('geom', 'button', 'next');
  await H.click(nx.x, nx.y);
  s = await H.until(s => s.scene === 'vn:f2corridor', 20000, '2층');
  check('「아래로 — 2층」 → 2층 창 함정 회랑(VN), 남은 촛불 1(가장 깊은 곳에서도 탐) + 4 = 5', s.progress.floor === 2 && s.progress.candles === 5, s.progress);
  await page.close();
}

// ───────── 경로 B: 어둠(가려진 예고) · 전조 · 운명 공격은 늘 보임 ─────────
async function pathB(browser) {
  say('경로 B: 촛불이 다 탄 뒤 어둠 2단계 → 가장 깊은 곳 예고 2개 「?」 → 거대한 발 1턴 「?」, 3턴 짓밟기는 보임 / 전조를 보았으면 가려지지 않음');
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: 1 });
  const H = helpers(page, 'B');
  await H.open('scene=room:deep&darkness=2&guides=reset');
  let s = await H.advanceAll(s => s.stage === 'battle:deep' && s.battle && s.battle.turn === 1 && !s.busy && !s.guideOpen && !s.dialogBusy, 90000, '깊은 곳(어둠)');
  const hid = s.battle.enemies.filter(e => e.intent && e.intent.hidden).length;
  await H.shot('B01_darkness_hidden_intents.png');
  check('어둠 2단계: 층 끝 광신도 전투의 예고 2개가 「?」 + 어둠 안내', s.battle.darkness === 2 && hid === 2 && has(s, /어둠 — 적의 예고 일부가 가려졌습니다/), { hid, d: s.battle.darkness });
  // 가려진 예고에 마우스를 올려도 누구를 노리는지 선이 보이지 않는다(그림으로만 확인)
  const it = await H.W('geom', 'intent', 'c1');
  if (it && it.x) { const p = await H.toPage(it.x, it.y); await page.mouse.move(p.x, p.y); await H.sleep(300); await H.shot('B02_hidden_hover.png'); }
  s = await H.fight(s => s.stage === 'battle:giant' && s.battle && s.battle.turn === 1 && !s.busy && !s.guideOpen && !s.dialogBusy, 180000, '거대한 발(어둠)');
  check('거대한 발 1턴 「그림자」도 어둠에 가려짐', s.battle.enemies[0].intent.hidden === true, s.battle.enemies[0].intent);
  s = await H.until(s => s.battle && s.battle.turn === 3 && s.battle.phase === 'player' && !s.busy && !s.guideOpen && !s.dialogBusy, 120000, '3턴', async s => {
    if (s.guideOpen || s.dialogBusy) { await H.W('advance'); return; }
    if (s.battle && s.battle.phase === 'player' && !s.busy && s.battle.turn < 3) await H.W('endTurn');
  });
  await H.shot('B03_stomp_visible_in_dark.png');
  check('운명 공격 「짓밟기」 예고는 어둠에서도 보인다', s.battle.enemies[0].intent.kind === 'stomp' && !s.battle.enemies[0].intent.hidden, s.battle.enemies[0].intent);
  // 전조를 본 상태: 같은 어둠이어도 층 끝 전투는 가려지지 않는다
  await H.open('scene=room:deep&darkness=3&omen=1');
  s = await H.advanceAll(s => s.stage === 'battle:deep' && s.battle && s.battle.turn === 1 && !s.busy && !s.guideOpen && !s.dialogBusy, 90000, '깊은 곳(전조)');
  check('전조를 보았으면 어둠 3단계여도 층 끝 전투 예고가 보인다', s.battle.darkness === 0 && s.battle.enemies.every(e => !e.intent || !e.intent.hidden));
  // 강적(무덤지기)은 전조와 상관없이 가려진다
  await H.open('scene=room:gravekeeper&darkness=1&omen=1');
  s = await H.advanceAll(s => s.stage === 'battle:gravekeeper' && s.battle && s.battle.turn === 1 && !s.busy && !s.guideOpen && !s.dialogBusy, 90000, '무덤지기');
  await H.shot('B04_gravekeeper_dark.png');
  check('강적 전투: 강적 안내 + 어둠 1단계면 예고 「?」(전조와 상관없음)', has(s, /강적 — 더 강하지만 보상이 큽니다/) && s.battle.enemies[0].intent.hidden === true, s.battle.enemies[0].intent);
  await page.close();
}

// ───────── 경로 C: 골라 들어가는 방 (사건·거래·훈련·휴식·전투·강적) ─────────
async function pathC(browser) {
  say('경로 C: 순장된 자의 방([꺼낸다] — HP −2·부적) / 묘지기의 좌판(카드 — HP 4) / 무너진 훈련장(강화) / 촛불 예배당(휴식) / 발자국 방(전조) / 기도실 전투(보상 화면 없음) / 무덤지기(카드 1장 강화된 채)');
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: 1 });
  const H = helpers(page, 'C');
  await H.open('scene=room:buried&guides=reset');
  let s = await H.advanceAll(s => s.vn && s.vn.choices === 2 && !s.dialogBusy, 60000, '순장된 자의 방');
  await H.sleep(500);
  await H.shot('C01_buried_choice.png');
  const w0 = s.party.witch.hp;
  const ob = await H.W('geom', 'button', 'open');
  await H.click(ob.x, ob.y);
  s = await H.advanceAll(s => s.scene === 'map' && !s.dialogBusy && !s.guideOpen, 60000, '꺼낸 뒤 지도');
  check('[꺼낸다](실제 클릭): 노엘 HP −2, 「작은 손의 부적」 덱에 → 지도', s.flags.buried === 'open' && s.party.witch.hp === w0 - 2 && has(s, /깜깜했어요/), { w0, w: s.party.witch.hp });
  await H.open('scene=room:stall&guides=reset');
  s = await H.advanceAll(s => s.vn && s.vn.choices === 3 && !s.dialogBusy, 60000, '묘지기의 좌판');
  await H.sleep(500);
  await H.shot('C02_stall_choice.png');
  const w1 = s.party.witch.hp;
  const d1 = s.party.deck;
  const cb = await H.W('geom', 'button', 'card');
  await H.click(cb.x, cb.y);
  s = await H.until(s => s.picker && s.picker.length === 3, 20000, '거래 카드 고르기');
  await H.sleep(400);
  await H.shot('C03_stall_pick.png');
  const p0 = await H.W('geom', 'pick', s.picker[0]);
  await H.click(p0.x, p0.y);
  s = await H.advanceAll(s => s.scene === 'map' && !s.dialogBusy, 60000, '거래 끝');
  check('거래 [카드 — HP 4](실제 클릭): 노엘 HP −4, 덱 +1, 묘지기 한마디', s.party.witch.hp === w1 - 4 && s.party.deck === d1 + 1 && has(s, /값은 올라/), { w1, w: s.party.witch.hp });
  await H.open('scene=room:training&guides=reset');
  s = await H.until(s => s.picker && s.picker.length === 3 && !s.guideOpen && !s.dialogBusy, 60000, '훈련', async s => { if (s.guideOpen || s.dialogBusy || (s.vn && !s.picker)) await H.W('advance'); });
  await H.sleep(500);
  await H.shot('C04_training_pick.png');
  const tp = await H.W('geom', 'pick', s.picker[0]);
  await H.click(tp.x, tp.y);
  s = await H.advanceAll(s => s.scene === 'map', 60000, '훈련 끝');
  check('훈련: 3장 중 1장 강화(Lv2) → 고른 카드에 따라 한 줄', !!s.flags.upgraded, s.flags.upgraded);
  await H.open('scene=room:chapel&guides=reset');
  s = await H.advanceAll(s => s.scene === 'map', 60000, '예배당');
  check('촛불 예배당(휴식): 모두 회복, 최대 HP 동료 +3·노엘 +2', s.party.witch.maxHp === 17 && s.party.allies.archer.maxHp === 15 && s.party.allies.hero.hp === 33 && has(s, /다 됐어요/), { w: s.party.witch, a: s.party.allies.archer });
  await H.open('scene=room:footprints&guides=reset');
  s = await H.advanceAll(s => s.scene === 'map', 60000, '발자국 방');
  await H.shot('C05_map_omen_seen.png');
  check('발자국 방(전조): 「전조를 보았습니다」 → 이 층 끝 전투는 가려지지 않음', s.progress.omen === true && has(s, /전조를 보았습니다/));
  await H.open('scene=room:prayer&guides=reset');
  s = await H.advanceAll(s => s.stage === 'battle:prayer' && s.battle, 90000, '기도실 전투 시작');
  const d2 = s.party.deck;   // 전투 시작 때 덱 수
  let sawPick2 = false;
  s = await H.fight(s => { if (s.picker) sawPick2 = true; return (s.log || []).includes('win prayer'); }, 180000, '기도실 전투 승리');
  s = await H.until(s => s.scene === 'map', 60000, '기도실 → 지도', async s => {
    if (s.picker) sawPick2 = true;
    if (s.guideOpen || s.dialogBusy || s.vn) await H.W('advance');
  });
  await H.sleep(300);
  await H.shot('C06_prayer_win_no_reward.png');
  check('기도실 전투 승리 → 카드 보상 화면 없이 지도로, 덱 그대로', !sawPick2 && s.party.deck === d2
    && !(s.log || []).some(l => /overlay cardPick|^reward|^win card|card gain/.test(l)), { d2, d: s.party.deck, sawPick2 });
  // 무덤지기(강적) [기본안]: 고르는 화면 없이 희귀 목록의 카드 1장이 강화된 채 바로 덱에 (카드 획득 연출 + 「○○ Lv2 — 덱에 들어왔다」)
  await H.open('scene=room:gravekeeper&guides=reset');
  s = await H.advanceAll(s => s.stage === 'battle:gravekeeper' && s.battle, 90000, '무덤지기 전투 시작');
  const d3 = s.party.deck;   // 전투 시작 때 덱 수 (승리와 카드 얻기는 거의 같은 순간이라 승리 때 재면 이미 +1)
  let sawPick3 = false;
  s = await H.fight(s => { if (s.picker) sawPick3 = true; return (s.log || []).includes('win gravekeeper'); }, 240000, '무덤지기 승리');
  s = await H.until(s => (s.log || []).some(l => /^card gain inherit /.test(l)), 30000, '무덤지기 → 카드 얻기', async s => {
    if (s.picker) sawPick3 = true;
    if (s.guideOpen || s.dialogBusy) await H.W('advance');
  });
  await H.sleep(700);
  await H.shot('C07_gravekeeper_card_gain.png');
  s = await H.until(s => s.scene === 'map', 60000, '무덤지기 → 지도', async s => {
    if (s.picker) sawPick3 = true;
    if (s.guideOpen || s.dialogBusy || s.vn) await H.W('advance');
  });
  const wl = (s.log || []).find(l => /^win card /.test(l)) || '';
  const wm = /^win card (\S+) up$/.exec(wl);
  check('무덤지기(강적) 승리 → 고르는 화면 없이 희귀 목록의 카드 1장이 강화된 채 덱에(덱 +1)', !sawPick3 && s.party.deck === d3 + 1
    && !!wm && ['holy_slash', 'snipe', 'cover', 'curse_flame'].includes(wm[1]) && (s.log || []).includes('card gain inherit ' + wm[1]), { d3, d: s.party.deck, wl, sawPick3 });
  await page.close();
}

// ───────── 경로 D: 휴대폰 가로 (돌아가게만 — PC 기준) ─────────
async function pathD(browser) {
  say('경로 D: 휴대폰 가로(iPhone 13) 터치 — 작은 화면 글씨, 터치 탭·터치 드래그로 카드 내기, 지도 터치, 세로 화면 "가로로 돌려 주세요"');
  const dev = devices['iPhone 13 landscape'] || { viewport: { width: 844, height: 390 }, deviceScaleFactor: 3, isMobile: true, hasTouch: true };
  const ctx = await browser.newContext({ ...dev });
  const page = await ctx.newPage();
  const H = helpers(page, 'D');
  await H.open('guides=reset');
  let s = await H.until(s => s.scene === 'title', 30000, '타이틀');
  check('작은 화면 감지 → 글씨 배율 확대', s.small && s.ui >= 1.6, { css: s.cssScale, ui: s.ui, card: s.cardPreview });
  const btn = await H.W('geom', 'button', 'start');
  await H.touchTap(btn.x, btn.y);
  s = await H.until(s => s.scene === 'vn:camp' && s.vn, 15000, '터치로 시작');
  check('터치 탭으로 시작', true);
  for (let i = 0; i < 6; i++) { await H.touchTap(960, 300); await H.sleep(150); }
  await H.sleep(500);
  await H.shot('D01_phone_camp_text.png');
  // 메뉴 단추(오른쪽 위): 건너뛰기 단추와 누르는 영역(실제 화면 44px 이상)까지 겹치지 않고, 터치로 일시정지 → 계속
  s = await H.state();
  {
    const mb = await H.W('geom', 'button', 'menu'), sk = await H.W('geom', 'button', 'skip');
    check('휴대폰 곁방: 메뉴 단추가 건너뛰기 단추와 겹치지 않음(누르는 영역 포함)', mb.x && sk.x && !H.overlap(mb, sk, s.cssScale), { mb, sk });
    await H.touchTap(mb.x, mb.y);
    s = await H.until(s => s.menu.paused && s.menu.panel === 'pause', 5000, '터치로 일시정지');
    await H.shot('D01b_phone_pause.png');
    const rb = await H.W('geom', 'button', 'resume');
    await H.touchTap(rb.x, rb.y);
    s = await H.until(s => !s.menu.paused && !s.menu.treePaused, 5000, '계속');
    check('휴대폰: 메뉴 단추 터치 → 일시정지 → 「계속」', s.menu.corner && s.scene === 'vn:camp');
  }
  await H.open('scene=corridor&guides=reset');
  await H.until(s => s.stage === 'battle:normal' && s.battle && s.battle.turn === 1 && s.guideOpen, 90000, '안내', async s => { if (s.vn || (s.dialogBusy && !s.guideOpen) || (s.guideOpen && (!s.battle || s.battle.turn < 1))) await H.touchTap(960, 560); });
  await H.sleep(800);
  await H.shot('D02_phone_guide_box.png');
  s = await H.until(s => s.battle && s.battle.turn === 1 && !s.busy && !s.guideOpen && !s.dialogBusy, 60000, '1턴', async s => { if (s.guideOpen || s.dialogBusy) await H.touchTap(960, 560); });
  check('안내 상자를 터치 탭으로 넘김', true);
  const hs = await H.W('geom', 'card', 'holy_slash');
  const p = await H.toPage(hs.x, hs.y);
  H.cdp = H.cdp || await page.context().newCDPSession(page);
  await H.cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: p.x, y: p.y }] });
  await H.sleep(400);
  await H.shot('D03_phone_card_preview.png');
  await H.cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
  await H.sleep(300);
  const en = await H.W('geom', 'enemy', 'c2');
  {
    const a = await H.toPage(hs.x, hs.y), b = await H.toPage(en.x, en.y);
    await H.cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: a.x, y: a.y }] });
    for (let i = 1; i <= 7; i++) {
      await H.sleep(20);
      await H.cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ x: a.x + (b.x - a.x) * i / 14, y: a.y + (b.y - a.y) * i / 14 }] });
    }
    await H.sleep(300);
    const m = await H.state();
    const hsUid = (m.battle.hand.find(c => c.id === 'holy_slash') || {}).uid;
    const g = H.gripOk(m, hsUid);
    check('휴대폰: 대상 고르는 중엔 카드 확대 해제 → 오른손이 그 카드를 손패 높이에서 작게 쥠(손은 둘)', g.ok, g.detail);
    for (let i = 8; i <= 14; i++) {
      await H.sleep(20);
      await H.cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ x: a.x + (b.x - a.x) * i / 14, y: a.y + (b.y - a.y) * i / 14 }] });
    }
    await H.sleep(30);
    await H.cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
  }
  s = await H.until(s => !s.busy && s.battle.enemies.find(e => e.id === 'c2').alive === false, 20000, '터치 드래그');
  check('터치 드래그로 성검 베기 → 광신도 처치', true);
  const h = await H.handsOk('휴대폰');
  check('휴대폰에서도 손은 둘 이하', h.ok, h.detail);
  await H.shot('D04_phone_battle.png');
  {
    const mb = await H.W('geom', 'button', 'menu'), et = await H.W('geom', 'endTurn');
    check('휴대폰 전투: 메뉴 단추가 보이고 턴 종료 단추와 겹치지 않음', mb.x && !H.overlap(mb, { x: et.x, y: et.y, w: 200, h: 90 }, s.cssScale), { mb, et });
  }
  // 지도: 터치 두 번으로 방에 들어간다
  await H.open('scene=map&guides=reset');
  s = await H.until(s => s.scene === 'map' && s.map && !s.map.busy, 30000, '지도');
  await H.sleep(500);
  await H.shot('D05_phone_map.png');
  {
    s = await H.state();
    const mb = await H.W('geom', 'button', 'menu');
    // 지도에서는 오른쪽 칸(층 이름 줄) 오른쪽 끝 — 칸 안, 이름 줄 아래 선(y 124) 위
    check('휴대폰 지도: 메뉴 단추가 오른쪽 칸의 층 이름 줄 안', mb.x && mb.x - mb.w / 2 >= 1440 && mb.x + mb.w / 2 <= 1880 && mb.y - mb.h / 2 >= 40 && mb.y + mb.h / 2 <= 124, mb);
  }
  const rc = await H.W('geom', 'room', 'chapel');
  const rs = await H.W('geom', 'room', 'stairs');
  await H.touchTap(rc.x, rc.y);
  await H.sleep(300);
  s = await H.state();
  check('휴대폰 지도: 아직 갈 수 없는 방(예배당)은 들어가지 않는다', s.scene === 'map' && s.progress.candles === 4);
  await H.touchTap(rs.x, rs.y);
  await H.sleep(300);
  await H.touchTap(rs.x, rs.y);
  s = await H.until(s => s.scene === 'vn:stairs', 20000, '계단 앞 홀(터치)');
  check('휴대폰 지도: 방을 두 번 터치하면 들어간다', s.progress.candles === 3);
  await page.setViewportSize({ width: 390, height: 844 });
  await H.sleep(800);
  await H.shot('D06_phone_portrait_rotate.png');
  await ctx.close();
}

// ───────── 경로 E: 느린 속도 연출 스크린샷 (손 들기 중간·컷인·동료 타격) ─────────
async function pathE(browser) {
  say('경로 E: 느린 속도 연출 — 오른손이 빠짐 → 세운 손 → 컷인 → 타격');
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: 1 });
  const H = helpers(page, 'E');
  await H.open('scene=corridor&autoguide=1');
  let s = await H.until(s => s.battle && s.battle.turn === 1 && !s.busy && !s.guideOpen && !s.dialogBusy, 120000, '1턴');
  await H.W('setSpeed', 0.12);
  await H.W('play', 'curse_flame', JSON.stringify({ enemy: 'c1' }));
  await H.sleep(700);
  await H.shot('E01_right_hand_out.png');
  let h = await H.handsOk('오른손이 빠지는 중');
  await H.sleep(1500);
  await H.shot('E02_raised_card.png');
  await H.until(s => s.cutinActive, 20000, '컷인 시작');
  await H.sleep(1600);
  await H.shot('E03_cutin_curse_flame.png');
  s = await H.until(s => !s.busy, 60000, '불꽃 끝');
  await H.W('play', 'shield_bash', JSON.stringify({ enemy: 'c3' }));
  await H.sleep(4700);
  await H.shot('E04_warrior_strike.png');
  s = await H.until(s => !s.busy, 60000, '방패 강타 끝');
  h = await H.handsOk('느린 속도 전체');
  check('느린 속도에서도 손은 언제나 둘 이하', h.ok, h.detail);
  check('저주의 불꽃 컷인(노엘)', s.cutinLog.includes('curse_flame'), s.cutinLog);
  await page.close();
}

// ───────── 경로 F: 2·3층 운명 (받아들인다 / 거스른다 — 2026-11-21 죽음 카드 컨셉 변경) ─────────
async function pathF(browser) {
  say('경로 F: 2층(VN 전조 → 납골당 2턴 「운명의 관통」 받아들임) → 계단(엘리안 운명) → 3층 → 화형대(운명의 불길 거스름) → 결과 → 3층 PC(엘리안 거스름 → 브룬힐드 Lv2 받아들임, 죽음 카드는 낼 수 없음) → 집행자를 먼저 쓰러뜨림');
  const dev = devices['iPhone 13 landscape'] || { viewport: { width: 844, height: 390 }, deviceScaleFactor: 3, isMobile: true, hasTouch: true };
  const ctx = await browser.newContext({ ...dev });
  const page = await ctx.newPage();
  const H = helpers(page, 'F');
  await H.open('scene=floor2&guides=reset');
  let s = await H.advanceAll(s => s.stage === 'battle:ossuary' && s.battle && s.battle.turn === 1 && !s.busy && !s.guideOpen && !s.dialogBusy, 90000, '2층 → 납골당 전투');
  check('2층: 탑뷰 없이 VN(창 함정 회랑 — 전조 속마음) → 납골당 VN → 같은 배경에서 전투', has(s, /이 층이다/) && has(s, /원정대였던 것/) && !s.topdown);
  await H.shot('F01_phone_ossuary_battle.png');
  const oh = s.battle.hand.map(c => c.id);
  check('납골당 1턴: 손패에 브룬힐드 죽음 카드(앞면, 낼 수 없음) + 새로 4장 + 「낼 수 없습니다」 안내', oh.includes('warrior_death') && oh.length === 5
    && !s.battle.hand.find(c => c.id === 'warrior_death').playable && has(s, /손패의 죽음 카드는 낼 수 없습니다/), oh);
  await H.W('endTurn');
  s = await H.advanceAll(s => s.battle && s.battle.turn === 2 && s.battle.phase === 'player' && !s.busy && !s.guideOpen && !s.dialogBusy, 60000, '2턴');
  const ki = s.battle.enemies.find(e => e.id === 'k1').intent;
  check('2턴 예고: 창 기사 「운명의 관통 → 브룬힐드」 치명·옮기기 불가', ki && ki.kind === 'fate' && ki.target === 'warrior' && ki.label === '운명의 관통' && !ki.redirectable && ki.lethal, ki);
  await H.W('endTurn');
  s = await H.until(s => s.fatePicker, 60000, '운명의 시도(납골당)', async s => { if (s.guideOpen || s.dialogBusy) await H.W('advance'); });
  await H.sleep(600);
  await H.shot('F02_phone_fate_choice.png');
  check('운명의 시도 안내: 받아들인다 / 거스른다', has(s, /받아들인다\*\*: 그 동료는 그 방식으로 죽고/));
  const ob = await H.W('geom', 'fateBtn', 'offer');
  check('선택 화면: [받아들인다 — 브룬힐드의 죽음] [거스른다 (흉터 1)]', ob && ob.x > 0 && ob.h >= 40, ob);
  await H.touchTap(ob.x, ob.y);
  s = await H.until(s => (s.cutLog || []).includes('W1'), 20000, '데스신');
  await H.sleep(1200);
  await H.shot('F03_phone_death_pierced.png');
  s = await H.advanceAll(s => s.battle && s.battle.hand.some(c => c.id === 'pierced_shield') && !s.busy && !s.dialogBusy && !s.guideOpen, 90000, '꿰뚫린 방패');
  const fw = s.fates.find(f => f.who === 'warrior');
  check('받아들임(전투): 데스신 → 브룬힐드 사망 → 「꿰뚫린 방패」 Lv1 손패, 흉터 0',
    s.cutLog.includes('W2') && s.party.allies.warrior.status === 'dead' && fw.result === 'offered' && s.battle.hand.find(c => c.id === 'pierced_shield').lv === 1 && s.scars === 0, { fw });
  await H.W('winBattle');
  s = await H.advanceAll(s => s.fates && s.fates.some(f => f.who === 'archer') && s.vn && s.vn.omen, 90000, '엘리안 운명');
  await H.sleep(2600);
  await H.shot('F04_phone_stairs_archer.png');
  const fa = s.fates.find(f => f.who === 'archer');
  check('2층 계단: 브룬힐드가 없으니 엘리안 화형 Lv1(3층)만', fa.level === 1 && fa.floor === 3, fa);
  s = await H.advanceAll(s => s.stage === 'battle:pyre' && s.battle && s.battle.turn === 1 && !s.busy && !s.guideOpen && !s.dialogBusy, 90000, '3층 → 화형대 전투');
  check('3층: VN(예배당 전조 — 엘리안만) → 화형대 VN → 전투', s.progress.floor === 3 && has(s, /엘리안의 불도/) && !has(s, /쇠꼬챙이/));
  await H.W('endTurn');
  s = await H.advanceAll(s => s.battle && s.battle.turn === 2 && s.battle.phase === 'player' && !s.busy && !s.guideOpen && !s.dialogBusy, 60000, '2턴');
  const pi = s.battle.enemies.find(e => e.id === 'p1').intent;
  await H.shot('F05_phone_fate_fire_intent.png');
  check('2턴 예고: 「운명의 불길 → 엘리안」 치명·옮기기 불가', pi && pi.kind === 'fate' && pi.target === 'archer' && !pi.redirectable && pi.lethal, pi);
  await H.W('endTurn');
  s = await H.until(s => s.fatePicker, 60000, '전투 중 운명의 시도', async s => { if (s.guideOpen || s.dialogBusy) await H.W('advance'); });
  await H.sleep(500);
  const db = await H.W('geom', 'fateBtn', 'defy');
  await H.touchTap(db.x, db.y);
  s = await H.advanceAll(s => s.battle && s.battle.turn === 3 && s.battle.phase === 'player' && !s.busy && !s.guideOpen && !s.dialogBusy, 90000, '거스른 뒤 3턴');
  await H.shot('F06_phone_after_defy.png');
  check('거스름(전투): 엘리안 생존 · 흉터 1장 · 운명은 미뤄짐', s.party.allies.archer.status !== 'dead' && s.scars === 1 && s.fates.find(f => f.who === 'archer').alive
    && s.fates.find(f => f.who === 'archer').triedFloor === 3, { a: s.party.allies.archer, scars: s.scars });
  await H.W('winBattle');
  s = await H.until(s => s.scene === 'result', 60000, '결과 요약', async s => { if (s.guideOpen || s.dialogBusy) await H.W('advance'); });
  await H.sleep(1500);
  await H.shot('F07_phone_result.png');
  check('결과 요약 화면(흉터 1)', s.scars === 1, s.fates);
  const r2 = await H.W('geom', 'button', 'floor2');
  await H.touchTap(r2.x, r2.y);
  s = await H.until(s => s.scene === 'vn:f2corridor', 30000, '2층부터 다시');
  check('「2층부터 다시」 → 2층 회랑, 브룬힐드 살아 있고 운명 Lv1', s.party.allies.warrior.status === 'ok' && s.fates.filter(f => f.alive).length === 1 && s.fates.find(f => f.who === 'warrior').level === 1);
  await ctx.close();
  // PC: 3층(브룬힐드 생존) — 두 운명이 화형대 한 전투에: 2턴 엘리안(거스름) → 3턴 브룬힐드 Lv2(받아들임). 죽음 카드는 낼 수 없다
  const page2 = await browser.newPage({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: 1 });
  const H2 = helpers(page2, 'F2');
  await H2.open('scene=floor3&brun=alive&guides=reset');
  s = await H2.advanceAll(s => s.stage === 'battle:pyre' && s.battle && s.battle.turn === 1 && !s.busy && !s.guideOpen && !s.dialogBusy, 90000, '3층 → 화형대');
  check('3층 예배당 전조: 브룬힐드·엘리안 둘 다', has(s, /쇠꼬챙이/) && has(s, /엘리안의 불도/) && s.scars === 1);
  const h2 = s.battle.hand;
  check('화형대 1턴: 두 죽음 카드(전사 Lv2·궁수 Lv1, 낼 수 없음) + 새로 3장', h2.length === 5 && h2.some(c => c.id === 'warrior_death' && c.lv === 2 && !c.playable) && h2.some(c => c.id === 'archer_death' && c.lv === 1 && !c.playable), h2.map(c => c.id + c.lv));
  await H2.shot('F08_pyre_two_death_cards.png');
  // 죽음 카드를 실제로 끌어 올려도 낼 수 없다
  const ad = await H2.W('geom', 'card', 'archer_death');
  await H2.drag({ x: ad.x, y: ad.y }, { x: ad.x - 80, y: 360 }, 10);
  await H2.sleep(700);
  s = await H2.state();
  check('죽음 카드(앞면)를 끌어 올려도 낼 수 없다 — 엘리안 생존', s.party.allies.archer.status === 'ok' && s.battle.hand.some(c => c.id === 'archer_death') && !s.busy);
  await H2.W('endTurn');
  s = await H2.until(s => s.fatePicker, 90000, '2턴 엘리안 시도', async s => {
    if (s.guideOpen || s.dialogBusy) await H2.W('advance');
    else if (s.battle && s.battle.turn === 2 && s.battle.phase === 'player' && !s.busy) await H2.W('endTurn');
  });
  await H2.sleep(400);
  const dbt = await H2.W('geom', 'fateBtn', 'defy');
  await H2.click(dbt.x, dbt.y);
  s = await H2.advanceAll(s => s.battle && s.battle.turn === 3 && s.battle.phase === 'player' && !s.busy && !s.guideOpen && !s.dialogBusy, 90000, '3턴');
  const t3 = s.battle.enemies.find(e => e.id === 'p1').intent;
  check('3턴 예고: 화형 사제 「운명의 꼬챙이 → 브룬힐드」 Lv2', t3 && t3.kind === 'fate' && t3.target === 'warrior' && t3.level === 2, t3);
  await H2.W('endTurn');
  s = await H2.until(s => s.fatePicker, 60000, '3턴 브룬힐드 시도', async s => { if (s.guideOpen || s.dialogBusy) await H2.W('advance'); });
  await H2.sleep(500);
  await H2.shot('F09_choice_lv2.png');
  const ob2 = await H2.W('geom', 'fateBtn', 'offer');
  await H2.click(ob2.x, ob2.y);
  s = await H2.until(s => (s.cutLog || []).includes('W1'), 20000, 'Lv2 데스신');
  await H2.sleep(1500);
  await H2.shot('F10_death_lv2.png');
  s = await H2.advanceAll(s => s.battle && s.battle.hand.some(c => c.id === 'pierced_shield') && !s.busy && !s.dialogBusy && !s.guideOpen, 90000, '받아들인 뒤');
  check('브룬힐드 Lv2 받아들임(전투): 사망, 「꿰뚫린 방패」 Lv2 손패', s.party.allies.warrior.status === 'dead' && s.fates.find(f => f.who === 'warrior').result === 'offered'
    && s.battle.hand.find(c => c.id === 'pierced_shield').lv === 2, s.battle.hand.map(c => c.id + c.lv));
  // 집행자를 먼저 쓰러뜨리면: 쓰러지는 순간 운명의 시도 (2층 납골당, 1턴)
  await H2.open('scene=ossuary&guides=reset');
  s = await H2.advanceAll(s => s.stage === 'battle:ossuary' && s.battle && s.battle.turn === 1 && !s.busy && !s.guideOpen && !s.dialogBusy, 90000, '납골당 전투(PC)');
  await H2.W('enemyHp', 'k1', 3);
  const atk = s.battle.hand.find(c => c.playable && ['holy_slash', 'snipe', 'suppress', 'shield_bash', 'curse_flame', 'broken_sword'].includes(c.id));
  await H2.W('play', atk.id, JSON.stringify({ enemy: 'k1' }));
  s = await H2.until(s => s.fatePicker, 30000, '쓰러지며 온 운명', async s => { if (s.guideOpen || s.dialogBusy) await H2.W('advance'); });
  await H2.sleep(500);
  await H2.shot('F11_executor_down_choice.png');
  check('집행자(창 기사)를 1턴에 쓰러뜨림 → 그 순간 운명의 시도 + 대사', (s.log || []).some(l => /fate trial battle warrior_pierce lv1 byDeath/.test(l)) && has(s, /쓰러지면서도/), s.log.slice(-6));
  const dd = await H2.W('geom', 'fateBtn', 'defy');
  await H2.click(dd.x, dd.y);
  s = await H2.advanceAll(s => s.battle && s.battle.phase === 'player' && !s.busy && !s.guideOpen && !s.dialogBusy && !s.fatePicker && !s.overlay, 60000, '거스른 뒤');
  check('쓰러지며 온 시도 거스름: 브룬힐드 생존·흉터 1, 전투 계속(광신도)', s.party.allies.warrior.status !== 'dead' && s.scars === 1 && !s.battle.result, { scars: s.scars });
  await page2.close();
}

// ───────── 경로 S: 기본 기능 — 타이틀·설정·일시정지·자동 저장·이어하기 (웹: 새로고침 뒤 이어하기) ─────────
async function pathS(browser) {
  say('경로 S: 타이틀(이어하기 꺼짐) → 설정(전체 화면·글자 속도, Esc 로 닫기) → 시작 → 일시정지(Esc, 멈춤) → 계속 → 장례 회랑(자동 저장) → 새로고침 → 이어하기 → 같은 방'
    + ' → 일시정지 → 타이틀로(확인) → 시작(저장 지움 확인: 취소 → 처음부터) / 휴대폰: 타이틀·설정·메뉴 단추로 일시정지');
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: 1 });
  const page = await ctx.newPage();
  const H = helpers(page, 'S');
  const clickBtn = async id => { const g = await H.W('geom', 'button', id); if (!g || g.x === undefined) throw new Error('단추 없음: ' + id); await H.click(g.x, g.y); return g; };
  await H.open('guides=reset');
  let s = await H.until(s => s.scene === 'title', 30000, '타이틀');
  await H.sleep(600);
  await H.shot('S01_title_no_save.png');
  const gq = await H.W('geom', 'button', 'quit'), gc = await H.W('geom', 'button', 'continue');
  check('타이틀: 시작·이어하기·설정, 웹에서는 끝내기 없음, 메뉴 단추 없음', (await H.W('geom', 'button', 'start')).x > 0 && (await H.W('geom', 'button', 'settings')).x > 0 && !gq.x && !s.menu.corner, { gq });
  check('저장이 없으면 이어하기가 흐리고 꺼져 있음', !s.menu.hasSave && gc.disabled === true && !s.menu.continueEnabled, gc);
  await H.click(gc.x, gc.y);
  await H.sleep(800);
  s = await H.state();
  check('꺼진 이어하기를 눌러도 타이틀 그대로', s.scene === 'title' && s.menu.panel === '');
  // 설정: 전체 화면(웹은 단추를 누른 그 처리 안에서 요청) 켜고 끄기 · 글자 속도
  await clickBtn('settings');
  s = await H.until(s => s.menu.panel === 'settings', 5000, '설정 열림');
  await H.sleep(500);
  await H.shot('S02_settings.png');
  check('설정: 화면(창·전체 화면)·글자 속도(느림·보통·빠름·즉시)·닫기, 소리 항목 없음', ['display_windowed', 'display_fullscreen', 'speed_slow', 'speed_normal', 'speed_fast', 'speed_instant', 'close'].every(b => s.menu.buttons.includes(b)) && s.menu.buttons.length === 7, s.menu.buttons);
  await clickBtn('display_fullscreen');
  const fsOn = await page.waitForFunction(() => !!document.fullscreenElement, null, { timeout: 8000 }).then(() => true, () => false);
  s = await H.until(s => s.menu.fullscreen || !fsOn, 5000, '전체 화면');
  await H.sleep(800);
  await clickBtn('display_windowed');
  const fsOff = await page.waitForFunction(() => !document.fullscreenElement, null, { timeout: 8000 }).then(() => true, () => false);
  s = await H.until(s => !s.menu.fullscreen, 5000, '창');
  check('웹: 「전체 화면」 클릭 → 브라우저 전체 화면, 「창」 → 돌아옴', fsOn && fsOff, { fsOn, fsOff });
  await clickBtn('speed_fast');
  s = await H.until(s => s.menu.textSpeed === 'fast', 5000, '글자 속도');
  check('글자 속도 「빠름」 → 대사 글자 속도 2배', s.menu.cps === 76, s.menu.cps);
  await page.keyboard.press('Escape');
  s = await H.until(s => s.menu.panel === '', 5000, 'Esc 로 설정 닫기');
  check('Esc 로 설정을 닫으면 타이틀(일시정지 아님)', s.scene === 'title' && !s.menu.paused);
  // 시작 → 곁방(자동 저장) → Esc 일시정지
  await clickBtn('start');
  s = await H.until(s => s.scene === 'vn:camp' && s.vn && s.vn.line >= 0, 15000, '곁방');
  check('저장이 없으면 확인 없이 시작 → 곁방, 들어가며 자동 저장', s.menu.panel === '' && s.menu.hasSave && s.menu.saveStep === 'camp' && s.menu.corner, s.menu);
  await H.sleep(300);
  await page.keyboard.press('Escape');
  s = await H.until(s => s.menu.paused && s.menu.panel === 'pause', 5000, 'Esc 일시정지');
  const line0 = s.vn.line, log0 = (s.log || []).length, typing0 = s.vn.typing;
  await H.sleep(500);
  await H.shot('S03_pause.png');
  await H.sleep(1200);
  s = await H.state();
  check('Esc → 일시정지(계속·설정·타이틀로): 멈춘 동안 대사·진행이 그대로', s.menu.treePaused && s.vn.line === line0 && (s.log || []).length === log0 && s.vn.typing === typing0
    && ['resume', 'settings', 'toTitle'].every(b => s.menu.buttons.includes(b)), { line0, line: s.vn.line, log0, log: (s.log || []).length });
  await clickBtn('settings');
  s = await H.until(s => s.menu.panel === 'settings', 5000, '일시정지 → 설정');
  check('일시정지에서 설정(같은 화면) — 글자 속도가 「빠름」으로 남아 있음', s.menu.treePaused && s.menu.textSpeed === 'fast');
  await clickBtn('close');
  s = await H.until(s => s.menu.panel === 'pause', 5000, '설정 닫기 → 일시정지');
  await clickBtn('resume');
  s = await H.until(s => !s.menu.paused && !s.menu.treePaused && s.menu.panel === '', 5000, '계속');
  check('「계속」 → 이어짐', s.scene === 'vn:camp');
  // 장례 회랑(방)에 들어가면 자동 저장 → 새로고침 → 이어하기
  s = await H.advanceAll(s => s.scene === 'vn:corridor' && s.vn && s.vn.line >= 1, 90000, '장례 회랑');
  check('장례 회랑에 들어가면 자동 저장(장례 탑 1층 · 장례 회랑)', s.menu.saveStep === 'corridor' && /장례 회랑/.test(s.menu.place), s.menu);
  await H.sleep(2000);   // 웹: user:// 가 브라우저 저장소(IndexedDB)에 옮겨 적힐 시간
  await H.open('');
  s = await H.until(s => s.scene === 'title', 30000, '새로고침 뒤 타이틀');
  await H.sleep(600);
  await H.shot('S04_title_continue.png');
  check('새로고침 뒤 타이틀: 이어하기 켜짐 + 저장한 곳, 설정(글자 속도)도 남음', s.menu.continueEnabled && s.menu.saveStep === 'corridor' && s.menu.textSpeed === 'fast', s.menu);
  await clickBtn('continue');
  s = await H.until(s => s.scene === 'vn:corridor' && s.vn, 20000, '이어하기');
  check('이어하기 → 같은 방(장례 회랑)의 처음부터', s.vn.line <= 1 && s.progress.room === 'corridor' && (s.log || []).some(l => /^continue corridor/.test(l)), { line: s.vn.line, room: s.progress.room });
  // 일시정지 → 타이틀로 (확인 한 번)
  await page.keyboard.press('Escape');
  await H.until(s => s.menu.panel === 'pause', 5000, '일시정지');
  await clickBtn('toTitle');
  s = await H.until(s => s.menu.panel === 'confirm', 5000, '타이틀로 확인');
  await H.sleep(300);
  await H.shot('S05_to_title_confirm.png');
  check('타이틀로: 「진행은 마지막 자동 저장까지만 남습니다」 확인 창', s.menu.buttons.includes('yes') && s.menu.buttons.includes('no'));
  await clickBtn('no');
  s = await H.until(s => s.menu.panel === 'pause', 5000, '취소 → 일시정지');
  await clickBtn('toTitle');
  await H.until(s => s.menu.panel === 'confirm', 5000, '다시 확인');
  await clickBtn('yes');
  await H.sleep(1500);
  await page.waitForFunction(() => window.__witchReady === true, null, { timeout: 30000 });
  s = await H.until(s => s.scene === 'title', 20000, '타이틀로 돌아감');
  check('확인 → 타이틀(일시정지 풀림), 저장은 장례 회랑 그대로', !s.menu.paused && !s.menu.treePaused && s.menu.continueEnabled && s.menu.saveStep === 'corridor', s.menu);
  // 저장이 있을 때 시작: 저장이 지워진다는 확인 → 취소 → 다시 → 처음부터
  await clickBtn('start');
  s = await H.until(s => s.menu.panel === 'confirm', 5000, '새로 시작 확인');
  await H.sleep(300);
  await H.shot('S06_new_game_confirm.png');
  await clickBtn('no');
  s = await H.until(s => s.menu.panel === '', 5000, '취소');
  check('저장이 있으면 시작 전에 확인 → 취소하면 타이틀·저장 그대로', s.scene === 'title' && s.menu.saveStep === 'corridor');
  await clickBtn('start');
  await H.until(s => s.menu.panel === 'confirm', 5000, '새로 시작 확인 2');
  await clickBtn('yes');
  s = await H.until(s => s.scene === 'vn:camp', 15000, '처음부터');
  check('확인하면 처음부터(곁방), 저장은 곁방으로 새로', s.menu.saveStep === 'camp' && s.progress.room === 'camp', s.menu);
  await ctx.close();
  // 휴대폰(iPhone 13 가로): 타이틀·설정·메뉴 단추로 일시정지 (스크린샷)
  const dev = devices['iPhone 13 landscape'] || { viewport: { width: 844, height: 390 }, deviceScaleFactor: 3, isMobile: true, hasTouch: true };
  const ctx2 = await browser.newContext({ ...dev });
  const page2 = await ctx2.newPage();
  const P = helpers(page2, 'S2');
  await P.open('guides=reset');
  s = await P.until(s => s.scene === 'title', 30000, '휴대폰 타이틀');
  await P.sleep(600);
  await P.shot('S11_phone_title.png');
  let g = await P.W('geom', 'button', 'settings');
  await P.touchTap(g.x, g.y);
  s = await P.until(s => s.menu.panel === 'settings', 5000, '휴대폰 설정');
  await P.sleep(600);
  await P.shot('S12_phone_settings.png');
  g = await P.W('geom', 'button', 'close');
  await P.touchTap(g.x, g.y);
  await P.until(s => s.menu.panel === '', 5000, '휴대폰 설정 닫기');
  g = await P.W('geom', 'button', 'start');
  await P.touchTap(g.x, g.y);
  s = await P.until(s => s.scene === 'vn:camp' && s.menu.corner, 15000, '휴대폰 곁방');
  await P.sleep(400);
  g = await P.W('geom', 'button', 'menu');
  await P.touchTap(g.x, g.y);
  s = await P.until(s => s.menu.paused && s.menu.panel === 'pause', 5000, '휴대폰 일시정지');
  await P.sleep(400);
  await P.shot('S13_phone_pause.png');
  check('휴대폰: 타이틀 설정 열고 닫기 → 시작 → 메뉴 단추 터치로 일시정지', s.menu.treePaused);
  await ctx2.close();
  // 연출 도중 일시정지: 카드 연출(손 들기·컷인·타격) · 데스신 — 멈춘 동안 그대로, 「계속」하면 이어서 끝난다
  const ctx3 = await browser.newContext({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: 1 });
  const page3 = await ctx3.newPage();
  const Q = helpers(page3, 'S3');
  await Q.open('scene=corridor&autoguide=1&nosave=1');
  s = await Q.until(s => s.battle && s.battle.turn === 1 && !s.busy && !s.guideOpen && !s.dialogBusy, 120000, '전투 1턴');
  const c1hp = s.battle.enemies.find(e => e.id === 'c1').hp;
  await Q.W('setSpeed', 0.3);
  await Q.W('play', 'curse_flame', JSON.stringify({ enemy: 'c1' }));
  await Q.sleep(500);
  g = await Q.W('geom', 'button', 'menu');
  await Q.click(g.x, g.y);
  s = await Q.until(s => s.menu.paused, 5000, '카드 연출 중 일시정지');
  const frozen = JSON.stringify([s.busy, s.raiseLog, s.cutinLog, s.motionLog, s.battle.enemies.map(e => e.hp), s.log.length]);
  await Q.sleep(500);
  await Q.shot('S20_pause_during_card.png');
  await Q.sleep(2000);
  s = await Q.state();
  const still = JSON.stringify([s.busy, s.raiseLog, s.cutinLog, s.motionLog, s.battle.enemies.map(e => e.hp), s.log.length]);
  check('카드 연출 도중 메뉴 단추(클릭) → 일시정지: 멈춘 동안 연출·전투 상태가 그대로', s.busy && still === frozen, { frozen, still });
  await page3.keyboard.press('Escape');
  s = await Q.until(s => !s.menu.paused, 5000, 'Esc 로 계속');
  await Q.W('setSpeed', 1);
  s = await Q.until(s => !s.busy, 60000, '카드 연출 끝');
  const c1 = s.battle.enemies.find(e => e.id === 'c1');
  check('Esc 로 계속 → 카드 연출이 이어서 끝남(저주의 불꽃 컷인·피해)', s.cutinLog.includes('curse_flame') && (!c1.alive || c1.hp < c1hp), { hp: c1.hp, c1hp });
  // 데스신 도중 (거대한 발 3턴 짓밟기 → 세라피나): 자동 진행으로 데스신까지
  await Q.open('scene=giant&autoguide=1&autoplay=1&nosave=1');
  s = await Q.until(s => s.scene === 'cutscene' && (s.cutLog || []).length >= 1, 240000, '데스신');
  await Q.sleep(600);
  await page3.keyboard.press('Escape');
  s = await Q.until(s => s.menu.paused, 5000, '데스신 일시정지');
  const cut0 = JSON.stringify([s.cutLog, s.log.length, (s.dialog || []).length]);
  await Q.sleep(500);
  await Q.shot('S21_pause_during_death_scene.png');
  await Q.sleep(3000);
  s = await Q.state();
  check('데스신 도중 Esc → 일시정지: 멈춘 동안 컷이 넘어가지 않음', s.scene === 'cutscene' && JSON.stringify([s.cutLog, s.log.length, (s.dialog || []).length]) === cut0, { cut0, now: s.cutLog });
  g = await Q.W('geom', 'button', 'resume');
  await Q.click(g.x, g.y);
  s = await Q.until(s => s.stage === 'vn:emptycamp' || s.scene === 'vn:emptycamp', 180000, '데스신 → 빈 곁방');
  check('「계속」 → 데스신 C1~C6 이 이어져 끝나고 빈 곁방으로', ['C1', 'C2', 'C3a', 'C3b', 'C4', 'C6'].every(c => s.cutLog.includes(c)) && s.party.allies.hero.status === 'dead', s.cutLog);
  await ctx3.close();
}

(async () => {
  const browser = await launch();
  const t0 = Date.now();
  const only = process.argv[4] || 'ABCDEFS';
  for (const [name, fn] of [['A', pathA], ['B', pathB], ['C', pathC], ['D', pathD], ['E', pathE], ['F', pathF], ['S', pathS]]) {
    if (!only.includes(name)) continue;
    try { await fn(browser); } catch (e) { check('경로 ' + name + ' 진행', false, e.message); }
  }
  await browser.close();
  check('브라우저 콘솔 에러 0', errors.length === 0, errors.slice(0, 8).join(' | '));
  const fails = results.filter(r => !r.ok).length;
  say(`smoke: ${results.length - fails} passed, failures: ${fails} (${Math.round((Date.now() - t0) / 1000)}s)`);
  fs.writeFileSync(path.join(SHOTS, 'smoke-log.txt'), log.join('\n') + '\n\n' + errors.join('\n'));
  fs.writeFileSync(path.join(SHOTS, 'smoke-results.json'), JSON.stringify({ results, errors }, null, 1));
  process.exit(fails ? 1 : 0);
})();
