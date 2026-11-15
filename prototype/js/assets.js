/*
 * assets.js — 그림 불러오기. 파일이 없으면 같은 자리에 회색 박스 + 파일명.
 * 그림 파일을 assets/에 넣고 새로고침하면 바로 바뀐다(목록은 data.js의 assets).
 */
(function (root) {
  'use strict';
  var Game = root.Game = root.Game || {};
  var A = Game.Assets = { status: {} };

  A.url = function (name) {
    if (name.indexOf('/') >= 0) return name;          // 상대 경로(예: ../reference/...)는 그대로
    return Game.DATA.assetDir + name;
  };

  function probe(name) {
    return new Promise(function (resolve) {
      var img = new Image();
      var done = false;
      function fin(ok) {
        if (done) return; done = true;
        A.status[name] = { ok: ok, w: ok ? img.naturalWidth : 0, h: ok ? img.naturalHeight : 0, src: A.url(name) };
        resolve();
      }
      img.onload = function () { fin(true); };
      img.onerror = function () { fin(false); };
      setTimeout(function () { fin(false); }, 8000);
      img.src = A.url(name);
    });
  }

  // 목록의 그림을 모두 확인한다. 컷신 대체 그림(fallback)도 함께 확인.
  A.load = function () {
    var D = Game.DATA, list = D.assets.slice();
    (D.cutscene.cuts || []).forEach(function (c) { if (c.fallback && list.indexOf(c.fallback) < 0) list.push(c.fallback); });
    return Promise.all(list.map(probe));
  };

  A.ok = function (name) { return !!(A.status[name] && A.status[name].ok); };
  A.size = function (name) { var s = A.status[name]; return s && s.ok ? { w: s.w, h: s.h } : null; };
  // 없으면 fallback 사용
  A.pick = function (name, fallback) {
    if (A.ok(name)) return name;
    if (fallback && A.ok(fallback)) return fallback;
    return name;
  };

  // 회색 박스
  A.placeholder = function (name, w, h, cls) {
    var d = document.createElement('div');
    d.className = 'ph' + (cls ? ' ' + cls : '');
    if (w != null) d.style.width = w + 'px';
    if (h != null) d.style.height = h + 'px';
    var s = document.createElement('span');
    s.textContent = name;
    d.appendChild(s);
    d.setAttribute('data-missing', name);
    return d;
  };

  // 그림 또는 회색 박스. opts: { cls, phCls }
  A.el = function (name, w, h, opts) {
    opts = opts || {};
    if (A.ok(name)) {
      var img = document.createElement('img');
      img.src = A.url(name);
      img.draggable = false;
      img.alt = '';
      if (opts.cls) img.className = opts.cls;
      if (w != null) img.style.width = w + 'px';
      if (h != null) img.style.height = h + 'px';
      return img;
    }
    return A.placeholder(name, w, h, opts.phCls);
  };

  // 표정 이름(예: 'hero_smile') → 그림 파일 이름 (data.js expressions.file)
  A.expressionFile = function (face) {
    var E = Game.DATA.expressions;
    return face && E ? E.file.replace('{name}', face) : null;
  };
  // 얼굴을 잘라 배경으로. face(표정 이름)가 있고 그 그림이 있으면 표정 그림(data.js expressions),
  // 없으면 스탠딩 그림에서 잘라 쓴다(data.js faces). large: 캠프 대화창의 큰 얼굴
  A.applyFace = function (el, who, boxSize, zoom, face, large) {
    var E = Game.DATA.expressions, file = A.expressionFile(face), f;
    if (file && A.ok(file)) {
      var ch = face.split('_')[0], c = ((large ? E.cropLarge : E.crop) || {})[ch] || E.crop[ch];
      f = { img: file, cx: c.cx, cy: c.cy, size: c.size };
    } else f = Game.DATA.faces[who];
    if (!f) { el.style.backgroundImage = 'none'; el.removeAttribute('data-face-img'); return; }
    var sz = A.size(f.img);
    if (!sz) { el.style.backgroundImage = 'none'; el.textContent = ''; el.removeAttribute('data-face-img'); return; }
    el.setAttribute('data-face-img', f.img);
    var size = f.size / (zoom || 1);
    var k = boxSize / size;
    el.style.backgroundImage = 'url("' + A.url(f.img) + '")';
    el.style.backgroundSize = (sz.w * k) + 'px ' + (sz.h * k) + 'px';
    el.style.backgroundPosition = (-(f.cx - size / 2) * k) + 'px ' + (-(f.cy - size / 2) * k) + 'px';
  };

  A.missing = function () {
    return Object.keys(A.status).filter(function (k) { return !A.status[k].ok; });
  };
})(window);
