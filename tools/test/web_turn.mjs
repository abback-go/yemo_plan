// 턴제(?turn) 웹 연기 시험 — 안드로이드 폰 가로 흉내 (터치 · 기기 픽셀 비율 · Android UA)
// 사용: node ../tools/test/web_turn.mjs <스크린샷 폴더> [주소] [CSS폭x높이@비율] [CPU 느리게 배수]
//   주소 기본 http://localhost:8766/index.html?turn&probe  (probe = 게임이 window.eskaProbe()로 화면 상태·누를 자리를 알려 줌, t_stage.gd _on_probe)
//   화면 기본 915x412@2.625 (20:9 갤럭시급) · 19.5:9 흉내는 844x390@3
//   CPU 배수(예 3)를 주면 CDP Emulation.setCPUThrottlingRate로 프레임을 길게 — 느린 프레임에서 짧은 탭이 길게 누르기로 먹히는지 (review_K K-10)
// 흐름: 타이틀(R6) → 첫 탭(이 탭을 뗄 때 전체 화면 요청 — R3 review_N N-02 · 첫 실행이라 곧장 안내 전투) → "안내 끄기" → X → 철수 → 편성
//       → 전투 고르기 → 출격 → 마녀 차례마다 기본 공격 칸 두 번 → 적 카드 짧게 탭(80~150 ms) — 탭이 먹혔는지 센다
//       → 적 카드 길게 누름(상세) → X → 철수 확인 → 취소 → **세로로 돌림(세로 안내 · 전투 멈춤) → 가로로 되돌림 → 멈춤 판 탭**
//       → 창 가려짐(visibilitychange) → localStorage 저장 → 새로고침 → 끊긴 전투 판
//   세로 화면(예 412x915@2.625)으로 시작하면: 세로 안내 판이 뜨고 누름을 먹는지만 보고 끝낸다
//   주소 막대 흉내(915x356@2.625): 전체 화면이 안 되면(헤드리스) 다시 들어가는 버튼이 보이는지 · 누르면 요청하는지
// 출력: 화면 배율·띠, 탭 결과, 콘솔 오류·경고 수. 통과 기준: "TAPS ok n/n" · "CONSOLE errors 0" · "RESUME panel resume" · "ROTATE portrait true pause true → back false"
// playwright 경로는 환경마다 다름 (예: /opt/node22/lib/node_modules/playwright/index.mjs)
import { chromium } from '/opt/node22/lib/node_modules/playwright/index.mjs';
const out = process.argv[2] || '/tmp/web_turn';
const url = process.argv[3] || 'http://localhost:8766/index.html?turn&probe';
const vm = (process.argv[4] || '915x412@2.625').match(/(\d+)x(\d+)@([\d.]+)/);
const W = +vm[1], H = +vm[2], DPR = +vm[3];
const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--autoplay-policy=no-user-gesture-required'] });
const context = await browser.newContext({
	viewport: { width: W, height: H }, deviceScaleFactor: DPR, isMobile: true, hasTouch: true,
	userAgent: 'Mozilla/5.0 (Linux; Android 14; SM-S921N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36',
});
const page = await context.newPage();
const logs = [];
page.on('console', m => logs.push(m.type() + ': ' + m.text()));
page.on('pageerror', e => logs.push('pageerror: ' + e.message));
const cdp = await context.newCDPSession(page);
const THROTTLE = +(process.argv[5] || 1);
const wait = ms => page.waitForTimeout(ms);
const shot = name => page.screenshot({ path: `${out}/${name}.png` });
const probe = async () => page.evaluate(() => { if (!window.eskaProbe) return null; window.eskaProbe(); return JSON.parse(window.eskaState); });
// 설계 좌표(640×360 화면 기준) → CSS 좌표: 창 픽셀 = origin + (ofs + p) × scale, CSS = 창 픽셀 / 비율 + 캔버스 자리
let canvasBox = null;
const toCss = (st, gx, gy) => ({ x: canvasBox.x + (st.origin[0] + (st.ofs[0] + gx) * st.scale) / DPR, y: canvasBox.y + (st.origin[1] + (st.ofs[1] + gy) * st.scale) / DPR });
const center = r => [r[0] + r[2] / 2, r[1] + r[3] / 2];
const touch = (type, pts) => cdp.send('Input.dispatchTouchEvent', { type, touchPoints: pts.map((p, i) => ({ x: p.x, y: p.y, id: i })) });
const tapAt = async (st, gx, gy, ms = 90) => { const p = toCss(st, gx, gy); await touch('touchStart', [p]); await wait(ms); await touch('touchEnd', []); };
const until = async (fn, ms = 20000) => { const t0 = Date.now(); while (Date.now() - t0 < ms) { const st = await probe(); if (st && fn(st)) return st; await wait(150); } return await probe(); };

await page.goto(url);
let st = await until(s => s !== null, 60000);
canvasBox = await page.evaluate(() => { const c = document.querySelector('canvas'); const r = c.getBoundingClientRect(); return { x: r.x, y: r.y, w: r.width, h: r.height, cw: c.width, ch: c.height }; });
await wait(1500);
st = await probe();
const usedW = (640 + 2 * st.ofs[0]) * st.scale, usedH = (360 + 2 * st.ofs[1]) * st.scale;
console.log(`SCREEN css ${W}x${H}@${DPR} canvas ${canvasBox.cw}x${canvasBox.ch} scale ${st.scale.toFixed(3)} view ${st.view.join('x')} ofs ${st.ofs.join(',')} origin ${st.origin.map(v => v.toFixed(1)).join(',')} used ${(100 * usedW / canvasBox.cw).toFixed(1)}% x ${(100 * usedH / canvasBox.ch).toFixed(1)}%`);
await shot('t1_first');
const fsDoc = async () => page.evaluate(() => !!document.fullscreenElement);
console.log(`FS web ${st.fs_web} tried ${st.fs_tried} is ${st.fs_is} portrait ${st.portrait}`);
if (H > W) {
	// 세로로 시작: 세로 안내 판 · 누름을 먹음 (편성 단계가 그대로)
	await tapAt(st, 320, 180); await wait(600);
	const s2 = await probe();
	await shot('p1_portrait');
	console.log(`PORTRAIT start ${st.portrait} after-tap ${s2.portrait} setup_step ${st.setup_step}→${s2.setup_step} card '${st.card}'→'${s2.card}' doc-fullscreen ${await fsDoc()}`);
	const errs0 = logs.filter(l => l.startsWith('error') || l.startsWith('pageerror'));
	console.log(`CONSOLE errors ${errs0.length} warnings ${logs.filter(l => l.startsWith('warning')).length} lines ${logs.length}`);
	for (const l of logs) console.log('  ' + l.slice(0, 300));
	await browser.close();
	process.exit(0);
}
// 타이틀 → 첫 탭 (이 탭을 뗄 때 전체 화면 요청 · 첫 실행이면 곧장 안내 전투 — R6 review_P D-2)
const title0 = st.guide_mode;
await tapAt(st, 320, 220); await wait(800);
st = await until(s => s.guide_mode !== 'title', 10000);
console.log(`TITLE mode '${title0}' → '${st.guide_mode}' in_battle ${st.in_battle} phase '${st.phase}'`);
st = await probe();
console.log(`FS after-first-tap tried ${st.fs_tried} is ${st.fs_is} doc-fullscreen ${await fsDoc()} btn ${JSON.stringify(st.fs_btn)} view ${st.view.join('x')}`);
if (await fsDoc()) {
	// 사용자가 전체 화면을 나간 것처럼 → 다시 들어가는 버튼이 떠야 함 (다음 탭에 저절로 다시 요청하지 않음)
	await page.evaluate(() => document.exitFullscreen().catch(() => {})); await wait(1200);
	canvasBox = await page.evaluate(() => { const c = document.querySelector('canvas'); const r = c.getBoundingClientRect(); return { x: r.x, y: r.y, w: r.width, h: r.height, cw: c.width, ch: c.height }; });
	st = await probe();
	console.log(`FS exited is ${st.fs_is} doc-fullscreen ${await fsDoc()} btn ${JSON.stringify(st.fs_btn)}`);
}
if (st.fs_btn && st.fs_btn[2] > 0) {
	await shot('t2b_fs_button');
	const b = center(st.fs_btn);
	const before = st.setup_step;
	await tapAt(st, b[0], b[1]); await wait(600);
	const s2 = await probe();
	console.log(`FS button tap → is ${s2.fs_is} doc-fullscreen ${await fsDoc()} setup_step ${before}→${s2.setup_step}`);
	st = s2;
}
// 안내 전투: B1 판이 뜨면 "안내 끄기" → X → 철수 (오른쪽) → 편성 (안내 전투는 이어 하기 저장을 쓰지 않아 일반 전투로 시험)
st = await until(s => s.card !== '' || !s.in_battle, 20000);
await shot('t1b_intro');
if (st.card) { const o = center(st.off); await tapAt(st, o[0], o[1]); await wait(500); }
st = await until(s => s.in_battle && s.hud_state === 'wheel', 20000);
if (st.in_battle) {
	const xr = center(st.x_rect); await tapAt(st, xr[0], xr[1]); await wait(500);
	st = await probe(); await tapAt(st, 368, 201); await wait(800);  // 철수 (오른쪽)
}
st = await until(s => s.setup_visible && s.guide_mode === '', 10000);
console.log(`INTRO off → setup ${st.setup_visible} step ${st.setup_step} card '${st.card}'`);
await shot('t2_setup');
let c = center(st.start1);
await tapAt(st, c[0], c[1]); await wait(800);             // 전투 고르기
await shot('t3_battles');
st = await probe();
await tapAt(st, c[0], c[1]);                               // 출격
st = await until(s => s.in_battle && s.hud_state === 'wheel', 30000);
await shot('t4_battle');
if (THROTTLE > 1) await cdp.send('Emulation.setCPUThrottlingRate', { rate: THROTTLE });
// 마녀 차례마다: 기본 공격 칸 두 번 → 대상 고르기 → 적 카드 짧게 탭
const taps = [];
for (let k = 0; k < 6; k++) {
	st = await until(s => s.in_battle && s.hud_state === 'wheel', 30000);
	if (!(st.in_battle && st.hud_state === 'wheel')) break;
	const s0 = center(st.slots[0]);
	await tapAt(st, s0[0], s0[1], 70); await wait(250);
	await tapAt(st, s0[0], s0[1], 70); await wait(250);
	st = await probe();
	if (st.hud_state !== 'target') { taps.push({ k, why: 'no target state', state: st.hud_state }); continue; }
	const ci = st.cards.findIndex(r => r.length);
	const cc = center(st.cards[ci]);
	const ms = 80 + 14 * k;
	if (k === 1) await shot('t5_target');
	await tapAt(st, cc[0], cc[1], ms); await wait(300);
	const s2 = await probe();
	const ok = s2.hud_state !== 'target';
	taps.push({ k, ms, ok, after: s2.hud_state, press: s2.last_press });
	if (k === 0) await shot('t6_after_tap');
}
if (THROTTLE > 1) await cdp.send('Emulation.setCPUThrottlingRate', { rate: 1 });
const okN = taps.filter(t => t.ok).length;
console.log(`TAPS ok ${okN}/${taps.length}`);
for (const t of taps) console.log('  TAP', JSON.stringify(t));
// 길게 누름 = 상세 (떼면 닫힘)
st = await until(s => s.in_battle && s.hud_state === 'wheel', 30000);
if (st.cards) {
	const cc = center(st.cards[st.cards.findIndex(r => r.length)]);
	const p = toCss(st, cc[0], cc[1]);
	await touch('touchStart', [p]); await wait(900); await shot('t7_detail'); await touch('touchEnd', []); await wait(300);
	const s3 = await probe();
	console.log('HOLD', JSON.stringify(s3.last_press), 'state', s3.hud_state);
}
// X → 철수 확인 → 취소
st = await probe();
c = center(st.x_rect);
await tapAt(st, c[0], c[1]); await wait(500);
await shot('t8_confirm');
st = await probe();
console.log('CONFIRM open', st.confirm);
await tapAt(st, 270, 200); await wait(400);                // 취소 (왼쪽)
// 세로로 돌림 → 세로 안내 + 전투 멈춤 → 가로로 되돌림 → 멈춤 판을 눌러 계속 (R3, review_N N-02)
st = await until(s => s.in_battle && s.hud_state === 'wheel', 30000);
await page.setViewportSize({ width: H, height: W }); await wait(900);
const sp = await probe();
await shot('t8b_rotated');
await page.setViewportSize({ width: W, height: H }); await wait(900);
const sb = await probe();
await shot('t8c_back');
console.log(`ROTATE portrait ${sp.portrait} pause ${sp.guide_mode === 'pause'} view ${sp.view.join('x')} → back ${sb.portrait} mode '${sb.guide_mode}'`);
canvasBox = await page.evaluate(() => { const c = document.querySelector('canvas'); const r = c.getBoundingClientRect(); return { x: r.x, y: r.y, w: r.width, h: r.height, cw: c.width, ch: c.height }; });
if (sb.guide_mode === 'pause') { await tapAt(sb, 320, 180); await wait(500); }
// 창 가려짐 → 저장 → 새로고침 → 끊긴 전투 판
st = await until(s => s.in_battle && s.hud_state === 'wheel', 30000);
await page.evaluate(() => { Object.defineProperty(document, 'visibilityState', { value: 'hidden', configurable: true }); document.dispatchEvent(new Event('visibilitychange')); });
await wait(800);
const saved = await page.evaluate(() => { const v = localStorage.getItem('eska_turn_battle'); return v ? v.length : 0; });
console.log('SAVED localStorage bytes', saved);
await page.reload();
st = await until(s => s !== null && s.guide_mode !== '', 60000);
await wait(1500);
await shot('t9_resume');
console.log('RESUME panel', st ? st.guide_mode : null);
const errs = logs.filter(l => l.startsWith('error') || l.startsWith('pageerror'));
const warns = logs.filter(l => l.startsWith('warning'));
console.log(`CONSOLE errors ${errs.length} warnings ${warns.length} lines ${logs.length}`);
for (const l of logs) if (!l.startsWith('log: PRESS')) console.log('  ' + l.slice(0, 300));
await browser.close();
