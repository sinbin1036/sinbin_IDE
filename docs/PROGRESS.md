# PROGRESS

현재 상태 Snapshot. History를 누적하지 않는다. Phase 정의는 [PROJECT.md](PROJECT.md) Roadmap.

- **Current Phase:** Phase 3 — Search / Navigation 준비
- **Status:** Phase 2 기본 Editing UX 완료. 설치된 Plugin: mini.pairs, mini.surround. 조작법은 [USAGE.md](USAGE.md).

## Completed
- Project 정의 ([TASK-001](tasks/completed/TASK-001-define-project.md))
- Phase 0 Bootstrap: `git init`(main), Junction 연결, 최소 `init.lua` ([TASK-002](tasks/completed/TASK-002-phase0-bootstrap.md))
- Phase 1 Core Config Skeleton ([TASK-003](tasks/completed/TASK-003-core-config.md))
- Plugin Manager `vim.pack` 도입 ([TASK-004](tasks/completed/TASK-004-plugin-manager.md))
- Phase 2 기본 Editing UX ([TASK-005](tasks/completed/TASK-005-basic-editing-ux.md))

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
Phase 3 (Search / Navigation) Task 작성: 사용자와 필요한 검색·이동 기능 범위 확정 → 내장 기능(`:find`, `:grep`, netrw 등)으로 가능한지 먼저 검토 후 Plugin 여부 결정. 파일 내용 검색을 다루므로 ripgrep WARNING 원인 확인을 함께 포함.
