# VERIFICATION

변경 종류별 검증 방법. 실제 실행해 본 명령만 "확인됨"으로 표시한다.

## 명령

| 명령 | 용도 | 상태 |
|---|---|---|
| `nvim --headless "+qa"` | Startup 에러 확인 (출력 없음 + exit 0 = 정상) | 확인됨 (2026-10-01) |
| `nvim --headless "+checkhealth" "+w! <file>" "+qa!"` | checkhealth 결과를 파일로 저장 → `ERROR` 검색 | 확인됨 (2026-10-01, ERROR 0) |
| `nvim --headless "+lua io.write(vim.env.MYVIMRC)" "+qa"` | 이 Repository의 `init.lua`가 로드되는지 확인 | 확인됨 (2026-10-01) |
| `nvim --headless "+lua io.write(vim.inspect({vim.g.mapleader, vim.o.clipboard}))" "+qa"` | Option·Leader 실제 적용 값 확인 (확인할 항목으로 교체) | 확인됨 (2026-10-01) |
| `nvim --headless "+verbose map <Space>" "+qa"` | Keymap 충돌 및 정의 위치 확인 | 확인됨 (2026-10-01) |
| `nvim --headless "+lua io.write(vim.inspect(vim.pack.get(nil,{info=false})))" "+qa"` | `vim.pack` 관리 Plugin 목록·revision 확인 | 확인됨 (2026-10-01) |
| `nvim --headless "+lua vim.pack.del({'<name>'})" "+qa"` | Plugin을 디스크에서 제거 (목록에서 먼저 지운 뒤) | 확인됨 (2026-10-01) |
| `powershell -ExecutionPolicy Bypass -File .\setup.ps1 -CheckOnly` | 설치 스크립트로 도구·Runtime·config link 확인만 (설치 안 함) | 확인됨 (2026-10-07) |
| `XDG_DATA_HOME=<임시> XDG_STATE_HOME=<임시> XDG_CACHE_HOME=<임시> powershell ... setup.ps1 -NoPrompt` | 쓰던 Neovim 데이터를 건드리지 않고 Plugin·parser·Mason 새 설치 흐름 확인 (Windows Neovim도 `XDG_*`를 따름: `<임시>/nvim-data`) | 확인됨 (2026-10-07) |

주의: Repository 안이 아닌 임시 디렉터리에서 실행하면 열린 파일의 영향 없이 Config만 검증된다.
주의: `mini.pick` picker는 입력을 기다리며 block되므로 headless에서 실행하지 않는다. picker 화면은 사용자 확인으로 검증.
주의: 외부 CLI를 설치한 직후에는 기존 Shell의 PATH가 갱신되지 않는다. 새 Terminal에서 확인.
주의: 디버그 검증은 `nvim --embed --headless -n`(UI attach) RPC로 breakpoint → 시작 → 정지 위치 → step → `scopes`/`variables` 요청 → 종료를 확인한다. 끝난 뒤 adapter 프로세스가 남지 않았는지도 확인.
주의: RPC 조작 client는 임시 venv의 `pynvim` (`python -m venv <임시>/venv` → `pip install pynvim`, 시스템 Python에는 설치 안 함) — `pynvim.attach("child", argv=["nvim","--embed","--headless","-n"])` → `ui_attach`. Neovim을 controller로 `jobstart(rpc)` + `nvim_ui_attach`하면 자식이 바로 종료됨 (redraw 알림 처리 불가, 2026-10-06 확인).
주의: 시작 시(VimEnter) 동작은 `nvim --embed -n`(`--headless` 없이)으로 확인한다. `--headless`를 붙이면 UI attach 전에 VimEnter가 지나가 `nvim_list_uis()`가 비어 있음 (2026-10-07 확인).
주의: 화면 배치 검증 (2026-10-06 확인)은 자식에서 `nvim_eval_statusline`(tabline/winbar/statusline 실제 표시 문자열)·`winlayout()`·창 크기를 읽는다. 자식에서 `set messagesopt=wait:0,history:500`로 hit-enter prompt를 막고 `:messages`로 에러 확인 (prompt에 걸리면 RPC 요청이 멈춤, `nvim_get_mode().blocking`으로 감지).
주의: WSL 검증은 Windows 쪽에서 `printf '<명령>' | wsl.exe -d Ubuntu-24.04 -- bash -l`로 실행 (인자로 넘기면 `$변수`가 Windows 쪽 Shell에서 풀림). 실제 TUI 시작은 `script -qfc "nvim ..." /dev/null` pty로 띄우고 `defer_fn`으로 상태를 파일에 기록 후 `qa!` — 이때 `E1568`(DSR 응답 없음)은 pty 때문이라 무시. SSH 모드 OSC 52는 같은 pty 출력에서 `\e]52;c;` 검색 (2026-10-07 확인).
주의: `mini.notify`는 알림을 다음 event loop에서 추가하므로 같은 명령 안에서 `get_all()`하면 비어 있음 (`+sleep` 뒤에 확인).
주의: `setup.ps1` 출력을 파일로 받으면 spinner 갱신(`\r`, `ESC[2K`, `ESC[nF`)이 모두 남는다. 최종 화면은 이 세 가지를 재생하는 스크립트로 복원해서 확인 (Python은 `open(..., newline='')`로 읽어야 `\r`이 줄바꿈으로 바뀌지 않음). 실제 터미널 모양은 사용자 확인. 실패 표시는 `. .\setup.ps1`(dot-source, 함수만 정의) 후 없는 winget ID로 `Install-Tool` 호출해 확인 (2026-10-07).
주의: autocmd 안의 `:checktime`은 안전한 시점까지 미뤄진다 (`:h :checktime`). headless 스크립트 안에서는 실행되지 않으므로 `nvim --embed`를 RPC로 조작해 확인한다.

## 변경 종류별

| 변경 | 검증 |
|---|---|
| Lua Config (`init.lua`, `lua/`) | Startup 에러 확인 → 변경한 기능 수동 확인 |
| Plugin 추가/제거 | Startup 에러 확인 → checkhealth (`vim.pack` 섹션) → `nvim-pack-lock.json` diff가 `plugins/init.lua` 변경과 일치하는지 확인 → 제거 시 `vim.pack.del()` 후 디스크에서 사라졌는지 확인 |
| Keymap | 충돌 확인 (`:verbose map <key>`) → 동작 수동 확인 |
| LSP / Formatter / Debugger | checkhealth (`vim.lsp` 섹션) → 대상 언어 샘플 프로젝트(root marker 포함)에서 attach·definition·hover·completion 확인 (`client:request_sync`로 headless 가능) |
| Platform Layer | 해당 OS에서 Startup 확인. 검증 불가한 OS는 UNVERIFIED로 기록 |
| Install script | 깨끗한 환경에서 실행 — UNVERIFIED (환경 없음) |
| Docs | 상대 링크 실존 여부, 정보 중복 여부 |

자동 Test 체계 없음. 필요해지면 DECISIONS에 기록 후 추가.

## Environment

2026-10-01 확인. 버전이 바뀌면 이전 검증 결과는 재확인 대상.

| 항목 | 상태 |
|---|---|
| OS | Windows 11 Pro |
| Neovim | v0.12.5 (`C:\Program Files\Neovim`) |
| Git | 2.55.0 |
| ripgrep | 15.2.0 (winget `BurntSushi.ripgrep.MSVC`, 2026-10-01 설치. 이전 기록 14.1.1은 실제로는 PATH에 없었음) |
| gcc (MSYS2) | 14.2.0 |
| node / python / go | 22.19.0 / 3.13.3 / 1.25.3 |
| Java / Maven | 27 / 3.9.16 |
| Dart (Flutter SDK `C:\flutter`) | 3.10.4 |
| LSP Server (Mason, 2026-10-02) | vtsls, basedpyright 1.40.1, ruff, clangd, jdtls |
| Debug Adapter (2026-10-02) | gdb 16.2 (MSYS2, `-i dap`), debugpy 1.8.22 / js-debug-adapter / java-debug-adapter (vscode-java-debug 0.59.0, plugin 0.53.2) (Mason), Dart/Flutter SDK adapter. Flutter device: Windows desktop, Chrome, Edge |
| tree-sitter CLI | 0.27.0 (winget `tree-sitter.tree-sitter-cli`, 2026-10-02 설치) |
| lazygit | 0.65.1 (winget `JesseDuffield.lazygit`, 2026-10-02 설치) |
| fd, fzf, make | 미설치 |
| Nerd Font | JetBrainsMono Nerd Font 3.3.0 (winget `DEVCOM.JetBrainsMonoNerdFont`, Font 이름 `JetBrainsMono NF`, 2026-10-02 설치). Windows Terminal Font 지정은 사용자 설정 |
| `%LOCALAPPDATA%\nvim` (Windows 기본 config 경로) | 이 Repository로의 Junction |
| WSL | Ubuntu 24.04.2 LTS (WSL2, `Ubuntu-24.04`), Neovim v0.12.5 (공식 tarball → `~/.local/opt`, `~/.local/bin/nvim`), tree-sitter CLI 0.27.0 (`~/.local/bin`), git·python3·node·gcc (apt 기본). `~/.config/nvim` → `/mnt/c/.../sinbin_IDE` symlink. ripgrep·lazygit·Mason 패키지 없음 (2026-10-07 설치·확인) |
| SSH | 실제 접속 미검증. WSL에서 `SSH_CONNECTION`을 설정해 SSH 모드로 확인 |
| Linux (WSL 아닌) / macOS | UNVERIFIED (검증 환경 없음) |

## Verification Context

| 구분 | 내용 |
|---|---|
| Relevant Source | `init.lua`, `lua/**` (생성 예정) |
| Relevant Config | `%LOCALAPPDATA%\nvim` Junction (깨지면 Config 미로드), `nvim-pack-lock.json` |
| Dependency | 외부 CLI Tool, LSP Server 등 ([PROJECT.md](PROJECT.md) Dependency 분류) |
| Toolchain | Neovim 버전 |
| Environment | OS, Shell, Nerd Font |
| Invalidating Change | Neovim 버전 변경, Plugin 업데이트, OS/Shell 변경, 외부 CLI 버전 변경 |
