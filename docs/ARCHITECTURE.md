# ARCHITECTURE

현재 Architecture의 Source of Truth. 실제 존재하는 것만 Current에 기록한다.

## Current

Repository Root = Neovim config 디렉터리. Windows에서는 `%LOCALAPPDATA%\nvim` Junction으로 연결 ([D-005](DECISIONS.md)).
Neovim은 Root의 `init.lua`(및 이후 `lua/` 등 runtime 경로)만 로드하며, 문서 파일은 무시된다.

| 경로 | 책임 |
|---|---|
| `init.lua` | Neovim 진입점. 아래 모듈을 순서대로 로드 (keymaps → options → platform → plugins) |
| `lua/sinbin/keymaps.lua` | Leader(`<Space>`) / LocalLeader(`\`) 설정. 기능 Keymap은 각 Phase에서 추가 |
| `lua/sinbin/options.lua` | OS 중립 기본 Option (번호, indent, search, clipboard, undo, split) |
| `lua/sinbin/platform/init.lua` | Platform Layer 진입점 ([D-003](DECISIONS.md)). OS 감지(`os`, `is_wsl`) 후 해당 OS 모듈 `setup()` 호출. OS 분기는 이 디렉터리에만 존재 |
| `lua/sinbin/platform/{windows,linux,macos}.lua` | OS별 설정. 현재 빈 `setup()` — 내용은 Phase 12 |
| `lua/sinbin/plugins.lua` | Plugin 목록 (`vim.pack.add()`, [D-007](DECISIONS.md)). 현재 비어 있음 |
| `nvim-pack-lock.json` | `vim.pack` lock 파일 (자동 생성, 직접 수정 금지). Plugin 설치 위치는 `stdpath('data')/site/pack/core/opt` (Repository 밖) |
| `AGENTS.md` / `CLAUDE.md` | AI Agent 작업 규약 / Claude Code 진입점 |
| `docs/` | Human Source of Truth |
| `.agent/` | 외부 Observer 관리 영역 — 이 프로젝트의 일부가 아님 |

## Planned

확정 전 방향. 구현되면 Current로 옮긴다.

- **Platform Layer 내용** — Shell, Path, Clipboard provider(SSH/WSL 등) 차이 구현 (Phase 12). 구조는 Current 참조
- **AI Agent Boundary** — Agent는 외부 CLI. Neovim은 Terminal/Panel로 실행·결과 확인만 담당 ([D-002](DECISIONS.md))
- **Run/Test Layer** — 프로젝트 종류 감지 → 실행 명령 매핑
- **Autocmd 모듈** — 실제 Autocmd가 생길 때 `lua/sinbin/autocmds.lua`로 추가
