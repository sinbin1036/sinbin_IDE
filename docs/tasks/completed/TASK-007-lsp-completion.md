# TASK-007: Phase 4 LSP / Completion

- **Status:** Completed (2026-10-02)
- **Goal:** 사용자가 주로 쓰는 5개 언어(TypeScript, Python, Java, Dart/Flutter, C)에서 LSP 기반 자동완성·정의 이동·이름 변경·포맷을 쓸 수 있게 한다.

## Background
PROGRESS Next Action. 범위는 사용자와 확정 (2026-10-02).
RULES Plugin 원칙에 따라 Neovim 0.12 내장 LSP(`vim.lsp.config` / `vim.lsp.enable`)를 기반으로 하고, 내장으로 부족한 부분만 Plugin으로 보완한다.

### 환경 (2026-10-02 확인)

| 언어 | Toolchain | LSP Server | 상태 |
|---|---|---|---|
| TypeScript | node 22.19.0, npm | `vtsls` | 미설치 |
| Python | python 3.13.3, pip | `basedpyright` + `ruff` | 미설치 |
| Java | Java 27, Maven 3.9.16 | `jdtls` | 미설치 |
| Dart/Flutter | Dart 3.10.4 (`C:\flutter`) | `dart language-server` (SDK 포함) | 설치됨 |
| C | gcc 14.2.0 (MSYS2) | `clangd` | 미설치 |

## Scope

| 항목 | 방식 | 이유 |
|---|---|---|
| LSP Client | Neovim 내장 `vim.lsp.config` / `vim.lsp.enable` | 내장 기능 |
| Server 설정 데이터 | `neovim/nvim-lspconfig` (`lsp/*.lua` 설정만 사용) | cmd·root marker·jdtls 설정을 직접 작성하지 않기 위함 |
| Server 설치 | `mason-org/mason.nvim` | OS 공통 설치 방식 (Phase 12/13 대비) |
| 자동완성 | `mini.completion` (snippet은 내장 `vim.snippet`, `mini.snippets` 미사용) | D-008/D-009 mini 계열 일관, 문서 창·signature help 제공 |
| Keymap | 내장 기본값(`K`, `grn`, `gra`, `grr`, `gri`, `gO`, Insert `<C-s>`) + `gd` 정의 이동, 포맷 Keymap | 내장 우선 |
| 포맷 | LSP formatting (`vim.lsp.buf.format`) | 외부 Formatter Plugin 없이 시작 |

### 언어별 진행 순서
1. 공통 구조 + Dart (설치 불필요 → 구조 검증)
2. TypeScript (`vtsls`), Python (`basedpyright` + `ruff`)
3. C (`clangd`)
4. Java (`jdtls`, 가장 무거움)

## Out of Scope
- Diagnostic UI·목록 (Phase 5). 내장 기본 표시만 사용
- Treesitter 구문 강조 → 별도 Task (TASK-008). `tree-sitter` CLI 미설치
- 외부 Formatter (prettier, clang-format 단독 등) → 필요 시 별도 Task
- Flutter 실행·hot reload, Debug (Phase 8/9)
- Server 설치 자동화 (Phase 13)

## Prerequisites
- TASK-004 (`vim.pack`), TASK-006 (`plugins/` 구조, D-009)

## Decisions (2026-10-02 사용자 확인)
1. **Server 설치:** mason.nvim
2. **자동완성:** mini.completion
3. **TypeScript:** vtsls
4. **Python:** basedpyright + ruff
5. **Treesitter:** 별도 Task로 분리

## Steps
1. Plugin 추가 (`nvim-lspconfig`, `mason.nvim`, `mini.completion`) 및 `plugins/lsp.lua` 구성
2. Dart LSP 연결 → 검증
3. TypeScript, Python → 검증
4. C → 검증
5. Java → 검증
6. Keymap 충돌 확인
7. 문서 갱신: USAGE, ARCHITECTURE, DECISIONS(D-010), VERIFICATION Environment, PROGRESS

## Acceptance Criteria
- Startup 에러 없음, checkhealth ERROR 0 (`vim.lsp` 섹션 포함)
- 5개 언어 각각 샘플 파일에서 LSP attach, 자동완성, hover, 정의 이동 동작
- Keymap 충돌은 의도한 것만 존재
- Plugin은 Scope에 명시된 것만 추가, lock 파일 git 반영
- USAGE에 LSP 조작법, Server 설치 방법 반영

## Verification
[VERIFICATION.md](../../VERIFICATION.md) — Lua Config, Keymap, Plugin 추가/제거, LSP 항목

## Related Files
`lua/sinbin/plugins/init.lua`, `lua/sinbin/plugins/lsp.lua`(신규), `nvim-pack-lock.json`,
`docs/USAGE.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, `docs/VERIFICATION.md`

## Result
- `plugins/init.lua`: nvim-lspconfig, mason.nvim, mini.completion 추가 (총 14개), lsp 모듈 로드
- `plugins/lsp.lua`(신규): Mason setup, mini.completion + `MiniIcons.tweak_lsp_kind()`, 공통 capabilities, `vim.lsp.enable` 6개 Server, Insert `<Tab>`/`<S-Tab>`/`<CR>`, LspAttach에서 `gd`, `<Leader>cf`, ruff hover 비활성
- `plugins/ui.lua`: mini.clue `<Leader>c` +Code 그룹
- `plugins/ui.lua`: mini.notify `lsp_progress` 비활성 (사용자 요청: LSP 진행 알림이 계속 떠서 방해됨, 일반 알림은 유지)
- `platform/windows.lua`: dartls `cmd`를 `dart.bat`로 지정
- Mason 설치: vtsls, basedpyright, ruff, clangd, jdtls
- 문서: USAGE, ARCHITECTURE, DECISIONS(D-010), VERIFICATION

## Verification Result (2026-10-02, Windows 11 / Neovim 0.12.5, headless)
샘플 프로젝트(root marker 포함)를 임시 디렉터리에 만들고 `client:request_sync`로 확인.

| 언어 | Client | definition | hover | completion |
|---|---|---|---|---|
| Dart | dartls | OK | OK | 221 |
| TypeScript | vtsls | OK | OK | 20 (`console.`) |
| Python | basedpyright + ruff | OK | OK | 457 |
| C | clangd | OK | OK | 88 |
| Java (Maven) | jdtls | OK | OK | 44 (`System.out.`) |

- `nvim --headless "+qa"` 출력 없음, exit 0. checkhealth(`vim.lsp`, `vim.pack`, `mason`) ERROR 0. WARNING은 Mason 선택 도구(wget, 7z, cargo 등) 미설치, clangd `c.doxygen` filetype 안내
- 포맷: Python `def  f( a,b ):` → `def f(a, b):` (ruff, `vim.lsp.buf.format`)
- Keymap: Insert `<Tab>`/`<S-Tab>`/`<CR>`는 의도한 덮어쓰기(내장 Tab, mini.pairs `<CR>`). 괄호 안 `<CR>`은 `MiniPairs.cr()` fallback으로 기존 동작 유지 확인
- 화면 확인 (사용자, 2026-10-02): 자동완성 popup·문서 창·인자 힌트, `gd`/`K`, 알림 설정 변경 후 동작

## Notes
- Windows: Flutter SDK의 확장자 없는 `dart` 스크립트를 exepath가 먼저 찾아 spawn 실패(ENOENT, 로그 없음) → Platform Layer에서 `dart.bat` 지정
- Mason Server는 `nvim-pack-lock.json` 밖이라 버전 고정 안 됨 (Phase 13 설치 자동화 대상)
