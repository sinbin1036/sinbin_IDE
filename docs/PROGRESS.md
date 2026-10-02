# PROGRESS

현재 상태 Snapshot. History를 누적하지 않는다. Phase 정의는 [PROJECT.md](PROJECT.md) Roadmap.

- **Current Phase:** Phase 5 — Diagnostics 준비
- **Status:** Phase 4 LSP / Completion + Treesitter 완료 (TypeScript, Python, Java, Dart, C). 설치된 Plugin 15개 ([D-009](DECISIONS.md), [D-010](DECISIONS.md), [D-011](DECISIONS.md)). 조작법은 [USAGE.md](USAGE.md).

## Completed
- Project 정의 ([TASK-001](tasks/completed/TASK-001-define-project.md))
- Phase 0 Bootstrap: `git init`(main), Junction 연결, 최소 `init.lua` ([TASK-002](tasks/completed/TASK-002-phase0-bootstrap.md))
- Phase 1 Core Config Skeleton ([TASK-003](tasks/completed/TASK-003-core-config.md))
- Plugin Manager `vim.pack` 도입 ([TASK-004](tasks/completed/TASK-004-plugin-manager.md))
- Phase 2 기본 Editing UX ([TASK-005](tasks/completed/TASK-005-basic-editing-ux.md))
- Phase 3 Search / Navigation + 기본 UI ([TASK-006](tasks/completed/TASK-006-search-navigation-ui.md))
- Phase 4 LSP / Completion ([TASK-007](tasks/completed/TASK-007-lsp-completion.md))
- Phase 4 Treesitter 구문 강조 ([TASK-008](tasks/completed/TASK-008-treesitter.md))

## In Progress
- 없음

## Blocked
- 없음

## Unverified
- Linux / macOS / WSL / SSH 환경 (Platform 감지 분기 포함)
- lock 파일 기준 새 장비 일괄 설치 (Phase 13). Mason Server, Treesitter parser는 lock 파일 밖

## Current Active Task
없음

## Next Action
Phase 5 (Diagnostics) Task 작성: 사용자와 범위 확정 (에러 표시 방식, 목록 보기, 이동 Keymap 등) → 내장 `vim.diagnostic`(virtual text/lines, `]d`/`[d`, quickfix/loclist)으로 가능한지 먼저 검토 후 Plugin 여부 결정. `<Leader>e` Error/Diagnostic 그룹 사용.
