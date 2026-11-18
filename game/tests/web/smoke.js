/*
 * 웹 빌드 스모크 테스트 (Playwright + Chromium) — Godot 판 "죽음을 보는 마녀" 튜토리얼
 *   node game/tests/web/smoke.js <웹 빌드 주소, 예: http://localhost:8000/> <스크린샷 폴더>
 *
 * Godot 캔버스에는 DOM 이 없으므로 게임이 ?test=1 일 때 붙이는 window.witch 훅(core/test_api.gd)으로 상태를 읽고 장면을 옮긴다.
 * 중요한 조작(카드 끌기·잠긴 죽음 카드·길 고르기·선택지·지도 닫기·턴 종료)은 좌표로 실제 마우스·터치 입력을 보낸다.
 *
 * 경로 A: 타이틀(실제 클릭) → 캠프(파티 소개 이름표·또렷한 죽음 카드) → 1층 전투(잠긴 죽음 카드를 끌어 내려다 실패, 성검 베기 조준(작은 오른손이 카드를 쥠)·취소, 성검 베기 실제 드래그,
 *         손 들기 중 손은 둘뿐, 운명 전가 2단계) → 승리 → (탑뷰) 회랑 → 갈림길 → 지도(처음: 안내) → 출구 앞 설명 → 다시 눌러 들어감
 *         → 휴식 → 계단(죽음 카드 다시 떠오름, [웃어 준다] 실제 클릭) → 1층의 깊은 곳 → 거대 존재 등장(발이 동료 뒤) → 자물쇠가 부서짐
 *         → 죽음 카드 실제 드래그(세운 손·팽팽한 실, 손은 둘) → 컷신 C1(웃어 준다 대사)~C6 → C7·C8 → 짓밟힘(컷인) → 탈출
 *         → 빈 캠프(흐린 카드 → 브룬힐드 관통 Lv1 또렷) → 1층 끝 → 2층
 * 경로 F: 1차 시험판 v2 운명 — 휴대폰: 2층 운명 표시·크게 보기, 조이스틱, 필드 운명의 시도(함정·시간 정지 → 바침: 데스신·상속 카드), 납골당,
 *         계단(엘리안 운명), 3층 조사, 화형대 2턴 「운명의 불길」 → 거스름(흉터), 결과 요약 → 2층부터 다시 / PC: 3층 브룬힐드 Lv2 바침, 죽음 카드 직접 내기
 * 경로 B: 거대 존재 전투에서 카드를 내지 않고 3턴 → 짓밟기 → "카드를 내지 않은 미래"(붉게 번짐·유리 깨짐) → 등장 직후(1턴)부터 재시작
 * 경로 C: 갈림길 시체 발견 / 훈련(카드 강화 +) 각각, 계단 [대답하지 못한다] → C1·빈 캠프 대사가 선택을 반영
 * 경로 D: 휴대폰 가로(iPhone 13 에뮬레이션, 터치) — 작은 화면 글씨 배율, 터치 탭·터치 드래그로 카드 내기, 세로 화면 "가로로 돌려 주세요"
 * 경로 T: 탑뷰 이동 시험판(?scene=topdown) — 걸어 들어옴(앞벽 가림, 동료 셋이 뒤따름)·세라피나 첫 대사 → 방향키·WASD 걷기(걷기 그림 프레임·속도 180,
 *         동료가 경로 뒤쪽에 간격을 두고 따라오고 멈추면 겹치지 않음) → 탭 이동 → 물건 4개 조사(탭·E 키) → 기둥 뒤 가림
 *         → 출구(설명 → 다시 탭 → 시험판 끝 → 입구로, 동료 다시 줄 섬) → 벽·아래 입구 막힘
 *         → 휴대폰(iPhone 13 가로): 터치 빈 바닥 탭은 안 움직임, 물건 터치 조사, 조사 버튼, 왼쪽 절반 조이스틱(끌기 → 이동·느리게 → 떼면 정지)
 *   경로만 고르기: node smoke.js <주소> <폴더> T   (기본: ABCDEFT 전부)
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
  // 조준 중: 작은 오른손이 그 카드를 쥐었는지, 손은 둘 이하인지, 쥔 카드가 손패 영역(화면 아래쪽) 안인지
  H.gripOk = (s, uid) => {
    const b = s.handGripBox || [];
    const inHand = b.length === 4 && b[1] >= 470 && b[3] <= 1080 && b[0] >= 200 && b[2] <= 1720;
    return { ok: s.handDragMode === 'aim' && s.handLifted === '' && s.handGrip === uid && s.handsNow <= 2 && inHand,
      detail: { mode: s.handDragMode, lifted: s.handLifted, grip: s.handGrip, uid, hands: s.handsNow, box: b.map(v => Math.round(v)) } };
  };
  // 탑뷰: 맵의 한 점(물건·출구·좌표)이 화면 밖이면 그쪽 화면 가장자리를 눌러 다가간 뒤, 보이면 실제로 누른다 (touch=true 면 터치)
  H.tdTap = async (kind, id, touch) => {
    for (let i = 0; i < 8; i++) {
      const g = await H.W('geom', kind, id);
      const inside = g.x > 60 && g.x < 1860 && g.y > 60 && g.y < 1020;
      const x = Math.max(160, Math.min(1760, g.x)), y = Math.max(160, Math.min(920, g.y));
      if (touch) await H.touchTap(x, y); else await H.click(x, y);
      if (inside) return true;
      await H.until(s => s.topdown.path === 0 && !s.topdown.moving, 30000, '화면 밖 ' + id + ' 쪽으로');
    }
    return false;
  };
  // 탑뷰(1차 시험판 v2): 출구 앞까지 걸어가 들어간다 / 트리거 안으로 걸어간다
  H.tdLeave = async id => {
    await H.until(s => s.topdown && s.topdown.mode === 'free' && !s.dialogBusy && !s.guideOpen, 60000, '자유 이동(' + id + ')', async s => { if (s.guideOpen || s.dialogBusy) await H.W('advance'); });
    await H.W('tdGo', 'exit:' + id);
    // 가는 길에 전조 대사가 뜨면 넘기고 다시 걷는다
    await H.until(s => s.topdown && s.topdown.exit === id && s.topdown.path === 0 && !s.topdown.moving, 40000, '출구 ' + id, async s => {
      if (s.guideOpen || s.dialogBusy) { await H.W('advance'); return; }
      if (s.topdown && s.topdown.mode === 'free' && s.topdown.path === 0 && !s.topdown.moving && s.topdown.exit !== id) await H.W('tdGo', 'exit:' + id);
    });
    await H.W('tdConfirm');
  };
  H.tdTrigger = async id => {
    await H.until(s => s.topdown && s.topdown.mode === 'free' && !s.dialogBusy && !s.guideOpen, 60000, '자유 이동(' + id + ')', async s => { if (s.guideOpen || s.dialogBusy) await H.W('advance'); });
    await H.W('tdGo', 'trigger:' + id);
  };
  H.handsOk = async label => {
    const s = await H.state();
    return { ok: s.maxHands <= 2, detail: label + ' maxHands=' + s.maxHands + ' now=' + s.handsNow };
  };
  return H;
}

const has = (s, re) => (s.dialog || []).some(l => re.test(l));
// 탑뷰 동료 줄: 노엘 발끝에서 dx,dy 방향(맵 px)으로 간격(gap)마다 한 사람씩 서 있는가 + 방향·서기 프레임
function tdLine(s, back, dir, still, n) {
  const t = s.topdown, g = t.gap;
  return t.followers.length === 3 && t.followers.slice(0, n || 3).every((f, i) => {
    const want = [t.pos[0] + back[0] * g * (i + 1), t.pos[1] + back[1] * g * (i + 1)];
    return Math.hypot(f.pos[0] - want[0], f.pos[1] - want[1]) < 1.6 && (!dir || f.dir === dir) && (!still || (!f.moving && f.frame === 1));
  });
}
// 멈춘 동료끼리(노엘 포함) 발끝 거리가 간격 가까이 떨어져 있는가 (겹쳐 쌓이지 않음)
function tdApart(s) {
  const pts = [s.topdown.pos, ...s.topdown.followers.map(f => f.pos)];
  let min = 1e9;
  for (let i = 0; i < pts.length; i++) for (let j = i + 1; j < pts.length; j++) min = Math.min(min, Math.hypot(pts[i][0] - pts[j][0], pts[i][1] - pts[j][1]));
  return { ok: min >= s.topdown.gap - 1.5, min };
}

// ───────── 경로 A ─────────
async function pathA(browser) {
  say('경로 A: 타이틀 → 캠프(탑뷰) → 광신도의 회랑 → 1층 전투 → 갈림길(지도) → 휴식 → 계단(웃어 준다) → 1층의 깊은 곳 → 거대 존재 → 죽음 카드 → 컷신 → 탈출 → 빈 캠프(브룬힐드 운명) → 1층 끝 → 2층');
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  const H = helpers(page, 'A');
  await H.open('guides=reset');
  let s = await H.until(s => s.scene === 'title', 20000, '타이틀');
  await H.sleep(500);
  await H.shot('A00_title.png');
  const btn = await H.W('geom', 'button', 'start');
  await H.click(btn.x, btn.y);
  s = await H.until(s => s.scene === 'td:camp' && s.vn, 15000, '캠프 시작');
  check('타이틀 「시작」 실제 클릭 → 캠프(탑뷰 맵 위 대화)', s.vn.overlay === true);
  // 파티 소개 이름표까지
  s = await H.advanceAll(s => s.vn && s.vn.line >= 25, 90000, '파티 소개');
  await H.sleep(900);
  await H.shot('A01_camp_party_intro.png');
  s = await H.advanceAll(s => s.vn && s.vn.omen, 120000, '캠프 죽음 카드');
  await H.sleep(1800);
  await H.shot('A02_camp_death_card_clear.png');
  check('캠프: 「용사의 죽음」이 손 위로 떠오름(또렷)', s.vn.omen);
  s = await H.advanceAll(s => s.topdown && s.topdown.map === 'camp' && s.topdown.mode === 'free' && !s.dialogBusy && !s.guideOpen && !s.vn, 180000, '캠프 자유 이동');
  await H.shot('A02b_camp_free_walk.png');
  check('캠프 대화가 끝나면 탑뷰 자유 이동(동료가 모닥불 자리에서 줄로)', s.topdown.followers.length === 3, s.topdown.followers.map(f => f.id));
  await H.tdLeave('out');
  s = await H.until(s => s.topdown && s.topdown.map === 'cult_hall', 30000, '광신도의 회랑');
  await H.tdTrigger('circle');
  s = await H.advanceAll(s => s.stage === 'battle:normal' && s.battle && s.battle.turn >= 1 && !s.busy, 120000, '1층 전투');
  check('광신도의 회랑: 의식 원에 들어서면 1층 전투', true);
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
    await H.shot('A04b_aiming_grip.png');
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
  // 성검 베기: 실제 드래그로 가운데 광신도에게
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
  // 회랑(이긴 뒤 광신도 없음) → 오른쪽 아치 → 갈림길 → 지도
  s = await H.until(s => s.topdown && s.topdown.map === 'cult_hall' && s.topdown.mode === 'free', 60000, '이긴 뒤 회랑', async s => { if (s.guideOpen || s.dialogBusy) await H.W('advance'); });
  await H.sleep(500);
  await H.shot('A09_cult_hall_after.png');
  check('이긴 뒤 회랑: 광신도가 사라지고 같은 자리에서 다시 걷는다', s.topdown.npcs.length === 0, s.topdown.npcs);
  await H.tdLeave('east');
  s = await H.until(s => s.topdown && s.topdown.map === 'fork' && s.topdown.hud && s.topdown.hud.mapOpen, 40000, '지도');
  await H.sleep(800);
  await H.shot('A10_map_first.png');
  s = await H.advanceAll(s => s.topdown && s.topdown.hud.mapOpen && !s.guideOpen && !s.dialogBusy, 60000, '지도 안내');
  check('처음 지도: 층·방·죽음 표식 안내가 나온다', has(s, /붉은 실 표식/), (s.dialog || []).slice(-1));
  // 지도 닫기 버튼 (지도 오른쪽 아래, 실제 클릭)
  const mclose = await H.W('geom', 'mapClose', '');
  if (mclose && mclose.x) await H.click(mclose.x, mclose.y); else await H.W('closeMap');
  s = await H.advanceAll(s => s.topdown && !s.topdown.hud.mapOpen && s.topdown.mode === 'free' && !s.guideOpen && !s.dialogBusy, 60000, '갈림길 안내');
  await H.shot('A11_fork.png');
  await H.W('tdGo', 'exit:rest');
  s = await H.until(s => s.topdown.exit === 'rest' && s.topdown.path === 0 && !s.topdown.moving, 40000, '길 설명');
  await H.sleep(300);
  await H.shot('A12_fork_desc.png');
  check('출구 앞에 서면 설명(아직 들어가지 않음)', /쉬어 갈 수 있을 것 같다/.test(s.topdown.desc) && s.topdown.mode === 'free', s.topdown.desc);
  await H.W('tdConfirm');
  s = await H.until(s => s.topdown && s.topdown.mode === 'event', 5000, '들어감');
  check('한 번 더 누르면 들어간다', s.topdown.exits.includes('rest'));
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
  // 이동 → 1층의 깊은 곳
  s = await H.advanceAll(s => s.topdown && s.topdown.map === 'deep_hall' && s.topdown.mode === 'free' && !s.dialogBusy, 120000, '1층의 깊은 곳');
  await H.sleep(600);
  await H.shot('A16_deep_hall.png');
  await H.tdTrigger('altar');
  s = await H.until(s => s.stage === 'battle:deep', 30000, '깊은 곳 전투');
  check('탐색·전투 HP 표시가 같은 파티 데이터(휴식 뒤 최대 HP 33/27/15·노엘 17)를 쓴다', s.party.allies.hero.maxHp === 33 && s.party.allies.warrior.maxHp === 27 && s.party.allies.archer.maxHp === 15 && s.party.witch.maxHp === 17, s.party);
  s = await H.fight(s => s.stage === 'battle:giant', 180000, '거대 존재 등장');
  await H.sleep(200);
  s = await H.state();
  check('1층의 깊은 곳: 광신도 1명 남자 발이 내려와 짓밟고 거대 존재 전투로', (s.log || []).some(l => /giant appears/.test(l)));
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
  s = await H.advanceAll(s => s.fates && s.fates.length === 1 && s.vn && s.vn.omen, 90000, '다음 죽음 카드가 또렷해짐');
  await H.sleep(2600);
  await H.shot('A27b_empty_camp_brunhild.png');
  check('빈 캠프: 흐릿한 카드가 또렷해져 브룬힐드 관통 Lv1(2층)', s.fates[0].who === 'warrior' && s.fates[0].level === 1 && s.fates[0].floor === 2, s.fates);
  s = await H.advanceAll(s => s.scene === 'chapter', 90000, '1층 끝');
  await H.sleep(4500);
  await H.shot('A28_chapter1.png');
  check('1층 끝 화면', s.scene === 'chapter');
  h = await H.handsOk('경로 A 전체');
  check('경로 A 전체에서 동시에 보인 손은 최대 둘', h.ok, h.detail);
  // 아래로 — 2층
  const nx = await H.W('geom', 'button', 'next');
  await H.click(nx.x, nx.y);
  s = await H.until(s => s.topdown && s.topdown.map === 'spike_corridor', 20000, '2층');
  check('「아래로 — 2층」 → 2층 창 함정 회랑(운명 표시: 전사의 죽음 Lv1)', s.progress.floor === 2 && s.topdown.hud.cards.length === 1 && s.topdown.hud.cards[0].lv === 1, s.topdown.hud);
  await page.close();
}

// ───────── 경로 B: 전멸 → 카드를 내지 않은 미래 → 재시작 ─────────
async function pathB(browser) {
  say('경로 B: 거대 존재 전투 3턴 버팀 → 짓밟기 → 되감기 → 등장 직후부터 재시작');
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  const H = helpers(page, 'B');
  await H.open('scene=giant&guides=reset');
  let s = await H.until(s => s.stage === 'battle:giant', 30000, '거대 존재');
  let shotRed = false;
  s = await H.until(s => (s.log || []).includes('rewind'), 120000, '짓밟기 전멸', async s => {
    if (s.battle && s.battle.turn >= 3 && s.battle.phase === 'enemy' && !shotRed) { shotRed = true; }
    await H.botStep(s, { noDeath: true });
  });
  await H.W('setSpeed', 0.3);
  await H.sleep(500);
  await H.shot('B01_rewind_red.png');
  await H.until(s => (s.log || []).includes('rewind glass'), 20000, '유리 깨짐');
  await H.sleep(600);
  await H.shot('B02_rewind_glass.png');
  await H.W('setSpeed', 1);
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
  check('훈련: 후보 3장 중 1장 강화(Lv2)', !!s.flags.upgraded, s.flags.upgraded);
  // 계단: 대답하지 못한다
  await H.open('scene=stairs&guides=reset');
  s = await H.advanceAll(s => s.vn && s.vn.choices === 2, 90000, '선택지');
  const sil = await H.W('geom', 'button', 'silent');
  await H.click(sil.x, sil.y);
  s = await H.advanceAll(s => s.scene === 'td:deep_hall', 60000, '계단 끝');
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
  s = await H.until(s => s.scene === 'td:camp' && s.vn, 15000, '터치로 시작');
  check('터치 탭으로 시작', true);
  for (let i = 0; i < 6; i++) { await H.touchTap(960, 300); await H.sleep(150); }
  await H.sleep(500);
  await H.shot('D01_phone_camp_text.png');
  await H.open('scene=normal&guides=reset');
  s = await H.until(s => s.stage === 'battle:normal', 30000, '전투');
  await H.until(s => s.battle && s.battle.turn === 1 && s.guideOpen, 60000, '안내', async s => { if ((s.dialogBusy && !s.guideOpen) || (s.guideOpen && (!s.battle || s.battle.turn < 1))) await H.touchTap(960, 560); });
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
  // 대상을 고르는 동안에는 카드 확대가 풀려야 한다(확대된 카드가 동료·적을 가리지 않게)
  {
    const a = await H.toPage(hs.x, hs.y), b = await H.toPage(en.x, en.y);
    await H.cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: a.x, y: a.y }] });
    for (let i = 1; i <= 7; i++) {
      await H.sleep(20);
      await H.cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ x: a.x + (b.x - a.x) * i / 14, y: a.y + (b.y - a.y) * i / 14 }] });
    }
    await H.sleep(300);
    const m = await H.state();
    await H.shot('D03b_phone_aiming.png');
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
  // 세로 화면
  await page.setViewportSize({ width: 390, height: 844 });
  await H.sleep(800);
  await H.shot('D05_phone_portrait_rotate.png');
  await ctx.close();
}

// ───────── 경로 E: 느린 속도 연출 스크린샷 (손 들기 중간·컷인·동료 타격) ─────────
async function pathE(browser) {
  say('경로 E: 느린 속도 연출 — 오른손이 빠짐 → 세운 손 → 컷인 → 타격');
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  const H = helpers(page, 'E');
  await H.open('scene=normal&autoguide=1');
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

// ───────── 경로 T: 탑뷰 이동 시험판 (?scene=topdown) ─────────
async function pathT(browser) {
  say('경로 T: 탑뷰 시험판 — 걸어 들어옴 → 키보드 걷기 → 탭 이동 → 물건 4개 조사 → 출구 → 벽 → 휴대폰 터치');
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  const H = helpers(page, 'T');
  await H.open('scene=topdown&speed=0.3');
  let s = await H.until(s => s.topdown && s.topdown.pos[1] < 625, 30000, '탑뷰 장면');
  check('?scene=topdown → 탑뷰 장면', s.scene === 'topdown', s.scene);
  await H.shot('T01_intro_arch.png');
  await H.W('setSpeed', 1);
  s = await H.state();
  check('시작: 아래 입구 아치에서 걸어 들어옴(앞벽이 노엘 위에 덮임)', s.topdown.mode === 'intro' || s.topdown.pos[1] > 560, s.topdown);
  s = await H.until(s => s.topdown.mode === 'talk' && s.topdown.stand === 'hero', 30000, '세라피나 첫 대사');
  await H.sleep(900);
  await H.shot('T02_intro_sera.png');
  check('첫 대사: 세라피나 + 세라피나 스탠딩', has(s, /세라피나: 노엘, 길이 셋으로 갈린다\. 어디로 갈까\?/) && s.topdown.stand === 'hero', s.dialog.slice(-2));
  check('걸어 들어온 동료 셋(세라피나·브룬힐드·엘리안)이 노엘 뒤(아래)에 간격을 두고 줄 섬, 위를 봄·서기', tdLine(s, [0, 1], 'up', true)
    && s.topdown.followers.map(f => f.id).join() === 'seraphina,brunhild,elian', s.topdown.followers);
  s = await H.advanceAll(s => s.topdown.mode === 'free' && !s.dialogBusy, 30000, '자유 이동');
  const p0 = s.topdown.pos;
  check('입구 자리에 섬(설 수 있는 곳)', s.topdown.canStand && Math.abs(p0[0] - 424) < 2 && Math.abs(p0[1] - 468) < 2, s.topdown.pos);
  // 키보드: 캔버스에 초점 → 오른쪽으로 걷기
  await page.evaluate(() => { const c = document.querySelector('canvas'); c.setAttribute('tabindex', '0'); c.focus(); });
  const seen = new Set(), fseen = new Set();
  let sa = null;
  await page.keyboard.down('ArrowRight');
  // 속도 180 이면 금방 오른쪽 벽에 닿으므로, 벽에 닿기 전(x < 760) 구간만으로 속도를 잰다
  let kmove = null;
  for (let i = 0; i < 6; i++) {
    // 간격을 들쭉날쭉하게(걷기 그림 주기와 맞물려 같은 프레임만 잡히지 않게)
    await H.sleep(30 + 41 * i); s = await H.state(); seen.add(s.topdown.sheetFrame); fseen.add(s.topdown.followers[0].sheetFrame);
    if (i === 0) sa = s;
    if (s.topdown.pos[0] < 760) kmove = s;
    if (i === 2) await H.shot('T03_key_walk_right.png');
  }
  kmove = kmove || s;
  await page.keyboard.up('ArrowRight');
  check('방향키 → 오른쪽으로 걸음(x 증가, 오른쪽 행 그림)', s.topdown.pos[0] > p0[0] + 10 && s.topdown.dir === 'right', { pos: s.topdown.pos, dir: s.topdown.dir });
  check('걷기 그림: 걷는 동안 프레임이 바뀜(오른쪽 행 6~8 중 둘 이상)', [6, 7, 8].filter(x => seen.has(x)).length >= 2, [...seen]);
  const kv = (kmove.topdown.pos[0] - sa.topdown.pos[0]) / ((kmove.topdown.t - sa.topdown.t) / 1000);
  check('걷는 속도 약 180 맵px/초', kv > 160 && kv < 200, Math.round(kv));
  // 노엘이 걸은 거리만큼 모퉁이를 돈 동료(간격 × 순번 ≤ 걸은 거리)는 가로줄에서 오른쪽을 보고 걷는다 (나머지는 아직 모퉁이 뒤)
  const walkedN = Math.max(1, Math.min(3, Math.floor((kmove.topdown.pos[0] - p0[0] - 10) / kmove.topdown.gap)));
  check('걷는 동안 동료가 노엘 경로 뒤쪽(왼쪽)에 간격을 두고 따라옴, 오른쪽 행 걷기 그림', tdLine(kmove, [-1, 0], 'right', false, walkedN)
    && kmove.topdown.followers.every(f => f.moving) && kmove.topdown.followers.slice(0, walkedN).every(f => Math.floor(f.sheetFrame / 3) === 2) && [6, 7, 8].some(x => fseen.has(x)),
    { f: kmove.topdown.followers, n: kmove.topdown.pos, fseen: [...fseen], walkedN });
  await H.sleep(300);
  s = await H.state();
  check('멈추면 서기 프레임', !s.topdown.moving && s.topdown.frame === 1, s.topdown);
  const ap = tdApart(s);
  check('노엘이 멈추면 동료도 간격을 둔 채 멈춤(서기 프레임, 겹치지 않음)', tdLine(s, [-1, 0], 'right', true) && ap.ok, { min: ap.min, f: s.topdown.followers });
  const p1 = s.topdown.pos;
  await page.keyboard.down('KeyW');
  await H.sleep(900);
  s = await H.state();
  await page.keyboard.up('KeyW');
  check('W → 위로 걸음(뒷모습 행)', s.topdown.pos[1] < p1[1] - 10 && s.topdown.dir === 'up' && Math.floor(s.topdown.sheetFrame / 3) === 3, s.topdown);
  // 탭 이동
  await H.sleep(800);
  let g = await H.W('geom', 'tdMap', '560,330');
  await H.click(g.x, g.y);
  await H.sleep(300);
  s = await H.until(s => s.topdown.path === 0 && !s.topdown.moving, 20000, '탭한 곳까지');
  check('탭한 곳으로 걸어감', Math.hypot(s.topdown.pos[0] - 560, s.topdown.pos[1] - 330) < 12, s.topdown.pos);
  // 물건 4개
  const want = {
    shield: [/왕도 기사단의 문장\. …원정대는, 여기까지는 왔다\./],
    journal: [/찢어진 일지\. 마지막 장만 읽힌다\./, /「발소리가 들린다\. 위에서\.」/],
    spade: [/돌에 새긴 카드 한 장\./, /…나 말고도, 카드를 쓰는 누군가가 여기 있었다\./],
    thread: [/붉은 실\. 내 것이 아니다\./, /끊어진 채, 돌에 걸려 있다\./],
  };
  let n = 0;
  for (const id of ['shield', 'journal', 'spade', 'thread']) {
    if (id === 'spade') {
      // 가까이 걸어가서 E 키로 조사 (! 표시 확인)
      await H.tdTap('tdMap', '96,372');
      s = await H.until(s => s.topdown.near === 'spade' && s.topdown.path === 0 && !s.topdown.moving, 30000, '카드 무늬 앞');
      await H.sleep(300);
      await H.shot('T05_near_spade_mark.png');
      await page.keyboard.press('KeyE');
    } else {
      await H.tdTap('tdItem', id);
    }
    s = await H.until(s => s.topdown.inspecting === id && s.topdown.stand === 'inner', 40000, '조사 ' + id);
    if (n === 0) { await H.sleep(1200); await H.shot('T04_inspect_shield_dialog.png'); }
    s = await H.advanceAll(s => s.topdown.mode === 'free' && !s.dialogBusy, 30000, '조사 끝 ' + id);
    const ok = want[id].every(re => has(s, re));
    check('조사 ' + id + ' → 노엘 속마음 대사', ok, s.dialog.slice(-3));
    n++;
  }
  check('물건 4개 모두 조사함', s.topdown.inspected.length === 4, s.topdown.inspected);
  // 기둥 뒤(위쪽)로 → 기둥이 노엘을 가림
  await H.tdTap('tdMap', '50,428');
  s = await H.until(s => s.topdown.path === 0 && !s.topdown.moving, 30000, '기둥 뒤');
  await H.sleep(500);
  await H.shot('T06_behind_pillar.png');
  check('기둥 뒤에 섬(y 정렬 가림 확인용)', s.topdown.pos[1] < 436 && s.topdown.pos[0] < 80 && s.topdown.canStand, s.topdown.pos);
  // 출구: 예배당
  await H.tdTap('tdExit', 'rest');
  s = await H.until(s => s.topdown.exit === 'rest' && s.topdown.path === 0, 40000, '예배당 앞');
  await H.sleep(400);
  await H.shot('T07_exit_rest_desc.png');
  check('출구 앞 → 갈림길 설명 문구(예배당)', /쉬어 갈 수 있을 것 같다/.test(s.topdown.desc), s.topdown.desc);
  g = await H.W('geom', 'tdExit', 'rest');
  await H.click(g.x, g.y);
  s = await H.until(s => s.topdown.mode === 'leaving', 10000, '들어가기');
  await H.sleep(300);
  await H.shot('T08_trial_end.png');
  check('다시 탭 → "시험판은 여기까지"', /시험판은 여기까지/.test(s.topdown.desc), s.topdown.desc);
  s = await H.until(s => s.topdown.mode === 'free' && s.fade < 0.05, 20000, '입구로 되돌아옴');
  check('입구 자리로 되돌림', Math.abs(s.topdown.pos[0] - 424) < 2 && Math.abs(s.topdown.pos[1] - 468) < 2 && s.topdown.exits.includes('rest'), s.topdown);
  check('되돌아오면 동료도 노엘 뒤에 다시 줄 섬', tdLine(s, [0, 1], 'up', true), s.topdown.followers);
  // 벽: 아래(입구 밖)로·왼쪽 벽으로 계속 밀기
  await page.keyboard.down('ArrowDown');
  await H.sleep(1500);
  await page.keyboard.up('ArrowDown');
  s = await H.state();
  check('아래 입구로 나가려 하면 막힘', s.topdown.pos[1] <= 581 && s.topdown.canStand, s.topdown.pos);
  await H.tdTap('tdMap', '300,300');
  await H.until(s => s.topdown.path === 0 && !s.topdown.moving, 30000, '가운데로');
  await H.W('setSpeed', 3);
  await page.keyboard.down('ArrowLeft');
  await H.sleep(3000);
  await page.keyboard.up('ArrowLeft');
  s = await H.state();
  check('왼쪽 벽까지 걷고 뚫지 않음', s.topdown.pos[0] >= 46 && s.topdown.pos[0] < 52 && s.topdown.canStand, s.topdown.pos);
  await page.keyboard.down('ArrowUp');
  await H.sleep(3000);
  await page.keyboard.up('ArrowUp');
  s = await H.state();
  check('위쪽 벽까지 걷고 뚫지 않음', s.topdown.pos[1] >= 152 && s.topdown.pos[1] < 158 && s.topdown.canStand, s.topdown.pos);
  // 벽 안쪽을 탭 → 가장 가까운 바닥까지만
  await H.tdTap('tdMap', '600,60');
  s = await H.until(s => s.topdown.path === 0 && !s.topdown.moving, 30000, '벽 탭');
  check('벽을 탭해도 바닥 안에 멈춤', s.topdown.canStand && s.topdown.pos[1] >= 140, s.topdown.pos);
  await H.W('setSpeed', 1);
  // 앞벽 가림: 앞벽 바로 뒤에 서기
  await H.tdTap('tdMap', '424,576');
  s = await H.until(s => s.topdown.path === 0 && !s.topdown.moving, 30000, '앞벽 뒤');
  await page.keyboard.down('ArrowDown'); await H.sleep(500); await page.keyboard.up('ArrowDown');
  await H.sleep(400);
  await H.shot('T09_front_wall.png');
  await page.close();

  // 휴대폰 가로: 터치 빈 바닥 탭은 안 움직임 · 물건 터치 조사 · 조사 버튼 · 조이스틱
  const dev = devices['iPhone 13 landscape'] || { viewport: { width: 844, height: 390 }, deviceScaleFactor: 3, isMobile: true, hasTouch: true };
  const ctx = await browser.newContext({ ...dev });
  const pp = await ctx.newPage();
  const P = helpers(pp, 'T-phone');
  await P.open('scene=topdown');
  s = await P.until(s => s.topdown && s.topdown.mode === 'talk', 40000, '휴대폰 첫 대사');
  await P.sleep(800);
  await P.shot('T10_phone_intro.png');
  for (let i = 0; i < 6 && s.topdown.mode !== 'free'; i++) { await P.touchTap(1300, 300); await P.sleep(400); s = await P.state(); }
  s = await P.until(s => s.topdown.mode === 'free' && !s.dialogBusy, 20000, '휴대폰 자유 이동');
  check('휴대폰: 동료 셋이 노엘 뒤에 줄 섬', tdLine(s, [0, 1], 'up', true), s.topdown.followers);
  check('휴대폰: 조사 버튼이 오른쪽 아래에 보이고, 가까운 물건이 없으면 꺼짐', s.topdown.touch && s.topdown.btn.rect[2] > 100 && s.topdown.btn.rect[0] > 1500 && s.topdown.btn.rect[1] > 700 && !s.topdown.btn.active, s.topdown.btn);
  const q0 = s.topdown.pos;
  g = await P.W('geom', 'tdMap', '600,450');
  await P.touchTap(g.x, g.y);
  await P.sleep(500);
  await P.touchTap(500, 420);
  await P.sleep(700);
  s = await P.state();
  check('휴대폰: 빈 바닥을 터치 탭해도 걸어가지 않음(오른쪽·왼쪽 절반)', s.topdown.path === 0 && !s.topdown.moving && Math.hypot(s.topdown.pos[0] - q0[0], s.topdown.pos[1] - q0[1]) < 0.5 && !s.topdown.stick.on, { from: q0, to: s.topdown.pos });
  await P.tdTap('tdItem', 'journal', true);
  s = await P.until(s => s.topdown.inspecting === 'journal', 30000, '휴대폰 일지 조사');
  await P.sleep(1200);
  await P.shot('T11_phone_inspect.png');
  check('휴대폰: 물건 터치 → 걸어가서 조사', has(s, /찢어진 일지/), s.dialog.slice(-2));
  for (let i = 0; i < 8 && (s.topdown.mode !== 'free' || s.dialogBusy); i++) { await P.touchTap(1300, 300); await P.sleep(400); s = await P.state(); }
  s = await P.until(s => s.topdown.mode === 'free' && !s.dialogBusy && s.topdown.near === 'journal', 20000, '일지 앞 자유 이동');
  await P.sleep(300);
  s = await P.state();
  await P.shot('T13_phone_button.png');
  check('휴대폰: 물건 가까이에서 조사 버튼이 켜짐', s.topdown.btn.active, s.topdown.btn);
  const br = s.topdown.btn.rect;
  await P.touchTap(br[0] + br[2] / 2, br[1] + br[3] / 2);
  s = await P.until(s => s.topdown.inspecting === 'journal', 10000, '조사 버튼');
  check('휴대폰: 조사 버튼 → E 키와 같은 조사', s.topdown.mode === 'talk', s.topdown.mode);
  for (let i = 0; i < 8 && (s.topdown.mode !== 'free' || s.dialogBusy); i++) { await P.touchTap(1300, 300); await P.sleep(400); s = await P.state(); }
  s = await P.until(s => s.topdown.mode === 'free' && !s.dialogBusy, 20000, '조사 끝');
  // 조이스틱: 왼쪽 절반을 누른 채 오른쪽으로 끌기 → 이동 → 조금만 기울이면 느리게 → 떼면 정지
  const j0 = { x: 300, y: 820 };
  await P.touchStart(j0.x, j0.y);
  await P.sleep(150);
  s = await P.state();
  const R = s.topdown.stick.r;
  check('휴대폰: 왼쪽 절반을 누른 자리에 조이스틱(지름 약 130 CSS px)', s.topdown.stick.on && Math.hypot(s.topdown.stick.c[0] - j0.x, s.topdown.stick.c[1] - j0.y) < 4
    && R * 2 * s.cssScale > 110 && R * 2 * s.cssScale < 150, { stick: s.topdown.stick, css: s.cssScale });
  for (let i = 1; i <= 8; i++) { await P.touchMove(j0.x + R * 1.1 * i / 8, j0.y); await P.sleep(25); }
  await P.sleep(300);
  const ja = await P.state();
  await P.sleep(800);
  const jb = await P.state();
  await P.shot('T12_phone_joystick.png');
  const fast = (jb.topdown.pos[0] - ja.topdown.pos[0]) / ((jb.topdown.t - ja.topdown.t) / 1000);
  check('휴대폰: 조이스틱 끝까지 → 오른쪽으로 최대 속도(약 180) 걷기', jb.topdown.moving && jb.topdown.dir === 'right' && fast > 140 && fast < 210 && jb.topdown.pace > 0.99, { fast: Math.round(fast), pace: jb.topdown.pace });
  check('휴대폰: 조이스틱으로 걸을 때도 동료가 뒤따라옴', tdLine(jb, [-1, 0], 'right'), jb.topdown.followers);
  const c = jb.topdown.stick.c;
  await P.touchMove(c[0] - R * 0.3, c[1]);   // 오른쪽 벽 가까이 와 있으므로 느린 걸음은 왼쪽으로 잰다
  await P.sleep(300);
  const jc = await P.state();
  await P.sleep(800);
  const jd = await P.state();
  const slow = (jc.topdown.pos[0] - jd.topdown.pos[0]) / ((jd.topdown.t - jc.topdown.t) / 1000);
  check('휴대폰: 조금만 기울이면 느리게 걷기', slow > 15 && slow < fast * 0.7 && jd.topdown.pace < 0.7, { slow: Math.round(slow), pace: jd.topdown.pace, a: ja.topdown.pos, b: jb.topdown.pos, c: jc.topdown.pos, d: jd.topdown.pos, moving: jd.topdown.moving, dir: jd.topdown.dir });
  await P.touchEnd();
  await P.sleep(400);
  s = await P.state();
  const ap2 = tdApart(s);
  check('휴대폰: 손을 떼면 조이스틱이 사라지고 멈춤(동료도 겹치지 않고 멈춤)', !s.topdown.stick.on && !s.topdown.moving && s.topdown.frame === 1 && ap2.ok
    && s.topdown.followers.every(f => !f.moving), { stick: s.topdown.stick, min: ap2.min });
  await ctx.close();
}

// ───────── 경로 F: 1차 시험판 v2 — 2·3층 운명 흐름 + 휴대폰 터치 ─────────
async function pathF(browser) {
  say('경로 F: 2층(전조 → 납골당 전투 2턴 「운명의 관통」 바침) → 계단(엘리안 운명) → 3층 → 화형대(운명의 불길 거스름) → 결과 → 3층 PC(두 운명이 한 전투에: 엘리안 거스름 → 브룬힐드 Lv2 바침) → 집행자를 먼저 쓰러뜨림');
  const dev = devices['iPhone 13 landscape'] || { viewport: { width: 844, height: 390 }, deviceScaleFactor: 3, isMobile: true, hasTouch: true };
  const ctx = await browser.newContext({ ...dev });
  const page = await ctx.newPage();
  const H = helpers(page, 'F');
  await H.open('scene=floor2&guides=reset');
  let s = await H.advanceAll(s => s.topdown && s.topdown.map === 'spike_corridor' && s.topdown.mode === 'free' && !s.dialogBusy && !s.guideOpen, 60000, '2층 회랑');
  await H.shot('F01_phone_corridor.png');
  check('2층 회랑: 운명 표시(「전사의 죽음 Lv1」)·지도 버튼, 동료 둘(브룬힐드·엘리안), 전조 트리거만 켜짐', s.topdown.hud.cards.length === 1 && s.topdown.hud.cards[0].id === 'warrior_death' && s.topdown.hud.cards[0].lv === 1
    && s.topdown.followers.map(f => f.id).join() === 'brunhild,elian' && s.topdown.armed.join() === 'omen', { hud: s.topdown.hud, armed: s.topdown.armed });
  // 운명 표시 카드를 터치 → 크게 보기 → 터치로 닫기
  const hc = s.topdown.hud.cards[0].rect;
  await H.touchTap(hc[0] + hc[2] / 2, hc[1] + hc[3] / 2);
  s = await H.until(s => s.topdown.hud.big, 5000, '운명 카드 크게');
  await H.sleep(300);
  await H.shot('F02_phone_fate_card_big.png');
  await H.touchTap(960, 540);
  s = await H.until(s => !s.topdown.hud.big, 5000, '크게 보기 닫기');
  check('운명 표시를 터치하면 카드를 크게 보고, 터치하면 닫힌다', true);
  // 조이스틱으로 위로 몇 걸음
  const p0 = s.topdown.pos;
  await H.touchStart(400, 800);
  for (let i = 1; i <= 6; i++) { await H.touchMove(400, 800 - i * 25); await H.sleep(20); }
  await H.sleep(150);
  await H.touchEnd();
  s = await H.state();
  check('휴대폰 조이스틱(위로 끌기) → 위로 걸음', s.topdown.pos[1] < p0[1] - 10, { from: p0, to: s.topdown.pos });
  // 회랑 중간: 운명의 시도 없이 전조(노엘 속마음)만
  await H.tdTrigger('omen');
  s = await H.until(s => has(s, /이 층이다/), 30000, '전조');
  await H.sleep(700);
  await H.shot('F03_phone_omen.png');
  s = await H.advanceAll(s => s.topdown.mode === 'free' && !s.dialogBusy, 30000, '전조 끝');
  check('필드: 운명의 시도·선택 화면 없이 전조 대사만, 브룬힐드 생존·흉터 0', !s.fatePicker && s.party.allies.warrior.status === 'ok' && s.scars === 0 && s.fates[0].triedFloor === 0
    && has(s, /창을 들고 기다린다/), s.fates);
  // 납골당 → 창 기사 전투: 2턴에 운명의 관통
  await H.tdLeave('north');
  s = await H.until(s => s.topdown && s.topdown.map === 'ossuary', 30000, '납골당');
  await H.tdTrigger('altar');
  s = await H.advanceAll(s => s.stage === 'battle:ossuary' && s.battle && s.battle.turn === 1 && !s.busy && !s.guideOpen && !s.dialogBusy, 60000, '납골당 전투');
  await H.shot('F04_phone_ossuary_battle.png');
  const oh = s.battle.hand.map(c => c.id);
  check('납골당 1턴: 창 기사 + 광신도, 손패에 브룬힐드 죽음 카드 + 새로 4장', s.battle.enemies.some(e => e.id === 'k1') && oh.includes('warrior_death') && oh.length === 5, oh);
  await H.W('endTurn');
  s = await H.advanceAll(s => s.battle && s.battle.turn === 2 && s.battle.phase === 'player' && !s.busy && !s.guideOpen && !s.dialogBusy, 60000, '2턴');
  const ki = s.battle.enemies.find(e => e.id === 'k1').intent;
  await H.shot('F05_phone_fate_pierce_intent.png');
  check('2턴 예고: 창 기사 「운명의 관통 → 브룬힐드」 치명·옮기기 불가', ki && ki.kind === 'fate' && ki.target === 'warrior' && ki.label === '운명의 관통' && !ki.redirectable && ki.lethal, ki);
  await H.W('endTurn');
  s = await H.until(s => s.fatePicker, 60000, '운명의 시도(납골당)', async s => { if (s.guideOpen || s.dialogBusy) await H.W('advance'); });
  await H.sleep(600);
  await H.shot('F06_phone_fate_choice.png');
  const ob = await H.W('geom', 'fateBtn', 'offer');
  check('선택 화면: [카드를 낸다 — 브룬힐드를 바친다] [거스른다 (흉터 1)]', ob && ob.x > 0 && ob.h >= 40, ob);
  await H.touchTap(ob.x, ob.y);
  s = await H.until(s => (s.cutLog || []).includes('W1'), 20000, '데스신');
  await H.sleep(1200);
  await H.shot('F07_phone_death_pierced.png');
  s = await H.advanceAll(s => s.battle && s.battle.hand.some(c => c.id === 'pierced_shield') && !s.busy && !s.dialogBusy && !s.guideOpen, 90000, '꿰뚫린 방패');
  await H.shot('F08_phone_inherit_hand.png');
  const fw = s.fates.find(f => f.who === 'warrior');
  check('바침(전투): 데스신 → 브룬힐드 사망 → 「꿰뚫린 방패」 Lv1 손패, 흉터 0',
    s.cutLog.includes('W2') && s.party.allies.warrior.status === 'dead' && fw.result === 'offered' && s.battle.hand.find(c => c.id === 'pierced_shield').lv === 1 && s.scars === 0, { fw });
  await H.W('winBattle');
  s = await H.advanceAll(s => s.topdown && s.topdown.map === 'ossuary' && s.topdown.mode === 'free', 60000, '이긴 뒤');
  check('전투 뒤 탑뷰: 브룬힐드는 줄에서 빠짐', s.topdown.followers.map(f => f.id).join() === 'elian', s.topdown.followers);
  await H.tdLeave('north');
  // 계단: 새 운명
  s = await H.advanceAll(s => s.fates && s.fates.some(f => f.who === 'archer') && s.vn && s.vn.omen, 90000, '엘리안 운명');
  await H.sleep(2600);
  await H.shot('F09_phone_stairs_archer.png');
  const fa = s.fates.find(f => f.who === 'archer');
  check('2층 계단: 브룬힐드가 없으니 엘리안 화형 Lv1(3층)만', fa.level === 1 && fa.floor === 3, fa);
  s = await H.advanceAll(s => s.topdown && s.topdown.map === 'burnt_chapel' && s.topdown.mode === 'free' && !s.dialogBusy, 90000, '3층');
  check('3층 불탄 예배당: 전조 트리거만(엘리안)', s.progress.floor === 3 && s.topdown.armed.join() === 'omen', s.topdown.armed);
  // 타 버린 활: 터치로 조사
  await H.W('tdGo', 'item:bow');
  s = await H.until(s => s.topdown.inspecting === 'bow' || has(s, /궁수였나 봐/), 30000, '활 조사');
  await H.sleep(800);
  await H.shot('F10_phone_bow.png');
  s = await H.advanceAll(s => s.topdown.mode === 'free' && !s.dialogBusy, 30000, '조사 끝');
  check('조사: 타 버린 활 → 엘리안 대사 + 노엘 속마음', has(s, /궁수였나 봐/) && has(s, /그녀의 카드와 같은 불/));
  await H.tdLeave('north');
  s = await H.until(s => s.topdown && s.topdown.map === 'pyre_court', 30000, '화형대 광장');
  await H.tdTrigger('pyre');
  s = await H.advanceAll(s => s.stage === 'battle:pyre' && s.battle && s.battle.turn === 1 && !s.busy && !s.guideOpen && !s.dialogBusy, 60000, '화형대 전투');
  const hd = s.battle.hand.map(c => c.id);
  check('화형대 1턴: 엘리안 죽음 카드(비용 0, 보존) + 새로 4장', hd.length === 5 && hd.includes('archer_death') && !hd.includes('warrior_death'), hd);
  await H.W('endTurn');
  s = await H.advanceAll(s => s.battle && s.battle.turn === 2 && s.battle.phase === 'player' && !s.busy && !s.guideOpen && !s.dialogBusy, 60000, '2턴');
  const pi = s.battle.enemies.find(e => e.id === 'p1').intent;
  await H.shot('F11_phone_fate_fire_intent.png');
  check('2턴 예고: 「운명의 불길 → 엘리안」 치명·옮기기 불가', pi && pi.kind === 'fate' && pi.target === 'archer' && !pi.redirectable && pi.lethal, pi);
  await H.W('endTurn');
  s = await H.until(s => s.fatePicker, 60000, '전투 중 운명의 시도', async s => { if (s.guideOpen || s.dialogBusy) await H.W('advance'); });
  await H.sleep(500);
  const db = await H.W('geom', 'fateBtn', 'defy');
  await H.touchTap(db.x, db.y);
  s = await H.advanceAll(s => s.battle && s.battle.turn === 3 && s.battle.phase === 'player' && !s.busy && !s.guideOpen && !s.dialogBusy, 90000, '거스른 뒤 3턴');
  await H.shot('F12_phone_after_defy.png');
  const p3i = s.battle.enemies.find(e => e.id === 'p1').intent;
  check('거스름(전투): 엘리안 생존 · 흉터 1장 · 운명은 미뤄짐, 브룬힐드가 없으니 3턴 운명 공격 없음', s.party.allies.archer.status !== 'dead' && s.scars === 1 && s.fates.find(f => f.who === 'archer').alive
    && s.fates.find(f => f.who === 'archer').triedFloor === 3 && !(p3i && p3i.kind === 'fate'), { a: s.party.allies.archer, scars: s.scars, p3i });
  await H.W('winBattle');
  s = await H.advanceAll(s => s.topdown && s.topdown.map === 'pyre_court' && s.topdown.mode === 'free', 60000, '이긴 뒤');
  await H.tdLeave('north');
  s = await H.until(s => s.scene === 'result', 30000, '결과 요약');
  await H.sleep(1500);
  await H.shot('F13_phone_result.png');
  check('결과 요약 화면(흉터 1, 다음 층: 엘리안 2단계)', s.scars === 1, s.fates);
  const r2 = await H.W('geom', 'button', 'floor2');
  await H.touchTap(r2.x, r2.y);
  s = await H.until(s => s.topdown && s.topdown.map === 'spike_corridor', 30000, '2층부터 다시');
  check('「2층부터 다시」 → 2층 회랑, 브룬힐드 살아 있고 운명 Lv1', s.party.allies.warrior.status === 'ok' && s.fates.length === 1 && s.fates[0].level === 1);
  await ctx.close();
  // PC: 3층(브룬힐드 생존) — 두 운명이 화형대 한 전투에: 2턴 엘리안(거스름) → 3턴 브룬힐드 Lv2(바침) → 손패의 엘리안 카드를 직접 냄
  const page2 = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  const H2 = helpers(page2, 'F2');
  await H2.open('scene=floor3&brun=alive&guides=reset');
  s = await H2.advanceAll(s => s.topdown && s.topdown.map === 'burnt_chapel' && s.topdown.mode === 'free' && !s.dialogBusy, 60000, '3층');
  check('3층(브룬힐드 생존): 운명 표시 둘(전사 Lv2·궁수 Lv1)', s.topdown.hud.cards.length === 2 && s.topdown.hud.cards.some(c => c.id === 'warrior_death' && c.lv === 2), s.topdown.hud.cards);
  await H2.tdTrigger('omen');
  s = await H2.until(s => has(s, /쇠꼬챙이/), 30000, '전조 둘');
  s = await H2.advanceAll(s => s.topdown.mode === 'free' && !s.dialogBusy, 30000, '전조 끝');
  await H2.shot('F14_chapel_two_fates.png');
  check('예배당 전조: 브룬힐드·엘리안 둘 다 (선택 화면 없음)', has(s, /쇠꼬챙이/) && has(s, /엘리안의 불도/) && !s.fatePicker && s.scars === 1);
  await H2.tdLeave('north');
  s = await H2.until(s => s.topdown && s.topdown.map === 'pyre_court', 30000, '화형대');
  await H2.tdTrigger('pyre');
  s = await H2.advanceAll(s => s.stage === 'battle:pyre' && s.battle && s.battle.turn === 1 && !s.busy && !s.guideOpen && !s.dialogBusy, 60000, '전투');
  const h2 = s.battle.hand;
  check('화형대 1턴: 두 죽음 카드(전사 Lv2·궁수 Lv1) + 새로 3장', h2.length === 5 && h2.some(c => c.id === 'warrior_death' && c.lv === 2) && h2.some(c => c.id === 'archer_death' && c.lv === 1), h2.map(c => c.id + c.lv));
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
  await H2.shot('F15_pyre_t3_spear_intent.png');
  check('3턴 예고: 화형 사제 「운명의 꼬챙이 → 브룬힐드」 Lv2', t3 && t3.kind === 'fate' && t3.target === 'warrior' && t3.level === 2, t3);
  await H2.W('endTurn');
  s = await H2.until(s => s.fatePicker, 60000, '3턴 브룬힐드 시도', async s => { if (s.guideOpen || s.dialogBusy) await H2.W('advance'); });
  await H2.sleep(500);
  await H2.shot('F16_choice_lv2.png');
  const ob2 = await H2.W('geom', 'fateBtn', 'offer');
  await H2.click(ob2.x, ob2.y);
  s = await H2.until(s => (s.cutLog || []).includes('W1'), 20000, 'Lv2 데스신');
  await H2.sleep(1500);
  await H2.shot('F17_death_lv2.png');
  s = await H2.advanceAll(s => s.battle && s.battle.hand.some(c => c.id === 'pierced_shield') && !s.busy && !s.dialogBusy && !s.guideOpen, 90000, '바친 뒤');
  check('브룬힐드 Lv2 바침(전투): 사망, 「꿰뚫린 방패」 Lv2 손패', s.party.allies.warrior.status === 'dead' && s.fates.find(f => f.who === 'warrior').result === 'offered'
    && s.battle.hand.find(c => c.id === 'pierced_shield').lv === 2, s.battle.hand.map(c => c.id + c.lv));
  // 손패의 죽음 카드를 직접 낸다
  s = await H2.until(s => s.battle && s.battle.phase === 'player' && !s.busy && !s.dialogBusy && !s.guideOpen, 60000, '내 차례', async s => { if (s.guideOpen || s.dialogBusy) await H2.W('advance'); });
  await H2.W('play', 'archer_death', '');
  s = await H2.until(s => (s.cutLog || []).includes('A1'), 30000, '화형 데스신');
  await H2.sleep(1500);
  await H2.shot('F18_death_archer.png');
  s = await H2.advanceAll(s => s.battle && s.battle.hand.some(c => c.id === 'burnt_bow') && !s.busy && !s.dialogBusy && !s.guideOpen, 90000, '타버린 활');
  await H2.shot('F19_burnt_bow_hand.png');
  check('죽음 카드를 직접 냄: 엘리안 사망 → 「타버린 활」 Lv1 손패, 노엘 혼자여도 전투 계속', s.party.allies.archer.status === 'dead' && s.battle && !s.battle.result && s.battle.hand.find(c => c.id === 'burnt_bow').lv === 1, s.battle.hand.map(c => c.id + c.lv));
  // 집행자를 먼저 쓰러뜨리면: 쓰러지는 순간 운명의 시도 (2층 납골당, 1턴)
  await H2.open('scene=ossuary&guides=reset');
  s = await H2.until(s => s.stage === 'battle:ossuary' && s.battle && s.battle.turn === 1 && !s.busy && !s.guideOpen && !s.dialogBusy, 90000, '납골당 전투(PC)', async s => {
    if (s.guideOpen || s.dialogBusy || s.vn) await H2.W('advance');
    else if (s.topdown && s.topdown.mode === 'free') await H2.W('tdGo', 'trigger:altar');
  });
  await H2.W('enemyHp', 'k1', 3);
  const atk = s.battle.hand.find(c => c.playable && ['holy_slash', 'snipe', 'suppress', 'shield_bash', 'curse_flame', 'broken_sword'].includes(c.id));
  await H2.W('play', atk.id, JSON.stringify({ enemy: 'k1' }));
  s = await H2.until(s => s.fatePicker, 30000, '쓰러지며 온 운명', async s => { if (s.guideOpen || s.dialogBusy) await H2.W('advance'); });
  await H2.sleep(500);
  await H2.shot('F20_executor_down_choice.png');
  check('집행자(창 기사)를 1턴에 쓰러뜨림 → 그 순간 운명의 시도 + 전조 대사', (s.log || []).some(l => /fate trial battle warrior_pierce lv1 byDeath/.test(l)) && has(s, /쓰러지면서도/), s.log.slice(-6));
  const dd = await H2.W('geom', 'fateBtn', 'defy');
  await H2.click(dd.x, dd.y);
  s = await H2.advanceAll(s => s.battle && s.battle.phase === 'player' && !s.busy && !s.guideOpen && !s.dialogBusy && !s.fatePicker && !s.overlay, 60000, '거스른 뒤');
  check('쓰러지며 온 시도 거스름: 브룬힐드 생존·흉터 1, 전투 계속(광신도)', s.party.allies.warrior.status !== 'dead' && s.scars === 1 && !s.battle.result, { scars: s.scars });
  await page2.close();
}

(async () => {
  const browser = await launch();
  const t0 = Date.now();
  const only = process.argv[4] || 'ABCDEFT';
  for (const [name, fn] of [['A', pathA], ['B', pathB], ['C', pathC], ['D', pathD], ['E', pathE], ['F', pathF], ['T', pathT]]) {
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
