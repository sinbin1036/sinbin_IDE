# PROGRESS

현재 상태 Snapshot. History를 누적하지 않는다. Phase 정의는 [PROJECT.md](PROJECT.md) Roadmap.

- **Current Phase:** Phase 4 — LSP / Completion 준비
- **Status:** Phase 3 Search / Navigation + 기본 UI 완료. 설치된 Plugin: mini 계열 10개 + tokyonight ([D-009](DECISIONS.md)). 조작법은 [USAGE.md](USAGE.md).

## Completed
- Project 정의 ([TASK-001](tasks/completed/TASK-001-define-project.md))
- Phase 0 Bootstrap: `git init`(main), Junction 연결, 최소 `init.lua` ([TASK-002](tasks/completed/TASK-002-phase0-bootstrap.md))
- Phase 1 Core Config Skeleton ([TASK-003](tasks/completed/TASK-003-core-config.md))
- Plugin Manager `vim.pack` 도입 ([TASK-004](tasks/completed/TASK-004-plugin-manager.md))
- Phase 2 기본 Editing UX ([TASK-005](tasks/completed/TASK-005-basic-editing-ux.md))
- Phase 3 Search / Navigation + 기본 UI ([TASK-006](tasks/completed/TASK-006-search-navigation-ui.md))

## In Progress
- 없음

## Blocked
- 없음

## Unverified
- Linux / macOS / WSL / SSH 환경 (Platform 감지 분기 포함)
- lock 파일 기준 새 장비 일괄 설치 (Phase 13)

## Current Active Task
없음

## Next Action
Phase 4 (LSP / Completion) Task 작성: 사용자와 대상 언어·필요 기능(자동완성, 정의 이동, 포맷 등) 범위 확정 → Neovim 0.12 내장 LSP(`vim.lsp.config`/`vim.lsp.enable`)·내장 completion으로 가능한지 먼저 검토 후 Plugin 여부 결정. LSP Server 설치 방법도 함께 결정.
