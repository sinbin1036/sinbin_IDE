# ARCHITECTURE

현재 Architecture의 Source of Truth. 실제 존재하는 것만 Current에 기록한다.

## Current

Repository Root = Neovim config 디렉터리. Windows에서는 `%LOCALAPPDATA%\nvim` Junction으로 연결 ([D-005](DECISIONS.md)).
Neovim은 Root의 `init.lua`(및 이후 `lua/` 등 runtime 경로)만 로드하며, 문서 파일은 무시된다.
`setup.ps1`·`scripts/setup/`은 설치 스크립트로, Neovim이 로드하지 않는다 (helper `nvim_setup.lua`만 설치 중 `luafile`로 실행).

| 경로 | 책임 |
|---|---|
| `init.lua` | Neovim 진입점. 시작 시각 기록(`vim.g.sinbin_start`, 시작 화면 표시용) 후 아래 모듈을 순서대로 로드 (keymaps → settings → options → autocmds → commands → diagnostics → platform → plugins → terminal → run → lazygit → agent → ime) |
| `setup.ps1` | Windows 설치 진입점 ([TASK-021](tasks/completed/TASK-021-installer.md)): Preflight → Core tools → Build & helper tools → Language runtimes(선택) → Config link(Junction) → Neovim plugins → Treesitter parsers → Mason. 항목마다 확인 후 없는 것만 winget / helper로 설치, 결과(설치·있음·건너뜀·실패 + 단계)를 모아 요약. `-Update`(TASK-023): Plugin·parser·Mason 단계를 helper의 `update_*` 단계로 바꿔 새 버전으로 올리고 결과에 `updated` 추가, Plugin이 바뀌면 lock 파일 커밋 안내 (외부 도구는 업그레이드 안 함). 의존 단계는 앞 단계 결과(`$Have`)로 건너뜀. dot-source 시 함수만 정의 |
| `scripts/setup/ui.ps1`, `proc.ps1` | 설치 화면(busy.js 스타일 gradient·spinner·bar·로고, 한글 폭 계산) / 외부 명령 실행기 (C# `Process` 래퍼: 출력 줄·종료를 queue + `AutoResetEvent`로 알림, 끝은 `Exited` 이벤트 기준) |
| `scripts/setup/nvim_setup.lua` | 설치용 Neovim headless helper (OS 중립): `SINBIN_SETUP_STEP` = plugins / parsers / mason (업데이트: update_plugins = `vim.pack.update` `force`, update_parsers = 설치 revision ≠ nvim-treesitter 고정 revision이면 다시 빌드, update_mason = 설치 버전 ≠ registry 최신이면 다시 설치) 단계를 실행하고 항목마다 `@@sinbin\|event\|name\|info` 출력. parser 목록은 `plugins/treesitter.lua` 반환값 |
| `lua/sinbin/keymaps.lua` | Leader(`<Space>`) / LocalLeader(`\`) 설정 및 Plugin과 무관한 전역 Keymap (Phase 2 편집 Keymap, 창 이동 `Alt+h/j/k/l` [D-019](DECISIONS.md)). Plugin 전용 Keymap은 `plugins/` 영역별 파일 |
| `lua/sinbin/settings.lua` | 사용자 설정 ([D-024](DECISIONS.md)): 항목 목록(분류·이름·선택지·기본값·바로 적용 함수·적용 시점), 기본값과 다른 값만 `stdpath('data')/sinbin/settings.json`에 저장·읽기(잘못된 값 무시), `get`/`set`/`reset`, 테마 적용(`apply_theme`), 파일 직접 저장 시 다시 읽기(BufWritePost). 각 모듈은 load 시 `get()`으로 읽음 |
| `lua/sinbin/settings_ui.lua` | 설정 패널: 가운데 floating 창, 분류별 항목·값, `j`/`k`·`<CR>`/`Space`·`h`/`l`·`q`, 고급 항목은 패널을 닫은 뒤 실행. `<Leader>,`(keymaps)·`:Settings`(commands)·시작 화면 `c` |
| `lua/sinbin/options.lua` | OS 중립 기본 Option (번호, indent, search, clipboard, undo, split, 표시, 긴 줄, inccommand, 화면 전체 상태바 한 줄 `laststatus=3`) |
| `lua/sinbin/autocmds.lua` | 전역 Autocmd (`sinbin` augroup 하나): Yank 하이라이트, 커서 위치 복원, 자동 저장(설정, InsertLeave/BufLeave/FocusLost), 외부 수정 반영(`checktime`) |
| `lua/sinbin/quit_confirm.lua` | 강제 종료 확인 (TASK-022): `:` 명령줄 `<CR>`/`<kEnter>`/`<NL>` expr 매핑이 입력이 강제 종료 명령(`:q!`·`:qa!`·`:wq!`·`:x!`·`:xa!`·`:wqa!`·`:exit!`·`:cq`, 줄임말 포함)이면 명령줄을 빠져나와(`<C-c>`, 기록은 `histadd`) 가운데 floating 확인 창 → 예일 때만 입력했던 창으로 돌아가 `vim.cmd`로 실행 (창을 벗어나면 취소). `ZQ`도 같은 확인. `QuitPre`는 종료를 취소할 수 없어 명령줄에서 가로챔 |
| `lua/sinbin/commands.lua` | 사용자 명령: `:TrimWhitespace` (저장 시 자동 실행 안 함), `:Settings`, `:Home[!]`, `:Setup` (Plugin보다 먼저 로드되어 Plugin 없이도 있음) |
| `lua/sinbin/setup.lua` | `:Setup` / `:Setup update`(TASK-023, `-Update`) / 시작 화면 `s` (TASK-021): Platform Layer `setup_cmd(root, update)`(Windows: `setup.ps1`)를 새 탭 페이지 Terminal(내장 `jobstart` `term = true`, `sinbin.terminal` 안 씀)에서 실행. root는 config 경로의 실제 경로(`fs_realpath`, Junction 아님). 끝나면 알림 + `q`로 탭 닫기 |
| `lua/sinbin/diagnostics/init.lua` | 내장 `vim.diagnostic` 설정(virtual_text, 심각도 정렬, sign 아이콘, 이동 시 float)과 Plugin 무관 `<Leader>e` Keymap. virtual_text·float의 `format`에서 혼합 번역 적용. Picker Keymap(`<Leader>ed`/`eD`)은 `plugins/search.lua` |
| `lua/sinbin/diagnostics/translate.lua` | 진단 메시지 첫 줄을 규칙으로 혼합 번역 (표시 전용, 진단 데이터는 변경 안 함, [D-012](DECISIONS.md)) |
| `lua/sinbin/diagnostics/rules_ko.lua` | 언어별 번역 규칙 목록 (Lua pattern → 치환문) |
| `lua/sinbin/platform/init.lua` | Platform Layer 진입점 ([D-003](DECISIONS.md)). OS 감지(`os`, `is_wsl`)·SSH 감지(`is_ssh`) 후 해당 OS 모듈 `setup()` 호출. SSH 접속 중이면 clipboard를 복사 전용 OSC 52로 (붙여넣기는 마지막 복사 내용, [D-025](DECISIONS.md)). OS 분기는 이 디렉터리에만 존재 |
| `lua/sinbin/platform/{windows,linux,macos}.lua` | OS별 설정. `windows`: 'shell'이 cmd가 아니면(Git Bash에서 실행) `cmd.exe`로 되돌림 (TASK-020), dartls `cmd`를 `dart.bat`로 지정 (TASK-007), Terminal용 Shell(`platform.terminal_shell`)을 Git Bash로 지정 (TASK-012), Run 명령 실행(`platform.terminal_exec` = `bash -c`), Python 실행 파일 이름(`platform.python`) (TASK-013), 설치 스크립트 명령(`setup_cmd`, TASK-021), 실행 파일 확장자(`exe_suffix`)·venv 폴더(`venv_bin`)·SDK의 실제 `dart.exe`(`dart_exe`)·Flutter 실행 명령(`flutter_cmd`) (TASK-014). `linux`/`macos`: `python` = `python3`만, 나머지는 사용하는 쪽의 Unix 기본값 (Shell = 'shell'(`$SHELL`), `venv_bin` = `bin` 등). WSL clipboard는 Neovim 기본 감지(`win32yank.exe`) (TASK-020) |
| `lua/sinbin/plugins/init.lua` | Plugin 목록 (`vim.pack.add()` 한 곳, [D-007](DECISIONS.md)). `load` 함수로 nvim-dap·nvim-dap-view·diffview-plus는 시작 시 `packadd!`하지 않음(처음 쓸 때 `packadd`, TASK-023), 나머지는 기본처럼 `packadd!`. 그 후 영역별 설정 모듈을 ui → editing → search → sidebar → lsp → treesitter → git → debug 순으로 로드 ([D-009](DECISIONS.md)) |
| `lua/sinbin/plugins/ui.lua` | Colorscheme(tokyonight moon), mini.icons(+ nvim-web-devicons 대체), mini.statusline(내용은 `statusline.lua`), 위쪽 탭 바 bufferline.nvim(`custom_filter`: 폴더 버퍼·비어 있고 수정 안 된 이름 없는 버퍼 제외)과 `<Leader>b`·`]b`/`[b` Keymap ([D-018](DECISIONS.md)), mini.notify, mini.starter(내용은 `starter.lua`), mini.clue |
| `lua/sinbin/starter.lua` | 시작 화면 ([D-023](DECISIONS.md)): mini.starter content hook 하나로 배치 — SINBIN 블록 로고(열마다 highlight group, 파랑→보라→분홍 gradient)·`I D E`, Actions 2열(이름 첫 글자가 키, `evaluate_single`, 기존 Keymap을 `maparg`로 실행, `c` = 설정 패널), Recent Projects(숫자 키, 긴 경로는 앞부분 생략), Plugin 수·시작 시간·Tip. 창이 로고(42칸)보다 좁으면 `SinBin IDE` 한 줄. 작업 폴더 변경 시 다시 그림 |
| `lua/sinbin/starter.lua` `home(force)` | `:Home[!]` (TASK-022): 저장 안 된 목록 버퍼가 있으면(`!` 없을 때) 이름 표시 후 중단 → scratch 버퍼로 새 탭 페이지(`tab sbuffer`, 빈 일반 버퍼면 시작 화면 뒤 첫 진입 처리가 오른쪽 영역을 엶) → `tabonly!`·나머지 창 닫기 → 홈 폴더로 `chdir` → `MiniStarter.open()` → 파일 버퍼 삭제. Terminal 버퍼는 숨김 상태로 유지. 최근 프로젝트 항목은 `chdir` 후 빈 편집기(`layout.show_empty`) + `agent.enter_project()`(오른쪽 Shell을 `terminal.close`로 끝내고 새 폴더에서 다시 시작, Agent는 유지) |
| `lua/sinbin/projects.lua` | 최근 프로젝트 목록: 시작 시(UI 있을 때)·전역 `DirChanged`마다 작업 폴더를 `stdpath('data')/sinbin/projects.txt` 맨 위로 (중복 없음, 10개, 홈 폴더 제외). 시작 시 파일 인자가 없으면(그냥 `nvim`, UI 있을 때) 기록하지 않고 홈 폴더로 `chdir` (TASK-022) |
| `lua/sinbin/plugins/editing.lua` | mini.pairs, mini.surround 설정·Keymap ([D-008](DECISIONS.md)) |
| `lua/sinbin/plugins/search.lua` | mini.pick, mini.extra 설정 및 `<Leader>f`/`<Leader>s` Keymap, 프로젝트 심볼 `<Leader>ss`(workspace symbol, 입력이 곧 LSP 질의), 명령 팔레트 `<Leader>sc`/`sk`, 진단 picker `<Leader>ed`/`<Leader>eD`, Run 명령 목록 picker `<Leader>rt` |
| `lua/sinbin/plugins/sidebar.lua` | 왼쪽 영역 ([D-018](DECISIONS.md)): Files = mini.files(floating, `g.` 작업 폴더 변경, `files_git.lua`), Outline = aerial.nvim(현재 파일 심볼 트리, 왼쪽 끝 split). 한 번에 하나만, `<Leader>fe`/`<Leader>co`, 패널 안 `<Tab>` 전환 |
| `lua/sinbin/files_git.lua` | mini.files에 Git 상태 표시: `git status --porcelain=v1 -z` 비동기(1초 cache, 탐색기 열 때 새로 읽음) → 이름 색 + 오른쪽 끝 `M`/`A`/`U`/`R`/`!`, 변경 포함 폴더 `•` |
| `lua/sinbin/layout.lua` | 창 배치 ([D-018](DECISIONS.md), [D-021](DECISIONS.md)): Terminal 영역(하단 패널·오른쪽 영역) 창에 파일이 들어오면 마지막 코드 창으로 옮기고 Terminal을 되돌림(BufWinEnter, `vim.w.sinbin_term`), 마지막 코드 창의 `:q`는 다른 영역을 먼저 닫아 종료(QuitPre), Outline 왼쪽·Agent 오른쪽 위아래 전체, 하단 패널은 코드 아래에만 (`WinNew` 뒤 `<C-w>H`/`L`로 보정, 크기 유지), 영역 표시(`vim.w.sinbin_region`), 코드 창 winbar 경로, 탭 닫기(`close_buffer`, 창 유지). 빈 편집기(TASK-022): 파일 없는 코드 창은 읽기 전용 scratch 버퍼(`filetype` `sinbinempty`, `bufhidden` wipe, `empty_buf()`/`show_empty()`)에 키 안내를 창 가운데 그림(`BufWinEnter`·`WinResized`·`VimResized`) — 마지막 코드 창을 닫은 자리, 마지막 탭 닫기, `nvim .`의 폴더 버퍼(VimEnter에서 교체), 시작 화면의 최근 프로젝트 |
| `lua/sinbin/ime.lua` | 한/영 자동 전환 ([D-022](DECISIONS.md)): 코드 창 진입(WinEnter/BufEnter) 시 Platform Layer `ime.to_english()` 비동기 호출 (focus 중·터미널 UI일 때만, Platform에 `ime` 없으면 없음) |
| `lua/sinbin/platform/windows_ime.lua`, `ime_helper.cs` | Windows IME 도우미: C# 소스를 `csc.exe`로 `stdpath("data")/sinbin/ime-helper.exe`에 빌드·실행, 전경 창이 터미널 프로세스일 때만 한글 → 영어 |
| `lua/sinbin/statusline.lua` | mini.statusline 내용과 색 ([D-020](DECISIONS.md)), VS Code 상태바 형식: 모드(진한 색) · 브랜치(`*` 변경 있음) · pull/push · 에러/경고 · 작업 폴더 / 실행 중 배지 Run·Debug·Agent · `Ln, Col` · 파일 타입. 저장소 상태(`rev-list`·`branch --show-current`·`status --porcelain`, status는 `--no-optional-locks`)는 timer(`defer_fn`)로 미뤄 비동기로 읽어 cache (git 프로세스 시작이 Windows에서 약 20ms라 첫 화면·버퍼 전환을 막지 않게, TASK-023), 디버그 중 상태바 전체 주황 (`package.loaded.dap`이 있을 때만 확인) |
| `lua/sinbin/plugins/lsp.lua` | mason.nvim, mini.completion 설정(완성 kind 아이콘, SymbolKind 이름은 원래대로 — aerial 필터·highlight 이름), `vim.lsp.enable()` Server 목록 (nvim-lspconfig 설정 사용, [D-010](DECISIONS.md)), 자동완성 Keymap, LspAttach Keymap |
| `lua/sinbin/plugins/treesitter.lua` | nvim-treesitter parser 설치 목록, FileType autocmd로 내장 `vim.treesitter.start()`, `PackChanged` 시 `:TSUpdate` ([D-011](DECISIONS.md)). 빠진 parser가 있는데 `tree-sitter` CLI가 없으면 설치 대신 경고 1회 (TASK-020). `SINBIN_SETUP` 환경 변수가 있으면 시작 시 설치 안 함, parser 목록을 `return { parsers }` (TASK-021) |
| `lua/sinbin/plugins/git.lua` | gitsigns.nvim 설정(변경 표시, hunk, inline blame), diffview-plus 설정(전체 변경 검토, 파일 이력, `q` 닫기 — `<Leader>gv`/`<Leader>gl`이나 `:Diffview*` 대체 명령을 처음 쓸 때 `packadd` + setup, 대체 명령은 diffview 자체 명령으로 바뀜), `<Leader>g` Keymap, mini.extra git picker ([D-013](DECISIONS.md)) |
| `lua/sinbin/terminal.lua` | Terminal 창 (`jobstart` `term = true`, [D-014](DECISIONS.md)): 영역마다 창 하나 + winbar 탭(클릭 전환) — **하단 패널**(번호별 Shell, Run, [D-018](DECISIONS.md)) / **오른쪽 영역**(Shell `side`, Agent, [D-020](DECISIONS.md)), floating Shell Terminal, 커서 이동 없이 시작(`background`), 오른쪽 영역 전체 화면(`toggle_zoom`: 오른쪽 열을 닫고 같은 Terminal을 편집 영역 전체 float로, `Alt+z`/`<Leader>az`), 오른쪽 세로 창 프로그램 Terminal(`toggle(id, "right", { cmd })`), 숨겨도 프로세스 유지, `focus`/`send`(입력창에 텍스트 입력), 영역 키 규칙(숨김 → 열기 / 보임 → 이동 / 현재 → 숨김)·하단 패널 전체 `toggle_panel`(`<Leader>tp`, `` Alt+` ``)·Terminal 진입 시 자동 입력 모드 ([D-019](DECISIONS.md)), 명령 실행용 floating(`run_float`)·하단(`exec`/`stop`/`job_running`), `<Leader>tt`/`tf`, Terminal 모드 `<C-q>`. Shell은 `platform.terminal_shell` 또는 'shell' |
| `lua/sinbin/run.lua` | Run/Build/Test를 **파일 범위**(`<Leader>rr`/`rb`/`xf`, filetype별 명령)와 **프로젝트 범위**(`<Leader>rR`/`rB`/`xx`, 가장 가까운 marker의 프로젝트)로 실행. 파일이 아니면 작업 폴더 기준, 없으면 하위 프로젝트 선택(`vim.ui.select`). `.sinbin/run.json` 덮어쓰기, `terminal.exec("run")` ([D-015](DECISIONS.md)) |
| `lua/sinbin/plugins/debug.lua` | 디버그 Keymap만 (`<Leader>d*`·F5/F10/F11/F12). 처음 누를 때 `load()`가 nvim-dap·nvim-dap-view를 `packadd`하고 `debug_config.lua`를 로드 (TASK-023) |
| `lua/sinbin/plugins/debug_config.lua` | nvim-dap + nvim-dap-view(패널, 줄 끝 변수 값) 설정, 언어별 adapter·configuration (C gdb DAP, Python debugpy, Node js-debug, Dart/Flutter SDK adapter, Java java-debug bundle), 시작/계속 전 설정·adapter 확인(`start_or_continue`) ([D-016](DECISIONS.md)). Mason `.cmd` shim 대신 실제 실행 파일로 adapter 실행. 디버그 패널은 하단 패널이 열려 있으면 그 오른쪽 절반 |
| `lua/sinbin/agent.lua` | AI Agent CLI(Claude Code `claude`, Codex `codex`)를 오른쪽 영역 Terminal로 실행·토글(현재 파일의 git root에서 시작), 현재 파일·선택 줄을 `@경로#L10-20`으로 입력창에 입력, `<Leader>a*` ([D-017](DECISIONS.md)). 시작 시 오른쪽 영역 일반 Shell(VimEnter, 시작 화면이면 첫 파일 BufEnter까지 미룸), `Alt+a` 코드 ↔ 오른쪽 영역 ([D-020](DECISIONS.md)) |
| `lua/sinbin/lazygit.lua` | 외부 CLI lazygit을 `terminal.run_float`로 실행 (`<Leader>gg`), 종료 시 `checktime` |
| Treesitter Parser (Repository 밖) | `stdpath('data')/site/parser`. `c` 등 내장 parser는 Neovim 설치 경로 |
| LSP Server (Repository 밖) | Mason 설치 위치 `stdpath('data')/mason`. Dart는 Flutter SDK의 `dart language-server` |
| `nvim-pack-lock.json` | `vim.pack` lock 파일 (자동 생성, 직접 수정 금지). Plugin 설치 위치는 `stdpath('data')/site/pack/core/opt` (Repository 밖) |
| `AGENTS.md` / `CLAUDE.md` | AI Agent 작업 규약 / Claude Code 진입점 |
| `docs/` | Human Source of Truth |
| `.agent/` | 외부 Observer 관리 영역 — 이 프로젝트의 일부가 아님 |

## Planned

확정 전 방향. 구현되면 Current로 옮긴다.

- **Run/Test Layer** — 프로젝트 종류 감지 → 실행 명령 매핑
