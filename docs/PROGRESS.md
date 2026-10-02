# PROGRESS

현재 상태 Snapshot. History를 누적하지 않는다. Phase 정의는 [PROJECT.md](PROJECT.md) Roadmap.

- **Current Phase:** Phase 4 — Treesitter 준비 (Phase 4 마무리)
- **Status:** LSP / Completion 완료 (TypeScript, Python, Java, Dart, C). 설치된 Plugin 14개 ([D-009](DECISIONS.md), [D-010](DECISIONS.md)). 조작법은 [USAGE.md](USAGE.md).

## Completed
- Project 정의 ([TASK-001](tasks/completed/TASK-001-define-project.md))
- Phase 0 Bootstrap: `git init`(main), Junction 연결, 최소 `init.lua` ([TASK-002](tasks/completed/TASK-002-phase0-bootstrap.md))
- Phase 1 Core Config Skeleton ([TASK-003](tasks/completed/TASK-003-core-config.md))
- Plugin Manager `vim.pack` 도입 ([TASK-004](tasks/completed/TASK-004-plugin-manager.md))
- Phase 2 기본 Editing UX ([TASK-005](tasks/completed/TASK-005-basic-editing-ux.md))
- Phase 3 Search / Navigation + 기본 UI ([TASK-006](tasks/completed/TASK-006-search-navigation-ui.md))
- Phase 4 LSP / Completion ([TASK-007](tasks/completed/TASK-007-lsp-completion.md))

## In Progress
- 없음

## Blocked
- 없음

## Unverified
- Linux / macOS / WSL / SSH 환경 (Platform 감지 분기 포함)
- lock 파일 기준 새 장비 일괄 설치 (Phase 13). Mason Server는 lock 파일 밖

## Current Active Task
없음

## Next Action
TASK-008 Treesitter Task 작성 (TASK-007에서 분리 결정): 5개 언어 구문 강조. Neovim 내장 parser 범위 확인 → nvim-treesitter 필요 여부, `tree-sitter` CLI(미설치)·C compiler(gcc 있음) 요구사항 확인 후 사용자와 범위 확정.
