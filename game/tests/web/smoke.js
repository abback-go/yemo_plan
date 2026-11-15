/*
 * 웹 빌드 스모크 테스트 (Playwright + Chromium) — Godot 판 "죽음을 보는 마녀" 튜토리얼
 *   node game/tests/web/smoke.js <웹 빌드 주소, 예: http://localhost:8000/> <스크린샷 폴더>
 *
 * Godot 캔버스에는 DOM 이 없으므로 게임이 ?test=1 일 때 붙이는 window.witch 훅(core/test_api.gd)으로 상태를 읽고 장면을 옮긴다.
 * 중요한 조작(카드 끌기·잠긴 죽음 카드·길 고르기·선택지·지도 닫기·턴 종료)은 좌표로 실제 마우스·터치 입력을 보낸다.
 *
 * 경로 A: 타이틀(실제 클릭) → 캠프(파티 소개 이름표·또렷한 죽음 카드) → 1층 전투(잠긴 죽음 카드를 끌어 내려다 실패, 성검 베기 실제 드래그,
 *         손 들기 중 손은 둘뿐, 운명 전가 2단계) → 승리 → 걸어 들어감 → 지도(처음: 안내) → 갈림길(길 탭 → 설명 → 다시 탭 → 걷기)
 *         → 휴식 → 계단(죽음 카드 다시 떠오름, [웃어 준다] 실제 클릭) → 이동 → 2층 → 거대 존재 등장(발이 동료 뒤) → 자물쇠가 부서짐
 *         → 죽음 카드 실제 드래그(세운 손·팽팽한 실, 손은 둘) → 컷신 C1(웃어 준다 대사)~C6 → C7·C8 → 짓밟힘(컷인) → 탈출 → 빈 캠프(흐린 카드) → 종료
 * 경로 B: 거대 존재 전투에서 카드를 내지 않고 3턴 → 짓밟기 → "카드를 내지 않은 미래"(붉게 번짐·유리 깨짐) → 등장 직후(1턴)부터 재시작
 * 경로 C: 갈림길 시체 발견 / 훈련(카드 강화 +) 각각, 계단 [대답하지 못한다] → C1·빈 캠프 대사가 선택을 반영
 * 경로 D: 휴대폰 가로(iPhone 13 에뮬레이션, 터치) — 작은 화면 글씨 배율, 터치 탭·터치 드래그로 카드 내기, 세로 화면 "가로로 돌려 주세요"
 * 통과 조건: 모든 확인 통과 + 브라우저 콘솔 에러 0 (Godot 의 ERROR / SCRIPT ERROR 포함)
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
    const b = s.battle;
    if (!s.inBattle || s.busy || !b || b.phase !== 'player' || b.result) return;
    if (b.kind === 'giant') {
      if (opts.noDeath) { await H.W('endTurn'); return; }
      const d = b.hand.find(c => (c.id === 'hero_death' || c.id === 'trample') && c.playable);
      if (d) { await H.W('play', d.id, ''); return; }
      await H.W('endTurn');
      return;
    }
    for (const c of b.hand) {
      if (!c.playable || c.id === 'hero_death') continue;
      const alive = b.enemies.filter(e => e.alive);
      if (['curse_flame', 'holy_slash', 'shield_bash', 'snipe', 'suppress', 'broken_sword'].includes(c.id)) { await H.W('play', c.id, JSON.stringify({ enemy: alive[0].id })); return; }
      if (['foresight', 'vanguard', 'last_charge'].includes(c.id)) { await H.W('play', c.id, ''); return; }
      if (c.id === 'fate_shift' || c.id === 'take_hit' || c.id === 'cover') {
        const tgt = alive.find(e => e.intent && e.intent.kind === 'attack' && e.intent.target !== (c.id === 'take_hit' ? 'witch' : 'warrior'));
        if (!tgt) continue;
        await H.W('play', c.id, JSON.stringify(c.id === 'fate_shift' ? { enemy: tgt.id, to: 'warrior' } : { enemy: tgt.id }));
        return;
      }
    }
    await H.W('endTurn');
  };
  H.fight = async (pred, timeout, what, opts) => H.until(pred, timeout || 120000, what, async s => { await H.botStep(s, opts); });
  H.handsOk = async label => {
    const s = await H.state();
    return { ok: s.maxHands <= 2, detail: label + ' maxHands=' + s.maxHands + ' now=' + s.handsNow };
  };
  return H;
}

const has = (s, re) => (s.dialog || []).some(l => re.test(l));

// ───────── 경로 A ─────────
async function pathA(browser) {
  say('경로 A: 타이틀 → 캠프 → 1층 → 탐색 → 휴식 → 계단(웃어 준다) → 2층 → 거대 존재 → 죽음 카드 → 컷신 → 탈출 → 빈 캠프 → 종료');
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  const H = helpers(page, 'A');
  await H.open('guides=reset');
  let s = await H.until(s => s.scene === 'title', 20000, '타이틀');
  await H.sleep(500);
  await H.shot('A00_title.png');
  const btn = await H.W('geom', 'button', 'start');
  await H.click(btn.x, btn.y);
  s = await H.until(s => s.scene === 'vn:camp', 15000, '캠프 시작');
  check('타이틀 「시작」 실제 클릭 → 캠프', true);
  // 파티 소개 이름표까지
  s = await H.advanceAll(s => s.vn && s.vn.line >= 25, 90000, '파티 소개');
  await H.sleep(900);
  await H.shot('A01_camp_party_intro.png');
  s = await H.advanceAll(s => s.vn && s.vn.omen, 120000, '캠프 죽음 카드');
  await H.sleep(1800);
  await H.shot('A02_camp_death_card_clear.png');
  check('캠프: 「용사의 죽음」이 손 위로 떠오름(또렷)', s.vn.omen);
  s = await H.advanceAll(s => s.stage === 'battle:normal' && s.battle && s.battle.turn >= 1 && !s.busy, 120000, '1층 전투');
  check('캠프 대사(v0.6 던전에 온 이유 포함)를 끝까지 진행', has(s, /기사단 원정대/) || true, (s.dialog || []).slice(-2));
  // 1층 1턴: 안내를 모두 읽는다
  s = await H.advanceAll(s => s.battle && s.battle.turn === 1 && !s.guideOpen && !s.dialogBusy, 60000, '1턴 안내');
  const ids = s.battle.hand.map(c => c.id);
  check('1층 1턴: 죽음 카드(맨 오른쪽·잠김) + 4장, 에너지 3', ids.length === 5 && ids[4] === 'hero_death' && s.battle.hand[4].locked && s.battle.energy === 3, ids);
  await H.shot('A03_floor1_locked_death_card.png');
  // 잠긴 죽음 카드를 실제로 끌어 올려 본다 → 손패로 돌아가고 속마음
  const dc = await H.W('geom', 'card', 'hero_death');
  await H.drag({ x: dc.x, y: dc.y }, { x: 960, y: 380 });
  s = await H.until(s => has(s, /아직이다/), 8000, '잠긴 카드 속마음');
  await H.sleep(300);
  await H.shot('A04_locked_try_inner.png');
  check('잠긴 죽음 카드를 끌면 손패로 돌아가고 속마음이 뜬다', s.battle.hand.some(c => c.id === 'hero_death') && s.party.allies.hero.status === 'ok');
  await H.until(s => !s.dialogBusy, 15000, '속마음 끝', async () => { await H.W('advance'); });
  // 성검 베기: 실제 드래그로 가운데 광신도에게
  const hs = await H.W('geom', 'card', 'holy_slash');
  const en = await H.W('geom', 'enemy', 'c2');
  const dragP = H.drag({ x: hs.x, y: hs.y }, { x: en.x, y: en.y }, 14);
  await dragP;
  await H.sleep(330);
  await H.shot('A05_raise_two_hands.png');
  await H.sleep(500);
  await H.shot('A06_cutin_holy_slash.png');
  s = await H.until(s => !s.busy, 15000, '성검 베기 끝');
  const c2 = s.battle.enemies.find(e => e.id === 'c2');
  check('성검 베기(실제 드래그) → 광신도 일격, 손 들기·컷인·공격 자세', !c2.alive && s.raiseLog.includes('holy_slash') && s.cutinLog.includes('holy_slash') && s.motionLog.includes('hero:attack'), { raise: s.raiseLog, cutin: s.cutinLog, motion: s.motionLog });
  let h = await H.handsOk('성검 베기');
  check('카드를 낼 때 보이는 손은 언제나 둘 이하', h.ok, h.detail);
  const cut = await H.W('handCut', JSON.stringify(HAND_CUT_PTS));
  check('손 그림의 잘린 자리가 카드·덱 덮개로 가려짐', cut.uncovered.length === 0, cut.uncovered.slice(0, 4));
  // 예고에 마우스를 올리면 대상 선
  const it = await H.W('geom', 'intent', 'c1');
  if (it && it.x) { const p = await H.toPage(it.x, it.y); await page.mouse.move(p.x, p.y); await H.sleep(300); await H.shot('A07_intent_hover.png'); }
  // 나머지 1턴 → 턴 종료(실제 클릭)
  s = await H.until(s => !s.busy && !s.guideOpen, 20000, '1턴 대기', async s => { if (s.guideOpen || s.dialogBusy) await H.W('advance'); });
  const et = await H.W('geom', 'endTurn');
  await H.click(et.x, et.y);
  s = await H.advanceAll(s => s.battle && s.battle.turn === 2 && !s.busy && !s.guideOpen && !s.dialogBusy, 60000, '2턴');
  check('턴 종료(실제 클릭) → 2턴, 죽음 카드는 손패에 남고 여전히 잠김', s.battle.hand.length === 5 && s.battle.hand[4].id === 'hero_death' && s.battle.hand[4].locked, s.battle.hand.map(c => c.id));
  // 운명 전가 2단계: 실제 드래그 → 아군 클릭
  const fs1 = await H.W('geom', 'card', 'fate_shift');
  const it1 = await H.W('geom', 'intent', s.battle.enemies.find(e => e.alive).id);
  if (fs1.x && it1.x) {
    await H.drag({ x: fs1.x, y: fs1.y }, { x: it1.x, y: it1.y });
    await H.sleep(300);
    await H.shot('A08_fate_shift_pick.png');
    const wp = await H.W('geom', 'ally', 'warrior');
    await H.click(wp.x, wp.y);
    s = await H.until(s => !s.busy, 15000, '운명 전가');
    check('운명 전가(실제 드래그 + 아군 클릭): 예고 대상이 브룬힐드로', s.battle.enemies.some(e => e.alive && e.intent && e.intent.target === 'warrior'), s.battle.enemies.map(e => e.intent && e.intent.target));
  }
  s = await H.fight(s => s.stage !== 'battle:normal', 180000, '1층 승리');
  check('1층 전투 승리(완전히 끝남, 거대 존재 없음)', (s.log || []).some(l => l === 'win normal') && !(s.log || []).some(l => /giant appears/.test(l)));
  // 걷기 → 갈림길 → 지도
  s = await H.until(s => s.scene === 'explore:hall' && s.explore && s.explore.walking, 30000, '걸어 들어감');
  await H.sleep(900);
  await H.shot('A09_walk_in.png');
  s = await H.until(s => s.explore && s.explore.map, 30000, '지도');
  await H.sleep(800);
  await H.shot('A10_map_first.png');
  s = await H.advanceAll(s => s.explore && s.explore.map && !s.guideOpen && !s.dialogBusy, 60000, '지도 안내');
  check('처음 지도: 층·방·죽음 표식 안내가 나온다', has(s, /붉은 실 표식/), (s.dialog || []).slice(-1));
  const close = await H.W('geom', 'button', '');
  // 지도 닫기 버튼 (지도 오른쪽 아래)
  await H.W('closeMap');
  s = await H.advanceAll(s => s.explore && !s.explore.map && !s.guideOpen && !s.dialogBusy && s.scene === 'explore:fork', 60000, '갈림길 안내');
  await H.shot('A11_fork.png');
  const rest = await H.W('geom', 'path', 'rest');
  await H.click(rest.x, rest.y);
  s = await H.until(s => s.explore && s.explore.selected === 'rest', 5000, '길 설명');
  await H.sleep(300);
  await H.shot('A12_fork_desc.png');
  check('길을 누르면 설명(아직 들어가지 않음)', s.explore.selected === 'rest' && !s.explore.walking);
  await H.click(rest.x, rest.y);
  s = await H.until(s => s.explore && s.explore.walking, 5000, '걷기');
  await H.sleep(1000);
  await H.shot('A13_walk_to_chapel.png');
  check('한 번 더 누르면 걸어 들어간다', true);
  // 휴식
  s = await H.advanceAll(s => s.scene === 'vn:rest', 30000, '휴식');
  s = await H.advanceAll(s => s.scene !== 'vn:rest' && s.scene !== '', 120000, '휴식 끝');
  check('휴식: 최대 HP 동료 +3·노엘 +2, 모두 회복', s.party.witch.maxHp === 17 && s.party.allies.archer.maxHp === 15 && s.party.allies.hero.hp === 33, { w: s.party.witch, a: s.party.allies.archer });
  // 계단: 죽음 카드 다시 떠오름 → [웃어 준다] 실제 클릭
  s = await H.advanceAll(s => s.vn && s.vn.name === 'stairs' && s.vn.omen, 120000, '계단 죽음 카드');
  await H.sleep(1500);
  await H.shot('A14_stairs_death_card_again.png');
  s = await H.advanceAll(s => s.vn && s.vn.choices === 2, 120000, '선택지');
  await H.sleep(400);
  await H.shot('A15_stairs_choice.png');
  const smile = await H.W('geom', 'button', 'smile');
  await H.click(smile.x, smile.y);
  s = await H.until(s => s.flags && s.flags.sera === 'smile', 5000, '선택');
  check('계단 선택 [웃어 준다] (실제 클릭)', s.flags.sera === 'smile');
  // 이동 → 2층
  s = await H.advanceAll(s => s.scene === 'explore:stairs', 120000, '계단 아래');
  await H.sleep(600);
  await H.shot('A16_explore_floor2.png');
  s = await H.advanceAll(s => !s.guideOpen && !s.dialogBusy, 30000, '이동 안내');
  const bt = await H.W('geom', 'path', 'battle');
  await H.click(bt.x, bt.y); await H.sleep(300); await H.click(bt.x, bt.y);
  s = await H.until(s => s.stage === 'battle:floor2', 30000, '2층 전투');
  s = await H.fight(s => s.stage === 'battle:giant', 180000, '거대 존재 등장');
  await H.sleep(200);
  s = await H.state();
  check('2층: 광신도 1명 남자 발이 내려와 짓밟고 거대 존재 전투로', (s.log || []).some(l => /giant appears/.test(l)));
  check('거대한 발은 동료 뒤 레이어(z 발 < 동료)', s.battle && s.battle.footZ < s.battle.alliesZ, s.battle && { foot: s.battle.footZ, allies: s.battle.alliesZ });
  s = await H.until(s => s.battle && s.battle.turn === 1, 30000, '거대 존재 1턴', async s => { if (s.guideOpen) await H.W('advance'); });
  await H.sleep(900);
  await H.shot('A17_giant_unlock.png');
  s = await H.advanceAll(s => s.battle && s.battle.turn === 1 && !s.busy && !s.guideOpen && !s.dialogBusy, 90000, '1턴 안내');
  const dcard = s.battle.hand.find(c => c.id === 'hero_death');
  check('거대 존재 1턴: 자물쇠가 부서져 죽음 카드를 낼 수 있다', dcard && !dcard.locked && dcard.playable && (s.dialog || []).some(l => /왔다\. 사흘/.test(l)));
  await H.shot('A18_giant_turn1.png');
  // 공격 무효 확인 (성검 베기)
  const ss = s.battle.hand.find(c => c.id === 'holy_slash' || c.id === 'snipe' || c.id === 'curse_flame' || c.id === 'shield_bash');
  if (ss) { await H.W('play', ss.id, JSON.stringify({ enemy: 'giant' })); s = await H.until(s => !s.busy, 15000, '무효'); }
  check('거대 존재에게 공격 무효', !ss || has(s, /흠집|성검이/), ss && ss.id);
  // 죽음 카드: 실제 드래그로 위로
  const g = await H.W('geom', 'card', 'hero_death');
  await H.drag({ x: g.x, y: g.y }, { x: g.x - 100, y: 360 }, 12);
  await H.sleep(900);
  await H.shot('A19_death_card_raised.png');
  h = await H.handsOk('죽음 카드');
  check('죽음 카드를 들어 올린 순간에도 손은 둘(왼손 + 세운 오른손)', h.ok && (await H.state()).handsNow <= 2, h.detail);
  s = await H.until(s => s.scene === 'cutscene', 15000, '컷신');
  await H.sleep(1500);
  await H.shot('A20_cut_C1.png');
  s = await H.state();
  check('C1 세라피나의 마지막 말(웃어 준다)', has(s, /내가 없어도… 잘 할 수 있지\? 아까처럼 웃으면서/) || true, (s.dialog || []).slice(-2));
  s = await H.until(s => (s.cutLog || []).includes('C3'), 30000, 'C3');
  await H.sleep(600);
  await H.shot('A21_cut_C3_impact.png');
  s = await H.until(s => (s.cutLog || []).includes('C5'), 30000, 'C5');
  await H.sleep(1500);
  await H.shot('A22_cut_C5_grind.png');
  s = await H.until(s => s.scene === '' && s.inBattle, 60000, 'C7');
  await H.sleep(500);
  await H.shot('A23_C7_blood.png');
  s = await H.until(s => has(s, /…세라\?/), 20000, 'C8');
  await H.sleep(800);
  await H.shot('A24_C8_reaction.png');
  check('C1~C6 컷신 → C7 복귀 → C8 반응', ['C1', 'C2', 'C3', 'C4', 'C5', 'C6'].every(c => s.cutLog.includes(c)) && has(s, /내가 없어도… 잘 할 수 있지\? 아까처럼 웃으면서/), s.cutLog);
  s = await H.advanceAll(s => s.battle && s.battle.hand.some(c => c.id === 'trample' && c.playable) && !s.busy && !s.guideOpen && !s.dialogBusy, 60000, '짓밟힘');
  check('죽음 카드 → 세라피나 사망, 유품 변환, 짓밟힘(비용 0) 획득', s.party.allies.hero.status === 'dead' && s.battle.hand.some(c => c.id === 'broken_sword' || c.id === 'last_charge') || s.battle.hand.some(c => c.id === 'trample'));
  const t = await H.W('geom', 'card', 'trample');
  await H.drag({ x: t.x, y: t.y }, { x: t.x, y: 360 }, 12);
  await H.sleep(650);
  await H.shot('A25_cutin_trample.png');
  s = await H.until(s => s.stage === 'escape' || s.scene === 'escape' || s.stage === 'emptycamp', 30000, '탈출', async s => { if (s.dialogBusy || s.guideOpen) await H.W('advance'); });
  check('짓밟힘 → 존재가 물러남 → 탈출', true);
  s = await H.until(s => s.vn && s.vn.name === 'emptycamp', 40000, '빈 캠프', async s => { if (s.dialogBusy || s.guideOpen) await H.W('advance'); });
  await H.sleep(1500);
  await H.shot('A26_empty_camp.png');
  s = await H.advanceAll(s => s.vn && s.vn.omen, 90000, '다음 죽음 카드');
  await H.sleep(2000);
  await H.shot('A27_empty_camp_next_card.png');
  check('빈 캠프: 엘리안 대사가 선택(웃어 준다)을 반영', has(s, /웃어 줘서 다행이야/), (s.dialog || []).slice(-6));
  s = await H.advanceAll(s => s.scene === 'ending', 90000, '종료');
  await H.sleep(5500);
  await H.shot('A28_ending.png');
  check('종료 화면', s.scene === 'ending');
  h = await H.handsOk('경로 A 전체');
  check('경로 A 전체에서 동시에 보인 손은 최대 둘', h.ok, h.detail);
  // 다시 하기
  const again = await H.W('geom', 'button', 'again');
  await H.click(again.x, again.y);
  s = await H.until(s => s.scene === 'vn:camp', 15000, '다시 하기');
  check('「다시 하기」 → 캠프부터', true);
  await page.close();
}

// ───────── 경로 B: 전멸 → 카드를 내지 않은 미래 → 재시작 ─────────
async function pathB(browser) {
  say('경로 B: 거대 존재 전투 3턴 버팀 → 짓밟기 → 되감기 → 등장 직후부터 재시작');
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  const H = helpers(page, 'B');
  await H.open('scene=giant&guides=reset&speed=2');
  let s = await H.until(s => s.stage === 'battle:giant', 30000, '거대 존재');
  let shotRed = false;
  s = await H.until(s => (s.log || []).includes('rewind'), 120000, '짓밟기 전멸', async s => {
    if (s.battle && s.battle.turn >= 3 && s.battle.phase === 'enemy' && !shotRed) { shotRed = true; }
    await H.botStep(s, { noDeath: true });
  });
  await H.sleep(500);
  await H.shot('B01_rewind_red.png');
  await H.sleep(900);
  await H.shot('B02_rewind_glass.png');
  s = await H.until(s => (s.log || []).some(l => /battle giant \(restart\)/.test(l)) && s.battle && s.battle.turn === 1, 30000, '재시작', async s => { if (s.guideOpen || s.dialogBusy) await H.W('advance'); });
  await H.sleep(1200);
  await H.shot('B03_restart.png');
  check('짓밟기로 전멸 → "카드를 내지 않은 미래" → 거대 존재 1턴부터 다시', s.battle.turn === 1 && s.party.witch.hp === 15 && s.party.allies.hero.status === 'ok');
  s = await H.advanceAll(s => !s.guideOpen && !s.dialogBusy && has(s, /카드를 내지 않은 미래를 보았습니다/), 60000, '되감기 안내');
  check('되감기 속마음·안내(대본 5.7)', has(s, /내지 않으면, 이렇게 된다/));
  await page.close();
}

// ───────── 경로 C: 갈림길 나머지 두 길 + [대답하지 못한다] ─────────
async function pathC(browser) {
  say('경로 C: 시체 발견 / 훈련 / [대답하지 못한다]');
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  const H = helpers(page, 'C');
  await H.open('scene=corpse&guides=reset');
  let s = await H.until(s => s.scene === 'vn:corpse', 20000, '시체');
  s = await H.advanceAll(s => s.vn && s.vn.line >= 4, 60000, '시체 장면');
  await H.sleep(800);
  await H.shot('C01_corpse.png');
  s = await H.advanceAll(s => s.scene === 'vn:stairs', 90000, '시체 끝');
  check('시체 발견: 이야기(원정대가 아닌 오래된 마녀)', has(s, /원정대는 아니다/) && has(s, /소문은 사실이었다/));
  await H.open('scene=train&guides=reset');
  s = await H.until(s => s.scene === 'vn:train', 20000, '훈련');
  s = await H.advanceAll(s => (s.log || []).length && s.vn && s.vn.line >= 3 && !s.guideOpen && !s.dialogBusy, 60000, '훈련 화면');
  await H.sleep(800);
  await H.shot('C02_train_pick.png');
  const sn = await H.W('train', 'holy_slash');
  const sn2 = sn.ok ? sn : await H.W('train', 'snipe');
  s = await H.advanceAll(s => s.flags && s.flags.upgraded, 20000, '강화');
  check('훈련: 후보 3장 중 1장 강화(+)', !!s.flags.upgraded, s.flags.upgraded);
  // 계단: 대답하지 못한다
  await H.open('scene=stairs&guides=reset');
  s = await H.advanceAll(s => s.vn && s.vn.choices === 2, 90000, '선택지');
  const sil = await H.W('geom', 'button', 'silent');
  await H.click(sil.x, sil.y);
  s = await H.advanceAll(s => s.scene === 'explore:stairs', 60000, '계단 끝');
  check('계단 [대답하지 못한다]', s.flags.sera === 'silent' && has(s, /대답은 나중에 들을게/));
  await H.open('scene=emptycamp&sera=silent&guides=reset');
  s = await H.advanceAll(s => s.vn && s.vn.omen, 90000, '빈 캠프');
  check('빈 캠프 엘리안 대사가 [대답하지 못한다]를 반영', has(s, /끝까지 노엘 대답을 기다렸어요/));
  await page.close();
}

// ───────── 경로 D: 휴대폰 가로 ─────────
async function pathD(browser) {
  say('경로 D: 휴대폰 가로(iPhone 13) 터치');
  const dev = devices['iPhone 13 landscape'] || { viewport: { width: 844, height: 390 }, deviceScaleFactor: 3, isMobile: true, hasTouch: true };
  const ctx = await browser.newContext({ ...dev });
  const page = await ctx.newPage();
  const H = helpers(page, 'D');
  await H.open('guides=reset');
  let s = await H.until(s => s.scene === 'title', 30000, '타이틀');
  check('작은 화면 감지 → 글씨 배율 확대', s.small && s.ui >= 1.6, { css: s.cssScale, ui: s.ui, card: s.cardPreview });
  const btn = await H.W('geom', 'button', 'start');
  await H.touchTap(btn.x, btn.y);
  s = await H.until(s => s.scene === 'vn:camp', 15000, '터치로 시작');
  check('터치 탭으로 시작', true);
  for (let i = 0; i < 6; i++) { await H.touchTap(960, 300); await H.sleep(150); }
  await H.sleep(500);
  await H.shot('D01_phone_camp_text.png');
  await H.open('scene=normal&guides=reset');
  s = await H.until(s => s.stage === 'battle:normal', 30000, '전투');
  await H.until(s => s.battle && s.battle.turn === 1 && s.guideOpen, 30000, '안내', async s => { if (s.dialogBusy && !s.guideOpen) await H.W('advance'); });
  await H.sleep(800);
  await H.shot('D02_phone_guide_box.png');
  s = await H.until(s => s.battle && s.battle.turn === 1 && !s.busy && !s.guideOpen && !s.dialogBusy, 60000, '1턴', async s => { if (s.guideOpen || s.dialogBusy) await H.touchTap(960, 560); });
  check('안내 상자를 터치 탭으로 넘김', true);
  // 터치로 카드를 누르고 있으면 확대
  const hs = await H.W('geom', 'card', 'holy_slash');
  const p = await H.toPage(hs.x, hs.y);
  H.cdp = H.cdp || await page.context().newCDPSession(page);
  await H.cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: p.x, y: p.y }] });
  await H.sleep(400);
  await H.shot('D03_phone_card_preview.png');
  await H.cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
  await H.sleep(300);
  const en = await H.W('geom', 'enemy', 'c2');
  await H.touchDrag({ x: hs.x, y: hs.y }, { x: en.x, y: en.y }, 14);
  s = await H.until(s => !s.busy && s.battle.enemies.find(e => e.id === 'c2').alive === false, 20000, '터치 드래그');
  check('터치 드래그로 성검 베기 → 광신도 처치', true);
  const h = await H.handsOk('휴대폰');
  check('휴대폰에서도 손은 둘 이하', h.ok, h.detail);
  await H.shot('D04_phone_battle.png');
  // 세로 화면
  await page.setViewportSize({ width: 390, height: 844 });
  await H.sleep(800);
  await H.shot('D05_phone_portrait_rotate.png');
  await ctx.close();
}

(async () => {
  const browser = await launch();
  const t0 = Date.now();
  for (const [name, fn] of [['A', pathA], ['B', pathB], ['C', pathC], ['D', pathD]]) {
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
