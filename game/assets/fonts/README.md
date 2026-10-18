# 폰트

- `Galmuri11.ttf` — 갈무리11 (Galmuri) v2.40.4, © 2019–2025 Lee Minseo, SIL Open Font License 1.1 (`Galmuri-OFL.md`)
  - 출처: https://github.com/quiple/galmuri
  - 웹 빌드 용량을 줄이려고 한글 완성형(가~힣), 한글 자모, 기본 라틴 문자, 일부 기호만 남긴 부분 집합(subset)이다. 글자는 수정하지 않았다.
- `Galmuri14.ttf`(15px 설계) · `Galmuri9.ttf`(10px 설계) · `Galmuri7.ttf`(8px 설계) — 같은 갈무리 v2.40.3 (npm `galmuri` 패키지 `dist/`), 같은 OFL 1.1
  - 턴제 전투 화면용(`game/proto/turn/t_theme.gd`). 갈무리는 크기마다 다른 글꼴이라 설계 크기로만 그린다(안티에일리어싱 꺼짐).
  - Galmuri14·9: KS X 1001 한글 2,350자 + Galmuri11과 같은 자모·라틴·기호 + `−×ⅠⅡⅢ①~⑤◆◇` 부분 집합. 없는 글자는 Galmuri11로 대신 그린다(`TTheme`이 fallback을 건다).
  - Galmuri7: 기본 라틴(숫자·영문·기호) + `−×◆◇·…` 만 (아이콘 위 숫자 전용).
  - 만든 법: `pyftsubset GalmuriN.ttf --unicodes-file=목록 --output-file=GalmuriN.ttf` (fontTools 4.66). 글자 모양은 고치지 않았다.
