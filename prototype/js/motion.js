/*
 * motion.js — 동료·적의 움직임
 *  · 동료 카드: 준비(살짝 움츠림) → 기본 자세와 행동 자세를 겹쳐 녹임 → 타격(대상 쪽으로 튀어나감 + 확대, 순간 멈춤, 잔상)
 *    → 복귀(살짝 지나쳤다 돌아오는 감속, 기본 자세로 녹아듦)
 *  · 대기 중 숨쉬기(위아래 1~2px, 캐릭터마다 위상 다르게) — CSS 애니메이션, prefers-reduced-motion 이면 멈춤
 *  · 적 공격: 몸을 젖혔다 달려듦 / 맞은 동료: 흔들림
 * 수치는 data.js motion, 자세 그림은 data.js layout.poses
 */
(function (root) {
  'use strict';
  var Game = root.Game = root.Game || {};
  var M = Game.Motion = { log: [] };   // log: 시험용 기록

  function D() { return Game.DATA; }
  function V() { return Game.View; }
  function FX() { return Game.FX; }
  function done() { return Promise.resolve(); }

  // 행동 자세 그림의 화면 상자: 기본 자세와 같은 배율, 발끝(아래 가운데) 기준
  M.poseBox = function (id, pose) {
    var p = (D().layout.poses[id] || {})[pose], a = D().layout.allies[id];
    if (!p) return null;
    var base = Game.Assets.size(a.img), sz = Game.Assets.size(p.img);
    if (!base || !sz) return null;
    var k = a.h / base.h, w = sz.w * k, h = sz.h * k;
    var b = V().allyBox(id);
    return { x: b.w / 2 - w / 2 + (p.dx || 0), y: b.h - h + (p.dy || 0), w: w, h: h, img: p.img };
  };

  // 동료 요소 안에 행동 자세 그림을 미리 깔아 둔다(투명). V.build 에서 호출
  M.buildAlly = function (id, el, shadeBox) {
    var poses = D().layout.poses[id] || {};
    var pose = el.querySelector('.pose');
    Object.keys(poses).forEach(function (name) {
      var bx = M.poseBox(id, name);
      if (!bx) return;
      var act = document.createElement('div');
      act.className = 'act';
      act.setAttribute('data-pose', name);
      act.style.left = bx.x + 'px'; act.style.top = bx.y + 'px'; act.style.width = bx.w + 'px'; act.style.height = bx.h + 'px';
      act.appendChild(Game.Assets.el(bx.img, bx.w, bx.h));
      if (shadeBox) act.appendChild(shadeBox(bx.img, bx.w, bx.h, bx.x, bx.y));
      pose.appendChild(act);
    });
    // 숨쉬기: 캐릭터마다 위상이 다르게
    var br = D().motion.breathe, order = Game.DATA.party.order, i = Math.max(0, order.indexOf(id));
    pose.style.setProperty('--breathe-amp', (-br.amp) + 'px');
    pose.style.animationDuration = (br.period / 1000) + 's';
    pose.style.animationDelay = (-(i * 0.37 + 0.11) * br.period / 1000) + 's';
  };

  // 동료 카드 연출. to: 대상 위치(화면 좌표). 반환 { hit: 타격 순간에 끝나는 Promise, done: 다 끝나면 }
  M.strike = function (id, pose, to) {
    var el = V().els.allies[id], m = D().motion;
    if (!el || V().vm.status[id] !== 'ok') return { hit: done(), done: done() };
    M.log.push(id + ':' + pose);
    var act = el.querySelector('.act[data-pose="' + pose + '"]'), body = el.querySelector('.body');
    var L = m.lunge[id] || { toward: 0.1, max: 60, dy: -40, scale: 1.05 };
    var red = FX().reduced ? 0.3 : 1;
    var a = V().allyAnchor(id);
    var dx = Math.max(-L.max, Math.min(L.max, ((to ? to.x : a.x) - a.x) * L.toward)) * red, dy = L.dy * red, sc = 1 + (L.scale - 1) * red;
    var cr = m.crouch * red;
    var w = m.windup, b = m.blend, s = m.strike, hs = m.hitstop, rc = m.recover, T = w + b + s + hs + rc;
    function o(t) { return t / T; }
    el.getAnimations().forEach(function (an) { if (an.id === 'strike') an.cancel(); });
    var main = el.animate([
      { transform: 'translate(0px,0px) scale(1)', easing: 'cubic-bezier(.3,0,.4,1)' },
      { transform: 'translate(0px,' + cr + 'px) scale(.985)', offset: o(w), easing: 'linear' },
      { transform: 'translate(' + (-dx * 0.05) + 'px,' + (cr * 1.2) + 'px) scale(.98)', offset: o(w + b), easing: 'cubic-bezier(.55,0,.9,.45)' },
      { transform: 'translate(' + dx + 'px,' + dy + 'px) scale(' + sc + ')', offset: o(w + b + s), easing: 'linear' },
      { transform: 'translate(' + dx + 'px,' + dy + 'px) scale(' + sc + ')', offset: o(w + b + s + hs), easing: 'cubic-bezier(.2,.7,.3,1)' },
      { transform: 'translate(' + (-dx * 0.06) + 'px,' + (cr * 0.5) + 'px) scale(.995)', offset: o(w + b + s + hs + rc * 0.6), easing: 'ease-in-out' },
      { transform: 'translate(0px,0px) scale(1)' }
    ], { duration: FX().ms(T) });
    main.id = 'strike';
    // 기본 자세 ↔ 행동 자세 녹이기
    if (act && body) {
      act.animate([
        { opacity: 0 }, { opacity: 0, offset: o(w) }, { opacity: 1, offset: o(w + b) },
        { opacity: 1, offset: o(w + b + s + hs + rc * 0.35) }, { opacity: 0 }
      ], { duration: FX().ms(T) });
      body.animate([
        { opacity: 1 }, { opacity: 1, offset: o(w) }, { opacity: 0, offset: o(w + b) },
        { opacity: 0, offset: o(w + b + s + hs + rc * 0.35) }, { opacity: 1 }
      ], { duration: FX().ms(T) });
      // 잔상: 타격이 시작되는 자리에 행동 자세가 남아 흐려진다
      setTimeout(function () { afterimage(el, act, 0); }, FX().ms(w + b));
      setTimeout(function () { afterimage(el, act, 0.5); }, FX().ms(w + b + s * 0.5));
    }
    var hit = FX().wait(w + b + s);
    hit.then(function () { if (!FX().reduced) FX().shake(5, 160); });
    return { hit: hit, done: FX().wait(T) };
  };
  function afterimage(el, act, k) {
    var img = act.querySelector('img');
    if (!img) return;
    var stage = document.getElementById('stage').getBoundingClientRect(), s = stage.width / 1920;
    var ghost = img.cloneNode();
    ghost.className = 'afterimage';
    var ar = act.getBoundingClientRect();
    ghost.style.left = (ar.left - stage.left) / s + 'px'; ghost.style.top = (ar.top - stage.top) / s + 'px';
    ghost.style.width = ar.width / s + 'px'; ghost.style.height = ar.height / s + 'px';
    document.getElementById('allyLayer').appendChild(ghost);
    FX().anim(ghost, [{ opacity: 0.45 - k * 0.2 }, { opacity: 0 }], { duration: 260, easing: 'ease-out' }).then(function () { ghost.remove(); });
  }

  // 맞은 동료가 흔들린다(앞으로 밀렸다가 좌우로 떨림)
  M.hurt = function (id) {
    var el = V().els.allies[id], h = D().motion.hurt;
    if (!el) return done();
    var p = h.power * (FX().reduced ? 0.3 : 1), fr = [], n = 7;
    fr.push({ transform: 'translate(0px,0px)' });
    for (var i = 0; i < n; i++) {
      var k = 1 - i / n;
      fr.push({ transform: 'translate(' + ((i % 2 ? -1 : 1) * p * k).toFixed(1) + 'px,' + (p * 0.6 * k).toFixed(1) + 'px)' });
    }
    fr.push({ transform: 'translate(0px,0px)' });
    return FX().anim(el, fr, { duration: h.dur, easing: 'ease-out' });
  };

  // 적의 공격: 몸을 젖힘 → 달려듦(화면 앞쪽으로 커지며) → 제자리. 반환 { hit, done }
  M.enemyLunge = function (el) {
    var m = D().motion.enemy;
    if (!el) return { hit: done(), done: done() };
    var red = FX().reduced ? 0.3 : 1, T = m.windup + m.rush + m.back;
    function o(t) { return t / T; }
    el.animate([
      { transform: 'translateY(0px) scale(1)', easing: 'ease-out' },
      { transform: 'translateY(' + (-8 * red) + 'px) scale(' + (1 - 0.03 * red) + ')', offset: o(m.windup), easing: 'cubic-bezier(.5,0,.9,.5)' },
      { transform: 'translateY(' + (m.dy * red) + 'px) scale(' + (1 + (m.scale - 1) * red) + ')', offset: o(m.windup + m.rush), easing: 'cubic-bezier(.2,.7,.3,1)' },
      { transform: 'translateY(0px) scale(1)' }
    ], { duration: FX().ms(T) });
    return { hit: FX().wait(m.windup + m.rush), done: FX().wait(T) };
  };
})(window);
