# PROGRESS

현재 상태 Snapshot. History를 누적하지 않는다. Phase 정의는 [PROJECT.md](PROJECT.md) Roadmap.

- **Current Phase:** Phase 2 — 기본 Editing UX 준비
- **Status:** Core Config Skeleton 및 Plugin Manager(`vim.pack`) 연결 완료. 설치된 Plugin 없음.

## Completed
- Project 정의 ([TASK-001](tasks/completed/TASK-001-define-project.md))
- Phase 0 Bootstrap: `git init`(main), Junction 연결, 최소 `init.lua` ([TASK-002](tasks/completed/TASK-002-phase0-bootstrap.md))
- Phase 1 Core Config Skeleton ([TASK-003](tasks/completed/TASK-003-core-config.md))
- Plugin Manager `vim.pack` 도입 ([TASK-004](tasks/completed/TASK-004-plugin-manager.md))

## In Progress
- 없음

## Blocked
- 없음

## Unverified
- Nerd Font 설치 여부
- Linux / macOS / WSL / SSH 환경 (Platform 감지 분기 포함)
- lock 파일 기준 새 장비 일괄 설치 (Phase 13)
- checkhealth `ripgrep not available` WARNING 원인 (Git Bash PATH로 추정)

## Current Active Task
없음

## Next Action
Phase 2 (기본 Editing UX) Task 작성: 사용자와 필요한 편집 기능 범위 확정 → Neovim 기본 기능으로 가능한지 먼저 검토 후 Plugin 여부 결정.
