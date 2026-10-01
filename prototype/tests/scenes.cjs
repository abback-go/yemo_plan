// 개별 장면 캡처: 사건 시트·대화·전투 연출을 직접 띄워 스크린샷으로 확인한다.
const path = require('path');
const { chromium } = require('/opt/node22/lib/node_modules/playwright');
const URL = 'file://' + path.join(__dirname, '..', 'dist', 'index.html');
(async () => {
  const b = await chromium.launch();
  const page = await (await b.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1, isMobile: true, hasTouch: true })).newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));
  page.on('console', (m) => { if (m.type() === 'error' && !/ERR_CERT|fonts\./.test(m.text())) errors.push(m.text()); });
  await page.goto(URL);
  await page.waitForTimeout(200);
  const shot = async (n) => { await page.waitForTimeout(450); await page.screenshot({ path: path.join(__dirname, 'out', `scene-${n}.png`) }); };
  // 중반 상태 만들기
  await page.evaluate(() => {
    const R = W.rules, s = R.newGame();
    s.flags.introSeen = true; s.flags.metCustomer = true; s.flags.dungeonTip = true; s.flags.battleTip = true; s.flags.clubTip = true;
    R.gainExp(s, 20 + 45 + 80); s.floorsReached = 3; s.silver = 320; s.inv = { hp_potion: 4, mp_potion: 2, key: 1, salt: 1, herb: 1, feather: 1 };
    R.refreshCustomers(s); R.acceptQuest(s, 'q1'); s.silver += 200; R.acceptQuest(s, 'q4'); R.acceptQuest(s, 'q6');
    W.game.state = s; R.startExpedition(s, 3); W.ui.debug.snapPos(); W.ui.go('dungeon');
  });
  await shot('b3-map');
  const scenes = [
    ['quiz', { type: 'event', ev: 'quiz', x: 1, y: 1 }],
    ['jar', { type: 'event', ev: 'jar', x: 1, y: 1 }],
    ['door', { type: 'door' }],
    ['fountain', { type: 'fountain', x: 1, y: 1 }],
    ['merchant', { type: 'merchant' }],
    ['rumor', { type: 'event', ev: 'rumor', x: 1, y: 1 }],
  ];
  for (const [name, e] of scenes) {
    page.evaluate((ev) => { W.ui.debug.handleEvent(ev, 4, 5); }, e);
    await shot(name);
    await page.evaluate(() => { const c = document.querySelector('#sheet [data-act="choose"]:last-of-type') || document.querySelector('#sheet [data-act="sheetDismiss"]'); if (c) c.click(); });
    await page.evaluate(() => { const c = document.querySelector('#sheet [data-act="choose"]'); if (c) c.click(); });
    await page.waitForTimeout(150);
  }
  // 극장장 전투 + 기 모으기
  page.evaluate(() => W.ui.runBattle('director', {}));
  await page.waitForTimeout(700);
  await page.evaluate(() => { const B = W.game.ui.battle; B.b.charging = true; B.b.pcurse = 2; W.game.state.player.status.poison = 3; });
  await page.click('[data-act="bmenu"][data-arg="spell"]');
  await shot('director-charging');
  await page.click('[data-act="bspell"][data-arg="ice"]');
  await page.waitForTimeout(250);
  await shot('director-hit');
  await page.evaluate(() => { const B = W.game.ui.battle; B.b.hp = 1; B.b.traits = {}; });
  await page.waitForTimeout(1600);
  await page.click('[data-act="battack"]');
  await page.waitForTimeout(1800);
  await shot('victory');
  // 레벨업 시트
  await page.evaluate(() => { const c = document.querySelector('#sheet [data-act="choose"]'); if (c) c.click(); });
  await page.waitForTimeout(300);
  await shot('levelup-or-next');
  await page.evaluate(() => { for (let i = 0; i < 4; i++) { const c = document.querySelector('#sheet [data-act="choose"]'); if (c) c.click(); } });
  // 보스 대화
  page.evaluate(() => W.ui.debug.say(W.DATA.LINES.bossIntro));
  await page.waitForTimeout(900);
  await shot('boss-dialog');
  await page.click('.dialog-skip');
  // 녹턴 방패 페이즈
  page.evaluate(() => W.ui.runBattle('nocturne', {}));
  await page.waitForTimeout(700);
  await page.evaluate(() => { const B = W.game.ui.battle; B.b.shield = 2; B.b.hp = 240; W.game.state.known.nocturne = { weak: true }; W.rules.gainExp(W.game.state, 400); W.game.state.player.mp = 40; });
  await page.evaluate(() => W.ui.ACT.bmenu('spell'));
  await shot('nocturne-shield');
  // 엔딩 대화
  await page.evaluate(() => { const B = W.game.ui.battle; B.b.hp = 1; });
  await page.click('[data-act="bspell"][data-arg="light"]');
  await page.waitForTimeout(2500);
  await page.evaluate(() => { for (let i = 0; i < 4; i++) { const c = document.querySelector('#sheet [data-act="choose"]'); if (c) c.click(); } });
  await page.evaluate(() => { const s = W.game.state; s.flags.bossDefeated = true; s.purified = 5; s.exp = null; W.ui.go('hub'); W.ui.debug.maybeEnding(); });
  await page.waitForTimeout(1500);
  await shot('ending-dialog');
  for (let i = 0; i < 6; i++) { await page.click('.dialog-skip').catch(() => {}); await page.waitForTimeout(100); }
  await shot('ending-card');
  console.log(JSON.stringify({ errors }));
  await b.close();
})();
