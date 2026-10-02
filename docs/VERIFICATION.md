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

주의: Repository 안이 아닌 임시 디렉터리에서 실행하면 열린 파일의 영향 없이 Config만 검증된다.
주의: `mini.pick` picker는 입력을 기다리며 block되므로 headless에서 실행하지 않는다. picker 화면은 사용자 확인으로 검증.
주의: 외부 CLI를 설치한 직후에는 기존 Shell의 PATH가 갱신되지 않는다. 새 Terminal에서 확인.
주의: 디버그 검증은 `nvim --embed --headless -n`(UI attach) RPC로 breakpoint → 시작 → 정지 위치 → step → `scopes`/`variables` 요청 → 종료를 확인한다. 끝난 뒤 adapter 프로세스가 남지 않았는지도 확인.
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
| Linux / macOS / WSL / SSH | UNVERIFIED (검증 환경 없음) |

## Verification Context

| 구분 | 내용 |
|---|---|
| Relevant Source | `init.lua`, `lua/**` (생성 예정) |
| Relevant Config | `%LOCALAPPDATA%\nvim` Junction (깨지면 Config 미로드), `nvim-pack-lock.json` |
| Dependency | 외부 CLI Tool, LSP Server 등 ([PROJECT.md](PROJECT.md) Dependency 분류) |
| Toolchain | Neovim 버전 |
| Environment | OS, Shell, Nerd Font |
| Invalidating Change | Neovim 버전 변경, Plugin 업데이트, OS/Shell 변경, 외부 CLI 버전 변경 |
