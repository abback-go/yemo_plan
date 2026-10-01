/* 저주 매입합니다 — 화면과 흐름 */
(function () {
  'use strict';
  const W = globalThis.W;
  const D = W.DATA, R = W.rules, A = W.art, S = W.audio;
  const SAVE_KEY = 'curse-antique-save-v1';
  const STEP_MS = 120;

  const G = (W.game = {
    state: null,
    ui: { screen: 'title', shopTab: 'potion', log: [], tip: 0, busy: false, tile: 32, dialog: null, battle: null },
  });

  // ───────── 공용 도우미 ─────────
  const $ = (sel, root) => (root || document).querySelector(sel);
  const $$ = (sel, root) => Array.from((root || document).querySelectorAll(sel));
  const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  // 테스트에서 W.game.ui.speed 로 연출 시간을 줄일 수 있다
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms * ((W.game && W.game.ui.speed) || 1)));
  const dpr = () => Math.min(3, window.devicePixelRatio || 1);
  const img = (name, cls, px) => `<img class="${cls || 'ico'}" src="${A.iconURL(name, px || 64)}" alt="">`;
  const coin = () => `<img src="${A.iconURL('coin', 32)}" alt="은화">`;
  const gradeTag = (g) => `<span class="grade" style="color:${D.GRADES[g].color}">${D.GRADES[g].name}</span>`;
  function sprite(name, opts, cls, anim) {
    return `<canvas class="${cls || ''}" data-sprite="${name}" data-opts='${esc(JSON.stringify(opts || {}))}'${anim ? ' data-anim="1"' : ''}></canvas>`;
  }
  function portrait(npcId, cls, anim, mood) {
    const p = A.portraitOf(npcId);
    return sprite(p.name, { npc: p.npc, mood }, cls, anim);
  }

  // 애니메이션 루프 (레이어별)
  const anims = { screen: new Set(), overlay: new Set(), sheet: new Set(), dialog: new Set() };
  function addAnim(layer, fn) { anims[layer].add(fn); fn(performance.now() / 1000); return fn; }
  function clearAnims(layer) { anims[layer].clear(); }
  function loop(ts) {
    const t = ts / 1000;
    for (const k of Object.keys(anims)) for (const f of anims[k]) { try { f(t); } catch (e) { console.error(e); anims[k].delete(f); } }
    requestAnimationFrame(loop);
  }
  function paintCanvases(root, layer) {
    for (const cv of $$('canvas[data-sprite]', root)) {
      const w = cv.clientWidth || 48, h = cv.clientHeight || w;
      const k = dpr();
      cv.width = Math.round(w * k); cv.height = Math.round(h * k);
      const ctx = cv.getContext('2d');
      const name = cv.dataset.sprite;
      let opts = {};
      try { opts = JSON.parse(cv.dataset.opts || '{}'); } catch (e) { opts = {}; }
      const size = Math.min(cv.width, cv.height);
      const ox = (cv.width - size) / 2, oy = (cv.height - size) / 2;
      const paint = (t) => { ctx.clearRect(0, 0, cv.width, cv.height); A.draw(ctx, name, ox, oy, size, Object.assign({}, opts, { t })); };
      if (cv.dataset.anim) addAnim(layer, (t) => { if (cv.isConnected) paint(t); });
      else paint(0.6);
    }
  }

  // 저장
  function save() { try { localStorage.setItem(SAVE_KEY, R.serialize(G.state)); } catch (e) { /* 저장 불가 환경 */ } }
  function loadSave() { try { const s = localStorage.getItem(SAVE_KEY); return s ? R.deserialize(s) : null; } catch (e) { return null; } }
  function clearSave() { try { localStorage.removeItem(SAVE_KEY); } catch (e) { /* 무시 */ } }

  // 토스트·배너
  function toast(text, kind) {
    const box = $('#toasts'); if (!box) return;
    const el = document.createElement('div');
    el.className = 'toast ' + (kind || '');
    el.textContent = text;
    box.appendChild(el);
    setTimeout(() => el.remove(), 2500);
    while (box.children.length > 3) box.firstChild.remove();
  }
  function log(text) { G.ui.log.push(text); if (G.ui.log.length > 30) G.ui.log.shift(); refreshDungeonHUD(); }

  // ───────── 시트(아래에서 올라오는 창) ─────────
  let sheetResolve = null;
  function openSheet(o) {
    clearAnims('sheet');
    const root = $('#sheet');
    root.innerHTML = `<div class="sheet-back" ${o.dismiss === false ? '' : 'data-act="sheetDismiss"'}></div>
      <div class="sheet" role="dialog" aria-modal="true">
        <div class="grab"></div>
        ${o.title ? `<div class="sh-head">${o.icon || ''}<h2>${o.title}</h2>${o.dismiss === false ? '' : '<button class="icon-btn" data-act="sheetDismiss" aria-label="닫기">✕</button>'}</div>` : ''}
        <div class="sh-body">${o.art ? `<div class="art">${o.art}</div>` : ''}${o.body || ''}</div>
        ${o.foot ? `<div class="sh-foot">${o.foot}</div>` : ''}
      </div>`;
    paintCanvases(root, 'sheet');
    if (o.after) o.after(root);
  }
  function closeSheet(value) {
    clearAnims('sheet');
    $('#sheet').innerHTML = '';
    const r = sheetResolve; sheetResolve = null;
    if (r) r(value);
  }
  // 선택지 시트: choices = [{label, value, cls, disabled}]
  function ask(o) {
    return new Promise((resolve) => {
      if (sheetResolve) { const prev = sheetResolve; sheetResolve = null; prev(null); }
      sheetResolve = resolve;
      const foot = o.choices.map((c, i) => `<button class="btn ${c.cls || ''}" data-act="choose" data-arg="${i}" ${c.disabled ? 'disabled' : ''}>${c.label}</button>`).join('');
      G.ui.choices = o.choices;
      openSheet(Object.assign({}, o, { foot: o.vertical ? null : foot, body: (o.body || '') + (o.vertical ? `<div class="choices">${foot}</div>` : '') }));
    });
  }

  // ───────── 대화 ─────────
  function say(lines) {
    if (!lines || !lines.length) return Promise.resolve();
    return new Promise((resolve) => { G.ui.dialog = { lines, i: 0, resolve, shown: 0, timer: null }; renderDialog(); });
  }
  function renderDialog() {
    const d = G.ui.dialog;
    const root = $('#dialog');
    clearAnims('dialog');
    if (!d) { root.innerHTML = ''; return; }
    const line = d.lines[d.i];
    const npc = line.who ? D.NPCS[line.who] : null;
    root.innerHTML = `<div class="dialog-back" data-act="dlgNext"></div>
      <button class="btn small ghost dialog-skip" data-act="dlgSkip">건너뛰기 ≫</button>
      <div class="dialog ${npc ? '' : 'narr'}" data-act="dlgNext">
        ${npc ? portrait(line.who, 'face', true, line.mood) : ''}
        <div class="box"><div class="who">${npc ? esc(npc.name) : ''}</div><div class="txt"></div><div class="next">탭해서 계속 ▸</div></div>
      </div>`;
    paintCanvases(root, 'dialog');
    const txt = $('.txt', root);
    const full = line.text;
    d.shown = 0;
    clearInterval(d.timer);
    d.timer = setInterval(() => {
      d.shown = Math.min(full.length, d.shown + 2);
      txt.textContent = full.slice(0, d.shown);
      if (d.shown >= full.length) clearInterval(d.timer);
    }, 24);
  }
  function dialogNext() {
    const d = G.ui.dialog; if (!d) return;
    const full = d.lines[d.i].text;
    if (d.shown < full.length) { clearInterval(d.timer); d.shown = full.length; $('#dialog .txt').textContent = full; return; }
    d.i += 1;
    if (d.i >= d.lines.length) { clearInterval(d.timer); G.ui.dialog = null; renderDialog(); d.resolve(); return; }
    S.play('tap');
    renderDialog();
  }
  function dialogSkip() { const d = G.ui.dialog; if (!d) return; clearInterval(d.timer); G.ui.dialog = null; renderDialog(); d.resolve(); }

  // ───────── 상태바 ─────────
  function statusBar() {
    const s = G.state;
    const st = R.stats(s);
    const hpP = Math.round((s.player.hp / st.maxHp) * 100);
    const mpP = Math.round((s.player.mp / st.maxMp) * 100);
    const status = [];
    if (s.player.status.poison) status.push('<span class="chip bad">독</span>');
    if (s.player.status.curseNext) status.push('<span class="chip curse">저주 연기</span>');
    return `<div class="status">
      <div class="lv">Lv${s.player.lv}</div>
      <div class="bars">
        <div class="bar hp"><i style="width:${hpP}%"></i><span>체력 ${s.player.hp}/${st.maxHp}</span></div>
        <div class="bar mp"><i style="width:${mpP}%"></i><span>마력 ${s.player.mp}/${st.maxMp}</span></div>
      </div>
      ${status.join('')}
      <div class="money">${coin()}${s.silver}</div>
    </div>`;
  }

  // ───────── 화면 ─────────
  const SCREENS = {};
  const AFTER = {};

  function render() {
    clearAnims('screen');
    const html = SCREENS[G.ui.screen]();
    $('#screen').innerHTML = html;
    paintCanvases($('#screen'), 'screen');
    if (AFTER[G.ui.screen]) AFTER[G.ui.screen]();
  }
  function go(screen) { G.ui.screen = screen; render(); }

  // 타이틀
  SCREENS.title = () => {
    const sv = loadSave();
    G.ui.hasSave = !!sv;
    return `<div class="title">
      <canvas class="bgfx" id="title-fx"></canvas>
      <div class="logo"><small>마녀학교 저주골동품부</small><h1>저주<br>매입합니다</h1><p>저주 물건, 정성껏 사들여 정화해 드립니다.</p></div>
      <div class="hero">${sprite('rumi', { shadow: false }, 'hero-rumi', true)}${sprite('cat', {}, 'hero-cat', true)}</div>
      <div class="actions">
        ${sv ? `<button class="btn primary wide" data-act="continue">이어하기 <span class="tiny" style="opacity:.75">· ${sv.day}일째 · Lv${sv.player.lv} · 실적 ${sv.purified}/5</span></button>` : ''}
        <button class="btn ${sv ? '' : 'primary'} wide" data-act="newGame">처음부터 시작</button>
      </div>
      <div class="ver">프로토타입 v0.1 · 기획 검증용 빌드</div>
    </div>`;
  };
  AFTER.title = () => {
    const cv = $('#title-fx');
    const k = dpr();
    cv.width = cv.clientWidth * k; cv.height = cv.clientHeight * k;
    const ctx = cv.getContext('2d');
    const parts = Array.from({ length: 26 }, (_, i) => ({ x: A.hash(i, 1, 7), y: A.hash(i, 2, 7), s: 0.4 + A.hash(i, 3, 7), c: i % 5 === 0 }));
    addAnim('screen', (t) => {
      const w = cv.width, h = cv.height;
      ctx.clearRect(0, 0, w, h);
      const hero = $('.title .hero');
      if (hero) {
        const r0 = cv.getBoundingClientRect(), r1 = hero.getBoundingClientRect();
        const cx = (r1.left - r0.left + r1.width / 2) * k, cy = (r1.top - r0.top + r1.height / 2) * k;
        const rad = Math.min(w * 0.42, r1.height * k * 0.62);
        ctx.save(); ctx.translate(cx, cy);
        ctx.globalAlpha = 0.18; ctx.fillStyle = '#7b5bc4'; ctx.beginPath(); ctx.arc(0, 0, rad, 0, Math.PI * 2); ctx.fill();
        ctx.globalAlpha = 0.45; ctx.strokeStyle = '#c9a0ff'; ctx.lineWidth = 1.5 * k;
        ctx.beginPath(); ctx.arc(0, 0, rad * 0.92, 0, Math.PI * 2); ctx.stroke();
        ctx.beginPath(); ctx.arc(0, 0, rad * 0.78, 0, Math.PI * 2); ctx.stroke();
        ctx.rotate(t * 0.15);
        ctx.beginPath(); for (let i = 0; i <= 5; i++) { const a = -Math.PI / 2 + (i * 4 * Math.PI) / 5; ctx.lineTo(Math.cos(a) * rad * 0.78, Math.sin(a) * rad * 0.78); } ctx.stroke();
        ctx.restore(); ctx.globalAlpha = 1;
      }
      for (const p of parts) {
        const y = ((p.y - t * 0.02 * p.s) % 1 + 1) % 1;
        const x = p.x + Math.sin(t * 0.7 + p.y * 10) * 0.02;
        if (p.c) { A.flame(ctx, x * w, y * h, 0.6 * k * p.s, '#ffb35a', '#fff1b0', t + p.x * 9); }
        else { ctx.globalAlpha = 0.3 + 0.4 * Math.abs(Math.sin(t + p.x * 6)); ctx.fillStyle = '#d9c4ff'; ctx.fillRect(x * w, y * h, 2 * k, 2 * k); ctx.globalAlpha = 1; }
      }
    });
  };

  // 학교(허브)
  SCREENS.hub = () => {
    const s = G.state;
    const cust = R.customers(s).length;
    const readyN = D.QUESTS.filter((q) => R.canPurifyQuest(s, q.id)).length;
    const cursedN = s.antiques.filter((a) => a.state === 'cursed').length;
    const st = R.stats(s);
    const hurt = s.player.hp < st.maxHp * 0.6 || s.player.status.poison;
    return `<div class="scr hub">
      ${statusBar()}
      <div class="hub-head"><h1>마녀학교</h1><span>${s.day}일째 · 정화 실적 <b style="color:var(--gold)">${s.purified}/5</b></span></div>
      <div class="objective">${img('medal', 'ico sm', 40)}<span>${esc(R.objectiveText(s))}</span></div>
      <div class="hub-art"><canvas id="school-cv"></canvas></div>
      <div class="places">
        <button class="place" data-act="go" data-arg="club">${readyN ? '<span class="ping">정화 가능</span>' : cust ? `<span class="ping">손님 ${cust}</span>` : cursedN ? `<span class="ping curse">미정화 ${cursedN}</span>` : ''}${sprite('cat', {}, '', true)}<b>저주골동품부 부실</b><small>매입 · 정화 · 장착</small></button>
        <button class="place" data-act="go" data-arg="shop">${sprite('batgranny', {}, '', true)}<b>박쥐네 매점</b><small>물약 · 도구 · 재료</small></button>
        <button class="place" data-act="go" data-arg="infirmary">${hurt ? '<span class="ping">치료 필요</span>' : ''}${sprite('mummy', {}, '', true)}<b>양호실</b><small>${s.flags.infirmaryFree ? '첫 치료 무료' : `치료비 ${D.TUNING.infirmaryCost}은화`}</small></button>
        <button class="place" data-act="go" data-arg="gate">${sprite('cursed', {}, '', true)}<b>봉인 창고</b><small>B1${s.floorsReached > 1 ? `~B${s.floorsReached}` : ''} 이동 가능</small></button>
      </div>
      ${tabbar()}
    </div>`;
  };
  function tabbar() {
    return `<nav class="tabbar">
      <button data-act="openBag">${img('bag', '', 48)}가방</button>
      <button data-act="openStatus">${img('witch', '', 48)}루미</button>
      <button data-act="openCodex">${img('book', '', 48)}도감</button>
      <button data-act="openBadges">${img('medal', '', 48)}훈장</button>
      <button data-act="openSettings">${img('gear', '', 48)}설정</button>
    </nav>`;
  }
  AFTER.hub = () => {
    const cv = $('#school-cv');
    const k = dpr();
    cv.width = cv.clientWidth * k; cv.height = cv.clientHeight * k;
    const ctx = cv.getContext('2d');
    addAnim('screen', (t) => A.drawSchool(ctx, cv.width, cv.height, t));
  };

  // 부실
  SCREENS.club = () => {
    const s = G.state;
    const cust = R.customers(s);
    const act = R.activeQuests(s);
    const cursed = s.antiques.filter((a) => a.state === 'cursed');
    const shelf = s.antiques.filter((a) => a.state === 'purified');
    const tip = D.LINES.mukmulTips[G.ui.tip % D.LINES.mukmulTips.length];
    return `<div class="scr club">
      ${statusBar()}
      <div class="bar-head"><button class="icon-btn" data-act="go" data-arg="hub" aria-label="학교로">←</button><h2>저주골동품부 부실</h2></div>
      <div class="content">
        <div class="cat-corner" data-act="catTip">${sprite('cat', {}, '', true)}<div class="bubble">${esc(tip)}</div></div>
        <section><h3 class="sec">찾아온 손님 <small>매입하면 의뢰가 시작돼요</small></h3>
          ${cust.length ? cust.map((q) => `<button class="card customer" data-act="customer" data-arg="${q.id}">${portrait(q.customer, '', false, 'worried')}<div class="grow"><b>${esc(D.NPCS[q.customer].name)} <span class="dim small">${esc(D.NPCS[q.customer].role)}</span></b><div class="small">「${esc(q.cursedName)}」</div><div class="tiny muted">${esc(q.symptom)}</div></div><div class="tiny" style="text-align:right;white-space:nowrap">매입가<br><b style="color:var(--gold)">${q.buy}</b> 은화</div></button>`).join('') : `<div class="empty">오늘은 손님이 없어요. 봉인 창고를 탐험하고 오면 새 손님이 찾아와요.</div>`}
        </section>
        <section><h3 class="sec">진행 중인 의뢰 <small>${act.length}/3</small></h3>
          ${act.length ? act.map(questCard).join('') : `<div class="empty">진행 중인 의뢰가 없어요.</div>`}
        </section>
        ${cursed.length ? `<section><h3 class="sec">미정화 골동품 <small>정화 소금 보유 ${R.count(s, 'salt')}</small></h3>
          ${cursed.map((a) => `<div class="card row">${img('cursed', 'ico', 64)}<div class="grow"><b>저주받은 골동품</b><div class="tiny muted">B${a.floor}에서 발견 · 정화하면 정체가 드러나요</div></div><div style="display:grid;gap:6px"><button class="btn small curse" data-act="purifyFound" data-arg="${a.uid}" ${R.count(s, 'salt') ? '' : 'disabled'}>정화</button><button class="btn small ghost" data-act="sellCursed" data-arg="${a.uid}">헐값 10</button></div></div>`).join('')}
          ${R.count(s, 'salt') ? '' : '<div class="tiny dim">정화 소금은 매점에서 40은화에 팔아요.</div>'}</section>` : ''}
        <section><h3 class="sec">진열장 <small>정화한 골동품 ${shelf.length}개</small></h3>
          ${shelf.length ? shelf.map((a) => antiqueRow(a)).join('') : `<div class="empty">정화한 골동품이 여기에 놓여요.</div>`}
        </section>
      </div>
    </div>`;
  };
  function questCard(q) {
    const s = G.state;
    const rec = s.quests[q.id];
    const ready = R.canPurifyQuest(s, q.id);
    let prog = '';
    if (q.objective.type === 'items') {
      prog = Object.keys(q.objective.items).map((id) => `${D.ITEMS[id].name} <b>${Math.min(R.count(s, id), q.objective.items[id])}/${q.objective.items[id]}</b>`).join(' · ');
    } else prog = rec.status === 'ready' ? '<b style="color:var(--gold)">목표 달성! 정화할 수 있어요.</b>' : esc(q.hint);
    return `<div class="card quest ${ready ? 'ready' : ''}">
      <div class="row">${img('cursed', 'ico', 64)}<div class="grow"><b>「${esc(q.cursedName)}」</b><div class="tiny muted">의뢰인 ${esc(D.NPCS[q.customer].name)} · ${esc(q.symptom)}</div></div></div>
      <div class="progress-line">${prog}</div>
      ${ready ? `<div class="actions"><button class="btn primary wide" data-act="purifyQuest" data-arg="${q.id}">정화하기</button></div>` : ''}
    </div>`;
  }
  function antiqueRow(a) {
    const s = G.state;
    const def = D.ANTIQUES[a.def];
    const eq = s.equip.indexOf(a.uid);
    return `<button class="card row" data-act="antique" data-arg="${a.uid}" style="text-align:left;width:100%">${img(def.icon, 'ico', 64)}<div class="grow"><b>${esc(def.name)} ${gradeTag(def.grade)}${eq >= 0 ? ' <span class="chip good">장착 중</span>' : ''}</b><div class="tiny muted">${esc(R.describeEffect(def.effect))}</div></div><div class="tiny" style="white-space:nowrap">${coin().replace('<img', '<img style="width:14px;height:14px;vertical-align:-2px"')} ${def.value}</div></button>`;
  }

  // 매점
  SCREENS.shop = () => {
    const s = G.state;
    const tab = G.ui.shopTab;
    const line = G.ui.kikiLine || D.LINES.kiki[0];
    let grid;
    if (tab === 'sell') {
      const ids = Object.keys(s.inv).filter((id) => D.ITEMS[id] && D.ITEMS[id].cat !== 'quest' && s.inv[id] > 0);
      grid = ids.length ? ids.map((id) => `<button class="tile" data-act="sellSheet" data-arg="${id}">${img(D.ITEMS[id].icon, '', 64)}<b>${esc(D.ITEMS[id].name)}</b><span class="price">${coin()}${R.sellPrice(id)}</span><span class="own">보유 ${s.inv[id]}</span></button>`).join('') : `<div class="empty" style="grid-column:1/-1">팔 물건이 없어요.</div>`;
    } else {
      const all = Object.keys(D.ITEMS).filter((id) => D.ITEMS[id].cat === tab);
      grid = all.map((id) => {
        const it = D.ITEMS[id];
        const locked = it.unlockFloor && s.floorsReached < it.unlockFloor;
        return `<button class="tile ${locked ? 'locked' : ''}" data-act="${locked ? 'lockedItem' : 'buySheet'}" data-arg="${id}">${img(it.icon, '', 64)}<b>${esc(it.name)}</b>${locked ? `<span class="tiny dim">B${it.unlockFloor} 도달 후</span>` : `<span class="price">${coin()}${it.price}</span>`}<span class="own">${R.count(s, id) ? '보유 ' + R.count(s, id) : ''}</span></button>`;
      }).join('');
    }
    return `<div class="scr shop">
      ${statusBar()}
      <div class="bar-head"><button class="icon-btn" data-act="go" data-arg="hub" aria-label="학교로">←</button><h2>박쥐네 매점</h2></div>
      <div class="shopkeeper">${sprite('batgranny', {}, '', true)}<div class="bubble">${esc(line)}</div></div>
      <div class="tabs">${D.SHOP_TABS.map((t) => `<button class="${t.id === tab ? 'on' : ''}" data-act="shopTab" data-arg="${t.id}">${t.name}</button>`).join('')}</div>
      <div class="content"><div class="shelf">${grid}</div></div>
    </div>`;
  };

  // 양호실
  SCREENS.infirmary = () => {
    const s = G.state;
    const st = R.stats(s);
    const full = s.player.hp >= st.maxHp && s.player.mp >= st.maxMp && !s.player.status.poison && !s.player.status.curseNext;
    const cost = s.flags.infirmaryFree ? 0 : D.TUNING.infirmaryCost;
    const line = G.ui.momoLine || D.LINES.momo[0];
    return `<div class="scr infirmary">
      ${statusBar()}
      <div class="bar-head"><button class="icon-btn" data-act="go" data-arg="hub" aria-label="학교로">←</button><h2>양호실</h2></div>
      <div class="content">
        <div class="cat-corner">${sprite('mummy', {}, '', true).replace('<canvas', '<canvas style="width:96px;height:96px"')}<div class="bubble">${esc(line)}</div></div>
        <div class="card"><div class="stats-grid">
          <div><span>체력</span><b>${s.player.hp}/${st.maxHp}</b></div><div><span>마력</span><b>${s.player.mp}/${st.maxMp}</b></div>
          <div><span>독</span><b>${s.player.status.poison ? '걸림' : '없음'}</b></div><div><span>치료비</span><b>${cost ? cost + '은화' : '무료'}</b></div>
        </div></div>
        <button class="btn primary wide" data-act="heal" ${full ? 'disabled' : ''}>${full ? '아픈 곳이 없어요' : `치료받기 · ${cost ? cost + '은화' : '무료'}`}</button>
        <p class="tiny dim">체력·마력이 모두 차고, 독과 저주 연기도 사라져요. 동물농장 병원처럼 진료비는 20(은화)!</p>
      </div>
    </div>`;
  };

  // 봉인 창고 입구
  SCREENS.gate = () => {
    const s = G.state;
    const rows = [];
    for (let f = 1; f <= 5; f++) {
      const F = D.FLOORS[f];
      const open = f <= s.floorsReached;
      const qs = R.activeQuests(s).filter((q) => q.objective.floor === f && s.quests[q.id].status === 'active');
      rows.push(`<button class="card row" data-act="${open ? 'enter' : 'lockedFloor'}" data-arg="${f}" style="text-align:left;width:100%;${open ? '' : 'opacity:.5'}">
        <div style="font-family:var(--font-display);font-size:26px;color:${open ? 'var(--gold)' : 'var(--dim)'};min-width:44px">B${f}</div>
        <div class="grow"><b>${open ? esc(F.name) : '봉인되어 있다'}</b><div class="tiny muted">${open ? `권장 Lv${F.recLv}${f === 5 ? ' · 보스' : ''}` : `B${f - 1} 계단으로 내려가면 열려요`}</div>${qs.map((q) => `<div class="tiny" style="color:var(--gold)">의뢰: ${esc(q.objective.place)}</div>`).join('')}</div>
        ${open ? '<span class="chip">이동 ▸</span>' : ''}</button>`);
    }
    return `<div class="scr gate">
      ${statusBar()}
      <div class="bar-head"><button class="icon-btn" data-act="go" data-arg="hub" aria-label="학교로">←</button><h2>봉인 창고 입구</h2></div>
      <div class="content">
        <div class="hub-art" style="margin:0;height:120px"><canvas id="gate-cv"></canvas></div>
        <p class="small muted" style="margin:0">공간이동 항아리가 한 번이라도 가본 층으로 보내준다. 들어가면 하루가 흐르고, 학교로 돌아오면 상자와 몬스터가 다시 채워진다.</p>
        ${rows.join('')}
      </div>
    </div>`;
  };
  AFTER.gate = () => {
    const cv = $('#gate-cv');
    const k = dpr();
    cv.width = cv.clientWidth * k; cv.height = cv.clientHeight * k;
    const ctx = cv.getContext('2d');
    addAnim('screen', (t) => A.drawGate(ctx, cv.width, cv.height, t));
  };

  // ───────── 던전 ─────────
  SCREENS.dungeon = () => {
    const s = G.state;
    const F = D.FLOORS[s.exp.floor];
    const run = s.exp.runs[s.exp.floor];
    return `<div class="scr dungeon">
      ${statusBar()}
      <div class="d-head"><b>B${F.id}</b><span>${esc(F.name)}</span><span class="d-obj">${esc(shortObjective())}</span></div>
      <div class="d-map"><canvas id="map-cv" aria-label="봉인 창고 지도"></canvas></div>
      <div class="d-log">${G.ui.log.slice(-2).map((l) => `<p>${esc(l)}</p>`).join('')}</div>
      <div class="d-ctrl">
        <div class="d-btns">
          <button class="btn" data-act="openBag">${img('bag', '', 48)}가방</button>
          <button class="btn" data-act="petHint">${img('cat', '', 48)}먹물<em>냄새 ${run.hints}</em></button>
          <button class="btn" data-act="goHomeAsk">${img('feather', '', 48)}귀환<em>깃털 ${R.count(s, 'feather')}</em></button>
        </div>
        <div class="dpad">
          <button class="up" data-act="move" data-arg="0,-1" aria-label="위">▲</button>
          <button class="left" data-act="move" data-arg="-1,0" aria-label="왼쪽">◀</button>
          <button class="here" data-act="here" aria-label="이 칸 살펴보기">●</button>
          <button class="right" data-act="move" data-arg="1,0" aria-label="오른쪽">▶</button>
          <button class="down" data-act="move" data-arg="0,1" aria-label="아래">▼</button>
        </div>
      </div>
    </div>`;
  };
  function shortObjective() {
    const s = G.state;
    const q = R.activeQuests(s).find((x) => x.objective.floor === s.exp.floor && s.quests[x.id].status === 'active');
    if (q) return '의뢰: ' + q.objective.place;
    if (D.FLOORS[s.exp.floor].down) return '아래층 계단 찾기';
    return s.flags.bossDefeated ? '자유 탐험' : '가장 깊은 곳으로';
  }
  function refreshDungeonHUD() {
    if (G.ui.screen !== 'dungeon' || !$('.dungeon')) return;
    const s = G.state;
    const run = s.exp && s.exp.runs[s.exp.floor];
    const st = $('.dungeon .status');
    if (st) st.outerHTML = statusBar();
    const lg = $('.d-log');
    if (lg) lg.innerHTML = G.ui.log.slice(-2).map((l) => `<p>${esc(l)}</p>`).join('');
    const pet = $('[data-act="petHint"] em'); if (pet && run) pet.textContent = '냄새 ' + run.hints;
    const fe = $('[data-act="goHomeAsk"] em'); if (fe) fe.textContent = '깃털 ' + R.count(s, 'feather');
    const ob = $('.d-obj'); if (ob) ob.textContent = shortObjective();
  }
  function refreshStatus() { const st = $('#screen .status'); if (st) st.outerHTML = statusBar(); }

  AFTER.dungeon = () => {
    const cv = $('#map-cv');
    const box = $('.d-map');
    const tile = Math.max(14, Math.floor(Math.min((box.clientWidth - 16) / R.MAP_W, (box.clientHeight - 6) / R.MAP_H)));
    G.ui.tile = tile;
    const k = dpr();
    cv.width = tile * R.MAP_W * k; cv.height = tile * R.MAP_H * k;
    cv.style.width = tile * R.MAP_W + 'px'; cv.style.height = tile * R.MAP_H + 'px';
    const ctx = cv.getContext('2d');
    if (!G.ui.pos) G.ui.pos = { x: G.state.exp.x, y: G.state.exp.y };
    addAnim('screen', (t) => drawMap(ctx, k, tile, t));
    cv.addEventListener('pointerup', onMapTap);
  };
  function snapPos() { const s = G.state; G.ui.pos = { x: s.exp.x, y: s.exp.y }; G.ui.tween = null; G.ui.cat = { x: s.exp.x, y: s.exp.y }; }
  function playerVisual(now) {
    const tw = G.ui.tween;
    if (!tw) return G.ui.pos;
    const p = Math.min(1, (now - tw.start) / tw.dur);
    const e = p < 0.5 ? 2 * p * p : 1 - Math.pow(-2 * p + 2, 2) / 2;
    if (p >= 1) { G.ui.tween = null; G.ui.pos = { x: tw.tx, y: tw.ty }; return G.ui.pos; }
    return { x: tw.fx + (tw.tx - tw.fx) * e, y: tw.fy + (tw.ty - tw.fy) * e };
  }
  function drawMap(ctx, k, s, t) {
    const st = G.state;
    if (!st || !st.exp) return;
    const f = st.exp.floor;
    const map = R.genFloor(f);
    const pal = D.FLOORS[f].palette;
    const now = performance.now();
    ctx.setTransform(k, 0, 0, k, 0, 0);
    ctx.lineJoin = 'round'; ctx.lineCap = 'round';
    ctx.fillStyle = '#07050b';
    ctx.fillRect(0, 0, s * map.w, s * map.h);
    const pv = playerVisual(now);
    for (let y = 0; y < map.h; y++) for (let x = 0; x < map.w; x++) {
      if (!R.isRevealed(st, x, y)) {
        const hh = A.hash(x, y, 31);
        ctx.fillStyle = hh < 0.5 ? '#0d0a13' : '#100c17';
        ctx.fillRect(x * s, y * s, s + 0.5, s + 0.5);
        ctx.fillStyle = 'rgba(190,160,255,0.05)';
        ctx.fillRect(x * s + s * (0.2 + hh * 0.4), y * s + s * (0.3 + A.hash(y, x, 9) * 0.4), s * 0.12, s * 0.12);
        continue;
      }
      const ts = R.tileState(st, x, y);
      if (ts.kind === 'wall') { A.drawWall(ctx, x, y, s, pal, y + 1 < map.h && R.tileCh(map, x, y + 1) !== '#'); continue; }
      A.drawFloor(ctx, x, y, s, pal, f);
      drawTileThing(ctx, ts, x * s, y * s, s, t, pal, x, y);
    }
    // 경로 미리보기
    if (G.ui.path && G.ui.path.length) {
      ctx.fillStyle = 'rgba(255,207,90,0.55)';
      for (const [px, py] of G.ui.path) { ctx.beginPath(); ctx.arc((px + 0.5) * s, (py + 0.5) * s, s * 0.08, 0, Math.PI * 2); ctx.fill(); }
      const [tx, ty] = G.ui.path[G.ui.path.length - 1];
      ctx.strokeStyle = 'rgba(255,207,90,0.8)'; ctx.lineWidth = 2;
      ctx.beginPath(); ctx.arc((tx + 0.5) * s, (ty + 0.5) * s, s * 0.32 + Math.sin(t * 6) * 1.5, 0, Math.PI * 2); ctx.stroke();
    }
    // 고양이(한 칸 뒤)
    const cat = G.ui.cat || pv;
    A.draw(ctx, 'cat', (cat.x + 0.18) * s, (cat.y + 0.3) * s, s * 0.66, { t: t + 0.4 });
    // 루미
    A.draw(ctx, 'rumi', (pv.x - 0.12) * s, (pv.y - 0.4) * s, s * 1.24, { t, shadow: st.flags.bossDefeated });
    // 조명
    const cx = (pv.x + 0.5) * s, cy = (pv.y + 0.5) * s;
    const r = (R.sightRange(st) + 1.6) * s * (1 + Math.sin(t * 7) * 0.012);
    const g = ctx.createRadialGradient(cx, cy, s * 0.8, cx, cy, r);
    g.addColorStop(0, 'rgba(255,190,110,0.10)');
    g.addColorStop(0.55, 'rgba(12,8,20,0.10)');
    g.addColorStop(1, 'rgba(6,4,10,0.45)');
    ctx.fillStyle = g;
    ctx.fillRect(0, 0, s * map.w, s * map.h);
    // 먹물 힌트 화살표
    const h = G.ui.hint;
    if (h && now < h.until) {
      const a = h.angle;
      const len = s * 1.6;
      ctx.save(); ctx.translate(cx, cy); ctx.rotate(a);
      ctx.globalAlpha = 0.6 + Math.sin(t * 8) * 0.3;
      ctx.fillStyle = '#ffcf5a'; ctx.strokeStyle = '#2a1508'; ctx.lineWidth = 2;
      ctx.beginPath(); ctx.moveTo(len, 0); ctx.lineTo(len - s * 0.5, -s * 0.32); ctx.lineTo(len - s * 0.5, s * 0.32); ctx.closePath(); ctx.fill(); ctx.stroke();
      ctx.fillRect(s * 0.6, -s * 0.09, len - s * 1.1, s * 0.18);
      ctx.restore(); ctx.globalAlpha = 1;
    }
    // 떠오르는 글자
    G.ui.mapFloats = (G.ui.mapFloats || []).filter((m) => now - m.start < 900);
    for (const m of G.ui.mapFloats) {
      const p = (now - m.start) / 900;
      ctx.globalAlpha = 1 - p;
      ctx.font = `bold ${Math.round(s * 0.42)}px sans-serif`;
      ctx.textAlign = 'center';
      ctx.fillStyle = m.color; ctx.strokeStyle = '#000'; ctx.lineWidth = 3;
      ctx.strokeText(m.text, cx, cy - s * 0.6 - p * s); ctx.fillText(m.text, cx, cy - s * 0.6 - p * s);
      ctx.globalAlpha = 1;
    }
  }
  function mapFloat(text, color) { (G.ui.mapFloats = G.ui.mapFloats || []).push({ text, color: color || '#fff', start: performance.now() }); }
  function drawTileThing(ctx, ts, px, py, s, t, pal, x, y) {
    const bob = Math.sin(t * 3 + x + y) * s * 0.04;
    switch (ts.kind) {
      case 'up': A.drawStairsUp(ctx, px, py, s); break;
      case 'down': A.drawStairsDown(ctx, px, py, s, pal.glow); break;
      case 'door': A.drawDoor(ctx, px, py, s, false); break;
      case 'doorOpen': A.drawDoor(ctx, px, py, s, true); break;
      case 'monster': A.drawSpriteTile(ctx, (c, tt) => A.MON[ts.enemy](c, tt), px, py + bob, s, t + x * 0.7, 0.95); break;
      case 'boss': {
        ctx.globalAlpha = 0.4 + Math.sin(t * 3) * 0.2; ctx.fillStyle = '#7b5bc4'; ctx.beginPath(); ctx.arc(px + s / 2, py + s / 2, s * 0.6, 0, Math.PI * 2); ctx.fill(); ctx.globalAlpha = 1;
        A.drawSpriteTile(ctx, (c, tt) => A.MON[ts.enemy](c, tt), px, py - s * 0.15, s, t, 1.25); break;
      }
      case 'chest': A.drawChestTile(ctx, px, py + bob * 0.3, s, 'closed'); break;
      case 'lockedChest': A.drawChestTile(ctx, px, py, s, 'locked'); break;
      case 'chestOpen': A.drawChestTile(ctx, px, py, s, 'open'); break;
      case 'key': A.draw(ctx, 'key', px + s * 0.18, py + s * 0.18 + bob, s * 0.64, { t }); break;
      case 'fountain': case 'fountainDry': {
        ctx.fillStyle = '#6f6784'; ctx.beginPath(); ctx.ellipse(px + s / 2, py + s * 0.6, s * 0.38, s * 0.24, 0, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = ts.kind === 'fountain' ? '#8fd3ff' : '#2a2438'; ctx.beginPath(); ctx.ellipse(px + s / 2, py + s * 0.57, s * 0.28, s * 0.15, 0, 0, Math.PI * 2); ctx.fill();
        if (ts.kind === 'fountain') { ctx.globalAlpha = 0.5 + Math.sin(t * 4) * 0.3; ctx.fillStyle = '#e8f6ff'; ctx.beginPath(); ctx.arc(px + s * 0.5, py + s * (0.36 + Math.sin(t * 5) * 0.04), s * 0.06, 0, Math.PI * 2); ctx.fill(); ctx.globalAlpha = 1; }
        break;
      }
      case 'event': {
        const yy = py + s * 0.5 + bob * 1.5;
        ctx.globalAlpha = 0.5; ctx.fillStyle = '#b996ff'; ctx.beginPath(); ctx.arc(px + s / 2, yy, s * 0.36, 0, Math.PI * 2); ctx.fill(); ctx.globalAlpha = 1;
        ctx.fillStyle = '#efe3ff'; ctx.beginPath(); ctx.arc(px + s / 2, yy, s * 0.24, 0, Math.PI * 2); ctx.fill();
        ctx.fillStyle = '#3b2366'; ctx.font = `bold ${Math.round(s * 0.36)}px sans-serif`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillText('?', px + s / 2, yy + 1);
        ctx.textBaseline = 'alphabetic';
        break;
      }
      case 'trapSeen': ctx.fillStyle = '#c9c3d6'; for (let i = 0; i < 3; i++) { ctx.beginPath(); ctx.moveTo(px + s * (0.2 + i * 0.22), py + s * 0.72); ctx.lineTo(px + s * (0.31 + i * 0.22), py + s * 0.42); ctx.lineTo(px + s * (0.42 + i * 0.22), py + s * 0.72); ctx.fill(); } break;
      case 'trapSprung': ctx.fillStyle = '#0a070f'; ctx.beginPath(); ctx.ellipse(px + s / 2, py + s / 2, s * 0.3, s * 0.2, 0, 0, Math.PI * 2); ctx.fill(); break;
      case 'puzzle': case 'puzzleDone': {
        ctx.fillStyle = ts.kind === 'puzzle' ? '#5b3a8c' : '#2a1f3a';
        ctx.beginPath(); ctx.moveTo(px + s * 0.22, py + s * 0.95); ctx.lineTo(px + s * 0.22, py + s * 0.4); ctx.arc(px + s / 2, py + s * 0.4, s * 0.28, Math.PI, 0); ctx.lineTo(px + s * 0.78, py + s * 0.95); ctx.closePath(); ctx.fill();
        if (ts.kind === 'puzzle') { ctx.fillStyle = '#fff'; ctx.beginPath(); ctx.ellipse(px + s / 2, py + s * 0.5, s * 0.14, s * 0.09, 0, 0, Math.PI * 2); ctx.fill(); ctx.fillStyle = '#e5566e'; ctx.beginPath(); ctx.arc(px + s / 2 + Math.sin(t * 2) * s * 0.04, py + s * 0.5, s * 0.05, 0, Math.PI * 2); ctx.fill(); }
        break;
      }
      case 'merchant': A.draw(ctx, 'cat2', px + s * 0.05, py + s * 0.02 + bob, s * 0.9, { t }); break;
      case 'quest': {
        const pulse = 1 + Math.sin(t * 5) * 0.12;
        ctx.globalAlpha = 0.35; ctx.fillStyle = '#ffcf5a'; ctx.beginPath(); ctx.arc(px + s / 2, py + s / 2, s * 0.46 * pulse, 0, Math.PI * 2); ctx.fill(); ctx.globalAlpha = 1;
        ctx.save(); ctx.translate(px + s / 2, py + s / 2); ctx.scale(s / 100, s / 100); A.star(ctx, 0, 0, 30 * pulse, '#ffcf5a'); ctx.restore();
        break;
      }
      case 'altar': ctx.fillStyle = '#ffe680'; ctx.globalAlpha = 0.6; ctx.beginPath(); ctx.arc(px + s / 2, py + s / 2, s * 0.3, 0, Math.PI * 2); ctx.fill(); ctx.globalAlpha = 1; break;
      default: break;
    }
  }

  // 지도 탭 → 길 찾아 걷기
  function onMapTap(e) {
    if (G.ui.dialog || $('#sheet').innerHTML || G.ui.battle) return;
    const cv = e.currentTarget;
    const rect = cv.getBoundingClientRect();
    const x = Math.floor((e.clientX - rect.left) / G.ui.tile);
    const y = Math.floor((e.clientY - rect.top) / G.ui.tile);
    if (G.ui.busy) { G.ui.redirect = { x, y }; G.ui.cancelWalk = true; return; }
    tapTile(x, y);
  }
  async function tapTile(x, y) {
    const s = G.state;
    if (!s.exp || x < 0 || y < 0 || x >= R.MAP_W || y >= R.MAP_H) return;
    if (x === s.exp.x && y === s.exp.y) return interactHere();
    if (!R.isRevealed(s, x, y)) { toast('아직 어둠에 가려진 곳이다.'); S.play('error'); return; }
    const ts = R.tileState(s, x, y);
    if (ts.kind === 'wall') { S.play('error'); return; }
    const path = R.findPath(s, x, y, false);
    if (!path || !path.length) { toast('그곳까지 가는 길을 아직 모른다.'); S.play('error'); return; }
    await walk(path);
  }
  async function walk(path) {
    G.ui.busy = true; G.ui.cancelWalk = false; G.ui.redirect = null;
    G.ui.path = path.slice();
    for (const [nx, ny] of path) {
      if (G.ui.cancelWalk) break;
      const cont = await stepTo(nx, ny);
      G.ui.path && G.ui.path.shift();
      if (!cont) break;
    }
    G.ui.path = null;
    G.ui.busy = false;
    save();
    refreshDungeonHUD();
    const rd = G.ui.redirect; G.ui.redirect = null;
    if (rd && G.ui.screen === 'dungeon') tapTile(rd.x, rd.y);
  }
  async function stepTo(nx, ny) {
    const s = G.state;
    const fx = s.exp.x, fy = s.exp.y;
    const ev = R.stepInto(s, nx, ny);
    if (s.exp && s.exp.x === nx && s.exp.y === ny) {
      G.ui.cat = { x: fx, y: fy };
      G.ui.tween = { fx: G.ui.pos.x, fy: G.ui.pos.y, tx: nx, ty: ny, start: performance.now(), dur: STEP_MS * (G.ui.speed || 1) };
      G.ui.pos = { x: nx, y: ny };
      S.play('step');
      await sleep(STEP_MS);
      refreshStatus();
    }
    if (!ev) return true;
    return handleEvent(ev, nx, ny);
  }
  async function interactHere() {
    const s = G.state;
    const ts = R.tileState(s, s.exp.x, s.exp.y);
    const x = s.exp.x, y = s.exp.y;
    const map = { up: { type: 'up' }, down: { type: 'down' }, merchant: { type: 'merchant' }, fountain: { type: 'fountain', x, y }, puzzle: { type: 'puzzle', x, y }, quest: { type: 'quest', qid: ts.quest, x, y } };
    if (ts.kind === 'event') return handleEvent({ type: 'event', ev: s.exp.runs[s.exp.floor].etype[R.key(x, y)], x, y }, x, y);
    if (map[ts.kind]) { G.ui.busy = true; await handleEvent(map[ts.kind], x, y); G.ui.busy = false; save(); refreshDungeonHUD(); return; }
    toast('여기엔 별다른 것이 없다.');
  }

  // 사건 처리. true = 계속 걸어도 됨
  async function handleEvent(ev, x, y) {
    const s = G.state;
    if (ev.type === 'multi') { for (const e of ev.list) { const c = await handleEvent(e, x, y); if (!c) return false; } return true; }
    switch (ev.type) {
      case 'blocked': S.play('error'); return false;
      case 'poisonTick': mapFloat(`-${ev.dmg}`, '#b6f07a'); log(`독이 퍼진다. 체력 -${ev.dmg}`); if (ev.cured) toast('독이 다 빠졌다.', 'good'); return true;
      case 'key': S.play('coin'); toast('녹슨 열쇠를 주웠다!', 'gold'); log('녹슨 열쇠를 주웠다.'); return true;
      case 'trapAvoided': toast('할머니 돋보기로 함정을 알아채고 피했다.', 'good'); return true;
      case 'trap':
        S.play('hurt');
        if (ev.kind === 'pit') { mapFloat(`-${ev.dmg}`, '#ff8a9a'); toast(`바닥이 꺼졌다! 체력 -${ev.dmg}`, 'bad'); log(`함정! 체력 -${ev.dmg}`); }
        else { toast('독가시 함정! 독에 걸렸다.', 'bad'); log('독가시 함정에 찔렸다.'); }
        refreshStatus();
        return false;
      case 'door': return doorEvent(x, y);
      case 'battle': return battleEvent(ev, x, y);
      case 'boss': return bossEvent(ev, x, y);
      case 'up': return upEvent();
      case 'down': return downEvent();
      case 'chest': { const loot = R.openChest(s, ev.x, ev.y, ev.treasure); S.play('chest'); await lootSheet(ev.treasure ? '보물 상자를 열었다!' : '상자를 열었다!', loot); return false; }
      case 'lockedChest': return lockedChestEvent(ev);
      case 'mimic': {
        await say([{ who: null, text: '상자를 열려는 순간— 상자가 혀를 날름 내밀었다!' }]);
        R.markOpened(s, ev.x, ev.y);
        const r = await runBattle('lockmimic', {});
        if (r === 'lose') { await defeat(); }
        return false;
      }
      case 'fountain': {
        const st = R.stats(s);
        const c = await ask({ title: '달빛 샘물', art: '', body: `<p>달빛을 머금은 샘물이 조용히 빛난다. 마시면 체력과 마력이 40%씩 회복된다. (이번 탐험에서 한 번)</p><p class="tiny dim">지금 체력 ${s.player.hp}/${st.maxHp} · 마력 ${s.player.mp}/${st.maxMp}</p>`, choices: [{ label: '마신다', value: 'drink', cls: 'primary' }, { label: '나중에', value: null }] });
        if (c === 'drink') { const r = R.useFountain(s, ev.x, ev.y); S.play('heal'); toast(`체력 +${r.hp} · 마력 +${r.mp}`, 'good'); refreshStatus(); }
        return false;
      }
      case 'event': return randomEvent(ev);
      case 'puzzle': {
        const c = await ask({ title: '기묘한 방', body: '<p>문틈으로 꺼진 촛불들이 보인다. 벽에 글씨가 있다. 「모두 밝히면 문이 열린다.」</p>', choices: [{ label: '들어간다', value: 'go', cls: 'curse' }, { label: '나중에', value: null }] });
        if (c !== 'go') return false;
        const ok = await runPuzzle(D.FLOORS[s.exp.floor].id >= 4 ? 5 : 4);
        if (ok) { const loot = R.puzzleReward(s, ev.x, ev.y); S.play('chest'); await lootSheet('촛불이 모두 켜지자 숨은 상자가 나타났다!', loot); R.checkBadges(s).forEach(badgeToast); }
        return false;
      }
      case 'merchant': await merchantSheet(); return false;
      case 'quest': return questEvent(ev);
      case 'up': return upEvent();
      default: return false;
    }
  }
  async function doorEvent(x, y) {
    const s = G.state;
    const keys = R.count(s, 'key');
    const c = await ask({ title: '잠긴 문', body: `<p>녹슨 자물쇠가 걸린 문이다. 문 너머에서 은은한 빛이 새어 나온다.</p><p class="tiny dim">녹슨 열쇠 ${keys}개 보유 · 매점에서 50은화</p>`, choices: [{ label: '열쇠를 쓴다', value: 'open', cls: 'primary', disabled: !keys }, { label: '돌아선다', value: null }] });
    if (c === 'open') { R.openDoor(s, x, y); S.play('door'); toast('철컥! 문이 열렸다.', 'gold'); log('잠긴 문을 열었다.'); }
    return false;
  }
  async function lockedChestEvent(ev) {
    const s = G.state;
    const keys = R.count(s, 'key');
    const c = await ask({ title: '잠긴 상자', body: `<p>단단히 잠긴 상자다. 안에서 무언가 달그락거린다.</p><p class="tiny dim">녹슨 열쇠 ${keys}개 보유</p>`, choices: [{ label: '열쇠를 쓴다', value: 'open', cls: 'primary', disabled: !keys }, { label: '그냥 둔다', value: null }] });
    if (c !== 'open') return false;
    const r = R.openLockedChest(s, ev.x, ev.y);
    if (r.ok) { S.play('chest'); await lootSheet('잠긴 상자를 열었다!', r.loot); }
    return false;
  }
  async function battleEvent(ev, x, y) {
    const s = G.state;
    const res = await runBattle(ev.enemy, ev.fixed ? { fixedKey: R.key(x, y) } : {});
    if (res === 'win' && ev.fixed) { s.exp.x = x; s.exp.y = y; R.reveal(s); G.ui.cat = { x: G.ui.pos.x, y: G.ui.pos.y }; G.ui.pos = { x, y }; G.ui.tween = null; }
    if (res === 'lose') await defeat();
    return false;
  }
  async function bossEvent(ev, x, y) {
    const s = G.state;
    const st = R.stats(s);
    const c = await ask({ title: '짙은 그림자', body: `<p>그림자가 뭉쳐 사람의 형상을 이룬다. 이 너머가 봉인 창고의 가장 깊은 곳이다.</p><p class="tiny dim">보스와의 전투는 도망칠 수 없다. 지금 체력 ${s.player.hp}/${st.maxHp} · 마력 ${s.player.mp}/${st.maxMp}</p>`, choices: [{ label: '맞선다', value: 'go', cls: 'curse' }, { label: '준비하고 온다', value: null }] });
    if (c !== 'go') return false;
    await say(D.LINES.bossIntro);
    const r = await runBattle(ev.enemy, {});
    if (r === 'win') {
      await say(D.LINES.bossWin);
      s.exp.x = x; s.exp.y = y; R.reveal(s); snapPos();
      R.checkBadges(s).forEach(badgeToast);
      save();
      if (s.purified < 5) toast(`정화 실적 ${s.purified}/5 — 손님 의뢰를 더 해결하면 엔딩!`, 'gold');
      else toast('학교로 돌아가 학생회에 보고하자!', 'gold');
    } else if (r === 'lose') await defeat();
    return false;
  }
  async function upEvent() {
    const s = G.state;
    const f = s.exp.floor;
    if (f === 1) {
      const c = await ask({ title: '학교로 돌아갈까?', body: '<p>계단을 오르면 오늘 탐험이 끝나고 하루가 지난다. 상자와 몬스터는 다시 채워지고, 부실에 새 손님이 올 수 있다.</p>', choices: [{ label: '학교로 돌아간다', value: 'home', cls: 'primary' }, { label: '더 탐험한다', value: null }] });
      if (c === 'home') await goHome('계단을 올라 학교로 돌아왔다.');
      return false;
    }
    const c = await ask({ title: '올라가는 계단', body: `<p>B${f - 1} ${esc(D.FLOORS[f - 1].name)}(으)로 올라갈 수 있다.</p>`, choices: [{ label: `B${f - 1}로 올라간다`, value: 'up', cls: 'primary' }, { label: '그만둔다', value: null }] });
    if (c === 'up') { R.enterFloor(s, f - 1, 'goal'); snapPos(); G.ui.log = []; render(); floorBanner(); }
    return false;
  }
  async function downEvent() {
    const s = G.state;
    const f = s.exp.floor;
    const nf = D.FLOORS[f + 1];
    const warn = s.player.lv < nf.recLv ? `<p class="small" style="color:var(--warn)">권장 Lv${nf.recLv} — 지금 Lv${s.player.lv}. 조심해요!</p>` : `<p class="small muted">권장 Lv${nf.recLv}</p>`;
    const c = await ask({ title: `B${f + 1} ${nf.name}`, body: `<p>더 짙은 저주의 냄새가 올라온다.</p>${warn}`, choices: [{ label: '내려간다', value: 'down', cls: 'primary' }, { label: '그만둔다', value: null }] });
    if (c === 'down') {
      const first = s.floorsReached < f + 1;
      R.enterFloor(s, f + 1, 'start'); snapPos(); G.ui.log = []; render(); floorBanner();
      if (first) { R.checkBadges(s).forEach(badgeToast); toast('공간이동 항아리에 새 층이 등록됐다.', 'gold'); }
      save();
    }
    return false;
  }
  function floorBanner() {
    const s = G.state; const F = D.FLOORS[s.exp.floor];
    log(`B${F.id} ${F.name}에 들어섰다.`);
  }
  async function randomEvent(ev) {
    const s = G.state;
    const kind = ev.ev;
    if (kind === 'quiz') {
      R.markUsed(s, ev.x, ev.y);
      const i = R.pickQuiz(s);
      const q = D.QUIZ[i];
      const order = [0, 1, 2];
      const c = await ask({ title: '수다쟁이 초상화 자매', art: sprite('portraits', {}, '', true), body: `<p class="small muted">"어머, 손님! 문제 하나 풀고 가요~"</p><p><b>${esc(q.q)}</b></p>`, vertical: true, dismiss: false, choices: order.map((k) => ({ label: esc(q.a[k]), value: k })) });
      const r = R.answerQuiz(s, i, c);
      if (r.correct) { S.play('good'); toast(`"정답~!" 액자 뒤에서 은화 ${r.silver}개가 떨어졌다.`, 'gold'); log(`퀴즈 정답! 은화 +${r.silver}`); }
      else { S.play('bad'); toast(`"땡~!" 정답은 「${r.answer}」. 액자 모서리로 콩! 체력 -${r.dmg}`, 'bad'); log(`퀴즈 오답… 체력 -${r.dmg}`); }
      R.checkBadges(s).forEach(badgeToast);
      refreshStatus();
      return false;
    }
    if (kind === 'jar') {
      const cost = D.TUNING.gambleCost;
      const c = await ask({ title: '운명의 항아리', art: sprite('jar', {}, '', true), body: `<p>"은화 ${cost}개를 넣어 봐. 무슨 일이 일어날지는 나도 몰라."</p><p class="tiny dim">은화가 불어나거나, 물건이 나오거나, 아무 일도 없거나… 가끔은 저주 연기가 나온다.</p>`, choices: [{ label: `은화 ${cost}개 넣기`, value: 'put', cls: 'curse', disabled: s.silver < cost }, { label: '지나간다', value: null }] });
      if (c !== 'put') return false;
      R.markUsed(s, ev.x, ev.y);
      const r = R.gamble(s);
      if (r.out === 'silver') { S.play('coin'); toast(`짤랑! 은화 ${r.silver}개가 쏟아졌다.`, 'gold'); }
      else if (r.out === 'item') { S.play('chest'); toast(`항아리에서 「${D.ITEMS[r.item].name}」이(가) 튀어나왔다.`, 'gold'); }
      else if (r.out === 'curse') { S.play('bad'); toast('보라색 연기가 피어올랐다… 다음 전투에서 공격력이 떨어진다.', 'bad'); }
      else { S.play('error'); toast('항아리가 "꺼억" 하고 트림만 했다.'); }
      R.checkBadges(s).forEach(badgeToast);
      refreshStatus();
      return false;
    }
    if (kind === 'rumor') {
      R.markUsed(s, ev.x, ev.y);
      const r = R.rumor(s);
      await ask({ title: '벽의 낙서', art: sprite('scroll', {}, '', false), body: `<p>「${esc(r.text)}」</p>${r.target ? `<p class="small" style="color:var(--gold)">낙서 옆에 지도가 그려져 있다. ${esc(r.target.label)} 근처가 밝혀졌다!</p>` : ''}`, choices: [{ label: '확인', value: 1, cls: 'primary' }] });
      return false;
    }
    if (kind === 'treasure') {
      R.markUsed(s, ev.x, ev.y);
      const r = R.treasureFind(s);
      S.play('coin'); toast(`바닥에서 반짝이는 은화 ${r.silver}개를 주웠다.`, 'gold'); log(`은화 +${r.silver}`);
      refreshStatus();
      return false;
    }
    if (kind === 'ambush') {
      R.markUsed(s, ev.x, ev.y);
      await say([{ who: null, text: '물음표의 정체는… 숨어 있던 몬스터였다!' }]);
      const r = await runBattle(R.weighted(D.FLOORS[s.exp.floor].enemies), {});
      if (r === 'lose') await defeat();
      return false;
    }
    return false;
  }
  async function questEvent(ev) {
    const s = G.state;
    const q = R.questDef(ev.qid);
    const o = q.objective;
    await say(q.found.map((text) => ({ who: null, text })));
    if (o.type === 'fetch') {
      R.completeObjective(s, q.id);
      S.play('chest');
      toast(`의뢰 목표 달성! 「${D.ITEMS[o.item].name}」`, 'gold');
      log(`「${D.ITEMS[o.item].name}」을(를) 찾았다. 부실로 돌아가 정화하자.`);
    } else if (o.type === 'defeat') {
      const r = await runBattle(o.enemy, { qid: q.id });
      if (r === 'lose') { await defeat(); return false; }
      if (r === 'win') { toast('의뢰 목표 달성! 부실로 돌아가 정화하자.', 'gold'); log('의뢰 대상을 쓰러뜨렸다.'); }
    } else if (o.type === 'puzzle') {
      const ok = await runPuzzle(5);
      if (ok) { R.completeObjective(s, q.id); S.play('purify'); toast('글자들이 일기장 쪽으로 날아갔다! 의뢰 목표 달성.', 'gold'); s.stats.puzzles += 1; R.checkBadges(s).forEach(badgeToast); }
    }
    save();
    refreshDungeonHUD();
    return false;
  }
  async function goHome(msg) {
    const s = G.state;
    R.returnHome(s);
    save();
    G.ui.log = []; G.ui.pos = null;
    go('hub');
    const n = R.customers(s).length;
    toast(msg || '학교로 돌아왔다.', 'gold');
    setTimeout(() => toast(`${s.day}일째 아침.${n ? ` 부실에 손님 ${n}명이 기다린다.` : ''}`), 400);
    await maybeEnding();
  }
  async function defeat() {
    await say([{ who: null, text: '눈앞이 캄캄해졌다…' }, { who: 'mukmul', text: '냐아… (먹물이 루미의 망토를 물고 양호실까지 끌고 왔다)' }]);
    const r = R.applyDefeat(G.state);
    save();
    G.ui.log = []; G.ui.pos = null;
    go('infirmary');
    toast(`양호실에서 깨어났다. 은화 ${r.lost}개를 잃어버렸다.`, 'bad');
  }
  async function maybeEnding() {
    const s = G.state;
    if (!R.canSeeEnding(s)) return;
    await say(D.LINES.ending);
    s.flags.endingSeen = true;
    save();
    const badges = Object.keys(s.badges).length;
    await ask({
      title: '저주골동품부 존속 확정!',
      art: sprite('rumi', { shadow: true }, '', true).replace('<canvas', '<canvas style="width:120px;height:120px"'),
      body: `<div class="ending-card"><h2>프로토타입 클리어</h2><div class="stats-grid">
        <div><span>걸린 날</span><b>${s.day}일</b></div><div><span>레벨</span><b>Lv${s.player.lv}</b></div>
        <div><span>정화 실적</span><b>${s.purified}건</b></div><div><span>전투</span><b>${s.stats.battles}회</b></div>
        <div><span>훈장</span><b>${badges}/${D.BADGES.length}</b></div><div><span>도감</span><b>${Object.keys(s.codex).length}/${Object.keys(D.ANTIQUES).length}</b></div>
      </div><p class="small muted">플레이해 주셔서 고마워요! 아쉬운 점을 기억해 두었다가 기획을 다듬어요.</p></div>`,
      choices: [{ label: '계속 탐험하기', value: 1, cls: 'primary' }],
    });
    render();
  }

  // ───────── 전투 ─────────
  function runBattle(enemyId, ctx) {
    return new Promise((resolve) => {
      const b = R.createBattle(G.state, enemyId, ctx);
      G.ui.battle = { b, log: [], menu: 'main', busy: true, resolve, fx: { shake: 0, flash: 0, fade: 1, parts: [], appear: performance.now() } };
      renderBattle();
      (async () => {
        S.play('charge');
        blog(`${b.name}이(가) 나타났다!`);
        const E = D.ENEMIES[enemyId];
        if (E.desc) blog(E.desc);
        for (const e of b.intro) blog(e.text);
        if (!G.state.flags.battleTip) { G.state.flags.battleTip = true; blog('공격·마법·물약·도망 중에 골라요. 약점 마법은 더 아파요!'); }
        await sleep(500);
        G.ui.battle.busy = false;
        renderCmds();
      })();
    });
  }
  function renderBattle() {
    clearAnims('overlay');
    const B = G.ui.battle;
    const b = B.b;
    $('#overlay').innerHTML = `<div class="battle" id="battle">
      <div class="b-top">
        <div class="b-name">${esc(b.name)}${b.boss ? '<span class="tag">보스</span>' : b.elite ? '<span class="tag elite">의뢰 대상</span>' : ''}</div>
        <div class="bar ehp big" id="b-ehp"><i></i><span></span></div>
        <div class="b-chips" id="b-chips"></div>
      </div>
      <div class="b-stage"><canvas id="enemy-cv"></canvas><div class="floats" id="e-floats"></div><div class="b-intent" id="b-intent"></div></div>
      <div class="b-log" id="b-log"></div>
      <div class="b-me" id="b-me">${sprite('rumi', { shadow: false }, '', true)}<div class="info"><div class="nm"><b>루미 Lv${G.state.player.lv}</b><span id="b-pchips"></span></div>
        <div class="bar hp" id="b-php"><i></i><span></span></div><div class="bar mp" id="b-pmp"><i></i><span></span></div></div><div class="floats" id="p-floats"></div></div>
      <div class="b-cmds" id="b-cmds"></div>
    </div>`;
    paintCanvases($('#overlay'), 'overlay');
    const cv = $('#enemy-cv');
    const k = dpr();
    const stage = $('.b-stage');
    const side = Math.max(160, Math.min(stage.clientWidth * 0.9, stage.clientHeight, 360));
    cv.width = Math.round(side * k); cv.height = Math.round(side * k);
    const ctx = cv.getContext('2d');
    const fn = A.MON[b.enemyId];
    const scale = D.ENEMIES[b.enemyId].scale || 1;
    addAnim('overlay', (t) => {
      const fx = B.fx;
      const w = cv.width, h = cv.height;
      ctx.setTransform(1, 0, 0, 1, 0, 0);
      ctx.clearRect(0, 0, w, h);
      const now = performance.now();
      const appear = Math.min(1, (now - fx.appear) / 350);
      const sh = fx.shake > now ? Math.sin(now / 18) * w * 0.025 : 0;
      const size = w * 0.76 * Math.min(1.08, scale * 0.84) * (0.6 + 0.4 * appear);
      ctx.save();
      ctx.globalAlpha = fx.fade * appear;
      ctx.translate((w - size) / 2 + sh, (h - size) / 2 + (1 - appear) * 20);
      ctx.scale(size / 100, size / 100);
      ctx.lineJoin = 'round'; ctx.lineCap = 'round';
      if (b.charging) { const gr = ctx.createRadialGradient(50, 55, 10, 50, 55, 54); gr.addColorStop(0, 'rgba(255,125,71,0)'); gr.addColorStop(0.7, `rgba(255,125,71,${0.18 + Math.sin(t * 10) * 0.08})`); gr.addColorStop(1, 'rgba(255,125,71,0)'); ctx.fillStyle = gr; ctx.beginPath(); ctx.arc(50, 55, 54, 0, Math.PI * 2); ctx.fill(); }
      if (b.shield > 0) { ctx.globalAlpha = 0.5; ctx.strokeStyle = '#9b7be0'; ctx.lineWidth = 5; ctx.beginPath(); ctx.arc(50, 55, 50 + Math.sin(t * 4) * 2, 0, Math.PI * 2); ctx.stroke(); ctx.globalAlpha = fx.fade * appear; }
      fn(ctx, b.frozen > 0 || b.sleep > 0 ? t * 0.2 : t);
      if (b.frozen > 0) { ctx.globalAlpha = 0.35; ctx.fillStyle = '#bfe6ff'; ctx.fillRect(0, 0, 100, 100); }
      ctx.restore();
      if (fx.flash > now) {
        ctx.save(); ctx.globalCompositeOperation = 'source-atop'; ctx.globalAlpha = 0.7 * ((fx.flash - now) / 160); ctx.fillStyle = fx.flashColor || '#fff'; ctx.fillRect(0, 0, w, h); ctx.restore();
      }
      // 파티클
      fx.parts = fx.parts.filter((p) => now - p.start < p.life);
      for (const p of fx.parts) {
        const q = (now - p.start) / p.life;
        ctx.globalAlpha = 1 - q;
        ctx.fillStyle = p.color;
        ctx.beginPath(); ctx.arc(p.x * w + p.vx * q * w, p.y * h + p.vy * q * h, p.r * k * (1 - q * 0.5), 0, Math.PI * 2); ctx.fill();
      }
      ctx.globalAlpha = 1;
    });
    updateBattleHUD();
    renderCmds();
  }
  function burst(color, n, spread) {
    const fx = G.ui.battle && G.ui.battle.fx; if (!fx) return;
    const now = performance.now();
    for (let i = 0; i < (n || 14); i++) {
      const a = Math.random() * Math.PI * 2, sp = (spread || 0.35) * (0.4 + Math.random());
      fx.parts.push({ x: 0.5, y: 0.52, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp, r: 3 + Math.random() * 4, color, start: now, life: 500 + Math.random() * 300 });
    }
  }
  function blog(text) {
    const B = G.ui.battle; if (!B) return;
    B.log.push(text);
    const el = $('#b-log');
    if (el) el.innerHTML = B.log.slice(-4).map((l) => `<p>${esc(l)}</p>`).join('');
  }
  function updateBattleHUD() {
    const B = G.ui.battle; if (!B) return;
    const b = B.b, s = G.state, st = R.stats(s);
    const eh = $('#b-ehp');
    if (eh) { eh.querySelector('i').style.width = Math.round((b.hp / b.maxHp) * 100) + '%'; eh.querySelector('span').textContent = `${b.hp}/${b.maxHp}`; }
    const ph = $('#b-php'), pm = $('#b-pmp');
    if (ph) { ph.querySelector('i').style.width = Math.round((s.player.hp / st.maxHp) * 100) + '%'; ph.querySelector('span').textContent = `체력 ${s.player.hp}/${st.maxHp}`; }
    if (pm) { pm.querySelector('i').style.width = Math.round((s.player.mp / st.maxMp) * 100) + '%'; pm.querySelector('span').textContent = `마력 ${s.player.mp}/${st.maxMp}`; }
    const kn = s.known[b.enemyId] || {};
    const chips = [];
    chips.push(b.weak ? (kn.weak ? `<span class="chip weak">약점 ${D.ELEMENTS[b.weak].name}</span>` : '<span class="chip">약점 ?</span>') : '');
    if (b.resist && kn.resist) chips.push(`<span class="chip">저항 ${D.ELEMENTS[b.resist].name}</span>`);
    if (b.traits.evasive) chips.push('<span class="chip">잘 피함</span>');
    if (b.traits.regen) chips.push('<span class="chip">재생</span>');
    if (b.burn > 0) chips.push(`<span class="chip bad">화상 ${b.burn}</span>`);
    if (b.frozen > 0) chips.push('<span class="chip good">빙결</span>');
    if (b.sleep > 0) chips.push('<span class="chip good">잠듦</span>');
    if (b.shield > 0) chips.push(`<span class="chip curse">그림자 방패 ${b.shield}</span>`);
    const c = $('#b-chips'); if (c) c.innerHTML = chips.join('');
    const pc = [];
    if (s.player.status.poison) pc.push('<span class="chip bad">독</span>');
    if (b.pcurse > 0) pc.push(`<span class="chip curse">저주 ${b.pcurse}</span>`);
    const p = $('#b-pchips'); if (p) p.innerHTML = pc.join(' ');
    const it = $('#b-intent'); if (it) it.textContent = b.charging ? '⚠ 기를 모으고 있다! (얼음 가시로 끊기)' : '';
  }
  function renderCmds() {
    const B = G.ui.battle; if (!B) return;
    const b = B.b, s = G.state, st = R.stats(s);
    const el = $('#b-cmds'); if (!el) return;
    const dis = B.busy || b.over ? 'disabled' : '';
    if (B.menu === 'spell') {
      const list = R.knownSpells(s).map((id) => {
        const sp = D.SPELLS[id];
        const ok = R.canAct(s, b, { type: 'spell', id }).ok;
        const hint = sp.elem && b.weak === sp.elem && (s.known[b.enemyId] || {}).weak ? ' · 약점!' : '';
        return `<button class="btn" data-act="bspell" data-arg="${id}" ${ok && !dis ? '' : 'disabled'}><b>${sp.name}${hint}</b><span>마력 ${sp.mp}</span></button>`;
      }).join('');
      el.innerHTML = `<div class="cmd-list">${list}</div><button class="btn wide ghost cmd-back" data-act="bmenu" data-arg="main">← 뒤로</button>`;
      return;
    }
    if (B.menu === 'item') {
      const ids = Object.keys(D.ITEMS).filter((id) => D.ITEMS[id].battle && R.count(s, id) > 0);
      const list = ids.length ? ids.map((id) => {
        const ok = R.canAct(s, b, { type: 'item', id }).ok;
        return `<button class="btn" data-act="bitem" data-arg="${id}" ${ok && !dis ? '' : 'disabled'}><b>${img(D.ITEMS[id].icon, 'ico sm', 48)} ${D.ITEMS[id].name} ×${R.count(s, id)}</b><span>${esc(D.ITEMS[id].desc)}</span></button>`;
      }).join('') : '<div class="empty">쓸 수 있는 물건이 없다.</div>';
      el.innerHTML = `<div class="cmd-list">${list}</div><button class="btn wide ghost cmd-back" data-act="bmenu" data-arg="main">← 뒤로</button>`;
      return;
    }
    const canFlee = !b.noFlee;
    el.innerHTML = `<div class="cmd-grid">
      <button class="btn primary" data-act="battack" ${dis}>공격<small>지팡이</small></button>
      <button class="btn curse" data-act="bmenu" data-arg="spell" ${dis}>마법<small>마력 ${s.player.mp}/${st.maxMp}</small></button>
      <button class="btn" data-act="bmenu" data-arg="item" ${dis}>물약<small>가방</small></button>
      <button class="btn" data-act="bflee" ${dis || (canFlee ? '' : 'disabled')}>도망<small>${canFlee ? Math.round(Math.min(0.95, D.TUNING.fleeBase + st.flee) * 100) + '%' : '불가'}</small></button>
    </div>`;
  }
  function floatAt(target, text, cls) {
    const root = $(target === 'enemy' ? '#e-floats' : '#p-floats');
    if (!root) return;
    const el = document.createElement('div');
    el.className = 'float ' + (cls || '');
    el.textContent = text;
    el.style.left = (45 + Math.random() * 10) + '%';
    root.appendChild(el);
    setTimeout(() => el.remove(), 950);
  }
  async function doAction(action) {
    const B = G.ui.battle;
    if (!B || B.busy || B.b.over) return;
    const chk = R.canAct(G.state, B.b, action);
    if (!chk.ok) { toast(chk.reason, 'bad'); S.play('error'); return; }
    B.busy = true; B.menu = 'main'; renderCmds();
    const ev = R.playerAction(G.state, B.b, action);
    await playEvents(ev);
    updateBattleHUD();
    if (B.b.over) return finishBattle();
    B.busy = false;
    renderCmds();
  }
  async function playEvents(evs) {
    const B = G.ui.battle;
    const now = () => performance.now();
    for (const e of evs) {
      switch (e.t) {
        case 'act':
          if (e.who === 'player' && e.kind === 'spell') {
            const col = { fire: '#ff9a52', ice: '#9fdcff', light: '#ffe680' }[e.elem] || '#9fe0bf';
            S.play(e.spell === 'heal' ? 'heal' : e.elem);
            if (e.elem) burst(col, 18, 0.45);
            await sleep(180);
          } else if (e.who === 'player' && e.kind === 'item') { S.play('heal'); await sleep(120); }
          else if (e.who === 'enemy') { await sleep(240); }
          break;
        case 'dmg':
          if (e.target === 'enemy') {
            B.fx.shake = now() + 260; B.fx.flash = now() + 160; B.fx.flashColor = '#fff';
            S.play(e.amount >= 25 ? 'crit' : 'hit');
            floatAt('enemy', String(e.amount), e.shielded ? 'small' : '');
            burst('#ffffff', 6, 0.2);
          } else {
            S.play('hurt');
            floatAt('player', '-' + e.amount, e.poison ? 'small' : '');
            const me = $('#b-me'); if (me) { me.classList.remove('hurt'); void me.offsetWidth; me.classList.add('hurt'); }
            if (e.big) { const bt = $('#battle'); if (bt) { bt.classList.remove('shake'); void bt.offsetWidth; bt.classList.add('shake'); } }
          }
          updateBattleHUD();
          await sleep(330);
          break;
        case 'miss': floatAt('enemy', '빗나감', 'miss'); S.play('error'); await sleep(250); break;
        case 'crit': floatAt('enemy', '치명타!', 'crit'); break;
        case 'weak': floatAt('enemy', '약점!', 'weak'); break;
        case 'heal': floatAt(e.target, '+' + e.amount, 'heal'); updateBattleHUD(); await sleep(260); break;
        case 'mp': floatAt('player', '+' + e.amount, 'mp'); updateBattleHUD(); await sleep(200); break;
        case 'status': updateBattleHUD(); await sleep(120); break;
        case 'charge': S.play('charge'); updateBattleHUD(); await sleep(260); break;
        case 'shield': burst('#9b7be0', 20, 0.5); updateBattleHUD(); await sleep(300); break;
        case 'shieldBreak': burst('#ffe680', 24, 0.6); updateBattleHUD(); await sleep(250); break;
        case 'pet': S.play('meow'); floatAt('enemy', '냥냥펀치!', 'weak'); await sleep(200); break;
        case 'log': blog(e.text); await sleep(200); break;
        case 'win': burst('#ffcf5a', 30, 0.6); B.fx.fadeStart = now(); fadeEnemy(); break;
        case 'lose': break;
        case 'flee': break;
        case 'deny': toast(e.text, 'bad'); break;
        default: break;
      }
    }
  }
  function fadeEnemy() {
    const B = G.ui.battle; if (!B) return;
    const start = performance.now();
    const f = () => { if (!G.ui.battle) return; const p = (performance.now() - start) / 600; B.fx.fade = Math.max(0, 1 - p); if (p < 1) requestAnimationFrame(f); };
    requestAnimationFrame(f);
  }
  async function finishBattle() {
    const B = G.ui.battle;
    const b = B.b;
    if (b.result === 'win') { S.play('win'); await sleep(650); }
    if (b.result === 'lose') { S.play('lose'); await sleep(900); }
    if (b.result === 'flee') { await sleep(350); }
    clearAnims('overlay');
    $('#overlay').innerHTML = '';
    G.ui.battle = null;
    if (b.result === 'win') await showRewards(b);
    refreshDungeonHUD();
    refreshStatus();
    save();
    B.resolve(b.result);
  }
  async function showRewards(b) {
    const s = G.state;
    const r = b.rewards;
    const rows = [`<div class="row">${img('heart', 'ico sm', 48)}<div class="grow">경험치</div><b>+${r.exp}</b></div>`];
    if (r.silver) rows.push(`<div class="row">${img('coin', 'ico sm', 48)}<div class="grow">은화</div><b>+${r.silver}</b></div>`);
    for (const id of Object.keys(r.items)) rows.push(`<div class="row">${img(D.ITEMS[id].icon, 'ico sm', 48)}<div class="grow">${esc(D.ITEMS[id].name)}</div><b>×${r.items[id]}</b></div>`);
    for (let i = 0; i < r.antiques.length; i++) rows.push(`<div class="row">${img('cursed', 'ico sm', 48)}<div class="grow">저주받은 골동품 <span class="tiny dim">부실에서 정화</span></div><b>×1</b></div>`);
    const toNext = R.expToNext(s);
    await ask({ title: `${b.name} 정화 완료!`, art: '', body: `<div class="loot">${rows.join('')}</div><div class="bar exp"><i style="width:${Math.round((s.player.exp / toNext) * 100)}%"></i><span>다음 레벨까지 ${toNext - s.player.exp}</span></div>`, choices: [{ label: '계속', value: 1, cls: 'primary' }] });
    for (const up of r.levelUps) {
      S.play('levelup');
      const learned = up.learned.map((id) => `<div class="card"><b style="color:var(--curse)">새 마법: ${D.SPELLS[id].name}</b><div class="small muted">${esc(D.SPELLS[id].desc)}</div></div>`).join('');
      await ask({ title: `레벨 업! Lv${up.lv}`, art: sprite('rumi', { shadow: false }, '', true), body: `<div class="stats-grid"><div><span>최대 체력</span><b>+${D.PLAYER.perLevel.maxHp}</b></div><div><span>최대 마력</span><b>+${D.PLAYER.perLevel.maxMp}</b></div><div><span>공격</span><b>+${D.PLAYER.perLevel.atk}</b></div><div><span>방어</span><b>+${D.PLAYER.perLevel.def}</b></div></div>${learned}`, choices: [{ label: '좋아!', value: 1, cls: 'primary' }] });
    }
    R.checkBadges(s).forEach(badgeToast);
  }
  function badgeToast(b) { S.play('good'); toast(`훈장 획득: ${b.name} (+${b.reward}은화)`, 'gold'); }

  // ───────── 퍼즐 ─────────
  function runPuzzle(presses) {
    return new Promise((resolve) => {
      G.ui.puzzle = { g: R.puzzleNew(presses), moves: 0, resolve, start: null };
      G.ui.puzzle.start = G.ui.puzzle.g.slice();
      renderPuzzle();
    });
  }
  function renderPuzzle() {
    const P = G.ui.puzzle;
    const cells = P.g.map((on, i) => `<button class="${on ? 'on' : ''}" data-act="candle" data-arg="${i}" aria-label="촛불 ${i + 1} ${on ? '켜짐' : '꺼짐'}"><canvas data-candle="${on ? 1 : 0}"></canvas></button>`).join('');
    openSheet({
      title: '이상한 방 · 촛불을 모두 밝혀라',
      dismiss: false,
      body: `<p class="small muted">촛불을 누르면 그 촛불과 위·아래·왼쪽·오른쪽 촛불이 함께 켜지거나 꺼진다.</p><div class="candles">${cells}</div><p class="tiny dim" style="text-align:center">누른 횟수 ${P.moves}</p>`,
      foot: `<button class="btn" data-act="puzzleReset">처음부터</button><button class="btn ghost" data-act="puzzleLeave">나간다</button>`,
      after: (root) => {
        const k = dpr();
        for (const cv of $$('canvas[data-candle]', root)) {
          cv.width = cv.clientWidth * k; cv.height = cv.clientHeight * k;
          const ctx = cv.getContext('2d');
          const on = cv.dataset.candle === '1';
          addAnim('sheet', (t) => {
            ctx.clearRect(0, 0, cv.width, cv.height);
            const w = cv.width;
            ctx.save(); ctx.scale(w / 100, w / 100); ctx.lineJoin = 'round';
            ctx.fillStyle = '#efe3cf'; ctx.strokeStyle = '#1d1327'; ctx.lineWidth = 4;
            ctx.beginPath(); ctx.rect(36, 40, 28, 48); ctx.fill(); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(50, 40); ctx.lineTo(50, 32); ctx.stroke();
            if (on) A.flame(ctx, 50, 24, 1, '#ffb35a', '#fff1b0', t + Math.random() * 0.1);
            ctx.restore();
          });
        }
      },
    });
  }

  // ───────── 공용 시트 ─────────
  async function lootSheet(title, loot) {
    const rows = [];
    if (loot.silver) rows.push(`<div class="row">${img('coin', 'ico sm', 48)}<div class="grow">은화</div><b>+${loot.silver}</b></div>`);
    for (const id of Object.keys(loot.items || {})) rows.push(`<div class="row">${img(D.ITEMS[id].icon, 'ico sm', 48)}<div class="grow">${esc(D.ITEMS[id].name)}<div class="tiny dim">${esc(D.ITEMS[id].desc)}</div></div><b>×${loot.items[id]}</b></div>`);
    for (let i = 0; i < (loot.antiques || 0); i++) rows.push(`<div class="row">${img('cursed', 'ico sm', 48)}<div class="grow">저주받은 골동품<div class="tiny dim">부실에서 정화 소금으로 정화하면 정체가 드러난다.</div></div><b>×1</b></div>`);
    log(title);
    refreshStatus();
    await ask({ title, body: `<div class="loot">${rows.join('') || '<div class="empty">텅 비어 있다.</div>'}</div>`, choices: [{ label: '챙긴다', value: 1, cls: 'primary' }] });
  }
  async function merchantSheet() {
    const s = G.state;
    const ids = ['hp_potion', 'mp_potion', 'herb', 'salt', 'feather', 'key'];
    if (s.floorsReached >= 2) ids.push('dew');
    if (s.floorsReached >= 4) ids.push('sand', 'big_potion');
    const line = D.LINES.wanderer[Math.floor(Math.random() * D.LINES.wanderer.length)];
    while (true) {
      const c = await ask({
        title: '방랑냥의 보따리', art: sprite('cat2', {}, '', true), vertical: true,
        body: `<p class="small muted">"${esc(line)}" (매점 가격의 1.5배)</p><p class="tiny">보유 은화 ${s.silver}</p>`,
        choices: ids.map((id) => ({ label: `${D.ITEMS[id].name} · ${Math.round(D.ITEMS[id].price * 1.5)}은화 (보유 ${R.count(s, id)})`, value: id, disabled: s.silver < Math.round(D.ITEMS[id].price * 1.5) })).concat([{ label: '그만 산다', value: null, cls: 'ghost' }]),
      });
      if (!c) break;
      const r = R.buy(s, c, 1, 1.5);
      if (r.ok) { S.play('coin'); toast(`${D.ITEMS[c].name}을(를) 샀다.`, 'gold'); refreshStatus(); }
    }
  }

  // ───────── 액션 ─────────
  const ACT = {};
  ACT.choose = (arg) => { const c = G.ui.choices && G.ui.choices[Number(arg)]; S.play('tap'); closeSheet(c ? c.value : null); };
  ACT.sheetDismiss = () => closeSheet(null);
  ACT.dlgNext = () => dialogNext();
  ACT.dlgSkip = () => dialogSkip();
  ACT.go = (arg) => {
    S.play('tap');
    if (arg === 'shop') G.ui.kikiLine = D.LINES.kiki[Math.floor(Math.random() * D.LINES.kiki.length)];
    if (arg === 'infirmary') G.ui.momoLine = D.LINES.momo[Math.floor(Math.random() * D.LINES.momo.length)];
    go(arg);
    if (arg === 'hub') maybeEnding();
    if (arg === 'club' && !G.state.flags.clubTip) {
      G.state.flags.clubTip = true;
      say([{ who: 'mukmul', text: '냐. (손님 카드를 누르면 사연을 들을 수 있다)' }, { who: 'rumi', text: '매입하면 의뢰가 시작되는구나. 해결하고 돌아와서 정화하면 실적 1건!' }]);
    }
  };
  ACT.newGame = async () => {
    if (G.ui.hasSave) {
      const c = await ask({ title: '처음부터 시작할까요?', body: '<p>저장된 진행이 지워집니다.</p>', choices: [{ label: '처음부터', value: 'yes', cls: 'curse' }, { label: '취소', value: null }] });
      if (c !== 'yes') return;
    }
    clearSave();
    G.state = R.newGame();
    S.setEnabled(G.state.settings.sound);
    save();
    go('hub');
    await say(D.LINES.intro);
    G.state.flags.introSeen = true;
    save();
  };
  ACT.continue = () => {
    const sv = loadSave();
    if (!sv) { toast('저장된 진행이 없어요.', 'bad'); return; }
    G.state = sv;
    S.setEnabled(sv.settings.sound);
    if (sv.exp) { G.ui.pos = null; snapPosSafe(); go('dungeon'); floorBanner(); } else go('hub');
  };
  function snapPosSafe() { if (G.state.exp) snapPos(); }
  ACT.catTip = () => { G.ui.tip += 1; S.play('meow'); render(); };
  ACT.customer = async (qid) => {
    const s = G.state;
    const q = R.questDef(qid);
    const npc = D.NPCS[q.customer];
    await say(q.story.map((text) => ({ who: q.customer, text, mood: 'worried' })));
    const c = await ask({
      title: `「${q.cursedName}」 매입`,
      art: img('cursed', 'ico lg', 128),
      body: `<div class="card"><div class="small"><b>증상</b> ${esc(q.symptom)}</div><div class="small" style="margin-top:6px"><b>해결 방법</b> ${esc(q.hint)}</div><div class="tiny dim" style="margin-top:6px">정화하면 「${esc(D.ANTIQUES[q.antique].name)}」 ${gradeTag(D.ANTIQUES[q.antique].grade)}이(가) 된다.</div></div>
        <p class="small">매입가 <b style="color:var(--gold)">${q.buy}은화</b> · 보유 ${s.silver}은화 · 진행 중 의뢰 ${R.activeQuests(s).length}/3</p>`,
      choices: [{ label: `매입한다 (-${q.buy})`, value: 'buy', cls: 'primary', disabled: s.silver < q.buy || R.activeQuests(s).length >= 3 }, { label: '돌려보낸다', value: 'no' }],
    });
    if (c === 'buy') {
      const r = R.acceptQuest(s, qid);
      if (r.ok) { S.play('coin'); await say([{ who: q.customer, text: '고마워요, 선배! 꼭 부탁해요.' }]); toast(`의뢰 시작! 「${q.objective.place}」`, 'gold'); R.checkBadges(s).forEach(badgeToast); }
      else toast(r.reason, 'bad');
    } else if (c === 'no') {
      R.declineQuest(s, qid);
      await say([{ who: q.customer, text: '…그럼 내일 다시 올게요.' }]);
    }
    save(); render();
    void npc;
  };
  ACT.purifyQuest = async (qid) => {
    const s = G.state;
    const q = R.questDef(qid);
    const r = R.purifyQuest(s, qid);
    if (!r.ok) { toast(r.reason, 'bad'); return; }
    save();
    await purifyReveal(r.antique, q.purify);
    await say([{ who: q.customer, text: '와… 정말 고마워요! 이건 선배가 가져요. 정화 실적에 꼭 넣어주세요!' }]);
    R.checkBadges(s).forEach(badgeToast);
    if (s.purified === 5) toast('정화 실적 5건 달성! 폐부 위기를 넘겼다.', 'gold');
    save(); render();
    await maybeEnding();
  };
  ACT.purifyFound = async (uid) => {
    const s = G.state;
    const r = R.purifyFound(s, Number(uid));
    if (!r.ok) { toast(r.reason, 'bad'); return; }
    save();
    await purifyReveal(r.antique, '정화 소금을 뿌리자 보라색 연기가 걷히고, 골동품이 본모습을 드러냈다.');
    R.checkBadges(s).forEach(badgeToast);
    save(); render();
  };
  async function purifyReveal(a, text) {
    const def = D.ANTIQUES[a.def];
    S.play('purify');
    const c = await ask({
      title: '정화 완료!',
      art: `<canvas id="purify-cv" style="width:140px;height:140px"></canvas>`,
      body: `<p class="small muted">${esc(text)}</p><div class="card row">${img(def.icon, 'ico', 64)}<div class="grow"><b>${esc(def.name)} ${gradeTag(def.grade)}</b><div class="tiny muted">${esc(R.describeEffect(def.effect))}</div><div class="tiny dim">${esc(def.desc)}</div></div></div>`,
      choices: [{ label: '장착', value: 'equip', cls: 'primary' }, { label: '보관', value: 'keep' }, { label: `판매 +${def.value}`, value: 'sell' }],
      after: (root) => {
        const cv = $('#purify-cv', root);
        const k = dpr();
        cv.width = cv.clientWidth * k; cv.height = cv.clientHeight * k;
        const ctx = cv.getContext('2d');
        const t0 = performance.now();
        addAnim('sheet', (t) => {
          const p = Math.min(1, (performance.now() - t0) / 900);
          const w = cv.width;
          ctx.clearRect(0, 0, w, w);
          ctx.globalAlpha = 0.35 + 0.25 * Math.sin(t * 4); ctx.fillStyle = def.grade === 'legend' ? '#ffcf5a' : '#b996ff';
          ctx.beginPath(); ctx.arc(w / 2, w / 2, w * 0.45 * (0.6 + p * 0.4), 0, Math.PI * 2); ctx.fill(); ctx.globalAlpha = 1;
          ctx.globalAlpha = 1 - p; A.draw(ctx, 'cursed', w * 0.15, w * 0.15, w * 0.7, { t });
          ctx.globalAlpha = p; A.draw(ctx, def.icon, w * 0.15, w * 0.15, w * 0.7, { t });
          ctx.globalAlpha = 1;
          for (let i = 0; i < 8; i++) { const a2 = t * 2 + i * 0.8; ctx.fillStyle = '#fff6d0'; ctx.fillRect(w / 2 + Math.cos(a2) * w * 0.4 * p, w / 2 + Math.sin(a2) * w * 0.4 * p, 3 * k, 3 * k); }
        });
      },
    });
    const s = G.state;
    if (c === 'equip') { const r = R.equipAntique(s, a.uid); if (r.ok) toast(`${def.name} 장착!`, 'good'); }
    if (c === 'sell') { const r = R.sellAntique(s, a.uid); if (r.ok) { S.play('coin'); toast(`은화 ${r.price}개를 받았다.`, 'gold'); } }
  }
  ACT.sellCursed = async (uid) => {
    const c = await ask({ title: '헐값에 팔까요?', body: '<p>정화하지 않은 골동품은 10은화밖에 못 받아요. 정화하면 진짜 가치가 드러나요.</p>', choices: [{ label: '10은화에 판다', value: 'yes', cls: 'curse' }, { label: '취소', value: null }] });
    if (c !== 'yes') return;
    R.sellAntique(G.state, Number(uid)); S.play('coin'); save(); render();
  };
  ACT.antique = async (uid) => {
    const s = G.state;
    const a = s.antiques.find((x) => x.uid === Number(uid));
    if (!a) return;
    const def = D.ANTIQUES[a.def];
    const eq = s.equip.indexOf(a.uid);
    const c = await ask({
      title: def.name, art: img(def.icon, 'ico lg', 128),
      body: `<p>${gradeTag(def.grade)} ${esc(def.desc)}</p><div class="card small">${esc(R.describeEffect(def.effect))}</div><p class="tiny dim">장신구 칸은 2개. 판매가 ${def.value}은화</p>`,
      choices: eq >= 0 ? [{ label: '장착 해제', value: 'off' }, { label: '닫기', value: null, cls: 'ghost' }] : [{ label: '장착한다', value: 'on', cls: 'primary' }, { label: `판다 +${def.value}`, value: 'sell' }],
    });
    if (c === 'on') { const r = R.equipAntique(s, a.uid); toast(r.ok ? `${def.name} 장착!` : r.reason, r.ok ? 'good' : 'bad'); }
    if (c === 'off') { R.unequip(s, eq); toast('장착을 해제했다.'); }
    if (c === 'sell') { const r = R.sellAntique(s, a.uid); if (r.ok) { S.play('coin'); toast(`은화 ${r.price}개를 받았다.`, 'gold'); } else toast(r.reason, 'bad'); }
    save(); render();
  };
  // 매점
  ACT.shopTab = (arg) => { G.ui.shopTab = arg; S.play('tap'); render(); };
  ACT.lockedItem = (id) => toast(`B${D.ITEMS[id].unlockFloor}에 도달하면 들여놓을게. 끼끼.`);
  ACT.buySheet = (id) => { G.ui.qty = 1; buySheet(id); };
  function buySheet(id) {
    const s = G.state;
    const it = D.ITEMS[id];
    const total = it.price * G.ui.qty;
    openSheet({
      title: it.name, art: img(it.icon, 'ico lg', 128),
      body: `<p>${esc(it.desc)}</p><p class="tiny dim">보유 ${R.count(s, id)}개 · 보유 은화 ${s.silver}</p>
        <div class="qty"><button class="icon-btn" data-act="qty" data-arg="-1" data-id="${id}" aria-label="하나 빼기">−</button><b>${G.ui.qty}</b><button class="icon-btn" data-act="qty" data-arg="1" data-id="${id}" aria-label="하나 더하기">＋</button></div>`,
      foot: `<button class="btn primary" data-act="buyConfirm" data-arg="${id}" ${s.silver < total ? 'disabled' : ''}>${coin().replace('<img', '<img style="width:18px;height:18px"')} ${total} 사기</button>`,
    });
  }
  ACT.qty = (arg, el) => {
    const id = el.dataset.id;
    G.ui.qty = Math.max(1, Math.min(9, G.ui.qty + Number(arg)));
    if (G.ui.sellMode) sellSheet(id); else buySheet(id);
  };
  ACT.buyConfirm = (id) => {
    const r = R.buy(G.state, id, G.ui.qty);
    if (!r.ok) { toast(r.reason, 'bad'); S.play('error'); return; }
    S.play('coin');
    closeSheet();
    G.ui.kikiLine = `끼끼, ${D.ITEMS[id].name} ${G.ui.qty}개. 고마워! (은화 -${r.price})`;
    R.checkBadges(G.state).forEach(badgeToast);
    save(); render();
  };
  ACT.sellSheet = (id) => { G.ui.qty = 1; G.ui.sellMode = true; sellSheet(id); };
  function sellSheet(id) {
    const s = G.state;
    const it = D.ITEMS[id];
    G.ui.qty = Math.min(G.ui.qty, R.count(s, id));
    openSheet({
      title: `${it.name} 팔기`, art: img(it.icon, 'ico lg', 128),
      body: `<p class="small muted">반값에 사들일게. 끼끼.</p><div class="qty"><button class="icon-btn" data-act="qty" data-arg="-1" data-id="${id}" aria-label="하나 빼기">−</button><b>${G.ui.qty}</b><button class="icon-btn" data-act="qty" data-arg="1" data-id="${id}" aria-label="하나 더하기">＋</button></div><p class="tiny dim" style="text-align:center">보유 ${R.count(s, id)}개</p>`,
      foot: `<button class="btn primary" data-act="sellConfirm" data-arg="${id}">+${R.sellPrice(id) * G.ui.qty}은화 받고 팔기</button>`,
    });
  }
  ACT.sellConfirm = (id) => {
    const r = R.sellItem(G.state, id, G.ui.qty);
    G.ui.sellMode = false;
    if (!r.ok) { toast(r.reason, 'bad'); return; }
    S.play('coin'); closeSheet(); toast(`은화 ${r.price}개를 받았다.`, 'gold'); save(); render();
  };
  // 양호실
  ACT.heal = () => {
    const r = R.infirmary(G.state);
    if (!r.ok) { toast(r.reason, 'bad'); S.play('error'); return; }
    S.play('heal');
    G.ui.momoLine = '다 나았어요! 무리하지 말아요.';
    toast(r.cost ? `치료비 ${r.cost}은화. 몸이 가벼워졌다!` : '첫 치료는 무료예요. 몸이 가벼워졌다!', 'good');
    save(); render();
  };
  // 봉인 창고
  ACT.lockedFloor = (f) => toast(`B${Number(f) - 1}의 계단을 찾아 내려가면 열려요.`);
  ACT.enter = async (f) => {
    const s = G.state;
    const fl = Number(f);
    const st = R.stats(s);
    if (s.player.hp < st.maxHp * 0.5) {
      const c = await ask({ title: '이대로 들어갈까요?', body: `<p>체력이 ${s.player.hp}/${st.maxHp}밖에 없어요. 양호실에서 치료하고 가는 걸 추천해요.</p>`, choices: [{ label: '그래도 들어간다', value: 'go', cls: 'curse' }, { label: '양호실로', value: 'heal' }] });
      if (c === 'heal') { go('infirmary'); return; }
      if (c !== 'go') return;
    }
    R.startExpedition(s, fl);
    G.ui.log = [];
    snapPos();
    save();
    go('dungeon');
    floorBanner();
    if (!s.flags.dungeonTip) {
      s.flags.dungeonTip = true;
      save();
      await say([
        { who: 'rumi', text: '여기가 봉인 창고… 어두운 곳은 아직 모르는 곳이야.' },
        { who: 'mukmul', text: '냐. (바닥을 톡 누르면 거기까지 걸어가. 십자 버튼으로 한 칸씩도 갈 수 있어)' },
        { who: 'mukmul', text: '냐아. (물음표는 사건, 상자는 보물, 몬스터 칸에 들어가면 전투!)' },
        { who: 'rumi', text: '길을 잃으면 먹물 버튼! 냄새로 방향을 알려줘. 돌아갈 땐 처음 계단(↑)이나 귀환 깃털.' },
      ]);
    }
  };
  ACT.move = (arg) => {
    if (G.ui.busy || G.ui.battle) return;
    const [dx, dy] = arg.split(',').map(Number);
    const s = G.state;
    walk([[s.exp.x + dx, s.exp.y + dy]]);
  };
  ACT.here = () => { if (!G.ui.busy) interactHere(); };
  ACT.petHint = () => {
    const s = G.state;
    const r = R.petHint(s);
    S.play('meow');
    if (!r.ok) { toast(r.reason); return; }
    G.ui.hint = { angle: r.angle, until: performance.now() + 3500 };
    toast(`먹물: 냐! ${r.dir} ${r.far}에서 「${r.label}」 냄새가 난다.`, 'gold');
    log(`먹물이 ${r.dir}을(를) 가리킨다. (${r.label})`);
    save();
  };
  ACT.goHomeAsk = async () => {
    const s = G.state;
    if (G.ui.busy) return;
    const n = R.count(s, 'feather');
    if (!n) { toast('귀환 깃털이 없다. 처음 내려온 계단(↑)으로 올라가야 한다.'); return; }
    const c = await ask({ title: '귀환 깃털', body: `<p>깃털을 쓰면 곧장 학교로 돌아간다. (보유 ${n}개)</p>`, choices: [{ label: '학교로 돌아간다', value: 'go', cls: 'primary' }, { label: '취소', value: null }] });
    if (c !== 'go') return;
    R.removeItem(s, 'feather', 1);
    await goHome('깃털이 루미를 감싸 학교로 날아올랐다.');
  };
  // 전투 명령
  ACT.battack = () => doAction({ type: 'attack' });
  ACT.bflee = () => doAction({ type: 'flee' });
  ACT.bspell = (id) => doAction({ type: 'spell', id });
  ACT.bitem = (id) => doAction({ type: 'item', id });
  ACT.bmenu = (arg) => { const B = G.ui.battle; if (!B || B.busy) return; B.menu = arg; S.play('tap'); renderCmds(); };
  // 퍼즐
  ACT.candle = (arg) => {
    const P = G.ui.puzzle; if (!P) return;
    R.puzzleToggle(P.g, Number(arg));
    P.moves += 1;
    S.play('tap');
    if (R.puzzleSolved(P.g)) {
      S.play('purify');
      renderPuzzle();
      setTimeout(() => { closeSheet(); const r = P.resolve; G.ui.puzzle = null; toast('모든 촛불이 켜졌다!', 'gold'); r(true); }, 500);
      return;
    }
    renderPuzzle();
  };
  ACT.puzzleReset = () => { const P = G.ui.puzzle; if (!P) return; P.g = P.start.slice(); P.moves = 0; renderPuzzle(); };
  ACT.puzzleLeave = () => { const P = G.ui.puzzle; if (!P) return; closeSheet(); G.ui.puzzle = null; P.resolve(false); };
  // 메뉴 시트
  ACT.openBag = () => bagSheet();
  function bagSheet() {
    const s = G.state;
    const ids = Object.keys(s.inv).filter((id) => s.inv[id] > 0 && D.ITEMS[id]);
    const order = { potion: 0, tool: 1, material: 2, quest: 3 };
    ids.sort((a, b) => order[D.ITEMS[a].cat] - order[D.ITEMS[b].cat]);
    const rows = ids.map((id) => {
      const it = D.ITEMS[id];
      const usable = it.field && (!(it.use || {}).returnHome && !(it.use || {}).sight || s.exp);
      return `<div class="card row">${img(it.icon, 'ico', 64)}<div class="grow"><b>${esc(it.name)} <span class="dim">×${s.inv[id]}</span></b><div class="tiny muted">${esc(it.desc)}</div></div>${usable ? `<button class="btn small" data-act="useItem" data-arg="${id}">쓰기</button>` : ''}</div>`;
    }).join('');
    openSheet({ title: '가방', icon: img('bag', 'ico sm', 48), body: rows || '<div class="empty">가방이 비어 있다.</div>' });
  }
  ACT.useItem = async (id) => {
    const s = G.state;
    const r = R.useItemField(s, id);
    if (!r.ok) { toast(r.reason, 'bad'); S.play('error'); return; }
    S.play('heal');
    toast(r.text, 'good');
    save();
    if (r.returnHome) { closeSheet(); await goHome(r.text); return; }
    refreshStatus(); refreshDungeonHUD();
    bagSheet();
  };
  ACT.openStatus = () => statusSheet();
  function statusSheet() {
    const s = G.state;
    const st = R.stats(s);
    const toNext = R.expToNext(s);
    const slots = [0, 1].map((i) => {
      const a = s.equip[i] != null ? s.antiques.find((x) => x.uid === s.equip[i]) : null;
      const def = a && D.ANTIQUES[a.def];
      return `<button class="card row" data-act="equipSlot" data-arg="${i}" style="width:100%;text-align:left">${def ? img(def.icon, 'ico', 64) : '<div class="ico" style="border:1.5px dashed var(--line);border-radius:10px"></div>'}<div class="grow"><b>${def ? esc(def.name) : `장신구 칸 ${i + 1}`}</b><div class="tiny muted">${def ? esc(R.describeEffect(def.effect)) : '정화한 골동품을 장착할 수 있다'}</div></div><span class="chip">바꾸기</span></button>`;
    }).join('');
    const extra = [];
    if (st.flee) extra.push(`도망 +${Math.round(st.flee * 100)}%`);
    if (st.crit) extra.push(`치명타 +${Math.round(st.crit * 100)}%`);
    if (st.sight) extra.push(`시야 +${st.sight}`);
    if (st.mpRegen) extra.push(`매 턴 마력 +${st.mpRegen}`);
    if (st.fireBoost) extra.push(`불 +${Math.round(st.fireBoost * 100)}%`);
    if (st.iceBoost) extra.push(`얼음 +${Math.round(st.iceBoost * 100)}%`);
    if (st.lightBoost) extra.push(`빛 +${Math.round(st.lightBoost * 100)}%`);
    if (st.silverBoost) extra.push(`은화 +${Math.round(st.silverBoost * 100)}%`);
    if (st.trapSight) extra.push('함정 감지');
    openSheet({
      title: `루미 · Lv${s.player.lv}`, art: sprite('rumi', { shadow: s.flags.bossDefeated }, '', true),
      body: `<div class="bar exp big"><i style="width:${Math.round((s.player.exp / toNext) * 100)}%"></i><span>경험치 ${s.player.exp}/${toNext}</span></div>
        <div class="stats-grid"><div><span>체력</span><b>${s.player.hp}/${st.maxHp}</b></div><div><span>마력</span><b>${s.player.mp}/${st.maxMp}</b></div><div><span>공격</span><b>${st.atk}</b></div><div><span>방어</span><b>${st.def}</b></div></div>
        ${extra.length ? `<div class="small muted">${extra.join(' · ')}</div>` : ''}
        <h3 class="sec" style="margin-top:6px">장신구 (정화한 골동품)</h3>${slots}
        <h3 class="sec" style="margin-top:6px">마법</h3>
        ${D.SPELL_ORDER.map((id) => { const sp = D.SPELLS[id]; const k = sp.learn <= s.player.lv; return `<div class="card small" style="${k ? '' : 'opacity:.45'}"><b>${sp.name}</b> <span class="dim">마력 ${sp.mp}${k ? '' : ` · Lv${sp.learn}에 배움`}</span><div class="tiny muted">${esc(sp.desc)}</div></div>`; }).join('')}
        <p class="tiny dim">그림자: ${s.flags.bossDefeated ? '발끝까지 돌아왔다' : '없다… (봉인 창고 아래에서 냄새가 난다)'}</p>`,
    });
  }
  ACT.equipSlot = async (arg) => {
    const s = G.state;
    const slot = Number(arg);
    const list = s.antiques.filter((a) => a.state === 'purified');
    const choices = list.map((a) => ({ label: `${D.ANTIQUES[a.def].name} · ${R.describeEffect(D.ANTIQUES[a.def].effect)}${s.equip.indexOf(a.uid) >= 0 ? ' (장착 중)' : ''}`, value: a.uid }));
    if (s.equip[slot] != null) choices.push({ label: '비워 두기', value: 'off', cls: 'ghost' });
    if (!choices.length) { toast('정화한 골동품이 없어요. 부실에서 정화해 보세요.'); return; }
    const c = await ask({ title: `장신구 칸 ${slot + 1}`, vertical: true, body: '', choices });
    if (c === 'off') R.unequip(s, slot);
    else if (c != null) R.equipAntique(s, c, slot);
    save();
    if (G.ui.screen !== 'dungeon') render(); else refreshDungeonHUD();
    statusSheet();
  };
  ACT.openCodex = () => {
    const s = G.state;
    const ids = Object.keys(D.ANTIQUES);
    openSheet({
      title: `골동품 도감 ${Object.keys(s.codex).length}/${ids.length}`, icon: img('book', 'ico sm', 48),
      body: `<div class="codex">${ids.map((id) => { const d = D.ANTIQUES[id]; const k = s.codex[id]; return `<button class="tile ${k ? '' : 'unknown'}" data-act="codexItem" data-arg="${id}">${img(d.icon, '', 64)}<b>${k ? esc(d.name) : '???'}</b><span class="tiny" style="color:${D.GRADES[d.grade].color}">${D.GRADES[d.grade].name}</span></button>`; }).join('')}</div>
        <p class="tiny dim">의뢰를 정화하거나, 봉인 창고에서 찾은 저주받은 골동품을 정화하면 채워진다.</p>`,
    });
  };
  ACT.codexItem = (id) => {
    const s = G.state; const d = D.ANTIQUES[id];
    if (!s.codex[id]) { toast(d.random ? '봉인 창고 어딘가에서 잠들어 있다.' : '손님의 의뢰로 만날 수 있다.'); return; }
    toast(`${d.name}: ${R.describeEffect(d.effect)}`, 'gold');
  };
  ACT.openBadges = () => {
    const s = G.state;
    openSheet({
      title: `훈장 ${Object.keys(s.badges).length}/${D.BADGES.length}`, icon: img('medal', 'ico sm', 48),
      body: D.BADGES.map((b) => `<div class="card row badge-row ${s.badges[b.id] ? 'on' : ''}">${img('medal', 'ico', 64)}<div class="grow"><b>${esc(b.name)}</b><div class="tiny muted">${esc(b.desc)}</div></div><span class="tiny">${s.badges[b.id] ? `${s.badges[b.id]}일째` : `+${b.reward}`}</span></div>`).join(''),
    });
  };
  ACT.openSettings = () => {
    const s = G.state;
    openSheet({
      title: '설정', icon: img('gear', 'ico sm', 48),
      body: `<button class="btn wide" data-act="toggleSound">효과음 ${s.settings.sound ? '켜짐' : '꺼짐'}</button>
        <button class="btn wide" data-act="help">플레이 방법</button>
        <button class="btn wide ghost" data-act="resetAsk">처음부터 다시 하기</button>
        <p class="tiny dim">프로토타입 v0.1 · 진행은 이 브라우저에만 저장돼요. 레퍼런스: 마녀의 집(분위기), 동물농장(상점·훈장·북쪽탑 탐험), 마법학교 아르피아(미로·방 찾기), 크라라 공주와 이상한 방(촛불 퍼즐).</p>`,
    });
  };
  ACT.toggleSound = () => { const s = G.state; s.settings.sound = !s.settings.sound; S.setEnabled(s.settings.sound); save(); ACT.openSettings(); };
  ACT.help = () => {
    openSheet({
      title: '플레이 방법',
      body: `<ol class="small" style="margin:0;padding-left:20px;display:grid;gap:8px">
        <li>부실에서 손님의 저주 물건을 <b>매입</b>하면 의뢰가 시작돼요.</li>
        <li>봉인 창고에서 바닥을 <b>탭</b>하면 그곳까지 걸어가요. 십자 버튼으로 한 칸씩도 움직여요.</li>
        <li>몬스터 칸에 들어가면 <b>턴제 전투</b>. 공격·마법·물약·도망 중에 골라요.</li>
        <li><b>약점 속성</b> 마법은 더 아파요. 기를 모으는 적은 <b>얼음 가시</b>로 끊어요.</li>
        <li>의뢰를 마치면 부실에서 <b>정화</b>. 정화한 골동품은 팔거나 장착해요.</li>
        <li>정화 실적 <b>5건</b> + B5의 <b>그림자 집사</b>를 쓰러뜨리면 엔딩!</li>
        <li>길을 잃으면 <b>먹물</b> 버튼 (층마다 3번). 돌아갈 땐 처음 계단(↑)이나 귀환 깃털.</li>
      </ol>`,
    });
  };
  ACT.resetAsk = async () => {
    const c = await ask({ title: '정말 처음부터 할까요?', body: '<p>저장된 진행이 모두 지워집니다.</p>', choices: [{ label: '지우고 처음부터', value: 'yes', cls: 'curse' }, { label: '취소', value: null }] });
    if (c !== 'yes') return;
    clearSave();
    G.state = null; G.ui.hasSave = false;
    go('title');
  };

  // 클릭 위임
  function onClick(e) {
    const el = e.target.closest('[data-act]');
    if (!el || el.disabled) return;
    S.unlock();
    const fn = ACT[el.dataset.act];
    if (!fn) return;
    e.preventDefault();
    if (el.dataset.act !== 'choose' && el.dataset.act !== 'dlgNext' && el.dataset.act !== 'move') S.play('tap');
    fn(el.dataset.arg, el, e);
  }

  function boot(restore) {
    document.addEventListener('click', onClick);
    requestAnimationFrame(loop);
    let resizeT = null;
    window.addEventListener('resize', () => { clearTimeout(resizeT); resizeT = setTimeout(() => { if (G.state || G.ui.screen === 'title') render(); }, 150); });
    if (restore) {
      const st = R.deserialize(restore);
      if (st) { G.state = st; S.setEnabled(st.settings.sound); if (st.exp) { snapPos(); go('dungeon'); } else go('hub'); return; }
    }
    go('title');
  }

  W.ui = { boot, render, go, G, ACT, toast, save, tapTile, walk, runBattle, debug: { handleEvent, say, ask, showRewards, snapPos, maybeEnding } };
})();
