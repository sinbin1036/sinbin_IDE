# PROGRESS

현재 상태 Snapshot. History를 누적하지 않는다. Phase 정의는 [PROJECT.md](PROJECT.md) Roadmap.

- **Current Phase:** Phase 2 — 기본 Editing UX 준비
- **Status:** TASK-005 구현·headless 검증 완료, PR 리뷰 및 화면 확인 대기. 설치된 Plugin: mini.pairs, mini.surround.

## Completed
- Project 정의 ([TASK-001](tasks/completed/TASK-001-define-project.md))
- Phase 0 Bootstrap: `git init`(main), Junction 연결, 최소 `init.lua` ([TASK-002](tasks/completed/TASK-002-phase0-bootstrap.md))
- Phase 1 Core Config Skeleton ([TASK-003](tasks/completed/TASK-003-core-config.md))
- Plugin Manager `vim.pack` 도입 ([TASK-004](tasks/completed/TASK-004-plugin-manager.md))

## In Progress
- TASK-005 기본 Editing UX (화면 확인 대기)

## Blocked
- 없음

## Unverified
- Nerd Font 설치 여부
- Linux / macOS / WSL / SSH 환경 (Platform 감지 분기 포함)
- lock 파일 기준 새 장비 일괄 설치 (Phase 13)
- checkhealth `ripgrep not available` WARNING 원인 (Git Bash PATH로 추정)

## Current Active Task
[TASK-005](tasks/active/TASK-005-basic-editing-ux.md)

## Next Action
TASK-005 화면 확인(Yank 하이라이트, listchars, inccommand, cursorline) → PR merge → TASK-005 completed 이동.
