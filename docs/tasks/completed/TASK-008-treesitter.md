# TASK-008: Phase 4 Treesitter 구문 강조

- **Status:** Completed (2026-10-02)
- **Goal:** 주로 쓰는 5개 언어(TypeScript, Python, Java, Dart, C)와 자주 여는 설정 파일을 Treesitter 기반으로 정확하게 구문 강조한다.

## Background
TASK-007에서 분리 결정 (2026-10-02). PROGRESS Next Action.

### 현재 상태 (2026-10-02 확인)
- Neovim 0.12.5 내장 parser: `c`, `lua`, `markdown`, `markdown_inline`, `query`, `vim`, `vimdoc`뿐. TypeScript, Python, Java, Dart parser 없음
- 5개 언어 파일에서 Treesitter highlighter 비활성 (`vim.treesitter.highlighter.active` 없음). 현재 색은 Vim regex syntax + LSP semantic token
- `nvim-treesitter` `main` branch 요구사항 (README): Neovim 0.12.0+, `tree-sitter` CLI 0.26.1+ (npm 설치 불가), C compiler, `tar`, `curl`. `master` branch는 잠김(0.11 호환용). Lazy-loading 미지원. Indent는 experimental
- 이 PC: gcc 14.2.0 (MSYS2) 있음, `tar.exe` / `curl.exe` (Windows 내장) 있음, `tree-sitter` CLI 미설치 (winget `tree-sitter.tree-sitter-cli` 0.27.0 제공)

## Scope

| 항목 | 방식 |
|---|---|
| Parser 설치·관리 | `nvim-treesitter` (`main` branch) |
| `tree-sitter` CLI | winget 설치 |
| Highlight 시작 | 내장 `vim.treesitter.start()`를 FileType autocmd에서 호출 |
| Parser 목록 | 아래 Decisions 2 |

## Out of Scope
- Treesitter text object (`mini.ai`, nvim-treesitter-textobjects), context 표시 → 필요 시 별도 Task
- Parser 설치 자동화 (Phase 13)

## Prerequisites
- TASK-006 (`plugins/` 구조), TASK-007 (LSP, D-010)

## Decisions (2026-10-02 사용자 확인)
1. **방식:** `nvim-treesitter` `main` branch ([D-011](../../DECISIONS.md))
2. **Parser 목록:** `typescript`, `tsx`, `javascript`, `python`, `java`, `dart`, `json`, `yaml`, `toml`. `c`는 Neovim 내장 parser 사용
3. **Treesitter indent:** 미사용 (experimental, 내장 indent 유지)
4. **Treesitter folding:** 미사용

## Steps
1. Decisions 확인
2. `tree-sitter` CLI 설치 (winget) → 버전 확인
3. `nvim-treesitter` 추가, parser 설치, FileType autocmd로 highlight 시작
4. 언어별 highlighter 활성 확인
5. 문서 갱신: USAGE, ARCHITECTURE, DECISIONS(D-011), VERIFICATION Environment, PROGRESS

## Acceptance Criteria
- Startup 에러 없음, checkhealth ERROR 0 (`nvim-treesitter`, `vim.treesitter` 섹션)
- 대상 filetype에서 Treesitter highlighter 활성
- Parser가 없는 filetype을 열어도 에러 없음
- Plugin은 Scope에 명시된 것만 추가, lock 파일 git 반영
- 화면에서 강조 확인 (사용자)

## Verification
[VERIFICATION.md](../../VERIFICATION.md) — Lua Config, Plugin 추가/제거 항목

## Related Files
`lua/sinbin/plugins/init.lua`, `lua/sinbin/plugins/treesitter.lua`(신규), `nvim-pack-lock.json`,
`docs/USAGE.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, `docs/VERIFICATION.md`

## Result
- `tree-sitter` CLI 0.27.0 설치 (winget). User PATH 등록 확인
- `plugins/init.lua`: `nvim-treesitter` (`version = "main"`) 추가 (총 15개), treesitter 모듈 로드
- `plugins/treesitter.lua`(신규): parser 목록 `install()` (비동기, 설치된 parser는 no-op), FileType autocmd에서 parser가 있으면 `vim.treesitter.start()`, `PackChanged`(update) 시 `:TSUpdate`
- 문서: USAGE, ARCHITECTURE, DECISIONS(D-011), VERIFICATION

## Verification Result (2026-10-02, Windows 11 / Neovim 0.12.5, headless)
- parser 9개 설치 (`install():wait()`), `stdpath('data')/site/parser`에 생성
- Treesitter highlighter 활성: typescript, typescriptreact, javascript, python, java, dart, c, json, yaml, toml
- parser 없는 filetype(`sh`, 알 수 없는 확장자): 에러 없이 열림, highlighter 비활성
- `indentexpr`는 기존 filetype 값 유지, `foldmethod=manual` (indent·folding 미사용 확인)
- `nvim --headless "+qa"` 출력 없음, exit 0. checkhealth(`nvim-treesitter`, `vim.treesitter`) ERROR 0, `tree-sitter-cli 0.27.0` OK
- 화면 확인 (사용자, 2026-10-02): 샘플 프로젝트(TypeScript, TSX, Python, Java, Dart, C, JSON/YAML/TOML)에서 구문 강조 확인

## Notes
- 설치 직후 기존 Shell은 PATH 미갱신 → checkhealth가 `tree-sitter-cli not found` ERROR 표시. 새 Terminal에서는 정상
- tar/curl은 Git for Windows 것이 PATH에서 먼저 잡힘 (동작 문제 없음)
