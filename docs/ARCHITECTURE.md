# ARCHITECTURE

현재 Architecture의 Source of Truth. 실제 존재하는 것만 Current에 기록한다.

## Current

Repository Root = Neovim config 디렉터리. Windows에서는 `%LOCALAPPDATA%\nvim` Junction으로 연결 ([D-005](DECISIONS.md)).
Neovim은 Root의 `init.lua`(및 이후 `lua/` 등 runtime 경로)만 로드하며, 문서 파일은 무시된다.

| 경로 | 책임 |
|---|---|
| `init.lua` | Neovim 진입점 (현재 빈 파일, 주석만) |
| `AGENTS.md` / `CLAUDE.md` | AI Agent 작업 규약 / Claude Code 진입점 |
| `docs/` | Human Source of Truth |
| `.agent/` | 외부 Observer 관리 영역 — 이 프로젝트의 일부가 아님 |

## Planned

확정 전 방향. 구현되면 Current로 옮긴다.

- **Platform Layer** — OS 차이를 한 계층에 격리 ([D-003](DECISIONS.md)). 예상 형태:
  `lua/platform/{windows,linux,macos}.lua`
- **AI Agent Boundary** — Agent는 외부 CLI. Neovim은 Terminal/Panel로 실행·결과 확인만 담당 ([D-002](DECISIONS.md))
- **Run/Test Layer** — 프로젝트 종류 감지 → 실행 명령 매핑

그 외 모듈 구조(`init.lua`, `lua/` 하위 분할)는 Phase 1에서 결정한다.
