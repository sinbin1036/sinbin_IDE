# ARCHITECTURE

현재 Architecture의 Source of Truth. 실제 존재하는 것만 Current에 기록한다.

## Current

Repository Root = Neovim config 디렉터리. Windows에서는 `%LOCALAPPDATA%\nvim` Junction으로 연결 ([D-005](DECISIONS.md)).
Neovim은 Root의 `init.lua`(및 이후 `lua/` 등 runtime 경로)만 로드하며, 문서 파일은 무시된다.

| 경로 | 책임 |
|---|---|
| `init.lua` | Neovim 진입점. 아래 모듈을 순서대로 로드 (keymaps → options → autocmds → commands → diagnostics → platform → plugins) |
| `lua/sinbin/keymaps.lua` | Leader(`<Space>`) / LocalLeader(`\`) 설정 및 Plugin과 무관한 전역 Keymap (Phase 2 편집 Keymap). Plugin 전용 Keymap은 `plugins/` 영역별 파일 |
| `lua/sinbin/options.lua` | OS 중립 기본 Option (번호, indent, search, clipboard, undo, split, 표시, 긴 줄, inccommand) |
| `lua/sinbin/autocmds.lua` | 전역 Autocmd (`sinbin` augroup 하나): Yank 하이라이트, 커서 위치 복원 |
| `lua/sinbin/commands.lua` | 사용자 명령: `:TrimWhitespace` (저장 시 자동 실행 안 함) |
| `lua/sinbin/diagnostics.lua` | 내장 `vim.diagnostic` 설정(virtual_text, 심각도 정렬, sign 아이콘, 이동 시 float)과 Plugin 무관 `<Leader>e` Keymap. Picker Keymap(`<Leader>ed`/`eD`)은 `plugins/search.lua` |
| `lua/sinbin/platform/init.lua` | Platform Layer 진입점 ([D-003](DECISIONS.md)). OS 감지(`os`, `is_wsl`) 후 해당 OS 모듈 `setup()` 호출. OS 분기는 이 디렉터리에만 존재 |
| `lua/sinbin/platform/{windows,linux,macos}.lua` | OS별 설정. `windows`: dartls `cmd`를 `dart.bat`로 지정 (TASK-007). 그 외 내용은 Phase 12 |
| `lua/sinbin/plugins/init.lua` | Plugin 목록 (`vim.pack.add()` 한 곳, [D-007](DECISIONS.md)) 후 영역별 설정 모듈을 ui → editing → search → lsp → treesitter 순으로 로드 ([D-009](DECISIONS.md)) |
| `lua/sinbin/plugins/ui.lua` | Colorscheme(tokyonight moon), mini.icons, mini.statusline, mini.notify, mini.starter, mini.clue |
| `lua/sinbin/plugins/editing.lua` | mini.pairs, mini.surround 설정·Keymap ([D-008](DECISIONS.md)) |
| `lua/sinbin/plugins/search.lua` | mini.pick, mini.extra, mini.files 설정 및 `<Leader>f`/`<Leader>s` Keymap, 진단 picker `<Leader>ed`/`<Leader>eD` |
| `lua/sinbin/plugins/lsp.lua` | mason.nvim, mini.completion 설정, `vim.lsp.enable()` Server 목록 (nvim-lspconfig 설정 사용, [D-010](DECISIONS.md)), 자동완성 Keymap, LspAttach Keymap |
| `lua/sinbin/plugins/treesitter.lua` | nvim-treesitter parser 설치 목록, FileType autocmd로 내장 `vim.treesitter.start()`, `PackChanged` 시 `:TSUpdate` ([D-011](DECISIONS.md)) |
| Treesitter Parser (Repository 밖) | `stdpath('data')/site/parser`. `c` 등 내장 parser는 Neovim 설치 경로 |
| LSP Server (Repository 밖) | Mason 설치 위치 `stdpath('data')/mason`. Dart는 Flutter SDK의 `dart language-server` |
| `nvim-pack-lock.json` | `vim.pack` lock 파일 (자동 생성, 직접 수정 금지). Plugin 설치 위치는 `stdpath('data')/site/pack/core/opt` (Repository 밖) |
| `AGENTS.md` / `CLAUDE.md` | AI Agent 작업 규약 / Claude Code 진입점 |
| `docs/` | Human Source of Truth |
| `.agent/` | 외부 Observer 관리 영역 — 이 프로젝트의 일부가 아님 |

## Planned

확정 전 방향. 구현되면 Current로 옮긴다.

- **Platform Layer 내용** — Shell, Path, Clipboard provider(SSH/WSL 등) 차이 구현 (Phase 12). 구조는 Current 참조
- **AI Agent Boundary** — Agent는 외부 CLI. Neovim은 Terminal/Panel로 실행·결과 확인만 담당 ([D-002](DECISIONS.md))
- **Run/Test Layer** — 프로젝트 종류 감지 → 실행 명령 매핑
