# ARCHITECTURE

현재 Architecture의 Source of Truth. 실제 존재하는 것만 Current에 기록한다.

## Current

Repository Root = Neovim config 디렉터리. Windows에서는 `%LOCALAPPDATA%\nvim` Junction으로 연결 ([D-005](DECISIONS.md)).
Neovim은 Root의 `init.lua`(및 이후 `lua/` 등 runtime 경로)만 로드하며, 문서 파일은 무시된다.

| 경로 | 책임 |
|---|---|
| `init.lua` | Neovim 진입점. 아래 모듈을 순서대로 로드 (keymaps → options → autocmds → commands → diagnostics → platform → plugins → terminal → run → lazygit) |
| `lua/sinbin/keymaps.lua` | Leader(`<Space>`) / LocalLeader(`\`) 설정 및 Plugin과 무관한 전역 Keymap (Phase 2 편집 Keymap). Plugin 전용 Keymap은 `plugins/` 영역별 파일 |
| `lua/sinbin/options.lua` | OS 중립 기본 Option (번호, indent, search, clipboard, undo, split, 표시, 긴 줄, inccommand) |
| `lua/sinbin/autocmds.lua` | 전역 Autocmd (`sinbin` augroup 하나): Yank 하이라이트, 커서 위치 복원, 외부 수정 반영(`checktime`) |
| `lua/sinbin/commands.lua` | 사용자 명령: `:TrimWhitespace` (저장 시 자동 실행 안 함) |
| `lua/sinbin/diagnostics/init.lua` | 내장 `vim.diagnostic` 설정(virtual_text, 심각도 정렬, sign 아이콘, 이동 시 float)과 Plugin 무관 `<Leader>e` Keymap. virtual_text·float의 `format`에서 혼합 번역 적용. Picker Keymap(`<Leader>ed`/`eD`)은 `plugins/search.lua` |
| `lua/sinbin/diagnostics/translate.lua` | 진단 메시지 첫 줄을 규칙으로 혼합 번역 (표시 전용, 진단 데이터는 변경 안 함, [D-012](DECISIONS.md)) |
| `lua/sinbin/diagnostics/rules_ko.lua` | 언어별 번역 규칙 목록 (Lua pattern → 치환문) |
| `lua/sinbin/platform/init.lua` | Platform Layer 진입점 ([D-003](DECISIONS.md)). OS 감지(`os`, `is_wsl`) 후 해당 OS 모듈 `setup()` 호출. OS 분기는 이 디렉터리에만 존재 |
| `lua/sinbin/platform/{windows,linux,macos}.lua` | OS별 설정. `windows`: dartls `cmd`를 `dart.bat`로 지정 (TASK-007), Terminal용 Shell(`platform.terminal_shell`)을 Git Bash로 지정 (TASK-012), Run 명령 실행(`platform.terminal_exec` = `bash -c`), Python 실행 파일 이름(`platform.python`) (TASK-013), 실행 파일 확장자(`exe_suffix`)·venv 폴더(`venv_bin`)·SDK의 실제 `dart.exe`(`dart_exe`)·Flutter 실행 명령(`flutter_cmd`) (TASK-014). 그 외 내용은 Phase 12 |
| `lua/sinbin/plugins/init.lua` | Plugin 목록 (`vim.pack.add()` 한 곳, [D-007](DECISIONS.md)) 후 영역별 설정 모듈을 ui → editing → search → lsp → treesitter → git → debug 순으로 로드 ([D-009](DECISIONS.md)) |
| `lua/sinbin/plugins/ui.lua` | Colorscheme(tokyonight moon), mini.icons, mini.statusline, mini.notify, mini.starter, mini.clue |
| `lua/sinbin/plugins/editing.lua` | mini.pairs, mini.surround 설정·Keymap ([D-008](DECISIONS.md)) |
| `lua/sinbin/plugins/search.lua` | mini.pick, mini.extra, mini.files 설정(탐색기 `g.` = 작업 폴더 변경) 및 `<Leader>f`/`<Leader>s` Keymap, 진단 picker `<Leader>ed`/`<Leader>eD`, Terminal 목록 picker `<Leader>tl`, Run 명령 목록 picker `<Leader>rt` |
| `lua/sinbin/plugins/lsp.lua` | mason.nvim, mini.completion 설정, `vim.lsp.enable()` Server 목록 (nvim-lspconfig 설정 사용, [D-010](DECISIONS.md)), 자동완성 Keymap, LspAttach Keymap |
| `lua/sinbin/plugins/treesitter.lua` | nvim-treesitter parser 설치 목록, FileType autocmd로 내장 `vim.treesitter.start()`, `PackChanged` 시 `:TSUpdate` ([D-011](DECISIONS.md)) |
| `lua/sinbin/plugins/git.lua` | gitsigns.nvim 설정(변경 표시, hunk, inline blame), diffview-plus 설정(전체 변경 검토, 파일 이력, `q` 닫기), `<Leader>g` Keymap, mini.extra git picker ([D-013](DECISIONS.md)) |
| `lua/sinbin/terminal.lua` | Terminal 창 (`jobstart` `term = true`, [D-014](DECISIONS.md)): 번호별 하단 split·floating Shell Terminal 토글(숨겨도 프로세스 유지), 명령 실행용 floating(`run_float`), 명령 실행용 하단 Terminal(`exec`/`stop`, 출력 유지·재사용), `<Leader>tt`/`tf`, Terminal 모드 `<C-q>`. Shell은 `platform.terminal_shell` 또는 'shell' |
| `lua/sinbin/run.lua` | Run/Build/Test를 **파일 범위**(`<Leader>rr`/`rb`/`xf`, filetype별 명령)와 **프로젝트 범위**(`<Leader>rR`/`rB`/`xx`, 가장 가까운 marker의 프로젝트)로 실행. 파일이 아니면 작업 폴더 기준, 없으면 하위 프로젝트 선택(`vim.ui.select`). `.sinbin/run.json` 덮어쓰기, `terminal.exec("run")` ([D-015](DECISIONS.md)) |
| `lua/sinbin/plugins/debug.lua` | nvim-dap + nvim-dap-view(패널, 줄 끝 변수 값) 설정, 언어별 adapter·configuration (C gdb DAP, Python debugpy, Node js-debug, Dart/Flutter SDK adapter, Java java-debug bundle), `<Leader>d*`·F5/F10/F11/F12 ([D-016](DECISIONS.md)). Mason `.cmd` shim 대신 실제 실행 파일로 adapter 실행 |
| `lua/sinbin/lazygit.lua` | 외부 CLI lazygit을 `terminal.run_float`로 실행 (`<Leader>gg`), 종료 시 `checktime` |
| Treesitter Parser (Repository 밖) | `stdpath('data')/site/parser`. `c` 등 내장 parser는 Neovim 설치 경로 |
| LSP Server (Repository 밖) | Mason 설치 위치 `stdpath('data')/mason`. Dart는 Flutter SDK의 `dart language-server` |
| `nvim-pack-lock.json` | `vim.pack` lock 파일 (자동 생성, 직접 수정 금지). Plugin 설치 위치는 `stdpath('data')/site/pack/core/opt` (Repository 밖) |
| `AGENTS.md` / `CLAUDE.md` | AI Agent 작업 규약 / Claude Code 진입점 |
| `docs/` | Human Source of Truth |
| `.agent/` | 외부 Observer 관리 영역 — 이 프로젝트의 일부가 아님 |

## Planned

확정 전 방향. 구현되면 Current로 옮긴다.

- **Platform Layer 내용** — Shell, Path, Clipboard provider(SSH/WSL 등) 차이 구현 (Phase 12). 구조는 Current 참조
- **AI Agent Boundary** — Agent는 외부 CLI. Neovim은 Terminal/Panel로 실행·결과 확인만 담당 ([D-002](DECISIONS.md)). 실행 기반은 `terminal.lua` (Phase 10)
- **Run/Test Layer** — 프로젝트 종류 감지 → 실행 명령 매핑
