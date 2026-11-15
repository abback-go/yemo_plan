/*
 * scenes.js — 타이틀 / 캠프 대화(비주얼노벨) / 용사 사망 컷신(C1~C6) / 탈출 / 종료 / 전멸
 */
(function (root) {
  'use strict';
  var Game = root.Game = root.Game || {};
  var S = Game.Scenes = { current: null };
  var FX = Game.FX;

  function D() { return Game.DATA; }
  function $(id) { return document.getElementById(id); }
  function div(cls, parent) { var d = document.createElement('div'); if (cls) d.className = cls; if (parent) parent.appendChild(d); return d; }

  S.clear = function () {
    $('sceneLayer').innerHTML = '';
    S.current = null;
  };
  function mount(cls, name) {
    S.clear();
    var el = div('scene ' + cls, $('sceneLayer'));
    el.setAttribute('data-scene', name);
    S.current = name;
    return el;
  }

  // ───────── 타이틀 ─────────
  S.title = function () {
    Game.Ctl.inBattle = false;
    Game.View.clear();
    Game.Dialog.clear();
    var el = mount('title-scene', 'title');
    var m = D().meta;
    el.innerHTML = '<div class="title-thread"></div><h1>' + m.title + '</h1><div class="sub">' + m.subtitle + '</div>' +
      '<div class="btn" data-act="start">' + m.startButton + '</div><div class="note">' + m.note + '</div>';
    el.querySelector('[data-act=start]').addEventListener('click', function () { Game.Ctl.startTutorial(); });
    FX.fade(0, 300);
  };

  // ───────── 캠프 대화 ─────────
  var SLOT_X = { FL: 250, L: 600, C: 960, R: 1320, FR: 1670 }, STAND_H = 1010;
  S.camp = function () {
    return new Promise(function (resolve) {
      Game.Ctl.inBattle = false;
      Game.View.clear();
      var el = mount('vn', 'camp');
      var bg = div('vn-bg', el);
      bg.appendChild(Game.Assets.el(D().camp.bg, 1920, 1080, { phCls: 'bg' }));
      div('vn-fire', el);
      var stands = {};
      Object.keys(D().standing).forEach(function (k) {
        var s = div('stand', el);
        s.setAttribute('data-char', k);
        // 너비를 그림의 원래 비율로 직접 정한다(화면 오른쪽 끝 자리에서도 상자가 줄어들어 그림이 찌그러지지 않게)
        var file = D().standing[k], sz = Game.Assets.size(file), h = STAND_H, w = sz ? h * sz.w / sz.h : 430;
        s.style.width = w + 'px'; s.style.height = h + 'px';
        s.appendChild(Game.Assets.el(file, w, h));
        stands[k] = s;
      });
      var box = div('vn-box', el);
      var face = div('vn-face', box);
      var nm = div('vn-name', box), tx = div('vn-text', box), nx = div('vn-next', box);
      nx.textContent = '▼';
      var skip = div('vn-skip', el);
      skip.textContent = '건너뛰기 ▶▶';
      var script = D().camp.script, idx = -1, typing = false, timer = null, full = '';
      var cur = {};

      function applyShow(show) {
        cur = show;
        Object.keys(stands).forEach(function (k) {
          var on = show[k] != null;
          stands[k].classList.toggle('on', on);
          if (on) stands[k].style.left = SLOT_X[show[k]] + 'px';
        });
      }
      function next() {
        idx++;
        if (idx >= script.length) return finish();
        var ln = script[idx];
        if (ln.show) applyShow(ln.show);
        var sp = ln.speaker, who = sp === 'inner' ? 'noel' : sp;
        Object.keys(stands).forEach(function (k) {
          stands[k].classList.toggle('dim', !(k === who) && (sp !== 'narr' ? true : true));
        });
        if (sp !== 'narr' && !stands[who]) Object.keys(stands).forEach(function (k) { stands[k].classList.remove('dim'); });
        var nmText = D().names[sp] || '';
        if (sp === 'inner') nmText = '노엘';
        nm.textContent = nmText;
        nm.classList.toggle('empty', !nmText);
        // 말하는 사람의 표정 (표정 그림이 있는 대사만 큰 얼굴로)
        var hasFace = !!(ln.face && Game.Assets.ok(Game.Assets.expressionFile(ln.face)));
        box.classList.toggle('has-face', hasFace);
        if (hasFace) Game.Assets.applyFace(face, who, 230, 1, ln.face, true);
        else face.removeAttribute('data-face-img');
        tx.className = 'vn-text' + (sp === 'narr' ? ' narr' : sp === 'inner' ? ' inner' : '');
        full = sp === 'inner' ? '(' + ln.text + ')' : ln.text;
        tx.textContent = '';
        typing = true;
        var n = 0;
        clearInterval(timer);
        timer = setInterval(function () {
          n++;
          tx.textContent = full.slice(0, n);
          if (n >= full.length) { clearInterval(timer); typing = false; }
        }, 1000 / (D().timing.typeCharsPerSec * FX.speed));
        el.setAttribute('data-line', idx);
      }
      function finish() {
        clearInterval(timer);
        el.removeEventListener('pointerdown', onClick);
        FX.fade(1, 600).then(function () { resolve(); });
      }
      function onClick(e) {
        if (e.button !== 0) return;
        if (typing) { clearInterval(timer); typing = false; tx.textContent = full; return; }
        next();
      }
      el.addEventListener('pointerdown', onClick);
      skip.addEventListener('pointerdown', function (e) { e.stopPropagation(); idx = script.length; finish(); });
      FX.fade(0, 500);
      next();
    });
  };

  // ───────── 용사 사망 컷신 C1~C6 ─────────
  var cut = null;
  function waitOrClick(ms) {
    return new Promise(function (res) {
      var done = false;
      function fin() { if (done) return; done = true; clearTimeout(t); if (cut && cut.waiter === fin) cut.waiter = null; res(); }
      var t = setTimeout(fin, FX.ms(ms));
      if (cut) cut.waiter = fin;
    });
  }
  function setImage(name, fallback) {
    var pick = Game.Assets.pick(name, fallback);
    var img = Game.Assets.el(pick, 1920, 1080, { phCls: 'cutph' });
    if (cut.img) cut.img.remove();
    cut.box.insertBefore(img, cut.box.firstChild);
    cut.img = img;
    cut.imageName = name;
    cut.root.setAttribute('data-image', pick);
  }
  function zoom(from, to, ms) {
    if (cut.zoomAnim) cut.zoomAnim.cancel();
    cut.box.style.transform = '';
    cut.zoomAnim = cut.box.animate([{ transform: 'scale(' + from + ')' }, { transform: 'scale(' + to + ')' }], { duration: FX.ms(ms), easing: 'linear', fill: 'forwards' });
  }
  function shade(v, ms) { cut.shade.style.transition = 'opacity ' + (FX.ms(ms) / 1000) + 's'; cut.shade.style.opacity = v; }
  function black(v, ms) { cut.black.style.transition = 'opacity ' + (FX.ms(ms || 0) / 1000) + 's'; cut.black.style.opacity = v; return FX.wait(ms || 0); }
  function subtitle(ln) {
    if (!ln) { cut.sub.style.opacity = 0; return; }
    var who = ln.who === 'system' ? '' : (D().names[ln.who] || '');
    cut.sub.innerHTML = (who ? '<span class="who">' + who + '</span>' : '') + ln.text;
    cut.sub.style.opacity = 1;
  }

  async function imageCut(c) {
    setImage(c.image, c.fallback);
    var z = c.zoom || [1, 1.03];
    zoom(z[0], z[1], c.duration);
    if (c.id === 'C1') { shade(0, 0); setTimeout(function () { shade(0.35, c.duration); }, 30); }
    else if (c.id === 'C2') { shade(0.35, 0); setTimeout(function () { shade(0.62, c.duration * 0.8); }, 30); FX.shakeEl(cut.img, 3, c.duration, 0.2); }
    else shade(0, 300);
    await black(0, c.id === 'C1' ? 700 : 250);
    var lines = c.lines || [];
    if (!lines.length) { subtitle(null); await waitOrClick(c.duration); return; }
    for (var i = 0; i < lines.length; i++) {
      subtitle(lines[i]);
      await waitOrClick(c.duration / lines.length);
    }
    subtitle(null);
  }

  async function impactCut(c) {
    subtitle(null);
    FX.flash('#fff', 260, 1);
    await FX.wait(90);
    black(1, 0);
    shade(0, 0);
    FX.shakeEl(cut.root, 44, 750);
    cut.lensCv.style.transition = 'none'; cut.lensCv.style.opacity = 1;
    Game.Blood.spray(cut.lens, { count: 4, min: 160, max: 300, x0: 300, x1: 1500, y0: 150, y1: 700, seed: 13, stagger: 40 });
    Game.Blood.spray(cut.lens, { count: 7, min: 40, max: 110, seed: 31, stagger: 25 });
    await waitOrClick(c.duration);
  }

  async function grindCut(c) {
    if (cut.imageName !== c.image) setImage(c.image);
    if (cut.zoomAnim) { cut.zoomAnim.cancel(); cut.zoomAnim = null; }
    black(0, 0);
    var box = cut.box, lift = c.lift || 40, tw = c.twistDeg || 2;
    var t0 = performance.now(), skipped = false;
    var skipWait = waitOrClick(c.duration).then(function () { skipped = true; });
    for (var i = 0; i < (c.slams || 2) && !skipped; i++) {
      // 발이 살짝 들린다(그림 전체가 위로)
      // (확대해 두어 그림이 움직여도 가장자리가 비지 않게)
      await FX.anim(box, [{ transform: 'translateY(0) scale(1.08)' }, { transform: 'translateY(' + (-lift) + 'px) scale(1.1)' }], { duration: 460, easing: 'ease-out', fill: 'forwards' });
      if (skipped) break;
      await FX.wait(120);
      // 세게 내리찍는다
      await FX.anim(box, [{ transform: 'translateY(' + (-lift) + 'px) scale(1.1)' }, { transform: 'translateY(14px) scale(1.14)', offset: 0.55 }, { transform: 'translateY(0) scale(1.08)' }], { duration: 220, easing: 'ease-in', fill: 'forwards' });
      FX.shakeEl(cut.root, 40, 480);
      FX.flash('#3a0006', 240, 0.45);
      cut.poolItem.level += 1.1;
      await FX.wait(380);
    }
    if (!skipped) {
      // 비틀기: 좌우 회전 흔들림
      FX.shakeEl(cut.root, 12, 760);
      cut.poolItem.level += 0.9;
      await FX.anim(box, [
        { transform: 'translateY(0) scale(1.08) rotate(0deg)' }, { transform: 'translateY(4px) scale(1.1) rotate(' + (-tw) + 'deg)', offset: 0.2 },
        { transform: 'translateY(2px) scale(1.1) rotate(' + tw + 'deg)', offset: 0.45 }, { transform: 'translateY(4px) scale(1.1) rotate(' + (-tw * 0.6) + 'deg)', offset: 0.7 },
        { transform: 'translateY(0) scale(1.08) rotate(' + (tw * 0.25) + 'deg)', offset: 0.88 }, { transform: 'translateY(0) scale(1.08) rotate(0deg)' }
      ], { duration: 760, easing: 'ease-in-out', fill: 'forwards' });
    }
    var left = c.duration - (performance.now() - t0) * FX.speed;
    if (!skipped && left > 0) await skipWait;
  }

  S.cutscene = async function () {
    var cs = D().cutscene;
    var el = mount('cut', 'cutscene');
    cut = { root: el, waiter: null };
    cut.box = div('cut-img', el);
    var pool = document.createElement('canvas'); pool.width = 1920; pool.height = 1080; pool.style.mixBlendMode = 'multiply'; cut.box.appendChild(pool);
    cut.shade = div('cut-shade', el);
    cut.black = div('cut-black', el);
    var lens = document.createElement('canvas'); lens.width = 1920; lens.height = 1080; el.appendChild(lens);
    cut.lensCv = lens;
    cut.sub = div('cut-sub', el);
    var hint = div('cut-hint', el); hint.textContent = '클릭: 다음';
    cut.pool = Game.Blood.layer(pool);
    cut.poolItem = Game.Blood.pool(cs.pool.x0, cs.pool.x1, cs.pool.y, 5);
    cut.pool.items.push(cut.poolItem);
    cut.lens = Game.Blood.layer(lens);
    el.addEventListener('pointerdown', function () { if (cut && cut.waiter) cut.waiter(); });
    black(1, 0);
    S.cutLog = [];
    for (var i = 0; i < cs.cuts.length; i++) {
      var c = cs.cuts[i];
      el.setAttribute('data-cut', c.id);
      S.cutLog.push(c.id);
      if (c.id === 'C4') { cut.lensCv.style.transition = 'opacity 1.2s'; cut.lensCv.style.opacity = 0.85; }
      if (c.code === 'impact') await impactCut(c);
      else if (c.code === 'grind') await grindCut(c);
      else {
        if (c.id === 'C6') { cut.pool.items = []; cut.box.getAnimations().forEach(function (a) { a.cancel(); }); cut.lensCv.style.transition = 'opacity ' + FX.ms(c.duration) / 1000 + 's'; cut.lensCv.style.opacity = 0.45; }
        await imageCut(c);
      }
    }
    subtitle(null);
    cut.lensCv.style.transition = 'opacity .4s'; cut.lensCv.style.opacity = 0;
    await black(1, 500);
  };
  // 컷신을 걷고 전투 화면으로 (C7)
  S.closeCutscene = async function (delay) {
    if (!cut) return;
    await FX.wait(delay || 0);
    var el = cut.root;
    await FX.anim(el, [{ opacity: 1 }, { opacity: 0 }], { duration: 700, fill: 'forwards' });
    Game.Blood.remove(cut.pool); Game.Blood.remove(cut.lens);
    if (cut.zoomAnim) cut.zoomAnim.cancel();
    el.remove();
    cut = null;
    S.current = null;
  };

  // ───────── 탈출 → 종료 ─────────
  S.escape = async function () {
    await Game.Dialog.say(D().escape.lines);
    await FX.fade(1, 900);
    Game.Ctl.inBattle = false;
    Game.Dialog.clear();
    var el = mount('escape', 'escape');
    var t = div('escape-title', el);
    t.textContent = D().escape.title;
    await FX.fade(0, 200);
    await FX.wait(60);
    t.classList.add('on');
    await FX.wait(1900);
    t.classList.remove('on');
    await FX.wait(800);
    S.ending();
  };

  S.ending = function () {
    Game.Ctl.inBattle = false;
    Game.View.clear();
    var e = D().ending;
    var el = mount('end-scene', 'ending');
    el.innerHTML = '<h2>' + e.title + '</h2>' + e.lines.map(function (l) { return '<p>' + l + '</p>'; }).join('') +
      '<p class="inner">' + e.inner + '</p><div class="btn" data-act="again">' + e.button + '</div>';
    var ps = el.querySelectorAll('p'), btn = el.querySelector('.btn');
    Array.prototype.forEach.call(ps, function (p, i) { setTimeout(function () { p.classList.add('on'); }, FX.ms(500 + i * 1400)); });
    setTimeout(function () { btn.classList.add('on'); }, FX.ms(500 + ps.length * 1400));
    btn.addEventListener('click', function () { Game.Ctl.startTutorial(); });
    FX.fade(0, 400);
  };

  // ───────── 전멸 ─────────
  S.wipe = function (kind) {
    return new Promise(function (resolve) {
      var w = D().wipe[kind] || D().wipe.normal;
      var el = div('scene wipe-scene', $('sceneLayer'));
      el.setAttribute('data-scene', 'wipe');
      S.current = 'wipe';
      el.innerHTML = '<h2>' + w.title + '</h2><p>' + w.text + '</p><div class="btn" data-act="retry">' + w.button + '</div>';
      el.querySelector('[data-act=retry]').addEventListener('click', function () { el.remove(); S.current = null; resolve(); });
      FX.fade(0, 500);
    });
  };
})(window);
