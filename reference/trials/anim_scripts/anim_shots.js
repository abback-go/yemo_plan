// 움직임 비교 자료: 그 전 기본(base = ?anim=off) / A′(a — 2026-11-22부터 기본. C 는 지움) — 장례 회랑 전투 1턴: 대기 → 세라피나 성검 베기(공격) → 턴 종료(세라피나·엘리안·브룬힐드 피격)
// node anim_shots.js <주소> <출력 폴더> <모드: base|a|c> [nohand]
// 영상(webm)을 녹화하고, 각 구간의 시작·끝 시각(영상 기준 초)을 times.json 에 남긴다 → 스틸은 영상에서 ffmpeg 로 뽑는다(스크린샷은 swiftshader 에서 느려 연속 촬영이 안 됨)
'use strict';
const { chromium } = require('/opt/node-tools/node_modules/playwright');
const fs = require('fs');
const path = require('path');
const BASE = process.argv[2].replace(/\/?$/, '/');
const OUT = process.argv[3];
const MODE = process.argv[4] || 'base';
const NOHAND = process.argv[5] === 'nohand';
const dir = path.join(OUT, 'anim_' + MODE + (NOHAND ? '_nohand' : ''));
fs.mkdirSync(dir, { recursive: true });
const errors = [];
const times = {};

(async () => {
  const browser = await chromium.launch({ args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: 1, recordVideo: { dir: path.join(dir, 'video'), size: { width: 1280, height: 720 } } });
  const page = await ctx.newPage();
  const T0 = Date.now();
  const mark = k => { times[k] = (Date.now() - T0) / 1000; };
  page.on('console', m => { const t = m.text(); if (m.type() === 'error' || /^(SCRIPT )?ERROR:/.test(t)) errors.push(t); });
  page.on('pageerror', e => errors.push('pageerror: ' + e.message));
  const W = (name, ...args) => page.evaluate(([n, a]) => { window.__witchOut = null; window.witch[n](...a); return JSON.parse(window.__witchOut || 'null'); }, [name, args]);
  const sleep = ms => page.waitForTimeout(ms);
  const until = async (pred, timeout, what) => {
    const t0 = Date.now();
    let s;
    while (Date.now() - t0 < timeout) { s = await W('state'); if (pred(s)) return s; await sleep(100); }
    throw new Error('timeout ' + what);
  };
  const shot = async name => page.screenshot({ path: path.join(dir, name) });
  const q = 'index.html?test=1&seed=7&scene=corridor&autoguide=1&nosave=1&guides=reset&trace=1' + (MODE === 'base' ? '&anim=off' : '&anim=' + MODE);
  await page.goto(BASE + q);
  await page.waitForFunction(() => window.__witchReady === true, null, { timeout: 90000 });
  let s = await until(s => s.battle && s.battle.turn === 1 && !s.busy && !s.guideOpen && !s.dialogBusy, 120000, 'turn1');
  if (NOHAND) await W('hideHand', true);
  await sleep(800);
  mark('idle0');
  await shot('idle_0.png');
  await sleep(1500);
  await shot('idle_1.png');
  await sleep(2500);
  mark('idle1');
  // 공격: 0.3배 속도로 성검 베기 → 광신도 c1
  await W('setSpeed', 0.3);
  mark('play');
  const r = await W('play', 'holy_slash', JSON.stringify({ enemy: 'c1' }));
  if (!r || !r.ok) throw new Error('play failed ' + JSON.stringify(r));
  await until(s => (s.motionLog || []).length > 0, 60000, 'strike start');
  mark('strike');
  await until(s => !s.busy, 60000, 'attack end');
  mark('attackEnd');
  // 피격: 턴 종료 → 적의 차례 (가운데 광신도 → 세라피나, 오른쪽 → 엘리안)
  await W('endTurn');
  mark('endTurn');
  // 세라피나·엘리안의 HP 가 줄어드는 순간을 표시(영상에서 피격 장면을 찾는 데 쓴다)
  await until(s => {
    // 규칙은 턴 종료 때 한꺼번에 계산되고 화면은 이벤트를 차례로 그린다 → HP 대신 첫 'ev enemyAct'(가운데 광신도 → 세라피나)를 본다
    if ((s.log || []).some(l => /ev enemyAct/.test(l)) && times.heroHit === undefined) mark('heroHit');
    return s.battle && s.battle.turn === 2;
  }, 90000, 'turn2');
  mark('turn2');
  await W('setSpeed', 1);
  await until(s => !s.busy, 60000, 'turn2 idle').catch(() => {});
  // 일시정지: 멈춘 동안 그림이 그대로인지(숨쉬기·뼈대도 멈춤) — 두 장의 화면을 비교한다
  await page.keyboard.press('Escape');
  await until(s => s.menu && s.menu.paused, 5000, 'paused');
  await sleep(600);
  const p0 = await page.screenshot({ clip: { x: 0, y: 150, width: 1280, height: 400 } });
  await sleep(1900);
  const p1 = await page.screenshot({ clip: { x: 0, y: 150, width: 1280, height: 400 } });
  const pauseSame = Buffer.compare(p0, p1) === 0;
  await page.keyboard.press('Escape');
  await sleep(500);
  s = await W('state');
  fs.writeFileSync(path.join(dir, 'state.json'), JSON.stringify({ mode: MODE, nohand: NOHAND, errors, pauseSame, times, motion: s.motionLog,
    hp: s.party && Object.fromEntries(Object.entries(s.party.allies).map(([k, v]) => [k, v.hp])), log: (s.log || []).slice(-12) }, null, 1));
  await ctx.close();
  await browser.close();
  console.log(MODE + (NOHAND ? ' nohand' : ''), 'errors', errors.length, 'pauseSame', pauseSame, JSON.stringify(times));
  if (errors.length) console.log(errors.slice(0, 5).join('\n'));
})().catch(e => { console.error('FAIL', e.message, errors.slice(0, 5)); process.exit(1); });
