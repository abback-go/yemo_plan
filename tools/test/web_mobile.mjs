// 모바일(안드로이드 태블릿 가로) 흉내 웹 시험: 터치로 시작 → 대화 넘기기 → 조이스틱·버튼 → 인터넷을 끊고 다시 열기
// 사용: node tools/test/web_mobile.mjs <스크린샷 폴더> [주소]   (game/ 에서 Web 내보내기 후 http.server로 띄워 둔다)
// playwright 경로는 환경마다 다름 (예: /opt/node22/lib/node_modules/playwright/index.mjs)
import { chromium } from '/opt/node22/lib/node_modules/playwright/index.mjs';
const out = process.argv[2];
const url = process.argv[3] || 'http://localhost:8766/index.html';
const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--autoplay-policy=no-user-gesture-required'] });
// 가로 태블릿 (CSS 1280×800, 기기 픽셀 비율 1.5)
const context = await browser.newContext({
	viewport: { width: 1280, height: 800 }, deviceScaleFactor: 1.5, isMobile: true, hasTouch: true,
	userAgent: 'Mozilla/5.0 (Linux; Android 14; SM-X710) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36',
});
const page = await context.newPage();
const logs = [];
page.on('console', m => logs.push(m.type() + ': ' + m.text()));
page.on('pageerror', e => logs.push('pageerror: ' + e.message));
const cdp = await context.newCDPSession(page);
// 게임 좌표(640×360) → CSS 좌표. 1280×800 화면에서 정수 배율 2, 위아래 검은 띠 40px
const G = (gx, gy) => ({ x: gx * 2, y: 40 + gy * 2 });
const touch = (type, pts) => cdp.send('Input.dispatchTouchEvent', { type, touchPoints: pts.map((p, i) => ({ x: p.x, y: p.y, id: p.id ?? i })) });
const tapG = async (gx, gy, ms = 80) => { const p = G(gx, gy); await touch('touchStart', [p]); await page.waitForTimeout(ms); await touch('touchEnd', []); };
const wait = ms => page.waitForTimeout(ms);
const shot = name => page.screenshot({ path: `${out}/${name}.png` });

await page.goto(url);
await wait(10000);
await shot('m1_title');
const sw = await page.evaluate(async () => {
	const reg = await navigator.serviceWorker.getRegistration();
	await navigator.serviceWorker.ready;
	const keys = await caches.keys();
	const files = [];
	for (const k of keys) for (const r of await (await caches.open(k)).keys()) files.push(r.url.split('/').pop());
	return { registered: !!reg, controlled: !!navigator.serviceWorker.controller, caches: keys, files };
});
console.log('SW', JSON.stringify(sw));

await tapG(320, 200); await wait(800);          // 화면을 누르세요 → 메뉴
await shot('m2_menu');
await tapG(300, 204); await wait(3000);         // 새로 시작 (기록이 없으면 첫 항목)
for (let i = 0; i < 14; i++) { await tapG(320, 180); await wait(900); }  // 오프닝 대사·안내 넘기기
await shot('m3_play');
// 조이스틱 오른쪽 1.5초 + 그 사이 점프 버튼 (두 손가락)
const s0 = G(100, 280), s1 = G(140, 282), j = G(530, 320);
await touch('touchStart', [{ ...s0, id: 0 }]);
await touch('touchMove', [{ ...s1, id: 0 }]);
await wait(700);
await touch('touchStart', [{ ...s1, id: 0 }, { ...j, id: 1 }]);
await wait(150);
await shot('m4_run_jump');
await touch('touchEnd', [{ ...s1, id: 0 }]);
await wait(700);
await touch('touchEnd', []);
await wait(500);
await shot('m5_after');
await tapG(618, 20); await wait(700);           // 일시정지 버튼
await shot('m6_pause');
await tapG(80, 126); await wait(500);           // 계속하기

// 인터넷 끊고 다시 열기
await context.setOffline(true);
await page.reload();
await wait(10000);
await shot('m7_offline_reload');
const offlineTitle = await page.title();
console.log('OFFLINE title', offlineTitle, 'controlled', await page.evaluate(() => !!navigator.serviceWorker.controller));
console.log(logs.filter(l => !l.includes('[.WebGL') && !l.includes('GPU stall')).slice(0, 40).join('\n'));
await browser.close();
