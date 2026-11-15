/*
 * cardart.js — 카드 안쪽 그림(코드로 그린 SVG). 일러스트가 생기면 교체할 자리.
 * 크기 212×184 (카드의 그림 창)
 */
(function (root) {
  'use strict';
  var Game = root.Game = root.Game || {};
  var ART = Game.CardArt = {};

  var BG = {
    witch: ['#3a1838', '#0d060d'], hero: ['#3a4256', '#0b0d13'], warrior: ['#4a3626', '#100b07'],
    archer: ['#2a4a2c', '#081009'], death: ['#2a0006', '#000000'], inherit: ['#5a0610', '#0a0000'],
    relic: ['#4a4a4a', '#0c0c0c'], wound: ['#3a0a10', '#080203']
  };
  function wrap(key, tone, body) {
    var c = BG[tone] || BG.witch, id = 'bg-' + tone;
    return '<svg viewBox="0 0 212 184" xmlns="http://www.w3.org/2000/svg">' +
      '<defs><radialGradient id="' + id + '" cx="50%" cy="42%" r="75%"><stop offset="0" stop-color="' + c[0] + '"/><stop offset="1" stop-color="' + c[1] + '"/></radialGradient>' +
      '<linearGradient id="gSteel" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7d8596"/><stop offset=".5" stop-color="#eef2fa"/><stop offset="1" stop-color="#6b7384"/></linearGradient>' +
      '<linearGradient id="gFlame" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#ff3a1e"/><stop offset=".6" stop-color="#ff9a2a"/><stop offset="1" stop-color="#ffe08a"/></linearGradient>' +
      '<linearGradient id="gIron" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#5b5f68"/><stop offset="1" stop-color="#23262c"/></linearGradient>' +
      '<radialGradient id="gGlow" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="#fff" stop-opacity=".8"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></radialGradient>' +
      '</defs><rect width="212" height="184" fill="url(#' + id + ')"/>' + body + '</svg>';
  }

  var E = {
    flame: function () {
      return '<ellipse cx="106" cy="150" rx="60" ry="14" fill="#ff5a2a" opacity=".25"/>' +
        '<path d="M106 26 C126 62 154 80 150 118 C147 148 128 166 106 166 C82 166 62 149 62 121 C62 96 82 86 86 62 C95 78 99 88 106 92 C110 70 102 50 106 26Z" fill="url(#gFlame)"/>' +
        '<path d="M106 92 C121 112 129 126 125 143 C121 157 113 162 106 162 C95 162 87 153 87 141 C87 126 100 118 106 92Z" fill="#fff0b0" opacity=".85"/>' +
        '<circle cx="98" cy="140" r="4" fill="#3a0010"/><circle cx="114" cy="140" r="4" fill="#3a0010"/>';
    },
    fate: function () {
      return '<g fill="#d9cfd8" opacity=".85"><circle cx="54" cy="70" r="13"/><path d="M36 128 Q54 86 72 128Z"/><circle cx="158" cy="70" r="13"/><path d="M140 128 Q158 86 176 128Z"/></g>' +
        '<path d="M54 52 C70 8 142 8 158 48" stroke="#ff2a3c" stroke-width="5" fill="none" stroke-linecap="round"/>' +
        '<path d="M150 40 L160 52 L146 54" stroke="#ff2a3c" stroke-width="5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>' +
        '<path d="M30 150 C70 132 140 170 182 146" stroke="#b3121f" stroke-width="2.5" fill="none" stroke-dasharray="6 6"/>';
    },
    hand: function () {
      return '<path d="M66 172 L66 112 C66 104 76 102 78 110 L80 128 L80 78 C80 70 92 70 92 78 L94 120 L96 66 C96 58 108 58 108 66 L110 120 L112 72 C112 64 124 64 124 72 L126 124 L132 104 C135 96 147 98 145 108 L136 150 C132 166 122 174 108 174Z" fill="#e8d6d2" stroke="#7a5a58" stroke-width="2"/>' +
        '<path d="M106 20 L106 74" stroke="#ff2a3c" stroke-width="6" stroke-linecap="round"/><path d="M92 60 L106 80 L120 60" stroke="#ff2a3c" stroke-width="6" fill="none" stroke-linecap="round" stroke-linejoin="round"/>' +
        '<circle cx="110" cy="128" r="9" fill="#b3121f"/>';
    },
    eye: function () {
      return '<path d="M20 92 Q106 20 192 92 Q106 164 20 92Z" fill="#eae0dc" stroke="#2a0a10" stroke-width="4"/>' +
        '<circle cx="106" cy="92" r="34" fill="#a3101f"/><circle cx="106" cy="92" r="34" fill="none" stroke="#ff6070" stroke-width="2"/>' +
        '<ellipse cx="106" cy="92" rx="8" ry="24" fill="#080003"/><circle cx="96" cy="80" r="6" fill="#fff" opacity=".8"/>' +
        '<path d="M106 126 C104 140 100 150 106 172 C112 150 108 140 106 126Z" fill="#b3121f"/>' +
        '<g stroke="#2a0a10" stroke-width="3"><path d="M50 58 L40 42"/><path d="M80 44 L74 26"/><path d="M132 44 L138 26"/><path d="M162 58 L172 42"/></g>';
    },
    sword: function () {
      return '<circle cx="106" cy="92" r="70" fill="url(#gGlow)" opacity=".35"/>' +
        '<path d="M100 18 L112 18 L114 128 L98 128Z" fill="url(#gSteel)"/><path d="M106 14 L112 22 L100 22Z" fill="#eef2fa"/>' +
        '<path d="M106 22 L106 126" stroke="#bfe6ff" stroke-width="1.5" opacity=".9"/>' +
        '<rect x="70" y="126" width="72" height="10" rx="4" fill="#d9dde6" stroke="#8a8f9c"/><rect x="101" y="136" width="10" height="28" fill="#5a3a2a"/>' +
        '<circle cx="106" cy="170" r="8" fill="#b3121f" stroke="#d9dde6" stroke-width="2"/>' +
        '<path d="M28 150 Q90 40 190 30" stroke="#fff" stroke-width="3" fill="none" opacity=".55"/>';
    },
    charge: function () {
      return '<path d="M40 150 L150 40" stroke="url(#gSteel)" stroke-width="12" stroke-linecap="round"/><path d="M150 40 L170 22 L160 50Z" fill="#eef2fa"/>' +
        '<path d="M52 128 L74 150" stroke="#d9dde6" stroke-width="8" stroke-linecap="round"/>' +
        '<path d="M60 40 L60 110 L100 96 L60 82" fill="#b3121f" opacity=".9"/><path d="M60 30 L60 120" stroke="#5a3a2a" stroke-width="4"/>' +
        '<g stroke="#fff" stroke-width="3" opacity=".5" stroke-linecap="round"><path d="M120 120 L190 120"/><path d="M130 140 L196 140"/><path d="M110 100 L180 100"/></g>';
    },
    shield: function () {
      return '<path d="M56 26 L156 26 L156 120 Q156 160 106 176 Q56 160 56 120Z" fill="url(#gIron)" stroke="#9aa0ab" stroke-width="4"/>' +
        '<path d="M106 40 L106 150 M78 78 L134 78" stroke="#c9a24a" stroke-width="10" stroke-linecap="round"/>' +
        '<g stroke="#120c0a" stroke-width="3" opacity=".7"><path d="M70 50 L84 70"/><path d="M140 100 L128 124"/><path d="M76 120 L88 140"/></g>' +
        '<path d="M56 26 L156 26" stroke="#b3121f" stroke-width="4"/>';
    },
    bash: function () {
      return '<g transform="rotate(-18 96 100)"><path d="M46 36 L136 36 L136 122 Q136 156 91 170 Q46 156 46 122Z" fill="url(#gIron)" stroke="#9aa0ab" stroke-width="4"/>' +
        '<path d="M91 50 L91 150 M66 84 L116 84" stroke="#c9a24a" stroke-width="9" stroke-linecap="round"/></g>' +
        '<g stroke="#ffd36b" stroke-width="5" stroke-linecap="round"><path d="M158 60 L190 44"/><path d="M164 92 L200 92"/><path d="M158 124 L190 140"/></g>' +
        '<circle cx="150" cy="92" r="14" fill="#ffd36b" opacity=".6"/>';
    },
    arrow: function () {
      return '<g fill="none" stroke="#ff4a5a" stroke-width="3" opacity=".75"><circle cx="150" cy="58" r="34"/><circle cx="150" cy="58" r="20"/></g><circle cx="150" cy="58" r="7" fill="#ff4a5a"/>' +
        '<path d="M28 166 L146 62" stroke="#c8a070" stroke-width="5" stroke-linecap="round"/><path d="M146 62 L134 64 L144 52Z" fill="#e0e6ee" stroke="#e0e6ee" stroke-width="5" stroke-linejoin="round"/>' +
        '<path d="M28 166 L22 150 M28 166 L44 170 M36 158 L30 142 M36 158 L52 162" stroke="#f4f4f4" stroke-width="4" stroke-linecap="round"/>';
    },
    arrows: function () {
      return '<path d="M20 140 L150 50" stroke="#c8a070" stroke-width="4" stroke-linecap="round"/><path d="M150 50 L140 50 L148 40Z" fill="#e0e6ee" stroke="#e0e6ee" stroke-width="4" stroke-linejoin="round"/>' +
        '<path d="M40 170 L170 80" stroke="#c8a070" stroke-width="4" stroke-linecap="round"/><path d="M170 80 L160 80 L168 70Z" fill="#e0e6ee" stroke="#e0e6ee" stroke-width="4" stroke-linejoin="round"/>' +
        '<path d="M176 24 L176 64 M162 50 L176 66 L190 50" stroke="#9be59b" stroke-width="6" fill="none" stroke-linecap="round" stroke-linejoin="round"/>';
    },
    brokensword: function () {
      return '<path d="M98 112 L114 112 L112 70 L104 62 L100 76Z" fill="url(#gSteel)"/>' +
        '<path d="M120 20 L132 24 L118 60 L110 54Z" fill="url(#gSteel)" transform="rotate(16 120 40)"/>' +
        '<rect x="70" y="110" width="72" height="10" rx="4" fill="#cfcfcf" stroke="#888"/><rect x="101" y="120" width="10" height="28" fill="#555"/>' +
        '<circle cx="106" cy="154" r="8" fill="#888" stroke="#ddd" stroke-width="2"/>' +
        '<g fill="#999"><circle cx="70" cy="168" r="3"/><circle cx="140" cy="164" r="2"/><circle cx="160" cy="170" r="3"/></g>';
    },
    lastcharge: function () {
      return '<path d="M60 20 L60 172" stroke="#666" stroke-width="5"/><path d="M60 28 L150 40 L128 62 L156 80 L60 92Z" fill="#9a9a9a" opacity=".9"/>' +
        '<path d="M120 44 L118 60 M136 70 L130 80" stroke="#333" stroke-width="3"/>' +
        '<path d="M88 170 L170 110" stroke="url(#gSteel)" stroke-width="9" stroke-linecap="round"/><path d="M170 110 L184 100" stroke="#bbb" stroke-width="4" stroke-dasharray="4 5"/>';
    },
    foot: function () {
      return '<g opacity=".35" stroke="#ff2a3c" stroke-width="2" fill="none"><path d="M20 170 L60 130 L50 100"/><path d="M190 168 L160 128 L176 96"/><path d="M106 182 L110 150"/></g>' +
        '<path d="M76 74 C70 104 72 146 102 166 C128 180 150 160 148 126 C146 100 140 84 140 70 C140 56 80 52 76 74Z" fill="#6a0610" stroke="#ff3346" stroke-width="2"/>' +
        '<ellipse cx="80" cy="50" rx="12" ry="14" fill="#6a0610" stroke="#ff3346" stroke-width="2"/><ellipse cx="102" cy="38" rx="11" ry="13" fill="#6a0610" stroke="#ff3346" stroke-width="2"/>' +
        '<ellipse cx="122" cy="38" rx="10" ry="12" fill="#6a0610" stroke="#ff3346" stroke-width="2"/><ellipse cx="139" cy="46" rx="9" ry="11" fill="#6a0610" stroke="#ff3346" stroke-width="2"/>' +
        '<ellipse cx="152" cy="60" rx="8" ry="9" fill="#6a0610" stroke="#ff3346" stroke-width="2"/>';
    },
    wound: function () {
      return '<g stroke="#b3121f" stroke-linecap="round"><path d="M50 40 Q90 90 70 150" stroke-width="9"/><path d="M100 30 Q130 90 108 160" stroke-width="11"/><path d="M150 44 Q170 96 150 146" stroke-width="7"/></g>' +
        '<g fill="#7a0010"><circle cx="72" cy="160" r="5"/><circle cx="110" cy="170" r="6"/><circle cx="150" cy="156" r="4"/></g>';
    },
    deathface: function () {
      // 얼굴 그림은 카드 위에 따로 얹고(stand_hero.png), 여기서는 금·실만
      return '<path d="M0 30 L60 70 L92 60 L130 110 L212 120" stroke="#ff2a3c" stroke-width="2" fill="none" opacity=".9"/>' +
        '<path d="M150 0 L138 50 L160 92 L144 184" stroke="#000" stroke-width="3" fill="none" opacity=".8"/>';
    }
  };

  ART.svg = function (artKey, tone) {
    var f = E[artKey] || E.eye;
    return wrap(artKey, tone, f());
  };
  ART.hasFace = function (artKey) { return artKey === 'deathface'; };
})(window);
