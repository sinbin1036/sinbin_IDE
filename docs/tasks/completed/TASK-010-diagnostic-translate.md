# TASK-010: 진단 메시지 혼합 번역 (영어 용어 + 한국어 문장)

- **Status:** Completed (2026-10-02)
- **Goal:** 자주 나오는 진단 메시지를 "쉬운 용어는 영어, 어려운 말은 한국어, 짧은 끝맺음" 스타일로 바꿔 보여 주고, 메시지 창에는 영어 원문을 함께 보여 준다.

## Background
TASK-009 Notes. 언어 서버의 한국어 번역은 vtsls·basedpyright만 지원하고 전체 번역이라, 사용자는 스타크래프트 리마스터식 혼합 표기를 원함 (2026-10-02).
→ 모든 서버에서 영어 원문을 받아 Neovim 표시 단계에서 패턴으로 바꾼다. 외부 서비스·AI 번역 없음.

## Decisions (2026-10-02 사용자 확인)
1. **용어 스타일:** 쉬운 단어는 영어 그대로, 어려운 말은 한국어
   - 예: `'string' type을 'number' type에 할당할 수 없음`
2. **끝맺음:** `~할 수 없음`, `~없음`, `~안 됨` (짧게)
3. **표시 위치:** 줄 끝(`virtual_text`)은 번역만, 메시지 창(`]d`, `<Space>ee`)은 번역 + 영어 원문
4. **초기 범위:** 언어별 자주 나오는 메시지 10~15개 (타입 불일치, 이름 찾을 수 없음, 미사용 변수, 인자 개수 등)

### 용어표 (초안)

| 영어 유지 | 한국어 |
|---|---|
| type, name, module, import, class, method, function, property, attribute, member, variable, parameter, argument, value, return, constant, final, private, null, undefined, file, header, URI | assign → 할당, declare → 선언, define → 정의, convert → 변환, access → 접근, call → 호출, resolve(찾다) → 찾을 수 없음, missing → 누락, unused → 사용 안 됨, required/expected → 필요, duplicate → 중복, syntax error → 문법 오류 |

- 조사 오류를 피하기 위해 이름 뒤에 고정 명사를 붙인다 (예: `'x' variable을`, `'f'에`).

## 설계
- 데이터를 바꾸지 않고 **표시 단계에서만** 변환: `vim.diagnostic.config()`의 `virtual_text.format`, `float.format`
- picker(`<Space>ed`)·quickfix(`<Space>eq`)는 영어 원문 그대로 (검색용)
- 첫 줄만 번역 (Dart의 `Try ...` 같은 둘째 줄 힌트는 메시지 창의 원문으로 확인)
- 규칙에 없는 메시지는 영어 원문 그대로

| 파일 | 역할 |
|---|---|
| `lua/sinbin/diagnostics/init.lua` | 기존 `diagnostics.lua` 이동, format 연결 |
| `lua/sinbin/diagnostics/translate.lua` | 번역 함수 (첫 줄 매칭, 첫 규칙 적용) |
| `lua/sinbin/diagnostics/rules_ko.lua` | 언어별 패턴 목록 (Lua pattern → 치환문) |

## 실제 수집한 메시지 (2026-10-02, 의도적으로 에러를 넣은 샘플)
TypeScript(vtsls) 21개, Python(basedpyright + ruff) 30개, Dart 17개, C(clangd) 10개, Java(jdtls) 11개.
규칙은 이 실제 원문을 기준으로 작성한다. 수집 못 한 메시지(Java 미사용 변수 등)는 추가 샘플로 확인 후 넣는다.

## Out of Scope
- picker·quickfix 목록 번역
- 서버 자체 locale 설정 (vtsls `typescript.locale`, basedpyright `LC_ALL`)
- 자동/AI 번역

## Steps
1. `diagnostics.lua` → `diagnostics/` 디렉터리로 이동, translate·rules 모듈 추가
2. 규칙 작성 (언어별 10~15개)
3. 수집한 원문 전체에 규칙을 돌려 매칭률·결과 확인
4. 실제 LSP 화면 경로(virtual_text / float)에서 확인
5. 문서 갱신: USAGE(규칙 추가 방법), ARCHITECTURE, PROGRESS

## Acceptance Criteria
- Startup 에러 없음
- 수집한 원문 중 규칙 대상 메시지가 번역되고, 나머지는 원문 그대로
- 줄 끝은 번역만, 메시지 창은 번역 + 원문
- 규칙 추가 방법이 USAGE에 있음

## Related Files
`lua/sinbin/diagnostics.lua` → `lua/sinbin/diagnostics/{init,translate,rules_ko}.lua`, `docs/USAGE.md`, `docs/ARCHITECTURE.md`

## Result
- `lua/sinbin/diagnostics.lua` → `lua/sinbin/diagnostics/init.lua` (git mv), `virtual_text.format`(번역만), `float.format`(번역 + 원문)
- `lua/sinbin/diagnostics/translate.lua`(신규): 첫 줄만 매칭, 첫 규칙 적용, clangd `(fix available)` → `(fix 가능)`
- `lua/sinbin/diagnostics/rules_ko.lua`(신규): 73개 규칙 (TypeScript 16, Python basedpyright 14 + ruff 6, Java 10, Dart 13, C 14)
- 문서: USAGE(혼합 번역, 규칙 추가 방법), ARCHITECTURE, DECISIONS(D-012)

## Verification Result (2026-10-02, Windows 11 / Neovim 0.12.5, headless)
- 실제 수집 메시지 104개(2회 수집, TypeScript 27, Python 30, Dart 21, C 14, Java 13) 전부 규칙 매칭
- TypeScript 에러 샘플 화면 경로:
  - virtual_text: `● 'string' type을 'number' type에 할당할 수 없음`
  - float(`]d`): 번역 줄 + `Type 'string' is not assignable to type 'number'. [2322]`
  - quickfix: 영어 원문 유지
- `nvim --headless "+qa"` 출력 없음, exit 0
- 화면 확인 (사용자, 2026-10-02): 번역 표현 및 메시지 창 원문 병기, 표현 개정 2회 반영 후 승인

## 표현 개정 (2026-10-02, 사용자 피드백)
- 기준: 핵심 용어 영어 유지, 설명성 표현 한국어, 짧은 끝맺음, 원문 대응 유지, 원문에 없는 정보 추가 금지, 이름 뒤 고정 명사
- 같은 상황 같은 표현으로 통일: 찾을 수 없음 / 정의 안 됨 / 없음 / 사용 안 됨 / 할당할 수 없음 / 변환할 수 없음 / 필요 / 누락
- 순서 통일: `'이름' 명사 + 서술` (예: `'b' local variable 사용 안 됨`), 소속은 앞에 (`'P' type에 'x' property 없음`)
- 수정: deprecated `%1+` → `%1부터` (capture 오류는 아니었고 원문에 없는 `+` 제거), Java `(으)로` 제거, property 누락·function return 문구 단축 등
- capture 정적 검사 스크립트로 73개 규칙 전부 확인: 개정 전 문제 1건(C const rule의 capture 2 미사용) → 수정 후 0건. 실제 메시지 104개 재확인 전부 매칭

- 2차 개정 (Codex 제안 검토 후 일부만 반영): `Undefined name` / `is not defined` → `name 정의 안 됨`, clangd `Call to undeclared function` → `'x' function 선언 안 됨`, 상단 영어 용어 목록에 attribute·member·field·module 추가. 미반영: TypeScript `is declared but ...`에 `variable` 추가(실제 9건 중 5건이 function·class·import라 오역), C 초기화의 `'int'을`(조사 직결), Dart `expected by 'X'`의 `function` 단정, 상태 → 권고형 변경. 재검사: capture 문제 0, 104개 전부 매칭, 금지 패턴 0

## Notes
- Java의 미사용 local variable, final 재할당 메시지는 이번 샘플에서 jdtls가 보내지 않아 규칙에 넣지 않음 (확인한 원문만 규칙화)
- 규칙 표현 수정·추가는 쓰면서 계속 (사용자 피드백 기준)
