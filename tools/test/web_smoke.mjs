// playwright 경로는 환경마다 다름 (예: /opt/node22/lib/node_modules/playwright/index.mjs)
import { chromium } from '/opt/node22/lib/node_modules/playwright/index.mjs';
const out = process.argv[2];
const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--autoplay-policy=no-user-gesture-required'] });
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
const logs = [];
page.on('console', m => logs.push(m.type() + ': ' + m.text()));
page.on('pageerror', e => logs.push('pageerror: ' + e.message));
const t0 = Date.now();
await page.goto('http://localhost:8766/index.html');
await page.waitForTimeout(9000);
await page.screenshot({ path: out + '/y1_title.png' });
const tap = async (k, ms = 80) => { await page.keyboard.down(k); await page.waitForTimeout(ms); await page.keyboard.up(k); };
await page.mouse.click(640, 360);
await page.waitForTimeout(800);
await tap('KeyZ'); await page.waitForTimeout(700);   // 아무 키 → 메뉴
await page.screenshot({ path: out + '/y2_menu.png' });
// 메뉴: 저장이 없으면 첫 항목이 "새로 시작"
await tap('Enter'); await page.waitForTimeout(3000);
await page.screenshot({ path: out + '/y3_intro.png' });
for (let i = 0; i < 12; i++) { await tap('KeyZ'); await page.waitForTimeout(900); }
await page.screenshot({ path: out + '/y4_pass.png' });
await tap('ArrowRight'); await page.waitForTimeout(300);
await page.keyboard.down('ArrowRight'); await page.waitForTimeout(1200);
await page.screenshot({ path: out + '/y5_run.png' });
await page.keyboard.up('ArrowRight');
for (let i = 0; i < 4; i++) { await tap('KeyZ'); await page.waitForTimeout(600); }
await page.keyboard.down('ArrowRight'); await page.waitForTimeout(1500); await page.keyboard.up('ArrowRight');
await page.screenshot({ path: out + '/y6_more.png' });
await tap('Tab'); await page.waitForTimeout(600);
await page.screenshot({ path: out + '/y7_map.png' });
await tap('Tab'); await page.waitForTimeout(300);
await tap('Escape'); await page.waitForTimeout(500);
await page.screenshot({ path: out + '/y8_pause.png' });
await tap('Escape'); await page.waitForTimeout(300);
console.log('elapsed ms', Date.now() - t0);
console.log(logs.filter(l => !l.includes('[.WebGL')).slice(0, 60).join('\n'));
await browser.close();
